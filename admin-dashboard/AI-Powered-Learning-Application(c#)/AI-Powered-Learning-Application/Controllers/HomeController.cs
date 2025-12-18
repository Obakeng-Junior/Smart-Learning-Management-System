using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using AI_Powered_Learning_Application.Models;
using AI_Powered_Learning_Application.Services;
using Google.Cloud.Firestore;

namespace AI_Powered_Learning_Application.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly FirestoreDb _firestoreDb;

    public HomeController(ILogger<HomeController> logger, FirebaseService firebaseService)
    {
        _logger = logger;
        _firestoreDb = firebaseService.GetDb();
    }

    public async Task<IActionResult> Index()
    {
        var dashboardData = new DashboardViewModel
        {
            StudentCount = await GetStudentCountAsync(),
            CourseCount = await GetCourseCountAsync()
        };

        return View(dashboardData);
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }

    private async Task<int> GetStudentCountAsync()
    {
        try
        {
            var studentsCollection = _firestoreDb.Collection("students");
            var snapshot = await studentsCollection.GetSnapshotAsync();

            // Count only active students (not deleted)
            var activeStudentsCount = snapshot.Documents
                .Count(doc =>
                {
                    var data = doc.ToDictionary();
                    return !data.ContainsKey("isDeleted") ||
                           (data.ContainsKey("isDeleted") && !(bool)data["isDeleted"]);
                });

            return activeStudentsCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting student count");
            return 0;
        }
    }

    private async Task<int> GetCourseCountAsync()
    {
        try
        {
            var coursesCollection = _firestoreDb.Collection("courses");
            var snapshot = await coursesCollection.GetSnapshotAsync();

            // Count all courses (you can add filtering logic if needed)
            return snapshot.Documents.Count;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting course count");
            return 0;
        }
    }
}

public class DashboardViewModel
{
    public int StudentCount { get; set; }
    public int CourseCount { get; set; }
}