/** Scripts for Specimen Part Name vocabulary management.
 *
 * vocabularies/js/ctspecimen_part_name.js
 *
 * Copyright 2008-2026 President and Fellows of Harvard College
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Open the jquery-ui edit dialog for a specimen part name row.
 * Reads data-* attributes from the row element to populate the form.
 *
 * @param {number} ctspnid - primary key of the ctspecimen_part_name record
 */
function openEditPartDialog(ctspnid) {
	var row = $('#r' + ctspnid);
	var collection_cde = row.data('collection-cde');
	var part_name = row.data('part-name');
	var is_tissue = row.data('is-tissue');
	var description = row.data('description');

	$('#editPartCtspnid').val(ctspnid);
	$('#editPartCollCde').val(collection_cde);
	$('#editPartName').val(part_name);
	$('#editPartIsTissue').val(is_tissue);
	$('#editPartDescription').val(description);
	$('#editPartUpAllDesc').val('0');
	$('#editPartUpAllTiss').val('0');
	$('#editPartFeedback').html('').removeClass('text-danger text-success text-warning');

	$('#editPartDialog').dialog({
		title: 'Edit Part Name: ' + part_name,
		modal: true,
		width: 520,
		minHeight: 350,
		draggable: true,
		resizable: true,
		buttons: {
			'Save': function() {
				saveCtPartName();
			},
			'Cancel': function() {
				$(this).dialog('close');
			}
		},
		close: function() {
			$(this).dialog('destroy');
		},
		open: function(event, ui) {
			var maxZIndex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZIndex + 4});
			$('.ui-widget-overlay').css({'z-index': maxZIndex + 3});
		}
	});
	$('#editPartDialog').dialog('open');
}

/**
 * Submit the edit dialog form via AJAX to /vocabularies/component/functions.cfc.
 * On success, updates the table row in place (or reloads if a bulk update was requested).
 */
function saveCtPartName() {
	var ctspnid      = $('#editPartCtspnid').val();
	var collection_cde = $('#editPartCollCde').val();
	var part_name    = $('#editPartName').val();
	var is_tissue    = $('#editPartIsTissue').val();
	var description  = $('#editPartDescription').val();
	var upAllDesc    = $('#editPartUpAllDesc').val();
	var upAllTiss    = $('#editPartUpAllTiss').val();

	$('#editPartFeedback').html('Saving&hellip;').removeClass('text-danger text-success').addClass('text-warning');

	$.ajax({
		url: '/vocabularies/component/functions.cfc',
		data: {
			method: 'updateCtPartName',
			ctspnid: ctspnid,
			collection_cde: collection_cde,
			part_name: part_name,
			is_tissue: is_tissue,
			description: description,
			upAllDesc: upAllDesc,
			upAllTiss: upAllTiss,
			returnformat: 'json'
		},
		dataType: 'json',
		success: function(result) {
			if (result.STATUS === 1) {
				if (result.UPALLDESC === 1 || result.UPALLTISS === 1) {
					document.location.reload();
				} else {
					var row = $('#r' + ctspnid);
					row.data('collection-cde', result.COLLECTION_CDE);
					row.data('part-name', result.PART_NAME);
					row.data('is-tissue', result.IS_TISSUE);
					row.data('description', result.DESCRIPTION);
					row.find('.col-cde').text(result.COLLECTION_CDE);
					row.find('.col-part').text(result.PART_NAME);
					row.find('.col-tissue').text(result.IS_TISSUE === 1 ? 'yes' : 'no');
					row.find('.col-desc').text(result.DESCRIPTION);
					$('#editPartDialog').dialog('close');
				}
			} else {
				$('#editPartFeedback')
					.html('Error: ' + result.MESSAGE)
					.removeClass('text-warning text-success')
					.addClass('text-danger');
			}
		},
		error: function(jqXHR, textStatus, error) {
			$('#editPartFeedback')
				.html('Error: ' + error)
				.removeClass('text-warning text-success')
				.addClass('text-danger');
		}
	});
}

/**
 * Delete a specimen part name record via AJAX.
 * Removes the table row on success.
 *
 * @param {number} ctspnid - primary key of the record to delete
 */
function deleteCtPartName(ctspnid) {
	var partName = $('#r' + ctspnid).data('part-name') || 'this part name';
	confirmDialog('Delete the part name \u201c' + partName + '\u201d?', 'Confirm Delete', function() {
		$.ajax({
			url: '/vocabularies/component/functions.cfc',
			data: {
				method: 'deleteCtPartName',
				ctspnid: ctspnid,
				returnformat: 'json'
			},
			dataType: 'json',
			success: function(result) {
				if (result.STATUS === 1) {
					$('#r' + ctspnid).remove();
				} else {
					messageDialog(result.MESSAGE, 'Delete Failed');
				}
			},
			error: function(jqXHR, textStatus, error) {
				messageDialog(error, 'Delete Failed');
			}
		});
	});
}
