<cf_rolecheck>
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
<link rel="SHORTCUT ICON" href="/includes/images/favicon.ico">
<cfif not isdefined("pageTitle")>
   <!--- Long term we can set a default value, short term throw an exception to make developers add pageTitle to invoking pages. --->
   <cfthrow message="Error: includes/_header.cfm was included from a page that does not set the required pageTitle.">
</cfif>
<title>#pageTitle#</title>
<cfinclude template="/includes/functionLib.cfm">
<link rel="stylesheet" href="/lib/bootstrap/css/bootstrap.min.css"><!---needed for overall look--->
<link rel="stylesheet" href="/lib/bootstrap/css/bootstrap-multiselect.css"><!---don't know--->
<link rel="stylesheet" href="/lib/fontawesome/fontawesome-free-5.5.0-web/css/all.css"><!--account, magnifier, and cog icons-->
<link rel="stylesheet" href="/lib/JQWidgets/jqwidgets/styles/jqx.base.css"><!---don't know--->
<link rel="stylesheet" href="/lib/JQWidgets/jqwidgets/styles/jqx.classic.css"><!---don't know--->
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.css"><!---don't know--->
<script type="text/javascript" src="/lib/fontawesome/fontawesome-free-5.5.0-web/js/all.js"></script><!--account and cog icons-->

<script type="text/javascript" src="/lib/jquery/jquery-1.7.1.min.js"></script><!---don't know--->
<script type="text/javascript" src="/includes/js/popper.js"></script>
<!---	<link rel="stylesheet" href="/lib/JQWidgets/jqwidgets/styles/jqx.light.css" />--->
<script type="text/javascript" src="/lib/jquery/jquery-3.3.1.js"></script><!---don't know --->
<script type="text/javascript" src="/lib/jquery-ui-1.12.1/jquery-ui.js"></script><!---not there now--->
<script type="text/javascript" src="/lib/bootstrap/js/bootstrap-multiselect.js"></script>
<script type="text/javascript" src="/lib/bootstrap/js/bootstrap.min.js"></script>
<link rel="stylesheet" href="/lib/bootstrap/css/bootstrap-select.min.css"><!---don't know but tabs work--->
<script type="text/javascript" src="/lib/bootstrap/js/bootstrap-select.min.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxcore.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdata.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdata.export.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxbuttons.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxscrollbar.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxlistbox.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdropdownlist.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxmenu.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxwindow.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdatetimeinput.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdate.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxslider.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.filter.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.edit.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.sort.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.selection.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.export.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.storage.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxpanel.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxcheckbox.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.pager.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.grouping.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.aggregates.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxinput.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdragdrop.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/globalization/globalize.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.columnsresize.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxgrid.columnsreorder.js"></script> 
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxcalendar.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdate.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxtree.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxdatetimeinput.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxinput.js"></script>
<script type="text/javascript" src="/includes/js/knockout-2.2.1.js"></script>
<script type="text/javascript" src="/lib/misc/knockout-2.2.1.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets/jqxknockout.js"></script>
<script type="text/javascript" src="/lib/JQWidgets/scripts/demos.js"></script>
<script type="text/javascript" src="/includes/js/shared-scripts.js"></script>
<script type="text/javascript" src="/lib/jquery/jquery.multiselect.min.js"></script>
<script type="text/javascript" src="/specimens/js/dialogAjax.js"></script>
	
<link rel="stylesheet" href="/lib/jquery-ui-1.12.1/jquery-ui.min.css" />
<link rel="stylesheet" href="/lib/jquery/jquery.multiselect.css" />	
<link rel="stylesheet" href="/includes/css/custom_styles.css">
  <cfif not isdefined("session.header_color")>
      <cfset setDbUser()>
    </cfif>
</head>

<body class="default cbp-spmenu-push cbp-spmenu-pushtoleft">

<header id="header">

<cfoutput>
<div class="branding-container clearfix" style="background-color: #Application.header_color#;">
	<div class="branding-left justify-content-start">
		<a href="http://www.harvard.edu/" > 
			<img src="https://mcz.harvard.edu/profiles/openscholar/themes/hwpi_basetheme/images/harvard-logo.png" width="235" height="32" alt="University Logo" />
		</a> 
	</div>
	<div class="branding-right justify-content-end"> 
		<a href="http://www.harvard.edu/">HARVARD.EDU</a> 
	</div>
</div>
<nav class="navbar justify-content-start navbar-expand-md navbar-expand-sm navbar-harvard pt-2 pb-1 harvard_banner">
	<ul class="navbar col-lg-9 col-md-8 col-sm-9 pt-0 pb-0 mb-1">
		<li class="nav-item mcz2"><a href="https://www.mcz.harvard.edu/" target="_blank">Museum of Comparative Zoology</a></li>
		<li class="nav-item mczbase"><a href="/Specimens.cfm" target="_blank">#session.collection_link_text# </a></li>
	</ul>
	<ul class="navbar col-lg-3 col-md-8 col-sm-3 pt-0 pb-0 mb-1 d-flex justify-content-end">
		<div class="mcz_logo">
			<li class="nav-item d-flex align-content-end"> <a href="https://mcz.harvard.edu"><img class="mcz_logo_krono" src="#Application.header_image#" width="160"></a> </li>
		</div>
	</ul>
</nav>
</cfoutput>
<nav class="navbar navbar-expand-md navbar-light bg-light py-1 border-bottom">
	<div class="container p-5px">
		<button class="navbar-toggler" style="z-index:4000;" type="button" data-toggle="collapse" data-target="##navbarTogglerDemo01" aria-controls="navbarTogglerDemo01" aria-expanded="false" aria-label="Toggle navigation"> <span class="navbar-toggler-icon"></span> </button>
		<div class="col-md-10 col-lg-12 offset-lg-1 offset-md-0 collapse navbar-collapse" id="navbarTogglerDemo01">
			 <cfif len(session.roles) gt 0 and session.roles is not "public">
				 <ul class="navbar-nav nav-fill w-100">
					 <cfelse>
						 
			<ul class="navbar-nav nav-fill w-50">
				</cfif>
				<li class="nav-item dropdown active"> <a class="nav-link dropdown-toggle" href="/Specimens.cfm" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Specimen Data</a>
					<ul class="dropdown-menu" aria-labelledby="navbarDropdown">
						<li></li>
						<li><a class="dropdown-item" href="/Specimens.cfm">Specimens</a></li>
						<li><a class="dropdown-item" href="/Media.cfm">Media</a></li>
						<li><a class="dropdown-item" href="/Locality.cfm">Places</a></li>
						<li><a class="dropdown-item" href="/Publication.cfm">Publications</a></li>
						<li><a class="dropdown-item" href="/Agent.cfm">Agents</a></li>
						<li><a class="dropdown-item" href="/Taxonomy.cfm">Taxonomy</a></li>
					</ul>
				</li>
			  <cfif len(session.roles) gt 0 and session.roles is not "public">
              <cfset r = replace(session.roles,",","','","all")>
              <cfset r = "'#r#'">
              <cfquery name="roles" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,60,0)#">
							select form_path from cf_form_permissions
							where upper(role_name) IN (#ucase(preservesinglequotes(r))#)
							minus select form_path from cf_form_permissions
							where upper(role_name)  not in (#ucase(preservesinglequotes(r))#)
						</cfquery>
              <cfset formList = valuelist(roles.form_path)>
				<li class="nav-item dropdown"> 
					<a class="nav-link dropdown-toggle" href="##" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> Data Entry </a>
					<ul class="dropdown-menu" aria-labelledby="navbarDropdown">
						<li></li>
						<li><a class="dropdown-item" href="/DataEntry.cfm">Enter Single Records</a></li>
						<li><a class="dropdown-item" href="/Bulkloader.cfm">Bulkload Records</a> </li>
						<li><a class="dropdown-item" href="/BulkloadSpecimen.cfm">Bulkload Builder</a></li>
						<li><a class="dropdown-item" href="/Browse.cfm">Browse and Edit</a> </li>
						<li><a class="dropdown-item" href="/BulkloaderStatus.cfm">Bulkloader Status</a> </li>
						<li><a class="dropdown-item" href="##">Batch Tools</a></li>
					</ul>
				</li>
				<li class="nav-item dropdown"> 
					<a class="nav-link dropdown-toggle" href="##" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Manage </a>
					<ul class="dropdown-menu" aria-labelledby="navbarDropdown">
						<li></li>
						<li><a class="dropdown-item" href="##">Projects</a></li>
						<li class="dropdown-submenu wd-130"><a class="wd-130 dropdown-item dropdown-toggle" href="##">Reports</a>
							<ul class="dropdown-menu">
								<li></li>
								<li><a class="dropdown-item" href="##">Statistics</a></li>
								<li><a class="dropdown-item" href="##">Annual Reports</a></li>
								<li class="dropdown-submenu wd-130"><a class="wd-130 dropdown-item dropdown-toggle" href="##">Shared Data</a>
									<ul class="dropdown-menu">
										<li></li>
										<li><a class="dropdown-item" href="##">Recently Georeferenced Localities</a></li>
										<li><a class="dropdown-item" href="##">Taxonomy Review</a></li>
									</ul>
								</li>
							</ul>
						</li>
						<li><a class="dropdown-item" href="##">Object Tracking</a></li>
						<li><a class="dropdown-item" href="##">Encumbrances</a></li>
						<li><a class="dropdown-item" href="##">Record Review</a></li>
					</ul>
				</li>
				<li class="nav-item dropdown"> 
					<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> Transactions </a>
					<ul class="dropdown-menu" aria-labelledby="navbarDropdown">
						<li></li>
						<li><a class="dropdown-item" href="/Accession.cfm">Accessions</a> </li>
						<li><a class="dropdown-item" href="/Deaccession.cfm">Deaccessions</a> </li>
						<li><a class="dropdown-item" href="/Borrow.cfm">Borrows</a> </li>
						<li><a class="dropdown-item" href="/Loan.cfm">Loans</a> </li>
						<li><a class="dropdown-item" href="/Permit.cfm;">Permits</a> </li>
					</ul>
				</li>
				  </cfif>
				<li class="nav-item dropdown">
				 		<a class="nav-link dropdown-toggle" href="##" id="navbarDropdownMenuLink" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> Help </a>
					<ul class="dropdown-menu" aria-labelledby="navbarDropdown">
						<li></li>
						<li><a class="dropdown-item" href="https://code.mcz.harvard.edu/wiki/index.php/Main_Page">MCZbase Wiki</a></li>
						<li><a class="dropdown-item" href="/About.cfm">About MCZbase</a> </li>
				
					</ul> 
				 </li>
			</ul>
		</div>
	</div>
	<ul id="profiles" class="nav justify-content-end col-sm-2 accn-icons pt-1">
		<li class="nav-item dropdown">
			<a href="##accountSettings" data-toggle="dropdown" role="button"> 
				<i class="fas fa-cog text-black-50"></i> 
			</a> 
		</li>
		<li class="nav-item dropdown"> 
			<a href="##formLogin" data-toggle="dropdown" role="button"> 
				<cfif session.roles contains "coldfusion_user">
				<i class="fas fa-user-check" style="color: #39A845;"></i> 
					
				<cfelse>
				
				<i class="fas fa-user"></i> 
			
				</cfif>
					
			</a> 
		</li>
	</ul>
</nav>
<div class="dropdown-menu" id="accountSettings">
	<div class="row">
		<div class="container-fluid">
			
				<div class="form-group"> 
				<!---	<a href="##">Profile Settings</a> --->
					<a href="/searchBuilder.cfm">Custom Fixed Search Builder</a> 
					<a href="/saveSearch.cfm?action=manage">Saved Searches</a> 
					<a href="##">Manage Collection Contact and Link info.</a> 
				</div>
		
		</div>
	</div>
</div>
			
<div class="dropdown-menu" id="formLogin">
	<div class="row">
		<div class="container-fluid">
			<div class="form-group"> 
				<cfif not isdefined("session.header_color")>
					<cfset setDbUser()>
				</cfif>
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
		
		<a class="alert-link alert-success" style="background-color: ##C3E6CB; color: ##155724;" target="_top" href="/login.cfm?action=signOut">Log out #session.username#
		<cfif isdefined("session.last_login") and len(#session.last_login#) gt 0>	<span>(Last login: #dateformat(session.last_login, "dd-mmm-yyyy hh:mm")#)&nbsp;</span></cfif>
		</a>

	<cfelse>
		<cfif isdefined("session.needEmailAddr") and session.needEmailAddr is 1>
		 <br>
			<span style="font-size: 12px;"> You have no email address in your profile. Please correct. </span>
		</cfif>
		<cfif isdefined("session.username") and isdefined("cgi.REDIRECT_URL") and len(cgi.REDIRECT_URL) gt 0>
		<cfset gtp=replace(cgi.REDIRECT_URL, "//", "/")>
		<cfelse>
		<cfset gtp=replace(cgi.SCRIPT_NAME, "//", "/")>
		</cfif>
			<form name="logIn" method="post" action="/login.cfm">
				  <input type="hidden" name="action" value="signIn">
				  <input type="hidden" name="gotopage" value="#gtp#">
			
				
				<div class="form-group ml-2">
					<label for="username" class="wd-90p">Username:</label>
					<input type="text" name="username" title="Username" size="14" class="loginTxt" onfocus="if(this.value==this.title){this.value=''};">
				</div>
				<div class="form-group ml-2">
					<label for="password" class="wd-90p">Password:</label>
					<input type="password" name="password" title="Password" size="14" class="loginTxt">
				</div>
				<div class="form-group ml-2">
				<input type="submit" value="Log In" class="btn btn-secondary btn-sm" onClick="logIn.action.value='signIn';submit();"><span class="d-inline-block px-2">or</span>
				<input type="submit" value="Create Account" class="btn btn-primary btn-sm" onClick="logIn.action.value='nothing';submit();">
				</div>
			</form>
	</cfif>
			
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
	<form name="userProfile" method="post" action="/UserProfile.cfm">
			<input type="hidden" name="action" value="nothing">
			<button value="User Profile" onclick="userProfile.action.value='nothing';submit();" class="btn btn-light btn-sm w-100">User Profile</button>
		</form>
		
		
			</cfif>
			</div>
		</div>
	</div>
</div>
</header>
<cf_rolecheck>
</cfoutput>
<cfset HEADER_DELIVERED=true>
