import 'package:babycare/routes.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'child_profile_form_screen.dart';
import 'child_profile_repository.dart';

class HomeScreen extends StatefulWidget {
  late User? user;

  HomeScreen({Key? key, required this.user}) :
        super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState(user: user);
}


class _HomeScreenState extends State<HomeScreen> {
  final ChildProfileRepository repository;
  late User? user;
  late Future<List<ChildProfile>> _childProfilesFuture;

  @override
  void initState() {
    super.initState();
    _loadProfiles(); // Ładowanie profili przy starcie
  }

  void _loadProfiles() {
    setState(() {
      _childProfilesFuture = repository.getChildProfiles(); // Future na dane
    });
  }

  _HomeScreenState({required this.user}) :
        this.repository = ChildProfileRepository();

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': "HomeScreen",
        'screen_class': "HomeScreen",
      },
    );

    repository.getChildProfiles()
    .asStream()
    .map((child) {
      return child;
    });
    return Scaffold(
      drawer: ApppDrawer(),
      appBar: AppBar(
        title: Text('Witaj, ${user?.email ?? user?.displayName}'),
      ),
      body: Center(child: ListView(
        padding: EdgeInsets.all(16.0),
        scrollDirection: Axis.vertical,
        children: [
          // Nagłówek
          Text(
            'Zalogowano pomyślnie!\n\nUID: ${user?.uid}',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          // StreamBuilder dla profili
          FutureBuilder<List<ChildProfile>>(
            future: _childProfilesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Wystąpił błąd: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                print("TR2");
                return Center(child: Text('Brak elementów do wyświetlenia.'));
              }

              if (snapshot.data!.isEmpty) {
                print("TR32");
              }

              return Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Wybierz profil dziecka",
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(height: 16),
                    StreamBuilder<List<Card>>(
                      stream: getChildProfileCards(context, snapshot.data!).asStream(),
                      builder: (context, cards) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Wystąpił błąd: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData) {
                          print("TR1");
                          return Center(child: Text('Brak elementów do wyświetlenia.'));
                        }

                        if (snapshot.data!.isEmpty) {

                          print("TR13");
                        }

                        return Column(children: [...?cards.data]);
                      },
                    ),
                  ],
                )
              );
            },
          ),
        ],
      ),
      )
    );
  }

  Future<List<Card>> getChildProfileCards(BuildContext context, List<ChildProfile> children) async {
    var cards = children.map<Card>((child) {
      return Card(
        shape: CircleBorder(),
        child: InkWell(
          onTap: () {
            print(Routes.child.replaceFirst(":id", child.id!));
            context.go(Routes.child.replaceFirst(":id", child.id!));
          },
          child: Padding(
            padding: EdgeInsets.all(30.0),
            child:
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.baby_changing_station_sharp, size: 70,),
                Text(
                  child.name ?? "",
                  style: TextStyle(
                    fontSize: 24, // Zmiana rozmiaru czcionki
                    fontWeight: FontWeight.bold, // Opcjonalnie pogrubienie
                  ),
                ),
              ],
            ),
          )
        )
      );
    }).toList();

    cards.add(
        Card(
          child: InkWell(
            onTap: () {
              context.go(Routes.newChild);
            },
            child:
            Padding(
              padding: EdgeInsets.all(30.0),
              child: Icon(Icons.add, size: 80)
            ),
          ),
          shape: CircleBorder(),
        )
    );
    return cards;
  }

}