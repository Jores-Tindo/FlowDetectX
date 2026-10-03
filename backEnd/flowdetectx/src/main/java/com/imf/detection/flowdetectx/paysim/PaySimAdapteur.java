package com.imf.detection.flowdetectx.paysim;

import lombok.extern.slf4j.Slf4j;
import org.paysim.paysim.PaySim;
import org.paysim.paysim.base.Transaction;
import org.paysim.paysim.parameters.Parameters;

import java.util.ArrayList;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

/**
 * Adapteur PaySim pour Spring Boot.
 *
 * Surcharge writeOutputStep() (rendu protected dans PaySim source)
 * pour intercepter les transactions a chaque step et les placer
 * dans une BlockingQueue plutot que les ecrire dans des fichiers.
 *
 * Le SimulationService consomme la queue dans un thread separe et
 * soumet chaque transaction au moteur Drools pour detection.
 *
 * Un poison pill (sentinelle step=-1) est insere en fin de queue
 * pour signaler la fin de la simulation au consommateur.
 */
@Slf4j
public class PaySimAdapteur extends PaySim {

    private final BlockingQueue<Transaction> queue;
    private volatile boolean arret = false;

    public PaySimAdapteur() {
        super();
        this.queue = new LinkedBlockingQueue<>(100_000);
    }

    /**
     * Signal interne utilise pour interrompre runSimulation() en plein step.
     * writeOutputStep() n'est appelee qu'APRES schedule.step(this) dans la
     * boucle while() de PaySim : le flag "arret" seul ne peut donc pas stopper
     * la boucle. On la lance ici pour qu'elle remonte jusqu'a demarrer(),
     * qui l'attrape et pose immediatement la sentinelle sur la queue.
     */
    private static final class SimulationArreteeException extends RuntimeException {
    }


    @Override
public void finish() {
    // On surcharge finish() pour eviter l'erreur FileNotFoundException
    // PaySim essaie de lire des CSV depuis son dossier de sortie
    // qu'il cree lui-meme - on ignore cette etape
    log.info("[PaySimAdapteur] finish() appele - simulation terminee.");
}

@Override
public void start() {
    super.start();
    log.info("[PaySimAdapteur] start() termine - nbClients dans Parameters: {}", 
            Parameters.nbClients);
}
    /**
     * Demarre la simulation PaySim de maniere bloquante.
     * A appeler dans un thread separe (ExecutorService).
     */
    public void demarrer() {
    try {
        log.info("[PaySimAdapteur] Demarrage simulation ({} steps).", Parameters.nbSteps);
        runSimulation();
    } catch (SimulationArreteeException e) {
        log.info("[PaySimAdapteur] Simulation interrompue manuellement.");
    } catch (Exception e) {
        log.error("[PaySimAdapteur] Erreur : {}", e.getMessage(), e);
    } finally {
        try {
            queue.put(creerSentinelle());
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
        log.info("[PaySimAdapteur] Simulation terminee.");
    }
}

    /**
     * Demande l'arret propre de la simulation.
     *
     * Coupe la generation (via le flag "arret", vu par writeOutputStep()
     * au step suivant), MAIS vide aussi la queue et y pose directement
     * la sentinelle : sans ca, si le producteur a deja rempli la queue
     * plus vite que le consommateur ne peut la vider (frequent avec
     * beaucoup de clients), le consommateur mettrait plusieurs minutes
     * a traiter tout le backlog deja accumule avant de voir la fin,
     * meme si la generation, elle, s'est bien arretee tout de suite.
     */
    public void arreter() {
        this.arret = true;
        queue.clear();
        try {
            queue.put(creerSentinelle());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public BlockingQueue<Transaction> getQueue() {
        return queue;
    }

    /**
     * Surcharge de writeOutputStep() (rendu protected dans PaySim)
     * pour intercepter les transactions au lieu de les ecrire en fichier.
     */
@Override
protected void writeOutputStep() {
    log.info("[PaySimAdapteur] writeOutputStep appelee - step: {}", schedule.getSteps());
    if (arret) throw new SimulationArreteeException();
    
    ArrayList<Transaction> transactionsStep = getTransactions();
    log.info("[PaySimAdapteur] {} transactions dans ce step.", transactionsStep.size());
    
    for (Transaction t : transactionsStep) {
        try {
            queue.put(t);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return;
        }
    }
}


    /** Transaction sentinelle (step=-1) = signal de fin pour le consommateur. */
    private Transaction creerSentinelle() {
        return new Transaction(-1, "FIN_SIMULATION", 0,
                "SENTINELLE", 0, 0,
                "SENTINELLE", 0, 0);
    }
}