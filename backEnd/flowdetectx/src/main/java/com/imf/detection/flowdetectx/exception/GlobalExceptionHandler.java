package com.imf.detection.flowdetectx.exception;

import com.imf.detection.flowdetectx.dto.response.MessageResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(
            MethodArgumentNotValidException ex) {
        Map<String, String> erreurs = new HashMap<>();
        for (FieldError fe : ex.getBindingResult().getFieldErrors()) {
            erreurs.put(fe.getField(), fe.getDefaultMessage());
        }
        return ResponseEntity.badRequest().body(erreurs);
    }

    @ExceptionHandler(AuthentificationException.class)
    public ResponseEntity<MessageResponse> handleAuth(AuthentificationException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(MessageResponse.of(ex.getMessage()));
    }

    @ExceptionHandler(CompteException.class)
    public ResponseEntity<MessageResponse> handleCompte(CompteException ex) {
        return ResponseEntity.badRequest().body(MessageResponse.of(ex.getMessage()));
    }

    @ExceptionHandler(ConflitDonneesException.class)
    public ResponseEntity<MessageResponse> handleConflit(ConflitDonneesException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(MessageResponse.of(ex.getMessage()));
    }

    @ExceptionHandler(RessourceNotFoundException.class)
    public ResponseEntity<MessageResponse> handleNotFound(RessourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(MessageResponse.of(ex.getMessage()));
    }

    @ExceptionHandler(TokenInvalideException.class)
    public ResponseEntity<MessageResponse> handleToken(TokenInvalideException ex) {
        return ResponseEntity.badRequest().body(MessageResponse.of(ex.getMessage()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<MessageResponse> handleIllegalArg(IllegalArgumentException ex) {
        return ResponseEntity.badRequest().body(MessageResponse.of(ex.getMessage()));
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<MessageResponse> handleIllegalState(IllegalStateException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(MessageResponse.of(ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<MessageResponse> handleGeneral(Exception ex) {
        log.error("[GlobalExceptionHandler] Erreur inattendue : {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(MessageResponse.of("Une erreur interne est survenue."));
    }
}