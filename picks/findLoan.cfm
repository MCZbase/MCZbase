<cfinclude template="../includes/_pickHeader.cfm">
<cfoutput>
	<cfif action is "nothing">
		<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select collection_id,collection from collection order by collection
		</cfquery>
		<form name="searchForLoan" action="findLoan.cfm" method="post">
			<input type="hidden" name="action" value="srch">
			<input type="hidden" name="LoanNumFld" value="#LoanNumFld#">
			<input type="hidden" name="LoanIdFld" value="#LoanIdFld#">
			<input type="hidden" name="formName" value="#formName#">
			<label for="collection_id">Collection</label>
			<select name="collection_id" id="collection_id">
				<option value=""></option>
				<cfloop query="ctcollection">
					<option value="#collection_id#">#collection#</option>
				</cfloop>
			</select>
			<label for="Loan_number">Loan Number</label>
			<input type="text" name="Loan_number" id="Loan_number">
			<input type="submit"
				value="Search"
				class="lnkBtn"
				onmouseover="this.className='lnkBtn btnhov'"
				onmouseout="this.className='lnkBtn'">
		</form>
	</cfif>
	<cfif action is "srch">
		<cfquery name="getLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				collection,
				Loan_number,
				Loan.transaction_id
			FROM
				Loan,
				trans,
				collection
			WHERE
				Loan.transaction_id=trans.transaction_id and
				trans.collection_id=collection.collection_id and
				<cfif len(collection_id) gt 0>
					collection.collection_id=#collection_id# and
				</cfif>
				upper(Loan_number) like '%#ucase(Loan_number)#%'
			ORDER BY
				collection,
				Loan_number
		</cfquery>
		<cfif #getLoan.recordcount# is 0>
			Nothing matched. <a href="findLoan.cfm?formName=#formName#&LoanNumFld=#LoanNumFld#&LoanIdFld=#LoanIdFld#">Try again.</a>
		<cfelse>
			<table border>
				<tr>
					<td>Loan</td>
				</tr>
				<cfloop query="getLoan">
					<cfif #getLoan.recordcount# is 1>
						<script>
							opener.document.#formName#.#LoanNumFld#.value='#collection# #Loan_number#';
							opener.document.#formName#.#LoanIdFld#.value='#transaction_id#';
							opener.document.#formName#.#LoanNumFld#.style.background='##8BFEB9';
							self.close();
						</script>
					<cfelse>
						<tr>
							<td>
								<a href="##" onClick="javascript: opener.document.#formName#.#LoanNumFld#.value='#collection# #Loan_number#';
									opener.document.#formName#.#LoanIdFld#.value='#transaction_id#';self.close();">#collection# #Loan_number#</a>
							</td>
						</tr>
					</cfif>
				</cfloop>
			</table>
		</cfif>
	</cfif>
</cfoutput>
<cfinclude template="../includes/_pickFooter.cfm">