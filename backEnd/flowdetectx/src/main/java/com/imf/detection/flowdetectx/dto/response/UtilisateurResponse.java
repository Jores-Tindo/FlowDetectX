package com.imf.detection.flowdetectx.dto.response;

import com.imf.detection.flowdetectx.model.Utilisateur;
import com.imf.detection.flowdetectx.model.enums.RoleEnum;
import com.imf.detection.flowdetectx.model.enums.StatutCompteEnum;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UtilisateurResponse {

    private Long id;
    private String nom;
    private String prenom;
    private String email;
    private String identifiant;
    private RoleEnum role;
    private StatutCompteEnum statut;
    private LocalDateTime dateCreation;

    public static UtilisateurResponse fromEntity(Utilisateur u) {
        return UtilisateurResponse.builder()
                .id(u.getId())
                .nom(u.getNom())
                .prenom(u.getPrenom())
                .email(u.getEmail())
                .identifiant(u.getIdentifiant())
                .role(u.getRole())
                .statut(u.getStatut())
                .dateCreation(u.getDateCreation())
                .build();
    }
}