
function SetStockpileGroupsDisplay() {
    var rowId = "StockpileGroupsRow";
     
    var groupStockpilesCheck = document.getElementById("GroupStockpiles")
 
    for(var i=0; i < 5; i++)
    {
        var control = document.getElementById(rowId + i);
        
        if (control != null)
        {
            if (groupStockpilesCheck != null)
            {
                if (groupStockpilesCheck.checked == true)
                {
                    control.style.display = "inline";
                }
                else 
                    control.style.display = "none";               
            }
        }
        
        control = document.getElementById("StockpileGroupsRowBottom")
        if (control != null){
         if (groupStockpilesCheck != null)
            {
                if (groupStockpilesCheck.checked == true)
                {
                    control.style.display = "inline";
                }
                else 
                    control.style.display = "none";               
            }
        }   
    }
}

function CheckAllGroups() {
   var key = "CheckBox"    
   for (var i = 0; i < document.forms['stockpileForm'].elements.length; i++) {
        var e = document.forms['stockpileForm'].elements[i];
        if ((e.type == 'checkbox') && (e.name.indexOf(key) > -1)) {
            e.checked = true;
        }
    }
}

function UncheckAllGroups() {
  
    var key = "CheckBox"    
   for (var i = 0; i < document.forms['stockpileForm'].elements.length; i++) {
        var e = document.forms['stockpileForm'].elements[i];
        if ((e.type == 'checkbox') && (e.name.indexOf(key) > -1)) {
            e.checked = false;
        }
    }
}

function ClearStockpileDetailsFilterDates()
{
    var startDate = document.getElementsByName("StockpileDateFromText").item(0);
    var endDate = document.getElementsByName("StockpileDateToText").item(0);
    
    startDate.value = "";
    endDate.value = "";
    
    return false;

}

function SetupStockpileDetailsFilterDates(startDateStr, endDateStr)
{
    var startDate = document.getElementsByName("StockpileDateFromText").item(0);
    var endDate = document.getElementsByName("StockpileDateToText").item(0);
    
    startDate.value = startDateStr;
    endDate.value = endDateStr;
    
    return false;
}

function ValidateBhpbioStockpileManualAdjustmentList() {

    if (ValidateBhpbioStockpileManualAdjustmentFilterValues()) {
        GetStockpileManualAdjustmentList();
    }

    return false;
}

function ValidateBhpbioStockpileManualAdjustmentFilterValues() {

    var success = true;
    var currentDate = new Date();
    var alertStr = "";
    var startDate = document.getElementById("AdjustmentDateFromText").value;
    var endDate = document.getElementById("AdjustmentDateToText").value;

    var dateValid = (function(d) { return d && d.getTime && !isNaN(d.getTime()); });
    var HasEmptyStart = (startDate === "");
    var HasEmptyEnd = (endDate === "");
    
    startDate = calMgr.getDateFromFormat(startDate, calMgr.defaultDateFormat);
    endDate = calMgr.getDateFromFormat(endDate, calMgr.defaultDateFormat);

    if(!HasEmptyStart && !dateValid(startDate)) {
        alertStr = alertStr + '- Start Date is not well formed \n';
        success = false;
    }

    if (!HasEmptyEnd && !dateValid(endDate)) {
        alertStr = alertStr + '- End Date is not well formed \n';
        success = false;
    }    
    
    if (startDate > currentDate) {
        alertStr = alertStr + '- Date From cannot be later than Current Date \n';
        success = false;
    }

    if (endDate > currentDate) {
        alertStr = alertStr + '- Date To cannot be later than Current Date \n';
        success = false;
    }

    if (startDate != "" && endDate != "") {
        if (startDate > endDate) {
            alertStr = alertStr + '- Date From cannot be later than Date To \n';
            success = false;
        }
    }

    if (alertStr != "") {
        alertStr = 'Please Fix the following Errors : \n' + alertStr;
        alert(alertStr);
    }

    return success;
}

function ValidateFilterParameters()
{
    var startDate = document.getElementsByName("StockpileDateFromText").item(0).value;
    var endDate = document.getElementsByName("StockpileDateToText").item(0).value;
    var transactionStartDate = document.getElementsByName("TransactionStartDateText").item(0).value;
    var transactionEndDate = document.getElementsByName("TransactionEndDateText").item(0).value;
    
    var groupStockpilesCheck = document.getElementById("GroupStockpiles");
       
    if(ValidateStockpileFilterParameters(startDate, endDate, transactionStartDate, transactionEndDate, groupStockpilesCheck )) {
            GetStockpileList();
    }
         
    return false;
}

function ValidateStockpileDetailsFilterParameters()
{
    var startDate = document.getElementsByName("StockpileDateFromText").item(0).value;
    var endDate = document.getElementsByName("StockpileDateToText").item(0).value;
    
    if(ValidateDateDetailParameters(startDate, endDate)) {
        GetStockpileDetails();
    }
         
    return false;
}

function ValidateStockpileFilterParameters(startDate, endDate, transactionStartDateStr, transactionEndDateStr, groupStockpilesCheck){
    var success = true;
    var alertStr = "";
    var currentDate = new Date();
    
    startDate = calMgr.getDateFromFormat(startDate, calMgr.defaultDateFormat)
    endDate = calMgr.getDateFromFormat(endDate, calMgr.defaultDateFormat)  
    transactionStartDate = calMgr.getDateFromFormat(transactionStartDateStr, calMgr.defaultDateFormat)
    transactionEndDate = calMgr.getDateFromFormat(transactionEndDateStr, calMgr.defaultDateFormat)
 
    var dateValid = (function(d) { return d && d.getTime && !isNaN(d.getTime()); });
    
      var key = "CheckBox" ;
      var validGroups = false;
            
      if (groupStockpilesCheck.checked == true)
      {
           for (var i = 0; i < document.forms['stockpileForm'].elements.length; i++) {
                var e = document.forms['stockpileForm'].elements[i];    
                if (e != null) {       
                 if ((e.type == 'checkbox') && (e.name.indexOf(key) > -1)) {
                    if(e.checked)
                        validGroups = true;
                }
              }
            }
            
        if(validGroups == false) {
            alertStr = alertStr + '- Please select at least one Stockpile Group \n';
            success = false;
        } 
      }       
    
    if(transactionStartDateStr && !dateValid(transactionStartDate)) {
        alertStr = alertStr + "- The value for 'Transaction Start Date' is not well formed \n";
        success = false;
    }
    
    if(transactionEndDateStr && !dateValid(transactionEndDate)) {
        alertStr = alertStr + "- The value for 'Transaction End Date' is not well formed \n";
        success = false;
    }
    
    if (startDate > currentDate) {
        alertStr = alertStr + '- Start Date cannot be later than Current Date \n';
        success = false;
    }
    
    if (endDate > currentDate) {
        alertStr = alertStr + '- End Date cannot be later than Current Date \n';
        success = false;
    }
    
    if (transactionStartDate > currentDate) {
        alertStr = alertStr + '- Transaction Date From cannot be later than Current Date \n';
        success = false;
    }
    
      if (transactionEndDate > currentDate) {
        alertStr = alertStr + '- Transaction Date To cannot be later than Current Date \n';
        success = false;
    }
    
    if(startDate != "" && endDate != "")
    {
         if( startDate > endDate)
         {
            alertStr = alertStr + '- Start Date cannot be later than End Date \n';
            success = false;  
         }
    }    
    
    if(transactionStartDate != "" && transactionEndDate != "")
    {
         if( transactionStartDate > transactionEndDate)
         {
            alertStr = alertStr + '- Transaction Date From cannot be later than Transaction Date To \n';
            success = false;  
         }
    }
    
    if (alertStr != "") {
        alertStr = 'Please Fix the following Errors : \n' +alertStr ;
        alert(alertStr);
    }
    
    return success 
}

function ValidateDateDetailParameters(startDate, endDate)
{
    var success = true;
    var alertStr = "";
    var currentDate = new Date();
    
    startDate = calMgr.getDateFromFormat(startDate, calMgr.defaultDateFormat)
    endDate = calMgr.getDateFromFormat(endDate, calMgr.defaultDateFormat)  

    //Genealogy tab - date to control is hidden
    
    var dateToControlHidden = false;
    var dateToControlClass = document.getElementById("DateToControl");
    
    if (dateToControlClass != null)
        if(dateToControlClass.className == 'hide')
            dateToControlHidden = true;
          
    if(startDate == "") {
      alertStr = alertStr + '- Start Date not selected \n';
        success = false; 
    }
    else if (startDate > currentDate) {
        alertStr = alertStr + '- Start Date cannot be later than Current Date \n';
        success = false;
    }
    
    // if date to control is hidden do not validate
    
    if(dateToControlHidden == false)
    {
    
        if (endDate == "") {
              alertStr = alertStr + '- End Date not selected \n';
            success = false; 
        }
        else if (endDate > currentDate) {
            alertStr = alertStr + '- End Date cannot be later than Current Date \n';
            success = false;
        }
        
        if(startDate != "" && endDate != "")
        {
             if( startDate > endDate)
             {
                alertStr = alertStr + '- Start Date cannot be later than End Date \n';
                success = false;  
             }
        }
    }
    
    if (alertStr != "") {
        alertStr = 'Please Fix the following Errors : \n' +alertStr ;
        alert(alertStr);
    }
    
    return success 
}

function ResetStockpileFilter(locationDivId, locationWidth, lowestDescription)
{
    var LimitRecords
    , GroupStockpiles
    , StateType
    , StockpileIdFilter
    , StockpileDateFrom
    , StockpileDateTo
    , TransactionStartDate
    , TransactionEndDate
    , IncludeLocationsBelow;
    
    UncheckAllGroups();

    GroupStockpiles = document.getElementById('GroupStockpiles');
    LimitRecords = document.getElementById('LimitRecords');
    StateType = document.getElementById('StateType');
    StockpileIdFilter = document.getElementById('StockpileIdFilter');
    StockpileDateFrom = document.getElementById('StockpileDateFromText');
    StockpileDateTo = document.getElementById('StockpileDateToText');
    TransactionStartDate = document.getElementById('TransactionStartDateText');
    TransactionEndDate = document.getElementById('TransactionEndDateText');
    IncludeLocationsBelow = document.getElementById('IncludeLocationsBelow');

    if (StateType) {
        for (var i = StateType.options.length - 1; i >= 0; i--) {
            if (StateType.options[i].text == 'Active Stockpiles') {
                StateType.selectedIndex = i;
            }
        }
    }
    
    if (StockpileIdFilter) { StockpileIdFilter.value = ''; } 
    if (StockpileDateFrom) { StockpileDateFrom.value = ''; }
    if (StockpileDateTo) { StockpileDateTo.value = ''; }
    if (TransactionStartDate) { TransactionStartDate.value = ''; }
    if (TransactionEndDate) { TransactionEndDate.value = ''; }
    if (GroupStockpiles) { GroupStockpiles.checked = 1; }
    if (LimitRecords) { LimitRecords.checked = 1; }
    if (IncludeLocationsBelow) { IncludeLocationsBelow.checked = 1; }

    LoadLocation(false, 0, locationDivId, locationWidth, true, 'LocationId', '','','', lowestDescription); 
    
    SetStockpileGroupsDisplay();
}

function GetStockpileListLocationDate(locationId, dateFrom, dateTo, locationDivId, locationWidth, lowestDescription) {
    document.stockpileForm.StateType.value = ""; // View = All Stockpiles

    document.stockpileForm.CheckBoxStockpilesNOTGrouped.checked = true;
    document.stockpileForm.ExcludeEmptyRecords.checked = false;
    // Have to uncheck them all or it'll use remembered states
    document.stockpileForm.CheckBoxPostCrusher.checked = false;
    document.stockpileForm.CheckBoxPortTrainRake.checked = false;
    document.stockpileForm.CheckBoxROM.checked = false;
    document.stockpileForm.CheckBoxBeneFines.checked = false;
    document.stockpileForm.CheckBoxBeneReject.checked = false;
    document.stockpileForm.CheckBoxCrusherProduct.checked = false;
    document.stockpileForm.CheckBoxBeneFeed.checked = false;
    document.stockpileForm.CheckBoxBeneProduct.checked = false;
    document.stockpileForm.CheckBoxHighGrade.checked = false;
    document.stockpileForm.CheckBoxLowGrade.checked = false;
    document.stockpileForm.CheckBoxPyriticWaste.checked = false;
    document.stockpileForm.CheckBoxWaste.checked = false;
    document.stockpileForm.CheckBoxHUBTrainRake.checked = false;
    document.stockpileForm.CheckBoxTopSoilStorage.checked = false;
    document.stockpileForm.CheckBoxReportExclude.checked = false;
    document.stockpileForm.CheckBoxReportExcludeHvP.checked = false;

    document.stockpileForm.LocationId.value = locationId;
    LoadLocation(false, locationId, locationDivId, locationWidth, true, 'LocationId', '', '', '', lowestDescription); 

    document.stockpileForm.TransactionStartDateText.value = dateFrom;
    document.stockpileForm.TransactionEndDateText.value = dateTo;

    // validateDate doesn't actually return true, it returns false or undefined, undefined should be considered valid...
    var dateFromWellFormed = calMgr.validateDate(document.stockpileForm.TransactionStartDateText, false);
    var dateToWellFormed = calMgr.validateDate(document.stockpileForm.TransactionEndDateText, false);

    var isValidationError = false;
    var validationErrorMessage = "";

    if (dateFrom !== '' && dateFrom !== null && dateFromWellFormed === false) {
        isValidationError = true;
        validationErrorMessage = validationErrorMessage + "The value for 'Start Date From' is not well formed.\n";
    }

    if (dateTo !== '' && dateTo !== null && dateToWellFormed === false) {
        isValidationError = true;
        validationErrorMessage = validationErrorMessage + "The value for 'Start Date To' is not well formed.\n";
    }

    if (isValidationError) {
        alert(validationErrorMessage);
    } else {
        var element = document.getElementById('stockpileList');
        if (element !== null) {
            var url = './StockpileList.aspx';
            SubmitForm('stockpileForm', 'stockpileList', url, 'image');
        } else {
            if (confirm('This will disregard changes to this record. Continue?')) {
                window.location = 'default.aspx';
            }
        }
    }
    return false;
}