<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">
<cfset collection_object_id = "5243961">
<cfquery name="named_group" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select underscore_collection.collection_name, underscore_relation.collection_object_id
from underscore_collection, underscore_relation 
where underscore_relation.UNDERSCORE_collection_ID = underscore_collection.UNDERSCORE_COLLECTION_ID
and underscore_relation.collection_object_id = 5243961
</cfquery>
<cfoutput>
<main class="container py-3">

	<h1>#collection_object_id# #collection_name#</h1>
</main><!--- class="container" --->
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
