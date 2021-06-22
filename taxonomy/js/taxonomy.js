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
 * deleteCommonName, given common name record for a taxon delete the common name
 * record and reload the list of common names for the taxon.
 * 
 * @param common_name_id the primary key value for the common name to delete.
 * @param taxon_name_id the primary key for the taxon record for the common name.
 * @param target the id of the target div containing the list of common names 
 *   to reload, without a leading # selector.
 */
function deleteCommonName(common_name_id,taxon_name_id,target) {
	jQuery.getJSON("/taxonomy/component/functions.cfc",
		{
			method : "deleteCommon",
			common_name_id: common_name_id,
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

function saveCommon(common_name_id, common_name, taxon_name_id, target) {
	jQuery.getJSON("/taxonomy/component/functions.cfc",
		{
			method : "saveCommon",
			common_name : common_name,
			common_name_id : common_name_id,
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

/** Load taxon relationships as html into a target div **/
function loadTaxonRelations(taxon_name_id,target) {
   jQuery.ajax({
      url: "/taxonomy/component/functions.cfc",
      data : {
         method : "getTaxonRelationsHtml",
         taxon_name_id: taxon_name_id,
         target: target 
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
function addTaxonRelation(taxon_name_id,related_taxon_name_id,taxon_relationship,relation_authority,target) {
	jQuery.getJSON("/taxonomy/component/functions.cfc",
		{
			method : "newTaxonRelation",
			taxon_name_id : taxon_name_id,
			newRelatedId: related_taxon_name_id,
			taxon_relationship : taxon_relationship,
			relation_authority : relation_authority,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadTaxonRelations(taxon_name_id,target);
			clearTaxonRelationFields();
			$("#addTaxonRelationFeedback").hide();
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"saving changes to a taxon relationship");
		$("#addTaxonRelationFeedback").hide();
	});
};
/**
 * deleteTaxonRelation, given the elements needed to uniquely identify a taxon_relations record
 * delete that record.
 * 
 * @param taxon_name_id the primary key for the taxon record to which to delete the relationship.
 * @param related_taxon_name_id the primary key for the related taxon record in the relationship.
 * @param taxon_relationship the text string representing the taxon relationship type.
 * @param target the id of the target div containing the list of taxon relationships
 *   to reload, without a leading # selector.
 */
function deleteTaxonRelation(taxon_name_id,related_taxon_name_id,taxon_relationship,target) {
	jQuery.getJSON("/taxonomy/component/functions.cfc",
		{
			method : "deleteTaxonRelation",
			taxon_relationship : taxon_relationship ,
			taxon_name_id : taxon_name_id,
			related_taxon_name_id : related_taxon_name_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadTaxonRelations(taxon_name_id,target);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing relationship from taxon");
	});
};

/* function openEditTaxonRelationDialog create a dialog to edit a taxon relationship
 * 
 * @param taxon_name_id the id of the parent taxon
 * @param related_taxon_name_id the id of the related taxon
*  @param relationship the relationship type
 * @param dialogId the id, without a leading # selector, of the div that is to contain the dialog.
 * @param projectsDivId the id, without a leading # selector, of the div containing a list of relations
 *   that is to be reloaded with loadRelations at dialog close.
 * @see loadProjects
 */
function openEditTaxonRelationDialog(taxon_name_id, related_taxon_name_id, relationship, dialogId, relationsDivId) { 
	var title = "Edit Taxon Relationship.";
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		minWidth: 320,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$(this).dialog("close"); 
				loadTaxonRelations(taxon_name_id,relationsDivId);
			}
		},
		open: function (event, ui) {
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			$("#"+dialogId+"_div").html("");
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/taxonomy/component/functions.cfc",
		type: "get",
		data: {
			method: 'getTaxonRelationEditor',
			returnformat: "plain",
			taxon_name_id: taxon_name_id,
			related_taxon_name_id: related_taxon_name_id,
			taxon_relationship: relationship,
			target: relationsDivId
		},
		success: function(data) {
			$("#"+dialogId+"_div").html(data);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"openting edit taxon relationship dialog");
		}
	});
}
/** function saveTaxonRelation for a given taxon name id, save changes to an existing relationship to another taxon.
 *
 * @param taxon_name_id the primary key for the taxon record to which to delete the relationship.
 * @param related_taxon_name_id the primary key for the related taxon record in the relationship.
 * @param taxon_relationship the text string representing the taxon relationship type.
 * @param target the id of the target div containing the list of taxon relationships
 *   to reload, without a leading # selector.
 * @param feedbacktarget the id of an output node, without a leading # selector, in which to show saving/saved feedback.
**/
function saveTaxonRelation(taxon_name_id,orig_related_taxon_name_id,orig_taxon_relationship,new_related_taxon_name_id,new_taxon_relationship,new_relation_authority,target,feedbacktarget) {
   $("#"+feedbacktarget).html("<img src='/shared/images/indicator.gif'> Saving...");
   $("#"+feedbacktarget).show();
	jQuery.getJSON("/taxonomy/component/functions.cfc",
		{
			method : "saveTaxonRelationEdit",
			orig_taxon_name_id : taxon_name_id,
			orig_related_taxon_name_id: orig_related_taxon_name_id,
			orig_taxon_relationship : orig_taxon_relationship,
			new_related_taxon_name_id: new_related_taxon_name_id,
			new_taxon_relationship : new_taxon_relationship,
			relation_authority : new_relation_authority,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadTaxonRelations(taxon_name_id,target);
   		$("#"+feedbacktarget).html("Saved.");
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"saving changes to a taxon relationship");
   	$("#"+feedbacktarget).html("Error.");
	});
};

/**
 * newHabitat, given a taxon and text string for a habitat of the taxon
 * link the habitat and reload the list of habitats for the taxon.
 * 
 * @param taxon_name_id the primary key for the taxon record to which to add the habitat.
 * @param habitat the text string to add to the taxon as a habitat.
 * @param target the id of the target div containing the list of habitats 
 *   to reload, without a leading # selector.
 */
function newHabitat(taxon_name_id,habitat,target) {
	jQuery.getJSON("/taxonomy/component/functions.cfc",
		{
			method : "newHabitat",
			taxon_habitat : habitat,
			taxon_name_id : taxon_name_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadHabitats(taxon_name_id,target);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"adding habitat to taxon");
	});
};
/** given a taxon_habitat_id remove a row from the taxon_habitat table 
 * and reload the habitats for a specified taxon into a specified target div
 */
function deleteHabitat(taxon_habitat_id,taxon_name_id,target) {
	jQuery.getJSON("/taxonomy/component/functions.cfc",
		{
			method : "deleteHabitat",
			taxon_habitat_id : taxon_habitat_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadHabitats(taxon_name_id,target);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"adding habitat to taxon");
	});
};
/** given a taxon name id and a target div, load an html description of the habitats
 * for the specified taxon.
 * @param taxon_name_id the pk of the taxonomy table for which to look up habitats.
 * @param target the id of the target div to contain the list of habitats 
 *   to load, without a leading # selector.
 */
function loadHabitats(taxon_name_id,target) { 
   jQuery.ajax({
      url: "/taxonomy/component/functions.cfc",
      data : {
         method : "getHabitatsHtml",
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
