<!--
media/debugMediaGallery.cfm

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

-->
<!--- Gallery of media blocks from getMediaBlockHtml() in each display mode, and test cases for
      the enlarged view from /shared/js/media-zoom.js. --->
<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/public.cfc" runOnce="true">

<cfoutput>
	<main class="container-fluid my-3" id="content">

		<h1 class="h2">Gallery of images for testing/debugging the media widget.</h1>

		<cfquery name="examples" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select distinct media_id from (
				select max(media_id) media_id from media
				group by mime_type, media_type
				union
				select max(media_relations.media_id) media_id from media_relations join media on media_relations.media_id = media.media_id
				group by media_relationship
				union
				select max(media_id) media_id from media 
				group by media.auto_host
				having count(*) > 50
				union
				select max(media_labels.media_id) from media_labels join media on media_labels.media_id = media.media_id
				where media_label = 'height'
				group by label_value
				having count(*) > 500
			)
		</cfquery>
		<div class="row">
			<div class="container-fluid mt-5">
				<h2 class="h4">
				Background light gray.  These examples are set with a size attribute (e.g., <strong>size="400"</strong>) and a captionAs attribute (e.g., <strong>textMid</strong>) to getMediaBlockHtml(). The image is sized to 400px wide and high and has a gray background where it doesn&apos;t fit the square. The preview_URI will be shown as is (sizewise).  The placeholder images are given a maximum width, which keeps them thumbnail size of 125px even if the container is larger and the size of the shared drive images are 400px. The thumbnail for spectrometer data (an SVG) could be better.  I couldn&apos;t find many public domain SVGs. Shrinking the container will shrink the caption and should be done with the "size". It is possible to allow these placeholder images to fill the container they are in by increasing the max-width (<cfset l_styles = "max-width:150px;max-height:auto;">--auto is need here because the text img is portrait size -- svg files so it shouldn&apos;t matter too much) on line 1121 of media/components/search.cfc. I figured out that italics cannot be in the description label or it breaks the html.
				</h2>
				<code>&lt;cfset mediablock= getMediaBlockHtml(media_id="##media_id##",size="400",captionAs="textMid")&gt;</code>
			</div>
			<cfloop query="examples">
				<div class="col-12 col-sm-6 col-md-4 col-xl-3 mt-5 bg-light">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="400",captionAs="textMid")>
					<div id="mediaBlock#media_id#" class="border rounded">
						<cfif len(trim(mediablock)) EQ 0><cfset mediablock="ERROR: empty widget for media_id=#media_id#"></cfif>
						#mediablock#
					</div>
				</div>
			</cfloop>
		</div>

		<div class="row">
			<div class="container-fluid mt-5">
				<h2 class="h4">
					fixedSmallThumb, textMid caption (for debugging mime types, likely want to use captionAs="textNone"), background_color=white, to paste the thumbnails into a square image of the specified background color, background_style not relevant here as the resulting image is opaque;
				</h2>
				<code>&lt;cfset mediablock= getMediaBlockHtml(media_id="##media_id##",displayAs="fixedSmallThumb",size="100", captionAs="textMid", background_color="white")&gt;</code>
			</div>
			<cfloop query="examples">
				<div class="col-12 col-sm-6 col-md-4 col-xl-3 mt-5 bg-light">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="fixedSmallThumb",size="100", captionAs="textMid", background_color="white")>
					<div id="mediaBlock#media_id#" class="border pt-2 rounded">
					#mediablock#
					</div>
				</div>
			</cfloop>
		</div>

		<div class="row">
			<div class="container-fluid mt-5"><h2 class="h4 mb-0"> Background teal.  These examples are set with displayAs set to "thumb" and a captionAs as "textShort" in getMediaBlockHtml(). The placeholder images are given a maximum width, which keeps them thumbnail size (max of 150px) even if the container is larger and the size of the shared-drive images are their intrinsic sizes.  It is possible to allow these placeholder images to fill their container by increasing the max-width (See <cfset l_styles = "max-width:150px;max-height:auto;"> on line 1121 of media/components/search.cfc.) </h2>
			</div>
			<cfloop query="examples">
				<div class="col-12 col-sm-4 col-md-2 col-xl-2" style="background-color:aquamarine">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="thumb",captionAs="textShort")>
					<div id="mediaBlock#media_id#" class="border rounded">
						#mediablock#
					</div>
				</div>
			</cfloop>
		</div>

		<div class="row">
			<div class="container-fluid mt-5"><h2 class="h4 mb-0"> Background blue.  These examples are set with size="600" captionAs="textFull" (still truncated to 250 chars)in getMediaBlockHtml(). Includes license info. </h2>
			</div>
			<cfloop query="examples">
				<div class="col-12 col-md-6 col-xl-4" style="background-color:aliceblue">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="600",captionAs="textFull")>
					<div id="mediaBlock#media_id#" class="border rounded">
					#mediablock#
					</div>
				</div>
			</cfloop>
		</div>
		
		<div class="row">
			<div class="container-fluid mt-5"><h2 class="h4">Background yellow. If displayAs="full" is used, it goes to our default size of 600px wide. Instead the image size="1500" is put in the getMediaBlockHtml attribute. The captionAs="textShort" (50 chars)</h2>
			</div>
			<div class="col-10 float-left" style="background-color:lemonchiffon">
			<cfset media_id = "1334">
				<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="1500",captionAs="textShort")>
				<div id="mediaFullBlock#media_id#" class="border rounded">
					#mediablock#
				</div>
			</div>
		</div>
		<div class="row">
			<div class="container-fluid mt-5"><h2 class="h4 mb-0"> Background peach.  This example is the intrinsic size of the thumbnail (displayAs="thumb") with only the links (captionAs="textLinks").  </h2>
			</div>
				<div class="col-1 px-0 float-left" style="background-color:peachpuff">
					<cfset media_id = "90914">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="thumb",captionAs="textLinks")>
					<div id="mediaThumbBlock#media_id#" class="border rounded">
						#mediablock#
					</div>
				</div>	
		</div>
		<!--- Cases for the enlarged view (/shared/js/media-zoom.js) that the galleries above don't
		      reach: placement at the window's edge, collapsed panels, dialogs, blocks loaded by AJAX,
		      a large image that fails to load, and turning the view off. --->
		<cfquery name="zoomExamples" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="zoomExamples_result">
			SELECT media_id
			FROM (
				SELECT media_id
				FROM media
				WHERE
					media_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="image">
					AND mime_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="image/jpeg">
					AND mask_media_fg = 0
				ORDER BY media_id DESC
			)
			WHERE ROWNUM <= 5
		</cfquery>
		<cfset zoomMediaId = "">
		<cfloop query="zoomExamples">
			<cfif len(zoomMediaId) EQ 0 AND len(trim(getMediaBlockHtml(media_id="#zoomExamples.media_id#",displayAs="thumb",captionAs="textNone"))) GT 0>
				<cfset zoomMediaId = zoomExamples.media_id>
			</cfif>
		</cfloop>
		<section class="row mt-5 mb-4">
			<div class="col-12">
				<h2 class="h4">Enlarged view (hover and keyboard)</h2>
				<p>
					Hover over an image: an enlarged view appears beside it, on the right when there is room, otherwise on the left.
					Scroll the mouse wheel over the image, or press + and &minus;, to zoom; a lens on the image marks the part shown, and moving the mouse or the arrow keys pan.
					Escape closes the view until the mouse leaves the image.
					Tab to an image's link: the view appears, and the same keys work.
					The keys don't act while typing in a field, and Ctrl + and Ctrl &minus; still zoom the browser.
					On a touch screen the image is a plain link.
				</p>
				<cfif len(zoomMediaId) EQ 0>
					<p class="text-danger">No public JPEG media found for these tests.</p>
				<cfelse>
					<h3 class="h5">Placement</h3>
					<p>The left image's view should open to its right; the right image's, at the window's edge, to its left.</p>
					<div class="d-flex justify-content-between border rounded bg-light p-2">
						<div style="width:150px;">#getMediaBlockHtml(media_id="#zoomMediaId#",displayAs="thumb",captionAs="textNone")#</div>
						<div style="width:150px;">#getMediaBlockHtml(media_id="#zoomMediaId#",displayAs="thumb",captionAs="textNone")#</div>
					</div>

					<h3 class="h5 mt-3">Collapsed panel</h3>
					<p>Hover, then collapse the panel with the keyboard while the view is open: the view should close with it, and open in the right place after the panel is expanded again.</p>
					<button type="button" class="btn btn-xs btn-secondary" data-toggle="collapse" data-target="##zoomTestCollapse" aria-expanded="true" aria-controls="zoomTestCollapse">Show/hide panel</button>
					<div class="collapse show border rounded bg-light p-2 mt-1" id="zoomTestCollapse">
						<div style="width:150px;">#getMediaBlockHtml(media_id="#zoomMediaId#",displayAs="thumb",captionAs="textNone")#</div>
					</div>

					<h3 class="h5 mt-3">Dialog</h3>
					<p>The view should appear above the dialog, not behind it.</p>
					<button type="button" class="btn btn-xs btn-secondary" onclick="openZoomTestDialog('zoomTestDialog');">Open dialog</button>
					<div id="zoomTestDialog" title="Media in a dialog" class="d-none">
						<div style="width:150px;">#getMediaBlockHtml(media_id="#zoomMediaId#",displayAs="thumb",captionAs="textNone")#</div>
					</div>

					<h3 class="h5 mt-3">Loaded by AJAX</h3>
					<p>A block loaded after the page, as on the specimen and media edit pages, should zoom like the others.</p>
					<button type="button" class="btn btn-xs btn-secondary" onclick="getMediaBlockHtml('#zoomMediaId#', 'zoomTestAjaxBlock', 'thumb', 'textShort', '150', 'white');">Load media block</button>
					<div id="zoomTestAjaxBlock" class="border rounded bg-light p-2 mt-1" style="width:170px;min-height:40px;"></div>

					<h3 class="h5 mt-3">Large image that fails to load</h3>
					<p>The view should show the loading indicator, then close, and not open again for this image; nothing should be logged as an error.</p>
					<div class="border rounded bg-light p-2" style="width:170px;">
						<a href="/media/#zoomMediaId#" class="d-block text-center" onfocus="mczMediaZoom.focusLink(this)">
							<img src="/shared/images/Image-x-generic.svg" alt="Placeholder whose large image is missing" width="90" height="90" data-mcz-zoom="/shared/images/noSuchLargeImage.jpg" data-mcz-zoom-scale="4" onpointerenter="mczMediaZoom.pointerEnter(this, event)">
						</a>
					</div>

					<h3 class="h5 mt-3">Turned off</h3>
					<p>As while the specimen page's in-page editor is open: when off, hovering shows nothing.</p>
					<button type="button" class="btn btn-xs btn-secondary" onclick="setZoomTestEnabled(false, 'zoomTestState');">Turn off</button>
					<button type="button" class="btn btn-xs btn-secondary" onclick="setZoomTestEnabled(true, 'zoomTestState');">Turn on</button>
					<output id="zoomTestState" class="ml-2">On</output>
					<div class="border rounded bg-light p-2 mt-1" style="width:170px;">
						#getMediaBlockHtml(media_id="#zoomMediaId#",displayAs="thumb",captionAs="textNone")#
					</div>
					<script>
						/** openZoomTestDialog opens a hidden div as a jQuery UI dialog.
						 * @param dialogId the id of the div, without a leading ##.
						 */
						function openZoomTestDialog(dialogId) {
							$("##" + dialogId).removeClass("d-none").dialog({ modal: true, width: 320 });
						}
						/** setZoomTestEnabled turns the enlarged view on or off and reports it.
						 * @param on true to turn it on.
						 * @param outputId the id of the output element for the state, without a leading ##.
						 */
						function setZoomTestEnabled(on, outputId) {
							mczMediaZoom.setEnabled(on);
							$("##" + outputId).text(on ? "On" : "Off");
						}
					</script>
				</cfif>
			</div>
		</section>
	</main>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
