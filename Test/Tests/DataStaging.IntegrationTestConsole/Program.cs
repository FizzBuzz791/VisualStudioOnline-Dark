using Snowden.Consulting.IntegrationService.Model;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DataStaging.IntegrationTestConsole
{
    class Program
    {
        /// <summary>
        /// Entry point to assembly
        /// </summary>
        /// <param name="args">command line argumenst (as described in usage text)</param>
        static void Main(string[] args)
        {
            string originalWorkingDirectory = Directory.GetCurrentDirectory();

            try
            {
                if (IsHelpMode(args))
                {
                    OutputUsage();
                    return;
                }

                // flag used to track success or failure
                bool allSuccess = false;

                // array of message paths for processing
                string[] messageFilePaths = null;

                // attempt to get a single message file path from command line
                string messageFilePath = GetMessageFilePath(args);
                if (!string.IsNullOrEmpty(messageFilePath))
                {
                    Console.WriteLine("Processing single file");
                    messageFilePaths = new string[] { messageFilePath };

                    Console.WriteLine(string.Format("Message Path is: {0}", messageFilePath));
                }
                else
                {
                    // otherwise process a message list file
                    Console.WriteLine("Processing files based on a message list");

                    // get a message list path from command line OR from settings
                    string messageListPath = GetMessageListPath(args);

                    if (string.IsNullOrEmpty(messageListPath))
                    {
                        OutputUsage();
                        return;
                    }

                    string messageListDirectory = Path.GetDirectoryName(messageListPath);

                    if (Directory.Exists(messageListDirectory)) 
                    {
                        Directory.SetCurrentDirectory(messageListDirectory);
                    }

                    Console.WriteLine(string.Format("Message List Path is: {0}", messageListPath));
                    messageFilePaths = GetMessageFilePaths(messageListPath);
                }


                // build the handler configuration
                MessageHandlerConfiguration configuration = BuildMessageHandlerConfiguration();
                // make the handler and initialise it
                IMessageHandler handler = InstantiateMessageHandler();
                handler.Initialise(configuration);

                // if file paths have been determined
                if (messageFilePaths != null)
                {
                    int index = 1;
                    int totalFiles = messageFilePaths.Length;
                    allSuccess = true;

                    // process each path
                    foreach (string path in messageFilePaths)
                    {
                        Console.Write("Processing file {0} of {1}: ", index, totalFiles);
                        allSuccess = allSuccess && ProcessMessageAtFilePath(handler, configuration, path);
                        index++;
                    }
                }

                if (allSuccess)
                {
                    Console.WriteLine("Finished with success");
                }
                else
                {
                    Console.WriteLine("Finished with errors");
                }
            }
            finally
            {
                if (Directory.GetCurrentDirectory() != originalWorkingDirectory)
                {
                    // reset the working directory if needed
                    Directory.SetCurrentDirectory(originalWorkingDirectory);
                }
            }
            
        }

        /// <summary>
        /// Instantiate the handler for processing
        /// </summary>
        /// <returns>the handler to perform processing</returns>
        private static IMessageHandler InstantiateMessageHandler()
        {
            Type handlerType = Type.GetType(Settings.Default.MessageHandlerType);

            if (handlerType == null) 
            {
                throw new InvalidOperationException(string.Format("Cannot instantiate handler for type: {0}", Settings.Default.MessageHandlerType));
            }
            IMessageHandler handler = Activator.CreateInstance(handlerType) as IMessageHandler;

            return handler;
        }

        /// <summary>
        /// Process a file
        /// </summary>
        /// <param name="handler">handler to perform processing</param>
        /// <param name="configuration">configuration to be used</param>
        /// <param name="messageFilePath">file path to the file containing message text</param>
        /// <returns>true on success, false otherwise</returns>
        private static bool ProcessMessageAtFilePath(IMessageHandler handler, MessageHandlerConfiguration configuration, string messageFilePath)
        {
            bool success = false;

            if (!File.Exists(messageFilePath))
            {
                Console.WriteLine("****** Skipping ****** file does not exist: {0}", messageFilePath);
            }
            else
            {
                Console.WriteLine("{0}", messageFilePath);

                string fileContents = File.ReadAllText(messageFilePath);

                Message m = new Message();
                m.MessageBody = fileContents;
                handler.Process(m);

                success = true;
            }

            return success;
        }

        /// <summary>
        /// Build a handler configuration based on settings
        /// </summary>
        /// <returns></returns>
        private static MessageHandlerConfiguration BuildMessageHandlerConfiguration()
        {
            MessageHandlerConfiguration config = new MessageHandlerConfiguration();
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "ProductionConfigurationPath", Value = Settings.Default.ProductionConfigurationPath });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "Database", Value = Settings.Default.DatabaseKey });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "ProductUser", Value = Settings.Default.ProductUser });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "StringReplaceSearchValues", Value = Settings.Default.StringReplaceSearchValues });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "StringReplaceReplaceValues", Value = Settings.Default.StringReplaceReplaceValues });

            return config;
        }

        /// <summary>
        /// Get a list of message file paths based on the contents of a message list
        /// </summary>
        /// <param name="messageListPath">path to the message list</param>
        /// <returns>an array of message files</returns>
        private static string[] GetMessageFilePaths(string messageListPath)
        {
            if (!File.Exists(messageListPath))
            {
                throw new Exception(String.Format("Message list file does not exist at '{0}'", Settings.Default.MessageListPath));
            }

            // each line of the file is the path of a message, except lines that start with '#'
            // or blank lines
            return File.ReadAllLines(messageListPath).Where(f => !String.IsNullOrEmpty(f) && !f.Trim().StartsWith("#")).ToArray();
        }

        /// <summary>
        /// Gets a Message List Path given a command line.  If no path is specified in the command line, the path defined in settings is returned
        /// </summary>
        /// <param name="args">command line arguments to be searched for a pth</param>
        /// <returns>The path to a message list file, from the command line if one was specified, otherwise from settings</returns>
        private static string GetMessageListPath(string[] args)
        {
            return GetParameterValueFollowingMarker(args, "-messageListPath") ?? Settings.Default.MessageListPath;
        }

        /// <summary>
        /// Gets a Message file Path given a command line.  If no path is specified in the command line, null is returned
        /// </summary>
        /// <param name="args">command line arguments to be searched for a pth</param>
        /// <returns>The path found if any</returns>
        private static string GetMessageFilePath(string[] args)
        {
            return GetParameterValueFollowingMarker(args, "-messageFilePath");
        }

        /// <summary>
        /// Determines whether this tool is being used in help mode
        /// </summary>
        /// <param name="args">command line arguments to be searched</param>
        /// <returns>true if -help has been passed</returns>
        private static bool IsHelpMode(string[] args)
        {
            bool helpMode = false;

            if (args != null)
            {
                if (args.Any(a =>
                {
                    bool match = false;

                    switch (a.ToLower())
                    {
                        case "/help":
                            match = true;
                            break;
                        case "-help":
                            match = true;
                            break;
                        case "--help":
                            match = true;
                            break;
                        case "?":
                            match = true;
                            break;
                        case "/?":
                            match = true;
                            break;
                        case "-?":
                            match = true;
                            break;
                        case "--?":
                            match = true;
                            break;
                        default:
                            match = false;
                            break;
                    }
                    return match;
                })) 
                {
                    helpMode = true;
                }
            }

            return helpMode;
        }

        /// <summary>
        /// Returns the command line parameter value that follows a given marker
        /// </summary>
        /// <param name="args">command line arguments to search</param>
        /// <param name="marker">the marker which precedes the value to return</param>
        /// <returns>the command line parameter value matched if any</returns>
        private static string GetParameterValueFollowingMarker(string[] args, string marker)
        {
            string returnValue = null;

            int? paramIndex = null;
            for (int i = 0; i < args.Length; i++)
            {
                if (args[i].ToLower() == marker.ToLower())
                {
                    paramIndex = i;
                    break;
                }
            }

            if (paramIndex != null)
            {
                if (args.Length >= paramIndex.Value)
                {
                    returnValue = args[paramIndex.Value + 1];
                }
            }

            return returnValue;
        }

        /// <summary>
        /// Output usage information for the tool
        /// </summary>
        private static void OutputUsage()
        {
            Console.WriteLine(@"
DataStaging.IntegrationTestConsole Usage Instructions.

This tool uses a mix of config file and command line arguments.  

    -   The path to a ProductConfiguration file and other
        important information must be defined in the 
        configuration file (refer to example configuration files).

    -   A path to a message list file can also be defined in
        the configuration file.

    -   The path to a message list file can be overridden on 
        the command line using the -messageListPath argument.
    
    -   The path to an individual message file can be passed
        on the command line using the -messageFilePath argument.

The default mode of operation is to process a list of messages
defined by a message list file. However if the -messageFilePath 
command line argument is used then only the individual message 
at the specified path will be processed.

The tool can be used in the following forms:

    DataStaging.IntegrationTestConsole [/help|-help|--help|?|/?|-?|--?] 
        :   displays this usage text without processing any messages

    DataStaging.IntegrationTestConsole
        :   processes messages within a message list based entirely on
            configuration file settings

    DataStaging.IntegrationTestConsole -messageFilePath [filepath]
        :   processes a specfic message file

    DataStaging.IntegrationTestConsole -messageListPath [filepath]
        :   processes a list of messages based on the message 
            list at the path specified

");
        }
    }
}
