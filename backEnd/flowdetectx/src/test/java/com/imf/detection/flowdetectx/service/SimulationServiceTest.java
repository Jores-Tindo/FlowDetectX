package com.imf.detection.flowdetectx.service;

import com.imf.detection.flowdetectx.model.Simulation;
import com.imf.detection.flowdetectx.model.enums.StatutSimulationEnum;
import com.imf.detection.flowdetectx.paysim.PaySimAdapteur;
import com.imf.detection.flowdetectx.repository.AlerteRepository;
import com.imf.detection.flowdetectx.repository.SimulationRepository;
import com.imf.detection.flowdetectx.repository.TransactionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SimulationServiceTest {

    @Mock
    private SimulationRepository simulationRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private AlerteRepository alerteRepository;

    @Mock
    private MoteurDroolsService moteurDroolsService;

    @Mock
    private EvaluationService evaluationService;

    @Mock
    private JournalService journalService;

    @InjectMocks
    private SimulationService simulationService;

    @Test
    void arreter_shouldMarkSimulationAsTermineeImmediately() {
        Long simulationId = 42L;
        Long utilisateurId = 7L;
        Simulation simulation = Simulation.builder()
                .id(simulationId)
                .utilisateurId(utilisateurId)
                .dateDebut(LocalDateTime.now())
                .statut(StatutSimulationEnum.EN_COURS)
                .build();

        Map<Long, PaySimAdapteur> simulations = new ConcurrentHashMap<>();
        PaySimAdapteur adapteur = org.mockito.Mockito.mock(PaySimAdapteur.class);
        simulations.put(simulationId, adapteur);

        ReflectionTestUtils.setField(simulationService, "simulations", simulations);
        when(simulationRepository.findById(simulationId)).thenReturn(Optional.of(simulation));

        simulationService.arreter(simulationId, utilisateurId);

        ArgumentCaptor<Simulation> captor = ArgumentCaptor.forClass(Simulation.class);
        verify(simulationRepository).save(captor.capture());

        Simulation sauvegardee = captor.getValue();
        assertThat(sauvegardee.getStatut()).isEqualTo(StatutSimulationEnum.TERMINEE);
        assertThat(sauvegardee.getDateFin()).isNotNull();
        verify(adapteur).arreter();
        verify(journalService).journaliser(utilisateurId, "ARRET_SIMULATION", "Simulation #42 arretee manuellement.");
    }
}
