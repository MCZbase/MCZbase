<cfcomponent>
<!--- Name of the custom bulkloader table. --->
<cfset datashotbl="MCZBASE.bulkloader_lepidoptera">
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
                        higher_geog='#geog#'
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
                        higher_geog='#geog#'
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
	<cfargument name="collection_object_id" required="yes">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from #datashotbl# where collection_object_id=#collection_object_id#
	</cfquery>
	<cfreturn d>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="deleteRecord" access="remote">
	<cfargument name="collection_object_id" required="yes">
	<cftransaction>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from #datashotbl# where collection_object_id=#collection_object_id#
		</cfquery>
	</cftransaction>
	<cfquery name="next" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select #collection_object_id# oldValue, max(collection_object_id) nextValue from #datashotbl# 
		where enteredby = '#session.username#'
	</cfquery>
	<cfreturn next>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getPrefs" access="remote">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from cf_dataentry_settings where username='#session.username#'
	</cfquery>
	<cfreturn d>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="saveEdits" access="remote">
	<cfargument name="q" required="yes">
	<cfoutput>
		<cfquery name="getCols" datasource="uam_god">
			select column_name from sys.user_tab_cols
			where table_name='BULKLOADER'
			order by internal_column_id
		</cfquery>
		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "variables.#k#"=urldecode(v)>
		</cfloop>
		<cfset sql = "UPDATE #datashotbl# SET ">
		<cfloop query="getCols">
			<cfif isDefined("variables.#column_name#")>
				<cfif column_name is not "collection_object_id">
					<cfset thisData = evaluate("variables." & column_name)>
					<cfset thisData = replace(thisData,"'","''","all")>
					<cfset sql = "#SQL#,#COLUMN_NAME# = '#thisData#'">
				</cfif>
			</cfif>
		</cfloop>
		<cfset sql = "#SQL# where collection_object_id = #collection_object_id#">
		<cfset sql = replace(sql,"UPDATE #datashotbl# SET ,","UPDATE #datashotbl# SET ")>			
		<cftry>
			<cftransaction>
				<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					#preservesinglequotes(sql)#
				</cfquery>
				<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select #collection_object_id# collection_object_id, bulk_check_one(#collection_object_id#) rslt from dual
				</cfquery>
			</cftransaction>
		<cfcatch>
			<cfset result = querynew("collection_object_id,rslt")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "collection_object_id", collection_object_id, 1)>
			<cfset temp = QuerySetCell(result, "rslt",  cfcatch.message & "; " &  cfcatch.detail, 1)>
		</cfcatch>
		</cftry>
		<cfreturn result>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="saveNewRecord" access="remote">
	<cfargument name="q" required="yes">
	<cfoutput>
		<cfquery name="getCols" datasource="uam_god">
			select column_name from sys.user_tab_cols
			where table_name='BULKLOADER'
			order by internal_column_id
		</cfquery>
		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "variables.#k#"=urldecode(v)>
		</cfloop>
		<cfset sql = "INSERT INTO #datashotbl# (">
		<cfset flds = "">
		<cfset data = "">
		<cfloop query="getCols">
			<cfif isDefined("variables.#column_name#")>
				<cfif column_name is not "collection_object_id">
					<cfset flds = "#flds#,#column_name#">
					<cfset thisData = evaluate("variables." & column_name)>
					<cfset thisData = replace(thisData,"'","''","all")>
					<cfset data = "#data#,'#thisData#'">
				</cfif>
			</cfif>
		</cfloop>
		<cfset flds = trim(flds)>
		<cfset flds=right(flds,len(flds)-1)>
		<cfset data = trim(data)>
		<cfset data=right(data,len(data)-1)>
		<cfset flds = "collection_object_id,#flds#">
		<cfset data = "#datashotbl#_PKEY.nextval,#data#">
		<cfset sql = "insert into #datashotbl# (#flds#) values (#data#)">
		<cftry>
			<cftransaction>
				<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					#preservesinglequotes(sql)#
				</cfquery>
				<cfquery name="tVal" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select #datashotbl#_PKEY.currval as currval from dual
				</cfquery>
				<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select #datashotbl#_PKEY.currval collection_object_id, bulk_check_one(#datashotbl#_PKEY.currval) rslt from dual
				</cfquery>
			</cftransaction>
		<cfcatch>
			<cfset result = querynew("collection_object_id,rslt")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "collection_object_id", collection_object_id, 1)>
			<cfset temp = QuerySetCell(result, "rslt",  cfcatch.message & "; " &  cfcatch.detail, 1)>
		</cfcatch>
		</cftry>
		<cfreturn result>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getPage" access="remote">
	<cfargument name="page" required="yes">
    <cfargument name="pageSize" required="yes">
	<cfargument name="gridsortcolumn" required="yes">
    <cfargument name="gridsortdirection" required="yes">
	<cfargument name="accn" required="yes">
	<cfargument name="enteredby" required="yes">
	<cfargument name="colln" required="yes">
	<cfset startrow=page * pageSize>
	<cfset stoprow=startrow + pageSize>
	<cfif len(gridsortcolumn) is 0>
		<cfset gridsortcolumn="collection_object_id">
	</cfif>
<cfoutput>
	<cfset sql="select * from #datashotbl# where 1=1 ">
        <!--- 
	<cfif len(accn) gt 0>
		<cfset sql=sql & " and accn IN (#accn#)">
	</cfif>
	<cfif len(enteredby) gt 0>
		<cfset sql=sql & " and enteredby IN (#enteredby#)">
	</cfif>
        --->
	<cfif len(colln) gt 0>
		<cfset sql = "#sql# AND institution_acronym || ':' || collection_cde IN (#colln#)">
	</cfif>
	<cfset sql=sql & " order by #gridsortcolumn# #gridsortdirection#">

	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		#preservesinglequotes(sql)#
	</cfquery>
</cfoutput>
	      <cfreturn queryconvertforgrid(data,page,pagesize)/>
</cffunction>
<!--------------------------------------->
<cffunction name="editRecord" access="remote">
	<cfargument name="cfgridaction" required="yes">
    <cfargument name="cfgridrow" required="yes">
	<cfargument name="cfgridchanged" required="yes">
	<cfoutput>
		<cfset colname = StructKeyList(cfgridchanged)>
		<cfset value = cfgridchanged[colname]>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update #datashotbl# set  #colname# = '#value#'
			where collection_object_id=#cfgridrow.collection_object_id#
		</cfquery>
	</cfoutput>
</cffunction>
</cfcomponent>
