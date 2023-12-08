<!--- 
  Reports/loan.cfm proof of concept loan paperwork generation.

Copyright 2023 President and Fellows of Harvard College

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

<cfif not isDefined("transaction_id") OR len(transaction_id) EQ 0>
	<cfthrow message = "No transaction_id provided for loan to print.">
</cfif>
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="entryPoint">
</cfif>

<cfquery name="getLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT loan_number, collection, collection_id 
	FROM trans 
		JOIN loan on trans.transaction_id = loan.transaction_id
		JOIN collection on trans.collection_id = collection.collection_id
	WHERE
		transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
</cfquery>
<cfquery name="getLoanItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT guid, part_name
	FROM trans_item
		JOIN specimen_part on trans_item.collection_object_id
		JOIN flat on specimen_part.derived_from_cat_item = flat.collection_object_id
	WHERE
		transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
</cfquery>

<!--------------------------------------------------------------------------------->
<cfdocument format="pdf">
	<cfoutput>

		<cfdocumentitem type="header">
			Museum of Comparative Zoology Loan #getLoan.loan_number#
		</cfdocumentitem>
		
		<cfdocumentitem type="header">
			#dateFormat(now(),'yyyy-mm-dd')#
		</cfdocumentitem>

		<cfdocumentsection name="Loan Header">
			<h1>Loan of #collection# Specimens</h1>
		</cfdocumentsection>

		<cfdocumentsection name="Loan Conditions">
			<h1>Conditions of Use</h1>
		</cfdocumentsection>

		<cfdocumentsection name="Items In Loan">
			<h1>Items in Loan</h1>
			<cfloop query="getLoanItems">
				#guid# #part_name#
			</cfloop>
		</cfdocumentsection>

	</cfoutput>
</cfdocument>
