<cfinclude template="../includes/_pickHeader.cfm">
<cfoutput>
	<cfif action is "nothing">
		<form name="searchForNamedCollection" action="findNamedCollection.cfm" method="post">
			<input type="hidden" name="action" value="srch">
			<input type="hidden" name="NameFld" value="#NameFld#">
			<input type="hidden" name="IdFld" value="#IdFld#">
			<input type="hidden" name="formName" value="#formName#">
			<label for="collection_name">Name for the group of cataloged items</label>
			<input type="text" name="colleciton_name" id="collection_name" >
			<input type="submit"
				value="Search"
				class="lnkBtn"
				onmouseover="this.className='lnkBtn btnhov'"
				onmouseout="this.className='lnkBtn'">
		</form>
	</cfif>
	<cfif action is "srch">
		<cfquery name="lookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				underscore_collection_id,
				collection_name,
				underscore_collection_type 
			FROM
				underscore_collection
			WHERE
				upper(collection_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(collection_name)#%">
			ORDER BY
				collection_name
		</cfquery>
		<cfif #lookup.recordcount# is 0>
			Nothing matched. <a href="findNamedGroup.cfm?formName=#formName#&NameFld=#NameFld#&IdFld=#IdFld#">Try again.</a>
		<cfelse>
			<table border>
				<tr>
					<td>Named Group</td>
				</tr>
				<cfloop query="lookup">
					<cfif #lookup.recordcount# is 1>
						<script>
							opener.document.#formName#.#NameFld#.value='#collection_name#';
							opener.document.#formName#.#IdFld#.value='#underscore_collection_id#';
							opener.document.#formName#.#NameFld#.style.background='##8BFEB9';
							self.close();
						</script>
					<cfelse>
						<tr>
							<td>
								<a href="##" onClick="javascript: opener.document.#formName#.#NameFld#.value='#collection_name#';
									opener.document.#formName#.#IdFld#.value='#underscore_collection_id#';self.close();">#collection_name#</a>
							</td>
						</tr>
					</cfif>
				</cfloop>
			</table>
		</cfif>
	</cfif>
</cfoutput>
<cfinclude template="../includes/_pickFooter.cfm">
