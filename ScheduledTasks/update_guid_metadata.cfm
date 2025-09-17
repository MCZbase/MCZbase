<cfquery  name="getGuids" datasource="cf_dbuser">
	SELECT assembled_resolvable 
	FROM guid_our_thing 
	WHERE metadata IS NULL
		AND resolver_prefix = 'https://mczbase.mcz.harvard.edu/uuid/'
		AND disposition = 'exists'
</cfquery>
<cfloop query="getGuids">
	<cfhttp url="#getGuids.assembled_resolvable#/json" method="get" result="httpResponse" timeout="10">
	<cfif httpResponse.statusCode EQ "200">
		<cfset jsonData = deserializeJson(httpResponse.fileContent)>
		<cfquery datasource="uam_god">
			UPDATE guid_our_thing
			SET metadata = <cfqueryparam value="#serializeJson(jsonData)#" cfsqltype="cf_sql_longvarchar">
			WHERE assembled_resolvable = <cfqueryparam value="#getGuids.assembled_resolvable#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfoutput>Updated metadata for GUID: #getGuids.assembled_resolvable#<br></cfoutput>
	<cfelse>
		<cfoutput>No metadata found for GUID: #getGuids.assembled_resolvable#<br></cfoutput>
	</cfif>
</cfloop>
