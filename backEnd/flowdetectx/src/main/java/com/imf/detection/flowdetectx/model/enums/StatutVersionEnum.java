package com.imf.detection.flowdetectx.model.enums;

/**
 * Statut d'une version specifique d'une regle (VersionRegle).
 *
 * - EN_ATTENTE : version soumise, non encore validee (estActive = false)
 * - ACTIVE     : version actuellement chargee dans le moteur Drools (estActive = true)
 * - REMPLACEE  : ancienne version active, remplacee par une version plus recente approuvee
 * - REJETEE    : version proposee mais rejetee par le validateur
 */
public enum StatutVersionEnum {
    EN_ATTENTE,
    ACTIVE,
    REMPLACEE,
    REJETEE
}
