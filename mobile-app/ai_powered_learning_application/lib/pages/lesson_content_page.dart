import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'student_progress_tracking.dart';

class LessonContentPage extends StatefulWidget {
  final String courseId;
  final String contentId;
  final String studentId;

  const LessonContentPage({
    super.key,
    required this.courseId,
    required this.contentId,
    required this.studentId,
  });

  @override
  State<LessonContentPage> createState() => _LessonContentPageState();
}

class _LessonContentPageState extends State<LessonContentPage> {
  String? selectedAnswer;
  bool answered = false;
  bool isSubmitting = false;
  String? correctAnswer;
  Map<String, dynamic>? quizData;
  bool isLoadingQuiz = false;
  String? errorMessage;
  List<Map<String, dynamic>> allQuizzes = [];
  bool showDebugInfo = false;
  int score = 0;
  int totalQuestions = 0;
  Map<String, dynamic>? quizResponse;
  Map<String, dynamic> progress = {};
  bool hasViewedContent = false;
  int attempts = 0;
  bool _isDownloadingPdf = false;
  final Map<String, WebViewController> _webViewControllers = {};

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition if on Android (new way)
    if (Platform.isAndroid) {
      // This is handled automatically in newer versions
      // No need for SurfaceAndroidWebView initialization
    }
    _loadStudentProgress();
    _fetchQuiz();
  }

  Future<void> _loadStudentProgress() async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (studentDoc.exists) {
        setState(() {
          progress =
              Map<String, dynamic>.from(studentDoc.data()?['progress'] ?? {});

          // Get attempts for this lesson
          final courseProgress =
              progress[widget.courseId] as Map<String, dynamic>?;
          if (courseProgress != null) {
            final lessonProgress =
                courseProgress[widget.contentId] as Map<String, dynamic>?;
            if (lessonProgress != null) {
              attempts = lessonProgress['attempts'] ?? 0;
              answered = lessonProgress['completed'] ?? false;
              score = lessonProgress['quizScore'] ?? 0;
              selectedAnswer = lessonProgress['selectedAnswer'];
              hasViewedContent = lessonProgress['viewed'] ?? false;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading student progress: $e');
    }
  }

  Future<void> _markContentAsViewed() async {
    if (hasViewedContent) return;

    try {
      setState(() {
        hasViewedContent = true;
      });

      // Update progress in Firestore
      final updateData = {
        'progress.${widget.courseId}.${widget.contentId}.viewed': true,
        'progress.${widget.courseId}.${widget.contentId}.lastViewed':
            FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .update(updateData);

      await _loadStudentProgress();
    } catch (e) {
      print('Error marking content as viewed: $e');
    }
  }

  Future<void> _fetchQuiz() async {
    setState(() {
      isLoadingQuiz = true;
      errorMessage = null;
    });

    try {
      final quizSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('contents')
          .doc(widget.contentId)
          .collection('quizzes')
          .get();

      if (quizSnapshot.docs.isNotEmpty) {
        setState(() {
          quizData = quizSnapshot.docs.first.data();
          correctAnswer = quizData?['CorrectAnswer'];
          allQuizzes = quizSnapshot.docs.map((doc) => doc.data()).toList();
          isLoadingQuiz = false;
          totalQuestions = quizSnapshot.docs.length;
        });
      } else {
        setState(() {
          isLoadingQuiz = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingQuiz = false;
        errorMessage = "Error loading quiz: $e";
      });
      print('Error fetching quiz: $e');
    }
  }

  Future<void> _submitQuizResponse() async {
    if (selectedAnswer == null) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final isCorrect = selectedAnswer == correctAnswer;
      final points = isCorrect ? 1 : 0;
      final quizScore = isCorrect ? 100 : 0;

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('contents')
          .doc(widget.contentId)
          .collection('quizResponses')
          .add({
        'studentId': widget.studentId,
        'selectedAnswer': selectedAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
        'score': points,
        'quizScore': quizScore,
        'timestamp': FieldValue.serverTimestamp(),
        'question': quizData?['Question'],
        'quizId': allQuizzes.isNotEmpty ? allQuizzes[0]['id'] : 'unknown',
        'courseId': widget.courseId,
        'contentId': widget.contentId,
        'attempt': attempts + 1,
      });

      final updateData = {
        'lastActivity': FieldValue.serverTimestamp(),
        'progress.${widget.courseId}.${widget.contentId}.completed': true,
        'progress.${widget.courseId}.${widget.contentId}.quizScore': quizScore,
        'progress.${widget.courseId}.${widget.contentId}.selectedAnswer':
            selectedAnswer,
        'progress.${widget.courseId}.${widget.contentId}.completedAt':
            FieldValue.serverTimestamp(),
        'progress.${widget.courseId}.${widget.contentId}.attempts':
            attempts + 1,
      };

      final courseProgress = progress[widget.courseId] as Map<String, dynamic>?;
      final previouslyCompleted = courseProgress != null &&
          courseProgress[widget.contentId] != null &&
          courseProgress[widget.contentId]['completed'] == true;

      if (!previouslyCompleted) {
        updateData['totalScore'] = FieldValue.increment(points);
      }

      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .update(updateData);

      await _loadStudentProgress();

      setState(() {
        answered = true;
        isSubmitting = false;
        score = points;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCorrect
              ? "✅ Correct! Well done. ${previouslyCompleted ? '' : '+1 point'}"
              : "❌ Incorrect. The correct answer is $correctAnswer"),
          backgroundColor: isCorrect ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting quiz: $e"),
          backgroundColor: Colors.red,
        ),
      );
      print('Error submitting quiz: $e');
    }
  }

  // PDF Download and Open Functions
  Future<void> _downloadAndOpenPdf(String url) async {
    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      print('Downloading PDF from: $url');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Opening PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Downloading: ${_getPdfFileName(url)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = _getPdfFileName(url);
        final file = File('${tempDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);
        print('PDF downloaded to: ${file.path}');

        Navigator.of(context).pop();

        final result = await OpenFile.open(file.path);

        if (result.type == ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF opened successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open PDF: ${result.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        Navigator.of(context).pop();
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('Error downloading/opening PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isDownloadingPdf = false;
      });
    }
  }

  Future<void> _openPdf(String url) async {
    _markContentAsViewed();
    await _downloadAndOpenPdf(url);
  }

  Widget _buildPdfCard(String url) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: _isDownloadingPdf
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: const Text(
          "PDF Document",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getPdfFileName(url),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              _isDownloadingPdf ? 'Downloading...' : 'Tap to download and open',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: _isDownloadingPdf
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download, size: 20),
        onTap: () {
          _openPdf(url);
        },
      ),
    );
  }

  Widget _buildExternalResourceCard(String url) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.launch, color: Colors.blue),
        title: const Text(
          "Web Resource",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getResourceName(url),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap to open in browser',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.open_in_new, size: 20),
        onTap: () {
          _markContentAsViewed();
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
      ),
    );
  }

  Widget _buildYouTubeCard(String url, String videoId) {
    // Create HTML for YouTube embed
    final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            margin: 0;
            padding: 0;
            background: black;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
          }
          .container {
            width: 100%;
            height: 100%;
          }
          iframe {
            width: 100%;
            height: 100%;
            border: none;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <iframe 
            src="https://www.youtube.com/embed/$videoId?rel=0&modestbranding=1&playsinline=0"
            frameborder="0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowfullscreen>
          </iframe>
        </div>
      </body>
      </html>
    ''';

    // Create WebViewController
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('WebView loading: $progress%');
          },
          onPageStarted: (String url) {
            print('WebView started loading: $url');
          },
          onPageFinished: (String url) {
            print('WebView finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle navigation requests (like clicking YouTube links)
            if (request.url.contains('youtube.com') ||
                request.url.contains('youtube-nocookie.com')) {
              return NavigationDecision.navigate;
            }
            // Block other external URLs
            if (!request.url.startsWith('about:blank')) {
              _openYouTubeInApp(videoId);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(htmlContent);

    _webViewControllers[videoId] = controller;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.play_circle_filled, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  "YouTube Video",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 20),
                  onPressed: () {
                    _markContentAsViewed();
                    _openYouTubeInApp(videoId);
                  },
                  tooltip: 'Open in YouTube App',
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: WebViewWidget(controller: controller),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Video ID: $videoId • Tap fullscreen for best experience',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _openYouTubeInApp(String videoId) async {
    try {
      // Try to open in YouTube app first
      final youtubeAppUri = Uri.parse('youtube://watch?v=$videoId');
      final youtubeWebUri = Uri.parse('https://youtube.com/watch?v=$videoId');

      if (await canLaunchUrl(youtubeAppUri)) {
        await launchUrl(youtubeAppUri);
      } else {
        // Fallback to web version
        await launchUrl(youtubeWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Final fallback
      await launchUrl(
        Uri.parse('https://youtube.com/watch?v=$videoId'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  String _getResourceName(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain;
    } catch (e) {
      return 'External Link';
    }
  }

  String _getPdfFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        String fileName = pathSegments.lastWhere(
          (segment) => segment.contains('.pdf'),
          orElse: () => 'document.pdf',
        );

        if (fileName.contains('%2F')) {
          fileName = Uri.decodeComponent(fileName);
        }

        if (fileName.contains('?')) {
          fileName = fileName.split('?').first;
        }

        if (fileName.contains('/')) {
          fileName = fileName.split('/').last;
        }

        if (fileName.length > 30) {
          fileName = '${fileName.substring(0, 27)}...';
        }
        return fileName;
      }
    } catch (e) {
      print('Error parsing PDF URL: $e');
    }
    return 'document.pdf';
  }

  String _extractYouTubeId(String url) {
    try {
      final regExp = RegExp(
        r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
        caseSensitive: false,
      );
      final match = regExp.firstMatch(url);
      return (match != null &&
              match.group(7) != null &&
              match.group(7)!.length == 11)
          ? match.group(7)!
          : '';
    } catch (e) {
      return '';
    }
  }

  Widget _buildNoQuizMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            "No Quiz Available",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "This lesson doesn't have a quiz yet.\nCheck back later or continue with the next lesson.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Lesson Content"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentProgressPage(
                    studentId: widget.studentId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('contents')
            .doc(widget.contentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Content not found",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Path: courses/${widget.courseId}/contents/${widget.contentId}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          List contentUrls = data['ContentUrls'] ?? [];
          String title = data['Title'] ?? 'Untitled Lesson';
          String description =
              data['Description'] ?? 'No description available';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Status
                Card(
                  color: answered ? Colors.green.shade50 : Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          answered
                              ? Icons.check_circle
                              : Icons.play_circle_outline,
                          color: answered ? Colors.green : Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                answered ? "Lesson Completed" : "In Progress",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: answered ? Colors.green : Colors.blue,
                                ),
                              ),
                              if (answered)
                                Text(
                                  "Score: $score% ",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              if (attempts > 0)
                                Text(
                                  "Attempts: $attempts",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (showDebugInfo) _buildDebugInfo(data),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),

                if (contentUrls.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Lesson Materials:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...contentUrls.map((url) {
                        if (url.contains("youtube.com") ||
                            url.contains("youtu.be")) {
                          String videoId = _extractYouTubeId(url);
                          if (videoId.isNotEmpty) {
                            return _buildYouTubeCard(url, videoId);
                          } else {
                            return _buildExternalResourceCard(url);
                          }
                        } else if (url.endsWith(".pdf")) {
                          return _buildPdfCard(url);
                        } else {
                          return _buildExternalResourceCard(url);
                        }
                      }),
                    ],
                  )
                else
                  const Text(
                    "No materials available for this lesson",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),

                const Divider(thickness: 1.5, height: 40),

                Row(
                  children: [
                    const Text(
                      "Lesson Quiz",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (answered) ...[
                      const SizedBox(width: 10),
                      Icon(
                        score > 0 ? Icons.check_circle : Icons.cancel,
                        color: score > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Score: ${score > 0 ? '100%' : '0%'}",
                        style: TextStyle(
                          color: score > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Test your understanding of this lesson",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                if (isLoadingQuiz)
                  const Center(child: CircularProgressIndicator())
                else if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            const Text(
                              "Error loading quiz",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchQuiz,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                else if (quizData == null || quizData!.isEmpty)
                  _buildNoQuizMessage()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quizData!['Question'] ?? 'No question available',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...["A", "B", "C", "D"].map((option) {
                        String optionText = quizData!["Option$option"] ?? '';
                        if (optionText.isEmpty) return const SizedBox();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: answered
                              ? (option == correctAnswer
                                  ? Colors.green.shade50
                                  : (option == selectedAnswer
                                      ? Colors.red.shade50
                                      : null))
                              : null,
                          child: RadioListTile<String>(
                            title: Text(
                              "$option. $optionText",
                              style: TextStyle(
                                fontWeight: option == selectedAnswer
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            value: option,
                            groupValue: selectedAnswer,
                            onChanged: answered
                                ? null
                                : (value) {
                                    setState(() => selectedAnswer = value);
                                  },
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      if (!answered)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: selectedAnswer == null || isSubmitting
                                ? null
                                : _submitQuizResponse,
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Submit Answer",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      if (answered && selectedAnswer != correctAnswer) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                selectedAnswer = null;
                                answered = false;
                              });
                            },
                            child: const Text("Try Again"),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebugInfo(Map<String, dynamic> contentData) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Progress Structure",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Current progress data structure:",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              progress.toString(),
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadStudentProgress,
              child: const Text("Refresh Progress Data"),
            ),
          ],
        ),
      ),
    );
  }
}
