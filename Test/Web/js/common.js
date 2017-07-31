var TableHeight = new JSDictionary();
var CalendarControls = new JSDictionary();
var ControlValidation = new JSDictionary();

// note - this is private use!
// if you need to call something "after" a page has loaded, use the CallAjax parameters instead
var AjaxFinalCall = '';
var AjaxCounter = 0;

window.onresize =
	function() {
	    ResizeContainer();
	}

function Trim(inputString) {
    if (typeof inputString != 'string') { return inputString; }
    var retValue = inputString;
    var ch = retValue.substring(0, 1);
    while (ch == ' ') {
        retValue = retValue.substring(1, retValue.length);
        ch = retValue.substring(0, 1);
    }
    ch = retValue.substring(retValue.length - 1, retValue.length);
    while (ch == ' ') {
        retValue = retValue.substring(0, retValue.length - 1);
        ch = retValue.substring(retValue.length - 1, retValue.length);
    }
    while (retValue.indexOf('  ') != -1) {
        retValue = retValue.substring(0, retValue.indexOf('  ')) + retValue.substring(retValue.indexOf('  ') + 1, retValue.length);
    }
    return retValue;
}

function VbReplace(strString, strOld, strNew) {
    var intIndex = 0;
    var intIndexAdd = 0;
    var intIndexAdd2 = 0;

    if (strNew.indexOf(strOld) != -1) {
        intIndexAdd = strNew.length - strOld.length + 1
    }

    do {
        intIndex = strString.indexOf(strOld, intIndex + intIndexAdd2);

        intIndexAdd2 = intIndexAdd;

        if (intIndex != -1) {
            strString = strString.substring(0, intIndex) + strNew + strString.substring(intIndex + strOld.length);
        }
    } while (intIndex != -1)

    return strString;
}

function ExpandCollapsePlusMinus(ImageElement, ShowElement) {
    ToggleShow(ShowElement);
    TogglePlusMinus(ImageElement);

    return false;
}

function ExpandCollapseTable(TableId) {
    var OuterDiv = document.getElementById('Outerdiv_' + TableId);
    var ExpandImage = document.getElementById('ExpandImage_' + TableId);

    if (TableHeight.Lookup(TableId) == null) {
        TableHeight.Add(TableId, OuterDiv.style.height);
    }

    if (OuterDiv.className.indexOf('Collapse') == -1) {
        OuterDiv.className = 'ReconcilorTableOuterDivCollapse';
        OuterDiv.style.height = TableHeight.Lookup(TableId);
        ExpandImage.src = '../images/ArrowExpand.png';
        ExpandImage.alt = 'Expand';
    } else {
        OuterDiv.className = 'ReconcilorTableOuterDivExpand';
        OuterDiv.style.height = 'auto';
        ExpandImage.src = '../images/ArrowCollapse.png';
        ExpandImage.alt = 'Collapse';
    }

    return false;
}

function HtmlJSEval(response) {
    var scriptReg = new RegExp('(</?script.*?>)', 'gi');
    var result;
    var StartIndex, EndIndex;
    var container = document.createElement('DIV');

    // Put the response in a tag to grab a tag logic.
    container.innerHTML = response;
    var scriptSrc = container.getElementsByTagName('SCRIPT');
    for (var i = 0; i < scriptSrc.length; i++) {
        if (scriptSrc[i].src) {
            var fileref = document.createElement('script')
            fileref.setAttribute("type", "text/javascript")
            fileref.setAttribute("src", scriptSrc[i].src)
            document.getElementsByTagName("head")[0].appendChild(fileref)
        }
    }

    try {
        while ((result = scriptReg.exec(response)) != null) {
            if (result[0] == '</script>') {
                EndIndex = result.index;
                eval(response.substring(StartIndex, EndIndex).replace('<!--', '').replace('//-->', '').replace('// -->', ''));
            } else {
                StartIndex = result.index + result[0].length;
            }
        }
    } catch (err) {
        alert('Javascript Evaluation Error:\n\nName: ' + err.name + '\nNumber: ' + err.number + '\nMessage: ' + err.message);
        //alert(response.substring(StartIndex, EndIndex).replace('<!--', '').replace('//-->', '').replace('// -->', ''))
    }
}

function EvalJS(container, response) {
    var i;

    if (container) {
        if (container.children.length == 0) {
            alert(container.outerHTML);
        }
        var scriptSrc = container.getElementsByTagName('SCRIPT');
        for (i = 0; i < scriptSrc.length; i++) {
            if (scriptSrc[i].src) {
                var fileref = document.createElement('script');
                fileref.setAttribute("type", "text/javascript");
                fileref.setAttribute("src", scriptSrc[i].src);
                document.getElementsByTagName("head")[0].appendChild(fileref);
            } else {
                eval(scriptSrc[i].innerHTML.replace('<!--', '').replace('//-->', '').replace('// -->', ''));
            }
        }
    }
    else // There is only one script tag.
    {
        var newRes = response.replace('\n', '').replace('\r', '');
        var divTag = document.createElement('div');
        divTag.innerHTML = '<b></b>' + response.replace('\n', '');

        var str = '';
        for (i = 0; i < newRes.length; i++) {
            if (newRes.charCodeAt(i) != 13 && newRes.charCodeAt(i) != 10)
                str = str + newRes.charAt(i)
        }
    }
}

function DecrementAjaxCounter() {
    AjaxCounter--;

    if (AjaxCounter == 0 && AjaxFinalCall != '') {
        eval(AjaxFinalCall);
        AjaxFinalCall = '';
    }
}

function CallAjax(elementId, urlToLoad, showLoading, finalCall, vars) {
    // try to obtain the element that is to be populated with results (if any)
    var element = elementId == null || elementId == undefined ||
                    document.getElementById(elementId) == undefined ||
                    document.getElementById(elementId) == null ? null : document.getElementById(elementId);
                    
    if (element != null) {
        switch (showLoading) {
            case 'image':
                element.innerHTML = '<div align="center"><img id="loadingImage" alt="" src="../images/loading.gif" /></div>'
                break;
            case 'imageWide':
                element.innerHTML = '<div align="center" style="width: 400px;"><img id="loadingImage" alt="" src="../images/loading.gif" /></div>';
                break;
            case 'text':
                element.innerHTML = '<div align="center">Loading ...</div>';
                break;
        }
    }

    if (finalCall != undefined && finalCall != '' && finalCall != null) {
        eval('AjaxFinalCall = \'' + VbReplace(finalCall, '\'', '\\\'') + '\';')
    }
    AjaxCounter++;    
    
    $.ajax({
        url: urlToLoad,
        type: 'POST',
        data: vars,
        async: true,
        cache: false,
        error: function(XMLHttpRequest, textStatus, errorThrown) {
            alert('Error has occurred (during AJAX call).');
        },
        success: function(data, textStatus, XMLHttpRequest) {
            if (Trim(data).length != 0) {
                if (data.substring(0, 1) == '<') {
                    if (element == null) {
                        // if the element was not found on first attempt
                        // try a second time to obtain it now (on ajax return)
                        // there are some timing issues that relate to the first attempt being made before the DOM is ready
                        // this second attempt aims to work around this, although attempts should be made to avoid this
                        var element = elementId == null || elementId == undefined ||
                            document.getElementById(elementId) == undefined ||
                            document.getElementById(elementId) == null ? null : document.getElementById(elementId);
                    }
                    if (element != null) {
                        var scriptPattern = /\<script (.|\n)*?\>(.|\n)*?\<\/script\>/gi;
                        var html = data.replace(scriptPattern, '');
                        element.innerHTML = html;
                    }
                    HtmlJSEval(data);
                } else {
                    eval(data);
                }
            }
        },
        complete: function(XMLHttpRequest, textStatus) {
            DecrementAjaxCounter();
        }

    });
    return false;
}

function GetTabPageData(elementId, urlToLoad, showLoading, finalCall) {
    if (document.getElementById(elementId).innerHTML == '') {
        CallAjax(elementId, urlToLoad, showLoading, finalCall)
    }

    return false;
}

function GetTabPageDataForm(formName, elementId, urlToLoad, showLoading, finalCall) {
    if (document.getElementById(elementId).innerHTML == '') {
        SubmitForm(formName, elementId, urlToLoad, showLoading, finalCall)
    }
    else if (finalCall != '') {
        eval(finalCall);
    }

    return false;
}

// Ensure that the dates are not in the future
// and the start is before the end date
function validateDates() 
{
    // --
    // PP: This method is not in use...changes to be made based on code review...
    // --
    
    var box;
    var foundStartResults = false;
    var foundEndResults = false;
    
    // Get the current date and format it correctly
    var currentDate = new Date();
    var weekDate = (currentDate.getDate() < 10) ? "0" + currentDate.getDate() : currentDate.getDate();
    var monthDate = Array("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
    var currentDateFormat = calMgr.getDateFromFormat(weekDate + "-" + monthDate[currentDate.getMonth()] + "-" + currentDate.getYear(), calMgr.defaultDateFormat);

    var listForms = document.getElementsByTagName("input");

    for (var i = 0; i < listForms.length; i++) 
    {       
        if ((listForms[i].value.length > 0) && listForms[i].name.match(/Date(?:To|From)/)) 
        {
            // DateFrom
            if (listForms[i].name.match(/Date(?:From)/)) 
            {
                startDate = calMgr.getDateFromFormat(listForms[i].value, calMgr.defaultDateFormat);
                foundStartResults = true;
            }

            // DateTo
            else if (listForms[i].name.match(/Date(?:To)/)) 
            {
                endDate = calMgr.getDateFromFormat(listForms[i].value, calMgr.defaultDateFormat);
                foundEndResults = true;
            }           
        }
    }

    // Only do a check if there are dates on this page!
    if (foundStartResults && foundEndResults) 
    {
        if (startDate > endDate) 
        {
            box = confirm('The end date must be after the start date.');
        }

        else if (startDate > currentDateFormat || endDate > currentDateFormat) 
        {
            box = confirm('The start and end dates must not be in the future.');
        }
    }  
}

function ResizeContainer() {

   //validateDates();

    // 1. layout_padding_left               - dynamic
    // 2. sidenav_layout_nav_container      - dynamic
    // 3. sidenav_layout_spacer             - static
    // 4. sidenav_layout_content_container  - dynamic

    // these elements make up the "content" area of the user interface
    var content = document.getElementById('pageBody');
   
    var layoutPaddingLeft = document.getElementById('layout_padding_left');
    var sideNav = document.getElementById('sidenav_layout_nav_container');
    var spacer = document.getElementById('sidenav_layout_spacer');
    var containerSmallContent = document.getElementById('container_small_content');

    // these hold our key widths that we're collecting
    var widthSideNav;
    var widthContent;
    var widthSpacer;
    var widthWindow = getClientWindowWidth();

    var temp;

    // get the current width of the content container
    if (containerSmallContent !== null) {
        widthContent = GetElementWidth(containerSmallContent);
    }
    else {
        widthContent = 0;
    }
 
    // get the current width of the sidenav
    if (sideNav !== null) {
        widthSideNav = GetElementWidth(sideNav);
    }
    else {
        widthSideNav = 0;
    }

    // get the current width of the spacer
    if (spacer !== null) {
        widthSpacer = GetElementWidth(spacer);
    }
    else {
        widthSpacer = 0;
    }
    
    // based on the width that the buttons take out determine if we need to resize.
    // otherwise resizing will be handled using tables.
    if (layoutPaddingLeft !== null) {

        if (widthSideNav + widthSpacer + widthContent <= widthWindow) {
            // everything fits within the viewable screen
            // set the padding as an arbitrary percentage of the screen width
            // but no more than an arbitrary 10%

            temp = (widthWindow - (widthSideNav + widthSpacer + widthContent)) / 2;
            if (temp > widthWindow * 0.1) {
                temp = widthWindow * 0.1;
            }

            layoutPaddingLeft.style.width = temp;
        }
        else {
            // if it doesn't fit (i.e it overflows off the right) then set to zero
            layoutPaddingLeft.style.width = 0;
        }
    }
    
    // Resize the header.
    resizeHeader();
}

function resizeHeader() {
    var content = document.getElementById('ReconcilorContentMainLayoutTable');

    var header = document.getElementById('header');
    var tabs = document.getElementById('tabs');
    var exception = document.getElementById('ReconcilorExceptionBar');

    var overflowContainer = document.getElementById('overflowDiv');
    var overflowHeader = document.getElementById('overflowHeader');
    var overflowTabs = document.getElementById('overflowTabs');
    var overflowException = document.getElementById('overflowException');

    var overflowExceptionText = document.getElementById('overflowExceptionText');
    var exceptionText = document.getElementById('exceptionText');

    var widthClient;
    var widthContent;

    if (!(header == null || tabs == null || exception == null
          || overflowHeader == null || overflowTabs == null || overflowException == null))
    {
        // take the viewable window width
        widthClient = getClientWindowWidth();

        // calculate the Content Width
        if (content != null) {
            widthContent = GetElementWidth(content);
        }
        else {
            widthContent = 0
        }

        // the widths must match the window width
        header.style.width = widthClient;
        tabs.style.width = widthClient;
        exception.style.width = widthClient;

        // the overflows must continue until the content width is met
        if (widthContent > widthClient) {
            overflowContainer.style.left = widthClient;
            overflowHeader.style.width = widthContent - widthClient;
            overflowTabs.style.width = widthContent - widthClient;
            overflowException.style.width = widthContent - widthClient;

            overflowHeader.style.height = GetElementHeight(header);
            overflowTabs.style.height = GetElementHeight(tabs);
            overflowException.style.height = GetElementHeight(exception);

            if (exceptionText != null) {
                overflowExceptionText.style.height = GetElementHeight(exceptionText);
            }
            else {
                overflowExceptionText.style.height = 0
            }
        }
        else {
            overflowContainer.style.left = 0;
            overflowHeader.style.width = 0;
            overflowTabs.style.width = 0;
            overflowException.style.width = 0;
        }        
    }
}

function getClientWindowWidth() {
    var myWidth = 0, myHeight = 0;

    if (typeof (window.innerWidth) == 'number') {
        //Non-IE
        myWidth = window.innerWidth;
        myHeight = window.innerHeight;
    }
    else if (document.documentElement && (document.documentElement.clientWidth || document.documentElement.clientHeight)) {
        //IE 6+ in 'standards compliant mode'
        myWidth = document.documentElement.clientWidth;
        myHeight = document.documentElement.clientHeight;
    }
    else if (document.body && (document.body.clientWidth || document.body.clientHeight)) {
        //IE 4 compatible
        myWidth = document.body.clientWidth;
        myHeight = document.body.clientHeight;
    }

    return myWidth;
}

function SubmitForm(formName, elementId, urlToLoad, showLoading, finalCall) {
    // PP: Disabling this call until updated based on code-review
    // validateDates();

    var QueryString = '?';
    var ServerForm = $('#' + formName);
    var vars = new Object();

    if (urlToLoad.indexOf('?') != -1) {
        QueryString += urlToLoad.substring(urlToLoad.indexOf('?') + 1) + '&';
        urlToLoad = urlToLoad.substring(0, urlToLoad.indexOf('?'));
    }
    ServerForm.find('input').each(function(i) {
        var el = $(this);
        var type = el.attr('type').toLowerCase();
        var name = el.attr('name');
        switch (type) {
            case 'hidden':
                if (name.substring(0, 2) != '__') {
                    vars[name] = el.val();
                }
                break;
            case 'text':
                vars[name] = el.val();
                break;
            case 'radio':
                if (el.attr('checked') == true) {
                    vars[name] = el.val();
                }
                break;
            case 'checkbox':
                vars[name] = el.attr('checked') == true ? el.val() : '';
                break;
            case 'button':
            case 'submit':
                vars[name] = el.val();
                break;
        }
    });
    ServerForm.find('select').each(function(i) {
        var el = $(this);
        if (el.find('option').length > 0) {
            var name = el.attr('name');
            vars[name] = el.val();
        }
    });
    ServerForm.find('textarea').each(function(i) {
        var el = $(this);
        var name = el.attr('name');
        vars[name] = el.val();
    });
    CallAjax(elementId, urlToLoad + QueryString, showLoading, finalCall, vars);
    return false;
}



function ClearElement(elementId) {
    
    var ElementToClear = document.getElementById(elementId);
    
    if(ElementToClear != null)
        ElementToClear.innerHTML = '';

    return false;
}

function ToggleShow(id) {
    var e = document.getElementById(id);

    if (e.className.indexOf('hide') == -1) {
        e.className = e.className.replace(/show/, 'hide');
    } else {
        e.className = e.className.replace(/hide/, 'show');
    }

    return false;
}

function TogglePlusMinus(ImageElement) {
    var ImageSource = ImageElement.src;

    if (ImageSource.indexOf('minus.png') == -1) {
        ImageElement.src = VbReplace(ImageSource, 'plus.png', 'minus.png');
    } else {
        ImageElement.src = VbReplace(ImageSource, 'minus.png', 'plus.png');
    }

    return false;
}

function GetReconcilorTabletoCsvWindow(tableId) {
    GetReconcilorTableToCsvSubmit(tableId);
}

function GetReconcilorTableToCsvSubmit(tableId) {

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
function ForceHide(id) {
    var e = document.getElementById(id);

    if (!e) {
        alert('Error! Element ' + id + ' could not be found. Unable to hide.');
    } else {
        e.className = e.className.replace(/show/, 'hide');

        if (e.className.indexOf('hide') == -1) {
            if (Trim(e.className) == '') {
                e.className = 'hide';
            } else {
                e.className = e.className + ' hide';
            }
        }
    }
    return false;
}

function ForceShow(id) {
    var e = document.getElementById(id);

    if (!e) {
        alert('Error! Element ' + id + ' could not be found. Unable to show.');
    } else {
        e.className = e.className.replace(/hide/, 'show');

        if (e.className.indexOf('show') == -1) {
            if (Trim(e.className) == '') {
                e.className = 'show';
            } else {
                e.className = e.className + ' show';
            }
        }
    }
    return false;
}

function ForceEnabled(id) {
    var e = document.getElementById(id);

    if (e != 'undefined' && e != null) {
        e.disabled = false;
    }

    return false;
}

function ForceDisabled(id) {
    var e = document.getElementById(id);
    if (e != 'undefined' && e != null) {
        e.disabled = true;
    }

    return false;
}

function PopulateSelectBox(SelectId, Data, SelectedValue) {
    var SelectBox = document.getElementById(SelectId);
    var DataArray = Data.split('||');
    var DataItemArray;
    var Counter;

    RemoveSelectOptions(SelectBox)

    for (Counter = 0; Counter < DataArray.length; Counter++) {
        DataItem = DataArray[Counter].split('|');

        SelectBox.options.add(new Option(DataItem[0], DataItem[1]));

        if (DataItem[1] == SelectedValue) {
            SelectBox.options[Counter].selected = true;
        }
    }

    return false;
}

function RemoveSelectedOption(SelectBox) {
    SelectBox.options[SelectBox.selectedIndex] = null;

    if (SelectBox.options.length != 0) {
        SelectBox.options[0].selected;
    }
}

function RemoveSelectOptions(SelectBox) {
    SelectBox.options.length = 0;

    return false;
}

function SaveGroupBoxCollapseSetting(GroupBoxImage, UserSettingTypeId) {
    var SettingValue;

    if (GroupBoxImage.src.indexOf('minus.png') == -1) {
        SettingValue = 'True'
    } else {
        SettingValue = 'False'
    }

    SaveUserSetting(UserSettingTypeId, SettingValue);

    return false;
}

function SaveUserSetting(UserSettingTypeId, SettingValue) {
    CallAjax('', '../Utilities/UserSettingSave.aspx?ustId=' + UserSettingTypeId + '&val=' + SettingValue);

    return false;
}

function SubmitScript(action, script) {
    var scriptElement = document.createElement('input');
    scriptElement.setAttribute('type', 'hidden');
    scriptElement.setAttribute('id', 'script');
    scriptElement.setAttribute('name', 'script');
    scriptElement.setAttribute('value', script);
    scriptElement.value = script;

    var formElement = document.createElement('form');
    formElement.setAttribute('method', 'POST');
    formElement.setAttribute('action', action);
    formElement.appendChild(scriptElement);

    document.getElementById('footer').appendChild(formElement);

    formElement.submit();
}

function ToggleCheckboxes(CheckBox, NamePart) {
    var checkboxes;

    //	while(parentTable && parentTable.tagName.toLowerCase() != 'table'){
    //		parentTable = parentTable.parentNode;
    //	}

    checkboxes = document.getElementsByTagName('INPUT');

    for (i = 0; i < checkboxes.length; i++) {
        if (checkboxes[i].type.toLowerCase() == 'checkbox' && checkboxes[i].id.indexOf(NamePart) != -1) {
            checkboxes[i].checked = CheckBox.checked;



        }
    }
}

//Dictionary Object Script
//
// The one lookup method:
function mLookup(strKeyName) {
    return (this[strKeyName]);
}

// The meta Add method:
function mAdd() {
    for (c = 0; c < mAdd.arguments.length; c += 2) {
        this[mAdd.arguments[c]] = mAdd.arguments[c + 1];
    }
}

// The Delete method
function mDelete(strKeyName) {
    for (c = 0; c < mDelete.arguments.length; c++) {
        this[mDelete.arguments[c]] = null;
    }
}

// A dictionary object of Cities and States/Countries:
function JSDictionary() {
    this.Add = mAdd;
    this.Delete = mDelete;
    this.Lookup = mLookup;
}

function CheckLocationPoint(checkBox) {
    var prefix = checkBox.id.substring(0, checkBox.id.indexOf('_'));
    var elements = document.getElementsByTagName('INPUT');

    for (i = 0; i < elements.length; i++) {
        var FormItem = elements[i];

        if ((FormItem.tagName == 'INPUT') && (FormItem.type == 'checkbox') && (FormItem.id.indexOf(prefix) == 0)) {
            if (FormItem.id != checkBox.id) {
                FormItem.checked = false;
            }

            document.getElementById(FormItem.id + '_Value').disabled = !FormItem.checked;
        }
    }

    if (document.getElementById(prefix + '_Img')) {
        if (checkBox.checked) {
            ForceShow(prefix + '_Img');
        } else {
            ForceHide(prefix + '_Img');
        }
    }
}

function InputText_OnChange_Width(thisobj, minsize, maxsize, charPixelWidth) {
    if (thisobj && minsize && maxsize) {
        var charLength = charPixelWidth * thisobj.value.length;

        if (charLength < minsize)
            charLength = minsize
        else if (charLength > maxsize)
            charLength = maxsize

        thisobj.style.width = charLength
    }
}

function InputText_OnChange_Numeric(thisobj) {
    if (isNumeric(thisobj.value) == null) {
        alert("Please enter a numeric value.");
    }
}


function isNumeric(x) {
    var RegExp = /^(-)?(\d*)(\.?)(\d*)$/;
    var result = x.match(RegExp);
    return result;
}

function sleep(naptime) {
    naptime = naptime;
    var sleeping = true;
    var now = new Date();
    var alarm;
    var startingMSeconds = now.getTime();

    while (sleeping) {
        alarm = new Date();
        alarmMSeconds = alarm.getTime();
        if (alarmMSeconds - startingMSeconds > naptime) {
            sleeping = false;
        }
    }
}

function addCommas(nStr) {
    nStr += '';
    x = nStr.split('.');
    x1 = x[0];
    x2 = x.length > 1 ? '.' + x[1] : '';
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
        x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
}

function insertAfter(parent, node, referenceNode) {
    parent.insertBefore(node, referenceNode.nextSibling);
}

//Pass in a list of elements or ids to this function and itll return an array of DOM elements
function $() {
    var elements = new Array();
    for (var i = 0; i < arguments.length; i++) {
        var element = arguments[i];
        if (typeof element == 'string')
            element = document.getElementById(element);
        if (arguments.length == 1)
            return element;
        elements.push(element);
    }
    return elements;
}

//Common Control Functions
function FilterDropdown(filterPattern, dropdownCtrlId) {
    filterPattern = filterPattern.replace('\\', '\\\\');

    var i = 0;
    var selection = 0;
    var pattern = new RegExp('^' + filterPattern, "i");

    var dropdownCtrl = document.getElementById(dropdownCtrlId);

    if (dropdownCtrl != 'undefined' && dropdownCtrl != null) {
        while (i < dropdownCtrl.options.length) {
            if (pattern.test(dropdownCtrl.options[i].text)) {
                selection = i;
                break;
            }
            else if (pattern.test(dropdownCtrl.options[i].value)) {
                selection = i;
                break;
            }

            i++;
        }

        
        dropdownCtrl.options.selectedIndex = selection;
    }
}

//Treeview V2
function AppendNodeRows(stageTable, targetTable, rowToPutUnder) {
    if (stageTable.childNodes[0]) //item 0 will be the tbody of a Table passed through ajax
    {
        //Might want to check if the childNodes[0] is actually the tbody rather than assume it
        var rows = stageTable.childNodes[0].childNodes;
        var rowToPutBefore = rowToPutUnder.nextSibling

        while (rows.length > 0) {
            //Carefull - as it gets added it removes it from the array
            targetTable.insertBefore(rows[0], rowToPutBefore);
        }
    }
}

function CollapseNodeRow(nodeRowId) {
    var curRow = document.getElementById(nodeRowId);
    var table = curRow.parentNode;

    if (table.childNodes) //item 0 will be the tbody
    {
        var rows = table.childNodes;

        for (var i = 0; i < rows.length; i++) {
            //Child nodes will be nodeRowId + '_<RecordId>' so look for anything at that level
            if (rows[i].id.match(nodeRowId) && rows[i].id != nodeRowId) {
                ForceHide(rows[i].id);
            }
        }
    }

    return true;
}

function ExpandNode(nodeRowId) {
    var curRow = document.getElementById(nodeRowId);
    var table = curRow.parentNode;
    var found = false;

    var counter = 0;

    //Check for Nodes that already exist
    if (table.childNodes) //item 0 will be the tbody
    {
        var rows = table.childNodes;

        //Show the nodes	
        for (var i = 0; i < rows.length; i++) {
            //Child nodes will be nodeRowId + '_<RecordId>' so look for anything at that level
            if (rows[i].id.match(nodeRowId) == nodeRowId && rows[i].id != nodeRowId) {
                //Find the image of this nodes parent and make sure its expanded before I show it
                imgId = rows[i].id.replace('Node_', 'Image_');
                imgId = imgId.substr(0, imgId.lastIndexOf('_'));
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

function ToggleNode(nodeRowId) {
    //Update this image
    var imgId = nodeRowId.replace('Node_', 'Image_');
    var img = document.getElementById(imgId);

    if (img) {
        if (img.src.match("plus")) {
            img.src = '../images/minus.png';
            return ExpandNode(nodeRowId);
        }
        else {
            img.src = '../images/plus.png';
            return CollapseNodeRow(nodeRowId);
        }
    }
}

//Reconcilor Control Ajax calls
function GetReconcilorExceptionBar() {
    CallAjax('ReconcilorExceptionBar', '../ReconcilorExceptionBar.aspx');
    return false;
}

// Spiffy Calendar Control

function setSpiffyCalendarDefaults(minDateStr, maxDateStr, controlName) {
    // Lets you set the min and max date for spiffy control 
    // Just blanks out dates before and after so you can't select them.

    var TodaysDate = new Date();
    var cal1 = CalendarControls.Lookup(controlName);

    if (cal1 != null) {
        cal1.useDateRange = true;
        //calMgr.showHelpAlerts = true;

        if (minDateStr != null && minDateStr != '') {
            var minDate = new Date(minDateStr);
            cal1.setMinDate(minDate.getFullYear(), minDate.getMonth() + 1, minDate.getDate());
        }
        else {
            cal1.minDate = null;
        }

        if (maxDateStr != null && maxDateStr != '') {
            var maxDate = new Date(maxDateStr);
            cal1.setMaxDate(parseInt(maxDate.getFullYear()) + 1, parseInt(maxDate.getMonth()) + 1, maxDate.getDate());
        }
        else {
            cal1.maxDate = null;
        }
    }
}

// -------------------
// -- LOCATION CONTROL

function LocationDropDownChanged(locationCtrl, locationDivId, locationColWidth, showCaptions, controlId,
 callbackMethodUp, callbackMethodDown, onChange, lowestLocationTypeDescription) {
    if (locationCtrl.selectedIndex > -1) {
        var locationId = locationCtrl.options[locationCtrl.selectedIndex].value;
        LoadLocation(false, locationId, locationDivId, locationColWidth, showCaptions, controlId,
         callbackMethodUp, callbackMethodDown, onChange, lowestLocationTypeDescription)
    }
}

function LocationReconfigureControls(locationIdStatic, locationIdDynamic,
 locationNameIdStatic, locationNameIdDynamic, locationTypeDescriptionIdStatic, locationTypeDescriptionIdDynamic) {
    // copies the content of the controls from the "dynamic" controls into the "static/persistent" controls

    var staticControl;
    var dynamicControl;

    // locationId
    staticControl = document.getElementById(locationIdStatic);
    dynamicControl = document.getElementById(locationIdDynamic);
    if ((staticControl != null) && (dynamicControl != null)) {
        staticControl.value = dynamicControl.value
    }

    // locationName
    staticControl = document.getElementById(locationNameIdStatic);
    dynamicControl = document.getElementById(locationNameIdDynamic);
    if ((staticControl != null) && (dynamicControl != null)) {
        staticControl.value = dynamicControl.value
    }

    // locationTypeDescription
    staticControl = document.getElementById(locationTypeDescriptionIdStatic);
    dynamicControl = document.getElementById(locationTypeDescriptionIdDynamic);
    if ((staticControl != null) && (dynamicControl != null)) {
        staticControl.value = dynamicControl.value
    }
}

function LoadLocation(isLocationMandatory, locationId, locationDivId, locationColWidth, showCaptions, controlId,
 callbackMethodUp, callbackMethodDown, onChange, lowestLocationTypeDescription, initialLoad, omitInitialChange) {
    if (!lowestLocationTypeDescription) {
        lowestLocationTypeDescription = '';
    }
    if (!onChange) {
        onChange = '';
    }

    var qryStr = '../Utilities/LocationFilterLoad.aspx?LocationId=' + locationId +
		'&LocationDivId=' + locationDivId + '&LocationColWidth=' + locationColWidth +
		'&ShowCaptions=' + showCaptions + '&ControlId=' + controlId +
		'&CallbackMethodUp=' + callbackMethodUp + '&CallbackMethodDown=' + callbackMethodDown +
        '&onChange=' + onChange + '&lowestLocationTypeDescription=' + lowestLocationTypeDescription +
        '&initialLoad=' + initialLoad + '&omitInitialChange=' + omitInitialChange + '&Mandatory=' + isLocationMandatory;

    CallAjax(locationDivId, qryStr, 'image');

    return false;
}

function GetElementWidth(element) {
    if (typeof element.clip !== "undefined") {
        return element.clip.width;
    } else {
        if (element.style.pixelWidth) {
            return element.style.pixelWidth;
        } else {
            return element.offsetWidth;
        }
    }
}

function GetElementHeight(element) {
    if (typeof element.clip !== "undefined") {
        return element.clip.height;
    } else {
        if (element.style.pixelHeight) {
            return element.style.pixelHeight;
        } else {
            return element.offsetHeight;
        }
    }
}

function ValidateControls() {
    var validationMessage = '';

    for (var i = 0; i < ControlValidation; i++) 
    {
        validationMessage = validationMessage + ControlValidation(i);
    }
    
    if (validationMessage != '')
    {
        alert(validationMessage);
        return false;
    }
    else
    {
        return true;
    }
}

// This function should be called in situations where a set of dates is included in the form. If datesMustBeCurrentOrEarlier
// is true then a message will be displayed to the user that this is not advisible. If datesMustBeCurrentOrEarlier is false,
// this message will not be shown and the dates will simply be validated to ensure that the start date is before
// the finish date.
function SubmitFormWithDateValidation(datesMustBeCurrentOrEarlier, formName, elementId, urlToLoad, showLoading, finalCall) {
    // ensure that it is not undefined, we need to know if this is true or false so as to know whether
    // to alert the user that they shouldn't enter dates that are in the future.
    datesMustBeCurrentOrEarlier = (datesMustBeCurrentOrEarlier) ? true : false;

    // form should not be submitted if it fails validation
    if (ValidateSubmittedDatePickerRange(datesMustBeCurrentOrEarlier)) {
        SubmitForm(formName, elementId, urlToLoad, showLoading, finalCall);
    }
}

// Ensure that the dates are not in the future
// and the start is before the end date
function ValidateSubmittedDatePickerRange(datesMustBeCurrentOrEarlier) {
    var box;
    var errors = '';

    var foundStartResults = false;
    var foundEndResults = false;

    var currentDate = new Date();

    var listForms = document.getElementsByTagName("input");

    var i = 0;
    while (i < listForms.length && (!foundStartResults || !foundEndResults)) {
        if ((listForms[i].value.length > 0) && listForms[i].name.match(/Date(?:To|From)/)) {
            // DateFrom
            if (listForms[i].name.match(/Date(?:From)/)) {
                startDate = calMgr.getDateFromFormat(listForms[i].value, calMgr.defaultDateFormat);
                foundStartResults = true;

                var dateFromWellFormed = calMgr.validateDate(listForms[i], false);
                if (dateFromWellFormed == false) {
                    errors += 'The start date is invalid.';
                }

                // Only check future dates if datesMustBeCurrentOrEarlier is true
                if (datesMustBeCurrentOrEarlier && startDate > currentDate) {
                    errors += ' The start date must not be in the future.';
                }
            }

            // DateTo
            else if (listForms[i].name.match(/Date(?:To)/)) {
                endDate = calMgr.getDateFromFormat(listForms[i].value, calMgr.defaultDateFormat);
                foundEndResults = true;

                var dateToWellFormed = calMgr.validateDate(listForms[i], false);
                if (dateToWellFormed == false) {
                    errors += ' The end date is invalid.';
                }

                // Only check future dates if datesMustBeCurrentOrEarlier is true
                if (datesMustBeCurrentOrEarlier && endDate > currentDate) {
                    errors += ' The end date must not be in the future.';
                }
            }
        }

        i++;
    }

    // Only do a check if there are dates on this page!
    if (foundStartResults && foundEndResults) {
        if (startDate > endDate) {
            errors += ' The end date must be after the start date.';
        }
    }

    if (errors.length > 0) {
        box = alert(errors);
        return false;
    } else {
        return true;
    }
}

function HideDisplayElement(id, hide) {
    var e = document.getElementById(id);
    if (e) {
        if (hide) {
            e.style.display = "none"
        }
        
        e.disabled = true;

        var elems = e.getElementsByTagName('input');
        for (var i = 0; i < elems.length; i++) {
            elems[i].disabled = true;
        }

        elems = e.getElementsByTagName('select');
        for (var i = 0; i < elems.length; i++) {
            elems[i].disabled = true;
        }
    }
}

function ShowDisplayElement(id, hide) {
    var e = document.getElementById(id);
    if (e) {
        if (hide) {
            e.style.display = "inline"
        }
        e.disabled = false;

        var elems = e.getElementsByTagName('input');
        for (var i = 0; i < elems.length; i++) {
            elems[i].disabled = false;
        }

        elems = e.getElementsByTagName('select');
        for (var i = 0; i < elems.length; i++) {
            elems[i].disabled = false;
        }
    }
}