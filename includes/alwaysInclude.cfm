<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
<cfif not isdefined("content_url")>
	<cfset content_url="">
</cfif>
<cfinclude template="/includes/functionLib.cfm">

<cfif isdefined("jquery11")>
<!--- Use jquery 1.11.x --->
<link rel="stylesheet" href="/includes/jquery/jquery-ui-1.11.4.custom/jquery-ui.css">
<link rel="stylesheet" href="/includes/jquery/jquery-ui-1.11.4.custom/jquery-ui.theme.css">
<script type='text/javascript' language="javascript" src='/includes/jquery/1.11.3/jquery-1.11.3.min.js'></script>
<script type='text/javascript' language="javascript" src='/includes/jquery/1.11.3/jquery-migrate-1.2.1.min.js'></script>
<script language="JavaScript" src="/includes/jquery/jquery-ui-1.11.4.custom/jquery-ui.min.js" type="text/javascript"></script>
<script type='text/javascript' language="javascript" src='/includes/ajax.min.js'></script>
<script language="JavaScript" src="/includes/jquery/jquery-ui.datepicker.1.11.4.js" type="text/javascript"></script>
<link rel="stylesheet" href="/shared/css/customstyles_jquery-ui.css">
<!---<link rel="stylesheet" href="/shared/css/custom_styles.css">--->
<cfelse>
<!--- Use jquery 1.3.2 --->
<cfoutput>
<!---  script type='text/javascript' language="javascript" src='#Application.protocol#://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js'></script --->
<script type='text/javascript' language="javascript" src='/includes/jquery/jquery-1.3.2.min.js'></script>
</cfoutput>
<script type='text/javascript' language="javascript" src='/includes/ajax.min.js'></script>
<script language="JavaScript" src="/includes/jquery/jquery.ui.datepicker.min.js" type="text/javascript"></script>
</cfif>
<link rel="stylesheet" type="text/css" href="/includes/style.css" >
<link rel="stylesheet" href="/shared/css/customstyles_jquery-ui.css">
<!---<link rel="stylesheet" href="/shared/css/custom_styles.css">--->


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
