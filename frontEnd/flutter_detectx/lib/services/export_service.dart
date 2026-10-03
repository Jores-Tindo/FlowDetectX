import 'dart:io';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:file_selector/file_selector.dart';

enum FormatExport { pdf, csv, excel }

// Helper pour parser DateTime du backend
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return null;
}

class FiltreExport {
  final DateTimeRange? periode;
  final String criticite; // TOUS | CRITIQUE | ELEVEE | MOYENNE
  final String recherche;

  const FiltreExport({
    this.periode,
    this.criticite = 'TOUS',
    this.recherche = '',
  });
}

/// Résultat renvoyé par l'isolate : soit un chemin de succès, soit une
/// erreur explicite (au lieu d'un simple null qui masque la vraie cause).
class ResultatExport {
  final String? chemin;
  final String? erreur;
  const ResultatExport.succes(this.chemin) : erreur = null;
  const ResultatExport.echec(this.erreur) : chemin = null;
}

/// Regroupe tous les arguments nécessaires à la génération du fichier,
/// pour pouvoir les envoyer en un seul bloc à compute() (isolate séparé).
class _ArgsGeneration {
  final List<Map<String, dynamic>> donnees;
  final String chemin;
  final FormatExport format;
  final String criticite;
  final DateTimeRange? periode;
  final String recherche;

  _ArgsGeneration({
    required this.donnees,
    required this.chemin,
    required this.format,
    required this.criticite,
    required this.periode,
    required this.recherche,
  });
}

class ExportService {
  /// Filtre les alertes selon les critères
  static List<Map<String, dynamic>> filtrerAlertes(
    List<Map<String, dynamic>> alertes,
    FiltreExport filtre,
  ) {
    return alertes.where((a) {
      // Filtre criticité
      final matchCriticite =
          filtre.criticite == 'TOUS' || a['criticite'] == filtre.criticite;

      // Filtre période
      final horodatage = _parseDateTime(a['horodatage']);
      final matchPeriode = filtre.periode == null ||
          (horodatage != null &&
              horodatage.isAfter(filtre.periode!.start) &&
              horodatage
                  .isBefore(filtre.periode!.end.add(const Duration(days: 1))));

      // Filtre recherche
      final q = filtre.recherche.toLowerCase();
      final matchRecherche = q.isEmpty ||
          (a['regleNom']?.toString().toLowerCase().contains(q) ?? false) ||
          (a['nomClient']?.toString().toLowerCase().contains(q) ?? false) ||
          (a['type']?.toString().toLowerCase().contains(q) ?? false);

      return matchCriticite && matchPeriode && matchRecherche;
    }).toList();
  }

  /// Choisir le dossier de destination selon l'OS
  static Future<String?> choisirDossier() async {
    try {
      final String? dossier = await getDirectoryPath(
        initialDirectory: (await getDownloadsDirectory())?.path,
        confirmButtonText: 'Choisir le dossier',
      );
      if (dossier != null && dossier.isNotEmpty) {
        final normalized = p.normalize(dossier);
        if (await _validerDossier(normalized)) return normalized;
      }
    } catch (e) {
      debugPrint('Erreur file_selector directory picker: $e');
    }

    // Fallback vers le dossier Téléchargements ou Documents
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final fallback = dir.path;
    return (await _validerDossier(fallback)) ? p.normalize(fallback) : null;
  }

  static Future<bool> _validerDossier(String chemin) async {
    try {
      final dossier = Directory(chemin);
      if (await dossier.exists()) return true;
      await dossier.create(recursive: true);
      return await dossier.exists();
    } catch (e) {
      debugPrint('Dossier invalide ou impossible à créer: $e');
      return false;
    }
  }

  /// Générer le nom du fichier
  static String _nomFichier(FormatExport format) {
    final now = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    switch (format) {
      case FormatExport.pdf:
        return 'alertes_$now.pdf';
      case FormatExport.csv:
        return 'alertes_$now.csv';
      case FormatExport.excel:
        return 'alertes_$now.xlsx';
    }
  }

  /// Export principal.
  /// Le filtrage (léger) reste sur le thread principal, mais la génération
  /// du fichier (potentiellement lourde avec un grand volume d'alertes,
  /// surtout en PDF) est déléguée à un isolate séparé via compute(), pour
  /// ne JAMAIS geler l'interface pendant l'export — plus de risque de
  /// "l'application ne répond pas" côté OS.
  static Future<ResultatExport> exporter({
    required List<Map<String, dynamic>> alertes,
    required FiltreExport filtre,
    required FormatExport format,
    String? dossierDestination,
  }) async {
    final donnees = filtrerAlertes(alertes, filtre);
    if (donnees.isEmpty) {
      return const ResultatExport.echec(
          'Aucune alerte ne correspond aux filtres sélectionnés.');
    }

    final dossierBrut = dossierDestination ?? await choisirDossier();
    if (dossierBrut == null) {
      return const ResultatExport.echec(
          'Aucun dossier de destination sélectionné.');
    }

    final dossier = p.normalize(dossierBrut);
    if (!await _validerDossier(dossier)) {
      return ResultatExport.echec(
          'Le dossier "$dossier" est invalide ou non accessible en écriture.');
    }

    final chemin = p.join(dossier, _nomFichier(format));

    try {
      final args = _ArgsGeneration(
        donnees: donnees,
        chemin: chemin,
        format: format,
        criticite: filtre.criticite,
        periode: filtre.periode,
        recherche: filtre.recherche,
      );
      // Exécuté dans un isolate séparé : aucune UI ne peut geler ici,
      // quel que soit le nombre d'alertes.
      final resultat = await compute(_genererFichierIsolate, args);
      return resultat;
    } catch (e) {
      // Erreur réelle et explicite, plus jamais un message générique
      // qui pointe à tort vers le dossier de destination.
      debugPrint('Erreur export ($format): $e');
      return ResultatExport.echec('Échec de la génération du fichier : $e');
    }
  }

  /// Ouvrir le fichier exporté
  static Future<void> ouvrirFichier(String chemin) async {
    await OpenFilex.open(chemin);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Fonction TOP-LEVEL (obligatoire pour compute()) : tout le travail lourd
// de génération de fichier s'exécute ici, dans l'isolate séparé.
// ─────────────────────────────────────────────────────────────────────────

Future<ResultatExport> _genererFichierIsolate(_ArgsGeneration args) async {
  try {
    switch (args.format) {
      case FormatExport.csv:
        return await _exportCSV(args.donnees, args.chemin);
      case FormatExport.excel:
        return await _exportExcel(args.donnees, args.chemin);
      case FormatExport.pdf:
        return await _exportPDF(
          args.donnees,
          args.chemin,
          FiltreExport(
            criticite: args.criticite,
            periode: args.periode,
            recherche: args.recherche,
          ),
        );
    }
  } catch (e) {
    return ResultatExport.echec('Erreur pendant la génération : $e');
  }
}

// ─── Export CSV ─────────────────────────────────────────────────────────────

Future<ResultatExport> _exportCSV(
  List<Map<String, dynamic>> alertes,
  String chemin,
) async {
  try {
    final rows = <List<dynamic>>[];

    rows.add([
      'ID',
      'Règle déclenchée',
      'Client',
      'Montant (FCFA)',
      'Type',
      'Criticité',
      'Horodatage',
    ]);

    for (final a in alertes) {
      rows.add([
        a['id']?.toString() ?? '-',
        a['regleNom'] ?? '-',
        a['nomClient'] ?? '-',
        a['montant']?.toString() ?? '0',
        a['type'] ?? '-',
        a['criticite'] ?? '-',
        a['horodatage'] != null
            ? DateFormat('dd/MM/yyyy HH:mm:ss')
                .format(_parseDateTime(a['horodatage']) ?? DateTime.now())
            : '-',
      ]);
    }

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      eol: '\n',
    ).convert(rows);

    final bytes = [0xEF, 0xBB, 0xBF, ...csv.codeUnits];
    await File(chemin).writeAsBytes(bytes);
    return ResultatExport.succes(chemin);
  } catch (e) {
    return ResultatExport.echec('Erreur export CSV : $e');
  }
}

// ─── Export Excel ───────────────────────────────────────────────────────────

Future<ResultatExport> _exportExcel(
  List<Map<String, dynamic>> alertes,
  String chemin,
) async {
  try {
    final excel = Excel.createExcel();
    final sheet = excel['Alertes FlowDetectX'];

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#0A1628'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    final entetes = [
      'ID',
      'Règle déclenchée',
      'Client',
      'Montant (FCFA)',
      'Type',
      'Criticité',
      'Horodatage',
    ];

    for (var i = 0; i < entetes.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(entetes[i]);
      cell.cellStyle = headerStyle;
    }

    for (var rowIdx = 0; rowIdx < alertes.length; rowIdx++) {
      final a = alertes[rowIdx];
      final row = rowIdx + 1;

      final couleurCriticite = a['criticite'] == 'CRITIQUE'
          ? '#FCEBEB'
          : a['criticite'] == 'ELEVEE'
              ? '#FAEEDA'
              : '#E6F1FB';

      final rowStyle = CellStyle(
        backgroundColorHex:
            ExcelColor.fromHexString(rowIdx.isEven ? '#F8FAFC' : '#FFFFFF'),
      );

      final criStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(couleurCriticite),
        bold: true,
      );

      void setCell(int col, CellValue val, [CellStyle? style]) {
        final cell = sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = val;
        cell.cellStyle = style ?? rowStyle;
      }

      setCell(0, TextCellValue(a['id']?.toString() ?? '-'));
      setCell(1, TextCellValue(a['regleNom'] ?? '-'));
      setCell(2, TextCellValue(a['nomClient'] ?? '-'));
      setCell(3, IntCellValue(a['montant'] ?? 0));
      setCell(4, TextCellValue(a['type'] ?? '-'));
      setCell(5, TextCellValue(a['criticite'] ?? '-'), criStyle);
      setCell(
        6,
        TextCellValue(
          a['horodatage'] != null
              ? DateFormat('dd/MM/yyyy HH:mm:ss')
                  .format(_parseDateTime(a['horodatage']) ?? DateTime.now())
              : '-',
        ),
      );
    }

    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 35);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 12);
    sheet.setColumnWidth(6, 22);

    excel.delete('Sheet1');

    final bytes = excel.save();
    if (bytes == null) {
      return const ResultatExport.echec(
          'La génération Excel a renvoyé un résultat vide.');
    }
    await File(chemin).writeAsBytes(bytes);
    return ResultatExport.succes(chemin);
  } catch (e) {
    return ResultatExport.echec('Erreur export Excel : $e');
  }
}

// ─── Export PDF ──────────────────────────────────────────────────────────────

/// Nombre maximal de lignes traitées en un seul document PDF. Au-delà,
/// le package pdf devient extrêmement lent/gourmand en mémoire (des
/// dizaines de milliers de widgets de texte mis en page en une fois),
/// ce qui a provoqué les blocages observés avec 22758 alertes. Passé ce
/// seuil, on tronque le PDF (rapport pensé pour être lisible/imprimable,
/// pas pour un export massif de données brutes) et on le signale dans le
/// document lui-même — pour un export complet de gros volumes, le CSV ou
/// l'Excel restent les formats adaptés.
const int _maxLignesPDF = 3000;

Future<ResultatExport> _exportPDF(
  List<Map<String, dynamic>> alertesInitiales,
  String chemin,
  FiltreExport filtre,
) async {
  try {
    final tronque = alertesInitiales.length > _maxLignesPDF;
    final alertes =
        tronque ? alertesInitiales.sublist(0, _maxLignesPDF) : alertesInitiales;

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final now = DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now());

    const navy = PdfColor.fromInt(0xFF0A1628);
    const gris = PdfColor.fromInt(0xFF64748B);
    const bordure = PdfColor.fromInt(0xFFE2E8F0);
    const surface = PdfColor.fromInt(0xFFF8FAFC);
    const dangerBg = PdfColor.fromInt(0xFFFCEBEB);
    const dangerTxt = PdfColor.fromInt(0xFFA32D2D);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        maxPages: 200,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FlowDetectX',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: navy)),
                    pw.Text('Rapport d\'alertes de détection',
                        style: const pw.TextStyle(fontSize: 11, color: gris)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Généré le $now',
                        style: const pw.TextStyle(fontSize: 9, color: gris)),
                    pw.Text('${alertesInitiales.length} alerte(s)',
                        style: pw.TextStyle(
                            fontSize: 9,
                            color: gris,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            if (tronque)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: dangerBg,
                  border: pw.Border.all(color: dangerTxt, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Ce PDF affiche les $_maxLignesPDF premières alertes sur '
                  '${alertesInitiales.length} au total. Pour l\'export complet, '
                  'utilisez le format Excel ou CSV.',
                  style: pw.TextStyle(
                      fontSize: 8,
                      color: dangerTxt,
                      fontWeight: pw.FontWeight.bold),
                ),
              ),
            if (filtre.criticite != 'TOUS' ||
                filtre.periode != null ||
                filtre.recherche.isNotEmpty)
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: surface,
                  border: pw.Border.all(color: bordure),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('Filtres : ',
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: gris)),
                    if (filtre.criticite != 'TOUS')
                      pw.Text('Criticité: ${filtre.criticite}  ',
                          style: const pw.TextStyle(fontSize: 8, color: gris)),
                    if (filtre.periode != null)
                      pw.Text(
                        'Période: ${DateFormat('dd/MM/yyyy').format(filtre.periode!.start)} → ${DateFormat('dd/MM/yyyy').format(filtre.periode!.end)}  ',
                        style: const pw.TextStyle(fontSize: 8, color: gris),
                      ),
                    if (filtre.recherche.isNotEmpty)
                      pw.Text('Recherche: "${filtre.recherche}"',
                          style: const pw.TextStyle(fontSize: 8, color: gris)),
                  ],
                ),
              ),
            pw.SizedBox(height: 8),
            pw.Divider(color: bordure),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('FlowDetectX — Confidentiel',
                style: const pw.TextStyle(fontSize: 8, color: gris)),
            pw.Text('Page ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: gris)),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'Règle déclenchée',
              'Client',
              'Montant (FCFA)',
              'Type',
              'Criticité',
              'Horodatage',
            ],
            data: alertes.map((a) {
              return [
                a['regleNom'] ?? '-',
                a['nomClient'] ?? '-',
                NumberFormat('#,###', 'fr_FR').format(a['montant'] ?? 0),
                a['type'] ?? '-',
                a['criticite'] ?? '-',
                a['horodatage'] != null
                    ? dateFormat.format(
                        _parseDateTime(a['horodatage']) ?? DateTime.now())
                    : '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(color: navy),
            rowDecoration: const pw.BoxDecoration(),
            oddRowDecoration: const pw.BoxDecoration(color: surface),
            cellStyle: const pw.TextStyle(fontSize: 8, color: navy),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(2),
            },
            cellDecoration: (index, data, rowNum) {
              if (index == 4) {
                final val = data.toString();
                final cellColor = val == 'CRITIQUE'
                    ? const PdfColor.fromInt(0x26FF4757)
                    : val == 'ELEVEE'
                        ? const PdfColor.fromInt(0x26F0A500)
                        : const PdfColor.fromInt(0x26378ADD);
                return pw.BoxDecoration(
                  color: cellColor,
                  border: pw.Border.all(color: bordure, width: 0.5),
                );
              }
              return pw.BoxDecoration(
                border: pw.Border.all(color: bordure, width: 0.5),
              );
            },
          ),
        ],
      ),
    );

    await File(chemin).writeAsBytes(await pdf.save());
    return ResultatExport.succes(chemin);
  } catch (e) {
    return ResultatExport.echec('Erreur export PDF : $e');
  }
}
