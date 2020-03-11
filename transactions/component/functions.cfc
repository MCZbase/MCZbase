<!---
specimens/component/functions.cfc

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

<cffunction name="checkAgentFlag" access="remote">
   <cfargument name="agent_id" type="numeric" required="yes">
   <cfquery name="checkAgentQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
      select MCZBASE.get_worstagentrank(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">) as agentrank from dual
   </cfquery>
   <cfreturn checkAgentQuery>
</cffunction>

<!-------------------------------------------->
<!--- obtain counts of loan items --->
<cffunction name="getLoanItemCounts" access="remote">
        <cfargument name="transaction_id" type="string" required="yes">
        <cfif listcontainsnocase(session.roles,"admin_transactions")>
                <cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select
		1 as status,
                count(distinct cataloged_item.collection_object_id) catItemCount,
                count(distinct collection.collection_cde) as collectionCount,
                count(distinct preserve_method) as preserveCount,
                count(distinct specimen_part.collection_object_id) as partCount
        from
                loan_item,
                loan,
                specimen_part,
                coll_object,
                cataloged_item,
                coll_object_encumbrance,
                encumbrance,
                agent_name,
                identification,
                collection
        WHERE
                loan_item.collection_object_id = specimen_part.collection_object_id AND
                loan.transaction_id = loan_item.transaction_id AND
                specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
                specimen_part.collection_object_id = coll_object.collection_object_id AND
                coll_object.collection_object_id = coll_object_encumbrance.collection_object_id (+) and
                coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND
                encumbrance.encumbering_agent_id = agent_name.agent_id (+) AND
                cataloged_item.collection_object_id = identification.collection_object_id AND
                identification.accepted_id_fg = 1 AND
                cataloged_item.collection_id=collection.collection_id AND
                loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
                </cfquery>
        <cfelse>
                <cfset rankCount=queryNew("status, message")>
                <cfset t = queryaddrow(rankCount,1)>
                <cfset t = QuerySetCell(rankCount, "status", "-1", 1)>
                <cfset t = QuerySetCell(rankCount, "message", "Not Authorized", 1)>
        </cfif>
        <cfreturn rankCount>
</cffunction>

</cfcomponent>
