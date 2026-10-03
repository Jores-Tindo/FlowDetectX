package com.imf.detection.flowdetectx.dto.request;

import com.imf.detection.flowdetectx.validation.MotDePasseFort;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ActivationCompteRequest {

    @NotBlank(message = "Le token est obligatoire.")
    private String token;

    @NotBlank(message = "L'identifiant est obligatoire.")
    @Size(min = 4, max = 50, message = "L'identifiant doit contenir entre 4 et 50 caracteres.")
    private String identifiant;

    @NotBlank(message = "Le mot de passe est obligatoire.")
    @MotDePasseFort
    private String motDePasse;

    @NotBlank(message = "La confirmation du mot de passe est obligatoire.")
    private String confirmationMotDePasse;
}