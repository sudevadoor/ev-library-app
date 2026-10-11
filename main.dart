import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/add_book_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadSettings();
  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  static const Color seed = Color(0xFF6C8EF5); // soft periwinkle blue

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF5B7FE8),
      primaryContainer: const Color(0xFFE3EBFF),
      secondaryContainer: const Color(0xFFFFE9D6),
      surface: Colors.white,
    );

    return MaterialApp(
      title: 'E.V. LIBRARY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          foregroundColor: Color(0xFF2F3E6B),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF2F3E6B),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE6ECFA)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      builder: (context, child) =>
          _PatternBackground(child: child ?? const SizedBox.shrink()),
      home: const HomeScreen(),
    );
  }
}

/// Light gradient with a faint dotted pattern and soft circles.
class _PatternBackground extends StatelessWidget {
  final Widget child;
  const _PatternBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3F6FF), // pale blue
            Color(0xFFFFF6EE), // pale peach
            Color(0xFFF1FBF6), // pale mint
          ],
        ),
      ),
      child: CustomPaint(
        painter: _PatternPainter(),
        child: child,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // faint dot grid
    final dot = Paint()..color = const Color(0xFF5B7FE8).withValues(alpha: 0.07);
    const gap = 28.0;
    for (double y = 14; y < size.height; y += gap) {
      for (double x = ((y / gap).floor().isEven ? 14 : 28); x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.6, dot);
      }
    }

    // soft decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.08),
      90,
      Paint()..color = const Color(0xFFFFC9A8).withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.62),
      110,
      Paint()..color = const Color(0xFFB8E6D0).withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.95),
      120,
      Paint()..color = const Color(0xFFC9D6FF).withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E.V. LIBRARY'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: [
            _HomeTile(
              icon: Icons.add_box,
              title: 'Add Book',
              tint: const Color(0xFFE3EBFF),
              iconColor: const Color(0xFF4A6BD6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddBookScreen(),
                  ),
                );
              },
            ),
            _HomeTile(
              icon: Icons.search,
              title: 'Search Books',
              tint: const Color(0xFFFFE9D6),
              iconColor: const Color(0xFFE08A4B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchBooksScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color tint;
  final Color iconColor;

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.tint = const Color(0xFFE3EBFF),
    this.iconColor = const Color(0xFF4A6BD6),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, size: 38, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F3E6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final controller = TextEditingController();
  final sheetController = TextEditingController();
  bool saving = false;
  bool testing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    controller.text = ApiService.baseUrl;
    sheetController.text = prefs.getString('google_sheet_id') ?? ApiService.sheetId;
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => saving = true);
    await ApiService.saveSettings(
      url: controller.text.trim(),
      id: sheetController.text.trim(),
    );
    setState(() => saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Library connection saved.')),
      );
    }
  }

  Future<void> _testSheet() async {
    setState(() => testing = true);
    try {
      final value = sheetController.text.trim();
      if (value.isEmpty) throw Exception('Enter a Google Sheet URL or ID.');
      final result = await ApiService.validateSheet(value);
      if (result['valid'] == true) {
        await ApiService.saveSettings(url: controller.text.trim(), id: value);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to: ${result['spreadsheet'] ?? 'Google Sheet'}')),
          );
        }
      } else {
        final missing = (result['missingColumns'] as List?)?.join(', ') ?? '';
        throw Exception(missing.isEmpty ? (result['error'] ?? 'Invalid sheet.') : 'Missing columns: $missing');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Apps Script Web App URL',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://script.google.com/macros/s/.../exec',
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 18),
            const Text(
              'Google Sheet URL or Sheet ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: sheetController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://docs.google.com/spreadsheets/d/.../edit',
                helperText: 'The spreadsheet must contain a Books sheet with the required 14 fields.',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(saving ? 'Saving...' : 'Save'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: testing ? null : _testSheet,
                  icon: const Icon(Icons.cloud_done),
                  label: Text(testing ? 'Checking...' : 'Test Sheet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBooksScreen extends StatefulWidget {
  const SearchBooksScreen({super.key});

  @override
  State<SearchBooksScreen> createState() => _SearchBooksScreenState();
}

class _SearchBooksScreenState extends State<SearchBooksScreen> {
  final controller = TextEditingController();
  bool loading = false;
  List<dynamic> books = [];

  Future<void> search() async {
    setState(() => loading = true);
    try {
      final result =
          await ApiService.searchBooks(controller.text.trim());
      books = (result['books'] as List?) ?? [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Books')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => search(),
                    decoration: const InputDecoration(
                      labelText: 'Title / Author / Stock / ISBN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: loading ? null : search,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          if (loading)
            const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (_, index) {
                final b =
                    Map<String, dynamic>.from(books[index]);
                final shelf = '${b['Shelf'] ?? ''}'.trim();
                return ListTile(
                  title: Text(
                    '${b['Title'] ?? ''}',
                  ),
                  subtitle: Text(
                    'Stock: ${b['Stock Number'] ?? ''}   '
                    'Call: ${b['Call Number'] ?? ''}\n'
                    'Author: ${b['Author'] ?? ''}\n'
                    'Shelf: ${shelf.isEmpty ? '-' : shelf}',
                  ),
                  isThreeLine: true,
                  trailing: shelf.isEmpty
                      ? null
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3EBFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'SHELF',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A6BD6),
                                ),
                              ),
                              Text(
                                shelf,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2F3E6B),
                                ),
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
