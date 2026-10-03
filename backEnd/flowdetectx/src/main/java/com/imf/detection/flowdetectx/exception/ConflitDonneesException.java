package com.imf.detection.flowdetectx.exception;

/** Levee en cas de conflit d'unicite (email ou identifiant deja utilise). */
public class ConflitDonneesException extends RuntimeException {
    public ConflitDonneesException(String message) {
        super(message);
    }
}