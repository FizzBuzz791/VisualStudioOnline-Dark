// Message Grouping

var importMessageNode = new Array();
var imageExpanded = '../images/minus.png';
var imageCollapsed = '../images/plus.png';

var contentIndex = 0;
var contentImageState = 1;
var contentImageId = 2;
var contentType = 3;
var contentUserMessage = 4;
var contentImportId = 5;
var contentMessageContentDivId = 6;
var contentMessageRowId = 7;

function AddImportMessageNode(index, imageState, imageId, type, userMessage, importId, messageRowId, messageContentDivId) {
    var content = new Array();

    content[contentIndex] = index;
    content[contentImageState] = imageState;
    content[contentImageId] = imageId;
    content[contentType] = type;
    content[contentUserMessage] = userMessage;
    content[contentImportId] = importId;
    content[contentMessageRowId] = messageRowId;
    content[contentMessageContentDivId] = messageContentDivId;

    importMessageNode[index] = content;
}

function ToggleImportMessageNode(index) {
    var content = importMessageNode[index];

    var imageElement = document.getElementById(content[contentImageId]);
    var messageRowElement = document.getElementById(content[contentMessageRowId]);
    var messageContentDivElement = document.getElementById(content[contentMessageContentDivId]);

    if (content[contentImageState] == 'expanded') {
        // collapsing the node
        imageElement.src = imageCollapsed;
        content[contentImageState] = 'collapsed';

        messageRowElement.style.visible = "false";

        ClearElement(messageContentDivElement.id);
        ResizeContainer();
    } else {
        // expanding the node
        imageElement.src = imageExpanded;
        content[contentImageState] = 'expanded';

        messageRowElement.style.height = "0px";
        messageRowElement.style.visible = "true";

        var url = null;
        
        if (content[contentType] == 'conflict') {
            url = ImportMessageUrl(content[contentMessageContentDivId], content[contentImportId], content[contentType], content[contentUserMessage], 0);
            CallAjax(messageContentDivElement.id,url , 'image', 'ResizeContainer();', content[contentUserMessage]);
        } else {
            url = ImportMessageUrl(content[contentMessageContentDivId], content[contentImportId], content[contentType], '', 0);
            CallAjax(messageContentDivElement.id, url, 'image', 'ResizeContainer();', content[contentUserMessage]);
        }
    }

    return false;
}

function ImportMessageUrl(messageContentDivId, importId, type, userMessage, page) {
    var result = './ImportMessage.aspx?MessageContentDivId=' + messageContentDivId +
     '&ImportId=' + importId + '&Type=' + type +
     '&Page=' + page;

    if (userMessage) {
        result += ('&UserMessage=' + userMessage);
    }

    return result;
}

function postToUrl(path, param) {

    var method = "post";

    var form = document.createElement("form");
    form.setAttribute("method", method);
    form.setAttribute("action", path);
    form.setAttribute("target", "_blank");

    var hiddenField = document.createElement("input");
    hiddenField.setAttribute("type", "hidden");
    hiddenField.setAttribute("name", "UserMessage");
    hiddenField.setAttribute("value", param);

    form.appendChild(hiddenField);

    document.body.appendChild(form);
    form.submit();
}

// Message Detail

function ImportMessageDetailFirst(messageContentDivId, importId, type, userMessage, page, lastPage) {
    var url = ImportMessageUrl(messageContentDivId, importId, type, userMessage, 0)
    CallAjax(messageContentDivId, url, 'image', 'ResizeContainer();', null);
    return false;
}

function ImportMessageDetailPrevious(messageContentDivId, importId, type, userMessage, page, lastPage) {
    var url = ImportMessageUrl(messageContentDivId, importId, type, userMessage, page - 1)
    CallAjax(messageContentDivId, url, 'image', 'ResizeContainer();', null);
    return false;
}

function ImportMessageDetailNext(messageContentDivId, importId, type, userMessage, page, lastPage) {
    var url = ImportMessageUrl(messageContentDivId, importId, type, userMessage, page + 1)
    CallAjax(messageContentDivId, url, 'image', 'ResizeContainer();', null);
    return false;
}

function ImportMessageDetailLast(messageContentDivId, importId, type, userMessage, page, lastPage) {
    var url = ImportMessageUrl(messageContentDivId, importId, type, userMessage, lastPage)
    CallAjax(messageContentDivId, url, 'image', 'ResizeContainer();', null);
    return false;
}

// OTHER SCREENS (the old soup)

function ShowValidateScreen(ImportId) {
    CallAjax('itemDetail', './ImportMessageGrouping.aspx?ImportId=' + ImportId + '&Type=Validate');
    return false;
}

function ShowCriticalScreen(ImportId) {
    CallAjax('itemDetail', './ImportMessageGrouping.aspx?ImportId=' + ImportId + '&Type=Critical');
    return false;
}

function ShowConflictScreen(ImportId) {
    CallAjax('itemDetail', './ImportMessageGrouping.aspx?ImportId=' + ImportId + '&Type=Conflict');
    return false;
}

function ShowConflictScreenExpanded(ImportId) {
    CallAjax('itemDetail', './ImportMessageGrouping.aspx?ImportId=' + ImportId + '&Type=Conflict', null, 'ToggleImportMessageNode(0)');
    return false;
}

function ViewJob(JobId) {
    CallAjax('itemDetail', './ImportJobDetail.aspx?jID=' + JobId);
    return false;
}

function RunJob(ID, Status) {
    CallAjax('importsContent', './ImportJobRun.aspx?ID=' + ID + '&RunType=' + Status);
    return false;
}

function SaveImportDetails() {
    SubmitForm('importForm', 'importsContent', './ImportSave.aspx');
    //SubmitFormWithDateValidation(true, 'importForm', 'importsContent', './ImportSave.aspx');
    return false;
}

function SaveImportJobDetails() {
    SubmitForm('importJobForm', 'queueContent', './ImportJobSave.aspx');
    //SubmitFormWithDateValidation(true, 'importJobForm', 'queueContent', './ImportJobSave.aspx');
    return false;
}

function ViewImport(ImportId) {
    CallAjax('itemDetail', './ImportDetail.aspx?iID=' + ImportId);
    return false;
}

// Simple notifications
function EditSimpleNotifications(ImportId) {
    CallAjax('itemDetail', './ImportSimpleNotificationsEdit.aspx?ImportId=' + ImportId);
    return false;
}

function DeleteSimpleNotificationUser(RecipientId, ImportId, User, Refresh)
{
    if (confirm('Remove the recepient  \'' + User + '\'')) {
        CallAjax('', './ImportSimpleNotificationDelete.aspx?ImportId=' + ImportId + '&RecipientId=' + RecipientId);
    }

    // Refresh area
    if (Refresh == 1) {
        location.reload(true);
    } 

    return false;
}

function SaveSimpleNotificationUser(importId, name, refresh) {
    var failedEmailInput = document.getElementById('failedEmailInput').value;
    var notOccurredEmailInput = document.getElementById('notOccurredEmailInput').value;
    var failedUsernameInput = document.getElementById('failedUsernameInput').value;
    var notOccurredUsernameInput = document.getElementById('notOccurredUsernameInput').value;

    if (name == 'failed') {
        // avoid sending a blank parameter:
        failedEmailInput = (failedEmailInput != '') ? failedEmailInput : 'empty';
    
        CallAjax('', './ImportSimpleNotificationSaveRecipient.aspx?ImportId=' + importId + '&Type=1&Email=' + failedEmailInput + '&UserId=' + failedUsernameInput);
    }

    else if (name == 'notOccurred') {
        notOccurredEmailInput = (notOccurredEmailInput != '') ? notOccurredEmailInput : 'empty';
    
        CallAjax('', './ImportSimpleNotificationSaveRecipient.aspx?ImportId=' + importId + '&Type=0&Email=' + notOccurredEmailInput + '&UserId=' + notOccurredUsernameInput);
    }

    // Sishen only
    else if (name == 'blockModel') {
        var blockModelUsernameInput = document.getElementById('blockModelUsernameInput').value;
        var blockModelEmailInput = document.getElementById('blockModelEmailInput').value;
    
        blockModelEmailInput = (blockModelEmailInput != '') ? blockModelEmailInput : 'empty';

        CallAjax('', './ImportSimpleNotificationSaveRecipient.aspx?ImportId=' + importId + '&Type=2&Email=' + blockModelEmailInput + '&UserId=' + blockModelUsernameInput);
    }

    // Refresh area
    if (refresh == 1) {
        location.reload(true);
    }
}

function KillJob(JobId) {
    if (confirm('Kill job \'' + JobId + '\'?')) {
        CallAjax('queueContent', './ImportJobKill.aspx?ImportJobID=' + JobId);
    }
    return false;
}

function RemoveTableHeaderFilter(tableId) {
    var table;
    table = document.getElementById('HeaderTable_' + tableId);
    table.className = 'ReconcilorTableHeaderNoFilter';
    return false;
}

function CancelJob(JobId) {
    if (confirm('Cancel job \'' + JobId + '\'?')) {
        CallAjax('queueContent', './ImportJobCancel.aspx?ImportJobID=' + JobId);
    }
    return false;
}

// Inspired from stack overflow
function GetAddressParameter(param, url) 
{
    var result = url.search.match(
        new RegExp("(\\?|&)" + param + "(\\[\\])?=([^&]*)")
    );

    return result ? result[3] : false; 
}

function GetImportsList(importId) {
    // See if the critical or validation link has been clicked
    var url = GetAddressParameter('Tab', window.location)
    
    switch (url) 
    {
        case "Validation":
        case "Critical":
            url = './ImportList.aspx?Tab=' + url
            if (importId != null) {
                url = url + '&ImportId=' + importId
            }
            CallAjax('importsContent', url);
            break;
            
        default:
            CallAjax('importsContent', './ImportList.aspx');
    }
    
    return false;
}

function GetImportsTabContent(importId) {
    ClearElement('itemDetail');
    if (document.getElementById('importsContent').innerHTML == '') {
        GetImportsList(importId);
    }

    return false;
}

function GetImportSummaryList() {
    ClearElement('itemDetail');
    SubmitFormWithDateValidation(true, 'importAdminForm', 'summaryContent', './ImportSummaryList.aspx', 'image');
    return false;
}

function GetImportQueueList() {
    ClearElement('itemDetail');
    SubmitFormWithDateValidation(true, 'importAdminForm', 'queueContent', './ImportQueueList.aspx', 'image');
    return false;
}

function GetJobsRequiredList() {
    ClearElement('itemDetail');
    SubmitForm('importAdminForm', 'jobsRequiredContent', './ImportJobsRequiredList.aspx', 'image');
    return false;
}

function GetSummaryTabContent() {
    ClearElement('itemDetail');
    if (document.getElementById('summaryContent').innerHTML == '') {
        GetImportSummaryList();
    }
    return false;
}

function GetQueueTabContent() {
    ClearElement('itemDetail');
    if (document.getElementById('queueContent').innerHTML == '') {
        GetImportQueueList();
    }
    return false;
}

function GetJobsRequiredTabContent() {
    ClearElement('itemDetail');
    if (document.getElementById('jobsRequiredContent').innerHTML == '') {
        GetJobsRequiredList();
    }

    return false;
}

function showObject(e, object) {
    var objectToShow = document.getElementById(object);

    if (objectToShow != null) {
        objectToShow.style.visibility = "visible";
        objectToShow.style.left = e.clientX;
        objectToShow.style.top = e.clientY;
    }
}

function hideObject(object) {
    var objectToShow = document.getElementById(object);
    if (objectToShow != null) {
        objectToShow.style.visibility = "hidden";
    }
}

