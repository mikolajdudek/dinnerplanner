import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dinnerplanner/przepisy.dart';
import 'package:dinnerplanner/shopitem.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'addingdinnerplans.dart';


void main() async {
  //WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Planer obiadowy'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> recipeNames = [];
  String selectedRecipe = ''; // Początkowo ustawiamy na pustą wartość

  String selectedDay = 'Poniedziałek'; // Domyślnie wybrany dzień tygodnia

  List<String> daysOfWeek = [
    'Poniedziałek',
    'Wtorek',
    'Środa',
    'Czwartek',
    'Piątek',
    'Sobota',
    'Niedziela',
  ];

  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Pobierz nazwy potraw z bazy Firebase Firestore
    db.collection('przepisy').get().then((querySnapshot) {
      setState(() {
        recipeNames = querySnapshot.docs.map((doc) => doc['NazwaPotrawy'] as String).toList();
        // Dodajmy specjalny element do listy, który oznacza brak wyboru
        recipeNames.insert(0, 'Brak wyboru');
        selectedRecipe = recipeNames[0]; // Ustaw początkową wartość
      });
    });
  }

  void _showDialog(BuildContext context) {
    // Usunięcie dishNameController, ponieważ będziemy wybierać potrawę z istniejących przepisów
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Zaplanuj obiad!'),
              contentPadding: EdgeInsets.all(20.0),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Dropdown z wyborem przepisu
                    DropdownButton<String>(
                      value: recipeNames.contains(selectedRecipe) ? selectedRecipe : null,
                      onChanged: (newValue) {
                        db.collection('przepisy').get().then((querySnapshot) {
                          setState(() {
                            recipeNames = querySnapshot.docs.map((doc) => doc['NazwaPotrawy'] as String).toList();
                          });
                        });
                        setState(() {
                          selectedRecipe = newValue.toString();
                        });
                      },
                      items: recipeNames.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      hint: const Text('Wybierz przepis'),
                    ),
                    SizedBox(height: 20),
                    DropdownButton<String>(
                      value: selectedDay,
                      onChanged: (newValue) {
                        setState(() {
                          selectedDay = newValue!;
                        });
                      },
                      items: daysOfWeek.map<DropdownMenuItem<String>>(
                            (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        },
                      ).toList(),
                      hint: Text('Wybierz dzień tygodnia'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: Text('Anuluj'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Zatwierdź'),
                  onPressed: () {
                    if (selectedRecipe != 'Brak wyboru') {
                      print('Wybrano potrawę: $selectedRecipe');
                    } else {
                      print('Nie wybrano żadnej potrawy.');
                    }

                    // Przykładowa struktura danych do Firebase
                    final newRecipe = <String, dynamic>{
                      'Dzień': selectedDay,
                      'NazwaPotrawy': selectedRecipe, // Wybrany przepis
                    };

                    // Tu dodaj kod zapisujący nowy przepis do bazy danych
                    // Add a new document with a generated ID
                    FirebaseFirestore.instance.collection("dinner").add(newRecipe).then((DocumentReference doc) =>
                        print('DocumentSnapshot added with ID: ${doc.id}'));

                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }



  void removeData(String docId){
    db.collection("dinner").doc(docId).delete();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Lista Obiadów'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20.0),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('dinner').snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Wystąpił błąd: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  // Wyświetl listę obiadów w formie kafelków
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Ilość kafelków w jednym wierszu
                    ),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      DocumentSnapshot document = snapshot.data!.docs[index];
                      Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                      // Pobierz nazwę dnia i nazwę potrawy
                      String day = data['Dzień'] ?? '';
                      String dishName = data['NazwaPotrawy'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          // Po kliknięciu w kafelek wyświetl wszystkie dane w ExpansionTile
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Czy na pewno usunąć?'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: Text('Usuń'),
                                      onTap: () {
                                        // Obsłuż akcję usuwania
                                        removeData(document.id);
                                        Navigator.pop(context); // Zamknij AlertDialog
                                        // Wywołaj funkcję do usuwania danych
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Card(
                          elevation: 2.0,
                          margin: EdgeInsets.all(10.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$day'.toUpperCase()),
                                const SizedBox(height: 10,),
                                Text('Potrawa: $dishName'),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showDialog(context);
        },
        tooltip: 'Planuj obiad na kolejne dni',
        label: Text("Zaplanuj obiady"),
        icon: const Icon(Icons.add),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text('Baza przepisów'),
              onTap: () {
                Navigator.pop(context); // Zamknij menu
                Navigator.push(context, MaterialPageRoute(builder: (context) => Przepisy()));
              },
            ),
            ListTile(
              title: Text('Dodaj nowy przepis'),
              onTap: () {
                Navigator.pop(context); // Zamknij menu
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddingDinnerPlansScreen()));
              },
            ),
            ListTile(
              title: Text('Stwórz listę zakupową'),
              onTap: () {
                Navigator.pop(context); // Zamknij menu
                Navigator.push(context, MaterialPageRoute(builder: (context) => ShopItemPage()));
              },
            ),
            // Dodaj inne pozycje menu tutaj
          ],
        ),
      ),
    );
  }
}
