using AI_Powered_Learning_Application.Models;
using AI_Powered_Learning_Application.Models.ViewModels;
using AI_Powered_Learning_Application.Services;
using Google.Cloud.Firestore;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

namespace AI_Powered_Learning_Application.Controllers
{
    public class CourseContentController : Controller
    {
        private readonly FirestoreDb _firestore;
        private readonly CloudinaryService _cloudinary;
        private readonly IFirebaseStorageService _firebaseStorage;
        private readonly ILogger<CourseContentController> _logger;

        public CourseContentController(
            FirebaseService firebaseService,
            CloudinaryService cloudinary,
            IFirebaseStorageService firebaseStorage,
            ILogger<CourseContentController> logger)
        {
            _firestore = firebaseService.GetDb();
            _cloudinary = cloudinary;
            _firebaseStorage = firebaseStorage;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> Index(string courseId)
        {
            var snapshot = await _firestore
                .Collection("courses")
                .Document(courseId)
                .Collection("contents")
                .GetSnapshotAsync();

            var courseContents = snapshot.Documents
                .Select(d => d.ConvertTo<CourseContent>())
                .ToList();

            return View(courseContents);
        }

        [HttpGet]
        public async Task<IActionResult> Details(string courseId, string contentId)
        {
            try
            {
                var contentRef = _firestore
                    .Collection("courses")
                    .Document(courseId)
                    .Collection("contents")
                    .Document(contentId);

                var contentSnap = await contentRef.GetSnapshotAsync();
                if (!contentSnap.Exists) return NotFound();

                var content = contentSnap.ConvertTo<CourseContent>();

                // Get quizzes
                var quizSnapshot = await contentRef.Collection("quizzes").GetSnapshotAsync();
                var quizzes = quizSnapshot.Documents
                    .Select(d => d.ConvertTo<Quiz>())
                    .ToList();

                var viewModel = new CourseContentDetailsViewModel
                {
                    Content = content,
                    Quizzes = quizzes
                };

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error loading details for content {contentId} in course {courseId}");
                TempData["ErrorMessage"] = "Error loading content details.";
                return RedirectToAction("Details", "ManageCourse", new { id = courseId });
            }
        }

        [HttpGet]
        public IActionResult Create(string courseId)
        {
            var model = new CourseContentFormViewModel
            {
                CourseId = courseId
            };
            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> Create(CourseContentFormViewModel model)
        {
            try
            {
                List<string> contentUrls = new List<string>();

                
                if (model.ContentType != "Link" && model.ContentFiles != null && model.ContentFiles.Count > 0)
                {
                    foreach (var file in model.ContentFiles)
                    {
                        if (file.Length > 0)
                        {
                            
                            string url;
                            if (file.ContentType == "application/pdf" || Path.GetExtension(file.FileName).ToLower() == ".pdf")
                            {
                                url = await _firebaseStorage.UploadPdfAsync(file, file.FileName);
                                _logger.LogInformation($"PDF uploaded to Firebase: {url}");
                            }
                            else
                            {
                                url = await _cloudinary.UploadFileAsync(file);
                                _logger.LogInformation($"File uploaded to Cloudinary: {url}");
                            }
                            contentUrls.Add(url);
                        }
                    }
                }
               
                else if (model.ContentType == "Link" && !string.IsNullOrEmpty(model.ContentUrl))
                {
                    contentUrls.Add(model.ContentUrl);
                }
                else
                {
                    ModelState.AddModelError("", "Please provide either files or a URL");
                    return View(model);
                }

                // Create Firestore document
                var docRef = _firestore
                    .Collection("courses")
                    .Document(model.CourseId)
                    .Collection("contents")
                    .Document();

                var content = new CourseContent
                {
                    Id = docRef.Id,
                    CourseId = model.CourseId,
                    Title = model.Title,
                    Description = model.Description,
                    ContentType = model.ContentType,
                    ContentUrls = contentUrls,
                    UploadedAt = DateTime.UtcNow
                };

                await docRef.SetAsync(content);

                TempData["SuccessMessage"] = "Content created successfully!";
                return RedirectToAction("Details", "ManageCourse", new { id = model.CourseId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating course content");
                ModelState.AddModelError("", "An error occurred while saving. Please try again.");
                return View(model);
            }
        }

        [HttpGet]
        public async Task<IActionResult> Edit(string courseId, string contentId)
        {
            try
            {
                var docRef = _firestore
                    .Collection("courses")
                    .Document(courseId)
                    .Collection("contents")
                    .Document(contentId);

                var snapshot = await docRef.GetSnapshotAsync();
                if (!snapshot.Exists)
                {
                    _logger.LogWarning($"Content not found: {contentId} in course {courseId}");
                    return NotFound();
                }

                var content = snapshot.ConvertTo<CourseContent>();

                var model = new CourseContentFormViewModel
                {
                    Id = content.Id,
                    CourseId = content.CourseId,
                    Title = content.Title,
                    Description = content.Description,
                    ContentType = content.ContentType,
                    ContentUrl = content.ContentUrls?.FirstOrDefault(),
                    ExistingFileUrls = content.ContentUrls ?? new List<string>()
                };

                return View(model);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error loading content for editing: {contentId}");
                TempData["ErrorMessage"] = "Error loading content for editing.";
                return RedirectToAction("Details", "ManageCourse", new { id = courseId });
            }
        }

       
        [HttpPost]
        public async Task<IActionResult> Edit(CourseContentFormViewModel model)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    _logger.LogWarning("Edit model validation failed");
                    return View(model);
                }

                var docRef = _firestore
                    .Collection("courses")
                    .Document(model.CourseId)
                    .Collection("contents")
                    .Document(model.Id);

                var snapshot = await docRef.GetSnapshotAsync();
                if (!snapshot.Exists)
                {
                    _logger.LogWarning($"Content not found during edit: {model.Id}");
                    return NotFound();
                }

                var existingContent = snapshot.ConvertTo<CourseContent>();
                var contentUrls = new List<string>();

                // Handle content updates based on type
                if (model.ContentType != "Link")
                {
                    // For file uploads
                    if (model.ContentFiles != null && model.ContentFiles.Any(f => f.Length > 0))
                    {
                        // Delete old files only after new ones are successfully uploaded
                        var newUrls = new List<string>();
                        foreach (var file in model.ContentFiles.Where(f => f.Length > 0))
                        {
                            try
                            {
                                string url;
                                // Use Firebase for PDFs, Cloudinary for other files
                                if (file.ContentType == "application/pdf" || Path.GetExtension(file.FileName).ToLower() == ".pdf")
                                {
                                    url = await _firebaseStorage.UploadPdfAsync(file, file.FileName);
                                    _logger.LogInformation($"PDF uploaded to Firebase: {url}");
                                }
                                else
                                {
                                    url = await _cloudinary.UploadFileAsync(file);
                                    _logger.LogInformation($"File uploaded to Cloudinary: {url}");
                                }
                                newUrls.Add(url);
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, $"Error uploading file: {file.FileName}");
                                ModelState.AddModelError("", $"Error uploading {file.FileName}");
                                return View(model);
                            }
                        }

                        // Only delete old files if new ones uploaded successfully
                        if (existingContent.ContentUrls != null)
                        {
                            foreach (var oldUrl in existingContent.ContentUrls)
                            {
                                try
                                {
                                    await DeleteFileFromStorage(oldUrl);
                                }
                                catch (Exception ex)
                                {
                                    _logger.LogError(ex, $"Error deleting old file: {oldUrl}");
                                    // Continue with other deletions even if one fails
                                }
                            }
                        }

                        contentUrls = newUrls;
                    }
                    else
                    {
                        // Keep existing files if no new ones uploaded AND content type hasn't changed
                        if (existingContent.ContentType == model.ContentType)
                        {
                            contentUrls = existingContent.ContentUrls?.ToList() ?? new List<string>();
                        }
                        else
                        {
                            // Content type changed but no new files - this should be handled by validation
                            ModelState.AddModelError("", "When changing content type, you must upload new files.");
                            return View(model);
                        }
                    }
                }
                else
                {
                    // For link content
                    if (string.IsNullOrEmpty(model.ContentUrl))
                    {
                        ModelState.AddModelError(nameof(model.ContentUrl), "URL is required for link content");
                        return View(model);
                    }
                    contentUrls = new List<string> { model.ContentUrl };

                    // Delete old files if switching from files to link
                    if (existingContent.ContentType != "Link" && existingContent.ContentUrls != null)
                    {
                        foreach (var oldUrl in existingContent.ContentUrls)
                        {
                            try
                            {
                                await DeleteFileFromStorage(oldUrl);
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, $"Error deleting old file: {oldUrl}");
                            }
                        }
                    }
                }

                var updatedContent = new CourseContent
                {
                    Id = model.Id,
                    CourseId = model.CourseId,
                    Title = model.Title,
                    Description = model.Description,
                    ContentType = model.ContentType,
                    ContentUrls = contentUrls,
                    UploadedAt = existingContent.UploadedAt
                };

                await docRef.SetAsync(updatedContent);
                _logger.LogInformation($"Successfully updated content {model.Id}");

                TempData["SuccessMessage"] = "Content updated successfully!";
                return RedirectToAction("Details", "ManageCourse", new { id = model.CourseId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error editing content");
                TempData["ErrorMessage"] = "An error occurred while updating the content.";
                return View(model);
            }
        }

        [HttpPost, ActionName("Delete")]
        public async Task<IActionResult> DeleteConfirmed(string courseId, string contentId)
        {
            try
            {
                var docRef = _firestore
                    .Collection("courses")
                    .Document(courseId)
                    .Collection("contents")
                    .Document(contentId);

                var snapshot = await docRef.GetSnapshotAsync();
                if (!snapshot.Exists) return NotFound();

                var content = snapshot.ConvertTo<CourseContent>();

                // Delete all associated files from storage
                if (content.ContentUrls != null)
                {
                    foreach (var url in content.ContentUrls)
                    {
                        if (!string.IsNullOrEmpty(url))
                        {
                            try
                            {
                                await DeleteFileFromStorage(url);
                                _logger.LogInformation($"Deleted file from storage: {url}");
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, $"Error deleting file from storage: {url}");
                                // Continue with other files even if one fails
                            }
                        }
                    }
                }

                await docRef.DeleteAsync();
                _logger.LogInformation($"Deleted content {contentId} from course {courseId}");

                TempData["SuccessMessage"] = "Content deleted successfully!";
                return RedirectToAction("Details", "ManageCourse", new { id = courseId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error while deleting course content");
                TempData["ErrorMessage"] = "Error deleting content. Some files may not have been removed.";
                return RedirectToAction("Details", "ManageCourse", new { id = courseId });
            }
        }

        // Helper method to delete files from appropriate storage service
        private async Task DeleteFileFromStorage(string fileUrl)
        {
            if (_firebaseStorage.IsPdfUrl(fileUrl))
            {
                await _firebaseStorage.DeletePdfAsync(fileUrl);
            }
            else
            {
                await _cloudinary.DeleteFileAsync(fileUrl);
            }
        }

        // Optional: API endpoint for direct PDF upload (if needed for AJAX uploads)
        [HttpPost]
        public async Task<IActionResult> UploadPdf(string courseId, IFormFile pdfFile)
        {
            try
            {
                if (pdfFile == null || pdfFile.Length == 0)
                {
                    return BadRequest(new { error = "No file provided" });
                }

                if (Path.GetExtension(pdfFile.FileName).ToLower() != ".pdf")
                {
                    return BadRequest(new { error = "Only PDF files are allowed" });
                }

                var pdfUrl = await _firebaseStorage.UploadPdfAsync(pdfFile, pdfFile.FileName);

                return Ok(new
                {
                    success = true,
                    url = pdfUrl,
                    message = "PDF uploaded successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading PDF");
                return StatusCode(500, new { error = "Error uploading PDF file" });
            }
        }
    }
}