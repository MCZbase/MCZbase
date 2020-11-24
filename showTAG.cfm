<cfinclude template = "/includes/_header.cfm">
<cfset title="View Media TAGs">
<script language="JavaScript" src="/includes/jquery/jquery.imgareaselect.pack.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="/includes/jquery/css/imgareaselect-default.css">
<link rel="stylesheet" type="text/css" href="/includes/jquery/css/ui-lightness/jquery-ui-1.7.2.custom.css">
<script language="JavaScript" src="/includes/jquery/jquery-ui-1.7.2.custom.min.js" type="text/javascript"></script>
<script language="JavaScript" src="/includes/jquery/scrollTo.js" type="text/javascript"></script>
<script language="JavaScript" src="/includes/showTAG.js" type="text/javascript"></script>

<cfoutput>
	<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * 
		from media 
		where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			and MCZBASE.is_media_encumbered(media.media_id) < 1
	</cfquery>
	<cfif (c.media_type is not "image" and c.media_type is not "multi-page document") or c.mime_type does not contain 'image/'>
		<h2>unsupported media type for tags</h2>
	<cfelse>
		<div id="imgDiv"></div>
		<script>
			$(document).ready(function () {		
				loadTAG(#c.media_id#,'#c.media_uri#');
			});
		</script>
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
