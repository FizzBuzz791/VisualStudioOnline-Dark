Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Internal
    Public Class LocationPickerTree
        Inherits WebpageTemplates.ReconcilorAjaxPage

#Region " Properties "
        Private _disposed As Boolean
        Private _dalUtility As Snowden.Reconcilor.Core.Database.DalBaseObjects.IUtility
        Private _locationPickerTree As ReconcilorControls.ReconcilorTable
        Private _stagingDiv As New Tags.HtmlDivTag
        Private _width As Int32
        Private _locationJavaScript As String
        Private _showLocationType As Boolean
        Private _showNodeImage As Boolean
        Private _autoSelectNode As Boolean
        Private _pickerId As String
        Private _lowestLocationTypeDescription As String

        Public Property DalUtility() As Core.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Core.Database.DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property

        Public Property LocationPickerTree() As ReconcilorControls.ReconcilorTable
            Get
                Return _locationPickerTree
            End Get
            Set(ByVal value As ReconcilorControls.ReconcilorTable)
                _locationPickerTree = value
            End Set
        End Property

        Public ReadOnly Property StagingDiv() As Tags.HtmlDivTag
            Get
                Return _stagingDiv
            End Get
        End Property
#End Region

        Public Sub New()
            _width = 150
        End Sub


#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        'Clean up managed Resources ie: Objects
                        If (Not _stagingDiv Is Nothing) Then
                            _stagingDiv.Dispose()
                            _stagingDiv = Nothing
                        End If

                        If (Not _locationPickerTree Is Nothing) Then
                            _locationPickerTree.Dispose()
                            _locationPickerTree = Nothing
                        End If

                        If (Not _dalUtility Is Nothing) Then
                            _dalUtility.Dispose()
                            _dalUtility = Nothing
                        End If
                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                ProcessData()
            Catch ea As Threading.ThreadAbortException
                Return
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error retrieving location picker tree:\n")
            End Try
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _width = RequestAsInt32("Width")
            _locationJavaScript = RequestAsString("locationJavaScript")
            _showLocationType = RequestAsBoolean("showLocationType")
            _showNodeImage = RequestAsBoolean("showNodeImage")
            _autoSelectNode = RequestAsBoolean("autoSelectNode")
            _pickerId = RequestAsString("pickerId")
            _lowestLocationTypeDescription = RequestAsString("lowestLocationTypeDescription")
        End Sub

        Protected Overrides Sub ProcessData()
            Dim stageArea As New Tags.HtmlDivTag("itemStage")
            Dim useColumns As String() = {"Expand"}
            Dim locationTypeId As Int16 = 0
            If _showLocationType = False Then
                locationTypeId = DoNotSetValues.Int16
            End If
            Dim nodeData As DataTable = LocationPickerTreeNode.GetNodeData(DalUtility, "", _
             0, locationTypeId, 0, _locationJavaScript, _showNodeImage, _pickerId, _lowestLocationTypeDescription)

            ' If auto select and there are nodes.
            If _autoSelectNode AndAlso nodeData.Rows.Count > 0 Then
                If _showLocationType = False And _locationJavaScript <> "" Then
                    Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
                     Tags.ScriptLanguage.JavaScript, "", _locationJavaScript & "('" & nodeData.Rows(0)("Location_Id").ToString & "');"))
                End If
            End If

            MyBase.ProcessData()

            LocationPickerTree = New ReconcilorControls.ReconcilorTable(nodeData, useColumns)
            With LocationPickerTree
                .ID = _pickerId + "tree"
                .RowIdColumn = "NodeRowId"
                .IsSortable = False
                .CanExportCsv = False
                .Height = 200
                .HeaderHeight = 30

                .Columns.Add("Expand", New ReconcilorControls.ReconcilorTableColumn("Location Picker", _width))
                .Columns("Expand").TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Left

                .DataBind()
            End With

            With stageArea
                .Style.Add("display", "none")
            End With

            Controls.Add(LocationPickerTree)
            Controls.Add(stageArea)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If DalUtility Is Nothing Then
                DalUtility = New Core.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub
    End Class
End Namespace