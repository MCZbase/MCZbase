<!--- Parameters this page reads from the request, declared explicitly rather than resolved
	implicitly across the url and form scopes, which is deprecated. --->
<cfparam name="url.q" default="">
<cfparam name="form.q" default="">
<cfset variables.q = url.q>
<cfif len(form.q) GT 0>
	<cfset variables.q = form.q>
</cfif>
<cfoutput>
	<!--- The portal specific code table is named by the portal, which cannot be bound: an
		identifier is not a parameter.  It comes from the session rather than the request, and is
		checked numeric here so nothing but a number can reach the statement. --->
	<cfif isdefined("session.portal_id") and isnumeric(session.portal_id) and session.portal_id gt 0>
		<cftry>
			<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select a.part_name
				from (
				        select part_name, partname
				        from cctspecimen_part_name#session.portal_id#, ctspecimen_part_list_order
				        where cctspecimen_part_name#session.portal_id#.part_name =  ctspecimen_part_list_order.partname (+)
				        and upper(part_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.q)#%">
				) a
				group by a.part_name, a.partname
				order by a.partname asc, a.part_name
			</cfquery>
			<cfcatch>
				<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
					select a.part_name
					from (
					        select part_name, partname
					        from ctspecimen_part_name, ctspecimen_part_list_order
					        where ctspecimen_part_name.part_name =  ctspecimen_part_list_order.partname (+)
					        and upper(part_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.q)#%">
					) a
					group by a.part_name, a.partname
					order by a.partname asc, a.part_name
				</cfquery>
			</cfcatch>
		</cftry>
	<cfelse>
		<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select a.part_name
			from (
			        select part_name, partname
			        from ctspecimen_part_name, ctspecimen_part_list_order
			        where ctspecimen_part_name.part_name =  ctspecimen_part_list_order.partname (+)
			        and upper(part_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.q)#%">
			) a
			group by a.part_name, a.partname
			order by a.partname asc, a.part_name
		</cfquery>
	</cfif>
	<cfloop query="pn">
		#part_name# #chr(10)#
	</cfloop>
</cfoutput>
