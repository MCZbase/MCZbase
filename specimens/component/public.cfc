<!---
specimens/component/public.cfc

Copyright 2021 President and Fellows of Harvard College

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
<!--- publicly available functions to support /specimens/Specimen.cfm --->
<cfcomponent>
<cf_rolecheck>
<cfinclude template = "/shared/functionLib.cfm" runOnce="true">

<!--- getIdentificationsHTML obtain a block of html listing identifications for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the identifications.
 @return html for viewing identifications for the specified cataloged item. 
--->
<cffunction name="getIdentificationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getIdentificationsThread">
		<cfoutput>
			<cftry>
				<cfquery name="identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						identification.scientific_name,
						identification.collection_object_id,
						concatidagent(identification.identification_id) agent_name,
						made_date,
						nature_of_id,
						identification_remarks,
						identification.identification_id,
						accepted_id_fg,
						taxa_formula,
						formatted_publication,
						identification.publication_id,
						stored_as_fg
					FROM
						identification,
						(select * from formatted_publication where format_style='short') formatted_publication
					WHERE
						identification.publication_id=formatted_publication.publication_id (+) and
						identification.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					ORDER BY accepted_id_fg DESC,sort_order, made_date DESC
				</cfquery>
				<cfloop query="identification">
					<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT distinct
							taxonomy.taxon_name_id,
							display_name,
							scientific_name,
							author_text,
							full_taxon_name 
						FROM 
							identification_taxonomy,
							taxonomy
						WHERE 
							identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id 
							AND identification_id = <cfqueryparam value="#identification_id#" cfsqltype="CF_SQL_DECIMAL">
					</cfquery>
					<cfif accepted_id_fg is 1>
						<ul class="list-group border-green rounded p-2 h4 font-weight-normal">
							<div class="d-inline-block mb-2 h4 text-success">Current Identification</div>
							<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
								<div class="font-italic h4 mb-1 font-weight-lessbold d-inline-block"> <a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name# </a>
								<cfif len(getTaxa.author_text) gt 0>
									<span class="sm-caps font-weight-lessbold">#getTaxa.author_text#</span>
								</cfif>
								</div>
								<cfelse>
								<cfset link="">
								<cfset i=1>
								<cfset thisSciName="#scientific_name#">
								<cfloop query="getTaxa">
									<span class="font-italic h4 font-weight-lessbold d-inline-block">
									<cfset thisLink='<a href="/name/#scientific_name#" class="d-inline" target="_blank">#display_name#</a>'>
									<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>
									<cfset i=#i#+1>
									<a href="##">#thisSciName#</a> <span class="sm-caps font-weight-lessbold">#getTaxa.author_text#</span> </span>
								</cfloop>
							</cfif>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<cfif stored_as_fg is 1>
									<span class="bg-gray float-right rounded p-1">STORED AS</span>
								</cfif>
							</cfif>
							<cfif not isdefined("metaDesc")>
								<cfset metaDesc="">
							</cfif>
							<cfloop query="getTaxa">
								<div class="h5 mb-1 text-dark font-italic"> #full_taxon_name# </div>
								<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
								<cfquery name="cName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										common_name 
									FROM 
										common_name
									WHERE 
										taxon_name_id= <cfqueryparam value="#taxon_name_id#" cfsqltype="CF_SQL_DECIMAL"> 
										and common_name is not null
									GROUP BY 
										common_name order by common_name
								</cfquery>
								<cfif len(cName.common_name) gt 0><div class="h5 mb-1 text-muted font-weight-normal pl-3">Common Name(s): #valuelist(cName.common_name,"; ")# </div></cfif>
								<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")><!---  common name for current id--->
							</cfloop>
							<div class="form-row mx-0">
								<div class="small mr-2"><span class="h5">Determiner:</span> #agent_name#
									<cfif len(made_date) gt 0>
										<span class="h5">on Date:</span> #dateformat(made_date,"yyyy-mm-dd")#
									</cfif>
								</div>
							</div>
							<div class="small mr-2"><span class="h5">Nature of ID:</span> #nature_of_id# </div>
							<cfif len(identification_remarks) gt 0>
								<div class="small"><span class="h5">Remarks:</span> #identification_remarks#</div>
							</cfif>
						</ul>	
						<cfelse><!---Start of former Identifications--->
							<cfif getTaxa.recordcount gt 0>		
								<div class="h4 pl-4 mt-1 mb-0 text-success">Former Identifications</div>
							</cfif><!---Add Title for former identifications--->
						<ul class="list-group py-1 px-3 ml-2 text-dark bg-light">
						<li class="px-0">
						<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
							<span class="font-italic h4 font-weight-normal"><a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name#</a></span><!---identification  for former names when there is no author--->
							<cfif len(getTaxa.author_text) gt 0>
								<span class="color-black sm-caps">#getTaxa.author_text#</span><!---author text for former names--->
							</cfif>
							<cfelse>
							<cfset link="">
							<cfset i=1>
							<cfset thisSciName="#scientific_name#">
							<cfloop query="getTaxa">
								<cfset thisLink='<a href="/name/#scientific_name#" target="_blank">#display_name#</a>'>
								<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>
								<cfset i=#i#+1>
							</cfloop>
							#thisSciName# <!---identification for former names when there is an author--it put the sci name with the author--->
						</cfif>
						<cfif listcontainsnocase(session.roles,"manage_specimens")>
							<cfif stored_as_fg is 1>
								<span style="float-right rounded p-1 bg-light">STORED AS</span>
							</cfif>
						</cfif>
						<cfif not isdefined("metaDesc")>
							<cfset metaDesc="">
						</cfif>
						<cfloop query="getTaxa">
							<!--- TODO: We loop through getTaxa results three times, and query for common names twice?????  Construction here needs review.  --->
							<p class="small text-muted mb-0"> #full_taxon_name#</p><!--- full taxon name for former id--->
							<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
							<cfquery name="cName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										common_name 
									FROM 
										common_name
									WHERE 
										taxon_name_id= <cfqueryparam value="#taxon_name_id#" cfsqltype="CF_SQL_DECIMAL"> 
										and common_name is not null
									GROUP BY 
										common_name order by common_name
							</cfquery>
							<cfif len(cName.common_name) gt 0><div class="small text-muted pl-3">Common Name(s): #valuelist(cName.common_name,"; ")#</div>
							<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")></cfif><!---  common name for former id--->
						</cfloop>
						<cfif len(formatted_publication) gt 0>
							sensu <a href="/publication/#publication_id#" target="_mainFrame"> #formatted_publication# </a><!---  Don't think this is used--->
						</cfif>
						<span class="small">Determination: #agent_name#
							<cfif len(made_date) gt 0>
								on #dateformat(made_date,"yyyy-mm-dd")#
							</cfif>
							<span class="d-block">Nature of ID: #nature_of_id#</span> 
						<cfif len(identification_remarks) gt 0>
							<span class="d-block">Remarks: #identification_remarks#</span>
						</cfif>
					</cfif>
					</li>
					</ul>
				</cfloop>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>

	<cfthread action="join" name="getIdentificationsThread" />
	<cfreturn getIdentificationsThread.output>
</cffunction>

<!--- getOtherIdsHTML obtain a block of html listing other id numbers for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the other id numbers
 @return html for viewing identifications for the specified cataloged item. 
--->
<cffunction name="getOtherIDsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getOtherIDsThread">
		<cfoutput>
			<cftry>
			<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						coll_obj_other_id_num.other_id_type,
						coll_obj_other_id_num.display_value
				
					FROM
						coll_obj_other_id_num 
					where
						coll_obj_other_id_num.collection_object_id= <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					ORDER BY
						coll_obj_other_id_num.other_id_type,
						coll_obj_other_id_num.display_value
				</cfquery>
				<cfif len(oid.other_id_type) gt 0>
					<ul class="list-group">
						<cfloop query="oid">
							<li class="list-group-item">#other_id_type#:
								<cfif len(link) gt 0>
									<a class="external" href="##" target="_blank">#display_value#</a>
									<cfelse>
									#display_value#
								</cfif>
							</li>
						</cfloop>
					</ul>
				</cfif>
				<cfcatch>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>

	<cfthread action="join" name="getOtherIDsThread" />
	<cfreturn getOtherIDsThread.output>
</cffunction>

</cfcomponent>
