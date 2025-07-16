import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import './active_listings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF52525B),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.16,
            height: 1.5,
          ),
        ),
      );

  Widget _profileButton({
    required String text,
    required VoidCallback onTap,
  }) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0x10102828),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.16,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black, size: 20),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(127),
        child: Container(
          width: double.infinity,
          height: 127,
          padding: const EdgeInsets.fromLTRB(13, 16, 13, 8),
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 13,
                bottom: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: SvgPicture.asset(
                    'assets/icons/chevron-states.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.grey[300],
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 13, right: 13, top: 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Головне
            _sectionTitle('Головне'),
            _profileButton(
              text: 'Особисті данні',
              onTap: () {},
            ),
            _profileButton(
              text: 'Вийти з облікового запису',
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
            _profileButton(
              text: 'Видалити обліковий запис',
              onTap: () {},
            ),
            const SizedBox(height: 20),
            // (Аватар між блоками видалено)
            const SizedBox(height: 20),
            // Мої оголошення
            _sectionTitle('Мої оголошення'),
            _profileButton(
              text: 'Активні',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ActiveListingsPage()),
                );
              },
            ),
            _profileButton(
              text: 'Неактивні',
              onTap: () {},
            ),
            _profileButton(
              text: 'Улюблені оголошення',
              onTap: () {},
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
} 