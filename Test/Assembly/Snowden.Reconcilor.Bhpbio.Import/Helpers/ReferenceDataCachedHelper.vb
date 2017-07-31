Imports Snowden.Common.Database.DataAccessBaseObjects
Imports DataHelper = Snowden.Common.Database.DataHelper

Public NotInheritable Class ReferenceDataCachedHelper
    Private Shared _blockModelDal As Core.Database.DalBaseObjects.IBlockModel
    Private Shared _utilityDal As Bhpbio.Database.DalBaseObjects.IUtility

    'grade data
    Private Shared _gradeLookup As DataTable

    'block model data
    Private Shared _blockModelLookup As DataTable

    'material lookup data
    Private Shared _materialLookup As Dictionary(Of String, DataTable)

    'location type lookup data
    Private Shared _locationTypeLookup As DataTable

    ' the prefixes of grades that are considered optional within the grade control model
    Private Shared _optionalGradeControlModelGradePrefixes As String() = {"H2O", "Ultrafines"}

    Public Shared Property BlockModelDal() As Core.Database.DalBaseObjects.IBlockModel
        Get
            Return _blockModelDal
        End Get
        Set(ByVal value As Core.Database.DalBaseObjects.IBlockModel)
            _blockModelDal = value
        End Set
    End Property

    Public Shared Property UtilityDal() As Bhpbio.Database.DalBaseObjects.IUtility
        Get
            Return _utilityDal
        End Get
        Set(ByVal value As Bhpbio.Database.DalBaseObjects.IUtility)
            _utilityDal = value
        End Set
    End Property

    Private Sub New()
        'prevent instantiation
        'i.e.  YOU CAN'T TOUCH THIS. Hammer time.
    End Sub

    Private Shared Sub PrepareGradeLookup()
        If _utilityDal Is Nothing Then
            Throw New InvalidOperationException("The Utility Dal Is Not active.")
        End If

        If _gradeLookup Is Nothing Then
            _gradeLookup = _utilityDal.GetGradeList(NullValues.Int16)
        End If
    End Sub

    Private Shared Sub PrepareBlockModelLookup()
        If _blockModelDal Is Nothing Then
            Throw New InvalidOperationException("The Block Model Dal Is Not active.")
        End If

        If _blockModelLookup Is Nothing Then
            _blockModelLookup = _blockModelDal.GetBlockModelList(NullValues.Int32, NullValues.String, NullValues.Int16)
        End If
    End Sub

    Private Shared Sub PrepareMaterialLookup(ByVal materialCategoryId As String)
        If _utilityDal Is Nothing Then
            Throw New InvalidOperationException("The Utility Dal Is Not active.")
        End If

        If _materialLookup Is Nothing Then
            _materialLookup = New Dictionary(Of String, DataTable)
        End If

        If Not _materialLookup.ContainsKey(materialCategoryId) Then
            _materialLookup.Add(materialCategoryId, _
             _utilityDal.GetBhpbioMaterialLookup(materialCategoryId, NullValues.Int16))
        End If
    End Sub

    Private Shared Sub PrepareLocationTypeLookup()
        If _utilityDal Is Nothing Then
            Throw New InvalidOperationException("The Utility Dal Is Not active.")
        End If

        If _locationTypeLookup Is Nothing Then
            _locationTypeLookup = _utilityDal.GetLocationTypeList(DoNotSetValues.Byte)
        End If
    End Sub

    Public Shared Function GetGradeId(ByVal gradeName As String) As Nullable(Of Int16)
        Dim grades As DataRow()
        Dim result As Nullable(Of Int16)

        PrepareGradeLookup()

        grades = _gradeLookup.Select("Grade_Name = '" & gradeName & "'")

    If grades.Length = 0 Then
            result = Nothing
        Else
            result = Convert.ToInt16(grades(0)("Grade_Id"))
        End If

        Return result
    End Function

    ' Test whether a grade name relates to a Grade that is considered mandatory for the Grade Control Model
    Private Shared Function IsGradeMandatoryForGradeControlModel(ByVal gradeName As String) As Boolean

        Dim isMandatory As Boolean = True

        ' A better mechanism for identifying mandatory grades could be implemented here..
        ' up until now all grades have been mandatory
        For Each prefix As String In _optionalGradeControlModelGradePrefixes
            ' The grade is not mandatory if it's name starts with a prefix identified as optional
            If gradeName.StartsWith(prefix) Then
                isMandatory = False
            End If
        Next

        Return isMandatory

    End Function

    Public Shared Function GetGradeList(Optional ByVal gradeControlModelMandatoryGradesOnly As Boolean = False) As Generic.IList(Of String)
        Dim gradeList As Generic.List(Of String)
        Dim grade As DataRow
        Dim gradeName As String

        PrepareGradeLookup()

        gradeList = New Generic.List(Of String)

        For Each grade In _gradeLookup.Rows()
            gradeName = DirectCast(grade("Grade_Name"), String)
            If (Not gradeControlModelMandatoryGradesOnly) OrElse IsGradeMandatoryForGradeControlModel(gradeName) Then
                    gradeList.Add(gradeName)
            End If
        Next

        Return gradeList
    End Function

    Public Shared Function GetBlockModelId(ByVal name As String) As Nullable(Of Int32)
        Dim blockModels As DataRow()
        Dim result As Nullable(Of Int32)

        PrepareBlockModelLookup()

        blockModels = _blockModelLookup.Select("Name = '" & name & "'")

        If blockModels.Length = 0 Then
            result = Nothing
        Else
            result = DirectCast(blockModels(0)("Block_Model_Id"), Int32)
        End If

        Return result
    End Function

    Public Shared Function GetMaterialTypeId(ByVal materialCategoryId As String, _
     ByVal abbreviation As String, ByVal locationId As Int32?) As Int32?
        Dim materials As DataRow()
        Dim result As Int32?

        PrepareMaterialLookup(materialCategoryId)

        If locationId.HasValue Then
            materials = _materialLookup(materialCategoryId).Select("Abbreviation = '" & abbreviation & "'" & _
             " AND LocationId = " & locationId.Value.ToString)
        Else
            materials = _materialLookup(materialCategoryId).Select("Abbreviation = '" & abbreviation & "'")
        End If

        If materials.Length = 0 Then
            result = Nothing
        Else
            result = DirectCast(materials(0)("MaterialTypeId"), Int32)
        End If

        Return result
    End Function

    Public Shared Function GetLocationTypeId(ByVal locationTypeName As String, _
     ByVal parentLocationTypeId As Byte?) As Byte?
        Dim lookupRows As DataRow()
        Dim result As Byte?

        PrepareLocationTypeLookup()

        'look up the location type id based on the location type name provided
        If parentLocationTypeId.HasValue Then
            lookupRows = _locationTypeLookup.Select("Description = '" & locationTypeName & "'" & _
                                                    " AND Parent_Location_Type_Id = " & parentLocationTypeId.Value.ToString)
        Else
            lookupRows = _locationTypeLookup.Select("Description = '" & locationTypeName & "'")
        End If

        If lookupRows.Length = 0 Then
            result = Nothing
        Else
            result = DirectCast(lookupRows(0)("Location_Type_Id"), Byte)
        End If

        Return result
    End Function
End Class
