<cfinclude template="/includes/_header.cfm">

<cfset title="Bulkload Specimens">
<cfif #action# is "nothing">
 <div class="basic_box">
    <div class="BulkSpec">
           <h2 class="wikilink">Load your .csv file.</h2>
        <p>Upload a comma-delimited text file (csv).</p>
        <p>If your text file does not load, you can build templates that will load using the <a href="/Bulkloader/bulkloaderBuilder.cfm">Bulkloader Builder</a>.</p>

        <br><br>
<cfform name="oids" method="post" enctype="multipart/form-data">
	<input type="hidden" name="Action" value="getFile">
	  <cfinput type="file" name="FiletoUpload" size="45" >
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
    </div>
</cfif>
    </div>
<!------------------------------------------------------->
<cfif #action# is "getFile">
<cfoutput>
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from bulkloader_stage
	</cfquery>
	<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="#cSet#">
	<!---cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="utf-8"--->
	<cfset fileContent=replace(fileContent,"'","''","all")>
	<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
	<cfset colNames="">
	<cfloop from="1" to ="#ArrayLen(arrResult)#" index="o">
		<cfset colVals="">
			<cfloop from="1"  to ="#ArrayLen(arrResult[o])#" index="i">
				<cfset thisBit=trim(arrResult[o][i])>
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
				insert into bulkloader_stage (#colNames#) values (#preservesinglequotes(colVals)#)
			</cfquery>
		</cfif>
	</cfloop>
	<cflocation url="BulkloadSpecimens.cfm?action=validate" addtoken="false">
</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif #action# is "validate">
     <div class="basic_wide_box">
<cfoutput>
	<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as cnt from bulkloader_stage
	</cfquery>
    <h3>Success!</h3>
    <p>You successfully loaded #c.cnt# records into the <em><strong>staging</strong></em> table.
	They have not been checked or processed yet. You aren't done here!</p>

	<ul class="geol_hier">
		<li>
			<a href="BulkloadSpecimens.cfm?action=checkStaged" target="_self">Check and load these records</a>.
			This is a slow process, but completing it will allow you to fix problems in the data in your csv file and re-load your data as necessary.
			Email a DBA if you wish to check your records at this stage but the process times out. We can schedule
			the process, allowing it to take as long as necessary to complete, and notify you when it's done.
			This method is strongly preferred.
		</li>
		<li>
			<a href="BulkloadSpecimens.cfm?action=loadAnyway" target="_self">Just load these records</a>.
			Use this method if you wish to use Arctos' tools to fix any errors. Everything will go to the normal
			Bulkloader tables and be available via <a href="/Bulkloader/browseBulk.cfm">the Browse Bulk app</a>.
			You need a thorough understanding of Arctos' bulkloader tools and great confidence in your data
			to use this application. Misuse can result in
			a huge mess in the Bulkloader, which may require sorting out record by record.
		</li>
	</ul>
</cfoutput>
    </div>
</cfif>
<!------------------------------------------------------->
<cfif #action# is "loadAnyway">
<cfoutput>
	<cfquery name="allId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select collection_object_id from bulkloader_stage
	</cfquery>
	<cfloop query="allId">
		<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update bulkloader_stage set collection_object_id=bulkloader_pkey.nextval
			where collection_object_id=#collection_object_id#
		</cfquery>
	</cfloop>
	<cfquery name="flag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update bulkloader_stage set loaded = 'BULKLOADED RECORD'
	</cfquery>
	<!---cfquery name="moveEm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		insert into bulkloader(COLLECTOR_ROLE_1,COLLECTOR_AGENT_1,COLL_EVENT_REMARKS,HABITAT_DESC,LOCALITY_REMARKS,ORIG_ELEV_UNITS,MINIMUM_ELEVATION,MAXIMUM_ELEVATION,VERIFICATIONSTATUS,LAT_LONG_REMARKS,DETERMINED_DATE,DETERMINED_BY_AGENT,GEOREFMETHOD,MAX_ERROR_UNITS,MAX_ERROR_DISTANCE,LAT_LONG_REF_SOURCE,DATUM,LONGDIR,LONGSEC,LONGMIN,DEC_LONG_MIN,LONGDEG,LATDIR,LATSEC,LATMIN,DEC_LAT_MIN,LATDEG,DEC_LONG,DEC_LAT,ORIG_LAT_LONG_UNITS,VERBATIM_LOCALITY,verbatimdepth,verbatimelevation,SPEC_LOCALITY,HIGHER_GEOG,ENDED_DATE,BEGAN_DATE,VERBATIM_DATE,IDENTIFICATION_REMARKS,MADE_DATE,ID_MADE_BY_AGENT,NATURE_OF_ID,TAXON_NAME,ACCN,OTHER_ID_NUM_TYPE_1,OTHER_ID_NUM_1,OTHER_ID_NUM_TYPE_5,OTHER_ID_NUM_5,ENTEREDBY,LOADED,COLLECTION_OBJECT_ID,COLLECTING_EVENT_ID,PRESERV_METHOD_9,PART_NAME_9,PART_REMARK_8,PART_DISPOSITION_8,PART_LOT_COUNT_8,PART_CONTAINER_LABEL_8,PART_BARCODE_8,PART_CONDITION_8,PRESERV_METHOD_8,PART_NAME_8,PART_REMARK_7,PART_DISPOSITION_7,PART_LOT_COUNT_7,PART_CONTAINER_LABEL_7,PART_BARCODE_7,PART_CONDITION_7,PRESERV_METHOD_7,PART_NAME_7,PART_REMARK_6,PART_DISPOSITION_6,PART_LOT_COUNT_6,PART_CONTAINER_LABEL_6,PART_BARCODE_6,PART_CONDITION_6,PRESERV_METHOD_6,PART_NAME_6,PART_REMARK_5,PART_DISPOSITION_5,PART_LOT_COUNT_5,PART_CONTAINER_LABEL_5,PART_BARCODE_5,PART_CONDITION_5,PRESERV_METHOD_5,PART_NAME_5,PART_REMARK_4,PART_DISPOSITION_4,PART_LOT_COUNT_4,PART_CONTAINER_LABEL_4,PART_BARCODE_4,PART_CONDITION_4,PRESERV_METHOD_4,PART_NAME_4,PART_REMARK_3,PART_DISPOSITION_3,PART_LOT_COUNT_3,PART_CONTAINER_LABEL_3,PART_BARCODE_3,PART_CONDITION_3,PRESERV_METHOD_3,PART_NAME_3,PART_REMARK_2,PART_DISPOSITION_2,PART_LOT_COUNT_2,PART_CONTAINER_LABEL_2,PART_BARCODE_2,PART_CONDITION_2,PRESERV_METHOD_2,PART_NAME_2,PART_REMARK_1,PART_DISPOSITION_1,PART_LOT_COUNT_1,PART_CONTAINER_LABEL_1,PART_BARCODE_1,PART_CONDITION_1,PRESERV_METHOD_1,PART_NAME_1,OTHER_ID_NUM_TYPE_4,OTHER_ID_NUM_4,OTHER_ID_NUM_TYPE_3,OTHER_ID_NUM_3,OTHER_ID_NUM_TYPE_2,OTHER_ID_NUM_2,DISPOSITION_REMARKS,COLL_OBJECT_REMARKS,CONDITION,COLL_OBJ_DISPOSITION,FLAGS,INSTITUTION_ACRONYM,COLLECTION_CDE,COLLECTOR_ROLE_8,COLLECTOR_AGENT_8,COLLECTOR_ROLE_7,COLLECTOR_AGENT_7,COLLECTOR_ROLE_6,COLLECTOR_AGENT_6,COLLECTOR_ROLE_5,COLLECTOR_AGENT_5,COLLECTOR_ROLE_4,COLLECTOR_AGENT_4,COLLECTOR_ROLE_3,COLLECTOR_AGENT_3,COLLECTOR_ROLE_2,COLLECTOR_AGENT_2,ATTRIBUTE_UNITS_10,ATTRIBUTE_VALUE_10,ATTRIBUTE_10,ATTRIBUTE_DETERMINER_9,ATTRIBUTE_DET_METH_9,ATTRIBUTE_DATE_9,ATTRIBUTE_REMARKS_9,ATTRIBUTE_UNITS_9,ATTRIBUTE_VALUE_9,ATTRIBUTE_9,ATTRIBUTE_DETERMINER_8,ATTRIBUTE_DET_METH_8,ATTRIBUTE_DATE_8,ATTRIBUTE_REMARKS_8,ATTRIBUTE_UNITS_8,ATTRIBUTE_VALUE_8,ATTRIBUTE_8,ATTRIBUTE_DETERMINER_7,ATTRIBUTE_DET_METH_7,ATTRIBUTE_DATE_7,ATTRIBUTE_REMARKS_7,ATTRIBUTE_UNITS_7,ATTRIBUTE_VALUE_7,ATTRIBUTE_7,ATTRIBUTE_DETERMINER_6,ATTRIBUTE_DET_METH_6,ATTRIBUTE_DATE_6,ATTRIBUTE_REMARKS_6,ATTRIBUTE_UNITS_6,ATTRIBUTE_VALUE_6,ATTRIBUTE_6,ATTRIBUTE_DETERMINER_5,ATTRIBUTE_DET_METH_5,ATTRIBUTE_DATE_5,ATTRIBUTE_REMARKS_5,ATTRIBUTE_UNITS_5,ATTRIBUTE_VALUE_5,ATTRIBUTE_5,ATTRIBUTE_DETERMINER_4,ATTRIBUTE_DET_METH_4,ATTRIBUTE_DATE_4,ATTRIBUTE_REMARKS_4,ATTRIBUTE_UNITS_4,ATTRIBUTE_VALUE_4,ATTRIBUTE_4,ATTRIBUTE_DETERMINER_3,ATTRIBUTE_DET_METH_3,ATTRIBUTE_DATE_3,ATTRIBUTE_REMARKS_3,ATTRIBUTE_UNITS_3,ATTRIBUTE_VALUE_3,ATTRIBUTE_3,ATTRIBUTE_DETERMINER_2,ATTRIBUTE_DET_METH_2,ATTRIBUTE_DATE_2,ATTRIBUTE_REMARKS_2,ATTRIBUTE_UNITS_2,ATTRIBUTE_VALUE_2,ATTRIBUTE_2,ATTRIBUTE_DETERMINER_1,ATTRIBUTE_DET_METH_1,ATTRIBUTE_DATE_1,ATTRIBUTE_REMARKS_1,ATTRIBUTE_UNITS_1,ATTRIBUTE_VALUE_1,ATTRIBUTE_1,PART_REMARK_12,PART_DISPOSITION_12,PART_LOT_COUNT_12,PART_CONTAINER_LABEL_12,PART_BARCODE_12,PART_CONDITION_12,PRESERV_METHOD_12,PART_NAME_12,PART_REMARK_11,PART_DISPOSITION_11,PART_LOT_COUNT_11,PART_CONTAINER_LABEL_11,PART_BARCODE_11,PART_CONDITION_11,PRESERV_METHOD_11,PART_NAME_11,PART_REMARK_10,PART_DISPOSITION_10,PART_LOT_COUNT_10,PART_CONTAINER_LABEL_10,PART_BARCODE_10,PART_CONDITION_10,PRESERV_METHOD_10,PART_NAME_10,PART_REMARK_9,PART_DISPOSITION_9,PART_LOT_COUNT_9,PART_CONTAINER_LABEL_9,PART_BARCODE_9,PART_CONDITION_9,CAT_NUM,CATALOG_NUMBER_SUFFIX,CATALOG_NUMBER,CATALOG_NUMBER_PREFIX,GEO_ATT_REMARK_6,GEO_ATT_DETERMINED_METHOD_6,GEO_ATT_DETERMINED_DATE_6,GEO_ATT_DETERMINER_6,GEO_ATT_VALUE_6,GEOLOGY_ATTRIBUTE_6,GEO_ATT_REMARK_5,GEO_ATT_DETERMINED_METHOD_5,GEO_ATT_DETERMINED_DATE_5,GEO_ATT_DETERMINER_5,GEO_ATT_VALUE_5,GEOLOGY_ATTRIBUTE_5,GEO_ATT_REMARK_4,GEO_ATT_DETERMINED_METHOD_4,GEO_ATT_DETERMINED_DATE_4,GEO_ATT_DETERMINER_4,GEO_ATT_VALUE_4,GEOLOGY_ATTRIBUTE_4,GEO_ATT_REMARK_3,GEO_ATT_DETERMINED_METHOD_3,GEO_ATT_DETERMINED_DATE_3,GEO_ATT_DETERMINER_3,GEO_ATT_VALUE_3,GEOLOGY_ATTRIBUTE_3,GEO_ATT_REMARK_2,GEO_ATT_DETERMINED_METHOD_2,GEO_ATT_DETERMINED_DATE_2,GEO_ATT_DETERMINER_2,GEO_ATT_VALUE_2,GEOLOGY_ATTRIBUTE_2,GEO_ATT_REMARK_1,GEO_ATT_DETERMINED_METHOD_1,GEO_ATT_DETERMINED_DATE_1,GEO_ATT_DETERMINER_1,GEO_ATT_VALUE_1,GEOLOGY_ATTRIBUTE_1,GPSACCURACY,EXTENT,UTM_NS,UTM_EW,UTM_ZONE,LOCALITY_ID,ASSOCIATED_SPECIES,COLL_OBJECT_HABITAT,COLLECTING_SOURCE,COLLECTING_METHOD,STATION_NUMBER,STATION_NAME,VESSEL,DEPTH_UNITS,MAX_DEPTH,MIN_DEPTH,RELATED_TO_NUM_TYPE,RELATED_TO_NUMBER,RELATIONSHIP,ATTRIBUTE_DETERMINER_10,ATTRIBUTE_DET_METH_10,ATTRIBUTE_DATE_10,ATTRIBUTE_REMARKS_10,PART_LOT_CNT_MOD_1,PART_LOT_CNT_MOD_2,PART_LOT_CNT_MOD_3,PART_LOT_CNT_MOD_4,PART_LOT_CNT_MOD_5,PART_LOT_CNT_MOD_6,PART_LOT_CNT_MOD_7,PART_LOT_CNT_MOD_8,PART_LOT_CNT_MOD_9,PART_LOT_CNT_MOD_10,PART_LOT_CNT_MOD_11,PART_LOT_CNT_MOD_12,MASK_RECORD)
		(select COLLECTOR_ROLE_1,COLLECTOR_AGENT_1,COLL_EVENT_REMARKS,HABITAT_DESC,LOCALITY_REMARKS,ORIG_ELEV_UNITS,MINIMUM_ELEVATION,MAXIMUM_ELEVATION,VERIFICATIONSTATUS,LAT_LONG_REMARKS,DETERMINED_DATE,DETERMINED_BY_AGENT,GEOREFMETHOD,MAX_ERROR_UNITS,MAX_ERROR_DISTANCE,LAT_LONG_REF_SOURCE,DATUM,LONGDIR,LONGSEC,LONGMIN,DEC_LONG_MIN,LONGDEG,LATDIR,LATSEC,LATMIN,DEC_LAT_MIN,LATDEG,DEC_LONG,DEC_LAT,ORIG_LAT_LONG_UNITS,VERBATIM_LOCALITY,verbatimdepth,verbatimelevation,SPEC_LOCALITY,HIGHER_GEOG,ENDED_DATE,BEGAN_DATE,VERBATIM_DATE,IDENTIFICATION_REMARKS,MADE_DATE,ID_MADE_BY_AGENT,NATURE_OF_ID,TAXON_NAME,ACCN,OTHER_ID_NUM_TYPE_1,OTHER_ID_NUM_1,OTHER_ID_NUM_TYPE_5,OTHER_ID_NUM_5,ENTEREDBY,LOADED,COLLECTION_OBJECT_ID,COLLECTING_EVENT_ID,PRESERV_METHOD_9,PART_NAME_9,PART_REMARK_8,PART_DISPOSITION_8,PART_LOT_COUNT_8,PART_CONTAINER_LABEL_8,PART_BARCODE_8,PART_CONDITION_8,PRESERV_METHOD_8,PART_NAME_8,PART_REMARK_7,PART_DISPOSITION_7,PART_LOT_COUNT_7,PART_CONTAINER_LABEL_7,PART_BARCODE_7,PART_CONDITION_7,PRESERV_METHOD_7,PART_NAME_7,PART_REMARK_6,PART_DISPOSITION_6,PART_LOT_COUNT_6,PART_CONTAINER_LABEL_6,PART_BARCODE_6,PART_CONDITION_6,PRESERV_METHOD_6,PART_NAME_6,PART_REMARK_5,PART_DISPOSITION_5,PART_LOT_COUNT_5,PART_CONTAINER_LABEL_5,PART_BARCODE_5,PART_CONDITION_5,PRESERV_METHOD_5,PART_NAME_5,PART_REMARK_4,PART_DISPOSITION_4,PART_LOT_COUNT_4,PART_CONTAINER_LABEL_4,PART_BARCODE_4,PART_CONDITION_4,PRESERV_METHOD_4,PART_NAME_4,PART_REMARK_3,PART_DISPOSITION_3,PART_LOT_COUNT_3,PART_CONTAINER_LABEL_3,PART_BARCODE_3,PART_CONDITION_3,PRESERV_METHOD_3,PART_NAME_3,PART_REMARK_2,PART_DISPOSITION_2,PART_LOT_COUNT_2,PART_CONTAINER_LABEL_2,PART_BARCODE_2,PART_CONDITION_2,PRESERV_METHOD_2,PART_NAME_2,PART_REMARK_1,PART_DISPOSITION_1,PART_LOT_COUNT_1,PART_CONTAINER_LABEL_1,PART_BARCODE_1,PART_CONDITION_1,PRESERV_METHOD_1,PART_NAME_1,OTHER_ID_NUM_TYPE_4,OTHER_ID_NUM_4,OTHER_ID_NUM_TYPE_3,OTHER_ID_NUM_3,OTHER_ID_NUM_TYPE_2,OTHER_ID_NUM_2,DISPOSITION_REMARKS,COLL_OBJECT_REMARKS,CONDITION,COLL_OBJ_DISPOSITION,FLAGS,INSTITUTION_ACRONYM,COLLECTION_CDE,COLLECTOR_ROLE_8,COLLECTOR_AGENT_8,COLLECTOR_ROLE_7,COLLECTOR_AGENT_7,COLLECTOR_ROLE_6,COLLECTOR_AGENT_6,COLLECTOR_ROLE_5,COLLECTOR_AGENT_5,COLLECTOR_ROLE_4,COLLECTOR_AGENT_4,COLLECTOR_ROLE_3,COLLECTOR_AGENT_3,COLLECTOR_ROLE_2,COLLECTOR_AGENT_2,ATTRIBUTE_UNITS_10,ATTRIBUTE_VALUE_10,ATTRIBUTE_10,ATTRIBUTE_DETERMINER_9,ATTRIBUTE_DET_METH_9,ATTRIBUTE_DATE_9,ATTRIBUTE_REMARKS_9,ATTRIBUTE_UNITS_9,ATTRIBUTE_VALUE_9,ATTRIBUTE_9,ATTRIBUTE_DETERMINER_8,ATTRIBUTE_DET_METH_8,ATTRIBUTE_DATE_8,ATTRIBUTE_REMARKS_8,ATTRIBUTE_UNITS_8,ATTRIBUTE_VALUE_8,ATTRIBUTE_8,ATTRIBUTE_DETERMINER_7,ATTRIBUTE_DET_METH_7,ATTRIBUTE_DATE_7,ATTRIBUTE_REMARKS_7,ATTRIBUTE_UNITS_7,ATTRIBUTE_VALUE_7,ATTRIBUTE_7,ATTRIBUTE_DETERMINER_6,ATTRIBUTE_DET_METH_6,ATTRIBUTE_DATE_6,ATTRIBUTE_REMARKS_6,ATTRIBUTE_UNITS_6,ATTRIBUTE_VALUE_6,ATTRIBUTE_6,ATTRIBUTE_DETERMINER_5,ATTRIBUTE_DET_METH_5,ATTRIBUTE_DATE_5,ATTRIBUTE_REMARKS_5,ATTRIBUTE_UNITS_5,ATTRIBUTE_VALUE_5,ATTRIBUTE_5,ATTRIBUTE_DETERMINER_4,ATTRIBUTE_DET_METH_4,ATTRIBUTE_DATE_4,ATTRIBUTE_REMARKS_4,ATTRIBUTE_UNITS_4,ATTRIBUTE_VALUE_4,ATTRIBUTE_4,ATTRIBUTE_DETERMINER_3,ATTRIBUTE_DET_METH_3,ATTRIBUTE_DATE_3,ATTRIBUTE_REMARKS_3,ATTRIBUTE_UNITS_3,ATTRIBUTE_VALUE_3,ATTRIBUTE_3,ATTRIBUTE_DETERMINER_2,ATTRIBUTE_DET_METH_2,ATTRIBUTE_DATE_2,ATTRIBUTE_REMARKS_2,ATTRIBUTE_UNITS_2,ATTRIBUTE_VALUE_2,ATTRIBUTE_2,ATTRIBUTE_DETERMINER_1,ATTRIBUTE_DET_METH_1,ATTRIBUTE_DATE_1,ATTRIBUTE_REMARKS_1,ATTRIBUTE_UNITS_1,ATTRIBUTE_VALUE_1,ATTRIBUTE_1,PART_REMARK_12,PART_DISPOSITION_12,PART_LOT_COUNT_12,PART_CONTAINER_LABEL_12,PART_BARCODE_12,PART_CONDITION_12,PRESERV_METHOD_12,PART_NAME_12,PART_REMARK_11,PART_DISPOSITION_11,PART_LOT_COUNT_11,PART_CONTAINER_LABEL_11,PART_BARCODE_11,PART_CONDITION_11,PRESERV_METHOD_11,PART_NAME_11,PART_REMARK_10,PART_DISPOSITION_10,PART_LOT_COUNT_10,PART_CONTAINER_LABEL_10,PART_BARCODE_10,PART_CONDITION_10,PRESERV_METHOD_10,PART_NAME_10,PART_REMARK_9,PART_DISPOSITION_9,PART_LOT_COUNT_9,PART_CONTAINER_LABEL_9,PART_BARCODE_9,PART_CONDITION_9,CAT_NUM,CATALOG_NUMBER_SUFFIX,CATALOG_NUMBER,CATALOG_NUMBER_PREFIX,GEO_ATT_REMARK_6,GEO_ATT_DETERMINED_METHOD_6,GEO_ATT_DETERMINED_DATE_6,GEO_ATT_DETERMINER_6,GEO_ATT_VALUE_6,GEOLOGY_ATTRIBUTE_6,GEO_ATT_REMARK_5,GEO_ATT_DETERMINED_METHOD_5,GEO_ATT_DETERMINED_DATE_5,GEO_ATT_DETERMINER_5,GEO_ATT_VALUE_5,GEOLOGY_ATTRIBUTE_5,GEO_ATT_REMARK_4,GEO_ATT_DETERMINED_METHOD_4,GEO_ATT_DETERMINED_DATE_4,GEO_ATT_DETERMINER_4,GEO_ATT_VALUE_4,GEOLOGY_ATTRIBUTE_4,GEO_ATT_REMARK_3,GEO_ATT_DETERMINED_METHOD_3,GEO_ATT_DETERMINED_DATE_3,GEO_ATT_DETERMINER_3,GEO_ATT_VALUE_3,GEOLOGY_ATTRIBUTE_3,GEO_ATT_REMARK_2,GEO_ATT_DETERMINED_METHOD_2,GEO_ATT_DETERMINED_DATE_2,GEO_ATT_DETERMINER_2,GEO_ATT_VALUE_2,GEOLOGY_ATTRIBUTE_2,GEO_ATT_REMARK_1,GEO_ATT_DETERMINED_METHOD_1,GEO_ATT_DETERMINED_DATE_1,GEO_ATT_DETERMINER_1,GEO_ATT_VALUE_1,GEOLOGY_ATTRIBUTE_1,GPSACCURACY,EXTENT,UTM_NS,UTM_EW,UTM_ZONE,LOCALITY_ID,ASSOCIATED_SPECIES,COLL_OBJECT_HABITAT,COLLECTING_SOURCE,COLLECTING_METHOD,STATION_NUMBER,STATION_NAME,VESSEL,DEPTH_UNITS,MAX_DEPTH,MIN_DEPTH,RELATED_TO_NUM_TYPE,RELATED_TO_NUMBER,RELATIONSHIP,ATTRIBUTE_DETERMINER_10,ATTRIBUTE_DET_METH_10,ATTRIBUTE_DATE_10,ATTRIBUTE_REMARKS_10,PART_LOT_CNT_MOD_1,PART_LOT_CNT_MOD_2,PART_LOT_CNT_MOD_3,PART_LOT_CNT_MOD_4,PART_LOT_CNT_MOD_5,PART_LOT_CNT_MOD_6,PART_LOT_CNT_MOD_7,PART_LOT_CNT_MOD_8,PART_LOT_CNT_MOD_9,PART_LOT_CNT_MOD_10,PART_LOT_CNT_MOD_11,PART_LOT_CNT_MOD_12,MASK_RECORD from bulkloader_stage)
	</cfquery--->
	<cfquery name="moveEm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		insert into bulkloader select * from bulkloader_stage
	</cfquery>
	Your records have been checked and are now in table Bulkloader and flagged as
		loaded='BULKLOADED RECORD'. A data administrator can un-flag
		and load them.
		You can access these records in the Bulkloader with <a href="/Bulkloader/browseBulk.cfm">Browse and Edit</a>.
</cfoutput>
</cfif>
<!------------------------------------------->
<cfif #action# is "checkStaged">
<cfoutput>
	<cfstoredproc datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" procedure="bulkloader_stage_check">
	</cfstoredproc>
	<cfquery name="anyBads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as cnt from bulkloader_stage
		where loaded is not null
	</cfquery>
	<cfquery name="allData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as cnt from bulkloader_stage
	</cfquery>
	<cfif #anyBads.cnt# gt 0>
		<cfinclude template="getBulkloaderStageRecs.cfm">
			#anyBads.cnt# of #allData.cnt# records will not successfully load.
			<br>
			Click <a href="bulkloader.txt" target="_blank">here</a>
			to retrieve all data including error messages. Fix them up and reload them.
			This method is strongly preferred.
			<p>
			Click <a href="bulkloaderLoader.cfm?action=loadAnyway">here</a> to load them to the
			bulkloader anyway. Use Arctos to fix them up and load them.
			</p>
	<cfelse>
		<cftransaction >
			<cfquery name="allId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select collection_object_id from bulkloader_stage
			</cfquery>
			<cfloop query="allId">
				<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update bulkloader_stage set collection_object_id=bulkloader_pkey.nextval
					where collection_object_id=#collection_object_id#
				</cfquery>
			</cfloop>
			<cfquery name="flag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update bulkloader_stage set loaded = 'BULKLOADED RECORD'
			</cfquery>
			<cfquery name="moveEm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into bulkloader select * from bulkloader_stage
			</cfquery>
			Your records have been checked and are now in table Bulkloader and flagged as
			loaded='BULKLOADED RECORD'. A data administrator can un-flag
			and load them.
			You can access these records in the Bulkloader with <a href="/Bulkloader/browseBulk.cfm">Browse and Edit</a>.
		</cftransaction>
	</cfif>
</cfoutput>
</cfif>

<cfinclude template="/includes/_footer.cfm">
