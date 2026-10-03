package com.imf.detection.flowdetectx.dto.response;

import com.imf.detection.flowdetectx.model.Alerte;
import com.imf.detection.flowdetectx.model.enums.CriticiteEnum;
import lombok.*;
import java.time.LocalDateTime;

/**
 * DTO plat envoye via le flux SSE (/api/simulation/stream/{id}).
 *
 * On evite volontairement d'envoyer l'entite Alerte brute : elle
 * embarque des relations JPA completes (Simulation, Transaction)
 * qui produiraient un JSON imbrique et inutilement lourd cote
 * frontend. Ce DTO remonte directement les champs de la transaction
 * associee (nomClient, montant, type) au meme niveau que ceux de
 * l'alerte, pour un mapping simple cote client (Flutter, etc).
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AlerteSseResponse {

    private Long id;
    private String regleNom;
    private CriticiteEnum criticite;
    private String description;
    private LocalDateTime horodatage;

    // Champs remontes depuis la Transaction associee
    private String nomClient;
    private double montant;
    private String type;

    public static AlerteSseResponse fromEntity(Alerte a) {
        var tx = a.getTransaction();
        return AlerteSseResponse.builder()
                .id(a.getId())
                .regleNom(a.getRegleNom())
                .criticite(a.getCriticite())
                .description(a.getDescription())
                .horodatage(a.getHorodatage())
                .nomClient(tx != null ? tx.getNomClient() : null)
                .montant(tx != null ? tx.getMontant() : 0.0)
                .type(tx != null ? tx.getType() : null)
                .build();
    }
}