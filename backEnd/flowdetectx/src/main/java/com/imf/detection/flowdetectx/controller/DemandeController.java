package com.imf.detection.flowdetectx.controller;

import com.imf.detection.flowdetectx.dto.request.RejetDemandeRequest;
import com.imf.detection.flowdetectx.dto.response.DemandeResponse;
import com.imf.detection.flowdetectx.service.ValidationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/demandes")
@RequiredArgsConstructor
public class DemandeController {

    private final ValidationService validationService;

    @GetMapping
    public ResponseEntity<List<DemandeResponse>> listerToutes() {
        return ResponseEntity.ok(validationService.listerToutesDemandes());
    }

    @GetMapping("/en-attente")
    public ResponseEntity<List<DemandeResponse>> enAttente() {
        return ResponseEntity.ok(validationService.listerDemandesEnAttente());
    }

    @GetMapping("/mes-demandes")
    public ResponseEntity<List<DemandeResponse>> mesDemandes(Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(
                validationService.listerDemandesParAgentConformite(userId));
    }

    @PostMapping("/{id}/approuver")
    public ResponseEntity<DemandeResponse> approuver(
            @PathVariable Long id, Authentication authentication) {
        Long validateurId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(validationService.approuver(id, validateurId));
    }

    @PostMapping("/{id}/rejeter")
    public ResponseEntity<DemandeResponse> rejeter(
            @PathVariable Long id,
            @Valid @RequestBody RejetDemandeRequest dto,
            Authentication authentication) {
        Long validateurId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(
                validationService.rejeter(id, dto.getMotifRejet(), validateurId));
    }
}