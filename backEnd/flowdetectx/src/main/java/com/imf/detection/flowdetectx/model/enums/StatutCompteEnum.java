package com.imf.detection.flowdetectx.model.enums;

/**
 * Statut d'un compte utilisateur.
 *
 * - INACTIF  : compte cree par l'administrateur, en attente d'activation par token
 * - ACTIF    : compte active, identifiant + mot de passe definis
 * - SUSPENDU : compte desactive par l'administrateur, connexion impossible
 */
public enum StatutCompteEnum {
    INACTIF,
    ACTIF,
    SUSPENDU
}
