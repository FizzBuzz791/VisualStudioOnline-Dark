Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects
    Public Interface IDigblock
        Inherits Snowden.Reconcilor.Core.Database.DalBaseObjects.IDigblock

        Function GetDigblockModelBlockGradeOverPeriod(ByVal locationId As Int32, _
            ByVal blockModelId As Int32, ByVal gradeId As Int32) As DataTable

        Function GetDigblockHaulageGradeOverRange(ByVal locationId As Int32, _
         ByVal startDate As DateTime, _
         ByVal endDate As DateTime, ByVal gradeId As Int32) As DataTable

        Function GetDigblockReconciledGradeOverPeriod(ByVal locationId As Int32, _
         ByVal startDate As DateTime, _
         ByVal endDate As DateTime, ByVal gradeId As Int32) As DataTable

        <System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1024:UsePropertiesWhereAppropriate")> _
        Function GetBhpbioReconciliationMovements(ByVal LocationId As Integer) As DataTable

        Function GetBhpbioDigblockPolygonList(ByVal locationId As Int32, _
         ByVal materialCategoryId As String, ByVal rootMaterialTypeId As Int32) As DataTable

        Function DoesBhpbioDigblockNotesExist(ByVal digblockNotesField As String, ByVal digblockNotes As String) As Boolean

        Function GetBhpbioDigblockFieldNotes(ByVal digblockId As String, ByVal digblockNotesField As String) As String

        Function DoesBhpbioDigblockHaulageExist(ByVal digblockId As String) As Boolean

        Function DoesBhpbioDigblockAssociationsExist(ByVal digblockId As String) As Boolean

        Sub ResolveBhpbioDataExceptionDigblockHasHaulage(ByVal digblockId As String)

        Sub DeleteBhpbioDataExceptionDigblockHasHaulage(ByVal digblockId As String)

        Sub AddOrActivateBhpbioDataExceptionDigblockHasHaulage(ByVal digblockId As String)
        Function GetBhpbioResourceClassificationData(ByVal digiblock As String) As DataTable
    End Interface
End Namespace
