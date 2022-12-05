<!--- /publications/component/functions.cfc

Backing methods to support editing publication records.

Copyright 2022 President and Fellows of Harvard College

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
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/media/component/search.cfc" runOnce="true"> <!--- getMediaBlockHtml --->
<cf_rolecheck>

<!--- getCitationForPubHtml get the long or short form of the citation for a publication record.
  @param publication_id the publication for which to obtain the citaiton.
  @param form optional 'long', 'plain' or 'short', default 'long' for the form of the citation to return.
  @return html containing the citation in the requested form with html markup.
--->
<cffunction name="getCitationForPubHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="form" type="string" required="no">
	<cfif NOT isDefined("form") OR len(form) EQ 0>
		<cfset form="long">
	</cfif>

	<cftry>
		<cfoutput>
			<cfquery name="getCitation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getCitation_result">
				SELECT
					<cfif form EQ "short">
						mczbase.getshortcitation(publication_id) as citation
					<cfelseif form EQ "plain">
						mczbase.assemble_fullcitation(publication_id,0) as citation
					<cfelse>
						mczbase.getfullcitation(publication_id) as citation
					</cfif>
				FROM publication
				WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfif getCitation.recordcount EQ 0>
				<cfthrow message="No matching records in the formatted publication table.">
			</cfif>
			<cfloop query="getCitation">
				#getCitation.citation#
			</cfloop>
		</cfoutput>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfoutput>
			<h2 class="h3">Error in #function_called#:</h2>
			<div>#error_message#</div>
		</cfoutput>
	</cfcatch>
	</cftry>
</cffunction>

<!--- savePublication update a publication record --->
<cffunction name="savePublication" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="published_year" type="string" required="no">
	<cfargument name="publication_type" type="string" required="yes">
	<cfargument name="publication_title" type="string" required="yes">
	<cfargument name="publication_remarks" type="string" required="yes">
	<cfargument name="is_peer_reviewed_fg" type="string" required="yes">
	<cfargument name="doi" type="string" required="yes">
	<cfargument name="publication_loc" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
  			<cfif len(doi) gt 0>
				<cfinvoke component="/component/functions" method="checkDOI" returnVariable="isok">
					<cfinvokeargument name="doi" value="#doi#">
				</cfinvoke>
				<cfif isok is not "true">
					<cfthrow message = "DOI #doi# failed validation with StatusCode #isok#">
				</cfif>
			</cfif>
			<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE publication 
				SET
					published_year=
						<cfif isDefined("published_year") AND len(published_year) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_" value="#published_year#">,
						<cfelse>
							NULL,
						</cfif>
					publication_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_type#">,
					publication_loc=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_loc#">,
					publication_title=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_title#">,
					publication_remarks=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_remarks#">,
					is_peer_reviewed_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#is_peer_reviewed_fg#">,
					doi = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#doi#">
				WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#publication_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- lookup potential DOI matches in crossref ---> 
<cffunction name="crossRefLookup" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
	
	<cfset data = ArrayNew(1)>
	<!--- find email for current user to include in crossref as pid --->
	<cfquery name="getEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select email from cf_user_data,cf_users
		where cf_user_data.user_id = cf_users.user_id and
		cf_users.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>

	<!--- obtain data on publication to put into url for crossref --->
	<cfquery name="getPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT
			publication_title,
			published_year as year,
			get_publication_attribute(publication_id,'begin page') as spage,
			get_publication_attribute(publication_id,'journal name') as jtitle,
			get_publication_attribute(publication_id,'volume') as volume,
			get_publication_attribute(publication_id,'issue') as issue
		FROM
			publication
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="getAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT person.last_name as aulast
		FROM
			publication_author_name p
			join agent_name an on p.agent_name_id = an.agent_name_id
			join person on an.agent_id = person.person_id
		WHERE
			p.author_role = 'author' and p.author_position = 1 and
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	
	<!--- make request to crossref --->
	<!--- crossref metadata lookup resources: https://www.crossref.org/services/metadata-retrieval/#00356 --->

	<!--- crossref OpenURL documentation: https://www.crossref.org/documentation/retrieve-metadata/openurl/ --->
	<!--- example:
		https://www.crossref.org/openurl?pid=bdim@oeb.harvard.edu&title=Journal%20of%20Paleontology&aulast=Hodnett&date=2018&spage=1&redirect=false&multihit=true
	--->

	<cfset query = "">
	<cfif getPub.recordcount GT 0>
		<cfif len(getPub.jtitle) GT 0>
			<cfset query="&title=#getPub.jtitle#">
		<cfelse>
			<cfif len(getPub.publication_title) GT 0>
				<cfset query="&stitle=#getPub.publication_title#">
			</cfif>
		</cfif>
		<cfif len(getPub.spage) GT 0 >
			<cfset query="#query#&spage=#getPub.spage#">
		</cfif>
		<cfif len(getPub.year) GT 0 >
			<cfset query="#query#&date=#getPub.year#">
		</cfif>
		<cfif len(getPub.volume) GT 0 >
			<cfset query="#query#&volume=#getPub.volume#">
		</cfif>
		<cfif len(getPub.issue) GT 0 >
			<cfset query="#query#&issue=#getPub.issue#">
		</cfif>
	</cfif>
	<cfif getAuthor.recordcount GT 0>
		<cfif len(getAuthor.aulast) GT 0 >
			<cfset query="#query#&aulast=#getAuthor.aulast#">
		</cfif>
	</cfif>

	<cfif len(query) GT 0>
		<cfset lookupURI="https://www.crossref.org/openurl?pid=#getEmail.email#&#query#&redirect=false&multihit=true">
	<cfelse>
		<cfthrow message="nothing found to look up.">
	</cfif>

	<cfhttp url="#lookupURI#"></cfhttp>
	<!--- parse returned xml --->
	<cfset xmlReturn = cfhttp.filecontent>
	<!--- return results --->
	<cfset return = xmlParse(xmlReturn)>
	<cfset body = return.crossref_result.query_result.body >
	<cfif arrayLen(body) EQ 1>
		<cftry>
			<cfset doi = return.crossref_result.query_result.body.query.doi.XmlText>
			<cfset row = StructNew()>
			<cfset row["match"] = "1">
			<cfset row["doi"] = "#doi#">
			<cfset data[1] = row>
		<cfcatch>
   		<cfset status = return.crossref_result.query_result.body.query.XMLAttributes.status >
			<cfif status EQ "unresolved">
				<cfthrow message = "No matches found">
			</cfif>
			<cfdump var="#return#">
		</cfcatch>
		</cftry>
	<cfelseif arrayLen(body) GT 1>
		<!--- TODO: Handle multiple possible matches --->
		<cfdump var="#return#">
	<cfelse>
		<cfset row = StructNew()>
		<cfset row["match"] = "0">
		<cfset row["doi"] = "">
		<cfset data[1] = row>
	</cfif>

	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="addMedia" access="remote" returntype="any" returnformat="json">
<!---------------------------------------------------------------------------------------------------------->
		<cfif len(media_uri) gt 0>
			<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_media_id.nextval nv from dual
			</cfquery>
			<cfset media_id=mid.nv>
			<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media 
					(media_id,media_uri,mime_type,media_type,preview_uri)
	            values 
					(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_uri#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#">)
			</cfquery>
			<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media_relations (
					media_id,
					media_relationship,
					related_primary_key
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					'shows publication',
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				)
			</cfquery>
			<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media_labels (
					media_id,
					media_label,
					label_value)
				values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					'description',
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_desc#">)
			</cfquery>
		</cfif>
</cffunction>


<!--- getAuthorsForPubHtml obtain a block of html for editing the authors and editors
   of a publication 
 @param publication_id the publication for which to obtain authors/editors
 @return html listing authors and editors for the specified publication in a form for editing
---->
<cffunction name="getAuthorsForPubHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getAuthorsForPubThread">

		<cftry>
			<cfquery name="getAuthorsEditors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAuthorsEditors_result">
				SELECT
					publication_author_name.PUBLICATION_AUTHOR_NAME_ID PUBLICATION_AUTHOR_NAME_ID,
					publication_author_name.AGENT_NAME_ID AGENT_NAME_ID,
					publication_author_name.AUTHOR_POSITION AUTHOR_POSITION,
					publication_author_name.AUTHOR_ROLE AUTHOR_ROLE,
					agent_name.AGENT_ID AGENT_ID,
					agent_name.AGENT_NAME_TYPE AGENT_NAME_TYPE,
					agent_name.AGENT_NAME AGENT_NAME
				FROM publication_author_name
					join agent_name on publication_author_name.agent_name_id=agent_name.agent_name_id 
				WHERE
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				ORDER BY author_role, author_position
			</cfquery>
			<cfquery name="getAuthors" dbtype="query">
				SELECT *
				FROM getAuthorsEditors
				WHERE 
					author_role = 'author'
			</cfquery>
			<cfquery name="getEditors" dbtype="query">
				SELECT *
				FROM getAuthorsEditors
				WHERE 
					author_role = 'editor'
			</cfquery>
			<cfoutput>
				<div class="col-12 col-md-6">
					<h2 class="h3" >Authors</h2> 
					<button class="btn btn-xs btn-primary" onclick=" openAddAuthorEditorDialog('addAuthorEditorDialogDiv', '#publication_id#', 'authors', reloadAuthors); ">Add Authors</button>
					<ol>
						<cfloop query="getAuthors">
							<li value="#author_position#">
								<a href="/agents/Agent.cfm?agent_id=#agent_id#" target="_blank">#agent_name#</a> 
								<!--- TODO: Edit --->
								<!--- TODO: move --->
								<button type="button" 
									onClick="  confirmDialog('Remove Author #agent_name#?','Remove?', function() {removeAuthor('#publication_author_name_id#',reloadAuthors);} );"
									arial-label='remove this author from this publication' 
									class='btn btn-xs btn-warning' >Remove</button>
							</li>
						</cfloop>
					</ul>
				</div>
				<div class="col-12 col-md-6">
					<h3 class="h4" >Editors</h3> 
					<button class="btn btn-xs btn-primary" onclick=" openAddAuthorEditorDialog('addAuthorEditorDialogDiv', '#publication_id#', 'editors', reloadAuthors); ">Add Editors</button>
					<ol>
						<cfloop query="getEditors">
							<li value="#author_position#">
								<a href="/agents/Agent.cfm?agent_id=#agent_id#" target="_blank">#agent_name#</a> 
								<!--- TODO: Edit --->
								<!--- TODO: move --->
								<button type="button" 
									onClick="  confirmDialog('Remove Editor #agent_name#?','Remove?', function() {removeAuthor('#publication_author_name_id#',reloadAuthors);} );"
									arial-label='remove this editor from this publication' 
									class='btn btn-xs btn-warning' >Remove</button>
							</li>
						</cfloop>
					</ul>
				</div>
				<div id="addAuthorEditorDialogDiv"></div>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAuthorsForPubThread" />
	<cfreturn getAuthorsForPubThread.output>
</cffunction>

<!--- addAuthorEditorHtml obtain a block of html to populate a dialog for adding an author or editor to a publication
 @param publication_id the publication for which to obtain authors/editors.
 @param role the role in which to add new agents, allowed values authors or editors.
 @return html form for a dialog to add authors/editors to a publication.
---->
<cffunction name="addAuthorEditorHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="role" type="string" required="yes">
	<cfset variables.publication_id = arguments.publication_id>
	<cfset variables.role = arguments.role>
	<cfthread name="getAuthorEditorHtmlThread">

		<cftry>
			<cfif role EQ "authors">
				<cfset roleLabel = "Author">
			<cfelseif role EQ "editors">
				<cfset roleLabel = "Editor">
			<cfelse>
				<cfthrow message="Add Author or Editor Dialog must be created with role='authors' or role='editors'. [#encodeForHtml(role)#] is not an acceptable value.">
			</cfif>
			<!--- ordinal position is a single counter, applied to both editors and authors --->
			<cfquery name="getMaxPosition" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getMaxPosition_result">
				SELECT
					max(author_position) max_position
				FROM publication_author_name
				WHERE
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfquery name="getAuthorsEditors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAuthorsEditors_result">
				SELECT
					publication_author_name.PUBLICATION_AUTHOR_NAME_ID PUBLICATION_AUTHOR_NAME_ID,
					publication_author_name.AGENT_NAME_ID AGENT_NAME_ID,
					publication_author_name.AUTHOR_POSITION AUTHOR_POSITION,
					publication_author_name.AUTHOR_ROLE AUTHOR_ROLE,
					agent_name.AGENT_ID AGENT_ID,
					agent_name.AGENT_NAME_TYPE AGENT_NAME_TYPE,
					agent_name.AGENT_NAME AGENT_NAME
				FROM publication_author_name
					join agent_name on publication_author_name.agent_name_id=agent_name.agent_name_id 
				WHERE
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					<cfif role EQ "authors">
						and author_role = 'author'
					<cfelseif role EQ "editors">
						and author_role = 'editor'
					</cfif>
				ORDER BY author_position asc
			</cfquery>
			<cfset minpositionfortype = 0>
			<cfloop query="getAuthorsEditors">
				<cfif minpositionfortype EQ 0>
					<cfset minpositionfortype=author_position>
				</cfif>
			</cfloop>
			<cfset maxposition = 0>
			<cfloop query="getMaxPosition">
				<cfset maxposition=max_position>
			</cfloop>
			<cfif maxposition EQ minpositionfortype>
				<cfset newpos=1>
				<cfset nameform="author">
			<cfelse>
				<cfset newpos=2>
				<cfset nameform="second author">
			</cfif>
			<cfoutput>
				<div class="form-row">
					<div class="col-12">
						<h3 class="h4" >Add #roleLabel#</h3>
						<!--- TODO: Add UI elements to add a first/second author form of name if one is not present for selected agent --->
						<div class="form-row">
							<div class="col-12 col-md-6">
								<label for="agent_name" class="data-entry-label">Pick an agent to add as an #roleLabel#</label>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="agent_name" id="agent_name" class="form-control rounded-right data-entry-input form-control-sm reqdClr" aria-label="Agent Name" aria-describedby="agent_name_label" value="" required>
									<input type="hidden" name="agent_id" id="agent_id" value="">
								</div>
							</div>
							<div class="col-12 col-md-3">
								<label for="agent_view" class="data-entry-label">Selected Agent</label>
								<div id="agent_view"></div>
							</div>
							<div class="col-12 col-md-3">
								<label for="agent_name_control" class="data-entry-label">#roleLabel#</label>
								<div id="author_name_control"></div>
								<input type="hidden" name="author_name_id" id="author_name_id" value="">
								<input type="hidden" name="next_author_position" id="next_author_position" value="#maxposition+1#">
							</div>
						</div>
						<div class="form-row">
							<div class="col-12 col-md-3">
								<button class="btn btn-xs btn-primary disabled" id="addButton" onclick="addAuthor($('##author_name_id').val(),'#publication_id#',$('##next_author_position').val(),'#role#',reloadAuthors);" disabled >Add as #roleLabel# <span id="position_to_add_span">#maxposition+1#</span></button>
							</div>
							<div class="col-12 col-md-3" id="missingNameDiv">
								Missing the <span id="form_to_add_span">#nameform#</span> form of the author name for this agent.
								<button class="btn btn-xs btn-primary disabled" id="addNameButton" onclick="showAddAuthorNameDialog();" disabled >Add</button>
							</div>
							<!--- TODO: Add UI elements to add a new agent with author names if no matches --->
							<script>
								$(document).ready(function() {
									$('##missingNameDiv').hide();
								});
								function showAddAuthorNameDialog() {
									console.log($('##agent_id').val());
									console.log($('##next_author_position').val()); 
									openAddAgentNameOfTypeDialog('addNameTypeDialogDiv', $('##agent_id').val(), $('##form_to_add_span').html());
								};
							</script>
							<div id="addNameTypeDialogDiv"></div>
						<script>
							<!--- TODO: Refactor to inclulde first/second author name forms as appropriate.  --->
							$(document).ready(function() {
								makeRichAuthorPicker('agent_name', 'agent_id', 'agent_name_icon', 'agent_view', null, 'author_name_control','author_name_id',$('##next_author_position').val());
							});
						</script>
					</div>
					<div class="col-12" id="listOfAuthorsDiv">
						<ol id="authorListOnDialog">
							<cfloop query="getAuthorsEditors">
								<li>#getAuthorsEditors.agent_name#</li>
							</cfloop>
						</ol>
					</div>
					<!--- TODO: Save and continue button, handling switch from first author to second author if first was added --->
				</div>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAuthorEditorHtmlThread" />
	<cfreturn getAuthorEditorHtmlThread.output>
</cffunction>

<cffunction name="addAgentNameOfTypeHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="agent_name_type" type="string" required="yes">
	<cfset variables.agent_id = arguments.agent_id>
	<cfset variables.agent_name_type = arguments.agent_name_type>
	<cfthread name="addAgentNameOfTypeHtmlThread">
		<cftry>
			<cfquery name="ctNameType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					agent_name_type name_type
				FROM ctagent_name_type 
				WHERE agent_name_type != 'preferred' order by agent_name_type
			</cfquery>
			<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAgent_result">
				SELECT 
					MCZBASE.get_agentnameoftype(agent_id) name,
					agent_id
				FROM agent
				WHERE
					agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
			<cfoutput>
				<div class="form-row">
					<div class="col-12">
						<h3 class="h4" >Add Name to Agent #getAgent.name#</h3>
						<div class="form-row">
							<div class="col-12 col-md-6">
								<label for="agent_name_type" class="data-entry-label">Type of Name</label>
								<select name="agent_name_type" id="agent_name_type" size="1" class="data-entry-select reqdClr" required>
									<cfloop query="ctNameType">
										<cfif variables.agent_name_type IS ctNameType.name_type>
											<cfset selected = "selected='selected'">
										<cfelse>
											<cfset selected = "">
										</cfif>
										<option value="#ctNameType.name_type#" #selected#>#ctNameType.name_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-6">
								<label for="agent_name" class="data-entry-label">Name</label>
								<input name="agent_name" id="agent_name" value="" class="data-entry-input reqdClr" required>
							</div>
							<div class="col-12 col-md-6">
								<button type="button" onclick="addNameAction();" class="btn btn-xs btn-primary">Add</button>
								<script>
									function addNameAction() { 
										addAuthorName('#getAgent.agent_id#',$('##agent_name_type').val(),$('##agent_name').val(),'agent_name_id');
									};
								</script>
								<input type="hidden" id="added_agent_name_id" value="">
							</div>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="addAgentNameOfTypeHtmlThread" />
	<cfreturn addAgentNameOfTypeHtmlThread.output>
</cffunction>


<!--- addAuthor add a publication_author_name record linking a publication to an
  agent in the role of author or editor.
  @param publication_id the publication to which to add the author/editor.
  @param agent_name_id the agent name of the agent to add as the author/editor
  @param author_position the ordinal position of the author/editor in the list 
   of authors or of editors.
  @param author_role role of the agent either author or editor.
  @return a structure with status=added, id=publication_author_name_id
    or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="addAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="agent_name_id" type="string" required="yes">
	<cfargument name="author_position" type="string" required="yes">
	<cfargument name="author_role" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cfif lcase(author_role) EQ "authors">
			<cfset author_role = "author">
		<cfelseif lcase(author_role) EQ "editors">
			<cfset author_role = "editor">
		</cfif>
		<cftry>
			<cfquery name="insertAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertAuthor_result">
				INSERT INTO publication_author_name (
					publication_id,
					agent_name_id,
					author_position,
					author_role
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#author_position#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#author_role#">
				)
			</cfquery>
			<cfif insertAuthor_result.recordcount eq 0>
				<cfthrow message="Failed to properly insert new publication_author_name record">
			</cfif>
			<cfset rowid = insertAuthor_result.generatedkey>
			<cftransaction action="commit">
			<cfquery name="getId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getId_result">
				SELECT
					publication_author_name_id as id
				FROM 
					publication_author_name
				WHERE
					ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
			</cfquery>
			<cfquery name="report" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="report_result">
				SELECT
					publication_author_name_id as id,
					agent_name.agent_id,
 					agent_name.agent_name
				FROM 
					publication_author_name
					join agent_name on publication_author_name.agent_name_id = agent_name.agent_name_id
				WHERE
					publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getId.id#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "added">
			<cfset row["id"] = "#report.id#">
			<cfset row["agent_name"] = "#report.agent_name#">
			<cfset row["agent_id"] = "#report.agent_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- removeAuthor delete a publication_author_name record linking a publication to an
  agent in the role of author or editor, updates author_position of remining records
  for the same publication.
  @param publication_author_name_id the primary key value of the row to delete.
  @return a structure with status=deleted, updates=number of publication_author_name 
    records updated as a result of promoting their author_position to fill the gap.
    or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="removeAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_author_name_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- find the current oridinal position and type of the author in the list of authors/editors. --->
			<cfquery name="lookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookup_result">
				SELECT
					publication_id,
					author_position,
					author_role
				FROM
					publication_author_name
				WHERE
					publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
			</cfquery>
			<cfif lookup.recordcount NEQ 1>
				<cfthrow message = "error finding publication_author_name record to delete">
			</cfif>
			<!--- delete the target author/editor --->
			<cfquery name="deleteAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteAuthor_result">
				delete from publication_author_name 
				where
					publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
			</cfquery>
			<cfif deleteAuthor_result.recordcount NEQ 1>
				<cfthrow message = "error deleting publication_author_name record [#encodeForHtml(publication_author_name_id)#]">
			</cfif>
			<!--- update the ordinal positon of the rest of the list.  --->
			<cfquery name="reorder" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="reorder_result">
				update publication_author_name 
				set author_position=author_position-1 
				where
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.publication_id#">
					and author_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lookup.author_role#">
					and author_position > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.author_position#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["updates"] = "#reorder_result.recordcount#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!--- moveAuthor move an author or editor to a specified position in the list. 

--->
<cffunction name="moveAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_author_name_id" type="string" required="yes">
	<cfargument name="to_position" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="lookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookup_result">
				SELECT
					publication_id,
					author_position,
					author_role
				FROM
					publication_author_name
				WHERE
					publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
			</cfquery>
			<cfif lookup.recordcount NEQ 1>
				<cfthrow message = "error finding publication_author_name record to move">
			</cfif>
			<cfif author_position EQ to_position>
				<!--- no action --->
				<cfthrow message = "no change, old position and new position are the same.">
			</cfif>
			<cfif author_position EQ 1 OR to_position EQ 1>
				<!--- lookup agent and first/second author name forms --->
				<cfquery name="lookupAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupAgent_result">
					SELECT
						agent.agent_id,
						fan.agent_name_id first_author_agent_name_id,
						san.agent_name_id second_author_agent_name_id
					FROM
						agent_name author_agent_name
						join agent on author_agent_name.agent_id = agent.agent_id
						left join agent_name fan on agent.agent_id = fan.agent_id and fan.agent_name_type = 'author'
						left join agent_name san on agent.agent_id = san.agent_id and san.agent_name_type = 'second author'
				</cfquery>
			</cfif>
			<cfif author_position EQ 1>
				<!--- does a second author form of name exist for the agent --->
				<cfthrow message = "Move from first author not implemented yet.">
			<cfelse>
				<cfif to_position EQ 1>
					<!--- does a first author form of name exist for the agent --->
					<cfthrow message = "Move to first author not implemented yet.">
				<cfelse>
					<!--- increment everyone from to_position up by 1 --->
					<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="up_result">
						UPDATE
							publication_author_name
						SET
							author_position = author_position + 1
						WHERE
							publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.publication_id#">
							and author_role = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.author_role#">
							and author_position >= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#to_position#">
					</cfquery>
					<cfif author_position GT to_position>
						<!--- move to to_position --->
						<cfquery name="mv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="mv_result">
							UPDATE
								publication_author_name
							SET
								author_position = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#to_position#">
							WHERE
								publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
						</cfquery>
					<cfelse>	
						<!--- author_position LT to_position --->
						<!--- move to to_position+1 --->
						<cfset target = to_position + 1>
						<cfquery name="mv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="mv_result">
							UPDATE
								publication_author_name
							SET
								author_position = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target#">
							WHERE
								publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
						</cfquery>
					</cfif>
					<!--- move everyone above author_position down by 1 --->
					<cfquery name="dn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="dn_result">
						UPDATE
							publication_author_name
						SET
							author_position = author_position - 1
						WHERE
							publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.publication_id#">
							and author_role = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.author_role#">
							and author_position >= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.author_position#">
					</cfquery>
				</cfif>
			</cfif>

			<cfset row = StructNew()>
			<cfset row["status"] = "moved">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>



<!--- updateAuthor update a publication_author_name record without changing ordinal position. 
--->
<cffunction name="updateAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_author_name_id" type="string" required="yes">
	<cfargument name="agent_name_id" type="string" required="yes">
	<cfargument name="author_role" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAuthor_result">
				UPDATE
					publication_author_name
				SET
					agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAgentNameId#">,
					author_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAuthorRole#">
				WHERE
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					and publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRowId#">
			</cfquery>
			<cfif	updateAuthor_result.recordcount NEQ 1>
				<cfthrow message = "Error updating publication_author_name record.">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#publication_author_name_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="getAnnotationsForPubHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getAnnotationsForPubThread">
		<cftry>
			<cfoutput>
				<h2 class="h3">Annotations:</h2>
				<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) cnt from annotations
					where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				</cfquery>
				<cfif #existingAnnotations.cnt# GT 0>
					<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
						class="btn btn-xs btn-info" value="Annotate this record and view existing annotations"
						onClick=" openAnnotationsDialog('annotationDialog','publication',#publication_id#,reloadPublicationAnnotations);">Annotate/View Annotations</button>
				<cfelse>
					<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
						class="btn btn-xs btn-info" value="Annotate this record"
						onClick=" openAnnotationsDialog('annotationDialog','publication',#publication_id#,reloadPublicationAnnotations);">Annotate</button>
				</cfif>
				<div id="annotationDialog"></div>
				<cfif #existingAnnotations.cnt# gt 0>
					<cfif #existingAnnotations.cnt# EQ 1>
						<cfset are = "is">
						<cfset s = "">
					<cfelse>
						<cfset are = "are">
						<cfset s = "s">
					</cfif>
					<p>There #are# #existingAnnotations.cnt# annotation#s# on this publications record</p>
					<cfquery name="AnnotationStates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select count(*) statecount, state from annotations
						where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						group by state
					</cfquery>
					<ul>
						<cfloop query="AnnotationStates">
							<li>#state#: #statecount#</li>
						</cfloop>
					</ul>
				<cfelse>
					<p class="my-2">There are no annotations on this publication record</p>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAnnotationsForPubThread" />
	<cfreturn getAnnotationsForPubThread.output>
</cffunction>


<cffunction name="getAttributesForPubHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getAttributesForPubThread">
		<cftry>
			<cfquery name="ctpublication_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select publication_attribute from ctpublication_attribute order by publication_attribute
			</cfquery>
			<cfquery name="atts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="atts_result">
				SELECT
					publication_attribute_id,
					publication_id,
					publication_attribute,
					pub_att_value
				FROM publication_attributes 
				WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfquery name="available_pub_att" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT ctpublication_attribute.publication_attribute, 
					description
				FROM ctpublication_attribute 
				WHERE
					ctpublication_attribute.publication_attribute NOT IN (
						SELECT distinct publication_attribute 
						FROM publication_attributes
						WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					)
				ORDER BY ctpublication_attribute.publication_attribute
			</cfquery>
			<cfoutput>
				<h2 class="h3">Attributes</h2>
				<label for="new_attr" class="data-entry-label">Add</a>
				<script>
					<!--- TODO: Implement addAttribute, ? move to dialog --->
				</script>
				<select name="new_attr" id="new_attr" onchange="addAttribute(this.value)">
					<option value=""></option>
					<cfloop query="available_pub_att">
						<cfif len(available_pub_att.description) GT 0>
							<cfset descr = " (#available_pub_att.description#)">
						<cfelse>
							<cfset descr = "">
						</cfif>
						<option value="#available_pub_att.publication_attribute#">#available_pub_att.publication_attribute##descr#</option>
					</cfloop>
				</select>
				<ul>
					<cfloop query="atts">
						<!--- TODO: Edit --->
						<!--- TODO: Delete --->
						<li>
							#atts.publication_attribute#: #atts.pub_att_value#
							<button class="btn btn-xs btn-primary" onclick="deleteAttribute(#atts.publication_attribute_id#,reloadAttributes);">Delete</button>
						</li>
					</cfloop>
				</ul>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAttributesForPubThread" />
	<cfreturn getAttributesForPubThread.output>
</cffunction>

<!--- deleteAttribute delete a publication_attribute record.
  @param publication_attribute_id the primary key value of the row to delete.
  @return a structure with status=deleted
    or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="deleteAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_attribute_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- delete the target attribute --->
			<cfquery name="deleteAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteAttribute_result">
				delete from publication_attributes
				where
				publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_attribute_id#">
			</cfquery>
			<cfif deleteAttribute_result.recordcount NEQ 1>
				<cfthrow message = "error deleting publication_attribute record [#encodeForHtml(publication_attribute_id)#]">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- updateAttribute update a publication_attribute record.
  @param publication_attribute_id the primary key value of the row to update.
  @param publication_id the publication to which the attribute applies (optional,
   as the likely case is an update of attribute value for a record, rather than changing
   the publication to which an attribute is applied).
  @param publication_attribute the attribute to update.
  @param pub_att_value the value of the attribute to update.
  @return a structure with status=updated and id=publication_attribute_id
    or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="updateAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_attribute_id" type="string" required="yes">
	<cfargument name="publication_id" type="string" required="no">
	<cfargument name="publication_attribute" type="string" required="yes">
	<cfargument name="pub_att_value" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- update the target attribute --->
			<cfquery name="updateAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteAttribute_result">
				UPDATE publication_attributes
				SET
					<cfif isDefined("publication_id") AND len(publication_id) GT 0 >
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
					</cfif>
					publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_attribute#">,
					pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pub_att_value#">
				WHERE
					publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_attribute_id#">
			</cfquery>
			<cfif deleteAttribute_result.recordcount NEQ 1>
				<cfthrow message = "error updating publication_attribute record [#encodeForHtml(publication_attribute_id)#]">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#publication_attribute_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---------------------------------------------------------------------------------------------------------->
<!---
		<cfloop from="1" to="#numberAttributes#" index="n">
			<cfif isdefined("attribute_type#n#")>
				<cfset thisAttribute = #evaluate("attribute_type" & n)#>
			<cfelse>
				<cfset thisAttribute = "">
			</cfif>
			<cfset thisAttVal = #evaluate("attribute" & n)#>
			<cfif isdefined("publication_attribute_id#n#")>
				<cfset thisAttId = #evaluate("publication_attribute_id" & n)#>
			<cfelse>
				<cfset thisAttId = "">
			</cfif>
			<cfelseif thisAttId gt 0>
				<cfquery name="upAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update
						publication_attributes
					set
						publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttribute#">,
						pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttVal#">
					where 
						publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAttId#">
				</cfquery>
			<cfelseif len(thisAttId) is 0 and len(thisAttVal) gt 0>
				<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into publication_attributes (
						publication_id,
						publication_attribute,
						pub_att_value
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttribute#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttVal#">
					)
				</cfquery>
			</cfif>
		</cfloop>
--->
<!---------------------------------------------------------------------------------------------------------->
<!---
	</cftransaction>
--->
<!---------------------------------------------------------------------------------------------------------->
<!--- now get the formatted publications --->
<!--- 
	<cfinvoke component="/component/publication" method="shortCitation" returnVariable="shortCitation">
		<cfinvokeargument name="publication_id" value="#publication_id#">
		<cfinvokeargument name="returnFormat" value="plain">
	</cfinvoke>
	<cfinvoke component="/component/publication" method="longCitation" returnVariable="longCitation">
		<cfinvokeargument name="publication_id" value="#publication_id#">
		<cfinvokeargument name="returnFormat" value="plain">
	</cfinvoke>

	<cfquery name="sfp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update formatted_publication 
		set formatted_publication = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shortCitation#">
		where
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			and format_style = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="short">
	</cfquery>
	<cfquery name="lfp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update formatted_publication 
		set formatted_publication = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#longCitation#">
		where
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			and format_style = 'long'
	</cfquery>
	<cflocation url="Publication.cfm?action=edit&publication_id=#publication_id#" addtoken="false">
--->

<!--- getMediaForPubHtml obtain a block of html for editing media related to a publication.
 @param publication_id the publication for which to obtain media
 @return html listing media for the specified publication in a form for editing
---->
<cffunction name="getMediaForPubHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getMediaForPubThread">

		<cftry>
			<cfoutput>
				<cfquery name="getMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getMedia_result">
					SELECT distinct
						media.media_id, media_relations_id
					FROM
						media 
						join media_relations on media.media_id=media_relations.media_id
					WHERE
						media_relations.media_relationship like '%publication' and
						media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				</cfquery>
				<cfif getMedia.recordcount gt 0>
					<h2 class="h3">Media</h2>
					<div class="col-12 row">
						<cfloop query="getMedia">
							<div class="col-12 col-sm-6 col-md-4 col-xl-3 bg-light">
								<div id="mediaBlock#media_id#" class="border rounded">
									<cfset mediablock= getMediaBlockHtmlUnthreaded(media_id="#media_id#",size="400",captionAs="textMid")>
									<input type='button' 
										value="Remove" aria-label="unlink this media record from this publication"
										class="btn btn-xs btn-warning"
										onClick="confirmDialog('Remove Relationship to this Media record?','Remove?', function() { deleteMediaRelation('#getMedia.media_relations_id#',reloadPublicationMedia); } );">
								</div>
							</div>
						</cfloop>
					</div>
				<cfelse>
					<p>There are no media records related to this publication</p>
				</cfif>

				<div class="col-12 row">
					<div class="col-12 row">
					<input type='button' 
						value="Create Media" 
						class="btn btn-xs btn-secondary"
						onClick="opencreatemediadialog('addMediaDialog',$('##fullCitationPlain').val(),'#publication_id#','shows publication',reloadPublicationMedia);" >
					<input type='button' 
						value='Link Media' 
						class='btn btn-xs btn-secondary' 
						onClick="openlinkmediadialog('linkMediaDialog','Link media to '+$('##fullCitationPlain').val() ,'#publication_id#','shows publication',reloadPublicationMedia); " >
				</div>
				<div id='addMediaDialog'></div>
				<div id='linkMediaDialog'></div>

			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getMediaForPubThread" />
	<cfreturn getMediaForPubThread.output>
</cffunction>

</cfcomponent>
