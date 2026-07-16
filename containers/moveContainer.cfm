<!---
/containers/moveContainer.cfm

Rapid-scan page for moving a container into a parent container by barcode.

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
<cf_rolecheck>
<cfparam name="url.action" default="">
<cfparam name="url.child_barcode" default="">
<cfparam name="url.parent_barcode" default="">

<cfset pageTitle = "Move Container">
<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">

<main id="content" class="container py-3">
	<cfoutput>
	<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="moveContainerHeading">
		<div class="col-12">
			<h1 class="h2 ml-1 mb-1" id="moveContainerHeading">Move Container</h1>
			<p class="small text-muted">Scan or enter a parent container barcode and child container barcode, then confirm the move.</p>
			<form class="col-12 px-0" id="moveContainerForm" name="moveContainerForm" method="post" novalidate onsubmit="return false;">
				<div class="form-row">
					<div class="col-12 col-md-6 col-xl-4 mb-2">
						<label for="parent_barcode" class="data-entry-label">Parent Unique Identifier</label>
						<input type="text" name="parent_barcode" id="parent_barcode" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(url.parent_barcode)#">
					</div>
					<div class="col-12 col-md-6 col-xl-4 mb-2">
						<label for="child_barcode" class="data-entry-label">Child Unique Identifier</label>
						<input type="text" name="child_barcode" id="child_barcode" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(url.child_barcode)#">
					</div>
					<div class="col-12 col-md-6 col-xl-4 mb-2">
						<label for="move_timestamp" class="data-entry-label">Timestamp (optional)</label>
						<input type="text" name="move_timestamp" id="move_timestamp" class="data-entry-input col-12" placeholder="yyyy-mm-dd HH:mm:ss">
					</div>
				</div>
				<div class="form-row mb-2">
					<div class="col-12">
						<button type="button" class="btn btn-xs btn-primary" id="moveContainerSubmit">Move Container</button>
						<button type="button" class="btn btn-xs btn-secondary ml-1" id="moveContainerNow">Set Timestamp to Now</button>
						<button type="reset" class="btn btn-xs btn-warning ml-1" id="moveContainerClear">Clear Form</button>
						<label class="ml-3 mb-0 small" for="moveContainerAutoSubmit">
							<input type="checkbox" id="moveContainerAutoSubmit"> Submit on Child Change
						</label>
						<output id="moveContainerStatus" class="ml-2" aria-live="polite"></output>
					</div>
				</div>
			</form>
		</div>
	</section>

	<section class="mb-4" aria-labelledby="moveContainerResultsHeading">
		<div class="d-flex align-items-center flex-wrap mb-2">
			<h2 class="h4 mb-0 mr-2" id="moveContainerResultsHeading">Move Log</h2>
			<span class="badge badge-light border" id="moveContainerCounter">0 moved</span>
		</div>
		<div id="moveContainerResultList"></div>
	</section>
	</cfoutput>
</main>

<script>
	function formatMoveResultContainer(label, barcode) {
		var display = barcode || label || 'Unnamed container';
		if (barcode && label && barcode !== label) {
			display = barcode + ' (' + label + ')';
		}
		return display;
	}

	function appendMoveResult(cssClass, messageHtml) {
		var container = $('#moveContainerResultList');
		var item = $('<div></div>').addClass('alert ' + cssClass + ' py-1 px-2 small mb-1').html(messageHtml);
		container.prepend(item);
	}

	function setTimestampToNow() {
		var now = new Date();
		var month = String(now.getMonth() + 1).padStart(2, '0');
		var day = String(now.getDate()).padStart(2, '0');
		var hour = String(now.getHours()).padStart(2, '0');
		var min = String(now.getMinutes()).padStart(2, '0');
		$('#move_timestamp').val(now.getFullYear() + '-' + month + '-' + day + ' ' + hour + ':' + min + ':00');
	}

	function submitMoveContainer() {
		var parentBarcode = $.trim($('#parent_barcode').val());
		var childBarcode = $.trim($('#child_barcode').val());
		var moveTimestamp = $.trim($('#move_timestamp').val());
		if (!parentBarcode || !childBarcode) {
			setFeedbackControlState('moveContainerStatus', 'error', 'Parent and child barcodes are required.');
			return;
		}
		setFeedbackControlState('moveContainerStatus', 'saving', 'Moving...');
		$('#moveContainerSubmit').prop('disabled', true);
		$.ajax({
			url: '/containers/component/functions.cfc',
			type: 'post',
			dataType: 'json',
			data: {
				method: 'moveContainerByBarcode',
				returnformat: 'json',
				child_barcode: childBarcode,
				parent_barcode: parentBarcode,
				move_timestamp: moveTimestamp
			},
			success: function(result) {
				$('#moveContainerSubmit').prop('disabled', false);
				if (result.status === 'moved') {
					var childDisplay = formatMoveResultContainer(result.child_label, childBarcode);
					var parentDisplay = formatMoveResultContainer(result.parent_label, parentBarcode);
					appendMoveResult('alert-success', 'Moved <strong>' + $('<div>').text(childDisplay).html() + '</strong> into <strong>' + $('<div>').text(parentDisplay).html() + '</strong>.');
					var movedCount = parseInt($('#moveContainerCounter').text(), 10) || 0;
					$('#moveContainerCounter').text((movedCount + 1) + ' moved');
					setFeedbackControlState('moveContainerStatus', 'saved', 'Move recorded.');
					$('#child_barcode').val('').focus();
				} else if (result.status === 'notfound') {
					appendMoveResult('alert-danger', $('<div>').text(result.message || 'Container was not found.').html());
					setFeedbackControlState('moveContainerStatus', 'error', result.message || 'Container was not found.');
				} else {
					appendMoveResult('alert-danger', $('<div>').text(result.message || 'Move failed.').html());
					setFeedbackControlState('moveContainerStatus', 'error', result.message || 'Move failed.');
				}
			},
			error: function(jqXHR, textStatus, error) {
				$('#moveContainerSubmit').prop('disabled', false);
				setFeedbackControlState('moveContainerStatus', 'error', 'Move failed.');
				handleFail(jqXHR, textStatus, error, 'moving container by barcode');
			}
		});
	}

	$(document).ready(function() {
		$('#move_timestamp').datepicker({ dateFormat: 'yy-mm-dd' });
		$('#moveContainerSubmit').on('click', submitMoveContainer);
		$('#moveContainerNow').on('click', setTimestampToNow);
		$('#child_barcode').on('change', function() {
			if ($('#moveContainerAutoSubmit').prop('checked')) {
				submitMoveContainer();
			}
		});
		setTimestampToNow();
		if ($.trim($('#child_barcode').val()).length > 0 && $.trim($('#parent_barcode').val()).length > 0) {
			submitMoveContainer();
		}
	});
</script>

<cfinclude template="/shared/_footer.cfm">
