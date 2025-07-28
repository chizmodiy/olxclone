import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/common_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool isBuyerSelected = true; // За замовчуванням 'Купую'

  String? _currentUserId;
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadChats();
  }

  Future<void> _loadChats() async {
        setState(() {
      _loading = true;
    });
    final client = Supabase.instance.client;
    // 1. Отримати всі chat_participants для поточного користувача
    final participants = await client
        .from('chat_participants')
        .select('chat_id, user_id, joined_at')
        .eq('user_id', _currentUserId);
    final chatIds = participants.map((p) => p['chat_id'] as String).toList();
    if (chatIds.isEmpty) {
      setState(() {
        _chats = [];
        _loading = false;
      });
      return;
    }
    // 2. Отримати всі чати за цими chat_id
    final chats = await client
        .from('chats')
        .select('*')
        .in_('id', chatIds);
    // 3. Для кожного чату отримати учасників, останнє повідомлення, оголошення, співрозмовника
    List<Map<String, dynamic>> chatCards = [];
    for (final chat in chats) {
      // Отримати учасників чату
      final chatParticipants = await client
          .from('chat_participants')
          .select('user_id, joined_at')
          .eq('chat_id', chat['id']);
      // Визначити ініціатора (хто перший приєднався)
      chatParticipants.sort((a, b) => (a['joined_at'] as String).compareTo(b['joined_at'] as String));
      final initiatorId = chatParticipants.first['user_id'] as String;
      final isBuyer = initiatorId == _currentUserId;
      // Фільтрація за перемикачем
      if (isBuyerSelected && !isBuyer) continue;
      if (!isBuyerSelected && isBuyer) continue;
      // Знайти співрозмовника
      final otherUser = chatParticipants.firstWhere((p) => p['user_id'] != _currentUserId, orElse: () => null);
      String otherUserId = otherUser != null ? otherUser['user_id'] as String : '';
      // Отримати профіль співрозмовника
      Map<String, dynamic>? otherProfile;
      if (otherUserId.isNotEmpty) {
        otherProfile = await client
            .from('profiles')
            .select('first_name, last_name')
            .eq('id', otherUserId)
            .maybeSingle();
      }
      // Отримати останнє повідомлення
      final lastMsgList = await client
          .from('chat_messages')
          .select('*')
          .eq('chat_id', chat['id'])
          .order('created_at', ascending: false)
          .limit(1);
      final lastMsg = lastMsgList.isNotEmpty ? lastMsgList.first : null;
      // Отримати кількість непрочитаних
      final unreadCount = await client
          .from('chat_messages')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('chat_id', chat['id'])
          .eq('is_read', false)
          .neq('sender_id', _currentUserId);
      // Отримати оголошення (listing)
      // Припустимо, що в chat є поле listing_id
      String? listingId = chat['listing_id'] as String?;
      Map<String, dynamic>? listing;
      if (listingId != null) {
        final listingList = await client
            .from('listings')
            .select('title, photos')
            .eq('id', listingId)
            .limit(1);
        if (listingList.isNotEmpty) {
          listing = listingList.first;
        }
      }
      chatCards.add({
        'chatId': chat['id'],
        'listingTitle': listing?['title'] ?? 'Оголошення',
        'imageUrl': (listing?['photos'] != null && (listing?['photos'] as List).isNotEmpty)
            ? (listing?['photos'] as List).first
            : 'https://placehold.co/92x92',
        'userName': (otherProfile != null)
            ? ((otherProfile['first_name'] ?? '') + ' ' + (otherProfile['last_name'] ?? ''))
            : 'Користувач',
        'lastMessage': lastMsg != null ? (lastMsg['content'] ?? '[Фото]') : '',
        'time': lastMsg != null ? (lastMsg['created_at'] as String).substring(11, 16) : '',
        'unreadCount': unreadCount.count ?? 0,
      });
    }
    setState(() {
      _chats = chatCards;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonHeader(),
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 13, right: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Чат',
              style: TextStyle(
                color: Color(0xFF161817),
                fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            ChatTypeSwitch(
              isBuyerSelected: isBuyerSelected,
              onChanged: (value) {
                      setState(() {
                  isBuyerSelected = value;
                });
                _loadChats();
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _currentUserId == null
                      ? Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(top: 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Content
                                  Column(
                                    children: [
                                      // Featured icon with message
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.zinc100,
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: AppColors.zinc50,
                                            width: 8,
                                          ),
                                        ),
                                        child: Center(
                                          child: SvgPicture.asset(
                                            'assets/icons/message-circle-01.svg',
                                            width: 24,
                                            height: 24,
                                            colorFilter: const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Text content
                                      Column(
                                        children: [
                                          Text(
                                            'Обмінюйтесь повідомленями',
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.heading1Semibold.copyWith(
                                              color: Colors.black,
                                              fontSize: 24,
                                              height: 28.8 / 24,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Увійдіть або створіть профіль для обміну повідомленнями з іншими користувачами нашої платформи.',
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.body1Regular.copyWith(
                                              color: AppColors.color7,
                                              height: 22.4 / 16,
                                              letterSpacing: 0.16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 40),
                                  // Buttons
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pushNamed('/auth');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(200),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                            elevation: 0,
                                            shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
                                          ),
                                          child: Text(
                                            'Увійти',
                                            style: AppTextStyles.body1Medium.copyWith(
                                              color: Colors.white,
                                              letterSpacing: 0.16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(context).pushNamed('/auth');
                                          },
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            side: const BorderSide(color: AppColors.zinc200, width: 1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(200),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                            elevation: 0,
                                            shadowColor: const Color.fromRGBO(16, 24, 40, 0.05),
                                          ),
                                          child: Text(
                                            'Створити акаунт',
                                            style: AppTextStyles.body1Medium.copyWith(
                                              color: Colors.black,
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
                            const Spacer(),
                          ],
                        )
                      : _chats.isEmpty
                          ? Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              child: Container(
                                                width: 52,
                                                height: 52,
                                                decoration: const ShapeDecoration(
                                                  color: Color(0xFFFAFAFA),
                                                  shape: OvalBorder(),
                                                ),
                                              ),
                                            ),
                                            const Positioned(
                                              left: 14,
                                              top: 14,
                                              child: Icon(
                                                Icons.chat_bubble_outline,
                                                size: 24,
                                                color: Color(0xFF52525B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        width: double.infinity,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: const Text(
                                                'Немає повідомлень',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Color(0xFF667084),
                                                  fontSize: 16,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.40,
                                                  letterSpacing: 0.16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                              ],
                            )
                      : ListView.separated(
                          itemCount: _chats.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 20),
                          itemBuilder: (context, index) {
                            final chat = _chats[index];
                            return ChatCard(
                              imageUrl: chat['imageUrl'],
                              listingTitle: chat['listingTitle'],
                              userName: chat['userName'],
                              lastMessage: chat['lastMessage'],
                              time: chat['time'],
                              unreadCount: chat['unreadCount'],
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChatDialogPage(
                                      chatId: chat['chatId'] ?? '',
                                      userName: chat['userName'] ?? '',
                                      userAvatarUrl: chat['userAvatarUrl'] ?? '',
                                      listingTitle: chat['listingTitle'] ?? '',
                                      listingImageUrl: chat['imageUrl'] ?? '',
                                      listingPrice: chat['listingPrice'] ?? '',
                                      listingDate: chat['listingDate'] ?? '',
                                      listingLocation: chat['listingLocation'] ?? '',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatTypeSwitch extends StatelessWidget {
  final bool isBuyerSelected;
  final ValueChanged<bool> onChanged;

  const ChatTypeSwitch({
    super.key,
    required this.isBuyerSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: const Color(0xFFF4F4F5),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            color: Color(0xFFFAFAFA),
          ),
          borderRadius: BorderRadius.circular(200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: ShapeDecoration(
                  color: isBuyerSelected ? Colors.white : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: isBuyerSelected ? const Color(0xFFE4E4E7) : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(200),
                  ),
                  shadows: isBuyerSelected
                      ? [
                          const BoxShadow(
                            color: Color(0x0C101828),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                            spreadRadius: 0,
                          )
                        ]
                      : [],
                ),
                child: const Center(
                  child: Text(
                    'Купую',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                      letterSpacing: 0.14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: ShapeDecoration(
                  color: !isBuyerSelected ? Colors.white : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: !isBuyerSelected ? const Color(0xFFE4E4E7) : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(200),
                  ),
                  shadows: !isBuyerSelected
                      ? [
                          const BoxShadow(
                            color: Color(0x0C101828),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                            spreadRadius: 0,
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Продаю',
                    style: TextStyle(
                      color: !isBuyerSelected ? Colors.black : Color(0xFF71717A),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                      letterSpacing: 0.14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Додаю компонент ChatCard
class ChatCard extends StatelessWidget {
  final String imageUrl;
  final String listingTitle;
  final String userName;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final VoidCallback? onTap;

  const ChatCard({
    super.key,
    required this.imageUrl,
    required this.listingTitle,
    required this.userName,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: const Color(0xFFFAFAFA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                listingTitle,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  height: 1.40,
                                  letterSpacing: 0.14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: const TextStyle(
                                color: Color(0xFF52525B),
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                height: 1.30,
                                letterSpacing: 0.24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.30,
                            letterSpacing: 0.24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessage,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  height: 1.43,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF83DAF5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF015873),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.50,
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChatDialogPage extends StatefulWidget {
  final String chatId;
  final String userName;
  final String userAvatarUrl;
  final String listingTitle;
  final String listingImageUrl;
  final String listingPrice;
  final String listingDate;
  final String listingLocation;

  const ChatDialogPage({
    super.key,
    required this.chatId,
    required this.userName,
    required this.userAvatarUrl,
    required this.listingTitle,
    required this.listingImageUrl,
    required this.listingPrice,
    required this.listingDate,
    required this.listingLocation,
  });

  @override
  State<ChatDialogPage> createState() => _ChatDialogPageState();
}

class _ChatDialogPageState extends State<ChatDialogPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _currentUserId;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadMessages();
    _subscribeToNewMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;
    final messages = await client
        .from('chat_messages')
        .select('*')
        .eq('chat_id', widget.chatId)
        .order('created_at', ascending: false)
        .limit(30);
    setState(() {
      _messages = List<Map<String, dynamic>>.from(messages.reversed);
      _loading = false;
    });
    _scrollToBottom();
    await _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null) return;
    final client = Supabase.instance.client;
    await client
        .from('chat_messages')
        .update({'is_read': true})
        .eq('chat_id', widget.chatId)
        .eq('is_read', false)
        .neq('sender_id', _currentUserId);
  }

  void _subscribeToNewMessages() {
    final client = Supabase.instance.client;
    _realtimeChannel = client.channel('public:chat_messages')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'chat_messages',
          filter: 'chat_id=eq.${widget.chatId}',
        ),
        (payload, [ref]) {
                        setState(() {
            _messages.add(payload['new'] as Map<String, dynamic>);
          });
          _scrollToBottom();
        },
      )
      ..subscribe();
  }

  void _scrollToBottom() {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    // Pick an image
    final XFile? imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );

    if (imageFile == null || _currentUserId == null) {
      return;
    }

    final client = Supabase.instance.client;
    final imageExtension = imageFile.name.split('.').last.toLowerCase();
    final imageBytes = await imageFile.readAsBytes();
    final imagePath =
        '$_currentUserId/${DateTime.now().millisecondsSinceEpoch}.$imageExtension';

    try {
      await client.storage.from('chat_images').uploadBinary(
            imagePath,
            imageBytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: imageFile.mimeType,
            ),
          );

      final imageUrl =
          client.storage.from('chat_images').getPublicUrl(imagePath);
      await _sendMessage(imageUrl: imageUrl);
    } catch (e) {
      // ignore: avoid_print
      print('!!!!!!!!!!!!!!!!! SUPABASE STORAGE ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка завантаження фото: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _textController.text.trim();
    if ((text.isEmpty && imageUrl == null) || _currentUserId == null) return;

    final client = Supabase.instance.client;

    final messageData = {
      'chat_id': widget.chatId,
      'sender_id': _currentUserId,
      'content': text.isNotEmpty ? text : null,
      'image_url': imageUrl,
    };

    final response =
        await client.from('chat_messages').insert(messageData).select().single();

    if (imageUrl == null) {
    _textController.clear();
    }

    // Додаємо повідомлення одразу після відправки
    setState(() {
      _messages.add({
        'chat_id': widget.chatId,
        'sender_id': _currentUserId,
        'content': text.isNotEmpty ? text : null,
        'image_url': imageUrl,
        'created_at':
            response['created_at'] ?? DateTime.now().toIso8601String(),
        // додай інші потрібні поля, якщо треба
      });
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ChatAppBar(
          userName: widget.userName,
          userAvatarUrl: widget.userAvatarUrl,
          onBack: () => Navigator.of(context).pop(),
          onMenu: () {},
        ),
      ),
      body: Column(
            children: [
          ChatListingCard(
            imageUrl: widget.listingImageUrl,
            title: widget.listingTitle,
            price: widget.listingPrice,
            date: widget.listingDate,
            location: widget.listingLocation,
          ),
          // Видалити Divider над полем для введення повідомлення
          // const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(top: 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 52,
                                            height: 52,
                                            decoration: const ShapeDecoration(
                                              color: Color(0xFFFAFAFA),
                                              shape: OvalBorder(),
                                            ),
                                          ),
                                        ),
                                        const Positioned(
                                          left: 14,
                                          top: 14,
                                          child: Icon(
                                            Icons.chat_bubble_outline,
                                            size: 24,
                                            color: Color(0xFF52525B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: const Text(
                                            'Немає повідомлень',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Color(0xFF667084),
                                              fontSize: 16,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                              height: 1.40,
                                              letterSpacing: 0.16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                    color: Color(0xFFFAFAFA),
                    child: ListView.builder(
                      key: ValueKey(_messages.length),
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 13),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['sender_id'] == _currentUserId;
                        final senderName = isMe ? 'Ви' : widget.userName;
                        final senderAvatarUrl = isMe ? null : widget.userAvatarUrl;
                        final text = msg['content'] as String?;
                        final imageUrl = msg['image_url'] as String?;
                        final createdAt = DateTime.tryParse(msg['created_at'] ?? '') ?? DateTime.now();
                        final time = '${_weekdayName(createdAt.weekday)} ${createdAt.hour.toString().padLeft(2, '0')}.${createdAt.minute.toString().padLeft(2, '0')}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: MessageBubble(
                            isMe: isMe,
                            senderName: senderName,
                            senderAvatarUrl: senderAvatarUrl,
                            text: text,
                            imageUrl: imageUrl,
                            time: time,
                          ),
                        );
                      },
                    ),
                  ),
          ),
          // Прибрати Divider або border в самому низу сторінки відкритого чату
          // const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 36, top: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Поле введення з іконкою фото
                Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                      color: Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        child: Row(
                          children: [
                        IconButton(
                          icon: const Icon(Icons.photo, color: Color(0xFF52525B)),
                          onPressed: _pickAndUploadImage,
                          splashRadius: 20,
                        ),
                            Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Написати повідомлення',
                              hintStyle: TextStyle(
                                color: Color(0xFFA1A1AA),
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                height: 1.5,
                                  letterSpacing: 0.16,
                                ),
                              border: InputBorder.none,
                              ),
                            minLines: 1,
                            maxLines: 4,
                            ),
                        ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(width: 12),
                // Кнопка відправки: прибрати border
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF015873),
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(),
                    splashRadius: 24,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayName(int weekday) {
    const names = [
      '',
      'Понеділок',
      'Вівторок',
      'Середа',
      'Четвер',
      'Пʼятниця',
      'Субота',
      'Неділя',
    ];
    return names[weekday];
  }
}

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String senderName;
  final String? senderAvatarUrl;
  final String? text;
  final String? imageUrl;
  final String time;

  const MessageBubble({
    super.key,
    required this.isMe,
    required this.senderName,
    this.senderAvatarUrl,
    this.text,
    this.imageUrl,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? const Color(0xFF015873) : const Color(0xFFF4F4F5);
    final textColor = isMe ? Colors.white : Colors.black;
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: senderAvatarUrl != null && senderAvatarUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(senderAvatarUrl!),
                    )
                  : const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE4E4E7),
                      child: Icon(Icons.person, color: Color(0xFF71717A)),
                    ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? 'Ви' : senderName,
                      style: const TextStyle(
                        color: Color(0xFF344054),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF52525B),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        letterSpacing: 0.24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (text != null)
                  Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                        minWidth: 0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: borderRadius,
                        ),
                        child: Text(
                          text!,
                          style: TextStyle(
                            color: textColor,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                    ),
                  ),
                ),
                if (imageUrl != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                      minWidth: 0,
                    ),
                    child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: borderRadius,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl!,
                        height: 200,
                        fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String userAvatarUrl;
  final VoidCallback onBack;
  final VoidCallback? onMenu;

  const ChatAppBar({
    super.key,
    required this.userName,
    required this.userAvatarUrl,
    required this.onBack,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left, size: 28, color: Colors.black),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(10),
                  shape: const CircleBorder(),
                  backgroundColor: Colors.transparent,
                ),
              ),
              // Avatar and name
              Expanded(
                child: Row(
                  children: [
                    // Avatar
                    userAvatarUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(userAvatarUrl),
                          )
                        : const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFE4E4E7),
                            child: Icon(Icons.person, color: Color(0xFF71717A)),
                          ),
                    const SizedBox(width: 8),
                    // Name
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: Colors.black,
                          letterSpacing: 0.14,
                          height: 1.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu button
              IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.more_vert, color: Colors.black),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(10),
                  shape: const CircleBorder(),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class ChatListingCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String date;
  final String location;

  const ChatListingCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.date,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: Color(0xFFE4E4E7)),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Фото оголошення або заглушка (без заокруглень)
              imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      color: Color(0xFFED3131),
                      child: Icon(Icons.image, color: Colors.white),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500, // medium
                              height: 1.4,
                              letterSpacing: 0.14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Color(0xFF838583),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                            letterSpacing: 0.24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            price,
                            style: const TextStyle(
                              color: Color(0xFF52525B),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500, // medium
                              height: 1.3,
                              letterSpacing: 0.24,
                            ),
                          ),
                        ),
                        Text(
                          location,
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500, // medium
                            height: 1.3,
                            letterSpacing: 0.24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: Color(0xFFE4E4E7)),
      ],
    );
  }
} 