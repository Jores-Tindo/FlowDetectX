package com.imf.detection.flowdetectx.service;

import com.imf.detection.flowdetectx.dto.response.JournalActiviteResponse;
import com.imf.detection.flowdetectx.model.JournalActivite;
import com.imf.detection.flowdetectx.model.Utilisateur;
import com.imf.detection.flowdetectx.repository.JournalActiviteRepository;
import com.imf.detection.flowdetectx.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class JournalService {

    private final JournalActiviteRepository journalActiviteRepository;
    private final UtilisateurRepository utilisateurRepository;

    public void journaliser(Long utilisateurId, String action, String details) {
        JournalActivite entree = JournalActivite.builder()
                .utilisateurId(utilisateurId)
                .action(action)
                .details(details)
                .horodatage(LocalDateTime.now())
                .build();
        journalActiviteRepository.save(entree);
    }

    public List<JournalActiviteResponse> listerTout() {
        return resoudreUtilisateurs(journalActiviteRepository.findAllByOrderByHorodatageDesc());
    }

    public List<JournalActiviteResponse> listerParUtilisateur(Long utilisateurId) {
        return resoudreUtilisateurs(
                journalActiviteRepository.findByUtilisateurIdOrderByHorodatageDesc(utilisateurId));
    }

    /**
     * Resout en UNE seule requete (findAllById) les utilisateurs de toutes
     * les entrees du journal, pour eviter une requete SQL par ligne
     * (probleme N+1) sur des journaux qui peuvent contenir des centaines
     * d'entrees.
     */
    private List<JournalActiviteResponse> resoudreUtilisateurs(List<JournalActivite> entrees) {
        List<Long> ids = entrees.stream()
                .map(JournalActivite::getUtilisateurId)
                .filter(id -> id != null)
                .distinct()
                .toList();

        Map<Long, Utilisateur> utilisateursParId = utilisateurRepository.findAllById(ids).stream()
                .collect(Collectors.toMap(Utilisateur::getId, u -> u));

        return entrees.stream()
                .map(e -> JournalActiviteResponse.fromEntity(e, utilisateursParId.get(e.getUtilisateurId())))
                .toList();
    }
}