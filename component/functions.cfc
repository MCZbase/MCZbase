<cfcomponent>
<cfinclude template = "../includes/functionLib.cfm">
<!------------------------------------------------------------------->
<cffunction name="getPartByContainer" access="remote">
	<cfargument name="barcode" type="string" required="yes">
	<cfargument name="i" type="string" required="yes">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select
			1 C,
			#i# I,
			cat_num,
			cataloged_item.collection_object_id,
			collection,
			part_name,
			condition,
			sampled_from_obj_id,
			coll_obj_disposition,
			scientific_name,
			concatEncumbrances(cataloged_item.collection_object_id) encumbrances,
			specimen_part.collection_object_id as partID,
			concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
			p1.barcode
		 from
			specimen_part,
			coll_object,
			cataloged_item,
			identification,
			collection,
			coll_obj_cont_hist,
			container p,
			container p1
		WHERE
			specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
			specimen_part.collection_object_id = coll_object.collection_object_id AND
			cataloged_item.collection_object_id = identification.collection_object_id AND
			identification.accepted_id_fg = 1 AND
			cataloged_item.collection_id=collection.collection_id AND
			specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id (+) AND
			coll_obj_cont_hist.container_id=p.container_id and
			p.parent_container_id=p1.container_id and
		  	p1.barcode=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#barcode#">
	</cfquery>
	<cfif d.recordcount is not 1>
		<cfset rc=d.recordcount>
		<cfset d = querynew("C,I")>
		<cfset temp = queryaddrow(d,1)>
		<cfset temp = QuerySetCell(d, "C", rc, 1)>
		<cfset temp = QuerySetCell(d, "I", i, 1)>
	</cfif>
	<cfreturn d>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="strToIso8601" access="remote">
	<cfargument name="str" type="string" required="yes">
	<cfset began=''>
	<cfset end="">
	<cfif isdate(str)>
		<cfset began=dateformat(str,"yyyy-mm-dd")>
		<cfset end=dateformat(str,"yyyy-mm-dd")>
	</cfif>
	<cfset result = querynew("I,B,E")>
	<cfset temp = queryaddrow(result,1)>
	<cfset temp = QuerySetCell(result, "I", str, 1)>
	<cfset temp = QuerySetCell(result, "B", began, 1)>
	<cfset temp = QuerySetCell(result, "E", end, 1)>

	<cfreturn result>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="flagDupAgent" access="remote">
	<cfargument name="bad" type="numeric" required="yes">
	<cfargument name="good" type="numeric" required="yes">
	<cftry>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into agent_relations (agent_id,related_agent_id,agent_relationship) values (#bad#,#good#,'bad duplicate of')
		</cfquery>
		<cfset result = querynew("STATUS,GOOD,BAD,MSG")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "status", "success", 1)>
		<cfset temp = QuerySetCell(result, "GOOD", "#good#", 1)>
		<cfset temp = QuerySetCell(result, "BAD", "#bad#", 1)>
		<cfcatch>
			<cfset result = querynew("STATUS,GOOD,BAD,MSG")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "status", "fail", 1)>
			<cfset temp = QuerySetCell(result, "GOOD", "#good#", 1)>
			<cfset temp = QuerySetCell(result, "BAD", "#bad#", 1)>
			<cfset temp = QuerySetCell(result, "MSG", "#cfcatch.message#: #cfcatch.detail#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------->
<cffunction name="getAttCodeTbl"  access="remote">
	<cfargument name="attribute" type="string" required="yes">
	<cfargument name="collection_cde" type="string" required="yes">
	<cfargument name="element" type="string" required="yes">
        <cftry>
        <cfset threadname = "getAttCodeTblThread">
        <cfthread name="#threadname#"  >
	<cfquery name="isCtControlled" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select VALUE_CODE_TABLE,UNITS_CODE_TABLE from ctattribute_code_tables where attribute_type='#attribute#'
	</cfquery>
	<cfif isCtControlled.recordcount is 1>
		<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
			<cfquery name="getCols" datasource="uam_god">
				select column_name from sys.user_tab_columns where table_name='#ucase(isCtControlled.value_code_table)#'
				and column_name <> 'DESCRIPTION'
			</cfquery>
			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select * from #isCtControlled.value_code_table#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(#collCode#) gt 0>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCode from valCT
					WHERE collection_cde='#collection_cde#'
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCode from valCT
				</cfquery>
			</cfif>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "value",1)>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfset temp = QuerySetCell(result, "v", "#valCodes.valCode#",#i#)>
				<cfset i=#i#+1>
			</cfloop>

		<cfelseif #isCtControlled.UNITS_CODE_TABLE# gt 0>
			<cfquery name="getCols" datasource="uam_god">
				select column_name from sys.user_tab_columns where table_name='#ucase(isCtControlled.UNITS_CODE_TABLE)#'
				and column_name <> 'DESCRIPTION'
			</cfquery>
			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select * from #isCtControlled.UNITS_CODE_TABLE#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(#collCode#) gt 0>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCode from valCT
					WHERE collection_cde='#collection_cde#'
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCode from valCT
				</cfquery>
			</cfif>
			<cfset result = "unit - #isCtControlled.UNITS_CODE_TABLE#">
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "units")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfset temp = QuerySetCell(result, "v", "#valCodes.valCode#",#i#)>
				<cfset i=#i#+1>
			</cfloop>
		<cfelse>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "ERROR")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
		</cfif>
	<cfelse>
		<cfset result = QueryNew("V")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "NONE")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "#element#",2)>
	</cfif>
        <cfoutput>#SerializeJSON(result,true)#</cfoutput>
        </cfthread>
        <cfthread action="join" name="#threadname#" />
        <cfcatch>
		<cfset result = QueryNew("V")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "ERROR")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "#element#",2)>
	        <cfreturn result>
        </cfcatch>
        </cftry>
        <cfreturn getAttCodeTblThread.output>
</cffunction>
<!---------------------------------------------------------------->
<cffunction name="removeAccnContainer" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="barcode" type="string" required="yes">
	<cftry>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select container_id from container where barcode='#barcode#'
		</cfquery>
		<cfif c.recordcount is 1>
			<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				delete from trans_container where
					transaction_id=#transaction_id# and
					container_id='#c.container_id#'
			</cfquery>
			<cfset r=structNew()>
			<cfset r.status="success">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
		<cfelse>
			<cfset r=structNew()>
			<cfset r.status="fail">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
			<cfset r.error="barcode not found">
		</cfif>
		<cfcatch>
			<cfset r.status="fail">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
			<cfset r.error=cfcatch.message & '; ' & cfcatch.detail>
		</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>
<!----------------------------------------------->
<cffunction name="addAccnContainer" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="barcode" type="string" required="yes">
	<cftry>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select container_id from container where barcode='#barcode#'
		</cfquery>
		<cfif c.recordcount is 1>
			<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				insert into trans_container (
					transaction_id,
					container_id
				) values (
					#transaction_id#,
					'#c.container_id#'
				)
			</cfquery>
			<cfset r=structNew()>
			<cfset r.status="success">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
		<cfelse>
			<cfset r=structNew()>
			<cfset r.status="fail">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
			<cfset r.error="barcode not found">
		</cfif>
		<cfcatch>
			<cfset r.status="fail">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
			<cfset r.error=cfcatch.message & '; ' & cfcatch.detail>
		</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>
<!----------------------------------------------->
<cffunction name="saveNewPartAtt" access="remote">
	<cfargument name="attribute_type" type="string" required="yes">
	<cfargument name="partID" type="numeric" required="yes">
	<cfargument name="attribute_value" type="string" required="yes">
	<cfargument name="attribute_units" type="string" required="no">
	<cfargument name="determined_date" type="string" required="no">
	<cfargument name="determined_by_agent_id" type="string" required="no">
	<cfargument name="attribute_remark" type="string" required="no">
	<cfargument name="determined_agent" type="string" required="no">

	<cftry>
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into specimen_part_attribute (
				collection_object_id,
				attribute_type,
				attribute_value,
				attribute_units,
				determined_date,
				determined_by_agent_id,
				attribute_remark
			) values (
				#partID#,
				'#attribute_type#',
				'#attribute_value#',
				'#attribute_units#',
				'#determined_date#',
				'#determined_by_agent_id#',
				'#attribute_remark#'
			)
		</cfquery>
		<cfset r=structNew()>
		<cfset r.status="spiffy">
		<cfset r.attribute_type=attribute_type>
		<cfset r.attribute_value=attribute_value>
		<cfset r.attribute_units=attribute_units>
		<cfset r.determined_date=determined_date>
		<cfset r.determined_by_agent_id=determined_by_agent_id>
		<cfset r.attribute_remark=attribute_remark>
		<cfset r.determined_agent=determined_agent>
		<cfreturn r>
		<cfcatch>
			<cfset r=structNew()>
			<cfset r.status="fail">
			<cfset r.error=cfcatch.message & '; ' & cfcatch.detail>
		</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>



<cffunction name="getPartAttOptions" access="remote">
	<cfargument name="patype" type="string" required="yes">
	<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from ctspec_part_att_att where attribute_type='#patype#'
	</cfquery>
	<cfif len(k.VALUE_code_table) gt 0>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select * from #k.VALUE_code_table# where collection_cde = '#collectionCDE#'
		</cfquery>
		<cfloop list="#d.columnlist#" index="i">
			<cfif i is not "description" and i is not "collection_cde">
				<cfquery name="r" dbtype="query">
					select #i# d from d order by #i#
				</cfquery>
			</cfif>
		</cfloop>
		<cfset rA=structNew()>
		<cfset rA.type='value'>
		<cfset rA.values=valuelist(r.d,"|")>
		<cfreturn rA>
	<cfelseif len(k.unit_code_table) gt 0>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select * from #k.unit_code_table#
		</cfquery>
		<cfloop list="#d.columnlist#" index="i">
			<cfif i is not "description" and i is not "collection_cde">
				<cfquery name="r" dbtype="query">
					select #i# d from d order by #i#
				</cfquery>
			</cfif>
		</cfloop>
		<cfset rA=structNew()>
		<cfset rA.type='unit'>
		<cfset rA.values=valuelist(r.d,"|")>
		<cfreturn rA>
	<cfelse>
		<cfset rA=structNew()>
		<cfset rA.type='none'>
		<cfreturn rA>
	</cfif>
</cffunction>

<cffunction name="deleteCtPartName" access="remote">
	<cfargument name="ctspnid" type="numeric" required="yes">
	<cftry>
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from ctspecimen_part_name where ctspnid=#ctspnid#
		</cfquery>
		<cfreturn ctspnid>
	<cfcatch>
		<cfreturn cfcatch.message & ': ' & cfcatch.detail>
	</cfcatch>
	</cftry>
</cffunction>
<!------------------------------------------------------->
<cffunction name="getTrans_agent_role" access="remote">
	<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select trans_agent_role from cttrans_agent_role where trans_agent_role != 'entered by' order by trans_agent_role
	</cfquery>
	<cfreturn k>
</cffunction>

<!------------------------------------------------------->

<cffunction name="getBorrowItems" access="remote">
        <cfargument name="transaction_id" type="numeric" required="yes">
        <cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                select transaction_id,borrow_item_id,catalog_number,sci_name,no_of_spec,spec_prep,type_status,country_of_origin,object_remarks from borrow_item where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
        </cfquery>
        <cfreturn k>
</cffunction>
<!------------------------------------------------------->
<cffunction name="addBorrowItem" access="remote">
    <cfargument name="transaction_id" type="numeric" required="yes">
    <cfargument name="catalog_number" required="no">
    <cfargument name="sci_name" required="no">
    <cfargument name="no_of_spec" required="no">
    <cfargument name="spec_prep" required="no">
    <cfargument name="type_status" required="no">
    <cfargument name="country_of_origin" required="no">
    <cfargument name="object_remarks" required="no">
    <cftry>
       <cfquery name="newBorrow_Item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newBorrow_ItemRes">
		INSERT INTO BORROW_ITEM (
			TRANSACTION_ID,
			CATALOG_NUMBER,
			SCI_NAME,
			NO_OF_SPEC,
			SPEC_PREP,
			TYPE_STATUS,
			COUNTRY_OF_ORIGIN,
            OBJECT_REMARKS

		) VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CATALOG_NUMBER#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SCI_NAME#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NO_OF_SPEC#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SPEC_PREP#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TYPE_STATUS#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COUNTRY_OF_ORIGIN#">,
            <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OBJECT_REMARKS#">

		)
        </cfquery>
        <cfif newBorrow_ItemRes.recordcount eq 0>
             <cfset theResult=queryNew("status, message")>
             <cfset t = queryaddrow(theResult,1)>
             <cfset t = QuerySetCell(theResult, "status", "0", 1)>
             <cfset t = QuerySetCell(theResult, "message", "Record not added. #transaction_id# #newBorrow_ItemRes.sql#", 1)>
       </cfif>
       <cfif newBorrow_ItemRes.recordcount eq 1>
             <cfset theResult=queryNew("status, message")>
             <cfset t = queryaddrow(theResult,1)>
             <cfset t = QuerySetCell(theResult, "status", "1", 1)>
             <cfset t = QuerySetCell(theResult, "message", "Borrow_Item added to Borrow.", 1)>
       </cfif>
        <cfcatch>
            <cfset theResult=queryNew("status, message")>
            <cfset t = queryaddrow(theResult,1)>
            <cfset t = QuerySetCell(theResult, "status", "-1", 1)>
            <cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
        </cfcatch>
     </cftry>
        <cfreturn theResult>
</cffunction>
<!------------------------------------------------------->

<cffunction name="deleteBorrowItem" access="remote">
    <cfargument name="borrow_item_id" type="numeric" required="yes">
    <cftry>
       <cfquery name="newBorrow_Item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newBorrow_ItemRes">
		DELETE from BORROW_ITEM where
			BORROW_ITEM_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#borrow_item_id#">
        </cfquery>
        <cfif newBorrow_ItemRes.recordcount eq 0>
             <cfset theResult=queryNew("status, message")>
             <cfset t = queryaddrow(theResult,1)>
             <cfset t = QuerySetCell(theResult, "status", "0", 1)>
             <cfset t = QuerySetCell(theResult, "message", "Record not deleted. #borrow_item_id# #newBorrow_ItemRes.sql#", 1)>
       </cfif>
       <cfif newBorrow_ItemRes.recordcount eq 1>
             <cfset theResult=queryNew("status, message")>
             <cfset t = queryaddrow(theResult,1)>
             <cfset t = QuerySetCell(theResult, "status", "1", 1)>
             <cfset t = QuerySetCell(theResult, "message", "Borrow_Item deleted.", 1)>
       </cfif>
        <cfcatch>
            <cfset theResult=queryNew("status, message")>
            <cfset t = queryaddrow(theResult,1)>
            <cfset t = QuerySetCell(theResult, "status", "-1", 1)>
            <cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
        </cfcatch>
     </cftry>
        <cfreturn theResult>
</cffunction>

<!------------------------------------------------------------------>

<cffunction name="getBorrowItemsHTML" returntype="string" access="remote" returnformat="plain">
        <cfargument name="transaction_id" type="numeric" required="yes">
        <cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                select transaction_id,borrow_item_id,catalog_number,sci_name,no_of_spec,spec_prep,type_status,country_of_origin,object_remarks from borrow_item where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
        </cfquery>


            <cfset resulthtml = "<table style='width:1100px;'>">
            <cfset resulthtml = resulthtml & "<h3>Borrowed Items</h3>">
            <cfset resulthtml = resulthtml & "<tr><td><label>Catalog Number</label></td><td><label>Scientific Name</label></td>">
            <cfset resulthtml = resulthtml & "<td><label>No. of Specimens</label></td>">
            <cfset resulthtml = resulthtml & "<td><label>Specimen Preparation</label></td>">
            <cfset resulthtml = resulthtml & "<td><label>Type Status</label></td>">
            <cfset resulthtml = resulthtml & "<td><label>Country of Origin</label></td>">
            <cfset resulthtml = resulthtml & "<td><label>Remarks</label></td>">
            <cfset resulthtml = resulthtml & "</td></tr>">

            <cfloop query="k">
                <cfset resulthtml = resulthtml & "<tr><td>#catalog_number#</td><td>#sci_name#</td><td>#no_of_spec#</td><td>#spec_prep#</td>">
                <cfset resulthtml = resulthtml & "<td>#type_status#</td>">
                <cfset resulthtml = resulthtml & "<td>#country_of_origin#</td>">
                <cfset resulthtml = resulthtml & "<td>#object_remarks#</td>">
                <cfset resulthtml = resulthtml & "<td><input name='deleteBorrowItem' type='button' value='Delete' onclick='deleteBorrowItem(#borrow_item_id#);'>">
                <cfset resulthtml = resulthtml & "</td></tr>">


            </cfloop>
            <cfset resulthtml = resulthtml & "</table>">
        <cfreturn resulthtml>
</cffunction>

<!------------------------------------------------------------------>

<cffunction name="checkAgentFlag" access="remote">
	<cfargument name="agent_id" type="numeric" required="yes">
	<cfquery name="checkAgentQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select MCZBASE.get_worstagentrank(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">) as agentrank from dual
	</cfquery>
	<cfreturn checkAgentQuery>
</cffunction>


<!------------------------------------------------------->
<cffunction name="insertAgentName" access="remote">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="id" type="numeric" required="yes">
	<cftry>
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO agent_name (
				agent_name_id, agent_id, agent_name_type, agent_name)
			VALUES (
				sq_agent_name_id.nextval, #id#, 'aka','#name#')
		</cfquery>
		<cfreturn "success">
	<cfcatch>
		<cfreturn cfcatch.message & ': ' & cfcatch.detail>
	</cfcatch>
	</cftry>
</cffunction>
<!------------------------------------------------------->
<cffunction name="encumberThis" access="remote">
	<cfargument name="cid" type="numeric" required="yes">
	<cfargument name="eid" type="numeric" required="yes">
	<cftry>
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into  coll_object_encumbrance (ENCUMBRANCE_ID,COLLECTION_OBJECT_ID)
			values (#eid#,#cid#)
		</cfquery>
		<cfreturn cid>
	<cfcatch>
		<cfreturn cfcatch.message & ': ' & cfcatch.detail>
	</cfcatch>
	</cftry>
</cffunction>

<cffunction name="cloneCatalogedItem" access="remote">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfset problem="">
			<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select somerandomsequence.nextval c from dual
			</cfquery>
			<cfset key=k.c>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				insert into bulkloader (
					COLLECTION_OBJECT_ID,
					LOADED,
					ENTEREDBY,
					ACCN,
					TAXON_NAME,
					NATURE_OF_ID,
					MADE_DATE,
					IDENTIFICATION_REMARKS,
					COLLECTION_CDE,
					INSTITUTION_ACRONYM,
					COLL_OBJECT_REMARKS,
					COLLECTING_EVENT_ID
				) (
					select
						#key#,
						'cloned from ' || collection || ' ' || cat_num,
						'#session.username#',
						accn_number,
						scientific_name,
						nature_of_id,
						made_date,
						IDENTIFICATION_REMARKS,
						collection.COLLECTION_CDE,
						collection.INSTITUTION_ACRONYM,
						COLL_OBJECT_REMARKS,
						cataloged_item.COLLECTING_EVENT_ID
					from
						cataloged_item,
						collection,
						identification,
						coll_object,
						COLL_OBJECT_REMARK,
						accn
					where
						cataloged_item.collection_id=collection.collection_id and
						cataloged_item.ACCN_ID=accn.transaction_id and
						cataloged_item.collection_object_id=identification.collection_object_id and
						identification.accepted_id_fg=1 and
						cataloged_item.collection_object_id=coll_object.collection_object_id and
						cataloged_item.collection_object_id=COLL_OBJECT_REMARK.collection_object_id (+) and
						cataloged_item.collection_object_id = #collection_object_id#
				)
			</cfquery>
			<cfset debugmsg="record inserted">
			<cfquery name="idby" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					agent_name
				from
					identification,
					identification_agent,
					preferred_agent_name
				where
					identification.identification_id=identification_agent.identification_id and
					identification_agent.agent_id=preferred_agent_name.agent_id and
					identification.collection_object_id = #collection_object_id#
				order by IDENTIFIER_ORDER
			</cfquery>
			<cfif idby.recordcount is 1>
				<cfquery name="iidby" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update bulkloader set ID_MADE_BY_AGENT='#idby.agent_name#'
					where collection_object_id=#key#
				</cfquery>
			<cfelse>
				<cfset problem="too many identifiers: #valuelist(idby.agent_name)#">
			</cfif>
			<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					other_id_type,
					display_value
				from coll_obj_other_id_num
				where collection_object_id=#collection_object_id#
			</cfquery>


			<cfif oid.recordcount gt 0>
				<cfset i=1>
				<cfset sql="update bulkloader set ">
				<cfloop query="oid">
					<cfif i lt 5>
						<cfset sql=sql & "OTHER_ID_NUM_TYPE_#i# = '#other_id_type#',
							OTHER_ID_NUM_#i#='#display_value#',">
						<cfset i=i+1>
					</cfif>
				</cfloop>
				<cfset sql=sql & ' where collection_object_id=#key#'>
				<cfset sql=replace(sql,", where"," where","all")>
				<cfquery name="ioid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					#preservesinglequotes(sql)#
				</cfquery>
			</cfif>
			<cfif oid.recordcount gt 4>
				<cfset ids="">
				<cfloop query="oid">
					<cfset ids=listappend(ids,"#other_id_type#=#display_value#",";")>
				</cfloop>
				<cfset problem="too many IDs: #ids#">
			</cfif>

			<cfquery name="col" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					agent_name,
					COLLECTOR_ROLE
				from
					collector,
					preferred_agent_name
				where
					collector.agent_id=preferred_agent_name.agent_id and
					collector.collection_object_id=#collection_object_id#
				order by
					COLLECTOR_ROLE,
					COLL_ORDER
			</cfquery>

			<cfif col.recordcount gt 0>
				<cfset i=1>
				<cfset sql="update bulkloader set ">
				<cfloop query="col">
					<cfif i lt 9>
						<cfset sql=sql & "COLLECTOR_AGENT_#i# = '#replace(agent_name, "'", "''")#',
							COLLECTOR_ROLE_#i#='#COLLECTOR_ROLE#',">
						<cfset i=i+1>
					</cfif>
				</cfloop>
				<cfset sql=sql & ' where collection_object_id=#key#'>
				<cfset sql=replace(sql,", where"," where","all")>
				<cfquery name="icoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					#preservesinglequotes(sql)#
				</cfquery>
			</cfif>
			<cfif col.recordcount gt 8>
				<cfset ids="">
				<cfloop query="oid">
					<cfset ids=listappend(ids,"#other_id_type#=#display_value#",";")>
				</cfloop>
				<cfset problem="too many collectors: #valuelist(col.agent_name)#">
			</cfif>


			<cfquery name="part" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					part_name,
					condition,
					/*p.barcode,*/
					p.label,
					to_char(lot_count) lot_count,
					COLL_OBJ_DISPOSITION,
					coll_object_remarks
				from
					specimen_part,
					coll_object,
					coll_object_remark,
					coll_obj_cont_hist,
					container c,
					container p
				where
					specimen_part.collection_object_id=coll_object.collection_object_id and
					specimen_part.collection_object_id=coll_object_remark.collection_object_id (+) and
					specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id and
					coll_obj_cont_hist.container_id=c.container_id (+) and
					c.parent_container_id=p.container_id (+) and
					specimen_part.derived_from_cat_item=#collection_object_id#
			</cfquery>

			<cfif part.recordcount gt 0>
				<cfset i=1>
				<cfset sql="update bulkloader set ">
				<cfloop query="part">
					<cfif i lt 13>
						<cfset sql=sql & "PART_NAME_#i# = '#part_name#',
							PART_CONDITION_#i#='#condition#',
							PART_LOT_COUNT_#i#='#lot_count#',
							PART_DISPOSITION_#i#='#COLL_OBJ_DISPOSITION#',
							PART_REMARK_#i#='#replace(coll_object_remarks,"'","''","all")#',">
						<cfset i=i+1>
					</cfif>
				</cfloop>
				<cfset sql=sql & ' where collection_object_id=#key#'>
				<cfset sql=replace(sql,", where"," where","all")>
				<cfquery name="ipart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					#preservesinglequotes(sql)#
				</cfquery>
			</cfif>
			<cfif part.recordcount gt 12>
				<cfset problem="too many part: #valuelist(part.part_name)#">
			</cfif>



			<cfquery name="att" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					ATTRIBUTE_TYPE,
					ATTRIBUTE_VALUE,
					ATTRIBUTE_UNITS,
					ATTRIBUTE_REMARK,
					agent_name,
					to_char(DETERMINED_DATE,'yyyy-mm-dd') DETERMINED_DATE,
					DETERMINATION_METHOD
				from
					attributes,
					preferred_agent_name
				where
					attributes.DETERMINED_BY_AGENT_ID=preferred_agent_name.agent_id and
					attributes.collection_object_id=#collection_object_id#
			</cfquery>
			<!--- attributes 1 through 6 are customizable and we can't use them here --->
			<cfif att.recordcount gt 0>
				<cfset i=7>
				<cfset sql="update bulkloader set ">
				<cfloop query="att">
					<cfif i lte 10>
						<cfset sql=sql & "ATTRIBUTE_#i# = '#ATTRIBUTE_TYPE#',
							ATTRIBUTE_VALUE_#i#='#ATTRIBUTE_VALUE#',
							ATTRIBUTE_UNITS_#i#='#ATTRIBUTE_UNITS#',
							ATTRIBUTE_REMARKS_#i#='#ATTRIBUTE_REMARK#',
							ATTRIBUTE_DATE_#i#='#DETERMINED_DATE#',
							ATTRIBUTE_DET_METH_#i#='#DETERMINATION_METHOD#',
							ATTRIBUTE_DETERMINER_#i#='#agent_name#',">
						<cfset i=i+1>
					</cfif>
				</cfloop>
				<cfset sql=sql & ' where collection_object_id=#key#'>
				<cfset sql=replace(sql,", where"," where","all")>
				<cfquery name="iatt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					#preservesinglequotes(sql)#
				</cfquery>
			</cfif>
			<cfif att.recordcount gt 4>
				<cfset problem="too many attribute: #valuelist(att.ATTRIBUTE_TYPE)#">
			</cfif>
			<cfquery name="irel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update bulkloader set
					COLL_OBJECT_REMARKS='#problem#',
					RELATIONSHIP='cloned from record',
					RELATED_TO_NUMBER= (
										select
											collection.institution_acronym || ':' || collection.collection_cde || ':' || cat_num
										from
											cataloged_item,collection
										where cataloged_item.collection_id=collection.collection_id and
										cataloged_item.collection_object_id=#collection_object_id#
										),
					RELATED_TO_NUM_TYPE='catalog number'
				where collection_object_id=#key#
			</cfquery>
		</cftransaction>
			<cfreturn "spiffy:#key#">
		<cfcatch>
			<cfreturn "fail: #cfcatch.message# #problem# SQL:#preservesinglequotes(sql)#">
		</cfcatch>
	</cftry>
</cffunction>
<!------------------------------------------------------->
<cffunction name="getGeologyValues" access="remote">
	<cfargument name="attribute" type="string" required="yes">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			attribute_value
		FROM
			geology_attribute_hierarchy
		WHERE
			USABLE_VALUE_FG=1 and
			attribute='#attribute#'
		group by attribute_value
		order by attribute_value
	</cfquery>
	<cfreturn d>
</cffunction>
<!------------------------------------------------------->
<cffunction name="getReportDescription" access="remote">
	<cfargument name="report_id" type="string" required="yes">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT description from cf_report_sql where report_name = <cfqueryparam value="#report_id#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfreturn d>
</cffunction>
<!------------------------------------------------------->

<cffunction name="saveAgentRank" access="remote">
	<cfargument name="agent_id" type="numeric" required="yes">
	<cfargument name="agent_rank" type="string" required="yes">
	<cfargument name="remark" type="string" required="no">
	<cfargument name="transaction_type" type="string" required="yes">
	<cftry>
		<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into agent_rank (
				agent_id,
				agent_rank,
				ranked_by_agent_id,
				remark,
				transaction_type
			) values (
				#agent_id#,
				'#agent_rank#',
				#session.myAgentId#,
				'#escapeQuotes(remark)#',
				'#transaction_type#'
			)
		</cfquery>
		<cfreturn agent_id>
	<cfcatch>
		<cfreturn "fail: #cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="checkDOI" access="remote">
	<cfargument name="doi" type="string" required="yes">
	<cfhttp method="head" url="https://doi.org/#doi#"></cfhttp>
	<cfif left(cfhttp.statuscode,3) is "404">
		<cfreturn cfhttp.statuscode>
	<cfelse>
		<cfreturn "true">
	</cfif>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="getPublication" access="remote">
	<cfargument name="idtype" type="string" required="yes">
	<cfargument name="identifier" type="string" required="yes">
	<cfparam name="debug" default="false">
	<cfset rauths="">
	<cfset lPage=''>
	<cfset pubYear=''>
	<cfset jVol=''>
	<cfset jIssue=''>
	<cfset fPage=''>
	<cfset fail="">
	<cfset firstAuthLastName=''>
	<cfset secondAuthLastName=''>
	<cfoutput>
		<cftry>
		<cfif idtype is 'DOI'>
			<cfhttp url="http://www.crossref.org/openurl/?id=#identifier#&noredirect=true&pid=bhaleyOEB@gmail.com&format=unixref"></cfhttp>
			<cfset r=xmlParse(cfhttp.fileContent)>
			<cfif debug>
				<cfdump var=#r#>
			</cfif>
			<cfif left(cfhttp.statuscode,3) is not "200" or not structKeyExists(r.doi_records[1].doi_record[1].crossref[1],"journal")>
				<cfset fail="not found or not journal">
			</cfif>
			<cfif len(fail) is 0>
				<cfset numberOfAuthors=arraylen(r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article[1].contributors.xmlchildren)>
				<cfloop from="1" to="#numberOfAuthors#" index="i">
					<cfset fName=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article[1].contributors[1].person_name[i].given_name.xmltext>
					<cfset lName=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article[1].contributors[1].person_name[i].surname.xmltext>
					<cfset thisName=fName & ' ' & lName>
					<cfset rauths=listappend(rauths,thisName,"|")>
				</cfloop>
				<cfset firstAuthLastName=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article[1].contributors[1].person_name[1].surname.xmltext>
				<cfif numberOfAuthors gt 1>
					<cfset secondAuthLastName=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article[1].contributors[1].person_name[2].surname.xmltext>
				</cfif>
				<cfif structKeyExists(r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article.publication_date,"year")>
					<cfset pubYear=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article.publication_date.year.xmltext>
				<cfelseif structKeyExists(r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_issue.publication_date,"year")>>
					<cfset pubYear=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_issue.publication_date.year.xmltext>
				</cfif>
				<cfset pubTitle=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article.titles.title.xmltext>
				<cfset jName=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_metadata.full_title.xmltext>
				<cfif structKeyExists(r.doi_records[1].doi_record[1].crossref[1].journal[1],"journal_issue")>
					<cfif structKeyExists(r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_issue,"journal_volume")>
						<cfif structKeyExists(r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_issue.journal_volume,"volume")>
							<cfset jVol=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_issue.journal_volume.volume.xmltext>
						</cfif>
					</cfif>
					<cfif structKeyExists(r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_issue,"issue")>
						<cfset jIssue=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_issue.issue.xmltext>
					</cfif>
				</cfif>
				<cfif structKeyExists(r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article,"pages")>
					<cfif structKeyExists(r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article.pages,"first_page")>
						<cfset fPage=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article.pages.first_page.xmltext>
					</cfif>
					<cfif structKeyExists(r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article.pages,"last_page")>
						<cfset lPage=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article.pages.last_page.xmltext>
					</cfif>
				</cfif>
			</cfif><!--- end DOI --->
		<cfelseif idtype is "PMID">
			<cfhttp url="http://www.ncbi.nlm.nih.gov/pubmed/#identifier#?report=XML"></cfhttp>
			<cfset theData=replace(cfhttp.fileContent,'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">','')>
			<cfset theData=replace(theData,"&gt;",">","all")>
			<cfset theData=replace(theData,"&lt;","<","all")>
			<cfset r=xmlParse(theData)>
			<cfif left(cfhttp.statuscode,3) is not "200" or not structKeyExists(r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1],"Journal")>
				<cfset fail="not found or not journal">
			</cfif>
			<cfif len(fail) is 0>
				<cfif debug>
					<cfdump var=#r#>
				</cfif>
				<cfset numberOfAuthors=arraylen(r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].AuthorList[1].xmlchildren)>
				<cfloop from="1" to="#numberOfAuthors#" index="i">
					<cfset fName=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].AuthorList[1].Author[i].ForeName.xmltext>
					<cfset lName=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].AuthorList[1].Author[i].LastName.xmltext>
					<cfset thisName=fName & ' ' & lName>
					<cfset rauths=listappend(rauths,thisName,"|")>
				</cfloop>
				<cfset firstAuthLastName=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].AuthorList[1].Author[1].LastName.xmltext>
				<cfif numberOfAuthors gt 1>
					<cfset secondAuthLastName=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].AuthorList[1].Author[2].LastName.xmltext>
				</cfif>
				<cfif structKeyExists(r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].Journal[1].JournalIssue[1].PubDate,"Year")>
					<cfset pubYear=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].Journal[1].JournalIssue[1].PubDate.Year.xmltext>
				</cfif>
				<cfset pubTitle=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].ArticleTitle.xmltext>
				<cfif right(pubTitle,1) is ".">
					<cfset pubTitle=left(pubTitle,len(pubTitle)-1)>
				</cfif>
				<cfset jName=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].Journal.Title.xmltext>
				<cfif structKeyExists(r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].Journal.JournalIssue,"Issue")>
					<cfset jIssue=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].Journal.JournalIssue.Issue.xmltext>
				</cfif>
				<cfif structKeyExists(r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].Journal.JournalIssue,"Volume")>
					<cfset jVol=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].Journal.JournalIssue.Volume.xmltext>
				</cfif>
				<cfset pages=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].Pagination.MedlinePgn.xmltext>
				<cfif listlen(pages,"-") is 2>
					<cfset fPage=listgetat(pages,1,"-")>
					<cfset lPage=listgetat(pages,2,"-")>
				</cfif>
			</cfif><!--- PMID nofail --->
		</cfif><!---- end PMID --->
		<cfcatch>
			<cfset fail='error_getting_data: #cfcatch.message# #cfcatch.detail#'>
		</cfcatch>
		</cftry>

		<cfif len(fail) is 0>
			<cftry>
			<cfif listlen(rauths,"|") is 2>
				<cfset auths=replace(rauths,"|"," and ")>
			<cfelse>
				<cfset auths=listchangedelims(rauths,", ","|")>
			</cfif>
			<cfset longCit="#auths#.">
			<cfif len(pubYear) gt 0>
				<cfset longCit=longCit & " #pubYear#.">
			</cfif>
			<cfset longCit=longCit & " #pubTitle#. #jName#">
			<cfif len(jVol) gt 0>
				<cfset longCit=longCit & " #jVol#">
			</cfif>
			<cfif len(jIssue) gt 0>
				<cfset longCit=longCit & "(#jIssue#)">
			</cfif>
			<cfif len(fPage) gt 0>
				<cfset longCit=longCit & ":#fPage#">
			</cfif>
			<cfif len(lPage) gt 0>
				<cfset longCit=longCit & "-#lPage#">
			</cfif>
			<cfset longCit=longCit & ".">
			<cfif numberOfAuthors is 1>
				<cfset shortCit="#firstAuthLastName# #pubYear#">
			<cfelseif numberOfAuthors is 2>
				<cfset shortCit="#firstAuthLastName# and #secondAuthLastName# #pubYear#">
			<cfelse>
				<cfset shortCit="#firstAuthLastName# et al. #pubYear#">
			</cfif>
			<cfset d = querynew("STATUS,PUBLICATIONTYPE,LONGCITE,SHORTCITE,YEAR,AUTHOR1,AUTHOR2,AUTHOR3,AUTHOR4,AUTHOR5")>
			<cfset temp = queryaddrow(d,1)>
			<cfset temp = QuerySetCell(d, "STATUS", 'success', 1)>
			<cfset temp = QuerySetCell(d, "PUBLICATIONTYPE", 'journal article', 1)>
			<cfset temp = QuerySetCell(d, "LONGCITE", longCit, 1)>
			<cfset temp = QuerySetCell(d, "SHORTCITE", shortCit, 1)>
			<cfset temp = QuerySetCell(d, "YEAR", pubYear, 1)>
			<cfset l=1>
			<cfloop list="#rauths#" index="a" delimiters="|">
				<cfif l lte 5>
					<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
						select * from (
							select
								preferred_agent_name.agent_name,
								preferred_agent_name.agent_id
							from
								preferred_agent_name,
								agent_name
							where
								preferred_agent_name.agent_id=agent_name.agent_id and
								upper(agent_name.agent_name) like '%#ucase(a)#%'
							group by
								preferred_agent_name.agent_name,
								preferred_agent_name.agent_id
						) where rownum<=5
					</cfquery>
					<cfif a.recordcount gt 0>
						<cfset thisAuthSugg="">
						<cfloop query="a">
							<cfset thisAuthSuggElem="#agent_name#@#agent_id#">
							<cfset thisAuthSugg=listappend(thisAuthSugg,thisAuthSuggElem,"|")>
						</cfloop>
					<cfelse>
						<cfif idtype is "DOI">
							<cfset thisLastName=r.doi_records[1].doi_record[1].crossref[1].journal[1].journal_article[1].contributors[1].person_name[l].surname.xmltext>
						<cfelseif idtype is "PMID">
							<cfset thisLastName=r.pre[1].PubmedArticle[1].MedlineCitation[1].Article[1].AuthorList[1].Author[l].LastName.xmltext>
						</cfif>

						<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
							select * from (
								select
									preferred_agent_name.agent_name,
									preferred_agent_name.agent_id
								from
									preferred_agent_name,
									agent_name
								where
									preferred_agent_name.agent_id=agent_name.agent_id and
									upper(agent_name.agent_name) like '%#ucase(thisLastName)#%'
							) where rownum<=5
						</cfquery>
						<cfif a.recordcount gt 0>
							<cfset thisAuthSugg="">
							<cfloop query="a">
								<cfset thisAuthSuggElem="#agent_name#@#agent_id#">
								<cfset thisAuthSugg=listappend(thisAuthSugg,thisAuthSuggElem,"|")>
							</cfloop>
						<cfelse>
							<cfset thisAuthSugg="">
						</cfif>
					</cfif>
					<cfset temp = QuerySetCell(d, "AUTHOR#l#", thisAuthSugg, 1)>
				</cfif>
				<cfset l=l+1>
			</cfloop>
		<cfcatch>
			<cfset fail='error_getting_author: #cfcatch.message# #cfcatch.detail#'>
		</cfcatch>
		</cftry>
	</cfif>
	<cfif len(fail) gt 0>
		<cfset d = querynew("STATUS,PUBLICATIONTYPE,LONGCITE,SHORTCITE,YEAR,AUTHORS")>
		<cfset temp = queryaddrow(d,1)>
		<cfset temp = QuerySetCell(d, "STATUS", 'fail:#cfhttp.statuscode#:#fail#', 1)>
	</cfif>
	<cfreturn d>
</cfoutput>
</cffunction>
<!------------------------------------------------------->
<cffunction name="getPubAttributes" access="remote">
	<cfargument name="attribute" type="string" required="yes">
	<cftry>
		<cfquery name="res" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT control 
			FROM ctpublication_attribute 
			WHERE publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">
		</cfquery>
		<cfif len(res.control) gt 0>
			<cfset controlBits = listToArray(res.control,'.')>
			<cfif ArrayLen(controlBits) EQ 2>
				<!--- support TABLE.FIELD structure for control as well as TABLE --->
				<cfquery name="ctval" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select #controlBits[2]# from #controlBits[1]#
				</cfquery>
			<cfelse>
				<cfquery name="ctval" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select * from #res.control#
				</cfquery>
			</cfif>
			<cfset cl=ctval.columnlist>
			<cfif listcontainsnocase(cl,"description")>
				<cfset cl=listdeleteat(cl,listfindnocase(cl,"description"))>
			</cfif>
			<cfif listcontainsnocase(cl,"collection_cde")>
				<cfset cl=listdeleteat(cl,listfindnocase(cl,"collection_cde"))>
			</cfif>
			<cfif listlen(cl) is 1>
				<cfquery name="return" dbtype="query">
					select #cl# as V from ctval order by #cl#
				</cfquery>
				<cfreturn return>
			<cfelse>
				<cfreturn "fail: cl is #cl#">
			</cfif>
		</cfif>
	<cfcatch>
		<cfreturn "fail: #cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn "nocontrol">
</cffunction>
<!------------------------------------------------------->
<cffunction name="kill_canned_search" access="remote">
	<cfargument name="canned_id" type="numeric" required="yes">
	<cftry>
		<cfquery name="res" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from cf_canned_search where canned_id=#canned_id#
		</cfquery>
		<cfset result="#canned_id#">
	<cfcatch>
		<cfset result = "failure: #cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="genMD5" access="remote">
	<cfargument name="uri" type="string" required="yes">
	<cfif len(uri) is 0>
		<cfreturn ''>
	<cfelseif uri contains application.serverRootUrl>
		<cftry>
		<cfset f=replace(uri,application.serverRootUrl,application.webDirectory)>
		<cffile action="readbinary" file="#f#" variable="myBinaryFile">
		<cfset md5 = createObject("component","includes.cfc.hashBinary").hashBinary(myBinaryFile)>
		<cfreturn md5>
		<cfcatch>
			<cfreturn "">
		</cfcatch>
		</cftry>
	<cfelse>
		<cftry>
			<cfhttp url="#uri#" getAsbinary="yes" />
			<cfset md5 = createObject("component","includes.cfc.hashBinary").hashBinary(cfhttp.filecontent)>
			<cfreturn md5>
		<cfcatch>
			<cfreturn "">
		</cfcatch>
		</cftry>
	</cfif>
</cffunction>
<!-------------------------------------------->
<cffunction name="saveLocSrchPref" access="remote">
	<cfargument name="id" type="string" required="yes">
	<cfargument name="onOff" type="numeric" required="yes">
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
	   <cfthread name="saveLocSrchThread" >
		<cftry>
			<cfquery name="ins" datasource="cf_dbuser">
				select LOCSRCHPREFS
				from cf_users
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset cv=valuelist(ins.LOCSRCHPREFS)>
			<cfif onOff is 1>
				<cfif not listfind(cv,id)>
					<cfset nv=listappend(cv,id)>
				</cfif>
			<cfelse>
				<cfif listfind(cv,id)>
					<cfset nv=listdeleteat(cv,listfind(cv,id))>
				</cfif>
			</cfif>
			<cfquery name="ins" datasource="cf_dbuser">
				update cf_users
				set LOCSRCHPREFS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nv#">
				where
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset session.locSrchPrefs=nv>
			<cfcatch><!-- nada --></cfcatch>
		</cftry>
	   </cfthread>
	</cfif>
	<cfreturn 1>
</cffunction>
<!------------------------------------------->
<cffunction name="updatePartDisposition" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="disposition" type="string" required="yes">
	<cftry>
		<cfquery name="upPartDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update coll_object set COLL_OBJ_DISPOSITION
			='#disposition#' where
			collection_object_id=#part_id#
		</cfquery>
		<cfset result = querynew("STATUS,PART_ID,DISPOSITION")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "status", "success", 1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "disposition", "#disposition#", 1)>
	<cfcatch>
		<cfset result = querynew("STATUS,PART_ID,DISPOSITION")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "status", "failure", 1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "disposition", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<!------------------------------------------->
<cffunction name="remPartFromLoan" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cftry>
		<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from loan_item where
			collection_object_id = #part_id# and
			transaction_id=#transaction_id#
		</cfquery>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>

	</cftry>
		<cfreturn result>
</cffunction>
<!------------------------------------------->
<cffunction name="remPartFromDeacc" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cftry>
		<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from deacc_item where
			collection_object_id = #part_id# and
			transaction_id=#transaction_id#
		</cfquery>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>

	</cftry>
		<cfreturn result>
</cffunction>
<!------------------------------------------->
<cffunction name="del_remPartFromLoan" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				delete from loan_item where
				collection_object_id = #part_id# and
				transaction_id=#transaction_id#
			</cfquery>
			<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				delete from specimen_part where collection_object_id = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<!------------------------------------------->
<cffunction name="del_remPartFromDeacc" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				delete from deacc_item where
				collection_object_id = #part_id# and
				transaction_id=#transaction_id#
			</cfquery>
			<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				delete from specimen_part where collection_object_id = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<!------------------------------------------->
<cffunction name="updateInstructions" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="item_instructions" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update loan_item set
				ITEM_INSTRUCTIONS = '#item_instructions#'
				where
				TRANSACTION_ID=#transaction_id# and
				COLLECTION_OBJECT_ID = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>

	</cftry>
		<cfreturn result>
</cffunction>
<!----------------------------------------->
<cffunction name="updateLoanItemRemarks" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="loan_item_remarks" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update loan_item set
				loan_item_remarks = '#loan_item_remarks#'
				where
				TRANSACTION_ID=#transaction_id# and
				COLLECTION_OBJECT_ID = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>

	</cftry>
		<cfreturn result>
</cffunction>

<!------------------------------------------->
<cffunction name="updateDeaccItemRemarks" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="deacc_item_remarks" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update deacc_item set
				deacc_item_remarks = '#deacc_item_remarks#'
				where
				TRANSACTION_ID=#transaction_id# and
				COLLECTION_OBJECT_ID = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>

	</cftry>
		<cfreturn result>
</cffunction>
<!------------------------------------------->
<cffunction name="updateDeaccItemInstructions" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="item_instructions" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update deacc_item set
				item_instructions = '#item_instructions#'
				where
				TRANSACTION_ID=#transaction_id# and
				COLLECTION_OBJECT_ID = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>

	</cftry>
		<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="addAddressHtml" returntype="string" access="remote" returnformat="plain">
   <cfargument name="create_from_address_id" type="string" required="yes">
   <cfargument name="address_type" type="string" required="no">
   <cfset result="">
   <cfif not isdefined("address_type") or len(#address_type#) gt 0>
      <cfset address_type = "temporary">
   </cfif>
   <cfquery name="qAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    	select agent_id from addr where addr_id = <cfqueryparam value="#create_from_address_id#" CFSQLTYPE="CF_SQL_VARCHAR">
   </cfquery>
   <cfset agent_id = qAgent.agent_id >
   <cfquery name="ctAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    	select addr_type from ctaddr_type where addr_type = <cfqueryparam value="#address_type#" CFSQLTYPE="CF_SQL_VARCHAR">
   </cfquery>
   <cfif ctAddrType.addr_type IS ''>
       <cfset result=result & "<ul><li>Provided address type is unknown.</li></ul>">
   <cfelse>
   <cfset result="">
   <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
           select agent_name
           from agent a left join agent_name on a.preferred_agent_name_id = agent_name.agent_name_id
           where
               a.agent_id = <cfqueryparam value="#agent_id#" CFSQLType="CF_SQL_DECIMAL">
               and rownum < 2
   </cfquery>
   <cfif query.recordcount gt 0>
       <cfset result=result & "<ul>">
       <cfloop query="query">
<!-- TODO: Make ajax response to save and hold resulting addressid for pickup.-->
          <cfset result = result & "
<div id='newAddressStatus'></div>
<form name='newAddress' id='newAddressForm'>
    <input type='hidden' name='method' value='addNewAddress'>
    <input type='hidden' name='returnformat' value='json'>
    <input type='hidden' name='queryformat' value='column'>
    <input type='hidden' name='agent_id' value='#agent_id#'>
    <input type='hidden' name='addr_type' value='#address_type#'>
    <input type='hidden' name='valid_addr_fg' id='valid_addr_fg' value='0'>
    <table>
     <tr>
      <td>
       <strong>Address Type:</strong> #ctAddrType.addr_type#
      </td>
      <td>
       <strong>Address For:</strong> #query.agent_name#
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='institution'>Institution</label>
       <input type='text' name='institution' id='institution'size='50' >
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='department'>Department</label>
       <input type='text' name='department' id='department' size='50' >
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='street_addr1'>Street Address 1</label>
       <input type='text' name='street_addr1' id='street_addr1' size='50' class='reqdClr'>
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='street_addr2'>Street Address 2</label>
       <input type='text' name='street_addr2' id='street_addr2' size='50'>
      </td>
     </tr>
     <tr>
      <td>
       <label for='city'>City</label>
       <input type='text' name='city' id='city' class='reqdClr'>
      </td>
      <td>
       <label for='state'>State</label>
       <input type='text' name='state' id='state' class='reqdClr'>
      </td>
     </tr>
     <tr>
      <td>
       <label for='zip'>Zip</label>
       <input type='text' name='zip' id='zip' class='reqdClr'>
      </td>
      <td>
       <label for='country_cde'>Country</label>
       <input type='text' name='country_cde' id='country_cde' class='reqdClr'>
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='mail_stop'>Mail Stop</label>
       <input type='text' name='mail_stop' id='mail_stop'>
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='addr_remarks'>Address Remark</label>
       <input type='text' name='addr_remarks' id='addr_remarks' size='50'>
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <input type='submit' class='insBtn' value='Create Address' >
       <script>
         $('##newAddressForm').submit( function (e) {
             $.ajax({
                url: '/component/functions.cfc',
                data : $('##newAddressForm').serialize(),
                success: function (result) {
                     if (result.DATA.STATUS[0]=='success') {
                        $('##newAddressStatus').html('New Address Added');
                        $('##new_address_id').val(result.DATA.ADDRESS_ID[0]);
                        $('##new_address').val(result.DATA.ADDRESS[0]);
                        $('##tempAddressDialog').dialog('close');
                     } else {
                        $('##newAddressStatus').html(result.DATA.MESSAGE[0]);
                     }
                },
        	dataType: 'json'
              });
              e.preventDefault();
         });
      </script>
      </td>
     </tr>
    </table>
    <input type='hidden' name='new_address_id' id='new_address_id' value=''>
    <input type='hidden' name='new_address' id='new_address' value=''>
</form>
" >
       </cfloop>
       <cfset result= result & "</ul>">
   <cfelse>
       <cfset result=result & "<ul><li>No Agent Found for temporary address.</li></ul>">
   </cfif>
   </cfif>  <!--- known address type provided --->
   <cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="addNewAddress" access="remote" returntype="query">
	<cftransaction>
    <cftry>
        <cfquery name="prefName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
            select agent_name from preferred_agent_name
            where agent_id= <cfqueryparam value='#agent_id#' cfsqltype='CF_SQL_DECIMAL'>
        </cfquery>
        <cfquery name="addrNextId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
            select sq_addr_id.nextval as id from dual
        </cfquery>
        <cfset pk = addrNextId.id>
        <cfquery name="addr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addrResult">
            INSERT INTO addr (
                                ADDR_ID
                                ,STREET_ADDR1
                                ,STREET_ADDR2
                                ,institution
                                ,department
                                ,CITY
                                ,state
                                ,ZIP
                                ,COUNTRY_CDE
                                ,MAIL_STOP
                                ,agent_id
                                ,addr_type
                                ,valid_addr_fg
                                ,addr_remarks
                        ) VALUES (
                                 <cfqueryparam value='#pk#' cfsqltype='CF_SQL_DECIMAL'>
                                ,<cfqueryparam value='#STREET_ADDR1#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#STREET_ADDR2#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#institution#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#department#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#CITY#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#state#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#ZIP#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#COUNTRY_CDE#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#MAIL_STOP#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#agent_id#' cfsqltype='CF_SQL_DECIMAL'>
                                ,<cfqueryparam value='#addr_type#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#valid_addr_fg#' cfsqltype='CF_SQL_DECIMAL'>
                                ,<cfqueryparam value='#addr_remarks#' cfsqltype='CF_SQL_VARCHAR'>
                        )
        </cfquery>
        <cfquery name="newAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addrResult">
            select formatted_addr from addr
            where addr_id = <cfqueryparam value='#pk#' cfsqltype="CF_SQL_DECIMAL">
        </cfquery>
		<cfset q=queryNew("STATUS,ADDRESS_ID,ADDRESS,MESSAGE")>
		<cfset t = queryaddrow(q,1)>
		<cfset t = QuerySetCell(q, "STATUS", "success", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS_ID", "#pk#", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS", "#newAddr.formatted_addr#", 1)>
		<cfset t = QuerySetCell(q, "MESSAGE", "", 1)>
     <cfcatch>
        <cftransaction action="rollback"/>
		<cfset q=queryNew("STATUS,ADDRESS_ID,ADDRESS,MESSAGE")>
		<cfset t = queryaddrow(q,1)>
		<cfset t = QuerySetCell(q, "STATUS", "error", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS_ID", "", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS", "", 1)>
		<cfset t = QuerySetCell(q, "MESSAGE", "Error: #cfcatch.message# #cfcatch.detail#", 1)>
     </cfcatch>
     </cftry>
	</cftransaction>
     <cfreturn q>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getMediaForTransHtml" returntype="string" access="remote" returnformat="plain">
   <cfargument name="transaction_id" type="string" required="yes">
   <cfargument name="transaction_type" type="string" required="yes">
   <cfset relword="documents">
   <cfset result="">
   <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
           select distinct
               media.media_id as media_id,
               preview_uri,
               media.media_uri,
               media.mime_type,
               media.media_type as media_type,
  					mczbase.get_media_descriptor(media.media_id) as media_descriptor,
               MCZBASE.is_media_encumbered(media.media_id) as hideMedia,
               nvl(MCZBASE.get_medialabel(media.media_id,'description'),'[No Description]') as label_value
           from
               media_relations left join media on media_relations.media_id = media.media_id
           where
               media_relationship like '% #transaction_type#'
               and media_relations.related_primary_key = <cfqueryparam value="#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
   </cfquery>
	<cfif query.recordcount gt 0>
		<cfset result=result & "<ul>">
		<cfloop query="query">
			<cfset puri=getMediaPreview(preview_uri,media_type) >
			<cfif puri EQ "/images/noThumb.jpg">
				<cfset altText = "Red X in a red square, with text, no preview image available">
			<cfelse>
				<cfset altText = query.media_descriptor>
			</cfif>
			<cfset result = result & "<li><a href='#media_uri#' target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15' alt='#altText#'></a> #mime_type# #media_type# #label_value# <a href='/media/#media_id#' target='_blank'>Media Details</a>  <a onClick='  confirmAction(""Remove this media from this transaction?"", ""Confirm Unlink Media"", function() { deleteMediaFromTrans(#media_id#,#transaction_id#,""#relWord# #transaction_type#""); } ); '>Remove</a> </li>" >
		</cfloop>
		<cfset result= result & "</ul>">
	<cfelse>
		<cfset result=result & "<ul><li>None</li></ul>">
	</cfif>
   <cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="removeMediaFromDeaccession" returntype="query" access="remote">
        <cfargument name="transaction_id" type="string" required="yes">
        <cfargument name="media_id" type="string" required="yes">
        <cfargument name="media_relationship" type="string" required="yes">
        <cfset r=1>
        <cftry>
            <cfquery name="deleteResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteResult">
             delete from media_relations
             where related_primary_key =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
               and media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
               and media_relationship=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship#">
            </cfquery>
                <cfif deleteResult.recordcount eq 0>
                  <cfset theResult=queryNew("status, message")>
                  <cfset t = queryaddrow(theResult,1)>
                  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
                  <cfset t = QuerySetCell(theResult, "message", "No records deleted. #media_id# #media_relationship# #transaction_id# #deleteResult.sql#", 1)>
                </cfif>
                <cfif deleteResult.recordcount eq 1>
                  <cfset theResult=queryNew("status, message")>
                  <cfset t = queryaddrow(theResult,1)>
                  <cfset t = QuerySetCell(theResult, "status", "1", 1)>
                  <cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
                </cfif>
        <cfcatch>
          <cfset theResult=queryNew("status, message")>
                <cfset t = queryaddrow(theResult,1)>
                <cfset t = QuerySetCell(theResult, "status", "-1", 1)>
                <cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
          </cfcatch>
        </cftry>
    <cfif isDefined("asTable") AND asTable eq "true">
            <cfreturn resulthtml>
    <cfelse>
            <cfreturn theResult>
    </cfif>
</cffunction>
<!------------------------------------------->
<cffunction name="updateCondition" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update coll_object set
				condition = '#condition#'
				where
				COLLECTION_OBJECT_ID = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>

	</cftry>
		<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="moveContainer" access="remote">
	<cfargument name="box_position" type="numeric" required="yes">
	<cfargument name="position_id" type="numeric" required="yes">
	<cfargument name="barcode" type="string" required="yes">
	<cfset thisContainerId = "">
	<CFTRY>
		<cfquery name="thisID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select container_id,label from container where barcode='#barcode#'
			AND container_type = 'cryovial'
		</cfquery>
		<cfif #thisID.recordcount# is 0>
			<cfquery name="thisID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select container_id,label from container where barcode='#barcode#'
				AND container_type = 'cryovial label'
			</cfquery>
			<cfif #thisID.recordcount# is 1>
				<cfquery name="update" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update container set container_type='cryovial'
					where container_id=#thisID.container_id#
				</cfquery>
				<cfset thisContainerId = #thisID.container_id#>
			</cfif>
		<cfelse>
			<cfset thisContainerId = #thisID.container_id#>
		</cfif>

		<cfif len(#thisContainerId#) gt 0>
			<cfquery name="putItIn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update container set
				parent_container_id = #position_id#,
				PARENT_INSTALL_DATE = sysdate
				where container_id = #thisContainerId#
			</cfquery>
			<cfset result = "#box_position#|#thisID.label#">
		<cfelse>
			<cfset result = "-#box_position#|Container not found.">
		</cfif>
	<cfcatch>
		<cfset result = "-#box_position#|#cfcatch.Message#">
	</cfcatch>
	</CFTRY>
	<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
		<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getCatalogedItemCitation" access="remote">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfargument name="theNum" type="string" required="yes">
	<cfargument name="type" type="string" required="yes">
	<cfoutput>
	<cftry>
		<cfif type is "cat_num">
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					cataloged_item.COLLECTION_OBJECT_ID,
					cataloged_item.cat_num,
					scientific_name
				from
					cataloged_item,
					identification
				where
					cataloged_item.collection_object_id = identification.collection_object_id AND
					accepted_id_fg=1 and
					cat_num='#theNum#' and
					collection_id=#collection_id#
			</cfquery>
		<cfelse>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					cataloged_item.COLLECTION_OBJECT_ID,
					cataloged_item.cat_num,
					scientific_name
				from
					cataloged_item,
					identification,
					coll_obj_other_id_num
				where
					cataloged_item.collection_object_id = identification.collection_object_id AND
					cataloged_item.collection_object_id = coll_obj_other_id_num.collection_object_id AND
					accepted_id_fg=1 and
					display_value='#theNum#' and
					other_id_type='#type#' and
					collection_id=#collection_id#
			</cfquery>
		</cfif>
		<cfcatch>
			<cfset result = querynew("collection_object_id,scientific_name")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "collection_object_id", "-1", 1)>
			<cfset temp = QuerySetCell(result, "scientific_name", "#cfcatch.Message# #cfcatch.Detail#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn result>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="setUserFormAccess" access="remote">
	<cfargument name="role" type="string" required="yes">
	<cfargument name="form" type="string" required="yes">
	<cfargument name="onoff" type="string" required="yes">
	<cfif onoff is "true">
		<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into cf_form_permissions (form_path,role_name) values ('#form#','#role#')
		</cfquery>
	<cfelseif onoff is "false">
		<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from cf_form_permissions where
				form_path = '#form#' and
				role_name = '#role#'
		</cfquery>
	<cfelse>
		<cfreturn "Error:invalid state">
	</cfif>
	<cfreturn "Success:#form#:#role#:#onoff#">
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getParts" access="remote">
	<cfargument name="collection_id" type="string" required="yes">
	<cfargument name="other_id_type" type="string" required="yes">
	<cfargument name="oidnum" type="string" required="yes">
	<cfargument name="noBarcode" type="string" required="yes">
	<cfargument name="noSubsample" type="string" required="yes">
	<cftry>
		<cfset t="select
				cataloged_item.collection_object_id,
				specimen_part.collection_object_id partID,
				decode(p.barcode,'0',null,p.barcode) barcode,
				decode(sampled_from_obj_id,
					null,part_name,
					part_name || ' SAMPLE') part_name,
				cat_num,
				collection,
				concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
				'#session.CustomOtherIdentifier#' as CustomIdType
			from
				specimen_part,
				cataloged_item,
				collection,
				coll_obj_cont_hist,
				container c,
				container p">
		<cfset w = "where
				specimen_part.derived_from_cat_item = cataloged_item.collection_object_id and
				cataloged_item.collection_id=collection.collection_id and
				specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id and
				coll_obj_cont_hist.container_id=c.container_id and
				c.parent_container_id=p.container_id (+) and
				cataloged_item.collection_id=#collection_id#">
		<cfif other_id_type is not "catalog_number">
			<cfset t=t&" ,coll_obj_other_id_num">
			<cfset w=w & " and cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id and
					coll_obj_other_id_num.other_id_type='#other_id_type#' and
					coll_obj_other_id_num.display_value='#oidnum#'">
		<cfelse>
			<cfset w=w & " and cataloged_item.cat_num=#oidnum#">
		</cfif>
		<cfif noBarcode is true>
			<cfset w=w & " and (c.parent_container_id = 0 or c.parent_container_id is null or c.parent_container_id=476089)">
				<!--- 476089 is barcode 0 - our universal trashcan --->
		</cfif>
		<cfif noSubsample is true>
			<cfset w=w & " and specimen_part.SAMPLED_FROM_OBJ_ID is null">
		</cfif>
		<cfset q = t & " " & w & " order by part_name">
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			#preservesinglequotes(q)#
		</cfquery>
		<cfquery name="u" dbtype="query">
			select count(distinct(collection_object_id)) c from q
		</cfquery>
		<cfif q.recordcount is 0>
			<cfset q=queryNew("PART_NAME")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "PART_NAME", "Error: no_parts_found", 1)>
		</cfif>
		<cfif u.c is not 1>
			<cfset q=queryNew("PART_NAME")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "PART_NAME", "Error: #u.c# specimens match", 1)>
		</cfif>
	<cfcatch>
		<!---
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "collection_object_id", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "typeList", "#cfcatch.detail#", 1)>
		<cfreturn theResult>
		--->
		<cfset q=queryNew("PART_NAME")>
		<cfset t = queryaddrow(q,1)>
		<cfset t = QuerySetCell(q, "PART_NAME", "Error: #cfcatch.Message# #cfcatch.detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn q>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getSpecimen" access="remote">
	<cfargument name="collection_id" type="string" required="yes">
	<cfargument name="other_id_type" type="string" required="yes">
	<cfargument name="oidnum" type="string" required="yes">
	<cftry>
		<cfset t="select
				cataloged_item.collection_object_id
			from
				cataloged_item">
		<cfset w = "where cataloged_item.collection_id=#collection_id#">
		<cfif other_id_type is not "catalog_number">
			<cfset t=t&" ,coll_obj_other_id_num">
			<cfset w=w & " and cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id and
					coll_obj_other_id_num.other_id_type='#other_id_type#' and
					coll_obj_other_id_num.display_value='#oidnum#'">
		<cfelse>
			<cfset w=w & " and cataloged_item.cat_num=#oidnum#">
		</cfif>
		<cfset q = t & " " & w>
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			#preservesinglequotes(q)#
		</cfquery>
		<cfif q.recordcount is 0>
			<cfset q=queryNew("collection_object_id")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "collection_object_id", "Error: item_not_found", 1)>
		<cfelseif q.recordcount gt 1>
			<cfset q=queryNew("collection_object_id")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "collection_object_id", "Error: multiple_matches", 1)>
		</cfif>
	<cfcatch>
		<cfset q=queryNew("collection_object_id")>
		<cfset t = queryaddrow(q,1)>
		<cfset t = QuerySetCell(q, "collection_object_id", "Error: #cfcatch.Message# #cfcatch.detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn q>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="addPartToContainer" access="remote">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="part_id2" type="string" required="no">
	<cfargument name="parent_barcode" type="string" required="yes">
	<cfargument name="new_container_type" type="string" required="yes">
	<cfoutput>
	<cftry>
		<cftransaction>
			<cfquery name="isGoodParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select container_id from container where container_type <> 'collection object'
				and barcode='#parent_barcode#'
			</cfquery>
			<cfif #isGoodParent.recordcount# is not 1>
				<cfreturn "0|Parent container (barcode #parent_barcode#) not found.">
			</cfif>
			<cfquery name="cont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select container_id FROM coll_obj_cont_hist where collection_object_id=#part_id#
			</cfquery>
			<cfif #cont.recordcount# is not 1>
				<cfreturn "0|Yikes! A part is not a container.">
			</cfif>
			<cfquery name="newparent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE container SET container_type = '#new_container_type#' WHERE
					container_id=#isGoodParent.container_id#
			</cfquery>
			<cftransaction action="commit" />
			<cfquery name="moveIt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE container SET parent_container_id = #isGoodParent.container_id# WHERE
				container_id=#cont.container_id#
			</cfquery>
			<cfif len(#part_id2#) gt 0>
				<cfquery name="cont2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select container_id FROM coll_obj_cont_hist where collection_object_id=#part_id2#
				</cfquery>
				<cfquery name="moveIt2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE container SET parent_container_id = #isGoodParent.container_id# WHERE
					container_id=#cont2.container_id#
				</cfquery>
			</cfif>
		</cftransaction>
		<cfquery name="coll_obj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select
				cat_num,
				institution_acronym,
				collection.collection_cde,
				collection.collection,
				scientific_name,
				part_name
				<cfif len(part_id2) gt 0>
					|| (select ' and ' || part_name from specimen_part where collection_object_id=#part_id2#)
				</cfif>
				part_name
			from
				cataloged_item,
				collection,
				identification,
				specimen_part
			where
				cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
				cataloged_item.collection_object_id=identification.collection_object_id and
				accepted_id_fg=1 and
				cataloged_item.collection_id=collection.collection_id and
				specimen_part.collection_object_id=#part_id#
		</cfquery>
		<cfset r='Moved <a href="/guid/#coll_obj.institution_acronym#:#coll_obj.collection_cde#:#coll_obj.cat_num#">'>
		<cfset r="#r##coll_obj.collection# #coll_obj.cat_num#">
		<cfset r="#r#</a> (<i>#coll_obj.scientific_name#</i>) #coll_obj.part_name#">
		<cfset r="#r# to container barcode #parent_barcode# (#new_container_type#)">
		<cfreturn '1|#r#'>>
		<cfcatch>
			<cfreturn "0|#cfcatch.message# #cfcatch.detail#">
		</cfcatch>
	</cftry>
	</cfoutput>
</cffunction>
<!------------------------------------------------------------------>
<cffunction name="changefancyCOID" access="remote">
	<cfargument name="tgt" type="string" required="yes">
	<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					fancyCOID =
					<cfif #tgt# is 1>
						#tgt#
					<cfelse>
						NULL
					</cfif>
				WHERE username = '#session.username#'
			</cfquery>
			<cfif #tgt# gt 0>
				<cfset session.fancyCOID = "#tgt#">
			<cfelse>
				<cfset session.fancyCOID = "">
			</cfif>
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!------------------------------------------------------------------>
<cffunction name="changeexclusive_collection_id" access="remote">
	<cfargument name="tgt" type="string" required="yes">
	<cftry>
		<cfquery name="up" datasource="cf_dbuser">
			UPDATE cf_users SET
				exclusive_collection_id =
				<cfif #tgt# gt 0>
					#tgt#
				<cfelse>
					NULL
				</cfif>
			WHERE username = '#session.username#'
			</cfquery>
		<cfset setDbUser(tgt)>
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="changecustomOtherIdentifier" access="remote">
	<cfargument name="tgt" type="string" required="yes">
	<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					customOtherIdentifier =
					<cfif len(#tgt#) gt 0>
						'#tgt#'
					<cfelse>
						NULL
					</cfif>
				WHERE username = '#session.username#'
			</cfquery>
			<cfset session.customOtherIdentifier = "#tgt#">
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!-------------------------------------------->
<cffunction name="getSpecSrchPref" access="remote">
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
		<cftry>
			<cfquery name="ins" datasource="cf_dbuser">
				select specsrchprefs from cf_users
				where username='#session.username#'
			</cfquery>
				<cfreturn ins.specsrchprefs>
			<cfcatch><!-- nada --></cfcatch>
		</cftry>
	</cfif>
	<cfreturn "cookie">
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="findAccession"  access="remote">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfargument name="accn_number" type="string" required="yes">
	<cftry>
		<cfquery name="accn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT accn.TRANSACTION_ID FROM accn,trans WHERE
			accn.TRANSACTION_ID=trans.TRANSACTION_ID AND
			accn_number = '#accn_number#'
			and collection_id = #collection_id#
		</cfquery>
		<cfif accn.recordcount is 1 and len(accn.transaction_id) gt 0>
			<cfreturn accn.transaction_id>
		<cfelse>
			<cfreturn -1>
		</cfif>
		<cfcatch>
			<cfreturn -1>
		</cfcatch>
	</cftry>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getSpecResultsData" access="remote">
	<cfargument name="startrow" type="numeric" required="yes">
	<cfargument name="numRecs" type="numeric" required="yes">
	<cfargument name="orderBy" type="string" required="yes">
	<cfset stopRow = startrow + numRecs -1>
	<!--- strip Safari idiocy --->
	<cfset orderBy=replace(orderBy,"%20"," ","all")>
	<cfset orderBy=replace(orderBy,"%2C",",","all")>
	<cfset orderBy=replace(orderBy,"cat_num","cat_num_prefix,cat_num_integer","all")>
	<cftry>
		<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			Select * from (
				Select a.*, rownum rnum From (
					select * from #session.SpecSrchTab# order by #orderBy#
				) a where rownum <= #stoprow#
			) where rnum >= #startrow#
		</cfquery>
		<cfset collObjIdList = valuelist(result.collection_object_id)>
		<cfset session.collObjIdList=collObjIdList>
		<cfquery name="cols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			 select column_name from user_tab_cols where
			 upper(table_name)=upper('#session.SpecSrchTab#') order by internal_column_id
		</cfquery>
		<cfset clist = result.COLUMNLIST>
		<cfset t = arrayNew(1)>
		<cfset temp = queryaddcolumn(result,"COLUMNLIST",t)>
		<cfset temp = QuerySetCell(result, "COLUMNLIST", "#valuelist(cols.column_name)#", 1)>
	<cfcatch>
			<cfset result = querynew("collection_object_id,message")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "collection_object_id", "-1", 1)>
			<cfset temp = QuerySetCell(result, "message", "#cfcatch.Message# #cfcatch.Detail#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="clientResultColumnList" access="remote">
	<cfargument name="ColumnList" type="string" required="yes">
	<cfargument name="in_or_out" type="string" required="yes">
	<cfif not isdefined("session.ResultColumnList")>
		<cfset session.ResultColumnList=''>
	</cfif>
	<cfset result="OK">
	<cfif in_or_out is "in">
		<cfloop list="#ColumnList#" index="i">
		<cfif not ListFindNoCase(session.resultColumnList,i,",")>
			<cfset session.resultColumnList = ListAppend(session.resultColumnList, i,",")>
		</cfif>
		</cfloop>
	<cfelse>
		<cfloop list="#ColumnList#" index="i">
		<cfif ListFindNoCase(session.resultColumnList,i,",")>
			<cfset session.resultColumnList = ListDeleteAt(session.resultColumnList, ListFindNoCase(session.resultColumnList,i,","),",")>
		</cfif>
		</cfloop>
	</cfif>
	<cfquery name ="upDb" datasource="cf_dbuser">
		update cf_users set resultcolumnlist='#session.resultColumnList#' where
		username='#session.username#'
	</cfquery>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="makePart" access="remote">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="part_name" type="string" required="yes">
	<cfargument name="lot_count" type="string" required="yes">
	<cfargument name="coll_obj_disposition" type="string" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cfargument name="coll_object_remarks" type="string" required="yes">
	<cfargument name="barcode" type="string" required="yes">
	<cfargument name="new_container_type" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="ccid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select sq_collection_object_id.nextval nv from dual
			</cfquery>
			<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO coll_object (
					COLLECTION_OBJECT_ID,
					COLL_OBJECT_TYPE,
					ENTERED_PERSON_ID,
					COLL_OBJECT_ENTERED_DATE,
					LAST_EDITED_PERSON_ID,
					COLL_OBJ_DISPOSITION,
					LOT_COUNT,
					CONDITION,
					FLAGS )
				VALUES (
					#ccid.nv#,
					'SP',
					#session.myAgentId#,
					sysdate,
					#session.myAgentId#,
					'#COLL_OBJ_DISPOSITION#',
					#lot_count#,
					'#condition#',
					0 )
			</cfquery>
			<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO specimen_part (
					  COLLECTION_OBJECT_ID,
					  PART_NAME
						,DERIVED_FROM_cat_item)
					VALUES (
						#ccid.nv#,
					  '#PART_NAME#'
						,#collection_object_id#)
			</cfquery>
			<cfif len(#coll_object_remarks#) gt 0>
				<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
					VALUES (#ccid.nv#, '#coll_object_remarks#')
				</cfquery>
			</cfif>
			<cfif len(barcode) gt 0>
				<cfquery name="np" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select container_id from coll_obj_cont_hist where collection_object_id=#ccid.nv#
				</cfquery>
				<cfquery name="pc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select container_id from container where barcode='#barcode#'
				</cfquery>
				<cfquery name="m2p" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update container set parent_container_id=#pc.container_id# where container_id=#np.container_id#
				</cfquery>
				<cfif len(new_container_type) gt 0>
					<cfquery name="uct" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update container set container_type='#new_container_type#' where
						container_id=#pc.container_id#
					</cfquery>
				</cfif>
			</cfif>
			<cfset q=queryNew("STATUS,PART_NAME,LOT_COUNT,COLL_OBJ_DISPOSITION,CONDITION,COLL_OBJECT_REMARKS,BARCODE,NEW_CONTAINER_TYPE")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "STATUS", "success", 1)>
			<cfset t = QuerySetCell(q, "part_name", "#part_name#", 1)>
			<cfset t = QuerySetCell(q, "lot_count", "#lot_count#", 1)>
			<cfset t = QuerySetCell(q, "coll_obj_disposition", "#coll_obj_disposition#", 1)>
			<cfset t = QuerySetCell(q, "condition", "#condition#", 1)>
			<cfset t = QuerySetCell(q, "coll_object_remarks", "#coll_object_remarks#", 1)>
			<cfset t = QuerySetCell(q, "barcode", "#barcode#", 1)>
			<cfset t = QuerySetCell(q, "new_container_type", "#new_container_type#", 1)>
		</cftransaction>
		<cfcatch>
			<cfset q=queryNew("status,msg")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "status", "error", 1)>
			<cfset t = QuerySetCell(q, "msg", "#cfcatch.message# #cfcatch.detail#:: #ccid.nv#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn q>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getLoanPartResults" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfoutput>
	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select
			cataloged_item.COLLECTION_OBJECT_ID,
			specimen_part.collection_object_id partID,
			coll_object.COLL_OBJ_DISPOSITION,
			coll_object.LOT_COUNT,
			coll_object.CONDITION,
			specimen_part.PART_NAME,
			specimen_part.PRESERVE_METHOD,
			specimen_part.SAMPLED_FROM_OBJ_ID,
			concatEncumbrances(cataloged_item.collection_object_id) as encumbrance_action,
			loan_item.transaction_id,
			nvl(p1.barcode,'NOBARCODE') barcode
		from
			#session.SpecSrchTab#,
			cataloged_item,
			coll_object,
			specimen_part,
			(select * from loan_item where transaction_id = #transaction_id#) loan_item,
			coll_obj_cont_hist,
			container p0,
			container p1
		where
			#session.SpecSrchTab#.collection_object_id = cataloged_item.collection_object_id AND
			cataloged_item.collection_object_id = specimen_part.derived_from_cat_item AND
			specimen_part.collection_object_id = coll_object.collection_object_id and
			specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id (+) and
			coll_obj_cont_hist.container_id=p0.container_id (+) and
			p0.parent_container_id=p1.container_id (+) and
			specimen_part.SAMPLED_FROM_OBJ_ID is null and
			specimen_part.collection_object_id = loan_item.collection_object_id (+)
		order by
			cataloged_item.collection_object_id, specimen_part.part_name, specimen_part.collection_object_id
	</cfquery>
	<cfreturn result>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getDeaccPartResults" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfoutput>
	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select
			cataloged_item.COLLECTION_OBJECT_ID,
			specimen_part.collection_object_id partID,
			coll_object.COLL_OBJ_DISPOSITION,
			coll_object.LOT_COUNT,
			coll_object.CONDITION,
			specimen_part.PART_NAME,
			specimen_part.PRESERVE_METHOD,
			specimen_part.SAMPLED_FROM_OBJ_ID,
			concatEncumbrances(cataloged_item.collection_object_id) as encumbrance_action,
			deacc_item.transaction_id,
			nvl(p1.barcode,'NOBARCODE') barcode
		from
			#session.SpecSrchTab#,
			cataloged_item,
			coll_object,
			specimen_part,
			(select * from deacc_item where transaction_id = #transaction_id#) deacc_item,
			coll_obj_cont_hist,
			container p0,
			container p1
		where
			#session.SpecSrchTab#.collection_object_id = cataloged_item.collection_object_id AND
			cataloged_item.collection_object_id = specimen_part.derived_from_cat_item AND
			specimen_part.collection_object_id = coll_object.collection_object_id and
			specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id (+) and
			coll_obj_cont_hist.container_id=p0.container_id (+) and
			p0.parent_container_id=p1.container_id (+) and
			specimen_part.collection_object_id = deacc_item.collection_object_id (+)
		order by
			cataloged_item.collection_object_id, specimen_part.part_name
	</cfquery>
	<cfreturn result>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="ssvar" access="remote">
	<cfargument name="startrow" type="numeric" required="yes">
	<cfargument name="maxrows" type="numeric" required="yes">
	<cfset session.maxrows=#maxrows#>
	<cfset session.startrow=#startrow#>
	<cfset result="ok">
	<cfreturn result>
</cffunction>
<!-------------------------------------------------------------------------------------------->
<cffunction name="addPartToLoan" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="partID" type="numeric" required="yes">
	<cfargument name="remark" type="string" required="yes">
	<cfargument name="instructions" type="string" required="yes">
	<cfargument name="subsample" type="numeric" required="yes">
	<cfoutput>
	<cftransaction>
		<cftry>
			<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select sq_collection_object_id.nextval n from dual
			</cfquery>
			<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select cataloged_item.collection_object_id,
				cat_num,collection,part_name, preserve_method
				from
				cataloged_item,
				collection,
				specimen_part
				where
				cataloged_item.collection_id=collection.collection_id and
				cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
				specimen_part.collection_object_id=#partID#
			</cfquery>
			<cfif #subsample# is 1>
			<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					coll_obj_disposition,
					condition,
					part_name,
					preserve_method,
					derived_from_cat_item
				FROM
					coll_object, specimen_part
				WHERE
					coll_object.collection_object_id = specimen_part.collection_object_id AND
					coll_object.collection_object_id = #partID#
			</cfquery>
			<cfquery name="newCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO coll_object (
					COLLECTION_OBJECT_ID,
					COLL_OBJECT_TYPE,
					ENTERED_PERSON_ID,
					COLL_OBJECT_ENTERED_DATE,
					LAST_EDITED_PERSON_ID,
					LAST_EDIT_DATE,
					COLL_OBJ_DISPOSITION,
					LOT_COUNT,
					CONDITION)
				VALUES
					(#n.n#,
					'SS',
					#session.myAgentId#,
					sysdate,
					#session.myAgentId#,
					sysdate,
					'#parentData.coll_obj_disposition#',
					1,
					'#parentData.condition#')
			</cfquery>
			<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO specimen_part (
					COLLECTION_OBJECT_ID
					,PART_NAME
					,PRESERVE_METHOD
					,SAMPLED_FROM_OBJ_ID
					,DERIVED_FROM_CAT_ITEM)
				VALUES (
					#n.n#
					,'#parentData.part_name#'
					,'#parentData.preserve_method#'
					,#partID#
					,#parentData.derived_from_cat_item#)
			</cfquery>
		</cfif>
		<cfquery name="addLoanItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO loan_item (
				TRANSACTION_ID,
				COLLECTION_OBJECT_ID,
				RECONCILED_BY_PERSON_ID,
				RECONCILED_DATE
				,ITEM_DESCR
				<cfif len(#instructions#) gt 0>
					,ITEM_INSTRUCTIONS
				</cfif>
				<cfif len(#remark#) gt 0>
					,LOAN_ITEM_REMARKS
				</cfif>
				       )
			VALUES (
				#TRANSACTION_ID#,
				<cfif #subsample# is 1>
					#n.n#,
				<cfelse>
					#partID#,
				</cfif>
				#session.myagentid#,
				sysdate
				,'#meta.collection# #meta.cat_num# #meta.part_name#(#meta.preserve_method#)'
				<cfif len(#instructions#) gt 0>
					,'#instructions#'
				</cfif>
				<cfif len(#remark#) gt 0>
					,'#remark#'
				</cfif>
				)
		</cfquery>
		<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE coll_object SET coll_obj_disposition = 'on loan'
			where collection_object_id =
		<cfif #subsample# is 1>
				#n.n#
			<cfelse>
				#partID#
			</cfif>
		</cfquery>
	<cfcatch>
		<cfset result = "0|#cfcatch.message# #cfcatch.detail#">
		<cfreturn result>
	</cfcatch>
	</cftry>
	<cfreturn "1|#partID#">
	</cftransaction>
	</cfoutput>
</cffunction>

<!-------------------------------------------------------------------------------------------->
<cffunction name="addPartToDeacc" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="partID" type="numeric" required="yes">
	<cfargument name="remark" type="string" required="yes">
	<cfargument name="instructions" type="string" required="yes">
	<cfargument name="subsample" type="numeric" required="yes">
	<cfoutput>
	<cftransaction>
		<cftry>
			<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select sq_collection_object_id.nextval n from dual
			</cfquery>
			<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select cataloged_item.collection_object_id,
				cat_num,collection,part_name, preserve_method
				from
				cataloged_item,
				collection,
				specimen_part
				where
				cataloged_item.collection_id=collection.collection_id and
				cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
				specimen_part.collection_object_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
			</cfquery>
			<cfif #subsample# is 1>
			<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					coll_obj_disposition,
					condition,
					part_name,
					preserve_method,
					derived_from_cat_item
				FROM
					coll_object, specimen_part
				WHERE
					coll_object.collection_object_id = specimen_part.collection_object_id AND
					coll_object.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
			</cfquery>
			<cfquery name="newCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO coll_object (
					COLLECTION_OBJECT_ID,
					COLL_OBJECT_TYPE,
					ENTERED_PERSON_ID,
					COLL_OBJECT_ENTERED_DATE,
					LAST_EDITED_PERSON_ID,
					LAST_EDIT_DATE,
					COLL_OBJ_DISPOSITION,
					LOT_COUNT,
					CONDITION)
				VALUES
					(
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#n.n#">,
					'SS',
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
					sysdate,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
					sysdate,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.coll_obj_disposition#">,
					1,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.condition#">)
			</cfquery>
			<cfquery name="decrementParentLotCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE coll_object set LOT_COUNT = LOT_COUNT -1,
					LAST_EDITED_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
					LAST_EDIT_DATE = sysdate
				where COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
					and LOT_COUNT > 1
			</cfquery>
			<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO specimen_part (
					COLLECTION_OBJECT_ID
					,PART_NAME
					,PRESERVE_METHOD
					,SAMPLED_FROM_OBJ_ID
					,DERIVED_FROM_CAT_ITEM)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#n.n#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.part_name#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.preserve_method#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parentData.derived_from_cat_item#">)
			</cfquery>
			<cfquery name="newRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO coll_object_remark (
					COLLECTION_OBJECT_ID,
 					COLL_OBJECT_REMARKS )
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#n.n#">,
					'Deaccessioned Subsample')
			</cfquery>
		</cfif>
		<cfquery name="addDeaccItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO DEACC_ITEM (
				TRANSACTION_ID,
				COLLECTION_OBJECT_ID,
				RECONCILED_BY_PERSON_ID,
				RECONCILED_DATE
				,ITEM_DESCR
				<cfif len(#instructions#) gt 0>
					,ITEM_INSTRUCTIONS
				</cfif>
				<cfif len(#remark#) gt 0>
					,DEACC_ITEM_REMARKS
				</cfif>
				       )
			VALUES (
				#TRANSACTION_ID#,
				<cfif #subsample# is 1>
					#n.n#,
				<cfelse>
					#partID#,
				</cfif>
				#session.myagentid#,
				sysdate
				,'#meta.collection# #meta.cat_num# #meta.part_name#(#meta.preserve_method#)'
				<cfif len(#instructions#) gt 0>
					,'#instructions#'
				</cfif>
				<cfif len(#remark#) gt 0>
					,'#remark#'
				</cfif>
				)
		</cfquery>

               <cfquery name="getDeaccType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                       select deacc_type from deaccession where transaction_id = #TRANSACTION_ID#
               </cfquery>

               <cfset partDisp = getDeaccType.deacc_type>

               <cfif partDisp eq "exchange">
                       <cfset partDisp = "exchanged">
               </cfif>

		<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                       UPDATE coll_object SET coll_obj_disposition = 'deaccessioned - ' || '#partDisp#'
			where collection_object_id =
		<cfif #subsample# is 1>
				#n.n#
			<cfelse>
				#partID#
			</cfif>
		</cfquery>
	<cfcatch>
		<cfset result = "0|#cfcatch.message# #cfcatch.detail#">
		<cfreturn result>
	</cfcatch>
	</cftry>
	<cfreturn "1|#partID#">
	</cftransaction>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getMedia" access="remote">
	<cfargument name="idList" type="string" required="yes">
	<cfset theResult=queryNew("media_id,collection_object_id,media_relationship")>
	<cfset r=1>
	<cfset tableList="cataloged_item,collecting_event">
	<cftry>
	        <cfset threadname = "getMediaThread">
	        <cfthread name="#threadname#" >
		   <cfloop list="#idList#" index="cid">
			<cfloop list="#tableList#" index="tabl">
				<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select MCZBASE.getMediaBySpecimen('#tabl#',#cid#) midList from dual
				</cfquery>
				<cfif len(mid.midList) gt 0>
					<cfset t = queryaddrow(theResult,1)>
					<cfset t = QuerySetCell(theResult, "collection_object_id", "#cid#", r)>
					<cfset t = QuerySetCell(theResult, "media_id", "#mid.midList#", r)>
					<cfset t = QuerySetCell(theResult, "media_relationship", "#tabl#", r)>
					<cfset r=r+1>
				</cfif>
			</cfloop>
		   </cfloop>
	        </cfthread>
        	<cfthread action="join" name="#threadname#" />
	<cfcatch>
		<cfset craps=queryNew("media_id,collection_object_id,media_relationship")>
		<cfset temp = queryaddrow(craps,1)>
		<cfset t = QuerySetCell(craps, "collection_object_id", "12", 1)>
		<cfset t = QuerySetCell(craps, "media_id", "45", 1)>
		<cfset t = QuerySetCell(craps, "media_relationship", "#cfcatch.message# #cfcatch.detail#", 1)>
		<cfreturn craps>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!---  Given a list of collection object ids, return a result object consisting of collection object id values with
       corresponding type status values (along with counts) for that collection object in a typeList variable.  In
       the event of an error return a result object with one row where the collection object id has the value -1 and
       the typeList contains an error message.
--->
<cffunction name="getTypes" access="remote">
	<cfargument name="idList" type="string" required="yes">
	<cfset theResult=queryNew("collection_object_id,typeList")>
	<cfset r=1>
	<cftry>
	        <cfset threadname = "getTypesThread">
	        <cfthread name="#threadname#" >
		   <cfloop list="#idList#" index="cid">
			<cfquery name="ts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT type_status || decode(count(*),1,'','(' || count(*) || ')') type_status
				FROM citation
				WHERE collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#cid#">
				GROUP BY type_status
			</cfquery>
			<cfif ts.recordcount gt 0>
				<cfset tl="">
				<cfloop query="ts">
					<cfset tl=listappend(tl,ts.type_status,";")>
				</cfloop>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "collection_object_id", "#cid#", r)>
				<cfset t = QuerySetCell(theResult, "typeList", "#tl#", r)>
				<cfset r=r+1>
			</cfif>
		   </cfloop>
	        </cfthread>
        	<cfthread action="join" name="#threadname#" />
	<cfcatch>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "collection_object_id", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "typeList", "#cfcatch.detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!--- Create an html form for entering a new permit and linking it to a transaction or shipment.
      @param related_id the transaction or shipment ID to link the new permit to.
      @param related_label a human readable description of the transaction or shipment to link the new permit to.
      @param relation_type 'transaction' to relate the new permit to a transaction, 'shipment' to relate to a shipment.
      @return an html form suitable for placement as the content of a jquery-ui dialog to create the new permit.

      @see createNewPermitForTrans
--->
<cffunction name="getNewPermitForTransHtml" access="remote" returntype="string">
    <cfargument name="related_id" type="string" required="yes">
    <cfargument name="related_label" type="string" required="yes">
    <cfargument name="relation_type" type="string" required="yes">

    <cfset result = "">

   <cftry>
     <cfif relation_type EQ "transaction">
         <cfset transaction_id = related_id>
     <cfelse>
         <cfset shipment_id = related_id>
     </cfif>

    <cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select ct.specific_type, ct.permit_type, count(p.permit_id) uses from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
        group by ct.specific_type, ct.permit_type
        order by ct.specific_type
    </cfquery>
    <cfset result = result & "<h2>Create New Permissions &amp; Rights Document</h2>
    <p>Enter a new record for a permit or similar document related to permissions and rights (access benefit sharing agreements,
       material transfer agreements, collecting permits, salvage permits, etc.)  This record will be linked to #related_label#</p>
	<cfoutput>
	<form id='newPermitForm' onsubmit='addnewpermit'>
   	    <input type='hidden' name='method' value='createNewPermitForTrans'>
    	<input type='hidden' name='returnformat' value='plain'>
    	<input type='hidden' name='related_id' value='#related_id#'>
    	<input type='hidden' name='related_label' value='#related_label#'>
    	<input type='hidden' name='relation_type' value='#relation_type#'>
	<table>
		<tr>
			<td>Issued By</td>
			<td colspan='3'>
			<input type='hidden' name='IssuedByAgentId'>
			<input type='text' name='IssuedByAgent' class='reqdClr' size='50' required='yes'
		 	  onchange=""getAgent('IssuedByAgentId','IssuedByAgent','newPermitForm',this.value); return false;""
			  onKeyUp='return noenter();'>


		    </td>
		</tr>
			<tr>
			<td>Issued To</td>
			<td colspan='3'>
			<input type='hidden' name='IssuedToAgentId'>
			<input type='text' name='IssuedToAgent' class='reqdClr' size='50' required='yes'
			  onchange=""getAgent('IssuedToAgentId','IssuedToAgent','newPermitForm',this.value); return false;""
			  onKeyUp='return noenter();'>
		    </td>
		</tr>
		<tr>
			<td>Contact Person</td>
			<td colspan='3'>
			<input type='hidden' name='contact_agent_id'>
			<input type='text' name='ContactAgent' size='50'
		 		onchange=""getAgent('contact_agent_id','ContactAgent','newPermitForm',this.value); return false;""
			  	onKeyUp='return noenter();'>


		    </td>
		</tr>
		<tr>
			<td>Issued Date</td>
			<td><input type='text' name='issued_Date'></td>
			<td>Renewed Date</td>
			<td><input type='text' name='renewed_Date'></td>
		</tr>
		<tr>
			<td>Expiration Date</td>
			<td><input type='text' name='exp_Date'></td>
			<td>Permit Number</td>
			<td><input type='text' name='permit_Num'></td>
		</tr>
		<tr>
			<td>Specific Document Type</td>
			<td colspan=3>
				<select name='specific_type' id='specific_type' size='1' class='reqdClr' required='yes' >
					<option value=''></option>">
					<cfloop query="ctSpecificPermitType">
                        <cfset result = result & " <option value = '#ctSpecificPermitType.specific_type#'>#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.permit_type#)</option>">
					</cfloop>
                    <cfset result = result & "
				</select>">
                   <cfif isdefined("session.roles") and listfindnocase(session.roles,"admin_permits")>
                        <cfset result = result & "
                       <button id='addSpecificTypeButton' onclick='openAddSpecificTypeDialog(); event.preventDefault();'>+</button>
                       <div id='newPermitASTDialog'></div> ">
                   </cfif>
            <cfset result = result & "
			</td>
		</tr>
		<tr>
			<td>Document Title</td>
			<td><input type='text' name='permit_title' style='width: 26em;' ></td>
			<td>Remarks</td>
			<td><input type='text' name='permit_remarks' style='width: 26em;' ></td>
		</tr>
		<tr>
			<td>Summary of Restrictions on use</td>
			<td colspan='3'><textarea cols='80' rows='3' name='restriction_summary'></textarea></td>
		</tr>
		<tr>
			<td>Summary of Agreed Benefits: All users</td>
			<td colspan='3'><textarea cols='80' rows='3' name='benefits_summary'></textarea></td>
		</tr>
		<tr>
			<td>Summary of Agreed Benefits: Harvard only</td>
			<td colspan='3'><textarea cols='80' rows='3' name='internal_benefits_summary'></textarea></td>
		</tr>
		<tr>
			<td>Benefits Provided</td>
			<td colspan='3'><textarea cols='80' rows='3' name='benefits_provided'></textarea></td>
		</tr>
	</table>
    <script language='javascript' type='text/javascript'>
        function addnewpermit(event) {
           event.preventDefault();
           return false;
        };
        </script>
    </form>
    <div id='permitAddResults'></div>
">
    <cfcatch>
		<cfset result = "Error: #cfcatch.Message# #cfcatch.Detail#">
    </cfcatch>
    </cftry>
    <cfreturn result >
</cffunction>
<!--------------------------------------------------------------------------------------------------->
<!--- Given information about a new permissions/rights document record, create that record, and
      link it to a provided transaction or shipment.

      @param related_id the transaction_id or shipment_id to link the new permit to.
      @param related_label a human readable descriptor of the transaction or shipment to link to.
      @param relation_type the value "tranasction" to link the new permit to a transaction, "shipment"
            to link it to a shipment.

      @see getNewPermitForTransHtml
--->
<cffunction name="createNewPermitForTrans" returntype="string" access="remote">
    <cfargument name="related_id" type="string" required="yes">
    <cfargument name="related_label" type="string" required="yes">
    <cfargument name="relation_type" type="string" required="yes">
    <cfargument name="specific_type" type="string" required="yes">
    <cfargument name="issuedByAgentId" type="string" required="yes">
    <cfargument name="issuedToAgentId" type="string" required="yes">
    <cfargument name="issued_date" type="string" required="no">
    <cfargument name="renewed_date" type="string" required="no">
    <cfargument name="exp_date" type="string" required="no">
    <cfargument name="permit_num" type="string" required="no">
    <cfargument name="permit_title" type="string" required="no">
    <cfargument name="permit_remarks" type="string" required="no">
    <cfargument name="restriction_summary" type="string" required="no">
    <cfargument name="benefits_summary" type="string" required="no">
    <cfargument name="internal_benefits_summary" type="string" required="no">
    <cfargument name="benefits_provided" type="string" required="no">
    <cfargument name="contact_agent_id" type="string" required="no">

    <cfset result = "">

    <cftransaction action="begin">
    <cftry>
        <cfif NOT isdefined('issued_date')><cfset issued_date=''></cfif>
        <cfif NOT isdefined('renewed_date')><cfset renewed_date=''></cfif>
        <cfif NOT isdefined('exp_date')><cfset exp_date=''></cfif>
        <cfif NOT isdefined('permit_num')><cfset permit_num=''></cfif>
        <cfif NOT isdefined('permit_title')><cfset permit_title=''></cfif>
        <cfif NOT isdefined('permit_remarks')><cfset permit_remarks=''></cfif>
        <cfif NOT isdefined('restriction_summary')><cfset restriction_summary=''></cfif>
        <cfif NOT isdefined('benefits_summary')><cfset benefits_summary=''></cfif>
        <cfif NOT isdefined('internal_benefits_summary')><cfset internal_benefits_summary=''></cfif>
        <cfif NOT isdefined('benefits_provided')><cfset benefits_provided=''></cfif>
        <cfif NOT isdefined('contact_agent_id')><cfset contact_agent_id=''></cfif>

        <cfif relation_type EQ "transaction">
             <cfset transaction_id = related_id>
         <cfelse>
             <cfset shipment_id = related_id>
         </cfif>

        <cfquery name="ptype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
           select permit_type from ctspecific_permit_type where specific_type = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
        </cfquery>
        <cfset permit_type = #ptype.permit_type#>
        <cfquery name="nextPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        	select sq_permit_id.nextval nextPermit from dual
        </cfquery>
        <cfif isdefined("specific_type") and len(#specific_type#) is 0 and ( not isdefined("permit_type") OR len(#permit_type#) is 0 )>
	        <cfthrow message="Error: There was an error selecting the permit type for the specific document type.  Please file a bug report.">
        </cfif>
		<cfquery name="newPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newPermitResult">
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
			 <cfif len(#internal_benefits_summary#) gt 0>
			 	,internal_benefits_summary
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
			 	,<cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(ISSUED_DATE,"yyyy-mm-dd")#">
			 </cfif>
			 , <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#IssuedToAgentId#">
			  <cfif len(#RENEWED_DATE#) gt 0>
			 	,<cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(RENEWED_DATE,"yyyy-mm-dd")#">
			 </cfif>
			 <cfif len(#EXP_DATE#) gt 0>
			 	,<cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(EXP_DATE,"yyyy-mm-dd")#">
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
			 <cfif len(#internal_benefits_summary#) gt 0>
			 	, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#internal_benefits_summary#">
		     </cfif>
			 <cfif len(#benefits_provided#) gt 0>
			 	, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_provided#">
		     </cfif>
			 <cfif len(#contact_agent_id#) gt 0>
			 	, <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#contact_agent_id#">
			 </cfif>)
		</cfquery>
        <cfif newPermitResult.recordcount eq 1>
            <cfset result = result & "<span>Created new Permissons/Rights record. ">
            <cfset result = result & "<a id='permitEditLink' href='/transactions/Permit.cfm?permit_id=#nextPermit.nextPermit#&action=edit' target='_blank'>Edit</a></span>">
            <cfset result = result & "<form><input type='hidden' value='#permit_num#' id='permit_number_passon'></form>">
            <cfset result = result & "<script>$('##permitEditLink).removeClass(ui-widget-content);'</script>">
        </cfif>
		<cfquery name="newPermitLink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newPermitLinkResult">
            <cfif relation_type EQ "transaction">
            INSERT into permit_trans (permit_id, transaction_id)
            <cfelse>
            INSERT into permit_shipment (permit_id, shipment_id)
            </cfif>
            VALUES
            (<cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#nextPermit.nextPermit#">,
            <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#related_id#">)
        </cfquery>
        <cfif newPermitLinkResult.recordcount eq 1>
            <cfset result = result & "Linked to #related_label#">
        </cfif>
        <cftransaction action="commit">
    <cfcatch>
		<cfset result = "Error: #cfcatch.Message# #cfcatch.Detail#">
        <cftransaction action="rollback">
    </cfcatch>
    </cftry>
    </cftransaction>
    <cfreturn result >
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="savePermitChanges" returntype="string" access="remote">
    <cfargument name="permit_id" type="string" required="yes">
    <cfargument name="specific_type" type="string" required="yes">
    <cfargument name="issuedByAgentId" type="string" required="yes">
    <cfargument name="issuedToAgentId" type="string" required="yes">
    <cfargument name="issued_date" type="string" required="no">
    <cfargument name="renewed_date" type="string" required="no">
    <cfargument name="exp_date" type="string" required="no">
    <cfargument name="permit_num" type="string" required="no">
    <cfargument name="permit_title" type="string" required="no">
    <cfargument name="permit_remarks" type="string" required="no">
    <cfargument name="restriction_summary" type="string" required="no">
    <cfargument name="benefits_summary" type="string" required="no">
    <cfargument name="internal_benefits_summary" type="string" required="no">
    <cfargument name="benefits_provided" type="string" required="no">
    <cfargument name="contact_agent_id" type="string" required="no">

    <cftransaction action="begin">
    <cftry>
        <cfif NOT isdefined('issued_date')><cfset issued_date=''></cfif>
        <cfif NOT isdefined('renewed_date')><cfset renewed_date=''></cfif>
        <cfif NOT isdefined('exp_date')><cfset exp_date=''></cfif>
        <cfif NOT isdefined('permit_num')><cfset permit_num=''></cfif>
        <cfif NOT isdefined('permit_title')><cfset permit_title=''></cfif>
        <cfif NOT isdefined('permit_remarks')><cfset permit_remarks=''></cfif>
        <cfif NOT isdefined('restriction_summary')><cfset restriction_summary=''></cfif>
        <cfif NOT isdefined('benefits_summary')><cfset benefits_summary=''></cfif>
        <cfif NOT isdefined('internal_benefits_summary')><cfset internal_benefits_summary=''></cfif>
        <cfif NOT isdefined('benefits_provided')><cfset benefits_provided=''></cfif>
        <cfif NOT isdefined('contact_agent_id')><cfset contact_agent_id=''></cfif>
		<cfquery name="ptype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		   select permit_type from ctspecific_permit_type where specific_type = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
		</cfquery>
		<cfset permit_type = #ptype.permit_type#>
		<cfquery name="updatePermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		UPDATE permit SET
			permit_id = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#permit_id#">
			<cfif len(#issuedByAgentId#) gt 0>
			 	,ISSUED_BY_AGENT_ID = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#issuedByAgentId#">
		    </cfif>
			 <cfif len(#ISSUED_DATE#) gt 0>
			 	,ISSUED_DATE = <cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(ISSUED_DATE,"yyyy-mm-dd")#">
			 </cfif>
			 <cfif len(#IssuedToAgentId#) gt 0>
			 	,ISSUED_TO_AGENT_ID = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#IssuedToAgentId#">
			 </cfif>
			 <cfif len(#RENEWED_DATE#) gt 0>
			 	,RENEWED_DATE = <cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#RENEWED_DATE#">
			 </cfif>
			 <cfif len(#EXP_DATE#) gt 0>
			 	,EXP_DATE = <cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#EXP_DATE#">
			 </cfif>
			 <cfif len(#PERMIT_NUM#) gt 0>
			 	,PERMIT_NUM = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#PERMIT_NUM#">
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
			<cfif len(#internal_benefits_summary#) gt 0>
			 	,internal_benefits_summary = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#internal_benefits_summary#">
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
          <cfif updatePermit.recordcount eq 1>
             <cfset result=queryNew("status, message")>
             <cfset t = queryaddrow(result,1)>
             <cfset t = QuerySetCell(result, "status", "1", 1)>
             <cfset t = QuerySetCell(result, "message", "Changes saved.", 1)>
            <cftransaction action="commit">
          <cfelse>
            <cfthrow message="No records modified.">
            <cftransaction action="rollback">
          </cfif>
       <cfcatch>
          <cfset result=queryNew("status, message")>
          <cfset t = queryaddrow(result,1)>
          <cfset t = QuerySetCell(result, "status", "-1", 1)>
          <cfset t = QuerySetCell(result, "message", "Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
       </cfcatch>
    </cftry>
    </cftransaction>
    <cfreturn result>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!---  Given a shipment_id, return a block of html code for a permit picking dialog to pick permits for the given
       shipment.
       @param shipment_id the transaction to which selected permits are to be related.
       @return html content for a permit picker dialog for transaction permits or an error message if an exception was raised.

       @see setShipmentForPermit
       @see findPermitShipSearchResults
--->
<cffunction name="shipmentPermitPickerHtml" returntype="string" access="remote">
    <cfargument name="shipment_id" type="string" required="yes">
    <cfargument name="shipment_label" type="string" required="yes">

    <cfset result = "">
    <cftry>
        <cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    	select ct.permit_type, count(p.permit_id) uses
        from ctpermit_type ct left join permit p on ct.permit_type = p.permit_type
        group by ct.permit_type
        order by ct.permit_type
        </cfquery>
        <cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select ct.specific_type, count(p.permit_id) uses
        from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
        group by ct.specific_type
        order by ct.specific_type
        </cfquery>
        <cfset result = result & "
   <h3>Search for Permissions &amp; Rights documents. Any part of dates and names accepted, case isn't important.</h3>
   <form id='findPermitForm' onsubmit='searchforpermits(event);'>
   	<input type='hidden' name='method' value='findPermitShipSearchResults'>
    	<input type='hidden' name='returnformat' value='plain'>
	<input type='hidden' name='shipment_id' value='#shipment_id#'>
	<input type='hidden' name='shipment_label' value='#shipment_label#'>
	<table>
		<tr>
			<td>Issued By</td>
			<td><input type='text' name='IssuedByAgent'></td>
			<td>Issued To</td>
			<td><input type='text' name='IssuedToAgent'></td>


		</tr>
		<tr>
			<td>Issued Date</td>
			<td><input type='text' name='issued_Date'></td>
			<td>Renewed Date</td>
			<td><input type='text' name='renewed_Date'></td>
		</tr>
		<tr>
			<td>Expiration Date</td>
			<td><input type='text' name='exp_Date'></td>
			<td>Permit Number</td>
			<td><input type='text' name='permit_Num' id='permit_Num'></td>
		</tr>
		<tr>
			<td>Permit Type</td>
			<td>
				<select name='permit_Type' size='1' style='width: 15em;'>
					<option value=''></option>">
					<cfloop query='ctPermitType'>
                        <cfset result = result & "<option value = '#ctPermitType.permit_type#'>#ctPermitType.permit_type# (#ctPermitType.uses#)</option>">
					</cfloop>
				    <cfset result = result & "
				</select>
			</td>
			<td>Remarks</td>
			<td><input type='text' name='permit_remarks'></td>
		</tr>
		<tr>
			<td>Specific Type</td>
			<td>
				<select name='specific_type' size='1' style='width: 15em;'>
					<option value=''></option> ">
					<cfloop query='ctSpecificPermitType'>
						<cfset result = result & "<option value = '#ctSpecificPermitType.specific_type#'>#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>" >
					</cfloop>
				    <cfset result = result & "
				</select>
			</td>
			<td>Permit Title</td>
			<td><input type='text' name='permit_title'></td>
		</tr>
		<tr>
			<td></td>
			<td>
			    <input type='submit' value='Search' class='schBtn'>
			</td>
			<td>
                <script>
                   function createPermitDialogDone () {
                       $('##permit_Num').val($('##permit_number_passon').val());
                   };
                </script>
                <span id='createPermit_#shipment_id#_span'><input type='button' style='margin-left: 30px;' value='New Permit' class='lnkBtn' onClick='opencreatepermitdialog(""createPermitDlg_#shipment_id#"",""#shipment_label#"", #shipment_id#, ""shipment"", createPermitDialogDone);' ></span><div id='createPermitDlg_#shipment_id#'></div>

			</td>
			<td>
   			    <input type='reset' value='Clear' class='clrBtn'>
			</td>
		</tr>
	</table>
	</form>
    <script language='javascript' type='text/javascript'>
        function searchforpermits(event) {
           event.preventDefault();
           // to debug ajax call on component getting entire page redirected to blank page uncomment to create submission
           // alert($('##findPermitForm').serialize());
           jQuery.ajax({
             url: '/component/functions.cfc',
             type: 'post',
             data: $('##findPermitForm').serialize(),
             success: function (data) {
                 $('##permitSearchResults').html(data);
             },
             fail: function (jqXHR, textStatus) {
                 $('##permitSearchResults').html('Error:' + textStatus);
             }
           });
           return false;
        };
        </script>
    <div id='permitSearchResults'></div>
    ">
    <cfcatch>
		<cfset result = "Error: #cfcatch.Message# #cfcatch.Detail#">
    </cfcatch>
    </cftry>
    <cfreturn result >
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!--- Given a shipment_id and a list of permit search criteria return an html list of permits matching the
      search criteria, along with controls allowing selected permits to be linked to the specified shipment.

      @see shipmentPermitPickerHtml
      @see setShipmentForPermit
--->
<cffunction name="findPermitShipSearchResults" access="remote" returntype="string">
    <cfargument name="shipment_id" type="string" required="yes">
    <cfargument name="shipment_label" type="string" required="yes">
	<cfargument name="IssuedByAgent" type="string" required="no">
	<cfargument name="IssuedToAgent" type="string" required="no">
	<cfargument name="issued_Date" type="string" required="no">
	<cfargument name="renewed_Date" type="string" required="no">
	<cfargument name="exp_Date" type="string" required="no">
	<cfargument name="permit_Num" type="string" required="no">
	<cfargument name="specific_type" type="string" required="no">
	<cfargument name="permit_Type" type="string" required="no">
	<cfargument name="permit_title" type="string" required="no">
	<cfargument name="permit_remarks" type="string" required="no">
    <cfset result = "">
    <cftry>
        <cfif NOT isdefined('IssuedByAgent')><cfset IssuedByAgent=''></cfif>
        <cfif NOT isdefined('IssuedToAgent')><cfset IssuedToAgent=''></cfif>
        <cfif NOT isdefined('issued_Date')><cfset issued_Date=''></cfif>
        <cfif NOT isdefined('renewed_Date')><cfset renewed_Date=''></cfif>
        <cfif NOT isdefined('exp_Date')><cfset exp_Date=''></cfif>
        <cfif NOT isdefined('permit_Num')><cfset permit_Num=''></cfif>
        <cfif NOT isdefined('specific_type')><cfset specific_type=''></cfif>
        <cfif NOT isdefined('permit_Type')><cfset permit_Type=''></cfif>
        <cfif NOT isdefined('permit_title')><cfset permit_title=''></cfif>
        <cfif NOT isdefined('permit_remarks')><cfset permit_remarks=''></cfif>
        <cfif len(IssuedByAgent) EQ 0 AND len(IssuedToAgent) EQ 0 AND len(issued_Date) EQ 0 AND
              len(renewed_Date) EQ 0 AND len(exp_Date) EQ 0 AND len(permit_Num) EQ 0 AND
              len(specific_type) EQ 0 AND len(permit_Type) EQ 0 AND len(permit_title) EQ 0 AND
              len(permit_remarks) EQ 0 >
            <cfthrow type="noQueryParameters" message="No search criteria provided." >
        </cfif>

    <cfquery name="matchPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    select distinct permit.permit_id,
	    issuedByPref.agent_name IssuedByAgent,
    	issuedToPref.agent_name IssuedToAgent,
	    issued_Date,
	    renewed_Date,
    	exp_Date,
	    permit_Num,
    	permit_Type,
	    permit_title,
    	specific_type,
	    permit_remarks,
            (select count(*) from permit_shipment
		where permit_shipment.permit_id = permit.permit_id
		and permit_shipment.shipment_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#shipment_id#'>
	    ) as linkcount
    from
	    permit
    	left join preferred_agent_name issuedToPref on permit.issued_to_agent_id = issuedToPref.agent_id
	    left join preferred_agent_name issuedByPref on permit.issued_by_agent_id = issuedByPref.agent_id
    	left join agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
 	    left join agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
            left join permit_trans on permit.permit_id = permit_trans.permit_id
    where
        permit.permit_id is not null
		<cfif len(#IssuedByAgent#) gt 0>
			 AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(IssuedByAgent)#%'>
		</cfif>
		<cfif len(#IssuedToAgent#) gt 0>
			 AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(IssuedToAgent)#%'>
		</cfif>
		<cfif len(#issued_Date#) gt 0>
			 AND upper(issued_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(issued_Date)#%'>
		</cfif>
		<cfif len(#renewed_Date#) gt 0>
			 AND upper(renewed_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(renewed_Date)#%'>
		</cfif>
		<cfif len(#exp_Date#) gt 0>
			 AND upper(exp_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(exp_Date)#%'>
		</cfif>
		<cfif len(#permit_Num#) gt 0>
			 AND permit_Num = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#permit_Num#'>
		</cfif>
		<cfif len(#specific_type#) gt 0>
			 AND specific_type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#specific_type#'>
		</cfif>
		<cfif len(#permit_Type#) gt 0>
			 AND permit_Type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#permit_Type#'>
		</cfif>
		<cfif len(#permit_title#) gt 0>
			 AND upper(permit_title) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(permit_title)#%'>
		</cfif>
		<cfif len(#permit_remarks#) gt 0>
			 AND upper(permit_remarks) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(permit_remarks)#%'>
		</cfif>
    ORDER BY permit_id
    </cfquery>
    <cfset i=1>
    <cfset result = result & "<h2>Find permits to link to #shipment_label#</h2>">
    <cfloop query="matchPermit" >
        <cfset result = result & "<hr><div">
        <cfif (i MOD 2) EQ 0>
             <cfset result = result & "class='evenRow'">
        <cfelse>
             <cfset result = result & "class='oddRow'">
        </cfif>
        <cfset result = result & " >">
        <cfset result = result & "
    	<form id='pp_#permit_id#_#shipment_id#_#i#' >
	        Permit Number #matchPermit.permit_Num# (#matchPermit.permit_Type#:#matchPermit.specific_type#)
            issued to #matchPermit.IssuedToAgent# by #matchPermit.IssuedByAgent# on #dateformat(matchPermit.issued_Date,'yyyy-mm-dd')# ">
            <cfif len(#matchPermit.renewed_Date#) gt 0><cfset result = result & " (renewed #dateformat(matchPermit.renewed_Date,'yyyy-mm-dd')#)"></cfif>
            <cfset result = result & ". Expires #dateformat(matchPermit.exp_Date,'yyyy-mm-dd')#.  ">
            <cfif len(#matchPermit.permit_remarks#) gt 0><cfset result = result & "Remarks: #matchPermit.permit_remarks# "></cfif>
            <cfset result = result & " (ID## #matchPermit.permit_id#) #matchPermit.permit_title#
            <div id='pickResponse#shipment_id#_#i#'>">
                <cfif matchPermit.linkcount GT 0>
            		<cfset result = result & " This Permit is already linked to #shipment_label# ">
                <cfelse>
			<cfset result = result & "
                <input type='button' class='picBtn'
                onclick='linkpermittoship(#matchPermit.permit_id#,#shipment_id#,""#shipment_label#"",""pickResponse#shipment_id#_#i#"");' value='Add this permit'>
			">
		</cfif>
		<cfset result = result & "
            </div>
    	</form>
        <script language='javascript' type='text/javascript'>
        $('##pp_#permit_id#_#shipment_id#_#i#').removeClass('ui-widget-content');
        function linkpermittoship(permit_id, shipment_id, shipment_label, div_id) {
          jQuery.ajax({
             url: '/component/functions.cfc',
             type: 'post',
             data: {
                method: 'setShipmentForPermit',
                permit_id: permit_id,
                shipment_id: shipment_id,
		returnformat: 'json',
		queryformat: 'column'
            },
            success: function (data) {
		var dataobj = JSON.parse(data)
                $('##'+div_id).html(dataobj.DATA.MESSAGE);
            },
            fail: function (jqXHR, textStatus) {
                $('##'+div_id).html('Error:' + textStatus);
            }
          });
        };
        </script>
        </div>">
        <cfset i=i+1>
    </cfloop>

    <cfcatch>
		<cfset result = "Error: #cfcatch.Message# #cfcatch.Detail#">
    </cfcatch>
    </cftry>
    <cfreturn result>
</cffunction>


<!----------------------------------------------------------------------------------------------------------------->
<!---  Given a transaction_id, return a block of html code for a permit picking dialog to pick permits for the given
       transaction.
       @param transaction_id the transaction to which selected permits are to be related.
       @return html content for a permit picker dialog for transaction permits or an error message if an exception was raised.

       @see linkPermitToTrans
       @see findPermitSearchResults
--->
<cffunction name="transPermitPickerHtml" returntype="string" access="remote">
    <cfargument name="transaction_id" type="string" required="yes">
    <cfargument name="transaction_label" type="string" required="yes">

    <cfset result = "">
    <cftry>
        <cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    	select ct.permit_type, count(p.permit_id) uses
        from ctpermit_type ct left join permit p on ct.permit_type = p.permit_type
        group by ct.permit_type
        order by ct.permit_type
        </cfquery>
        <cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select ct.specific_type, count(p.permit_id) uses
        from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
        group by ct.specific_type
        order by ct.specific_type
        </cfquery>
        <cfset result = result & "
   <h3>Search for Permissions &amp; Rights documents. Any part of dates and names accepted, case isn't important.</h3>
   <form id='findPermitForm' onsubmit='searchforpermits(event);'>
   	<input type='hidden' name='method' value='findPermitSearchResults'>
    	<input type='hidden' name='returnformat' value='plain'>
	<input type='hidden' name='transaction_id' value='#transaction_id#'>
	<input type='hidden' name='transaction_label' value='#transaction_label#'>
	<table>
		<tr>
			<td>Issued By</td>
			<td><input type='text' name='IssuedByAgent'></td>
			<td>Issued To</td>
			<td><input type='text' name='IssuedToAgent'></td>


		</tr>
		<tr>
			<td>Issued Date</td>
			<td><input type='text' name='issued_Date'></td>
			<td>Renewed Date</td>
			<td><input type='text' name='renewed_Date'></td>
		</tr>
		<tr>
			<td>Expiration Date</td>
			<td><input type='text' name='exp_Date'></td>
			<td>Permit Number</td>
			<td><input type='text' name='permit_Num' id='permit_Num'></td>
		</tr>
		<tr>
			<td>Permit Type</td>
			<td>
				<select name='permit_Type' size='1' style='width: 15em;'>
					<option value=''></option>">
					<cfloop query='ctPermitType'>
                        <cfset result = result & "<option value = '#ctPermitType.permit_type#'>#ctPermitType.permit_type# (#ctPermitType.uses#)</option>">
					</cfloop>
				    <cfset result = result & "
				</select>
			</td>
			<td>Remarks</td>
			<td><input type='text' name='permit_remarks'></td>
		</tr>
		<tr>
			<td>Specific Type</td>
			<td>
				<select name='specific_type' size='1' style='width: 15em;'>
					<option value=''></option> ">
					<cfloop query='ctSpecificPermitType'>
						<cfset result = result & "<option value = '#ctSpecificPermitType.specific_type#'>#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>" >
					</cfloop>
				    <cfset result = result & "
				</select>
			</td>
			<td>Permit Title</td>
			<td><input type='text' name='permit_title'></td>
		</tr>
		<tr>
			<td></td>
			<td>
			    <input type='submit' value='Search' class='schBtn'>
			</td>
			<td>
                <script>
                   function createPermitDialogDone () {
                       $('##permit_Num').val($('##permit_number_passon').val());
                   };
                </script>
                <span id='createPermit_#transaction_id#_span'><input type='button' style='margin-left: 30px;' value='New Permit' class='lnkBtn' onClick='opencreatepermitdialog(""createPermitDlg_#transaction_id#"",""#transaction_label#"", #transaction_id#, ""transaction"", createPermitDialogDone);' ></span><div id='createPermitDlg_#transaction_id#'></div>

			</td>
			<td>
   			    <input type='reset' value='Clear' class='clrBtn'>
			</td>
		</tr>
	</table>
	</form>
    <script language='javascript' type='text/javascript'>
        function searchforpermits(event) {
           event.preventDefault();
           // to debug ajax call on component getting entire page redirected to blank page uncomment to create submission
           // alert($('##findPermitForm').serialize());
           jQuery.ajax({
             url: '/component/functions.cfc',
             type: 'post',
             data: $('##findPermitForm').serialize(),
             success: function (data) {
                 $('##permitSearchResults').html(data);
             },
             fail: function (jqXHR, textStatus) {
                 $('##permitSearchResults').html('Error:' + textStatus);
             }
           });
           return false;
        };
        </script>
    <div id='permitSearchResults'></div>
    ">
    <cfcatch>
		<cfset result = "Error: #cfcatch.Message# #cfcatch.Detail#">
    </cfcatch>
    </cftry>
    <cfreturn result >
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!--- Given a transaction_id and a list of permit search criteria return an html list of permits matching the
      search criteria, along with controls allowing selected permits to be linked to the specified transaction.

      @see transPermitPickerHtml
      @see linkPermitToTrans
--->
<cffunction name="findPermitSearchResults" access="remote" returntype="string">
    <cfargument name="transaction_id" type="string" required="yes">
    <cfargument name="transaction_label" type="string" required="yes">
	<cfargument name="IssuedByAgent" type="string" required="no">
	<cfargument name="IssuedToAgent" type="string" required="no">
	<cfargument name="issued_Date" type="string" required="no">
	<cfargument name="renewed_Date" type="string" required="no">
	<cfargument name="exp_Date" type="string" required="no">
	<cfargument name="permit_Num" type="string" required="no">
	<cfargument name="specific_type" type="string" required="no">
	<cfargument name="permit_Type" type="string" required="no">
	<cfargument name="permit_title" type="string" required="no">
	<cfargument name="permit_remarks" type="string" required="no">
    <cfset result = "">
    <cftry>
        <cfif NOT isdefined('IssuedByAgent')><cfset IssuedByAgent=''></cfif>
        <cfif NOT isdefined('IssuedToAgent')><cfset IssuedToAgent=''></cfif>
        <cfif NOT isdefined('issued_Date')><cfset issued_Date=''></cfif>
        <cfif NOT isdefined('renewed_Date')><cfset renewed_Date=''></cfif>
        <cfif NOT isdefined('exp_Date')><cfset exp_Date=''></cfif>
        <cfif NOT isdefined('permit_Num')><cfset permit_Num=''></cfif>
        <cfif NOT isdefined('specific_type')><cfset specific_type=''></cfif>
        <cfif NOT isdefined('permit_Type')><cfset permit_Type=''></cfif>
        <cfif NOT isdefined('permit_title')><cfset permit_title=''></cfif>
        <cfif NOT isdefined('permit_remarks')><cfset permit_remarks=''></cfif>
        <cfif len(IssuedByAgent) EQ 0 AND len(IssuedToAgent) EQ 0 AND len(issued_Date) EQ 0 AND
              len(renewed_Date) EQ 0 AND len(exp_Date) EQ 0 AND len(permit_Num) EQ 0 AND
              len(specific_type) EQ 0 AND len(permit_Type) EQ 0 AND len(permit_title) EQ 0 AND
              len(permit_remarks) EQ 0 >
            <cfthrow type="noQueryParameters" message="No search criteria provided." >
        </cfif>

    <cfquery name="matchPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    select distinct permit.permit_id,
	    issuedByPref.agent_name IssuedByAgent,
    	issuedToPref.agent_name IssuedToAgent,
	    issued_Date,
	    renewed_Date,
    	exp_Date,
	    permit_Num,
    	permit_Type,
	    permit_title,
    	specific_type,
	    permit_remarks,
            (select count(*) from permit_trans
		where permit_trans.permit_id = permit.permit_id
		and permit_trans.transaction_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#transaction_id#'>
	    ) as linkcount
    from
	    permit
    	left join preferred_agent_name issuedToPref on permit.issued_to_agent_id = issuedToPref.agent_id
	    left join preferred_agent_name issuedByPref on permit.issued_by_agent_id = issuedByPref.agent_id
    	left join agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
 	    left join agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
            left join permit_trans on permit.permit_id = permit_trans.permit_id
    where
        permit.permit_id is not null
		<cfif len(#IssuedByAgent#) gt 0>
			 AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(IssuedByAgent)#%'>
		</cfif>
		<cfif len(#IssuedToAgent#) gt 0>
			 AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(IssuedToAgent)#%'>
		</cfif>
		<cfif len(#issued_Date#) gt 0>
			 AND upper(issued_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(issued_Date)#%'>
		</cfif>
		<cfif len(#renewed_Date#) gt 0>
			 AND upper(renewed_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(renewed_Date)#%'>
		</cfif>
		<cfif len(#exp_Date#) gt 0>
			 AND upper(exp_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(exp_Date)#%'>
		</cfif>
		<cfif len(#permit_Num#) gt 0>
			 AND permit_Num = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#permit_Num#'>
		</cfif>
		<cfif len(#specific_type#) gt 0>
			 AND specific_type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#specific_type#'>
		</cfif>
		<cfif len(#permit_Type#) gt 0>
			 AND permit_Type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#permit_Type#'>
		</cfif>
		<cfif len(#permit_title#) gt 0>
			 AND upper(permit_title) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(permit_title)#%'>
		</cfif>
		<cfif len(#permit_remarks#) gt 0>
			 AND upper(permit_remarks) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(permit_remarks)#%'>
		</cfif>
    ORDER BY permit_id
    </cfquery>
    <cfset i=1>
    <cfset result = result & "<h2>Find permits to link to #transaction_label#</h2>">
    <cfloop query="matchPermit" >
        <cfset result = result & "<hr><div">
        <cfif (i MOD 2) EQ 0>
             <cfset result = result & "class='evenRow'">
        <cfelse>
             <cfset result = result & "class='oddRow'">
        </cfif>
        <cfset result = result & " >">
        <cfset result = result & "
    	<form id='pp_#permit_id#_#transaction_id#_#i#' >
	        Permit Number #matchPermit.permit_Num# (#matchPermit.permit_Type#:#matchPermit.specific_type#)
            issued to #matchPermit.IssuedToAgent# by #matchPermit.IssuedByAgent# on #dateformat(matchPermit.issued_Date,'yyyy-mm-dd')# ">
            <cfif len(#matchPermit.renewed_Date#) gt 0><cfset result = result & " (renewed #dateformat(matchPermit.renewed_Date,'yyyy-mm-dd')#)"></cfif>
            <cfset result = result & ". Expires #dateformat(matchPermit.exp_Date,'yyyy-mm-dd')#.  ">
            <cfif len(#matchPermit.permit_remarks#) gt 0><cfset result = result & "Remarks: #matchPermit.permit_remarks# "></cfif>
            <cfset result = result & " (ID## #matchPermit.permit_id#) #matchPermit.permit_title#
            <div id='pickResponse#transaction_id#_#i#'>">
                <cfif matchPermit.linkcount GT 0>
            		<cfset result = result & " This Permit is already linked to #transaction_label# ">
                <cfelse>
			<cfset result = result & "
                <input type='button' class='picBtn'
                onclick='linkpermit(#matchPermit.permit_id#,#transaction_id#,""#transaction_label#"",""pickResponse#transaction_id#_#i#"");' value='Add this permit'>
			">
		</cfif>
		<cfset result = result & "
            </div>
    	</form>
        <script language='javascript' type='text/javascript'>
        $('##pp_#permit_id#_#transaction_id#_#i#').removeClass('ui-widget-content');
        function linkpermit(permit_id, transaction_id, transaction_label, div_id) {
          jQuery.ajax({
             url: '/component/functions.cfc',
             type: 'post',
             data: {
                method: 'linkPermitToTrans',
                returnformat: 'plain',
                permit_id: permit_id,
                transaction_id: transaction_id,
                transaction_label: transaction_label
            },
            success: function (data) {
                $('##'+div_id).html(data);
            },
            fail: function (jqXHR, textStatus) {
                $('##'+div_id).html('Error:' + textStatus);
            }
          });
        };
        </script>
        </div>">
        <cfset i=i+1>
    </cfloop>

    <cfcatch>
		<cfset result = "Error: #cfcatch.Message# #cfcatch.Detail#">
    </cfcatch>
    </cftry>
    <cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!---  Given a transaction_id and a permit_id, create a permit_trans record to link the permit to the transaction.
       @param transaction_id the transaction to link
       @param permit_id the permit to link
       @return html message indicating success, or an error message on failure.

       @see transPermitPickerHtml
       @see findPermitSearchResults
--->
<cffunction name="linkPermitToTrans" access="remote" returntype="string">
    <cfargument name="transaction_id" type="string" required="yes">
    <cfargument name="transaction_label" type="string" required="yes">
    <cfargument name="permit_id" type="string" required="yes">

    <cfset result = "">
    <cftry>
		<cfquery name="addPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO permit_trans (permit_id, transaction_id) VALUES (#permit_id#, #transaction_id#)
		</cfquery>

		<cfset result = "Added this permit (#permit_id#) to transaction #transaction_label#. ">

    <cfcatch>
		<cfif cfcatch.detail CONTAINS "ORA-00001: unique constraint (MCZBASE.PKEY_PERMIT_TRANS">
			<cfset result = "Error: This permit is already linked to #transaction_label#">
                <cfelse>
			<cfset result = "Error: #cfcatch.message# #cfcatch.detail#">
 		</cfif>
    </cfcatch>
    </cftry>
    <cfreturn result>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!--- get permits as query json objects by a list of permit ids
      @param permitIdList a comma delimited list of permit_id values.
      @return a query object containing permit records (with status=1) or containing status=0|-1 and message.
--->
<cffunction name="getPermits" returntype="query" access="remote">
   <cfargument name="permitidList" type="string" required="yes">
   <cftry>
      <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
           select distinct 1 as status, permit_id, permit_num, permit_type, issued_date, renewed_date, exp_date,
                issued_by_agent_id, mczbase.get_agentnamebytype(issued_by_agent_id,'preferred') as issued_by_agent,
                issued_to_agent_id, mczbase.get_agentnamebytype(issued_to_agent_id,'preferred') as issued_to_agent,
                permit_remarks
           from permit
           where permit.permit_id in ( #permitidList# )
           order by permit_type, issued_date
      </cfquery>
      <cfif theResult.recordcount eq 0>
         <cfset theResult=queryNew("status, message")>
         <cfset t = queryaddrow(theResult,1)>
         <cfset t = QuerySetCell(theResult, "status", "0", 1)>
         <cfset t = QuerySetCell(theResult, "message", "No permits found.", 1)>
      </cfif>
   <cfcatch>
      <cfset theResult=queryNew("status, message")>
      <cfset t = queryaddrow(theResult,1)>
      <cfset t = QuerySetCell(theResult, "status", "-1", 1)>
      <cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
   </cfcatch>
   </cftry>
   <cfreturn theResult>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->

<cffunction name="getPermitsForTransHtml" returntype="string" access="remote" returnformat="plain">
   <cfargument name="transaction_id" type="string" required="yes">
   <cfset resulthtml="">
   <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select distinct permit_num, permit_type, issued_date, permit.permit_id,
             issuedBy.agent_name as IssuedByAgent
        from permit left join permit_trans on permit.permit_id = permit_trans.permit_id
             left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
        where permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#transaction_id#>
        order by permit_type, issued_date
   </cfquery>

   <cfset resulthtml = resulthtml & "<div class='permittrans'><span id='permits_tr_#transaction_id#'>">
   <cfloop query="query">
   	<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select media.media_id, media_uri, preview_uri, media_type,
  				 mczbase.get_media_descriptor(media.media_id) as media_descriptor
		from media_relations left join media on media_relations.media_id = media.media_id
		where media_relations.media_relationship = 'shows permit'
			and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#permit_id#>
	</cfquery>
	<cfset mediaLink = "&##8855;">
	<cfloop query="mediaQuery">
			<cfset puri=getMediaPreview(preview_uri,media_type) >
			<cfif puri EQ "/images/noThumb.jpg">
				<cfset altText = "Red X in a red square, with text, no preview image available">
			<cfelse>
				<cfset altText = mediaQuery.media_descriptor>
			</cfif>
		<cfset mediaLink = "<a href='#media_uri#'target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15' alt='#altText#'></a>" >
	</cfloop>
       <cfset resulthtml = resulthtml & "<ul class='permitshipul'><li><span>#mediaLink# #permit_type# #permit_Num#</span></li><li>Issued: #dateformat(issued_Date,'yyyy-mm-dd')#</li><li style='width:300px;'>#IssuedByAgent#</li></ul>">

       <cfset resulthtml = resulthtml & "<ul class='permitshipul2'>">
       <cfset resulthtml = resulthtml & "<li><input type='button' class='savBtn' style='padding:1px 6px;' onClick=' window.open(""/transactions/Permit.cfm?Action=edit&permit_id=#permit_id#"")' target='_blank' value='Edit'></li> ">
       <cfset resulthtml = resulthtml & "<li><input type='button' class='delBtn' style='padding:1px 6px;' onClick='confirmAction(""Remove this permit from this Transaction (#permit_type# #permit_Num#)?"", ""Confirm Remove Permit"", function() { deletePermitFromTransaction(#permit_id#,#transaction_id#); } ); ' value='Remove Permit'></li>">
       <cfset resulthtml = resulthtml & "</ul>">
   </cfloop>
   <cfif query.recordcount eq 0>
       <cfset resulthtml = resulthtml & "None">
   </cfif>
   <cfset resulthtml = resulthtml & "</span></div>"> <!--- span#permit_tr_, div.permittrans --->

   <cfreturn resulthtml>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="removePermitFromTransaction" returntype="query" access="remote">
        <cfargument name="permit_id" type="string" required="yes">
        <cfargument name="transaction_id" type="string" required="yes">
        <cfset r=1>
        <cftry>
            <cfquery name="deleteResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteResultRes">
             delete from permit_trans
             where permit_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
               and transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
            </cfquery>
                <cfif deleteResultRes.recordcount eq 0>
                  <cfset theResult=queryNew("status, message")>
                  <cfset t = queryaddrow(theResult,1)>
                  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
                  <cfset t = QuerySetCell(theResult, "message", "No records deleted. #permit_id# #transaction_id# #deleteResult.sql#", 1)>
                </cfif>
                <cfif deleteResultRes.recordcount eq 1>
                  <cfset theResult=queryNew("status, message")>
                  <cfset t = queryaddrow(theResult,1)>
                  <cfset t = QuerySetCell(theResult, "status", "1", 1)>
                  <cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
                </cfif>
        <cfcatch>
          <cfset theResult=queryNew("status, message")>
                <cfset t = queryaddrow(theResult,1)>
                <cfset t = QuerySetCell(theResult, "status", "-1", 1)>
                <cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
          </cfcatch>
        </cftry>
    <cfif isDefined("asTable") AND asTable eq "true">
            <cfreturn resulthtml>
    <cfelse>
            <cfreturn theResult>
    </cfif>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!---
   Save a permit record.  Creates a new permit if no permit_id is provided, otherwise updates permit record.
--->
<cffunction name="savePermit" returntype="query" access="remote">
   <cfargument name="permit_id" type="string" required="yes">
   <cfargument name="permit_num" type="string" required="yes">
   <cfargument name="permit_type" type="string" required="yes">
   <cfargument name="issued_date" type="string" required="yes">
   <cfargument name="renewed_date" type="string" required="yes">
   <cfargument name="exp_date" type="string" required="yes">
   <cfargument name="issued_by_agent_id" type="string" required="yes">
   <cfargument name="issued_to_agent_id" type="string" required="yes">
   <cfargument name="permit_remarks" type="string" required="yes">
   <cfset theResult=queryNew("status, message")>
   <cftransaction action="begin">
   <cftry>
      <cfif permit_id EQ "">
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
             insert into permit (
                permit_num, permit_type, issued_date, renewed_date, exp_date,
                issued_by_agent_id, issued_to_agent_id, permit_remarks
             )
             values (
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_num#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">,
                <cfqueryparam cfsqltype="CF_SQL_DATE" value="#issued_date#">,
                <cfqueryparam cfsqltype="CF_SQL_DATE" value="#renewed_date#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exp_date#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_by_agent_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_to_agent_id#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_remarks#">
             }
         </cfquery>
      <cfelse>
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
             update permit set
                issued_to_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_to_agent_id#">,
                issued_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_by_agent_id#">,
                permit_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_num#">,
                permit_type = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_type#">,
                issued_date = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_date#">,
                renewed_date = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#renewed_date#">,
                exp_date = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#exp_date#">,
                permit_remarks = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_remarks#">,,
             where
                permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
          </cfquery>
      </cfif>
      <cftransaction action="commit">
      <cfset t = queryaddrow(theResult,1)>
      <cfset t = QuerySetCell(theResult, "status", "1", 1)>
      <cfset t = QuerySetCell(theResult, "message", "Saved.", 1)>
	<cfcatch>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "0", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
        <cftransaction action="rollback">
	</cfcatch>
    </cftry>
   </cftransaction>
    <cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getPermitMediaHtml" returntype="string" access="remote" returnformat="plain">
   <cfargument name="permit_id" type="string" required="yes">
   <cfargument name="correspondence" type="string" required="no">
   <cfif isdefined("correspondence") and len(#correspondence#) gt 0>
       <cfset relation = "document for permit">
       <cfset heading = "Additional Documents">
   <cfelse>
       <cfset relation = "shows permit">
       <cfset heading = "The Document (copy of the actual permit)">
   </cfif>
   <cfset rel = left(relation,3)>
   <cfset result="">
     <cfquery name="permitInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    select permit.permit_id,
    issuedBy.agent_name as IssuedByAgent,
    issued_Date,
    permit_Num,
    permit_Type
    from
        permit,
        preferred_agent_name issuedBy
    where
        permit.issued_by_agent_id = issuedBy.agent_id (+)
    and permit_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
    </cfquery>
   <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select distinct media.media_id as media_id, preview_uri, media.media_uri, media.mime_type, media.media_type as media_type,
               MCZBASE.is_media_encumbered(media.media_id) as hideMedia,
  					MCZBASE.get_media_descriptor(media.media_id) as media_descriptor,
               label_value
         from media_relations left join media on media_relations.media_id = media.media_id
               left join media_labels on media.media_id = media_labels.media_id
         where media_relations.media_relationship = <cfqueryparam value="#relation#" CFSQLType="CF_SQL_VARCHAR">
               and (media_label = 'description' or media_label is null )
               and media_relations.related_primary_key = <cfqueryparam value="#permit_id#" CFSQLType="CF_SQL_DECIMAL">
   </cfquery>
   <cfset result="<h3>#heading# Media</h3>">
   <cfif query.recordcount gt 0>
       <cfset result=result & "<ul>">
       <cfloop query="query">
          <cfset puri=getMediaPreview(preview_uri,media_type) >
			<cfif puri EQ "/images/noThumb.jpg">
				<cfset altText = "Red X in a red square, with text, no preview image available">
			<cfelse>
				<cfset altText = query.media_descriptor>
			</cfif>
          <cfset result = result & "<li><a href='#media_uri#'><img src='#puri#' height='50' alt='#media_descriptor#'></a> #mime_type# #media_type# #label_value# <a href='/media/#media_id#' target='_blank'>Media Details</a>  <input class='delBtn' onClick='  confirmAction(""Remove this media from this permit (#relation#)?"", ""Confirm Unlink Media"", function() { deleteMediaFromPermit(#media_id#,#permit_id#,""#relation#""); } ); event.prefentDefault(); ' value='Remove' style='width: 5em; text-align: center;' onmouseover=""this.className='delBtn btnhov'"" onmouseout=""this.className='delBtn'"" > </li>" >

       </cfloop>
       <cfset result= result & "</ul>">
   </cfif>
   <cfset result=result & "<span>">
   <cfif query.recordcount EQ 0 or relation IS 'document for permit'>
	<cfset result = result & "<input type='button'
		onClick=""opencreatemediadialog('addMediaDlg_#permit_id#_#rel#','permissions/rights document #permitInfo.permit_Type# - #jsescape(permitInfo.IssuedByAgent)# - #permitInfo.permit_Num#','#permit_id#','#relation#',reloadPermitMedia);"" value='Create Media' class='lnkBtn'>&nbsp;" >
	<cfset result = result & "<span id='addPermit_#permit_id#'><input type='button' value='Link Media' class='lnkBtn' onClick=""openlinkmediadialog('addPermitDlg_#permit_id#_#rel#','Pick Media for Permit #permitInfo.permit_Type# - #jsescape(permitInfo.IssuedByAgent)# - #permitInfo.permit_Num#','#permit_id#','#relation#',reloadPermitMedia); "" ></span>">
   </cfif>
   <cfset result=result & "</span>">
   <cfset result=result & "<div id='addMediaDlg_#permit_id#_#rel#'></div>" >
   <cfset result=result & "<div id='addPermitDlg_#permit_id#_#rel#'></div>">
   <cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="removeMediaFromPermit" returntype="query" access="remote">
        <cfargument name="permit_id" type="string" required="yes">
        <cfargument name="media_id" type="string" required="yes">
        <cfargument name="media_relationship" type="string" required="yes">
        <cfset r=1>
        <cftry>
            <cfquery name="deleteResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteResult">
             delete from media_relations
             where related_primary_key =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
               and media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
               and media_relationship=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship#">
            </cfquery>
                <cfif deleteResult.recordcount eq 0>
                  <cfset theResult=queryNew("status, message")>
                  <cfset t = queryaddrow(theResult,1)>
                  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
                  <cfset t = QuerySetCell(theResult, "message", "No records deleted. #media_id# #media_relationship# #permit_id# #deleteResult.sql#", 1)>
                </cfif>
                <cfif deleteResult.recordcount eq 1>
                  <cfset theResult=queryNew("status, message")>
                  <cfset t = queryaddrow(theResult,1)>
                  <cfset t = QuerySetCell(theResult, "status", "1", 1)>
                  <cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
                </cfif>
        <cfcatch>
          <cfset theResult=queryNew("status, message")>
                <cfset t = queryaddrow(theResult,1)>
                <cfset t = QuerySetCell(theResult, "status", "-1", 1)>
                <cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
          </cfcatch>
        </cftry>
    <cfif isDefined("asTable") AND asTable eq "true">
            <cfreturn resulthtml>
    <cfelse>
            <cfreturn theResult>
    </cfif>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!---
   Function to create or save a shipment from a ajax post
   @param shipment_id the shipment_id of the shipment to save, if null, then create a new shipment.
   @param transaction_id the transaction with which this shipment is associated.
   @return json query structure with STATUS = 0|1 and MESSAGE, status = 0 on a failure.
 --->
<cffunction name="saveShipment" returntype="query" access="remote">
   <cfargument name="shipment_id" required="no">
   <cfargument name="transaction_id" type="numeric" required="yes">
   <cfargument name="packed_by_agent_id" type="numeric" required="no">
   <cfargument name="shipped_carrier_method" type="string" required="no">
   <cfargument name="carriers_tracking_number" type="string" required="no">
   <cfargument name="shipped_date" type="string" required="no">
   <cfargument name="package_weight" type="string" required="no">
   <cfargument name="no_of_packages" type="string" required="no">
   <cfargument name="hazmat_fg" type="numeric" required="no">
   <cfargument name="insured_for_insured_value" type="string" required="no">
   <cfargument name="shipment_remarks" type="string" required="no">
   <cfargument name="contents" type="string" required="no">
   <cfargument name="foreign_shipment_fg" type="numeric" required="no">
   <cfargument name="shipped_to_addr_id" type="string" required="no">
   <cfargument name="shipped_from_addr_id" type="string" required="no">
   <cfset theResult=queryNew("status, message")>
   <cftry>
      <cfset debug = shipment_id >
      <!---  Try to obtain a numeric value for no_of_packages, if this fails, set no_of_packages to empty string to not include --->
      <cfset noofpackages = val(#no_of_packages#) >
      <cfif noofpackages EQ 0>
          <cfset no_of_packages = "">
      </cfif>
      <cfif NOT IsDefined("shipment_id") OR shipment_id EQ "">
         <!---  Determine how many shipments there are in this transaction, if none, set the print_flag on the new shipment --->
         <cfquery name="countShipments" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
             select count(*) ct from shipment
                where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
         </cfquery>
         <cfif countShipments.ct EQ 0>
             <cfset printFlag = 1>
         <cfelse>
             <cfset printFlag = 0>
         </cfif>
         <cfset debug = shipment_id & "Insert" >
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
             insert into shipment (
                transaction_id, packed_by_agent_id, shipped_carrier_method, carriers_tracking_number, shipped_date, package_weight,
                <cfif isdefined("no_of_packages") and len(#no_of_packages#) gt 0>
                  no_of_packages,
                </cfif>
                <cfif isdefined("insured_for_insured_value") and len(#insured_for_insured_value#) gt 0>
                  insured_for_insured_value,
                </cfif>
                hazmat_fg, shipment_remarks, contents, foreign_shipment_fg,
                shipped_to_addr_id, shipped_from_addr_id,
                print_flag
             )
             values (
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#packed_by_agent_id#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipped_carrier_method#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#carriers_tracking_number#">,
                <cfqueryparam cfsqltype="CF_SQL_DATE" value="#shipped_date#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#package_weight#">,
                <cfif isdefined("no_of_packages") and len(#no_of_packages#) gt 0>
                   <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#noofpackages#">,
                </cfif>
                <cfif isdefined("insured_for_insured_value") and len(#insured_for_insured_value#) gt 0>
                   <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#insured_for_insured_value#" null="yes">,
                </cfif>
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hazmat_fg#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipment_remarks#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#contents#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#foreign_shipment_fg#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_to_addr_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_from_addr_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#printFlag#">
             )
         </cfquery>
      <cfelse>
         <cfset debug = shipment_id & "Update" >
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
             update shipment set
                packed_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#packed_by_agent_id#">,
                shipped_carrier_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipped_carrier_method#">,
                carriers_tracking_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#carriers_tracking_number#">,
                shipped_date = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#shipped_date#">,
                package_weight = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#package_weight#">,
                <cfif isdefined("no_of_packages") and len(#no_of_packages#) gt 0>
                   no_of_packages = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#noofpackages#" >,
                <cfelse>
                   no_of_packages = <cfqueryparam cfsqltype="CF_SQL_NULL" null="yes" value="" >,
                </cfif>
                <cfif isdefined("insured_for_insured_value") and len(#insured_for_insured_value#) gt 0>
                   insured_for_insured_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insured_for_insured_value#">,
                </cfif>
                hazmat_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hazmat_fg#">,
                shipment_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipment_remarks#">,
                contents = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#contents#">,
                foreign_shipment_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#foreign_shipment_fg#">,
                shipped_to_addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_to_addr_id#">,
                shipped_from_addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_from_addr_id#">
             where
                shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#"> and
                transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
          </cfquery>
      </cfif>
      <cfset t = queryaddrow(theResult,1)>
      <cfset t = QuerySetCell(theResult, "status", "1", 1)>
      <cfset t = QuerySetCell(theResult, "message", "Saved.", 1)>
	<cfcatch>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "0", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#debug# #cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	</cfcatch>
    </cftry>
    <cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getPermitsForShipment" returntype="string" access="remote" returnformat="plain">
   <cfargument name="shipment_id" type="string" required="yes">
   <cfset result="">
   <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select distinct permit_num, permit_type, issued_date, permit.permit_id,
             issuedBy.agent_name as IssuedByAgent
        from permit_shipment left join permit on permit_shipment.permit_id = permit.permit_id
             left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
        where permit_shipment.shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#shipment_id#>
        order by permit_type, issued_date
   </cfquery>
   <cfif query.recordcount gt 0>
       <cfset result="<ul>">
       <cfloop query="query">
   	    <cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		    select media.media_id, media_uri, preview_uri, media_type,
  					mczbase.get_media_descriptor(media.media_id) as media_descriptor
    		from media_relations left join media on media_relations.media_id = media.media_id
	    	where media_relations.media_relationship = 'shows permit'
		    	and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#query.permit_id#>
    	</cfquery>
	    <cfset mediaLink = "&##8855;">
    	<cfloop query="mediaQuery">
			<cfset puri=getMediaPreview(preview_uri,media_type) >
			<cfif puri EQ "/images/noThumb.jpg">
				<cfset altText = "Red X in a red square, with text, no preview image available">
			<cfelse>
				<cfset altText = mediaQuery.media_descriptor>
			</cfif>
	    	<cfset mediaLink = "<a href='#media_uri#' target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15' alt='#altText#'></a>" >
    	</cfloop>
          <cfset result = result & "<li><span>#mediaLink# #permit_type# #permit_num# Issued:#dateformat(issued_date,'yyyy-mm-dd')# #IssuedByAgent#</span></li>">
       </cfloop>
       <cfset result= result & "</ul>">
   </cfif>
   <cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="removePermitFromShipment" returntype="query" access="remote">
        <cfargument name="permit_id" type="string" required="yes">
        <cfargument name="shipment_id" type="string" required="yes">
        <cfset r=1>
        <cftry>
            <cfquery name="deleteResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteResultRes">
             delete from permit_shipment
             where permit_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
               and shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
            </cfquery>
                <cfif deleteResultRes.recordcount eq 0>
                  <cfset theResult=queryNew("status, message")>
                  <cfset t = queryaddrow(theResult,1)>
                  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
                  <cfset t = QuerySetCell(theResult, "message", "No records deleted. #permit_id# #shipment_id# #deleteResult.sql#", 1)>
                </cfif>
                <cfif deleteResultRes.recordcount eq 1>
                  <cfset theResult=queryNew("status, message")>
                  <cfset t = queryaddrow(theResult,1)>
                  <cfset t = QuerySetCell(theResult, "status", "1", 1)>
                  <cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
                </cfif>
        <cfcatch>
          <cfset theResult=queryNew("status, message")>
                <cfset t = queryaddrow(theResult,1)>
                <cfset t = QuerySetCell(theResult, "status", "-1", 1)>
                <cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
          </cfcatch>
        </cftry>
    <cfif isDefined("asTable") AND asTable eq "true">
            <cfreturn resulthtml>
    <cfelse>
            <cfreturn theResult>
    </cfif>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="removeShipment" returntype="query" access="remote">
        <cfargument name="shipment_id" type="string" required="yes">
        <cfargument name="transaction_id" type="string" required="yes">
        <cfset r=1>
        <cftry>
            <cfquery name="countPermits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteResult">
             select count(*) as ct from permit_shipment
             where shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
            </cfquery>
            <cfif countPermits.ct EQ 0 >
               <cfquery name="deleteResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteResult">
                delete from shipment
                where transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
                 and shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
               </cfquery>
                <cfif deleteResult.recordcount eq 0>
                  <cfset theResult=queryNew("status, message")>
                  <cfset t = queryaddrow(theResult,1)>
                  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
                  <cfset t = QuerySetCell(theResult, "message", "No records deleted. #shipment_id# #deleteResult.sql#", 1)>
                </cfif>
                <cfif deleteResult.recordcount eq 1>
                  <cfset theResult=queryNew("status, message")>
                  <cfset t = queryaddrow(theResult,1)>
                  <cfset t = QuerySetCell(theResult, "status", "1", 1)>
                  <cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
                </cfif>
            <cfelse>
                <cfset theResult=queryNew("status, message")>
                <cfset t = queryaddrow(theResult,1)>
                <cfset t = QuerySetCell(theResult, "status", "0", 1)>
                <cfset t = QuerySetCell(theResult, "message", "Can't delete shipment with attached permits.", 1)>
            </cfif>
        <cfcatch>
          <cfset theResult=queryNew("status, message")>
                <cfset t = queryaddrow(theResult,1)>
                <cfset t = QuerySetCell(theResult, "status", "-1", 1)>
                <cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
          </cfcatch>
        </cftry>
        <cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getShipments" returntype="query" access="remote">
	<cfargument name="shipmentidList" type="string" required="yes">
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		   select 1 as status, shipment_id, transaction_id,
                   packed_by_agent_id, mczbase.get_agentnameoftype(packed_by_agent_id,'preferred') packed_by_agent, carriers_tracking_number,
                   shipped_carrier_method, to_char(shipped_date, 'yyyy-mm-dd') as shipped_date, package_weight, no_of_packages,
                   hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id,
                   shipped_from_addr_id, fromaddr.formatted_addr as shipped_from_address, toaddr.formatted_addr as shipped_to_address,
 	           shipment.print_flag
             from shipment
                  left join addr fromaddr on shipment.shipped_from_addr_id = fromaddr.addr_id
                  left join addr toaddr on shipment.shipped_to_addr_id = toaddr.addr_id
             where shipment_id in (#shipmentidList#)
		</cfquery>
		<cfif theResult.recordcount eq 0>
	  	  <cfset theResult=queryNew("status, message")>
		  <cfset t = queryaddrow(theResult,1)>
		  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
	  <cfcatch>
	   	<cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getShipmentsByTrans" returntype="query" access="remote">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
	    <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select 1 as status, shipment_id, packed_by_agent_id, shipped_carrier_method, shipped_date, package_weight, no_of_packages,
                   hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id,
                   shipped_from_addr_id, fromaddr.formatted_addr, toaddr.formatted_addr,
 	           shipment.print_flag
             from shipment
                  left join addr fromaddr on shipment.shipped_from_addr_id = fromaddr.addr_id
                  left join addr toaddr on shipment.shipped_from_addr_id = toaddr.addr_id
             where shipment.transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
	  	  <cfset theResult=queryNew("status, message")>
		  <cfset t = queryaddrow(theResult,1)>
		  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
	<cfcatch>
	  <cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
    <cfif isDefined("asTable") AND asTable eq "true">
	    <cfreturn resulthtml>
    <cfelse>
   	    <cfreturn theResult>
    </cfif>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->

<!---  Obtain the list of shipments and their permits for a transaction formatted in html for display on a transaction page --->
<!---  @param transaction_id  the transaction for which to obtain a list of shipments and their permits.  --->
<!---  @return html list of shipments and permits, including editing controls for adding/editing/removing shipments and permits. --->
<cffunction name="getShipmentsByTransHtml" returntype="string" access="remote" returnformat="plain">
   <cfargument name="transaction_id" type="string" required="yes">
   <cfset r=1>
   <cfthread name="getSBTHtmlThread">
   <cftry>
       <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
         select 1 as status, shipment_id, packed_by_agent_id, shipped_carrier_method, shipped_date, package_weight, no_of_packages,
                   hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id, carriers_tracking_number,
                   shipped_from_addr_id, fromaddr.formatted_addr, toaddr.formatted_addr,
                   toaddr.country_cde tocountry, toaddr.institution toinst, toaddr.formatted_addr tofaddr,
                   fromaddr.country_cde fromcountry, fromaddr.institution frominst, fromaddr.formatted_addr fromfaddr,
 	           shipment.print_flag
             from shipment
                  left join addr fromaddr on shipment.shipped_from_addr_id = fromaddr.addr_id
                  left join addr toaddr on shipment.shipped_to_addr_id = toaddr.addr_id
             where shipment.transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
             order by shipped_date
      </cfquery>
      <cfset resulthtml = "<div id='shipments'> ">

      <cfloop query="theResult">
         <cfif print_flag eq "1">
            <cfset printedOnInvoice = "&##9745; Printed on invoice">
         <cfelse>
            <cfset printedOnInvoice = "<span class='infoLink' onClick=' setShipmentToPrint(#shipment_id#,#transaction_id#); ' >&##9744; Not Printed</span>">
         </cfif>
         <cfquery name="shippermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                 select permit.permit_id,
                   issuedBy.agent_name as IssuedByAgent,
                   issued_Date,
                   renewed_Date,
                   exp_Date,
                   permit_Num,
                   permit_Type
                 from
                   permit_shipment left join permit on permit_shipment.permit_id = permit.permit_id
                   left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
                 where
                   permit_shipment.shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
         </cfquery>
         <cfset resulthtml = resulthtml & "<script>function reloadShipments() { loadShipments(#transaction_id#); } </script>" >
         <cfset resulthtml = resulthtml & "<div class='shipment'>" >
            <cfset resulthtml = resulthtml & "<ul class='shipheaders'><li>Ship Date:</li><li>Method:</li><li>Packages:</li><li>Tracking Number:</li></ul>">
            <cfset resulthtml = resulthtml & " <ul class='shipdata'>" >
                <cfset resulthtml = resulthtml & "<li>#dateformat(shipped_date,'yyyy-mm-dd')#&nbsp;</li> " >
                <cfset resulthtml = resulthtml & " <li>#shipped_carrier_method#&nbsp;</li> " >
                <cfset resulthtml = resulthtml & " <li>#no_of_packages#&nbsp;</li> " >
                <cfset resulthtml = resulthtml & " <li>#carriers_tracking_number#</li>">
            <cfset resulthtml = resulthtml & "</ul>">
            <cfset resulthtml = resulthtml & "<ul class='shipaddresseshead'><li>Shipped To:</li><li>Shipped From:</li></ul>">
            <cfset resulthtml = resulthtml & " <ul class='shipaddressesdata'>">
                <cfset resulthtml = resulthtml & "<li>(#printedOnInvoice#) #tofaddr#</li> ">
                <cfset resulthtml = resulthtml & " <li>#fromfaddr#</li>">
            <cfset resulthtml = resulthtml & "</ul>">
            <cfset resulthtml = resulthtml & "<div class='changeship'><div class='shipbuttons'><input type='button' value='Edit this Shipment' class='lnkBtn' onClick=""$('##dialog-shipment').dialog('open'); loadShipment(#shipment_id#,'shipmentForm');""></div><div class='shipbuttons' id='addPermit_#shipment_id#'><input type='button' value='Add Permit to this Shipment' class='lnkBtn' onClick="" openlinkpermitshipdialog('addPermitDlg_#shipment_id#','#shipment_id#','Shipment: #carriers_tracking_number#',reloadShipments); "" ></div><div id='addPermitDlg_#shipment_id#'></div></div> ">
            <cfset resulthtml = resulthtml & "<div class='shippermitstyle'><h4>Permits:</h4>">
                 <cfset resulthtml = resulthtml & "<div class='permitship'><span id='permits_ship_#shipment_id#'>">
                 <cfloop query="shippermit">
   	    		<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			    select media.media_id, media_uri, preview_uri, media_type,
  						mczbase.get_media_descriptor(media.media_id) as media_descriptor
    				from media_relations left join media on media_relations.media_id = media.media_id
			    	where media_relations.media_relationship = 'shows permit'
			    	and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#shippermit.permit_id#>
		    	</cfquery>
	    		<cfset mediaLink = "&##8855;">
		    	<cfloop query="mediaQuery">
					<cfset puri=getMediaPreview(preview_uri,media_type) >
					<cfif puri EQ "/images/noThumb.jpg">
						<cfset altText = "Red X in a red square, with text, no preview image available">
					<cfelse>
						<cfset altText = mediaQuery.media_descriptor>
					</cfif>
	    			<cfset mediaLink = "<a href='#media_uri#' target='_blank' rel='noopener noreferrer' ><img src='#puri#' height='15' alt='#altText#'></a>" >
		    	</cfloop>
                    <cfset resulthtml = resulthtml & "<ul class='permitshipul'><li><span>#mediaLink# #permit_type# #permit_Num#</span></li><li>Issued: #dateformat(issued_Date,'yyyy-mm-dd')#</li><li style='width:300px;'> #IssuedByAgent#</li></ul>">
                    <cfset resulthtml = resulthtml & "<ul class='permitshipul2'>">
                       <cfset resulthtml = resulthtml & "<li><input type='button' class='savBtn' style='padding:1px 6px;' onClick=' window.open(""/transactions/Permit.cfm?action=edit&permit_id=#permit_id#"")' target='_blank' value='Edit'></li> ">
                       <cfset resulthtml = resulthtml & "<li><input type='button' class='delBtn' style='padding:1px 6px;' onClick='confirmAction(""Remove this permit from this shipment (#permit_type# #permit_Num#)?"", ""Confirm Remove Permit"", function() { deletePermitFromShipment(#theResult.shipment_id#,#permit_id#,#transaction_id#); } ); ' value='Remove Permit'></li>">
                       <cfset resulthtml = resulthtml & "<li>">
                       <cfset resulthtml = resulthtml & "<input type='button' onClick=' opendialog(""picks/PermitPick.cfm?Action=movePermit&permit_id=#permit_id#&transaction_id=#transaction_id#&current_shipment_id=#theResult.shipment_id#"",""##movePermitDlg_#theResult.shipment_id##permit_id#"",""Move Permit to another Shipment"");' class='lnkBtn' style='padding:1px 6px;' value='Move'>">
                       <cfset resulthtml = resulthtml & "<span id='movePermitDlg_#theResult.shipment_id##permit_id#'></span></li>">
                    <cfset resulthtml = resulthtml & "</ul>">
                 </cfloop>
                 <cfif shippermit.recordcount eq 0>
                     <cfset resulthtml = resulthtml & "None">
                 </cfif>
            <cfset resulthtml = resulthtml & "</span></div></div>"> <!--- span#permit_ships_, div.permitship div.shippermitsstyle --->
            <cfif shippermit.recordcount eq 0>
                <cfset resulthtml = resulthtml & "<div class='deletestyle' id='removeShipment_#shipment_id#'><input type='button' value='Delete this Shipment' class='delBtn' onClick="" confirmAction('Delete this shipment (#theResult.shipped_carrier_method# #theResult.carriers_tracking_number#)?', 'Confirm Delete Shipment', function() { deleteShipment(#shipment_id#,#transaction_id#); }  ); "" ></div>">
            <cfelse>
                <cfset resulthtml = resulthtml & "<div class='deletestyle'><input type='button' class='disBtn' value='Delete this Shipment'></div>">
            </cfif>
            <cfset resulthtml = resulthtml & "</div>" > <!--- shipment div --->
      </cfloop> <!--- theResult --->
      <cfset resulthtml = resulthtml & "</div>"><!--- shipments div --->
      <cfif theResult.recordcount eq 0>
          <cfset resulthtml = resulthtml & "No shipments found for this transaction.">
      </cfif>
   <cfcatch>
       <cfset resulthtml = resulthtml & "Error:" & "#cfcatch.type# #cfcatch.message# #cfcatch.detail#">
   </cfcatch>
   </cftry>
     <cfoutput>#resulthtml#</cfoutput>
   </cfthread>
    <cfthread action="join" name="getSBTHtmlThread" />
    <cfreturn getSBTHtmlThread.output>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!---  Given a shipment_id, set only that shipment out of the set of shipments in that transaction to print. --->
<cffunction name="setShipmentToPrint" access="remote">
    <cfargument name="shipment_id" type="numeric" required="yes">
    <cftry>
       <cftransaction action="begin">
       <!--- First set the print flag off for all shipments on this transaction. --->
       <cfquery name="clearResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearResultRes">
            update shipment set print_flag = 0 where transaction_id in (
                  select transaction_id from shipment where shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
            )
       </cfquery>
       <!--- Then set the print flag on for the provided shipments. --->
       <cfif clearResultRes.recordcount GT 0 >
          <cfquery name="updateResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateResultRes">
              update shipment set print_flag = 1 where shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
          </cfquery>

          <cfif updateResultRes.recordcount eq 0>
             <cftransaction action="rollback"/>
             <cfset theResult=queryNew("status, message")>
             <cfset t = queryaddrow(theResult,1)>
             <cfset t = QuerySetCell(theResult, "status", "0", 1)>
             <cfset t = QuerySetCell(theResult, "message", "Shipment not updated. #shipment_id# #updateResultRes.sql#", 1)>
          </cfif>
          <cfif updateResultRes.recordcount eq 1>
             <cftransaction action="commit"/>
             <cfset theResult=queryNew("status, message")>
             <cfset t = queryaddrow(theResult,1)>
             <cfset t = QuerySetCell(theResult, "status", "1", 1)>
             <cfset t = QuerySetCell(theResult, "message", "Shipment updated to print.", 1)>
          </cfif>
       <cfelse>
             <cftransaction action="rollback"/>
             <cfset theResult=queryNew("status, message")>
             <cfset t = queryaddrow(theResult,1)>
             <cfset t = QuerySetCell(theResult, "status", "0", 1)>
             <cfset t = QuerySetCell(theResult, "message", "Shipment not found. #shipment_id# #clearResultRes.sql#", 1)>
       </cfif>
       </cftransaction>
    <cfcatch>
        <cfset theResult=queryNew("status, message")>
        <cfset t = queryaddrow(theResult,1)>
        <cfset t = QuerySetCell(theResult, "status", "-1", 1)>
        <cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
        </cfcatch>
    </cftry>
    <cfreturn theResult>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!---  Given a permit_id and a shipment_id, link the permit to the shipment --->
<cffunction name="setShipmentForPermit" access="remote">
    <cfargument name="shipment_id" type="numeric" required="yes">
    <cfargument name="permit_id" type="numeric" required="yes">
    <cftry>
       <cfquery name="insertResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insertResultRes">
            insert into permit_shipment (permit_id, shipment_id)
            values ( <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">, <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">)
       </cfquery>
       <cfif insertResultRes.recordcount eq 0>
             <cfset theResult=queryNew("status, message")>
             <cfset t = queryaddrow(theResult,1)>
             <cfset t = QuerySetCell(theResult, "status", "0", 1)>
             <cfset t = QuerySetCell(theResult, "message", "Record not added. #permit_id# #shipment_id# #deleteResult.sql#", 1)>
       </cfif>
       <cfif insertResultRes.recordcount eq 1>
             <cfset theResult=queryNew("status, message")>
             <cfset t = queryaddrow(theResult,1)>
             <cfset t = QuerySetCell(theResult, "status", "1", 1)>
             <cfset t = QuerySetCell(theResult, "message", "Permit added to shipment.", 1)>
       </cfif>
    <cfcatch>
        <cfset theResult=queryNew("status, message")>
        <cfset t = queryaddrow(theResult,1)>
        <cfset t = QuerySetCell(theResult, "status", "-1", 1)>
        <cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
        </cfcatch>
    </cftry>
    <cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="addNewctSpecificType" access="remote" returnformat="json">
        <cfargument name="new_specific_type" type="string" required="yes">
        <cfset result = structNew()>
        <cftry>
        <cfset new_specific_type = trim(new_specific_type) >
        <cfquery name="addSpecificType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
           insert into ctspecific_permit_type (specific_type)
               values ( <cfqueryparam value = "#new_specific_type#" CFSQLType="CF_SQL_VARCHAR"> )
        </cfquery>
        <cfset result["message"] = "Added #new_specific_type#.">
        <cfcatch>
            <cfif cfcatch.queryError contains 'ORA-00001'>
               <cfset result["message"] = "Error: That value is already a specific type of permit.">
            <cfelse>
               <cfset result["message"] = "Error #cfcatch.message# #cfcatch.queryError#">
            </cfif>
        </cfcatch>
        </cftry>
        <cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getLatLonRefSourceFilter" access="remote" returnformat="json">
        <cfargument name="term" type="string" required="no">
	<cfif isdefined("term")>
             <cfset term = "%#term#%">
        <cfelse>
             <cfset term = "%">
        </cfif>
        <cfset results = arrayNew(1)>
        <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                select
                        distinct(lat_long_ref_source) lat_long_ref_source
                FROM
                        lat_long
                WHERE
                        lat_long_ref_source like <cfqueryparam value="#term#" cfsqltype="CF_SQL_VARCHAR">
                ORDER BY
                        lat_long_ref_source
        </cfquery>
        <cfloop query="query">
            <cfset result = structNew()>
            <cfset result['id'] = query.lat_long_ref_source >
            <cfset result['label'] = query.lat_long_ref_source >
            <cfset result['value'] = query.lat_long_ref_source >
            <cfset ArrayAppend(results,result)>
        </cfloop>
        <cfreturn results >
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="saveSearch" access="remote">
	<cfargument name="returnURL" type="string" required="yes">
	<cfargument name="srchName" type="string" required="yes">
	<cfset srchName=urldecode(srchName)>
	<cftry>
		<cfquery name="me" datasource="cf_dbuser">
			select user_id
			from cf_users
			where username='#session.username#'
		</cfquery>
		<cfset urlRoot=left(returnURL,find(".cfm", returnURL))>
		<cfquery name="alreadyGotOne" datasource="cf_dbuser">
			select search_name
			from cf_canned_search
			where search_name='#srchName#'
				and user_id='#me.user_id#'
				and url like '#urlRoot#%'
		</cfquery>
		<cfif len(alreadyGotOne.search_name) gt 0>
			<cfset msg="The name of your saved search is already in use.">
		<cfelse>
			<cfquery name="i" datasource="cf_dbuser">
				insert into cf_canned_search (
				user_id,
				search_name,
				url
				) values (
				 #me.user_id#,
				 '#srchName#',
				 '#returnURL#')
			</cfquery>
			<cfset msg="success">
		</cfif>
	<cfcatch>
		<cfset msg="An error occured while saving your search: #cfcatch.message# #cfcatch.detail#">
	</cfcatch>
	</cftry>
	<cfreturn msg>
</cffunction>
<!------------------------------------->
<cffunction name="changeresultSort" access="remote">
	<cfargument name="tgt" type="string" required="yes">
	<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					result_sort = '#tgt#'
				WHERE username = '#session.username#'
			</cfquery>
			<cfset session.result_sort = "#tgt#">
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!----------------------------------------------------------------------------------------->
<cffunction name="changeSpecimensDefaultAction" access="remote">
	<cfargument name="specimens_default_action" type="string" required="yes">
	<cftry>
			<cfquery name="updatespecdefact" datasource="cf_dbuser" result="result_updatespecdefact">
				UPDATE cf_users SET
					specimens_default_action = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#specimens_default_action#">
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getspecdefact" datasource="cf_dbuser" result="result_updatespecdefact">
				SELECT specimens_default_action
				FROM cf_users 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset session.specimens_default_action = getspecdefact.specimens_default_action>
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="changeSpecimensPinGuid" access="remote">
	<cfargument name="specimens_pin_guid" type="string" required="yes">
	<cftry>
			<cfquery name="updatespecpinguid" datasource="cf_dbuser" result="result_updatespecpinguid">
				UPDATE cf_users SET
					specimens_pin_guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#specimens_pin_guid#">
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getspecpinguid" datasource="cf_dbuser" result="result_updatespecpinguid">
				SELECT specimens_pin_guid
				FROM cf_users 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset session.specimens_pin_guid = getspecpinguid.specimens_pin_guid>
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="changeSpecimensPageSize" access="remote">
	<cfargument name="specimens_pagesize" type="string" required="yes">
	<cftry>
			<cfquery name="updatespecpinguid" datasource="cf_dbuser" result="result_updatespecpinguid">
				UPDATE cf_users SET
					specimens_pagesize = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#specimens_pagesize#">
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getspecpagesize" datasource="cf_dbuser" result="result_getspecpagesize">
				SELECT specimens_pagesize
				FROM cf_users 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset session.specimens_pagesize = getspecpagesize.specimens_pagesize>
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="changeGridEnableMousewheel" access="remote">
	<cfargument name="gridenablemousewheel" type="string" required="yes">
	<cftry>
			<cfquery name="updateenablemousewheel" datasource="cf_dbuser" result="result_updateenabmemousewheel">
				UPDATE cf_users SET
					gridenablemousewheel = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#gridenablemousewheel#">
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getgridenablemousewheel" datasource="cf_dbuser" result="result_getgridenablemousewheel">
				SELECT gridenablemousewheel
				FROM cf_users 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset session.gridenablemousewheel = getgridenablemousewheel.gridenablemousewheel>
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="changeGridScrollToTop" access="remote">
	<cfargument name="gridscrolltotop" type="string" required="yes">
	<cftry>
			<cfquery name="updatescrollgrid" datasource="cf_dbuser" result="result_updatescrollgrid">
				UPDATE cf_users SET
					gridscrolltotop = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#gridscrolltotop#">
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getgridscrolltotop" datasource="cf_dbuser" result="result_getscrolltotop">
				SELECT gridscrolltotop
				FROM cf_users 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset session.gridscrolltotop = getgridscrolltotop.gridscrolltotop>
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="changedisplayRows" access="remote">
	<cfargument name="tgt" type="string" required="yes">
	<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					displayrows = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tgt#">
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset session.displayrows = "#tgt#">
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="setSrchVal" access="remote">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="tgt" type="numeric" required="yes">
	<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					#name# =
					#tgt#
				WHERE username = '#session.username#'
			</cfquery>
			<cfif #tgt# is 1>
				<cfset session.searchBy="#session.searchBy#,#name#">
			<cfelse>
				<cfset i = listfindnocase(session.searchBy,name,",")>
				<cfif i gt 0>
					<cfset session.searchBy=listdeleteat(session.searchBy,i)>
				</cfif>
			</cfif>
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="changeAttDetr" access="remote">
	<cfargument name="attribute_id" type="numeric" required="yes">
	<cfargument name="i" type="numeric" required="yes">
	<cfargument name="attribute_determiner" type="string" required="yes">
	  	<cfquery name="names" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select agent_name,agent_id
			from preferred_agent_name
			where upper(agent_name) like '%#ucase(attribute_determiner)#%'
		</cfquery>
		<cfif #names.recordcount# is 0>
			<cfset result = "Nothing matched.">
		<cfelseif #names.recordcount# is 1>
			<cftry>
				<cfquery name="upatt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update attributes set DETERMINED_BY_AGENT_ID = #names.agent_id#
					where attribute_id = #attribute_id#
				</cfquery>
				<cfset result = '#i#::#names.agent_name#'>
			<cfcatch>
				<cfset result = 'A database error occured!'>
			</cfcatch>
			</cftry>
		<cfelse>
			<cfset result = "#i#::">
			<cfloop query="names">
				<cfset result = "#result#|#agent_name#">
			</cfloop>
		</cfif>
	  <cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
		<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<!----------------------------------------------------------------------------------------->
<cffunction name="changeAttDetrId" access="remote">
	<cfargument name="attribute_id" type="numeric" required="yes">
	<cfargument name="i" type="numeric" required="yes">
	<cfargument name="agent_id" type="numeric" required="yes">
	<cfquery name="names" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select agent_name,agent_id
		from preferred_agent_name
		where agent_id = #agent_id#
	</cfquery>
	<cfif #names.recordcount# is 0>
		<cfset result = "Nothing matched.">
	<cfelseif #names.recordcount# is 1>
		<cftry>
			<cfquery name="upatt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update attributes set DETERMINED_BY_AGENT_ID = #names.agent_id#
				where attribute_id = #attribute_id#
			</cfquery>
			<cfset result = '#i#::#names.agent_name#'>
		<cfcatch>
			<cfset result = 'A database error occured!'>
		</cfcatch>
		</cftry>
	<cfelse>
		<cfset result = "#i#::">
		<cfloop query="names">
			<cfset result = "#result#|#agent_name#">
		</cfloop>
	</cfif>
	<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="addAnnotation" access="remote">
	<cfargument name="idType" type="string" required="yes">
	<cfargument name="idvalue" type="numeric" required="yes">
	<cfargument name="annotation" type="string" required="yes">
	<cfif idType NEQ "collection_object_id">
        <cfset result="Only annotation of collection objects is supported at this time">
    <cfelse>
    	<cftry>
    	   <cfquery name="annotator" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                 select username, first_name, last_name, affiliation, email
                     from cf_users u left join cf_user_data ud on u.user_id = ud.user_id
                     where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
           </cfquery>
    	   <cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                 select 'MCZ:' || collection_cde || ':' || cat_num as guid
                     from cataloged_item
                     where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#idvalue#">
           </cfquery>
                <cfif idType EQ 'collection_object_id'>
                   <cfset targetType = 'collection_object_id'>
                <cfelse>
                   <cfset targetType = 'not_supported_field_query_fails'>
                </cfif>
    		<cfquery name="insAnn" datasource="uam_god">
    			insert into annotations (
    				cf_username,
    				#targetType#,
    				annotation
    			) values (
    				<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#session.username#' >,
    				<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#idvalue#' >,
    				<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='For #annotated.guid# #annotator.first_name# #annotator.last_name# #annotator.affiliation# #annotator.email# reported: #urldecode(annotation)#' >
    			)
    		</cfquery>
    		<cfquery name="whoTo" datasource="uam_god">
    			select
    				address
    			FROM
    				cataloged_item,
    				collection,
    				collection_contacts,
    				electronic_address
    			WHERE
    				cataloged_item.collection_id = collection.collection_id AND
    				collection.collection_id = collection_contacts.collection_id AND
    				collection_contacts.contact_agent_id = electronic_address.agent_id AND
    				collection_contacts.CONTACT_ROLE = 'data quality' and
    				electronic_address.ADDRESS_TYPE='e-mail' and
    				cataloged_item.collection_object_id= <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#idvalue#' >
    		</cfquery>
    		<cfset mailTo = valuelist(whoTo.address)>
    		<cfset mailTo=listappend(mailTo,Application.bugReportEmail,",")>
    		<cfmail to="#mailTo#" from="annotation@#Application.fromEmail#" subject="Annotation Submitted" type="html">
    			An MCZbase User: #session.username# (#annotator.first_name# #annotator.last_name# #annotator.affiliation# #annotator.email#) has submitted an annotation to report problematic data concerning #annotated.guid#.

    			<blockquote>
    				#annotation#
    			</blockquote>

    			View details at
    			<a href="#Application.ServerRootUrl#/info/reviewAnnotation.cfm?action=show&type=#idType#&id=#idvalue#">
    			#Application.ServerRootUrl#/info/annotate.cfm?action=show&type=#idType#&id=#idvalue#
    			</a>
    		</cfmail>
                <cfset newline= Chr(13) & Chr(10)>
                <cfset reported_name = "#annotator.first_name# #annotator.last_name# #annotator.affiliation#">
                <cfset summary=left("#annotated.guid# #annotation#",60)><!--- obtain the begining of the complaint as a bug summary --->
                <cfset bugzilla_mail="#Application.bugzillaToEmail#"><!--- address to access email_in.pl script --->
                <cfset bugzilla_user="#Application.bugzillaFromEmail#"><!--- bugs submitted by email can only come from a registered bugzilla user --->
                <cfmail to="#bugzilla_mail#" subject="#summary#" from="#bugzilla_user#" type="text">@rep_platform = PC
@op_sys = Linux
@product = MCZbase
@component = Data
@version = 2.5.1merge
@priority = P3
@bug_severity = enhancement

Bug report by: #reported_name# (Username: #session.username#)
Email: #annotator.email#
Complaint: #annotation#
#newline##newline#
Annotation to report problematic data concerning #annotated.guid#
                </cfmail>


    	    <cfset result = "success">
    	<cfcatch>
    		<cfset result = "A database error occured: #cfcatch.message# #cfcatch.detail#">
    	</cfcatch>
    	</cftry>
    </cfif>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="changeshowObservations" access="remote">
	<cfargument name="tgt" type="string" required="yes">
	<cfif tgt is "true">
		<cfset t = 1>
	<cfelse>
		<cfset t = 0>
	</cfif>
	<cftry>
		<cfquery name="up" datasource="cf_dbuser">
			UPDATE cf_users SET
				showObservations = #t#
			WHERE username = '#session.username#'
		</cfquery>
		<cfset session.showObservations = "#t#">
		<cfset result="success">
		<cfcatch>
			<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="saveSpecSrchPref" access="remote">
	<cfargument name="id" type="string" required="yes">
	<cfargument name="onOff" type="numeric" required="yes">
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
		<cftry>
			<cfquery name="ins" datasource="cf_dbuser">
				select specsrchprefs from cf_users
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfset cv=valuelist(ins.specsrchprefs)>
			<cfif onOff is 1>
				<cfif not listfind(cv,id)>
					<cfset nv=listappend(cv,id)>
					<cfquery name="ins" datasource="cf_dbuser">
						update cf_users set specsrchprefs='#nv#'
						where username='#session.username#'
					</cfquery>
				</cfif>
			<cfelse>
				<cfif listfind(cv,id)>
					<cfset nv=listdeleteat(cv,listfind(cv,id))>
					<cfquery name="ins" datasource="cf_dbuser">
						update cf_users set specsrchprefs='#nv#'
						where username='#session.username#'
					</cfquery>
				</cfif>
			</cfif>
			<cfquery name="ins" datasource="cf_dbuser">
				update cf_users set specsrchprefs= <cfqueryparam value="#nv#" CFSQLType="CF_SQL_VARCHAR">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfcatch><!-- nada --></cfcatch>
		</cftry>
		<cfreturn "saved">
	</cfif>
	<cfreturn "cookie,#id#,#onOff#">
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="saveSpecSrchPrefs" access="remote">
        <!--- Save a composed list of the sections on the specimen search for which to show more options. --->
	<cfargument name="onList" type="string" required="yes">
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
		<cftry>
			<cfquery name="ins" datasource="cf_dbuser">
				update cf_users set specsrchprefs= <cfqueryparam value="#onList#" CFSQLType="CF_SQL_VARCHAR">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfcatch>
                   <cfreturn "error">
                </cfcatch>
		</cftry>
		<cfreturn "saved">
	</cfif>
</cffunction>
<!------------------------------------->
<cffunction name="addSubLoanToLoan" access="remote">
        <cfargument name="transaction_id" type="string" required="yes">
        <cfargument name="subloan_transaction_id" type="string" required="yes">
        <cfquery name="addChildLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
           insert into loan_relations (transaction_id, related_transaction_id, relation_type)
               values (
               <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">,
               <cfqueryparam value = "#subloan_transaction_id#" CFSQLType="CF_SQL_DECIMAL">,
               'Subloan'
               )
        </cfquery>
        <cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
           select l.loan_number, l.transaction_id from loan_relations lr left join loan l on lr.related_transaction_id = l.transaction_id
               where lr.transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
               order by l.loan_number
        </cfquery>
        <cfreturn childLoans>
</cffunction>
<!------------------------------------->
<cffunction name="removeSubLoan" access="remote">
        <cfargument name="transaction_id" type="string" required="yes">
        <cfargument name="subloan_transaction_id" type="string" required="yes">
        <cfquery name="removeChildLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
           delete from loan_relations
               where transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL"> and
               related_transaction_id = <cfqueryparam value = "#subloan_transaction_id#" CFSQLType="CF_SQL_DECIMAL"> and
               relation_type = 'Subloan'
        </cfquery>
        <cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
           select l.loan_number, l.transaction_id from loan_relations lr left join loan l on lr.related_transaction_id = l.transaction_id
               where lr.transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
               order by l.loan_number
        </cfquery>
        <cfreturn childLoans>
</cffunction>
<!------------------------------------->
<!---
      @see findMediaSearchResults
      @see linkMediaRecord
--->
<cffunction name="linkMediaHtml" access="remote">
   <cfargument name="relationship" type="string" required="yes">
   <cfargument name="related_value" type="string" required="yes">
   <cfargument name="related_id" type="string" required="yes">
   <cfset target_id = related_id>
   <cfset target_relation = relationship>
   <cfset target_label = related_value>
   <cfset result = "">
   <cftry>
   <cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select media_type from ctmedia_type order by media_type
   </cfquery>
   <cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select mime_type from ctmime_type order by mime_type
   </cfquery>
    <cfset result = result & "
    <div id='mediaSearchForm'>
    Search for media. Any part of media uri accepted.<br>
    <form id='findMediaForm' onsubmit='return searchformedia(event);' >
        <input type='hidden' name='method' value='findMediaSearchResults'>
        <input type='hidden' name='returnformat' value='plain'>
        <input type='hidden' name='target_id' value='#target_id#'>
        <input type='hidden' name='target_relation' value='#target_relation#'>
        <table>

          <tr>
          <td colspan='3'>
             <label for='media_uri'>Media URI</label>
             <input type='text' name='media_uri' id='media_uri' size='90' value=''>
          </td>
          </tr>

          <tr>
          <td>
             <label for='mimetype'>MIME Type</label>
             <select name='mimetype' id='mimetype'>
               <option value=''></option>
    ">
               <cfloop query='ctmime_type'>

                 <cfset result = result & "<option value='#ctmime_type.mime_type#'>#ctmime_type.mime_type#</option>">
               </cfloop>
    <cfset result = result & "
             </select>
          </td>
          <td>
             <label for='mediatype'>Media Type</label>
             <select name='mediatype' id='mediatype'>
               <option value=''></option>
    ">
               <cfloop query='ctmedia_type'>
                 <cfset result = result & "<option value='#ctmedia_type.media_type#'>#ctmedia_type.media_type#</option>">
               </cfloop>
    <cfset result = result & "
             </select>
          </td>
          <td></td>
          </tr>
            <tr>
            <td>
               <span>
                 <input type='checkbox' name='unlinked' id='unlinked' value='true'>
                 <label style='display:contents;' for='unlinked'>Media not yet linked to any record</label>
               </span>
            </td>
            <td>
                <input type='submit' value='Search' class='schBtn'>
            </td>
            <td>
                <span ><input type='reset' value='Clear' class='clrBtn'>
		<input type='button' onClick=""opencreatemediadialog('newMediaDlg1_#target_id#','#target_label#','#target_id#','#relationship#',reloadTransMedia);"" value='Create Media' class='lnkBtn' >&nbsp;
                </span>
            </td>
            </tr>
        </table>
    </form>
    </div>
    <script language='javascript' type='text/javascript'>
        function searchformedia(event) {
           event.preventDefault();
           jQuery.ajax({
             url: '/component/functions.cfc',
             type: 'post',
             data: $('##findMediaForm').serialize(),
             success: function (data) {
                 $('##mediaSearchResults').html(data);
             },
             fail: function (jqXHR, textStatus) {
                 $('##mediaSearchResults').html('Error:' + textStatus);
             }
           });
           return false;
        };
        </script>
    <div id='newMediaDlg1_#target_id#'></div>
    <div id='mediaSearchResults'></div>
    " >
    <cfcatch>
      <cfset result = "Error: " & cfcatch.type & " " & cfcatch.message & " " &  cfcatch.detail >
    </cfcatch>
    </cftry>

   <cfreturn result>
</cffunction>
<!------------------------------------->
<!--- Given some basic query parameters for media records, find matching media records and return
      a list with controls to link those media records in a provided relation to a provided target
      @param target_relation the type of media relationship that is to be made.
      @param target_id the primary key of the related record that the media record is to be related to.
      @param mediatype the media type to search for, can be blank.
      @param mimetype the mime type of the media to search for, can be blank.
      @param media_uri the uri of the media record to search for, can be blank.
      @param unlinked if equal to the string literal 'true' then only return matching media records that lack relations, can be blank.
      @return html listing matching media records with 'add this media' buttons for each record or an error message.
      @see linkMediaRecord
--->
<cffunction name="findMediaSearchResults" access="remote">
   <cfargument name="target_relation" type="string" required="yes">
   <cfargument name="target_id" type="string" required="yes">
   <cfargument name="mediatype" type="string" required="no">
   <cfargument name="mimetype" type="string" required="no">
   <cfargument name="media_uri" type="string" required="no">
   <cfargument name="unlinked" type="string" required="no">
   <cfset result = "">
   <cftry>
    <cfquery name="matchMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select distinct media.media_id, media_uri uri, preview_uri, mime_type, media_type,
               MCZBASE.get_medialabel(media.media_id,'description') description
        from media
          <cfif isdefined("unlinked") and unlinked EQ "true">
             left join media_relations on media.media_id = media_relations.media_id
          </cfif>
        where
          media.media_id is not null
          <cfif isdefined("mediatype") and len(mediatype) gt 0>
            and media_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mediatype#">
          </cfif>
          <cfif isdefined("mimetype") and len(mimetype) gt 0>
            and mime_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mimetype#">
          </cfif>
          <cfif isdefined("media_uri") and len(media_uri) gt 0>
            and media_uri like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#media_uri#%">
          </cfif>
          <cfif isdefined("unlinked") and unlinked EQ "true">
            and media_relations.media_id is null
          </cfif>
    </cfquery>

    <cfset i=1>
    <cfif matchMedia.recordcount eq 0>
       <cfset result = "No matching media records found">
    <cfelse>
    <cfloop query="matchMedia">
        <cfset result = result & "<div">
          <cfif (i MOD 2) EQ 0>
             <cfset result = result & "class='evenRow'">
          <cfelse>
             <cfset result = result & "class='oddRow'">
          </cfif>
        <cfset result = result & "
        <form id='pickForm#target_id#_#i#'>
            <input type='hidden' value='#target_relation#' name='target_relation'>
            <input type='hidden' name='target_id' value='#target_id#'>
            <input type='hidden' name='media_id' value='#media_id#'>
            <input type='hidden' name='Action' value='addThisOne'>
            <div><a href='#uri#'>#uri#</a></div><div>#description# #mime_type# #media_type#</div><div><a href='/media/#media_id#' target='_blank'>Media Details</a></div>
        <div id='pickResponse#target_id#_#i#'>
            <input type='button'
            onclick='linkmedia(#media_id#,#target_id#,""#target_relation#"",""pickResponse#target_id#_#i#"");' value='Add this media'>
        </div>
        <hr>
        </form>
        <script language='javascript' type='text/javascript'>
        $('##pickForm#target_id#_#i#').removeClass('ui-widget-content');
        function linkmedia(media_id, target_id, target_relation, div_id) {
          jQuery.ajax({
             url: '/component/functions.cfc',
             type: 'post',
             data: {
                method: 'linkMediaRecord',
                returnformat: 'plain',
                target_relation: target_relation,
                target_id: target_id,
                media_id: media_id
            },
            success: function (data) {
                $('##'+div_id).html(data);
            },
            fail: function (jqXHR, textStatus) {
                $('##'+div_id).html('Error:' + textStatus);
            }
          });
        };
        </script>
        </div>">
        <cfset i=i+1>
    </cfloop>
    </cfif>
    <cfcatch>
        <cfset result = "Error: " & cfcatch.type & " " & cfcatch.message & " " &  cfcatch.detail >
    </cfcatch>
    </cftry>
    <cfreturn result>
</cffunction>
<!------------------------------------->
<!--- Given a relationship, primary key to link to, and media_id, create a media relation by
      performing an insert into media_relations.
      @return text indicating action performed or an error message.
  --->
<cffunction name="linkMediaRecord" access="remote">
   <cfargument name="target_relation" type="string" required="yes">
   <cfargument name="target_id" type="string" required="yes">
   <cfargument name="media_id" type="string" required="yes">
   <cfset result = "">
   <cftry>
            <cfquery name="addMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addMediaResult">
                INSERT INTO media_relations (media_id, related_primary_key, media_relationship,created_by_agent_id) VALUES (
                  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
                  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">,
                  <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#target_relation#">,
                  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">)
            </cfquery>
            <cfset result = "Added media #media_id# in relationship #target_relation# to #target_id#.">
    <cfcatch>
        <cfset result = "Error: " & cfcatch.type & " " & cfcatch.message & " " &  cfcatch.detail >
    </cfcatch>
    </cftry>
    <cfreturn result>
</cffunction>
<!------------------------------------->
<cffunction name="createMediaHtml" access="remote">
   <cfargument name="relationship" type="string" required="yes">
   <cfargument name="related_value" type="string" required="yes">
   <cfargument name="related_id" type="string" required="yes">
   <cfargument name="collection_object_id" type="string" required="no">
   <cfset result = "">
   <cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select media_relationship from ctmedia_relationship order by media_relationship
   </cfquery>
   <cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select media_label from ctmedia_label order by media_label
   </cfquery>
   <cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select media_type from ctmedia_type order by media_type
   </cfquery>
   <cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select mime_type from ctmime_type order by mime_type
   </cfquery>
   <cfquery name="ctmedia_license" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select media_license_id,display media_license from ctmedia_license order by media_license_id
   </cfquery>

   <!---  TODO: Changed from post to media.cfm to ajax save operation.  --->
   <cfset result = result & '
      <div>
          <h2 class="wikilink">Create Media <img src="/images/info_i.gif" onClick="getMCZDocs(''Media'')" class="likeLink" alt="[ help ]"></h2>
          <div style="border: 1px dotted gray; background-color: ##f8f8f8;padding: 1em;margin: .5em 0 1em 0;">
    <form name="newMedia" id="newMedia">
      <input type="hidden" name="action" value="saveNew">
      <input type="hidden" name="headless" value="true">
      <input type="hidden" id="number_of_relations" name="number_of_relations" value="1">
      <input type="hidden" id="number_of_labels" name="number_of_labels" value="1">
      <label for="media_uri">Media URI</label>
      <input type="text" name="media_uri" id="media_uri" size="105" class="reqdClr" required>
      <!--- <span class="infoLink" id="uploadMedia">Upload</span> --->
      <label for="preview_uri">Preview URI</label>
      <input type="text" name="preview_uri" id="preview_uri" size="105">
      <label for="mime_type">MIME Type</label>
      <select name="mime_type" id="mime_type" class="reqdClr" style="width: 160px;" required>
        <option value=""></option>'>
        <cfloop query="ctmime_type">
          <cfset result = result & "<option value='#mime_type#'>#mime_type#</option>">
        </cfloop>
      <cfset result = result & '
      </select>
      <label for="media_type">Media Type</label>
      <select name="media_type" id="media_type" class="reqdClr" style="width: 160px;" required>
        <option value=""></option>'>
        <cfloop query="ctmedia_type">
          <cfset result = result & '<option value="#media_type#">#media_type#</option>' >
        </cfloop>
      <cfset result = result & '
      </select>
      <div class="license_box" style="padding-bottom: 1em;padding-left: 1.15em;">
        <label for="media_license_id">License</label>
        <select name="media_license_id" id="media_license_id" style="width:300px;">
          <option value="">Research copyright &amp; then choose...</option>'>
          <cfloop query="ctmedia_license">
             <cfset result = result & '<option value="#media_license_id#">#media_license#</option>'>
          </cfloop>
        <cfset result = result & '
        </select>
        <a class="infoLink" onClick="popupDefine()">Define Licenses</a><br/>
        <ul class="lisc">
            <p>Notes:</p>
          <li>media should not be uploaded until copyright is assessed and, if relevant, permission is granted (<a href="https://code.mcz.harvard.edu/wiki/index.php/Non-MCZ_Digital_Media_Licenses/Assignment" target="_blank">more info</a>)</li>
          <li>remove media immediately if owner requests it</li>
          <li>contact <a href="mailto:mcz_collections_operations@oeb.harvard.edu?subject=media licensing">MCZ Collections Operations</a> if additional licensing situations arise</li>
        </ul>
      </div>
      <label for="mask_media_fg">Media Record Visibility</label>
      <select name="mask_media_fg" value="mask_media_fg">
           <option value="0" selected="selected">Public</option>
           <option value="1">Hidden</option>
      </select>

      <label for="relationships" style="margin-top:.5em;">Media Relationships</label>
      <div id="relationships" class="graydot">
        <div id="relationshiperror"></div>
        <select name="relationship__1" id="relationship__1" size="1" onchange="pickedRelationship(this.id)" style="width: 200px;">
          <option value="">None/Unpick</option>'>
          <cfloop query="ctmedia_relationship">
            <cfset result = result & '<option value="#media_relationship#">#media_relationship#</option>'>
          </cfloop>
        <cfset result = result & '
        </select>
        :&nbsp;
        <input type="text" name="related_value__1" id="related_value__1" size="70" readonly>
        <input type="hidden" name="related_id__1" id="related_id__1">
       <br>
        <span class="infoLink" id="addRelationship" onclick="addRelation(2)">Add Relationship</span> </div>

      <label for="labels" style="margin-top:.5em;">Media Labels</label>
      <p>Note: For media of permits, correspondence, and other transaction related documents, please enter a "description" media label.</p>
      <div id="labels" class="graydot">
        <div id="labelsDiv__1">
          <select name="label__1" id="label__1" size="1" style="width: 200px;">
            <option value=""></option>'>
            <cfloop query="ctmedia_label">
              <cfset result = result & '<option value="#media_label#">#media_label#</option>'>
            </cfloop>
          <cfset result = result & '
          </select>
          :&nbsp;
          <input type="text" name="label_value__1" id="label_value__1" size="70">&nbsp;
            <br><span class="infoLink" id="addLabel" onclick="addLabel(2)">Add Label</span>
      </div>

       </div>
        </div>
    </form>'>
    <cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
       <cfquery name="s"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
          select guid from flat where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
       </cfquery>
       <cfset result = result & '
       <script language="javascript" type="text/javascript">
          $("##relationship__1").val("shows cataloged_item");
          $("##related_value__1").val("#s.guid#");
          $("##related_id__1").val("#collection_object_id#");
       </script>'>
    </cfif>
    <cfif isdefined("relationship") and len(relationship) gt 0>
      <cfquery name="s"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	  select media_relationship from ctmedia_relationship where media_relationship= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
      </cfquery>
      <cfif s.recordCount eq 1 >
       <cfset result = result & '
         <script language="javascript" type="text/javascript">
            $("##relationship__1").val("#relationship#");
            $("##related_value__1").val("#related_value#");
            $("##related_id__1").val("#related_id#");
         </script>'>
      <cfelse>
       <cfset result = result & '
          <script language="javascript" type="text/javascript">
				$("##relationshiperror").html("<h2>Error: Unknown media relationship type #relationship#</h2>");
         </script>'>
      </cfif>
    </cfif>
    <cfset result = result & '</div>'>

   <cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getMediaOfPermit" access="remote">
	<cfargument name="permitid" type="string" required="yes">
	<cfargument name="correspondence" type="string" required="no">
	<cfset theResult=queryNew("media_id,collection_object_id,media_relationship")>
	<cfset r=1>
	<cfif isdefined("correspondence") and len(#correspondence#) gt 0>
       <cfset relation = "document for permit">
    <cfelse>
       <cfset relation = "shows permit">
    </cfif>
	<cftry>
	        <cfset threadname = "getMediaPermitThread">
	        <cfthread name="#threadname#" >
		   <cfloop list="#idList#" index="cid">
			<cfloop list="#tableList#" index="tabl">
				<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                    select media.media_id, preview_uri, media.media_uri, media.mime_type, media.media_type,
                           MCZBASE.is_media_encumbered(media.media_id) as hideMedia
                       from media_relations left join media on media_relations.media_id = media.media_id
                       where media_relations.media_relationship = <cfqueryparam value="#relation#" CFSQLType="CF_SQL_VARCHAR">
                             and media_relations.related_primary_key = <cfqueryparam value="#permitid#" CFSQLType="CF_SQL_DECIMAL">
				</cfquery>
				<cfif len(mid.midList) gt 0>
					<cfset t = queryaddrow(theResult,1)>
					<cfset t = QuerySetCell(theResult, "media_id", "#mid.media_id#", r)>
					<cfset t = QuerySetCell(theResult, "preview_uri", "#mid.preview_uri#", r)>
					<cfset t = QuerySetCell(theResult, "media_uri", "#mid.media_uri#", r)>
					<cfset t = QuerySetCell(theResult, "mime_type", "#mid.mime_type#", r)>
					<cfset t = QuerySetCell(theResult, "media_type", "#mid.media_type#", r)>
					<cfset t = QuerySetCell(theResult, "hide_media", "#mid.hide_media#", r)>
					<cfset r=r+1>
				</cfif>
			</cfloop>
		   </cfloop>
	        </cfthread>
        	<cfthread action="join" name="#threadname#" />
		<cfif theResult.recordcount eq 0>
	  	  <cfset theResult=queryNew("status, message")>
		  <cfset t = queryaddrow(theResult,1)>
		  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResult, "message", "No media found.", 1)>
		</cfif>
	<cfcatch>
	   	<cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
		<cfreturn craps>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>
<!-------------------------------------------->
<!--- Obtain the ranks for an agent --->
<!--- @param agent_id the agent for whom to retrieve the ranks --->
<!--- @return data structure containing ct, agent_rank, and status (1 on success) (count of that rank for the agent and the rank) --->
<cffunction name="getAgentRanks" access="remote">
        <cfargument name="agent_id" type="string" required="yes">
        <cfif listcontainsnocase(session.roles,"admin_transactions")>
		<cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select count(*) ct, agent_rank agent_rank, 1 as status from agent_rank
                        where agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
                        group by agent_rank
		</cfquery>
        <cfelse>
	   	<cfset rankCount=queryNew("status, message")>
		<cfset t = queryaddrow(rankCount,1)>
		<cfset t = QuerySetCell(rankCount, "status", "-1", 1)>
		<cfset t = QuerySetCell(rankCount, "message", "Not Authorized", 1)>
        </cfif>
        <cfreturn rankCount>
</cffunction>
<!-------------------------------------------->
<!--- obtain counts of deaccession items --->
<cffunction name="getDeaccItemCounts" access="remote">
        <cfargument name="transaction_id" type="string" required="yes">
        <cfif listcontainsnocase(session.roles,"admin_transactions")>
                <cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select
		1 as status,
                count(distinct cataloged_item.collection_object_id) catItemCount,
                count(distinct collection.collection_cde) as collectionCount,
                count(distinct preserve_method) as preserveCount,
                count(distinct specimen_part.collection_object_id) as partCount
         from
                deacc_item,
                deaccession,
                specimen_part,
                coll_object,
                cataloged_item,
                coll_object_encumbrance,
                encumbrance,
                agent_name,
                identification,
                collection,
        accn
        WHERE
                deacc_item.collection_object_id = specimen_part.collection_object_id AND
                deaccession.transaction_id = deacc_item.transaction_id AND
                specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
                specimen_part.collection_object_id = coll_object.collection_object_id AND
                cataloged_item.collection_object_id = coll_object_encumbrance.collection_object_id (+) and
                coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND
                encumbrance.encumbering_agent_id = agent_name.agent_id (+) AND
                cataloged_item.collection_object_id = identification.collection_object_id AND
                identification.accepted_id_fg = 1 AND
                cataloged_item.collection_id=collection.collection_id AND
                cataloged_item.accn_id = accn.transaction_id AND
                deacc_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
                </cfquery>
        <cfelse>
                <cfset rankCount=queryNew("status, message")>
                <cfset t = queryaddrow(rankCount,1)>
                <cfset t = QuerySetCell(rankCount, "status", "-1", 1)>
                <cfset t = QuerySetCell(rankCount, "message", "Not Authorized", 1)>
        </cfif>
        <cfreturn rankCount>
</cffunction>
<!-------------------------------------------->
<!--- obtain counts of loan items --->
<cffunction name="getLoanItemCounts" access="remote">
        <cfargument name="transaction_id" type="string" required="yes">
        <cfif listcontainsnocase(session.roles,"admin_transactions")>
                <cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select
		1 as status,
                count(distinct cataloged_item.collection_object_id) catItemCount,
                count(distinct collection.collection_cde) as collectionCount,
                count(distinct preserve_method) as preserveCount,
                count(distinct specimen_part.collection_object_id) as partCount
        from
                loan_item,
                loan,
                specimen_part,
                coll_object,
                cataloged_item,
                coll_object_encumbrance,
                encumbrance,
                agent_name,
                identification,
                collection
        WHERE
                loan_item.collection_object_id = specimen_part.collection_object_id AND
                loan.transaction_id = loan_item.transaction_id AND
                specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
                specimen_part.collection_object_id = coll_object.collection_object_id AND
                coll_object.collection_object_id = coll_object_encumbrance.collection_object_id (+) and
                coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND
                encumbrance.encumbering_agent_id = agent_name.agent_id (+) AND
                cataloged_item.collection_object_id = identification.collection_object_id AND
                identification.accepted_id_fg = 1 AND
                cataloged_item.collection_id=collection.collection_id AND
                loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
                </cfquery>
        <cfelse>
                <cfset rankCount=queryNew("status, message")>
                <cfset t = queryaddrow(rankCount,1)>
                <cfset t = QuerySetCell(rankCount, "status", "-1", 1)>
                <cfset t = QuerySetCell(rankCount, "message", "Not Authorized", 1)>
        </cfif>
        <cfreturn rankCount>
</cffunction>


<!----------------------------------------------------------------------------------------------------------------->
</cfcomponent>
