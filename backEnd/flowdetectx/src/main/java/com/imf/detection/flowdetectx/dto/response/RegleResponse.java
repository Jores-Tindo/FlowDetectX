package com.imf.detection.flowdetectx.dto.response;

import com.imf.detection.flowdetectx.model.RegleDetection;
import com.imf.detection.flowdetectx.model.enums.CriticiteEnum;
import com.imf.detection.flowdetectx.model.enums.StatutRegleEnum;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RegleResponse {

    private Long id;
    private String nom;
    private String description;
    private CriticiteEnum criticite;
    private StatutRegleEnum statut;
    private boolean estReglementaire;
    private Long creePar;
    private LocalDateTime dateCreation;

    /** Null si aucune version active (ex : regle EN_ATTENTE de creation). */
    private VersionRegleResponse versionActive;

    public static RegleResponse fromEntity(RegleDetection r) {
        return RegleResponse.builder()
                .id(r.getId())
                .nom(r.getNom())
                .description(r.getDescription())
                .criticite(r.getCriticite())
                .statut(r.getStatut())
                .estReglementaire(r.isEstReglementaire())
                .creePar(r.getCreePar())
                .dateCreation(r.getDateCreation())
                .versionActive(r.getVersionActive() != null
                        ? VersionRegleResponse.fromEntity(r.getVersionActive())
                        : null)
                .build();
    }
}