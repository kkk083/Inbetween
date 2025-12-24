import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _universityController;
  
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _universityController = TextEditingController(text: user?.university ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? profilePicUrl;

        // Upload nouvelle photo si sélectionnée
        if (_selectedImage != null) {
          final storageService = StorageService();
          profilePicUrl = await storageService.uploadProfilePicture(
            File(_selectedImage!.path),
            authProvider.currentUser!.id,
          );
        }

        // Mettre à jour le profil
        bool success = await authProvider.updateProfile(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          university: _universityController.text.trim().isEmpty 
              ? null 
              : _universityController.text.trim(),
          profilePicUrl: profilePicUrl,
        );

        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil mis à jour avec succès ! ✅'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Erreur lors de la mise à jour'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo de profil
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            child: _selectedImage != null
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return ClipOval(
                                          child: Image.memory(
                                            snapshot.data!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }
                                      return const CircularProgressIndicator();
                                    },
                                  )
                                : user.profilePicUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          user.profilePicUrl!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Text(
                                        user.name[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 40,
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.photo_library),
                                            title: const Text('Galerie'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _pickImage();
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.camera_alt),
                                            title: const Text('Prendre une photo'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _takePhoto();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nom
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Entre ton nom';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Entre ton numéro de téléphone';
                        }
                        if (value.length < 8) {
                          return 'Numéro invalide';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Université
                    TextFormField(
                      controller: _universityController,
                      decoration: const InputDecoration(
                        labelText: 'Université (optionnel)',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Email (non modifiable)
                    TextFormField(
                      initialValue: user.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        helperText: 'L\'email ne peut pas être modifié',
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton enregistrer
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}