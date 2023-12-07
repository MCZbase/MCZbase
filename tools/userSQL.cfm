<cfset pageTitle="User SQL">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action")>
	<cfset action = "nothing"> 
<cfelse>
	<cfset action = "run"> 
</cfif>
<cfif not isdefined("sql")>
	<!--- if sql is defined, it takes priority, otherwise pre-populated form can't be changed --->
	<cfif isDefined("input_sql") and len(input_sql) GT 0> 
		<cfset guidanceText = "Modify this query to your needs. Retain the user_search_table.result_id in the query to ask questions about your original search result or eliminate it to extend the query results to the entire database. ">
		<cfset sql = input_sql>
	<cfelse>
		<cfset guidanceText = "This tool allows you to run arbitrary queries on MCZbase. ">
		<cfset sql = "SELECT 'test' FROM dual">
	</cfif>
</cfif>
<cfset guidanceText = "#guidanceText# The <a href='/documentation/er_diagrams/' target='_blank'>E-R Diagrams</a>, <a href='https://github.com/MCZbase/DDL/tree/master/TABLE' target='_blank'>Schema documentation</a>, and <a href='https://github.com/MCZbase/queries_MCZbase' target='_blank'>Example Query Library</a> may help in formulating queries."> <!--- " --->
<cfif isDefined("sql")>
	<!--- prevent typical copy/paste problem that users encounter, a query with normal ; termination. Strip off the ; to allow query to pass checks --->
	<cfset sql=Trim(sql)>
	<cfif Right(sql,1) EQ ";">
		<cfset sql = REReplace(sql,";$","")>
	</cfif>
</cfif>
<cfif not isdefined("format")>
	<cfset format = "table">
</cfif>
<cfoutput>
	<div class="container">
		<div class="row mx-0">
			<div class="col-12 mt-3">
				<form method="post" action="">
					<input type="hidden" name="action" value="run">
					<h1 class="h2">SQL</h1>
					<p class="">#guidanceText#</p>
					<label for="sql" class="data_entry_label d-none">SQL</label>
					<textarea name="sql" spellcheck="false" id="sql" rows="10" cols="80" wrap="soft" class="form-control">#sql#</textarea>
					<h2 class="h3">Result Output Format: &nbsp; &nbsp;
					Table <input type="radio" name="format" value="table" <cfif #format# is "table"> checked="checked" </cfif>> &nbsp;&nbsp;
					CSV <input type="radio" name="format" value="csv" <cfif #format# is "csv"> checked="checked" </cfif>></h2>
					<input type="submit" value="Run Query" class="btn btn-xs btn-primary mt-2">
				</form>
			</div>
		</div>
	</div>
	<cfif #action# is "run">
		<div class="container-fluid">
			<div class="row mx-0">
				<div class="col-12 my-3">
					<hr>
					<!--- check the SQL to see if they're doing anything naughty --->
					<cfset nono="update,insert,delete,drop,create,alter,set,execute,exec,begin,end,declare,all_tables,v$session">
					<cfset dels="';','|',">
					<cfset safe=0>
					<cfloop index="i" list="#sql#" delimiters=" .,?!:%$&""'/|[]{}()">
						<cfif ListFindNoCase(nono, i)>
							<cfset safe=1>
						</cfif>
					</cfloop>
					<h2 class="h3">Result: </h2>
					<cfif unsafeSql(sql)>
						<div class="error">
							<h2 class="h3">The code you submitted contains illegal characters.</h2>
						</div> 
					<cfelse>
						<cftry>
							<cfif session.username is "uam" or session.username is "uam_update">
								<cfabort>
							</cfif>
							<cfquery name="user_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								#preservesinglequotes(sql)#
							</cfquery>
							<cfif format is "csv">
								<cfset ac = user_sql.columnlist>
								<cfset fileDir = "#Application.webDirectory#/download/">
								<cfset fileName = "MCZbaseUserSql_#cfid#_#cftoken#.csv">
								<cfset header=#trim(ac)#>
								<cffile action="write" file="#fileDir##fileName#" addnewline="yes" output="#header#">
								<cfloop query="user_sql">
									<cfset oneLine = "">
									<cfloop list="#ac#" index="z">
										<cfset thisData = #replace(replace(evaluate(z),'"','""','All'),'\n','','All')#>
										<cfif len(#oneLine#) is 0>
											<cfset oneLine = '"#thisData#"'>
										<cfelse>
											<cfset oneLine = '#oneLine#,"#thisData#"'>
										</cfif>
									</cfloop>
									<cfset oneLine = trim(oneLine)>
									<cffile action="append" file="#fileDir##fileName#" addnewline="yes" output="#oneLine#">
								</cfloop>
								<a href="/download.cfm?file=#fileName#" class="h3">Click to download</a>
							<cfelse>
								<cfdump var=#user_sql#>
							</cfif>
						<cfcatch>
							<div class="error">
								#cfcatch.message#
								<br>
								#cfcatch.detail#
							</div>
						</cfcatch>
						</cftry>
					</cfif>
				</div>
			</div>
		</div>
	</cfif>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
