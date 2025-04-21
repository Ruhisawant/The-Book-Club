import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final emailControl = TextEditingController();
  final passwordControl = TextEditingController();
  final List<String> genres = [
    'Fiction', 'Non-fiction', 'Science Fiction',
    'Fantasy', 'Mystery', 'Romance', 'Horror',
    'Thriller', 'Biography', 'History',
    'Self-help', 'Poetry', 'Children\'s', 'Young Adult',
  ];
  String genreSelect = 'Fiction';
  bool loggedIn = true;
  String errorMessage = '';

  Future<void> AuthenticationHandler() async {
    try {
      final email = emailControl.text.trim();
      final password = passwordControl.text.trim();

      if (loggedIn) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Successful Login!')));
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final userInformation = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userInformation.user!.uid)
            .set({'email': email, 'genrePreference': genreSelect});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account Made!')));
              setState(() {
                loggedIn = true;
              });
            }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Error';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please Try Again'))); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(loggedIn ? 'Login' : 'Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loggedIn ? 'Welcome Back' : 'Make New Account',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 20),
              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: TextStyle(color: Colors.red)),
              TextField(
                controller: emailControl,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12),
              TextField(
                controller: passwordControl,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 12),
              if (!loggedIn)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Your Favorite Genre'),
                    SizedBox(height: 10),
                    DropdownButton<String>(
                      value: genreSelect,
                      onChanged: (String? newValue) {
                        setState(() {
                          genreSelect = newValue!;
                        });
                      },
                      items:
                          genres
                              .map(
                                (genre) => DropdownMenuItem(
                                  value: genre,
                                  child: Text(genre),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              SizedBox(height: 25),
              ElevatedButton(
                onPressed: AuthenticationHandler,
                child: Text(loggedIn ? 'Login' : 'Sign Up'),
              ),
              SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  setState(() {
                    loggedIn = !loggedIn;
                    errorMessage = '';
                    emailControl.clear();
                    passwordControl.clear();
                  });
                },
                child: Text(
                  loggedIn
                      ? "Make Your Account"
                      : "You Already Have an Account",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}