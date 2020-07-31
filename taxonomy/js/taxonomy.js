/** Scripts specific to taxonomy pages. **/

/** loadTaxonName given a taxon name id and a target in the dom, replace the 
 * content of the target in the dom with the html of the taxon name string (with authorship).
 * @param taxon_name_id the taxonomy entry to look up
 * @param target the target div to replace the content of with the return value 
 */
function loadTaxonName(taxon_name_id,target) {
   jQuery.ajax({
      url: "/taxonomy/component/functions.cfc",
      data : {
         method : "getTaxonNameHtml",
         taxon_name_id: taxon_name_id,
      },
      success: function (result) {
         $("#" + target).html(result);
      },
      error: function (jqXHR, status, message) {
         if (jqXHR.responseXML) { msg = jqXHR.responseXML; } else { msg = jqXHR.responseText; }
         messageDialog("Error loading taxon name: " + message + " " + msg ,'Error: '+ message);
      },
      dataType: "html"
   });
};

function loadTaxonPublications(taxon_name_id,target) {
   jQuery.ajax({
      url: "/taxonomy/component/functions.cfc",
      data : {
         method : "getTaxonPublicationsHtml",
         taxon_name_id: taxon_name_id,
      },
      success: function (result) {
         $("#" + target).html(result);
      },
      error: function (jqXHR, status, message) {
         if (jqXHR.responseXML) { msg = jqXHR.responseXML; } else { msg = jqXHR.responseText; }
         messageDialog("Error loading taxon publications: " + message + " " + msg ,'Error: '+ message);
      },
      dataType: "html"
   });
};
