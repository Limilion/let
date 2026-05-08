import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _linksController;
  late TextEditingController _tagsController;
  late TextEditingController _musicTitleController;
  
  String? _musicTrackUrl;
  XFile? _selectedPhoto;
  XFile? _selectedCover;
  File? _selectedAudio;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?['name'] ?? '');
    _bioController = TextEditingController(text: user?['bio'] ?? '');
    _linksController = TextEditingController(text: ((user?['profileLinks'] as List?) ?? []).join(', '));
    _tagsController = TextEditingController(text: ((user?['tags'] as List?) ?? []).join(', '));
    _musicTitleController = TextEditingController(text: user?['musicTitle'] ?? '');
    _musicTrackUrl = user?['musicTrack'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _linksController.dispose();
    _tagsController.dispose();
    _musicTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCover) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: isCover ? 75 : 70,
    );
    if (image != null) {
      setState(() {
        if (isCover) {
          _selectedCover = image;
        } else {
          _selectedPhoto = image;
        }
      });
    }
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _selectedAudio = File(result.files.single.path!);
        if (_musicTitleController.text.isEmpty) {
          _musicTitleController.text = result.files.single.name.split('.').first;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الاسم')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl = authProvider.user?['photo'];
      String? coverUrl = authProvider.user?['coverPhoto'];
      String? musicTrack = _musicTrackUrl;

      // Upload files if selected
      if (_selectedPhoto != null) {
        final res = await ApiService.upload('upload_media', File(_selectedPhoto!.path));
        if (res['success']) photoUrl = res['data']['url'];
      }
      if (_selectedCover != null) {
        final res = await ApiService.upload('upload_media', File(_selectedCover!.path));
        if (res['success']) coverUrl = res['data']['url'];
      }
      if (_selectedAudio != null) {
        final res = await ApiService.upload('upload_media', _selectedAudio!);
        if (res['success']) musicTrack = res['data']['url'];
      }

      final result = await authProvider.updateProfileV2({
        'name': name,
        'bio': _bioController.text.trim(),
        'photo': photoUrl,
        'coverPhoto': coverUrl,
        'musicTrack': musicTrack,
        'musicTitle': _musicTitleController.text.trim(),
        'profileLinks': _linksController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'tags': _tagsController.text
            .split(',')
            .map((e) => e.trim().replaceFirst('#', ''))
            .where((e) => e.isNotEmpty)
            .toList(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح ✨')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'فشل التحديث')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('تعديل الملف الشخصي', style: TextStyle(color: colors.text, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header: Cover + Avatar
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        image: _selectedCover != null
                            ? DecorationImage(image: FileImage(File(_selectedCover!.path)), fit: BoxFit.cover)
                            : (user?['coverPhoto'] != null
                                ? DecorationImage(image: NetworkImage(ApiService.getImageUrl(user!['coverPhoto'])!), fit: BoxFit.cover)
                                : null),
                      ),
                      child: Center(
                        child: Icon(Icons.add_a_photo_rounded, color: colors.textSecondary.withValues(alpha: 0.5), size: 32),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: colors.background, shape: BoxShape.circle),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                            image: _selectedPhoto != null
                                ? DecorationImage(image: FileImage(File(_selectedPhoto!.path)), fit: BoxFit.cover)
                                : (user?['photo'] != null
                                    ? DecorationImage(image: NetworkImage(ApiService.getImageUrl(user!['photo'])!), fit: BoxFit.cover)
                                    : null),
                          ),
                          child: Center(
                            child: Icon(Icons.camera_alt_rounded, color: colors.primary, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('المعلومات الأساسية', colors),
                  const SizedBox(height: 16),
                  _buildModernField(
                    label: 'الاسم الكامل',
                    controller: _nameController,
                    hint: 'اسمك كما سيظهر للآخرين',
                    colors: colors,
                  ),
                  const SizedBox(height: 16),
                  _buildModernField(
                    label: 'النبذة (Bio)',
                    controller: _bioController,
                    hint: 'أخبر العالم عن نفسك... يمكنك استخدام #tags و @mentions',
                    colors: colors,
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('الموسيقى (Bio Music)', colors),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Icon(Icons.music_note_rounded, color: colors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedAudio != null ? 'تم اختيار: ${_selectedAudio!.path.split('/').last}' : (user?['musicTrack'] != null ? 'موسيقى مفعلة' : 'لم يتم اختيار موسيقى'),
                                    style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'ستظهر الموسيقى في بروفايلك للمتابعين',
                                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _pickAudio,
                              child: const Text('تغيير'),
                            ),
                          ],
                        ),
                        if (user?['musicTrack'] != null || _selectedAudio != null) ...[
                          const SizedBox(height: 16),
                          _buildModernField(
                            label: 'عنوان المقطع',
                            controller: _musicTitleController,
                            hint: 'مثلاً: أغنيتي المفضلة 🎵',
                            colors: colors,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Social & Tags', colors),
                  const SizedBox(height: 16),
                  _buildModernField(
                    label: 'الروابط',
                    controller: _linksController,
                    hint: 'https://site.com, https://instagram.com/..',
                    colors: colors,
                  ),
                  const SizedBox(height: 16),
                  _buildModernField(
                    label: 'الاهتمامات (Tags)',
                    controller: _tagsController,
                    hint: 'flutter, uiux, music, travel',
                    colors: colors,
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, CustomColors colors) {
    return Text(
      title,
      style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
    );
  }

  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required CustomColors colors,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.4)),
            filled: true,
            fillColor: colors.surface.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.5))),
          ),
        ),
      ],
    );
  }
}
