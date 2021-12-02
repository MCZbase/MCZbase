<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">
<cfset media_id = "1333">
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfoutput>

	<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="100%")>
	<div class="container-fluid">
		<div class="row">
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
		</div>
	</div>

</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
