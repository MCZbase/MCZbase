<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">
<cfset collection_object_id = "5243961">
	<cfoutput>
<cfquery name="namedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select underscore_collection.collection_name, underscore_relation.collection_object_id
from underscore_collection, underscore_relation 
where underscore_relation.UNDERSCORE_collection_ID = underscore_collection.UNDERSCORE_COLLECTION_ID
and underscore_relation.collection_object_id = 5243961
</cfquery>

<main class="container py-3">

	
	<div class="row">
	 	<div class="col-12">
			<h1>#namedGroup.collection_name#</h1>
			<div class="col-5 border float-left">Media</div>
			<div class="col-7 border float-left">Description</div>
		</div>
	</div>
</main><!--- class="container" --->
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
