import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../models/product_model.dart';
import '../../utils/constants.dart';
import '../product/product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        favoriteProvider.listenToFavoriteProducts(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'Rs ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
      ),
      body: favoriteProvider.favoriteProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun favori pour le moment',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoute des produits à tes favoris !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: favoriteProvider.favoriteProducts.length,
              itemBuilder: (context, index) {
                final product = favoriteProvider.favoriteProducts[index];
                return _buildProductCard(product, currencyFormat);
              },
            ),
    );
  }

  Widget _buildProductCard(ProductModel product, NumberFormat currencyFormat) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: product.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrls[0],
                            fit: BoxFit.cover,
                            memCacheWidth: 400,
                            memCacheHeight: 400,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(Icons.broken_image, color: Colors.grey[400]),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<FavoriteProvider>(
                      builder: (context, favoriteProvider, _) {
                        return GestureDetector(
                          onTap: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            favoriteProvider.toggleFavorite(authProvider.currentUser!.id, product.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormat.format(product.price),
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.condition,
                                style: TextStyle(
                                  color: AppConstants.textSecondary,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}