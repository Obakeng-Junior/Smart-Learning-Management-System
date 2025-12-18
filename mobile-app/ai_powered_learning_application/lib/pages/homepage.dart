import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ai_tutor.dart';
import 'course_enrollment.dart';
import 'my_courses.dart';
import 'recommend_content_page.dart';
import 'student_profile.dart';
import 'student_progress_tracking.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentHomePage extends StatefulWidget {
  final String studentId;
  const StudentHomePage({super.key, required this.studentId});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _studentName = "";
  String _studentSurname = "";
  bool _isLoading = true;

  // Color palette
  final Color primaryBlue = Color(0xFF1A73E8);
  final Color darkBlue = Color(0xFF0D47A1);
  final Color lightBlue = Color(0xFFE8F0FE);
  final Color accentBlue = Color(0xFF4285F4);
  final Color backgroundBlue = Color(0xFFF8FBFF);
  final Color cardBlue = Color(0xFFE3F2FD);
  final Color gradientStart = Color(0xFF1A73E8);
  final Color gradientEnd = Color(0xFFF8FBFF);

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final studentDoc =
          await _firestore.collection('students').doc(widget.studentId).get();

      if (studentDoc.exists) {
        setState(() {
          _studentName = studentDoc['name'] ?? "Student";
          _studentSurname = studentDoc['surname'] ?? "";
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading student data: $e");
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: lightBlue,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: iconColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, size: 30, color: iconColor),
                ),
                const SizedBox(width: 16),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isLoading
            ? const Text(
                "Loading...",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )
            : Text(
                "Welcome, $_studentName!",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentProfilePage(studentId: widget.studentId),
                ),
              );
            },
            tooltip: "Profile",
          )
        ],
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, backgroundBlue],
            stops: [0.0, 0.3],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading your dashboard...",
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.school,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "Learning Dashboard",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Welcome Message
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(text: 'Hello, '),
                                TextSpan(
                                  text: _studentName,
                                  style: TextStyle(
                                    color: lightBlue,
                                  ),
                                ),
                                const TextSpan(text: '! 👋'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ready to continue your learning journey?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dashboard Cards Section
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 32,
                          bottom: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Title
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Learning Tools',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Everything you need for successful learning',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Dashboard Cards
                            _buildDashboardCard(
                              icon: Icons.bar_chart,
                              title: "Track Progress",
                              subtitle:
                                  "Monitor your learning journey and achievements",
                              iconColor: Color(0xFF0F9D58), // Green
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentProgressPage(
                                        studentId: widget.studentId),
                                  ),
                                );
                              },
                            ),
                            _buildDashboardCard(
                              icon: Icons.library_books,
                              title: "My Courses",
                              subtitle:
                                  "Access your enrolled courses and lessons",
                              iconColor: primaryBlue, // Blue
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyCoursesPage(
                                        studentId: widget.studentId),
                                  ),
                                );
                              },
                            ),
                            _buildDashboardCard(
                              icon: Icons.auto_awesome,
                              title: "Smart Recommendations",
                              subtitle:
                                  "Personalized content based on your progress",
                              iconColor: Color(0xFFF4B400), // Amber
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecommendationPage(
                                        studentId: widget.studentId),
                                  ),
                                );
                              },
                            ),
                            _buildDashboardCard(
                              icon: Icons.add_circle_outline,
                              title: "Browse Courses",
                              subtitle: "Discover new courses to enroll in",
                              iconColor: Color(0xFFDB4437), // Red
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RecommendedCoursesPage(
                                            studentId: widget.studentId),
                                  ),
                                );
                              },
                            ),
                            _buildDashboardCard(
                              icon: Icons.smart_toy,
                              title: "AI Tutor",
                              subtitle: "Get personalized help and guidance",
                              iconColor: Color(0xFF9C27B0), // Purple
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AITutorPage(
                                      studentId: FirebaseAuth
                                          .instance.currentUser!.uid,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
