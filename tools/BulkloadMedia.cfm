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
    <div style="width: 54em; margin: 0 auto;padding: 1em 0 3em 0;">
<cfif #action# is "nothing">
    <h3 class="wikilink">Bulkload Media</h3>
    <p>Step 1: Ensure that Media exists on the shared drive or external URL and that the records that you want to relate to this media exist.</p>
    <p>Step 2: Upload a comma-delimited text file (csv).</p>
    <p>Include column headings, spelled exactly as below.  </p>
<p></p><span class="likeLink" onclick="document.getElementById('template').style.display='block';"> view template</span></p>
	<div id="template" style="display:none;margin: 1em 0;">
		<label for="t">Copy and save as a .csv file</label>
		<textarea rows="2" cols="80" id="t">MEDIA_URI,MIME_TYPE,MEDIA_TYPE,PREVIEW_URI,MEDIA_RELATIONSHIPS,MEDIA_LABELS</textarea>
	</div>

    <p>Columns in <span style="color:red">red</span> are required; others are optional:</p>
<ul class="geol_hier" style="padding-bottom:1em;">
	<li style="color:red">MEDIA_URI</li>
	<li style="color:red">MIME_TYPE</li>
	<li style="color:red">MEDIA_TYPE</li>
	<li>PREVIEW_URI</li>
	<li>MEDIA_RELATIONSHIPS</li>
	<li>MEDIA_LABELS</li>
</ul>

<p>The format for MEDIA_RELATIONSHIPS is {media_relationship}={value}[;{media_relationship}={value}]</p>
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
    <p style="margin-top:.5em;font-weight:bold;">Examples:</p>
	<ul  class="geol_hier" style="padding-top:.25em;padding-bottom: 1em;">
		<li>
			audio bit resolution=whatever
		</li>
		<li>
			audio bit resolution=2;audio cut id=5
		</li>
		<li>
			audio bit resolution=2;audio cut id=5;made date=7 January 1964
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

<cfform name="atts" method="post" enctype="multipart/form-data">
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
           <cflocation url="BulkloadMedia.cfm?action=validate">
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
		select * from media where media_uri = '#media_uri#'
	</cfquery>
	<cfif c.RecordCount gt 0>
		<cfset rec_stat=listappend(rec_stat,'MEDIA_URI already exists in MEDIA table',";")>
	</cfif>
	<cfif len(MEDIA_LABELS) gt 0>
		<cfloop list="#media_labels#" index="l" delimiters=";">
			<cfset ln=listgetat(l,1,"=")>
			<cfset lv=listgetat(l,2,"=")>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select MEDIA_LABEL from CTMEDIA_LABEL where MEDIA_LABEL='#ln#'
			</cfquery>
			<cfif len(c.MEDIA_LABEL) is 0>
				<cfset rec_stat=listappend(rec_stat,'Media label #ln# is invalid',";")>
			<cfelse>
				<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into cf_temp_media_labels (
						key,
						MEDIA_LABEL,
						ASSIGNED_BY_AGENT_ID,
						LABEL_VALUE
					) values (
						#key#,
						'#ln#',
						#session.myAgentId#,
						'#lv#'
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
	<cfhttp url="#media_uri#" charset="utf-8" method="get" />
	<cfif left(cfhttp.statuscode,3) is not "200">
		<cfset rec_stat=listappend(rec_stat,'#media_uri# is invalid',";")>
	</cfif>
	<cfif len(preview_uri) gt 0>
		<cfhttp url="#preview_uri#" charset="utf-8" method="get" />
		<cfif left(cfhttp.statuscode,3) is not "200">
			<cfset rec_stat=listappend(rec_stat,'#preview_uri# is invalid',";")>
		</cfif>
	</cfif>
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
	Yay! Everything looks OK. Check it over in the tables below, then
	<a href="BulkloadMedia.cfm?action=load"><strong>click here</strong></a> to proceed.
	<br>^^^ that thing. You must click it.
	(Note that the table below is "flattened." Media entries are repeated for every Label and Relationship.)
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			cf_temp_media.key,
			status,
			MEDIA_URI,
			MIME_TYPE,
			MEDIA_TYPE,
			PREVIEW_URI,
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
			<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media (media_id,media_uri,mime_type,media_type,preview_uri, MEDIA_LICENSE_ID)
	            values (#media_id#,'#escapeQuotes(media_uri)#','#mime_type#','#media_type#','#preview_uri#', 1)
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
