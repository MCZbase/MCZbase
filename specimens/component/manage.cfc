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

	<cfset variables.result_id = arguments.result_id>
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
								<cfif collections.recordcount GT 1>
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

	<cfset variables.result_id = arguments.result_id>
	<cfthread name="getCountriesSummaryThread">
		<cfoutput>
			<cftry>
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
							<li class="list-group-item">#countries.continent_ocean#&thinsp;:&thinsp;#countries.country# (#countries.ct#); </li>
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

	<cfset variables.result_id = arguments.result_id>
	<cfthread name="getFamiliesSummaryThread">
		<cfoutput>
			<cftry>
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
							<li class="list-group-item">#families.phylorder#&thinsp;:&thinsp;#families.family# (#families.ct#);</li>
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
<cffunction name="getAccessionsSummaryHtml" returntype="string" access="remote" returnformat="plain">
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

	<cfset variables.result_id = arguments.result_id>
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
								<cfif prefixes.recordcount GT 1>
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

</cfcomponent>
