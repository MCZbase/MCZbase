function italicize(e){
	var textarea = document.getElementById(e);
	var len = textarea.value.length;
	var start = textarea.selectionStart;
	var end = textarea.selectionEnd;
	var sel = textarea.value.substring(start, end);
	if (sel.length>0){
		var replace = '<i>' + sel + '</i>';
		textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
	}
}
function bold(e){
	var textarea = document.getElementById(e);
	var len = textarea.value.length;
	var start = textarea.selectionStart;
	var end = textarea.selectionEnd;
	var sel = textarea.value.substring(start, end);
	if (sel.length>0){
		var replace = '<b>' + sel + '</b>';
		textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
	}
}
function superscript(e){
	var textarea = document.getElementById(e);
	var len = textarea.value.length;
	var start = textarea.selectionStart;
	var end = textarea.selectionEnd;
	var sel = textarea.value.substring(start, end);
	if (sel.length>0){
		var replace = '<sup>' + sel + '</sup>';
		textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
	}
}
function subscript(e){
	var textarea = document.getElementById(e);
	var len = textarea.value.length;
	var start = textarea.selectionStart;
	var end = textarea.selectionEnd;
	var sel = textarea.value.substring(start, end);
	if (sel.length>0){
		var replace = '<sub>' + sel + '</sub>';
		textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
	}
}
function getMCZDocs(url,anc) {
	var url;
	var anc;
	var baseUrl = "https://code.mcz.harvard.edu/wiki/index.php/";
	var extension = "";
	var fullURL = baseUrl + url + extension;
		if (anc != null) {
			fullURL += "#" + anc;
		}
	siteHelpWin=windowOpener(fullURL,"HelpWin","width=1024,height=640, resizable,scrollbars,location,toolbar");
}
function saveNewPartAtt () {
	jQuery.getJSON("/component/functions.cfc",
	{
		method : "saveNewPartAtt",
		returnformat : "json",
		attribute_type: $('#attribute_type_new').val(),
		attribute_value: $('#attribute_value_new').val(),
		attribute_units: $('#attribute_units_new').val(),
		determined_date: $('#determined_date_new').val(),
		determined_by_agent_id: $('#determined_id_new').val(),
		attribute_remark: $('#attribute_remark_new').val(),
		partID: $('#partID').val(),
		determined_agent: $('#determined_agent_new').val()
	},
		function (data) {
			console.log(data);
		}
	);
}
function setPartAttOptions(id,patype,collectionCDE) {
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getPartAttOptions",
			returnformat : "json",
			patype      : patype,
			collectionCDE	:collectionCDE
		},
		function (data) {
			var cType=data.TYPE;
			var valElem='attribute_value_' + id;
			var unitElem='attribute_units_' + id;
			if (data.TYPE=='unit') {
				var d='<input type="text" name="' + valElem + '" id="' + valElem + '">';
				$('#v_' + id).html(d);
				var theVals=data.VALUES.split('|');
				var d='<select name="' + unitElem + '" id="' + unitElem + '">';
	  			for (a=0; a<theVals.length; ++a) {
					d+='<option value="' + theVals[a] + '">'+ theVals[a] +'</option>';
				}
	  			d+="</select>";
	  			$('#u_' + id).html(d);
			} else if (data.TYPE=='value') {
				var theVals=data.VALUES.split('|');
				var d='<select name="' + valElem + '" id="' + valElem + '">';
	  			for (a=0; a<theVals.length; ++a) {
					d+='<option value="' + theVals[a] + '">'+ theVals[a] +'</option>';
				}
	  			d+="</select>";
	  			$('#v_' + id).html(d);
				$('#u_' + id).html('');
			} else {
				var dv='<input type="text" name="' + valElem + '" id="' + valElem + '">';
				$('#v_' + id).html(dv);
				$('#u_' + id).html('');
			}
		}
	);
}
function mgPartAtts(partID, collectionCDE) {
	addBGDiv('closePartAtts()');
	var theDiv = document.createElement('iFrame');
	theDiv.id = 'partsAttDiv';
	theDiv.className = 'annotateBox';
	theDiv.innerHTML='<br>Loading...';
	document.body.appendChild(theDiv);
	var ptl="/form/partAtts.cfm?partID=" + partID + "&collectionCde=" + collectionCDE;
	theDiv.src=ptl;
	viewport.init("#partsAttDiv");
}
function mgPartAttsDE(ctPartName, collection_CDE) {
	addBGDiv('closePartAtts()');
	var theDiv = document.createElement('iFrame');
	theDiv.id = 'partsAttDiv';
	theDiv.className = 'annotateBox';
	theDiv.innerHTML='<br>Loading...';
	document.body.appendChild(theDiv);
	var ptl="/form/partAtts.cfm?partID=" + ctPartName + "&collection_Cde=" + collection_CDE;
	theDiv.src=ptl;
	viewport.init("#partsAttDiv");
}
function closePartAtts() {
	/*
	 *
	 * var theDiv = document.getElementById('bgDiv');
	document.body.removeChild(theDiv);
	var theDiv = document.getElementById('partsAttDiv');
	document.body.removeChild(theDiv);

		var theDiv = parent.document.getElementById('bgDiv');
	parent.document.body.removeChild(theDiv);
	var theDiv = parent.document.getElementById('partsAttDiv');
	parent.document.body.removeChild(theDiv);


	*/
	$('#bgDiv').remove();
	$('#partsAttDiv').remove();
	$('#bgDiv', window.parent.document).remove();
	$('#partsAttDiv', window.parent.document).remove();


}
function cloneTransAgent(i){
	var id=jQuery('#agent_id_' + i).val();
	var name=jQuery('#trans_agent_' + i).val();
	var role=jQuery('#cloneTransAgent_' + i).val();
	jQuery('#cloneTransAgent_' + i).val('');
	addTransAgent (id,name,role);
}

function addTransAgent (id,name,role) {
   addTransAgentToForm(id,name,role,'editloan');
}
/** Add an agent to a transaction edit form.
 *
 * Assumes the presence of an input numAgents holding a count of the number of agents in the transaction.
 * Assumes the presence of an html table with an id loanAgents, to which the new agent line is added as the last row.
 */
function addTransAgentToForm (id,name,role,formid) {
	if (typeof id == "undefined") {
		id = "";
	 }
	if (typeof name == "undefined") {
		name = "";
	 }
	if (typeof role == "undefined") {
		role = "";
	 }
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getTrans_agent_role",
			returnformat : "json",
			queryformat : 'column'
		},
		function (data) {
			var i=parseInt($('#numAgents').val())+1;
			var d='<tr><td>';
			d+='<input type="hidden" name="trans_agent_id_' + i + '" id="trans_agent_id_' + i + '" value="new">';
			d+='<input type="text" id="trans_agent_' + i + '" name="trans_agent_' + i + '" class="reqdClr" size="30" value="' + name + '"';
  			d+=' onchange="getAgent(\'agent_id_' + i + '\',\'trans_agent_' + i + '\',\'' + formid + '\',this.value);"';
  			d+=' return false;"	onKeyPress="return noenter(event);">';
  			d+='<input type="hidden" id="agent_id_' + i + '" name="agent_id_' + i + '" value="' + id + '" ';
			d+=' onchange=" updateAgentLink($(\'#agent_id_' + i +'\').val(),\'agentViewLink_' + i + '\'); " >';
  			d+='</td><td><span id="agentViewLink_' + i + '"></span></td><td>';
  			d+='<select name="trans_agent_role_' + i + '" id="trans_agent_role_' + i + '">';
  			for (a=0; a<data.ROWCOUNT; ++a) {
				d+='<option ';
				if(role==data.DATA.TRANS_AGENT_ROLE[a]){
					d+=' selected="selected"';
				}
				d+=' value="' + data.DATA.TRANS_AGENT_ROLE[a] + '">'+ data.DATA.TRANS_AGENT_ROLE[a] +'</option>';
			}
  			d+='</td><td>';
  			d+='<input type="checkbox" name="del_agnt_' + i + '" name="del_agnt_' + i + '" value="1">';
  			d+='</td><td>';
  			d+='<select id="cloneTransAgent_' + i + '" onchange="cloneTransAgent(' + i + ')" style="width:8em">';
  			d+='<option value=""></option>';
  			for (a=0; a<data.ROWCOUNT; ++a) {
				d+='<option value="' + data.DATA.TRANS_AGENT_ROLE[a] + '">'+ data.DATA.TRANS_AGENT_ROLE[a] +'</option>';
			}
			d+='</select>';
  			d+='</td></tr>';
  			$('#numAgents').val(i);
  			jQuery('#loanAgents tr:last').after(d);
		}
	);
}

function cloneTransAgentDeacc(i){
	var id=jQuery('#agent_id_' + i).val();
	var name=jQuery('#trans_agent_' + i).val();
	var role=jQuery('#cloneTransAgent_' + i).val();
	jQuery('#cloneTransAgent_' + i).val('');
	addTransAgentDeacc (id,name,role);
}
function addTransAgentDeacc (id,name,role) {
	if (typeof id == "undefined") {
		id = "";
	 }
	if (typeof name == "undefined") {
		name = "";
	 }
	if (typeof role == "undefined") {
		role = "";
	 }
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getTrans_agent_role",
			returnformat : "json",
			queryformat : 'column'
		},
		function (data) {
			var i=parseInt(document.getElementById('numAgents').value)+1;
			var d='<tr><td>';
			d+='<input type="hidden" name="trans_agent_id_' + i + '" id="trans_agent_id_' + i + '" value="new">';
			d+='<input type="text" id="trans_agent_' + i + '" name="trans_agent_' + i + '" class="reqdClr" size="30" value="' + name + '"';
  			d+=' onchange="getAgent(\'agent_id_' + i + '\',\'trans_agent_' + i + '\',\'editDeacc\',this.value);"';
  			d+=' return false;"	onKeyPress="return noenter(event);">';
  			d+='<input type="hidden" id="agent_id_' + i + '" name="agent_id_' + i + '" value="' + id + '">';
  			d+='</td><td>';
  			d+='<select name="trans_agent_role_' + i + '" id="trans_agent_role_' + i + '">';
  			for (a=0; a<data.ROWCOUNT; ++a) {
				d+='<option ';
				if(role==data.DATA.TRANS_AGENT_ROLE[a]){
					d+=' selected="selected"';
				}
				d+=' value="' + data.DATA.TRANS_AGENT_ROLE[a] + '">'+ data.DATA.TRANS_AGENT_ROLE[a] +'</option>';
			}
  			d+='</td><td>';
  			d+='<input type="checkbox" name="del_agnt_' + i + '" name="del_agnt_' + i + '" value="1">';
  			d+='</td><td>';
  			d+='<select id="cloneTransAgent_' + i + '" onchange="cloneTransAgent(' + i + ')" style="width:8em">';
  			d+='<option value=""></option>';
  			for (a=0; a<data.ROWCOUNT; ++a) {
				d+='<option value="' + data.DATA.TRANS_AGENT_ROLE[a] + '">'+ data.DATA.TRANS_AGENT_ROLE[a] +'</option>';
			}
			d+='</select>';
  			d+='</td><td>-</td></tr>';
  			document.getElementById('numAgents').value=i;
  			jQuery('#deaccAgents tr:last').after(d);
		}
	);
}

function addLendersObject (transaction_id,catalog_number,sci_name,no_of_spec,spec_prep,type_status,country_of_origin,object_remarks) {

	if (typeof catalog_number == "undefined") {
		catalog_number = "";
	 }
	if (typeof sci_name == "undefined") {
		sci_name = "";
	 }
    if (typeof no_of_spec == "undefined") {
		no_of_spec = "";
	 }
     if (typeof spec_prep == "undefined") {
		spec_prep = "";
	 }
     if (typeof type_status == "undefined") {
		type_status = "";
	 }
    if (typeof country_of_origin == "undefined") {
		country_of_origin = "";
	 }
      if (typeof object_remarks == "undefined") {
		object_remarks = "";
	 }

	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getLenders_Object",
			returnformat : "json",
			queryformat : 'column'
		},
                   	function (data) {
			var i=parseInt(document.getElementById('numObject').value)+1;
			var d='<input type="hidden" name="transaction_id_' + i + '" id="transaction_id_' + i + '" value="newLender_Object">';
			d+='<label for "catalog_number_' + i + '"><input type="text" id="catalog_number_' + i + '" name="catalog_number_' + i + '" value="catalog_number_' + i + '"></label>';
  			d+='<label for "sci_name_' + i + '"><input type="text" id="sci_name_' + i + '" name="sci_name_' + i + '" value="sci_name_' + i + '"></label>';
  			d+='<label for "no_of_spec_' + i + '"><input type="text" id="no_of_spec_' + i + '" name="no_of_spec_' + i + '" value="no_of_spec_' + i + '"></label>';
  			d+='<label for "spec_prep_' + i + '"><input type="text" id="spec_prep_' + i + '" name="spec_prep_' + i + '" value="spec_prep_' + i + '"></label>';
  			d+='<label for "type_status_' + i + '"><input type="text" id="type_status_' + i + '" name="type_status_' + i + '" value="type_status_' + i + '"></label>';
  			d+='<label for "country_of_origin_' + i + '"><input type="text" id="country_of_origin_' + i + '" name="country_of_origin_' + i + '" value="country_of_origin_' + i + '"></label>';
            d+='<label for "object_remarks_' + i + '"><input type="text" id="object_remarks_' + i + '" name="object_remarks_' + i + '" value="object_remarks_' + i + '"></label>';
  			document.getElementById('numObject').value=i;
  			jQuery('#addLender_Object label:last').after(d);
		}

	);
}

jQuery("#uploadMedia").live('click', function(e){
	addBGDiv('removeUpload()');
	var theDiv = document.createElement('iFrame');
	theDiv.id = 'uploadDiv';
	theDiv.className = 'uploadMediaDiv';
	theDiv.innerHTML='<br>Loading...';
	document.body.appendChild(theDiv);
	var ptl="/info/upMedia.cfm";
	theDiv.src=ptl;
	viewport.init("#uploadDiv");
});
function removeUpload() {
	if(document.getElementById('uploadDiv')){
		jQuery('#uploadDiv').remove();
	}
	removeBgDiv();
}
function closeUpload(media_uri,preview_uri) {
	document.getElementById('media_uri').value=media_uri;
	document.getElementById('preview_uri').value=preview_uri;
	removeUpload();
}
function generateMD5() {
	var theImageFile=document.getElementById('media_uri').value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "genMD5",
			uri : theImageFile,
			returnformat : "json",
			queryformat : 'column'
		},
		success_generateMD5
	);
}
function success_generateMD5(result){
	var cc=document.getElementById('number_of_labels').value;
	cc=parseInt(cc)+parseInt(1);
	addLabel(cc);
	var lid='label__' + cc;
	var lvid='label_value__' + cc;
	var nl=document.getElementById(lid);
	var nlv=document.getElementById(lvid);
	nl.value='MD5 checksum';
	nlv.value=result;
}
function closePreviewUpload(preview_uri) {
	var theDiv = document.getElementById('uploadDiv');
	document.body.removeChild(theDiv);
	document.getElementById('preview_uri').value=preview_uri;
}

function clickUploadPreview(){
	var theDiv = document.createElement('iFrame');
	theDiv.id = 'uploadDiv';
	theDiv.name = 'uploadDiv';
	theDiv.className = 'uploadMediaDiv';
	document.body.appendChild(theDiv);
	var guts = "/info/upMediaPreview.cfm";
	theDiv.src=guts;
}
function getBorrow(StringFld,IdFld,formName){
	var url="/picks/findBorrow.cfm";
	var pickwin=url+"?BorrowNumFld="+StringFld+"&BorrowIdFld="+IdFld+"&formName="+formName;
	pickwin=window.open(pickwin,"","width=600,height=400, resizable,scrollbars");
}
function pickedRelationship (id){
	var relationship=document.getElementById(id).value;
	var formName=document.getElementById(id).form.getAttribute('name');
	var ddPos = id.lastIndexOf('__');
	var elementNumber=id.substring(ddPos+2,id.length);
	var relatedTableAry=relationship.split(" ");
	var relatedTable=relatedTableAry[relatedTableAry.length-1];
	var idInputName = 'related_id__' + elementNumber;
	var dispInputName = 'related_value__' + elementNumber;
	var hid=document.getElementById(idInputName);
	hid.value='';
	var inp=document.getElementById(dispInputName);
	inp.value='';
	if (relatedTable=='') {
		// do nothing, cleanup already happened
	} else if (relatedTable=='agent'){
		//addAgentRelation(elementNumber);
		getAgent(idInputName,dispInputName,formName,'');
	} else if (relatedTable=='locality'){
		LocalityPick(idInputName,dispInputName,formName);
	} else if (relatedTable=='collecting_event'){
		findCollEvent(idInputName,formName,dispInputName);
	} else if (relatedTable=='cataloged_item'){
		findCatalogedItem(idInputName,dispInputName,formName);
	} else if (relatedTable=='project'){
		getProject(idInputName,dispInputName,formName);
	} else if (relatedTable=='taxonomy'){
		taxaPick(idInputName,dispInputName,formName);
	} else if (relatedTable=='publication'){
		getPublication(dispInputName,idInputName,'',formName);
	} else if (relatedTable=='accn'){
		getAccn(dispInputName,idInputName,formName);
	} else if (relatedTable=='deaccession'){
		getDeaccession(dispInputName,idInputName,formName);
	} else if (relatedTable=='permit'){
		getPermit(dispInputName,idInputName,formName);
	} else if (relatedTable=='loan'){
		getLoan(dispInputName,idInputName,formName);
	} else if (relatedTable=='borrow'){
		getBorrow(dispInputName,idInputName,formName);
	} else if (relatedTable=='media'){
		findMedia(dispInputName,idInputName);
	} else if (relatedTable=='delete'){
		document.getElementById(dispInputName).value='Marked for deletion.....';
	} else {
		alert('Something is broken. I have no idea what to do with a relationship to ' + relatedTable);
	}
}

/*
function addAgentRelation (elementNumber){
	var theDivName = 'relationshipDiv__' + elementNumber;
	var theDiv=document.getElementById(theDivName);
	var theSpanName = 'relationshipSpan__' + elementNumber;
	nSpan = document.createElement("span");
	var idInputName = 'agent_id_' + elementNumber;
	var dispInputName = 'agent_name_' + elementNumber;
	var theHtml='<input type="hidden" name="' + idInputName + '">';
	theHtml+='<input type="text" name="' + dispInputName + '" size="80">';
	nSpan.innerHTML=theHtml;
	nSpan.id=theSpanName;
	theDiv.appendChild(nSpan);
	getAgent(idInputName,dispInputName,'newMedia','');
}
function addLocalityRelation (elementNumber){
	var theDivName = 'relationshipDiv__' + elementNumber;
	var theDiv=document.getElementById(theDivName);
	var theSpanName = 'relationshipSpan__' + elementNumber;
	nSpan = document.createElement("span");
	var idInputName = 'locality_id_' + elementNumber;
	var dispInputName = 'spec_locality_' + elementNumber;
	var theHtml='<input type="hidden" name="' + idInputName + '">';
	theHtml+='<input type="text" name="' + dispInputName + '" size="80">';
	nSpan.innerHTML=theHtml;
	nSpan.id=theSpanName;
	theDiv.appendChild(nSpan);
	LocalityPick(idInputName,dispInputName,'newMedia');
}
*/
function addRelation(n) {
	var pDiv=document.getElementById('relationships');
	var nDiv = document.createElement('div');
	nDiv.id='relationshipDiv__' + n;
	pDiv.appendChild(nDiv);
	var n1=n-1;
	var selName='relationship__' + n1;
	var nSel = document.getElementById(selName).cloneNode(true);
	nSel.name="relationship__" + n;
	nSel.id="relationship__" + n;
	nSel.value='';
	nDiv.appendChild(nSel);

	c = document.createElement("textNode");
	c.innerHTML=":&nbsp;";
	nDiv.appendChild(c);

	var n1=n-1;
	var inpName='related_value__' + n1;
	var nInp = document.getElementById(inpName).cloneNode(true);
	nInp.name="related_value__" + n;
	nInp.id="related_value__" + n;
	nInp.value='';
	nDiv.appendChild(nInp);

	var hName='related_id__' + n1;
	var nHid = document.getElementById(hName).cloneNode(true);
	nHid.name="related_id__" + n;
	nHid.id="related_id__" + n;
	nDiv.appendChild(nHid);

	var mS = document.getElementById('addRelationship');
	pDiv.removeChild(mS);
	var np1=n+1;
	var oc="addRelation(" + np1 + ")";
	mS.setAttribute("onclick",oc);
	pDiv.appendChild(mS);

	var cc=document.getElementById('number_of_relations');
	cc.value=parseInt(cc.value)+1;
}

function addLabel (n) {
	var pDiv=document.getElementById('labels');
	var nDiv = document.createElement('div');
	nDiv.id='labelsDiv__' + n;
	pDiv.appendChild(nDiv);
	var n1=n-1;
	var selName='label__' + n1;
	var nSel = document.getElementById(selName).cloneNode(true);
	nSel.name="label__" + n;
	nSel.id="label__" + n;
	nSel.value='';
	nDiv.appendChild(nSel);

	c = document.createElement("textNode");
	c.innerHTML=":&nbsp;";
	nDiv.appendChild(c);

	var inpName='label_value__' + n1;
	var nInp = document.getElementById(inpName).cloneNode(true);
	nInp.name="label_value__" + n;
	nInp.id="label_value__" + n;
	nInp.value='';
	nDiv.appendChild(nInp);

	var mS = document.getElementById('addLabel');
	pDiv.removeChild(mS);
	var np1=n+1;
	var oc="addLabel(" + np1 + ")";
	mS.setAttribute("onclick",oc);
	pDiv.appendChild(mS);

	var cc=document.getElementById('number_of_labels');
	cc.value=parseInt(cc.value)+1;
}
function tog_AgentRankDetail(toState){
	if(toState==1){
		document.getElementById('agentRankDetails').style.display='block';
		jQuery('#t_agentRankDetails').text('Hide Details').removeAttr('onclick').bind("click", function() {
			tog_AgentRankDetail(0);
		});
	} else {
		document.getElementById('agentRankDetails').style.display='none';
		jQuery('#t_agentRankDetails').text('Show Details').removeAttr('onclick').bind("click", function() {
			tog_AgentRankDetail(1);
		});
	}
}
function loadAgentRankSummary(targetId,agentId) {
   jQuery.getJSON("/component/functions.cfc",
      {
         method : "getAgentRanks",
         agent_id : agentId,
         returnformat : 'json',
         queryformat : 'column'
      },
      function (result) {
         if (result.DATA.STATUS[0]==1) {
            var output = "Ranking: " ;
  	    for (a=0; a<result.ROWCOUNT; ++a) {
               output =  output + result.DATA.AGENT_RANK[a] + "&nbsp;" + result.DATA.CT[a]
               if (result.DATA.AGENT_RANK[a]=='F') {
                  output = output + "<img src='/images/flag-red.svg.png' width='16'>" ;
               }
               if (a<result.ROWCOUNT-1) { output = output + ";&nbsp;"; }
            }
            $("#" + targetId).html(output);
         } else {
            $("#" + targetId).html(result.DATA.MESSAGE[0]);
         }
      }
   );
}
function saveAgentRank(){
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "saveAgentRank",
			agent_id : $('#agent_id').val(),
			agent_rank : $('#agent_rank').val(),
			remark : $('#remark').val(),
			transaction_type : $('#transaction_type').val(),
			returnformat : 'json',
			queryformat : 'column'
		},
		function (data) {
			if(data.length>0 && data.substring(0,4)=='fail'){
				alert(data);
				$('#saveAgentRankFeedback').append(d);
			} else {
				var ih = 'Thank you for adding an agent rank.';
				$('#saveAgentRankFeedback').append(ih);
			}
		}
	);
}
function pickThis (fld,idfld,display,aid) {
	document.getElementById(fld).value=display;
	document.getElementById(idfld).value=aid;
	document.getElementById(fld).className='goodPick';
	removePick();
}
function removePick() {
	if(document.getElementById('pickDiv')){
		jQuery('#pickDiv').remove();
	}
	removeBgDiv();
}
function addBGDiv(f){
	var bgDiv = document.createElement('div');
	bgDiv.id = 'bgDiv';
	bgDiv.className = 'bgDiv';
	if(f==null || f.length==0){
		f="removeBgDiv()";
	}
	bgDiv.setAttribute('onclick',f);
	document.body.appendChild(bgDiv);
	viewport.init("#bgDiv");
}
function removeBgDiv () {
	if(document.getElementById('bgDiv')){
		jQuery('#bgDiv').remove();
	}
}
/** This may be obsolete, replaced by getTransAgent? **/
function get_AgentName(name,fld,idfld){
	addBGDiv('removePick()');
	var theDiv = document.createElement('div');
	theDiv.id = 'pickDiv';
	theDiv.className = 'pickDiv';
	theDiv.innerHTML='<br>Loading...';
	document.body.appendChild(theDiv);
	var ptl="/picks/getAgentName.cfm";
	jQuery.get(ptl,{agentname: name, fld: fld, idfld: idfld},function(data){
		document.getElementById('pickDiv').innerHTML=data;
		viewport.init("#pickDiv");
	});
}
function addLink (n) {
	var lid = jQuery('#linkTab tr:last').attr("id");
	var lastID=lid.replace('linkRow','');
	if (lastID.length==0){
		lastID=0;
	}
	var thisID=parseInt(lastID) + 1;
	var newRow='<tr id="linkRow' + thisID + '">';
	newRow+='<td>';
	newRow+='<input type="text"  size="60" name="link' + thisID + '" id="link' + thisID + '">';
	newRow+='</td>';
	newRow+='<td>';
	newRow+='<input type="text"  size="10" name="description' + thisID + '" id="description' + thisID + '">';
	newRow+='</td>';
	newRow+='</tr>';
	jQuery('#linkTab tr:last').after(newRow);
	document.getElementById('numberLinks').value=thisID;
}

function addAgent (n) {
	var lid = jQuery('#authTab tr:last').attr("id");
	var lastID='';
	if (typeof lid !== 'undefined') {
	   lastID = lid.replace('authortr','');
	}
	if(lastID==''){
		lastID=0;
	}
	var thisID=parseInt(lastID) + 1;
	var newRow='<tr id="authortr' + thisID + '">';
	newRow+='<td>';
	newRow+='<select name="author_role_' + thisID + '" id="author_role_' + thisID + '1">';
	newRow+='<option value="author">author</option>';
	newRow+='<option value="editor">editor</option>';
	newRow+='</select>';
	newRow+='</td>';
	newRow+='<td>';
	newRow+='<input type="hidden" name="author_id_' + thisID + '" id="author_id_' + thisID + '">';
	newRow+='<input type="text" name="author_name_' + thisID + '" id="author_name_' + thisID + '" class="reqdClr"  size="50" ';
	newRow+='onchange="findAgentName(\'author_id_' + thisID + '\',this.name,this.value);"';
	newRow+='onKeyPress="return noenter(event);">';
	newRow+='</td>';
	newRow+='</tr>';
	jQuery('#authTab tr:last').after(newRow);
	document.getElementById('numberAuthors').value=thisID;
}
function removeAgent() {
	var lid = jQuery('#authTab tr:last').attr("id");
	var lastID=lid.replace('authortr','');
	var thisID=parseInt(lastID) - 1;
	document.getElementById('numberAuthors').value=thisID;
	if(thisID>=1){
		jQuery('#authTab tr:last').remove();
	} else {
		alert('You must have at least one author');
	}
}
function removeLastAttribute() {
	var lid = jQuery('#attTab tr:last').attr("id");
	if (lid===undefined || lid.length==0) {
		alert('nothing to remove');
		return false;
	}
	var lastID=lid.replace('attRow','');
	var thisID=parseInt(lastID) - 1;
	document.getElementById('numberAttributes').value=thisID;
	jQuery('#attTab tr:last').remove();
}
function addAttribute(V){
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getPubAttributes",
			attribute : V,
			returnformat : "json",
			queryformat : 'column'
		},
		function (d) {
			var lid=jQuery('#attTab tr:last').attr("id");
			if(lid === undefined || lid.length==0){
				lid='attRow0';
			}
			var lastID=lid.replace('attRow','');
			var thisID=parseInt(lastID) + 1;
			var newRow='<tr id="attRow' + thisID + '"><td>' + V;
			newRow+='<input type="hidden" name="attribute_type' + thisID + '"';
			newRow+=' id="attribute_type' + thisID + '" class="reqdClr" value="' + V + '"></td><td>';
			if(d.length>0 && d.substring(0,4)=='fail'){
				alert(d);
				return false;
			} else if(d=='nocontrol'){
				newRow+='<input type="text" name="attribute' + thisID + '" id="attribute' + thisID + '" size="50" class="reqdClr">';
			} else {
				newRow+='<select name="attribute' + thisID + '" id="attribute' + thisID + '" class="reqdClr">';
				for (i=0; i<d.ROWCOUNT; ++i) {
					newRow+='<option value="' + d.DATA.V[i] + '">'+ d.DATA.V[i] +'</option>';
				}
				newRow+='</select>';
			}
			newRow+="</td></tr>";
			jQuery('#attTab tr:last').after(newRow);
			document.getElementById('numberAttributes').value=thisID;
		}
	);
}
function setDefaultPub(t){
	if(t=='journal article'){
    	addAttribute('journal name');
    	// crude but try to get this stuff in order if we can...
    	setTimeout( "addAttribute('begin page')", 1000);
    	setTimeout( "addAttribute('end page');", 1500);
    	setTimeout( "addAttribute('volume');", 2000);
    	setTimeout( "addAttribute('issue');", 2500);

	} else if (t=='book'){
		addAttribute('publisher');
    setTimeout( "addAttribute('page total')", 1000);
		setTimeout("addAttribute('volume')", 1200);


	} else if (t=='book section'){
    	addAttribute('begin page');
		setTimeout( "addAttribute('end page')", 1000);
    setTimeout( "addAttribute('book title')", 1500);
    setTimeout( "addAttribute('publisher');", 2000);
		setTimeout( "addAttribute('page total')", 2500);


	} else if (t=='journal section'){
    	addAttribute('journal name');
		setTimeout( "addAttribute('begin page');", 1000);
		setTimeout( "addAttribute('end page')", 1500);
    setTimeout( "addAttribute('journal section')", 2200);
		setTimeout( "addAttribute('volume');", 2500);
		setTimeout( "addAttribute('issue');", 2800);


	} else if (t=='data release'){
			addAttribute('publisher');
		setTimeout( "addAttribute('version');", 2800);

	} else if (t=='serial monograph'){
    	addAttribute('journal name');
		setTimeout( "addAttribute('begin page');", 1000);
		setTimeout( "addAttribute('end page')", 1500);
		setTimeout( "addAttribute('publisher');", 2000);
		setTimeout( "addAttribute('number');", 2200);
		setTimeout( "addAttribute('volume');", 2500);
		setTimeout( "addAttribute('issue');", 2800);



	}

}
function deleteAgent(r){
	jQuery('#author_id_' + r).val("-1");
	jQuery('#authortr' + r + ' td:nth-child(1)').addClass('red').text(jQuery('#author_role_' + r).val());
	jQuery('#authortr' + r + ' td:nth-child(2)').addClass('red').text(jQuery('#author_name_' + r).val());
	jQuery('#authortr' + r + ' td:nth-child(3)').addClass('red').text('deleted');
}
function deletePubAtt(r){
	var newElem='<input type="hidden" name="attribute' + r + '" id="attribute' + r + '" value="deleted">';
	jQuery('#attRow' + r + ' td:nth-child(1)').addClass('red').text(jQuery('#attribute_type' + r).val());
	jQuery('#attRow' + r + ' td:nth-child(2)').addClass('red').text(jQuery('#attribute' + r).val()).append(newElem);
	jQuery('#attRow' + r + ' td:nth-child(3)').addClass('red').text('deleted');
}
function deleteLink(r){
	var newElem='<input type="hidden" name="link' + r + '" id="link' + r + '" value="deleted">';
	jQuery('#linkRow' + r + ' td:nth-child(1)').addClass('red').text('deleted').append(newElem);
	jQuery('#linkRow' + r + ' td:nth-child(2)').addClass('red').text('');
}

