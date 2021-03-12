<cfcomponent>
<cf_rolecheck>
<cfinclude template = "/shared/functionLib.cfm">

<cffunction name="getExternalStatus" access="remote">
	<cfargument name="uri" type="string" required="yes">

	<cfhttp url="#uri#" method="head"></cfhttp>
	<cfreturn left(cfhttp.statuscode,3)>
</cffunction>

<!--- updateCondition update the condition on a part identified by the part's collection object id 
 @param part_id the collection_object_id for the part to update
 @param condition the new condition to update the part to 
 @return a json structure containing the part_id and a message, with "success" as the value of the message on a successful update.
--->
<cffunction name="updateCondition" access="remote" returntype="query">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update coll_object 
				set
					condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#condition#">
				where
					COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<cffunction name="getIdentifications" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 1 as status, identification_id, collection_object_id, nature_of_id, accepted_id_fg,
				identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
			from identification
			where identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No identifications found.", 1)>
		</cfif>
	<cfcatch>
		<cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>

<!--- getEditIdentificationsHTML obtain a block of html to populate an identification edtior dialog for a specimen.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the identification
	editor dialog.
 @return html for editing identifications for the specified cataloged item. 
--->
<cffunction name="getEditIdentificationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditIdentsThread">
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
					<!--- TODO: editable form ---> 
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
							<cfif oneOfUs is 1 and stored_as_fg is 1>
								<span class="bg-gray float-right rounded p-1">STORED AS</span>
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
						<cfif oneOfUs is 1 and stored_as_fg is 1>
							<span style="float-right rounded p-1 bg-light">STORED AS</span>
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

	<cfthread action="join" name="getEditIdentsThread" />
	<cfreturn getEditIdentsThread.output>
</cffunction>

<!--- getIdentificationsHTML obtain a block of html listing identifications for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the identification
	editor dialog.
 @return html for viewing identifications for the specified cataloged item. 
--->
<cffunction name="getIdentificationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getIdentificationsThread">
		<cfoutput>
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
						<cfif oneOfUs is 1 and stored_as_fg is 1>
							<span class="bg-gray float-right rounded p-1">STORED AS</span>
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
					<cfif oneOfUs is 1 and stored_as_fg is 1>
						<span style="float-right rounded p-1 bg-light">STORED AS</span>
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
		</cfoutput>
	</cfthread>

	<cfthread action="join" name="getIdentificationsThread" />
	<cfreturn getIdentificationsThread.output>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!--- function getIdentificationHtml obtain an html block to popluate an edit dialog for an identification 
 @param identification-id the identification.identification_id to edit.
 @return html for editing the identification 
--->
<cffunction name="getIdentificationHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="identification_id" type="string" required="yes">

	<cfthread name="getIdentificationThread">
		<cftry>
			<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 1 as status, identification.identification_id, identification.collection_object_id, 
					identification.scientific_name, identification.made_date, identification.nature_of_id, 
					identification.stored_as_fg, identification.identification_remarks, identification.accepted_id_fg, 
					identification.taxa_formula, identification.sort_order, taxonomy.full_taxon_name, taxonomy.author_text, 
					identification_agent.agent_id, concatidagent(identification.identification_id) agent_name
				FROM 
					identification
					left join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id 
					left join taxonomy on identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id and 
					left join identification_agent on identification_agent.identification_id = identification.identification_id and
				WHERE 	
					identification.identification_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
				ORDER BY 
					made_date
			</cfquery>
			<cfoutput>
				<div id="identificationHTML">
					<cfloop query="theResult">
						<div class="identifcationExistingForm">
							<form>
								<div class="container pl-1">
									<div class="col-md-6 col-sm-12 float-left">
										<div class="form-group">
											<label for="scientific_name">Scientific Name:</label>
											<input type="text" name="taxona" id="taxona" class="reqdClr form-control form-control-sm" value="#scientific_name#" size="1" 
												onChange="taxaPick('taxona_id','taxona','newID',this.value); return false;"
												onKeyPress="return noenter(event);">
											<input type="hidden" name="taxona_id" id=taxona_id" class="reqdClr">
										</div>
										<div class="form-group w-25 mb-3 float-left">
											<label for="taxa_formula">Formula:</label>
											<select class="border custom-select form-control input-sm" id="select">
												<option value="" disabled="" selected="">#taxa_formula#</option>
												<!--- TODO: Shouldn't this be from a code table? --->
												<option value="A">A</option>
												<option value="B">B</option>
												<option value="sp.">sp.</option>
											</select>
										</div>
										<div class="form-group w-50 mb-3 ml-3 float-left">
											<label for="made_date">Made Date:</label>
											<input type="text" class="form-control ml-0 input-sm" id="made_date" value="#dateformat(made_date,'yyyy-mm-dd')#&nbsp;">
										</div>
									</div>
									<div class="col-md-6 col-sm-12 float-left">
										<div class="form-group">
											<!--- TODO: Fix this, should be an agent picker --->
											<label for="determinedby">Determined By:</label>
											<input type="text" class="form-control-sm" id="determinedby" value="#agent_name#">
										</div>
										<div class="form-group">
											<label for="nature_of_id">Nature of ID:</label>
											<select name="nature_of_id" id="nature_of_id" size="1" class="reqdClr custom-select form-control">
												<option value="#nature_of_id#">#nature_of_id#</option>
												<!--- TODO: Wrong query name, should reference a code table query. --->
												<cfloop query="theResult">
													<option value="theResult.nature_of_id">#nature_of_id#</option>
												</cfloop>
											</select>
										</div>
									</div>
									<div class="col-md-12 col-sm-12 float-left">
										<div class="form-group">
											<label for="full_taxon_name">Full Taxon Name:</label>
											<input type="text" class="form-control-sm" id="full_taxon_name" value="#full_taxon_name#">
										</div>
										<div class="form-group">
											<label for="identification_remarks">Identification Remarks:</label>
											<textarea type="text" class="form-control" id="identification_remarks" value="#identification_remarks#"></textarea>
										</div>
										<div class="form-check">
											<input type="checkbox" class="form-check-input" id="materialUnchecked">
											<label class="mt-2 form-check-label" for="materialUnchecked">Stored as #scientific_name#</label>
										</div>
										<div class="form-group float-right">
											<button type="button" value="Create New Identification" class="btn btn-primary ml-2"
												 onClick="$('.dialog').dialog('open'); loadNewIdentificationForm(identification_id,'newIdentificationForm');">Create New Identification</button>
										</div>
									</div>
								</div>
							</form>
						</div>
			 		</cfloop> <!--- theResult --->
				</div>
			</cfoutput>
		<cfcatch>
			<cfoutput>
				<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>

	<cfthread action="join" name="getIdentificationThread" />
	<cfreturn getIdentificationThread.output>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getIdentificationTable" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
	    <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
   			select 1 as status, identifications_id, collection_object_id, made_date, nature_of_id, accepted_id_fg,identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
            from identification
            where identification_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
	  	  <cfset theResult=queryNew("status, message")>
		  <cfset t = queryaddrow(theResult,1)>
		  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
	<cfcatch>
	  <cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
    <cfif isDefined("asTable") AND asTable eq "true">
	    <cfreturn resulthtml>
    <cfelse>
   	    <cfreturn theResult>
    </cfif>
</cffunction>

<cffunction name="loadLocality" returntype="query" access="remote">
	<cfargument name="locality_id" type="string" required="yes">
	<cftry>
		<cfquery name="theResults" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		   select 1 as status, locality_id, geog_auth_rec_id, spec_locality
             from locality
             where locality_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		</cfquery>
		<cfif theResults.recordcount eq 0>
	  	  <cfset theResults=queryNew("status, message")>
		  <cfset t = queryaddrow(theResults,1)>
		  <cfset t = QuerySetCell(theResults, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResults, "message", "No localities found.", 1)>
		</cfif>
	  <cfcatch>
	   	<cfset theResults=queryNew("status, message")>
		<cfset t = queryaddrow(theResults,1)>
		<cfset t = QuerySetCell(theResults, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResults, "message", "#cfcatch.type# hi #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
	<cfreturn theResults>
</cffunction>
			
<cffunction name="getLocalityHTML" returntype="string" access="remote" returnformat="plain">
   <cfargument name="locality_id" type="string" required="yes">
   <cfset r=1>
   <cfthread name="getLocalityThread">
   <cftry>
    <cfquery name="theResults" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select 1 as status, locality.spec_locality, locality.geog_auth_rec_id, collecting_event.collecting_event_id, collecting_event.verbatim_locality, collecting_event.began_date, collecting_event.ended_date, collecting_event.collecting_source 
		from locality, collecting_event, geog_auth_rec 
		where locality.geog_auth_rec_id= geog_auth_rec.geog_auth_rec_id
		and collecting_event.locality_id = locality.locality_id
		and locality.locality_id = <cfqueryparam value="#locality_id#" cfsqltype="CF_SQL_DECIMAL">
	</cfquery>

      <cfset resulthtml1 = "<div id='localityHTML'> ">

      <cfloop query="theResults">
         <cfset resulthtml1 = resulthtml1 & "<div class='localityExistingForm'>">
            <cfset resulthtml1 = resulthtml1 & "<form><div class='container pl-1'>">
			<cfset resulthtml1 = resulthtml1 & "<div class='col-md-6 col-sm-12 float-left'>">
			<cfset resulthtml1 = resulthtml1 & "<div class='form-group'><label for='spec_locality' class='data-entry-label mb-0'>Specific Locality</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='spec_locality' class='data-entry-input' value='#spec_locality#'></div>">
			<cfset resulthtml1 = resulthtml1 & "<div class='form-row form-group'><label for='verbatim_locality' class='data-entry-label mb-0'>Verbatim Locality</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='verbatim_locality' class='data-entry-input' value='#verbatim_locality#'></div></div>">
			<cfset resulthtml1 = resulthtml1 & "<div class='col-md-6 col-sm-12 float-left'><label for='collecting_source' class='data-entry-label mb-0'>Collecting Source</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='collecting_source' class='data-entry-input' value='#collecting_source#'>">
			<cfset resulthtml1 = resulthtml1 & "<label for='began_date' class='data-entry-label mb-0'>Began Date</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='began_date' class='data-entry-input' value='#began_date#'>">
			<cfset resulthtml1 = resulthtml1 & "<label for='ended_date' class='data-entry-label mb-0'>End Date</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='ended_date' class='data-entry-input' value='#ended_date#'></div>">
		
			<cfset resulthtml1 = resulthtml1 & "</div></div></form>">
       
				<cfset resulthtml1 = resulthtml1 & "</div></div>"> 
      </cfloop> <!--- theResult --->

   <cfcatch>
       <cfset resulthtml1 = resulthtml1 & "Error:" & "#cfcatch.type# #cfcatch.message# #cfcatch.detail#">
   </cfcatch>
   </cftry>
     <cfoutput>#resulthtml1#</cfoutput>
   </cfthread>
    <cfthread action="join" name="getLocalityThread" />
    <cfreturn getLocalityThread.output>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getPartName" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

   <cftry>
      <cfset rows = 0>
      <cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select a.part_name
			from (
				select part_name, partname
				from ctspecimen_part_name, ctspecimen_part_list_order
				where ctspecimen_part_name.part_name =  ctspecimen_part_list_order.partname (+)
					and upper(part_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
				) a
			group by a.part_name, a.partname
			order by a.partname asc, a.part_name
      </cfquery>
   <cfset rows = search_result.recordcount>
      <cfset i = 1>
      <cfloop query="search">
         <cfset row = StructNew()>
         <cfset row["id"] = "#search.part_name#">
         <cfset row["value"] = "#search.part_name#" >
         <cfset data[i]  = row>
         <cfset i = i + 1>
      </cfloop>
      <cfreturn #serializeJSON(data)#>
   <cfcatch>
      <cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
      <cfset message = trim("Error processing getAgentPartName: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
      <cfheader statusCode="500" statusText="#message#">
         <cfoutput>
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
         </cfoutput>
      <cfabort>
   </cfcatch>
   </cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getMediaForPublication" returntype="string" access="remote" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getMediaForCitPub">
		<cfquery name="query"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				mr.media_id, m.media_uri, m.preview_uri, ml.label_value descr, m.media_type, m.mime_type
			FROM
				media_relations mr, media_labels ml, media m, citation c, formatted_publication fp
			WHERE
				mr.media_id = ml.media_id and
				mr.media_id = m.media_id and
				ml.media_label = 'description' and
				MEDIA_RELATIONSHIP like '% publication' and
				RELATED_PRIMARY_KEY = c.publication_id and
				c.publication_id = fp.publication_id and
				fp.format_style='short' and
				c.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			ORDER by substr(formatted_publication, -4)
		</cfquery>
		<cfoutput>
		<div class='Media1'>
				<span class="pb-2">
					<cfloop query="query">
						<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select media.media_id, media_uri, preview_uri, media_type, mczbase.get_media_descriptor(media.media_id) as media_descriptor
							from media_relations left join media on media_relations.media_id = media.media_id
							where media_relations.media_relationship = '%publication'
								and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#publication_id#>
						</cfquery>
						<cfset mediaLink = "&##8855;">
						<cfloop query="mediaQuery">
							<cfset puri=getMediaPreview(preview_uri,media_type) >
							<cfif puri EQ "/images/noThumb.jpg">
								<cfset altText = "Red X in a red square, with text, no preview image available">
							<cfelse>
								<cfset altText = mediaQuery.media_descriptor>
							</cfif>
							<cfset mediaLink = "<a href='#media_uri#'target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15' alt='#altText#'></a>" >
						</cfloop>
						<ul class='list-style-disc pl-4 pr-0'>
							<li class="my-1">
								#formatted_publication# 
								
							</li>
						</ul>
					</cfloop>
					<cfif query.recordcount eq 0>
				 		None
					</cfif>
				</span>
			</div> <!---  --->
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getMediaForCitPub" />
	<cfreturn getMediaForCitPub.output>
</cffunction>

</cfcomponent>
