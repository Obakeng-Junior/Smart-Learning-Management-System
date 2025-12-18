import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'my_courses.dart';

class RecommendedCoursesPage extends StatefulWidget {
  final String studentId;

  const RecommendedCoursesPage({super.key, required this.studentId});

  @override
  State<RecommendedCoursesPage> createState() => _RecommendedCoursesPageState();
}

class _RecommendedCoursesPageState extends State<RecommendedCoursesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _enrolledCourses = [];
  List<DocumentSnapshot> _allCourses = [];
  List<DocumentSnapshot> _filteredCourses = [];
  String _studentName = '';
  String _studentSurname = '';
  String _studentSkillLevel = 'Beginner'; // Default skill level

  String _selectedCategory = 'All';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Color palette
  final Color primaryBlue = Color(0xFF1A73E8);
  final Color darkBlue = Color(0xFF0D47A1);
  final Color lightBlue = Color(0xFFE8F0FE);
  final Color accentBlue = Color(0xFF4285F4);
  final Color backgroundBlue = Color(0xFFF8FBFF);
  final Color cardBlue = Color(0xFFE3F2FD);
  final Color gradientStart = Color(0xFF1A73E8);
  final Color gradientEnd = Color(0xFFF8FBFF);

  final List<String> availableSubjects = [
    'All',
    'Information Technology',
    'Programming',
    'Web Development',
    'Data Science',
    'Mobile Development'
  ];

  // Skill levels in order
  final List<String> skillLevels = ["Beginner", "Intermediate", "Advanced"];

  @override
  void initState() {
    super.initState();
    _loadStudentDataAndCourses();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentDataAndCourses() async {
    try {
      // Load student data first
      final studentDoc =
          await _firestore.collection('students').doc(widget.studentId).get();

      if (studentDoc.exists) {
        final data = studentDoc.data()!;
        print('Loaded student data: $data');

        setState(() {
          _studentName = data['name'] ?? 'Student';
          _studentSurname = data['surname'] ?? '';
          _enrolledCourses = List<String>.from(data['enrolledCourses'] ?? []);
          _studentSkillLevel = data['skillLevel'] ?? 'Beginner';
        });
      } else {
        print('Student document does not exist');
      }

      // Then load courses
      final courseSnapshot = await _firestore.collection('courses').get();

      setState(() {
        _allCourses = courseSnapshot.docs;
        _filterCoursesBySkillLevel();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter courses based on student's skill level
  void _filterCoursesBySkillLevel() {
    final studentLevelIndex = skillLevels.indexOf(_studentSkillLevel);

    if (studentLevelIndex == -1) {
      // If student skill level is not found, show all courses
      _filteredCourses = _allCourses;
      return;
    }

    _filteredCourses = _allCourses.where((course) {
      final courseDifficulty =
          _getLessonData(course, 'Difficulty', defaultValue: 'Beginner');
      final courseLevelIndex = skillLevels.indexOf(courseDifficulty);

      // If course difficulty is not found in our levels, show it
      if (courseLevelIndex == -1) return true;

      // Show courses that are at or below student's skill level
      return courseLevelIndex <= studentLevelIndex;
    }).toList();
  }

  // Check if student can enroll in a course based on skill level
  bool _canEnrollInCourse(String courseDifficulty) {
    final studentLevelIndex = skillLevels.indexOf(_studentSkillLevel);
    final courseLevelIndex = skillLevels.indexOf(courseDifficulty);

    if (studentLevelIndex == -1 || courseLevelIndex == -1) return true;

    return courseLevelIndex <= studentLevelIndex;
  }

  // Get skill level recommendation message
  String _getSkillLevelMessage() {
    switch (_studentSkillLevel.toLowerCase()) {
      case "beginner":
        return " These courses match your current skill level.";
      case "intermediate":
        return " These courses will help you advance your skills.";
      case "advanced":
        return "Expert-level courses to challenge and expand your knowledge.";
      default:
        return "Courses tailored to your learning journey.";
    }
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filterByCategory(_selectedCategory);
      } else {
        List<DocumentSnapshot> baseCourses = _allCourses.where((course) {
          final courseDifficulty =
              _getLessonData(course, 'Difficulty', defaultValue: 'Beginner');
          final studentLevelIndex = skillLevels.indexOf(_studentSkillLevel);
          final courseLevelIndex = skillLevels.indexOf(courseDifficulty);

          // Filter by skill level first
          final matchesSkillLevel =
              courseLevelIndex == -1 || courseLevelIndex <= studentLevelIndex;
          if (!matchesSkillLevel) return false;

          // Then filter by search query
          final title = (course['Title'] ?? '').toString().toLowerCase();
          final description =
              (course['Description'] ?? '').toString().toLowerCase();
          final category = (course['Category'] ?? '').toString().toLowerCase();

          return title.contains(query) ||
              description.contains(query) ||
              category.contains(query);
        }).toList();

        // Apply category filter on top of search and skill level
        if (_selectedCategory != 'All') {
          _filteredCourses = baseCourses.where((course) {
            final courseCategory = (course['Category'] ?? '').toString().trim();
            return courseCategory.toLowerCase() ==
                _selectedCategory.toLowerCase();
          }).toList();
        } else {
          _filteredCourses = baseCourses;
        }
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;

      if (category == 'All') {
        _filterCoursesBySkillLevel();
      } else {
        _filteredCourses = _allCourses.where((course) {
          final courseCategory = (course['Category'] ?? '').toString().trim();
          final courseDifficulty =
              _getLessonData(course, 'Difficulty', defaultValue: 'Beginner');
          final studentLevelIndex = skillLevels.indexOf(_studentSkillLevel);
          final courseLevelIndex = skillLevels.indexOf(courseDifficulty);

          // Check both category and skill level
          final matchesCategory =
              courseCategory.toLowerCase() == category.toLowerCase();
          final matchesSkillLevel =
              courseLevelIndex == -1 || courseLevelIndex <= studentLevelIndex;

          return matchesCategory && matchesSkillLevel;
        }).toList();
      }
    });
  }

  Future<void> _enrollInCourse(String courseId, String courseDifficulty) async {
    if (!_canEnrollInCourse(courseDifficulty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'This course is too advanced for your current skill level ($_studentSkillLevel)'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final studentRef =
          _firestore.collection('students').doc(widget.studentId);

      await studentRef.set({
        'enrolledCourses': FieldValue.arrayUnion([courseId])
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully enrolled in course!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      setState(() {
        _enrolledCourses.add(courseId);
      });
    } catch (e) {
      print('Error enrolling in course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enroll. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
          'Enroll for Course',
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
                      "Finding courses for you...",
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Skill Level Badge
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
                                Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "Skill Level: $_studentSkillLevel",
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
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(text: 'Hello '),
                                TextSpan(
                                  text: _studentSurname.isEmpty
                                      ? '$_studentName!'
                                      : '$_studentName!',
                                  style: TextStyle(
                                    color: lightBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Skill Level Recommendation
                          Text(
                            _getSkillLevelMessage(),
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
                  ),

                  // White Content Section
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // My Courses Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyCoursesPage(
                                          studentId: widget.studentId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.school, size: 20),
                                label: const Text(
                                  'View My Courses',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: lightBlue,
                                  foregroundColor: primaryBlue,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                        color: primaryBlue.withOpacity(0.3)),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Search Bar
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search courses...',
                                prefixIcon:
                                    Icon(Icons.search, color: primaryBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: lightBlue),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: lightBlue),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide:
                                      BorderSide(color: primaryBlue, width: 2),
                                ),
                                filled: true,
                                fillColor: lightBlue.withOpacity(0.3),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Category Filter
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                labelStyle: TextStyle(color: primaryBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: lightBlue),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: lightBlue),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide:
                                      BorderSide(color: primaryBlue, width: 2),
                                ),
                                filled: true,
                                fillColor: lightBlue.withOpacity(0.3),
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              icon: Icon(Icons.arrow_drop_down,
                                  color: primaryBlue),
                              items: availableSubjects.map((subject) {
                                return DropdownMenuItem(
                                  value: subject,
                                  child: Text(
                                    subject,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontWeight: subject == _selectedCategory
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _filterByCategory(value);
                                }
                              },
                            ),
                            const SizedBox(height: 24),

                            // Section Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ' Courses',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: darkBlue,
                                  ),
                                ),
                                Text(
                                  '${_filteredCourses.length} ${_filteredCourses.length == 1 ? 'course' : 'courses'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Courses List
                  _filteredCourses.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 80,
                                    color: lightBlue,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "No Courses Available",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: darkBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40),
                                    child: Text(
                                      'No courses found for your skill level ($_studentSkillLevel).\nTry updating your skill level or check back later.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final course = _filteredCourses[index];
                              final courseId = course.id;
                              final title =
                                  course['Title'] ?? 'Untitled Course';
                              final category = course['Category'] ?? 'General';
                              final difficulty = _getLessonData(
                                  course, 'Difficulty',
                                  defaultValue: 'Beginner');
                              final description = course['Description'] ??
                                  'No description available';
                              final imageUrl = course['ImageUrl'];

                              final isEnrolled =
                                  _enrolledCourses.contains(courseId);
                              final canEnroll = _canEnrollInCourse(difficulty);

                              return Container(
                                margin: const EdgeInsets.only(
                                    bottom: 16, left: 24, right: 24),
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
                                    onTap: () {},
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Course Image
                                          if (imageUrl != null &&
                                              imageUrl != '')
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.network(
                                                imageUrl,
                                                height: 160,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          const SizedBox(height: 16),
                                          // Title
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Tags
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              // Category
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: cardBlue,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  category,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: accentBlue,
                                                  ),
                                                ),
                                              ),
                                              // Difficulty
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getDifficultyColor(
                                                          difficulty)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  difficulty,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getDifficultyColor(
                                                        difficulty),
                                                  ),
                                                ),
                                              ),
                                              // Skill Level Match
                                              if (canEnroll)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.check,
                                                          size: 12,
                                                          color: Colors.green),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Matches your level',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          // Description
                                          Text(
                                            description,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 16),
                                          // Enroll Button
                                          SizedBox(
                                            width: double.infinity,
                                            child: isEnrolled
                                                ? OutlinedButton.icon(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              MyCoursesPage(
                                                                  studentId: widget
                                                                      .studentId),
                                                        ),
                                                      );
                                                    },
                                                    icon: Icon(
                                                        Icons.check_circle,
                                                        size: 18),
                                                    label: Text(
                                                      "Go to Course",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      foregroundColor:
                                                          Colors.green,
                                                      side: BorderSide(
                                                          color: Colors.green),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                    ),
                                                  )
                                                : ElevatedButton.icon(
                                                    onPressed: () =>
                                                        _enrollInCourse(
                                                            courseId,
                                                            difficulty),
                                                    icon: Icon(Icons.add,
                                                        size: 18),
                                                    label: Text(
                                                      "Enroll Now",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
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
                                                                .circular(16),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _filteredCourses.length,
                          ),
                        ),
                ],
              ),
      ),
    );
  }

  // Safe data access method
  String _getLessonData(DocumentSnapshot lesson, String field,
      {String defaultValue = ''}) {
    try {
      final data = lesson.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey(field)) {
        return data[field]?.toString() ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
}
