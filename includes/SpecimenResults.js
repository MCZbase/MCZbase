function saveSearch(returnURL){
	var sName=prompt("Name this search", "my search");
	if (sName!==null){
		var sn=encodeURIComponent(sName);
		var ru=encodeURI(returnURL);
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "saveSearch",
				returnURL : ru,
				srchName : sn,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				if(r!='success'){
					alert(r);
				}
			}
		);
	}
}
function insertTypes(idList) {
	var s=document.createElement('DIV');
	s.id='ajaxStatus';
	s.className='ajaxStatus';
	s.innerHTML='Checking for Types...';
	document.body.appendChild(s);
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getTypes",
			idList : idList,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			var sBox=document.getElementById('ajaxStatus');
			try{
				sBox.innerHTML='Processing Types....';
				for (i=0; i<result.ROWCOUNT; ++i) {
					var sid=result.DATA.COLLECTION_OBJECT_ID[i];
					var tl=result.DATA.TYPELIST[i];
					var sel='CatItem_' + sid;
					if (sel.length>0){
						var el=document.getElementById(sel);
						var ns='<div class="showType">' + tl + '</div>';
						el.innerHTML+=ns;
					}
				}
			}
			catch(e){}
			document.body.removeChild(sBox);
		}
	);
}
function insertMedia(idList) {
	var s=document.createElement('DIV');
	s.id='ajaxStatus';
	s.className='ajaxStatus';
	s.innerHTML='Checking for Media...';
	document.body.appendChild(s);
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getMedia",
			idList : idList,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			try{
				var sBox=document.getElementById('ajaxStatus');
				sBox.innerHTML='Processing Media....';
				for (i=0; i<result.ROWCOUNT; ++i) {
					var sel;
					var sid=result.DATA.COLLECTION_OBJECT_ID[i];
					var mid=result.DATA.MEDIA_ID[i];
					var rel=result.DATA.MEDIA_RELATIONSHIP[i];
					if (rel=='cataloged_item') {
						sel='CatItem_' + sid;
					} else if (rel=='collecting_event') {
						sel='SpecLocality_' + sid;
					}
					if (sel.length>0){
						var el=document.getElementById(sel);
						var ns='<a href="/MediaSearch.cfm?action=search&media_id='+mid+'" class="mediaLink" target="_blank" id="mediaSpan_'+sid+'">';
						ns+='Media';
						ns+='</a>';
						el.innerHTML+=ns;
					}
				}
				document.body.removeChild(sBox);
				}
			catch(e) {
				sBox=document.getElementById('ajaxStatus');
				document.body.removeChild(sBox);
			}
		}
	);
}
function addPartToLoan(partID) {
	var rs = "item_remark_" + partID;
	var is = "item_instructions_" + partID;
	var ss = "subsample_" + partID;
	var remark=document.getElementById(rs).value;
	var instructions=document.getElementById(is).value;
	var subsample=document.getElementById(ss).checked;
	if (subsample==true) {
		subsample=1;
	} else {
		subsample=0;
	}
	var transaction_id=document.getElementById('transaction_id').value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "addPartToLoan",
			transaction_id : transaction_id,
			partID : partID,
			remark : remark,
			instructions : instructions,
			subsample : subsample,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			var rar = result.split("|");
			var status=rar[0];
			if (status==1){
				var b = "theButton_" + rar[1];
				var theBtn = document.getElementById(b);
				theBtn.value="In Loan";
				theBtn.onclick="";
			}else{
				var msg = rar[1];
				alert('An error occured!\n' + msg);
			}
		}
	);
}
function addPartToDeacc(partID) {
	var rs = "item_remark_" + partID;
	var is = "item_instructions_" + partID;
	var ss = "subsample_" + partID;
	var remark=document.getElementById(rs).value;
	var instructions=document.getElementById(is).value;
	var subsample=document.getElementById(ss).checked;
	if (subsample==true) {
		subsample=1;
	} else {
		subsample=0;
	}
	var transaction_id=document.getElementById('transaction_id').value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "addPartToDeacc",
			transaction_id : transaction_id,
			partID : partID,
			remark : remark,
			instructions : instructions,
			subsample : subsample,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			var rar = result.split("|");
			var status=rar[0];
			if (status==1){
				var b = "theButton_" + rar[1];
				var theBtn = document.getElementById(b);
				theBtn.value="In Deaccession";
				theBtn.onclick="";
			}else{
				var msg = rar[1];
				alert('An error occured!\n' + msg);
			}
		}
	);
}
function success_makePartThingy(r){
	result=r.DATA;
	var lastID;
	var theTable;
	for (i=0; i<r.ROWCOUNT; ++i) {
		var cid = 'partCell_' + result.COLLECTION_OBJECT_ID[i];
		if (document.getElementById(cid)){
			var theCell = document.getElementById(cid);
			theCell.innerHTML='Fetching loan data....';
			if (lastID == result.COLLECTION_OBJECT_ID[i]) {
				theTable += "<tr>";
			} else {
				theTable = '<table border width="100%"><tr>';
			}
			theTable += '<td nowrap="nowrap" class="specResultPartCell">';
			theTable += '<i>' + result.PART_NAME[i];
			if (result.SAMPLED_FROM_OBJ_ID[i] > 0) {
				theTable += '&nbsp;sample';
			}
         theTable += '(' + result.PRESERVE_METHOD[i] + ')';
         theTable += '[' + result.LOT_COUNT[i] + ']';
			theTable += "&nbsp;(" + result.COLL_OBJ_DISPOSITION[i] + ")</i> [" + result.BARCODE[i] + "]";
			theTable += '</td><td nowrap="nowrap" class="specResultPartCell">';
			theTable += 'Remark:&nbsp;<input type="text" name="item_remark" size="10" id="item_remark_' + result.PARTID[i] + '">';
			theTable += '</td><td nowrap="nowrap" class="specResultPartCell">';
			theTable += 'Instr.:&nbsp;<input type="text" name="item_instructions" size="10" id="item_instructions_' + result.PARTID[i] + '">';
			theTable += '</td><td nowrap="nowrap" class="specResultPartCell">';
			theTable += 'Subsample?:&nbsp;<input type="checkbox" name="subsample" id="subsample_' + result.PARTID[i] + '">';
			theTable += '</td><td nowrap="nowrap" class="specResultPartCell">';
			theTable += '<input type="button" id="theButton_' + result.PARTID[i] + '"';
			theTable += ' class="insBtn"';
			if (result.TRANSACTION_ID[i] > 0) {
				theTable += ' onclick="" value="In Loan">';
			} else {
				theTable += ' value="Add" onclick="addPartToLoan(';
				theTable += result.PARTID[i] + ');">';
			}
			if (result.ENCUMBRANCE_ACTION[i]!==null) {
				theTable += '<br><i>Encumbrances:&nbsp;' + result.ENCUMBRANCE_ACTION[i] + '</i>';
			}
			theTable +="</td>";
			if (result.COLLECTION_OBJECT_ID[i+1] && result.COLLECTION_OBJECT_ID[i+1] == result.COLLECTION_OBJECT_ID[i]) {
				theTable += "</tr>";
			} else {
				theTable += "</tr></table>";
				theCell.innerHTML = theTable;
			}
			lastID = result.COLLECTION_OBJECT_ID[i];
		}
	}
}
function makePartThingy() {
	var transaction_id = document.getElementById("transaction_id").value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getLoanPartResults",
			transaction_id : transaction_id,
			returnformat : "json",
			queryformat : 'column'
		},
		success_makePartThingy
	);
}

function cordFormat(str) {
	var rStr;
	if (str==null) {
		rStr='';
	} else {
		rStr = str;
		var rExp = /s/gi;
		rStr = rStr.replace(rExp,"\'\'");
		rExp = /d/gi;
		rStr = rStr.replace(rExp,'<sup>o</sup>');
		rExp = /m/gi;
		rStr = rStr.replace(rExp,"\'");
		rExp = / /gi;
		rStr = rStr.replace(rExp,'&nbsp;');
	}
	return rStr;
}
function success_makePartDeaccThingy(r){
	result=r.DATA;
	var lastID;
	var theTable;
	for (i=0; i<r.ROWCOUNT; ++i) {
		var cid = 'partCell_' + result.COLLECTION_OBJECT_ID[i];
		if (document.getElementById(cid)){
			var theCell = document.getElementById(cid);
			theCell.innerHTML='Fetching deaccession data....';
			if (lastID == result.COLLECTION_OBJECT_ID[i]) {
				theTable += "<tr>";
			} else {
				theTable = '<table border width="100%"><tr>';
			}
			theTable += '<td nowrap="nowrap" class="specResultPartCell">';
			theTable += '<i>' + result.PART_NAME[i];
			theTable += '(' + result.PRESERVE_METHOD[i] + ')';
			if (result.SAMPLED_FROM_OBJ_ID[i] > 0) {
				theTable += '&nbsp;sample';
			}
			theTable += "&nbsp;(" + result.COLL_OBJ_DISPOSITION[i] + ")</i> [" + result.BARCODE[i] + "]";
			theTable += '</td><td nowrap="nowrap" class="specResultPartCell">';
			theTable += 'Remark:&nbsp;<input type="text" name="item_remark" size="10" id="item_remark_' + result.PARTID[i] + '">';
			theTable += '</td><td nowrap="nowrap" class="specResultPartCell">';
			theTable += 'Instr.:&nbsp;<input type="text" name="item_instructions" size="10" id="item_instructions_' + result.PARTID[i] + '">';
			theTable += '</td><td nowrap="nowrap" class="specResultPartCell">';
			if (result.SAMPLED_FROM_OBJ_ID[i] > 0) {
			   theTable += 'Is a subsample<input type="hidden" name="subsample" id="subsample_' + result.PARTID[i] + '" value="0">';
			} else {
			   theTable += 'Subsample?:&nbsp;<input type="checkbox" name="subsample" id="subsample_' + result.PARTID[i] + '">';
			}
			theTable += '</td><td nowrap="nowrap" class="specResultPartCell">';
			theTable += '<input type="button" id="theButton_' + result.PARTID[i] + '"';
			theTable += ' class="insBtn"';
			if (result.TRANSACTION_ID[i] > 0) {
				theTable += ' onclick="" value="In Deaccession">';
			} else {
				theTable += ' value="Add" onclick="addPartToDeacc(';
				theTable += result.PARTID[i] + ');">';
			}
			if (result.ENCUMBRANCE_ACTION[i]!==null) {
				theTable += '<br><i>Encumbrances:&nbsp;' + result.ENCUMBRANCE_ACTION[i] + '</i>';
			}
			theTable +="</td>";
			if (result.COLLECTION_OBJECT_ID[i+1] && result.COLLECTION_OBJECT_ID[i+1] == result.COLLECTION_OBJECT_ID[i]) {
				theTable += "</tr>";
			} else {
				theTable += "</tr></table>";
				theCell.innerHTML = theTable;
			}
			lastID = result.COLLECTION_OBJECT_ID[i];
		}
	}
}
function makePartDeaccThingy() {
	var transaction_id = document.getElementById("transaction_id").value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getDeaccPartResults",
			transaction_id : transaction_id,
			returnformat : "json",
			queryformat : 'column'
		},
		success_makePartDeaccThingy
	);
}
function cordFormat(str) {
	var rStr;
	if (str==null) {
		rStr='';
	} else {
		rStr = str;
		var rExp = /s/gi;
		rStr = rStr.replace(rExp,"\'\'");
		rExp = /d/gi;
		rStr = rStr.replace(rExp,'<sup>o</sup>');
		rExp = /m/gi;
		rStr = rStr.replace(rExp,"\'");
		rExp = / /gi;
		rStr = rStr.replace(rExp,'&nbsp;');
	}
	return rStr;
}
function spaceStripper(str) {
	str=String(str);
	var rStr;
	if (str==null) {
		rStr='';
	} else {
		rStr = str.replace(/ /gi,'&nbsp;');
	}
	return rStr;
}
function splitByComma(str) {
	var rStr;
	if (str==null) {
		rStr='';
	} else {
		var rExp = /, /gi;
		rStr = str.replace(rExp,'<br>');
		rExp = / /gi;
		rStr = rStr.replace(rExp,'&nbsp;');
	}
	return rStr;
}
function splitByLF(str) {
	var rStr;
	if (str==null) {
		rStr='';
	} else {
		rStr = str.replace('\n','<br>','g');
	}
	return rStr;
}
function splitBySemicolon(str) {
	var rStr;
	if (str==null) {
		rStr='';
	} else {
		var rExp = /; /gi;
		rStr = str.replace(rExp,'<br>');
		rExp = / /gi;
		rStr = rStr.replace(rExp,'&nbsp;');
	}
	return rStr;
}
function goPickParts (collection_object_id,transaction_id) {
	var url='/picks/internalAddLoanItemTwo.cfm?collection_object_id=' + collection_object_id +"&transaction_id=" + transaction_id;
	mywin=windowOpener(url,'myWin','height=300,width=800,resizable,location,menubar ,scrollbars ,status ,titlebar,toolbar');
}
function goPickPartsDeacc (collection_object_id,transaction_id) {
	var url='/picks/internalAddDeaccItemTwo.cfm?collection_object_id=' + collection_object_id +"&transaction_id=" + transaction_id;
	mywin=windowOpener(url,'myWin','height=300,width=800,resizable,location,menubar ,scrollbars ,status ,titlebar,toolbar');
}
function removeItems() {
	var theList = document.getElementById('killRowList').value;
	var currentLocn = document.getElementById('mapURL').value;
	document.location='SpecimenResults.cfm?' + currentLocn + '&exclCollObjId=' + theList;
}
function toggleKillrow(id,status) {
	//alert(id + ' ' + status);

	var theEl = document.getElementById('killRowList');
	if (status==true) {
		var theArray = [];
		if (theEl.value.length > 0) {
			theArray = theEl.value.split(',');
		}
		theArray.push(id);
		var theString = theArray.join(",");
		theEl.value = theString;
	} else {
		var theArray = theEl.value.split(',');
		for (i=0; i<theArray.length; ++i) {
			//alert(theArray[i]);
			if (theArray[i] == id) {
				theArray.splice(i,1);
			}
		}
		var theString = theArray.toString();
		theEl.value=theString;
	}
	var theButton = document.getElementById('removeChecked');
	if (theString.length > -1) {
		theButton.style.display='block';
	} else {
		theButton.style.display='none';
	}
}

function getSpecResultsData (startrow,numrecs,orderBy,orderOrder) {
	if (document.getElementById('resultsGoHere')) {
		var guts = '<div id="loading" style="position:relative;top:0px;left:0px;z-index:999;color:white;background-color:green;';
	 	guts += 'font-size:large;font-weight:bold;padding:15px;">Fetching data...</div>';
	 	var tgt = document.getElementById('resultsGoHere');
		tgt.innerHTML = guts;
	}
	if (isNaN(startrow) && startrow.indexOf(',') > 0) {
   		var ar = startrow.split(',');
   		startrow = ar[0];
   		numrecs = ar[1];
   	}
	if (orderBy==null) {
		if (document.getElementById('orderBy1') && document.getElementById('orderBy1')) {
			var o1=document.getElementById('orderBy1').value;
			var o2=document.getElementById('orderBy2').value;
			var orderBy = o1 + ',' + o2;
		} else {
			var orderBy = 'cat_num';
		}
	}
	if (orderOrder==null) {
		var orderOrder = 'ASC';
	}
	if (orderBy.indexOf(',') > -1) {
		var oA=orderBy.split(',');
		if (oA[1]==oA[0]){
			orderBy=oA[0] + ' ' + orderOrder;
		} else {
			orderBy=oA[0] + ' ' + orderOrder + ',' + oA[1] + ' ' + orderOrder;
		}
	} else {
		orderBy += ' ' + orderOrder;
	}
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getSpecResultsData",
			startrow : startrow,
			numrecs : numrecs,
			orderBy : orderBy,
			returnformat : "json",
			queryformat : 'column'
		},
		success_getSpecResultsData
	);
}

function success_getSpecResultsData(result){
	var data = result.DATA;
	var attributes="Associated_MCZ_Collection,abnormality,age,age_class,associated_grant,associated_taxon,bare_parts_coloration,body_length,citation,colors,crown_rump_length,date_collected,date_emerged,diameter,disk_length,disk_width,ear_from_notch,extent,fat_deposition,forearm_length,fork_length,fossil_measurement,head_length,height,hind_foot_with_claw,host,incubation,length,life_cycle_stage,life_stage,max_display_angle,molt_condition,numeric_age,ossification,plumage_coloration,plumage_description,reference,reproductive_condition,reproductive_data,section_length,section_stain,sex,size_fish,snout_vent_length,specimen_length,stage_description,standard_length,stomach_contents,storage,tail_length,temperature_experiment,total_length,total_size,tragus_length,unformatted_measurements,unnamed_form,unspecified_measurement,verbatim_elevation,weight,width,wing_chord";
	var attAry=attributes.split(",");
	var nAtt=attAry.length;
	var collection_object_id = data.COLLECTION_OBJECT_ID[0];
	if (collection_object_id < 1) {
		var msg = data.message[0];
		alert(msg);
	} else {
		var clist = data.COLUMNLIST[0];
		var tgt = document.getElementById('resultsGoHere');
		if (document.getElementById('killrow') && document.getElementById('killrow').value==1){
			var killrow = 1;
		} else {
			var killrow = 0;
		}
		if (document.getElementById('action') && document.getElementById('action').value.length>0){
			var action = document.getElementById('action').value;
		} else {
			var action='';
		}
		if (document.getElementById('transaction_id') && document.getElementById('transaction_id').value.length>0){
			var transaction_id = document.getElementById('transaction_id').value;
		} else {
			var transaction_id='';
		}
		if (document.getElementById('loan_request_coll_id') && document.getElementById('loan_request_coll_id').value.length>0){
			var loan_request_coll_id = document.getElementById('loan_request_coll_id').value;
		} else {
			var loan_request_coll_id='';
		}
		if (document.getElementById('deacc_request_coll_id') && document.getElementById('deacc_request_coll_id').value.length>0){
			var deacc_request_coll_id = document.getElementById('deacc_request_coll_id').value;
		} else {
			var deacc_request_coll_id='';
		}
		if (document.getElementById('mapURL') && document.getElementById('mapURL').value.length>0){
			var mapURL = document.getElementById('mapURL').value;
		} else {
			var mapURL='';
		}
		var theInnerHtml = '<table class="specResultTab"><tr>';
			if (killrow == 1){
				theInnerHtml += '<th>Remove</th>';
			}
			theInnerHtml += '<th>Cat&nbsp;Num</th>';
			if (loan_request_coll_id.length > 0){
				theInnerHtml +='<th>Request</th>';
			}
			if (action == 'dispCollObj'){
				theInnerHtml +='<th>Loan</th>';
			}
				if (deacc_request_coll_id.length > 0){
				theInnerHtml +='<th>Request</th>';
			}
			if (action == 'dispCollObjDeacc'){
				theInnerHtml +='<th>Deaccession</th>';
			}
			if (data.COLUMNLIST[0].indexOf('CUSTOMID')> -1) {
				theInnerHtml += '<th>';
					theInnerHtml += data.MYCUSTOMIDTYPE[0];
				theInnerHtml += '</th>';
			}
			if (data.COLUMNLIST[0].indexOf('MEDIA')> -1) {
				theInnerHtml += '<th>Media</th>';
			}
			theInnerHtml += '<th>Identification</th>';
			if (data.COLUMNLIST[0].indexOf('STORED_AS')> -1) {
				theInnerHtml += '<th>STORED AS</th>';
			}
			if (data.COLUMNLIST[0].indexOf('ID_SENSU')> -1) {
				theInnerHtml += '<th>ID sensu</th>';
			}
			if (data.COLUMNLIST[0].indexOf('SCI_NAME_WITH_AUTH')> -1) {
				theInnerHtml += '<th>Scientific&nbsp;Name</th>';
			}
			if (data.COLUMNLIST[0].indexOf('CITED_AS')> -1) {
				theInnerHtml += '<th>Cited&nbsp;As</th>';
			}
			if (data.COLUMNLIST[0].indexOf('CITATIONS')> -1) {
				theInnerHtml += '<th>Citations</th>';
			}
			if (data.COLUMNLIST[0].indexOf('ID_HISTORY')> -1) {
				theInnerHtml += '<th>Identification&nbsp;History</th>';
			}
			if (data.COLUMNLIST[0].indexOf('IDENTIFIED_BY')> -1) {
				theInnerHtml += '<th>Identified&nbsp;By</th>';
			}
			if (data.COLUMNLIST[0].indexOf('PHYLCLASS')> -1) {
				theInnerHtml += '<th>Class</th>';
			}
			if (data.COLUMNLIST[0].indexOf('PHYLORDER')> -1) {
				theInnerHtml += '<th>Order</th>';
			}
			if (data.COLUMNLIST[0].indexOf('FAMILY')> -1) {
				theInnerHtml += '<th>Family</th>';
			}
			if (data.COLUMNLIST[0].indexOf('OTHERCATALOGNUMBERS')> -1) {
				theInnerHtml += '<th>Other&nbsp;Identifiers</th>';
			}
			if (data.COLUMNLIST[0].indexOf('ACCESSION')> -1) {
				theInnerHtml += '<th>Accession</th>';
			}
			if (data.COLUMNLIST[0].indexOf('COLLECTORS')> -1) {
				theInnerHtml += '<th>Collectors</th>';
			}
			if (data.COLUMNLIST[0].indexOf('PREPARATORS')> -1) {
				theInnerHtml += '<th>Preparators</th>';
			}
			if (data.COLUMNLIST[0].indexOf('VERBATIMLATITUDE')> -1) {
				theInnerHtml += '<th>Verbatim Latitude</th>';
			}
			if (data.COLUMNLIST[0].indexOf('VERBATIMLONGITUDE')> -1) {
				theInnerHtml += '<th>Verbatim Longitude</th>';
			}
			if (data.COLUMNLIST[0].indexOf('COORDINATEUNCERTAINTYINMETERS')> -1) {
				theInnerHtml += '<th>Max&nbsp;Error&nbsp;(m)</th>';
			}
			if (data.COLUMNLIST[0].indexOf('DATUM')> -1) {
				theInnerHtml += '<th>Datum</th>';
			}
			if (data.COLUMNLIST[0].indexOf('ORIG_LAT_LONG_UNITS')> -1) {
				theInnerHtml += '<th>Original&nbsp;Lat/Long&nbsp;Units</th>';
			}
			if (data.COLUMNLIST[0].indexOf('LAT_LONG_DETERMINER')> -1) {
				theInnerHtml += '<th>Georeferenced&nbsp;By</th>';
			}
			if (data.COLUMNLIST[0].indexOf('LAT_LONG_REF_SOURCE')> -1) {
				theInnerHtml += '<th>Lat/Long&nbsp;Reference</th>';
			}
			if (data.COLUMNLIST[0].indexOf('LAT_LONG_REMARKS')> -1) {
				theInnerHtml += '<th>Lat/Long&nbsp;Remarks</th>';
			}
			if (data.COLUMNLIST[0].indexOf('CONTINENT_OCEAN')> -1) {
				theInnerHtml += '<th>Continent</th>';
			}
			if (data.COLUMNLIST[0].indexOf('COUNTRY')> -1) {
				theInnerHtml += '<th>Country</th>';
			}
			if (data.COLUMNLIST[0].indexOf('STATE_PROV')> -1) {
				theInnerHtml += '<th>State</th>';
			}
			if (data.COLUMNLIST[0].indexOf('SEA')> -1) {
				theInnerHtml += '<th>Sea</th>';
			}
			if (data.COLUMNLIST[0].indexOf('QUAD')> -1) {
				theInnerHtml += '<th>Map&nbsp;Name</th>';
			}
			if (data.COLUMNLIST[0].indexOf('FEATURE')> -1) {
				theInnerHtml += '<th>Land Feature</th>';
			}
			if (data.COLUMNLIST[0].indexOf('WATER_FEATURE')> -1) {
				theInnerHtml += '<th>Water Feature</th>';
			}
			if (data.COLUMNLIST[0].indexOf('COUNTY')> -1) {
				theInnerHtml += '<th>County</th>';
			}
			if (data.COLUMNLIST[0].indexOf('ISLAND_GROUP')> -1) {
				theInnerHtml += '<th>Island&nbsp;Group</th>';
			}
			if (data.COLUMNLIST[0].indexOf('ISLAND')> -1) {
				theInnerHtml += '<th>Island</th>';
			}
			if (data.COLUMNLIST[0].indexOf('ASSOCIATED_SPECIES')> -1) {
				theInnerHtml += '<th>Associated&nbsp;Species</th>';
			}
			if (data.COLUMNLIST[0].indexOf('HABITAT')> -1) {
				theInnerHtml += '<th>Microhabitat</th>';
			}
			if (data.COLUMNLIST[0].indexOf('MIN_ELEV_IN_M')> -1) {
				theInnerHtml += '<th>Min&nbsp;Elevation&nbsp;(m)</th>';
			}
			if (data.COLUMNLIST[0].indexOf('MAX_ELEV_IN_M')> -1) {
				theInnerHtml += '<th>Max&nbsp;Elevation&nbsp;(m)</th>';
			}
			if (data.COLUMNLIST[0].indexOf('MINIMUM_ELEVATION')> -1) {
				theInnerHtml += '<th>Min&nbsp;Elevation</th>';
			}
			if (data.COLUMNLIST[0].indexOf('MAXIMUM_ELEVATION')> -1) {
				theInnerHtml += '<th>Max&nbsp;Elevation</th>';
			}
			if (data.COLUMNLIST[0].indexOf('ORIG_ELEV_UNITS')> -1) {
				theInnerHtml += '<th>Elevation&nbsp;Units</th>';
			}
			if (data.COLUMNLIST[0].indexOf('MIN_DEPTH_IN_M')> -1) {
				theInnerHtml += '<th>Min&nbsp;Depth&nbsp;(m)</th>';
			}
			if (data.COLUMNLIST[0].indexOf('MAX_DEPTH_IN_M')> -1) {
				theInnerHtml += '<th>Max&nbsp;Depth&nbsp;(m)</th>';
			}
			if (data.COLUMNLIST[0].indexOf('MIN_DEPTH')> -1) {
				theInnerHtml += '<th>Minimum&nbsp;Depth</th>';
			}
			if (data.COLUMNLIST[0].indexOf('MAX_DEPTH')> -1) {
				theInnerHtml += '<th>Maximum&nbsp;Depth</th>';
			}
			if (data.COLUMNLIST[0].indexOf('DEPTH_UNITS')> -1) {
				theInnerHtml += '<th>Depth&nbsp;Units</th>';
			}
			if (data.COLUMNLIST[0].indexOf('SPEC_LOCALITY')> -1) {
				theInnerHtml += '<th>Specific&nbsp;Locality</th>';
			}
			if (data.COLUMNLIST[0].indexOf('VERBATIMLOCALITY')> -1) {
				theInnerHtml += '<th>Verbatim&nbsp;Locality</th>';
			}
			if (data.COLUMNLIST[0].indexOf('GEOLOGY_ATTRIBUTES')> -1) {
				theInnerHtml += '<th>Geology&nbsp;Attributes</th>';
			}

			if (data.COLUMNLIST[0].indexOf('VERBATIM_DATE')> -1) {
				theInnerHtml += '<th>Verbatim&nbsp;Date</th>';
			}
			if (data.COLUMNLIST[0].indexOf('BEGAN_DATE')> -1) {
				theInnerHtml += '<th>Began&nbsp;Date</th>';
			}
			if (data.COLUMNLIST[0].indexOf('ENDED_DATE')> -1) {
				theInnerHtml += '<th>Ended&nbsp;Date</th>';
			}
            if (data.COLUMNLIST[0].indexOf('LAST_EDIT_DATE')> -1) {
				theInnerHtml += '<th>Last&nbsp;Edit&nbsp;Date</th>';
			}
			if (data.COLUMNLIST[0].indexOf('COLLECTING_TIME')> -1) {
				theInnerHtml += '<th>Collecting&nbsp;Time</th>';
			}
			if (data.COLUMNLIST[0].indexOf('COLLECTING_METHOD')> -1) {
				theInnerHtml += '<th>Collecting&nbsp;Method</th>';
			}
			if (data.COLUMNLIST[0].indexOf('YEARCOLL')> -1) {
				theInnerHtml += '<th>Year</th>';
			}
			if (data.COLUMNLIST[0].indexOf('MONCOLL')> -1) {
				theInnerHtml += '<th>Month</th>';
			}
			if (data.COLUMNLIST[0].indexOf('DAYCOLL')> -1) {
				theInnerHtml += '<th>Day</th>';
			}
			if (data.COLUMNLIST[0].indexOf('TOTAL_PARTS')> -1) {
				theInnerHtml += '<th>TOTAL PARTS</th>';
			}
			if (data.COLUMNLIST[0].indexOf('PARTS')> -1) {
				theInnerHtml += '<th>Parts</th>';
			}
			if (data.COLUMNLIST[0].indexOf('PARTDETAIL')> -1) {
				theInnerHtml += '<th>Part Detail</th>';
			}
			if (data.COLUMNLIST[0].indexOf('SEX')> -1) {
				theInnerHtml += '<th>Sex</th>';
			}
			if (data.COLUMNLIST[0].indexOf('REMARKS')> -1) {
				theInnerHtml += '<th>Specimen&nbsp;Remarks</th>';
			}
			for (a=0; a<nAtt; a++) {
				if (data.COLUMNLIST[0].indexOf(attAry[a].toUpperCase())> -1) {
					theInnerHtml += '<th>' + attAry[a] + '</th>';
				}
			}
			if (data.COLUMNLIST[0].indexOf('DEC_LAT')> -1) {
				theInnerHtml += '<th>Dec.&nbsp;Lat.</th>';
			}
			if (data.COLUMNLIST[0].indexOf('DEC_LONG')> -1) {
				theInnerHtml += '<th>Dec.&nbsp;Long.</th>';
			}
			if (data.COLUMNLIST[0].indexOf('GREF_COLLNUM') > -1) {
				theInnerHtml += '<th>Gref&nbsp;Link</th>';
			}
		theInnerHtml += '</tr>';
		// get an ordered list of collection_object_ids to pass on to
		// SpecimenDetail for browsing
		var orderedCollObjIdArray = new Array();
		for (i=0; i<result.ROWCOUNT; ++i) {
			orderedCollObjIdArray.push(data.COLLECTION_OBJECT_ID[i]);
		}
		var orderedCollObjIdList='';
		if (orderedCollObjIdArray.length < 200) {
			var orderedCollObjIdList = orderedCollObjIdArray.join(",");
		}
		for (i=0; i<result.ROWCOUNT; ++i) {
			orderedCollObjIdArray.push(data.COLLECTION_OBJECT_ID[i]);

                        var isType = false;
                        var isPSType = false;
                        var typestatus = "";
                        var rowClass = "";
			if (data.COLUMNLIST[0].indexOf('TYPESTATUS') > -1) {
			     if (data.TYPESTATUS[i]!=null && data.TYPESTATUS[i].length>0) {
			        isType = true;
			        typestatus = data.TYPESTATUS[i].replace("|","<BR>");
                             }
                        }
			if (data.COLUMNLIST[0].indexOf('TOPTYPESTATUSKIND') > -1) {
                             if (data.TOPTYPESTATUSKIND[i]!=null && data.TOPTYPESTATUSKIND[i].length>0) {
                                 typestatuskind = data.TOPTYPESTATUSKIND[i];
                                 if (typestatuskind.indexOf("Primary")>-1) {
                                     isPSType = true;
                                     rowClass = "typeRow";
                                 }
                                 if (typestatuskind.indexOf("Secondary")>-1) {
                                     isPSType = true;
                                     rowClass = "secTypeRow";
                                 }
                             }
			}
                        if (isPSType) {
				theInnerHtml += '<tr class="' + rowClass +  '">';
                        } else {
			    if (i%2) {
				theInnerHtml += '<tr class="oddRow">';
			    } else {
				theInnerHtml += '<tr class="evenRow">';
			    }
                        }


				if (killrow == 1){
					theInnerHtml += '<td align="center"><input type="checkbox" onchange="toggleKillrow(' + "'";
					theInnerHtml +=data.COLLECTION_OBJECT_ID[i] + "'" + ',this.checked);"></td>';
				}
				theInnerHtml += '<td nowrap="nowrap" id="CatItem_'+data.COLLECTION_OBJECT_ID[i]+'">';
					theInnerHtml += '<a target="_blank" href="/SpecimenDetail.cfm?collection_object_id=';
					theInnerHtml += data.COLLECTION_OBJECT_ID[i];
					theInnerHtml += '" onClick=" event.preventDefault(); $(&#39;#aLinkForm'+data.COLLECTION_OBJECT_ID[i]+'&#39;).submit();"  >';
					theInnerHtml += data.COLLECTION[i];
					theInnerHtml += '&nbsp;';
					theInnerHtml += data.CAT_NUM[i];
					theInnerHtml += '</a>';
					theInnerHtml += '<form action="/guid/MCZ:'+data.COLLECTION_CDE[i]+':'+data.CAT_NUM[i]+'" method="post" target="_blank" id="aLinkForm'+data.COLLECTION_OBJECT_ID[i]+'">';
					theInnerHtml += '<input type="hidden" name="old" value="true" />';
					theInnerHtml += '</form>';
				if (isType) {
					theInnerHtml += '<div class="showType">' + typestatus + '</div>';
				}
				theInnerHtml += '</td>';
				if (loan_request_coll_id.length > 0) {
					if (loan_request_coll_id == data.COLLECTION_ID[i]){
						theInnerHtml +='<td><span class="likeLink" onclick="addLoanItem(' + "'";
						theInnerHtml += data.COLLECTION_OBJECT_ID;
						theInnerHtml += "');" + '">Request</span></td>';
					} else {
						theInnerHtml +='<td>N/A</td>';
					}
				}
				if (action == 'dispCollObj' || action == 'dispCollObjDeacc'){
					theInnerHtml +='<td id="partCell_' + data.COLLECTION_OBJECT_ID[i] + '"></td>';
				}
				if (data.COLUMNLIST[0].indexOf('CUSTOMID')> -1) {
					theInnerHtml += '<td>' + data.CUSTOMID[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('MEDIA')> -1) {
					theInnerHtml += '<td>';
					theInnerHtml += '<div class="shortThumb"><div class="thumb_spcr">&nbsp;</div>';
						var thisMedia=JSON.parse(data.MEDIA[i]);
						for (m=0; m<thisMedia.ROWCOUNT; ++m) {
							if(thisMedia.DATA.preview_uri[m].length > 0) {
								pURI=thisMedia.DATA.preview_uri[m];
							} else {
								if (thisMedia.DATA.mimecat[m]=='audio'){
									pURI='images/audioNoThumb.png';
								} else {
									pURI='/images/noThumb.jpg';
								}
							}
							theInnerHtml += '<div class="one_thumb">';
							theInnerHtml += '<a href="' + thisMedia.DATA.media_uri[m] + '" target="_blank">';
							theInnerHtml += '<img src="' + pURI + '" class="theThumb"></a>';
							theInnerHtml += '<p>' + thisMedia.DATA.mimecat[m] + ' (' + thisMedia.DATA.mime_type[m] + ')';
							theInnerHtml += '<br><a target="_blank" href="/media/' + thisMedia.DATA.media_id[m] + '">Media Detail</a></p></div>';
						}
					theInnerHtml += '<div class="thumb_spcr">&nbsp;</div></div>';
					theInnerHtml += '</td>';
				}
				theInnerHtml += '<td>';
				theInnerHtml += '<span class="browseLink" type="scientific_name" dval="' + encodeURI(data.SCIENTIFIC_NAME[i]) + '">' + spaceStripper(data.SCIENTIFIC_NAME[i]);
				theInnerHtml += '</span>';
				theInnerHtml += '</td>';
				if (data.COLUMNLIST[0].indexOf('STORED_AS')> -1) {
					theInnerHtml += '<td>';
						theInnerHtml += data.STORED_AS[i];
					theInnerHtml += '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('ID_SENSU')> -1) {
					theInnerHtml += '<td>';
						theInnerHtml += data.ID_SENSU[i];
					theInnerHtml += '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('SCI_NAME_WITH_AUTH')> -1) {
					theInnerHtml += '<td>';
						theInnerHtml += spaceStripper(data.SCI_NAME_WITH_AUTH[i]);
					theInnerHtml += '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('CITED_AS')> -1) {
					theInnerHtml += '<td>';
						theInnerHtml += spaceStripper(data.CITED_AS[i]);
					theInnerHtml += '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('CITATIONS')> -1) {
					theInnerHtml += '<td>';
						theInnerHtml += spaceStripper(data.CITATIONS[i]);
					theInnerHtml += '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('ID_HISTORY')> -1) {
					theInnerHtml += '<td>';
						theInnerHtml += data.ID_HISTORY[i];
					theInnerHtml += '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('IDENTIFIED_BY')> -1) {
					theInnerHtml += '<td>' + splitBySemicolon(data.IDENTIFIED_BY[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('PHYLCLASS')> -1) {
					theInnerHtml += '<td>' + data.PHYLCLASS[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('PHYLORDER')> -1) {
					theInnerHtml += '<td>' + data.PHYLORDER[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('FAMILY')> -1) {
					theInnerHtml += '<td>' + data.FAMILY[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('OTHERCATALOGNUMBERS')> -1) {
					theInnerHtml += '<td>' + splitBySemicolon(data.OTHERCATALOGNUMBERS[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('ACCESSION')> -1) {
					theInnerHtml += '<td>' + spaceStripper(data.ACCESSION[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('COLLECTORS')> -1) {
					theInnerHtml += '<td>' + splitByComma(data.COLLECTORS[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('PREPARATORS')> -1) {
					theInnerHtml += '<td>' + splitByComma(data.PREPARATORS[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('VERBATIMLATITUDE')> -1) {
					theInnerHtml += '<td>' + cordFormat(data.VERBATIMLATITUDE[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('VERBATIMLONGITUDE')> -1) {
					theInnerHtml += '<td>' + cordFormat(data.VERBATIMLONGITUDE[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('COORDINATEUNCERTAINTYINMETERS')> -1) {
					theInnerHtml += '<td>' + data.COORDINATEUNCERTAINTYINMETERS[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('DATUM')> -1) {
					theInnerHtml += '<td>' + spaceStripper(data.DATUM[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('ORIG_LAT_LONG_UNITS')> -1) {
					theInnerHtml += '<td>' + data.ORIG_LAT_LONG_UNITS[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('LAT_LONG_DETERMINER')> -1) {
					theInnerHtml += '<td>' + splitBySemicolon(data.LAT_LONG_DETERMINER[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('LAT_LONG_REF_SOURCE')> -1) {
					theInnerHtml += '<td>' + data.LAT_LONG_REF_SOURCE[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('LAT_LONG_REMARKS')> -1) {
					theInnerHtml += '<td><div class="wrapLong">' + data.LAT_LONG_REMARKS[i] + '</div></td>';
				}
				if (data.COLUMNLIST[0].indexOf('CONTINENT_OCEAN')> -1) {
					theInnerHtml += '<td>' + spaceStripper(data.CONTINENT_OCEAN[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('COUNTRY')> -1) {
					theInnerHtml += '<td>' + spaceStripper(data.COUNTRY[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('STATE_PROV')> -1) {
					theInnerHtml += '<td>' + spaceStripper(data.STATE_PROV[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('SEA')> -1) {
					theInnerHtml += '<td>' + data.SEA[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('QUAD')> -1) {
					theInnerHtml += '<td>' + spaceStripper(data.QUAD[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('FEATURE')> -1) {
					theInnerHtml += '<td>' + spaceStripper(data.FEATURE[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('WATER_FEATURE')> -1) {
					theInnerHtml += '<td>' + spaceStripper(data.WATER_FEATURE[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('COUNTY')> -1) {
					theInnerHtml += '<td>' + data.COUNTY[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('ISLAND_GROUP')> -1) {
					theInnerHtml += '<td>' + spaceStripper(data.ISLAND_GROUP[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('ISLAND')> -1) {
					theInnerHtml += '<td>' + spaceStripper(data.ISLAND[i]) + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('ASSOCIATED_SPECIES')> -1) {
					theInnerHtml += '<td><div class="wrapLong">' + data.ASSOCIATED_SPECIES[i] + '</div></td>';
				}
				if (data.COLUMNLIST[0].indexOf('HABITAT')> -1) {
					theInnerHtml += '<td><div class="wrapLong">' + data.HABITAT[i] + '</div></td>';
				}
				if (data.COLUMNLIST[0].indexOf('MIN_ELEV_IN_M')> -1) {
					theInnerHtml += '<td>' + data.MIN_ELEV_IN_M[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('MAX_ELEV_IN_M')> -1) {
					theInnerHtml += '<td>' + data.MAX_ELEV_IN_M[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('MINIMUM_ELEVATION')> -1) {
					theInnerHtml += '<td>' + data.MINIMUM_ELEVATION[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('MAXIMUM_ELEVATION')> -1) {
					theInnerHtml += '<td>' + data.MAXIMUM_ELEVATION[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('ORIG_ELEV_UNITS')> -1) {
					theInnerHtml += '<td>' + data.ORIG_ELEV_UNITS[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('MIN_DEPTH_IN_M')> -1) {
					theInnerHtml += '<td>' + data.MIN_DEPTH_IN_M[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('MAX_DEPTH_IN_M')> -1) {
					theInnerHtml += '<td>' + data.MAX_DEPTH_IN_M[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('MIN_DEPTH')> -1) {
					theInnerHtml += '<td>' + data.MIN_DEPTH[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('MAX_DEPTH')> -1) {
					theInnerHtml += '<td>' + data.MAX_DEPTH[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('DEPTH_UNITS')> -1) {
					theInnerHtml += '<td>' + data.DEPTH_UNITS[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('SPEC_LOCALITY')> -1) {
					theInnerHtml += '<td id="SpecLocality_'+data.COLLECTION_OBJECT_ID[i] + '">';
					theInnerHtml += '<span class="browseLink" type="spec_locality" dval="' + encodeURI(data.SPEC_LOCALITY[i]) + '"><div class="wrapLong">' + data.SPEC_LOCALITY[i] + '</div>';
					theInnerHtml += '</span>';
					theInnerHtml += '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('VERBATIMLOCALITY')> -1) {
					theInnerHtml += '<td>' + data.VERBATIMLOCALITY[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('GEOLOGY_ATTRIBUTES')> -1) {
					theInnerHtml += '<td>' + data.GEOLOGY_ATTRIBUTES[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('VERBATIM_DATE')> -1) {
					theInnerHtml += '<td>' + data.VERBATIM_DATE[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('BEGAN_DATE')> -1) {
					theInnerHtml += '<td>' + data.BEGAN_DATE[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('ENDED_DATE')> -1) {
					theInnerHtml += '<td>' + data.ENDED_DATE[i] + '</td>';
				}
                if (data.COLUMNLIST[0].indexOf('LAST_EDIT_DATE')> -1) {
					theInnerHtml += '<td>' + data.LAST_EDIT_DATE[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('COLLECTING_TIME')> -1) {
					theInnerHtml += '<td>' + data.COLLECTING_TIME[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('COLLECTING_METHOD')> -1) {
					theInnerHtml += '<td>' + data.COLLECTING_METHOD[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('YEARCOLL')> -1) {
					theInnerHtml += '<td>' + data.YEARCOLL[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('MONCOLL')> -1) {
					theInnerHtml += '<td>' + data.MONCOLL[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('DAYCOLL')> -1) {
					theInnerHtml += '<td>' + data.DAYCOLL[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('TOTAL_PARTS')> -1) {
					theInnerHtml += '<td>' + data.TOTAL_PARTS[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('PARTS')> -1) {
					theInnerHtml += '<td><div class="wrapLong">' + splitBySemicolon(data.PARTS[i]) + '</div></td>';
				}
				if (data.COLUMNLIST[0].indexOf('PARTDETAIL')> -1) {
					theInnerHtml += '<td><div class="wrapLong">' + splitByLF(data.PARTDETAIL[i]) + '</div></td>';
				}
				if (data.COLUMNLIST[0].indexOf('SEX')> -1) {
					theInnerHtml += '<td>' + data.SEX[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('REMARKS')> -1) {
					theInnerHtml += '<td>' + data.REMARKS[i] + '</td>';
				}
				for (a=0; a<nAtt; a++) {
					if (data.COLUMNLIST[0].indexOf(attAry[a].toUpperCase())> -1) {
					var attStr='data.' + attAry[a].toUpperCase() + '[' + i + ']';
						theInnerHtml += '<td>' + eval(attStr) + '</td>';
					}
				}
				if (data.COLUMNLIST[0].indexOf('DEC_LAT')> -1) {
					theInnerHtml += '<td style="font-size:small">' + data.DEC_LAT[i] + '</td>';
				}
				if (data.COLUMNLIST[0].indexOf('DEC_LONG')> -1) {
					theInnerHtml += '<td style="font-size:small">' + data.DEC_LONG[i] + '</td>';
				}
			theInnerHtml += '</tr>';
		}
		theInnerHtml += '</table>';
	    theInnerHtml = theInnerHtml.replace(/<td>null<\/td>/g,"<td>&nbsp;</td>");
	    theInnerHtml = theInnerHtml.replace(/<div class="wrapLong">null<\/div>/g,"&nbsp;");
	    theInnerHtml = theInnerHtml.replace(/<td style="font-size:small">null<\/td>/g,"<td>&nbsp;</td>");


		tgt.innerHTML = theInnerHtml;
		if (action == 'dispCollObj'){
			makePartThingy();
		}
		if (action == 'dispCollObjDeacc'){
			makePartDeaccThingy();
		}
		insertMedia(orderedCollObjIdList);
		// insertTypes(orderedCollObjIdList);
	}
}
function ssvar (startrow,maxrows) {
	alert(startrow + ' ' + maxrows);
	var s_startrow = document.getElementById('s_startrow');
	var s_torow = document.getElementById('s_torow');
	s_startrow.innerHTML = startrow;
	s_torow.innerHTML = parseInt(startrow) + parseInt(maxrows) -1;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "ssvar",
			startrow : startrow,
			maxrows : maxrows,
			returnformat : "json",
			queryformat : 'column'
		},
	success_ssvar
	);
}
function jumpToPage (v) {
	var a = v.split(",");
	var p = a[0];
	var m=a[1];
	ssvar(p,m);
}
function closeCustom() {
	var theDiv = document.getElementById('customDiv');
	document.body.removeChild(theDiv);
	var murl='/SpecimenResults.cfm?' + document.getElementById('mapURL').value;
	window.location=murl;
}
function closeCustomNoRefresh() {
	var theDiv = document.getElementById('customDiv');
	document.body.removeChild(theDiv);
	var theDiv = document.getElementById('bgDiv');
	document.body.removeChild(theDiv);
}
function logIt(msg,status) {
	var mDiv=document.getElementById('msgs');
	var mhDiv=document.getElementById('msgs_hist');
	var mh=mDiv.innerHTML + '<hr>' + mhDiv.innerHTML;
	mhDiv.innerHTML=mh;
	mDiv.innerHTML=msg;
	if (status==0){
		mDiv.className='error';
	} else {
		mDiv.className='successDiv';
		document.getElementById('oidnum').focus();
		document.getElementById('oidnum').select();
	}
}
