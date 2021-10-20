<cfinclude template="/includes/_header.cfm">
 <!--- these have to live in CF runtime to be accessable to cfexecute --->
 <!--- relies on a staging table:
 
 create table bulkloader_stage as select * from bulkloader;
 delete from bulkloader_stage;
 create public synonym bulkloader_stage for bulkloader_stage;
 grant all on bulkloader_stage to uam_query,uam_update;
 --->
 <!---
 <cfset filename = "/opt/coldfusionmx7/runtime/bin/bulk_data_upload.txt">
 <cfset outFile = "/opt/coldfusionmx7/runtime/bin/bulkData.ctl">
 
 <cfset logfile = "/opt/coldfusionmx7/runtime/bin/bulkData.log">
 <cfset badfile = "/opt/coldfusionmx7/runtime/bin/bulkData.bad">
 
 <cfset webFileName = "/var/www/html/Bulkloader/bulk_data_upload.txt">
 <cfset weboutFile = "/var/www/html/Bulkloader/bulkData.ctl">
 <cfset weblogfile = "/var/www/html/Bulkloader/bulkData.log">
 <cfset webbadfile = "/var/www/html/Bulkloader/bulkData.bad">
---->
 <!------------------------------------------->
 <cfif #action# is "nothing">
 
<strong> Load files to bulkload</strong>
<ul>
	<li>You must load a tab-delimited text file</li>
	<li><strong>Include</strong> headers on the first row; headers must match column names in table Bulkloader</li>
	<li>Do not put quotes around fields (and you cannot have a tab in the data you are loading)</li>
	<li>You don't need all available fields to use this application; if you don't want to look at part_name_8, just delete it.</li>
	<li><strong>Read</strong> the messages on this form; assume nothing.</li>
</ul>
 Upload a file:
 <br>

  <cfform action="bulkloaderLoader.cfm?action=newScans" method="post" enctype="multipart/form-data">
      <input type="file"
   name="FiletoUpload"
   size="45">
   
      <input type="submit" 
				value="Upload this file" 
				class="savBtn"
				onmouseover="this.className='savBtn btnhov'"
				onmouseout="this.className='savBtn'">
				
				
    </cfform>
</cfif>
<!------------------------------------------->
<cfif #action# is "newScans">
 <cfoutput>
	 
	 <cfset filename = "#Application.webDirectory#/Bulkloader/bulk_data_upload.txt">
	 <cfset controlFile = "#Application.webDirectory#/Bulkloader/bulkData.ctl">
	 <cfset logFile = "#Application.webDirectory#/Bulkloader/bulkData.log">
	 <cfset badFile = "#Application.webDirectory#/Bulkloader/bulkData.bad">
	 
	 
	 <cfif #cgi.HTTP_HOST# contains "database.museum">
		<cfset sqlldrScript = "/opt/coldfusion8/runtime/bin/runSqlldr">
	</cfif>
	
	<cfif FileExists("#filename#")>
		  <cffile action="delete" file="#filename#">
	</cfif>
	<cfif FileExists("#controlFile#")>
		<cffile action="delete" file="#controlFile#">
	</cfif>
	<cfif FileExists("#logFile#")>
		<cffile action="delete" file="#logFile#">
	</cfif>
	<cfif FileExists("#badFile#")>
		<cffile action="delete" file="#badFile#">
	</cfif>
	  
	  
	  
	  
 	<!---<cffile action="write" file="#filename#" nameconflict="overwrite" output="blank" mode="777">--->
    <cffile action="upload"
      destination="#filename#"
      nameConflict="overwrite"
      fileField="Form.FiletoUpload">


		<!---cfexecute name="/bin/sh" arguments="/usr/bin/dos2unix #filename#" timeout="240">
		
		</cfexecute--->
	 <!---- see if the bulkloader is deletable ---->
	 <cfquery name="remOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	 	delete from bulkloader_stage
	 </cfquery>
	
	 <!----table is empty, get the data to memory ---->
	 <!--- kill old files 
	
	 <cftry>
		 <cffile action="delete" file="#webbadfile#">
		 <cffile action="delete" file="#weblogfile#">
		 <cffile action="delete" file="#webFileName#">
		 <cffile action="delete" file="#weboutFile#">
	 	<cfcatch>
			<!--- whatever - isn't there, don't care ---->
			
		</cfcatch>
	 </cftry>
	 <!--- Get rid of files in CF runtime, create new blanks with the proper rights --->
		<cffile action="write" file="#logfile#" nameconflict="overwrite" output="blank" mode="777">
		<cffile action="write" file="#badfile#" nameconflict="overwrite" output="blank" mode="777">
		<cffile action="write" file="#outFile#" nameconflict="overwrite" output="blank" mode="777">
	 
	 ---->
	 <!--- first line of file should be column names ---->
	<cfset stoopidLongColumns = "LAT_LONG_REMARKS,COLL_OBJECT_REMARKS">  
	
	

	<cffile action="READ" file="#filename#" variable="fileContent"  charset="windows-1252" >
	 	<cfset fileContent=replace(fileContent,"#chr(13)##chr(10)#",chr(13), "all")>
	 	<cfset fileContent=replace(fileContent,chr(13),chr(10), "all")>
	 	<!---
	 	
	 	
	 	<cfset fileContent=replace(fileContent,chr(13),"==================chr(13)=======================", "all")>
	 	<cfset ColumnList = listgetat(#filecontent#,1,"#chr(10)#")>
	 	---->
	 	<cfset ColumnList = listgetat(#filecontent#,1,"#chr(10)#")>
	 	
	 	
	 	
	 	
		<cfset theseData = replace(filecontent,ColumnList,"","all")>
		<cfset ColumnList = replace(ColumnList,"#chr(9)#",",","all")>	
		<cfset theseData = replace(theseData,"#chr(9)#","|","all")>

		<cfloop list="#stoopidLongColumns#" index="c">
	 		<cfset ColumnList = replace(ColumnList,c,c & " char(4000)")>
	 	</cfloop>
		<cfset thisHeader = "load data">
		<cfset thisHeader = thisHeader & chr(10) & "infile *">
		<cfset thisHeader = thisHeader & chr(10) & "insert into table bulkloader_stage">
		<cfset thisHeader = thisHeader & chr(10) & "fields terminated by ""|""">
		<cfset thisHeader = thisHeader & chr(10) & "TRAILING NULLCOLS ">
		<cfset thisHeader = thisHeader & chr(10) & "(#ColumnList#) ">
		<cfset thisHeader = thisHeader & chr(10) & "begindata" & theseData>
		
		<cffile action="write" file="#controlFile#" addnewline="no" output="#thisHeader#" charset="windows-1252">		
		
		
		<!---
		ORACLE_HOME=/opt/oracle/10.2.0/client
export ORACLE_HOME
#ls -latr
#source /home/fndlm/.bash_profile
echo $ORACLE_HOME
/opt/oracle/10.2.0/client/bin/sqlldr uam_query@arctos/uamdb1 control=/var/www/ht
ml/Bulkloader/bulkData.ctl log=/var/www/html/Bulkloader/bulkData.log




		<cfscript>
function exec_cmd(cmd) {
   var runtimeClass="";
   var out="";
    // Initialize the Java class.
    runtimeClass=CreateObject("java", "java.lang.Runtime");
    // Execute command
    out=runtimeClass.getRuntime().exec(cmd);
    // Return the output
   out.waitFor();
   return out.getInputStream().read();
}
command_output = exec_cmd('#sqlldrScript#');
</cfscript>
<hr>
<cfoutput>#command_output#</cfoutput>
<hr>

		--->
		
		
		
		<cfexecute name="#sqlldrScript#" timeout="240">
		
		</cfexecute>
	<cflocation url="bulkloaderLoader.cfm?action=inStage">	
		
		<!---
		<cfdump var=#cfe#>
		
		<br />		
<cfscript>  
       try {  
       	 runtime = createObject("java", "java.lang.Runtime").getRuntime();  
        command = '#sqlldrScript#';   
         process = runtime.exec(command);  
         //#results.errorLogSuccess = processStream(process.getErrorStream(), errorLog);  
         //results.resultLogSuccess = processStream(process.getInputStream(), resultLog);  
         //results.exitCode = process.waitFor();  
     }  
     catch(exception e) {  
         results.status = e;      
     }  
 </cfscript>


 move the files from CF runtime to a web dir <cftry>


	 	<cffile action="copy" destination="#weblogfile#" source="#logfile#" nameconflict="overwrite">
		 <cffile action="copy" destination="#webbadfile#" source="#badfile#" nameconflict="overwrite">
		 <cffile action="copy" destination="#weboutFile#" source="#outFile#" nameconflict="overwrite">
		 <cffile action="copy" destination="#webFileName#" source="#filename#" nameconflict="overwrite">
	 	<cfcatch><!--- so what? ---></cfcatch>
		</cftry>

		<cffile action="copy" destination="/var/www/html/Bulkloader" source="#logfile#" nameconflict="overwrite">
		 <cffile action="copy" destination="#webBadFile#" source="#badfile#" nameconflict="overwrite">
		 <cffile action="copy" destination="#weboutFile#" source="#outFile#" nameconflict="overwrite">
		 <cffile action="copy" destination="#webFileName#" source="#filename#" nameconflict="overwrite">
<cflocation url="bulkloaderLoader.cfm?action=inStage">
--->

		<!--- 
		<cfscript>
  // first of we set the command to call
  cmd = "/var/www/html/Bulkloader/a";
  // the environment variable is empty
  envp = arraynew(1);
  // and we want to run from a given "root"
  path = "/var/www/html/Bulkloader";
  dir = createobject("java", "java.io.File").init(path);
  // get the java runtime object
  rt = createobject("java", "java.lang.Runtime").getRuntime();
  // and make the exec call to run the command
  rt.exec(cmd, envp, dir);
</cfscript>
		
 uam_query@arctos/uamdb1 control=/var/www/html/Bulkloader/bulkData.ctl log=/var/www/html/Bulkloader/bulkData.log ---->
		
	 </cfoutput>
</cfif>	 

<!---------------------------------------->
<cfif #action# is "inStage">
	<cfoutput>
	<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as cnt from bulkloader_stage
	</cfquery>
	You successfully loaded #c.cnt# records into the <em><strong>staging</strong></em> table. They have not been checked or processed yet. You aren't done here!
	<p>
	Click <a href="/Bulkloader/bulkData.log" target="_blank">here</a> to view the logfile in a new window. Check data and time (near the bottom) to make sure this is your logfile. Times are AKST.
	</p>
	<p>
		Bad records are <a href="/Bulkloader/bulkData.bad" target="_blank">here</a>.
	</p>
	<p>
		Your data, as they were received by this application, are <a href="/Bulkloader/bulk_data_upload.txt" target="_blank">here</a>.
	</p>
	<p>
		The generated control file is <a href="/Bulkloader/bulkData.ctl" target="_blank">here</a>.
	</p>
	<p>
		If all of that looks reasonable, 
		click <a href="/Bulkloader/bulkloaderLoader.cfm?action=checkStaged" target="_self">here</a> 
		to continue.
		 It'll take awhile. Maybe a long while. Mashing the button more than once will make it take longer.
		 Don't do that. You'll probably break something. This means you. Yea, you. #session.username#. <<-- that you.
		 
		 <p>
			NOTE: If you're loading a lot of records - more than a few hundred - you may need help from
			a DBA. Push the button if you're feeling lucky, it'll either time out or work, but
			won't break anything either way.
		</p>
	</p>	
	</cfoutput>
</cfif>
<!---------------------------------------->
<cfif #action# is "checkStaged">
	<cfstoredproc datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" procedure="bulkloader_stage_check">
	</cfstoredproc>
	<cfquery name="anyBads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as cnt from bulkloader_stage
		where loaded is not null and loaded <> 'waiting approval'
	</cfquery>
	<cfquery name="allData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as cnt from bulkloader_stage
	</cfquery>
	<cfoutput>
		<cfif #anyBads.cnt# gt 0>
			<cfinclude template="getBulkloaderStageRecs.cfm">
				#anyBads.cnt# of #allData.cnt# records will not successfully load. 
				Click <a href="bulkloader.txt" target="_blank">here</a> 
				to retrieve all data including error messages. Fix them up and reload them.
				<p>
				Click <a href="bulkloaderLoader.cfm?action=loadAnyway">here</a> to load them to the
				bulkloader anyway. Use Arctos to fix them up and load them. You'll need Data Entry Admin permissions to use this option.
				</p>
	<cfelse>
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
			<!--->insert into bulkloader select * from bulkloader_stage--->
			insert into bulkloader(CATALOG_NUMBER,UTM_EW,EXTENT,GPSACCURACY,UTM_NS,CATALOG_NUMBER_SUFFIX,RELATIONSHIP,CATALOG_NUMBER_PREFIX,RELATED_TO_NUMBER,RELATED_TO_NUM_TYPE,PART_CONTAINER_LABEL_6,PART_LOT_COUNT_11,ATTRIBUTE_DETERMINER_2,ATTRIBUTE_UNITS_6,COLLECTOR_AGENT_4,PART_BARCODE_3,ATTRIBUTE_DETERMINER_1,PART_BARCODE_11,PART_LOT_COUNT_9,ATTRIBUTE_DET_METH_1,LONGDIR,ATTRIBUTE_DET_METH_10,ATTRIBUTE_DETERMINER_6,PART_CONTAINER_LABEL_5,ATTRIBUTE_DETERMINER_9,ATTRIBUTE_UNITS_7,ATTRIBUTE_DETERMINER_5,ATTRIBUTE_1,PART_CONTAINER_LABEL_8,PART_CONTAINER_LABEL_9,LATDIR,ATTRIBUTE_UNITS_3,ATTRIBUTE_UNITS_5,PART_LOT_COUNT_10,PART_BARCODE_5,PART_CONTAINER_LABEL_7,ATTRIBUTE_DETERMINER_8,ATTRIBUTE_UNITS_8,ATTRIBUTE_DET_METH_3,ATTRIBUTE_DETERMINER_3,INSTITUTION_ACRONYM,ATTRIBUTE_DET_METH_8,PART_CONTAINER_LABEL_11,ATTRIBUTE_DET_METH_7,ATTRIBUTE_6,COLLECTOR_ROLE_4,ATTRIBUTE_UNITS_9,PART_CONTAINER_LABEL_2,ATTRIBUTE_UNITS_4,ATTRIBUTE_10,PART_CONTAINER_LABEL_1,PART_BARCODE_12,ATTRIBUTE_DET_METH_2,PART_CONTAINER_LABEL_3,ATTRIBUTE_DATE_9,PART_BARCODE_2,PART_BARCODE_8,PART_BARCODE_9,PART_BARCODE_1,ATTRIBUTE_3,PART_BARCODE_7,ATTRIBUTE_DETERMINER_10,PART_CONTAINER_LABEL_10,PART_BARCODE_6,ATTRIBUTE_DETERMINER_4,ATTRIBUTE_DET_METH_4,PART_CONTAINER_LABEL_4,ATTRIBUTE_7,PART_BARCODE_10,ATTRIBUTE_8,ATTRIBUTE_2,ATTRIBUTE_DET_METH_6,PART_LOT_COUNT_12,ATTRIBUTE_DET_METH_9,PART_BARCODE_4,ATTRIBUTE_4,ATTRIBUTE_DET_METH_5,ATTRIBUTE_5,ATTRIBUTE_UNITS_2,ATTRIBUTE_DETERMINER_7,PART_CONTAINER_LABEL_12,ATTRIBUTE_9,ATTRIBUTE_DATE_10,ATTRIBUTE_UNITS_10,PART_LOT_COUNT_1,GEO_ATT_REMARK_5,COLL_OBJECT_REMARKS,GEO_ATT_REMARK_1,GEO_ATT_REMARK_4,IDENTIFICATION_REMARKS,GEO_ATT_REMARK_2,GEO_ATT_REMARK_3,GEO_ATT_REMARK_6,DEPTH_UNITS,UTM_ZONE,ATTRIBUTE_UNITS_1,PART_DISPOSITION_3,DEC_LONG_MIN,PART_NAME_11,COLLECTOR_AGENT_7,DATUM,VERBATIM_LOCALITY,PART_DISPOSITION_1,PART_REMARK_11,PART_DISPOSITION_9,ORIG_LAT_LONG_UNITS,HIGHER_GEOG,COLL_OBJ_DISPOSITION,PART_NAME_4,ASSOCIATED_SPECIES,ATTRIBUTE_REMARKS_8,COLLECTOR_ROLE_3,VESSEL,PART_CONDITION_1,PART_MODIFIER_2,GEO_ATT_DETERMINED_METHOD_5,PART_NAME_7,PART_CONDITION_12,ATTRIBUTE_REMARKS_4,GEO_ATT_DETERMINER_3,PART_REMARK_9,GEO_ATT_VALUE_4,OTHER_ID_NUM_4,LAT_LONG_REMARKS,DEC_LAT,PART_NAME_2,OTHER_ID_NUM_TYPE_4,COLLECTOR_ROLE_5,GEO_ATT_DETERMINER_5,ATTRIBUTE_REMARKS_7,GEO_ATT_DETERMINER_4,STATION_NUMBER,OTHER_ID_NUM_1,COLLECTOR_AGENT_1,CONDITION,DETERMINED_BY_AGENT,PART_CONDITION_10,PRESERV_METHOD_2,GEO_ATT_DETERMINED_METHOD_4,DEC_LAT_MIN,GEOLOGY_ATTRIBUTE_4,COLLECTOR_ROLE_6,PRESERV_METHOD_11,PART_REMARK_8,GEO_ATT_VALUE_5,ATTRIBUTE_REMARKS_5,PART_MODIFIER_6,GEO_ATT_DETERMINED_DATE_5,GEOLOGY_ATTRIBUTE_2,ATTRIBUTE_REMARKS_6,GEOREFMETHOD,PART_REMARK_10,ENTEREDBY,ATTRIBUTE_VALUE_3,OTHER_ID_NUM_TYPE_2,ID_MADE_BY_AGENT,OTHER_ID_NUM_TYPE_3,COLLECTING_METHOD,PART_NAME_10,PART_CONDITION_6,PART_CONDITION_7,PART_REMARK_6,GEOLOGY_ATTRIBUTE_1,PART_REMARK_1,PART_NAME_8,OTHER_ID_NUM_TYPE_1,MAX_ERROR_UNITS,COLLECTOR_AGENT_8,GEOLOGY_ATTRIBUTE_3,GEO_ATT_DETERMINER_6,SPEC_LOCALITY,GEO_ATT_DETERMINED_DATE_1,TAXON_NAME,PRESERV_METHOD_9,PART_CONDITION_5,PART_DISPOSITION_2,COLLECTOR_AGENT_6,PART_MODIFIER_4,DEC_LONG,PRESERV_METHOD_5,PRESERV_METHOD_6,PRESERV_METHOD_12,PART_MODIFIER_11,PART_CONDITION_11,ATTRIBUTE_VALUE_8,GEO_ATT_DETERMINED_METHOD_3,PART_REMARK_7,PART_NAME_5,ATTRIBUTE_VALUE_9,HABITAT_DESC,PRESERV_METHOD_4,GEO_ATT_DETERMINER_1,COLLECTOR_AGENT_5,PART_CONDITION_9,PART_MODIFIER_3,PART_CONDITION_4,DISPOSITION_REMARKS,ATTRIBUTE_REMARKS_1,PRESERV_METHOD_8,VERIFICATIONSTATUS,PART_MODIFIER_5,GEO_ATT_DETERMINED_METHOD_1,PRESERV_METHOD_1,ATTRIBUTE_VALUE_7,LAT_LONG_REF_SOURCE,ATTRIBUTE_REMARKS_2,PART_CONDITION_2,GEO_ATT_DETERMINED_METHOD_2,PART_REMARK_12,PART_MODIFIER_7,NATURE_OF_ID,COLLECTOR_ROLE_2,LONGMIN,OTHER_ID_NUM_5,ATTRIBUTE_VALUE_2,COLL_EVENT_REMARKS,MAX_ERROR_DISTANCE,ORIG_ELEV_UNITS,PART_MODIFIER_10,LONGSEC,PART_REMARK_4,OTHER_ID_NUM_2,OTHER_ID_NUM_TYPE_5,PART_MODIFIER_8,LOCALITY_REMARKS,PART_CONDITION_3,PART_REMARK_2,ATTRIBUTE_REMARKS_10,GEOLOGY_ATTRIBUTE_5,PART_REMARK_5,PART_MODIFIER_1,PART_DISPOSITION_5,GEO_ATT_VALUE_6,PART_DISPOSITION_8,PART_NAME_6,PART_DISPOSITION_4,PART_DISPOSITION_6,LOADED,COLLECTING_SOURCE,PART_CONDITION_8,COLLECTION_CDE,COLLECTOR_ROLE_1,STATION_NAME,ATTRIBUTE_VALUE_1,PART_DISPOSITION_11,COLLECTOR_AGENT_3,VERBATIM_DATE,GEO_ATT_DETERMINER_2,PART_NAME_3,GEO_ATT_DETERMINED_DATE_3,PRESERV_METHOD_3,GEO_ATT_VALUE_2,OTHER_ID_NUM_3,GEO_ATT_DETERMINED_DATE_4,PART_NAME_1,PART_DISPOSITION_7,PART_MODIFIER_12,PART_DISPOSITION_10,PART_MODIFIER_9,ATTRIBUTE_REMARKS_9,LATSEC,COLLECTOR_ROLE_7,GEO_ATT_VALUE_3,GEO_ATT_VALUE_1,COLL_OBJECT_HABITAT,ATTRIBUTE_VALUE_4,GEOLOGY_ATTRIBUTE_6,LATMIN,ATTRIBUTE_REMARKS_3,ATTRIBUTE_VALUE_5,PRESERV_METHOD_7,COLLECTOR_ROLE_8,GEO_ATT_DETERMINED_DATE_6,PART_NAME_9,GEO_ATT_DETERMINED_METHOD_6,ATTRIBUTE_VALUE_10,GEO_ATT_DETERMINED_DATE_2,PART_DISPOSITION_12,PART_NAME_12,PRESERV_METHOD_10,COLLECTOR_AGENT_2,PART_REMARK_3,ATTRIBUTE_VALUE_6,ATTRIBUTE_DATE_4,ACCN,LONGDEG,MIN_DEPTH,FLAGS,LOCALITY_ID,CAT_NUM,ATTRIBUTE_DATE_8,MINIMUM_ELEVATION,MAXIMUM_ELEVATION,ATTRIBUTE_DATE_1,ATTRIBUTE_DATE_5,ATTRIBUTE_DATE_3,ATTRIBUTE_DATE_7,ATTRIBUTE_DATE_6,MADE_DATE,BEGAN_DATE,DETERMINED_DATE,ENDED_DATE,LATDEG,ATTRIBUTE_DATE_2,MAX_DEPTH,PART_LOT_COUNT_4,PART_LOT_COUNT_5,PART_LOT_COUNT_6,PART_LOT_COUNT_8,PART_LOT_COUNT_2,PART_LOT_COUNT_7,PART_LOT_COUNT_3,COLLECTING_EVENT_ID,COLLECTION_OBJECT_ID)
			select CATALOG_NUMBER,UTM_EW,EXTENT,GPSACCURACY,UTM_NS,CATALOG_NUMBER_SUFFIX,RELATIONSHIP,CATALOG_NUMBER_PREFIX,RELATED_TO_NUMBER,RELATED_TO_NUM_TYPE,PART_CONTAINER_LABEL_6,PART_LOT_COUNT_11,ATTRIBUTE_DETERMINER_2,ATTRIBUTE_UNITS_6,COLLECTOR_AGENT_4,PART_BARCODE_3,ATTRIBUTE_DETERMINER_1,PART_BARCODE_11,PART_LOT_COUNT_9,ATTRIBUTE_DET_METH_1,LONGDIR,ATTRIBUTE_DET_METH_10,ATTRIBUTE_DETERMINER_6,PART_CONTAINER_LABEL_5,ATTRIBUTE_DETERMINER_9,ATTRIBUTE_UNITS_7,ATTRIBUTE_DETERMINER_5,ATTRIBUTE_1,PART_CONTAINER_LABEL_8,PART_CONTAINER_LABEL_9,LATDIR,ATTRIBUTE_UNITS_3,ATTRIBUTE_UNITS_5,PART_LOT_COUNT_10,PART_BARCODE_5,PART_CONTAINER_LABEL_7,ATTRIBUTE_DETERMINER_8,ATTRIBUTE_UNITS_8,ATTRIBUTE_DET_METH_3,ATTRIBUTE_DETERMINER_3,INSTITUTION_ACRONYM,ATTRIBUTE_DET_METH_8,PART_CONTAINER_LABEL_11,ATTRIBUTE_DET_METH_7,ATTRIBUTE_6,COLLECTOR_ROLE_4,ATTRIBUTE_UNITS_9,PART_CONTAINER_LABEL_2,ATTRIBUTE_UNITS_4,ATTRIBUTE_10,PART_CONTAINER_LABEL_1,PART_BARCODE_12,ATTRIBUTE_DET_METH_2,PART_CONTAINER_LABEL_3,ATTRIBUTE_DATE_9,PART_BARCODE_2,PART_BARCODE_8,PART_BARCODE_9,PART_BARCODE_1,ATTRIBUTE_3,PART_BARCODE_7,ATTRIBUTE_DETERMINER_10,PART_CONTAINER_LABEL_10,PART_BARCODE_6,ATTRIBUTE_DETERMINER_4,ATTRIBUTE_DET_METH_4,PART_CONTAINER_LABEL_4,ATTRIBUTE_7,PART_BARCODE_10,ATTRIBUTE_8,ATTRIBUTE_2,ATTRIBUTE_DET_METH_6,PART_LOT_COUNT_12,ATTRIBUTE_DET_METH_9,PART_BARCODE_4,ATTRIBUTE_4,ATTRIBUTE_DET_METH_5,ATTRIBUTE_5,ATTRIBUTE_UNITS_2,ATTRIBUTE_DETERMINER_7,PART_CONTAINER_LABEL_12,ATTRIBUTE_9,ATTRIBUTE_DATE_10,ATTRIBUTE_UNITS_10,PART_LOT_COUNT_1,GEO_ATT_REMARK_5,COLL_OBJECT_REMARKS,GEO_ATT_REMARK_1,GEO_ATT_REMARK_4,IDENTIFICATION_REMARKS,GEO_ATT_REMARK_2,GEO_ATT_REMARK_3,GEO_ATT_REMARK_6,DEPTH_UNITS,UTM_ZONE,ATTRIBUTE_UNITS_1,PART_DISPOSITION_3,DEC_LONG_MIN,PART_NAME_11,COLLECTOR_AGENT_7,DATUM,VERBATIM_LOCALITY,PART_DISPOSITION_1,PART_REMARK_11,PART_DISPOSITION_9,ORIG_LAT_LONG_UNITS,HIGHER_GEOG,COLL_OBJ_DISPOSITION,PART_NAME_4,ASSOCIATED_SPECIES,ATTRIBUTE_REMARKS_8,COLLECTOR_ROLE_3,VESSEL,PART_CONDITION_1,PART_MODIFIER_2,GEO_ATT_DETERMINED_METHOD_5,PART_NAME_7,PART_CONDITION_12,ATTRIBUTE_REMARKS_4,GEO_ATT_DETERMINER_3,PART_REMARK_9,GEO_ATT_VALUE_4,OTHER_ID_NUM_4,LAT_LONG_REMARKS,DEC_LAT,PART_NAME_2,OTHER_ID_NUM_TYPE_4,COLLECTOR_ROLE_5,GEO_ATT_DETERMINER_5,ATTRIBUTE_REMARKS_7,GEO_ATT_DETERMINER_4,STATION_NUMBER,OTHER_ID_NUM_1,COLLECTOR_AGENT_1,CONDITION,DETERMINED_BY_AGENT,PART_CONDITION_10,PRESERV_METHOD_2,GEO_ATT_DETERMINED_METHOD_4,DEC_LAT_MIN,GEOLOGY_ATTRIBUTE_4,COLLECTOR_ROLE_6,PRESERV_METHOD_11,PART_REMARK_8,GEO_ATT_VALUE_5,ATTRIBUTE_REMARKS_5,PART_MODIFIER_6,GEO_ATT_DETERMINED_DATE_5,GEOLOGY_ATTRIBUTE_2,ATTRIBUTE_REMARKS_6,GEOREFMETHOD,PART_REMARK_10,ENTEREDBY,ATTRIBUTE_VALUE_3,OTHER_ID_NUM_TYPE_2,ID_MADE_BY_AGENT,OTHER_ID_NUM_TYPE_3,COLLECTING_METHOD,PART_NAME_10,PART_CONDITION_6,PART_CONDITION_7,PART_REMARK_6,GEOLOGY_ATTRIBUTE_1,PART_REMARK_1,PART_NAME_8,OTHER_ID_NUM_TYPE_1,MAX_ERROR_UNITS,COLLECTOR_AGENT_8,GEOLOGY_ATTRIBUTE_3,GEO_ATT_DETERMINER_6,SPEC_LOCALITY,GEO_ATT_DETERMINED_DATE_1,TAXON_NAME,PRESERV_METHOD_9,PART_CONDITION_5,PART_DISPOSITION_2,COLLECTOR_AGENT_6,PART_MODIFIER_4,DEC_LONG,PRESERV_METHOD_5,PRESERV_METHOD_6,PRESERV_METHOD_12,PART_MODIFIER_11,PART_CONDITION_11,ATTRIBUTE_VALUE_8,GEO_ATT_DETERMINED_METHOD_3,PART_REMARK_7,PART_NAME_5,ATTRIBUTE_VALUE_9,HABITAT_DESC,PRESERV_METHOD_4,GEO_ATT_DETERMINER_1,COLLECTOR_AGENT_5,PART_CONDITION_9,PART_MODIFIER_3,PART_CONDITION_4,DISPOSITION_REMARKS,ATTRIBUTE_REMARKS_1,PRESERV_METHOD_8,VERIFICATIONSTATUS,PART_MODIFIER_5,GEO_ATT_DETERMINED_METHOD_1,PRESERV_METHOD_1,ATTRIBUTE_VALUE_7,LAT_LONG_REF_SOURCE,ATTRIBUTE_REMARKS_2,PART_CONDITION_2,GEO_ATT_DETERMINED_METHOD_2,PART_REMARK_12,PART_MODIFIER_7,NATURE_OF_ID,COLLECTOR_ROLE_2,LONGMIN,OTHER_ID_NUM_5,ATTRIBUTE_VALUE_2,COLL_EVENT_REMARKS,MAX_ERROR_DISTANCE,ORIG_ELEV_UNITS,PART_MODIFIER_10,LONGSEC,PART_REMARK_4,OTHER_ID_NUM_2,OTHER_ID_NUM_TYPE_5,PART_MODIFIER_8,LOCALITY_REMARKS,PART_CONDITION_3,PART_REMARK_2,ATTRIBUTE_REMARKS_10,GEOLOGY_ATTRIBUTE_5,PART_REMARK_5,PART_MODIFIER_1,PART_DISPOSITION_5,GEO_ATT_VALUE_6,PART_DISPOSITION_8,PART_NAME_6,PART_DISPOSITION_4,PART_DISPOSITION_6,LOADED,COLLECTING_SOURCE,PART_CONDITION_8,COLLECTION_CDE,COLLECTOR_ROLE_1,STATION_NAME,ATTRIBUTE_VALUE_1,PART_DISPOSITION_11,COLLECTOR_AGENT_3,VERBATIM_DATE,GEO_ATT_DETERMINER_2,PART_NAME_3,GEO_ATT_DETERMINED_DATE_3,PRESERV_METHOD_3,GEO_ATT_VALUE_2,OTHER_ID_NUM_3,GEO_ATT_DETERMINED_DATE_4,PART_NAME_1,PART_DISPOSITION_7,PART_MODIFIER_12,PART_DISPOSITION_10,PART_MODIFIER_9,ATTRIBUTE_REMARKS_9,LATSEC,COLLECTOR_ROLE_7,GEO_ATT_VALUE_3,GEO_ATT_VALUE_1,COLL_OBJECT_HABITAT,ATTRIBUTE_VALUE_4,GEOLOGY_ATTRIBUTE_6,LATMIN,ATTRIBUTE_REMARKS_3,ATTRIBUTE_VALUE_5,PRESERV_METHOD_7,COLLECTOR_ROLE_8,GEO_ATT_DETERMINED_DATE_6,PART_NAME_9,GEO_ATT_DETERMINED_METHOD_6,ATTRIBUTE_VALUE_10,GEO_ATT_DETERMINED_DATE_2,PART_DISPOSITION_12,PART_NAME_12,PRESERV_METHOD_10,COLLECTOR_AGENT_2,PART_REMARK_3,ATTRIBUTE_VALUE_6,ATTRIBUTE_DATE_4,ACCN,LONGDEG,MIN_DEPTH,FLAGS,LOCALITY_ID,CAT_NUM,ATTRIBUTE_DATE_8,MINIMUM_ELEVATION,MAXIMUM_ELEVATION,ATTRIBUTE_DATE_1,ATTRIBUTE_DATE_5,ATTRIBUTE_DATE_3,ATTRIBUTE_DATE_7,ATTRIBUTE_DATE_6,MADE_DATE,BEGAN_DATE,DETERMINED_DATE,ENDED_DATE,LATDEG,ATTRIBUTE_DATE_2,MAX_DEPTH,PART_LOT_COUNT_4,PART_LOT_COUNT_5,PART_LOT_COUNT_6,PART_LOT_COUNT_8,PART_LOT_COUNT_2,PART_LOT_COUNT_7,PART_LOT_COUNT_3,COLLECTING_EVENT_ID,COLLECTION_OBJECT_ID
				from bulkloader_stage
		</cfquery>
		Your records have been checked and are now in table Bulkloader and flagged as
		loaded='BULKLOADED RECORD'. A data administrator can un-flag
		and load them.
	</cfif>
		
		
		<!--- SQL to accomplish above:
			create or replace PROCEDURE up_bs_id 
			is
			  BEGIN
				FOR rec IN (SELECT collection_object_id FROM bulkloader_stage) LOOP
					update bulkloader_stage set collection_object_id = bulkloader_pkey.nextval
							where collection_object_id=rec.collection_object_id;
				END LOOP;
			END;
			/
			
			exec up_bs_id;

		--->
		<!--- now move em to the real bulkloader --->
		
		<!---
			update bulkloader_stage set loaded = 'BULKLOADED RECORD' where loaded is null;
		--->
		
	</cfoutput>
		<!---
	<cfquery name="b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update bulkloader_stage set loaded = 'UNCHECKED BULKLOADED RECORD' 
	</cfquery>
	<cftry>
	<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		insert into bulkloader select * from bulkloader_stage
	</cfquery>
		<cfcatch>
			<cfquery name="u" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from bulkloader where loaded = 'UNCHECKED BULKLOADED RECORD' 
			</cfquery>
		</cfcatch>
	</cftry>
	
	
	
		<cfoutput>
			
			
				<!--- make the text download file --->
				
				<!---
				no download here
				--->
				<cfinclude template="getBulkloaderStageRecs.cfm">
				#anyBads.cnt# of #allData.recordcount# records will not successfully load. 
				Click <a href="bulkloader.txt" target="_blank">here</a> 
				to retrieve all data including error messages.
			<cfelse>
					
					<!--- no problems, move the records into the real bulkloader table --->
					<!--- first, update collection_object_ids --->
					
					
			</cfif>
		</cfoutput>
		--->
</cfif>
<!---------------------------------------->
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
	<cfquery name="moveEm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			<!--->insert into bulkloader select * from bulkloader_stage--->
			insert into bulkloader			
			select * from bulkloader_stage
	</cfquery>
	Your records have been checked and are now in table Bulkloader and flagged as
		loaded='BULKLOADED RECORD'. A data administrator can un-flag
		and load them.
</cfoutput>
</cfif>
<!---------------------------------------->
<cfif #action# is "logs">
<cfoutput>
	<strong>Something happened!</strong>
		<br>That's not necessarily a good thing. This application calls an Oracle application which sometimes produces cryptic logs, no logs at all, or otherwise fails for no apparent reason.
		<br>
		Click <a href="/Bulkloader/bulkData.log" target="_blank">here</a> to view the logfile in a new window. Check data and time (near the bottom) to make sure this is your logfile. Times are AKST. Near the bottom, you should see something like:
		<blockquote>
			<em><strong>Table "UAM"."BULKLOADER":<br>
  71 Rows successfully loaded.<br>
  0 Rows not loaded due to data errors.<br>
  0 Rows not loaded because all WHEN clauses were failed.<br>
  0 Rows not loaded because all fields were null.<br></strong></em>
		</blockquote>
	If there are problems, click <a href="/Bulkloader/bulkData.bad" target="_blank">here</a>
	to see bad records. You'll have to begin the process over.
	<p>
		Your data, as they were received by this application, are <a href="/Bulkloader/bulk_data_upload.txt" target="_blank">here</a>.
	</p>
	<p>
		The generated control file is <a href="/Bulkloader/bulkData.ctl" target="_blank">here</a>.
	</p>
	<cfquery name="whatsThere" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) cnt from bulkloader
	</cfquery>
	<p>
		<cfif #whatsThere.cnt# is 0>
			There are currently #whatsThere.cnt# records in table Bulkloader.
			That may be because this page loaded before the bulkloading process
			had completed. 
			<a href="bulkloaderLoader.cfm?action=logs">Reload this page</a>
			 and see if you still get this message. If you do, you've probably really loaded nothing.
		<cfelse>
			There are currently #whatsThere.cnt# records in table Bulkloader.
		</cfif>
		
	</p>
	If nothing above scares you, click <a href="Bulkloader.cfm">here</a> to begin bulkloading!
	<p>
		If something does scare you, click <a href="bulkloaderLoader.cfm?action=killEmAll">here</a> to delete these records and restart the 
		load process.
	</p>
</cfoutput>
		
</cfif>
 <cfinclude template="/includes/_footer.cfm">
