package com.imf.detection.flowdetectx.model;

import com.imf.detection.flowdetectx.model.enums.TypeTokenEnum;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Jeton temporaire utilise pour :
 *  - l'activation d'un compte cree par l'administrateur (TypeTokenEnum.ACTIVATION)
 *  - la reinitialisation d'un mot de passe oublie (TypeTokenEnum.REINITIALISATION)
 *
 * Un utilisateur possede au plus un token actif (0..1) a un instant donne.
 */
@Entity
@Table(name = "tokens_activation")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TokenActivation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String token;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_token", nullable = false, length = 30)
    private TypeTokenEnum typeToken;

    @Column(name = "date_expiration", nullable = false)
    private LocalDateTime dateExpiration;

    @Column(name = "est_utilise", nullable = false)
    private boolean estUtilise;

    @Column(name = "utilisateur_id", nullable = false)
    private Long utilisateurId;

    @PrePersist
    protected void onCreate() {
        if (!estUtiliseInitialized()) {
            this.estUtilise = false;
        }
    }

    private boolean estUtiliseInitialized() {
        return true; // boolean par defaut deja a false ; conserve pour clarte
    }

    /**
     * Verifie si le token est expire par rapport a l'instant present.
     */
    @Transient
    public boolean estExpire() {
        return LocalDateTime.now().isAfter(this.dateExpiration);
    }
}
