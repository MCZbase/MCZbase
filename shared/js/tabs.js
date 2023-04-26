// Support tabs, including accessibility
// 
// Modified from https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/Tab_Role#example 
//
// Make available to pages with  <cfset pageHasTabs="true"> before loading shared/_header.cfm
//
window.addEventListener("DOMContentLoaded", loadTabs);
var tabs;
var tabList;

// enumerate page elements with role tab or tablist, invoke with $(document).ready(loadTabs) when using on ajax loaded elements
// subsequent to initial DOMContentLoaded event.
// 
// each tab must have a role=tab, and an integer tabid, where tabid is 1 indexed
// one tab on page load should have class active.
// container for tabs must have role=tablist
function loadTabs() { 
	tabs = document.querySelectorAll('[role="tab"]');
	tabList = document.querySelector('[role="tablist"]');
	var activeTab = $('.tabList > .active').get(0);
	if (typeof activeTab !== 'undefined') { 
		var activeTabId = $(activeTab).attr('tabid');
		var activeTabIndex = activeTabId - 1; // tabs array is zero indexed, tabid values are 1 indexed.
	} else { 
		var activeTabIndex = 0;
		console.log("Page loaded with no active tab, index:" + activeTabIndex);
	}
	let tabFocus = activeTabIndex;  // define a block scope variable for the tab with initial focus on page load, used in the keydown event listener

	// Add a click event handler to each tab
	tabs.forEach(tab => {
		tab.addEventListener("click", changeTabs);
	});

	// Enable arrow navigation between tabs in the tab list, if there is a tabList
	if (tabList !== null) { 
		tabList.addEventListener("keydown", function(event) { handleKeyPressOnTab(event) ); });
	}
}

// key press handler, move right or left on tabs from arrow key presses
function handleKeyPressOnTab(e) {
	if (e.keyCode === 39 || e.keyCode === 37) {
		// keystroke was left arrow or right arrow
		tabs[tabFocus].setAttribute("tabindex", -1);
		if (e.keyCode === 39) {
			// Move right
			tabFocus++;
			// If we're at the end, go to the start
			if (tabFocus >= tabs.length) {
				tabFocus = 0;
			}
		} else if (e.keyCode === 37) {
			// Move left
			tabFocus--;
			// If we're at the start, move to the end
			if (tabFocus < 0) {
				tabFocus = tabs.length - 1;
			}
		}
		tabs[tabFocus].setAttribute("tabindex", 0);
		tabs[tabFocus].focus();
		changeTabs(e);
	}
}

// tab click event handler, also invoked from keystroke listener
function changeTabs(e) {
	const target = e.target;  // the tab 
	const parent = target.parentNode; // the container for the tabs 
	const grandparent = parent.parentNode; // the container for the tabs plus the panels to show/hide

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
