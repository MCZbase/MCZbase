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
      <div class="sf-mainMenuWrapper">

  <ul class="sf-menu">
        <li><!--main menu element-->
            <a target="_top" href="/SpecimenSearch.cfm">Search</a>
              <ul>
                 <li><a target="_top" href="/SpecimenSearch.cfm">Specimens</a></li>
                 <li><a target="_top" href="/SpecimenUsage.cfm">Publications/Projects</a></li>
                 <li><a target="_top" href="/Taxa.cfm">Taxonomy</a></li>
                 <li><a target="_top" href="/MediaSearch.cfm">Media</a></li>
                 <li><a target="_top" href="/showLocality.cfm">Places</a></li>
				  <li><a target="_top" href="/agents.cfm">Agents</a></li>
				 <li><a target="_top" href="/SpecimenUsage.cfm">Publications/Projects</a></li>
				 <li><a target="_top" href="/info/reviewAnnotation.cfm">Annotations</a></li>
<cfif len(session.roles) gt 0 and session.roles is not "public">
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
						<li><a target="_top" href="/DataEntry.cfm">Enter Specimen Data</a></li>
						<li><a target="_top" href="">Create Media Record</a></li>
						<li><a target="_top" href="">Create Agent Record</a></li>
						<li><a target="_top" href="">Create Project Record</a></li>
						<li><a target="_top" href="">Create Publication Record</a></li>
						<li><a target="_top" href="/bulkloading/Bulkloaders.cfm">Bulkloaders</a></li>
						<li><a target="_top" href="/Bulkloader/bulkloader_status.cfm">Bulkload Status</a></li>
						<li><a target="_top" href="/Bulkloader/bulkloaderBuilder.cfm">Bulkloader Builder</a></li>
						<li><a target="_top" href="/bulkloading/Bulkloaders.cfm">Browse &amp; Edit</a></li>
					</ul>
              </li>
				  <!--start main menu element-->
         <li>
            <a target="_top" href="##">Manage Data</a>
            <ul>
              	<cfif listfind(formList,"/Locality.cfm")>
                <li><a target="_top" href="##">Location</a>
                  	<ul>
                    <li><a target="_top" href="/Locality.cfm?action=findHG">Find Geography</a></li>
					<cfif len(session.roles) gt 0 and FindNoCase("manage_geography",session.roles) NEQ 0>
                    	<li><a target="_top" href="/Locality.cfm?action=newHG">Create Geography</a></li>
					</cfif>
                    <li><a target="_top" href="/Locality.cfm?action=findLO">Find Locality</a></li>
                    <li><a target="_top" href="/Locality.cfm?action=newLocality">Create Locality</a></li>
                    <li><a target="_top" href="/Locality.cfm?action=findCO">Find Event</a></li>
                    <li><a target="_top" href="/info/geol_hierarchy.cfm">Geology Attributes Hierarchy</a></li>
                  </ul>
                </li>
              </cfif>
								 <li><a target="_top" href="##">Agents</a>
					<ul>
						  <cfif listfind(formList,"/agents.cfm")>
							<li><a target="_top" href="/agents.cfm">Agents</a></li>
						  </cfif>
						  <cfif listfind(formList,"/Admin/agentMergeReview.cfm")>
							<li><a target="_top" href="/Admin/agentMergeReview.cfm">Review pending agent merges</a></li>
						  </cfif>
						  <cfif listfind(formList,"/Admin/killBadAgentDups.cfm")>
							<li><a target="_top" href="/Admin/killBadAgentDups.cfm">Merge bad dup agents</a></li>
						  </cfif>
					</ul>
				</li>
                <cfif listfind(formList,"/editContainer.cfm") OR listfind(formList,"/tools/dgr_locator.cfm")>
                <li><a target="_top" href="##">Object Tracking</a>
                      <ul>
                    <cfif listfind(formList,"/tools/dgr_locator.cfm")>
                          <li><a target="_top" href="/tools/dgr_locator.cfm">DGR Locator</a></li>
                        </cfif>
                    <cfif listfind(formList,"/moveContainer.cfm")>
                          <li><a target="_top" href="/findContainer.cfm">Find Container</a></li>
                          <li><a target="_top" href="/moveContainer.cfm">Move Container</a></li>
                          <li><a target="_top" href="/batchScan.cfm">Batch Scan</a></li>
                          <li><a target="_top" href="/labels2containers.cfm">Label>Container</a></li>
                          <li><a target="_top" href="/part2container.cfm">Object+BC>>Container</a></li>
                        </cfif>
                    <cfif listfind(formList,"/editContainer.cfm")>
                          <li><a target="_top" href="/LoadBarcodes.cfm">Upload Scan File</a></li>
                          <li><a target="_top" href="/editContainer.cfm?action=newContainer">Create Container</a></li>
                          <li><a target="_top" href="/CreateContainersForBarcodes.cfm">Create Container Series</a></li>
                          <li><a target="_top" href="/SpecimenContainerLabels.cfm">Clear Part Flags</a></li>
                        </cfif>
                  </ul>
               </li>
              	</cfif>
                <cfif listfind(formList,"/Encumbrances.cfm")>
                   <li><a target="_top" href="##">Metadata</a>
                      <ul>
                        <cfif listfind(formList,"/Encumbrances.cfm")>
                          <li><a target="_top" href="/Encumbrances.cfm">Encumbrances</a></li>
                        </cfif>
                        <cfif listfind(formList,"/CodeTableEditor.cfm")>
                          <li><a target="_top" href="/CodeTableEditor.cfm">Code Tables</a></li>
                        </cfif>
                        <cfif listfind(formList,"/Admin/Collection.cfm")>
                          <li><a target="_top" href="/Admin/Collection.cfm">Manage Collection</a></li>
                        </cfif>
                     </ul>
                  </li>
                  </cfif>
                <cfif listfind(formList,"/info/reviewAnnotation.cfm")>
                	<li><a target="_top" href="##">Tools</a>
						<ul>
								<li><a target="_top" href="/tools/PublicationStatus.cfm">Publication Staging</a></li>
									  <li><a target="_top" href="/tools/parent_child_taxonomy.cfm">Sync <span style="font-size: 10px;">parent/child</span> taxonomy</a></li>
								<li><a target="_top" href="/tools/pendingRelations.cfm">Pending Relationships</a></li>
								<cfif listfind(formList,"/tools/sqlTaxonomy.cfm")>
									  <li><a target="_top" href="/tools/sqlTaxonomy.cfm">SQL Taxonomy</a></li>
									</cfif>
								<li><a target="_top" href="/Admin/redirect.cfm">Redirects</a></li>
						</ul>
                    </li>
              	</cfif>
            </ul>
		</li><!--end main menu element-->
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
            <li><a target="_top" href="##">Reports & Statistics</a>
                  <ul>

					    <li><a target="_top" href="/reporting/Reports.cfm">List of Reports</a></li>
                        <li><a target="_top" href="/info/queryStats.cfm">Query Stats</a></li>
<!---                  <li><a target="_top" href="##">Reports</a>
                           <ul>
							<li><a target="_top" href="/Reports/reporter.cfm">Reporter</a></li>
                        	<li><a target="_top" href="/info/mia_in_genbank.cfm">GenBank MIA</a></li>
                        	<li><a target="_top" href="/info/reviewAnnotation.cfm">Annotations</a></li>
                       		<li><a target="_top" href="/info/recentgeorefs.cfm">Recently Georeferenced Localities</a></li>
                            <li><a target="_top" href="/info/collnHoldgByClass.cfm">Collection Holdings by Class</a></li>
                            <li><a target="_top" href="/Admin/bad_taxonomy.cfm">Invalid Taxonomy</a></li>
                            <li><a target="_top" href="/tools/TaxonomyScriptGap.cfm">Unscriptable Taxonomy Gaps</a></li>
                            <li><a target="_top" href="/info/slacker.cfm">Suspect Data</a></li>
                            <li><a target="_top" href="/info/noParts.cfm">Partless Specimens</a></li>
                            <li><a target="_top" href="/tools/TaxonomyGaps.cfm">Messy Taxonomy</a></li>
                            <li><a target="_top" href="/tools/findGap.cfm">Catalog Number Gaps</a></li>
                            <li><a target="_top" href="/info/dupAgent.cfm">Duplicate Agents</a></li>
                            <li><a target="_top" href="/Reports/partusage.cfm">Part Usage</a></li>
                          </ul>
                    </li>--->
<!---                          <li><a target="_top" href="##">Oracle/SQL</a>
                           <ul>
                            <li><a target="_top" href="/Admin/ActivityLog.cfm">Audit SQL</a></li>
                           <li><a target="_top" href="/tools/downloadData.cfm">Download Tables</a></li>
                           <li><a target="_top" href="/tools/access_report.cfm">Oracle Roles</a></li>
                            <cfif listfind(formList,"/tools/userSQL.cfm")>
                            <li><a target="_top" href="/tools/userSQL.cfm">Write SQL</a></li>
                            </cfif>
                           </ul>
                       </li>--->
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
           <li><a target="_top" href="/myArctos.cfm">My Stuff</a>
              <ul>
                  <cfif len(session.username) gt 0>
                  <li><a target="_top" href="/myArctos.cfm">Profile</a></li>
                  <cfelse>
                  <li><a target="_top" href="/myArctos.cfm">Log In</a></li>
                  </cfif>
                <li><a target="_blank" href="https://sites.google.com/site/arctosdb/" class="external">More Info</a></li>
                <li><a target="_top" href="/home.cfm">About</a></li>
                <li><a target="_top" href="/Collections/index.cfm">Collections (Loans)</a></li>
                <cfif len(session.username) gt 0>
                	<li><a target="_top" href="/saveSearch.cfm?action=manage">Saved Searches</a></li>
                </cfif>
                <li><a target="_top" href="/info/api.cfm">API</a></li>
              </ul>
            </li>
          <li><a target="_top" href="##">Help</a>
                    <ul>
                       <cfscript>
			    serverName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
                       </cfscript>
                     <!--- server name may be the correct fully qualified name or may be just the hostname, e.g. mczbase-prd  ---> 
                     <cfif serverName contains "harvard.edu" or serverName contains "mczbase" >
                       <li><a target="_blank" href="https://code.mcz.harvard.edu/wiki/index.php/Using_MCZbase">Using MCZbase</a></li>
                     </cfif>
                      <li><a target="_blank" href="http://arctosdb.wordpress.com">About Arctos</a></li>
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
