jQuery(document).ready(function() {
	$("#made_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "../images/cal_icon.png",
			buttonImageOnly: true});
	$("#began_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "../images/cal_icon.png",
			buttonImageOnly: true });
	$("#ended_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "../images/cal_icon.png",
			buttonImageOnly: true});	
	$("#determined_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true});
	for (i=1;i<=14;i++){
		$("#geo_att_determined_date_" + i).datepicker({dateFormat: "yy-mm-dd"});
		$("#attribute_date_" + i).datepicker({dateFormat: "yy-mm-dd"});
	}
  $(".ui-datepicker-trigger").css("vertical-align","middle");
    $(".ui-datepicker-trigger").css("height","20px");
    $(".ui-datepicker-trigger").css("width","18px");

	$("input[type=text]").focus(function(){
	    //this.select();
	});
	$("select[id^='geology_attribute_']").each(function(e){
		var gid='geology_attribute_' + String(e+1);
		populateGeology(gid);			
	});
        if (window.addEventListener) {
                window.addEventListener("message", getGeolocate, false);
        } else {
                window.attachEvent("onmessage", getGeolocate);
        }
});


// Functions supporting georeferencing through geolocate.
function padzero(n) {
        return n < 10 ? '0' + n : n;
}
function pad2zeros(n) {
        if (n < 100) {
                n = '0' + n;
        }
        if (n < 10) {
                n = '0' + n;
        }
        return n;     
}
function toISOString(d) {
        return d.getUTCFullYear() + '-' +  padzero(d.getUTCMonth() + 1) + '-' + padzero(d.getUTCDate()) + 'T' + padzero(d.getUTCHours()) + ':' +  padzero(d.getUTCMinutes()) + ':' + padzero(d.getUTCSeconds()) + '.' + pad2zeros(d.getUTCMilliseconds()) + 'Z';
}

function DEuseGL(glat,glon,gerr){
        if ($("#orig_lat_long_units").val() != ''){
                var answer = confirm("Replace existing coordinates?")
                if (! answer){
                        closeGeoLocate('replace denied');
                        return;
                }
        }
        switchActive('decimal degrees');
        $("#orig_lat_long_units").val('decimal degrees');
        $("#max_error_distance").val(gerr);     
        $("#max_error_units").val('m'); 
        $("#extent").val('');   
        $("#gpsaccuracy").val('');      
        $("#datum").val('WGS84');  
        $("#determined_by_agent").val($("#enteredby").val());
        var now = new Date();
        var dt=toISOString(now);
        var dt2=dt.substring(0,10);
        $("#determined_date").val(dt2); 
        $("#lat_long_ref_source").val('GeoLocate');     
        $("#georefmethod").val('GEOLocate');    
        $("#verificationstatus").val('unverified');     
        $("#lat_long_remarks").val(''); 
        $("#dec_lat").val(glat);        
        $("#dec_long").val(glon);
        closeGeoLocate('inserted coordinates');
}
function geolocate () {
        $("#geoLocateResults").html('<img src="/images/indicator.gif">');
        if ($("#locality_id").val().length>0 || $("#collecting_event_id").val().length>0){
                alert('You cannot use geolocate with a picked locality.');
                closeGeoLocate('picked locality fail');
                return;
        }
        
        
        if ($("#higher_geog").val().length==0 || $("#spec_locality").val().length==0){
                alert('You cannot use geolocate without values in higher geography and spec locality.');
                closeGeoLocate('no geog fail');
                return;
        }
        $.getJSON("/component/Bulkloader.cfc",
                {
                        method : "splitGeog",
                        geog: $("#higher_geog").val(),
                        specloc: $("#spec_locality").val(),
                        returnformat : "json",
                        queryformat : 'column'
                },
                function(r) {
                        var bgDiv = document.createElement('div');
                        bgDiv.id = 'bgDiv';
                        bgDiv.className = 'bgDiv';
                        bgDiv.setAttribute('onclick','closeGeoLocate("clicked closed")');
                        document.body.appendChild(bgDiv);
                        var popDiv=document.createElement('div');
                        popDiv.id = 'popDiv';
                        popDiv.className = 'editAppBox';
                        document.body.appendChild(popDiv);      
                        var cDiv=document.createElement('div');
                        cDiv.className = 'fancybox-close';
                        cDiv.id='cDiv';
                        cDiv.setAttribute('onclick','closeGeoLocate("clicked closed")');
                        $("#popDiv").append(cDiv);
                        
                        var hDiv=document.createElement('div');
                        hDiv.className = 'fancybox-help';
                        hDiv.id='hDiv';
                        hDiv.innerHTML='<a href="https://arctosdb.wordpress.com/how-to/create/data-entry/geolocate/" target="blank">[ help ]</a>';
                        $("#popDiv").append(hDiv);
                        
                        $("#popDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
                        var theFrame = document.createElement('iFrame');
                        theFrame.id='theFrame';
                        theFrame.className = 'editFrame';
                        theFrame.src=r;
                        $("#popDiv").append(theFrame);
                }       
        );      
}
function getGeolocate(evt) {
    if (evt.origin.includes("://mczbase") && evt.data == "") { 
        console.log(evt); // Chrome appears to trigger an extra invocation of getGeolocate from mczbase with empty data.
    } else {  
        if (evt.origin !== "https://www.geo-locate.org") {
           console.log("getGeolocate()");
           console.log(evt);
           console.log("evt.origin: " + evt.origin);
           alert( "MCZbase error: iframe url does not have permision to interact with me" );
           closeGeoLocate('intruder alert');
        } else {
           var breakdown = evt.data.split("|");
           if (breakdown.length == 4) {
                    var glat=breakdown[0];
                    var glon=breakdown[1];
                    var gerr=breakdown[2];
                    DEuseGL(glat,glon,gerr)
           } else {
              alert( "MCZbase error: Unable to parse geolocate data. data length=" +  breakdown.length);
              closeGeoLocate('ERROR - breakdown length');
           }
       }
    }
}
function closeGeoLocate(msg) {
        $('#bgDiv').remove();
        $('#bgDiv', window.parent.document).remove();
        $('#popDiv').remove();
        $('#popDiv', window.parent.document).remove();
        $('#cDiv').remove();
        $('#cDiv', window.parent.document).remove();
        $('#theFrame').remove();
        $('#theFrame', window.parent.document).remove();
        $("#geoLocateResults").html(msg);
}

function loadRecord(collection_object_id){
        //console.log('loadRecord');

        // figure out if we're trying to enter or edit and call the appropriate function
        // this function is called when the page is initially loaded
        // it cannot be replaced with a direct call to lrEnter or edit
        if($("#action").val()=='enter') {
                loadRecordEnter(collection_object_id);
        } else if($("#action").val()=='edit') {
                loadRecordEdit(collection_object_id);
        }
}
function setNewRecDefaults () {
	var cc = $('#collection_cde').val();
	var ia =  $('#institution_acronym').val();
}
function incCatNum() {
	if ($("#cat_num").val()!=''){
		alert('There is already a cat number. Aborting....');
	} else {
		var inst = $("#institution_acronym").val();
		var coll = $("#collection_cde").val();		
		var coll_id = inst + " " + coll;
		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "getcatNumSeq",
				coll : coll_id,
				returnformat : "json",
				queryformat : 'column'
			},
			function(result){
				var catnum = document.getElementById('cat_num');
				catnum.value=result;
			}
		);
	}
}
function changeMode (mode) {
        console.log(mode);
	var status=$.trim($("#loadedMsgDiv").text());
        if (status=='null') { status = null; }  
	if(status){
		// got an error - force them to fix it
		mode='edit';
	} else { 
	   status=$.trim($("#loaded").val());
           if (status=='waiting approval') { status = null; }  
           if (status!=null) { 
	      $("#loadedMsgDiv").text(status);
           }
        }
        console.log(status);
        console.log(mode);
	$(".hasProbs").removeClass();
	if (mode == 'edit') {
		$("#customizeForm").hide(); //Save This As A New Record
		$("#theNewButton").hide(); //Save This As A New Record
		$("#theSaveButton").show(); // Save Edits/Delete Record
		$("#enterMode").hide(); // Edit Last Record
		if(status){
console.log('a');
			$('#modeDisplayDiv').text("FIX RECORD");
			// don't let them leave until this is fixed
			$("#browseThingy").hide();
			$("#editMode").hide(); // Clone This Record
			$("#theTable").removeClass().addClass('isBadEdit');
			$("#pageTitle").show();	
			highlightErrors(status);
		} else {
console.log('b');
			$('#modeDisplayDiv').text("EDIT EXISTING RECORD");
			$("#browseThingy").show();
			$("#editMode").show(); // Clone This Record
			$("#theTable").removeClass().addClass('isGoodEdit');
			$("#pageTitle").hide();	
		}
	} else { // entry mode
		$('#modeDisplayDiv').text("ENTER NEW RECORD");
		$("#customizeForm").show(); //Save This As A New Record
		$("#theTable").removeClass().addClass('isEnter');
		$("#theNewButton").show(); //Save This As A New Record
		$("#theSaveButton").hide(); // Save Edits/Delete Record
		$("#enterMode").show(); // Edit Last Record
		$("#editMode").hide(); // Clone This Record
		$("#browseThingy").hide();
		setPagePrefs();
	}
	$("#splash").hide();
	$("#theTable").show();	
}
function createClone() {
	yesChange = window.confirm('You will lose any unsaved changes. Continue?');
	if (yesChange == true) {
		changeMode('enter');
	}	
}
function setPagePrefs(){
	msg('setting customizations.....','bad');
	$.getJSON("/component/Bulkloader.cfc",
		{
			method : "getPrefs",
			returnformat : "json",
			queryformat : 'column'
		},
		function(r) {
			var columns=r.COLUMNS;
			for (i=0;i<columns.length;i++) {
				var cName=columns[i];
				var cVal=eval("r.DATA." + columns[i]);
				var eName=cName.toLowerCase();
				if (cVal==0){
					// clear and hide
					$("#" + eName).val('');
					$("#d_" + eName).hide();
				} else if (cVal==1) {
					// visible and clear
					$("#" + eName).val('');
					$("#d_" + eName).show();
				} else {
					// visible and leave value alone
					$("#d_" + eName).show();
				}
			}
			setNewRecDefaults();
			msg('page ready','good');
		}
	);
}
function closeCust() {
	$('#bgDiv').remove();
	$('#bgDiv', window.parent.document).remove();
	$('#popDiv').remove();
	$('#popDiv', window.parent.document).remove();
	$('#cDiv').remove();
	$('#cDiv', window.parent.document).remove();
	$('#theFrame').remove();
	$('#theFrame', window.parent.document).remove();
	setPagePrefs();
}
function customize(t) {
	var bgDiv = document.createElement('div');
	bgDiv.id = 'bgDiv';
	bgDiv.className = 'bgDiv';
	bgDiv.setAttribute('onclick','closeCust()');
	document.body.appendChild(bgDiv);
	var popDiv=document.createElement('div');
	popDiv.id = 'popDiv';
	popDiv.className = 'editAppBox';
	document.body.appendChild(popDiv);	
	var cDiv=document.createElement('div');
	cDiv.className = 'fancybox-close';
	cDiv.id='cDiv';
	cDiv.setAttribute('onclick','closeCust()');
	$("#popDiv").append(cDiv);
	$("#popDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
	var theFrame = document.createElement('iFrame');
	theFrame.id='theFrame';
	theFrame.className = 'editFrame';
	var ptl="/form/customizeDataEntry.cfm";
	theFrame.src=ptl;
	$("#popDiv").append(theFrame);
}
function msg(m,s){
	if (s=='bad' || s=='wait'){
                // add a styled bgDiv and animation for a wait state, if this stays up, it is bad.
		if ($("#bgDiv").length==0){
			var d='<div id="bgDiv" class="bgDiv"></div>';
			$('body').append(d);
			var im='<img id="loadingAnimation" src="/images/loadingAnimation.gif">';
			$('body').append(im);
		}
	} else {
                // e.g. s=='good'
		$("#bgDiv").remove();
		$("#loadingAnimation").remove();
	}
	$("#msg").removeClass().addClass(s).html(m);
}
function deleteThisRec () {
	// should only available from edit mode
	yesDelete = window.confirm('Are you sure you want to delete this record?');
	if (yesDelete == true) {
		msg('deleting record....','wait');
		collection_object_id=$("#collection_object_id").val();
		$.getJSON("/component/Bulkloader.cfc",
			{
				method : "deleteRecord",
				collection_object_id : collection_object_id,
				returnformat : "json"
			},
			function(r) {
				console.log(r);
				if(r){
					msg(r,'good');
				} else {
					console.log('r is not');
					return false;
				}
				console.log('deleted ' + collection_object_id);
				var nextID=$('#selectbrowse option:selected').next().val();
				if (! nextID){
					//console.log('going for previous');
					var nextID=$('#selectbrowse option:selected').prev().val();
					if (! nextID){
						alert('Deleted record successfully.  Navigating to previous record, but none was found. Select a new record in the dropdown, or close and re-open this form.');
						msg('no record found','good');
						return false;
					}
				}
				console.log('going to ' + nextID);
				$("#recCount").text(parseInt(parseInt($("#recCount").text())-1));
				$("#selectbrowse option[value=" + collection_object_id + "]").remove();
				$("#selectbrowse").val(nextID);
				loadRecordEdit(nextID);
			}
		);
	}
}


function saveNewRecord () { 
        console.log('saveNewRecord');
	// tries to save whatever's in the screen to the bulkloader
	// if success, just let them know it saved and move on to the next record
	// if fail, force edit
	// check that we've met all the restrictions imposed by collections, etc.
	if (cleanup()) {
		msg('saving....','wait');
		$(".hasProbs").removeClass();
		$.ajax({
			url: "/component/Bulkloader.cfc",
			type: "POST",
			dataType: "json",
	
			data: {
				method:  "saveNewRecord",
				q: $('#dataEntry').serialize(),
				returnformat : "json",
				queryFormat : "column"
			},
			success: function(r) {
				var pmode= 'enter';
				var coid=r.DATA.COLLECTION_OBJECT_ID[0];
				var status=r.DATA.RSLT[0];
				$("#collection_object_id").val(coid);
				if (status){
					msg(status,'err');
					$("#loadedMsgDiv").text(status).show();
					// dump the result into edit mode
					loadedEditRecord();
				} else {
					msg('inserted ' + coid,'good');
					var o='<option value="' + coid + '">' + coid + '</option>';
					$("#selectbrowse").append(o);
					$("#recCount").text(parseInt(parseInt($("#recCount").text())+1));
					if ($('#autoinc').is(':checked')){
						$.getJSON("/component/DataEntry.cfc",
							{
							method : "incrementCustomId",
							cidType: $("#other_id_num_type_5").val(),
							cidVal: $("#other_id_num_5").val(),
							returnformat : "json",
							queryformat : 'column'	
							},
							function(r) {
							if (r!='') {
								$("#other_id_num_5").val(r);
							}
						});
					
					}
					// switch to enter mode
					$("#action").val('editMode');
					changeMode('edit');
					// reapple any customizations, etc.
					setPagePrefs();
				}
		},
		error: function (xhr, textStatus, errorThrown){
		    // show error
		    alert(errorThrown + 'The saveNewRecord error');
		  }
		});
	}
}
function saveEditedRecord () {
	// save edited - this happens only from edit and 
	// returns only to edit
	if (cleanup()) {
		msg('saving....','wait');
		$.ajax({
		    url: "/component/Bulkloader.cfc",
		    dataType: "json",
		    type: "POST",
		    data: {
				method: "saveEdits",
				q : $("#dataEntry").serialize(),
				returnformat : "json",
				queryformat : 'column'
			},
			success: function( r ){
				var coid=r.DATA.COLLECTION_OBJECT_ID[0];
				var status=r.DATA.RSLT[0];
				console.log('saveEditedRecord back with msg ' + status);
				msg(status,'done');
				$("#loadedMsgDiv").text(status);
				loadedEditRecord();
			},
			error: function( result, strError ){
				alert('Error saving edits: ' + strError);
				msg('record failed to load','good');
				// turn on browse at least
				$("#browseThingy").show();
				return false;
			}
		});
	}
}

function loadedEditRecord(){
        console.log('loadedEditRecord()');
	// show errors and set the form up to deal with them if necessary
	// used by saveEditedRecord and loadRecordEdit
	// this function is NOT suitable for enter mode calls
	//console.log('loadedEditRecord');
	if ($("#collection_object_id").val()< "#MAXTEMPLATE"){
		// one of the templates
		//var loadedMsg='';
		alert('edit template - bad');
		return false;
	} 
	// make sure everything is on - override any user customizations	
	$("div[id^='d_']").show();
	var loadedMsg=$.trim($("#msg").text());
	//console.log('loadedMsg='+loadedMsg);	
	$(".hasProbs").removeClass();
	//console.log('loadedMsg='+loadedMsg);
	// make sure loaded isn't NULL for some reason
	// this form cannot be used to set records to load
	// just stop that and document if necessary
	if ($("#loaded").val().length==0){
		$("#loaded").val('waiting approval');
	}
        console.log(loadedMsg);
	if(loadedMsg && loadedMsg != 'waiting approval'){
		console.log('true loadedEditRecord+loadedMsg='+loadedMsg);
		//$("#loadedMsgDiv").show();
		var prob_array = loadedMsg.split(" ");
		for (var loop=0; loop < prob_array.length; loop++) {
			var thisSlice = prob_array[loop];
			////console.log('thisSlice='+thisSlice);
			var hasSpace = thisSlice.indexOf(" ");
			if (hasSpace == -1) {
				//console.log('trying....');
				try {
					console.log('adding class to ' + thisSlice.toLowerCase());
					$("#" + thisSlice.toLowerCase()).addClass('hasProbs');
				}
				catch ( err ){// nothing, just ignore 
				       console.log('caught: ' + err);
				}
			}
		}
		
		msg('record failed checks: ' + loadedMsg,'done');
	} else {
		console.log('false loadedEditRecord+loadedMsg='+loadedMsg);
		if ($("#selectbrowse").val()==$("#selectbrowse option:last").val()){
			$("#nBrowse").hide();
		} else {
			$("#nBrowse").show();
		}
		if ($("#selectbrowse").val()==$("#selectbrowse option:first").val()){
			$("#pBrowse").hide();
		} else {
			$("#pBrowse").show();
		}
		
		//Save This As A New Record
		$("#enterMode").show(); // Edit Last Record		
		//$("#loadedMsgDiv").hide();
		msg('record loaded - passed checks','good');
	}
        changeMode('edit');
	console.log('collection_object_id='+$("#collection_object_id").val());
	$("#selectbrowse").val($("#collection_object_id").val());
	// force attribute check
	checkRequiredParts();
	// set up edit URL
	var theURL='/DataEntry.cfm?action=edit';
	if ($("#ImAGod").val()=="yes"){
		theURL+='&ImAGod=yes';
	}
	theURL+='&collection_object_id=' + $("#collection_object_id").val();
}

function checkRequiredParts(){
   for (i=1;i<=12;i++){
       if ($("#part_name_" + i) && $("#part_name_" + i).val().length>0){
           $("#part_condition_" + i).addClass('reqdClr');
           $("#part_lot_count_" + i).addClass('reqdClr');
           $("#part_disposition_" + i).addClass('reqdClr');
       } else {
           $("#part_condition_" + i).removeClass('reqdClr');
           $("#part_lot_count_" + i).removeClass('reqdClr');
           $("#part_disposition_" + i).removeClass('reqdClr');
       }
   }
}

function loadRecordEdit (collection_object_id) {
   //load a record in EDIT mode
   msg('fetching data....','good');
   $.getJSON("/component/Bulkloader.cfc",
      {
         method : "loadRecord",
         collection_object_id : collection_object_id,
         returnformat : "json",
         queryformat : 'column'
      },
      function(r) {
         var columns=r.COLUMNS;
         for (i=0;i<columns.length;i++) {
            var cName=columns[i];
            var cVal=eval("r.DATA." + columns[i]);
            var eName=cName.toLowerCase();
            $("#" + eName).val(cVal);
         }
         $("#selectbrowse").val(r.DATA.COLLECTION_OBJECT_ID[0]);
         $("#pBrowse").show();
         $("#nBrowse").show();
         if ($("#selectbrowse").val()==$("#selectbrowse option:last").val()){
            $("#nBrowse").hide();
         }
         if ($("#selectbrowse").val()==$("#selectbrowse option:first").val()){
            $("#pBrowse").hide();
         }
         // turn some form stuff on/off as appropriate
         changeMode('edit');
         msg('record ' + r.DATA.COLLECTION_OBJECT_ID[0] + ' loaded','good');
      }
   );
}


//load a record (using an existing record as a template) in INSERT mode
function loadRecordEnter(collection_object_id){
   //load a record in EDIT mode
   msg('fetching data....','good');
   $.getJSON("/component/Bulkloader.cfc",
      {
         method : "loadRecord",
         collection_object_id : collection_object_id,
         returnformat : "json",
         queryformat : 'column'
      },
      function(r) {
         var columns=r.COLUMNS;
         for (i=0;i<columns.length;i++) {
            var cName=columns[i];
            var cVal=eval("r.DATA." + columns[i]);
            var eName=cName.toLowerCase();
            $("#" + eName).val(cVal);
         }
         $("#selectbrowse").val(r.DATA.COLLECTION_OBJECT_ID[0]);
         $("#pBrowse").show();
         $("#nBrowse").show();
         if ($("#selectbrowse").val()==$("#selectbrowse option:last").val()){
            $("#nBrowse").hide();
         }
         if ($("#selectbrowse").val()==$("#selectbrowse option:first").val()){
            $("#pBrowse").hide();
         }
         // default stuff for new records
         $("#enteredby").val($("#sessionusername").val());
         $("#other_id_num_type_5").val($("#sessioncustomotheridentifier").val());
         $("#loaded").val('waiting approval');
         // turn some form stuff on/off as appropriate
         changeMode('enter');
         msg('record ' + r.DATA.COLLECTION_OBJECT_ID[0] + ' loaded','good');
      }
   );
}

function editThis(){
	yesChange = window.confirm('You will lose any unsaved changes. Continue?');
	if (yesChange == true) {
		loadRecordEdit($("#collection_object_id").val());
		$("#selectbrowse").val($("#collection_object_id").val());
		changeMode('edit');
	}
}

function editLast() {
	//find the last record entered by the current user and load it for edit
	yesChange = window.confirm('You will lose any unsaved changes to this record. Continue?');
	if (yesChange == true) {
		$.getJSON("/component/Bulkloader.cfc",
			{
				method : "my_last_record",
				returnformat : "plain",
			},
			function(r) {
				loadRecordEdit(r);
				//$("#selectbrowse").val(r);
			}	
		);
	}
}

// Load the previous or next record in the current recordset in edit mode.
function browseTo(direction){
	var ix = $("#selectbrowse").attr( "selectedIndex" );	
	console.log('ix='+ix);
	if (direction=='next'){
		ix=parseInt(parseInt(ix)+1);
	} else {
		ix=parseInt(parseInt(ix)-1);
	}
	var c = $("#selectbrowse").find("option:eq(" + ix +")" ).val();
	loadRecordEdit(c);	
}

function copyBeganEnded() {
	$("#ended_date").val($("#began_date").val());
}

function isValidISODate(val) {
	jQuery.getJSON("/component/DataEntry.cfc",
		{
			method : "isValidISODate",
			datestring : val,
			returnformat : "json",
			queryformat : 'column'
		},
		function(result){
			return result;
		}
	);
}

function loadRecord (collection_object_id) {
        console.log('loadRecord ' + collection_object_id  + ' ' + $("#action").val());
        if($("#action").val()=='enter') {
                loadRecordEnter(collection_object_id);
        } else if($("#action").val()=='edit') {
                loadRecordEdit(collection_object_id);
      } else{
                loadRecordEdit(collection_object_id);
        }
}

function copyVerbatim(str){
	$.getJSON("/component/functions.cfc",
		{
			method : "strToIso8601",
			str : str,
			returnformat : "json",
			queryformat : 'column'
		},
		function(r) {
			if(r.DATA.B[0].length==0 || r.DATA.E[0].length==0){
				msg(r.DATA.I[0] + ' could not be converted to ISO8601.','err');
				//$("#dateConvertStatus").addClass('err').text(r.DATA.I[0] + ' could not be converted.');
			} else {
				//$("#dateConvertStatus").removeClass().text('');
				msg('ISO8601 convert success','good');
				$("#began_date").val(r.DATA.B[0]);
				$("#ended_date").val(r.DATA.E[0]);
			}
		}
	);
}
function populateGeology(id) {
	var idNum=id.replace('geology_attribute_','');
	var thisValue=$("#geology_attribute_" + idNum).val();;
	var dataValue=$("#geo_att_value_" + idNum).val();
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getGeologyValues",
			attribute : thisValue,
			returnformat : "json",
			queryformat : 'column'
		},
		function (r) {
			var s='<option value=""></option>';
			for (i=0; i<r.ROWCOUNT; ++i) {
				s+='<option value="' + r.DATA.ATTRIBUTE_VALUE[i] + '"';
				if (r.DATA.ATTRIBUTE_VALUE[i]==dataValue) {
					s+=' selected="selected"';
				}
				s+='>' + r.DATA.ATTRIBUTE_VALUE[i] + '</option>';
			}
			$("select#geo_att_value_" + idNum).html(s);				
		}
	);
}
var MONTH_NAMES=new Array('January','February','March','April','May','June','July','August','September','October','November','December','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
var DAY_NAMES=new Array('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sun','Mon','Tue','Wed','Thu','Fri','Sat');
function LZ(x) {return(x<0||x>9?"":"0")+x}
function changeCollection(v){
	var yesno = confirm("Are you sure you want to move this record to " + v + "? \nDoing so may cause attribute verification failure.")
	if (yesno){
		var ary=v.split(':');
		document.getElementById('institution_acronym').value=ary[0];
		document.getElementById('collection_cde').value=ary[1];
	} else {
		var i=document.getElementById('institution_acronym').value;
		var c=document.getElementById('collection_cde').value;
		var s=document.getElementById('colln');
		s.value=i + ':' + c;
	}
}
/* recheck */
function requirePartAtts(i,v){
	var pn=document.getElementById('part_name_' + i);
	var pc=document.getElementById('part_condition_' + i);
	var pl=document.getElementById('part_lot_count_' + i);
	var pd=document.getElementById('part_disposition_' + i);
	if (v.length > 0) {
		pn.className='reqdClr';
		pc.className='reqdClr';
		pl.className='reqdClr';
		pd.className='reqdClr';
	} else {
		pn.className='';
		pc.className='';
		pl.className='';
		pd.className='';
	}
}
function _isInteger(val){var digits="1234567890";for(var i=0;i < val.length;i++){if(digits.indexOf(val.charAt(i))==-1){return false;}}return true;}

function _getInt(str,i,minlength,maxlength) {
	for (var x=maxlength; x>=minlength; x--) {
		var token=str.substring(i,i+x);
		if (token.length < minlength) { return null; }
		if (_isInteger(token)) { return token; }
	}
	return null;
}
function getDateFromFormat(val,format) {
	val=val+"";
	format=format+"";
	var i_val=0;
	var i_format=0;
	var c="";
	var token="";
	var token2="";
	var x,y;
	var now=new Date();
	var year=now.getYear();
	var month=now.getMonth()+1;
	var date=1;
	var hh=now.getHours();
	var mm=now.getMinutes();
	var ss=now.getSeconds();
	var ampm="";
	while (i_format < format.length) {
		c=format.charAt(i_format);
		token="";
		while ((format.charAt(i_format)==c) && (i_format < format.length)) {
			token += format.charAt(i_format++);
		}
		if (token=="yyyy" || token=="yy" || token=="y") {
			if (token=="yyyy") { x=4;y=4; }
			if (token=="yy")   { x=2;y=2; }
			if (token=="y")    { x=2;y=4; }
			year=_getInt(val,i_val,x,y);
			if (year==null) { return 0; }
			i_val += year.length;
			if (year.length==2) {
				if (year > 70) { year=1900+(year-0); }
				else { year=2000+(year-0); }
			}
		}
		else if (token=="MMM"||token=="NNN"){
			month=0;
			for (var i=0; i<MONTH_NAMES.length; i++) {
				var month_name=MONTH_NAMES[i];
				if (val.substring(i_val,i_val+month_name.length).toLowerCase()==month_name.toLowerCase()) {
					if (token=="MMM"||(token=="NNN"&&i>11)) {
						month=i+1;
						if (month>12) { month -= 12; }
						i_val += month_name.length;
						break;
					}
				}
			}
			if ((month < 1)||(month>12)){return 0;}
		}
		else if (token=="EE"||token=="E"){
			for (var i=0; i<DAY_NAMES.length; i++) {
				var day_name=DAY_NAMES[i];
				if (val.substring(i_val,i_val+day_name.length).toLowerCase()==day_name.toLowerCase()) {
					i_val += day_name.length;
					break;
				}
			}
		}
		else if (token=="MM"||token=="M") {
			month=_getInt(val,i_val,token.length,2);
			if(month==null||(month<1)||(month>12)){return 0;}
			i_val+=month.length;}
		else if (token=="dd"||token=="d") {
			date=_getInt(val,i_val,token.length,2);
			if(date==null||(date<1)||(date>31)){return 0;}
			i_val+=date.length;}
		else if (token=="hh"||token=="h") {
			hh=_getInt(val,i_val,token.length,2);
			if(hh==null||(hh<1)||(hh>12)){return 0;}
			i_val+=hh.length;}
		else if (token=="HH"||token=="H") {
			hh=_getInt(val,i_val,token.length,2);
			if(hh==null||(hh<0)||(hh>23)){return 0;}
			i_val+=hh.length;}
		else if (token=="KK"||token=="K") {
			hh=_getInt(val,i_val,token.length,2);
			if(hh==null||(hh<0)||(hh>11)){return 0;}
			i_val+=hh.length;}
		else if (token=="kk"||token=="k") {
			hh=_getInt(val,i_val,token.length,2);
			if(hh==null||(hh<1)||(hh>24)){return 0;}
			i_val+=hh.length;hh--;}
		else if (token=="mm"||token=="m") {
			mm=_getInt(val,i_val,token.length,2);
			if(mm==null||(mm<0)||(mm>59)){return 0;}
			i_val+=mm.length;}
		else if (token=="ss"||token=="s") {
			ss=_getInt(val,i_val,token.length,2);
			if(ss==null||(ss<0)||(ss>59)){return 0;}
			i_val+=ss.length;}
		else if (token=="a") {
			if (val.substring(i_val,i_val+2).toLowerCase()=="am") {ampm="AM";}
			else if (val.substring(i_val,i_val+2).toLowerCase()=="pm") {ampm="PM";}
			else {return 0;}
			i_val+=2;}
		else {
			if (val.substring(i_val,i_val+token.length)!=token) {return 0;}
			else {i_val+=token.length;}
			}
		}
	// If there are any trailing characters left in the value, it doesn't match
	if (i_val != val.length) { return 0; }
	// Is date valid for month?
	if (month==2) {
		// Check for leap year
		if ( ( (year%4==0)&&(year%100 != 0) ) || (year%400==0) ) { // leap year
			if (date > 29){ return 0; }
			}
		else { if (date > 28) { return 0; } }
		}
	if ((month==4)||(month==6)||(month==9)||(month==11)) {
		if (date > 30) { return 0; }
		}
	// Correct hours value
	if (hh<12 && ampm=="PM") { hh=hh-0+12; }
	else if (hh>11 && ampm=="AM") { hh-=12; }
	var newdate=new Date(year,month-1,date,hh,mm,ss);
	return newdate.getTime();
}	
function isValidDate(val) {
	var preferEuro=(arguments.length==2)?arguments[1]:false;
	generalFormats=new Array('y-M-d','MMM d, y','MMM d,y','y-MMM-d','d-MMM-y','d M y','d MMM y','d-M-Y','d-MMM-y');
	monthFirst=new Array('M/d/y','M-d-y','M.d.y','MMM-d','M/d','M-d');
	dateFirst =new Array('d/M/y','d-M-y','d.M.y');
	var checkList=new Array('generalFormats','dateFirst');
	var d=null;
	for (var i=0; i<checkList.length; i++) {
		var l=window[checkList[i]];
		for (var j=0; j<l.length; j++) {
			d=getDateFromFormat(val,l[j]);
			if (d!=0) { 
				return true;
			} 	
		}
	return false;
	}
}


function clearAll () {
	var theForm = document.getElementById('dataEntry');
	for(i=0; i<theForm.elements.length; i++) {
		if (theForm.elements[i].type == "text") {
			theForm.elements[i].value = '';
		}
	}	
}

function switchActive(OrigUnits) {
	var OrigUnits;
	var a=document.getElementById('dms');
	var b=document.getElementById('ddm');
	var c=document.getElementById('dd');
	var u=document.getElementById('utm');
	var d=document.getElementById('lat_long_meta');
	var gg=document.getElementById('orig_lat_long_units');
 	a.className='noShow';
	b.className='noShow';
	c.className='noShow';
	u.className='noShow';
	d.className='noShow';
	var isSomething = OrigUnits.length;
	if (isSomething > 0) {
		d.className='doShow';
		gg.className='reqdClr';
	}	else {
		gg.className='';
		gg.value='';
	}
	if (OrigUnits == 'deg. min. sec.') {
		a.className='doShow';
	} else if (OrigUnits == 'decimal degrees') {
		c.className='doShow';
	} else if (OrigUnits == 'degrees dec. minutes') {
		b.className='doShow';
	} else if (OrigUnits == 'UTM') {
		u.className='doShow';
	}
}



function setPartLabel (thisID) {
	var thePartNum = thisID.replace('part_container_unique_id_','');
	var theOIDType = document.getElementById('other_id_num_type_5').value;
	if (theOIDType == 'AF') {
		var theLabelStr = 'part_container_name_' + thePartNum;
		var theLabel = document.getElementById(theLabelStr);
		var theLabelVal = theLabel.value;
		var isLbl = theLabelVal.length;
		if ( isLbl == 0) {
			var theAf = document.getElementById('other_id_num_5').value;
			var isAf = theAf.length;
			if (isAf > 0) {
				theLabel.value = 'AF' + theAf;
			}
		}
	}
}
function doAttributeDefaults () {
	var theDef = document.getElementById('attribute_determiner_1').value;	
	var isDef = theDef.length;
	if (isDef > 0) {
		var atts = new Array();
		atts.push('attribute_determiner_2');
		atts.push('attribute_determiner_3');
		atts.push('attribute_determiner_4');
		atts.push('attribute_determiner_5');
		atts.push('attribute_determiner_6');
		atts.push('attribute_determiner_7');
		atts.push('attribute_determiner_8');
		atts.push('attribute_determiner_9');
		atts.push('attribute_determiner_10');		
		for (i=0;i<atts.length;i++) {
			try {
				var thisFld = document.getElementById(atts[i]);
				var isThere = thisFld.length;
				if (isThere == 0) {
					thisFld.value=theDef;
					alert('doing something');
				}
			}
			catch ( err ){// nothing, just ignore 
			}
		}
	}
}
function click_changeMode (mode,collobjid) {
	yesChange = window.confirm('You will lose any unsaved changes. Continue?');
	if (yesChange == true) {
		if (mode == 'edit') {
				document.location='DataEntry.cfm?collection_object_id=' + collobjid + '&pMode=edit&action=editEnterData';
		} else {
			changeMode(mode,collobjid);
			
		}
	}	
}

function UAMArtDefaults() {
	var i=1;
	for (i=1;i<=12;i++){
		var thisPartConditionString='part_condition_' + i;
		if (document.getElementById(thisPartConditionString)) {
			var thisPartCondition=document.getElementById(thisPartConditionString);
			var thisPartConditionValue=thisPartCondition.value;
			if (thisPartConditionValue==''){
				thisPartCondition.value='unchecked';
			}
		}
	}
}
	
function copyAllDates(theID) {
	var theDate = document.getElementById(theID).value;
	if (theDate.length > 0) {
		var date_array = new Array();
		date_array.push('ended_date');
		date_array.push('began_date');
		date_array.push('determined_date');
		date_array.push('made_date');
		date_array.push('attribute_date_1');
		date_array.push('attribute_date_2');
		date_array.push('attribute_date_3');
		date_array.push('attribute_date_4');
		date_array.push('attribute_date_5');
		date_array.push('attribute_date_6');
		date_array.push('attribute_date_7');
		date_array.push('attribute_date_8');
		date_array.push('attribute_date_9');
		date_array.push('attribute_date_10');
		for (i=0;i<date_array.length;i++) {
			try {
				var thisFld = document.getElementById(date_array[i]);
				var theValue = thisFld.value;
				thisFld.value=theDate;
			}
			catch ( err ){// nothing, just ignore 
			}
		
		}	
	}
}
function copyAttributeDates(theID) {
	var theDate = document.getElementById(theID).value;
	if (theDate.length > 0) {
		var date_array = new Array();
		date_array.push('attribute_date_1');
		date_array.push('attribute_date_2');
		date_array.push('attribute_date_3');
		date_array.push('attribute_date_4');
		date_array.push('attribute_date_5');
		date_array.push('attribute_date_6');
		date_array.push('attribute_date_7');
		date_array.push('attribute_date_8');
		date_array.push('attribute_date_9');
		date_array.push('attribute_date_10');
		for (i=0;i<date_array.length;i++) {
			try {
				var thisFld = document.getElementById(date_array[i]);
				var theValue = thisFld.value;
				thisFld.value=theDate;
			}
			catch ( err ){// nothing, just ignore 
			}
		
		}	
	}
}
function copyAttributeDetr(theID) {
	var theAgent = document.getElementById(theID).value;
	if (theAgent.length > 0) {
		var agnt_array = new Array();
		agnt_array.push('attribute_determiner_1');
		agnt_array.push('attribute_determiner_2');
		agnt_array.push('attribute_determiner_3');
		agnt_array.push('attribute_determiner_4');
		agnt_array.push('attribute_determiner_5');
		agnt_array.push('attribute_determiner_6');
		agnt_array.push('attribute_determiner_7');
		agnt_array.push('attribute_determiner_8');
		agnt_array.push('attribute_determiner_9');
		agnt_array.push('attribute_determiner_10');
		for (i=0;i<agnt_array.length;i++) {
			try {
				var thisFld = document.getElementById(agnt_array[i]);
				var theValue = thisFld.value;
				thisFld.value=theAgent;
			}
			catch ( err ){// nothing, just ignore 
			}
		
		}	
	}
}
function copyAllAgents(theID) {
	var theAgent = document.getElementById(theID).value;
	if (theAgent.length > 0) {
		var agnt_array = new Array();
		agnt_array.push('determined_by_agent');
		agnt_array.push('id_made_by_agent');
		agnt_array.push('attribute_determiner_1');
		agnt_array.push('attribute_determiner_2');
		agnt_array.push('attribute_determiner_3');
		agnt_array.push('attribute_determiner_4');
		agnt_array.push('attribute_determiner_5');
		agnt_array.push('attribute_determiner_6');
		agnt_array.push('attribute_determiner_7');
		agnt_array.push('attribute_determiner_8');
		agnt_array.push('attribute_determiner_9');
		agnt_array.push('attribute_determiner_10');
		for (i=0;i<agnt_array.length;i++) {
			try {
				var thisFld = document.getElementById(agnt_array[i]);
				var theValue = thisFld.value;
				thisFld.value=theAgent;
			}
			catch ( err ){// nothing, just ignore 
			}
		
		}	
	}
}
function highlightErrors (loadedMsg) {
	if(loadedMsg){
		$("#loadedMsgDiv").show();
		var prob_array = loadedMsg.split(" ");
		for (var loop=0; loop < prob_array.length; loop++) {
			var thisSlice = prob_array[loop];
			var hasSpace = thisSlice.indexOf(" ");
			if (hasSpace == -1) {
				try {
					var theField = document.getElementById(thisSlice.toLowerCase());
					theField.className = 'hasProbs';
				}
				catch ( err ){// nothing, just ignore 
				}
			}
		}
	} else {
		$("#loadedMsgDiv").hide();
	}
}

function cleanup () {
	var thisCC = document.getElementById('collection_cde').value;
	if (thisCC == 'Mamm') {	
		/******************************** Mammal Routine ************************************************/
		try {
			var Att2UnitVal = document.getElementById('attribute_units_2').value; //total length & "standard"
			var Att3UnitVal = document.getElementById('attribute_units_3'); //tail length
			var Att4UnitVal = document.getElementById('attribute_units_4'); //HF length
			var Att5UnitVal = document.getElementById('attribute_units_5'); //EFN length
			Att3UnitVal.value = Att2UnitVal;
			Att4UnitVal.value = Att2UnitVal;
			Att5UnitVal.value = Att2UnitVal;
			var Det2UnitVal = document.getElementById('attribute_determiner_2').value; //total length
			var Det3UnitVal = document.getElementById('attribute_determiner_3'); //tail length
			var Det4UnitVal = document.getElementById('attribute_determiner_4'); //HF length
			var Det5UnitVal = document.getElementById('attribute_determiner_5'); //EFN length
			var Det6UnitVal = document.getElementById('attribute_determiner_6'); //weight
			Det3UnitVal.value = Det2UnitVal;
			Det4UnitVal.value = Det2UnitVal;
			Det5UnitVal.value = Det2UnitVal;
			Det6UnitVal.value = Det2UnitVal;
			var Date2UnitVal = document.getElementById('attribute_date_2').value; //total length
			var Date3UnitVal = document.getElementById('attribute_date_3'); //tail length
			var Date4UnitVal = document.getElementById('attribute_date_4'); //HF length
			var Date5UnitVal = document.getElementById('attribute_date_5'); //EFN length
			var Date6UnitVal = document.getElementById('attribute_date_6'); //weight
			Date3UnitVal.value = Date2UnitVal;
			Date4UnitVal.value = Date2UnitVal;
			Date5UnitVal.value = Date2UnitVal;
			Date6UnitVal.value = Date2UnitVal;
		} catch(e){
			// whatever
		}
	} else if (thisCC == 'Orn') {
		/************************************************** Bird Routine **************************************************/
		try {
			var Det2UnitVal = document.getElementById('attribute_determiner_2').value; //age & standard
			var Det3UnitVal = document.getElementById('attribute_determiner_3'); //fat
			var Det4UnitVal = document.getElementById('attribute_determiner_4'); //molt
			var Det5UnitVal = document.getElementById('attribute_determiner_5'); //skull
			var Det6UnitVal = document.getElementById('attribute_determiner_6'); //weight
			Det3UnitVal.value = Det2UnitVal;
			Det4UnitVal.value = Det2UnitVal;
			Det5UnitVal.value = Det2UnitVal;
			Det6UnitVal.value = Det2UnitVal;
			var Date2UnitVal = document.getElementById('attribute_date_2').value; //age & standard
			var Date3UnitVal = document.getElementById('attribute_date_3'); //fat
			var Date4UnitVal = document.getElementById('attribute_date_4'); //molt
			var Date5UnitVal = document.getElementById('attribute_date_5'); //skull
			var Date6UnitVal = document.getElementById('attribute_date_6'); //weight
			Date3UnitVal.value = Date2UnitVal;
			Date4UnitVal.value = Date2UnitVal;
			Date5UnitVal.value = Date2UnitVal;
			Date6UnitVal.value = Date2UnitVal;
			var oid1 = document.getElementById('other_id_num_type_1');
			var oid2 = document.getElementById('other_id_num_type_2');
			var theMsg = "";
			/*
			if (oid1.value == 'collector number') {
				var oidv1 = document.getElementById('other_id_num_1').value;
				if (oidv1.length == 0) {
					theMsg = "You did not enter a collector number";
				}			
			}
			if (oid2.value == 'preparator number') {
				var oidv2 = document.getElementById('other_id_num_2').value;
				if (oidv2.length == 0) {
					theMsg += "\nYou did not enter a preparator number";
				}			
			}
			*/
			if (theMsg.length > 0) {
				theMsg +="\nContinue?";
				whatever = window.confirm(theMsg);
				if (whatever == false) {
					return false;
				} else {
					return true;
				}
			}
		} catch(e){
			// whatever
		}
	}// end collection specific thingy
	/******************************************************************** Any Collection ***************************************/
	// make an array of required values and loop through the array checking them
	// this must always happen at the bottom of function cleanup - some of these things
	// may be populated by this function
	var reqdFlds = new Array();
	var missingData = "";
	// these fields are always required
	reqdFlds.push('accn');
	reqdFlds.push('collector_agent_1');
	reqdFlds.push('higher_geog');
	reqdFlds.push('spec_locality');
	reqdFlds.push('verbatim_locality');
	reqdFlds.push('verbatim_date');
	reqdFlds.push('began_date');
	reqdFlds.push('ended_date');
	reqdFlds.push('taxon_name');
	reqdFlds.push('id_made_by_agent');
	reqdFlds.push('nature_of_id');
	var thisIA = document.getElementById('institution_acronym').value;

	if (!(thisIA=='MCZ' && thisCC=='Ent') && !(thisIA=='MCZ' && thisCC=='Cryo') && !(thisIA=='MCZ' && thisCC=='SC') && !(thisIA=='MCZ' && thisCC=='Herp') && !(thisIA=='MCZ' && thisCC=='HerpOBS') && !(thisIA=='MCZ' && thisCC=='Orn') && !(thisIA=='MCZ' && thisCC=='IZ') && !(thisIA=='MCZ' && thisCC=='Mala') && !(thisIA=='MCZ' && thisCC=='IP') && !(thisIA=='MCZ' && thisCC=='VP') && !(thisIA=='UAM' && thisCC=='Herp') && thisCC != 'Crus' && thisCC != 'Herb' && thisCC != 'ES' && thisCC != 'Ich' && thisCC != 'Para' && thisCC != 'Art') {
		reqdFlds.push('attribute_value_1');
		reqdFlds.push('attribute_determiner_1');
	}
	reqdFlds.push('part_condition_1');
	var llUnit=document.getElementById('orig_lat_long_units').value;
	if (llUnit.length > 0) {
		reqdFlds.push('datum');
		reqdFlds.push('determined_by_agent');
		reqdFlds.push('determined_date');
		reqdFlds.push('lat_long_ref_source');
		reqdFlds.push('georefmethod');
		reqdFlds.push('verificationstatus');
		if (llUnit == 'deg. min. sec.') {
			reqdFlds.push('latdeg');
			reqdFlds.push('latmin');
			reqdFlds.push('latsec');
			reqdFlds.push('latdir');
			reqdFlds.push('longdeg');
			reqdFlds.push('longmin');
			reqdFlds.push('longsec');
			reqdFlds.push('longdir');
		}
		if (llUnit == 'decimal degrees') {
			reqdFlds.push('dec_lat');
			reqdFlds.push('dec_long');
		}
		if (llUnit == 'degrees dec. minutes') {
			reqdFlds.push('decLAT_DEG');
			reqdFlds.push('dec_lat_min');
			reqdFlds.push('decLAT_DIR');
			reqdFlds.push('decLONGDEG');
			reqdFlds.push('DEC_LONG_MIN');
			reqdFlds.push('decLONGDIR');
		}
		if (llUnit == 'UTM') {
			reqdFlds.push('utm_zone');
			reqdFlds.push('utm_ns');
			reqdFlds.push('utm_ew');
		}
	}
	for (i=0;i<reqdFlds.length;i++) {
		try {
			var thisFld = document.getElementById(reqdFlds[i]).value;
			if (thisFld.length == 0) {
				var thisFldName = document.getElementById(reqdFlds[i]).name;
				missingData = missingData + "\n" + thisFldName;					}
			}
		catch ( err ){// nothing, just ignore 
		}
	}
	if (missingData.length > 0) {
		alert('You must enter data in required fields: ' + missingData + "\n Aborting Save!");
		return false;
	}
	var dateFields = new Array();
	var badDates = "";
	//dateFields.push('made_date');
	//dateFields.push('began_date');
	//dateFields.push('ended_date');
	dateFields.push('determined_date');
	dateFields.push('attribute_date_1');
	dateFields.push('attribute_date_2');
	dateFields.push('attribute_date_3');
	dateFields.push('attribute_date_4');
	dateFields.push('attribute_date_5');
	dateFields.push('attribute_date_6');
	dateFields.push('attribute_date_7');
	dateFields.push('attribute_date_8');
	dateFields.push('attribute_date_9');
	dateFields.push('attribute_date_10');
	for (i=0;i<dateFields.length;i++) {
		var thisFld = document.getElementById(dateFields[i]).value;
		if (thisFld.length > 0 && isValidDate(thisFld) == false) {
			badDates += ' ' + thisFld + '\n';
		}
	}
	if (badDates.length > 0) {
		alert('The following dates are not in a recognized format, or are not valid dates: \n' + badDates);
		return false;
	}
	return true;
}
setInterval ( "checkPicked()", 5000 );
setInterval ( "checkPickedEvnt()", 5000 );
function checkPicked(){
	if(document.getElementById('locality_id')){
		var locality_id=document.getElementById('locality_id');
		if (locality_id.value.length>0){
			pickedLocality();
		}
	}
}
function checkPickedEvnt(){
	if(document.getElementById('collecting_event_id')){
		var collecting_event_id=document.getElementById('collecting_event_id');
		if (collecting_event_id.value.length>0){
			document.getElementById('locality_id').value='';
			pickedEvent();
		}
	}
}			
function rememberLastOtherId (yesno) {
	jQuery.getJSON("/component/DataEntry.cfc",
		{
			method : "rememberLastOtherId",
			yesno : yesno,
			returnformat : "json",
			queryformat : 'column'
		},
		function(yesno){
			var theSpan = document.getElementById('rememberLastId');
			if (yesno==0){
				theSpan.innerHTML='<span class="infoLink" onclick="rememberLastOtherId(1)">Increment This</span>';
			} else if (yesno == 1) {
				theSpan.innerHTML='<span class="infoLink" onclick="rememberLastOtherId(0)">Nevermind</span>';
			} else {
				alert('Something goofy happened. Remembering your next Other ID may not have worked.');
			}
		}
	);
}
function isGoodAccn () {
	jQuery.getJSON("/component/DataEntry.cfc",
		{
			method : "is_good_accn",
			accn : $("#accn").val(),
			institution_acronym : $("#institution_acronym").val(),
			collection_cde: $("#collection_cde").val(),
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			var accn = document.getElementById('accn');
			if (result == 1) {
				accn.className = 'reqdClr';
			} else if (result == 0) {
				alert('You must enter a valid, pre-existing accn.');
				accn.className = 'hasProbs';
			} else {
				alert('An error occured while validating accn. \nYou must enter a valid, pre-existing accn.\n' + result );
				accn.className = 'hasProbs';
			}
		}
	);
	return null;
}
function turnSaveOn () {
	document.getElementById('localityPicker').style.display='none';
	document.getElementById('localityUnPicker').style.display='none';
}
function unpickEvent() {
	$("#collecting_event_id").val('');
	$("#locality_id").val('');
	$("#began_date").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#ended_date").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#verbatim_date").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#collecting_source").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#verbatim_locality").attr("readOnly", false).removeClass();
	$("#coll_event_remarks").attr("readOnly", false).removeClass();
	$("#collecting_method").attr("readOnly", false).removeClass();
	$("#collecting_time").attr("readOnly", false).removeClass();
	$("#habitat_desc").attr("readOnly", false).removeClass();
	$("#eventUnPicker").hide();
	$("#eventPicker").show();
	unpickLocality();
}						
function unpickLocality () {
	switchActive($("#orig_lat_long_units").val());
	
	$("#higher_geog").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#spec_locality").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#latdeg").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#decLAT_DEG").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#latmin").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#latsec").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#latdir").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#longdeg").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#longmin").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#longsec").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#longdir").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#dec_lat_min").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#decLAT_DIR").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#decLONGDEG").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#dec_long_min").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#decLONGDIR").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#dec_lat").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#dec_long").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#datum").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#determined_by_agent").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#determined_date").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#lat_long_ref_source").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#georefmethod").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#verificationstatus").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#maximum_elevation").attr("readOnly", false).removeClass();
	$("#minimum_elevation").attr("readOnly", false).removeClass();
	$("#orig_elev_units").attr("readOnly", false).removeClass();
	$("#max_depth").attr("readOnly", false).removeClass();
	$("#min_depth").attr("readOnly", false).removeClass();
	$("#depth_units").attr("readOnly", false).removeClass();
	$("#locality_remarks").attr("readOnly", false).removeClass();
	$("#max_error_distance").attr("readOnly", false).removeClass();
	$("#max_error_units").attr("readOnly", false).removeClass();
	$("#extent").attr("readOnly", false).removeClass();
	$("#gpsaccuracy").attr("readOnly", false).removeClass();
	$("#lat_long_remarks").attr("readOnly", false).removeClass();
	$("#orig_lat_long_units").attr("readOnly", false).removeClass();	
	$("#utm_zone").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#utm_ew").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#utm_ns").attr("readOnly", false).removeClass().addClass('reqdClr');
	$("#locality_id").val('');
	$("#fetched_locid").val('');
	$("#fetched_eventid").val('');
	$("#localityUnPicker").hide();
	$("#localityPicker").show('');
	for (i=0;i<6;i++) {
		var eNum=parseInt(i+1);
		var thisVal=$("#geo_att_value_" + eNum).val();
		$("#geology_attribute_" + eNum).attr("readOnly", false).removeClass().addClass('reqdClr');
		populateGeology('geology_attribute_' + eNum);
		$("#geo_att_value_" + eNum).attr("readOnly", false).removeClass().addClass('reqdClr').val(thisVal);
		$("#geo_att_determiner_" + eNum).attr("readOnly", false).removeClass();
		$("#geo_att_determiner_" + eNum).attr("readOnly", false).removeClass();
		$("#geo_att_determined_date_" + eNum).attr("readOnly", false).removeClass();
		$("#geo_att_determined_method_" + eNum).attr("readOnly", false).removeClass();
		$("#geo_att_remark_" + eNum).attr("readOnly", false).removeClass();
	}
}
function pickedEvent () {
	var collecting_event_id = document.getElementById('collecting_event_id').value;
	var peid = document.getElementById('fetched_eventid').value;
	if (collecting_event_id==peid){
		return false;
	}
	if (collecting_event_id.length > 0) {
		document.getElementById('locality_id').value='';
		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "get_picked_event",
				collecting_event_id : collecting_event_id,
				returnformat : "json",
				queryformat : 'column'
			},
			success_pickedEvent
		);
	}
}
function success_pickedEvent(r){
	var result=r.DATA;
	if (result.COLLECTING_EVENT_ID[0] < 0) {
		alert('Oops! Something bad happend with the collecting_event pick. ' + result.MSG);
	} else {
		$("#locality_id").val('');
		$("#fetched_eventid").val(result.COLLECTING_EVENT_ID[0]);
		$("#began_date").val(result.BEGAN_DATE[0]).removeClass().addClass('readClr').attr('readonly',true);
		$("#ended_date").val(result.ENDED_DATE[0]).removeClass().addClass('readClr').attr('readonly',true);
		$("#verbatim_date").val(result.VERBATIM_DATE[0]).removeClass().addClass('readClr').attr('readonly',true);
		$("#verbatim_locality").val(result.VERBATIM_LOCALITY[0]).removeClass().addClass('readClr').attr('readonly',true);
		$("#coll_event_remarks").val(result.COLL_EVENT_REMARKS[0]).removeClass().addClass('readClr').attr('readonly',true);
		$("#collecting_source").val(result.COLLECTING_SOURCE[0]).removeClass().addClass('readClr').attr('readonly',true);
		$("#collecting_method").val(result.COLLECTING_METHOD[0]).removeClass().addClass('readClr').attr('readonly',true);
		$("#collecting_time").val(result.COLLECTING_TIME[0]).removeClass().addClass('readClr').attr('readonly',true);
		$("#habitat_desc").val(result.HABITAT_DESC[0]).removeClass().addClass('readClr').attr('readonly',true);		
		$("#eventPicker").hide();
		$("#eventUnPicker").show();
		success_pickedLocality(r);
	}
}
function pickedLocality () {
	var locality_id = document.getElementById('locality_id').value;
	var pid = document.getElementById('fetched_locid').value;
	var collecting_event_id = document.getElementById('collecting_event_id').value;
	if (collecting_event_id.length>0){
		locality_id.value='';
		return false;
	}
	if (locality_id==pid){
		return false;
	}
	if (locality_id.length > 0) {
		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "get_picked_locality",
				locality_id : locality_id,
				returnformat : "json",
				queryformat : 'column'
			},
			success_pickedLocality
		);
	}
}
function success_pickedLocality (r) {
	result=r.DATA;
	if (result.LOCALITY_ID[0] < 0) {
		alert('Oops! Something bad happend with the locality pick. ' + result.MSG[0]);
	} else {
		$("#fetched_locid").val(result.LOCALITY_ID[0]);

		$("#higher_geog").attr("readOnly", true).removeClass().addClass('readClr').val(result.HIGHER_GEOG[0]);
		$("#maximum_elevation").attr("readOnly", true).removeClass().addClass('readClr').val(result.MAXIMUM_ELEVATION[0]);
		$("#minimum_elevation").attr("readOnly", true).removeClass().addClass('readClr').val(result.MINIMUM_ELEVATION[0]);
		$("#orig_elev_units").attr("readOnly", true).removeClass().addClass('readClr').val(result.ORIG_ELEV_UNITS[0]);
		$("#max_depth").attr("readOnly", true).removeClass().addClass('readClr').val(result.MAX_DEPTH[0]);
		$("#min_depth").attr("readOnly", true).removeClass().addClass('readClr').val(result.MIN_DEPTH[0]);
		$("#depth_units").attr("readOnly", true).removeClass().addClass('readClr').val(result.DEPTH_UNITS[0]);
		$("#spec_locality").attr("readOnly", true).removeClass().addClass('readClr').val(result.SPEC_LOCALITY[0]);
		$("#locality_remarks").attr("readOnly", true).removeClass().addClass('readClr').val(result.LOCALITY_REMARKS[0]);
		$("#latdeg").attr("readOnly", true).removeClass().addClass('readClr').val(result.LAT_DEG[0]);
		$("#decLAT_DEG").attr("readOnly", true).removeClass().addClass('readClr').val(result.LAT_DEG[0]);
		$("#latmin").attr("readOnly", true).removeClass().addClass('readClr').val(result.LAT_MIN[0]);
		$("#latsec").attr("readOnly", true).removeClass().addClass('readClr').val(result.LAT_SEC[0]);
		$("#latdir").attr("readOnly", true).removeClass().addClass('readClr').val(result.LAT_DIR[0]);
		$("#longdeg").attr("readOnly", true).removeClass().addClass('readClr').val(result.LONG_DEG[0]);
		$("#longmin").attr("readOnly", true).removeClass().addClass('readClr').val(result.LONG_MIN[0]);
		$("#longsec").attr("readOnly", true).removeClass().addClass('readClr').val(result.LONG_SEC[0]);
		$("#longdir").attr("readOnly", true).removeClass().addClass('readClr').val(result.LONG_DIR[0]);
		$("#dec_lat_min").attr("readOnly", true).removeClass().addClass('readClr').val(result.DEC_LAT_MIN[0]);
		$("#decLAT_DIR").attr("readOnly", true).removeClass().addClass('readClr').val(result.LAT_DIR[0]);
		$("#decLONGDEG").attr("readOnly", true).removeClass().addClass('readClr').val(result.LONG_DEG[0]);
		$("#dec_long_min").attr("readOnly", true).removeClass().addClass('readClr').val(result.DEC_LONG_MIN[0]);
		$("#decLONGDIR").attr("readOnly", true).removeClass().addClass('readClr').val(result.LONG_DIR[0]);
		$("#dec_lat").attr("readOnly", true).removeClass().addClass('readClr').val(result.DEC_LAT[0]);
		$("#dec_long").attr("readOnly", true).removeClass().addClass('readClr').val(result.DEC_LONG[0]);
		$("#max_error_distance").attr("readOnly", true).removeClass().addClass('readClr').val(result.MAX_ERROR_DISTANCE[0]);
		$("#max_error_units").attr("readOnly", true).removeClass().addClass('readClr').val(result.MAX_ERROR_UNITS[0]);
		$("#extent").attr("readOnly", true).removeClass().addClass('readClr').val(result.EXTENT[0]);
		$("#gpsaccuracy").attr("readOnly", true).removeClass().addClass('readClr').val(result.GPSACCURACY[0]);
		$("#datum").attr("readOnly", true).removeClass().addClass('readClr').val(result.DATUM[0]);
		$("#determined_by_agent").attr("readOnly", true).removeClass().addClass('readClr').val(result.DETERMINED_BY[0]);
		$("#determined_date").attr("readOnly", true).removeClass().addClass('readClr').val(result.DETERMINED_DATE[0]);
		$("#lat_long_ref_source").attr("readOnly", true).removeClass().addClass('readClr').val(result.LAT_LONG_REF_SOURCE[0]);
		$("#georefmethod").attr("readOnly", true).removeClass().addClass('readClr').val(result.GEOREFMETHOD[0]);
		$("#verificationstatus").attr("readOnly", true).removeClass().addClass('readClr').val(result.VERIFICATIONSTATUS[0]);
		$("#lat_long_remarks").attr("readOnly", true).removeClass().addClass('readClr').val(result.LAT_LONG_REMARKS[0]);
		$("#utm_zone").attr("readOnly", true).removeClass().addClass('readClr').val(result.UTM_ZONE[0]);
		$("#utm_ew").attr("readOnly", true).removeClass().addClass('readClr').val(result.UTM_EW[0]);
		$("#utm_ns").attr("readOnly", true).removeClass().addClass('readClr').val(result.UTM_NS[0]);
		
		
		switchActive(result.ORIG_LAT_LONG_UNITS[0]);
		
		$("#orig_lat_long_units").attr("readOnly", true).removeClass().addClass('readClr').val(result.ORIG_LAT_LONG_UNITS[0]);
		
		$("#localityPicker").hide();
		$("#localityUnPicker").show();
		
		if (r.ROWCOUNT > 6) {
			alert('Whoa! That is a lot of geology attribtues. They will not all be displayed here, but the locality will still have them.');
		}
		//try {
		for (i=0;i<6;i++) {
				var eNum=parseInt(i+1);
				$("#geology_attribute_" + eNum).attr("readOnly", true).removeClass().addClass('readClr').val('');
				$("#geo_att_value_" + eNum).attr("readOnly", true).removeClass().addClass('readClr').val('');
				$("#geo_att_determiner_" + eNum).attr("readOnly", true).removeClass().addClass('readClr').val('');
				$("#geo_att_determined_date_" + eNum).attr("readOnly", true).removeClass().addClass('readClr').val('');
				$("#geo_att_determined_method_" + eNum).attr("readOnly", true).removeClass().addClass('readClr').val('');
				$("#geo_att_remark_" + eNum).attr("readOnly", true).removeClass().addClass('readClr').val('');
			}
			for (i=0;i<r.ROWCOUNT;i++) {
				if (i<5) {
					var eNum=parseInt(i+1);
					$("#geology_attribute_" + eNum).val(result.GEOLOGY_ATTRIBUTE[i]);
					$("#geo_att_value_" + eNum).append('<option value="' + result.GEO_ATT_VALUE[i] + '">' + result.GEO_ATT_VALUE[i] + '</option>').val(result.GEO_ATT_VALUE[i]);
					$("#geo_att_determiner_" + eNum).val(result.GEO_ATT_DETERMINER[i]);
					$("#geo_att_determined_date_" + eNum).val(result.GEO_ATT_DETERMINED_DATE[i]);
					$("#geo_att_determined_method_" + eNum).val(result.GEO_ATT_DETERMINED_DATE[i]);
					$("#geo_att_remark_" + eNum).val(result.GEO_ATT_DETERMINED_DATE[i]);
				}
			}
		//} catch(err) {
			// whatever
		//}		
	}
}
function catNumSeq () {
	var catnum = document.getElementById('cat_num').value;
	var isCatNum = catnum.length;
	if (isCatNum == 0) { // only get the number if there's not already one in place
		var inst = document.getElementById('institution_acronym').value;
		var coll = document.getElementById('collection_cde').value;			
		var coll_id = inst + " " + coll;
		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "getcatNumSeq",
				coll : coll_id,
				returnformat : "json",
				queryformat : 'column'
			},
			function(result){
				var catnum = document.getElementById('cat_num');
				catnum.value=result;
			}
		);
	}
}
function getAttributeStuff (attribute,element) {
	var isSomething = attribute.length;
	if (isSomething > 0) {
		var optn = document.getElementById(element);
		optn.style.backgroundColor='red';
		var thisCC = document.getElementById('collection_cde').value;
		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "getAttCodeTbl",
				attribute : attribute,
				collection_cde : thisCC,
				element : element,
				returnformat : "json",
				queryformat : 'column'
			},
			success_getAttributeStuff
		);
	}
}
function success_getAttributeStuff (r) {
	var result=r.DATA;
	var resType=result.V[0];
	var theEl=result.V[1];
	var optn = document.getElementById(theEl);
	optn.style.backgroundColor='';
	var n=result.V.length;
	var theNumber = theEl.replace("attribute_","");
	if (resType == 'value') {
		var theDivName = "attribute_value_cell_" + theNumber;
		theTextDivName = "attribute_units_cell_" + theNumber;
		theSelectName = "attribute_value_" + theNumber;
		theTextName = "attribute_units_" + theNumber;
	} else if (resType == 'units') {
		var theDivName = "attribute_units_cell_" + theNumber;
		theSelectName = "attribute_units_" + theNumber;
		theTextDivName = "attribute_value_cell_" + theNumber;
		theTextName = "attribute_value_" + theNumber;
	} else {
		var theDivName = "attribute_value_cell_" + theNumber;
		var theTextDivName = "attribute_units_cell_" + theNumber;
		theSelectName = "attribute_value_" + theNumber;
		theTextName = "attribute_units_" + theNumber;
	}
	var theDiv = document.getElementById(theDivName);
	var theText = document.getElementById(theTextDivName);
	if (resType == 'value' || resType == 'units') {
		theDiv.innerHTML = ''; // clear it out
		theText.innerHTML = '';
		if (n > 2) {
			var theNewSelect = document.createElement('SELECT');
			theNewSelect.name = theSelectName;
			theNewSelect.id = theSelectName;
			if (resType == 'units') {
				var sWid = '60px;';
			} else {
				var sWid = '90px;';
			}
			theNewSelect.style.width=sWid;
			theNewSelect.className = "";
			var a = document.createElement("option");
			a.text = '';
    		a.value = '';
			theNewSelect.appendChild(a);// add blank
			for (i=2;i<result.V.length;i++) {
				var theStr = result.V[i];
				var a = document.createElement("option");
				a.text = theStr;
				a.value = theStr;
				theNewSelect.appendChild(a);
			}
			theDiv.appendChild(theNewSelect);
			if (resType == 'units') {
				var theNewText = document.createElement('INPUT');
				theNewText.name = theTextName;
				theNewText.id = theTextName;	
				theNewText.type="text";
				theNewText.style.width='95px';
				theNewText.className = "";
				theText.appendChild(theNewText);
			}
		}
	} else if (resType == 'NONE') {
		theDiv.innerHTML = '';
		theText.innerHTML = '';
		var theNewText = document.createElement('INPUT');
		theNewText.name = theSelectName;
		theNewText.id = theSelectName;	
		theNewText.type="text";
		theNewText.style.width='95px';
		theNewText.className = "";
		theDiv.appendChild(theNewText);
	} else {
		alert('Something bad happened! Try selecting nothing, then re-selecting an attribute or reloading this page');
	}
}
