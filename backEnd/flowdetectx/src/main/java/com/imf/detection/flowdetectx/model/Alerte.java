package com.imf.detection.flowdetectx.model;

import com.imf.detection.flowdetectx.model.enums.CriticiteEnum;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Represente une alerte generee par le MoteurDrools lorsqu'une
 * VersionRegle active est declenchee par une Transaction.
 *
 * Chaque Alerte est rattachee a la Simulation en cours (pour le calcul
 * de nbAlertes) et a la Transaction qui l'a declenchee. Conservee
 * definitivement dans l'historique (CU-09, CU-10).
 */
@Entity
@Table(name = "alertes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Alerte {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "simulation_id", nullable = false)
    private Simulation simulation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transaction_id", nullable = false)
    private Transaction transaction;

    @Column(name = "regle_nom", nullable = false, length = 200)
    private String regleNom;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CriticiteEnum criticite;

    @Lob
    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private LocalDateTime horodatage;

    @PrePersist
    protected void onCreate() {
        if (this.horodatage == null) {
            this.horodatage = LocalDateTime.now();
        }
    }
}
