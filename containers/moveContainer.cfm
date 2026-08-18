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
<cfparam name="url.batch_mode" default="0">
<cfset variables.scannerModeParam = lcase(trim(url.barcode_scanner_mode))>
<cfset variables.scannerModeEnabled = listFindNoCase("1,true,yes,on", variables.scannerModeParam) GT 0>
<cfset variables.batchModeParam = lcase(trim(url.batch_mode))>
<cfset variables.batchModeEnabled = listFindNoCase("1,true,yes,on", variables.batchModeParam) GT 0>
<cfif variables.batchModeEnabled>
	<!--- batch mode and scanner mode are mutually exclusive in the UI; batch mode wins if both are requested --->
	<cfset variables.scannerModeEnabled = false>
</cfif>

<cfset pageTitle = "Move Container">
<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">

<main id="content" class="container py-3">
	<cfoutput>
	<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="moveContainerHeading">
		<div class="col-12">
			<h1 class="h2 ml-1 mb-1" id="moveContainerHeading">Move Container</h1>
			<p class="small text-muted">Scan or enter a parent container barcode and child container barcode, then confirm the move. Use Batch Mode to move a list of children into one parent at once.</p>
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
					<div class="col-12 col-md-6 col-l-5 col-xl-5 mb-2" id="moveContainerSingleChildWrap">
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
				<div class="form-row mb-2" id="moveContainerBatchWrap" style="display:none;">
					<div class="col-12">
						<label for="batch_child_barcodes" class="data-entry-label">Child Unique Identifiers (one per line, or separated by commas)</label>
						<textarea name="batch_child_barcodes" id="batch_child_barcodes" class="data-entry-input col-12 col-md-8 col-lg-6" rows="6" aria-describedby="batchChildBarcodesHelp"></textarea>
						<small id="batchChildBarcodesHelp" class="text-muted d-block">Each valid barcode is moved into the parent above. Placements needing a warning confirmation, or that fail, are skipped and reported below rather than moved automatically &mdash; use the single-move fields above to resolve those.</small>
						<button type="button" class="btn btn-xs btn-primary mt-1" id="moveContainerBatchSubmit">Move All</button>
					</div>
				</div>
				<div class="form-row mb-2">
					<div class="col-12">
						<button type="button" class="btn btn-xs btn-primary" id="moveContainerSubmit">Move Container</button>
						<button type="button" class="btn btn-xs btn-secondary ml-1" id="moveContainerNow">Set Timestamp to Now</button>
						<button type="reset" class="btn btn-xs btn-warning ml-1" id="moveContainerClear">Clear Form</button>
						<span class="ml-3">
							<input type="checkbox" id="moveContainerScannerMode"<cfif variables.scannerModeEnabled> checked</cfif>>
							<label class="mb-0 small d-inline" for="moveContainerScannerMode">Barcode Scanner Mode</label>
						</span>
						<span class="ml-3">
							<input type="checkbox" id="moveContainerAutoSubmit">
							<label class="mb-0 small d-inline" for="moveContainerAutoSubmit">Submit on Child Change</label>
						</span>
						<span class="ml-3">
							<input type="checkbox" id="moveContainerBatchMode"<cfif variables.batchModeEnabled> checked</cfif>>
							<label class="mb-0 small d-inline" for="moveContainerBatchMode">Batch Mode (Multiple Children)</label>
						</span>
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
		$('#moveContainerBatchMode').prop('disabled', isScannerMode);
	}

	/** Toggle batch mode behavior: swap the single child-barcode field for a multi-line list, and
	 * disable barcode scanner mode's per-scan auto-submit while a batch is being composed.
	 * @param {boolean} isBatchMode - true shows the batch textarea and Move All button in place of the single child field.
	 * @returns {void}
	 */
	function applyBatchModeState(isBatchMode) {
		isBatchMode = !!isBatchMode;
		$('#moveContainerSingleChildWrap').toggle(!isBatchMode);
		$('#moveContainerBatchWrap').toggle(isBatchMode);
		$('#moveContainerSubmit').prop('disabled', isBatchMode);
		$('#moveContainerScannerMode').prop('disabled', isBatchMode);
		if (isBatchMode) {
			$('#moveContainerAutoSubmit').prop('checked', false);
		}
	}

	/** Execute a barcode move after preflight has approved or warning-confirmed it.
	 * @param {string} parentBarcode - destination parent container barcode.
	 * @param {string} childBarcode - child container barcode being moved.
	 * @param {string} moveTimestamp - optional move timestamp.
	 * @param {function(string):void} [onComplete] - when given, called with the outcome status ('moved'|'notfound'|'failed') instead of
	 *   focusing the single child-barcode field, so a batch queue can chain to the next item.
	 * @returns {void}
	 */
	function executeMoveContainer(parentBarcode, childBarcode, moveTimestamp, onComplete) {
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
					if (onComplete) { onComplete('moved'); } else { $('#child_barcode').val('').focus(); }
				} else if (result.status === 'notfound') {
					appendMoveResult('alert-danger', $('<div>').text(result.message || 'Container was not found.').html());
					setFeedbackControlState('moveContainerStatus', 'error', result.message || 'Container was not found.');
					if (onComplete) { onComplete('notfound'); }
				} else {
					appendMoveResult('alert-danger', $('<div>').text(result.message || 'Move failed.').html());
					setFeedbackControlState('moveContainerStatus', 'error', result.message || 'Move failed.');
					if (onComplete) { onComplete('failed'); }
				}
			},
			error: function(jqXHR, textStatus, error) {
				$('#moveContainerSubmit').prop('disabled', false);
				setFeedbackControlState('moveContainerStatus', 'error', 'Move failed.');
				handleFail(jqXHR, textStatus, error, 'moving container by barcode');
				if (onComplete) { onComplete('failed'); }
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

	/** Split batch textarea input into a list of non-empty barcodes, one per line or comma-separated.
	 * @param {string} rawText - raw contents of the batch child-barcodes textarea.
	 * @returns {Array<string>} trimmed, non-empty barcodes in entry order.
	 */
	function parseBatchChildBarcodes(rawText) {
		var pieces = String(rawText || '').split(/[\r\n,]+/);
		var barcodes = [];
		$.each(pieces, function(i, piece) {
			var trimmed = $.trim(piece);
			if (trimmed.length > 0) {
				barcodes.push(trimmed);
			}
		});
		return barcodes;
	}

	/** Run preflight for one barcode in a batch queue and either execute the move or skip it.
	 * Unlike runMoveContainerPreflight, this never opens a confirm dialog: an unattended batch
	 * treats anything needing a warning confirmation as skipped-for-manual-review, so a long list
	 * doesn't stack up modal dialogs waiting on the user.
	 * @param {string} parentBarcode - destination parent container barcode.
	 * @param {string} childBarcode - child container barcode being moved.
	 * @param {string} moveTimestamp - optional move timestamp passed through on move.
	 * @param {function(string):void} onComplete - called with 'moved', 'skipped', or 'failed' when this item is done.
	 * @returns {void}
	 */
	function runBatchMovePreflight(parentBarcode, childBarcode, moveTimestamp, onComplete) {
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
					appendMoveResult('alert-danger', $('<div>').text(childBarcode + ': ' + ((preflight && preflight.message) ? preflight.message : 'Unable to validate placement.')).html());
					onComplete('failed');
					return;
				}
				if (preflight.status === 'notfound') {
					appendMoveResult('alert-danger', $('<div>').text(childBarcode + ': ' + (preflight.message || 'Container was not found.')).html());
					onComplete('skipped');
					return;
				}
				if (preflight.allowed !== true) {
					var blockedMessage = joinPlacementMessages(preflight.blocks) || 'Placement is not allowed.';
					appendMoveResult('alert-danger', $('<div>').text(childBarcode + ': ' + blockedMessage).html());
					onComplete('skipped');
					return;
				}
				if (preflight.severity === 'warn') {
					var warningMessage = joinPlacementMessages(preflight.warnings) || 'Needs a warning confirmation.';
					appendMoveResult('alert-warning', $('<div>').text(childBarcode + ': skipped, ' + warningMessage + ' Use the single-move fields above to confirm.').html());
					onComplete('skipped');
					return;
				}
				executeMoveContainer(parentBarcode, childBarcode, moveTimestamp, onComplete);
			},
			error: function(jqXHR, textStatus, error) {
				handleFail(jqXHR, textStatus, error, 'validating batch move container placement');
				onComplete('failed');
			}
		});
	}

	/** Process a list of child barcodes sequentially against one parent container.
	 * @param {string} parentBarcode - destination parent container barcode.
	 * @param {Array<string>} childBarcodes - child barcodes to move, in order.
	 * @param {string} moveTimestamp - optional move timestamp applied to every successful move.
	 * @returns {void}
	 */
	function processBatchMoveQueue(parentBarcode, childBarcodes, moveTimestamp) {
		var total = childBarcodes.length;
		var counts = { moved: 0, skipped: 0, failed: 0 };
		$('#moveContainerBatchSubmit').prop('disabled', true);
		function advance(index) {
			if (index >= total) {
				appendMoveResult('alert-info', 'Batch complete: ' + counts.moved + ' moved, ' + counts.skipped + ' skipped, ' + counts.failed + ' failed.');
				setFeedbackControlState('moveContainerStatus', (counts.failed > 0 || counts.skipped > 0) ? 'warning' : 'saved', 'Batch complete.');
				$('#moveContainerBatchSubmit').prop('disabled', false);
				return;
			}
			setFeedbackControlState('moveContainerStatus', 'saving', 'Processing ' + (index + 1) + ' of ' + total + '...');
			runBatchMovePreflight(parentBarcode, childBarcodes[index], moveTimestamp, function(outcome) {
				if (outcome === 'moved') { counts.moved++; }
				else if (outcome === 'skipped') { counts.skipped++; }
				else { counts.failed++; }
				advance(index + 1);
			});
		}
		advance(0);
	}

	/** Validate required fields and begin processing the batch child-barcode queue.
	 * @returns {void}
	 */
	function submitBatchMoveContainer() {
		var parentBarcode = $.trim($('#parent_barcode').val());
		var childBarcodes = parseBatchChildBarcodes($('#batch_child_barcodes').val());
		if (!parentBarcode) {
			setFeedbackControlState('moveContainerStatus', 'error', 'Parent barcode is required.');
			return;
		}
		if (childBarcodes.length === 0) {
			setFeedbackControlState('moveContainerStatus', 'error', 'Enter at least one child identifier.');
			return;
		}
		var moveTimestamp = $.trim($('#move_timestamp').val());
		processBatchMoveQueue(parentBarcode, childBarcodes, moveTimestamp);
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
		$('#moveContainerBatchMode').on('change', function() {
			applyBatchModeState($(this).prop('checked'));
		});
		$('#moveContainerBatchSubmit').on('click', submitBatchMoveContainer);
		$('#moveContainerForm').on('reset', function() {
			var updateModeState = function() {
				applyBarcodeScannerModeState($('#moveContainerScannerMode').prop('checked'));
				applyBatchModeState($('#moveContainerBatchMode').prop('checked'));
			};
			if (window.requestAnimationFrame) {
				window.requestAnimationFrame(updateModeState);
			} else {
				updateModeState();
			}
		});
		setTimestampToNow();
		applyBatchModeState($('#moveContainerBatchMode').prop('checked'));
		applyBarcodeScannerModeState($('#moveContainerScannerMode').prop('checked'));
		if (!$('#moveContainerBatchMode').prop('checked') && $.trim($('#child_barcode').val()).length > 0 && $.trim($('#parent_barcode').val()).length > 0) {
			submitMoveContainer();
		}
	});
</script>

<cfinclude template="/shared/_footer.cfm">
