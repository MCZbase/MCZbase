<!--- specimens/component/manage.cfc summary data about specimen search results sets 

Copyright 2024 President and Fellows of Harvard College

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
<!--- publicly available functions to support /specimens/Specimen.cfm --->
<cfcomponent>
<cf_rolecheck>
<cfinclude template = "/shared/functionLib.cfm" runOnce="true">
<cfinclude template="/media/component/search.cfc" runOnce="true"><!--- ? unused ? remove ? --->
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for getMediaBlockHtml --->
<cfinclude template = "/shared/component/functions.cfc" runOnce="true"><!--- for getGuidLink() --->
<cfif NOT isDefined("reportError")>
	<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
</cfif>

<!--- obtain a count of the number of cataloged items in a result set 
 @param result_id the guid for the result for which to return a count of records.
--->
<cffunction name="getCatalogedItemCount" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">

	<cfquery name="results" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="results_result">
		SELECT count(distinct collection_object_id) ct
		FROM user_search_table
		WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
	</cfquery>
	<cfreturn results.ct>
</cffunction>

<!--- obtain a count of the number of georeferenced cataloged items in a result set 
 @param result_id the guid for the result for which to return a count of georeferenced records.
--->
<cffunction name="getGeoreferenceCount" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	
	<cfquery name="countGeorefs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT count(*) ct 
		FROM user_search_table
			JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
				ON user_search_table.collection_object_id = flatTableName.collection_object_id
		WHERE
			user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.result_id#">
			AND flatTableName.dec_lat is not null 
			AND flatTableName.dec_long is not null 
	</cfquery>
	<cfreturn countGeorefs.ct>
</cffunction>

<!--- obtain a block of html summarizing the georeferences associated with a specimen search result set 
 @param result_id the guid for the result for which to return a summary of georeferenced records.
--->
<cffunction name="getGeoreferenceSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfthread name="getGeorefSummaryThread">
		<cfoutput>
			<cftry>
				<ul class="list-group list-group-horizontal d-flex flex-wrap">
					<cfquery name="countGeorefs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT count(*) ct 
						FROM user_search_table
							JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
								ON user_search_table.collection_object_id = flatTableName.collection_object_id
						WHERE
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
							AND flatTableName.dec_lat is not null 
							AND flatTableName.dec_long is not null 
					</cfquery>
					<cfloop query="countGeorefs">
						<cfset foundCount = countGeorefs.ct>
						<li class="list-group-item">
							<a href="/bnhmMaps/bnhmMapData.cfm?result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">
								#countGeorefs.ct# with georeferences
							</a>
						</li>
					</cfloop>
					<cfif foundCount GT 0>
						<li class="list-group-item">
							<a href="/specimens/downloadGeospatialData.cfm?result_id=#encodeForUrl(variables.result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Map File (KML,GPX)</a>
						</li>
						<cfquery name="countGoodGeorefs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT count(*) ct 
							FROM user_search_table
								JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
									ON user_search_table.collection_object_id = flatTableName.collection_object_id
							WHERE
								user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
								AND flatTableName.dec_lat is not null 
								AND flatTableName.dec_long is not null 
								AND flatTableName.datum is not null 
								AND flatTableName.coordinate_precision is not null 
								AND flatTableName.COORDINATEUNCERTAINTYINMETERS is not null 
						</cfquery>
						<cfloop query="countGoodGeorefs">
							<li class="list-group-item">
								#countGoodGeorefs.ct# with datum, precision, and uncertainty
							</li>
						</cfloop>
						<cfquery name="countPreciceGeorefs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT count(*) ct 
							FROM user_search_table
								JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
									ON user_search_table.collection_object_id = flatTableName.collection_object_id
							WHERE
								user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
								AND flatTableName.dec_lat is not null 
								AND flatTableName.dec_long is not null 
								AND flatTableName.datum is not null 
								AND flatTableName.coordinate_precision >= 2 -- better than 1111m about one minute
								AND flatTableName.COORDINATEUNCERTAINTYINMETERS <= 1111
						</cfquery>
						<cfloop query="countPreciceGeorefs">
							<li class="list-group-item">
								#countPreciceGeorefs.ct# with one minute precision or better
							</li>
						</cfloop>
					</cfif>
				<cfcatch>
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<cfset function_called = "#GetFunctionCalledName()#">
					<h2 class='h3'>Error in #function_called#:</h2>
					<div>#error_message#</div>
				</cfcatch>
				</cftry>
			</ul>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getGeorefSummaryThread" />
	<cfreturn getGeorefSummaryThread.output>
</cffunction>

<!---
 ** Obtain summary information on Collections in a result set 
 * @param result_id the result for which to return summary information
--->
<cffunction name="getCollectionsSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="allowremove" type="string" required="no" default="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfset variables.allowremove = arguments.allowremove>
	<cfthread name="getCollsSummaryThread">
		<cfoutput>
			<cftry>
				<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="collections_result">
					SELECT count(*) ct, 
						collection_cde, 
						collection_id
					FROM user_search_table
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
					WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					GROUP BY collection_cde, collection_id
				</cfquery>
				<div class="card-header h4">Collections (#collections.recordcount#)</div>
				<div class="card-body">
					<ul class="list-group list-group-horizontal d-flex flex-wrap">
						<cfloop query="collections">
							<li class="list-group-item">
								<cfif collections.recordcount GT 1 AND variables.allowremove EQ "yes">
									<input type="button" onClick=" confirmDialog('Remove all records from #collections.collection_cde# from these search results','Confirm Remove By Collection Code', function() { removeCollection ('#collection_cde#'); }  ); " class="p-1 btn btn-xs btn-warning" value="&##8998;" aria-label="Remove"/>
								</cfif>
								#collections.collection_cde# (#collections.ct#);
							</li>
						</cfloop>
					</ul>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getCollsSummaryThread" />
	<cfreturn getCollsSummaryThread.output>
</cffunction>

<!---
 ** Obtain summary information on Countries in a result set 
 * @param result_id the result for which to return summary information
--->
<cffunction name="getCountriesSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="allowremove" type="string" required="no" default="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfset variables.allowremove = arguments.allowremove>
	<cfthread name="getCountriesSummaryThread">
		<cfoutput>
			<cftry>
				<!--- NOTE: string replacements for null are referenced in null replacement below. --->
				<cfquery name="countries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="countries_result">
					SELECT count(*) ct, 
						nvl(continent_ocean,'[no continent/ocean]') as continent_ocean, nvl(country,'[no country]') as country
					FROM user_search_table
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
					WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					GROUP BY 
						continent_ocean, country
				</cfquery>
				<div class="card-header h4">Countries (#countries.recordcount#)</div>
				<div class="card-body">
					<ul class="list-group list-group-horizontal d-flex flex-wrap">
						<cfloop query="countries">
							<li class="list-group-item">
								<cfif countries.recordcount GT 1 AND variables.allowremove EQ "yes">
									<cfset continentBit = "#countries.continent_ocean#">
									<cfset countryBit = "#countries.country#">
									<cfif continentBit EQ "[no continent/ocean]"><cfset continentBit = "NULL"></cfif>
									<cfif countryBit EQ "[no country]"><cfset countryBit = "NULL"></cfif>
									<cfset submitValue = "#continentBit#|#countryBit#">
									<input type="button" onClick=" confirmDialog('Remove all records from #countries.country# in continent/ocean #countries.continent_ocean# from these search results','Confirm Remove By Country', function() { removeByCountry ('#submitValue#'); }  ); " class="p-1 btn btn-xs btn-warning" value="&##8998;" aria-label="Remove"/>
								</cfif>
								#countries.continent_ocean#&thinsp;:&thinsp;#countries.country# (#countries.ct#);
							</li>
						</cfloop>
					</ul>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getCountriesSummaryThread" />
	<cfreturn getCountriesSummaryThread.output>
</cffunction>


<!---
 ** Obtain summary information on Families in a result set 
 * @param result_id the result for which to return summary information
--->
<cffunction name="getFamiliesSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="allowremove" type="string" required="no" default="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfset variables.allowremove = arguments.allowremove>
	<cfthread name="getFamiliesSummaryThread">
		<cfoutput>
			<cftry>
				<!--- NOTE: string replacements for null are referenced in null replacement below. --->
				<cfquery name="families" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="families_result">
					SELECT count(*) ct, 
						nvl(phylorder,'[no order]') as phylorder, nvl(family,'[no family]') as family
					FROM user_search_table
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
					WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					GROUP BY phylorder, family
				</cfquery>
				<div class="card-header h4">Families (#families.recordcount#)</div>
				<div class="card-body">
					<ul class="list-group list-group-horizontal d-flex flex-wrap">
						<cfloop query="families">
							<li class="list-group-item">
								<cfif families.recordcount GT 1 && variables.allowremove EQ "yes">
									<cfset orderBit = "#families.phylorder#">
									<cfset familyBit = "#families.family#">
									<cfif orderBit EQ "[no order]"><cfset orderBit = "NULL"></cfif>
									<cfif familyBit EQ "[no family]"><cfset familyBit = "NULL"></cfif>
									<cfset submitValue = "#orderBit#|#familyBit#">
									<input type="button" onClick=" confirmDialog('Remove all records in family #families.family# with order #families.phylorder# from these search results','Confirm Remove By Family', function() { removeByFamily ('#submitValue#'); }  ); " class="p-1 btn btn-xs btn-warning" value="&##8998;" aria-label="Remove"/>
								</cfif>
								#families.phylorder#&thinsp;:&thinsp;#families.family# (#families.ct#);
							</li>
						</cfloop>
					</ul>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getFamiliesSummaryThread" />
	<cfreturn getFamiliesSummaryThread.output>
</cffunction>


<!---
 ** Obtain summary information on Accessions in a result set 
 * @param result_id the result for which to return summary information
--->
<cffunction name="getAccessionsSummaryHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfthread name="getAccessionsSummaryThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
					<cfquery name="accessions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="accessions_result">
						SELECT count(*) ct, 
							accn_number, 
							accn_coll.collection,
							nvl(to_char(accn.received_date,'YYYY'),'[no date]') year
						FROM user_search_table
							left join cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
							left join accn on cataloged_item.accn_id = accn.transaction_id
							LEFT JOIN trans on accn.transaction_id = trans.transaction_id 
							LEFT JOIN collection accn_coll on trans.collection_id=accn_coll.collection_id
						WHERE 
							result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						GROUP BY accn_number, accn_coll.collection, nvl(to_char(accn.received_date,'YYYY'),'[no date]')
						ORDER BY accn_number
					</cfquery>
					<div class="card-header h4">Accessions (#accessions.recordcount#)</div>
					<div class="card-body">
						<ul class="list-group list-group-horizontal d-flex flex-wrap">
							<cfloop query="accessions">
								<li class="list-group-item">#accessions.collection# #accessions.accn_number#&thinsp;:&thinsp;#accessions.year# (#accessions.ct#);</li>
							</cfloop>
						</ul>
					</div>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getAccessionsSummaryThread" />
	<cfreturn getAccessionsSummaryThread.output>
</cffunction>

<!---
 ** Obtain summary information on Localities in a result set 
 * @param result_id the result for which to return summary information
--->
<cffunction name="getLocalitiesSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfthread name="getLocalitiesSummaryThread">
		<cfoutput>
			<cftry>
				<cfquery name="localities" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="localities_result">
					SELECT count(*) ct, 
						locality_id, spec_locality
					FROM user_search_table
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
					WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					GROUP BY locality_id, spec_locality
				</cfquery>
				<div class="card-header h4">Specific Localities (#localities.recordcount#)</div>
				<div class="card-body">
					<ul class="list-group list-group-horizontal d-flex flex-wrap">
						<cfloop query="localities">
							<li class="list-group-item">#localities.spec_locality# (#localities.ct#);</li>
						</cfloop>
					</ul>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getLocalitiesSummaryThread" />
	<cfreturn getLocalitiesSummaryThread.output>
</cffunction>


<!---
 ** Obtain summary information on CollEvents in a result set 
 * @param result_id the result for which to return summary information
--->
<cffunction name="getCollEventsSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfthread name="getCollEventsSummaryThread">
		<cfoutput>
			<cftry>
				<cfquery name="collectingEvents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="collectingEvents_result">
					SELECT count(*) ct, 
						collecting_event_id, began_date, ended_date, verbatim_date
					FROM user_search_table
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
					WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					GROUP BY 
						collecting_event_id, began_date, ended_date, verbatim_date
					ORDER BY
						began_date, ended_date
				</cfquery>
				<div class="card-header h4">Collecting Events (#collectingEvents.recordcount#)</div>
				<div class="card-body">
					<ul class="list-group list-group-horizontal d-flex flex-wrap">
						<cfloop query="collectingEvents">
							<cfset summary = began_date>
							<cfif ended_date NEQ began_date>
								<cfset summary = "#summary#/#ended_date#">
							</cfif>
							<cfif len(verbatim_date) GT 0 AND verbatim_date NEQ "[no verbatim date data]" >
								<cfset summary = "#summary# [#verbatim_date#]">
							</cfif>
							<li class="list-group-item">#summary# (#collectingEvents.ct#);</li>
						</cfloop>
					</ul>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getCollEventsSummaryThread" />
	<cfreturn getCollEventsSummaryThread.output>
</cffunction>


<!---
 ** Obtain summary information on catalog number prefixes in a result set 
 * @param result_id the result for which to return summary information
--->
<cffunction name="getPrefixesSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="allowremove" type="string" required="no" default="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfset variables.allowremove = arguments.allowremove>
	<cfthread name="getPrefixSummaryThread">
		<cfoutput>
			<cftry>
				<cfquery name="prefixes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="prefixes_result">
					SELECT count(*) ct, 
						cat_num_prefix
					FROM user_search_table
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
					WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					GROUP BY cat_num_prefix
				</cfquery>
				<div class="card-header h4">Catalog Number Prefixes (#prefixes.recordcount#)</div>
				<div class="card-body">
					<ul class="list-group list-group-horizontal d-flex flex-wrap">
						<cfloop query="prefixes">
							<li class="list-group-item">
								<cfif len(prefixes.cat_num_prefix) EQ 0> 
									<cfset prefixSubmit = "NULL">
									<cfset prefixDisplay = "[no prefix]">
								<cfelse>
									<cfset prefixSubmit = "#prefixes.cat_num_prefix#">
									<cfset prefixDisplay = "#prefixes.cat_num_prefix#">
								</cfif>
								<cfif prefixes.recordcount GT 1 AND variables.allowremove EQ "yes">
									<input type="button" onClick=" confirmDialog('Remove all records with the catalog number prefix #prefixDisplay# from these search results','Confirm Remove By Prefix', function() { removeByPrefix ('#prefixSubmit#'); }  ); " class="p-1 btn btn-xs btn-warning" value="&##8998;" aria-label="Remove"/>
								</cfif>
								#prefixDisplay# (#prefixes.ct#);
							</li>
						</cfloop>
					</ul>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getPrefixSummaryThread" />
	<cfreturn getPrefixSummaryThread.output>
</cffunction>

<!---
 ** Obtain summary information on part and preservation types in a result set
 * @param result_id the result for which to return summary information
--->
<cffunction name="getPartsSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="allowremove" type="string" required="no" default="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfset variables.allowremove = arguments.allowremove>
	<cfthread name="getPartsSummaryThread">
		<cfoutput>
			<cftry>
				<!--- crude first cut, just strings from flat --->
				<cfquery name="parts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="parts_result">
					SELECT count(user_search_table.collection_object_id) ct, parts
					FROM user_search_table
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
					WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					GROUP BY parts
				</cfquery>
				<div class="card-header h4">Lists of Parts (#parts.recordcount#)</div>
				<div class="card-body">
					<ul class="list-group list-group-horizontal d-flex flex-wrap">
						<cfloop query="parts">
							<li class="list-group-item">
								<cfif len(parts.parts) EQ 0> 
									<cfset partsSubmit = "NULL">
									<cfset partsDisplay = "[no parts]">
								<cfelse>
									<cfset partsSubmit = "#parts.parts#">
									<cfset partsDisplay = "#parts.parts#">
								</cfif>
								<cfif parts.recordcount GT 1 && variables.allowremove EQ "yes">
									<input type="button" onClick=" confirmDialog('Remove all records where the list of parts matches #partsDisplay# from these search results','Confirm Remove By Parts', function() { removeByParts ('#partsSubmit#'); }  ); " class="p-1 btn btn-xs btn-warning" value="&##8998;" aria-label="Remove"/>
								</cfif>
								#partsDisplay# (#parts.ct#);
							</li>
						</cfloop>
					</ul>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getPartsSummaryThread" />
	<cfreturn getPartsSummaryThread.output>
</cffunction>

<!---
 ** Obtain summary information on preservation types on parts on specimens in a result set
 * @param result_id the result for which to return summary information
--->
<cffunction name="getPreservationsSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="allowremove" type="string" required="no" default="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfset variables.allowremove = arguments.allowremove>
	<cfthread name="getPreservationsSummaryThread">
		<cfoutput>
			<cftry>
				<cfquery name="preservation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="preservation_result">
					SELECT count(flat.collection_object_id) ct, preserve_method
					FROM user_search_table
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
						left join specimen_part on flat.collection_object_id = specimen_part.derived_from_cat_item
					WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					GROUP BY preserve_method
				</cfquery>
				<div class="card-header h4">Preservation Methods on any part (#preservation.recordcount#)</div>
				<div class="card-body">
					<ul class="list-group list-group-horizontal d-flex flex-wrap">
						<cfloop query="preservation">
							<li class="list-group-item">
								<cfif len(preservation.preserve_method) EQ 0> 
									<cfset preservationSubmit = "NULL">
									<cfset preservationDisplay = "[no preserve method]">
								<cfelse>
									<cfset preservationSubmit = "#preservation.preserve_method#">
									<cfset preservationDisplay = "#preservation.preserve_method#">
								</cfif>
								<cfif preservation.recordcount GT 1 && variables.allowremove EQ "yes">
									<input type="button" onClick=" confirmDialog('Remove all records where any part has a preserve type of #preservationDisplay# from these search results','Confirm Remove By Preservations', function() { removeByPreservations ('#preservationSubmit#'); }  ); " class="p-1 btn btn-xs btn-warning" value="&##8998;" aria-label="Remove"/>
								</cfif>
								#preservationDisplay# (#preservation.ct#);
							</li>
						</cfloop>
					</ul>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getPreservationsSummaryThread" />
	<cfreturn getPreservationsSummaryThread.output>
</cffunction>

<!--- obtain the georeferences of the cataloged items in a result set, the data for the map files of
 /specimens/downloadGeospatialData.cfm.
 @param result_id the guid for the result set.
 @param acceptedOnly true for only accepted georeferences, false to include unaccepted ones.
 @param mapByLocality true for every cataloged item at each locality in the result, not only those in it.
 @return a query with a row for each cataloged item and georeference.
--->
<cffunction name="getResultGeoreferences" returntype="query" access="public" output="false">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="acceptedOnly" type="boolean" required="no" default="true">
	<cfargument name="mapByLocality" type="boolean" required="no" default="false">

	<cfset var useFlat = false>
	<cfif ucase(session.flatTableName) EQ "FLAT">
		<cfset useFlat = true>
	</cfif>
	<cfset var georeferences = "">
	<cfset var georeferences_result = "">
	<cfquery name="georeferences" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="georeferences_result" timeout="#Application.query_timeout#">
		SELECT DISTINCT
			flatTableName.collection_object_id,
			flatTableName.guid,
			flatTableName.institution_acronym,
			flatTableName.collection_cde,
			flatTableName.cat_num,
			flatTableName.began_date,
			flatTableName.ended_date,
			flatTableName.scientific_name,
			flatTableName.collection,
			flatTableName.spec_locality,
			flatTableName.locality_id,
			lat_long.dec_lat,
			lat_long.dec_long,
			lat_long.accepted_lat_long_fg,
			ROUND(to_meters(lat_long.max_error_distance, lat_long.max_error_units)) error_in_meters,
			lat_long.datum
		FROM
			<cfif useFlat>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
			JOIN lat_long ON flatTableName.locality_id = lat_long.locality_id
		WHERE
			lat_long.dec_lat IS NOT NULL
			AND lat_long.dec_long IS NOT NULL
			<cfif arguments.acceptedOnly>
				AND lat_long.accepted_lat_long_fg = 1
			</cfif>
			<cfif arguments.mapByLocality>
				AND flatTableName.locality_id IN (
					SELECT resultFlat.locality_id
					FROM user_search_table
						JOIN <cfif useFlat>FLAT<cfelse>FILTERED_FLAT</cfif> resultFlat
							ON user_search_table.collection_object_id = resultFlat.collection_object_id
					WHERE user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.result_id#">
				)
			<cfelse>
				AND flatTableName.collection_object_id IN (
					SELECT collection_object_id
					FROM user_search_table
					WHERE result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.result_id#">
				)
			</cfif>
		ORDER BY
			flatTableName.collection, flatTableName.scientific_name, flatTableName.cat_num
	</cfquery>
	<cfreturn georeferences>
</cffunction>

<!--- obtain a KML document of the georeferenced cataloged items in a result set, with the options of
 the legacy /bnhmMaps/kml.cfm.  As there, error circles, unaccepted georeferences and all records at
 each locality are offered only when coloring by collection.
 @param result_id the guid for the result set to map.
 @param colorBy collection for a folder of localities for each collection, species for a folder of
  cataloged items for each scientific name.
 @param showErrors true to draw a circle of each georeference's error radius.
 @param mapByLocality true to list every cataloged item at each locality, not only those in the result.
 @param showUnaccepted true to include unaccepted georeferences, which get a red marker.
 @param includeTimeSpan true to give each placemark its collecting dates as a KML TimeSpan.
 @return the KML document.
--->
<cffunction name="getResultKml" returntype="string" access="public" output="false">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="colorBy" type="string" required="yes">
	<cfargument name="showErrors" type="boolean" required="no" default="false">
	<cfargument name="mapByLocality" type="boolean" required="no" default="false">
	<cfargument name="showUnaccepted" type="boolean" required="no" default="false">
	<cfargument name="includeTimeSpan" type="boolean" required="no" default="false">

	<cfset var bySpecies = false>
	<cfif arguments.colorBy EQ "species">
		<cfset bySpecies = true>
	</cfif>
	<cfset var kmlData = "">
	<cfset var kmlSpecies = "">
	<cfset var kmlSpeciesRecords = "">
	<cfset var kmlCollections = "">
	<cfset var kmlLocalities = "">
	<cfset var kmlErrors = "">
	<cfif bySpecies>
		<cfset kmlData = getResultGeoreferences(result_id = arguments.result_id)>
	<cfelse>
		<cfset kmlData = getResultGeoreferences(result_id = arguments.result_id, acceptedOnly = NOT arguments.showUnaccepted, mapByLocality = arguments.mapByLocality)>
	</cfif>

	<cfset var kml = createObject("java", "java.lang.StringBuilder").init()>
	<cfset var nl = chr(10)>
	<cfset var tab = chr(9)>
	<cfset kml.append('<?xml version="1.0" encoding="UTF-8"?>' & nl)>
	<cfset kml.append('<kml xmlns="http://www.opengis.net/kml/2.2">' & nl)>
	<cfset kml.append(tab & '<Document>' & nl & tab & tab & '<name>MCZbase Localities</name>' & nl & tab & tab & '<open>1</open>' & nl)>
	<cfif bySpecies>
		<cfquery name="kmlSpecies" dbtype="query">
			SELECT scientific_name
			FROM kmlData
			GROUP BY scientific_name
			ORDER BY scientific_name
		</cfquery>
		<!--- style ids by position, as scientific names aren't valid XML ids --->
		<cfset var speciesStyle = structNew()>
		<cfset var speciesColor = "">
		<cfloop query="kmlSpecies">
			<cfset speciesStyle[kmlSpecies.scientific_name] = "species#kmlSpecies.currentRow#">
			<cfset speciesColor = getKmlColor(kmlSpecies.currentRow)>
			<cfset kml.append(tab & tab & '<Style id="species#kmlSpecies.currentRow#"><IconStyle><color>#speciesColor#</color><scale>1.1</scale>')>
			<cfset kml.append('<Icon><href>#xmlFormat(Application.serverRootUrl)#/images/whiteBalloon.png</href></Icon></IconStyle></Style>' & nl)>
		</cfloop>
		<cfloop query="kmlSpecies">
			<cfquery name="kmlSpeciesRecords" dbtype="query">
				SELECT collection, guid, cat_num, scientific_name, dec_lat, dec_long, error_in_meters, datum, began_date, ended_date
				FROM kmlData
				WHERE scientific_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#kmlSpecies.scientific_name#">
			</cfquery>
			<cfset kml.append(tab & tab & '<Folder>' & nl & tab & tab & tab & '<name>#xmlFormat(kmlSpecies.scientific_name)#</name>' & nl & tab & tab & tab & '<visibility>1</visibility>' & nl)>
			<cfloop query="kmlSpeciesRecords">
				<cfset kml.append(tab & tab & tab & '<Placemark>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<name>#xmlFormat("#kmlSpeciesRecords.collection# #kmlSpeciesRecords.cat_num# (#kmlSpeciesRecords.scientific_name#)")#</name>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<visibility>1</visibility>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<description><![CDATA[Datum: #encodeForHtml(kmlSpeciesRecords.datum)#<br/>Error: #getKmlErrorText(kmlSpeciesRecords.error_in_meters)#<br/>]]></description>' & nl)>
				<cfif arguments.includeTimeSpan>
					<cfset kml.append(tab & tab & tab & tab & '<TimeSpan><begin>#xmlFormat(kmlSpeciesRecords.began_date)#</begin><end>#xmlFormat(kmlSpeciesRecords.ended_date)#</end></TimeSpan>' & nl)>
				</cfif>
				<cfset kml.append(tab & tab & tab & tab & '<styleUrl>##' & speciesStyle[kmlSpecies.scientific_name] & '</styleUrl>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & getKmlExtendedData({
					"collection" = kmlSpeciesRecords.collection,
					"catalogNumber" = kmlSpeciesRecords.guid,
					"scientificName" = kmlSpeciesRecords.scientific_name,
					"geodeticDatum" = kmlSpeciesRecords.datum,
					"coordinateUncertaintyInMeters" = kmlSpeciesRecords.error_in_meters
				}) & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<Point><coordinates>#getPlainNumber(kmlSpeciesRecords.dec_long)#,#getPlainNumber(kmlSpeciesRecords.dec_lat)#,0</coordinates></Point>' & nl)>
				<cfset kml.append(tab & tab & tab & '</Placemark>' & nl)>
			</cfloop>
			<cfset kml.append(tab & tab & '</Folder>' & nl)>
		</cfloop>
	<cfelse>
		<cfset kml.append(tab & tab & '<Style id="red-star"><IconStyle><Icon><href>https://maps.google.com/mapfiles/kml/paddle/red-stars.png</href></Icon></IconStyle></Style>' & nl)>
		<cfset kml.append(tab & tab & '<Style id="error-line"><LineStyle><color>ff0000ff</color><width>1</width></LineStyle></Style>' & nl)>
		<!--- the cataloged items at each locality, gathered once rather than queried for each placemark --->
		<cfset var localityItems = structNew()>
		<cfset var itemsSeen = structNew()>
		<!--- keyed by the integer, as the database and query of queries values may print differently --->
		<cfset var localityKey = "">
		<cfloop query="kmlData">
			<cfset localityKey = int(kmlData.locality_id)>
			<cfif NOT structKeyExists(itemsSeen, "#localityKey#|#kmlData.collection_object_id#")>
				<cfset itemsSeen["#localityKey#|#kmlData.collection_object_id#"] = true>
				<cfif NOT structKeyExists(localityItems, localityKey)>
					<cfset localityItems[localityKey] = "">
				</cfif>
				<cfset localityItems[localityKey] &= '<a href="#encodeForHtml(Application.serverRootUrl)#/guid/#encodeForHtml(kmlData.guid)#">#encodeForHtml(kmlData.collection)# #encodeForHtml(kmlData.cat_num)# (<em>#encodeForHtml(kmlData.scientific_name)#</em>)</a><br/>'>
			</cfif>
		</cfloop>
		<cfset var localityLink = "">
		<cfset var acceptedText = "">
		<cfquery name="kmlCollections" dbtype="query">
			SELECT collection
			FROM kmlData
			GROUP BY collection
			ORDER BY collection
		</cfquery>
		<!--- a color for each collection; unaccepted georeferences keep the red star --->
		<cfloop query="kmlCollections">
			<cfset kml.append(tab & tab & '<Style id="collection#kmlCollections.currentRow#"><IconStyle><color>#getKmlColor(kmlCollections.currentRow)#</color><scale>1.1</scale>')>
			<cfset kml.append('<Icon><href>#xmlFormat(Application.serverRootUrl)#/images/whiteBalloon.png</href></Icon></IconStyle></Style>' & nl)>
		</cfloop>
		<cfloop query="kmlCollections">
			<cfquery name="kmlLocalities" dbtype="query">
				SELECT dec_lat, dec_long, accepted_lat_long_fg, error_in_meters, datum, spec_locality, locality_id, began_date, ended_date
				FROM kmlData
				WHERE collection = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#kmlCollections.collection#">
				GROUP BY dec_lat, dec_long, accepted_lat_long_fg, error_in_meters, datum, spec_locality, locality_id, began_date, ended_date
			</cfquery>
			<cfset kml.append(tab & tab & '<Folder>' & nl & tab & tab & tab & '<name>#xmlFormat(kmlCollections.collection)#</name>' & nl & tab & tab & tab & '<visibility>1</visibility>' & nl)>
			<cfloop query="kmlLocalities">
				<cfset localityLink = "">
				<cfif isdefined("session.roles") AND listFindNoCase(session.roles,"manage_locality")>
					<cfset localityLink = '<p><a href="#encodeForHtml(Application.serverRootUrl)#/localities/Locality.cfm?locality_id=#encodeForUrl(kmlLocalities.locality_id)#">Edit Locality</a></p>'>
				<cfelseif isdefined("session.roles") AND listFindNoCase(session.roles,"coldfusion_user")>
					<cfset localityLink = '<p><a href="#encodeForHtml(Application.serverRootUrl)#/localities/viewLocality.cfm?locality_id=#encodeForUrl(kmlLocalities.locality_id)#">Locality Details</a></p>'>
				</cfif>
				<cfset kml.append(tab & tab & tab & '<Placemark>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<name>#xmlFormat("#kmlLocalities.spec_locality# (#kmlLocalities.locality_id#)")#</name>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<visibility>1</visibility>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<description><![CDATA[Datum: #encodeForHtml(kmlLocalities.datum)#<br/>Error: #getKmlErrorText(kmlLocalities.error_in_meters)#<br/>#localityLink##localityItems[int(kmlLocalities.locality_id)]#]]></description>' & nl)>
				<cfif arguments.includeTimeSpan>
					<cfset kml.append(tab & tab & tab & tab & '<TimeSpan><begin>#xmlFormat(kmlLocalities.began_date)#</begin><end>#xmlFormat(kmlLocalities.ended_date)#</end></TimeSpan>' & nl)>
				</cfif>
				<cfset acceptedText = "no">
				<cfif kmlLocalities.accepted_lat_long_fg EQ 1>
					<cfset acceptedText = "yes">
					<cfset kml.append(tab & tab & tab & tab & '<styleUrl>##collection#kmlCollections.currentRow#</styleUrl>' & nl)>
				<cfelse>
					<cfset kml.append(tab & tab & tab & tab & '<styleUrl>##red-star</styleUrl>' & nl)>
				</cfif>
				<cfset kml.append(tab & tab & tab & tab & getKmlExtendedData({
					"collection" = kmlCollections.collection,
					"locationID" = kmlLocalities.locality_id,
					"locality" = kmlLocalities.spec_locality,
					"acceptedGeoreference" = acceptedText,
					"geodeticDatum" = kmlLocalities.datum,
					"coordinateUncertaintyInMeters" = kmlLocalities.error_in_meters
				}) & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<Point><coordinates>#getPlainNumber(kmlLocalities.dec_long)#,#getPlainNumber(kmlLocalities.dec_lat)#</coordinates></Point>' & nl)>
				<cfset kml.append(tab & tab & tab & '</Placemark>' & nl)>
			</cfloop>
			<cfset kml.append(tab & tab & '</Folder>' & nl)>
		</cfloop>
		<cfif arguments.showErrors>
			<cfquery name="kmlErrors" dbtype="query">
				SELECT error_in_meters, dec_lat, dec_long
				FROM kmlData
				WHERE error_in_meters > 0
				GROUP BY error_in_meters, dec_lat, dec_long
			</cfquery>
			<cfset kml.append(tab & tab & '<Folder>' & nl & tab & tab & tab & '<name>Error Circles</name>' & nl)>
			<cfset var circlePoint = "">
			<cfset var circleCoordinates = "">
			<cfloop query="kmlErrors">
				<cfset circleCoordinates = createObject("java", "java.lang.StringBuilder").init()>
				<cfloop array="#getErrorCirclePoints(kmlErrors.dec_lat, kmlErrors.dec_long, kmlErrors.error_in_meters)#" index="circlePoint">
					<cfset circleCoordinates.append(nl & circlePoint[1] & "," & circlePoint[2])>
				</cfloop>
				<cfset kml.append(tab & tab & tab & '<Placemark><name>Error</name><visibility>1</visibility><styleUrl>##error-line</styleUrl><LineString><coordinates>' & circleCoordinates.toString() & nl & '</coordinates></LineString></Placemark>' & nl)>
			</cfloop>
			<cfset kml.append(tab & tab & '</Folder>' & nl)>
		</cfif>
	</cfif>
	<cfset kml.append(tab & '</Document>' & nl & '</kml>' & nl)>
	<cfreturn kml.toString()>
</cffunction>

<!--- obtain a KML color for the nth folder of a map file, hues spaced by the golden ratio so that
 neighboring folders differ however many there are.
 @param index the one based position of the folder.
 @return the color as KML writes it, alpha, blue, green, red in hexadecimal.
--->
<cffunction name="getKmlColor" returntype="string" access="public" output="false">
	<cfargument name="index" type="numeric" required="yes">

	<cfset var hue = (arguments.index * 0.618033988749895) - int(arguments.index * 0.618033988749895)>
	<!--- saturation 0.75 and value 0.9, converted from HSV --->
	<cfset var sector = int(hue * 6)>
	<cfset var fraction = hue * 6 - sector>
	<cfset var high = 0.9>
	<cfset var low = 0.9 * (1 - 0.75)>
	<cfset var falling = 0.9 * (1 - 0.75 * fraction)>
	<cfset var rising = 0.9 * (1 - 0.75 * (1 - fraction))>
	<cfset var sectorColors = [[high, rising, low], [falling, high, low], [low, high, rising], [low, falling, high], [rising, low, high], [high, low, falling]]>
	<cfset var rgb = sectorColors[sector + 1]>
	<cfset var color = "ff">
	<cfset var channel = 0>
	<cfloop index="channel" list="3,2,1">
		<cfset color &= right("0" & formatBaseN(round(rgb[channel] * 255), 16), 2)>
	</cfloop>
	<cfreturn color>
</cffunction>

<!--- obtain a georeference's error radius for a KML description.
 @param errorInMeters the radius in meters, or an empty string.
 @return the radius with its unit, or "not recorded".
--->
<cffunction name="getKmlErrorText" returntype="string" access="public" output="false">
	<cfargument name="errorInMeters" type="string" required="yes">

	<cfif len(arguments.errorInMeters) EQ 0>
		<cfreturn "not recorded">
	</cfif>
	<cfreturn "#encodeForHtml(arguments.errorInMeters)# m">
</cffunction>

<!--- obtain a KML ExtendedData element, which GIS software reads as the placemark's attributes, so that
 it can color by them where it doesn't use the KML styles.
 @param values a struct of attribute names and values; names keep the case they are given in.
 @return the ExtendedData element.
--->
<cffunction name="getKmlExtendedData" returntype="string" access="public" output="false">
	<cfargument name="values" type="struct" required="yes">

	<cfset var extendedData = "<ExtendedData>">
	<cfset var valueName = "">
	<cfloop collection="#arguments.values#" item="valueName">
		<cfset extendedData &= '<Data name="#xmlFormat(valueName)#"><value>#xmlFormat(arguments.values[valueName])#</value></Data>'>
	</cfloop>
	<cfreturn extendedData & "</ExtendedData>">
</cffunction>

<!--- obtain the Darwin Core terms for one row of getResultGeoreferences, shared by the GeoJSON and CSV
 map files.
 @param georeferences the query from getResultGeoreferences.
 @param row the row of that query.
 @return a struct of term values, all strings, empty when there is no value.
--->
<cffunction name="getGeoreferenceTerms" returntype="struct" access="public" output="false">
	<cfargument name="georeferences" type="query" required="yes">
	<cfargument name="row" type="numeric" required="yes">

	<cfset var terms = structNew()>
	<cfset var began = arguments.georeferences.began_date[arguments.row]>
	<cfset var ended = arguments.georeferences.ended_date[arguments.row]>
	<cfset terms["institutionCode"] = arguments.georeferences.institution_acronym[arguments.row]>
	<cfset terms["collectionCode"] = arguments.georeferences.collection_cde[arguments.row]>
	<cfset terms["catalogNumber"] = arguments.georeferences.cat_num[arguments.row]>
	<cfset terms["scientificName"] = arguments.georeferences.scientific_name[arguments.row]>
	<cfset terms["locality"] = arguments.georeferences.spec_locality[arguments.row]>
	<cfset terms["locationID"] = arguments.georeferences.locality_id[arguments.row]>
	<cfset terms["decimalLatitude"] = getPlainNumber(arguments.georeferences.dec_lat[arguments.row])>
	<cfset terms["decimalLongitude"] = getPlainNumber(arguments.georeferences.dec_long[arguments.row])>
	<cfset terms["geodeticDatum"] = arguments.georeferences.datum[arguments.row]>
	<cfset terms["coordinateUncertaintyInMeters"] = arguments.georeferences.error_in_meters[arguments.row]>
	<cfset terms["eventDate"] = began>
	<cfif len(ended) GT 0 AND ended NEQ began>
		<cfset terms["eventDate"] = "#began#/#ended#">
	</cfif>
	<cfset terms["georeferenceRemarks"] = "">
	<cfif arguments.georeferences.accepted_lat_long_fg[arguments.row] NEQ 1>
		<cfset terms["georeferenceRemarks"] = "not the accepted georeference">
	</cfif>
	<cfset terms["references"] = "#Application.serverRootUrl#/guid/#arguments.georeferences.guid[arguments.row]#">
	<cfreturn terms>
</cffunction>

<!--- obtain a GeoJSON FeatureCollection of the georeferenced cataloged items in a result set, a Point
 for each cataloged item and georeference with Darwin Core terms as properties.
 @param result_id the guid for the result set.
 @param showErrors true to add a Polygon of each distinct georeference's error radius.
 @param mapByLocality true for every cataloged item at each locality in the result.
 @param showUnaccepted true to include unaccepted georeferences.
 @return the GeoJSON document.
--->
<cffunction name="getResultGeoJson" returntype="string" access="public" output="false">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="showErrors" type="boolean" required="no" default="false">
	<cfargument name="mapByLocality" type="boolean" required="no" default="false">
	<cfargument name="showUnaccepted" type="boolean" required="no" default="false">

	<cfset var georeferences = getResultGeoreferences(result_id = arguments.result_id, acceptedOnly = NOT arguments.showUnaccepted, mapByLocality = arguments.mapByLocality)>
	<cfset var PROPERTY_TERMS = "institutionCode,collectionCode,catalogNumber,scientificName,locality,locationID,geodeticDatum,coordinateUncertaintyInMeters,eventDate,georeferenceRemarks,references">
	<cfset var json = createObject("java", "java.lang.StringBuilder").init()>
	<cfset var terms = "">
	<cfset var term = "">
	<cfset var properties = "">
	<cfset var separator = "">
	<cfset var circlePoint = "">
	<cfset var circleCoordinates = "">
	<cfset var circlesDone = structNew()>
	<cfset var circleKey = "">
	<cfset json.append('{"type":"FeatureCollection","features":[')>
	<cfloop query="georeferences">
		<cfset terms = getGeoreferenceTerms(georeferences, georeferences.currentRow)>
		<cfset properties = "">
		<cfloop list="#PROPERTY_TERMS#" index="term">
			<cfif len(properties) GT 0>
				<cfset properties &= ",">
			</cfif>
			<cfif term EQ "coordinateUncertaintyInMeters" OR term EQ "locationID">
				<!--- numbers, or null --->
				<cfif len(terms[term]) GT 0>
					<cfset properties &= '#getJsonString(term)#:#getPlainNumber(terms[term])#'>
				<cfelse>
					<cfset properties &= '#getJsonString(term)#:null'>
				</cfif>
			<cfelse>
				<cfset properties &= '#getJsonString(term)#:#getJsonString(terms[term])#'>
			</cfif>
		</cfloop>
		<cfset json.append(separator & chr(10) & '{"type":"Feature","geometry":{"type":"Point","coordinates":[#terms.decimalLongitude#,#terms.decimalLatitude#]},"properties":{#properties#}}')>
		<cfset separator = ",">
		<cfif arguments.showErrors AND val(georeferences.error_in_meters) GT 0>
			<cfset circleKey = "#terms.decimalLatitude#|#terms.decimalLongitude#|#georeferences.error_in_meters#">
			<cfif NOT structKeyExists(circlesDone, circleKey)>
				<cfset circlesDone[circleKey] = true>
				<cfset circleCoordinates = "">
				<cfloop array="#getErrorCirclePoints(georeferences.dec_lat, georeferences.dec_long, georeferences.error_in_meters)#" index="circlePoint">
					<cfif len(circleCoordinates) GT 0>
						<cfset circleCoordinates &= ",">
					</cfif>
					<cfset circleCoordinates &= "[#circlePoint[1]#,#circlePoint[2]#]">
				</cfloop>
				<cfset json.append(separator & chr(10) & '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[#circleCoordinates#]]},"properties":{"featureType":"error circle","coordinateUncertaintyInMeters":#getPlainNumber(georeferences.error_in_meters)#}}')>
			</cfif>
		</cfif>
	</cfloop>
	<cfset json.append(chr(10) & ']}' & chr(10))>
	<cfreturn json.toString()>
</cffunction>

<!--- obtain a GPX document with a waypoint for each distinct georeference of the cataloged items in a
 result set, for handheld GPS units.
 @param result_id the guid for the result set.
 @param mapByLocality true for every cataloged item at each locality in the result.
 @param showUnaccepted true to include unaccepted georeferences.
 @return the GPX document.
--->
<cffunction name="getResultGpx" returntype="string" access="public" output="false">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="mapByLocality" type="boolean" required="no" default="false">
	<cfargument name="showUnaccepted" type="boolean" required="no" default="false">

	<cfset var georeferences = getResultGeoreferences(result_id = arguments.result_id, acceptedOnly = NOT arguments.showUnaccepted, mapByLocality = arguments.mapByLocality)>
	<!--- waypoints in the order first seen, each listing its cataloged items --->
	<cfset var waypointKeys = arrayNew(1)>
	<cfset var waypoints = structNew()>
	<cfset var waypointKey = "">
	<cfloop query="georeferences">
		<cfset waypointKey = "#int(georeferences.locality_id)#|#getPlainNumber(georeferences.dec_lat)#|#getPlainNumber(georeferences.dec_long)#">
		<cfif NOT structKeyExists(waypoints, waypointKey)>
			<cfset arrayAppend(waypointKeys, waypointKey)>
			<cfset waypoints[waypointKey] = {
				latitude = getPlainNumber(georeferences.dec_lat),
				longitude = getPlainNumber(georeferences.dec_long),
				name = "#georeferences.spec_locality# (#georeferences.locality_id#)",
				datum = georeferences.datum,
				items = ""
			}>
		</cfif>
		<cfif len(waypoints[waypointKey].items) GT 0>
			<cfset waypoints[waypointKey].items &= "; ">
		</cfif>
		<cfset waypoints[waypointKey].items &= "#georeferences.guid# #georeferences.scientific_name#">
	</cfloop>
	<cfset var gpx = createObject("java", "java.lang.StringBuilder").init()>
	<cfset gpx.append('<?xml version="1.0" encoding="UTF-8"?>' & chr(10))>
	<cfset gpx.append('<gpx version="1.1" creator="MCZbase" xmlns="http://www.topografix.com/GPX/1/1">' & chr(10))>
	<cfloop array="#waypointKeys#" index="waypointKey">
		<cfset gpx.append(chr(9) & '<wpt lat="#waypoints[waypointKey].latitude#" lon="#waypoints[waypointKey].longitude#">')>
		<cfset gpx.append('<name>#xmlFormat(waypoints[waypointKey].name)#</name>')>
		<cfset gpx.append('<desc>#xmlFormat("Datum: #waypoints[waypointKey].datum#. #waypoints[waypointKey].items#")#</desc>')>
		<cfset gpx.append('</wpt>' & chr(10))>
	</cfloop>
	<cfset gpx.append('</gpx>' & chr(10))>
	<cfreturn gpx.toString()>
</cffunction>

<!--- obtain a CSV file of the georeferenced cataloged items in a result set, a row for each cataloged
 item and georeference, with Darwin Core terms as column names and the error radius as a footprintWKT
 polygon.
 @param result_id the guid for the result set.
 @param mapByLocality true for every cataloged item at each locality in the result.
 @param showUnaccepted true to include unaccepted georeferences.
 @return the CSV file.
--->
<cffunction name="getResultDarwinCoreCsv" returntype="string" access="public" output="false">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="mapByLocality" type="boolean" required="no" default="false">
	<cfargument name="showUnaccepted" type="boolean" required="no" default="false">

	<cfset var georeferences = getResultGeoreferences(result_id = arguments.result_id, acceptedOnly = NOT arguments.showUnaccepted, mapByLocality = arguments.mapByLocality)>
	<cfset var CSV_TERMS = "institutionCode,collectionCode,catalogNumber,scientificName,locality,locationID,decimalLatitude,decimalLongitude,geodeticDatum,coordinateUncertaintyInMeters,footprintWKT,eventDate,georeferenceRemarks,references">
	<cfset var csv = createObject("java", "java.lang.StringBuilder").init()>
	<cfset var terms = "">
	<cfset var term = "">
	<cfset var line = "">
	<cfset var footprints = structNew()>
	<cfset var footprintKey = "">
	<cfset csv.append(CSV_TERMS & chr(13) & chr(10))>
	<cfloop query="georeferences">
		<cfset terms = getGeoreferenceTerms(georeferences, georeferences.currentRow)>
		<cfset terms["footprintWKT"] = "">
		<cfif val(georeferences.error_in_meters) GT 0>
			<cfset footprintKey = "#terms.decimalLatitude#|#terms.decimalLongitude#|#georeferences.error_in_meters#">
			<cfif NOT structKeyExists(footprints, footprintKey)>
				<cfset footprints[footprintKey] = getWktErrorCircle(georeferences.dec_lat, georeferences.dec_long, georeferences.error_in_meters)>
			</cfif>
			<cfset terms["footprintWKT"] = footprints[footprintKey]>
		</cfif>
		<cfset line = "">
		<cfloop list="#CSV_TERMS#" index="term">
			<cfif len(line) GT 0>
				<cfset line &= ",">
			</cfif>
			<cfset line &= getCsvField(terms[term])>
		</cfloop>
		<cfset csv.append(line & chr(13) & chr(10))>
	</cfloop>
	<cfreturn csv.toString()>
</cffunction>

<!--- obtain the points of a circle around a georeference, for its error radius.
 @param latitude the decimal latitude of the center.
 @param longitude the decimal longitude of the center.
 @param radius the radius in meters.
 @return an array of 361 [longitude, latitude] pairs as plain decimal strings, the last the same as the first.
--->
<cffunction name="getErrorCirclePoints" returntype="array" access="public" output="false">
	<cfargument name="latitude" type="numeric" required="yes">
	<cfargument name="longitude" type="numeric" required="yes">
	<cfargument name="radius" type="numeric" required="yes">

	<cfset var math = createObject("java", "java.lang.Math")>
	<cfset var lat = arguments.latitude * pi() / 180>
	<cfset var lon = arguments.longitude * pi() / 180>
	<!--- the radius as an angle, on a sphere of the WGS84 equatorial radius --->
	<cfset var angularRadius = arguments.radius / 6378137>
	<cfset var points = arrayNew(1)>
	<cfset var bearing = 0>
	<cfset var pointLat = 0>
	<cfset var pointLon = 0>
	<cfset var i = 0>
	<cfloop from="0" to="360" index="i">
		<cfset bearing = i * pi() / 180>
		<cfset pointLat = math.asin(javaCast("double", sin(lat) * cos(angularRadius) + cos(lat) * sin(angularRadius) * cos(bearing)))>
		<cfset pointLon = lon + math.atan2(javaCast("double", sin(bearing) * sin(angularRadius) * cos(lat)), javaCast("double", cos(angularRadius) - sin(lat) * sin(pointLat)))>
		<!--- back into -180 to 180; MOD is integer only --->
		<cfset pointLon = pointLon - 2 * pi() * int((pointLon + pi()) / (2 * pi()))>
		<cfset arrayAppend(points, [getPlainNumber(pointLon * 180 / pi(), 7), getPlainNumber(pointLat * 180 / pi(), 7)])>
	</cfloop>
	<cfreturn points>
</cffunction>

<!--- obtain a georeference's error circle as a WKT polygon, for the Darwin Core footprintWKT.
 @param latitude the decimal latitude of the center.
 @param longitude the decimal longitude of the center.
 @param radius the radius in meters.
 @return the POLYGON, longitude before latitude as WKT orders them.
--->
<cffunction name="getWktErrorCircle" returntype="string" access="public" output="false">
	<cfargument name="latitude" type="numeric" required="yes">
	<cfargument name="longitude" type="numeric" required="yes">
	<cfargument name="radius" type="numeric" required="yes">

	<cfset var ring = "">
	<cfset var circlePoint = "">
	<cfloop array="#getErrorCirclePoints(arguments.latitude, arguments.longitude, arguments.radius)#" index="circlePoint">
		<cfif len(ring) GT 0>
			<cfset ring &= ", ">
		</cfif>
		<cfset ring &= "#circlePoint[1]# #circlePoint[2]#">
	</cfloop>
	<cfreturn "POLYGON ((#ring#))">
</cffunction>

<!--- obtain a number as a plain decimal string, as ColdFusion may print small or large numbers in
 exponent form, which KML, GPX, GeoJSON and WKT don't accept.
 @param value the number, or an empty string.
 @param decimals the number of decimal places to round to, or -1 to keep the value's own.
 @return the number without an exponent, or an empty string.
--->
<cffunction name="getPlainNumber" returntype="string" access="public" output="false">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="decimals" type="numeric" required="no" default="-1">

	<cfif NOT isNumeric(arguments.value)>
		<cfreturn "">
	</cfif>
	<cfset var number = createObject("java", "java.math.BigDecimal").init(javaCast("string", arguments.value))>
	<cfif arguments.decimals GTE 0>
		<cfset number = number.setScale(javaCast("int", arguments.decimals), createObject("java", "java.math.RoundingMode").HALF_UP).stripTrailingZeros()>
	</cfif>
	<cfreturn number.toPlainString()>
</cffunction>

<!--- obtain a value as a JSON string literal.
 @param value the text.
 @return the text quoted, with quotes, backslashes and control characters escaped.
--->
<cffunction name="getJsonString" returntype="string" access="public" output="false">
	<cfargument name="value" type="string" required="yes">

	<cfset var escaped = replace(arguments.value, "\", "\\", "all")>
	<cfset escaped = replace(escaped, '"', '\"', "all")>
	<cfset escaped = replace(escaped, chr(10), "\n", "all")>
	<cfset escaped = replace(escaped, chr(13), "\r", "all")>
	<cfset escaped = replace(escaped, chr(9), "\t", "all")>
	<cfset escaped = REReplace(escaped, "[\x00-\x1F]", " ", "all")>
	<cfreturn '"#escaped#"'>
</cffunction>

<!--- obtain a value as a CSV field.
 @param value the text.
 @return the text in double quotes with its quotes doubled, prefixed with an apostrophe when it starts
  with a character a spreadsheet would take as the start of a formula and isn't a number.
--->
<cffunction name="getCsvField" returntype="string" access="public" output="false">
	<cfargument name="value" type="string" required="yes">

	<cfset var field = arguments.value>
	<cfif REFind("^[=+@\t\r-]", field) GT 0 AND NOT isNumeric(field)>
		<cfset field = "'" & field>
	</cfif>
	<cfreturn '"' & replace(field, '"', '""', "all") & '"'>
</cffunction>

</cfcomponent>
