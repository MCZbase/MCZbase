<cfset pageTitle="Edit Bulkloaded Data">
<cfinclude template="/shared/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
<style>
.blTabDiv {
	width: 100%;
	overflow-x:scroll;
}
.x-border-box,
.x-border-box * {
  box-sizing: border-box;
  -moz-box-sizing: border-box;
  -ms-box-sizing: border-box;
  -webkit-box-sizing:border-box; }
.x-grid-col {min-width: 100px;}
.x	
</style>
<!-------------------------------------------------------------->
<cfif action is "loadAll">
	<cfoutput>
		<cfset sql="UPDATE bulkloader SET LOADED = NULL WHERE enteredby IN (#enteredby#)">
		<cfif len(accn) gt 0>
			<cfset sql = "#sql# AND accn IN (#accn#)">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset sql = "#sql# AND institution_acronym || ':' || collection_cde IN (#colln#)">
		</cfif>
		<cfquery name="upBulk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			#preservesinglequotes(sql)#
		</cfquery>
		<cflocation url="browseBulk.cfm?action=#returnAction#&enteredby=#enteredby#&accn=#accn#&colln=#colln#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "download">
	<cfoutput>
		<cfquery name="cNames" datasource="uam_god">
			select column_name from user_tab_cols where table_name='BULKLOADER'
			order by internal_column_id
		</cfquery>
		<cfset sql = "select * from bulkloader where enteredby IN (#enteredby#)">
		<cfif len(accn) gt 0>
			<cfset sql = "#sql# AND accn IN (#accn#)">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset sql = "#sql# AND institution_acronym || ':' || collection_cde IN (#colln#)">
		</cfif>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			#preservesinglequotes(sql)#	
		</cfquery>
		<cfset variables.encoding="UTF-8">
		<cfset fname = "BulkPendingData_#cfid#_#cftoken#.csv">
		<cfset variables.fileName="#Application.webDirectory#/download/#fname#">
		<cfset header=#trim(valuelist(cNames.column_name))#>
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
			variables.joFileWriter.writeLine(header); 
		</cfscript>
		<cfloop query="data">
			<cfset oneLine = "">
			<cfloop list="#valuelist(cNames.column_name)#" index="c">
				<cfset thisData = #evaluate(c)#>
				<cfif len(oneLine) is 0>
					<cfset oneLine = '"#thisData#"'>
				<cfelse>
					<cfset oneLine = '#oneLine#,"#thisData#"'>
				</cfif>
			</cfloop>
			<cfset oneLine = trim(oneLine)>
			<cfscript>
				variables.joFileWriter.writeLine(oneLine);
			</cfscript>
		</cfloop>
		<cfscript>	
			variables.joFileWriter.close();
		</cfscript>
		<cflocation url="/download.cfm?file=#fname#" addtoken="false">
		<a href="/download/#fname#">Click here if your file does not automatically download.</a>
	</cfoutput>
</cfif>
<cfif action is "ajaxGrid">
	<div class="container-fluid">
		<div class="col-12 p-4">
	<h1 class="h2">Grid of New Cataloged Items to be Loaded</h1>
		<h2 class="h4">Tips for finding and editing data</h2>
		<ul class="pb-3">
			<li>Default: All columns visible. Hover on any column header to see the option menu. Use the "Columns" button in the menu to select the columns visible in the grid. There is a delay after ticking a checkbox in the popup, especially when there are many rows/pages in the grid.</li>
			<li>On page load, rows are sorted by the Key. Clicking on column header sorts by that column. Also, sort through option menu next to each column header (hover to see menu). </li>
			<li>Double click fields to edit. Use "control" + "F" to bring field to focus on your screen.  This is less helpful for inserting values into empty columns because it doesn't find column headers. </li>
		</ul>
		<cfoutput>
		<cfquery name="cNames" datasource="uam_god">
			select user_tab_cols.column_name from user_tab_cols
				left outer join BULKLOADER_FIELD_ORDER
				on user_tab_cols.column_name = BULKLOADER_FIELD_ORDER.column_name
			where user_tab_cols.table_name='BULKLOADER' 
				and 
				(
					(BULKLOADER_FIELD_ORDER.SHOW = 1 and BULKLOADER_FIELD_ORDER.department = 'All')
					or BULKLOADER_FIELD_ORDER.column_name is null
				)
			order by BULKLOADER_FIELD_ORDER.sort_order, user_tab_cols.internal_column_id
		</cfquery>
		<cfset ColNameList = valuelist(cNames.column_name)>
		<cfset ColNameList = replace(ColNameList,"COLLECTION_OBJECT_ID","","all")>
		<cfset args.stripeRows = true>
		<cfset args.selectColor = "##D9E8FB">
		<cfset args.selectmode = "edit">
		<cfset args.format="html">
		<cfset args.gridLines = "yes">
		<cfset args.title="Bulkloader">
		<cfset args.onChange = "cfc:component.Bulkloader.editRecord({cfgridaction},{cfgridrow},{cfgridchanged})">
		<cfset args.bind="cfc:component.Bulkloader.getPage({cfgridpage},{cfgridpagesize},{cfgridsortcolumn},{cfgridsortdirection},{accn},{enteredby},{colln})">
		<cfset args.name="blGrid">
		<cfset args.pageSize="25">
		<cfset args.multirowselect="no">
		<cfset args.autoWidth="no">
		<a class="px-1 h4" href="browseBulk.cfm?action=loadAll&enteredby=#enteredby#&accn=#accn#&colln=#colln#&returnAction=ajaxGrid">Mark all to load</a>
		 <span class="h4">&nbsp;~&nbsp;</span> <a class="px-1 h4" href="browseBulk.cfm?action=download&enteredby=#enteredby#&accn=#accn#&colln=#colln#">Download CSV</a>
		<cfform method="post" action="browseBulk.cfm">
			<cfinput type="hidden" name="returnAction" value="ajaxGrid">
			<cfinput type="hidden" name="action" value="saveGridUpdate">
			<cfinput type="hidden" name="enteredby" value="#enteredby#">
			<cfinput type="hidden" name="accn" value="#accn#">
			<cfinput type="hidden" name="colln" value="#colln#">
			<cfgrid attributeCollection="#args#">
				<!--- enteredby2 instead of enteredby as DataEntry.cfm overwrites enteredby --->
				<cfgridcolumn name="collection_object_id" select="no" display="yes" href="/DataEntry.cfm?action=editEnterData&pMode=edit&ImAGod=yes&enteredby2=#enteredby#&accn2=#accn#&colln2=#colln#" 
					hrefkey="collection_object_id" target="_blank" header="Key_(tempID)" textcolor="##006ee3" autoExpand="yes">
				<cfloop list="#ColNameList#" index="thisName">
					<cfgridcolumn name="#thisName#" width="135" autoExpand="no">
				</cfloop>
			</cfgrid>
		</cfform>
		
	</cfoutput>
		</div>
	</div>
</cfif>
<!-------------------------------------------------------->
<cfif action IS "nothing">
	<cfoutput>
		<cf_setDataEntryGroups>
		<cfset delimitedAdminForGroups=ListQualify(adminForUsers, "'")>
		<cfquery name="ctAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 
				accn 
			from 
				bulkloader 
			where 
				enteredby in (#preservesinglequotes(delimitedAdminForGroups)#) 
			group by 
				accn 
			order by accn
		</cfquery>
		<cfquery name="ctColln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 
				institution_acronym || ':' || collection_cde colln 
			from 
				bulkloader 
			where 
				enteredby in (#preservesinglequotes(delimitedAdminForGroups)#)		
			group by 
				institution_acronym || ':' || collection_cde 
			order by institution_acronym || ':' || collection_cde
		</cfquery>
		<div class="container-fluid container-xl">
			<div class="row mx-0">
				<div class="col-12 mt-3 pb-5 float-left">
					<h1 class="h2 px-0 mt-3 pb-2">Edit Media Browse Bulkloader</h2>
					<div class="col-12 col-md-5 px-0 pr-md-3 float-left">
						<p>Pick any or all of enteredby agent, accession, or collection to edit and approve entered or loaded data.</p>
							<ul>
								<li>
									<h2 class="h3">Edit in SQL</h2>
									<p>Allows mass updates based on existing values. Will only load 500 records at one time.   Watch your browser's loading indicator for signs of it finishing to load before trying to update data. Use "control" + "F" to find data values in table.</p>
								</li>
								<li class="mt-2">
									<h2 class="h3">Edit in AJAX grid</h2>
									<p>Opens an AJAX table. Doubleclick cells to edit.
										Saves automatically on change. Use "control" + "F" to find column headers and data values in the table.</p>
								</li>
							</ul>
					</div>
					<div class="col-12 col-md-auto px-0 float-left">
						<form name="f" method="post" action="browseBulk.cfm">
							<table class="">
								<tr>
									<td align="center">
										<input type="hidden" name="action" value="viewTable" />
										<label for="enteredby" class="data-entry-label font-weight-bold">Entered By</label>
										<select name="enteredby" multiple="multiple" size="12" id="enteredby" class="">
											<option value="#delimitedAdminForGroups#" selected="selected" class="p-1">All</option>
											<cfloop list="#adminForUsers#" index='agent_name'>
												<option value="'#agent_name#'" class="p-1">#agent_name#</option>
											</cfloop>
										</select>
									</td>
									<td align="center">
										<label for="accn" class="data-entry-label font-weight-bold">Accession</label>
										<select name="accn" multiple="multiple" size="12" id="accn" class="">
											<option value="" selected class="p-1">All</option>
											<cfloop query="ctAccn">
												<option value="'#accn#'" class="p-1">#accn#</option>
											</cfloop>
										</select>
									</td>
									<td align="center">
										<label for="colln" class="data-entry-label font-weight-bold">Collection</label>
										<select name="colln" multiple="multiple" size="12" id="colln" class="">
											<option value="" selected class="p-1">All</option>
											<cfloop query="ctColln">
												<option value="'#colln#'" class="p-1">#colln#</option>
											</cfloop>
										</select>
									</td>
								</tr>
								<tr>
									<td colspan="3">
										<input type="button" value="SQL" class="lnkBtn" onclick="f.action.value='sqlTab';f.submit();">
										<input type="button" value="AJAX grid" class="lnkBtn" onclick="f.action.value='ajaxGrid';f.submit();">
									</td>
								</tr>
							</table>
						</form>
					</div>

				</div>
			</div>
		</div>
	</cfoutput>
</cfif>
<!----------------------------------------------------------->
<cfif action is "runSQLUp">
	<cfoutput>
		<cfif not isdefined("uc1") or not isdefined("uv1") or len(uc1) is 0 or len(uv1) is 0>
			Not enough information. <cfabort>
		</cfif>
		<cfif uv1 is "NULL">
			<cfset sql = "update bulkloader set #uc1# = NULL where enteredby IN (#enteredby#)">
		<cfelse>
		<cfset sql = "update bulkloader set #uc1# = '#uv1#' where enteredby IN (#enteredby#)">
		</cfif>
		<cfif isdefined("accn") and len(accn) gt 0>
			<cfset sql = "#sql# AND accn IN (#accn#)">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset sql = "#sql# AND institution_acronym || ':' || collection_cde IN (#colln#)">
		</cfif>
		<cfif isdefined("c1") and len(c1) gt 0 and isdefined("op1") and len(op1) gt 0 and isdefined("v1") and len(v1) gt 0>
			<cfset sql = "#sql# AND #c1# #op1# ">
			<cfif op1 is "=">
				<cfset sql = "#sql# '#v1#'">
			<cfelseif op1 is "like">
				<cfset sql = "#sql# '%#v1#%'">
			<cfelseif op1 is "in">
				<cfset sql = "#sql# ('#replace(v1,",","','","all")#')">
			<cfelseif op1 is "between">
				<cfset dash = find("-",v1)>
				<cfset f = left(v1,dash-1)>
				<cfset t = mid(v1,dash+1,len(v1))>
				<cfset sql = "#sql# #f# and #t# ">
			</cfif>		 
		</cfif>
		<cfif isdefined("c2") and len(c2) gt 0 and isdefined("op2") and len(op2) gt 0 and isdefined("v2") and len(v2) gt 0>
			<cfset sql = "#sql# AND #c2# #op2# ">
			<cfif op2 is "=">
				<cfset sql = "#sql# '#v2#'">
			<cfelseif op2 is "like">
				<cfset sql = "#sql# '%#v2#%'">
			<cfelseif op2 is "in">
				<cfset sql = "#sql# ('#replace(v2,",","','","all")#')">
			<cfelseif op2 is "between">
				<cfset dash = find("-",v2)>
				<cfset f = left(v2,dash-1)>
				<cfset t = mid(v2,dash+1,len(v2))>
				<cfset sql = "#sql# #f# and #t# ">
			</cfif>		 
		</cfif>
		<cfif isdefined("c3") and len(c3) gt 0 and isdefined("op3") and len(op3) gt 0 and isdefined("v3") and len(v3) gt 0>
			<cfset sql = "#sql# AND #c3# #op3# ">
			<cfif #op3# is "=">
				<cfset sql = "#sql# '#v3#'">
			<cfelseif op3 is "like">
				<cfset sql = "#sql# '%#v3#%'">
			<cfelseif op3 is "in">
				<cfset sql = "#sql# ('#replace(v3,",","','","all")#')">
			<cfelseif op3 is "between">
				<cfset dash = find("-",v3)>
				<cfset f = left(v3,dash-1)>
				<cfset t = mid(v3,dash+1,len(v3))>
				<cfset sql = "#sql# #f# and #t# ">
			</cfif>	 
		</cfif>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			#preservesinglequotes(sql)#	
		</cfquery>
		<cfset rUrl="browseBulk.cfm?action=sqlTab&enteredby=#enteredby#">
		<cfif isdefined("accn") and len(accn) gt 0>
			<cfset rUrl="#rUrl#&accn=#accn#">
		</cfif>		
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset rUrl = "#rUrl#&colln=#colln#">
		</cfif>
		<cfif isdefined("c1") and len(c1) gt 0 and isdefined("op1") and len(op1) gt 0 and isdefined("v1") and len(v1) gt 0>
			<cfset rUrl="#rUrl#&c1=#c1#&op1=#op1#&v1=#v1#"> 
		</cfif>
		<cfif isdefined("c2") and len(c2) gt 0 and isdefined("op2") and len(op2) gt 0 and isdefined("v2") and len(v2) gt 0>
			<cfset rUrl="#rUrl#&c2=#c2#&op2=#op2#&v2=#v2#"> 
		</cfif>
		<cfif isdefined("c3") and len(c3) gt 0 and isdefined("op3") and len(op3) gt 0 and isdefined("v3") and len(v3) gt 0>
			<cfset rUrl="#rUrl#&c3=#c3#&op3=#op3#&v3=#v3#"> 
		</cfif>
		<cflocation url="#rUrl#" addtoken="false">
	</cfoutput>	
</cfif>
<!----------------------------------------------------------->
<cfif action is "sqlTab">
<cfoutput>
	<cfset sql = "select * from bulkloader where enteredby IN (#enteredby#)">
	<cfif isdefined("accn") and len(accn) gt 0>
		<cfset sql = "#sql# AND accn IN (#accn#)">
	</cfif>
	<cfif isdefined("colln") and len(colln) gt 0>
		<cfset sql = "#sql# AND institution_acronym || ':' || collection_cde IN (#colln#)">
	</cfif>
	<cfif isdefined("c1") and len(c1) gt 0 and isdefined("op1") and len(op1) gt 0 and isdefined("v1") and len(v1) gt 0>
		<cfset sql = "#sql# AND #c1# #op1# ">
		<cfif #op1# is "=">
			<cfset sql = "#sql# '#v1#'">
		<cfelseif op1 is "like">
			<cfset sql = "#sql# '%#v1#%'">
		<cfelseif op1 is "in">
			<cfset sql = "#sql# ('#replace(v1,",","','","all")#')">
		<cfelseif op1 is "between">
			<cfset dash = find("-",v1)>
			<cfset f = left(v1,dash-1)>
			<cfset t = mid(v1,dash+1,len(v1))>
			<cfset sql = "#sql# #f# and #t# ">
		</cfif>		 
	</cfif>
	<cfif isdefined("c2") and len(c2) gt 0 and isdefined("op2") and len(op2) gt 0 and isdefined("v2") and len(v2) gt 0>
		<cfset sql = "#sql# AND #c2# #op2# ">
		<cfif #op2# is "=">
			<cfset sql = "#sql# '#v2#'">
		<cfelseif op2 is "like">
			<cfset sql = "#sql# '%#v2#%'">
		<cfelseif op2 is "in">
			<cfset sql = "#sql# ('#replace(v2,",","','","all")#')">
		<cfelseif op2 is "between">
			<cfset dash = find("-",v2)>
			<cfset f = left(v2,dash-1)>
			<cfset t = mid(v2,dash+1,len(v2))>
			<cfset sql = "#sql# #f# and #t# ">
		</cfif>		 
	</cfif>
	<cfif isdefined("c3") and len(c3) gt 0 and isdefined("op3") and len(op3) gt 0 and isdefined("v3") and len(v3) gt 0>
		<cfset sql = "#sql# AND #c3# #op3# ">
		<cfif op3 is "=">
			<cfset sql = "#sql# '#v3#'">
		<cfelseif op3 is "like">
			<cfset sql = "#sql# '%#v3#%'">
		<cfelseif op3 is "in">
			<cfset sql = "#sql# ('#replace(v3,",","','","all")#')">
		<cfelseif op3 is "between">
			<cfset dash = find("-",v3)>
			<cfset f = left(v3,dash-1)>
			<cfset t = mid(v3,dash+1,len(v3))>
			<cfset sql = "#sql# #f# and #t# ">
		</cfif>		 
	</cfif>
	<cfset sql="#sql# and rownum<500">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		#preservesinglequotes(sql)#	
	</cfquery>
	<cfquery name="cNames" datasource="uam_god">
		select user_tab_cols.column_name from user_tab_cols
				left outer join BULKLOADER_FIELD_ORDER
				on user_tab_cols.column_name = BULKLOADER_FIELD_ORDER.column_name
			where user_tab_cols.table_name='BULKLOADER' 
				and 
				(
					(BULKLOADER_FIELD_ORDER.SHOW = 1 and BULKLOADER_FIELD_ORDER.department = 'All')
						or BULKLOADER_FIELD_ORDER.column_name is null
				)
			order by BULKLOADER_FIELD_ORDER.sort_order, user_tab_cols.internal_column_id
	</cfquery>
		<div class="container-fluid">
			<div class="row mx-0">
				<div class="col-12 px-0">
					<div class="col-12 mt-4 pb-2 float-left"><h1 class="h2">Filter and Update Column Values in Bulk</h1>
						<p>Use the top form to filter the table to the records of interest. All values are joined with "AND" and everything is case-sensitive. You must provide all three values (row) for the filter to apply. Then, use the bottom form to update them. Values in the update form are also case sensitive. There is no control over entries here - you can easily update such that records will never load. <span class="text-info font-weight-lessbold">Updates will affect only the records visible in the table below, and will affect ALL records in the table in the same way.</span></p>
					</div>
					<div class="col-12 col-md-4 mt-2 pb-2 float-left">
						<h2 class="h4">Operator values:</h2>
							<ul class="geol_hier">
								<li><b>&##61;</b> : single case-sensitive exact match ("something"-->"<strong>something</strong>")</li>
								<li><b>like</b> : partial string match ("somet" --> "<strong>somet</strong>hing", "got<strong>somet</strong>oo", "<strong>somet</strong>ime", etc.)</li>
								<li><b>in</b> : comma-delimited list ("one,two" --> "<strong>one</strong>" OR "<strong>two</strong>")</li>
								<li><b>between</b> : range ("1-5" --> "1,2...5") Works only when ALL values are numeric (not only those you see in the current table)</li>
							</ul>
						<p>
							NOTE: This form will load at most 500 records. 
						</p>
					</div>
					<div class="col-12 col-md-8 mt-1 pb-3 float-left">
						<form name="filter" method="post" action="browseBulk.cfm">
							<input type="hidden" name="action" value="sqlTab">
							<input type="hidden" name="enteredby" value="#enteredby#">
							<cfif isdefined("accn") and len(accn) gt 0>
								<input type="hidden" name="accn" value="#accn#">
							</cfif>
							<cfif isdefined("colln") and len(colln) gt 0>
								<input type="hidden" name="colln" value="#colln#">
							</cfif>
							<h2>Create Filter:</h2>
							<table class="table table-responsive">
								<thead class="thead-light">
								<tr>
									<th>Column</th>
									<th>Operator</th>
									<th>Value</th>
								</tr>
								</thead>
								<tbody>
									<tr>
										<td>
											<select name="c1" size="1">
												<option value=""></option>
												<cfloop query="cNames">
													<option 
														<cfif isdefined("c1") and c1 is column_name> selected="selected" </cfif>value="#column_name#">#column_name#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<select name="op1" size="1">
												<option <cfif isdefined("op1") and op1 is "="> selected="selected" </cfif>value="=">=</option>
												<option <cfif isdefined("op1") and op1 is "like"> selected="selected" </cfif>value="like">like</option>
												<option <cfif isdefined("op1") and op1 is "in"> selected="selected" </cfif>value="in">in</option>
												<option <cfif isdefined("op1") and op1 is "between"> selected="selected" </cfif>value="between">between</option>
											</select>
										</td>
										<td>
											<input type="text" name="v1" <cfif isdefined("v1")> value="#v1#"</cfif> size="50">
										</td>
									</tr>
									<tr>
										<td>
											<select name="c2" size="1">
												<option value=""></option>
												<cfloop query="cNames">
													<option 
														<cfif isdefined("c2") and #c2# is #column_name#> selected="selected" </cfif>value="#column_name#">#column_name#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<select name="op2" size="1">
												<option <cfif isdefined("op2") and op2 is "="> selected="selected" </cfif>value="=">=</option>
												<option <cfif isdefined("op2") and op2 is "like"> selected="selected" </cfif>value="like">like</option>
												<option <cfif isdefined("op2") and op2 is "in"> selected="selected" </cfif>value="in">in</option>
												<option <cfif isdefined("op2") and op2 is "between"> selected="selected" </cfif>value="between">between</option>
											</select>
										</td>
										<td>
											<input type="text" name="v2" <cfif isdefined("v2")> value="#v2#"</cfif> size="50">
										</td>
									</tr>
									<tr>
										<td>
											<select name="c3" size="1">
												<option value=""></option>
												<cfloop query="cNames">
													<option 
														<cfif isdefined("c3") and #c3# is #column_name#> selected="selected" </cfif>value="#column_name#">#column_name#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<select name="op3" size="1">
												<option <cfif isdefined("op3") and op3 is "="> selected="selected" </cfif>value="=">=</option>
												<option <cfif isdefined("op3") and op3 is "like"> selected="selected" </cfif>value="like">like</option>
												<option <cfif isdefined("op3") and op3 is "in"> selected="selected" </cfif>value="in">in</option>
												<option <cfif isdefined("op3") and op3 is "between"> selected="selected" </cfif>value="between">between</option>
											</select>
										</td>
										<td>
											<input type="text" name="v3" <cfif isdefined("v3")> value="#v3#"</cfif> size="50">
										</td>
									</tr>
									<tr>
										<td colspan="3">
											<input type="submit" value="Filter">
										</td>
									</tr>
								</tbody>
							</table>
						</form>
					</div>
					<div class="col-12 mb-3 mt-0 float-left">
						<h2>Update data in table below: </h2> 
						<h3 class="h4 font-italic text-info">To check updates: Use "control" + "F" to bring a column header or value into focus.</h3>
						<h3 class="h4 font-italic text-info">To empty a column, click "NULL" for the value and update.</h3>
						<form name="up" method="post" action="browseBulk.cfm">
							<input type="hidden" name="action" value="runSQLUp">
							<input type="hidden" name="enteredby" value="#enteredby#">
							<cfif isdefined("accn") and len(accn) gt 0>
								<input type="hidden" name="accn" value="#accn#">
							</cfif>
							<cfif isdefined("colln") and len(colln) gt 0>
								<input type="hidden" name="colln" value="#colln#">
							</cfif>
							<cfif isdefined("c1") and len(#c1#) gt 0 and isdefined("op1") and len(#op1#) gt 0 and isdefined("v1") and len(#v1#) gt 0>
								<input type="hidden" name="c1" value="#c1#">
								<input type="hidden" name="op1" value="#op1#">
								<input type="hidden" name="v1" value="#v1#">			
							</cfif>
							<cfif isdefined("c2") and len(#c2#) gt 0 and isdefined("op2") and len(#op2#) gt 0 and isdefined("v2") and len(#v2#) gt 0>
								<input type="hidden" name="c2" value="#c2#">
								<input type="hidden" name="op2" value="#op2#">
								<input type="hidden" name="v2" value="#v2#">			
							</cfif>
							<cfif isdefined("c3") and len(#c3#) gt 0 and isdefined("op3") and len(#op3#) gt 0 and isdefined("v3") and len(#v3#) gt 0>
								<input type="hidden" name="c3" value="#c3#">
								<input type="hidden" name="op3" value="#op3#">
								<input type="hidden" name="v3" value="#v3#">			
							</cfif>
							<table class="table table-responsive">
								<thead class="thead-light">
									<tr>
										<th>Column</th>
										<th>Update To</th>
										<th>Value</th>
									</tr>
								</thead>
								<tbody>
									<tr>
										<td>
											<select name="uc1" size="1">
												<option value=""></option>
												<cfloop query="cNames">
													<option value="#column_name#">#column_name#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<span style="font-size: 30px;" class="px-3">→</span>
										</td>
										<td>
											<input type="text" name="uv1" id="uv1" size="50">
											<span class="infoLink" onclick="document.getElementById('uv1').value='NULL';">NULL</span>
										</td>
									</tr>
									<tr>
										<td colspan="3">
											<input type="submit" value="Update">
										</td>
									</tr>
								</tbody>
							</table>
						</form>
						<div class="blTabDiv">
							<table class="table" id="t"> 
				<!---				   class="sortable">  Sortable class goes with table id="t" but it slows the load down so much that it isn't practical to use for more than a handful of records. It also won't work for styling to have the <tr> wrapped around the whole table without <thead> and <tbody> --->
							<!---	<tr>--->
									<thead class="thead-light">
										<tr>
											<cfloop query="cNames">
												<th class="px-2">#column_name#</th>
											</cfloop>
										</tr>
									</thead>
									<tbody>
										<cfloop query="data">
											<tr>
											<cfquery name="thisRec" dbtype="query">
												select * from data where collection_object_id=#data.collection_object_id#
											</cfquery>
											<cfloop query="cNames">
												<cfset thisData = evaluate("thisRec." & cNames.column_name)>
												<td class="px-2">#thisData#</td>
											</cfloop>
											</tr>
										</cfloop>
									</tbody>
								<!---</tr>--->
							</table>
						</div>
					</div>
				</div>
			</div>
		</div>
</cfoutput>
</cfif>
<!-------------------------->
<cfif #action# is "saveGridUpdate">
<cfoutput>
<cfquery name="cNames" datasource="uam_god">
	select column_name from user_tab_cols where table_name='BULKLOADER'
</cfquery>
<cfset ColNameList = valuelist(cNames.column_name)>
<cfset GridName = "blGrid">
<cfset numRows = #ArrayLen(form.blGrid.rowstatus.action)#>
<h3>#numRows# rows updated</h3>
<!--- loop for each record --->
<cfloop from="1" to="#numRows#" index="i">
	<!--- and for each column --->
	<cfset thisCollObjId = evaluate("Form.#GridName#.collection_object_id[#i#]")>
	<cfset sql ='update BULKLOADER SET collection_object_id = #thisCollObjId#'>
	<cfloop index="ColName" list="#ColNameList#">
		<cfset oldValue = evaluate("Form.#GridName#.original.#ColName#[#i#]")>
		<cfset newValue = evaluate("Form.#GridName#.#ColName#[#i#]")>
		<cfif #oldValue# neq #newValue#>
			<cfset sql = "#sql#, #ColName# = '#newValue#'">
		</cfif>
	</cfloop>
	
		<cfset sql ="#sql# WHERE collection_object_id = #thisCollObjId#">
	<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		#preservesinglequotes(sql)#
	</cfquery>
</cfloop>
<cflocation url="browseBulk.cfm?action=#returnAction#&enteredby=#enteredby#&accn=#accn#&colln=#colln#">
</cfoutput>
</cfif>
			

<!-------------------------------------------------------------->
<cfif #action# is "upBulk">
<cfoutput>
	<cfif len(#loaded#) gt 0 and
		len(#column_name#) gt 0 and
		len(#tValue#) gt 0>	
		<cfset sql="UPDATE bulkloader SET LOADED = ">
		<cfif #loaded# is "NULL">
			<cfset sql="#sql# NULL">
		<cfelse>
			<cfset sql="#sql# '#loaded#'">
		</cfif>
		<cfset sql="#sql# WHERE #column_name#	=
			'#trim(tValue)#' AND
			enteredby IN (#enteredby#)">
		<cfif len(accn) gt 0>
			<cfset sql = "#sql# AND accn IN (#accn#)">
		</cfif>		
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset sql = "#sql# AND institution_acronym || ':' || collection_cde IN (#colln#)">
		</cfif>
			#preservesinglequotes(sql)#
		<!---
		
		<cfabort>
		--->
		<cfquery name="upBulk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			#preservesinglequotes(sql)#
		</cfquery>
	</cfif>

<cflocation url="browseBulk.cfm?action=viewTable&enteredby=#enteredby#&accn=#accn#&colln=#colln#">
		
</cfoutput>
</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "viewTable">
<cfoutput>
<cfset sql = "select * from bulkloader
	where enteredby IN (#enteredby#)">
<cfif len(accn) gt 0>
	<!----
	<cfset thisAccnList = "">
	<cfloop list="#accn#" index="a" delimiters=",">
		<cfif len(#thisAccnList#) is 0>
			<cfset thisAccnList = "'#a#'">
		<cfelse>
			<cfset thisAccnList = "#thisAccnList#,'#a#'">
		</cfif>
	</cfloop>
	<cfset sql = "#sql# AND accn IN (#preservesinglequotes(thisAccnList)#)">
	---->
	<cfset sql = "#sql# AND accn IN (#accn#)">
	
</cfif>

	<cfif isdefined("colln") and len(colln) gt 0>
		<cfset sql = "#sql# AND institution_acronym || ':' || collection_cde IN (#colln#)">
	</cfif>
<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	#preservesinglequotes(sql)#	
</cfquery>
<cfquery name="cNames" datasource="uam_god">
	select user_tab_cols.column_name from user_tab_cols
		   left outer join BULKLOADER_FIELD_ORDER
		   on user_tab_cols.column_name = BULKLOADER_FIELD_ORDER.column_name
		where user_tab_cols.table_name='BULKLOADER' 
			  and 
			  (
				 (BULKLOADER_FIELD_ORDER.SHOW = 1 and BULKLOADER_FIELD_ORDER.department = 'All')
				 or BULKLOADER_FIELD_ORDER.column_name is null
			  )
		order by BULKLOADER_FIELD_ORDER.sort_order, user_tab_cols.internal_column_id
</cfquery>
<div class="container-fluid px-4">
<!---
<div style="background-color:##FFFFCC;">
Mark some of the records in this bulkloader batch:
<cfset columnList = "SPEC_LOCALITY,HIGHER_GEOG,ENTEREDBY,LOADED,ACCN,OTHER_ID_NUM_5">

<form name="bulkStuff" method="post" action="browseBulk.cfm">
	<input type="hidden" name="action" value="upBulk" />
	<input type="hidden" name="enteredby" value="#enteredby#" />
	<input type="hidden" name="accn" value="#accn#" />
	UPDATE bulkloader SET LOADED = 
	<select name="loaded" size="1">
		<option value="NULL">NULL</option>
		<option value="FLAGGED BY BULKLOADER EDITOR">FLAGGED BY BULKLOADER EDITOR</option>
		<option value="MARK FOR DELETION">MARK FOR DELETION</option>
	</select>
	<br />WHERE
	<select name="column_name" size="1">
		<CFLOOP list="#columnList#" index="i">
			<option value="#i#">#i#</option>
		</CFLOOP>
	</select>
	= TRIM(
	<input type="text" name="tValue" size="50" />)
	<br />
	<input type="submit" 
				value="Update All Matches"
				class="savBtn"
				onmouseover="this.className='savBtn btnhov'"
				onmouseout="this.className='savBtn'">
</form>
</div>
---->
<hr /><cfset ColNameList = valuelist(cNames.column_name)>
<cfset ColNameList = replace(ColNameList,"COLLECTION_OBJECT_ID","","all")>
<!---
<cfset ColNameList = replace(ColNameList,"LOADED","","all")>
<cfset ColNameList = replace(ColNameList,"ENTEREDBY","","all")>
--->
<hr />
	<cfform method="post" action="browseBulk.cfm">
		<cfinput type="hidden" name="action" value="saveGridUpdate">
		<cfinput type="hidden" name="enteredby" value="#enteredby#">
		<cfinput type="hidden" name="accn" value="#accn#">
		<cfinput type="hidden" name="colln" value="#colln#">
		<cfinput type="hidden" name="returnAction" value="viewTable">

		<cfgrid query="data"  name="blGrid" selectmode="edit">
			<cfgridcolumn name="collection_object_id" select="no" href="/DataEntry.cfm?action=editEnterData&ImAGod=yes&pMode=edit" hrefkey="collection_object_id" target="_blank">
			<!----
			<cfgridcolumn name="loaded" select="yes">---->
	<!---		<cfgridcolumn name="ENTEREDBY" select="yes">--->
			
			<cfloop list="#ColNameList#" index="thisName">
				<cfgridcolumn name="#thisName#">
			</cfloop>

		<cfinput type="submit" name="save" value="Save Changes In Grid">
		<a href="browseBulk.cfm?action=loadAll&enteredby=#enteredby#&accn=#accn#&colln=#colln#&returnAction=viewTable">Mark all to load</a>
		&nbsp;~&nbsp;<a href="browseBulk.cfm?action=download&enteredby=#enteredby#&accn=#accn#&colln=#colln#">Download CSV</a>
		</cfgrid>

	</cfform>
</div>
</cfoutput>
</cfif>
<cfinclude template="/shared/_footer.cfm">
