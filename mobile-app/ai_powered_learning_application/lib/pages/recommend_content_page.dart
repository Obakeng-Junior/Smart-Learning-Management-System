import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'lesson_content_page.dart';

class RecommendationPage extends StatefulWidget {
  final String studentId;

  const RecommendationPage({super.key, required this.studentId});

  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> recommended = [];
  Map<String, dynamic> studentProgress = {};
  bool isLoading = true;
  String skillLevel = "Beginner";

  // Color palette
  final Color primaryBlue = Color(0xFF1A73E8);
  final Color darkBlue = Color(0xFF0D47A1);
  final Color lightBlue = Color(0xFFE8F0FE);
  final Color accentBlue = Color(0xFF4285F4);
  final Color backgroundBlue = Color(0xFFF8FBFF);
  final Color cardBlue = Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    _generateRecommendations();
  }

  // 🔹 Generate recommendations
  Future<void> _generateRecommendations() async {
    setState(() {
      isLoading = true;
    });

    // 1️⃣ Fetch student data
    final studentSnap =
        await _firestore.collection("students").doc(widget.studentId).get();

    if (!studentSnap.exists) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final studentData = studentSnap.data()!;
    final enrolledCourses =
        List<String>.from(studentData['enrolledCourses'] ?? []);
    studentProgress = Map<String, dynamic>.from(studentData['progress'] ?? {});
    skillLevel = studentData['skillLevel'] ?? "Beginner";

    List<Map<String, dynamic>> allContents = [];

    // 2️⃣ Fetch all contents for enrolled courses
    for (var courseId in enrolledCourses) {
      final courseDoc =
          await _firestore.collection("courses").doc(courseId).get();
      final courseData = courseDoc.data() ?? {};

      final contentsSnap = await _firestore
          .collection("courses")
          .doc(courseId)
          .collection("contents")
          .get();

      allContents.addAll(contentsSnap.docs.map((doc) {
        var data = doc.data();
        data['Id'] = doc.id; // important to track progress
        data['courseId'] = courseId;
        data['courseImageUrl'] = courseData['ImageUrl'] ?? '';
        data['courseName'] = courseData['Title'] ?? 'Unknown Course';
        return data;
      }));
    }

    // 3️⃣ Filter recommendations: not completed AND matches skill level
    List<Map<String, dynamic>> tempRecommended = [];
    for (var content in allContents) {
      String courseId = content['courseId'];
      String contentId = content['Id'];
      String contentDifficulty = content['Difficulty'] ?? "Beginner";

      // 🔹 Navigate nested progress: progress[courseId][contentId]
      var courseProgress = studentProgress[courseId] ?? {};
      var lessonProgress = courseProgress[contentId] ?? {};

      // 🔹 Determine if lesson is completed
      bool completed = (lessonProgress['completed'] ?? false) &&
          ((lessonProgress['quizScore'] ?? 0) >= 100);

      if (!completed && _matchesSkillLevel(skillLevel, contentDifficulty)) {
        tempRecommended.add(content);
      }
    }

    setState(() {
      recommended = tempRecommended;
      isLoading = false;
    });
  }

  // 🔹 Skill level check
  bool _matchesSkillLevel(String studentSkill, String contentDifficulty) {
    List<String> levels = ["Beginner", "Intermediate", "Advanced"];
    int studentIndex = levels.indexOf(studentSkill);
    int contentIndex = levels.indexOf(contentDifficulty);
    return contentIndex <= studentIndex;
  }

  // 🔹 Mark lesson as viewed
  Future<void> _markAsViewed(Map<String, dynamic> content) async {
    final courseId = content['courseId'];
    final contentId = content['Id'];
    final studentRef = _firestore.collection("students").doc(widget.studentId);

    await studentRef.set({
      "progress": {
        courseId: {
          contentId: {
            "viewed": true,
            "lastViewed": FieldValue.serverTimestamp(),
          }
        }
      }
    }, SetOptions(merge: true));

    await _generateRecommendations();
  }

  // 🔹 Get difficulty color
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case "Beginner":
        return Color(0xFF0F9D58); // Green
      case "Intermediate":
        return Color(0xFFF4B400); // Amber
      case "Advanced":
        return Color(0xFFDB4437); // Red
      default:
        return Colors.grey;
    }
  }

  // 🔹 Get content type icon
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Recommended For You",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 18)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _generateRecommendations,
            tooltip: "Refresh recommendations",
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryBlue, backgroundBlue],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skill Level Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Skill Level: $skillLevel",
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
                    "Personalized Recommendations",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Content tailored to your learning journey",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: isLoading
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
                              "Finding your lessons...",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : recommended.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 80,
                                  color: lightBlue,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "All caught up! 🎉",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: darkBlue,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No recommended content at the moment.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                                top: 24, left: 16, right: 16, bottom: 16),
                            itemCount: recommended.length,
                            itemBuilder: (context, index) {
                              final item = recommended[index];
                              final title = item['Title'] ?? "Untitled";
                              final description = item['Description'] ??
                                  "No description available.";
                              final type = item['ContentType'] ?? "Lesson";
                              final difficulty =
                                  item['Difficulty'] ?? "Beginner";
                              final urls =
                                  List<String>.from(item['ContentUrls'] ?? []);
                              final imageUrl = item['courseImageUrl'] ?? '';
                              final courseName = item['courseName'] ?? '';

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
                                      if (urls.isNotEmpty) {
                                        debugPrint("Open Lesson: ${urls[0]}");
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      accentBlue,
                                                      darkBlue
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                                child: imageUrl.isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                        child: Image.network(
                                                          imageUrl,
                                                          width: 70,
                                                          height: 70,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      )
                                                    : Center(
                                                        child: Icon(
                                                          _getContentTypeIcon(
                                                              type),
                                                          size: 32,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Course Name
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: lightBlue,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        courseName,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: primaryBlue,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Title
                                                    Text(
                                                      title,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),

                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _getDifficultyColor(
                                                                    difficulty)
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.flag,
                                                                size: 14,
                                                                color: _getDifficultyColor(
                                                                    difficulty),
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                difficulty,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: _getDifficultyColor(
                                                                      difficulty),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        // Content Type
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: cardBlue,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                _getContentTypeIcon(
                                                                    type),
                                                                size: 14,
                                                                color:
                                                                    accentBlue,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                type,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      accentBlue,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              OutlinedButton.icon(
                                                icon: Icon(
                                                    Icons.visibility_outlined,
                                                    size: 18,
                                                    color: primaryBlue),
                                                label: Text("Mark Viewed",
                                                    style: TextStyle(
                                                        color: primaryBlue,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(
                                                      color: primaryBlue,
                                                      width: 1.5),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                                ),
                                                onPressed: () async {
                                                  await _markAsViewed(item);
                                                },
                                              ),
                                              const SizedBox(width: 12),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryBlue,
                                                  foregroundColor: Colors.white,
                                                  elevation: 2,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 24,
                                                      vertical: 12),
                                                ),
                                                onPressed: () {
                                                  final courseId =
                                                      item['courseId'];
                                                  final contentId = item['Id'];
                                                  final studentId =
                                                      widget.studentId;

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          LessonContentPage(
                                                        courseId: courseId,
                                                        contentId: contentId,
                                                        studentId: studentId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text("Go to Lesson",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                    SizedBox(width: 6),
                                                    Icon(Icons.arrow_forward,
                                                        size: 18),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
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
