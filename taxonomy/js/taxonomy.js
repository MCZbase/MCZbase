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
         taxon_name_id: taxon_name_id
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

function loadCommonNames(taxon_name_id,target) { 
   jQuery.ajax({
      url: "/taxonomy/component/functions.cfc",
      data : {
         method : "getCommonHtml",
         taxon_name_id: taxon_name_id,
         target: target
      },
      success: function (result) {
         $("#" + target).html(result);
      },
      error: function (jqXHR, textStatus, message) {
			handleFail(jqXHR,textStatus,message,"loading common names for taxon");
      },
      dataType: "html"
   });
}

/**
 * newCommon, given a taxon and text string for a common name of the taxon
 * link the common name and reload the list of common names for the taxon.
 * 
 * @param taxon_name_id the primary key for the taxon record to which to add the common name.
 * @param common_name the text string to add to the taxon as a common name.
 * @param target the id of the target div containing the list of common names 
 *   to reload, without a leading # selector.
 */
function newCommon(taxon_name_id,common_name,target) {
	jQuery.getJSON("/taxonomy/component/functions.cfc",
		{
			method : "newCommon",
			common_name : common_name,
			taxon_name_id : taxon_name_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadCommonNames(taxon_name_id,target);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"adding common name to taxon");
	});
};

/**
 * deleteCommonName, given a taxon and text string for a common name of the taxon
 * delete the common name record for that taxon and reload the list of common names for the taxon.
 * 
 * @param taxon_name_id the primary key for the taxon record to which to delete the common name.
 * @param common_name the text string to remove from the taxon as a common name.
 * @param target the id of the target div containing the list of common names 
 *   to reload, without a leading # selector.
 */
function deleteCommonName(taxon_name_id,common_name,target) {
	jQuery.getJSON("/taxonomy/component/functions.cfc",
		{
			method : "deleteCommon",
			common_name : common_name,
			taxon_name_id : taxon_name_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadCommonNames(taxon_name_id,target);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing common name from taxon");
	});
};

function saveCommon(original_common_name, common_name, taxon_name_id,target) {
	jQuery.getJSON("/taxonomy/component/functions.cfc",
		{
			method : "saveCommon",
			common_name : common_name,
			origcommonname : original_common_name,
			taxon_name_id : taxon_name_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadCommonNames(taxon_name_id,target);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"saving changes to common name of taxon");
	});
};

function loadTaxonRelations(taxon_name_id,target) {
   jQuery.ajax({
      url: "/taxonomy/component/functions.cfc",
      data : {
         method : "getTaxonRelationsHtml",
         taxon_name_id: taxon_name_id
      },
      success: function (result) {
         $("#" + target).html(result);
      },
      error: function (jqXHR, textStatus,error) {
			handleFail(jqXHR,textStatus,error,"loading taxon relationships taxon");
      },
      dataType: "html"
   });
};
