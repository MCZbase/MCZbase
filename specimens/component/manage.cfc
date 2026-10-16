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
	<cfset var useFlat = false>
	<cfif ucase(session.flatTableName) EQ "FLAT">
		<cfset useFlat = true>
	</cfif>
	<cfset var kmlData = "">
	<cfset var kmlData_result = "">
	<cfset var kmlSpecies = "">
	<cfset var kmlSpeciesRecords = "">
	<cfset var kmlCollections = "">
	<cfset var kmlLocalities = "">
	<cfset var kmlErrors = "">
	<cfquery name="kmlData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="kmlData_result" timeout="#Application.query_timeout#">
		SELECT DISTINCT
			flatTableName.collection_object_id,
			flatTableName.guid,
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
			<cfif bySpecies OR NOT arguments.showUnaccepted>
				AND lat_long.accepted_lat_long_fg = 1
			</cfif>
			<cfif NOT bySpecies AND arguments.mapByLocality>
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
			<cfset speciesColor = right("00000" & formatBaseN(randRange(0, 16777215), 16), 6)>
			<cfset kml.append(tab & tab & '<Style id="species#kmlSpecies.currentRow#"><IconStyle><color>ff#speciesColor#</color><scale>1.1</scale>')>
			<cfset kml.append('<Icon><href>#xmlFormat(Application.serverRootUrl)#/images/whiteBalloon.png</href></Icon></IconStyle></Style>' & nl)>
		</cfloop>
		<cfloop query="kmlSpecies">
			<cfquery name="kmlSpeciesRecords" dbtype="query">
				SELECT collection, cat_num, scientific_name, dec_lat, dec_long, error_in_meters, datum, began_date, ended_date
				FROM kmlData
				WHERE scientific_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#kmlSpecies.scientific_name#">
			</cfquery>
			<cfset kml.append(tab & tab & '<Folder>' & nl & tab & tab & tab & '<name>#xmlFormat(kmlSpecies.scientific_name)#</name>' & nl & tab & tab & tab & '<visibility>1</visibility>' & nl)>
			<cfloop query="kmlSpeciesRecords">
				<cfset kml.append(tab & tab & tab & '<Placemark>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<name>#xmlFormat("#kmlSpeciesRecords.collection# #kmlSpeciesRecords.cat_num# (#kmlSpeciesRecords.scientific_name#)")#</name>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<visibility>1</visibility>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<description><![CDATA[Datum: #encodeForHtml(kmlSpeciesRecords.datum)#<br/>Error: #encodeForHtml(kmlSpeciesRecords.error_in_meters)# m<br/>]]></description>' & nl)>
				<cfif arguments.includeTimeSpan>
					<cfset kml.append(tab & tab & tab & tab & '<TimeSpan><begin>#xmlFormat(kmlSpeciesRecords.began_date)#</begin><end>#xmlFormat(kmlSpeciesRecords.ended_date)#</end></TimeSpan>' & nl)>
				</cfif>
				<cfset kml.append(tab & tab & tab & tab & '<styleUrl>##' & speciesStyle[kmlSpecies.scientific_name] & '</styleUrl>' & nl)>
				<cfset kml.append(tab & tab & tab & tab & '<Point><coordinates>#kmlSpeciesRecords.dec_long#,#kmlSpeciesRecords.dec_lat#,0</coordinates></Point>' & nl)>
				<cfset kml.append(tab & tab & tab & '</Placemark>' & nl)>
			</cfloop>
			<cfset kml.append(tab & tab & '</Folder>' & nl)>
		</cfloop>
	<cfelse>
		<cfset kml.append(tab & tab & '<Style id="green-star"><IconStyle><Icon><href>https://maps.google.com/mapfiles/kml/paddle/grn-stars.png</href></Icon></IconStyle></Style>' & nl)>
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
		<cfquery name="kmlCollections" dbtype="query">
			SELECT collection
			FROM kmlData
			GROUP BY collection
			ORDER BY collection
		</cfquery>
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
				<cfset kml.append(tab & tab & tab & tab & '<description><![CDATA[Datum: #encodeForHtml(kmlLocalities.datum)#<br/>Error: #encodeForHtml(kmlLocalities.error_in_meters)# m<br/>#localityLink##localityItems[int(kmlLocalities.locality_id)]#]]></description>' & nl)>
				<cfif arguments.includeTimeSpan>
					<cfset kml.append(tab & tab & tab & tab & '<TimeSpan><begin>#xmlFormat(kmlLocalities.began_date)#</begin><end>#xmlFormat(kmlLocalities.ended_date)#</end></TimeSpan>' & nl)>
				</cfif>
				<cfif kmlLocalities.accepted_lat_long_fg EQ 1>
					<cfset kml.append(tab & tab & tab & tab & '<styleUrl>##green-star</styleUrl>' & nl)>
				<cfelse>
					<cfset kml.append(tab & tab & tab & tab & '<styleUrl>##red-star</styleUrl>' & nl)>
				</cfif>
				<cfset kml.append(tab & tab & tab & tab & '<Point><coordinates>#kmlLocalities.dec_long#,#kmlLocalities.dec_lat#</coordinates></Point>' & nl)>
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
			<cfloop query="kmlErrors">
				<cfset kml.append(getKmlErrorCircle(kmlErrors.dec_lat, kmlErrors.dec_long, kmlErrors.error_in_meters))>
			</cfloop>
			<cfset kml.append(tab & tab & '</Folder>' & nl)>
		</cfif>
	</cfif>
	<cfset kml.append(tab & '</Document>' & nl & '</kml>' & nl)>
	<cfreturn kml.toString()>
</cffunction>

<!--- obtain a KML placemark drawing a circle around a point, for a georeference's error radius.
 @param latitude the decimal latitude of the center.
 @param longitude the decimal longitude of the center.
 @param radius the radius in meters.
 @return a Placemark element with a LineString of 361 points, styled with error-line.
--->
<cffunction name="getKmlErrorCircle" returntype="string" access="public" output="false">
	<cfargument name="latitude" type="numeric" required="yes">
	<cfargument name="longitude" type="numeric" required="yes">
	<cfargument name="radius" type="numeric" required="yes">

	<cfset var math = createObject("java", "java.lang.Math")>
	<cfset var lat = arguments.latitude * pi() / 180>
	<cfset var lon = arguments.longitude * pi() / 180>
	<!--- the radius as an angle, on a sphere of the WGS84 equatorial radius --->
	<cfset var angularRadius = arguments.radius / 6378137>
	<cfset var coordinates = createObject("java", "java.lang.StringBuilder").init()>
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
		<cfset coordinates.append(chr(10) & "#pointLon * 180 / pi()#,#pointLat * 180 / pi()#")>
	</cfloop>
	<cfreturn chr(9) & chr(9) & chr(9) & '<Placemark><name>Error</name><visibility>1</visibility><styleUrl>##error-line</styleUrl><LineString><coordinates>' & coordinates.toString() & chr(10) & '</coordinates></LineString></Placemark>' & chr(10)>
</cffunction>

</cfcomponent>
