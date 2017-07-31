Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports System.Data.SqlClient
Imports System.Text.RegularExpressions

Namespace Utilities
    Public Class DefaultDepositSave
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _dalUtility As Database.DalBaseObjects.IUtility

#Region "Properties"

        Protected Property BhpbioDefaultDepositId As Integer? = Nothing

        Public ReadOnly Property Name As String
            Get
                Return Request("Name")
            End Get
        End Property


        Protected Property DalUtility As Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set
                _dalUtility = Value
            End Set
        End Property

#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
        End Sub

        Protected Overrides Function ValidateData() As String
            Dim returnValue As String = MyBase.ValidateData()

            If (String.IsNullOrEmpty(Name)) Then
                If (returnValue.Length > 0) Then
                    returnValue += "\n"
                End If
                returnValue += " - Name of Deposit must be specified."
            End If

            Dim parentLocationId = Convert.ToInt32(Request("ParentLocationDepositId"))
            Dim depositList = DalUtility.GetBhpbioDepositList(parentLocationId)
            Dim originalName = Request("OriginalName")
            If (Not String.IsNullOrEmpty(originalName) AndAlso Not originalName.Equals(Name)) Or String.IsNullOrEmpty(originalName) Then ' No point in checking when it hasn't changed (or is new)
                If depositList.Rows.Cast(Of DataRow)().Any(Function(row) (row.ItemArray(0).Equals(Name))) Then
                    If (returnValue.Length > 0) Then
                        returnValue += "\n"
                    End If
                    returnValue += " - Deposit Name already exists."
                ElseIf Not Regex.IsMatch(Name, "^[A-Za-z0-9 ]+$") Then
                    If (returnValue.Length > 0) Then
                        returnValue += "\n"
                    End If
                    returnValue += " - Deposit Name must contain only numbers, letters and spaces."
                End If
            End If

            If Not Request.Form.AllKeys.Any(Function(key) (Request(key).Trim = "on")) Then
                If (returnValue.Length > 0) Then
                    returnValue += "\n"
                End If
                returnValue += " - Please select at least one (1) Pit."
            End If

            Return returnValue
        End Function

        Protected Overrides Sub ProcessData()
            MyBase.ProcessData()

            DalUtility.DataAccess.BeginTransaction()

            Dim parentLocationId = Convert.ToInt32(Request("ParentLocationDepositId"))

            Dim depositId As Integer?
            If Not String.IsNullOrEmpty(Request("BhpbioDefaultDepositId")) Then
                depositId = Convert.ToInt32(Request("BhpbioDefaultDepositId"))
            End If

            Try
                Dim pitLists = From r In Request.Form.AllKeys
                               Where r.StartsWith("pit_") AndAlso (Request(r).Trim = "on")
                               Select r.Replace("pit_", "").Trim

                Dim pitListString = pitLists.ToArray()
                DalUtility.AddOrUpdateBhpbioLocationGroup(depositId, parentLocationId, Name, String.Join(",", pitListString))

                DalUtility.DataAccess.CommitTransaction()
            Catch ex As Exception
                Try
                    DalUtility.DataAccess.RollbackTransaction()
                Catch
                    Throw
                End Try
                Throw
            End Try
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then
                    If BhpbioDefaultDepositId Is Nothing Then
                        EventLogDescription = "Save new deposit"
                    Else
                        EventLogDescription = String.Format("Save update to deposit record ID: {0}", BhpbioDefaultDepositId)
                    End If

                    ProcessData()
                    JavaScriptAlert("Deposit saved successfully.", String.Empty, "GetDepositsForSite();")
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issue(s):")
                End If
            Catch ex As SqlException
                JavaScriptAlert(String.Format("Error while saving Deposit: {0}", ex.Message))
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