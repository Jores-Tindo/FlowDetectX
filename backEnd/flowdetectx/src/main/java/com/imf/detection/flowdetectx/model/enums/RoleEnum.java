package com.imf.detection.flowdetectx.model.enums;

/**
 * Roles disponibles dans le systeme RuleDetect-IMF.
 *
 * - ADMINISTRATEUR : gestion des comptes, parametrage technique, dashboard
 * - VALIDATEUR     : approbation/rejet des demandes de gestion de regles
 * - UTILISATEUR_METIER : agent de conformite, gestion des regles, simulation
 */
public enum RoleEnum {
    ADMINISTRATEUR,
    VALIDATEUR,
    UTILISATEUR_METIER
}
