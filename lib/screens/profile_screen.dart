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

  Future<void> profileUpdate() async {
    if (user != null &&
        (username != newUsername.text.trim() ||
            email != newEmail.text.trim())) {
      try {
        final updates = <String, dynamic>{};
        if (username != newUsername.text.trim()) {
          updates['username'] = newUsername.text.trim();
          setState(() {
            username = newUsername.text.trim();
          });
        }
        if (email != newEmail.text.trim()) {
          await user!.updateEmail(newEmail.text.trim());
          setState(() {
            email = newEmail.text.trim();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email has been updated.')),
          );
        }
        if (updates.isNotEmpty) {
          await firestore.collection('users').doc(user!.uid).update(updates);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profile has updated!')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No changesmade.')));
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error has occured: $e')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes made.')));
    }
  }

  Future<void> favoriteGenre() async {
    return showDialog(
      context: context,
      builder: (context) {
        TextEditingController genre = TextEditingController();
        return AlertDialog(
          title: const Text('Add Favorite Genre'),
          content: TextField(
            controller: genre,
            decoration: const InputDecoration(hintText: 'Add genre'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final newAddedGenre = genre.text.trim();
                if (newAddedGenre.isNotEmpty &&
                    !favoriteBookGenres.contains(newAddedGenre)) {
                  setState(() {
                    favoriteBookGenres.add(newAddedGenre);
                  });
                  firestore.collection('users').doc(user!.uid).update({
                    'favoriteBookGenres': favoriteBookGenres,
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> passwordChange() async {
    if (currentPassword.text.isEmpty ||
        newPassword.text.isEmpty ||
        newPasswordConfirmation.text.isEmpty) {
      setState(() {
        passwordErrorMessage = 'Please fill out all boxes.';
      });
      return;
    }
    if (newPassword.text != newPasswordConfirmation.text) {
      setState(() {
        passwordErrorMessage = 'New passwords do not match.';
      });
      return;
    }
    if (newPassword.text.length < 6) {
      setState(() {
        passwordErrorMessage = 'Password must be 6 characters or longer.';
      });
      return;
    }

    try {
      final appCredentials = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword.text,
      );
      await user!.reauthenticateWithCredential(appCredentials);
      await user!.updatePassword(newPassword.text.trim());
      setState(() {
        passwordErrorMessage = '';
        currentPassword.clear();
        newPassword.clear();
        newPasswordConfirmation.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password has been updated!')),
        );
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        passwordErrorMessage = e.message ?? 'Password change failed.';
      });
    }
  }

  Future<void> appLogout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context,'/',); // replace / with the navigation route for the login screen
    }
  }

  Future<void> accountDelete() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Do you want to delete your account?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Account'),
              onPressed: () async {
                try {
                  await user?.delete();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context,'/'); //Replace with the navigation route for the login screen
                  }
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account deletion failed: ${e.message}'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    newUsername.text = username ?? '';
    newEmail.text = email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10.0),
            TextField(
              controller: newUsername,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: newEmail,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            if (address != null)
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: address,
                ),
              ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: profileUpdate,
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Favorite Genres',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10.0),
            Wrap(
              spacing: 8.0,
              children:
                  favoriteBookGenres
                      .map((genre) => Chip(label: Text(genre)))
                      .toList(),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: favoriteGenre,
              child: const Text('Add Favorite Genre'),
            ),
            const SizedBox(height: 20.0),
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('App Notifications'),
                Switch(
                  value: appNotifications,
                  onChanged: (bool value) {
                    setState(() {
                      appNotifications = value;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'App Notifications: ${value ? 'Enabled' : 'disabled'}',
                          ),
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextField(
              controller: currentPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            TextField(
              controller: newPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: newPasswordConfirmation,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confrim Password'),
            ),
            if (passwordErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  passwordErrorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: passwordChange,
              child: const Text('Change Your Password'),
            ),
            const SizedBox(height: 30.0),
            ElevatedButton(onPressed: appLogout, child: const Text('Logout')),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: accountDelete,
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
