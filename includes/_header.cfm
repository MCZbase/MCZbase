<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<cfset headerPath = "includes"><!--- Identify which header has been included --->
<head>

<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=<cfoutput>#Application.Google_uacct#</cfoutput>"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', '<cfoutput>#Application.Google_uacct#</cfoutput>');
</script>

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

	<!---  WARNING: Styles set on these elements must not set the color, this is set in a server specific variable from Application.cfc --->
	<div id="headerContent" style="background-color: #Application.header_color#;">
		<div id="image_headerWrap">
			<div class="headerText">
				<a href="http://mcz.harvard.edu/" target="_blank">
					<img src="#Application.header_image#" alt="MCZ Kronosaurus Logo">
				</a>
				<!---  WARNING: Styles set on these elements must not set the color, this is set in a server specific variable from Application.cfc --->
				<h1 style="color:#Application.collectionlinkcolor#;"><span style='font-size: 1.2rem;'>#Application.collection_link_text#</h1>  <!--- close span is in collection_collection_link_text --->
				<h2 style="color:#Application.institutionlinkcolor#;"><a href="https://mcz.harvard.edu/" target="_blank"><span style="color:#Application.institutionlinkcolor#" class="headerInstitutionText">#session.institution_link_text#</span></a></h2>
			</div><!---end headerText--->
		</div><!---end image_headerWrap--->
	</div><!--- end headerContent div --->
	<div class="sf-mainMenuWrapper" style="font-size: 14px;background-color: ##ddd;">

		<ul class="sf-menu">
			<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"public")>
				<li class="nav-item dropdown">
					<!--- main menu element for search, mostly public --->
					<a href="##" class="nav-link dropdown-toggle text-left">Search</a>
					<ul class="dropdown-menu border-0 shadow" style="min-width: 12em; border-radius: .2rem;">
						<li class="d-md-flex align-items-start justify-content-start">
							<div>
								<a class="dropdown-item" target="_top" href="/Specimens.cfm">Specimens</a>
								<a class="dropdown-item" target="_top" href="/SpecimenSearch.cfm">Specimens (old)</a>
								<a class="dropdown-item" target="_top" href="/Taxa.cfm">Taxonomy</a>
								<a class="dropdown-item" target="_top" href="/media/findMedia.cfm">Media</a>
								<a class="dropdown-item" target="_top" href="/MediaSearch.cfm">Media (old)</a>
								<a class="dropdown-item" target="_top" href="/showLocality.cfm">Places</a>
								<a class="dropdown-item" target="_top" href="/Agents.cfm">Agents</a>
								<a class="dropdown-item" target="_top" href="/Publications.cfm">Publications</a>
								<a class="dropdown-item" target="_top" href="/SpecimenUsage.cfm">Projects</a>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
									<a class="dropdown-item" target="_top" href="/info/reviewAnnotation.cfm">Annotations</a>
									<a class="dropdown-item" target="_top" href="/tools/userSQL.cfm">SQL Queries</a>
								</cfif>
							</div>
						</li>
					</ul>
					<!--- end main menu element for search --->
	 			</li>
			</cfif>
			<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"public")>
				<li class="nav-item dropdown"> 
					<a class="nav-link dropdown-toggle px-3 text-left" href="##" id="searchDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" aria-label="Search shorcut=alt+m" title="Search (Alt+m)" >Browse</a>
					<ul class="dropdown-menu border-0 shadow" aria-labelledby="searchDropdown" style="min-width: 14em; border-radius: .2rem;">
						<li> 	
							<a class="dropdown-item" href="/specimens/browseSpecimens.cfm">Browse Specimens</a>
							<a class="dropdown-item" href="/grouping/index.cfm">Featured Collections</a>
							<a class="dropdown-item" href="/collections/index.cfm">Holdings</a>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href="/ContainerBrowse.cfm">Browse Storage Locations</a>
								<cfelse>
									<a class="dropdown-item bg-warning" href="/ContainerBrowse.cfm">Browse Storage Locations</a>
								</cfif>
							</cfif>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
								<cfif targetMenu EQ "production">
									<a class="dropdown-item" href="/Bulkloader/browseBulk.cfm">Browse and Edit Bulkloader</a>
								<cfelse>
									<a class="dropdown-item bg-warning" href="/Bulkloader/browseBulk.cfm">Browse and Edit Bulkloader</a>
								</cfif>
							</cfif>
						 </li>
					</ul>
				</li>
			</cfif>
			<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
				<!--- begin additional main menu items to be shown to authorized users --->
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
					<li class="nav-item dropdown">
						<!--- main menu item data entry --->
						<a href="##" class="nav-link dropdown-toggle text-left">Data Entry</a>
						<ul class="dropdown-menu border-0 shadow" style="min-width: 23em; border-radius: .2rem;">
							<li class="d-md-flex align-items-start justify-content-start">
							<div style="float:left; width: 49%;">
								<div class="h5 dropdown-header px-4 text-danger">Create New Record</div>
									<a class="dropdown-item" target="_top" href="/DataEntry.cfm">Specimen Record</a>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
										<a class="dropdown-item" target="_top" href="/media.cfm?action=newMedia">Media Record</a>
									</cfif>
									<cfif isdefined("session.roles") and ( listcontainsnocase(session.roles,"manage_agents") or listcontainsnocase(session.roles,"MANAGE_AGENT_RANKING") or listcontainsnocase(session.roles,"ADMIN_AGENT_RANKING "))>
										<a class="dropdown-item" target="_top" href="/agents/editAgent.cfm?action=new">Agent Record</a>
									</cfif>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_publications")>
										<a class="dropdown-item" target="_top" href="/publications/Publication.cfm?action=new">Publication Record</a> 
										<a class="dropdown-item" target="_top" href="/Project.cfm?action=makeNew">Project Record</a>
									</cfif>
								</div>
								<div style="float:left; width: 49%;">
									<div class="h5 dropdown-header px-4 text-danger">Bulkloading</div>
									<a class="dropdown-item" target="_top" href="/Bulkloader/bulkloaderBuilder.cfm">Bulkloader Builder</a>
									<a class="dropdown-item" href="/Bulkloader/browseBulk.cfm">Browse and Edit</a>
									<cfif targetMenu EQ "production">
										<a class="dropdown-item" href="/Bulkloader/BulkloadSpecimens.cfm">Bulkload Specimens</a>
									<cfelse>
										<a class="dropdown-item bg-warning" href="/Bulkloader/BulkloadSpecimens.cfm">Bulkload Specimens</a>
									</cfif>
									<a class="dropdown-item" target="_top" href="/Bulkloader/bulkloader_status.cfm">Bulkload Status</a>
									<a class="dropdown-item" target="_top" href="/bulkloading/Bulkloaders.cfm">Bulkloaders</a>
									<a class="dropdown-item" target="_top" href="/tools/PublicationStatus.cfm">Publication Staging</a>
									<a class="dropdown-item" target="_top" href="/tools/DataLoanBulkload.cfm">Data Loan Items</a>
								</div>
							</li>
						</ul>
						<!--- end main menu item data entry --->
					</li>
				</cfif>
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
					<li class="nav-item dropdown">
						<!--- main menu item manage data --->
						<a class="nav-link dropdown-toggle text-left" target="_top" href="##">Manage Data</a>
						<ul class="dropdown-menu border-0 shadow" style="min-width: 48em; border-radius: .2rem;">
							<li class="d-md-flex align-items-start justify-content-start">
								<div style="float:left; width: 33.2%;">
									<div class="h5 dropdown-header px-4 text-danger">Search &amp; Edit</div>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
										<a class="dropdown-item" target="_top" href="/localities/HigherGeographies.cfm">Geography</a> 
										<a class="dropdown-item" target="_top" href="/localities/Localities.cfm">Localities</a> 
										<a class="dropdown-item" target="_top" href="/localities/CollectingEvents.cfm">Collecting Events</a> 
									</cfif>
									<a class="dropdown-item" target="_top" href="/vocabularies/CollEventNumberSeries.cfm">Collecting Event Number Series</a>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_agents")>
										<a class="dropdown-item" target="_top" href="/Agents.cfm">Agents</a>
									</cfif>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_publications")>
										<a class="dropdown-item" href="/Publications.cfm">Publications</a>
										<a class="dropdown-item" href="/publications/Journals.cfm">Serial/Journal Titles</a> 
									</cfif>
								</div>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
									<div style="float:left; width: 33.2%;">
										<div class="h5 dropdown-header px-4 text-danger">Create</div>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_geography")>
											<a class="dropdown-item" target="_top" href="/localities/HigherGeography.cfm?action=new">Geography</a>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
											<a class="dropdown-item" target="_top" href="/localities/Locality.cfm?action=new">Locality</a>
										</cfif>
										<a class="dropdown-item" target="_top" href="/vocabularies/CollEventNumberSeries.cfm?action=new">Collecting Event Number Series</a>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_agents")>
											<a class="dropdown-item" target="_top" href="/agents/editAgent.cfm?action=new&agent_type=person">Person</a>
											<a class="dropdown-item" target="_top" href="/agents/editAgent.cfm?action=new&agent_type=organization">Organization Agent</a>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_publications")>
											<a class="dropdown-item" href="/publications/Publication.cfm?action=new">Publication</a> 
										</cfif>
									</div>
								</cfif>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens") and listcontainsnocase(session.roles,"manage_collection")>
									<div style="float:left; width: 33.2%;">
										<div class="h5 dropdown-header px-4 text-danger">Manage</div>
											<a class="dropdown-item" target="_top" href="/Encumbrances.cfm">Encumbrances</a>
											<a class="dropdown-item" href="/info/reviewAnnotation.cfm">Annotations</a>
											<a class="dropdown-item" target="_top" href="/Admin/Collection.cfm">Manage Collection</a>
											<cfif isdefined("session.roles") and ( listcontainsnocase(session.roles,"manage_agents") or listcontainsnocase(session.roles,"MANAGE_AGENT_RANKING") or listcontainsnocase(session.roles,"ADMIN_AGENT_RANKING"))>
												<a class="dropdown-item" target="_top" href="/Admin/agentMergeReview.cfm">Review Pending Agent Merges</a>
												<a class="dropdown-item" target="_top" href="/Admin/killBadAgentDups.cfm">Merge Bad Duplicate Agents</a>
											</cfif>
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_taxonomy")>
												<a class="dropdown-item" target="_top" href="/tools/parent_child_taxonomy.cfm">Sync Parent/Child Taxonomy</a>
												<a class="dropdown-item" target="_top" href="/tools/pendingRelations.cfm">Pending Relationships</a>
												<a class="dropdown-item" target="_top" href="/tools/sqlTaxonomy.cfm">SQL Taxonomy</a>
												<a class="dropdown-item" target="_top" href="/tools/BulkloadTaxonomy.cfm">Bulk Taxonomy</a>
											</cfif>
										</div>
								</cfif>
							</li>
						</ul>
						<!--- end main menu item manage data --->
					</li>
				</cfif>
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
					<li class="nav-item dropdown">
						<!--- main menu item curation --->
						<a class="nav-link dropdown-toggle text-left" target="_top" href="##">Curation</a>
						<ul class="dropdown-menu border-0 shadow" style="min-width: 45em; border-radius: .2rem;">
							<li class="d-md-flex align-items-start justify-content-start">
								<div style="float:left; width: 33.2%;">
									<div class="h5 dropdown-header px-4 text-danger">Search &amp; Edit</div>
									<a class="dropdown-item" href="/grouping/NamedCollection.cfm" target="_top">Named Group</a>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
										<cfif targetMenu EQ "production">
											<a class="dropdown-item" href="/ContainerBrowse.cfm">Browse Storage Locations</a>
										<cfelse>
											<a class="dropdown-item bg-warning" href="/ContainerBrowse.cfm">Browse Storage Locations</a>
										</cfif>
										<a class="dropdown-item" href="/findContainer.cfm" target="_top">Find Storage Location/Container</a>
									</cfif>
								</div>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"data_entry")>
									<div style="float:left; width: 33.2%;">
										<div class="h5 dropdown-header px-4 text-danger">Create</div>
										<a class="dropdown-item"  href="/grouping/NamedCollection.cfm?action=new" target="_top">Named Group</a>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
											<a class="dropdown-item"  href="/editContainer.cfm?action=newContainer" target="_top">Storage Location/Create Container</a>
											<a class="dropdown-item"  href="/CreateContainersForBarcodes.cfm" target="_top">Create Container Series</a>

										</cfif>
									</div>
								</cfif>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
									<div style="float:left; width: 33.2%;">
										<div class="h5 dropdown-header px-4 text-danger">Manage</div>
										<a class="dropdown-item"  href="/moveContainer.cfm" target="_top">Move Container</a>
										<a class="dropdown-item"  href="/batchScan.cfm" target="_top">Batch Scan</a>
										<a class="dropdown-item"  href="/labels2containers.cfm" target="_top">Label &gt; Container</a>
										<a class="dropdown-item"  href="/part2container.cfm" target="_top">Put Parts in Containers</a>
										<a class="dropdown-item"  href="/SpecimenContainerLabels.cfm" target="_top">Clear Flags</a>
										<a class="dropdown-item"  href="/LoadBarcodes.cfm" target="_top">Upload Scan File</a>
										<!---[Bug 5212] Moved to Bulkloaders.cfm link found under Data Entry menu--->
										<!---<a class="dropdown-item"  href="/tools/BulkloadContEditParent.cfm" target="_top">Bulk Edit Container</a>--->
									</div>
								</cfif>
							</li>
						</ul>
						<!--- end main menu item curation --->
					</li>
				</cfif>
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
					<li class="nav-item dropdown">
						<!--- main menu item transactions --->
						<a class="nav-link dropdown-toggle text-left" target="_top" href="##">Transactions</a>
						<ul class="dropdown-menu border-0 shadow" style="min-width:22em; border-radius: .2rem;">
							<li class="d-md-flex align-items-start justify-content-start">
								<div style="float:left; width: 49%;">
									<div class="h5 dropdown-header px-4 text-danger">Search &amp; Edit</div>
									<a class="dropdown-item" target="_top" href="/Transactions.cfm">All Transactions</a>
									<a class="dropdown-item" target="_top" href="/Transactions.cfm?action=findAccessions">Accession</a>
									<a class="dropdown-item" target="_top" href="/Transactions.cfm?action=findLoans">Loans</a>
									<a class="dropdown-item" target="_top" href="/Transactions.cfm?action=findBorrows">Borrow</a>
									<a class="dropdown-item" target="_top" href="/Transactions.cfm?action=findDeaccessions">Deaccession</a>
									<a class="dropdown-item" target="_top" href="/transactions/Permit.cfm">Permissions &amp; Rights</a>
								</div>
								<div style="float:left; width: 49%;">
									<div class="h5 dropdown-header px-4 text-danger">Create New Record</div>
									<a class="dropdown-item" target="_top" href="/transactions/Accession.cfm?action=new">Accession</a>
									<a class="dropdown-item" target="_top" href="/transactions/Loan.cfm?Action=newLoan">Loan</a>
									<a class="dropdown-item" target="_top" href="/transactions/Borrow.cfm?action=new">Borrow</a>
									<a class="dropdown-item" target="_top" href="/transactions/Deaccession.cfm?Action=new">Deaccession</a>
									<a class="dropdown-item" target="_top" href="/transactions/Permit.cfm?action=new">Permissions &amp; Rights</a>
								</div>
							</li>
						</ul>
						<!--- end main menu item transactions --->
					</li>
			 	</cfif>
				<li class="nav-item dropdown">
					<!--- main menu item review date, available to all with coldfusion_users --->
					<a class="nav-link dropdown-toggle text-left" target="_top" href="##">Review Data</a>
					<ul class="dropdown-menu border-0 shadow" style="min-width:23.5em; border-radius: .2rem;">
						<li class="d-md-flex align-items-start justify-content-start">
							<div style="float:left; width: 49%;">
								<div class="h5 dropdown-header px-4 text-danger">Reports &amp; Statistics</div>
								<a class="dropdown-item"  target="_top" href="/reporting/Reports.cfm">List of Reports</a>
								<a class="dropdown-item"  target="_top" href="/info/queryStats.cfm">Query Stats</a>
							</div>
							<div style="float:left;width: 49%;">
								<div class="h5 dropdown-header px-4 text-danger">Aggregators</div>
								<a class="dropdown-item"  target="_blank" href="https://www.gbif.org/occurrence/map?dataset_key=4bfac3ea-8763-4f4b-a71a-76a6f5f243d3">View MCZ data in GBIF </a>
								<a class="dropdown-item"  target="_blank" href="https://portal.idigbio.org/portal/search">View MCZ data in iDigBio</a>
							</div>
						</li>
					</ul>
					<!--- end main menu item review date --->
				</li>
				<cfif isdefined("session.roles") and ( listcontainsnocase(session.roles,"manage_codetables") or listcontainsnocase(session.roles,"dba") or listcontainsnocase(session.roles,"global_admin") )>
					<li class="nav-item dropdown">
						<!--- main menu item admin --->
						<a class="nav-link dropdown-toggle text-left" target="_top" href="##">Admin</a>
						<ul class="dropdown-menu border-0 shadow" style="min-width:34rem;border-radius: .2rem;">
							<li class="d-md-flex align-items-start justify-content-start">
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_codetables")>
									<div style="float:left; width: 33.2%;">
										<div class="h5 dropdown-header px-4 text-danger">Data</div>
										<a class="dropdown-item" target="_top" href="/CodeTableEditor.cfm">Code Table Editor</a>
										<a class="dropdown-item" target="_top" href="/vocabularies/GeologicalHierarchies.cfm">Geology Attribute Heirarchies</a>
										<a class="dropdown-item" target="_top" href="/Reports/reporter.cfm">Label/Report Management</a>
										<a class="dropdown-item" target="_top" href="/tools/downloadData.cfm">Download Tables</a>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
											<a class="dropdown-item" target="_top" href="/specimens/adminSpecimenSearch.cfm?action=search">Manage Specimen Search Fields</a>
											<a class="dropdown-item" target="_top" href="/specimens/adminSpecimenSearch.cfm?action=results">Manage Specimen Results Columns</a>
											<a class="dropdown-item" target="_top" href="/Admin/dumpAll.cfm">Dump Coldfusion Vars</a>
											<a class="dropdown-item" target="_top" href="/ScheduledTasks/index.cfm">Scheduled Tasks</a>
											<a class="dropdown-item" target="_top" href="/tools/imageList.cfm">Image List</a>
										</cfif>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"collops")>
											<a class="dropdown-item" target="_top" href="/media/debugMediaGallery.cfm">Test/Debug Media Widget</a>
										</cfif>
									</div>
								</cfif>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
									<div style="float:left;width: 33.2%;">
										<div class="h5 dropdown-header px-4 text-danger">Users/Privileges</div>
										<a class="dropdown-item" target="_top" href="/Admin/ActivityLog.cfm">Audit SQL</a>
										<a class="dropdown-item" target="_top" href="/AdminUsers.cfm">MCZbase Users</a>
										<a class="dropdown-item" target="_top" href="/tools/access_report.cfm?action=role">User Role Report</a>
										<a class="dropdown-item" target="_top" href="/Admin/user_roles.cfm">Database Roles</a>
										<!---
											<a class="dropdown-item" target="_top" href="/Admin/form_roles.cfm">Form Permissions</a>
											<a class="dropdown-item" target="_top" href="/tools/uncontrolledPages.cfm">See Form Permissions</a>
											TODO:  These doesn't seem to work on production, fix or remove.
										--->
										<a class="dropdown-item" target="_top" href="/Admin/blacklist.cfm">Manage Blocklist</a>
										<a class="dropdown-item" target="_top" href="/Admin/user_report.cfm">List of All Users</a>
										<a class="dropdown-item" target="_top" href="/Admin/manage_user_loan_request.cfm">User Loan Management</a>
									</div>
									<div style="float:left;width: 33.2%;">
										<div class="h5 dropdown-header px-4 text-danger">Application</div>
										<a class="dropdown-item" target="_top" href="/Admin/Collection.cfm">Manage Collection</a>
										<a class="dropdown-item" target="_top" href="/Admin/redirect.cfm">Redirects</a>
										<a class="dropdown-item" target="_top" href="/CFIDE/administrator/">Manage ColdFusion</a>
									</div>
								</cfif>
							</li>
						</ul>
						<!--- main menu item admin --->
					</li>
				</cfif>
				<!--- end additional main menu items to be shown to authorized users --->
			</cfif>
			<cfif len(session.username) gt 0>
				<li class="nav-item dropdown">
					<!--- main menu item account, for logged in users --->
					<a class="nav-link dropdown-toggle text-left" target="_top" href="##">Account</a>
					<ul class="dropdown-menu border-0 shadow" style="min-width:10rem;border-radius: .2rem;">
						<li class="d-md-flex align-items-start justify-content-start">
							<div>
								<a class="dropdown-item" target="_top" href="/users/UserProfile.cfm">User Profile</a>
								<cfif session.roles contains "coldfusion_user">
									<a class="dropdown-item" target="_top" href="/users/Searches.cfm">Saved Searches</a>
									<a href="/users/manageDownloadProfiles.cfm" class="dropdown-item" target="_top">Manage CSV Download Columm Profiles</a>
								</cfif>
							</div>
						</li>
					</ul>
					<!--- end main menu item account --->
				</li>
			</cfif>
			<li class="nav-item dropdown">
				<!--- main menu item help --->
				<a class="nav-link dropdown-toggle text-left" target="_top" href="##">Help</a>
				<ul class="dropdown-menu border-0 shadow" style="min-width:15rem;border-radius: .2rem;">
					<li class="d-md-flex align-items-start justify-content-start">
						<div>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
								<!--- show internal MCZ wiki link only to users with role coldfusion_user --->
								<a class="dropdown-item" target="_blank" href="https://code.mcz.harvard.edu/wiki/index.php/Using_MCZbase">Using MCZbase (Wiki Support)</a>
							</cfif>
							<a class="dropdown-item" target="_blank" href="https://mcz.harvard.edu/database">About MCZbase</a>
							<a class="dropdown-item" target="_blank" href="/vocabularies/ControlledVocabulary.cfm">Controlled Vocabularies</a>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
								<a class="dropdown-item" target="_blank" href="/specimens/viewSpecimenSearchMetadata.cfm?action=search&execute=true&method=getcf_spec_search_cols&access_role=!HIDE">Specimen Search Builder Help</a>
							<cfelse>
								<a class="dropdown-item" target="_blank" href="/specimens/viewSpecimenSearchMetadata.cfm?action=search&execute=true&method=getcf_spec_search_cols&access_role=PUBLIC">Specimen Search Builder Help</a>
							</cfif>
							<a class="dropdown-item" href="/collections/index.cfm">Holdings</a>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
								<a class="dropdown-item" href="/Reports/listReports.cfm">List of Label Reports</a>
							</cfif>
					 		<a class="dropdown-item" target="_blank" href="/info/api.cfm">API</a>
						</div>
					</li>
				</ul>
				<!--- end main menu item help --->
			</li>
		</ul><!---sf-menu--->
		<div id="headerLinks">
			<!--- login/logout section of menu bar --->
			<cfif len(#session.username#) gt 0>
				<ul>
					<li><a target="_top" href="/login.cfm?action=signOut">Log out #session.username#</a></li>
					<cfif isdefined("session.last_login") and len(#session.last_login#) gt 0>
						<li><span>&nbsp;&nbsp;(Last login: #dateformat(session.last_login, "dd-mmm-yyyy")#)&nbsp;</span></li>
					</cfif>
					<cfif isdefined("session.needEmailAddr") and session.needEmailAddr is 1>
						<br>
						<li><span> You have no email address in your profile. Please correct. </span></li>
					</cfif>
				</ul>
			<cfelse>
				<cfif isdefined("cgi.REDIRECT_URL") and len(cgi.REDIRECT_URL) gt 0>
					<cfset gtp=replace(cgi.REDIRECT_URL, "//", "/")>
				<cfelse>
					<cfset gtp=replace(cgi.SCRIPT_NAME, "//", "/")>
				</cfif>
				<form name="logIn" method="post" action="/login.cfm">
					<input type="hidden" name="action" value="signIn">
					<input type="hidden" name="mode" value="">
					<input type="hidden" name="gotopage" value="#gtp#">
					<ul>
						<li><span>Username:</span></li>
						<li>
							<input type="text" name="username" title="Username" size="14"
								class="loginTxt" onfocus="if(this.value==this.title){this.value=''};">
						</li>
						<li><span>Password:</span></li>
						<li><input type="password" name="password" title="Password" size="14" class="loginTxt"></li>
						<li>
							<input type="submit" value="Log In" class="smallBtn"> <span>or</span>
							<input type="button" value="Create Account" class="smallBtn" onClick="logIn.action.value='loginForm';logIn.mode.value='register';submit();">
						</li>
					</ul>
				</form>
			</cfif>
		</div><!---end headerLinks--->
	</div><!--- end sf-mainMenuWrapper--->

	<cf_rolecheck>

</cfoutput>
<div id="pg_container">
<div class="content_box">
