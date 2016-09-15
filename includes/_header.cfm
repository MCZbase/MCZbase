<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
 <head>
    <cfif isdefined("usealternatehead") and #usealternatehead# eq "image">
      <cfinclude template="/includes/imageInclude.cfm">
      <cfelseif isdefined("usealternatehead") and #usealternatehead# eq "feedreader">
      <cfinclude template="/includes/feedReaderInclude.cfm">
      <cfelseif isdefined("usealternatehead") and #usealternatehead# eq "DataEntry">
      <cfinclude template="/includes/DataEntryInclude.cfm">
      <cfelse>
      <!--- Default elements to be included at the top of the html head --->
      <cfinclude template="/includes/alwaysInclude.cfm">
    </cfif>
    <cfif not isdefined("session.header_color")>
      <cfset setDbUser()>
    </cfif>
    <cfoutput>
    <script language="javascript" type="text/javascript">
           jQuery(document).ready(function(){
                jQuery("ul.sf-menu").supersubs({
                    minWidth:    12,
                    maxWidth:    30,
                    extraWidth:  1
                }).superfish({
                    delay:       600,
                    animation:   {opacity:'show',height:'show'},
                    speed:       0,
                });
                if (top.location!=document.location) {
                                $("##footerContentBox").hide();
                                $("##headerContent").hide();
                                $("##mainMenuWrapper").hide();
                }
            });
	</script>
    <meta name="keywords" content="#session.meta_keywords#">
    <LINK REL="SHORTCUT ICON" HREF="/images/favicon.ico">
    <meta http-equiv="content-type" content="text/html; charset=utf-8">
</head>
<body>
<noscript>
    <div class="browserCheck"> JavaScript is turned off in your web browser. Please turn it on to take full advantage of Arctos, or
  try our <a target="_top" href="/SpecimenSearchHTML.cfm">HTML SpecimenSearch</a> option. </div>
</noscript>

<div id="headerContent" style='background-color: #Application.header_color#;'>
     <div id="image_headerWrap">
           <div class="headerText"> 
              <a href="http://www.mcz.harvard.edu" target="_blank">
              <img src="#Application.header_image#" alt="MCZ Kronosaurus Logo">
              </a> 
              <h1 style="color: #Application.collectionlinkcolor#;">#Application.collection_link_text#</h1>
              <h2 style="color: #Application.institutionlinkcolor#;">#session.institution_link_text#</h2>
         </div><!---end headerText--->
    </div><!---end image_headerWrap--->
  </div><!--- end headerContent div --->
 <div id="mainMenuWrapper" class="sf-mainMenuWrapper">
        <div id="headerLinks">
        <cfif len(#session.username#) gt 0>
              <a target="_top" href="/login.cfm?action=signOut">Log out #session.username#</a>
                  <cfif isdefined("session.last_login") and len(#session.last_login#) gt 0>
                  <span>(Last login: #dateformat(session.last_login, "dd-mmm-yyyy")#)</span>&nbsp;
                  </cfif>
                 <cfif isdefined("session.needEmailAddr") and session.needEmailAddr is 1>
                    <br>
                  <span> You have no email address in your profile. Please correct. </span>
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
         <ul>
         <li>Username:
   		 <input type="text" name="username" title="Username" size="14" class="loginTxt" onfocus="if(this.value==this.title){this.value=''};"></li>
         <li>Password:
         <input type="password" name="password" title="Password" size="14" class="loginTxt"> 
         <input type="submit" value="Log In" class="smallBtn"> or
         <input type="button" value="Create Account" class="smallBtn"
             onClick="logIn.action.value='newUser';submit();"></li>
          </ul>
     </form>
           </div><!---end headerLinks--->
         </cfif>
    
        <ul class="sf-menu">
        <li> <a target="_top" href="/SpecimenSearch.cfm">Search</a>
              <ul>
            <li><a target="_top" href="/SpecimenSearch.cfm">Specimens</a></li>
            <li><a target="_top" href="/SpecimenUsage.cfm">Publications/Projects</a></li>
            <li><a target="_top" href="/TaxonomySearch.cfm">Taxonomy</a></li>
            <li><a target="_top" href="/MediaSearch.cfm">Media</a></li>
            <li><a target="_top" href="/showLocality.cfm">Places</a></li>
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
              <li><a href="##">Enter Data</a>
            <ul>
                  <li><a target="_top" href="/DataEntry.cfm">Data Entry</a></li>
                  <li><a target="_top" href="##">Bulkloader</a>
                <ul>
                      <cfif listfind(formList,"/Bulkloader/bulkloader_status.cfm")>
                    <li><a target="_top" href="/Bulkloader/">Bulkload Specimens</a></li>
                    <li><a target="_top" href="/Bulkloader/bulkloader_status.cfm">Bulkloader Status</a></li>
                    <li><a target="_top" href="/Bulkloader/bulkloaderBuilder.cfm">Bulkloader Builder</a></li>
                    <li><a target="_top" href="##" onclick="getDocs('Bulkloader/index')">Bulkloader Docs</a></li>
                  </cfif>
                      <cfif listfind(formList,"/Bulkloader/browseBulk.cfm")>
                    <li><a target="_top" href="/Bulkloader/browseBulk.cfm">Browse and Edit</a></li>
                  </cfif>
                    </ul>
              </li>
                  <cfif listfind(formList,"/tools/BulkloadParts.cfm")>
                <li><a target="_top" href="##">Batch Tools</a>
                      <ul>
                    <li><a target="_top" href="/tools/BulkloadParts.cfm">Bulkload Parts</a></li>
                    <!--<li><a target="_top" href="/tools/BulkPartSample.cfm">Bulkload Part Subsamples (Lots)</a></li>-->
                    <li><a target="_top" href="/tools/BulkloadAttributes.cfm">Bulkload Attributes</a></li>
                    <li><a target="_top" href="/tools/BulkloadCitations.cfm">Bulkload Citations</a></li>
                    <li><a target="_top" href="/tools/BulkloadOtherId.cfm">Bulkload Identifiers</a></li>
                    <li><a target="_top" href="/tools/loanBulkload.cfm">Bulkload Loan Items</a></li>
                    <li><a target="_top" href="/tools/DataLoanBulkload.cfm">Bulkload DataLoan Items</a></li>
                    <li><a target="_top" href="/DataServices/agents.cfm">Bulkload Agents</a></li>
                    <li><a target="_top" href="/tools/BulkloadPartContainer.cfm">Parts>>Containers</a></li>
                    <li><a target="_top" href="/tools/BulkloadIdentification.cfm">Identifications</a></li>
                    <li><a target="_top" href="/tools/BulkloadContEditParent.cfm">Bulk Edit Container</a></li>
                    <li><a target="_top" href="/tools/BulkloadMedia.cfm">Bulkload Media</a></li>
                    <!---li><a target="_top" href="/tools/uploadMedia.cfm">upload images</a></li--->
                    <li><a target="_top" href="/tools/BulkloadRelations.cfm">Bulkload Relationships</a></li>
                    <li><a target="_top" href="/tools/BulkloadGeoref.cfm">Bulkload Georeference</a></li>
                    <cfif listfind(formList,"/tools/BulkloadTaxonomy.cfm")>
                          <li><a target="_top" href="/tools/BulkloadTaxonomy.cfm">Bulk Taxonomy</a></li>
                        </cfif>
                  </ul>
                    </li>
              </cfif>
                </ul>
          </li>
              <li><a target="_top" href="##">Manage Data</a>
            <ul>
                  <cfif listfind(formList,"/Locality.cfm")>
                <li><a target="_top" href="##">Location</a>
                      <ul>
                    <li><a target="_top" href="/Locality.cfm?action=findHG">Find Geography</a></li>
                    <li><a target="_top" href="/Locality.cfm?action=newHG">Create Geography</a></li>
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
                  <cfif listfind(formList,"/EditContainer.cfm") OR listfind(formList,"/tools/dgr_locator.cfm")>
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
                    <cfif listfind(formList,"/EditContainer.cfm")>
                          <li><a target="_top" href="/LoadBarcodes.cfm">Upload Scan File</a></li>
                          <li><a target="_top" href="/EditContainer.cfm?action=newContainer">Create Container</a></li>
                          <li><a target="_top" href="/CreateContainersForBarcodes.cfm">Create Container Series</a></li>
                          <li><a target="_top" href="/SpecimenContainerLabels.cfm">Clear Part Flags</a></li>
                        </cfif>
                  </ul>
                    </li>
              </cfif>
                  <cfif listfind(formList,"/Loan.cfm")>
                <li><a target="_top" href="##">Transactions</a>
                      <ul>
                    <li><a target="_top" href="/newAccn.cfm">Create Accession</a></li>
                    <li><a target="_top" href="/editAccn.cfm">Find Accession</a></li>
                    <li><a target="_top" href="/Loan.cfm?Action=newLoan">Create Loan</a></li>
                    <li><a target="_top" href="/Loan.cfm?Action=newLoan&scope=Gift">Create Gift</a></li>
                    <li><a target="_top" href="/Loan.cfm?Action=search">Find Loans/Gifts</a></li>
                    <li><a target="_top" href="/borrow.cfm?action=new">Create Borrow</a></li>
                    <li><a target="_top" href="/borrow.cfm">Find Borrow</a></li>
                    <li><a target="_top" href="/Permit.cfm?action=newPermit">Create Permit</a></li>
                    <li><a target="_top" href="/Permit.cfm">Find Permit</a></li>
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
                    <li><a target="_top" href="/tools/parent_child_taxonomy.cfm">Sync parent/child taxonomy</a></li>
                    <li><a target="_top" href="/tools/pendingRelations.cfm">Pending Relationships</a></li>
                    <cfif listfind(formList,"/tools/sqlTaxonomy.cfm")>
                          <li><a target="_top" href="/tools/sqlTaxonomy.cfm">SQL Taxonomy</a></li>
                        </cfif>
                    <li><a target="_top" href="/Admin/redirect.cfm">Redirects</a></li>
                  </ul>
                    </li>
              </cfif>
                </ul>
          <li><a target="_top" href="##">Manage Arctos</a>
            <ul>
              <cfif listfind(formList,"/info/svn.cfm")>
                <li> <a target="_top" href="##">Developer Widgets</a>
                  <ul>
                    <li><a target="_top" href="/ScheduledTasks/index.cfm">Scheduled Tasks</a></li>
                    <li><a target="_top" href="/info/svn.cfm">SVN</a></li>
                    <li><a target="_top" href="/Admin/dumpAll.cfm">dump</a></li>
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
                    <li><a target="_top" href="/AdminUsers.cfm">Arctos Users</a></li>
                    <li><a target="_top" href="/Admin/user_roles.cfm">Database Roles</a></li>
                    <li><a target="_top" href="/Admin/user_report.cfm">All User Stats</a></li>
                    <li><a target="_top" href="/Admin/manage_user_loan_request.cfm">User Loan</a></li>
                  </ul>
                </li>
              </cfif>
            </ul>
          </li>
              <cfif listfind(formList,"/Admin/ActivityLog.cfm")>
            <li><a target="_top" href="##">Reports</a>
                  <ul>
                <li><a target="_top" href="/Reports/reporter.cfm">Reporter</a></li>
                <li><a target="_top" href="/info/mia_in_genbank.cfm">GenBank MIA</a></li>
                <li><a target="_top" href="/info/reviewAnnotation.cfm">Annotations</a></li>
                <li><a target="_top" href="/info/loanStats.cfm">Loan/Citation Stats</a></li>
                <li><a target="_top" href="/info/Citations.cfm">More Citation Stats</a></li>
                <li><a target="_top" href="/info/MoreCitationStats.cfm">Even More Citation Stats</a></li>
                <li><a target="_top" href="/Admin/download.cfm">Download Stats</a></li>
                <li><a target="_top" href="/info/queryStats.cfm">Query Stats</a></li>
                <li><a target="_top" href="/Admin/ActivityLog.cfm">Audit SQL</a></li>
                <li><a target="_top" href="/tools/downloadData.cfm">Download Tables</a></li>
                <li><a target="_top" href="/tools/access_report.cfm">Oracle Roles</a></li>
                <cfif listfind(formList,"/tools/userSQL.cfm")>
                      <li><a target="_top" href="/tools/userSQL.cfm">Write SQL</a></li>
                    </cfif>
                <li><a target="_top" href="##">Funky Data</a>
                      <ul>
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
                    </li>
              </ul>
                </li>
          </cfif>
            </cfif>
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
            <li><a target="_top" href="/saveSearch.cfm?action=manage">Saved Searches</a></li>
            <li><a target="_top" href="/info/api.cfm">API</a></li>
          </ul>
            </li>
        <li><a target="_top" href="##">Help</a>
              <ul>
            <cfscript>
							serverName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
						</cfscript>
            <cfif serverName contains "harvard.edu">
                  <li><a target="_blank" href="https://code.mcz.harvard.edu/wiki/index.php/Using_MCZbase">Using MCZbase</a></li>
                </cfif>
            <li><a target="_blank" href="http://arctosdb.wordpress.com">About Arctos</a></li>
          </ul>
            </li>
      </ul><!---sf-menu--->
    </div><!--- end sf-mainMenuWrapper--->


<cf_rolecheck>
</cfoutput> 
<div id="pg_container">
<div class="content_box clearfix">
