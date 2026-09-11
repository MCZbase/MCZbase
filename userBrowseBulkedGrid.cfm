<cfinclude template="/includes/_header.cfm">
<!--- This page sits at the web root, which Application.cfc's directory gate does not cover,
	and it edits staged bulkloader rows.  action was read without being declared, so a request
	without it failed on an undefined variable. --->
<cf_rolecheck>
<cfparam name="form.action" default="nothing">
<cfparam name="url.action" default="">
<cfset variables.action = form.action>
<cfif len(url.action) GT 0>
	<cfset variables.action = url.action>
</cfif>
<cfif variables.action is "ajaxGrid">
<cfoutput>
<cfquery name="cNames" datasource="uam_god">
	select column_name from user_tab_cols where table_name='BULKLOADER'
	order by internal_column_id
</cfquery>
<cfset ColNameList = valuelist(cNames.column_name)>
<cfset ColNameList = replace(ColNameList,"COLLECTION_OBJECT_ID","","all")>

<cfset ColNameList = replace(ColNameList,"LOADED","","all")>
<cfset ColNameList = replace(ColNameList,"ENTEREDBY","","all")>
<cfset args.width="1200">
<cfset args.stripeRows = true>
<cfset args.selectColor = "##D9E8FB">
<cfset args.selectmode = "edit">
<cfset args.format="html">
<cfset args.onchange = "cfc:component.Bulkloader.editRecord({cfgridaction},{cfgridrow},{cfgridchanged})">
<cfset args.bind="cfc:component.Bulkloader.getPage({cfgridpage},{cfgridpagesize},{cfgridsortcolumn},{cfgridsortdirection},{accn},{enteredby},{colln})">
<cfset args.name="blGrid">
<cfset args.pageSize="20">
<cfform method="post" action="userBrowseBulkedGrid.cfm">
	<cfinput type="hidden" name="returnAction" value="ajaxGrid">
	<cfinput type="hidden" name="action" value="saveGridUpdate">
	<!--- Unquoted: component/Bulkloader.cfc binds this as a list, and quotes carried in the
		value would become part of the element rather than delimit it. --->
	<cfinput type="hidden" name="enteredby" value="#session.username#">
	<cfinput type="hidden" name="accn" value="">
	<cfinput type="hidden" name="colln" value="">
	<cfgrid attributeCollection="#args#">
		<cfgridcolumn name="collection_object_id" select="no" href="/DataEntry.cfm?action=editEnterData&pMode=edit" 
			hrefkey="collection_object_id" header="Key">
		<cfgridcolumn name="loaded" select="no" header="loaded">
		<cfgridcolumn name="enteredby" select="no" header="enteredby">
		<cfloop list="#ColNameList#" index="thisName">
			<cfgridcolumn name="#thisName#">
		</cfloop>
	</cfgrid>
</cfform>
</cfoutput>
</cfif>







<cfif variables.action is "nothing">

<cfquery name="getCols" datasource="uam_god">
	select column_name from sys.user_tab_cols
	where table_name='BULKLOADER'
	order by internal_column_id
</cfquery>
<cfoutput>
<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select * from bulkloader
	where enteredby = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
</cfquery>
<cfset ColNameList = valuelist(getCols.column_name)>
<cfset ColNameList = replace(ColNameList,"COLLECTION_OBJECT_ID","","all")>
<cfset ColNameList = replace(ColNameList,"LOADED","","all")>
<cfset ColNameList = replace(ColNameList,"ENTEREDBY","","all")>
<cfform method="post" action="userBrowseBulkedGrid.cfm" >
	<cfinput type="hidden" name="action" value="saveGridUpdate">
	<cfgrid query="data"  name="blGrid" width="1200" height="400" selectmode="edit">
		<cfgridcolumn name="collection_object_id" select="no" href="/DataEntry.cfm?action=editEnterData&pMode=edit" hrefkey="collection_object_id" target="_blank">
		<cfgridcolumn name="loaded" select="no">
		<cfgridcolumn name="ENTEREDBY" select="no">
		<cfloop list="#ColNameList#" index="thisName">
			<cfgridcolumn name="#thisName#">
		</cfloop>
	</cfgrid>
	<br>
	<cfinput type="submit" name="save" value="Save Changes In Grid">
</cfform>
</cfoutput>


</cfif>

<cfif variables.action is "saveGridUpdate">
<cfoutput>
<cfquery name="cNames" datasource="uam_god">
	select column_name from user_tab_cols where table_name='BULKLOADER'
</cfquery>
<cfset ColNameList = valuelist(cNames.column_name)>
<cfset GridName = "blGrid">
<cfset numRows = #ArrayLen(form.blGrid.rowstatus.action)#>
<p></p>there are	#numRows# rows updated
<!--- loop for each record --->
<cfloop from="1" to="#numRows#" index="i">
	<!--- and for each column --->
	<cfset thisCollObjId = evaluate("Form.#GridName#.collection_object_id[#i#]")>
	<cfif NOT isNumeric(thisCollObjId)>
		<cfthrow type="InvalidParameter" message="collection_object_id must be numeric.">
	</cfif>
	
	<!--- Column names come from the data dictionary and are trusted; the values come from the
		posted grid and bind.  collection_object_id is skipped in the loop: it is set once from
		the validated key above, and setting a column twice in one SET list is not legal. --->
	<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		UPDATE bulkloader SET
			collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisCollObjId#">
		<cfloop index="ColName" list="#ColNameList#">
			<cfif ColName IS NOT "collection_object_id">
				<cfset oldValue = evaluate("Form.#GridName#.original.#ColName#[#i#]")>
				<cfset newValue = evaluate("Form.#GridName#.#ColName#[#i#]")>
				<cfif oldValue neq newValue>
					,#ColName# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newValue#">
				</cfif>
			</cfif>
		</cfloop>
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisCollObjId#">
	</cfquery>
	


	

</cfloop>
	<cflocation url="userBrowseBulkedGrid.cfm" addtoken="false">
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">