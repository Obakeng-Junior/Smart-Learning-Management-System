using AI_Powered_Learning_Application.Models.ViewModels;
using AI_Powered_Learning_Application.Services;
using Google.Cloud.Firestore;
using Microsoft.AspNetCore.Mvc;

namespace AI_Powered_Learning_Application.Controllers
{
    public class StudentProgressController : Controller
    {
        private readonly FirestoreDb _firestoreDb;

        public StudentProgressController(FirebaseService firebaseService)
        {
            _firestoreDb = firebaseService.GetDb();
        }

        private async Task<string> GetCourseName(string courseId)
        {
            try
            {
                var courseDoc = _firestoreDb.Collection("courses").Document(courseId);
                var snapshot = await courseDoc.GetSnapshotAsync();
                if (snapshot.Exists)
                {
                    var courseData = snapshot.ToDictionary();
                    return courseData.ContainsKey("Title") ? courseData["Title"].ToString() : courseId;
                }
                return courseId;
            }
            catch
            {
                return courseId;
            }
        }

        private async Task<Dictionary<string, List<QuizResponseViewModel>>> GetStudentQuizResponses(string studentId, string courseId)
        {
            var quizResponses = new Dictionary<string, List<QuizResponseViewModel>>();

            try
            {
                var contentsSnapshot = await _firestoreDb.Collection("courses").Document(courseId)
                    .Collection("contents").GetSnapshotAsync();

                foreach (var contentDoc in contentsSnapshot.Documents)
                {
                    var contentId = contentDoc.Id;

                    var responsesSnapshot = await _firestoreDb.Collection("courses").Document(courseId)
                        .Collection("contents").Document(contentId)
                        .Collection("quizResponses")
                        .WhereEqualTo("studentId", studentId)
                        .OrderBy("attempt")
                        .GetSnapshotAsync();

                    var contentResponses = new List<QuizResponseViewModel>();

                    foreach (var responseDoc in responsesSnapshot.Documents)
                    {
                        var responseData = responseDoc.ToDictionary();
                        var response = new QuizResponseViewModel
                        {
                            ResponseId = responseDoc.Id,
                            ContentId = responseData.ContainsKey("contentId") ? responseData["contentId"]?.ToString() : contentId,
                            CourseId = responseData.ContainsKey("courseId") ? responseData["courseId"]?.ToString() : courseId,
                            Attempt = responseData.ContainsKey("attempt") ? Convert.ToInt32(responseData["attempt"]) : 1,
                            IsCorrect = responseData.ContainsKey("isCorrect") && responseData["isCorrect"] is bool correct && correct,

                            // Both scores - Option 1
                            QuizScore = responseData.ContainsKey("quizScore") ? Convert.ToDouble(responseData["quizScore"]) : 0,
                            PointsScore = responseData.ContainsKey("score") ? Convert.ToInt32(responseData["score"]) : 0,

                            SelectedAnswer = responseData.ContainsKey("selectedAnswer") ? responseData["selectedAnswer"]?.ToString() : null,
                            CorrectAnswer = responseData.ContainsKey("correctAnswer") ? responseData["correctAnswer"]?.ToString() : null,
                            Question = responseData.ContainsKey("question") ? responseData["question"]?.ToString() : "Unknown Question",
                            Timestamp = responseData.ContainsKey("timestamp") && responseData["timestamp"] is Timestamp ts
                                ? ts.ToDateTime() : DateTime.MinValue
                        };

                        contentResponses.Add(response);
                    }

                    // Mark the best attempt for each content
                    if (contentResponses.Any())
                    {
                        var bestAttempt = contentResponses
                            .OrderByDescending(r => r.QuizScore)
                            .ThenByDescending(r => r.PointsScore)
                            .First();

                        bestAttempt.IsBestAttempt = true;
                        quizResponses[contentId] = contentResponses;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error fetching quiz responses: {ex.Message}");
            }

            return quizResponses;
        }

        public async Task<IActionResult> Details(string id)
        {
            if (string.IsNullOrEmpty(id))
                return NotFound();

            var studentDoc = _firestoreDb.Collection("students").Document(id);
            var snapshot = await studentDoc.GetSnapshotAsync();

            if (!snapshot.Exists)
                return NotFound();

            var studentData = snapshot.ToDictionary();
            var detailViewModel = new StudentDetailViewModel
            {
                Id = id,
                Name = studentData.ContainsKey("name") ? studentData["name"]?.ToString() : "Unknown",
                Surname = studentData.ContainsKey("surname") ? studentData["surname"]?.ToString() : "",
                Email = studentData.ContainsKey("email") ? studentData["email"]?.ToString() : "No email",
                CreatedAt = studentData.ContainsKey("createdAt") && studentData["createdAt"] is Timestamp tsCreated
                    ? tsCreated.ToDateTime()
                    : DateTime.MinValue,
                LastActivity = studentData.ContainsKey("lastActivity") && studentData["lastActivity"] is Timestamp tsLast
                    ? tsLast.ToDateTime()
                    : DateTime.MinValue,
                EnrolledCourses = studentData.ContainsKey("enrolledCourses") && studentData["enrolledCourses"] is List<object> enrolled
                    ? enrolled.Select(x => x?.ToString()).Where(x => !string.IsNullOrEmpty(x)).ToList()
                    : new List<string>(),
                SubjectsOfInterest = studentData.ContainsKey("subjectsOfInterest") && studentData["subjectsOfInterest"] is List<object> subjects
                    ? subjects.Select(x => x?.ToString()).Where(x => !string.IsNullOrEmpty(x)).ToList()
                    : new List<string>(),
                TotalScore = studentData.ContainsKey("totalScore") ? Convert.ToInt32(studentData["totalScore"]) : 0,
                SkillLevel = studentData.ContainsKey("skillLevel") ? studentData["skillLevel"]?.ToString() : "Not set",
                Status = studentData.ContainsKey("isDeleted") && studentData["isDeleted"] is bool deleted && deleted
                    ? "Deleted" : "Active",
                CourseProgress = new List<CourseProgressViewModel>()
            };

            // Load basic progress from student document
            var studentProgress = new Dictionary<string, Dictionary<string, object>>();

            if (studentData.ContainsKey("progress") && studentData["progress"] is Dictionary<string, object> progressData)
            {
                foreach (var progressItem in progressData)
                {
                    var contentId = progressItem.Key;
                    var progressDetails = progressItem.Value as Dictionary<string, object>;

                    if (progressDetails != null)
                    {
                        studentProgress[contentId] = progressDetails;
                    }
                }
            }

            // Build detailed progress for each enrolled course
            foreach (var courseId in detailViewModel.EnrolledCourses)
            {
                var quizResponses = await GetStudentQuizResponses(id, courseId);

                var courseProgress = new CourseProgressViewModel
                {
                    CourseId = courseId,
                    CourseName = await GetCourseName(courseId),
                    Lessons = new List<LessonProgressViewModel>()
                };

                var contentsSnapshot = await _firestoreDb.Collection("courses").Document(courseId)
                    .Collection("contents").GetSnapshotAsync();

                foreach (var contentDoc in contentsSnapshot.Documents)
                {
                    var contentId = contentDoc.Id;
                    var contentData = contentDoc.ToDictionary();

                    // Get basic progress
                    Dictionary<string, object> basicProgress = null;
                    if (studentProgress.ContainsKey(contentId))
                    {
                        basicProgress = studentProgress[contentId];
                    }

                    // Get quiz responses
                    var contentQuizResponses = quizResponses.ContainsKey(contentId)
                        ? quizResponses[contentId]
                        : new List<QuizResponseViewModel>();

                    // Calculate completion status
                    var isQuizCompleted = contentQuizResponses.Any(r => r.QuizScore >= 80);
                    var bestAttempt = contentQuizResponses
                        .OrderByDescending(r => r.QuizScore)
                        .ThenByDescending(r => r.PointsScore)
                        .FirstOrDefault();

                    var lessonProgress = new LessonProgressViewModel
                    {
                        LessonId = contentId,
                        LessonName = contentData.ContainsKey("Title") ? contentData["Title"].ToString() : contentId,
                        Viewed = basicProgress?.ContainsKey("viewed") == true &&
                                basicProgress["viewed"] is bool viewed && viewed,
                        LastViewed = basicProgress?.ContainsKey("lastViewed") == true &&
                                   basicProgress["lastViewed"] is Timestamp tsLastViewed
                            ? tsLastViewed.ToDateTime()
                            : DateTime.MinValue,
                        Completed = (basicProgress?.ContainsKey("completed") == true &&
                                   basicProgress["completed"] is bool completed && completed)
                                   || isQuizCompleted,
                        Attempts = contentQuizResponses.Count,

                        // Both scores - use best attempt
                        QuizScore = bestAttempt?.QuizScore ?? 0,
                        PointsScore = bestAttempt?.PointsScore ?? 0,
                        MaxPossiblePoints = 1,

                        SelectedAnswer = bestAttempt?.SelectedAnswer,
                        CompletedAt = basicProgress?.ContainsKey("completedAt") == true &&
                                     basicProgress["completedAt"] is Timestamp tsCompletedAt
                            ? tsCompletedAt.ToDateTime()
                            : (bestAttempt?.Timestamp ?? DateTime.MinValue),
                        QuizResponses = contentQuizResponses
                    };

                    courseProgress.Lessons.Add(lessonProgress);
                }

                detailViewModel.CourseProgress.Add(courseProgress);
            }

            return View(detailViewModel);
        }

        public IActionResult Index()
        {
            return View();
        }
    }
}