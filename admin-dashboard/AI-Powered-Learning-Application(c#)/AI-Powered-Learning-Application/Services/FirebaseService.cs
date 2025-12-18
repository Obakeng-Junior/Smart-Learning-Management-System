using AI_Powered_Learning_Application.Models;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using System;
using System.Web;

namespace AI_Powered_Learning_Application.Services
{
    public class FirebaseService
    {
        private readonly FirestoreDb _firestoreDb;

        public FirebaseService()
        {
            string path = Path.Combine(Directory.GetCurrentDirectory(), "appData", "ai-powered-app-9f8f5-firebase-adminsdk-fbsvc-3053abb861.json");

            Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", path);

            _firestoreDb = FirestoreDb.Create("ai-powered-app-9f8f5"); 
        }


        public FirestoreDb GetDb()
        {
            return _firestoreDb;
        }

        public async Task<List<Student>> GetAllStudentsAsync()
        {
            var snapshot = await _firestoreDb.Collection("students").GetSnapshotAsync();
            return snapshot.Documents.Select(doc => doc.ConvertTo<Student>()).ToList();
        }
        public async Task<Student?> GetStudentByIdAsync(string id)
        {
            var doc = await _firestoreDb.Collection("students").Document(id).GetSnapshotAsync();
            if (!doc.Exists) return null;

            var student = doc.ConvertTo<Student>();
            student.Id = doc.Id;
            return student;
        }

        public async Task DeleteStudentAsync(string documentId)
        {
            await _firestoreDb.Collection("students").Document(documentId).DeleteAsync();
        }
    }
}
