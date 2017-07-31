// Variance Setup BHPBIO Specific logic
function getVarianceDetails(locationId) {
    var qrystr = '?LocationId=' + locationId;
    CallAjax('varianceSetup', './DigblockSpatialVarianceViewSetup.aspx' + qrystr, 'image');
    return false;
}

function GetOutlierAnalysisGrid() {
    
    //CallAjax('itemDetail', './OutlierAnalysisGrid.aspx')
    var locationId = document.getElementById('locationDynamic').value;
    
    if (locationId == null || locationId == -1) {
        alert('Please select a Location');
        return false;
    }
    var startdate = "01-" + document.getElementById('MonthPickerMonthPartStart').value + "-"+ document.getElementById('MonthPickerYearPartStart').value;
    var enddate= "01-" + document.getElementById('MonthPickerMonthPartEnd').value + "-" + document.getElementById('MonthPickerYearPartEnd').value;
  
    if (!ValidateDateParameters(startdate, enddate)) {
        return false;
    }
    SubmitForm('outlierForm', 'itemDetail', './OutlierAnalysisGrid.aspx', 'image');
    return false;
}

function GetOutlierAnalysisFilter() {
    CallAjax('itemList', './OutlierAnalysisFilter.aspx');
    return false;
}


function ClearOutlierAnalysisFilter(defaultLocationWidth, locationDivId) {
    
    document.getElementById('AnalysisGroup').selectedIndex = 0;

    var d = new Date();

    document.getElementById('MonthPickerMonthPartStart').selectedIndex = d.getMonth();
    document.getElementById('MonthPickerMonthPartEnd').selectedIndex = d.getMonth();
    document.getElementById('MonthPickerYearPartStart').selectedIndex = 0;
    document.getElementById('MonthPickerYearPartEnd').selectedIndex = 0;
    document.getElementById('MonthValueStart').value = '1-May-2009';
    document.getElementById('MonthValueEnd').value = '1-Jun-2009';

    document.getElementById('productTypeProductSize').selectedIndex = 0;
    document.getElementById('All').checked = true;
    document.getElementById('deviations').selectedIndex = 0;

    LoadBhpbioLocation(0, locationDivId, defaultLocationWidth, true, 'location', '', {
        lowestLocationTypeDescription: 'PIT'
    });

    return false;
}


function GetOutlierAnalysisFilterQstr(AnalysisGroup, MonthStart, MonthEnd, LocationId, ProductSize, AttributeFilter) {
    var qryStr = '?AnalysisGroup=' + AnalysisGroup +
		'&MonthStart=' + MonthStart + '&MonthEnd=' + MonthEnd +
		'&LocationId=' + LocationId + '&ProductSize=' + ProductSize + '&AttributeFilter=' + AttributeFilter;
    CallAjax('itemList', './OutlierAnalysisFilter.aspx' + qryStr);
    return false;
}

function ApplyVarianceSettings(locationId) {
    var qrystr = '?ApplyVariance=true&LocationId=' + locationId;
    SubmitForm('VarianceForm', '', './DigblockSpatialVarianceSave.aspx' + qrystr, 'image');
    return false;
}

function RemoveVarianceOverride(locationId) {
    var qrystr = '?ResetVariance=true&LocationId=' + locationId;
    SubmitForm('VarianceForm', '', './DigblockSpatialVarianceSave.aspx' + qrystr, 'image');
    return false;
}

// Digblock Spatial Comparison
function getVarianceLegend(locationId) {
    var qrystr = '?LocationId=' + locationId;
    CallAjax('legendDiv', './DigblockSpatialAdministrationLegend.aspx' + qrystr, 'image');
    return false;
}

// Location
function LoadBhpbioLocation(locationId, locationDivId, locationColWidth, showCaptions, controlId, onChange, options) {
    options = options || {}
    var qryStr = '../Utilities/LocationFilterLoad.aspx?LocationId=' + locationId +
		'&LocationDivId=' + locationDivId + '&LocationColWidth=' + locationColWidth +
		'&ShowCaptions=' + showCaptions + '&ControlId=' + controlId + '&onChange=' + onChange;
    
    if (options.lowestLocationTypeDescription) {
        qryStr += '&lowestLocationTypeDescription=' + options.lowestLocationTypeDescription;
    }

    CallAjax(locationDivId, qryStr, 'image');

    return false;
}

function LocationBhpbioDropDownChanged(locationCtrl, locationDivId, locationColWidth, showCaptions, controlId, onChange) {
    if (locationCtrl.selectedIndex > -1) {
        var locationId = locationCtrl.options[locationCtrl.selectedIndex].value;
        LoadBhpbioLocation(locationId, locationDivId, locationColWidth, showCaptions, controlId, onChange)
    }
}

function RenderBhpbioDataExport() {
    // remove the viewstate so we don't get crazy errors when posting to the server
    document.getElementById('__VIEWSTATE').value = '';

    // validate that a location was selected
    var locationId = document.getElementById('LocationId').value;
    if (locationId == null || locationId == -1) {
        alert('Please select a Location');
        return false;
    }

    var startMonth = document.getElementById('MonthValueStart').value;
    var endMonth = document.getElementById('MonthValueEnd').value;

    // if the month string doesn't have a leading zero, then we need to add this on, or the validation
    // method won't parse it properly
    if(startMonth.charAt(1) == '-') {
        startMonth = '0' + startMonth;
    }
    
    if(endMonth.charAt(1) == '-') {
        endMonth = '0' + endMonth;
    }

    if (!ValidateDateParameters(startMonth, endMonth)) {
        return false;
    }

    return true;
}

function RenderBhpbioProdDataExport(lumpDateString) {
    // remove the viewstate so we don't get crazy errors when posting to the server
    document.getElementById('__VIEWSTATE').value = '';

    var productTypeCode = document.getElementById('productTypeCode').value;
    if (productTypeCode == null || productTypeCode == 'NONE') {
        alert('Please select a Product Type');
        return false;
    }

    var startMonth = document.getElementById('MonthValueStart').value;
    var endMonth = document.getElementById('MonthValueEnd').value;

    // if the month string doesn't have a leading zero, then we need to add this on, or the validation
    // method won't parse it properly
    if (startMonth.charAt(1) == '-') {
        startMonth = '0' + startMonth;
    }

    if (endMonth.charAt(1) == '-') {
        endMonth = '0' + endMonth;
    }

    if (!ValidateDateParameters(startMonth, endMonth)) {
        return false;
    }

    if (lumpDateString) {
        var lumpDates = new Date(lumpDateString);
        var startDateAsDate = calMgr.getDateFromFormat(startMonth, calMgr.defaultDateFormat)

        if (startDateAsDate < lumpDates) {
            // the export must also not run prior to the lump fines cutover
            BhpbioDisplayLumpFinesDateValidationErrorMessage(lumpDates, "export");
            return false;
        }
    }
    
    return true;
}

function RenderBhpbioSpatialComparison() {
    var locationDesc = document.getElementById("LocationTypeDescription");
    
      // check that the location control has had a chance to load
    if (locationDesc == null) {
        alert('Please wait for the filters to load.');
        return false;
    }
    // check the location hierarchy selection
    else if (locationDesc.value == 'Company' || locationDesc.value == 'Hub'
             || locationDesc.value == 'Site' || locationDesc.value == 'Pit'
             || locationDesc.value == '') {
        alert('You may only select Bench, Blast or Block for comparison.');
        return false;
    }
       
    // run the original call
    else {
        return RenderSpatialComparison();
    }
}

function ResetBhpbioAnalysisFilters(defaultFromDate, defaultToDate, defaultLocationWidth, locationDivId) {
    var location = document.getElementById('LocationId');
    var dateFrom = document.getElementById('SpatialDateFromText');
    var dateTo = document.getElementById('SpatialDateToText');
    var leftComparison = document.getElementById('LeftComparison');
    var rightComparison = document.getElementById('RightComparison');
    var useCircles = document.getElementById('UseCircles');
    var tonnes = document.getElementById('Tonnes');
    var designation = document.getElementById('Designation');

    if (location == null || dateFrom == null || dateTo == null || leftComparison == null
        || rightComparison == null || useCircles == null || tonnes == null || designation == null) {
        alert('Please wait for the filters to load.');
    }
    else {
        LoadBhpbioLocation(0, locationDivId, defaultLocationWidth, true, 'LocationId', '', '');

        dateFrom.value = defaultFromDate;
        dateTo.value = defaultToDate;
        designation.value = -1;
        leftComparison.value = -1;
        SpatialComparisonSeletion(leftComparison, 'Left');
        rightComparison.value = -1;
        SpatialComparisonSeletion(rightComparison, 'Right');
        useCircles.checked = -1;
        tonnes.checked = -1;
    }
}

//Digblock Filter Functions

function setupDigblockFilterDates(startDateStr, endDateStr)
{
    var startDate = document.getElementsByName("HaulageDateFromText").item(0);
    var endDate = document.getElementsByName("HaulageDateToText").item(0);
    
    startDate.value = startDateStr;
    endDate.value = endDateStr;
    
    return false;
}

function clearDigblockFilterDates()
{
    var startDate = document.getElementsByName("HaulageDateFromText").item(0);
    var endDate = document.getElementsByName("HaulageDateToText").item(0);
    
    startDate.value = "";
    endDate.value = "";
    
    return false;
}

//Digblock Validation Functions


function ValidateDigblockFilterParameters()
{
    var startDate = document.getElementsByName("DigblockDateFromText").item(0).value;
    var endDate = document.getElementsByName("DigblockDateToText").item(0).value;

    if (ValidateDateParameters(startDate, endDate)) {
        return GetDigblockList();
    }
    else
    {
        return false;    
    }
}

function ValidateDateParameters(startDate, endDate)
{
    var success = true;
    var alertStr = ""; 
    var currentDate = new Date();

    var dateValid = (function(d) { return d && d.getTime && !isNaN(d.getTime()); });
    var HasEmptyStart = (startDate === "");
    var HasEmptyEnd = (endDate === "");
        
    startDate = calMgr.getDateFromFormat(startDate, calMgr.defaultDateFormat);
    endDate = calMgr.getDateFromFormat(endDate, calMgr.defaultDateFormat);

    if(startDate != "") {
        if (startDate > currentDate) {
            alertStr = alertStr + '- Start Date cannot be later than Current Date \n';
            success = false;
        }
 
    } else if(!HasEmptyStart && !dateValid(startDate)) {
        alertStr = alertStr + '- Start Date is not well formed \n';
        success = false; 
    }
    
    if (endDate != "") {
        if (endDate > currentDate) {
            alertStr = alertStr + '- End Date cannot be later than Current Date \n';
            success = false;
        }

    } else if (!HasEmptyEnd && !dateValid(endDate)) {
        alertStr = alertStr + '- End Date is not well formed \n';
        success = false; 
    }
    
    if(startDate != "" && endDate != "")
    {
         if( startDate > endDate) {
            alertStr = alertStr + '- Start Date cannot be later than End Date \n';
            success = false; 
        }
    } 
   
    
    if (alertStr != "") {
        alertStr = 'Please Fix the following Errors : \n' +alertStr ;
        alert(alertStr);
    }
    
    return success 
}


function ValidateDetailDateParameters(startDate, endDate)
{
    var success = true;
    var alertStr = ""; 
    var currentDate = new Date();
    var dateValid = (function(d) { return d && d.getTime && !isNaN(d.getTime()); });
    
    startDate = calMgr.getDateFromFormat(startDate, calMgr.defaultDateFormat)
    endDate = calMgr.getDateFromFormat(endDate, calMgr.defaultDateFormat)  
    
    if(startDate == "") {
      alertStr = alertStr + '- Start Date not selected \n';
        success = false; 
    } else if (startDate > currentDate) {
        alertStr = alertStr + '- Start Date cannot be later than Current Date \n';
        success = false;
    }
    
     if (endDate == "") {
          alertStr = alertStr + '- End Date not selected \n';
        success = false; 
    } else if (endDate > currentDate) {
        alertStr = alertStr + '- End Date cannot be later than Current Date \n';
        success = false;
    }
    
    if(startDate != "" && endDate != "")
    {
         if( startDate > endDate) {
            alertStr = alertStr + '- Start Date cannot be later than End Date \n';
            success = false; 
        }
        
        if(!dateValid(startDate)) {
            alertStr = alertStr + '- Start Date is not well formed \n';
            success = false; 
        }
        
        if(!dateValid(endDate)) {
            alertStr = alertStr + '- End Date is not well formed \n';
            success = false; 
        }
    }    
    
    if (alertStr != "") {
        alertStr = 'Please Fix the following Errors : \n' +alertStr ;
        alert(alertStr);
    }
    
    return success 
}

function ValidateTransactionDetailFilterParameters() {
    var startDate = document.getElementsByName("TransactionDateFromText").item(0).value;
    var endDate = document.getElementsByName("TransactionDateToText").item(0).value;

    if (ValidateDateParameters(startDate, endDate)) {
        GetDigblockTransactionList();
    }

    return false;
}

function ValidateDigblockDetailFilterParameters()
{
    var startDate = document.getElementsByName("HaulageDateFromText").item(0).value;
    var endDate = document.getElementsByName("HaulageDateToText").item(0).value;

    if(ValidateDateParameters(startDate, endDate)) {
        GetDigblockHaulageList();
    }
         
    return false;
}

// this little module is here to help with date handling. Have put it in its own
// namespace so that it doesn't interfere with other methods
(function() {
    var $ = function(elem) {
        if (typeof elem == 'string') {
            return document.getElementById(elem);
        } else {
            return elem;
        }        
    }

    var hideElement = function(elem) {
        elem = $(elem);
        if (elem) {
            elem.style.display = 'none';
        }
    }

    var showElement = function(elem) {
        elem = $(elem);
        if (elem) {
            elem.style.display = '';
        }
    }
    
    // use this to get the <td> for the select boxes. We could keep going up the
    // heirachy checking the types, but lets just assume that the <td> is the direct 
    // parent
    var getCell = function(elem) {
        elem = $(elem);
        if (elem) {
            return elem.parentNode;
        }
    }

    // this is called when the Quarter selectbox changes to update the
    // hidden date value for that date select. This should be used when the
    // month select changes as well, but that code already works, so no sense
    // to break it
    //
    // selectIndex is the suffix of the date picker, it will almost always be
    // 'Start' or 'End'
    var onQuarterDateChange = function(selectIndex) {

        var quarterPicker = $('QuarterPickerPart' + selectIndex);
        var yearPicker = $('MonthPickerYearPart' + selectIndex);
        var dateValueInput = $('MonthValue' + selectIndex);

        var dateRange = ConvertQuarterToDate(quarterPicker.value, yearPicker.value);
        var dateStr = (selectIndex.toUpperCase() == 'END' ? dateRange.end : dateRange.start);

        dateValueInput.value = dateStr;
    }
    
    var onMonthDateChange = function(selectIndex) {
        $('MonthValue' + selectIndex).value = '01-' + $('MonthPickerMonthPart' + selectIndex).value + '-' + $('MonthPickerYearPart' + selectIndex).value;
    }
    
    var onDateChange = function(selectIndex) {
        var dateBreakdownInput = $('dateBreakdown');
        var dateBreakdown = "MONTH"
        
        if(dateBreakdownInput) {
            dateBreakdown = dateBreakdownInput.value;
        }

        if(dateBreakdown == "QUARTER") {
            onQuarterDateChange(selectIndex);            
        } else {
            onMonthDateChange(selectIndex)
        }
    }

    var onDateBreakdownChange = function() {
        var breakdown = $('dateBreakdown').value;

        if (breakdown == 'MONTH') {
            hideElement(getCell('QuarterPickerPartStart'));
            hideElement(getCell('QuarterPickerPartEnd'));
            showElement(getCell('MonthPickerMonthPartStart'));
            showElement(getCell('MonthPickerMonthPartEnd'));
        } else if (breakdown == 'QUARTER') {
            showElement(getCell('QuarterPickerPartStart'));
            showElement(getCell('QuarterPickerPartEnd'));
            hideElement(getCell('MonthPickerMonthPartStart'));
            hideElement(getCell('MonthPickerMonthPartEnd'));
        }
        
        onDateChange('Start');
        onDateChange('End');
    }

    // converts a quarter and year into a date string. The quarter code should be in the format 'Q1' etc
    //
    // The return value is an object in the format: {start: '01-Jan-2013', end: '31-Mar-2013'}
    //
    var ConvertQuarterToDate = function(quarterCode, year) {
        if (typeof year == 'string') {
            year = parseInt(year, 10);
        }

        var quarterLookup = {
            'Q1': { startMonth: 'Jul', endMonth: 'Sep', endDay: 30 },
            'Q2': { startMonth: 'Oct', endMonth: 'Dec', endDay: 31 },
            'Q3': { startMonth: 'Jan', endMonth: 'Mar', endDay: 31 },
            'Q4': { startMonth: 'Apr', endMonth: 'Jun', endDay: 30 }
        }

        var q = quarterLookup[quarterCode];

        if (!q) {
            quarterCode = "Q1";
            q = quarterLookup[quarterCode];
        }

        // we are dealing with FYs, so the first two Qs are actually in
        // the previous calender year
        if (quarterCode == "Q1" || quarterCode == "Q2") {
            year--;
        }

        var startDateStr = '01-' + q.startMonth + '-' + year.toString();
        var endDateStr = q.endDay.toString() + '-' + q.endMonth + '-' + year.toString();

        return { start: startDateStr, end: endDateStr };
    }

    // this makes the methods 'public' so they can be accessed / referenced in the C# set events
    window.DateHelpers = {
        onDateBreakdownChange: onDateBreakdownChange,
        onDateChange: onDateChange
    };

})();