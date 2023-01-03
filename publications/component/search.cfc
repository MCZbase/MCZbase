<!---
publications/component/search.cfc

Copyright 2020 President and Fellows of Harvard College

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
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---
Function getPublications.  Search for publications by fields
 returning json suitable for a dataadaptor.

@param any_part any part of formatted publication string to search for.
@return a json structure containing matching publications with ids, years, long format of publication, etc.
--->
<cffunction name="getPublications" access="remote" returntype="any" returnformat="json">
	<cfargument name="text" type="string" required="no">
	<cfargument name="publication_type" type="string" required="no">
	<cfargument name="publication_title" type="string" required="no">
	<cfargument name="publication_remarks" type="string" required="no">
	<cfargument name="is_peer_reviewed_fg" type="string" required="no">
	<cfargument name="journal_name" type="string" required="no">
	<cfargument name="doi" type="string" required="no">
	<cfargument name="volume" type="string" required="no">
	<cfargument name="issue" type="string" required="no">
	<cfargument name="number" type="string" required="no">
	<cfargument name="begin_page" type="string" required="no">
	<cfargument name="published_year" type="string" required="no">
	<cfargument name="to_published_year" type="string" required="no">
	<cfargument name="cites_collection" type="string" required="no"><!--- TODO --->
	<cfargument name="cites_specimens" type="string" required="no">
	<cfargument name="cited_taxon" type="string" required="no"><!--- TODO --->
	<cfargument name="accepted_for_cited_taxon" type="string" required="no"><!--- TODO --->
	<cfargument name="cited_collection_object_id" type="string" required="no">
	<cfargument name="related_cataloged_item" type="string" required="no">
	<cfargument name="publication_attribute_type" type="string" required="no">
	<cfargument name="publication_attribute_value" type="string" required="no">
	<cfargument name="author_agent_name" type="string" required="no">
	<cfargument name="author_agent_id" type="string" required="no">
	<cfargument name="editor_agent_name" type="string" required="no">
	<cfargument name="editor_agent_id" type="string" required="no">
	<cfargument name="publisher" type="string" required="no">
	<cfargument name="taxon_publication" type="string" required="no">
	<cfargument name="cited_named_group_id" type="string" required="no">
	<cfargument name="type_status" type="string" required="no">

	<cfif NOT (isDefined("cited_collection_object_id") AND len(cited_collection_object_id) GT 0) 
		AND NOT (isDefined("related_cataloged_item") AND len(related_cataloged_item) GT 0) >
		<!--- ignore cites_specimens if a cited specimen is specified --->
		<cfif isDefined("cites_specimens") AND len(cites_specimens) GT 0>
			<cfif cites_specimens EQ "true">
				<cfset cited_collection_object_id = "NOT NULL">
			<cfelseif cites_specimens EQ "false">
				<cfset cited_collection_object_id = "NULL">
			</cfif>
		</cfif>
	</cfif>
	<cfif NOT isDefined("related_cataloged_item")><cfset related_cataloged_item = ""></cfif>
	<cfif related_cataloged_item EQ "NULL">
		<cfset cited_collection_object_id = "NULL">
		<cfset related_cataloged_item = "">
	<cfelseif related_cataloged_item EQ "NOT NULL">
		<cfset cited_collection_object_id = "NOT NULL">
		<cfset related_cataloged_item = "">
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				publication.publication_id, 
				publication_type, 
				published_year, 
				publication_title,
				publication_remarks,
				formatted_publication,
				MCZbase.get_publication_authors(publication.publication_id) as authors,
				MCZbase.get_publication_editors(publication.publication_id) as editors,
				jour_att.pub_att_value as journal_name,
				publisher_att.pub_att_value as publisher,
				doi,
				MCZbase.getshortcitation(publication.publication_id) as short_citation,
				MCZBASE.count_citations_for_pub(publication.publication_id) as cited_specimen_count
			FROM 
				publication
				join formatted_publication on publication.publication_id = formatted_publication.publication_id
					and formatted_publication.format_style = 'long'
				left join publication_attributes jour_att 
					on publication.publication_id = jour_att.publication_id
						and jour_att.publication_attribute = 'journal name'
				left join publication_attributes publisher_att 
					on publication.publication_id = publisher_att.publication_id
						and publisher_att.publication_attribute = 'publisher'
				<cfif isDefined("cites_collection") AND len(cites_collection) GT 0>
					left join citation citation_coll on publication.publication_id = citation_coll.publication_id
					left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat_coll on citation_coll.collection_object_id = flat_coll.collection_object_id
				</cfif>
				<cfif isDefined("volume") AND len(volume) GT 0>
					left join publication_attributes volume_att 
						on publication.publication_id = volume_att.publication_id
							and volume_att.publication_attribute = 'volume'
				</cfif>
				<cfif isDefined("issue") AND len(issue) GT 0>
					left join publication_attributes issue_att 
						on publication.publication_id = issue_att.publication_id
							and issue_att.publication_attribute = 'issue'
				</cfif>
				<cfif isDefined("number") AND len(number) GT 0>
					left join publication_attributes number_att 
						on publication.publication_id = number_att.publication_id
							and number_att.publication_attribute = 'number'
				</cfif>
				<cfif isDefined("begin_page") AND len(begin_page) GT 0>
					left join publication_attributes begin_page_att 
						on publication.publication_id = begin_page_att.publication_id
							and begin_page_att.publication_attribute = 'begin page'
				</cfif>
				<cfif isDefined("publication_attribute_type") AND len(publication_attribute_type) GT 0>
					left join publication_attributes publication_attribute_type_att 
						on publication.publication_id = publication_attribute_type_att.publication_id
							and publication_attribute_type_att.publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_attribute_type#">
				</cfif>
				<cfif isDefined("type_status") AND len(type_status) GT 0>
					left join citation type_status_citation on publication.publication_id = type_status_citation.publication_id
				</cfif>
				<cfif isDefined("cited_collection_object_id") AND len(cited_collection_object_id) GT 0 >
					left join citation on publication.publication_id = citation.publication_id
				<cfelse>
					<cfif isDefined("related_cataloged_item") AND len(related_cataloged_item) GT 0>
						left join citation on publication.publication_id = citation.publication_id
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on citation.collection_object_id = flat.collection_object_id
					</cfif>
				</cfif>
				<cfif isDefined("cited_taxon") AND len(cited_taxon) GT 0>
					left join citation taxon_cite on publication.publication_id = taxon_cite.publication_id
					left join taxonomy on taxon_cite.cited_taxon_name_id = taxonomy.taxon_name_id
				</cfif>
				<cfif isDefined("accepted_for_cited_taxon") AND len(accepted_for_cited_taxon) GT 0>
					left join citation accepted_taxon_cite on publication.publication_id = accepted_taxon_cite.publication_id
					left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> accepted_flat on accepted_taxon_cite.collection_object_id = accepted_flat.collection_object_id
				</cfif>
				<cfif (isDefined("author_agent_id") AND len(author_agent_id) GT 0) OR (isDefined("author_agent_name") AND len(author_agent_name) GT 0) >
					left join publication_author_name on publication.publication_id = publication_author_name.publication_id and publication_author_name.author_role = 'author'
					left join agent_name pubagent_name on publication_author_name.agent_name_id = pubagent_name.agent_name_id
					<cfif isDefined("author_agent_name") AND len(author_agent_name) GT 0 >
						left join agent_name anyagentname on pubagent_name.agent_id = anyagentname.agent_id 
					</cfif>
				</cfif>
				<cfif (isDefined("editor_agent_id") AND len(editor_agent_id) GT 0) OR (isDefined("editor_agent_name") AND len(editor_agent_name) GT 0) >
					left join publication_author_name publication_editor_name on publication.publication_id = publication_editor_name.publication_id and publication_editor_name.author_role = 'editor'
					left join agent_name pubeditor_name on publication_editor_name.agent_name_id = pubeditor_name.agent_name_id
					<cfif isDefined("editor_agent_name") AND len(editor_agent_name) GT 0 >
						left join agent_name anyeditoragentname on pubeditor_name.agent_id = anyeditoragentname.agent_id 
					</cfif>
				</cfif>
				<cfif isDefined("cited_named_group_id") AND len(cited_named_group_id) GT 0>
					left join underscore_collection_citation on publication.publication_id = underscore_collection_citation.publication_id
				</cfif>
				<cfif isDefined("taxon_publication") AND len(taxon_publication) GT 0>
					left join taxonomy_publication on publication.publication_id = taxonomy_publication.publication_id
					left join taxonomy pub_taxon on taxonomy_publication.taxon_name_id = pub_taxon.taxon_name_id
				</cfif>
			WHERE
				publication.publication_id is not null
				<cfif isDefined("text") AND len(text) GT 0>
					and upper(formatted_publication) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(text)#%">
				</cfif>
				<cfif isDefined("published_year") AND len(published_year) GT 0>
					<cfif isDefined("to_published_year") AND len(to_published_year) GT 0>
						and published_year between
							 <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#published_year#">
								and
							 <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#to_published_year#">
					<cfelse>
						and published_year = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#published_year#">
					</cfif>
				</cfif>
				<cfif isDefined("publication_title") AND len(publication_title) GT 0>
					and upper(publication_title) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(publication_title)#%">
				</cfif>
				<cfif isDefined("publication_remarks") AND len(publication_remarks) GT 0>
					and upper(publication_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(publication_remarks)#%">
				</cfif>
				<cfif isDefined("publication_type") AND len(publication_type) GT 0>
					<cfif left(publication_type,1) EQ "!">
						and publication_type <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(publication_type,len(publication_type)-1)#">
					<cfelse>
						and publication_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_type#">
					</cfif>
				</cfif>
				<cfif isDefined("is_peer_reviewed_fg") AND len(is_peer_reviewed_fg) GT 0>
					and is_peer_reviewed_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#is_peer_reviewed_fg#">
				</cfif>
				<cfif isDefined("doi") AND len(doi) GT 0>
					<cfif doi EQ "NULL">
						and doi IS NULL
					<cfelseif doi EQ "NOT NULL">
						and doi IS NOT NULL
					<cfelse>
						and doi like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#doi#%">
					</cfif>
				</cfif>
				<cfif isDefined("journal_name") AND len(journal_name) GT 0>
					<cfif journal_name EQ "NULL">
						and jour_att.pub_att_value IS NULL
					<cfelseif journal_name EQ "NOT NULL">
						and jour_att.pub_att_value IS NOT NULL
					<cfelse>
						and upper(jour_att.pub_att_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(journal_name)#%">
					</cfif>
				</cfif>
				<cfif isDefined("publisher") AND len(publisher) GT 0>
					<cfif publisher EQ "NULL">
						and publisher_att.pub_att_value IS NULL
					<cfelseif publisher EQ "NOT NULL">
						and publisher_att.pub_att_value IS NOT NULL
					<cfelse>
						<cfif left(publisher,1) EQ "!">
							<!--- behavior: has a publisher, but not the specified one --->
							and publisher_att.pub_att_value <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(publisher,len(publisher)-1)#">
						<cfelse>
							and publisher_att.pub_att_value like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#publisher#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("volume") AND len(volume) GT 0>
					<cfif volume EQ "NULL">
						and volume_att.pub_att_value IS NULL
					<cfelseif volume EQ "NOT NULL">
						and volume_att.pub_att_value IS NOT NULL
					<cfelse>
						<cfif left(volume,1) EQ "!">
							and volume_att.pub_att_value <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(volume,len(volume)-1)#">
						<cfelseif left(volume,1) EQ "=">
							and volume_att.pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(volume,len(volume)-1)#">
						<cfelse>
							and volume_att.pub_att_value like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#volume#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("issue") AND len(issue) GT 0>
					<cfif issue EQ "NULL">
						and issue_att.pub_att_value IS NULL
					<cfelseif issue EQ "NOT NULL">
						and issue_att.pub_att_value IS NOT NULL
					<cfelse>
						<cfif left(issue,1) EQ "!">
							and issue_att.pub_att_value <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(issue,len(issue)-1)#">
						<cfelseif left(issue,1) EQ "=">
							and issue_att.pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(issue,len(issue)-1)#">
						<cfelse>
							and issue_att.pub_att_value like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#issue#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("begin_page") AND len(begin_page) GT 0>
					<cfif begin_page EQ "NULL">
						and begin_page_att.pub_att_value IS NULL
					<cfelseif begin_page EQ "NOT NULL">
						and begin_page_att.pub_att_value IS NOT NULL
					<cfelse>
						<cfif left(begin_page,1) EQ "!">
							and begin_page_att.pub_att_value <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(begin_page,len(begin_page)-1)#">
						<cfelseif left(begin_page,1) EQ "=">
							and begin_page_att.pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(begin_page,len(begin_page)-1)#">
						<cfelse>
							and begin_page_att.pub_att_value like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#begin_page#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("number") AND len(number) GT 0>
					<cfif number EQ "NULL">
						and number_att.pub_att_value IS NULL
					<cfelseif number EQ "NOT NULL">
						and number_att.pub_att_value IS NOT NULL
					<cfelse>
						<cfif left(number,1) EQ "!">
							and number_att.pub_att_value <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(number,len(number)-1)#">
						<cfelseif left(number,1) EQ "=">
							and number_att.pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(number,len(number)-1)#">
						<cfelse>
							and number_att.pub_att_value like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#number#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("publication_attribute_type") AND len(publication_attribute_type) GT 0>
					<cfif isDefined("publication_attribute_value") AND len(publication_attribute_value) GT 0>
						<cfif publication_attribute_value EQ "NULL">
							and publication_attribute_type_att.pub_att_value IS NULL
						<cfelseif publication_attribute_value EQ "NOT NULL">
							and publication_attribute_type_att.pub_att_value IS NOT NULL
						<cfelse>
							<cfif left(publication_attribute_value,1) EQ "!">
								and publication_attribute_type_att.pub_att_value <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(publication_attribute_value,len(publication_attribute_value)-1)#">
							<cfelseif left(publication_attribute_value,1) EQ "=">
								and publication_attribute_type_att.pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(publication_attribute_value,len(publication_attribute_value)-1)#">
							<cfelse>
								and publication_attribute_type_att.pub_att_value like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#publication_attribute_value#%">
							</cfif>
						</cfif>
					<cfelse>
						and publication_attribute_type_att.pub_att_value IS NOT NULL
					</cfif>
				</cfif>
				<cfif isDefined("type_status") AND len(type_status) GT 0 >
					and type_status_citation.type_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type_status#">
				</cfif>
				<cfif isDefined("cited_collection_object_id") AND len(cited_collection_object_id) GT 0>
					<cfif cited_collection_object_id EQ "NULL">
						and citation.collection_object_id IS NULL
					<cfelseif cited_collection_object_id EQ "NOT NULL">
						and citation.collection_object_id IS NOT NULL
					<cfelse>
						and citation.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cited_collection_object_id#">
					</cfif>
				</cfif>
				<cfif isDefined("related_cataloged_item") AND len(related_cataloged_item) GT 0>
					and flat.guid in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_cataloged_item#" list="yes">)
				</cfif>
				<cfif isDefined("cites_collection") AND len(cites_collection) GT 0>
					<cfif cites_collection EQ "NOT NULL">
						and flat_coll.collection_cde IS NOT NULL
					<cfelse>
						and flat_coll.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cites_collection#">
					</cfif>
				</cfif>
				<cfif isDefined("cited_taxon") AND len(cited_taxon) GT 0>
					<cfif left(cited_taxon,1) EQ "=">
						and taxonomy.scientific_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(cited_taxon,len(cited_taxon)-1)#">
					<cfelse>
						and upper(taxonomy.scientific_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(cited_taxon)#%">
					</cfif>
				</cfif>
				<cfif isDefined("accepted_for_cited_taxon") AND len(accepted_for_cited_taxon) GT 0>
					<cfif left(accepted_for_cited_taxon,1) EQ "=">
						and accepted_flat.scientific_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(accepted_for_cited_taxon,len(accepted_for_cited_taxon)-1)#">
					<cfelse>
						and upper(accepted_flat.scientific_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(accepted_for_cited_taxon)#%">
					</cfif>
				</cfif>
				<cfif isDefined("author_agent_id") AND len(author_agent_id) GT 0>
					and pubagent_name.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#author_agent_id#">
				<cfelseif isDefined("author_agent_name") AND len(author_agent_name) GT 0>
					and anyagentname like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#author_agent_name#%">
				</cfif>
				<cfif isDefined("editor_agent_id") AND len(editor_agent_id) GT 0>
					and pubeditor_name.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#editor_agent_id#">
				<cfelseif isDefined("editor_agent_name") AND len(editor_agent_name) GT 0>
					and anyeditoragentname like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#author_agent_name#%">
				</cfif>
				<cfif isDefined("cited_named_group_id") AND len(cited_named_group_id) GT 0>
					and underscore_collection_citation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#cited_named_group_id#">
				</cfif>
				<cfif isDefined("taxon_publication") AND len(taxon_publication) GT 0>
					<cfif taxon_publication EQ "NULL">
						and pub_taxon.taxon_name_id IS NULL
					<cfelseif taxon_publication EQ "NOT NULL">
						and pub_taxon.taxon_name_id IS NOT NULL
					<cfelse>
						<cfif left(taxon_publication,1) EQ "=">
							and pub_taxon.scientific_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(taxon_publication,len(taxon_publication)-1)#">
						<cfelse>
							and upper(pub_taxon.scientific_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(taxon_publication)#%">
						</cfif>
					</cfif>
				</cfif>
			ORDER BY
				published_year
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!---
Function getPublicationList.  Search for publications by name with a substring match on text, returning json suitable for a dataadaptor.

@param text in formatted_publication to search for.
@return a json structure containing matching publications with ids, years, long format of publication, etc.
--->
<cffunction name="getPublicationList" access="remote" returntype="any" returnformat="json">
	<cfargument name="text" type="string" required="yes">
	<!--- perform wildcard search anywhere in formatted_publication.formatted_publication --->
	<cfset text = "%#text#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				publication_type, published_year, publication_title,
				publication_remarks,
				publication.publication_id, formatted_publication,
				MCZbase.get_publication_authors(publication.publication_id) as authors,
				MCZbase.get_publication_editors(publication.publication_id) as editors
			FROM 
				publication
				left join formatted_publication on publication.publication_id = formatted_publication.publication_id
			WHERE
				formatted_publication like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#text#">
				and format_style = 'long'
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["publication_id"] = "#search.publication_id#">
			<cfset row["formatted_publication"] = "#search.formatted_publication#">
			<cfset row["authors"] = "#search.authors#">
			<cfset row["published_year"] = "#search.published_year#">
			<cfset row["publication_title"] = "#search.publication_title#">
			<cfset row["editors"] = "#search.editors#">
			<cfset row["publication_type"] = "#search.publication_type#">
			<cfset row["publication_remarks"] = "#search.publication_remarks#">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getPublicationAutocomplete.  Search for publications by name with a substring match on any name, returning json suitable for jquery-ui autocomplete.

@param term publication name to search for.
@return a json structure containing id and value, with matching publications with matched name in value and publication_id in id.
--->
<cffunction name="getPublicationAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in publication_name.publication_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				publication_id, formatted_publication
			FROM 
				formatted_publication
			WHERE
				upper(formatted_publication) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.publication_id#">
			<cfset row["value"] = "#reReplace(Canonicalize(search.formatted_publication,false,true),'<(i|/i)>','','all')#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getPublicationAutocompleteMeta.  Search for publications by name with a substring match on any name, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just the publication name as the selected value.

@param term publication name to search for.
@return a json structure containing id and value, with matching publications with matched name in value and publication_id in id, and matched name 
  with * and preferred name in meta.
--->
<cffunction name="getPublicationAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in publication_name.publication_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				publication_id, formatted_publication
			FROM 
				formatted_publication
			WHERE
				upper(formatted_publication) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.publication_id#">
			<cfset row["value"] = "#search.formatted_publication#" >
			<cfset row["meta"] = "#search.formatted_publication#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getTypeStatusSearchAutocomplete.  Search for type status values, returning json suitable for jquery-ui autocomplete.

@param term type status to search for.
@return a json structure containing id and value, with matching publications with type_status in name and in id.
--->
<cffunction name="getTypeStatusSearchAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
			   type_status, category	
			FROM 
				ctcitation_type_status
			WHERE
				upper(type_status) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfset row = StructNew()>
		<cfset row["id"] = "any">
		<cfset row["value"] = "Any" >
		<cfset data[i]  = row>
		<cfset i = i + 1>
		<cfset row = StructNew()>
		<cfset row["id"] = "any type">
		<cfset row["value"] = "Any Type" >
		<cfset data[i]  = row>
		<cfset i = i + 1>
		<cfset row = StructNew()>
		<cfset row["id"] = "any primary">
		<cfset row["value"] = "Any Primary Type" >
		<cfset data[i]  = row>
		<cfset i = i + 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.type_status#">
			<cfset row["value"] = "#search.type_status#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getDOIAutocomplete.  Search for dois by name with a substring match
   returning json suitable for jquery-ui autocomplete, with meta renderer.

@param term doi to search for.
@return a json structure containing id, meta, and value, with matching dois with match in both 
  value and id, and doi plus short citation in meta.
--->
<cffunction name="getDOIAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				doi as id, 
				doi as value,
				MCZBASE.getshortcitation(publication_id) as short
			FROM 
				publication
			WHERE
				doi like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.id#">
			<cfset row["value"] = "#search.value#" >
			<cfset row["meta"] = "#search.value# (#search.short#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getJournalNames.  Search for publications by fields
 returning json suitable for a dataadaptor.

@param any_part any part of formatted publication string to search for.
@return a json structure containing matching publications with ids, years, long format of publication, etc.
--->
<cffunction name="getJournalNames" access="remote" returntype="any" returnformat="json">
	<cfargument name="journal_name" type="string" required="no">
	<cfargument name="issn" type="string" required="no">
	<cfargument name="short_name" type="string" required="no">
	<cfargument name="start_year" type="string" required="no">
	<cfargument name="end_year" type="string" required="no">
	<cfargument name="remarks" type="string" required="no">

	<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"manage_publications")>
		<cfthrow message="Insufficent rights to run journal search.">
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfif isDefined("journal_name") AND len(journal_name) GT 0>
			<!--- Set up the session to run an accent insensitive search --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_COMP = LINGUISTIC
			</cfquery>
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_SORT = GENERIC_M_AI
			</cfquery>
		</cfif>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				journal_name,
				short_name,
				issn, 
				start_year,
				end_year,
				remarks,
				count(distinct publication_id) as publication_count
			FROM 
				ctjournal_name
				left join publication_attributes on ctjournal_name.journal_name = publication_attributes.pub_att_value and publication_attributes.publication_attribute = 'journal name'
			WHERE
				journal_name is not null
				<cfif isDefined("remarks") AND len(remarks) GT 0>
					and upper(remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(remarks)#%">
				</cfif>
				<cfif isDefined("journal_name") AND len(journal_name) GT 0>
					<cfif left(journal_name,1) EQ "=">
						and journal_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(journal_name,len(journal_name)-1)#">
					<cfelseif left(journal_name,1) EQ "!">
						and journal_name <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(journal_name,len(journal_name)-1)#">
					<cfelseif left(journal_name,1) is "~">
						AND utl_match.jaro_winkler(journal_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(journal_name,len(journal_name)-1)#">) >= 0.85
					<cfelseif left(journal_name,1) is "$">
						AND soundex(journal_name) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(journal_name,len(journal_name)-1))#">)
					<cfelseif left(journal_name,2) is "!$">
						AND soundex(journal_name) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(journal_name,len(journal_name)-2))#">)
					<cfelse>
						and upper(journal_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(journal_name)#%">
					</cfif>
				</cfif>
				<cfif isDefined("short_name") AND len(short_name) GT 0>
					<cfif short_name EQ "NULL">
						and short_name IS NULL
					<cfelseif short_name EQ "NOT NULL">
						and short_name IS NOT NULL
					<cfelse>
						<cfif left(short_name,1) EQ "=">
							and short_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(short_name,len(short_name)-1)#">
						<cfelseif left(short_name,1) is "~">
							AND utl_match.jaro_winkler(short_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(short_name,len(short_name)-1)#">) >= 0.90
						<cfelseif left(short_name,1) is "$">
							AND soundex(short_name) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(short_name,len(short_name)-1))#">)
						<cfelseif left(short_name,2) is "!$">
							AND soundex(short_name) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(short_name,len(short_name)-2))#">)
						<cfelse>
							and upper(short_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(short_name)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("issn") AND len(issn) GT 0>
					<cfif issn EQ "NULL">
						and issn IS NULL
					<cfelseif issn EQ "NOT NULL">
						and issn IS NOT NULL
					<cfelse>
						<cfif left(issn,1) EQ "!">
							<!--- behavior: has a issn, but not the specified one --->
							and issn <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(issn,len(issn)-1)#">
						<cfelseif left(issn,1) is "~">
							AND utl_match.jaro_winkler(issn, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(issn,len(issn)-1)#">) >= 0.90
						<cfelseif left(issn,1) is "=">
							AND issn = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(issn,len(issn)-1)#">
						<cfelse>
							and issn like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#issn#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("start_year") AND len(start_year) GT 0>
					<cfif start_year EQ "NULL">
						and start_year IS NULL
					<cfelseif start_year EQ "NOT NULL">
						and start_year IS NOT NULL
					<cfelse>
						<cfif left(start_year,1) EQ ">">
							and start_year > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(start_year,len(start_year)-1)#">
						<cfelseif left(start_year,1) is "<">
							AND start_year < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(start_year,len(start_year)-1)#">
						<cfelse>
							and start_year = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#start_year#">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("end_year") AND len(end_year) GT 0>
					<cfif end_year EQ "NULL">
						and end_year IS NULL
					<cfelseif end_year EQ "NOT NULL">
						and end_year IS NOT NULL
					<cfelse>
						<cfif left(end_year,1) EQ ">">
							and end_year > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(end_year,len(end_year)-1)#">
						<cfelseif left(end_year,1) is "<">
							AND end_year < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(end_year,len(end_year)-1)#">
						<cfelse>
							and end_year = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#end_year#">
						</cfif>
					</cfif>
				</cfif>
			GROUP BY
				journal_name,
				short_name,
				issn, 
				start_year,
				end_year,
				remarks
			ORDER BY
				journal_name	
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	<cffinally>
		<cfif isDefined("journal_name") AND len(journal_name) GT 0>
			<!--- Reset NLS_COMP back to the default, or the session will keep using the generic_m_ai comparison/sort on subsequent searches. --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_COMP = BINARY
			</cfquery>
		</cfif>
	</cffinally>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- check if there is a case and accent insensitive match to a specified journal name 
 @param journal_name the name to check 
--->
<cffunction name="checkJournalNameExists" returntype="any" access="remote" returnformat="json">
	<cfargument name="journal_name" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- Set up the session to run an accent insensitive search --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_COMP = LINGUISTIC
			</cfquery>
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_SORT = GENERIC_M_AI
			</cfquery>
			<cfquery name="dupPref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="dupPref_result">
				SELECT journal_name
				FROM 
					ctjournal_name
				WHERE 
					upper(journal_name) = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ucase(journal_name)#'>
			</cfquery>
			<cfset matchcount = dupPref.recordcount>
			<cfset i = 1>
			<cfloop query="dupPref">
				<cfset row = StructNew()>
				<cfset columnNames = ListToArray(dupPref.columnList)>
				<cfloop array="#columnNames#" index="columnName">
					<cfset row["#columnName#"] = "#dupPref[columnName][currentrow]#">
				</cfloop>
				<cfset data[i] = row>
				<cfset i = i + 1>
			</cfloop>
			<cfreturn #serializeJSON(data)#>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		<cffinally>
			<!--- Reset NLS_COMP back to the default, or the session will keep using the generic_m_ai comparison/sort on subsequent searches. --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_COMP = BINARY
			</cfquery>
		</cffinally>
		</cftry>
	</cftransaction>
</cffunction>

</cfcomponent>
