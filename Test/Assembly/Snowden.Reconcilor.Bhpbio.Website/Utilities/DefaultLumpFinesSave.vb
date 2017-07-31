Imports System.Text
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports System.Data.SqlClient

Namespace Utilities
    Public Class DefaultLumpFinesSave
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _bhpbioDefaultLumpFinesId As Integer? = Nothing
        Private _isNonDeletable As Boolean
        Private _locationId As Integer = Nothing
        Private _startDate As Date = Nothing
        Private _lumpPercentage As Decimal
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility

        Protected Property BhpbioDefaultLumpFinesId() As Integer?
            Get
                Return _bhpbioDefaultLumpFinesId
            End Get
            Set(ByVal value As Integer?)
                _bhpbioDefaultLumpFinesId = value
            End Set
        End Property

        Protected Property IsNonDeletable() As Boolean
            Get
                Return _isNonDeletable
            End Get
            Set(ByVal value As Boolean)
                _isNonDeletable = value
            End Set
        End Property

        Protected Property LocationId() As Integer
            Get
                Return _locationId
            End Get
            Set(ByVal value As Integer)
                _locationId = value
            End Set
        End Property

        Protected Property StartDate() As Date
            Get
                Return _startDate
            End Get
            Set(ByVal value As Date)
                _startDate = value
            End Set
        End Property

        Protected Property LumpPercentage() As Decimal
            Get
                Return _lumpPercentage
            End Get
            Set(ByVal value As Decimal)
                _lumpPercentage = value
            End Set
        End Property

        Protected Property DalUtility() As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property

        Protected Overrides Function ValidateData() As String
            Dim errorMessage As New StringBuilder(MyBase.ValidateData())

            If Not Request("BhpbioDefaultLumpFinesId") Is Nothing Then
                Dim val As Integer
                If Integer.TryParse(Request("BhpbioDefaultLumpFinesId"), val) Then
                    BhpbioDefaultLumpFinesId = val
                End If
            End If

            If Not Request("IsNonDeletable") Is Nothing Then
                If Not Boolean.TryParse(Request("IsNonDeletable"), IsNonDeletable) Then
                    errorMessage.Append("\nIsNonDeletable form parameter was not provided.")
                End If
            End If

            If IsNonDeletable Then
                'this implies that neither location nor start date can change: set them to arbitrary values such that the stored procedure can accept them
                LocationId = 0
                StartDate = DateTime.Now
            Else
                If Request("Location") Is Nothing Then
                    errorMessage.Append("\n - Location parameter is missing.")
                ElseIf Not Integer.TryParse(Request("Location").ToString, LocationId) Then
                    errorMessage.Append("\n - Location ID is not valid.")
                End If

                If LocationId < 1 Then
                    errorMessage.Append("\n - Location must be selected.")
                End If

                If Request("LumpPercentStartDateText") Is Nothing Then
                    errorMessage.Append("\n - Start Date must be provided.")
                ElseIf Not Date.TryParse(Request("LumpPercentStartDateText"), StartDate) Then
                    errorMessage.Append("\n - Start Date is invalid.")
                End If
            End If

            If Request("LumpPercentage") Is Nothing Then
                errorMessage.Append("\n - Lump Percentage must be provided.")
            ElseIf Not Decimal.TryParse(Request("LumpPercentage"), LumpPercentage) Then
                errorMessage.Append("\n - Lump Percentage value is not decimal.")
            End If

            If LumpPercentage < 0 Or LumpPercentage > 100 Then
                errorMessage.Append("\n - Lump Percentage must be between 0 and 100.")
            End If

            '''''''''''''''''''''''''''''''''''''''''''''''''''''''
            ' Convert percentage into ratio for saving to database
            '''''''''''''''''''''''''''''''''''''''''''''''''''''''
            LumpPercentage = LumpPercentage / 100

            If errorMessage.Length = 0 Then
                Dim validationData As DataTable = DalUtility.AddOrUpdateBhpbioLumpFinesRecord(BhpbioDefaultLumpFinesId, LocationId, StartDate, LumpPercentage, True)
                If Not Convert.ToBoolean(validationData.Rows(0).Item("Success")) Then
                    errorMessage.Append(validationData.Rows(0).Item("ErrorMessage").ToString)
                End If
            End If

            Return errorMessage.ToString
        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                If BhpbioDefaultLumpFinesId Is Nothing Then
                    EventLogDescription = "Save new Lump Percentage record"
                Else
                    EventLogDescription = String.Format("Save update to Lump Percentage record ID: {0}", BhpbioDefaultLumpFinesId)
                End If

                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then
                    DalUtility.AddOrUpdateBhpbioLumpFinesRecord(BhpbioDefaultLumpFinesId, LocationId, StartDate, LumpPercentage, False)
                    JavaScriptAlert("Lump Percentage saved successfully.", String.Empty, "GetDefaultLumpFinesList();")
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert(String.Format("Error while saving Lump Percentage: {0}", ex.Message))
            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub
    End Class
End Namespace
