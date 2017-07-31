Imports System.IO
Imports System.IO.Compression
Imports Snowden.Common.Import

Public Class GeneralHelper

    Public Shared Sub LogValidationError(message As String, fields() As String, syncQueueRow As DataRow, importSyncValidate As DataTable, importSyncValidateField As DataTable)
        LogValidationError(message, message, fields, syncQueueRow, importSyncValidate, importSyncValidateField)
    End Sub


    Public Shared Sub LogValidationError(userMessage As String, internalMessage As String, fields() As String, syncQueueRow As DataRow, importSyncValidate As DataTable,
        importSyncValidateField As DataTable)

        Dim field As String

        Dim importSyncValidateId As Long = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, DirectCast(syncQueueRow("ImportSyncQueueId"), Int64),
            userMessage, internalMessage)

        For Each field In fields
            SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, field)
        Next
    End Sub

    Public Shared Sub LogValidationError(message As String, field As String, syncQueueRow As DataRow, importSyncValidate As DataTable,
        importSyncValidateField As DataTable)

        Dim importSyncValidateId As Long = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, DirectCast(syncQueueRow("ImportSyncQueueId"), Int64),
            message, message)

        SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, field)
    End Sub

    Public Shared Sub LogConflict(message As String, fields() As String, syncQueueRow As DataRow, importSyncConflict As DataTable,
        importSyncConflictField As DataTable)

        Dim field As String

        Dim importSyncConflictId As Long = SyncImportDataHelper.AddImportSyncConflict(importSyncConflict, DirectCast(syncQueueRow("ImportSyncQueueId"), Int64),
            message, message)

        For Each field In fields
            SyncImportDataHelper.AddImportSyncConflictField(importSyncConflictField, importSyncConflictId, field)
        Next
    End Sub

    Public Shared Sub LogConflict(message As String, field As String, syncQueueRow As DataRow, importSyncConflict As DataTable,
        importSyncConflictField As DataTable)

        Dim importSyncConflictId As Long = SyncImportDataHelper.AddImportSyncConflict(importSyncConflict, DirectCast(syncQueueRow("ImportSyncQueueId"), Int64),
            message, message)

        SyncImportDataHelper.AddImportSyncConflictField(importSyncConflictField, importSyncConflictId, field)
    End Sub

    Public Shared Function CompressString(uncompressedInput As String, header As String, footer As String) As String
        Dim result As String
        Dim outputStream As MemoryStream = Nothing
        Dim compressedStream As DeflateStream = Nothing
        Dim writer As StreamWriter = Nothing

        Try
            outputStream = New MemoryStream()
            compressedStream = New DeflateStream(outputStream, CompressionMode.Compress)
            writer = New StreamWriter(compressedStream)

            writer.Write(uncompressedInput)
            writer.Flush()
            writer.Close()
            result = header & Convert.ToBase64String(outputStream.ToArray) & footer
        Finally
            If Not (outputStream Is Nothing) Then
                outputStream.Dispose()
            End If

            If Not (compressedStream Is Nothing) Then
                compressedStream.Dispose()
            End If

            If Not (writer Is Nothing) Then
                writer.Dispose()
            End If
        End Try

        Return result
    End Function

    Public Shared Function DecompressString(compressedInput As String, header As String, footer As String) As String
        Dim result As String
        Dim compressedBinary As Byte()
        Dim inputStream As MemoryStream = Nothing
        Dim decompressedStream As Stream = Nothing
        Dim reader As StreamReader

        If Not compressedInput.StartsWith(header) Or Not compressedInput.EndsWith(footer) Then
            Throw New InvalidOperationException("The string provided does not have the correct header and footer.")
        End If

        Try
            compressedBinary = Convert.FromBase64String(compressedInput.Substring(header.Length, compressedInput.Length - header.Length - footer.Length))
            inputStream = New MemoryStream(compressedBinary)
            decompressedStream = New DeflateStream(inputStream, CompressionMode.Decompress)

            reader = New StreamReader(decompressedStream)
            result = reader.ReadLine()
            reader.Close()
        Finally
            If Not (inputStream Is Nothing) Then
                inputStream.Dispose()
            End If

            If Not (decompressedStream Is Nothing) Then
                decompressedStream.Dispose()
            End If
        End Try

        Return result
    End Function
End Class