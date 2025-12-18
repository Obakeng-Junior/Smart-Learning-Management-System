namespace AI_Powered_Learning_Application.Models.ViewModels
{
    public class QuizResponseViewModel
    {
        public string ResponseId { get; set; }
        public string ContentId { get; set; }
        public string CourseId { get; set; }
        public int Attempt { get; set; }
        public bool IsCorrect { get; set; }

        // Both score types - Option 1 implementation
        public double QuizScore { get; set; } // Percentage (0-100)
        public int PointsScore { get; set; }  // Points earned

        public string SelectedAnswer { get; set; }
        public string CorrectAnswer { get; set; }
        public string Question { get; set; }
        public DateTime Timestamp { get; set; }

        // Helper properties
        public string TimestampFormatted => Timestamp.ToString("yyyy-MM-dd HH:mm");
        public string Result => IsCorrect ? "Correct" : "Incorrect";
        public string QuizScoreDisplay => $"{QuizScore}%";
        public string PointsScoreDisplay => $"{PointsScore} point{(PointsScore != 1 ? "s" : "")}";
        public bool IsBestAttempt { get; set; } // Will be set during processing
    }
}
