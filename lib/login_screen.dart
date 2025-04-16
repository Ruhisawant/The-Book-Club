import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginForm = true;
  final List<String> _selectedGenres = [];
  final List<String> _genres = [
    'Fiction', 'Non-fiction', 'Science Fiction', 'Fantasy', 
    'Mystery', 'Romance', 'Horror', 'Thriller', 'Biography',
    'History', 'Self-help', 'Poetry', 'Children\'s', 'Young Adult'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleFormMode() {
    setState(() {
      _isLoginForm = !_isLoginForm;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Normally you would authenticate with a backend here
      // For now, we'll just navigate to the home screen
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isLoginForm ? 'Login to Your Account' : 'Create a New Account',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!_isLoginForm && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          if (!_isLoginForm) ...[
            Text(
              'Select your favorite genres:',
            ),
            SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: _genres.length,
                itemBuilder: (context, index) {
                  final genre = _genres[index];
                  return CheckboxListTile(
                    title: Text(genre),
                    value: _selectedGenres.contains(genre),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedGenres.add(genre);
                        } else {
                          _selectedGenres.remove(genre);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: _submitForm,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                _isLoginForm ? 'Login' : 'Create Account',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: _toggleFormMode,
            child: Text(
              _isLoginForm
                  ? 'Don\'t have an account? Create one'
                  : 'Already have an account? Login',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                Text(
                  'BookClub',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 50),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}