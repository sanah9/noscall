import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/account/account.dart';
import '../core/account/account+profile.dart';
import '../core/account/model/userDB_isar.dart';
import '../contacts/user_avatar.dart';
import '../utils/toast.dart';
import '../utils/file_upload_manager.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  UserDBISAR? _user;
  bool _isLoading = false;
  File? _selectedAvatarFile;

  late ThemeData theme;
  Color get primary => theme.colorScheme.primary;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get onPrimary => theme.colorScheme.onPrimary;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    _isLoading = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        final user = Account.sharedInstance.me;
        if (user != null) {
          setState(() {
            _user = user;
            _nameController.text = user.displayName();
            _aboutController.text = user.about ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          AppToast.showError(context, 'Failed to load user data');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        AppToast.showError(context, 'Failed to load user data: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);

    if (_isLoading && _user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile Settings'),
          backgroundColor: primary,
          foregroundColor: onPrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile Settings'),
          backgroundColor: primary,
          foregroundColor: onPrimary,
        ),
        body: const Center(
          child: Text('Failed to load user data'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: primary,
        foregroundColor: onPrimary,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 20),
            _buildAvatarSection(),
            const SizedBox(height: 32),
            _buildNameField(),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return GestureDetector(
      onTap: _showImagePickerDialog,
      child: _selectedAvatarFile != null
          ? CircleAvatar(
              radius: 40,
              backgroundImage: FileImage(_selectedAvatarFile!),
            )
          : UserAvatar(
              user: _user!,
              radius: 40,
            ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Display Name',
        hintText: 'Enter your display name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      maxLength: 50,
    );
  }



  Future<bool> _ensurePermission(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) return true;
    final requested = await permission.request();
    if (requested.isGranted) return true;
    if (requested.isPermanentlyDenied) {
      AppToast.showError(context, 'Permission denied. Please enable it in Settings.');
      await openAppSettings();
    }
    return false;
  }

  Future<void> _pickFromGallery() async {
    final ok = Platform.isIOS
        ? await _ensurePermission(Permission.photos)
        : await _ensurePermission(Permission.storage);
    if (!ok) return;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (image != null) {
        setState(() {
          _selectedAvatarFile = File(image.path);
        });
      }
    } catch (e) {
      AppToast.showError(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    final ok = await _ensurePermission(Permission.camera);
    if (!ok) return;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (image != null) {
        setState(() {
          _selectedAvatarFile = File(image.path);
        });
      }
    } catch (e) {
      AppToast.showError(context, 'Failed to take photo: $e');
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      AppToast.showError(context, 'Name cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? pictureUrl = _user!.picture;

      // Upload avatar if selected
      if (_selectedAvatarFile != null) {
        AppToast.showInfo(context, 'Uploading avatar...');

        // Check file type
        if (!FileUploadManager.isSupportedFileType(_selectedAvatarFile!.path)) {
          AppToast.showError(context, 'Unsupported file type');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Check file size
        final fileSize = await _selectedAvatarFile!.length();
        if (fileSize > 50 * 1024 * 1024) { // 50 MiB
          AppToast.showError(context, 'File size exceeds 50 MiB limit');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Upload file
        final uploadedUrl = await FileUploadManager.uploadImage(_selectedAvatarFile!);
        if (uploadedUrl != null) {
          pictureUrl = uploadedUrl;
          AppToast.showSuccess(context, 'Avatar uploaded successfully');
        } else {
          AppToast.showError(context, 'Failed to upload avatar');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Create updated user data
      final updatedUser = UserDBISAR(
        pubKey: _user!.pubKey,
        name: _nameController.text.trim(),
        about: _aboutController.text.trim(),
        picture: pictureUrl,
        // Copy other existing fields
        encryptedPrivKey: _user!.encryptedPrivKey,
        privkey: _user!.privkey,
        defaultPassword: _user!.defaultPassword,
        nickName: _user!.nickName,
        mainRelay: _user!.mainRelay,
        dns: _user!.dns,
        lnurl: _user!.lnurl,
        badges: _user!.badges,
        gender: _user!.gender,
        area: _user!.area,
        banner: _user!.banner,
        aliasPubkey: _user!.aliasPubkey,
        toAliasPubkey: _user!.toAliasPubkey,
        toAliasPrivkey: _user!.toAliasPrivkey,
        friendsList: _user!.friendsList,
        blockedList: _user!.blockedList,
        blockedHashTags: _user!.blockedHashTags,
        blockedThreads: _user!.blockedThreads,
        blockedWords: _user!.blockedWords,
        followersList: _user!.followersList,
        followingList: _user!.followingList,
        relayList: _user!.relayList,
        dmRelayList: _user!.dmRelayList,
        inboxRelayList: _user!.inboxRelayList,
        outboxRelayList: _user!.outboxRelayList,
        mute: _user!.mute,
        lastUpdatedTime: _user!.lastUpdatedTime,
        lastBlockListUpdatedTime: _user!.lastBlockListUpdatedTime,
        lastFriendsListUpdatedTime: _user!.lastFriendsListUpdatedTime,
        lastRelayListUpdatedTime: _user!.lastRelayListUpdatedTime,
        lastFollowingListUpdatedTime: _user!.lastFollowingListUpdatedTime,
        lastDMRelayListUpdatedTime: _user!.lastDMRelayListUpdatedTime,
        otherField: _user!.otherField,
        nwcURI: _user!.nwcURI,
        remoteSignerURI: _user!.remoteSignerURI,
        clientPrivateKey: _user!.clientPrivateKey,
        remotePubkey: _user!.remotePubkey,
        settings: _user!.settings,
      );

      // Update profile using Account.sharedInstance.updateProfile (extension method)
      final result = await Account.sharedInstance.updateProfile(updatedUser);

      if (result != null) {
        setState(() {
          _user = result;
          _selectedAvatarFile = null; // Clear selected file after successful upload
          _isLoading = false;
        });
        AppToast.showSuccess(context, 'Profile updated successfully');
        context.pop();
      } else {
        setState(() {
          _isLoading = false;
        });
        AppToast.showError(context, 'Failed to update profile');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppToast.showError(context, 'Failed to update profile: $e');
    }
  }
}