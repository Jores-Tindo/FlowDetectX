package com.imf.detection.flowdetectx.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ModificationProfilRequest {

    @NotBlank(message = "Le nom est requis.")
    private String nom;

    @NotBlank(message = "Le prenom est requis.")
    private String prenom;

    @NotBlank(message = "L'email est requis.")
    @Email(message = "Email invalide.")
    private String email;
}