Module EngineConsole

    Sub Main()
        Dim engine As Snowden.Common.Engine.Engine

        Dim currentDomain As AppDomain = AppDomain.CurrentDomain
        AddHandler currentDomain.UnhandledException, AddressOf MyHandler

        Console.WriteLine("Reconcilor Engine Console")
        Console.WriteLine()

        Console.Write("Creating the Engine....... ")
        engine = New Snowden.Common.Engine.Engine()
        Console.WriteLine("Created.")

        Try

            Console.Write("Initialising the Engine... ")
            engine.Initialise()
            Console.WriteLine("Initialised.")

            Console.Write("Starting Engine........... ")
            engine.RequestStart()
            Console.WriteLine("Started.")
            Console.WriteLine()

            Console.Write(".. Press <Space> to Stop ..")
            While Not Console.ReadKey().KeyChar = " "c
                'keep looping until <space> is pressed
            End While
            Console.WriteLine()
            Console.WriteLine()

            Console.Write("Stopping Engine........... ")
            engine.RequestStop()
            Console.WriteLine("Stopped.")
            Console.WriteLine()

        Catch ex As Exception
            Console.WriteLine("An exception has been encountered:")
            Console.WriteLine(ex.ToString)
            Console.WriteLine()

        Finally
            If Not engine Is Nothing Then
                engine.Dispose()
                engine = Nothing
            End If
        End Try

        Console.Write(".. Press <Space> to Close ..")
        While Not Console.ReadKey().KeyChar = " "c
            'keep looping until <space> is pressed
        End While
    End Sub

    Sub MyHandler(sender As Object, args As UnhandledExceptionEventArgs)
        Dim e As Exception = DirectCast(args.ExceptionObject, Exception)
        Console.WriteLine("MyHandler caught : " + e.Message)
    End Sub

End Module
