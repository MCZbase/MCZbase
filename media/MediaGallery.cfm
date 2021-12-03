<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfoutput>

	<cfset media_id = "1492277">
	<div class="container-fluid">
		<div class="row my-3">

			<cfset mediablock= getMediaBlockHtml(media_id="#media_id#")>
			<div class="col-5">
				<div id="mediaBlockHtml">
					#mediablock#
				</div>
			</div>
			
			<div class="col-3">
				<div id="mediaBlockHtml">
					#mediablock#
				</div>
			</div>
			
			<div class="col-2">
				<div id="mediaBlockHtml">
					#mediablock#
				</div>
			</div>
				
			<div class="col-1 p-0">
				<div id="mediaBlockHtml">
					#mediablock#
				</div>
			</div>

		</div>
	</div>

</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
