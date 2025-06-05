import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PulseApp());
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String insight = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchInsight();
  }

  Future<void> fetchInsight() async {
    final resp = await http.get(Uri.parse('https://example.com/getDailyPulse'));
    if (resp.statusCode == 200) {
      setState(() => insight = json.decode(resp.body)['insight']);
    } else {
      setState(() => insight = 'Error fetching insight');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(child: PulseCard(content: insight)),
      bottomNavigationBar: const PulseNavBar(current: 0),
    );
  }
}

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  Future<void> logMeal() async {
    await http.post(Uri.parse('https://example.com/logMeal'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Log')),
      body: Center(
        child: ElevatedButton(
          onPressed: logMeal,
          child: const Text('Log Meal'),
        ),
      ),
      bottomNavigationBar: const PulseNavBar(current: 1),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    final resp = await http.get(Uri.parse('https://example.com/healthDashboard'));
    if (resp.statusCode == 200) {
      setState(() => data = json.decode(resp.body));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        children: [
          Text('Sleep: ${data['sleep'] ?? '-'}'),
          Text('Steps: ${data['steps'] ?? '-'}'),
          Text('HRV: ${data['hrv'] ?? '-'}'),
          Text('Nutrition: ${data['nutrition'] ?? '-'}'),
        ],
      ),
      bottomNavigationBar: const PulseNavBar(current: 2),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Text(user != null ? 'Logged in as ${user.email}' : 'Not logged in'),
      ),
      bottomNavigationBar: const PulseNavBar(current: 3),
    );
  }
}

class PulseNavBar extends StatelessWidget {
  final int current;
  const PulseNavBar({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: current,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            break;
          case 1:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const NutritionScreen()));
            break;
          case 2:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()));
            break;
          case 3:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Nutrition'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

class PulseCard extends StatelessWidget {
  final String content;
  const PulseCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(content),
      ),
    );
  }
}
