package com.imf.detection.flowdetectx.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ChangementMotDePasseRequest {

    @NotBlank(message = "Le mot de passe actuel est requis.")
    private String ancienMotDePasse;

    @NotBlank(message = "Le nouveau mot de passe est requis.")
    @Size(min = 8, message = "Minimum 8 caracteres requis.")
    private String nouveauMotDePasse;

    @NotBlank(message = "La confirmation est requise.")
    private String confirmationMotDePasse;
}