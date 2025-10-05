import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'recipe_details.dart';
class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> favoriteRecipes = [];
  int selectedTab = 0; // 0 = All, 1 = Recently Added

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favorites = prefs.getStringList('favoriteRecipes');
    if (favorites != null) {
      setState(() {
        favoriteRecipes = favorites
            .map((recipeJson) => jsonDecode(recipeJson) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  void removeFromFavorites(Map<String, dynamic> recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favorites = prefs.getStringList('favoriteRecipes');
    if (favorites != null) {
      final recipeJson = jsonEncode(recipe);
      favorites.remove(recipeJson);
      await prefs.setStringList('favoriteRecipes', favorites);
      loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.green[600],
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Favorite Recipes', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {
                // TODO: Sort/filter action
              },
            ),
            SizedBox(width: 10),
          ],
        ),
      ),
      body: Column(
        children: [
          // Segmented control/tabs
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _segmentButton('All Favorites', 0),
                _segmentButton('Recently Added', 1),
                Spacer(),
                // Add more filters/categories here if needed
              ],
            ),
          ),
          Expanded(
            child: favoriteRecipes.isEmpty
                ? Center(child: Text('No favorites yet.', style: TextStyle(fontSize: 18)))
                : GridView.builder(
                    padding: const EdgeInsets.all(10.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: favoriteRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = favoriteRecipes[index];
                      return _favoriteCard(recipe, context);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, int index) {
    final selected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
          // You can add logic to filter/sort here
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green[600] : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _favoriteCard(Map<String, dynamic> recipe, BuildContext context) {
    return
    GestureDetector(
      onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsPage(recipe: recipe),
      ),
    );
  },
       child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 4,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: recipe['image'] != null
                    ? Stack(
                        children: [
                          Image.network(
                            recipe['image'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.image, size: 38, color: Colors.grey),
                            ),
                          ),
                          Container(
                            alignment: Alignment.bottomLeft,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black38],
                                stops: [0.6, 1.0],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                recipe['title'] ?? 'Recipe',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ]),
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Center(child: Icon(Icons.image, size: 38, color: Colors.grey)),
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8, top: 12),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 15, color: Colors.green[600]),
                      SizedBox(width: 4),
                      Text(
                        '${recipe['readyInMinutes'] ?? '--'} min',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.favorite, color: Colors.redAccent, size: 22),
                        onPressed: () => removeFromFavorites(recipe),
                        tooltip: 'Remove from Favorites',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6),
              ],
            ),
            // Optionally add interactive overlay buttons for share/more if wanted
          ],
        ),
           ),
     );
  }
}
