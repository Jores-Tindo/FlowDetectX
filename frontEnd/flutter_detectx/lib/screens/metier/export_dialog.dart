import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/export_service.dart';

class ExportDialog extends StatefulWidget {
  final List<Map<String, dynamic>> alertes;

  const ExportDialog({super.key, required this.alertes});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  FormatExport _format = FormatExport.pdf;
  String _criticite = 'TOUS';
  DateTimeRange? _periode;
  final TextEditingController _rechercheCtrl = TextEditingController();
  String? _dossierDestination;
  bool _enCours = false;
  String? _cheminResultat;
  String? _erreur;

  // Au-delà de ce volume en PDF, on prévient l'utilisateur avant même
  // qu'il lance l'export (le PDF sera tronqué, voir export_service.dart).
  static const int _seuilAvertissementPDF = 3000;

  int get _nbAlertesFiltrees => ExportService.filtrerAlertes(
        widget.alertes,
        FiltreExport(
          criticite: _criticite,
          periode: _periode,
          recherche: _rechercheCtrl.text,
        ),
      ).length;

  Future<void> _choisirDossier() async {
    final dossier = await ExportService.choisirDossier();
    if (dossier != null) setState(() => _dossierDestination = dossier);
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

  Future<void> _exporter() async {
    if (_nbAlertesFiltrees == 0) {
      setState(() =>
          _erreur = 'Aucune alerte ne correspond aux filtres sélectionnés.');
      return;
    }

    setState(() {
      _enCours = true;
      _erreur = null;
      _cheminResultat = null;
    });

    // La génération tourne désormais dans un isolate séparé (compute()) :
    // l'UI reste réactive même avec plusieurs dizaines de milliers
    // d'alertes, quel que soit le format.
    final resultat = await ExportService.exporter(
      alertes: widget.alertes,
      filtre: FiltreExport(
        criticite: _criticite,
        periode: _periode,
        recherche: _rechercheCtrl.text,
      ),
      format: _format,
      dossierDestination: _dossierDestination,
    );

    if (!mounted) return;
    setState(() {
      _enCours = false;
      if (resultat.chemin != null) {
        _cheminResultat = resultat.chemin;
      } else {
        _erreur =
            resultat.erreur ?? 'Échec de l\'export pour une raison inconnue.';
      }
    });
  }

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final volumeImportantPDF = _format == FormatExport.pdf &&
        _nbAlertesFiltrees > _seuilAvertissementPDF;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.blueImf.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.download_rounded,
                      size: 18, color: AppColors.blueImf),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Exporter les alertes',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('${widget.alertes.length} alerte(s) disponible(s)',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary)),
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

            const SizedBox(height: 20),
            const Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 20),

            // Résultat succès
            if (_cheminResultat != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text('Export réussi !',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _cheminResultat!,
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ExportService.ouvrirFichier(_cheminResultat!),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('Ouvrir le fichier'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.blueImf,
                          side: const BorderSide(
                              color: AppColors.blueImf, width: 0.5),
                          textStyle: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Erreur (message réel remonté par ExportService, plus jamais
            // un texte générique qui pointe à tort vers le dossier)
            if (_erreur != null) ...[
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
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 14, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_erreur!,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Avertissement volume important + PDF
            if (volumeImportantPDF && _erreur == null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Volume important ($_nbAlertesFiltrees alertes) : le PDF '
                        'affichera uniquement les $_seuilAvertissementPDF premières. '
                        'Pour un export complet, utilisez Excel ou CSV.',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.warning,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Format ────────────────────────────────────────────────────
            const _SectionLabel(label: 'Format d\'export'),
            const SizedBox(height: 10),
            Row(
              children: [
                _FormatCard(
                  format: FormatExport.pdf,
                  selected: _format == FormatExport.pdf,
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  description: 'Rapport formaté\nprêt à imprimer',
                  color: AppColors.danger,
                  onTap: () => setState(() => _format = FormatExport.pdf),
                ),
                const SizedBox(width: 10),
                _FormatCard(
                  format: FormatExport.excel,
                  selected: _format == FormatExport.excel,
                  icon: Icons.table_chart_outlined,
                  label: 'Excel',
                  description: 'Tableau avec\nmise en forme',
                  color: AppColors.success,
                  onTap: () => setState(() => _format = FormatExport.excel),
                ),
                const SizedBox(width: 10),
                _FormatCard(
                  format: FormatExport.csv,
                  selected: _format == FormatExport.csv,
                  icon: Icons.data_object_rounded,
                  label: 'CSV',
                  description: 'Données brutes\ncompatibles tout logiciel',
                  color: AppColors.info,
                  onTap: () => setState(() => _format = FormatExport.csv),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Filtres ───────────────────────────────────────────────────
            const _SectionLabel(label: 'Filtres'),
            const SizedBox(height: 10),

            // Criticité
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('Criticité',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: ['TOUS', 'ELEVE', 'MOYEN', 'FAIBLE'].map((c) {
                      final color = c == 'ELEVE'
                          ? AppColors.danger
                          : c == 'MOYEN'
                              ? AppColors.warning
                              : c == 'FAIBLE'
                                  ? AppColors.info
                                  : AppColors.blueImf;
                      final actif = _criticite == c;
                      final label = c == 'TOUS'
                          ? 'Toutes'
                          : c == 'ELEVE'
                              ? 'Élevée'
                              : c == 'MOYEN'
                                  ? 'Moyenne'
                                  : 'Faible';
                      return GestureDetector(
                        onTap: () => setState(() => _criticite = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: actif
                                ? color.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: actif ? color : AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: actif ? color : AppColors.textSecondary,
                                fontWeight:
                                    actif ? FontWeight.w500 : FontWeight.w400),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Période
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('Période',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _choisirPeriode,
                        icon:
                            const Icon(Icons.calendar_today_outlined, size: 13),
                        label: Text(
                          _periode == null
                              ? 'Toute la période'
                              : '${DateFormat('dd/MM/yy').format(_periode!.start)} → ${DateFormat('dd/MM/yy').format(_periode!.end)}',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _periode != null
                              ? AppColors.blueImf
                              : AppColors.textSecondary,
                          side: BorderSide(
                            color: _periode != null
                                ? AppColors.blueImf
                                : AppColors.border,
                            width: 0.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      if (_periode != null) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 15, color: AppColors.textSecondary),
                          onPressed: () => setState(() => _periode = null),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recherche
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('Recherche',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _rechercheCtrl,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.inter(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Règle, client, type...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 15, color: AppColors.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.border, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.border, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.blueImf, width: 1),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Dossier destination ───────────────────────────────────────
            const _SectionLabel(label: 'Dossier de destination'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_outlined,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dossierDestination ??
                                'Par défaut : ~/Téléchargements',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: _dossierDestination != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _choisirDossier,
                  icon: const Icon(Icons.folder_open_outlined, size: 14),
                  label: const Text('Parcourir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blueImf,
                    side:
                        const BorderSide(color: AppColors.blueImf, width: 0.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    textStyle: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 16),

            // Résumé + bouton export
            Row(
              children: [
                // Résumé
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.blueImf.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.blueImf.withValues(alpha: 0.2),
                        width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 13, color: AppColors.blueImf),
                      const SizedBox(width: 6),
                      Text(
                        '$_nbAlertesFiltrees alerte(s) seront exportées',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.blueImf),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler',
                      style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _enCours ? null : _exporter,
                  icon: _enCours
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 16),
                  label: Text(_enCours ? 'Export...' : 'Exporter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    textStyle: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Composants ───────────────────────────────────────────────────────────────

class _FormatCard extends StatelessWidget {
  final FormatExport format;
  final bool selected;
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _FormatCard({
    required this.format,
    required this.selected,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon,
                      size: 18,
                      color: selected ? color : AppColors.textSecondary),
                  const Spacer(),
                  if (selected)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 10, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : AppColors.textPrimary)),
              const SizedBox(height: 3),
              Text(description,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1.0)),
        const SizedBox(width: 10),
        const Expanded(
            child: Divider(
                color: AppColors.borderLight, height: 1, thickness: 0.5)),
      ],
    );
  }
}
