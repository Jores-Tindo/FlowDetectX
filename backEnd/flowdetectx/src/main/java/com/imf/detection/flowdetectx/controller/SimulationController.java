package com.imf.detection.flowdetectx.controller;

import com.imf.detection.flowdetectx.dto.response.AlerteSseResponse;
import com.imf.detection.flowdetectx.dto.response.MessageResponse;
import com.imf.detection.flowdetectx.dto.response.SimulationResponse;
import com.imf.detection.flowdetectx.service.SimulationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/simulation")
@RequiredArgsConstructor
public class SimulationController {

    private final SimulationService simulationService;

    @PostMapping("/demarrer")
    public ResponseEntity<SimulationResponse> demarrer(
            @RequestParam(required = false) Integer nbSteps,
            Authentication authentication) throws IOException {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(SimulationResponse.fromEntity(simulationService.demarrer(userId, nbSteps)));
    }

    @GetMapping(value = "/stream/{id}", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(@PathVariable Long id) {
        return simulationService.creerEmitter(id);
    }

    @PostMapping("/{id}/arreter")
    public ResponseEntity<MessageResponse> arreter(
            @PathVariable Long id, Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        String message = simulationService.arreter(id, userId);
        return ResponseEntity.ok(MessageResponse.of(message));
    }

    @GetMapping("/mes-simulations")
    public ResponseEntity<List<SimulationResponse>> mesSimulations(
            Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(
                simulationService.listerParUtilisateur(userId).stream()
                        .map(SimulationResponse::fromEntity).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<SimulationResponse> obtenirParId(@PathVariable Long id) {
        return ResponseEntity.ok(
                SimulationResponse.fromEntity(simulationService.obtenirParId(id)));
    }

    @GetMapping("/{id}/alertes")
    public ResponseEntity<List<AlerteSseResponse>> alertes(@PathVariable Long id) {
        return ResponseEntity.ok(
                simulationService.listerAlertes(id).stream()
                        .map(AlerteSseResponse::fromEntity).toList());
    }
}