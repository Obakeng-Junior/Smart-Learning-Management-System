using Google.Cloud.Firestore;

namespace AI_Powered_Learning_Application.Models
{
    [FirestoreData]
    public class CourseContent
    {
        [FirestoreDocumentId]
        public string Id { get; set; }          
        [FirestoreProperty]
        public string CourseId { get; set; }     
        [FirestoreProperty]
        public string Title { get; set; }        
        [FirestoreProperty]
        public string Description { get; set; }  
        [FirestoreProperty]
        public string ContentType { get; set; } 
        [FirestoreProperty]
        public List<string> ContentUrls { get; set; } = new List<string>();

        [FirestoreProperty]
        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    }
}
