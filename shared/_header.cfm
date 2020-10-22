<!---
_header.cfm

Copyright 2019 President and Fellows of Harvard College

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
<link rel="stylesheet" href="/lib/bootstrap/bootstrap-4.5.0-dist/css/bootstrap.min.css">
<!---needed for overall look--->
<link rel="stylesheet" href="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/styles/jqx.base.css">
<!--- needed for jqxwidgets to work --->
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.css">
<!--- Use JQuery-UI widgets when available, only use jqwidgets for extended functionality --->
<link rel="stylesheet" href="/lib/fontawesome/fontawesome-free-5.5.0-web/css/all.css">
<!-- Provides account, magnifier, and cog icons--> 
<!---<link rel="stylesheet" href="/lib/JQWidgets/jqwidgets/styles/jqx.bootstrap.css" >--->
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.min.css" />
<!--- Library supporting a multiselect widget based on jquery-ui.  --->
<link rel="stylesheet" href="/lib/misc/jquery-ui-multiselect-widget-3.0.0/css/jquery.multiselect.css" />
<link rel="stylesheet" href="/lib/misc/jquery-ui-multiselect-widget-3.0.0/css/jquery.multiselect.filter.css" />
<link rel="stylesheet" href="/shared/css/header_footer_styles.css">
<link rel="stylesheet" href="/shared/css/custom_styles.css">
<link rel="stylesheet" href="/shared/css/customstyles_jquery-ui.css">
<script type="text/javascript" src="/lib/fontawesome/fontawesome-free-5.5.0-web/js/all.js"></script><!---search, account and cog icons---> 
<script type="text/javascript" src="/lib/jquery/jquery-3.5.1.min.js"></script> 
<script type="text/javascript" src="/lib/jquery-ui-1.12.1/jquery-ui.js"></script><!--- Use JQuery-UI widgets when available. ---> 
<!---<script type="text/javascript" src="/lib/bootstrap/js/bootstrap-multiselect.js"></script>---> 
<script type="text/javascript" src="/lib/bootstrap/bootstrap-4.5.0-dist/js/bootstrap.bundle.min.js"></script><!--- popper is in the bundle---> 
<!---<script type="text/javascript" src="/lib/bootstrap/js/bootstrap-select.min.js"></script>---> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxcore.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxdata.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxdata.export.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.js"></script> <!--- jqxgrid is the primary reason we are including jqwidgets ---> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.filter.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.edit.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.sort.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.selection.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.export.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.storage.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxcombobox.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.pager.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.grouping.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.aggregates.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxscrollbar.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/globalization/globalize.js"></script> 
<!--- All jqwidgets below are suspect, include only if they provide functionality not available in jquery-ui.  ---> 
<!--- TODO: Remove all jqwidgets where functionality can be provided by jquery-ui ---> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxbuttons.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxlistbox.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxdropdownlist.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxmenu.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxwindow.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxdatetimeinput.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxdate.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxslider.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxpanel.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxinput.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxdragdrop.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.columnsresize.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.columnsreorder.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxcalendar.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxtree.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxinput.js"></script> 
<!--- End supspect block ---> 

<script type="text/javascript" src="/shared/js/shared-scripts.js"></script>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<script type="text/javascript" src="/shared/js/internal-scripts.js"></script> 
	<script type="text/javascript" src="/shared/js/vocabulary_scripts.js"></script>
</cfif>

<!--- Multiselect widget used on specimen search, probably not needed everywhere ---> 
<script type="text/javascript" src="/lib/misc/jquery-ui-multiselect-widget-3.0.0/src/jquery.multiselect.js"></script> 
<script type="text/javascript" src="/lib/misc/jquery-ui-multiselect-widget-3.0.0/src/jquery.multiselect.filter.js"></script>
<cfif isdefined("addheaderresource")>
	<cfif addheaderresource EQ "feedreader">
		<script type="text/javascript" src="/lib/misc/jquery-migrate-1.0.0.js"></script> 
		<script type="text/javascript" src="/lib/misc/jquery.jfeed.js"></script>
	</cfif>
</cfif>
<cfif CGI.script_name CONTAINS "/transactions/" OR CGI.script_name IS "/Transactions.cfm">
	<script type="text/javascript" src="/transactions/js/transactions.js"></script>
</cfif>
<cfif CGI.script_name CONTAINS "/taxonomy/" OR CGI.script_name IS "/Taxa.cfm">
	<script type="text/javascript" src="/taxonomy/js/taxonomy.js"></script>
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
<!--- Workaround for current production header/collectionlink color values being different from redesign values  --->
<cfif isdefined("Application.header_image")>
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
		<ul class="navbar col-lg-9 col-xs-6 p-0 m-0" style="background-color: #header_color#; ">
			<li class="nav-item mcz2"> <a href="https://www.mcz.harvard.edu/" target="_blank" rel="noreferrer" style="color: #collection_link_color#;" >Museum of Comparative Zoology</a> </li>
			<li class="nav-item mczbase my-1 py-0"> <a href="/" target="_blank" style="color: #collection_link_color#" >#session.collection_link_text#</a> </li>
		</ul>
		<ul class="navbar col-lg-3 col-sm-3 p-0 m-0 d-flex justify-content-end">
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
			Test for Application.header_image is required for continued integration, as the production menu
			must point to files present on production while the redesign menu points at their replacements in redesign
		--->
		<cfif isdefined("Application.header_image")>
			<cfset targetMenu = "production">
		<cfelse>
			<cfset targetMenu = "redesign">
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
									<a class="dropdown-item" href="">Browse Specimens By Category</a>
								</cfif>
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href="/Taxonomy.cfm">Taxonomy</a><!--- we still need the old /Taxonomy.cfm page until Redmine 708 is closed. --->
									<a class="dropdown-item" href="/Taxa.cfm">Taxonomy (new)</a>
								<cfelse>
									<a class="dropdown-item" href="/Taxa.cfm">Taxonomy</a>
								</cfif>
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href="/MediaSearch.cfm">Media</a><!--- old --->
								<cfelse>
									<a class="dropdown-item" href="">Media</a>
								</cfif>						
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href="/showLocality.cfm">Localities</a>
								<cfelse>
									<a class="dropdown-item" href="">Localities</a>
								</cfif>		
								<cfif targetMenu EQ "redesign">
									<a class="dropdown-item" href="">Geography</a>
				
									<a class="dropdown-item" href="">Geology</a>
							
									<a class="dropdown-item" href="">Collecting Events</a>
								</cfif>					
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href="/agents.cfm">Agents</a> <!--- old --->
								<cfelse>
									<a class="dropdown-item" href="">Agents</a> 
								</cfif>						
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href = "/SpecimenUsage.cfm">Publications/Projects</a><!--- old --->
								<cfelse>
									<a class="dropdown-item" href="">Publications</a>
								</cfif>	
								<cfif targetMenu EQ "redesign">
									<a class="dropdown-item" href="">Projects</a>
								</cfif>
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href = "/info/reviewAnnotation.cfm">Annotations</a><!---old - but relocated, not in this menu on current prd --->
								<cfelse>
									<a class="dropdown-item" href="">Annotations</a>
								</cfif>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
									<cfif targetMenu EQ "production">
										<a class="dropdown-item" href="/tools/userSQL.cfm">SQL Queries</a> <!--- old - but relocated, not in this menu on current prd--->
									<cfelse>
										<a class="dropdown-item" href="">SQL Queries</a> 
									</cfif>
								</cfif>
							 </li>
						</ul>
					</li>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
						<li class="nav-item dropdown">
							<a class="nav-link dropdown-toggle px-3 text-left" href="" id="aboutDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Data Entry</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="aboutDropdown">
								<li class="d-md-flex align-items-start justify-content-start">
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Create New Record</div>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
											<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/DataEntry.cfm">Data Entry</a><!--- old --->
											<cfelse>
											<a class="dropdown-item" href="">Specimen</a>
											</cfif>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/media.cfm?action=newMedia">Media</a><!--- old --->
											<cfelse>
												<a class="dropdown-item" href="">Media</a>
											</cfif>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_agents")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/agents.cfm">Agent</a><!--- old --->
											<cfelse>
												<a class="dropdown-item" href="">Agent</a> 
											</cfif>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_publications")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Publication.cfm?action=newPub">Publication</a><!--- old --->
											<cfelse>
												<a class="dropdown-item" href="">Publication</a> 
											</cfif>
										</cfif>
									</div>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Bulkload</div>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Bulkloader/bulkloaderBuilder.cfm">Bulkload Builder</a><!--- old --->
											<cfelse>
												<a class="dropdown-item" href="">Bulkload Builder</a> 
											</cfif>									
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Bulkloader/">Bulkload Specimens</a><!--- old --->
											<cfelse>
												<a class="dropdown-item" href="">Bulkload Specimens</a> 
											</cfif>			
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Bulkloader/browseBulk.cfm">Browse and Edit</a><!--- old --->
											<cfelse>
												<a class="dropdown-item" href="">Browse and Edit</a> 
											</cfif>							
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Bulkloader/bulkloader_status.cfm">Bulkloader Status</a><!--- old --->
											<cfelse>
												<a class="dropdown-item" href="">Bulkloader Status</a> 
											</cfif>			
											<cfif targetMenu EQ "redesign">
												<a class="dropdown-item" href="">Batch Tools (alter existing records)</a><!--- new --plan for landing page--->
											</cfif>			
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_publications")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/tools/PublicationStatus.cfm">Publication Staging</a>
											<cfelse>
												<a class="dropdown-item" href="">Publication Staging</a>
											</cfif>
										</cfif>								
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
											<cfif targetMenu EQ "redesign">
												<a class="dropdown-item" href="">Data Loan Items</a>
											</cfif>
										</cfif>	
									</div>
									<cfif targetMenu EQ "production">
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
											<div>
											<div class="h5 dropdown-header px-4 text-danger">Batch Tools</div><!--- old, retain until landing page is in place. --->

												<a class="dropdown-item" href="/tools/BulkloadNewParts.cfm">Bulk Parts</a>

												<a class="dropdown-item" href="/tools/BulkloadEditedParts.cfm">Bulk Edited Parts</a>

												<a class="dropdown-item" href="/tools/BulkloadAttributes.cfm">Bulk Attributes</a>

												<a class="dropdown-item" href="/tools/BulkloadCitations.cfm">Bulk Citations</a>

												<a class="dropdown-item" href="/tools/BulkloadOtherId.cfm">Bulk Identifiers</a>

												<a class="dropdown-item" href="/tools/loanBulkload.cfm">Bulk Loans</a>
												
												<a class="dropdown-item" href="/tools/DataLoanBulkload.cfm">Bulk Data Loans</a>

												<a class="dropdown-item" href="/DataServices/agents.cfm">Bulk Agents</a>

												<a class="dropdown-item" href="/tools/BulkloadPartContainer.cfm">Bulk Part Containers</a>

												<a class="dropdown-item" href="/tools/BulkloadIdentification.cfm">Bulk Identifications</a> 

												<a class="dropdown-item" href="/tools/BulkloadContEditParent.cfm">Bulk Edit/Move Parts</a> 

												<a class="dropdown-item" href="/tools/BulkloadMedia.cfm">Bulk Media</a> 

												<a class="dropdown-item" href="/tools/BulkloadRelations.cfm">Bulk Relationships</a>

												<a class="dropdown-item" href="/tools/BulkloadGeoref.cfm">Bulk Georeference</a> 

												<a class="dropdown-item" href="/tools/BulkloadTaxonomy.cfm">Bulk Taxonomy</a> 
											</div>
										</cfif>	
									</cfif>
								</li>
							</ul>
						</li>
					</cfif>	
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
						<li class="nav-item dropdown">
							<a class="nav-link dropdown-toggle px-3 text-left" href="" id="manageDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Manage Data</a>
	      	        	<ul class="dropdown-menu border-0 shadow" aria-labelledby="manageDropdown">			
								<li class="d-md-flex align-items-start justify-content-start">		
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Search &amp; Edit</div>

										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Locality.cfm?action=findHG">Geography</a> 
										<cfelse>
											<a class="dropdown-item" href="">Geography</a>
										</cfif>
											
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Locality.cfm?action=findLO">Localities</a> 
										<cfelse>
											<a class="dropdown-item" href="">Localities</a>
										</cfif>
																					
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Locality.cfm?action=findCO">Collecting Event</a> 
										<cfelse>
											<a class="dropdown-item" href="">Collecting Event</a>
										</cfif>
												
										<cfif targetMenu EQ "redesign">
											<a class="dropdown-item" href="/vocabularies/CollEventNumberSeries.cfm">Collecting Event Number Series</a> 
										</cfif> 
									</div>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Create New Record</div>
										
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_geography")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Locality.cfm?action=newHG">Geography</a> 
											<cfelse>
												<a class="dropdown-item" href="">Geography</a> 
											</cfif>
										</cfif>
											
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Locality.cfm?action=newHG">Locality</a> 
											<cfelse>
												<a class="dropdown-item" href="">Locality</a> 
											</cfif>
										</cfif>
									
										<cfif targetMenu EQ "redesign">									
											<a class="dropdown-item" href="/vocabularies/CollEventNumberSeries.cfm?action=new">Collecting Event Number Series</a> 
										</cfif>
									</div>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Manage</div>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Encumbrances.cfm">Encumbrances</a>
										<cfelse>
											<a class="dropdown-item" href="">Encumbrances</a>
										</cfif>
										<cfif targetMenu EQ "redesign">
											<a class="dropdown-item" href="">Annotations</a>
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href = "/Admin/agentMergeReview.cfm">Review Pending Merges</a>
										<cfelse>
											<a class="dropdown-item" href="">Review Pending Agent Merges</a>
										</cfif>
										
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href = "/Admin/killBadAgentDups.cfm">Merge bad duplicate agents</a>
										<cfelse>
											<a class="dropdown-item" href="">Merge bad duplicate agents</a>
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href = "/tools/parent_child_taxonomy.cfm">Sync Parent/Child Taxonomy</a>
										<cfelse>
											<a class="dropdown-item" href="">Sync Parent/Child Taxonomy</a>
										</cfif>
											
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href = "/tools/pendingRelations.cfm">Pending Relationships</a>
										<cfelse>
											<a class="dropdown-item" href="">Pending Relationships</a>
										</cfif>
										
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/tools/sqlTaxonomy.cfm">SQL Taxonomy</a>
										<cfelse>
											<a class="dropdown-item" href="">SQL Taxonomy</a>
										</cfif>
									</cfif>
									</div>
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
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/info/reviewAnnotation.cfm">Annotations</a> 
										</cfif>
										<a class="dropdown-item" href="/grouping/NamedCollection.cfm">Named Groupings</a>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/ContainerBrowse.cfm">Browse Storage Locations</a>
											<cfelse>
												<a class="dropdown-item" href="">Browse Storage Locations</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/findContainer.cfm">Find Storage Location/Container</a> 
											<cfelse>
												<a class="dropdown-item" href="">Find Storage Location/Container</a>
											</cfif>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"dgr_locator")>
											<a class="dropdown-item" href="">DGR Locator</a> 
										</cfif>
									</div>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Create New Record</div>
										<cfif targetMenu EQ "redesign">
										<a class="dropdown-item" href="">Annotation</a>
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/grouping/NamedCollection.cfm?action=new">Named Grouping</a>
										<cfelse>
											<a class="dropdown-item" href="/grouping/NamedCollection.cfm?action=new">Named Grouping</a>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
											<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/editContainer.cfm?action=newContainer">Storage Location/Create Container</a> 
											<cfelse>
												<a class="dropdown-item" href="">Storage Location/Create Container</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/CreateContainersForBarcodes.cfm">Create Container Series</a>
											<cfelse>
												<a class="dropdown-item" href="">Create Container Series</a>
											</cfif>
										</cfif>
									</div>
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
										
										</div>
									</cfif>
								</li>
							</ul>
						</li>
					</cfif>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
						<li class="nav-item dropdown">
							<a class="nav-link dropdown-toggle px-3 text-left" href="" id="transactionDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Transactions</a>
	              			<ul class="dropdown-menu border-0 shadow" aria-labelledby="transactionDropdown">			
									<li class="d-md-flex align-items-start justify-content-start">		
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Search &amp; Edit</div>							
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Transactions.cfm">All Transactions</a>
										<cfelse>
											<a class="dropdown-item" href="/Transactions.cfm?action=findAll">All Transactions</a>
										</cfif>			
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href = "/editAccn.cfm">Accessions</a>
										<cfelse>
											<a class="dropdown-item" href="">Accessions</a>
										</cfif>			
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Transactions.cfm?action=findLoans">Loans</a> 
										<cfelse>
											<a class="dropdown-item" href="/Transactions.cfm?action=findLoans">Loans</a> 
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href = "/Borrow.cfm">Borrow</a>
										<cfelse>
											<a class="dropdown-item" href="">Borrow</a>
										</cfif>	
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href = "/Deaccession.cfm">Deaccession</a>
										<cfelse>
											<a class="dropdown-item" href="">Deaccession</a>
										</cfif>	
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Permit.cfm">Permissions &amp; Rights</a>
										<cfelse>
											<a class="dropdown-item" href="/transactions/Permit.cfm">Permissions &amp; Rights</a> 
										</cfif>
									</div>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Create New Record</div>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/addAccn.cfm">Accession</a> 
										<cfelse>
											<a class="dropdown-item" href="">Accession</a> 
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Loan.cfm?action=newLoan">Loan</a> 
										<cfelse>
											<a class="dropdown-item" href="/transactions/Loan.cfm?action=newLoan">Loan</a> 
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Deaccession.cfm?action=newDeacc">Deaccession</a> 
										<cfelse>
											<a class="dropdown-item" href="">Deaccession</a> 
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Borrow.cfm?action=new">Borrow</a> 
										<cfelse>
											<a class="dropdown-item" href="">Borrow</a> 
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Permit.cfm?action=newPermit">Permissions &amp; Rights</a> 
										<cfelse>
											<a class="dropdown-item" href="/transactions/Permit.cfm?action=new">Permissions &amp; Rights</a> 
										</cfif>
									</div>
									</li>
							</ul>
						</li>
					</cfif>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
						<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle px-3 text-left" href="" id="reportDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Review Data</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="reportDropdown">			
									<li class="d-md-flex align-items-start justify-content-start">		
									<div>
									<div class="h5 dropdown-header px-4 text-danger">Reports</div>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/info/recentgeorefs.cfm">Recently Georeferenced Localities</a> 
										<cfelse>
											<a class="dropdown-item" href="">Recently Georeferenced Localities</a> 
										</cfif>
											<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/info/collnHoldgByClass.cfm">Holdings by Class</a> 
										<cfelse>
											<a class="dropdown-item" href="">Holdings by Class</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/info/mia_in_genbank.cfm">Genbank Missing Data</a> 
										<cfelse>
											<a class="dropdown-item" href="">Genbank Missing Data</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/Admin/bad_taxonomy.cfm">Invalid Taxonomy</a> 
										<cfelse>
											<a class="dropdown-item" href="">Invalid Taxonomy</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/tools/TaxonomyScriptGap.cfm">Taxonomy Gaps</a> 
										<cfelse>
											<a class="dropdown-item" href="">Taxonomy Gaps</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/tools/TaxonomyGaps.cfm">Messy Taxonomy</a> 
										<cfelse>
											<a class="dropdown-item" href="">Messy Taxonomy</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/info/slacker.cfm">Suspect Data</a> 
										<cfelse>
											<a class="dropdown-item" href="">Suspect Data</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/Reports/partusage.cfm">Part Usage</a> 
										<cfelse>
											<a class="dropdown-item" href="">Part Usage</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/info/noParts.cfm">Partless Specimen Records</a> 
										<cfelse>
											<a class="dropdown-item" href="">Partless Specimen Records</a> 
										</cfif>
								
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/tools/findGap.cfm">Catalog Number Gaps</a> 
										<cfelse>
											<a class="dropdown-item" href="">Catalog Number Gaps</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/info/dupAgent.cfm">Duplicate Agents</a> 
										<cfelse>
											<a class="dropdown-item" href="">Duplicate Agents</a> 
										</cfif>																		
									</div>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Statistics</div>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/info/Citations.cfm">Citations Summary</a> 
										<cfelse>
											<a class="dropdown-item" href="">Citation Summary</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/info/MoreCitationStats.cfm">Citation Details</a> 
										<cfelse>
											<a class="dropdown-item" href="">Citation Details</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/info/loanStats.cfm">Loans Statistics</a> 
										<cfelse>
											<a class="dropdown-item" href="">Loan Statistics</a> 
										</cfif>
										<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/Admin/download.cfm">Download Statistics</a> 
										<cfelse>
											<a class="dropdown-item" href="">Download Statistics</a> 
										</cfif>
											<cfif targetMenu EQ "production">		
											<a class="dropdown-item" href="/info/queryStats.cfm">Query Statistics</a> 
										<cfelse>
											<a class="dropdown-item" href="">Query Statistics</a> 
										</cfif>
									</div>
								</li>
							</ul>
						</li>
					</cfif>
			<!---		<cfif isdefined("session.roles") and ( listcontainsnocase(session.roles,"manage_codetables") or listcontainsnocase(session.roles,"dba") or listcontainsnocase(session.roles,"global_admin") )>  Can't see what I'm doing with these permissions--->
						<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"MANAGE_CODETABLES")>
						<li class="nav-item dropdown">
							<a class="nav-link dropdown-toggle px-3 text-left" href="" id="adminDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Admin</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="adminDropdown">
								<li class="d-md-flex align-items-start justify-content-start">		
									<!--- TODO: Review administrative functions --->
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Data</div>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_codetables")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/CodeTableEditor.cfm">Code Table Editor</a>
											<cfelse>
												<a class="dropdown-item" href="">Code Table Editor</a>
											</cfif>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_codetables")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/info/geol_hierarchy.cfm">Geology Attributes Hierarchy</a>
											<cfelse>
												<a class="dropdown-item" href="">Geology Attributes Hierarchy</a>
											</cfif>
										</cfif>
										<!--- TODO: Need another role for report management  --->
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_codetables")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Reporter.cfm">Reporter</a>
											<cfelse>
												<a class="dropdown-item" href="">Reporter</a>
											</cfif>
										</cfif>
										<!--- TODO: are the rest of these DBA or another role?  --->
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_codetables")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/tools/downloadData.cfm">Download Tables</a>
											<cfelse>
												<a class="dropdown-item" href="">Download Tables</a>
											</cfif>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_codetables")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Admin/dumpAll.cfm">Dump</a>
											<cfelse>
												<a class="dropdown-item" href="">Dump</a>
											</cfif>
										</cfif>	
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item"  href = "/ScheduledTasks/index.cfm">Scheduled Tasks</a>
											<cfelse>
												<a class="dropdown-item"  href = "">Scheduled Tasks</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item"  href = "/tools/imageList.cfm">
											<cfelse>
												<a class="dropdown-item" href="">Image List</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item"  href = "/tools/imageList.cfm">
											<cfelse>
												<a class="dropdown-item" href="">Image List</a>
											</cfif>
										</cfif>
									</div>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Users/Privileges</div>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Admin/ActivityLog.cfm">Audit SQL</a>
										<cfelse>
											<a class="dropdown-item" href="/">Audit SQL</a>
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/AdminUsers.cfm">MCZbase User Access</a>
										<cfelse>
											<a class="dropdown-item" href="/">MCZbase User Access</a>
										</cfif>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href = "/tools/access_report.cfm?action=role">User Role Report</a>
										<cfelse>
											<a class="dropdown-item" href = "">User Role Report</a>
										</cfif>
										<cfif targetMenu EQ "production">
												<a class="dropdown-item" href = "/Admin/user_roles.cfm">Database Role Definitions</a>
											<cfelse>
												<a class="dropdown-item" href = "">Database Role Definitions</a>
										</cfif>	
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Admin/form_roles.cfm">Form Permissions</a>
											<cfelse>
												<a class="dropdown-item" href="">Form Permissions</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href = "/Admin/blacklist.cfm">Blacklist</a>
											<cfelse>
												<a class="dropdown-item" href = "">Blacklist</a>
											</cfif>
												
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href = "/Admin/manage_user_loan_request.cfm">User Loan</a>
											<cfelse>
												<a class="dropdown-item" href = "">User Loan</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href = "/Admin/user_report.cfm">All User Stats</a>
											<cfelse>
												<a class="dropdown-item" href = "">All User Stats</a>
											</cfif>
										</cfif>
									</div>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"GLOBAL_ADMIN")>
										<div>
											<div class="h5 dropdown-header px-4 text-danger">Application</div>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href = "/Admin/Collection.cfm">Manage Collection</a>
											<cfelse>
												<a class="dropdown-item" href = "">Manage Collection</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href = "/CFIDE/administrator/">Manage Coldfusion</a>
											<cfelse>
												<a class="dropdown-item" href = "">Manage Coldfusion</a>
											</cfif>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href = "/Admin/redirect.cfm">Redirects</a>
											<cfelse>
												<a class="dropdown-item" href = "">Redirects</a>
											</cfif> 
										</div>
									</cfif>
								</li>
							</ul>
						</li>
					</cfif>
					<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle px-3 text-left" href="" id="helpDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Help</a>
						<ul class="dropdown-menu border-0 shadow" aria-labelledby="helpDropdown">
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
								<a class="dropdown-item" href="https://code.mcz.harvard.edu/wiki/index.php/Main_Page">Using MCZbase (Wiki Support)</a>
								<a class="dropdown-item" href="/vocabularies/ControlledVocabulary.cfm">Controlled Vocabularies</a>
							</cfif>
								<a class="dropdown-item" href="https://mcz.harvard.edu/database">About MCZbase</a>
								<a class="dropdown-item" href="/info/api.cfm">API</a>
								<a class="dropdown-item" href="/site/arctosdb/">Technical Details</a>
						</ul>
					</li>
				</ul>
				<ul class="navbar-nav ml-auto">
					<cfif isdefined("session.username") and len(#session.username#) gt 0>
						<li class="nav-item dropdown mr-xl-2"> <a id="dropdownMenu5" href="" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" class="nav-link dropdown-toggle px-3 text-left">Account
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
										<a href="" class="dropdown-item">
										<!--- TODO: Fix this, should be just a link, not a form POST -- it is not working either way right now (after a test)--->
										<form name="profile" method="post" action="/UserProfile.cfm">
											<input type="hidden" name="action" value="nothing">
											<input type="submit" aria-label="Search" value="User Profile" class="user form-control-sm form-control-plaintext p-0 text-left outline-0 border-0"  placeholder="User Profile" onClick="logIn.action.value='nothing';submit();">
										</form>
										</a> 
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
								<input type="text" name="username" id="username" placeholder="username" class="data-entry-input d-inline loginButtons loginfld1">
								<label for="password" class="mr-1 sr-only"> Password:</label>
								<input type="password" id="password" name="password" autocomplete="current password" placeholder="password" title="Password" class="loginButtons data-entry-input d-inline loginfld2">
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
