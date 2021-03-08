<cfcomponent>
<cf_rolecheck>
<cfinclude template = "/shared/functionLib.cfm">

<cffunction name="getExternalStatus" access="remote">
	<cfargument name="uri" type="string" required="yes">
	<cfhttp url="#uri#" method="head"></cfhttp>
	<cfreturn left(cfhttp.statuscode,3)>
</cffunction>

<!--- updateCondition update the condition on a part identified by the part's collection object id 
 @param part_id the collection_object_id for the part to update
 @param condition the new condition to update the part to 
 @return a json structure containing the part_id and a message, with "success" as the value of the message on a successful update.
--->
<cffunction name="updateCondition" access="remote" returntype="query">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update coll_object 
				set
					condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#condition#">
				where
					COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!------EXISTING----------------------------------------------------------------------------------------------------------->
<cffunction name="getIdentifications" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 1 as status, identification_id, collection_object_id, nature_of_id, accepted_id_fg,
				identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
			from identification
			where identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No identifications found.", 1)>
		</cfif>
	<cfcatch>
		<cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getIdentificationTable" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
	    <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
   			select 1 as status, identifications_id, collection_object_id, made_date, nature_of_id, accepted_id_fg,identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
            from identification
            where identification_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
	  	  <cfset theResult=queryNew("status, message")>
		  <cfset t = queryaddrow(theResult,1)>
		  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
	<cfcatch>
	  <cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
    <cfif isDefined("asTable") AND asTable eq "true">
	    <cfreturn resulthtml>
    <cfelse>
   	    <cfreturn theResult>
    </cfif>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getPartName" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

   <cftry>
      <cfset rows = 0>
      <cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select a.part_name
			from (
				select part_name, partname
				from ctspecimen_part_name, ctspecimen_part_list_order
				where ctspecimen_part_name.part_name =  ctspecimen_part_list_order.partname (+)
					and upper(part_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
				) a
			group by a.part_name, a.partname
			order by a.partname asc, a.part_name
      </cfquery>
   <cfset rows = search_result.recordcount>
      <cfset i = 1>
      <cfloop query="search">
         <cfset row = StructNew()>
         <cfset row["id"] = "#search.part_name#">
         <cfset row["value"] = "#search.part_name#" >
         <cfset data[i]  = row>
         <cfset i = i + 1>
      </cfloop>
      <cfreturn #serializeJSON(data)#>
   <cfcatch>
      <cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
      <cfset message = trim("Error processing getAgentPartName: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
      <cfheader statusCode="500" statusText="#message#">
         <cfoutput>
            <div class="container">
               <div class="row">
                  <div class="alert alert-danger" role="alert">
                     <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
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
<!----------------------------------------------------------------------------------------------------------------->
</cfcomponent>
