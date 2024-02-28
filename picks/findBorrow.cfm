<cfinclude template="../includes/_pickHeader.cfm">
<cfoutput>
	<cfif action is "nothing">
		<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select collection_id,collection from collection order by collection
		</cfquery>
		<form name="searchForBorrow" action="findBorrow.cfm" method="post">
			<input type="hidden" name="action" value="srch">
			<input type="hidden" name="BorrowNumFld" value="#BorrowNumFld#">
			<input type="hidden" name="BorrowIdFld" value="#BorrowIdFld#">
			<input type="hidden" name="formName" value="#formName#">
			<label for="collection_id">Collection</label>
			<select name="collection_id" id="collection_id">
				<option value=""></option>
				<cfloop query="ctcollection">
					<option value="#collection_id#">#collection#</option>
				</cfloop>
			</select>
			<label for="Borrow_number">Borrow Number</label>
			<input type="text" name="Borrow_number" id="Borrow_number" placeholder="Byyyy-n-Col">
			<input type="submit"
				value="Search"
				class="lnkBtn"
				onmouseover="this.className='lnkBtn btnhov'"
				onmouseout="this.className='lnkBtn'">
		</form>
	</cfif>
	<cfif action is "srch">
		<cfquery name="getBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				collection,
				borrow_number,
				borrow.transaction_id
			FROM
				borrow,
				trans,
				collection
			WHERE
				borrow.transaction_id=trans.transaction_id and
				trans.collection_id=collection.collection_id and
				<cfif len(collection_id) gt 0>
					collection.collection_id=#collection_id# and
				</cfif>
				upper(borrow_number) like '%#ucase(borrow_number)#%'
			ORDER BY
				collection,
				borrow_number
		</cfquery>
		<cfif #getBorrow.recordcount# is 0>
			Nothing matched. <a href="findBorrow.cfm?formName=#formName#&BorrowNumFld=#BorrowNumFld#&BorrowIdFld=#BorrowIdFld#">Try again.</a>
		<cfelse>
			<table border>
				<tr>
					<td>Borrow</td>
				</tr>
				<cfloop query="getBorrow">
					<cfif #getBorrow.recordcount# is 1>
						<script>
							opener.document.#formName#.#BorrowNumFld#.value='#collection# #Borrow_number#';
							opener.document.#formName#.#BorrowIdFld#.value='#transaction_id#';
							opener.document.#formName#.#BorrowNumFld#.style.background='##8BFEB9';
							self.close();
						</script>
					<cfelse>
						<tr>
							<td>
								<a href="##" onClick="javascript: opener.document.#formName#.#BorrowNumFld#.value='#collection# #Borrow_number#';
									opener.document.#formName#.#BorrowIdFld#.value='#transaction_id#';self.close();">#collection# #Borrow_number#</a>
							</td>
						</tr>
					</cfif>
				</cfloop>
			</table>
		</cfif>
	</cfif>
</cfoutput>
<cfinclude template="../includes/_pickFooter.cfm">
