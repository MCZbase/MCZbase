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
<cfinclude template="/shared/functionLib.cfm"><!--- Easy to overlook this shared function file --->
<!--- include stylesheets and javascript library files --->
<link rel="stylesheet" href="/lib/bootstrap/bootstrap-4.5.0-dist/css/bootstrap.min.css"><!---needed for overall look--->
<link rel="stylesheet" href="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/styles/jqx.base.css"><!--- needed for jqxwidgets to work --->
<!--- link rel="stylesheet" href="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/styles/jqx.light.css"---><!--- TODO: Remove, makes jqxgrid header hard to understand--->
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.css"><!--- Use JQuery-UI widgets when available, only use jqwidgets for extended functionality --->
<link rel="stylesheet" href="/lib/fontawesome/fontawesome-free-5.5.0-web/css/all.css"><!-- Provides account, magnifier, and cog icons-->
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
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/jqwidgets/jqxgrid.js"></script>  <!--- jqxgrid is the primary reason we are including jqwidgets --->
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
/// some script

// jquery ready start
$(document).ready(function() {
	// jQuery code

	//////////////////////// Prevent closing from click inside dropdown
    $(document).on('click', '.dropdown-menu', function (e) {
      e.stopPropagation();
    });

    // make it as accordion for smaller screens
    if ($(window).width() < 992) {
	  	$('.dropdown-menu a').click(function(e){
	  		e.preventDefault();
	        if($(this).next('.submenu').length){
	        	$(this).next('.submenu').toggle();
	        }
	        $('.dropdown').on('hide.bs.dropdown', function () {
			   $(this).find('.submenu').hide();
			})
	  	});
	}
	
}); // jquery end
</script>
<style type="text/css">

		.dropdown-menu .dropdown-toggle:after{
			border-top: .3em solid transparent;
		    border-right: 0;
		    border-bottom: .3em solid transparent;
		    border-left: .3em solid;
		}

		.dropdown-menu .dropdown-menu{
			margin-left:0; margin-right: 0;
		}

		.dropdown-menu li{
			position: relative;
		}
		.nav-item .submenu{ 
			display: none;
			position: absolute;
			left:100%; top:-7px;
		}
		.nav-item .submenu-left{ 
			right:100%; left:auto;
		}

		.dropdown-menu > li:hover{ background-color: ##f1f1f1 }
		.dropdown-menu > li:hover > .submenu{
			display: block;
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

<div class="container-fluid">
<nav class="navbar navbar-expand-lg navbar-dark bg-light">
  <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="##main_nav">
    <span class="navbar-toggler-icon"></span>
  </button>
  <div class="collapse navbar-collapse" id="main_nav">

<ul class="navbar-nav">
	<li class="nav-item active"> <a class="nav-link" href="##">Home </a> </li>
	<li class="nav-item"><a class="nav-link" href="##"> About </a></li>
	<li class="nav-item dropdown">
		<a class="nav-link dropdown-toggle" href="##" data-toggle="dropdown">  Treeview menu  </a>
	    <ul class="dropdown-menu">
		  <li><a class="dropdown-item" href="##"> Dropdown item 1 </a></li>
		  <li><a class="dropdown-item" href="##"> Dropdown item 2 &raquo </a>
		  	 <ul class="submenu dropdown-menu">
			    <li><a class="dropdown-item" href="">Submenu item 1</a></li>
			    <li><a class="dropdown-item" href="">Submenu item 2</a></li>
			    <li><a class="dropdown-item" href="">Submenu item 3 &raquo </a>
			    	<ul class="submenu dropdown-menu">
					    <li><a class="dropdown-item" href="">Multi level 1</a></li>
					    <li><a class="dropdown-item" href="">Multi level 2</a></li>
					</ul>
			    </li>
			    <li><a class="dropdown-item" href="">Submenu item 4</a></li>
			    <li><a class="dropdown-item" href="">Submenu item 5</a></li>
			 </ul>
		  </li>
		  <li><a class="dropdown-item" href="##"> Dropdown item 3 </a></li>
		  <li><a class="dropdown-item" href="##"> Dropdown item 4 </a>
	    </ul>
	</li>
	<li class="nav-item dropdown">
		<a class="nav-link dropdown-toggle" href="##" data-toggle="dropdown">  More items  </a>
	    <ul class="dropdown-menu">
		  <li><a class="dropdown-item" href="##"> Dropdown item 1 </a></li>
		  <li><a class="dropdown-item dropdown-toggle" href="##"> Dropdown item 2 </a>
		  	 <ul class="submenu dropdown-menu">
			    <li><a class="dropdown-item" href="">Submenu item 1</a></li>
			    <li><a class="dropdown-item" href="">Submenu item 2</a></li>
			    <li><a class="dropdown-item" href="">Submenu item 3</a></li>
			 </ul>
		  </li>
		  <li><a class="dropdown-item dropdown-toggle" href="##"> Dropdown item 3 </a>
		  	 <ul class="submenu dropdown-menu">
			    <li><a class="dropdown-item" href="">Another submenu 1</a></li>
			    <li><a class="dropdown-item" href="">Another submenu 2</a></li>
			    <li><a class="dropdown-item" href="">Another submenu 3</a></li>
			    <li><a class="dropdown-item" href="">Another submenu 4</a></li>
			 </ul>
		  </li>
		  <li><a class="dropdown-item dropdown-toggle" href="##"> Dropdown item 4 </a>
		  	 <ul class="submenu dropdown-menu">
			    <li><a class="dropdown-item" href="">Another submenu 1</a></li>
			    <li><a class="dropdown-item" href="">Another submenu 2</a></li>
			    <li><a class="dropdown-item" href="">Another submenu 3</a></li>
			    <li><a class="dropdown-item" href="">Another submenu 4</a></li>
			 </ul>
		  </li>
		  <li><a class="dropdown-item" href="##"> Dropdown item 4 </a></li>
		  <li><a class="dropdown-item" href="##"> Dropdown item 5 </a></li>
	    </ul>
	</li>
</ul>

<ul class="navbar-nav ml-auto">
	<li class="nav-item"><a class="nav-link" href="##"> Menu item </a></li>
	<li class="nav-item"><a class="nav-link" href="##"> Menu item </a></li>
	<li class="nav-item dropdown">
		<a class="nav-link  dropdown-toggle" href="##" data-toggle="dropdown"> Dropdown right </a>
	    <ul class="dropdown-menu dropdown-menu-right">
		  <li><a class="dropdown-item" href="##"> Dropdown item 1</a></li>
		  <li><a class="dropdown-item" href="##"> Dropdown item 2 </a></li>
		  <li><a class="dropdown-item dropdown-toggle" href="##"> Dropdown item 3 </a>
		  	 <ul class="submenu submenu-left dropdown-menu">
			    <li><a class="dropdown-item" href="">Submenu item 1</a></li>
			    <li><a class="dropdown-item" href="">Submenu item 2</a></li>
			    <li><a class="dropdown-item" href="">Submenu item 3</a></li>
			    <li><a class="dropdown-item" href="">Submenu item 4</a></li>
			 </ul>
		  </li>
		  <li><a class="dropdown-item" href="##"> Dropdown item 4 </a></li>
	    </ul>
	</li>

</ul>

  </div> <!-- navbar-collapse.// -->

</nav>

<section class="section-content py-5">

		<h6>Demo view: Bootstrap multilevel dropdown menu </h6>
        <p>For this demo page you should connect to the internet to receive files from CDN  like Bootstrap CSS, Bootstrap JS and jQuery. </p>
		<p> Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
		tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
		quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
		consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
		cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
		proident, sunt in culpa qui officia deserunt mollit anim id est laborum. </p>

		<p> Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
		tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
		quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
		consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
		cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
		proident, sunt in culpa qui officia deserunt mollit anim id est laborum. </p>

		<a href="http://bootstrap-menu.com/multilevel.html" class="btn btn-warning">Back to tutorial or Download code</a>

</section>

</div><!-- container //  -->
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
	
