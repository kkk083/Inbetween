import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../utils/constants.dart';
import '../product/product_detail_screen.dart';
import '../product/add_product_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers/favorite_provider.dart';
import '../favorites/favorite_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'Tout';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      productProvider.listenToProducts();
      
      // ✅ NOUVEAU : Écoute les favoris de l'utilisateur
      if (authProvider.currentUser != null) {
        favoriteProvider.listenToFavorites(authProvider.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _selectedCategory = 'Tout';
    });
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (query.isEmpty) {
      productProvider.listenToProducts();
    } else {
      productProvider.searchProducts(query);
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
    });
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.filterByCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final List<Widget> pages = [
      _buildHomePage(productProvider),
      AddProductScreen(
        // ✅ CALLBACK: Appelé quand un produit est ajouté
        onProductAdded: () {
          setState(() {
            _currentIndex = 0; // Retour à l'onglet Home
            _selectedCategory = 'Tout'; // Reset le filtre
            _searchController.clear(); // Clear la recherche
          });
          // Le Stream détecte automatiquement le nouveau produit
        },
      ),
      ProfileScreen(userId: authProvider.currentUser!.id),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbetween'),
        automaticallyImplyLeading: false,
        actions: [
          // ✅ NOUVEAU : Bouton Favoris
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications à venir !')),
              );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppConstants.primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Vendre',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(ProductProvider productProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
            ),
            onChanged: _onSearch,
          ),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip('Tout'),
              ...AppConstants.categories.map((cat) => _buildCategoryChip(cat)),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: productProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : productProvider.products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedCategory == 'Tout'
                                ? 'Aucun produit disponible'
                                : 'Aucun produit dans "$_selectedCategory"',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (_selectedCategory != 'Tout')
                            TextButton.icon(
                              onPressed: () => _onCategorySelected('Tout'),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Voir tous les produits'),
                            )
                          else
                            Text(
                              'Sois le premier à publier !',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        productProvider.listenToProducts();
                        setState(() {
                          _selectedCategory = 'Tout';
                          _searchController.clear();
                        });
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: productProvider.products.length,
                        itemBuilder: (context, index) {
                          final product = productProvider.products[index];
                          return _buildProductCard(product);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'Rs ');

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
                  // Image du produit
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
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Image non disponible',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
                          ),
                  ),
                  
                  // ✅ NOUVEAU : Bouton Favoris en haut à droite
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<FavoriteProvider>(
                      builder: (context, favoriteProvider, _) {
                        final isFav = favoriteProvider.isFavorite(product.id);
                        
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.grey[700],
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