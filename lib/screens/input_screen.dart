import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/meal_providers.dart';
import 'confirm_screen.dart';

class InputScreen extends ConsumerStatefulWidget {
  final String? prefill;
  const InputScreen({super.key, this.prefill});

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  late final TextEditingController _controller;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.prefill ?? '');
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _imageBytes = bytes;
        _error = null;
      });
      _analyze();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Foto konnte nicht geladen werden: $e');
    }
  }

  Future<void> _analyze() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _imageBytes == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(claudeClientProvider);
      final result = await client.parseMeal(text, imageBytes: _imageBytes);
      if (!mounted) return;
      if (!result.isMeal) {
        setState(() {
          _error = result.rejectionReason ??
              'Bitte beschreibe ein Essen oder Getränk.';
          _loading = false;
        });
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmScreen(
            rawText: text,
            parsed: result,
            imageBytes: _imageBytes,
          ),
        ),
      );
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAnalyze = !_loading &&
        (_controller.text.trim().isNotEmpty || _imageBytes != null);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(title: const Text('Neuer Eintrag'), centerTitle: false),
        body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText:
                    'z.B. Müsli mit Joghurt, oder großer Latte Macchiato',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Kamera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _loading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galerie'),
                  ),
                ),
              ],
            ),
            if (_imageBytes != null) ...[
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _imageBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _loading
                            ? null
                            : () => setState(() => _imageBytes = null),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.close,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            FilledButton.icon(
              onPressed: canAnalyze ? _analyze : null,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Analysiere...' : 'Analysieren'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
