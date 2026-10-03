package com.imf.detection.flowdetectx.controller;

import com.imf.detection.flowdetectx.dto.response.MessageResponse;
import com.imf.detection.flowdetectx.dto.response.UtilisateurResponse;
import com.imf.detection.flowdetectx.model.enums.RoleEnum;
import com.imf.detection.flowdetectx.service.UtilisateurService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/utilisateurs")
@RequiredArgsConstructor
public class UtilisateurController {

    private final UtilisateurService utilisateurService;

    @GetMapping
    public ResponseEntity<List<UtilisateurResponse>> lister(
            @RequestParam(required = false) RoleEnum role) {
        if (role != null) return ResponseEntity.ok(utilisateurService.listerParRole(role));
        return ResponseEntity.ok(utilisateurService.listerTous());
    }

    @GetMapping("/{id}")
    public ResponseEntity<UtilisateurResponse> obtenirParId(@PathVariable Long id) {
        return ResponseEntity.ok(utilisateurService.obtenirParId(id));
    }

    @PutMapping("/{id}/suspendre")
    public ResponseEntity<MessageResponse> suspendre(
            @PathVariable Long id, Authentication authentication) {
        Long adminId = (Long) authentication.getPrincipal();
        utilisateurService.suspendre(id, adminId);
        return ResponseEntity.ok(MessageResponse.of("Compte suspendu avec succes."));
    }

    @PutMapping("/{id}/reactiver")
    public ResponseEntity<MessageResponse> reactiver(@PathVariable Long id) {
        utilisateurService.reactiver(id);
        return ResponseEntity.ok(MessageResponse.of("Compte reactive avec succes."));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> supprimer(@PathVariable Long id) {
        utilisateurService.supprimer(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/supprimer")
    public ResponseEntity<MessageResponse> supprimerAvecPost(@PathVariable Long id) {
        utilisateurService.supprimer(id);
        return ResponseEntity.ok(MessageResponse.of("Compte supprime avec succes."));
    }
}