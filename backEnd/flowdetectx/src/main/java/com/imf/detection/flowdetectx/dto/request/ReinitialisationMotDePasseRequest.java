package com.imf.detection.flowdetectx.dto.request;

import com.imf.detection.flowdetectx.validation.MotDePasseFort;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ReinitialisationMotDePasseRequest {

    @NotBlank(message = "Le token est obligatoire.")
    private String token;

    @NotBlank(message = "Le nouveau mot de passe est obligatoire.")
    @MotDePasseFort
    private String nouveauMotDePasse;

    @NotBlank(message = "La confirmation du mot de passe est obligatoire.")
    private String confirmationMotDePasse;
}