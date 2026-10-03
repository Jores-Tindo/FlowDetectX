package com.imf.detection.flowdetectx.model.enums;

/**
 * Statut global d'une regle de detection (RegleDetection).
 *
 * - ACTIVE     : la version active de la regle est chargee dans le moteur Drools
 * - EN_ATTENTE : une demande concernant cette regle est en attente de validation
 * - REJETEE    : la derniere demande concernant cette regle a ete rejetee
 * - INACTIVE   : la regle a ete desactivee (apres validation)
 */
public enum StatutRegleEnum {
    ACTIVE,
    EN_ATTENTE,
    REJETEE,
    INACTIVE
}
