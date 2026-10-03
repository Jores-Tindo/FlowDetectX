package com.imf.detection.flowdetectx.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {

    @NotBlank(message = "L'identifiant est obligatoire.")
    private String identifiant;

    @NotBlank(message = "Le mot de passe est obligatoire.")
    private String motDePasse;
}