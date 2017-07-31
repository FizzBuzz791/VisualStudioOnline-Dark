Imports Snowden.Reconcilor.Bhpbio.WebDevelopment
Imports System.Web.UI
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Web.BaseHtmlControls.Tags

Namespace Approval
    Public Class ApprovalData
        Inherits WebpageTemplates.ApprovalTemplate

#Region " Properties "
        Private _approvalForm As New HtmlFormTag
        Private _disposed As Boolean
        Private _dalHaulage As Core.Database.DalBaseObjects.IHaulage
        Private _headerDiv As New HtmlDivTag()
        Private _filterBox As ReconcilorControls.FilterBoxes.Approval.ApprovalF1F2F3Filter

        Protected ReadOnly Property HeaderDiv() As HtmlDivTag
            Get
                Return _headerDiv
            End Get
        End Property

        Protected ReadOnly Property ApprovalForm() As HtmlFormTag
            Get
                Return _approvalForm
            End Get
        End Property

        Public Property DalHaulage() As Core.Database.DalBaseObjects.IHaulage
            Get
                Return _dalHaulage
            End Get
            Set(ByVal value As Core.Database.DalBaseObjects.IHaulage)
                _dalHaulage = value
            End Set
        End Property

        Protected ReadOnly Property FilterBox() As ReconcilorControls.FilterBoxes.Approval.ApprovalF1F2F3Filter
            Get
                Return _filterBox
            End Get
        End Property
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _approvalForm Is Nothing) Then
                            _approvalForm.Dispose()
                            _approvalForm = Nothing
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

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("APPROVAL_FREPORT"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            With ApprovalForm
                .ID = "approvalForm"
                '    .OnSubmit = "return GetApprovalDataList();"
            End With

            With FilterBox
                .ShowLimit = False
            End With

            With HeaderDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("F1F2F3 Validation & Approval"))
            End With
        End Sub

        Protected Overrides Sub SetupPageLayout()
            HasCalendarControl = True

            MyBase.SetupPageLayout()

            Dim spacer As New LiteralControl() With {
                .Text = "&nbsp;&nbsp;"
            }

            With ApprovalForm
                .Controls.Add(HeaderDiv)
                .Controls.Add(New HtmlDivTag(Nothing, "", "tabs_spacer"))
                .Controls.Add(New HtmlDivTag("itemList"))
                .Controls.Add(New HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(ApprovalForm)
            End With
        End Sub

        Protected Overrides Sub OnPreInit(ByVal e As EventArgs)
            MyBase.OnPreInit(e)

            'create the filter box
            _filterBox = CType(Resources.DependencyFactories.FilterBoxFactory.Create("ApprovalF1F2F3", Resources),
                ReconcilorControls.FilterBoxes.Approval.ApprovalF1F2F3Filter)
            _filterBox.SetServerForm(ApprovalForm)
        End Sub
    End Class
End Namespace