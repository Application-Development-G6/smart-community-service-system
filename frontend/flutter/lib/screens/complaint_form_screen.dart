import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/complaints_api.dart';

const _complaintCategories = [
  'Roads and sidewalks',
  'Waste management',
  'Water and drainage',
  'Street lighting',
  'Public safety',
  'Other',
];

enum ComplaintFormNavigation { trackReports }

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _category;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      if (file.size > 5 * 1024 * 1024) {
        _showMessage('Choose an image that is 5 MB or smaller.');
        return;
      }
      if (file.bytes == null) {
        _showMessage('The selected image could not be read.');
        return;
      }

      setState(() {
        _imageBytes = file.bytes;
        _imageName = file.name;
      });
    } catch (error) {
      _showMessage('Unable to choose an image: $error');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ComplaintsApi.createComplaint(
        title: _titleController.text.trim(),
        category: _category!,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ComplaintsApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unable to submit the complaint: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit a complaint'),
        actions: [
          if (isWide) ...[
            _FormNavButton(
              label: 'Home',
              onPressed: () => Navigator.pop(context),
            ),
            const _FormNavButton(label: 'Report a Problem', selected: true),
            _FormNavButton(
              label: 'Track Reports',
              onPressed: () =>
                  Navigator.pop(context, ComplaintFormNavigation.trackReports),
            ),
          ] else
            PopupMenuButton<int>(
              tooltip: 'Navigation',
              icon: const Icon(Icons.menu_rounded),
              onSelected: (index) {
                if (index == 0) Navigator.pop(context);
                if (index == 2) {
                  Navigator.pop(context, ComplaintFormNavigation.trackReports);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 0, child: Text('Home')),
                PopupMenuItem(value: 1, child: Text('Report a Problem')),
                PopupMenuItem(value: 2, child: Text('Track Reports')),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1060),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                final formCard = _buildFormCard(context);
                final nextStepsCard = const _NextStepsCard();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESIDENT SERVICES',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF21835F),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Report a community problem',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFF173B2E),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Provide the details below so the concern can be documented.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFF718078)),
                    ),
                    const SizedBox(height: 18),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: formCard),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: nextStepsCard),
                        ],
                      )
                    else ...[
                      formCard,
                      const SizedBox(height: 16),
                      nextStepsCard,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldLabel(context, 'Report title *'),
              TextFormField(
                controller: _titleController,
                maxLength: 150,
                decoration: const InputDecoration(
                  hintText: 'Briefly describe the problem',
                  counterText: '',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fields = [
                    _categoryField(context),
                    _locationField(context),
                  ];
                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        fields[0],
                        const SizedBox(height: 16),
                        fields[1],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 14),
                      Expanded(child: fields[1]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel(context, 'Description *'),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue and any useful details...',
                  alignLabelWithHint: true,
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),
              _fieldLabel(context, 'Photo evidence (optional)'),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _chooseImage,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  _imageName ?? 'Choose a photo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  side: const BorderSide(color: Color(0xFFDCE8E0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'JPEG, PNG, GIF, or WebP. Maximum file size: 5 MB.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFF718078), fontSize: 11),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _imageBytes!,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                            _imageBytes = null;
                            _imageName = null;
                          }),
                    icon: const Icon(Icons.close),
                    label: const Text('Remove photo'),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Please provide accurate information. For emergencies, '
                  'contact the appropriate emergency service directly. '
                  'This system is not an emergency-response service.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF557267), height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit report',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF176B4D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, 'Problem category *'),
        DropdownButtonFormField<String>(
          initialValue: _category,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Select category'),
          items: _complaintCategories
              .map(
                (category) =>
                    DropdownMenuItem(value: category, child: Text(category)),
              )
              .toList(),
          onChanged: (value) => setState(() => _category = value),
          validator: (value) => value == null ? 'Choose a category' : null,
        ),
      ],
    );
  }

  Widget _locationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, 'Location / Purok *'),
        TextFormField(
          controller: _locationController,
          maxLength: 255,
          decoration: const InputDecoration(
            hintText: 'e.g. Purok 2, near the covered court',
            counterText: '',
          ),
          validator: _requiredValidator,
        ),
      ],
    );
  }

  Widget _fieldLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF173B2E),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }
}

class _FormNavButton extends StatelessWidget {
  const _FormNavButton({
    required this.label,
    this.selected = false,
    this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? const Color(0xFF176B4D)
            : const Color(0xFF607168),
        backgroundColor: selected
            ? const Color(0xFFE5F2E9)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        title: 'Report submitted',
        description: 'Your concern is saved with a reference number.',
      ),
      (
        title: 'Official review',
        description: 'Authorized officials review and prioritize reports.',
      ),
      (
        title: 'Status updated',
        description: 'Follow progress from Pending to Ongoing and Resolved.',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What happens next?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF173B2E),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A simple overview of the process',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFF718078)),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < steps.length; index++) ...[
              _NextStepRow(
                number: index + 1,
                title: steps[index].title,
                description: steps[index].description,
              ),
              if (index < steps.length - 1)
                const Divider(height: 1, color: Color(0xFFE3EBE6)),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextStepRow extends StatelessWidget {
  const _NextStepRow({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D9),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF765419),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF173B2E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF718078), height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
