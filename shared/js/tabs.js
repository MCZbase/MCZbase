// For accessibility of tabs //
// from https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/Tab_Role#example 
//
window.addEventListener("DOMContentLoaded", () => {
	const tabs = document.querySelectorAll('[role="tab"]');
	const tabList = document.querySelector('[role="tablist"]');
	var activeTab = $('.tabList > .active').get(0);
	var activeTabId = $(activeTab).attr('id');
	var activeTabIndex = activeTabId - 1; // tabs array is zero indexed, tab Ids are 1 indexed.
	console.log('Page loaded with Tab Button:' + activeTabId + " index:" + activeTabIndex);
	let tabFocus = activeTabIndex;  // define a block scope variable for the tab with initial focus on page load, used in the keydown event listener

	// Add a click event handler to each tab
	tabs.forEach(tab => {
		tab.addEventListener("click", changeTabs);
		tab.focus()
	});

	// Enable arrow navigation between tabs in the tab list
	tabList.addEventListener("keydown", e => {
		// Move right
		if (e.keyCode === 39 || e.keyCode === 37) {
			tabs[tabFocus].setAttribute("tabindex", -1);
			if (e.keyCode === 39) {
				tabFocus++;
				// If we're at the end, go to the start
				if (tabFocus >= tabs.length) {
					tabFocus = 0;
				}
				// Move left
			} else if (e.keyCode === 37) {
				tabFocus--;
				// If we're at the start, move to the end
				if (tabFocus < 0) {
					tabFocus = tabs.length - 1;
				}
			}
			tabs[tabFocus].setAttribute("tabindex", 0);
			tabs[tabFocus].focus();
		}
	});
});

function changeTabs(e) {
	const target = e.target;
	const parent = target.parentNode;
	const grandparent = parent.parentNode;

	// Remove all current selected tabs
	parent
		.querySelectorAll('[aria-selected="true"]')
		.forEach(t => t.setAttribute("aria-selected", false));

	// Set this tab as selected
	target.setAttribute("aria-selected", true);

	// Hide all tab panels
	grandparent
	.querySelectorAll('[role="tabpanel"]')
	.forEach(p => p.setAttribute("hidden", true));

	// Show the selected panel
	grandparent.parentNode
		.querySelector(`#${target.getAttribute("aria-controls")}`)
		.removeAttribute("hidden");
	}
