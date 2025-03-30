import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/message.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _consultationsCollection => 
      _firestore.collection('consultations');
  CollectionReference get _patientsCollection => 
      _firestore.collection('patients');
  CollectionReference get _doctorsCollection => 
      _firestore.collection('doctors');

  // DOCTOR PROFILE METHODS
  Stream<Doctor?> getDoctorProfile(String userId) {
    return _doctorsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final doc = snapshot.docs.first;
      return Doctor.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Future<void> updateDoctorAvailability(String userId, bool isAvailable) async {
    final querySnapshot = await _doctorsCollection
        .where('userId', isEqualTo: userId)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Doctor not found');
    }
    
    final doctorId = querySnapshot.docs.first.id;
    return _doctorsCollection.doc(doctorId).update({
      'isAvailable': isAvailable,
    });
  }

  // PATIENT CRUD OPERATIONS
  Future<String> createPatient(Patient patient) async {
    DocumentReference docRef = await _patientsCollection.add(patient.toJson());
    return docRef.id;
  }

  Future<Patient?> getPatient(String patientId) async {
    try {
      final doc = await _patientsCollection.doc(patientId).get();
      if (doc.exists) {
        return Patient.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting patient: $e');
      return null;
    }
  }

  Future<Patient?> getPatientByUserId(String userId) async {
    QuerySnapshot querySnapshot = await _patientsCollection.where('userId', isEqualTo: userId).get();
    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = querySnapshot.docs.first;
      return Patient.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updatePatient(Patient patient) async {
    await _patientsCollection.doc(patient.id).update(patient.toJson());
  }

  Stream<List<Patient>> getAllPatients() {
    return _patientsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Patient.fromJson(
          doc.data() as Map<String, dynamic>, 
          doc.id,
        );
      }).toList();
    });
  }

  // DOCTOR CRUD OPERATIONS
  Future<String> createDoctor(Doctor doctor) async {
    DocumentReference docRef = await _doctorsCollection.add(doctor.toJson());
    return docRef.id;
  }

  Future<Doctor?> getDoctor(String userId) async {
    try {
      final doc = await _doctorsCollection.doc(userId).get();
      if (doc.exists) {
        return Doctor.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting doctor: $e');
      return null;
    }
  }

  Future<void> updateDoctor(Doctor doctor) async {
    await _doctorsCollection.doc(doctor.id).update(doctor.toJson());
  }

  Stream<List<Doctor>> getAllDoctors() {
    return _doctorsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Doctor.fromJson(
          doc.data() as Map<String, dynamic>, 
          doc.id,
        );
      }).toList();
    });
  }

  // CONSULTATION CRUD OPERATIONS
  Future<String> createConsultation(Consultation consultation) async {
    try {
      final docRef = await _consultationsCollection.add(consultation.toJson());
      return docRef.id;
    } catch (e) {
      print('Error creating consultation: $e');
      rethrow;
    }
  }

  Future<Consultation?> getConsultation(String consultationId) async {
    DocumentSnapshot doc = await _consultationsCollection.doc(consultationId).get();
    if (doc.exists) {
      return Consultation.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateConsultation(Consultation consultation) async {
    try {
      await _consultationsCollection.doc(consultation.id).update(consultation.toJson());
    } catch (e) {
      print('Error updating consultation: $e');
      rethrow;
    }
  }

  Future<void> deleteConsultation(String consultationId) async {
    await _consultationsCollection.doc(consultationId).delete();
  }

  Stream<List<Consultation>> getPatientConsultations(String patientId) {
    try {
      return _consultationsCollection
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          final consultations = snapshot.docs.map((doc) {
            try {
              return Consultation.fromJson(
                doc.data() as Map<String, dynamic>, 
                doc.id,
              );
            } catch (e) {
              print('Error parsing consultation document ${doc.id}: $e');
              // Return a placeholder consultation instead of failing
              return Consultation(
                id: doc.id,
                patientId: patientId,
                title: 'Error: Unable to load consultation',
                status: 'error',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }
          }).toList();
          
          // Only include successfully parsed consultations
          final validConsultations = consultations.where((c) => c.status != 'error').toList();
          validConsultations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return validConsultations;
        })
        .handleError((error) {
          print('Error in getPatientConsultations: $error');
          // Return empty list on error
          return <Consultation>[];
        });
    } catch (e) {
      print('Error setting up patient consultations stream: $e');
      // Return a stream with an empty list
      return Stream.value(<Consultation>[]);
    }
  }

  Stream<List<Consultation>> getDoctorConsultations(String doctorId) {
    try {
      return _consultationsCollection
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          final consultations = snapshot.docs.map((doc) {
            try {
              return Consultation.fromJson(
                doc.data() as Map<String, dynamic>, 
                doc.id,
              );
            } catch (e) {
              print('Error parsing consultation document ${doc.id}: $e');
              // Return a placeholder consultation instead of failing
              return Consultation(
                id: doc.id,
                patientId: '',
                doctorId: doctorId,
                title: 'Error: Unable to load consultation',
                status: 'error',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }
          }).toList();
          
          // Only include successfully parsed consultations
          final validConsultations = consultations.where((c) => c.status != 'error').toList();
          validConsultations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return validConsultations;
        })
        .handleError((error) {
          print('Error in getDoctorConsultations: $error');
          // Return empty list on error
          return <Consultation>[];
        });
    } catch (e) {
      print('Error setting up doctor consultations stream: $e');
      // Return a stream with an empty list
      return Stream.value(<Consultation>[]);
    }
  }

  Stream<List<Consultation>> getOpenConsultations() {
    try {
      return _consultationsCollection
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) {
          final consultations = snapshot.docs.map((doc) {
            try {
              return Consultation.fromJson(
                doc.data() as Map<String, dynamic>, 
                doc.id,
              );
            } catch (e) {
              print('Error parsing consultation document ${doc.id}: $e');
              // Skip this document
              return null;
            }
          })
          .where((consultation) => consultation != null)
          .cast<Consultation>()
          .toList();
          
          consultations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return consultations;
        })
        .handleError((error) {
          print('Error in getOpenConsultations: $error');
          // Return empty list on error
          return <Consultation>[];
        });
    } catch (e) {
      print('Error setting up open consultations stream: $e');
      // Return a stream with an empty list
      return Stream.value(<Consultation>[]);
    }
  }

  // MESSAGES CRUD OPERATIONS
  Stream<List<Message>> getConsultationMessages(String consultationId) {
    return _consultationsCollection
      .doc(consultationId)
      .collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Message.fromJson(
            doc.data() as Map<String, dynamic>, 
            doc.id,
          );
        }).toList();
      });
  }

  Future<void> sendMessage(Message message) async {
    try {
      await _consultationsCollection
          .doc(message.consultationId)
          .collection('messages')
          .add(message.toJson());
      
      // Update consultation's updatedAt time
      await _consultationsCollection
          .doc(message.consultationId)
          .update({
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}