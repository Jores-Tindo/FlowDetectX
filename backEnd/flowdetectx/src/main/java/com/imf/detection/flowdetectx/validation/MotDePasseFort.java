package com.imf.detection.flowdetectx.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Documented
@Constraint(validatedBy = MotDePasseFortValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
public @interface MotDePasseFort {

    String message() default "Le mot de passe doit contenir au moins 8 caracteres, "
            + "une majuscule, une minuscule, un chiffre et un caractere special.";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}