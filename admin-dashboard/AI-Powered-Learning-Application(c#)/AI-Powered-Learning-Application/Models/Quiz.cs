using Google.Cloud.Firestore;

namespace AI_Powered_Learning_Application.Models
{
    [FirestoreData]
    public class Quiz
    {
        [FirestoreDocumentId]
        public string Id { get; set; }
        [FirestoreProperty]
        public string CourseId { get; set; }   // Link quiz to a course'
        [FirestoreProperty]
        public string ContentId { get; set; }
        [FirestoreProperty]
        public string Question { get; set; }    // Quiz question
        [FirestoreProperty]
        public string OptionA { get; set; }     // Option A
        [FirestoreProperty]
        public string OptionB { get; set; }     // Option B
        [FirestoreProperty]
        public string OptionC { get; set; }     // Option C
        [FirestoreProperty]
        public string OptionD { get; set; }     // Option D
        [FirestoreProperty]
        public string CorrectAnswer { get; set; }  // "A", "B", "C", or "D"
        [FirestoreProperty]
        public string Difficulty { get; set; }  // Beginner, Intermediate, Advanced
        [FirestoreProperty]
        public DateTime CreatedAt { get; set; }
    }
}
