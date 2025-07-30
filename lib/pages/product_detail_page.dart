import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/profile_service.dart';
import '../services/complaint_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'chat_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../pages/edit_listing_page_fixed.dart';
import '../widgets/blocked_user_bottom_sheet.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final PageController _pageController;
  late final ProductService _productService;
  late final CategoryService _categoryService;
  late final ProfileService _profileService;
  late final ComplaintService _complaintService;
  int _currentPage = 0;
  Product? _product;
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;
  String? _categoryName;
  String? _subcategoryName;
  String? _currentUserId;
  bool _isFavorite = false;
  String _activeContactMethod = 'phone'; // 'phone', 'whatsapp', 'telegram', 'viber', 'message'
  bool _showComplaintDialog = false; // Add this line
  String _selectedComplaintType = 'Товар не відповідає опису'; // Add this line
  final TextEditingController _complaintTitleController = TextEditingController(); // Add this line
  final TextEditingController _complaintDescriptionController = TextEditingController(); // Add this line
  // Додаємо стан для показу інпуту повідомлення
  bool _showMessageInput = false;
  final TextEditingController _messageController = TextEditingController();
  bool _sendingMessage = false;

  // Мапа категорій
  final Map<String, String> _categories = {
    '066e2754-e51c-4395-9e3f-f78503444704': 'Знайомства',
    '0eb7b6db-e505-4503-8bc0-020914a3ebcf': 'Бізнес та послуги',
    '261d5661-f4c6-408e-b1f3-8d9a04f68081': 'Тварини',
    '2b33ab6e-94b3-4268-b8b8-5c23d7ba2d2b': 'Оренда та прокат',
    '30934dd8-8fb3-4e24-91a4-6cf137bd7412': 'Дім і сад',
    '3d668ce4-969f-49ad-96c2-7152c2184567': 'Робота',
    '63ca90d1-6735-4fff-b469-94f325b99900': 'Авто',
    '7065bc9d-d34f-4394-9a08-e8da1f8c6a98': 'Нерухомість',
    '7515a738-62eb-4a8b-bcfd-872a10a72e25': 'Віддам безкоштовно',
    '85e264dd-3456-42a8-a6ca-6123e2a07d40': 'Житло подобово',
    '90d34cdb-7617-4b17-8106-9c94d802f812': 'Мода і стиль',
    'c785ac08-c2f0-4766-af8d-0b09cb0c3d94': 'Запчастини для транспорту',
    'cce00594-36b9-482b-b21f-43818155de2b': 'Хобі, відпочинок і спорт',
    'cf21cd87-d2e6-45d2-bea3-d68931ca5f97': 'Електроніка',
    'e34417la-a607-4fc3-b6e9-7ad049c1fdc5': 'Допомога',
    'ffa87acb-45fb-42b3-bfc6-00609ec6e879': 'Дитячий світ',
  };

  // Мапа підкатегорій
  final Map<String, String> _subcategories = {
    'women_clothing': 'Жіночий одяг',
    'men_clothing': 'Чоловічий одяг',
    'phones': 'Телефони',
    'computers': 'Комп\'ютери',
    'furniture': 'Меблі',
    // Додайте інші підкатегорії за потреби
  };

  String _getCategoryName(String categoryId) {
    return _categories[categoryId] ?? 'Інше';
  }

  String _getSubcategoryName(String subcategoryId) {
    return _subcategories[subcategoryId] ?? 'Інше';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _productService = ProductService();
    _categoryService = CategoryService();
    _profileService = ProfileService();
    _complaintService = ComplaintService(Supabase.instance.client);
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadProduct();
    _loadFavoriteStatus();
    
    // Перевіряємо статус користувача після завантаження
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_currentUserId != null) {
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

  Future<void> _loadProduct() async {
    try {
      setState(() => _isLoading = true);
      final product = await _productService.getProductById(widget.productId);
      final categoryName = await _categoryService.getCategoryNameCached(product.categoryId);
      final subcategoryName = await _categoryService.getSubcategoryNameCached(product.subcategoryId);
      final userProfile = await _profileService.getUser(product.userId);
      
      setState(() {
        _product = product;
        _userProfile = userProfile;
        _categoryName = categoryName;
        _subcategoryName = subcategoryName;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    if (_currentUserId == null) return;
    try {
      final favoriteIds = await _profileService.getFavoriteProductIds();
      setState(() {
        _isFavorite = favoriteIds.contains(widget.productId);
      });
    } catch (e) {
      // Error loading favorite status
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUserId == null) {
      return;
    }

    try {
      if (_isFavorite) {
        await _profileService.removeFavoriteProduct(widget.productId);
      } else {
        await _profileService.addFavoriteProduct(widget.productId);
      }
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      // Error toggling favorite
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _complaintTitleController.dispose(); // Add this line
    _complaintDescriptionController.dispose(); // Add this line
    _messageController.dispose();
    super.dispose();
  }

  void _showComplaint() {
    setState(() {
      _showComplaintDialog = true;
    });
  }

  void _hideComplaint() {
    setState(() {
      _showComplaintDialog = false;
      _complaintTitleController.clear();
      _complaintDescriptionController.clear();
      _selectedComplaintType = 'Товар не відповідає опису';
    });
  }

  Future<void> _submitComplaint() async {
    if (_currentUserId == null) {
      return;
    }

    if (_complaintTitleController.text.isEmpty) {
      return;
    }

    if (_complaintDescriptionController.text.isEmpty) {
      return;
    }

    try {
      await _complaintService.createComplaint(
        listingId: widget.productId,
        title: _complaintTitleController.text,
        description: _complaintDescriptionController.text,
        types: [_selectedComplaintType],
      );
      
      _hideComplaint();
    } catch (e) {
      // Error submitting complaint
    }
  }

  Widget _buildComplaintDialog() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E7),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Повідомити про проблему',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Опишіть проблему яку ви зустріли з цим продавцем',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _hideComplaint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Назва товару',
                      style: TextStyle(
                        color: Color(0xFF52525B),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: 0.14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _complaintTitleController,
                      decoration: InputDecoration(
                        hintText: 'Введіть назву товару',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          letterSpacing: 0.16,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(200),
                          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(200),
                          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(200),
                          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0.16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE4E4E7)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildComplaintTypeChip('Товар не відповідає опису'),
                    _buildComplaintTypeChip('Не отримав товар'),
                    _buildComplaintTypeChip('Продавець не відповідав'),
                    _buildComplaintTypeChip('Проблема з оплатою'),
                    _buildComplaintTypeChip('Неналежна поведінка'),
                    _buildComplaintTypeChip('Інше'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Опис',
                        style: TextStyle(
                          color: Color(0xFF52525B),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: 0.14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: TextField(
                          controller: _complaintDescriptionController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: 'Опишіть свою скаргу',
                            alignLabelWithHint: false,
                            hintStyle: const TextStyle(
                              color: Color(0xFFA1A1AA),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              letterSpacing: 0.16,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                            ),
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            letterSpacing: 0.16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _submitComplaint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF015873),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(200),
                      ),
                    ),
                    child: const Text(
                      'Надіслати скаргу',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _hideComplaint,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(200),
                      ),
                    ),
                    child: const Text(
                      'Скасувати',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintTypeChip(String type) {
    final isSelected = _selectedComplaintType == type;
    return ChoiceChip(
      label: Text(
        type,
        style: TextStyle(
          color: isSelected ? Colors.black : const Color(0xFF52525B),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedComplaintType = type;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFF4F4F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(200),
        side: BorderSide(
          color: isSelected ? const Color(0xFFF4F4F5) : const Color(0xFFE4E4E7),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    );
  }

  Widget _buildContactButton(
    String type,
    String iconPath,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    final bool isSocialIcon = type == 'whatsapp' || type == 'telegram' || type == 'viber';
    final bool isActive = _activeContactMethod == type;
    
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF015873) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(200),
        border: Border.all(
          color: isActive ? const Color(0xFF015873) : const Color(0xFFF4F4F5),
        ),
      ),
      child: IconButton(
        icon: SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
          colorFilter: isSocialIcon 
              ? null 
              : ColorFilter.mode(
                  isActive ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
        ),
        onPressed: () {
          setState(() {
            _activeContactMethod = type;
            _showMessageInput = type == 'message';
          });
        },
      ),
    );
  }

  Widget _buildContactInfo(String iconPath, String text) {
    bool isSocialIcon = false;
    if (iconPath.contains('whatsapp') || iconPath.contains('telegram') || iconPath.contains('viber')) {
      isSocialIcon = true;
    }
    
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 24,
          height: 24,
          colorFilter: isSocialIcon ? null : const ColorFilter.mode(Color(0xFFA1A1AA), BlendMode.srcIn),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: 0.16,
          ),
        ),
      ],
    );
  }

  void _handleContactPress(String method) {
    setState(() {
      _activeContactMethod = method;
    });
  }

  Widget _buildUserInfo() {
    if (_userProfile == null) {
      return const Text(
        'Завантаження...',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          height: 1.5,
          letterSpacing: 0.16,
        ),
      );
    }

    return Text(
      _userProfile!.fullName,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0.16,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Повідомлення',
            style: TextStyle(
              color: Color(0xFF52525B),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: 0.14,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE4E4E7)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(16, 24, 40, 0.05),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Опишіть ваше повідомлення тут',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Color(0xFFA1A1AA),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  letterSpacing: 0.16,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _messageController.text.trim().isEmpty || _sendingMessage
                  ? null
                  : _sendFirstMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF015873),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: Color(0xFF015873), width: 1),
                ),
                elevation: 4,
                shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
              ),
              child: _sendingMessage
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Написати',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        height: 1.4,
                        letterSpacing: 0.14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFirstMessage() async {
    if (_currentUserId == null || _product == null || _userProfile == null) return;
    setState(() => _sendingMessage = true);
    final ownerId = _product!.userId;
    final client = Supabase.instance.client;
    String? chatId;
    // 1. Перевірити, чи вже існує чат між цими двома користувачами по цьому оголошенню
    final existingChats = await client
        .from('chats')
        .select('id')
        .eq('listing_id', _product!.id);
    if (existingChats.isNotEmpty) {
      // Перевірити, чи обидва користувачі є учасниками
      for (final chat in existingChats) {
        final participants = await client
            .from('chat_participants')
            .select('user_id')
            .eq('chat_id', chat['id']);
        final userIds = participants.map((p) => p['user_id'] as String).toSet();
        if (userIds.contains(_currentUserId) && userIds.contains(ownerId)) {
          chatId = chat['id'] as String;
          break;
        }
      }
    }
    if (chatId == null) {
      // Створити новий чат
      final chatInsert = await client
          .from('chats')
          .insert({
            'is_group': false,
            'listing_id': _product!.id,
          })
          .select()
          .single();
      chatId = chatInsert['id'] as String;
      // Додати обох учасників
      await client.from('chat_participants').insert([
        {
          'chat_id': chatId,
          'user_id': _currentUserId,
        },
        {
          'chat_id': chatId,
          'user_id': ownerId,
        },
      ]);
    }
    // Відправити перше повідомлення
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      await client.from('chat_messages').insert({
        'chat_id': chatId,
        'sender_id': _currentUserId,
        'content': text,
      });
    }
    setState(() => _sendingMessage = false);
    _messageController.clear();
    setState(() => _showMessageInput = false);
    // Перейти на сторінку чату
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDialogPage(
          chatId: chatId!,
          userName: _userProfile!.fullName,
          userAvatarUrl: _userProfile!.avatarUrl ?? '',
          listingTitle: _product!.title,
          listingImageUrl: _product!.photos.isNotEmpty ? _product!.photos.first : '',
          listingPrice: _product!.formattedPrice,
          listingDate: _product!.formattedDate,
          listingLocation: _product!.location,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageHeight = size.height * 0.35;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Помилка: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProduct,
                child: const Text('Спробувати знову'),
              ),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Товар не знайдено'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildMainContent(imageHeight),
          if (_showComplaintDialog) ComplaintDialog(
            onClose: _hideComplaint,
            onSubmit: (title, description, type) => _submitComplaintWithData(title, description, type),
            initialType: _selectedComplaintType,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(double imageHeight) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // First section - Image gallery
          SizedBox(
            height: imageHeight,
            child: Stack(
              children: [
                // Image gallery
                PageView.builder(
                  controller: _pageController,
                  itemCount: _product!.photos.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imageWidget = CachedNetworkImage(
                      imageUrl: _product!.photos[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                    if (index == 0) {
                      return Hero(
                        tag: 'product-photo-${_product!.id}',
                        child: imageWidget,
                      );
                    }
                    return imageWidget;
                  },
                ),
                // Navigation buttons
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavigationButton(
                        iconPath: 'assets/icons/chevron-states.svg',
                        onTap: () => Navigator.pop(context),
                      ),
                      Row( // Group share and edit buttons
                        children: [
                          _buildNavigationButton(
                            iconPath: 'assets/icons/share-07.svg',
                            onTap: () {
                              // Share functionality coming soon
                            },
                          ),
                          const SizedBox(width: 12), // 12px gap
                          GestureDetector(
                            onTap: () async {
                              if (_product != null) {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditListingPage(listing: _product!.toListing()),
                                  ),
                                );
                                
                                // Якщо редагування було успішним, оновлюємо дані
                                if (result == true) {
                                  setState(() {
                                    // Оновлюємо дані продукту
                                    _loadProduct();
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1,
                                    color: Color(0xFFE4E4E7),
                                  ),
                                  borderRadius: BorderRadius.circular(200),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x0C101828),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  )
                                ],
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/edit-0333.svg',
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Page indicators
                if (_product!.photos.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 30,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: ShapeDecoration(
                          color: Colors.black.withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ...List.generate(_product!.photos.length > 3 ? 3 : _product!.photos.length, (index) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: ShapeDecoration(
                                  color: _currentPage == index 
                                    ? const Color(0xFF015873) 
                                    : Colors.white.withOpacity(0.25),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)
                                  ),
                                ),
                              );
                            }),
                            if (_product!.photos.length > 3)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                child: Text(
                                  "...",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    height: 0.8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Second section - Content
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 20, 14, 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        Text(
                          _product!.formattedDate,
                          style: const TextStyle(
                            color: Color(0xFF838583),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                            letterSpacing: 0.24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Title and Price with Favorite button
                        SizedBox(
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(right: 48),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _product!.title,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        height: 1.5,
                                        letterSpacing: 0.16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _product!.formattedPrice,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 24,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Favorite button
                              Positioned(
                                right: 0,
                                top: 9,
                                child: GestureDetector(
                                  onTap: _toggleFavorite,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F4F5),
                                      borderRadius: BorderRadius.circular(200),
                                      border: Border.all(
                                        color: const Color(0xFFF4F4F5),
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Icon(
                                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                                        size: 20,
                                        color: _isFavorite ? const Color(0xFF015873) : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Categories
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF83DAF5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _categoryName ?? 'Інше',
                                style: const TextStyle(
                                  color: Color(0xFF015873),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  height: 1.43,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _subcategoryName ?? 'Інше',
                                style: const TextStyle(
                                  color: Color(0xFF52525B),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  height: 1.43,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Description section
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Опис',
                          style: TextStyle(
                            color: Color(0xFF52525B),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            letterSpacing: 0.14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _product!.description ?? 'Опис відсутній',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            letterSpacing: 0.16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Location block (address, region, map)
                  if (_product!.address != null && _product!.address!.isNotEmpty) ...[
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/addresssdv.svg',
                          width: 22,
                          height: 22,
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text(_product!.address!)),
                      ],
                    ),
                    SizedBox(height: 4),
                  ],
                  if (_product!.region != null && _product!.region!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 30.0, bottom: 8),
                      child: Text(
                        _product!.region!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                  if (_product!.latitude != null && _product!.longitude != null) ...[
                    SizedBox(
                      height: 180,
                      child: FlutterMap(
                        options: MapOptions(
                          center: LatLng(_product!.latitude!, _product!.longitude!),
                          zoom: 14,
                          interactiveFlags: InteractiveFlag.none,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 40,
                                height: 40,
                                point: LatLng(_product!.latitude!, _product!.longitude!),
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  
                  // User section
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                height: 1.4,
                                letterSpacing: 0.14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(200),
                              ),
                              child: TextButton(
                                onPressed: _showComplaint,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Icon(
                                  Icons.flag_outlined,
                                  size: 20,
                                  color: Color(0xFF27272A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(240),
                                color: const Color(0xFFE4E4E7),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 24,
                                color: Color(0xFF71717A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildUserInfo(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Contacts section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Контакти',
                        style: TextStyle(
                          color: Color(0xFF52525B),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: 0.14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Contact buttons row
                          Row(
                            children: [
                                                                              // WhatsApp button
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildContactButton(
                                      'whatsapp',
                                      'assets/icons/whatsapp.svg',
                                      () => _handleContactPress('whatsapp'),
                                      isPrimary: _activeContactMethod == 'whatsapp',
                                    ),
                                  ),
                                  // Telegram button
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildContactButton(
                                      'telegram',
                                      'assets/icons/telegram.svg',
                                      () => _handleContactPress('telegram'),
                                      isPrimary: _activeContactMethod == 'telegram',
                                    ),
                                  ),
                                  // Viber button
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildContactButton(
                                      'viber',
                                      'assets/icons/viber.svg',
                                      () => _handleContactPress('viber'),
                                      isPrimary: _activeContactMethod == 'viber',
                                    ),
                                  ),
                                  // Phone button
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildContactButton(
                                      'phone',
                                      'assets/icons/phone.svg',
                                      () => _handleContactPress('phone'),
                                      isPrimary: _activeContactMethod == 'phone',
                                    ),
                                  ),
                                  // Message button
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildContactButton(
                                      'message',
                                      'assets/icons/message-circle-01.svg',
                                      () => setState(() => _showMessageInput = true),
                                      isPrimary: _activeContactMethod == 'message',
                                    ),
                                  ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Contact info display
                          if (_activeContactMethod == 'message' && _showMessageInput)
                            _buildMessageInput(),
                          if (_activeContactMethod != 'message')
                            if (_activeContactMethod == 'phone')
                              _buildContactInfo(
                                'assets/icons/phone.svg',
                                _product?.phoneNumber ?? 'Відсутнє',
                              ),
                            if (_activeContactMethod == 'whatsapp')
                              _buildContactInfo(
                                'assets/icons/whatsapp.svg',
                                _product?.whatsapp ?? 'Відсутнє',
                              ),
                            if (_activeContactMethod == 'telegram')
                              _buildContactInfo(
                                'assets/icons/telegram.svg',
                                _product?.telegram ?? 'Відсутнє',
                              ),
                            if (_activeContactMethod == 'viber')
                              _buildContactInfo(
                                'assets/icons/viber.svg',
                                _product?.viber ?? 'Відсутнє',
                              ),
                        ],
                      ),
                    ],
                  ),
                  if (_showMessageInput) _buildMessageInput(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _startChatWithOwner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF015873),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(color: Color(0xFF015873), width: 1),
                  ),
                  elevation: 4,
                  shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
                ),
                child: const Text(
                  'Написати',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    height: 1.4,
                    letterSpacing: 0.14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintOverlay() {
    return GestureDetector(
      onTap: _hideComplaint,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {}, // Prevent tap through
              child: _buildComplaintDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: Color(0xFFE4E4E7),
            ),
            borderRadius: BorderRadius.circular(200),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x0C101828),
              blurRadius: 2,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
        ),
      ),
    );
  }

  Future<void> _startChatWithOwner() async {
    if (_currentUserId == null || _product == null || _userProfile == null) return;
    final ownerId = _product!.userId;
    if (ownerId == _currentUserId) {
      return;
    }
    final client = Supabase.instance.client;
    // 1. Перевірити, чи вже існує чат між цими двома користувачами по цьому оголошенню
    final existingChats = await client
        .from('chats')
        .select('id')
        .eq('listing_id', _product!.id);
    String? chatId;
    if (existingChats.isNotEmpty) {
      // Перевірити, чи обидва користувачі є учасниками
      for (final chat in existingChats) {
        final participants = await client
            .from('chat_participants')
            .select('user_id')
            .eq('chat_id', chat['id']);
        final userIds = participants.map((p) => p['user_id'] as String).toSet();
        if (userIds.contains(_currentUserId) && userIds.contains(ownerId)) {
          chatId = chat['id'] as String;
          break;
        }
      }
    }
    if (chatId == null) {
      // Створити новий чат
      final chatInsert = await client
          .from('chats')
          .insert({
            'is_group': false,
            'listing_id': _product!.id,
          })
          .select()
          .single();
      chatId = chatInsert['id'] as String;
      // Додати обох учасників
      await client.from('chat_participants').insert([
        {
          'chat_id': chatId,
          'user_id': _currentUserId,
        },
        {
          'chat_id': chatId,
          'user_id': ownerId,
        },
      ]);
    }
    // Перейти на сторінку чату, передавши всі потрібні дані
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDialogPage(
          chatId: chatId!,
          userName: _userProfile!.fullName,
          userAvatarUrl: _userProfile!.avatarUrl ?? '',
          listingTitle: _product!.title,
          listingImageUrl: _product!.photos.isNotEmpty ? _product!.photos.first : '',
          listingPrice: _product!.formattedPrice,
          listingDate: _product!.formattedDate,
          listingLocation: _product!.location,
        ),
      ),
    );
  }

  void _submitComplaintWithData(String title, String description, String type) {
    if (_currentUserId == null) {
      return;
    }

    if (title.isEmpty) {
      return;
    }

    if (description.isEmpty) {
      return;
    }

    try {
      _complaintService.createComplaint(
        listingId: widget.productId,
        title: title,
        description: description,
        types: [type],
      );
      
      _hideComplaint();
    } catch (e) {
      // Error submitting complaint
    }
  }
} 

class ComplaintDialog extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String title, String description, String type) onSubmit;
  final String initialType;
  const ComplaintDialog({
    super.key,
    required this.onClose,
    required this.onSubmit,
    required this.initialType,
  });
  @override
  State<ComplaintDialog> createState() => _ComplaintDialogState();
}
class _ComplaintDialogState extends State<ComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedType;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedType = widget.initialType;
  }
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E4E7),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Повідомити про проблему',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Опишіть проблему яку ви зустріли з цим продавцем',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Назва товару',
                    style: TextStyle(
                      color: Color(0xFF52525B),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      letterSpacing: 0.14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введіть назву товару';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Введіть назву товару',
                      hintStyle: const TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0.16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(200),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(200),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(200),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      letterSpacing: 0.16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE4E4E7)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in [
                        'Товар не відповідає опису',
                        'Не отримав товар',
                        'Продавець не відповідав',
                        'Проблема з оплатою',
                        'Неналежна поведінка',
                        'Інше',
                      ])
                        ChoiceChip(
                          label: Text(type),
                          selected: _selectedType == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = type;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Опис',
                          style: TextStyle(
                            color: Color(0xFF52525B),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            letterSpacing: 0.14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: TextFormField(
                            controller: _descriptionController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введіть опис скарги';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Опишіть свою скаргу',
                              alignLabelWithHint: false,
                              hintStyle: const TextStyle(
                                color: Color(0xFFA1A1AA),
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                                letterSpacing: 0.16,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFAFAFA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              letterSpacing: 0.16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onSubmit(
                            _titleController.text,
                            _descriptionController.text,
                            _selectedType,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF015873),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(200),
                        ),
                      ),
                      child: const Text(
                        'Надіслати скаргу',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE4E4E7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(200),
                        ),
                      ),
                      child: const Text(
                        'Скасувати',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 