package com.imf.detection.flowdetectx.dto.response;

import com.imf.detection.flowdetectx.model.DemandeValidation;
import com.imf.detection.flowdetectx.model.VersionRegle;
import com.imf.detection.flowdetectx.model.enums.StatutDemandeEnum;
import com.imf.detection.flowdetectx.model.enums.TypeDemandeEnum;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DemandeResponse {

    private Long id;
    private TypeDemandeEnum type;

    /** Null si la regle a ete supprimee — nomRegleHistorique conserve le nom. */
    private Long regleId;

    /** Snapshot du nom au moment de la soumission — persiste apres suppression. */
    private String nomRegleHistorique;

    private Long versionRegleId;
    private StatutDemandeEnum statut;
    private String motifRejet;
    private Long soumisePar;
    private Long traiteePar;
    private LocalDateTime dateCreation;
    private LocalDateTime dateTraitement;
    private String motifDemande;
   private String criticite;
private String conditions;
private String contenuDrl;
private Integer numeroVersion;

public static DemandeResponse fromEntity(DemandeValidation d, VersionRegle versionActive) {
    VersionRegle versionAAfficher = d.getVersionRegle() != null ? d.getVersionRegle() : versionActive;

    return DemandeResponse.builder()
            .id(d.getId())
            .type(d.getType())
            .regleId(d.getRegle() != null ? d.getRegle().getId() : null)
            .nomRegleHistorique(d.getNomRegleHistorique())
            .versionRegleId(d.getVersionRegle() != null ? d.getVersionRegle().getId() : null)
            .statut(d.getStatut())
            .motifRejet(d.getMotifRejet())
            .soumisePar(d.getSoumisePar())
            .traiteePar(d.getTraiteePar())
            .dateCreation(d.getDateCreation())
            .dateTraitement(d.getDateTraitement())
            .motifDemande(d.getMotifDemande())
            .criticite(d.getRegle() != null ? d.getRegle().getCriticite().toString() : null)
            .conditions(versionAAfficher != null ? versionAAfficher.getConditions() : null)
            .contenuDrl(versionAAfficher != null ? versionAAfficher.getContenuDrl() : null)
            .numeroVersion(versionAAfficher != null ? versionAAfficher.getNumeroVersion() : null)
            .build();
}

public static DemandeResponse fromEntity(DemandeValidation d) {
    return fromEntity(d, null);
}
}