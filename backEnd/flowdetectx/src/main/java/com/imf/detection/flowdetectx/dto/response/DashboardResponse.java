package com.imf.detection.flowdetectx.dto.response;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DashboardResponse {

    private long totalReglesActives;
    private long totalReglesEnAttente;
    private long totalDemandesEnAttente;
    private long totalSimulations;
    private long totalAlertes;
    private Double dernierePrecision;
    private Double dernierRappel;
    private Double dernierF1;
    private Double tauxFauxPositifs;
    private long vraisPositifs;
    private long fauxPositifs;
    private long fauxNegatifs;
    private long vraisNegatifs;
    private long totalTransactions;
}