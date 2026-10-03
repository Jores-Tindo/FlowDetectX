package com.imf.detection.flowdetectx.dto.request;

import com.imf.detection.flowdetectx.model.enums.RoleEnum;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreationCompteRequest {

    @NotBlank(message = "Le nom est obligatoire.")
    private String nom;

    @NotBlank(message = "Le prenom est obligatoire.")
    private String prenom;

    @NotBlank(message = "L'email est obligatoire.")
    @Email(message = "Format d'email invalide.")
    private String email;

    @NotNull(message = "Le role est obligatoire.")
    private RoleEnum role;
}