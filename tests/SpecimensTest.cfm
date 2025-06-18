<cfset pageTitle = "Search Specimen | Basic">
<cfinclude template = "/shared/_header.cfm">
	
<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfquery name="ctCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
	SELECT
		collection_cde,
		collection,
		collection_id
	FROM
		collection
	ORDER BY collection.collection
</cfquery>
<cfquery name="ctother_id_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT count(*) ct, other_id_type 
	FROM coll_obj_other_id_num co
	GROUP BY other_id_type 
	ORDER BY other_id_type
</cfquery>
<cfquery name="ctnature_of_id" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,60,0)#">
	SELECT nature_of_id, count(*) as ct 
	FROM IDENTIFICATION
	GROUP BY nature_of_id
 	ORDER BY nature_of_id
</cfquery>

<cfquery name="column_headers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select column_name, data_type from all_tab_columns where table_name = 'FLAT' and rownum = 1
</cfquery>

<!--- ensure that pass through parameters for linking to a search are defined --->
<cfif NOT isdefined("url.searchText")>
	<cfset searchText = "">
<cfelse>
	<cfset searchText = url.searchText>
</cfif>
	
<cfif not isdefined("collection_cde") AND isdefined("collection_id") AND len(collection_id) GT 0 >
	<!--- if collection id was provided, but not a collection code, lookup the collection code --->
	<cfquery name="lookupCollection_cde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="lookupCollection_cde_result" timeout="#Application.short_timeout#">
		SELECT
			collection_cde code
		FROM
			collection
		WHERE
			collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
	</cfquery>
	<cfloop query="lookupCollection_cde">
		<cfset collection_cde = lookupCollection_cde.code>
		<cfset collection = lookupCollection_cde.code>
	</cfloop>
</cfif>
<cfif not isdefined("underscore_collection") AND isdefined("underscore_collection_id") AND len(underscore_collection_id) GT 0 >
	<!--- if underscore collection id was provided, but not a collection name, lookup the collection name --->
	<cfquery name="lookupNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="lookupNamedGroup_result" timeout="#Application.short_timeout#">
		SELECT
			collection_name
		FROM
			underscore_collection
		WHERE
			underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
	</cfquery>
	<cfloop query="lookupNamedGroup">
		<cfset underscore_collection = lookupNamedGroup.collection_name>
	</cfloop>
</cfif>
		
<cfoutput>
<style>
/*fas is for the arrow up and down (more and less on form sections*/
.fas {
	font-size: 16px;
}
/*for the */
@media screen and (max-width: 678px) {
       .animation-element {
               width: 100%;
               margin: 0px 0px 30px 0px;
       }
}
/* below is for the basic search width of form fields area inside teal box */
@media screen and (min-width: 1200px) {
.col-xxl-1 {max-width: 7.666667%}
.col-xxl-11 {max-width: 90.333333%}
}
</style>	
		
</cfoutput>
  <div id="fixedsearchResultsGrid"></div>
  <script>
    var data = [
      { name: 'Alice', action: '<a href="#">Link</a>' },
      { name: 'Bob',   action: '<a href="#">Link</a>' }
    ];
    var source = {
      datatype: "array",
      localdata: data,
      datafields: [
        { name: 'name', type: 'string'},
        { name: 'action', type: 'string'}
      ]
    };
    var dataAdapter = new $.jqx.dataAdapter(source);

    $('#fixedsearchResultsGrid').jqxGrid({
      width: 400,
      autoheight: true,
      source: dataAdapter,
      columns: [
        { text: 'Name', datafield: 'name', width: 150 },
        { text: 'Action', datafield: 'action', width: 150, cellsrenderer: function(row, columnfield, value) { return value; } }
      ],
      selectionmode: 'singlecell',
      keyboardnavigation: true
    });

    // Ensure tabindex for focusing
    $('#fixedsearchResultsGrid').attr('tabindex', 0);

    $('#fixedsearchResultsGrid').on('bindingcomplete', function() {
      setTimeout(function() {
        var columns = $('#fixedsearchResultsGrid').jqxGrid('columns').records;
        if (columns.length) {
          $('#fixedsearchResultsGrid').jqxGrid('selectcell', 0, columns[0].datafield);
          $('#fixedsearchResultsGrid').focus();
        }
      }, 100);
    });
  </script>
  <p>Tab into the grid with your keyboard, and use arrow keys.</p>
</body>
</html>