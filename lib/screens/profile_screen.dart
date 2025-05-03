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
  List<String> favoriteBookGenres = [];
  final List<String> genres = [
    'Fiction',
    'Non-fiction',
    'Science Fiction',
    'Fantasy',
    'Mystery',
    'Romance',
    'Horror',
    'Thriller',
    'Biography',
    'History',
    'Self-help',
    'Poetry',
    'Children\'s',
    'Young Adult',
  ];

  String? genreSelect;
  bool appNotification = false;
  final TextEditingController newUsername = TextEditingController();
  final TextEditingController newEmail = TextEditingController();
  final TextEditingController currentPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController newPasswordConfirmation = TextEditingController();
  String passwordError = '';

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    getProfile();
  }

  Future<void> getProfile() async {
    user = _auth.currentUser;
    if (user != null) {
      final userDoc = await firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          username = userDoc.data()?['username'] ?? '';
          email = user!.email;
          favoriteBookGenres =
              (userDoc.data()?['favoriteBookGenres'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];
          // Set notification state if it exists in Firestore
          appNotification = userDoc.data()?['appNotification'] ?? false;
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
        (username != newUsername.text || email != newEmail.text)) {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Email Updated')));
        }
        if (updates.isNotEmpty) {
          await firestore.collection('users').doc(user!.uid).update(updates);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profile Updated')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No Changes Made')));
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to Update: ${e.message}')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error Has Occurred')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No Changes Made')));
    }
  }

  Future<void> addGenre(String? selectedGenre) async {
    if (selectedGenre != null && !favoriteBookGenres.contains(selectedGenre)) {
      setState(() {
        favoriteBookGenres.add(selectedGenre);
      });
      await firestore.collection('users').doc(user!.uid).update({
        'favoriteBookGenres': favoriteBookGenres,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $selectedGenre to favorite genres.')),
      );
    }
  }

  Future<void> removeGenre(String genre) async {
    setState(() {
      favoriteBookGenres.remove(genre);
    });
    await firestore.collection('users').doc(user!.uid).update({
      'favoriteBookGenres': favoriteBookGenres,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed $genre from favorite genres.')),
    );
  }

  Future<void> changePassword() async {
    if (currentPassword.text.isEmpty ||
        newPassword.text.isEmpty ||
        newPasswordConfirmation.text.isEmpty) {
      setState(() {
        passwordError = 'Fill out all fields.';
      });
      return;
    }
    if (newPassword.text != newPasswordConfirmation.text) {
      setState(() {
        passwordError = 'New password does not match.';
      });
      return;
    }
    if (newPassword.text.length < 6) {
      setState(() {
        passwordError = 'Password should be at least 6 characters.';
      });
      return;
    }
    try {
      final credentials = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword.text,
      );
      await user!.reauthenticateWithCredential(credentials);
      await user!.updatePassword(newPassword.text.trim());
      setState(() {
        passwordError = '';
        currentPassword.clear();
        newPassword.clear();
        newPasswordConfirmation.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password Updated')));
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        passwordError = e.message ?? 'Password Update Failed';
      });
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');  // Fixed navigation error
    }
  }

  Future<void> accountDeletion() async {
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
                  // First delete user data from Firestore
                  await firestore.collection('users').doc(user!.uid).delete();
                  // Then delete the auth account
                  await user!.delete();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/');  // Fixed navigation error
                  }
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Account Deletion Failed: ${e.message}')),
                  );
                  Navigator.of(context).pop();  // Close dialog on error
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget buttonBuild({
    required VoidCallback onPressed,
    required String text,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,  // Center the content
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon), const SizedBox(width: 8.0)],
            Text(text, style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    newUsername.text = username ?? '';
    newEmail.text = email ?? '';
    List<String> genresList =
        genres.where((genre) => !favoriteBookGenres.contains(genre)).toList();
    String? dropDownNumber = genresList.isNotEmpty ? genresList.first : null;
    final theme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle('Account Information'),
              inputField(
                controller: newUsername,
                label: 'Username',  // Fixed label text
                icon: Icons.person,
              ),
              inputField(
                controller: newEmail,
                label: 'Email',  // Fixed label text
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16.0),
              buttonBuild(
                onPressed: profileUpdate,
                text: 'Save Changes',
                icon: Icons.save,
                backgroundColor: theme.primary,
                textColor: Colors.white,
              ),
              sectionTitle('Favorite Genres'),
              favoriteBookGenres.isEmpty  // FIXED: Corrected the logical condition
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No Genres Added',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                  : Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children:
                          favoriteBookGenres
                              .map(
                                (genre) => Chip(
                                  label: Text(genre),
                                  labelStyle: TextStyle(
                                    color: theme.onSecondary,
                                  ),
                                  backgroundColor: theme.secondary,
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 18.0,
                                  ),
                                  deleteIconColor: theme.onSecondary,
                                  onDeleted: () => removeGenre(genre),
                                ),
                              )
                              .toList(),
                    ),
                  ),
              const SizedBox(height: 16.0),
              if (genresList.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Genre',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: dropDownNumber,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              items:
                                  genresList.map((String genre) {
                                    return DropdownMenuItem<String>(
                                      value: genre,
                                      child: Text(genre),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  dropDownNumber = newValue;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          ElevatedButton(
                            onPressed:
                                dropDownNumber != null
                                    ? () => addGenre(dropDownNumber)
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.secondary,
                              foregroundColor: theme.onSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (favoriteBookGenres.isNotEmpty) ...[  // Only show this when they have genres but can't add more
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Text(
                      'You have added all genres',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
              sectionTitle('App Settings'),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications, color: theme.primary),
                        const SizedBox(width: 12),
                        const Text(
                          'App Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: appNotification,
                      activeColor: theme.primary,
                      onChanged: (bool value) {
                        setState(() {
                          appNotification = value;
                          
                          // Update notification setting in Firestore
                          firestore.collection('users').doc(user!.uid).update({
                            'appNotification': value,
                          }).then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'App Notifications: ${value ? 'Enabled' : 'Disabled'}',
                                ),
                              ),
                            );
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              sectionTitle('Change Password'),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, 
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    inputField(
                      controller: currentPassword, 
                      label: 'Current Password',
                      icon: Icons.lock,
                      obscureText: true, 
                    ),
                    inputField(
                      controller: newPassword, 
                      label: 'New Password',
                      icon: Icons.lock,
                      obscureText: true, 
                    ),
                    inputField(
                      controller: newPasswordConfirmation, 
                      label: 'Confirm New Password',
                      icon: Icons.lock,
                      obscureText: true, 
                    ),
                    if (passwordError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top : 8.0, bottom: 16.0),
                        child: Container(
                          width: double.infinity, 
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            passwordError, 
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ), 
                      buttonBuild(
                        onPressed: changePassword, 
                        text: 'Change Password',
                        icon: Icons.update, 
                        backgroundColor: theme.primary, 
                        textColor: Colors.white
                      ),
                  ],
                ),
              ),
              sectionTitle('Account Actions'),
              const SizedBox(height: 8),
              buttonBuild(
                onPressed: signOut, 
                text: 'Logout',
                icon: Icons.logout,
                backgroundColor: Colors.grey.shade200, 
                textColor: Colors.black87,
              ),
              const SizedBox(height: 8.0),
              buttonBuild(
                onPressed: accountDeletion, 
                text: 'Delete Account', 
                icon: Icons.delete,
                backgroundColor: Colors.red.shade400,
                textColor: Colors.white
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}