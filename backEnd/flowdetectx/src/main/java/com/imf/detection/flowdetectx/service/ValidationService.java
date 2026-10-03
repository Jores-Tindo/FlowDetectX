package com.imf.detection.flowdetectx.service;

import com.imf.detection.flowdetectx.dto.request.RejetDemandeRequest;
import com.imf.detection.flowdetectx.dto.response.DemandeResponse;
import com.imf.detection.flowdetectx.exception.CompteException;
import com.imf.detection.flowdetectx.exception.RessourceNotFoundException;
import com.imf.detection.flowdetectx.model.DemandeValidation;
import com.imf.detection.flowdetectx.model.RegleDetection;
import com.imf.detection.flowdetectx.model.VersionRegle;
import com.imf.detection.flowdetectx.model.enums.*;
import com.imf.detection.flowdetectx.repository.DemandeValidationRepository;
import com.imf.detection.flowdetectx.repository.RegleDetectionRepository;
import com.imf.detection.flowdetectx.repository.VersionRegleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ValidationService {

    private final DemandeValidationRepository demandeRepository;
    private final RegleDetectionRepository regleRepository;
    private final VersionRegleRepository versionRegleRepository;
    private final MoteurDroolsService moteurDroolsService;
    private final JournalService journalService;

    // --- Consultation ---
    @Transactional(readOnly = true)
    public List<DemandeResponse> listerDemandesEnAttente() {
    return demandeRepository.findByStatut(StatutDemandeEnum.EN_ATTENTE).stream()
            .map(this::mapAvecVersionActive).toList();
}
    @Transactional(readOnly = true)
public List<DemandeResponse> listerToutesDemandes() {
    return demandeRepository.findAll().stream()
            .map(this::mapAvecVersionActive).toList();
}
    @Transactional(readOnly = true)
public List<DemandeResponse> listerDemandesParAgentConformite(Long utilisateurId) {
    return demandeRepository.findBySoumiseParOrderByDateCreationDesc(utilisateurId).stream()
            .map(this::mapAvecVersionActive).toList();
}

private DemandeResponse mapAvecVersionActive(DemandeValidation demande) {
    VersionRegle versionActive = (demande.getVersionRegle() == null && demande.getRegle() != null)
            ? demande.getRegle().getVersionActive()
            : null;
    return DemandeResponse.fromEntity(demande, versionActive);
}

    // --- Approbation ---

    @Transactional
    public DemandeResponse approuver(Long demandeId, Long validateurId) {
        DemandeValidation demande = trouverDemande(demandeId);
        verifierEnAttente(demande);

        switch (demande.getType()) {
            case CREATION    -> approuverCreation(demande);
            case MODIFICATION -> approuverModification(demande);
            case SUPPRESSION  -> approuverSuppression(demande);
            case ACTIVATION   -> approuverActivation(demande);
            case DESACTIVATION -> approuverDesactivation(demande);
        }

        demande.setStatut(StatutDemandeEnum.APPROUVEE);
        demande.setTraiteePar(validateurId);
        demande.setDateTraitement(LocalDateTime.now());
        demandeRepository.save(demande);

        moteurDroolsService.rechargerMoteur();

        journalService.journaliser(validateurId, "APPROBATION_DEMANDE",
                "Demande #" + demandeId + " (" + demande.getType() + ") approuvee - Regle : "
                        + demande.getNomRegleHistorique());
        return DemandeResponse.fromEntity(demande);
    }

    // --- Rejet ---

    @Transactional
    public DemandeResponse rejeter(Long demandeId, String motifRejet, Long validateurId) {
        DemandeValidation demande = trouverDemande(demandeId);
        verifierEnAttente(demande);

        RegleDetection regle = demande.getRegle();
        if (regle != null) {
            StatutRegleEnum statutApresRejet = switch (demande.getType()) {
                case CREATION              -> StatutRegleEnum.REJETEE;
                case MODIFICATION,
                     DESACTIVATION,
                     SUPPRESSION           -> StatutRegleEnum.ACTIVE;
                case ACTIVATION            -> StatutRegleEnum.INACTIVE;
            };
            regle.setStatut(statutApresRejet);
            regleRepository.save(regle);
        }

        if (demande.getVersionRegle() != null) {
            VersionRegle version = demande.getVersionRegle();
            version.setStatut(StatutVersionEnum.REJETEE);
            versionRegleRepository.save(version);
        }

        demande.setStatut(StatutDemandeEnum.REJETEE);
        demande.setMotifRejet(motifRejet);
        demande.setTraiteePar(validateurId);
        demande.setDateTraitement(LocalDateTime.now());
        demandeRepository.save(demande);

        journalService.journaliser(validateurId, "REJET_DEMANDE",
                "Demande #" + demandeId + " (" + demande.getType() + ") rejetee - Regle : "
                        + demande.getNomRegleHistorique() + " - Motif : " + motifRejet);
        return DemandeResponse.fromEntity(demande);
    }

    // --- Logique d'approbation par type ---

    private void approuverCreation(DemandeValidation demande) {
        demande.getRegle().setStatut(StatutRegleEnum.ACTIVE);
        regleRepository.save(demande.getRegle());

        VersionRegle v = demande.getVersionRegle();
        v.setStatut(StatutVersionEnum.ACTIVE);
        v.setEstActive(true);
        versionRegleRepository.save(v);
    }

    private void approuverModification(DemandeValidation demande) {
        versionRegleRepository.findByRegleIdAndEstActiveTrue(demande.getRegle().getId())
                .ifPresent(ancienne -> {
                    ancienne.setEstActive(false);
                    ancienne.setStatut(StatutVersionEnum.REMPLACEE);
                    versionRegleRepository.save(ancienne);
                });

        VersionRegle nouvelle = demande.getVersionRegle();
        nouvelle.setEstActive(true);
        nouvelle.setStatut(StatutVersionEnum.ACTIVE);
        versionRegleRepository.save(nouvelle);

        demande.getRegle().setStatut(StatutRegleEnum.ACTIVE);
        regleRepository.save(demande.getRegle());
    }

    private void approuverSuppression(DemandeValidation demandeCourante) {
    RegleDetection regle = demandeCourante.getRegle();
    if (regle == null) return;

    List<DemandeValidation> demandesLiees = demandeRepository.findAll().stream()
            .filter(d -> d.getRegle() != null && d.getRegle().getId().equals(regle.getId()))
            .toList();

    for (DemandeValidation d : demandesLiees) {
        d.setVersionRegle(null);
        d.setRegle(null);
        demandeRepository.save(d);
    }

    regleRepository.delete(regle);
}

    private void approuverActivation(DemandeValidation demande) {
        demande.getRegle().setStatut(StatutRegleEnum.ACTIVE);
        regleRepository.save(demande.getRegle());
    }

    private void approuverDesactivation(DemandeValidation demande) {
        demande.getRegle().setStatut(StatutRegleEnum.INACTIVE);
        regleRepository.save(demande.getRegle());
    }

    // --- Helpers ---

    private DemandeValidation trouverDemande(Long id) {
        return demandeRepository.findById(id)
                .orElseThrow(() -> new RessourceNotFoundException("Demande introuvable."));
    }

    private void verifierEnAttente(DemandeValidation demande) {
        if (demande.getStatut() != StatutDemandeEnum.EN_ATTENTE)
            throw new CompteException("Cette demande a deja ete traitee.");
    }
}