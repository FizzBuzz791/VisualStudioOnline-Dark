'Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
'Imports System.Web.UI
'Imports System.Web.UI.WebControls
'Imports Snowden.Common.Web.BaseHtmlControls

'Namespace Controls
'    Public Class FFactorTable
'        Inherits DataGrid

'#Region " Properties "
'        Private _disposed As Boolean
'        Private _dataSource As New DataTable
'        Private _thresholdSource As New DataTable
'        Private _summaryGrid As New DataGrid

'        Public Property SummaryGrid() As DataGrid
'            Get
'                Return _summaryGrid
'            End Get
'            Set(ByVal value As DataGrid)
'                _summaryGrid = value
'            End Set
'        End Property

'        Public Property DataSource() As DataTable
'            Get
'                Return _dataSource
'            End Get
'            Set(ByVal value As DataTable)
'                _dataSource = value
'            End Set
'        End Property

'        Public Property ThresholdSource() As DataTable
'            Get
'                Return _thresholdSource
'            End Get
'            Set(ByVal value As DataTable)
'                _thresholdSource = value
'            End Set
'        End Property
'#End Region


'#Region " Constructor & Destructor "
'        Public Sub New(ByVal fData As DataTable)
'            Me.DataSource = fData
'        End Sub

'        Public Overrides Sub Dispose()
'            Dispose(True)
'            GC.SuppressFinalize(Me)
'        End Sub

'        Public Overloads Sub Dispose(ByVal disposing As Boolean)
'            Try
'                If (Not _disposed) Then
'                    If (disposing) Then
'                        If (Not _dataSource Is Nothing) Then
'                            _dataSource.Dispose()
'                            _dataSource = Nothing
'                        End If

'                        If (Not _summaryGrid Is Nothing) Then
'                            _summaryGrid.Dispose()
'                            _summaryGrid = Nothing
'                        End If
'                    End If

'                    'Clean up unmanaged resources ie: Pointers & Handles				
'                End If

'                _disposed = True
'            Finally
'                MyBase.Dispose()
'            End Try
'        End Sub
'#End Region


'        Public Overrides Sub DataBind()
'            DataBind(True)
'        End Sub

'        Protected Overrides Sub OnInit(ByVal e As System.EventArgs)

'            MyBase.OnInit(e)

'            SetupControls()
'            SetupLayout()

'        End Sub

'        '  Protected Overrides Sub DataBind(ByVal raiseOnDataBinding As Boolean)
'        Private Sub SetupControls()
'            AddHandler SummaryGrid.ItemDataBound, AddressOf SummaryGrid_ItemDataBound

'            SummaryGrid.AutoGenerateColumns = False
'            SummaryGrid.CellPadding = 3
'            SummaryGrid.CellSpacing = 0
'            SummaryGrid.GridLines = GridLines.None

'            SummaryGrid.HeaderStyle.Font.Bold = True
'            SummaryGrid.HeaderStyle.BorderStyle = BorderStyle.Solid
'            SummaryGrid.HeaderStyle.BorderWidth = 1
'            SummaryGrid.HeaderStyle.BorderColor = Drawing.Color.Black
'            SummaryGrid.HeaderStyle.BackColor = Drawing.Color.White
'            SummaryGrid.BorderStyle = BorderStyle.Solid
'            SummaryGrid.BorderWidth = 1
'            SummaryGrid.BorderColor = Drawing.Color.Black

'            Dim boundCol As New BoundColumn()
'            Dim templateCol As New TemplateColumn()

'            boundCol.HeaderText = "Summary"
'            boundCol.DataField = "Description"
'            boundCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Left
'            boundCol.ItemStyle.Font.Bold = True
'            boundCol.ItemStyle.HorizontalAlign = HorizontalAlign.Left
'            SummaryGrid.Columns.Add(boundCol)

'            templateCol = New TemplateColumn()
'            templateCol.HeaderText = "Tonnes"
'            templateCol.ItemStyle.Width = 50
'            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
'            SummaryGrid.Columns.Add(templateCol)

'            templateCol = New TemplateColumn()
'            templateCol.HeaderText = "Fe %"
'            templateCol.ItemStyle.Width = 50
'            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
'            SummaryGrid.Columns.Add(templateCol)

'            templateCol = New TemplateColumn()
'            templateCol.HeaderText = "P %"
'            templateCol.ItemStyle.Width = 50
'            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
'            SummaryGrid.Columns.Add(templateCol)

'            templateCol = New TemplateColumn()
'            templateCol.HeaderText = "SiO2 %"
'            templateCol.ItemStyle.Width = 50
'            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
'            SummaryGrid.Columns.Add(templateCol)

'            templateCol = New TemplateColumn()
'            templateCol.HeaderText = "Al2O3 %"
'            templateCol.ItemStyle.Width = 50
'            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
'            SummaryGrid.Columns.Add(templateCol)

'            templateCol = New TemplateColumn()
'            templateCol.HeaderText = "LOI %"
'            templateCol.ItemStyle.Width = 50
'            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
'            SummaryGrid.Columns.Add(templateCol)

'            SummaryGrid.DataSource = DataSource
'            SummaryGrid.DataBind()
'        End Sub

'        Private Sub SummaryGrid_ItemDataBound(ByVal sender As Object, ByVal e As DataGridItemEventArgs)

'            If ((e.Item.ItemType = ListItemType.Item) Or (e.Item.ItemType = ListItemType.AlternatingItem)) Then
'                Dim fDataRow As DataRow

'                fDataRow = DataSource.Rows(e.Item.ItemIndex)

'                e.Item.Cells(0).Style.Add("border-right", "solid 1px black")

'                e.Item.Cells(1).Controls.Add(GetImage(Convert.ToDouble(DataSource.Rows(e.Item.ItemIndex).Item("Tonnes"))))
'                e.Item.Cells(2).Controls.Add(GetImage(Convert.ToDouble(DataSource.Rows(e.Item.ItemIndex).Item("Fe"))))
'                e.Item.Cells(3).Controls.Add(GetImage(Convert.ToDouble(DataSource.Rows(e.Item.ItemIndex).Item("P"))))
'                e.Item.Cells(4).Controls.Add(GetImage(Convert.ToDouble(DataSource.Rows(e.Item.ItemIndex).Item("SiO2"))))
'                e.Item.Cells(5).Controls.Add(GetImage(Convert.ToDouble(DataSource.Rows(e.Item.ItemIndex).Item("Al2O3"))))
'                e.Item.Cells(6).Controls.Add(GetImage(Convert.ToDouble(DataSource.Rows(e.Item.ItemIndex).Item("LOI"))))

'                If (fDataRow.Item("TagId").ToString.ToLower = "f1factor") Then
'                    e.Item.Cells(0).Style.Add("color", "green")
'                ElseIf (fDataRow.Item("TagId").ToString.ToLower = "f2factor") Then
'                    e.Item.Cells(0).Style.Add("color", "hotpink")
'                ElseIf (fDataRow.Item("TagId").ToString.ToLower = "f3factor") Then
'                    e.Item.Cells(0).Style.Add("color", "blue")
'                End If
'            ElseIf (e.Item.ItemType = ListItemType.Header) Then
'                e.Item.Cells(0).Style.Add("border-right", "solid 1px black")
'                e.Item.Cells(0).Style.Add("border-bottom", "solid 1px black")
'                e.Item.Cells(1).Style.Add("border-bottom", "solid 1px black")
'                e.Item.Cells(2).Style.Add("border-bottom", "solid 1px black")
'                e.Item.Cells(3).Style.Add("border-bottom", "solid 1px black")
'                e.Item.Cells(4).Style.Add("border-bottom", "solid 1px black")
'                e.Item.Cells(5).Style.Add("border-bottom", "solid 1px black")
'                e.Item.Cells(6).Style.Add("border-bottom", "solid 1px black")
'            End If
'        End Sub

'        Private Function GetImage(ByVal value As Double) As Image
'            Dim face As New Image

'            If (value > 1) Then
'                face.ImageUrl = "../images/faceGreen.gif"
'            ElseIf (value > 0 And value <= 1) Then
'                face.ImageUrl = "../images/faceOrange.gif"
'            Else
'                face.ImageUrl = "../images/faceRed.gif"
'            End If

'            face.BorderStyle = BorderStyle.None
'            Return face
'        End Function

'        ' Protected Overrides Sub Render(ByVal writer As System.Web.UI.HtmlTextWriter)
'        'Dim result As String

'        'Dim strWriter As New System.IO.StringWriter()
'        'Dim htmlTextWriter As New System.Web.UI.HtmlTextWriter(strWriter)

'        'htmlTextWriter.RenderBeginTag(HtmlTextWriterTag.Html)
'        'htmlTextWriter.RenderBeginTag(HtmlTextWriterTag.Body)

'        'SummaryGrid.RenderControl(htmlTextWriter)

'        'htmlTextWriter.RenderEndTag()
'        'htmlTextWriter.RenderEndTag()
'        'htmlTextWriter.Flush()

'        'result = strWriter.ToString()
'        'writer.Write(result)
'        ' End Sub
'        '
'        Protected Sub SetupLayout()
'            Controls.Add(SummaryGrid)
'        End Sub
'    End Class
'End Namespace
