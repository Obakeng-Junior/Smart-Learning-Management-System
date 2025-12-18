namespace AI_Powered_Learning_Application.Models.ViewModels
{
    public class CourseProgressViewModel
    {
        public string CourseId { get; set; }
        public string CourseName { get; set; }
        public List<LessonProgressViewModel> Lessons { get; set; } = new List<LessonProgressViewModel>();

        // Completion metrics
        public int CompletedLessons => Lessons.Count(l => l.Completed);
        public int TotalLessons => Lessons.Count;
        public double CompletionPercentage => TotalLessons > 0 ? (CompletedLessons * 100.0) / TotalLessons : 0;

        // Score metrics - Option 3 implementation
        public double AverageQuizScore => Lessons.Where(l => l.Completed).Select(l => l.QuizScore).DefaultIfEmpty(0).Average();
        public double AveragePointsPercentage => Lessons.Where(l => l.Completed).Select(l => l.PointsPercentage).DefaultIfEmpty(0).Average();

        // Total points earned in the course
        public int TotalPointsEarned => Lessons.Sum(l => l.PointsScore);
        public int TotalPossiblePoints => Lessons.Count; // Assuming 1 point per lesson
        public double OverallPointsPercentage => TotalPossiblePoints > 0 ? (TotalPointsEarned * 100.0) / TotalPossiblePoints : 0;

        // Helper properties for display
        public string CompletionDisplay => $"{CompletedLessons}/{TotalLessons} ({CompletionPercentage:F1}%)";
        public string QuizScoreDisplay => $"{AverageQuizScore:F1}%";
        public string PointsDisplay => $"{TotalPointsEarned}/{TotalPossiblePoints} ({OverallPointsPercentage:F1}%)";
        public string Status => CompletionPercentage >= 80 ? "Completed" : "In Progress";
    }
}

