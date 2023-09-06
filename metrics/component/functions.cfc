<cffunction name="getMetrics"  access="remote" returntype="string" returnformat="plain">
	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getMetrics#tn#" threadName="getMetrics#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="getStats" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select f.COLLECTION, ts.CATEGORY as "CITATION_TYPE",ts.type_status, count(distinct f.collection_object_id) as "NUMBER_CATALOG_ITEMS", count(distinct media_id) as "NUMBER_OF_IMAGES", 
					count(distinct mr.related_primary_key) as "NUMBER_OF_TYPES_WITH_IMAGES", to_char(co.coll_object_entered_date,'YYYY') as "ENTERED_DATE"
					from flat f, citation c, ctcitation_type_status ts, coll_object co,
					(select * from media_relations where media_relationship = 'shows cataloged_item') mr
					where f.collection_object_id=c.collection_object_id
					and c.type_status=ts.type_status
					and mr.related_primary_key(+) = f.collection_object_id
					and f.collection_object_id = co.collection_object_id
					and ts.category != 'Temp'
					group by f.collection, ts.type_status, co.coll_object_entered_date, ts.category
				</cfquery>
				<cfif getStats.recordcount EQ 0>
					<cfthrow message="No Metrics">
				</cfif>
				<!--- The queries to specific relationships below provide the variables for displaying the links within the id=relatedLinks div --->
				
			<cfoutput>
 				<cfset csv = queryToCSV(getStats)> 
				<cffile action="write" file="#application.webDirectory#/metrics/datafiles/chart_data.csv" output = "#csv#" addnewline="No">
			</cfoutput>
				
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getMetrics#tn#" />
	<cfreturn cfthread["getMetrics#tn#"].output>
</cffunction>