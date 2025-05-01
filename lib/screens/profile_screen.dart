import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user;
  String? username;
  String? email;
  String? address;
  List<String> favoriteBookGenres = [];
  bool appNotifications = false;
  final TextEditingController newUsername = TextEditingController();
  final TextEditingController newEmail = TextEditingController();
  final TextEditingController currentPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController newPasswordConfirmation = TextEditingController();
  String passwordErrorMessage = '';

  @override
  void initState() {
    super.initState();
    getUserProfile();
  }

  Future<void> getUserProfile() async {
    user = _auth.currentUser;
    if (user != null) {
      final userDoc = await firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          username = userDoc.data()?['username'] as String? ?? '';
          email = user!.email;
          address = userDoc.data()?['address'] as String? ?? '';
          favoriteBookGenres =
              (userDoc.data()?['favoriteBookGenres'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];
        });
      } else {
        setState(() {
          email = user!.email; 
        });
      }
    }
  }
}
