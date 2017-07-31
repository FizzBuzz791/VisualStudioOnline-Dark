Imports System.Text
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports System.Data.SqlClient
Imports System.Security.Permissions
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Security.RoleBasedSecurity
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Utilities
    Public Class DefaultShippingTargetSave
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _shippingTargetPeriodId As Integer? = Nothing
        Private _isNonDeletable As Boolean
        Private _locationId As Integer = Nothing
        Private _startDate As Date = Nothing
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
        Private _dalShippingTarget As IShippingTarget
        Private _description As String = Nothing
        Private _defaultProductTypeSize As String = Nothing
        Private _returnTable As ReconcilorTable
        Private _locations As ArrayList = New ArrayList()

        Protected Property ShippingTargetPeriodId() As Integer?
            Get
                Return _shippingTargetPeriodId
            End Get
            Set(ByVal value As Integer?)
                _shippingTargetPeriodId = value
            End Set
        End Property

        Protected Property ReturnTable() As ReconcilorTable
            Get
                Return _returnTable
            End Get
            Set(ByVal value As ReconcilorTable)
                _returnTable = value
            End Set
        End Property

        Protected Property ProductSize() As String
            Get
                Return _defaultProductTypeSize
            End Get
            Set(ByVal value As String)
                _defaultProductTypeSize = value
            End Set
        End Property

        Protected Property DalUtility() As Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Database.DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            ShippingTargetPeriodId = RequestAsInt32("ShippingTargetPeriodId")
            'Description = RequestAsString("Description")
            'ProductSize = RequestAsString("productTypeProductSize")
            'CodeBox = RequestAsString("CodeBox")

            'Dim hubsDataTable As DataTable = DalUtility.GetBhpbioLocationChildrenNameWithOverride(1, DateTime.Now, DateTime.Now)
            'For Each row As DataRow In hubsDataTable.Rows
            '    Dim idd As String = row("Location_Id").ToString()
            '    If Not RequestAsString("hub_" + idd) Is Nothing Then
            '        _locations.Add(idd)
            '    End If
            'Next
        End Sub

        Protected Overrides Function ValidateData() As String
            Dim errorMessage As New StringBuilder(MyBase.ValidateData())

            If Request("ShippingTargetPeriodId") = "" Then 'New record
                ShippingTargetPeriodId = 0
            End If

			If (RequestAsInt32("ProductTypePicker") <= 0) Then
				errorMessage.Append("\nA product has not been selected.")
			End If

            Dim grades = DalUtility.GetGradeList(1)
            For Each dr As DataRow In grades.Rows
                Dim upper As Double = 0
                Dim target As Double = 0
                Dim lower As Double = 0

                If Not Request("U_Attribute_" + dr("grade_id").ToString()) = "" Then
                    upper = Double.Parse(Request("U_Attribute_" + dr("grade_id").ToString()))
                End If

                If Not Request("T_Attribute_" + dr("grade_id").ToString()) = "" Then
                    target = Double.Parse(Request("T_Attribute_" + dr("grade_id").ToString()))
                End If

                If Not Request("L_Attribute_" + dr("grade_id").ToString()) = "" Then
                    lower = Double.Parse(Request("L_Attribute_" + dr("grade_id").ToString()))
                End If

				If (upper < 0 OrElse upper > 100) Then
					errorMessage.Append(String.Format("\nThe Upper Control value for '{0}' must be between 0 and 100.", dr("Grade_Name")))
				End If

				If (target < 0 OrElse target > 100) Then
					errorMessage.Append(String.Format("\nThe Target value for '{0}' must be between 0 and 100.", dr("Grade_Name")))
				End If

				If (lower < 0 OrElse lower > 100) Then
					errorMessage.Append(String.Format("\nThe Lower Control value for '{0}' must be between 0 and 100.", dr("Grade_Name")))
				End If
				
				If (target > upper AndAlso Not IsCellNA(dr("Grade_Name").ToString(), "Target") AndAlso Not IsCellNA(dr("Grade_Name").ToString(), "Upper Control")) Then
					errorMessage.Append(String.Format("\nThe Target value for '{0}' must be less than or equal to the Upper Control value.", dr("Grade_Name")))
				End If
				
				If (lower > target AndAlso Not IsCellNA(dr("Grade_Name").ToString(), "Target") AndAlso Not IsCellNA(dr("Grade_Name").ToString(), "Lower Control")) Then
					errorMessage.Append(String.Format("\nThe Lower Control value for '{0}' must be less than or equal to the Target value.", dr("Grade_Name")))
				End If
            Next

            'Insert Oversize and Undersize
            Dim uOversize As Double = 0
            Dim uUndersize As Double = 0
            Dim tOversize As Double = 0
            Dim tUndersize As Double = 0

            'Upper Control
            If Not Request("U_Oversize") = "" Then
                uOversize = Double.Parse(Request("U_Oversize"))
            End If
            If Not Request("U_Undersize") = "" Then
                uUndersize = Double.Parse(Request("U_Undersize"))
            End If
            'Target
            If Not Request("T_Oversize") = "" Then
                tOversize = Double.Parse(Request("T_Oversize"))
            End If
            If Not Request("T_Undersize") = "" Then
                tUndersize = Double.Parse(Request("T_Undersize"))
            End If

			If (uOversize < 0 OrElse uOversize > 100) Then
				errorMessage.Append("\nThe Upper Control value for 'Oversize' must be between 0 and 100.")
			End If

			If (tOversize < 0 OrElse tOversize > 100) Then
				errorMessage.Append("\nThe Target value for 'Oversize' must be between 0 and 100.")
			End If
				
			If (tOversize > uOversize) Then
				errorMessage.Append("\nThe Target value for 'Oversize' must be less than or equal to the Upper Control value.")
			End If

			If (uUndersize < 0 OrElse uUndersize > 100) Then
				errorMessage.Append("\nThe Upper Control value for 'Undersize' must be between 0 and 100.")
			End If

			If (tUndersize < 0 OrElse tUndersize > 100) Then
				errorMessage.Append("\nThe Target value for 'Undersize' must be between 0 and 100.")
			End If
				
			If (tUndersize > uUndersize) Then
				errorMessage.Append("\nThe Target value for 'Undersize' must be less than or equal to the Upper Control value.")
			End If

            Return errorMessage.ToString
        End Function

		Private Function IsCellNA(ByVal gradeName As String, ByVal valueType As String) As Boolean
            Return gradeName.ToUpper = "LOI" AndAlso valueType.ToUpper <> "TARGET"
        End Function
        Protected Property DalShippingTarget() As IShippingTarget
            Get
                Return _dalShippingTarget
            End Get
            Set(ByVal value As IShippingTarget)
                _dalShippingTarget = value
            End Set
        End Property

		Private Sub Save()

            Dim month As Date = NullValues.DateTime
            Dim producttype As Integer = 0

            'If new record , get ShippingTargetPeriodId
            If DateTime.TryParse("01-" + Request("MonthPickerMonthPart").ToString() + "-" + Request("MonthPickerYearPart").ToString(), month) Then
                month = Date.Parse("01-" + Request("MonthPickerMonthPart").ToString() + "-" + Request("MonthPickerYearPart").ToString())
            End If

            If Not Request("producttypepicker") = "" Then
                producttype = Int32.Parse(Request("producttypepicker"))
            End If

            If ShippingTargetPeriodId <= 0 Then
                ShippingTargetPeriodId = DalShippingTarget.AddBhpbioShippingTarget(producttype, month, Resources.UserSecurity.UserId.Value)
            Else
                DalShippingTarget.UpdateBhpbioShippingTarget(producttype, ShippingTargetPeriodId.Value, month, Resources.UserSecurity.UserId.Value)
            End If

            'Dinamically go through Grades to get values to insert
            Dim grades = DalUtility.GetGradeList(1)
            For Each dr As DataRow In grades.Rows
                Dim upper As Double = 0
                Dim target As Double = 0
                Dim lower As Double = 0

                If Not Request("U_Attribute_" + dr("grade_id").ToString()) = "" Then
                    upper = Double.Parse(Request("U_Attribute_" + dr("grade_id").ToString()))
                End If

                If Not Request("T_Attribute_" + dr("grade_id").ToString()) = "" Then
                    target = Double.Parse(Request("T_Attribute_" + dr("grade_id").ToString()))
                End If

                If Not Request("L_Attribute_" + dr("grade_id").ToString()) = "" Then
                    lower = Double.Parse(Request("L_Attribute_" + dr("grade_id").ToString()))
                End If

                DalShippingTarget.AddOrUpdateBhpbioShippingTargetValue(ShippingTargetPeriodId.Value, Int32.Parse(dr("Grade_id").ToString()), upper, target, lower)

            Next
            'Insert Oversize and Undersize
            Dim u_oversize As Double = 0
            Dim u_undersize As Double = 0
            Dim t_oversize As Double = 0
            Dim t_undersize As Double = 0

            'Upper Control
            If Not Request("U_Oversize") = "" Then
                u_oversize = Double.Parse(Request("U_Oversize"))
            End If
            If Not Request("U_Undersize") = "" Then
                u_undersize = Double.Parse(Request("U_Undersize"))
            End If
            'Target
            If Not Request("T_Oversize") = "" Then
                t_oversize = Double.Parse(Request("T_Oversize"))
            End If
            If Not Request("T_Undersize") = "" Then
                t_undersize = Double.Parse(Request("T_Undersize"))
            End If

            DalShippingTarget.AddOrUpdateBhpbioShippingTargetValue(ShippingTargetPeriodId.Value, -1, u_oversize, t_oversize, 0)
            DalShippingTarget.AddOrUpdateBhpbioShippingTargetValue(ShippingTargetPeriodId.Value, -2, u_undersize, t_undersize, 0)

        End Sub
        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                If ShippingTargetPeriodId Is Nothing Then
                    EventLogDescription = "Save new Shipping Target record"
                Else
                    EventLogDescription = String.Format("Save update to Shipping Target record ID: {0}", ShippingTargetPeriodId)
                End If

                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then
                    Try
                        Save()
                    Catch ex As Exception
                        JavaScriptAlert(ex.Message)
                    End Try

                    JavaScriptAlert("Shipping Target saved successfully.", String.Empty, "GetDefaultshippingTargetList();")
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert(String.Format("Error while saving Shipping Target: {0}", ex.Message))
            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If
            If _dalShippingTarget Is Nothing Then
                _dalShippingTarget = New SqlDalShippingTarget(Resources.Connection)
            End If
        End Sub
    End Class
End Namespace
