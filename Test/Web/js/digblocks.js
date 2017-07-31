//Digblock scripts
var ActivationType = 'Commenced';

function ActivateForHaulage(){
	var QueryString = Trim(GetDigblocksToActivate());
	var ShiftType = document.getElementById('ShiftType');
	var ActivationDate = document.getElementById('ActivationDateText');
	
	
	if (QueryString != ''){
		QueryString = QueryString.substring(0, QueryString.length -1);
	}
	
	
	if (ShiftType && ActivationDate)
	{
		QueryString = '?ShiftType=' + ShiftType.value 
            + '&ActivationDate=' + ActivationDate.value
            + '&Type=' + ActivationType 
            + '&DigblockList=' + QueryString;
            
	    ActivationType = 'Commenced';
    	CallAjax('', './DigblockActivateForHaulage.aspx' + QueryString);
	}	
	else
	{
	    alert('Date must be supplied');
	}
	
	return false;
}

function AddDigblock(isLocationMandatory){
    SubmitForm('EditForm', '', './DigblockSave.aspx?IsLocationMandatory=' + isLocationMandatory, 'image');
	return false;
}

function CheckDigblock(CheckBox){
	var parentTable = CheckBox.parentNode;
	var checkboxes;
	
	while(parentTable && parentTable.tagName.toLowerCase() != 'table'){
		parentTable = parentTable.parentNode;
	}
	
	checkboxes = parentTable.getElementsByTagName('INPUT');
	
	for (i=0; i<checkboxes.length; i++){
		if (checkboxes[i].type.toLowerCase() == 'checkbox' && checkboxes[i].id != CheckBox.id){
			checkboxes[i].disabled = CheckBox.checked;
			checkboxes[i].checked = CheckBox.checked;
		}
	}
}

function DeleteDigblock(EncodedDigblockId, LoadScreen){
    if (confirm('Delete the digblock \'' + unescape(EncodedDigblockId.replace("+", " ")) + '\'?')) {
	    CallAjax('', './DigblockDelete.aspx?DigblockId=' + EncodedDigblockId + '&LoadScreen=' + LoadScreen, 'image');
	}
	
	return false;
}

function DeletePolygonPoint(Point){
    CallAjax('', './DigblockEditPolygonPointDelete.aspx?Point=' + Point);
    return false;
}

function DigblockEditAddPoint(){
	SubmitForm('PointForm', '', './DigblockEditPolygonPointAdd.aspx');
	return false;
}

function DigblockEditPointClearForm(){
	document.getElementById('PointX').value = '';
	document.getElementById('PointY').value = '';
	document.getElementById('PointZ').value = '';
}

function DigblockPolygonMapClick(UrlEncodedDigblockId) {
    var w = window.open('../Digblocks/DigblockDetails.aspx?DigblockId=' + UrlEncodedDigblockId, '_digblock');
	w.focus();

	return false;
}

function GetActivateForHaulageFilter(Script){
	CallAjax('activateForHaulageFilter', './GetActivateForHaulageFilter.aspx', null, Script);
	return false;
}

function GetDigblockEditPolygonForm(){
	CallAjax('PolygonForm', './DigblockEditPolygonPointForm.aspx');
	return false;
}

function GetDigblockEditPolygonList(){
	CallAjax('PolygonList', './DigblockEditPolygonPointList.aspx');
	return false;
}

function GetDigblockHaulageList(validateInput) {
    if (validateInput) {
        calMgr.validateDate(document.digblockForm.HaulageDateFromText, CalendarControls.Lookup('HaulageDateFrom').required);
        calMgr.validateDate(document.digblockForm.HaulageDateToText, CalendarControls.Lookup('HaulageDateTo').required);
    }
    
	SubmitForm('digblockForm', 'HaulageList', './DigblockHaulageList.aspx', 'image');
	return false;
}

function GetDigblockList(prompt){
	var promptReturn = true;
	var str = String(window.location);

	var dateFrom = document.digblockForm.DigblockDateFromText.value;
	var dateTo = document.digblockForm.DigblockDateToText.value;
	
    var dateFromWellFormed = calMgr.validateDate(document.digblockForm.DigblockDateFromText, CalendarControls.Lookup('DigblockDateFrom').required);
    var dateToWellFormed = calMgr.validateDate(document.digblockForm.DigblockDateToText, CalendarControls.Lookup('DigblockDateTo').required);
    
	calMgr.formatDate(document.digblockForm.DigblockDateFromText, CalendarControls.Lookup('DigblockDateFrom').dateFormat);
	calMgr.formatDate(document.digblockForm.DigblockDateToText, CalendarControls.Lookup('DigblockDateTo').dateFormat);

	var validationError = false;
	var validationErrorMessage = "";

	if (dateFrom != '' && dateFrom != null && dateFromWellFormed == false) {
	    validationError = true;
	    validationErrorMessage = validationErrorMessage + "The value for 'Start Date From' is not well formed.\n";
	}

	if (dateTo != '' && dateTo != null && dateToWellFormed == false) {
	    validationError = true;
	    validationErrorMessage = validationErrorMessage + "The value for 'Start Date To' is not well formed.\n";
	}

	if (validationError) {
	    alert(validationErrorMessage);
	} else {

	    //Check if
	    if (str.indexOf('Treeview') != -1) {
	        //Force refresh if its the tree
	        window.location = window.location;
	    }
	    else if (prompt) {

	        if (prompt != 'dateError') {
	            if (confirm(prompt)) {
	                SubmitForm('digblockForm', 'digblockList', './DigblockList.aspx?IgnorePrompt=1', 'image');
	            };
	        }

	    }
	    else {
	        //SubmitForm('digblockForm', 'digblockList', './DigblockList.aspx', 'image');
	        SubmitFormWithDateValidation(false, 'digblockForm', 'digblockList', './DigblockList.aspx', 'image');
	    }
	}
	
	return false;
}

function GetDigblocksToActivate(){
	var DigblockList = '';
	var inputControls = document.getElementsByTagName('input');
	
	for (i=0; i<inputControls.length; i++){
		if ((inputControls[i].type == 'checkbox')&&(inputControls[i].id.indexOf('activate_') != -1)){
			if (inputControls[i].checked) {
				DigblockList += VbReplace(inputControls[i].id, 'activate_', '') + '|';
			}
		}
	}
	
	return DigblockList;
}

function GetDigblockTreeNode(ImageElement, ParentNodeId) {
    var SettingValue;
    var checked = document.getElementById(ParentNodeId + '_chk');

    if (checked) {
        checked = checked.checked;
    }
    else {
        checked = false;
    }

    if (ImageElement.src.indexOf('minus.png') == -1) {
        SettingValue = 'True'
    } else {
        SettingValue = 'False'
    }

    ExpandCollapsePlusMinus(ImageElement, ParentNodeId)

    SaveUserSetting(ParentNodeId + '_Expanded', SettingValue);

    GetTabPageData(ParentNodeId + '_data', './DigblockTreeviewGetNode.aspx?nodeId=' + ParentNodeId + '&checked=' + checked, 'image');
}

function ResetDigblockFilters(locationDivId, TopLocationTypeId, SettingPrefix, locationWidth)
{
    var StateType, DigblockIdFilter, DigblockDateFrom, DigblockDateTo;

    StateType = document.getElementById('StateType');
    DigblockIdFilter = document.getElementById('DigblockIdFilter');
    DigblockDateFrom = document.getElementById('DigblockDateFromText');
    DigblockDateTo = document.getElementById('DigblockDateToText');

    if (StateType) { StateType.selectedIndex = 0; }
    if (DigblockIdFilter) { DigblockIdFilter.value = ''; }
    if (DigblockDateFrom) { DigblockDateFrom.value = ''; }
    if (DigblockDateTo) { DigblockDateTo.value = ''; }
	
	LoadLocation(false, 0, locationDivId, locationWidth, true, 'LocationId');
}

function GetDigblockTransactionList(validateInput) 
{
    if (validateInput) {
        calMgr.validateDate(document.digblockForm.TransactionDateFromText, CalendarControls.Lookup('TransactionDateFrom').required);
        calMgr.validateDate(document.digblockForm.TransactionDateToText, CalendarControls.Lookup('TransactionDateTo').required);
    }

    SubmitForm('digblockForm', 'transactionList', './DigblockTransactionsList.aspx', 'image');
    return false;
}

function GetDataTransactionTonnesDetails(dttId) 
{
    CallAjax('transactionDetailDiv', '../Digblocks/DigblockGetFlowDetails.aspx'
			 + '?dttId=' + dttId, 'image');

    return false;
}
