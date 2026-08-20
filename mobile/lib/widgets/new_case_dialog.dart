import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/case_file.dart';
import '../services/api_exception.dart';
import '../theme/app_theme.dart';

Future<CaseFile?> showNewCaseDialog(BuildContext context) {
  return showDialog<CaseFile>(
    context: context,
    builder: (_) => const _NewCaseDialog(),
  );
}

class _NewCaseDialog extends StatefulWidget {
  const _NewCaseDialog();

  @override
  State<_NewCaseDialog> createState() => _NewCaseDialogState();
}

class _NewCaseDialogState extends State<_NewCaseDialog> {
  late final TextEditingController _caseNumberController;
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _caseNumberController = TextEditingController(text: 'CHD-${now.year}-${now.millisecondsSinceEpoch % 1000}');
  }

  @override
  void dispose() {
    _caseNumberController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_caseNumberController.text.trim().isEmpty) {
      setState(() => _error = 'Case / FIR number is required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = context.read<Repository>();
      final created = await repo.createCase(
        caseNumber: _caseNumberController.text.trim(),
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on ApiHttpException catch (e) {
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.folder_open, color: AppColors.accent, size: 20),
          SizedBox(width: 10),
          Text('New Case / FIR'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _caseNumberController,
              decoration: const InputDecoration(labelText: 'Case / FIR number', prefixIcon: Icon(Icons.numbers)),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title (optional)', prefixIcon: Icon(Icons.title)),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location (optional)', prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentOn))
              : const Text('CREATE'),
        ),
      ],
    );
  }
}
