package com.imf.detection.flowdetectx.dto.response;

import com.imf.detection.flowdetectx.model.JournalActivite;
import com.imf.detection.flowdetectx.model.Utilisateur;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
@AllArgsConstructor
public class JournalActiviteResponse {

    private Long id;
    private String action;
    private String details;

    /**
     * Libelle du role de l'auteur de l'action (ex: "Validateur"),
     * ou "Systeme" si l'utilisateur n'a pas pu etre resolu
     * (action automatique, ou compte supprime depuis).
     */
    private String utilisateurRole;

    private LocalDateTime horodatage;

    public static JournalActiviteResponse fromEntity(JournalActivite entite, Utilisateur utilisateur) {
        return JournalActiviteResponse.builder()
                .id(entite.getId())
                .action(entite.getAction())
                .details(entite.getDetails())
                .horodatage(entite.getHorodatage())
                .utilisateurRole(libelleRole(utilisateur))
                .build();
    }

    private static String libelleRole(Utilisateur utilisateur) {
        if (utilisateur == null || utilisateur.getRole() == null) {
            return "Systeme";
        }
        // Comparaison sur le nom brut de l'enum : si les constantes reelles
        // de RoleEnum different de celles supposees ici, ca degrade
        // proprement (affiche le nom brut) au lieu de planter a la
        // compilation.
        return switch (utilisateur.getRole().name()) {
            case "ADMINISTRATEUR" -> "Administrateur";
            case "VALIDATEUR" -> "Validateur";
            case "UTILISATEUR_METIER" -> "Utilisateur metier";
            default -> utilisateur.getRole().name();
        };
    }
}