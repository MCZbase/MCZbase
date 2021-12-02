<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">
<cfset media_id = "1333">
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfset mediablock= getMediaBlockHtml(media_id="#media_id#")>
<div class="container-fluid">
	<div class="row">
		<div class="col-12">
			<div id="mediaBlockHtml">
				#mediablock#
			</div>
		</div>
	</div>	
</div>

	
	
	
<cfinclude template = "/shared/_footer.cfm">