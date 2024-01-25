<cfoutput>
<cfinclude template="/includes/_header.cfm">
<cfinclude template="/Reports/functions/label_functions.cfm">
<!-------------------------------------------------------------->
<cfif #action# is "delete">
    <cfquery name="e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        delete from cf_report_sql
        where report_id= <CFQUERYPARAM VALUE="#report_id#" CFSQLTYPE="CF_SQL_DECIMAL">
    </cfquery>
    <cflocation url="reporter.cfm">
</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "saveEdit">
    <cfif unsafeSql(sql_text)>
        Your SQL is not acceptable.
        <cfabort>
    </cfif>
	<cfif REFind("[^A-Za-z0-9_]",report_name,1) gt 0>
		report_name must contain only alphanumeric characters and underscore.
		<cfabort>
	</cfif>
    <cfquery name="e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        update cf_report_sql set
        report_name = <CFQUERYPARAM VALUE="#report_name#" CFSQLTYPE="CF_SQL_VARCHAR"> ,
        report_template  = <CFQUERYPARAM VALUE="#report_template#" CFSQLTYPE="CF_SQL_VARCHAR"> ,
        sql_text = <CFQUERYPARAM VALUE="#sql_text#" CFSQLTYPE="CF_SQL_CLOB"> ,
        description = <CFQUERYPARAM VALUE="#description#" CFSQLTYPE="CF_SQL_VARCHAR"> ,
        pre_function = <CFQUERYPARAM VALUE="#pre_function#" CFSQLTYPE="CF_SQL_VARCHAR"> ,
        report_format = <CFQUERYPARAM VALUE="#report_format#" CFSQLTYPE="CF_SQL_VARCHAR">
        where report_id = <CFQUERYPARAM VALUE="#report_id#" CFSQLTYPE="CF_SQL_DECIMAL">
    </cfquery>
    <cflocation url="reporter.cfm?action=edit&report_id=#report_id#">
</cfif>
<!--------------------------------------------------------------------------------------->
<cfif #action# is "edit">
    <cfif not isdefined("report_id")>
	    <cfquery name="e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	        select report_id from cf_report_sql where report_name='#report_name#'
	    </cfquery>
        <cflocation url="reporter.cfm?action=edit&report_id=#e.report_id#">
    </cfif>

    <cfquery name="e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select * from cf_report_sql where report_id='#report_id#'
    </cfquery>
    <cfdirectory action="list" directory="#Application.webDirectory#/Reports/templates" filter="*.cfr" name="reportList">

    <form method="get" action="reporter.cfm" enctype="text/plain">
        <input type="hidden" name="action" value="saveEdit">
        <input type="hidden" name="report_id" value="#e.report_id#">
        <label for="report_name">Report Name ({Dry|Fluid|Skin|Pin}_{report type}__{ underscore delimited list of collection codes or All})(Separate report type from collection codes with two underscores).  Label reports with names ending in __All will be shown to all users by default, those ending with __{collection codes} will be shown only to people who have indicated preferences in those collections by default.   Reports that are not labels should have names that start with mcz_ and will not be shown on the list of labels, all other reports will be listed as if they were labels, even if they are not.  Report names for loan and other transaction paperwork may be hardcoded in the coldfusion application and should not be lightly changed.</label>
        <input type="text" name="report_name" id="report_name" value="#e.report_name#" maxlength="38" style="width: 38em;">
        <label for="report_template">Report Template</label>
        <select name="report_template" id="report_template">
            <option value="-notfound-">ERROR: Not found!</option>
            <cfloop query="reportList">
                <option <cfif name is e.report_template> selected="selected" </cfif>value="#name#">#name#</option>
            </cfloop>
        </select>
        <label for="pre_function">Pre-Function</label>
        <input type="text" name="pre_function" id="pre_function" value="#e.pre_function#">
        <label for="report_format">Report Format</label>
        <cfset fmt="PDF,FlashPaper,RTF">

        <select name="report_format" id="report_format">
            <cfloop list="#fmt#" index="f">
                <option <cfif f is e.report_format> selected="selected" </cfif>value="#f#">#f#</option>
            </cfloop>
        </select>
        <label for="description">Description/Assumptions</label>
        <textarea name="description" id="description" rows="10" cols="120" wrap="soft">#e.description#</textarea>
        <label for="sql_text">SQL</label>
        <textarea name="sql_text" id="sql_text" rows="40" cols="120" wrap="soft"></textarea>
        <br>
        <input type="submit" value="Save Handler" class="savBtn">
    </form>
    <cfset j=JSStringFormat(e.sql_text)>
    <script>
        var a = escape("#j#");
        var b=document.getElementById('sql_text');
        b.value=unescape(a);
    </script>
       <form method="post" action="reporter.cfm" target="_blank">
           <input type="hidden" name="action" value="testSQL">
	       <input type="hidden" name="test_sql" id="test_sql">
           <input type="hidden" name="format" id="format" value="table">
           <input type="button" value="Test SQL" onclick="document.getElementById('test_sql').value=document.getElementById('sql_text').value;
                submit();" class="lnkBtn">
    </form>
    <div style="background-color:gray;font-size:smaller;">
        The reports
		To print reports, your SQL will need to include the following:
        <br><strong>AND collection_object_id IN (##collection_object_id##)</strong>
        <br>
        For testing purposes, that will default to 12, or you can replace <strong>(##collection_object_id##)</strong>
        with a comma-separated list of collection_object_ids, eg:
        <strong>(1,5,874,2355,4)</strong>
        <p>An optional limit on the preservation types included in the report can be added with <strong>-- ##limit_preserve_method##</strong> as the next to last clause in a where clause, after an AND (and at the end of a line, as the -- will comment out the line if the clause isn&apos;t rewritten.  The query will need to include specimen_part, as the limit_preserve_method tag will be rewritten to "specimen_part.preserve_method = '{selected value}' AND", where the selected value is provided from a preservation type picklist on the report_printer page.</p>
    </div>
</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "newHandler">
     <cfset tc=getTickCount()>
     <cfquery name="e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        insert into cf_report_sql (
            report_name,
            report_template,
            sql_text)
        values (
            'New_Report_#tc#',
            '#report_template#',
            'select 1 from dual')
    </cfquery>
    <cflocation url="reporter.cfm?action=edit&report_name=New_Report_#tc#">
</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "clone">
    <cfquery name="e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select * from cf_report_sql where report_id='#report_id#'
    </cfquery>
    <cfset tc=getTickCount()>
    <cfquery name="e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        insert into cf_report_sql (
            report_name,
            report_template,
            description,
            sql_text)
        values (
            substr('Clone_Of_#e.report_name#_#tc#',38),
            '#e.report_template#',
            <CFQUERYPARAM VALUE="#e.description#" CFSQLTYPE="CF_SQL_CLOB">,
            <CFQUERYPARAM VALUE="#e.sql_text#" CFSQLTYPE="CF_SQL_CLOB"> )
    </cfquery>
    <cflocation url="reporter.cfm">
</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "testSQL">
    <cfif unsafeSql(test_sql)>
        <div class="error">
             The code you submitted contains illegal characters.
         </div>
         <cfabort>
    </cfif>

         <cfset sql=replace(test_sql,"##collection_object_id##",12)>
		<cfset sql=replace(test_sql,"##container_id##",12)>
         <cfquery name="user_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             #preservesinglequotes(sql)#
         </cfquery>
         <cfdump var=#user_sql#>

</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "loadTemplate">
    <cffile action="upload"
    	destination="#Application.webDirectory#/Reports/templates/"
      	nameConflict="overwrite"
      	fileField="Form.FiletoUpload" mode="777">
	<cfset fileName=#cffile.serverfile#>
	<cfset dotPos=find(".",fileName)>
	<cfset name=left(fileName,dotPos-1)>
	<cfset extension=right(fileName,len(fileName)-dotPos+1)>
	<cfif REFind("[^A-Za-z0-9_]",name,1) gt 0>
		<font color="##FF0000" size="+2">The filename (<strong>#fileName#</strong>) you entered contains characters that are not alphanumeric.
		Please rename your file and try again.</font>
		<a href="javascript:back()">Go Back</a>
		<cffile action="delete"
	    	file="#Application.webDirectory#/Reports/templates/#fileName#">
        <cfabort>
	</cfif>
	<cfset ext=right(extension,len(extension)-1)>
	<cfif ext is not "cfr">
		Only .cfr files are accepted.
		<cffile action="delete"
	    	file="#Application.webDirectory#/Reports/templates/#fileName#">
        <cfabort>
	</cfif>
	<cflocation url="reporter.cfm">

</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "nothing">
	<!--- list available templates for editing --->
	<div style="width: 69em; margin: 0 auto; padding: 2em 0 3em 0;">
		<!--- obtain a list of .cfr templates in the upload /Reports/templates directory. --->
		<cfdirectory action="list" directory="#Application.webDirectory#/Reports/templates" filter="*.cfr" name="reportList" sort="name ASC">
		<cfset reportNames = "">
		<cfloop query="reportList">
			<cfset reportNames = ListAppend(reportNames,reportList.name)>
		</cfloop>

		<p>Load a new template (will overwrite old templates). .cfr files only.</p>
		<form name="n" method="post" enctype="multipart/form-data" action="reporter.cfm">
			<input type="hidden" name="action" value="loadTemplate">
			<input type="file" name="FiletoUpload" id="FiletoUpload" size="45" accept=".cfr">
			<input type="submit" class="savBtn" value="Upload File">
		</form>

      <h3 style="wikilink" style="margin-bottom:0;">Existing Reports:</h3>
		<table border>
			<tr>
				<th>Report Template</th>
				<th>Handler Name</th>
				<th colspan="4">Actions</th>
			</tr>
			<!--- obtain the records of .cfr and .cfm templates known to cf_report_sql in the database. --->
			<cfquery name="getReports" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					report_id, report_name, report_template, sql_text_old, pre_function,
					report_format, sql_text, description 
				FROM cf_report_sql 
				WHERE 
					report_template IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#reportNames#" list="yes">) 
					OR 
					report_template LIKE '%.cfm'
				ORDER BY 
					report_name
			</cfquery>
			<cfset templatesWithRecords = "">
	    	<cfloop query="getReports">
				<cfif Right(getReports.report_template,4) EQ ".cfr"> 
					<!--- accumulate list of known .cfr files --->
					<cfset templatesWithRecords = listAppend(templatesWithRecords,"#getReports.report_template#")>
				</cfif>
				<!--- list reports that exist in the database --->
				<tr>
					<td>#report_template#</td>
					<td>#report_name#</td>
					<td><a href="reporter.cfm?action=edit&report_id=#report_id#">Edit Handler</a></td>
					<td><a href="reporter.cfm?action=clone&report_id=#report_id#">Clone Handler</a></td>
					<td><a href="reporter.cfm?action=delete&report_id=#report_id#">Delete Handler</a></td>
					<cfif 
					<cfif Right(getReports.report_template,4) EQ ".cfr"> 
	            	<td><a href="reporter.cfm?action=download&report_template=#report_template#">Download Report</a></td>
					<cfelse>
	            	<td>#report_template#</td>
					</cfif>
	        </tr>
			</cfloop>
			<cfloop query="reportList">
				<!--- list .cfr templates on the filesystem that are not in the database --->
				<cfif listContains(templatesWithRecords,reportList.name) EQ 0>
					<tr>
						<td>#reportList.name#</td>
						<td></td>
						<td colspan="4"><a href="reporter.cfm?action=newHandler&report_template=#reportList.name#">Create Handler</a></td>
					</tr>
				</cfif>
    		</cfloop>
		</table>
	</div>
</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "download">
	<cfheader name="Content-Disposition" value="attachment; filename=#report_template#">
	<cfcontent type="application/vnd.coldfusion-reporter" file="#Application.webDirectory#/Reports/templates/#report_template#">
</cfif>
<!-------------------------------------------------------------->
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
