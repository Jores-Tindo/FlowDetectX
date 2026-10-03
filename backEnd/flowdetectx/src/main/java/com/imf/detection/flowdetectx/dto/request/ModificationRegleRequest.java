package com.imf.detection.flowdetectx.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class ModificationRegleRequest {

    /** Optionnel : null = description inchangee. */
    private String description;

    @NotBlank(message = "Les nouvelles conditions sont obligatoires.")
    private String conditions;

    @NotBlank(message = "Le nouveau contenu DRL est obligatoire.")
    private String contenuDrl;
}