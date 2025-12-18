using Google.Cloud.Firestore;
using Microsoft.AspNetCore.Http.HttpResults;

namespace AI_Powered_Learning_Application.Models
{
    [FirestoreData]
    public class Student
    {
        [FirestoreDocumentId]
        public string Id { get; set; }

        [FirestoreProperty("name")]
        public string name { get; set; }

        [FirestoreProperty("surname")]
        public string surname { get; set; }

        [FirestoreProperty("email")]
        public string email { get; set; }

        [FirestoreProperty("createdAt")]
        public Timestamp createdAt { get; set; }

        [FirestoreProperty("isDeleted")]
        public bool isDeleted { get; set; }
        [FirestoreProperty]
        public Timestamp LastActivity { get; set; }

        [FirestoreProperty]
        public List<string> EnrolledCourses { get; set; } = new List<string>();

        [FirestoreProperty]
        public List<string> SubjectsOfInterest { get; set; } = new List<string>();

        [FirestoreProperty]
        public int TotalScore { get; set; }

        [FirestoreProperty]
        public string SkillLevel { get; set; } // Beginner, Intermediate, Advanced

        [FirestoreProperty]
        public Dictionary<string, Dictionary<string, LessonProgress>> Progress { get; set; }
            = new Dictionary<string, Dictionary<string, LessonProgress>>();

        public DateTime CreatedAtDateTime => createdAt.ToDateTime();
        public DateTime LastActivityDateTime => LastActivity.ToDateTime();

        public string Status => isDeleted ? "Deleted" : "Active";
        public int EnrolledCoursesCount => EnrolledCourses?.Count ?? 0;
        
    }
}
