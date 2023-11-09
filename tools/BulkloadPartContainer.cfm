<!------------------------------
CREATE OR REPLACE TRIGGER cf_temp_barcode_parts_key
 before insert  ON cf_temp_barcode_parts
 for each row
    begin
    	if :NEW.key is null then
    		select somerandomsequence.nextval into :new.key from dual;
    	end if;
    end;
/
sho err
		create table cf_temp_barcode_parts (
			 KEY number not null,
			 OTHER_ID_TYPE varchar2(255),
			 OTHER_ID_NUMBER varchar2(60),
			 COLLECTION_CDE varchar2(20),
			 INSTITUTION_ACRONYM varchar2(20),
			 part_name varchar2(255),
			 barcode varchar2(255),
			 COLLECTION_OBJECT_ID number,
			 container_id number
			 );
		CREATE PUBLIC SYNONYM cf_temp_barcode_parts FOR cf_temp_barcode_parts;
		GRANT select,insert,update,delete ON cf_temp_barcode_parts to manage_container;

		alter table cf_temp_barcode_parts add status varchar2(255);
		alter table cf_temp_barcode_parts add parent_container_id number;
		alter table cf_temp_barcode_parts add part_container_id number;
------------------------------------->
<cfinclude template="/includes/_header.cfm">
    <div style="width: 56em; margin: 0 auto; padding: 1em 0 3em 0;">
<cfif action is "makeTemplate">
	<cfset header="OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_CDE,INSTITUTION_ACRONYM,PART_NAME,PRESERVE_METHOD,CONTAINER_UNIQUE_ID">
	<cffile action = "write"
    file = "#Application.webDirectory#/download/BulkPartContainer.csv"
    output = "#header#"
    addNewLine = "no">
	<cflocation url="/download.cfm?file=BulkPartContainer.csv" addtoken="false">
</cfif>
<cfif action is  "nothing">
    <h3 class="wikilink">Bulkload Part Containers</h3>
	<p>Use this form to put collection objects (that is, parts) in containers. Parts and containers must already exist. This form can be used for specimen records with multiple parts as long as the full names (name plus preserve method) of the parts are unique.</p>
    <p style="margin: .5em 0;"><a href="BulkloadPartContainer.cfm?action=makeTemplate">Download a CSV template</a></p>
	<p>Columns in red are required:</p>
	<ul class="geol_hier">

        <li style="color: red;">other_id_type
          <ul>
             <li style="color: black;">"catalog number" is also a valid other_id_type</li>
		     <li style="color: black;"><a href="/info/ctDocumentation.cfm?table=ctcoll_other_id_type" target="_blank">other_id_type values list</a></li>
          </ul>
		</li>
		<li style="color: red;">other_id_number</li>
		<li style="color: red;">Collection_Cde</li>
    <li style="color: red;">Institution_Acronym  <span style="color:black;">(case-sensitive, e.g., "MCZ")</span></li>

		<li style="color: red;">
			Part_Name
			<!--<br><a href="/info/ctDocumentation.cfm?table=ctspecimen_part_name" target="_blank">part_name values</a>-->
		</li>
		<li style="color: red">
			Preserve_Method

		</li>
		<li style="color: red">container_unique_id
            <ul style="color: black;"><li>is the unique id of the container into which you want to place the part</li></ul>

        </li>
		<!---li style="color: red">
			new_container_type
            <ul style="color:black;"><li>the container type into which you wish to place the part may be a label of some sort</li>
                <li>container must already exist in MCZbase</li>
                <li><a href="/info/ctDocumentation.cfm?table=ctcontainer_type" target="_blank">valid container type list</a></li></ul>

		</li--->
	</ul>

	<cfform name="getFile" method="post" action="BulkloadPartContainer.cfm" enctype="multipart/form-data">
		<input type="hidden" name="action" value="getFileData">
		 <input type="file"
			   name="FiletoUpload"
			   size="45">
		<input type="submit" value="Upload this file" class="savBtn">
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
<!---------------------------------------------------------------------->
  <cfif action is "getFileData">
<cfoutput>
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from cf_temp_barcode_parts
	</cfquery>
	<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="#cSet#">
	<cfset fileContent=replace(fileContent,"'","''","all")>
	<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
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
				insert into cf_temp_barcode_parts (#colNames#) values (#preservesinglequotes(colVals)#)
			</cfquery>
		</cfif>
	</cfloop>
	<cflocation url="BulkloadPartContainer.cfm?action=validateFromFile">
</cfoutput>
</cfif>
<!--------------------------------------------------------------------------->
<cfif action is "validateFromFile">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select KEY,
			trim(INSTITutION_ACRONYM) INSTITUTION_ACRONYM,
			trim(COLLECTION_CDE) COLLECTION_CDE,
			trim(OTHER_ID_TYPE) OTHER_ID_TYPE,
			trim(OTHER_ID_NUMBER) oidNum,
			trim(part_name) part_name,
			trim(preserve_method) preserve_method,
			trim(container_unique_id) container_unique_id,
			print_fg
		from
			cf_temp_barcode_parts
	</cfquery>
	<!---cfquery name="goodContainers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_barcode_parts set status='bad_container_type'
		where new_container_type NOT IN (
			select container_type from ctcontainer_type)
	</cfquery--->
	<cfoutput>
		<cfloop query="data">
			<cfset sts=''>
			<cfif other_id_type is "catalog number">
				<cfquery name="coll_obj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select specimen_part.collection_object_id FROM
						cataloged_item,
						specimen_part,
						collection
					WHERE
						cataloged_item.collection_object_id = specimen_part.derived_from_cat_item AND
						cataloged_item.collection_id = collection.collection_id AND
						collection.COLLECTION_CDE='#COLLECTION_CDE#' AND
						collection.INSTITutION_ACRONYM = '#INSTITutION_ACRONYM#' AND
						cat_num='#oidnum#' AND
						part_name='#part_name#' AND
						preserve_method = '#preserve_method#'
				</cfquery>
			<cfelse>
				<cfquery name="coll_obj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select specimen_part.collection_object_id FROM
						cataloged_item,
						specimen_part,
						coll_obj_other_id_num,
						collection
					WHERE
						cataloged_item.collection_object_id = specimen_part.derived_from_cat_item AND
						cataloged_item.collection_object_id = coll_obj_other_id_num.collection_object_id AND
						cataloged_item.collection_id = collection.collection_id AND
						collection.COLLECTION_CDE='#COLLECTION_CDE#' AND
						collection.INSTITutION_ACRONYM = '#INSTITutION_ACRONYM#' AND
						other_id_type='#other_id_type#' AND
						display_value= '#oidnum#' AND
						part_name='#part_name#' AND
						preserve_method = '#preserve_method#'
				</cfquery>
			</cfif>
			<cfif coll_obj.recordcount is not 1>
				<cfset sts='item_not_found'>
			</cfif>
			<!--- see if they gave a valid parent container ---->
			<cfquery name="isGoodParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select container_id from container where container_type <> 'collection object'
				and barcode='#container_unique_id#'
			</cfquery>
			<cfif isGoodParent.recordcount is not 1>
				<cfset sts='container_unique_id_not_found'>
			</cfif>
			<cfif sts is ''>
				<cfquery name="cont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select container_id FROM coll_obj_cont_hist where
					collection_object_id=#coll_obj.collection_object_id#
				</cfquery>
				<cfif len(cont.container_id) is 0>
					<cfset sts='part_container_not_found'>
				</cfif>
			</cfif>
			<cfif sts is ''>
				<cfquery name="setter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_barcode_parts set
						parent_container_id=#isGoodParent.container_id#,
						part_container_id=#cont.container_id#
					where key=#key#
				</cfquery>
			<cfelse>
				<cfquery name="ssetter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_barcode_parts set
						status='#sts#'
					where key=#key#
				</cfquery>
			</cfif>
		</cfloop>
	</cfoutput>
	<cflocation url="BulkloadPartContainer.cfm?action=load">
</cfif>
<cfif action is "load">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_barcode_parts
	</cfquery>
	<cfif len(valuelist(d.status,'')) gt 0>
		Fix this and reload - nothing's been saved.
		<cfdump var=#d#>
	<cfelse>
		<cftransaction>
			<cfloop query="d">
				<!---cfquery name="flagIT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update
						container
					set
						container_type='#NEW_CONTAINER_TYPE#'
					where
						container_id = #parent_container_id#
				</cfquery--->
				<cfquery name="moveIt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE
						container
					SET
						parent_container_id = #parent_container_id#
					 WHERE
					container_id=#part_container_id#
				</cfquery>
			</cfloop>
		</cftransaction>
		woo hoo, it worked
	</cfif>
</cfif>
        </div>
<!------------------------------------------------------------------->
<cfinclude template="/includes/_footer.cfm"/>
