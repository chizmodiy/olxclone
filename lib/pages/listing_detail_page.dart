import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/complaint_modal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  void _loadListing() {
    final listingService = ListingService(Supabase.instance.client);
    _listingFuture = listingService.getListingById(widget.listingId);
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
                return IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  onPressed: () => _showComplaintModal(snapshot.data!),
                  tooltip: 'Поскаржитись',
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
            padding: const EdgeInsets.all(16),
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
                if (listing.price != null)
                  Text(
                    '${listing.price} ${listing.currency}',
                    style: AppTextStyles.heading2Semibold.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  )
                else
                  Text(
                    'Безкоштовно',
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
                Text(
                  'Місцезнаходження: ${listing.location}',
                  style: AppTextStyles.body2Regular,
                ),
                const SizedBox(height: 8),
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
              ],
            ),
          );
        },
      ),
    );
  }
} 