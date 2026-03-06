// JavaScript Document
// wikiDrawer.js

function initWikiDrawer(options) {
    // options: { targetWikiPage, canEdit }

    $('#show-wiki').on('click', function (e) {
        e.preventDefault();

        showWiki(
            options.targetWikiPage,
            false,
            "wiki-content",
            "wiki-content-title",
            openWikiDrawer,
            closeWikiDrawer,
            options.canEdit,
            0
        );

        $("#show-wiki").hide();
        $("#hide-wiki").show();
    });

    $('#hide-wiki').on('click', function (e) {
        e.preventDefault();
        closeWikiDrawer();
    });

    $(document).ready(function () {
        $("#hide-wiki").hide();
    });
}