namespace AI_Powered_Learning_Application.Models.ViewModels
{
    public class CourseDetailsViewModel
    {
        public ManageCourses Course { get; set; }

        public List<CourseContent> Contents { get; set; } = new List<CourseContent>();
    }
}
