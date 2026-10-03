package com.imf.detection.flowdetectx.exception;

/** Levee quand un token d'activation/reinitialisation est invalide, expire ou deja utilise. */
public class TokenInvalideException extends RuntimeException {
    public TokenInvalideException(String message) {
        super(message);
    }
}