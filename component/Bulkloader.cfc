<cfcomponent>
<!--- BULKLOADER.LOADED is VARCHAR2(255 CHAR). --->
<cfset LOADED_MAX_LEN = 255>
<!--- Every method here backs the bulkloader and the data entry screen, so the check is at
	component level: it runs on instantiation and therefore on any method, including a direct
	request for one.  The roles it demands come from cf_form_permissions keyed on this path, not
	from here. --->
<cf_rolecheck>

<cffunction name="splitGeog" access="remote">
        <cfargument name="geog" required="yes">
        <cfargument name="specloc" required="yes">
        <cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                select
                        country,
                        county,
                        state_prov
                from
                        geog_auth_rec
                where
                        higher_geog=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog#">
        </cfquery>
        <cfset guri="#Application.protocol#://www.geo-locate.org/web/WebGeoreflight.aspx?georef=run&locality=#specloc#">
        <cfif len(g.country) gt 0>
                <cfset guri=listappend(guri,"country=#g.country#","&")>
        </cfif>
        <cfif len(g.state_prov) gt 0>
                <cfset guri=listappend(guri,"state=#g.state_prov#","&")>
        </cfif>
        <cfif len(g.county) gt 0>
                <cfset cnty=replace(g.county," County","")>
                <cfset guri=listappend(guri,"county=#cnty#","&")>
        </cfif>
        <cfreturn guri>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="geolocate" access="remote">
        <cfargument name="geog" required="yes">
        <cfargument name="specloc" required="yes">
        <cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                select
                        country,
                        county,
                        state_prov
                from
                        geog_auth_rec
                where
                        higher_geog=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog#">
        </cfquery>
        <cfhttp method="post" url="#Application.protocol#://www.geo-locate.org/webservices/geolocatesvcv2/geolocatesvc.asmx/Georef2" timeout="5">
            <cfhttpparam name="Country" type="FormField" value="#g.country#">
            <cfhttpparam name="County" type="FormField" value="#g.county#">
            <cfhttpparam name="LocalityString" type="FormField" value="#specloc#">
            <cfhttpparam name="State" type="FormField" value="#g.state_prov#">
            <cfhttpparam name="HwyX" type="FormField" value="false">
            <cfhttpparam name="FindWaterbody" type="FormField" value="false">
            <cfhttpparam name="RestrictToLowestAdm" type="FormField" value="false">
            <cfhttpparam name="doUncert" type="FormField" value="true">
            <cfhttpparam name="doPoly" type="FormField" value="false">
            <cfhttpparam name="displacePoly" type="FormField" value="false">
            <cfhttpparam name="polyAsLinkID" type="FormField" value="false">
            <cfhttpparam name="LanguageKey" type="FormField" value="0">
        </cfhttp>
        <cfset glat=''>
        <cfset glon=''>
        <cfset gerr=''>
        <cfif cfhttp.statuscode is "200 OK">
                <cfset gl=xmlparse(cfhttp.fileContent)>
                <cfif gl.Georef_Result_Set.NumResults.xmltext is 1>
                        <cfset glat=gl.Georef_Result_Set.ResultSet.WGS84Coordinate.Latitude.XmlText>
                        <cfset glon=gl.Georef_Result_Set.ResultSet.WGS84Coordinate.Longitude.XmlText>
                        <cfset gerr=gl.Georef_Result_Set.ResultSet.UncertaintyRadiusMeters.XmlText>
                </cfif>
        </cfif>
        <cfset result = querynew("GLAT,GLON,GERR")>
        <cfset temp = queryaddrow(result,1)>
        <cfset temp = QuerySetCell(result, "GLAT", glat, 1)>
        <cfset temp = QuerySetCell(result, "GLON", glon, 1)>
        <cfset temp = QuerySetCell(result, "GERR", gerr, 1)>
        <cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->


<cffunction name="incrementCustomId" access="remote">
	<cfargument name="cidType" required="yes">
	<cfargument name="cidVal" required="yes">
	<cfset cVal="">
	<cfif isdefined("session.rememberLastOtherId") and session.rememberLastOtherId is 1>
		<cftry>
			<cfif isnumeric(cidVal)>
				<cfset cVal = cidVal + 1>
			<cfelseif isnumeric(right(cidVal,len(cidVal)-1))>
				<cfset temp = (right(cidVal,len(cidVal)-1)) + 1>
				<cfset cVal = left(cidVal,1) & temp>
			</cfif>
		<cfcatch>
			<cfmail to="arctos.database@gmail.com" subject="data entry catch" from="wtf@#Application.fromEmail#" type="html">
				from incrementCustomId-----
				cidVal: #cidVal#
				<br>
				<cfdump var=#cfcatch#>
			</cfmail>
		</cfcatch>
		</cftry>
	</cfif>
	<cfreturn cVal>
</cffunction>
<!----------------------------------------------------------------------------------------->

<cffunction name="loadRecord" access="remote">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from bulkloader where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
	</cfquery>
	<cfreturn d>
</cffunction>

<!----------------------------------------------------------------------------------------->

<cffunction name="deleteRecord" access="remote">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	<cftransaction>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from bulkloader where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
		</cfquery>
	</cftransaction>
	<cfquery name="next" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		<!--- oldValue is echoed back rather than bound: a bind in a select list has no column for
			this driver to resolve a type against.  The argument is declared numeric above, which
			is what makes interpolating it here safe. --->
		select #collection_object_id# oldValue, max(collection_object_id) nextValue from bulkloader
		where enteredby = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
    <!--- cfreturn next --->
    <!--- Using $.getJSON, we can't include a queryFormat = columns, but we can force the desired JSON serialization here --->
    <cfset out = SerializeJSON(next,true) >
    <cfoutput>#out#</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------->

<cffunction name="getPrefs" access="remote">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from cf_dataentry_settings where username=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfreturn d>
</cffunction>
<!----------------------------------------------------------------------------------------->
<!--- Function getBulkloaderColumns returns the column names of the bulkloader table, used to
	decide which caller supplied names may be used as column identifiers.  Read from the data
	dictionary rather than held as a list here so it cannot drift from the table.  uam_god is
	needed because sys.user_tab_cols shows the tables of the connected user and the account behind
	user_login does not own this one.

	Names that are not plain identifiers are left out: such a name could not be used as a column
	identifier or as a bind parameter name without quoting, so accepting it would mean assembling
	statement text around it.  There are none in this table today.

@return comma delimited list of column names of the bulkloader table.
--->
<cffunction name="getBulkloaderColumns" access="private" returntype="string">
	<cfset var getCols = "">
	<cfset var columns = "">
	<cfquery name="getCols" datasource="uam_god">
		SELECT column_name
		FROM sys.user_tab_cols
		WHERE table_name='BULKLOADER'
		ORDER BY internal_column_id
	</cfquery>
	<cfloop query="getCols">
		<cfif REFind("^[A-Za-z_][A-Za-z0-9_]*$",getCols.column_name) GT 0>
			<cfset columns = listappend(columns,getCols.column_name)>
		</cfif>
	</cfloop>
	<cfreturn columns>
</cffunction>
<!----------------------------------------------------------------------------------------->
<!--- Function parseFieldValues splits the query string the data entry screen sends into a struct
	of column name to value, discarding any name that is not a column of the bulkloader table.
	This replaces a loop that did <cfset "variables.#k#"=urldecode(v)>, which let a caller create
	a variable of any name it chose in the page scope of this component, including names the
	surrounding code then read back.

@param q query string of name=value pairs delimited by ampersands.
@param columns list of column names that may appear in q, from getBulkloaderColumns.
@return struct of column name to decoded value, holding only names present in columns.
--->
<cffunction name="parseFieldValues" access="private" returntype="struct">
	<cfargument name="q" type="string" required="yes">
	<cfargument name="columns" type="string" required="yes">
	<cfset var fields = structNew()>
	<cfset var kv = "">
	<cfset var separator = 0>
	<cfset var fieldName = "">
	<cfset var position = 0>
	<cfloop list="#arguments.q#" index="kv" delimiters="&">
		<cfset separator = find("=",kv)>
		<cfif separator GT 1>
			<cfset position = listfindnocase(arguments.columns,left(kv,separator-1))>
			<cfif position GT 0>
				<!--- keyed on the name as the data dictionary spells it, not as the caller sent it --->
				<cfset fieldName = listgetat(arguments.columns,position)>
				<cfset fields[fieldName] = urldecode(mid(kv,separator+1,len(kv)-separator))>
			</cfif>
		</cfif>
	</cfloop>
	<cfreturn fields>
</cffunction>
<!----------------------------------------------------------------------------------------->
<!--- Function saveEdits updates one staged bulkloader record from the data entry screen.

@param q query string of column=value pairs for the columns to set, which must include
	collection_object_id to identify the record.
@return serialized JSON of one row of collection_object_id and the result of bulk_check_one.
--->
<cffunction name="saveEdits" access="remote">
	<cfargument name="q" required="yes">
	<cfset var columns = getBulkloaderColumns()>
	<cfset var fields = parseFieldValues(q=arguments.q,columns=columns)>
	<cfset var sqlParams = structNew()>
	<cfset var setClauses = arrayNew(1)>
	<cfset var fieldName = "">
	<cfset var sqlString = "">
	<cfset var collection_object_id = "">
	<cfset var errorMessage = "">
	<cfset var result = "">
	<cfset var temp = "">
	<cfset var out = "">
	<cfif NOT structKeyExists(fields,"collection_object_id") OR NOT isNumeric(fields["collection_object_id"])>
		<cfthrow type="InvalidParameter" message="A numeric collection_object_id is required to save edits.">
	</cfif>
	<cfset collection_object_id = fields["collection_object_id"]>
	<!--- Iterated over the column list rather than the struct so the clauses come out in table
		order, and so each identifier written into the statement is a data dictionary value. --->
	<cfloop list="#columns#" index="fieldName">
		<cfif fieldName IS NOT "collection_object_id" AND structKeyExists(fields,fieldName)>
			<cfset arrayAppend(setClauses,"#fieldName# = :#fieldName#")>
			<cfset sqlParams[fieldName] = { value=fields[fieldName], cfsqltype="CF_SQL_VARCHAR" }>
		</cfif>
	</cfloop>
	<cftry>
		<cftransaction>
			<cfif arrayLen(setClauses) GT 0>
				<cfset sqlParams["collection_object_id"] = { value=collection_object_id, cfsqltype="CF_SQL_DECIMAL" }>
				<cfset sqlString = "UPDATE bulkloader SET " & arrayToList(setClauses,", ") & " WHERE collection_object_id = :collection_object_id">
				<cfset queryExecute(sqlString,sqlParams,{
					datasource = "user_login",
					username = session.dbuser,
					password = decrypt(session.epw,cookie.cfid)
				})>
			</cfif>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				<!--- Interpolated rather than bound, and safe because the value is checked numeric
					above: a bind in a select list, or inside a function's argument list, leaves
					this driver with no column to resolve the parameter's type against. --->
				SELECT #collection_object_id# collection_object_id,
					bulk_check_one(#collection_object_id#) rslt
				FROM dual
			</cfquery>
			<cfset errorMessage = result.rslt>
		</cftransaction>
	<cfcatch>
		<cfset result = querynew("collection_object_id,rslt")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "collection_object_id", collection_object_id, 1)>
		<cfset errorMessage = cfcatch.message & "; " & cfcatch.detail>
		<cfset temp = QuerySetCell(result, "rslt", errorMessage, 1)>
	</cfcatch>
	</cftry>
	<cfif len(errorMessage) EQ 0>
		<cfset errorMessage = "waiting approval">
	</cfif>
	<!--- Truncated to the width of the column.  An Oracle error message reaches here on the catch
		path and is routinely longer than that, which used to raise ORA-12899 from the statement
		below, which sits outside the try that would have handled it. --->
	<cfif len(errorMessage) GT LOADED_MAX_LEN>
		<cfset errorMessage = left(errorMessage,LOADED_MAX_LEN)>
	</cfif>
	<cfset queryExecute(
		"UPDATE bulkloader SET loaded = :loaded WHERE collection_object_id = :collection_object_id",
		{
			loaded = { value=errorMessage, cfsqltype="CF_SQL_VARCHAR" },
			collection_object_id = { value=collection_object_id, cfsqltype="CF_SQL_DECIMAL" }
		},
		{
			datasource = "user_login",
			username = session.dbuser,
			password = decrypt(session.epw,cookie.cfid)
		})>
	<cfset out = SerializeJSON(result,true)>
	<cfoutput>#out#</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------->

<!--- Function saveNewRecord inserts a new staged bulkloader record from the data entry screen.

@param q query string of column=value pairs for the columns to set.  Any collection_object_id in
	it is ignored: the new record takes its key from bulkloader_PKEY.
@return serialized JSON of one row of collection_object_id and the result of bulk_check_one.
--->
<cffunction name="saveNewRecord" access="remote">
	<cfargument name="q" required="yes">
	<cfset var columns = getBulkloaderColumns()>
	<cfset var fields = parseFieldValues(q=arguments.q,columns=columns)>
	<cfset var sqlParams = structNew()>
	<cfset var insertColumns = arrayNew(1)>
	<cfset var insertValues = arrayNew(1)>
	<cfset var fieldName = "">
	<cfset var sqlString = "">
	<cfset var result = "">
	<cfset var temp = "">
	<cfset var out = "">
	<cfloop list="#columns#" index="fieldName">
		<cfif fieldName IS NOT "collection_object_id" AND structKeyExists(fields,fieldName)>
			<cfset arrayAppend(insertColumns,fieldName)>
			<cfset arrayAppend(insertValues,":#fieldName#")>
			<cfset sqlParams[fieldName] = { value=fields[fieldName], cfsqltype="CF_SQL_VARCHAR" }>
		</cfif>
	</cfloop>
	<cftry>
		<cftransaction>
			<cfif arrayLen(insertColumns) GT 0>
				<cfset sqlString = "INSERT INTO bulkloader (collection_object_id," & arrayToList(insertColumns,",")
					& ") VALUES (bulkloader_PKEY.nextval," & arrayToList(insertValues,",") & ")">
			<cfelse>
				<cfset sqlString = "INSERT INTO bulkloader (collection_object_id) VALUES (bulkloader_PKEY.nextval)">
			</cfif>
			<cfset queryExecute(sqlString,sqlParams,{
				datasource = "user_login",
				username = session.dbuser,
				password = decrypt(session.epw,cookie.cfid)
			})>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT bulkloader_PKEY.currval collection_object_id,
					bulk_check_one(bulkloader_PKEY.currval) rslt
				FROM dual
			</cfquery>
		</cftransaction>
	<cfcatch>
		<cfset result = querynew("collection_object_id,rslt")>
		<cfset temp = queryaddrow(result,1)>
		<!--- Left empty rather than reporting an id: the insert that would have produced one is
			what failed.  This used to report collection_object_id, which on this path was whatever
			the caller happened to have set in page scope, or undefined. --->
		<cfset temp = QuerySetCell(result, "collection_object_id", "", 1)>
		<cfset temp = QuerySetCell(result, "rslt", cfcatch.message & "; " & cfcatch.detail, 1)>
	</cfcatch>
	</cftry>
	<cfset out = SerializeJSON(result,true)>
	<cfoutput>#out#</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------->
<!--- Function getPage returns a page of staged bulkloader records for the browse grid.

@param page grid page number.
@param pageSize rows per grid page.
@param gridsortcolumn column to sort on, ignored unless it is a column of bulkloader.
@param gridsortdirection asc or desc.
@param accn list of accession numbers to filter on.
@param enteredby list of usernames to filter on.
@param colln list of institution_acronym:collection_cde values to filter on.
@return query converted for a cfgrid.
--->
<cffunction name="getPage" access="remote">
	<cfargument name="page" required="yes">
	<cfargument name="pageSize" required="yes">
	<cfargument name="gridsortcolumn" required="yes">
	<cfargument name="gridsortdirection" required="yes">
	<cfargument name="accn" required="yes">
	<cfargument name="enteredby" required="yes">
	<cfargument name="colln" required="yes">
	<cfset var columns = getBulkloaderColumns()>
	<cfset var sqlParams = structNew()>
	<cfset var whereClauses = arrayNew(1)>
	<cfset var sortPosition = 0>
	<cfset var sortColumn = "collection_object_id">
	<cfset var sortDirection = "ASC">
	<cfset var sqlString = "">
	<cfset var data = "">
	<!--- A sort column and a sort direction are identifiers and a keyword, neither of which can be
		bound, so each is replaced by a value this code chose: the column as the data dictionary
		spells it, or the default. --->
	<cfset sortPosition = listfindnocase(columns,arguments.gridsortcolumn)>
	<cfif sortPosition GT 0>
		<cfset sortColumn = listgetat(columns,sortPosition)>
	</cfif>
	<cfif arguments.gridsortdirection IS "desc">
		<cfset sortDirection = "DESC">
	</cfif>
	<cfif len(arguments.accn) GT 0>
		<cfset arrayAppend(whereClauses,"accn IN (:accn)")>
		<cfset sqlParams["accn"] = { value=arguments.accn, cfsqltype="CF_SQL_VARCHAR", list=true }>
	</cfif>
	<cfif len(arguments.enteredby) GT 0>
		<cfset arrayAppend(whereClauses,"enteredby IN (:enteredby)")>
		<cfset sqlParams["enteredby"] = { value=arguments.enteredby, cfsqltype="CF_SQL_VARCHAR", list=true }>
	</cfif>
	<cfif len(arguments.colln) GT 0>
		<cfset arrayAppend(whereClauses,"institution_acronym || ':' || collection_cde IN (:colln)")>
		<cfset sqlParams["colln"] = { value=arguments.colln, cfsqltype="CF_SQL_VARCHAR", list=true }>
	</cfif>
	<cfset sqlString = "SELECT * FROM bulkloader">
	<cfif arrayLen(whereClauses) GT 0>
		<cfset sqlString = sqlString & " WHERE " & arrayToList(whereClauses," AND ")>
	</cfif>
	<cfset sqlString = sqlString & " ORDER BY " & sortColumn & " " & sortDirection>
	<cfset data = queryExecute(sqlString,sqlParams,{
		datasource = "user_login",
		username = session.dbuser,
		password = decrypt(session.epw,cookie.cfid)
	})>
	<cfreturn queryconvertforgrid(data,arguments.page,arguments.pageSize)>
</cffunction>
<!--------------------------------------->
<!--- Function editRecord saves one cell edited in place in the browse grid.

@param cfgridaction grid action, supplied by cfgrid.
@param cfgridrow the grid row, whose collection_object_id identifies the record.
@param cfgridchanged struct of the changed column to its new value.
--->
<cffunction name="editRecord" access="remote">
	<cfargument name="cfgridaction" required="yes">
	<cfargument name="cfgridrow" required="yes">
	<cfargument name="cfgridchanged" required="yes">
	<cfset var columns = getBulkloaderColumns()>
	<cfset var changedColumn = structKeyList(arguments.cfgridchanged)>
	<cfset var columnPosition = listfindnocase(columns,changedColumn)>
	<cfset var fieldName = "">
	<cfif columnPosition EQ 0>
		<!--- Also reached when more than one column arrives at once, which this cannot express. --->
		<cfthrow type="InvalidParameter" message="Not a single column of the bulkloader table.">
	</cfif>
	<cfif NOT isNumeric(arguments.cfgridrow.collection_object_id)>
		<cfthrow type="InvalidParameter" message="A numeric collection_object_id is required to edit a record.">
	</cfif>
	<cfset fieldName = listgetat(columns,columnPosition)>
	<cfset queryExecute(
		"UPDATE bulkloader SET #fieldName# = :newValue WHERE collection_object_id = :collection_object_id",
		{
			newValue = { value=arguments.cfgridchanged[changedColumn], cfsqltype="CF_SQL_VARCHAR" },
			collection_object_id = { value=arguments.cfgridrow.collection_object_id, cfsqltype="CF_SQL_DECIMAL" }
		},
		{
			datasource = "user_login",
			username = session.dbuser,
			password = decrypt(session.epw,cookie.cfid)
		})>
</cffunction>
</cfcomponent>
