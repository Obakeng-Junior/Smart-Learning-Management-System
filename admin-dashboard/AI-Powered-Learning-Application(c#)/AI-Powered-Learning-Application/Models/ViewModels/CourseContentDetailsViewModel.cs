namespace AI_Powered_Learning_Application.Models.ViewModels
{
    public class CourseContentDetailsViewModel
    {
        public CourseContent Content { get; set; }
        public List<Quiz> Quizzes { get; set; } = new List<Quiz>();
    }
}
