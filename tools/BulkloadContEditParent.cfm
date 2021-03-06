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
				select container_type from container where container_id='#parent_container_id#'
			</cfquery>
			<cfif isplbl.container_type contains 'label'>
				<cfquery name="miapp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_cont_edit set status = 'parent_is_label'
					where key=#key#
				</cfquery>
			</cfif>
		</cfif>
	</cfloop--->
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_cont_edit
	</cfquery>
	<cfdump var=#data#>
	<cfquery name="pf" dbtype="query">
		select count(*) c from data where status is not null
	</cfquery>
	<cfif pf.c gt 0>
		DoH! Something's busted. Check STATUS.
	<cfelse>
		yippee! Look over the above grid and <a href="BulkloadContEditParent.cfm?action=load">click to continue</a> if it all looks good.
	</cfif>
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
				update container set
					CONTAINER_TYPE='#CONTAINER_TYPE#'
				where CONTAINER_ID=#CONTAINER_ID#
			</cfquery>
		</cfloop>
	</cftransaction>
	<cfcatch>
		There was a problem updating container types.
		 <cfrethrow>
	</cfcatch>
	</cftry>
	<cftransaction>
		<cfloop query="getTempData">
			<cfquery name="updateC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update container set
					label='#CONTAINER_NAME#',
					DESCRIPTION='#DESCRIPTION#',
					PARENT_INSTALL_DATE=sysdate,
					CONTAINER_REMARKS='#remarks#'
					<cfif len(#WIDTH#) gt 0>
						,WIDTH=#WIDTH#
					</cfif>
					<cfif len(#HEIGHT#) gt 0>
						,HEIGHT=#HEIGHT#
					</cfif>
					<cfif len(#LENGTH#) gt 0>
						,LENGTH=#LENGTH#
					</cfif>
					<cfif len(#NUMBER_POSITIONS#) gt 0>
						,NUMBER_POSITIONS=#NUMBER_POSITIONS#
					</cfif>
					<cfif len(#parent_container_id#) gt 0>
						,parent_container_id=#parent_container_id#
					</cfif>
				where CONTAINER_ID=#CONTAINER_ID#
			</cfquery>
		</cfloop>
	</cftransaction>
	Spiffy, all done.
</cfoutput>
</cfif>
    </div>
<cfinclude template="/includes/_footer.cfm">