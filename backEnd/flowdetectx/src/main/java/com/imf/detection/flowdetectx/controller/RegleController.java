package com.imf.detection.flowdetectx.controller;

import com.imf.detection.flowdetectx.dto.request.CreationRegleRequest;
import com.imf.detection.flowdetectx.dto.request.ModificationRegleRequest;
import com.imf.detection.flowdetectx.dto.response.DemandeResponse;
import com.imf.detection.flowdetectx.dto.response.RegleResponse;
import com.imf.detection.flowdetectx.dto.response.VersionRegleResponse;
import com.imf.detection.flowdetectx.service.RegleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/regles")
@RequiredArgsConstructor
public class RegleController {

    private final RegleService regleService;

    @GetMapping
    public ResponseEntity<List<RegleResponse>> lister() {
        return ResponseEntity.ok(regleService.listerRegles());
    }

    @GetMapping("/{id}")
    public ResponseEntity<RegleResponse> obtenirParId(@PathVariable Long id) {
        return ResponseEntity.ok(regleService.obtenirRegle(id));
    }

    @GetMapping("/{id}/versions")
    public ResponseEntity<List<VersionRegleResponse>> versions(@PathVariable Long id) {
        return ResponseEntity.ok(regleService.listerVersions(id));
    }

    @PostMapping("/creer")
    public ResponseEntity<DemandeResponse> creer(
            @Valid @RequestBody CreationRegleRequest dto,
            Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(regleService.soumettreCreation(dto, userId));
    }

    @PostMapping("/{id}/modifier")
    public ResponseEntity<DemandeResponse> modifier(
            @PathVariable Long id,
            @Valid @RequestBody ModificationRegleRequest dto,
            Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(regleService.soumettreModification(id, dto, userId));
    }

    @PostMapping("/{id}/supprimer")
    public ResponseEntity<DemandeResponse> supprimer(
            @PathVariable Long id, Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(regleService.soumettreSuppression(id, userId));
    }

    @PostMapping("/{id}/activer")
    public ResponseEntity<DemandeResponse> activer(
            @PathVariable Long id, Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(regleService.soumettreActivation(id, userId));
    }

    @PostMapping("/{id}/desactiver")
    public ResponseEntity<DemandeResponse> desactiver(
            @PathVariable Long id, Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(regleService.soumettreDesactivation(id, userId));
    }
}