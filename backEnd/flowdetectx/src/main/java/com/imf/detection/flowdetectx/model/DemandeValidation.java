package com.imf.detection.flowdetectx.model;

import com.imf.detection.flowdetectx.model.enums.StatutDemandeEnum;
import com.imf.detection.flowdetectx.model.enums.TypeDemandeEnum;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Represente une demande de gestion d'une regle de detection soumise
 * par un Utilisateur metier et necessitant l'approbation d'un Validateur.
 *
 * Toute action sur une regle - hors consultation - genere une
 * DemandeValidation : creation, modification, suppression, activation
 * ou desactivation (cf. CU-03 a CU-07).
 *
 * Pour CREATION et MODIFICATION, versionRegle reference la nouvelle
 * VersionRegle (statut EN_ATTENTE) concernee par la demande (0..1).
 * Pour SUPPRESSION, ACTIVATION, DESACTIVATION, versionRegle peut etre null :
 * ces demandes portent directement sur la RegleDetection.
 */
@Entity
@Table(name = "demandes_validation")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DemandeValidation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TypeDemandeEnum type;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "regle_id", nullable = true)
    private RegleDetection regle;
    @Column(name = "nom_regle_historique", nullable = false, length = 255)
    private String nomRegleHistorique;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "version_regle_id")
    private VersionRegle versionRegle;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutDemandeEnum statut;

    @Lob
    @Column(name = "motif_demande", columnDefinition = "TEXT")
    private String motifDemande;
        
    @Lob
    @Column(name = "motif_rejet", columnDefinition = "TEXT")
    private String motifRejet;

    @Column(name = "soumise_par", nullable = false)
    private Long soumisePar;

    @Column(name = "traitee_par")
    private Long traiteePar;

    @Column(name = "date_creation", nullable = false)
    private LocalDateTime dateCreation;

    @Column(name = "date_traitement")
    private LocalDateTime dateTraitement;

    @PrePersist
    protected void onCreate() {
        if (this.dateCreation == null) {
            this.dateCreation = LocalDateTime.now();
        }
        if (this.statut == null) {
            this.statut = StatutDemandeEnum.EN_ATTENTE;
        }
    }
}
