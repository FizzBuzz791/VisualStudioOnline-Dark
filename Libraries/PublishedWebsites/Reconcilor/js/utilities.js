var numberOfMessageWindowsOpened;
numberOfMessageWindowsOpened = 0

//Event Scripts
function GetEventList() {
    //SubmitForm('eventForm', 'eventList', './EventList.aspx', 'image');
    SubmitFormWithDateValidation(false, 'eventForm', 'eventList', './EventList.aspx', 'image');
    ClearElement('eventDetail');
    return false;
}

function GetEventDetail(AuditHistoryId) {
    CallAjax('eventDetail', './EventDetail.aspx?AuditHistoryId=' + AuditHistoryId, 'image');
    return false;
}

function PopulateAuditType() {
    CallAjax('', './EventAuditTypeList.aspx?atgId=' + document.getElementById('AuditTypeGroup').value)
    return false;
}

//Haulage Correction
function AddNameResolution(locationId) {
    locationId = document.getElementById('LocationId').value;
    CallAjax('itemDetail', './HaulageCorrectionNameResolutionAddDate.aspx?lid=' + locationId);
    return false;
}

function DeactivateNameResolution(haulageResolveBasicId) {
    var locationId = document.getElementById('LocationId').value;
    CallAjax('itemDetail', './HaulageCorrectionNameResolutionDeactivate.aspx?HaulageResolveBasicId=' + haulageResolveBasicId + '&lid=' + locationId);
    return false
}

function DeleteNameResolution(haulageResolveBasicId) {
    var locationId = document.getElementById('LocationId').value;
    if (confirm('Are you sure you want to delete this name resolution?')) {
        CallAjax('itemDetail', './HaulageCorrectionNameResolutionDelete.aspx?HaulageResolveBasicId=' + haulageResolveBasicId + '&lid=' + locationId);
    }
}

function ViewJob(JobId) {
    CallAjax('itemDetail', './ImportJobDetail.aspx?jID=' + JobId);
    return false;
}

function CorrectBulkHaulageError() {
    var Type = document.getElementById('Action').value;
    var SelectBoxId = 'Old' + Type;
    var SelectBox = document.getElementById(SelectBoxId);
    var OldValue = SelectBox.options[SelectBox.selectedIndex].value;
    var NewValue;
    var prefix;
    var checkboxes;
    var controlName;

    if (Type == 'Source') {
        prefix = 'Src';
    } else if (Type == 'Destination') {
        prefix = 'Des';
    } else if (Type == 'Truck') {
        prefix = 'Trk';
    }

    checkboxes = document.getElementsByTagName('INPUT');

    for (i = 0; i < checkboxes.length; i++) {
        if (checkboxes[i].type.toLowerCase() == 'checkbox' && checkboxes[i].checked && checkboxes[i].id.indexOf(prefix + '_') != -1) {
            controlName = checkboxes[i].id + '_Value';
            SelectBox = document.getElementById(controlName);

            if (SelectBox.type == 'text') {
                NewValue = SelectBox.value;
            }
            else {
                NewValue = SelectBox.options[SelectBox.selectedIndex].value;
            }
        }
    }

    if (OldValue != '' && NewValue != '' && NewValue && OldValue) {
        CallAjax('', './HaulageCorrectionBulkCorrectionSave.aspx?OldValue=' + OldValue + '&NewValue=' + NewValue + '&Type=' + Type + '&SelectId=' + SelectBoxId + '&ControlName=' + controlName);
    }

    return false;
}

function CorrectHaulageError() {
    SubmitForm('serverForm', '', './HaulageCorrectionCorrectErrorSave.aspx');
    return false;
}

function DeleteHaulageError(HaulageRawId) {
    if (confirm('Delete Haulage Error Record?')) {
        CallAjax('', './HaulageCorrectionCorrectErrorDelete.aspx?HaulageRawId=' + HaulageRawId);
    }

    return false;
}

function GetBulkCorrectionPointData(SelectBox, Type, ContainerId) {
    var SelectValue = SelectBox.options[SelectBox.selectedIndex].value;

    if (SelectValue != '') {
        CallAjax(ContainerId, './HaulageCorrectionBulkCorrectionPointData.aspx?Type=' + Type + '&PointId=' + SelectValue);
    }
    else { // Set the point to data to blank.
        var obj = document.getElementById(ContainerId);
        if (obj) {
            obj.innerHTML = '';
        }
    }

    return false;
}

function GetBulkCorrectionValidPoints(SelectBox, Type, ContainerId) {
    var SelectValue = SelectBox.options[SelectBox.selectedIndex].value;
    var obj = document.getElementById(ContainerId);

    if (SelectValue == '') {
        if (Type == 'Source') {
            ForceHide('Src_Img');
            if (obj) {
                obj.innerHTML = 'Select an old source';
            }
        } else if (Type == 'Destination') {
            ForceHide('Des_Img');
            if (obj) {
                obj.innerHTML = 'Select an old destination';
            }
        } else if (Type == 'Truck') {
            ForceHide('Trk_Img');
            if (obj) {
                obj.innerHTML = 'Select an old Truck';
            }
        }
    } else {
        CallAjax(ContainerId, './HaulageCorrectionBulkCorrectionValidPoint.aspx?Type=' + Type + '&OldValue=' + SelectValue);
    }

    return false;
}

function GetHaulageCorrectionList() {
    SubmitForm('filterForm', 'itemList', './HaulageCorrectionList.aspx', 'image');

    return false;
}

function GetHaulageCorrectionNameResolutionList(locationId) {
    SubmitForm('filterForm', 'itemList', './HaulageCorrectionNameResolutionList.aspx', 'image');
    ClearElement('itemDetail')
    return false;
}

function GetNextHaulageError(NextHaulageRecordId) {
    document.location = './HaulageCorrectionCorrectError.aspx?hid=' + NextHaulageRecordId;
    return false;
}

function OverrideRecord(importSyncRowId) {
    if (confirm('Are you sure you want to overwrite?')) {
        CallAjax('', './OverrideImportSyncConflict.aspx?importSyncRowId=' + importSyncRowId);
    }
    return false;
}

function OverrideRecordAndRedirect(importSyncRowId, importId) {
    if (confirm('Are you sure you want to overwrite?')) {
        CallAjax('', './OverrideImportSyncConflict.aspx?importSyncRowId=' + importSyncRowId, null, 'window.location="ImportAdministration.aspx?ImportId=' + importId + '"');
    }
    return false;
}

function CancelConflictResolution(importId) {
    window.location = './ImportAdministration.aspx?ImportId=' + importId;
    return false;
}

function HaulageCorrectionCheck(checkBox) {
    var prefix = checkBox.id.substring(0, checkBox.id.indexOf('_'));
    var ServerForm = document.getElementById('serverForm');

    for (i = 0; i < ServerForm.elements.length; i++) {
        var FormItem = ServerForm.elements[i];

        if ((FormItem.tagName == 'INPUT') && (FormItem.type == 'checkbox') && (FormItem.id.indexOf(prefix) == 0)) {
            if (FormItem.id != checkBox.id) {
                FormItem.checked = false;
            }

            document.getElementById(FormItem.id + '_Value').disabled = !FormItem.checked;
        }
    }

    if (checkBox.checked) {
        ForceShow(prefix + '_Img');
    } else {
        ForceHide(prefix + '_Img');
    }
}

function HaulageNameResolutionCheck(checkBox) {
    var prefix = checkBox.id.substring(0, checkBox.id.indexOf('_'));
    var ServerForm = document.getElementById('EditForm');

    for (i = 0; i < ServerForm.elements.length; i++) {
        var FormItem = ServerForm.elements[i];

        if ((FormItem.tagName == 'INPUT') && (FormItem.type == 'checkbox') && (FormItem.id.indexOf(prefix) == 0)) {
            if (FormItem.id != checkBox.id) {
                FormItem.checked = false;
            }

            document.getElementById(FormItem.id + '_Value').disabled = !FormItem.checked;
        }
    }
}

// Haulage Administration

function GetHaulageAdministrationSourceAndDestinationByLocation() {

    var locationControl = document.getElementById("LocationId");

    CallAjax('sourceDiv', './GetHaulageAdministrationSourceByLocation.aspx?LocationId=' + locationControl.value, 'image');
    CallAjax('destinationDiv', './GetHaulageAdministrationDestinationByLocation.aspx?LocationId=' + locationControl.value, 'image');

    return false;
}

function GetHaulageAdministrationList() {
    var dateFromWellFormed = calMgr.validateDate(document.filterForm.HaulageDateFromText, false);
    var dateToWellFormed = calMgr.validateDate(document.filterForm.HaulageDateToText, false);

    var isValidationError = false;
    var validationErrorMessage = "";

    if (dateFromWellFormed == false) {
        isValidationError = true;
        validationErrorMessage = validationErrorMessage + "The value for 'Haulage From' is invalid.\n";
    }

    if (dateToWellFormed == false) {
        isValidationError = true;
        validationErrorMessage = validationErrorMessage + "The value for 'Haulage To' is invalid.\n";
    }

    if (isValidationError) {
        alert(validationErrorMessage);
    } else {
        calMgr.formatDate(document.filterForm.HaulageDateFromText, CalendarControls.Lookup('HaulageDateFrom').dateFormat);
        calMgr.formatDate(document.filterForm.HaulageDateToText, CalendarControls.Lookup('HaulageDateTo').dateFormat);

        SubmitForm('filterForm', 'itemList', './HaulageAdministrationList.aspx', 'image');
    }
    return false;
}

function DeleteHaulage(HaulageId) {

    if (confirm('Delete the haulage \'' + HaulageId + '\'')) {
        CallAjax('', './HaulageAdministrationDelete.aspx?HaulageId=' + HaulageId);
    }

    return false;
}

function FilterHaulageRecords() {
    var locationId = document.getElementById('LocationId')

    if ((locationId != null) && (locationId.value != '-1')) {
        document.location = './HaulageCorrection.aspx?lid=' + locationId.value
    }
}

function FilterCorrectionLocations(haulageId) {
    var locationId = document.getElementById('LocationId')
    if (locationId != null) {
        document.location = './HaulageCorrectionCorrectError.aspx?hid=' + haulageId + '&lid=' + locationId.value
    }
}

function FilterHaulageAdministrationLocations(bulkEdit) {
    var locationId = document.getElementById('LocationId')
    if (locationId != null) {
        if (!bulkEdit) {
            document.location = './HaulageAdministration.aspx?lid=' + locationId.value;
        }
        else {
            document.location = './HaulageAdministrationBulkEdit.aspx?lid=' + locationId.value;
        }
    }
}

/* Haulage Correction Splitting */

var aryDigblockSplits = new Array()
var digblocksToLoad

function LoadDigblockSplitList(digblocksToLoadString) {
    var canModifySplit = document.getElementById('CanModifySplit');
    var digblocksToLoad = digblocksToLoadString.split(',');
    aryDigblockSplits = new Array();
    var i;

    for (i = 0; i < digblocksToLoad.length; i++) {

        if (digblocksToLoad[i] != '') {
            haulageSplitAddDigblock(digblocksToLoad[i]);

        }
    }

    // Refresh the list of selected digblocks. (Or show the no digblocks message)
    if (canModifySplit.value == "True") {
        haulageSplitRefreshList(false);
    }
    else {
        haulageSplitRefreshList(true);
    }

}

function GetHaulageSplittingList() {
    ClearElement('splittingDetail');
    CallAjax('splittingContent', './HaulageCorrectionSplittingList.aspx', 'image');
    return false;
}

function GetHaulageSplittingEdit(HaulageResolveSplitId) {
    var params = '';
    ClearElement('splittingDetail');
    if (HaulageResolveSplitId) {
        params = '?HaulageResolveSplitId=' + HaulageResolveSplitId;
    }
    CallAjax('splittingDetail', './HaulageCorrectionSplittingEdit.aspx' + params, 'image');
    return false;
}

function DeleteHaulageSplit(HaulageResolveSplitId) {
    if (confirm('Are you sure you wish to delete this Haulage Splitting code?')) {
        CallAjax('', './HaulageCorrectionSplittingDelete.aspx?HaulageResolveSplitId=' + HaulageResolveSplitId)
        GetHaulageSplittingList();
        ClearElement('splittingDetail');
    }
}

function haulageSplitSave() {
    var numDigblocks = document.getElementById('NumberOfDigblocks');

    if (numDigblocks) {
        if (numDigblocks.value > 0) {
            SubmitForm('AddHaulageSplitEditForm', '', './HaulageCorrectionSplittingEditSave.aspx', false, '');
        }
        else {
            alert('Reconcilor Error:\nYou must select at least one digblock in the split.');
        }
    }
}

function haulageSplitAddDigblock(digblockID) {
    var oSlkDigblock = document.getElementById('Digblock_ID');
    var oOptDigblock, i, noMatch;

    // If a digblock is provided, try and fetch that.
    if (oSlkDigblock) {

        if (digblockID) {

            // For each item in the select box, try and match the digblock ID
            for (i = oSlkDigblock.options.length - 1; i >= 0; i--) {
                if (oSlkDigblock.options[i].value == digblockID)
                    oOptDigblock = oSlkDigblock.options[i];
            }

        }
        else // Otherwise obtain the selected option.
            oOptDigblock = oSlkDigblock.options[oSlkDigblock.selectedIndex];
    }


    if (oOptDigblock) {
        // Attempt to find if it's already been selected.
        noMatch = true;
        for (i = 0; i < aryDigblockSplits.length; i++) {
            if (aryDigblockSplits[i] == oOptDigblock.value)
                noMatch = false;
        }

        // If it isn't in the list already, Add it and remove it from
        // the select box.
        if (noMatch) {
            aryDigblockSplits.push(oOptDigblock.value);

            for (i = oSlkDigblock.options.length - 1; i >= 0; i--) {
                if (oSlkDigblock.options[i] == oOptDigblock)
                    oSlkDigblock.remove(i);
            }
            haulageSplitRefreshList();
        }
        else // There was a match, display an alert.
            alert('This digblock already exists in the split.');
    }

}

// Remove the digblock from the list, and add it back into the select list.
function haulageSplitRemoveDB(digblockID) {
    var i;
    var oSlkDigblock = document.getElementById('DigblockId');
    var oOption = document.createElement('option'); ;

    // Cycle through each element looking for the requested digblock
    for (i = 0; i < aryDigblockSplits.length; i++) {
        if (aryDigblockSplits[i] == digblockID) {
            // On match, remove from the array, refresh the visible list
            aryDigblockSplits.splice(i, 1)
            haulageSplitRefreshList();
            // Add the removed digblock back into the select box.
            if (oSlkDigblock) {
                oOption.value = digblockID;
                oOption.text = digblockID
                oSlkDigblock.add(oOption);
            }
            break;
        }
    }
    // Return false to make the <a> tag not carry on.
    return false;
}

// Function to refresh the contents of the list based on the java array.
function haulageSplitRefreshList(NoEdit) {
    var divList = document.getElementById('DigblockList');
    var html = '';
    var i;


    if (divList) {
        // If the array has elements in it
        if (aryDigblockSplits.length > 0) {
            // For each element, Add it to the list, along with a remove button and a hidden form tag.
            for (i = 0; i < aryDigblockSplits.length; i++) {
                html = html + '<li>' + aryDigblockSplits[i];
                html = html + '<input type="hidden" name="Digblock' + i + '" value="' + aryDigblockSplits[i] + '">';
                if (!NoEdit) {

                    html = html + ' <a href="#" onclick="haulageSplitRemoveDB(\'' + aryDigblockSplits[i].replace(/\\/g, '\\\\') + '\');">';
                    html = html + '<font color=red>Remove</font></a>';
                }
                html = html + '</li>';
            }
            // Update the contents of the <div> and update the number of digblock hidden form tag.
            divList.innerHTML = html

            if (document.getElementById('NumberOfDigblocks'))
                document.getElementById('NumberOfDigblocks').value = aryDigblockSplits.length;
        }
        else  // There were no selected digblocks so display the message.
        {
            divList.innerHTML = '<li><font color=red>There are no Digblocks.</font></li>';

            document.getElementById('NumberOfDigblocks').value = '';
        }
    }
}

/* ----------End-------------- */

//Reference Drill Rig Scripts
function AddNewDrillRig() {
    CallAjax('itemDetail', './ReferenceDrillRigEdit.aspx');
    return false;
}

function DeleteDrillRig(DrillId, Description) {
    ClearElement('itemDetail');

    if (confirm('Delete the drill rig \'' + Description + '\'')) {
        CallAjax('', './ReferenceDrillRigDelete.aspx?DrillId=' + DrillId);
    }

    return false;
}

function EditDrillRig(DrillId) {
    CallAjax('itemDetail', './ReferenceDrillRigEdit.aspx?DrillId=' + DrillId);
    return false;
}

function GetDrillRigList() {
    CallAjax('itemList', './ReferenceDrillRigList.aspx');
    return false;
}

//Reference Grade Scripts
function EditGrade(GradeId) {
    CallAjax('itemDetail', './ReferenceGradeEdit.aspx?GradeId=' + GradeId);
    return false;
}

function GetGradeList() {
    CallAjax('itemList', './ReferenceGradeList.aspx');
    return false;
}

function MoveGradeOrderUp(GradeId) {
    ClearElement('itemDetail');

    CallAjax('', './ReferenceGradeChangeOrder.aspx?GradeId=' + GradeId + '&Increment=-1');

    return false;
}

function MoveGradeOrderDown(GradeId) {
    ClearElement('itemDetail');

    CallAjax('', './ReferenceGradeChangeOrder.aspx?GradeId=' + GradeId + '&Increment=1');

    return false;
}

//Reference Locations Scripts
function AddNewLocation(ParentLocationTypeId, LocationTypeID, ParentLocationId) {
    var qrystr = 'ParentLocationTypeId=' + ParentLocationTypeId;
    qrystr += '&ParentLocationId=' + ParentLocationId;

    //If its the source node then we need to know which type to default to in the drop down
    if (ParentLocationTypeId == "0")
        qrystr += '&LocationTypeID=' + LocationTypeID;

    CallAjax('itemDetail', './ReferenceLocationEdit.aspx?' + qrystr);
    return false;
}

function AddNewLocationType() {
    CallAjax('itemDetail', './ReferenceLocationTypeEdit.aspx');
    return false;
}

function DeleteLocation(LocationID, Description) {
    ClearElement('itemDetail');

    if (confirm('Are you sure you want to delete the location \'' + Description + '\'?')) {
        CallAjax('', './ReferenceLocationDelete.aspx?LocationID=' + LocationID);
    }

    return false;
}

function DeleteLocationType(LocationTypeId, Description) {
    ClearElement('itemDetail');

    if (confirm('Are you sure you want to delete the location type \'' + Description + '\'?')) {
        CallAjax('', './ReferenceLocationTypeDelete.aspx?LocationTypeId=' + LocationTypeId);
    }

    return false;
}

function EditLocationType(LocationTypeId) {
    CallAjax('itemDetail', './ReferenceLocationTypeEdit.aspx?LocationTypeId=' + LocationTypeId);
    return false;
}

function EditLocation(LocationID, ParentLocationTypeId) {
    var qrystr = 'ParentLocationTypeId=' + ParentLocationTypeId;
    qrystr += '&LocationId=' + LocationID;

    CallAjax('itemDetail', './ReferenceLocationEdit.aspx?' + qrystr);
    return false;
}

function GetLocationTypeList() {
    CallAjax('LocationTypeContent', './ReferenceLocationTypeList.aspx');
    return false;
}

function GetLocationList() {
    CallAjax('LocationContent', './ReferenceLocationList.aspx');
    return false;
}

function GetLocationTreeNode(ImageElement, ParentNodeId) {
    var SettingValue;

    if (ImageElement.src.indexOf('minus.png') == -1) {
        SettingValue = 'True'
    } else {
        SettingValue = 'False'
    }

    ExpandCollapsePlusMinus(ImageElement, ParentNodeId)

    SaveUserSetting(ParentNodeId + '_Expanded', SettingValue);

    GetTabPageData(ParentNodeId + '_data', '../Utilities/ReferenceLocationGetNode.aspx?nodeId=' + ParentNodeId, 'image');
}

function GetLocationTypeTabContent() {
    ClearElement('itemDetail');
    CallAjax('sidenav_layout_nav_container', './ReferenceLocationTypeSideNavigation.aspx');
    if (document.getElementById('LocationTypeContent').innerHTML == '') {
        GetLocationTypeList()
    }

    return false;
}

function GetLocationTabContent() {
    ClearElement('itemDetail');
    CallAjax('sidenav_layout_nav_container', './ReferenceLocationSideNavigation.aspx');
    if (document.getElementById('LocationContent').innerHTML == '') {
        GetLocationList()
    }

    return false;
}


//Reference Material Types Scripts
function AddNewMaterialType() {
    CallAjax('itemDetail', './ReferenceMaterialTypeEdit.aspx');
    return false;
}

function AddNewMaterialTypeGroup() {
    CallAjax('itemDetail', './ReferenceMaterialTypeGroupEdit.aspx');
    return false;
}

function DeleteMaterialType(MaterialTypeId, Description) {
    ClearElement('itemDetail');

    if (confirm('Delete the material type \'' + Description + '\'')) {
        CallAjax('', './ReferenceMaterialTypeDelete.aspx?mtId=' + MaterialTypeId);
    }

    return false;
}

function DeleteMaterialTypeGroup(MaterialTypeGroupId, Description) {
    ClearElement('itemDetail');

    if (confirm('Delete the material type group \'' + Description + '\'')) {
        CallAjax('', './ReferenceMaterialTypeGroupDelete.aspx?MaterialTypeGroupId=' + MaterialTypeGroupId);
    }

    return false;
}

function DeleteMaterialTypeWastePeriod(MaterialTypeId, WasteTypeId) {
    CallAjax('', './ReferenceMaterialTypeWastePeriodDelete.aspx?MaterialTypeId=' + MaterialTypeId + '&WasteTypeId=' + WasteTypeId);

    return false;
}

function EditMaterialTypeGroup(MaterialTypeGroupId) {
    CallAjax('itemDetail', './ReferenceMaterialTypeGroupEdit.aspx?MaterialTypeGroupId=' + MaterialTypeGroupId);
    return false;
}

function EditMaterialType(MaterialTypeId) {
    CallAjax('itemDetail', './ReferenceMaterialTypeEdit.aspx?mtId=' + MaterialTypeId);
    return false;
}

function GetMaterialTypeGroupList() {
    CallAjax('MaterialTypeGroupContent', './ReferenceMaterialTypeGroupList.aspx');
    return false;
}

function GetMaterialTypeList() {
    SubmitForm('FilterForm', 'MaterialTypeContent', './ReferenceMaterialTypeList.aspx', 'image');
    return false;
}

function GetMaterialTypeGroupTabContent() {
    ClearElement('itemDetail');
    CallAjax('sidenav_layout_nav_container', './ReferenceMaterialTypeGroupSideNavigation.aspx');
    if (document.getElementById('MaterialTypeGroupContent').innerHTML == '') {
        GetMaterialTypeGroupList()
    }

    return false;
}

function GetMaterialTypeTabContent() {
    ClearElement('itemDetail');
    CallAjax('sidenav_layout_nav_container', './ReferenceMaterialTypeSideNavigation.aspx');
    if (document.getElementById('MaterialTypeContent').innerHTML == '') {
        GetMaterialTypeList()
    }
    return false;
}

function GetMaterialTypeWastePeriodAddForm(MaterialTypeId) {
    CallAjax('WastePeriodAdd', './ReferenceMaterialTypeWastePeriodEdit.aspx?MaterialTypeId=' + MaterialTypeId);
}

function GetMaterialTypeWastePeriodList(MaterialTypeId, WasteTypeId, DivId) {
    CallAjax(DivId, './ReferenceMaterialTypeWastePeriodList.aspx?MaterialTypeId=' + MaterialTypeId + '&WasteTypeId=' + WasteTypeId);
}

function GetMaterialTypeWastePeriodListGroup(MaterialTypeId) {
    CallAjax('WastePeriod', './ReferenceMaterialTypeWastePeriodListGroup.aspx?MaterialTypeId=' + MaterialTypeId);
}

function GetMaterialTypeWastePeriodListSummary(MaterialTypeId) {
    CallAjax('WasteSummary', './ReferenceMaterialTypeWastePeriodListSummary.aspx?MaterialTypeId=' + MaterialTypeId);
}

//Reference Object Notes Scripts
function AddNewObjectNotes() {
    CallAjax('itemDetail', './ReferenceObjectNotesEdit.aspx');
    return false;
}

function DeleteObjectNotes(ObjectId) {
    ClearElement('itemDetail');

    if (confirm('Delete the object \'' + ObjectId + '\'')) {
        CallAjax('', './ReferenceObjectNotesDelete.aspx?ObjectId=' + ObjectId);
    }

    return false;
}

function EditObjectNotes(ObjectId) {
    CallAjax('itemDetail', './ReferenceObjectNotesEdit.aspx?ObjectId=' + ObjectId);
    return false;
}

function GetObjectNotesList() {
    CallAjax('itemList', './ReferenceObjectNotesList.aspx');
    return false;
}

//Reference Stockpile Groups Scripts
function AddNewStockpileGroup() {
    CallAjax('itemDetail', './ReferenceStockpileGroupEdit.aspx');
    return false;
}

function DeleteStockpileGroup(StockpileGroupId, Description) {
    ClearElement('itemDetail');

    if (confirm('Delete the stockpile group \'' + Description + '\'')) {
        CallAjax('', './ReferenceStockpileGroupDelete.aspx?StockpileGroupId=' + StockpileGroupId);
    }

    return false;
}

function IgnoreConflict(importSyncRowId, importId) {

    if (confirm('Are you sure you would like to ignore this Conflict?')) {
        CallAjax('', './IgnoreImportSyncConflict.aspx?importSyncRowId=' + importSyncRowId, null, 'ShowConflictScreenExpanded(' + importId + ');');
    }
    return false;
}

function OverrideConflict(importSyncRowId, importId) {

    if (confirm('Are you sure you would like to override this Conflict?')) {
        CallAjax('', './OverrideImportSyncConflict.aspx?importSyncRowId=' + importSyncRowId, null, 'ShowConflictScreenExpanded(' + importId + ');');
    }
    return false;
}

function EditStockpileGroup(StockpileGroupId) {
    CallAjax('itemDetail', './ReferenceStockpileGroupEdit.aspx?StockpileGroupId=' + StockpileGroupId);
    return false;
}

function GetStockpileGroupList() {
    CallAjax('itemList', './ReferenceStockpileGroupList.aspx');
    return false;
}

function GetStockpileGroupStockpileList(StockpileGroupId) {
    CallAjax('stockpileList', './ReferenceStockpileGroupStockpileList.aspx?StockpileGroupId=' + StockpileGroupId, true);
    return false;
}

function MoveStockpileGroupOrderUp(StockpileGroupId) {
    ClearElement('itemDetail');

    CallAjax('', './ReferenceStockpileGroupChangeOrder.aspx?StockpileGroupId=' + StockpileGroupId + '&Increment=-1');

    return false;
}

function MoveStockpileGroupOrderDown(StockpileGroupId) {
    ClearElement('itemDetail');

    CallAjax('', './ReferenceStockpileGroupChangeOrder.aspx?StockpileGroupId=' + StockpileGroupId + '&Increment=1');

    return false;
}

//Reference Truck Scripts
function AddNewTruck() {
    CallAjax('itemDetail', './ReferenceTruckEdit.aspx');
    return false;
}

function AddNewTruckType() {
    CallAjax('itemDetail', './ReferenceTruckTypeEdit.aspx');
    return false;
}

function DeleteTruck(TruckId, Description) {
    ClearElement('itemDetail');

    if (confirm('Delete the truck \'' + Description + '\'')) {
        CallAjax('', './ReferenceTruckDelete.aspx?TruckId=' + TruckId);
    }

    return false;
}

function DeleteTruckType(TruckTypeId, Description) {
    ClearElement('itemDetail');

    if (confirm('Delete the truck type \'' + Description + '\'')) {
        CallAjax('', './ReferenceTruckTypeDelete.aspx?TruckTypeId=' + TruckTypeId);
    }

    return false;
}

function DeleteTruckTypeFactorPeriod(TruckTypeId) {
    CallAjax('', './ReferenceTruckTypeFactorPeriodDelete.aspx?TruckTypeId=' + TruckTypeId);

    return false;
}

function EditTruck(TruckId) {
    CallAjax('itemDetail', './ReferenceTruckEdit.aspx?TruckId=' + TruckId);
    return false;
}

function EditTruckType(TruckTypeId) {
    CallAjax('itemDetail', './ReferenceTruckTypeEdit.aspx?TruckTypeId=' + TruckTypeId);
    return false;
}

function EditTruckTypeFactorPeriod(TruckTypeId) {
    CallAjax('TruckTypeFactorPeriodContainer', './ReferenceTruckTypeFactorPeriodEdit.aspx?TruckTypeId=' + TruckTypeId);
    return false;
}

function GetTruckTypeList() {
    CallAjax('TruckTypeContent', './ReferenceTruckTypeList.aspx');
    return false;
}

function GetTruckList() {
    CallAjax('TruckContent', './ReferenceTruckList.aspx');
    return false;
}

function GetTruckTypeFactorPeriodList(TruckTypeId) {
    CallAjax('TruckTypeFactorPeriodListContainer', './ReferenceTruckTypeFactorPeriodList.aspx?TruckTypeId=' + TruckTypeId);
    return false;
}

function GetTruckTypeTabContent() {
    ClearElement('itemDetail');
    CallAjax('sidenav_layout_nav_container', './ReferenceTruckTypeSideNavigation.aspx');
    if (document.getElementById('TruckTypeContent').innerHTML == '') {
        GetTruckTypeList()
    }

    return false;
}

function GetTruckTabContent() {
    ClearElement('itemDetail');
    CallAjax('sidenav_layout_nav_container', './ReferenceTruckSideNavigation.aspx');
    if (document.getElementById('TruckContent').innerHTML == '') {
        GetTruckList()
    }

    return false;
}

//User Interface Listing Scripts
//function AddNewObjectNotes(){
//	CallAjax('itemDetail', './ReferenceObjectNotesEdit.aspx');
//	return false;
//}

//function DeleteObjectNotes(ObjectId){
//	ClearElement('itemDetail');
//	
//	if(confirm('Delete the object \'' + ObjectId + '\'')){
//		CallAjax('', './ReferenceObjectNotesDelete.aspx?ObjectId=' + ObjectId);
//	}
//	
//	return false;
//}

function EditUserInterfaceListingField(UserInterfaceListingId, ListingStoredProcedure) {
    CallAjax('itemDetail', './ReferenceInterfaceListingEdit.aspx?UserInterfaceListingId=' + UserInterfaceListingId + '&ListingStoredProcedure=' + ListingStoredProcedure, 'image');
    return false;
}

function GetUserInterfaceListingList() {
    CallAjax('itemList', './ReferenceInterfaceListingList.aspx');
    return false;
}

function MoveUserInterfaceListingOrderUp(UIFieldId, UserInterfaceListingId) {
    ClearElement('itemDetail');

    var qryStr = 'UserInterfaceListingId=' + UserInterfaceListingId +
		'&UIFieldId=' + UIFieldId + '&Increment=-1'

    CallAjax('', './ReferenceInterfaceListingChangeOrder.aspx?' + qryStr);

    return false;
}

function MoveUserInterfaceListingOrderDown(UIFieldId, UserInterfaceListingId) {
    ClearElement('itemDetail');

    var qryStr = 'UserInterfaceListingId=' + UserInterfaceListingId +
		'&UIFieldId=' + UIFieldId + '&Increment=1'

    CallAjax('', './ReferenceInterfaceListingChangeOrder.aspx?' + qryStr);

    return false;
}

//Reference Waste Types Scripts
function AddNewWasteType() {
    CallAjax('itemDetail', './ReferenceWasteTypeEdit.aspx');
    return false;
}

function DeleteWasteType(WasteTypeId, Description) {
    ClearElement('itemDetail');

    if (confirm('Delete the waste type \'' + Description + '\'')) {
        CallAjax('', './ReferenceWasteTypeDelete.aspx?WasteTypeId=' + WasteTypeId);
    }

    return false;
}

function EditWasteType(WasteTypeId) {
    CallAjax('itemDetail', './ReferenceWasteTypeEdit.aspx?WasteTypeId=' + WasteTypeId);
    return false;
}

function GetWasteTypeList() {
    CallAjax('itemList', './ReferenceWasteTypeList.aspx');
    return false;
}

//Role Administration Scripts
function AddNewRole() {
    CallAjax('roleAction', './RoleEdit.aspx');
    return false;
}

function AddRoleAssignment(FormId, AssignmentTypeId) {
    SubmitForm(FormId, 'roleAction', './RoleAssignmentSave.aspx?atId=' + AssignmentTypeId);

    return false;
}

function DeleteRole(RoleId, Description) {
    ClearElement('roleAction');

    if (confirm('Delete the role \'' + Description + '\'')) {
        CallAjax('roleAction', './RoleDelete.aspx?RoleId=' + RoleId);
    }

    return false;
}

function DeleteRoleAssignment(RoleId, RoleAssignmentId, UserName) {
    var AssignmentTypeId = document.getElementById('AssignmentTypeId')[document.getElementById('AssignmentTypeId').selectedIndex].value;
    if (confirm('Delete the role assignment for \'' + UserName + '\'')) {
        CallAjax('roleAction', './RoleAssignmentDelete.aspx?RoleId=' + RoleId + '&AssignmentId=' + RoleAssignmentId + '&AssignmentTypeId=' + AssignmentTypeId);
    }

    return false;
}

function EditRole(RoleId) {
    CallAjax('roleAction', './RoleEdit.aspx?RoleId=' + RoleId);
    return false;
}

function EditRoleAssignments(RoleId, AssignmentTypeId) {
    CallAjax('roleAction', './RoleAssignmentEdit.aspx?RoleId=' + RoleId + '&AssignmentTypeId=' + AssignmentTypeId);
    return false;
}

function EditRoleSecurityOptions(RoleId) {
    CallAjax('roleAction', './RoleOptionEdit.aspx?RoleId=' + RoleId);
    return false;
}

function GetRoleList() {
    CallAjax('roleList', './RoleList.aspx');
    return false;
}

function GetImportMappingList() {
    CallAjax('importMappingList', './ImportMappingList.aspx',"image");
    return false;
}

function CopyImportMappingRevision(importRevisionId, ImportRevisionName) {
    ClearElement('importMappingAction');
    CallAjax('importMappingAction', './ImportRevisionCopy.aspx?ImportRevisionId=' + importRevisionId + '&ImportRevisionName=' + ImportRevisionName);
    return false;
}

function ImportTypeStateChanged(ctrl) {
    var importMappingId = ctrl.options[ctrl.selectedIndex].value;
    CallAjax('importMappingAction', './ImportMappingLoadData.aspx?ImportMappingId='+ importMappingId);
  return false
}


function AddImportMappingRevision() {
    CallAjax('importMappingAction', './ImportRevisionAdd.aspx');
    return false;
}
function DeleteImportMappingRevision(importRevisionId, ImportRevisionName) {
     ClearElement('importMappingAction');
     if (confirm('Delete the Import Revision \'' + ImportRevisionName + '\'?')) {
         CallAjax('importMappingAction', './ImportMappingDelete.aspx?ImportRevisionId=' + importRevisionId + '&ImportRevisionName=' + ImportRevisionName);
    }  
    return false;
}

function EditImportRevision(importRevisionId, ImportRevisionName) {
    ClearElement('importMappingAction');
    CallAjax('importMappingAction', './ImportRevisionEdit.aspx?ImportRevisionId=' + importRevisionId + '&ImportRevisionName=' + ImportRevisionName);
    return false;

}
function ShowUserOrGroupSelection(assignmentType) {

    var submitButton = document.getElementById('AddAssignment');
    var userSelect = document.getElementById('UserId');
    var groupSelect = document.getElementById('GroupId');
    var opt = document.createElement("option");


    submitButton.disabled = false;

    if (assignmentType == "G") {
        //If we already have a no group available option on the list, disable the button.
        if (groupSelect.length == 1) {
            if (groupSelect[0].value == -1) {
                submitButton.disabled = true;
            }
        }
        ForceHide('UserSelectDiv');
        ForceShow('GroupSelectDiv');
    }
    else if (assignmentType == "U") {
        //If we already have a no user available option on the list, disable the button.
        if (userSelect.length == 0) {
            if (userSelect[0].value == -1) {
                submitButton.disabled = true;
            }
        }
        ForceShow('UserSelectDiv');
        ForceHide('GroupSelectDiv');
    }

    //Always make sure there is something on the select box
    if (groupSelect.length == 0) {
        opt.value = -1;
        opt.text = "No groups available";
        groupSelect.add(opt);
        //If we are after a group assignment type then make sure it is disabled
        if (assignmentType == "G") {
            submitButton.disabled = true;
        }
    }

    //Always make sure there is something on the select box.
    if (userSelect.length == 0) {
        opt.value = -1;
        opt.text = "No users available";
        userSelect.add(opt);
        //If we are after a user assignment type then make sure it is disabled
        if (assignmentType == "U") {
            submitButton.disabled = true;
        }
    }
}

//System Settings Scripts
function AddNewSystemSettings() {
    CallAjax('itemDetail', './SystemSettingsEdit.aspx');
    return false;
}

function DeleteSystemSettings(SettingId) {
    ClearElement('itemDetail');

    if (confirm('Delete the setting \'' + SettingId + '\'')) {
        CallAjax('', './SystemSettingsDelete.aspx?SettingId=' + SettingId);
    }

    return false;
}

function EditSystemSettings(SettingId) {
    CallAjax('itemDetail', './SystemSettingsEdit.aspx?SettingId=' + SettingId);
    return false;
}

function GetSystemSettingsList() {
    CallAjax('itemList', './SystemSettingsList.aspx');
    return false;
}

//User & Group Administration Scripts
function AddNewUser() {

    CallAjax('actionContainer', './UserEdit.aspx');
    userTabScript.select();
    GetUserTabContent();
    return false;
}

function AddNewGroup() {
    CallAjax('actionContainer', './GroupEdit.aspx');
    groupTabScript.select();
    GetGroupTabContent();
    return false;
}

function DeleteGroup(GroupId, GroupName) {
    if (confirm('Are you sure you wish to delete the group ' + GroupName + '?\nAll role assignments attached to this group will also be deleted\n and access may be lost for 1 or more users')) {
        CallAjax('', './GroupDelete.aspx?groupId=' + GroupId);
        return false;
    }
}

function CheckUser(ntAccountName) {
    CallAjax('', './UserCheck.aspx?ntAccountName=' + ntAccountName);
    return false;
}

function EditUser(UserId) {
    CallAjax('actionContainer', './UserEdit.aspx?UserId=' + UserId);
    return false;
}

function EditGroup(GroupId) {
    CallAjax('actionContainer', './GroupEdit.aspx?GroupId=' + GroupId);
    return false;
}

function ActivateUser(UserId) {
    CallAjax('', './UserActivation.aspx?UserId=' + UserId + '&action=Activate');
}

function DeactivateUser(UserId) {
    CallAjax('', './UserActivation.aspx?UserId=' + UserId + '&action=Deactivate');
}

function GetUserTabContent() {
    CallAjax('userTabList', './UserList.aspx');
    return false;
}

function GetGroupTabContent() {
    CallAjax('groupTabList', './GroupList.aspx');
    return false;
}


function GetUserRoles(UserId) {
    CallAjax('actionContainer', './UserRoles.aspx?UserId=' + UserId);
    return false;
}

function GetGroupRoles(GroupId) {
    CallAjax('actionContainer', './GroupRoles.aspx?GroupId=' + GroupId);
    return false;
}

function AssignmentTypeChanged(assignmentType) {
    if (assignmentType == "Reconcilor User") {
        document.getElementById('RoleAssignmentId').style.display = "none"
        document.getElementById('ReconcilorUserSelect').style.display = "inline"
    }
    else {
        document.getElementById('ReconcilorUserSelect').style.display = "none"
        document.getElementById('RoleAssignmentId').style.display = "inline"
    }
}

//Weightometer Scripts
function GetWeightometerSampleList() {
    calMgr.formatDate(document.sampleFilter.SampleDateFromText, CalendarControls.Lookup('SampleDateFrom').dateFormat);
    calMgr.formatDate(document.sampleFilter.SampleDateToText, CalendarControls.Lookup('SampleDateTo').dateFormat);

    //SubmitForm('sampleFilter', 'itemList', './WeightometerSampleList.aspx', 'image');
    SubmitFormWithDateValidation(false, 'sampleFilter', 'itemList', './WeightometerSampleList.aspx', 'image');
    return false;
}

function WeightometerSave() {
    CallAjax('', './WeightometerDataSave.aspx?data=' + document.getElementById('fcx').SaveToString(true));
    return false;
}

//Weightometer Sample Scripts
function DeleteWeightometerSample(sampleId) {
    if (confirm('Are you sure you want to delete this weightometer sample?')) {
        CallAjax('', './WeightometerSampleDelete.aspx?WeightometerSampleID=' + sampleId);
    }

    return false;
}

//Data Exception Scripts
function GetDataExceptionTreeNode(ImageElement, ParentNodeId, IncludeActive, IncludeDismissed, IncludeResolved, DataExceptionTypeId, DateFrom, DateTo, DescriptionContains, MaxDataExceptions, LocationId) {
    var SettingValue;

    if (ImageElement.src.indexOf('minus.png') == -1) {
        SettingValue = 'True'
    }
    else {
        SettingValue = 'False'
    }

    ExpandCollapsePlusMinus(ImageElement, ParentNodeId)
    SaveUserSetting(ParentNodeId + '_Expanded', SettingValue);

    var qryStr = 'nodeId=' + ParentNodeId
    qryStr += '&IncludeActive=' + IncludeActive
    qryStr += '&IncludeDismissed=' + IncludeDismissed
    qryStr += '&IncludeResolved=' + IncludeResolved

    if (DataExceptionTypeId != null) {
        qryStr += '&DataExceptionTypeId=' + escape(DataExceptionTypeId)
    }

    if (DateFrom != null) {
        qryStr += '&DateFrom=' + escape(DateFrom)
    }

    if (DateTo != null) {
        qryStr += '&DateTo=' + escape(DateTo)
    }

    if (DescriptionContains != null) {
        qryStr += '&DescriptionContains=' + escape(DescriptionContains)
    }

    if (MaxDataExceptions != null) {
        qryStr += '&MaxDataExceptionsOfEachType=' + escape(MaxDataExceptions)
    }

    if (LocationId != null) {
        qryStr += '&LocationId=' + escape(LocationId)
    }

    GetTabPageData(ParentNodeId + '_data', '../Utilities/DataExceptionGetNode.aspx?' + qryStr, 'image');
}

function GetDataExceptionDetail(ExceptionID) {
    CallAjax('itemDetail', './DataExceptionView.aspx?ExceptionID=' + ExceptionID);
    return false;
}

function UpdateDataExceptionStatus(ExceptionID, ExceptionStatus, NodeId, IncludeActive, IncludeDismissed, IncludeResolved) {
    var qryStr = 'ExceptionID=' + ExceptionID
    qryStr += '&ExceptionStatusID=' + ExceptionStatus

    if (confirm('Are you sure you want to update the status of this exception?'))
        CallAjax('', './DataExceptionUpdateStatus.aspx?' + qryStr);

    return false;
}

function GetDataExceptionList() {
    var dateFromInput = document.getElementById('DateFromText')
    var dateToInput = document.getElementById('DateToText')

    if (dateFromInput && dateToInput && ValidateDateParameters(dateFromInput.value, dateToInput.value)) {
        SubmitForm('exceptionFilter', 'itemList', './DataExceptionList.aspx');
    }
    return false;
}

//Monthly Aprroval
function GetMonthlyApproval() {
    CallAjax('itemDetail', './MonthlyApprovalList.aspx');
    return false;
}

function UnapproveMonth() {
    SubmitForm('approvalForm', '', './MonthlyApprovalUnapprove.aspx');
    return false;
}

function ApproveMonth() {
    SubmitForm('approvalForm', '', './MonthlyApprovalApprove.aspx');
    return false;
}

// Recalc Log Viewer
function GetRecalcLogViewerList() {

    calMgr.formatDate(document.filterForm.LogDateFromText, CalendarControls.Lookup('LogDateFrom').dateFormat);
    calMgr.formatDate(document.filterForm.LogDateToText, CalendarControls.Lookup('LogDateTo').dateFormat);

    //SubmitForm('filterForm', 'itemList', './RecalcLogViewerList.aspx');
    SubmitFormWithDateValidation(false, 'filterForm', 'itemList', './RecalcLogViewerList.aspx', 'image');
    ClearElement('itemDetail');
    return false;
}

function GetRecalcLog(RecalcHistoryID) {
    CallAjax('itemDetail', './RecalcLogViewerDetails.aspx?RecalcHistoryID=' + RecalcHistoryID);
    return false;
}

//Reference Material Hierarchy Scripts
function AddNewMaterialHierarchyType(ParentMaterialCategoryId, MaterialCategoryId, ParentMaterialTypeId) {
    var qrystr = 'ParentMaterialCategoryId=' + ParentMaterialCategoryId;
    qrystr += '&ParentMaterialTypeId=' + ParentMaterialTypeId;

    //If its the source node then we need to know which type to default to in the drop down
    if (ParentMaterialCategoryId == "0")
        qrystr += '&MaterialCategoryId=' + MaterialCategoryId;

    CallAjax('itemDetail', './ReferenceMaterialHierarchyEdit.aspx?' + qrystr);
    return false;
}

function AddNewMaterialCategory() {
    CallAjax('itemDetail', './ReferenceMaterialCategoryEdit.aspx');
    return false;
}

function DeleteMaterialHierarchyType(MaterialTypeId, Description) {
    ClearElement('itemDetail');

    if (confirm('Are you sure you want to delete the material in the hierarchy \'' + Description + '\'?')) {
        CallAjax('', './ReferenceMaterialHierarchyDelete.aspx?MaterialTypeId=' + MaterialTypeId);
    }

    return false;
}

function DeleteMaterialCategory(MaterialCategoryId, Description) {
    ClearElement('itemDetail');

    if (confirm('Are you sure you want to delete the material category \'' + Description + '\'?')) {
        CallAjax('', './ReferenceMaterialCategoryDelete.aspx?MaterialCategoryId=' + MaterialCategoryId);
    }

    return false;
}

function EditMaterialCategory(MaterialCategoryId) {
    CallAjax('itemDetail', './ReferenceMaterialCategoryEdit.aspx?MaterialCategoryId=' + MaterialCategoryId);
    return false;
}

function EditMaterialHierarchyType(MaterialTypeId, ParentMaterialCategoryId) {
    var qrystr = 'ParentMaterialCategoryId=' + ParentMaterialCategoryId;
    qrystr += '&MaterialTypeId=' + MaterialTypeId;

    CallAjax('itemDetail', './ReferenceMaterialHierarchyEdit.aspx?' + qrystr);
    return false;
}

function GetMaterialCategoryList() {
    CallAjax('MaterialCategoryContent', './ReferenceMaterialCategoryList.aspx');
    return false;
}

function GetMaterialHierarchyList() {
    SubmitForm('FilterForm', 'MaterialHierarchyContent', './ReferenceMaterialHierarchyList.aspx', 'image');
    return false;
}

function GetMaterialHierarchyTreeNode(ImageElement, ParentNodeId) {
    var SettingValue;

    if (ImageElement.src.indexOf('minus.png') == -1) {
        SettingValue = 'True'
    } else {
        SettingValue = 'False'
    }

    ExpandCollapsePlusMinus(ImageElement, ParentNodeId)

    SaveUserSetting(ParentNodeId + '_Expanded', SettingValue);

    GetTabPageData(ParentNodeId + '_data', '../Utilities/ReferenceMaterialHierarchyGetNode.aspx?nodeId=' + ParentNodeId);
}

function GetMaterialCategoryTabContent() {
    ClearElement('itemDetail');
    CallAjax('sidenav_layout_nav_container', './ReferenceMaterialCategorySideNavigation.aspx');
    if (document.getElementById('MaterialCategoryContent').innerHTML == '') {
        GetMaterialCategoryList()
    }

    return false;
}

function GetMaterialHierarchyTabContent() {
    ClearElement('itemDetail');
    CallAjax('sidenav_layout_nav_container', './ReferenceMaterialHierarchySideNavigation.aspx');
    if (document.getElementById('MaterialHierarchyContent').innerHTML == '') {
        GetMaterialHierarchyList()
    }

    return false;
}


//Invalid Movements Scripts

function GetInvalidMovementList() {
    CallAjax('itemList', './InvalidMovementsList.aspx');
    ClearElement('itemDetail');
    return false;
}

function AddNewInvalidMovement() {
    ClearElement('itemDetail');
    CallAjax('itemDetail', './InvalidMovementsEdit.aspx');
    return false;
}

function EditInvalidMovement(invalidMovementId) {
    ClearElement('itemDetail');
    CallAjax('itemDetail', './InvalidMovementsEdit.aspx?InvalidMovementId=' + invalidMovementId);
    return false;
}

function DeleteInvalidMovement(invalidMovementId) {
    ClearElement('itemDetail');
    if (confirm('Delete invalid movement definition?')) {
        CallAjax('', './InvalidMovementsDelete.aspx?InvalidMovementId=' + invalidMovementId);
    }
    return false;
}

function GetInvalidMovementSourceDestinationList(selectBox, type, containerId) {
    if (type != null && type != '') {
        var elem = document.getElementById(type)
        if (elem != null) {
            //remove current drop-down before adding a new one
            elem.parentNode.removeChild(elem);
        }
    }

    var selectedValue = Trim(selectBox.options[selectBox.selectedIndex].value);
    //add new drop-down based on type: Source | Destination
    CallAjax(containerId, './InvalidMovementSourceDestinationList.aspx?InvalidMovementType=' + selectedValue + '&Type=' + type, 'imageWide');
    return false;
}

if (!ValidateDateParameters) {
    function ValidateDateParameters(startDate, endDate) {
        var success = true;
        var alertStr = "";
        var currentDate = new Date();

        startDate = calMgr.getDateFromFormat(startDate, calMgr.defaultDateFormat)
        endDate = calMgr.getDateFromFormat(endDate, calMgr.defaultDateFormat)

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

        return success
    }
}


