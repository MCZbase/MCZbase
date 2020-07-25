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
<!--- link rel="stylesheet" href="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/styles/jqx.light.css"---><!--- TODO: Remove, makes jqxgrid header hard to understand--->
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
<script type="text/javascript">
///// some script
//
//// jquery ready start
//$(document).ready(function() {
//	// jQuery code
//
//	//////////////////////// Prevent closing from click inside dropdown
//    $(document).on('click', '.dropdown-menu', function (e) {
//      e.stopPropagation();
//    });
//
//    // make it as accordion for smaller screens
//    if ($(window).width() < 992) {
//	  	$('.dropdown-menu li a').click(function(e){
//	  		e.preventDefault();
//	        if($(this).next('.submenu').length){
//	        	$(this).next('.submenu').toggle();
//	        }
//	        $('.dropdown').on('hide.bs.dropdown', function () {
//			   $(this).find('.submenu').hide();
//			})
//	  	});
//	}
//	
//}); // jquery end
</script>
<style type="text/css">
nav {    
  display: block;
  text-align: center;
}
nav ul {
  margin: 0;
  padding:0;
  list-style: none;
}
.nav a {
  display:block; 
  background: ##111; 
  color: ##fff; 
  text-decoration: none;
  padding: 0.8em 1.8em;
  text-transform: uppercase;
  font-size: 80%;
  letter-spacing: 2px;
  text-shadow: 0 -1px 0 ##000;
  position: relative;
}
.nav{  
  vertical-align: top; 
  display: inline-block;
  box-shadow: 
    1px -1px -1px 1px ##000, 
    -1px 1px -1px 1px ##fff, 
    0 0 6px 3px ##fff;
  border-radius:6px;
}
.nav li {
  position: relative;
}
.nav > li { 
  float: left; 
  border-bottom: 4px ##aaa solid; 
  margin-right: 1px; 
} 
.nav > li > a { 
  margin-bottom: 1px;
  box-shadow: inset 0 2em .33em -0.5em ##555; 
}
.nav > li:hover, 
.nav > li:hover > a { 
  border-bottom-color: blue;
}
.nav li:hover > a { 
  color:blue; 
}
.nav > li:first-child { 
  border-radius: 4px 0 0 4px;
} 
.nav > li:first-child > a { 
  border-radius: 4px 0 0 0;
}
.nav > li:last-child { 
  border-radius: 0 0 4px 0; 
  margin-right: 0;
} 
.nav > li:last-child > a { 
  border-radius: 0 4px 0 0;
}
.nav li li a { 
  margin-top: 1px;
}
.nav li a:first-child:nth-last-child(2):before { 
  content: ""; 
  position: absolute; 
  height: 0; 
  width: 0; 
  border: 5px solid transparent; 
  top: 50% ;
  right:5px;  
 }
	/* submenu positioning*/
.nav ul {
  position: absolute;
  white-space: nowrap;
  border-bottom: 5px solid  blue;
  z-index: 1;
  left: -99999em;
}
.nav > li:hover > ul {
  left: auto;
  margin-top: 5px;
  min-width: 100%;
}
.nav > li li:hover > ul { 
  left: 100%;
  margin-left: 1px;
  top: -1px;
}
/* arrow hover styling */
.nav > li > a:first-child:nth-last-child(2):before { 
  border-top-color: ##aaa; 
}
.nav > li:hover > a:first-child:nth-last-child(2):before {
  border: 5px solid transparent; 
  border-bottom-color: blue; 
  margin-top:-5px
}
.nav li li > a:first-child:nth-last-child(2):before {  
  border-left-color: ##aaa; 
  margin-top: -5px
}
.nav li li:hover > a:first-child:nth-last-child(2):before {
  border: 5px solid transparent; 
  border-right-color: blue;
  right: 10px; 
}
@media (max-width: 44em){
.nav li a:first-child:nth-last-child(2):before { 
  position: relative; 
 }
	/* submenu positioning*/
.nav ul {
  position: relative;
}
  nav[role="full-horizontal"] {
    ul > li {
      width: 100%;
    }
}
</style>
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
	<!--- TODO: [Michelle] Move (this fixed) background-color for this top black bar to a stylesheet. --->
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
<div class="container-fluid bg-light">
	<!---	<nav class="navbar navbar-expand-lg navbar-light">
			<button class="navbar-toggler" type="button" data-toggle="collapse" aria-label="Toggle navigation" data-target="##main_nav"> <span class="navbar-toggler-icon"></span> </button>
			<div class="collapse navbar-collapse" id="main_nav">
				<ul class="navbar-nav">
				<li class="nav-item dropdown"> 
					<a class="nav-link dropdown-toggle" href="##" data-toggle="dropdown"> Search </a>
					<ul class="dropdown-menu">
						<li><a class="dropdown-item" href="/Specimens.cfm">Specimens</a></li>
						<li><a class="dropdown-item" href="/Taxa.cfm">Taxonomy </a></li>
						<li><a class="dropdown-item" href="##">Media </a></li>
						<li><a class="dropdown-item" href="##">Publications </a></li>
						<li><a class="dropdown-item" href="##">Localities </a></li>
						<li><a class="dropdown-item" href="##">Agents </a></li>
					</ul>
				</li>
				<li class="nav-item dropdown"> 
					<a class="nav-link dropdown-toggle" href="##" data-toggle="dropdown"> Enter Data </a>
					<ul class="dropdown-menu">
						<li><a class="dropdown-item" href="##"> New Record &raquo </a>
							<ul class="submenu dropdown-menu">
								<li><a class="dropdown-item" href="/DataEntry.cfm">Specimen</a></li>
								<li><a class="dropdown-item" href="">Taxonomy</a></li>
								<li><a class="dropdown-item" href="">Media</a></li>
								<li><a class="dropdown-item" href="">Publication</a></li>
								<li><a class="dropdown-item" href="">Locality</a></li>
								<li><a class="dropdown-item" href="">Agent</a></li>
							</ul>
						</li>
						<li><a class="dropdown-item" href="##"> Bulkloader &raquo </a>
							<ul class="submenu dropdown-menu">
								<li><a class="dropdown-item" href="">Bulkload Specimens</a></li>
								<li><a class="dropdown-item" href="">Bulkloader Status</a></li>
								<li><a class="dropdown-item" href="">Bulkload Builder</a></li>
								<li><a class="dropdown-item" href="">Browse &amp; Edit</a></li>
							</ul>
						</li>
						<li><a class="dropdown-item" href="##"> Batch Tools &raquo </a>
							<ul class="submenu dropdown-menu">
								<li><a class="dropdown-item" href="">Agents</a></li>
								<li><a class="dropdown-item" href="">Attributes</a></li>
								<li><a class="dropdown-item" href="">Citations</a></li>
								<li><a class="dropdown-item" href="">Containers &raquo </a>
									<ul class="submenu dropdown-menu">
										<li><a class="dropdown-item" href="">Edit Containers</a></li>
										<li><a class="dropdown-item" href="">Parts to Containers</a></li>
									</ul>
								</li>
								<li><a class="dropdown-item" href="">Georeferences</a></li>
								<li><a class="dropdown-item" href="">Identifiers</a></li>
								<li><a class="dropdown-item" href="">Loans &raquo </a>
									<ul class="submenu dropdown-menu">
										<li><a class="dropdown-item" href="">Loan Items</a></li>
										<li><a class="dropdown-item" href="">Loans of Data</a></li>
									</ul>
								</li>
								<li><a class="dropdown-item" href="">Media</a></li>
								<li><a class="dropdown-item" href="">Parts &raquo </a>
									<ul class="submenu dropdown-menu">
										<li><a class="dropdown-item" href="">New Parts</a></li>
										<li><a class="dropdown-item" href="">Edited Parts</a></li>
										<li><a class="dropdown-item" href="">Parts to Containers</a></li>
									</ul>
								</li>
								<li><a class="dropdown-item" href="">Relationships</a></li>
								<li><a class="dropdown-item" href="">Taxonomy</a></li>
							</ul>
						</li>
					</ul>
				</li>
				<li class="nav-item dropdown"> 
					<a class="nav-link dropdown-toggle" href="##" data-toggle="dropdown"> Transactions</a>
					<ul class="dropdown-menu">
						<li><a class="dropdown-item" href="/Transactions.cfm?action=findAll">Search All Transactions </a></li>
						<li><a class="dropdown-item">Accessions &raquo; </a>
							<ul class="submenu dropdown-menu">
								<li><a class="dropdown-item" href="">Search & Edit</a></li>
								<li><a class="dropdown-item" href="">New Accession</a></li>
							</ul>
						</li>
						<li><a class="dropdown-item">Borrows &raquo; </a>
							<ul class="submenu dropdown-menu">
								<li><a class="dropdown-item" href="">Search & Edit</a></li>
								<li><a class="dropdown-item" href="">New Borrow</a></li>
							</ul>
						</li>
						<li><a class="dropdown-item">Deaccessions &raquo; </a>
							<ul class="submenu dropdown-menu">
								<li><a class="dropdown-item" href="">Search & Edit</a></li>
								<li><a class="dropdown-item" href="">New Deaccession</a></li>
							</ul>
						</li>
						<li><a class="dropdown-item">Loans &raquo; </a>
							<ul class="submenu dropdown-menu">
								<li><a class="dropdown-item" href="/Transactions.cfm?action=findLoans">Search & Edit</a></li>
								<li><a class="dropdown-item" href="">New Loan</a></li>
							</ul>
						</li>
						<li><a class="dropdown-item">Permits &raquo; </a>
							<ul class="submenu dropdown-menu">
								<li><a class="dropdown-item" href="">Search & Edit</a></li>
								<li><a class="dropdown-item" href="">New Permit</a></li>
							</ul>
						</li>
					</ul>
				</li>
				<li class="nav-item dropdown"> 
					<a class="nav-link dropdown-toggle" href="##" data-toggle="dropdown"> Tools</a>
					<ul class="dropdown-menu">
						<li><a class="dropdown-item">Projects </a></li>
						<li><a class="dropdown-item" href="/grouping/NamedCollection.cfm">Named Collections </a></li>
						<li><a class="dropdown-item" href="/vocabularies/CollEventNumberSeries.cfm">Collecting Event Number Series </a></li>
						<li><a class="dropdown-item">Object Tracking </a></li>
						<li><a class="dropdown-item">Encumbrances </a></li>
					</ul>
				</li>
				<li class="nav-item dropdown"> 
					<a class="nav-link dropdown-toggle" href="##" data-toggle="dropdown"> About</a>
					<ul class="dropdown-menu">
						<li><a class="dropdown-item" href="https://code.mcz.harvard.edu/wiki/index.php/Using_MCZbase">Using MCZbase </a></li>
						<li><a class="dropdown-item">About MCZbase</a></li>
						<li><a class="dropdown-item">MCZbase Statistics </a></li>
						<li><a class="dropdown-item">Self-service Reports &raquo; </a>
							<ul class="submenu dropdown-menu">
								<li><a class="dropdown-item" href="">Loan</a></li>
								<li><a class="dropdown-item" href="">By Taxonomy</a></li>
								<li><a class="dropdown-item" href="">Part Usage</a></li>
							</ul>
						</li>
					</ul>
				</li>
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					</ul>
					<ul class="navbar-nav ml-auto mt-0 mt-lg-0">
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
									<a class="dropdown-item pl-5 pl-lg-2" href="/customSettings.cfm">Custom Settings</a> <a class="dropdown-item pl-5 pl-lg-2" href="/saveSearch.cfm?action=manage">Saved Searches</a>
								</cfif>
							</div>
						</li>
					</ul>
				</cfif>
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
<!---						<input type="hidden" name="gotopage" value="#gtp#">
						<div class="login-form" id="header_login_form_div">
							<label for="username" class="sr-only"> Username:</label>
							<input type="text" name="username" id="username" placeholder="username" class="loginButtons">
							<label for="password" class="mr-1 sr-only"> Password:</label>
							<input type="password" id="password" name="password" autocomplete="current password" placeholder="password" title="Password" size="14" class="loginButtons">
							<label for="login" class="mr-1 sr-only"> Password:</label>
							<input type="submit" value="Log In" id="login" class="btn-primary loginButtons"  onClick="logIn.action.value='signIn';submit();" aria-label="click to login">
							<label for="create_account" class="mr-1 sr-only"> Password:</label>
							<input type="submit" value="Register" class="btn-primary loginButtons" id="create_account" onClick="logIn.action.value='newUser';submit();" aria-label="click to create new account">
						</div>
					</form>
				</cfif>
			</div>--->
			<!-- navbar-collapse.// --> 
			
		</nav>--->
<nav role="full-horizontal">
<button class="navbar-toggler" type="button" data-toggle="collapse" aria-label="Toggle navigation" data-target="##main_nav"> <span class="navbar-toggler-icon"></span> </button>
<div class="collapse navbar-collapse" id="main_nav">
<ul class="nav">
    <li><a href="##">home</a></li>
    <li><a href="##">Search</a>
      <ul>
        <li><a href="/Specimens.cfm">Specimens</a></li>
        <li><a href="##">Taxonomy</a></li>
        <li><a href="##">Media</a></li>
        <li><a href="##">Publications</a></li>
		  <li><a href="/Taxa.cfm">Publications</a></li>
      </ul>
    </li>
    <li><a href="##">Enter Data</a>
      <ul>
   
        <li><a href="##">New Record</a>
          <ul>
            <li><a href="/DataEntry.cfm">Specimen</a></li>
            <li><a href="##">Media</a></li>
            <li><a href="##">Publication</a></li>
            <li><a href="##">Agent</a></li>
          </ul>
        </li>
        <li><a href="##">Bulkloader</a>
		  <ul>
            <li><a href="##">Bulkload Specimens</a></li>
            <li><a href="##">Bulkloader Status</a></li>
            <li><a href="##">Bulkload .CSV Builder</a></li>
            <li><a href="##">Browse and Edit Staged Records</a></li>
          </ul></li>
        <li><a href="##">Batch Tools</a>	  <ul>
            <li><a href="##">Agents</a></li>
            <li><a href="##">Attributes</a></li>
            <li><a href="##">Containers</a></li>
            <li><a href="##">Media</a></li>
          </ul>
		  </li>
      </ul>
    </li>
    <li><a href="##">Transactions</a>
      <ul>
        <li><a href="##">item</a></li>
        <li><a href="##">item</a></li>
        <li><a href="##">item</a></li>
        <li><a href="##">item</a></li>
      </ul>
    </li>
    <li><a href="##">About</a></li>
  </ul>
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
							<label for="username" class="sr-only"> Username:</label>
							<input type="text" name="username" id="username" placeholder="username" class="loginButtons">
							<label for="password" class="mr-1 sr-only"> Password:</label>
							<input type="password" id="password" name="password" autocomplete="current password" placeholder="password" title="Password" size="14" class="loginButtons">
							<label for="login" class="mr-1 sr-only"> Password:</label>
							<input type="submit" value="Log In" id="login" class="btn-primary loginButtons"  onClick="logIn.action.value='signIn';submit();" aria-label="click to login">
							<label for="create_account" class="mr-1 sr-only"> Password:</label>
							<input type="submit" value="Register" class="btn-primary loginButtons" id="create_account" onClick="logIn.action.value='newUser';submit();" aria-label="click to create new account">
						</div>
					</form>
				</cfif>
</div>
</nav>
</div>
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
