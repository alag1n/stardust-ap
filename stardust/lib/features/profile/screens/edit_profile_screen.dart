import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';
import 'package:stardust/core/widgets/cosmic_button.dart';
import 'package:stardust/services/auth_service.dart';
import 'package:stardust/services/image_upload_service.dart';
import 'package:stardust/services/location_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _imageService = ImageUploadService();
  final _locationService = LocationService();
  final _userId = FirebaseAuth.instance.currentUser?.uid;
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _genderController;
  
  int _age = 25;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isUpdatingLocation = false;
  String? _photoUrl;
  List<String> _photos = [];
  
  // Настройки поиска
  String _preferredGender = 'all';
  int _preferredAgeMin = 18;
  int _preferredAgeMax = 35;
  double _preferredDistance = 50.0;
  
  final List<String> _availableInterests = [
    'Космос', 'Астрономия', 'Музыка', 'Путешествия', 'Фотография',
    'Кино', 'Книги', 'Спорт', 'Игры', 'Искусство', 'Наука', 'Технологии',
    'Природа', 'Готовка', 'Танцы', 'Рисование',
  ];
  
  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _cityController = TextEditingController();
    _genderController = TextEditingController();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    if (_userId != null) {
      final user = await _authService.getUserData(_userId);
      if (user != null && mounted) {
        setState(() {
          _nameController.text = user.name;
          _bioController.text = user.bio ?? '';
          _cityController.text = user.location ?? '';
          _genderController.text = user.gender;
          _age = user.age;
          _selectedInterests = List<String>.from(user.interestedIn?.split(', ') ?? []);
          _photoUrl = user.photoUrl;
          _photos = List<String>.from(user.photos);
          // Загрузка настроек поиска
          _preferredGender = user.preferredGender ?? 'all';
          _preferredAgeMin = user.preferredAgeMin ?? 18;
          _preferredAgeMax = user.preferredAgeMax ?? 35;
          _preferredDistance = user.preferredDistance ?? 50.0;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_genderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите пол')),
      );
      return;
    }
    
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы 1 интерес')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Пытаемся получить геолокацию
      double? latitude;
      double? longitude;
      String? location;
      
      if (_cityController.text.isNotEmpty) {
        // Если указан город - используем его
        location = _cityController.text.trim();
      } else {
        // Пробуем получить GPS координаты
        setState(() => _isUpdatingLocation = true);
        final locationData = await _locationService.getLocationData();
        if (locationData != null) {
          latitude = locationData['latitude'];
          longitude = locationData['longitude'];
          location = locationData['location'];
        }
        setState(() => _isUpdatingLocation = false);
      }

      final userData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': location,
        'age': _age,
        'gender': _genderController.text.trim(),
        'interestedIn': _selectedInterests.join(', '),
        'isProfileComplete': true,
        'lastActive': DateTime.now().toIso8601String(),
        
        // Настройки поиска
        'preferredGender': _preferredGender,
        'preferredAgeMin': _preferredAgeMin,
        'preferredAgeMax': _preferredAgeMax,
        'preferredDistance': _preferredDistance,
      };

      // Добавляем координаты если есть
      if (latitude != null) userData['latitude'] = latitude;
      if (longitude != null) userData['longitude'] = longitude;

      // Добавляем фото если есть
      if (_photoUrl != null) {
        userData['photoUrl'] = _photoUrl;
      }
      if (_photos.isNotEmpty) {
        userData['photos'] = _photos;
      }

      await _authService.updateUserData(_userId!, userData);
      
      // Обновляем имя в Firebase Auth
      await _authService.updateProfile(displayName: _nameController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль сохранён')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarBackground(animate: false),
          SafeArea(
            child: Column(
              children: [
                // Хедер
                _buildHeader(context),
                // Форма
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Фото профиля
                          _buildPhotoSection(),
                          const SizedBox(height: 24),
                          // Имя
                          _buildTextField(
                            controller: _nameController,
                            label: 'Имя',
                            icon: Icons.person_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите имя';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Пол
                          _buildGenderSelector(),
                          const SizedBox(height: 16),
                          // Возраст
                          _buildAgeSelector(),
                          const SizedBox(height: 16),
                          // Город
                          _buildTextField(
                            controller: _cityController,
                            label: 'Город',
                            icon: Icons.location_on_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите город';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // О себе
                          _buildTextField(
                            controller: _bioController,
                            label: 'О себе',
                            icon: Icons.edit_note,
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Расскажите о себе';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Интересы
                          _buildInterestsSection(),
                          const SizedBox(height: 24),
                          // Настройки поиска
                          _buildSearchPreferencesSection(),
                          const SizedBox(height: 32),
                          // Кнопка сохранения
                          CosmicButton(
                            text: _isLoading ? 'Сохранение...' : 'Сохранить',
                            onPressed: _isLoading ? () {} : _saveProfile,
                            width: double.infinity,
                          ),
                          const SizedBox(height: 16),
                        ],
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceLight.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            icon: const Icon(Icons.close),
          ),
          const Expanded(
            child: Text(
              'Редактирование профиля',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          // Основное фото
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 3,
                    ),
                    image: _photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _photoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (_isUploadingPhoto)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showPhotoOptions,
            child: const Text('Изменить фото'),
          ),
          // Дополнительные фото
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length + 1,
                itemBuilder: (context, index) {
                  if (index == _photos.length) {
                    // Кнопка добавления
                    return GestureDetector(
                      onTap: _addMorePhotos,
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }
                  
                  return Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(_photos[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_photos.length < 6)
              TextButton(
                onPressed: _addMorePhotos,
                child: Text('Добавить ещё фото (${6 - _photos.length} осталось)'),
              ),
          ] else
            TextButton(
              onPressed: _addMorePhotos,
              child: const Text('Добавить фото (до 6)'),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(fromCamera: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(fromCamera: true);
                },
              ),
              if (_photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Удалить фото', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeMainPhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    if (_userId == null) return;
    
    setState(() => _isUploadingPhoto = true);
    
    try {
      final file = fromCamera 
          ? await _imageService.pickFromCamera()
          : await _imageService.pickFromGallery();
      
      if (file != null) {
        final url = await _imageService.uploadToFirebase(
          file: file,
          userId: _userId!,
          folder: 'avatars',
        );
        
        if (mounted) {
          setState(() => _photoUrl = url);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _removeMainPhoto() {
    setState(() => _photoUrl = null);
  }

  Future<void> _addMorePhotos() async {
    if (_userId == null || _photos.length >= 6) return;
    
    try {
      final files = await _imageService.pickMultiple();
      
      if (files.isEmpty) return;
      
      setState(() => _isUploadingPhoto = true);
      
      final remaining = 6 - _photos.length;
      final toUpload = files.take(remaining).toList();
      
      for (final file in toUpload) {
        final url = await _imageService.uploadToFirebase(
          file: file,
          userId: _userId!,
          folder: 'photos',
        );
        
        _photos.add(url);
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1);
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wc_outlined, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              const Text(
                'Пол',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _genderController.text = 'male'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _genderController.text == 'male'
                          ? AppColors.primary
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Мужской',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _genderController.text == 'male'
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _genderController.text = 'female'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _genderController.text == 'female'
                          ? AppColors.primary
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Женский',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _genderController.text == 'female'
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1);
  }

  Widget _buildAgeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cake_outlined, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              const Text(
                'Возраст',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$_age лет',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _age.toDouble(),
            min: 18,
            max: 65,
            divisions: 47,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _age = value.round());
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1);
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Интересы',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Выберите до 10 интересов',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest);
                  } else if (_selectedInterests.length < 10) {
                    _selectedInterests.add(interest);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceLight,
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1);
  }

  Widget _buildSearchPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Настройки поиска',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Кого вы ищете',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        
        // Пол
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Пол',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGenderChip('all', 'Все'),
                  const SizedBox(width: 8),
                  _buildGenderChip('female', 'Девушки'),
                  const SizedBox(width: 8),
                  _buildGenderChip('male', 'Мужчины'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Возраст
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Возраст',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$_preferredAgeMin - $_preferredAgeMax лет',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: RangeValues(
                  _preferredAgeMin.toDouble(),
                  _preferredAgeMax.toDouble(),
                ),
                min: 18,
                max: 65,
                divisions: 47,
                activeColor: AppColors.primary,
                onChanged: (values) {
                  setState(() {
                    _preferredAgeMin = values.start.round();
                    _preferredAgeMax = values.end.round();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Расстояние
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Расстояние',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${_preferredDistance.round()} км',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _preferredDistance,
                min: 1,
                max: 200,
                divisions: 199,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => _preferredDistance = value);
                },
              ),
            ],
          ),
        ),
        
        // Геолокация
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Определить местоположение',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _isUpdatingLocation 
                          ? 'Определение...' 
                          : 'Для поиска по расстоянию',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _isUpdatingLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: _updateLocation,
                      icon: const Icon(Icons.refresh),
                    ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1);
  }

  Widget _buildGenderChip(String value, String label) {
    final isSelected = _preferredGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _preferredGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateLocation() async {
    setState(() => _isUpdatingLocation = true);
    
    try {
      final locationData = await _locationService.getLocationData();
      if (locationData != null && mounted) {
        setState(() {
          _cityController.text = locationData['location'] ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Местоположение: ${locationData['location'] ?? 'определено'}'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось определить местоположение')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLocation = false);
      }
    }
  }
}
