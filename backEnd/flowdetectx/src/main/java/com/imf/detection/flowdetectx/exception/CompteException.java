package com.imf.detection.flowdetectx.exception;

/** Levee pour les etats de compte invalides (inactif, suspendu, mots de passe non identiques...). */
public class CompteException extends RuntimeException {
    public CompteException(String message) {
        super(message);
    }
}