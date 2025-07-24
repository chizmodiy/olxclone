import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedTab = 0; // 0 - Оголошення, 1 - Скарги, 2 - Користувачі
  bool _showMenu = false;

  final List<String> _tabs = ['Оголошення', 'Скарги', 'Користувачі'];

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
                                              child: TextField(
                                                decoration: InputDecoration(
                                                  hintText: 'Пошук',
                                                  border: InputBorder.none,
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
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: const [
                                        SizedBox(width: 120, child: Text('Назва', style: TextStyle(fontWeight: FontWeight.w600))),
                                        Expanded(flex: 2, child: Text('Опис', style: TextStyle(fontWeight: FontWeight.w600))),
                                        SizedBox(width: 90, child: Text('Дата', style: TextStyle(fontWeight: FontWeight.w600))),
                                        SizedBox(width: 90, child: Text('Ціна', style: TextStyle(fontWeight: FontWeight.w600))),
                                        SizedBox(width: 100, child: Text('Локація', style: TextStyle(fontWeight: FontWeight.w600))),
                                        SizedBox(width: 100, child: Text('Категорія', style: TextStyle(fontWeight: FontWeight.w600))),
                                        SizedBox(width: 90, child: Text('Статус', style: TextStyle(fontWeight: FontWeight.w600))),
                                        SizedBox(width: 40), // Для іконки видалення
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
                                  // Рядки з даними
                                  ..._mockAds.map((ad) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: [
                                        // Назва + зображення
                                        SizedBox(
                                          width: 120,
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(ad['image'], width: 40, height: 40, fit: BoxFit.cover),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(ad['title'], maxLines: 2, overflow: TextOverflow.ellipsis),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Опис
                                        Expanded(
                                          flex: 2,
                                          child: Text(ad['desc'], maxLines: 2, overflow: TextOverflow.ellipsis),
                                        ),
                                        // Дата
                                        SizedBox(
                                          width: 90,
                                          child: Text(ad['date']),
                                        ),
                                        // Ціна
                                        SizedBox(
                                          width: 90,
                                          child: Text(ad['price']),
                                        ),
                                        // Локація
                                        SizedBox(
                                          width: 100,
                                          child: Text(ad['location'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        // Категорія
                                        SizedBox(
                                          width: 100,
                                          child: Text(ad['category'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        // Статус
                                        SizedBox(
                                          width: 90,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: ad['status'] == 'active' ? const Color(0xFFB6E6F2) : const Color(0xFFE4E4E7),
                                                borderRadius: BorderRadius.circular(100),
                                              ),
                                              child: Text(
                                                ad['status'] == 'active' ? 'Активний' : 'Неактивний',
                                                style: TextStyle(
                                                  color: ad['status'] == 'active' ? const Color(0xFF015873) : const Color(0xFF52525B),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Дія (видалення)
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
                                  )),
                                  const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
                                  // Пагінація
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Сторінка 1 із 10', style: TextStyle(fontSize: 14)),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.chevron_left),
                                              onPressed: () {},
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.chevron_right),
                                              onPressed: () {},
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
}

// Додаю мок-дані для оголошень
final List<Map<String, dynamic>> _mockAds = [
  {
    'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
    'title': 'Нова повсякденна сукня',
    'desc': 'XL, біла, 100% бавовна',
    'date': '12.05 16:00',
    'price': '₴290.00',
    'location': 'Харків',
    'category': 'Одяг',
    'status': 'active',
  },
  {
    'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
    'title': 'Худі, нове',
    'desc': 'Легка, дихаюча тканина',
    'date': '12.05 16:00',
    'price': '€12.00',
    'location': 'Київ',
    'category': 'Одяг',
    'status': 'inactive',
  },
  {
    'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
    'title': 'Футболка, біла, брендова',
    'desc': 'Тонкий дизайн із зручним кроєм',
    'date': '12.05 16:00',
    'price': '₴290.00',
    'location': 'Харків',
    'category': 'Одяг',
    'status': 'inactive',
  },
  {
    'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
    'title': 'Кросівки, Нові',
    'desc': 'Легка, дихаюча тканина',
    'date': '12.05 16:00',
    'price': '₴290.00',
    'location': 'Миколаїв',
    'category': 'Взуття',
    'status': 'active',
  },
  {
    'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
    'title': 'Шкіряний гаманець',
    'desc': 'Тонкий дизайн із захистом RFID',
    'date': '12.05 16:00',
    'price': '₴290.00',
    'location': 'Львів',
    'category': 'Аксесуари',
    'status': 'active',
  },
  {
    'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
    'title': 'Кросівки для бігу',
    'desc': 'Легка, дихаюча тканина',
    'date': '12.05 16:00',
    'price': '₴290.00',
    'location': 'Харків',
    'category': 'Взуття',
    'status': 'inactive',
  },
  {
    'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
    'title': 'Навушники Bluetooth',
    'desc': 'Шумопоглинаючі, з кейсом',
    'date': '12.05 16:00',
    'price': '₴290.00',
    'location': 'Харків',
    'category': 'Електроніка',
    'status': 'inactive',
  },
  {
    'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
    'title': 'Павербанк',
    'desc': '10000 mah, type-c',
    'date': '12.05 16:00',
    'price': '₴290.00',
    'location': 'Харків',
    'category': 'Електроніка',
    'status': 'inactive',
  },
]; 