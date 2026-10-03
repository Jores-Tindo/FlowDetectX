package com.imf.detection.flowdetectx.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Represente une transaction financiere issue du flux PaySim et
 * analysee par le MoteurDrools.
 *
 * IMPORTANT : conformement a la mesure de securite 2.3.2.7 (minimisation
 * de l'exposition des donnees financieres), SEULES les transactions ayant
 * declenche au moins une regle (donc associees a une Alerte) sont
 * persistees en base. Les transactions normales ne sont jamais stockees ;
 * elles sont uniquement utilisees en memoire pour le calcul en temps reel
 * des metriques de performance (EvaluationService).
 */
@Entity
@Table(name = "transactions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "simulation_id", nullable = false)
    private Simulation simulation;

    /** Correspond au champ "step" du dataset PaySim (unite de temps). */
    @Column(nullable = false)
    private int step;

    /** Type de transaction PaySim : CASH_IN, CASH_OUT, DEBIT, PAYMENT, TRANSFER. */
    @Column(nullable = false, length = 20)
    private String type;

    @Column(nullable = false)
    private double montant;

    @Column(name = "nom_client", nullable = false, length = 50)
    private String nomClient;

    @Column(name = "solde_avant_client", nullable = false)
    private double soldeAvantClient;

    @Column(name = "solde_apres_client", nullable = false)
    private double soldeApresClient;

    @Column(name = "nom_destinataire", length = 50)
    private String nomDestinataire;

    @Column(name = "solde_avant_dest")
    private Double soldeAvantDest;

    @Column(name = "solde_apres_dest")
    private Double soldeApresDest;

    /** Verite terrain PaySim : indique si la transaction est reellement frauduleuse. */
    @Column(name = "est_fraude", nullable = false)
    private boolean estFraude;

    @Column(name = "date_enregistrement", nullable = false)
private java.util.Date dateEnregistrement;

    @PrePersist
    protected void onCreate() {
        if (this.dateEnregistrement == null) {
            this.dateEnregistrement = new java.util.Date();
        }
    }
}
