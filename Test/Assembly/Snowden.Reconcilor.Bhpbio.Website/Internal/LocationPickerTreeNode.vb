Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Internal
    Public Class LocationPickerTreeNode
        Inherits WebpageTemplates.AnalysisAjaxTemplate

#Region " Properties "
        Private _dalUtility As Core.Database.DalBaseObjects.IUtility
        Private _nodeLevel As Int32 = DoNotSetValues.Int32
        Private _nodeRowId As String
        Private _locationId As Int32 = DoNotSetValues.Int32
        Private _locationTypeId As Int16 = DoNotSetValues.Int16
        Private _locationJavaScript As String
        Private _showNodeImage As Boolean
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

        Public Property NodeLevel() As Int32
            Get
                Return _nodeLevel
            End Get
            Set(ByVal value As Int32)
                _nodeLevel = value
            End Set
        End Property

        Public Property NodeRowId() As String
            Get
                Return _nodeRowId
            End Get
            Set(ByVal value As String)
                _nodeRowId = value
            End Set
        End Property

        Public Property LocationTypeId() As Int16
            Get
                Return _locationTypeId
            End Get
            Set(ByVal value As Int16)
                _locationTypeId = value
            End Set
        End Property

        Public Property LocationId() As Int32
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32)
                _locationId = value
            End Set
        End Property
#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Try
                NodeLevel = RequestAsInt32("NodeLevel")
                NodeRowId = RequestAsString("NodeRowId")
                LocationTypeId = RequestAsInt16("LocationTypeId")
                LocationId = RequestAsInt32("LocationId")
                _locationJavaScript = RequestAsString("locationJavaScript")
                _showNodeImage = RequestAsBoolean("showNodeImage")
                _pickerId = RequestAsString("pickerId")

                _lowestLocationTypeDescription = RequestAsString("lowestLocationTypeDescription")
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error retrieving location picker node request:\n")
            End Try
        End Sub

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


        Protected Overrides Sub ProcessData()
            MyBase.ProcessData()

            Dim nodeData As DataTable
            Dim data As DataRow
            Dim returnTable As New Web.UI.WebControls.Table

            nodeData = GetNodeData(DalUtility, NodeRowId, LocationId, _
             LocationTypeId, NodeLevel, _locationJavaScript, _showNodeImage, _pickerId, _lowestLocationTypeDescription)

            returnTable.ID = "StageTable"

            For Each data In nodeData.Rows
                returnTable.Controls.Add(GetNodeTableRow(data))
            Next

            Controls.Add(returnTable)

            'Add call to append nodes
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
             Tags.ScriptLanguage.JavaScript, "", "AppendLocationPickerNodes('" & NodeRowId & "');"))
        End Sub

        Protected Overridable Function GetNodeTableRow(ByVal data As DataRow) As Web.UI.WebControls.TableRow
            Dim returnRow As New Web.UI.WebControls.TableRow
            Dim cell As Web.UI.WebControls.TableCell

            'Setup the returning row so we know a bit more about it when showing/hiding it
            'Append the recordId to the end of the parent Id so that a simple "in string" check
            'can be done.
            returnRow.ID = NodeRowId & "_" & data("Location_Id").ToString()

            cell = New Web.UI.WebControls.TableCell
            cell.Controls.Add(ReconcilorFunctions.GetIndentedNodeTable(data("Expand"), NodeLevel))
            returnRow.Cells.Add(cell)
            'cell = New Web.UI.WebControls.TableCell
            'cell.Controls.Add(ReconcilorFunctions.FormatDataColumn(data, "Select"))
            'returnRow.Cells.Add(cell)

            Return returnRow
        End Function

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New Core.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If
        End Sub

        Public Shared Function GetNodeData(ByVal dal As Core.Database.DalBaseObjects.IUtility, _
         ByVal nodeId As String, ByVal locationId As Int32, ByVal locationTypeId As Short, _
         ByVal nodeLevel As Int32, ByVal locationJs As String, ByVal showImage As Boolean, ByVal pickerId As String, ByVal lowestLocationTypeDescription As String) As DataTable
            Dim nodeData As DataTable
            Dim expandStr As String
            Dim colExpression As String
            Dim descriptionText As String = ""
            Dim lowestLocationTypeId As Integer

            If (locationTypeId = 0) Then
                nodeData = dal.GetLocationTypeList(0)
            ElseIf (locationId = 0) Then
                nodeData = dal.GetLocationList(0, locationId, DoNotSetValues.Int32, locationTypeId)
            Else
                nodeData = dal.GetLocationList(0, locationId, DoNotSetValues.Int32, DoNotSetValues.Int16)
            End If

            If lowestLocationTypeDescription <> String.Empty Then

                lowestLocationTypeId = Convert.ToInt32(dal.GetLocationTypeList(NullValues.Int16).Select("Description='" + lowestLocationTypeDescription + "'")(0)("Location_Type_Id"))

                For Each row As DataRow In nodeData.Rows
                    If DirectCast(row("Children"), Integer) > 0 AndAlso _
                        Convert.ToInt32(row("Location_Type_Id")) = lowestLocationTypeId Then
                        row("Children") = 0
                    End If
                Next

                nodeData.AcceptChanges()

            End If


            expandStr = _
             "'<img src=""%IMAGELOCATION%"" id=""Image_%PICKERID%_%NODEROWID%"" " & _
             "onclick=""ToggleLocationPickerNode(''Node_%PICKERID%_%NODEROWID%'', %NODELEVEL%, %LOCATIONID%, %LOCATIONTYPEID%, ''%LOCATIONJSFUNCTION%'', ''%SHOWNODEIMAGE%'', ''%PICKERID%'', ''%LOWESTTYPE%'' );"" />' "
            If showImage Then
                If nodeLevel = 0 Then
                    descriptionText = descriptionText & "'<img src=""../images/locationTreeRoot.gif"">' +"
                Else
                    descriptionText = descriptionText & "'<img src=""../images/locationTreeNode.gif"">' +"
                End If
            End If
            If (locationJs <> "" And locationTypeId <> 0) Then
                descriptionText = descriptionText & " '<a href=""#"" onclick=""%LOCATIONJSFUNCTION%(%LOCATIONID%);"">' + Description  + '</a>'"
            Else
                descriptionText = descriptionText & "Description"
            End If

            expandStr = expandStr.Replace("%LOWESTTYPE%", lowestLocationTypeDescription)
            expandStr = expandStr.Replace("%PICKERID%", pickerId)
            descriptionText = descriptionText.Replace("%LOCATIONJSFUNCTION%", locationJs)
            expandStr = expandStr.Replace("%LOCATIONJSFUNCTION%", locationJs)
            expandStr = expandStr.Replace("%IMAGELOCATION%", "../images/plus.png")
            expandStr = expandStr.Replace("%NODELEVEL%", (nodeLevel + 1).ToString)
            expandStr = expandStr.Replace("%LOCATIONTYPEID%", "' + Location_Type_Id + '")
            expandStr = expandStr.Replace("%SHOWNODEIMAGE%", showImage.ToString)

            If Not locationTypeId = 0 Then
                descriptionText = descriptionText.Replace("%LOCATIONID%", "' + location_Id + '")
                expandStr = expandStr.Replace("%LOCATIONID%", "' + location_Id + '")
                expandStr = expandStr.Replace("%UNIQUEID%", "' + Location_Id + '")
                expandStr = expandStr.Replace("%IMAGEID%", nodeId.Replace("Node_", "Image_") & "_' + Transaction_List_Id + '")
                If nodeId = "" Then
                    expandStr = expandStr.Replace("%NODEROWID%", "' + Location_Id + '")
                Else
                    expandStr = expandStr.Replace("%NODEROWID%", nodeId.Replace("Node_" + pickerId + "_", "") & "_' + Location_Id + '")
                End If
                nodeData.Columns.Add(New DataColumn("NodeId", GetType(String), "'Node_' + Location_Id"))

                nodeData.Columns.Add(New DataColumn("NodeRowId", GetType(String), "'Node_" + pickerId + "_' + Location_Id"))
                nodeData.Columns.Add(New DataColumn("Select", GetType(String), "'<a onclick=""selectLocationPickerNode(' + Location_Id + ');"">Select</a>'"))
                colExpression = "IIF(Children < 1, " & descriptionText & ", " & expandStr & " + " & descriptionText & ")"
            Else
                expandStr = expandStr.Replace("%LOCATIONID%", "0")
                descriptionText = descriptionText.Replace("%LOCATIONID%", "' + location_Id + '")
                expandStr = expandStr.Replace("%NODEROWID%", "Type" & "' + Location_Type_Id + '")
                nodeData.Columns.Add(New DataColumn("NodeRowId", GetType(String), "'Node_" + pickerId + "_Type" & "' + Location_Type_Id"))
                nodeData.Columns.Add(New DataColumn("NodeId", GetType(String), "'Node_" & "Type" & "' + Location_Type_Id"))
                nodeData.Columns.Add(New DataColumn("Select", GetType(String), "'<a onclick=""selectLocationPickerNode(-1);"">All</a>'"))
                colExpression = "IIF(Location_Type_Id Is Null, " & descriptionText & ", " & expandStr & " + " & descriptionText & ")"
            End If


            'Add additional columns
            nodeData.Columns.Add(New DataColumn("Expand", GetType(String), colExpression))

            Return nodeData
        End Function
    End Class
End Namespace