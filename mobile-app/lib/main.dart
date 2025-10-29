import 'package:flutter/material.dart';

void main() {
  runApp(const UpvistaApp());
}

class UpvistaApp extends StatelessWidget {
  const UpvistaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upvista Community',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon/Logo placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.people,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Welcome Text
                const Text(
                  "Welcome to Upvista's Community Mobile App",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Subtitle
                const Text(
                  "Connect, collaborate, and grow with our vibrant community platform",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                
                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to main app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Welcome to Upvista Community!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Learn More Button
                TextButton(
                  onPressed: () {
                    // TODO: Show more information
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Learn more about Upvista Community'),
                      ),
                    );
                  },
                  child: const Text(
                    'Learn More',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
