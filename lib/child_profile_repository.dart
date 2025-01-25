import 'package:babycare/gender_dropdown_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  ChildProfileRepository();

  void _settings() {
    _firestore.settings = Settings(persistenceEnabled: false);
  }

  /// Dodawanie profilu dziecka do Firestore
  Future<void> editChildProfile({
    required String id,
    required String name,
    required DateTime birthDate,
    required String gender,
  }) async {
    try {
      _settings();
      // Pobranie aktualnego użytkownika
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid == null) {
        throw Exception("Użytkownik nie jest zalogowany");
      }

      // Tworzenie nowego dokumentu w kolekcji 'children'
      final docRef = _firestore.collection('children').doc(id);

      print(docRef);
      print(docRef.path);
      // Dane do zapisania
      await docRef.update({
        'name': name,
        'birthDate': Timestamp.fromDate(birthDate),
        'gender': gender
      });
      print("git");
    } catch (e) {
      print("Błąd podczas edytowania profilu dziecka: $e");
      rethrow; // Rzuć wyjątek wyżej, jeśli coś pójdzie nie tak
    }
  }

  Future<void> addChildProfile({
    required String name,
    required DateTime birthDate,
    required String gender,
  }) async {
    try {
      _settings();
      // Pobranie aktualnego użytkownika
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid == null) {
        throw Exception("Użytkownik nie jest zalogowany");
      }

      // Tworzenie nowego dokumentu w kolekcji 'children'
      final docRef = _firestore.collection('children').doc();

      // Dane do zapisania
      await docRef.set({
        'name': name,
        'birthDate': Timestamp.fromDate(birthDate),
        'owners': [uid], // Lista właścicieli
        'gender': gender, // Płeć dziecka
        'createdAt': Timestamp.now(), // Znacznik czasu utworzenia
      }).timeout(Duration(
          seconds: 10),
          onTimeout: throw Exception("Super"));
      print("after save");
    } catch (e) {
      print("Błąd podczas dodawania profilu dziecka: $e");
      rethrow; // Rzuć wyjątek wyżej, jeśli coś pójdzie nie tak
    }
  }

  void deleteChildProfile({
    required String id,
  }) async {
    try {
      _settings();
      // Pobranie aktualnego użytkownika
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid == null) {
        throw Exception("Użytkownik nie jest zalogowany");
      }

      // Tworzenie nowego dokumentu w kolekcji 'children'
      await _firestore.collection('children').doc(id).delete();
    } catch (e) {
      print("Błąd podczas usuwania profilu dziecka: $e");
      rethrow; // Rzuć wyjątek wyżej, jeśli coś pójdzie nie tak
    }
  }

  /// Pobieranie wszystkich profili dzieci przypisanych do zalogowanego użytkownika
  Future<List<ChildProfile>> getChildProfiles() async {
    try {
      _settings();
      // Pobranie aktualnego użytkownika
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid == null) {
        throw Exception("Użytkownik nie jest zalogowany");
      }

      // Zapytanie do Firestore, aby pobrać dzieci, w których właścicielem jest użytkownik
      final querySnapshot = await _firestore
          .collection('children')
          .where('owners', arrayContains: uid)
          .orderBy('createdAt', descending: true) // Optional: sortowanie po dacie
          .get();

      // Przekształcenie wyników w listę map
      return querySnapshot.docs.map((doc) {
        print(doc.id);
        print(doc.data()['birthDate']);
        print(doc.data()['createdAt']);
        return ChildProfile(
            id: doc.id,
            name: doc.data()['name'],
            birthDate: doc.data()['birthDate']?.toDate(),
            gender: Gender.fromString(doc.data()['gender']),
            createdAt: doc.data()['createdAt']?.toDate(),
        );
      }).toList();
    } catch (e) {
      print("Błąd podczas pobierania profili dzieci: $e");
      rethrow;
    }
  }

  Stream<List<ChildProfile>> getChildProfilesStream() {
    try {
      _settings();
      // Pobranie aktualnego użytkownika
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid == null) {
        throw Exception("Użytkownik nie jest zalogowany");
      }

      // Zapytanie do Firestore, aby pobrać dzieci, w których właścicielem jest użytkownik
      return _firestore
          .collection('children')
          .where('owners', arrayContains: uid)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              print(doc);
              print(doc.data()['birthDate']);
              print(doc.data()['createdAt']);
              return ChildProfile(
                id: doc.id,
                name: doc.data()['name'],
                birthDate: doc.data()['birthDate']?.toDate(),
                gender: Gender.fromString(doc.data()['gender']),
                createdAt: doc.data()['createdAt']?.toDate(),
              );
            }).toList();
          });
    } catch (e) {
      print("Błąd podczas pobierania profili dzieci: $e");
      rethrow;
    }
  }


  Future<ChildProfile> getChildProfile(String id) async {
    try {
      _settings();
      print("getChildProfile");
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('children')
          .doc(id)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw Exception("Błą∂");
      }
      final data = doc.data() as Map<String, dynamic>;

      print(doc);
      print(doc.id);
      print(data['name']?? "");
      return ChildProfile(
        id: doc.id,
        name: data['name'] ?? "",
        birthDate: data['birthDate']?.toDate(),
        gender: Gender.fromString(data['gender']),
        createdAt: data['createdAt']?.toDate(),
      );
    } catch (e) {
      print("Błąd podczas ładowania profilu: $e");
    }
    return Future.value(ChildProfile());
  }

}
class ChildProfile {
  late String? id;
  late String? name;
  late DateTime? birthDate;
  late Gender? gender;
  late DateTime? createdAt;

  ChildProfile({
    this.id,
    this.name,
    this.gender,
    this.birthDate,
    this.createdAt,
  });

}