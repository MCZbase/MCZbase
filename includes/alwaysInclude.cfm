<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
<cfif not isdefined("content_url")>
	<cfset content_url="">
</cfif>
<cfinclude template="/includes/functionLib.cfm">
<link rel="stylesheet" type="text/css" href="/includes/style.css" >
<script language="JavaScript" src="/includes/jquery/jquery-ui-1.11.4.custom/jquery-ui.css" type="text/javascript"></script>
<script type='text/javascript' language="javascript" src='/includes/jquery/1.11.3/jquery-1.11.3.min.js'></script>
<script type='text/javascript' language="javascript" src='/includes/jquery/1.11.3/jquery-migrate-1.2.1.min.js'></script>
<script type='text/javascript' language="javascript" src='/includes/ajax.min.js'></script>
<script language="JavaScript" src="/includes/jquery/jquery-ui.datepicker.1.11.4.js" type="text/javascript"></script>
