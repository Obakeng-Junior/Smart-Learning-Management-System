using AI_Powered_Learning_Application.Models;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace AI_Powered_Learning_Application.Services
{
    public class FirebaseService
    {
        private readonly FirestoreDb _firestoreDb;

        public FirebaseService()
        {
            // Read path from environment variable
            string path = Environment.GetEnvironmentVariable("FIREBASE_KEY_PATH");

            if (string.IsNullOrEmpty(path) || !File.Exists(path))
                throw new FileNotFoundException(
                    "Firebase key not found. Please set FIREBASE_KEY_PATH environment variable to your service account JSON path."
                );

            // Set Google credentials environment variable
            Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", path);

            // Initialize Firebase app (only once)
            if (FirebaseApp.DefaultInstance == null)
            {
                FirebaseApp.Create(new AppOptions()
                {
                    Credential = GoogleCredential.FromFile(path)
                });
            }

            // Initialize Firestore
            _firestoreDb = FirestoreDb.Create("ai-powered-app-9f8f5");
        }

        public FirestoreDb GetDb() => _firestoreDb;

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
