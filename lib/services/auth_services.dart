import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _user != null;

  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _userData = doc.data() as Map<String, dynamic>;
          notifyListeners();
        }
      } catch (e) {
        print('Erreur lors du chargement des données utilisateur: $e');
      }
    }
  }

  Future<UserCredential> signUp(String email, String password, Map<String, dynamic> userData) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Ajouter les données utilisateur à Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        ...userData,
      });
      
      await _loadUserData();
      return userCredential;
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserData();
      return userCredential;
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userData = null;
    notifyListeners();
  }

  Future<void> updateUserData(Map<String, dynamic> newData) async {
    if (_user != null) {
      try {
        await _firestore.collection('users').doc(_user!.uid).update(newData);
        await _loadUserData();
      } catch (e) {
        print('Erreur lors de la mise à jour des données: $e');
        rethrow;
      }
    }
  }
}
