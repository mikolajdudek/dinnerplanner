import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddingDinnerPlansScreen extends StatefulWidget {
  const AddingDinnerPlansScreen({super.key});

  @override
  _AddingDinnerPlansScreenState createState() =>
      _AddingDinnerPlansScreenState();
}

class _AddingDinnerPlansScreenState extends State<AddingDinnerPlansScreen> {
  List<TextEditingController> ingredientControllers = [];
  List<TextEditingController> gramsControllers = [];
  TextEditingController dishNameController = TextEditingController();

  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dodawanie przepisów do bazy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: ingredientControllers.length + 1, // +1 dla pola nazwy potrawy
          itemBuilder: (context, index) {
            if (index == 0) {
              // Pierwszy element - pole nazwy potrawy
              return TextField(
                controller: dishNameController,
                decoration: InputDecoration(
                  labelText: 'Nazwa potrawy',
                ),
              );
            } else {
              // Kolejne elementy - pola składnika i gramatury
              final ingredientController =
              ingredientControllers[index - 1]; // Odejmujemy 1, bo pierwszy element to pole nazwy potrawy
              final gramsController = gramsControllers[index - 1];
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ingredientController,
                      decoration: InputDecoration(
                        labelText: 'Składnik',
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: TextField(
                      controller: gramsController,
                      decoration: InputDecoration(
                        labelText: 'Gramatura',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        // Usuwanie pola składnika i gramatury
                        ingredientControllers.removeAt(index - 1);
                        gramsControllers.removeAt(index - 1);
                      });
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            left: 36.0,
            bottom: 16.0,
            child: FloatingActionButton(
              heroTag: 'btn1',
              onPressed: () {
                setState(() {
                  // Dodawanie nowego pola składnika i gramatury
                  ingredientControllers.add(TextEditingController());
                  gramsControllers.add(TextEditingController());
                });
              },
              child: Icon(Icons.add),
            ),
          ),
          Positioned(
            right: 16.0,
            bottom: 16.0,
            child: FloatingActionButton(
              heroTag: 'btn2',
              onPressed: () {
                // Obsługa przycisku na lewej dolnej stronie
                saveData(); // Wywołujemy funkcję do zapisu danych
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => AddingDinnerPlansScreen()),
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dodano potrawę')));
                },
              child: Icon(Icons.save),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose kontrolerów tekstowych, aby uniknąć wycieków pamięci
    dishNameController.dispose();
    ingredientControllers.forEach((controller) => controller.dispose());
    gramsControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void saveData() {
    List<String> ingredients =
    ingredientControllers.map((controller) => controller.text).toList();
    List<String> grams =
    gramsControllers.map((controller) => controller.text).toList();
    final dishName = dishNameController.text;

    // Przykładowa struktura danych do Firebase
    final newRecipe = <String, dynamic>{
      'NazwaPotrawy': dishName,
      'Skladniki': ingredients,
      'Gramatura': grams,
      // Tutaj przekazujemy listę z gramaturami
    };

    // Tu dodaj kod zapisujący nowy przepis do bazy danych
    // Add a new document with a generated ID
    db.collection("przepisy").add(newRecipe).then((DocumentReference doc) =>
        print('DocumentSnapshot added with ID: ${doc.id}'));
  }
}
