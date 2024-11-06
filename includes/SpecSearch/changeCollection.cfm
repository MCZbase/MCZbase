<script language="javascript" type="text/javascript">
function closeThis(){
	document.location=location.href;
	var theDiv = document.getElementById('customDiv');
	document.body.removeChild(theDiv);
}
</script>
<cfoutput>
<cfquery name="yourcollid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select collection_id,collection from collection
	order by collection
</cfquery>
<cfquery name="collid" datasource="uam_god">
	select cf_collection_id,collection from cf_collection
	order by collection
</cfquery>
<table class="ssrch">
	<tr>
		<td colspan="2" class="secHead">
				<span class="secLabel">Customize Identifiers</span>
				<span class="secControl" id="c_collevent"
					onclick="closeThis();">Close</span>
		</td>
	</tr>
	<tr>
		<td>
			<label for="yourColl">Your collection(s)</label>
			<select name="currColl" id="yourColl" size="6" readonly="readonly">
				<cfloop query="yourcollid">
					<option>#collection#</option>
				</cfloop>
			</select>
		</td>
		<td valign="top">
		</td>
	</tr>
</table>
</cfoutput>
