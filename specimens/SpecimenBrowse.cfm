<cfset pageTitle = "Browse Specimen Data">
<!--
specimens/SpecimenBrowse.cfm

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

-->
<cfinclude template = "/shared/_header.cfm">

<cfquery name="namedGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#">
	SELECT count(flat.collection_object_id) ct, underscore_collection.collection_name, underscore_collection.underscore_collection_id, underscore_collection.mask_fg
	FROM UNDERSCORE_COLLECTION
	LEFT JOIN underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
	LEFT JOIN<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flat
		on underscore_relation.collection_object_id = flat.collection_object_id
	<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
		WHERE underscore_collection.mask_fg = 0
	</cfif>
	GROUP BY
		underscore_collection.collection_name, underscore_collection.underscore_collection_id, underscore_collection.mask_fg
	ORDER BY underscore_collection.collection_name
</cfquery>
<cfquery name="countries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#">
	select count(*) ct, country 
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where country is not null
	group by country
	order by country
</cfquery>
<cfquery name="notcountries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	select count(*) ct, continent_ocean
	from
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where country is null
	group by continent_ocean
</cfquery>
<cfquery name="phyla" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	select count(*) ct, phylum 
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where phylum is not null
	group by phylum
	order by phylum
</cfquery>
<cfquery name="notphyla" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	select count(*) ct, kingdom, phylorder 
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where phylum is null and (kingdom is not null or phylorder is not null)
	group by kingdom, phylorder
	order by phylorder
</cfquery>
<cfquery name="notkingdoms" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	select count(*) ct, scientific_name
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where kingdom is null and phylum is null and phylorder is null
	group by scientific_name
	order by scientific_name
</cfquery> 
<cfquery name="primaryTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	SELECT collection, collection_id, toptypestatus, count(*) as ct
	FROM
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	WHERE
		toptypestatuskind = 'Primary'
	GROUP BY
		collection, collection_id, toptypestatus
</cfquery>

<cfif findNoCase('redesign',Session.gitBranch) GT 0>
	<cfset specimenSearch="/Specimens.cfm?execute=true&action=fixedSearch">
<cfelse>
	<cfset specimenSearch="/SpecimenResults.cfm?ShowObservations=true">
</cfif>
<cfoutput>
	<main class="container">
		<div class="row">
			<div class="col-12 mt-2">
			<div class="col-12 mt-3">
				<h2 class="h2">Primary Types</h2>
				<ul class="list-group list-group-horizontal">
					<cfloop query="primaryTypes">
						<li class="list-group-item"><a href="#specimenSearch#&collection_id=#primaryTypes.collection_id#&type_status=#toptypestatus#">#collection# #toptypestatus#</a> (#ct#)</li>
					</cfloop>
				</ul>
			</div>
			<div class="col-12">
				<h2 class="h2">MCZ Featured Collections of Cataloged Items</h2>
				<ul class="list-group-horizontal list-group">
					<cfloop query="namedGroups">
						<cfset mask="">
						<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") GT 0>
							<cfif namedGroups.mask_fg EQ 1>
								<cfset mask=" [Hidden]">
							</cfif>
						</cfif>
						<li class="list-group-item"><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#underscore_collection_id#">#collection_name#</a> (#ct#)#mask#</li>
					</cfloop>
				</ul>
			</div>
			<div class="col-12">
				<h2 class="h2">Browse by higher geography</h2>
				<ul class="list-group list-group-horizontal">
					<cfloop query="countries">
						<li class="list-group-item"><a href="#specimenSearch#&country=#country#">#country#</a> (#ct#)</li>
					</cfloop>
					<cfloop query="notcountries">
						<li class="list-group-item"><a href="#specimenSearch#&country=NULL&continent_ocean=#continent_ocean#">#continent_ocean#</a> (#ct#)</li>
					</cfloop>
				</ul>
			</div>
			<div class="col-12">
				<h2 class="h2">Browse by higher taxonomy</h2>
				<ul class="list-group list-group-horizontal">
					<cfloop query="phyla">
						<li class="list-group-item"><a href="#specimenSearch#&phylum=#phylum#">#phylum#</a> (#ct#)</li>
					</cfloop>
					<cfloop query="notphyla">
						<li class="list-group-item"><a href="#specimenSearch#&phylum=NULL&kingdom=#kingdom#&phylorder=#phylorder#">#kingdom#:#phylorder#</a> (#ct#)</li>
					</cfloop>
					<cfloop query="notkingdoms">
						<li class="list-group-item"><a href="#specimenSearch#&phylum=NULL&kingdom=NULL&phylorder=NULL&scientific_name=#scientific_name#">#scientific_name#</a> (#ct#)</li>
					</cfloop>
				</ul>
			</div>
		</div>
		</div>
	</main>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
