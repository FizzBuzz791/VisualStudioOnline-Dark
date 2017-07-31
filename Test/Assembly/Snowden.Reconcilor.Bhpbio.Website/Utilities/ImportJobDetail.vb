Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Common.Web.BaseHtmlControls.WebpageControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags

Namespace Utilities
	Class ImportJobDetail
		Inherits Core.Website.Utilities.ImportJobDetail

		Private _disposed As Boolean

		Public Property DalUtility As IUtility

		Public Property LocationCodeList As List(Of ImportLocationCode)

		Protected Overrides Sub SetupDalObjects()
			If (DalUtility Is Nothing) Then
				DalUtility = New SqlDalUtility(Resources.Connection)
			End If

			MyBase.SetupDalObjects()
		End Sub

		Protected Overrides Function CreateJobParametersTabPage() As TabPage
			Dim tabPage = MyBase.CreateJobParametersTabPage()

			For Each tag In From control As Object In tabPage.Controls Select tag1 = TryCast(control, HtmlFormTag) Where (Not tag1 Is Nothing AndAlso tag1.ID = "importJobForm")
				tag.OnSubmit = "return BhpbioSaveImportJobDetails();"
				Exit For
			Next

			Return tabPage
		End Function

		Protected Overrides Function CreateJobDetailTabPage() As TabPage
			Dim importLocationCodes = DalUtility.GetBhpbioImportLocationCodeList(Nothing, Nothing)
			LocationCodeList = New List(Of ImportLocationCode)

			For Each row As DataRow In importLocationCodes.Rows
				LocationCodeList.Add(New ImportLocationCode() With {
									 .ImportParameterId = Convert.ToInt32(row("ImportParameterId")),
									 .LocationId = Convert.ToInt32(row("LocationId")),
									 .LocationCode = row("LocationCode").ToString(),
									 .Name = row("Name").ToString(),
									 .Description = row("Description").ToString()
									 })
			Next

			Return MyBase.CreateJobDetailTabPage()
		End Function

		Protected Overrides Function CreateJobParameterInputControl(ByRef parameter As DataRow) As WebControl
			' We want to use this method to provide the user with a location dropdown or date picker when appropriate
			'  - if the parameter name is DateFrom or DateTo then return a date picker
			'  - if the ImportParamterId is NOT in the BhpbioImportLocationCode then just return the parent method
			'  - if it is in that table, then get the list of codes + location names, and return a ReconcilorControls.InputTags.SelectBox
			'    with those locations
			'
			Dim importParameterId = Convert.ToInt32(parameter("ImportParameterID"))
			Dim parameterName = parameter("ParameterName").ToString()

            If (parameterName = "DateFrom" OrElse parameterName = "DateTo") Then
                ' date paramter so add what we need for the calendar control to the page
                Dim dateTimeValue As Date

                If (Not Date.TryParse(parameter("ParameterValue").ToString, dateTimeValue)) Then
                    dateTimeValue = DatePicker.NoDate
                End If

                Dim dateControl = New DatePicker(parameterName, "importJobForm", dateTimeValue)
                dateControl.ElementId = parameterName & "Container"

                Response.Write(dateControl.InitialiseScript)
                Response.Write(dateControl.ControlScript)

                Dim controlContainer = New WebControl(HtmlTextWriterTag.Span)

                controlContainer.ID = parameterName & "Container"
                controlContainer.Attributes.Add("data-tag", importParameterId.ToString())

                Return controlContainer
            ElseIf (LocationCodeList.Any(Function(c) c.ImportParameterId = importParameterId)) Then
                ' this is a location picker, so create a select box

                Dim selectedLocationCode = parameter("ParameterValue").ToString()
                Dim items = LocationCodeList.
                    Where(Function(c) c.ImportParameterId = importParameterId).
                    Select(Function(c) New ListItem(String.Format("{0} ({1})", c.Description, c.LocationCode), c.LocationCode)).
                    ToArray()

                Dim selectBox = New SelectBox()
                selectBox.Items.AddRange(items)

                ' the select box doesn't contain the selected item - maybe the import was automatically queued with
                ' something that doesn't exist - this means that the default first item in the select list will be
                ' selected when the user looks at the list. We don't want this, because it is confusing, so lets
                ' add an extra item to the end of the list
                If Not String.IsNullOrEmpty(selectedLocationCode) AndAlso Not items.Select(Function(i) i.Value).Contains(selectedLocationCode) Then
                    Dim desc = String.Format("{0} ({1})", "Unknown", selectedLocationCode)
                    selectBox.Items.Add(New ListItem(desc, selectedLocationCode))
                End If

                selectBox.SelectedValue = selectedLocationCode
                Return selectBox
            Else
                ' not a date picker or a location, so just do whatever the default from the parent class is
                Return MyBase.CreateJobParameterInputControl(parameter)
            End If
        End Function

		Protected Overrides Sub Dispose(ByVal disposing As Boolean)
			Try
				If (Not _disposed) Then
					If (disposing) Then
						If (Not DalUtility Is Nothing) Then
							DalUtility.Dispose()
							DalUtility = Nothing
						End If
					End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

				_disposed = True
			Finally
				MyBase.Dispose(disposing)
			End Try
		End Sub

		Public Class ImportLocationCode
			Public Property ImportParameterId As Int32
			Public Property LocationId As Int32
			Public Property LocationCode As String
			Public Property Name As String
			Public Property Description As String
		End Class
	End Class
End Namespace