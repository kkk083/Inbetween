import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/constants.dart';
import '../../utils/image_helper.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onProductAdded;
  
  const AddProductScreen({super.key, this.onProductAdded});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedCategory = AppConstants.categories[0];
  String _selectedCondition = AppConstants.conditions[0];
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 50,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajoute au moins une photo de ton produit'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      List<File> imageFiles = _selectedImages.map((xFile) => File(xFile.path)).toList();
      List<File> compressedFiles = await ImageHelper.compressImages(imageFiles);

      bool success = await productProvider.createProduct(
        sellerId: authProvider.currentUser!.id,
        sellerName: authProvider.currentUser!.name,
        sellerPhone: authProvider.currentUser!.phoneNumber, // ✅ NOUVEAU
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        condition: _selectedCondition,
        images: compressedFiles,
      );

      if (success && mounted) {
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        setState(() {
          _selectedImages = [];
          _selectedCategory = AppConstants.categories[0];
          _selectedCondition = AppConstants.conditions[0];
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Produit publié avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted && widget.onProductAdded != null) {
          widget.onProductAdded!();
        }
        
      } else if (mounted) {
        setState(() {
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.errorMessage ?? 'Erreur lors de la publication'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendre un produit'),
        automaticallyImplyLeading: false,
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Publication en cours...',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload des images...',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Photos du produit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoute jusqu\'à 5 photos pour attirer plus d\'acheteurs',
                      style: TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_selectedImages.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: FutureBuilder<Uint8List>(
                                    future: _selectedImages[index].readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galerie'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Caméra'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre du produit',
                        hintText: 'Ex: iPhone 13 Pro Max',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Entre un titre pour ton produit';
                        }
                        if (value.length < 3) {
                          return 'Le titre doit avoir au moins 3 caractères';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Décris ton produit en détail...',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Entre une description';
                        }
                        if (value.length < 10) {
                          return 'La description doit avoir au moins 10 caractères';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix (Rs)',
                        hintText: 'Ex: 5000',
                        prefixText: 'Rs ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Entre le prix de ton produit';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Entre un prix valide';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Le prix doit être supérieur à 0';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                      ),
                      items: AppConstants.categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'État du produit',
                      ),
                      items: AppConstants.conditions.map((condition) {
                        return DropdownMenuItem(
                          value: condition,
                          child: Text(condition),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCondition = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _submitProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Publier le produit',
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