Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Web.BaseHtmlControls.Tags.HtmlScriptTag
Imports System.Web.UI
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Database.DataAccessBaseObjects


Namespace ReconcilorControls.Inputs
    Public Class LocationPicker
        Inherits Common.Web.BaseHtmlControls.GenericControlBase

#Region "Properties"
        Private _disposed As Boolean
        Private _image As New Tags.HtmlImageTag
        Private _locationPopUpDiv As New Tags.HtmlDivTag("")
        Private _inputBox As New InputTags.InputHidden()
        Private _displayText As New LiteralControl()
        Private _id As String
        Private _layoutTable As New Tags.HtmlTableTag
        Private _treeTable As New Tags.HtmlTableTag
        Private _locationTreePopUpDiv As New Tags.HtmlDivTag
        Private _locationTreeStaticDiv As New Tags.HtmlDivTag
        Private _popupTable As Boolean = True
        Private _width As Double = DoNotSetValues.Double
        Private _locationJavaScript As String
        Private _showLocationTypes As Boolean = True
        Private _showImageNodes As Boolean = True
        Private _autoSelectNode As Boolean = True
        Private _lowestLocationTypeDescription As String = String.Empty

        Protected ReadOnly Property DisplayText() As LiteralControl
            Get
                Return _displayText
            End Get
        End Property

        Public Property LowestLocationTypeDescription() As String
            Get
                Return _lowestLocationTypeDescription
            End Get
            Set(ByVal value As String)
                _lowestLocationTypeDescription = value
            End Set
        End Property

        Protected ReadOnly Property InputBox() As InputTags.InputHidden
            Get
                Return _inputBox
            End Get
        End Property

        Protected ReadOnly Property Image() As Tags.HtmlImageTag
            Get
                Return _image
            End Get
        End Property

        Protected ReadOnly Property LocationPopUpDiv() As Tags.HtmlDivTag
            Get
                Return _locationPopUpDiv
            End Get
        End Property

        <System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId:="PopUp")> Protected ReadOnly Property LocationTreePopUpDiv() As Tags.HtmlDivTag
            Get
                Return _locationTreePopUpDiv
            End Get
        End Property

        Protected ReadOnly Property LocationTreeStaticDiv() As Tags.HtmlDivTag
            Get
                Return _locationTreeStaticDiv
            End Get
        End Property

        Protected ReadOnly Property LayoutTable() As Tags.HtmlTableTag
            Get
                Return _layoutTable
            End Get
        End Property

        Protected ReadOnly Property TreeTable() As Tags.HtmlTableTag
            Get
                Return _treeTable
            End Get
        End Property

        Public Property PopupTable() As Boolean
            Get
                Return _popupTable
            End Get
            Set(ByVal value As Boolean)
                _popupTable = value
            End Set
        End Property

        Public Property Width() As Double
            Get
                Return _width
            End Get
            Set(ByVal value As Double)
                _width = value
            End Set
        End Property

        Public Property LocationJavaScript() As String
            Get
                Return _locationJavaScript
            End Get
            Set(ByVal value As String)
                _locationJavaScript = value
            End Set
        End Property

        Public Property ShowLocationTypes() As Boolean
            Get
                Return _showLocationTypes
            End Get
            Set(ByVal value As Boolean)
                _showLocationTypes = value
            End Set
        End Property

        Public Property ShowImageNodes() As Boolean
            Get
                Return _showImageNodes
            End Get
            Set(ByVal value As Boolean)
                _showImageNodes = value
            End Set
        End Property

        Public Property AutoSelectNode() As Boolean
            Get
                Return _autoSelectNode
            End Get
            Set(ByVal value As Boolean)
                _autoSelectNode = value
            End Set
        End Property
#End Region

#Region " Constructor & Destructor "
        Public Sub New()
        End Sub

        Public Sub New(ByVal id As String)
            _id = id
            _width = 150
        End Sub

        Public NotOverridable Overrides Sub Dispose()
            Dispose(True)
            GC.SuppressFinalize(Me)
        End Sub

        Protected Overridable Overloads Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then

                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles				
                End If

                _disposed = True
            Finally
                MyBase.Dispose()
            End Try
        End Sub
#End Region

        Protected Overrides Sub OnInit(ByVal e As System.EventArgs)
            MyBase.OnInit(e)

            SetupLayout()
            SetupControls()
            CompleteLayout()
        End Sub

        Protected Overridable Sub SetupLayout()
            Dim js As String
            'Dim script As New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
            ' Tags.HtmlScriptTag.ScriptLanguage.JavaScript, "", "new locationFilter(this, '../images/')")
            'Controls.Add(script)

            'Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.HtmlScriptTag.ScriptLanguage.JavaScript, "../js/LocationPicker.js", ""))

            js = String.Format("locationFilter_LoadStatic('{0}','{1}','{2}','{3}','{4}','{5}','{6}');", _id, _
             LocationJavaScript, Width, ShowLocationTypes, ShowImageNodes, AutoSelectNode, LowestLocationTypeDescription)

            If PopupTable = True Then
                Controls.Add(LocationPopUpDiv)
                Controls.Add(LayoutTable)
                Controls.Add(InputBox)

                With LayoutTable
                    .CellPadding = 3
                    .AddCellInNewRow().Controls.Add(Image)
                    .AddCell().Controls.Add(DisplayText)
                End With
            Else
                Controls.Add(LocationTreeStaticDiv)
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, js))
            End If
        End Sub

        Protected Overridable Sub SetupControls()
            With DisplayText
                .Text = ""
                .ID = _id & "text"
            End With

            With InputBox()
                .ID = _id
            End With

            With LocationPopUpDiv
                .ID = _id & "div"
                .Controls.Add(TreeTable)
                .StyleClass = "locationpickertree"
            End With

            With TreeTable
                .AddCellInNewRow().Controls.Add(LocationTreePopUpDiv)
                .BorderStyle = WebControls.BorderStyle.Solid
                .BorderWidth = 1
                .BorderColor = System.Drawing.Color.Black
                .BackColor = Drawing.Color.White
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Left
                .CellPadding = 0
                .CellSpacing = 0
            End With

            LocationTreePopUpDiv.ID = _id & "tree"
            LocationTreeStaticDiv.ID = _id & "tree"

            With Image
                .ID = _id & "image"
                .Source = "../images/btn_loct_up.gif"
                .Attributes.Add("onclick", "locationFilter_Click(this, '" & _id & "');")
                .Attributes.Add("onmouseover", "locationFilter_MouseOver(this);")
                .Attributes.Add("onmouseout", "locationFilter_MouseOut(this);")
                .Attributes.Add("imageUp", "btn_loct_up.gif")
                .Attributes.Add("imageOver", "btn_loct_over.gif")
                .Attributes.Add("imageDown", "btn_loct_down.gif")
            End With

            'Controls.Add(New Tags.HtmlScriptTag(ScriptType.TextJavaScript, "new locationPicker('" & Image.ID & "');"))
        End Sub

        Protected Overridable Sub CompleteLayout()
        End Sub

    End Class
End Namespace
