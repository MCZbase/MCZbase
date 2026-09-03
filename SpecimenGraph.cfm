<cfinclude template="includes/_header.cfm">
<!--- Parameters this page reads from the request, put in the variables scope explicitly
	rather than resolved implicitly across the url and form scopes, which is deprecated.
	A name that was not supplied is omitted, so the defaults below still apply. --->
<cfset REQUEST_PARAMETERS = "action,cbifurl,chartType,detail_level,graphThis,mapurl,newQuery,newSearch,order_by,
	order_order,searchParams,show3D,size,startRow,type">
<cfset structAppend(variables,requestScopeValues(REQUEST_PARAMETERS),true)>
<!--- These are read without an isdefined guard, so they need a value even when the
	request omits them. --->
<cfparam name="variables.action" default="">
<cfparam name="variables.chartType" default="">
<cfparam name="variables.graphThis" default="">
<cfparam name="variables.searchParams" default="">
<cfparam name="variables.show3D" default="">
<cfparam name="variables.type" default="">
<!--- Columns graphThis may name.  These are grouped on, and an identifier cannot be bound,
	so the value is matched against this list rather than passed through. --->
<cfset GRAPHABLE_COLUMNS = "continent_ocean,country,state_prov,scientific_name,phylclass,genus,family,phylorder">
<cfif #action# is "nothing">
<cfoutput>
	<cfset searchParams = "">
	<!--- set up hidden form variables to use when customizing.
			Explicitly exclude things we don't want --->
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
					and #key# is not "action"
					and #key# is not "detail_level">
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
					and #key# is not "action"
					and #key# is not "detail_level">
					<cfif len(#searchParams#) is 0>
						<cfset searchParams='<input type="hidden" name="#key#" value="#url[key]#">'>
					<cfelse>
						<cfset searchParams='#searchParams#<input type="hidden" name="#key#" value="#url[key]#">'>
					</cfif>
				</cfif>
			 </cfif>
		</cfloop>
                    <div style="width: 52em;margin:0 auto;padding: 1em 0 3em 0;">
		
		<cfset searchParams = #replace(searchParams,"'","","all")#>
	<table>
		
<form name="browse" action="SpecimenGraph.cfm" method="post">
    <h2 class="wikilinks">Specimen Search Resuts as a Graph</h2>
				<tr>
					<td><strong>Chart Settings</strong></td>
					<td><strong>Chart Data</strong><sup>1</sup></td>
				</tr>
				<tr>
					<td valign="top">
						<table>
							<tr>
								<td align="right">Format:<sup>2</sup></td>
								<td>
									<select name="chartType" size="1">
										<option value="jpg">JPG</option>
										<option value="png">PNG</option>
									</select>
								</td>
							</tr>
							<tr>
								<td align="right">Size:</td>
								<td>
									<select name="size" size="1">
										<option value="240 x 320">240 x 320</option>
										<option selected="selected" value="480 x 640">480 x 640</option>
										<option value="960 x 1280">960 x 1280</option>
									</select>
								</td>
							</tr>
							<tr>
								<td align="right">Dimensions:</td>
								<td>
									<select name="show3D" size="1">
										<option value="yes">3D</option>
										<option value="no">2D</option>
									</select>
								</td>
							</tr>
							<tr>
								<td align="right">Type:</td>
								<td>
									<select name="type" size="1">
										<option value="pie">pie</option>
										<option value="bar">bar</option>
										<option value="line">line</option>
										<option value="pyramid">pyramid</option>
										<option value="area">area</option>
										<option value="horizontalbar">horizontalbar</option>
										<option value="cone">cone</option>
										<option value="curve">curve</option>
										<option value="cylinder">cylinder</option>
										<option value="step">step</option>
										<option value="scatter">scatter</option>
									</select>
								</td>
							</tr>
						</table>
					</td>
					<td valign="top">
						<select name="graphThis" multiple="multiple" size="10">
                         <option value="continent_ocean">Specimens by Continent or Ocean</option>
							<option value="country">Specimens by Country</option>
							<option value="state_prov">Specimens by State</option>
							<option value="scientific_name">Specimens by Identification</option>
                            <option value="phylclass">Specimens by Class</option>
							<option value="genus">Specimens by Genus</option>
							<option value="family">Specimens by Family</option>
							<option value="phylorder">Specimens by Order</option>
						</select>
					</td>
				</tr>
  
				#searchparams#
				<input type="hidden" name="searchParams" value='#searchParams#'>
				<input type="hidden" name="action" value="getGraph">
				<tr>
                    
					<td colspan="2" align="center">
						<input type="submit" 
								value="Get Graphs" 
								class="schBtn"
   								onmouseover="this.className='schBtn btnhov'" 
								onmouseout="this.className='schBtn'" style="margin: 1em 0;">	
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<div class="grayishbox">
                            <ul class="pubLinks" style="margin-top:0;"><li>1) CONTROL and click to create multiple charts</li>
                                <li>2) You may save charts to your hard drive as images. </li>
							<ul><li>Your browser may act strangely, but it will probably
                                work if you can save with an image (not .cfm) extension.</li>
                                </ul>
                            </ul>
						</div>
					</td>
				</tr>
				
				
				
				
			</form>
			
	</table>
            </div>
	
		</cfoutput>
</cfif>		
<!------------------------------------------------------------------->
<cfif #action# is "getGraph">
<cfoutput>
	<cfset chartHeight = listfirst(size," x ")>
	<cfset chartWidth = listlast(size," x ")>
	<cfloop list="#graphThis#" index="variables.graphColumn">
		<cfif NOT listfindnocase(GRAPHABLE_COLUMNS,variables.graphColumn)>
			<cfthrow message="Unsupported value for graphThis.">
		</cfif>
	</cfloop>
	<cfloop list="#graphThis#" index="item">
		<cfset x = "#item#">
		<cfset y="Specimens">
			<cfif listcontains("family,phylorder,genus",#item#)>
				<cfset basSelect = "SELECT count(flatTableName.cat_num) as y_data,
					getTaxa(flatTableName.collection_object_id,'#item#') as x_data">
				<cfset basGroup = "GROUP BY getTaxa(flatTableName.collection_object_id,'#item#')">
			<cfelse>
				<cfset basSelect = "SELECT count(flatTableName.cat_num) y_data,
					decode(flatTableName.#item#,
					NULL,'not recorded',
					flatTableName.#item#) as x_data">
				<cfif #item# is "scientific_name">
					<cfset basGroup = "GROUP BY flatTableName.#item#">
				<cfelse>
					<cfset basGroup = "GROUP BY #item#">
				</cfif>
				
			</cfif>
			
			<cfset basFrom = " FROM #session.flatTableName# flatTableName">
			<cfset basJoin = "INNER JOIN cataloged_item ON (flatTableName.collection_object_id =cataloged_item.collection_object_id)">
			<cfset basWhere = " WHERE flatTableName.collection_object_id IS NOT NULL ">	
			
			<cfset mapurl="">
			<!--- One chart per column, each with its own criteria, so the clauses and their values
				start empty on every pass rather than accumulating across the loop. --->
			<cfset variables.whereClauses = arrayNew(1)>
			<cfset variables.sqlParams = structNew()>
			<cfset variables.customIdTypeAdded = false>
			<cfset variables.basShellPredicate = "">
			<cfset basOrder = "ORDER BY count(flatTableName.cat_num) DESC">
			<cfinclude template="includes/SearchSql.cfm">
			<cfset SqlString = "#basSelect# #basFrom# #basJoin# #basWhere# #whereClausesToSql(variables.whereClauses)# #basGroup# #basOrder#">	
			<cfset getGraph = queryExecute(SqlString,variables.sqlParams,{
				datasource = "user_login",
				username = session.dbuser,
				password = decrypt(session.epw,cookie.cfid)
			})>
			
			 
			
			<cfchart format="#chartType#" 
				chartHeight = "#chartHeight#"
				chartWidth = "#chartWidth#"
				xaxistitle="#left(ucase(item),1)##right(lcase(item),len(item)-1)#" 
				yaxistitle="#y#"
				show3D="#show3D#"
				title = "Search Results by #left(ucase(item),1)##right(lcase(item),len(item)-1)# (#dateformat(now(),'dd mmm yyyy')#)"
				fontBold="yes"> 
				
				<cfchartseries type="#type#" 
					query="getGraph" 
					itemcolumn="x_data" 
					valuecolumn="y_data"
					seriesColor="##0066FF">
				</cfchartseries>
			</cfchart> 
	</cfloop>
</cfoutput>
</cfif>

<cfinclude template="includes/_footer.cfm">
