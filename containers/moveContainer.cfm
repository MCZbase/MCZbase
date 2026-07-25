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
<cfparam name="url.barcode_scanner_mode" default="0">
<cfset variables.scannerModeParam = lcase(trim(url.barcode_scanner_mode))>
<cfset variables.scannerModeEnabled = listFindNoCase("1,true,yes,on", variables.scannerModeParam) GT 0>

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
					<div class="col-12 col-md-6 col-l-5 col-xl-5 mb-2">
						<label for="parent_barcode" class="data-entry-label">Parent Unique Identifier</label>
						<div class="container-picker-row d-flex align-items-center form-row">
							<div class="col-12 col-md-8 col-lg-9 pr-md-0 move-container-input-wrap">
								<input type="text" name="parent_barcode" id="parent_barcode" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(url.parent_barcode)#">
							</div>
							<div class="col-12 col-md-4 col-lg-3 pl-md-0 mt-1 mt-md-0 move-container-chooser">
								<button type="button" id="chooseParentContainerBtn" class="btn btn-xs btn-secondary ml-1">Choose Parent</button>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-6 col-l-5 col-xl-5 mb-2">
						<label for="child_barcode" class="data-entry-label">Child Unique Identifier</label>
						<div class="container-picker-row d-flex align-items-center form-row">
							<div class="col-12 col-md-8 col-lg-9 pr-md-0 move-container-input-wrap">
								<input type="text" name="child_barcode" id="child_barcode" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(url.child_barcode)#">
							</div>
							<div class="col-12 col-md-4 col-lg-3 pl-md-0 mt-1 mt-md-0 move-container-chooser">
								<button type="button" id="chooseChildContainerBtn" class="btn btn-xs btn-secondary ml-1">Choose Child</button>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-6 col-l-2 col-xl-2 mb-2">
						<label for="move_timestamp" class="data-entry-label">Timestamp (optional)</label>
						<input type="text" name="move_timestamp" id="move_timestamp" class="data-entry-input col-12" aria-describedby="moveTimestampHelp" placeholder="yyyy-mm-dd HH:mm:ss">
						<small id="moveTimestampHelp" class="text-muted">Format: yyyy-mm-dd HH:mm:ss</small>
					</div>
				</div>
				<div class="form-row mb-2">
					<div class="col-12">
						<button type="button" class="btn btn-xs btn-primary" id="moveContainerSubmit">Move Container</button>
						<button type="button" class="btn btn-xs btn-secondary ml-1" id="moveContainerNow">Set Timestamp to Now</button>
						<button type="reset" class="btn btn-xs btn-warning ml-1" id="moveContainerClear">Clear Form</button>
						<label class="ml-3 mb-0 small" for="moveContainerScannerMode">
							<input type="checkbox" id="moveContainerScannerMode"<cfif variables.scannerModeEnabled> checked</cfif>> Barcode Scanner Mode
						</label>
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
			<span class="badge badge-light border" id="moveContainerCounter" data-count="0">0 moved</span>
		</div>
		<div id="moveContainerResultList"></div>
	</section>
	</cfoutput>
</main>

<script>
	function appendMoveResult(cssClass, messageHtml) {
		var container = $('#moveContainerResultList');
		var item = $('<div></div>').addClass('alert ' + cssClass + ' py-1 px-2 small mb-1').html(messageHtml);
		container.prepend(item);
	}

	/** Join placement validation messages into a single sentence.
	 * @param {Array<string>} messages - warning or block messages from placement validation.
	 * @returns {string} space-separated non-empty message text.
	 */
	function joinPlacementMessages(messages) {
		var cleanMessages = [];
		$.each(messages || [], function(i, message) {
			var text = $.trim(message || '');
			if (text.length > 0) {
				cleanMessages.push(text);
			}
		});
		return cleanMessages.join(' ');
	}

	/** Build warning-confirmation dialog markup for a preflight warning result.
	 * @param {Object} preflight - response from preflightMoveContainerByBarcode.
	 * @param {string} childDisplay - formatted child container display text.
	 * @param {string} parentDisplay - formatted parent container display text.
	 * @returns {string} html to show in confirmDialog.
	 */
	function buildPlacementWarningDialogText(preflight, childDisplay, parentDisplay) {
		var warningList = $('<ul class="pl-3 mb-2"></ul>');
		$.each(preflight.warnings || [], function(i, warning) {
			warningList.append($('<li></li>').text(warning));
		});
		var warningListHtml = $('<div></div>').append(warningList).html();
		return '<p>Place <strong>' + $('<div>').text(childDisplay).html() + '</strong> into <strong>' + $('<div>').text(parentDisplay).html() + '</strong>?</p>'
			+ warningListHtml
			+ '<p class="mb-0">Proceed with this move?</p>';
	}

	function setTimestampToNow() {
		var now = new Date();
		var month = String(now.getMonth() + 1).padStart(2, '0');
		var day = String(now.getDate()).padStart(2, '0');
		var hour = String(now.getHours()).padStart(2, '0');
		var min = String(now.getMinutes()).padStart(2, '0');
		$('#move_timestamp').val(now.getFullYear() + '-' + month + '-' + day + ' ' + hour + ':' + min + ':00');
	}

	/** Toggle barcode scanner mode behavior.
	 * @param {boolean} isScannerMode - true hides picker buttons and forces submit-on-child-change checked; false shows picker buttons and forces submit-on-child-change unchecked.
	 * @returns {void}
	 */
	function applyBarcodeScannerModeState(isScannerMode) {
		isScannerMode = !!isScannerMode;
		var timestampInput = $('#move_timestamp');
		$('.move-container-chooser').toggle(!isScannerMode);
		$('.move-container-input-wrap').toggleClass('col-md-12 col-lg-12', isScannerMode).toggleClass('col-md-8 col-lg-9', !isScannerMode);
		if (isScannerMode) {
			timestampInput.val('');
		}
		timestampInput.prop('disabled', isScannerMode);
		$('#moveContainerNow').prop('disabled', isScannerMode);
		$('#moveContainerAutoSubmit').prop('checked', isScannerMode);
	}

	/** Execute a barcode move after preflight has approved or warning-confirmed it.
	 * @param {string} parentBarcode - destination parent container barcode.
	 * @param {string} childBarcode - child container barcode being moved.
	 * @param {string} moveTimestamp - optional move timestamp.
	 * @returns {void}
	 */
	function executeMoveContainer(parentBarcode, childBarcode, moveTimestamp) {
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
					var childDisplay = formatContainerDisplay(childBarcode, result.child_label);
					var parentDisplay = formatContainerDisplay(parentBarcode, result.parent_label);
					appendMoveResult('alert-success', 'Moved <strong>' + $('<div>').text(childDisplay).html() + '</strong> into <strong>' + $('<div>').text(parentDisplay).html() + '</strong>.');
					var movedCount = parseInt($('#moveContainerCounter').data('count'), 10) || 0;
					var nextCount = movedCount + 1;
					$('#moveContainerCounter').data('count', nextCount).text(nextCount + ' moved');
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

	/** Run barcode-based preflight validation and handle allow/warn/block outcomes.
	 * @param {string} parentBarcode - destination parent container barcode.
	 * @param {string} childBarcode - child container barcode being moved.
	 * @param {string} moveTimestamp - optional move timestamp passed through on move.
	 * @returns {void}
	 */
	function runMoveContainerPreflight(parentBarcode, childBarcode, moveTimestamp) {
		setFeedbackControlState('moveContainerStatus', 'saving', 'Checking placement...');
		$('#moveContainerSubmit').prop('disabled', true);
		$.ajax({
			url: '/containers/component/functions.cfc',
			type: 'get',
			dataType: 'json',
			data: {
				method: 'preflightMoveContainerByBarcode',
				returnformat: 'json',
				child_barcode: childBarcode,
				parent_barcode: parentBarcode
			},
			success: function(preflight) {
				if (!preflight || preflight.status === 'error') {
					var errorMessage = (preflight && preflight.message) ? preflight.message : 'Unable to validate placement.';
					appendMoveResult('alert-danger', $('<div>').text(errorMessage).html());
					setFeedbackControlState('moveContainerStatus', 'error', errorMessage);
					$('#moveContainerSubmit').prop('disabled', false);
					return;
				}
				if (preflight.status === 'notfound') {
					appendMoveResult('alert-danger', $('<div>').text(preflight.message || 'Container was not found.').html());
					setFeedbackControlState('moveContainerStatus', 'error', preflight.message || 'Container was not found.');
					$('#moveContainerSubmit').prop('disabled', false);
					return;
				}
				if (preflight.allowed !== true) {
					var blockedMessage = joinPlacementMessages(preflight.blocks) || 'Placement is not allowed.';
					appendMoveResult('alert-danger', $('<div>').text(blockedMessage).html());
					setFeedbackControlState('moveContainerStatus', 'error', blockedMessage);
					messageDialog(blockedMessage, 'Placement Not Allowed');
					$('#moveContainerSubmit').prop('disabled', false);
					return;
				}
				if (preflight.severity === 'warn') {
					var childDisplay = formatContainerDisplay(childBarcode, preflight.child_label);
					var parentDisplay = formatContainerDisplay(parentBarcode, preflight.parent_label);
					var warningDialogText = buildPlacementWarningDialogText(preflight, childDisplay, parentDisplay);
					setFeedbackControlState('moveContainerStatus', 'warning', 'Placement warning requires confirmation.');
					$('#moveContainerSubmit').prop('disabled', false);
					confirmDialog(warningDialogText, 'Placement Warning', function() {
						executeMoveContainer(parentBarcode, childBarcode, moveTimestamp);
					});
					return;
				}
				executeMoveContainer(parentBarcode, childBarcode, moveTimestamp);
			},
			error: function(jqXHR, textStatus, error) {
				$('#moveContainerSubmit').prop('disabled', false);
				setFeedbackControlState('moveContainerStatus', 'error', 'Unable to validate placement.');
				handleFail(jqXHR, textStatus, error, 'validating move container placement');
			}
		});
	}

	/** Validate required fields and begin preflight validation for a move.
	 * @returns {void}
	 */
	function submitMoveContainer() {
		var parentBarcode = $.trim($('#parent_barcode').val());
		var childBarcode = $.trim($('#child_barcode').val());
		var moveTimestamp = $.trim($('#move_timestamp').val());
		if (!parentBarcode || !childBarcode) {
			setFeedbackControlState('moveContainerStatus', 'error', 'Parent and child barcodes are required.');
			return;
		}
		runMoveContainerPreflight(parentBarcode, childBarcode, moveTimestamp);
	}

	/** Copy selected container identifier into a move barcode input.
	 * @param {string} targetInputId - input control id to populate.
	 * @param {Object} selectedItem - selected autocomplete item containing barcode and label keys.
	 * @param {string} selectedLabel - selected text fallback from autocomplete.
	 * @returns {void}
	 */
	function applyPickedContainerToMoveInput(targetInputId, selectedItem, selectedLabel) {
		var barcode = $.trim((selectedItem && selectedItem.barcode) ? selectedItem.barcode : '');
		var label = $.trim((selectedItem && selectedItem.label) ? selectedItem.label : '');
		var valueToSet = barcode || label || $.trim(selectedLabel || '');
		$('#' + targetInputId).val(valueToSet).trigger('change').focus();
	}

	$(document).ready(function() {
		$('#move_timestamp').datepicker({ dateFormat: 'yy-mm-dd' });
		$('#moveContainerSubmit').on('click', submitMoveContainer);
		$('#moveContainerNow').on('click', setTimestampToNow);
		$('#chooseParentContainerBtn').on('click', function() {
			openContainerPickerDialog({
				mode: 'find',
				dialogTitle: 'Select Parent Container',
				onSelect: function(selectedId, selectedLabel, wrapper, controls, selectedItem) {
					applyPickedContainerToMoveInput('parent_barcode', selectedItem, selectedLabel);
					wrapper.dialog('close');
				}
			});
		});
		$('#chooseChildContainerBtn').on('click', function() {
			openContainerPickerDialog({
				mode: 'find',
				dialogTitle: 'Select Child Container',
				onSelect: function(selectedId, selectedLabel, wrapper, controls, selectedItem) {
					applyPickedContainerToMoveInput('child_barcode', selectedItem, selectedLabel);
					wrapper.dialog('close');
				}
			});
		});
		$('#child_barcode').on('change', function() {
			if ($('#moveContainerAutoSubmit').prop('checked')) {
				submitMoveContainer();
			}
		});
		$('#moveContainerScannerMode').on('change', function() {
			applyBarcodeScannerModeState($(this).prop('checked'));
		});
		$('#moveContainerForm').on('reset', function() {
			var updateScannerState = function() {
				applyBarcodeScannerModeState($('#moveContainerScannerMode').prop('checked'));
			};
			if (window.requestAnimationFrame) {
				window.requestAnimationFrame(updateScannerState);
			} else {
				updateScannerState();
			}
		});
		setTimestampToNow();
		applyBarcodeScannerModeState($('#moveContainerScannerMode').prop('checked'));
		if ($.trim($('#child_barcode').val()).length > 0 && $.trim($('#parent_barcode').val()).length > 0) {
			submitMoveContainer();
		}
	});
</script>

<cfinclude template="/shared/_footer.cfm">
