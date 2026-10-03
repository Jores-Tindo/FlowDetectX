package com.imf.detection.flowdetectx.exception;

/** Levee quand l'identifiant ou le mot de passe fourni est incorrect. */
public class AuthentificationException extends RuntimeException {
    public AuthentificationException(String message) {
        super(message);
    }
}