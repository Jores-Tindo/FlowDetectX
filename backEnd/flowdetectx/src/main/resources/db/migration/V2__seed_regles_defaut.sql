-- ====================================================================
-- RuleDetect-IMF - V2 : Compte administrateur racine + 6 regles par defaut
-- ====================================================================

-- ==================== COMPTE ADMINISTRATEUR RACINE ====================
-- Seul compte cree directement en base (cree_par = NULL).
-- Mot de passe par defaut "Admin@2026" hache en BCrypt (a changer en prod).
-- Identifiant : admin.racine
INSERT INTO utilisateurs
    (nom, prenom, email, identifiant, mot_de_passe, role, statut, cree_par, date_creation)
VALUES
    ('ADMIN', 'Racine', 'admin@ruledetect-imf.bj', 'admin.racine',
     '$2a$10$WlPMrhdYNHpUQK2gQyqGwOEpC8B0eO9TUtcEduXMb2gI2jVUE3qbi',
     'ADMINISTRATEUR', 'ACTIF', NULL, NOW());

-- ==================== 6 REGLES DE DETECTION PAR DEFAUT ====================
-- Issues des typologies documentees par la CENTIF-BJ, le GIABA, l'ANSSFD,
-- la BCEAO (Instruction N 233/07/2024) et la Loi Uniforme LBC/FT de l'UMOA.
-- cree_par = id du compte admin racine (id=1)

INSERT INTO regles_detection (nom, description, criticite, statut, est_reglementaire, cree_par, date_creation)
VALUES
('R001 - Depot fractionne d''especes (Smurfing)',
 'Detecte plusieurs petits depots en especes realises par un meme client sur une courte periode, visant a contourner les seuils de declaration obligatoire. Reference : Rapport GIABA sur les typologies de blanchiment au Benin.',
 'ELEVE', 'ACTIVE', TRUE, 1, NOW()),

('R002 - Operation cash hors profil',
 'Detecte tout versement en especes dont le montant depasse le seuil de 5 000 000 FCFA fixe par l''Instruction BCEAO N 233/07/2024, au-dela duquel les instruments de paiement traçables deviennent obligatoires dans l''UMOA.',
 'ELEVE', 'ACTIVE', TRUE, 1, NOW()),

('R003 - Transit rapide de fonds (Pass-through)',
 'Detecte un compte recevant des fonds qui sont immediatement retires en totalite ou en quasi-totalite, sans justification economique apparente. Reference : Rapport CENTIF-BJ sur les typologies de cybercriminalite.',
 'ELEVE', 'ACTIVE', TRUE, 1, NOW()),

('R004 - Explosion de frequence transactionnelle (Velocity Trigger)',
 'Detecte un nombre anormalement eleve de transactions sur un meme compte sur une periode tres courte. Reference : Directives ANSSFD sur la surveillance des SFD.',
 'MOYEN', 'ACTIVE', TRUE, 1, NOW()),

('R005 - Depassement du revenu declare (KYC Ecart)',
 'Detecte une transaction dont le montant est manifestement disproportionne par rapport au profil economique du client enregistre lors du KYC. Reference : Loi Uniforme LBC/FT UMOA - obligation de vigilance constante.',
 'MOYEN', 'ACTIVE', TRUE, 1, NOW()),

('R006 - Reactivation brutale d''un compte dormant',
 'Detecte un compte inactif depuis une longue periode dont l''activite reprend soudainement avec des transactions de volume important. Reference : Typologies CENTIF-BJ sur les fraudes internes aux IMF.',
 'MOYEN', 'ACTIVE', TRUE, 1, NOW());

-- ==================== VERSION 1 ACTIVE POUR CHACUNE DES 6 REGLES ====================
-- IMPORTANT : contenu_drl ne contient QUE le bloc "rule ... when ... then ... end".
-- Le package, les imports et le "declare Transaction" sont rajoutes par
-- MoteurDroolsService.ENTETE_DRL avant compilation. Le corps de chaque regle
-- ci-dessous est une copie exacte des fichiers src/main/resources/rules/*.drl
-- (Alerte construite via new Alerte() + setters, jamais via un constructeur
-- a arguments qui n'existe pas sur l'entite).

INSERT INTO versions_regle (regle_id, numero_version, conditions, contenu_drl, est_active, statut, date_creation)
VALUES
(1, 1, 'nombreDepots >= 3 ET montantTotal24h >= 2000000 ET memeClient = true',
 'rule "R001_Smurfing_DepotFractionne"\n    salience 100\nwhen\n    $t : Transaction(type == "CASH_IN", montant < 2000000)\n    $count : Number(intValue >= 3) from accumulate(\n        Transaction(\n            nomClient == $t.nomClient,\n            type == "CASH_IN"\n        ) over window:time(24h),\n        count(1)\n    )\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R001 - Depot fractionne d''especes (Smurfing)");\n    alerte.setCriticite(CriticiteEnum.ELEVE);\n    alerte.setDescription(\n        "Client " + $t.getNomClient() + " : au moins 3 depots en especes "\n        + "en moins de 24h, montant cumule suspect de fractionnement "\n        + "(seuil de declaration potentiellement contourne)."\n    );\n    insertLogical(alerte);\nend',
 TRUE, 'ACTIVE', NOW()),

(2, 1, 'type == CASH_IN ET montant > 5000000',
 'rule "R002_CashHorsProfil_SeuilBCEAO"\n    salience 100\nwhen\n    $t : Transaction(type == "CASH_IN", montant > 5000000)\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R002 - Operation cash hors profil");\n    alerte.setCriticite(CriticiteEnum.ELEVE);\n    alerte.setDescription(\n        "Versement en especes de " + $t.getMontant() + " FCFA par "\n        + $t.getNomClient() + ", superieur au seuil de 5 000 000 FCFA "\n        + "fixe par l''Instruction BCEAO N 233/07/2024."\n    );\n    insertLogical(alerte);\nend',
 TRUE, 'ACTIVE', NOW()),

(3, 1, 'montantRecu >= 0.9 * montantRetireImmediat ET delaiRetrait < 10 minutes',
 'rule "R003_PassThrough_TransitRapide"\n    salience 100\nwhen\n    $sortie : Transaction(type == "CASH_OUT")\n    $entree : Transaction(\n        nomClient == $sortie.nomClient,\n        type == "CASH_IN",\n        montant >= ($sortie.montant * 0.9),\n        this after[0s, 10m] $sortie\n    )\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R003 - Transit rapide de fonds (Pass-through)");\n    alerte.setCriticite(CriticiteEnum.ELEVE);\n    alerte.setDescription(\n        "Compte de " + $sortie.getNomClient() + " : fonds recus puis "\n        + "retires en quasi-totalite en moins de 10 minutes, sans "\n        + "justification economique apparente (compte de passage)."\n    );\n    insertLogical(alerte);\nend',
 TRUE, 'ACTIVE', NOW()),

(4, 1, 'nombreTransactions1h > 15 ET memeClient = true',
 'rule "R004_VelocityTrigger_ExplosionFrequence"\n    salience 90\nwhen\n    $t : Transaction($client : nomClient)\n    $count : Number(intValue > 15) from accumulate(\n        Transaction(nomClient == $client) over window:time(1h),\n        count(1)\n    )\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R004 - Explosion de frequence (Velocity Trigger)");\n    alerte.setCriticite(CriticiteEnum.MOYEN);\n    alerte.setDescription(\n        "Compte " + $client + " : plus de 15 transactions enregistrees "\n        + "en 1 heure, frequence incompatible avec un usage normal "\n        + "(risque de location de compte ou de collecte illegale)."\n    );\n    insertLogical(alerte);\nend',
 TRUE, 'ACTIVE', NOW()),

(5, 1, 'montantTransaction > (revenuDeclareKYC * 10)',
 'rule "R005_KycEcart_RevenuDeclare"\n    salience 80\nwhen\n    $t : Transaction($montant : montant, $client : nomClient)\n    $profil : ProfilClient(\n        nomClient == $client,\n        (revenuDeclare * 10) < $montant\n    )\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R005 - Depassement du revenu declare (KYC Ecart)");\n    alerte.setCriticite(CriticiteEnum.MOYEN);\n    alerte.setDescription(\n        "Client " + $client + " : transaction de " + $montant\n        + " FCFA, manifestement incoherente avec le revenu declare au "\n        + "KYC (" + $profil.getRevenuDeclare() + " FCFA/mois)."\n    );\n    insertLogical(alerte);\nend',
 TRUE, 'ACTIVE', NOW()),

(6, 1, 'compteInactifDepuis > 180 jours ET nouvelleTransaction.montant > 500000',
 'rule "R006_CompteDormant_Reactivation"\n    salience 80\nwhen\n    $t : Transaction($client : nomClient, montant > 500000)\n    $profil : ProfilClient(\n        nomClient == $client,\n        eval(ChronoUnit.DAYS.between(derniereActivite, LocalDateTime.now()) > 180)\n    )\nthen\n    Alerte alerte = new Alerte();\n    alerte.setRegleNom("R006 - Reactivation brutale d''un compte dormant");\n    alerte.setCriticite(CriticiteEnum.MOYEN);\n    alerte.setDescription(\n        "Compte " + $client + " : inactif depuis plus de 6 mois, "\n        + "reactivation soudaine avec une transaction de " + $t.getMontant()\n        + " FCFA (risque d''usurpation ou de complicite interne)."\n    );\n    insertLogical(alerte);\nend',
 TRUE, 'ACTIVE', NOW());