import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/regles_provider.dart';
import '../../theme/app_theme.dart';

class ReglesScreen extends StatefulWidget {
  const ReglesScreen({super.key});

  @override
  State<ReglesScreen> createState() => _ReglesScreenState();
}

class _ReglesScreenState extends State<ReglesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtreCriticite = 'TOUS';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _chargerDemandes());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerDemandes() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<ReglesProvider>();
    await provider.chargerDemandes(auth.token ?? '');
    if (mounted) {
      setState(() {});
    }
  }

  List<Map<String, dynamic>> _filtrerPar(String statut) {
    final demandes = context.read<ReglesProvider>().demandes;
    return demandes.where((r) {
      final q = _searchCtrl.text.toLowerCase();
      final matchSearch = q.isEmpty ||
          r['nom'].toString().toLowerCase().contains(q) ||
          r['description'].toString().toLowerCase().contains(q);
      final matchCriticite =
          _filtreCriticite == 'TOUS' || r['criticite'] == _filtreCriticite;
      final matchStatut = statut == 'TOUS' || r['statut'] == statut;
      return matchSearch && matchCriticite && matchStatut;
    }).toList();
  }

  int get _nbEnAttente => context.read<ReglesProvider>().nbDemandesEnAttente;

  void _approuver(Map<String, dynamic> regle) {
    showDialog(
      context: context,
      builder: (_) => _DialogAction(
        titre: 'Approuver la règle',
        message:
            'Confirmer l\'approbation de "${regle['nom']}" ?\nElle sera compilée et activée dans Drools.',
        labelConfirm: 'Approuver',
        couleur: AppColors.success,
        avecMotif: false,
        onConfirm: (_) async {
          final auth = context.read<AuthProvider>();
          final provider = context.read<ReglesProvider>();
          await provider.approuverDemande(auth.token ?? '', regle['id']);
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _rejeter(Map<String, dynamic> regle) {
    showDialog(
      context: context,
      builder: (_) => _DialogAction(
        titre: 'Rejeter la règle',
        message: 'Indiquez le motif de rejet pour "${regle['nom']}".',
        labelConfirm: 'Rejeter',
        couleur: AppColors.danger,
        avecMotif: true,
        onConfirm: (motif) async {
          final auth = context.read<AuthProvider>();
          final provider = context.read<ReglesProvider>();
          await provider.rejeterDemande(
              auth.token ?? '', regle['id'], motif ?? '');
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _examiner(Map<String, dynamic> regle) {
    showDialog(
      context: context,
      builder: (_) => _DialogExamen(
        regle: regle,
        onApprouver: () => _approuver(regle),
        onRejeter: () => _rejeter(regle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ReglesProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildTopbar(),
          _buildBarreOutils(),
          _buildTabs(),
          Expanded(child: _buildContenu()),
        ],
      ),
    );
  }

  // ─── Topbar ───────────────────────────────────────────────────────────────

  Widget _buildTopbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Règles de détection',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('Consulter, examiner et valider les demandes',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          if (_nbEnAttente > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending_actions_outlined,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text('$_nbEnAttente en attente',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.warning)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Barre outils ─────────────────────────────────────────────────────────

  Widget _buildBarreOutils() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher une règle...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 17, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.blueImf, width: 1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filtre criticité
          _FiltreChip(
            label: 'Élevée',
            actif: _filtreCriticite == 'ELEVE',
            color: AppColors.danger,
            onTap: () => setState(() => _filtreCriticite = 'ELEVE'),
          ),
          const SizedBox(width: 6),
          _FiltreChip(
            label: 'Moyenne',
            actif: _filtreCriticite == 'MOYEN',
            color: AppColors.warning,
            onTap: () => setState(() => _filtreCriticite = 'MOYEN'),
          ),
          const SizedBox(width: 6),
          _FiltreChip(
            label: 'Faible',
            actif: _filtreCriticite == 'FAIBLE',
            color: AppColors.info,
            onTap: () => setState(() => _filtreCriticite = 'FAIBLE'),
          ),
        ],
      ),
    );
  }

  // ─── Tabs ─────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
        labelColor: AppColors.blueImf,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.blueImf,
        indicatorWeight: 2,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('En attente'),
                const SizedBox(width: 6),
                if (_nbEnAttente > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$_nbEnAttente',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const Tab(text: 'Approuvées'),
          const Tab(text: 'Rejetées'),
        ],
      ),
    );
  }

  // ─── Contenu tabs ─────────────────────────────────────────────────────────

  Widget _buildContenu() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildListe('EN_ATTENTE'),
        _buildListe('APPROUVEE'),
        _buildListe('REJETEE'),
      ],
    );
  }

  Widget _buildListe(String statut) {
    final liste = _filtrerPar(statut);

    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statut == 'EN_ATTENTE'
                  ? Icons.check_circle_outline_rounded
                  : Icons.inbox_outlined,
              size: 40,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              statut == 'EN_ATTENTE'
                  ? 'Aucune règle en attente'
                  : 'Aucune règle ici',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: liste
            .map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CarteRegle(
                    regle: r,
                    onExaminer: () => _examiner(r),
                    onApprouver: r['statut'] == 'EN_ATTENTE'
                        ? () => _approuver(r)
                        : null,
                    onRejeter:
                        r['statut'] == 'EN_ATTENTE' ? () => _rejeter(r) : null,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Carte règle ──────────────────────────────────────────────────────────────

class _CarteRegle extends StatelessWidget {
  final Map<String, dynamic> regle;
  final VoidCallback onExaminer;
  final VoidCallback? onApprouver;
  final VoidCallback? onRejeter;

  const _CarteRegle({
    required this.regle,
    required this.onExaminer,
    this.onApprouver,
    this.onRejeter,
  });

  Color get _couleurCriticite {
    switch (regle['criticite']) {
      case 'ELEVE':
        return AppColors.danger;
      case 'MOYEN':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  Color get _couleurStatut {
    switch (regle['statut']) {
      case 'APPROUVEE':
        return AppColors.success;
      case 'REJETEE':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  IconData get _iconeStatut {
    switch (regle['statut']) {
      case 'APPROUVEE':
        return Icons.check_circle_outline_rounded;
      case 'REJETEE':
        return Icons.cancel_outlined;
      default:
        return Icons.pending_actions_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enAttente = regle['statut'] == 'EN_ATTENTE';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header carte
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barre criticité
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _couleurCriticite,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              regle['nom']?.toString() ?? '-',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                            label: regle['criticite']?.toString() ?? 'MOYEN',
                            color: _couleurCriticite,
                          ),
                          const SizedBox(width: 6),
                          _Badge(
                            label: regle['statut'] == 'EN_ATTENTE'
                                ? 'EN ATTENTE'
                                : (regle['statut']?.toString() ?? ''),
                            color: _couleurStatut,
                            icon: _iconeStatut,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        regle['description']?.toString() ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Infos ligne
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.borderLight, width: 0.5),
                bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                _InfoPuce(
                  icon: Icons.code_rounded,
                  label: 'Conditions',
                  valeur: regle['conditions']?.toString() ?? '',
                ),
                const SizedBox(width: 24),
                _InfoPuce(
                  icon: Icons.tag_rounded,
                  label: 'Version',
                  valeur: 'v${regle['version']?.toString() ?? '1'}',
                ),
                const SizedBox(width: 24),
                _InfoPuce(
                  icon: Icons.access_time_rounded,
                  label: 'Soumis',
                  valeur: regle['soumisLe'] is DateTime
                      ? DateFormat('dd/MM/yyyy HH:mm').format(regle['soumisLe'])
                      : '-',
                ),
                if (regle['motifDemande'] != null &&
                    regle['motifDemande'].toString().isNotEmpty) ...[
                  const SizedBox(width: 24),
                  _InfoPuce(
                    icon: Icons.description_outlined,
                    label: 'Motif demande',
                    valeur: regle['motifDemande'].toString(),
                  ),
                ],
                if (regle['motifRejet'] != null) ...[
                  const SizedBox(width: 24),
                  _InfoPuce(
                    icon: Icons.info_outline_rounded,
                    label: 'Motif rejet',
                    valeur: regle['motifRejet'],
                    couleur: AppColors.danger,
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 10, 16, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onExaminer,
                  icon: const Icon(Icons.search_rounded, size: 14),
                  label: const Text('Examiner le DRL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blueImf,
                    side:
                        const BorderSide(color: AppColors.blueImf, width: 0.5),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
                const Spacer(),
                if (enAttente) ...[
                  OutlinedButton(
                    onPressed: onRejeter,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side:
                          const BorderSide(color: AppColors.danger, width: 0.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 12),
                    ),
                    child: const Text('Rejeter'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onApprouver,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 12),
                    ),
                    child: const Text('Approuver'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog examen DRL ────────────────────────────────────────────────────────

class _DialogExamen extends StatelessWidget {
  final Map<String, dynamic> regle;
  final VoidCallback onApprouver;
  final VoidCallback onRejeter;

  const _DialogExamen({
    required this.regle,
    required this.onApprouver,
    required this.onRejeter,
  });

  @override
  Widget build(BuildContext context) {
    final enAttente = regle['statut'] == 'EN_ATTENTE';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(regle['nom']?.toString() ?? '-',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('Examen du contenu DRL',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 16),

            // Méta infos
            Row(
              children: [
                _MetaChip(
                  label: regle['criticite'] == 'ELEVE'
                      ? 'Élevée'
                      : regle['criticite'] == 'MOYEN'
                          ? 'Moyenne'
                          : 'Faible',
                  color: regle['criticite'] == 'ELEVE'
                      ? AppColors.danger
                      : regle['criticite'] == 'MOYEN'
                          ? AppColors.warning
                          : AppColors.info,
                ),
                const SizedBox(width: 8),
                _MetaChip(
                  label: 'v${regle['numeroVersion']?.toString() ?? '1'}',
                  color: AppColors.blueImf,
                ),
                const SizedBox(width: 8),
                Text(
                  'Soumis le ${regle['soumisLe'] is DateTime ? DateFormat('dd/MM/yyyy à HH:mm').format(regle['soumisLe']) : '-'}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Description
            Text('Description',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(regle['description']?.toString() ?? '',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 14),

            // Conditions lisibles
            Text('Conditions',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.blueImf.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.blueImf.withValues(alpha: 0.2),
                    width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.code_rounded,
                      size: 14, color: AppColors.blueImf),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(regle['conditions']?.toString() ?? '',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 12, color: AppColors.blueImf)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Contenu DRL
            Text('Contenu DRL',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  (regle['contenuDrl'] ?? '').toString().isEmpty
                      ? '— Aucun contenu DRL disponible —'
                      : (regle['contenuDrl']?.toString() ?? ''),
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, color: AppColors.success, height: 1.7),
                ),
              ),
            ),

            // Motif de la demande (généré automatiquement par le backend)
            if (regle['motifDemande'] != null &&
                regle['motifDemande'].toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Motif de la demande',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(regle['motifDemande'].toString(),
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5)),
            ],

            // Motif rejet si existant
            if (regle['motifRejet'] != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.2),
                      width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Motif de rejet',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger)),
                          const SizedBox(height: 2),
                          Text(regle['motifRejet']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Fermer',
                      style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ),
                if (enAttente) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onRejeter();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side:
                          const BorderSide(color: AppColors.danger, width: 0.5),
                    ),
                    child: const Text('Rejeter'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onApprouver();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Approuver'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dialog action ────────────────────────────────────────────────────────────

class _DialogAction extends StatefulWidget {
  final String titre;
  final String message;
  final String labelConfirm;
  final Color couleur;
  final bool avecMotif;
  final Function(String?) onConfirm;

  const _DialogAction({
    required this.titre,
    required this.message,
    required this.labelConfirm,
    required this.couleur,
    required this.avecMotif,
    required this.onConfirm,
  });

  @override
  State<_DialogAction> createState() => _DialogActionState();
}

class _DialogActionState extends State<_DialogAction> {
  final _motifCtrl = TextEditingController();

  @override
  void dispose() {
    _motifCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(widget.titre,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          if (widget.avecMotif) ...[
            const SizedBox(height: 14),
            Text('Motif de rejet',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _motifCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Décrivez la raison du rejet...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.blueImf, width: 1),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler',
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm(widget.avecMotif ? _motifCtrl.text : null);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.couleur,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child:
              Text(widget.labelConfirm, style: GoogleFonts.inter(fontSize: 13)),
        ),
      ],
    );
  }
}

// ─── Composants ───────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

class _InfoPuce extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valeur;
  final Color? couleur;

  const _InfoPuce({
    required this.icon,
    required this.label,
    required this.valeur,
    this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: couleur ?? AppColors.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
                Text(valeur,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: couleur ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltreChip extends StatelessWidget {
  final String label;
  final bool actif;
  final VoidCallback onTap;
  final Color? color;

  const _FiltreChip({
    required this.label,
    required this.actif,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.blueImf;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: actif ? c.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: actif ? c : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: actif ? c : AppColors.textSecondary,
            fontWeight: actif ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
