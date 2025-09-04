import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import '../services/listing_service.dart';
import '../services/complaint_service.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/user_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';
import '../services/profile_service.dart';
import '../widgets/logout_confirmation_bottom_sheet.dart';
import '../widgets/success_bottom_sheet.dart'; // Import the new success bottom sheet

// Додаю ActionIconButton і SVG одразу після імпортів
class _ActionIconButton extends StatelessWidget {
  final String svg;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;
  const _ActionIconButton({required this.svg, required this.tooltip, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),
          child: SvgPicture.string(
            svg,
            width: 20,
            height: 20,
            color: color,
          ),
        ),
      ),
    );
  }
}

const String _chevronLeftSvg = '''<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M12.2556 4.41073C12.581 4.73617 12.581 5.26381 12.2556 5.58925L7.84485 9.99999L12.2556 14.4107C12.581 14.7362 12.581 15.2638 12.2556 15.5892C11.9302 15.9147 11.4025 15.9147 11.0771 15.5892L6.07709 10.5892C5.75165 10.2638 5.75165 9.73617 6.07709 9.41073L11.0771 4.41073C11.4025 4.0853 11.9302 4.0853 12.2556 4.41073Z" fill="currentColor"/></svg>''';

const String _chevronRightSvg = '''<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M7.74408 4.41073C8.06951 4.0853 8.59715 4.0853 8.92259 4.41073L13.9226 9.41073C14.248 9.73617 14.248 10.2638 13.9226 10.5892L8.92259 15.5892C8.59715 15.9147 8.06951 15.9147 7.74408 15.5892C7.41864 15.2638 7.41864 14.7362 7.74408 14.4107L12.1548 9.99999L7.74408 5.58925C7.41864 5.26381 7.41864 4.73617 7.74408 4.41073Z" fill="currentColor"/></svg>''';

const String _userIconSvg = '''<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M20 20C24.4183 20 28 16.4183 28 12C28 7.58172 24.4183 4 20 4C15.5817 4 12 7.58172 12 12C12 16.4183 15.5817 20 20 20Z" fill="#6B7280"/><path d="M8 36C8 28.268 13.268 23 21 23H19C11.268 23 6 28.268 6 36H8Z" fill="#6B7280"/></svg>''';

const String _productIconSvg = '''<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="40" height="40" rx="8" fill="#3B82F6"/><path d="M12 16H28M12 20H28M12 24H20" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

const String _arrowUpRightSvg = '''<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M5.83398 14.1667L14.1673 5.83334M14.1673 5.83334H5.83398M14.1673 5.83334V14.1667" stroke="black" stroke-width="1.66667" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

const String _slashCircleSvg = '''<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><g clip-path="url(#clip0_2001_301)"><path d="M4.10768 4.10832L15.891 15.8917M18.3327 9.99999C18.3327 14.6024 14.6017 18.3333 9.99935 18.3333C5.39698 18.3333 1.66602 14.6024 1.66602 9.99999C1.66602 5.39762 5.39698 1.66666 9.99935 1.66666C14.6017 1.66666 18.3327 5.39762 18.3327 9.99999Z" stroke="#52525B" stroke-width="1.66667" stroke-linecap="round" stroke-linejoin="round"/></g><defs><clipPath id="clip0_2001_301"><rect width="20" height="20" fill="white"/></clipPath></defs></svg>''';

const String _trashSvg = '''<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M13.3333 4.99999V4.33332C13.3333 3.3999 13.3333 2.93319 13.1517 2.57667C12.9919 2.26307 12.7369 2.0081 12.4233 1.84831C12.0668 1.66666 11.6001 1.66666 10.6667 1.66666H9.33333C8.39991 1.66666 7.9332 1.66666 7.57668 1.84831C7.26308 2.0081 7.00811 2.26307 6.84832 2.57667C6.66667 2.93319 6.66667 3.3999 6.66667 4.33332V4.99999M8.33333 9.58332V13.75M11.6667 9.58332V13.75M2.5 4.99999H17.5M15.8333 4.99999V14.3333C15.8333 15.7335 15.8333 16.4335 15.5608 16.9683C15.3212 17.4387 14.9387 17.8212 14.4683 18.0608C13.9335 18.3333 13.2335 18.3333 11.8333 18.3333H8.16667C6.76654 18.3333 6.06647 18.3333 5.53169 18.0608C5.06129 17.8212 4.67883 17.4387 4.43915 16.9683C4.16667 16.4335 4.16667 15.7335 4.16667 14.3333V4.99999" stroke="#B42318" stroke-width="1.66667" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

// Функція для показу діалогу видалення оголошення
Future<void> showDeleteListingDialog({
  required BuildContext context,
  required VoidCallback onDelete,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 390,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Заголовок
                    Text(
                      'Видалити оголошення',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                        color: Colors.black,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Пояснення
                    Text(
                      'Ви впевнені що бажаєте видалити це оголошення?',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Inter',
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: const StadiumBorder(),
                              side: const BorderSide(color: Color(0xFFE4E4E7)),
                              backgroundColor: Colors.white,
                              shadowColor: Color.fromRGBO(16, 24, 40, 0.05),
                              elevation: 1,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Скасувати',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: const StadiumBorder(),
                              backgroundColor: Color(0xFFB42318),
                              side: const BorderSide(color: Color(0xFFB42318)),
                              shadowColor: Color.fromRGBO(16, 24, 40, 0.05),
                              elevation: 1,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDelete();
                            },
                            child: const Text(
                              'Видалити',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Кнопка закриття (іконка)
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                      color: Colors.transparent,
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF27272A), size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Функція для показу діалогу блокування оголошення
Future<void> showBlockListingDialog({
  required BuildContext context,
  required String listingTitle,
  required VoidCallback onBlock,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 390,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Заголовок
                    Text(
                      'Заблокувати оголошення',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                        color: Colors.black,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Пояснення
                    Text(
                      'Ви впевнені що бажаєте заблокувати оголошення "$listingTitle"?',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Inter',
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: const StadiumBorder(),
                              side: const BorderSide(color: Color(0xFFE4E4E7)),
                              backgroundColor: Colors.white,
                              shadowColor: Color.fromRGBO(16, 24, 40, 0.05),
                              elevation: 1,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Скасувати',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: const StadiumBorder(),
                              backgroundColor: Color(0xFFF04438),
                              side: const BorderSide(color: Color(0xFFF04438)),
                              shadowColor: Color.fromRGBO(16, 24, 40, 0.05),
                              elevation: 1,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onBlock();
                            },
                            child: const Text(
                              'Заблокувати',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Кнопка закриття (іконка)
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                      color: Colors.transparent,
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF27272A), size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedTab = 0; // 0 - Оголошення, 1 - Скарги, 2 - Користувачі
  bool _showMenu = false;
  final List<String> _tabs = ['Оголошення', 'Скарги', 'Користувачі'];

  final ProductService _productService = ProductService();
  final ListingService _listingService = ListingService(Supabase.instance.client);
  final ComplaintService _complaintService = ComplaintService(Supabase.instance.client);
  List<Product> _products = [];
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingProducts = false;
  bool _isLoadingComplaints = false;
  bool _isLoadingUsers = false;
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _pageSize = 8;

  final CategoryService _categoryService = CategoryService();
  final Map<String, String> _categoryNameCache = {};
  Map<String, String> _allCategories = {};
  final UserService _userService = UserService(Supabase.instance.client);
  final ProfileService _profileService = ProfileService();

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initCategoriesAndProducts();
    
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

  void _showLogoutConfirmationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const LogoutConfirmationBottomSheet(),
    );
  }

  Future<void> _initCategoriesAndProducts() async {
    await _fetchAllCategories();
    await _fetchProducts();
    await _fetchComplaints();
    await _fetchUsers();
  }

  Future<void> _fetchAllCategories() async {
    final cats = await _categoryService.getCategories();
    setState(() {
      _allCategories = {for (var c in cats) c.id: c.name};
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    
    try {
      // Використовуємо Supabase напряму для адмін панелі, щоб отримати актуальні дані
      dynamic query = Supabase.instance.client
          .from('listings')
          .select()
          .order('created_at', ascending: false);
      
      // Додаємо пошук якщо є запит
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$_searchQuery%');
      }
      
      // Додаємо пагінацію
      query = query.range((_currentPage - 1) * _pageSize, (_currentPage * _pageSize) - 1);
      
      final response = await query;
      final products = (response as List).map((json) => Product.fromJson(json)).toList();
      
      // Підрахунок загальної кількості сторінок з урахуванням фільтрів
      dynamic countQuery = Supabase.instance.client
        .from('listings')
        .select('id', const FetchOptions(count: CountOption.exact));
      
      // Додаємо ті ж фільтри для підрахунку
      if (_searchQuery.isNotEmpty) {
        countQuery = countQuery.ilike('title', '%$_searchQuery%');
      }
      
      final countResp = await countQuery;
    final totalCount = countResp.count ?? products.length;
      
    setState(() {
      _products = products;
      _isLoadingProducts = false;
      _totalPages = (totalCount / _pageSize).ceil().clamp(1, 9999);
    });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _fetchComplaints() async {
    print('=== _fetchComplaints початок ===');
    setState(() => _isLoadingComplaints = true);
    try {
      final complaints = await _complaintService.getComplaints();
      
      setState(() {
        _complaints = complaints;
        _isLoadingComplaints = false;
      });
      print('=== _fetchComplaints завершено, знайдено ${complaints.length} скарг ===');
      
    } catch (e) {
      print('=== _fetchComplaints помилка: $e ===');
      setState(() {
        _isLoadingComplaints = false;
      });
      if (mounted) {
        // Error loading complaints
      }
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('id', ascending: false);
      setState(() {
        _users = List<Map<String, dynamic>>.from(users);
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      if (mounted) {
        // Error loading users
      }
    }
  }

  void _onPageChanged(int newPage) {
    if (newPage < 1 || newPage > _totalPages) return;
    setState(() => _currentPage = newPage);
    _fetchProducts();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = value;
        _currentPage = 1;
      });
      _fetchProducts();
    });
  }

  Future<String> _getCategoryName(String categoryId) async {
    if (_categoryNameCache.containsKey(categoryId)) {
      return _categoryNameCache[categoryId]!;
    }
    final name = await _categoryService.getCategoryNameCached(categoryId);
    setState(() {
      _categoryNameCache[categoryId] = name;
    });
    return name;
  }

  // Додаю метод для пагінації
  Widget _buildPagination() {
    return Container(
      height: 64,
      padding: const EdgeInsets.only(top: 12, bottom: 16, left: 24, right: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFEAECF0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ліва частина: текст
          Row(
            children: [
              Text(
                'Сторінка $_currentPage із $_totalPages',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.14,
                  height: 1.4,
                ),
              ),
            ],
          ),
          // Права частина: кнопки
          Row(
            children: [
              _PaginationButton(isLeft: true, onTap: _currentPage > 1 ? () => _onPageChanged(_currentPage - 1) : null),
              const SizedBox(width: 8),
              _PaginationButton(isLeft: false, onTap: _currentPage < _totalPages ? () => _onPageChanged(_currentPage + 1) : null),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final initials = _getInitials(user?.email ?? '');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE4E4E7), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Логотип
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF015873),
                      ),
                    ),
                    const SizedBox(width: 40),
                    // Навігація
                    Row(
                      children: List.generate(_tabs.length, (i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton(
                          onPressed: () => setState(() => _selectedTab = i),
                          style: TextButton.styleFrom(
                            backgroundColor: i == _selectedTab ? const Color(0xFFF4F4F5) : Colors.transparent,
                            foregroundColor: i == _selectedTab ? Colors.black : const Color(0xFF667085),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(200), side: BorderSide(color: i == _selectedTab ? const Color(0xFFF4F4F5) : Colors.transparent)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.16, fontFamily: 'Inter'),
                          ),
                          child: Text(_tabs[i]),
                        ),
                      )),
                    ),
                  ],
                ),
                // Аватар і меню
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showMenu = !_showMenu),
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrl))
                        : CircleAvatar(radius: 18, backgroundColor: const Color(0xFFE2E8F0), child: Text(initials, style: const TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500))),
                    ),
                    if (_showMenu)
                      Positioned(
                        right: 0,
                        top: 44,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE4E4E7)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.logout, size: 20),
                                  title: const Text('Вийти', style: TextStyle(fontSize: 16)),
                                  onTap: () {
                                    _showLogoutConfirmationBottomSheet();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 36),
                        child: Column(
                          children: [
                            // Блок заголовку з пошуком і фільтром
                            Container(
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Оголошення',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                      height: 1.2,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // Поле пошуку
                                      Container(
                                        width: 320,
                                        constraints: const BoxConstraints(minHeight: 44),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F3F3),
                                          borderRadius: BorderRadius.circular(200),
                                          border: Border.all(color: const Color(0xFFE4E4E7)),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color.fromRGBO(16, 24, 40, 0.05),
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 16),
                                              child: Icon(Icons.search, color: Color(0xFF52525B), size: 20),
                                            ),
                                            Expanded(
                                              child: Theme(
                                                data: Theme.of(context).copyWith(
                                                  hoverColor: Colors.transparent,
                                                  focusColor: Colors.transparent,
                                                  splashColor: Colors.transparent,
                                                  highlightColor: Colors.transparent,
                                                ),
                                                child: TextField(
                                                  onChanged: _onSearchChanged,
                                                  decoration: InputDecoration(
                                                    hintText: 'Пошук',
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(200),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(200),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(200),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    filled: true,
                                                    fillColor: const Color(0xFFF3F3F3),
                                                    hintStyle: const TextStyle(
                                                      color: Color(0xFFA1A1AA),
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w400,
                                                      fontFamily: 'Inter',
                                                      letterSpacing: 0.16,
                                                      height: 1.5,
                                                    ),
                                                    isDense: true,
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Кнопка фільтра
                                      OutlinedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.filter_alt_outlined, color: Colors.black, size: 20),
                                        label: const Text(
                                          'Фільтр',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.16,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          side: const BorderSide(color: Color(0xFFE4E4E7)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(200)),
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                                        ),
                                      ),
                                    ],
                                  ),

                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Блок для таблиці оголошень
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 36),
                              constraints: const BoxConstraints(
                                minHeight: 80 + 8 * 72 + 56, // заголовки + 8 рядків + пагінація
                                maxHeight: 80 + 8 * 72 + 56,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE4E4E7)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Заголовки колонок
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFAFAFA),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: const [
                                        Expanded(flex: 2, child: Text('Назва', style: TextStyle(fontWeight: FontWeight.w600))),
                                        Expanded(flex: 3, child: Text('Опис', style: TextStyle(fontWeight: FontWeight.w600))),
                                        Expanded(flex: 2, child: Text('Дата', style: TextStyle(fontWeight: FontWeight.w600))),
                                        Expanded(flex: 2, child: Text('Ціна', style: TextStyle(fontWeight: FontWeight.w600))),
                                        Expanded(flex: 2, child: Text('Локація', style: TextStyle(fontWeight: FontWeight.w600))),
                                        Expanded(flex: 2, child: Text('Категорія', style: TextStyle(fontWeight: FontWeight.w600))),
                                        Expanded(flex: 2, child: Text('Статус', style: TextStyle(fontWeight: FontWeight.w600))),
                                        SizedBox(width: 40), // Для іконки видалення
                                      ],
                                    ),
                                  ),
                                  // Рядки з реальними даними (без скролу)
                                  _isLoadingProducts
                                      ? const Expanded(child: Center(child: CircularProgressIndicator()))
                                      : Expanded(
                                          child: Column(
                                            children: [
                                              for (final ad in _products.take(8))
                                                SizedBox(
                                                  height: 72,
                                                  child: AdminAdTableRow(
                                                  ad: ad,
                                                  categoryName: _allCategories[ad.categoryId] ?? '',
                                                  formatDate: _formatDate,
                                                  formatPrice: _formatPrice,
                                                  listingService: _listingService,
                                                  onStatusChanged: () => _fetchProducts(),
                                                  ),
                                                ),
                                            ],
                                          ),
                                  ),
                                  // Пагінація (завжди внизу)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                                    child: _buildPagination(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _selectedTab == 1
                    ? SingleChildScrollView(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 36),
                            child: Column(
                              children: [
                                // Блок заголовку з пошуком і фільтром
                                Container(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Скарги',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                          height: 1.2,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          // Кнопка оновлення скарг
                                          ElevatedButton(
                                            onPressed: _fetchComplaints,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Оновити скарги'),
                                          ),
                                          const SizedBox(width: 24),
                                          // Поле пошуку
                                          Container(
                                            width: 320,
                                            constraints: const BoxConstraints(minHeight: 44),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F3F3),
                                              borderRadius: BorderRadius.circular(200),
                                              border: Border.all(color: const Color(0xFFE4E4E7)),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color.fromRGBO(16, 24, 40, 0.05),
                                                  blurRadius: 2,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                                  child: Icon(Icons.search, color: Color(0xFF52525B), size: 20),
                                                ),
                                                Expanded(
                                                  child: Theme(
                                                    data: Theme.of(context).copyWith(
                                                      hoverColor: Colors.transparent,
                                                      focusColor: Colors.transparent,
                                                      splashColor: Colors.transparent,
                                                      highlightColor: Colors.transparent,
                                                    ),
                                                    child: TextField(
                                                      onChanged: _onSearchChanged,
                                                      decoration: InputDecoration(
                                                        hintText: 'Пошук',
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(200),
                                                          borderSide: BorderSide.none,
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(200),
                                                          borderSide: BorderSide.none,
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(200),
                                                          borderSide: BorderSide.none,
                                                        ),
                                                        filled: true,
                                                        fillColor: const Color(0xFFF3F3F3),
                                                        hintStyle: const TextStyle(
                                                          color: Color(0xFFA1A1AA),
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w400,
                                                          fontFamily: 'Inter',
                                                          letterSpacing: 0.16,
                                                          height: 1.5,
                                                        ),
                                                        isDense: true,
                                                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                                const SizedBox(height: 40),
                                // Блок для таблиці скарг
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 36),
                                  constraints: const BoxConstraints(
                                    minHeight: 80 + 8 * 72 + 56, // заголовки + 8 рядків + пагінація
                                    maxHeight: 80 + 8 * 72 + 56,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE4E4E7)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Заголовки колонок
                                      Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFAFAFA),
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                        ),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        child: Row(
                                          children: const [
                                            SizedBox(width: 280, child: Text('Автор скарги', style: TextStyle(fontWeight: FontWeight.w600))),
                                            SizedBox(width: 280, child: Text('Оголошення', style: TextStyle(fontWeight: FontWeight.w600))),
                                            Expanded(child: Text('Короткий опис', style: TextStyle(fontWeight: FontWeight.w600))),
                                            SizedBox(width: 80), // Для іконок дій
                                          ],
                                        ),
                                      ),
                                      // Рядки з реальними даними (без скролу)
                                      _isLoadingProducts
                                          ? const Expanded(child: Center(child: CircularProgressIndicator()))
                                          : Expanded(
                                              child: Column(
                                                children: [
                                                  // Реальні дані з бази
                                                  if (_isLoadingComplaints)
                                                    const Expanded(child: Center(child: CircularProgressIndicator()))
                                                  else if (_complaints.isEmpty)
                                                    Expanded(
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.inbox_outlined,
                                                              size: 64,
                                                              color: Colors.grey[400],
                                                            ),
                                                            const SizedBox(height: 16),
                                                            Text(
                                                              'Скарг поки немає',
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.w500,
                                                                color: Colors.grey[600],
                                                              ),
                                                            ),
                                                            const SizedBox(height: 8),
                                                            Text(
                                                              'Коли користувачі створюють скарги,\nвони з\'являться тут',
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors.grey[500],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    for (final complaint in _complaints.take(8))
                                                      ComplaintTableRow(
                                                        complaint: complaint,
                                                        onViewDetails: () {
                                                          print('=== onViewDetails викликано ===');
                                                          showComplaintDialog(
                                                            context: context,
                                                            complaint: complaint,
                                                            onComplaintProcessed: () {
                                                              print('=== onComplaintProcessed викликано ===');
                                                              if (mounted) {
                                                                print('=== Викликаємо _fetchComplaints ===');
                                                                _fetchComplaints();
                                                                print('=== _fetchComplaints завершено ===');
                                                              }
                                                            },
                                                          );
                                                        },
                                                      ),
                                                ],
                                              ),
                                      ),
                                      // Пагінація (завжди внизу)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                                        child: _buildPagination(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : _selectedTab == 2
                        ? SingleChildScrollView(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 36),
                                child: Column(
                                  children: [
                                    // Блок заголовку з пошуком і фільтром
                                    Container(
                                      width: double.infinity,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                          const Text(
                                            'Користувачі',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter',
                                              height: 1.2,
                                            ),
                                          ),
                                        Row(
                                          children: [
                                              // Поле пошуку
                                              Container(
                                                width: 320,
                                                constraints: const BoxConstraints(minHeight: 44),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF3F3F3),
                                                  borderRadius: BorderRadius.circular(200),
                                                  border: Border.all(color: const Color(0xFFE4E4E7)),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color.fromRGBO(16, 24, 40, 0.05),
                                                      blurRadius: 2,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                                      child: Icon(Icons.search, color: Color(0xFF52525B), size: 20),
                                                    ),
                                                    Expanded(
                                                      child: Theme(
                                                        data: Theme.of(context).copyWith(
                                                          hoverColor: Colors.transparent,
                                                          focusColor: Colors.transparent,
                                                          splashColor: Colors.transparent,
                                                          highlightColor: Colors.transparent,
                                                        ),
                                                        child: TextField(
                                                          onChanged: _onSearchChanged,
                                                          decoration: InputDecoration(
                                                            hintText: 'Пошук',
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(200),
                                                              borderSide: BorderSide.none,
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(200),
                                                              borderSide: BorderSide.none,
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(200),
                                                              borderSide: BorderSide.none,
                                                            ),
                                                            filled: true,
                                                            fillColor: const Color(0xFFF3F3F3),
                                                            hintStyle: const TextStyle(
                                                              color: Color(0xFFA1A1AA),
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w400,
                                                              fontFamily: 'Inter',
                                                              letterSpacing: 0.16,
                                                              height: 1.5,
                                                            ),
                                                            isDense: true,
                                                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                                    const SizedBox(height: 40),
                                    // Блок для таблиці користувачів
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 36),
                                      constraints: const BoxConstraints(
                                        minHeight: 80 + 8 * 72 + 56, // заголовки + 8 рядків + пагінація
                                        maxHeight: 80 + 8 * 72 + 56,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE4E4E7)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                                      child: Column(
                                        children: [
                                          // Заголовки колонок
                                          Container(
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFAFAFA),
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            child: Row(
                                              children: const [
                                                Expanded(flex: 2, child: Text('Назва', style: TextStyle(fontWeight: FontWeight.w600))),
                                                Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
                                                Expanded(flex: 2, child: Text('Телефон', style: TextStyle(fontWeight: FontWeight.w600))),
                                                Expanded(flex: 2, child: Text('Дата створення', style: TextStyle(fontWeight: FontWeight.w600))),
                                                Expanded(flex: 2, child: Text('Статус', style: TextStyle(fontWeight: FontWeight.w600))),

                                                SizedBox(width: 80), // Для іконок дій
                                              ],
                                            ),
                                          ),
                                          // Рядки з реальними даними (без скролу)
                                          _isLoadingUsers
                                              ? const Expanded(child: Center(child: CircularProgressIndicator()))
                                              : Expanded(
                                                  child: Column(
                                                    children: [
                                                      for (final user in _users.take(8))
                                                        UserTableRow(
                                                          user: user,
                                                          userService: _userService,
                                                          onStatusChanged: () => _fetchUsers(),
                                                          onDelete: () async {
                                                            await showDeleteUserDialog(
                                                              context: context,
                                                              onDelete: () async {
                                                                await _userService.deleteUser(user['id']);
                                                                await _fetchUsers();
                                                              },
                                                            );
                                                          },
                                                        ),
                                                    ],
                                                  ),
                                          ),
                                          // Пагінація (завжди внизу)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 16, bottom: 16),
                                            child: _buildPagination(),
                                          ),
                                        ],
                                      ),
                                    ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text('Сторінка: ${_tabs[_selectedTab]}', style: const TextStyle(fontSize: 24)),
                  ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String email) {
    final parts = email.split('@').first.split('.');
    return parts.map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(Product ad) {
    if (ad.isFree == true) return 'Безкоштовно';
    if (ad.price == null) return '';
    final currency = ad.currency ?? '₴';
    return '$currency${ad.price?.toStringAsFixed(2) ?? ''}';
  }


}

// Додаю віджет для рядка таблиці
class AdminAdTableRow extends StatelessWidget {
  final Product ad;
  final String categoryName;
  final String Function(DateTime?) formatDate;
  final String Function(Product) formatPrice;
  final ListingService listingService;
  final VoidCallback? onStatusChanged;
  const AdminAdTableRow({Key? key, required this.ad, required this.categoryName, required this.formatDate, required this.formatPrice, required this.listingService, this.onStatusChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (ad.photos.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(ad.photos.first, width: 40, height: 40, fit: BoxFit.cover),
                  )
                else
                  Container(width: 40, height: 40, color: const Color(0xFFE4E4E7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ad.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(ad.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(formatDate(ad.createdAt)),
          ),
          Expanded(
            flex: 2,
            child: Text(formatPrice(ad)),
          ),
          Expanded(
            flex: 2,
            child: Text(ad.location ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(categoryName, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(ad.status ?? 'active'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _ActionIconButton(
                svg: _slashCircleSvg,
                tooltip: (ad.status == 'blocked') ? 'Розблокувати' : 'Заблокувати',
                onTap: () {
                  if (ad.status == 'blocked') {
                    // Розблокувати оголошення
                    _unblockListing(context);
                  } else {
                    // Заблокувати оголошення
                    showBlockListingDialog(
                      context: context,
                      listingTitle: ad.title,
                      onBlock: () async {
                        try {
                          await listingService.updateListingStatus(ad.id, 'blocked');
                          // Оновлюємо список продуктів для відображення змін
                          onStatusChanged?.call();
                        } catch (e) {
                          if (context.mounted) {
                            // Error occurred
                          }
                        }
                      },
                    );
                  }
                },
                color: (ad.status == 'blocked') ? Colors.green : null,
              ),
              const SizedBox(width: 8),
              _ActionIconButton(
                svg: _trashSvg,
                tooltip: 'Видалити',
                onTap: () {
                  showDeleteListingDialog(
                    context: context,
                    onDelete: () async {
                      try {
                
                        await listingService.deleteListing(ad.id);
                        // Оновлюємо список продуктів для відображення змін
                        onStatusChanged?.call();
                      } catch (e) {
                        if (context.mounted) {
                          // Error occurred
                        }
                      }
                    },
                  );
                },
                color: const Color(0xFFB42318),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Метод для розблокування оголошення
  Future<void> _unblockListing(BuildContext context) async {
    try {
      await listingService.updateListingStatus(ad.id, 'active');
      // Оновлюємо список продуктів для відображення змін
      onStatusChanged?.call();
    } catch (e) {
      if (context.mounted) {
        // Error occurred
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'active':
        return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
            color: const Color(0xFFB6E6F2),
                  borderRadius: BorderRadius.circular(100),
                ),
          child: const Text(
            'Активний',
                  style: TextStyle(
              color: Color(0xFF015873),
                    fontWeight: FontWeight.w500,
                  ),
                ),
        );
      case 'inactive':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Неактивний',
            style: TextStyle(
              color: Color(0xFF52525B),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.14,
              height: 1.4,
            ),
          ),
        );
      case 'blocked':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCDC2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Заблокований',
            style: TextStyle(
              color: Color(0xFFB42318),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.14,
              height: 1.4,
            ),
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFB6E6F2),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Text(
            'Активний',
            style: TextStyle(
              color: Color(0xFF015873),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }
}

class _PaginationButton extends StatelessWidget {
  final bool isLeft;
  final VoidCallback? onTap;
  const _PaginationButton({required this.isLeft, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E4E7)),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(16, 24, 40, 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
          ),
        ],
        ),
        child: SvgPicture.string(
          isLeft ? _chevronLeftSvg : _chevronRightSvg,
          width: 20,
          height: 20,
          color: onTap != null ? Colors.black : const Color(0xFFBDBDBD),
        ),
      ),
    );
  }
}

// Віджет для рядка скарги
class ComplaintTableRow extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback? onViewDetails;
  
  const ComplaintTableRow({
    Key? key, 
    required this.complaint, 
    this.onViewDetails
  }) : super(key: key);

    @override
  Widget build(BuildContext context) {
    // Get listing info with fallbacks
    final listings = complaint['listings'] ?? {};
    final productName = listings['title'] ?? 'Невідоме оголошення';
    
    // Get user profile info
    final userProfile = complaint['user_profile'];
    final firstName = userProfile?['first_name'] ?? '';
    final lastName = userProfile?['last_name'] ?? '';
    final avatarUrl = userProfile?['avatar_url'];
    
    // Build user name
    String userName;
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      userName = '${firstName.trim()} ${lastName.trim()}'.trim();
    } else {
      // Fallback to user ID if no name
      final complaintCreatorId = complaint['user_id'] ?? 'Невідомий ID';
      userName = 'Користувач $complaintCreatorId';
    }
    
    // Temporary logging to debug
    print('ComplaintTableRow - listings: $listings');
    print('ComplaintTableRow - productName: $productName');
    print('ComplaintTableRow - photos: ${listings['photos']}');
    print('ComplaintTableRow - userProfile: $userProfile');
    print('ComplaintTableRow - userName: $userName');
    print('ComplaintTableRow - avatarUrl: $avatarUrl');
    
    final description = complaint['description'] ?? '';
    
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAECF0), width: 1)),
      ),
      child: Row(
        children: [
          // Автор скарги
          Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Фото користувача
                Container(
            width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[200],
                  ),
                  child: _buildUserAvatar(avatarUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    userName,
                    style: const TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Оголошення
          Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Фото оголошення
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: _buildListingImage(listings['photos']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Короткий опис
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                description,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.16,
                  height: 1.5,
                ),
              ),
            ),
          ),
          // Дії
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _ActionIconButton(
                  svg: _arrowUpRightSvg,
                  tooltip: 'Переглянути деталі',
                  onTap: () {
                    print('=== ComplaintTableRow onTap ===');
                    print('onViewDetails callback: $onViewDetails');
                    showComplaintDialog(
                      context: context, 
                      complaint: complaint,
                      onComplaintProcessed: onViewDetails,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Метод для відображення фото користувача
  Widget _buildUserAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      // Якщо фото немає, показуємо заглушку
      return const Icon(
        Icons.person,
        size: 24,
        color: Colors.grey,
      );
    }
    
    // Показуємо фото користувача
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        avatarUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Якщо фото не завантажилося, показуємо заглушку
          return const Icon(
            Icons.person,
            size: 24,
            color: Colors.grey,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  // Метод для відображення фото оголошення
  Widget _buildListingImage(dynamic photos) {
    if (photos == null || photos.isEmpty || photos is! List || photos.isEmpty) {
      // Якщо фото немає, показуємо іконку
      return const Icon(
        Icons.article,
        size: 24,
        color: Colors.grey,
      );
    }
    
    // Беремо перше фото
    final firstPhoto = photos.first;
    if (firstPhoto == null || firstPhoto.toString().isEmpty) {
      return const Icon(
        Icons.article,
        size: 24,
        color: Colors.grey,
      );
    }
    
    // Показуємо фото
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        firstPhoto.toString(),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Якщо фото не завантажилося, показуємо іконку
          return const Icon(
            Icons.article,
            size: 24,
            color: Colors.grey,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

}

// Віджет для рядка користувача
class UserTableRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onBlock;
  final VoidCallback? onDelete;
  final UserService userService;
  final VoidCallback onStatusChanged;
  
  const UserTableRow({
    Key? key, 
    required this.user, 
    required this.userService,
    required this.onStatusChanged,
    this.onBlock,
    this.onDelete
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final userName = '$firstName $lastName'.trim().isEmpty ? 'Невідомий користувач' : '$firstName $lastName'.trim();
    final email = user['email'] ?? '';
    final phone = user['phone'] ?? '';
    final status = user['status'] ?? 'active';
    final avatarUrl = user['avatar_url'] as String?;
    
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAECF0), width: 1)),
      ),
      child: Row(
        children: [
          // Назва (з аватаром)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: avatarUrl != null && avatarUrl.isNotEmpty 
                          ? Colors.transparent 
                          : const Color(0xFF8B1B1B),
                    ),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              avatarUrl, 
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Email
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                email,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.16,
                  height: 1.5,
                ),
              ),
            ),
          ),
          // Номер телефону
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                phone,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.16,
                  height: 1.5,
                ),
              ),
            ),
          ),
          // Дата створення акаунту
          Expanded(
            flex: 2,
            child: Container(
              width: 160,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                _formatUserDate(user['created_at']),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.16,
                  height: 1.5,
                ),
              ),
            ),
          ),
          // Статус
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildUserStatusBadge(status),
          ),

          // Дії
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _ActionIconButton(
                  svg: _slashCircleSvg,
                  tooltip: status == 'blocked' ? 'Розблокувати користувача' : 'Заблокувати користувача',
                  onTap: () async {
                    if (status == 'blocked') {
                      // Розблокувати користувача
                      await userService.unblockUser(user['id']);
                      onStatusChanged();
                    } else {
                      // Заблокувати користувача
                      await showBlockUserDialog(
                        context: context,
                        onBlock: (String reason) async {
                          await userService.blockUser(user['id'], reason);
                          onStatusChanged();
                        },
                      );
                    }
                  },
                  color: status == 'blocked' ? Colors.green : null,
                ),
                const SizedBox(width: 8),
                _ActionIconButton(
                  svg: _trashSvg,
                  tooltip: 'Видалити користувача',
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusBadge(String status) {
    switch (status) {
      case 'active':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF83DAF5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Активний',
            style: TextStyle(
              color: Color(0xFF015873),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.14,
              height: 1.4,
            ),
          ),
        );
      case 'inactive':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Неактивний',
            style: TextStyle(
              color: Color(0xFF52525B),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.14,
              height: 1.4,
            ),
          ),
        );
      case 'blocked':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCDC2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Заблокований',
            style: TextStyle(
              color: Color(0xFFB42318),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.14,
              height: 1.4,
            ),
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF83DAF5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Активний',
            style: TextStyle(
              color: Color(0xFF015873),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.14,
              height: 1.4,
            ),
          ),
        );
    }
  }

  String _formatUserDate(dynamic date) {
    if (date == null) return 'Невідомо';
    
    try {
      final dateTime = DateTime.tryParse(date.toString());
      if (dateTime == null) return 'Невідомо';
      
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')} ${dateTime.year}';
    } catch (e) {
      return 'Невідомо';
    }
  }
} 

Future<void> showComplaintDialog({
  required BuildContext context,
  required Map<String, dynamic> complaint,
  VoidCallback? onComplaintProcessed, // New callback for when a complaint is processed
}) async {
  // Отримуємо актуальні дані про оголошення
  final listingId = complaint['listing_id'];
  final userId = complaint['user_id'];
  final supabase = Supabase.instance.client;
  
  // Отримуємо актуальну інформацію про оголошення
  Map<String, dynamic> listing = {};
  try {
    final listingResponse = await supabase
        .from('listings')
        .select('id, title, description, photos, price, is_free, location, created_at, status')
        .eq('id', listingId)
        .single();
    
    listing = listingResponse ?? {};
  } catch (e) {
    print('Error fetching fresh listing data: $e');
    // Якщо не вдалося отримати актуальні дані, використовуємо старі
    listing = complaint['listings'] ?? {};
  }
  
  // Отримуємо дані користувача з profiles
  Map<String, dynamic> userProfile = {};
  try {
    final userResponse = await supabase
        .from('profiles')
        .select('id, first_name, last_name, avatar_url')
        .eq('id', userId)
        .single();
    
    userProfile = userResponse ?? {};
  } catch (e) {
    print('Error fetching user profile data: $e');
    // Якщо не вдалося отримати дані користувача, використовуємо пустий об'єкт
    userProfile = {};
  }
  
  // Get listing fields
  final productName = listing['title'] ?? 'Невідоме оголошення';
  final price = listing['price'];
  final isFree = listing['is_free'] ?? false;
  final location = listing['location'] ?? '';
  final photos = listing['photos'] ?? [];
  
  // Перевіряємо статус оголошення
  final listingStatus = listing['status'] ?? 'active';
  final isListingBlocked = listingStatus == 'blocked';
  
  // Дата створення оголошення (не скарги)
  final listingCreatedAt = listing['created_at'] != null ? DateTime.tryParse(listing['created_at']) : null;
  final listingDate = listingCreatedAt != null ? '${listingCreatedAt.day.toString().padLeft(2, '0')} ${_monthUA(listingCreatedAt.month)} ${listingCreatedAt.hour.toString().padLeft(2, '0')}:${listingCreatedAt.minute.toString().padLeft(2, '0')}' : '';
  
  // Дата створення скарги
  final complaintCreatedAt = complaint['created_at'] != null ? DateTime.tryParse(complaint['created_at']) : null;
  final complaintDate = complaintCreatedAt != null ? '${complaintCreatedAt.day.toString().padLeft(2, '0')} ${_monthUA(complaintCreatedAt.month)} ${complaintCreatedAt.hour.toString().padLeft(2, '0')}:${complaintCreatedAt.minute.toString().padLeft(2, '0')}' : '';
  
  // Створюємо ім'я користувача
  final firstName = userProfile['first_name'] ?? '';
  final lastName = userProfile['last_name'] ?? '';
  final avatarUrl = userProfile['avatar_url'];
  
  String userName;
  if (firstName.isNotEmpty || lastName.isNotEmpty) {
    userName = '${firstName.trim()} ${lastName.trim()}'.trim();
  } else {
    // Fallback до ID якщо немає імені
    userName = 'Користувач ${userId ?? 'Невідомий'}';
  }
  
  final description = complaint['description'] ?? '';
  
  // Логування для перевірки даних
  print('=== showComplaintDialog ===');
  print('Listing ID: $listingId');
  print('User ID: $userId');
  print('Fresh listing data: $listing');
  print('User profile data: $userProfile');
  print('User name: $userName');
  print('Avatar URL: $avatarUrl');
  print('Price: $price, isFree: $isFree');
  print('Location: $location');
  print('Photos: $photos');
  print('Listing status: $listingStatus');
  print('Is listing blocked: $isListingBlocked');
  print('onComplaintProcessed callback: $onComplaintProcessed');

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 390,
            maxWidth: 600,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Заголовок
                    const Text(
                      'Повідомлення про скаргу',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                        color: Colors.black,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Блок оголошення
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: _buildListingImageInDialog(photos),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          productName,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.14,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      if (listingDate.isNotEmpty)
                                        Text(
                                          'Створено: $listingDate',
                                          style: const TextStyle(
                                            color: Color(0xFF838583),
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 0.24,
                                            height: 1.3,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Ціна
                                  if (price != null || isFree)
                                  Row(
                                    children: [
                                        Text(
                                          isFree ? 'Безкоштовно' : '₴${price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Color(0xFF838583),
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 0.24,
                                            height: 1.3,
                                          ),
                                        ),
                                        const Spacer(),
                                      if (location.isNotEmpty)
                                        Text(
                                          location,
                                          style: const TextStyle(
                                              color: Color(0xFF838583),
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                            letterSpacing: 0.24,
                                            height: 1.3,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Користувач
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Користувач',
                          style: TextStyle(
                            color: Color(0xFF52525B),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.14,
                            height: 1.4,
                          ),
                        ),
                        Row(
                          children: [
                            // Фото користувача
                            if (avatarUrl != null && avatarUrl.isNotEmpty)
                              Container(
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey[200],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    avatarUrl,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 20,
                                        color: Colors.grey,
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey[200],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            // Ім'я користувача
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.16,
                            height: 1.5,
                          ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Дата скарги
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Дата скарги',
                          style: TextStyle(
                            color: Color(0xFF52525B),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.14,
                            height: 1.4,
                          ),
                        ),
                        Text(
                          complaintDate,
                          style: const TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Короткий опис
                    const Text(
                      'Короткий опис',
                      style: TextStyle(
                        color: Color(0xFF52525B),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.14,
                        height: 1.4,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Пояснення
                    Text(
                      isListingBlocked 
                        ? 'Оголошення вже заблоковано'
                        : 'По підтвердженню буде блокуватися оголошення і далі ніде не показуватися',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isListingBlocked ? Color(0xFFB42318) : Color(0xFF52525B),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Кнопки
                    if (isListingBlocked)
                      // Якщо оголошення заблоковане - тільки кнопка "Скасувати"
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            shape: const StadiumBorder(),
                            side: const BorderSide(color: Color(0xFFE4E4E7)),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Скасувати',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.16,
                            ),
                          ),
                        ),
                      )
                    else
                      // Якщо оголошення не заблоковане - обидві кнопки
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              shape: const StadiumBorder(),
                              side: const BorderSide(color: Color(0xFFE4E4E7)),
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Скасувати',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                                                          onPressed: () async {
                              print('=== Підтвердити натиснуто ===');
                              print('onComplaintProcessed callback: $onComplaintProcessed');
                              
                              try {
                                // Блокуємо оголошення
                                final supabase = Supabase.instance.client;
                                print('Блокуємо оголошення ${complaint['listing_id']}');
                                await supabase
                                    .from('listings')
                                    .update({'status': 'blocked'})
                                    .eq('id', complaint['listing_id']);
                                
                                // Видаляємо скаргу
                                print('Видаляємо скаргу ${complaint['id']}');
                                await supabase
                                    .from('complaints')
                                    .delete()
                                    .eq('id', complaint['id']);
                                
                                print('Закриваємо попап');
                                // Закриваємо попап
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  print('Попап закрито успішно');
                                } else {
                                  print('Context не mounted, не можемо закрити попап');
                                }
                                
                                print('Викликаємо onComplaintProcessed callback');
                                // Оновлюємо список скарг
                                onComplaintProcessed?.call();
                                
                              } catch (e) {
                                print('Error processing complaint: $e');
                                // Якщо помилка, все одно закриваємо попап
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  print('Попап закрито успішно (після помилки)');
                                }
                                onComplaintProcessed?.call();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              shape: const StadiumBorder(),
                              backgroundColor: const Color(0xFF015873),
                              side: const BorderSide(color: Color(0xFF015873)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Підтвердити',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Кнопка закриття (іконка)
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                      color: Colors.transparent,
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF27272A), size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Функція для відображення фото оголошення в діалозі
Widget _buildListingImageInDialog(List<dynamic> photos) {
  if (photos.isEmpty) {
    return const Icon(Icons.image, size: 32, color: Colors.grey);
  }
  
  final firstPhoto = photos.first;
  if (firstPhoto == null || firstPhoto.toString().isEmpty) {
    return const Icon(Icons.image, size: 32, color: Colors.grey);
  }
  
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      firstPhoto.toString(),
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.image, size: 32, color: Colors.grey);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> showBlockUserDialog({
  required BuildContext context,
  required Function(String reason) onBlock,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return BlockUserDialog(onBlock: onBlock);
    },
  );
}

class BlockUserDialog extends StatefulWidget {
  final Function(String reason) onBlock;
  
  const BlockUserDialog({Key? key, required this.onBlock}) : super(key: key);
  
  @override
  _BlockUserDialogState createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<BlockUserDialog> {
  final TextEditingController reasonController = TextEditingController();
  bool isReasonFilled = false;
  
  @override
  void initState() {
    super.initState();
    reasonController.addListener(() {
      setState(() {
        isReasonFilled = reasonController.text.trim().isNotEmpty;
      });
    });
  }
  
  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 390,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Заблокувати користувача',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                        color: Colors.black,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ви впевнені що бажаєте заблокувати цього користувача?',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Inter',
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),
                  // Поле для введення причини блокування
                  Container(
                    width: double.infinity,
                    height: 160,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Причина',
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
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFAFAFA),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFFE4E4E7),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadows: [
                                BoxShadow(
                                  color: Color(0x0C101828),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                  spreadRadius: 0,
                                )
                              ],
                            ),
                            child: TextField(
                              controller: reasonController,
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                hintText: 'Вкажіть причину блокування користувача',
                                hintStyle: TextStyle(
                                  color: const Color(0xFFA1A1AA),
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                  letterSpacing: 0.16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: const StadiumBorder(),
                              side: const BorderSide(color: Color(0xFFE4E4E7)),
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Скасувати',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                          onPressed: isReasonFilled ? () {
                              Navigator.of(context).pop();
                            widget.onBlock(reasonController.text.trim());
                          } : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: const StadiumBorder(),
                            backgroundColor: isReasonFilled ? const Color(0xFFB42318) : const Color(0xFFD1D5DB),
                            side: BorderSide(color: isReasonFilled ? const Color(0xFFB42318) : const Color(0xFFD1D5DB)),
                              elevation: 0,
                            ),
                          child: Text(
                              'Заблокувати',
                              style: TextStyle(
                              color: isReasonFilled ? Colors.white : const Color(0xFF9CA3AF),
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                      color: Colors.transparent,
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF27272A), size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
  );
  }
}

Future<void> showDeleteUserDialog({
  required BuildContext context,
  required VoidCallback onDelete,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 390,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Видалити користувача',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                        color: Colors.black,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ви впевнені що бажаєте видалити цього користувача? Будуть видалені всі його оголошення та скарги.',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Inter',
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: const StadiumBorder(),
                              side: const BorderSide(color: Color(0xFFE4E4E7)),
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Скасувати',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDelete();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: const StadiumBorder(),
                              backgroundColor: const Color(0xFFB42318),
                              side: const BorderSide(color: Color(0xFFB42318)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Видалити',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                      color: Colors.transparent,
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF27272A), size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _monthUA(int month) {
  const months = [
    '', 'Січня', 'Лютого', 'Березня', 'Квітня', 'Травня', 'Червня',
    'Липня', 'Серпня', 'Вересня', 'Жовтня', 'Листопада', 'Грудня'
  ];
  return months[month];
} 