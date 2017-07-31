﻿Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment
Imports System.Web.UI

Namespace Approval
    Public Class DefaultApproval
        Inherits WebpageTemplates.ApprovalTemplate

#Region " Properties "
        Private _approvalForm As New Tags.HtmlFormTag
        Private _disposed As Boolean
        Private _dalHaulage As Core.Database.DalBaseObjects.IHaulage
        Private _headerDiv As New Tags.HtmlDivTag()
        Private _filterBox As ReconcilorControls.FilterBoxes.Approval.ApprovalFilter
        Private _digblockTerm As String = Core.WebDevelopment.ReconcilorFunctions.GetSiteTerminology("Digblock")
        Private _locationId As Integer
        Private _selectedMonth As Date

        Protected ReadOnly Property HeaderDiv() As Tags.HtmlDivTag
            Get
                Return _headerDiv
            End Get
        End Property

        Protected ReadOnly Property ApprovalForm() As Tags.HtmlFormTag
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

        Protected ReadOnly Property FilterBox() As ReconcilorControls.FilterBoxes.Approval.ApprovalFilter
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
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("APPROVAL_DIGBLOCK"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If (DalHaulage Is Nothing) Then
                DalHaulage = New Core.Database.SqlDal.SqlDalHaulage(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            With ApprovalForm
                .ID = "approvalForm"
                .OnSubmit = "return GetApprovalDigblockList();"
            End With

            With HeaderDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl(_digblockTerm & " Validation"))
            End With

            With HelpBox
                .Container.Style.Add("display", "none")
                .Container.ID = "ApprovalHelpBox"
                .Content.ID = "ApprovalHelpBoxContent"
                .Title = "Approval Restrictions"
                .Visible = False
            End With

            With FilterBox
                .LocationSelector.LocationId = _locationId
                .MonthFilter.SelectedDate = _selectedMonth
            End With
        End Sub

        Protected Overrides Sub SetupPageLayout()
            HasCalendarControl = True

            MyBase.SetupPageLayout()

            With ApprovalForm
                .Controls.Add(HeaderDiv)
                .Controls.Add(FilterBox)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("itemList"))
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(ApprovalForm)
            End With
        End Sub

        Protected Overrides Sub OnPreInit(ByVal e As System.EventArgs)
            MyBase.OnPreInit(e)

            'create the filter box
            _filterBox = CType(Resources.DependencyFactories.FilterBoxFactory.Create("Approval", Resources),  _
                ReconcilorControls.FilterBoxes.Approval.ApprovalFilter)
            _filterBox.SetServerForm(ApprovalForm)
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If (Request("LocationId") IsNot Nothing) Then
                _locationId = RequestAsInt32("LocationId")
            End If

            If (Request("SelectedMonth") IsNot Nothing) Then
                _selectedMonth = RequestAsDateTime("SelectedMonth")
            End If
        End Sub
    End Class
End Namespace
