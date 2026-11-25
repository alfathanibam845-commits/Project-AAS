
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:item_shop/pages/welcomeapp_page.dart';
import 'package:item_shop/services/api.dart';
import 'package:item_shop/services/theme_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userId;
  String _userName = 'My Account';
  String? _profileUrl;
  String? _bannerUrl;

  bool _isLoading = true;
  bool _isUploading = false;
  bool _isSavingName = false;

  final ImagePicker _picker = ImagePicker();
  final ImageCropper _cropper = ImageCropper();

  @override
  void initState() {
    super.initState();
    _readUser();
  }

  // ==========================================
  // LOAD PROFILE
  // ==========================================

  Future<void> _readUser() async {
    final id = await ApiService.getId();

    if (!mounted) return;

    setState(() {
      _userId = id;
    });

    await _loadProfile();
  }

  Future<void> _loadProfile({
    bool showError = true,
  }) async {
    try {
      final response = await ApiService.get('/users/me');

      final responseData =
          Map<String, dynamic>.from(response);

      final data = Map<String, dynamic>.from(
        responseData['data'] ?? {},
      );

      final user = Map<String, dynamic>.from(
        data['user'] ?? {},
      );

      if (!mounted) return;

      setState(() {
        _userId = user['id']?.toString() ?? _userId;

        _userName =
            user['username']?.toString() ?? 'My Account';

        _profileUrl = user['profileImage']?.toString();
        _bannerUrl = user['bannerImage']?.toString();

        if (_profileUrl?.isEmpty ?? false) {
          _profileUrl = null;
        }

        if (_bannerUrl?.isEmpty ?? false) {
          _bannerUrl = null;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (showError) {
        _showMessage('Gagal mengambil data profil: $e');
      }
    }
  }

  // ==========================================
  // EDIT NAME
  // ==========================================

  Future<void> _editName() async {
    if (_isSavingName) return;

    final newName = await showDialog<String>(
      context: context,
      builder: (_) {
        return EditNameDialog(
          initialName: _userName,
        );
      },
    );

    if (!mounted || newName == null || newName.isEmpty) {
      return;
    }

    if (newName == _userName) return;

    setState(() {
      _isSavingName = true;
    });

    try {
      await ApiService.put(
        '/users/me',
        {
          'username': newName,
        },
      );

      if (!mounted) return;

      setState(() {
        _userName = newName;
      });

      _showMessage('Nama berhasil diperbarui!');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal memperbarui nama: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingName = false;
        });
      }
    }
  }

  // ==========================================
  // PICK IMAGE + IMAGE CROPPER
  // ==========================================

  Future<void> _pickImage({
    required bool isBanner,
  }) async {
    if (_isUploading) return;

    try {
      final selected = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (selected == null || !mounted) return;

      XFile imageToUpload = selected;

      if (isBanner) {
        final croppedImage = await _cropper.cropImage(
          sourcePath: selected.path,
          aspectRatio: const CropAspectRatio(
            ratioX: 16,
            ratioY: 9,
          ),
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 90,
          maxWidth: 1920,
          maxHeight: 1080,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Atur Banner',
              toolbarColor: const Color(0xFF174D3A),
              toolbarWidgetColor: Colors.white,
              backgroundColor: Colors.black,
              activeControlsWidgetColor:
                  const Color(0xFF8BC5A5),
              dimmedLayerColor: Colors.black54,
              cropFrameColor: Colors.white,
              cropGridColor: Colors.white70,
              showCropGrid: true,
              lockAspectRatio: true,
              initAspectRatio:
                  CropAspectRatioPreset.ratio16x9,
              aspectRatioPresets: [
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.page,
              themeData: WebThemeData(),
            ),
          ],
        );

        if (croppedImage == null || !mounted) return;

        imageToUpload = XFile(croppedImage.path);
      }

      if (!mounted) return;

      setState(() {
        _isUploading = true;
      });

      final response = await ApiService.postMultiPart(
        endpoint: isBanner
            ? '/users/me/banner'
            : '/users/me/profile-photo',
        data: {},
        image: imageToUpload,
        method: 'PUT',
      );

      final responseData =
          Map<String, dynamic>.from(response);

      final data = Map<String, dynamic>.from(
        responseData['data'] ?? {},
      );

      if (!mounted) return;

      setState(() {
        if (isBanner) {
          _bannerUrl = data['bannerImage']?.toString();
        } else {
          _profileUrl = data['profileImage']?.toString();
        }
      });

      await _loadProfile(showError: false);

      if (!mounted) return;

      _showMessage(
        isBanner
            ? 'Banner berhasil diperbarui!'
            : 'Foto profil berhasil diperbarui!',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal mengunggah gambar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // ==========================================
  // SNACKBAR
  // ==========================================

  void _showMessage(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ==========================================
  // LOGOUT WITH CONFIRMATION
  // ==========================================

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Konfirmasi Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Ingin keluar dari akun?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Tidak',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );

    // Jika memilih Tidak atau dialog ditutup,
    // proses logout dibatalkan.
    if (confirm != true) return;

    // Jika memilih Ya, hapus data login.
    await ApiService.logout();

    if (!mounted) return;

    // Kembali ke WelcomePage dan hapus halaman sebelumnya.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomePage(),
      ),
      (route) => false,
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDark;

    final textColor =
        Theme.of(context).colorScheme.onSurface;

    final mutedColor =
        Theme.of(context).colorScheme.onSurfaceVariant;

    final cardColor =
        Theme.of(context).colorScheme.surface;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // PROFILE HEADER
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withOpacity(0.12),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 188,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // BANNER
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 145,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFF174D3A),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                          child: _bannerUrl != null
                              ? Image.network(
                                  _bannerUrl!,
                                  width: double.infinity,
                                  height: 145,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 40,
                                        color: Colors.white54,
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.landscape_outlined,
                                    size: 45,
                                    color: Colors.white30,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // EDIT BANNER
                    Positioned(
                      right: 14,
                      top: 14,
                      child: _circleButton(
                        icon: Icons.edit_outlined,
                        onTap: _isUploading
                            ? null
                            : () => _pickImage(
                                  isBanner: true,
                                ),
                      ),
                    ),

                    // PROFILE PHOTO
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: cardColor,
                              child: CircleAvatar(
                                radius: 43,
                                backgroundColor:
                                    const Color(0xFFDCE9DF),
                                backgroundImage:
                                    _profileUrl != null
                                        ? NetworkImage(
                                            _profileUrl!,
                                          )
                                        : null,
                                child: _profileUrl == null
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: Color(0xFF174D3A),
                                      )
                                    : null,
                              ),
                            ),

                            // EDIT PROFILE PHOTO
                            Positioned(
                              right: 0,
                              bottom: 2,
                              child: _circleButton(
                                icon: Icons.camera_alt_outlined,
                                onTap: _isUploading
                                    ? null
                                    : () => _pickImage(
                                          isBanner: false,
                                        ),
                                background:
                                    const Color.fromARGB(
                                  255,
                                  3,
                                  3,
                                  3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _userName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                _userId == null
                    ? 'User ID unavailable'
                    : 'User ID: $_userId',
                style: TextStyle(
                  color: mutedColor,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // EDIT NAME
        _settingTile(
          icon: Icons.person_outline_rounded,
          title: 'Edit Name',
          subtitle: _isSavingName
              ? 'Saving changes...'
              : 'Change your account name',
          onTap: _isSavingName ? () {} : _editName,
        ),

        const SizedBox(height: 12),

        // UPLOAD STATUS
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),

        // DARK MODE
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.dark_mode_outlined,
                color: Color(0xFF174D3A),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark Mode',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    Text(
                      'Change app appearance',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Switch(
                value: isDark,
                activeColor: const Color(0xFF8BC5A5),
                onChanged: (value) {
                  ThemeController.instance
                      .toggleTheme(value);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // SIGN OUT
        _settingTile(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          subtitle: 'Sign out from your itemShop account',
          onTap: _logout,
          iconColor: const Color.fromARGB(
            255,
            206,
            33,
            33,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CIRCULAR BUTTON
  // ==========================================

  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onTap,
    Color background = const Color(0x66000000),
  }) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 19,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SETTING TILE
  // ==========================================

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF174D3A),
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .dividerColor
                .withOpacity(0.12),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          leading: Icon(
            icon,
            color: iconColor,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(
            Icons.chevron_right_rounded,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

// ==========================================
// EDIT NAME DIALOG
// ==========================================

class EditNameDialog extends StatefulWidget {
  final String initialName;

  const EditNameDialog({
    super.key,
    required this.initialName,
  });

  @override
  State<EditNameDialog> createState() =>
      _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();

    if (value.isEmpty) return;

    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Account name',
          hintText: 'Enter your name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
