using AI_Powered_Learning_Application.Models;
using AI_Powered_Learning_Application.Services;
using Google.Cloud.Firestore;
using Google.Cloud.Firestore.V1;
using Microsoft.AspNetCore.Mvc;

namespace AI_Powered_Learning_Application.Controllers
{
    public class QuizController : Controller
    {
        private readonly FirestoreDb _firestoreDb;
        public QuizController(FirebaseService firebaseService)
        {
            _firestoreDb = firebaseService.GetDb();
        }

        [HttpGet]
        public IActionResult Create(string courseId, string contentId)
        {
            var model = new Quiz
            {
                CourseId = courseId,
                ContentId = contentId
            };

            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> Create(string courseId, string contentId, Quiz quiz)
        {
            try
            {
                var quizRef = _firestoreDb
                    .Collection("courses")
                    .Document(courseId)
                    .Collection("contents")
                    .Document(contentId)
                    .Collection("quizzes");

                // Create the quiz data with CreatedAt timestamp
                var quizData = new
                {
                    Question = quiz.Question,
                    OptionA = quiz.OptionA,
                    OptionB = quiz.OptionB,
                    OptionC = quiz.OptionC,
                    OptionD = quiz.OptionD,
                    CorrectAnswer = quiz.CorrectAnswer,
                  
                    CreatedAt = DateTime.UtcNow, // Add the creation timestamp
                    CourseId = courseId, // Store for reference
                    ContentId = contentId // Store for reference
                };

                await quizRef.AddAsync(quizData);

                TempData["SuccessMessage"] = "Quiz created successfully!";

                // Redirect to the content details page
                return RedirectToAction(
                    "Details",
                    "CourseContent",
                    new { courseId = courseId, contentId = contentId }
                );
            }
            catch (Exception ex)
            {
                // Log the error
                TempData["ErrorMessage"] = "An error occurred while creating the quiz. Please try again.";
                return View(quiz);
            }
        }

        // Optional: Add Edit and Delete actions if needed later
        [HttpGet]
        public async Task<IActionResult> Edit(string courseId, string contentId, string quizId)
        {
            try
            {
                var quizDoc = _firestoreDb
                    .Collection("courses")
                    .Document(courseId)
                    .Collection("contents")
                    .Document(contentId)
                    .Collection("quizzes")
                    .Document(quizId);

                var snapshot = await quizDoc.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    TempData["ErrorMessage"] = "Quiz not found.";
                    return RedirectToAction("Details", "CourseContent", new { courseId, contentId });
                }

                var quiz = snapshot.ConvertTo<Quiz>();
                quiz.Id = quizId;
                quiz.CourseId = courseId;
                quiz.ContentId = contentId;

                return View(quiz);
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "Error loading quiz for editing.";
                return RedirectToAction("Details", "CourseContent", new { courseId, contentId });
            }
        }

        [HttpPost]
        public async Task<IActionResult> Edit(string courseId, string contentId, string quizId, Quiz quiz)
        {
            try
            {
                var quizDoc = _firestoreDb
                    .Collection("courses")
                    .Document(courseId)
                    .Collection("contents")
                    .Document(contentId)
                    .Collection("quizzes")
                    .Document(quizId);

                // Update the quiz data (keep original CreatedAt)
                var updateData = new Dictionary<string, object>
                {
                    { "Question", quiz.Question },
                    { "OptionA", quiz.OptionA },
                    { "OptionB", quiz.OptionB },
                    { "OptionC", quiz.OptionC },
                    { "OptionD", quiz.OptionD },
                    { "CorrectAnswer", quiz.CorrectAnswer },
                   
                };

                await quizDoc.UpdateAsync(updateData);

                TempData["SuccessMessage"] = "Quiz updated successfully!";
                return RedirectToAction("Details", "CourseContent", new { courseId, contentId });
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "Error updating quiz.";
                return View(quiz);
            }
        }

        [HttpPost]
        public async Task<IActionResult> Delete(string courseId, string contentId, string quizId)
        {
            try
            {
                var quizDoc = _firestoreDb
                    .Collection("courses")
                    .Document(courseId)
                    .Collection("contents")
                    .Document(contentId)
                    .Collection("quizzes")
                    .Document(quizId);

                await quizDoc.DeleteAsync();

                TempData["SuccessMessage"] = "Quiz deleted successfully!";
                return RedirectToAction("Details", "CourseContent", new { courseId, contentId });
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "Error deleting quiz.";
                return RedirectToAction("Details", "CourseContent", new { courseId, contentId });
            }
        }
    }
}