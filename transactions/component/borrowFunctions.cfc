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
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- Return the borrow items for a transaction as structured data --->
<cffunction name="getBorrowItems" access="remote" returntype="any" returnformat="json">
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
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
</cffunction>

<!--- add an item to a borrow 
 @param transaction_id the borrow transaction to add the borrow item to
 @param catalog_number the catalog number for the borrow item
 @param sci_name the scientific name for the borrow item
 @param no_of_sepc the number of specimens for the borrow item
 @param spec_prep the preparations for the borrow item
 @param type_status the type status for the borrow item
 @param country_of_origin the country of origin for the borrow item
 @param object_remarks the remarks for the borrow item
--->
<cffunction name="addBorrowItem" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="catalog_number" required="yes">
	<cfargument name="sci_name" required="yes">
	<cfargument name="no_of_spec" required="yes">
	<cfargument name="spec_prep" required="yes">
	<cfargument name="type_status" required="yes">
	<cfargument name="country_of_origin" required="yes">
	<cfargument name="object_remarks" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="newBorrow_Item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newBorrow_Item_result">
				INSERT INTO BORROW_ITEM (
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
			<cfif newBorrow_Item_result.recordcount NEQ 1>
				<cfthrow message="Record not added. #transaction_id# #newBorrow_Item_result.sql#">
			</cfif>
			<cfif newBorrow_Item_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Borrow_Item added to Borrow.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>
<!--- Update a borrow_item record. 
 @param borrow_item_id the borrow item to be updated.
--->
<cffunction name="updateBorrowItem" access="remote" returntype="any" returnformat="json">
	<cfargument name="borrow_item_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="catalog_number" required="yes">
	<cfargument name="sci_name" required="yes">
	<cfargument name="no_of_spec" required="yes">
	<cfargument name="spec_prep" required="yes">
	<cfargument name="type_status" required="yes">
	<cfargument name="country_of_origin" required="yes">
	<cfargument name="object_remarks" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="updateBorrow_Item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateBorrow_Item_result">
				UPDATE BORROW_ITEM 
				SET
					catalog_number =<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CATALOG_NUMBER#">,
					sci_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SCI_NAME#">,
					no_of_spec = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NO_OF_SPEC#">,
					spec_prep = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SPEC_PREP#">,
					type_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TYPE_STATUS#">,
					country_of_origin = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COUNTRY_OF_ORIGIN#">,
					object_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OBJECT_REMARKS#">
				where
					borrow_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#borrow_item_id#">
					and transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif updateBorrow_Item_result.recordcount NEQ 1>
				<cfthrow message="Record not updated. #borrow_item_id# #updateBorrow_Item_result.sql#">
			</cfif>
			<cfif updateBorrow_Item_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "borrow_item updated.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>

	<cfreturn theResult>
</cffunction>

<!--- Remove an item from a borrow by deleting the borrow_item record. 
 @param borrow_item_id the borrow item to be deleted.
--->
<cffunction name="deleteBorrowItem" access="remote" returntype="any" returnformat="json">
	<cfargument name="borrow_item_id" type="numeric" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="delBorrow_Item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delBorrow_Item_result">
				DELETE from BORROW_ITEM 
				where
					borrow_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#borrow_item_id#">
			</cfquery>
			<cfif delBorrow_Item_result.recordcount NEQ 1>
				<cfthrow message = "Record not deleted. #borrow_item_id# #delBorrow_Item_result.sql#">
			</cfif>
			<cfif delBorrow_Item_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "borrow_item deleted.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>

	<cfreturn theResult>
</cffunction>

<!--- deprecated, now uses editable grid with data load from getBorrowItemsData ---> 
<cffunction name="getBorrowItemsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfquery name="borrowItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="borrowItems_result">
		select transaction_id,borrow_item_id,catalog_number,sci_name,
				no_of_spec,spec_prep,type_status,country_of_origin,object_remarks 
		from borrow_item 
		where 
			transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
	</cfquery>

	<cfset resulthtml = "<table class='w-100'>">
	<cfset resulthtml = resulthtml & "<h3>Borrowed Items</h3>">
	<cfset resulthtml = resulthtml & "<tr><td><label>Catalog Number</label></td><td><label>Scientific Name</label></td>">
	<cfset resulthtml = resulthtml & "<td><label>No. of Specimens</label></td>">
	<cfset resulthtml = resulthtml & "<td><label>Specimen Preparation</label></td>">
	<cfset resulthtml = resulthtml & "<td><label>Type Status</label></td>">
	<cfset resulthtml = resulthtml & "<td><label>Country of Origin</label></td>">
	<cfset resulthtml = resulthtml & "<td><label>Remarks</label></td>">
	<cfset resulthtml = resulthtml & "</td>Action</tr>">

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

<!--- Return the borrow items for a transaction as json to populate a jqx grid 
 @param transaction_id idenitifying the borrow for which to return the borrow items.
--->
<cffunction name="getBorrowItemsData" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="numeric" required="yes">
	
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="getBorrowItemsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getBorrowItemsQuery_result">
			select 
				transaction_id, borrow_item_id, 
				catalog_number, sci_name, 
				no_of_spec, spec_prep, 
				type_status, country_of_origin, 
				object_remarks
			from borrow_item 
			where 
				transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfset rows = getBorrowItemsQuery_result.recordcount>
		<cfset i = 1>
		<cfloop query="getBorrowItemsQuery">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(getBorrowItemsQuery.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#getBorrowItemsQuery[col][currentRow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
</cffunction>

</cfcomponent>
