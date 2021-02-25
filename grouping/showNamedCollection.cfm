<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">
<cfset collection_object_id = "5243961">
<cfif isdefined("collection_object_id")>
<cfquery name="named_group">
select collection_name 
from underscore_collection, underscore_relation 
where underscore_relation.UNDERSCORE_collection_ID = underscore_collection.UNDERSCORE_COLLECTION_ID
and underscore_relation.collection_object_id = 5243961
	</cfquery>
</cfif>

 
<main class="container py-3">
	<h1>#collection_object_id#</h1>


</main><!--- class="container" --->
<cfinclude template = "/shared/_footer.cfm">
