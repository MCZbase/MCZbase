function loadCitPubForMedia(publication_id) {
targetDiv="CitPubFormMedia";
	console.log(" media in #"+ targetDiv);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getMediaForCitPub",
			publication_id: publication_id,
		},
		success: function (result) {
			$("#CitPubFormMedia").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing pub");
		},
		dataType: "html"
	});
}

	$(function() {
     $(".dialog").dialog({
		open: function(event,ui){},
        Title: {style:"font-size: 1.3em;"},
		bgiframe: true,
        autoOpen: false,
    	width: '700px',
    	minWidth: 500,
    	minHeight: 450,
		buttons: [
			{ text: "Cancel", click: function () { $(this).dialog( "close" );}, class: "btn", style:"background: none; border: none;" },
        	{ text: "Save",  click: function() { alert("save"); }, class:"btn btn-primary"}
		 ],
        close: function() {
            $(this).dialog( "close" );
        },
        modal: true
	 }
       );
     $('body')
      .bind(
       'click',
       function(e){
        if(
         $('.dialog-ID').dialog('isOpen')
         && !$(e.target).is('.ui-dialog, button')
         && !$(e.target).closest('.ui-dialog').length
        ){
         $('.dialog').dialog('close');
        }
       }
      );
    }
   );
//function loadIdentification(identification_id,form) {
//	jQuery.ajax({
//		url: "/specimens/component/functions.cfc",
//		data : {
//			method : "getIdentificationHtml",
//			identification_id: identification_id,
//		},
//		success: function (result) {
//			$("#identificationHTML").html(result);
//		},
//		error: function (jqXHR, textStatus, error) {
//			handleFail(jqXHR,textStatus,error,"removing identification");
//		},
//		dataType: "html"
//	});
//};
//function loadIdentification(identification_id) {
//	console.log("Reloading ID in #indentificationHTML");
//	jQuery.ajax({
//		url: "/specimens/component/functions.cfc",
//		data : {
//			method : "getIdentificationByHtml",
//			identification_id : identification_id
//		},
//		success: function (result) {
//			$("#identificationHTML").html(result);
//		},
//		error: function (jqXHR, textStatus, error) {
//			handleFail(jqXHR,textStatus,error,"deleting ID");
//		},
//		dataType: "html"
//	});
//};
function loadIdentification(identificationId,form) {
	$("#dialog-identification").dialog( "option", "title", "Edit Identification " + identificationId ); 
	jQuery.getJSON("/specimens/component/functions.cfc",
		{
			method : "getIdentification",
			identificatonidList : identificationId,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			try{
				if (result.ROWCOUNT == 1) {
					var i = 0;
					$(" #" + form + " input[name=identification_id]").val(result.DATA.IDENTIFICATION_ID[i]);
					$("#identification_id").val(result.DATA.IDENTIFICATION_ID[i]);
					$("#collection_object_id").val(result.DATA.COLLECTION_OBJECT_ID[i]);
					$("#made_date").val(result.DATA.MADE_DATE[i]);
					$("#nature_of_id").val(result.DATA.NATURE_OF_ID[i]);
					$("#identification_remarks").val(result.DATA.IDENTIFICATION_REMARKS[i]);
					$("#scientific_name").val(result.DATA.SCIENTIFIC_NAME[i]);
					$("#accepted_id_fg").val(result.DATA.ACCEPTED_ID_FG[i]);
					$("#taxa_formula").val(result.DATA.TAXA_FORMULA[i]);
					$("#formatted_publication").val(result.DATA.FORMATTED_PUBLICATION[i]);
					$("#publication_id").val(result.DATA.PUBLICATION_ID[i]);
					$("#stored_as_fg").val(result.DATA.STORED_AS_FG[i]);
					var target = "#shipped_carrier_method option[value='" + result.DATA.SHIPPED_CARRIER_METHOD[i] + "']";

				loadIdentification(identificationId);
			}
			catch(e){ alert(e); }
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"loading identification record");
	});
};
//function loadNewIdentificationForm(addIdentification_id,form) {
//	jQuery.ajax({
//		url: "/specimens/component/functions.cfc",
//		data : {
//			method : "getIdentificationHtml",
//			identification_id: identification_id,
//		},
//		success: function (result) {
//			$("#identificationHTML").html(result);
//		},
//		error: function (jqXHR, textStatus, error) {
//			handleFail(jqXHR,textStatus,error,"removing identification");
//		},
//		dataType: "html"
//	});
//};
function checkFormValidity(form) { 
	var result = false;
	if (!form.checkValidity || form.checkValidity()) { 
		result = true;
	} else { 
		var message = "Form Input validation problem.<br><dl>";
		for(var i=0; i < form.elements.length; i++){
			var element = form.elements[i];
			if (element.checkValidity() == false) { 
				var label = $( "label[for=" + element.id + "] ").text();
				if (label==null || label=='') { label = element.id; }
					message = message + "<dt>" + label + ":</dt> <dd>" + element.validationMessage + "</dd>";
				}
			}
			message = message + "</dl>"
			messageDialog(message,'Unable to Save');
		}
	return result;
};
