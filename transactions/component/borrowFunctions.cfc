<!---
transactions/component/borrowFunctions.cfm
 
Copyright 2021 President and Fellows of Harvard College

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
<!--- Special purpose ffunctions and backing methods pertaining to borrows --->
<cfcomponent>
<cf_rolecheck>

<!--- Return the borrow items for a transaction as structured data --->
<cffunction name="getBorrowItems" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	
	<cftry>
	<cfquery name="getBorrowItemsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getBorrowItemsQuery_result">
			select 
				transaction_id, borrow_item_id, 
				catalog_number, sci_name, no_of_spec, 
				spec_prep, type_status, country_of_origin, object_remarks
			from borrow_item 
			where 
				transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfreturn getBorrowItemsQuery>
	<cfcatch>
	</cfcatch>
	</cftry>
</cffunction>

<!--- add an item to a borrow --->
<cffunction name="addBorrowItem" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="catalog_number" required="no">
	<cfargument name="sci_name" required="no">
	<cfargument name="no_of_spec" required="no">
	<cfargument name="spec_prep" required="no">
	<cfargument name="type_status" required="no">
	<cfargument name="country_of_origin" required="no">
	<cfargument name="object_remarks" required="no">

	<cftry>
		<cfquery name="newBorrow_Item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newBorrow_ItemRes">
		INSERT INTO BORROW_ITEM 
		(
			TRANSACTION_ID,
			CATALOG_NUMBER,
			SCI_NAME,
			NO_OF_SPEC,
			SPEC_PREP,
			TYPE_STATUS,
			COUNTRY_OF_ORIGIN,
			OBJECT_REMARKS
		) VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CATALOG_NUMBER#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SCI_NAME#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NO_OF_SPEC#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SPEC_PREP#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TYPE_STATUS#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COUNTRY_OF_ORIGIN#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OBJECT_REMARKS#">
		)
		</cfquery>
		<cfif newBorrow_ItemRes.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record not added. #transaction_id# #newBorrow_ItemRes.sql#", 1)>
		</cfif>
		<cfif newBorrow_ItemRes.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Borrow_Item added to Borrow.", 1)>
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

<!--- Remove an item from a borrow by deleting the borrow_item record. 
 @param borrow_item_id the borrow item to be deleted.
--->
<cffunction name="deleteBorrowItem" access="remote">
	<cfargument name="borrow_item_id" type="numeric" required="yes">
	<cftry>
		<cfquery name="newBorrow_Item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newBorrow_ItemRes">
			DELETE from BORROW_ITEM 
			where
				borrow_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#borrow_item_id#">
		</cfquery>
		<cfif newBorrow_ItemRes.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record not deleted. #borrow_item_id# #newBorrow_ItemRes.sql#", 1)>
		</cfif>
		<cfif newBorrow_ItemRes.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "borrow_item deleted.", 1)>
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

<!--- TODO: Refactor to use grid ---> 
<cffunction name="getBorrowItemsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfquery name="borrowItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="borrowItems_result">
		select transaction_id,borrow_item_id,catalog_number,sci_name,
				no_of_spec,spec_prep,type_status,country_of_origin,object_remarks 
		from borrow_item 
		where 
			transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
	</cfquery>

	<cfset resulthtml = "<table style='width:1100px;'>">
	<cfset resulthtml = resulthtml & "<h3>Borrowed Items</h3>">
	<cfset resulthtml = resulthtml & "<tr><td><label>Catalog Number</label></td><td><label>Scientific Name</label></td>">
	<cfset resulthtml = resulthtml & "<td><label>No. of Specimens</label></td>">
	<cfset resulthtml = resulthtml & "<td><label>Specimen Preparation</label></td>">
	<cfset resulthtml = resulthtml & "<td><label>Type Status</label></td>">
	<cfset resulthtml = resulthtml & "<td><label>Country of Origin</label></td>">
	<cfset resulthtml = resulthtml & "<td><label>Remarks</label></td>">
	<cfset resulthtml = resulthtml & "</td></tr>">

	<cfloop query="borrowItems">
		<cfset resulthtml = resulthtml & "<tr><td>#catalog_number#</td><td>#sci_name#</td><td>#no_of_spec#</td><td>#spec_prep#</td>">
		<cfset resulthtml = resulthtml & "<td>#type_status#</td>">
		<cfset resulthtml = resulthtml & "<td>#country_of_origin#</td>">
		<cfset resulthtml = resulthtml & "<td>#object_remarks#</td>">
		<cfset resulthtml = resulthtml & "<td><input name='deleteBorrowItem' type='button' value='Delete' onclick='deleteBorrowItem(#borrow_item_id#);'>">
		<cfset resulthtml = resulthtml & "</td></tr>">
	</cfloop>
	<cfset resulthtml = resulthtml & "</table>">

	<cfreturn resulthtml>
</cffunction>

</cfcomponent>
