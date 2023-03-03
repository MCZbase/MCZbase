<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT container_unique_id,parent_unique_id,container_type,container_name, 
			description, remarks, width, height, length, number_positions,
			status 
		FROM cf_temp_cont_edit 
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
<cfabort>
</cfif>
<!--- end special case dump of problems --->
<cfinclude template="/includes/_header.cfm">
     <div style="width: 50em; margin: 0 auto; padding: 3em 0 4em 0;">
         <h3>Bulkload Container Edit Parent</h3>
<cfset title="Bulk Edit Container">
<cfif #action# is "nothing">
<p>This tool is used to edit container information and/or move parts to a different parent container.</p>
<p>Upload a comma-delimited text file (csv).
    Include column headings, spelled exactly as below. </p>
<span class="likeLink" onclick="document.getElementById('template').style.display='block';">View template</span>
	<div id="template" style="display:none;margin: 1em 0;">
		<label for="t">Copy the existing code and save as a .csv file</label>
		<textarea rows="2" cols="80" id="t">container_unique_id,parent_unique_id,container_type,container_name,description,remarks,width,height,length,number_positions</textarea>
	</div>
<p>Columns in <span style="color:red">red</span> are required; others are optional:</p>
<ul class="geol_hier">
	<li style="color:red">container_unique_id</li>
	<li>parent_unique_id</li>
	<li style="color:red">container_type</li>
	<li style="color:red">container_name</li>
	<li>description</li>
	<li>remarks</li>
	<li>width</li>
	<li>height</li>
	<li>length</li>
	<li>number_positions</li>
</ul>



<cfform name="atts" method="post" enctype="multipart/form-data" action="BulkloadContEditParent.cfm">
			<input type="hidden" name="Action" value="getFile">
			  <input type="file"
		   name="FiletoUpload"
		   size="45">
			 <input type="submit" value="Upload this file"
		class="savBtn"
		onmouseover="this.className='savBtn btnhov'"
		onmouseout="this.className='savBtn'">
  </cfform>

</cfif>
<!------------------------------------------------------->
<!------------------------------------------------------->

<!------------------------------------------------------->
<cfif #action# is "getFile">
<cfoutput>
	<cffile action="READ" file="#FiletoUpload#" variable="fileContent">

	<cfset fileContent=replace(fileContent,"'","''","all")>

	 <cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />

 <cfquery name="die" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	delete from cf_temp_cont_edit
</cfquery>

<cfset colNames="">
	<cfloop from="1" to ="#ArrayLen(arrResult)#" index="o">
		<cfset colVals="">
			<cfloop from="1"  to ="#ArrayLen(arrResult[o])#" index="i">
				<cfset thisBit=arrResult[o][i]>
				<cfif #o# is 1>
					<cfset colNames="#colNames#,#thisBit#">
				<cfelse>
					<cfset colVals="#colVals#,'#thisBit#'">
				</cfif>
			</cfloop>
		<cfif #o# is 1>
			<cfset colNames=replace(colNames,",","","first")>
		</cfif>
		<cfif len(#colVals#) gt 1>
			<cfset colVals=replace(colVals,",","","first")>
			<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into cf_temp_cont_edit (#colNames#) values (#preservesinglequotes(colVals)#)
			</cfquery>
		</cfif>
	</cfloop>

	<cflocation url="BulkloadContEditParent.cfm?action=validate">
</cfoutput>
</cfif>
<!------------------------------------------------------->
<!------------------------------------------------------->
<cfif #action# is "validate">
validate
<cfoutput>
	<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_cont_edit set container_id=
		(select container_id from container where container.barcode = cf_temp_cont_edit.container_unique_id)
	</cfquery>
	<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_cont_edit set parent_container_id=
		(select container_id from container where container.barcode = cf_temp_cont_edit.parent_unique_id)
	</cfquery>
	<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_cont_edit set status = 'container_not_found'
		where container_id is null
	</cfquery>
	<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_cont_edit set status = 'parent_container_not_found'
		where parent_container_id is null and parent_unique_id is not null
	</cfquery>
	<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_cont_edit set status = 'bad_container_type'
		where container_type not in (select container_type from ctcontainer_type)
	</cfquery>
	<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_cont_edit set status = 'missing_label'
		where CONTAINER_NAME is null
	</cfquery>

	<!---cfquery name="lq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select container_id,parent_container_id,key from cf_temp_cont_edit
	</cfquery>
	<cfloop query="lq">
		<cfquery name="islbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select container_type from container where container_id='#container_id#'
		</cfquery>
		<cfif islbl.container_type does not contain 'label'>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_cont_edit set status = 'only_updates_to_labels'
				where key=#key#
			</cfquery>
		</cfif>
		<cfif len(parent_container_id) gt 0>
			<cfquery name="isplbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT container_type from container 
				WHERE container_id = <cfqueryparam cfsqtype="CF_SQL_DECIMAL" value="#parent_container_id#">
			</cfquery>
			<cfif isplbl.container_type contains 'label'>
				<cfquery name="miapp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_cont_edit set status = 'parent_is_label'
					WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#">
				</cfquery>
			</cfif>
		</cfif>
	</cfloop--->
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT CONTAINER_UNIQUE_ID, PARENT_UNIQUE_ID, CONTAINER_TYPE, CONTAINER_NAME, DESCRIPTION, REMARKS, WIDTH,
			HEIGHT, LENGTH, NUMBER_POSITIONS, CONTAINER_ID, PARENT_CONTAINER_ID, STATUS 
		FROM cf_temp_cont_edit
	</cfquery>
	<cfquery name="pf" dbtype="query">
		select count(*) c from data where status is not null
	</cfquery>
	<cfif pf.c gt 0>
		<h2>
		There is a problem with #pf.c# row(s). Check STATUS. (<a href="/tools/BulkloadContEditParent.cfm?action=dumpProblems">download</a>).
		</h2>
	<cfelse>
		Validation checks passed. Look over the table below and <a href="BulkloadContEditParent.cfm?action=load">click to continue</a> if it all looks good.
	</cfif>
	<table>
		<thead>
			<tr>
				<th>CONTAINER_UNIQUE_ID</th>
				<th>PARENT_UNIQUE_ID</th>
				<th>CONTAINER_TYPE</th>
				<th>CONTAINER_NAME</th>
				<th>DESCRIPTION</th>
				<th>REMARKS</th>
				<th>WIDTH</th>
				<th>HEIGHT</th>
				<th>LENGTH</th>
				<th>NUMBER_POSITIONS</th>
				<th>CONTAINER_ID</th>
				<th>PARENT_CONTAINER_ID</th>
				<th>STATUS</th>
			</tr>
		<tbody>
			<tr>
				<cfloop query="data">
				<td>#data.CONTAINER_UNIQUE_ID#</td>
				<td>#data.PARENT_UNIQUE_ID#</td>
				<td>#data.CONTAINER_TYPE#</td>
				<td>#data.CONTAINER_NAME#</td>
				<td>#data.DESCRIPTION#</td>
				<td>#data.REMARKS#</td>
				<td>#data.WIDTH#</td>
				<td>#data.HEIGHT#</td>
				<td>#data.LENGTH#</td>
				<td>#data.NUMBER_POSITIONS#</td>
				<td>#data.CONTAINER_ID#</td>
				<td>#data.PARENT_CONTAINER_ID#</td>
				<td><strong>#STATUS#</strong></td>
				</cfloop>
			</tr>
		</tbody>
	</table>
</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------->
<cfif action is "load">
<cfoutput>
	<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_cont_edit
	</cfquery>
	<cftry>
	<cftransaction>
		<cfloop query="getTempData">
			<cfquery name="updateC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE
					container 
				SET
					CONTAINER_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CONTAINER_TYPE#">
				WHERE
					CONTAINER_ID= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CONTAINER_ID#">
			</cfquery>
		</cfloop>
	</cftransaction>
	<cfcatch>
		<h2>There was a problem updating container types.</h2>
		<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT container_unique_id,parent_unique_id,container_type,container_name, status 
			FROM cf_temp_cont_edit 
			WHERE status is not null
		</cfquery>
		<h3>Problematic Rows (<a href="/tools/BulkloadContEditParent.cfm?action=dumpProblems">download</a>)</h3>
		<table>
			<tr><th>container_unique_id</th><th>parent_unique_id</th><th>container_type</th><th>container_name</th><th>status</th></tr> 
			<cfloop query="getProblemData">
				<tr>
					<td>#getProblemData.container_unique_id#</td>
					<td>#getProblemData.parent_unique_id#</td>
					<td>#getProblemData.container_type#</td>
					<td>#getProblemData.container_name#</td>
					<td>#getProblemData.status#</td>
				</tr> 
			</cfloop>
		</table>
		<cfrethrow>
	</cfcatch>
	</cftry>
	<cftransaction>
		<cfloop query="getTempData">
			<cfquery name="updateC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE
					container 
				SET
					label=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CONTAINER_NAME#">,
					DESCRIPTION=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DESCRIPTION#">,
					PARENT_INSTALL_DATE=sysdate,
					CONTAINER_REMARKS=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
					<cfif len(#WIDTH#) gt 0>
						,WIDTH=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#WIDTH#">
					</cfif>
					<cfif len(#HEIGHT#) gt 0>
						,HEIGHT=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#HEIGHT#">
					</cfif>
					<cfif len(#LENGTH#) gt 0>
						,LENGTH=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LENGTH#">
					</cfif>
					<cfif len(#NUMBER_POSITIONS#) gt 0>
						,NUMBER_POSITIONS=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#NUMBER_POSITIONS#">
					</cfif>
					<cfif len(#parent_container_id#) gt 0>
						,parent_container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_container_id#">
					</cfif>
				WHERE
					CONTAINER_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CONTAINER_ID#">
			</cfquery>
		</cfloop>
	</cftransaction>
	Success, changes applied.
</cfoutput>
</cfif>
    </div>
<cfinclude template="/includes/_footer.cfm">
