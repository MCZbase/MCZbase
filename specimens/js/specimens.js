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
    	width: '500px',
    	minWidth: 500,
    	minHeight: 450,
		buttons: [
			{ text: "Cancel", click: function () { $(this).dialog( "close" ); ;}, class: "btn", style:"background: none; border: none;" },
        	{ text: "Save", click: function () { alert("save"); }, class:"btn btn-primary"}
        
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
/** function loadShipment load a shipment into an edit shipment form within a shipment dialog.
 *  @param shipmentId the shipment_id of the shipment to edit
 *  @param form the id without a leading # selector of the shipment form.
 */
function loadIdentification(identfication_id,form) {
	$("#dialog").dialog( "option", "title", "Edit Identification hi " + identfication_id );
	$("#identificationHTML").html(""); 
	$("#identificationFormStatus").html(""); 
	jQuery.getJSON("/specimens/component/functions.cfc",
		{
			method : "getIdentificationHTML",
			identification_id : identfication_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			try{
				if (result.ROWCOUNT == 1) {
					var i = 0;
					$(" #" + form + " input[name=identification_id]").val(result.DATA.IDENTIFICATION_ID[i]);
					$("#identification_id").val(result.DATA.IDENTIFICATION_ID[i]);
					$("#scientific_name").val(result.DATA.SCIENTIFIC_NAME[i]);	
				} else { 
					 $("#dialog").dialog( "close" );
				}
				loadIdentificationForm(identification_id);
			}
			catch(e){ alert(e); }
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"loading identification");
	});
};
//function loadIdentification(identification_id,form) {
//	$("#dialog_identification").dialog( "option", "title", "Edit Identification here:" + identification_id );
//	$("#identificationForm").html(""); 
//	jQuery.getJSON("/transactions/component/functions.cfc",
//		{
//			method : "getIdentification",
//			shipmentidList : identification_id,
//			returnformat : "json",
//			queryformat : 'column'
//		},
//		function (result) {
//			try{
//				if (result.ROWCOUNT == 1) {
//					var i = 0;
//					$(" #" + form + " input[name=identification_id]").val(result.DATA.IDENTIFICATION_ID[i]);
//					$("#identification_id").val(result.DATA.IDENTIFICATION_ID[i]);
//					$("#scientific_name").val(result.DATA.SCIENTIFIC_NAME[i]);
//					
//				} else { 
//					 $("#dialog_identification").dialog( "close" );
//				}
//			}
//			catch(e){ alert(e); }
//		}
//	).fail(function(jqXHR,textStatus,error){
//		handleFail(jqXHR,textStatus,error,"loading identification record");
//	});
//};
