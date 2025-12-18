namespace AI_Powered_Learning_Application.Models.ViewModels
{
    public class StudentViewModel
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Surname { get; set; }
        public string Email { get; set; }
        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastActivity { get; set; }
        public int EnrolledCoursesCount { get; set; }

        // New properties for detailed view
        public List<string> SubjectsOfInterest { get; set; } = new List<string>();
        public string SkillLevel { get; set; }
        public int TotalScore { get; set; }

        // Helper properties for display
        public string FullName => $"{Name} {Surname}";
        public string LastActivityFormatted => LastActivity == DateTime.MinValue ? "Never" : LastActivity.ToString("MMM dd, yyyy HH:mm");
        public string CreatedAtFormatted => CreatedAt.ToString("MMM dd, yyyy");
    }
}