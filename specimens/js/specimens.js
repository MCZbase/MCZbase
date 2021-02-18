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
        	{ text: "Save", click: function () { function(){ 
				var datasub = $('#identificationForm').serialize();
				if ($('#identificationForm')[0].checkValidity()) {
					$.ajax({
						url: "/specimens/component/functions.cfc",
						type: 'post',
						returnformat: 'plain',
						data: datasub,
						success: function(data) { 
							if (jQuery.type(okcallback)==='function') {
								okcallback();
							};
							$("#"+dialogid+"_div").html(data);
						},
						fail: function (jqXHR, textStatus,error) { 
							handleFail(jqXHR,textStatus,error,"saving identification");
						}	
					});
		 		} else { 
					messageDialog('Missing required elements in form.  Fill in all yellow boxes. ','Form Submission Error, missing required values');
		 		}; }, class:"btn btn-primary"}
        
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

