package com.imf.detection.flowdetectx.model;

import com.imf.detection.flowdetectx.model.enums.StatutSimulationEnum;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Represente une session de simulation temps reel basee sur le
 * Simulateur PaySim (CU-08).
 *
 * Pendant la simulation, le MoteurDrools analyse chaque transaction
 * recue. Les metriques de performance (precision, rappel, F1-score)
 * sont calculees en temps reel, sans stockage massif des transactions :
 * seules les transactions ayant genere au moins une alerte sont
 * persistees (cf. table transactions).
 */
@Entity
@Table(name = "simulations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Simulation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "utilisateur_id", nullable = false)
    private Long utilisateurId;

    @Column(name = "date_debut", nullable = false)
    private LocalDateTime dateDebut;

    @Column(name = "date_fin")
    private LocalDateTime dateFin;

    @Column(name = "nb_transactions_traitees", nullable = false)
    @Builder.Default
    private long nbTransactionsTraitees = 0L;

    @Column(name = "nb_alertes", nullable = false)
    @Builder.Default
    private long nbAlertes = 0L;

    @Column(name = "vrais_positifs", nullable = false)
    @Builder.Default
    private long vraisPositifs = 0L;

    @Column(name = "faux_positifs", nullable = false)
    @Builder.Default
    private long fauxPositifs = 0L;

    @Column(name = "faux_negatifs", nullable = false)
    @Builder.Default
    private long fauxNegatifs = 0L;

    @Column(name = "vrais_negatifs", nullable = false)
    @Builder.Default
    private long vraisNegatifs = 0L;

    @Column(name = "taux_faux_positifs")
    private Double tauxFauxPositifs;

    @Column(name = "precision_score")
    private Double precisionScore;

    @Column(name = "rappel_score")
    private Double rappelScore;

    @Column(name = "f1_score")
    private Double f1Score;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutSimulationEnum statut;

    @PrePersist
    protected void onCreate() {
        if (this.dateDebut == null) {
            this.dateDebut = LocalDateTime.now();
        }
        if (this.statut == null) {
            this.statut = StatutSimulationEnum.EN_COURS;
        }
    }
}
