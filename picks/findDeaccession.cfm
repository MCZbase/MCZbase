<cfinclude template="../includes/_pickHeader.cfm">
<cfoutput>
	<cfif action is "nothing">
		<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select collection_id,collection from collection order by collection
		</cfquery>
		<form name="searchForAccn" action="findDeaccession.cfm" method="post">
			<input type="hidden" name="action" value="srch">
			<input type="hidden" name="DeaccNumFld" value="#DeaccNumFld#">
			<input type="hidden" name="DeaccIdFld" value="#DeaccIdFld#">
			<input type="hidden" name="formName" value="#formName#">
			<label for="collection_id">Collection</label>
			<select name="collection_id" id="collection_id">
				<option value=""></option>
				<cfloop query="ctcollection">
					<option value="#collection_id#">#collection#</option>
				</cfloop>
			</select>
			<label for="deacc_number">Deaccession Number</label>
			<input type="text" name="deacc_number" id="deacc_number">
			<input type="submit" 
				value="Search" 
				class="lnkBtn"
				onmouseover="this.className='lnkBtn btnhov'"
				onmouseout="this.className='lnkBtn'">
		</form>
	</cfif>
	<cfif action is "srch">
		<cfquery name="getDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				collection,
				deacc_number,
				deaccession.transaction_id
			FROM
				deaccession,
				trans,
				collection
			WHERE
				deaccession.transaction_id=trans.transaction_id and
				trans.collection_id=collection.collection_id and
				<cfif len(collection_id) gt 0>
					collection.collection_id=#collection_id# and
				</cfif>
				upper(deacc_number) like '%#ucase(deacc_number)#%'
			ORDER BY
				collection,
				deacc_number
		</cfquery>
		<cfif #getDeacc.recordcount# is 0>
			Nothing matched. <a href="findDeaccession.cfm?formName=#formName#&DeaccNumFld=#DeaccNumFld#&DeaccIdFld=#DeaccIdFld#">Try again.</a>
		<cfelse>
			<table border>
				<tr>
					<td>Deaccession</td>
				</tr>
				<cfloop query="getDeacc">
					<cfif #getDeacc.recordcount# is 1>
						<script>
							opener.document.#formName#.#DeaccNumFld#.value='#collection# #deacc_number#';
							opener.document.#formName#.#DeaccIdFld#.value='#transaction_id#';
							opener.document.#formName#.#DeaccNumFld#.style.background='##8BFEB9';
							self.close();
						</script>
					<cfelse>
						<tr>
							<td>
								<a href="##" onClick="javascript: opener.document.#formName#.#DeaccNumFld#.value='#collection# #deacc_number#';
									opener.document.#formName#.#DeaccIdFld#.value='#transaction_id#';self.close();">#collection# #deacc_number#</a>
							</td>
						</tr>
					</cfif>
				</cfloop>
			</table>
		</cfif>
	</cfif>
</cfoutput>
<cfinclude template="../includes/_pickFooter.cfm">
