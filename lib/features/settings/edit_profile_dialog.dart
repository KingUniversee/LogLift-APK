import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _avatarUrlController = TextEditingController(text: widget.profile.avatarUrl);
    _avatarUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _removeAvatar() {
    setState(() {
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
      final updatedProfile = widget.profile.copyWith(
        name: name,
        avatarUrl: _avatarUrlController.text.trim(),
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
    final hasCustomAvatar = avatarUrl.isNotEmpty;

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

            // Avatar Preview & Remove button
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasCustomAvatar ? null : AppColors.accentGlowGradient,
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: hasCustomAvatar
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
                              size: 44,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (hasCustomAvatar)
                    TextButton.icon(
                      onPressed: _removeAvatar,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.accentRose),
                      label: const Text(
                        'Remove Image',
                        style: TextStyle(fontSize: 13, color: AppColors.accentRose, fontWeight: FontWeight.w600),
                      ),
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
              'Paste any direct image URL, or leave blank to use default avatar.',
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
