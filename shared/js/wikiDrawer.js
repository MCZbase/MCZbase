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
function showWiki(page, showImages, targetDiv, titleTargetDiv, openFunction, closeFunction, titleLink, section = null) {

    $.ajax({
        url: '/shared/component/functions.cfc?method=getWikiArticle',
        method: 'GET',
        data: {
            page: page,
            showImages: showImages ? 'true' : 'false',  // CF-friendly
            section: section || '',
            returnFormat: 'json'
        },
        dataType: 'json',
        success: function (response) {
            // CF remote CFC returns {"RESULT":"<html>..."}
            var html = response.result || response.RESULT || "<div>Section not found.</div>";

            // Open the drawer (if callback provided)
            if (typeof openFunction === 'function') {
                openFunction();
            }

            // Insert the HTML into the target div
            var $content = $('#' + targetDiv);
            $content.html(html);

            // Optional: post-process HTML if you have such a function
            if (typeof processWikiContent === 'function') {
                processWikiContent($content);
            }

            // Set the title, if a titleTargetDiv was provided
            if (titleTargetDiv) {
                var $title = $('#' + titleTargetDiv);
                var titleText = page.replace(/_/g, ' ');

                if (titleLink) {
                    // If you had titleLink behavior before, adapt as needed:
                    // e.g., make it an <a>:
                    $title.html('<a href="' + titleLink + '">' + titleText + '</a>');
                } else {
                    $title.text(titleText);
                }
            }
        },
        error: function (jqXHR, textStatus, errorThrown) {
            if (typeof closeFunction === 'function') {
                closeFunction();
            }
            if (typeof handleFail === 'function') {
                handleFail(jqXHR, textStatus, errorThrown, "loading wiki content for page: " + page);
            } else {
                console.error("Error loading wiki content for page " + page + ":", textStatus, errorThrown);
            }
        }
    });
}
// Shared wiki drawer open/close functions, assume wiki drawer is a div with id wikiDrawer, and
// that there are show-wiki and hide-wiki buttons to toggle with the drawer.
function openWikiDrawer() {
	$('#wikiDrawer').addClass('open');
	$('#content').addClass('pushed');
	$("#show-wiki").hide();
	$("#hide-wiki").show();
}
function closeWikiDrawer() {
	$('#wikiDrawer').removeClass('open');
	$('#content').removeClass('pushed');
	$("#show-wiki").show();
	$("#hide-wiki").hide();
}



// Shared process/cleanup wiki content
function processWikiContent($container) {
	$container.find('.mw-editsection').remove(); // remove edit controls
	$container.find('#toc').remove(); // remove table of contents

	$container.find('a').filter(function() {
		return $(this).text().trim().toLowerCase() === "edit";
	}).remove(); // remove edit links within the content.

	$container.html($container.html().replace(/edit\]|\]$/gm, '')); // remove trailing edit links and brackets

	// Update image links to point to a corrected uri, and remove width/height attributes from images.
	$container.find('a.image').each(function() {
		var $a = $(this), $img = $a.find('img');
		var href = $a.attr('href');
		var src = $img.attr('src');
		if (href && href.indexOf('http') !== 0) $a.attr('href', 'https://code.mcz.harvard.edu' + href);
		$a.attr('target', '_blank');
		if (src && src.indexOf('http') !== 0) $img.attr('src', 'https://code.mcz.harvard.edu' + src);
		var srcset = $img.attr('srcset');
		if (srcset) $img.attr('srcset', srcset.replace(/(\/wiki\/images\/[^\s]*)/g, "https://code.mcz.harvard.edu$1"));
		$img.removeAttr('width').removeAttr('height');
	});
	$container.find('img').removeAttr('width').removeAttr('height');

	$container.find('a').contents().unwrap(); // remove all <a> tags around text, leaving just the text.

   // alternately, correct links to point to the wiki, uncomment the following lines to do so:
	// TODO: Put this into the backing method, only allowed for coldfusion_user roles
   //$container.find('a').each(function() {
	//	var $a = $(this);
	//	if ($a.attr('href') && $a.attr('href').indexOf('http') !== 0) {
	//		$a.attr('href', 'https://code.mcz.harvard.edu' + $a.attr('href'));
	//	}
	//	$a.attr('target', '_blank');
	//});
}

/**** End wiki content loading and processing functions ****/

function initWikiDrawer(options) {
    $(function () {
        $('#show-wiki').on('click', function (e) {
            e.preventDefault();

            showWiki(
                options.targetWikiPage,     // page
                false,                      // showImages
                'wiki-content',             // targetDiv
                'wiki-content-title',       // titleTargetDiv
                openWikiDrawer,             // openFunction
                closeWikiDrawer,            // closeFunction
                null,                       // titleLink (or a URL if you use it)
                0                           // section
            );

            $('#show-wiki').hide();
            $('#hide-wiki').show();
        });

        $('#hide-wiki').on('click', function (e) {
            e.preventDefault();
            closeWikiDrawer();
        });

        $('#hide-wiki').hide();
    });
}