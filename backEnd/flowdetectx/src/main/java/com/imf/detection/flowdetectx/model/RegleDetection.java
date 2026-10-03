package com.imf.detection.flowdetectx.model;

import com.imf.detection.flowdetectx.model.enums.CriticiteEnum;
import com.imf.detection.flowdetectx.model.enums.StatutRegleEnum;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Represente une regle de detection geree par le systeme.
 *
 * Les 6 regles par defaut (estReglementaire = true) sont issues des
 * typologies documentees par la CENTIF-BJ, le GIABA, l'ANSSFD, la BCEAO
 * (Instruction N 233/07/2024) et la Loi Uniforme LBC/FT de l'UMOA.
 *
 * Une RegleDetection possede toujours au moins une VersionRegle (1..*).
 * La version dont estActive = true est celle chargee dans le moteur Drools.
 */
@Entity
@Table(name = "regles_detection")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegleDetection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String nom;

    @Lob
    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CriticiteEnum criticite;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutRegleEnum statut;

    @Column(name = "est_reglementaire", nullable = false)
    private boolean estReglementaire;

    @Column(name = "cree_par", nullable = false)
    private Long creePar;

    @Column(name = "date_creation", nullable = false)
    private LocalDateTime dateCreation;

    @OneToMany(mappedBy = "regle", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<VersionRegle> versions = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        if (this.dateCreation == null) {
            this.dateCreation = LocalDateTime.now();
        }
    }

    /**
     * Retourne la version actuellement active de la regle, c'est-a-dire
     * celle chargee dans le moteur Drools (estActive = true).
     */
    @Transient
    public VersionRegle getVersionActive() {
        return this.versions.stream()
                .filter(VersionRegle::isEstActive)
                .findFirst()
                .orElse(null);
    }
}
