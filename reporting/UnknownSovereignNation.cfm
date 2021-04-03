<!---
/reporting/UnknownSovereignNation.cfm

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
<!---
Report on localities, by department, with a value of sovereign_nation of [unknown], and no georeference.
--->
<cfset pageTitle = "Unknown Sovereign Nation Report">
<cfinclude template = "/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<section class="row">
			<div class="col-12">
				<h1 class="h2">Localities with Sovereign Nation of [unknown]</h1>
				
				<cfquery name="getcounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getcounts_result">
					select count(locality.locality_id) ct, mczbase.get_collcodes_for_locality(locality.locality_id, 0) colls
					from locality 
					left outer join accepted_lat_long on locality.locality_id=accepted_lat_long.locality_id
					where locality.sovereign_nation = '[unknown]'
						and accepted_lat_long.locality_id is null
					group by mczbase.get_collcodes_for_locality(locality.locality_id, 0)
				</cfquery>
				<ul>
					<cfset accumulate_shared = 0>
					<cfloop query="getcounts">
						<cfif colls contains ','>
							<cfset accumulate_shared = accumulate_shared + ct>
						<cfelse>
							<cfquery name="getcid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getcid_result">
								select collection_id from collection where collection_cde=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#colls#">
							</cfquery>
							<li class="py-1"><a href="/Locality.cfm?action=findLocality&collection_id=#getcid.collection_id#&collnOpr=usedOnlyBy&sovereign_nation=[unknown]&findNoGeoRef=on">#getcounts.colls#</a> (#getcounts.ct#)</li>
						</cfif>
					</cfloop>
					<cfif accumulate_shared NEQ 0>
						<li class="py-1"><a href="/Locality.cfm?action=findLocality&sovereign_nation=[unknown]&findNoGeoRef=on&onlyShared=on&include_counts=1">Shared</a> (#accumulate_shared#)</li>
					</cfif>
				</ul>
			</div>
		</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
