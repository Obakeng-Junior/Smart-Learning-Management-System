using AI_Powered_Learning_Application.Models;
using AI_Powered_Learning_Application.Models.ViewModels;
using AI_Powered_Learning_Application.Services;
using Google.Cloud.Firestore;
using Microsoft.AspNetCore.Mvc;

namespace AI_Powered_Learning_Application.Controllers
{
    public class StudentController : Controller
    {
        private readonly FirebaseService _firebaseService;
        private readonly FirestoreDb _firestoreDb;

        public StudentController(FirebaseService firebaseService)
        {
            _firebaseService = firebaseService;
            _firestoreDb = firebaseService.GetDb();
        }

        // GET: Students Index
        public async Task<IActionResult> Index(string searchTerm)
        {
            var studentsCollection = _firestoreDb.Collection("students");
            var snapshot = await studentsCollection.GetSnapshotAsync();

            var students = new List<StudentViewModel>();

            foreach (var document in snapshot.Documents)
            {
                var studentData = document.ToDictionary();

                // Skip deleted students unless specifically searching for them
                bool isDeleted = studentData.ContainsKey("isDeleted") && (bool)studentData["isDeleted"];
                if (isDeleted && string.IsNullOrEmpty(searchTerm))
                    continue;

                var student = new StudentViewModel
                {
                    Id = document.Id,
                    Name = studentData.ContainsKey("name") ? studentData["name"].ToString() : "Unknown",
                    Surname = studentData.ContainsKey("surname") ? studentData["surname"].ToString() : "",
                    Email = studentData.ContainsKey("email") ? studentData["email"].ToString() : "No email",
                    CreatedAt = studentData.ContainsKey("createdAt") ?
                        ((Timestamp)studentData["createdAt"]).ToDateTime() : DateTime.MinValue,
                    LastActivity = studentData.ContainsKey("lastActivity") && studentData["lastActivity"] != null ?
                        ((Timestamp)studentData["lastActivity"]).ToDateTime() : DateTime.MinValue,
                    Status = isDeleted ? "Deleted" : "Active",
                    EnrolledCoursesCount = studentData.ContainsKey("enrolledCourses") ?
                        ((List<object>)studentData["enrolledCourses"]).Count : 0
                };

                // Apply search filter
                if (string.IsNullOrEmpty(searchTerm) ||
                    student.Name.Contains(searchTerm, StringComparison.OrdinalIgnoreCase) ||
                    student.Surname.Contains(searchTerm, StringComparison.OrdinalIgnoreCase) ||
                    student.Email.Contains(searchTerm, StringComparison.OrdinalIgnoreCase) ||
                    student.Status.Contains(searchTerm, StringComparison.OrdinalIgnoreCase))
                {
                    students.Add(student);
                }
            }

            ViewBag.SearchTerm = searchTerm;
            return View(students.OrderByDescending(s => s.CreatedAt).ToList());
        }

        // GET: Student Details
    

        // GET: Create Student
        public IActionResult Create()
        {
            return View();
        }

        // POST: Create Student
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(StudentCreateViewModel model)
        {
            
                try
                {
                    var studentData = new Dictionary<string, object>
                    {
                        ["name"] = model.Name,
                        ["surname"] = model.Surname,
                        ["email"] = model.Email,
                        ["createdAt"] = Timestamp.FromDateTime(DateTime.UtcNow),
                        ["lastActivity"] = Timestamp.FromDateTime(DateTime.UtcNow),
                        ["isDeleted"] = false,
                        ["enrolledCourses"] = new List<string>(),
                        ["subjectsOfInterest"] = model.SubjectsOfInterest ?? new List<string>(),
                        ["skillLevel"] = model.SkillLevel ?? "Beginner",
                        ["totalScore"] = 0
                    };

                    await _firestoreDb.Collection("students").AddAsync(studentData);

                    TempData["SuccessMessage"] = "Student created successfully!";
                    return RedirectToAction(nameof(Index));
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("", $"Error creating student: {ex.Message}");
                }
            

            return View(model);
        }

       

      
        public async Task<IActionResult> Delete(string id)
        {
            if (string.IsNullOrEmpty(id))
                return NotFound();

            var studentDoc = _firestoreDb.Collection("students").Document(id);
            var snapshot = await studentDoc.GetSnapshotAsync();

            if (!snapshot.Exists)
                return NotFound();

            var studentData = snapshot.ToDictionary();
            var student = new StudentViewModel
            {
                Id = id,
                Name = studentData.ContainsKey("name") ? studentData["name"].ToString() : "Unknown",
                Surname = studentData.ContainsKey("surname") ? studentData["surname"].ToString() : "",
                Email = studentData.ContainsKey("email") ? studentData["email"].ToString() : "No email",
                CreatedAt = studentData.ContainsKey("createdAt") && studentData["createdAt"] is Timestamp tsCreated ?
                    tsCreated.ToDateTime() : DateTime.MinValue,
                Status = studentData.ContainsKey("isDeleted") && studentData["isDeleted"] is bool deleted && deleted ?
                    "Deleted" : "Active"
            };

            return View(student);
        }

        // POST: Delete Student
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(string id)
        {
            try
            {
                var studentDoc = _firestoreDb.Collection("students").Document(id);

                // Soft delete - mark as deleted instead of removing from database
                var updateData = new Dictionary<string, object>
                {
                    ["isDeleted"] = true,
                    ["lastActivity"] = Timestamp.FromDateTime(DateTime.UtcNow)
                };

                await studentDoc.UpdateAsync(updateData);

                TempData["SuccessMessage"] = "Student deleted successfully!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error deleting student: {ex.Message}";
                return RedirectToAction(nameof(Delete), new { id });
            }
        }

        // POST: Restore Student
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Restore(string id)
        {
            try
            {
                var studentDoc = _firestoreDb.Collection("students").Document(id);
                var updateData = new Dictionary<string, object>
                {
                    ["isDeleted"] = false,
                    ["lastActivity"] = Timestamp.FromDateTime(DateTime.UtcNow)
                };

                await studentDoc.UpdateAsync(updateData);

                TempData["SuccessMessage"] = "Student restored successfully!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error restoring student: {ex.Message}";
                return RedirectToAction(nameof(Index));
            }
        }

        // GET: Student Progress (Redirect to StudentProgress Controller)
        public IActionResult Progress(string id)
        {
            return RedirectToAction("Details", "StudentProgress", new { id });
        }
    }
}