import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/profile_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/blocked_user_bottom_sheet.dart';
import '../services/profile_notifier.dart'; // Import ProfileNotifier
import '../utils/avatar_utils.dart';

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
  String? _nameError; // Помилка для імені
  final ProfileService _profileService = ProfileService();
  XFile? _pickedAvatar;
  Uint8List? _avatarBytes;

  // Змінні для попереднього перегляду змін
  String? _tempAvatarUrl; // Тимчасовий URL аватара
  String? _tempName; // Тимчасове ім'я
  bool _hasUnsavedChanges = false; // Чи є незбережені зміни
  bool _isAvatarDeleted = false; // Чи видалено аватар

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    // Додаємо слухач для інпуту
    _nameController.addListener(() {
      setState(() {
        if (_nameError != null) {
          _nameError = null;
        }
        // Перевіряємо, чи змінилося ім'я
        _tempName = _nameController.text;
        _checkForUnsavedChanges();
      });
    });
    
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

  void _showBlockedUserBottomSheet() async {
    // Отримуємо профіль користувача з причиною блокування
    final userProfile = await _profileService.getCurrentUserProfile();
    final blockReason = userProfile?['block_reason'];
    
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false, // Неможливо закрити
        enableDrag: false, // Неможливо перетягувати
        builder: (context) => BlockedUserBottomSheet(blockReason: blockReason),
      );
    }
  }

  // Метод для перевірки незбережених змін
  void _checkForUnsavedChanges() {
    final nameChanged = _tempName != _originalName;
    final avatarChanged = _tempAvatarUrl != _avatarUrl || _isAvatarDeleted;
    
    setState(() {
      _hasUnsavedChanges = nameChanged || avatarChanged;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _deleteAvatar() async {
    print('Marking avatar for deletion...');
    
    // Тільки позначаємо аватар як видалений, не видаляємо одразу
      setState(() {
      _tempAvatarUrl = null;
      _isAvatarDeleted = true;
      _checkForUnsavedChanges();
    });
  }

  Future<void> _loadProfile() async {
    print('Loading profile...');
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('No current user found in _loadProfile');
      return;
    }
    print('Loading profile for user: ${user.id}');
    final profile = await _profileService.getUser(user.id);
    print('Profile loaded: ${profile?.avatarUrl}');
    
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
    
    
    
    setState(() {
      final fullName = (profile?.firstName ?? '') + (profile?.lastName != null ? ' ${profile!.lastName}' : '');
      _nameController.text = fullName;
      _originalName = fullName; // Зберігаємо оригінальне ім'я
      _tempName = fullName; // Встановлюємо тимчасове ім'я
      
      // Перевіряємо, чи URL не порожній
      final avatarUrl = profile?.avatarUrl;
      final isValidAvatar = AvatarUtils.isValidAvatarUrl(avatarUrl);
      print('Avatar URL from profile: $avatarUrl, isValid: $isValidAvatar');
      _avatarUrl = isValidAvatar ? avatarUrl : null;
      _tempAvatarUrl = _avatarUrl; // Встановлюємо тимчасовий URL аватара
      print('Final avatar URL set to: $_avatarUrl');
      _phone = phoneNumber ?? '+380951234567'; // Fallback для тестування
      
      _hasUnsavedChanges = false;
      _isAvatarDeleted = false;
      _isLoading = false;
    });
    print('Profile loading completed');
  }

  Future<void> _pickAvatar() async {
    print('PersonalDataPage._pickAvatar called');
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      print('Image picked: ${picked.path}');
      setState(() => _isLoading = true);
      
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          print('No current user found in _pickAvatar');
          return;
        }
        print('Current user ID in _pickAvatar: ${user.id}');

        String? avatarUrl;
        
        if (kIsWeb) {
          // Для веб версії
          final bytes = await picked.readAsBytes();
          final fileName = 'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final response = await Supabase.instance.client.storage
              .from('avatars')
              .uploadBinary(fileName, bytes);
          
          avatarUrl = Supabase.instance.client.storage
              .from('avatars')
              .getPublicUrl(fileName);
        } else {
          // Для мобільної версії
          final fileName = 'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final fileBytes = await picked.readAsBytes();
          
          final response = await Supabase.instance.client.storage
              .from('avatars')
              .uploadBinary(fileName, fileBytes);
          
          avatarUrl = Supabase.instance.client.storage
              .from('avatars')
              .getPublicUrl(fileName);
        }

        if (avatarUrl != null) {
          // Тільки встановлюємо тимчасовий URL, не зберігаємо одразу
          setState(() {
            _tempAvatarUrl = avatarUrl;
            _isAvatarDeleted = false;
            _checkForUnsavedChanges();
          });
        }
      } catch (e) {

        _showErrorSnackBar('Помилка при завантаженні фото');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    print('PersonalDataPage._saveProfile called');
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('No current user found in _saveProfile');
      return;
    }
    print('Current user ID in _saveProfile: ${user.id}');
    
    setState(() => _isLoading = true);
    
    try {
      // Застосовуємо зміни імені
      if (_tempName != _originalName) {
        final nameParts = _tempName?.trim().split(' ') ?? [];
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        print('Name parts: firstName=$firstName, lastName=$lastName');
        
        await _profileService.updateUserProfile(
          userId: user.id,
          firstName: firstName,
          lastName: lastName,
          avatarUrl: _avatarUrl, // Зберігаємо поточний URL аватара
        );
      }
      
      // Застосовуємо зміни аватара
      if (_tempAvatarUrl != _avatarUrl || _isAvatarDeleted) {
        if (_isAvatarDeleted) {
          // Видаляємо аватар
          if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
            try {
              final uri = Uri.parse(_avatarUrl!);
              final pathSegments = uri.pathSegments;
              if (pathSegments.isNotEmpty) {
                final fileName = pathSegments.last;
                await Supabase.instance.client.storage
                    .from('avatars')
                    .remove([fileName]);
              }
            } catch (storageError) {
              print('Storage removal error: $storageError');
            }
          }
          
          await _profileService.updateUserProfile(
            userId: user.id,
            avatarUrl: null,
          );
          
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'avatar_url': null,
              },
            ),
          );
        } else if (_tempAvatarUrl != null) {
          // Оновлюємо аватар
          await _profileService.updateUserProfile(
            userId: user.id,
            avatarUrl: _tempAvatarUrl,
          );
          
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'avatar_url': _tempAvatarUrl,
              },
            ),
          );
        }
      }
      
      // Оновлюємо локальний стан
      setState(() {
        _originalName = _tempName;
        _avatarUrl = _tempAvatarUrl;
        _hasUnsavedChanges = false;
        _isAvatarDeleted = false;
      });
      
      ProfileNotifier().notifyProfileUpdate();
      
      if (mounted) Navigator.of(context).pop(true); // Повертаємо true щоб показати, що зміни були збережені
    } catch (e) {
      print('Error saving profile: $e');
      _showErrorSnackBar('Помилка при збереженні змін: $e');
    } finally {
    setState(() => _isLoading = false);
    }
  }

  // Перевіряємо, чи змінилося ім'я
  bool get _hasNameChanged {
    return _nameController.text.trim() != (_originalName ?? '').trim();
  }

  // Перевіряємо, чи ім'я валідне
  bool get _isNameValid {
    return _nameController.text.trim().isNotEmpty;
  }

  // Перевіряємо, чи можна зберегти
  bool get _canSave {
    return _hasUnsavedChanges && _isNameValid;
  }

  // Перевіряємо, чи є у користувача власна іконка (оригінальна або тимчасова)
  bool get _hasCustomAvatar {
    // Якщо аватар позначений як видалений, не показуємо його
    if (_isAvatarDeleted) {
      return false;
    }
    final currentAvatarUrl = _tempAvatarUrl ?? _avatarUrl;
    final hasCustom = AvatarUtils.isValidAvatarUrl(currentAvatarUrl);
    print('_hasCustomAvatar check: $currentAvatarUrl -> $hasCustom');
    return hasCustom;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('PersonalDataPage.build called, _avatarUrl=$_avatarUrl, _hasCustomAvatar=$_hasCustomAvatar');
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
                                            : AvatarUtils.buildAvatar(
                                                avatarUrl: _hasCustomAvatar ? (_tempAvatarUrl ?? _avatarUrl) : null,
                                                size: 64,
                                                backgroundColor: const Color(0xFFE4E4E7),
                                                iconColor: const Color(0xFFA1A1AA),
                                                iconSize: 32,
                                              ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Показуємо "Видалити" тільки якщо є власна іконка і вона не позначена як видалена
                                    if (_hasCustomAvatar)
                                      GestureDetector(
                                        onTap: _deleteAvatar,
                                        child: Container(
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
                                      ),
                                    if (_hasCustomAvatar)
                                      const SizedBox(width: 8),
                                    GestureDetector( // Added GestureDetector here
                                      onTap: _pickAvatar, // Call _pickAvatar when 'Оновити' is tapped
                                      child: Container(
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
                                onChanged: (value) {
                                  setState(() {
                                    _tempName = value;
                                    _checkForUnsavedChanges();
                                  });
                                },
                                textAlignVertical: TextAlignVertical.center,
                                textAlign: TextAlign.left,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  hintText: "Введіть ім'я",
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
                              backgroundColor: _canSave 
                                ? const Color(0xFF015873)
                                : const Color(0xFFE4E4E7), // Сірий колір коли неактивна
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(200),
                                side: BorderSide(
                                  color: _canSave 
                                    ? const Color(0xFF015873)
                                    : const Color(0xFFE4E4E7),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                              elevation: 0,
                            ),
                            onPressed: _canSave ? () {
                              if (!_isNameValid) {
                                _showErrorSnackBar('Ім\'я не може бути порожнім');
                                return;
                              }
                              _saveProfile();
                            } : null,
                            child: Text(
                              _hasUnsavedChanges ? 'Підтвердити зміни' : 'Підтвердити',
                              style: TextStyle(
                                color: _canSave ? Colors.white : const Color(0xFFA1A1AA),
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
                            onPressed: () {
                              // Відновлюємо оригінальний стан при скасуванні
                              setState(() {
                                _tempName = _originalName;
                                _nameController.text = _originalName ?? '';
                                _tempAvatarUrl = _avatarUrl;
                                _isAvatarDeleted = false;
                                _hasUnsavedChanges = false;
                              });
                              Navigator.of(context).pop();
                            },
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