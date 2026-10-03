package com.imf.detection.flowdetectx.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Represente le profil KYC (Know Your Customer) d'un client, utilise
 * comme FAIT Drools en memoire (non persiste) pour evaluer les regles
 * R005 (ecart KYC) et R006 (compte dormant).
 *
 * Ces profils sont generes/simules a partir des donnees PaySim au
 * demarrage d'une simulation : ils ne font pas partie du dataset
 * original de Kaggle (qui ne contient pas d'information KYC), mais
 * sont necessaires pour rendre ces deux regles evaluables.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProfilClient {

    /** Identifiant du client, correspond a Transaction.nomClient. */
    private String nomClient;

    /** Revenu mensuel declare lors de l'inscription (KYC), en FCFA. */
    private double revenuDeclare;

    /** Date de la derniere activite connue avant la simulation en cours. */
    private LocalDateTime derniereActivite;
}
