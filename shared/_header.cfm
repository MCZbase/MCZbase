<!---
_header.cfm

Copyright 2019-2021 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfset headerPath = "shared"><!--- Identify which header has been included --->
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<cfoutput>
<meta name="description" content="#Application.meta_description#">
<meta name="keywords" content="#Application.meta_keywords#">
<meta name="author" content="Museum of Comparative Zoology, Harvard University">
<link rel="SHORTCUT ICON" href="/shared/images/favicon.ico">
<cfif not isdefined("pageTitle")>
	<!--- Long term we can set a default value, short term throw an exception to make developers add pageTitle to invoking pages. --->
	<cfthrow message="Error: shared/_header.cfm was included from a page that does not set the required pageTitle.">
</cfif>
<title>#pageTitle# | MCZbase</title>
<cfinclude template="/shared/functionLib.cfm">
<!--- Easy to overlook this shared function file ---> 
<!--- include stylesheets and javascript library files --->
<link rel="stylesheet" href="/lib/bootstrap/bootstrap-4.5.0-dist/css/bootstrap.min.css"><!---needed for overall look--->
<link rel="stylesheet" href="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/styles/jqx.base.css"><!--- needed for jqxwidgets to work --->
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.css"><!--- Use JQuery-UI widgets when available, only use jqwidgets for extended functionality --->
<link rel="stylesheet" href="/lib/fontawesome/fontawesome-free-5.5.0-web/css/all.css"><!-- Provides account, magnifier, and cog icons-->
<!--- NOTE, use either the fontawesome css implementation or the js implementation, not both.  CSS is substantially smaller, JS is minimum 1 MB --->
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.min.css" /><!--- Library supporting a multiselect widget based on jquery-ui.  --->
<!--- Multiselect widget used on specimen search, probably not needed everywhere ---> 
<!--- TODO: Replace with jqx multiselect instead of using additional library --->
<link rel="stylesheet" href="/lib/misc/jquery-ui-multiselect-widget-3.0.0/css/jquery.multiselect.css" />
<link rel="stylesheet" href="/lib/misc/jquery-ui-multiselect-widget-3.0.0/css/jquery.multiselect.filter.css" />

<link rel="stylesheet" href="/shared/css/header_footer_styles.css">
<link rel="stylesheet" href="/shared/css/custom_styles.css">
<link rel="stylesheet" href="/shared/css/customstyles_jquery-ui.css">
<script type="text/javascript" src="/lib/jquery/jquery-3.5.1.min.js"></script> 
<script type="text/javascript" src="/lib/jquery-ui-1.12.1/jquery-ui.js"></script><!--- Use JQuery-UI widgets when available. ---> 
<!---<script type="text/javascript" src="/lib/bootstrap/js/bootstrap-multiselect.js"></script>---> 
<script type="text/javascript" src="/lib/bootstrap/bootstrap-4.5.0-dist/js/bootstrap.bundle.min.js"></script><!--- popper is in the bundle---> 
<!---<script type="text/javascript" src="/lib/bootstrap/js/bootstrap-select.min.js"></script>---> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxcore.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxdata.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxdata.export.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.js"></script> <!--- jqxgrid is the primary reason we are including jqwidgets ---> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.filter.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.edit.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.sort.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.selection.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.export.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.storage.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxcombobox.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.pager.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.grouping.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.aggregates.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.columnsresize.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxgrid.columnsreorder.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxscrollbar.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxwindow.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/globalization/globalize.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxbuttons.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxlistbox.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxdropdownlist.js"></script>
<!--- All jqwidgets below are suspect, include only if they provide functionality not available in jquery-ui.  ---> 
<!--- TODO: Remove all jqwidgets where functionality can be provided by jquery-ui ---> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxmenu.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxdatetimeinput.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxdate.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxslider.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxpanel.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxinput.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxdragdrop.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxcalendar.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxtree.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxinput.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxexport.js"></script> 
<!---- End supspect block ----> 

<!---- JQX WSIWG text editor ---->
<cfif isdefined("includeJQXEditor") AND includeJQXEditor IS 'true'>
	<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxscrollbar.js"></script>
	<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxdropdownbutton.js"></script>
	<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxcolorpicker.js"></script>
	<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxeditor.js"></script>
	<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxtooltip.js"></script>
	<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver12.0.4/jqwidgets/jqxcheckbox.js"></script>
</cfif>

<script type="text/javascript" src="/shared/js/shared-scripts.js"></script>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<script type="text/javascript" src="/specimens/js/specimens.js"></script> 
	<script type="text/javascript" src="/shared/js/internal-scripts.js"></script> 
	<script type="text/javascript" src="/shared/js/vocabulary_scripts.js"></script>
</cfif>

<!--- Multiselect widget used on specimen search, probably not needed everywhere ---> 
<!--- TODO: Replace with jqx multiselect instead of using additional library --->
<script type="text/javascript" src="/lib/misc/jquery-ui-multiselect-widget-3.0.0/src/jquery.multiselect.js"></script> 
<script type="text/javascript" src="/lib/misc/jquery-ui-multiselect-widget-3.0.0/src/jquery.multiselect.filter.js"></script>
	<script type="text/javascript" src="/specimens/js/specimens.js"></script>
<cfif isdefined("addheaderresource")>
	<cfif addheaderresource EQ "feedreader">
		<script type="text/javascript" src="/lib/misc/jquery-migrate-1.0.0.js"></script> 
		<script type="text/javascript" src="/lib/misc/jquery.jfeed.js"></script>
	</cfif>
</cfif>
<cfif CGI.script_name CONTAINS "/transactions/" OR CGI.script_name IS "/Transactions.cfm">
	<script type="text/javascript" src="/transactions/js/transactions.js"></script>
</cfif>
<cfif CGI.script_name CONTAINS "/media/" OR CGI.script_name IS "/Media.cfm">
	<script type="text/javascript" src="/media/js/media.js"></script>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
		<script type="text/javascript" src="/transactions/js/transactions.js"></script>
	</cfif>
</cfif>
<cfif CGI.script_name IS "/Specimens.cfm" OR CGI.script_name IS "/Transactions.cfm">
	<script type="text/javascript" src="/shared/js/tabs.js"></script>
</cfif>
<cfif CGI.script_name CONTAINS "/taxonomy/" OR CGI.script_name IS "/Taxa.cfm" OR CGI.script_name is "/Specimens.cfm">
	<script type="text/javascript" src="/taxonomy/js/taxonomy.js"></script>
</cfif>
<cfif CGI.script_name CONTAINS "/agents/">
	<script type="text/javascript" src="/agents/js/agents.js"></script>
</cfif>
<cfif not isdefined("session.header_color")>
	<cfif NOT isDefined('setDbUser')>
		<cfinclude template="/shared/loginFunctions.cfm">
	</cfif>
	<cfset setDbUser()>
</cfif>
</head>
<body class="default">
<cfset header_color = Application.header_color>
<cfset collection_link_color = Application.collectionlinkcolor>
<cfif not isdefined("Session.gitBranch")>
<!--- determine which git branch is currently checked out --->
<!--- TODO: Move to initSession --->
	<cftry>
		<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
		<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
	<cfcatch>
		<cfset gitBranch = "unknown">
	</cfcatch>
	</cftry>
	<cfset Session.gitBranch = gitBranch>
</cfif>
<!--- Workaround for current production header/collectionlink color values being different from redesign values  --->
<cfif findNoCase('redesign',Session.gitBranch) EQ 0>
	<!---  TODO: Remove this block when rollout of redesign is complete (when Application.cfc from redesign is used in master). --->
	<cfset header_color = "##A51C30">
	<cfset collection_link_color = "white">
	<cfif Application.serverName contains "-test">
		<cfset header_color = "##ADE1EA" >
		<cfset collection_link_color = "##94131C" >
		<cfelseif Application.serverName contains "-dev">
		<cfset header_color = "##CAEAAD">
		<cfset collection_link_color = "##94131C" />
	</cfif>
</cfif>
<!--- End workaround ---> 

<a href="##content" class="sr-only sr-only-focusable btn-link mx-3 d-block px-2 py-1" aria-label="Skip to main content" title="skip navigation">Skip to main content</a>
<header id="header" role="heading" class="border-bottom">
	<div class="branding clearfix bg-black">
		<div class="branding-left justify-content-start"> <a href="http://www.harvard.edu/" aria-label="link to Harvard website"> <img class="shield" src="/shared/images/Harvard_shield-University.png" alt="Harvard University Shield"> <span class="d-inline-block parent">Harvard University</span> </a> </div>
		<div class="branding-right justify-content-end"> <a href="https://www.harvard.edu/about-harvard" class="font-weight-bold" aria-label="link to Harvard website">HARVARD.EDU</a> </div>
	</div>
	<div class="navbar justify-content-start navbar-expand-md navbar-expand-sm navbar-harvard harvard_banner border-bottom border-dark"> 
		<!--- Obtain header_color and matching link color for this list from server specific values set in Application.cfm  --->
		<!---  WARNING: Styles set on these elements must not set the color, this is set in a server specific variable from Application.cfc, with modifications above --->
		<ul class="navbar col-11 col-sm-7 col-md-7 col-lg-8 p-0 m-0" style="background-color: #header_color#; ">
			<li class="nav-item mcz2"> <a href="https://www.mcz.harvard.edu/" target="_blank" rel="noreferrer" style="color: #collection_link_color#;" >Museum of Comparative Zoology</a> </li>
			<!---  WARNING: Application and Session.collection_link_text contain a </span> tag and must currently be preceeded by a <span> tag, see Application.cfc --->
			<li class="nav-item mczbase my-1 py-0"> <a href="/" target="_blank" style="color: #collection_link_color#" ><span style='font-size: 1.1rem;'>#session.collection_link_text#</a> </li> <!--- close span is in collection_collection_link_text --->
		</ul>
		<ul class="navbar col-12 col-sm-5 col-md-5 col-lg-4 p-0 m-0 d-flex justify-content-end">
			<li class="nav-item d-flex align-content-end"> <a href="https://mcz.harvard.edu" aria-label="link to MCZ website"> <img class="mcz_logo_krono" src="/shared/images/mcz_logo_white_left.png" width="160" alt="mcz kronosaurus logo with link to website"></a> </li>
		</ul>
	</div>
	<noscript>
	<div class="container-fluid bg-light">
		<div class="row">
			<div class="col-12 pb-2">
				<h1 class="h2 text-center text-danger">MCZbase requires Javascript to function.</h1>
				<nav class="navbar navbar-expand-lg navbar-light bg-light p-0">
					<ul class="navbar-nav mx-auto">
						<li class="nav-item"> <a class="nav-link mr-2" href="/SpecimenSearchHTML.cfm">Minimal Specimen Search</a></li>
						<li class="nav-item"><a class="nav-link mr-2" href="/BrowseHTML.cfm">Browse Data</a></li>
						<li class="nav-item"><a class="nav-link mr-2" href="/https://mcz.harvard.edu/database">About MCZbase</a></li>
						<cfif isdefined("session.username") and len(#session.username#) gt 0>
							<a href="/login.cfm?action=signOut" class="btn btn-outline-success py-0 px-2" aria-label="logout">Log out #session.username#
							<cfif isdefined("session.last_login") and len(#session.last_login#)gt 0>
								<small>(Last login: #dateformat(session.last_login, "dd-mmm-yyyy, hh:mm")#)</small>
							</cfif>
							</a>
							<cfelse>
							<form name="logIn" method="post" action="/login.cfm" class="m-0 form-login">
								<input type="hidden" name="action" value="signIn">
								<div class="login-form" id="header_login_form_div">
									<label for="username" class="sr-only"> Username:</label>
									<input type="text" name="username" id="username" placeholder="username" class="loginButtons" style="width:100px;">
									<label for="password" class="mr-1 sr-only"> Password:</label>
									<input type="password" id="password" name="password" autocomplete="current password" placeholder="password" title="Password" class="loginButtons" style="width: 80px;">
									<input type="submit" value="Log In" id="login" class="btn-primary loginButtons" aria-label="click to login">
								</div>
							</form>
						</cfif>
					</ul>
				</nav>
			</div>
		</div>
	</div>
	</noscript>
	<div class="container-fluid bg-light px-0" style="display: none;" id="mainMenuContainer">
		<!--- display turned on with javascript below ---> 
		<!---	
			Test for redesign checkout is required for continued integration, as the production menu
			must point to files present on production while the redesign menu points at their replacements in redesign
		--->
		<cfif findNoCase('redesign',Session.gitBranch) GT 0>
			<!--- checkout is redesign, redesign2, or similar --->
			<cfset targetMenu = "redesign">
		<cfelse>
			<!--- checkout is master, integration, test, and other non-redesign branches --->
			<cfset targetMenu = "production">
		</cfif>
		<script>
			// Keyboard shortcut for Search
			document.addEventListener ("keydown", function (evt) {
				if (evt.altKey && evt.key === "m") {  
					evt.preventDefault();
					evt.stopPropagation();
					$('##searchDropdown').click();	
					$('##specimenMenuItem').focus();	
					return false;
				}
			});

		</script>

		<nav class="navbar navbar-light bg-transparent navbar-expand-xl py-0" id="main_nav">
			<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="##navbar_toplevel_div" aria-controls="navbar_toplevel_div" aria-expanded="false" aria-label="Toggle navigation"> <span class="navbar-toggler-icon"></span> </button>
			<div class="collapse navbar-collapse" id="navbar_toplevel_div">
				<ul class="navbar-nav nav-fill mr-auto">
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"public")>
					<li class="nav-item dropdown"> 
						<a class="nav-link dropdown-toggle px-3 text-left" href="##" id="searchDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" aria-label="Search shorcut=alt+m" title="Search (Alt+m)" >Search</a>
						<ul class="dropdown-menu border-0 shadow" aria-labelledby="aboutDropdown">
							<li> 	
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" id="specimenMenuItem" href="/SpecimenSearch.cfm">Specimens</a> <!--- old --->
								<cfelse>
									<a class="dropdown-item" id="specimenMenuItem" href="/Specimens.cfm">Specimens</a>
								</cfif>				
								<cfif targetMenu EQ "redesign">
									<a class="dropdown-item" href="/specimens/SpecimenBrowse.cfm">Browse Specimens By Category</a>
								</cfif>
								<a class="dropdown-item" href="/Taxa.cfm">Taxonomy</a>
								<a class="dropdown-item" href="/media/findMedia.cfm">Media</a>
								<a class="dropdown-item" href="/MediaSearch.cfm">Media (old)</a><!--- old --->
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href="/showLocality.cfm">Places</a>
								<cfelse>
									<a class="dropdown-item bg-warning" href="">Places</a>
								</cfif>	
								<a class="dropdown-item" target="_top" href="/Agents.cfm">Agents</a>
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href="/SpecimenUsage.cfm">Publications/Projects</a><!--- old --->
								<cfelse>
									<a class="dropdown-item bg-warning" href="">Publications</a>
									<a class="dropdown-item bg-warning" href="">Projects</a>
								</cfif>	
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
									<cfif targetMenu EQ "production">
										<a class="dropdown-item" href="/info/reviewAnnotation.cfm">Annotations</a><!---old - but relocated, not in this menu on current prd --->
										<a class="dropdown-item" href="/tools/userSQL.cfm">SQL Queries</a> <!--- old - but relocated, not in this menu on current prd--->
									<cfelse>
										<a class="dropdown-item bg-warning" href="">Annotations</a>
										<a class="dropdown-item bg-warning" href="">SQL Queries</a> 
									</cfif>
								</cfif>
							 </li>
						</ul>
					</li>
					</cfif>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
						<li class="nav-item dropdown">
							<a class="nav-link dropdown-toggle px-3 text-left" href="" id="aboutDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Data Entry</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="aboutDropdown">
								<li class="d-md-flex align-items-start justify-content-start">
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Create New Record</div>
										
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/DataEntry.cfm">Enter Specimen Data</a><!--- old --->
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Specimen</a>
											</cfif>
										
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/media.cfm?action=newMedia">Media</a><!--- old --->
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Media</a>
											</cfif>
										</cfif>
										<cfif isdefined("session.roles") and ( listcontainsnocase(session.roles,"manage_agents") or listcontainsnocase(session.roles,"MANAGE_AGENT_RANKING") or listcontainsnocase(session.roles,"ADMIN_AGENT_RANKING "))>
											<a class="dropdown-item" href="/agents/editAgent.cfm?action=new">Agent</a>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_publications")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Publication.cfm?action=newPub">Publication</a><!--- old --->
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Publication</a> 
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Project.cfm?action=makeNew">Projects</a><!--- old --->
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Projects</a> 
											</cfif>
										</cfif>
									</div>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Bulkload</div>
										<a class="dropdown-item" href="/Bulkloader/bulkloaderBuilder.cfm">Bulkload Builder</a>							
										<a class="dropdown-item" href="/Bulkloader/browseBulk.cfm">Browse and Edit</a>
										<a class="dropdown-item" href="/Bulkloader/bulkloader_status.cfm">Bulkloader Status</a>
										<a class="dropdown-item" href="/bulkloading/Bulkloaders.cfm">Bulkloaders</a>				
										<a class="dropdown-item" href="/tools/PublicationStatus.cfm">Publication Staging</a>
										<a class="dropdown-item" href="/tools/DataLoanBulkload.cfm">Data Loan Items</a>
									</div>
								</li>
							</ul>
						</li>
					</cfif>	
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
						<li class="nav-item dropdown">
							<a class="nav-link dropdown-toggle px-3 text-left" href="" id="manageDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Manage Data</a>
	      	        	<ul class="dropdown-menu border-0 shadow" aria-labelledby="manageDropdown">	
							
								<li class="d-md-flex align-items-start justify-content-start">		
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
									<div>
									<div class="h5 dropdown-header px-4 text-danger">Search &amp; Edit</div>
									
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Locality.cfm?action=findHG">Geography</a> 
										<cfelse>
											<a class="dropdown-item bg-warning" href="">Geography</a>
										</cfif>
											
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Locality.cfm?action=findLO">Localities</a> 
										<cfelse>
											<a class="dropdown-item bg-warning" href="">Localities</a>
										</cfif>
																					
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Locality.cfm?action=findCO">Collecting Events</a> 
										<cfelse>
											<a class="dropdown-item bg-warning" href="">Collecting Events</a>
										</cfif>
									
										<a class="dropdown-item" href="/vocabularies/CollEventNumberSeries.cfm">Collecting Event Number Series</a> 
										<a class="dropdown-item" href="/Agents.cfm">Agents</a> 
									</div>
								</cfif>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
									<div>
								
										<div class="h5 dropdown-header px-4 text-danger">Create</div>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_geography")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Locality.cfm?action=newHG">Geography</a> 
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Geography</a> 
											</cfif>
										</cfif>		
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Locality.cfm?action=newHG">Locality</a> 
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Locality</a> 
											</cfif>
										</cfif>
								
										<a class="dropdown-item" href="/vocabularies/CollEventNumberSeries.cfm?action=new">Collecting Event Number Series</a> 
										<a class="dropdown-item" href="/agents/editAgent.cfm?action=new&agent_type=person">Person</a> 
										<a class="dropdown-item" href="/agents/editAgent.cfm?action=new&agent_type=organization">Organization Agent</a> 
									</div>
									</cfif>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_collection")>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Manage</div>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_collection")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Encumbrances.cfm">Encumbrances</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Encumbrances</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/info/reviewAnnotation.cfm">Annotations</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Annotations</a>
											</cfif>
										</cfif>
										<cfif isdefined("session.roles") and ( listcontainsnocase(session.roles,"manage_agents") or listcontainsnocase(session.roles,"MANAGE_AGENT_RANKING") or listcontainsnocase(session.roles,"ADMIN_AGENT_RANKING "))>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Admin/agentMergeReview.cfm">Review Pending Merges</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="">Review Pending Agent Merges</a>
										</cfif>	
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Admin/killBadAgentDups.cfm">Merge bad duplicate agents</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="">Merge bad duplicate agents</a>
										</cfif>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_taxonomy")>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/tools/parent_child_taxonomy.cfm">Sync Parent/Child Taxonomy</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="">Sync Parent/Child Taxonomy</a>
										</cfif>									
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/tools/pendingRelations.cfm">Pending Relationships</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="">Pending Relationships</a>
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/tools/sqlTaxonomy.cfm">SQL Taxonomy</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="">SQL Taxonomy</a>
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/tools/BulkloadTaxonomy.cfm">Bulk Taxonomy</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="">Bulk Taxonomy</a>
										</cfif>
										</cfif>
									</div>
									</cfif>
								</cfif>
								</li>
							</ul>
						</li>
					</cfif>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
						<!--- TODO: Review roles and permissions --->
						<li class="nav-item dropdown">
							<a class="nav-link dropdown-toggle px-3 text-left" href="" id="curationDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Curation</a>
		              		<ul class="dropdown-menu border-0 shadow" aria-labelledby="curationDropdown">		
								<li class="d-md-flex align-items-start justify-content-start">		
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Search &amp; Edit</div>
										<a class="dropdown-item" href="/grouping/NamedCollection.cfm">Named Group</a>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/ContainerBrowse.cfm">Browse Storage Locations</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Browse Storage Locations</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/findContainer.cfm">Find Storage Location/Container</a> 
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Find Storage Location/Container</a>
											</cfif>
										</cfif>
									</div>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Create</div>
										<a class="dropdown-item" href="/grouping/NamedCollection.cfm?action=new">Named Group</a>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
											<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/editContainer.cfm?action=newContainer">Storage Location/Create Container</a> 
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Storage Location/Create Container</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/CreateContainersForBarcodes.cfm">Create Container Series</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Create Container Series</a>
											</cfif>
										</cfif>
									</div>
									</cfif>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
										<div>
											<div class="h5 dropdown-header px-4 text-danger">Manage</div>
																					
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/moveContainer.cfm">Move Container</a> 
											<cfelse>
												<a class="dropdown-item stillNeedToDo" href="">Move Container</a> 
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/batchScan.cfm">Batch Scan</a>
											<cfelse>
												<a class="dropdown-item stillNeedToDo" href="">Batch Scan</a>
											</cfif>	
								
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/labels2containers.cfm">Label > Container</a> 
											<cfelse>
												<a class="dropdown-item  stillNeedToDo" href="">Label > Container</a> 
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/part2container.cfm">Put Parts in Containers</a> 
											<cfelse>
												<a class="dropdown-item stillNeedToDo" href="">Put Parts in Containers</a> 
											</cfif>
								
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/part2container.cfm">Clear Part Flags</a> 
											<cfelse>
												<a class="dropdown-item stillNeedToDo" href="">Clear Part Flags</a> 
											</cfif>
												
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/LoadBarcodes.cfm">Upload Scan File</a> 
											<cfelse>
												<a class="dropdown-item stillNeedToDo" href="">Upload Scan File</a> 
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/tools/BulkloadContEditParent.cfm">Bulk Edit Container</a> 
											<cfelse>
												<a class="dropdown-item stillNeedToDo" href="">Bulk Edit Container</a> 
											</cfif>
										</div>
									</cfif>
									</cfif>
								</li>
							</ul>
						</li>
					</cfif>
					<cfif isdefined("session.roles") and ( listcontainsnocase(session.roles,"manage_transactions") or listcontainsnocase(session.roles,"manage_permits") or listcontainsnocase(session.roles,"admin_transactions") or listcontainsnocase(session.roles,"admin_permits") )>
						<li class="nav-item dropdown">
							<a class="nav-link dropdown-toggle px-3 text-left" href="" id="transactionDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Transactions</a>
	              			<ul class="dropdown-menu border-0 shadow" aria-labelledby="transactionDropdown">			
									<li class="d-md-flex align-items-start justify-content-start">		
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Search &amp; Edit</div>							
										<a class="dropdown-item" href="/Transactions.cfm?action=findAll">All Transactions</a>
										<a class="dropdown-item" href="/Transactions.cfm?action=findAccessions">Accessions</a>
										<a class="dropdown-item" href="/Transactions.cfm?action=findLoans">Loans</a> 
										<a class="dropdown-item" href="/Transactions.cfm?action=findBorrows">Borrows</a> 
										<a class="dropdown-item" href="/Transactions.cfm?action=findDeaccessions">Deacessions</a> 
										<a class="dropdown-item" href="/transactions/Permit.cfm">Permissions &amp; Rights</a> 
									</div>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Create New Record</div>
										<a class="dropdown-item" href="/transactions/Accession.cfm?action=new">Accession</a> 
										<a class="dropdown-item" href="/transactions/Loan.cfm?action=newLoan">Loan</a> 
										<a class="dropdown-item" href="/transactions/Borrow.cfm?action=new">Borrow</a> 
										<a class="dropdown-item" href="/transactions/Deaccession.cfm?action=new">Deaccession</a> 
										<a class="dropdown-item" href="/transactions/Permit.cfm?action=new">Permissions &amp; Rights</a> 
									</div>
									</cfif>
									</li>
							</ul>
						</li>
					</cfif>
					<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle px-3 text-left" href="" id="reportDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Review Data</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="reportDropdown">			
									<li class="d-md-flex align-items-start justify-content-start">		
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Reports & Statistics</div>
										<a class="dropdown-item" href="/reporting/Reports.cfm">List of Reports</a>
										<a class="dropdown-item" href="/info/queryStats.cfm">Query Statistics</a>
									</div>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Aggregators</div>
										<a class="dropdown-item" target="_blank" href="https://www.gbif.org/occurrence/map?dataset_key=4bfac3ea-8763-4f4b-a71a-76a6f5f243d3">View MCZ data in GBIF</a>
										<a class="dropdown-item" target="_blank" href="https://portal.idigbio.org/portal/search?rq={%22recordset%22:%22271a9ce9-c6d3-4b63-a722-cb0adc48863f%22}">View MCZ data in iDigBio</a>
									</div>
								</li>
							</ul>
						</li>
					<cfif isdefined("session.roles") and ( listcontainsnocase(session.roles,"manage_codetables") or listcontainsnocase(session.roles,"dba") or listcontainsnocase(session.roles,"global_admin") )>
						<li class="nav-item dropdown">
							<a class="nav-link dropdown-toggle px-3 text-left" href="##" id="adminDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Admin</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="adminDropdown">
								<li class="d-md-flex align-items-start justify-content-start">		
									<!--- TODO: Review administrative functions --->
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_codetables")>
									<div>
										
										<div class="h5 dropdown-header px-4 text-danger">Data</div>
										
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/CodeTableEditor.cfm">Code Table Editor</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Code Table Editor</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/info/geol_hierarchy.cfm">Geology Attributes Hierarchy</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Geology Attributes Hierarchy</a>
											</cfif>
										<!--- TODO: Need another role for report management  --->
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Reporter.cfm">Label/Report Management</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Label/Report Management</a>
											</cfif>
									
										<!--- TODO: are the rest of these DBA or another role?  --->
									
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/tools/downloadData.cfm">Download Tables</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Download Tables</a>
											</cfif>
									
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
											<a class="dropdown-item" href="/Admin/dumpAll.cfm">Dump Coldfusion Vars</a>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item"  href="/ScheduledTasks/index.cfm">Scheduled Tasks</a>
											<cfelse>
												<a class="dropdown-item"  href="">Scheduled Tasks</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item"  href="/tools/imageList.cfm">Image List</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Image List</a>
											</cfif>
										</cfif>
									</div>
									</cfif>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
									<div>
								
									<div class="h5 dropdown-header px-4 text-danger">Users/Privileges</div>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Admin/ActivityLog.cfm">Audit SQL</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="">Audit SQL</a>
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/AdminUsers.cfm">MCZbase User Access</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="">MCZbase User Access</a>
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/tools/access_report.cfm?action=role">User Role Report</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="">User Role Report</a>
										</cfif>
										<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Admin/user_roles.cfm">Database Role Definitions</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Database Role Definitions</a>
										</cfif>	
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
<!---											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Admin/form_roles.cfm">Form Permissions</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Form Permissions</a>
											</cfif>--->
											<a class="dropdown-item" href="/Admin/blacklist.cfm">Manage Blocklist</a>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Admin/manage_user_loan_request.cfm">User Loan Management</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">User Loan Management</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Admin/user_report.cfm">List of All Users</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">List of All Users</a>
											</cfif>
										</cfif>
									</div>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"GLOBAL_ADMIN")>
										<div>
											<div class="h5 dropdown-header px-4 text-danger">Application</div>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Admin/Collection.cfm">Manage Collection</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Manage Collection</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Admin/redirect.cfm">Redirects</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Redirects</a>
											</cfif> 
											<a class="dropdown-item" href="/CFIDE/administrator/">Manage Coldfusion</a>
										</div>
									</cfif>
									</cfif>
								</li>
							</ul>
						</li>
					</cfif>
					</cfif>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"public")>
					<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle px-3 text-left" href="##" id="helpDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Help</a>
						<ul class="dropdown-menu border-0 shadow" aria-labelledby="helpDropdown">
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
								<a class="dropdown-item" href="https://code.mcz.harvard.edu/wiki/index.php/Main_Page">Using MCZbase (Wiki Support)</a>
							</cfif>
							<a class="dropdown-item" href="https://mcz.harvard.edu/database">About MCZbase</a>
							<a class="dropdown-item" href="/vocabularies/ControlledVocabulary.cfm">Controlled Vocabularies</a>
							<a class="dropdown-item" href="/Collections/index.cfm">Holdings</a>
							<cfif targetMenu EQ "production">
								<a class="dropdown-item" href="/info/api.cfm">API</a>
							<cfelse>
								<a class="dropdown-item bg-warning" href="">API</a>
								<a class="dropdown-item bg-warning" href="">Technical Details</a>
							</cfif>
						</ul>
					</li>
											</cfif>
				</ul>
				<ul class="navbar-nav ml-auto">
					<cfif isdefined("session.username") and len(#session.username#) gt 0>
						<li class="nav-item dropdown mr-xl-0"> <a id="dropdownMenu5" href="" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" class="nav-link dropdown-toggle px-3 px-xl-2 text-left">Account
							<cfif isdefined("session.username") and len(#session.username#) gt 0 and session.roles contains "public">
								<i class="fas fa-user-check color-green"></i>
								<cfelse>
								<i class="fas fa-user-cog text-body"></i>
							</cfif>
							</a>
							<ul aria-labelledby="dropdownMenu5" class="dropdown-menu border-0 shadow">
								<li>
									<cfif session.roles contains "coldfusion_user">
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/myArctos.cfm">User Profile</a>
										<cfelse>
											<a href="/UserProfile.cfm?action=nothing" class="dropdown-item">User Profile</a>
										</cfif>
										<cfif targetMenu EQ "redesign">
											<a href="" class="dropdown-item">Settings</a>
										</cfif>
										<cfif targetMenu EQ "production">
											<a href="/saveSearch.cfm?action=manage" class="dropdown-item">Saved Searches</a>
										<cfelse>
											<a href="" class="dropdown-item">Saved Searches</a>
										</cfif>
										<cfif targetMenu EQ "redesign">
											<a href="" class="dropdown-item">Saved Search Queries</a>
										</cfif>
									</cfif>
								</li>	
							</ul>
						</li>
					</cfif>
			
				</ul>
			</div>
			<cfif isdefined("session.username") and len(#session.username#) gt 0>
						<form class="form-inline logout-style" name="signOut" method="post" action="/login.cfm">
							<input type="hidden" name="action" value="signOut">
							<button class="btn btn-outline-success logout" aria-label="logout" onclick="signOut.action.value='signOut';submit();" target="_top">Log out #session.username#
							<cfif isdefined("session.last_login") and len(#session.last_login#)gt 0>
								<small>(Last login: #dateformat(session.last_login, "dd-mmm-yyyy, hh:mm")#)</small>
							</cfif>
							</button>
						</form>
						<cfelse>
						<cfif isdefined("gotopage") and len(gotopage) GT 0>
							<cfset gtp = gotopage>
							<cfelse>
							<cfif isdefined("cgi.REDIRECT_URL") and len(cgi.REDIRECT_URL) gt 0>
								<cfset gtp=replace(cgi.REDIRECT_URL, "//", "/")>
								<cfelse>
								<cfset requestData = #GetHttpRequestData()#>
								<cfif isdefined("requestData.headers.referer") and len(requestData.headers.referer) gt 0>
									<cfset gtp=requestData.headers.referer>
									<cfelse>
									<cfset gtp=replace(cgi.SCRIPT_NAME, "//", "/")>
								</cfif>
							</cfif>
						</cfif>
						<cfif gtp EQ '/errors/forbidden.cfm'>
							<cfset gtp = "/UserProfile.cfm">
						</cfif>
						<form name="logIn" method="post" action="/login.cfm" class="m-0 form-login">
							<input type="hidden" name="action" value="signIn">
							<input type="hidden" name="gotopage" value="#gtp#">
							<div class="login-form" id="header_login_form_div">
								<label for="username" class="sr-only"> Username:</label>
								<input type="text" name="username" id="username" placeholder="username" class="loginfields d-inline loginButtons loginfld1">
								<label for="password" class="mr-1 sr-only"> Password:</label>
								<input type="password" id="password" name="password" autocomplete="current password" placeholder="password" title="Password" class="loginButtons loginfields d-inline loginfld2">
								<label for="login" class="mr-1 sr-only"> Password:</label>
								<input type="submit" value="Log In" id="login" class="btn-primary loginButtons"  onClick="logIn.action.value='signIn';submit();" aria-label="click to login">
								<label for="create_account" class="mr-1 sr-only"> Password:</label>
								<input type="submit" value="Register" class="btn-primary loginButtons" id="create_account" onClick="logIn.action.value='newUser';submit();" aria-label="click to create new account">
							</div>
						</form>
					</cfif>
		</nav>
	</div>
	<!-- container //  --> 
	<script>
		document.getElementById("mainMenuContainer").style.display = "block";	
	</script> 
</header>
<script type="text/javascript">
	/** add active class when selected--makes the link of the menu bar item different color when active */
	var url = window.location;
	
	//makes selected menu header have darker text
	$('ul.navbar-nav a').filter(function() { return this.href == url; }).parentsUntil(".navbar > .navbar-nav").addClass('active');
	//makes selected dropdown option have different background --##deebec
	$('ul.navbar-nav a').filter(function() { return this.href == url; }).addClass('active');
	
	//prevents double click behavior on menu
	$('.dropdown-toggle').click(function(e) {
    e.preventDefault();
    e.stopPropagation();

    return false;
	});
</script>
<cf_rolecheck>
</cfoutput>
<cfset HEADER_DELIVERED=true>
