import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class RegionSelectionPage extends StatefulWidget {
  const RegionSelectionPage({Key? key}) : super(key: key);

  @override
  State<RegionSelectionPage> createState() => _RegionSelectionPageState();
}

class _RegionSelectionPageState extends State<RegionSelectionPage> {
  final List<Category> _regions = [
    Category(id: 'kyiv', name: 'Київ'),
    Category(id: 'kyiv_oblast', name: 'Київська область'),
    Category(id: 'kharkiv', name: 'Харківська область'),
    Category(id: 'odesa', name: 'Одеська область'),
    Category(id: 'dnipro', name: 'Дніпропетровська область'),
    Category(id: 'lviv', name: 'Львівська область'),
    Category(id: 'donetsk', name: 'Донецька область'),
    Category(id: 'zaporizhzhia', name: 'Запорізька область'),
    Category(id: 'mykolaiv', name: 'Миколаївська область'),
    Category(id: 'vinnytsia', name: 'Вінницька область'),
    Category(id: 'poltava', name: 'Полтавська область'),
    Category(id: 'sumy', name: 'Сумська область'),
    Category(id: 'khmelnytskyi', name: 'Хмельницька область'),
    Category(id: 'cherkasy', name: 'Черкаська область'),
    Category(id: 'zhytomyr', name: 'Житомирська область'),
    Category(id: 'chernihiv', name: 'Чернігівська область'),
    Category(id: 'kropyvnytskyi', name: 'Кіровоградська область'),
    Category(id: 'rivne', name: 'Рівненська область'),
    Category(id: 'ternopil', name: 'Тернопільська область'),
    Category(id: 'ivano-frankivsk', name: 'Івано-Франківська область'),
    Category(id: 'lutsk', name: 'Волинська область'),
    Category(id: 'uzhhorod', name: 'Закарпатська область'),
    Category(id: 'chernivtsi', name: 'Чернівецька область'),
    Category(id: 'kherson', name: 'Херсонська область'),
    Category(id: 'luhansk', name: 'Луганська область'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 1 + 20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.zinc200,
                width: 1.0,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 24,
                  ),
                  const SizedBox(width: 18),
                  Text(
                    'Оберіть область',
                    style: AppTextStyles.heading2Semibold,
                  ),
                ],
              ),
            ),
            centerTitle: false,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _regions.length,
        itemBuilder: (context, index) {
          final region = _regions[index];
          return GestureDetector(
            onTap: () {
              Navigator.pop(context, {'category': region});
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.zinc200,
                  width: 1,
                ),
              ),
              child: Text(
                region.name,
                style: AppTextStyles.body1Regular,
              ),
            ),
          );
        },
      ),
    );
  }
} 