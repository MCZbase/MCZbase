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
		<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update taxonomy set
				valid_catalog_term_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">
				,source_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#source_authority#">
				,nomenclatural_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nomenclatural_code#">
				<cfif isdefined("taxon_status") and len(taxon_status) GT 0>
					,taxon_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_status#">
				<cfelse>
					,taxon_status = NULL </cfif>
				<cfif isdefined("taxon_remarks") and len(taxon_remarks) GT 0>
					,taxon_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_remarks#">
				<cfelse> 
					,taxon_remarks = NULL
				</cfif>
				<cfif isdefined("genus") and len(genus) GT 0> ,genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#genus#"> <cfelse> ,genus = NULL </cfif>
				<cfif isdefined("subgenus") and len(subgenus) GT 0> ,subgenus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#subgenus#"> <cfelse> ,subgenus = NULL </cfif>
				<cfif isdefined("species") and len(species) GT 0> ,species = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#species#"> <cfelse> ,species = NULL </cfif>
				<cfif isdefined("subspecies") and len(subspecies) GT 0> ,subspecies = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#subspecies#"> <cfelse> ,subspecies = NULL </cfif>
				<cfif isdefined("author_text") and len(author_text) GT 0> ,author_text = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#author_text#"> <cfelse> ,author_text = NULL </cfif>
				<cfif isdefined("infraspecific_rank") and len(infraspecific_rank) GT 0> ,infraspecific_rank = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#infraspecific_rank#"> <cfelse> ,infraspecific_rank = NULL </cfif>
				<cfif isdefined("infraspecific_author") and len(infraspecific_author) GT 0> ,infraspecific_author = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#infraspecific_author#"> <cfelse> ,infraspecific_author = NULL </cfif>
				<cfif isdefined("kingdom") and len(kingdom) GT 0> ,kingdom = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#kingdom#"> <cfelse> ,kingdom = NULL </cfif>
				<cfif isdefined("phylum") and len(phylum) GT 0> ,phylum = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#phylum#"> <cfelse> ,phylum = NULL </cfif>
				<cfif isdefined("subphylum") and len(subphylum) GT 0> ,subphylum = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#subphylum#"> <cfelse> ,subphylum = NULL </cfif>
				<cfif isdefined("superclass") and len(superclass) GT 0> ,superclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#superclass#"> <cfelse> ,superclass = NULL </cfif>
				<cfif isdefined("phylclass") and len(phylclass) GT 0> ,phylclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#phylclass#"> <cfelse> ,phylclass = NULL </cfif>
				<cfif isdefined("subclass") and len(subclass) GT 0> ,subclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#subclass#"> <cfelse> ,subclass = NULL </cfif>
				<cfif isdefined("infraclass") and len(infraclass) GT 0> ,infraclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#infraclass#"> <cfelse> ,infraclass = NULL </cfif>
				<cfif isdefined("superorder") and len(superorder) GT 0> ,superorder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#superorder#"> <cfelse> ,superorder = NULL </cfif>
				<cfif isdefined("phylorder") and len(phylorder) GT 0> ,phylorder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#phylorder#"> <cfelse> ,phylorder = NULL </cfif>
				<cfif isdefined("suborder") and len(suborder) GT 0> ,suborder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#suborder#"> <cfelse> ,suborder = NULL </cfif>
				<cfif isdefined("infraorder") and len(infraorder) GT 0> ,infraorder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#infraorder#"> <cfelse> ,infraorder = NULL </cfif>
				<cfif isdefined("superfamily") and len(superfamily) GT 0> ,superfamily = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#superfamily#"> <cfelse> ,superfamily = NULL </cfif>
				<cfif isdefined("family") and len(family) GT 0> ,family = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#family#"> <cfelse> ,family = NULL </cfif>
				<cfif isdefined("subfamily") and len(subfamily) GT 0> ,subfamily = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#subfamily#"> <cfelse> ,subfamily = NULL </cfif>
				<cfif isdefined("tribe") and len(tribe) GT 0> ,tribe = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#tribe#"> <cfelse> ,tribe = NULL </cfif>
				<cfif isdefined("division") and len(division) GT 0> ,division = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#division#"> <cfelse> ,division = NULL </cfif>
				<cfif isdefined("subdivision") and len(subdivision) GT 0> ,subdivision = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#subdivision#"> <cfelse> ,subdivision = NULL </cfif>
				<cfif isdefined("subsection") and len(subsection) GT 0> ,subsection = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#subsection#"> <cfelse> ,subsection = NULL </cfif>
				<cfif isdefined("taxonid_guid_type") and len(taxonid_guid_type) GT 0 and isdefined("taxonid") and len(taxonid) GT 0> 
					,taxonid_guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxonid_guid_type#">
				<cfelse>
					,taxonid_guid_type = NULL
				</cfif>
				<cfif isdefined("taxonid") and len(taxonid) GT 0> ,taxonid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxonid#"> <cfelse> ,taxonid = NULL </cfif>
				<cfif isdefined("scientificnameid_guid_type") and len(scientificnameid_guid_type) GT 0 and isdefined("scientificnameid") and len(scientificnameid) GT 0> 
					,scientificnameid_guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scientificnameid_guid_type#">
				<cfelse>
					,scientificnameid_guid_type = NULL 
				</cfif>
				<cfif isdefined("scientificnameid") and len(scientificnameid) GT 0> ,scientificnameid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scientificnameid#"> <cfelse> ,scientificnameid = NULL </cfif>
			where 
				taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "saved">
		<cfset row["id"] = "#taxon_name_id#">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing saveTaxonomy: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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

<!---------------------------------------------------------------------------------------------------->
<cffunction name="removeTaxonPub" access="remote" returntype="any" returnformat="json">
	<cfargument name="taxonomy_publication_id" type="numeric" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="removePub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="removePub_result">
			delete from taxonomy_publication 
			where taxonomy_publication_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxonomy_publication_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "deleted">
		<cfset row["id"] = "#taxonomy_publication_id#">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()# " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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

<!---------------------------------------------------------------------------------------------------->
<cffunction name="newTaxonPub" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="numeric" required="yes">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="newTaxonPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newTaxonPub_result">
				INSERT INTO taxonomy_publication 
					(taxon_name_id,publication_id)
				VALUES 
					(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#"> ,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#"> )
			</cfquery>
			<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="pkResult">
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
		<cfset message = trim("Error processing #GetFunctionCalledName()# " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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


<cffunction name="getTaxonNameHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfset result = "">  

		<cfquery name="getTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getTaxon_result">
			select  scientific_name, author_text
			from taxonomy 
			where 
				taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		</cfquery>
		<cfloop query="getTaxon">
			<cfset result="<em>#getTaxon.scientific_name#</em> <span class='sm-caps'>#getTaxon.author_text#</span>">
		</cfloop>

	<cfreturn result>
</cffunction>

<cffunction name="getTaxonPublicationsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">

	<cfset result ="">
	<cftry>
		<cfquery name="tax_pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="tax_pub_result">
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
			<cfloop query="tax_pub">
				<cfset result=result & "<div class='col-12 my-2 px-1'>">
				<!--- Create a link out of author year. in the publication, ensure that link closes. --->
				<cfset publication = "<a href='SpecimenUsage.cfm?publication_id=#publication_id#' target='_blank'>" & rereplace(formatted_publication,'([0-9]\.)','\1</a>') >
				<cfif NOT findNoCase('</a>',publication)><cfset publication = publication & "</a"></cfif>
				<cfset result=result & "#publication#">
				<cfset result=result & "<button class='btn-xs btn-secondary mx-1' onclick='removeTaxonPub(#taxonomy_publication_id#);' value='Remove' title='Remove' aria-label='Remove this Publication from Taxonomy'>Remove</button>">
				<cfset result=result & "</div>">
				</cfloop>
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()# " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
	<cfreturn result>
</cffunction>


<cffunction name="getTaxonRelationsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">
	<cfset result ="">
	<cftry>
		<cfquery name="relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="relations_result">
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
		<cfif relations.recordcount gt 0>
			<cfloop query="relations">
				<!--- PRIMARY KEY ("TAXON_NAME_ID", "RELATED_TAXON_NAME_ID", "TAXON_RELATIONSHIP") --->
				<cfset result=result & "<li>">
				<cfset result=result & "#relations.taxonrelationship# ">
				<!--- Create a link out of scientific name --->
				<cfset taxonname = "<em><a href='/taxonomy/Taxonomy.cfm?taxon_name_id=#relations.related_taxon_name_id#' target='_blank'>#relations.scientific_name#</a></em>">
				<cfset taxonname = taxonname & "<span class='sm-caps'>#relations.author_text#</span>">
				<cfset result=result & "#taxonname# ">
				<cfif len(relations.relation_authority) GT 0>
					<cfset result=result & " fide #relations.relation_authority# ">
				</cfif>
				<cfset result=result & "<button class='btn-xs btn-secondary mx-1' onclick='editTaxonRelation(#taxon_name_id#,#relations.related_taxon_name_id#,#relations.taxon_relationship#);' value='Edit' title='Edit' aria-label='Edit this Taxon Relation'>Edit</button>">
				<cfset result=result & "<button class='btn-xs btn-secondary mx-1' onclick='removeTaxonRelation(#taxon_name_id#,#relations.related_taxon_name_id#,#relations.taxon_relationship#);' value='Remove' title='Remove' aria-label='Remove this Relation from Taxonomy'>Remove</button>">
				<cfset result=result & "</li>">
				</cfloop>
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()# " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
	<cfreturn result>
</cffunction>

<cffunction name="getTaxonRelationsHtml" returntype="string" access="remote" returnformat="plain">
							<form name="relation#i#" method="post" action="/taxonomy/Taxonomy.cfm">
								<input type="hidden" name="taxon_name_id" value="#getTaxa.taxon_name_id#">
								<input type="hidden" name="Action">
								<input type="hidden" name="related_taxon_name_id" value="#related_taxon_name_id#">
								<input type="hidden" name="origTaxon_Relationship" value="#taxon_relationship#">
								<select name="taxon_relationship" class="reqdClr custom-select data-entry-select">
									<cfloop query="ctRelation">
										<option <cfif ctRelation.taxon_relationship is relations.taxon_relationship>
									selected="selected" </cfif>value="#ctRelation.taxon_relationship#">#ctRelation.taxon_relationship# </option>
									</cfloop>
								</select>
								<input type="text" name="relatedName" class="reqdClr data-entry-input" value="#relations.scientific_name#" onChange="taxaPick('newRelatedId','relatedName','relation#i#',this.value); return false;"
								onKeyPress="return noenter(event);">
								<input type="hidden" name="newRelatedId">
								<input type="text" name="relation_authority" value="#relations.relation_authority#" class="data-entry-input">
								<input type="button" value="Save" class="btn-xs btn-primary" onclick="relation#i#.Action.value='saveRelnEdit';submit();">
								<input type="button" value="Delete" class="btn-xs btn-warning" onclick="relation#i#.Action.value='deleReln';confirmDelete('relation#i#');">
							</form>
</cfcomponent>
