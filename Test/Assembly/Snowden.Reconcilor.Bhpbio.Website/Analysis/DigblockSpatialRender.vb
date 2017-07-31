Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Reconcilor.Core
Imports System.Text
Imports Snowden.Reconcilor.Core.Website.Analysis
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.Drawing

Namespace Analysis
    Public Class DigblockSpatialRender
        Inherits Snowden.Reconcilor.Core.Website.Analysis.DigblockSpatialRender

        Private Const _designationMaterialCategoryId As String = "Designation"

        Private _attributeFilter As String
        Private _grades As New Dictionary(Of String, Grade)
        Private _disposed As Boolean
        Private _designationMaterialTypeId As Int32?

        Public Property AttributeFilter() As String
            Get
                Return _attributeFilter
            End Get
            Set(ByVal value As String)
                _attributeFilter = value
            End Set
        End Property

        Public Property Grades() As Dictionary(Of String, Reconcilor.Core.Grade)
            Get
                Return _grades
            End Get
            Set(ByVal value As Dictionary(Of String, Reconcilor.Core.Grade))
                _grades = value
            End Set
        End Property

        Public Property DesignationMaterialTypeId() As Int32?
            Get
                Return _designationMaterialTypeId
            End Get
            Set(ByVal value As Int32?)
                _designationMaterialTypeId = value
            End Set
        End Property

        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                    End If

                    _grades = Nothing
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub

        Public Overridable Sub GetGradeInformation()
            Grades() = New Dictionary(Of String, Reconcilor.Core.Grade)
            Dim gradeData As DataTable = DalUtility.GetGradeList(Convert.ToInt16(True))
            Dim gradeRow As DataRow
            Dim numberFormat As String = DalUtility.GetSystemSetting("FORMAT_NUMERIC")

            For Each gradeRow In gradeData.Rows
                Grades.Add(gradeRow("Grade_ID").ToString, New Grade(gradeRow, numberFormat))
            Next
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            Try
                AttributeFilter = RequestAsString("AttributeFilter")
                DesignationMaterialTypeId = RequestAsInt32("Designation")
                If DesignationMaterialTypeId = -1 Then
                    DesignationMaterialTypeId = Nothing
                End If
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error retrieving spatial comparison request:\n")
            End Try

            MyBase.RetrieveRequestData()
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If DalDigblock Is Nothing Then
                DalDigblock = New Bhpbio.Database.SqlDal.SqlDalDigblock(Resources.Connection)
            End If

            If DalUtility Is Nothing Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Function RetrieveComparisonDataTable(ByVal comparisonType As Integer, ByVal postFix As String) As DataTable
            Dim returnTable As DataTable
            Dim bhpDalDigblock As Bhpbio.Database.DalBaseObjects.IDigblock

            bhpDalDigblock = DirectCast(DalDigblock, Bhpbio.Database.SqlDal.SqlDalDigblock)
            returnTable = New DataTable
            If AttributeFilter = "Tonnes" Then
                returnTable = MyBase.RetrieveComparisonDataTable(comparisonType, postFix)
            Else
                Select Case comparisonType
                    Case SpatialActualHaulageItem
                        returnTable = bhpDalDigblock.GetDigblockHaulageGradeOverRange(LocationId, StartDate, EndDate, Convert.ToInt32(AttributeFilter))
                    Case SpatialActualReconciledItem
                        returnTable = bhpDalDigblock.GetDigblockReconciledGradeOverPeriod(LocationId, StartDate, EndDate, Convert.ToInt32(AttributeFilter))
                    Case SpatialModelBlockItem
                        If postFix = "A" Then
                            returnTable = bhpDalDigblock.GetDigblockModelBlockGradeOverPeriod(LocationId, LeftBlockModelId, Convert.ToInt32(AttributeFilter))
                        Else
                            returnTable = bhpDalDigblock.GetDigblockModelBlockGradeOverPeriod(LocationId, RightBlockModelId, Convert.ToInt32(AttributeFilter))
                        End If
                    Case Else
                        Throw New InvalidOperationException("Comparison type for " & postFix & " is not supported.")
                End Select

                returnTable.Columns("Tonnes").ColumnName = "Tonnes_" & postFix
            End If

            Return returnTable
        End Function

        Protected Overrides Function GeneratePolygonToolTip(ByVal digblockId As String, ByVal variance As Object, ByVal tonnesA As Object, ByVal tonnesB As Object) As String
            Dim returnString As New StringBuilder
            Dim numberFormat As String = DalUtility.GetSystemSetting("FORMAT_NUMERIC")

            GetGradeInformation()

            returnString.Append(digblockId)
            returnString.Append(vbCrLf)

            If AttributeFilter = "Tonnes" Then
                returnString.Append("Tonnes Comparison")
            Else
                returnString.Append("Grade " & Grades.Item(AttributeFilter).Name & " Comparison")
            End If
            returnString.Append(vbCrLf)

            If (variance Is DBNull.Value) Or (variance Is Nothing) Then
                returnString.Append("Variance: - ")
            Else
                returnString.Append("Variance: ")
                returnString.Append(Convert.ToDouble(variance).ToString(numberFormat))
                returnString.Append("%")
            End If

            returnString.Append(vbCrLf)
            returnString.Append("Comparison A:")

            If (tonnesA Is DBNull.Value) Or (tonnesA Is Nothing) Then
                returnString.Append(" - ")
            Else
                If AttributeFilter = "Tonnes" Then
                    returnString.Append(Convert.ToDouble(tonnesA).ToString(numberFormat))
                Else
                    returnString.Append(Grades.Item(AttributeFilter).ToString(tonnesA))
                End If
            End If

            returnString.Append(vbCrLf)
            returnString.Append("Comparison B:")

            If (tonnesB Is DBNull.Value) Or (tonnesB Is Nothing) Then
                returnString.Append(" - ")
            Else
                If AttributeFilter = "Tonnes" Then
                    returnString.Append(Convert.ToDouble(tonnesB).ToString(numberFormat))
                Else
                    returnString.Append(Grades.Item(AttributeFilter).ToString(tonnesB))
                End If
            End If

            Return returnString.ToString
        End Function

        Protected Overrides Function BuildComparisonDataTable() As DataSet
            Dim returnDs As New DataSet
            Dim compA, compB As DataTable

            Dim dalBhpbioDigblock As Bhpbio.Database.DalBaseObjects.IDigblock

            dalBhpbioDigblock = New Bhpbio.Database.SqlDal.SqlDalDigblock()
            dalBhpbioDigblock.DataAccess.Connection = DalDigblock.DataAccess.Connection

            'Load the original polygon list
            If _designationMaterialTypeId.HasValue Then
                returnDs.Tables.Add(dalBhpbioDigblock.GetBhpbioDigblockPolygonList(LocationId, _
                 _designationMaterialCategoryId, _designationMaterialTypeId.Value))
            Else
                returnDs.Tables.Add(dalBhpbioDigblock.GetBhpbioDigblockPolygonList(LocationId, _
                 _designationMaterialCategoryId, NullValues.Int32))
            End If
            returnDs.Tables(0).TableName = "PolygonData"

            'Load the comparison tables
            compA = RetrieveComparisonDataTable(LeftComparisonType, "A")
            compB = RetrieveComparisonDataTable(RightComparisonType, "B")

            'Merge the comps into the source table
            Dim primaryKey() As DataColumn = {compA.Columns("Digblock_Id")}
            compA.PrimaryKey = primaryKey
            compA.Columns.Add(New DataColumn("Tonnes_B", GetType(Double)))
            compA.Merge(compB)

            'Add the Variance Calculated Column
            compA.Columns.Add(New DataColumn("Variance", GetType(Double), "(Tonnes_B - Tonnes_A) / Tonnes_A * 100"))

            returnDs.Tables.Add(compA)
            returnDs.Tables(1).TableName = "VarianceData"

            dalBhpbioDigblock = Nothing

            Return returnDs
        End Function

    End Class
End Namespace