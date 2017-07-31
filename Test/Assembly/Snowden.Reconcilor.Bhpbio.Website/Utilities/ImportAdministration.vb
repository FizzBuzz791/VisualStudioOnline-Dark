Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Controls.FilterBoxes.Utilities
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Utilities
    Public Class ImportAdministration
        Inherits Core.Website.Utilities.ImportAdministration

        Private _importsFilterBox As ImportsFilterBox
        Private _dalUtility As SqlDalUtility = Nothing

        Public Property ImportsFilterBox As ImportsFilterBox
            Get
                Return _importsFilterBox
            End Get
            Set
                If (Not value Is Nothing) Then
                    _importsFilterBox = value
                End If
            End Set
        End Property

        Protected Overrides Sub OnPreInit(e As EventArgs)
            MyBase.OnPreInit(e)

            Dim validationFromDate As Date = Nothing
            Dim useMonthLocationFilter = False
            Dim lookbackDate As Date
            Dim lookbackFound = Date.TryParse(_dalUtility.GetSystemSetting("IMPORT_VALIDATION_LOOKBACK_DATE"), lookbackDate)

            If RequestAsString("SelectedMonth") IsNot Nothing Then
                validationFromDate = RequestAsDateTime("SelectedMonth")
                useMonthLocationFilter = True
            ElseIf lookbackFound Then
                validationFromDate = lookbackDate
            Else
                validationFromDate = New Date(Date.Now.Year, Date.Now.Month, 1)
            End If

            'setup filterbox
            ImportsFilterBox = DirectCast(Resources.DependencyFactories.FilterBoxFactory.Create("ImportsFilterBox", Resources), ImportsFilterBox)
            With ImportsFilterBox
                .SetDateFrom(validationFromDate)

                If (Request("LocationId") Is Nothing) Then
                    .SetLocation(1) ' Default to WAIO
                Else
                    .SetLocation(RequestAsInt32("LocationId"))
                End If

                .SetFilter(useMonthLocationFilter)
                .SetDefaultDate(lookbackDate)

                If useMonthLocationFilter Then
                    .SetMonth(validationFromDate)
                Else
                    .SetMonth(New Date(Date.Now.Year, Date.Now.Month, 1))
                End If
            End With
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", ""))

            ImportsFilterBox.SetServerForm(ImportAdminForm)
            ImportsTab.Controls.AddAt(0, ImportsFilterBox)

        End Sub

        Protected Overrides Sub SetupDalObjects()
            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub
    End Class
End Namespace