using Google.Cloud.Firestore;
using Google.Cloud.Firestore;

namespace AI_Powered_Learning_Application.Models
{
    [FirestoreData]
    public class ManageCourses
    {
        [FirestoreDocumentId]
        public string Id { get; set; }

        [FirestoreProperty]
        public string Title { get; set; }

        [FirestoreProperty]
        public string Description { get; set; }

        [FirestoreProperty]
        public string Category { get; set; }

        [FirestoreProperty]
        public string Difficulty { get; set; } 
        [FirestoreProperty]
        public string ImageUrl { get; set; }

       
    }
}
