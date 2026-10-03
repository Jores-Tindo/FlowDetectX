package com.imf.detection.flowdetectx.dto.response;

import com.imf.detection.flowdetectx.model.enums.RoleEnum;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {

    private String token;
    private Long id;
    private String nom;
    private String prenom;
    private String identifiant;
    private String email;
    private RoleEnum role;
}