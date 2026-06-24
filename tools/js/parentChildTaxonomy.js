document.addEventListener("DOMContentLoaded", function () {
	const rowChecks = document.querySelectorAll(".relationship-row-check");
	const selectedCount = document.getElementById("selectedCount");
	const bulkSyncBtn = document.getElementById("bulkSyncBtn");

	if (!selectedCount || !bulkSyncBtn || rowChecks.length === 0) {
		return;
	}

	const updateSelectionState = function () {
		const selected = document.querySelectorAll(".relationship-row-check:checked").length;
		selectedCount.textContent = selected + " action" + (selected === 1 ? "" : "s") + " selected";
		bulkSyncBtn.disabled = selected === 0;
	};

	rowChecks.forEach(function (rowCheck) {
		rowCheck.addEventListener("change", function () {
			if (rowCheck.checked) {
				const row = rowCheck.closest("tr");
				if (row) {
					const rowCheckGroup = row.querySelectorAll(".relationship-row-check");
					rowCheckGroup.forEach(function (otherCheck) {
						if (otherCheck !== rowCheck) {
							otherCheck.checked = false;
						}
					});
				}
			}
			updateSelectionState();
		});
	});

	updateSelectionState();
});
