<!---
taxonomy/component/functions.cfc

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
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<cffunction name="saveTaxonomy" access="remote" returntype="any" returnformat="json">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfargument name="source_authority" type="string" required="yes">
	<cfargument name="nomenclatural_code" type="string" required="yes">	
	<cfargument name="valid_catalog_term_fg" type="numeric" required="yes">	
	<cfargument name="taxon_status" type="string" required="no">	
	<cfargument name="genus" type="string" required="no">		
	<cfargument name="subgenus" type="string" required="no">
	<cfargument name="species" type="string" required="no">
	<cfargument name="subspecies" type="string" required="no">
	<cfargument name="author_text" type="string" required="no">
	<cfargument name="year_of_publication" type="string" required="no">
	<cfargument name="infraspecific_author" type="string" required="yes">
	<cfargument name="infraspecific_rank" type="string" required="no">	
	<cfargument name="kingdom" type="string" required="no">		
	<cfargument name="division" type="string" required="no">
	<cfargument name="subdivision" type="string" required="no">	
	<cfargument name="subsection" type="string" required="no">	
	<cfargument name="phylum" type="string" required="no">
	<cfargument name="subphylum" type="string" required="no">
	<cfargument name="superclass" type="string" required="no">
	<cfargument name="phylclass" type="string" required="no">
	<cfargument name="subclass" type="string" required="no">
	<cfargument name="infraclass" type="string" required="no">
	<cfargument name="superorder" type="string" required="no">	
	<cfargument name="phylorder" type="string" required="no">
	<cfargument name="suborder" type="string" required="no">
	<cfargument name="infraorder" type="string" required="no">
	<cfargument name="superfamily" type="string" required="no">
	<cfargument name="family" type="string" required="no">	
	<cfargument name="subfamily" type="string" required="no">	
	<cfargument name="tribe" type="string" required="no">		
	<cfargument name="taxonid_guid_type" type="string" required="no">
	<cfargument name="taxonid" type="string" required="no">
	<cfargument name="scientificnameid_guid_type" type="string" required="no">
	<cfargument name="scientificnameid" type="string" required="no">
	<cfargument name="taxon_remarks" type="string" required="no">
	
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfif len(trim(#source_authority#)) EQ 0>
			<cfthrow type="Application" message="Source must contain a value.">
		</cfif>
		<cfif len(trim(#valid_catalog_term_fg#)) EQ 0>
			<cfthrow type="Application" message="Valid for catalog must contain a value.">
		</cfif>
		<cfif len(trim(#nomenclatural_code#)) EQ 0>
			<cfthrow type="Application" message="Nomenclatural code must contain a value.">
		</cfif>
		<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update taxonomy set
				valid_catalog_term_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">
				,source_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#source_authority#">
				,nomenclatural_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nomenclatural_code#">
				<cfif isdefined("taxon_status") and len(taxon_status) GT 0>
					,taxon_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_status#">
				<cfelse>
					,taxon_status = NULL </cfif>
				<cfif isdefined("taxon_remarks") and len(taxon_remarks) GT 0>
					,taxon_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(taxon_remarks)#">
				<cfelse> 
					,taxon_remarks = NULL
				</cfif>
				<cfif isdefined("genus") and len(genus) GT 0> ,genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#genus#"> <cfelse> ,genus = NULL </cfif>
				<cfif isdefined("subgenus") and len(subgenus) GT 0> ,subgenus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#subgenus#"> <cfelse> ,subgenus = NULL </cfif>
				<cfif isdefined("species") and len(species) GT 0> ,species = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#species#"> <cfelse> ,species = NULL </cfif>
				<cfif isdefined("subspecies") and len(subspecies) GT 0> ,subspecies = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#subspecies#"> <cfelse> ,subspecies = NULL </cfif>
				<cfif isdefined("author_text") and len(author_text) GT 0> ,author_text = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#author_text#"> <cfelse> ,author_text = NULL </cfif>
				<cfif isdefined("year_of_publication") and len(year_of_publication) GT 0> ,year_of_publication = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#year_of_publication#"> <cfelse> ,year_of_publication = NULL </cfif>
				<cfif isdefined("infraspecific_rank") and len(infraspecific_rank) GT 0> ,infraspecific_rank = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#infraspecific_rank#"> <cfelse> ,infraspecific_rank = NULL </cfif>
				<cfif isdefined("infraspecific_author") and len(infraspecific_author) GT 0> ,infraspecific_author = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#infraspecific_author#"> <cfelse> ,infraspecific_author = NULL </cfif>
				<cfif isdefined("kingdom") and len(kingdom) GT 0> ,kingdom = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(kingdom)#"> <cfelse> ,kingdom = NULL </cfif>
				<cfif isdefined("phylum") and len(phylum) GT 0> ,phylum = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(phylum)#"> <cfelse> ,phylum = NULL </cfif>
				<cfif isdefined("subphylum") and len(subphylum) GT 0> ,subphylum = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subphylum)#"> <cfelse> ,subphylum = NULL </cfif>
				<cfif isdefined("superclass") and len(superclass) GT 0> ,superclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(superclass)#"> <cfelse> ,superclass = NULL </cfif>
				<cfif isdefined("phylclass") and len(phylclass) GT 0> ,phylclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(phylclass)#"> <cfelse> ,phylclass = NULL </cfif>
				<cfif isdefined("subclass") and len(subclass) GT 0> ,subclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subclass)#"> <cfelse> ,subclass = NULL </cfif>
				<cfif isdefined("infraclass") and len(infraclass) GT 0> ,infraclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(infraclass)#"> <cfelse> ,infraclass = NULL </cfif>
				<cfif isdefined("superorder") and len(superorder) GT 0> ,superorder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(superorder)#"> <cfelse> ,superorder = NULL </cfif>
				<cfif isdefined("phylorder") and len(phylorder) GT 0> ,phylorder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(phylorder)#"> <cfelse> ,phylorder = NULL </cfif>
				<cfif isdefined("suborder") and len(suborder) GT 0> ,suborder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(suborder)#"> <cfelse> ,suborder = NULL </cfif>
				<cfif isdefined("infraorder") and len(infraorder) GT 0> ,infraorder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(infraorder)#"> <cfelse> ,infraorder = NULL </cfif>
				<cfif isdefined("superfamily") and len(superfamily) GT 0> ,superfamily = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(superfamily)#"> <cfelse> ,superfamily = NULL </cfif>
				<cfif isdefined("family") and len(family) GT 0> ,family = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(family)#"> <cfelse> ,family = NULL </cfif>
				<cfif isdefined("subfamily") and len(subfamily) GT 0> ,subfamily = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subfamily)#"> <cfelse> ,subfamily = NULL </cfif>
				<cfif isdefined("tribe") and len(tribe) GT 0> ,tribe = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(tribe)#"> <cfelse> ,tribe = NULL </cfif>
				<cfif isdefined("division") and len(division) GT 0> ,division = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(division)#"> <cfelse> ,division = NULL </cfif>
				<cfif isdefined("subdivision") and len(subdivision) GT 0> ,subdivision = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subdivision)#"> <cfelse> ,subdivision = NULL </cfif>
				<cfif isdefined("subsection") and len(subsection) GT 0> ,subsection = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subsection)#"> <cfelse> ,subsection = NULL </cfif>
				<cfif isdefined("taxonid_guid_type") and len(taxonid_guid_type) GT 0 and isdefined("taxonid") and len(taxonid) GT 0> 
					,taxonid_guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxonid_guid_type#">
				<cfelse>
					,taxonid_guid_type = NULL
				</cfif>
				<cfif isdefined("taxonid") and len(taxonid) GT 0> ,taxonid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(taxonid)#"> <cfelse> ,taxonid = NULL </cfif>
				<cfif isdefined("scientificnameid_guid_type") and len(scientificnameid_guid_type) GT 0 and isdefined("scientificnameid") and len(scientificnameid) GT 0> 
					,scientificnameid_guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scientificnameid_guid_type#">
				<cfelse>
					,scientificnameid_guid_type = NULL 
				</cfif>
				<cfif isdefined("scientificnameid") and len(scientificnameid) GT 0> ,scientificnameid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(scientificnameid)#"> <cfelse> ,scientificnameid = NULL </cfif>
			where 
				taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "saved">
		<cfset row["id"] = "#taxon_name_id#">
		<cfset data[1] = row>
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

<!---------------------------------------------------------------------------------------------------->
<cffunction name="removeTaxonPub" access="remote" returntype="any" returnformat="json">
	<cfargument name="taxonomy_publication_id" type="numeric" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="removePub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="removePub_result">
			delete from taxonomy_publication 
			where taxonomy_publication_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxonomy_publication_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "deleted">
		<cfset row["id"] = "#taxonomy_publication_id#">
		<cfset data[1] = row>
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

<!---------------------------------------------------------------------------------------------------->
<cffunction name="newTaxonPub" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="numeric" required="yes">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="newTaxonPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newTaxonPub_result">
				INSERT INTO taxonomy_publication 
					(taxon_name_id,publication_id)
				VALUES 
					(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#"> ,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#"> )
			</cfquery>
			<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="pkResult">
					select taxonomy_publication_id from taxonomy_publication
					where ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newTaxonPub_result.GENERATEDKEY#">
			</cfquery>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "added">
		<cfset row["id"] = "#savePK.taxonomy_publication_id#">
		<cfset data[1] = row>
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


<cffunction name="getTaxonNameHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfset result = "">  
	
	<cfquery name="getTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getTaxon_result">
		select display_name, scientific_name, author_text
		from taxonomy 
		where 
			taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
	<cfloop query="getTaxon">
		<cfset result="#getTaxon.display_name# <span class='sm-caps font-weight-normal small90'>#getTaxon.author_text#</span>">
	</cfloop>
	<cfreturn result>
</cffunction>

<cffunction name="getTaxonPublicationsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">

	<cfset result ="">
	<cftry>
		<cfquery name="tax_pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="tax_pub_result">
			select
				taxonomy_publication_id,
				formatted_publication,
				taxonomy_publication.publication_id
			from
				taxonomy_publication,
				formatted_publication
			where
				format_style='long' and
				taxonomy_publication.publication_id=formatted_publication.publication_id and
				taxonomy_publication.taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		</cfquery>
		<cfif tax_pub.recordcount gt 0>
			<cfset result=result & "<div class='col-12 px-0'><ul class='mx-0 col-12 mt-1 mb-3 list-group px-0'>">
			<cfloop query="tax_pub">
				<!--- Create a link out of author year. in the publication, ensure that link closes. --->
				<cfset publication = "<li class='mx-0 mb-1 pl-2 list-group-item border rounded col-12 pr-1'><span class='col-12 col-md-11 px-0 float-left'> <a href='/publications/showPublication.cfm?publication_id=#publication_id#' target='_blank' class='d-inline-block'><img src='/shared/images/48px-Gnome-text-x-preview.svg.png' width='15' height='20' alt='document icon' class='mr-2'>" & rereplace(formatted_publication,'([0-9]\.)','\1</a>') >
					<cfif NOT findNoCase('</a>',publication)><cfset publication = publication & "</a>"></cfif>
						<cfset result=result & " #publication#">
							<cfset result=result & "</span><button class='btn-xs btn-warning ml-2 mr-0 mt-2 mt-md-0 float-right' onclick=' confirmDialog("" Remove Relationship?"",""Remove?"", function() { removeTaxonPub(#taxonomy_publication_id#); } );' value='Remove' title='Remove' aria-label='Remove this Publication from Taxonomy'>Remove</button>">
					<cfset result=result & "</li>">
				</cfloop>
			<cfset result=result & "</ul></div>">
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!--- given a taxon name id, return the higher taxonomy string for that taxon record, leaving off any element after a space 
 that is, return the higher taxonomy from genus up.
 @param taxon_name_id the taxon name for which to return the higher taxonomy
 @return the higher taxonomy from taxonomy.full_taxon_name excluding anything after the first space.
 --->
<cffunction name="getFullTaxonName" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfthread name="getFullTaxonNameThread">
		<cftry>
			<cfquery name="full" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="full_result">
				SELECT full_taxon_name 
				FROM taxonomy
				WHERE
					taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
			</cfquery>
			<cfoutput query = "full">
				#encodeForHTML(ListDeleteAt(full.full_taxon_name,ListLen(full.full_taxon_name," ")," "))#
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getFullTaxonNameThread" />
	<cfreturn getFullTaxonNameThread.output>
</cffunction>

<!---
Given a taxon_name_id retrieve, as html, an editable list of the relationships for that taxon to other taxa.
@param taxon_name_id the PK of the taxon name for which to look up relationshis.
@param target the id of the element in the DOM, without a leading # selector,
  into which the result is to be placed, used to specify target for reload after successful save.
@return a block of html listing relationships, if any, with edit/delete controls.
--->
<cffunction name="getTaxonRelationsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfargument name="target" type="string" required="yes">
	<cfthread name="getRelationsHtmlThread">
		<cftry>
			<cfquery name="taxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="relations_result">
				SELECT scientific_name, author_text
				FROM taxonomy
				WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
			</cfquery>
			<cfset taxonname = "#taxon.scientific_name# <span class='sm-caps'>#taxon.author_text#</span>" >
			<cfquery name="relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="relations_result">
				SELECT
					scientific_name,
					author_text,
					taxon_relationship,
					relation_authority,
					related_taxon_name_id
				FROM
					taxon_relations,
					taxonomy
				WHERE
					taxon_relations.related_taxon_name_id = taxonomy.taxon_name_id
					AND taxon_relations.taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
			</cfquery>
			<cfquery name="inverse_relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="relations_result">
				SELECT
					scientific_name,
					author_text,
					taxon_relations.taxon_relationship,
					cttaxon_relation.inverse_relation,
					relation_authority,
					taxonomy.taxon_name_id
				FROM
					taxon_relations
					left join taxonomy on taxon_relations.taxon_name_id = taxonomy.taxon_name_id
					left join cttaxon_relation on taxon_relations.taxon_relationship = cttaxon_relation.taxon_relationship
				WHERE
					taxon_relations.related_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
			</cfquery>
			<cfset i=0>
			<cfoutput>
				<cfif relations.recordcount gt 0 OR inverse_relations.recordcount gt 0>
					<cfif relations.recordcount gt 0>
						<ul class="mx-0 px-0 mb-1 list-group col-12">
							<cfloop query="relations">
								<cfset i=i+1>
								<!--- PRIMARY KEY ("TAXON_NAME_ID", "RELATED_TAXON_NAME_ID", "TAXON_RELATIONSHIP") --->
								<li class="mx-0 pb-1 mb-1 list-group-item border col-12 col-xl-9 pl-2 pr-0">
									<span class="col-12 col-xl-10 px-1 d-inline-block">	#taxonname# #relations.taxon_relationship#
									<!--- Create a link out of scientific name --->
									<em><a href='/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=#relations.related_taxon_name_id#' target='_blank'>#relations.scientific_name#</a></em>
									<span class='sm-caps'>#relations.author_text#</span>
									<cfif len(relations.relation_authority) GT 0>
										 fide #relations.relation_authority# 
										</cfif></span>
									<button class='btn-xs btn-warning mx-1 mt-2 mt-md-0 float-right' 
										onclick=' confirmDialog(" Remove Relationship?","Remove?", function() { deleteTaxonRelation(#taxon_name_id#,#relations.related_taxon_name_id#,"#relations.taxon_relationship#","#target#"); }); ' 
										value='Remove' title='Remove' aria-label='Remove this Relation from Taxonomy'>Remove</button>
									<button class='btn-xs btn-secondary mx-1 mt-2 mt-md-0 float-right' onclick='openEditTaxonRelationDialog(#taxon_name_id#,#relations.related_taxon_name_id#,"#relations.taxon_relationship#","editTaxonRelationDialog","#target#");' value='Edit' 
										title='Edit' aria-label='Edit this Taxon Relation'>Edit</button>
					
									</li>
							</cfloop>
						</ul>
					<cfelse>
						<ul class="px-4 mt-2 list-style-disc"><li>No relationships from this taxon</li></ul>
					</cfif>
					<cfif inverse_relations.recordcount gt 0>
						<ul class="mx-0 px-4 mt-2 list-style-circle">
							<cfloop query="inverse_relations">
								<cfset i=i+1>
								<li class="mb-1">
									<span class="col-12 col-xl-10 px-1 d-inline-block">
										#taxonname#
										#inverse_relations.inverse_relation# 
										<em><a href='/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=#inverse_relations.taxon_name_id#' target='_blank'>#inverse_relations.scientific_name#</a></em>
										<span class='sm-caps'>#inverse_relations.author_text#</span>
										<cfif len(inverse_relations.relation_authority) GT 0>
											 fide #inverse_relations.relation_authority# 
										</cfif>
									</span>
								</li>
							</cfloop>
						</ul>
					<cfelse>
						<ul class="px-4 mt-2 list-style-circle"><li>No relationships to this taxon</li></ul>
					</cfif>
				<cfelse>
					<ul class="px-4 mt-2 list-style-disc"><li>No Taxon Relationships</li></ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getRelationsHtmlThread" />
	<cfreturn getRelationsHtmlThread.output>
</cffunction>


<!--- TODO: dialog for editing a taxon relationship --->
<cffunction name="getTaxonRelationEditor" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfargument name="related_taxon_name_id" type="numeric" required="yes">
	<cfargument name="taxon_relationship" type="string" required="yes">
	<cfargument name="target" type="string" required="yes">
	<cfquery name="ctRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select taxon_relationship  from cttaxon_relation order by taxon_relationship
	</cfquery>
	<cfthread name="getRelationEditorHtmlThread">
		<cftry>
			<cfquery name="relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="relations_result">
				SELECT
					p.scientific_name sourcename,
					p.author_text sourceauthor,
					taxon_relationship,
					relation_authority,
					related_taxon_name_id,
					c.scientific_name targetname,
					c.author_text targetauthor
				FROM
					taxon_relations 
					left join taxonomy p on taxon_relations.taxon_name_id = p.taxon_name_id
					left join taxonomy c on taxon_relations.related_taxon_name_id = c.taxon_name_id
				WHERE
					taxon_relations.taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
					AND taxon_relations.related_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_taxon_name_id#">
					AND taxon_relations.taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_relationship#">
			</cfquery>
			<cfset i=0>
			<cfoutput>
				<cfloop query="relations">
					<cfset i=i+1>
					<form id="relationEditForm_#i#">
						<div class="form-row">
							<input type="hidden" name="related_taxon_name_id" value="#related_taxon_name_id#" id="orig_related_taxon_name_id_#i#">
							<input type="hidden" name="origTaxon_Relationship" value="#taxon_relationship#" id="orig_taxon_relationship_#i#">
							<div class="col-12">
								<h2 class="h3">#sourcename# <span class="sm-caps">#sourceauthor#</span> is a/an</h2>
							</div>
							<div class="col-12">
								<label for="taxon_relationship_EF#i#" class="data-entry-label">Relationship</label>
								<select name="taxon_relationship" class="reqdClr custom-select data-entry-select" id="new_taxon_relationship_#i#" required>
									<cfloop query="ctRelation">
										<cfset selected = "">
										<cfif ctRelation.taxon_relationship is relations.taxon_relationship>
											<cfset selected="selected='selected'">
										</cfif>
										<option #selected# value="#ctRelation.taxon_relationship#">#ctRelation.taxon_relationship# </option>
									</cfloop>
								</select>
							</div>
							<div class="col-12">
								<label for="relatedName_EF#i#" class="data-entry-label">Related Taxon </label>
								<input type="text" name="relatedName" class="reqdClr data-entry-input" required
									value="#relations.targetname# #relations.targetauthor#" id="relatedName_EF#i#" >
								<input type="hidden" name="newRelatedId" id="new_related_taxon_name_id_#i#" value="#related_taxon_name_id#">
							</div>
							<div class="col-12">
								<input type="text" name="relation_authority" value="#relations.relation_authority#" class="data-entry-input" id="new_relation_authority_#i#">
							</div>
							<div class="col-12">
								<input type="button" value="Save" class="btn-xs btn-primary" onclick=" saveRelEFChanges(#i#); ">
								<output id="editTaxonRelationFeedback#i#" style="display: none;"></output>
							</div>
						</div>
					</form>
					<script>
						$(document).ready( function() { 
							makeScientificNameAutocompleteMeta('relatedName_EF#i#', 'new_related_taxon_name_id_#i#');
							$('##relationEditForm_#i#').submit( function(event){ event.preventDefault(); } );
						});
					</script>
				</cfloop>
				<script>
					function saveRelEFChanges(counter) { 
						if ($('##relationEditForm_'+counter)[0].checkValidity()) { 
							if ($('##new_related_taxon_name_id_'+counter).val() == "") { 
								messageDialog('Error: Unable to save relationship, you must pick a related taxon from the picklist, click Close Dialog on relationship edit dialog to exit without saving changes.' ,'Error: No related taxon selected');
							} else { 
								saveTaxonRelation(
									#taxon_name_id#,
									$('##orig_related_taxon_name_id_'+counter).val(),
									$('##orig_taxon_relationship_'+counter).val(),
									$('##new_related_taxon_name_id_'+counter).val(),
									$('##new_taxon_relationship_'+counter).val(),
									$('##new_relation_authority_'+counter).val(),
									"#target#",
									"editTaxonRelationFeedback"+counter
								);
							};
						};
					};
				</script>
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getRelationEditorHtmlThread" />
	<cfreturn getRelationEditorHtmlThread.output>
</cffunction>

<!--- function newTaxonRelation 
 Given a a taxon_name_id, related taxon name id, relationship, and optional authority add a row from the (weak entity) taxon_relations table.
 @param taxon_name_id the PK of the taxonomy record to which the relationship is to be made
 @param newRelatedId the PK of the taxonomy record which is to be related to the taxon_name_id record
 @param taxon_relationship the type of relationship between the two taxa.
 @param relation_authority the authority to which the relationship can be attributed.
--->
<cffunction name="newTaxonRelation" access="remote" returntype="any" returnformat="json">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfargument name="newRelatedId" type="numeric" required="yes">
	<cfargument name="taxon_relationship" type="string" required="yes">
	<cfargument name="relation_authority" type="string" required="no">
	<cftry>
		<cftransaction>
			<cfquery name="newRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newRelation_result">
				INSERT INTO taxon_relations (
					TAXON_NAME_ID,
					RELATED_TAXON_NAME_ID,
					TAXON_RELATIONSHIP,
					RELATION_AUTHORITY
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#TAXON_NAME_ID#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newRelatedId#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TAXON_RELATIONSHIP#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RELATION_AUTHORITY#">
				)
			</cfquery>
			<cfif newRelation_result.recordcount NEQ 1>
				<cftransaction action="rollback"/>
				<cfthrow message="Other than one row (#newRelation_result.recordcount#) inserted.  Insert canceled and rolled back">
			</cfif>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "added">
		<cfset data[1] = row>
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
Given a taxon relationship and a taxon_name_id, delete the matching row from the (weak entity) taxon_relations table.
@param taxon_relationship a text string representing a taxon relationship of a taxon, together with taxon_name_id and 
 related taxon name id forms PK of taxon_relations table.
@param taxon_name_id the PK of the taxon for which to remove the matching taxon relationship.
@param related_taxon_name_id the PK of the related taxon for which to remove the matching taxon relationship.
--->
<cffunction name="deleteTaxonRelation" access="remote" returntype="any" returnformat="json">
	<cfargument name="taxon_relationship" type="string" required="yes">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfargument name="related_taxon_name_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="deleteTaxonRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteTaxonRelation_result">
				DELETE FROM
					taxon_relations
				WHERE
					taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
					AND taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_relationship#">
					AND related_taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_taxon_name_id#">
			</cfquery>
			<cfif deleteTaxonRelation_result.recordcount NEQ 1>
				<cftransaction action="rollback"/>
				<cfthrow message="Other than one row (#deleteTaxonRelation_result.recordcount#) would be deleted.  Delete canceled and rolled back">
			</cfif>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "deleted">
		<cfset data[1] = row>
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
Given old and new taxon_name_id, related taxon name id, and relationship values along with an 
authority, update a row in the taxon_relations table.  

@param orig_taxon_relationship a text string representing the current relationship type.
@param new_taxon_relationship a text string representing the new relationship type.
@param orig_taxon_name_id the PK of the taxon name to which the relationship belongs.
@param new_taxon_name_id optional the PK of the taxon name to be changed for the relationship (moves the relationship to a different taxon).
@param orig_related_taxon_name_id the PK of the taxon name on the other side of the relationship.
@param new_related_taxon_name_id the PK of the taxon name on the other side of the relationship.
@param relation_authority a text string representing the source authority for the relationship, 
  if an empty string will set existing value to null, to retain rather than overwrite an
  existing value, the existing value must be passed along in this parameter.
@return a json data structure contaning the status of the save, or an http 500 error.
--->
<cffunction name="saveTaxonRelationEdit" access="remote" returntype="any" returnformat="json">
	<cfargument name="orig_taxon_name_id" type="numeric" required="yes">
	<cfargument name="new_taxon_name_id" type="numeric" required="no"><!--- possible to change, but not needed --->
	<cfargument name="orig_related_taxon_name_id" type="numeric" required="yes">
	<cfargument name="new_related_taxon_name_id" type="numeric" required="yes">
	<cfargument name="orig_taxon_relationship" type="string" required="yes">
	<cfargument name="new_taxon_relationship" type="string" required="yes">
	<cfargument name="relation_authority" type="string" required="yes"><!--- if empty string will set to null, but must be provided --->
	<cftry>
		<cftransaction>
			<cfquery name="saveTaxonRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="saveTaxonRelation_result">
				UPDATE taxon_relations SET
					taxon_relationship = '#new_taxon_relationship#'
					,related_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_related_taxon_name_id#">
					<cfif len(#relation_authority#) gt 0>
						,relation_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relation_authority#">
					<cfelse>
						,relation_authority = null
					</cfif>
					<cfif isdefined("new_taxon_name_id") AND len(#new_taxon_name_id#) gt 0 >
						,taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_taxon_name_id#">
					</cfif>
					WHERE
						taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#orig_taxon_name_id#">
						AND Taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#orig_taxon_relationship#">
						AND related_taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#orig_related_taxon_name_id#">
			</cfquery>
			<cfif saveTaxonRelation_result.recordcount NEQ 1>
				<cftransaction action="rollback"/>
				<cfthrow message="Other than one row (#saveTaxonRelation_result.recordcount#) affected by update, edit canceled and rolled back">
			</cfif>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "saved">
		<cfset data[1] = row>
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
Given a taxon_name_id retrieve, as html, an editable list of the common names for that taxon.
@param taxon_name_id the PK of the taxon name for which to look up common names.
@param target the id of the element in the DOM, without a leading # selector,
  into which the result is to be placed, used to specify target for reload after successful save.
@return a block of html listing common names, if any, with edit/delete controls.
--->
<cffunction name="getCommonHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfargument name="target" type="string" required="yes">
	
	<cfset taxon_name_id = arguments.taxon_name_id>
	<cfset localtarget = arguments.target>
	<cfthread name="getCommonHtmlThread">
		<cftry>
			<cfquery name="common" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="common_result">
				select common_name, common_name_id
				from common_name 
				where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
			</cfquery>
			<cfoutput>
				<h2 class="h3 mt-0 px-1">Common Names</h2>
				<cfset i=1>
				<cfif common.recordcount gt 0>
					<cfloop query="common">
						<form name="common#i#" class="row mx-0" action="" onClick=" function(e){e.preventDefault();};">
							<ul class="mx-0 px-0 mb-1 list-group col-12">
								<li class="mx-0 pb-1 list-group-item border col-12 col-xl-9 px-1">
									<script>
										function doDeleteCN_#i#(){ 
											deleteCommonName(#common_name_id#,#taxon_name_id#,'#localtarget#');
										};
										function toggleCommon#i#(){
											$('##label_common_name_#i#').toggle();
											$('##common_name_#i#').toggle();
											$('##commonSaveButton_#i#').toggle();
											$('##commonEditButton_#i#').toggle();
										};
									</script>
									<label id="label_common_name_#i#" value="#common_name#" class="w-auto float-left pt-1 px-2" 
										onClick="toggleCommon#i#()">#encodeForHtml(common_name)#</label>
									<input id="common_name_#i#" type="text" name="common_name" value="#encodeForHtml(common_name)#" 
										class="data-entry-input w-75 float-left" style="display: none;">
									<input type="button" value="Delete" class="btn btn-xs btn-danger ml-1 my-0 float-right" 
										id="commonDeleteButton_#i#">
									<input type="button" value="Save" class="btn btn-xs btn-secondary ml-1 my-0 float-right" 
										id="commonSaveButton_#i#"
										style="display: none;">
									<input type="button" value="Edit" class="btn btn-xs btn-secondary ml-1 my-0 float-right" 
										onClick="toggleCommon#i#()" 
										id="commonEditButton_#i#"
										>
									
									<script>
										$(document).ready(function () {
											$('##commonDeleteButton_#i#').click(function(evt){
												evt.preventDefault();
												confirmWarningDialog('Delete <b>#encodeForHtml(common_name)#</b> common name entry','Confirm Delete?', doDeleteCN_#i#);
											});
											$('##commonSaveButton_#i#').click(function(evt){
												evt.preventDefault();
												saveCommon(#common_name_id#,$('##common_name_#i#').val(),#taxon_name_id#,'#localtarget#');
											});
										});
									</script>
								</li>
							</ul>
						</form>
						<cfset i=i+1>
					</cfloop>
				<cfelse>
					<ul class="px-4 list-style-disc"><li>No Common Names Entered</li></ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getCommonHtmlThread" />
	<cfreturn getCommonHtmlThread.output>
</cffunction>

<!---
Given a common name and a taxon_name_id, add a row from the (weak entity) common_name table.
@param common_name a text string representing a common name of a taxon, together with taxon_name_id forms PK of common_name table.
@param taxon_name_id the PK of the taxon name for which to add the matching common name.
--->
<cffunction name="newCommon" access="remote" returntype="any" returnformat="json">
	<cfargument name="common_name" type="string" required="yes">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="newCommon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newCommon_result">
				INSERT INTO common_name (
					common_name, 
					taxon_name_id)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#common_name#"> , 
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#"> 
				)
			</cfquery>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "added">
		<cfset data[1] = row>
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
Given a common name and a taxon_name_id, delete the matching row from the common_name table.
@param common_name_id the PK of the common name to fremove
--->
<cffunction name="deleteCommon" access="remote" returntype="any" returnformat="json">
	<cfargument name="common_name_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="deleteCommon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteCommon_result">
				DELETE FROM common_name
				WHERE
					common_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#common_name_id#">
			</cfquery>
			<cfif deleteCommon_result.recordcount NEQ 1>
				<cftransaction action="rollback"/>
				<cfthrow message="Other than one row (#deleteCommon_result.recordcount#) would be deleted.  Delete canceled and rolled back">
			</cfif>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "deleted">
		<cfset data[1] = row>
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
Given common_name_id and new common name, update a row in the common name table
@param common_name_id the common name to update  a text string representing a common name of a taxon to update to.
@param common_name a text string representing a common name of a taxon to update to.
--->
<cffunction name="saveCommon" access="remote" returntype="any" returnformat="json">
	<cfargument name="common_name_id" type="string" required="yes">
	<cfargument name="common_name" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="saveCommon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="saveCommon_result">
				UPDATE
					common_name
				SET
					common_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(common_name)#">
				WHERE
					common_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#common_name_id#">
			</cfquery>
			<cfif saveCommon_result.recordcount NEQ 1>
				<cftransaction action="rollback"/>
				<cfthrow message="Other than one row (#saveCommon_result.recordcount#) affected by update, edit canceled and rolled back">
			</cfif>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "saved">
		<cfset row["newname"] = "#common_name#">
		<cfset data[1] = row>
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
Given a habitat and a taxon_name_id, add a row from the taxon_habitat table.
@param taxon_habitat a text string representing a habitat.
@param taxon_name_id the PK of the taxon name for which to add the matching common name.
@return a json structure the status and the id of the new taxon_habitat row.
--->
<cffunction name="newHabitat" access="remote" returntype="any" returnformat="json">
	<cfargument name="taxon_habitat" type="string" required="yes">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="newHabitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newHabitat_result">
				INSERT INTO taxon_habitat 
					(taxon_habitat, taxon_name_id)
				VALUES 
					(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_habitat#">, 
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">)
			</cfquery>
			<cfif newHabitat_result.recordcount eq 1>
				<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="pkResult">
					select taxon_habitat_id from taxon_habitat
					where ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newHabitat_result.GENERATEDKEY#">
				</cfquery>
			<cfelse>
				<cftransaction action="rollback">
				<cfthrow message="Other than one row (#newHabitat_result.recordcount#) would be added, insert canceled and rolled back">
			</cfif>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "added">
		<cfset row["id"] = "#savePK.taxon_habitat_id#">
		<cfset data[1] = row>
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
Given a taxon_habitat_id, delete the matching row from the taxon_habitat table.
@param taxon_habitat_id the PK value for the row to remove from the taxon_habitat table.
@return a data structure with status or an http 400 status.
--->
<cffunction name="deleteHabitat" access="remote" returntype="any" returnformat="json">
	<cfargument name="taxon_habitat_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="deleteHabitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteHabitat_result">
				DELETE FROM
					taxon_habitat
				WHERE
					taxon_habitat_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_habitat_id#">
			</cfquery>
			<cfif deleteHabitat_result.recordcount NEQ 1>
				<cftransaction action="rollback"/>
				<cfthrow message="Other than one row (#deleteHabitat_result.recordcount#) would be deleted.  Delete canceled and rolled back">
			</cfif>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "deleted">
		<cfset data[1] = row>
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
Given a taxon_name_id retrieve, as html, an editable list of the habitats for that taxon.
@param taxon_name_id the PK of the taxon name for which to look up habitats.
@param target the id of the element in the DOM, without a leading # selector,
  into which the result is to be placed, used to specify target for reload after successful save.
@return a block of html listing habitats, if any, with edit/delete controls.
--->
<cffunction name="getHabitatsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfargument name="target" type="string" required="yes">
	<cfthread name="getHabitatsHtmlThread">
		<cftry>
			<cfquery name="habitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select taxon_habitat, taxon_habitat_id
				from taxon_habitat 
				where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
			</cfquery>
			<cfoutput>
				<cfset i=1>
				<cfif habitat.recordcount gt 0>
					<cfloop query="habitat">
						<ul class="mx-0 px-0 my-0 list-group">
							<li class="mx-0 mb-1 list-group-item border col-12 col-xl-9 px-1">
								<label id="label_taxon_habitat_#i#" value="#taxon_habitat#" class="w-75 float-left pt-1 px-2">#taxon_habitat#</label>
								<button value="Remove" class="btn btn-xs btn-warning my-0 float-right" onClick=" confirmDialog('Remove <b>#taxon_habitat#</b> habitat entry from this taxon?','Remove Habitat?', function() { deleteHabitat(#taxon_habitat_id#,#taxon_name_id#,'#target#'); } ); " 
								id="habitatDeleteButton_#i#">Remove</button>
							</li>
						</ul>
						<cfset i=i+1>
					</cfloop>
				<cfelse>
					<ul class="px-4 list-style-disc"><li>No Habitats Entered</li></ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getHabitatsHtmlThread" />
	<cfreturn getHabitatsHtmlThread.output>
</cffunction>

<cffunction name="lookupInWoRMS" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfset data = ArrayNew(1)>
	<cfthread name="lookupInWoRMSThread">
		<cftry>
			<cfquery name="taxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="taxon_lookup">
				select taxon_name_id, kingdom, family, scientific_name, author_text
				from taxonomy 
				where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
			</cfquery>
			<cfoutput query="taxon">
				<cfobject type="Java" class="edu.harvard.mcz.nametools.NameUsage" name="nameUsage">
				<cfobject type="Java" class="org.filteredpush.qc.sciname.services.WoRMSService" name="wormsService">
	
				<cfset inputName = nameUsage.init()>
				<cfset validator = wormsService.init(false)>
				<cfset void = inputName.setInputDbPK(taxon.taxon_name_id) >
				<cfset void = inputName.setScientificName(taxon.scientific_name) >
				<cfset void = inputName.setAuthorship(taxon.author_text) >
				<cfif  len(taxon.kingdom) GT 0> 
					<cfset void = inputName.setKingdom(taxon.kingdom)>
				</cfif>
				<cfif  len(taxon.family) GT 0> 
					<cfset void = inputName.setFamily(taxon.family)>
				</cfif>
					
				<cfset outputMatch = validator.validate(inputName)>
	
				<cfif outputMatch NEQ null>
					<cfset row = StructNew()>
					<cfset row["match"] = outputMatch.getMatchDescription()>
					<cfset row["guid"] = outputMatch.getGuid()>
					<cfset row["scientific_name"] = outputMatch.getScientificName()>
					<cfset row["authorship"] = outputMatch.getAuthorship()>
					<cfset habitats = outputMatch.getExtension()>
					<cfset row["marine"] = habitats.get("marine")>
					<cfset row["brackish"] = habitats.get("brackish")>
					<cfset row["freshwater"] = habitats.get("freshwater")>
					<cfset row["terrestrial"] = habitats.get("terrestrial")>
					<cfset row["extinct"] = habitats.get("extinct")>
					<cfset data[1] = row>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="lookupInWoRMSThread" />
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
