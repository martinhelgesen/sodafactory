using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using sodafactoryclient.Models;

namespace sodafactoryclient.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private static int pageviewcount = 0;
    
    public HomeController(ILogger<HomeController> logger)
    {
        _logger = logger;
    }

    public IActionResult Index()
    {
        ViewData["PageViewCount"] = ++pageviewcount;
        return View();
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
