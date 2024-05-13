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
								<cfif findNoCase('master',Session.gitBranch) EQ 0>
								<cfif collections.recordcount GT 1>
									<input type="button" onClick=" confirmDialog('Remove all records from #collections.collection_cde# from these search results','Confirm Remove By Collection Code', function() { removeCollection ('#collection_cde#'); }  ); " class="p-1 btn btn-xs btn-warning" value="&##8998;" aria-label="Remove"/>
								</cfif>
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
</cfcomponent>
