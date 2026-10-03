import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/regles_provider.dart';
import '../../theme/app_theme.dart';

class CatalogueReglesScreen extends StatefulWidget {
  const CatalogueReglesScreen({super.key});

  @override
  State<CatalogueReglesScreen> createState() => _CatalogueReglesScreenState();
}

class _CatalogueReglesScreenState extends State<CatalogueReglesScreen>
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
  }

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
              Text('Catalogue des règles',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('Vue d\'ensemble des règles actives et inactives en base',
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
                  child: _CarteRegle(regle: r),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Carte règle (lecture seule) ──────────────────────────────────────────────

class _CarteRegle extends StatelessWidget {
  final Map<String, dynamic> regle;

  const _CarteRegle({required this.regle});

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
    final bool estReglementaire = regle['estReglementaire'] == true;
    final bool active = regle['active'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.borderLight, width: 0.5),
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
                const SizedBox(width: 24),
                _InfoPuce(
                  icon: active
                      ? Icons.check_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  label: 'Statut',
                  valeur: active ? 'Active' : 'Inactive',
                  couleur: active ? AppColors.success : AppColors.textSecondary,
                ),
                if (regle['numeroVersion'] != null) ...[
                  const SizedBox(width: 24),
                  _InfoPuce(
                    icon: Icons.tag_rounded,
                    label: 'Version',
                    valeur: 'v${regle['numeroVersion']}',
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
