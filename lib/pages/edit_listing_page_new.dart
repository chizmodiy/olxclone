import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:olxclone/theme/app_colors.dart';
import 'package:olxclone/theme/app_text_styles.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/category.dart';
import '../services/category_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subcategory.dart';
import '../services/subcategory_service.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import '../models/region.dart';
import '../services/region_service.dart';
import '../models/city.dart';

import '../services/listing_service.dart';
import 'package:flutter/services.dart';

import 'dart:async';
import '../widgets/location_creation_block.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';
import '../models/listing.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';

class EditListingPageNew extends StatefulWidget {
  final Listing listing;
  
  const EditListingPageNew({super.key, required this.listing});

  @override
  State<EditListingPageNew> createState() => _EditListingPageNewState();
}

class _EditListingPageNewState extends State<EditListingPageNew> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<dynamic> _selectedImages = []; // Може містити String (URL) або XFile
  final PageController _imagePageController = PageController();

  final GlobalKey _categoryButtonKey = GlobalKey();
  final GlobalKey _subcategoryButtonKey = GlobalKey();


  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  Category? _selectedCategory;
    List<Category> _categories = [];
  bool _isLoadingCategories = true;
  Subcategory? _selectedSubcategory;
    List<Subcategory> _subcategories = [];
  bool _isLoadingSubcategories = false;
  Region? _selectedRegion;
    List<Region> _regions = [];
  bool _isLoadingRegions = true;
  bool _isForSale = true;
    String _selectedCurrency = 'UAH';
  bool _isNegotiablePrice = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _viberController = TextEditingController();
  String _selectedMessenger = 'phone';
  final Map<String, TextEditingController> _extraFieldControllers = {};
  final Map<String, dynamic> _extraFieldValues = {};
  bool _isLoading = false;
  
  final TextEditingController _citySearchController = TextEditingController();


  City? _selectedCity;
  Timer? _debounceTimer;
  String? _selectedAddress;
  String? _selectedRegionName;
  double? _selectedLatitude;
  double? _selectedLongitude;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadCategories();
    _loadRegions();
    _addFormListeners();
    
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

  void _initializeData() {
    // Ініціалізуємо дані з існуючого оголошення
    _titleController.text = widget.listing.title;
    _descriptionController.text = widget.listing.description;
    
    if (widget.listing.isFree) {
      _isForSale = false;
      _priceController.clear();
      _selectedCurrency = 'UAH';
      _isNegotiablePrice = false;
    } else if (widget.listing.price != null) {
      _priceController.text = widget.listing.price.toString();
      _isForSale = true;
    } else {
      _isForSale = false; // Fallback if price is null and not explicitly free
    }
    
    if (widget.listing.currency != null) {
      _selectedCurrency = widget.listing.currency!;
    }
    
    // Ініціалізуємо контактні дані
    if (widget.listing.phoneNumber != null) {
      String phoneNumber = widget.listing.phoneNumber!;
      if (phoneNumber.startsWith('+380')) {
        _phoneController.text = phoneNumber.substring(4); // Видаляємо +380
      } else {
        _phoneController.text = phoneNumber;
      }
      _selectedMessenger = 'phone';
    } else if (widget.listing.whatsapp != null) {
      String whatsapp = widget.listing.whatsapp!;
      if (whatsapp.startsWith('+380')) {
        _whatsappController.text = whatsapp.substring(4); // Видаляємо +380
      } else {
        _whatsappController.text = whatsapp;
      }
      _selectedMessenger = 'whatsapp';
    } else if (widget.listing.telegram != null) {
      _telegramController.text = widget.listing.telegram!;
      _selectedMessenger = 'telegram';
    } else if (widget.listing.viber != null) {
      String viber = widget.listing.viber!;
      if (viber.startsWith('+380')) {
        _viberController.text = viber.substring(4); // Видаляємо +380
      } else {
        _viberController.text = viber;
      }
      _selectedMessenger = 'viber';
    }

    // Додатково ініціалізуємо інші контактні дані, якщо вони є
    if (widget.listing.whatsapp != null && _whatsappController.text.isEmpty) {
      String whatsapp = widget.listing.whatsapp!;
      if (whatsapp.startsWith('+380')) {
        _whatsappController.text = whatsapp.substring(4);
      } else {
        _whatsappController.text = whatsapp;
      }
    }
    
    if (widget.listing.telegram != null && _telegramController.text.isEmpty) {
      _telegramController.text = widget.listing.telegram!;
    }
    
    if (widget.listing.viber != null && _viberController.text.isEmpty) {
      String viber = widget.listing.viber!;
      if (viber.startsWith('+380')) {
        _viberController.text = viber.substring(4);
      } else {
        _viberController.text = viber;
      }
    }
    
    // Ініціалізуємо зображення
    if (widget.listing.photos.isNotEmpty) {
      _selectedImages.addAll(widget.listing.photos);
    }
    
    // Ініціалізуємо локацію
    _selectedAddress = widget.listing.address;
    _selectedLatitude = widget.listing.latitude;
    _selectedLongitude = widget.listing.longitude;
    _selectedRegionName = widget.listing.region;
  }

  void _addFormListeners() {
    _titleController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
    _priceController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _whatsappController.addListener(_validateForm);
    _telegramController.addListener(_validateForm);
    _viberController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _telegramController.dispose();
    _viberController.dispose();
    _citySearchController.dispose();
    _imagePageController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Методи валідації
  bool _isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return true; // Поле не обов'язкове
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.startsWith('380')) {
      return phone.length == 12;
    } else if (phone.startsWith('0')) {
      return phone.length == 10;
    } else {
      return phone.length >= 9 && phone.length <= 13;
    }
  }





  void _validateForm() {
    // Перевіряємо, що хоча б один контактний метод заповнений
    bool hasContactInfo = _phoneController.text.isNotEmpty ||
                         _whatsappController.text.isNotEmpty ||
                         _telegramController.text.isNotEmpty ||
                         _viberController.text.isNotEmpty;
    
    if (!hasContactInfo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Будь ласка, заповніть хоча б один контактний метод'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {});
  }

  // Методи завантаження даних
  Future<void> _loadCategories() async {
    try {
      final categoryService = CategoryService();
      final categories = await categoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
      
      // Find and select the category
      if (widget.listing.isFree) {
        _selectedCategory = categories.firstWhereOrNull((cat) => cat.name == 'Віддам безкоштовно');
      } else if (widget.listing.categoryId != null) {
        _selectedCategory = categories.firstWhereOrNull(
          (cat) => cat.id == widget.listing.categoryId,
        );
      }
      
      if (_selectedCategory != null) {
        await _loadSubcategories();
      } else {
        // Fallback to first category if original not found
        _selectedCategory = categories.firstOrNull;
        if (_selectedCategory != null) {
          await _loadSubcategories();
        }
      }
    } catch (e) {
      
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadSubcategories() async {
    if (_selectedCategory == null) return;
    
    setState(() {
      _isLoadingSubcategories = true;
    });
    
    try {
      final subcategoryService = SubcategoryService(Supabase.instance.client);
      final subcategories = await subcategoryService.getSubcategoriesForCategory(_selectedCategory!.id);
      setState(() {
        _subcategories = subcategories;
        _isLoadingSubcategories = false;
      });
      
      // Find and select the subcategory
      if (_selectedCategory?.name == 'Віддам безкоштовно') {
        _selectedSubcategory = subcategories.firstWhereOrNull((subcat) => subcat.name == 'Безкоштовно');
      } else if (widget.listing.subcategoryId != null) {
        _selectedSubcategory = subcategories.firstWhereOrNull(
          (subcat) => subcat.id == widget.listing.subcategoryId,
        );
      }

      _initializeExtraFields();
    } catch (e) {
      
      setState(() {
        _isLoadingSubcategories = false;
      });
    }
  }

  void _initializeExtraFields() {
    if (_selectedSubcategory == null) return;
    
    _extraFieldControllers.clear();
    _extraFieldValues.clear();
    
    for (var field in _selectedSubcategory!.extraFields) {
      _extraFieldControllers[field.name] = TextEditingController();
      
      if (widget.listing.customAttributes != null && 
          widget.listing.customAttributes!.containsKey(field.name)) {
        final value = widget.listing.customAttributes![field.name];
        if (field.type == 'number' && value is num) {
          _extraFieldControllers[field.name]!.text = value.toString();
        } else if (field.type == 'range' && value is Map) {
          if (value['min'] != null) {
            _extraFieldControllers['${field.name}_min'] = TextEditingController(text: value['min'].toString());
          }
          if (value['max'] != null) {
            _extraFieldControllers['${field.name}_max'] = TextEditingController(text: value['max'].toString());
          }
        } else if (field.type == 'select' && value != null) {
          _extraFieldValues[field.name] = value.toString();
        }
      }
    }
  }

  Future<void> _loadRegions() async {
    try {
      final regionService = RegionService(Supabase.instance.client);
      final regions = await regionService.getRegions();
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
      
      if (widget.listing.region != null) {
        _selectedRegion = regions.firstWhere(
          (region) => region.name == widget.listing.region,
          orElse: () => regions.first,
        );
      }
    } catch (e) {
      
      setState(() {
        _isLoadingRegions = false;
      });
    }
  }

  void _showBlockedUserBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BlockedUserBottomSheet(),
    );
  }

  // Метод оновлення оголошення
  Future<void> _updateListing() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final listingService = ListingService(Supabase.instance.client);

        Map<String, dynamic>? customAttributes;
        if (_selectedSubcategory != null && _extraFieldValues.isNotEmpty) {
          customAttributes = {};
          for (var field in _selectedSubcategory!.extraFields) {
            if (field.type == 'number') {
              final value = double.tryParse(_extraFieldControllers[field.name]?.text ?? '');
              if (value != null) {
                customAttributes[field.name] = value;
              }
            } else if (field.type == 'range') {
              final minValue = double.tryParse(_extraFieldControllers['${field.name}_min']?.text ?? '');
              final maxValue = double.tryParse(_extraFieldControllers['${field.name}_max']?.text ?? '');
              if (minValue != null || maxValue != null) {
                customAttributes[field.name] = {
                  'min': minValue,
                  'max': maxValue,
                };
              }
            } else if (field.type == 'select') {
              customAttributes[field.name] = _extraFieldValues[field.name];
            }
          }
        }

        final List<String> existingImageUrls = _selectedImages.whereType<String>().toList();
        final List<XFile> newImagesToUpload = _selectedImages.whereType<XFile>().toList();

        String locationString = '';
        if (_selectedRegion != null) {
          locationString = _selectedRegion!.name;
        } else if (_selectedRegionName != null) {
          locationString = _selectedRegionName!;
        } else {
          locationString = widget.listing.location;
        }

        await listingService.updateListing(
          listingId: widget.listing.id,
          title: _titleController.text,
          description: _descriptionController.text,
          categoryId: _selectedCategory?.id ?? widget.listing.categoryId,
          subcategoryId: _selectedSubcategory?.id ?? widget.listing.subcategoryId,
          location: locationString,
          isFree: !_isForSale,
          currency: _isForSale ? _selectedCurrency : null,
          price: _isForSale ? double.tryParse(_priceController.text) : null,
          phoneNumber: _phoneController.text.isNotEmpty ? '+380${_phoneController.text}' : null,
          whatsapp: _whatsappController.text.isNotEmpty ? '+380${_whatsappController.text}' : null,
          telegram: _telegramController.text.isNotEmpty ? _telegramController.text : null,
          viber: _viberController.text.isNotEmpty ? '+380${_viberController.text}' : null,
          customAttributes: customAttributes ?? {},
          newImages: newImagesToUpload,
          existingImageUrls: existingImageUrls,
          address: _selectedAddress,
          region: _selectedRegionName,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
        );

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        // Помилка оновлення оголошення
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        elevation: 0.0,
        scrolledUnderElevation: 0.0,
        toolbarHeight: 70.0,
        centerTitle: false,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back,
            color: AppColors.color2,
            size: 24,
          ),
        ),
        title: Text(
          'Редагувати оголошення',
          style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 1,
                          color: AppColors.zinc200,
                        ),
                        const SizedBox(height: 20),

                        // Photos Section
                        _buildPhotosSection(),
                        const SizedBox(height: 20),

                        // Title Input Field
                        Text(
                          'Заголовок',
                          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.zinc50,
                            borderRadius: BorderRadius.circular(200),
                            border: Border.all(color: AppColors.zinc200, width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(16, 24, 40, 0.05),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _titleController,
                            style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                            decoration: InputDecoration(
                              hintText: 'Введіть текст',
                              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description Input Field
                        Text(
                          'Опис',
                          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 180,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.zinc50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.zinc200, width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(16, 24, 40, 0.05),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                            decoration: InputDecoration(
                              hintText: 'Введіть текст',
                              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Category Section
                        _buildCategorySection(),
                        const SizedBox(height: 20),

                        // Subcategory Section
                        _buildSubcategorySection(),
                        const SizedBox(height: 20),

                        // LocationCreationBlock
                        LocationCreationBlock(
                          initialLocation: _selectedLatitude != null && _selectedLongitude != null 
                              ? latlong.LatLng(_selectedLatitude!, _selectedLongitude!)
                              : null,
                          initialRegion: _selectedRegionName,
                          initialCity: _selectedCity?.name,
                          onLocationSelected: (latLng, address, regionName, cityName) async {
                            if (latLng != null) {
                              Region? foundRegion;
                              if (regionName != null) {
                                foundRegion = _regions.firstWhereOrNull((region) => region.name == regionName);
                              }

                              if (foundRegion == null) {
                                double shortestDistance = double.infinity;
                                for (final region in _regions) {
                                  if (region.minLat != null && region.maxLat != null &&
                                      region.minLon != null && region.maxLon != null) {
                                    final centerLat = (region.minLat! + region.maxLat!) / 2;
                                    final centerLon = (region.minLon! + region.maxLon!) / 2;

                                    final distance = Geolocator.distanceBetween(
                                      latLng.latitude,
                                      latLng.longitude,
                                      centerLat,
                                      centerLon,
                                    );

                                    if (distance < shortestDistance) {
                                      shortestDistance = distance;
                                      foundRegion = region;
                                    }
                                  }
                                }
                              }

                              setState(() {
                                _selectedRegion = foundRegion;
                                _selectedRegionName = foundRegion?.name ?? regionName;
                                _selectedCity = cityName != null ? City(name: cityName, regionId: regionName ?? '') : null;
                                _selectedLatitude = latLng.latitude;
                                _selectedLongitude = latLng.longitude;
                                _selectedAddress = address ?? 'Обрана локація';
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Listing Type Toggle
                        if (_selectedCategory?.name != 'Віддам безкоштовно') ...[
                          _buildListingTypeToggle(),
                          const SizedBox(height: 20),
                        ],

                        // Currency Switch - only show if not free
                        if (_isForSale) ...[
                          _buildCurrencySection(),
                          const SizedBox(height: 20),
                        ],

                        // Price Input Field - only show if not free
                        if (_isForSale) ...[
                          _buildPriceSection(),
                          const SizedBox(height: 20),
                        ],

                        // Contact Form Section
                        _buildContactForm(),
                        const SizedBox(height: 20),

                        // Extra fields section
                        _buildExtraFieldsSection(),
                        const SizedBox(height: 20),

                        // Add bottom padding to account for floating buttons
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                // Floating buttons
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _updateListing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Зберегти зміни',
                              style: AppTextStyles.body2Semibold.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: AppColors.zinc200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Скасувати',
                              style: AppTextStyles.body2Semibold.copyWith(
                                color: AppColors.color8,
                              ),
                            ),
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

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Додайте фото',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            Text(
              '${_selectedImages.length}/7',
              style: AppTextStyles.captionMedium.copyWith(color: AppColors.color5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: AppColors.zinc200,
              strokeWidth: 1.0,
              dashWidth: 13.0,
              gapWidth: 13.0,
              borderRadius: 12.0,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/icons/Featured icon.svg',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Перемістіть зображення',
                    style: AppTextStyles.body1Medium.copyWith(color: AppColors.color2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG, JPG (max. 200MB)',
                    style: AppTextStyles.captionRegular.copyWith(color: AppColors.color8),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(_selectedImages.length, (index) {
                final image = _selectedImages[index];
                return SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImageWidget(image),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      if (_selectedImages.length >= 7) {
        return;
      }
      
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        
        // Validate each image before adding
        for (var image in images) {
          try {
            // Verify the image can be read
            await image.readAsBytes();
            
            if (_selectedImages.length < 7) {
              setState(() {
                _selectedImages.add(image);
              });
            }
          } catch (e) {
            // Skip invalid image
          }
        }
      }
    } catch (e) {
      // Error selecting images
    }
  }

  Widget _buildImageWidget(dynamic image) {
    if (image is String) {
      // Це URL зображення (існуюче зображення)
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.zinc200,
            child: Icon(Icons.error, color: AppColors.color5),
          );
        },
      );
    } else if (image is XFile) {
      // Це нове зображення
      if (kIsWeb) {
        return Image.network(
          image.path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.zinc200,
              child: Icon(Icons.error, color: AppColors.color5),
            );
          },
        );
      }
      return Image.file(
        File(image.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.zinc200,
            child: Icon(Icons.error, color: AppColors.color5),
          );
        },
      );
    }
    return Container(
      color: AppColors.zinc200,
      child: Icon(Icons.error, color: AppColors.color5),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Категорія',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          key: _categoryButtonKey,
          onTap: () {
            final RenderBox? button = _categoryButtonKey.currentContext?.findRenderObject() as RenderBox?;
            if (button != null) {
              final buttonPosition = button.localToGlobal(Offset.zero);
              final buttonSize = button.size;
              
              _showCategoryPicker(
                position: buttonPosition,
                size: buttonSize,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.zinc50,
              borderRadius: BorderRadius.circular(200),
              border: Border.all(color: AppColors.zinc200, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(16, 24, 40, 0.05),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategory?.name ?? 'Оберіть категорію',
                    style: AppTextStyles.body1Regular.copyWith(
                      color: _selectedCategory != null ? AppColors.color2 : AppColors.color5,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron_down.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(AppColors.color7, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategorySection() {
    if (_selectedCategory == null || _selectedCategory!.name == 'Віддам безкоштовно') {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Підкатегорія',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          key: _subcategoryButtonKey,
          onTap: _selectedCategory == null ? null : () {
            final RenderBox? button = _subcategoryButtonKey.currentContext?.findRenderObject() as RenderBox?;
            if (button != null) {
              final buttonPosition = button.localToGlobal(Offset.zero);
              final buttonSize = button.size;
              
              _showSubcategoryPicker(
                position: buttonPosition,
                size: buttonSize,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _selectedCategory == null ? AppColors.zinc100 : AppColors.zinc50,
              borderRadius: BorderRadius.circular(200),
              border: Border.all(color: AppColors.zinc200, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(16, 24, 40, 0.05),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSubcategory?.name ?? 'Оберіть підкатегорію',
                    style: AppTextStyles.body1Regular.copyWith(
                      color: _selectedSubcategory != null ? AppColors.color2 : AppColors.color5,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron_down.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(AppColors.color7, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListingTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип оголошення',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.zinc50,
            borderRadius: BorderRadius.circular(200),
            border: Border.all(color: AppColors.zinc200, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isForSale = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _isForSale ? AppColors.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: Text(
                      'Продати',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body2Medium.copyWith(
                        color: _isForSale ? Colors.white : AppColors.color2,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isForSale = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: !_isForSale ? AppColors.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: Text(
                      'Безкоштовно',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body2Medium.copyWith(
                        color: !_isForSale ? Colors.white : AppColors.color2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySection() {
    if (!_isForSale) {
      return const SizedBox.shrink(); // Hide currency section if not for sale
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Валюта',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(200),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCurrency = 'UAH';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedCurrency == 'UAH' ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(200),
                      border: Border.all(
                        color: _selectedCurrency == 'UAH' ? AppColors.primaryColor : AppColors.zinc200,
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(16, 24, 40, 0.05),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/currency-grivna-svgrepo-com 1.svg',
                          width: 21,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            _selectedCurrency == 'UAH' ? Colors.white : AppColors.color5,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ГРН',
                          style: AppTextStyles.body2Semibold.copyWith(
                            color: _selectedCurrency == 'UAH' ? Colors.white : AppColors.color8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCurrency = 'EUR';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedCurrency == 'EUR' ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(200),
                      border: Border.all(
                        color: _selectedCurrency == 'EUR' ? AppColors.primaryColor : AppColors.zinc200,
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(16, 24, 40, 0.05),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/currency-euro.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            _selectedCurrency == 'EUR' ? Colors.white : AppColors.color5,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'EUR',
                          style: AppTextStyles.body2Semibold.copyWith(
                            color: _selectedCurrency == 'EUR' ? Colors.white : AppColors.color8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCurrency = 'USD';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedCurrency == 'USD' ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(200),
                      border: Border.all(
                        color: _selectedCurrency == 'USD' ? AppColors.primaryColor : AppColors.zinc200,
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(16, 24, 40, 0.05),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/currency-dollar.svg',
                          width: 21,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            _selectedCurrency == 'USD' ? Colors.white : AppColors.color5,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'USD',
                          style: AppTextStyles.body2Semibold.copyWith(
                            color: _selectedCurrency == 'USD' ? Colors.white : AppColors.color8,
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
      ],
    );
  }

  Widget _buildPriceSection() {
    if (!_isForSale) {
      return const SizedBox.shrink(); // Hide price section if not for sale
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ціна',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.zinc50,
            borderRadius: BorderRadius.circular(200),
            border: Border.all(color: AppColors.zinc200, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(16, 24, 40, 0.05),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
            decoration: InputDecoration(
              hintText: 'Введіть ціну',
              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Контактна форма',
          style: AppTextStyles.body1Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 4),
        Text(
          'Оберіть спосіб зв\'язку',
          style: AppTextStyles.body2Regular.copyWith(color: AppColors.color5),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMessengerButton(
                type: 'whatsapp',
                iconPath: 'assets/icons/whatsapp.svg',
                label: '',
              ),
              const SizedBox(width: 8),
              _buildMessengerButton(
                type: 'telegram',
                iconPath: 'assets/icons/telegram.svg',
                label: '',
              ),
              const SizedBox(width: 8),
              _buildMessengerButton(
                type: 'viber',
                iconPath: 'assets/icons/viber.svg',
                label: '',
              ),
              const SizedBox(width: 8),
              _buildMessengerButton(
                type: 'phone',
                iconPath: 'assets/icons/phone.svg',
                label: '',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedMessenger == 'phone')
          _buildPhoneInput(
            controller: _phoneController,
            hintText: '(XX) XXX-XX-XX',
          )
        else if (_selectedMessenger == 'whatsapp')
          _buildPhoneInput(
            controller: _whatsappController,
            hintText: '(XX) XXX-XX-XX',
          )
        else if (_selectedMessenger == 'telegram')
          _buildPhoneInput(
            controller: _telegramController,
            hintText: 'Введіть номер телефону або нік',
            isTelegramInput: true,
          )
        else if (_selectedMessenger == 'viber')
          _buildPhoneInput(
            controller: _viberController,
            hintText: '(XX) XXX-XX-XX',
          ),
      ],
    );
  }

  Widget _buildMessengerButton({
    required String type,
    required String iconPath,
    required String label,
  }) {
    final bool isSelected = _selectedMessenger == type;
    final bool isSocialIcon = type == 'whatsapp' || type == 'telegram' || type == 'viber';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMessenger = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.zinc100,
          borderRadius: BorderRadius.circular(200),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.zinc100,
            width: 1,
          ),
          boxShadow: isSelected ? const [
            BoxShadow(
              color: Color(0x0C101828),
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: 0,
            )
          ] : null,
        ),
        child: SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
          colorFilter: isSocialIcon 
              ? null 
              : ColorFilter.mode(
                  isSelected ? Colors.white : AppColors.color5,
                  BlendMode.srcIn,
                ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput({
    required TextEditingController controller,
    required String hintText,
    bool isTelegramInput = false,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.zinc50,
        borderRadius: BorderRadius.circular(200),
        border: Border.all(color: AppColors.zinc200),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 24, 40, 0.05),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isTelegramInput) ...[
            const SizedBox(width: 16),
            // Прапор України
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0057B8),
              ),
              child: ClipOval(
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0057B8),
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Префікс +380
            Text(
              '+380',
              style: AppTextStyles.body1Regular.copyWith(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Center(
              child: TextField(
                controller: controller,
                keyboardType: isTelegramInput ? TextInputType.text : TextInputType.phone,
                inputFormatters: _getContactInputFormatters(),
                decoration: InputDecoration(
                  hintText: isTelegramInput ? hintText : '(XX) XXX-XX-XX',
                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                  contentPadding: EdgeInsets.only(
                    left: isTelegramInput ? 16 : 0,
                    right: 16,
                    top: 0,
                    bottom: 0,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: AppTextStyles.body1Regular.copyWith(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextInputFormatter> _getContactInputFormatters() {
    switch (_selectedMessenger) {
      case 'phone':
      case 'whatsapp':
      case 'viber':
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9), // Обмеження до 9 цифр (без +380)
        ];
      case 'telegram':
        return [
          LengthLimitingTextInputFormatter(32), // Обмеження для Telegram username
        ];
      default:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ];
    }
  }

  Widget _buildExtraFieldsSection() {
    if (_selectedSubcategory == null || _selectedSubcategory!.extraFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Додаткові характеристики',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 12),
        ..._selectedSubcategory!.extraFields.map((field) => _buildExtraField(field)),
      ],
    );
  }

  Widget _buildExtraField(dynamic field) {
    switch (field.type) {
      case 'number':
        return _buildNumberField(field);
      case 'range':
        return _buildRangeField(field);
      case 'select':
        return _buildSelectField(field);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNumberField(dynamic field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.name,
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.zinc50,
            borderRadius: BorderRadius.circular(200),
            border: Border.all(color: AppColors.zinc200, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(16, 24, 40, 0.05),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: TextField(
            controller: _extraFieldControllers[field.name],
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
            decoration: InputDecoration(
              hintText: 'Введіть значення',
              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildRangeField(dynamic field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.name,
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.zinc50,
                  borderRadius: BorderRadius.circular(200),
                  border: Border.all(color: AppColors.zinc200, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(16, 24, 40, 0.05),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _extraFieldControllers['${field.name}_min'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                  decoration: InputDecoration(
                    hintText: 'Мін',
                    hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.zinc50,
                  borderRadius: BorderRadius.circular(200),
                  border: Border.all(color: AppColors.zinc200, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(16, 24, 40, 0.05),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _extraFieldControllers['${field.name}_max'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                  decoration: InputDecoration(
                    hintText: 'Макс',
                    hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSelectField(dynamic field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.name,
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.zinc50,
            borderRadius: BorderRadius.circular(200),
            border: Border.all(color: AppColors.zinc200, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(16, 24, 40, 0.05),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _extraFieldValues[field.name],
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            hint: Text(
              'Оберіть значення',
              style: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
            ),
            items: field.options.map<DropdownMenuItem<String>>((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _extraFieldValues[field.name] = newValue;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showCategoryPicker({required Offset position, required Size size}) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: position.dy + size.height + 4,
              left: position.dx,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: size.width,
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.zinc200),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.03),
                        offset: Offset(0, 4),
                        blurRadius: 6,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return ListTile(
                              title: Text(
                                category.name,
                                style: AppTextStyles.body1Regular.copyWith(
                                  color: AppColors.color2,
                                ),
                              ),
                              onTap: () async {
                                setState(() {
                                  _selectedCategory = category;
                                  _selectedSubcategory = null;
                                  _subcategories.clear();
                                  _extraFieldControllers.clear();
                                  _extraFieldValues.clear();
                                });

                                await _loadSubcategories(); // Load subcategories first

                                if (category.name == 'Віддам безкоштовно') {
                                  setState(() {
                                    _isForSale = false; // Set to free
                                    _priceController.clear(); // Clear price
                                    _selectedCurrency = 'UAH'; // Reset currency
                                    _isNegotiablePrice = false; // Reset negotiable
                                    final freeSubcategory = _subcategories.firstWhereOrNull(
                                      (sub) => sub.name == 'Безкоштовно',
                                    );
                                    if (freeSubcategory != null) {
                                      _selectedSubcategory = freeSubcategory;
                                    }
                                  });
                                } else {
                                  setState(() {
                                    _isForSale = true; // Default to for sale
                                  });
                                }
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSubcategoryPicker({required Offset position, required Size size}) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: position.dy + size.height + 4,
              left: position.dx,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: size.width,
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.zinc200),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.03),
                        offset: Offset(0, 4),
                        blurRadius: 6,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _subcategories.length,
                          itemBuilder: (context, index) {
                            final subcategory = _subcategories[index];
                            return ListTile(
                              title: Text(
                                subcategory.name,
                                style: AppTextStyles.body1Regular.copyWith(
                                  color: AppColors.color2,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedSubcategory = subcategory;
                                  _extraFieldControllers.clear();
                                  _extraFieldValues.clear();
                                });
                                _initializeExtraFields();
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gapWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    ));

    final Path dashedPath = Path();
    final double dashLength = dashWidth;
    final double gapLength = gapWidth;
    final double totalLength = dashLength + gapLength;

    final double pathLength = _getPathLength(path);
    double currentLength = 0;

    while (currentLength < pathLength) {
      final double start = currentLength;
      final double end = (currentLength + dashLength).clamp(0.0, pathLength);
      
      if (start < end) {
        final double startT = start / pathLength;
        final double endT = end / pathLength;
        
        final Offset startPoint = _getPointAt(path, startT);
        final Offset endPoint = _getPointAt(path, endT);
        
        dashedPath.moveTo(startPoint.dx, startPoint.dy);
        dashedPath.lineTo(endPoint.dx, endPoint.dy);
      }
      
      currentLength += totalLength;
    }

    canvas.drawPath(dashedPath, paint);
  }

  double _getPathLength(Path path) {
    // Приблизний розрахунок довжини шляху
    return 2 * (100 + 50); // Приблизна довжина для прямокутника
  }

  Offset _getPointAt(Path path, double t) {
    // Приблизний розрахунок точки на шляху
    return Offset(t * 100, t * 50);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 