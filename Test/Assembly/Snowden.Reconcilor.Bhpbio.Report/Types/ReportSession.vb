Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Types
    Public Enum GeometTypeSelection
        NA
        AsShipped
        AsDropped
    End Enum

    Public Enum ProductSizeFilterValue
        NONE
        LUMP
        FINES
        TOTAL
    End Enum

    Public Class ReportSession
        Implements IDisposable

#Region "Properties"
        Private _disposed As Boolean
        Private _connection As IDataAccessConnection
        Private _dalReport As SqlDalReport
        Private _dalApproval As SqlDalApproval
        Private _dalUtility As SqlDalUtility
        Private _dalShippingTarget As SqlDalShippingTarget
        Private _dalSecurityLocation As SqlDalSecurityLocation
        Private _dalBhpbioLocationGroup As SqlDalBhpbioLocationGroup
        Private _dalBlockModel As Reconcilor.Core.Database.SqlDal.SqlDalBlockModel
        Private _requestParameter As DataRequest
        Private _approvalInformation As Boolean
        Private _useHistorical As Boolean
        Private _noData As Boolean

        Private _includeProductSizeBreakdown As Boolean
        Private _productSizeFilter As ProductSizeFilterValue = ProductSizeFilterValue.NONE

        Private _productTypes As List(Of ProductType) = Nothing
        Private _selectedProductType As ProductType = Nothing

        Private _context As ReportContext = ReportContext.Standard
        Private _dalConnectionText As String
        Private _liveDataContexts As HashSet(Of ReportContext)
        Private _approvedDataContexts As HashSet(Of ReportContext)
        Private _reportBreakdown As ReportBreakdown?
        Private _userSecurity As Snowden.Common.Security.RoleBasedSecurity.IUserSecurity
        Private _allowActualMinedVisible As Boolean = False
        Private _explicitlyIncludeExtendedH2OModelCalculations As Boolean = False
        Private _optionalCalculationTypesToInclude As New List(Of Calc.CalcType)
        Private _locationTypes As Dictionary(Of Integer, String) = Nothing

        ''' <summary>
        ''' if this is true then the session should try calculate the geomet split data for the 
        ''' table if possible, if this is false it doesn't mean that no geomet data will be added
        ''' - this is just a hint
        ''' </summary>
        Public Property IncludeGeometData() As Boolean = False


        ''' <summary>
        ''' If the calculation set encounters errors on one of the sub threads when generating data, the errors will usually
        ''' be swallowed. If this is set to true, the exceptions will be rethrown when the calculation result threads rejoin 
        ''' the main thread
        ''' </summary>
        Public Property RethrowCalculationSetErrors As Boolean = False


        ''' <summary>
        ''' when this property is set to true, an exception will be thrown inside the DAL method to help
        ''' with testing the thread exception catch and rethrow
        ''' </summary>
        Public Property ThrowTestExceptionInDAL As Boolean = False


        ReadOnly Property LocationTypes() As Dictionary(Of Integer, String)
            Get
                If _locationTypes Is Nothing Then
                    _locationTypes = New Dictionary(Of Integer, String) From {
                        {1, "Company"},
                        {2, "Hub"},
                        {3, "Site"},
                        {4, "Pit"},
                        {5, "Bench"},
                        {6, "Blast"},
                        {7, "Block"}
                    }
                End If

                Return _locationTypes
            End Get
        End Property

        ' when setting the prodct type code we want to set a bunch of other properties as well
        ' so that the report is filtered properly
        Property ProductTypeCode() As String
            Get
                If SelectedProductType Is Nothing Then Return Nothing
                Return SelectedProductType.ProductTypeCode
            End Get

            Set(ByVal value As String)
                If value Is Nothing Then
                    SelectedProductType = Nothing
                    Return
                End If

                Dim productType = ProductTypes.FirstOrDefault(Function(p) p.ProductTypeCode = value)
                If productType Is Nothing Then Throw New Exception(String.Format("ProductType with code '{0}' could not be found", value))
                SelectedProductType = productType
            End Set


        End Property

        Property ProductTypeId() As Integer
            Get
                If SelectedProductType Is Nothing Then Return -1
                Return SelectedProductType.ProductTypeID
            End Get

            Set(ByVal value As Integer)
                If value < 0 Then
                    SelectedProductType = Nothing
                    Return
                End If

                Dim productType = ProductTypes.FirstOrDefault(Function(p) p.ProductTypeID = value)
                If productType Is Nothing Then Throw New Exception(String.Format("ProductType with id '{0}' could not be found", value))
                SelectedProductType = productType
            End Set
        End Property

        Property SelectedProductType() As ProductType
            Get
                Return _selectedProductType
            End Get
            Private Set(value As ProductType)
                _selectedProductType = value

                If _selectedProductType IsNot Nothing Then
                    ProductSizeFilterString = _selectedProductType.ProductSize

                    ' we can only set the location_id if the request parameter has been set up already - this might not be
                    ' the case, as it gets set relatively late. When it is created we will check the SelectedProductType
                    ' - if there is one selected then we set the product type code again to reset the location id
                    If RequestParameter IsNot Nothing Then
                        ' this is a hack for the initial development, we assume there is only one location_id, 
                        ' even though that doesn't have to be true
                        RequestParameter.LocationId = _selectedProductType.LocationId
                    End If
                End If
            End Set

        End Property

        ' this contains the list of valid property types. The list is populated the first time
        ' it is accessed by though a DAL method. The number of productTypes is always going to 
        ' be pretty small, so we just get them all at once, instead of getting them by ID later on
        '
        ' the list of LocationIds for each ProductType is also contained in the ProductType object
        '
        ' Not sure that it is best to actually store this here directly on the report session, 
        ' but I couldn't think of a better place for it.
        '
        ReadOnly Property ProductTypes As List(Of ProductType)
            Get
                If DalUtility Is Nothing Then Throw New Exception("Cannot get ProductTypes without DalUtility")

                If _productTypes Is Nothing Then
                    Dim table = DalUtility.GetBhpbioProductTypesWithLocationIds()
                    _productTypes = ProductType.FromDataTable(table)
                End If

                Return _productTypes
            End Get
        End Property

        Private _locationGroups As List(Of LocationGroup) = Nothing
        Private _selectedLocationGroup As LocationGroup = Nothing

        Public ReadOnly Property LocationGroups As List(Of LocationGroup)
            Get
                If _locationGroups Is Nothing Then
                    Dim table = DalUtility.GetBhpbioLocationGroupsWithLocationIds()
                    _locationGroups = LocationGroup.FromDataTable(table)
                End If

                Return _locationGroups
            End Get
        End Property

        Public ReadOnly Property SelectedLocationGroup As LocationGroup
            Get
                Return _selectedLocationGroup
            End Get
        End Property

        Public Property LocationGroupId As Integer
            Get
                If _selectedLocationGroup Is Nothing Then
                    Return -1
                Else
                    Return _selectedLocationGroup.LocationGroupId
                End If
            End Get

            Set(value As Integer)
                _selectedLocationGroup = LocationGroups.FirstOrDefault(Function(g) g.LocationGroupId = value)

                If _selectedLocationGroup Is Nothing Then
                    Throw New Exception("Invalid LocationGroupId (" + value.ToString + ")")
                End If
            End Set
        End Property


        Property Context() As ReportContext
            Get
                Return _context
            End Get
            Set(ByVal value As ReportContext)
                _context = value
            End Set
        End Property

        Property DalApproval() As SqlDalApproval
            Get
                Return _dalApproval
            End Get
            Set(ByVal value As SqlDalApproval)
                _dalApproval = value
            End Set
        End Property

        ''' <summary>
        ''' Explicitly include the extended H2O model calculations (ie the AsDropped, AsShipped variants)
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property ExplicitlyIncludeExtendedH2OModelCalculations() As Boolean
            Get
                Return _explicitlyIncludeExtendedH2OModelCalculations
            End Get
            Set(ByVal value As Boolean)
                _explicitlyIncludeExtendedH2OModelCalculations = value
            End Set
        End Property

        Public Property IncludeAsShippedModelsInHubSet As Boolean = False

        ''' <summary>
        ''' A list of optional calculation types to be include (where otherwise they would not ordinarily be included)
        ''' </summary>
        ''' <returns>The list containing optional calc types to include</returns>
        Public ReadOnly Property OptionalCalculationTypesToInclude() As List(Of Calc.CalcType)
            Get
                Return _optionalCalculationTypesToInclude
            End Get
        End Property

        ''' <summary>
        ''' The connection text (string) that was used to instantiate DAL instances
        ''' </summary>
        ''' <value>a connection string</value>
        ''' <returns>The connection string used to instantiate DAL instances</returns>
        Friend Property DalConnectionText() As String
            Get
                Return _dalConnectionText
            End Get
            Set(ByVal value As String)
                _dalConnectionText = value
            End Set
        End Property

        ''' <summary>
        ''' Gets a SqlDalReport instance used to retrieve report data
        ''' </summary>
        ''' <value>A SqlDalReportInstance</value>
        ''' <returns>A SqlDalReportInstance</returns>
        ''' <remarks>This property will return the instance owned by this session, unless there is a DalReport instance available in a current ReportThreadContext in which case the Thread specific instance will be returned.  
        ''' This is needed to work around thread-safety issue with SqlDalReport and is needed because multiple threads are now used to retrieve data more efficiently</remarks>
        Property DalReport() As SqlDalReport
            Get
                ' If there is a thread specific DalReport then use it... 
                If Not ReportThreadContext.Current Is Nothing AndAlso Not ReportThreadContext.Current.DalReport Is Nothing Then
                    Return ReportThreadContext.Current.DalReport
                Else
                    ' otherwise use the one attached to this instance
                    Return _dalReport
                End If
            End Get
            Set(ByVal value As SqlDalReport)
                _dalReport = value
            End Set
        End Property

        Property DalUtility() As SqlDalUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As SqlDalUtility)
                _dalUtility = value
            End Set
        End Property

        Property DalSecurityLocation() As SqlDalSecurityLocation
            Get
                Return _dalSecurityLocation
            End Get
            Set(ByVal value As SqlDalSecurityLocation)
                _dalSecurityLocation = value
            End Set
        End Property

        Property DalBhpbioLocationGroup() As SqlDalBhpbioLocationGroup
            Get
                Return _dalBhpbioLocationGroup
            End Get
            Set(ByVal value As SqlDalBhpbioLocationGroup)
                _dalBhpbioLocationGroup = value
            End Set
        End Property

        Property DalBlockModel() As Reconcilor.Core.Database.SqlDal.SqlDalBlockModel
            Get
                Return _dalBlockModel
            End Get
            Set(ByVal value As Reconcilor.Core.Database.SqlDal.SqlDalBlockModel)
                _dalBlockModel = value
            End Set
        End Property

        Property DalShippingTarget() As Reconcilor.Bhpbio.Database.SqlDal.SqlDalShippingTarget
            Get
                Return _dalShippingTarget
            End Get
            Set(ByVal value As Reconcilor.Bhpbio.Database.SqlDal.SqlDalShippingTarget)
                _dalShippingTarget = value
            End Set
        End Property

        Public Property RequestParameter() As DataRequest
            Get
                Return _requestParameter
            End Get
            Set(ByVal value As DataRequest)
                _requestParameter = value
            End Set
        End Property

        Public Property ApprovalInformation() As Boolean
            Get
                Return _approvalInformation
            End Get
            Set(ByVal value As Boolean)
                _approvalInformation = value
            End Set
        End Property

        Public Property UseHistorical() As Boolean
            Get
                Return _useHistorical
            End Get
            Set(ByVal value As Boolean)
                _useHistorical = value
            End Set
        End Property

        Public Property AllowActualMinedVisible() As Boolean
            Get
                Return _allowActualMinedVisible
            End Get
            Set(ByVal value As Boolean)
                _allowActualMinedVisible = value
            End Set
        End Property

        Public Property NoData() As Boolean
            Get
                Return _noData
            End Get
            Set(ByVal value As Boolean)
                _noData = value
            End Set
        End Property

        Public Property IncludeProductSizeBreakdown() As Boolean
            Get
                Return _includeProductSizeBreakdown
            End Get
            Set(ByVal value As Boolean)
                _includeProductSizeBreakdown = value
            End Set
        End Property

        Public Property ProductSizeFilter() As ProductSizeFilterValue
            Get
                Return _productSizeFilter
            End Get

            Set(ByVal value As ProductSizeFilterValue)
                _productSizeFilter = value

                ' when setting this value, we also want to change the include L/F flag - its no
                ' good to filter by Lump if that data is not getting returned.
                '
                ' If the user changes back to TOTAL, we could also turn the flag back off, but
                ' I think that would be a bit unexpected, so we won't change it in this case
                If _productSizeFilter = ProductSizeFilterValue.LUMP Or _productSizeFilter = ProductSizeFilterValue.FINES Then
                    Me.IncludeProductSizeBreakdown = True
                End If
            End Set
        End Property

        ' the actual product size filter value is stored in the ProductSizeFilter enum
        ' but since the rest of the application expects strings, we use this property to
        ' convert to and from the backing value
        Public Property ProductSizeFilterString() As String
            Get
                Return Me.ProductSizeFilter.ToString.ToUpper
            End Get

            Set(ByVal value As String)
                If String.IsNullOrEmpty(value) Then
                    _productSizeFilter = ProductSizeFilterValue.NONE
                    Return
                End If

                Select Case value.ToUpper
                    Case "LUMP" : Me.ProductSizeFilter = ProductSizeFilterValue.LUMP
                    Case "FINES" : Me.ProductSizeFilter = ProductSizeFilterValue.FINES
                    Case "TOTAL" : Me.ProductSizeFilter = ProductSizeFilterValue.TOTAL
                    Case Else : Throw New Exception(String.Format("Cannot convert string '{0}' to ProductSizeFilterValue", value))
                End Select
            End Set
        End Property

        ' we have this in a separate property as well as in the requestparamters so that it
        ' can be passed down easily from the webservice, even when quering mulitple locations 
        ' with mulitple sets of request parameters
        Public Property DateBreakdown() As Types.ReportBreakdown?
            Get
                Return _reportBreakdown
            End Get
            Set(ByVal value As Types.ReportBreakdown?)
                _reportBreakdown = value
            End Set
        End Property

        ' When the report session is being called from within the website (and not actually through reporting services)
        ' we might want to have access to the user security interface. This is used, for example, on the F1F2F3 approval
        ' pages. Any calculations that use this should check to make sure that it is not null before using it, as when
        ' the reports are actually called through the webservice by SSRS, it is not possible to get a security context
        ' like this (AFAIK!)
        Public Property UserSecurity() As Snowden.Common.Security.RoleBasedSecurity.IUserSecurity
            Get
                Return _userSecurity
            End Get
            Set(ByVal value As Snowden.Common.Security.RoleBasedSecurity.IUserSecurity)
                _userSecurity = value
            End Set
        End Property

        Public ReadOnly Property GeometReportingEnabled() As Boolean
            Get
                Dim setting = Me.DalUtility.GetSystemSetting("GEOMET_REPORTING_ENABLED")

                If String.IsNullOrEmpty(setting) Then
                    Return False
                ElseIf setting = "1" Or setting.ToLower = "true" Then
                    Return True
                Else
                    Return False
                End If
            End Get
        End Property

        ' This should be set when the report session is created, by the Server.MapPath method, so we can access it 
        ' down in the DAL, where we don't have access to the Server.* methods
        Public Property FileSystemRoot As String = Nothing
#End Region

#Region "Session Level Data"

        Private _cacheBlockModel As New Dictionary(Of GeometTypeSelection, Cache.BlockModel)
        Private _cacheActualHubPostCrusherStockpileDelta As Cache.ActualHubPostCrusherStockpileDelta
        Private _cacheActualSitePostCrusherStockpileDelta As Cache.ActualSitePostCrusherStockpileDelta
        Private _cacheActualExpitToStockpile As Cache.ActualExpitToStockpile
        Private _cacheActualDirectFeed As Cache.ActualDirectFeed
        Private _cacheActualMined As Cache.ActualMined
        Private _cacheActualMineProduction As Cache.ActualMineProduction
        Private _cacheActualStockpileToCrusher As Cache.ActualStockpileToCrusher
        Private _cacheActualOreForRail As Cache.OreForRail
        Private _cacheActualBeneProduct As Cache.ActualBeneProduct
        Private _cachePortBlendedAdjustment As Cache.PortBlendedAdjustment
        Private _cachePortOreShipped As Cache.PortOreShipped
        Private _cachePortStockpileDelta As Cache.PortStockpileDelta
        Private _cacheHistorical As Cache.Historical
        Private _approvedData As Collections.Generic.Dictionary(Of Date, DataSet)
        Private _systemStartDate As DateTime? = Nothing
        Private _historicalCalculationStartDate As DateTime? = Nothing
        Private _reportMaterialList As IDictionary(Of Int32, String)
        Private _lumpFinesCutoverDate As DateTime?
        Private _hubReportSetExcludedFactors As New HashSet(Of String)
        Private _includeModelDataForInactiveLocations As Boolean
        Private _ignoreLumpFinesCutover As Boolean = False
        Private _forwardModelFactorCalculation As Boolean = False
        Private _overrideModelDataLocationTypeBreakdown As String = Nothing

        ''' <summary>
        ''' Flag used to control whether model data is loaded for inactive locations or not
        ''' </summary>
        ''' <returns>True if model data should be returned, falst otherwise</returns>
        ''' <remarks>This is useful for the reporting system</remarks>
        Public Property IncludeModelDataForInactiveLocations() As Boolean
            Get
                Return _includeModelDataForInactiveLocations
            End Get
            Set(ByVal value As Boolean)
                _includeModelDataForInactiveLocations = value
            End Set
        End Property

        ''' <summary>
        ''' Flag used to indicate that the model calculations are to be based on remaining rather than depleted material
        ''' </summary>
        ''' <returns>True if model data should be returned based on remaining material, falst otherwise</returns>
        Public Property ForwardModelFactorCalculation() As Boolean
            Get
                Return _forwardModelFactorCalculation
            End Get
            Set(ByVal value As Boolean)
                _forwardModelFactorCalculation = value
            End Set
        End Property

        ''' <summary>
        ''' Indicates an override location type for the retrieval of model data
        ''' </summary>
        Public Property OverrideModelDataLocationTypeBreakdown() As String
            Get
                Return _overrideModelDataLocationTypeBreakdown
            End Get
            Set(ByVal value As String)
                _overrideModelDataLocationTypeBreakdown = value
            End Set
        End Property

        ''' <summary>
        ''' If True then the Lump/Fines data will always be returned, regardless of the cutover date
        ''' </summary>
        Public Property IgnoreLumpFinesCutover() As Boolean
            Get
                Return _ignoreLumpFinesCutover
            End Get
            Set(ByVal value As Boolean)
                _ignoreLumpFinesCutover = value
            End Set
        End Property

        Public ReadOnly Property ShouldIncludeLiveData() As Boolean
            Get
                Return _liveDataContexts.Contains(_context)
            End Get
        End Property

        Public ReadOnly Property ShouldIncludeApprovedData() As Boolean
            Get
                Return _approvedDataContexts.Contains(_context)
            End Get
        End Property

        Public ReadOnly Property GetReportMaterialList() As IDictionary(Of Int32, String)
            Get
                If _reportMaterialList Is Nothing Then
                    _reportMaterialList = Data.MaterialType.GetReportMaterialList(DalUtility)
                End If
                Return _reportMaterialList
            End Get
        End Property

        Public ReadOnly Property GetSystemStartDate() As DateTime
            Get
                Dim startDate As DateTime
                If Not _systemStartDate.HasValue Then
                    If DateTime.TryParse(DalUtility.GetSystemSetting("SYSTEM_START_DATE").ToString, startDate) Then
                        _systemStartDate = startDate
                    End If
                End If
                Return _systemStartDate.Value
            End Get
        End Property

        Public ReadOnly Property GetLumpFinesCutoverDate() As DateTime
            Get
                If Not _lumpFinesCutoverDate.HasValue Then
                    Dim lumpFinesCutoverDate As DateTime
                    If DateTime.TryParse(DalUtility.GetSystemSetting("LUMP_FINES_CUTOVER_DATE").ToString, lumpFinesCutoverDate) Then
                        _lumpFinesCutoverDate = lumpFinesCutoverDate
                    End If
                End If
                Return _lumpFinesCutoverDate.Value
            End Get
        End Property

        'why isn't this being used??  oh, dear... i think i know...
        'Public ReadOnly Property GetHistoricalCalculationStartDate() As DateTime
        '    Get
        '        Dim startDate As DateTime
        '        If Not _historicalCalculationStartDate.HasValue Then
        '            If DateTime.TryParse(DalUtility.GetSystemSetting("HISTORICAL_START_DATE").ToString, startDate) Then
        '                _historicalCalculationStartDate = startDate
        '            End If
        '        End If
        '        Return _historicalCalculationStartDate.Value
        '    End Get
        'End Property

        Public ReadOnly Property CreateApprovedData(ByVal month As DateTime) As DataSet
            Get
                If _approvedData Is Nothing Then
                    _approvedData = New Generic.Dictionary(Of Date, DataSet)
                End If

                ' the approved data cache needs to be able to hold multiple months worth of approval
                ' data, but it all gets cleared once the report session is closed off
                If Not _approvedData.ContainsKey(month.Date) Then
                    _approvedData(month.Date) = DalApproval.GetBhpbioApprovalData(month)
                End If

                Return _approvedData(month.Date)
            End Get
        End Property

        Public Function GetCacheBlockModel() As Cache.DataCache
            Return GetCacheBlockModel(GeometTypeSelection.AsDropped)
        End Function


        Public Function GetCacheBlockModel(geometType As GeometTypeSelection) As Cache.DataCache
            If _cacheBlockModel Is Nothing Then
                _cacheBlockModel = New Dictionary(Of GeometTypeSelection, Cache.BlockModel)
            End If

            If Not _cacheBlockModel.ContainsKey(geometType) Then
                _cacheBlockModel(geometType) = New Cache.BlockModel(Me, geometType)
            End If

            Dim cacheItem = _cacheBlockModel(geometType)
            cacheItem.RequestParameter = RequestParameter
            Return cacheItem
        End Function

        Public ReadOnly Property GetCacheActualHubPostCrusherStockpileDelta() As Cache.DataCache
            Get
                If _cacheActualHubPostCrusherStockpileDelta Is Nothing Then
                    _cacheActualHubPostCrusherStockpileDelta = New Cache.ActualHubPostCrusherStockpileDelta(Me)
                End If
                _cacheActualHubPostCrusherStockpileDelta.RequestParameter = RequestParameter
                Return _cacheActualHubPostCrusherStockpileDelta
            End Get
        End Property


        Public ReadOnly Property GetCacheActualSitePostCrusherStockpileDelta() As Cache.DataCache
            Get
                If _cacheActualSitePostCrusherStockpileDelta Is Nothing Then
                    _cacheActualSitePostCrusherStockpileDelta = New Cache.ActualSitePostCrusherStockpileDelta(Me)
                End If
                _cacheActualSitePostCrusherStockpileDelta.RequestParameter = RequestParameter
                Return _cacheActualSitePostCrusherStockpileDelta
            End Get
        End Property

        Public ReadOnly Property GetCacheActualDirectFeed() As Cache.DataCache
            Get
                If _cacheActualDirectFeed Is Nothing Then
                    _cacheActualDirectFeed = New Cache.ActualDirectFeed(Me)
                End If
                _cacheActualDirectFeed.RequestParameter = RequestParameter
                Return _cacheActualDirectFeed
            End Get
        End Property

        Public ReadOnly Property GetCacheActualExpitToStockpile() As Cache.DataCache
            Get
                If _cacheActualExpitToStockpile Is Nothing Then
                    _cacheActualExpitToStockpile = New Cache.ActualExpitToStockpile(Me)
                End If
                _cacheActualExpitToStockpile.RequestParameter = RequestParameter
                Return _cacheActualExpitToStockpile
            End Get
        End Property

        Public ReadOnly Property GetCacheActualMineProduction() As Cache.DataCache
            Get
                If _cacheActualMineProduction Is Nothing Then
                    _cacheActualMineProduction = New Cache.ActualMineProduction(Me)
                End If
                _cacheActualMineProduction.RequestParameter = RequestParameter
                Return _cacheActualMineProduction
            End Get
        End Property


        Public ReadOnly Property GetCacheActualMined() As Cache.DataCache
            Get
                If _cacheActualMined Is Nothing Then
                    _cacheActualMined = New Cache.ActualMined(Me)
                End If

                _cacheActualMined.RequestParameter = RequestParameter
                Return _cacheActualMined
            End Get
        End Property

        Public ReadOnly Property GetCacheActualStockpileToCrusher() As Cache.DataCache
            Get
                If _cacheActualStockpileToCrusher Is Nothing Then
                    _cacheActualStockpileToCrusher = New Cache.ActualStockpileToCrusher(Me)
                End If
                _cacheActualStockpileToCrusher.RequestParameter = RequestParameter
                Return _cacheActualStockpileToCrusher
            End Get
        End Property

        Public ReadOnly Property GetCacheOreForRail() As Cache.DataCache
            Get
                If _cacheActualOreForRail Is Nothing Then
                    _cacheActualOreForRail = New Cache.OreForRail(Me)
                End If
                _cacheActualOreForRail.RequestParameter = RequestParameter
                Return _cacheActualOreForRail
            End Get
        End Property

        Public ReadOnly Property GetCacheActualBeneProduct() As Cache.DataCache
            Get
                If _cacheActualBeneProduct Is Nothing Then
                    _cacheActualBeneProduct = New Cache.ActualBeneProduct(Me)
                End If
                _cacheActualBeneProduct.RequestParameter = RequestParameter
                Return _cacheActualBeneProduct
            End Get
        End Property

        Public ReadOnly Property GetCachePortBlendedAdjustment() As Cache.DataCache
            Get
                If _cachePortBlendedAdjustment Is Nothing Then
                    _cachePortBlendedAdjustment = New Cache.PortBlendedAdjustment(Me)
                End If
                _cachePortBlendedAdjustment.RequestParameter = RequestParameter
                Return _cachePortBlendedAdjustment
            End Get
        End Property

        Public ReadOnly Property GetCachePortOreShipped() As Cache.DataCache
            Get
                If _cachePortOreShipped Is Nothing Then
                    _cachePortOreShipped = New Cache.PortOreShipped(Me)
                End If
                _cachePortOreShipped.RequestParameter = RequestParameter
                Return _cachePortOreShipped
            End Get
        End Property

        Public ReadOnly Property GetCachePortStockpileDelta() As Cache.DataCache
            Get
                If _cachePortStockpileDelta Is Nothing Then
                    _cachePortStockpileDelta = New Cache.PortStockpileDelta(Me)
                End If
                _cachePortStockpileDelta.RequestParameter = RequestParameter
                Return _cachePortStockpileDelta
            End Get
        End Property

        Public ReadOnly Property GetCacheHistorical() As Cache.Historical
            Get
                If _cacheHistorical Is Nothing Then
                    _cacheHistorical = New Cache.Historical(Me)
                End If
                _cacheHistorical.RequestParameter = RequestParameter
                Return _cacheHistorical
            End Get
        End Property

        Public Property IncludeResourceClassification As Boolean = False

        ''' <summary>
        ''' Gets or sets a comma delimited list of Models
        ''' </summary>
        Public Property RequiredModelList As HashSet(Of String) = New HashSet(Of String)()


        ''' <summary>
        ''' Stores the name of the report that called the webmethod. *Note that this is only set in some cases*
        ''' </summary>
        Public Property ReportName As String = Nothing


        ''' <summary>
        ''' Set this to true to change the functionality of the CalculationModel class to get the model data by block out
        ''' date, not by depletion month. This is used by the Reconciliation Risk Blockout Summary Report
        ''' </summary>
        Public Property GetModelDesignDataByBlockoutDate As Boolean = False

        Public Property IncludeStratigraphy As Boolean = False
#End Region

#Region "Constructors"
        Public Sub New()
            _liveDataContexts = New HashSet(Of ReportContext)
            _liveDataContexts.Add(ReportContext.ApprovalListing)
            _liveDataContexts.Add(ReportContext.LiveOnly)

            _approvedDataContexts = New HashSet(Of ReportContext)
            _approvedDataContexts.Add(ReportContext.Standard)
            _approvedDataContexts.Add(ReportContext.ApprovalListing)

        End Sub

        Public Sub New(ByVal connection As String)
            Me.New()
            SetupDal(connection)
        End Sub
#End Region

#Region " Destructors "



        Public Sub Dispose() Implements IDisposable.Dispose
            Dispose(True)
            GC.SuppressFinalize(Me)
        End Sub

        Protected Overridable Sub Dispose(ByVal disposing As Boolean)
            If (Not _disposed) Then
                If (disposing) Then
                    If (Not _dalApproval Is Nothing) Then
                        _dalApproval.Dispose()
                        _dalApproval = Nothing
                    End If

                    If (Not _dalReport Is Nothing) Then
                        _dalReport.Dispose()
                        _dalReport = Nothing
                    End If

                    If (Not _dalUtility Is Nothing) Then
                        _dalUtility.Dispose()
                        _dalUtility = Nothing
                    End If

                    If (Not _dalSecurityLocation Is Nothing) Then
                        _dalSecurityLocation.Dispose()
                        _dalSecurityLocation = Nothing
                    End If

                    If (Not _dalBhpbioLocationGroup Is Nothing) Then
                        _dalBhpbioLocationGroup.Dispose()
                        _dalBhpbioLocationGroup = Nothing
                    End If

                    If (Not _dalBlockModel Is Nothing) Then
                        _dalBlockModel.Dispose()
                        _dalBlockModel = Nothing
                    End If

                    If (Not _cacheBlockModel Is Nothing) Then
                        For Each _cacheItem In _cacheBlockModel.Values
                            _cacheItem.Dispose()
                        Next

                        _cacheBlockModel.Clear()
                        _cacheBlockModel = Nothing
                    End If

                    If (Not _cacheActualExpitToStockpile Is Nothing) Then
                        _cacheActualExpitToStockpile.Dispose()
                        _cacheActualExpitToStockpile = Nothing
                    End If

                    If (Not _cacheActualMineProduction Is Nothing) Then
                        _cacheActualMineProduction.Dispose()
                        _cacheActualMineProduction = Nothing
                    End If

                    If (Not _cacheActualStockpileToCrusher Is Nothing) Then
                        _cacheActualStockpileToCrusher.Dispose()
                        _cacheActualStockpileToCrusher = Nothing
                    End If

                    If (Not _cacheActualBeneProduct Is Nothing) Then
                        _cacheActualBeneProduct.Dispose()
                        _cacheActualBeneProduct = Nothing
                    End If

                    If (Not _cachePortBlendedAdjustment Is Nothing) Then
                        _cachePortBlendedAdjustment.Dispose()
                        _cachePortBlendedAdjustment = Nothing
                    End If

                    If (Not _cachePortOreShipped Is Nothing) Then
                        _cachePortOreShipped.Dispose()
                        _cachePortOreShipped = Nothing
                    End If


                    If (Not _cachePortStockpileDelta Is Nothing) Then
                        _cachePortStockpileDelta.Dispose()
                        _cachePortStockpileDelta = Nothing
                    End If

                    'If (Not _cacheHistorical Is Nothing) Then
                    '    _cacheHistorical.Dispose()
                    '    _cacheHistorical = Nothing
                    'End If

                    If (Not _approvedData Is Nothing) Then
                        For Each d As DataSet In _approvedData.Values
                            d.Dispose()
                        Next

                        _approvedData = Nothing
                    End If

                    If (Not _connection Is Nothing) Then
                        _connection.Dispose()
                        _connection = Nothing
                    End If
                End If

                _reportMaterialList = Nothing
            End If

            _disposed = True
        End Sub

        Protected Overrides Sub Finalize()
            Dispose(False)
            MyBase.Finalize()
        End Sub

        Public Sub ClearCacheBlockModel()
            If _cacheBlockModel IsNot Nothing Then
                For Each _cacheItem In _cacheBlockModel.Values
                    _cacheItem.Dispose()
                Next

                _cacheBlockModel.Clear()
                _cacheBlockModel = Nothing
            End If
        End Sub
#End Region

        Public Sub SetupDal(ByVal connectionText As String)
            DalConnectionText = connectionText
            _connection = Snowden.Common.Database.SqlDataAccessBaseObjects.SqlDataAccessConnection.GetConnection(connectionText, False)

            _dalApproval = New SqlDalApproval(_connection)
            _dalReport = New SqlDalReport(_connection)
            _dalUtility = New SqlDalUtility(_connection)
            _dalSecurityLocation = New SqlDalSecurityLocation(_connection)
            _dalBhpbioLocationGroup = New SqlDalBhpbioLocationGroup(_connection)
            _dalShippingTarget = New SqlDalShippingTarget(_connection)
            _dalBlockModel = New Reconcilor.Core.Database.SqlDal.SqlDalBlockModel(_connection)


            ' would be good to do this in a more generic way with reflection, but this will do for now
            _dalReport.FileSystemRoot = Me.FileSystemRoot

            If Me.FileSystemRoot IsNot Nothing Then
                Try
                    ' if an import has started then we want to delete everything from before the date that happened, so we can be sure
                    ' that the cache is ok
                    Dim lastImportDate = _dalUtility.BhpbioGetImportJobLatestActivtyDate("SUCCEEDED")
                    Dim reportCache = New ReportFileCache(FileSystemRoot, _dalReport.ReportCacheMaxAge)
                    reportCache.DeleteOldCacheData(lastImportDate.AddMinutes(5))
                    reportCache.DeleteOldCacheData()
                Catch ex As Exception
                    Debug.Print("Could not clear cache: " + ex.Message)
                End Try
            End If

        End Sub

        Public Sub CalculationParameters(ByVal startDate As Date, ByVal endDate As Date,
         ByVal locationId As Nullable(Of Int32), ByVal childLocations As Boolean)
            CalculationParameters(startDate, endDate, ReportBreakdown.Monthly, locationId, childLocations)
        End Sub

        Public Sub CalculationParameters(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As ReportBreakdown,
         ByVal locationId As Nullable(Of Int32), ByVal childLocations As Boolean)

            ' check that when report breakdown is None the time period spans less than one month
            If dateBreakdown = ReportBreakdown.None Then
                Dim span As TimeSpan = endDate - startDate

                If span.TotalDays > 31.0 Then
                    Throw New ArgumentException("When report period spans more than one month the date breakdown cannot be NONE.")
                End If
            End If

            If locationId < 1 Then
                locationId = 1
            End If

            RequestParameter = New DataRequest(locationId, startDate, endDate, dateBreakdown, childLocations)

        End Sub

        ''' <summary>
        ''' Test whether a factor is to be excluded from the report set or not
        ''' </summary>
        ''' <param name="factor">The factor to be excluded</param>
        ''' <returns>True if the factor is excluded, false otherwise</returns>
        ''' <remarks>Useful for the home screen that doesn't need all factors</remarks>
        Public Function IsFactorExcludedFromHubReportSet(ByVal factor As String) As Boolean
            Return _hubReportSetExcludedFactors.Contains(factor)
        End Function

        ''' <summary>
        ''' Exclude a factor from the hub report set
        ''' </summary>
        ''' <param name="factor">the factor to be excluded</param>
        ''' <remarks>Useful for the home screen that doesn't need all factors</remarks>
        Public Sub ExcludeFactorFromHubReportSet(ByVal factor As String)
            _hubReportSetExcludedFactors.Add(factor)
        End Sub

        Public Function GetLocationTypeId(locationId As Integer) As Integer
            Return Convert.ToInt32(Report.Data.Location.GetLocationType(Me, locationId))
        End Function

        Public Function GetLocationTypeName(locationId As Integer) As String
            Return LocationTypes.Item(GetLocationTypeId(locationId))
        End Function

        Public Function GetLocationName(locationId As Integer) As String
            Dim dt As DataTable = DalUtility.GetLocation(locationId)
            If dt.Rows.Count = 0 Then
                Throw New ArgumentException("No Location was found")
            End If

            Return dt.Rows(0)("Name").ToString()

        End Function

        Public Shared Function ConvertReportBreakdown(ByVal dateBreakdown As String) As ReportBreakdown
            Dim breakdownType As ReportBreakdown
            If dateBreakdown.ToUpper = "MONTH" Then
                breakdownType = ReportBreakdown.Monthly
            ElseIf dateBreakdown.ToUpper = "QUARTER" Then
                breakdownType = ReportBreakdown.CalendarQuarter
            ElseIf dateBreakdown.ToUpper = "YEAR" Then
                breakdownType = ReportBreakdown.Yearly
            Else
                breakdownType = ReportBreakdown.None
            End If

            Return breakdownType
        End Function

        Public Shared Function ConvertReportBreakdown(ByVal breakdown As ReportBreakdown) As String
            Dim breakdownText As String = NullValues.String
            If breakdown = ReportBreakdown.Monthly Then
                breakdownText = "MONTH"
            ElseIf breakdown = ReportBreakdown.CalendarQuarter Then
                breakdownText = "QUARTER"
            ElseIf breakdown = ReportBreakdown.Yearly Then
                breakdownText = "YEAR"
            End If

            Return breakdownText
        End Function


    End Class
End Namespace
