import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import 'dart:async';

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
  List<Product> _products = [];
  bool _isLoadingProducts = false;
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _pageSize = 8;

  final CategoryService _categoryService = CategoryService();
  final Map<String, String> _categoryNameCache = {};

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    final products = await _productService.getProducts(
      limit: _pageSize,
      offset: (_currentPage - 1) * _pageSize,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    // Підрахунок загальної кількості сторінок (отримуємо count окремо)
    final countResp = await Supabase.instance.client
        .from('listings')
        .select('id', const FetchOptions(count: CountOption.exact));
    final totalCount = countResp.count ?? products.length;
    setState(() {
      _products = products;
      _isLoadingProducts = false;
      _totalPages = (totalCount / _pageSize).ceil().clamp(1, 9999);
    });
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final initials = _getInitials(user?.email ?? '');
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
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
                                  onTap: () async {
                                    await Supabase.instance.client.auth.signOut();
                                    if (context.mounted) {
                                      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
                                    }
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
                                              padding: EdgeInsets.symmetric(horizontal: 12),
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
                                                    hintStyle: TextStyle(
                                                      color: Color(0xFFA1A1AA),
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w400,
                                                      fontFamily: 'Inter',
                                                      letterSpacing: 0.16,
                                                    ),
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
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
                              constraints: const BoxConstraints(
                                minHeight: 80 + 8 * 64 + 56, // заголовки + 8 рядків + пагінація
                                maxHeight: 80 + 8 * 64 + 56,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
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
                                  Expanded(
                                    child: _isLoadingProducts
                                        ? const Center(child: CircularProgressIndicator())
                                        : Column(
                                            children: [
                                              for (final ad in _products)
                                                Padding(
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
                                                        child: Text(_formatDate(ad.createdAt)),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(_formatPrice(ad)),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(ad.location ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: FutureBuilder<String>(
                                                          future: _getCategoryName(ad.categoryId),
                                                          builder: (context, snapshot) {
                                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                                              return const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2));
                                                            }
                                                            return Text(snapshot.data ?? '', maxLines: 1, overflow: TextOverflow.ellipsis);
                                                          },
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Align(
                                                          alignment: Alignment.centerLeft,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: (ad.customAttributes?['status'] ?? 'active') == 'active' ? const Color(0xFFB6E6F2) : const Color(0xFFE4E4E7),
                                                              borderRadius: BorderRadius.circular(100),
                                                            ),
                                                            child: Text(
                                                              (ad.customAttributes?['status'] ?? 'active') == 'active' ? 'Активний' : 'Неактивний',
                                                              style: TextStyle(
                                                                color: (ad.customAttributes?['status'] ?? 'active') == 'active' ? const Color(0xFF015873) : const Color(0xFF52525B),
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 40,
                                                        child: IconButton(
                                                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEB5757)),
                                                          onPressed: () {},
                                                          tooltip: 'Видалити',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
                                              const Spacer(),
                                            ],
                                          ),
                                  ),
                                  // Пагінація (завжди внизу)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Сторінка $_currentPage із $_totalPages', style: const TextStyle(fontSize: 14)),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.chevron_left),
                                              onPressed: _currentPage > 1 ? () => _onPageChanged(_currentPage - 1) : null,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.chevron_right),
                                              onPressed: _currentPage < _totalPages ? () => _onPageChanged(_currentPage + 1) : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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