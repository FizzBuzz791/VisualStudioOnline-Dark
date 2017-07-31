function GetRawStockpileAttributeTabContent() {
    CurrentTab = 'RawAttribute';

    ForceHide('RowChartOptions');
    ForceHide('RowShift');
    ForceHide('RowActivityType');
    ForceShow('DateToLabel');
    ForceShow('DateToControl');
    ForceHide('StockpileFilterChartButtonDiv');
    SetDateFromText("Date From: ");
    SetShiftFromText("Shift From: ");

    document.getElementById('StockpileFilterButton').value = ' Filter ';

    GetTabPageDataForm('stockpileForm', 'StockpileRawAttributeContent', './StockpileDetailsTabRawAttribute.aspx', 'imageWide', 'MoveStockpileFilter("rawAttribsFilterDiv");');
    ResizeContainer();
    return false;
}

function GetRawStockpileBalanceTabContent() {
    CurrentTab = 'RawBalance';

    ForceHide('RowChartOptions');
    ForceHide('RowShift');
    ForceHide('RowActivityType');
    ForceShow('DateToLabel');
    ForceShow('DateToControl');
    ForceHide('StockpileFilterChartButtonDiv');
    SetDateFromText("Date From: ");
    SetShiftFromText("Shift From: ");

    document.getElementById('StockpileFilterButton').value = ' Filter ';

    GetTabPageDataForm('stockpileForm', 'StockpileRawBalanceContent', './StockpileDetailsTabRawBalance.aspx', 'imageWide', 'MoveStockpileFilter("rawBalanceFilterDiv");');
    ResizeContainer();
    return false;
}

//Stockpiles Scripts
var CurrentTab;

function DeleteStockpile(StockpileId, Description, LoadScreen){	
	if(confirm('Are you sure you want to delete \'' + Description + '\'?')){
		CallAjax('', './StockpileDelete.aspx?StockpileId=' + StockpileId + '&Description=' + Description);
	}
	
	return false;
}

function AddStockpile(){
	var returnValue;
	
	returnValue = AIM.submit(document.getElementById('EditForm'), './StockpileEditUploadImage.aspx', {'onComplete' : completeCallback});
	document.getElementById('EditForm').submit();
	//returnValue = AIM.submit(document.getElementById('EditForm'), './StockpileEditUploadImage.aspx', {'onStart' : startCallback, 'onComplete' : completeCallback});
	return false;
}

function startCallback() {   
    // make something useful before submit (onStart)
    return true;   
}   

function completeCallback(response) {
    if (response.substr(0,8) == 'uploaded') {
		SubmitForm('EditForm', '', './StockpileSave.aspx'); 
    }else{
		try{
			eval(response);
		}catch(err){
		}
    }
}   

function SetDateFromText(newText)
{
	var e = document.getElementById('DateFromLabel');

	if (e)
	{
		e.innerHTML = newText;
	}
}

function SetShiftFromText(newText)
{
	var e = document.getElementById('ShiftFromLabel');

	if (e)
	{
		e.innerHTML = newText;
	}
}


function GetStockpileActivityTabContent(){
	CurrentTab = 'Activity';
	ForceHide('RowChartOptions');
	ForceHide('RowShift');
	ForceShow('RowActivityType');
	ForceShow('DateToLabel');
	ForceShow('DateToControl');
	ForceHide('StockpileFilterChartButtonDiv');
	SetDateFromText("Date From: ");
	SetShiftFromText("Shift From: ");
	
	document.getElementById('StockpileFilterButton').value = ' Filter ';
	
	GetTabPageDataForm('stockpileForm', 'StockpileActivityContent', './StockpileDetailsTabActivity.aspx', 'imageWide', 'MoveStockpileFilter("activityFilterDiv");');
	ResizeContainer();
	return false;
}

function GetStockpileAttributeTabContent(){
	CurrentTab = 'Attribute';

	ForceHide('RowChartOptions');
	ForceHide('RowShift');
	ForceHide('RowActivityType');
	ForceShow('DateToLabel');
	ForceShow('DateToControl');
	ForceHide('StockpileFilterChartButtonDiv');
	SetDateFromText("Date From: ");
	SetShiftFromText("Shift From: ");

	document.getElementById('StockpileFilterButton').value = ' Filter ';

	GetTabPageDataForm('stockpileForm', 'StockpileAttributeContent', './StockpileDetailsTabAttribute.aspx', 'imageWide', 'MoveStockpileFilter("attribsFilterDiv");');
	ResizeContainer();
	return false;
}

function GetStockpileBalanceTabContent(){
	CurrentTab = 'Balance';

	ForceHide('RowChartOptions');
	ForceHide('RowShift');
	ForceHide('RowActivityType');
	ForceShow('DateToLabel');
	ForceShow('DateToControl');
	ForceHide('StockpileFilterChartButtonDiv');
	SetDateFromText("Date From: ");
	SetShiftFromText("Shift From: ");

	document.getElementById('StockpileFilterButton').value = ' Filter ';

	GetTabPageDataForm('stockpileForm', 'StockpileBalanceContent', './StockpileDetailsTabBalance.aspx', 'imageWide', 'MoveStockpileFilter("balanceFilterDiv");');
	ResizeContainer();
	return false;
}

function GetStockpileChartingSecondChart(StockpileId){
	CallAjax('StockpileChartingSecondChart', './StockpileDetailsTabChartingSecondChart.aspx?StockpileId=' + StockpileId, 'imageWide');
	ResizeContainer();
	return false;
}

function GetStockpileChartingSecondChartContent(){
	var Suffix;
	Suffix = 'SecondChart';
	
	SetDateFromText("Date From: ");
	SetShiftFromText("Shift From: ");
	ForceHide('RowActivityType' + Suffix);
	ForceHide('RowShift' + Suffix);
	SubmitForm('stockpileFormSecondChart', 'StockpileChartingSecondChartContent', './StockpileDetailsTabCharting.aspx?Suffix=SecondChart', 'imageWide');
	ResizeContainer();
	return false;
}

function GetStockpileChartingTabContent(){

	ForceShow('RowChartOptions');
	ForceHide('RowShift');
	ForceHide('RowActivityType');
	ForceShow('DateToLabel');
	ForceShow('DateToControl');
	ForceShow('StockpileFilterChartButtonDiv');
	ForceShow(StockpileDetailsFilterBox.id);
	SetDateFromText("Date From: ");
	SetShiftFromText("Shift From: ");

	document.getElementById('StockpileFilterButton').value = ' Redraw Graph ';

	if (CurrentTab == 'Charting') {
	    GetTabPageDataForm('stockpileForm', 'StockpileChartingContent', './StockpileDetailsTabCharting.aspx', 'imageWide');
	} else {
	    CurrentTab = 'Charting';
	    GetTabPageDataForm('stockpileForm', 'StockpileChartingContent', './StockpileDetailsTabCharting.aspx', 'imageWide', 'MoveStockpileFilter("chartFilterDiv");');
	}
	ResizeContainer();
	return false;
}

function GetStockpileOpenGraphWindow(prnt){
	var wnd = window.open('about:blank', 'secondChart', '');
    var a = window.setTimeout("GetStockpileOpenGraphWindowSubmit(" + prnt + ");", 500); 
  wnd.focus(); 
	
	return false;
}

function GetStockpileOpenGraphWindowSubmit(prnt){
    var form = document.getElementById('stockpileForm');
    form.target = 'secondChart';
    form.action = './StockpileDetailsTabCharting.aspx?popup=true';
	if (prnt) {
	    form.action = form.action + '&print=true';
	}
	form.submit();
	return false;
}

function ShowHideStockpileGroups(){
	var multiBuild = document.getElementById('MultiBuild');
	//var multiComponent = document.getElementById('MultiComponent');
	var DateItems = document.getElementById('DateItems');
	var TonnesAndGradeItems = document.getElementById('TonnesAndGradeItems');
	
	if (multiBuild.checked){
		ForceHide(DateItems.id);
		ForceHide(TonnesAndGradeItems.id);
	//}else if(multiComponent.checked){
	//	ForceShow(DateItems.id);
	//	ForceHide(TonnesAndGradeItems.id);
	}else{
		ForceShow(DateItems.id);
		ForceShow(TonnesAndGradeItems.id);
	}
}

function GetStockpileDetails(){
	var filterBox = document.getElementById('StockpileDetailsFilterBox');
	ForceHide(StockpileDetailsFilterBox.id);
	//document.appendChild(StockpileDetailsFilterBox);

	ClearElement('StockpileAttributeContent');
	ClearElement('StockpileChartingContent');
	ClearElement('StockpileActivityContent');
	ClearElement('StockpileGenealogyContent');
	ClearElement('StockpileLocationContent');
	ClearElement('StockpileBalanceContent');
	ClearElement('StockpileRawAttributeContent');
	ClearElement('StockpileRawBalanceContent');
	
	switch (CurrentTab){
		case 'Attribute':
			GetStockpileAttributeTabContent();
			break;
		case 'Charting':
			GetStockpileChartingTabContent();
			break;
		case 'Activity':
			GetStockpileActivityTabContent();
			break;
		case 'Genealogy':
			GetStockpileGenealogyTabContent();
			break;
		case 'Location':
			GetStockpileLocationTabContent();
			break;
		case 'Balance':
			GetStockpileBalanceTabContent();
			break;
        case 'RawBalance':
            GetRawStockpileBalanceTabContent();
            break;
        case 'RawAttribute':
            GetRawStockpileAttributeTabContent();
            break;
	}
	
	return false;
}

function GetStockpileEditModellingForm(){
	CallAjax('ModellingForm', './StockpileEditModellingForm.aspx');
	return false;
}

function DeleteStockpileModellingType(stockpileId)
{
	CallAjax('', './StockpileEditModellingDelete.aspx?stockpileId='+stockpileId);
	return false;
}

function GetStockpileEditModellingList(){
	CallAjax('ModellingList', './StockpileEditModellingList.aspx');
	return false;
}

function GetStockpileList() {

    var element = document.getElementById('stockpileList');

    var dateFrom = document.stockpileForm.StockpileDateFromText.value;
    var dateTo = document.stockpileForm.StockpileDateToText.value;

    var dateFromWellFormed = calMgr.validateDate(document.stockpileForm.StockpileDateFromText, false);
    var dateToWellFormed = calMgr.validateDate(document.stockpileForm.StockpileDateToText, false);

    var isValidationError = false;
    var validationErrorMessage = "";

    if (dateFrom != '' && dateFrom != null && dateFromWellFormed == false) {
        isValidationError = true;
        validationErrorMessage = validationErrorMessage + "The value for 'Start Date From' is not well formed.\n";
    }

    if (dateTo != '' && dateTo != null && dateToWellFormed == false) {
        isValidationError = true;
        validationErrorMessage = validationErrorMessage + "The value for 'Start Date To' is not well formed.\n";
    }

    if (isValidationError) {
        alert(validationErrorMessage);
    } else {

        if (element != null) {
            SubmitForm('stockpileForm', 'stockpileList', './StockpileList.aspx', 'image');            
        }
        else {
            if (confirm('This will disregard changes to this record. Continue?')) {
                window.location = 'default.aspx';
            }
        }
    }
    return false;
}

function GetStockpileGenealogyTabContent(){
	CurrentTab = 'Genealogy';
	ForceHide('RowChartOptions');
	ForceHide('RowActivityType');
	ForceHide('DateToLabel');
	ForceHide('DateToControl');
	ForceShow('RowShift');
	ForceHide('StockpileFilterChartButtonDiv');

	SetDateFromText("Date: ");
	SetShiftFromText("Shift: ");
	
	document.getElementById('StockpileFilterButton').value = ' Filter ';
	
	GetTabPageDataForm('stockpileForm', 'StockpileGenealogyContent', './StockpileDetailsTabGenealogy.aspx', 'imageWide',  'MoveStockpileFilter("genealogyFilterDiv");');
	return false;
}

function GetStockpileLocationTabContent(){
	CurrentTab = 'Location';
	ForceHide('RowChartOptions');
	ForceHide('RowShift');
	ForceHide('RowActivityType');
	ForceHide('StockpileFilterChartButtonDiv');
	
	document.getElementById('StockpileFilterButton').value = ' Filter ';
	
	GetTabPageDataForm('stockpileForm', 'StockpileLocationContent', './StockpileDetailsTabLocation.aspx', 'imageWide',  'MoveStockpileFilter("locationFilterDiv");');
	return false;
}

function GetStockpileLocation(SelectBox, GetSelected, SettingPrefix){
	var DivId = VbReplace(SelectBox.id, 'Location_', 'LocationContainer_')
	var SelectValue = SelectBox.options[SelectBox.selectedIndex].value
	
	if (SelectValue == ''){
		ClearElement(DivId)
	}else{
		CallAjax(DivId, '../Stockpiles/GetStockpileLocation.aspx?Type=' + VbReplace(SelectBox.id.substring(0, SelectBox.id.lastIndexOf('_')), 'Location_', '') + '&Level=' + SelectBox.id.substring(SelectBox.id.lastIndexOf('_') + 1) + '&ParentLocationId=' + SelectValue + '&GetSelected=' + GetSelected + '&SettingPrefix=' + SettingPrefix);
	}
}

function StockpileStateChanged(ctrl)
{
	var selValue = ctrl.options[ctrl.selectedIndex].value;

	if (selValue == 'CLOSED')
	{
		ForceShow('CompleteDescriptionRow');
	}
	else
	{
		ForceHide('CompleteDescriptionRow');
	}
}

// Builds
function AddNewBuild(StockpileId){
	CallAjax('itemDetail', './StockpileBuildEdit.aspx?StockpileId=' + StockpileId);
	return false;
}

function GetBuildList(StockpileId){
	CallAjax('itemList', './StockpileBuildList.aspx?StockpileId=' + StockpileId, 'image');
	return false;
}

function EditBuild(StockpileId, BuildId){
	CallAjax('itemDetail', './StockpileBuildEdit.aspx?StockpileId=' + StockpileId + '&BuildId=' + BuildId);
	return false;
}

function DeleteBuild(StockpileId, BuildId, Description){
	if(confirm('Delete the Build \'' + Description + '\'?')){
		CallAjax('itemDetail', './StockpileBuildDelete.aspx?StockpileId=' + StockpileId + '&BuildId=' + BuildId);
	}
	
	return false;
}

// Components
function AddNewComponent(StockpileId){
	CallAjax('itemDetail', './StockpileComponentEdit.aspx?StockpileId=' + StockpileId);
	return false;
}

function GetComponentList(StockpileId){
	CallAjax('itemList', './StockpileComponentList.aspx?StockpileId=' + StockpileId, 'image');
	return false;
}

function EditComponent(StockpileId, BuildId, ComponentId){
	CallAjax('itemDetail', './StockpileComponentEdit.aspx?StockpileId=' + StockpileId + '&BuildId=' + BuildId  + '&ComponentId=' + ComponentId);
	return false;
}

function DeleteComponent(StockpileId, BuildId, ComponentId, Description){
	if(confirm('Delete the Component \'' + Description + '\'?')){
		CallAjax('itemDetail', './StockpileComponentDelete.aspx?StockpileId=' + StockpileId + '&BuildId=' + BuildId + '&ComponentId=' + ComponentId);
	}
	
	return false;
}

//Manual Adjustments
function AdjustmentsFormFields(isChecked, strType) {
    
    var component = true;

    if (isChecked) 
    {
        component = false;
    }

    if (strType == "grades") 
    {
        for (var i = 0; i < document.getElementById("GradesGroup").getElementsByTagName("input").length; i++)
        {
            document.getElementById("GradesGroup").getElementsByTagName("input")[i].disabled = component;
        }
    }

    if (strType == "tonnes")
    {
        document.getElementById("TonnesGroup").getElementsByTagName("select")[0].disabled = component;
        
        for (var j = 0; j < document.getElementById("TonnesGroup").getElementsByTagName("input").length; j++) 
        {
            document.getElementById("TonnesGroup").getElementsByTagName("input")[j].disabled = component;
        }
    }
}

function GetStockpileManualAdjustmentList() {

    calMgr.formatDate(document.ManualAdjustments.AdjustmentDateFromText, CalendarControls.Lookup('AdjustmentDateFrom').dateFormat);
    calMgr.formatDate(document.ManualAdjustments.AdjustmentDateToText, CalendarControls.Lookup('AdjustmentDateTo').dateFormat);
    
	ClearElement('itemList');
	SubmitForm('ManualAdjustments', 'itemList', './StockpileManualAdjustmentList.aspx', 'image');
	return false;
}

function ValidateStockpileManualAdjustmentList() {

    if (ValidateStockpileManualAdjustmentFilterValues())
        GetStockpileManualAdjustmentList();
    
    return false;
}

function ValidateStockpileManualAdjustmentFilterValues() {
    
    var success = true;
    var currentDate = new Date();
    var alertStr = "";    
    var startDate = document.getElementById("AdjustmentDateFromText").value;
    var endDate = document.getElementById("AdjustmentDateToText").value;
    
    startDate = calMgr.getDateFromFormat(startDate, calMgr.defaultDateFormat);
    endDate = calMgr.getDateFromFormat(endDate, calMgr.defaultDateFormat);
    
    if (startDate > currentDate) {
        alertStr = alertStr + '- Date From cannot be later than Current Date \n';
        success = false;
    }
    
    if (endDate > currentDate) {
        alertStr = alertStr + '- Date To cannot be later than Current Date \n';
        success = false;
    }
    
    if(startDate != "" && endDate != "")
    {
         if( startDate > endDate)
         {
            alertStr = alertStr + '- Date From cannot be later than Date To \n';
            success = false;  
         }
    }        
        
    if (alertStr != "") {
        alertStr = 'Please Fix the following Errors : \n' +alertStr ;
        alert(alertStr);
    }
        
    return success;
}

function GetStockpileFilterListByLocation() {

    var locationControl = document.getElementById("LocationId");
    var stockpileId = $("#StockpileId").val();

    CallAjax('sourceDiv', './GetStockpileManualAdjustmentStockpile.aspx?LocationId='+locationControl.value+'&StockpileId='+stockpileId, 'image');

    return false;
}


function DeleteStockpileAdjustment(stockpileAdjustmentId)
{
	if(confirm('Are you sure you wish to delete this adjustment?'))
	{
		CallAjax('', './StockpileManualAdjustmentDelete.aspx?StockpileAdjustmentID='+stockpileAdjustmentId);
	}

	return false;
}

function ToggleTonnesAdjustment(isChecked)
{
	if(isChecked)
	{
		ForceShow('TonnesGroup');
	}
	else
	{
		ForceHide('TonnesGroup');
	}

	return true;
}

function ToggleGradesAdjustment(isChecked)
{
	if(isChecked)
	{
		ForceShow('GradesGroup');
	}
	else
	{
		ForceHide('GradesGroup');
	}

	return true;
}

function ToggleReasonDropType(obj, init) {
    var type;

    if (init == 1) 
    {
        type = "0";
    }

    else 
    {
        type = obj.options[obj.selectedIndex].value;
    }

    switch (type) 
    {
        case "0":
            document.getElementById("Reason").value = "The balance is negative.";
            document.getElementById("Reason").disabled = true;
            break;
        case "1":
            document.getElementById("Reason").value = "The balance is zero.";
            document.getElementById("Reason").disabled = true;
            break;
        case "2":
            document.getElementById("Reason").value = "";
            document.getElementById("Reason").disabled = false;
            document.getElementById("Reason").focus();
            break;
        default:
            document.getElementById("Reason").value = "";
    }
}

function ToggleTonnesAdjustmentType(obj, checkType) {
    var type = obj.options[obj.selectedIndex].value;
	
	if(type == checkType)
	{
		ForceShow('TonnesAddRemove');
	}
	else
	{
	    ForceHide('TonnesAddRemove');

	    if (type == 2) // reset to zero
	    {
	        document.getElementById("TonnesGroup").getElementsByTagName("input")[0].value = 0;
	    }
	    //else 
	    //{
	    //    document.getElementById("TonnesGroup").getElementsByTagName("input")[0].value = "";
	    //}
	}
}

function RedirectToStockpilePage(stockpileID)
{
	window.location = './StockpileDetails.aspx?StockpileId='+stockpileID;
	return false;
}

function SaveStockpileAdjustment()
{
	SubmitForm('AdjustmentForm', '', './StockpileManualAdjustmentSave.aspx');	
	return false;
}

function ViewStockpileAdjustment(stockpileID, stockpileAdjustmentID)
{
	document.location = './StockpileManualAdjustmentEdit.aspx?StockpileId='+stockpileID+'&StockpileAdjustmentId='+stockpileAdjustmentID;
	return false;
}

function MoveStockpileFilter(targetDiv)
{
	var filterBox = document.getElementById('StockpileDetailsFilterBox');
	var target = document.getElementById(targetDiv);
	target.className = "stockpileTabFilter";
	
	if(filterBox != null && filterBox != 'undefined')
	{
		target.appendChild(filterBox);
		ForceShow(filterBox.id);
    }
}

//Stockpile Transfers
function GetStockpileBuilds(stockpileCtrl, buildDiv, targetId)
{
	var stockpileId = stockpileCtrl.options[stockpileCtrl.selectedIndex].value;
	var qryStr = 'StockpileId=' + stockpileId + '&TargetId=' + targetId;

	CallAjax(buildDiv, './StockpileTransferGetBuilds.aspx?'+qryStr, 'image');
}

function SaveTransfer(){
	var returnValue = false;
	
	AIM.submit(document.getElementById('TransferForm'), './StockpileTransferCheckTonnes.aspx', {'onComplete' : completeTonnesCheckCallback});
	document.getElementById('TransferForm').submit();
	return false;
}

function completeTonnesCheckCallback(response) {   
    var returnValue = false;
	
    if (Trim(response) == '')
	{
		returnValue = true;		
    }
	else
	{
		eval(response);
    }

	if(returnValue)
	{
		SubmitForm('TransferForm', '', './StockpileTransferSave.aspx'); 
	}

	return false;
}   

function ViewStockpileTransfer(stockpileAdjustmentId)
{
	document.location = './StockpileTransfer.aspx?StockpileAdjustmentId='+stockpileAdjustmentId;
	return false;
}

//Stockpile Surveys
function GetStockpileSurveyList()
{
	ClearElement('itemDetail');
	SubmitForm('StockpileSurveyForm', 'itemList', './StockpileSurveyList.aspx');
	return false;
}

function AddStockpileSurvey()
{
	ClearElement('itemDetail');
	CallAjax('itemDetail', './StockpileSurveyAdd.aspx');
	return false;
}

function SaveStockpileSurvey()
{
	SubmitForm('SurveyAddForm', 'itemDetail', './StockpileSurveySave.aspx');
	return false;
}

function ViewStockpileSurvey(surveyDate, surveyShift, surveyType)
{
	var qryStr = './StockpileSurveyView.aspx?SurveyDate='+surveyDate+
		'&SurveyShift='+surveyShift+
		'&SurveyTypeId='+surveyType;

	ClearElement('itemDetail');
	CallAjax('itemDetail', qryStr);
}

function DeleteStockpileSurvey(surveyDate, surveyShift, surveyType)
{
	var qryStr = './StockpileSurveyDelete.aspx?SurveyDate='+surveyDate+
		'&SurveyShift='+surveyShift+
		'&SurveyTypeId='+surveyType;

	if (confirm('Are you sure you wish to remove this survey? ('+surveyDate+', '+surveyShift+', '+surveyType+')'))
		CallAjax('', qryStr);

	return false;
}

function EditStockpileSurvey(surveyDate, surveyShift, surveyType)
{
	var qryStr = './StockpileSurveyDetail.aspx?SurveyDate='+surveyDate+
		'&SurveyShift='+surveyShift+
		'&SurveyTypeId='+surveyType;

	document.location = qryStr;

	return false;
}

function SaveAndApproveStockpileSurvey(surveyDate, surveyShift, surveyType)
{
	if (confirm('Are you sure you wish to approve this survey? ('+surveyDate+', '+surveyShift+', '+surveyType+')'))
	{
		SaveStockpileSurveySamples(true);
	}

	return false;
}

//Called from Save
function ApproveStockpileSurvey(surveyDate, surveyShift, surveyType)
{
	var qryStr = './StockpileSurveyApprove.aspx?SurveyDate='+surveyDate+
		'&SurveyShift='+surveyShift+
		'&SurveyTypeId='+surveyType+
		'&Approve=1';

	CallAjax('', qryStr);

	return false;
}

function UnapproveStockpileSurvey(surveyDate, surveyShift, surveyType)
{
	var qryStr = './StockpileSurveyApprove.aspx?SurveyDate='+surveyDate+
		'&SurveyShift='+surveyShift+
		'&SurveyTypeId='+surveyType+
		'&Approve=0';

	if (confirm('Are you sure you wish to unapprove this survey? ('+surveyDate+', '+surveyShift+', '+surveyType+')'))
		CallAjax('', qryStr);

	return false;
}

function SaveStockpileSurveySamples(approve)
{
	if(approve)
	{
		SubmitForm('surveyForm', '', './StockpileSurveySaveSample.aspx?Approve=1');
	}
	else
	{
		SubmitForm('surveyForm', '', './StockpileSurveySaveSample.aspx?Approve=0');
	}
	
	return false;
}

function CalculateReconciled(elementId, threshhold)
{
	var balanceDiv = document.getElementById('Balance_'+elementId);
	var surveyInp = document.getElementById('Survey_'+elementId);
	var diffDiv = document.getElementById('Difference_'+elementId);

	var balance, survey, diff;
	var retText;
	
	//Check the balance isnt null
	if(balanceDiv.innerHtml != '')				 
	{
		balance = balanceDiv.innerHTML.replace(/,/g, '');
	}
	else
	{
		balance = 0;
	}
	
	//Check the input to text box is valid
	if(surveyInp.value != '')
	{
		survey = surveyInp.value;
	}
	else
	{
		survey = balance;
	}

	//Calculate the difference and add the commas back in
	diff = survey - balance;
	retText = addCommas(diff)
	
	//If the difference is below zero make it red
	if(diff > threshhold || diff < (threshhold * -1))
	{
		retText = '<font color=red>' + retText + '</font>'
	}	

	//Reset the difference Div
	diffDiv.innerHTML = retText;
}

function RedirectToStockpileSurveyList()
{
	document.location = './StockpileSurveyAdministration.aspx'
}

function ResetStockpileFilters(locationDivId, locationWidth) {
    var stateType, stockpileIdFilter, stockpileDateFrom, stockpileDateTo, materialType;

    stateType = document.getElementById('StateType');
    materialType = document.getElementById('MaterialTypeId');
    stockpileIdFilter = document.getElementById('StockpileIdFilter');
    stockpileDateFrom = document.getElementById('StockpileDateFromText');
    stockpileDateTo = document.getElementById('StockpileDateToText');

    if (stateType) { stateType.selectedIndex = 0; }
    if (materialType) { materialType.selectedIndex = 0; }
    if (stockpileIdFilter) { stockpileIdFilter.value = ''; }
    if (stockpileDateFrom) { stockpileDateFrom.value = ''; }
    if (stockpileDateTo) { stockpileDateTo.value = ''; }

    LoadLocation(false, 0, locationDivId, locationWidth, true, 'LocationId');
}