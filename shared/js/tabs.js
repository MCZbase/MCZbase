// For accessibility of tabs //
// from https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/Tab_Role#example 
//
$(function(){
  var index = 0;
  var $tabs = $('button[role="tab"]');

  $tabs.bind(
  {
    // on keydown,
    // determine which tab to select
    keydown: function(ev){
      var LEFT_ARROW = 37;
      var UP_ARROW = 38;
      var RIGHT_ARROW = 39;
      var DOWN_ARROW = 40;

      var k = ev.which || ev.keyCode;

      // if the key pressed was an arrow key
      if (k >= LEFT_ARROW && k <= DOWN_ARROW){
        // move left one tab for left and up arrows
        if (k == LEFT_ARROW || k == UP_ARROW){
          if (index > 0) {
            index--;
          }
          // unless you are on the first tab,
          // in which case select the last tab.
          else {
            index = $tabs.length - 1;
          }
        }

        // move right one tab for right and down arrows
        else if (k == RIGHT_ARROW || k == DOWN_ARROW){
          if (index < ($tabs.length - 1)){
            index++;
          }
          // unless you're at the last tab,
          // in which case select the first one
          else {
            index = 0;
          }
        }

        // trigger a click event on the tab to move to
        $($tabs.get(index)).click();
        ev.preventDefault();
      }
    },

    // just make the clicked tab the selected one
    click: function(ev){
      index = $.inArray(this, $tabs.get());
      setFocus();
      ev.preventDefault();
    }
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