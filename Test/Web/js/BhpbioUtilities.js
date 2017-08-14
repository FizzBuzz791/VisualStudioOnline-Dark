function GetHaulageAdministrationSourceAndDestinationByLocation() {

    var locationControl = document.getElementById("LocationId");
             
    CallAjax('sourceDiv', './GetHaulageAdministrationSourceByLocation.aspx?LocationId='+locationControl.value, 'image');
    CallAjax('destinationDiv', './GetHaulageAdministrationDestinationByLocation.aspx?LocationId='+locationControl.value, 'image');

    return false;
}

function GetHaulageCorrectionSourceAndDestinationByLocation() {

    var locationControl = document.getElementById("LocationId");

    CallAjax('sourceDiv', './GetHaulageCorrectionSourceByLocation.aspx?LocationId='+locationControl.value, 'image');
    CallAjax('destinationDiv', './GetHaulageCorrectionDestinationByLocation.aspx?LocationId='+locationControl.value, 'image');

    return false;
}


function GetBhpbioMaterialTypeLocationList(MaterialTypeId) {
    CallAjax('materialLocationList', './ReferenceBhpbioMaterialTypeLocationList.aspx?MaterialTypeId=' + MaterialTypeId, true);
    return false;
}

// this overrides the existing method - if it gets called without an
function GetImportsTabContent(importId) {

    if (!importId || importId < 0) {
        return GetBhpbioImportsTabContent();
    } else {
        ClearElement('itemDetail');
        if (document.getElementById('importsContent').innerHTML == '') {
            GetImportsList(importId);
        }
    }

    return false;
}

function GetBhpbioImportsTabContent() {
    ClearElement('itemDetail');
    SubmitFormWithDateValidation(true, 'importAdminForm', 'importsContent', './ImportList.aspx', 'image');
    return false;
}

// override existing method to force submit so that filters work correctly
function GetImportsList(importId) {
    // see if the critical or validation link has been clicked
    var url = GetAddressParameter('Tab', window.location);

    switch (url)
    {
        case "Validation":
        case "Critical":
            url = './ImportList.aspx?Tab=' + url;
            if (importId != null) {
                url = url + '&ImportId=' + importId;
            }
            CallAjax('importContent', url);
            break;
        default:
            // Super important; Submit is necessary so that filter parameters are passed through.
            SubmitFormWithDateValidation(true, 'importAdminForm', 'importsContent', './ImportList.aspx', 'image');
    }
}

function FilterBhpbioHaulageCorrectionLocations() {
    var locationId = document.getElementById('LocationId')
    if (locationId != null) {
        document.location = './HaulageCorrection.aspx?LocationId=' + locationId.value;
    }
}

function ShowValidateScreen(ImportId) {
    var validationDateFrom = GetElementValue('ImportDateFromText');

    var monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    var month = $.inArray(GetElementValue('MonthPickerMonthPart'), monthNames) + 1;

    var year = GetElementValue('MonthPickerYearPart');
    var locationId = GetElementValue('LocationId');
    var locationName = GetElementValue('LocationName');
    var locationType = GetElementValue('LocationTypeDescription');
    var useMonthLocation = document.getElementById('MonthLocationRadio').checked;
    CallAjax('itemDetail',
        './ImportMessageGrouping.aspx?ImportId=' + ImportId +
        '&Type=Validate&ValidationDateFrom=' + validationDateFrom +
        '&Month=' + month +
        '&Year=' + year +
        '&LocationId=' + locationId +
        '&LocationName=' + locationName +
        '&locationType=' + locationType +
        '&UseMonthLocation=' + useMonthLocation);
    return false;
}

function ShowCriticalScreen(ImportId) {
    var validationDateFrom = GetElementValue('ImportDateFromText');
    CallAjax('itemDetail', './ImportMessageGrouping.aspx?ImportId=' + ImportId + '&Type=Critical&ValidationDateFrom=' + validationDateFrom);
    return false;
}

// this overrides an existing method in Core, and is used by 4 or 5 methods that make requests to get this
// data via ajax
function ImportMessageUrl(messageContentDivId, importId, type, userMessage, page) {
    var validationDateFrom = GetElementValue('ImportDateFromText');

    var monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    var month = $.inArray(GetElementValue('MonthPickerMonthPart'), monthNames) + 1;

    var year = GetElementValue('MonthPickerYearPart');
    var locationId = GetElementValue('LocationId');
    var locationName = GetElementValue('LocationName');
    var locationType = GetElementValue('LocationTypeDescription');
    var useMonthLocation = document.getElementById('MonthLocationRadio').checked;

    var result = './ImportMessage.aspx?MessageContentDivId=' + messageContentDivId +
     '&ImportId=' + importId + '&Type=' + type +
     '&Page=' + page +
     '&ValidationDateFrom=' + validationDateFrom +
     '&Month=' + month +
     '&Year=' + year +
     '&LocationId=' + locationId +
     '&LocationName=' + locationName +
     '&locationType=' + locationType +
     '&UseMonthLocation=' + useMonthLocation;

    if (userMessage) {
        result += ('&UserMessage=' + userMessage);
    }

    return result;
}

function ValidateEventFilterParameters()
{
    var currentDate = new Date();
    var startDate = document.getElementsByName("EventDateFromText").item(0).value;
    var endDate = document.getElementsByName("EventDateToText").item(0).value;

    startDate = calMgr.getDateFromFormat(startDate, calMgr.defaultDateFormat)
    endDate = calMgr.getDateFromFormat(endDate, calMgr.defaultDateFormat)

    var alertStr = "";

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
        }
    }



    if (alertStr != "") {
        alertStr = 'Please Fix the following Errors : \n' +alertStr ;
        alert(alertStr);
    } else
    {
         GetEventList();
    }

    return false;
}

function ValidateRecalcLogViewerFilterParameters()
{
   var startDate = document.getElementsByName("LogDateFromText").item(0).value;
    var endDate = document.getElementsByName("LogDateToText").item(0).value;

    if(ValidateDateParameters(startDate, endDate)) {
         GetRecalcLogViewerList();
    }

    return false;
}

function ValidateWeightometerSampleFilterParameters()
{
   var startDate = document.getElementsByName("SampleDateFromText").item(0).value;
    var endDate = document.getElementsByName("SampleDateToText").item(0).value;

    if(ValidateDateParameters(startDate, endDate)) {
         GetWeightometerSampleList();
    }

    return false;
}


function ValidateImportFilterParameters()
{
   var startDate = document.getElementsByName("QueueDateFromText").item(0).value;
    var endDate = document.getElementsByName("QueueDateToText").item(0).value;

    if(ValidateDateParameters(startDate, endDate)) {
         GetImportQueueList();
    }

    return false;
}

function ValidateHaulageFilterParameters(locationId, bulkEdit)
{
    var startDate = document.getElementsByName("HaulageDateFromText").item(0).value;
    var endDate = document.getElementsByName("HaulageDateToText").item(0).value;

    if(ValidateDateParameters(startDate, endDate)) {
        if(bulkEdit.toString().toLowerCase() == 'false')
              GetHaulageAdministrationList();
        else if (bulkEdit.toString().toLowerCase() == 'true')
              GetHaulageAdministrationBulkEditFilter(locationId);
    }

    return false;
}

if (!ValidateDateParameters) {
    function ValidateDateParameters(startDate, endDate) {
        var success = true;
        var alertStr = "";
        var currentDate = new Date();

        startDate = calMgr.getDateFromFormat(startDate, calMgr.defaultDateFormat);
        endDate = calMgr.getDateFromFormat(endDate, calMgr.defaultDateFormat);

        if (startDate == "") {
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

        if (startDate != "" && endDate != "") {
            if (startDate > endDate) {
                alertStr = alertStr + '- Start Date cannot be later than End Date \n';
                success = false;
            }
        }


        if (alertStr != "") {
            alertStr = 'Please Fix the following Errors : \n' + alertStr;
            alert(alertStr);
        }

        return success;
    }
}

function GetBhpbioStockpileGroupStockpileList() {
    var submitButton;
    submitButton = document.getElementById('SubmitEdit');
    submitButton.style.display = 'none';
    SubmitForm('EditForm', 'stockpileList', './ReferenceStockpileGroupStockpileList.aspx','image');
    return false;
}

function AddDefaultDeposit() {
    var locationControl = document.getElementById("LocationId");
    if (locationControl==null || locationControl.value == '')
        alert('Select site first')
    CallAjax('itemDetail', './DefaultDepositEdit.aspx?ParentLocationId=' +locationControl.value);
    return false;
}


function EditDepositLocation(BhpbioDefaultDepositId) {
    ClearElement('itemDetail')
    CallAjax('itemDetail', './DefaultDepositEdit.aspx?BhpbioDefaultDepositId=' +BhpbioDefaultDepositId);
    return false;
    }

function DeleteDepositLocation(BhpbioDefaultDepositId) {
    ClearElement('itemDetail')
    if (confirm('Are you sure you want to delete?')) {
        CallAjax('itemDetail', './DefaultDepositDelete.aspx?BhpbioDefaultDepositId=' + BhpbioDefaultDepositId);
    }
    return false;
}

function GetDepositsForSite() {
    var locationType = document.getElementById("LocationTypeDescription");
    if (locationType.value == '' || locationType.value.toUpperCase() === 'SITE') { // On initialisation, it'll be empty, just let it go through, it doesn't affect anything.
        ClearElement('itemDetail');
        SubmitForm('FilterForm', 'DepositContent', './DefaultDepositList.aspx', 'image');
    } else {
        alert("Please ensure a Site is chosen.")
    }
    return false;
}

function GetSampleStations() {
    ClearElement("SampleStationDetail");
    SubmitForm("FilterForm", "SampleStationContent", "./DefaultSampleStationList.aspx", "image");
    return false;
}

function DeleteSampleStation(sampleStationId) {
    ClearElement("SampleStationDetail");
    if (confirm("Are you sure you want to delete?")) {
        CallAjax("SampleStationContent", "./DefaultSampleStationDelete.aspx?SampleStationId=" + sampleStationId);
    }
    return false;
}

function AddDefaultSampleStation() {
    CallAjax("SampleStationDetail", "./DefaultSampleStationEdit.aspx");
}

function PopulateWeightometer() {
    var locationType = GetElementValue("SampleStationLocationIDTypeDescription");
    var locationId = GetElementValue("SampleStationLocationID");

    if (locationType !== "" &&
        (locationType.toUpperCase() === "HUB" || locationType.toUpperCase() === "SITE")) {

        $("#FilteredWeightometerList").empty();
        $("#BodyTable_WeightometerList tr").filter(function(index, element) {
            if (parseInt($(element)[0].all[2].innerText) === parseInt(locationId) ||
                parseInt($(element)[0].all[3].innerText) === parseInt(locationId)) {
                var option = document.createElement("option");
                option.text = $.trim($(element)[0].all[0].innerText);
                document.getElementById("FilteredWeightometerList").add(option);
            }
        });
    }
}

function EditSampleStation(sampleStationId) {
    ClearElement("SampleStationDetail");
    CallAjax("SampleStationDetail", "./DefaultSampleStationEdit.aspx?SampleStationId=" + sampleStationId);
    return false;
}

function CancelEditSampleStation() {
    ClearElement("SampleStationDetail");
}

function AddSampleStationTarget(sampleStationId) {
    CallAjax("TargetContent", "./DefaultSampleStationTargetEdit.aspx?SampleStationId=" + sampleStationId);
}

function EditSampleStationTarget(targetId) {
    ClearElement("TargetContent");
    CallAjax("TargetContent", "./DefaultSampleStationTargetEdit.aspx?TargetId=" + targetId);
}

function CancelEditSampleStationTarget() {
    ClearElement("TargetContent");
}

function DeleteSampleStationTarget(targetId) {
    ClearElement("TargetContent");
    if (confirm("Are you sure you want to delete?")) {
        CallAjax("SampleStationDetail", "./DefaultSampleStationTargetDelete.aspx?TargetId=" + targetId);
    }
}

function CancelEditDefaultDeposit() {
    ClearElement('itemDetail')
}

function GetDefaultProductTypeList() {
    ClearElement('itemDetail')
    ClearElement('itemList')
    CallAjax('itemDetail', './DefaultProductTypeList.aspx')
    return false;
}

function GetDefaultshippingTargetList() {
    ClearElement('itemDetail')
    ClearElement('itemList')
    CallAjax('itemList', './DefaultshippingTargetList.aspx')
    return false;
}

function CleanShippingTargetDetail() {
    ClearElement('itemDetail');
    return false;
}

function GetDefaultLumpFinesList() {
    ClearElement('itemDetail')
    SubmitForm('DefaultLumpFinesForm', 'itemList', './DefaultLumpFinesList.aspx', 'image')
    return false;
}

function GetDefaultOutlierSeriesList() {
    ClearElement('itemDetail')
    ClearElement('itemList')
    CallAjax('itemDetail', './GetDefaultOutlierSeriesList.aspx')
    return false;
}

function EditDefaultLumpFines(BhpbioDefaultLumpFinesId) {
    ClearElement('itemDetail')
    CallAjax('itemDetail', './DefaultLumpFinesEdit.aspx?BhpbioDefaultLumpFinesId=' + BhpbioDefaultLumpFinesId);
    return false;
}

function EditProductTypeLocation(BhpbioDefaultProductTypeId) {
    //ClearElement('itemDetail')
    CallAjax('itemList', './DefaultProductTypeEdit.aspx?BhpbioDefaultProductTypeId=' + BhpbioDefaultProductTypeId);
    return false;
}

function EditOutlierSeriesConfiguration(OutlierSeriesConfigurationId) {
    //ClearElement('itemDetail')
    CallAjax('itemList', './DefaultOutlierSeriesConfigurationEdit.aspx?OutlierSeriesConfigurationId=' + OutlierSeriesConfigurationId);
    return false;
}

function EditShippingTarget(ShippingTargetPeriodId) {
    //ClearElement('itemDetail')
    CallAjax('itemDetail', './DefaultshippingTargetEdit.aspx?ShippingTargetPeriodId=' + ShippingTargetPeriodId);
    return false;
}
function EditShippingTargetGrid(productTypeId, shippingTargetDate, shouldCopy) {
    //ClearElement('itemDetail')
    shouldCopy = (shouldCopy === true) ? '1' : '0';
    CallAjax('itemDetail', './DefaultshippingTargetEdit.aspx?ProductTypeId=' + productTypeId +
        '&ShippingTargetDate=' + encodeURIComponent(shippingTargetDate) +
        '&ShouldCopy=' + shouldCopy);

    return false;
}
function CancelEditDefaultLumpFines() {
    ClearElement('itemDetail')
    return false;
}

function CancelEditDefaultProductType() {
    ClearElement('itemList')
    return false;
}

function CancelEditOutlierSeriesConfiguration() {
    ClearElement('itemList')
    return false;
}

function CancelRefreshShippingTarget() {
    ClearElement('itemList')
    return false;
}

function AddDefaultLumpFines() {
    ClearElement('itemDetail')
    CallAjax('itemDetail', './DefaultLumpFinesEdit.aspx');
    return false;
}

function RefreshShippingTargets() {
    //ClearElement('itemDetail')
    CallAjax('itemDetail', './DefaultProductTypeEdit.aspx');
    return false;
}

function AddDefaultProductType() {
    //ClearElement('itemDetail')
    CallAjax('itemList', './DefaultProductTypeEdit.aspx');
    return false;
}

function DeleteDefaultLumpFines(BhpbioDefaultLumpFinesId) {
    ClearElement('itemDetail');
    if (confirm('Are you sure you want to delete?')) {
        CallAjax('', './DefaultLumpFinesDelete.aspx?BhpbioDefaultLumpFinesId=' + BhpbioDefaultLumpFinesId);
    }
    return false;
}

function DeleteShippingTarget(ShippingTargetPeriodId) {
    ClearElement('itemDetail');
    if (confirm('Are you sure you want to delete?')) {
        CallAjax('', './DefaultshippingTargetDelete.aspx?ShippingTargetPeriodId=' + ShippingTargetPeriodId);
    }
    return false;
}

function DeleteProductTypeLocation(ProductTypeId) {
    ClearElement('itemList');
    if (confirm('Are you sure you want to delete?')) {
        CallAjax('', './DefaultProductTypeDelete.aspx?ProductTypeId=' + ProductTypeId);
    }
    return false;
}
function DismissAllClick() {
    SubmitForm('exceptionFilter', 'itemList', './DataExceptionListDismissAll.aspx');
    return false;
}

function BhpbioSaveImportJobDetails() {

    var from = AddHiddenFieldToDatePicker("#DateFromContainer");
    var to = AddHiddenFieldToDatePicker("#DateToContainer");

    if (from && !IsDateStringValid(from))
    {
        alert('Could not save: From Date is invalid');
        return false;
    }

    if (to && !IsDateStringValid(to))
    {
        alert('Could not save: To Date is invalid');
        return false;
    }

	return SaveImportJobDetails();
}

function GetElementValue(id)
{
    var e = document.getElementById(id);

    if (e) {
        return e.value;
    } else {
        return null;
    }
}

// uses the calender control to check that the date is properly formatted
// returns a bool
function IsDateStringValid(dateString)
{
    if (!dateString)
        return false;

    // if the date is valid then a Date object will be return, if it is invalid
    // 0 or false will come back
    return !!calMgr.getDateFromFormat(dateString, calMgr.defaultDateFormat);
}

function AddHiddenFieldToDatePicker(containerId) {
    var inputId = "ParameterInput_" + $(containerId).attr("data-tag");

    // add the hidden input if it doesn't exist already
    if ($("#" + inputId).length == 0) {
        $(containerId).append('<input type="hidden" id="' + inputId + '" name="' + inputId + '" value="" />');
    }

    // transfer the value from the picker to the hidden input, so it can be submitted to the server
    var value = $(containerId).find("input[type=\"text\"]").val();
    $("#" + inputId).val(value);

    return value;
}

function ResetImportsFilters(locationDivId, locationWidth, lowestDescription, defaultDate) {
    var dateFrom = document.getElementsByName("ImportDateFromText")[0];
    var monthFilter = document.getElementById("MonthValue");
    var monthFilterMonth = document.getElementById("MonthPickerMonthPart");
    var monthFilterYear = document.getElementById("MonthPickerYearPart");

    dateFrom.value = defaultDate;

    monthFilter.value = formatDate(new Date());
    var monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    monthFilterMonth.value = monthNames[new Date().getMonth()]; // Already 0 indexed.
    monthFilterYear.value = new Date().getFullYear();

    LoadLocation(false, 1, locationDivId, locationWidth, true, "LocationId", "","","", lowestDescription);
}

function formatDate(date) {
    var monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];

    var day = date.getDate();
    var monthIndex = date.getMonth();
    var year = date.getFullYear();

    return day + "-" + monthNames[monthIndex] + "-" + year;
}

function SetFilterControlsStates(dateFromRadioSelected) {
    // TODO: Couldn't get this working. Will leave for now incase client *really* wants it.
}