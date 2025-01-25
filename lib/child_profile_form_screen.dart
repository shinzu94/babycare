import 'package:babycare/child_page_navigation_rail.dart';
import 'package:babycare/routes.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'child_profile_repository.dart';
import 'colors_schema.dart';
import 'gender_dropdown_form.dart';

class ChildProfileForm extends StatefulWidget {
  String? id;

  ChildProfileForm({Key? key, this.id}) :
        super(key: key);
  @override
  _ChildProfileFormState createState() => _ChildProfileFormState(id: this.id);
}

class _ChildProfileFormState extends State<ChildProfileForm> {
  final _formKey = GlobalKey<FormState>();

  _ChildProfileFormState({this.id});
  String? id;
  String? _name;
  DateTime? _dateOfBirth;
  Gender? _selectedGender; // Przechowywanie wybranej płci
  ChildProfileRepository repository = ChildProfileRepository();
  BrandColorSchema brandColorSchema = BrandColorSchema();

  Future<void> _pickDate() async {
    // Wyświetlamy DatePicker

    var now = DateTime.now();
    var today = DateTime(now.year, now.month, now.day);
    var year = 365;
    var firstDate = today.subtract(Duration(days: year * 12));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: firstDate, // Zakres dat od 1900 roku
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      // Jeżeli wybrano datę, zaktualizuj stan
      setState(() {
        _dateOfBirth = pickedDate;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      print(_selectedGender);
      if (id == null) {
        print("add");
        await repository.addChildProfile(
            name: _name!,
            birthDate: _dateOfBirth!,
            gender: _selectedGender!.label
        );
      } else {
        print("edit");
        await repository.editChildProfile(
            id: id!,
            name: _name!,
            birthDate: _dateOfBirth!,
            gender: _selectedGender!.label
        );
        print("aft edit");
      }
      print("snack");
      // Wyświetlamy snackbar jako potwierdzenie zapisu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profil zapisany!")),
      );

      print("go");
      context.go(Routes.home);
    }
  }

  Future<void> _deleteProfile() async {
    if (_formKey.currentState!.validate()) {
      print("delete %s");
      print(id);
      if (id != null) {
        print("bef");
        repository.deleteChildProfile(
            id: id!
        );
        print("aft");
      }
      print("snack");
      // Wyświetlamy snackbar jako potwierdzenie zapisu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profil usunięty!")),
      );

      print("go");
      // Zamknięcie formularza
      // Navigator.pop(context);
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': "ChildProfileForm",
        'screen_class': "ChildProfileForm",
      },
    );
    print("build");
    print(id);
    return Scaffold(
      drawer: ApppDrawer(),
      appBar: AppBar(
        title: Text("Profil Dziecka"),
      ),

      body:
      SafeArea(
          child: Row(
            children: [
              ChildPageNavigationRail(id: id,),
              VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: Column(
                  children: [id != null
                      ? FutureBuilder<ChildProfile>(
                    future: repository.getChildProfile(id!), // Pobierz dziecko dla podanego ID
                    builder: (BuildContext context, AsyncSnapshot<ChildProfile> snapshot) {
                      print("FutureBuilder");
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Wyświetl ładowanie
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        // Obsłuż błąd
                        return Center(child: Text("Błąd: ${snapshot.error}"));
                      } else if (snapshot.hasData) {
                        // Formularz z załadowanymi danymi
                        return _buildForm(snapshot.data!);
                      } else {
                        // Obsłuż brak danych
                        return Center(child: Text("Nie znaleziono profilu dziecka"));
                      }
                    },
                  )
                      : _buildForm(null)],
                ),
              )

            ],
          )
      )
    );
  }

  Widget _buildForm(ChildProfile? profile) {
    _name = _name != null && _name!.length > 0 ? _name : profile?.name ?? "";
    _dateOfBirth = _dateOfBirth ?? profile?.birthDate;
    _selectedGender = _selectedGender ?? profile?.gender ?? Gender.Male;

    return
      Padding(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(
                    labelText: "Imię dziecka",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _name = value,
                  validator: (value) =>
                  value == null || value.isEmpty ? "Wpisz imię dziecka" : null,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: "Data urodzenia" ,
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: _dateOfBirth != null
                            ? "${_dateOfBirth?.toIso8601String().split("T").first}"
                            : "",
                      ),
                      validator: (_) =>
                      _dateOfBirth == null ? "Wybierz datę urodzenia" : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GenderDropdownForm(
                  initialValue: _selectedGender,
                  onGenderSelected: (Gender? gender) {
                    setState(() {
                      _selectedGender = gender;
                    });
                  },
                ),
                const SizedBox(height: 16),

                FloatingActionButton.extended(
                  foregroundColor: brandColorSchema.b2,
                  backgroundColor: Colors.redAccent,
                  onPressed: _deleteProfile,
                  label: const Text('Usuń'),
                  icon: const Icon(Icons.delete),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  foregroundColor: brandColorSchema.b2,
                  backgroundColor: brandColorSchema.gray,
                  onPressed: _saveProfile,
                  label: const Text('Zapisz'),
                  icon: const Icon(Icons.save),
                ),
              ],
            ),
      )
    );
  }
}

class ApppDrawer extends StatelessWidget {
  const ApppDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 97, 97, 97),
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Strona główna'),
            onTap: () {
              context.go(Routes.home);
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Wyloguj'),
            onTap: () {
              FirebaseAuth.instance.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Wylogowano")),
              );
            },
          ),
        ],
      ),
    );
  }
}