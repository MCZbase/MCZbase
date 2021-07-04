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

<cfquery name="countries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select count(*) ct, country 
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where country is not null
	group by country
	order by country
</cfquery>
<cfquery name="notcountries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select count(*) ct, continent_ocean
	from
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where country is null
	group by continent_ocean
</cfquery>
<cfquery name="phyla" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select count(*) ct, phylum 
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where phylum is not null
	group by phylum
	order by phylum
</cfquery>
<cfquery name="notphyla" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select count(*) ct, kingdom, phylorder 
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where phylum is null and (kingdom is not null or phylorder is not null)
	group by kingdom, phylorder
	order by phylorder
</cfquery>
<cfquery name="notkingdoms" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select count(*) ct, scientific_name
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where kingdom is null and phylum is null and phylorder is null
	group by scientific_name
	order by scientific_name
</cfquery> 

<cfoutput>
	<main class="container">
		<div class="row">
			<div class="col-12 col-md-6">
				<h1 class="h2">Browse by higher geography</h1>
				<ul>
					<cfloop query="countries">
						<li><a href="/Specimens.cfm?country=#country#&execute=true">#country#</a> (#ct#)</li>
					</cfloop>
					<cfloop query="notcountries">
						<li><a href="/Specimens.cfm?country=NULL&continent_ocean=#continent_ocean#&execute=true">#continent_ocean#</a> (#ct#)</li>
					</cfloop>
				</ul>
			</div>
			<div class="col-12 col-md-6">
				<h1 class="h2">Browse by higher taxonomy</h1>
				<ul>
					<cfloop query="phyla">
						<li><a href="/Specimens.cfm?phylum=#phylum#&execute=true">#phylum#</a> (#ct#)</li>
					</cfloop>
					<cfloop query="notphyla">
						<li><a href="/Specimens.cfm?phylum=NULL&kingdom=#kingdom#&phylorder=#phylorder#&execute=true">#kingdom#:#phylorder#</a> (#ct#)</li>
					</cfloop>
					<cfloop query="notkingdoms">
						<li><a href="/Specimens.cfm?phylum=NULL&kingdom=NULL&phylorder=NULL&scientific_name=#scientific_name#&execute=true">#scientific_name#</a> (#ct#)</li>
					</cfloop>
				</ul>
			</div>
		</div>
	</main>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
