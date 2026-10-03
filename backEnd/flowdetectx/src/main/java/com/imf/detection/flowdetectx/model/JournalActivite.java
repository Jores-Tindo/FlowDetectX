package com.imf.detection.flowdetectx.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.LocalDateTime;

/**
 * Journal d'audit (BNF-06) : enregistre toute action critique effectuee
 * par un utilisateur (connexion, gestion de comptes, soumission et
 * traitement de demandes, simulations, exports...).
 * 
 * Conforme aux exigences de surveillance des directives UEMOA et aux
 * recommandations du GAFI.
 */
@Entity
@Table(name = "journal_activite")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JournalActivite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "utilisateur_id", nullable = false)
    private Long utilisateurId;

    @Column(nullable = false, length = 100)
    private String action;

    @Lob
    @Column(columnDefinition = "TEXT")
    private String details;

    @Column(nullable = false)
    private LocalDateTime horodatage;

    @PrePersist
    protected void onCreate() {
        if (this.horodatage == null) {
            this.horodatage = LocalDateTime.now();
        }
    }
}
