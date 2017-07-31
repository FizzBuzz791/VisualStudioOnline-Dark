Namespace Calc

    Public Interface IAllMaterialTypesCalculation

        ''' <summary>
        ''' Contorls whether to fetch high grade only or all material types. Used for density calculations where all material types are included.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Property IncludeAllMaterialTypes() As Boolean

    End Interface

End Namespace
