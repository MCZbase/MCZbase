<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">
<cfset media_id = "1333">
	<cfinclude template="/media/component/search.cfc">
<cfset mediablock= getMediaBlockHtml(media_id="#media_id#")>

	<div id="mediaBlockHtml">
		#mediablock#
	</div>
	
	
		<a role="button" href="##" id="btn_pane" class="anchorFocus btn btn-xs small py-0" onClick="getMediaBlockHtml(media_id="#media_id#")">
			media
		</a>
	
	
	
<cfinclude template = "/shared/_footer.cfm">