import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/profile_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/blocked_user_bottom_sheet.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final _nameController = TextEditingController();
  String? _avatarUrl;
  bool _isLoading = false;
  String? _phone;
  String? _originalName; // Зберігаємо оригінальне ім'я
  final ProfileService _profileService = ProfileService();
  XFile? _pickedAvatar;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    // Перевіряємо статус користувача після завантаження
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final userStatus = await _profileService.getUserStatus();
        if (userStatus == 'blocked') {
          _showBlockedUserBottomSheet();
        }
      }
    });
  }

  void _showBlockedUserBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Неможливо закрити
      enableDrag: false, // Неможливо перетягувати
      builder: (context) => const BlockedUserBottomSheet(),
    );
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await _profileService.getUser(user.id);
    
    // Спробуємо отримати номер телефону різними способами
    String? phoneNumber = user.phone;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      // Спробуємо отримати з профілю
      phoneNumber = profile?.phone;
    }
    if (phoneNumber == null || phoneNumber.isEmpty) {
      // Спробуємо отримати з email (якщо використовується як телефон)
      phoneNumber = user.email;
    }
    
    print('User phone: ${user.phone}');
    print('Profile phone: ${profile?.phone}');
    print('User email: ${user.email}');
    print('Profile: $profile');
    
    setState(() {
      final fullName = (profile?.firstName ?? '') + (profile?.lastName != null ? ' ${profile!.lastName}' : '');
      _nameController.text = fullName;
      _originalName = fullName; // Зберігаємо оригінальне ім'я
      _avatarUrl = profile?.avatarUrl;
      _phone = phoneNumber ?? '+380951234567'; // Fallback для тестування
      print('Loaded phone: $_phone');
      _isLoading = false;
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedAvatar = picked;
          _avatarBytes = bytes;
        });
      } else {
        setState(() {
          _pickedAvatar = picked;
          _avatarBytes = null;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final nameParts = _nameController.text.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    setState(() => _isLoading = true);
    await _profileService.updateUserProfile(
      userId: user.id,
      firstName: firstName,
      lastName: lastName,
      // avatarUrl: _avatarUrl, // Додати upload якщо потрібно
    );
    setState(() => _isLoading = false);
    if (mounted) Navigator.of(context).pop();
  }

  // Перевіряємо, чи змінилося ім'я
  bool get _hasNameChanged {
    return _nameController.text.trim() != (_originalName ?? '').trim();
  }

  // Перевіряємо, чи є у користувача власна іконка
  bool get _hasCustomAvatar {
    return _avatarUrl != null && _avatarUrl!.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!_isLoading)
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            // Хедер
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF27272A),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 18),
                                  const Text(
                                    'Особисті данні',
                                    style: TextStyle(
                                      color: Color(0xFF161817),
                                      fontSize: 24,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      height: 1.20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Аватар + кнопки
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: _pickAvatar,
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFE4E4E7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(200),
                                      ),
                                    ),
                                    child: _avatarBytes != null
                                        ? ClipOval(child: Image.memory(_avatarBytes!, fit: BoxFit.cover, width: 64, height: 64))
                                        : (_pickedAvatar != null && !kIsWeb)
                                            ? ClipOval(child: Image.file(File(_pickedAvatar!.path), fit: BoxFit.cover, width: 64, height: 64))
                                            : (_avatarUrl != null)
                                                ? ClipOval(child: Image.network(_avatarUrl!, fit: BoxFit.cover, width: 64, height: 64))
                                                : const Icon(Icons.person, size: 32, color: Color(0xFFA1A1AA)),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Показуємо "Видалити" тільки якщо є власна іконка
                                    if (_hasCustomAvatar)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: ShapeDecoration(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(200),
                                          ),
                                        ),
                                        child: const Text(
                                          'Видалити',
                                          style: TextStyle(
                                            color: Color(0xFFB8362D),
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            height: 1.40,
                                            letterSpacing: 0.14,
                                          ),
                                        ),
                                      ),
                                    if (_hasCustomAvatar)
                                      const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: ShapeDecoration(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(200),
                                        ),
                                      ),
                                      child: const Text(
                                        'Оновити',
                                        style: TextStyle(
                                          color: Color(0xFF27272A),
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          height: 1.40,
                                          letterSpacing: 0.14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Ім'я та прізвище
                            Container(
                              width: double.infinity,
                              height: 48,
                              alignment: Alignment.centerLeft,
                              decoration: ShapeDecoration(
                                color: const Color(0xFFFAFAFA),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(width: 1, color: Color(0xFFE4E4E7)),
                                  borderRadius: BorderRadius.circular(200),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x0C101828),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                    spreadRadius: 0,
                                  )
                                ],
                              ),
                              child: TextField(
                                controller: _nameController,
                                textAlignVertical: TextAlignVertical.center,
                                textAlign: TextAlign.left,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  hintText: "Ім'я та прізвище",
                                  hintStyle: TextStyle(
                                    color: Color(0xFFA1A1AA),
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                    letterSpacing: 0.16,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                  letterSpacing: 0.16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Телефон (disabled)
                            Container(
                              width: double.infinity,
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(200),
                                border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(16, 24, 40, 0.05),
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/UA.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+380',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      height: 1.50,
                                      letterSpacing: 0.16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Builder(
                                      builder: (context) {
                                        final phoneNumber = _phone?.replaceFirst('+380', '') ?? '';
                                        print('Displaying phone: $phoneNumber (original: $_phone)');
                                        return Text(
                                          phoneNumber,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            height: 1.50,
                                            letterSpacing: 0.16,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Кнопки внизу
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 13, right: 13, bottom: 34, top: 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasNameChanged 
                                ? const Color(0xFF015873)
                                : const Color(0xFFE4E4E7), // Сірий колір коли неактивна
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(200),
                                side: BorderSide(
                                  color: _hasNameChanged 
                                    ? const Color(0xFF015873)
                                    : const Color(0xFFE4E4E7),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                              elevation: 0,
                            ),
                            onPressed: _hasNameChanged ? _saveProfile : null,
                            child: Text(
                              'Підтвердити',
                              style: TextStyle(
                                color: _hasNameChanged ? Colors.white : const Color(0xFFA1A1AA),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFE4E4E7)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(200),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Скасувати',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
} 