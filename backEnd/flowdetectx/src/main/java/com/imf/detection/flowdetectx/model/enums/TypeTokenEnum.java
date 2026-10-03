package com.imf.detection.flowdetectx.model.enums;

/**
 * Type d'un jeton temporaire (TokenActivation).
 *
 * - ACTIVATION       : utilise lors de la creation d'un compte par l'administrateur
 * - REINITIALISATION : utilise lors d'une demande de mot de passe oublie
 */
public enum TypeTokenEnum {
    ACTIVATION,
    REINITIALISATION
}
