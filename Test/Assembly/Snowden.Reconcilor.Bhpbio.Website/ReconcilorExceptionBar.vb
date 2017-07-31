Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI

Public Class ReconcilorExceptionBar
    Inherits Core.Website.ReconcilorExceptionBar

#Region " Properties "
    Private _dalSecurityLocation As Reconcilor.Bhpbio.Database.DalBaseObjects.ISecurityLocation
    Private _dalPurge As Reconcilor.Bhpbio.Database.DalBaseObjects.IPurge

    Public Property DalSecurityLocation() As Bhpbio.Database.DalBaseObjects.ISecurityLocation
        Get
            Return _dalSecurityLocation
        End Get
        Set(ByVal value As Bhpbio.Database.DalBaseObjects.ISecurityLocation)
            _dalSecurityLocation = value
        End Set
    End Property


    Public Property DalPurge() As Bhpbio.Database.DalBaseObjects.IPurge
        Get
            Return _dalPurge
        End Get
        Set(ByVal value As Bhpbio.Database.DalBaseObjects.IPurge)
            _dalPurge = value
        End Set
    End Property

#End Region

    Protected Overrides Sub SetupDalObjects()
        If (DalUtility Is Nothing) Then
            DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
        End If

        If (DalHaulage Is Nothing) Then
            DalHaulage = New Bhpbio.Database.SqlDal.SqlDalHaulage(Resources.Connection)
        End If

        If (DalSecurityLocation Is Nothing) Then
            DalSecurityLocation = New Bhpbio.Database.SqlDal.SqlDalSecurityLocation(Resources.Connection)
        End If

        If (DalImportManager Is Nothing) Then
            DalImportManager = New Bhpbio.Database.SqlDal.SqlDalImportManager(Resources.Connection)
        End If

        If (DalPurge Is Nothing) Then
            DalPurge = New Bhpbio.Database.SqlDal.SqlDalPurge(Resources.Connection)
        End If

        MyBase.SetupDalObjects()
    End Sub

    Protected Overrides Function GetHaulageErrorCount() As Int32
        Dim userLocation As Int32
        Dim Dal As Bhpbio.Database.DalBaseObjects.IHaulage _
            = DirectCast(DalHaulage, Bhpbio.Database.DalBaseObjects.IHaulage)

        userLocation = DalSecurityLocation.GetBhpbioUserLocation(Resources.UserSecurity.UserId.Value)

        Return Dal.GetBhpbioHaulageErrorCount(userLocation)
    End Function

    Protected Overrides Function GetDataExceptionCount() As Int32
        Dim userLocation As Int32
        Dim Dal As Bhpbio.Database.DalBaseObjects.IUtility _
            = DirectCast(DalUtility, Bhpbio.Database.DalBaseObjects.IUtility)

        userLocation = DalSecurityLocation.GetBhpbioUserLocation(Resources.UserSecurity.UserId.Value)

        Return Dal.GetBhpbioDataExceptionCount(userLocation)
    End Function

    Protected Overrides Function GetImportsRunningCount() As Integer
        Dim Dal As Bhpbio.Database.DalBaseObjects.IImportManager _
            = DirectCast(DalImportManager, Bhpbio.Database.DalBaseObjects.IImportManager)

        Return Dal.GetImportsRunningQueuedCount()
    End Function

    Protected Overrides Function GetImportErrorCount() As Dictionary(Of String, Int32)
        Dim Dal = DirectCast(DalImportManager, Bhpbio.Database.SqlDal.SqlDalImportManager)
        Dim errors As New Dictionary(Of String, Int32)
        Dim validationFromDate As Date = Nothing

        If Not Date.TryParse(Me.DalUtility.GetSystemSetting("IMPORT_VALIDATION_LOOKBACK_DATE"), validationFromDate) Then
            validationFromDate = New Date(Date.Now.Year, 1, 1)
        End If

        Dim rows = Dal.GetLookbackImportErrorsCount(validationFromDate).AsEnumerable
        errors.Add(ConflictFailures, rows.Sum(Function(r) Convert.ToInt32(r("ConflictCount"))))
        errors.Add(ValidationFailures, rows.Sum(Function(r) Convert.ToInt32(r("ValidateCount"))))
        errors.Add(CriticalErrors, rows.Sum(Function(r) Convert.ToInt32(r("CriticalErrorCount"))))

        Return errors
    End Function
    Protected Overrides Sub SetExceptionText()
        MyBase.SetExceptionText()

        HaulageErrorText = "Haulage Errors"
        DataExceptionText = "Data Exceptions"
        ImportStatusText = "Imports Running/Queued"
        ValidationFailures = "Recent Validation Failures"
    End Sub

    Protected Overrides Sub SetupPageLayout()
        MyBase.SetupPageLayout()

        Dim helpDocumentation As New Tags.HtmlAnchorTag(Request.ApplicationPath & "\Utilities\HelpDocumentation.aspx")
        Dim helpImage As New Tags.HtmlImageTag(Request.ApplicationPath & "\images\Help.gif")
        helpImage.Height = 20

        With helpDocumentation
            .Controls.Add(helpImage)
            .Controls.Add(New LiteralControl(" Help Documentation"))
        End With

        ' find out the latest purge month
        Dim latestPurgeMonth As DateTime? = DalPurge.GetLatestPurgeMonth()

        If (Not latestPurgeMonth Is Nothing) Then
            ' and add a message to the exception bar for it
            Dim purgeMessage As String = String.Format("<b>No live data</b> exists before {0:MMMM yyyy}. ", latestPurgeMonth.Value.AddMonths(1))
            ' replace spaces with the non-breaking space character
            purgeMessage = purgeMessage.Replace(" ", "&nbsp;")
            Dim purgeMessageControl As New LiteralControl(purgeMessage)

            ExceptionDiv.Controls.Add(purgeMessageControl)
        End If

        Me.Resources.ProductConfiguration.Open()
        Dim product As Bcd.ProductConfiguration.Product = Me.Resources.ProductConfiguration.GetProduct()

        Dim versionTag As New Tags.HtmlSpanTag()
        versionTag.Controls.Add(New LiteralControl("<b>Version:</b>&nbsp;"))

        Dim productVersion As String = "development"
        If Not product Is Nothing AndAlso Not product.Version.NullVersion Then
            productVersion = product.Version.ToString()
        End If
        versionTag.Controls.Add(New LiteralControl(productVersion))

        ExceptionDiv.Controls.Add(versionTag)
        ExceptionDiv.Controls.Add(helpDocumentation)
    End Sub
End Class
