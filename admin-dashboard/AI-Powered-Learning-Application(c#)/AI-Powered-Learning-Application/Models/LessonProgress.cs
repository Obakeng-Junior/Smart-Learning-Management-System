using Google.Cloud.Firestore;

namespace AI_Powered_Learning_Application.Models
{
    public class LessonProgress
    {
        [FirestoreProperty]
        public bool Viewed { get; set; }

        [FirestoreProperty]
        public Timestamp LastViewed { get; set; }

        [FirestoreProperty]
        public bool Completed { get; set; }

        [FirestoreProperty]
        public int Attempts { get; set; }

        [FirestoreProperty]
        public double QuizScore { get; set; }

        [FirestoreProperty]
        public string SelectedAnswer { get; set; }

        [FirestoreProperty]
        public Timestamp CompletedAt { get; set; }

        public DateTime LastViewedDateTime => LastViewed.ToDateTime();
        public DateTime CompletedAtDateTime => CompletedAt.ToDateTime();
    }
}
