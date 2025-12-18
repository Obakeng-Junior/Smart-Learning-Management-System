using System.ComponentModel.DataAnnotations;

namespace AI_Powered_Learning_Application.Models.ViewModels
{
    public class StudentCreateViewModel
    {
        [Required(ErrorMessage = "Name is required")]
        [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters")]
        [Display(Name = "First Name")]
        public string Name { get; set; }

        [Required(ErrorMessage = "Surname is required")]
        [StringLength(100, ErrorMessage = "Surname cannot exceed 100 characters")]
        [Display(Name = "Last Name")]
        public string Surname { get; set; }

        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Invalid email address format")]
        [StringLength(255, ErrorMessage = "Email cannot exceed 255 characters")]
        [Display(Name = "Email Address")]
        public string Email { get; set; }

        [Display(Name = "Skill Level")]
        public string SkillLevel { get; set; } = "Beginner";

        [Display(Name = "Subjects of Interest")]
        public List<string> SubjectsOfInterest { get; set; } = new List<string>();

        // Helper property for form display
        public string NewSubject { get; set; }
    }
}