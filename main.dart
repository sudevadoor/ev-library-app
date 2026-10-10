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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E.V. LIBRARY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
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

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 46),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
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
                return ListTile(
                  title: Text(
                    '${b['Title'] ?? ''}',
                  ),
                  subtitle: Text(
                    'Stock: ${b['Stock Number'] ?? ''}   '
                    'Call: ${b['Call Number'] ?? ''}\n'
                    'Author: ${b['Author'] ?? ''}',
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
