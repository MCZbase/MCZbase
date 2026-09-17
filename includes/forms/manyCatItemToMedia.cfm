<cfinclude template="/includes/_pickHeader.cfm">
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select distinct(collection) from collection order by collection
</cfquery>
<cfquery name="ctOtherIdType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    select distinct(other_id_type) FROM ctColl_Other_Id_Type ORDER BY other_Id_Type
</cfquery>
<cfoutput>
	<form name="findCatItem" method="post" action="manyCatItemToMedia.cfm">
        <input type="hidden" name="action" value="search">
		<input type="hidden" name="media_id" value="#media_id#">
		<label for="collID">Collection</label>
        <select name="collID" id="collID" size="1">
		    <option value="">Any</option>
			<cfloop query="ctcollection">
				<option value="#collection#">#collection#</option>
			</cfloop>
		</select>
		<label for="oidType">Other ID Type</label>
        <select name="oidType" id="oidType" size="1">
			<option value="catalog_number">Catalog Number</option>
			<cfloop query="ctOtherIdType">
				<option value="#other_id_type#">#other_id_type#</option>
			</cfloop>
		</select>
		<label for="oidNum">Other ID Num (comma-list)</label>
        <textarea id="oidNum" name="oidNum" rows="4" cols="40"></textarea>
        <br>
		<input type="submit" value="Search" class="schBtn">
	</form>
	<cfif action is "search">
		<!--- Was assembled as text and run through preservesinglequotes, splicing oidType and collID
			into quoted literals and oidNum through listqualify, which wraps each element in quotes without
			escaping any it contains.  All four columns compared here are character columns, so the binds
			match what the quoted literals did.  The varying FROM clause is expressed with cfif inside the
			block rather than by building a string.  The custom identifier binds inside
			concatSingleOtherId's argument list, as tools/parent_child_taxonomy.cfm:400 already does. --->
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				cat_num,
				collection,
				cataloged_item.collection_object_id,
				scientific_name,
				concatSingleOtherId(cataloged_item.collection_object_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#" null="#NOT isDefined('session.CustomOtherIdentifier') OR len(session.CustomOtherIdentifier) EQ 0#">) AS CustomID
			FROM
				cataloged_item,
				identification,
				collection
				<cfif oidType is not "catalog_number">
					,coll_obj_other_id_num
				</cfif>
			WHERE
				cataloged_item.collection_object_id = identification.collection_object_id
				AND cataloged_item.collection_id = collection.collection_id
				AND identification.accepted_id_fg = 1
				<cfif oidType is "catalog_number">
					AND cat_num IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oidNum#" list="yes">)
				<cfelse>
					AND cataloged_item.collection_object_id = coll_obj_other_id_num.collection_object_id
					AND other_id_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oidType#">
					AND display_value IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oidNum#" list="yes">)
				</cfif>
				<cfif len(collID) GT 0>
					AND collection = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collID#">
				</cfif>
		</cfquery>
        <cfif getItems.recordcount is 0>
			-foundNothing-
		<cfelse>
			Found #getItems.recordcount# specimens. 
			<a href="manyCatItemToMedia.cfm?action=add&media_id=#media_id#&cid=#valuelist(getItems.collection_object_id)#">
				Add all to Media as "shows cataloged_item"
			</a>
			<table border>
				<tr>
					<th>Item</th>
					<th>ID</th>
					<th>#session.CustomOtherIdentifier#</th>
				</tr>
				<cfloop query="getItems">
					<tr>
						<td>
							#collection# #cat_num#
						</td>
						<td>#scientific_name#</td>
						<td>#CustomID#</td>
					</tr>
				</cfloop>
			</table>
			
	</cfif>
	</cfif>
	<cfif action is "add">
		<cftransaction>
			<cfloop list="#cid#" index="i">
				<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					insert into media_relations (
						media_id,
						MEDIA_RELATIONSHIP,
						RELATED_PRIMARY_KEY
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
						'shows cataloged_item',
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#i#">
					)
				</cfquery>
			</cfloop>
		</cftransaction>
		<script>
			top.location="/media.cfm?action=edit&media_id=" + #media_id#;
		</script>
	</cfif>
</cfoutput>
