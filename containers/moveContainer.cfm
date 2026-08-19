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
<cfset variables.scannerModeEnabled = false>
<cfif trim(url.barcode_scanner_mode) EQ "1">
	<cfset variables.scannerModeEnabled = true>
</cfif>
<cfset variables.batchModeEnabled = false>
<cfif trim(url.batch_mode) EQ "1">
	<cfset variables.batchModeEnabled = true>
</cfif>
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
			<p class="small text-muted">Scan or enter a parent container barcode and child container barcode, then confirm the move. Use Batch Mode to check a list of children against one parent, then move them all at once.</p>
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
						<div id="childPlacementBadge" class="small mt-1" role="status"></div>
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
						<small id="batchChildGridHelp" class="text-muted d-block mb-1">Scan or type a barcode into a box; it's checked against the parent above as soon as you leave the box, then focus moves on to the next box. A new box appears automatically as you fill the last one. Nothing is moved until you click Move Container below.</small>
						<div class="positions-grid positions-grid-autofill" id="batchChildGrid" role="group" aria-labelledby="batchChildGridLabel" aria-describedby="batchChildGridHelp"></div>
					</div>
				</div>
				<div class="form-row mb-2">
					<div class="col-12">
						<button type="button" class="btn btn-xs btn-primary" id="moveContainerSubmit">Move Container</button>
						<button type="button" class="btn btn-xs btn-secondary ml-1" id="moveContainerNow">Set Timestamp to Now</button>
						<button type="reset" class="btn btn-xs btn-warning ml-1" id="moveContainerClear">Clear Form</button>
						<span class="ml-3" id="moveContainerScannerModeWrap">
							<input type="checkbox" id="moveContainerScannerMode"<cfif variables.scannerModeEnabled> checked</cfif>>
							<label class="mb-0 small d-inline" for="moveContainerScannerMode">Barcode Scanner Mode</label>
						</span>
						<span class="ml-3" id="moveContainerAutoSubmitWrap">
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

	/** Build an HTML string for a link that opens the shared container details dialog
	 * (openContainerDetailsDialog in containers.js) for one container, for embedding into other
	 * string-templated HTML such as Move Log entries. The onclick attribute is set through the DOM
	 * and read back via outerHTML so the browser handles escaping the display text correctly,
	 * rather than hand-escaping a string for both HTML and JS-string-literal contexts at once.
	 * @param {number|string} containerId - container_id to open details for.
	 * @param {string} displayText - visible link text and dialog title.
	 * @returns {string} an <a> tag as an HTML string, safe to concatenate into other markup.
	 */
	function buildContainerDetailsLinkHtml(containerId, displayText) {
		return $('<a href="javascript:void(0);"></a>')
			.attr('onclick', 'openContainerDetailsDialog(' + parseInt(containerId, 10) + ', ' + JSON.stringify(String(displayText)) + ', null, false); return false;')
			.text(displayText)
			.prop('outerHTML');
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

	/** Toggle batch mode behavior: swap the single child-barcode field for a grid of scan-and-check
	 * cells. Batch mode has no per-input auto-submit — checking each entry as it's scanned and then
	 * moving everything at once are deliberately separate steps here, so Scanner Mode and Submit on
	 * Child Change (both about auto-committing a single entry the instant it changes) are hidden
	 * rather than merely disabled, since neither applies to the batch workflow.
	 * @param {boolean} isBatchMode - true shows the batch grid in place of the single child field.
	 * @returns {void}
	 */
	function applyBatchModeState(isBatchMode) {
		isBatchMode = !!isBatchMode;
		$('#moveContainerSingleChildWrap').toggle(!isBatchMode);
		$('#moveContainerBatchWrap').toggle(isBatchMode);
		$('#moveContainerScannerModeWrap').toggle(!isBatchMode);
		$('#moveContainerAutoSubmitWrap').toggle(!isBatchMode);
		$('#moveContainerSubmit').text(isBatchMode ? 'Move Containers' : 'Move Container');
		if (isBatchMode) {
			$('#moveContainerAutoSubmit').prop('checked', false);
			$('#moveContainerScannerMode').prop('checked', false);
			applyBarcodeScannerModeState(false);
			if ($('#batchChildGrid').children().length === 0) {
				resetBatchChildGrid();
			}
		}
		updateMoveContainerSubmitState();
	}

	/** Render the shared placement badge (renderPlacementWarningBadge in containers.js — the same
	 * ok/warn/blocked badge used on Container.cfm and viewContainer.cfm) for one preflight result,
	 * additionally handling the barcode-not-found/error cases that function doesn't cover on its
	 * own (it expects an already-resolved validateContainerPlacement result, not a barcode lookup).
	 * @param {string} badgeTargetId - id of the element to render the badge into (without leading #).
	 * @param {Object} preflight - response from preflightMoveContainerByBarcode.
	 * @returns {string} normalized outcome: 'ok', 'warn', 'blocked', 'notfound', or 'error'.
	 */
	function renderChildPlacementBadge(badgeTargetId, preflight) {
		var target = $('#' + badgeTargetId);
		if (!preflight || preflight.status === 'error') {
			target.empty().append($('<span class="badge badge-danger"></span>').text('✗ ' + ((preflight && preflight.message) ? preflight.message : 'Unable to validate placement.')));
			return 'error';
		}
		if (preflight.status === 'notfound') {
			target.empty().append($('<span class="badge badge-danger"></span>').text('✗ ' + (preflight.message || 'Container was not found.')));
			return 'notfound';
		}
		renderPlacementWarningBadge(preflight, badgeTargetId);
		return preflight.allowed === true ? (preflight.severity === 'warn' ? 'warn' : 'ok') : 'blocked';
	}

	/** Run barcode-based placement preflight for one input and render the shared placement badge.
	 * Never opens a modal dialog or confirm button — every outcome, including a transport error, is
	 * shown inline at the badge next to the input that triggered it, so neither a single scan nor a
	 * batch of them ever has focus stolen by a popup.
	 * @param {jQuery} inputEl - the barcode input being validated.
	 * @param {string} badgeTargetId - id of the element to render the badge into (without leading #).
	 * @param {string} parentBarcode - destination parent container barcode.
	 * @param {string} childBarcode - child container barcode being validated.
	 * @param {function(string):void} onDone - called with the normalized outcome ('ok'|'warn'|'blocked'|'notfound'|'error').
	 * @returns {void}
	 */
	function runChildPlacementPreflight(inputEl, badgeTargetId, parentBarcode, childBarcode, onDone) {
		$('#' + badgeTargetId).html('<span class="small text-muted"><img src="/shared/images/indicator.gif"> Checking…</span>');
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
				onDone(renderChildPlacementBadge(badgeTargetId, preflight));
			},
			error: function(jqXHR, textStatus, error) {
				inputEl.prop('disabled', false);
				var message = 'Unable to reach the server. ' + prepareErrorMessage(jqXHR.responseText);
				$('#' + badgeTargetId).empty().append($('<span class="badge badge-danger"></span>').text('✗ ' + message));
				onDone('error');
			}
		});
	}

	/** Execute the actual move for one already-checked child barcode. Callers decide what "done"
	 * means for their own input — single mode clears and reuses the field for the next scan, batch
	 * mode locks the box as a permanent record — so this only handles the request itself, the Move
	 * Log entry, and (on failure) replacing the badge with the failure reason.
	 * @param {jQuery} inputEl - the barcode input this move applies to.
	 * @param {string} badgeTargetId - id of the element the placement badge is shown in.
	 * @param {string} parentBarcode - destination parent container barcode.
	 * @param {string} childBarcode - child container barcode being moved.
	 * @param {string} moveTimestamp - optional move timestamp.
	 * @param {function(boolean):void} onDone - called with true if the move succeeded, false otherwise.
	 * @returns {void}
	 */
	function commitChildMove(inputEl, badgeTargetId, parentBarcode, childBarcode, moveTimestamp, onDone) {
		inputEl.prop('disabled', true);
		setFeedbackControlState('moveContainerStatus', 'saving', 'Moving...');
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
				inputEl.prop('disabled', false);
				if (result && result.status === 'moved') {
					var childDisplay = formatContainerDisplay(childBarcode, result.child_label);
					var parentDisplay = formatContainerDisplay(parentBarcode, result.parent_label);
					var childLink = buildContainerDetailsLinkHtml(result.child_container_id, childDisplay);
					var parentLink = buildContainerDetailsLinkHtml(result.parent_container_id, parentDisplay);
					appendMoveResult('alert-success', 'Moved <strong>' + childLink + '</strong> into <strong>' + parentLink + '</strong>.');
					var movedCount = parseInt($('#moveContainerCounter').data('count'), 10) || 0;
					$('#moveContainerCounter').data('count', movedCount + 1).text((movedCount + 1) + ' moved');
					setFeedbackControlState('moveContainerStatus', 'saved', 'Move recorded.');
					onDone(true);
				} else {
					var failMessage = (result && result.message) ? result.message : 'Move failed.';
					$('#' + badgeTargetId).empty().append($('<span class="badge badge-danger"></span>').text('✗ ' + failMessage));
					appendMoveResult('alert-danger', $('<div>').text(failMessage).html());
					setFeedbackControlState('moveContainerStatus', 'error', failMessage);
					onDone(false);
				}
			},
			error: function(jqXHR, textStatus, error) {
				inputEl.prop('disabled', false);
				var message = 'Unable to reach the server. ' + prepareErrorMessage(jqXHR.responseText);
				$('#' + badgeTargetId).empty().append($('<span class="badge badge-danger"></span>').text('✗ ' + message));
				setFeedbackControlState('moveContainerStatus', 'error', 'Move failed.');
				onDone(false);
			}
		});
	}

	/** Show a placement preview badge for the single child field without moving anything.
	 * @returns {void}
	 */
	function previewChildPlacement() {
		var parentBarcode = $.trim($('#parent_barcode').val());
		var childBarcode = $.trim($('#child_barcode').val());
		$('#childPlacementBadge').empty();
		if (!childBarcode) {
			return;
		}
		if (!parentBarcode) {
			$('#childPlacementBadge').append($('<span class="badge badge-danger"></span>').text('✗ Enter the parent barcode first.'));
			return;
		}
		runChildPlacementPreflight($('#child_barcode'), 'childPlacementBadge', parentBarcode, childBarcode, function() {});
	}

	/** Validate required fields, preflight-check the single child field, and move it immediately if
	 * the placement isn't blocked (an ok or warn outcome both proceed — this button click is itself
	 * the confirmation, there's no separate confirm step or dialog).
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
		runChildPlacementPreflight($('#child_barcode'), 'childPlacementBadge', parentBarcode, childBarcode, function(outcome) {
			if (outcome !== 'ok' && outcome !== 'warn') {
				setFeedbackControlState('moveContainerStatus', 'error', 'Placement is not allowed.');
				return;
			}
			commitChildMove($('#child_barcode'), 'childPlacementBadge', parentBarcode, childBarcode, moveTimestamp, function(moved) {
				if (moved) {
					$('#child_barcode').val('').focus();
					$('#childPlacementBadge').empty();
				}
			});
		});
	}

	var batchChildRowCounter = 0;

	/** Ensure the batch grid always has one trailing blank input ready for the next scan.
	 * @returns {void}
	 */
	function ensureTrailingBatchChildRow() {
		var lastInput = $('#batchChildGrid .positions-grid-barcode-input').last();
		if (lastInput.length === 0 || $.trim(lastInput.val()).length > 0) {
			addBatchChildRow();
		}
	}

	/** Move focus to the grid's trailing blank input, so scanning can continue without the mouse.
	 * @returns {void}
	 */
	function focusTrailingBatchChildRow() {
		var lastInput = $('#batchChildGrid .positions-grid-barcode-input').last();
		if (lastInput.length) {
			lastInput.trigger('focus');
		}
	}

	/** Enable the Move Container(s) button only in single mode, or in batch mode only when the grid
	 * has at least one checked, movable (ok/warn) box and none that are blocked, not found, or in
	 * error — a single unresolved box anywhere holds off submission until it's fixed or cleared.
	 * @returns {void}
	 */
	function updateMoveContainerSubmitState() {
		if (!$('#moveContainerBatchMode').prop('checked')) {
			$('#moveContainerSubmit').prop('disabled', false);
			return;
		}
		var movable = 0;
		var blocking = 0;
		$('#batchChildGrid .positions-grid-barcode-input').each(function() {
			var inputEl = $(this);
			if ($.trim(inputEl.val()).length === 0 || inputEl.prop('readonly')) {
				return;
			}
			var outcome = inputEl.data('outcome');
			if (outcome === 'ok' || outcome === 'warn') {
				movable++;
			} else if (outcome === 'blocked' || outcome === 'notfound' || outcome === 'error') {
				blocking++;
			}
		});
		$('#moveContainerSubmit').prop('disabled', !(movable > 0 && blocking === 0));
	}

	/** Handle a barcode entered or scanned into a batch grid cell: preflight-check it, render its
	 * badge, remember the outcome for the eventual batch commit, and move on to the next box.
	 * Nothing is moved here — batch mode always defers the actual move to the Move Containers button.
	 * @param {jQuery} inputEl - the barcode input that changed.
	 * @returns {void}
	 */
	function handleBatchChildBarcodeChange(inputEl) {
		var badgeTargetId = inputEl.data('badgeId');
		$('#' + badgeTargetId).empty();
		inputEl.removeData('outcome').removeData('checkedValue');
		var childBarcode = $.trim(inputEl.val());
		if (!childBarcode) {
			updateMoveContainerSubmitState();
			return;
		}
		var parentBarcode = $.trim($('#parent_barcode').val());
		if (!parentBarcode) {
			$('#' + badgeTargetId).append($('<span class="badge badge-danger"></span>').text('✗ Enter the parent barcode above first.'));
			updateMoveContainerSubmitState();
			return;
		}
		runChildPlacementPreflight(inputEl, badgeTargetId, parentBarcode, childBarcode, function(outcome) {
			inputEl.data('outcome', outcome).data('checkedValue', childBarcode);
			updateMoveContainerSubmitState();
			ensureTrailingBatchChildRow();
			focusTrailingBatchChildRow();
		});
	}

	/** Append one blank barcode-entry cell to the batch grid and wire its change handler.
	 * @returns {jQuery} the newly created barcode input element.
	 */
	function addBatchChildRow() {
		batchChildRowCounter++;
		var inputId = 'batchChildInput_' + batchChildRowCounter;
		var badgeId = 'batchChildBadge_' + batchChildRowCounter;
		var cell = $('<div class="positions-grid-cell positions-grid-cell-empty"></div>');
		var input = $('<input type="text" class="positions-grid-barcode-input data-entry-input">')
			.attr({ id: inputId, placeholder: 'Scan barcode' })
			.data('badgeId', badgeId);
		cell.append($('<label class="positions-grid-label"></label>').attr('for', inputId).text(batchChildRowCounter));
		cell.append(input);
		cell.append($('<div class="positions-grid-barcode-status small" id="' + badgeId + '" role="status"></div>'));
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

	/** Commit every batch grid box currently showing an 'ok' or 'warn' outcome, sequentially,
	 * re-checking first any filled box that was never validated or was edited since (e.g. a barcode
	 * pasted into the last box and never tabbed out of before this button was clicked). Boxes that
	 * are empty, already moved (readonly), or come back blocked/not found/in error are left alone.
	 * @returns {void}
	 */
	function runBatchMoveCommit() {
		var parentBarcode = $.trim($('#parent_barcode').val());
		if (!parentBarcode) {
			setFeedbackControlState('moveContainerStatus', 'error', 'Parent barcode is required.');
			return;
		}
		var moveTimestamp = $.trim($('#move_timestamp').val());
		var inputs = $('#batchChildGrid .positions-grid-barcode-input').filter(function() {
			return $.trim($(this).val()).length > 0 && !$(this).prop('readonly');
		}).get();
		$('#moveContainerSubmit').prop('disabled', true);
		var counts = { moved: 0, skipped: 0 };
		function advance(index) {
			if (index >= inputs.length) {
				setFeedbackControlState('moveContainerStatus', (counts.skipped > 0) ? 'warning' : 'saved', counts.moved + ' moved, ' + counts.skipped + ' not moved.');
				updateMoveContainerSubmitState();
				return;
			}
			var inputEl = $(inputs[index]);
			var childBarcode = $.trim(inputEl.val());
			var badgeTargetId = inputEl.data('badgeId');
			var proceed = function(outcome) {
				if (outcome === 'ok' || outcome === 'warn') {
					commitChildMove(inputEl, badgeTargetId, parentBarcode, childBarcode, moveTimestamp, function(moved) {
						if (moved) {
							inputEl.prop('readonly', true);
							counts.moved++;
						} else {
							counts.skipped++;
						}
						advance(index + 1);
					});
				} else {
					counts.skipped++;
					advance(index + 1);
				}
			};
			if (inputEl.data('outcome') && inputEl.data('checkedValue') === childBarcode) {
				proceed(inputEl.data('outcome'));
			} else {
				runChildPlacementPreflight(inputEl, badgeTargetId, parentBarcode, childBarcode, function(outcome) {
					inputEl.data('outcome', outcome).data('checkedValue', childBarcode);
					proceed(outcome);
				});
			}
		}
		advance(0);
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
		$('#moveContainerSubmit').on('click', function() {
			if ($('#moveContainerBatchMode').prop('checked')) {
				runBatchMoveCommit();
			} else {
				submitMoveContainer();
			}
		});
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
			} else {
				previewChildPlacement();
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
				updateMoveContainerSubmitState();
				$('#childPlacementBadge').empty();
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
