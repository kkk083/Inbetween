import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';
import '../../utils/constants.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  
  late String _selectedCategory;
  late String _selectedCondition;
  List<String> _existingImageUrls = [];
  List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _selectedCategory = widget.product.category;
    _selectedCondition = widget.product.condition;
    _existingImageUrls = List.from(widget.product.imageUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
      if (images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images);
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

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajoute au moins une photo'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final storageService = StorageService();
        final firestoreService = FirestoreService();

        List<String> finalImageUrls = List.from(_existingImageUrls);

        if (_newImages.isNotEmpty) {
          List<File> newImageFiles = _newImages.map((xFile) => File(xFile.path)).toList();
          List<String> uploadedUrls = await storageService.uploadProductImages(
            newImageFiles,
            widget.product.id,
          );
          finalImageUrls.addAll(uploadedUrls);
        }

        await firestoreService.updateProduct(widget.product.id, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'category': _selectedCategory,
          'condition': _selectedCondition,
          'imageUrls': finalImageUrls,
        });

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produit modifié avec succès ! ✅'),
              backgroundColor: Colors.green,
            ),
          );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le produit'),
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
                    const Text(
                      'Photos actuelles',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_existingImageUrls.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImageUrls.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(_existingImageUrls[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _removeExistingImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    if (_newImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Nouvelles photos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: FutureBuilder<Uint8List>(
                                    future: _newImages[index].readAsBytes(),
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
                                    onTap: () => _removeNewImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Ajouter des photos'),
                    ),

                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Titre'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Entre un titre';
                        if (value.length < 3) return 'Minimum 3 caractères';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Entre une description';
                        if (value.length < 10) return 'Minimum 10 caractères';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix (Rs)',
                        prefixText: 'Rs ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Entre un prix';
                        if (double.tryParse(value) == null) return 'Prix invalide';
                        if (double.parse(value) <= 0) return 'Le prix doit être positif';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                      items: AppConstants.categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
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
                      decoration: const InputDecoration(labelText: 'État'),
                      items: AppConstants.conditions.map((cond) {
                        return DropdownMenuItem(value: cond, child: Text(cond));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCondition = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}