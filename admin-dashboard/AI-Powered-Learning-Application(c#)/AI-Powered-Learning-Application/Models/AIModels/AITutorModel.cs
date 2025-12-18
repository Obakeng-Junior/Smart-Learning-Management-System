using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace AI_Powered_Learning_Application.Models.AIModels
{
    public class AITutorServiceSemantic
    {
        private class QA
        {
            public string Question { get; set; } = string.Empty;
            public string Answer { get; set; } = string.Empty;
        }

        private readonly List<QA> _qaList = new List<QA>();

        public AITutorServiceSemantic()
        {
            LoadCsv();
        }

        private void LoadCsv()
        {
            var dataPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "appData", "AITutorData.csv");

            if (!File.Exists(dataPath))
                throw new FileNotFoundException("CSV file not found at: " + dataPath);

            var lines = File.ReadAllLines(dataPath);
            foreach (var line in lines.Skip(1)) // skip header
            {
                var parts = ParseCsvLine(line);
                if (parts.Length >= 3)
                {
                    _qaList.Add(new QA
                    {
                        Question = parts[0],
                        Answer = parts[2]
                    });
                }
            }
        }

        private string[] ParseCsvLine(string line)
        {
            // Handles CSV with quotes
            var pattern = @"""([^""]*)""|([^,]+)";
            var matches = Regex.Matches(line, pattern);
            return matches.Select(m => string.IsNullOrEmpty(m.Groups[1].Value) ? m.Groups[2].Value : m.Groups[1].Value).ToArray();
        }

        public string GetAnswer(string studentQuestion)
        {
            if (string.IsNullOrWhiteSpace(studentQuestion))
                return "Please ask a valid question.";

            // Normalize the student question
            var normalizedQuery = studentQuestion.Trim().ToLower();

            // Compute similarity with all CSV questions
            QA bestMatch = null!;
            double bestScore = -1;

            foreach (var qa in _qaList)
            {
                var score = Similarity(normalizedQuery, qa.Question.ToLower());
                if (score > bestScore)
                {
                    bestScore = score;
                    bestMatch = qa;
                }
            }

            // Threshold to avoid totally unrelated matches
            if (bestScore < 0.3) // adjust as needed
                return "Sorry, I don't have an answer for that question.";

            return bestMatch.Answer;
        }

        private double Similarity(string a, string b)
        {
            var aWords = a.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            var bWords = b.Split(' ', StringSplitOptions.RemoveEmptyEntries);

            if (aWords.Length == 0 || bWords.Length == 0) return 0;

            var common = aWords.Intersect(bWords).Count();
            var total = Math.Sqrt(aWords.Length * bWords.Length);

            return common / total; // simple cosine-like similarity
        }
    }
}
