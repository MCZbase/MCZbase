<cfset pageTitle = "Named Group">
<cfinclude template = "/shared/_header.cfm">
			<cfquery name="getNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select 
					collection_name 
				from 
					underscore_collection, underscore_relation, cataloged_item 
				where 
					underscore_relation.UNDERSCORE_collection_ID = underscore_collection.UNDERSCORE_COLLECTION_ID
				and 
					underscore_relation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			</cfquery>
<main class="container py-3">
	<h1>#collection_name#</h1>


</main><!--- class="container" --->
<cfinclude template = "/shared/_footer.cfm">
