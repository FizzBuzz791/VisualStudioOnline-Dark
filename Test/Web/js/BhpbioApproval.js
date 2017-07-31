//Approval scripts

function ClearApprovalList(id) {
    var elem = document.getElementById('itemList')
    if (elem != null) {
        elem.innerHTML = '';
        HideApprovalList();
    }
}

function ChangedLocationApprovalBlockList(id) {
    var limitDisableLocationType = 'Pit';
    var locationTypeInput = document.getElementById('LocationTypeDescription');
    var limitInput = document.getElementById('LimitRecords');

    // Clear the list like the other screens.
    ClearApprovalList(id);

    // If the location is at the pit level, disable the record limiter.
    if (locationTypeInput && limitInput) {
        if (locationTypeInput.value == limitDisableLocationType) {
            if (locationTypeInput.oldValue != limitDisableLocationType)
                limitInput.oldChecked = limitInput.checked;
            limitInput.disabled = true;
            limitInput.checked = false;
        }
            // If it is not at the pit level, see if it just came from the pit and then restore it.
        else if (limitInput.disabled) {
            limitInput.disabled = false;
            limitInput.checked = limitInput.oldChecked;
        }
    }
    locationTypeInput.oldValue = locationTypeInput.value;
}

function ShowApprovalList(text) {
    var helpBox = document.getElementById('ApprovalHelpBox');
    var helpBoxContent = document.getElementById('ApprovalHelpBoxContent');
    if (helpBox && helpBoxContent && text != '') {
        helpBoxContent.innerHTML = text;
        helpBox.style.display = 'block';
    }
}

function HideApprovalList() {
    var helpBox = document.getElementById('ApprovalHelpBox');
    var helpBoxContent = document.getElementById('ApprovalHelpBoxContent');
    if (helpBox && helpBoxContent) {
        helpBoxContent.innerHTML = '';
        helpBox.style.display = 'none';
    }
}

function GetApprovalDigblockList() {
    if (ValidateDateParameters()) {
        HideApprovalList();
        SubmitForm('approvalForm', 'itemList', './ApprovalDigblockList.aspx', 'image');
    }
    return false;
}

function LoadBlastBlock(locationId, monthString) {
    var qryStr = '?LocationId=' + locationId + '&LimitRecords=666' + '&MonthValue=' + monthString;
    CallAjax('sidenav_layout_content_container', './ApprovalDigblockList.aspx' + qryStr);
}

function ApproveDigblock() {
    SubmitForm('approvalForm', '', './ApprovalDigblockUpdate.aspx', '');
}

function GetApprovalDataList() {
    if (ValidateDateParameters()) {
        HideApprovalList()
        SubmitForm('approvalForm', 'itemList', './ApprovalDataList.aspx', 'image');
    }
    return false;
}

function GetOutlierAnalysisApprovalGrid(locationid, MonthStart, first, limitToSubLocationOnly) {
    var called = document.getElementById("GridShown");
    var e = document.getElementById("itemOutlier");
    var i = document.getElementById("outlierimg");
    var qryStr = '?location=' + locationid +
       '&MonthValueStart=' + MonthStart;

    if (limitToSubLocationOnly == true) {
        qryStr = qryStr + '&limitSubLocationOnly=true'
    }

    if (first == 1) {
        i.innerHTML = '<img src="../images/plus.png">';
        return false;
    }
    if (e.style.display == 'block') {
        i.innerHTML = '<img src="../images/plus.png">';
        e.style.display = 'none';
    }
    else {
         i.innerHTML = '<img src="../images/minus.png">';
        e.style.display = 'block';
        if (called.value == 0) {
            CallAjax('itemOutlier', '../Analysis/OutlierAnalysisGrid.aspx' + qryStr);
            called.value = 1
        }
    }
}

function GetApprovalOtherList() {
    if (ValidateDateParameters()) {
        HideApprovalList();
        SubmitForm('approvalForm', 'itemList', './ApprovalOtherList.aspx', 'image');
    }
    return false;
}

function ApproveData() {
    SubmitForm('approvalForm', '', './ApprovalDataUpdate.aspx', '');
}

function ApproveOtherMovement() {
    SubmitForm('approvalForm', '', './ApprovalDataUpdate.aspx?Other=True', '');
}

function ValidateDateParameters() {
    var success = true;
    var alertStr = "";
    var currentDate = new Date();

    var month = document.getElementById("MonthPickerMonthPart").value;
    var year = document.getElementById("MonthPickerYearPart").value;

    var selectedDate = new Date(year, GetMonthFromString(month), 1);

    if (selectedDate > currentDate) {
        alertStr = alertStr + '- Start Date cannot be later than Current Date \n';
        success = false;
    }

    if (alertStr != "") {
        alertStr = 'Please Fix the following Errors : \n' + alertStr;
        alert(alertStr);
    }

    return success;
}

function GetMonthFromString(monthAsString) {
    var month;
    switch (monthAsString) {
        case "Jan": month = 0; break;
        case "Feb": month = 1; break;
        case "Mar": month = 2; break;
        case "Apr": month = 3; break;
        case "May": month = 4; break;
        case "Jun": month = 5; break;
        case "Jul": month = 6; break;
        case "Aug": month = 7; break;
        case "Sep": month = 8; break;
        case "Oct": month = 9; break;
        case "Nov": month = 10; break;
        case "Dec": month = 11; break;
    }

    return month;
}

// Will match the approval click with other check box's with the same locationId and TagId.
function MatchClickByName(checkBox) {
    var rowId = checkBox.id.replace('approved_', '');
    var tagId = document.getElementById('approvedTagId_' + rowId);
    var locationId = document.getElementById('approvedLocation_' + rowId);
    var currentRowId;
    var currentTagId;
    var currentLocationId;
    var checkboxes;

    // If the current check box has a valid tagId and locationId
    if (tagId && locationId) {
        // For each checkbox which isn't itself and has approved_ as the start of it's id.
        checkboxes = document.getElementsByTagName('INPUT');
        for (i = 0; i < checkboxes.length; i++) {
            if (checkboxes[i].type.toLowerCase() == 'checkbox' && checkboxes[i].id != checkBox.id
             && checkboxes[i].id.indexOf('approved_') != -1) {
                // obtain this row's tagId and location id
                currentRowId = checkboxes[i].id.replace('approved_', '');
                currentTagId = document.getElementById('approvedTagId_' + currentRowId);
                currentLocationId = document.getElementById('approvedLocation_' + currentRowId);
                if (currentTagId && currentLocationId) {
                    // check to see if its the same as the inital checkbox and if it is match them.
                    if (tagId.value == currentTagId.value && locationId.value == currentLocationId.value) {
                        checkboxes[i].checked = checkBox.checked;
                    }
                }
            }
        }
    }
}

function ToggleApprovalCheckboxes(CheckBox, NamePart, message) {
    var checkboxes = document.getElementsByTagName('INPUT');
    var proceed = true;
    if (message) {
        proceed = confirm(message);
    }

    if (proceed) {
        for (i = 0; i < checkboxes.length; i++) {
            if (checkboxes[i].type.toLowerCase() == 'checkbox' && checkboxes[i].id.indexOf(NamePart) != -1) {
                if (!checkboxes[i].disabled) {
                    checkboxes[i].checked = CheckBox.checked;
                }
            }
        }
    }
    else {
        CheckBox.checked = !CheckBox.checked;
    }

}

function ApprovalInvestigationFilter(tagId) {
    //ApprovalInvestigationFilter
    var dateFromVal, dateToVal, productSize;
    var dateFrom = document.getElementsByName('FilterDateFromText');
    var dateTo = document.getElementsByName('FilterDateToText');
    var location = document.getElementById('LocationPicker');
    var product = document.getElementById('ProductFilter');

    productSize = product.value;

    var url = '?TagId=' + tagId;

    if (dateFrom[0])
        dateFromVal = dateFrom[0].value;
    if (dateTo[0])
        dateToVal = dateTo[0].value;

    if (dateFrom)
        url += '&DateFrom=' + dateFromVal;
    if (dateTo)
        url += '&dateTo=' + dateToVal;
    url += '&LocationId=' + location.value;
    url += '&ProductSize=' + productSize;

    window.location = url;
}

/* Approval Tree Load */
function ToggleApprovalNode(nodeRowId, nodeLevel, calcId, locationId, approvalMonth) {
    if (!ApprovalToggleNode(nodeRowId)) {
        AddLoadingImage(nodeRowId);
        GetApprovalNode(nodeRowId, nodeLevel, calcId, locationId, approvalMonth);
    }
}

function GetApprovalNode(nodeRowId, nodeLevel, calcId, locationId, approvalMonth) {
    var qryStr = '../Approval/ApprovalDataListNode.aspx';

    qryStr += '?NodeRowId=' + nodeRowId;
    qryStr += '&NodeLevel=' + nodeLevel;
    qryStr += '&CalcId=' + calcId;
    qryStr += '&LocationId=' + locationId;
    qryStr += '&ApprovalMonth=' + approvalMonth;

    CallAjax('itemStage', qryStr);
}

function AppendApprovalNodes(nodeRowId) {
    var stage = document.getElementById('StageTable');
    var curRow = document.getElementById(nodeRowId);
    var endRow = document.getElementById(nodeRowId + 'End');
    var table = curRow.parentNode;
    var img = document.getElementById(nodeRowId.replace('Node_', 'Image_'));

    if (endRow) {
        curRow = endRow;
    }

    RemoveLoadingImage(table, nodeRowId);
    AppendNodeRows(stage, table, curRow);

    //Check to see if it is expanded. If it isn't then make sure the newly added rows are also hidden.
    if (img && img.src.match("plus")) {
        return ApprovalCollapseNodeRow(nodeRowId);
    }

    document.getElementById('itemStage').innerHTML = '';
}

/* Other Movement Approval Tree Load */
function ToggleApprovalOtherNode(nodeRowId, nodeLevel, locationId, approvalMonth) {
    if (!ApprovalToggleNode(nodeRowId)) {
        AddLoadingImage(nodeRowId);
        GetApprovalOtherNode(nodeRowId, nodeLevel, locationId, approvalMonth);
    }
}

function GetApprovalOtherNode(nodeRowId, nodeLevel, locationId, approvalMonth) {
    var qryStr = '../Approval/ApprovalOtherListNode.aspx';
    qryStr += '?NodeRowId=' + nodeRowId;
    qryStr += '&NodeLevel=' + nodeLevel;
    qryStr += '&LocationId=' + locationId;
    qryStr += '&ApprovalMonth=' + approvalMonth;
    CallAjax('itemStage', qryStr);
}

/* Shared tree calls */
function ApprovalToggleNode(nodeRowId) {
    //Update this image
    var imgId = nodeRowId.replace('Node_', 'Image_');
    var img = document.getElementById(imgId);

    if (img) {
        if (img.src.match("plus")) {
            img.src = '../images/minus.png';
            return ApprovalExpandNode(nodeRowId);
        }
        else {
            img.src = '../images/plus.png';
            return ApprovalCollapseNodeRow(nodeRowId);
        }
    }
}

function AddLoadingImage(nodeRowId) {
    var stage = document.getElementById('itemStage');
    var html = '<TD colspan=11 align=center><img src="../images/loading.gif" height=18></TD>'
    html = '<TABLE id=StageTable border=0><TR id=' + nodeRowId + '_Loading>' + html + '</TR></TABLE>'
    if (stage) {
        stage.innerHTML = html;
        AppendApprovalNodes(nodeRowId);
    }
}

function RemoveLoadingImage(table, nodeRowId) {
    var loadingNode = document.getElementById(nodeRowId + '_Loading');

    if (loadingNode && loadingNode.parentNode == table) {
        table.deleteRow(loadingNode.rowIndex);
    }
}

function ApprovalCollapseNodeRow(nodeRowId) {
    var curRow = document.getElementById(nodeRowId);
    var table = curRow.parentNode;

    if (table.childNodes) //item 0 will be the tbody
    {
        var rows = table.childNodes;

        for (var i = 0; i < rows.length; i++) {
            //Child nodes will be nodeRowId + '_<RecordId>' so look for anything at that level
            if ((rows[i].id.match(nodeRowId + '~') || rows[i].id.match(nodeRowId + '_')) && rows[i].id != nodeRowId) {
                ForceHide(rows[i].id);
            }
        }
    }

    return true;
}

function ApprovalExpandNode(nodeRowId) {
    var curRow = document.getElementById(nodeRowId);
    if (curRow == null)
        return;

    var table = curRow.parentNode;
    var found = false;
    var imgId;

    //Check for Nodes that already exist
    if (table.childNodes) //item 0 will be the tbody
    {
        var rows = table.childNodes;

        //Show the nodes	
        for (var i = 0; i < rows.length; i++) {
            //Child nodes will be nodeRowId + '~<RecordId>' so look for anything at that level
            if ((rows[i].id.match(nodeRowId + '~') || rows[i].id.match(nodeRowId + '_')) && rows[i].id != nodeRowId) {

                var matchChar = rows[i].id.match(nodeRowId + '_') ? '_' : '~';

                //Find the image of this nodes parent and make sure its expanded before I show it
                imgId = rows[i].id.replace('Node_', 'Image_').replace('~End', '');
                imgId = imgId.substr(0, imgId.lastIndexOf(matchChar));
                img = document.getElementById(imgId);

                if (img) //Make sure we found 1
                {
                    if (img.src.match('minus')) {
                        ForceShow(rows[i].id);
                        found = true;
                    }
                }
            }
        }
    }

    //return whether we found any nodes already there
    return found;
}

window.GetReconcilorTableToCsvSubmit = function (tableId) {

    var HeaderTable = document.getElementById('HeaderTable_' + tableId);
    var BodyTable = document.getElementById('BodyTable_' + tableId);
    var CsvData;
    var scriptReg = new RegExp('(\<(/?[^\>]+)\>)', 'gi');
    var scriptTitleReg = new RegExp('<([^ >]+)[^>]*title="([^">]*)"[^>]*>[^<]*</[^>]*>', 'gi');
    var newLinesReg = new RegExp('.&#13;&#10;', 'gi');
    var input = document.createElement('input');
    var form = document.createElement('form');

    form.id = 'form_' & tableId;
    form.method = 'post';
    form.action = '../Utilities/ExportCsvData.aspx';

    input.type = 'hidden';
    input.id = 'CsvData';
    input.name = 'CsvData';

    CsvData = HeaderTable.innerHTML.replace(/(\r\n|&nbsp;|,)/gi, '').replace(/\<\/th\>\<th/gi, ',<').replace(/\<br\s*\/?\>/gi, ' ').replace(scriptReg, '').replace(/↓/gi, '');
    CsvData = CsvData.substring(0, CsvData.length - 1) + '\r\n' + BodyTable.innerHTML
        .replace(/(\r\n|&nbsp;|,)/gi, '')
        .replace(/\<\/tr\>\<tr\>/gi, '\r\n')
        .replace(/\<\/tr\>\<tr\s*.+?\>/gi, '\r\n') // new to pick up rows with ids and other attributes
        .replace(/\<\/td\>\<td\s*(style=\"[\w\s;]+\"\s*)?(class=[\"\w]+\s*)?\>/gi, ',')
        .replace(/(sqlBox\.gif|sqlCross\.gif)/gi, '>False<')
        .replace(/sqlTick\.gif/gi, '>True<')
        .replace(scriptTitleReg, '$2')
        .replace(scriptReg, '')
        .replace(newLinesReg, '  ');

    input.value = CsvData;

    form.appendChild(input);
    document.appendChild(form);
    form.submit();

    input = null;
    form = null;

}

// This function is *only* used by the ApprovalBulk screen/buttons.
function ApproveOrUnapprove(approveUnapprove) {
    //Prevent clicking on disabled buttons
    if( document.getElementById('BulkApprovalForm').disabled )
        return false;

    var locationControl = document.getElementById("LocationId");
    if (locationControl == null || locationControl.value == '') {
        alert('Select site first')
        return false;
    }

    var alertContent = approveUnapprove + ' from ' + $('#MonthValueFrom').val().replace('1-', '') + ' to ' + $('#MonthValueTo').val().replace('1-', '')

    var highestLocationText = $('#HighestLocationType option:selected').text();
    var lowestLocationText = $('#LowestLocationType option:selected').text();

    if (highestLocationText == lowestLocationText) {
        alertContent += ' for ' + lowestLocationText + 's';
    } else {
        alertContent += ' from ' + highestLocationText + ' to ' + lowestLocationText;
    }
    
    alertContent += ' under ' + $('#BulkApproveLocationNameDynamic').val();

    if (confirm('Are you sure you want to ' + alertContent + '?')) {
        SubmitForm('BulkApprovalForm', 'itemDetail', './ApprovalBulkSubmit.aspx?Type=' + approveUnapprove + '&IsBulk=true');
    }
    return false;
}

function DisplayApprovalProgress(approvalId, isBasicView) {
    var elementToDisable = document.getElementById('BulkApprovalForm');
    if (elementToDisable !== null) {
        elementToDisable.setAttribute('disabled', 'disabled');
    }

    var elementToShow = document.getElementById('itemDetail');
    if (elementToShow !== null) {
        elementToShow.style.display = 'block';
    }

    UpdateApprovalProcess(approvalId, isBasicView);
}

function UpdateApprovalProcess(approvalId, isBasicView) {
    url = './ApprovalProgress.aspx?ApprovalId=' + approvalId;
    if (isBasicView != null) {
        url += '&IsBasicView='+isBasicView;
    }
    CallAjax('itemDetail', url);
}

function UpdateApprovalProcessDelayed(approvalId, isBasicView, delayMs) {
    delayMs = delayMs || 1000;

    setTimeout(function () {
        UpdateApprovalProcess(approvalId, isBasicView);
    }, delayMs);
}

function LoadApprovalSummary() {
    var numberPreviousMonths = 2;
    var month = document.getElementById('MonthPickerMonthPart').selectedIndex;
    var year = document.getElementById('MonthPickerYearPart').options[document.getElementById('MonthPickerYearPart').selectedIndex].value;

    var date = new Date(year, month, 1);
    if (date <= new Date()) {
        var dateString = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();

        var url = './ApprovalSummaryList.aspx?SelectedMonth=' + dateString + '&NumberPreviousMonths=' + numberPreviousMonths;
        CallAjax('sidenav_layout_content_container', url, 'image');
        document.getElementById('sidenav_layout_content_container').setAttribute('align', 'left');
    } else {
        alert("The selected month cannot be after the current month.")
    }
    return false;
}

function LoadDefaultApprovalSummary() {
    //Called when the tab Approvals is hit
    var url = './ApprovalSummaryList.aspx'
    CallAjax('sidenav_layout_content_container', url, 'image');
    document.getElementById('sidenav_layout_content_container').setAttribute('align', 'left');
    return false;
}

function _LoadFactorApprovalScreen() {
    var month = document.getElementById('MonthPickerMonthPart').selectedIndex;
    var year = document.getElementById('MonthPickerYearPart').options[document.getElementById('MonthPickerYearPart').selectedIndex].value;

    var date = new Date(year, month, 1);
    if (date <= new Date()) {
        var dateString = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();

        var location = document.getElementById('LocationIdDynamic');
        if (location == null) {
            alert('Location control not found');
        }

        return LoadFactorApprovalScreen(dateString, location.value);
    } else {
        alert("The selected month cannot be after the current month.")
    }
}

function LoadFactorApprovalScreen(dateString, locationId) {
    var url = './ApprovalFactorList.aspx?SelectedMonth=' + dateString + '&LocationId=' + locationId.toString();

    CallAjax('sidenav_layout_content_container', url, 'image');

    document.getElementById('sidenav_layout_content_container').setAttribute('align', 'left');
    return false;
}

//Some prototype to preload the single tabs...
function PreLoadKtoNSections(locationIdList) {
    //var locationIds = locationIdList.split(",");
    //for(var a in locationIds) {
    //    var element = document.createElement('div');
    //    element.setAttribute("type", "hidden");

    //    element.id = 'LocationTabPage_' + locationIds[a];
    //    var url = './ApprovalFactorListTabPage.aspx?LocationId=' + locationIds[a];
             
    //    //var msg = 'Loaded '+element.id.toString+')';
    //    //CallAjax(element.id, url, 'image', ' alert('+msg+')');
    //}
}

function LoadTabPageContentDiv(tabPageId, locationId, month) {
    var content = document.getElementById('TabPageContentDiv');

    var page = document.getElementById(tabPageId);
    if (page ==null) {
        return;
    }

    page.appendChild(content)

    var locationName = GetElementValue('LocationName');
    var locationType = GetElementValue('LocationTypeDescription');

    var url = './ApprovalFactorListTabPage.aspx?LocationId=' + locationId + '&SelectedMonth=' + month + '&LocationName=' + locationName + '&LocationType=' + locationType;
    CallAjax('TabPageContentDiv', url, 'image');
}

function GetElementValue(id) {
    var e = document.getElementById(id);

    if (e) {
        return e.value;
    } else {
        return null;
    }
}

// This function is only used by the Approve button on the main approval screen
function ApproveAll(location, monthString) {
    var statementCheck = document.getElementById('chkStatement');
    if (statementCheck !== null) {
        if (statementCheck.checked) {
            statementCheck.setAttribute('disabled', 'disabled');
            var approveButton = document.getElementById('ApproveInputButton');
            if (approveButton !== null) {
                approveButton.setAttribute('disabled', 'disabled');
                CallAjax('itemDetail', './ApprovalBulkSubmit.aspx?Type=Approve&LocationId=' + location + '&MonthValue=' + monthString + '&IsBasicView=true&IsBulk=false');
            }
        } else {
            alert("Please check the box to confirm you have reviewed the data.");
        }
    }
}

// This function is only used by the Unapprove button on the main approval screen
function UnapproveAll(location, monthString, isBulk) {
    var elementToDisable = document.getElementById('UnapproveInputButton');
    if (elementToDisable != null)
        elementToDisable.setAttribute('disabled', 'disabled');
    elementToDisable = document.getElementById('chkStatement');
    if (elementToDisable != null)
        elementToDisable.setAttribute('disabled', 'disabled');

    CallAjax('itemDetail', './ApprovalBulkSubmit.aspx?Type=Unapprove&LocationId=' + location + '&MonthValue=' +monthString + '&IsBasicView=true&IsBulk=false');
}

//executed once approval tab page section is opened
function LoadOnExpand(element, sectionName, url) {
    if (element.src.indexOf('minus.png') == -1)//same approach as core
        return;

    //This code executed on expand group 
    CallAjax(sectionName, url, 'image');
}