Namespace Controls
	Public Class ReconcilorLocationSelector
		Inherits Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector

		Private _startDate As DateTime?
		Public Property StartDate() As DateTime?
			Get
				Return _startDate
			End Get
			Set(ByVal value As DateTime?)
				_startDate = value
			End Set
		End Property

		Private _startDateElementName As String
		Public Property StartDateElementName() As String
			Get
				Return _startDateElementName
			End Get
			Set(ByVal value As String)
				_startDateElementName = value.Trim()
			End Set
		End Property

		Private _startQuarterElementName As String
		Public Property StartQuarterElementName() As String
			Get
				Return _startQuarterElementName
			End Get
			Set(ByVal value As String)
				_startQuarterElementName = value
			End Set
		End Property

        ' when this property is set to true, locationGroups that apply to the parent location (such as deposits)
        ' will be shown in the location picker
        Public Property ShowLocationGroups As Boolean = False

        Protected Overrides Sub OnInit(ByVal e As EventArgs)
            MyBase.OnInit(e)

            LoadScript.InnerScript = LoadScript.InnerScript.Replace("LoadLocation(", "LoadLocationOverride(")

            If (StartDate.HasValue) Then
                LoadScript.InnerScript = LoadScript.InnerScript.Replace(");", ",'" & StartDate.Value.ToString("yyyy-MM-dd") & "');")

                LoadScript.InnerScript = "reportStartDateElementName = '" & StartDateElementName & "';reportStartQuarterElementName = '" & StartQuarterElementName & "';" & LoadScript.InnerScript
            End If

            Dim showLocationGroupsInput = New Web.UI.HtmlControls.HtmlInputHidden()
            showLocationGroupsInput.ID = "ShowLocationGroups"
            showLocationGroupsInput.Name = "ShowLocationGroups"
            showLocationGroupsInput.Value = ShowLocationGroups.ToString.ToLower
            Controls.Add(showLocationGroupsInput)
        End Sub


    End Class
End Namespace
