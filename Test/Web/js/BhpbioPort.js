var CurrentTab;
var baseWidth = 640;

function GetPortDetails() {

//        ** Commented out could be causing problems on site - can't replicate locally

//        var filterBox = document.getElementById('PortFilterBox');
//        ForceHide(filterBox.id);
//        document.appendChild(filterBox);

        ClearElement('shippingContent');
        ClearElement('portBlendingContent');
        ClearElement('portBalancesContent');

        switch (CurrentTab) {
            case 'Shipping':
                GetShippingTabContent();
                break;
            case 'Port Blending':
                GetPortBlendingTabContent();
                break;
            case 'Port Balances':
                GetPortBalancesTabContent();
                break;
        }

    return false;
}

function clearDate() {
    var startDate = document.getElementsByName("PortDateFromText").item(0);
    var endDate = document.getElementsByName("PortDateToText").item(0);
    
    startDate.value = "";
    endDate.value = "";
    
    return false;
}

function populateDate(startDateStr, endDateStr) {
 var PortDateFrom, PortDateTo;
 
    PortDateFrom = document.getElementById('PortDateFromText');
    PortDateTo = document.getElementById('PortDateToText');
    
    PortDateFrom.value = startDateStr;
    PortDateTo.value = endDateStr;

    return false; 
}

function ValidatePortFilterParameters()
{
    var startDate = document.getElementsByName("PortDateFromText").item(0);
    var endDate = document.getElementsByName("PortDateToText").item(0);
    
    if(ValidateDateParameters(startDate.value, endDate.value)) {
        GetPortDetails();
    } 
         
    return false;
}


function ValidateDateParameters(startDate, endDate)
{
    var success = true;
    var alertStr = ""; 
    var currentDate = new Date();
    
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
    } 
   
    
    if (alertStr != "") {
        alertStr = 'Please Fix the following Errors : \n' +alertStr ;
        alert(alertStr);
    }
    
    return success ;
}
  
function GetShippingTabContent() {
       
        CurrentTab = 'Shipping';       
        GetPortTabPageDataForm('portForm', 'shippingContent', './PortShippingList.aspx', 'imageWide', 'MovePortFilter("shippingFilterDiv");');
    
    return false;
}

function GetPortBlendingTabContent() {
 
    CurrentTab = 'Port Blending';
    GetPortTabPageDataForm('portForm', 'portBlendingContent', './PortBlendingList.aspx', 'imageWide', 'MovePortFilter("portBlendingFilterDiv");');    

    return false;
}

function GetPortBalancesTabContent() {

    CurrentTab = 'Port Balances';
    GetPortTabPageDataForm('portForm', 'portBalancesContent', './PortBalancesList.aspx', 'imageWide', 'MovePortFilter("portBalancesFilterDiv");');       

    return false;
}

function GetPortTabPageDataForm(formName, elementId, urlToLoad, showLoading, finalCall){
	//if(document.getElementById(elementId).innerHTML == ''){
		SubmitForm(formName, elementId, urlToLoad, showLoading, finalCall)
	//}
	
	 if (finalCall != '')
	{
		eval(finalCall);
	}
	
	return false;
}

function MovePortFilter(targetDiv) {

        var filterBox = document.getElementById('PortFilterBox');
        var target = document.getElementById(targetDiv);

        if (filterBox != null && filterBox != 'undefined') {
            target.appendChild(filterBox);
            ForceShow(filterBox.id);
        }
}

function ResetPortFilters(locationDivId, lowestLocationTypeId) {
    var PortDateFrom, PortDateTo;

    PortDateFrom = document.getElementById('PortDateFromText');
    PortDateTo = document.getElementById('PortDateToText');

    if (PortDateFrom) { PortDateFrom.value = ''; }
    if (PortDateTo) { PortDateTo.value = ''; }

    LoadLocation(false, 0, locationDivId, 0, true, 'LocationId', '', '', '', lowestLocationTypeId);
}
