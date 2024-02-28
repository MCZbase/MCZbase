<cfinclude template="/includes/_header.cfm">
    <div class="basic_box">

        <cfif #action# is "nothing">
<h3 class="wikilink">Bulkload Edited Parts <br> <span style="font-size: 15px;">(update existing part and/or append remark to existing remarks)</span></h3>
<p>Upload a comma-delimited text file (csv).
    Include column headings, spelled exactly as below.</p>
<p style="margin:1em;"><span class="likeLink" onclick="document.getElementById('template').style.display='block';">view template</span></p>
	<div id="template" style="display:none;margin: 1em 0;">
		<label for="t">Copy the existing code and save as a .csv file</label>
		<textarea rows="2" cols="80" id="t">institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,disposition,lot_count_modifier,lot_count,current_remarks,container_unique_id,change_container_type,condition,append_to_remarks,changed_date,new_preserve_method</textarea>
	</div>
    <p>Columns in <span style="color:red">red</span> are required and should match existing part row to update; others are optional:</p>
<ul class="geol_hier" style="padding-bottom: .25em;">
	<li style="color:red">institution_acronym</li>
	<li style="color:red">collection_cde</li>
	<li style="color:red">other_id_type</li>
		<ul style="margin-left:1em;padding-bottom: .5em;font-size: 14px;">
				<li>To match records by catalog number, use "catalog number" for other_id_type, and the catalog number in other_id_number.</li>
				<li>To match by other id types, put the type in other_id_type, and the value in other_id_number.</li>
		</ul>
	</li>
	<li style="color:red">other_id_number</li>
	<li style="color:red">part_name</li>
	<li style="color:red">preserve_method</li>
	<li style="color:red">disposition</li>
	<li>lot_count_modifier</li>
	<li style="color:red">lot_count</li>
	<li>container_unique_id
		<ul style="margin-left:1em;padding-bottom: .5em;font-size: 14px;">
				<li>Container Unique ID in which to place this part</li>
		</ul>
	</li>
	<li style="color:red">condition</li>
	<li>current_remarks
		<ul style="margin-left:1em;padding-bottom: .5em;font-size: 14px;">
			<li>
				Notes in the remarks field on the specimen record now. Copy and paste into the spreadsheet if possible.
				They must match the remarks on the record.
			</li>
		</ul>
	</li>
	<li>append_to_remarks
			<ul style="margin-left:1em;padding-bottom: .5em;font-size: 14px;">
				<li>Anything in this field will be appended to the current remarks. It will be automatically separated by a semicolon.</li>
			</ul>
	</li>
	<li>changed_date
			<ul style="margin-left:1em;padding-bottom: .5em;font-size: 14px;">
				<li>If the date the part preservation was changed is different than today, use this field to mark the preservation history correctly, otherwise leave blank. Format = YYYY-MM-DD</li>
			</ul>
	</li>
	<li>new_preserve_method
		<ul style="margin-left:1em;padding-bottom: .5em;font-size: 14px;">
				<li>The value in this field will replace the current preserve method for this part</li>
			</ul>
	</li>
</ul>

<br>

<cfform name="atts" method="post" enctype="multipart/form-data" action="BulkloadEditedParts.cfm">
			<input type="hidden" name="Action" value="getFile">
			  <input type="file"
		   name="FiletoUpload"
		   size="45">
			 <input type="submit" value="Upload this file"
		class="savBtn"
		onmouseover="this.className='savBtn btnhov'"
		onmouseout="this.className='savBtn'">
		<br><br>
	Character Set: <select name="cSet" id="cSet">
		<option value="windows-1252" selected>windows-1252</option>
		<option value="MacRoman">MacRoman</option>
		<option value="utf-8">utf-8</option>
		<option value="utf-16">utf-16</option>
		<option value="unicode">unicode</option>
	</input>
  </cfform>

</cfif>
<!------------------------------------------------------->
<!------------------------------------------------------->
<!------------------------------------------------------->
<cfif #action# is "getFile">
<cfoutput>

	<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="#cSet#">

	<cfset fileContent=replace(fileContent,"'","''","all")>

	 <cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />

 <cfquery name="die" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	delete from cf_temp_parts
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
			<cftransaction>
			<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into cf_temp_parts (#colNames#) values (#preservesinglequotes(colVals)#)
			</cfquery>
			insert into cf_temp_parts (#colNames#) values (#preservesinglequotes(colVals)#)
			<cfquery name="setuseexistingflag"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_parts set use_existing = 1
			</cfquery>
			</cftransaction>
		</cfif>
	</cfloop>

	<cflocation url="BulkloadEditedParts.cfm?action=validate">
</cfoutput>
</cfif>
<!------------------------------------------------------->
<!------------------------------------------------------->
<cfif #action# is "validate">
validate
<cfoutput>
	<cfquery name="getParentContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set parent_container_id =
		(select container_id from container where container.barcode = cf_temp_parts.CONTAINER_UNIQUE_ID)
	</cfquery>
	<cfquery name="validateGotParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Container Unique ID not found'
		where CONTAINER_UNIQUE_ID is not null and parent_container_id is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid part_name'
		where part_name|| '|' ||collection_cde NOT IN (
			select part_name|| '|' ||collection_cde from ctspecimen_part_name
			)
			OR part_name is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid preserve_method'
		where preserve_method|| '|' ||collection_cde NOT IN (
			select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method
			)
			OR preserve_method is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid new_preserve_method'
		where new_preserve_method|| '|' ||collection_cde NOT IN (
			select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method
			)
			and new_preserve_method is not null
	</cfquery>
    	<cfquery name="isValid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid use_existing flag'
			where use_existing not in ('0','1') OR
			use_existing is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid CONTAINER_UNIQUE_ID'
		where CONTAINER_UNIQUE_ID NOT IN (
			select barcode from container where barcode is not null
			)
		AND CONTAINER_UNIQUE_ID is not null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid DISPOSITION'
		where DISPOSITION NOT IN (
			select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP
			)
			OR disposition is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid CONTAINER_TYPE'
		where change_container_type NOT IN (
			select container_type from ctcontainer_type
			)
			AND change_container_type is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid CONDITION'
		where CONDITION is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';invalid lot_count_modifier'
		where lot_count_modifier NOT IN (
			select modifier from ctnumeric_modifiers
			)
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid LOT_COUNT'
		where (
			LOT_COUNT is null OR
			is_number(lot_count) = 0
			)
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid CHANGED_DATE'
		where isdate(changed_date) = 0
	</cfquery>

	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_parts where validated_status is null
	</cfquery>
	<cfloop query="data">
		<cfif #other_id_type# is "catalog number">
			<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						collection_object_id
					FROM
						cataloged_item,
						collection
					WHERE
						cataloged_item.collection_id = collection.collection_id and
						collection.collection_cde = '#collection_cde#' and
						collection.institution_acronym = '#institution_acronym#' and
						cat_num='#other_id_number#'
				</cfquery>
			<cfelse>
				<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						coll_obj_other_id_num.collection_object_id
					FROM
						coll_obj_other_id_num,
						cataloged_item,
						collection
					WHERE
						coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id and
						cataloged_item.collection_id = collection.collection_id and
						collection.collection_cde = '#collection_cde#' and
						collection.institution_acronym = '#institution_acronym#' and
						other_id_type = '#other_id_type#' and
						display_value = '#other_id_number#'
				</cfquery>
			</cfif>
			<cfif #collObj.recordcount# is 1>
				<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_parts SET collection_object_id = #collObj.collection_object_id# ,
					validated_status='VALID'
					where
					key = #key#
				</cfquery>
			<cfelse>
				<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_parts SET validated_status =
					validated_status || ';#data.institution_acronym# #data.collection_cde# #data.other_id_type# #data.other_id_number# could not be found.'
					where key = #key#
				</cfquery>
			</cfif>
		</cfloop>
		<!---
			Things that can happen here:
				1) Upload a part that doesn't exist
					Solution: create a new part, optionally put it in a container that they specify in the upload.
				2) Upload a part that already exists
					a) use_existing = 1
						1) part is in a container
							Solution: warn them, create new part, optionally put it in a container that they've specified
						 2) part is NOT already in a container
						 	Solution: put the existing part into the new container that they've specified or, if
						 	they haven't specified a new container, ignore this line as it does nothing.
					b) use_existing = 0
						1) part is in a container
							Solution: warn them, create a new part, optionally put it in the container they've specified
						2) part is not in a container
							Solution: same: warning and new part
		---->
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set (validated_status) = (
			select
			decode(parent_container_id,
			0,'NOTE: PART EXISTS',
			'NOTE: PART EXISTS IN PARENT CONTAINER')
			from specimen_part,coll_obj_cont_hist,container, coll_object_remark where
			specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id AND
			coll_obj_cont_hist.container_id = container.container_id AND
			coll_object_remark.collection_object_id(+) = specimen_part.collection_object_id AND
			derived_from_cat_item = cf_temp_parts.collection_object_id AND
			cf_temp_parts.part_name=specimen_part.part_name AND
			cf_temp_parts.preserve_method=specimen_part.preserve_method AND
			nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL')
			group by parent_container_id)
			where validated_status='VALID'
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set (parent_container_id) = (
			select container_id
			from container where
			barcode=CONTAINER_UNIQUE_ID)
			where substr(validated_status,1,5) IN ('VALID','NOTE:')
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set (use_part_id) = (
			select min(specimen_part.collection_object_id)
			from specimen_part, coll_object_remark where
			specimen_part.collection_object_id = coll_object_remark.collection_object_id(+) AND
			cf_temp_parts.part_name=specimen_part.part_name and
			cf_temp_parts.preserve_method=specimen_part.preserve_method and
			cf_temp_parts.collection_object_id=specimen_part.derived_from_cat_item and
			nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL'))
			where validated_status like '%NOTE: PART EXISTS%' AND
			use_existing =1
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set validated_status = 'PART NOT FOUND' where validated_status is null
		</cfquery>
		<cflocation url="BulkloadEditedParts.cfm?action=checkValidate">
</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif #action# is "checkValidate">

	<cfoutput>

	<cfquery name="inT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_parts
	</cfquery>
	<table border>
		<tr>
			<td>Problem</td>
			<td>institution_acronym</td>
			<td>collection_cde</td>
			<td>OTHER_ID_TYPE</td>
			<td>OTHER_ID_NUMBER</td>
			<td>part_name</td>
			<td>preserve_method</td>
			<td>disposition</td>
			<td>lot_count_modifier</td>
			<td>lot_count</td>
			<td>current_remarks</td>
			<td>condition</td>
			<td>CONTAINER_UNIQUE_ID</td>
			<td>use_existing</td>
			<td>append_to_remarks</td>
			<td>changed_date</td>
			<td>new_preserve_method</td>
		</tr>
		<cfloop query="inT">
			<tr>
				<td>
					<cfif len(#collection_object_id#) gt 0 and
							(#validated_status# is 'VALID')>
						<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#"
							target="_blank">Specimen</a>
					<cfelseif left(validated_status,5) is 'NOTE:'>
						<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#"
							target="_blank">Specimen</a> (#validated_status#)
					<cfelse>
						#validated_status#
					</cfif>
				</td>
				<td>#institution_acronym#</td>
				<td>#collection_cde#</td>
				<td>#OTHER_ID_TYPE#</td>
				<td>#OTHER_ID_NUMBER#</td>
				<td>#part_name#</td>
				<td>#preserve_method#</td>
				<td>#disposition#</td>
				<td>#lot_count_modifier#</td>
				<td>#lot_count#</td>
				<td>#current_remarks#</td>
				<td>#condition#</td>
				<td>#CONTAINER_UNIQUE_ID#</td>
				<td>1</td>
				<td>#append_to_remarks#</td>
				<td>#changed_date#</td>
				<td>#new_preserve_method#</td>
			</tr>
		</cfloop>
	</table>
	</cfoutput>
	<cfquery name="allValid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as cnt from cf_temp_parts where substr(validated_status,1,5) NOT IN
			('VALID','NOTE:')
	</cfquery>
	<cfif #allValid.cnt# is 0>
		<a href="BulkloadEditedParts.cfm?action=loadToDb">Load these parts....</a>
	<cfelse>
		You must fix everything above to proceed.
	</cfif>

</cfif>

<!-------------------------------------------------------------------------------------------->

<cfif #action# is "loadToDb">

<cfoutput>
	<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_parts where validated_status not in ('LOADED', 'PART NOT FOUND')
	</cfquery>
	<cfquery name= "getEntBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT agent_id FROM agent_name WHERE agent_name = '#session.username#'
	</cfquery>
	<cfif getEntBy.recordcount is 0>
		<cfabort showerror = "You aren't a recognized agent!">
	<cfelseif getEntBy.recordcount gt 1>
		<cfabort showerror = "Your login has has multiple matches.">
	</cfif>
	<cfset enteredbyid = getEntBy.agent_id>
	<cftransaction>
	<cfloop query="getTempData">
	<cfif len(#use_part_id#) is 0 and use_existing is not 1> <!---AND len(#CONTAINER_UNIQUE_ID#) gt 0--->>
		<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select sq_collection_object_id.nextval NEXTID from dual
		</cfquery>
		<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO coll_object (
				COLLECTION_OBJECT_ID,
				COLL_OBJECT_TYPE,
				ENTERED_PERSON_ID,
				COLL_OBJECT_ENTERED_DATE,
				LAST_EDITED_PERSON_ID,
				COLL_OBJ_DISPOSITION,
				LOT_COUNT_MODIFIER,
				LOT_COUNT,
				CONDITION,
				FLAGS )
			VALUES (
				#NEXTID.NEXTID#,
				'SP',
				#enteredbyid#,
				sysdate,
				#enteredbyid#,
				'#DISPOSITION#',
				'#lot_count_modifier#',
				#lot_count#,
				'#condition#',
				1 )
		</cfquery>
		<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO specimen_part (
				  COLLECTION_OBJECT_ID,
				  PART_NAME,
				  PRESERVE_METHOD,
				  DERIVED_FROM_cat_item )
				VALUES (
					#NEXTID.NEXTID#,
				  '#PART_NAME#',
				  '#PRESERVE_METHOD#'
					,#collection_object_id# )
		</cfquery>
		<cfif len(#current_remarks#) gt 0>
				<!---- new remark --->
				<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
					VALUES (sq_collection_object_id.currval, '#current_remarks#')
				</cfquery>
		</cfif>
		<cfif len(#changed_date#) gt 0>
			<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update SPECIMEN_PART_PRES_HIST set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') where collection_object_id =#NEXTID.NEXTID# and is_current_fg = 1
			</cfquery>
		</cfif>
		<cfif len(#CONTAINER_UNIQUE_ID#) gt 0>
			<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select container_id from coll_obj_cont_hist where collection_object_id = #NEXTID.NEXTID#
			</cfquery>
				<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update container set parent_container_id=#parent_container_id#
					where container_id = #part_container_id.container_id#
				</cfquery>
			<cfif #len(change_container_type)# gt 0>
				<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update container set
					container_type='#change_container_type#'
					where container_id=#parent_container_id#
				</cfquery>
			</cfif>
		</cfif>
	<cfelse>
	<!--- there is an existing matching container that is not in a parent_container;
		all we need to do is move the container to a parent IF it exists and is specified, or nothing otherwise --->
		<cfif len(#disposition#) gt 0>
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update coll_object set COLL_OBJ_DISPOSITION = '#disposition#' where collection_object_id = #use_part_id#
			</cfquery>
		</cfif>
		<cfif len(#condition#) gt 0>
			<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update coll_object set condition = '#condition#' where collection_object_id = #use_part_id#
			</cfquery>
		</cfif>
		<cfif len(#lot_count#) gt 0>
			<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update coll_object set lot_count = #lot_count#, lot_count_modifier='#lot_count_modifier#' where collection_object_id = #use_part_id#
			</cfquery>
		</cfif>
		<cfif len(#new_preserve_method#) gt 0>
			<cfquery name="change_preservemethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update SPECIMEN_PART set PRESERVE_METHOD = '#NEW_PRESERVE_METHOD#' where collection_object_id =#use_part_id#
			</cfquery>
		</cfif>
		<cfif len(#append_to_remarks#) gt 0>
			<cfquery name="remarksCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from coll_object_remark where collection_object_id = #use_part_id#
			</cfquery>
			<cfif remarksCount.recordcount is 0>
				<cfquery name="insertRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
					VALUES (#use_part_id#, '#append_to_remarks#')
				</cfquery>
			<cfelse>
				<cfquery name="updateRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update coll_object_remark
					set coll_object_remarks = DECODE(coll_object_remarks, null, '#append_to_remarks#', coll_object_remarks || '; #append_to_remarks#')
					where collection_object_id = #use_part_id#
				</cfquery>
			</cfif>
		</cfif>
		<cfif len(#CONTAINER_UNIQUE_ID#) gt 0>
			<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select container_id from coll_obj_cont_hist where collection_object_id = #use_part_id#
			</cfquery>
				<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update container set parent_container_id=#parent_container_id#
					where container_id = #part_container_id.container_id#
				</cfquery>
			<cfif #len(change_container_type)# gt 0>
				<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update container set
					container_type='#change_container_type#'
					where container_id=#parent_container_id#
				</cfquery>
			</cfif>
		</cfif>
		<cfif len(#changed_date#) gt 0>
			<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update SPECIMEN_PART_PRES_HIST set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') where collection_object_id =#use_part_id# and is_current_fg = 1
			</cfquery>
		</cfif>
	</cfif>
	<cfquery name="upLoaded" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = 'LOADED'
	</cfquery>
	</cfloop>
	</cftransaction>

	Spiffy, all done.
	<a href="/SpecimenResults.cfm?collection_object_id=#valuelist(getTempData.collection_object_id)#">
		See in Specimen Results
	</a>
</cfoutput>
</cfif>
         </div>
<cfinclude template="/includes/_footer.cfm">
