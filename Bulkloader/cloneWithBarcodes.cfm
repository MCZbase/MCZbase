<cfinclude template="/includes/_header.cfm">
<cfinclude template="/Bulkloader/bulkEditFilters.cfm">

<!---- relies on table bulkloader_clone

create table bulkloader_clone as select * from bulkloader where 1=0;
create public synonym bulkloader_clone for bulkloader_clone;
grant all on bulkloader_clone to coldfusion_user;


---->
<script src="/lib/misc/sorttable.js"></script>
<style>
.blTabDiv {
	width: 100%;
	overflow:scroll;
	}
</style>
<cfif #action# IS "nothing">
<cfoutput>
<cf_setDataEntryGroups>
<cfset afg=ListQualify(adminForUsers, "'")>
<cfset variables.afgUsers = adminForUsers>
<cfif len(#afg#) is 0>
	<!--- for this form, let them "admin" their own records --->
    <cfset afg="'#session.username#'">
	<cfset variables.afgUsers = session.username>
</cfif>
<cfquery name="ctAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="ctAccn_result">
	select accn from bulkloader
	where enteredby in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.afgUsers#" list="yes">)
	group by accn order by accn
</cfquery>

<p>Filter records in bulkloader to:</p>


<form name="f" method="post" action="cloneWithBarcodes.cfm">
	<input type="hidden" name="action" value="sqlTab" />
	<label for="enteredby">Entered By</label>
	<select name="enteredby" multiple="multiple" size="4" id="enteredby">
		<option value="#afg#" selected="selected">All</option>
		<cfloop list="#adminForUsers#" index='agent_name'>
			<option value="'#agent_name#'">#agent_name#</option>
		</cfloop>
	</select>
	<label for="accn">Accession</label>
	<select name="accn" multiple="multiple" size="10" id="accn">
		<option value="" selected>All</option>
		<cfloop query="ctAccn">
			<option value="'#accn#'">#accn#</option>
		</cfloop>
	</select>
	<br /><input type="submit"
				value="Add Barcodes"
				class="lnkBtn"
				onmouseover="this.className='lnkBtn btnhov'"
				onmouseout="this.className='lnkBtn'">

</form>
</cfoutput>
</cfif>
<!----------------------------------------------------------->
<cfif #action# is "runSQLUp">
<cfoutput>
	<cfif not isdefined("uc1") or not isdefined("uv1") or len(#uc1#) is 0 or len(#uv1#) is 0>
		Not enough information. <cfabort>
	</cfif>
	<cfif NOT structKeyExists(BULKLOADERCOLUMNS, ucase(trim(uc1)))>
		The column to update is not a bulkloader column. <cfabort>
	</cfif>
	<cfset variables.collected = collectFilters()>
	<cfif len(variables.collected.problem) GT 0>
		#encodeForHtml(variables.collected.problem)# <cfabort>
	</cfif>
	<!--- the pickers send these lists quoted --->
	<cfset enteredByCleaned = replace(enteredby,"'","","All")>
	<cfset accnCleaned = "">
	<cfif isdefined("accn")>
		<cfset accnCleaned = replace(accn,"'","","All")>
	</cfif>
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="data_result">
		UPDATE bulkloader
		SET #ucase(trim(uc1))# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#uv1#">
		WHERE
			enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
			<cfif len(accnCleaned) gt 0>
				AND accn IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accnCleaned#" list="yes">)
			</cfif>
			<cfloop array="#variables.collected.filters#" index="variables.filter">
				AND #variables.filter.column#
				<cfif variables.filter.op EQ "=">
					= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.filter.value#">
				<cfelseif variables.filter.op EQ "like">
					LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#variables.filter.value#%">
				<cfelseif variables.filter.op EQ "in">
					IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.filter.value#" list="yes">)
				<cfelse>
					BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="10" value="#variables.filter.low#"> AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="10" value="#variables.filter.high#">
				</cfif>
			</cfloop>
	</cfquery>
	<cfset rUrl="cloneWithBarcodes.cfm?action=sqlTab&enteredby=#enteredby#">
	<cfif isdefined("accn") and len(#accn#) gt 0>
		<cfset rUrl="#rUrl#&accn=#accn#">
	</cfif>

	<cfif isdefined("c1") and len(#c1#) gt 0 and isdefined("op1") and len(#op1#) gt 0 and isdefined("v1") and len(#v1#) gt 0>
		<cfset rUrl="#rUrl#&c1=#encodeForUrl(c1)#&op1=#encodeForUrl(op1)#&v1=#encodeForUrl(v1)#">
	</cfif>
	<cfif isdefined("c2") and len(#c2#) gt 0 and isdefined("op2") and len(#op2#) gt 0 and isdefined("v2") and len(#v2#) gt 0>
		<cfset rUrl="#rUrl#&c2=#encodeForUrl(c2)#&op2=#encodeForUrl(op2)#&v2=#encodeForUrl(v2)#">
	</cfif>
	<cfif isdefined("c3") and len(#c3#) gt 0 and isdefined("op3") and len(#op3#) gt 0 and isdefined("v3") and len(#v3#) gt 0>
		<cfset rUrl="#rUrl#&c3=#encodeForUrl(c3)#&op3=#encodeForUrl(op3)#&v3=#encodeForUrl(v3)#">
	</cfif>
	<cflocation url="#rUrl#" addtoken="false">
</cfoutput>
</cfif>
<!----------------------------------------------------------->
<cfif #action# is "saveCodes">
    <cfoutput>
        <cftransaction>
            newCodes: #newCodes#
	         <cfquery name="cleanup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	            delete from bulkloader_clone
            </cfquery>
            <cfloop list="#newCodes#" index="i">
	            <cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	                insert into bulkloader_clone
                    (select * from bulkloader where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">)
                </cfquery>
                <!--- should now have ONE record in clone with passed-in coid --->
                <cfquery name="fix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	                update
                        bulkloader_clone
                    set
                        collection_object_id=bulkloader_pkey.nextval,
                        PART_BARCODE_1=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(i)#">,
                        PART_CONTAINER_LABEL_1=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(i)#">
                    where
                        collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
                </cfquery>
	        </cfloop>
            <!--- move the new stuff over --->
            <cfquery name="move" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                insert into bulkloader (select * from bulkloader_clone)
            </cfquery>
            <!--- kill the original ---->
            <cfquery name="move" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                delete from bulkloader where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
            </cfquery>
        </cftransaction>
        <!--- outa here..... ---->
        Created #listLen(newCodes)# clones.

        <a href="cloneWithBarcodes.cfm">Click to continue.</a>
    </cfoutput>
</cfif>
<!----------------------------------------------------------->
<cfif #action# is "addCodes">
    <cfoutput>
        collection_object_id: #collection_object_id#<br>
        Number barcodes: #listlen(newCodes)#<br>
        <table border>
	        <tr>
	             <th>Container Unique ID</th>
	             <th>Status</th>
	         </tr>
             <cfset status=0>
	        <cfloop list="#newCodes#" index="i">
	            <cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                    select * from container where barcode=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(i)#">
                </cfquery>
                <tr>
                    <td>#i#</td>
                    <td>
                        <cfif data.recordcount is 0>
                            Not found.
                            <cfset status=status+1>
                        <cfelseif data.container_type is "label">
                            Cannot put stuff into labels.
                            <cfset status=status+1>
                        <cfelse>
                            <span style="color:green">
                                #data.container_type#
                            </span>
                        </cfif>
                    </td>
                </tr>
            </cfloop>
        </table>
        <cfif #status# is 0>
            Yay! Looks like this will work. Click
            <a href="cloneWithBarcodes.cfm?action=saveCodes&collection_object_id=#encodeForUrl(collection_object_id)#&newCodes=#encodeForUrl(newCodes)#">here</a>
            to continue.
        <cfelse>
            There are problems with the barcodes you entered. Everything above must be green to continue.
        </cfif>
    </cfoutput>
</cfif>
<!----------------------------------------------------------->
<cfif #action# is "sqlTab">
<cfoutput>
	<cfset variables.collected = collectFilters()>
	<cfif len(variables.collected.problem) GT 0>
		#encodeForHtml(variables.collected.problem)# <cfabort>
	</cfif>
	<!--- the pickers send these lists quoted --->
	<cfset enteredByCleaned = replace(enteredby,"'","","All")>
	<cfset accnCleaned = "">
	<cfif isdefined("accn")>
		<cfset accnCleaned = replace(accn,"'","","All")>
	</cfif>
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="data_result">
		SELECT *
		FROM bulkloader
		WHERE
			enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
			<cfif len(accnCleaned) gt 0>
				AND accn IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accnCleaned#" list="yes">)
			</cfif>
			<cfloop array="#variables.collected.filters#" index="variables.filter">
				AND #variables.filter.column#
				<cfif variables.filter.op EQ "=">
					= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.filter.value#">
				<cfelseif variables.filter.op EQ "like">
					LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#variables.filter.value#%">
				<cfelseif variables.filter.op EQ "in">
					IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.filter.value#" list="yes">)
				<cfelse>
					BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="10" value="#variables.filter.low#"> AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="10" value="#variables.filter.high#">
				</cfif>
			</cfloop>
	</cfquery>
	<cfquery name="cNames" datasource="uam_god">
		select column_name from user_tab_cols where table_name='BULKLOADER'
		order by internal_column_id
	</cfquery>
	<div style="background-color:##C0C0C0; font-size:smaller;">
		Use the top form to filter the table
		<br>
        Add a comma-delimited list of container unique ids to the record you wish to clone
        <br>Submit to:
        <ol>
            <li>check unique ids</li>
            <li>Create a clone of the row for each container unique id you entered</li>
            <li>Delete the original</li>
        </ol>
	</div>
	<form name="filter" method="post" action="cloneWithBarcodes.cfm">
		<input type="hidden" name="action" value="sqlTab">
		<input type="hidden" name="enteredby" value="#enteredby#">
		<cfif isdefined("accn") and len(#accn#) gt 0>
			<input type="hidden" name="accn" value="#accn#">
		</cfif>
		<h2>Create Filter:</h2>
		<table border>
			<tr>
				<th>
					Column
				</th>
				<th>Operator</th>
				<th>Value</th>
			</tr>
			<tr>
				<td>
					<select name="c1" size="1">
						<option value=""></option>
						<cfloop query="cNames">
							<option
								<cfif isdefined("c1") and #c1# is #column_name#> selected="selected" </cfif>value="#column_name#">#column_name#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<select name="op1" size="1">
						<option <cfif isdefined("op1") and op1 is "="> selected="selected" </cfif>value="=">=</option>
						<option <cfif isdefined("op1") and op1 is "like"> selected="selected" </cfif>value="like">like</option>
						<option <cfif isdefined("op1") and op1 is "in"> selected="selected" </cfif>value="in">in</option>
						<option <cfif isdefined("op1") and op1 is "between"> selected="selected" </cfif>value="between">between</option>
					</select>
				</td>
				<td>
					<input type="text" name="v1" <cfif isdefined("v1")> value="#v1#"</cfif> size="50">
				</td>
			</tr>
			<tr>
				<td>
					<select name="c2" size="1">
						<option value=""></option>
						<cfloop query="cNames">
							<option
								<cfif isdefined("c2") and #c2# is #column_name#> selected="selected" </cfif>value="#column_name#">#column_name#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<select name="op2" size="1">
						<option <cfif isdefined("op2") and op2 is "="> selected="selected" </cfif>value="=">=</option>
						<option <cfif isdefined("op2") and op2 is "like"> selected="selected" </cfif>value="like">like</option>
						<option <cfif isdefined("op2") and op2 is "in"> selected="selected" </cfif>value="in">in</option>
						<option <cfif isdefined("op2") and op2 is "between"> selected="selected" </cfif>value="between">between</option>
					</select>
				</td>
				<td>
					<input type="text" name="v2" <cfif isdefined("v2")> value="#v2#"</cfif> size="50">
				</td>
			</tr>
			<tr>
				<td>
					<select name="c3" size="1">
						<option value=""></option>
						<cfloop query="cNames">
							<option
								<cfif isdefined("c3") and #c3# is #column_name#> selected="selected" </cfif>value="#column_name#">#column_name#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<select name="op3" size="1">
						<option <cfif isdefined("op3") and op3 is "="> selected="selected" </cfif>value="=">=</option>
						<option <cfif isdefined("op3") and op3 is "like"> selected="selected" </cfif>value="like">like</option>
						<option <cfif isdefined("op3") and op3 is "in"> selected="selected" </cfif>value="in">in</option>
						<option <cfif isdefined("op3") and op3 is "between"> selected="selected" </cfif>value="between">between</option>
					</select>
				</td>
				<td>
					<input type="text" name="v3" <cfif isdefined("v3")> value="#v3#"</cfif> size="50">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<input type="submit" value="Filter">
				</td>
			</tr>
		</table>
	</form>
    <!---
	<h2>Update data in table below:</h2>
	<form name="up" method="post" action="cloneWithBarcodes.cfm">
		<input type="hidden" name="action" value="runSQLUp">
		<input type="hidden" name="enteredby" value="#enteredby#">
		<cfif isdefined("accn") and len(#accn#) gt 0>
			<input type="hidden" name="accn" value="#accn#">
		</cfif>
		<cfif isdefined("c1") and len(#c1#) gt 0 and isdefined("op1") and len(#op1#) gt 0 and isdefined("v1") and len(#v1#) gt 0>
			<input type="hidden" name="c1" value="#c1#">
			<input type="hidden" name="op1" value="#op1#">
			<input type="hidden" name="v1" value="#v1#">
		</cfif>
		<cfif isdefined("c2") and len(#c2#) gt 0 and isdefined("op2") and len(#op2#) gt 0 and isdefined("v2") and len(#v2#) gt 0>
			<input type="hidden" name="c2" value="#c2#">
			<input type="hidden" name="op2" value="#op2#">
			<input type="hidden" name="v2" value="#v2#">
		</cfif>
		<cfif isdefined("c3") and len(#c3#) gt 0 and isdefined("op3") and len(#op3#) gt 0 and isdefined("v3") and len(#v3#) gt 0>
			<input type="hidden" name="c3" value="#c3#">
			<input type="hidden" name="op3" value="#op3#">
			<input type="hidden" name="v3" value="#v3#">
		</cfif>
		<table border>
			<tr>
				<th>
					Column
				</th>
				<th>Update To</th>
				<th>Value</th>
			</tr>
			<tr>
				<td>
					<select name="uc1" size="1">
						<option value=""></option>
						<cfloop query="cNames">
							<option value="#column_name#">#column_name#</option>
						</cfloop>
					</select>
				</td>
				<td>
					-->
				</td>
				<td>
					<input type="text" name="uv1" size="50">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<input type="submit" value="Update">
				</td>
			</tr>
		</table>
	</form>
	---->
	<div class="blTabDiv">
		<table border id="t" class="sortable">
			<tr>
                <th>New Container Unique IDs(comma-separated)</th>
			<cfloop query="cNames">
				<th>#column_name#</th>
			</cfloop>
			<cfloop query="data">
				<tr>
				<cfquery name="thisRec" dbtype="query">
					select * from data where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#data.collection_object_id#">
				</cfquery>
                <td>
                    <form name="addCodes" action="" method="post">
                        <input type="hidden" name="action" value="addCodes">
                        <input type="hidden" name="collection_object_id" value="#data.collection_object_id#">
                        <textarea name="newCodes" rows="5" cols="30" wrap="soft"></textarea>
                        <input type="submit" value="Create Clones">
                    </form>
                </td>
				<cfloop query="cNames">
					<cfset thisData = thisRec[cNames.column_name][1]>
					<td>#thisData#</td>
				</cfloop>
				</tr>
			</cfloop>
			</tr>
		</table>
	</div>
</cfoutput>
</cfif>
<!-------------------------->
<cfif #action# is "saveGridUpdate">
<cfoutput>
<cfset GridName = "blGrid">
<cfset numRows = #ArrayLen(form[GridName].rowstatus.action)#>
<p></p>there are	#numRows# rows updated
<!--- one update per grid row, setting only the columns whose values changed --->
<cfloop from="1" to="#numRows#" index="i">
	<cfset thisCollObjId = form[GridName]["collection_object_id"][i]>
	<cfset variables.changed = structNew()>
	<cfloop collection="#BULKLOADERCOLUMNS#" item="ColName">
		<cfif ColName NEQ "COLLECTION_OBJECT_ID" AND structKeyExists(form[GridName], ColName) AND structKeyExists(form[GridName].original, ColName)>
			<cfset oldValue = form[GridName].original[ColName][i]>
			<cfset newValue = form[GridName][ColName][i]>
			<cfif oldValue NEQ newValue>
				<cfset variables.changed[ColName] = newValue>
			</cfif>
		</cfif>
	</cfloop>
	<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="up_result">
		UPDATE bulkloader
		SET collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisCollObjId#">
			<cfloop collection="#variables.changed#" item="ColName">
				, #ColName# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.changed[ColName]#">
			</cfloop>
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisCollObjId#">
	</cfquery>
</cfloop>
<cflocation url="cloneWithBarcodes.cfm?action=viewTable&enteredby=#enteredby#&accn=#accn#">
</cfoutput>
</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "upBulk">
<cfoutput>
	<!--- the columns the viewTable form offers --->
	<cfset UPBULKCOLUMNS = "SPEC_LOCALITY,HIGHER_GEOG,ENTEREDBY,LOADED,ACCN,OTHER_ID_NUM_5">
	<cfif len(#loaded#) gt 0 and
		len(#column_name#) gt 0 and
		len(#tValue#) gt 0>
		<cfif listFindNoCase(UPBULKCOLUMNS, column_name) EQ 0 OR NOT structKeyExists(BULKLOADERCOLUMNS, ucase(column_name))>
			The column to match is not one this form offers. <cfabort>
		</cfif>
		<!--- the pickers send these lists quoted --->
		<cfset enteredByCleaned = replace(enteredby,"'","","All")>
		<cfset accnCleaned = "">
		<cfif isdefined("accn")>
			<cfset accnCleaned = replace(accn,"'","","All")>
		</cfif>
		<cfquery name="upBulk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upBulk_result">
			UPDATE bulkloader
			SET LOADED =
				<cfif #loaded# is "NULL">
					NULL
				<cfelse>
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loaded#">
				</cfif>
			WHERE
				#ucase(column_name)# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(tValue)#">
				AND enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
				<cfif len(accnCleaned) gt 0>
					AND accn IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accnCleaned#" list="yes">)
				</cfif>
		</cfquery>
	</cfif>

<cflocation url="cloneWithBarcodes.cfm?action=viewTable&enteredby=#enteredby#&accn=#accn#">

</cfoutput>
</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "viewTable">
<cfoutput>
<!--- the pickers send these lists quoted --->
<cfset enteredByCleaned = replace(enteredby,"'","","All")>
<cfset accnCleaned = "">
<cfif isdefined("accn")>
	<cfset accnCleaned = replace(accn,"'","","All")>
</cfif>
<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="data_result">
	SELECT *
	FROM bulkloader
	WHERE
			enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#enteredByCleaned#" list="yes">)
			<cfif len(accnCleaned) gt 0>
				AND accn IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accnCleaned#" list="yes">)
			</cfif>
</cfquery>
<cfquery name="cNames" datasource="uam_god">
	select column_name from user_tab_cols where table_name='BULKLOADER'
	order by internal_column_id
</cfquery>
<div style="background-color:##FFFFCC;">
Roll yer own:
<cfset columnList = "SPEC_LOCALITY,HIGHER_GEOG,ENTEREDBY,LOADED,ACCN,OTHER_ID_NUM_5">

<form name="bulkStuff" method="post" action="cloneWithBarcodes.cfm">
	<input type="hidden" name="action" value="upBulk" />
	<input type="hidden" name="enteredby" value="#enteredby#" />
	<input type="hidden" name="accn" value="#accn#" />
	UPDATE bulkloader SET LOADED =
	<select name="loaded" size="1">
		<option value="NULL">NULL</option>
		<option value="FLAGGED BY BULKLOADER EDITOR">FLAGGED BY BULKLOADER EDITOR</option>
		<option value="MARK FOR DELETION">MARK FOR DELETION</option>
	</select>
	<br />WHERE
	<select name="column_name" size="1">
		<CFLOOP list="#columnList#" index="i">
			<option value="#i#">#i#</option>
		</CFLOOP>
	</select>
	= TRIM(
	<input type="text" name="tValue" size="50" />)
	<br />
	<input type="submit"
				value="Update All Matches"
				class="savBtn"
				onmouseover="this.className='savBtn btnhov'"
				onmouseout="this.className='savBtn'">
</form>
</div>
<hr /><cfset ColNameList = valuelist(cNames.column_name)>
<cfset ColNameList = replace(ColNameList,"COLLECTION_OBJECT_ID","","all")>
<!---
<cfset ColNameList = replace(ColNameList,"LOADED","","all")>
<cfset ColNameList = replace(ColNameList,"ENTEREDBY","","all")>
--->
<hr />There are #data.recordcount# records in this view.
<cfform method="post" action="cloneWithBarcodes.cfm">
	<cfinput type="hidden" name="action" value="saveGridUpdate">
	<cfinput type="hidden" name="enteredby" value="#enteredby#">
	<cfinput type="hidden" name="accn" value="#accn#">
	<cfgrid query="data"  name="blGrid" width="1200" height="400" selectmode="edit">
		<cfgridcolumn name="collection_object_id" select="no" href="/DataEntry.cfm?action=editEnterData&showAllUsers=true&pMode=edit" hrefkey="collection_object_id" target="_blank">
		<!----
		<cfgridcolumn name="loaded" select="yes">
		<cfgridcolumn name="ENTEREDBY" select="yes">
		---->
		<cfloop list="#ColNameList#" index="thisName">
			<cfgridcolumn name="#thisName#">
		</cfloop>
	<cfinput type="submit" name="save" value="Save Changes In Grid">
	</cfgrid>
</cfform>

</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">