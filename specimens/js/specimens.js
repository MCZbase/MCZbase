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
    	width: 'auto',
    	minWidth: 'auto',
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
function getIdentification(identfication_id,form) {
	$("#dialog-identification").dialog( "option", "title", "Edit Identification " + identfication_id );
	$("#identificationForm").html(""); 
	$("#identificationFormStatus").html(""); 
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "getidentification",
			shipmentidList : identfication_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			try{
				if (result.ROWCOUNT == 1) {
					var i = 0;
					$(" #" + form + " input[name=identification_id]").val(result.DATA.identification_id[i]);
					$("#identification_id").val(result.DATA.identification_ID[i]);
					$("#scientific_name").val(result.DATA.scientific_name[i]);

					var target = "#shipped_carrier_method option[value='" + result.DATA.SHIPPED_CARRIER_METHOD[i] + "']";
$(target).attr("selected",true);
	
				} else { 
					 $("#dialog-identification").dialog( "close" );
				}
				loadIdentificationForm(identification_id);
			}
			catch(e){ alert(e); }
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"loading identification");
	});
};

