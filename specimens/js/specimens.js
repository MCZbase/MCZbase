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
function loadIdentification(identification_id,form) {
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getIdentificationHtml",
			identification_id: identification_id,
		},
		success: function (result) {
			$("#identificationHTML").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing identification");
		},
		dataType: "html"
	});
};
//function loadIdentification(identification_id,form) {
//	//$(".dialog").dialog( "option", "title", "Edit Identification here:" + identification_id );
//	$("#identificationHTML").html(""); 
//	jQuery.getJSON("/specimens/component/functions.cfc",
//		{
//			method : "getIdentificationHTML",
//			identification_id : identification_id,
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
//					 $(".dialog").dialog( "close" );
//				}
//			}
//			catch(e){ alert(e); }
//		}
//	).fail(function(jqXHR,textStatus,error){
//		handleFail(jqXHR,textStatus,error,"loading identification record");
//	});
//};
