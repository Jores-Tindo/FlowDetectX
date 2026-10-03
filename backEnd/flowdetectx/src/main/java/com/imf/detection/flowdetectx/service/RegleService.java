package com.imf.detection.flowdetectx.service;

import com.imf.detection.flowdetectx.dto.request.CreationRegleRequest;
import com.imf.detection.flowdetectx.dto.request.ModificationRegleRequest;
import com.imf.detection.flowdetectx.dto.response.DemandeResponse;
import com.imf.detection.flowdetectx.dto.response.RegleResponse;
import com.imf.detection.flowdetectx.dto.response.VersionRegleResponse;
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
import java.util.List;

@Service
@RequiredArgsConstructor
public class RegleService {

    private final RegleDetectionRepository regleRepository;
    private final VersionRegleRepository versionRegleRepository;
    private final DemandeValidationRepository demandeRepository;
    private final JournalService journalService;

    // --- Consultation ---

        @Transactional(readOnly = true)
    public List<RegleResponse> listerRegles() {
        return regleRepository.findAll().stream()
                .map(RegleResponse::fromEntity).toList();
    }

        @Transactional(readOnly = true)
    public RegleResponse obtenirRegle(Long id) {
        return RegleResponse.fromEntity(trouverRegle(id));
    }

    public List<VersionRegleResponse> listerVersions(Long regleId) {
        trouverRegle(regleId);
        return versionRegleRepository.findByRegleIdOrderByNumeroVersionDesc(regleId).stream()
                .map(VersionRegleResponse::fromEntity).toList();
    }

    // --- Soumissions ---

    @Transactional
    public DemandeResponse soumettreCreation(CreationRegleRequest dto, Long utilisateurId) {
        RegleDetection regle = regleRepository.save(RegleDetection.builder()
                .nom(dto.getNom()).description(dto.getDescription())
                .criticite(dto.getCriticite()).statut(StatutRegleEnum.EN_ATTENTE)
                .estReglementaire(false).creePar(utilisateurId).build());

        VersionRegle version = versionRegleRepository.save(VersionRegle.builder()
                .regle(regle).numeroVersion(1).conditions(dto.getConditions())
                .contenuDrl(dto.getContenuDrl()).estActive(false)
                .statut(StatutVersionEnum.EN_ATTENTE).build());

        DemandeValidation demande = demandeRepository.save(DemandeValidation.builder()
        .type(TypeDemandeEnum.CREATION).regle(regle)
        .nomRegleHistorique(regle.getNom()).versionRegle(version)
        .motifDemande("Création d'une nouvelle règle : " + regle.getNom())
        .statut(StatutDemandeEnum.EN_ATTENTE).soumisePar(utilisateurId).build());

        journalService.journaliser(utilisateurId, "SOUMISSION_CREATION",
                "Demande de creation de la regle : " + regle.getNom());
        return DemandeResponse.fromEntity(demande);
    }

    @Transactional
    public DemandeResponse soumettreModification(Long regleId, ModificationRegleRequest dto, Long utilisateurId) {
        RegleDetection regle = trouverRegle(regleId);
        verifierPasDeDemandeEnCours(regle);

        List<VersionRegle> versions = versionRegleRepository.findByRegleIdOrderByNumeroVersionDesc(regleId);
        int prochainNumero = versions.isEmpty() ? 1 : versions.get(0).getNumeroVersion() + 1;

        if (dto.getDescription() != null && !dto.getDescription().isBlank()) {
            regle.setDescription(dto.getDescription());
        }
        regle.setStatut(StatutRegleEnum.EN_ATTENTE);
        regleRepository.save(regle);

        VersionRegle nouvelleVersion = versionRegleRepository.save(VersionRegle.builder()
                .regle(regle).numeroVersion(prochainNumero).conditions(dto.getConditions())
                .contenuDrl(dto.getContenuDrl()).estActive(false)
                .statut(StatutVersionEnum.EN_ATTENTE).build());

        DemandeValidation demande = demandeRepository.save(DemandeValidation.builder()
        .type(TypeDemandeEnum.MODIFICATION).regle(regle)
        .nomRegleHistorique(regle.getNom()).versionRegle(nouvelleVersion)
        .motifDemande("Modification de la règle : " + regle.getNom() + " (version " + prochainNumero + ")")
        .statut(StatutDemandeEnum.EN_ATTENTE).soumisePar(utilisateurId).build());

        journalService.journaliser(utilisateurId, "SOUMISSION_MODIFICATION",
                "Demande de modification de la regle : " + regle.getNom() + " (v" + prochainNumero + ")");
        return DemandeResponse.fromEntity(demande);
    }

    @Transactional
    public DemandeResponse soumettreSuppression(Long regleId, Long utilisateurId) {
        RegleDetection regle = trouverRegle(regleId);
        if (regle.isEstReglementaire())
            throw new CompteException("Une regle reglementaire ne peut pas etre supprimee.");
        verifierPasDeDemandeEnCours(regle);

        regle.setStatut(StatutRegleEnum.EN_ATTENTE);
        regleRepository.save(regle);

        DemandeValidation demande = demandeRepository.save(DemandeValidation.builder()
        .type(TypeDemandeEnum.SUPPRESSION).regle(regle)
        .nomRegleHistorique(regle.getNom())
        .motifDemande("Suppression de la règle : " + regle.getNom())
        .statut(StatutDemandeEnum.EN_ATTENTE).soumisePar(utilisateurId).build());

        journalService.journaliser(utilisateurId, "SOUMISSION_SUPPRESSION",
                "Demande de suppression de la regle : " + regle.getNom());
        return DemandeResponse.fromEntity(demande);
    }

    @Transactional
    public DemandeResponse soumettreActivation(Long regleId, Long utilisateurId) {
        RegleDetection regle = trouverRegle(regleId);
        if (regle.getStatut() != StatutRegleEnum.INACTIVE)
            throw new CompteException("Seule une regle inactive peut etre soumise a une demande d'activation.");
        verifierPasDeDemandeEnCours(regle);

        regle.setStatut(StatutRegleEnum.EN_ATTENTE);
        regleRepository.save(regle);

        DemandeValidation demande = demandeRepository.save(DemandeValidation.builder()
        .type(TypeDemandeEnum.ACTIVATION).regle(regle)
        .nomRegleHistorique(regle.getNom())
        .motifDemande("Demande d'activation de la règle : " + regle.getNom())
        .statut(StatutDemandeEnum.EN_ATTENTE).soumisePar(utilisateurId).build());

        journalService.journaliser(utilisateurId, "SOUMISSION_ACTIVATION",
                "Demande d'activation de la regle : " + regle.getNom());
        return DemandeResponse.fromEntity(demande);
    }

    @Transactional
    public DemandeResponse soumettreDesactivation(Long regleId, Long utilisateurId) {
        RegleDetection regle = trouverRegle(regleId);
        if (regle.getStatut() != StatutRegleEnum.ACTIVE)
            throw new CompteException("Seule une regle active peut etre soumise a une demande de desactivation.");
        verifierPasDeDemandeEnCours(regle);

        regle.setStatut(StatutRegleEnum.EN_ATTENTE);
        regleRepository.save(regle);

        DemandeValidation demande = demandeRepository.save(DemandeValidation.builder()
        .type(TypeDemandeEnum.DESACTIVATION).regle(regle)
        .nomRegleHistorique(regle.getNom())
        .motifDemande("Demande de désactivation de la règle : " + regle.getNom())
        .statut(StatutDemandeEnum.EN_ATTENTE).soumisePar(utilisateurId).build());

        journalService.journaliser(utilisateurId, "SOUMISSION_DESACTIVATION",
                "Demande de desactivation de la regle : " + regle.getNom());
        return DemandeResponse.fromEntity(demande);
    }

    // --- Helpers ---

    private RegleDetection trouverRegle(Long id) {
        return regleRepository.findById(id)
                .orElseThrow(() -> new RessourceNotFoundException("Regle introuvable."));
    }

    private void verifierPasDeDemandeEnCours(RegleDetection regle) {
        if (regle.getStatut() == StatutRegleEnum.EN_ATTENTE)
            throw new CompteException("Une demande est deja en attente de validation pour cette regle.");
    }
}