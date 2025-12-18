import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'lesson_content_page.dart';

class CourseLessonsPage extends StatefulWidget {
  final String courseId;
  final String studentId;

  const CourseLessonsPage({
    super.key,
    required this.courseId,
    required this.studentId,
  });

  @override
  State<CourseLessonsPage> createState() => _CourseLessonsPageState();
}

class _CourseLessonsPageState extends State<CourseLessonsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<DocumentSnapshot> _lessons = [];
  Map<String, dynamic>? _courseData;

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
    _loadCourseData();
    _loadLessons();
  }

  Future<void> _loadCourseData() async {
    try {
      final courseDoc =
          await _firestore.collection('courses').doc(widget.courseId).get();

      if (courseDoc.exists) {
        setState(() {
          _courseData = courseDoc.data();
        });
      }
    } catch (e) {
      print("Error loading course data: $e");
    }
  }

  Future<void> _loadLessons() async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('contents')
          .orderBy('UploadedAt', descending: false)
          .get();

      setState(() {
        _lessons = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading lessons: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get content type icon
  IconData _getContentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case "video":
        return Icons.play_circle_filled;
      case "reading":
        return Icons.article;
      case "quiz":
        return Icons.quiz;
      default:
        return Icons.library_books;
    }
  }

  // Get content type color
  Color _getContentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case "video":
        return Color(0xFFE53935); // Red
      case "reading":
        return Color(0xFF43A047); // Green
      case "quiz":
        return Color(0xFFFB8C00); // Orange
      default:
        return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _courseData?['Title'] ?? 'Course Lessons',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            if (_courseData != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lesson Count Badge
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
                            Icon(Icons.playlist_play,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "${_lessons.length} ${_lessons.length == 1 ? 'Lesson' : 'Lessons'}",
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
                      Text(
                        _courseData!['Title'] ?? 'Course Lessons',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_courseData!['Description'] != null &&
                          _courseData!['Description'].toString().isNotEmpty)
                        Column(
                          children: [
                            Text(
                              _courseData!['Description'] ?? '',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 10, 66, 195)
                                    .withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                    ]),
              ),
            ],

            // Lessons List
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryBlue),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Loading lessons...",
                              style: TextStyle(
                                color: darkBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _lessons.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_library_outlined,
                                  size: 80,
                                  color: lightBlue,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "No Lessons Available",
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
                                    'Lessons will be added to this course soon.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              top: 24,
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            itemCount: _lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = _lessons[index];
                              final lessonId = lesson.id;

                              // Safe data access using the helper method
                              final title = _getLessonData(lesson, 'Title',
                                  defaultValue: 'Untitled Lesson');
                              final description = _getLessonData(
                                  lesson, 'Description',
                                  defaultValue: 'No description available');
                              final type = _getLessonData(lesson, 'ContentType',
                                  defaultValue: 'Lesson');
                              final difficulty = _getLessonData(
                                  lesson, 'Difficulty',
                                  defaultValue: 'General');

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
                                              LessonContentPage(
                                            courseId: widget.courseId,
                                            contentId: lessonId,
                                            studentId: widget.studentId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Lesson Icon
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: _getContentTypeColor(type)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color:
                                                    _getContentTypeColor(type)
                                                        .withOpacity(0.3),
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                _getContentTypeIcon(type),
                                                size: 28,
                                                color:
                                                    _getContentTypeColor(type),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Lesson Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Lesson Number and Title
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: primaryBlue
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        '${index + 1}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: primaryBlue,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
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
                                                const SizedBox(height: 12),
                                                // Tags Row
                                                Row(
                                                  children: [
                                                    // Content Type
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
                                                            _getContentTypeIcon(
                                                                type),
                                                            size: 14,
                                                            color: accentBlue,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            type,
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
                                                    // Difficulty (only show if available)
                                                    if (difficulty.isNotEmpty &&
                                                        difficulty != 'General')
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[100],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          difficulty,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors
                                                                .grey[700],
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Go to Lesson Arrow
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
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
