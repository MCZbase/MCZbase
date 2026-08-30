<!---
/containers/createContainerSeries.cfm

Bulk-creates a numbered series of container records sharing one parent and container type, for
pre-printing or reserving a run of barcode labels.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->

<cfset pageTitle = "Create Container Series">
<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">

<cfquery name="ctcontainer_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT container_type
	FROM ctcontainer_type
	ORDER BY container_type
</cfquery>
<cfquery name="ctinstitution_acronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT distinct institution_acronym
	FROM collection
	WHERE institution_acronym IS NOT NULL
	ORDER BY institution_acronym
</cfquery>

<main id="content" class="container py-3">
<cfoutput>
	<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="createContainerSeriesHeading">
		<div class="col-12">
			<h1 class="h2 ml-1 mb-1" id="createContainerSeriesHeading">Create Container Series</h1>
			<p>
				Containers (things you can stick a barcode on) in MCZbase should exist before they may be
				used. This form creates a series of containers -- use it if you have placed, will place, or
				intend to print a series of labels, or wish to create a set of containers for a set of 
				pre-printed barcodes, or wish to reserve a series of labels for any other
				reason. This form does nothing to labels that already exist.
				<strong>A series larger than 10000 is abnormally large and will ask you to confirm before proceeding; a series larger than 1000 will also ask you to confirm if the Parent Container is a specific location below building level (e.g. a room, freezer, or fixture), rather than left unplaced or placed at the institution/building level.</strong>
			</p>
			<p>
				The barcode will be <strong>Prefix{number}Suffix</strong> -- enter exactly what the scanner
				will read, including any spaces. Label Prefix/Suffix and Unique Identifier Prefix/Suffix are
				the non-numeric parts of the label and identifier applied to each container; if Label
				Prefix/Suffix are left blank, the Unique Identifier Prefix/Suffix are used for the label too.
			</p>
			<p>
				Containers for a range of pre-printed PLACE barcodes can be created in the form {m}PLACE{n}, 
				select the Create PLACE barcodes option and enter a number of  an up 8 digits as the
				low number and high number series,  where the number will be zero padded to 8 digits 
				and the first 4 digits will be used as m before PLACE, and the last 4 digits will be used
				as n after PLACE.  For example, enter 230001 as the low number and 230005 as the high number 
				to create 0023PLACE0001 to 0023PLACE0005, or 12345601 to 12345610 to create 1234PLACE5601 to
				1234PLACE5610.
			</p>
			<p>
				If the chosen Parent Container has its own declared positions (e.g. a freezer box or rack)
				with empty slots available, a "Place into empty positions" option will appear -- checking it
				places each new container into one empty position in sequence, instead of directly into the
				parent itself.
			</p>

			<form class="col-12 px-0" id="createContainerSeriesForm" name="createContainerSeriesForm" novalidate onsubmit="return false;">
				<div class="form-row">
					<div class="col-12 mb-2">
						<label for="parent_container" class="data-entry-label">Parent Container for the new series</label>
						<input type="hidden" name="parent_container_id" id="parent_container_id">
						<div class="d-flex align-items-center">
							<input type="text" name="parent_container" id="parent_container" class="data-entry-input reqdClr flex-grow-1" required aria-required="true">
							<button type="button" id="chooseParentContainerBtn" class="btn btn-xs btn-secondary ml-1">Choose...</button>
							<a href="##" target="_blank" rel="noopener noreferrer" id="viewParentContainerBtn" class="btn btn-xs btn-info ml-1 d-none">View</a>
						</div>
						<div id="createSeriesParentFeedback" class="small mt-1" role="status"></div>
						<div id="placeInPositionsRow" class="form-check mt-1 d-none">
							<input type="checkbox" class="form-check-input" name="place_in_positions" id="place_in_positions">
							<label class="form-check-label" for="place_in_positions">Place the new containers into the parent's empty positions, in sequence, instead of directly into the parent</label>
							<div id="placeInPositionsHint" class="text-muted"></div>
						</div>
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-4 mb-2">
						<label for="institution_acronym" class="data-entry-label">Institution Acronym</label>
						<select name="institution_acronym" id="institution_acronym" class="data-entry-select reqdClr col-12" required aria-required="true">
							<cfloop query="ctinstitution_acronym">
								<option value="#encodeForHtml(institution_acronym)#"<cfif institution_acronym EQ "MCZ"> selected</cfif>>#encodeForHtml(institution_acronym)#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-8 mb-2 mt-4">
						<input type="checkbox" name="cryo_barcode" id="cryo_barcode" value="true"> <label for="cryo_barcode" class="d-inline">Create "PLACE" barcodes for Cryo Collection</label>
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-3 mb-2">
						<label for="prefix" class="data-entry-label">Unique Identifier Prefix</label>
						<input type="text" name="prefix" id="prefix" class="data-entry-input col-12">
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label for="beginBarcode" class="data-entry-label">Low number in series</label>
						<input type="text" name="beginBarcode" id="beginBarcode" class="data-entry-input reqdClr col-12" required aria-required="true">
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label for="endBarcode" class="data-entry-label">High number in series</label>
						<input type="text" name="endBarcode" id="endBarcode" class="data-entry-input reqdClr col-12" required aria-required="true">
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label for="suffix" class="data-entry-label">Unique Identifier Suffix</label>
						<input type="text" name="suffix" id="suffix" class="data-entry-input col-12">
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-3 mb-2">
						<label for="label_prefix" class="data-entry-label">Label Prefix</label>
						<input type="text" name="label_prefix" id="label_prefix" class="data-entry-input col-12">
					</div>
					<div class="col-12 col-md-6"></div>
					<div class="col-12 col-md-3 mb-2">
						<label for="label_suffix" class="data-entry-label">Label Suffix</label>
						<input type="text" name="label_suffix" id="label_suffix" class="data-entry-input col-12">
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 mb-2">
						<label for="container_type" class="data-entry-label">Container Type</label>
						<select name="container_type" id="container_type" class="data-entry-select reqdClr col-12" required aria-required="true">
							<option value=""></option>
							<cfloop query="ctcontainer_type">
								<option value="#encodeForHtml(container_type)#">#encodeForHtml(container_type)#</option>
							</cfloop>
						</select>
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 mb-2">
						<label for="remarks" class="data-entry-label">Container Remarks (for each container)</label>
						<input type="text" name="remarks" id="remarks" class="data-entry-input col-12" maxlength="1000">
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 mb-2">
						<button type="button" class="btn btn-xs btn-primary" id="createSeriesButton">Create Series</button>
						<button type="button" class="btn btn-xs btn-primary" id="previewSeriesButton">Preview Series</button>
					</div>
				</div>
			</form>
			<output id="createSeriesPreview"></output>
			<output id="createSeriesFeedback"></output>
		</div>
	</section>
</cfoutput>
</main>

<cfoutput>
<script>
	/**
	 * Look up the currently-selected parent container and show its type, and its position/
	 * occupancy status only when it actually declares positions, under the Parent Container
	 * field; shows the "place into empty positions" checkbox only when empty positions exist;
	 * updates the "View" button to link to that container's own details page.
	 *
	 * @return void
	 */
	function refreshParentContainerInfo() {
		var parentContainerId = $.trim($('##parent_container_id').val());
		var infoDiv = $('##createSeriesParentFeedback');
		var positionsRow = $('##placeInPositionsRow');
		var viewBtn = $('##viewParentContainerBtn');
		infoDiv.empty();
		positionsRow.addClass('d-none');
		$('##place_in_positions').prop('checked', false);
		if (!parentContainerId) {
			viewBtn.addClass('d-none');
			return;
		}
		viewBtn.attr('href', '/containers/viewContainer.cfm?container_id=' + encodeURIComponent(parentContainerId)).removeClass('d-none');
		infoDiv.html('<img src="/shared/images/indicator.gif"> Loading container info...');
		$.ajax({
			url: '/containers/component/public.cfc',
			type: 'get',
			dataType: 'json',
			data: {
				method: 'getContainerPositionsGrid',
				returnformat: 'json',
				container_id: parentContainerId
			},
			success: function(resp) {
				// Discard a response for a parent that's no longer selected -- otherwise a slow
				// lookup for an earlier selection can land after a faster one and show stale info.
				if ($.trim($('##parent_container_id').val()) !== parentContainerId) {
					return;
				}
				var infoText = resp.container_type || '';
				var numberPositions = parseInt(resp.number_positions, 10) || 0;
				if (numberPositions > 0) {
					var emptyCount = 0;
					$.each(resp.positions || [], function(i, position) {
						if (!position.content_container_id) {
							emptyCount++;
						}
					});
					infoText += (infoText ? '. ' : '') + numberPositions + ' position(s) declared, ' + emptyCount + ' empty.';
					if (emptyCount > 0) {
						$('##placeInPositionsHint').text('Up to ' + emptyCount + ' empty position(s) available.');
						positionsRow.removeClass('d-none');
					}
				}
				infoDiv.text(infoText);
			},
			error: function() {
				if ($.trim($('##parent_container_id').val()) !== parentContainerId) {
					return;
				}
				infoDiv.text('Unable to load container info.');
			}
		});
	}

	/**
	 * Enable/disable the Unique Identifier Prefix/Suffix inputs based on whether "Create PLACE
	 * barcodes for Cryo Collection" is checked -- both are ignored server-side in PLACE mode.
	 *
	 * @return void
	 */
	function updateCryoBarcodeFieldState() {
		var isCryo = $('##cryo_barcode').is(':checked');
		$('##prefix').prop('disabled', isCryo);
		$('##suffix').prop('disabled', isCryo);
	}

	$(document).ready(function() {
		makeContainerAutocompleteMetaExcludeCO('parent_container', 'parent_container_id');
		$('##parent_container').on('autocompleteselect autocompletechange', function() {
			// allow the autocomplete widget's own select/change handlers to populate parent_container_id first.
			window.setTimeout(refreshParentContainerInfo, 10);
		});
		$('##chooseParentContainerBtn').on('click', function() {
			openContainerPickerDialog({
				mode: 'find',
				dialogTitle: 'Select Parent Container',
				onSelect: function(selectedId, selectedLabel, wrapper) {
					$('##parent_container_id').val(selectedId);
					$('##parent_container').val(selectedLabel);
					wrapper.dialog('close');
					refreshParentContainerInfo();
				}
			});
		});
		$('##cryo_barcode').on('change', updateCryoBarcodeFieldState);
		updateCryoBarcodeFieldState();
		$('##previewSeriesButton').on('click', function() {
			// TODO: Create preview of first and last barcodes in series, display in createSeriesPreview.
			var feedback = $('##createSeriesFeedback');
			feedback.empty();
			var previewoutput = $('##createSeriesPreview');
			previewoutput.empty();

			var parentContainerId = $.trim($('##parent_container_id').val());
			var beginBarcode = $.trim($('##beginBarcode').val());
			var endBarcode = $.trim($('##endBarcode').val());
			var containerType = $.trim($('##container_type').val());

			if (!parentContainerId) {
				feedback.append($('<div class="alert alert-danger py-1 px-2 small mb-0"></div>').text('Select a Parent Container for the new series.'));
				return;
			}
			if (!containerType) {
				feedback.append($('<div class="alert alert-danger py-1 px-2 small mb-0"></div>').text('Select a Container Type.'));
				return;
			}
			if (!/^[0-9]+$/.test(beginBarcode) || !/^[0-9]+$/.test(endBarcode)) {
				feedback.append($('<div class="alert alert-danger py-1 px-2 small mb-0"></div>').text('Low and High number in series must both be whole numbers.'));
				return;
			}

			var sendPreview = function(confirmLargeBatch, confirmAbnormalBatch) {
				previewoutput.html('<div class="text-center my-2"><img src="/shared/images/indicator.gif"> Previewing...</div>');
				$.ajax({
					url: '/containers/component/functions.cfc',
					type: 'post',
					dataType: 'json',
					data: {
						method: 'createContainerSeries',
						returnformat: 'json',
						parent_container_id: parentContainerId,
						container_type: containerType,
						institution_acronym: $('##institution_acronym').val(),
						cryo_barcode: $('##cryo_barcode').is(':checked'),
						prefix: $('##prefix').val(),
						suffix: $('##suffix').val(),
						label_prefix: $('##label_prefix').val(),
						label_suffix: $('##label_suffix').val(),
						remarks: $('##remarks').val(),
						begin_barcode: beginBarcode,
						end_barcode: endBarcode,
						place_in_positions: $('##place_in_positions').is(':checked'),
						dry_run: "true",
						confirm_large_batch: !!confirmLargeBatch,
						confirm_abnormal_batch: !!confirmAbnormalBatch
					},
					success: function(resp) {
						if (resp.status === 'confirm_large_batch' || resp.status === 'confirm_abnormal_batch') {
							previewoutput.empty();
							var title = resp.status === 'confirm_abnormal_batch' ? 'Abnormally Large Batch' : 'Large Batch';
							confirmDialog(resp.message, title, function() {
								sendPreview(resp.status === 'confirm_large_batch' || confirmLargeBatch, resp.status === 'confirm_abnormal_batch' || confirmAbnormalBatch);
							});
							return;
						}
						feedback.empty();
						previewoutput.empty();
						if (resp.status === 'created') {
							var parentLink = $('<a target="_blank"></a>')
								.attr('href', '/containers/Containers.cfm?barcode=' + encodeURIComponent('=' + resp.parent_barcode) + '&execute=true')
								.text(resp.parent_label);
							var successBox = $('<div class="alert alert-success py-2 px-2 small mb-2"></div>')
								.append($('<div></div>').text('Would Create ' + resp.count + ' container(s), from ' + resp.first_barcode + ' to ' + resp.last_barcode + '.'));
							if (resp.placed_in_positions) {
								successBox.append($('<div></div>').text('Would place into positions ' + resp.first_position_label + ' through ' + resp.last_position_label + ' of: ').append(parentLink));
							} else {
								successBox.append($('<div></div>').text('Would Create as children of Parent Container: ').append(parentLink));
							}
							previewoutput.append(successBox);
						} else {
							previewoutput.append($('<div class="alert alert-danger py-1 px-2 small mb-0"></div>').text(resp.message || 'Preview: Unable to create container records.'));
						}
					},
					error: function(jqXHR, textStatus, error) {
						$('##createSeriesButton').prop('disabled', false);
						previewoutput.empty();
						handleFail(jqXHR, textStatus, error, 'previewing a container series');
					}
				});
			};
			sendPreview(false, false);
		});

		$('##createSeriesButton').on('click', function() {
			var feedback = $('##createSeriesFeedback');
			feedback.empty();

			var parentContainerId = $.trim($('##parent_container_id').val());
			var beginBarcode = $.trim($('##beginBarcode').val());
			var endBarcode = $.trim($('##endBarcode').val());
			var containerType = $.trim($('##container_type').val());

			if (!parentContainerId) {
				feedback.append($('<div class="alert alert-danger py-1 px-2 small mb-0"></div>').text('Select a Parent Container for the new series.'));
				return;
			}
			if (!containerType) {
				feedback.append($('<div class="alert alert-danger py-1 px-2 small mb-0"></div>').text('Select a Container Type.'));
				return;
			}
			if (!/^[0-9]+$/.test(beginBarcode) || !/^[0-9]+$/.test(endBarcode)) {
				feedback.append($('<div class="alert alert-danger py-1 px-2 small mb-0"></div>').text('Low and High number in series must both be whole numbers.'));
				return;
			}

			$('##createSeriesButton').prop('disabled', true);

			var sendCreate = function(confirmLargeBatch, confirmAbnormalBatch) {
				feedback.html('<div class="text-center my-2"><img src="/shared/images/indicator.gif"> Creating...</div>');
				$.ajax({
					url: '/containers/component/functions.cfc',
					type: 'post',
					dataType: 'json',
					data: {
						method: 'createContainerSeries',
						returnformat: 'json',
						parent_container_id: parentContainerId,
						container_type: containerType,
						institution_acronym: $('##institution_acronym').val(),
						cryo_barcode: $('##cryo_barcode').is(':checked'),
						prefix: $('##prefix').val(),
						suffix: $('##suffix').val(),
						label_prefix: $('##label_prefix').val(),
						label_suffix: $('##label_suffix').val(),
						remarks: $('##remarks').val(),
						begin_barcode: beginBarcode,
						end_barcode: endBarcode,
						place_in_positions: $('##place_in_positions').is(':checked'),
						confirm_large_batch: !!confirmLargeBatch,
						confirm_abnormal_batch: !!confirmAbnormalBatch
					},
					success: function(resp) {
						if (resp.status === 'confirm_large_batch' || resp.status === 'confirm_abnormal_batch') {
							feedback.empty();
							var title = resp.status === 'confirm_abnormal_batch' ? 'Abnormally Large Batch' : 'Large Batch';
							confirmDialog(resp.message, title, function() {
								sendCreate(resp.status === 'confirm_large_batch' || confirmLargeBatch, resp.status === 'confirm_abnormal_batch' || confirmAbnormalBatch);
							}, function() {
								$('##createSeriesButton').prop('disabled', false);
							});
							return;
						}
						$('##createSeriesButton').prop('disabled', false);
						feedback.empty();
						if (resp.status === 'created') {
							var parentLink = $('<a target="_blank"></a>')
								.attr('href', '/containers/Containers.cfm?barcode=' + encodeURIComponent('=' + resp.parent_barcode) + '&execute=true')
								.text(resp.parent_label);
							var successBox = $('<div class="alert alert-success py-2 px-2 small mb-2"></div>')
								.append($('<div></div>').text('Created ' + resp.count + ' container(s), from ' + resp.first_barcode + ' to ' + resp.last_barcode + '.'));
							if (resp.placed_in_positions) {
								successBox.append($('<div></div>').text('Placed into positions ' + resp.first_position_label + ' through ' + resp.last_position_label + ' of: ').append(parentLink));
							} else {
								successBox.append($('<div></div>').text('Created as children of Parent Container: ').append(parentLink));
							}
							feedback.append(successBox);
						} else {
							feedback.append($('<div class="alert alert-danger py-1 px-2 small mb-0"></div>').text(resp.message || 'Unable to create container records.'));
						}
					},
					error: function(jqXHR, textStatus, error) {
						$('##createSeriesButton').prop('disabled', false);
						feedback.empty();
						handleFail(jqXHR, textStatus, error, 'creating a container series');
					}
				});
			};
			sendCreate(false, false);
		});
	});
</script>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
