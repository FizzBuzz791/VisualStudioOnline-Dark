Imports Snowden.Common.Import

Public Module ModMain
    Public Function Main() As Integer
        Dim messagesText As String
        Dim commandLine As Data.CommandLine
        Dim returnCode As Int32

        commandLine = New Data.CommandLine(My.Application.CommandLineArgs, My.Resources.ResourceManager)

        commandLine.AddResourceManager(Snowden.Reconcilor.Bhpbio.Import.ResMain.SharedResourceManager)
        commandLine.AddImport(New Haulage())
        commandLine.AddImport(New Shipping())
        commandLine.AddImport(New Production())
        commandLine.AddImport(New Stockpile())
        commandLine.AddImport(New StockpileAdjustment())
        commandLine.AddImport(New ReconciliationMovement())
        commandLine.AddImport(New ReconBlockInsertUpdate())
        commandLine.AddImport(New BlockModel())
        commandLine.AddImport(New PortBalances())
        commandLine.AddImport(New PortBlending())
        commandLine.AddImport(New MetBalancing())

        'run the import
        messagesText = commandLine.Run(returnCode)

        'display all messages out through the trace listeners
        If messagesText <> String.Empty Then
            Trace.TraceInformation(messagesText.ToString)
        End If

        'return the error code (0 = success, 1 = fail)
        Return returnCode
    End Function
End Module
