using AI_Powered_Learning_Application.Services;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Storage.V1;
using Microsoft.AspNetCore.Http;

namespace AI_Powered_Learning_Application.Services
{
    public class FirebaseStorageService : IFirebaseStorageService
    {
        private readonly StorageClient _storageClient;
        private readonly string _bucketName;
        private readonly ILogger<FirebaseStorageService> _logger;

        public FirebaseStorageService(IConfiguration configuration, ILogger<FirebaseStorageService> logger)
        {
            _logger = logger;

            // Use the EXACT bucket name from your Firebase config
            _bucketName = "ai-powered-app-9f8f5.firebasestorage.app";

            _logger.LogInformation($"Using Firebase Storage bucket: {_bucketName}");

            // Initialize Firebase App if not already done
            if (FirebaseApp.DefaultInstance == null)
            {
                try
                {
                    FirebaseApp.Create(new AppOptions()
                    {
                        Credential = GoogleCredential.GetApplicationDefault(),
                    });
                    _logger.LogInformation("Firebase app initialized successfully");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to initialize Firebase app");
                    throw;
                }
            }

            try
            {
                _storageClient = StorageClient.Create();
                _logger.LogInformation($"StorageClient created for bucket: {_bucketName}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create StorageClient");
                throw;
            }
        }

        public async Task<string> UploadPdfAsync(IFormFile pdfFile, string fileName)
        {
            try
            {
                // Generate unique file name
                var uniqueFileName = $"{Guid.NewGuid()}_{Path.GetFileName(fileName)}";
                var storagePath = $"pdfs/{uniqueFileName}";

                _logger.LogInformation($"Uploading PDF to: {_bucketName}/{storagePath}");

                using var stream = pdfFile.OpenReadStream();

                // Upload to Firebase Storage using your actual bucket name
                var uploadedObject = await _storageClient.UploadObjectAsync(
                    bucket: _bucketName,
                    objectName: storagePath,
                    contentType: "application/pdf",
                    source: stream
                );

                _logger.LogInformation($"PDF uploaded successfully: {storagePath}");

                // Generate public URL
                return GenerateFirebasePdfUrl(uniqueFileName);
            }
            catch (Google.GoogleApiException ex) when (ex.HttpStatusCode == System.Net.HttpStatusCode.NotFound)
            {
                _logger.LogError($"Bucket not found: {_bucketName}");
                _logger.LogError("Even though Storage is enabled, the .NET SDK might not support the new bucket format.");
                _logger.LogError("Try using the legacy bucket name format.");
                throw new Exception($"Bucket '{_bucketName}' not found. The .NET SDK may require the legacy 'appspot.com' format.", ex);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading PDF to Firebase Storage");
                throw;
            }
        }

        public async Task<bool> DeletePdfAsync(string fileUrl)
        {
            try
            {
                // Extract object name from URL
                var uri = new Uri(fileUrl);
                var objectName = Uri.UnescapeDataString(uri.Segments.Last());

                await _storageClient.DeleteObjectAsync(_bucketName, $"pdfs/{objectName}");

                _logger.LogInformation($"PDF deleted: {objectName}");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting PDF from Firebase Storage");
                return false;
            }
        }

        public string GenerateFirebasePdfUrl(string fileName)
        {
            var encodedFileName = Uri.EscapeDataString($"pdfs/{fileName}");

            // Generate URL using your actual bucket name
            return $"https://firebasestorage.googleapis.com/v0/b/{_bucketName}/o/{encodedFileName}?alt=media";
        }

        public bool IsPdfUrl(string url)
        {
            return url?.EndsWith(".pdf") == true ||
                   (url?.Contains("firebasestorage.googleapis.com") == true && url.Contains("pdfs")) ||
                   (url?.Contains("ai-powered-app-9f8f5.firebasestorage.app") == true && url.Contains("pdfs"));
        }
    }
}