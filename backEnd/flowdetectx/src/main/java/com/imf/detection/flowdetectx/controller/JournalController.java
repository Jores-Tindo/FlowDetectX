package com.imf.detection.flowdetectx.controller;

import com.imf.detection.flowdetectx.dto.response.JournalActiviteResponse;
import com.imf.detection.flowdetectx.service.JournalService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/journal")
@RequiredArgsConstructor
public class JournalController {

    private final JournalService journalService;

    @GetMapping
    public ResponseEntity<List<JournalActiviteResponse>> listerTout() {
        return ResponseEntity.ok(journalService.listerTout());
    }

    @GetMapping("/utilisateur/{id}")
    public ResponseEntity<List<JournalActiviteResponse>> listerParUtilisateur(
            @PathVariable Long id) {
        return ResponseEntity.ok(journalService.listerParUtilisateur(id));
    }
}