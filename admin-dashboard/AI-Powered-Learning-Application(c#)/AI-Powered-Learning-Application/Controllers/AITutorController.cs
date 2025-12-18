using Microsoft.AspNetCore.Mvc;
using AI_Powered_Learning_Application.Models.AIModels;

namespace AI_Powered_Learning_Application.Controllers
{
    [Route("api/aitutor")]
    [ApiController]
    public class AITutorController : ControllerBase
    {
        private static readonly AITutorServiceSemantic _aiService = new AITutorServiceSemantic();

        [HttpPost("ask")]
        public IActionResult Ask([FromBody] QuestionRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Question))
                return BadRequest("Question cannot be empty.");

            var answer = _aiService.GetAnswer(request.Question);
            return Ok(new { answer });
        }
    }

    public class QuestionRequest
    {
        public string Question { get; set; } = string.Empty;
    }
}
