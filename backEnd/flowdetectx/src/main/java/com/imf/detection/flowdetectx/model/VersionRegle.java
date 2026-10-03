package com.imf.detection.flowdetectx.model;

import com.imf.detection.flowdetectx.model.enums.StatutVersionEnum;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Represente une version specifique d'une RegleDetection.
 *
 * Mecanisme central de versioning : a chaque modification soumise par
 * l'utilisateur metier, une nouvelle VersionRegle est creee avec
 * estActive = false et statut = EN_ATTENTE, SANS desactiver la version
 * actuellement active. Ce n'est qu'apres approbation du Validateur que :
 *  - l'ancienne version passe estActive = false, statut = REMPLACEE
 *  - la nouvelle version passe estActive = true, statut = ACTIVE
 *
 * Cela garantit la continuite du service (BNF-03).
 */
@Entity
@Table(name = "versions_regle")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VersionRegle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "regle_id", nullable = false)
    private RegleDetection regle;

    @Column(name = "numero_version", nullable = false)
    private int numeroVersion;

    /**
     * Description structuree des conditions de la regle, saisie par
     * l'utilisateur metier (avant generation du DRL).
     */
    @Lob
    @Column(nullable = false, columnDefinition = "TEXT")
    private String conditions;

    /**
     * Code DRL genere a partir des conditions, compile dynamiquement
     * par le MoteurDroolsService apres approbation.
     */
    @Lob
    @Column(name = "contenu_drl", columnDefinition = "LONGTEXT")
    private String contenuDrl;

    @Column(name = "est_active", nullable = false)
    private boolean estActive;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutVersionEnum statut;

    @Column(name = "date_creation", nullable = false)
    private LocalDateTime dateCreation;

    @PrePersist
    protected void onCreate() {
        if (this.dateCreation == null) {
            this.dateCreation = LocalDateTime.now();
        }
    }
}
