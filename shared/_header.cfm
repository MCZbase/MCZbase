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
<cfinclude template="/shared/functionLib.cfm"><!---Easy to overlook this shared function file--->
<link rel="stylesheet" href="/lib/bootstrap/bootstrap-4.5.0-dist/css/bootstrap.min.css"><!---needed for overall look--->
<!---<link rel="stylesheet" href="/lib/bootstrap/css/bootstrap-multiselect.css">---><!--- TODO: Remove? don't know not in 4.1.3--->
<link rel="stylesheet" href="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/styles/jqx.base.css"><!---TODO: Remove? don't know--->
<link rel="stylesheet" href="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/styles/jqx.light.css"><!--- TODO: Remove? don't know--->
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.css"><!--- Use JQuery-UI widgets when available, only use jqwidgets for extended functionality --->
<!---<link rel="stylesheet" href="/lib/bootstrap/css/bootstrap-select.min.css">---><!--- TODO: Remove? don't know but tabs work--->
<link rel="stylesheet" href="/lib/fontawesome/fontawesome-free-5.5.0-web/css/all.css"><!-- Provides account, magnifier, and cog icons-->
<!---<link rel="stylesheet" href="/lib/JQWidgets/jqwidgets/styles/jqx.bootstrap.css" >--->
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.min.css" />
<!---<link rel="stylesheet" href="/lib/jquery/jquery.multiselect.css" />--->	
<link rel="stylesheet" href="/lib/jquery/jquery-ui-multiselect-widget-3.0.0/css/jquery.multiselect.css" />	
<link rel="stylesheet" href="/lib/jquery/jquery-ui-multiselect-widget-3.0.0/css/jquery.multiselect.filter.css" />	
<link rel="stylesheet" href="/shared/css/header_footer_styles.css">
<link rel="stylesheet" href="/shared/css/custom_styles.css">
<script type="text/javascript" src="/lib/fontawesome/fontawesome-free-5.5.0-web/js/all.js"></script><!---search, account and cog icons--->
<script type="text/javascript" src="/lib/jquery/jquery-3.5.1.min.js"></script>
<script type="text/javascript" src="/lib/jquery-ui-1.12.1/jquery-ui.js"></script><!--- Use JQuery-UI widgets when available. --->
<!---<script type="text/javascript" src="/lib/bootstrap/js/bootstrap-multiselect.js"></script>--->
<script type="text/javascript" src="/lib/bootstrap/bootstrap-4.5.0-dist/js/bootstrap.bundle.min.js"></script><!--- popper is in the bundle--->
<!---<script type="text/javascript" src="/lib/bootstrap/js/bootstrap-select.min.js"></script>--->
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxcore.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxdata.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxdata.export.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxgrid.js"></script>  <!--- jqxgrid is the primary reason we are including jqwidgets --->
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxgrid.filter.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxgrid.edit.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxgrid.sort.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxgrid.selection.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxgrid.export.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxgrid.storage.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxcombobox.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxgrid.pager.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxgrid.grouping.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxgrid.aggregates.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxscrollbar.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/globalization/globalize.js"></script>
<!--- All jqwidgets below are suspect, include only if they provide functionality not available in jquery-ui.  --->
<!--- TODO: Remove all jqwidgets where functionality can be provided by jquery-ui --->
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxbuttons.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxlistbox.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxdropdownlist.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxmenu.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxwindow.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdatetimeinput.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdate.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxslider.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxpanel.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxinput.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdragdrop.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.columnsresize.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.columnsreorder.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxcalendar.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxtree.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets=ver9.1.6/jqwidgets/jqxinput.js"></script>
<!--- End supspect block --->

<script type="text/javascript" src="/shared/js/shared-scripts.js"></script>

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<script type="text/javascript" src="/shared/js/internal-scripts.js"></script>
	<script type="text/javascript" src="/shared/js/vocabulary_scripts.js"></script>
</cfif>
<!---<script type="text/javascript" src="/lib/jquery/jquery.multiselect.min.js"></script>--->
	<script type="text/javascript" src="/lib/jquery/jquery-ui-multiselect-widget-3.0.0/src/jquery.multiselect.js"></script>	
	<script type="text/javascript" src="/lib/jquery/jquery-ui-multiselect-widget-3.0.0/src/jquery.multiselect.filter.js"></script>	
<cfif isdefined("addheaderresource")>
	<cfif addheaderresource EQ "feedreader">
		<script type="text/javascript" src="/lib/misc/jquery-migrate-1.0.0.js"></script>
		<script type="text/javascript" src="/lib/misc/jquery.jfeed.js"></script>
	 </cfif>
</cfif>
<cfif CGI.script_name CONTAINS "/transactions/" OR CGI.script_name IS "/Transactions.cfm">
	<script type="text/javascript" src="/transactions/js/transactions.js"></script>
</cfif>

<cfif not isdefined("session.header_color")>
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
</cfif>
<!--- End workaround --->

<a href="##content" class="sr-only sr-only-focusable mx-3 d-block px-2 py-1" aria-label="Skip to main content" title="skip navigation">Skip to main content</a>
<header id="header" role="heading" class="border-bottom">
<!--- TODO: [Michelle] Move (this fixed) background-color for this top black bar to a stylesheet. --->
<div class="branding clearfix bg-black">
	<div class="branding-left justify-content-start">
		<a href="http://www.harvard.edu/" aria-label="link to Harvard website"> 
			<img class="shield" src="/shared/images/Harvard_shield-University.png" alt="Harvard University Shield">
			<span class="d-inline-block parent">Harvard University</span>
		</a> 
	</div>
	<div class="branding-right justify-content-end"> 
		<a href="https://www.harvard.edu/about-harvard" class="font-weight-bold" aria-label="link to Harvard website">HARVARD.EDU</a> 
	</div>
</div>
<div class="navbar justify-content-start navbar-expand-md navbar-expand-sm navbar-harvard harvard_banner border-bottom border-dark">
	<!--- Obtain header_color and matching link color for this list from server specific values set in Application.cfm  --->
	<ul class="navbar col-lg-9 col-xs-6 p-0 m-0" style="background-color: #header_color#; ">
		<li class="nav-item mcz2">
			<a href="https://www.mcz.harvard.edu/" target="_blank" rel="noreferrer" style="color: #collection_link_color#;" >Museum of Comparative Zoology</a>
		</li>
		<li class="nav-item mczbase my-1 py-0">
			<a href="/" target="_blank" style="color: #collection_link_color#" >#session.collection_link_text#</a>
		</li>
	</ul>
	<ul class="navbar col-lg-3 col-sm-3 p-0 m-0 d-flex justify-content-end">
		<li class="nav-item d-flex align-content-end"> 
			<a href="https://mcz.harvard.edu" aria-label="link to MCZ website"><img class="mcz_logo_krono" src="/shared/images/mcz_logo_white_left.png" width="160" alt="mcz kronosaurus logo with link to website"></a> 
		</li>
		
	</ul>

</div>


<nav class="navbar navbar-expand-lg navbar-light bg-light">
	<button class="navbar-toggler" type="button" data-toggle="collapse" 
			data-target="##navbarToggler1" aria-controls="navbarToggler1" 
			aria-expanded="false" aria-label="Toggle navigation">
		<span class="navbar-toggler-icon"></span>
	</button>

	<div class="collapse navbar-collapse" id="navbarToggler1">
		<ul class="navbar-nav mr-auto mt-0 mt-lg-0">
			<cfif isdefined("Application.header_image")>
				<!---  Redesign menu for integration on production --->
				<li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink4" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
						Search
					</a>
					<div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink4">
						<a class="dropdown-item <cfif pageTitle EQ "Search Transactions">active </cfif>" name="find transactions" href="/SpecimenSearch.cfm">Specimen Search</a>
					</div>
				</li>
				<li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink4" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
						Transactions
					</a>
					<div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink4">
						<a class="dropdown-item <cfif pageTitle EQ "Search Transactions">active </cfif>" name="find transactions" href="/Transactions.cfm">Find Transactions</a>
						<a class="dropdown-item <cfif pageTitle EQ "Find Loans">active </cfif>" name="find loans" href="/Transactions.cfm?action=findLoans">Find Loans</a>
					</div>
				</li>
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					<li class="nav-item dropdown">
						<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLinka" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
							Account
							<cfif isdefined("session.username") and len(#session.username#) gt 0 and session.roles contains "public">
								<i class="fas fa-user-check color-green"></i> 
							<cfelse>
								<i class="fas fa-user-cog text-body"></i> 
							</cfif>	
						</a>
						<div class="dropdown-menu pl-5 pl-md-0" aria-labelledby="navbarDropdownMenuLinka">
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
			<cfelse>
				<!---  Redesign menu for the redesign --->
				<li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink1" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
						Data Searches
					</a>
					<div class="dropdown-menu pl-5 pl-md-0" aria-labelledby="navbarDropdownMenuLink1">
						<a class="dropdown-item <cfif pageTitle EQ "Search Specimens">active </cfif>" aria-label="specimen search" name="specimens" href="/Specimens.cfm">Specimens</a>
						<a class="dropdown-item" aria-label="media search" name="media" href="##">Media</a>
						<a class="dropdown-item" aria-label="places search" name="places" href="##">Places</a>
						<a class="dropdown-item" aria-label="publication search" name="publications" href="##">Publications</a>
						<a class="dropdown-item" aria-label="agent search" name="agents" href="##">Agents</a>
						<a class="dropdown-item" aria-label="taxonomy search" name="taxonomy" href="/TaxonomySearch.cfm">Taxonomy</a>
					</div>
				</li>
				<li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink2" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
						Data Entry
					</a>
					<div class="dropdown-menu pl-5 pl-md-0" aria-labelledby="navbarDropdownMenuLink2">
						<a class="dropdown-item <cfif pageTitle EQ "Data Entry">active </cfif>" name="enter a record" href="/DataEntry.cfm">Enter a Record</a>
						<a class="dropdown-item" name="bulkload records" href="##">Bulkload Records</a>
						<a class="dropdown-item" name="bulkload builder" href="##">Bulkload Builder</a>
						<a class="dropdown-item" name="browse and edit" href="##">Browse and Edit</a>
						<a class="dropdown-item" name="bulkloader status" href="##">Bulkloader Status</a>
						<a class="dropdown-item" name="batch tools" href="##">Batch Tools</a>
					</div>
				</li>
				<li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink3" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
						Manage Data
					</a>
					<div class="dropdown-menu pl-5 pl-md-0" aria-labelledby="navbarDropdownMenuLink3">
						<a class="dropdown-item" name="projects" href="##">Projects</a>
						<a class="dropdown-item" name="statistics" href="##">Statistics</a>
						<a class="dropdown-item" name="annual reports" href="##">Annual Reports</a>
						<a class="dropdown-item" name="recently georeferenced localities" href="##">Recently Georefereced Localities</a>
						<a class="dropdown-item" name="taxonomy review" href="##">Taxonomy Review</a>
						<a class="dropdown-item" name="object tracking" href="##">Object Tracking</a>
						<a class="dropdown-item" name="encumbrances" href="##">Encumbrances</a>
						<a class="dropdown-item" name="record review" href="##">Record Review</a>
					</div>
				</li>
				<li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink4" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
						Transactions
					</a>
					<div class="dropdown-menu pl-5 pl-md-0" aria-labelledby="navbarDropdownMenuLink4">
						<a class="dropdown-item <cfif pageTitle EQ "Search Transactions">active </cfif>" name="find transactions" href="/Transactions.cfm">Find Transactions</a>
						<a class="dropdown-item" name="accessions" href="##">Accessions</a>
						<a class="dropdown-item" name="deaccessions" href="##">Deaccessions</a>
						<a class="dropdown-item" name="borrows" href="##">Borrows</a>
						<a class="dropdown-item <cfif pageTitle EQ "Create New Loan">active </cfif>" name="create new loan" href="/transactions/Loan.cfm?action=newLoan">New Loan</a>
						<a class="dropdown-item <cfif pageTitle EQ "Find Loans">active </cfif>" name="find loans" href="/Transactions.cfm?action=findLoans">Find Loans</a>
						<a class="dropdown-item" name="permits" href="##">Permits</a>
					</div>
				</li>
				<li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink5" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
						Help
					</a>
					<div class="dropdown-menu pl-5 pl-md-0" aria-labelledby="navbarDropdownMenuLink5">
						<a class="dropdown-item" name="MCZbase Wiki" href="##">MCZbase Wiki</a>
						<a class="dropdown-item" name="about MCZbase" href="##">About MCZbase</a>
						<a class="dropdown-item" name="Site Map" href="/SiteMap.cfm">Site Map</a>
					</div>
				</li>
			
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
				</ul>
				<ul class="navbar-nav ml-auto mt-0 mt-lg-0">
					<li class="nav-item dropdown">
						<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLinka" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
							Account
							<cfif isdefined("session.username") and len(#session.username#) gt 0 and session.roles contains "public">
								<i class="fas fa-user-check color-green"></i> 
							<cfelse>
								<i class="fas fa-user-cog text-body"></i> 
							</cfif>	
						</a>
						<div class="dropdown-menu pl-5 pl-md-0" aria-labelledby="navbarDropdownMenuLinka">
							<cfif session.roles contains "coldfusion_user">
								<form name="profile" method="post" action="/UserProfile.cfm">
									<input type="hidden" name="action" value="nothing">
									<input type="submit" aria-label="Search" value="User Profile" class="anchor-button form-control mr-sm-0 my-0" placeholder="User Profile" onClick="logIn.action.value='nothing';submit();">
								</form>
							</cfif>
							<cfif session.roles contains "public">
								<a class="dropdown-item pl-5 pl-md-2" href="/customSettings.cfm">Custom Settings</a> 
								<a class="dropdown-item pl-5 pl-md-2" href="/saveSearch.cfm?action=manage">Saved Searches</a>
							</cfif>
						</div>
					</li>
				</ul>
				
				</cfif>	
			</cfif> <!--- End of Menu for redesign --->
		</ul><!--- end of menu ul --->
	</div><!--- end navbarToggler1 --->
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
			<form name="logIn" method="post" action="/login.cfm" class="m-0">
				<input type="hidden" name="action" value="signIn">
				<!---This is needed for the first login from the header. I have a default #gtp# on login.cfm.--->
				<input type="hidden" name="gotopage" value="#gtp#">
				<div class="login-form" id="header_login_form_div">
					<label for="Username" class="sr-only"> Username:</label>
					<input type="text" name="username" id="Username" placeholder="username" class="loginButtons">
					<label for="Password" class="mr-1 sr-only"> Password:</label>
					<input type="password" id="Password" name="password" autocomplete="current password" placeholder="password" title="Password" size="14" class="loginButtons">
					<label for="Login" class="mr-1 sr-only"> Password:</label>
					<input type="submit" value="Log In" id="login" class="btn-primary loginButtons"  onClick="logIn.action.value='signIn';submit();" aria-label="click to login">
					<label for="CreateAccount" class="mr-1 sr-only"> Password:</label>
					<input type="submit" value="Register" class="btn-primary loginButtons" id="create_account" onClick="logIn.action.value='newUser';submit();" aria-label="click to create new account">
				</div>
			</form>
		</cfif>
</nav>
</header>
<script type="text/javascript"> 
	/** add active class and stay opened when selected */ 
	var url = window.location; 
	// for sidebar menu entirely but not cover treeview 
	$('ul.navbar-nav a').filter(function() { return this.href == url; }).parent().addClass('active'); 
	// for treeview 
	$('ul.navbar-nav a').filter(function() { return this.href == url; }).parentsUntil(".navbar > .navbar-nav").addClass('active');
	
	
	$(".navbar-nav .nav-link a").on("click", function(){
	 $(".nav-link").find(".show").removeClass("show");
	 $(this).addClass("show");
});
</script>
<cf_rolecheck>
</cfoutput>
<cfset HEADER_DELIVERED=true>
	
