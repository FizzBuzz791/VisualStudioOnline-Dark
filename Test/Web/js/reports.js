//Report scripts
function SaveReportBoxCollapseSetting(GroupBoxImage, UserSettingTypeId){
	var SettingValue;
	
	if (GroupBoxImage.src.indexOf('minus.png') == -1){
		SettingValue = 'True'
	}else{
		SettingValue = 'False'
	}
	
	SaveUserSetting(UserSettingTypeId, SettingValue);
	
	return false;
}

function RenderStandardReport(reportId)
{
	CallAjax('reportDetail', './ReportsStandardRender.aspx?ReportId='+reportId, 'image');
	return false;
}

function FillNameParameter(dropdown, targetName)
{
    var target = document.getElementById(targetName);
    
    if (target && dropdown.selectedIndex >= 0)
    {
        target.value = dropdown.options[dropdown.selectedIndex].text;
    }
}

function RunReport(reportId) {
    if (document.getElementById('iStartDateText') != null)
        calMgr.formatDate(document.ReportForm.iStartDateText, CalendarControls.Lookup('iStartDate').dateFormat);

    if (document.getElementById('iEndDateText') != null)
        calMgr.formatDate(document.ReportForm.iEndDateText, CalendarControls.Lookup('iEndDate').dateFormat);

	if(ValidateData())
	{
		document.getElementById('ReportForm').action = 'ReportsRun.aspx?ReportId=' + reportId;
		return true;
	}
	else
	{
		return false;
	}
}

//Report Administration Scripts
function AddNewReportGroup(){
	CallAjax('itemDetail', './ReportGroupEdit.aspx');
	return false;
}

function DeleteReportGroup(ReportGroupId, Description){
	ClearElement('itemDetail');
	
	if(confirm('Delete the report group \'' + Description + '\'')){
		CallAjax('', './ReportGroupDelete.aspx?rgId=' + ReportGroupId);
	}
	
	return false;
}

function EditReport(ReportId){
	CallAjax('itemDetail', './ReportEdit.aspx?rId=' + ReportId);
	return false;
}

function DeleteReport(ReportId){
	if(confirm('Do you wish to delete this report?')){
		CallAjax('itemDetail', './ReportDelete.aspx?rId=' + ReportId);
	}
	return false;
}

function EditReportGroup(ReportGroupId){
	CallAjax('itemDetail', './ReportGroupEdit.aspx?rgId=' + ReportGroupId);
	return false;
}

function GetReportGroupList(){
	CallAjax('reportGroupContent', './ReportGroupList.aspx');
	return false;
}

function GetReportGroupTabContent(){
	ClearElement('itemDetail');
	CallAjax('sidenav_layout_nav_container', './ReportGroupSideNavigation.aspx');
	GetReportGroupList();
	return false;
}

function GetReportTabContent(){
	ClearElement('itemDetail');
	CallAjax('sidenav_layout_nav_container', './ReportSideNavigation.aspx');
	GetReportList();
	return false;
}

function GetReportList(){
	CallAjax('reportContent', './ReportList.aspx');
	return false;
}

// If there is a problem with SSRS, display a friendly message and take the 
// user back to the previous page
function DisplayErrorForSSRS(errorMessage) 
{
    document.body.innerHTML = '';

    if (confirm(errorMessage)) 
    {
        window.location = "../"; // Take the user back to the home screen
    }
}