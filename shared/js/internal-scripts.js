/**
 * Place scripts that should be available on all web pages for all coldfusion users here.
*/

/**
 * Given an url and a window name, either load the url in an existing window of that name, 
 * or open a new window of that name and load the url in that window.
 * 
 * @param url the IRI to load into the window.
 * @param name the name of the window.
 * @param args, if opening a new window the additional arguments to pass to window.open().
 */
function windowOpener(url, name, args) {
   popupWins = [];
   if ( typeof( popupWins[name] ) != "object" ){
         popupWins[name] = window.open(url,name,args);
   } else {
      if (!popupWins[name].closed){
         popupWins[name].location.href = url;
      } else {
         popupWins[name] = window.open(url, name,args);
      }
   }
   popupWins[name].focus();
}
/**
 * Obtain the (internal) MCZbase documentation given a wiki page and heading.
 * 
 * @param url the wiki page name to retrieve
 * @param anc an anchor tag on that wiki page, or null
 *
 */
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

// Check the validity of a form for submission return true if valid, false if not, and if 
// not valid, popup a message dialog listing the problem form elements and their validation messages.
// @param form DOM node of a form to validate
// @return true if the provided node has checkValidity() of true or if the node lacks the checkValidity method.\
//         false otherwise.
// Example usage in onClick event of a button in a form: if (checkFormValidity($('#formId')[0])) { submit();  }  
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
         mmessage = message + "</dl>"
         messageDialog(message,'Unable to Save');
     }
     return result;
};

// Simple message dialog with an OK button.
function messageDialog(dialogText, dialogTitle) {
  $('<div style="padding: 10px; max-width: 500px; word-wrap: break-word;">' + dialogText + '</div>').dialog({
    modal: true,
    resizable: false,
    draggable: true,
    width: 'auto',
    minHeight: 80,
    title: dialogTitle,
    buttons: {
      OK: function () {
         $(this).dialog('destroy');
      }
    },
    close: function() {
       $(this).dialog( "destroy" );
    }
  });
};

/** openlinkmediadialog, create and open a dialog to find and link existing media records with a provided relationship
 * @param dialogid id to give to the dialog
 * @param related_value human readable name of the object to link the media to
 * @param related_id primary key valuue of the object to link the media to
 * @param relationship type of relationship to create
 * @param okcallback callback function to invoke on closing dialog
 */
function openlinkmediadialog(dialogid, related_value, related_id, relationship, okcallback) {
	var title = "Link Media record to " + related_value;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true, 
		stack: true, 
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 400,
		minHeight: 450,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$(this).dialog('close'); 
			}
		}, 
		close: function(event,ui) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			$("#"+dialogid+"_div").html("");
	 		$("#"+dialogid).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/shared/component/functions.cfc",
		type: "post",
		data: {
			method: "linkMediaHtml",
			returnformat: "plain",
			relationship: relationship,
			related_value: related_value,
			related_id: related_id
		},
		success: function (data) {
			$("#"+dialogid+"_div").html(data);
		}, 
		error : function (jqXHR, status, error) {
			var message = "";
			if (error == 'timeout') { 
				message = ' Server took too long to respond.';
			} else { 
				message = jqXHR.responseText;
			}
			$("#"+dialogid+"_div").html("Error (" + error + "): " + message );
		}
	});
}
