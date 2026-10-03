-- ====================================================================
-- fix_regles_db.sql
-- Corrige le contenu_drl des 6 regles deja presentes dans ta base MySQL
-- (ruledetect_imf), sans dependre de Flyway (desactive dans ton
-- application.properties). A executer une seule fois.
--
-- Usage :
--   mysql -u root -p ruledetect_imf < fix_regles_db.sql
-- ou copier/coller dans un client SQL (DBeaver, phpMyAdmin, etc.)
-- ====================================================================

UPDATE versions_regle
SET contenu_drl = 'rule "R001_Smurfing_DepotFractionne"\n    salience 100\nwhen\n    $t : Transaction(type == "CASH_IN", montant < 2000000)\n    $count : Number(intValue >= 3) from accumulate(\n        Transaction(\n            nomClient == $t.nomClient,\n            type == "CASH_IN"\n        ) over window:time(24h),\n        count(1)\n    )\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R001 - Depot fractionne d''especes (Smurfing)");\n    alerte.setCriticite(CriticiteEnum.ELEVE);\n    alerte.setDescription(\n        "Client " + $t.getNomClient() + " : au moins 3 depots en especes "\n        + "en moins de 24h, montant cumule suspect de fractionnement "\n        + "(seuil de declaration potentiellement contourne)."\n    );\n    insertLogical(alerte);\nend'
WHERE regle_id = 1 AND est_active = TRUE;

UPDATE versions_regle
SET contenu_drl = 'rule "R002_CashHorsProfil_SeuilBCEAO"\n    salience 100\nwhen\n    $t : Transaction(type == "CASH_IN", montant > 5000000)\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R002 - Operation cash hors profil");\n    alerte.setCriticite(CriticiteEnum.ELEVE);\n    alerte.setDescription(\n        "Versement en especes de " + $t.getMontant() + " FCFA par "\n        + $t.getNomClient() + ", superieur au seuil de 5 000 000 FCFA "\n        + "fixe par l''Instruction BCEAO N 233/07/2024."\n    );\n    insertLogical(alerte);\nend'
WHERE regle_id = 2 AND est_active = TRUE;

UPDATE versions_regle
SET contenu_drl = 'rule "R003_PassThrough_TransitRapide"\n    salience 100\nwhen\n    $sortie : Transaction(type == "CASH_OUT")\n    $entree : Transaction(\n        nomClient == $sortie.nomClient,\n        type == "CASH_IN",\n        montant >= ($sortie.montant * 0.9),\n        this after[0s, 10m] $sortie\n    )\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R003 - Transit rapide de fonds (Pass-through)");\n    alerte.setCriticite(CriticiteEnum.ELEVE);\n    alerte.setDescription(\n        "Compte de " + $sortie.getNomClient() + " : fonds recus puis "\n        + "retires en quasi-totalite en moins de 10 minutes, sans "\n        + "justification economique apparente (compte de passage)."\n    );\n    insertLogical(alerte);\nend'
WHERE regle_id = 3 AND est_active = TRUE;

UPDATE versions_regle
SET contenu_drl = 'rule "R004_VelocityTrigger_ExplosionFrequence"\n    salience 90\nwhen\n    $t : Transaction($client : nomClient)\n    $count : Number(intValue > 15) from accumulate(\n        Transaction(nomClient == $client) over window:time(1h),\n        count(1)\n    )\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R004 - Explosion de frequence (Velocity Trigger)");\n    alerte.setCriticite(CriticiteEnum.MOYEN);\n    alerte.setDescription(\n        "Compte " + $client + " : plus de 15 transactions enregistrees "\n        + "en 1 heure, frequence incompatible avec un usage normal "\n        + "(risque de location de compte ou de collecte illegale)."\n    );\n    insertLogical(alerte);\nend'
WHERE regle_id = 4 AND est_active = TRUE;

UPDATE versions_regle
SET contenu_drl = 'rule "R005_KycEcart_RevenuDeclare"\n    salience 80\nwhen\n    $t : Transaction($montant : montant, $client : nomClient)\n    $profil : ProfilClient(\n        nomClient == $client,\n        (revenuDeclare * 10) < $montant\n    )\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R005 - Depassement du revenu declare (KYC Ecart)");\n    alerte.setCriticite(CriticiteEnum.MOYEN);\n    alerte.setDescription(\n        "Client " + $client + " : transaction de " + $montant\n        + " FCFA, manifestement incoherente avec le revenu declare au "\n        + "KYC (" + $profil.getRevenuDeclare() + " FCFA/mois)."\n    );\n    insertLogical(alerte);\nend'
WHERE regle_id = 5 AND est_active = TRUE;

UPDATE versions_regle
SET contenu_drl = 'rule "R006_CompteDormant_Reactivation"\n    salience 80\nwhen\n    $t : Transaction($client : nomClient, montant > 500000)\n    $profil : ProfilClient(\n        nomClient == $client,\n        eval(ChronoUnit.DAYS.between(derniereActivite, LocalDateTime.now()) > 180)\n    )\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R006 - Reactivation brutale d''un compte dormant");\n    alerte.setCriticite(CriticiteEnum.MOYEN);\n    alerte.setDescription(\n        "Compte " + $client + " : inactif depuis plus de 6 mois, "\n        + "reactivation soudaine avec une transaction de " + $t.getMontant()\n        + " FCFA (risque d''usurpation ou de complicite interne)."\n    );\n    insertLogical(alerte);\nend'
WHERE regle_id = 6 AND est_active = TRUE;

-- Verification : affiche les 6 regles et un extrait de leur contenu_drl
SELECT regle_id, numero_version, LEFT(contenu_drl, 60) AS apercu
FROM versions_regle WHERE est_active = TRUE ORDER BY regle_id;