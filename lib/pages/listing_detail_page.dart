import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/complaint_modal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../pages/edit_listing_page_new.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';

class ListingDetailPage extends StatefulWidget {
  final String listingId;

  const ListingDetailPage({
    super.key,
    required this.listingId,
  });

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  late Future<Listing> _listingFuture;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadListing();
    
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

  void _loadListing() {
    final listingService = ListingService(Supabase.instance.client);
    _listingFuture = listingService.getListingById(widget.listingId);
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

  void _showComplaintModal(Listing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ComplaintModal(
          productId: listing.id,
          productTitle: listing.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Деталі оголошення'),
        actions: [
          FutureBuilder<Listing>(
            future: _listingFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Редагувати',
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditListingPageNew(listing: snapshot.data!),
                          ),
                        );
                        
                        // Якщо редагування було успішним, оновлюємо дані
                        if (result == true) {
                          setState(() {
                            // Оновлюємо Future для перезавантаження даних
                            _loadListing();
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.flag_outlined),
                      onPressed: () => _showComplaintModal(snapshot.data!),
                      tooltip: 'Поскаржитись',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Listing>(
        future: _listingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Помилка: ${snapshot.error}',
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.notificationDotColor),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Оголошення не знайдено'),
            );
          }

          final listing = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (listing.photos.isNotEmpty)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(listing.photos.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  listing.title,
                  style: AppTextStyles.heading1Semibold,
                ),
                const SizedBox(height: 8),
                  Text(
                  listing.formattedPrice,
                    style: AppTextStyles.heading2Semibold.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  listing.description,
                  style: AppTextStyles.body1Regular,
                ),
                const SizedBox(height: 16),
                // Локація
                if (listing.location.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          listing.location,
                          style: AppTextStyles.body1Regular.copyWith(
                            color: AppColors.color2,
                          ),
                        ),
                      ),
                    ],
                  ),

                if (listing.phoneNumber != null)
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(listing.phoneNumber!),
                    onTap: () {/* TODO: Add phone call functionality */},
                  ),
                if (listing.whatsapp != null)
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.whatsapp),
                    title: Text(listing.whatsapp!),
                    onTap: () {/* TODO: Add WhatsApp functionality */},
                  ),
                if (listing.telegram != null)
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.telegram),
                    title: Text(listing.telegram!),
                    onTap: () {/* TODO: Add Telegram functionality */},
                  ),
                if (listing.viber != null)
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.viber),
                    title: Text(listing.viber!),
                    onTap: () {/* TODO: Add Viber functionality */},
                  ),
                const SizedBox(height: 16),
                // Користувач
                Text(
                  'Користувач',
                  style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.zinc100,
                      child: Icon(
                        Icons.person,
                        color: AppColors.color5,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Користувач', // TODO: Замінити на реальне ім'я користувача
                      style: AppTextStyles.body1Medium.copyWith(color: AppColors.color2),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 