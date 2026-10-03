package com.imf.detection.flowdetectx.model;

import com.imf.detection.flowdetectx.model.enums.RoleEnum;
import com.imf.detection.flowdetectx.model.enums.StatutCompteEnum;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Represente un utilisateur du systeme RuleDetect-IMF.
 *
 * Un meme schema couvre les trois roles (Administrateur, Validateur,
 * Utilisateur metier) via l'attribut {@link RoleEnum}.
 *
 * Cycle de vie du compte :
 *  - cree par un Administrateur : statut = INACTIF, identifiant/motDePasse = null
 *  - apres activation par token : statut = ACTIF, identifiant/motDePasse renseignes
 *  - email -> creation + recuperation mot de passe uniquement
 *  - identifiant + motDePasse -> connexion quotidienne
 */
@Entity
@Table(name = "utilisateurs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Utilisateur {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String nom;

    @Column(nullable = false, length = 100)
    private String prenom;

    @Column(nullable = false, unique = true, length = 150)
    private String email;

    @Column(unique = true, length = 50)
    private String identifiant;

    @Column(name = "mot_de_passe", length = 255)
    private String motDePasse;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private RoleEnum role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutCompteEnum statut;

    @Column(name = "cree_par")
    private Long creePar;

    @Column(name = "date_creation", nullable = false)
    private LocalDateTime dateCreation;

    @PrePersist
    protected void onCreate() {
        if (this.dateCreation == null) {
            this.dateCreation = LocalDateTime.now();
        }
        if (this.statut == null) {
            this.statut = StatutCompteEnum.INACTIF;
        }
    }
}
