import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/regles_provider.dart';
import '../../theme/app_theme.dart';
import 'regle_builder_screen.dart';

class MetierReglesScreen extends StatefulWidget {
  const MetierReglesScreen({super.key});

  @override
  State<MetierReglesScreen> createState() => _MetierReglesScreenState();
}

class _MetierReglesScreenState extends State<MetierReglesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtreCriticite = 'TOUS';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<ReglesProvider>();
    await provider.chargerRegles(auth.token ?? '');
    await provider.chargerDemandes(auth.token ?? '');
  }

  // ─── Filtrage ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _filtrer(bool active) {
    final regles = context.watch<ReglesProvider>().regles;
    return regles.where((r) {
      final q = _searchCtrl.text.toLowerCase();
      final matchSearch = q.isEmpty ||
          r['nom'].toString().toLowerCase().contains(q) ||
          r['description'].toString().toLowerCase().contains(q);
      final matchCriticite =
          _filtreCriticite == 'TOUS' || r['criticite'] == _filtreCriticite;
      return matchSearch && matchCriticite && r['active'] == active;
    }).toList();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _demanderCreation() {
    showDialog(
      context: context,
      builder: (_) => RegleBuilderScreen(
        onSoumettre: (data) async {
          final ok = await _soumettreDemande(
            type: 'CREATION',
            data: {
              'nom': data['nom'] ?? '',
              'description': data['description'] ?? '',
              'criticite': data['criticite'] ?? 'MOYEN',
              'contenuDrl': data['contenuDrl'] ?? '',
              'conditions': data['conditions'] ?? '',
            },
          );
          if (ok) {
            _showConfirmation('Demande de création soumise au validateur.');
          } else {
            _showErreur('Impossible de soumettre la demande.');
          }
        },
      ),
    );
  }

  void _demanderModification(Map<String, dynamic> regle) {
    if (regle['demandeEnCours'] == true) {
      _showErreur('Une demande est déjà en cours pour cette règle.');
      return;
    }
    if (regle['estReglementaire'] == true) {
      _showErreur('Les règles réglementaires ne peuvent pas être modifiées.');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => RegleBuilderScreen(
        regleExistante: regle,
        onSoumettre: (data) async {
          final ok = await _soumettreDemande(
            type: 'MODIFICATION',
            regleId: regle['id'],
            data: {
              'description': data['description'] ?? '',
              'contenuDrl': data['contenuDrl'] ?? '',
              'conditions': data['conditions'] ?? '',
            },
          );
          if (ok) {
            _showConfirmation('Demande de modification soumise au validateur.');
          } else {
            _showErreur('Impossible de soumettre la demande.');
          }
        },
      ),
    );
  }

  void _demanderSuppression(Map<String, dynamic> regle) {
    if (regle['demandeEnCours'] == true) {
      _showErreur('Une demande est déjà en cours pour cette règle.');
      return;
    }
    if (regle['estReglementaire'] == true) {
      _showErreur('Les règles réglementaires ne peuvent pas être supprimées.');
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Demander la suppression',
            style:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Text(
          'Soumettre une demande de suppression pour "${regle['nom']}" ?\n'
          'Le validateur devra approuver avant toute suppression.',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final ok = await _soumettreDemande(
                type: 'SUPPRESSION',
                regleId: regle['id'],
                data: const {},
              );
              if (ok) {
                _showConfirmation(
                    'Demande de suppression soumise au validateur.');
              } else {
                _showErreur('Impossible de soumettre la demande.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  void _demanderActivation(Map<String, dynamic> regle) {
    if (regle['demandeEnCours'] == true) {
      _showErreur('Une demande est déjà en cours pour cette règle.');
      return;
    }
    final bool active = regle['active'] == true;
    final action = active ? 'désactiver' : 'activer';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Demander l\'${action}ation',
            style:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Text(
          'Soumettre une demande pour $action "${regle['nom']}" ?\n'
          'Le validateur devra approuver.',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final ok = await _soumettreDemande(
                type: active ? 'DESACTIVATION' : 'ACTIVATION',
                regleId: regle['id'],
                data: const {},
              );
              if (ok) {
                _showConfirmation('Demande soumise au validateur.');
              } else {
                _showErreur('Impossible de soumettre la demande.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blueImf,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  Future<bool> _soumettreDemande({
    required String type,
    int? regleId,
    required Map<String, dynamic> data,
  }) async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<ReglesProvider>();
    return provider.soumettreDemande(
      token: auth.token ?? '',
      type: type,
      regleId: regleId,
      data: data,
    );
  }

  void _showConfirmation(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white))),
        ],
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showErreur(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white))),
        ],
      ),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ReglesProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildTopbar(),
          _buildBarreOutils(),
          _buildTabs(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContenu(),
          ),
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
              Text('Gestion des règles',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('Toute modification est soumise à validation',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _charger,
            icon: const Icon(Icons.refresh_rounded,
                size: 18, color: AppColors.textSecondary),
            tooltip: 'Actualiser',
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColors.info),
                const SizedBox(width: 6),
                Text('Les demandes sont soumises au validateur',
                    style:
                        GoogleFonts.inter(fontSize: 11, color: AppColors.info)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _demanderCreation,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Nouvelle règle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: GoogleFonts.inter(fontSize: 13),
              elevation: 0,
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
          _FiltreChip(
            label: 'Tous',
            actif: _filtreCriticite == 'TOUS',
            onTap: () => setState(() => _filtreCriticite = 'TOUS'),
          ),
          const SizedBox(width: 6),
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
                const Icon(Icons.check_circle_outline_rounded, size: 15),
                const SizedBox(width: 6),
                Text('Actives (${_filtrer(true).length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause_circle_outline_rounded, size: 15),
                const SizedBox(width: 6),
                Text('Inactives (${_filtrer(false).length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Contenu ──────────────────────────────────────────────────────────────

  Widget _buildContenu() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildListe(_filtrer(true)),
        _buildListe(_filtrer(false)),
      ],
    );
  }

  Widget _buildListe(List<Map<String, dynamic>> liste) {
    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rule_outlined,
                size: 40, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('Aucune règle trouvée',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary)),
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
                    onModifier: () => _demanderModification(r),
                    onSupprimer: () => _demanderSuppression(r),
                    onToggleActivation: () => _demanderActivation(r),
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
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;
  final VoidCallback onToggleActivation;

  const _CarteRegle({
    required this.regle,
    required this.onModifier,
    required this.onSupprimer,
    required this.onToggleActivation,
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

  String get _labelCriticite {
    switch (regle['criticite']) {
      case 'ELEVE':
        return 'Élevée';
      case 'MOYEN':
        return 'Moyenne';
      default:
        return 'Faible';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool demandeEnCours = regle['demandeEnCours'] == true;
    final bool estReglementaire = regle['estReglementaire'] == true;
    final bool active = regle['active'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: demandeEnCours
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
          width: demandeEnCours ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            child: Text(regle['nom'] ?? '-',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                              label: _labelCriticite, color: _couleurCriticite),
                          if (estReglementaire) ...[
                            const SizedBox(width: 6),
                            const _Badge(
                                label: 'Réglementaire',
                                color: AppColors.blueImf),
                          ],
                          if (demandeEnCours) ...[
                            const SizedBox(width: 6),
                            const _Badge(
                                label: 'Demande en cours',
                                color: AppColors.warning,
                                icon: Icons.pending_actions_outlined),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(regle['description'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Infos ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 8),
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
                  icon: Icons.calendar_today_outlined,
                  label: 'Créée le',
                  valeur: regle['dateCreation'] is DateTime
                      ? DateFormat('dd/MM/yyyy').format(regle['dateCreation'])
                      : '-',
                ),
                const SizedBox(width: 20),
                _InfoPuce(
                  icon: active
                      ? Icons.check_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  label: 'Statut',
                  valeur: active ? 'Active' : 'Inactive',
                  couleur: active ? AppColors.success : AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // ── Actions ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 10, 16, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: demandeEnCours ? null : onToggleActivation,
                  icon: Icon(
                    active
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 14,
                  ),
                  label: Text(active ? 'Désactiver' : 'Activer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        active ? AppColors.warning : AppColors.success,
                    side: BorderSide(
                      color: active ? AppColors.warning : AppColors.success,
                      width: 0.5,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    textStyle: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
                const Spacer(),
                if (!estReglementaire) ...[
                  OutlinedButton.icon(
                    onPressed: demandeEnCours ? null : onModifier,
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blueImf,
                      side: const BorderSide(
                          color: AppColors.blueImf, width: 0.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      textStyle: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: demandeEnCours ? null : onSupprimer,
                    icon: const Icon(Icons.delete_outline_rounded, size: 14),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side:
                          const BorderSide(color: AppColors.danger, width: 0.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      textStyle: GoogleFonts.inter(fontSize: 12),
                    ),
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
    return Row(
      children: [
        Icon(icon, size: 13, color: couleur ?? AppColors.textSecondary),
        const SizedBox(width: 5),
        Column(
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
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
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
