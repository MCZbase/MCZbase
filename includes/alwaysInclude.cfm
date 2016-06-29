<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
<cfif not isdefined("content_url")>
	<cfset content_url="">
</cfif>
<cfinclude template="/includes/functionLib.cfm">
<link rel="stylesheet" type="text/css" href="/includes/style.css" >
<cfif isdefined("jquery11")>
<!--- Use jquery 1.11.x --->
<link rel="stylesheet" href="/includes/jquery/jquery-ui-1.11.4.custom/jquery-ui.css">
<link rel="stylesheet" href="/includes/jquery/jquery-ui-1.11.4.custom/jquery-ui.theme.css">
<script language="JavaScript" src="/includes/jquery/jquery-ui-1.11.4.custom/jquery-ui.min.js" type="text/javascript"></script>
<script type='text/javascript' language="javascript" src='/includes/jquery/1.11.3/jquery-1.11.3.min.js'></script>
<script type='text/javascript' language="javascript" src='/includes/jquery/1.11.3/jquery-migrate-1.2.1.min.js'></script>
<script type='text/javascript' language="javascript" src='/includes/ajax.min.js'></script>
<script language="JavaScript" src="/includes/jquery/jquery-ui.datepicker.1.11.4.js" type="text/javascript"></script>
<cfelse>
<!--- Use jquery 1.3.2 --->
<script type='text/javascript' language="javascript" src='http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js'></script>
<script type='text/javascript' language="javascript" src='/includes/ajax.min.js'></script>
<script language="JavaScript" src="/includes/jquery/jquery.ui.datepicker.min.js" type="text/javascript"></script>
</cfif>
<script type="text/javascript">
function getMCZDocs(url,anc) {
	var url;
	var anc;
	var baseUrl = "https://code.mcz.harvard.edu/wiki/index.php/";
	var extension = "";
	var fullURL = baseUrl + url + extension;
		if (anc != null) {
			fullURL += "#" + anc;
		}
	siteHelpWin=windowOpener(fullURL,"HelpWin","width=1024,height=640, resizable,scrollbars,location,toolbar");
}
</script>