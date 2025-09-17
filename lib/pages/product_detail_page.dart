import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../pages/edit_listing_page_new.dart';
import '../widgets/blocked_user_bottom_sheet.dart';
import '../widgets/success_bottom_sheet.dart'; // Import the new success bottom sheet
import 'full_screen_image_slider_page.dart'; // Import the new full screen image slider page

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
  final TextEditingController _complaintDescriptionController = TextEditingController(); // Add this line
  // Додаємо стан для показу інпуту повідомлення
  bool _showMessageInput = false;
  final TextEditingController _messageController = TextEditingController();
  bool _sendingMessage = false;
  final MapController _mapController = MapController();
  // Floating chat button positioning (adjust as needed)
  double _chatButtonBottomOffset = 56;
  double _chatButtonHorizontalOffset = 25;
  bool _chatButtonAlignRight = true;

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

  String _getCustomAttributeDisplayName(String attributeName) {
    switch (attributeName) {
      // Загальні
      case 'condition':
        return 'Стан';
      case 'warranty':
        return 'Гарантія';
      case 'delivery':
        return 'Доставка';
      case 'payment':
        return 'Оплата';
      // Авто
      case 'year':
        return 'Рік випуску';
      case 'car_brand':
        return 'Марка авто';
      case 'engine_power':
        return 'Двигун (к.с.)';
      case 'mileage':
        return 'Пробіг (км)';
      case 'fuel_type':
        return 'Тип палива';
      case 'transmission':
        return 'Коробка передач';
      case 'body_type':
        return 'Тип кузова';
      case 'color':
        return 'Колір';
      // Нерухомість
      case 'area':
        return 'Площа (м²)';
      case 'rooms':
        return 'Кількість кімнат';
      case 'floor':
        return 'Поверх';
      case 'total_floors':
        return 'Всього поверхів';
      case 'property_type':
        return 'Тип нерухомості';
      case 'renovation':
        return 'Ремонт';
      case 'furniture':
        return 'Меблі';
      case 'balcony':
        return 'Балкон';
      case 'parking':
        return 'Парковка';
      // Електроніка
      case 'model':
        return 'Модель';
      case 'memory':
        return 'Пам\'ять';
      case 'storage':
        return 'Накопичувач';
      case 'processor':
        return 'Процесор';
      case 'screen_size':
        return 'Розмір екрану';
      case 'battery':
        return 'Батарея';
      // Одяг
      case 'size':
        return 'Розмір';
      case 'material':
        return 'Матеріал';
      case 'season':
        return 'Сезон';
      case 'style':
        return 'Стиль';
      case 'gender':
        return 'Стать';
      // Знайомства
      case 'age':
        return 'Вік';
      default:
        return attributeName.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
    }
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
    _complaintDescriptionController.dispose(); // Add this line
    _messageController.dispose();
    super.dispose();
  }

  void _showComplaint() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (context) => ComplaintBottomSheet(
        onSubmit: _submitComplaint,
        onClose: _hideComplaint,
        initialType: _selectedComplaintType,
        descriptionController: _complaintDescriptionController,
      ),
    );
  }

  void _hideComplaint() {
    Navigator.of(context).pop();
      _complaintDescriptionController.clear();
      _selectedComplaintType = 'Товар не відповідає опису';
  }

  Future<void> _submitComplaint() async {
    if (_currentUserId == null) {
      return;
    }

    // if (_complaintTitleController.text.isEmpty) {
    //   return;
    // }

    if (_complaintDescriptionController.text.isEmpty) {
      return;
    }

    try {
      await _complaintService.createComplaint(
        listingId: widget.productId,
        title: _product!.title,
        description: _complaintDescriptionController.text,
        types: [_selectedComplaintType],
      );
      
      if (mounted) {
        Navigator.of(context).pop(); // Close the complaint bottom sheet
        _showSuccessBottomSheet(); // Show the success bottom sheet
      }
    } catch (e) {
      if (mounted) {
        // Error submitting complaint (optional: show error snackbar)

      }
    }
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) => SuccessBottomSheet(
        title: 'Скаргу надіслано',
        message: 'Дякуємо за вашу скаргу! Ми розглянемо її якнайшвидше.',
        onClose: () {
          Navigator.of(context).pop(); // Close the success bottom sheet
        },
      ),
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

  Widget _buildContactItem(String iconPath, String text, {required bool isSocialIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: isSocialIcon ? null : const ColorFilter.mode(Color(0xFFA1A1AA), BlendMode.srcIn),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Скопійовано в буфер обміну'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(width: 7),
                Icon(
                  Icons.copy,
                  size: 20,
                  color: const Color(0xFFA1A1AA),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
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
              onChanged: (_) => setState(() {}              ),
            ),
          ),
          const SizedBox(height: 8),
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
                                  child: const CircularProgressIndicator(),
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
          if (_product != null && (_currentUserId == null || _currentUserId != _product!.userId))
            Positioned(
              left: _chatButtonAlignRight ? null : _chatButtonHorizontalOffset,
              right: _chatButtonAlignRight ? _chatButtonHorizontalOffset : null,
              bottom: _chatButtonBottomOffset + MediaQuery.of(context).padding.bottom,
              child: GestureDetector(
                onTap: _currentUserId == null ? null : _startChatWithOwner,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: const Color(0xFF015873),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                            color: Color(0xFF015873),
                          ),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: SvgPicture.asset(
                              'assets/icons/message-circle-01.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Чат',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.50,
                              letterSpacing: 0.16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(double imageHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // First section - Image gallery
          SizedBox(
            height: imageHeight,
            child: Stack(
              children: [
                // Image gallery
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageSliderPage(
                          imageUrls: _product!.photos,
                          initialIndex: _currentPage,
                        ),
                      ),
                    );
                  },
                  child: PageView.builder(
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
                ),
                // Navigation buttons
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 36),
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
                              iconPath: "assets/icons/upload-01.svg",
                              onTap: () async {
                                if (_product != null) {
                                  try {
                                    final productUrl = 'https://your-app-url.com/product/${_product!.id}';
                                    await Share.share(
                                      'Подивіться на це оголошення: ${_product!.title} - ${_product!.formattedPrice}\n$productUrl'
                                    );
                                    
                                  } catch (e) {
                                    
                                  }
                                } else {
                                  
                                }
                              },
                            ),
                            // Показуємо кнопку редагування тільки якщо це наше оголошення
                            if (_currentUserId != null && _product != null && _currentUserId == _product!.userId) ...[
                              const SizedBox(width: 12), // 12px gap
                              GestureDetector(
                                onTap: () async {
                                  if (_product != null) {
                                    final result = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => EditListingPageNew(listing: _product!.toListing()),
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
                          ],
                        ),
                      ],
                    ),
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
                        child: Builder(
                          builder: (context) {
                            final total = _product!.photos.length;
                            int start = 0;
                            int count = total;
                            if (total > 3) {
                              if (_currentPage <= 0) {
                                start = 0;
                              } else if (_currentPage >= total - 1) {
                                start = total - 3;
                              } else {
                                start = _currentPage - 1;
                              }
                              count = 3;
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(count, (i) {
                                final dotIndex = start + i;
                                final isActive = dotIndex == _currentPage;
                                return Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive
                                        ? const Color(0xFF015873)
                                        : Colors.white.withOpacity(0.25),
                                  ),
                                );
                              }),
                            );
                          },
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
                        // Categories and Negotiable Tag
                        Wrap(
                          spacing: 6.0, // Gap between tags
                          runSpacing: 6.0, // Gap between rows of tags
                          children: [
                            // Category Tag
                            if (_categoryName != null && _categoryName!.isNotEmpty)
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
                                  _categoryName!,
                                  style: const TextStyle(
                                    color: Color(0xFF015873),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.43,
                                  ),
                                ),
                              ),
                            // Subcategory Tag
                            if (_subcategoryName != null && _subcategoryName!.isNotEmpty)
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
                                  _subcategoryName!,
                                  style: const TextStyle(
                                    color: Color(0xFF52525B),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.43,
                                  ),
                                ),
                              ),
                            // Negotiable Tag
                            if (_product!.isNegotiable == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(16),
                                  // border: Border.all(color: const Color(0xFFE4E4E7)),
                                ),
                                child: const Text(
                                  'Договірна',
                                  style: TextStyle(
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
                  _buildCustomAttributesSection(),
                  // Location block (address, map)
                  if (_product!.address != null && _product!.address!.isNotEmpty)
                    GestureDetector(
                      onTap: () => _launchMapsUrl(_product!.latitude, _product!.longitude),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/addresssdv.svg',
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_product!.address!)),
                          ],
                        ),
                      ),
                    ),
                  if (_product!.latitude != null && _product!.longitude != null) ...[
                    SizedBox(
                      height: 180,
                      child: GestureDetector(
                        onTap: () => _launchMapsUrl(_product!.latitude, _product!.longitude),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                center: LatLng(_product!.latitude!, _product!.longitude!),
                                zoom: 14,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.pinchZoom,
                                ),
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
                            // Кнопки керування картою
                            Positioned(
                              right: 16,
                              top: 16,
                              child: Column(
                                children: [
                                  // Кнопка збільшення
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE4E4E7)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: () {
                                        _mapController.move(_mapController.center, _mapController.zoom + 1);
                                      },
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Кнопка зменшення
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE4E4E7)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: () {
                                        _mapController.move(_mapController.center, _mapController.zoom - 1);
                                      },
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
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
                            // Показуємо кнопку скарги тільки якщо це не наше оголошення
                            if (_currentUserId != null && _product != null && _currentUserId != _product!.userId)
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
                              child: _userProfile?.avatarUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _userProfile!.avatarUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person,
                                            size: 24,
                                            color: Color(0xFF71717A),
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
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
                  const SizedBox(height: 8),
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
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Contacts group (WhatsApp, Telegram, Viber, Phone)
                          if (_product?.whatsapp != null && _product!.whatsapp!.isNotEmpty ||
                              _product?.telegram != null && _product!.telegram!.isNotEmpty ||
                              _product?.viber != null && _product!.viber!.isNotEmpty ||
                              _product?.phoneNumber != null && _product!.phoneNumber!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                // WhatsApp contact
                                if (_product?.whatsapp != null && _product!.whatsapp!.isNotEmpty)
                                  _buildContactItem(
                                      'assets/icons/whatsapp.svg',
                                    _product!.whatsapp!,
                                    isSocialIcon: true,
                                  ),
                                // Telegram contact
                                if (_product?.telegram != null && _product!.telegram!.isNotEmpty)
                                  _buildContactItem(
                                      'assets/icons/telegram.svg',
                                    _product!.telegram!,
                                    isSocialIcon: true,
                                  ),
                                // Viber contact
                                if (_product?.viber != null && _product!.viber!.isNotEmpty)
                                  _buildContactItem(
                                      'assets/icons/viber.svg',
                                    _product!.viber!,
                                    isSocialIcon: true,
                                  ),
                                // Phone contact
                                if (_product?.phoneNumber != null && _product!.phoneNumber!.isNotEmpty)
                                  _buildContactItem(
                                      'assets/icons/phone.svg',
                                    _product!.phoneNumber!,
                                    isSocialIcon: false,
                              ),
                              ],
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

        ],
      ),
    );
  }

  Widget _buildCustomAttributesSection() {
    if (_product?.customAttributes == null || _product!.customAttributes!.isEmpty) {
      return const SizedBox.shrink();
    }

    final attributes = _product!.customAttributes!;
    final attributeWidgets = <Widget>[];

    attributes.forEach((key, value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        String displayValue;
        if (value is Map && value.containsKey('min') && value.containsKey('max')) {
          final min = value['min'];
          final max = value['max'];
          if (min != null && max != null) {
            displayValue = 'від $min до $max';
          } else if (min != null) {
            displayValue = 'від $min';
          } else if (max != null) {
            displayValue = 'до $max';
          } else {
            return;
          }
        } else {
          displayValue = value.toString();
        }

        attributeWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getCustomAttributeDisplayName(key),
                style: const TextStyle(
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
                displayValue,
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
        );
        attributeWidgets.add(const SizedBox(height: 24));
      }
    });

    if (attributeWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attributeWidgets,
    );
  }

  void _launchMapsUrl(double? lat, double? lon) async {
    if (lat == null || lon == null) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      
    }
  }

  Widget _buildComplaintOverlay() {
    return GestureDetector(
      onTap: _hideComplaint,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Empty for now since we're using showModalBottomSheet
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

  void _navigateToChatDialog(String? chatId) {
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
} 

class ComplaintDialog extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String description, String type) onSubmit; // Updated signature
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
  late TextEditingController _descriptionController;
  late String _selectedType;
  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _selectedType = widget.initialType;
  }
  @override
  void dispose() {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
      ),
    );
  }
} 

class ComplaintBottomSheet extends StatefulWidget {
  final VoidCallback onSubmit;
  final VoidCallback onClose;
  final String initialType;
  final TextEditingController descriptionController;

  const ComplaintBottomSheet({
    super.key,
    required this.onSubmit,
    required this.onClose,
    required this.initialType,
    required this.descriptionController,
  });

  @override
  State<ComplaintBottomSheet> createState() => _ComplaintBottomSheetState();
}

class _ComplaintBottomSheetState extends State<ComplaintBottomSheet> {
  late String _selectedComplaintType;

  @override
  void initState() {
    super.initState();
    _selectedComplaintType = widget.initialType;
    
    // Додаємо слухачі для оновлення стану кнопки
    widget.descriptionController.addListener(() {
      setState(() {});
    });
  }

  bool get _isFormValid {
    return widget.descriptionController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.descriptionController.removeListener(() {});
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E4E7),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
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
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE4E4E7)),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Тип скарги',
                        style: TextStyle(
                          color: Color(0xFF52525B),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: 0.14,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Опис скарги',
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
                        controller: widget.descriptionController,
                        maxLines: 5,
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
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isFormValid ? widget.onSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid 
                            ? const Color(0xFF015873)
                            : const Color(0xFFF4F4F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(200),
                        ),
                      ),
                      child: Text(
                        'Надіслати скаргу',
                        style: TextStyle(
                          color: _isFormValid ? Colors.white : Colors.black,
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