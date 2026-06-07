import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const apiKey = String.fromEnvironment(
  'ECOTRI_API_KEY',
  defaultValue: 'ecotri-demo-key',
);

Map<String, String> apiHeaders({bool json = false}) {
  return {
    'X-API-Key': apiKey,
    if (json) 'Content-Type': 'application/json',
  };
}

void main() {
  runApp(const EcoTriApp());
}

class EcoTriApp extends StatelessWidget {
  const EcoTriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoTri AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedPage = 0;
  String baseUrl = 'http://10.82.26.222:5000';
  bool apiOnline = false;
  bool checkingApi = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('base_url') ?? baseUrl;
    await checkApi();
  }

  Future<void> checkApi() async {
    setState(() => checkingApi = true);

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() => apiOnline = response.statusCode == 200);
    } catch (_) {
      if (!mounted) return;
      setState(() => apiOnline = false);
    } finally {
      if (mounted) setState(() => checkingApi = false);
    }
  }

  Future<void> saveApiUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', newUrl);

    setState(() => baseUrl = newUrl);
    await checkApi();
  }

  void openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SettingsSheet(
          initialUrl: baseUrl,
          onSave: (url) {
            Navigator.pop(context);
            saveApiUrl(url);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ScanPage(baseUrl: baseUrl, apiOnline: apiOnline),
      HistoryPage(baseUrl: baseUrl),
      StatsPage(baseUrl: baseUrl),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoTri AI'),
        actions: [
          IconButton(
            onPressed: checkApi,
            icon: checkingApi
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    apiOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: apiOnline ? Colors.green : Colors.orange,
                  ),
          ),
          IconButton(onPressed: openSettings, icon: const Icon(Icons.settings)),
        ],
      ),
      body: pages[selectedPage],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,
        onDestinationSelected: (index) {
          setState(() => selectedPage = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Scanner'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}

class ScanPage extends StatefulWidget {
  final String baseUrl;
  final bool apiOnline;

  const ScanPage({super.key, required this.baseUrl, required this.apiOnline});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final picker = ImagePicker();
  XFile? selectedImage;
  PredictionResult? result;
  bool loading = false;

  Future<void> pickAndSendImage(ImageSource source) async {
    final image = await picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    setState(() {
      selectedImage = image;
      result = null;
      loading = true;
    });

    try {
      final bytes = await image.readAsBytes();
      final response = await http
          .post(
            Uri.parse('${widget.baseUrl}/predict'),
            headers: apiHeaders(json: true),
            body: jsonEncode({'image': base64Encode(bytes)}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prediction = PredictionResult.fromJson(data);
        if (mounted) setState(() => result = prediction);
      } else {
        final message = data['error'] ?? 'Erreur serveur';
        showMessage(message.toString());
      }
    } catch (e) {
      showMessage('Erreur : $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: loading
                    ? null
                    : () => pickAndSendImage(ImageSource.camera),
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 82,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Appuyez pour capturer',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.apiOnline ? 'API connectee' : 'API hors ligne',
                style: TextStyle(
                  color: widget.apiOnline ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: loading
                    ? null
                    : () => pickAndSendImage(ImageSource.gallery),
                icon: const Icon(Icons.photo),
                label: const Text('Galerie'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (selectedImage != null) ImagePreview(file: selectedImage!),
        if (loading) const LoadingBox(),
        if (result != null) ResultCard(result: result!),
      ],
    );
  }
}

class HistoryPage extends StatefulWidget {
  final String baseUrl;

  const HistoryPage({super.key, required this.baseUrl});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<HistoryItem>> historyFuture;
  String selectedFilter = '';

  final List<String> categories = ['', 'biological', 'metal', 'paper', 'plastic'];

  @override
  void initState() {
    super.initState();
    historyFuture = loadHistory();
  }

  Future<List<HistoryItem>> loadHistory() async {
    final response = await http
        .get(
          Uri.parse('${widget.baseUrl}/historique'),
          headers: apiHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger l\'historique');
    }

    final List data = jsonDecode(response.body);
    return data.map((item) => HistoryItem.fromJson(item)).toList();
  }

  Future<void> refreshHistory() async {
    setState(() {
      historyFuture = loadHistory();
    });
    await historyFuture;
  }

  Future<void> deleteScan(HistoryItem item) async {
    try {
      final response = await http.delete(
        Uri.parse('${widget.baseUrl}/delete/${item.id}'),
        headers: apiHeaders(),
      );

      if (response.statusCode == 200) {
        showMessage('Scan supprime');
        refreshHistory();
      } else {
        showMessage('Suppression impossible');
      }
    } catch (e) {
      showMessage('Erreur : $e');
    }
  }

  void confirmDelete(HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer'),
          content: const Text('Voulez-vous supprimer ce scan ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                deleteScan(item);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<HistoryItem> _filterItems(List<HistoryItem> items) {
    if (selectedFilter.isEmpty) return items;
    return items.where((item) => item.classe == selectedFilter).toList();
  }

  Map<String, int> _getCategoryStats(List<HistoryItem> items) {
    final stats = <String, int>{};
    for (final item in items) {
      stats[item.classe] = (stats[item.classe] ?? 0) + 1;
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshHistory,
      child: FutureBuilder<List<HistoryItem>>(
        future: historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              children: const [
                SizedBox(height: 160),
                Center(child: Text('Impossible de charger l\'historique')),
              ],
            );
          }

          final items = snapshot.data ?? [];
          final filteredItems = _filterItems(items);
          final stats = _getCategoryStats(items);

          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 160),
                Center(child: Text('Aucun scan pour le moment')),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (stats.isNotEmpty) ...[
                Text(
                  'Répartition des déchets scannés',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sections: stats.entries.map((entry) {
                        final color = classColor(entry.key);
                        final label = classLabel(entry.key);
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: '${entry.value}',
                          color: color,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: stats.entries.map((entry) {
                    final color = classColor(entry.key);
                    final label = classLabel(entry.key);
                    return Chip(
                      label: Text('$label: ${entry.value}'),
                      backgroundColor: color.withOpacity(0.2),
                      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Filtrer par catégorie',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final isSelected = selectedFilter == category;
                  final label = category.isEmpty ? 'Tous' : classLabel(category);
                  final color = category.isEmpty ? Colors.grey : classColor(category);

                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => selectedFilter = category);
                    },
                    backgroundColor: color.withOpacity(0.1),
                    selectedColor: color.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (filteredItems.isEmpty)
                const Center(child: Text('Aucun scan dans cette catégorie'))
              else ...[
                Text(
                  '${filteredItems.length} scan${filteredItems.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ...filteredItems.map((item) {
                  return HistoryCard(
                    item: item,
                    onDelete: () => confirmDelete(item),
                  );
                }).toList(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class StatsPage extends StatefulWidget {
  final String baseUrl;

  const StatsPage({super.key, required this.baseUrl});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<List<StatItem>> statsFuture;

  @override
  void initState() {
    super.initState();
    statsFuture = loadStats();
  }

  Future<List<StatItem>> loadStats() async {
    final response = await http
        .get(
          Uri.parse('${widget.baseUrl}/stats'),
          headers: apiHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les statistiques');
    }

    final List data = jsonDecode(response.body);
    return data.map((item) => StatItem.fromJson(item)).toList();
  }

  Future<void> refreshStats() async {
    setState(() {
      statsFuture = loadStats();
    });
    await statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshStats,
      child: FutureBuilder<List<StatItem>>(
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              children: const [
                SizedBox(height: 160),
                Center(child: Text('Impossible de charger les statistiques')),
              ],
            );
          }

          final stats = snapshot.data ?? [];
          if (stats.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 160),
                Center(child: Text('Pas encore de statistiques')),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              return StatCard(item: stats[index]);
            },
          );
        },
      ),
    );
  }
}

class ApiStatusCard extends StatelessWidget {
  final bool apiOnline;

  const ApiStatusCard({super.key, required this.apiOnline});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              apiOnline ? Icons.check_circle : Icons.error,
              color: apiOnline ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                apiOnline
                    ? 'API connectee, vous pouvez scanner.'
                    : 'API hors ligne. Verifiez l\'adresse du serveur.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImagePreview extends StatelessWidget {
  final XFile file;

  const ImagePreview({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            snapshot.data!,
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Analyse en cours...'),
        ],
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final PredictionResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = classColor(result.classe);

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(classIcon(result.classe), color: color, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    classLabel(result.classe),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${result.confiance.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(result.conseil),
          ],
        ),
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onDelete;

  const HistoryCard({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = classColor(item.classe);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.imageUrl == null
              ? HistoryIcon(classe: item.classe, color: color)
              : Image.network(
                  item.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return HistoryIcon(classe: item.classe, color: color);
                  },
                ),
        ),
        title: Text(classLabel(item.classe)),
        subtitle: Text(item.dateScan),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.confiance.toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryIcon extends StatelessWidget {
  final String classe;
  final Color color;

  const HistoryIcon({super.key, required this.classe, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: color.withValues(alpha: 0.12),
      child: Icon(classIcon(classe), color: color),
    );
  }
}

class StatCard extends StatelessWidget {
  final StatItem item;

  const StatCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = classColor(item.classe);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(classIcon(item.classe), color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    classLabel(item.classe),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text('${item.total} scans'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: item.confianceMoyenne / 100,
              color: color,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              'Confiance moyenne : ${item.confianceMoyenne.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSheet extends StatefulWidget {
  final String initialUrl;
  final Function(String) onSave;

  const SettingsSheet({
    super.key,
    required this.initialUrl,
    required this.onSave,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Configuration API',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'URL du serveur Flask',
              hintText: 'http://192.168.1.10:5000',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSave(controller.text.trim());
              },
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}

class PredictionResult {
  final String classe;
  final double confiance;
  final String conseil;

  PredictionResult({
    required this.classe,
    required this.confiance,
    required this.conseil,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      classe: json['classe'] ?? 'inconnu',
      confiance: ((json['confiance'] ?? 0) as num).toDouble(),
      conseil: json['conseil'] ?? '',
    );
  }
}

class HistoryItem {
  final int id;
  final String classe;
  final double confiance;
  final String dateScan;
  final String? imageUrl;

  HistoryItem({
    required this.id,
    required this.classe,
    required this.confiance,
    required this.dateScan,
    required this.imageUrl,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? 0,
      classe: json['classe'] ?? 'inconnu',
      confiance: ((json['confiance'] ?? 0) as num).toDouble(),
      dateScan: json['date_scan'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}

class StatItem {
  final String classe;
  final int total;
  final double confianceMoyenne;

  StatItem({
    required this.classe,
    required this.total,
    required this.confianceMoyenne,
  });

  factory StatItem.fromJson(Map<String, dynamic> json) {
    return StatItem(
      classe: json['classe'] ?? 'inconnu',
      total: json['total'] ?? 0,
      confianceMoyenne: ((json['confiance_moyenne'] ?? 0) as num).toDouble(),
    );
  }
}

String classLabel(String classe) {
  switch (classe) {
    case 'biological':
      return 'Organique';
    case 'metal':
      return 'Metal';
    case 'paper':
      return 'Papier';
    case 'plastic':
      return 'Plastique';
    default:
      return classe;
  }
}

IconData classIcon(String classe) {
  switch (classe) {
    case 'biological':
      return Icons.eco;
    case 'metal':
      return Icons.precision_manufacturing;
    case 'paper':
      return Icons.description;
    case 'plastic':
      return Icons.local_drink;
    default:
      return Icons.recycling;
  }
}

Color classColor(String classe) {
  switch (classe) {
    case 'biological':
      return Colors.green;
    case 'metal':
      return Colors.blueGrey;
    case 'paper':
      return Colors.orange;
    case 'plastic':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}
