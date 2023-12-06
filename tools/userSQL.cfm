	<cfset pageTitle="User SQL">
<cfinclude template="/shared/_header.cfm">
<script type="text/javascript" language="javascript" src="/includes/jquery/jquery-1.3.2.min.js"></script>
	<script type="text/javascript" language="javascript" src="/includes/ajax.min.js"></script>
	<style>


	table.cfdump_wddx,
	table.cfdump_xml,
	table.cfdump_struct,
	table.cfdump_varundefined,
	table.cfdump_array,
	table.cfdump_query,
	table.cfdump_cfc,
	table.cfdump_object,
	table.cfdump_binary,
	table.cfdump_udf,
	table.cfdump_udfbody,
	table.cfdump_varnull,
	table.cfdump_udfarguments {
		font-size: xx-small;
		font-family: verdana, arial, helvetica, sans-serif;
	}

	table.cfdump_wddx th,
	table.cfdump_xml th,
	table.cfdump_struct th,
	table.cfdump_varundefined th,
	table.cfdump_array th,
	table.cfdump_query th,
	table.cfdump_cfc th,
	table.cfdump_object th,
	table.cfdump_binary th,
	table.cfdump_udf th,
	table.cfdump_udfbody th,
	table.cfdump_varnull th,
	table.cfdump_udfarguments th {
		text-align: left;
		color: white;
		padding: 5px;
	}

	table.cfdump_wddx td,
	table.cfdump_xml td,
	table.cfdump_struct td,
	table.cfdump_varundefined td,
	table.cfdump_array td,
	table.cfdump_query td,
	table.cfdump_cfc td,
	table.cfdump_object td,
	table.cfdump_binary td,
	table.cfdump_udf td,
	table.cfdump_udfbody td,
	table.cfdump_varnull td,
	table.cfdump_udfarguments td {
		padding: 3px;
		background-color: #ffffff;
		vertical-align : top;
	}

	table.cfdump_wddx {
		background-color: #000000;
	}
	table.cfdump_wddx th.wddx {
		background-color: #444444;
	}


	table.cfdump_xml {
		background-color: #888888;
	}
	table.cfdump_xml th.xml {
		background-color: #aaaaaa;
	}
	table.cfdump_xml td.xml {
		background-color: #dddddd;
	}

	table.cfdump_struct {
		background-color: #0000cc ;
	}
	table.cfdump_struct th.struct {
		background-color: #4444cc ;
	}
	table.cfdump_struct td.struct {
		background-color: #ccddff;
	}

	table.cfdump_varundefined {
		background-color: #CC3300 ;
	}
	table.cfdump_varundefined th.varundefined {
		background-color: #CC3300 ;
	}
	table.cfdump_varundefined td.varundefined {
		background-color: #ccddff;
	}

	table.cfdump_array {
		background-color: #006600 ;
	}
	table.cfdump_array th.array {
		background-color: #009900 ;
	}
	table.cfdump_array td.array {
		background-color: #ccffcc ;
	}

	table.cfdump_query {
		background-color: #884488 ;
	}
	table.cfdump_query th.query {
		background-color: #aa66aa ;
	}
	table.cfdump_query td.query {
		background-color: #ffddff ;
	}


	table.cfdump_cfc {
		background-color: #ff0000;
	}
	table.cfdump_cfc th.cfc{
		background-color: #ff4444;
	}
	table.cfdump_cfc td.cfc {
		background-color: #ffcccc;
	}


	table.cfdump_object {
		background-color : #ff0000;
	}
	table.cfdump_object th.object{
		background-color: #ff4444;
	}

	table.cfdump_binary {
		background-color : #eebb00;
	}
	table.cfdump_binary th.binary {
		background-color: #ffcc44;
	}
	table.cfdump_binary td {
		font-size: x-small;
	}
	table.cfdump_udf {
		background-color: #aa4400;
	}
	table.cfdump_udf th.udf {
		background-color: #cc6600;
	}
	table.cfdump_udfarguments {
		background-color: #dddddd;
	}
	table.cfdump_udfarguments th {
		background-color: #eeeeee;
		color: #000000;
	}

</style>
<script language="javascript">


// for queries we have more than one td element to collapse/expand
	var expand = "open";

	dump = function( obj ) {
		var out = "" ;
		if ( typeof obj == "object" ) {
			for ( key in obj ) {
				if ( typeof obj[key] != "function" ) out += key + ': ' + obj[key] + '<br>' ;
			}
		}
	}


	cfdump_toggleRow = function(source) {
		//target is the right cell
		if(document.all) target = source.parentElement.cells[1];
		else {
			var element = null;
			var vLen = source.parentNode.childNodes.length;
			for(var i=vLen-1;i>0;i--){
				if(source.parentNode.childNodes[i].nodeType == 1){
					element = source.parentNode.childNodes[i];
					break;
				}
			}
			if(element == null)
				target = source.parentNode.lastChild;
			else
				target = element;
		}
		//target = source.parentNode.lastChild ;
		cfdump_toggleTarget( target, cfdump_toggleSource( source ) ) ;
	}

	cfdump_toggleXmlDoc = function(source) {

		var caption = source.innerHTML.split( ' [' ) ;

		// toggle source (header)
		if ( source.style.fontStyle == 'italic' ) {
			// closed -> short
			source.style.fontStyle = 'normal' ;
			source.innerHTML = caption[0] + ' [short version]' ;
			source.title = 'click to maximize' ;
			switchLongToState = 'closed' ;
			switchShortToState = 'open' ;
		} else if ( source.innerHTML.indexOf('[short version]') != -1 ) {
			// short -> full
			source.innerHTML = caption[0] + ' [long version]' ;
			source.title = 'click to collapse' ;
			switchLongToState = 'open' ;
			switchShortToState = 'closed' ;
		} else {
			// full -> closed
			source.style.fontStyle = 'italic' ;
			source.title = 'click to expand' ;
			source.innerHTML = caption[0] ;
			switchLongToState = 'closed' ;
			switchShortToState = 'closed' ;
		}

		// Toggle the target (everething below the header row).
		// First two rows are XMLComment and XMLRoot - they are part
		// of the long dump, the rest are direct children - part of the
		// short dump
		if(document.all) {
			var table = source.parentElement.parentElement ;
			for ( var i = 1; i < table.rows.length; i++ ) {
				target = table.rows[i] ;
				if ( i < 3 ) cfdump_toggleTarget( target, switchLongToState ) ;
				else cfdump_toggleTarget( target, switchShortToState ) ;
			}
		}
		else {
			var table = source.parentNode.parentNode ;
			var row = 1;
			for ( var i = 1; i < table.childNodes.length; i++ ) {
				target = table.childNodes[i] ;
				if( target.style ) {
					if ( row < 3 ) {
						cfdump_toggleTarget( target, switchLongToState ) ;
					} else {
						cfdump_toggleTarget( target, switchShortToState ) ;
					}
					row++;
				}
			}
		}
	}

	cfdump_toggleTable = function(source) {

		var switchToState = cfdump_toggleSource( source ) ;
		if(document.all) {
			var table = source.parentElement.parentElement ;
			for ( var i = 1; i < table.rows.length; i++ ) {
				target = table.rows[i] ;
				cfdump_toggleTarget( target, switchToState ) ;
			}
		}
		else {
			var table = source.parentNode.parentNode ;
			for ( var i = 1; i < table.childNodes.length; i++ ) {
				target = table.childNodes[i] ;
				if(target.style) {
					cfdump_toggleTarget( target, switchToState ) ;
				}
			}
		}
	}

	cfdump_toggleSource = function( source ) {
		if ( source.style.fontStyle == 'italic' || source.style.fontStyle == null) {
			source.style.fontStyle = 'normal' ;
			source.title = 'click to collapse' ;
			return 'open' ;
		} else {
			source.style.fontStyle = 'italic' ;
			source.title = 'click to expand' ;
			return 'closed' ;
		}
	}

	cfdump_toggleTarget = function( target, switchToState ) {
		if ( switchToState == 'open' )	target.style.display = '' ;
		else target.style.display = 'none' ;
	}

	// collapse all td elements for queries
	cfdump_toggleRow_qry = function(source) {
		expand = (source.title == "click to collapse") ? "closed" : "open";
		if(document.all) {
			var nbrChildren = source.parentElement.cells.length;
			if(nbrChildren > 1){
				for(i=nbrChildren-1;i>0;i--){
					target = source.parentElement.cells[i];
					cfdump_toggleTarget( target,expand ) ;
					cfdump_toggleSource_qry(source);
				}
			}
			else {
				//target is the right cell
				target = source.parentElement.cells[1];
				cfdump_toggleTarget( target, cfdump_toggleSource( source ) ) ;
			}
		}
		else{
			var target = null;
			var vLen = source.parentNode.childNodes.length;
			for(var i=vLen-1;i>1;i--){
				if(source.parentNode.childNodes[i].nodeType == 1){
					target = source.parentNode.childNodes[i];
					cfdump_toggleTarget( target,expand );
					cfdump_toggleSource_qry(source);
				}
			}
			if(target == null){
				//target is the last cell
				target = source.parentNode.lastChild;
				cfdump_toggleTarget( target, cfdump_toggleSource( source ) ) ;
			}
		}
	}

	cfdump_toggleSource_qry = function(source) {
		if(expand == "closed"){
			source.title = "click to expand";
			source.style.fontStyle = "italic";
		}
		else{
			source.title = "click to collapse";
			source.style.fontStyle = "normal";
		}
	}

</script>
		<cfif not isdefined("sql")>
			<!--- if sql is defined, it takes priority, otherwise pre-populated form can't be changed --->
			<cfif isDefined("input_sql") and len(input_sql) GT 0> 
				<cfset sql = input_sql>
			<cfelse>
				<cfset sql = "SELECT 'test' FROM dual">
			</cfif>
		</cfif>
		<cfif not isdefined("format")>
			<cfset format = "table">
		</cfif>
		<cfoutput>
			<cfset #action# = "run">
			<div class="container">
				<div class="row">
					<div class="col-12">
						<form method="post" action="">
							<input type="hidden" name="action" value="run">
							<h1 class="h2 mt-3">SQL</h1>
							<label for="sql" class="data_entry_label d-none">SQL</label>
							<textarea name="sql" id="sql" rows="10" cols="80" wrap="soft" class="form-control">#sql#</textarea>
							<h2>Result: &nbsp; &nbsp;
							Table <input type="radio" name="format" value="table" <cfif #format# is "table"> checked="checked" </cfif>> &nbsp;&nbsp;
							CSV <input type="radio" name="format" value="csv" <cfif #format# is "csv"> checked="checked" </cfif>></h2>
							<input type="submit" value="Run Query" class="btn btn-xs btn-primary">
						</form>
					</div>
				</div>
			</div>
			<cfif #action# is "run">
				<hr>
				<!--- check the SQL to see if they're doing anything naughty --->
				<cfset nono="update,
							 insert,delete,drop,create,alter,set,execute,exec,begin,end,declare,all_tables,v$session">
				<cfset dels="';','|'">
				<cfset safe=0>
				<cfloop index="i" list="#sql#" delimiters=" .,?!:%$&""'/|[]{}()">
					<cfif ListFindNoCase(nono, i)>
						<cfset safe=1>
					</cfif>
				</cfloop>

				<div style="font-size:smaller;background-color:lightgray">
					SQL:<br>
					#sql#
				</div>
				Result:<br>
				<cfif unsafeSql(sql)>
					<div class="error">
						The code you submitted contains illegal characters.
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
							<a href="/download.cfm?file=#fileName#">Click to download</a>
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
			</cfif>
		</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
