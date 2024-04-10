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
							<a href="/bnhmMaps/SpecimensByLocality.cfm?result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">
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
			user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
			AND flatTableName.dec_lat is not null 
			AND flatTableName.dec_long is not null 
	</cfquery>
	<cfreturn countGeorefs.ct>
</cffunction>

</cfcomponent>
