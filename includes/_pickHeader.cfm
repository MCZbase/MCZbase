<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"> 
<head>
<cfinclude template="/includes/alwaysInclude.cfm"><!--- keep this stuff accessible from non-header-having files --->
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<!---  Check to see if a session stylesheet is set, otherwise we'll get a call to include the css directory --->
<cfif isDefined(session.stylesheet) and len(trim(session.stylesheet)) >
<cfset ssName = replace(session.stylesheet,".css","","all")>
<!---<link rel="alternate stylesheet" type="text/css" href="/includes/css/#session.stylesheet#" title="#ssName#">--->
</cfif>
<META http-equiv="Default-Style" content="#ssName#">
</head>
<body>
<cf_rolecheck>
