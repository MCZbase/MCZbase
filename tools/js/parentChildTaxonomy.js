document.addEventListener("DOMContentLoaded", function () {
	const rowChecks = document.querySelectorAll(".relationship-row-check");
	const selectedCount = document.getElementById("selectedCount");
	const bulkSyncBtn = document.getElementById("bulkSyncBtn");

	if (!selectedCount || !bulkSyncBtn || rowChecks.length === 0) {
		return;
	}

	const updateSelectionState = function () {
		const selected = document.querySelectorAll(".relationship-row-check:checked").length;
		selectedCount.textContent = selected + " selected";
		bulkSyncBtn.disabled = selected === 0;
	};

	rowChecks.forEach(function (rowCheck) {
		rowCheck.addEventListener("change", updateSelectionState);
	});

	updateSelectionState();
});
