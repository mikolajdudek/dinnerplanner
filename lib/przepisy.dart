import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Przepisy extends StatelessWidget {
  Przepisy({Key? key});

  FirebaseFirestore db = FirebaseFirestore.instance;

  void removeData(String docId) {
    db.collection("przepisy").doc(docId).delete().then((_) {
      print("Usunięto dokument o ID: $docId");
    }).catchError((error) {
      print("Błąd podczas usuwania dokumentu: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Przepisy'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('przepisy').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Wystąpił błąd: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          // Jeśli dane są dostępne, możesz je wyświetlić
          final przepisy = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: przepisy.length,
            itemBuilder: (context, index) {
              final przepis = przepisy[index].data() as Map<String, dynamic>;
              final nazwaPotrawy = przepis['NazwaPotrawy'] ?? '';

              List<dynamic> skladniki = przepis['Skladniki'] ?? [''];
              List<dynamic> gram = przepis['Gramatura'] ?? [''];

              // Tworzymy listę składników i gramatury w formacie nazwa + gramatura
              List<String> skladnikiGram = [];
              for (int i = 0; i < skladniki.length; i++) {
                String skladnik = skladniki[i].toString();
                String gramatura = gram[i].toString();
                skladnikiGram.add('$skladnik $gramatura' + 'g');
              }

              // Łączymy elementy listy w jeden tekst, oddzielając je spacjami
              String skladnikiGramText = skladnikiGram.join('\n');

              return ListTile(
                leading: IconButton(
                  icon: Icon(Icons.delete), // Przykładowa ikona usuwania
                  onPressed: () {
                    // Tutaj możesz dodać obsługę przycisku usuwania
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Opcje'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text('Usuń'),
                                onTap: () {
                                  // Obsłuż akcję usuwania
                                  String docId = przepisy[index].id; // Pobierz ID dokumentu
                                  removeData(docId); // Przekazujemy ID dokumentu do usunięcia
                                  Navigator.pop(context); // Zamknij AlertDialog
                                },
                              ),
                              ListTile(
                                title: Text('Edytuj'),
                                onTap: () {
                                  // Obsłuż akcję edycji
                                  Navigator.pop(context); // Zamknij AlertDialog
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                title: Text(nazwaPotrawy),
                subtitle: Text(skladnikiGramText), // Wyświetlamy składniki i gramaturę w jednym polu
              );
            },
            scrollDirection: Axis.vertical,
          );
        },
      ),
    );
  }
}
