import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  String _userName = '';

  String get userName => _userName;

  void setName(String name) {
    _userName = name;
    notifyListeners();
  }

  Future<void> fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          _userName = userDoc['name'];
          notifyListeners();
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
  }
}
