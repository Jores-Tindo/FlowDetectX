package com.imf.detection.flowdetectx.controller;

import com.imf.detection.flowdetectx.dto.request.*;
import com.imf.detection.flowdetectx.dto.response.AuthResponse;
import com.imf.detection.flowdetectx.dto.response.MessageResponse;
import com.imf.detection.flowdetectx.dto.response.UtilisateurResponse;
import com.imf.detection.flowdetectx.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    
    

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest dto) {
        return ResponseEntity.ok(authService.login(dto));
    }

    @PostMapping("/activation")
    public ResponseEntity<AuthResponse> activation(
            @Valid @RequestBody ActivationCompteRequest dto) {
        return ResponseEntity.ok(authService.activerCompte(dto));
    }

    @PostMapping("/mot-de-passe-oublie")
    public ResponseEntity<MessageResponse> motDePasseOublie(
            @Valid @RequestBody MotDePasseOublieRequest dto) {
        authService.demanderReinitialisation(dto);
        return ResponseEntity.ok(MessageResponse.of(
                "Si un compte actif existe avec cet email, un lien a ete envoye."));
    }

    @PostMapping("/reinitialisation")
    public ResponseEntity<MessageResponse> reinitialisation(
            @Valid @RequestBody ReinitialisationMotDePasseRequest dto) {
        authService.reinitialiserMotDePasse(dto);
        return ResponseEntity.ok(MessageResponse.of("Mot de passe reinitialise avec succes."));
    }

    @PostMapping("/creer-compte")
    public ResponseEntity<UtilisateurResponse> creerCompte(
            @Valid @RequestBody CreationCompteRequest dto,
            Authentication authentication) {
        Long adminId = (Long) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(authService.creerCompte(dto, adminId));
    }

    @PostMapping("/renvoyer-invitation/{id}")
    public ResponseEntity<MessageResponse> renvoyerInvitation(@PathVariable Long id) {
        authService.renvoyerInvitation(id);
        return ResponseEntity.ok(MessageResponse.of("Invitation renvoyee avec succes."));
    }

    @PostMapping("/profil")
public ResponseEntity<UtilisateurResponse> modifierProfil(
        @Valid @RequestBody ModificationProfilRequest dto,
        Authentication authentication) {
    Long userId = (Long) authentication.getPrincipal();
    return ResponseEntity.ok(authService.modifierProfil(userId, dto));
}

@PostMapping("/changer-mot-de-passe")
public ResponseEntity<MessageResponse> changerMotDePasse(
        @Valid @RequestBody ChangementMotDePasseRequest dto,
        Authentication authentication) {
    Long userId = (Long) authentication.getPrincipal();
    authService.changerMotDePasse(userId, dto);
    return ResponseEntity.ok(MessageResponse.of("Mot de passe modifie avec succes."));
}
}