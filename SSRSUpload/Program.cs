using System;
using System.IO;
using SSRSUpload.Properties;

namespace SSRSUpload {
    class Program
    {
        static ReportService2010.ReportingService2010 _rs = null;

        public static ReportService2010.ReportingService2010 rs
        {
            get
            {
                if(_rs == null)
                {
                    _rs = new ReportService2010.ReportingService2010();
                    _rs.Credentials = System.Net.CredentialCache.DefaultCredentials;
                }

                return _rs;
            }
        }

        static void Main(string[] args)
        {
            string sourceDirectory = Settings.Default.SourceFolder;
            string destinationPath = Settings.Default.DestinationFolder;

            string instanceName = rs.Url.Replace("http://", "").Replace("/ReportService2010.asmx", "").Replace("/ReportServer", "/");

            Console.WriteLine("Uploading reports to '{0}' from '{1}'", instanceName, sourceDirectory);

            foreach (var filePath in Directory.GetFiles(sourceDirectory, "*.rdl"))
            {
                var fileName = Path.GetFileName(filePath);
                Console.WriteLine("Uploading '{0}'", fileName);

                var warnings = UploadReport(filePath, destinationPath);
                PrintWarnings(fileName, warnings);
            }

        }

        private static void PrintWarnings(string fileName, ReportService2010.Warning[] warnings)
        {
            if (warnings != null && warnings.Length > 0)
            {
                foreach (var warning in warnings)
                {
                    if (warning.Message.Contains("Overlapping"))
                        continue;

                    Console.WriteLine(" - Warning for {0}: {1}", fileName, warning.Message);
                }
            }
        }

        public static ReportService2010.Warning[] UploadReport(string filePath, string serverPath)
        {
            var fileName = Path.GetFileName(filePath);
            var reportName = fileName.Replace(".rdl", "");
            var fileBytes = File.ReadAllBytes(filePath);

            ReportService2010.Warning[] warnings = null;
            rs.CreateCatalogItem("Report", reportName, serverPath, true, fileBytes, null, out warnings);
            return warnings;
        }
    }
}
