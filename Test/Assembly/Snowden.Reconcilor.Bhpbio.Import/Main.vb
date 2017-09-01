Imports System.Collections.ObjectModel
Imports System.Resources
Imports Snowden.Common.Import
Imports Snowden.Reconcilor.Bhpbio.Import

Public Module ModMain
    Public Function Main() As Integer
        SetupAndRunImport(My.Application.CommandLineArgs, My.Resources.ResourceManager)
    End Function

    Public Function SetupAndRunImportFromTestHarness(commandLineArgs As ReadOnlyCollection(Of String), importTypes As ImportTypeEnum) As Integer
        Dim config = ConfigurationSettings.BuildConfigurationSettings("reconcilor", "reconc!l0r", "D"c)

        Return SetupAndRunImport(commandLineArgs, My.Resources.ResourceManager, config, importTypes)
    End Function

    Private Function SetupAndRunImport(commandLineArgs As ReadOnlyCollection(Of String), resourceManager As ResourceManager, Optional config As ConfigurationSettings = Nothing, Optional importTypes As ImportTypeEnum = ImportTypeEnum.All) As Integer
        Dim messagesText As String
        Dim commandLine As Data.CommandLine
        Dim returnCode As Int32

        commandLine = New Data.CommandLine(commandLineArgs, resourceManager)

        commandLine.AddResourceManager(ResMain.SharedResourceManager)
        If (IsSet(importTypes, ImportTypeEnum.Haulage)) Then
            commandLine.AddImport(New Haulage(config))
        End If
        If (IsSet(importTypes, ImportTypeEnum.Shipping)) Then
            commandLine.AddImport(New Shipping(config))
        End If
        If (IsSet(importTypes, ImportTypeEnum.Production)) Then
            commandLine.AddImport(New Production(config))
        End If
        If (IsSet(importTypes, ImportTypeEnum.Stockpile)) Then
            commandLine.AddImport(New Stockpile(config))
        End If
        If (IsSet(importTypes, ImportTypeEnum.StockpileAdjustment)) Then
            commandLine.AddImport(New StockpileAdjustment(config))
        End If
        If (IsSet(importTypes, ImportTypeEnum.ReconciliationMovement)) Then
            commandLine.AddImport(New ReconciliationMovement(config))
        End If
        If (IsSet(importTypes, ImportTypeEnum.ReconBlockInsertUpdate)) Then
            commandLine.AddImport(New ReconBlockInsertUpdate(config))
        End If
        If (IsSet(importTypes, ImportTypeEnum.BlockModel)) Then
            commandLine.AddImport(New BlockModel())
        End If
        If (IsSet(importTypes, ImportTypeEnum.PortBalances)) Then
            commandLine.AddImport(New PortBalances(config))
        End If
        If (IsSet(importTypes, ImportTypeEnum.PortBlending)) Then
            commandLine.AddImport(New PortBlending(config))
        End If
        If (IsSet(importTypes, ImportTypeEnum.MetBalancing)) Then
            commandLine.AddImport(New MetBalancing(config))
        End If

        'run the import
        messagesText = commandLine.Run(returnCode)

        'display all messages out through the trace listeners
        If messagesText <> String.Empty Then
            Trace.TraceInformation(messagesText.ToString)
        End If

        'return the error code (0 = success, 1 = fail)
        Return returnCode
    End Function

    Public Function IsSet(value As ImportTypeEnum, flag As ImportTypeEnum) As Boolean
        Return (flag.Equals(ImportTypeEnum.All) Or ((value And flag).Equals(flag)))
    End Function

End Module
