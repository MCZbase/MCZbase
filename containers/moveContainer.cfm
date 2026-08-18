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
						<span class="data-entry-label" id="batchChildGridLabel">Child Unique Identifiers</span>
						<small id="batchChildGridHelp" class="text-muted d-block mb-1">Scan or type a barcode into a box; it's checked as soon as you leave the box. Green is moved, yellow needs confirmation, red needs correction. A new box appears automatically as you fill the last one.</small>
						<div class="positions-grid positions-grid-autofill" id="batchChildGrid" role="group" aria-labelledby="batchChildGridLabel" aria-describedby="batchChildGridHelp"></div>
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

	/** Toggle batch mode behavior: swap the single child-barcode field for a grid of scan-and-validate
	 * cells, and disable barcode scanner mode's per-scan auto-submit while batch mode is active.
	 * @param {boolean} isBatchMode - true shows the batch grid in place of the single child field.
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
			if ($('#batchChildGrid').children().length === 0) {
				resetBatchChildGrid();
			}
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

	var batchChildRowCounter = 0;

	/** Mark one batch grid cell with a validation/move outcome and its message.
	 * @param {jQuery} inputEl - the barcode input the outcome applies to.
	 * @param {string} state - one of 'ok', 'warn', or 'bad'.
	 * @param {string} message - short status text shown under the input.
	 * @returns {void}
	 */
	function markBatchChildRowStatus(inputEl, state, message) {
		var cell = inputEl.closest('.positions-grid-cell');
		var statusEl = cell.find('.positions-grid-status-icon');
		var messageEl = cell.find('.positions-grid-barcode-status');
		inputEl.removeClass('goodPick warnPick badPick');
		messageEl.removeClass('text-success text-warning text-danger');
		if (state === 'ok') {
			inputEl.addClass('goodPick');
			statusEl.html('<i class="fas fa-check-circle text-success" aria-hidden="true"></i>');
			messageEl.addClass('text-success');
		} else if (state === 'warn') {
			inputEl.addClass('warnPick');
			statusEl.html('<i class="fas fa-exclamation-triangle text-warning" aria-hidden="true"></i>');
			messageEl.addClass('text-warning');
		} else {
			inputEl.addClass('badPick');
			statusEl.html('<i class="fas fa-times-circle text-danger" aria-hidden="true"></i>');
			messageEl.addClass('text-danger');
		}
		messageEl.text(message || '');
	}

	/** Clear one batch grid cell back to its blank, unvalidated state.
	 * @param {jQuery} inputEl - the barcode input to reset.
	 * @returns {void}
	 */
	function resetBatchChildRowStatus(inputEl) {
		inputEl.removeClass('goodPick warnPick badPick');
		var cell = inputEl.closest('.positions-grid-cell');
		cell.find('.positions-grid-status-icon').empty();
		cell.find('.positions-grid-barcode-status').empty().removeClass('text-success text-warning text-danger');
	}

	/** Ensure the batch grid always has one trailing blank, enabled input ready for the next scan.
	 * @returns {void}
	 */
	function ensureTrailingBatchChildRow() {
		var lastInput = $('#batchChildGrid .positions-grid-barcode-input').last();
		if (lastInput.length === 0 || lastInput.prop('disabled') || $.trim(lastInput.val()).length > 0) {
			addBatchChildRow();
		}
	}

	/** Move focus to the grid's trailing blank input, so scanning can continue without the mouse.
	 * @returns {void}
	 */
	function focusTrailingBatchChildRow() {
		var lastInput = $('#batchChildGrid .positions-grid-barcode-input:enabled').last();
		if (lastInput.length) {
			lastInput.trigger('focus');
		}
	}

	/** Execute the move for one batch grid entry once preflight has approved it, or a warning was confirmed.
	 * @param {jQuery} inputEl - the barcode input this move applies to.
	 * @param {string} parentBarcode - destination parent container barcode.
	 * @param {string} childBarcode - child container barcode being moved.
	 * @param {string} moveTimestamp - optional move timestamp.
	 * @returns {void}
	 */
	function executeBatchChildMove(inputEl, parentBarcode, childBarcode, moveTimestamp) {
		inputEl.prop('disabled', true);
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
				if (result && result.status === 'moved') {
					markBatchChildRowStatus(inputEl, 'ok', 'Moved.');
					var childDisplay = formatContainerDisplay(childBarcode, result.child_label);
					var parentDisplay = formatContainerDisplay(parentBarcode, result.parent_label);
					appendMoveResult('alert-success', 'Moved <strong>' + $('<div>').text(childDisplay).html() + '</strong> into <strong>' + $('<div>').text(parentDisplay).html() + '</strong>.');
					var movedCount = parseInt($('#moveContainerCounter').data('count'), 10) || 0;
					var nextCount = movedCount + 1;
					$('#moveContainerCounter').data('count', nextCount).text(nextCount + ' moved');
					ensureTrailingBatchChildRow();
					focusTrailingBatchChildRow();
				} else {
					inputEl.prop('disabled', false);
					markBatchChildRowStatus(inputEl, 'bad', (result && result.message) ? result.message : 'Move failed.');
					inputEl.trigger('select');
				}
			},
			error: function(jqXHR, textStatus, error) {
				inputEl.prop('disabled', false);
				markBatchChildRowStatus(inputEl, 'bad', 'Unable to reach the server. ' + prepareErrorMessage(jqXHR.responseText));
			}
		});
	}

	/** Run preflight for one batch grid entry and either move it immediately (clean placement),
	 * offer an inline confirm for a warning, or mark it red for correction. Never opens a modal
	 * dialog: a scanning workflow shouldn't have focus stolen by a popup, so status is always
	 * shown inline at the input that triggered it, one input at a time.
	 * @param {jQuery} inputEl - the barcode input that changed.
	 * @param {string} parentBarcode - destination parent container barcode.
	 * @param {string} childBarcode - child container barcode being validated.
	 * @param {string} moveTimestamp - optional move timestamp passed through on move.
	 * @returns {void}
	 */
	function runBatchChildPreflight(inputEl, parentBarcode, childBarcode, moveTimestamp) {
		inputEl.prop('disabled', true);
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
				inputEl.prop('disabled', false);
				if (!preflight || preflight.status === 'error') {
					markBatchChildRowStatus(inputEl, 'bad', (preflight && preflight.message) ? preflight.message : 'Unable to validate placement.');
					inputEl.trigger('select');
					return;
				}
				if (preflight.status === 'notfound') {
					markBatchChildRowStatus(inputEl, 'bad', preflight.message || 'Container was not found.');
					inputEl.trigger('select');
					return;
				}
				if (preflight.allowed !== true) {
					markBatchChildRowStatus(inputEl, 'bad', joinPlacementMessages(preflight.blocks) || 'Placement is not allowed.');
					inputEl.trigger('select');
					return;
				}
				if (preflight.severity === 'warn') {
					var warningMessage = joinPlacementMessages(preflight.warnings) || 'Needs confirmation.';
					markBatchChildRowStatus(inputEl, 'warn', warningMessage);
					var confirmBtn = $('<button type="button" class="btn btn-xs btn-warning mt-1">Confirm Move</button>');
					confirmBtn.on('click', function() {
						confirmBtn.remove();
						executeBatchChildMove(inputEl, parentBarcode, childBarcode, moveTimestamp);
					});
					inputEl.closest('.positions-grid-cell').find('.positions-grid-barcode-status').after(confirmBtn);
					return;
				}
				executeBatchChildMove(inputEl, parentBarcode, childBarcode, moveTimestamp);
			},
			error: function(jqXHR, textStatus, error) {
				inputEl.prop('disabled', false);
				markBatchChildRowStatus(inputEl, 'bad', 'Unable to reach the server. ' + prepareErrorMessage(jqXHR.responseText));
			}
		});
	}

	/** Handle a barcode entered or scanned into a batch grid cell.
	 * @param {jQuery} inputEl - the barcode input that changed.
	 * @returns {void}
	 */
	function handleBatchChildBarcodeChange(inputEl) {
		inputEl.closest('.positions-grid-cell').find('button').remove();
		resetBatchChildRowStatus(inputEl);
		var childBarcode = $.trim(inputEl.val());
		if (!childBarcode) {
			return;
		}
		var parentBarcode = $.trim($('#parent_barcode').val());
		if (!parentBarcode) {
			markBatchChildRowStatus(inputEl, 'bad', 'Enter the parent barcode above first.');
			return;
		}
		var moveTimestamp = $.trim($('#move_timestamp').val());
		runBatchChildPreflight(inputEl, parentBarcode, childBarcode, moveTimestamp);
	}

	/** Append one blank barcode-entry cell to the batch grid and wire its change handler.
	 * @returns {jQuery} the newly created barcode input element.
	 */
	function addBatchChildRow() {
		batchChildRowCounter++;
		var inputId = 'batchChildInput_' + batchChildRowCounter;
		var cell = $('<div class="positions-grid-cell positions-grid-cell-empty"></div>');
		var input = $('<input type="text" class="positions-grid-barcode-input data-entry-input">').attr({ id: inputId, placeholder: 'Scan barcode' });
		cell.append($('<label class="positions-grid-label"></label>').attr('for', inputId).text(batchChildRowCounter));
		cell.append(input);
		cell.append($('<div class="positions-grid-status-icon" aria-hidden="true"></div>'));
		cell.append($('<div class="positions-grid-barcode-status small" role="status"></div>'));
		$('#batchChildGrid').append(cell);
		input.on('change', function() {
			handleBatchChildBarcodeChange($(this));
		});
		return input;
	}

	/** (Re)build the batch grid from scratch with one blank starting row. Called when batch mode
	 * is first turned on, and on form reset.
	 * @returns {void}
	 */
	function resetBatchChildGrid() {
		$('#batchChildGrid').empty();
		batchChildRowCounter = 0;
		addBatchChildRow();
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
		$('#moveContainerForm').on('reset', function() {
			var updateModeState = function() {
				applyBarcodeScannerModeState($('#moveContainerScannerMode').prop('checked'));
				applyBatchModeState($('#moveContainerBatchMode').prop('checked'));
				resetBatchChildGrid();
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
