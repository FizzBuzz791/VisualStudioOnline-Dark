var rulesToggled = false;
var notificationReconcilorUsers = new Array();
var notificationEmailUsers = new Array();
var notificationReconcilorUsersDescription = new Array();
var auditTypeGroupTypeListIds = new Array();
var auditTypeGroupTypeListNames = new Array();

function GetNotificationAdministrationList() {
    SubmitForm('NotificationListFilterForm', 'NotificationAdministrationList', './NotificationAdministrationList.aspx');
    return false;
}

function ToggleRules() {

    var hrefTag = document.getElementById('rules_tag');

    if (rulesToggled) {
        ForceHide('NotificationDefaultRules');

        hrefTag.firstChild.nodeValue = 'explain rules';
        rulesToggled = false;
    }
    else {
        ForceShow('NotificationDefaultRules');

        hrefTag.firstChild.nodeValue = 'hide explanation';
        rulesToggled = true;
    }
}

function RefreshNotificationTypeHeader() {
    // Loads or refreshes Notification Type Header

    var notificationTypeSelectBox = document.getElementById('TypeId');
    var typeId = notificationTypeSelectBox[notificationTypeSelectBox.selectedIndex].value;
    var instanceId = document.getElementById('InstanceId').value;

    ClearElement('NotificationAdministrationEditNotificationTypeHeader');
    ClearElement('NotificationAdministrationEditNotificationTypeDetail');

    CallAjax('NotificationAdministrationEditNotificationTypeHeader',
     './NotificationAdministrationEditNotificationTypeHeader.aspx?TypeId=' + typeId +
     "&InstanceId=" + instanceId, 'imageWide');

    return false;
}

function RefreshNotificationDetail() {
    // Loads or refreshes the Notification Detail

    var notificationTypeSelectBox = document.getElementById('TypeId');
    var typeId = notificationTypeSelectBox[notificationTypeSelectBox.selectedIndex].value;
    var instanceId = document.getElementById('InstanceId').value;

    ClearElement('NotificationAdministrationEditNotificationDetail');

    CallAjax('NotificationAdministrationEditNotificationDetail',
     './NotificationAdministrationEditNotificationDetail.aspx?TypeId=' + typeId +
     '&InstanceId=' + instanceId, 'imageWide');

    return false;
}

function RefreshNotificationTypeDetail(typeId, instanceId, queryString) {
    // loads or refreshes the Notification Type Detail
    // typeId is mandatory, instanceId is nullable, queryString is nullable

    var queryStringParameter;
    var instanceIdParameter;

    if (queryString == null) {
        queryStringParameter = "";
    } else {
        queryStringParameter = "&" + queryString;
    };

    if (instanceId == null) {
        instanceIdParameter = "";
    } else {
        instanceIdParameter = instanceId;
    };

    ClearElement('NotificationAdministrationEditNotificationTypeDetail');

    CallAjax('NotificationAdministrationEditNotificationTypeDetail',
     './NotificationAdministrationEditNotificationTypeDetail.aspx?TypeId='
     + typeId + "&InstanceId=" + instanceIdParameter + queryStringParameter, 'imageWide');

    return false;
}

function RefreshNotificationDetailTypeRules(typeId) {
    // reload the default rules
    CallAjax('NotificationDefaultRules',
     './NotificationAdministrationEditRules.aspx?TypeId=' + typeId, 'imageWide');

    // resync the rules
    rulesToggled = !rulesToggled;
    ToggleRules();
}

function NotificationActivation(notificationId, activate) {
    CallAjax('NotificationAdministrationListNotificationAdministrationList', './NotificationAdministrationActivation.aspx?InstanceId=' + notificationId + '&Activation=' + activate, 'imageWide');
    return false;
}


function NotificationDelete(notificationId) {
    if (confirm('Are you sure you wish to delete this notification?\nAll audit and state information will be lost.'))
    {
        CallAjax('NotificationAdministrationListNotificationAdministrationList', './NotificationAdministrationDelete.aspx?InstanceId=' + notificationId, 'imageWide');
    }
    return false;
}

function SaveExistingAuditTypeGroupList() {
    var auditTypeGroupTypeList = document.getElementById('AuditType');

    // clear the arrays
    auditTypeGroupTypeListIds = new Array();
    auditTypeGroupTypeListNames = new Array();

    // copy the entries from the dropdown into the arrays
    for (var i = 0; i < auditTypeGroupTypeList.options.length; i++) {
        auditTypeGroupTypeListIds.push(auditTypeGroupTypeList.options[i].value);
        auditTypeGroupTypeListNames.push(auditTypeGroupTypeList.options[i].text);
    }
}

function FilterAuditTypeList() {
    // get the selected audit type group
    var auditTypeGroupId = document.getElementById('AuditTypeGroup').value;

    var newSelectedIndex = 0;

    // get the audit type list
    var auditTypeGroupTypeList = document.getElementById('AuditType');
    var currentlySelected = auditTypeGroupTypeList.value;
    var option;
    var auditTypeGroupTypeCombo;
    var groupLength;

    // remove all the existing records
    groupLength = auditTypeGroupTypeList.length;
    for (var i = 0; i < groupLength; i++) {
        auditTypeGroupTypeList.remove(0);
    }

    // get the audit type ids which match the current audit type group
    for (var i = 0; i < auditTypeGroupTypeListIds.length; i++) {
        // get the group and id combo
        auditTypeGroupTypeCombo = auditTypeGroupTypeListIds[i].split(',');

        // check to see if the group matches the currently selected group.
        if (auditTypeGroupId == auditTypeGroupTypeCombo[1]) {
            // create a new option
            option = document.createElement('option');
            option.value = auditTypeGroupTypeCombo[0];
            option.text = auditTypeGroupTypeListNames[i];
            newSelectedIndex = newSelectedIndex + 1;

            auditTypeGroupTypeList.add(option);

            if (auditTypeGroupTypeListIds[i] == currentlySelected) {
                auditTypeGroupTypeList[newSelectedIndex - 1].selected = true;
            }
        }
    }
}

function IsPositiveNumberOrEmpty(x) {
    if (isNumeric(x) == null) {
        if (x != "") {
            return false;
        }
    }
    else {
        if (x < 0) {
            return false;
        }
    }
    return true;
}

function IsEmptyOrZero(x) {
    if (x == "") {
        return true;
    }
    if (x == 0) {
        return true;
    }
    return false;
}

function IsPositiveNumber(x) {
    if (isNumeric(x) == null || x == "") {
        return false;
    }
    else {
        if (x < 0) {
            return false;
        }
    }
    return true;
}

function isNumeric(x) {
    var RegExp = /^(-)?(\d*)(\.?)(\d*)$/;
    var result = x.match(RegExp);
    return result;
}

function OnL1EnabledClicked() {
    var l1Enabled;
    var l1SuccessOrNot;
    var l1OccurrenceDays;
    var l1OccurrenceHours;
    var l1OccurrenceMinutes;

    l1Enabled = document.getElementById('L1Enabled');
    l1SuccessOrNot = document.getElementById('L1SuccessOrNot');
    l1OccurrenceDays = document.getElementById('L1OccurrenceDays');
    l1OccurrenceHours = document.getElementById('L1OccurrenceHours');
    l1OccurrenceMinutes = document.getElementById('L1OccurrenceMinutes');

    if (l1Enabled.checked) {
        l1SuccessOrNot.disabled = false;
        l1OccurrenceDays.disabled = false;
        l1OccurrenceHours.disabled = false;
        l1OccurrenceMinutes.disabled = false;
    } else {
        l1SuccessOrNot.disabled = true;
        l1OccurrenceDays.disabled = true;
        l1OccurrenceHours.disabled = true;
        l1OccurrenceMinutes.disabled = true;

        // the way the current system has been coded
        // requires that the Days/Hours/Minutes are set to 0
        // whenever the option is set to disabled
        // not awesome, but will do the job
        l1OccurrenceDays.value = '0';
        l1OccurrenceHours.value = '0';
        l1OccurrenceMinutes.value = '0';
    }
}

function OnL2EnabledClicked() {
    var l2Enabled;
    var l2SuccessOrNot;
    var l2OccurrenceDays;
    var l2OccurrenceHours;
    var l2OccurrenceMinutes;

    l2Enabled = document.getElementById('L2Enabled');
    l2SuccessOrNot = document.getElementById('L2SuccessOrNot');
    l2OccurrenceDays = document.getElementById('L2OccurrenceDays');
    l2OccurrenceHours = document.getElementById('L2OccurrenceHours');
    l2OccurrenceMinutes = document.getElementById('L2OccurrenceMinutes');

    if (l2Enabled.checked) {
        l2SuccessOrNot.disabled = false;
        l2OccurrenceDays.disabled = false;
        l2OccurrenceHours.disabled = false;
        l2OccurrenceMinutes.disabled = false;
    } else {
        l2SuccessOrNot.disabled = true;
        l2OccurrenceDays.disabled = true;
        l2OccurrenceHours.disabled = true;
        l2OccurrenceMinutes.disabled = true;

        // the way the current system has been coded
        // requires that the Days/Hours/Minutes are set to 0
        // whenever the option is set to disabled
        // not awesome, but will do the job
        l2OccurrenceDays.value = '0';
        l2OccurrenceHours.value = '0';
        l2OccurrenceMinutes.value = '0';
    }
}

function OnNotificationStockpileSelectionClicked() {
    var stockpileGroupId;
    var stockpileId;

    // the four radio options
    var selectAllStockpilesOption;
    var selectUngroupedStockpilesOption;
    var selectStockpileGroup;
    var selectStockpile;

    stockpileGroupId = document.getElementById('StockpileGroupId');
    stockpileId = document.getElementById('StockpileId');

    selectAllStockpilesOption = document.getElementById('SelectAllStockpilesOption');
    selectUngroupedStockpilesOption = document.getElementById('SelectUngroupedStockpilesOption');
    selectStockpileGroup = document.getElementById('SelectStockpileGroup');
    selectStockpile = document.getElementById('SelectStockpile');

    if (selectAllStockpilesOption.checked || selectUngroupedStockpilesOption.checked) {
        stockpileGroupId.disabled = true;
        stockpileId.disabled = true;
    }

    if (selectStockpileGroup.checked) {
        stockpileGroupId.disabled = false;
        stockpileId.disabled = true;
    };

    if (selectStockpile.checked) {
        stockpileGroupId.disabled = true;
        stockpileId.disabled = false;
    };
}

function OnSendReminderEmailsClick() {
    var sendReminderEmails = document.getElementById('SendReminderEmails');
    var remindMeEveryDays = document.getElementById('RemindMeEveryDays');
    var remindMeEveryHours = document.getElementById('RemindMeEveryHours');
    var remindMeEveryMinutes = document.getElementById('RemindMeEveryMinutes');

    if (sendReminderEmails.checked) {
        remindMeEveryDays.disabled = false;
        remindMeEveryHours.disabled = false;
        remindMeEveryMinutes.disabled = false;
    }
    else {
        remindMeEveryDays.disabled = true;
        remindMeEveryHours.disabled = true;
        remindMeEveryMinutes.disabled = true;
    }
}

function OnImportEnableConflictRuleClick() {
    var importEnableConflictRule = document.getElementById('ImportEnableConflictRule');
    var conflictErrorThreshold = document.getElementById('ConflictErrorThreshold');

    if (importEnableConflictRule.checked) {
        conflictErrorThreshold.disabled = false;
    }
    else {
        conflictErrorThreshold.disabled = true;
        conflictErrorThreshold.value = "";
    }
}

function OnImportEnableValidateRuleClick() {
    var importEnableValidateRule = document.getElementById('ImportEnableValidateRule');
    var validateErrorThreshold = document.getElementById('ValidateErrorThreshold');

    if (importEnableValidateRule.checked) {
        validateErrorThreshold.disabled = false;
    }
    else {
        validateErrorThreshold.disabled = true;
        validateErrorThreshold.value = "";
    }
}

function OnImportEnableOccurrenceRuleClick() {
    var importEnableOccurrenceRule = document.getElementById('ImportEnableOccurrenceRule');
    var successOrNot = document.getElementById('SuccessOrNot');
    var occurrenceDays = document.getElementById('OccurrenceDays');
    var occurrenceHours = document.getElementById('OccurrenceHours');
    var occurrenceMinutes = document.getElementById('OccurrenceMinutes');

    if (importEnableOccurrenceRule.checked) {
        successOrNot.disabled = false;
        occurrenceDays.disabled = false;
        occurrenceHours.disabled = false;
        occurrenceMinutes.disabled = false;
    }
    else {
        successOrNot.disabled = true;
        occurrenceDays.disabled = true;
        occurrenceHours.disabled = true;
        occurrenceMinutes.disabled = true;

        occurrenceDays.value = "";
        occurrenceHours.value = "";
        occurrenceMinutes.value = "";
    }
}

function ValidateNotificationNumericSettings() {
    var returnMessage;
    var sendReminderEmails = document.getElementById('SendReminderEmails').checked;
    var remindMeEveryDays = document.getElementById('RemindMeEveryDays').value;
    var remindMeEveryHours = document.getElementById('RemindMeEveryHours').value;
    var remindMeEveryMinutes = document.getElementById('RemindMeEveryMinutes').value;
    var checkStateMinutes = document.getElementById('CheckStateMinutes').value;
    var reminderTimeSpecified;

    returnMessage = "";

    if (!IsPositiveNumber(checkStateMinutes)) {
        returnMessage = returnMessage + "\n - Please supply a whole positive number for the 'Check State' minutes interval."
    }
    if (!IsPositiveNumberOrEmpty(remindMeEveryDays)) {
        returnMessage = returnMessage + "\n - Please supply a positive number or leave the field blank for 'Days' reminder value"
    }
    if (!IsPositiveNumberOrEmpty(remindMeEveryHours)) {
        returnMessage = returnMessage + "\n - Please supply a positive number or leave the field blank for 'Hours' reminder value"
    }
    if (!IsPositiveNumberOrEmpty(remindMeEveryMinutes)) {
        returnMessage = returnMessage + "\n - Please supply a positive number or leave the field blank for 'Minutes' reminder value"
    }

    if (IsEmptyOrZero(remindMeEveryDays) && IsEmptyOrZero(remindMeEveryHours) && IsEmptyOrZero(remindMeEveryMinutes) && sendReminderEmails) {
        returnMessage = returnMessage + "\n - 'You must specify an interval to remind on";
    }

    return returnMessage;
}

function NotificationPartsLoaded() {
    var notificationHeaderLoaded = document.getElementById('NotificationHeaderLoaded');
    var notificationDetailLoaded = document.getElementById('NotificationDetailLoaded');
    var notificationTypeHeaderLoaded = document.getElementById('NotificationTypeHeaderLoaded');
    var notificationTypeDetailLoaded = document.getElementById('NotificationTypeDetailLoaded');

    if (notificationHeaderLoaded != null && notificationDetailLoaded != null
        && notificationTypeHeaderLoaded != null && notificationTypeDetailLoaded != null) {
        return true;
    } else {
        return false;
    }
}

function SaveNotification() {
    var i;
    var queryString = "";
    var notificationName = document.getElementById('Name').value;
    var description = document.getElementById('Description').value;
    var activated = document.getElementById('Activated').value;
    var notificationType = document.getElementById('TypeId').value;
    var validationMessage;

    if (!NotificationPartsLoaded()) {
        alert('The page has not yet finished loading.  Please wait and try again.');
        return false;
    } else {
        validationMessage = ValidateNotificationNumericSettings();

        if (description == "") {
            validationMessage = validationMessage + "\n - The description must be supplied";
        }

        if (notificationName == "") {
            validationMessage = validationMessage + "\n - The notification name must be supplied";
        }

        if (validationMessage == "") {
            SubmitForm('NotificationAdministrationEdit', '', './NotificationAdministrationSave.aspx');
            return false;
        }
        else {
            validationMessage = "The following problems have occured." + validationMessage;
            alert(validationMessage);
            return true;
        }
    }
}

function AddNotificationEmailByUserFromValue(user) {
    var userList = document.getElementById('ReconcilorUserList');

    for (var i = 0; i < userList.options.length; i++) {
        if (user == userList.options[i].value) {
            userList.options[i].selected = true;
        }
    }
    AddNotificationEmailByUser();
}

function AddNotificationEmailByEmailFromValue(address) {
    document.getElementById('AlternateEmailAddress').value = address;
    AddNotificationEmailByEmail();
    document.getElementById('AlternateEmailAddress').value = '';
}

function AddNotificationEmailByEmail() {
    var notificationEmail = document.getElementById('AlternateEmailAddress').value;
    var notificationEmailParse;
    notificationEmailParse = notificationEmail.split('@');



    if (notificationEmailParse.length != 2) {
        alert('Email address must be in the format, user@host');
    }
    else {
        if (arrayHasValue(notificationEmailUsers, notificationEmail)) {
            alert('The email address "' + notificationEmail + '" has already been added to the list');
        } else {
            notificationEmailUsers.push(notificationEmail);
        }
    }
    RedrawNotificationEmailEmailList();
    return false;
}

function arrayHasValue(array, value) {
    var i;
    for (i = 0; i < array.length; i++) {
        if (array[i] == value) {
            return true;
        }
    }
    return false;
}

function AddNotificationEmailByUser() {
    var ReconcilorUserList = document.getElementById('ReconcilorUserList');
    var notificationUser = ReconcilorUserList[ReconcilorUserList.selectedIndex].value;
    var notificationUserName = ReconcilorUserList[ReconcilorUserList.selectedIndex].text;
    //Remove it from the selection drop down
    ReconcilorUserList.remove(ReconcilorUserList.selectedIndex)
    //Push it onto the reconcilor users array
    notificationReconcilorUsers.push(notificationUser);
    notificationReconcilorUsersDescription.push(notificationUserName);
    DisableAddEmailByUserButton(ReconcilorUserList);
    RedrawNotificationEmailUserList();
    return false;
}

function DisableAddEmailByUserButton(ReconcilorUserList) {
    if (ReconcilorUserList.length == 0) {
        document.getElementById('AddNotificationEmailByUserButton').disabled = true;
    }
    else {
        document.getElementById('AddNotificationEmailByUserButton').disabled = false;
    }
}

function DeleteNotificationEmailByUser(userId) {
    var i;
    var reconcilorUserList = document.getElementById('ReconcilorUserList');
    var option = document.createElement('option');

    //Delete it from the array
    for (i = 0; i < notificationReconcilorUsers.length; i++) {
        if (notificationReconcilorUsers[i] == userId) {

            //Recreate the option to readd it.
            option.value = userId;
            option.text = notificationReconcilorUsersDescription[i];

            notificationReconcilorUsers.splice(i, 1);
            notificationReconcilorUsersDescription.splice(i, 1);
        }
    }

    //Readd the option to the Reconcilor User List
    reconcilorUserList.add(option);
    RedrawNotificationEmailUserList();

    //Disable the add email by user button if necessary.
    DisableAddEmailByUserButton(reconcilorUserList);

}

function DeleteNotificationEmailByEmail(emailAddress) {
    var i;
    for (i = 0; i < notificationEmailUsers.length; i++) {
        if (notificationEmailUsers[i] == emailAddress) {
            notificationEmailUsers.splice(i, 1)
        }
    }
    RedrawNotificationEmailEmailList();
}

function RedrawNotificationEmailEmailList() {
    var destinationDiv = document.getElementById('DestinationEmailList');
    DrawNotificationDestinationList(destinationDiv, notificationEmailUsers, notificationEmailUsers, 'DeleteNotificationEmailByEmail', 'Email Recipients To Notify');
    return false;
}

function RedrawNotificationEmailUserList() {
    var destinationDiv = document.getElementById('DestinationUserList');
    DrawNotificationDestinationList(destinationDiv, notificationReconcilorUsers, notificationReconcilorUsersDescription, 'DeleteNotificationEmailByUser', 'Reconcilor Users To Notify');
    return false;
}

function DrawNotificationDestinationList(destinationDiv, valueArray, descriptionArray, deleteFunc, tableHeader) {
    var html = '';
    var i;
    var idTag = '';

    if (deleteFunc == 'DeleteNotificationEmailByUser') {
        idTag = 'DestinationUser_';
    }
    else {
        idTag = 'DestinationEmail_';
    }

    if (destinationDiv) {
        // If the array has elements in it
        html = html + '<table class="NotificationsTable"><tr><td class="NotificationsTableHeader" colspan="2">' + tableHeader + '</td></tr>'

        if (valueArray.length > 0) {
            // For each element, Add it to the list, along with a remove button and a hidden form tag.

            for (i = 0; i < valueArray.length; i++) {
                html = html + '<tr><td class="NotificationsTableEmail">' + descriptionArray[i];
                html = html + '<input type="hidden" id="' + idTag + '" name="' + idTag + i + '" value="' + valueArray[i] + '"></td><td class="NotificationsTableRemoveEmail">';
                html = html + ' <a href="#" onclick="' + deleteFunc + '(\'' + valueArray[i] + '\');">';
                html = html + 'Remove</a></td></tr>';
                html = html + '';
            }

        }
        else  // There were no selected digblocks so display the message.
        {
            html = html + '<tr><td align="center" class="NotificationsTableOuter">No recipients selected.</td></tr>';
        }
        html = html + '</table>';

        // Update the contents of the <div>
        destinationDiv.innerHTML = html;
    }
}
