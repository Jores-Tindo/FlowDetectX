package com.imf.detection.flowdetectx.controller;

import com.imf.detection.flowdetectx.dto.response.DashboardResponse;
import com.imf.detection.flowdetectx.model.Simulation;
import com.imf.detection.flowdetectx.model.enums.StatutDemandeEnum;
import com.imf.detection.flowdetectx.model.enums.StatutRegleEnum;
import com.imf.detection.flowdetectx.model.enums.StatutSimulationEnum;
import com.imf.detection.flowdetectx.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final RegleDetectionRepository regleRepository;
    private final DemandeValidationRepository demandeRepository;
    private final SimulationRepository simulationRepository;
    private final AlerteRepository alerteRepository;

    @GetMapping
    public ResponseEntity<DashboardResponse> dashboard() {
        long reglesActives    = regleRepository.findByStatut(StatutRegleEnum.ACTIVE).size();
        long reglesEnAttente  = regleRepository.findByStatut(StatutRegleEnum.EN_ATTENTE).size();
        long demandesEnAttente = demandeRepository.findByStatut(StatutDemandeEnum.EN_ATTENTE).size();
        long totalSimulations = simulationRepository.count();
        long totalAlertes     = alerteRepository.count();

        Double precision = null, rappel = null, f1 = null, tauxFP = null;
        long vp = 0, fp = 0, fn = 0, vn = 0, totalTx = 0;

        List<Simulation> toutes = simulationRepository.findAll();
        Simulation derniere = toutes.stream()
                .filter(s -> s.getStatut() == StatutSimulationEnum.TERMINEE)
                .reduce((a, b) -> a.getDateDebut().isAfter(b.getDateDebut()) ? a : b)
                .orElse(null);

        if (derniere != null) {
            precision = derniere.getPrecisionScore();
            rappel    = derniere.getRappelScore();
            f1        = derniere.getF1Score();
            tauxFP    = derniere.getTauxFauxPositifs();
            vp        = derniere.getVraisPositifs();
            fp        = derniere.getFauxPositifs();
            fn        = derniere.getFauxNegatifs();
            vn        = derniere.getVraisNegatifs();
            totalTx   = derniere.getNbTransactionsTraitees();
        }

        return ResponseEntity.ok(DashboardResponse.builder()
                .totalReglesActives(reglesActives)
                .totalReglesEnAttente(reglesEnAttente)
                .totalDemandesEnAttente(demandesEnAttente)
                .totalSimulations(totalSimulations)
                .totalAlertes(totalAlertes)
                .dernierePrecision(precision)
                .dernierRappel(rappel)
                .dernierF1(f1)
                .tauxFauxPositifs(tauxFP)
                .vraisPositifs(vp)
                .fauxPositifs(fp)
                .fauxNegatifs(fn)
                .vraisNegatifs(vn)
                .totalTransactions(totalTx)
                .build());
    }
}