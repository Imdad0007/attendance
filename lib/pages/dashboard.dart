import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:attendance/composants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:attendance/composants/notification_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:attendance/services/web_download_service.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Données KPI
  int _totalSeances = 0;
  int _seancesFaites = 0;
  int _seancesRestantes = 0;
  int _totalAbsences = 0;
  int _surveillantsActifs = 0;

  // Listes Dynamiques
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _performanceSurveillants = [];
  List<Map<String, dynamic>> _absencesParClasse = [];

  // Métadonnées pour les rapports
  List<Map<String, dynamic>> _allLevels = [];

  @override
  void initState() {
    super.initState();
    _refreshAll();
    _setupRealtime();
  }

  void _setupRealtime() {
    _supabase
        .channel('dashboard_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'presence',
          callback: (payload) {
            debugPrint("Changement détecté sur Presence");
            _refreshAll();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'seance',
          callback: (payload) {
            debugPrint("Changement détecté sur Seance");
            _refreshAll();
          },
        )
        .subscribe();
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchKPIs(),
      _fetchAcademicStats(),
      _fetchMetadata(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchMetadata() async {
    try {
      final levels = await _supabase
          .from('niveau')
          .select('id_niveau, libelle');
      if (mounted) {
        setState(() {
          _allLevels = (levels as List)
              .map((l) => {'id': l['id_niveau'], 'label': l['libelle']})
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error Metadata: $e");
    }
  }

  Future<void> _fetchKPIs() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Séances du jour
      final seances = await _supabase
          .from('seance')
          .select('id_seance')
          .eq('date_seance', today);
      _totalSeances = (seances as List).length;

      if (_totalSeances > 0) {
        final ids = (seances as List).map((e) => e['id_seance']).toList();
        // Présences du jour
        final presences = await _supabase
            .from('presence')
            .select('id_seance, id_surveillant, date_presence')
            .filter('id_seance', 'in', ids);

        _seancesFaites = (presences as List).length;
        _surveillantsActifs = (presences as List)
            .map((e) => e['id_surveillant'])
            .toSet()
            .length;
      } else {
        _seancesFaites = 0;
        _surveillantsActifs = 0;
      }

      _seancesRestantes = _totalSeances - _seancesFaites;

      // Total absences du jour
      final absencesResponse = await _supabase
          .from('details_presence')
          .select('matricule, presence!inner(seance!inner(date_seance))')
          .eq('statut', 'absent')
          .eq('presence.seance.date_seance', today);
      _totalAbsences = (absencesResponse as List).length;

      _alerts = [];
      if (_seancesRestantes > 0) {
        _alerts.add({
          'title': "$_seancesRestantes séances en attente",
          'level': 'warning',
        });
      }
    } catch (e) {
      debugPrint("Error KPIs: $e");
    }
  }


  double _maxAbsences = 20; // Valeur par défaut pour l'échelle

  Future<void> _fetchAcademicStats() async {
    try {
      final response = await _supabase
          .from('details_presence')
          .select('etudiant(classe(filiere(nom_filiere), niveau(libelle)))')
          .eq('statut', 'absent');

      final List data = response as List;

      data.sort((a, b) {
        final etuA = a['etudiant'];
        final etuB = b['etudiant'];

        final classeA = etuA['classe'];
        final classeB = etuB['classe'];

        final filiereA = classeA['filiere']?['nom_filiere'] ?? '';
        final filiereB = classeB['filiere']?['nom_filiere'] ?? '';

        final niveauA = classeA['niveau']?['libelle'] ?? '';
        final niveauB = classeB['niveau']?['libelle'] ?? '';

        final compareFiliere = filiereA.compareTo(filiereB);
        if (compareFiliere != 0) return compareFiliere;

        return niveauA.compareTo(niveauB);
      });

      final Map<String, int> counts = {};

      for (var item in data) {
        try {
          dynamic etu = item['etudiant'];
          if (etu is List && etu.isNotEmpty) etu = etu[0];
          if (etu == null) continue;

          final classe = etu['classe'];
          if (classe == null) continue;

          final filiere = classe['filiere']?['nom_filiere'] ?? 'Inconnue';
          final niveau = classe['niveau']?['libelle'] ?? '';
          final String label = "$filiere - $niveau";
          counts[label] = (counts[label] ?? 0) + 1;
        } catch (e) {
          continue;
        }
      }

      final List<Color> barColors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.indigo,
        Colors.amber,
      ];

      if (mounted) {
        setState(() {
          _absencesParClasse = counts.entries.indexed.map((entry) {
            int idx = entry.$1;
            var e = entry.$2;
            return {
              'label': e.key,
              'value': e.value,
              'color': barColors[idx % barColors.length],
            };
          }).toList();

          if (_absencesParClasse.isNotEmpty) {
            final currentMax = _absencesParClasse
                .map((e) => e['value'] as int)
                .reduce((a, b) => a > b ? a : b);
            _maxAbsences = (currentMax * 1.3).ceilToDouble();
            if (_maxAbsences < 5) _maxAbsences = 5;
          }
        });
      }
    } catch (e) {
      debugPrint("Error Stats: $e");
    }
  }

  // ================= EXPORT LOGIC  =================

  Future<void> _generateLevelReport(int levelId, String levelLabel) async {
    try {
      AppNotification.info("Préparation du bilan pour $levelLabel...");
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1).toIso8601String();

      final fontData = await rootBundle.load(
        "assets/fonts/JetBrainsMono-Regular.ttf",
      );
      final ttf = pw.Font.ttf(fontData);
      final fontDataBold = await rootBundle.load(
        "assets/fonts/JetBrainsMono-Bold.ttf",
      );
      final ttfBold = pw.Font.ttf(fontDataBold);

      // 1. Récupérer toutes les classes de ce niveau
      final response = await _supabase
          .from('classe')
          .select('id_classe, filiere(nom_filiere)')
          .eq('id_niveau', levelId);

      final classes = response as List;

      if (classes.isEmpty) {
        AppNotification.warning("Aucune classe trouvée pour ce niveau.");
        return;
      }

      await _finalizeLevelReportWithData(
        levelId,
        levelLabel,
        firstDay,
        classes,
        ttf,
        ttfBold,
      );
    } catch (e, stack) {
      debugPrint("PDF Error: $e\n$stack");
      AppNotification.error("Erreur de génération du rapport");
    }
  }

  Future<void> _finalizeLevelReportWithData(
    int levelId,
    String levelLabel,
    String firstDay,
    List<dynamic> classes,
    pw.Font ttf,
    pw.Font ttfBold,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    List<pw.Widget> allWidgets = [];

    for (var cl in classes) {
      final classId = cl['id_classe'];

      // Gestion sécurisée de la filière
      dynamic filiereData = cl['filiere'];
      if (filiereData is List && filiereData.isNotEmpty) {
        filiereData = filiereData[0];
      }
      final String classLabel =
          filiereData?['nom_filiere'] ?? 'Classe Inconnue';

      final response = await _supabase
          .from('details_presence')
          .select('''
          matricule,
          etudiant!inner(nom, prenom),
          presence!inner(date_presence, seance!inner(ecue!inner(intitule_ecue)))
        ''')
          .eq('statut', 'absent')
          .eq('etudiant.id_classe', classId)
          .gte('presence.date_presence', firstDay)
          .order('matricule', ascending: true);

      final List data = response as List;
      if (data.isEmpty) continue;

      Map<String, Map<String, dynamic>> studentGroups = {};

      for (var item in data) {
        try {
          // Extraction sécurisée de l'étudiant
          dynamic etu = item['etudiant'];
          if (etu is List && etu.isNotEmpty) etu = etu[0];
          if (etu == null) continue;

          // Extraction sécurisée de la présence/séance
          dynamic pres = item['presence'];
          if (pres is List && pres.isNotEmpty) pres = pres[0];
          if (pres == null) continue;

          dynamic sea = pres['seance'];
          if (sea is List && sea.isNotEmpty) sea = sea[0];
          if (sea == null) continue;

          dynamic ecu = sea['ecue'];
          if (ecu is List && ecu.isNotEmpty) ecu = ecu[0];
          if (ecu == null) continue;

          String mat = item['matricule'] ?? 'N/A';
          String name = "${etu['nom'] ?? ''} ${etu['prenom'] ?? ''}".trim();
          if (name.isEmpty) name = "Étudiant Inconnu";

          String cours = ecu['intitule_ecue'] ?? 'Cours Inconnu';
          String dateRaw = pres['date_presence'];
          String date = DateFormat('dd/MM').format(DateTime.parse(dateRaw));

          if (!studentGroups.containsKey(mat)) {
            studentGroups[mat] = {
              'name': name,
              'absences': <String, List<String>>{},
              'total': 0,
            };
          }

          if (!studentGroups[mat]!['absences'].containsKey(cours)) {
            studentGroups[mat]!['absences'][cours] = <String>[];
          }

          studentGroups[mat]!['absences'][cours].add(date);
          studentGroups[mat]!['total']++;
        } catch (e) {
          debugPrint("Error processing row: $e");
          continue;
        }
      }

      allWidgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 25, bottom: 10),
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.blue900, width: 3),
              ),
            ),
            child: pw.Text(
              "CLASSE : ${classLabel.toString().toUpperCase()}",
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
          ),
        ),
      );

      List<pw.TableRow> tableRows = [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                "ÉTUDIANT",
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                "COURS",
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                "DATES",
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                "NB",
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                "TOTAL",
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ];

      studentGroups.forEach((mat, info) {
        final absencesMap = info['absences'] as Map<String, List<String>>;
        final List<String> courses = absencesMap.keys.toList();

        for (int i = 0; i < courses.length; i++) {
          final String cours = courses[i];
          final List<String> dates = absencesMap[cours]!;

          tableRows.add(
            pw.TableRow(
              children: [
                // Colonne Étudiant (seulement sur la première ligne de l'étudiant)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: i == 0
                      ? pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              info['name'],
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              mat,
                              style: const pw.TextStyle(
                                fontSize: 6,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        )
                      : pw.SizedBox(),
                ),
                // Colonne Cours
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(cours, style: const pw.TextStyle(fontSize: 7)),
                ),
                // Colonne Dates
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    dates.join(', '),
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
                // Colonne NB par cours
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    dates.length.toString(),
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // Colonne Total (seulement sur la première ligne de l'étudiant)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: i == 0
                      ? pw.Text(
                          info['total'].toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        )
                      : pw.SizedBox(),
                ),
              ],
            ),
          );
        }
        // Ligne de séparation subtile entre les étudiants
        tableRows.add(
          pw.TableRow(
            children: List.generate(
              5,
              (_) => pw.Container(height: 0.5, color: PdfColors.grey300),
            ),
          ),
        );
      });

      allWidgets.add(
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5), // Étudiant
            1: const pw.FlexColumnWidth(3), // Cours
            2: const pw.FlexColumnWidth(3), // Dates
            3: const pw.FlexColumnWidth(0.6), // NB
            4: const pw.FlexColumnWidth(0.8), // Total
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: tableRows,
        ),
      );
    }

    if (allWidgets.isEmpty) {
      AppNotification.info(
        "Aucune absence enregistrée pour ce niveau ce mois-ci.",
      );
      return;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "PIGIER BÉNIN",
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      "L'ÉCOLE DES MANAGERS",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Surveillance Générale",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "BILAN MENSUEL D'ABSENCE",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.Text(
                      "NIVEAU : $levelLabel",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Période : ${DateFormat('MMMM yyyy', 'fr_FR').format(now).toUpperCase()}",
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      "Généré le : ${DateFormat('dd/MM/yyyy HH:mm').format(now)}",
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5, color: PdfColors.blue900),
            pw.SizedBox(height: 15),
          ],
        ),
        build: (context) => allWidgets,
        footer: (context) => pw.Column(
          children: [
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "PIGIER BÉNIN - Rapport d'Assiduité",
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  "Page ${context.pageNumber} sur ${context.pagesCount}",
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await _finalizePdf(
      pdf,
      "bilan_absence_${levelLabel.toLowerCase().replaceAll(' ', '_')}",
    );
  }

  // ... (dans la classe _DashboardState)

  Future<void> _finalizePdf(pw.Document pdf, String baseName) async {
    final bytes = await pdf.save();
    final filename =
        '${baseName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    if (kIsWeb) {
      // Téléchargement direct pour le Web (Mobile & Desktop)
      WebDownloadService.downloadBytes(bytes, filename);
    } else {
      // Partage natif pour iOS/Android (application installée)
      await Printing.sharePdf(bytes: bytes, filename: filename);
    }
    AppNotification.success("Rapport généré avec succès !");
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),

        // backgroundColor : AppColors.bg,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "RAPPORTS MENSUEL PAR NIVEAU",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),

              if (_allLevels.isEmpty)
                const Text("Chargement des niveaux...")
              else
                ..._allLevels.map(
                  (l) => ListTile(
                    leading: const Icon(
                      Icons.analytics,
                      color: AppColors.primary,
                    ),
                    title: Text("Niveau ${l['label']}"),
                    subtitle: const Text(
                      "Tableau détaillé des absences du mois",
                      style: TextStyle(fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _generateLevelReport(l['id'], l['label']);
                    },
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportTile(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.download, size: 20),
      onTap: onTap,
    );
  }

  // ================= UI BUILDERS =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _refreshAll,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 25),
                    const Text(
                      "VUE D'ENSEMBLE DU JOUR",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildKPIGrid(),
                    const SizedBox(height: 24),
                    // Responsive layout for charts and side panel
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 900) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildLeftColumn()),
                              const SizedBox(width: 20),
                              Expanded(flex: 1, child: _buildRightColumn()),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildLeftColumn(),
                              const SizedBox(height: 20),
                              _buildRightColumn(),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (MediaQuery.of(context).size.width > 1000) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Expanded(child: _buildPerformanceAndAudit()),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              const SizedBox(height: 24),
                              _buildPerformanceAndAudit(),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 800;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: isWide ? 10 : 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Supervision",
                      style: TextStyle(
                        fontSize: isWide ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1D1E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: isWide ? 18 : 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            DateFormat(
                              "EEEE d MMMM yyyy",
                              "fr_FR",
                            ).format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: isWide ? 16 : 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              _buildHealthScore(isWide: isWide),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthScore({bool isWide = false}) {
    bool isGood = _seancesRestantes == 0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 16,
        vertical: isWide ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: (isGood ? Colors.green : Colors.orange).withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.check_circle_rounded : Icons.info_rounded,
            color: isGood ? Colors.green : Colors.orange,
            size: isWide ? 32 : 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "SANTÉ SYSTÈME",
                style: TextStyle(
                  fontSize: isWide ? 11 : 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[600],
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                isGood ? "TOUT EST OPTIMAL" : "ACTIONS REQUISES",
                style: TextStyle(
                  fontSize: isWide ? 14 : 12,
                  fontWeight: FontWeight.w900,
                  color: isGood ? Colors.green[700] : Colors.orange[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPIGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth > 1200) {
          crossAxisCount = 5;
          childAspectRatio = 2.2; // Plus d'espace vertical
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
          childAspectRatio = 1.8;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
          childAspectRatio = 1.5;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 1.1; // Presque carré pour mobile
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _kpiCard(
              "Séances Prévues",
              _totalSeances.toString(),
              Icons.calendar_today,
              Colors.blue,
            ),
            _kpiCard(
              "Séances Validées",
              _seancesFaites.toString(),
              Icons.verified_user,
              Colors.green,
            ),
            _kpiCard(
              "Séances En Attente",
              _seancesRestantes.toString(),
              Icons.hourglass_empty,
              Colors.orange,
            ),
            _kpiCard(
              "Absences",
              _totalAbsences.toString(),
              Icons.person_off,
              Colors.red,
            ),
            _kpiCard(
              "Surveillants Actifs",
              _surveillantsActifs.toString(),
              Icons.engineering,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 220;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 16 : 8,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isWide
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: color, size: 40),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              title.toUpperCase(),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            flex: 3,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                value,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      flex: 2,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLeftColumn() {
    return Column(children: [_buildAcademicStats()]);
  }

  final ScrollController _academicScrollController = ScrollController();

  @override
  void dispose() {
    _academicScrollController.dispose();
    super.dispose();
  }

  Widget _buildAcademicStats() {
    return _cardWrapper(
      title: "Analyse des Absences par Classe",
      child: Container(
        height: 400,
        padding: const EdgeInsets.only(top: 30),
        child: _absencesParClasse.isEmpty
            ? const Center(child: Text("Aucune donnée disponible"))
            : Scrollbar(
                controller: _academicScrollController,
                thumbVisibility:
                    true, // Toujours visible sur toutes les plateformes
                trackVisibility: false,
                thickness: 8,
                radius: const Radius.circular(10),
                child: SingleChildScrollView(
                  controller: _academicScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(
                    bottom: 15,
                  ), // Espace pour la barre
                  child: Container(
                    // Largeur dynamique : 100px par classe, minimum 600px
                    width: (_absencesParClasse.length * 100.0).clamp(
                      600.0,
                      double.infinity,
                    ),
                    padding: const EdgeInsets.only(
                      right: 20,
                      left: 10,
                      bottom: 10,
                    ),
                    child: BarChart(
                      BarChartData(
                        maxY: _maxAbsences,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: const EdgeInsets.all(4),
                            getTooltipColor: (group) => Colors.blueGrey[800]!,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                "${rod.toY.toInt()} absences",
                                const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index < 0 ||
                                    index >= _absencesParClasse.length) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Transform.rotate(
                                    angle: -0.5,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        _absencesParClasse[index]['label'],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withOpacity(0.1),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _absencesParClasse.asMap().entries.map((
                          entry,
                        ) {
                          final double val = (entry.value['value'] as int)
                              .toDouble();
                          return BarChartGroupData(
                            x: entry.key,
                            showingTooltipIndicators: [0],
                            barRods: [
                              BarChartRodData(
                                toY: val,
                                color: entry.value['color'],
                                width: 30, // Largeur des barres
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: _maxAbsences,
                                  color: Colors.grey.withOpacity(0.05),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        groupsSpace: 40, // Espace entre les groupes
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 1000),
                      swapAnimationCurve: Curves.elasticOut,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        _buildAlerts(),
        const SizedBox(height: 24),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildAlerts() {
    return _cardWrapper(
      title: "Alertes Critiques",
      child: Column(
        children: _alerts.isEmpty
            ? [
                const Text(
                  "Tout est sous contrôle",
                  style: TextStyle(color: Colors.green),
                ),
              ]
            : _alerts
                  .map(
                    (a) => Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            a['title'],
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  
  Future<List<Map<String, dynamic>>> fetchAuditLog() async {
    // Obtenir la date du jour au format YYYY-MM-DD
    final String today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _supabase
        .from('presence')
        .select('''
        id_presence,
        date_presence,
        surveillant:surveillant(id_surveillant, nom, prenom),
        seance:seance!inner(
          date_seance,
          ecue:ecue(
            intitule_ecue,
            ue:ue(
              classe:classe(
                filiere:filiere(nom_filiere),
                niveau:niveau(libelle)
              )
            )
          )
        )
      ''')
        .eq('seance.date_seance', today)
        .order('date_presence', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Widget _buildPerformanceAndAudit() {
    return _cardWrapper(
      title: "Journal d'Activité",
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAuditLog(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Aucune activité enregistrée"),
            );
          }

          final logs = snapshot.data!;

          return Column(
            children: logs.map((log) {
              final DateTime datePresence = DateTime.parse(
                log['date_presence'],
              ).toLocal();

              // Extraction sécurisée des relations
              dynamic survData = log['surveillant'];
              if (survData is List && survData.isNotEmpty)
                survData = survData[0];
              final surveillant = survData as Map<String, dynamic>?;

              dynamic seanceData = log['seance'];
              if (seanceData is List && seanceData.isNotEmpty) {
                seanceData = seanceData[0];
              }
              final seance = seanceData as Map<String, dynamic>?;

              if (surveillant == null || seance == null)
                return const SizedBox();

              dynamic ecueData = seance['ecue'];
              if (ecueData is List && ecueData.isNotEmpty) {
                ecueData = ecueData[0];
              }
              final ecue = ecueData as Map<String, dynamic>?;

              // Extraction de la classe
              String classLabel = "";
              try {
                final ue = ecue?['ue'];
                final classe = (ue is List && ue.isNotEmpty)
                    ? ue[0]['classe']
                    : ue?['classe'];
                final filiere = (classe is List && classe.isNotEmpty)
                    ? classe[0]['filiere']
                    : classe?['filiere'];
                final niveau = (classe is List && classe.isNotEmpty)
                    ? classe[0]['niveau']
                    : classe?['niveau'];

                final nomFiliere = (filiere is List && filiere.isNotEmpty)
                    ? filiere[0]['nom_filiere']
                    : filiere?['nom_filiere'];
                final libelleNiveau = (niveau is List && niveau.isNotEmpty)
                    ? niveau[0]['libelle']
                    : niveau?['libelle'];

                if (nomFiliere != null && libelleNiveau != null) {
                  classLabel = "$nomFiliere - $libelleNiveau";
                }
              } catch (e) {
                debugPrint("Error parsing class label: $e");
              }

              final DateTime dateSeance = DateTime.parse(
                seance['date_seance'] ?? DateTime.now().toIso8601String(),
              );

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_edu, color: Colors.grey),
                title: Text(
                  "Enregistrement de présence par ${surveillant['prenom'] ?? ''} ${surveillant['nom'] ?? ''}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "${ecue?['intitule_ecue'] ?? 'Cours inconnu'} ($classLabel) • Séance du ${DateFormat('dd/MM/yyyy').format(dateSeance)}",
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  DateFormat('HH:mm').format(datePresence),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return _cardWrapper(
      title: "Actions Rapides",
      child: Wrap(
        spacing: 15,
        runSpacing: 15,
        children: [
          _actionBtn(
            "Séance",
            Icons.add_circle,
            Colors.blue,
            () =>
                ref.read(navigationTabProvider.notifier).state = AppTab.seance,
          ),
          _actionBtn(
            "Historique",
            Icons.list_alt,
            Colors.orange,
            () => ref.read(navigationTabProvider.notifier).state =
                AppTab.historique,
          ),
          _actionBtn(
            "Utilisateurs",
            Icons.person_add,
            Colors.purple,
            () => ref.read(navigationTabProvider.notifier).state =
                AppTab.utilisateurs,
          ),
          _actionBtn(
            "Rapport PDF",
            Icons.picture_as_pdf,
            Colors.red,
            _showExportOptions,
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardWrapper({
    required String title,
    required Widget child,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1E),
                ),
              ),
              if (icon != null) Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const Divider(height: 40, thickness: 1),
          child,
        ],
      ),
    );
  }
}
