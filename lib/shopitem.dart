import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class ShopItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ShopItemPage(),
    );
  }
}

class ShopItemPage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<ShopItemPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<String> selectedDishes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista Potraw'),
      ),
      body: StreamBuilder(
        stream: firestore.collection('przepisy').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Wystąpił błąd: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Text('Brak dostępnych potraw.');
          } else {
            final dishes = snapshot.data!.docs;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: dishes.length,
                    itemBuilder: (context, index) {
                      final dish = dishes[index].data();
                      final dishName = dish['NazwaPotrawy'] ?? '';
                      final skladniki = dish['Skladniki'] as List<dynamic>;
                      final gramatura = dish['Gramatura'] as List<dynamic>;

                      // Tworzenie listy składników i gramatury w jednym polu
                      final skladnikiGram = List.generate(
                        skladniki.length,
                            (i) => '${skladniki[i]} ${gramatura[i]}g',
                      ).join('\n');

                      return ListTile(
                        title: Text(dishName),
                        subtitle: Text(skladnikiGram),
                        trailing: Checkbox(
                          value: selectedDishes.contains(dishName),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedDishes.add(dishName);
                              } else {
                                selectedDishes.remove(dishName);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _exportSelectedDishes();
                  },
                  child: Text('Eksport'),
                ),
                SizedBox(height: 50,)
              ],
            );
          }
        },
      ),
    );
  }

  void shareData(String data) {
    Share.share(data, subject: 'Zakupy');
  }

  void _exportSelectedDishes() async {
    final selectedDishesData = await Future.wait(
      selectedDishes.map((dishName) async {
        final querySnapshot = await firestore.collection('przepisy').where('NazwaPotrawy', isEqualTo: dishName).get();
        if (querySnapshot.docs.isNotEmpty) {
          final dish = querySnapshot.docs.first.data();
          final skladniki = dish['Skladniki'] as List<dynamic>;
          final gramatura = dish['Gramatura'] as List<dynamic>;
          return {
            'Potrawa': dishName,
            'Składniki': skladniki,
            'Gramatura': gramatura,
          };
        } else {
          return null;
        }
      }),
    );

    final validDishesData = selectedDishesData.where((data) => data != null).toList();

    // Tworzenie ciągu znaków z eksportowanymi danymi
    final exportString = validDishesData.map((data) {
      final dishName = data?['Potrawa'];
      final skladniki = data?['Składniki'] as List<dynamic>;
      final gramatura = data?['Gramatura'] as List<dynamic>;

      // Tworzenie listy składników i gramatury w jednym polu
      final skladnikiGram = List.generate(
        skladniki.length,
            (i) => '${skladniki[i]} ${gramatura[i]}g',
      ).join('\n');

      return 'Potrawa: $dishName\n$skladnikiGram\n';
    }).join('\n');

    // Teraz możesz zapisać `exportString` do pliku lub go wyświetlić w aplikacji
    print(exportString);
    shareData(exportString);
  }

}
