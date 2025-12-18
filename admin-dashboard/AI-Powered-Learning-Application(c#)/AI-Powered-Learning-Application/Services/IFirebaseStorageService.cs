using Microsoft.AspNetCore.Http;

namespace AI_Powered_Learning_Application.Services
{
    public interface IFirebaseStorageService
    {
        Task<string> UploadPdfAsync(IFormFile pdfFile, string fileName);
        Task<bool> DeletePdfAsync(string fileUrl);
        string GenerateFirebasePdfUrl(string fileName);
        bool IsPdfUrl(string url);
    }
}