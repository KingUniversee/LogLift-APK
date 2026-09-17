import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../data/models/user_profile.dart';
import '../../providers/app_providers.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _avatarUrlController;
  File? _selectedImageFile;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _avatarUrlController = TextEditingController(text: widget.profile.avatarUrl);
    _avatarUrlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    // If the user enters/pastes a URL, clear any locally selected image file
    if (_avatarUrlController.text.isNotEmpty && _selectedImageFile != null) {
      setState(() {
        _selectedImageFile = null;
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _avatarUrlController.removeListener(_onUrlChanged);
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final file = File(picked.path);
        final length = await file.length();
        if (length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected image exceeds 5MB limit. Please choose a smaller image.'),
              ),
            );
          }
          return;
        }
        setState(() {
          _selectedImageFile = file;
          _avatarUrlController.text = ''; // Clear URL field so picked file takes priority
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _removeAvatar() {
    setState(() {
      _selectedImageFile = null;
      _avatarUrlController.text = '';
    });
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      String resolvedAvatarUrl = _avatarUrlController.text.trim();

      // If user selected a local file from gallery, upload it first
      if (_selectedImageFile != null) {
        resolvedAvatarUrl = await ref
            .read(userProfileRepoProvider)
            .uploadAvatar(_selectedImageFile!);
      }

      final updatedProfile = widget.profile.copyWith(
        name: name,
        avatarUrl: resolvedAvatarUrl,
      );

      await ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _avatarUrlController.text.trim();
    final hasPickedFile = _selectedImageFile != null;
    final hasCustomAvatar = hasPickedFile || avatarUrl.isNotEmpty;

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.borderGlassHighlight),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Avatar Preview & Action Buttons
            Center(
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasCustomAvatar ? null : AppColors.accentGlowGradient,
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: hasPickedFile
                          ? Image.file(
                              _selectedImageFile!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white60,
                                size: 36,
                              ),
                            )
                          : avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.broken_image_rounded,
                                    color: Colors.white60,
                                    size: 36,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  color: Colors.black87,
                                  size: 46,
                                ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _pickImage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          side: BorderSide(
                            color: AppColors.primaryLight.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        icon: Icon(
                          hasPickedFile ? Icons.swap_horiz_rounded : Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: Text(
                          hasPickedFile ? 'Change Selected' : 'Choose from Gallery',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (hasCustomAvatar)
                        TextButton.icon(
                          onPressed: _isSaving ? null : _removeAvatar,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accentRose,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Remove Image',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.accentRose,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Name Field
            GlassTextField(
              controller: _nameController,
              label: 'Display Name',
              hint: 'e.g. John Doe',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 20),

            // Divider between gallery and URL
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.borderGlass)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR AVATAR IMAGE URL',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.borderGlass)),
              ],
            ),
            const SizedBox(height: 16),

            // Avatar URL Field
            GlassTextField(
              controller: _avatarUrlController,
              label: 'Avatar Image URL',
              hint: 'https://example.com/avatar.png',
              prefixIcon: Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload a photo from your gallery above or paste an image URL.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Cancel',
                    variant: GlassButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    label: _isSaving ? 'Saving...' : 'Save',
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
