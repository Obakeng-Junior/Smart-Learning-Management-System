import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AITutorPage extends StatefulWidget {
  final String studentId;
  const AITutorPage({super.key, required this.studentId});

  @override
  State<AITutorPage> createState() => _AITutorPageState();
}

class _AITutorPageState extends State<AITutorPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  final String apiUrl = "http://10.0.2.2:5287/api/aitutor/ask";
  bool _isLoading = false;
  bool _isLoadingHistory = true;

  final httpClient = IOClient();

  final Color _primaryBlue = const Color(0xFF1976D2);
  final Color _darkBlue = const Color(0xFF0D47A1);
  final Color _lightBlue = const Color(0xFFE3F2FD);
  final Color _accentBlue = const Color(0xFF2196F3);
  final Color _backgroundBlue = const Color(0xFFF8FBFF);

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      print('🔄 Loading chat history for student: ${widget.studentId}');

      QuerySnapshot snapshot;

      try {
        snapshot = await _firestore
            .collection('ai_tutor_chats')
            .where('studentId', isEqualTo: widget.studentId)
            .get();

        print('✅ Query with studentId only successful');
      } catch (e) {
        print('⚠️ Query with studentId failed: $e');
        print('🔄 Trying alternative approach...');

        final allDocs = await _firestore.collection('ai_tutor_chats').get();

        final filteredDocs = allDocs.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['studentId'] == widget.studentId;
        }).toList();

        print('✅ Filtered ${filteredDocs.length} documents locally');

        final loadedMessages = <Map<String, dynamic>>[];

        for (var doc in filteredDocs) {
          final data = doc.data() as Map<String, dynamic>?;

          if (data == null) {
            print('⚠️ Document ${doc.id} has null data');
            continue;
          }

          final question = data['question']?.toString() ?? '';
          final answer = data['answer']?.toString() ?? '';
          final timestamp = data['timestamp'];

          print('💬 Loading - Q: "$question" | A: "$answer"');

          if (question.trim().isNotEmpty) {
            loadedMessages.add({
              'sender': 'student',
              'text': question.trim(),
              'timestamp': _formatTimestamp(timestamp),
              'docId': doc.id,
            });
          }

          if (answer.trim().isNotEmpty) {
            loadedMessages.add({
              'sender': 'ai',
              'text': answer.trim(),
              'timestamp': _formatTimestamp(timestamp),
              'docId': doc.id,
            });
          }
        }

        loadedMessages.sort((a, b) {
          final timeA = a['timestamp']?.toString() ?? '';
          final timeB = b['timestamp']?.toString() ?? '';
          return timeA.compareTo(timeB);
        });

        print('✅ Prepared ${loadedMessages.length} messages for display');

        setState(() {
          _messages.clear();
          _messages.addAll(loadedMessages);
          _isLoadingHistory = false;
        });

        _scrollToBottom();
        return;
      }

      // Process the successful query result
      print('📚 Found ${snapshot.docs.length} chat records in Firestore');

      final loadedMessages = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data == null) {
          print('⚠️ Document ${doc.id} has null data');
          continue;
        }

        final question = data['question']?.toString() ?? '';
        final answer = data['answer']?.toString() ?? '';
        final timestamp = data['timestamp'];

        print('💬 Loading - Q: "$question" | A: "$answer"');

        if (question.trim().isNotEmpty) {
          loadedMessages.add({
            'sender': 'student',
            'text': question.trim(),
            'timestamp': _formatTimestamp(timestamp),
            'docId': doc.id,
          });
        }

        if (answer.trim().isNotEmpty) {
          loadedMessages.add({
            'sender': 'ai',
            'text': answer.trim(),
            'timestamp': _formatTimestamp(timestamp),
            'docId': doc.id,
          });
        }
      }

      // Sort messages by timestamp locally
      loadedMessages.sort((a, b) {
        final timeA = a['timestamp']?.toString() ?? '';
        final timeB = b['timestamp']?.toString() ?? '';
        return timeA.compareTo(timeB);
      });

      print('✅ Prepared ${loadedMessages.length} messages for display');

      setState(() {
        _messages.clear();
        _messages.addAll(loadedMessages);
        _isLoadingHistory = false;
      });

      print('🎉 Chat UI now has ${_messages.length} messages');

      _scrollToBottom();
    } catch (e, stackTrace) {
      print("❌ Error loading chat history: $e");
      print("📝 Stack trace: $stackTrace");
      setState(() {
        _isLoadingHistory = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chat history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now().toString();

    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate().toString();
      } else if (timestamp is String) {
        return timestamp;
      } else {
        return timestamp.toString();
      }
    } catch (e) {
      return DateTime.now().toString();
    }
  }

  Future<void> _sendQuestion(String question) async {
    if (question.trim().isEmpty) return;

    // Create temporary message
    final tempMessage = {
      'sender': 'student',
      'text': question,
      'timestamp': DateTime.now().toString(),
      'isTemp': true,
    };

    setState(() {
      _messages.add(tempMessage);
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    String answer = 'No answer received.';

    try {
      print('📤 Sending question to API: "$question"');
      print('🔗 API URL: $apiUrl');

      // Use the simple HTTP client (no certificate handling needed)
      final response = await httpClient.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      );

      print("📥 API Response Status: ${response.statusCode}");
      print("📥 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        answer = data['answer']?.toString() ?? 'No answer received from API.';
        print('✅ API Response: $answer');
      } else {
        answer = 'Error: ${response.statusCode} ${response.reasonPhrase}';
        print('❌ API Error: $answer');

        // Print response body for more details
        print('❌ Response body: ${response.body}');
      }
    } catch (e) {
      answer = 'Error connecting to API: $e';
      print("❌ API Connection Error: $e");

      // More detailed error information
      if (e is SocketException) {
        print('🔌 Socket Exception - Check if server is running on port 5287');
        answer =
            'Cannot connect to server. Make sure your ASP.NET Core app is running on http://localhost:5287';
      }
    }

    // Remove temporary message and add real ones
    setState(() {
      _messages.removeWhere((msg) => msg['isTemp'] == true);
      _messages.add({
        'sender': 'student',
        'text': question,
        'timestamp': DateTime.now().toString(),
      });
      _messages.add({
        'sender': 'ai',
        'text': answer,
        'timestamp': DateTime.now().toString(),
      });
      _isLoading = false;
    });

    _scrollToBottom();

    // Save to Firestore
    try {
      final chatData = {
        'studentId': widget.studentId,
        'question': question,
        'answer': answer,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('ai_tutor_chats').add(chatData);
      print('✅ Successfully saved to Firestore');

      // Reload history to get proper timestamps
      _loadChatHistory();
    } catch (e) {
      print("❌ Firestore save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save message: ${e.toString()}'),
            backgroundColor: _accentBlue,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isStudent = message['sender'] == 'student';
    final text = message['text']?.toString() ?? '';
    final sender = isStudent ? 'You' : 'AI Tutor';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isStudent ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isStudent) ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_primaryBlue, _darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isStudent
                    ? LinearGradient(
                        colors: [_primaryBlue, _darkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.white, _lightBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: isStudent
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  topRight: isStudent
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isStudent ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sender,
                    style: TextStyle(
                      color: isStudent
                          ? Colors.white70
                          : _primaryBlue.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isStudent) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_accentBlue, _primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accentBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundBlue,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'AI Tutor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: _primaryBlue,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isLoadingHistory = true;
                    });
                    _loadChatHistory();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoadingHistory)
            LinearProgressIndicator(
              backgroundColor: _lightBlue,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _backgroundBlue,
                    _lightBlue.withOpacity(0.3),
                  ],
                ),
              ),
              child: _isLoadingHistory
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_primaryBlue),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Loading your chat history...",
                            style: TextStyle(
                              fontSize: 16,
                              color: _darkBlue.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryBlue.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    size: 80,
                                    color: _primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  "Start a conversation with your AI Tutor!",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: _darkBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Ask anything you want to learn about your courses",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _darkBlue.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _lightBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessage(_messages[index]);
                          },
                        ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                backgroundColor: _lightBlue,
                valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
              ),
            ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: _lightBlue,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendQuestion,
                    decoration: InputDecoration(
                      hintText: 'Ask a question about your course...',
                      hintStyle: TextStyle(
                        color: _darkBlue.withOpacity(0.4),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    style: TextStyle(
                      color: _darkBlue,
                      fontSize: 14,
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: (_isLoading || _isLoadingHistory)
                        ? null
                        : LinearGradient(
                            colors: [_accentBlue, _primaryBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    shape: BoxShape.circle,
                    boxShadow: (_isLoading || _isLoadingHistory)
                        ? null
                        : [
                            BoxShadow(
                              color: _primaryBlue.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: IconButton(
                    onPressed: (_isLoading || _isLoadingHistory)
                        ? null
                        : () => _sendQuestion(_controller.text),
                    icon: Icon(
                      Icons.send,
                      color: (_isLoading || _isLoadingHistory)
                          ? _darkBlue.withOpacity(0.3)
                          : Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: (_isLoading || _isLoadingHistory)
                          ? _lightBlue
                          : Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
