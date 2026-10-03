package com.imf.detection.flowdetectx.dto.response;

import com.imf.detection.flowdetectx.model.VersionRegle;
import com.imf.detection.flowdetectx.model.enums.StatutVersionEnum;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class VersionRegleResponse {

    private Long id;
    private int numeroVersion;
    private String conditions;
    private String contenuDrl;
    private StatutVersionEnum statut;
    private boolean estActive;
    private LocalDateTime dateCreation;

    public static VersionRegleResponse fromEntity(VersionRegle v) {
        return VersionRegleResponse.builder()
                .id(v.getId())
                .numeroVersion(v.getNumeroVersion())
                .conditions(v.getConditions())
                .contenuDrl(v.getContenuDrl())
                .statut(v.getStatut())
                .estActive(v.isEstActive())
                .dateCreation(v.getDateCreation())
                .build();
    }
}