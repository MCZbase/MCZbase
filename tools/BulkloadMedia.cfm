<cfheader name="Cache-Control" value="no-cache, must-revalidate">
<!---
drop table cf_temp_media;
drop table cf_temp_media_relations;
drop table cf_temp_media_labels;

create table cf_temp_media (
 key NUMBER,
 MEDIA_URI VARCHAR2(255),
 MIME_TYPE VARCHAR2(255),
 MEDIA_TYPE VARCHAR2(255),
 PREVIEW_URI VARCHAR2(255),
MEDIA_RELATIONSHIPS VARCHAR2(244),
 MEDIA_LABELS VARCHAR2(255)
);

alter table cf_temp_media add status varchar2(255);

create table cf_temp_media_relations (
 key NUMBER,
 MEDIA_RELATIONSHIP VARCHAR2(40),
 CREATED_BY_AGENT_ID NUMBER,
 RELATED_PRIMARY_KEY NUMBER
);

create table cf_temp_media_labels (
key NUMBER,
 MEDIA_LABEL VARCHAR2(255),
LABEL_VALUE VARCHAR2(255),
 ASSIGNED_BY_AGENT_ID NUMBER
);

create or replace public synonym cf_temp_media for cf_temp_media;
grant all on cf_temp_media to manage_media;
grant select on cf_temp_media to public;

create public synonym cf_temp_media_relations for cf_temp_media_relations;
grant all on cf_temp_media_relations to manage_media;
grant select on cf_temp_media_relations to public;

create public synonym cf_temp_media_labels for cf_temp_media_labels;
grant all on cf_temp_media_labels to manage_media;
grant select on cf_temp_media_labels to public;

CREATE OR REPLACE TRIGGER cf_temp_media_key
 before insert  ON cf_temp_media
 for each row
    begin
    	if :NEW.key is null then
    		select somerandomsequence.nextval into :new.key from dual;
    	end if;
    end;
/
sho err
--->

<cfinclude template="/includes/_header.cfm">
    <div style="margin: 0 auto;padding: 1em 1em 3em 1em;">
<cfif #action# is "nothing">
    <h3 class="wikilink">Bulkload Media</h3>
    <p>Step 1: Ensure that Media exists on the shared drive or external URL and that the records that you want to relate to this media exist.</p>
    <p>Step 2: Upload a comma-delimited text file (csv).</p>
    <p>Include column headings, spelled exactly as below.  </p>
	 <p><span class="likeLink" onclick="document.getElementById('template').style.display='block';"> view template</span></p>
	<div id="template" style="display:none;margin: 1em 0;">
		<label for="t">Copy and save as a .csv file</label>
		<textarea rows="2" cols="80" id="t">MEDIA_URI,MIME_TYPE,MEDIA_TYPE,PREVIEW_URI,MEDIA_RELATIONSHIPS,MEDIA_LABELS,MEDIA_LICENSE_ID, MASK_MEDIA</textarea>
	</div>

    <p>Columns in <span style="color:red">red</span> are required; others are optional:</p>
<ul class="geol_hier" style="padding-bottom:1em;">
	<li style="color:red">MEDIA_URI</li>
	<li style="color:red">MIME_TYPE</li>
	<li style="color:red">MEDIA_TYPE</li>
	<li>PREVIEW_URI</li>
	<li>MEDIA_RELATIONSHIPS</li>
	<li>MEDIA_LABELS</li>
	<li>MEDIA_LICENSE_ID</li>
	<li>MASK_MEDIA</li>
</ul>

<p>MIME_TYPE must be one of the values in <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMIME_TYPE">the MIME_TYPE controlled vocabulary</a>, and MEDIA_TYPE must be one of the values in <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_TYPE">the MEDIA_TYPE controlled vocabulary</a>, and the combination of the two of these should be sensible (e.g. image and image/jpeg, but not image and audio/mpeg)</a>

<p>The format for MEDIA_RELATIONSHIPS is {media_relationship}={value}[;{media_relationship}={value}]</p>
	 <p>See <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_RELATIONSHIP">the MEDIA_RELATIONSHIP controlled vocabulary</a> for a list of allowed values.</p>
     <p style="margin-top:.5em;font-weight:bold;">Examples:</p>
	<ul class="geol_hier" style="padding-bottom:1em;padding-top: .25em;">
		<li>
			created by agent=Jane Doe
		</li>
		<li>
			created by agent=Jane Doe;assigned to project=Vocal variation in Pipilo maculatus
		</li>
		<li>
			created by agent=Jane Doe;assigned to project=Vocal variation in Pipilo maculatus;shows cataloged_item=MCZ:Bird:12345
		</li>
	</ul>
    <p style="margin-top:.5em;font-weight:bold;">Acceptable values are:</p>
	<ul class="geol_hier" style="padding-bottom:1em;padding-top:.25em;">
		<li>Agent Name (must resolve to one agent_id)</li>
		<li>Project Title (exact string match)</li>
		<li>Cataloged Item (DWC triplet)</li>
		<li>Collecting Event (collecting_event_id)</li>
	</ul>



    <p>The format for MEDIA_LABELS is {media_label}={value}[;{media_label}={value}]</p>
	 <p>See <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LABEL">the MEDIA_LABEL controlled vocabulary</a> for a list of allowed values.</p>
	 <p>Notes: Made date must be in the form yyyy-mm-dd. More than one media label must be separated by a semicolon, and individual values must not themselves contain semicolons.  Check the data as presented after the file has been uploaded carefully to make sure that the individual media labels and values have been correctly parsed.</p>
    <p style="margin-top:.5em;font-weight:bold;">Examples:</p>
	<ul  class="geol_hier" style="padding-top:.25em;padding-bottom: 1em;">
		<li>
			audio bit resolution=whatever
		</li>
		<li>
			audio bit resolution=2;audio cut id=5
		</li>
		<li>
			audio bit resolution=2;audio cut id=5;made date=1964-01-07
		</li>
	</ul>
        <p style="font-weight:bold;">Errors:</p>
<ul  class="geol_hier" style="padding-bottom:2em;padding-top:.25em;">
		<li>
			See <a href="https://code.mcz.harvard.edu/wiki/index.php/MCZbase_error_message_translation">MCZbase Wiki</a> for error message translations.
		</li>
		<li><b>Note:</b>  If you receive the same error messages after fixing them, you may have to clear your browser's cache to have the fixed .csv sheet load cleanly.
		</li>
	</ul>
	<p style="font-weight:bold;">MEDIA LICENSE:</p>
	<p>The media license id should be entered using the numeric codes below. If omitted this will default to &quot;1 - MCZ Permissions & Copyright&quot;</p>
<div class="geol_hier" style="padding-bottom:2em;padding-top:.25em;">
    <style>
	    dl {font-size: smaller;}
	    dt {font-weight: 550;margin-top: 8px; margin-bottom: 3px;}
	    dt span {display: inline-block; width: 20px;}
	</style>
		<dl>
			<dt><b>Codes</b></dt><dd></dd>
			<dt><span>1 </span> MCZ Permissions &amp; Copyright    copyrighted material</dt> <dd> All MCZ images and publications should have this designation</dd>
			<dt><span>4 </span> Rights defined by 3rd party host</dt> <dd>This material is hosted by an external party. Please refer to the licensing statement provided by the linked host.</dd>
			<dt><span>5 </span> Creative Commons Zero (CC0)</dt><dd>CC0 enables scientists, educators, artists and other creators and owners of copyright- or database-protected content to waive those interests in their works and thereby place them as completely as possible in the public domain.</dd>
			<dt><span>6 </span>Creative Commons Attribution (CC BY)</dt><dd>This license lets others distribute, remix, tweak, and build upon your work, even commercially, as long as they credit you for the original creation.</dd>
			<dt><span>7</span>Creative Commons Attribution-ShareAlike (CC BY-SA)</dt> <dd>This license lets others remix, tweak, and build upon your work even for commercial purposes, as long as they credit you and license their new creations under the identical terms.</dd>
			<dt><span>8 </span>Creative Commons Attribution-NonCommercial (CC BY-NC)</dt><dd>This license lets others remix, tweak, and build upon your work non-commercially, and although their new works must also acknowledge you and be non-commercial, they don&apos;t have to license their derivative works on the same terms.</dd>
			<dt><span>9 </span>Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)</dt><dd>This license lets others remix, tweak, and build upon your work non-commercially, as long as they credit you and license their new creations under the identical terms.</dd>
		</dl>
</div>

	<p style="font-weight:bold;">MASK MEDIA:</p>
	<p>To mark media as hidden from Public Users put a 1 in the MASK_MEDIA column. Leave blank for Public media</p>
<br>
<br>

	<cfform name="atts" method="post" enctype="multipart/form-data">
		<input type="hidden" name="Action" value="getFile">
		<input type="file" name="FiletoUpload" size="45">
		<select name="veryLargeFiles">
			<option value="">Process Normally</option>
			<option value="true">References Very Large Files</option>
		</select>
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
       <cfif !isdefined("FiletoUpload") OR len(FiletoUpload) eq 0 >
           <cfoutput>
	   You must select a file to upload.
	   Use your back button.
           </cfoutput>
       <cfelse>
           <!--- TODO: put this in a temp table --->
           <!--- *** Only one user can bulkload media at the same time *** --->
           <cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
           	delete from cf_temp_media
           </cfquery>
           <cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
           	delete from cf_temp_media_relations
           </cfquery>
           <cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
           	delete from cf_temp_media_labels
           </cfquery>

           <cfoutput>
           <cffile action="READ" file="#FiletoUpload#" variable="fileContent">
           <cfset fileContent=replace(fileContent,"'","''","all")>
           <cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
           <cfdump var=#arrResult#>

           <cfset numberOfColumns = ArrayLen(arrResult[1])>

           <cfset colNames="">
           <cfloop from="1" to ="#ArrayLen(arrResult)#" index="o">
              <cfset colVals="">
                 <cfloop from="1"  to ="#ArrayLen(arrResult[o])#" index="i">
                     <!---
                     <cfdump var="#arrResult[o]#">
                     --->
                     <cfset numColsRec = ArrayLen(arrResult[o])>
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
                 <cfif numColsRec lt numberOfColumns>
                    <cfset missingNumber = numberOfColumns - numColsRec>
                    <cfloop from="1" to="#missingNumber#" index="c">
                       <cfset colVals = "#colVals#,''">
                    </cfloop>
                 </cfif>
                 <cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                    insert into cf_temp_media (#colNames#) values (#preservesinglequotes(colVals)#)
                 </cfquery>

              </cfif>
           </cfloop>
           </cfoutput>
				<cfif not isDefined("veryLargeFiles")><cfset veryLargeFiles=""></cfif>
           <cflocation url="BulkloadMedia.cfm?action=validate&veryLargeFiles=#veryLargeFiles#">
       </cfif> <!--- File was selected --->
</cfif> <!--- action getFile --->
<!------------------------------------------------------->
<!------------------------------------------------------->
<cfif #action# is "validate">
<cfoutput>
<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from cf_temp_media
</cfquery>
<cfloop query="d">
	<cfset rec_stat="">
	<cfquery name = "c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT *
		FROM media 
		WHERE
			media_uri = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_uri#">
	</cfquery>
	<cfif c.RecordCount gt 0>
		<cfset rec_stat=listappend(rec_stat,'MEDIA_URI already exists in MEDIA table',";")>
	</cfif>
	<cfif len(mask_media) gt 0>
		<cfif not(mask_media EQ 1 or mask_media EQ 0)>
			<cfset rec_stat=listappend(rec_stat,'MASK_MEDIA should be blank, 1 or 0',";")>
		</cfif>
	</cfif>
	<cfif len(MEDIA_LABELS) gt 0>
		<cfloop list="#media_labels#" index="l" delimiters=";">
			<cfset ln=listgetat(l,1,"=")>
			<cfset lv=listgetat(l,2,"=")>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT MEDIA_LABEL 
				FROM CTMEDIA_LABEL 
				WHERE MEDIA_LABEL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ln#">
			</cfquery>
			<cfif len(c.MEDIA_LABEL) is 0>
				<cfset rec_stat=listappend(rec_stat,'Media label #ln# is invalid',";")>
			<cfelseif ln EQ "made date" && refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",lv) EQ 0>
				<cfset rec_stat=listappend(rec_stat,'Media label #ln# must have a value in the form yyyy-mm-dd',";")>
			<cfelse>
				<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into cf_temp_media_labels (
						key,
						MEDIA_LABEL,
						ASSIGNED_BY_AGENT_ID,
						LABEL_VALUE
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ln#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lv#">
					)
				</cfquery>
			</cfif>
		</cfloop>
	</cfif>
	<cfif len(MEDIA_RELATIONSHIPS) gt 0>
		<cfloop list="#MEDIA_RELATIONSHIPS#" index="l" delimiters=";">
			<cfset ln=listgetat(l,1,"=")>
			<cfset lv=listgetat(l,2,"=")>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select MEDIA_RELATIONSHIP from CTMEDIA_RELATIONSHIP where MEDIA_RELATIONSHIP='#ln#'
			</cfquery>
			<cfif len(c.MEDIA_RELATIONSHIP) is 0>
				<cfset rec_stat=listappend(rec_stat,'Media relationship #ln# is invalid',";")>
			<cfelse>
				<cfset table_name = listlast(ln," ")>
				<cfif table_name is "agent">
					<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct(agent_id) agent_id from agent_name where agent_name ='#lv#'
					</cfquery>
					<cfif c.recordcount is 1 and len(c.agent_id) gt 0>
						<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into cf_temp_media_relations (
 								key,
								MEDIA_RELATIONSHIP,
								CREATED_BY_AGENT_ID,
								RELATED_PRIMARY_KEY
							) values (
								#key#,
								'#ln#',
								#session.myAgentId#,
								#c.agent_id#
							)
						</cfquery>
					<cfelse>
						<cfset rec_stat=listappend(rec_stat,'Agent #lv# matched #c.recordcount# records.',";")>
					</cfif>
				<cfelseif table_name is "locality">
					<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select locality_id from locality where locality_id ='#lv#'
					</cfquery>
					<cfif c.recordcount is 1 and len(c.locality_id) gt 0>
						<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into cf_temp_media_relations (
 								key,
								MEDIA_RELATIONSHIP,
								CREATED_BY_AGENT_ID,
								RELATED_PRIMARY_KEY
							) values (
								#key#,
								'#ln#',
								#session.myAgentId#,
								#c.locality_id#
							)
						</cfquery>
					<cfelse>
						<cfset rec_stat=listappend(rec_stat,'locality_id #lv# matched #c.recordcount# records.',";")>
					</cfif>
				<cfelseif table_name is "collecting_event">
					<cfset idtype=trim(listfirst(lv,"|"))>
					<cfset idvalue=trim(listlast(lv,"|"))>
					<cfif idtype EQ "collecting_event_id">
						<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select collecting_event_id from collecting_event where collecting_event_id ='#lv#'
						</cfquery>
						<cfif c.recordcount is 1 and len(c.collecting_event_id) gt 0>
							<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								insert into cf_temp_media_relations (
	 								key,
									MEDIA_RELATIONSHIP,
									CREATED_BY_AGENT_ID,
									RELATED_PRIMARY_KEY
								) values (
									#key#,
									'#ln#',
									#session.myAgentId#,
									#c.collecting_event_id#
								)
							</cfquery>
						<cfelse>
							<cfset rec_stat=listappend(rec_stat,'collecting_event #lv# matched #c.recordcount# records.',";")>
						</cfif>
					<cfelse>
						<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select collecting_event_id 
							from coll_event_num_series ns 
    							join coll_event_number n  on ns.coll_event_num_series_id = n.coll_event_num_series_id
    							where ns.number_series = '#idtype#'
    							and n.coll_event_number = '#idvalue#'
						</cfquery>
						<cfif c.recordcount gt 0>
							<cfloop query="c">
								<cfif len(c.collecting_event_id) gt 0>
                                                        	<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                                                                	insert into cf_temp_media_relations (
                                                                        	key,
                                                                        	MEDIA_RELATIONSHIP,
                                                                        	CREATED_BY_AGENT_ID,
                                                                        	RELATED_PRIMARY_KEY
                                                                	) values (
                                                                        	#d.key#,
                                                                        	'#ln#',
                                                                        	#session.myAgentId#,
                                                                        	#c.collecting_event_id#
                                                                	)
                                                        	</cfquery>
								</cfif>
							</cfloop>							
						<cfelse>
							<cfset rec_stat=listappend(rec_stat,'collecting event number #lv# matched #c.recordcount# records.',";")>
						</cfif>
					</cfif>
				<cfelseif table_name is "project">
					<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct(project_id) project_id from project where PROJECT_NAME ='#lv#'
					</cfquery>
					<cfif c.recordcount is 1 and len(c.project_id) gt 0>
						<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into cf_temp_media_relations (
 								key,
								MEDIA_RELATIONSHIP,
								CREATED_BY_AGENT_ID,
								RELATED_PRIMARY_KEY
							) values (
								#key#,
								'#ln#',
								#session.myAgentId#,
								#c.project_id#
							)
						</cfquery>
					<cfelse>
						<cfset rec_stat=listappend(rec_stat,'Project #lv# matched #c.recordcount# records.',";")>
					</cfif>
				<cfelseif table_name is "publication">
					<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select publication_id from publication where publication_id ='#lv#'
					</cfquery>
					<cfif c.recordcount is 1 and len(c.publication_id) gt 0>
						<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into cf_temp_media_relations (
 								key,
								MEDIA_RELATIONSHIP,
								CREATED_BY_AGENT_ID,
								RELATED_PRIMARY_KEY
							) values (
								#key#,
								'#ln#',
								#session.myAgentId#,
								#c.publication_id#
							)
						</cfquery>
					<cfelse>
						<cfset rec_stat=listappend(rec_stat,'publication_id #lv# matched #c.recordcount# records.',";")>
					</cfif>
				<cfelseif table_name is "cataloged_item">
					<cftry>
					<cfset institution_acronym = listgetat(lv,1,":")>
					<cfset collection_cde = listgetat(lv,2,":")>
					<cfset cat_num = listgetat(lv,3,":")>
					<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select collection_object_id from
							cataloged_item,
							collection
						WHERE
							cataloged_item.collection_id = collection.collection_id AND
							cat_num = '#cat_num#' AND
							lower(collection.collection_cde)='#lcase(collection_cde)#' AND
							lower(collection.institution_acronym)='#lcase(institution_acronym)#'
					</cfquery>
					<cfif c.recordcount is 1 and len(c.collection_object_id) gt 0>
						<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into cf_temp_media_relations (
 								key,
								MEDIA_RELATIONSHIP,
								CREATED_BY_AGENT_ID,
								RELATED_PRIMARY_KEY
							) values (
								#key#,
								'#ln#',
								#session.myAgentId#,
								#c.collection_object_id#
							)
						</cfquery>
					<cfelse>
						<cfset rec_stat=listappend(rec_stat,'Cataloged Item #lv# matched #c.recordcount# records.',";")>
					</cfif>
					<cfcatch>
						<cfset rec_stat=listappend(rec_stat,'#lv# is not a BOO DWC Triplet. *#institution_acronym#* *#collection_cde#* *#cat_num#*',";")>
					</cfcatch>
					</cftry>
				<cfelseif table_name is "accn">
					<cfset coll = listgetat(lv,1," ")>
					<cfset accnnum = listgetat(lv,2," ")>
					<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select a.transaction_id
						from accn a, trans t, collection c
						where a.transaction_id = t.transaction_id
						and t.collection_id = c.collection_id
						and a.accn_number = #accnnum#
						and c.collection = '#coll#'
					</cfquery>
					<cfif c.recordcount is 1 and len(c.transaction_id) gt 0>
						<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into cf_temp_media_relations (
 								key,
								MEDIA_RELATIONSHIP,
								CREATED_BY_AGENT_ID,
								RELATED_PRIMARY_KEY
							) values (
								#key#,
								'#ln#',
								#session.myAgentId#,
								#c.transaction_id#
							)
						</cfquery>
					<cfelse>
						<cfset rec_stat=listappend(rec_stat,'accn number #lv# matched #c.recordcount# records.',";")>
					</cfif>
				<cfelseif table_name is "permit">
					<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select permit_id from permit where permit_num = '#lv#'
					</cfquery>
					<cfif c.recordcount is 1 and len(c.permit_id) gt 0>
						<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into cf_temp_media_relations (
 								key,
								MEDIA_RELATIONSHIP,
								CREATED_BY_AGENT_ID,
								RELATED_PRIMARY_KEY
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ln#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#c.permit_id#">
							)
						</cfquery>
					<cfelse>
						<cfset rec_stat=listappend(rec_stat,'permit number #lv# matched #c.recordcount# records.',";")>
					</cfif>
				<cfelseif table_name is "borrow">
					<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select transaction_id 
						from borrow 
						where borrow_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lv#">
					</cfquery>
					<cfif c.recordcount is 1 and len(c.transaction_id) gt 0>
						<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into cf_temp_media_relations (
 								key,
								MEDIA_RELATIONSHIP,
								CREATED_BY_AGENT_ID,
								RELATED_PRIMARY_KEY
							) values (
								#key#,
								'#ln#',
								#session.myAgentId#,
								#c.transaction_id#
							)
						</cfquery>
					<cfelse>
						<cfset rec_stat=listappend(rec_stat,'permit number #lv# matched #c.recordcount# records.',";")>
					</cfif>
				<cfelseif table_name is "specimen_part">
                                        <cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                                                select sp.collection_object_id
                                                from specimen_part sp
						join (select * from coll_obj_cont_hist where current_container_fg = 1)  ch on (sp.collection_object_id = ch.collection_object_id)
						join  container c on (ch.container_id = c.container_id)
						join  container pc on (c.parent_container_id = pc.container_id)
                                                where pc.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lv#">
                                        </cfquery>
                                        <cfif c.recordcount is 1 and len(c.collection_object_id) gt 0>
                                                <cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                                                        insert into cf_temp_media_relations (
                                                                key,
                                                                MEDIA_RELATIONSHIP,
                                                                CREATED_BY_AGENT_ID,
                                                                RELATED_PRIMARY_KEY
                                                        ) values (
                                                                #key#,
                                                                '#ln#',
                                                                #session.myAgentId#,
                                                                #c.collection_object_id#
                                                        )
                                                </cfquery>
                                        <cfelse>
                                                <cfset rec_stat=listappend(rec_stat,'barcode #lv# matched #c.recordcount# records.',";")>
                                        </cfif>


				<cfelse>
					<cfset rec_stat=listappend(rec_stat,'Media relationship #ln# is not handled',";")>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select MIME_TYPE from CTMIME_TYPE where MIME_TYPE='#MIME_TYPE#'
	</cfquery>
	<cfif len(c.MIME_TYPE) is 0>
		<cfset rec_stat=listappend(rec_stat,'MIME_TYPE #MIME_TYPE# is invalid',";")>
	</cfif>
	<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select MEDIA_TYPE from CTMEDIA_TYPE where MEDIA_TYPE='#MEDIA_TYPE#'
	</cfquery>
	<cfif len(c.MEDIA_TYPE) is 0>
		<cfset rec_stat=listappend(rec_stat,'MEDIA_TYPE #MEDIA_TYPE# is invalid',";")>
	</cfif>
	<cfif len(MEDIA_LICENSE_ID) gt 0>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select media_license_id from CTMEDIA_LICENSE where media_license_id='#MEDIA_LICENSE_ID#'
		</cfquery>
		<cfif len(c.media_license_id) is 0>
			<cfset rec_stat=listappend(rec_stat,'MEDIA_LICENSE_ID #MEDIA_LICENSE_ID# is invalid',";")>
		</cfif>
	</cfif>
	<cfhttp url="#media_uri#" charset="utf-8" timeout=5 method="head" />
	<cfif left(cfhttp.statuscode,3) is not "200">
		<cfset rec_stat=listappend(rec_stat,'#media_uri# is invalid',";")>
	</cfif>
	<cfif len(preview_uri) gt 0>
		<cfhttp url="#preview_uri#" charset="utf-8" timeout=5 method="head" />
		<cfif left(cfhttp.statuscode,3) is not "200">
			<cfset rec_stat=listappend(rec_stat,'#preview_uri# is invalid',";")>
		</cfif>
	</cfif>
	<cfif not isDefined("veryLargeFiles")><cfset veryLargeFiles=""></cfif>
	<cfif veryLargeFiles NEQ "true">
		<!--- both isimagefile and cfimage run into heap space limits with very large files --->
		<cfif isimagefile("#escapeQuotes(media_uri)#")>
			<cfimage action="info" source="#escapeQuotes(media_uri)#" structname="imgInfo"/>
			<cfquery name="makeHeightLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into cf_temp_media_labels (
							key,
							MEDIA_LABEL,
							ASSIGNED_BY_AGENT_ID,
							LABEL_VALUE
						) values (
							#key#,
							'height',
							#session.myAgentId#,
							'#imgInfo.height#'
						)
			</cfquery>
			<cfquery name="makeWidthLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						insert into cf_temp_media_labels (
							key,
							MEDIA_LABEL,
							ASSIGNED_BY_AGENT_ID,
							LABEL_VALUE
						) values (
							#key#,
							'width',
							#session.myAgentId#,
							'#imgInfo.width#'
						)
			</cfquery>
			<cfhttp url="#media_uri#" method="get" getAsBinary="yes" result="result">
			<cfset md5hash=Hash(result.filecontent,"MD5")>
	
			<cfquery name="makeMD5hash" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						insert into cf_temp_media_labels (
							key,
							MEDIA_LABEL,
							ASSIGNED_BY_AGENT_ID,
							LABEL_VALUE
						) values (
							#key#,
							'md5hash',
							#session.myAgentId#,
							'#md5Hash#'
						)
			</cfquery>
		</cfif>
	</cfif>
	<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_media set status='#rec_stat#' where key=#key#
	</cfquery>
</cfloop>
<cfquery name="bad" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from cf_temp_media where status is not null
</cfquery>
<cfif len(bad.key) gt 0>
	Oops! You must fix everything below before proceeding (see STATUS column).
	<cfdump var=#bad#>
<cfelse>
	Yay! Initial checks on your file passed. Carefully review the tables below, then
	<a href="BulkloadMedia.cfm?action=load"><strong>click here</strong></a> to proceed.
	<br>^^^ that thing. You must click it.
	<br>
	(Note that the table below is "flattened." Media entries are repeated for every Label and Relationship.)
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			cf_temp_media.key,
			status,
			MEDIA_URI,
			MIME_TYPE,
			MEDIA_TYPE,
			PREVIEW_URI,
			MEDIA_LICENSE_ID,
			MEDIA_RELATIONSHIP,
			RELATED_PRIMARY_KEY,
			MEDIA_LABEL,
			LABEL_VALUE
		from
			cf_temp_media,
			cf_temp_media_labels,
			cf_temp_media_relations
		where
			cf_temp_media.key=cf_temp_media_labels.key (+) and
			cf_temp_media.key=cf_temp_media_relations.key (+)
		group by
			cf_temp_media.key,
			status,
			MEDIA_URI,
			MIME_TYPE,
			MEDIA_TYPE,
			PREVIEW_URI,
			MEDIA_LICENSE_ID,
			MEDIA_RELATIONSHIP,
			RELATED_PRIMARY_KEY,
			MEDIA_LABEL,
			LABEL_VALUE
	</cfquery>
	<cfdump var=#media#>
</cfif>
</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif #action# is "load">
<cfoutput>
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			*
		from
			cf_temp_media
	</cfquery>
	<cftransaction>
		<cfloop query="media">
			<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_media_id.nextval nv from dual
			</cfquery>
			<cfset media_id=mid.nv>
			<cfif len(media_license_id) is 0>
				<cfset medialicenseid = 1>
			<cfelse>
				<cfset medialicenseid = media_license_id>
			</cfif>
			<cfif len(mask_media) is 0>
				<cfset maskmedia = 0>
			<cfelse>
				<cfset maskmedia = mask_media>
			</cfif>
			<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media (media_id,media_uri,mime_type,media_type,preview_uri, MEDIA_LICENSE_ID, MASK_MEDIA_FG)
	            values (#media_id#,'#escapeQuotes(media_uri)#','#mime_type#','#media_type#','#preview_uri#', #medialicenseid#, #MASKMEDIA#)
			</cfquery>
			<cfquery name="media_relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					*
				from
					cf_temp_media_relations
				where
					key=#key#
			</cfquery>
			<cfloop query="media_relations">
				<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into
						media_relations (
						media_id,media_relationship,related_primary_key
						)values (
						#media_id#,'#MEDIA_RELATIONSHIP#',#RELATED_PRIMARY_KEY#)
				</cfquery>
			</cfloop>
			<cfquery name="medialabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					*
				from
					cf_temp_media_labels
				where
					key=#key#
			</cfquery>
			<cfloop query="medialabels">
				<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into media_labels (media_id,media_label,label_value)
					values (#media_id#,'#MEDIA_LABEL#','#LABEL_VALUE#')
				</cfquery>
			</cfloop>
		</cfloop>
	</cftransaction>
	Spiffy, all done.
</cfoutput>
</cfif>
    </div>
<cfinclude template="/includes/_footer.cfm">
