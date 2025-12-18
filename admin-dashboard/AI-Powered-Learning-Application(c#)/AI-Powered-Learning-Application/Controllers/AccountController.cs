using AI_Powered_Learning_Application.Models.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace AI_Powered_Learning_Application.Controllers
{
    public class AccountController : Controller
    {
        private const string AdminUsername = "admin@gmail.com";
        private const string AdminPassword = "123456";

        [HttpGet]
        public IActionResult Login()
        {
            return View();
        }

        [HttpPost]
        public IActionResult Login(string username, string password)
        {
            if (username == AdminUsername && password == AdminPassword)
            {
                HttpContext.Session.SetString("IsAdmin", "true");
                return RedirectToAction("Index", "Home");
            }

            ViewBag.Error = "Invalid login credentials";
            return View();
        }

        public IActionResult Logout()
        {
            HttpContext.Session.Clear();
            HttpContext.Session.Remove("IsAdmin");
            return RedirectToAction("Login","Account");
        }
    }
}
