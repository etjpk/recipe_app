import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'secrets.dart';
Future<void> saveToFavorites(Map<String, dynamic> recipe) async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> favorites = prefs.getStringList('favoriteRecipes') ?? [];
  final recipeJson = jsonEncode(recipe);
  if (!favorites.contains(recipeJson)) {
    favorites.add(recipeJson);
    await prefs.setStringList('favoriteRecipes', favorites);
  }
}

class RecipeDetailsPage extends StatefulWidget {
  final Map<String, dynamic> recipe;
  const RecipeDetailsPage({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  Map<String, dynamic>? recipeInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecipeDetails();
  }

  Future<void> fetchRecipeDetails() async {
    final id = widget.recipe['id'];
    final url = Uri.parse(
  'https://api.spoonacular.com/recipes/$id/information?apiKey=${Secrets.SPOONACULAR_API_KEY}'
);

    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        recipeInfo = json.decode(response.body) as Map<String, dynamic>?;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = recipeInfo?['image'] as String?;
    final nutrition = recipeInfo?['nutrition'];
    String? calories;
    if (nutrition is Map && nutrition['nutrients'] is List && (nutrition['nutrients'] as List).isNotEmpty) {
      try {
        final found = (nutrition['nutrients'] as List).firstWhere(
          (n) => n is Map && n['name'] == 'Calories',
          orElse: () => (nutrition['nutrients'] as List)[0],
        );
        calories = (found is Map) ? (found['amount']?.toString()) : null;
      } catch (_) {
        calories = null;
      }
    }
    final ingredients = (recipeInfo?['extendedIngredients'] is List)
        ? List.from(recipeInfo!['extendedIngredients'] as List)
        : <dynamic>[];

    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : recipeInfo == null
              ? Center(child: Text('No details found.'))
              : Stack(
                  children: [
                    // Main Scrollable Body (under header)
                    CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          expandedHeight: 280,
                          flexibleSpace: FlexibleSpaceBar(
                            background: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, error, stack) =>
                                        Container(
                                          color: Colors.grey[300],
                                          child: Icon(Icons.broken_image, size: 70),
                                        ),
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image_not_supported, size: 70),
                                  ),
                          ),
                          leading: IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          actions: [
                            IconButton(
                              icon: Icon(Icons.share, color: Colors.white),
                              onPressed: () {},
                            ),
                          ],
                          backgroundColor: Colors.orange[400],
                          elevation: 0,
                        ),
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Floating Title and Favorite Button
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
                                child: Material(
                                  borderRadius: BorderRadius.circular(15),
                                  elevation: 4,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            recipeInfo!['title'] ?? '',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            saveToFavorites(recipeInfo!);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Recipe saved to favorites!')),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                          child: Text('Add to Favorites'),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Pills for Stats
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    if (recipeInfo!['readyInMinutes'] != null)
                                      _pill(Icons.timer, '${recipeInfo!['readyInMinutes']} min', Colors.green.shade100, Colors.green.shade700),
                                    if (recipeInfo!['vegetarian'] != null)
                                      _pill(Icons.eco, recipeInfo!['vegetarian'] ? 'Vegetarian' : 'Non-Vegetarian', Colors.yellow.shade100, Colors.orange.shade800),
                                    if (recipeInfo!['pricePerServing'] != null)
                                      _pill(Icons.attach_money, 'Price: ₹${recipeInfo!['pricePerServing']}', Colors.purple.shade100, Colors.purple.shade700),
                                    if (calories != null)
                                      _pill(Icons.local_fire_department, 'Calories: $calories', Colors.red.shade50, Colors.red.shade700),
                                    if (recipeInfo!['vegan'] == true)
                                      _pill(Icons.spa, 'Vegan', Colors.green.shade50, Colors.green.shade900),
                                    if (recipeInfo!['glutenFree'] == true)
                                      _pill(Icons.no_food, 'Gluten Free', Colors.blue.shade50, Colors.blue.shade900),
                                    if (recipeInfo!['dairyFree'] == true)
                                      _pill(Icons.icecream, 'Dairy Free', Colors.cyan.shade50, Colors.cyan.shade900),
                                    if (recipeInfo!['healthScore'] != null)
                                      _pill(Icons.healing, 'Health Score: ${recipeInfo!['healthScore']}', Colors.teal.shade50, Colors.teal.shade900),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              // Ingredients Section
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text('Ingredients',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                    )),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Material(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.orange[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: ingredients.map<Widget>((ing) {
                                        if (ing is Map) {
                                          return Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: Colors.orange.shade400, size: 22),
                                              SizedBox(width: 10),
                                              Expanded(child: Text(ing['original'] ?? ing['name'] ?? '', style: TextStyle(fontSize: 15))),
                                            ],
                                          );
                                        }
                                        return Text(ing.toString());
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              // Instructions Section
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text('Instructions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                    )),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                                child: Material(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey.shade100,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15),
                                    child: _buildInstructions(recipeInfo!['instructions']),
                                  ),
                                ),
                              ),
                              SizedBox(height: 70),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  // Widget to display info pills
  Widget _pill(IconData icon, String label, Color bgColor, Color iconColor) {
    return Container(
      margin: EdgeInsets.only(right: 10),
      child: Chip(
        avatar: Icon(icon, color: iconColor, size: 18),
        backgroundColor: bgColor,
        label: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: iconColor)),
        padding: EdgeInsets.symmetric(vertical: 3, horizontal: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }

  Widget _buildInstructions(String? instructions) {
    if (instructions == null || instructions.trim().isEmpty)
      return Text('No instructions found.');
    // Split by "." or by line
    final steps = instructions.split(RegExp(r'[\.\n]+')).where((s) => s.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Expanded(child: Text(steps[i].trim())),
              ],
            ),
          )
      ],
    );
  }
}
