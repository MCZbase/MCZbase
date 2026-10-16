<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
<cfif not isdefined("content_url")>
	<cfset content_url="">
</cfif>
<cfinclude template="/includes/functionLib.cfm">	
<link rel="stylesheet" type="text/css" href="/includes/style.css" >
<!--- The same jQuery and jQuery UI as /shared/_header.cfm. --->
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.min.css">
<script type="text/javascript" src="/lib/jquery/jquery-3.5.1.min.js"></script>
<script type="text/javascript" src="/lib/jquery-ui-1.12.1/jquery-ui.min.js"></script>
<script type="text/javascript" src="/includes/ajax.js"></script>


   
