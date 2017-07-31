var dom = (document.getElementsByTagName) ? true : false;
var ie5 = (document.getElementsByTagName && document.all) ? true : false;
var arrowUp, arrowDown;

if (ie5 || dom)
	initSortTable();

function initSortTable() {
	arrowUp = document.createElement("SPAN");
	arrowUp.innerHTML = "&#8593;";

	arrowDown = document.createElement("SPAN");
	arrowDown.innerHTML = "&#8595;";
}

function sortTable(tableNode, nCol, bDesc, sType) {
	var tBody = tableNode.tBodies[0];
	var trs = tBody.rows;
	var a = new Array();
	var g = new Array();
	var GroupCount = -1;
	var RowCount;
	
	for (var i=0; i<trs.length; i++) {
		if (trs[i].cells[0].className == 'ReconcilorTableGroupRow' || trs[i].cells[0].className == 'ReconcilorTableTotalRow' || trs[i].cells[0].className == 'ReconcilorTableBalanceRow'){
			GroupCount++;
			g[GroupCount] = trs[i];
			a[GroupCount] = new Array();
			RowCount = -1;
		}else{
			if (GroupCount == -1){
				GroupCount++;
				g[GroupCount] = 0;
				a[GroupCount] = new Array();
				RowCount = -1;
			}
			
			RowCount++;
			a[GroupCount][RowCount] = trs[i];
		}
	}
	
	
	/*
	
	May be able to sort by groups by
	- capturing rows that are groups (colspan = td count of header row)
	- separating the out to multiple arrays
	- sorting the multiple arrays
	- appending them back
	
	*/
	for (var i=0; i<a.length; i++){
		a[i].sort(compareByColumn(nCol,bDesc,sType));
	}
	
	for (var j=0; j<g.length; j++){
		if (g[j] != 0){
			tBody.appendChild(g[j]);
		}
		
		for (var i=0; i<a[j].length; i++) {
			tBody.appendChild(a[j][i]);
		}
	}
}

function CaseInsensitiveString(s) {
	return String(s).toUpperCase();
}

function parseDate(s) {
	s = Trim(s);
	
	if (s.indexOf(' ') == -1){
		return calMgr.getDateFromFormat(s, 'd-MMM-yyyy');
	}else{
		var DatePart = s.substring(0, s.indexOf(' '));
		var TimePart = s.substring(s.indexOf(' ') + 1, s.length);
		var HourPart = parseInt(TimePart.substring(0, TimePart.indexOf(':')));
		var MinutePart = parseInt(TimePart.substring(TimePart.indexOf(':') + 1, TimePart.indexOf(' ')));
		var returnDateTime = calMgr.getDateFromFormat(DatePart, 'd-MMM-yyyy')
		
		if (TimePart.indexOf('PM') != -1){
			HourPart = HourPart + 12
		}
		
		returnDateTime.setHours(HourPart, MinutePart);
		
		return returnDateTime;
	}
	//return new Date(s.substring(s.lastIndexOf('/') + 1, s.length),  parseInt(s.substring(s.indexOf('/') + 1, s.lastIndexOf('/'))) - 1,s.substring(0, s.indexOf('/')));
}

/* alternative to number function
 * This one is slower but can handle non numerical characters in
 * the string allow strings like the follow (as well as a lot more)
 * to be used:
 *    "1,000,000"
 *    "1 000 000"
 *    "100cm"
 */

function toNumber(s) {
    return Number(s.replace(/[^0-9\.\-]/g, ""));
}

function compareByColumn(nCol, bDescending, sType) {
	var c = nCol;
	var d = bDescending;
	
	var fTypeCast = String;
	
	if ((sType == "Number") || (sType == "Date"))
		fTypeCast = toNumber;
	else
	    fTypeCast = CaseInsensitiveString;
		
//	else if (sType == "CaseInsensitiveString")
//		fTypeCast = CaseInsensitiveString;

	return function (n1, n2) {
		if (fTypeCast(getInnerText(n1.cells[c], sType)) < fTypeCast(getInnerText(n2.cells[c], sType)))
			return d ? -1 : +1;
		if (fTypeCast(getInnerText(n1.cells[c], sType)) > fTypeCast(getInnerText(n2.cells[c], sType)))
			return d ? +1 : -1;
		return 0;
	};
}


function sortColumn(e) {

	var tmp, el, tHeadParent;

	if (ie5)
		tmp = e.srcElement;
	else if (dom)
		tmp = e.target;

	tHeadParent = getParent(tmp, "TBODY");
	el = getParent(tmp, "TH");

	if (tHeadParent == null)
		return;
		
	if (el != null) {
		if (el.getAttribute("type") != "NoSort"){
			var p = el.parentNode;
			var i;

			// get the index of the td
			for (i=0; i<p.cells.length; i++) {
				if (p.cells[i] == el) break;
			}
			
			if (i != p.cells.length - 1){
				if (el._descending)	// catch the null
					el._descending = false;
				else
					el._descending = true;
				
				if (tHeadParent.arrow != null) {
					if (tHeadParent.arrow.parentNode != el) {
						tHeadParent.arrow.parentNode._descending = null;	//reset sort order		
					}
					tHeadParent.arrow.parentNode.removeChild(tHeadParent.arrow);
				}

				if (el._descending)
					tHeadParent.arrow = arrowDown.cloneNode(true);
				else
					tHeadParent.arrow = arrowUp.cloneNode(true);

				el.appendChild(tHeadParent.arrow);

				var table = getParent(el, "TABLE");
				table = document.getElementById(VbReplace(table.id, 'HeaderTable_', 'BodyTable_'));
				// can't fail
				
				sortTable(table,i,el._descending, el.getAttribute("type"));
			}
		}
	}
}


function getInnerText(el, sType) {

    // use hidden field for dates if it exists
    elements = el.getElementsByTagName("INPUT")
    if ((sType == "Date") && (elements != null)) {
        if (elements.length == 0) {
            return "";
        }
        else {
            elementAtPositionZero = elements[0]
            
            if (elementAtPositionZero == null) {
                return ""
            }
            else {
                return elementAtPositionZero.value
            }
        }
    }
    
        
        
	if (ie5) return el.innerText;	//Not needed but it is faster
	
	var str = "";
	
	for (var i=0; i<el.childNodes.length; i++) {
		switch (el.childNodes.item(i).nodeType) {
			case 1: //ELEMENT_NODE
				str += getInnerText(el.childNodes.item(i));
				break;
			case 3:	//TEXT_NODE
				str += el.childNodes.item(i).nodeValue;
				break;
		}
		
	}
	
	return str;
}

function getParent(el, pTagName) {
	if (el == null) return null;
	else if (el.nodeType == 1 && el.tagName.toLowerCase() == pTagName.toLowerCase())	// Gecko bug, supposed to be uppercase
		return el;
	else
		return getParent(el.parentNode, pTagName);
}