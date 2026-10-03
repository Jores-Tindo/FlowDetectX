package com.imf.detection.flowdetectx.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.util.regex.Pattern;

public class MotDePasseFortValidator implements ConstraintValidator<MotDePasseFort, String> {

    // Au moins 8 caracteres, 1 minuscule, 1 majuscule, 1 chiffre, 1 caractere special.
    private static final Pattern PATTERN = Pattern.compile(
            "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@#$%^&+=!?*_\\-.]).{8,}$"
    );

    @Override
    public boolean isValid(String motDePasse, ConstraintValidatorContext context) {
        if (motDePasse == null) {
            return false;
        }
        return PATTERN.matcher(motDePasse).matches();
    }
}