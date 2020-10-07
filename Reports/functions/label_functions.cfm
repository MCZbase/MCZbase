<cffunction name="format_mcz" access="public" returntype="Query">
    <cfargument name="d" required="true" type="query">
	<!--- Set up arrays that will be used to hold new columns added to result set--->
    <cfset lAr = ArrayNew(1)>
	<cfset gAr = ArrayNew(1)>
	<cfset dAr = ArrayNew(1)>
	<cfset i=1>
	<cfloop query="d">
		<!---  create a re-written higher geography of country:state:county --->
        <cfset l_geog="">
        <cfif #country# is "United States">
                <cfset l_geog="USA">
        <cfelseif #country# is "United States of America">
             <cfset l_geog="USA">
        <cfelseif #country# is "Commonwealth of the Bahamas">
             <cfset l_geog="Bahamas">
        <cfelseif #country# is "Democratic Republic of the Congo">
             <cfset l_geog="D.R. Congo">
        <cfelseif #country# is "Federated States of Micronesia">
             <cfset l_geog="Micronesia">
        <cfelseif #country# is "British Virgin Islands">
             <cfset l_geog="British Virgin Is.">
        <cfelseif #country# is "Republic of Trinidad and Tobago">
             <cfset l_geog="Trinidad and Tobago">
        <cfelseif #country# is "Saint Kitts and Nevis">
             <cfset l_geog="St. Kitts and Nevis">
        <cfelseif #country# is "Central African Republic">
             <cfset l_geog="C.A.R.">
        <cfelseif #country# is "Virgin Islands of the United States">
             <cfset l_geog="U.S. Virgin Islands">
        <cfelseif #country# is "Turks and Caicos Islands">
             <cfset l_geog="Turks and Caicos">
        <cfelseif #country# is "Democratic Republic of Timor-Leste">
             <cfset l_geog="D.R. Timor-Leste">
        <cfelse>
             <cfset l_geog="#country#">
        </cfif>
        <cfset l_geog="#l_geog#: #state_prov#">
        <cfif len(#county#) gt 0>
                <cfset l_geog="#l_geog#; #replace(county,'County','Co.')#">
        </cfif>
        <cfset gAr[i] = "#l_geog#">
		
		<!--- create a rewritten specific locality that includes the elevation. --->
        <cfset l_spec_locality="">
        <cfif len(#ORIG_ELEV_UNITS#) gt 0>
                <cfif MINIMUM_ELEVATION is MAXIMUM_ELEVATION>
                        <cfset l_spec_locality = "#spec_locality#. Elev. #MINIMUM_ELEVATION# #ORIG_ELEV_UNITS#">
                <cfelse>
                        <cfset l_spec_locality = "#spec_locality#. Elev. #MINIMUM_ELEVATION#-#MAXIMUM_ELEVATION# #ORIG_ELEV_UNITS#">
                </cfif>
         </cfif>
         <cfset lAr[i] = "#l_spec_locality#">

		 <!--- create a re-written date collected, build from verbatim_date --->
		 <cfset colldate="">
		 <cfif Find("/", verbatim_date) GT 0>
		 		<cfif gettoken(verbatim_date, 1, "/") EQ "0">
		 			<cfset collday = "*">
		 		<cfelse>
		 			<cfset collday = gettoken(verbatim_date, 1, "/")>
		 		</cfif> 
		 		<cfset collmonth=gettoken(verbatim_date, 2, "/")>
				<cfswitch expression = "#collmonth#">
				   <cfcase value="1">
				   		<cfset collmonth = "Jan">
				   </cfcase>	 
				   <cfcase value="2">
				   		<cfset collmonth = "Feb">
				   </cfcase>
				   <cfcase value="3">
				   		<cfset collmonth = "Mar">
				   	</cfcase>
				   <cfcase value="4">
				   		<cfset collmonth = "Apr">
				   	</cfcase>
				   <cfcase value="5">
				   		<cfset collmonth = "May">
				   	</cfcase>
				   <cfcase value="6">
				   		<cfset collmonth = "Jun">
				   	</cfcase>
				   <cfcase value="7">
				   		<cfset collmonth = "Jul">
				   	</cfcase>
				   <cfcase value="8">
				   		<cfset collmonth = "Aug">
				   	</cfcase> 
				   <cfcase value="9">
				   		<cfset collmonth = "Sep">
				   	</cfcase>
				   <cfcase value="10">
				   		<cfset collmonth = "Oct">
				   	</cfcase>
				   <cfcase value="11">
				   		<cfset collmonth = "Nov">
				   	</cfcase>
				   <cfcase value="12">
				   		<cfset collmonth = "Dec">
				   	</cfcase>
				   <cfdefaultcase> 
					        <cfset collmonth="*"> 
					</cfdefaultcase>
				</cfswitch>
				<cfif gettoken(replace(verbatim_date, "-", "/"), 3, "/") eq "0">
					<cfset collyear= "*">
				<cfelse> 
					<cfset collyear = gettoken(replace(verbatim_date, "-", "/"), 3, "/")>
				</cfif>
				<cfset colldate="#collday#-#collmonth#-#collyear#">
			<cfelse>
				<cfset colldate=verbatim_date>
			</cfif>
			<cfset dAr[i] = "#colldate#">
			<!--- Iterate the array position counter --->
			<cfset i=i+1>
	</cfloop>
		
    <!---  Make the rewritten values available as new columns in the resultset --->
	<!---  The names here can be bound to controls in a report --->
    <cfset temp=queryAddColumn(d,"colldate","VarChar",dAr)>
    <cfset temp=queryAddColumn(d,"spec_locality_rewritten","VarChar",lAr)>
    <cfset temp=queryAddColumn(d,"geog_rewritten","VarChar",gAr)>

  <cfreturn d>
</cffunction>
