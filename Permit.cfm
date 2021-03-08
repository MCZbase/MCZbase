<cfset jquery11=true>
<cfif isdefined("headless") and headless EQ 'true'>
   <cfinclude template = "includes/_pickHeader.cfm">
<cfelse>
   <cfinclude template = "includes/_header.cfm">
</cfif>
<script type='text/javascript' src='/includes/transAjax.js'></script>
<!--- no security --->
<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select ct.permit_type, count(p.permit_id) uses from ctpermit_type ct left join permit p on ct.permit_type = p.permit_type
        group by ct.permit_type
        order by ct.permit_type
</cfquery>
<cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select ct.specific_type, ct.permit_type, count(p.permit_id) uses from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
        group by ct.specific_type, ct.permit_type
        order by ct.specific_type
</cfquery>
<cfif #action# is "nothing">
<cfset title = "Find Permissions/Rights Documents">
<cfoutput>
<font size="+1"><strong>Find Permissions &amp; Rights Documents</strong></font>
<p>Search for permits and similar documents related to permissions and rights (access benefit sharing agreements,
material transfer agreements, collecting permits, salvage permits, etc.)<p>
Any part of names accepted, case isn't important.  Use year or a date for dates.<br>
Leave "until date" fields empty unless you use the field to its left.<br>
<cfform name="findPermit" action="Permit.cfm" method="post">
	<input type="hidden" name="Action" value="search">
	<table><tr>
			<td align="right">Issued By</td>
			<td><input type="text" name="IssuedByAgent"></td>
			<td align="right">Issued To</td>
			<td><input type="text" name="IssuedToAgent"></td>
		</tr>
		<tr>
			<td align="right">Issued Date</td>
			<td><input type="text" name="issued_date"></td>
			<td align="right">Issued Until Date (leave blank otherwise)</td>
			<td><input type="text" name="issued_until_date"></td>
		</tr>
		<tr>
			<td align="right">Renewed Date</td>
			<td><input type="text" name="renewed_date"></td>
			<td align="right">Renewed Until Date (leave blank otherwise)</td>
			<td><input type="text" name="renewed_until_date"></td>
		</tr>
		<tr>
			<td align="right">Expiration Date</td>
			<td><input type="text" name="exp_date"></td>
			<td align="right">Expiration Until Date (leave blank otherwise)</td>
			<td><input type="text" name="exp_until_date"></td>
		</tr>
		<tr>
			<td align="right">Document Category</td>
			<td>
				<select name="permit_type" size="1">
					<option value=""></option>
					<cfloop query="ctPermitType">
						<option value = "#ctPermitType.permit_type#">#ctPermitType.permit_type# (#ctPermitType.uses#)</option>
					</cfloop>
				</select>
			</td>
			<td align="right">Specific Document Type</td>
			<td>
				<select name="specific_type" size="1">
					<option value=""></option>
					<cfloop query="ctSpecificPermitType">
						<option value = "#ctSpecificPermitType.specific_type#">#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>
					</cfloop>
				</select>
			</td>
		</tr>
		<tr>
			<td align="right">Permit Number</td>
			<td><input type="text" name="permit_num"></td>
			<td align="right">Permit Title</td>
			<td><input type="text" name="permit_title"></td>
		</tr>
		<tr>
			<td align="right">Contact Agent</td>
			<td><input type="text" name="ContactAgent"></td>
			<td align="right">Remarks</td>
			<td><input type="text" name="permit_remarks"></td>
		</tr>
		<tr>
			<td colspan="4" align="center">

				<input type="button" value="Search" class="schBtn"
   					onmouseover="this.className='schBtn btnhov'" onmouseout="this.className='schBtn'"
					onClick="findPermit.Action.value='search';submit();">




				 <input type="reset" value="Clear" class="qutBtn"
   onmouseover="this.className='qutBtn btnhov'" onmouseout="this.className='qutBtn'">

				<input type="button" value="Create New" class="insBtn"
   onmouseover="this.className='insBtn btnhov'" onmouseout="this.className='insBtn'"
   onClick="findPermit.Action.value='newPermit';submit();">

			</td>
		</tr>
	</table>
</cfform>
<hr>
</cfoutput>
</cfif>
<!--------------------------------------------------------------------------->
<cfif #Action# is "search">
<cfparam name="IssuedByAgent" default="">
<cfparam name="IssuedToAgent" default="">
<cfparam name="issued_Date" default="">
<cfparam name="renewed_Date" default="">
<cfparam name="exp_Date" default="">
<cfparam name="permit_Num" default="">
<cfparam name="permit_Type" default="">
<cfparam name="specific_type" default="">
<cfparam name="permit_title" default="">
<cfparam name="permit_remarks" default="">
<cfparam name="permit_id" default="">
<cfparam name="ContactAgent" default="">
<cfoutput>
<!--- set dateformat --->
<cfif not isdefined("sql") or len(#sql#) is 0>
	<!--- regular old search ---->
<cfset sql = "select permit.permit_id,
	issuedBy.agent_name as IssuedByAgent,
	issuedTo.agent_name as IssuedToAgent,
	Contact.agent_name as ContactAgent,
	issued_Date,
	renewed_Date,
	exp_Date,
	permit_Num,
	permit_Type,
        specific_type,
        permit_title,
	permit_remarks
from
	permit,  preferred_agent_name issuedTo, preferred_agent_name issuedBy, preferred_agent_name Contact
where
	permit.issued_by_agent_id = issuedBy.agent_id (+) and
	permit.issued_to_agent_id = issuedTo.agent_id (+) and
	permit.contact_agent_id = Contact.agent_id (+)">

<cfif len(#IssuedByAgent#) gt 0>
	<cfset sql = "#sql# AND upper(issuedBy.agent_name) like '%#escapequotes(ucase(IssuedByAgent))#%'">
</cfif>
<cfif isdefined("ISSUED_BY_AGENT_ID") and len(#ISSUED_BY_AGENT_ID#) gt 0>
	<cfset sql = "#sql# AND ISSUED_BY_AGENT_ID = #ISSUED_BY_AGENT_ID#">
</cfif>
<cfif isdefined("ISSUED_TO_AGENT_ID") and len(#ISSUED_TO_AGENT_ID#) gt 0>
	<cfset sql = "#sql# AND ISSUED_TO_AGENT_ID = #ISSUED_TO_AGENT_ID#">
</cfif>
<cfif isdefined("CONTACT_AGENT_ID") and len(#CONTACT_AGENT_ID#) gt 0>
	<cfset sql = "#sql# AND CONTACT_AGENT_ID = #CONTACT_AGENT_ID#">
</cfif>

<cfif len(#IssuedToAgent#) gt 0>
	<cfset sql = "#sql# AND upper(issuedTo.agent_name) like '%#escapequotes(ucase(IssuedToAgent))#%'">
</cfif>
<cfif len(#issued_date#) gt 0>
    <cfif len(#issued_date#) EQ 4>
 		<cfif len(#issued_until_date#) EQ 0>
           <cfset issued_until_date = "#issued_date#-12-31">
       </cfif>
       <cfset issued_date = "#issued_date#-01-01">
	   <cfif len(#issued_until_date#) EQ 4>
           <cfset issued_until_date = "#issued_until_date#-12-31">
       </cfif>
    </cfif>
	<cfif len(#issued_until_date#) gt 0>
		<cfset sql = "#sql# AND upper(issued_date) between to_date('#issued_date#', 'yyyy-mm-dd')
														and to_date('#issued_until_date#', 'yyyy-mm-dd')">
	<cfelse>
		<cfset sql = "#sql# AND upper(issued_date) like to_date('#issued_date#', 'yyyy-mm-dd')">
	</cfif>
</cfif>
<cfif len(#renewed_date#) gt 0>
    <cfif len(#renewed_date#) EQ 4>
		<cfif len(#renewed_until_date#) EQ 0>
           <cfset renewed_until_date = "#renewed_date#-12-31">
       </cfif>
       <cfset renewed_date = "#renewed_date#-01-01">
	   <cfif len(#renewed_until_date#) EQ 4>
           <cfset renewed_until_date = "#renewed_until_date#-12-31">
       </cfif>
    </cfif>
	<cfif len(#renewed_until_date#) gt 0>
		<cfset sql = "#sql# AND upper(renewed_date) between to_date('#renewed_date#', 'yyyy-mm-dd')
														and to_date('#renewed_until_date#', 'yyyy-mm-dd')">
	<cfelse>
		<cfset sql = "#sql# AND upper(renewed_date) like to_date('#renewed_date#', 'yyyy-mm-dd')">
	</cfif>
</cfif>
<cfif len(#exp_date#) gt 0>
    <cfif len(#exp_date#) EQ 4>
		<cfif len(#exp_until_date#) EQ 0>
           <cfset exp_until_date = "#exp_date#-12-31">
       </cfif>
       <cfset exp_date = "#exp_date#-01-01">
	   <cfif len(#exp_until_date#) EQ 4>
           <cfset exp_until_date = "#exp_until_date#-12-31">
       </cfif>
    </cfif>
	<cfif len(#exp_until_date#) gt 0>
		<cfset sql = "#sql# AND upper(exp_date) between to_date('#exp_date#', 'yyyy-mm-dd')
														and to_date('#exp_until_date#', 'yyyy-mm-dd')">
	<cfelse>
		<cfset sql = "#sql# AND upper(exp_date) like to_date('#exp_date#', 'yyyy-mm-dd')">
	</cfif>
</cfif>
<cfif len(#permit_Num#) gt 0>
	<cfset sql = "#sql# AND upper(permit_Num) like '%#ucase(permit_Num)#%'">
</cfif>
<cfif len(#ContactAgent#) gt 0>
	<cfset sql = "#sql# AND upper(Contact.agent_name) like '%#ucase(ContactAgent)#%'
			AND permit.contact_agent_id = Contact.agent_id">
</cfif>
<cfif len(#permit_type#) gt 0>
	<cfset permit_Type = #replace(permit_type,"'","''","All")#>
	<cfset sql = "#sql# AND permit_type = '#permit_type#'">
</cfif>
<cfif len(#permit_title#) gt 0>
	<cfset permit_title = #replace(permit_title,"'","''","All")#>
	<cfset sql = "#sql# AND upper(permit_title) like '%#ucase(permit_title)#%'">
</cfif>
<cfif len(#specific_type#) gt 0>
	<cfset specific_type = #replace(specific_type,"'","''","All")#>
	<cfset sql = "#sql# AND specific_type = '#specific_type#'">
</cfif>
<cfif len(#permit_remarks#) gt 0>
	<cfset sql = "#sql# AND upper(permit_remarks) like '%#ucase(permit_remarks)#%'">
</cfif>
<cfif len(#permit_id#) gt 0>
	<cfset sql = "#sql# AND permit_id = #permit_id#">
</cfif>

<cfif #sql# is "select * from permit, agent_name issuedTo, agent_name issuedBy where permit.issued_by_agent_id = issuedBy.agent_id and permit.issued_to_agent_id = issuedTo.agent_id ">
	Enter some criteria.<cfabort>
</cfif>
<cfset thisSql = #sql#>
<cfelse><!--- came in with sql defined ---->
	<cfset thisSql = "#sql# ORDER BY #order_by# #order_order#">
</cfif><!--- end sql isdefined --->
<cfquery name="matchPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	#preservesinglequotes(thisSql)#
</cfquery>

<table border>
	<tr>
	<form name="reorder" method="post" action="Permit.cfm">
		<input type="hidden" name="sql" value="#sql#">
		<input type="hidden" name="action" value="search">
		<input type="hidden" name="order_by">
		<input type="hidden" name="order_order">
		<td>
			<strong>Permit Number</strong>
			<cfset thisTerm = "permit_num">
			<cfset thisName = #replace(thisTerm,",","_","all")#>
			<br>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='asc';reorder.submit();"
				onMouseOver="self.status='Sort Ascending.';#thisName#up.src='/images/up_mo.gif';return true;"
				onmouseout="self.status='';#thisName#up.src='/images/up.gif';return true;">
				<img src="/images/up.gif" border="0" name="#thisName#up"></a>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='desc';reorder.submit();"
				onMouseOver="self.status='Sort Descending.';#thisName#dn.src='/images/down_mo.gif';return true;"
				onmouseout="self.status='';#thisName#dn.src='/images/down.gif';return true;">
				<img src="/images/down.gif" border="0" name="#thisName#dn"></a>
		</td>
		<td>
			<strong>Document Category</strong>
			<cfset thisTerm = "permit_Type">
			<cfset thisName = #replace(thisTerm,",","_","all")#>
			<br>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='asc';reorder.submit();"
				onMouseOver="self.status='Sort Ascending.';#thisName#up.src='/images/up_mo.gif';return true;"
				onmouseout="self.status='';#thisName#up.src='/images/up.gif';return true;">
				<img src="/images/up.gif" border="0" name="#thisName#up"></a>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='desc';reorder.submit();"
				onMouseOver="self.status='Sort Descending.';#thisName#dn.src='/images/down_mo.gif';return true;"
				onmouseout="self.status='';#thisName#dn.src='/images/down.gif';return true;">
				<img src="/images/down.gif" border="0" name="#thisName#dn"></a>
		</td>
		<td>
			<strong>Specific Type</strong>
			<cfset thisTerm = "specific_type">
			<cfset thisName = #replace(thisTerm,",","_","all")#>
			<br>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='asc';reorder.submit();"
				onMouseOver="self.status='Sort Ascending.';#thisName#up.src='/images/up_mo.gif';return true;"
				onmouseout="self.status='';#thisName#up.src='/images/up.gif';return true;">
				<img src="/images/up.gif" border="0" name="#thisName#up"></a>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='desc';reorder.submit();"
				onMouseOver="self.status='Sort Descending.';#thisName#dn.src='/images/down_mo.gif';return true;"
				onmouseout="self.status='';#thisName#dn.src='/images/down.gif';return true;">
				<img src="/images/down.gif" border="0" name="#thisName#dn"></a>
		</td>
		<td>
			<strong>Permit Title</strong>
			<cfset thisTerm = "permit_title">
			<cfset thisName = #replace(thisTerm,",","_","all")#>
			<br>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='asc';reorder.submit();"
				onMouseOver="self.status='Sort Ascending.';#thisName#up.src='/images/up_mo.gif';return true;"
				onmouseout="self.status='';#thisName#up.src='/images/up.gif';return true;">
				<img src="/images/up.gif" border="0" name="#thisName#up"></a>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='desc';reorder.submit();"
				onMouseOver="self.status='Sort Descending.';#thisName#dn.src='/images/down_mo.gif';return true;"
				onmouseout="self.status='';#thisName#dn.src='/images/down.gif';return true;">
				<img src="/images/down.gif" border="0" name="#thisName#dn"></a>
		</td>
		<td>
			<strong>Issued To</strong>
			<cfset thisTerm = "IssuedToAgent">
			<cfset thisName = #replace(thisTerm,",","_","all")#>
			<br>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='asc';reorder.submit();"
				onMouseOver="self.status='Sort Ascending.';#thisName#up.src='/images/up_mo.gif';return true;"
				onmouseout="self.status='';#thisName#up.src='/images/up.gif';return true;">
				<img src="/images/up.gif" border="0" name="#thisName#up"></a>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='desc';reorder.submit();"
				onMouseOver="self.status='Sort Descending.';#thisName#dn.src='/images/down_mo.gif';return true;"
				onmouseout="self.status='';#thisName#dn.src='/images/down.gif';return true;">
				<img src="/images/down.gif" border="0" name="#thisName#dn"></a>
		</td>
		<td>
			<strong>Issued By</strong>
			<cfset thisTerm = "IssuedByAgent">
			<cfset thisName = #replace(thisTerm,",","_","all")#>
			<br>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='asc';reorder.submit();"
				onMouseOver="self.status='Sort Ascending.';#thisName#up.src='/images/up_mo.gif';return true;"
				onmouseout="self.status='';#thisName#up.src='/images/up.gif';return true;">
				<img src="/images/up.gif" border="0" name="#thisName#up"></a>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='desc';reorder.submit();"
				onMouseOver="self.status='Sort Descending.';#thisName#dn.src='/images/down_mo.gif';return true;"
				onmouseout="self.status='';#thisName#dn.src='/images/down.gif';return true;">
				<img src="/images/down.gif" border="0" name="#thisName#dn"></a>
		</td>
		<td>
			<strong>Issued Date</strong>
			<cfset thisTerm = "issued_Date">
			<cfset thisName = #replace(thisTerm,",","_","all")#>
			<br>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='asc';reorder.submit();"
				onMouseOver="self.status='Sort Ascending.';#thisName#up.src='/images/up_mo.gif';return true;"
				onmouseout="self.status='';#thisName#up.src='/images/up.gif';return true;">
				<img src="/images/up.gif" border="0" name="#thisName#up"></a>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='desc';reorder.submit();"
				onMouseOver="self.status='Sort Descending.';#thisName#dn.src='/images/down_mo.gif';return true;"
				onmouseout="self.status='';#thisName#dn.src='/images/down.gif';return true;">
				<img src="/images/down.gif" border="0" name="#thisName#dn"></a>
		</td>
		<td>
			<strong>Renewed Date</strong>
			<cfset thisTerm = "renewed_Date">
			<cfset thisName = #replace(thisTerm,",","_","all")#>
			<br>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='asc';reorder.submit();"
				onMouseOver="self.status='Sort Ascending.';#thisName#up.src='/images/up_mo.gif';return true;"
				onmouseout="self.status='';#thisName#up.src='/images/up.gif';return true;">
				<img src="/images/up.gif" border="0" name="#thisName#up"></a>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='desc';reorder.submit();"
				onMouseOver="self.status='Sort Descending.';#thisName#dn.src='/images/down_mo.gif';return true;"
				onmouseout="self.status='';#thisName#dn.src='/images/down.gif';return true;">
				<img src="/images/down.gif" border="0" name="#thisName#dn"></a>
		</td>
		<td>
			<strong>Expires Date</strong>
			<br>
			<cfset thisTerm = "exp_Date">
			<cfset thisName = #replace(thisTerm,",","_","all")#>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='asc';reorder.submit();"
				onMouseOver="self.status='Sort Ascending.';#thisName#up.src='/images/up_mo.gif';return true;"
				onmouseout="self.status='';#thisName#up.src='/images/up.gif';return true;">
				<img src="/images/up.gif" border="0" name="#thisName#up"></a>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='desc';reorder.submit();"
				onMouseOver="self.status='Sort Descending.';#thisName#dn.src='/images/down_mo.gif';return true;"
				onmouseout="self.status='';#thisName#dn.src='/images/down.gif';return true;">
				<img src="/images/down.gif" border="0" name="#thisName#dn"></a>
		</td>
		<td><strong>Remarks</strong></td>
		<td>
			<strong>Contact</strong>
			<br>
			<cfset thisTerm = "ContactAgent">
			<cfset thisName = #replace(thisTerm,",","_","all")#>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='asc';reorder.submit();"
				onMouseOver="self.status='Sort Ascending.';#thisName#up.src='/images/up_mo.gif';return true;"
				onmouseout="self.status='';#thisName#up.src='/images/up.gif';return true;">
				<img src="/images/up.gif" border="0" name="#thisName#up"></a>
			<a href="javascript: void"
				onClick="reorder.order_by.value='#thisTerm#';reorder.order_order.value='desc';reorder.submit();"
				onMouseOver="self.status='Sort Descending.';#thisName#dn.src='/images/down_mo.gif';return true;"
				onmouseout="self.status='';#thisName#dn.src='/images/down.gif';return true;">
				<img src="/images/down.gif" border="0" name="#thisName#dn"></a>
		</td>
		<td>&nbsp;</td>
	</form>
	</tr>
</cfoutput>
<a href="Permit.cfm">Search Again</a>
<cfoutput query="matchPermit" group="permit_id">
	<cfif len(#exp_Date#) gt 0>
		<cfset ExpiresInDays = #datediff("d",now(),exp_Date)#>
		<cfif ExpiresInDays lt 0>
			<cfset tabCol = "##666666">
		<cfelseif ExpiresInDays lt 10>
			<cfset tabCol = "##FF0000">
		<cfelseif ExpiresInDays lt 30>
			<cfset tabCol = "##FF8040">
		<cfelseif ExpiresInDays lt 180>
			<cfset tabCol = "##FFFF00">
		<cfelseif ExpiresInDays gte 180>
			<cfset tabCol = "##00FF00">
		<cfelse>
			<cfset tabCol = "##FFFFFF">
		</cfif>
	<cfelse>
		<!--- there's a permit with no exp date - treat this as bad! --->
		<cfset tabCol = "##FF0000">
	</cfif>
	<tr>
		<td>#permit_Num#</td>
		<td>#permit_Type#</td>
		<td>#specific_type#</td>
		<td>#permit_title#</td>
		<td>#IssuedToAgent#</td>
		<td>#IssuedByAgent#</td>
		<td>#dateformat(issued_Date,"yyyy-mm-dd")#</td>
		<td>#dateformat(renewed_Date,"yyyy-mm-dd")#</td>
		<td style="background-color:#tabCol#; ">
			#dateformat(exp_Date,"yyyy-mm-dd")#
			<cfif len(#exp_Date#) is 0>
				not given!
			<cfelseif #ExpiresInDays# lt 0>
				<font size="-2"><br>(expired)</font>
			<cfelse>
				<font size="-2"><br>(exp in #ExpiresInDays# d.)</font>
			</cfif>
		</td>
		<td>#permit_remarks#</td>
		<td>#contactAgent#</td>
		<td>
	<form action="Permit.cfm" method="post" name="Copy">
	<input type="hidden" name="permit_id" value="#permit_id#">
	<input type="hidden" name="Action" value="editPermit">
		<input type="submit" value="Edit this permit" class="lnkBtn"
   				onmouseover="this.className='lnkBtn btnhov'" onmouseout="this.className='lnkBtn'">
	</form>
	<form action="editAccn.cfm" method="post">
	<input type="hidden" name="permit_id" value="#permit_id#">
	<input type="hidden" name="Action" value="findAccessions">
		<input type="submit" value="Accession List" class="lnkBtn"
				onmouseover="this.className='lnkBtn btnhov'" onmouseout="this.className='lnkBtn'">
	</form>
        <!--- TODO: revisit permit report --->
        <!---
	<form action="Reports/permit.cfm" method="post">
	<input type="hidden" name="permit_id" value="#permit_id#">
		<input type="submit" value="Permit Report" class="lnkBtn"
				onmouseover="this.className='lnkBtn btnhov'" onmouseout="this.className='lnkBtn'">
	</form>
        --->
       <form action="Permit.cfm" method="post">
       <input type="hidden" name="permit_id" value="#permit_id#">
       <input type="hidden" name="Action" value="PermitUseReport">
               <input type="submit" value="Permit Report" class="lnkBtn"
                               onmouseover="this.className='lnkBtn btnhov'" onmouseout="this.className='lnkBtn'">
       </form>

		</td>
	</tr>




</cfoutput>
</table>
</cfif>
<!--------------------------------------------------------------------------->
<!--------------------------------------------------------------------------->
<cfif #Action# is "newPermit">
<cfset title = "New Permissions/Rights Document">
    <font size="+1"><strong>New Permissions &amp; Rights Document</strong></font>
    <p>Enter a new record for a permit or similar document related to permissions and rights (access benefit sharing agreements,
       material transfer agreements, collecting permits, salvage permits, etc.)</p>
	<cfoutput>
	<cfform name="newPermit" action="Permit.cfm" method="post">
	<input type="hidden" name="Action" value="createPermit">
        <cfif isdefined("headless") and headless EQ 'true'>
	    <input type="hidden" name="headless" value="true">
        </cfif>
	<table>
		<tr>
			<td>Issued By</td>
			<td colspan="3">
			<input type="hidden" name="IssuedByAgentId">
			<input type="text" name="IssuedByAgent" class="reqdClr" size="50"
		 onchange="getAgent('IssuedByAgentId','IssuedByAgent','newPermit',this.value); return false;"
			  onKeyUp="return noenter();">


		    </td>
		</tr>
			<tr>
			<td>Issued To</td>
			<td colspan="3">
			<input type="hidden" name="IssuedToAgentId">
			<input type="text" name="IssuedToAgent" class="reqdClr" size="50"
		 onchange="getAgent('IssuedToAgentId','IssuedToAgent','newPermit',this.value); return false;"
			  onKeyUp="return noenter();">


		    </td>
		</tr>
		<tr>
			<td>Contact Person</td>
			<td colspan="3">
			<input type="hidden" name="contact_agent_id">
			<input type="text" name="ContactAgent" size="50"
		 		onchange="getAgent('contact_agent_id','ContactAgent','newPermit',this.value); return false;"
			  	onKeyUp="return noenter();">


		    </td>
		</tr>
		<tr>
			<td>Issued Date</td>
			<td><input type="text" name="issued_Date"></td>
			<td>Renewed Date</td>
			<td><input type="text" name="renewed_Date"></td>
		</tr>
		<tr>
			<td>Expiration Date</td>
			<td><input type="text" name="exp_Date"></td>
			<td>Permit Number</td>
			<td><input type="text" name="permit_Num"></td>
		</tr>
		<tr>
			<td>Specific Document Type</td>
			<td colspan=3>
				<select name="specific_type" id="specific_type" size="1" class="reqdClr">
					<option value=""></option>
					<cfloop query="ctSpecificPermitType">
						<option value = "#ctSpecificPermitType.specific_type#">#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.permit_type#)</option>
					</cfloop>
				</select>
                                <cfif isdefined("session.roles") and listfindnocase(session.roles,"admin_permits")>
                                   <button id="addSpecificTypeButton" onclick="openAddSpecificTypeDialog(); event.preventDefault();">+</button>
                                   <div id="newPermitASTDialog"></div>
                                </cfif>
			</td>
		</tr>
		<tr>
			<td>Document Title</td>
			<td><input type="text" name="permit_title" style="width: 26em;" ></td>
			<td>Remarks</td>
			<td><input type="text" name="permit_remarks" style="width: 26em;" ></td>
		</tr>
		<tr>
			<td>Summary of Restrictions on use</td>
			<td colspan="3"><textarea cols="80" rows="3" name="restriction_summary"></textarea></td>
		</tr>
		<tr>
			<td>Summary of Agreed Benefits</td>
			<td colspan="3"><textarea cols="80" rows="3" name="benefits_summary"></textarea></td>
		</tr>
		<tr>
			<td>Benefits Provided</td>
			<td colspan="3"><textarea cols="80" rows="3" name="benefits_provided"></textarea></td>
		</tr>
		<tr>
			<td colspan="4" align="center">
				<input type="submit" value="Save" class="insBtn"
   					onmouseover="this.className='insBtn btnhov'" onmouseout="this.className='insBtn'">

                                   <cfif  not ( isdefined("headless") and headless EQ 'true' ) >
					<input type="button" value="Quit" class="qutBtn"
   					onmouseover="this.className='qutBtn btnhov'" onmouseout="this.className='qutBtn'"
					 onClick="document.location='Permit.cfm'">
                                   </cfif>

			</td>
		</tr>
	</table>
</cfform>
	</cfoutput>
</cfif>
<!--------------------------------------------------------------------------------------------------->
<!--------------------------------------------------------------------------------------------------->
<cfif #Action# is "editPermit">
<cfset title = "Edit Permissions/Rights document">
<font size="+1"><strong>Edit Permissions &amp; Rights Document</strong></font><br>
<cfoutput>
<cfif not isdefined("permit_id") OR len(#permit_id#) is 0>
	Error: You didn't pass this form a permit_id. Go back and try again.<cfabort>
</cfif>
<cfquery name="permitInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select permit.permit_id,
	issuedBy.agent_name as IssuedByAgent,
	issuedBy.agent_id as IssuedByAgentID,
	issuedTo.agent_name as IssuedToAgent,
	issuedTo.agent_id as IssuedToAgentID,
	contact_agent_id,
	contact.agent_name as ContactAgent,
	issued_Date,
	renewed_Date,
	exp_Date,
    restriction_summary,
    benefits_summary,
    benefits_provided,
	permit_Num,
	permit_Type,
	specific_type,
	permit_title,
	permit_remarks
	from
		permit,
		preferred_agent_name issuedTo,
		preferred_agent_name issuedBy ,
		preferred_agent_name contact
	where
		permit.issued_by_agent_id = issuedBy.agent_id (+) and
	permit.issued_to_agent_id = issuedTo.agent_id (+) AND
	permit.contact_agent_id = contact.agent_id (+)
	and permit_id=<cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
	order by permit_id
</cfquery>
<script>
function opendialog(page,id,title) {
  var $dialog = $(id)
  .html('<iframe style="border: 0px; " src="' + page + '" width="100%" height="100%"></iframe>')
  .dialog({
    title: title,
    autoOpen: false,
    dialogClass: 'dialog_fixed,ui-widget-header',
    modal: true,
    height: 900,
    width: 1200,
    minWidth: 400,
    minHeight: 400,
    draggable:true,
    buttons: { "Ok": function () { loadPermitMedia(#permit_id#); loadPermitRelatedMedia(#permit_id#); $(this).dialog("close"); } }
  });
  $dialog.dialog('open');
};
</script>
</cfoutput>
<cfoutput query="permitInfo" group="permit_id">
<cfform name="newPermit" action="Permit.cfm" method="post">
	<input type="hidden" name="Action">
	<input type="hidden" name="permit_id" id="permit_id" value="#permit_id#">
    <!--- make permit number available as a element with a distinct id to grab with jquery --->
	<input type="hidden" name="permit_number_passon" id="permit_number_passon" value="#permit_Num#">
	<table>
		<tr>
			<td>Issued By</td>
			<td colspan="3">
				<input type="hidden" name="IssuedByAgentId">
				<input type="hidden" name="IssuedByOldAgentId" value="#IssuedByAgentID#">
				<input type="text" name="IssuedByAgent" class="reqdClr" size="50"
				value="#IssuedByAgent#"
		 onchange="getAgent('IssuedByAgentId','IssuedByAgent','newPermit',this.value); return false;"
			  onKeyUp="return noenter();">

		  </td>
		</tr>
		<tr>
			<td>Issued To</td>
			<td colspan="3">
				<input type="hidden" name="IssuedToAgentId">
				<input type="text" name="IssuedToAgent" class="reqdClr" size="50"
				value="#IssuedToAgent#"
		 onchange="getAgent('IssuedToAgentId','IssuedToAgent','newPermit',this.value); return false;"
			  onKeyUp="return noenter();">
			</td>
		</tr>
		<tr>
			<td>Contact Person</td>
			<td colspan="3">
			<input type="hidden" name="contact_agent_id" value="#contact_agent_id#">
			<input type="text" name="ContactAgent"  size="50" value="#ContactAgent#"
		 onchange="getAgent('contact_agent_id','ContactAgent','newPermit',this.value); return false;"
			  onKeyUp="return noenter();">
		</td>
		</tr>
		<tr>
			<td>Issued Date</td>
			<td><input type="text" name="issued_Date" value="#dateformat(issued_Date,"yyyy-mm-dd")#"></td>
			<td>Renewed Date</td>
			<td><input type="text" name="renewed_Date" value="#dateformat(renewed_Date,"yyyy-mm-dd")#"></td>
		</tr>
		<tr>
			<td>Expiration Date</td>
			<td><input type="text" name="exp_Date" value="#dateformat(exp_Date,"yyyy-mm-dd")#"></td>
			<td>Permit Number</td>
			<td><input type="text" name="permit_Num" id="permit_Num" value="#permit_Num#"></td>
		</tr>
        <tr>
            <td>Summary of Restrictions on use</td>
            <td colspan="3"><textarea cols="80" rows="3" name="restriction_summary" >#restriction_summary#</textarea></td>
        </tr>
        <tr>
            <td>Summary of Agreed Benefits</td>
            <td colspan="3"><textarea cols="80" rows="3" name="benefits_summary" >#benefits_summary#</textarea></td>
        </tr>
        <tr>
            <td>Benefits Provided</td>
            <td colspan="3"><textarea cols="80" rows="3" name="benefits_provided" >#benefits_provided#</textarea></td>
        </tr>

		<tr>
			<td>Document Type</td>
			<td colspan=3>
				<select name="specific_type" id="specific_type" class="reqdClr" size="1">
					<option value=""></option>
					<cfloop query="ctSpecificPermitType">
						<option <cfif #ctSpecificPermitType.specific_type# is "#permitInfo.specific_type#"> selected </cfif>value = "#ctSpecificPermitType.specific_type#">#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.permit_type#)</option>
					</cfloop>
				</select>
                                <cfif isdefined("session.roles") and listfindnocase(session.roles,"admin_permits")>
                                   <button id="addSpecificTypeButton" onclick="openAddSpecificTypeDialog(); event.preventDefault();">+</button>
                                   <div id="newPermitASTDialog"></div>
                                </cfif>
			</td>
		</tr>
		<tr>
			<td>Permit Title</td>
			<td><input type="text" name="permit_title" value="#permit_title#" style="width: 26em;"></td>
			<td>Remarks</td>
			<td><input type="text" name="permit_remarks" value="#permit_remarks#" style="width: 26em;"></td>
		</tr>
		<tr>
			<td colspan="4" align="center">
				<input type="submit" value="Save changes" class="savBtn"
   					onmouseover="this.className='savBtn btnhov'" onmouseout="this.className='savBtn'"
					onCLick="newPermit.Action.value='saveChanges';">

                                <cfif isdefined("headless") and headless EQ 'true' >
                                   <strong>Permit Added.  Click OK when done.</strong>
                                <cfelse>
				   <input type="button" value="Quit" class="qutBtn"
   					onmouseover="this.className='qutBtn btnhov'" onmouseout="this.className='qutBtn'"
					 onClick="document.location='Permit.cfm'">
                                </cfif>

				<input type="button" value="Delete" class="delBtn"
				   onmouseover="this.className='delBtn btnhov'" onmouseout="this.className='delBtn'"
				   onCLick="newPermit.Action.value='deletePermit';confirmDelete('newPermit');">

                                <input type="button" value="Permit Report" class="lnkBtn"
                                    onmouseover="this.className='lnkBtn btnhov'" onmouseout="this.className='lnkBtn'"
                                    onClick="document.location='Permit.cfm?Action=PermitUseReport&permit_id=#permit_id#'"
                                    >
			</td>
		</tr>
	</table>
</cfform>
    <!---  Show/add media copy of permit  (shows permit) --->
    <div id="copyofpermit" class="shippingBlock" ><img src='images/indicator.gif'></div>
    <!---  list/add media copy of associated documents (document for permit) --->
    <div id="associateddocuments" class="shippingBlock"><img src='images/indicator.gif'></div>

    <script>
    function addMediaHere(targetid,title,permitLabel,permit_id,relationship){
           var url = '/media.cfm?action=newMedia&relationship='+relationship+'&related_value='+permitLabel+'&related_id='+permit_id ;
           var amddialog = $('##'+targetid)
           .html('<iframe style="border: 0px; " src="'+url+'" width="100%" height="100%" id="mediaIframe"></iframe>')
           .dialog({
                 title: title,
                 autoOpen: false,
                 dialogClass: 'dialog_fixed,ui-widget-header',
                 modal: true,
                 height: 900,
                 width: 1100,
                 minWidth: 400,
                 minHeight: 400,
                 draggable:true,
                 buttons: { "Ok": function () { loadPermitMedia(#permit_id#); loadPermitRelatedMedia(#permit_id#); $(this).dialog("close"); } }
           });
           amddialog.dialog('open');          
           amddialog.dialog('moveToTop');
     };

     function removeMediaDiv() {
		if(document.getElementById('bgDiv')){
			jQuery('##bgDiv').remove();
		}
		if (document.getElementById('mediaDiv')) {
			jQuery('##mediaDiv').remove();
		}
     };
    function loadPermitMedia(permit_id) {
        jQuery.get("/component/functions.cfc",
        {
            method : "getPermitMediaHtml",
            permit_id : permit_id
        },
        function (result) {
           $("##copyofpermit").html(result);
        }
        );
    };

    function loadPermitRelatedMedia(permit_id) {
        jQuery.get("/component/functions.cfc",
        {
            method : "getPermitMediaHtml",
            permit_id : permit_id,
            correspondence : "yes"
        },
        function (result) {
          $("##associateddocuments").html(result);
        }
        );
    };
	
	function reloadTransMedia() { 
		reloadPermitMedia();
	}
	function reloadPermitMedia() { 
		loadPermitMedia(#permit_id#);
		loadPermitRelatedMedia(#permit_id#);
	}

     jQuery(document).ready(loadPermitMedia(#permit_id#));
     jQuery(document).ready(loadPermitRelatedMedia(#permit_id#));

     </script>
     <cfquery name="permituse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select 'accession' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Accession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri
from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join accn on trans.transaction_id = accn.transaction_id
  where trans.transaction_type = 'accn'
        and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'loan' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri
from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join loan on trans.transaction_id = loan.transaction_id
  where trans.transaction_type = 'loan'
        and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'deaccession' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Deaccession.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join MCZBASE.deaccession on trans.transaction_id = deaccession.transaction_id
  where trans.transaction_type = 'deaccession'
        and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'borrow' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('Borrow.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join borrow on trans.transaction_id = borrow.transaction_id
  where trans.transaction_type = 'borrow'
        and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'borrow shipment' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('Borrow.cfm?action=edit&transaction_id=',trans.transaction_id) as uri
from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
  left join trans on shipment.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join borrow on trans.transaction_id = borrow.transaction_id
  where trans.transaction_type = 'borrow'
        and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'loan shipment' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri
from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
  left join trans on shipment.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join loan on trans.transaction_id = loan.transaction_id
  where trans.transaction_type = 'loan'
        and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'accession shipment' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Accession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri
from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
  left join trans on shipment.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join accn on trans.transaction_id = accn.transaction_id
  where trans.transaction_type = 'accn'
        and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'deaccession shipment' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Deaccession.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
  left join trans on shipment.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join deaccession on trans.transaction_id = deaccession.transaction_id
  where trans.transaction_type = 'deaccession'
        and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">

     </cfquery>
     <div id="permitsusedin" class="shippingBlock" ><h3>Permit used for</h3><ul>
        <cfloop query="permituse">
           <li><a href="#uri#" target="_blank">#transaction_type# #tnumber#</a> #ontype# #ttype# #dateformat(trans_date,'yyyy-mm-dd')# #guid_prefix#</li>
        </cfloop>
        <cfif permituse.recordCount eq 0>
           <li>No linked transactions or shipments.</li>
        </cfif>
     </ul></div>

     <span>
     <form action="Permit.cfm" method="get" name="Copy">
        <input type="hidden" name="permit_id" value="#permit_id#">
        <input type="hidden" name="Action" value="PermitUseReport">
                <input type="submit" value="Detailed report on use of this Permit" class="lnkBtn"
                                onmouseover="this.className='lnkBtn btnhov'" onmouseout="this.className='lnkBtn'">
     </form>
     </span>

</cfoutput>
</cfif>
<!--------------------------------------------------------------------------------------------------->
<!--------------------------------------------------------------------------------------------------->
<cfif #Action# is "permitUseReport">
   <cfset title = "Permissions/Rights Use Report">
   <cfif not isdefined("permit_id") OR len(#permit_id#) is 0>
      <cfoutput>Error: You didn't pass this form a permit_id. Go back and try again.</cfoutput>
      <cfabort>
   </cfif>
     <cfquery name="permitInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select permit.permit_id,
    issuedBy.agent_name as IssuedByAgent,
    issuedTo.agent_name as IssuedToAgent,
    contact_agent_id,
    contact.agent_name as ContactAgent,
    issued_Date,
    renewed_Date,
    exp_Date,
    restriction_summary,
    benefits_summary,
    benefits_provided,
    permit_Num,
    permit_Type,
    specific_type,
    permit_title,
    permit_remarks
    from
        permit,
        preferred_agent_name issuedTo,
        preferred_agent_name issuedBy ,
        preferred_agent_name contact
    where
        permit.issued_by_agent_id = issuedBy.agent_id (+) and
    permit.issued_to_agent_id = issuedTo.agent_id (+) AND
    permit.contact_agent_id = contact.agent_id (+)
    and permit_id=<cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
    order by permit_id
    </cfquery>
     <cfoutput>
        <h3>Permit</h3>
        <cfloop query="permitInfo">
          #permit_Type# #permit_Num# Issued:#issued_date# Expires:#exp_Date# Renewed:#renewed_Date# Issued By: #issuedByAgent# Issued To: #issuedToAgent# #permit_remarks#
        </cfloop>
	<form action="Permit.cfm" method="get" name="EditPermit">
	   <input type="hidden" name="permit_id" value="#permit_id#">
	   <input type="hidden" name="Action" value="editPermit">
	   <input type="submit" value="Edit this permit" class="lnkBtn"
   	        onmouseover="this.className='lnkBtn btnhov'" onmouseout="this.className='lnkBtn'">
	</form>
	<form action="Reports/permit.cfm" method="get" name="Copy">
	   <input type="hidden" name="permit_id" value="#permit_id#">
	   <input type="submit" value="(Old) Permit Report" class="lnkBtn"
   	        onmouseover="this.className='lnkBtn btnhov'" onmouseout="this.className='lnkBtn'">
	</form>
     </cfoutput>
     <cfquery name="permituse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">

select 'accession' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Accession.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri,
    flat.country, flat.state_prov, flat.scientific_name, flat.guid,
    TO_DATE(null) as shipped_date,'Museum of Comparative Zoology' as toinstitution, ' ' as frominstitution, flat.parts,
    decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join accn on trans.transaction_id = accn.transaction_id
  left join cataloged_item on accn.transaction_id = cataloged_item.accn_id
  left join flat on cataloged_item.collection_object_id = flat.collection_object_id
  left join taxonomy on flat.scientific_name = taxonomy.scientific_name
  where trans.transaction_type = 'accn'
        and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'accession shipment' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Accession.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri,
    flat.country, flat.state_prov, flat.scientific_name, flat.guid,
    shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, flat.parts,
    decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
  left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
  left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
  left join trans on shipment.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join accn on trans.transaction_id = accn.transaction_id
  left join cataloged_item on accn.transaction_id = cataloged_item.accn_id
  left join flat on cataloged_item.collection_object_id = flat.collection_object_id
  left join taxonomy on flat.scientific_name = taxonomy.scientific_name
  where trans.transaction_type = 'accn'
        and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'loan' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri,
    flat.country, flat.state_prov, flat.scientific_name, flat.guid,
    TO_DATE(null) as shipped_date, ' ' as toinstitution, ' ' as frominstitution, flat.parts,
    decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join loan on trans.transaction_id = loan.transaction_id
  left join loan_item on loan.transaction_id = loan_item.transaction_id
  left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
  left join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
  left join taxonomy on flat.scientific_name = taxonomy.scientific_name
  where trans.transaction_type = 'loan'
        and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'loan shipment' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri,
    flat.country, flat.state_prov, flat.scientific_name, flat.guid,
    shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, flat.parts,
    decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
  left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
  left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
  left join trans on shipment.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join loan on trans.transaction_id = loan.transaction_id
  left join loan_item on loan.transaction_id = loan_item.transaction_id
  left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
  left join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
  left join taxonomy on flat.scientific_name = taxonomy.scientific_name
  where trans.transaction_type = 'loan'
        and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'deaccession' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Deaccession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
    flat.country, flat.state_prov, flat.scientific_name, flat.guid,
    TO_DATE(null) as shipped_date, ' ' as toinstitution, 'Museum of Comparative Zoology' as frominstitution, flat.parts,
    decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join deaccession on trans.transaction_id = deaccession.transaction_id
  left join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
  left join flat on deacc_item.collection_object_id = flat.collection_object_id
  left join taxonomy on flat.scientific_name = taxonomy.scientific_name
  where trans.transaction_type = 'deaccession'
        and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'deaccession shipment' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('/transactions/Deaccession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
    flat.country, flat.state_prov, flat.scientific_name, flat.guid,
    shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, flat.parts,
    decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
  left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
  left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
  left join trans on shipment.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join deaccession on trans.transaction_id = deaccession.transaction_id
  left join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
  left join flat on deacc_item.collection_object_id = flat.collection_object_id
  left join taxonomy on flat.scientific_name = taxonomy.scientific_name
  where trans.transaction_type = 'deaccession'
        and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'borrow' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('Borrow.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
    borrow_item.country_of_origin as country, '' as state_prov, borrow_item.sci_name as scientific_name, borrow_item.catalog_number as guid,
    TO_DATE(null) as shipped_date,'Museum of Comparative Zoology' as toinstitution, '' as frominstitution, borrow_item.spec_prep as parts,
    ' ' as common_name
from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join borrow on trans.transaction_id = borrow.transaction_id
  left join borrow_item on borrow.transaction_id = borrow_item.transaction_id
  where trans.transaction_type = 'borrow'
        and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
union
select 'borrow shipment' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
    concat('Borrow.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
    borrow_item.country_of_origin as country, '' as state_prov, borrow_item.sci_name as scientific_name, borrow_item.catalog_number as guid,
    shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, borrow_item.spec_prep as parts,
    ' ' as common_name
from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
  left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
  left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
  left join trans on shipment.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join borrow on trans.transaction_id = borrow.transaction_id
  left join borrow_item on borrow.transaction_id = borrow_item.transaction_id
  where trans.transaction_type = 'borrow'
        and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
     </cfquery>
     <cfoutput>
     <div id="permitsusedin"><h3>Used for</h3>
     <table>
           <tr>
             <th>Transaction</th>
             <th>Type</th>
             <th>Date</th>
             <th>Ship&nbsp;Date</th>
             <th>Collection</th>
             <th>Country&nbsp;of&nbsp;Origin</th>
             <th>State/Province</th>
             <th>Scientific&nbsp;Name</th>
             <th>Common&nbsp;Name</th>
             <th>Preparations</th>
             <th>Catalog&nbsp;Number</th>
             <th>From&nbsp;Institution</th>
             <th>To&nbsp;Institution</th>
           </tr>
        <cfloop query="permituse">
           <tr>
             <td><a href="#uri#" target="_blank">#transaction_type# #tnumber#</a></td>
             <td>#ontype# #ttype#</td>
             <td>#dateformat(trans_date,'yyyy-mm-dd')#</td>
             <td>#dateformat(shipped_date,'yyyy-mm-dd')#</td>
             <td>#guid_prefix#</td>
             <td>#country#</td>
             <td>#state_prov#</td>
             <td>#scientific_name#</td>
             <td>#common_name#</td>
             <td>#parts#</td>
             <td>#guid#</td>
             <td>#frominstitution#</td>
             <td>#toinstitution#</td>
           </tr>
        </cfloop>
     </table>
     </div>
     </cfoutput>
     <cfquery name="permitsalvagereport" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select
    count(cataloged_item.collection_object_id) as cat_count,
    sum(coll_object.lot_count) as spec_count,
    collection.guid_prefix,
    flat.country, flat.state_prov, flat.scientific_name, flat.county,
    mczbase.get_part_prep(specimen_part.collection_object_id) as parts,
    decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
  left join collection on trans.collection_id = collection.collection_id
  left join accn on trans.transaction_id = accn.transaction_id
  left join cataloged_item on accn.transaction_id = cataloged_item.accn_id
  left join flat on cataloged_item.collection_object_id = flat.collection_object_id
  left join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
  left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
  left join taxonomy on flat.scientific_name = taxonomy.scientific_name
  where trans.transaction_type = 'accn'
        and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
  group by collection.guid_prefix, country, state_prov, flat.scientific_name, flat.county,
        mczbase.get_part_prep(specimen_part.collection_object_id),
        decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id))
      </cfquery>
     <cfoutput>
     <div id="permitaccessionsummary"><h3>Accession Summary (Salvage Permit Reporting)</h3>
     <cfif permitsalvagereport.RecordCount eq 0>
       <h4>No accessions</h4>
     <cfelse>
     <table>
           <tr>
             <th>Specimen&nbsp;Count</th>
             <th>Collection</th>
             <th>Country</th>
             <th>State</th>
             <th>County</th>
             <th>Scientific&nbsp;Name</th>
             <th>Common&nbsp;Name</th>
             <th>Parts</th>
           </tr>
        <cfloop query="permitsalvagereport">
           <tr>
             <td>#spec_count#</td>
             <td>#guid_prefix#</td>
             <td>#country#</td>
             <td>#state_prov#</td>
             <td>#county#</td>
             <td>#scientific_name#</td>
             <td>#common_name#</td>
             <td>#parts#</td>
           </tr>
        </cfloop>
     </table>
     </cfif>
     </div>


     </cfoutput>
</cfif>
<!--------------------------------------------------------------------------------------------------->
<!--------------------------------------------------------------------------------------------------->
<cfif #Action# is "saveChanges">
<cfquery name="ptype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
   select permit_type from ctspecific_permit_type where specific_type = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
</cfquery>
<cfset permit_type = #ptype.permit_type#>
<cfoutput>
<cfquery name="updatePermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
UPDATE permit SET
	permit_id = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#permit_id#">
	<cfif len(#issuedByAgentId#) gt 0>
	 	,ISSUED_BY_AGENT_ID = #issuedByAgentId#
    </cfif>
	 <cfif len(#ISSUED_DATE#) gt 0>
	 	,ISSUED_DATE = '#ISSUED_DATE#'
	 </cfif>
	 <cfif len(#IssuedToAgentId#) gt 0>
	 	,ISSUED_TO_AGENT_ID = #IssuedToAgentId#
	 </cfif>
	 <cfif len(#RENEWED_DATE#) gt 0>
	 	,RENEWED_DATE = '#RENEWED_DATE#'
	 </cfif>
	 <cfif len(#EXP_DATE#) gt 0>
	 	,EXP_DATE = '#EXP_DATE#'
	 </cfif>
	 <cfif len(#PERMIT_NUM#) gt 0>
	 	,PERMIT_NUM = '#PERMIT_NUM#'
	 </cfif>
	 <cfif len(#PERMIT_TYPE#) gt 0>
	 	,PERMIT_TYPE = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_type#">
	 </cfif>
	 <cfif len(#SPECIFIC_TYPE#) gt 0>
	 	,SPECIFIC_TYPE = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
	 </cfif>
	 <cfif len(#PERMIT_TITLE#) gt 0>
	 	,PERMIT_TITLE = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_title#">
	 </cfif>
	<cfif len(#PERMIT_REMARKS#) gt 0>
	 	,PERMIT_REMARKS = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_remarks#">
    </cfif>
	<cfif len(#restriction_summary#) gt 0>
	 	,restriction_summary = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#restriction_summary#">
    </cfif>
	<cfif len(#benefits_summary#) gt 0>
	 	,benefits_summary = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_summary#">
    </cfif>
	<cfif len(#benefits_provided#) gt 0>
	 	,benefits_provided = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_provided#">
    </cfif>
	 <cfif len(#contact_agent_id#) gt 0>
	 	,contact_agent_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#contact_agent_id#">
	<cfelse>
		,contact_agent_id = null
	 </cfif>
	 where  permit_id =  <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
</cfquery>
<cflocation url="Permit.cfm?Action=editPermit&permit_id=#permit_id#">
</cfoutput>
</cfif>
<!--------------------------------------------------------------------------------------------------->
<!--------------------------------------------------------------------------------------------------->
<cfif #Action# is "createPermit">
<cfoutput>
<cfset hasError = 0 >
<cfif not isdefined("specific_type") OR len(#specific_type#) is 0>
	Error: You didn't select a document type. Go back and try again.
        <cfset hasError = 1 >
</cfif>
<cfif not isdefined("issuedByAgentId") OR len(#issuedByAgentId#) is 0>
	Error: You didn't select an issued by agent. Do you have popups enabled?  Go back and try again.
        <cfset hasError = 1 >
</cfif>
<cfif not isdefined("issuedToAgentId") OR len(#issuedToAgentId#) is 0>
	Error: You didn't select an issued to agent. Do you have popups enabled?  Go back and try again.
        <cfset hasError = 1 >
</cfif>
<cfquery name="ptype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
   select permit_type from ctspecific_permit_type where specific_type = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
</cfquery>
<cfset permit_type = #ptype.permit_type#>
<cfquery name="nextPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select sq_permit_id.nextval nextPermit from dual
</cfquery>
<cfif isdefined("specific_type") and len(#specific_type#) is 0 and ( not isdefined("permit_type") OR len(#permit_type#) is 0 )>
	Error: There was an error selecting the permit type for the specific document type.  Please file a bug report.
        <cfset hasError = 1 >
</cfif>
<cfif hasError eq 1>
    <cfabort>
</cfif>
<cfquery name="newPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newPermitResult">
INSERT INTO permit (
	 PERMIT_ID,
	 ISSUED_BY_AGENT_ID
	 <cfif len(#ISSUED_DATE#) gt 0>
	 	,ISSUED_DATE
	 </cfif>
	 ,ISSUED_TO_AGENT_ID
	  <cfif len(#RENEWED_DATE#) gt 0>
	 	,RENEWED_DATE
	 </cfif>
	 <cfif len(#EXP_DATE#) gt 0>
	 	,EXP_DATE
	 </cfif>
	 <cfif len(#PERMIT_NUM#) gt 0>
	 	,PERMIT_NUM
	 </cfif>
	 ,PERMIT_TYPE
	 ,SPECIFIC_TYPE
	 <cfif len(#PERMIT_TITLE#) gt 0>
	 	,PERMIT_TITLE
	 </cfif>
	 <cfif len(#PERMIT_REMARKS#) gt 0>
	 	,PERMIT_REMARKS
	 </cfif>
	 <cfif len(#restriction_summary#) gt 0>
	 	,restriction_summary
	 </cfif>
	 <cfif len(#benefits_summary#) gt 0>
	 	,benefits_summary
	 </cfif>
	 <cfif len(#benefits_provided#) gt 0>
	 	,benefits_provided
	 </cfif>
	  <cfif len(#contact_agent_id#) gt 0>
	 	,contact_agent_id
	 </cfif>)
VALUES (
	 #nextPermit.nextPermit#
	 , <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#IssuedByAgentId#">
	 <cfif len(#ISSUED_DATE#) gt 0>
	 	,'#dateformat(ISSUED_DATE,"yyyy-mm-dd")#'
	 </cfif>
	 , <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#IssuedToAgentId#">
	  <cfif len(#RENEWED_DATE#) gt 0>
	 	,'#dateformat(RENEWED_DATE,"yyyy-mm-dd")#'
	 </cfif>
	 <cfif len(#EXP_DATE#) gt 0>
	 	,'#dateformat(EXP_DATE,"yyyy-mm-dd")#'
	 </cfif>
	 <cfif len(#PERMIT_NUM#) gt 0>
	 	, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_num#">
	 </cfif>
	 , <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_type#">
	 , <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
	<cfif len(#PERMIT_TITLE#) gt 0>
	 	, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_title#">
	 </cfif>
	<cfif len(#PERMIT_REMARKS#) gt 0>
	 	, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_remarks#">
	 </cfif>
	 <cfif len(#restriction_summary#) gt 0>
	 	, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#restriction_summary#">
     </cfif>
	 <cfif len(#benefits_summary#) gt 0>
	 	, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_summary#">
     </cfif>
	 <cfif len(#benefits_provided#) gt 0>
	 	, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_provided#">
     </cfif>
	 <cfif len(#contact_agent_id#) gt 0>
	 	, <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#contact_agent_id#">
	 </cfif>)
</cfquery>
        <cfif isdefined("headless") and headless EQ 'true'>
   	     <cflocation url="Permit.cfm?Action=editPermit&headless=true&permit_id=#nextPermit.nextPermit#">
        <cfelse>
   	     <cflocation url="Permit.cfm?Action=editPermit&permit_id=#nextPermit.nextPermit#">
        </cfif>
  </cfoutput>
</cfif>
<!--------------------------------------------------------------------------------------------------->
<cfif #Action# is "deletePermit">
<cfoutput>
<cfquery name="deletePermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
DELETE FROM permit WHERE permit_id = #permit_id#
</cfquery>

	<cflocation url="Permit.cfm">
  </cfoutput>
</cfif>
<cfif isdefined("headless") and headless EQ 'true'>
    <cfinclude template = "includes/_pickFooter.cfm">
<cfelse>
    <cfinclude template = "includes/_footer.cfm">
</cfif>
