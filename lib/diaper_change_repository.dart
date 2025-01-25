import 'package:cloud_firestore/cloud_firestore.dart';

class DiaperChangeRepository {
  final FirebaseFirestore firestore;

  DiaperChangeRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  // Funkcja, która dodaje pojedynczą zmianę pieluch do podkolekcji dziecka
  Future<void> addDiaperChange({
    required String childId,
    required DiaperChange diaperChange,
  }) async {
    try {
      // Odwołanie do podkolekcji 'diaper_changes' w dokumencie danego dziecka
      final diaperChangeRef = firestore
          .collection('children') // Kolekcja główna
          .doc(childId) // Dokument odpowiadający dziecku
          .collection('diaper_changes'); // Podkolekcja dla zmian pieluch

      // Dodajemy nowy dokument do podkolekcji
      await diaperChangeRef.add({
        'createdAt': Timestamp.now(), // Czas w formacie ISO8601
        'pee': diaperChange.pee, // `pee`, `poop` lub `both`
        'poop': diaperChange.poop,
        "dateTime": diaperChange.dateTime
      });

      print('Przewijanie dodane');
    } catch (e) {
      print('Błąd podczas zapisu zmiany pieluchy: $e');
    }
  }

  // Funkcja, która pobiera wszystkie zmiany pieluch dla dziecka
  Future<List<DiaperChange>> getDiaperChanges(String childId) async {
    try {
      // Odwołanie do podkolekcji 'diaper_changes' w dokumencie dziecka
      final diaperChangeRef = firestore
          .collection('children')
          .doc(childId)
          .collection('diaper_changes');

      // Pobranie wszystkich rekordów
      final querySnapshot = await diaperChangeRef.get();

      // Mapujemy dane do listy
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return DiaperChange(
          id: doc.id,
          pee: data['pee'],
          poop: data['poop'],
          dateTime: data['dateTime'].toDate(),
          createdAt: data['createdAt'].toDate(),
        );
      }).toList();
    } catch (e) {
      print('Błąd podczas pobierania zmian pieluch: $e');
      return [];
    }
  }

  Future<List<DiaperChange>> getTodayDiaperChanges(String childId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day); // Początek dnia
      final endOfDay = startOfDay.add(Duration(days: 1));

      // Odwołanie do podkolekcji 'diaper_changes' w dokumencie dziecka
      final diaperChangeRef = firestore
          .collection('children')
          .doc(childId)
          .collection('diaper_changes')
          .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('dateTime', isLessThan: endOfDay);

      // Pobranie wszystkich rekordów
      final querySnapshot = await diaperChangeRef.get();

      // Mapujemy dane do listy
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return DiaperChange(
          id: doc.id,
          pee: data['pee'],
          poop: data['poop'],
          dateTime: data['dateTime'].toDate(),
          createdAt: data['createdAt'].toDate(),
        );
      }).toList();
    } catch (e) {
      print('Błąd podczas pobierania zmian pieluch: $e');
      return [];
    }
  }
}

class DiaperChange {
  late String? id;
  late DateTime dateTime;
  late bool pee;
  late bool poop;
  late DateTime? createdAt;

  DiaperChange({
    this.id,
    required this.dateTime,
    required this.pee,
    required this.poop,
    this.createdAt,
  });
}