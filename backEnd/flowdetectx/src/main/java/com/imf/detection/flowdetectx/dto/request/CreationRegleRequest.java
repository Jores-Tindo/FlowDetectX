package com.imf.detection.flowdetectx.dto.request;

import com.imf.detection.flowdetectx.model.enums.CriticiteEnum;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CreationRegleRequest {

    @NotBlank(message = "Le nom de la regle est obligatoire.")
    @Size(max = 200, message = "Le nom ne peut pas depasser 200 caracteres.")
    private String nom;

    @NotBlank(message = "La description est obligatoire.")
    private String description;

    @NotNull(message = "La criticite est obligatoire.")
    private CriticiteEnum criticite;

    @NotBlank(message = "Les conditions sont obligatoires.")
    private String conditions;

    @NotBlank(message = "Le contenu DRL est obligatoire.")
    private String contenuDrl;
}