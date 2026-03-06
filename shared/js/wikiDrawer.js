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


function showWiki(page, showImages, targetDiv, titleTargetDiv, openFunction, closeFunction, titleLink, section = null) {
    $.ajax({
        url: '/shared/component/functions.cfc?method=getWikiArticle',
        method: 'GET',
        data: {
            page: page,
            showImages: showImages ? 'true' : 'false',
            section: section || '',
            returnFormat: 'json'
        },
        dataType: 'json',
        success: function (response) {
            var html = response.result || response.RESULT || "<div>Section not found.</div>";

            if (typeof openFunction === 'function') {
                openFunction();
            }

            var $content = $('#' + targetDiv);
            $content.html(html);

            if (typeof processWikiContent === 'function') {
                processWikiContent($content);
            }

            if (titleTargetDiv) {
                var $title = $('#' + titleTargetDiv);
                var titleText = page.replace(/_/g, ' ');
                if (titleLink) {
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
                null,
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
    });
}