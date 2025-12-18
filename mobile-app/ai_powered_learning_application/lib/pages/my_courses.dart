import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'course_enrollment.dart';
import 'course_lessons_page.dart';

class MyCoursesPage extends StatefulWidget {
  final String studentId;
  const MyCoursesPage({super.key, required this.studentId});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DocumentSnapshot> _myCourses = [];
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
    _loadMyCourses();
  }

  Future<void> _loadMyCourses() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final studentDoc =
          await _firestore.collection('students').doc(currentUser.uid).get();
      if (!studentDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      List<String> enrolledCourses =
          List<String>.from(studentDoc.data()?['enrolledCourses'] ?? []);
      if (enrolledCourses.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final coursesSnapshot = await _firestore
          .collection('courses')
          .where(FieldPath.documentId, whereIn: enrolledCourses)
          .get();

      setState(() {
        _myCourses = coursesSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading courses: $e");
      setState(() => _isLoading = false);
    }
  }

  // Get difficulty color
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "beginner":
        return Color(0xFF0F9D58); // Green
      case "intermediate":
        return Color(0xFFF4B400); // Amber
      case "advanced":
        return Color(0xFFDB4437); // Red
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'My Courses',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
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
            stops: [0.0, 0.2],
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
                      "Loading your courses...",
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _myCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 80,
                          color: lightBlue,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "No Courses Yet",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'You have not enrolled in any courses yet. Explore our catalog to get started!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecommendedCoursesPage(
                                    studentId: widget.studentId),
                              ),
                            );
                          },
                          child: const Text(
                            "Browse Courses",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Course Count Badge
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
                                  Icon(Icons.library_books,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${_myCourses.length} ${_myCourses.length == 1 ? 'Course' : 'Courses'}",
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
                            const Text(
                              "My Learning Journey",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: ScrollConfiguration(
                            behavior: NoGlowScrollBehavior(),
                            child: ListView(
                              padding: const EdgeInsets.only(
                                top: 24,
                                left: 16,
                                right: 16,
                                bottom: 16,
                              ),
                              children: _myCourses.map((course) {
                                final title =
                                    course['Title'] ?? 'Untitled Course';
                                final category =
                                    course['Category'] ?? 'General';
                                final difficulty =
                                    course['Difficulty'] ?? 'Beginner';
                                final imageUrl = course['ImageUrl'];
                                final description = course['Description'] ??
                                    'No description available';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
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
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CourseLessonsPage(
                                              courseId: course.id,
                                              studentId: widget.studentId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Course Image
                                          if (imageUrl != null &&
                                              imageUrl != '')
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                              child: Stack(
                                                children: [
                                                  Image.network(
                                                    imageUrl,
                                                    height: 160,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  // Gradient overlay
                                                  Container(
                                                    height: 160,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment
                                                            .bottomCenter,
                                                        end:
                                                            Alignment.topCenter,
                                                        colors: [
                                                          Colors.black
                                                              .withOpacity(0.3),
                                                          Colors.transparent,
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          // Course Content
                                          Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Title
                                                Text(
                                                  title,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                // Tags Row
                                                Row(
                                                  children: [
                                                    // Category Chip
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: cardBlue,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.category,
                                                            size: 14,
                                                            color: accentBlue,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            category,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: accentBlue,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Difficulty Chip
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _getDifficultyColor(
                                                                    difficulty)
                                                                .withOpacity(
                                                                    0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.flag,
                                                            size: 14,
                                                            color:
                                                                _getDifficultyColor(
                                                                    difficulty),
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            difficulty,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  _getDifficultyColor(
                                                                      difficulty),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                // Description
                                                Text(
                                                  description,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                    height: 1.4,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 20),
                                                // View Lessons Button
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          primaryBlue,
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation: 2,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 24,
                                                        vertical: 12,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CourseLessonsPage(
                                                            courseId: course.id,
                                                            studentId: widget
                                                                .studentId,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          "Continue Learning",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Icon(
                                                            Icons.arrow_forward,
                                                            size: 18),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
      ),
    );
  }
}
