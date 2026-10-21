<cfinclude template="../includes/_pickHeader.cfm">
<cfset title = "Permit Pick">
<cfparam name="url.action" default="">
<cfparam name="form.action" default="">
<cfparam name="url.PermitNumFld" default="">
<cfparam name="form.PermitNumFld" default="">
<cfparam name="url.PermitIdFld" default="">
<cfparam name="form.PermitIdFld" default="">
<cfparam name="url.formName" default="">
<cfparam name="form.formName" default="">
<cfparam name="form.IssuedByAgent" default="">
<cfparam name="form.IssuedToAgent" default="">
<cfparam name="form.issued_Date" default="">
<cfparam name="form.renewed_Date" default="">
<cfparam name="form.exp_Date" default="">
<cfparam name="form.permit_Num" default="">
<cfparam name="form.permit_Type" default="">
<cfparam name="form.permit_remarks" default="">
<cfset variables.action = "nothing">
<cfif form.action EQ "search">
	<cfset variables.action = "search">
</cfif>
<!--- the opener's form and fields the pick fills in; only names, as they are written into script --->
<cfset variables.formName = form.formName>
<cfif len(variables.formName) EQ 0><cfset variables.formName = url.formName></cfif>
<cfset variables.PermitNumFld = form.PermitNumFld>
<cfif len(variables.PermitNumFld) EQ 0><cfset variables.PermitNumFld = url.PermitNumFld></cfif>
<cfset variables.PermitIdFld = form.PermitIdFld>
<cfif len(variables.PermitIdFld) EQ 0><cfset variables.PermitIdFld = url.PermitIdFld></cfif>
<cfloop list="formName,PermitNumFld,PermitIdFld" index="targetName">
	<cfif NOT REFind("^[A-Za-z_][A-Za-z0-9_]*$", variables[targetName])>
		<cfoutput>This picker was opened without a valid #targetName#.</cfoutput>
		<cfinclude template="../includes/_pickFooter.cfm">
		<cfabort>
	</cfif>
</cfloop>
<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT permit_type FROM ctpermit_type ORDER BY permit_type
</cfquery>
<cfoutput>
	<script>
		/** Fill in the opener's permit fields with the picked permit and close this window.
		 * @param permitId the permit_id of the picked permit.
		 * @param permitLabel the permit number and type to show in the opener.
		 */
		function pickPermit(permitId, permitLabel) {
			var form = opener.document.forms['#encodeForJavaScript(variables.formName)#'];
			form.elements['#encodeForJavaScript(variables.PermitNumFld)#'].value = permitLabel;
			form.elements['#encodeForJavaScript(variables.PermitIdFld)#'].value = permitId;
			form.elements['#encodeForJavaScript(variables.PermitNumFld)#'].style.background = '##8BFEB9';
			self.close();
		}
	</script>
	<cfif variables.action EQ "nothing">
		Search for permits. Any part of dates (yyyy-mm-dd) and names accepted, case isn't important.<br>
		<form name="findPermit" action="findPermit.cfm" method="post">
			<input type="hidden" name="action" value="search">
			<input type="hidden" name="PermitNumFld" value="#encodeForHtmlAttribute(variables.PermitNumFld)#">
			<input type="hidden" name="PermitIdFld" value="#encodeForHtmlAttribute(variables.PermitIdFld)#">
			<input type="hidden" name="formName" value="#encodeForHtmlAttribute(variables.formName)#">
			<table>
				<tr>
					<td><label for="IssuedByAgent">Issued By</label></td>
					<td><input type="text" name="IssuedByAgent" id="IssuedByAgent"></td>
					<td><label for="IssuedToAgent">Issued To</label></td>
					<td><input type="text" name="IssuedToAgent" id="IssuedToAgent"></td>
				</tr>
				<tr>
					<td><label for="issued_Date">Issued Date</label></td>
					<td><input type="text" name="issued_Date" id="issued_Date"></td>
					<td><label for="renewed_Date">Renewed Date</label></td>
					<td><input type="text" name="renewed_Date" id="renewed_Date"></td>
				</tr>
				<tr>
					<td><label for="exp_Date">Expiration Date</label></td>
					<td><input type="text" name="exp_Date" id="exp_Date"></td>
					<td><label for="permit_Num">Permit Number</label></td>
					<td><input type="text" name="permit_Num" id="permit_Num"></td>
				</tr>
				<tr>
					<td><label for="permit_Type">Permit Type</label></td>
					<td>
						<select name="permit_Type" id="permit_Type" size="1">
							<option value=""></option>
							<cfloop query="ctPermitType">
								<option value="#encodeForHtmlAttribute(ctPermitType.permit_type)#">#encodeForHtml(ctPermitType.permit_type)#</option>
							</cfloop>
						</select>
					</td>
					<td><label for="permit_remarks">Remarks</label></td>
					<td><input type="text" name="permit_remarks" id="permit_remarks"></td>
				</tr>
				<tr>
					<td colspan="4" align="center">
						<input type="submit" value="Search" class="schBtn">
						<img src="../images/nada.gif" width="30" alt="">
						<input type="reset" value="Clear" class="clrBtn">
					</td>
				</tr>
			</table>
		</form>
	</cfif>
	<cfif variables.action EQ "search">
		<cfset variables.searchAgain = "findPermit.cfm?formName=#encodeForUrl(variables.formName)#&PermitNumFld=#encodeForUrl(variables.PermitNumFld)#&PermitIdFld=#encodeForUrl(variables.PermitIdFld)#">
		<cfif len(form.IssuedByAgent & form.IssuedToAgent & form.issued_Date & form.renewed_Date & form.exp_Date & form.permit_Num & form.permit_Type & form.permit_remarks) EQ 0>
			<p>Enter some criteria. <a href="#encodeForHtmlAttribute(variables.searchAgain)#">Try again.</a></p>
			<cfinclude template="../includes/_pickFooter.cfm">
			<cfabort>
		</cfif>
		<cfquery name="matchPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="matchPermit_result">
			SELECT
				permit.permit_id,
				issuedByPref.agent_name issued_by_agent,
				issuedToPref.agent_name issued_to_agent,
				permit.issued_date,
				permit.renewed_date,
				permit.exp_date,
				permit.permit_num,
				permit.permit_type,
				permit.permit_remarks
			FROM
				permit
				JOIN preferred_agent_name issuedByPref ON permit.issued_by_agent_id = issuedByPref.agent_id
				JOIN preferred_agent_name issuedToPref ON permit.issued_to_agent_id = issuedToPref.agent_id
			WHERE
				permit.permit_id IS NOT NULL
				<cfif len(form.IssuedByAgent) GT 0>
					AND permit.issued_by_agent_id IN (
						SELECT agent_id FROM agent_name
						WHERE upper(agent_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(form.IssuedByAgent)#%">
					)
				</cfif>
				<cfif len(form.IssuedToAgent) GT 0>
					AND permit.issued_to_agent_id IN (
						SELECT agent_id FROM agent_name
						WHERE upper(agent_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(form.IssuedToAgent)#%">
					)
				</cfif>
				<cfif len(form.issued_Date) GT 0>
					AND to_char(permit.issued_date, 'YYYY-MM-DD') LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#form.issued_Date#%">
				</cfif>
				<cfif len(form.renewed_Date) GT 0>
					AND to_char(permit.renewed_date, 'YYYY-MM-DD') LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#form.renewed_Date#%">
				</cfif>
				<cfif len(form.exp_Date) GT 0>
					AND to_char(permit.exp_date, 'YYYY-MM-DD') LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#form.exp_Date#%">
				</cfif>
				<cfif len(form.permit_Num) GT 0>
					AND permit.permit_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.permit_Num#">
				</cfif>
				<cfif len(form.permit_Type) GT 0>
					AND permit.permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.permit_Type#">
				</cfif>
				<cfif len(form.permit_remarks) GT 0>
					AND upper(permit.permit_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(form.permit_remarks)#%">
				</cfif>
			ORDER BY permit.permit_id
		</cfquery>
		<cfif matchPermit.recordcount EQ 0>
			<p>Nothing matched. <a href="#encodeForHtmlAttribute(variables.searchAgain)#">Try again.</a></p>
		<cfelseif matchPermit.recordcount EQ 1>
			<script>
				pickPermit('#encodeForJavaScript(matchPermit.permit_id)#', '#encodeForJavaScript("#matchPermit.permit_num# (#matchPermit.permit_type#)")#');
			</script>
		<cfelse>
			<p>#matchPermit.recordcount# permits matched. <a href="#encodeForHtmlAttribute(variables.searchAgain)#">Search again.</a></p>
			<table class="permitPickTable">
				<thead>
					<tr>
						<th scope="col">Permit</th>
						<th scope="col">Issued to / by</th>
						<th scope="col">Dates</th>
						<th scope="col">Remarks</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="matchPermit">
						<cfset variables.permitLabel = "#matchPermit.permit_num# (#matchPermit.permit_type#)">
						<tr>
							<td>
								<input type="button" value="Pick" class="picBtn" onClick="pickPermit('#encodeForJavaScript(matchPermit.permit_id)#', '#encodeForJavaScript(variables.permitLabel)#');">
								<span class="permitNumber">#encodeForHtml(matchPermit.permit_num)#</span>
								<span class="permitDetail">#encodeForHtml(matchPermit.permit_type)#</span>
								<span class="permitDetail">ID #encodeForHtml(matchPermit.permit_id)#</span>
							</td>
							<td>
								<span class="permitDetail">to</span> #encodeForHtml(matchPermit.issued_to_agent)#<br>
								<span class="permitDetail">by</span> #encodeForHtml(matchPermit.issued_by_agent)#
							</td>
							<td>
								<span class="permitDetail">issued</span> #dateformat(matchPermit.issued_date,"yyyy-mm-dd")#
								<cfif len(matchPermit.renewed_date) GT 0><br><span class="permitDetail">renewed</span> #dateformat(matchPermit.renewed_date,"yyyy-mm-dd")#</cfif>
								<cfif len(matchPermit.exp_date) GT 0><br><span class="permitDetail">expires</span> #dateformat(matchPermit.exp_date,"yyyy-mm-dd")#</cfif>
							</td>
							<td>#encodeForHtml(matchPermit.permit_remarks)#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfif>
	</cfif>
</cfoutput>
<cfinclude template="../includes/_pickFooter.cfm">
