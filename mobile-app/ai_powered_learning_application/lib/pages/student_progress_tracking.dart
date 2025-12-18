import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'lesson_content_page.dart';

class StudentProgressPage extends StatefulWidget {
  final String studentId;

  const StudentProgressPage({super.key, required this.studentId});

  @override
  State<StudentProgressPage> createState() => _StudentProgressPageState();
}

class _StudentProgressPageState extends State<StudentProgressPage> {
  Map<String, dynamic> _studentData = {};
  Map<String, dynamic> _studentProgress = {};
  List<Map<String, dynamic>> _quizResponses = [];
  Map<String, dynamic> _courses = {};
  final Map<String, Map<String, Map<String, dynamic>>> _courseContents = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllProgressData();
  }

  Future<void> _loadAllProgressData() async {
    try {
      await _loadStudentData();
      await _loadQuizResponses();
      await _loadCourses();
      await _loadAllCourseContents();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() {
        _errorMessage = "Error loading progress: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudentData() async {
    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .get();

    if (!studentDoc.exists) {
      throw Exception("Student data not found");
    }

    final studentData = studentDoc.data()!;
    setState(() {
      _studentData = studentData;
      _studentProgress =
          Map<String, dynamic>.from(studentData['progress'] ?? {});
    });
    print('Loaded student progress: $_studentProgress'); // Debug
  }

  Future<void> _loadQuizResponses() async {
    try {
      final responsesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('quizResponses')
          .where('studentId', isEqualTo: widget.studentId)
          .get();

      final responses = <Map<String, dynamic>>[];
      for (var doc in responsesSnapshot.docs) {
        responses.add({'id': doc.id, ...doc.data()});
      }

      setState(() {
        _quizResponses = responses;
      });
      print('Loaded ${_quizResponses.length} quiz responses'); // Debug
    } catch (e) {
      print('Error loading quiz responses: $e');
    }
  }

  Future<void> _loadCourses() async {
    try {
      final coursesSnapshot =
          await FirebaseFirestore.instance.collection('courses').get();

      setState(() {
        _courses = {for (var doc in coursesSnapshot.docs) doc.id: doc.data()};
      });
      print('Loaded ${_courses.length} courses'); // Debug
    } catch (e) {
      print('Error loading courses: $e');
    }
  }

  Future<void> _loadAllCourseContents() async {
    try {
      final courseIds = _getEnrolledCourseIds();
      print('Loading contents for enrolled courses: $courseIds'); // Debug

      for (var courseId in courseIds) {
        final snapshot = await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .collection('contents')
            .get();

        final contentMap = <String, Map<String, dynamic>>{};
        for (var doc in snapshot.docs) {
          contentMap[doc.id] = doc.data();
        }
        print('Course $courseId has ${contentMap.length} contents'); // Debug
        _courseContents[courseId] = contentMap;
      }
      print('Total course contents loaded: ${_courseContents.length}'); // Debug
    } catch (e) {
      print('Error loading course contents: $e');
    }
  }

  List<String> _getEnrolledCourseIds() {
    return (_studentData['enrolledCourses'] as List<dynamic>?)
            ?.cast<String>() ??
        [];
  }

  Map<String, dynamic> _getCombinedCourseProgress(String courseId) {
    // Get course-specific progress (nested under courseId in progress map)
    final courseSpecificProgress =
        _studentProgress[courseId] as Map<String, dynamic>? ?? {};

    // Get quiz responses for this course
    final courseQuizResponses = _quizResponses
        .where((response) => response['courseId'] == courseId)
        .toList();

    // Get all contents for this course
    final contents = _courseContents[courseId] ?? {};
    print(
        'Combining progress for course $courseId: ${contents.length} contents, ${courseSpecificProgress.length} progress entries, ${courseQuizResponses.length} quiz responses');

    final combinedProgress = Map<String, dynamic>.from(courseSpecificProgress);

    // Initialize progress for all contents that exist in the course
    for (var contentId in contents.keys) {
      if (!combinedProgress.containsKey(contentId)) {
        combinedProgress[contentId] = {
          'completed': false,
          'viewed': false,
          'quizScore': 0,
          'attempts': 0,
        };
      }
    }

    // Update progress with quiz responses
    for (var response in courseQuizResponses) {
      final contentId = response['contentId'];
      if (contentId == null) continue;

      final score = _parseScore(response['quizScore'] ?? response['score']);
      final attempt = response['attempt'] ?? 1;
      final isCorrect = response['isCorrect'] == true;

      if (!combinedProgress.containsKey(contentId)) {
        combinedProgress[contentId] = {
          'completed': false,
          'viewed': false,
          'quizScore': 0,
          'attempts': 0,
        };
      }

      final contentProgress =
          combinedProgress[contentId] as Map<String, dynamic>;

      // Mark as completed if quiz was taken with a score
      if (score > 0 || isCorrect) {
        contentProgress['completed'] = true;
      }

      contentProgress['quizScore'] = score;
      contentProgress['attempts'] = attempt;
      contentProgress['hasQuizResponse'] = true;
      contentProgress['viewed'] = true; // If they took a quiz, they viewed it
    }

    return _calculateProgressMetrics(
        courseId, combinedProgress, courseQuizResponses.length);
  }

  Map<String, dynamic> _calculateProgressMetrics(String courseId,
      Map<String, dynamic> combinedProgress, int quizResponseCount) {
    int completedLessons = 0;
    double totalScore = 0;
    int scoredLessons = 0;
    int viewedLessons = 0;

    // Use the actual course contents length as total
    final totalLessons = _courseContents[courseId]?.length ?? 0;

    combinedProgress.forEach((contentId, progress) {
      if (progress is Map<String, dynamic>) {
        final isCompleted = progress['completed'] == true;
        final isViewed = progress['viewed'] == true;
        final quizScore = progress['quizScore'];

        if (isCompleted) completedLessons++;
        if (isViewed) viewedLessons++;
        if (quizScore != null && quizScore > 0) {
          totalScore += _parseScore(quizScore);
          scoredLessons++;
        }
      }
    });

    final percentage =
        totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0;
    final averageScore = scoredLessons > 0 ? totalScore / scoredLessons : 0;

    print(
        'Progress for $courseId: $completedLessons/$totalLessons completed, $percentage%'); // Debug

    return {
      'completed': completedLessons,
      'viewed': viewedLessons,
      'total': totalLessons,
      'percentage': percentage,
      'averageScore': averageScore,
      'quizResponseCount': quizResponseCount,
      'lessons': combinedProgress,
    };
  }

  List<Map<String, dynamic>> _getLessonsNeedingAttention(String courseId) {
    final courseProgress = _getCombinedCourseProgress(courseId);
    final lessonsProgress = courseProgress['lessons'] as Map<String, dynamic>;
    final contents = _courseContents[courseId] ?? {};

    return lessonsProgress.entries
        .map((entry) {
          final contentId = entry.key;
          final progress = entry.value as Map<String, dynamic>;
          final contentData = contents[contentId] ?? {};
          final score = _parseScore(progress['quizScore']);
          return {
            'lessonId': contentId,
            'Title': contentData['Title'] ?? 'Untitled Lesson',
            'Description': contentData['Description'] ?? '',
            'ContentUrls': contentData['ContentUrls'] ?? [],
            'ContentType': contentData['ContentType'] ?? '',
            'completed': progress['completed'] ?? false,
            'viewed': progress['viewed'] ?? false,
            'score': score,
            'attempts': progress['attempts'] ?? 0,
            'lastViewed': progress['lastViewed'] ?? progress['lastAttempt'],
          };
        })
        .where((lesson) => !lesson['completed'] || lesson['score'] < 70)
        .toList();
  }

  double _parseScore(dynamic score) {
    if (score is int) return score.toDouble();
    if (score is double) return score;
    if (score is String) return double.tryParse(score) ?? 0;
    return 0;
  }

  // UI Helper methods
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green.shade50;
      case 'intermediate':
        return Colors.orange.shade50;
      case 'advanced':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Not viewed';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return timestamp.toString();
  }

  Widget _buildStudentHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.purple.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_studentData['name'] ?? ''} ${_studentData['surname'] ?? ''}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _studentData['email'] ?? 'No email',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Skill Level',
                _studentData['skillLevel'] ?? 'Not set',
                Icons.school,
              ),
              _buildStatItem(
                'Total Score',
                '${_studentData['totalScore'] ?? 0}',
                Icons.emoji_events,
              ),
              _buildStatItem(
                'Courses',
                '${_getEnrolledCourseIds().length}',
                Icons.library_books,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailStat(String value, String label, IconData icon,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue.shade600, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showCourseDetails(BuildContext context, String courseId) {
    final courseProgress = _getCombinedCourseProgress(courseId);
    final courseData = _courses[courseId] ?? {};
    final courseName = courseData['Title'] ?? 'Unnamed Course';
    final courseDescription = courseData['Description'] ?? '';
    final courseCategory = courseData['Category'] ?? 'Uncategorized';
    final courseDifficulty = courseData['Difficulty'] ?? 'Not specified';
    final courseImageUrl = courseData['ImageUrl'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Course Image
                              if (courseImageUrl.isNotEmpty)
                                Container(
                                  height: 160,
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          courseImageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                              // Course Title
                              Text(
                                courseName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Course Info Chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(
                                    label: Text(courseCategory),
                                    backgroundColor: Colors.blue.shade50,
                                  ),
                                  Chip(
                                    label: Text(courseDifficulty),
                                    backgroundColor:
                                        _getDifficultyColor(courseDifficulty),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Course Description
                              Text(
                                courseDescription,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Progress Stats
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildDetailStat(
                                      "${courseProgress['completed']}/${courseProgress['total']}",
                                      "Lessons",
                                      Icons.library_books,
                                    ),
                                    _buildDetailStat(
                                      "${courseProgress['percentage']?.toStringAsFixed(0) ?? '0'}%",
                                      "Complete",
                                      Icons.trending_up,
                                    ),
                                    _buildDetailStat(
                                      "${courseProgress['averageScore']?.toStringAsFixed(0) ?? '0'}%",
                                      "Avg Score",
                                      Icons.assessment,
                                      color: (courseProgress['averageScore'] ??
                                                  0) >=
                                              70
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Lessons List Header
                              const Text(
                                "Lesson Progress",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),

                        // Lessons List
                        ..._buildLessonsList(courseId, courseProgress),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildLessonsList(
      String courseId, Map<String, dynamic> courseProgress) {
    final contents = _courseContents[courseId] ?? {};
    final lessonsProgress = courseProgress['lessons'] as Map<String, dynamic>;

    if (contents.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No lessons available for this course",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ];
    }

    return contents.entries.map((entry) {
      final contentId = entry.key;
      final contentData = entry.value;
      final lessonProgress =
          lessonsProgress[contentId] as Map<String, dynamic>? ??
              {
                'completed': false,
                'viewed': false,
                'quizScore': 0,
                'attempts': 0,
              };

      final lessonName = contentData['Title'] ?? 'Untitled Lesson';
      final isCompleted = lessonProgress['completed'] == true;
      final score = _parseScore(lessonProgress['quizScore']);
      final attempts = lessonProgress['attempts'] ?? 0;
      final lastViewed = lessonProgress['lastViewed'];

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          color: isCompleted
              ? (score >= 70 ? Colors.green.shade50 : Colors.orange.shade50)
              : null,
          child: ListTile(
            leading: Icon(
              isCompleted
                  ? (score >= 70 ? Icons.check_circle : Icons.warning)
                  : Icons.radio_button_unchecked,
              color: isCompleted
                  ? (score >= 70 ? Colors.green : Colors.orange)
                  : Colors.grey,
            ),
            title: Text(
              lessonName,
              style: TextStyle(
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCompleted)
                  Text(
                      "Score: ${score.toStringAsFixed(0)}% • Attempts: $attempts"),
                if (!isCompleted && lastViewed != null)
                  Text("Last viewed: ${_formatTimestamp(lastViewed)}"),
                if (!isCompleted && lastViewed == null)
                  const Text("Not started"),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LessonContentPage(
                    courseId: courseId,
                    contentId: contentId,
                    studentId: widget.studentId,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Loading your progress...",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Student Progress"),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadAllProgressData,
                  child: const Text("Try Again"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final courseIds = _getEnrolledCourseIds();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("My Learning Progress"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: courseIds.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "No Progress Yet",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Enroll in courses and start learning to track your progress here!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllProgressData,
              child: ListView(
                children: [
                  _buildStudentHeader(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Course Progress",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...courseIds.map((courseId) => _buildCourseCard(courseId)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCourseCard(String courseId) {
    final courseProgress = _getCombinedCourseProgress(courseId);
    final lessonsNeedingWork = _getLessonsNeedingAttention(courseId);
    final courseData = _courses[courseId] ?? {};
    final courseName = courseData['Title'] ?? 'Unnamed Course';
    final courseDescription = courseData['Description'] ?? '';
    final courseCategory = courseData['Category'] ?? 'Uncategorized';
    final courseDifficulty = courseData['Difficulty'] ?? 'Not specified';
    final courseImageUrl = courseData['ImageUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCourseDetails(context, courseId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image and Header
              if (courseImageUrl.isNotEmpty)
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(courseImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Course Title and Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courseName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          courseDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress Section
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value:
                                    (courseProgress['percentage'] ?? 0) / 100,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  (courseProgress['percentage'] ?? 0) == 100
                                      ? Colors.green
                                      : Colors.blue.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "${(courseProgress['percentage'] ?? 0).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${courseProgress['completed']}/${courseProgress['total']} lessons",
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              "Avg: ${(courseProgress['averageScore'] ?? 0).toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    (courseProgress['averageScore'] ?? 0) >= 70
                                        ? Colors.green
                                        : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Lessons Needing Work
              if (lessonsNeedingWork.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning,
                          color: Colors.orange.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${lessonsNeedingWork.length} lesson${lessonsNeedingWork.length > 1 ? 's' : ''} need attention",
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Course Completion Badge
              if (courseProgress['completed'] == courseProgress['total'] &&
                  courseProgress['total'] > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade600, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Course Completed!",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
