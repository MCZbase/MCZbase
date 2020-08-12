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
		<h1 class="h3">MCZbase requires Javascript to function.</h1>
		<nav class="navbar navbar-expand-lg navbar-light bg-light">
			<ul class="navbar-nav mr-auto mt-0 mt-lg-0">
				<li class="nav-item"> <a class="nav-link" href="/SpecimenSearchHTML.cfm">Minimal Specimen Search</a></li>
				<li class="nav-item"><a class="nav-link" href="/BrowseHTML.cfm">Browse Data</a></li>
				<li class="nav-item"><a class="nav-link" href="/https://mcz.harvard.edu/database">About MCZbase</a></li>
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					<button href="/login.cfm?action=signOut" class="btn btn-outline-success logout" aria-label="logout">Log out #session.username#
					<cfif isdefined("session.last_login") and len(#session.last_login#)gt 0>
						<small>(Last login: #dateformat(session.last_login, "dd-mmm-yyyy, hh:mm")#)</small>
					</cfif>
					</button>
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
	</noscript>
	<div class="container-fluid bg-light px-0" style="display: none;" id="mainMenuContainer"><!--- display turned on with javascript below ---> 
		<!---	
		Test for Application.header_image is required for continued integration, as the production menu
		must point to files present on production while the redesign menu points at their replacements in redesign
	--->
		<cfif isdefined("Application.header_image")>
			<nav class="navbar navbar-expand-lg navbar-light bg-light">
				<button class="navbar-toggler" type="button" data-toggle="collapse"
					data-target="##navbarToggler1" aria-controls="navbarToggler1"
					aria-expanded="false" aria-label="Toggle navigation"> <span class="navbar-toggler-icon"></span> </button>
				<div class="collapse navbar-collapse" id="navbarToggler1">
					<ul class="navbar-nav mr-auto mt-0 mt-lg-0">
						
						<!---  Redesign menu for integration on production --->
						<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink4" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> Search </a>
							<div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink4"> <a class="dropdown-item <cfif pageTitle EQ "Search Transactions">active </cfif>" name="find transactions" href="/SpecimenSearch.cfm">Specimen Search</a> 
								<!---old---><a class="dropdown-item" aria-label="media search" name="media" href="/MediaSearch.cfm">Media</a> 
								<!---old---><a class="dropdown-item" aria-label="locations search" name="locations" href="/showLocality.cfm">Locations</a> 
								<!---old---><a class="dropdown-item" aria-label="publication search" name="publications" href="/SpecimenUsage.cfm">Publications</a>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
									<!---old---><a class="dropdown-item" aria-label="agent search" name="agents" href="/agents.cfm">Agents</a>
								</cfif>
								<!---old---><a class="dropdown-item" aria-label="taxonomy search" name="taxonomy" href="/TaxonomySearch.cfm">Taxonomy</a> </div>
						</li>
						<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
							<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink2" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> Data Entry </a>
								<div class="dropdown-menu pl-5 pl-xl-0" aria-labelledby="navbarDropdownMenuLink2"> 
									<!---old---><a class="dropdown-item <cfif pageTitle EQ 'Data Entry'>active </cfif>" name="enter a record" href="/DataEntry.cfm">Enter a Record</a> </div>
							</li>
						</cfif>
						<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
							<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink3" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> Manage Data </a>
								<div class="dropdown-menu pl-5 pl-lg-0" aria-labelledby="navbarDropdownMenuLink3">
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
										<a class="dropdown-item" name="named collections" href="/grouping/NamedCollection.cfm">Named Collections</a> <a class="dropdown-item" name="named collections" href="/vocabularies/CollEventNumberSeries.cfm">Collecting Event Number Series</a>
									</cfif>
								</div>
							</li>
						</cfif>
						<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
							<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink4" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> Transactions </a>
								<div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink4"> <a class="dropdown-item <cfif pageTitle EQ "Search Transactions">active </cfif>" name="find transactions" href="/Transactions.cfm">Find Transactions</a> 
									<!---old---><a class="dropdown-item" name="accessions" href="/editAccn.cfm">Find Accessions</a> 
									<!---old---><a class="dropdown-item" name="accessions" href="/newAccn.cfm">New Accession</a> <a class="dropdown-item <cfif pageTitle EQ "Find Loans">active </cfif>" name="find loans" href="/Transactions.cfm?action=findLoans">Find Loans</a> 
									<!---old---><a class="dropdown-item <cfif pageTitle EQ "Create New Loan">active </cfif>" name="create new loan" href="/Loan.cfm?action=newLoan">New Loan</a> 
									<!---old---><a class="dropdown-item" name="deaccessions" href="/Deaccession.cfm?action=search">Deaccessions</a> 
									<!---old---><a class="dropdown-item" name="borrows" href="/Borrow.cfm">Borrows</a> 
									<!---old---><a class="dropdown-item" name="permits" href="/Permit.cfm">Find Permits</a> 
									<!---old---><a class="dropdown-item" name="permits" href="/Permit.cfm?action=newPermit">New Permit</a> </div>
							</li>
						</cfif>
						<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink5" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> Help </a>
							<div class="dropdown-menu pl-5 pl-lg-0" aria-labelledby="navbarDropdownMenuLink5">
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									<a class="dropdown-item" name="MCZbase Wiki" href="https://code.mcz.harvard.edu/wiki/index.php/Using_MCZbase">Using MCZbase</a> <a class="dropdown-item" name="Controlled Vocabularies" href="/vocabularies/ControlledVocabulary.cfm">Controlled Vocabularies</a>
								</cfif>
								<a class="dropdown-item" name="about MCZbase" href="https://mcz.harvard.edu/database">About MCZbase</a> </div>
						</li>
						<cfif isdefined("session.username") and len(#session.username#) gt 0>
							<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLinka" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> Account
								<cfif isdefined("session.username") and len(#session.username#) gt 0 and session.roles contains "public">
									<i class="fas fa-user-check color-green"></i>
									<cfelse>
									<i class="fas fa-user-cog text-body"></i>
								</cfif>
								</a>
								<div class="dropdown-menu pl-5 pl-lg-0" aria-labelledby="navbarDropdownMenuLinka">
									<cfif session.roles contains "coldfusion_user">
										<form name="profile" method="post" action="/UserProfile.cfm">
											<input type="hidden" name="action" value="nothing">
											<input type="submit" aria-label="Search" value="User Profile" class="anchor-button form-control mr-sm-0 my-0" placeholder="User Profile" onClick="logIn.action.value='nothing';submit();">
										</form>
									</cfif>
									<cfif session.roles contains "public">
										<a class="dropdown-item pl-3" href="/saveSearch.cfm?action=manage">Saved Searches</a>
									</cfif>
								</div>
							</li>
						</cfif>
					</ul>
				</div>
			</nav>
			<cfelse>

			<script>
				document.addEventListener ("keydown", function (evt) {
					if (evt.altKey && evt.key === "m") {  
						evt.preventDefault();
						evt.stopPropagation();
						$('##searchDropdown').click();	
						$('##specimenMenuItem').focus();	
						return false;
					}
				});
				
				// This toggleDropdown function removes the click to stick the menu dropdown behavior
				function toggleDropdown (e) {
  					const _d = $(e.target).closest('.dropdown'),
    				_m = $('.dropdown-menu', _d);
  					setTimeout(function(){
    					const shouldOpen = e.type !== 'click' && _d.is(':hover');
    					_m.toggleClass('show', shouldOpen);
    					_d.toggleClass('show', shouldOpen);
    				$('[data-toggle="dropdown"]', _d).attr('aria-expanded', shouldOpen);
  					}, e.type === 'mouseleave' ? 100 : 0);
				}
				$('body')
  					.on('mouseenter mouseleave','.dropdown',toggleDropdown)
  					.on('click', '.dropdown-menu a', toggleDropdown);
			</script>
			<nav class="navbar navbar-light bg-transparent navbar-expand-lg py-0" id="main_nav">
				<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="##menuTest1" aria-controls="menuTest1" aria-expanded="false" aria-label="Toggle navigation"> <span class="navbar-toggler-icon"></span> </button>
				<div class="collapse navbar-collapse" id="menuTest1">
					<ul class="navbar-nav nav-fill mr-auto">
						<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle px-3 text-left" href="##" id="searchDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" aria-label="Search" title="Search (Alt+m)" >Search</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="aboutDropdown">
								<li>
									<a class="dropdown-item" id="specimenMenuItem" href="/Specimens.cfm">Specimens</a> 
									<a class="dropdown-item" href="/Taxa.cfm">Taxonomy</a> 
									<a class="dropdown-item" href="/Media.cfm">Media</a> 
									<a class="dropdown-item" href="/Publications.cfm">Publications</a> 
									<a class="dropdown-item" href="/Geography.cfm">Geography</a> 
									<a class="dropdown-item" href="/Events.cfm">Event</a>
									<a class="dropdown-item" href="/Agents.cfm">Agents</a>
									<a class="dropdown-item" href="/Events.cfm">Projects</a>
									<a class="dropdown-item" href="/Agents.cfm">Annotations</a>
									<a class="dropdown-item" href="/Events.cfm">Browse Specimens</a>
								</li>
							</ul>
						</li>
						<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle px-3 text-left" href="##" id="aboutDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Data Entry</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="aboutDropdown">
								<li class="d-md-flex align-items-start justify-content-start">
									<div>
										<div class="dropdown-header px-4 text-danger">Create New Records</div>
										<a class="dropdown-item" href="/">Specimen Form</a> <a class="dropdown-item" href="/">Media Form</a> <a class="dropdown-item" href="/">Publication Form</a> <a class="dropdown-item" href="/">Taxonomy Form</a> <a class="dropdown-item" href="/">Higher Geography Form</a> <a class="dropdown-item" href="/">Locality Form</a> <a class="dropdown-item" href="/">Publication Form</a> <a class="dropdown-item" href="/">Agent Form</a><a class="dropdown-item" href="/">Loan Form</a> <a class="dropdown-item" href="/">Deaccession Form</a> <a class="dropdown-item" href="/">Accession Form</a> <a class="dropdown-item" href="/">Permit Form</a> <a class="dropdown-item" href="/">Borrow Form</a> 
									</div>
									<div>
										<div class="dropdown-header px-4 text-danger">Bulkloader</div>
										<a class="dropdown-item" href="/">Bulkload Specimens</a> <a class="dropdown-item" href="/">Bulkloader Status</a> <a class="dropdown-item" href="/">Bulkload Builder</a> <a class="dropdown-item" href="/">Browse and Edit</a> 
									</div>
									<div>
										<div class="dropdown-header px-4 text-danger">Batch Tools (add to records)</div>
										<a class="dropdown-item" href="/">Bulk Edit Parts</a> <a class="dropdown-item" href="/">Bulk Add Parts</a> <a class="dropdown-item" href="/">Bulk Add Citations</a> <a class="dropdown-item" href="/">Bulk Add Attributes</a> <a class="dropdown-item" href="/">Bulk Add Identifiers</a> <a class="dropdown-item" href="/">Bulk Add Agents</a> <a class="dropdown-item" href="/">Bulk Add Media</a> <a class="dropdown-item" href="/">Bulk Add Identifications</a> 
									</div>
								</li>
							</ul>
						</li>
						<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle px-3 text-left" href="##" id="servicesDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Data Tools</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="servicesDropdown">
								<li><a class="dropdown-item" href="/">Projects</a> <a class="dropdown-item" href="/">Named Groups</a> <a class="dropdown-item" href="/vocabularies/CollEventNumberSeries.cfm">Collecting Event Number Series</a> <a class="dropdown-item" href="/">Object Tracking</a> <a class="dropdown-item" href="/">Encumbrances</a> 
								</li>
							</ul>
						</li>
						<li class="nav-item dropdown"> <a class="nav-link dropdown-toggle px-3 text-left" href="##" id="servicesDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">About</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="servicesDropdown"> 
								<a class="dropdown-item" href="https://code.mcz.harvard.edu/wiki/index.php/Main_Page">Using MCZbase (Wiki)</a> <a class="dropdown-item" href="/">About MCZbase</a> <a class="dropdown-item" href="/"></a>
								<div class="dropdown-divider"></div>
								<li class="d-md-flex align-items-start justify-content-start">
									<div>
										<div class="dropdown-header text-danger">About Your Data</div>
										<a class="dropdown-item" href="/">Self-Service Reports</a> <a class="dropdown-item" href="/">Collection Statistics</a>  <a class="dropdown-item" href="/">Saved Searches</a>
									</div>
									<div>
										<div class="dropdown-header text-danger">Shared Data</div>
										<a class="dropdown-item" href="/project-rescue">Taxonomy</a> <a class="dropdown-item" href="/">Recently Georeferenced Localities</a><a class="dropdown-item" href="/">Agents</a><a class="dropdown-item" href="/">MCZbase Statistics</a> 
									</div>
								</li>
							</ul>
						</li>
						<cfif isdefined("session.username") and len(#session.username#) gt 0>
						</ul>
					
						
					<ul class="navbar-nav ml-auto">
			
							
					<li class="nav-item dropdown mr-xl-2">
						
						<a id="dropdownMenu5" href="##" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" class="nav-link dropdown-toggle px-3 text-left">Account <cfif isdefined("session.username") and len(#session.username#) gt 0 and session.roles contains "public">
							<i class="fas fa-user-check color-green"></i>
							<cfelse>
							<i class="fas fa-user-cog text-body"></i>
						</cfif>
						</a>
						<ul aria-labelledby="dropdownMenu5" class="dropdown-menu border-0 shadow">
							<li>
								<a href="##" class="dropdown-item">
								<cfif session.roles contains "coldfusion_user">
								<form name="profile" method="post" action="/UserProfile.cfm">
									<input type="hidden" name="action" value="nothing">
									<input type="submit" aria-label="Search" value="User Profile" class="user form-control-sm form-control-plaintext p-0 text-left outline-0 border-0"  placeholder="User Profile" onClick="logIn.action.value='nothing';submit();">
								</form>
								</cfif>
								</a>
							</li>
							<cfif session.roles contains "public">
							<div><a href="##" class="dropdown-item">Settings</a></div>
							</cfif>
			
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
							<input type="text" name="username" id="username" placeholder="username" class="loginButtons" style="width:100px;">
							<label for="password" class="mr-1 sr-only"> Password:</label>
							<input type="password" id="password" name="password" autocomplete="current password" placeholder="password" title="Password" class="loginButtons" style="width: 80px;">
							<label for="login" class="mr-1 sr-only"> Password:</label>
							<input type="submit" value="Log In" id="login" class="btn-primary loginButtons"  onClick="logIn.action.value='signIn';submit();" aria-label="click to login">
							<label for="create_account" class="mr-1 sr-only"> Password:</label>
							<input type="submit" value="Register" class="btn-primary loginButtons" id="create_account" onClick="logIn.action.value='newUser';submit();" aria-label="click to create new account">
						</div>
					</form>
				</cfif>
				</div>
			</nav>

		</cfif>
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
