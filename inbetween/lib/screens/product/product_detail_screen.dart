import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../utils/constants.dart';
import '../product/edit_product_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadProduct(widget.productId);
    });
    
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }

  Future<void> _callSeller(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'appeler ce numéro')),
        );
      }
    }
  }

  Future<void> _whatsappSeller(String phoneNumber, String productTitle) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final whatsappNumber = cleanNumber.startsWith('230') ? cleanNumber : '230$cleanNumber';
    
    final message = Uri.encodeComponent(
      'Bonjour, je suis intéressé(e) par "$productTitle" sur Inbetween.'
    );
    final Uri url = Uri.parse('https://wa.me/$whatsappNumber?text=$message');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'Rs ');

    if (productProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final product = productProvider.selectedProduct;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Produit introuvable')),
      );
    }

    final isMyProduct = product.sellerId == authProvider.currentUser?.id;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: product.imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          product.imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 80),
                              ),
                            );
                          },
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_outlined, size: 80),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.imageUrls.length > 1)
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          product.imageUrls.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? AppConstants.primaryColor
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  Text(
                    currencyFormat.format(product.price),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _buildInfoChip(Icons.check_circle_outline, product.condition),
                      const SizedBox(width: 8),
                      _buildInfoChip(Icons.category_outlined, product.category),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Publié ${timeago.format(product.createdAt, locale: 'fr')}',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                    ),
                  ),

                  const Divider(height: 32),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const Divider(height: 32),

                  const Text(
                    'Vendeur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppConstants.primaryColor,
                      child: Text(
                        product.sellerName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      product.sellerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Membre Inbetween'),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: isMyProduct
          ? _buildOwnerActions(product)
          : _buildBuyerActions(product, authProvider),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppConstants.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerActions(ProductModel product) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Bouton Modifier
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProductScreen(product: product),
                        ),
                      );
                      
                      if (result == true && mounted) {
                        // Recharger le produit
                        productProvider.loadProduct(product.id);
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: product.isAvailable ? () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Marquer comme vendu'),
                          content: const Text('Ce produit ne sera plus visible dans les annonces.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Confirmer'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        await productProvider.markAsSold(product.id);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Produit marqué comme vendu'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } : null,
                    icon: const Icon(Icons.check),
                    label: Text(product.isAvailable ? 'Marquer vendu' : 'Vendu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer le produit'),
                          content: const Text('Cette action est irréversible.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        await productProvider.deleteProduct(product.id, product.imageUrls);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Produit supprimé'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerActions(ProductModel product, AuthProvider authProvider) {
    final sellerPhone = authProvider.currentUser?.phoneNumber ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callSeller(sellerPhone),
                icon: const Icon(Icons.phone),
                label: const Text('Appeler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _whatsappSeller(sellerPhone, product.title),
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}