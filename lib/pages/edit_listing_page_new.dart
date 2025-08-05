import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/category.dart';
import '../services/category_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subcategory.dart';
import '../services/subcategory_service.dart';
import '../models/region.dart';
import '../services/region_service.dart';
import '../models/city.dart';
import '../services/city_service.dart';
import '../services/listing_service.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../widgets/location_picker.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';
import '../models/listing.dart';
import 'package:latlong2/latlong.dart' as latlong;

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
  final int _currentImagePage = 0;
  final GlobalKey _categoryButtonKey = GlobalKey();
  final GlobalKey _subcategoryButtonKey = GlobalKey();
  final GlobalKey _regionButtonKey = GlobalKey();
  final GlobalKey _cityButtonKey = GlobalKey();
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
  List<City> _cities = [];
  bool _isSearchingCities = false;
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
    
    if (widget.listing.price != null) {
      _priceController.text = widget.listing.price.toString();
      _isForSale = true;
    } else {
      _isForSale = false;
    }
    
    if (widget.listing.currency != null) {
      _selectedCurrency = widget.listing.currency!;
    }
    
    // Ініціалізуємо контактні дані
    if (widget.listing.phoneNumber != null) {
      _phoneController.text = widget.listing.phoneNumber!;
      _selectedMessenger = 'phone';
    } else if (widget.listing.whatsapp != null) {
      _whatsappController.text = widget.listing.whatsapp!;
      _selectedMessenger = 'whatsapp';
    } else if (widget.listing.telegram != null) {
      _telegramController.text = widget.listing.telegram!;
      _selectedMessenger = 'telegram';
    } else if (widget.listing.viber != null) {
      _viberController.text = widget.listing.viber!;
      _selectedMessenger = 'viber';
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
    if (phone.isEmpty) return true;
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.startsWith('380')) {
      return phone.length == 12;
    } else if (phone.startsWith('0')) {
      return phone.length == 10;
    } else {
      return phone.length >= 9 && phone.length <= 13;
    }
  }

  bool _isValidPhoneWithPrefix(String phone) {
    if (phone.isEmpty) return true;
    if (phone.startsWith('+380')) {
      return phone.length == 13;
    }
    return _isValidPhoneNumber(phone);
  }

  bool _isValidTelegram(String telegram) {
    if (telegram.isEmpty) return true;
    if (telegram.startsWith('@')) {
      return telegram.length >= 6 && telegram.length <= 33;
    } else if (RegExp(r'^[a-zA-Z0-9_]{5,32}$').hasMatch(telegram)) {
      return true;
    }
    return _isValidPhoneNumber(telegram);
  }

  bool get _isFormValid {
    return _titleController.text.isNotEmpty &&
           _descriptionController.text.isNotEmpty &&
           _selectedCategory != null &&
           _selectedSubcategory != null &&
           (_selectedAddress != null && _selectedAddress!.isNotEmpty) &&
           _isValidPhoneWithPrefix(_phoneController.text) &&
           _isValidPhoneWithPrefix(_whatsappController.text) &&
           _isValidTelegram(_telegramController.text) &&
           _isValidPhoneWithPrefix(_viberController.text) &&
           (_isForSale ? (_priceController.text.isNotEmpty && double.tryParse(_priceController.text) != null) : true);
  }

  void _validateForm() {
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
      
      // Знаходимо категорію оголошення
      if (widget.listing.categoryId != null) {
        _selectedCategory = categories.firstWhere(
          (cat) => cat.id == widget.listing.categoryId,
          orElse: () => categories.first,
        );
        await _loadSubcategories();
      }
    } catch (e) {
      print('Error loading categories: $e');
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
      
      // Знаходимо підкатегорію оголошення
      if (widget.listing.subcategoryId != null) {
        _selectedSubcategory = subcategories.firstWhere(
          (subcat) => subcat.id == widget.listing.subcategoryId,
          orElse: () => subcategories.first,
        );
        _initializeExtraFields();
      }
    } catch (e) {
      print('Error loading subcategories: $e');
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
      print('Error loading regions: $e');
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
        if (_selectedRegion != null && _selectedCity != null) {
          locationString = '${_selectedRegion!.name}, ${_selectedCity!.name}';
        } else if (_selectedRegion != null) {
          locationString = _selectedRegion!.name;
        } else if (_selectedCity != null) {
          locationString = _selectedCity!.name;
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
          phoneNumber: _selectedMessenger == 'phone' ? _phoneController.text : null,
          whatsapp: _selectedMessenger == 'whatsapp' ? _whatsappController.text : null,
          telegram: _selectedMessenger == 'telegram' ? _telegramController.text : null,
          viber: _selectedMessenger == 'viber' ? _viberController.text : null,
          customAttributes: customAttributes ?? {},
          newImages: newImagesToUpload,
          existingImageUrls: existingImageUrls,
          address: _selectedAddress,
          region: _selectedRegion?.name,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
        );

        Navigator.of(context).pop(true);
      } catch (e) {
        print('Error updating listing: $e');
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

                        // LocationPicker
                        LocationPicker(
                          initialLatLng: _selectedLatitude != null && _selectedLongitude != null 
                              ? latlong.LatLng(_selectedLatitude!, _selectedLongitude!)
                              : null,
                          initialAddress: _selectedAddress,
                          initialRegion: _selectedRegionName,
                          onLocationSelected: (latLng, address) {
                            setState(() {
                              _selectedAddress = address;
                              _selectedLatitude = latLng?.latitude;
                              _selectedLongitude = latLng?.longitude;
                              if (address != null && address.isNotEmpty) {
                                final region = _regions.firstWhere(
                                  (r) => address.contains(r.name),
                                  orElse: () => _regions.first,
                                );
                                _selectedRegion = region;
                                _selectedRegionName = region.name;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Listing Type Toggle
                        _buildListingTypeToggle(),
                        const SizedBox(height: 20),

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

  // Додамо всі необхідні методи з оригінального файлу...

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фотографії',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
          height: 120,
          child: _selectedImages.isEmpty
              ? _buildAddPhotoButton()
              : _buildPhotoGallery(),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: double.infinity,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: AppColors.color5,
            ),
            const SizedBox(height: 8),
            Text(
              'Додати фотографії',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _selectedImages.length + 1,
      itemBuilder: (context, index) {
        if (index == _selectedImages.length) {
          return _buildAddMorePhotoButton();
        }
        return _buildPhotoItem(index);
      },
    );
  }

  Widget _buildAddMorePhotoButton() {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: _pickImages,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.zinc50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.zinc200, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 24,
                color: AppColors.color5,
              ),
              const SizedBox(height: 4),
              Text(
                'Додати',
                style: AppTextStyles.captionMedium.copyWith(color: AppColors.color5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    final image = _selectedImages[index];
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image is String
                ? Image.network(
                    image,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(image.path),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
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
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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
          'Контактна інформація',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        
        // Messenger type selector
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
                      _selectedMessenger = 'phone';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedMessenger == 'phone' ? AppColors.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: Text(
                      'Телефон',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body2Medium.copyWith(
                        color: _selectedMessenger == 'phone' ? Colors.white : AppColors.color2,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMessenger = 'whatsapp';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedMessenger == 'whatsapp' ? AppColors.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: Text(
                      'WhatsApp',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body2Medium.copyWith(
                        color: _selectedMessenger == 'whatsapp' ? Colors.white : AppColors.color2,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMessenger = 'telegram';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedMessenger == 'telegram' ? AppColors.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: Text(
                      'Telegram',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body2Medium.copyWith(
                        color: _selectedMessenger == 'telegram' ? Colors.white : AppColors.color2,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMessenger = 'viber';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedMessenger == 'viber' ? AppColors.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: Text(
                      'Viber',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body2Medium.copyWith(
                        color: _selectedMessenger == 'viber' ? Colors.white : AppColors.color2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Contact input field
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
            controller: _getContactController(),
            keyboardType: _getContactKeyboardType(),
            inputFormatters: _getContactInputFormatters(),
            style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
            decoration: InputDecoration(
              hintText: _getContactHintText(),
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

  TextEditingController _getContactController() {
    switch (_selectedMessenger) {
      case 'phone':
        return _phoneController;
      case 'whatsapp':
        return _whatsappController;
      case 'telegram':
        return _telegramController;
      case 'viber':
        return _viberController;
      default:
        return _phoneController;
    }
  }

  TextInputType _getContactKeyboardType() {
    switch (_selectedMessenger) {
      case 'phone':
      case 'whatsapp':
      case 'viber':
        return TextInputType.phone;
      case 'telegram':
        return TextInputType.text;
      default:
        return TextInputType.phone;
    }
  }

  List<TextInputFormatter> _getContactInputFormatters() {
    switch (_selectedMessenger) {
      case 'phone':
      case 'whatsapp':
      case 'viber':
        return [
          FilteringTextInputFormatter.digitsOnly,
        ];
      case 'telegram':
        return [];
      default:
        return [
          FilteringTextInputFormatter.digitsOnly,
        ];
    }
  }

  String _getContactHintText() {
    switch (_selectedMessenger) {
      case 'phone':
        return '+380';
      case 'whatsapp':
        return '+380';
      case 'telegram':
        return '@username або номер телефону';
      case 'viber':
        return '+380';
      default:
        return '+380';
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
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                  _selectedSubcategory = null;
                                  _subcategories.clear();
                                  _extraFieldControllers.clear();
                                  _extraFieldValues.clear();
                                });
                                _loadSubcategories();
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
} 