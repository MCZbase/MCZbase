<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	Find gaps in catalog numbers:
	<cfquery name="oidnum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct(other_id_type) from coll_obj_other_id_num order by other_id_type
	</cfquery>
	<cfquery name="collection_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select institution_acronym||' '||collection_cde CID, collection_id from collection
		group by institution_acronym||' '||collection_cde,collection_id
		order by institution_acronym||' '||collection_cde
	</cfquery>
	<form name="go" method="post" action="findGap.cfm">
		<input type="hidden" name="action" value="cat_num">
		<select name="collection_id" size="1">
			<cfoutput query="collection_id">
				<option value="#collection_id#">#CID#</option>
			</cfoutput>
		</select>
		<input type="submit"
				value="show me the gaps"
				class="savBtn">
	</form>
</cfif>

<cfif action is "cat_num">
<cfquery name="what" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select collection from collection where collection_id=#collection_id#
</cfquery>
<cfquery name="prefixes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct nvl(cat_num_prefix,'[no prefix]') catnumprefix, cat_num_prefix from cataloged_item where collection_id=#collection_id# order by catnumprefix
</cfquery>
<cfoutput>
<b>The following catalog number gaps exist in the #what.collection# collection.</b> <a href="./findGap.cfm">Reset</a>
<br>

<cfif prefixes.recordcount GT 1>
<table>
<form name="filterByPrefix">
	<input type="hidden" name="action" value="cat_num" id="action">
	<input type="hidden" name="collection_id" value="#collection_id#" id="collection_id">
	<tr>
				<td>Filter by Prefix:
				<select name="filterPrefix" style="width:150px" onChange='document.getElementById("action").value="cat_num";document.forms["filterByPrefix"].submit();'>
					<cfloop query="prefixes">
						<option <cfif isdefined("filterPrefix") and #prefixes.catnumprefix# EQ #filterPrefix#>selected</cfif>>#prefixes.catnumprefix#</option>
					</cfloop>
				</td>
	</tr>
</form>
<table>

<cfif not isdefined("filterPrefix")>
	<cfset p=QueryGetRow(prefixes,1)>
	<cfset filterPrefix=p.catnumprefix>
</cfif>

</cfif>
<cfquery name="b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	WITH aquery AS
 		(SELECT cat_num_prefix, cat_num_integer after_gap,
 		LAG(cat_num_integer ,1,0) OVER (ORDER BY cat_num_prefix, cat_num_integer) before_gap
	 	FROM
			cataloged_item
		where
			collection_id=#collection_id#
		<cfif isdefined("filterPrefix") and len(#filterPrefix#) GT 0>
		AND
		<cfif filterPrefix EQ "[no prefix]">
			cat_num_prefix is null
		<cfelse>
			cat_num_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#filterPrefix#">
		</cfif>
		</cfif>
		)
 	SELECT
 		cat_num_prefix,before_gap, after_gap
 	FROM
 		aquery
 	WHERE
 		before_gap != 0
 	AND
 		after_gap - before_gap > 1
 	ORDER BY
 		cat_num_prefix,before_gap
</cfquery>
<br>
	<cfif b.recordcount EQ 0>
		<h3>There are no gaps in this number series.</h3>
	<cfelse>
		<table border>
			<tr>
				<th>Prefix</th>
				<th>##BeforeGap</th>
				<th>##AfterGap</th>
			</tr>
			<cfloop query="b">
				<tr>
					<td>#cat_num_prefix#</td>
					<td>#before_gap#</td>
					<td>#after_gap#</td>
				</tr>
			</cfloop>
		</table>
	</cfif>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">