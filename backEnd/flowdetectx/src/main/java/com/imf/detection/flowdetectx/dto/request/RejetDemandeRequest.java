package com.imf.detection.flowdetectx.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class RejetDemandeRequest {

    @NotBlank(message = "Le motif de rejet est obligatoire.")
    private String motifRejet;
}