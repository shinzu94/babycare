import 'package:babycare/child_profile_form_screen.dart';
import 'package:babycare/colors_schema.dart';
import 'package:babycare/diaper_change_repository.dart';
import 'package:babycare/routes.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'child_page_navigation_rail.dart';

class DiaperChangePageScreen extends StatefulWidget {
  String? id;

  DiaperChangePageScreen({Key? key, this.id}) :
        super(key: key);
  @override
  _DiaperChangePageScreenState createState() => _DiaperChangePageScreenState(id: this.id);
}

class _DiaperChangePageScreenState extends State<DiaperChangePageScreen> {
  _DiaperChangePageScreenState({this.id});
  String? id;
  bool _pee = false;
  bool _poop = false;
  DateTime? _timeOfChange;
  int _todayPeeCount = 0; // Licznik siku
  int _todayPoopCount = 0; // Licznik kupa

  BrandColorSchema brandColorSchema = BrandColorSchema();
  DiaperChangeRepository repository = DiaperChangeRepository();

  @override
  void initState() {
    super.initState();
    _fetchTodaySummary(); // Pobieranie danych podczas inicjalizacji ekranu
  }


  void _pickDateTime() async {
    var now = DateTime.now();
    var today = DateTime(now.year, now.month, now.day);
    var firstDate = today.subtract(Duration(days: 1));
    // Pokazanie okna wyboru daty
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: firstDate,
      lastDate: today,
    );

    if (pickedDate != null) {
      setState(() {
        _timeOfChange = pickedDate;
      });

      final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(now)
      );
      if (pickedTime != null) {
        setState(() {
          print("time");
          print(_timeOfChange);
          _timeOfChange = _timeOfChange?.add(
              Duration(hours: pickedTime.hour,
                  minutes: pickedTime.minute,
                  seconds: pickedTime.minute,
                  milliseconds: 0,
                  microseconds: 0)
          );

          print(Duration(hours: pickedTime.hour,
              minutes: pickedTime.minute,
              seconds: pickedTime.minute,
              milliseconds: 0,
              microseconds: 0));
          print(_timeOfChange);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': "DiaperChangePageScreen",
        'screen_class': "DiaperChangePageScreen",
      },
    );
    return Scaffold(
      drawer: ApppDrawer(),
      appBar: AppBar(
        title: Text("Przewijanie"),
      ),
      body: SafeArea(
          child: Row(
            children: [
              ChildPageNavigationRail(id: id,),
              VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: Column(
                  children: [
                    SwitchListTile(
                        value: _pee,
                        onChanged: (newValue){
                          setState(() {
                            _pee = newValue;
                          });
                        },
                      title: Text("Siku"),
                    ),
                    Divider(height: 1,),
                    SwitchListTile(
                      value: _poop,
                      onChanged: (newValue){
                        setState(() {
                          _poop = newValue;
                        });
                      },
                      title: Text("Kupa"),
                    ),
                    Divider(height: 1,),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: "Czas przewijania",
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.av_timer),
                          ),
                          controller: TextEditingController(
                            text: _timeOfChange != null
                                ? "${_timeOfChange?.toIso8601String().replaceAll("T", " ").split(".").first}"
                                : "",
                          ),
                          validator: (_) =>
                          _timeOfChange == null ? "Wybierz czas zmiany" : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.extended(
                      foregroundColor: brandColorSchema.blue,
                      backgroundColor: brandColorSchema.gray,
                      onPressed: _setTimeNow,
                      label: const Text('Teraz'),
                      icon: const Icon(Icons.av_timer_sharp),
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1,),
                    const SizedBox(height: 8),
                    FloatingActionButton.extended(
                      foregroundColor: brandColorSchema.gray,
                      backgroundColor: brandColorSchema.blue,
                      onPressed: () {
                        repository.addDiaperChange(
                            childId: id!,
                            diaperChange: DiaperChange(
                                dateTime: _timeOfChange!,
                                pee: _pee,
                                poop: _poop
                            )
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Przewiijanie dodane")),
                        );

                        context.go(Routes.child.replaceAll(":id", id!));
                      },
                      label: const Text('Dodaj'),
                      icon: const Icon(Icons.add),
                    ),
                    Divider(height: 60, thickness: 3, color: brandColorSchema.gray,),
                    Align(child:
                      Text("Podsumowanie dnia:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        textAlign: TextAlign.left,
                      ),
                      alignment: Alignment.centerLeft)
                    ,
                    SizedBox(height: 8),
                    Align(child:
                        Text("Kupa: $_todayPoopCount",
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.left,
                        ),
                        alignment: Alignment.centerLeft)
                    ,
                    Align(child:
                        Text("Siku: $_todayPeeCount",
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.left,
                        ),
                        alignment: Alignment.centerLeft)
                    ,

                  ],
                )
              )
            ]
          )
      )
    );
  }

  void _setTimeNow() {
    setState(() {
      _timeOfChange = DateTime.now();
    });
  }

  Future<void> _fetchTodaySummary() async {
    if (id == null) return;

    try {
      final changes = await repository.getTodayDiaperChanges(id!);

      // Liczba siku i kupa na podstawie danych
      final peeCount = changes.where((c) => c.pee).length;
      final poopCount = changes.where((c) => c.poop).length;

      setState(() {
        _todayPeeCount = peeCount;
        _todayPoopCount = poopCount;
      });
    } catch (e) {
      print("Błąd podczas pobierania danych: $e");
    }
  }

}