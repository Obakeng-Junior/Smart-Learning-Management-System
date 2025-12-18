using CloudinaryDotNet.Actions;
using CloudinaryDotNet;
using Microsoft.Extensions.Logging;

namespace AI_Powered_Learning_Application.Services
{
    public class CloudinaryService
    {
        private readonly Cloudinary _cloudinary;
        private readonly ILogger<CloudinaryService> _logger;

        public CloudinaryService(ILogger<CloudinaryService> logger)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));

            var account = new Account(
                "dusaw4y3p",
                "811287815544353",
                "jK_rZZmEWR_DIhKclHaWMymjU1g"
            );

            _cloudinary = new Cloudinary(account);
        }

        public async Task<string> UploadImageAsync(IFormFile file)
        {
            try
            {
                await using var stream = file.OpenReadStream();

                var uploadParams = new ImageUploadParams
                {
                    File = new FileDescription(file.FileName, stream),
                    Folder = "courses",
                    Transformation = new Transformation().Width(800).Height(600).Crop("fill").Gravity("auto")
                };

                var result = await _cloudinary.UploadAsync(uploadParams);

                return result.SecureUrl.ToString();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Cloudinary upload failed.");
                throw;
            }
        }
        public async Task<string> UploadFileAsync(IFormFile file)
        {
            // Convert the file to a stream
            await using var stream = file.OpenReadStream();

            // Define upload parameters
            var uploadParams = new ImageUploadParams
            {
                File = new FileDescription(file.FileName, stream),
                Folder = "course-contents"  // Optional folder name
            };

            // Upload the file
            var uploadResult = await _cloudinary.UploadAsync(uploadParams);

            // Return the secure URL of the uploaded file
            return uploadResult.SecureUrl.ToString();
        }

        public async Task DeleteFileAsync(string imageUrl)
        {
            try
            {
                if (string.IsNullOrEmpty(imageUrl))
                {
                    _logger.LogWarning("Empty URL provided for deletion");
                    return;
                }

                // Extract public ID from URL
                var uri = new Uri(imageUrl);
                var publicId = Path.GetFileNameWithoutExtension(uri.AbsolutePath);

                if (string.IsNullOrEmpty(publicId))
                {
                    _logger.LogWarning($"Could not extract public ID from URL: {imageUrl}");
                    return;
                }

                var deletionParams = new DeletionParams(publicId);
                var result = await _cloudinary.DestroyAsync(deletionParams);

                if (result.Result == "ok")
                {
                    _logger.LogInformation($"Successfully deleted file: {publicId}");
                }
                else
                {
                    _logger.LogWarning($"Failed to delete file: {publicId}. Result: {result.Result}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting file: {imageUrl}");
                throw; // Re-throw to be handled by the controller
            }
        }

        public async Task DeleteImageAsync(string imageUrl)
        {
            if (string.IsNullOrWhiteSpace(imageUrl)) return;

            var uri = new Uri(imageUrl);
            var path = uri.AbsolutePath;
            var publicId = path.Split("upload/")[1].Split('.')[0];

            var deletionParams = new DeletionParams(publicId);
            await _cloudinary.DestroyAsync(deletionParams);
        }

    }
}
