import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/historique_provider.dart';
import '../../theme/app_theme.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtreStatut = 'TOUS';
  final String _filtreCriticite = 'TOUS';
  DateTimeRange? _periode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      if (auth.token != null) {
        await context
            .read<HistoriqueProvider>()
            .chargerDemandesHistorique(auth.token!);
      }
    });
  }

  List<Map<String, dynamic>> _historiqueFromProvider(
      HistoriqueProvider provider) {
    return provider.demandesHistorique;
  }

  List<Map<String, dynamic>> _filtres(List<Map<String, dynamic>> historique) {
    return historique.where((h) {
      final q = _searchCtrl.text.toLowerCase();
      final matchSearch = q.isEmpty ||
          h['nom'].toString().toLowerCase().contains(q) ||
          h['description'].toString().toLowerCase().contains(q);
      final matchStatut =
          _filtreStatut == 'TOUS' || h['statut'] == _filtreStatut;
      final matchCriticite =
          _filtreCriticite == 'TOUS' || h['criticite'] == _filtreCriticite;
      final matchPeriode = _periode == null ||
          (h['traiteLe'] != null &&
              h['traiteLe'].isAfter(_periode!.start) &&
              h['traiteLe'].isBefore(_periode!.end));
      return matchSearch && matchStatut && matchCriticite && matchPeriode;
    }).toList();
  }

  int _countStatut(List<Map<String, dynamic>> historique, String statut) {
    return historique.where((h) => h['statut'] == statut).length;
  }

  Future<void> _choisirPeriode() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.blueImf),
        ),
        child: child!,
      ),
    );
    if (result != null) setState(() => _periode = result);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historiqueProvider = context.watch<HistoriqueProvider>();
    final historique = _historiqueFromProvider(historiqueProvider);
    final liste = _filtres(historique);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildTopbar(historiqueProvider, historique),
          _buildKpiRapide(historique, historiqueProvider.isLoading),
          _buildBarreOutils(),
          Expanded(child: _buildListe(liste, historiqueProvider.isLoading)),
        ],
      ),
    );
  }

  // ─── Topbar ───────────────────────────────────────────────────────────────

  Widget _buildTopbar(
      HistoriqueProvider historiqueProvider, List<Map<String, dynamic>> histo) {
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
              Text('Historique des validations',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('${histo.length} demande(s) traitée(s) au total',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              if (auth.token != null) {
                await context
                    .read<HistoriqueProvider>()
                    .chargerDemandesHistorique(auth.token!);
              }
            },
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border, width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: GoogleFonts.inter(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI rapide ───────────────────────────────────────────────────────────

  Widget _buildKpiRapide(
      List<Map<String, dynamic>> historique, bool isLoading) {
    final total = historique.length;
    final nbApprouvees = _countStatut(historique, 'APPROUVEE');
    final nbRejetees = _countStatut(historique, 'REJETEE');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _KpiPuce(
            label: 'Total traité',
            valeur: '$total',
            color: AppColors.blueImf,
            icon: Icons.rule_outlined,
          ),
          const SizedBox(width: 24),
          _KpiPuce(
            label: 'Approuvées',
            valeur: '$nbApprouvees',
            color: AppColors.success,
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(width: 24),
          _KpiPuce(
            label: 'Rejetées',
            valeur: '$nbRejetees',
            color: AppColors.danger,
            icon: Icons.cancel_outlined,
          ),
          const SizedBox(width: 24),
          _KpiPuce(
            label: 'Taux approbation',
            valeur: total > 0
                ? '${(nbApprouvees / total * 100).toStringAsFixed(0)}%'
                : '0%',
            color: AppColors.info,
            icon: Icons.percent_rounded,
          ),
        ],
      ),
    );
  }

  // ─── Barre outils ─────────────────────────────────────────────────────────

  Widget _buildBarreOutils() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Recherche
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher dans l\'historique...',
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

          // Filtre statut
          _FiltreChip(
            label: 'Tous',
            actif: _filtreStatut == 'TOUS',
            onTap: () => setState(() => _filtreStatut = 'TOUS'),
          ),
          const SizedBox(width: 6),
          _FiltreChip(
            label: 'Approuvées',
            actif: _filtreStatut == 'APPROUVEE',
            color: AppColors.success,
            onTap: () => setState(() => _filtreStatut = 'APPROUVEE'),
          ),
          const SizedBox(width: 6),
          _FiltreChip(
            label: 'Rejetées',
            actif: _filtreStatut == 'REJETEE',
            color: AppColors.danger,
            onTap: () => setState(() => _filtreStatut = 'REJETEE'),
          ),
          const SizedBox(width: 12),

          // Filtre période
          OutlinedButton.icon(
            onPressed: _choisirPeriode,
            icon: const Icon(Icons.calendar_today_outlined, size: 14),
            label: Text(
              _periode == null
                  ? 'Période'
                  : '${DateFormat('dd/MM').format(_periode!.start)} — ${DateFormat('dd/MM').format(_periode!.end)}',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _periode != null
                  ? AppColors.blueImf
                  : AppColors.textSecondary,
              side: BorderSide(
                color: _periode != null ? AppColors.blueImf : AppColors.border,
                width: 0.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
          ),
          if (_periode != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 15, color: AppColors.textSecondary),
              onPressed: () => setState(() => _periode = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Liste ────────────────────────────────────────────────────────────────

  Widget _buildListe(List<Map<String, dynamic>> liste, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_outlined,
                size: 40, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('Aucun résultat',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // En-tête tableau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: _EnTete('Règle')),
                Expanded(flex: 2, child: _EnTete('Criticité')),
                Expanded(flex: 2, child: _EnTete('Décision')),
                Expanded(flex: 2, child: _EnTete('Soumis le')),
                Expanded(flex: 2, child: _EnTete('Traité le')),
                SizedBox(width: 40),
              ],
            ),
          ),
          // Lignes
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              border: Border(
                left: BorderSide(color: AppColors.border, width: 0.5),
                right: BorderSide(color: AppColors.border, width: 0.5),
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Column(
              children: liste
                  .map((h) => _LigneHistorique(
                        item: h,
                        onVoir: () => _voirDetail(h),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _voirDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => _DialogDetail(item: item),
    );
  }
}

// ─── Ligne historique ─────────────────────────────────────────────────────────

class _LigneHistorique extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onVoir;

  const _LigneHistorique({required this.item, required this.onVoir});

  Color get _couleurCriticite {
    switch (item['criticite']) {
      case 'ELEVE':
        return AppColors.danger;
      case 'MOYEN':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final approuvee = item['statut'] == 'APPROUVEE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      child: Row(
        children: [
          // Règle
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _couleurCriticite,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nom'],
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['description'],
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Criticité
          Expanded(
            flex: 2,
            child: _Badge(
              label: item['criticite'],
              color: _couleurCriticite,
            ),
          ),
          // Décision
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  approuvee
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  size: 14,
                  color: approuvee ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 5),
                Text(
                  approuvee ? 'Approuvée' : 'Rejetée',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: approuvee ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          // Soumis le
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yyyy').format(item['soumisLe']),
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          // Traité le
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yyyy').format(item['traiteLe']),
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          // Action
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.open_in_new_rounded,
                  size: 16, color: AppColors.textSecondary),
              tooltip: 'Voir le détail',
              onPressed: onVoir,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog détail ────────────────────────────────────────────────────────────

class _DialogDetail extends StatelessWidget {
  final Map<String, dynamic> item;
  const _DialogDetail({required this.item});

  Color get _couleurCriticite {
    switch (item['criticite']) {
      case 'ELEVE':
        return AppColors.danger;
      case 'MOYEN':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final approuvee = item['statut'] == 'APPROUVEE';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Détail de la décision',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600)),
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
            _InfoLigne(label: 'Règle', valeur: item['nom']),
            const SizedBox(height: 10),
            _InfoLigne(label: 'Description', valeur: item['description']),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 90,
                  child: Text('Criticité',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
                _Badge(label: item['criticite'], color: _couleurCriticite),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 90,
                  child: Text('Décision',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
                Icon(
                  approuvee
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  size: 14,
                  color: approuvee ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 5),
                Text(
                  approuvee ? 'Approuvée' : 'Rejetée',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: approuvee ? AppColors.success : AppColors.danger),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoLigne(
              label: 'Soumis le',
              valeur: DateFormat('dd/MM/yyyy à HH:mm').format(item['soumisLe']),
            ),
            const SizedBox(height: 10),
            _InfoLigne(
              label: 'Traité le',
              valeur: DateFormat('dd/MM/yyyy à HH:mm').format(item['traiteLe']),
            ),
            if (item['motifRejet'] != null) ...[
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
                          Text(item['motifRejet'],
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.danger,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (item['motifDemande'] != null &&
                item['motifDemande'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoLigne(
                label: 'Motif demande',
                valeur: item['motifDemande'].toString(),
              ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer',
                    style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Composants ───────────────────────────────────────────────────────────────

class _KpiPuce extends StatelessWidget {
  final String label;
  final String valeur;
  final Color color;
  final IconData icon;

  const _KpiPuce({
    required this.label,
    required this.valeur,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valeur,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w500, color: color)),
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
          border: Border.all(color: actif ? c : AppColors.border, width: 0.5),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: actif ? c : AppColors.textSecondary,
                fontWeight: actif ? FontWeight.w500 : FontWeight.w400)),
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  final String label;
  const _EnTete(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.8));
  }
}

class _InfoLigne extends StatelessWidget {
  final String label;
  final String valeur;
  const _InfoLigne({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(valeur,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
