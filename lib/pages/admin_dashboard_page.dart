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
      
      // Підрахунок загальної кількості сторінок
    final countResp = await Supabase.instance.client
        .from('listings')
        .select('id', const FetchOptions(count: CountOption.exact));
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
    setState(() => _isLoadingComplaints = true);
    try {
      final complaints = await _complaintService.getComplaints();
      setState(() {
        _complaints = complaints;
        _isLoadingComplaints = false;
      });
    } catch (e) {
      setState(() => _isLoadingComplaints = false);
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
          // TODO: Далі контент сторінки відповідно до _selectedTab
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
                                  const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
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
                                              const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
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
                                            Expanded(flex: 2, child: Text('Назва', style: TextStyle(fontWeight: FontWeight.w600))),
                                            Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
                                            Expanded(flex: 2, child: Text('Номер телефону', style: TextStyle(fontWeight: FontWeight.w600))),
                                            Expanded(flex: 2, child: Text('Дата', style: TextStyle(fontWeight: FontWeight.w600))),
                                            Expanded(flex: 2, child: Text('Статус', style: TextStyle(fontWeight: FontWeight.w600))),
                                            SizedBox(width: 80), // Для іконок дій
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
                                      // Рядки з реальними даними (без скролу)
                                      _isLoadingProducts
                                          ? const Expanded(child: Center(child: CircularProgressIndicator()))
                                          : Expanded(
                                              child: Column(
                                                children: [
                                                  // Реальні дані з бази
                                                  if (_isLoadingComplaints)
                                                    const Expanded(child: Center(child: CircularProgressIndicator()))
                                                  else
                                                    for (final complaint in _complaints.take(8))
                                                      ComplaintTableRow(
                                                        complaint: complaint,
                                                        onViewDetails: () {
                                                          showComplaintDialog(context: context, complaint: complaint);
                                                        },
                                                      ),
                                                  const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
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
                                                Expanded(flex: 2, child: Text('Номер телефону', style: TextStyle(fontWeight: FontWeight.w600))),
                                                Expanded(flex: 2, child: Text('Дата', style: TextStyle(fontWeight: FontWeight.w600))),
                                                Expanded(flex: 2, child: Text('Статус', style: TextStyle(fontWeight: FontWeight.w600))),
                                                SizedBox(width: 80), // Для іконок дій
                                              ],
                                            ),
                                          ),
                                          const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
                                          // Рядки з реальними даними (без скролу)
                                          _isLoadingUsers
                                              ? const Expanded(child: Center(child: CircularProgressIndicator()))
                                              : Expanded(
                                                  child: Column(
                                                    children: [
                                                      for (final user in _users.take(8))
                                                        UserTableRow(
                                                          user: user,
                                                          onBlock: () async {
                                                            await showBlockUserDialog(
                                                              context: context,
                                                              onBlock: () async {
                                                                await _userService.blockUser(user['id']);
                                                                await _fetchUsers();
                                                              },
                                                            );
                                                          },
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
                                                      const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
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
                tooltip: 'Заблокувати',
                onTap: () {
                  // Поки що без дії
                },
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
                        print('Початок видалення оголошення ${ad.id}');
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
    final userName = complaint['profiles']?['full_name'] ?? 'Невідомий користувач';
    final productName = complaint['listings']?['title'] ?? 'Невідоме оголошення';
    final description = complaint['description'] ?? '';
    
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAECF0), width: 1)),
      ),
      child: Row(
        children: [
          // Користувач
          Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                SvgPicture.string(
                  _userIconSvg,
            width: 40,
                  height: 40,
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
                SvgPicture.string(
                  _productIconSvg,
                  width: 40,
                  height: 40,
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
                  onTap: () => showComplaintDialog(context: context, complaint: complaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Віджет для рядка користувача
class UserTableRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onBlock;
  final VoidCallback? onDelete;
  
  const UserTableRow({
    Key? key, 
    required this.user, 
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
          // Дата (поки що пуста, бо немає created_at)
          Expanded(
            flex: 2,
            child: Container(
              width: 160,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                '-',
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
                  tooltip: 'Заблокувати користувача',
                  onTap: onBlock,
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
} 

Future<void> showComplaintDialog({
  required BuildContext context,
  required Map<String, dynamic> complaint,
}) async {
  final listing = complaint['listings'] ?? {};
  final user = complaint['profiles'] ?? {};
  final imageUrl = listing['image_url'] as String?;
  final productName = listing['title'] ?? 'Невідоме оголошення';
  final createdAt = complaint['created_at'] != null ? DateTime.tryParse(complaint['created_at']) : null;
  final price = listing['price'] != null ? '₴${listing['price']}' : '';
  final location = listing['location'] ?? '';
  final userName = user['full_name'] ?? 'Невідомий користувач';
  final complaintDate = createdAt != null ? '${createdAt.day.toString().padLeft(2, '0')} ${_monthUA(createdAt.month)} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}' : '';
  final description = complaint['description'] ?? '';

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
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 32, color: Colors.grey)),
                                  )
                                : const Icon(Icons.image, size: 32, color: Colors.grey),
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
                                      if (complaintDate.isNotEmpty)
                                        Text(
                                          complaintDate,
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
                                  Row(
                                    children: [
                                      if (price.isNotEmpty)
                                        Text(
                                          price,
                                          style: const TextStyle(
                                            color: Color(0xFF52525B),
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.24,
                                            height: 1.3,
                                          ),
                                        ),
                                      const SizedBox(width: 16),
                                      if (location.isNotEmpty)
                                        Text(
                                          location,
                                          style: const TextStyle(
                                            color: Color(0xFFA1A1AA),
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
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
                    const SizedBox(height: 8),
                    // Дата
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Дата',
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
                    const Text(
                      'По підтвердженню буде блокуватися оголошення і далі ніде не показуватися',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF52525B),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Кнопки
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
                              // TODO: Додати логіку блокування оголошення
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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

Future<void> showBlockUserDialog({
  required BuildContext context,
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
                              onBlock();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: const StadiumBorder(),
                              backgroundColor: const Color(0xFFB42318),
                              side: const BorderSide(color: Color(0xFFB42318)),
                              elevation: 0,
                            ),
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