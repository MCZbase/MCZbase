<cfoutput>
	<cfif NOT isdefined("taxon_name_id")>
		<h3>No taxon name id provided to look up related taxon records.</h3>
	<cfelse>
		<cfquery name="t" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select TAXON_NAME_ID, PHYLCLASS, PHYLORDER, SUBORDER, FAMILY, SUBFAMILY, GENUS, SUBGENUS, SPECIES,
				SUBSPECIES, VALID_CATALOG_TERM_FG, SOURCE_AUTHORITY, FULL_TAXON_NAME, SCIENTIFIC_NAME, AUTHOR_TEXT, TRIBE,
				INFRASPECIFIC_RANK, TAXON_REMARKS, PHYLUM, SUPERFAMILY, SUBPHYLUM, SUBCLASS, KINGDOM, NOMENCLATURAL_CODE,
				INFRASPECIFIC_AUTHOR, INFRAORDER, SUPERORDER, DIVISION, SUBDIVISION, SUPERCLASS, DISPLAY_NAME, TAXON_STATUS,
				GUID, INFRACLASS, SUBSECTION, TAXONID_GUID_TYPE, TAXONID, SCIENTIFICNAMEID_GUID_TYPE, SCIENTIFICNAMEID 
			from taxonomy 
			where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		</cfquery>
		<cfif len(t.species) gt 0 and len(t.genus) gt 0>
			<div class="col-12 col-lg-6">
				<cfquery name="genus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
					select scientific_name, display_name, author_text 
					from taxonomy 
					where 
						genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and 
						subgenus is null and 
						species is null and 
						subspecies is null
				</cfquery>
				<cfif len(genus.scientific_name) gt 0>
					<p>Parent Genus: <a href="/name/#genus.scientific_name#">#genus.display_name# <span class="sm-caps">#genus.author_text#</span></a></p>
				<cfelse>
					<p>There is no taxonomy record in MCZbase for the genus #t.genus#
				</cfif>
			</div>
			<div class="col-12 col-lg-6">
				<cfif len(t.subspecies) gt 0>
					<cfquery name="ssp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
						select scientific_name, display_name, author_text
						from taxonomy 
						where 
							genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and 
							species = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.species#"> and 
							subspecies is null
					</cfquery>
					<cfif len(ssp.scientific_name) gt 0>
						<p>Parent Species: <a href="/name/#ssp.scientific_name#">#ssp.display_name# <span class="sm-caps">#ssp.author_text#</span></a></p>
					<cfelse>
						<p>There is no taxonomy record in MCZbase for the species #t.genus# #t.species#
					</cfif>
				</cfif>
			</div>
			<div class="accordion w-100" id="accordionForTaxa">
					<div class="card mb-2">
						<div class="card-header w-100" id="headingPart">
							<h2 class="h4 my-0 float-left">  <a class="btn-link text-black" role="button" data-toggle="collapse" data-target="##collapseRelatedTaxa">Related Taxon Records: </a></h2>
						</div>
						<div class="card-body px-3 py-0">
					
							<div id="collapseRelatedTaxa" class="collapse" aria-labelledby="headingPart" data-parent="##accordionForTaxa">
										<div class="row">
			<div class="col-12 col-lg-6">
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
					select 
						scientific_name, display_name, author_text
					from 
						taxonomy 
					where
						 genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and 
						 species = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.species#"> and 
						 subspecies is not null and
						 scientific_name != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.scientific_name#">
					order by
						scientific_name
				</cfquery>
				<cfif d.recordcount gt 0>
					<br><cfif len(t.subspecies) gt 0>Related </cfif>Subspecies:
				</cfif>
				<ul>
					<cfloop query="d">
						<li><a href="/name/#scientific_name#">#display_name# <span class="sm-caps">#d.author_text#</span></a></li>
					</cfloop>
				</ul>
			</div>
			<div class="col-12 col-lg-6">
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
					select 
						scientific_name,
						display_name 
					from 
						taxonomy 
					where
						 genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and 
						 species != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.species#"> and
						 subspecies is null
					order by
						scientific_name
				</cfquery>
				<cfif d.recordcount gt 0>
					<br>Related Species:
				</cfif>
				<ul>
					<cfloop query="d">
						<li><a href="/name/#scientific_name#">#display_name#</a></li>
					</cfloop>
				</ul>
			</div>
					</div>
		<cfelseif len(t.genus) gt 0 and len(t.species) is 0>
			<div class="col-12">
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
					select 
						scientific_name, display_name, author_text
					from taxonomy 
					where
						 genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and
						 species is not null and
						 subspecies is null
					order by
						scientific_name
				</cfquery>
				<cfif d.recordcount gt 0>
					<br>Included Species:
				</cfif>
				<ul>
					<cfloop query="d">
						<li><a href="/name/#scientific_name#">#display_name# <span class="sm-caps">#d.author_text#</span></a></li>
					</cfloop>
				</ul>
			</div>
		</cfif>
			</div>
					</div></div></div>
	</cfif>
</cfoutput>
