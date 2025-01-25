import 'package:flutter/material.dart';

enum Gender {
  Male(label: "Chłopiec"),
  Female(label: "Dziewczynka");

  final String label;
  const Gender({required this.label});

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (element) => element.name == value,
      orElse: () => Gender.Male,
      );
  }
}

class GenderDropdownForm extends StatefulWidget {
  final Gender? initialValue;
  final Function(Gender?) onGenderSelected; // Callback

  const GenderDropdownForm({
    Key? key,
    this.initialValue,
    required this.onGenderSelected})
      : super(key: key);

  @override
  _GenderDropdownFormState createState() => _GenderDropdownFormState(
      selectedGender:
      initialValue
  );
}

class _GenderDropdownFormState extends State<GenderDropdownForm> {
  Gender? _selectedGender;

  // Zmienna do przechowywania lokalnie wybranej płci
  _GenderDropdownFormState({Gender? selectedGender}) : _selectedGender = selectedGender;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Gender>(
      decoration: InputDecoration(
        labelText: "Płeć dziecka",
        border: OutlineInputBorder(),
      ),
      value: _selectedGender,
      items: Gender.values.map((gender) {
        return DropdownMenuItem<Gender>(
          value: gender,
          child: Text(gender.label),
        );
      }).toList(),
      onChanged: (Gender? newValue) {
        setState(() {
          _selectedGender = newValue; // Ustawienie nowej wartości lokalnej
        });

        // Wywołanie callbacku z wybraną wartością
        widget.onGenderSelected(newValue);
      },
      validator: (value) =>
      value == null ? "Proszę wybrać płeć dziecka" : null,
    );
  }
}