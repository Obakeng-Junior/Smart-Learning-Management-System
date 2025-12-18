import 'package:ai_powered_learning_application/pages/course_enrollment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../routes/routes.dart';
import 'ai_tutor.dart';
import 'homepage.dart';
import 'recommend_content_page.dart';

class StudentProfilePage extends StatefulWidget {
  final String studentId;

  const StudentProfilePage({super.key, required this.studentId});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();

  String? skillLevel;
  String? learningPreference;
  List<String> selectedSubjects = [];

  final List<String> skillLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> learningPreferences = [
    'Visual',
    'Video',
    'Reading/Writing'
  ];
  final List<String> availableSubjects = [
    'Information Technology',
    'Computer Systems',
    'Electrical Engineering',
    'Civil Engineering',
    'Mechanical Engineering',
    'Built Environment / Architecture',
    'Health Sciences',
    'Environmental Health',
    'Biomedical Technology',
    'Clinical Technology',
    'Radiography',
    'Education',
    'Language and Communication',
    'Design and Studio Art',
    'Accounting',
    'Entrepreneurship',
    'Human Resource Management',
    'Public Management',
    'Marketing',
    'Tourism and Hospitality',
    'Business Administration',
    'Mathematics',
    'Physics',
    'Biology',
    'Chemistry',
  ];

  bool isLoading = true;

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
    final doc =
        await _firestore.collection('students').doc(widget.studentId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nameController.text = data['name'] ?? '';
        surnameController.text = data['surname'] ?? '';
        skillLevel = data['skillLevel'];
        learningPreference = data['learningPreference'];
        selectedSubjects = List<String>.from(data['subjectsOfInterest'] ?? []);
        isLoading = false;
      });
    }
  }

  Future<void> _updateField(String field, dynamic value) async {
    await _firestore
        .collection('students')
        .doc(widget.studentId)
        .update({field: value});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Get skill level color
  Color _getSkillLevelColor(String? level) {
    switch (level?.toLowerCase()) {
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
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gradientStart, backgroundBlue],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  "Loading your profile...",
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
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
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Profile Info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  children: [
                    // Profile Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name
                    Text(
                      '${nameController.text} ${surnameController.text}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Skill Level Badge
                    if (skillLevel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
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
                              'Skill Level: $skillLevel',
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
                    // Subjects Count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.interests, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${selectedSubjects.length} Subjects of Interest',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Title
                      const Text(
                        'Profile Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your learning preferences and personal information',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Profile Options
                      _buildProfileOption(
                        title: 'Personal Information',
                        subtitle: 'Update your name and contact details',
                        icon: Icons.person_outline,
                        iconColor: primaryBlue,
                        onTap: () => _showPersonalInfoDialog(),
                      ),
                      _buildProfileOption(
                        title: 'Subjects of Interest',
                        subtitle: 'Choose topics you want to learn about',
                        icon: Icons.interests_outlined,
                        iconColor: Color(0xFF0F9D58),
                        onTap: () => _showSubjectsDialog(),
                      ),
                      _buildProfileOption(
                        title: 'Skill Level',
                        subtitle: 'Set your current expertise level',
                        icon: Icons.star_outline,
                        iconColor: Color(0xFFF4B400),
                        onTap: () => _showSkillLevelDialog(),
                      ),
                      const SizedBox(height: 30),

                      // Log Out Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _logout(),
                          icon: Icon(Icons.logout, size: 20),
                          label: Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
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

  Widget _buildProfileOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
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
                          fontWeight: FontWeight.w600,
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

  void _showPersonalInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Personal Information',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: darkBlue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: surnameController,
              decoration: InputDecoration(
                labelText: 'Surname',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateField('name', nameController.text.trim());
              await _updateField('surname', surnameController.text.trim());
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showSubjectsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subjects of Interest',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select the subjects you are interested in learning',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 400,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSubjects.map((subject) {
                      final selected = selectedSubjects.contains(subject);
                      return FilterChip(
                        label: Text(
                          subject,
                          style: TextStyle(
                            color: selected ? Colors.white : darkBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: selected,
                        onSelected: (bool selected) async {
                          setState(() {
                            if (selected) {
                              selectedSubjects.add(subject);
                            } else {
                              selectedSubjects.remove(subject);
                            }
                          });
                          await _updateField(
                              'subjectsOfInterest', selectedSubjects);
                        },
                        selectedColor: primaryBlue,
                        backgroundColor: lightBlue,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Selection',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSkillLevelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Skill Level',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: darkBlue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select your current skill level to get personalized course recommendations',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: skillLevel,
              hint: const Text('Select skill level'),
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: skillLevels.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getSkillLevelColor(level),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(level),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => skillLevel = value);
                _updateField('skillLevel', value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log Out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: darkBlue,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
