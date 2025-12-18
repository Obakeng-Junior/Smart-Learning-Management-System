namespace AI_Powered_Learning_Application.Models.ViewModels
{
    public class StudentDetailViewModel
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Surname { get; set; }
        public string Email { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastActivity { get; set; }
        public List<string> EnrolledCourses { get; set; } = new List<string>();
        public List<string> SubjectsOfInterest { get; set; } = new List<string>();
        public int TotalScore { get; set; }
        public string SkillLevel { get; set; }
        public string Status { get; set; }
        public List<CourseProgressViewModel> CourseProgress { get; set; } = new List<CourseProgressViewModel>();

        // Helper properties
        public string FullName => $"{Name} {Surname}";
        public string LastActivityFormatted => LastActivity == DateTime.MinValue ? "Never" : LastActivity.ToString("yyyy-MM-dd HH:mm");

        // Overall student statistics
        public int TotalCourses => CourseProgress.Count;
        public int TotalCompletedCourses => CourseProgress.Count(c => c.CompletionPercentage >= 80);
        public double OverallQuizScore => CourseProgress.Any() ? CourseProgress.Average(c => c.AverageQuizScore) : 0;
        public double OverallPointsPercentage => CourseProgress.Any() ? CourseProgress.Average(c => c.OverallPointsPercentage) : 0;
    }
}

