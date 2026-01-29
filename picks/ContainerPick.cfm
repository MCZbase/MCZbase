<cfinclude template="../includes/_pickHeader.cfm">
<cfset title = "Container Pick">
<!--- build a container id search --->
<form name="searchForContainer" action="/picks/ContainerPick.cfm" method="post">
	<br>Container Name: <input type="text" name="containername">
	<br><input type="submit" value="Find Matches">
	<input type="hidden" name="search" value="true">
	<cfoutput>
		<input type="hidden" name="IdFld" value="#IdFld#">
		<input type="hidden" name="NameFld" value="#NameFld#">
		<input type="hidden" name="formName" value="#formName#">
	</cfoutput>
</form>
<cfif isdefined("search") and #search# is "true">
	<!--- make sure we're searching for something --->
	<cfif len(#containername#) is 0>
		You must enter search criteria.
		<cfabort>
	</cfif>
	<cfoutput>
		<cfquery name="getContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT label, barcode, container_type, container_id 
			FROM container
			where
				UPPER(label) LIKE <cfqueryparam value="%#ucase(containername)#%" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
	</cfoutput>
	<cfoutput query="getContainerId">
<br>
<cfset thisName = #replace(label,"'","`","all")#>
<cfif barcode NEQ label and len(barcode) GT 0>
	<cfset thisName = #thisName# & " [#barcode#]">
</cfif>
<a href="##" onClick="javascript: opener.document.#formName#.#containerIdFld#.value='#container_id#';opener.document.#formName#.#containerNameFld#.value='#thisName#';self.close();">
#label#
<cfif barcode NEQ label and len(barcode) GT 0>
	[#barcode#]
</cfif>
(#container_type#)
</a>
	</cfoutput>
</cfif>
<cfinclude template="../includes/_pickFooter.cfm">
