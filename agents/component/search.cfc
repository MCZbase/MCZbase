<!---
agents/component/search.cfc

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

--->
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- function getAgents search for agents returning json suitable for a jqxgrid --->
<cffunction name="getAgents" access="remote" returntype="any" returnformat="json">
	<cfargument name="agent_type" type="string" required="no">
	<cfargument name="edited" type="string" required="no">
	<cfargument name="first_name" type="string" required="no">
	<cfargument name="last_name" type="string" required="no">
	<cfargument name="middle_name" type="string" required="no">
	<cfargument name="suffix" type="string" required="no">
	<cfargument name="prefix" type="string" required="no">
	<cfargument name="birth_date" type="string" required="no">
	<cfargument name="death_date" type="string" required="no">
	<cfargument name="collected_date" type="string" required="no">
	<cfargument name="to_birth_date" type="string" required="no">
	<cfargument name="to_death_date" type="string" required="no">
	<cfargument name="to_collected_date" type="string" required="no">
	<cfargument name="anyName" type="string" required="no">
	<cfargument name="agent_id" type="string" required="no">
	<cfargument name="address" type="string" required="no">
	<cfargument name="email" type="string" required="no">
	<cfargument name="phone" type="string" required="no">
	<cfargument name="agent_remarks" type="string" required="no">
	<cfargument name="biography" type="string" required="no">
	<cfargument name="remarks_biography" type="string" required="no">
	<cfargument name="ranking" type="string" required="no">
	<cfargument name="collector_collection" type="string" required="no">
	<cfargument name="author_collection" type="string" required="no">
	<cfargument name="trans_agent_collection" type="string" required="no">
	<cfargument name="permit_agent_role" type="string" required="no">

	<!--- clear any arguments where only an operator is given without a search term --->
	<cfif isdefined("first_name") AND first_name IS "="><cfset first_name = ""></cfif>
	<cfif isdefined("first_name") AND first_name IS "!"><cfset first_name = ""></cfif>
	<cfif isdefined("first_name") AND first_name IS "$"><cfset first_name = ""></cfif>
	<cfif isdefined("middle_name") AND middle_name IS "="><cfset middle_name = ""></cfif>
	<cfif isdefined("middle_name") AND middle_name IS "!"><cfset middle_name = ""></cfif>
	<cfif isdefined("middle_name") AND middle_name IS "$"><cfset middle_name = ""></cfif>
	<cfif isdefined("last_name") AND last_name IS "="><cfset last_name = ""></cfif>
	<cfif isdefined("last_name") AND last_name IS "!"><cfset last_name = ""></cfif>
	<cfif isdefined("last_name") AND last_name IS "$"><cfset last_name = ""></cfif>
	<cfif isdefined("anyName") AND anyName IS "="><cfset anyName = ""></cfif>
	<cfif isdefined("anyName") AND anyName IS "~"><cfset anyName = ""></cfif>

	<!--- if remarks_biography has a value, ignore remarks and biography --->
	<cfif isdefined("remarks_biography") AND len(remarks_biography) GT 0 >
		<cfset remarks="">
		<cfset biography="">
	</cfif>
	<!--- TODO: allow relaxation of this criterion --->
	<cfset knowntoyear = "yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<!--- Setup date ranges to use yyyy-mm-dd start and end dates even if only partial dates were provided --->
		<cfif isdefined("collected_date") and len(#collected_date#) gt 0>
			<!--- set start/end date range terms to same if only one is specified --->
			<cfif not isdefined("to_collected_date") or len(to_collected_date) is 0>
				<cfset to_collected_date=collected_date>
			</cfif>
			<cfif len(#collected_date#) LT 10 OR len(#to_collected_date#) LT 10>
				<cfquery name="lookupdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.short_timeout#">
					select to_char(to_startdate(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collected_date#">),'yyyy-mm-dd') as startdate,  
						to_char(to_enddate(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#to_collected_date#">),'yyyy-mm-dd') as enddate
					from dual
				</cfquery>
				<!--- support search on just a year or pair of years or pair of year-month --->
				<cfif len(#collected_date#) LT 10>
					<cfset collected_date = lookupdate.startdate>
				</cfif>
				<cfif len(#to_collected_date#) LT 10>
					<cfset to_collected_date = lookupdate.enddate>
				</cfif>
			</cfif>
		</cfif>
		<cfif isdefined("birth_date") AND len(#birth_date#) GT 0 AND NOT birth_date IS "NULL" AND NOT birth_date IS "NOT NULL" >
			<cfif NOT isdefined("session.roles") OR ( isdefined("session.roles") and NOT listfindnocase(session.roles,"coldfusion_user"))>
				<!--- truncate date to year --->
				<cfif len(#birth_date#) GT 4 ><cfset birth_date = left(birth_date,4)></cfif>
				<cfif len(#to_birth_date#) GT 4 ><cfset to_birth_date = left(to_birth_date,4)></cfif>
			</cfif>
			<!--- set start/end date range terms to same if only one is specified --->
			<cfif not isdefined("to_birth_date") or len(to_birth_date) is 0>
				<cfset to_birth_date=birth_date>
			</cfif>
			<cfif len(#birth_date#) LT 10 OR len(#to_birth_date#) LT 10 >
				<cfquery name="lookupbdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.short_timeout#">
					select to_char(to_startdate(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#birth_date#">),'yyyy-mm-dd') as startdate,  
						to_char(to_enddate(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#to_birth_date#">),'yyyy-mm-dd') as enddate
					from dual
				</cfquery>
				<!--- support search on just a year or pair of years or pair of year-month --->
				<cfif len(#birth_date#) LT 10 > 
					<cfset birth_date = lookupbdate.startdate>
				</cfif>
				<cfif len(#to_birth_date#) LT 10>
					<cfset to_birth_date = lookupbdate.enddate>
				</cfif>
			</cfif>
		</cfif>
		<cfif isdefined("death_date") and len(#death_date#) gt 0 AND NOT death_date IS "NULL" AND NOT death_date IS "NOT NULL">
			<cfif NOT isdefined("session.roles") OR ( isdefined("session.roles") and NOT listfindnocase(session.roles,"coldfusion_user"))>
				<!--- truncate date to year --->
				<cfif len(#death_date#) GT 4 ><cfset death_date = left(death_date,4)></cfif>
				<cfif len(#to_death_date#) GT 4 ><cfset to_death_date = left(to_death_date,4)></cfif>
			</cfif>
			<!--- set start/end date range terms to same if only one is specified --->
			<cfif not isdefined("to_death_date") or len(to_death_date) is 0>
				<cfset to_death_date=death_date>
			</cfif>
			<cfif len(#death_date#) LT 10 OR len(#to_death_date#) LT 10>
				<cfquery name="lookupddate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.short_timeout#">
					select to_char(to_startdate(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#death_date#">),'yyyy-mm-dd') as startdate,  
						to_char(to_enddate(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#to_death_date#">),'yyyy-mm-dd') as enddate
					from dual
				</cfquery>
				<!--- support search on just a year or pair of years or pair of year-month --->
				<cfif len(#death_date#) LT 10>
					<cfset death_date = lookupddate.startdate>
				</cfif>
				<cfif len(#to_death_date#) LT 10>
					<cfset to_death_date = lookupddate.enddate>
				</cfif>
			</cfif>
		</cfif>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT distinct
				preferred_agent_name.agent_id as agent_id,
				preferred_agent_name.agent_name as agent_name,
				agent_type,
				agent.edited,
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					MCZBASE.get_worstagentrank(agent.agent_id) as worstagentrank,
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					birth_date,
					death_date,
				<cfelse>
					(case when death_date is not null then substr(birth_date,0,4) else null end) as birth_date,
					substr(death_date,0,4) as death_date,
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					agent_remarks,
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					MCZBASE.GET_EMAILADDRESSES(agent.agent_id) as emails,
					MCZBASE.GET_NONEMAILEADDRESSES(agent.agent_id) as phones,
				</cfif>
				person.prefix,
				person.first_name,
				person.middle_name,
				person.last_name,
				person.suffix,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'preferred') as preferred,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'abbreviation') as abbreviation,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'author') as author,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'second author') as second_author,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'expanded') as expanded,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'full') as full,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'initials') as initials,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'initials plus last') as initials_plus_last,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'last_plus_initials') as last_plus_initials,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'maiden') as maiden,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'married') as married,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'aka') as aka,
				MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'acronym') as acronym,
				MCZBASE.get_collectorscope(agent.agent_id,'collections') as collections_scope,
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
					MCZBASE.GET_AGENTNAMEOFTYPE_EXISTS(agent.agent_id,'login') as login,
				</cfif>
				agentguid
			FROM 
				agent_name
				left outer join preferred_agent_name ON agent_name.agent_id = preferred_agent_name.agent_id
				LEFT OUTER JOIN agent ON agent_name.agent_id = agent.agent_id
				LEFT OUTER JOIN person ON agent.agent_id = person.person_id
				<cfif isdefined("collected_date") AND len(#collected_date#) gt 0>
					LEFT OUTER JOIN collector ON agent.agent_id = collector.agent_id
					LEFT OUTER JOIN cataloged_item on collector.collection_object_id = cataloged_item.collection_object_id
					LEFT OUTER JOIN collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
				</cfif>
			WHERE
				agent.agent_id > -1
				<cfif isdefined("agent_type") AND len(#agent_type#) gt 0>
					<cfif left(agent_type,1) is "!">
						AND agent_type <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(agent_type,len(agent_type)-1)#">
					<cfelse>
						AND agent_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_type#">
					</cfif>
				</cfif>
				<cfif isdefined("edited") AND len(#edited#) gt 0>
					AND edited = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#edited#">
				</cfif>
				<cfif isdefined("first_name") AND len(first_name) gt 0>
					<cfif left(first_name,2) is "==">
						AND first_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(first_name,len(first_name)-2)#">
					<cfelseif left(first_name,1) is "=">
						AND upper(first_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(first_name,len(first_name)-1))#">
					<cfelseif left(first_name,2) is "!!">
						AND first_name <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(first_name,len(first_name)-2)#">
					<cfelseif left(first_name,1) is "$">
						AND soundex(first_name) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(first_name,len(first_name)-1))#">)
					<cfelseif left(first_name,2) is "!$">
						AND soundex(first_name) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(first_name,len(first_name)-2))#">)
					<cfelseif left(first_name,1) is "!">
						AND upper(first_name) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(first_name,len(first_name)-1))#">
					<cfelseif first_name is "NULL">
						AND first_name is null
					<cfelseif first_name is "NOT NULL">
						AND first_name is not null
					<cfelse>
						<cfif find(',',first_name) GT 0>
							AND upper(first_name) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(first_name)#" list="yes"> )
						<cfelse>
							AND upper(first_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(first_name)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("middle_name") AND len(middle_name) gt 0>
					<cfif left(middle_name,2) is "==">
						AND middle_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(middle_name,len(middle_name)-2)#">
					<cfelseif left(middle_name,1) is "=">
						AND upper(middle_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(middle_name,len(middle_name)-1))#">
					<cfelseif left(middle_name,2) is "!!">
						AND middle_name <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(middle_name,len(middle_name)-2)#">
					<cfelseif left(middle_name,1) is "$">
						AND soundex(middle_name) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(middle_name,len(middle_name)-1))#">)
					<cfelseif left(middle_name,2) is "!$">
						AND soundex(middle_name) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(middle_name,len(middle_name)-2))#">)
					<cfelseif left(middle_name,1) is "!">
						AND upper(middle_name) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(middle_name,len(middle_name)-1))#">
					<cfelseif middle_name is "NULL">
						AND middle_name is null
					<cfelseif middle_name is "NULL">
						AND middle_name is null
					<cfelseif middle_name is "NOT NULL">
						AND middle_name is not null
					<cfelse>
						<cfif find(',',middle_name) GT 0>
							AND upper(middle_name) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(middle_name)#" list="yes"> )
						<cfelse>
							AND upper(middle_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(middle_name)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("last_name") AND len(last_name) gt 0>
					<cfif left(last_name,2) is "==">
						AND last_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(last_name,len(last_name)-2)#">
					<cfelseif left(last_name,1) is "=">
						AND upper(last_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(last_name,len(last_name)-1))#">
					<cfelseif left(last_name,2) is "!!">
						AND last_name <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(last_name,len(last_name)-2)#">
					<cfelseif left(last_name,1) is "$">
						AND soundex(last_name) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(last_name,len(last_name)-1)#">)
					<cfelseif left(last_name,2) is "!$">
						AND soundex(last_name) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(last_name,len(last_name)-2)#">)
					<cfelseif left(last_name,1) is "!">
						AND upper(last_name) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(last_name,len(last_name)-1))#">
					<cfelseif last_name is "NULL">
						AND last_name is null
					<cfelseif last_name is "NOT NULL">
						AND last_name is not null
					<cfelse>
						<cfif find(',',last_name) GT 0>
							AND upper(last_name) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(last_name)#" list="yes"> )
						<cfelse>
							AND upper(last_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(last_name)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("prefix") AND len(#prefix#) gt 0>
					<cfif left(prefix,1) is "!">
						AND upper(prefix) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(prefix,len(prefix)-1))#">
					<cfelseif prefix is "NULL">
						AND prefix is null
					<cfelseif prefix is "NOT NULL">
						AND prefix is not null
					<cfelse>
						AND prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#prefix#">
					</cfif>
				</cfif>
				<cfif isdefined("suffix") AND len(#suffix#) gt 0>
					<cfif left(suffix,1) is "!">
						AND upper(suffix) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(suffix,len(suffix)-1))#">
					<cfelseif suffix is "NULL">
						AND suffix is null
					<cfelseif suffix is "NOT NULL">
						AND suffix is not null
					<cfelse>
						AND suffix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#suffix#">
					</cfif>
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfif isdefined("birth_date") AND len(#birth_date#) gt 0>
						<cfif birth_date IS "NULL">
							AND birth_date IS NULL
						<cfelseif birth_date IS "NOT NULL">
							AND birth_date IS NOT NULL
						<cfelse>
							<cfset bdate = dateformat(birth_date,'yyyy-mm-dd')>
							<cfset to_bdate = dateformat(to_birth_date,'yyyy-mm-dd')>
							AND birth_date >= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#bdate#">
							AND birth_date <= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#to_bdate#">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("death_date") AND len(#death_date#) gt 0>
					<cfif death_date IS "NULL">
						AND death_date IS NULL
					<cfelseif death_date IS "NOT NULL">
						AND death_date IS NOT NULL
					<cfelse>
						<cfset ddate = dateformat(death_date,'yyyy-mm-dd')>
						<cfset to_ddate = dateformat(to_death_date,'yyyy-mm-dd')>
						AND death_date >= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ddate#">
						AND death_date <= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#to_ddate#">
					</cfif>
				</cfif>
				<cfif isdefined("collected_date") and len(collected_date) gt 0>
					AND collector_role = 'c'
					<cfif isdefined("knowntoyear") and knowntoyear EQ 'yes'>
						AND (
							(
								began_date between <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collected_date#"> and <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#to_collected_date#">
								OR 
								ended_date between <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collected_date#"> and <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#to_collected_date#">
							)
							AND
							(substr(began_date,0,4) = substr(ended_date,0,4))
						)
					<cfelse>
						AND (
							(began_date between <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collected_date#"> and <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#to_collected_date#">)
							OR (ended_date between <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collected_date#"> and <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#to_collected_date#">)
							OR (began_date <= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#to_collected_date#"> and ended_date >= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collected_date#"> and began_date <> '1700-01-01')
						)
					</cfif>
				</cfif>
				<cfif isdefined("anyName") AND len(anyName) gt 0>
					<cfif left(anyName,1) is "=">
						AND upper(agent_name.agent_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(anyName,len(anyName)-1))#">
					<cfelseif left(anyName,1) is "~">
						AND utl_match.jaro_winkler(agent_name.agent_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(anyName,len(anyName)-1)#">) >= 0.80
					<cfelseif left(anyName,1) is "!~">
						AND utl_match.jaro_winkler(agent_name.agent_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(anyName,len(anyName)-1)#">) < 0.80
					<cfelseif left(anyName,1) is "!">
						AND upper(agent_name.agent_name) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(anyName,len(anyName)-1))#">
					<cfelseif anyName is "NULL">
						AND agent_name.agent_name is null
					<cfelseif anyName is "NOT NULL">
						AND agent_name.agent_name is not null
					<cfelse>
						<cfif find(',',anyName) GT 0>
							AND upper(agent_name.agent_name) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(anyName)#" list="yes"> )
						<cfelse>
							AND (
								upper(agent_name.agent_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(anyName)#%"> OR
								upper(person.last_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(anyName)#%"> OR
								upper(person.middle_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(anyName)#%"> OR
								upper(person.first_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(anyName)#%">
								)
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("agent_id") AND isnumeric(#agent_id#)>
					AND agent_name.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfif isdefined("agent_remarks") AND len(agent_remarks) GT 0>
						<cfif agent_remarks is "NULL">
							AND agent_remarks is null
						<cfelseif agent_remarks is "NOT NULL">
							AND agent_remarks is not null
						<cfelse>
							AND upper(agent.agent_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_remarks)#%">
						</cfif>
					</cfif>
					<cfif isdefined("biography") AND len(biography) GT 0>
						<cfif biography is "NULL">
							AND biography is null
						<cfelseif biography is "NOT NULL">
							AND biography is not null
						<cfelse>
							AND upper(agent.biography) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(biography)#%">
						</cfif>
					</cfif>
					<cfif isdefined("remarks_biography") AND len(remarks_biography) GT 0>
						AND (
							upper(agent.agent_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(remarks_biography)#%"> 
							OR 
							upper(agent.biography) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(remarks_biography)#%"> 
							)
					</cfif>
					<cfif isdefined("address") AND len(#address#) gt 0>
						AND agent.agent_id IN (
							select agent_id from addr where upper(formatted_addr) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(address)#%">
						)
					</cfif>
					<cfif isdefined("email") AND len(#email#) gt 0>
						AND agent.agent_id IN (
							select agent_id from electronic_address 
							where upper(address) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(email)#%">
								and address_type = 'email'
						)
					</cfif>
					<cfif isdefined("phone") AND len(#phone#) gt 0>
						AND agent.agent_id IN (
							select agent_id from electronic_address 
							where upper(address) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phone)#%">
								and address_type <> 'email'
						)
					</cfif>
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					<cfif isdefined("ranking") AND len(#ranking#) gt 0>
						<cfif ranking EQ "any">
							AND MCZBASE.get_worstagentrank(agent.agent_id) <> 'A'
						<cfelseif ranking EQ "none">
							AND MCZBASE.get_worstagentrank(agent.agent_id) = 'A'
					 	</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("collector_collection") AND len(#collector_collection#) gt 0>
					AND agent.agent_id IN (
						select agent_id 
						from collector
							left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on collector.collection_object_id = flat.collection_object_id
						where flat.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collector_collection#">
					)
				</cfif>
				<cfif isdefined("author_collection") AND len(#author_collection#) gt 0>
					AND agent.agent_id IN (
						select agent_name.agent_id 
						from 
							publication_author_name 
							left join agent_name on publication_author_name.agent_name_id = agent_name.agent_name_id
							left join citation on publication_author_name.publication_id = citation.PUBLICATION_ID
							left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on citation.collection_object_id = flat.collection_object_id
						where flat.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#author_collection#">
					)
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					<cfif isdefined("trans_agent_collection") AND len(#trans_agent_collection#) gt 0>
						AND agent.agent_id IN (
							SELECT agent_id 
							FROM trans_agent
								left join trans on trans_agent.transaction_id = trans.transaction_id
							WHERE trans.collection_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_collection#">
						)
					</cfif>
					<cfif isdefined("permit_agent_role") AND len(#permit_agent_role#) gt 0>
						<cfif permit_agent_role EQ "any">
							AND agent.agent_id IN (
								select distinct agent_id from (
									select issued_by_agent_id as agent_id from permit
									union
									select issued_to_agent_id as agent_id from permit
									union
									select contact_agent_id as agent_id from permit
								)
								where agent_id is not null
							)
						<cfelseif permit_agent_role EQ "issued by">
							AND agent.agent_id IN (
								select issued_by_agent_id from permit
								where issued_by_agent_id is not null
							)
						<cfelseif permit_agent_role EQ "issued to">
							AND agent.agent_id IN (
								select issued_to_agent_id from permit
								where issued_to_agent_id is not null
							)
						<cfelseif permit_agent_role EQ "contact">
							AND agent.agent_id IN (
								select contact_agent_id from permit
								where contact_agent_id is not null
							)
						</cfif>
					</cfif>
				</cfif>
			ORDER BY 
				preferred_agent_name.agent_name
		</cfquery>

		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfif col EQ "AGENT_REMARKS">
					<!--- strip html markup out of remarks --->
					<cfset row["agent_remarks"] = REReplace(search.agent_remarks,"<[^>]*(?:>|$)","","ALL")>
				<cfelseif col EQ "EDITED">
					<cfset row["edited"] = edited_marker >
				<cfelse>
					<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
				</cfif>
			</cfloop>
			<cfset row["id_link"] = "<a href='/agents/Agent.cfm?agent_id#search.agent_id#' target='_blank'>#search.agent_name# #edited_marker#</a>">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getAgentList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>
<!---
Function getAgentList.  Search for agents by name with a substring match on any name, returning json suitable for a dataadaptor.

@param name agent name to search for.
@return a json structure containing matching agents with matched names, preferred names, types, edited states, and links.
--->
<cffunction name="getAgentList" access="remote" returntype="any" returnformat="json">
	<cfargument name="name" type="string" required="yes">
	<!--- perform wildcard search anywhere in agent_name.agent_name --->
	<cfset name = "%#name#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				searchname.agent_id, searchname.agent_name, searchname.agent_name_type,
				agent.agent_type, agent.edited,
				prefername.agent_name as preferred_agent_name
			FROM 
				agent_name searchname
				left join agent on searchname.agent_id = agent.agent_id
				left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
			WHERE
				searchname.agent_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#name#">
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["agent_id"] = "#search.agent_id#">
			<cfset row["agent_name"] = "#search.agent_name#">
			<cfset row["agent_name_type"] = "#search.agent_name_type#">
			<cfset row["agent_type"] = "#search.agent_type#">
			<cfset row["edited"] = "#search.edited#">
			<cfset row["preferred_agent_name"] = "#search.preferred_agent_name#">
			<cfif search.preferred_agent_name EQ search.agent_name >
				<cfset row["id_link"] = "<a href='/agents/Agent.cfm?agent_id#search.agent_id#' target='_blank'>#search.agent_name# #edited_marker#</a>">
			<cfelse>
				<cfset row["id_link"] = "<a href='/agents/Agent.cfm?agent_id#search.agent_id#' target='_blank'>#search.agent_name# (#search.preferred_agent_name#)#edited_marker#</a>">
			</cfif>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getAgentList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getPreferredNameExists Check if a prefered name exists.

@param agent_name name to look up.
@return 1 if one or more preferred names exactly matching the provided string exists, otherwise 0, 
 returns an http 500 status in the case of an error.
--->
<cffunction name="getPreferredNameExists" access="remote" returntype="any" returnformat="json">
	<cfargument name="agent_name" type="string" required="yes">

	<cfset retval ="">
	<cftry>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.short_timeout#">
			select count(*) as ct from agent_name
			where
				agent_name_type = 'preferred'
				and agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_name#">
		</cfquery>
		<cfset retval = search.ct>
		<cfif retval GT 1><cfset retval = 1></cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>

	<cfreturn #retval#>
</cffunction>
<!---
Function getAgentAutocomplete.  Search for agents by name with a substring match on any name, returning json suitable for jquery-ui autocomplete.

@param term agent name to search for.
@return a json structure containing id and value, with matching agents with matched name in value and agent_id in id.
--->
<cffunction name="getAgentAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in agent_name.agent_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				searchname.agent_id, searchname.agent_name, 
				agent.agent_type, agent.edited,
				prefername.agent_name as preferred_agent_name
			FROM 
				agent_name searchname
				left join agent on searchname.agent_id = agent.agent_id
				left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
			WHERE
				upper(searchname.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["id"] = "#search.agent_id#">
			<cfif search.preferred_agent_name EQ search.agent_name >
				<cfset row["value"] = "#search.agent_name# #edited_marker#" >
			<cfelse>
				<cfset row["value"] = "#search.agent_name# (#search.preferred_agent_name#)#edited_marker#" >
			</cfif>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getAgentList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getAgentAutocompleteMeta.  Search for agents by name with a substring match on any name, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just the agent name as the selected value.

@param term agent name to search for.
@param constraint limit agents to those agents where the constraint applies, supports:  permit_issued_by_agent,
	permit_issued_to_agent, permit_contact_agent, transaction_agent, project_agent, media_agent, media_creator_agent, 
	determiner, collector, preparator, author, editor, entered_by.
@param show_agent_id if no value provided, then do not include the agent_id in the meta, otherwise included the agent_id in the meta.
@return a json structure containing id and value, with matching agents with matched name in value and agent_id in id, and matched name 
  with * and preferred name in meta.
--->
<cffunction name="getAgentAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="constraint" type="string" required="no">
	<cfargument name="show_agent_id" type="string" required="no">
	<!--- perform wildcard search anywhere in agent_name.agent_name --->
	<cfset name = "%#term#%"> 

	<cfif not isDefined("show_agent_id") OR len(show_agent_id) EQ 0 >
		<cfset show_agent_id = false>
	<cfelse>
		<cfset show_agent_id = true>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT distinct
				searchname.agent_id, searchname.agent_name,
				agent.agent_type, agent.edited,
				prefername.agent_name as preferred_agent_name
			FROM 
				agent_name searchname
				left join agent on searchname.agent_id = agent.agent_id
				left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
				<cfif isdefined("constraint") AND constraint EQ 'permit_issued_by_agent'>
					left join permit on agent.agent_id = permit.issued_by_agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'permit_issued_to_agent'>
					left join permit on agent.agent_id = permit.issued_to_agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'permit_contact_agent'>
					left join permit on agent.agent_id = permit.contact_agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'transaction_agent'>
					left join trans_agent on agent.agent_id = trans_agent.agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'project_agent'>
					left join project_agent on searchname.agent_name_id = trans_agent.agent_name_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'media_agent'>
					left join media_relations on agent.agent_id = media_relations.related_primary_key
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'media_creator_agent'>
					left join media_relations on agent.agent_id = media_relations.related_primary_key
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'determiner'>
					join identification_agent on agent.agent_id = identification_agent.agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'collector'>
					join collector on agent.agent_id = collector.agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'preparator'>
					join collector on agent.agent_id = collector.agent_id
				</cfif>
				<cfif isdefined("constraint") AND ( constraint EQ 'author' OR constraint EQ 'editor' )>
					join agent_name pub_agent_name on agent.agent_id = pub_agent_name.agent_id
					join publication_author_name on pub_agent_name.agent_name_id = publication_author_name.agent_name_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'georeference_determiner'>
					join lat_long on agent.agent_id = lat_long.determined_by_agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'georeference_verifier'>
					join lat_long on agent.agent_id = lat_long.verified_by_agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'ce_date_determiner'>
					join collecting_event on agent.agent_id = collecting_event.date_determined_by_agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'entered_by'>
					left join coll_object on agent.agent_id = coll_object.entered_person_id
				</cfif>
			WHERE
				upper(searchname.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				<cfif isdefined("constraint") AND (constraint EQ 'permit_issued_to_agent' or constraint EQ 'permit_issued_by_agent' or constraint EQ 'permit_contact_agent' )>
					AND permit.permit_id is not null
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'transaction_agent'>
					AND trans_agent.trans_agent_id is not null
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'project_agent'>
					AND project_agent.project_id is not null
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'organization_agent'>
					AND agent.agent_type = 'organization'
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'media_agent'>
					AND media_relations.media_relationship like '% agent'
					AND media_relations.media_relationship <> 'created by agent'
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'media_creator_agent'>
					AND media_relations.media_relationship = 'created by agent'
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'determiner'>
					AND identification_agent.agent_id IS NOT NULL
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'collector'>
					AND collector.collector_role = 'c'
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'preparator'>
					AND collector.collector_role = 'p'
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'author'>
					and publication_author_name.author_role = 'author'
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'editor'>
					and publication_author_name.author_role = 'editor'
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'georeference_determiner'>
					and lat_long.determined_by_agent_id is not null
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'georeference_verifier'>
					and lat_long.verified_by_agent_id is not null
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'ce_date_determiner'>
					and collecting_event.date_determined_by_agent_id is not null
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'entered_by'>
					and coll_object.entered_person_id is not null
				</cfif>
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["id"] = "#search.agent_id#">
			<cfset row["value"] = "#search.preferred_agent_name#" >
			<cfif show_agent_id >
				<cfset agent_id_bit = " [#search.agent_id#]">
			<cfelse>
				<cfset agent_id_bit = "">
			</cfif>
			<cfif search.preferred_agent_name EQ search.agent_name >
				<cfset row["meta"] = "#search.agent_name# #edited_marker##agent_id_bit#" >
			<cfelse>
				<cfset row["meta"] = "#search.agent_name# (#search.preferred_agent_name#)#edited_marker##agent_id_bit#" >
			</cfif>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getAgentList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getAuthorAutocompleteMeta.  Search for agents by name with a substring match on any name, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just the agent name as the selected value along with additional structured 
 information on first author and second author forms of the agent name suitable for selecting authors for a publication to populate publication_author

@param term agent name to search for.
@param show_agent_id if no value provided, then do not include the agent_id in the meta, otherwise included the agent_id in the meta.
@return a json structure containing id and value, with matching agents with matched name in value and agent_id in id, and matched name 
  with * and preferred name in meta.
--->
<cffunction name="getAuthorAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="show_agent_id" type="string" required="no">
	<!--- perform wildcard search anywhere in agent_name.agent_name --->
	<cfset name = "%#term#%"> 

	<cfif not isDefined("show_agent_id") OR len(show_agent_id) EQ 0 >
		<cfset show_agent_id = false>
	<cfelse>
		<cfset show_agent_id = true>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT distinct
				searchname.agent_id, searchname.agent_name,
				agent.agent_type, agent.edited,
				prefername.agent_name as preferred_agent_name,
				firstauthor.agent_name as firstauthor_name, firstauthor.agent_name_id as firstauthor_agent_name_id,
				secondauthor.agent_name as secondauthor_name, secondauthor.agent_name_id as secondauthor_agent_name_id
			FROM 
				agent_name searchname
				left join agent on searchname.agent_id = agent.agent_id
				left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
				left join agent_name firstauthor on agent.agent_id = firstauthor.agent_id and firstauthor.agent_name_type = 'author'
				left join agent_name secondauthor on agent.agent_id = secondauthor.agent_id and secondauthor.agent_name_type = 'second author'
			WHERE
				upper(searchname.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["id"] = "#search.agent_id#">
			<cfset row["value"] = "#search.preferred_agent_name#" >
			<cfif show_agent_id >
				<cfset agent_id_bit = " [#search.agent_id#]">
			<cfelse>
				<cfset agent_id_bit = "">
			</cfif>
			<cfif search.preferred_agent_name EQ search.agent_name >
				<cfset row["meta"] = "#search.agent_name# #edited_marker##agent_id_bit# 1st:#search.firstauthor_name# 2nd:#search.secondauthor_name#" >
			<cfelse>
				<cfset row["meta"] = "#search.agent_name# (#search.preferred_agent_name#)#edited_marker##agent_id_bit# 1st:#search.firstauthor_name# 2nd:#search.secondauthor_name#" >
			</cfif>
			<cfset row["firstauthor_name"] = "#search.firstauthor_name#" >
			<cfset row["firstauthor_agent_name_id"] = "#search.firstauthor_agent_name_id#" >
			<cfset row["secondauthor_name"] = "#search.secondauthor_name#" >
			<cfset row["secondauthor_agent_name_id"] = "#search.secondauthor_agent_name_id#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getAgentList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getAgentNameOfType obtain an agent name of a specified type given an agent_id, used to find
  first or second author form of the agent name given an agent_id, if a name of that form exists.

@param agent_id the agent for which to look up author forms of the agent name.
@param agent_name_type the type of agent name to return (e.g. 'author', 'second author')
@return a structure containing agent_name and agent_name_id for the matched name, empty if no 
 agent names of the specified type are found, will return only one match, even if multiple forms
 of the same type exist for the specified agent. Returns an http 500 status in the case of an error.
--->
<cffunction name="getAgentNameOfType" access="remote" returntype="any" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="agent_name_type" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset i = 1>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.short_timeout#">
			select agent_name, agent_name_id
				from agent_name 
			where
				agent_name_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_name_type#">
				and agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
				and rownum < 2
		</cfquery>
		<cfset row = StructNew()>
		<cfif search.recordcount GT 0>
			<cfset row["agent_name"] = "#search.agent_name#" >
			<cfset row["agent_name_id"] = "#search.agent_name_id#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>

	<cfreturn #serializeJSON(data)#>
</cffunction>
</cfcomponent>
