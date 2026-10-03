package com.imf.detection.flowdetectx.service;

import com.imf.detection.flowdetectx.dto.response.UtilisateurResponse;
import com.imf.detection.flowdetectx.exception.CompteException;
import com.imf.detection.flowdetectx.exception.RessourceNotFoundException;
import com.imf.detection.flowdetectx.model.Utilisateur;
import com.imf.detection.flowdetectx.model.enums.RoleEnum;
import com.imf.detection.flowdetectx.model.enums.StatutCompteEnum;
import com.imf.detection.flowdetectx.repository.DemandeValidationRepository;
import com.imf.detection.flowdetectx.repository.JournalActiviteRepository;
import com.imf.detection.flowdetectx.repository.RegleDetectionRepository;
import com.imf.detection.flowdetectx.repository.SimulationRepository;
import com.imf.detection.flowdetectx.repository.TokenActivationRepository;
import com.imf.detection.flowdetectx.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UtilisateurService {

    private final UtilisateurRepository utilisateurRepository;
    private final DemandeValidationRepository demandeValidationRepository;
    private final SimulationRepository simulationRepository;
    private final JournalActiviteRepository journalActiviteRepository;
    private final TokenActivationRepository tokenActivationRepository;
    private final RegleDetectionRepository regleDetectionRepository;

    public List<UtilisateurResponse> listerTous() {
        return utilisateurRepository.findAll().stream()
                .map(UtilisateurResponse::fromEntity)
                .toList();
    }

    public List<UtilisateurResponse> listerParRole(RoleEnum role) {
        return utilisateurRepository.findByRole(role).stream()
                .map(UtilisateurResponse::fromEntity)
                .toList();
    }

    public UtilisateurResponse obtenirParId(Long id) {
        return UtilisateurResponse.fromEntity(trouverParId(id));
    }

    @Transactional
    public void suspendre(Long id, Long adminConnecteId) {
        if (id.equals(adminConnecteId)) {
            throw new CompteException("Vous ne pouvez pas suspendre votre propre compte.");
        }

        Utilisateur utilisateur = trouverParId(id);

        if (utilisateur.getStatut() != StatutCompteEnum.ACTIF) {
            throw new CompteException("Seul un compte actif peut etre suspendu.");
        }

        utilisateur.setStatut(StatutCompteEnum.SUSPENDU);
        utilisateurRepository.save(utilisateur);
    }

    @Transactional
    public void reactiver(Long id) {
        Utilisateur utilisateur = trouverParId(id);

        if (utilisateur.getStatut() != StatutCompteEnum.SUSPENDU) {
            throw new CompteException("Seul un compte suspendu peut etre reactive.");
        }

        utilisateur.setStatut(StatutCompteEnum.ACTIF);
        utilisateurRepository.save(utilisateur);
    }

    @Transactional
    public void supprimer(Long id) {
        if (utilisateurRepository.existsByCreePar(id)) {
            throw new CompteException("Impossible de supprimer ce compte car il a cree des utilisateurs lies.");
        }
        if (regleDetectionRepository.existsByCreePar(id)) {
            throw new CompteException("Impossible de supprimer ce compte car il a cree des regles de detection liees.");
        }

        Utilisateur utilisateur = trouverParId(id);
        journalActiviteRepository.deleteByUtilisateurId(id);
        demandeValidationRepository.deleteByTraiteePar(id);
        demandeValidationRepository.deleteBySoumisePar(id);
        tokenActivationRepository.deleteByUtilisateurId(id);
        simulationRepository.deleteByUtilisateurId(id);

        try {
            utilisateurRepository.delete(utilisateur);
        } catch (DataIntegrityViolationException ex) {
            throw new CompteException("Impossible de supprimer ce compte tant que des donnees associees existent.");
        }
    }

    private Utilisateur trouverParId(Long id) {
        return utilisateurRepository.findById(id)
                .orElseThrow(() -> new RessourceNotFoundException("Utilisateur introuvable."));
    }
}