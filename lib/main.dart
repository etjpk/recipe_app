import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recipe_details.dart';
import 'favorites_page.dart';
import 'secrets.dart';



void main() => runApp(RecipeFinderApp());

class RecipeFinderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Finder',
      theme: ThemeData(primarySwatch: Colors.green),
      home: RecipeHomePage(),
    );
  }
}

class RecipeHomePage extends StatefulWidget {
  @override
  _RecipeHomePageState createState() => _RecipeHomePageState();
}

class _RecipeHomePageState extends State<RecipeHomePage> {
  List recipes = [];
  TextEditingController searchController = TextEditingController();

  Future<void> fetchRecipes(String query) async {
    final url = Uri.parse(
  'https://api.spoonacular.com/recipes/complexSearch?query=$query&apiKey=${Secrets.SPOONACULAR_API_KEY}'
);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        recipes = data['results'] ?? [];
      });
    } else {
      print('API Error: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Finder'),
        backgroundColor: Color.fromARGB(255, 34, 10, 27),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoritesPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient Header + Search
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Text(
                    'Hello Chef, What are you craving?',
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for recipes or ingredients...',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                      onSubmitted: (value) {
                        fetchRecipes(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Trending Recipes (Horizontal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text('Trending Recipes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Container(
              height: 230,
              child: recipes.isEmpty
                  ? Center(child: Text('No trending recipes.'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recipes.length > 8 ? 8 : recipes.length, // Show 8 trending
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailsPage(recipe: recipe),
                              ),
                            );
                          },
                          child: Container(
                            width: 155,
                            margin: EdgeInsets.all(8),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                                    child: recipe['image'] != null
                                        ? Image.network(
                                            recipe['image'],
                                            height: 110,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                              Image.asset('assets/image.png', height: 110, fit: BoxFit.cover),
                                          )
                                        : Image.asset('assets/image.png', height: 110, fit: BoxFit.cover),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(recipe['title'] ?? 'Recipe', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                                          Spacer(),
                                          Row(
                                            children: [
                                              Icon(Icons.timer, size: 16, color: Colors.grey),
                                              SizedBox(width: 4),
                                              Text(recipe['readyInMinutes']?.toString() ?? '-', style: TextStyle(fontSize: 13)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Cuisine/Diet Chips
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Text('Browse by Cuisine & Diet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 8),
                  Chip(label: Text('Italian'), backgroundColor: Colors.redAccent.shade100),
                  SizedBox(width: 8),
                  Chip(label: Text('Mexican'), backgroundColor: Colors.orangeAccent.shade100),
                  SizedBox(width: 8),
                  Chip(label: Text('Vegan'), backgroundColor: Colors.green.shade200),
                  SizedBox(width: 8),
                  Chip(label: Text('Gluten-Free'), backgroundColor: Colors.blue.shade100),
                  SizedBox(width: 8),
                ],
              ),
            ),
            // Main Results List (Vertical, below or after chips)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: recipes.isEmpty
                  ? Center(child: Text('No recipes found. Try searching!'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return Card(
                          child: ListTile(
                            title: Text(recipe['title'] ?? 'No Title'),
                            leading: recipe['image'] != null
                                ? Image.network(
                                    recipe['image'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                      (context, error, stackTrace) =>
                                        Image.asset('assets/image.png', width: 50, height: 50, fit: BoxFit.cover),
                                  )
                                : Image.asset(
                                    'assets/image.png',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailsPage(recipe: recipe),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 16)
          ],
        ),
      ),
    );
  }
}
