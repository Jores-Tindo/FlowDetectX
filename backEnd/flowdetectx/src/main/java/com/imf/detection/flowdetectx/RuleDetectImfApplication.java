package com.imf.detection.flowdetectx;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Point d'entree de l'application RuleDetect-IMF.
 *
 * Moteur de regles de detection des transactions suspectes
 * pour les Institutions de Microfinance (IMF) beninoises.
 *
 * Conforme aux exigences de la CENTIF-BJ, de la BCEAO
 * (Instruction N 233/07/2024) et de la Directive UEMOA n 02/2015.
 */
@SpringBootApplication
public class RuleDetectImfApplication {

    public static void main(String[] args) {
        SpringApplication.run(RuleDetectImfApplication.class, args);
    }
}