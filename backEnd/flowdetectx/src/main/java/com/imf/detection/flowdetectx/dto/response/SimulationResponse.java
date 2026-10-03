package com.imf.detection.flowdetectx.dto.response;

import com.imf.detection.flowdetectx.model.Simulation;
import com.imf.detection.flowdetectx.model.enums.StatutSimulationEnum;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SimulationResponse {

    private Long id;
    private Long utilisateurId;
    private LocalDateTime dateDebut;
    private LocalDateTime dateFin;
    private long nbTransactionsTraitees;
    private long nbAlertes;
    private long vraisPositifs;
    private long fauxPositifs;
    private long fauxNegatifs;
    private Double precisionScore;
    private Double rappelScore;
    private Double f1Score;
    private StatutSimulationEnum statut;

    public static SimulationResponse fromEntity(Simulation s) {
        return SimulationResponse.builder()
                .id(s.getId())
                .utilisateurId(s.getUtilisateurId())
                .dateDebut(s.getDateDebut())
                .dateFin(s.getDateFin())
                .nbTransactionsTraitees(s.getNbTransactionsTraitees())
                .nbAlertes(s.getNbAlertes())
                .vraisPositifs(s.getVraisPositifs())
                .fauxPositifs(s.getFauxPositifs())
                .fauxNegatifs(s.getFauxNegatifs())
                .precisionScore(s.getPrecisionScore())
                .rappelScore(s.getRappelScore())
                .f1Score(s.getF1Score())
                .statut(s.getStatut())
                .build();
    }
}