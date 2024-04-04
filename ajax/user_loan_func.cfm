<!--- hint="type=keyvalue, jsreturn=array , listdelimiter=| , delimiter='='" --->
<cfinclude template="/ajax/core/cfajax.cfm">
<!------------------------------------->
<cffunction name="changeStatus" returntype="string">
	<cfargument name="partid" type="numeric" required="yes">
	<cfargument name="loanid" type="numeric" required="yes">
	<cfargument name="status" type="string" required="yes">
	
	<cfset result="success">
	<cftry>
	<cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		update cf_loan_item set
			APPROVAL_STATUS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#status#">
		where USER_LOAN_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loanid#">
			AND COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partid#">
	</cfquery>
	<cfcatch>
		<cfset result="fail">
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<!------------------------------------->
<cffunction name="changeRemark" returntype="string">
	<cfargument name="partid" type="numeric" required="yes">
	<cfargument name="loanid" type="numeric" required="yes">
	<cfargument name="remark" type="string" required="yes">
	
	<cfset result="success">
	<cftry>
	<cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		update cf_loan_item set
			ADMIN_REMARK = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remark#">
		where USER_LOAN_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loanid#">
			AND COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partid#">
	</cfquery>
	<cfcatch>
		<cfset result="fail">
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<!------------------------------------->
<cffunction name="getLoanDetails" returntype="query">
	<cfargument name="inst" type="string" required="no">
	<cfargument name="pre" type="string" required="no">
	<cfargument name="num" type="numeric" required="yes">
	<cfargument name="suf" type="string" required="no">
	<cftry>
		<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select 
				trans.transaction_id as transaction_id, 
				loan_type, 
				loan_instructions, 
				loan_description, 
				recAgnt.agent_name as rec_agent, 
				authAgnt.agent_name as auth_agent, 
				nature_of_material
			from 
				loan, 
				trans, 
				preferred_agent_name authAgnt, 
				preferred_agent_name recAgnt
			where 
				loan.transaction_id = trans.transaction_id AND 
				trans.auth_agent_id = authAgnt.agent_id (+) AND 
				trans.received_agent_id = recAgnt.agent_id AND 
				loan_num = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#num#">
				<cfif len(#inst#) gt 0>
					AND institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inst#">
				<cfelse>
					AND institution_acronym IS NULL
				</cfif>
				<cfif len(#pre#) gt 0>
					AND loan_num_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pre#">
				<cfelse>
					AND loan_num_prefix IS NULL
				</cfif>
				<cfif len(#suf#) gt 0>
					AND loan_num_suffix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#suf#">
				<cfelse>
					AND loan_num_suffix IS NULL
				</cfif>
		</cfquery>
		<cfif #result.recordcount# is 0>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select 
				0 as transaction_id
				from dual
			</cfquery>
		<cfelseif #result.recordcount# gt 1>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select 
				-99999 as transaction_id
				from dual
			</cfquery>
		</cfif>
		<cfcatch>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select 
				-1 as transaction_id
				from dual
			</cfquery>
		</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<!------------------------------------->


<cffunction name="getAccn" returntype="query">
	<cfargument name="inst" type="string" required="yes">
	<cfargument name="prefx" type="string" required="yes">
	
	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select 
			to_char(sysdate, 'YYYY') as accn_num_prefix,
			decode(max(accn_num),NULL,'1',max(accn_num) + 1) as nan
		from accn,trans
		where 
			accn.transaction_id=trans.transaction_id and
			institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inst#"> and
			accn_num_prefix = 
			<cfif len(#prefx#) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#prefx#">
			<cfelse>
				to_char(sysdate, 'YYYY')
			</cfif>
	</cfquery>
		<cfreturn result>
</cffunction>
<!-------------------------------------------------------------------->
<cffunction name="getLoan" returntype="query">
	<cfargument name="inst" type="string" required="yes">
	<cfset y = "#dateformat(now(), "yyyy")#">
	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select 
			to_char(sysdate, 'YYYY') as loan_num_prefix,
			decode(max(loan_num),NULL,'1',max(loan_num) + 1) as nln
		from 
			loan left join trans on loan.transaction_id = trans.transaction_id
		where 
			institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inst#"> and
			loan_num_prefix = to_char(sysdate, 'YYYY')
	</cfquery>
		<cfreturn result>
</cffunction>
<!-------------------------------------------------------------------->

<cffunction name="getContacts" returntype="string">
	<cfquery name="contacts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select 
			collection_contact_id,
			contact_role,
			contact_agent_id,
			agent_name contact_name
		from
			collection_contacts,
			preferred_agent_name
		where
			contact_agent_id = agent_id AND
			collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
		ORDER BY contact_name,contact_role
	</cfquery>
		
		<cfset result = 'success'>
		<cfreturn result>
</cffunction>
<!------------------------------------->
<cffunction name="getCollInstFromCollId" returntype="string">
	<cfargument name="collid" type="numeric" required="yes">
	<cftry>
		<cfquery name="getCollId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select collection_cde, institution_acronym 
			from collection 
			where collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collid#">
		</cfquery>
		<cfoutput>
		<cfset result = "#getCollId.institution_acronym#|#getCollId.collection_cde#">
		</cfoutput>
	<cfcatch>
		<cfset result = "QUERY FAILED">
	</cfcatch>
	</cftry>
  <cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
  <cfreturn result>
</cffunction>

<!------------------------------------->
<cffunction name="bulkEditUpdate" returntype="string">
	<cfargument name="theName" type="string" required="yes">
	<cfargument name="theValue" type="string" required="yes">

	<cfthrow message="method bulkEditUpdate has been removed.">

	<!--- parse name out
		format is field_name__collection_object_id --->

	<!--- commented out method body, theField would need to be hardened if this is used --->
	<!--- 
	<cfset hPos = find("__",theName)>
	<cfset theField = left(theName,hPos-1)>
	<cfset theCollObjId = mid(theName,hPos + 2,len(theName) - hPos)>
	<cfset result="#theName#">
	<cftry>
		<!--- cfquery name="upBulk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE bulkloader 
			SET <cfif 1=0>#theField#</cfif> = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#theValue#">
			WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#theCollObjId#">
		</cfquery --->
	<cfcatch>
		<cfset result = "QUERY FAILED">
	</cfcatch>
	</cftry>
  <cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
  <cfreturn result>
	--->
</cffunction>


<!------------------------------------->

<!------------------------------------->
<cffunction name="checkSessionExists" returntype="boolean">
	<cfif isDefined("session.name") AND session.name NEQ "">
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>
