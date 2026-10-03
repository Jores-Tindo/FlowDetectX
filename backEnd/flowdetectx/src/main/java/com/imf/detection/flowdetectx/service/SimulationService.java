package com.imf.detection.flowdetectx.service;

import com.imf.detection.flowdetectx.model.Alerte;
import com.imf.detection.flowdetectx.model.ProfilClient;
import com.imf.detection.flowdetectx.model.Simulation;
import com.imf.detection.flowdetectx.model.Transaction;
import com.imf.detection.flowdetectx.model.enums.StatutSimulationEnum;
import com.imf.detection.flowdetectx.paysim.PaySimAdapteur;
import com.imf.detection.flowdetectx.repository.AlerteRepository;
import com.imf.detection.flowdetectx.repository.SimulationRepository;
import com.imf.detection.flowdetectx.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.kie.api.runtime.KieSession;
import org.kie.api.runtime.rule.FactHandle;
import org.paysim.paysim.parameters.Parameters;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;
import jakarta.annotation.PostConstruct;


@Slf4j
@Service
@RequiredArgsConstructor
public class SimulationService {

    private final SimulationRepository simulationRepository;
    private final TransactionRepository transactionRepository;
    private final AlerteRepository alerteRepository;
    private final MoteurDroolsService moteurDroolsService;
    private final EvaluationService evaluationService;
    private final JournalService journalService;

    private final Map<Long, SseEmitter> emitters = new ConcurrentHashMap<>();
    private final Map<Long, PaySimAdapteur> simulations = new ConcurrentHashMap<>();
    private final ExecutorService executor = Executors.newCachedThreadPool();



//Verification et nettoyage des simulations orphelines au demarrage du service
@PostConstruct
public void nettoyerSimulationsOrphelines() {
    List<Simulation> enCours = simulationRepository
            .findAll()
            .stream()
            .filter(s -> s.getStatut() == StatutSimulationEnum.EN_COURS)
            .toList();

    if (enCours.isEmpty()) {
        log.info("[SimulationService] Aucune simulation orpheline detectee au demarrage.");
        return;
    }

    for (Simulation sim : enCours) {
        sim.setStatut(StatutSimulationEnum.TERMINEE);
        sim.setDateFin(LocalDateTime.now());
        simulationRepository.save(sim);
        log.warn("[SimulationService] Simulation #{} marquee orpheline au demarrage "
                + "(EN_COURS sans instance en memoire) : statut force a TERMINEE.",
                sim.getId());
    }

    log.info("[SimulationService] {} simulation(s) orpheline(s) nettoyee(s) au demarrage.",
            enCours.size());
}

    // ---------------------------------------------------------------
    // Demarrage
    // ---------------------------------------------------------------

    public Simulation demarrer(Long utilisateurId, Integer nbStepsDemande) throws IOException {
        if (!moteurDroolsService.estPret()) {
            throw new IllegalStateException(
                    "Le moteur Drools n'est pas initialise : aucune regle active en base.");
        }

        if (simulationRepository.existsByStatut(StatutSimulationEnum.EN_COURS)) {
            throw new IllegalStateException(
                    "Une simulation est deja en cours. Arretez-la avant d'en demarrer une nouvelle.");
        }

        Simulation simulation = simulationRepository.save(Simulation.builder()
                .utilisateurId(utilisateurId)
                .dateDebut(LocalDateTime.now())
                .statut(StatutSimulationEnum.EN_COURS)
                .build());

        // nbSteps optionnel : borne entre 1 et 500 pour eviter un run
        // demesure (chaque step peut generer plusieurs dizaines de
        // transactions avec 100 clients).
        Integer nbStepsBorne = null;
        if (nbStepsDemande != null) {
            nbStepsBorne = Math.max(1, Math.min(500, nbStepsDemande));
        }

        Path tempDir = extraireParamFiles(nbStepsBorne);
String propsPath = tempDir.resolve("PaySim.properties").toString();
Parameters.initParameters(propsPath);
log.info("[SimulationService] nbSteps={}, nbClients={}, multiplier={}", 
        Parameters.nbSteps, Parameters.nbClients, Parameters.multiplier);

        PaySimAdapteur adapteur = new PaySimAdapteur();
        simulations.put(simulation.getId(), adapteur);

        final Simulation sim = simulation;
        executor.submit(() -> executerSimulation(sim, adapteur, utilisateurId));

        journalService.journaliser(utilisateurId, "DEMARRAGE_SIMULATION",
                "Simulation #" + simulation.getId() + " demarree.");
        return simulation;
    }

    public SseEmitter creerEmitter(Long simulationId) {
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);
        emitters.put(simulationId, emitter);
        emitter.onCompletion(() -> emitters.remove(simulationId));
        emitter.onTimeout(()   -> emitters.remove(simulationId));
        emitter.onError(e      -> emitters.remove(simulationId));
        return emitter;
    }

    public String arreter(Long simulationId, Long utilisateurId) {
        PaySimAdapteur adapteur = simulations.get(simulationId);
        if (adapteur != null) {
            adapteur.arreter();
            journalService.journaliser(utilisateurId, "ARRET_SIMULATION",
                    "Simulation #" + simulationId + " arretee manuellement.");
            return "Arret demande.";
        }

        // Instance introuvable en memoire : soit id invalide, soit le
        // serveur a redemarre depuis le lancement de cette simulation
        // (le ConcurrentHashMap "simulations" est en memoire, non
        // persiste). Dans ce dernier cas, la simulation reste bloquee
        // EN_COURS en base indefiniment si on ne la corrige pas ici.
        Simulation simulation = simulationRepository.findById(simulationId)
                .orElseThrow(() -> new IllegalArgumentException("Simulation introuvable."));

        if (simulation.getStatut() == StatutSimulationEnum.EN_COURS) {
            simulation.setStatut(StatutSimulationEnum.TERMINEE);
            simulation.setDateFin(LocalDateTime.now());
            simulationRepository.save(simulation);
            journalService.journaliser(utilisateurId, "ARRET_SIMULATION",
                    "Simulation #" + simulationId + " orpheline (instance perdue, "
                    + "probablement suite a un redemarrage serveur) : statut force a TERMINEE.");
            return "Simulation orpheline detectee (processus introuvable) : "
                    + "statut force a TERMINEE.";
        }

        return "Cette simulation est deja terminee.";
    }

    // ---------------------------------------------------------------
    // Consultation
    // ---------------------------------------------------------------

    public List<Simulation> listerParUtilisateur(Long utilisateurId) {
        return simulationRepository.findByUtilisateurIdOrderByDateDebutDesc(utilisateurId);
    }

    public List<Simulation> listerToutes() {
        return simulationRepository.findAll();
    }

    public Simulation obtenirParId(Long id) {
        return simulationRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Simulation introuvable."));
    }

    public List<Alerte> listerAlertes(Long simulationId) {
        return alerteRepository.findBySimulationIdOrderByHorodatageDesc(simulationId);
    }

    // ---------------------------------------------------------------
    // Execution en arriere-plan
    // ---------------------------------------------------------------

    private void executerSimulation(Simulation simulation,
                                    PaySimAdapteur adapteur,
                                    Long utilisateurId) {
        BlockingQueue<org.paysim.paysim.base.Transaction> queue = adapteur.getQueue();

        long nbTransactions = 0, nbAlertes = 0;
        long vp = 0, fp = 0, fn = 0;

        // Session Drools UNIQUE pour toute la duree de la simulation.
        // Indispensable pour que R001 (accumulate sur 24h), R003
        // (correlation entree/sortie) et R004 (accumulate sur 1h)
        // puissent voir plusieurs Transaction du meme client a la fois :
        // avec une session jetee apres chaque transaction (ancien code),
        // ces regles ne pouvaient structurellement jamais se declencher.
        KieSession session = moteurDroolsService.ouvrirSession();
        Set<String> profilsInseres = new HashSet<>();

        executor.submit(adapteur::demarrer);

        try {
    while (true) {
        org.paysim.paysim.base.Transaction paySimTx = queue.take();
        if (paySimTx.getStep() == -1) break;

        nbTransactions++;
        if (nbTransactions <= 5) {
            log.info("[SimulationService] Tx #{}: type={}, montant={}", 
                    nbTransactions, paySimTx.getAction(), paySimTx.getAmount());
        }

        try {
            Transaction tx = convertir(paySimTx, simulation);
            List<Alerte> alertes = evaluerAvecDrools(session, tx, profilsInseres);

            boolean fraudeReelle = paySimTx.isFraud();
            boolean alerteLevee  = !alertes.isEmpty();

            if (fraudeReelle && alerteLevee)  vp++;
            if (!fraudeReelle && alerteLevee) fp++;
            if (fraudeReelle && !alerteLevee) fn++;

            if (alerteLevee) {
                nbAlertes++;
                Transaction txSauvee = transactionRepository.save(tx);
                for (Alerte alerte : alertes) {
                    alerte.setSimulation(simulation);
                    alerte.setTransaction(txSauvee);
                    alerte.setHorodatage(LocalDateTime.now());
                    Alerte alerteSauvee = alerteRepository.save(alerte);
                    envoyerSse(simulation.getId(), alerteSauvee);
                }
            }

            if (nbTransactions % 50 == 0) {
                mettreAJour(simulation.getId(), nbTransactions, nbAlertes, vp, fp, fn, false);
            }

        } catch (Exception e) {
            log.error("[SimulationService] Erreur tx #{}: {}", nbTransactions, e.getMessage(), e);
        }
    }
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();
    log.warn("[SimulationService] Simulation #{} interrompue.", simulation.getId());
} finally {
            session.dispose();
            mettreAJour(simulation.getId(), nbTransactions, nbAlertes, vp, fp, fn, true);
            simulations.remove(simulation.getId());
            fermerEmitter(simulation.getId());
            journalService.journaliser(utilisateurId, "FIN_SIMULATION",
                    "Simulation #" + simulation.getId() + " terminee — "
                            + nbTransactions + " tx, " + nbAlertes + " alertes.");
        }
    }

    // ---------------------------------------------------------------
    // Drools
    // ---------------------------------------------------------------

/**
 * Evalue une transaction dans la session Drools PARTAGEE de la
 * simulation en cours (une seule session pour tout le run, cf.
 * executerSimulation). C'est ce qui permet aux regles multi-transactions
 * (R001, R003, R004) de fonctionner : les faits Transaction precedents
 * restent en memoire de travail et peuvent etre corriges avec les
 * nouveaux, dans les fenetres temporelles definies par chaque regle.
 *
 * Insere aussi un fait ProfilClient (genere une seule fois par client,
 * donnees KYC simulees puisque le dataset PaySim n'en contient pas)
 * pour permettre a R005 et R006 de s'evaluer.
 */
private static final Random RANDOM_PROFILS = new Random();

private List<Alerte> evaluerAvecDrools(KieSession session, Transaction tx,
                                        Set<String> profilsInseres) {
    if (profilsInseres.add(tx.getNomClient())) {
        ProfilClient profil = genererProfilClient(tx.getNomClient());
        session.insert(profil);
    }

    session.insert(tx);
    session.fireAllRules();

    List<Alerte> nouvelles = session.getObjects(obj -> obj instanceof Alerte)
            .stream()
            .map(obj -> (Alerte) obj)
            .collect(Collectors.toList());

    // On retire les alertes de la session juste apres les avoir
    // recuperees : sinon elles restent en memoire de travail et
    // seraient re-comptees a chaque evaluation suivante.
    for (Alerte alerte : nouvelles) {
        FactHandle fh = session.getFactHandle(alerte);
        if (fh != null) session.delete(fh);
    }

    log.info("[Drools] {} alertes pour tx type={} montant={}",
            nouvelles.size(), tx.getType(), tx.getMontant());
    return nouvelles;
}

/**
 * Genere un profil KYC simule pour un client : revenu declare
 * plausible et derniere activite (parfois ancienne, pour permettre
 * a R006 de se declencher sur une fraction realiste des comptes).
 */
private ProfilClient genererProfilClient(String nomClient) {
    double revenuDeclare = 50_000 + RANDOM_PROFILS.nextDouble() * 2_450_000;

    int joursDepuisActivite = RANDOM_PROFILS.nextInt(400);
    LocalDateTime derniereActivite = LocalDateTime.now().minusDays(joursDepuisActivite);

    return ProfilClient.builder()
            .nomClient(nomClient)
            .revenuDeclare(revenuDeclare)
            .derniereActivite(derniereActivite)
            .build();
}

    // ---------------------------------------------------------------
    // SSE
    // ---------------------------------------------------------------

    private void envoyerSse(Long simulationId, Alerte alerte) {
        SseEmitter emitter = emitters.get(simulationId);
        if (emitter == null) return;
        try {
            emitter.send(SseEmitter.event().name("alerte")
                    .data(com.imf.detection.flowdetectx.dto.response.AlerteSseResponse.fromEntity(alerte)));
        } catch (IOException e) {
            emitters.remove(simulationId);
        }
    }

    private void fermerEmitter(Long simulationId) {
        SseEmitter emitter = emitters.remove(simulationId);
        if (emitter == null) return;
        try {
            emitter.send(SseEmitter.event().name("fin").data("Simulation terminee"));
        } catch (IOException ignored) {}
        emitter.complete();
    }

    // ---------------------------------------------------------------
    // Persistance
    // ---------------------------------------------------------------

    private void mettreAJour(Long simulationId, long nbTx, long nbAlertes,
                          long vp, long fp, long fn, boolean terminee) {
    simulationRepository.findById(simulationId).ifPresent(sim -> {
        int vn = evaluationService.calculerVraisNegatifs(nbTx, (int) vp, (int) fp, (int) fn);
        double[] m = evaluationService.calculerMetriques((int) vp, (int) fp, (int) fn, vn);
        sim.setNbTransactionsTraitees(nbTx);
        sim.setNbAlertes(nbAlertes);
        sim.setVraisPositifs(vp);
        sim.setFauxPositifs(fp);
        sim.setFauxNegatifs(fn);
        sim.setVraisNegatifs(vn);
        sim.setPrecisionScore(m[0]);
        sim.setRappelScore(m[1]);
        sim.setF1Score(m[2]);
        sim.setTauxFauxPositifs(m[3]);
        if (terminee) {
            sim.setStatut(StatutSimulationEnum.TERMINEE);
            sim.setDateFin(LocalDateTime.now());
        }
        simulationRepository.save(sim);
    });
}

    // ---------------------------------------------------------------
    // Conversion PaySim -> JPA
    // ---------------------------------------------------------------

    private Transaction convertir(org.paysim.paysim.base.Transaction pt,
                                   Simulation simulation) {
        return Transaction.builder()
                .simulation(simulation)
                .step(pt.getStep())
                .type(pt.getAction())
                .montant(pt.getAmount()* 655.36)
                .nomClient(pt.getNameOrig())
                .soldeAvantClient(pt.getOldBalanceOrig()* 655.36)
                .soldeApresClient(pt.getNewBalanceOrig()* 655.36)
                .nomDestinataire(pt.getNameDest())
                .soldeAvantDest(pt.getOldBalanceDest()* 655.36)
                .soldeApresDest(pt.getNewBalanceDest()* 655.36)
                .estFraude(pt.isFraud())
                .dateEnregistrement(new java.util.Date())
                .build();
    }

    // ---------------------------------------------------------------
    // Extraction paramFiles classpath -> temp
    // ---------------------------------------------------------------

    private Path extraireParamFiles(Integer nbStepsOverride) throws IOException {
        Path tempDir  = Files.createTempDirectory("ruledetect-paysim-");
        Path paramDir = tempDir.resolve("paramFiles");
        Files.createDirectories(paramDir);
        Files.createDirectories(paramDir.resolve("typologies"));

        String[] csvFiles = {
                "aggregatedTransactions.csv",
                "clientsProfiles.csv",
                "initialBalancesDistribution.csv",
                "maxOccurrencesPerClient.csv",
                "overdraftLimits.csv",
                "transactionsTypes.csv"
        };
        for (String csv : csvFiles) {
            copierRessource("paysim/paramFiles/" + csv, paramDir.resolve(csv));
        }
        copierRessource(
                "paysim/paramFiles/typologies/DrugNetworkOne.graphml",
                paramDir.resolve("typologies/DrugNetworkOne.graphml"));

        String props = lireRessource("paysim/PaySim.properties")
                .replace("PAYSIM_PARAM_PATH", paramDir.toAbsolutePath().toString())
                .replace("PAYSIM_OUTPUT_PATH", tempDir.toAbsolutePath().toString());

        if (nbStepsOverride != null) {
            props = props.replaceAll(
                    "(?m)^nbSteps\\s*=.*$",
                    "nbSteps=" + nbStepsOverride);
        }

        Files.writeString(tempDir.resolve("PaySim.properties"), props);

        log.info("[SimulationService] ParamFiles extraits dans : {}", tempDir);
        log.info("[SimulationService] Contenu PaySim.properties:\n{}", 
        Files.readString(tempDir.resolve("PaySim.properties")));
        return tempDir;
    }

    private void copierRessource(String cp, Path dest) throws IOException {
        try (InputStream is = new ClassPathResource(cp).getInputStream()) {
            Files.copy(is, dest, StandardCopyOption.REPLACE_EXISTING);
        }
    }

    private String lireRessource(String cp) throws IOException {
        try (InputStream is = new ClassPathResource(cp).getInputStream()) {
            return new String(is.readAllBytes());
        }
    }
}