<!--- tools/BulkPartSample.cfm bulk create subsamples,
   Decrements parent part lot count by one and creates a new part
	sampled from that parent.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2025 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
	
<!---- relies on table

drop table cf_temp_part_sample;

CREATE TABLE cf_temp_part_sample (
	r$institution_acronym VARCHAR2(60),
	r$collection_cde VARCHAR2(60),
	r$OTHER_ID_TYPE VARCHAR2(60),
 	r$OTHER_ID_NUMBER VARCHAR2(60),
 	r$exist_part_name VARCHAR2(60),
	exist_part_modifier VARCHAR2(60),
	exist_preserve_method VARCHAR2(60),
	r$sample_name varchar2(60),
	sample_modifier varchar2(60),
	sample_preserve_method varchar2(60),
	r$sample_disposition VARCHAR2(60),
	r$sample_condition VARCHAR2(60),
	r$sample_label varchar2(60),
	sample_barcode varchar2(60),
	sample_remarks VARCHAR2(60),
	i$validated_status varchar2(255),
	r$sample_container_type varchar2(255),
	i$collection_object_id NUMBER,
	i$KEY NUMBER NOT NULL,
	i$exist_part_id number,
	i$container_id number
	);
	
	comment on column cf_temp_part_sample.r$OTHER_ID_TYPE is '"catalog number" is a valid other_id_type';
	
alter table cf_temp_part_sample rename column sample_barcode to r$sample_barcode;

create or replace public synonym cf_temp_part_sample for cf_temp_part_sample;
grant all on cf_temp_part_sample to manage_specimens;

CREATE OR REPLACE TRIGGER cf_temp_part_sample_key                                         
 before insert  ON cf_temp_part_sample  
 for each row 
    begin     
    	if :NEW.i$key is null then                                                                                      
    		select somerandomsequence.nextval into :new.i$key from dual;
    	end if;                                
    end;                                                                                            
/
sho err
---->
<cfif isDefined("url.action")><cfset variables.action = url.action></cfif>
<cfif isDefined("form.action")><cfset variables.action = form.action></cfif>
<cfif len(variables.action) EQ 0>
	<cfset variables.action = "entryPoint">
</cfif>

<cfinclude template="/includes/_header.cfm">
<cfinclude template="/shared/component/stagingTables.cfc" runOnce="true">

<cfoutput>
	<cfswitch expression="#variables.action#">
		<cfcase value="entryPoint">
			<cfquery name="template" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT column_name, comments 
				FROM all_col_comments 
				WHERE lower(table_name) = 'cf_temp_part_sample'
			</cfquery>
			Step 1: Upload a comma-delimited text file (csv). 
			Include all column headings, spelled exactly as below, or use the following template.
			Columns that begin with r$ are required; others are optional:
			<ul>
				<cfset cols="">
				<cfloop query="template">
					<cfif left(column_name,2) is not 'i$'>
						<cfset cols=listappend(cols,column_name)>
						<li <cfif left(column_name,2) is "r$">  style="color:red"</cfif>>#column_name#
							<cfif len(comments) gt 0>
							<br><span style="padding-left:20px;font-size:small">#comments#</span></cfif>
						</li>
					</cfif>	
				</cfloop>
			</ul>
			<br>
			<div id="template">
				<label for="t">CSV Template</label>
				<textarea rows="2" cols="80" id="t">#cols#</textarea>
			</div> 
			<p></p>
			<label for="atts">Upload a CSV file</label>
			<cfform name="atts" method="post" enctype="multipart/form-data" action="BulkPartSample.cfm">
				<input type="hidden" name="Action" value="getFile">
				<input type="file" name="FiletoUpload" size="45">
				<input type="submit" value="Upload this file" class="savBtn" onmouseover="this.className='savBtn btnhov'" onmouseout="this.className='savBtn'">
			</cfform>
		</cfcase>
		<!------------------------------------------------------->
		<cfcase value="getFile">
			<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
			<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />

			<!--- TODO: add user column to cf_temp_part_sample --->
			<cfquery name="die" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE FROM cf_temp_part_sample
			</cfquery>

			<!--- only headers that are columns of the staging table are loaded; spreadsheets often carry other columns, and those are ignored --->
			<cfset variables.usable = usableHeaders(arrResult[1], "cf_temp_part_sample")>
			<cfif arrayLen(variables.usable.columns) EQ 0>
				No column of the file matches a column of the part sample staging table, so nothing was loaded.
				<cfabort>
			</cfif>
			<cfloop from="2" to="#ArrayLen(arrResult)#" index="o">
				<cfif NOT isBlankRow(arrResult[o])>
					<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="ins_result">
						INSERT INTO cf_temp_part_sample (#columnNameList(variables.usable.columns)#)
						VALUES (
							<cfloop from="1" to="#arrayLen(variables.usable.columns)#" index="i">
								<cfif i GT 1>,</cfif>
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cellValue(arrResult[o], variables.usable.columns[i].position)#">
							</cfloop>
						)
					</cfquery>
				</cfif>
			</cfloop>
			<cflocation url="BulkPartSample.cfm?action=validate">
		</cfcase>
		<!------------------------------------------------------->
		<cfcase value="validate">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT * 
				FROM cf_temp_part_sample
			</cfquery>
			<cfloop query="d">
				<cfset status="">
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) c 
					FROM ctspecimen_part_name 
					WHERE part_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$SAMPLE_NAME#"> 
						and collection_cde=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$COLLECTION_CDE#">
				</cfquery>
				<cfif bads.c is not 1>
					<cfset status=listappend(status,'bad R$SAMPLE_NAME')>
				</cfif>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) c 
					FROM ctspecimen_part_name 
					WHERE part_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$EXIST_PART_NAME#"> 
						and collection_cde=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$COLLECTION_CDE#">
				</cfquery>
				<cfif bads.c is not 1>
					<cfset status=listappend(status,'bad R$EXIST_PART_NAME')>
				</cfif>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) c 
					FROM CTCOLL_OBJ_DISP 
					WHERE COLL_OBJ_DISPOSITION=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$SAMPLE_DISPOSITION#">
				</cfquery>
				<cfif bads.c is not 1>
					<cfset status=listappend(status,'bad R$SAMPLE_DISPOSITION')>
				</cfif>
				
				<cfif #R$OTHER_ID_TYPE# is "catalog number">
					<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
							collection_object_id
						FROM
							cataloged_item,
							collection
						WHERE
							cataloged_item.collection_id = collection.collection_id and
							collection.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$COLLECTION_CDE#"> and
							collection.institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$INSTITUTION_ACRONYM#"> and
							cat_num=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$OTHER_ID_NUMBER#">
					</cfquery>
				<cfelse>
					<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
							coll_obj_other_id_num.collection_object_id
						FROM
							coll_obj_other_id_num,
							cataloged_item,
							collection
						WHERE
							coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id and
							cataloged_item.collection_id = collection.collection_id and
							collection.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$COLLECTION_CDE#"> and
							collection.institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$INSTITUTION_ACRONYM#"> and
							other_id_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$OTHER_ID_TYPE#"> and
							display_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$OTHER_ID_NUMBER#">
					</cfquery>
				</cfif>
				<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>			
					<cfset cat_item_id=collObj.collection_object_id>
				<cfelse>
					<cfset status=listappend(status,'cataloged item not found')>
					<cfset cat_item_id=-1>
				</cfif>
				<cfif len(R$SAMPLE_CONTAINER_TYPE) gt 0>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT count(*) c 
						FROM ctcontainer_type 
						WHERE container_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$SAMPLE_CONTAINER_TYPE#">
					</cfquery>
					<cfif bads.c is not 1>
						<cfset status=listappend(status,'bad R$SAMPLE_CONTAINER_TYPE')>
					</cfif>
				</cfif>
				<cfif len(R$SAMPLE_LABEL) is 0>
					<cfset status=listappend(status,'bad R$SAMPLE_LABEL')>
				</cfif>
				<cfif len(R$SAMPLE_CONDITION) is 0>
					<cfset status=listappend(status,'bad R$SAMPLE_CONDITION')>
				</cfif>
				<cfquery name="container" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT container_id 
					FROM container 
					WHERE barcode=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#R$SAMPLE_BARCODE#">
				</cfquery>
				<cfif container.recordcount is 1 and len(container.container_id) gt 0>
					<cfset container_id=container.container_id>
				<cfelse>
					<cfset container_id=-1>
					<cfset status=listappend(status,'bad R$SAMPLE_BARCODE')>
				</cfif>
		
				<cfquery name="pPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT min(collection_object_id)  collection_object_id
					FROM specimen_part 
					WHERE derived_from_cat_item=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#cat_item_id#"> and
						part_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#r$exist_part_name#">
				</cfquery>
				<cfif pPart.recordcount is 1 and len(pPart.collection_object_id) gt 0>
					<cfset partID=pPart.collection_object_id>
				<cfelse>
					<cfset partID=-1>
					<cfset status=listappend(status,'parent part not found')>
				</cfif>
				<cfquery name="status" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_part_sample 
					SET
						i$validated_status=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#status#">,
						i$collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#cat_item_id#">,
						i$exist_part_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">,
						i$container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#container_id#">
					WHERE i$KEY = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#i$KEY#">
				</cfquery>
			</cfloop>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT * 
				FROM cf_temp_part_sample
			</cfquery>
			<cfquery name="b" dbtype="query">
				SELECT count(*) c 
				FROM d 
				WHERE i$validated_status is not null
			</cfquery>
			<cfif b.c gt 0>
				You must clean up the #b.recordcount# rows with i$validated_status != NULL in this table before proceeding.
				<br>
				<cfdump var=#d#>
			<cfelse>
				<cflocation url="BulkPartSample.cfm?action=loadToDb">
			</cfif>
		</cfcase>
		<!-------------------------------------------------------------------------------------------->
		<cfcase value="loadToDb">
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT * 
				FROM cf_temp_part_sample
			</cfquery>
			<cftransaction>
			<cfloop query="getTempData">
				<cfquery name="pPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT *
					FROM specimen_part
						join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
					WHERE
						specimen_part.collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#i$exist_part_id#">
				</cfquery>
				<cfif pPart.lot_count lte 1>
					Parent lot count must be at least 1.
					<cfabort>
				<cfelse><!--- parent lot count check --->
					<cfquery name="lot_count" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE coll_object 
						SET lot_count=lot_count-1 
						WHERE collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#i$exist_part_id#">
					</cfquery>
					<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO coll_object (
							COLLECTION_OBJECT_ID,
							COLL_OBJECT_TYPE,
							ENTERED_PERSON_ID,
							COLL_OBJECT_ENTERED_DATE,
							COLL_OBJ_DISPOSITION,
							LOT_COUNT,
							CONDITION,
							FLAGS )
						VALUES (
							sq_collection_object_id.nextval,
							'SP',
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
							sysdate,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#r$sample_disposition#">,
							1,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#r$sample_condition#">,
							0
						)		
					</cfquery>
					<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO specimen_part (
							COLLECTION_OBJECT_ID,
							PART_NAME,
							DERIVED_FROM_cat_item,
							SAMPLED_FROM_OBJ_ID
						) VALUES (
							sq_collection_object_id.currval,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#r$sample_name#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#i$collection_object_id#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#i$exist_part_id#">
						)
					</cfquery>
					<cfif len(#sample_remarks#) gt 0>
						<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							INSERT INTO coll_object_remark (
								collection_object_id, 
								coll_object_remarks
							) VALUES (
								sq_collection_object_id.currval, 
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sample_remarks#">
							)
						</cfquery>
					</cfif>
					<cfquery name="pCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT container_id 
						FROM coll_obj_cont_hist 
						WHERE collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextID.nextID#">
					</cfquery>
					<cfquery name="upCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE container 
						SET parent_container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#i$container_id#"> 
						WHERE container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#pCont.container_id#">
					</cfquery>
					<cfquery name="upCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE container 
						SET label=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#r$sample_label#">,
							container_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#r$sample_container_type#"> 
						WHERE container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#i$container_id#">
					</cfquery>	
				</cfif><!--- parent lot count check --->
			</cfloop>
			</cftransaction>
			Spiffy, all done.
			<a href="/SpecimenResults.cfm?collection_object_id=#valuelist(getTempData.i$collection_object_id)#">
				See in Specimen Results
			</a>
		</cfcase>
	</cfswitch>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
