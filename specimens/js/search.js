/** Functions used to support specimen search only on the specimen search page.  **/



/** createSpecimenRowDetailsDialog 
 * Create a specialized jquery-ui dialog to display row details for a cataloged item in a jqxgrid.  
 * Iterates through columns in cataloged item data record and displays a variable height dialog showing the columns and details as 
 * key-value pairs for a particular row index in the grid, with special handling of some fields.
 *
 *@param gridId the id, without a leading # selector for the grid. 
 *@param rowDetailsTargetId the id, without the leading # selector or the trailing rowid created in the initrowdetails function.
 *@param datarecord the jqxgrid datarecord.
 *@param rowIndex the row index for the selected grid row, available as index in initRowDetails() or event.args.rowIndex in rowexpand event handler.
 *
 * @see createRowDetailsDialog for invocation details.
 */
function createSpecimenRowDetailsDialog(gridId, rowDetailsTargetId, datarecord,rowIndex) {
	var content = "<div id='" + gridId+  "RowDetailsDialog" + rowIndex + "'><ul>";
	var columns = $('#' + gridId).jqxGrid('columns').records;
	var gridWidth = $('#' + gridId).width();
	var dialogWidth = Math.round(gridWidth/2);
	if (dialogWidth < 150) { dialogWidth = 150; }
	var scientific_name = "";
	var collection_object_id = "";
	var guid = "";
	for (i = 1; i < columns.length; i++) {
		var text = columns[i].text;
		var datafield = columns[i].datafield;
		if (datafield=="SCIENTIFIC_NAME") { 
			scientific_name = encodeURIComponent(datarecord[datafield]);
		} else if (datafield=="GUID") { 
			guid = datarecord[datafield];
		} else if (datafield=="COLLECTION_OBJECT_ID") { 
			collection_object_id = datarecord[datafield];
		}
	}
	for (i = 1; i < columns.length; i++) {
		var text = columns[i].text;
		var datafield = columns[i].datafield;
		if (datarecord[datafield]) { 
			if (datafield=="SCIENTIFIC_NAME") { 
				content = content + "<li><strong>" + text + ":</strong> <a href='/name/"+scientific_name+"' target='_blank'>" + datarecord[datafield] +  "</a></li>";
			} else if (datafield=="SCI_NAME_WITH_AUTH") { 
				content = content + "<li><strong>" + text + ":</strong> <a href='/name/"+scientific_name+"' target='_blank'>" + datarecord[datafield] +  "</a></li>";
				content = content + "<li><strong>" + text + ":</strong> <a href='/Specimens.cfm?action=fixedSearch&scientific_name="+scientific_name+"' target='_blank'> Search for specimens identified as " + datarecord[datafield] +  "</a></li>";
			} else if (datafield=="MEDIA") { 
				content = content + "<li><strong>" + text + ":</strong> <a href='/media/findMedia.cfm?execute=true&method=getMedia&media_relationship_type=ANY%20cataloged_item&media_relationship_value="+ guid +"&media_relationship_id=" + collection_object)id + "' aria-label='related media' target='_blank'>" + datarecord[datafield] +  "</a></li>";
			} else if (datafield=="GUID") { 
				content = content + "<li><strong>" + text + ":</strong> <a href='/guid/"+guid+"' target='_blank'>" + datarecord[datafield] +  "</a></li>";
			} else if (datafield=="CAT_NUM_INGEGER" || datafield=="CAT_NUM_PREFIX" || datafield="CAT_NUM_SUFFIX") {
				// skip 
			} else { 
				content = content + "<li><strong>" + text + ":</strong> " + datarecord[datafield] +  "</li>";
			}
		}
	}
	content = content + "</ul></div>";
	$("#" + rowDetailsTargetId + rowIndex).html(content);
	$("#"+ gridId +"RowDetailsDialog" + rowIndex ).dialog(
		{ 
			autoOpen: true, 
			buttons: [ { text: "Ok", click: function() { $( this ).dialog( "close" ); $("#" + gridId).jqxGrid('hiderowdetails',rowIndex); } } ],
			width: dialogWidth,
			title: 'Record Details'		
		}
	);
	// Workaround, expansion sits below row in zindex.
	var maxZIndex = getMaxZIndex();
	$("#"+gridId+"RowDetailsDialog" + rowIndex ).parent().css('z-index', maxZIndex + 1);
};
>>>>>>> test
