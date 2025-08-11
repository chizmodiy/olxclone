import 'package:flutter/material.dart';
import '../services/complaint_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintModal extends StatefulWidget {
  final String productId;

  const ComplaintModal({
    super.key,
    required this.productId,
  });

  @override
  State<ComplaintModal> createState() => _ComplaintModalState();
}

class _ComplaintModalState extends State<ComplaintModal> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedTypes = {};
  bool _isLoading = false;

  final List<String> _complaintTypes = [
    'Шахрайство',
    'Неправдива інформація',
    'Заборонений товар',
    'Спам',
    'Образливий контент',
    'Інше',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      // No need to show snackbar here, parent will handle it
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    if (_selectedTypes.isEmpty) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final complaintService = ComplaintService(Supabase.instance.client);
      await complaintService.createComplaint(
        listingId: widget.productId,
        title: 'Не вказано',
        description: _descriptionController.text,
        types: _selectedTypes.toList(),
      );

      if (mounted) {
        // Повідомляємо батьківський віджет про успіх
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        // Повідомляємо батьківський віджет про помилку
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Поскаржитись на оголошення',
                style: AppTextStyles.heading3Medium,
              ),
              const SizedBox(height: 16),
              Text(
                'Тип скарги',
                style: AppTextStyles.body1Semibold,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _complaintTypes.map((type) {
                  final isSelected = _selectedTypes.contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTypes.add(type);
                        } else {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primaryColor.withOpacity(0.1),
                    checkmarkColor: AppColors.primaryColor,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Опис скарги',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введіть опис скарги';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Надіслати'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 