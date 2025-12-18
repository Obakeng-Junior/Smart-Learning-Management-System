using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace AI_Powered_Learning_Application.Controllers
{
    public class AdminController : Controller
    {
        public override void OnActionExecuting(ActionExecutingContext context)
        {
            if (HttpContext.Session.GetString("IsAdmin") != "true")
            {
                context.Result = RedirectToAction("Login", "Account");
            }
            base.OnActionExecuting(context);
        }

        public IActionResult Index()
        {
            return View();
        }
    }
}
