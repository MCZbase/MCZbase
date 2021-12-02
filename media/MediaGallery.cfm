<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">

	<cfset media_id = "1333">
	
			<script>
				$(document).ready(function() {
				function getMediaBlockHtml(media_id);
				}
			</script>
	<cfset mediablock= getMediaBlockHtml(media_id="#media_id#")>
#mediablock#

	
	
	
	
	
	
<cfinclude template = "/shared/_footer.cfm">