<cfset pageTitle="Build Bulkloadersheet">
<cfinclude template="/shared/_header.cfm">
<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
	<cfif not isdefined("content_url")>
	<cfset content_url="">
</cfif>
<cfif action is "nothing">
	<cfquery name="blt" datasource="uam_god">
		SELECT all_tab_columns.column_name, comments
		FROM all_tab_columns
			left join all_col_comments 
				on all_tab_columns.table_name = all_col_comments.table_name
				and all_tab_columns.column_name = all_col_comments.column_name
				and all_col_comments.owner = 'MCZBASE'
		WHERE all_tab_columns.table_name='BULKLOADER_STAGE' AND all_tab_columns.owner='MCZBASE'
			and all_tab_columns.column_name <> 'STAGING_USER'
		ORDER BY column_id
	</cfquery>
	<cfoutput>
		<cfset everything=valuelist(blt.column_name)>
		<cfset inListItems="">
		<cfset required="COLLECTION_OBJECT_ID,ENTEREDBY,ACCN,CAT_NUM,TAXON_NAME,NATURE_OF_ID,ID_MADE_BY_AGENT,MADE_DATE,VERBATIM_DATE,BEGAN_DATE,ENDED_DATE,HIGHER_GEOG,SPEC_LOCALITY,VERBATIM_LOCALITY,COLLECTION_CDE,INSTITUTION_ACRONYM,COLLECTOR_AGENT_1,COLLECTOR_ROLE_1,PART_NAME_1,PRESERV_METHOD_1,PART_CONDITION_1,PART_LOT_COUNT_1,PART_DISPOSITION_1,COLLECTING_METHOD,COLLECTING_SOURCE">
		<cfset inListItems=listappend(inListItems,required)>
		<cfset basicCoords="ORIG_LAT_LONG_UNITS, DATUM,LAT_LONG_REF_SOURCE,MAX_ERROR_DISTANCE,MAX_ERROR_UNITS,GEOREFMETHOD,DETERMINED_BY_AGENT,DETERMINED_DATE,LAT_LONG_REMARKS,VERIFICATIONSTATUS,GPSACCURACY,EXTENT,DATUM">
		<cfset inListItems=listappend(inListItems,basicCoords)>
		<cfset dms="LATDEG,LATMIN,LATSEC,LATDIR,LONGDEG,LONGMIN,LONGSEC,LONGDIR">
		<cfset inListItems=listappend(inListItems,dms)>
		<cfset ddm="LATDEG,DEC_LAT_MIN,LATDIR,LONGDEG,DEC_LONG_MIN,LONGDIR">
		<cfset inListItems=listappend(inListItems,ddm)>
		<cfset dd="DEC_LAT,DEC_LONG">
		<cfset inListItems=listappend(inListItems,dd)>
		<cfset utm="UTM_ZONE,UTM_EW,UTM_NS">
		<cfset inListItems=listappend(inListItems,utm)>
		<cfset geological="">
		<cfset n=5>
		<cfset oid="CAT_NUM">
		<cfloop from="1" to="#n#" index="i">
			<cfset oid=listappend(oid,"OTHER_ID_NUM_" & i)>
			<cfset oid=listappend(oid,"OTHER_ID_NUM_TYPE_" & i)>
		</cfloop>
		<cfset inListItems=listappend(inListItems,oid)>
		<cfset n=8>
		<cfset coll="">
		<cfloop from="1" to="#n#" index="i">
			<cfset coll=listappend(coll,"COLLECTOR_AGENT_" & i)>
			<cfset coll=listappend(coll,"COLLECTOR_ROLE_" & i)>
		</cfloop>
		<cfset inListItems=listappend(inListItems,coll)>
		<cfset n=12>
		<cfset part="">
		<cfloop from="1" to="#n#" index="i">
			<cfset part=listappend(part,"PART_NAME_" & i)>
			<cfset part=listappend(part,"PART_CONDITION_" & i)>
			<cfset part=listappend(part,"PART_CONTAINER_UNIQUE_ID_" & i)>
			<cfset part=listappend(part,"PART_CONTAINER_NAME_" & i)>
			<cfset part=listappend(part,"PART_LOT_COUNT_" & i)>
			<cfset part=listappend(part,"PART_DISPOSITION_" & i)>
			<cfset part=listappend(part,"PART_REMARK_" & i)>
		</cfloop>
		<cfset inListItems=listappend(inListItems,part)>
		<cfset n=10>
		<cfset attr="">
		<cfloop from="1" to="#n#" index="i">
			<cfset attr=listappend(attr,"ATTRIBUTE_" & i)>
			<cfset attr=listappend(attr,"ATTRIBUTE_VALUE_" & i)>
			<cfset attr=listappend(attr,"ATTRIBUTE_UNITS_" & i)>
			<cfset attr=listappend(attr,"ATTRIBUTE_REMARKS_" & i)>
			<cfset attr=listappend(attr,"ATTRIBUTE_DATE_" & i)>
			<cfset attr=listappend(attr,"ATTRIBUTE_DET_METH_" & i)>
			<cfset attr=listappend(attr,"ATTRIBUTE_DETERMINER_" & i)>
		</cfloop>
		<cfset inListItems=listappend(inListItems,attr)>
		<cfset n=6>
		<cfset geol="">
		<cfloop from="1" to="#n#" index="i">
			<cfset geol=listappend(geol,"GEOLOGY_ATTRIBUTE_" & i)>
			<cfset geol=listappend(geol,"GEO_ATT_VALUE_" & i)>
			<cfset geol=listappend(geol,"GEO_ATT_DETERMINER_" & i)>
			<cfset geol=listappend(geol,"GEO_ATT_DETERMINED_DATE_" & i)>
			<cfset geol=listappend(geol,"GEO_ATT_DETERMINED_METHOD_" & i)>
			<cfset geol=listappend(geol,"GEO_ATT_REMARK_" & i)>
		</cfloop>
		<cfset inListItems=listappend(inListItems,geol)>
		<cfset leftovers=everything>
		<cfloop list="#inListItems#" index="thisElement">
			<cfset lPos=listfind(leftovers,thisElement)>
			<cfif lPos gt 0>
				<cfset leftovers=listdeleteat(leftovers,lPos)>
			</cfif>
		</cfloop>
		<div class="container">
			<div class="row">
				<div class="col-12 pt-4 col-md-4 float-left">
					<h1 class="h2">Specimen Bulkload Builder</h2>
					<p>
						Build your own Specimen Bulkloader template and download it in a tab-delimited text or csv format.
						You may toggle groups on and off below or click on individual items on the right. Scroll down to review everything checked before clicking download.
					</p>
				<form name="controls" id="controls">
					<table class="table">
						<thead class="thead-light">
						<tr>
							<th>Group</th>
							<th>
								<span class="btn-xs btn btn-primary float-left"  onclick="checkAll(1)">All On</span>
								<span class="btn-xs btn btn-secondary float-left" onclick="checkAll(0)">All Off</span>
							</th>
						</tr>
						</thead>
						<tbody>
						<tr>
							<td>Required</td>
							<td><input type="checkbox" name="required" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>Coordinate Meta</td>
							<td><input type="checkbox" name="basicCoords" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>DMS Coordinates</td>
							<td><input type="checkbox" name="dms" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>DM.m Coordinates</td>
							<td><input type="checkbox" name="ddm" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>D.d Coordinates</td>
							<td><input type="checkbox" name="dd" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>UTM Coordinates</td>
							<td><input type="checkbox" name="utm" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>Identifiers</td>
							<td><input type="checkbox" name="oid" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>Agents</td>
							<td><input type="checkbox" name="coll" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>Parts</td>
							<td><input type="checkbox" name="part" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>Attributes</td>
							<td><input type="checkbox" name="attr" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>Geology</td>
							<td><input type="checkbox" name="geol" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						<tr>
							<td>The Rest</td>
							<td><input type="checkbox" name="leftovers" onchange="checkList(this.name, this.checked)"></td>
						</tr>
						</tbody>
					</table>
					</form>
					<script>
						var l_everything='#everything#';
						var l_required='#required#';
						var l_basicCoords='#basicCoords#';
						var l_dms='#dms#';
						var l_ddm='#ddm#';
						var l_dd='#dd#';
						var l_utm='#utm#';
						var l_oid='#oid#';
						var l_coll='#coll#';
						var l_part='#part#';
						var l_attr='#attr#';
						var l_geol='#geol#';
						var l_leftovers='#leftovers#';
	
						function checkAll(v){
							var radios = document.getElementById ('controls');
							if (radios) {
								var inputs = radios.getElementsByTagName ('input');
									if (inputs) {
										for (var i = 0; i < inputs.length; ++i) {
											inputs[i].checked = inputs[i].value == v;
											//console.log('checkAll: ' + inputs[i].name + ' ' + v);
											checkList2(inputs[i].name,v);
										}
									}
							}
						}
						function checkList(list, v) {
							//console.log('i am checklist');
							var theList=eval('l_' + list);
							var a = theList.split(',');
							for (i=0; i<a.length; ++i) {
								//console.log('i: ' + i);
								//alert(eid);
								if (document.getElementById(a[i])) {
									//alert(eid);
									if (v=='1'){
										document.getElementById(a[i]).checked=true;
									} else {
										document.getElementById(a[i]).checked=false;
									}
								}
							}
							var cStr=eval('document.controls.' + list);
	
							if (v=='1'){
								cStr.checked=true;
							} else {
								cStr.checked=false;
							}
	
							if (list=='ddm' || list=='dms' || list=='dd' || list=='utm'){
								if (v=='1'){
									checkList('basicCoords',v);
									}
								else {
									if(document.controls.ddm.checked==false && document.controls.dms.checked==false && document.controls.dd.checked==false && document.controls.utm.checked==false )
										{checkList('basicCoords',v);}
									}
	
								}
							if (list=='basicCoords'){
								if(document.controls.ddm.checked==true || document.controls.dms.checked==true || document.controls.dd.checked==true || document.controls.utm.checked==true )
										{checkList('basicCoords',1);}
								}
	
						}
	
						function checkList2(list, v) {
							//console.log('i am checklist');
							var theList=eval('l_' + list);
							var a = theList.split(',');
							for (i=0; i<a.length; ++i) {
								//console.log('i: ' + i);
								//alert(eid);
								if (document.getElementById(a[i])) {
									//alert(eid);
									if (v=='1'){
										document.getElementById(a[i]).checked=true;
									} else {
										document.getElementById(a[i]).checked=false;
									}
								}
							}
							var cStr=eval('document.controls.' + list);
	
							if (v=='1'){
								cStr.checked=true;
							} else {
								cStr.checked=false;
							}
						}
					</script>
				</div>
		
				<div class="col-12 col-md-8 pt-4 mt-0 mt-md-5 float-left">
					<form name="f" method="post" action="bulkloaderBuilder.cfm">
						<input type="hidden" name="action" value="getTemplate">
						<div class="border form-row mx-0 p-3">
							<div class="col-12 col-md-4">
								<label for="fileFormat" class="data-entry-label">Format:</label>
								<select name="fileFormat" id="fileFormat" class="data-entry-select">
									<option value="txt">Tab-delimited text</option>
									<option value="csv" selected>CSV</option>
								</select>
							</div>
							<div class="col-12 col-md-4">
								<label for="guidance" class="data-entry-label">Include Guidance:</label>
								<select name="guidance" id="guidance" class="data-entry-select float-left">
									<option value="yes" selected>Yes, second line.</option>
									<option value="no">No, just headers</option>
								</select>
							</div>
							<div class="col-12 col-md-4">
								<label for="submitButton" class="data-entry-label">&nbsp;</label>
								<input type="submit" id="submitButton" value="Download Template" class="btn-xs btn-primary float-left">
							</div>
						</div>
						<table class="table">
							<thead class="thead-light">
								<tr>
									<th>Individual Fields</th>
									<th>Include?</th>
									<th>Guidance for Use</th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="blt">
									<tr>
										<td>#column_name#</td>
										<td><input type="checkbox" name="fld" id="#column_name#" value="#column_name#"></td>
										<td>#comments#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</form>
					<script>
						checkAll(0);
						checkList('required',1);
					</script>
				</div>
			</div>
		</div>
	</cfoutput>
</cfif>
<cfif action is 'getTemplate'>
<cfoutput>
	<cfquery name="lookupColumns" datasource="uam_god" result="lookupColumns_result">
		SELECT all_tab_columns.column_name, comments
		FROM all_tab_columns
			left join all_col_comments 
				on all_tab_columns.table_name = all_col_comments.table_name
				and all_tab_columns.column_name = all_col_comments.column_name
				and all_col_comments.owner = 'MCZBASE'
		WHERE all_tab_columns.table_name='BULKLOADER_STAGE' AND all_tab_columns.owner='MCZBASE'
			and all_tab_columns.column_name <> 'STAGING_USER'
		ORDER BY column_id
	</cfquery>
	<cfset separator="">
	<cfset separatorTab="">
	<cfset headerLine="">
	<cfset headerLineTab="">
	<cfset guidanceLine="">
	<cfset guidanceLineTab="">
	<cfloop query="lookupColumns">
		<cfif ListContains(fld,lookupColumns.column_name) GT 0>
			<cfset headerLine = '#headerLine##separator#"#lookupColumns.column_name#"'>
			<cfset headerLineTab = '#headerLineTab##separatorTab##lookupColumns.column_name#'>
			<cfset quotesEscaped = replace(lookupColumns.comments,'"','""',"all")>
			<cfset guidanceLine = '#guidanceLine##separator#"#quotesEscaped#"'>
			<cfset quotesRemoved = replace(lookupColumns.comments,'"','',"all")>
			<cfset quotesRemoved = replace(quotesRemoved,'#chr(9)#','',"all")>
			<cfset guidanceLineTab = '#guidanceLineTab##separatorTab##trim(quotesRemoved)#'>
			<cfset separator=",">
			<cfset separatorTab="#chr(9)#">
		</cfif>
	</cfloop>
	<cfset fileDir = "#Application.webDirectory#">
		<cfif #fileFormat# is "csv">
			<cfset fileName = "CustomBulkloaderTemplate.csv">
			<cffile action="write" file="#Application.webDirectory#/download/#fileName#" addnewline="yes" output="#trim(headerLine)#" charset="utf-8">
			<cfif isDefined("guidance") AND guidance EQ "yes">
				<cffile action="append" file="#Application.webDirectory#/download/#fileName#" addnewline="yes" output="#trim(guidanceLine)#" charset="utf-8">
			</cfif>
			<cflocation url="/download.cfm?file=#fileName#" addtoken="false">
			<a href="/download/#fileName#">Click here if your file does not automatically download.</a>
		<cfelseif #fileFormat# is "txt">
			<cfset fileName = "CustomBulkloaderTemplate.txt">
			<cffile action="write" file="#Application.webDirectory#/download/#fileName#" addnewline="yes" output="#trim(headerLineTab)#" charset="utf-8">
			<cfif isDefined("guidance") AND guidance EQ "yes">
				<cffile action="append" file="#Application.webDirectory#/download/#fileName#" addnewline="yes" output="#guidanceLineTab#" charset="utf-8">
			</cfif>
			<cflocation url="/download.cfm?file=#fileName#" addtoken="false">
			<a href="/download/#fileName#">Click here if your file does not automatically download.</a>
		<cfelse>
			That file format is not supported.
		</cfif>
</cfoutput>
</cfif>


<cfinclude template="/shared/_footer.cfm">
