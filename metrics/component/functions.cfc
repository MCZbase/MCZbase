<cfquery name="getStats">
select collection_object_id, lastuser, collection, lastdate, scientific_name, state_prov from cf_temp_chart_data
</cfquery>
 <cfset csv = queryToCSV(getStats)> 
	 
<cffile action="write" file="#application.webDirectory#/media/datafiles/chart_data.csv">

<!---<cfexecute rscript>--->
