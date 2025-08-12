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
  String? _selectedType;
  bool _isLoading = false;
  bool _isButtonEnabled = false;

  final List<String> _complaintTypes = [
    'Товар не відповідає опису',
    'Не отримав товар',
    'Продавець не відповідав',
    'Проблема з оплатою',
    'Неналежна поведінка',
    'Інше',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateButtonState);
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    final bool shouldBeEnabled = _selectedType != null && _descriptionController.text.isNotEmpty;
    if (shouldBeEnabled != _isButtonEnabled) {
      setState(() {
        _isButtonEnabled = shouldBeEnabled;
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (!_isButtonEnabled || _isLoading) return;

    // Trigger validation
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final complaintService = ComplaintService(Supabase.instance.client);
      await complaintService.createComplaint(
        listingId: widget.productId,
        title: _selectedType!,
        description: _descriptionController.text,
        types: [_selectedType!],
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Success
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop(false); // Error
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
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Повідомити про проблему',
                  style: AppTextStyles.heading3Medium.copyWith(fontSize: 24),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Опишіть проблему яку ви зустріли з цим продавцем',
              style: AppTextStyles.body1Regular.copyWith(color: AppColors.color7),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _complaintTypes.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedType = null;
                      } else {
                        _selectedType = type;
                      }
                    });
                    _updateButtonState();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: ShapeDecoration(
                      color: isSelected ? const Color(0xFFF4F4F5) : Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: isSelected ? const Color(0xFFF4F4F5) : const Color(0xFFE4E4E7),
                        ),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      shadows: isSelected
                          ? []
                          : [
                              const BoxShadow(
                                color: Color(0x0C101828),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                                spreadRadius: 0,
                              )
                            ],
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xFF52525B),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.30,
                        letterSpacing: 0.24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Опис',
              style: TextStyle(
                color: const Color(0xFF52525B),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.40,
                letterSpacing: 0.14,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Опишіть свою скаргу текст',
                hintStyle: const TextStyle(
                  color: Color(0xFFA1A1AA),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                  letterSpacing: 0.16,
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.zinc200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.zinc200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryColor),
                ),
              ),
              maxLines: 4,
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
                onPressed: _isButtonEnabled && !_isLoading ? _submitComplaint : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonEnabled ? AppColors.primaryColor : AppColors.zinc200,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Надіслати скаргу'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.zinc200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Скасувати', style: TextStyle(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 