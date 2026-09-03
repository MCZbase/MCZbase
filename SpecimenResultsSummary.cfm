<cfinclude template = "/includes/_header.cfm">
<!--- Parameters this page reads from the request, put in the variables scope explicitly
	rather than resolved implicitly across the url and form scopes, which is deprecated.
	A name that was not supplied is omitted, so the defaults below still apply. --->
<cfset REQUEST_PARAMETERS = "cbifurl,cnt,detail_level,displayrows,downloadFile,groupBy,mapurl,maskThis,
	newQuery,newSearch,oidOper,order_by,order_order,sciNameOper,startRow">
<cfset structAppend(variables,requestScopeValues(REQUEST_PARAMETERS),true)>
<!--- These are read without an isdefined guard, so they need a value even when the
	request omits them. --->
<cfparam name="variables.downloadFile" default="">
<cfparam name="variables.order_by" default="">
     <div style="width: 70em;margin: 0 auto; padding: 2em 0 3em 0;">
<cfset title="Specimen Results">
<cfif not isdefined("displayrows")>
	<cfset displayrows = session.displayrows>
</cfif>
<cfif not isdefined("SearchParams")>
	<cfset SearchParams = "">
</cfif>
<cfif not isdefined("groupBy")>
	<cfset groupBy = "">
</cfif>
<cfif not isdefined("maskThis")>
	<cfset maskThis = "">
</cfif>

<cfif not isdefined("newQuery")>
	<cfset newQuery = 1>
</cfif>
<cfif not isdefined("sciNameOper")>
	<cfset sciNameOper = "LIKE">
</cfif>
<cfif not isdefined("oidOper")>
	<cfset oidOper = "LIKE">
</cfif>
<cfif not isdefined("mapurl")>
	<cfset mapurl = "null">
</cfif>
<cfif #action# contains ",">
	<cfset action = #left(action,find(",",action)-1)#>
</cfif>


<!--- set up the basic SQL, tack qualifiers on below ><cfset thisUserCols = "#thisUserCols#,attribute_detail">--->


<!--- The progress bar --->
<cfif #newQuery# is 1>
 <cfset basSelect = "SELECT COUNT(distinct(#session.flatTableName#.collection_object_id)) CountOfCatalogedItem">
 <cfset basJoin = "INNER JOIN cataloged_item ON (#session.flatTableName#.collection_object_id = cataloged_item.collection_object_id)">
 <cfset basFrom = " FROM #session.flatTableName#">
<cfset basGroup = "">
<cfif listfindnocase(groupBy,"scientific_name") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.scientific_name">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.scientific_name">
</cfif>

<cfif listfindnocase(groupBy,"continent_ocean") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.continent_ocean">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.continent_ocean">
</cfif>
<cfif listfindnocase(groupBy,"country") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.country">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.country">
</cfif>
<cfif listfindnocase(groupBy,"state_prov") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.state_prov">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.state_prov">
</cfif>
<cfif listfindnocase(groupBy,"county") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.county">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.county">
</cfif>
<cfif listfindnocase(groupBy,"quad") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.quad">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.quad">
</cfif>
<cfif listfindnocase(groupBy,"feature") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.feature">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.feature">
</cfif>
<cfif listfindnocase(groupBy,"water_feature") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.water_feature">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.water_feature">
</cfif>
<cfif listfindnocase(groupBy,"island_group") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.island_group">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.island_group">
</cfif>
<cfif listfindnocase(groupBy,"island") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.island">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.island">
</cfif>
<cfif listfindnocase(groupBy,"sea") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.sea">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.sea">
</cfif>
<cfif listfindnocase(groupBy,"spec_locality") GT 0>
	 <cfset basSelect = "#basSelect#,#session.flatTableName#.spec_locality">
	 <cfset basGroup = "#basGroup#,#session.flatTableName#.spec_locality">
</cfif>
<cfif listfindnocase(groupBy,"yr") GT 0>
	 <cfset basSelect = "#basSelect#,to_char(#session.flatTableName#.began_date,'yyyy') yr">
	 <cfset basGroup = "#basGroup#,to_char(#session.flatTableName#.began_date,'yyyy')">
</cfif>
<cfif len(basGroup) GT 0>
	<cfset basGroup = "GROUP BY #right(basGroup,len(basGroup)-1)#">
</cfif>



<!--------------------------------------------------------------->
	<cfset basWhere = " where 1=1 ">

	<cfset mapurl="">
	<cfinclude template="includes/SearchSql.cfm">
        <!--- require some actual searching --->
        <cfset srchTerms="">
        <cfloop list="#mapurl#" delimiters="&" index="t">
                <cfset tt=listgetat(t,1,"=")>
                <cfset srchTerms=listappend(srchTerms,tt)>
        </cfloop>
        <!--- remove standard criteria that kill Oracle... --->
        <cfif listcontains(srchTerms,"ShowObservations")>
                <cfset srchTerms=listdeleteat(srchTerms,listfindnocase(srchTerms,'ShowObservations'))>
        </cfif>
        <cfif listcontains(srchTerms,"collection_id")>
                <cfset srchTerms=listdeleteat(srchTerms,listfindnocase(srchTerms,'collection_id'))>
        </cfif>
        <!--- ... and abort if there's nothing left --->
        <cfif len(srchTerms) is 0>
                <CFSETTING ENABLECFOUTPUTONLY=0>
                <font color="##FF0000" size="+2">You must enter some search criteria!</font>
                <cfabort>
        </cfif>

	<!--- wrap everything up in a string --->

		<cfset SqlString = "#basSelect# #basFrom# #basJoin# #basWhere# #whereClausesToSql(variables.whereClauses)# #basGroup#">

		<!-----

		<cfoutput>
	#preserveSingleQuotes(SqlString)#	</cfoutput>
	<cfflush>

		----->



	<!---
		get search parameters
		There is soem goofy stuff that applies to thei form ONLY -
		be careful pasting this code!!
		-- REMOVE SCIENTIFIC NAME
		-- REMOVE sciNameOper
	---->

	<cfset searchParams = "">
	<cfoutput>
		<cfloop list="#StructKeyList(form)#" index="key">
			 <cfif len(#form[key]#) gt 0>
				<cfif #key# is not "FIELDNAMES"
					AND #key# is not "SEARCHPARAMS"
					AND #key# is not "mapurl"
					AND #key# is not "cbifurl"
					and #key# is not "newquery"
					and #key# is not "ORDER_ORDER"
					and #key# is not "ORDER_BY"
					and #key# is not "newsearch"
					and #key# is not "STARTROW"
					and #key# is not "sciNameOper"
					and #key# is not "scientific_name">
					<cfif len(#searchParams#) is 0>
						<cfset searchParams='<input type="hidden" name="#key#" value="#form[key]#">'>
					<cfelse>
						<cfset searchParams='#searchParams#<input type="hidden" name="#key#" value="#form[key]#">'>
					</cfif>
				</cfif>
			 </cfif>
		</cfloop>
		<!---- also grab anything from the URL --->
		<cfloop list="#StructKeyList(url)#" index="key">
		 <cfif len(#url[key]#) gt 0>
				<cfif #key# is not "FIELDNAMES"
					AND #key# is not "SEARCHPARAMS"
					AND #key# is not "mapurl"
					AND #key# is not "cbifurl"
					and #key# is not "newquery"
					and #key# is not "ORDER_ORDER"
					and #key# is not "ORDER_BY"
					and #key# is not "newsearch"
					and #key# is not "STARTROW"
					and #key# is not "sciNameOper"
					and #key# is not "scientific_name">
					<cfif len(#searchParams#) is 0>
						<cfset searchParams='<input type="hidden" name="#key#" value="#url[key]#">'>
					<cfelse>
						<cfset searchParams='#searchParams#<input type="hidden" name="#key#" value="#url[key]#">'>
					</cfif>
				</cfif>
		  </cfif>
		</cfloop>

		<cfset searchParams = #replace(searchParams,"'","","all")#>
	</cfoutput>


<cfset getData = queryExecute(SqlString,variables.sqlParams,{
	datasource = "user_login",
	username = session.dbuser,
	password = decrypt(session.epw,cookie.cfid)
})>
	<cfif getData.recordcount is 0>
	<CFSETTING ENABLECFOUTPUTONLY=0>
			<cfoutput>

		<font color="##FF0000" size="+2">Your search returned no results.</font>
		<p>Some possibilities include:</p>
		<ul>
			<li>
				If you searched by taxonomy, please consult the <a href="/Taxa.cfm" class="novisit">MCZbase Taxonomy</a>.			</li>
			<li>
				Try broadening your search criteria. Try the next-higher geographic element, remove criteria, etc.			</li>
			<li>
				Use dropdowns or partial word matches instead of text strings, which may be entered in unexpected ways. "Doe" is a good choice for a collector if "John P. Doe" didn't match anything.			</li>
			<li>
				Read the documentation for individual search fields (click the title of the field to see documentation). Arctos fields may not be what you expect them to be.			</li>
		</ul>
		</cfoutput>

		<cfabort>

	</cfif>

	<cfset newQuery=0>
<cfset newSearch = 1>
</cfif>
<cfset order_by = "">
<cfif listfindnocase(groupBy,"continent_ocean") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "continent_ocean">
	 <cfelse>
	 	<cfset order_by = "#order_by#,continent_ocean">
	 </cfif>
</cfif>
<cfif listfindnocase(groupBy,"country") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "country">
	 <cfelse>
	 	<cfset order_by = "#order_by#,country">
	 </cfif>
</cfif>
<cfif listfindnocase(groupBy,"state_prov") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "state_prov">
	 <cfelse>
	 	<cfset order_by = "#order_by#,state_prov">
	 </cfif>
</cfif>
<cfif listfindnocase(groupBy,"county") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "county">
	 <cfelse>
	 	<cfset order_by = "#order_by#,county">
	 </cfif>
</cfif>
<cfif listfindnocase(groupBy,"quad") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "quad">
	 <cfelse>
	 	<cfset order_by = "#order_by#,quad">
	 </cfif>
</cfif>
<cfif listfindnocase(groupBy,"feature") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "feature">
	 <cfelse>
	 	<cfset order_by = "#order_by#,feature">
	 </cfif>
</cfif>
<cfif listfindnocase(groupBy,"water_feature") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "water_feature">
	 <cfelse>
	 	<cfset order_by = "#order_by#,water_feature">
	 </cfif>
</cfif>
<cfif listfindnocase(groupBy,"island") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "island">
	 <cfelse>
	 	<cfset order_by = "#order_by#,island">
	 </cfif>
</cfif>
<cfif listfindnocase(groupBy,"island_group") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "island_group">
	 <cfelse>
	 	<cfset order_by = "#order_by#,island_group">
	 </cfif>
</cfif>
<cfif listfindnocase(groupBy,"sea") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "sea">
	 <cfelse>
	 	<cfset order_by = "#order_by#,sea">
	 </cfif>
</cfif>
<cfif listfindnocase(groupBy,"spec_locality") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "spec_locality">
	 <cfelse>
	 	<cfset order_by = "#order_by#,spec_locality">
	 </cfif>
</cfif>

<cfif listfindnocase(groupBy,"yr") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "yr">
	 <cfelse>
	 	<cfset order_by = "#order_by#,yr">
	 </cfif>
</cfif>

<cfif listfindnocase(groupBy,"scientific_name") GT 0>
	 <cfif len(#order_by#) is 0>
	 	<cfset order_by = "scientific_name">
	 <cfelse>
	 	<cfset order_by = "#order_by#,scientific_name">
	 </cfif>
</cfif>

<cfif not isdefined("order_order") or len(#order_order#) is 0>
	<cfset order_order = "asc">
</cfif>

<cfset cfidAndToken = "#cookie.cfid##session.reencodedToken#">
<cfif isdefined("newSearch") and #newSearch# is 1>
	<cfquery name="SpecRes#cfidAndToken#" dbtype="query" cachedwithin="#createtimespan(0,0,0,0)#">
		select * from getData
	</cfquery>
</cfif>
<cfquery name="SpecRes#cfidAndToken#" dbtype="query" cachedwithin="#createtimespan(0,0,60,0)#">
	select * from getData
</cfquery>


<cfoutput>
<cfquery name="getBasic" dbtype="query">
	select * from SpecRes#cfidAndToken#
	<cfif len(order_by) GT 0>
		order by #order_by#
	</cfif>
</cfquery>

<cfquery name="s" dbtype="query">
	select sum(COUNTOFCATALOGEDITEM) c from getBasic
</cfquery>
    <h3>Returned #s.c# specimens in #getBasic.recordcount# rows.</h3>
</cfoutput>

<cfquery name="cnt" dbtype="query">
	select CountOfCatalogedItem from getBasic
</cfquery>

<table border="1">
<tr>




	<!---- always on --->

	<td nowrap><strong>Count</strong>	</td>

	<cfif listfindnocase(groupBy,"scientific_name") GT 0>
		<td nowrap><strong>Scientific Name</strong></td>
	</cfif>
	<cfif listfindnocase(groupBy,"continent_ocean") GT 0>
		<td nowrap><strong>Continent</strong></td>
	</cfif>
	<cfif listfindnocase(groupBy,"yr") GT 0>
		<td nowrap><strong>Year</strong></td>
	</cfif>
	<cfif listfindnocase(groupBy,"country") GT 0>
		<td nowrap><strong>Country</strong></td>
	</cfif>
	<cfif listfindnocase(groupBy,"state_prov") GT 0>
		<td nowrap><strong>State</strong></td>
	</cfif>
	<cfif listfindnocase(groupBy,"county") GT 0>
		<td nowrap><strong>County</strong></td>
	</cfif>
	<cfif listfindnocase(groupBy,"quad") GT 0>
		<td nowrap><strong>Map Name</strong></td>
	</cfif>
	<cfif listfindnocase(groupBy,"feature") GT 0>
		<td nowrap><strong>Land Feature</strong></td>
	</cfif>
  <cfif listfindnocase(groupBy,"water_feature") GT 0>
    <td nowrap><strong>Water Feature</strong></td>
  </cfif>
	<cfif listfindnocase(groupBy,"island_group") GT 0>
		<td nowrap><strong>Island Group</strong></td>
	</cfif>
	<cfif listfindnocase(groupBy,"island") GT 0>
		<td nowrap><strong>Island</strong></td>
	</cfif>
	<cfif listfindnocase(groupBy,"sea") GT 0>
		<td nowrap><strong>Sea</strong></td>
	</cfif>
	<cfif listfindnocase(groupBy,"spec_locality") GT 0>
		<td nowrap><strong>Specific Locality</strong></td>
	</cfif>
	<cfset i=1>
<cfoutput query="getBasic">
    <tr	#iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#	>
	 <form name="theseSpecs#i#" method="post" action="/SpecimenResults.cfm">
	 #searchparams#
		<cfif listfindnocase(groupBy,"scientific_name") GT 0>
			<input type="hidden" name="Scientific_Name" value="#Scientific_Name#">
			<input type="hidden" name="sciNameOper" value="=">
		</cfif>

		<cfif listfindnocase(groupBy,"yr") GT 0 and searchparams does not contain 'name="yr"'>
			<cfif len(#yr#) gt 0>
				<input type="hidden" name="yr" value="#yr#">
			<cfelse>
				<input type="hidden" name="yr" value="NULL">
			</cfif>
		</cfif>
		<cfif listfindnocase(groupBy,"continent_ocean") GT 0 and searchparams does not contain 'name="continent_ocean"'>
			<cfif len(#continent_ocean#) gt 0>
				<input type="hidden" name="continent_ocean" value="#continent_ocean#">
			<cfelse>
				<input type="hidden" name="continent_ocean" value="NULL">
			</cfif>
		</cfif>
		<cfif listfindnocase(groupBy,"country") GT 0 and searchparams does not contain 'name="country"'>
			<cfif len(#country#) gt 0>
				<input type="hidden" name="country" value="#country#">
			<cfelse>
				<input type="hidden" name="country" value="NULL">
			</cfif>
		</cfif>
		<cfif listfindnocase(groupBy,"state_prov") GT 0 and searchparams does not contain 'name="state_prov"'>
			<cfif len(#state_prov#) gt 0>
				<input type="hidden" name="state_prov" value="#state_prov#">
			<cfelse>
				<input type="hidden" name="state_prov" value="NULL">
			</cfif>
		</cfif>
		<cfif listfindnocase(groupBy,"county") GT 0 and searchparams does not contain 'name="county"'>
			<cfif len(#county#) gt 0>
				<input type="hidden" name="county" value="#county#">
			<cfelse>
				<input type="hidden" name="county" value="NULL">
			</cfif>
		</cfif>
		<cfif listfindnocase(groupBy,"quad") GT 0 and searchparams does not contain 'name="quad"'>
			<cfif len(#quad#) gt 0>
				<input type="hidden" name="quad" value="#quad#">
			<cfelse>
				<input type="hidden" name="quad" value="NULL">
			</cfif>
		</cfif>
		<cfif listfindnocase(groupBy,"feature") GT 0 and searchparams does not contain 'name="feature"'>
			<cfif len(#feature#) gt 0>
				<input type="hidden" name="feature" value="#feature#">
			<cfelse>
				<input type="hidden" name="feature" value="NULL">
			</cfif>
		</cfif>
    <cfif listfindnocase(groupBy,"water_feature") GT 0 and searchparams does not contain 'name="water_feature"'>
      <cfif len(#water_feature#) gt 0>
        <input type="hidden" name="water_feature" value="#water_feature#">
      <cfelse>
        <input type="hidden" name="water_feature" value="NULL">
      </cfif>
    </cfif>
		<cfif listfindnocase(groupBy,"island_group") GT 0 and searchparams does not contain 'name="island_group"'>
			<cfif len(#island_group#) gt 0>
				<input type="hidden" name="island_group" value="#island_group#">
			<cfelse>
				<input type="hidden" name="island_group" value="NULL">
			</cfif>
		</cfif>
		<cfif listfindnocase(groupBy,"island") GT 0 and searchparams does not contain 'name="island"'>
			<cfif len(#island#) gt 0>
				<input type="hidden" name="island" value="#island#">
			<cfelse>
				<input type="hidden" name="island" value="NULL">
			</cfif>
		</cfif>
		<cfif listfindnocase(groupBy,"sea") GT 0 and searchparams does not contain 'name="sea"'>
			<cfif len(#sea#) gt 0>
				<input type="hidden" name="sea" value="#sea#">
			<cfelse>
				<input type="hidden" name="sea" value="NULL">
			</cfif>
		</cfif>
		<cfif listfindnocase(groupBy,"spec_locality") GT 0 and searchparams does not contain 'name="spec_locality"'>
			<cfif len(#spec_locality#) gt 0>
				<input type="hidden" name="spec_locality" value="#spec_locality#">
			<cfelse>
				<input type="hidden" name="spec_locality" value="NULL">
			</cfif>
		</cfif>
	  </form>
      <td nowrap>
	   <a href="javascript:void(0);"
	   	onClick="theseSpecs#i#.submit();"
		onMouseOver="self.status='Go to SpecimenRecords'"
		onMouseOut="self.status=''">
	 <div class="linkButton"
			onmouseover="this.className='linkButton btnhov'"
			onmouseout="this.className='linkButton'"
			>#countOfCatalogedItem#</div></a>	 </td>

	<cfif listfindnocase(groupBy,"scientific_name") GT 0>
		<td nowrap><i>#Scientific_Name#</i></td>
	</cfif>
	<cfif listfindnocase(groupBy,"continent_ocean") GT 0>
		<td nowrap>#continent_ocean#&nbsp;</td>
	</cfif>
	<cfif listfindnocase(groupBy,"yr") GT 0>
		<td nowrap>#yr#&nbsp;</td>
	</cfif>
	<cfif listfindnocase(groupBy,"country") GT 0>
		<td nowrap>#country#&nbsp;</td>
	</cfif>
	<cfif listfindnocase(groupBy,"state_prov") GT 0>
		<td nowrap>#state_prov#&nbsp;</td>
	</cfif>
	<cfif listfindnocase(groupBy,"county") GT 0>
		<td nowrap>#county#&nbsp;</td>
	</cfif>
	<cfif listfindnocase(groupBy,"quad") GT 0>
		<td nowrap>#quad#&nbsp;</td>
	</cfif>
	<cfif listfindnocase(groupBy,"feature") GT 0>
		<td nowrap>#feature#&nbsp;</td>
	</cfif>
  <cfif listfindnocase(groupBy,"water_feature") GT 0>
    <td nowrap>#water_feature#&nbsp;</td>
  </cfif>
	<cfif listfindnocase(groupBy,"island_group") GT 0>
		<td nowrap>#island_group#&nbsp;</td>
	</cfif>
	<cfif listfindnocase(groupBy,"island") GT 0>
		<td nowrap>#island#&nbsp;</td>
	</cfif>
	<cfif listfindnocase(groupBy,"sea") GT 0>
		<td nowrap>#sea#&nbsp;</td>
	</cfif>
	<cfif listfindnocase(groupBy,"spec_locality") GT 0>
		<td nowrap>#spec_locality#&nbsp;</td>
	</cfif>
  </tr>
  <cfset i=#I#+1>
  </cfoutput>
</table>

<!------------------------------- download --------------------------------->


<cfset dlPath = "#Application.SpecimenDownloadPath#">
<cfset dlFile = "#session.DownloadFileName#">
 <cfset header ="Count">
	<cfif listfindnocase(groupBy,"scientific_name") GT 0>
		<cfset header = "#header##chr(9)#Scientific_Name">
	</cfif>
	<cfif listfindnocase(groupBy,"continent_ocean") GT 0>
		 <cfset header = "#header##chr(9)#continent_ocean">
	</cfif>
	<cfif listfindnocase(groupBy,"country") GT 0>
		<cfset header = "#header##chr(9)#country">
	</cfif>
	<cfif listfindnocase(groupBy,"state_prov") GT 0>
		<cfset header = "#header##chr(9)#state_prov">
	</cfif>
	<cfif listfindnocase(groupBy,"county") GT 0>
		<cfset header = "#header##chr(9)#county">
	</cfif>
	<cfif listfindnocase(groupBy,"quad") GT 0>
		<cfset header = "#header##chr(9)#quad">
	</cfif>
	<cfif listfindnocase(groupBy,"feature") GT 0>
		<cfset header = "#header##chr(9)#feature">
	</cfif>
  <cfif listfindnocase(groupBy,"water_feature") GT 0>
    <cfset header = "#header##chr(9)#water_feature">
  </cfif>
	<cfif listfindnocase(groupBy,"island_group") GT 0>
		<cfset header = "#header##chr(9)#island_group">
	</cfif>
	<cfif listfindnocase(groupBy,"island") GT 0>
		<cfset header = "#header##chr(9)#island">
	</cfif>
	<cfif listfindnocase(groupBy,"sea") GT 0>
		<cfset header = "#header##chr(9)#sea">
	</cfif>
	<cfif listfindnocase(groupBy,"spec_locality") GT 0>
		<cfset header = "#header##chr(9)#spec_locality">
	</cfif>

<cfset header=#trim(header)#>
	<cfset header = "#header##chr(10)#"><!--- add one and only one line break back onto the end --->
<cffile action="write" file="#dlPath##dlFile#" addnewline="no" output="#header#">


<cfoutput query="getBasic">
 	 <cfset oneLine ="#countOfCatalogedItem#">
	<cfif listfindnocase(groupBy,"scientific_name") GT 0>
		<cfset oneLine = "#oneLine##chr(9)##Scientific_Name#">
	</cfif>
	<cfif listfindnocase(groupBy,"continent_ocean") GT 0>
		 <cfset oneLine = "#oneLine##chr(9)##continent_ocean#">
	</cfif>
	<cfif listfindnocase(groupBy,"country") GT 0>
		<cfset oneLine = "#oneLine##chr(9)##country#">
	</cfif>
	<cfif listfindnocase(groupBy,"state_prov") GT 0>
		<cfset oneLine = "#oneLine##chr(9)##state_prov#">
	</cfif>
	<cfif listfindnocase(groupBy,"county") GT 0>
		<cfset oneLine = "#oneLine##chr(9)##county#">
	</cfif>
	<cfif listfindnocase(groupBy,"quad") GT 0>
		<cfset oneLine = "#oneLine##chr(9)##quad#">
	</cfif>
	<cfif listfindnocase(groupBy,"feature") GT 0>
		<cfset oneLine = "#oneLine##chr(9)##feature#">
	</cfif>
  <cfif listfindnocase(groupBy,"water_feature") GT 0>
    <cfset oneLine = "#oneLine##chr(9)##water_feature#">
  </cfif>
	<cfif listfindnocase(groupBy,"island_group") GT 0>
		<cfset oneLine = "#oneLine##chr(9)##island_group#">
	</cfif>
	<cfif listfindnocase(groupBy,"island") GT 0>
		<cfset oneLine = "#oneLine##chr(9)##island#">
	</cfif>
	<cfif listfindnocase(groupBy,"sea") GT 0>
		<cfset oneLine = "#oneLine##chr(9)##sea#">
	</cfif>
	<cfif listfindnocase(groupBy,"spec_locality") GT 0>
		<cfset oneLine = "#oneLine##chr(9)##spec_locality#">
	</cfif>






<cfset oneLine = trim(#oneLine#)>
	<cffile action="append" file="#dlPath##dlFile#" addnewline="yes" output="#oneLine#">
</cfoutput>
	<cfoutput>
		<cfset downloadFile = "/download/#dlFile#">
		<form name="download" method="post" action="/download_agree.cfm">
			<input type="hidden" name="cnt" value="#cnt.recordcount#">
			<input type="hidden" name="downloadFile" value="#downloadFile#">
            <br>
			<input type="submit" value="Download"
			class="lnkBtn"
   			onmouseover="this.className='lnkBtn btnhov'"
			onmouseout="this.className='lnkBtn'">
		</form>
	</cfoutput>
        </div>
<cfinclude template = "includes/_footer.cfm">
