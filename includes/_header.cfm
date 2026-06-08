<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<cfset headerPath = "includes"><!--- Identify which header has been included --->
<head>

<!--= Global site tag (gtag.js) - Google Analytics --->
<script async src="https://www.googletagmanager.com/gtag/js?id=<cfoutput>#Application.Google_uacct#</cfoutput>"></script><!--- " --->
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', '<cfoutput>#Application.Google_uacct#</cfoutput>');
</script>

<style>
	table td {border:none;}
</style>
<cfif isdefined("usealternatehead") and #usealternatehead# eq "feedreader">
	<cfinclude template="/includes/feedReaderInclude.cfm">
<cfelseif isdefined("usealternatehead") and #usealternatehead# eq "DataEntry">
	<cfinclude template="/includes/DataEntryInclude.cfm">
	<cfoutput>
		<META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
	</cfoutput>
<cfelse>
	<!--- Default elements to be included at the top of the html head --->
	<cfinclude template="/includes/alwaysInclude.cfm">
</cfif>
<cfif not isdefined("session.header_color")>
	<cfset setDbUser()>
</cfif>

<script language="javascript" type="text/javascript">
	jQuery(document).ready(function(){
		jQuery("ul.sf-menu").supersubs({
			minWidth:    'auto',
			maxWidth:    60,
			extraWidth:  1
		}).superfish({
			delay:       600,
			animation:   {opacity:'show',height:'show'},
			speed:       0
		});
		if (top.location!=document.location) {
			// the page is being included in a frame or a dialog within a page which already contains the header, main menu, and footer
			// so hide these elements.
			$("#footerContentBox").hide();
			$("#headerContent").hide();
			$(".sf-mainMenuWrapper").hide();
		}
	});
</script>
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
<cfif NOT isDefined("session.header_color") or len(session.header_color) EQ 0>
	<!--- fallback to use application values, this should not be needed as setDbUser should have run from initSession --->
	<cfset session.old_header_color = Application.old_header_color>
	<cfset session.old_collectionlinkcolor = Application.old_collectionlinkcolor>
	<cfset session.institutionlinkcolor = Application.institutionlinkcolor>
	<cfset session.institution_url = Application.institution_url>
	<cfset session.old_header_image = Application.old_header_image>
	<cfset session.old_collection_link_text = Application.old_collection_link_text>
	<cfset session.old_institution_link_text = Application.old_institution_link_text>
	<cfset session.header_image_alt = Application.header_image_alt>
</cfif>
<cfoutput>
		<meta name="keywords" content="#session.meta_keywords#">
		<LINK REL="SHORTCUT ICON" HREF="/images/favicon.ico">
		<meta http-equiv="content-type" content="text/html; charset=utf-8">
	</head>
	<body>
	<noscript>
		<div class="browserCheck">
			JavaScript is turned off in your web browser. Please turn it on to take full advantage of MCZbase, or
			try our <a target="_top" href="/SpecimensHTML.cfm">HTML SpecimenSearch</a> option.
		</div>
	</noscript>

	<!---  WARNING: Styles set on these elements must not set the color, this is set in a server specific variable from Application.cfc or user specific in setDbUser--->
	<div id="headerContent" style="background-color: #Session.old_header_color#;">
		<div id="image_headerWrap">
			<div class="headerText">
				<a href="#Session.institution_url#" target="_blank">
					<img src="#Session.old_header_image#" alt="#Session.header_image_alt#">
				</a>
				<!---  WARNING: Styles set on these elements must not set the color, this is set in a server specific variable from Application.cfc or user specific in setDbUser --->
				<h1 style="color:#Session.old_collectionlinkcolor#;">#Session.old_collection_link_text#</h1>
				<h2 style="color:#Session.old_institutionlinkcolor#;"><a href="#Session.institution_url#" target="_blank"><span style="color:#Session.old_institutionlinkcolor#" class="headerInstitutionText">#Session.old_institution_link_text#</span></a></h2>
			</div><!---end headerText--->
		</div><!---end image_headerWrap--->
	</div><!--- end headerContent div --->
	<h1 class="h2 text-center text-danger mt-5 mt-md-3">MCZbase requires Javascript to function.</h1>
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					<a href="/login.cfm?action=signOut" class="btn btn-outline-success py-0 px-2" aria-label="log out username (Last login: date)">Log out #session.username#
					<cfif isdefined("session.last_login") and len(#session.last_login#)gt 0>
						<small>(Last login: #dateformat(session.last_login, "dd-mmm-yyyy, hh:mm")#)</small>
					</cfif>
					</a>
					<cfelse>
					<form name="logIn" method="post" action="/login.cfm" class="m-0 form-login float-right">
						<input type="hidden" name="action" value="signIn">
						<div class="login-form" id="header_login_form_div">
							<label for="username" class="sr-only"> Username:</label>
							<input type="text" name="username" id="username" placeholder="username" autocomplete="username" class="loginButtons" style="width:100px;">
							<label for="password" class="mr-1 sr-only"> Password:</label>
							<input type="password" id="password" name="password" autocomplete="off" placeholder="password" title="Password" class="loginButtons" style="width: 80px;">
							<input type="submit" value="Log In" id="login" class="btn-primary loginButtons" aria-label="click to login">
						</div>
					</form>
				</cfif>
				<nav class="navbar navbar-expand-sm navbar-light bg-light p-0">
					
					<ul class="navbar-nav mx-auto">
						<li class="nav-item"> <a class="nav-link mr-2" href="/SpecimensHTML.cfm">Minimal Specimen Search</a></li>
						<li class="nav-item"><a class="nav-link mr-2" href="/specimens/browseSpecimens.cfm?target=noscript">Browse Data</a></li>
						<li class="nav-item"><a class="nav-link mr-2" href="https://mcz.harvard.edu/database">About MCZbase</a></li>
						<li class="nav-item"><a class="nav-link mr-2" href="/info/HowToCite.cfm">Citing MCZbase</a></li>
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
		<cfif findNoCase('style_work',Session.gitBranch) GT 0>
			<!--- checkout is redesign, redesign2, or similar --->
			<cfset targetMenu = "style_work">
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
	
		<nav class="navbar navbar-light bg-transparent navbar-expand-lg py-0" id="main_nav">
			<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="##navbar_toplevel_div" aria-controls="navbar_toplevel_div" aria-expanded="false" aria-label="Toggle navigation"> <span class="navbar-toggler-icon"></span> </button>
			<div class="collapse navbar-collapse" id="navbar_toplevel_div">
				<ul class="navbar-nav nav-fill mr-auto">
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"public")>
					<li class="nav-item dropdown"> 
						<a class="nav-link dropdown-toggle px-3 text-left" href="##" id="searchDropdown1" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" aria-label="Search shorcut=alt+m" title="Search (Alt+m)" >Search</a>
						<ul class="dropdown-menu border-0 shadow" aria-labelledby="searchDropdown1">
							<li> 	
								<a class="dropdown-item " href="/Specimens.cfm">Specimens</a>
								<a class="dropdown-item" id="specimenMenuItem" href="/SpecimenSearch.cfm">Specimens (old)</a>
								<a class="dropdown-item" href="/Taxa.cfm">Taxonomy</a>
								<a class="dropdown-item" href="/media/findMedia.cfm">Media</a>
								<a class="dropdown-item" href="/MediaSearch.cfm">Media (old)</a><!--- old --->
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href="/showLocality.cfm">Places</a>
								<cfelse>
									<a class="dropdown-item bg-warning" href="">Places</a>
								</cfif>	
								<a class="dropdown-item" target="_top" href="/Agents.cfm">Agents</a>
								<a class="dropdown-item" href="/Publications.cfm">Publications</a>
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href="/SpecimenUsage.cfm">Projects</a><!--- old --->
								<cfelse>
									<a class="dropdown-item bg-warning" href="">Projects</a>
								</cfif>	
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
									<a class="dropdown-item" href="/annotations/Annotations.cfm">Annotations</a>
									<a class="dropdown-item" href="/tools/userSQL.cfm">SQL Queries</a> 
								</cfif>
							 </li>
						</ul>
					</li>
					</cfif>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"public")>
						<li class="nav-item dropdown"> 
							<a class="nav-link dropdown-toggle px-3 text-left" href="##" id="searchDropdown2" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" aria-label="Search shorcut=alt+m" title="Search (Alt+m)" >Browse</a>
							<ul class="dropdown-menu border-0 shadow" aria-labelledby="searchDropdown2" style="min-width: 14em; border-radius: .2rem;">
								<li> 	
									<a class="dropdown-item" href="/specimens/browseSpecimens.cfm">Browse Specimens</a>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"public")>
										<a class="dropdown-item" href="/grouping/index.cfm">Featured Collections</a>
									</cfif>
									<a class="dropdown-item" href="/collections/index.cfm">Holdings</a>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/ContainerBrowse.cfm">Browse Storage Locations</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="/ContainerBrowse.cfm">Browse Storage Locations</a>
										</cfif>
									</cfif>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
										<a class="dropdown-item" href="/Bulkloader/browseBulk.cfm">Browse and Edit Bulkloader</a>
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
											<a class="dropdown-item" href="/publications/Publication.cfm?action=new">Publication</a>
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Project.cfm?action=makeNew">Projects</a><!--- old --->
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Projects</a> 
											</cfif>
										</cfif>
									</div>
									<div>
										<div class="h5 dropdown-header px-4 text-danger">Bulkload</div>
										<a class="dropdown-item" href="/bulkloading/Bulkloaders.cfm">All Bulkloaders</a>
										<a class="dropdown-item" href="/Bulkloader/bulkloaderBuilder.cfm">Specimen Bulkload Builder</a>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/Bulkloader/BulkloadSpecimens.cfm">Bulkload Specimens</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="/Bulkloader/BulkloadSpecimens.cfm">Bulkload Specimens</a>
										</cfif>
										<a class="dropdown-item" href="/Bulkloader/browseBulk.cfm">Browse and Edit Specimen Bulkloads</a>
										<a class="dropdown-item" href="/Bulkloader/bulkloader_status.cfm">Specimen Bulkloader Status</a>
										<a class="dropdown-item" href="/tools/PublicationStatus.cfm">Publication Staging</a>
										<a class="dropdown-item" href="/tools/DataLoanBulkload.cfm">Data Loan Items</a>
										<a class="dropdown-item" href="/dataquality/check_names.cfm">Check CSV of Taxon Names</a>
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
									<div>
									<div class="h5 dropdown-header px-4 text-danger">Search &amp; Edit</div>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
											<a class="dropdown-item" href="/localities/HigherGeographies.cfm">Geography</a> 
											<a class="dropdown-item" href="/localities/Localities.cfm">Localities</a> 
											<a class="dropdown-item" href="/localities/CollectingEvents.cfm">Collecting Events</a> 
										</cfif>
									
										<a class="dropdown-item" href="/vocabularies/CollEventNumberSeries.cfm">Collecting Event Number Series</a> 
										
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_agents")>
											<a class="dropdown-item" href="/Agents.cfm">Agents</a> 
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_publications")>
											<a class="dropdown-item" href="/Publications.cfm">Publications</a>
											<a class="dropdown-item" href="/publications/Journals.cfm">Serial/Journal Titles</a> 
										</cfif>
									</div>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
										<div>
									
											<div class="h5 dropdown-header px-4 text-danger">Create</div>
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_geography")>
												<a class="dropdown-item" href="/localities/HigherGeography.cfm?action=new">Geography</a> 
											</cfif>		
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
												<a class="dropdown-item" href="/localities/Locality.cfm?action=new">Locality</a> 
												<a class="dropdown-item" href="/localities/CollectingEvent.cfm?action=new">Collecting Events</a> 
											</cfif>
									
											<a class="dropdown-item" href="/vocabularies/CollEventNumberSeries.cfm?action=new">Collecting Event Number Series</a> 
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_agents")>
												<a class="dropdown-item" href="/agents/editAgent.cfm?action=new&agent_type=person">Person</a> 
												<a class="dropdown-item" href="/agents/editAgent.cfm?action=new&agent_type=organization">Organization Agent</a> 
											</cfif>
	
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_publications")>
												<a class="dropdown-item" href="/publications/Publication.cfm?action=new">Publication</a> 
											</cfif>
	
										</div>
									</cfif>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens") AND isdefined("session.roles") and listcontainsnocase(session.roles,"manage_collection")>
										<div>
											<div class="h5 dropdown-header px-4 text-danger">Manage</div>
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_collection")>
												<cfif targetMenu EQ "production">
													<a class="dropdown-item" href="/Encumbrances.cfm">Encumbrances</a>
												<cfelse>
													<a class="dropdown-item bg-warning" href="">Encumbrances</a>
												</cfif>
												<a class="dropdown-item" href="/annotations/Annotations.cfm">Annotations</a>
											</cfif>
											<cfif isdefined("session.roles") and ( listcontainsnocase(session.roles,"manage_agents") or listcontainsnocase(session.roles,"MANAGE_AGENT_RANKING") or listcontainsnocase(session.roles,"ADMIN_AGENT_RANKING ") OR listcontainsnocase(session.roles,"merge_agents") )>
												<a class="dropdown-item" href="/Admin/agentMergeReview.cfm">Review Pending Merges</a>
												<a class="dropdown-item" href="/Admin/killBadAgentDups.cfm">Merge bad duplicate agents</a>
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
											<a class="dropdown-item" href="/CreateContainersForBarcodes.cfm">Create Container Series</a>
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
												<a class="dropdown-item stillNeedToDo" href="">Label > Container</a> 
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
										<a class="dropdown-item" href="/transactions/ShipmentReport.cfm">Shipment Report</a> 
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
										<div class="h5 dropdown-header px-4 text-danger">Reports &amp; Statistics</div>
										<a class="dropdown-item" href="/reporting/Reports.cfm">List of Reports</a>
										<a class="dropdown-item" href="/info/queryStats.cfm">Query Statistics</a>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
											<a class="dropdown-item" href="/metrics/Dashboard.cfm">Reporting Metrics</a>
											<a class="dropdown-item" href="/metrics/AgentRoles.cfm">Visualize Data</a>
										</cfif>
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
											<a class="dropdown-item" href="/vocabularies/GeologicalHierarchies.cfm">Geology Attributes Hierarchies</a>
											<!--- TODO: Need another role for report management  --->
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Reports/reporter.cfm">Label/Report Management</a>
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
											<a class="dropdown-item" href="/specimens/adminSpecimenSearch.cfm?action=search">Manage Specimen Search Fields</a>
											<a class="dropdown-item" href="/specimens/adminSpecimenSearch.cfm?action=results">Manage Specimen Results Columns</a>
											<a class="dropdown-item" href="/Admin/dumpAll.cfm">Dump Coldfusion Vars</a>
											<a class="dropdown-item"  href="/ScheduledTasks/index.cfm">Scheduled Tasks</a>
											<a class="dropdown-item"  href="/tools/listImages.cfm">Image List</a>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"collops")>
											<a class="dropdown-item" href="/media/debugMediaGallery.cfm">Test/Debug Media Widget</a>
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
										<a class="dropdown-item" href="/Admin/AdminUsers.cfm">MCZbase User Access</a>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/tools/access_report.cfm?action=role">User Role Report</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="">User Role Report</a>
										</cfif>
										<a class="dropdown-item" href="/Admin/user_roles.cfm">Database Role Definitions</a>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
											<!---
											<cfif targetMenu EQ "production">
												<a class="dropdown-item" href="/Admin/form_roles.cfm">Form Permissions</a>
											<cfelse>
												<a class="dropdown-item bg-warning" href="">Form Permissions</a>
											</cfif>
											--->
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
											<a class="dropdown-item" href="/Admin/Collection.cfm">Manage Collections</a>
											<a class="dropdown-item" href="/Admin/manageRedirects.cfm">Redirects</a>
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
							<a class="dropdown-item" href="/info/HowToCite.cfm">Citing MCZbase</a>
							<a class="dropdown-item" href="/vocabularies/ControlledVocabulary.cfm">Controlled Vocabularies</a>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
								<a class="dropdown-item" href="/specimens/viewSpecimenSearchMetadata.cfm?action=search&execute=true&method=getcf_spec_search_cols&access_role=!HIDE">Specimen Search Builder Help</a>
							<cfelse>
								<a class="dropdown-item" href="/specimens/viewSpecimenSearchMetadata.cfm?action=search&execute=true&method=getcf_spec_search_cols&access_role=PUBLIC">Specimen Search Builder Help</a>
							</cfif>
							<a class="dropdown-item" href="/collections/index.cfm">Holdings</a>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
								<a class="dropdown-item" href="/Reports/listReports.cfm">List of Label Reports</a>
							</cfif>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
								<a class="dropdown-item" href="https://github.com/MCZbase/MCZbase/blob/master/documentation/README.md">Developer&##39;guide</a>
							</cfif>
							<a class="dropdown-item" href="/info/api.cfm">API</a>
							<cfif targetMenu NEQ "production">
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
							<ul aria-labelledby="dropdownMenu5" class="dropdown-menu dropdown-menu-right border-0 shadow">
								<li>
									<a href="/users/UserProfile.cfm" class="dropdown-item">User Profile</a>
									<cfif session.roles contains "coldfusion_user">
										<a href="/users/Searches.cfm" class="dropdown-item">Saved Searches</a>
										<a href="/users/manageDownloadProfiles.cfm" class="dropdown-item">Manage CSV Download Columm Profiles</a>
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
				<!--- user is not logged in, if they do login, determine where to send them from the login page --->
				<cfif isdefined("gotopage") and len(trim(gotopage)) GT 0>
					<cfset gtp = trim(gotopage)>
				<cfelseif cgi.script_name EQ "/guid/handler.cfm" AND isDefined("url.catalog") AND len(trim(url.catalog)) GT 0 AND REFind("^[A-Z]+:[A-Za-z]+:[A-Za-z0-9-]+$", trim(url.catalog)) GT 0>
					<!--- initial request was for /guid/{guid} but user is not logged in, so send to login page and then back to the guid page after successful login --->
					<cfset gtp = "/guid/#trim(url.catalog)#">
				<cfelseif isDefined("cgi.REDIRECT_URL") AND len(trim(cgi.REDIRECT_URL)) GT 0 AND left(trim(cgi.REDIRECT_URL), 1) EQ "/" AND left(trim(cgi.REDIRECT_URL), 2) NEQ "//">
					<cfset gtp = trim(cgi.REDIRECT_URL)>
				<cfelseif isDefined("requestData.headers.referer") AND len(trim(requestData.headers.referer)) GT 0 AND left(trim(requestData.headers.referer), len(application.serverRootUrl)) EQ application.serverRootUrl>
					<cfset gtp = replace(trim(requestData.headers.referer), application.serverRootUrl, "")>
				<cfelse>
					<cfset gtp = replace(cgi.SCRIPT_NAME, "//", "/", "all")>
					<!--- if cgi.query_string is non empty, then append it so search pages can restore state after login --->
					<cfif isDefined("cgi.query_string") AND len(trim(cgi.query_string)) GT 0>
						<cfset cleanedQueryString = trim(cgi.query_string)>
						<cfset cleanedQueryString = REReplaceNoCase(cleanedQueryString, "(^|&)(CFID|CFTOKEN)=[^&]*", "", "all")>
						<cfset cleanedQueryString = REReplace(cleanedQueryString, "^&+|&+$", "", "all")>
						<cfset cleanedQueryString = REReplace(cleanedQueryString, "&{2,}", "&", "all")>
						<cfif len(cleanedQueryString) GT 0>
							<cfset gtp = "#gtp#?#cleanedQueryString#">
						</cfif>
					</cfif>
				</cfif>
				<cfif gtp EQ "/errors/forbidden.cfm">
					<cfset gtp = "/users/UserProfile.cfm">
				</cfif>
				<form name="logIn" method="post" action="/login.cfm" class="m-0 form-login">
					<input type="hidden" name="action" value="signIn">
					<input type="hidden" name="mode" value="">
					<input type="hidden" name="gotopage" value="#gtp#">
					<div class="login-form" id="header_login_form_div">
						<label for="username" class="sr-only"> Username:</label>
						<input type="text" name="username" id="username" placeholder="username" class="loginfields d-inline loginButtons loginfld1">
						<label for="password" class="mr-1 sr-only"> Password:</label>
						<input type="password" id="password" name="password" autocomplete="off" placeholder="password" title="Password" class="loginButtons loginfields d-inline loginfld2">
						<label for="login" class="mr-1 sr-only"> Password:</label>
						<input type="submit" value="Log In" id="login" class="btn-primary loginButtons"  onClick="logIn.action.value='signIn';submit();" aria-label="click to login">
						<label for="create_account" class="mr-1 sr-only"> Password:</label>
						<input type="submit" value="Register" class="btn-primary loginButtons" id="create_account" onClick="logIn.action.value='loginForm';logIn.mode.value='register';submit();" aria-label="click to create new account">
					</div>
				</form>
			</cfif>
		</nav>
	</div>
	<!-- container //  --> 
	<script>
		document.getElementById("mainMenuContainer").style.display = "block";	
	</script> 
	<cf_rolecheck>

</cfoutput>
<div id="pg_container">
<div class="content_box">
