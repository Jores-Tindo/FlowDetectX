package com.imf.detection.flowdetectx.controller;

import com.imf.detection.flowdetectx.dto.response.AlerteSseResponse;
import com.imf.detection.flowdetectx.model.enums.CriticiteEnum;
import com.imf.detection.flowdetectx.repository.AlerteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/alertes")
@RequiredArgsConstructor
public class AlerteController {

    private final AlerteRepository alerteRepository;

    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<List<AlerteSseResponse>> lister(
            @RequestParam(required = false) CriticiteEnum criticite) {
        if (criticite != null) {
            return ResponseEntity.ok(
                    alerteRepository.findByCriticiteOrderByHorodatageDesc(criticite)
                            .stream().map(AlerteSseResponse::fromEntity).toList());
        }
        return ResponseEntity.ok(
                alerteRepository.findAllByOrderByHorodatageDesc()
                        .stream().map(AlerteSseResponse::fromEntity).toList());
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<AlerteSseResponse> obtenirParId(@PathVariable Long id) {
        return alerteRepository.findById(id)
                .map(AlerteSseResponse::fromEntity)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}