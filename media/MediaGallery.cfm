<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/component/shared.cfc" runOnce="true">
	<cfset media_id = "1333">
	
	
	<cfset mediablock= getMediaBlockHtml(media_id="#media_id#")>
#mediablock#

	
	
	
	
	
	
<cfinclude template = "/shared/_footer.cfm">