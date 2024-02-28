<cfset pageTitle="Edit Bulkloaded Data">
<cfinclude template="/shared/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>
<cfset MAX_BULK_ROWS = 450>
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
table##t th {
	cursor: pointer;
}
</style>
<!-------------------------------------------------------------->
<cfif action is "loadAll">
	<cfoutput>
		<cfset enteredByCleaned = replace(enteredby,"'","","All")>
		<cfset accnCleaned = replace(accn,"'","","All")>
		<cfset collnCleaned = replace(colln,"'","","All")>
		<cfquery name="markForLoad" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE bulkloader 
			SET LOADED = NULL 
			WHERE 
				enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
			<cfif len(accn) gt 0>
				AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
			</cfif>
			<cfif isdefined("colln") and len(colln) gt 0>
				AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
			</cfif>
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
		<cfset ColNameList = valuelist(cNames.column_name)>
		<cfset enteredByCleaned = replace(enteredby,"'","","All")>
		<cfset accnCleaned = replace(accn,"'","","All")>
		<cfset collnCleaned = replace(colln,"'","","All")>
		<cfif isDefined("showOnlyPopulated") AND showOnlyPopulated EQ "true">
			<!--- optionally, leave unpopulated columns out of download --->
			<cfloop list="#ColNameList#" index="aColumnName">
				<cfquery name="checkForData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) as ct
					FROM bulkloader
					WHERE 
						#aColumnName# is NOT NULL
						AND enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
						<cfif len(accn) gt 0>
							AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
						</cfif>
						<cfif isdefined("colln") and len(colln) gt 0>
							AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
						</cfif>
				</cfquery>
				<cfif checkForData.ct EQ 0 AND ucase(aColumnName) NEQ "LOADED">
					<cfset ColNameList = ListDeleteAt(ColNameList,ListFind(ColNameList,"#aColumnName#"))>
				</cfif>
			</cfloop>
		</cfif>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT #ColNameList# from bulkloader 
			WHERE 
				enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
				<cfif len(accn) gt 0>
					AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
				</cfif>
				<cfif isdefined("colln") and len(colln) gt 0>
					AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
				</cfif>
		</cfquery>
		<cfset variables.encoding="UTF-8">
		<cfset timestamp = "#dateformat(now(),'yyyymmdd')#_#TimeFormat(Now(),'HHnnss')#">
		<cfset fname = "BulkPendingData_#timestamp#.csv">
		<cfset variables.fileName="#Application.webDirectory#/download/#fname#">
		<cfset header=#trim(ColNameList)#>
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
			variables.joFileWriter.writeLine(header); 
		</cfscript>
		<cfloop query="data">
			<cfset oneLine = "">
			<cfloop list="#ColNameList#" index="c">
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
<cfif isDefined("action") AND action is "listUniqueProblems">
	<cfset enteredByCleaned = replace(enteredby,"'","","All")>
	<cfset accnCleaned = replace(accn,"'","","All")>
	<cfset collnCleaned = replace(colln,"'","","All")>
	<cfquery name="countData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT count(*) as ct
		FROM bulkloader
		WHERE 
			enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
		<cfif len(accn) gt 0>
			AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
		</cfif>
	</cfquery>
	<cfset crlf = chr(13) & chr(10) >
	<cfquery name="getColumnsNoUser" datasource="uam_god">
		SELECT column_name
		FROM all_tab_columns
		WHERE table_name='BULKLOADER' AND owner='MCZBASE' 
		ORDER BY column_id
	</cfquery>
	<cfset columns = "">
	<cfloop query="getColumnsNoUser">
		<cfset columns=ListAppend(columns,getColumnsNoUser.column_name)>
	</cfloop>
	<cfquery name="getLoadedValues" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT distinct loaded 
		FROM bulkloader
		WHERE 
			loaded is not null
			AND loaded <> 'BULKLOADED RECORD'
			AND loaded <> 'MARK FOR DELETION'
			AND enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
		<cfif len(accn) gt 0>
			AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
		</cfif>
		ORDER BY loaded
	</cfquery>
	<cfset loadedArray = ArrayNew(1)>
	<cfloop query="getLoadedValues">
		<cfset loadedList = getLoadedValues.loaded>
		<cfloop list="#loadedList#" index="loadedItem" delimiters=";">
			<cfif len(loadedItem) GT 0>
				<cfif NOT ArrayContains(loadedArray,loadedItem)>
					<cfset ArrayAppend(loadedArray,loadedItem)>
				</cfif>
			</cfif>
		</cfloop>
	</cfloop>
	<div class="container-fluid">
		<div class="col-12 px-0 py-4">
			<cfoutput>
				<h1 class="h2 px-1">#ArrayLen(loadedArray)# issues with #countData.ct# records.</h2>
				<cfif listLen(enteredByCleaned) EQ 1>
					<cfset entryList = "by #encodeForHtml(enteredByCleaned)#">
				<cfelseif listLen(enteredByCleaned) GT 5>
					<cfset entryList = "by any of #listLen(enteredByCleaned)# users">
				<cfelse>
					<cfset entryList = "by any of #encodeForHtml(enteredByCleaned)#">
				</cfif>
				<p class="px-1">Issues with records in the bulkloader entered #entryList#
					<cfif len(accn) gt 0>
						with accession number(s) #encodeForHtml(accn)#
					</cfif>
					<cfif isdefined("colln") and len(colln) gt 0>
						in collection(s) #encodeForHtml(colln)#
					</cfif>
				</p>
				<div>
					<a class="px-1 h4" href="browseBulk.cfm?action=sqlTab&enteredby=#enteredby#&accn=#accn#&colln=#colln#">Edit in Bulk</a>
					<span class="h4">&nbsp;~&nbsp;</span> 
					<a class="px-1 h4" href="browseBulk.cfm?action=ajaxGrid&enteredby=#enteredby#&accn=#accn#&colln=#colln#">Edit in Ajax Grid</a>
				</div>
<!---				<cfif getLoadedValues.recordcount LT 31>
						<cfset sortable = "sortable">
					<cfelse>
						<cfset sortable = "">
				</cfif>--->
				<table class="table table-bordered table-responsive-md table-striped sortable" id="t">
					<thead class="thead-light">
						<tr>
							<th>Error</th>
							<th>Column</th>
							<th>Problem Value</th>
							<th>Records</th>
							<th>Count</th>
							<th>Action</th>
						</tr>
					</thead>
					<tbody>
						<cfset baseDoBulk = "?action=sqlTab&enteredby=#enteredby#">
						<cfif isdefined("accn") and len(accn) gt 0>
							<cfset baseDoBulk = "#baseDoBulk#&accn=#accn#">
						</cfif>
						<cfif isdefined("colln") and len(colln) gt 0>
							<cfset baseDoBulk = "#baseDoBulk#&colln=#colln#">
						</cfif>
						<cfloop index="i" from="1" to="#ArrayLen(loadedArray)#">
							<cfquery name="getErrorRows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT collection_object_id
								FROM bulkloader
								WHERE 
									loaded like '%#loadedArray[i]#%'
									AND enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
									<cfif len(accn) gt 0>
										AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
									</cfif>
									<cfif isdefined("colln") and len(colln) gt 0>
										AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
									</cfif>
							</cfquery>
							<cfset rows ="">
							<cfset separator="">
							<cfif getErrorRows.recordcount LT 21>
								<cfloop query="getErrorRows">
									<cfset rows = "#rows##separator#<a href='/DataEntry.cfm?action=editEnterData&CFGRIDKEY=#getErrorRows.collection_object_id#'>#getErrorRows.collection_object_id#</a>">
									<cfset separator=", "><!--- " --->
								</cfloop>
							<cfelse>
								<cfset rows = "in #getErrorRows.recordcount# records">
							</cfif>
							<cfset errorCase = loadedArray[i]>
							<cfset columnInError = "">
							<cfif FindNoCase('geog_auth_rec matched 0 records',errorCase) GT 0>
								<cfset columnInError = "HIGHER_GEOG">
							<cfelseif FindNoCase('Taxonomy (',errorCase) GT 0>
								<cfset columnInError = "TAXON_NAME">
							<cfelse>
								<cfloop list="#columns#" index="col">
									<cfif FindNoCase(col,errorCase) GT 0>
										<cfset columnInError = col>
									</cfif>
								</cfloop>
							</cfif>
							<cfif columnInError NEQ "">
								<cfquery name="getErrorCases" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT distinct #columnInError# value_error
									FROM bulkloader
									WHERE 
										loaded like '%#errorCase#%'
										AND enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
										<cfif len(accn) gt 0>
											AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
										</cfif>
										<cfif isdefined("colln") and len(colln) gt 0>
											AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
										</cfif>
								</cfquery>
								<cfloop query="getErrorCases">
									<cfquery name="getErrorRowsForCase" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT collection_object_id
										FROM bulkloader
										WHERE 
											loaded like '%#loadedArray[i]#%'
											AND #columnInError# = '#getErrorCases.value_error#'
											AND enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
											<cfif len(accn) gt 0>
												AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
											</cfif>
											<cfif isdefined("colln") and len(colln) gt 0>
												AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
											</cfif>
									</cfquery>
									<cfset rows ="">
									<cfset separator="">
									<cfif getErrorRowsForCase.recordcount LT 21>
										<cfloop query="getErrorRowsForCase">
											<cfset rows = "#rows##separator#<a href='/DataEntry.cfm?action=editEnterData&CFGRIDKEY=#getErrorRowsForCase.collection_object_id#'>#getErrorRowsForCase.collection_object_id#</a>">
											<cfset separator=", "><!--- " --->
										</cfloop>
									<cfelse>
										<cfset rows = "in #getErrorRowsForCase.recordcount# records">
									</cfif>
									<cfset doBulk = "#baseDoBulk#&c1=#columnInError#&v1=#encodeForURL(getErrorCases.value_error)#&op1==">
									<cfset doBulk = "#doBulk#&c2=LOADED&v2=#encodeForURL(errorCase)#&op2=like">
									<tr>
										<td>#errorCase#</td>
										<td>#columnInError#</td>
										<td>#getErrorCases.value_error#</td>
										<td>#rows#</td>
										<td>#getErrorRowsForCase.recordcount#</td>
										<td><a href="/Bulkloader/browseBulk.cfm#doBulk#">Bulk Edit</a></td>
								</cfloop>
							<cfelse>
								<cfset doBulk = "#baseDoBulk#&c1=LOADED&v1=#errorCase#&op1=like">
								<tr>
									<td>#errorCase#</td>
									<td></td>
									<td></td>
									<td>#rows#</td>
									<td>#getErrorRows.recordcount#</td>
									<td><a href="/Bulkloader/browseBulk.cfm#doBulk#">Bulk Edit</a></td>
								</tr>
							</cfif>
						</cfloop>
					</tbody>
				</table>
			</cfoutput>
		</div>
	</div>
</cfif>
<cfif action is "ajaxGrid">
	<cfset enteredByCleaned = replace(enteredby,"'","","All")>
	<cfset accnCleaned = replace(accn,"'","","All")>
	<cfset collnCleaned = replace(colln,"'","","All")>
	<cfquery name="countData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT count(*) as ct
		FROM bulkloader
		WHERE 
			enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
		<cfif len(accn) gt 0>
			AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
		</cfif>
	</cfquery>
	<div class="container-fluid">
		<div class="col-12 p-4" style="min-height: 1200px;">
			<cfoutput>
				<h1 class="h2">Edit #countData.ct# records individually in this grid.</h2>
				<cfif listLen(enteredByCleaned) EQ 1>
					<cfset entryList = "by #encodeForHtml(enteredByCleaned)#">
				<cfelseif listLen(enteredByCleaned) GT 5>
					<cfset entryList = "by any of #listLen(enteredByCleaned)# users">
				<cfelse>
					<cfset entryList = "by any of #encodeForHtml(enteredByCleaned)#">
				</cfif>
				<p>Viewing records in the bulkloader entered #entryList#
				<cfif len(accn) gt 0>
					with accession number(s) #encodeForHtml(accn)#
				</cfif>
				<cfif isdefined("colln") and len(colln) gt 0>
					in collection(s) #encodeForHtml(colln)#
				</cfif>
				.</p>
				<h2 class="h4"><u>Tips for finding and editing data</u></h2>
				<ul class="pb-3">
					<li>On page load, rows are sorted by the Key Column.  The key value is not important, but it is hyperlinked to the data entry screen for the record.</li>
					<li>Clicking on a column header sorts by that column. Also, sort through option menu next to each column header (hover to see menu (sort ascending, sort descending, columns)). </li>
					<li>All columns are visible by default.  Each column menu has an option &quot;Columns&quot; button to change the columns visible in the grid. There is a delay after ticking a checkbox in the popup column selection menu, especially when there are many rows/pages in the grid.  Show Only Columns With Data/Show All Columns will let you toggle between showing all columns and leaving off all columns without data.</li>
					<li>Use your browser Find &quot;control&quot; + &quot;F&quot; function to search for column headers or data values.  Find will move the grid when it finds a data value, but only highlights a column header and does not move the grid to the column, but highlighted columns are easier to see when scrolling the grid (e.g. search for COLLECTOR_ROLE and scroll to locate the block of related columns).</li>
					<li>Click fields to edit. Click the refresh icon (bottom of grid) to see that the changes are saved. Click &quot;Mark all to load&quot; to attempt to load edited records from the bulkloader into MCZbase, records that do not succeed will have an error message in the &quot;loaded&quot; column.</li>
				</ul>
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
				<cfif isDefined("showOnlyPopulated") AND showOnlyPopulated EQ "true">
					<!--- optionally, leave unpopulated columns out of grid --->
					<cfloop list="#ColNameList#" index="aColumnName">
						<cfquery name="checkForData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT count(*) as ct
						FROM bulkloader
						WHERE 
							#aColumnName# is NOT NULL
							AND enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
							<cfif len(accn) gt 0>
								AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
							</cfif>
							<cfif isdefined("colln") and len(colln) gt 0>
								AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
							</cfif>
						</cfquery>
						<cfif checkForData.ct EQ 0 AND ucase(aColumnName) NEQ "LOADED">
							<cfset ColNameList = ListDeleteAt(ColNameList,ListFind(ColNameList,"#aColumnName#"))>
						</cfif>
					</cfloop>
				</cfif>
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
				<span class="h4">&nbsp;~&nbsp;</span> 
				<a class="px-1 h4" href="browseBulk.cfm?action=download&enteredby=#enteredby#&accn=#accn#&colln=#colln#&showOnlyPopulated=true">Download CSV (data only)</a>
				<span class="h4">&nbsp;~&nbsp;</span> 
				<a class="px-1 h4" href="browseBulk.cfm?action=download&enteredby=#enteredby#&accn=#accn#&colln=#colln#">Download CSV (all columns)</a>
				<cfif isDefined("showOnlyPopulated") AND showOnlyPopulated EQ "true">
					<span class="h4">&nbsp;~&nbsp;</span> 
					<!--- change state --->
					<a class="px-1 h4" href="browseBulk.cfm?action=ajaxGrid&enteredby=#enteredby#&accn=#accn#&colln=#colln#">Show All Columns</a>
					<span class="h4">&nbsp;~&nbsp;</span> 
					<!--- pass on the current state state --->
					<a class="px-1 h4" href="browseBulk.cfm?action=sqlTab&enteredby=#enteredby#&accn=#accn#&colln=#colln#&showOnlyPopulated=true">Edit in Bulk</a>
				<cfelse>
					<span class="h4">&nbsp;~&nbsp;</span> 
					<!--- change state --->
					<a class="px-1 h4" href="browseBulk.cfm?action=ajaxGrid&enteredby=#enteredby#&accn=#accn#&colln=#colln#&showOnlyPopulated=true">Show Only Columns with Data</a>
					<span class="h4">&nbsp;~&nbsp;</span> 
					<!--- pass on the current state state --->
					<a class="px-1 h4" href="browseBulk.cfm?action=sqlTab&enteredby=#enteredby#&accn=#accn#&colln=#colln#">Edit in Bulk</a>
				</cfif>
				<span class="h4">&nbsp;~&nbsp;</span> 
				<a class="px-1 h4" href="browseBulk.cfm?action=listUniqueProblems&enteredby=#enteredby#&accn=#accn#&colln=#colln#">List Problems</a>
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
							<cfif ucase(left(thisName,15) EQ 'COLLECTOR_ROLE_')> 
								<cfgridcolumn name="#thisName#" values=",c,p" width="135" autoExpand="no">
							<cfelse>
								<cfgridcolumn name="#thisName#" width="135" autoExpand="no">
							</cfif>
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
		<cfquery name="userList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 
				cf_users.username, 
				count(bulkloader.collection_object_id) as ct
			from 
				cf_users left join bulkloader on cf_users.username = bulkloader.enteredby
			where 
				cf_users.username in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#adminForUsers#" list="yes">) 
			group by 
				cf_users.username
			order by cf_users.username
		</cfquery>
		<cfquery name="ctAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 
				accn, 
				count(collection_object_id) as ct 
			from 
				bulkloader 
			where 
				enteredby in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#adminForUsers#" list="yes">)
			group by 
				accn 
			order by accn
		</cfquery>
		<cfquery name="ctColln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 
				institution_acronym || ':' || collection_cde colln, 
				count(collection_object_id) ct
			from 
				bulkloader 
			where 
				enteredby in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#adminForUsers#" list="yes">)		
			group by 
				institution_acronym || ':' || collection_cde 
			order by institution_acronym || ':' || collection_cde
		</cfquery>
		<div class="container-fluid container-xl">
			<div class="row mx-0">
				<div class="col-12 mt-3 pb-5 float-left">
					<h1 class="h2 px-0 mt-3 pb-2">Browse Bulkloader</h2>
					<div class="col-12 col-md-5 px-0 pr-md-3 float-left">
						<p>Pick any or all of enteredby agent, accession, or collection to edit and approve entered or loaded data.</p>
							<ul>
								<li>
									<h2 class="h3">Edit in Bulk</h2>
									<p>
										Allows mass updates to multiple records at once. Shows data in a table.  Will load a maximum of #MAX_BULK_ROWS# records.   
										Watch your browser&apos;s loading indicator for signs of it finishing to load before trying to update data. 
										Use Find ("control" + "F") to find column headers and data values in the table.  
									</p>
								</li>
								<li class="mt-2">
									<h2 class="h3">Edit in AJAX grid</h2>
									<p>
										Shows data in an editable table. Click on cells to edit individually.
										Saves automatically on change. Use Browser&apos;s  Use Find "control" + "F" to find data values or column headers in the table.
									</p>
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
											<cfloop query="#userList#">
												<option value="'#username#'" class="p-1">#username# (#ct#)</option>
											</cfloop>
										</select>
									</td>
									<td align="center">
										<label for="accn" class="data-entry-label font-weight-bold">Accession</label>
										<select name="accn" multiple="multiple" size="12" id="accn" class="">
											<option value="" selected class="p-1">All</option>
											<cfloop query="ctAccn">
												<option value="'#accn#'" class="p-1">#accn# (#ct#)</option>
											</cfloop>
										</select>
									</td>
									<td align="center">
										<label for="colln" class="data-entry-label font-weight-bold">Collection</label>
										<select name="colln" multiple="multiple" size="12" id="colln" class="">
											<option value="" selected class="p-1">All</option>
											<cfloop query="ctColln">
												<option value="'#colln#'" class="p-1">#colln# (#ct#)</option>
											</cfloop>
										</select>
									</td>
								</tr>
								<tr>
									<td colspan="3">
										<input type="button" value="Edit in Bulk" class="lnkBtn" onclick="f.action.value='sqlTab';f.submit();">
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
		<cfif isdefined("showOnlyPopulated") and len(showOnlyPopulated) gt 0>
			<cfset rUrl="#rUrl#&showOnlyPopulated=#showOnlyPopulated#"> 
		</cfif>
		<cflocation url="#rUrl#" addtoken="false">
	</cfoutput>	
</cfif>
<!----------------------------------------------------------->
<cfif action is "sqlTab">
	<cfoutput>
		<cfif NOT isdefined("accn")>
			<cfset accn = "">
		</cfif>
		<cfif NOT isdefined("colln")>
			<cfset colln = "">
		</cfif>
		<cfset enteredByCleaned = replace(enteredby,"'","","All")>
		<cfset accnCleaned = replace(accn,"'","","All")>
		<cfset collnCleaned = replace(colln,"'","","All")>
		<cfquery name="countData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT count(*) as ct
			FROM bulkloader
			WHERE 
				enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
			<cfif len(accn) gt 0>
				AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
			</cfif>
			<cfif isdefined("colln") and len(colln) gt 0>
				AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
			</cfif>
		</cfquery>
		<cfset hasFilter = false>
		<cfset sql = "select * from bulkloader where enteredby IN (#enteredby#)">
		<cfif isdefined("accn") and len(accn) gt 0>
			<cfset sql = "#sql# AND accn IN (#accn#)">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset sql = "#sql# AND institution_acronym || ':' || collection_cde IN (#colln#)">
		</cfif>
		<cfif isdefined("c1") and len(c1) gt 0 and isdefined("op1") and len(op1) gt 0 and isdefined("v1") and len(v1) gt 0>
			<cfset hasFilter = true>
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
			<cfset hasFilter = true>
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
			<cfset hasFilter = true>
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
		<cfset sql="#sql# and rownum<=#MAX_BULK_ROWS#">
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
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
		<cfset sortableLimit = 50>
		<cfif isDefined("showOnlyPopulated") AND showOnlyPopulated EQ "true">
			<cfset sortableLimit = MAX_BULK_ROWS>
		</cfif>
		<div class="container-fluid">
			<div class="row mx-0">
				<div class="col-12 px-0">
					<div class="col-12 mt-4 pb-2 float-left">
						<h1 class="h2">Update column values for multiple (#data.recordcount#) records at once.</h1>
						<p>
							Use the top form to filter the table to the records of interest. All values are joined with "AND" and everything is case-sensitive. You must provide all three values (row) for the filter to apply. Then, use the bottom form to update them. Values in the update form are also case sensitive. There is no control over entries here - you can easily update such that records will never load. <span class="bg-dark px-1 text-white font-weight-lessbold">Updates will affect only the records visible in the table below, and will affect ALL records in the table in the same way.</span>
						</p>
						<cfif listLen(enteredByCleaned) EQ 1>
							<cfset entryList = "by #encodeForHtml(enteredByCleaned)#">
						<cfelseif listLen(enteredByCleaned) GT 5>
							<cfset entryList = "by any of #listLen(enteredByCleaned)# users">
						<cfelse>
							<cfset entryList = "by any of #encodeForHtml(enteredByCleaned)#">
						</cfif>
						<h2 class="h3">
							Starting with #countData.ct# records in the bulkloader entered #entryList#
							<cfif len(accn) gt 0>
								with accession number(s) #encodeForHtml(accn)#
							</cfif>
							<cfif isdefined("colln") and len(colln) gt 0>
								in collection(s) #encodeForHtml(colln)#
							</cfif>
							<cfif countData.ct GT MAX_BULK_ROWS>
						 		(limited to #MAX_BULK_ROWS# records)
							</cfif>.
						</h2>
						<h4>
							<cfif isDefined("showOnlyPopulated") AND showOnlyPopulated EQ "true">
								<cfset showPop = "&showOnlyPopulated=true">
								<cfset showPopLabel = "(data only)">
								<cfset showToggleLabel = "all columns">
							<cfelse>
								<cfset showPop = "">
								<cfset showPopLabel = "(all columns)">
								<cfset showToggleLabel = "data only">
							</cfif>
							<a class="px-1 h4" href="browseBulk.cfm?action=download&enteredby=#enteredby#&accn=#accn#&colln=#colln#&showOnlyPopulated=true">Download CSV (data only)</a>
							<span class="h4">&nbsp;~&nbsp;</span> 
							<a class="px-1 h4" href="browseBulk.cfm?action=download&enteredby=#enteredby#&accn=#accn#&colln=#colln#">Download CSV (all columns)</a>
							<span class="h4">&nbsp;~&nbsp;</span> 
							<span class="px-1 h4">(See filter for #showToggleLabel#)</span>
							<span class="h4">&nbsp;~&nbsp;</span> 
							<!--- pass on current state (change state is from filer form) --->
							<a class="px-1 h4" href="browseBulk.cfm?action=ajaxGrid&enteredby=#enteredby#&accn=#accn#&colln=#colln##showPop#">Edit in Ajax Grid</a>
							<span class="h4">&nbsp;~&nbsp;</span> 
							<a class="px-1 h4" href="browseBulk.cfm?action=listUniqueProblems&enteredby=#enteredby#&accn=#accn#&colln=#colln#">List Problems</a>
						</h4>
					</div>

					<div class="col-12 mt-1 pb-0 float-left">
						<form name="filter" method="post" action="browseBulk.cfm"  class="col-auto float-left px-0">
							<input type="hidden" name="action" value="sqlTab">
							<input type="hidden" name="enteredby" value="#enteredby#">
							<cfif isdefined("accn") and len(accn) gt 0>
								<input type="hidden" name="accn" value="#accn#">
							</cfif>
							<cfif isdefined("colln") and len(colln) gt 0>
								<input type="hidden" name="colln" value="#colln#">
							</cfif>
							<h2 class="h3">
								<cfif hasFilter>
									Filtered to #data.recordcount# records with filter:
								<cfelse>
									Optionally Filter these records with filter:
								</cfif>
							</h2>
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
										<td>
											Show Columns:
										</td>
										<td colspan="3">
											<select name="showOnlyPopulated" id="showOnlyPopulated">
												<cfif isDefined("showOnlyPopulated") and showOnlyPopulated EQ "true">
													<cfset selectedAll = "">
													<cfset selectedOnly = "selected">
												<cfelse>
													<cfset selectedAll = "selected">
													<cfset selectedOnly = "">
												</cfif>
												<option value="" #selectedAll#>All</option>
												<option value="true" #selectedOnly#>Only columns with data</option>
											</select>
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
						<div class="col-12 col-xl-6 mt-2 mt-xl-5 px-3 float-left mb-1">
							<h2 class="h4">Operator values:</h2>
								<ul class="geol_hier">
									<li><b>&##61;</b> : single case-sensitive exact match ("something"-->"<strong>something</strong>")</li>
									<li><b>like</b> : partial string match ("somet" --> "<strong>somet</strong>hing", "got<strong>somet</strong>oo", "<strong>somet</strong>ime", etc.)</li>
									<li><b>in</b> : comma-delimited list ("one,two" --> "<strong>one</strong>" OR "<strong>two</strong>")</li>
									<li><b>between</b> : range ("1-5" --> "1,2...5") Works only when ALL values are numeric (not only those you see in the current table)</li>
								</ul>
							<p>
								NOTE: This form will load at most #MAX_BULK_ROWS# records. In mobile view, swipe to see the whole table.  #sortableLimit# rows or fewer will be sortable.
							</p>
						</div>
					</div>

					<div class="col-12 mb-2 mt-1 pb-0 float-left">
						<h2 class="h3">Update data in table below (#data.recordcount# rows): </h2> 
						<form name="up" method="post" action="browseBulk.cfm" class="col-auto float-left px-0">
							<input type="hidden" name="action" value="runSQLUp">
							<input type="hidden" name="enteredby" value="#enteredby#">
							<cfif isDefined("showOnlyPopulated")>
								<input type="hidden" name="showOnlyPopulated" value="#showOnlyPopulated#">
							</cfif>
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
											<input type="submit" value="Update all #data.recordcount# rows"> 
										</td>
									</tr>
								</tbody>
							</table>
						</form>
						<p class="font-italic text-dark mb-3 mb-xl-1 col-12 col-xl-6 px-3 float-left">
						Select a column to update, then enter a new value to be applied to all records shown below.
						To empty a column, select the column, click "NULL" for the value, and then update. To sort, click on a column header and wait. The length of delay is proportional to the number of rows in the table.	Use your browser Find functionality ("control" + "F") to locate a column header or value.</p>
					</div>
					<cfset ColNameList = valuelist(cNames.column_name)>
					<cfif isDefined("showOnlyPopulated") AND showOnlyPopulated EQ "true">
						<!--- optionally, leave unpopulated columns out of table --->
						<cfloop query="cNames">
							<cfset aColumnName=cNames.column_name>
							<cfquery name="checkForData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT count(*) as ct
							FROM bulkloader
							WHERE 
								#aColumnName# is NOT NULL
								AND enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
								<cfif len(accn) gt 0>
									AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
								</cfif>
								<cfif isdefined("colln") and len(colln) gt 0>
									AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
								</cfif>
							</cfquery>
							<cfif checkForData.ct EQ 0 AND ucase(aColumnName) NEQ "LOADED">
								<cfset ColNameList = ListDeleteAt(ColNameList,ListFind(ColNameList,"#aColumnName#"))>
							</cfif>
						</cfloop>
					</cfif>

					<div class="col-12 mb-3 mt-0 float-left">
						<div class="scrollWrapperTop">
							<div class="topScrollBar">
								<!--- top scroll bar --->
								&nbsp;
							</div>
						</div>
						
						<div class="blTabDiv scrollWrapper">
							<!--- Sortable is slow to rewrite the th cells and isn't practical to use for more than a handful of records when all columns are included. --->
							<cfif data.recordcount LT sortableLimit + 1>
								<cfset sortable = "sortable">
							<cfelse>
								<cfset sortable = "">
							</cfif>
							
							<table class="table mb-0 #sortable# scrollContent" id="t">  
									<thead class="thead-light">
										<tr>
											<cfloop query="cNames">
												<cfif ListFindNoCase(ColNameList,cNames.column_name)>
													<th class="px-2">#column_name#</th>
												</cfif>
											</cfloop>
										</tr>
									</thead>
									<tbody>
										<cfloop query="data">
											<cfset thisRow = QueryGetRow(data,data.currentRow)>
											<tr>
												<cfloop list="#ColNameList#" index="currentColumn">
													<cfset thisData = "">
													<cftry>
														<cfset thisData = StructFind(thisRow,currentColumn)>
													<cfcatch>
														<!--- if column has no value in row StructFind throws an exception --->
													</cfcatch>
													</cftry>
													<cfif currentColumn EQ "COLLECTION_OBJECT_ID">
														<td class="px-2"><a href="/DataEntry.cfm?action=editEnterData&CFGRIDKEY=#thisData#">#thisData#</a></td>
													<cfelse>
													<td class="px-2">#thisData#</td>
													</cfif>
												</cfloop>
											</tr>
										</cfloop>
									</tbody>
							</table>
							<script>
								$(window).on("load",function () {
        							$('.topScrollBar').css('width', $('.scrollContent').outerWidth() );
    							});
								$(document).ready(function(){
									$(".scrollWrapperTop").scroll(function(){
										$(".scrollWrapper")
											.scrollLeft($(".scrollWrapperTop").scrollLeft());
									});
									$(".scrollWrapper").scroll(function(){
										$(".scrollWrapperTop")
											.scrollLeft($(".scrollWrapper").scrollLeft());
									});
									$(".scrollWrapperTop").one("scroll",function(){
        								$('.topScrollBar').css('width', $('.scrollContent').outerWidth() );
									});
									$(".scrollWrapper").one("scroll",function(){
        								$('.topScrollBar').css('width', $('.scrollContent').outerWidth() );
									});
								});
							</script>
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
<!--- unused action? --->
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
<!--- unused action? --->
<cfif #action# is "viewTable">
	<cfoutput>
		<!--- strip off quotes from lists --->
		<cfset enteredByCleaned = replace(enteredby,"'","","All")>
		<cfset accnCleaned = replace(accn,"'","","All")>
		<cfset collnCleaned = replace(colln,"'","","All")>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT * 
			FROM bulkloader
			WHERE 
				enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
			<cfif len(accn) gt 0>
				AND accn IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnCleaned#" list="yes">)
			</cfif>
			<cfif isdefined("colln") and len(colln) gt 0>
				AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collnCleaned#" list="yes">)
			</cfif>
		</cfquery>
		<cfquery name="cNames" datasource="uam_god">
			SELECT user_tab_cols.column_name 
			FROM user_tab_cols
		   	left outer join BULKLOADER_FIELD_ORDER on user_tab_cols.column_name = BULKLOADER_FIELD_ORDER.column_name
			WHERE user_tab_cols.table_name='BULKLOADER' 
			  and 
			  (
				 (BULKLOADER_FIELD_ORDER.SHOW = 1 and BULKLOADER_FIELD_ORDER.department = 'All')
				 or BULKLOADER_FIELD_ORDER.column_name is null
			  )
			ORDER BY BULKLOADER_FIELD_ORDER.sort_order, user_tab_cols.internal_column_id
		</cfquery>
		<div class="container-fluid px-4">
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
				<div style="background-color:##FFFFCC;">
					<h2 class="h3">Mark some of the records in this bulkloader batch:</h2>
					<cfset columnList = "SPEC_LOCALITY,HIGHER_GEOG,ENTEREDBY,LOADED,ACCN,OTHER_ID_NUM_5">
					<form name="bulkStuff" method="post" action="browseBulk.cfm">
						<input type="hidden" name="action" value="upBulk" />
						<input type="hidden" name="enteredby" value="#enteredby#" />
						<input type="hidden" name="accn" value="#accn#" />
						UPDATE bulkloader SET LOADED = 
						<select name="loaded" size="1">
							<option value="NULL">To Load</option>
							<option value="FLAGGED BY BULKLOADER EDITOR">FLAGGED BY BULKLOADER EDITOR</option>
							<option value="MARK FOR DELETION">MARK FOR DELETION</option>
						</select>
						<br />WHERE
						<select name="column_name" size="1">
							<CFLOOP list="#columnList#" index="i">
								<option value="#i#">#i#</option>
							</CFLOOP>
						</select>
						= TRIM(<input type="text" name="tValue" size="50" />)
						<br />
						<input type="submit" 
								value="Update All Matches"
								class="savBtn"
								onmouseover="this.className='savBtn btnhov'"
								onmouseout="this.className='savBtn'">
					</form>
				</div>
			</cfif>
			<hr />
			<cfset ColNameList = valuelist(cNames.column_name)>
			<cfset ColNameList = replace(ColNameList,"COLLECTION_OBJECT_ID","","all")>
			<!---
				<cfset ColNameList = replace(ColNameList,"LOADED","","all")>
				<cfset ColNameList = replace(ColNameList,"ENTEREDBY","","all")>
			--->
			<hr />
			<h2 class="h3">Edit #data.recordcount# records individually in this grid.</h2>
			<cfform method="post" action="browseBulk.cfm">
				<cfinput type="hidden" name="action" value="saveGridUpdate">
				<cfinput type="hidden" name="enteredby" value="#enteredby#">
				<cfinput type="hidden" name="accn" value="#accn#">
				<cfinput type="hidden" name="colln" value="#colln#">
				<cfinput type="hidden" name="returnAction" value="viewTable">

				<cfgrid query="data"  name="blGrid" selectmode="edit">
					<cfgridcolumn name="collection_object_id" select="no" href="/DataEntry.cfm?action=editEnterData&ImAGod=yes&pMode=edit" hrefkey="collection_object_id" target="_blank">
					<cfloop list="#ColNameList#" index="thisName">
						<cfif ucase(left(thisName,15) EQ 'COLLECTOR_ROLE_')> 
							<cfgridcolumn name="#thisName#" values=",c,p">
						<cfelse>
							<cfgridcolumn name="#thisName#">
						</cfif>
					</cfloop>

					<cfinput type="submit" name="save" value="Save Changes In Grid">
					<cfif isDefined("showOnlyPopulated") AND showOnlyPopulated EQ "true">
						<cfset showPop = "&showOnlyPopulated=true">
						<cfset showPopLabel = "(data only)">
					<cfelse>
						<cfset showPop = "">
						<cfset showPopLabel = "(all columns)">
					</cfif>
					<a href="browseBulk.cfm?action=loadAll&enteredby=#enteredby#&accn=#accn#&colln=#colln#&returnAction=viewTable">Mark all to load</a>
					&nbsp;~&nbsp;<a href="browseBulk.cfm?action=download&enteredby=#enteredby#&accn=#accn#&colln=#colln##showPop#">Download CSV #showPopLabel#</a>
				</cfgrid>
			</cfform>
		</div>
	</cfoutput>
</cfif>
<cfinclude template="/shared/_footer.cfm">
