namespace AI_Powered_Learning_Application.Models.ViewModels
{
    public class LessonProgressViewModel
    {
        public string LessonId { get; set; }
        public string LessonName { get; set; }
        public bool Viewed { get; set; }
        public DateTime LastViewed { get; set; }
        public bool Completed { get; set; }
        public int Attempts { get; set; }

        // Both score types - Option 1 implementation
        public double QuizScore { get; set; }     // Best percentage score (0-100)
        public int PointsScore { get; set; }      // Best points earned
        public int MaxPossiblePoints { get; set; } = 1; // Usually 1 point per quiz

        public string SelectedAnswer { get; set; }
        public DateTime CompletedAt { get; set; }
        public List<QuizResponseViewModel> QuizResponses { get; set; } = new List<QuizResponseViewModel>();
        public bool HasQuizzes => QuizResponses.Any();

        // Helper properties
        public string LastViewedFormatted => LastViewed == DateTime.MinValue ? "Never" : LastViewed.ToString("yyyy-MM-dd HH:mm");
        public string CompletedAtFormatted => CompletedAt == DateTime.MinValue ? "Not completed" : CompletedAt.ToString("yyyy-MM-dd HH:mm");
        public string Status => Completed ? "Completed" : (Viewed ? "Viewed" : "Not Started");
        public string QuizScoreDisplay => HasQuizzes ? $"{QuizScore}%" : "No quiz";
        public string PointsDisplay => HasQuizzes ? $"{PointsScore}/{MaxPossiblePoints}" : "No quiz";
        public double PointsPercentage => MaxPossiblePoints > 0 ? (PointsScore * 100.0) / MaxPossiblePoints : 0;
    }
}
