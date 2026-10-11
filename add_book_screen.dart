import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../services/api_service.dart';
import 'barcode_scanner_screen.dart';

enum StockNumberMode { generate, manual, ocr }
enum EntryMode { manual, ocr }

enum ChoiceEntryMode { list, manual, ocr }

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final stockController = TextEditingController();
  final barcodeController = TextEditingController();
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final priceController = TextEditingController();
  final publisherController = TextEditingController();
  final editionController = TextEditingController();
  final subjectsController = TextEditingController();
  final callNumberController = TextEditingController();

  final languageController = TextEditingController();
  final categoryController = TextEditingController();
  final shelfController = TextEditingController();
  final bookTypeController = TextEditingController();
  final statusController = TextEditingController();

  StockNumberMode stockMode = StockNumberMode.generate;

  EntryMode titleMode = EntryMode.manual;
  EntryMode authorMode = EntryMode.manual;
  EntryMode priceMode = EntryMode.manual;
  EntryMode publisherMode = EntryMode.manual;
  EntryMode editionMode = EntryMode.manual;
  EntryMode subjectsMode = EntryMode.manual;

  ChoiceEntryMode languageMode = ChoiceEntryMode.list;
  ChoiceEntryMode categoryMode = ChoiceEntryMode.list;
  ChoiceEntryMode shelfMode = ChoiceEntryMode.list;
  ChoiceEntryMode bookTypeMode = ChoiceEntryMode.list;
  ChoiceEntryMode statusMode = ChoiceEntryMode.list;

  List<String> categories = [];
  List<String> languages = [];
  List<String> shelves = [];
  List<String> bookTypes = [];
  List<String> statuses = [];

  String? language;
  String? category;
  String? shelf;
  String? bookType;
  String? status;

  bool loading = false;
  bool generatingCall = false;

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  @override
  void dispose() {
    stockController.dispose();
    barcodeController.dispose();
    titleController.dispose();
    authorController.dispose();
    priceController.dispose();
    publisherController.dispose();
    editionController.dispose();
    subjectsController.dispose();
    callNumberController.dispose();
    languageController.dispose();
    categoryController.dispose();
    shelfController.dispose();
    bookTypeController.dispose();
    statusController.dispose();
    super.dispose();
  }

  Future<void> loadConfig() async {
    try {
      final result = await ApiService.getConfig();

      categories = List<String>.from(result['categories'] ?? []);
      languages = List<String>.from(result['languages'] ?? []);
      shelves = List<String>.from(result['shelves'] ?? []);
      bookTypes = List<String>.from(result['bookTypes'] ?? []);
      statuses = List<String>.from(result['statuses'] ?? []);

      if (language == null && languages.isNotEmpty) language = languages.first;
      if (category == null && categories.isNotEmpty) category = categories.first;
      if (bookType == null && bookTypes.isNotEmpty) bookType = bookTypes.first;

      languageController.text = language ?? '';
      categoryController.text = category ?? '';
      bookTypeController.text = bookType ?? '';
      statusController.text = status ?? '';

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Configuration error: $e')),
        );
      }
    }
  }

  Future<void> generateStockNumber() async {
    setState(() => loading = true);
    try {
      final result = await ApiService.getNextStockNumber();
      stockController.text = result['stockNumber']?.toString() ?? '';
      if (mounted) setState(() => stockMode = StockNumberMode.generate);
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> scanStockNumberOCR() async {
    final text = await recognizeCameraText();
    if (text == null || text.trim().isEmpty) return;

    final extracted = extractStockNumber(text);
    if (extracted.isEmpty) {
      showError('Could not identify a stock number. Please try again or enter it manually.');
      return;
    }

    stockController.text = extracted;
    if (mounted) setState(() => stockMode = StockNumberMode.ocr);
  }

  String extractStockNumber(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    for (final line in lines) {
      final cleaned = line
          .replaceAll(
            RegExp(r'(?i)(stock\s*(number|no|num)?|accession\s*(number|no)?|sl\.?\s*no\.?)\s*[:#\-]?'),
            '',
          )
          .trim();
      final match = RegExp(r'[A-Za-z0-9][A-Za-z0-9\-\/]*').firstMatch(cleaned);
      if (match != null) return match.group(0)!.trim();
    }

    final fallback = RegExp(r'\b\d{1,8}\b').firstMatch(text);
    return fallback?.group(0) ?? '';
  }

  Future<String?> recognizeCameraText() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (image == null) return null;

    setState(() => loading = true);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final input = InputImage.fromFilePath(image.path);
      final recognized = await recognizer.processImage(input);
      return recognized.text;
    } catch (e) {
      showError('OCR failed: $e');
      return null;
    } finally {
      await recognizer.close();
      if (mounted) setState(() => loading = false);
    }
  }

  int maxLinesForOcr(TextEditingController controller) =>
      controller == subjectsController ? 3 : 1;

  /// Cleans raw OCR output: removes stray symbols, joins broken lines
  /// into one line and collapses repeated spaces.
  String cleanOcrText(String raw, {bool singleLine = true}) {
    var lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l
            .replaceAll(RegExp(r'[|_~^`\\<>{}\[\]=*#@]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim())
        // drop fragments with no letters or digits (OCR noise)
        .where((l) => RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(l))
        .toList();
    final joined = lines.join(singleLine ? ' ' : '\n').trim();
    return joined.replaceAll(RegExp(r' {2,}'), ' ');
  }

  Future<void> ocrInto(
    TextEditingController controller, {
    bool numericOnly = false,
  }) async {
    final text = await recognizeCameraText();
    if (text == null || text.trim().isEmpty) return;

    String value = cleanOcrText(text, singleLine: maxLinesForOcr(controller) == 1);
    if (numericOnly) {
      final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(value);
      value = match?.group(0) ?? value;
    }
    controller.text = value;
    if (mounted) setState(() {});
  }

  Future<void> scanBarcode() async {
    final value = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (value == null || value.isEmpty) return;

    barcodeController.text = value;
    setState(() => loading = true);

    try {
      final existing = await ApiService.checkBarcode(value);

      if (existing['exists'] == true && mounted) {
        final count = existing['count'] ?? 0;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('ISBN already exists'),
            content: Text(
              'This barcode/ISBN already exists for $count physical copy/copies.\n\n'
              'The details of the existing book can be used as a starting point. '
              'You can edit them and add another physical copy.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        final existingBook = existing['book'];
        if (existingBook is Map) {
          fillFromMap(existingBook);
        }
      } else {
        final metadata = await ApiService.getBookMetadata(value);
        if (metadata['found'] == true) {
          fillFromMetadata(metadata);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Book details retrieved. Please review/edit before saving.')),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ISBN detected, but no online details were found. Enter the fields manually or use OCR.')),
          );
        }
      }
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void fillFromMetadata(Map<String, dynamic> data) {
    titleController.text = data['title']?.toString() ?? '';
    authorController.text = data['author']?.toString() ?? '';
    publisherController.text = data['publisher']?.toString() ?? '';
    editionController.text = data['edition']?.toString() ?? '';
    subjectsController.text = data['subjects']?.toString() ?? '';

    setChoiceFromValue(
      type: 'language',
      value: data['language']?.toString() ?? '',
    );

    if (mounted) setState(() {});
  }

  void fillFromMap(Map data) {
    titleController.text = data['Title']?.toString() ?? data['title']?.toString() ?? '';
    authorController.text = data['Author']?.toString() ?? data['author']?.toString() ?? '';
    priceController.text = data['Price']?.toString() ?? data['price']?.toString() ?? '';
    publisherController.text = data['Publisher']?.toString() ?? data['publisher']?.toString() ?? '';
    editionController.text = data['Edition']?.toString() ?? data['edition']?.toString() ?? '';
    subjectsController.text = data['Subjects']?.toString() ?? data['subjects']?.toString() ?? '';

    setChoiceFromValue(type: 'language', value: data['Language']?.toString() ?? '');
    setChoiceFromValue(type: 'category', value: data['Category']?.toString() ?? '');
    setChoiceFromValue(type: 'shelf', value: data['Shelf']?.toString() ?? '');
    setChoiceFromValue(type: 'bookType', value: data['Book Type']?.toString() ?? '');
    setChoiceFromValue(type: 'status', value: data['Status']?.toString() ?? '');

    if (mounted) setState(() {});
  }

  void setChoiceFromValue({required String type, required String value}) {
    final text = value.trim();
    if (text.isEmpty) return;

    List<String> list;
    switch (type) {
      case 'language': list = languages; break;
      case 'category': list = categories; break;
      case 'shelf': list = shelves; break;
      case 'bookType': list = bookTypes; break;
      default: list = statuses;
    }

    String? match;
    for (final item in list) {
      if (item.toLowerCase() == text.toLowerCase()) {
        match = item;
        break;
      }
    }

    if (type == 'language') {
      language = match;
      languageController.text = match ?? text;
    } else if (type == 'category') {
      category = match;
      categoryController.text = match ?? text;
    } else if (type == 'shelf') {
      shelf = match;
      shelfController.text = match ?? text;
    } else if (type == 'bookType') {
      bookType = match;
      bookTypeController.text = match ?? text;
    } else {
      status = match;
      statusController.text = match ?? text;
    }

    if (match == null) {
      setState(() {
        if (type == 'language') languageMode = ChoiceEntryMode.manual;
        if (type == 'category') categoryMode = ChoiceEntryMode.manual;
        if (type == 'shelf') shelfMode = ChoiceEntryMode.manual;
        if (type == 'bookType') bookTypeMode = ChoiceEntryMode.manual;
        if (type == 'status') statusMode = ChoiceEntryMode.manual;
      });
    }
  }

  Future<void> showShelfPicker() async {
    if (shelves.isEmpty) {
      await showShelfManager();
      return;
    }

    int page = 0;
    const pageSize = 8;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final totalPages = (shelves.length / pageSize).ceil();
            if (page >= totalPages && totalPages > 0) page = totalPages - 1;
            final start = page * pageSize;
            final end = (start + pageSize < shelves.length)
                ? start + pageSize
                : shelves.length;
            final visibleShelves = shelves.sublist(start, end);

            return AlertDialog(
              title: Row(
                children: [
                  const Expanded(child: Text('Select Shelf')),
                  IconButton(
                    tooltip: 'Modify Shelf Numbers',
                    icon: const Icon(Icons.edit_note),
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await showShelfManager();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (visibleShelves.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No shelf numbers available.'),
                      )
                    else
                      ...visibleShelves.map(
                        (item) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.shelves),
                          title: Text(item),
                          selected: shelf == item,
                          onTap: () {
                            setState(() {
                              shelf = item;
                              shelfController.text = item;
                              shelfMode = ChoiceEntryMode.list;
                            });
                            Navigator.pop(dialogContext);
                          },
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: 'Previous 8 shelves',
                          onPressed: page > 0
                              ? () => setDialogState(() => page--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          totalPages == 0
                              ? '0 shelves'
                              : '${start + 1}–$end of ${shelves.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          tooltip: 'Next 8 shelves',
                          onPressed: page + 1 < totalPages
                              ? () => setDialogState(() => page++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await showShelfManager();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Modify Shelves'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showShelfManager() async {
    final controllers = <TextEditingController>[];
    for (final item in shelves) {
      controllers.add(TextEditingController(text: item));
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modify Shelf Numbers'),
              content: SizedBox(
                width: 420,
                height: 480,
                child: ListView.builder(
                  itemCount: controllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controllers[index],
                              decoration: InputDecoration(
                                labelText: 'Shelf ${index + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove shelf',
                            onPressed: () {
                              setDialogState(() {
                                controllers[index].dispose();
                                controllers.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      controllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Shelf'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final updated = controllers
                        .map((c) => c.text.trim())
                        .where((x) => x.isNotEmpty)
                        .toSet()
                        .toList();

                    if (updated.isEmpty) {
                      showError('Enter at least one shelf number.');
                      return;
                    }

                    try {
                      setState(() => loading = true);
                      await ApiService.saveShelves(updated);
                      if (!mounted) return;
                      setState(() {
                        shelves = updated;
                        shelf = shelves.contains(shelf) ? shelf : null;
                        if (shelf == null) shelfController.clear();
                      });
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Shelf list updated successfully. The modified list is now available in the Shelf dropdown.'),
                        ),
                      );
                    } catch (e) {
                      showError(e);
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Shelf List'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<void> generateCallNumber() async {
    final currentCategory = categoryMode == ChoiceEntryMode.list
        ? category
        : categoryController.text.trim();

    if (currentCategory == null ||
        currentCategory.isEmpty ||
        titleController.text.trim().isEmpty ||
        authorController.text.trim().isEmpty) {
      showError('Enter Category, Title and Author first.');
      return;
    }

    setState(() => generatingCall = true);
    try {
      final result = await ApiService.generateCallNumber(
        category: currentCategory,
        author: authorController.text.trim(),
        title: titleController.text.trim(),
      );
      callNumberController.text = result['callNumber']?.toString() ?? '';
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => generatingCall = false);
    }
  }

  String choiceValue(
    String type,
    ChoiceEntryMode mode,
  ) {
    if (type == 'language') return mode == ChoiceEntryMode.list ? (language ?? '') : languageController.text.trim();
    if (type == 'category') return mode == ChoiceEntryMode.list ? (category ?? '') : categoryController.text.trim();
    if (type == 'shelf') return mode == ChoiceEntryMode.list ? (shelf ?? '') : shelfController.text.trim();
    if (type == 'bookType') return mode == ChoiceEntryMode.list ? (bookType ?? '') : bookTypeController.text.trim();
    return mode == ChoiceEntryMode.list ? (status ?? '') : statusController.text.trim();
  }

  Future<void> saveBook() async {
    final stock = stockController.text.trim();
    final title = titleController.text.trim();
    final currentCategory = choiceValue('category', categoryMode);

    if (stock.isEmpty) {
      showError('Stock Number is required.');
      return;
    }
    if (title.isEmpty) {
      showError('Title is required.');
      return;
    }
    if (currentCategory.isEmpty) {
      showError('Please select or enter a Category.');
      return;
    }

    setState(() => loading = true);
    try {
      final result = await ApiService.addBook({
        'stockNumber': stock,
        'stockNumberMode': stockMode.name,
        'barcode': barcodeController.text.trim(),
        'title': title,
        'author': authorController.text.trim(),
        'language': choiceValue('language', languageMode),
        'category': currentCategory,
        'price': priceController.text.trim(),
        'publisher': publisherController.text.trim(),
        'edition': editionController.text.trim(),
        'shelf': choiceValue('shelf', shelfMode),
        'bookType': choiceValue('bookType', bookTypeMode),
        'status': choiceValue('status', statusMode),
        'subjects': subjectsController.text.trim(),
        'callNumber': callNumberController.text.trim(),
        'allowDuplicateBarcode': true,
      });

      if (result['duplicateBarcode'] == true) {
        showError(result['message']?.toString() ?? 'Barcode already exists.');
        return;
      }

      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Book Saved'),
            content: Text(
              'Stock Number: $stock\nCall Number: ${(result['callNumber']?.toString() ?? '').isNotEmpty ? result['callNumber'] : callNumberController.text}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  Widget modeButtons({
    required EntryMode value,
    required ValueChanged<EntryMode> onChanged,
  }) {
    return SegmentedButton<EntryMode>(
      segments: const [
        ButtonSegment(value: EntryMode.manual, label: Text('Manual'), icon: Icon(Icons.edit, size: 17)),
        ButtonSegment(value: EntryMode.ocr, label: Text('OCR'), icon: Icon(Icons.document_scanner, size: 17)),
      ],
      selected: {value},
      onSelectionChanged: (v) async {
        final mode = v.first;
        onChanged(mode);
      },
    );
  }

  Widget textEntry({
    required String label,
    required TextEditingController controller,
    required EntryMode mode,
    required ValueChanged<EntryMode> onModeChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool numericOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
              modeButtons(value: mode, onChanged: (newMode) async {
                onModeChanged(newMode);
                if (newMode == EntryMode.ocr) {
                  await ocrInto(controller, numericOnly: numericOnly);
                }
              }),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: '$label (editable)',
              border: const OutlineInputBorder(),
              suffixIcon: mode == EntryMode.ocr
                  ? IconButton(
                      tooltip: 'Scan with OCR',
                      onPressed: () => ocrInto(controller, numericOnly: numericOnly),
                      icon: const Icon(Icons.document_scanner),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget choiceEntry({
    required String label,
    required String? selected,
    required List<String> items,
    required TextEditingController controller,
    required ChoiceEntryMode mode,
    required ValueChanged<ChoiceEntryMode> onModeChanged,
    required ValueChanged<String?> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
              DropdownButton<ChoiceEntryMode>(
                value: mode,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: ChoiceEntryMode.list, child: Text('List')),
                  DropdownMenuItem(value: ChoiceEntryMode.manual, child: Text('Manual')),
                  DropdownMenuItem(value: ChoiceEntryMode.ocr, child: Text('OCR')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  onModeChanged(v);
                  if (v == ChoiceEntryMode.ocr) {
                    final text = await recognizeCameraText();
                    if (text != null && text.trim().isNotEmpty) {
                      controller.text = text.trim();
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (mode == ChoiceEntryMode.list)
            DropdownButtonFormField<String>(
              initialValue: items.contains(selected) ? selected : null,
              decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: onSelected,
            )
          else
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '$label (editable)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Scan with OCR',
                  onPressed: () async {
                    final text = await recognizeCameraText();
                    if (text != null && text.trim().isNotEmpty) {
                      controller.text = text.trim();
                      if (mounted) setState(() {});
                    }
                  },
                  icon: const Icon(Icons.document_scanner),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget stockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stock Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: stockController,
          decoration: InputDecoration(
            labelText: 'Stock Number (editable)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: 'Clear',
              onPressed: () { stockController.clear(); setState(() {}); },
              icon: const Icon(Icons.clear),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<StockNumberMode>(
          segments: const [
            ButtonSegment(value: StockNumberMode.generate, label: Text('Generate'), icon: Icon(Icons.auto_awesome)),
            ButtonSegment(value: StockNumberMode.manual, label: Text('Manual'), icon: Icon(Icons.edit)),
            ButtonSegment(value: StockNumberMode.ocr, label: Text('OCR'), icon: Icon(Icons.document_scanner)),
          ],
          selected: {stockMode},
          onSelectionChanged: (value) {
            setState(() => stockMode = value.first);
            if (stockMode == StockNumberMode.generate) generateStockNumber();
            if (stockMode == StockNumberMode.ocr) scanStockNumberOCR();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Book')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stockSection(),
                const Divider(height: 32),

                const Text('Barcode / ISBN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'ISBN / Barcode (manual)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Scan Barcode',
                      onPressed: scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                textEntry(
                  label: 'Title',
                  controller: titleController,
                  mode: titleMode,
                  onModeChanged: (v) => setState(() => titleMode = v),
                  maxLines: 2,
                ),
                textEntry(
                  label: 'Author',
                  controller: authorController,
                  mode: authorMode,
                  onModeChanged: (v) => setState(() => authorMode = v),
                ),

                choiceEntry(
                  label: 'Language',
                  selected: language,
                  items: languages,
                  controller: languageController,
                  mode: languageMode,
                  onModeChanged: (v) => setState(() => languageMode = v),
                  onSelected: (v) => setState(() { language = v; languageController.text = v ?? ''; }),
                ),
                choiceEntry(
                  label: 'Category',
                  selected: category,
                  items: categories,
                  controller: categoryController,
                  mode: categoryMode,
                  onModeChanged: (v) => setState(() => categoryMode = v),
                  onSelected: (v) => setState(() { category = v; categoryController.text = v ?? ''; }),
                ),
                textEntry(
                  label: 'Price',
                  controller: priceController,
                  mode: priceMode,
                  onModeChanged: (v) => setState(() => priceMode = v),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  numericOnly: true,
                ),
                textEntry(
                  label: 'Publisher',
                  controller: publisherController,
                  mode: publisherMode,
                  onModeChanged: (v) => setState(() => publisherMode = v),
                ),
                textEntry(
                  label: 'Edition',
                  controller: editionController,
                  mode: editionMode,
                  onModeChanged: (v) => setState(() => editionMode = v),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Shelf',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: showShelfManager,
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text('Modify Shelves'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: showShelfPicker,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Select Shelf',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            shelfController.text.isEmpty
                                ? 'Choose a shelf (8 shown at a time)'
                                : shelfController.text,
                            style: TextStyle(
                              color: shelfController.text.isEmpty
                                  ? Theme.of(context).hintColor
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shelves.isEmpty
                            ? 'No shelves configured. Tap Modify Shelves to add them.'
                            : '${shelves.length} shelf numbers available • 8 shown at a time',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                choiceEntry(
                  label: 'Book Type',
                  selected: bookType,
                  items: bookTypes,
                  controller: bookTypeController,
                  mode: bookTypeMode,
                  onModeChanged: (v) => setState(() => bookTypeMode = v),
                  onSelected: (v) => setState(() { bookType = v; bookTypeController.text = v ?? ''; }),
                ),
                choiceEntry(
                  label: 'Status (Optional)',
                  selected: status,
                  items: statuses,
                  controller: statusController,
                  mode: statusMode,
                  onModeChanged: (v) => setState(() => statusMode = v),
                  onSelected: (v) => setState(() { status = v; statusController.text = v ?? ''; }),
                ),
                textEntry(
                  label: 'Subjects (Optional)',
                  controller: subjectsController,
                  mode: subjectsMode,
                  onModeChanged: (v) => setState(() => subjectsMode = v),
                  maxLines: 3,
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: callNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Call Number',
                          border: OutlineInputBorder(),
                          helperText: 'Generate automatically or edit manually. OCR is not provided for Call Number.',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Generate Call Number',
                      onPressed: generatingCall ? null : generateCallNumber,
                      icon: generatingCall
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                    ),
                  ],
                ),

                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: callNumberController,
                  builder: (context, value, _) {
                    final text = value.text.trim();
                    if (text.isEmpty) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_library),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Call Number', style: TextStyle(fontSize: 12)),
                                SelectableText(
                                  text,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: loading ? null : saveBook,
                    icon: const Icon(Icons.save),
                    label: Text(loading ? 'Processing...' : 'SAVE BOOK'),
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
        ],
      ),
    );
  }
}
