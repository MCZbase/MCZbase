<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
 <head>
    <cfif isdefined("usealternatehead") and #usealternatehead# eq "image">
      <cfinclude template="/includes/imageInclude.cfm">
      <cfelseif isdefined("usealternatehead") and #usealternatehead# eq "feedreader">
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
                    minWidth:    12,
                    maxWidth:    30,
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
    <cfoutput>
    <meta name="keywords" content="#session.meta_keywords#">
    <LINK REL="SHORTCUT ICON" HREF="/images/favicon.ico">
    <meta http-equiv="content-type" content="text/html; charset=utf-8">
</head>
<body>
<noscript>
    <div class="browserCheck"> JavaScript is turned off in your web browser. Please turn it on to take full advantage of MCZbase, or
  try our <a target="_top" href="/SpecimenSearchHTML.cfm">HTML SpecimenSearch</a> option. </div>
</noscript>

<div id="headerContent" style="background-color: #Application.header_color#;">
     <div id="image_headerWrap">
           <div class="headerText">
              <a href="http://mcz.harvard.edu/" target="_blank">
              <img src="#Application.header_image#" alt="MCZ Kronosaurus Logo">
              </a>
              <h1 style="color:#Application.collectionlinkcolor#;"><span>#Application.collection_link_text#</h1>  <!--- close span is in collection_collection_link_text --->
              <h2 style="color:#Application.institutionlinkcolor#;"><a href="https://mcz.harvard.edu/" target="_blank"><span style="color:#Application.institutionlinkcolor#" class="headerInstitutionText">#session.institution_link_text#</span></a></h2>
         </div><!---end headerText--->
    </div><!---end image_headerWrap--->
  </div><!--- end headerContent div --->
      <div class="sf-mainMenuWrapper" style="font-size: 14px;">

  <ul class="sf-menu">
        <li><!--main menu element-->
            <a target="_top" href="/SpecimenSearch.cfm">Search</a>
              <ul>
                 <li><a target="_top" href="/SpecimenSearch.cfm">Specimens</a></li>
                 <li><a target="_top" href="/SpecimenUsage.cfm">Publications/Projects</a></li>
                 <li><a target="_top" href="/Taxa.cfm">Taxonomy</a></li>
                 <li><a target="_top" href="/MediaSearch.cfm">Media</a></li>
                 <li><a target="_top" href="/showLocality.cfm">Places</a></li>
				  <cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
				  <li><a target="_top" href="/agents.cfm">Agents</a></li>
				  </cfif>
				 <li><a target="_top" href="/SpecimenUsage.cfm">Publications/Projects</a></li>
				 <li><a target="_top" href="/info/reviewAnnotation.cfm">Annotations</a></li>
					<cfif len(session.roles) gt 0 and listcontainsnocase(session.roles,"coldfusion_user")>
					<li><a target="_top" href="/tools/userSQL.cfm">SQL Queries</a></li>
					</cfif>
             </ul>
         </li><!--end main menu element-->
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
              <li><!--main menu element-->
                  <a href="##">Data Entry</a>
					<ul>
					<cfif listfind(formList,"/DataEntry.cfm")>
						<li><a target="_top" href="/DataEntry.cfm">Enter Specimen Data</a></li>
						<li><a target="_top" href="">Create Media Record</a></li>
						</cfif>
						  <cfif listfind(formList,"/agents.cfm")>
						<li><a target="_top" href="">Create Agent Record</a></li>
						</cfif>
						<cfif listfind(formList,"/DataEntry.cfm")>
						<li><a target="_top" href="/Project.cfm?action=makeNew">Create Project Record</a></li>
						<li><a target="_top" href="/Publication.cfm?action=newPub">Create Publication Record</a></li>
						<li><a target="_top" href="/Bulkloader/bulkloaderBuilder.cfm">Bulkloader Builder</a></li>
						<li><a target="_top" href="/bulkloading/Bulkloaders.cfm">Browse &amp; Edit</a></li>
						<li><a target="_top" href="/Bulkloader/bulkloader_status.cfm">Bulkload Status</a></li>
						<li><a target="_top" href="/bulkloading/Bulkloaders.cfm">Bulkloaders</a></li>
						<li><a target="_top" href="/tools/PublicationStatus.cfm">Publication Staging</a></li>
						<li><a target="_top" href="/tools/DataLoanBulkload.cfm">Data Loan Items</a></li>
							</cfif>
					</ul>
              </li>
				  <!--start main menu element-->
         <li>
            <a target="_top" href="##">Manage Data</a>
			<ul>
				<cfif listfind(formList,"/Locality.cfm")>
				<li><a target="_top" href="/Locality.cfm?action=findHG">Search Geography</a></li>
				<li><a target="_top" href="/Locality.cfm?action=findLO">Search Localities</a></li>
				<li><a target="_top" href="/Locality.cfm?action=findCO">Search Collecting Event</a></li>
				<li><a target="_top" href="">Search Collecting Event Number Series</a></li>
				<li><a target="_top" href="/Locality.cfm?action=newHG">Create Geography</a></li>
				<li><a target="_top" href="/Locality.cfm?action=newLO">Create Locality</a></li>
				<li><a target="_top" href="/Locality.cfm?action=newCO">Create Collecting Event Number Series</a></li>
				</cfif>
				<li><a target="_top" href="/Encumbrances.cfm">Manage Encumbrances</a></li>
				<cfif listfind(formList,"/info/reviewAnnotation.cfm")>
				<li><a target="_top" href="/info/reviewAnnotation.cfm">Manage Annotations</a></li>
				</cfif>
				 <cfif listfind(formList,"/Admin/agentMergeReview.cfm")>
				<li><a target="_top" href="/Admin/agentMergeReview.cfm">Review Pending Agent Merges</a></li>
				</cfif>
				<cfif listfind(formList,"/Admin/killBadAgentDups.cfm")>
				<li><a target="_top" href="/Admin/killBadAgentDups.cfm">Merge Bad Duplicate Agents</a></li>
				</cfif>
				<li><a target="_top" href="/tools/parent_child_taxonomy.cfm">Sync Parent/Child Taxonomy</a></li>
				<li><a target="_top" href="/tools/pendingRelations.cfm">Pending Relationships</a></li>
				<li><a target="_top" href="/tools/sqlTaxonomy.cfm">SQL Taxonomy</a></li>
			</ul>

		</li><!--end main menu element-->
				  
		<li>
			<a target="_top" href="##">Curation</a>
			<ul>
				<li><a href="/grouping/NamedCollection.cfm" target="_top">Search Named Groupings</a></li>
				<li><a href="/grouping/NamedCollection.cfm?action=new" target="_top">Create Named Grouping</a></li>
				<cfif listfind(formList,"/editContainer.cfm") OR listfind(formList,"/tools/dgr_locator.cfm")>
				<li><a href="/ContainerBrowse.cfm" target="_top">Browse Storage Locations</a></li>
				<li><a href="/findContainer.cfm" target="_top">Find Storage Container Location</a></li>
				<li><a href="/editContainer.cfm?action=newContainer" target="_top">Create Container/Storage Location</a></li>
				<li><a href="/CreateContainersForBarcodes.cfm" target="_top">Create Container Series</a></li>
				<li><a href="/moveContainer.cfm" target="_top">Move Container</a></li>
				<li><a href="/batchScan.cfm" target="_top">Batch Scan</a></li>
				<li><a href="/labels2containers.cfm" target="_top">Label > Container</a></li>
				<li><a href="/part2container.cfm" target="_top">Put Parts in Containers</a></li>
				<li><a href="/SpecimenContainerLabels.cfm" target="_top">Clear Flags</a></li>
				<li><a href="/LoadBarcodes.cfm" target="_top">Upload Scan File</a></li>
					    <cfif listfind(formList,"/Encumbrances.cfm")>
                          <li><a target="_top" href="/Encumbrances.cfm">Encumbrances</a></li>
                        </cfif>
					     <cfif listfind(formList,"/CodeTableEditor.cfm")>
                          <li><a target="_top" href="/CodeTableEditor.cfm">Code Tables</a></li>
                        </cfif>
					     <cfif listfind(formList,"/Admin/Collection.cfm")>
                          <li><a target="_top" href="/Admin/Collection.cfm">Manage Collection</a></li>
                        </cfif>
				</cfif>
			</ul>
		</li>
			   
      <cfif listfind(formList,"/newAccn.cfm")>
		<li><a target="_top" href="##">Transactions</a>
                      <ul>
                        <li><a target="_top" href="/Transactions.cfm">Find Transactions</a></li>
                        <li><a target="_top" href="/newAccn.cfm">Create Accession</a></li>
                        <li><a target="_top" href="/editAccn.cfm">Find Accession</a></li>
                        <li><a target="_top" href="/transactions/Loan.cfm?Action=newLoan">Create Loan</a></li>
                        <li><a target="_top" href="/Transactions.cfm?action=findLoans">Find Loans</a></li>
                        <li><a target="_top" href="/Deaccession.cfm?Action=newDeacc">Create Deaccession</a></li>
                        <li><a target="_top" href="/Deaccession.cfm?Action=search">Find Deaccession</a></li>
                        <li><a target="_top" href="/Borrow.cfm?action=new">Create Borrow</a></li>
                        <li><a target="_top" href="/Borrow.cfm">Find Borrow</a></li>
                        <li><a target="_top" href="/transactions/Permit.cfm?action=new">Create Permit</a></li>
                        <li><a target="_top" href="/transactions/Permit.cfm">Find Permit</a></li>
                     </ul>
         </li><!--end main menu element-->
      </cfif>
  
           <cfif listfind(formList,"/Admin/ActivityLog.cfm")>
            <li><a target="_top" href="##">Review Data</a>
                  	<ul>
					    <li><a target="_top" href="/reporting/Reports.cfm">List of Reports &amp; Statistics</a></li>
                        <li><a target="_top" href="/info/queryStats.cfm">Query Stats</a></li>
					    <li><a target="_top" href="https://www.gbif.org/occurrence/map?dataset_key=4bfac3ea-8763-4f4b-a71a-76a6f5f243d3">View MCZ data in GBIF </a></li>
					    <li><a target="_top" href="https://portal.idigbio.org/portal/search">View MCZ data in iDigBio</a></li>
              		</ul>
                </li>
          </cfif>
            </cfif>
	        <li><a target="_top" href="##">Admin</a>
            <ul>
              <cfif listfind(formList,"/ScheduledTasks/index.cfm")>
                <li> <a target="_top" href="##">Developer Widgets</a>
                  <ul>
                    <li><a target="_top" href="/ScheduledTasks/index.cfm">Scheduled Tasks</a></li>
                    <li><a target="_top" href="/Admin/dumpAll.cfm">Dump</a></li>
                    <li><a target="_top" href="/CFIDE/administrator/">Manage ColdFusion</a></li>
                    <li><a target="_top" href="/tools/imageList.cfm">Image List</a></li>
                  </ul>
                </li>
              </cfif>
              <cfif listfind(formList,"/AdminUsers.cfm")>
                <li><a target="_top" href="##">Roles/Permissions</a>
                  <ul>
                    <li><a target="_top" href="/Admin/form_roles.cfm">Form Permissions</a></li>
                    <li><a target="_top" href="/tools/uncontrolledPages.cfm">See Form Permissions</a></li>
                    <li><a target="_top" href="/Admin/blacklist.cfm">Blacklist IP</a></li>
                    <li><a target="_top" href="/AdminUsers.cfm">MCZbase Users</a></li>
                    <li><a target="_top" href="/Admin/user_roles.cfm">Database Roles</a></li>
                    <li><a target="_top" href="/Admin/user_report.cfm">All User Stats</a></li>
                    <li><a target="_top" href="/Admin/manage_user_loan_request.cfm">User Loan</a></li>
					 <li><a target="_top" href="/Admin/ActivityLog.cfm">Oracle Audit</a></li>
                  </ul>
                </li>
              </cfif>
            </ul>
          </li>
           <li><a target="_top" href="/myArctos.cfm">Account</a>
              <ul>
                  <cfif len(session.username) gt 0>
                  <li><a target="_top" href="/myArctos.cfm">User Profile</a></li>
                  <cfelse>
                  <li><a target="_top" href="/myArctos.cfm">Log In</a></li>
                  </cfif>
                <li><a target="_top" href="/home.cfm">About</a></li>
          <!---      <li><a target="_top" href="/Collections/index.cfm">Collections (Loans)</a></li>--->
                <cfif len(session.username) gt 0>
                	<li><a target="_top" href="/saveSearch.cfm?action=manage">Saved Searches</a></li>
                </cfif>
     <!---           <li><a target="_top" href="/info/api.cfm">API</a></li>--->
					<!---    <li><a target="_top" href="">Technical Details</a></li>--->
              </ul>
            </li>
          <li><a target="_top" href="##">Help</a>
                  <ul>
                       <cfscript>
			    serverName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
                       </cfscript>
                     <!--- server name may be the correct fully qualified name or may be just the hostname, e.g. mczbase-prd  ---> 
                     <cfif serverName contains "harvard.edu" or serverName contains "mczbase" >
                       <li><a target="_blank" href="https://code.mcz.harvard.edu/wiki/index.php/Using_MCZbase">Using MCZbase (Wiki Support)</a></li>
                     </cfif>
					 <li><a target="_blank" href="/vocabularies/ControlledVocabulary.cfm">Controlled Vocabularies</a></li>
                     <li><a target="_blank" href="https://mcz.harvard.edu/database">About MCZbase</a></li>
					  <li><a target="_blank" href="/info/api.cfm">API</a></li>
                 </ul>
            </li>
      </ul><!---sf-menu--->
       <div id="headerLinks">
        <cfif len(#session.username#) gt 0>
            <ul><li><a target="_top" href="/login.cfm?action=signOut">Log out #session.username#</a></li>
                  <cfif isdefined("session.last_login") and len(#session.last_login#) gt 0>
                      <li><span>&nbsp;&nbsp;(Last login: #dateformat(session.last_login, "dd-mmm-yyyy")#)&nbsp;</span></li>
                  </cfif>
                 <cfif isdefined("session.needEmailAddr") and session.needEmailAddr is 1>
                    <br>
                     <li><span> You have no email address in your profile. Please correct. </span></li>
                     </ul>
                  </cfif>
           </div>
        <cfelse>
                 <cfif isdefined("cgi.REDIRECT_URL") and len(cgi.REDIRECT_URL) gt 0>
                   <cfset gtp=replace(cgi.REDIRECT_URL, "//", "/")>
                  <cfelse>
                   <cfset gtp=replace(cgi.SCRIPT_NAME, "//", "/")>
                  </cfif>
                        <form name="logIn" method="post" action="/login.cfm">
                          <input type="hidden" name="action" value="signIn">
                          <input type="hidden" name="gotopage" value="#gtp#">

                        <ul><li><span>Username:</span></li>
                            <li><input type="text" name="username" title="Username" size="14"
                                                      class="loginTxt" onfocus="if(this.value==this.title){this.value=''};"></li>
                            <li><span>Password:</span></li>
                            <li><input type="password" name="password" title="Password" size="14" class="loginTxt"></li>
                            <li><input type="submit" value="Log In" class="smallBtn"> <span>or</span>
                                  <input type="button" value="Create Account" class="smallBtn" onClick="logIn.action.value='newUser';submit();"></li>
                            </ul>
                         </form>
           </div><!---end headerLinks--->
         </cfif>
    </div><!--- end sf-mainMenuWrapper--->


<cf_rolecheck>
</cfoutput>
<div id="pg_container">
<div class="content_box">
