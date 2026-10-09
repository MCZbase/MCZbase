<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
<cfif not isdefined("content_url")>
	<cfset content_url="">
</cfif>
<cfinclude template="/includes/functionLib.cfm">

<!--- The same jQuery and jQuery UI as /shared/_header.cfm. --->
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.min.css">
<script type="text/javascript" src="/lib/jquery/jquery-3.5.1.min.js"></script>
<script type="text/javascript" src="/lib/jquery-ui-1.12.1/jquery-ui.min.js"></script>
<script type="text/javascript">
	// The date pickers on the legacy pages were written for these defaults.
	$.datepicker.setDefaults({ dateFormat: "yy-mm-dd", changeMonth: true, changeYear: true, yearRange: "1800:+0", constrainInput: false });
</script>
<script type="text/javascript" src="/includes/ajax.js"></script>
<link rel="stylesheet" type="text/css" href="/includes/style.css" >
<link rel="stylesheet" href="/shared/css/customstyles_jquery-ui.css">

<script language="JavaScript" src="/shared/js/vocabulary_scripts.js" type="text/javascript"></script>
<!--- Temporary file, to allow resolution of Redmine 674 Bugfix to f2fee81  making javascript messageDialog() available to Taxonomy.cfm without adding /shared/js/shared-scripts.js as an include in alwaysInclude.cfm --->
<script language="JavaScript" src="/includes/js/messageDialogWorkaround.js" type="text/javascript"></script>
<!--- script language="JavaScript" src="/shared/js/shared-scripts.js" type="text/javascript"></script --->
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
