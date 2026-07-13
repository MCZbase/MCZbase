// JavaScript Document
// wikiDrawer.js
/**** Functions to load wiki content and display it in a target div within an MCZbase page, including support for a wikiDrawer drawer container ******/
/**
 * Show a wiki article in a target div, with options for showing images and specifying a target div for content.
 * @param page the name of the wiki page to load.
 * @param showImages boolean indicating whether to show images in the article, false to exclude images, true to include them.
 * @param targetDiv the id of the div to place the content into without a leading # selector.
 * @param titleTargetDiv the id of the div to place the title into without a leading # selector.
 * @param openFunction optional, a function to call when the wiki content is successfully loaded, e.g. to open a drawer.
 * @param closeFunction optional, a function to call when the wiki content fails to load, e.g. to close a drawer.
 * @param titleLink boolean indicating whether to create a link to the wiki page in the title div, true to create a link, false to just show the title.
 * @param section optional, the section number to load from the wiki page, default 0 for the entire wiki article.
 */

function recenterOpenDialogs() {
	// For every visible jQuery UI dialog
	$('.ui-dialog:visible').each(function () {
		var $dlg = $(this);

		// If needed, let jQuery UI compute the position again
		var $widget = $dlg; // .ui-dialog wrapper
		var $content = $widget.find('.ui-dialog-content');

		if ($content.length && $content.data('ui-dialog')) {
			$content.dialog('option', 'position', {
				my: 'center',
				at: 'center',
				of: window
			});
		} else {
			// Fallback: simple CSS recentering
			$dlg.css({
				left: '50%',
				top:  '50%',
				transform: 'translate(-50%, -50%)'
			});
		}
	});
}

// Shared wiki drawer open/close functions, assume wiki drawer is a div with id wikiDrawer, and
// that there are show-wiki and hide-wiki buttons to toggle with the drawer.
function resizeAllGridsToContent() {
	var $content = $("#content");
	if (!$content.length) return;

	var newWidth = $content.width();
	 console.log('resizeAllGridsToContent, newWidth:', newWidth);

	$('.jqxGrid').each(function () {
		console.log('resizing grid', this.id, 'to', newWidth);
		$(this).jqxGrid('width', newWidth);
	});
}
function openWikiDrawer() {
	$('#wikiDrawer').addClass('open');
	$('#content').addClass('pushed');
	$('body').addClass('wiki-open'); 
	$("#show-wiki").hide();
	$("#hide-wiki").show();
	resizeAllGridsToContent();
	recenterOpenDialogs();  
}
function closeWikiDrawer() {
	$('#wikiDrawer').removeClass('open');
	$('#content').removeClass('pushed');
	$('body').removeClass('wiki-open');
	$("#show-wiki").show();
	$("#hide-wiki").hide();
	resizeAllGridsToContent();
	recenterOpenDialogs();  
}


function showWiki(page, showImages, targetDiv, titleTargetDiv, openFunction, closeFunction, titleLink, section = null) {
	$('#'+targetDiv).html('Loading...');
	if (titleLink) {
		$('#'+titleTargetDiv).html('<aside id="collapseHelp" class="wiki-help">Wiki Article: <a href="https://code.mcz.harvard.edu/wiki/index.php?title=' + page + '" target="_blank">' + page + '</a></aside>');
	} else {
		$('#'+titleTargetDiv).html('Wiki Article: ' + page);
	}
	$.ajax({
		url: '/shared/component/functions.cfc?method=getWikiArticle',
		data: {
			page: page,
			showImages: showImages,
			section: section,
			returnFormat: 'json'
		},
		dataType: 'json',
		success: function (response) {
			var html = response.result || response.RESULT || "<div>Section not found.</div>";

			if (typeof openFunction === 'function') {
				openFunction();
			}

			if (typeof onSuccess === 'function') {
				options.onSuccess(html);
			} else {
				$('#' + targetDiv).html(html);
				if (typeof processWikiContent === 'function') {
					processWikiContent($('#' + targetDiv));
				}
			}
		},
		error: function (jqXHR, textStatus, errorThrown) {
			if (typeof closeFunction === 'function') {
				closeFunction();
			}
			handleFail(jqXHR, textStatus, errorThrown, "loading wiki content for page: " + page);
		}
	});
}

function showDivInWikiDrawer(divId, titleText) {
	var $src = $('#' + divId);
	if (!$src.length) {
		console.warn('showDivInWikiDrawer: source div not found:', divId);
		return;
	}

	if (titleText) {
		$('#wiki-content-title').text(titleText);
	}

	$('#wiki-content').html($src.html());
	openWikiDrawer();
}


function initWikiDrawer(options) {
	$(function () {
		$('#show-wiki').on('click', function (e) {
			e.preventDefault();

				showWiki(
					options.targetWikiPage,
					false,
					'wiki-content',
					'wiki-content-title',
					openWikiDrawer,
					closeWikiDrawer,
					true,
					0
				);

				$('#show-wiki').hide();
				$('#hide-wiki').show();
			});

			$('#hide-wiki').on('click', function (e) {
				e.preventDefault();
				closeWikiDrawer();
			});

			$('#hide-wiki').hide();

		// Keep your existing #show-wiki and #hide-wiki handlers as-is.

		// ONE generic handler for all help buttons
		$(document).on('click', '.js-search-help', function (e) {
			e.preventDefault();

			var targetId = $(this).data('helpTarget'); // e.g. "collapseKeywordHelp"
			if (!targetId) {
				console.warn('js-search-help clicked without data-help-target');
				return;
			}

			// Toggle behavior: if the drawer is open, close it; otherwise show this aside
			if ($('#wikiDrawer').hasClass('open')) {
				closeWikiDrawer();
			} else {
				showDivInWikiDrawer(targetId, 'Search Help');
			}
		});
	});
}


//$(function () {
//	// Map panel IDs to their help aside IDs
//	var tabHelpMap = {
//		basicSearchTabButton:   'collapseFixedBasic',
//		keywordSearchTabButton: 'collapseKeywordHelp',
//		builderSearchTabButton: 'collapseBuilderHelp'
//	};
//
//	// When a tab is shown
//	// When a tab button is clicked
//	$('#basicSearchTabButton, #keywordSearchTabButton, #builderSearchTabButton').on('click', function () {
//		// If the drawer isn't open, do nothing
//		if (!$('#wikiDrawer').hasClass('open')) {
//			return;
//		}
//
//		var btnId   = this.id;
//		var helpId  = tabHelpMap[btnId];
//
//		if (helpId) {
//			// Replace drawer content with this tab's help aside
//			showDivInWikiDrawer(helpId, 'Search Help');
//		}
//	});
//});

$(function () {
	$('#basicSearchTabButton, #keywordSearchTabButton, #builderSearchTabButton')
		.on('click', function () {
		// If the drawer is NOT open, do nothing
		// Choose whichever check matches your CSS:
		if (!$('#wikiDrawer').is(':visible') && !$('#wikiDrawer').hasClass('open')) {
		return;
	}

	var page = $(this).data('wikiPage'); // from data-wiki-page
	if (!page) {
		console.warn('No data-wiki-page for tab button:', this.id);
		return;
	}

	// Drawer is open: swap the wiki article
	showWiki(
		page,
			false,                 // showImages
			'wiki-content',        // targetDiv
			'wiki-content-title',  // titleTargetDiv
			null,                  // DON'T auto-open here
			null,                  // DON'T auto-close here
			true,                  // titleLink
			0                      // section
		);
	});
});