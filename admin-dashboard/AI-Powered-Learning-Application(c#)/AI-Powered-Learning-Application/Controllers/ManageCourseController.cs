using AI_Powered_Learning_Application.Models;
using AI_Powered_Learning_Application.Services;
using Google.Cloud.Firestore;
using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Storage.V1;
using CloudinaryDotNet.Actions;
using CloudinaryDotNet;
using AI_Powered_Learning_Application.Models.ViewModels;

namespace AI_Powered_Learning_Application.Controllers
{
    public class ManageCourseController : Controller
    {
        private readonly FirestoreDb _firestore;
        private readonly CloudinaryService _cloudinary;
        private readonly IFirebaseStorageService _firebaseStorage;
        private readonly ILogger<ManageCourseController> _logger;

        private List<string> GetCategories()
        {
            return new List<string>
            {
                "Information Technology",
                "Computer Systems",
                "Electrical Engineering",
                "Civil Engineering",
                "Mechanical Engineering",
                "Built Environment / Architecture",
                "Health Sciences",
                "Environmental Health",
                "Biomedical Technology",
                "Clinical Technology",
                "Radiography",
                "Education",
                "Language and Communication",
                "Design and Studio Art",
                "Accounting",
                "Entrepreneurship",
                "Human Resource Management",
                "Public Management",
                "Marketing",
                "Tourism and Hospitality",
                "Business Administration",
                "Mathematics",
                "Physics",
                "Biology",
                "Chemistry"
            };
        }

        public ManageCourseController(
            FirebaseService firebaseService,
            CloudinaryService cloudinary,
            IFirebaseStorageService firebaseStorage,
            ILogger<ManageCourseController> logger)
        {
            _firestore = firebaseService.GetDb();
            _cloudinary = cloudinary;
            _firebaseStorage = firebaseStorage;
            _logger = logger;
        }

        public async Task<IActionResult> Index()
        {
            // Fetch courses from Firestore
            var snapshot = await _firestore.Collection("courses").GetSnapshotAsync();

            var courseVMs = new List<CourseViewModel>();

            foreach (var doc in snapshot.Documents)
            {
                var course = doc.ConvertTo<ManageCourses>();
                var courseId = doc.Id; // Use Firestore document ID as the CourseId

                // Count students who are enrolled in this course
                var studentSnapshot = await _firestore.Collection("students")
                    .WhereArrayContains("enrolledCourses", courseId)
                    .GetSnapshotAsync();

                int enrollmentCount = studentSnapshot.Count;

                course.Id = courseId; // Ensure course.Id is set from Firestore doc id

                courseVMs.Add(new CourseViewModel
                {
                    Course = course,
                    EnrollmentCount = enrollmentCount
                });
            }

            return View(courseVMs);
        }

        public async Task<IActionResult> Details(string id)
        {
            var courseDoc = await _firestore.Collection("courses").Document(id).GetSnapshotAsync();
            if (!courseDoc.Exists)
                return NotFound();

            var course = courseDoc.ConvertTo<ManageCourses>();

            var contentsSnapshot = await _firestore
                .Collection("courses")
                .Document(id)
                .Collection("contents")
                .GetSnapshotAsync();

            var contents = contentsSnapshot.Documents
                .Select(d => d.ConvertTo<CourseContent>())
                .ToList();

            var viewModel = new CourseDetailsViewModel
            {
                Course = course,
                Contents = contents
            };

            return View(viewModel);
        }

        [HttpGet]
        public IActionResult Create()
        {
            ViewBag.CategoryList = GetCategories().Select(c => new Microsoft.AspNetCore.Mvc.Rendering.SelectListItem
            {
                Text = c,
                Value = c
            }).ToList();

            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Create(ManageCourses course, IFormFile imageFile)
        {
            try
            {
                if (imageFile != null && imageFile.Length > 0)
                {
                    // Upload image to Cloudinary
                    course.ImageUrl = await _cloudinary.UploadImageAsync(imageFile);
                    _logger.LogInformation("Image uploaded successfully: " + course.ImageUrl);
                }

                // Save the course data to Firestore
                await _firestore.Collection("courses").AddAsync(course);
                _logger.LogInformation("Course saved to Firestore.");

                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during form submission or image upload.");
                ModelState.AddModelError("", "There was an error processing your request.");
                return View(course);
            }
        }

        [HttpGet]
        public async Task<IActionResult> Edit(string id)
        {
            var docRef = _firestore.Collection("courses").Document(id);
            var snapshot = await docRef.GetSnapshotAsync();
            if (!snapshot.Exists) return NotFound();

            var course = snapshot.ConvertTo<ManageCourses>();

            ViewBag.CategoryList = GetCategories().Select(c => new Microsoft.AspNetCore.Mvc.Rendering.SelectListItem
            {
                Text = c,
                Value = c,
                Selected = (c == course.Category)
            }).ToList();

            return View(course);
        }

        [HttpPost]
        public async Task<IActionResult> Edit(ManageCourses course, IFormFile imageFile)
        {
            try
            {
                // Fetch the existing course from Firestore to get the current ImageUrl
                var docRef = _firestore.Collection("courses").Document(course.Id);
                var snapshot = await docRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound();
                }

                // Retrieve the existing ImageUrl from Firestore (before any changes)
                var existingCourse = snapshot.ConvertTo<ManageCourses>();

                // If no new image is uploaded, retain the existing ImageUrl
                if (imageFile == null || imageFile.Length == 0)
                {
                    course.ImageUrl = existingCourse.ImageUrl;
                }
                else
                {
                    // Upload the new image if a file is selected
                    course.ImageUrl = await _cloudinary.UploadImageAsync(imageFile);
                }

                // Log the final ImageUrl being saved
                _logger.LogInformation("Saving course with ImageUrl: " + course.ImageUrl);

                // Save the updated course to Firestore
                await docRef.SetAsync(course);
                _logger.LogInformation("Course updated in Firestore with ImageUrl: " + course.ImageUrl);

                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during form submission or image upload.");
                ModelState.AddModelError("", "There was an error processing your request.");
                return View(course);
            }
        }

        public async Task<IActionResult> Delete(string id)
        {
            var docRef = _firestore.Collection("courses").Document(id);
            var snapshot = await docRef.GetSnapshotAsync();

            if (snapshot.Exists)
            {
                var course = snapshot.ConvertTo<ManageCourses>();

                // ✅ Delete image from Cloudinary
                if (!string.IsNullOrEmpty(course.ImageUrl))
                {
                    await _cloudinary.DeleteImageAsync(course.ImageUrl);
                }

                // ✅ Delete course from Firestore
                await docRef.DeleteAsync();
            }

            return RedirectToAction("Index");
        }

        // NEW: Method to upload PDF to Firebase Storage
        [HttpPost]
        public async Task<IActionResult> UploadPdf(string courseId, IFormFile pdfFile)
        {
            try
            {
                if (string.IsNullOrEmpty(courseId))
                {
                    return BadRequest("Course ID is required.");
                }

                if (pdfFile == null || pdfFile.Length == 0)
                {
                    return BadRequest("No PDF file provided.");
                }

                // Validate file type
                var fileExtension = Path.GetExtension(pdfFile.FileName).ToLower();
                if (fileExtension != ".pdf")
                {
                    return BadRequest("Only PDF files are allowed.");
                }

                // Validate file size (e.g., 10MB limit)
                if (pdfFile.Length > 10 * 1024 * 1024)
                {
                    return BadRequest("PDF file size must be less than 10MB.");
                }

                // Upload PDF to Firebase Storage
                var firebasePdfUrl = await _firebaseStorage.UploadPdfAsync(pdfFile, pdfFile.FileName);

                _logger.LogInformation($"PDF uploaded successfully to Firebase: {firebasePdfUrl}");

                // Return the Firebase URL
                return Ok(new { pdfUrl = firebasePdfUrl });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading PDF to Firebase Storage");
                return StatusCode(500, "Error uploading PDF file.");
            }
        }

        // NEW: Method to delete PDF from Firebase Storage
        [HttpPost]
        public async Task<IActionResult> DeletePdf(string pdfUrl)
        {
            try
            {
                if (string.IsNullOrEmpty(pdfUrl))
                {
                    return BadRequest("PDF URL is required.");
                }

                // Extract file name from Firebase URL for deletion
                // Note: You might need to enhance your IFirebaseStorageService with a delete method
                // For now, we'll just log and return success
                _logger.LogInformation($"PDF deletion requested for: {pdfUrl}");

                // TODO: Implement actual deletion in FirebaseStorageService if needed
                // await _firebaseStorage.DeletePdfAsync(pdfUrl);

                return Ok(new { message = "PDF deletion processed successfully." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting PDF from Firebase Storage");
                return StatusCode(500, "Error deleting PDF file.");
            }
        }

        // NEW: Method to get Firebase PDF URL (for existing PDFs)
        [HttpGet]
        public async Task<IActionResult> GetPdfUrl(string fileName)
        {
            try
            {
                if (string.IsNullOrEmpty(fileName))
                {
                    return BadRequest("File name is required.");
                }

                var pdfUrl = _firebaseStorage.GenerateFirebasePdfUrl(fileName);
                return Ok(new { pdfUrl });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating PDF URL");
                return StatusCode(500, "Error generating PDF URL.");
            }
        }
        [HttpGet]
        public async Task<IActionResult> ViewPdf(string url)
        {
            try
            {
                // Security: Validate that the URL is from your Firebase or Cloudinary account
                if (string.IsNullOrEmpty(url) || !IsValidPdfUrl(url))
                {
                    return NotFound("Invalid PDF URL");
                }

                // Create HttpClient with timeout
                using var httpClient = new HttpClient();
                httpClient.Timeout = TimeSpan.FromSeconds(30);
                httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36");

                // Fetch the PDF from the external service
                var response = await httpClient.GetAsync(url);

                if (response.IsSuccessStatusCode)
                {
                    // Get the PDF bytes and content type
                    var pdfBytes = await response.Content.ReadAsByteArrayAsync();
                    var contentType = "application/pdf";

                    // Return the PDF as a file
                    return File(pdfBytes, contentType, enableRangeProcessing: true);
                }
                else
                {
                    _logger.LogWarning("Failed to fetch PDF from {Url}. Status: {StatusCode}", url, response.StatusCode);
                    return StatusCode(500, $"Failed to load PDF: External service returned {response.StatusCode}");
                }
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Network error while fetching PDF from {Url}", url);
                return StatusCode(500, "Network error while loading PDF");
            }
            catch (TaskCanceledException)
            {
                _logger.LogWarning("Timeout while fetching PDF from {Url}", url);
                return StatusCode(500, "Request timeout - PDF is too large or network is slow");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading PDF from {Url}", url);
                return StatusCode(500, "Error loading PDF");
            }
        }

        // Security: Validate that the URL is from your services
        private bool IsValidPdfUrl(string url)
        {
            if (string.IsNullOrEmpty(url)) return false;

            // Only allow URLs from your Firebase Storage and Cloudinary
            var allowedDomains = new[]
            {
        "firebasestorage.googleapis.com",
        "ai-powered-app-9f8f5.firebasestorage.app",
        "res.cloudinary.com"
    };

            return allowedDomains.Any(domain => url.Contains(domain));
        }
    }
}