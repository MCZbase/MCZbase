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
			<!--- parent genus for subgenera, species, and subspecies --->
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
			<!--- parent species for subspecies --->
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
			<div class="accordion col-12 col-lg-9 px-0" id="accordionForTaxa">
				<!--- included subspecies --->
				<cfquery name="qsubspecies" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
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
				<!--- congeneric species --->
				<cfquery name="qspecies" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
					select 
						scientific_name,
						display_name 
					from 
						taxonomy 
					where
						 genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and 
						 species != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.species#"> and
						 subspecies is null and 
						 scientific_name != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.scientific_name#">
					order by
						scientific_name
				</cfquery>
				<cfif qsubspecies.recordcount LT 10 AND qspecies.recordcount LT 10>
					<cfset collapsed = "">
					<cfset collapseshow = "collapse show">
				<cfelse>
					<cfset collapsed = "collapsed">
					<cfset collapseshow = "collapse">
				</cfif>
				<div class="card mb-2 bg-light">
					<div class="card-header py-0" id="headingPart">
						<h2 class="h4 my-0">
							<button type="button" class="headerLnk w-100 text-left #collapsed#" data-toggle="collapse" aria-expanded="false" data-target="##collapseRelatedTaxa">
								Related Taxon Records (#qsubspecies.recordcount# subspecies, #qspecies.recordcount# species): 
							</button>
						</h2>
					</div>
					<div class="card-body px-3 py-0">
						<div id="collapseRelatedTaxa" class="#collapseshow#" aria-labelledby="headingPart" data-parent="##accordionForTaxa">
							<div class="row">
								<div class="col-12 col-lg-6">
									<br>
									<cfif qspecies.recordcount EQ 0>No</cfif>
									Congeneric Species:
									<ul class="px-0">
										<cfloop query="qspecies">
											<li><a href="/name/#scientific_name#">#display_name#</a></li>
										</cfloop>
									</ul>
								</div>
								<div class="col-12 col-lg-6">
									<br>
									<cfif qsubspecies.recordcount EQ 0>No</cfif>
									<cfif len(t.subspecies) gt 0>Included </cfif>Subspecies:
									<ul>
										<cfloop query="qsubspecies">
											<li><a href="/name/#scientific_name#">#display_name# <span class="sm-caps">#qsubspecies.author_text#</span></a></li>
										</cfloop>
									</ul>
								</div>
							</div>
						</div><!--- collapseRelatedTaxa --->
					</div>
				</div>
			</div><!--- accordion --->
		<cfelseif len(t.genus) gt 0 and len(t.species) is 0>
			<div class="accordion w-100" id="accordionForSpecies">
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
					select 
						scientific_name, display_name, author_text
					from taxonomy 
					where
						 genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and
						 species is not null and
						 subspecies is null and
						 scientific_name != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.scientific_name#">
					order by
						scientific_name
				</cfquery>
				<cfif d.recordcount LT 21 >
					<cfset collapsed = "">
					<cfset collapseshow = "collapse show">
				<cfelse>
					<cfset collapsed = "collapsed">
					<cfset collapseshow = "collapse">
				</cfif>
				<div class="card mb-2">
					<div class="card-header w-100" id="speciesHeadingPart">
						<h2 class="h4 my-0 float-left">  
							<a class="btn-link text-black #collapsed#" role="button" data-toggle="collapse" data-target="##collapseSpecies">
								Included Species (#d.recordcount#): 
							</a>
						</h2>
					</div>
					<div class="card-body px-3 py-0">
						<div id="collapseSpecies" class="#collapseshow#" aria-labelledby="headingPart" data-parent="##accordionForSpecies">
							<div class="row">
								<div class="col-12 col-lg-6">
									<cfif d.recordcount EQ 0>No</cfif>
									<br>Included Species:
									<ul>
										<cfloop query="d">
											<li><a href="/name/#scientific_name#">#display_name# <span class="sm-caps">#d.author_text#</span></a></li>
										</cfloop>
									</ul>
								</div>
							</div>
						</div>
					</div> <!--- collapseSpecies --->
				</div>
			</div><!--- accordion --->
		</cfif>
	</cfif>
</cfoutput>
