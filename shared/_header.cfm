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
<cfif not isdefined("session.header_color")>
	<cfif NOT isDefined('setDbUser')>
		<cfinclude template="/shared/loginFunctions.cfm">
	</cfif>
	<cfset setDbUser()>
</cfif>
<style type="text/css"></style>
<script>
var acc = document.getElementsByClassName("accordion");
var i;

for (i = 0; i < acc.length; i++) {
  acc[i].addEventListener("click", function() {
    /* Toggle between adding and removing the "active" class,
    to highlight the button that controls the panel */
    this.classList.toggle("active");

    /* Toggle between hiding and showing the active panel */
    var panel = this.nextElementSibling;
    if (panel.style.display === "block") {
      panel.style.display = "none";
    } else {
      panel.style.display = "block";
    }
  });
}
</script>
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
			<li class="nav-item d-flex align-content-end"> <a href="https://mcz.harvard.edu" aria-label="link to MCZ website"><img class="mcz_logo_krono" src="/shared/images/mcz_logo_white_left.png" width="160" alt="mcz kronosaurus logo with link to website"></a> </li>
		</ul>
	</div>
	<div class="container-fluid bg-light px-0 px-lg-4">
	<!---	
Temporaraly disabling redesign/production menus while work is done on sub menus.
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
								<i class="fas fa-user-check color-green"></i>_
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
		$(function() {
  // ------------------------------------------------------- //
  // Multi Level dropdowns
  // ------------------------------------------------------ //
  $("ul.dropdown-menu [data-toggle='dropdown']").on("click", function(event) {
    event.preventDefault();
    event.stopPropagation();

    $(this).siblings().toggleClass("show");


    if (!$(this).next().hasClass('show')) {
      $(this).parents('.dropdown-menu').first().find('.show').removeClass("show");
    }
    $(this).parents('li.nav-item.dropdown.show').on('hidden.bs.dropdown', function(e) {
      $('.dropdown-submenu .show').removeClass("show");
    });

  });
});
</script>
<style>
.dropdown-submenu {
  position: relative;
}
.dropdown-submenu>.dropdown-menu {
  top: 0;
  left: 100%;
  margin-top: 0px;
  margin-left: 0px;
}
@media (min-width: 991px) {
  .dropdown-menu {
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
  }
}
</style>
		<nav class="navbar navbar-expand-lg navbar-light bg-white py-3 shadow-sm">
			<div class="container-fluid">
				<button type="button" data-toggle="collapse" data-target="##navbarContent" aria-controls="navbars" aria-expanded="false" aria-label="Toggle navigation" class="navbar-toggler"> <span class="navbar-toggler-icon"></span> </button>
				<div id="navbarContent" class="collapse navbar-collapse">
					<ul class="navbar-nav mr-auto">
					<!-- Level one dropdown -->
					<li class="nav-item dropdown"> <a id="dropdownMenu1" href="##" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" class="nav-link dropdown-toggle">Search</a>
						<ul aria-labelledby="dropdownMenu1" class="dropdown-menu border-0 shadow">
							<li><a href="##" class="dropdown-item">Specimens.cfm </a></li>
							<li><a href="##" class="dropdown-item">Taxonomy.cfm</a></li>
							<li class="dropdown-divider"></li>
							<!-- Level two dropdown-->
								<li class="dropdown-submenu"> <a id="dropdownMenu2" href="##" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" class="dropdown-item">Hover for action &raquo;</a>
									<ul aria-labelledby="dropdownMenu2" class="dropdown-menu border-0 shadow">
										<li><a href="##" class="dropdown-item">level 2</a></li>
										<li><a href="##" class="dropdown-item">level 2</a></li>
										<li><a href="##" class="dropdown-item">level 2</a></li>
									</ul>
								</li>
							<!-- End Level two -->
							<li><a href="##" class="dropdown-item">Media.cfm</a></li>
						</ul>
					</li>
					<li class="nav-item dropdown"> <a id="dropdownMenuk" href="##" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" class="nav-link dropdown-toggle">Data Entry</a>
						<ul aria-labelledby="dropdownMenuk" class="dropdown-menu border-0 shadow">
							<li><a href="##" class="dropdown-item">Some action </a></li>
							<li><a href="##" class="dropdown-item">Some other action</a></li>
							<li class="dropdown-divider"></li>
							
							<!-- Level two dropdown-->
							<li class="dropdown-submenu"> <a id="dropdownMenul" href="##" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" class="dropdown-item dropdown-toggle">Hover for action</a>
								<ul aria-labelledby="dropdownMenul" class="dropdown-menu border-0 shadow">
									<li><a href="##" class="dropdown-item">level 2</a></li>
									<li><a href="##" class="dropdown-item">level 2</a></li>
									<li><a href="##" class="dropdown-item">level 2</a></li>
								</ul>
							</li>
							<!-- End Level two -->
						</ul>
					</li>
					<li class="nav-item"><a href="##" class="nav-link">About</a></li>
					<li class="nav-item"><a href="##" class="nav-link">Services</a></li>
					<li class="nav-item"><a href="##" class="nav-link">Contact</a></li>
					<cfif isdefined("session.username") and len(#session.username#) gt 0>
						</ul>
						<!--- end of menu ul --->
						
					<ul class="navbar-nav ml-auto">
					<!-- Level one dropdown -->
					<li class="nav-item dropdown"> 
						
						<a id="dropdownMenu1" href="##" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" class="nav-link dropdown-toggle">Account 
						<cfif isdefined("session.username") and len(#session.username#) gt 0 and session.roles contains "public">
							<i class="fas fa-user-check color-green"></i>
							<cfelse>
							<i class="fas fa-user-cog text-body"></i>
						</cfif>
						</a>
						<ul aria-labelledby="dropdownMenu1" class="dropdown-menu border-0 shadow">
							<li><a href="##" class="dropdown-item">
								<cfif session.roles contains "coldfusion_user">
								<form name="profile" method="post" action="/UserProfile.cfm">
									<input type="hidden" name="action" value="nothing">
									<input type="submit" aria-label="Search" value="User Profile" class="anchor-button form-control"  placeholder="User Profile" onClick="logIn.action.value='nothing';submit();">
								</form>
								</cfif> 
								</a>
							</li>
							<cfif session.roles contains "public">
								<cfif session.roles contains "public">
							<li><a href="/saveSearch.cfm?action=manage">Saved Searches</a></li>
						</cfif>
							</cfif>
						
						</ul>
					</li>
			
					</ul>
						</cfif>
				</div>
				<!--- end navbarToggler1 --->
		
			</div>
		
		</nav>
		
		<!---<div class="dropdown">
  <button class="btn btn-secondary dropdown-toggle" type="button" id="dropdownMenuButton" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
    Dropdown button
  </button>
  <div class="dropdown-menu" aria-labelledby="dropdownMenuButton">
    <a class="dropdown-item" href="##">Action</a>
    <a class="dropdown-item" href="##">Another action</a>
    <a class="dropdown-item" href="##">Something else here</a>
  </div>
</div>---> 
		
		<!---<nav class="navbar dropdown navbar-expand-lg navbar-light" role="navigation" id="navigation" aria-label="main menu" >
			<button class="navbar-toggler" type="button" data-toggle="collapse" aria-controls="menu-list" aria-label="Toggle navigation" aria-expanded="true"> 
				<span class="navbar-toggler-icon"></span> 
			</button>
			<div class="mt-1 mt-lg-0 collapse navbar-collapse" id="main_nav">
				<ul class="nav-menu mr-lg-auto" id="menu-list" role="menu">
					<li>
						<a href="##" role="button" name="Search" aria-haspopup="true" tabindex="0" aria-expanded="true" aria-control="oneSubMenu">Search</a>
						<ul class="dropdown show" aria-label="submenu" role="menu" id="oneSubMenu">
							<li role="menuitem"><a tabindex="-1" href="/Specimens.cfm">Specimens</a></li>
							<li role="menuitem"><a href="##">Media</a></li>
							<li role="menuitem"><a href="##">Publications</a></li>
							<li role="menuitem"><a href="/Taxa.cfm">Taxonomy</a></li>
						</ul>
					</li>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"data_entry")>
						<li><a href="##" tabindex="0" role="menuitem" name="Enter Data" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Enter Data</a>
							   <ul class="dropdown" aria-label="submenu">
								<li>
									<a href="##" tabindex="-1" class="accordion dropdown-item" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">New Record</a>
								   <ul class="dropdown panel" aria-label="submenu">
										<li><a tabindex="-1" href="/DataEntry.cfm" class="dropdown-item">Specimen</a></li>
										<li><a tabindex="-1" href="##" class="dropdown-item">Media</a></li>
										<li><a tabindex="-1" href="##" class="dropdowon-item">Publication</a></li>
										<li><a tabindex="-1" href="##" class="dropdown-item">Agent</a></li>
									</ul>
								</li>
								<li>
									<a href="##" tabindex="-1" class="accordion">Bulkloader</a>
									<ul class="dropdown panel" aria-label="submenu">
										<li><a href="##" class="dropdown-item">Bulkload Specimens</a></li>
										<li><a href="##" class="dropdown-item">Bulkloader Status</a></li>
										<li><a href="##">Bulkload .CSV Builder</a></li>
										<li><a href="##">Browse and Edit Staged Records</a></li>
									</ul>
								</li>
								<li><a href="##" tabindex="-1" class="accordion">Batch Tools</a>
									<ul class="dropdown panel" aria-label="submenu">
										<li><a href="##">Agents</a></li>
										<li><a href="##">Attributes</a></li>
										<li><a href="##">Containers</a></li>
										<li><a href="##">Media</a></li>
									</ul>
								</li>
							</ul>
						</li>
					</cfif>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
						<li><a tabindex="0" role="menuitem" name="Transactions" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" href="##">Transactions</a>
							<ul class="dropdown" class="accordion" aria-label="submenu">
								<li><a href="/Transactions.cfm?action=findLoans">All Transactions</a></li>
								<li><a href="##" class="accordion">Accessions</a>
									<ul class="dropdown panel" aria-label="submenu">
										<li><a href="##">Search & Edit </a></li>
										<li><a href="##">New Accession </a></li>
									</ul></li>
								<li><a href="##" class="accordion">Borrows</a>
									<ul class="dropdown panel" aria-label="submenu">
										<li><a href="##">Search & Edit </a></li>
										<li><a href="##">New Borrow </a></li>
									</ul></li>
								<li><a href="##" class="accordion">Deaccessions</a>	
									<ul class="dropdown panel" aria-label="submenu">
										<li><a href="##">Search & Edit </a></li>
										<li><a href="##">New Deaccession </a></li>
									</ul>
								</li>
								<li><a href="##" class="accordion">Loans</a>
									<ul class="dropdown panel" aria-label="submenu">
										<li><a href="/Transactions.cfm?action=findLoans">Search & Edit </a></li>
										<li><a href="##">New Loan </a></li>
									</ul>
								</li>
								<li><a href="##" class="accordion">Permits</a>
									<ul class="dropdown panel" aria-label="submenu">
										<li><a href="##">Search & Edit </a></li>
										<li><a href="##">New Permit </a></li>
									</ul>
								</li>
							</ul>
						</li>
					</cfif>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					<li><a tabindex="0" href="##" role="menuitem" data-toggle="dropdown" aria-haspopup="true" name="Tools" aria-expanded="false" >Tools</a>
						<ul class="dropdown" aria-label="submenu">
							<li><a href="##">Projects </a></li>
							<li><a href="/grouping/NamedCollection.cfm">Named Collections </a></li>
							<li><a href="/vocabularies/CollEventNumberSeries.cfm">Collecting Event Number Series </a></li>
							<li><a href="##">Object Tracking </a></li>
							<li><a href="##">Encumbrances </a></li>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_codetables")>
								<li><a href="##">Manage code tables</a></li>
							</cfif>
						</ul>
					</li>
					</cfif>
					<li><a tabindex="0" href="##" role="menuitem" data-toggle="dropdown" aria-haspopup="true" name="Help" aria-expanded="false">Help</a>
						<ul class="dropdown" aria-label="submenu">
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							<li><a name="MCZbase Wiki" href="https://code.mcz.harvard.edu/wiki/index.php/Using_MCZbase">Using MCZbase</a></li>
							<li><a name="Controlled Vocabularies" href="/vocabularies/ControlledVocabulary.cfm">Controlled Vocabularies</a></li>
						</cfif>
						<li><a  name="about MCZbase" href="https://mcz.harvard.edu/database">About MCZbase</a></li>
						</ul>
					</li>
				
					<cfif isdefined("session.username") and len(#session.username#) gt 0>
						</ul>
					<ul class="nav-menu ml-auto">
					<li><a tabindex="0" href="##" role="menuitem" data-toggle="dropdown" aria-haspopup="true" name="Account" aria-expanded="false">Account</a>
							<cfif isdefined("session.username") and len(#session.username#) gt 0 and session.roles contains "public">
								<i class="fas fa-user-check color-green"></i>
							<cfelse>
								<i class="fas fa-user-cog text-body"></i> 
							</cfif>	
						</a>
						<ul class="dropdown" aria-label="submenu">
							<cfif session.roles contains "coldfusion_user">
								<li>
								<form name="profile" method="post" action="/UserProfile.cfm">
									<input type="hidden" name="action" value="nothing">
									<input type="submit" aria-label="Search" value="User Profile" class="anchor-button form-control mr-sm-0 mt-2 mb-1 my-lg-0 px-5 px-lg-4 pt-1 bg-light text-left" style="height: 34px;font-size: .92em; margin-top:2px;"  placeholder="User Profile" onClick="logIn.action.value='nothing';submit();">
								</form>
								</li>
							</cfif>
							<cfif session.roles contains "public">
								<li><a href="/saveSearch.cfm?action=manage">Saved Searches</a></li>
							</cfif>
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
						<!---This is needed for the first login from the header. I have a default #gtp# on login.cfm.--->
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
		</nav>--->
<!---	</cfif>
	</div>--->
	<!-- container //  --> 
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
