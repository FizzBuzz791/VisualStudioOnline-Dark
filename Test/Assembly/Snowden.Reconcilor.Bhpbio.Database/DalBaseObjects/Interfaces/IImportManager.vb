Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects
    Public Interface IImportManager
        Inherits Snowden.Common.Import.Database.IImportManager

        <System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1024:UsePropertiesWhereAppropriate")> _
        Function GetImportsRunningQueuedCount() As Int32

        Function DoesQueuedBlocksJobExist(ByVal importId As Integer, ByVal site As String, ByVal pit As String, ByVal Bench As String) As Boolean

        Function GetBhpbioBlockImportSyncRowsForLocation(ByVal importId As Int16, _
            ByVal isCurrent As Int16, ByVal iSite As String, ByVal iPit As String, ByVal iBench As String) As IDataReader

        Function GetBhpbioNextSyncQueueEntryForLocation(ByVal orderNo As Int64, ByVal importId As Int16,
            ByVal iSite As String, ByVal iPit As String, ByVal iBench As String) As DataTable

        Function GetBlockModelResourceClassification(Optional ByVal blockModelResourceClassificationId As Integer = -1) As DataTable

        Sub DeleteBlockModelResourceClassification(ByVal blockModelId As Integer, ByVal resourceClassification As String)

        Sub AddUpdateBlockModelResourceClassification(ByVal blockModelId As Integer, ByVal resourceClassification As String, ByVal percentage As Double)

    End Interface
End Namespace