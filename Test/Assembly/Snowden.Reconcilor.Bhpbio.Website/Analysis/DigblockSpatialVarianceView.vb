Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports System.Web.UI

Namespace Analysis
    Public Class DigblockSpatialVarianceView
        Inherits Core.Website.Analysis.DigblockSpatialVarianceView

#Region "Properties"
        Private _fullLayoutTable As New Tags.HtmlTableTag
        Private _locationBox As New GroupBox("Location Selection")
        Private _locationPicker As New LocationPicker("LocationPicker")
        Private _varianceSetupBox As New GroupBox("Spatial Comparison Variance Setup")
        Private _varianceSetupDiv As New Tags.HtmlDivTag("varianceSetup")
        Private _disposed As Boolean

        Protected ReadOnly Property FullLayoutTable() As Tags.HtmlTableTag
            Get
                Return _fullLayoutTable
            End Get
        End Property

        Protected ReadOnly Property LocationBox() As GroupBox
            Get
                Return _locationBox
            End Get
        End Property

        Protected ReadOnly Property LocationPicker() As LocationPicker
            Get
                Return _locationPicker
            End Get
        End Property

        Protected ReadOnly Property VarianceSetupBox() As GroupBox
            Get
                Return _varianceSetupBox
            End Get
        End Property

        Protected ReadOnly Property VarianceSetupDiv() As Tags.HtmlDivTag
            Get
                Return _varianceSetupDiv
            End Get
        End Property
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        'Clean up managed Resources ie: Objects
                        If (Not _fullLayoutTable Is Nothing) Then
                            _fullLayoutTable.Dispose()
                            _fullLayoutTable = Nothing
                        End If

                        If (Not _locationBox Is Nothing) Then
                            _locationBox.Dispose()
                            _locationBox = Nothing
                        End If

                        If (Not _locationPicker Is Nothing) Then
                            _locationPicker.Dispose()
                            _locationPicker = Nothing
                        End If

                        If (Not _varianceSetupBox Is Nothing) Then
                            _varianceSetupBox.Dispose()
                            _varianceSetupBox = Nothing
                        End If

                        If (Not _varianceSetupDiv Is Nothing) Then
                            _varianceSetupDiv.Dispose()
                            _varianceSetupDiv = Nothing
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


        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/LocationPicker.js", ""))
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioAnalysis.js", ""))

            With FullLayoutTable
                .CellSpacing = 2
                .CellPadding = 2
                .AddCellInNewRow()
                .CurrentCell.Controls.Add(LocationBox)
                .CurrentCell.VerticalAlign = Web.UI.WebControls.VerticalAlign.Top
                .AddCell().Controls.Add(VarianceSetupBox)
                .CurrentCell.VerticalAlign = Web.UI.WebControls.VerticalAlign.Top
            End With

            With VarianceSetupDiv
                .Controls.Add(New LiteralControl("Select a location to view the Variance Setup."))
            End With

            With LocationPicker
                .PopupTable = False
                .LocationJavaScript = "getVarianceDetails"
                .Width = 180
                .ShowLocationTypes = False

            End With

            VarianceSetupBox.Width = 380

            ' Remove the controls before and add the new layout table.
            ReconcilorContent.ContainerContent.Controls.Clear()
            ReconcilorContent.ContainerContent.Controls.Add(FullLayoutTable)

        End Sub


        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            LocationBox.Controls.Add(LocationPicker)

            VarianceSetupBox.Controls.Add(VarianceSetupDiv)
        End Sub


    End Class
End Namespace
