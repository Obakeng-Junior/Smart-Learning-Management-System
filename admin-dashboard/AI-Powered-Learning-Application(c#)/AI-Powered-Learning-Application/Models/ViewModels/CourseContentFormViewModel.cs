using System.ComponentModel.DataAnnotations;

namespace AI_Powered_Learning_Application.Models.ViewModels
{
    public class CourseContentFormViewModel 
    {
        public string Id { get; set; }
        public string CourseId { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string ContentType { get; set; }
        public string ContentUrl { get; set; }
        [Display(Name = "Upload Files")]
        public List<IFormFile> ContentFiles { get; set; } = new List<IFormFile>();

       
        public List<string> ExistingFileUrls { get; set; } = new List<string>();
    }
    
}