package com.imf.detection.flowdetectx.exception;

/** Levee quand une ressource demandee (utilisateur, regle, etc.) n'existe pas. */
public class RessourceNotFoundException extends RuntimeException {
    public RessourceNotFoundException(String message) {
        super(message);
    }
}