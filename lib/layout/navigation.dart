import 'package:flutter/material.dart';
import '../home_screen.dart';
import '../library_screen.dart';
import '../discussion_boards.dart';
import '../profile_settings.dart';

class Navigation extends StatelessWidget {
  final int currentIndex;

  const Navigation({super.key, required this.currentIndex});

  static final List<Widget> _screens = [
    HomeScreen(),
    DiscussionBoards(),
    LibraryScreen(),
    ProfileSettings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          if (index != currentIndex) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Navigation(currentIndex: index),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'My Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Discussions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}