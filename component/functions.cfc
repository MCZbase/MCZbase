<cfcomponent>
<cfinclude template = "../includes/functionLib.cfm">
<!------------------------------------------------------------------->
<cffunction name="getExternalStatus" access="remote">
	<cfargument name="uri" type="string" required="yes">
	<cfhttp url="#uri#" method="head"></cfhttp>
	<cfreturn left(cfhttp.statuscode,3)>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="getPartByContainer" access="remote">
	<cfargument name="barcode" type="string" required="yes">
	<cfargument name="i" type="string" required="yes">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		  	p1.barcode='#barcode#'
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
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="isCtControlled" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select VALUE_CODE_TABLE,UNITS_CODE_TABLE from ctattribute_code_tables where attribute_type='#attribute#'
	</cfquery>
	<cfif isCtControlled.recordcount is 1>
		<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
			<cfquery name="getCols" datasource="uam_god">
				select column_name from sys.user_tab_columns where table_name='#ucase(isCtControlled.value_code_table)#'
				and column_name <> 'DESCRIPTION'
			</cfquery>
			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select container_id from container where barcode='#barcode#'
		</cfquery>
		<cfif c.recordcount is 1>
			<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select container_id from container where barcode='#barcode#'
		</cfquery>
		<cfif c.recordcount is 1>
			<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from ctspec_part_att_att where attribute_type='#patype#'
	</cfquery>
	<cfif len(k.VALUE_code_table) gt 0>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select trans_agent_role from cttrans_agent_role where trans_agent_role != 'entered by' order by trans_agent_role
	</cfquery>
	<cfreturn k>
</cffunction>

<!------------------------------------------------------->

<cffunction name="getBorrowItems" access="remote">
        <cfargument name="transaction_id" type="numeric" required="yes">
        <cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
       <cfquery name="newBorrow_Item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newBorrow_ItemRes">
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
       <cfquery name="newBorrow_Item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newBorrow_ItemRes">
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
        <cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="checkAgentQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select MCZBASE.get_worstagentrank(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">) as agentrank from dual 
	</cfquery>
	<cfreturn checkAgentQuery>
</cffunction>


<!------------------------------------------------------->
<cffunction name="insertAgentName" access="remote">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="id" type="numeric" required="yes">
	<cftry>
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select somerandomsequence.nextval c from dual
			</cfquery>
			<cfset key=k.c>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="idby" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				<cfquery name="iidby" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update bulkloader set ID_MADE_BY_AGENT='#idby.agent_name#'
					where collection_object_id=#key#
				</cfquery>
			<cfelse>
				<cfset problem="too many identifiers: #valuelist(idby.agent_name)#">
			</cfif>
			<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				<cfquery name="ioid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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

			<cfquery name="col" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				<cfquery name="icoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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


			<cfquery name="part" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				<cfquery name="ipart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					#preservesinglequotes(sql)#
				</cfquery>
			</cfif>
			<cfif part.recordcount gt 12>
				<cfset problem="too many part: #valuelist(part.part_name)#">
			</cfif>



			<cfquery name="att" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				<cfquery name="iatt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					#preservesinglequotes(sql)#
				</cfquery>
			</cfif>
			<cfif att.recordcount gt 4>
				<cfset problem="too many attribute: #valuelist(att.ATTRIBUTE_TYPE)#">
			</cfif>
			<cfquery name="irel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
<!------------------------------------------------------->
<cffunction name="getPubAttributes" access="remote">
	<cfargument name="attribute" type="string" required="yes">
	<cftry>
		<cfquery name="res" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select control from ctpublication_attribute where publication_attribute ='#attribute#'
		</cfquery>
		<cfif len(res.control) gt 0>
			<cfquery name="ctval" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from #res.control#
			</cfquery>
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
		<cfquery name="res" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cftry>
			<cfquery name="ins" datasource="cf_dbuser">
				select LOCSRCHPREFS from cf_users
				where username='#session.username#'
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
				update cf_users set LOCSRCHPREFS='#nv#'
				where username='#session.username#'
			</cfquery>
			<cfset session.locSrchPrefs=nv>
			<cfcatch><!-- nada --></cfcatch>
		</cftry>
	</cfif>
	<cfreturn 1>
</cffunction>
<!------------------------------------------->
<cffunction name="updatePartDisposition" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="disposition" type="string" required="yes">
	<cftry>
		<cfquery name="upPartDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from loan_item where
				collection_object_id = #part_id# and
				transaction_id=#transaction_id#
			</cfquery>
			<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from deacc_item where
				collection_object_id = #part_id# and
				transaction_id=#transaction_id#
			</cfquery>
			<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
<cffunction name="getDeaccMediaHtml" returntype="string" access="remote" returnformat="plain">
   <cfargument name="transaction_id" type="string" required="yes">
   <cfset result="">
   <cfquery name="deaccDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                select
            trans.transaction_id,
                        trans.trans_date,
                        deaccession.deacc_number,
                        deaccession.deacc_type,
                        deaccession.deacc_status,
            deaccession.value,
            deaccession.method,
                        deaccession.deacc_reason,
                        trans.nature_of_material,
                        trans.trans_remarks,
                        to_char(closed_date, 'YYYY-MM-DD') closed_date,
                        trans.collection_id,
                        collection.collection,
                        concattransagent(trans.transaction_id,'entered by') enteredby
                 from
                        deaccession,
                        trans,
                        collection
                where
                        deaccession.transaction_id = trans.transaction_id AND
                        trans.collection_id=collection.collection_id and
                        trans.transaction_id = <cfqueryparam value="#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
   </cfquery>
   <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
           select distinct
               media.media_id as media_id,
               preview_uri,
               media.media_uri,
               media.mime_type,
               media.media_type as media_type,
               MCZBASE.is_media_encumbered(media.media_id) as hideMedia,
               label_value
           from
               media_relations left join media on media_relations.media_id = media.media_id
               left join media_labels on media.media_id = media_labels.media_id
           where
               media_relationship like '% deaccession' and
               (media_label = 'description' or media_label is null )
               and media_relations.related_primary_key = <cfqueryparam value="#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
   </cfquery>
   <cfif query.recordcount gt 0>
       <cfset result=result & "<ul>">
       <cfloop query="query">
          <cfset puri=getMediaPreview(preview_uri,media_type) >
          <cfset result = result & "<li><a href='#media_uri#'><img src='#puri#' height='50'></a> #mime_type# #media_type# #label_value# <a href='/media/#media_id#' target='_blank'>Media Details</a>  <a onClick='  confirmAction(""Remove this media from this deaccession?"", ""Confirm Unlink Media"", function() { deleteMediaFromDeacc(#media_id#,#transaction_id#,""shows deaccession""); } ); '>Remove</a> </li>" >
       </cfloop>
       <cfset result= result & "</ul>">
   <cfelse>
       <cfset result=result & "<ul><li>None</li></ul>">
   </cfif>
   <cfset result = result & "<span class='likeLink' onclick=""addMediaHere('#deaccDetails.collection# #deaccDetails.deacc_number#','#transaction_id#');"">Create Media</span> ">
   <cfset result = result & "</span>&nbsp;~&nbsp;">
   <cfset result = result & "<span id='addDeacc_#transaction_id#'><input type='button' style='margin-left: 30px;' value='Link Media' class='lnkBtn' onClick=""opendialogcallback('picks/MediaPick.cfm?target_id=#transaction_id#&target_relation=shows deaccession','addDeaccDlg_#transaction_id#','Pick Media for Deaccession', reloadDeaccessionMedia ); "" ></div><div id='addDeaccDlg_#transaction_id#'></div></span>">
   <cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="removeMediaFromDeaccession" returntype="query" access="remote">
        <cfargument name="transaction_id" type="string" required="yes">
        <cfargument name="media_id" type="string" required="yes">
        <cfargument name="media_relationship" type="string" required="yes">
        <cfset r=1>
        <cftry>
            <cfquery name="deleteResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
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
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="thisID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select container_id,label from container where barcode='#barcode#'
			AND container_type = 'cryovial'
		</cfquery>
		<cfif #thisID.recordcount# is 0>
			<cfquery name="thisID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select container_id,label from container where barcode='#barcode#'
				AND container_type = 'cryovial label'
			</cfquery>
			<cfif #thisID.recordcount# is 1>
				<cfquery name="update" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update container set container_type='cryovial'
					where container_id=#thisID.container_id#
				</cfquery>
				<cfset thisContainerId = #thisID.container_id#>
			</cfif>
		<cfelse>
			<cfset thisContainerId = #thisID.container_id#>
		</cfif>

		<cfif len(#thisContainerId#) gt 0>
			<cfquery name="putItIn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into cf_form_permissions (form_path,role_name) values ('#form#','#role#')
		</cfquery>
	<cfelseif onoff is "false">
		<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="isGoodParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select container_id from container where container_type <> 'collection object'
				and barcode='#parent_barcode#'
			</cfquery>
			<cfif #isGoodParent.recordcount# is not 1>
				<cfreturn "0|Parent container (barcode #parent_barcode#) not found.">
			</cfif>
			<cfquery name="cont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select container_id FROM coll_obj_cont_hist where collection_object_id=#part_id#
			</cfquery>
			<cfif #cont.recordcount# is not 1>
				<cfreturn "0|Yikes! A part is not a container.">
			</cfif>
			<cfquery name="newparent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE container SET container_type = '#new_container_type#' WHERE
					container_id=#isGoodParent.container_id#
			</cfquery>
			<cftransaction action="commit" />
			<cfquery name="moveIt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE container SET parent_container_id = #isGoodParent.container_id# WHERE
				container_id=#cont.container_id#
			</cfquery>
			<cfif len(#part_id2#) gt 0>
				<cfquery name="cont2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select container_id FROM coll_obj_cont_hist where collection_object_id=#part_id2#
				</cfquery>
				<cfquery name="moveIt2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE container SET parent_container_id = #isGoodParent.container_id# WHERE
					container_id=#cont2.container_id#
				</cfquery>
			</cfif>
		</cftransaction>
		<cfquery name="coll_obj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfinclude template="/includes/functionLib.cfm">
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
		<cfquery name="accn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			Select * from (
				Select a.*, rownum rnum From (
					select * from #session.SpecSrchTab# order by #orderBy#
				) a where rownum <= #stoprow#
			) where rnum >= #startrow#
		</cfquery>
		<cfset collObjIdList = valuelist(result.collection_object_id)>
		<cfset session.collObjIdList=collObjIdList>
		<cfquery name="cols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="ccid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_collection_object_id.nextval nv from dual
			</cfquery>
			<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
					VALUES (#ccid.nv#, '#coll_object_remarks#')
				</cfquery>
			</cfif>
			<cfif len(barcode) gt 0>
				<cfquery name="np" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select container_id from coll_obj_cont_hist where collection_object_id=#ccid.nv#
				</cfquery>
				<cfquery name="pc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select container_id from container where barcode='#barcode#'
				</cfquery>
				<cfquery name="m2p" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update container set parent_container_id=#pc.container_id# where container_id=#np.container_id#
				</cfquery>
				<cfif len(new_container_type) gt 0>
					<cfquery name="uct" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			cataloged_item.collection_object_id, specimen_part.part_name
	</cfquery>
	<cfreturn result>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getDeaccPartResults" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfoutput>
	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_collection_object_id.nextval n from dual
			</cfquery>
			<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="newCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="addLoanItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_collection_object_id.nextval n from dual
			</cfquery>
			<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="newCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="decrementParentLotCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE coll_object set LOT_COUNT = LOT_COUNT -1, 
					LAST_EDITED_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
					LAST_EDIT_DATE = sysdate
				where COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#"> 
					and LOT_COUNT > 1
			</cfquery>
			<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="newRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO coll_object_remark (
					COLLECTION_OBJECT_ID,
 					COLL_OBJECT_REMARKS )
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#n.n#">, 
					'Deaccessioned Subsample')
			</cfquery>
		</cfif>
		<cfquery name="addDeaccItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE coll_object SET coll_obj_disposition = 'deaccessioned'
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
				<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
<cffunction name="getTypes" access="remote">
	<cfargument name="idList" type="string" required="yes">
	<cfset theResult=queryNew("collection_object_id,typeList")>
	<cfset r=1>
	<cftry>
	        <cfset threadname = "getTypesThread">
	        <cfthread name="#threadname#" >
		   <cfloop list="#idList#" index="cid">
			<cfquery name="ts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select  type_status || decode(count(*),1,'','(' || count(*) || ')') type_status from citation where collection_object_id=#cid# group by type_status
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

<!----------------------------------------------------------------------------------------------------------------->
<!--- get permits as query json objects by a list of permit ids
      @param permitIdList a comma delimited list of permit_id values.
      @return a query object containing permit records (with status=1) or containing status=0|-1 and message.
--->
<cffunction name="getPermits" returntype="query" access="remote">
   <cfargument name="permitidList" type="string" required="yes">
   <cftry>
      <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
   <cftry>
      <cfif permit_id EQ "">
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
      <cfset t = queryaddrow(theResult,1)>
      <cfset t = QuerySetCell(theResult, "status", "1", 1)>
      <cfset t = QuerySetCell(theResult, "message", "Saved.", 1)>
	<cfcatch>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "0", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	</cfcatch>
      </cftry>
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
       <cfset heading = "Permit">
   </cfif>
   <cfset result="">
     <cfquery name="permitInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
   <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select distinct media.media_id as media_id, preview_uri, media.media_uri, media.mime_type, media.media_type as media_type,
               MCZBASE.is_media_encumbered(media.media_id) as hideMedia
         from media_relations left join media on media_relations.media_id = media.media_id
         where media_relations.media_relationship = <cfqueryparam value="#relation#" CFSQLType="CF_SQL_VARCHAR">
               and media_relations.related_primary_key = <cfqueryparam value="#permit_id#" CFSQLType="CF_SQL_DECIMAL">
   </cfquery>
   <cfset result="<h3>#heading# Media</h3>">
   <cfif query.recordcount gt 0>
       <cfset result=result & "<ul>">
       <cfloop query="query">
          <cfset puri=getMediaPreview(preview_uri,media_type) >
          <cfset result = result & "<li><a href='#media_uri#'><img src='#puri#' height='50'></a> #mime_type# #media_type# <a href='/media/#media_id#' target='_blank'>Media Details</a>  <a onClick='  confirmAction(""Remove this media from this permit (#relation#)?"", ""Confirm Unlink Media"", function() { deleteMediaFromPermit(#media_id#,#permit_id#,""#relation#""); } ); '>Remove</a> </li>" >
       </cfloop>
       <cfset result= result & "</ul>">
   <cfelse>
      <cfset result = result & "<span class='likeLink' onclick=""addMediaHere('#permitInfo.permit_Type# #permitInfo.IssuedByAgent# #permitInfo.permit_Num#','#permit_id#');"">Create Media">
      <cfset result = result & "</span>&nbsp;~&nbsp;">
      <cfset result = result & "<span id='addPermit_#permit_id#'><input type='button' style='margin-left: 30px;' value='Link Media' class='lnkBtn' onClick=""opendialog('picks/MediaPick.cfm?target_id=#permit_id#&target_relation=#urlEncodedFormat(relation)#','##addPermitDlg_#permit_id#','Pick Media for Permit'); "" ></div><div id='addPermitDlg_#permit_id#'></div></span>">
   </cfif>
   <cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="removeMediaFromPermit" returntype="query" access="remote">
        <cfargument name="permit_id" type="string" required="yes">
        <cfargument name="media_id" type="string" required="yes">
        <cfargument name="media_relationship" type="string" required="yes">
        <cfset r=1>
        <cftry>
            <cfquery name="deleteResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
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
   Function to create save a shipment from a ajax post
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
         <cfset debug = shipment_id & "Insert" >
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             insert into shipment (
                transaction_id, packed_by_agent_id, shipped_carrier_method, carriers_tracking_number, shipped_date, package_weight,
                <cfif isdefined("no_of_packages") and len(#no_of_packages#) gt 0>
                  no_of_packages,
                </cfif>
                <cfif isdefined("insured_for_insured_value") and len(#insured_for_insured_value#) gt 0>
                  insured_for_insured_value,
                </cfif>
                hazmat_fg, shipment_remarks, contents, foreign_shipment_fg,
                shipped_to_addr_id, shipped_from_addr_id
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
                   <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#insured_for_insured_value#" null="yes">,
                </cfif>
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hazmat_fg#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipment_remarks#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#contents#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#foreign_shipment_fg#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_to_addr_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_from_addr_id#">
             )
         </cfquery>
      <cfelse>
         <cfset debug = shipment_id & "Update" >
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
   <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
          <cfset result = result & "<li>#permit_type# #permit_num# Issued:#dateformat(issued_date,'yyyy-mm-dd')# #IssuedByAgent#</li>">
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
            <cfquery name="deleteResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResultRes">
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
            <cfquery name="countPermits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
             select count(*) as ct from permit_shipment
             where shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
            </cfquery>
            <cfif countPermits.ct EQ 0 >
               <cfquery name="deleteResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
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
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		   select 1 as status, shipment_id, transaction_id,
                   packed_by_agent_id, mczbase.get_agentnameoftype(packed_by_agent_id,'preferred') packed_by_agent, carriers_tracking_number,
                   shipped_carrier_method, to_char(shipped_date, 'yyyy-mm-dd') as shipped_date, package_weight, no_of_packages,
                   hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id,
                   shipped_from_addr_id, fromaddr.formatted_addr as shipped_from_address, toaddr.formatted_addr as shipped_to_address
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
	    <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 1 as status, shipment_id, packed_by_agent_id, shipped_carrier_method, shipped_date, package_weight, no_of_packages,
                   hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id,
                   shipped_from_addr_id, fromaddr.formatted_addr, toaddr.formatted_addr
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
   <cftry>
       <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
         select 1 as status, shipment_id, packed_by_agent_id, shipped_carrier_method, shipped_date, package_weight, no_of_packages,
                   hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id, carriers_tracking_number,
                   shipped_from_addr_id, fromaddr.formatted_addr, toaddr.formatted_addr,
                   toaddr.country_cde tocountry, toaddr.institution toinst, toaddr.formatted_addr tofaddr, 
                   fromaddr.country_cde fromcountry, fromaddr.institution frominst, fromaddr.formatted_addr fromfaddr
             from shipment
                  left join addr fromaddr on shipment.shipped_from_addr_id = fromaddr.addr_id
                  left join addr toaddr on shipment.shipped_to_addr_id = toaddr.addr_id
             where shipment.transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
      </cfquery>
      <cfset resulthtml = "<div id='shipments'> ">
          
      <cfloop query="theResult">
         <cfquery name="shippermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
         <cfset resulthtml = resulthtml & "<div class='shipment'>" >
            <cfset resulthtml = resulthtml & "<ul class='shipheaders'><li>Ship Date:</li><li>Method:</li><li>Packages:</li><li>Tracking Number:</li></ul>">
            <cfset resulthtml = resulthtml & " <ul class='shipdata'>" >
                <cfset resulthtml = resulthtml & "<li>#dateformat(shipped_date,'yyyy-mm-dd')#</li> " >
                <cfset resulthtml = resulthtml & " <li>#shipped_carrier_method#</li> " >
                <cfset resulthtml = resulthtml & " <li>#no_of_packages#</li> " >
                <cfset resulthtml = resulthtml & " <li>#carriers_tracking_number#</li>">
            <cfset resulthtml = resulthtml & "</ul>">
            <cfset resulthtml = resulthtml & "<ul class='shipaddresseshead'><li>Shipped To:</li><li>Shipped From:</li></ul>">
            <cfset resulthtml = resulthtml & " <ul class='shipaddressesdata'>">
                <cfset resulthtml = resulthtml & "<li>#tofaddr#</li> ">
                <cfset resulthtml = resulthtml & " <li>#fromfaddr#</li>">
            <cfset resulthtml = resulthtml & "</ul>">
            <cfset resulthtml = resulthtml & "<div class='changeship'><div class='shipbuttons'><input type='button' value='Edit this Shipment' class='lnkBtn' onClick=""$('##dialog-shipment').dialog('open'); loadShipment(#shipment_id#,'shipmentForm');""></div><div class='shipbuttons' id='addPermit_#shipment_id#'><input type='button' value='Add Permit to this Shipment' class='lnkBtn' onClick=""opendialog('picks/PermitShipmentPick.cfm?shipment_id=#shipment_id#','##addPermitDlg_#shipment_id#','Pick Permit for Shipment'); "" ></div><div id='addPermitDlg_#shipment_id#'></div></div> ">

            <cfset resulthtml = resulthtml & "<div class='shippermitstyle'><h4>Permits:</h4>">
                 <cfset resulthtml = resulthtml & "<div class='permitship'><span id='permits_ship_#shipment_id#'>">
                 <cfloop query="shippermit">
                    <cfset resulthtml = resulthtml & "<ul class='permitshipul'><li>#permit_type# #permit_Num#</li><li>Issued: #dateformat(issued_Date,'yyyy-mm-dd')#</li><li style='width:300px;'> #IssuedByAgent#</li></ul>">
                    <cfset resulthtml = resulthtml & "<ul class='permitshipul2'>">
                       <cfset resulthtml = resulthtml & "<li><input type='button' class='savBtn' style='padding:1px 6px;' onClick=' window.open(""Permit.cfm?Action=editPermit&permit_id=#permit_id#"")' target='_blank' value='Edit'></li> ">
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
    <cfreturn resulthtml>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!---  Given a permit_id and a shipment_id, link the permit to the shipment --->
<cffunction name="setShipmentForPermit" access="remote">
    <cfargument name="shipment_id" type="numeric" required="yes">
    <cfargument name="permit_id" type="numeric" required="yes">
    <cftry>
       <cfquery name="insertResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertResultRes">
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
<cffunction name="changekillRows" access="remote">
	<cfargument name="tgt" type="string" required="yes">
	<cftry>
			<cfif tgt is not 1>
				<cfset tgt=0>
			</cfif>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					KILLROW = #tgt#
				WHERE username = '#session.username#'
			</cfquery>
			<cfset session.KILLROW = "#tgt#">
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="changeBlockSuggest" access="remote">
	<cfargument name="onoff" type="string" required="yes">
	<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					block_suggest = #onoff#
				WHERE username = '#session.username#'
			</cfquery>
			<cfset session.block_suggest = onoff>
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
					displayrows = #tgt#
				WHERE username = '#session.username#'
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
	  	<cfquery name="names" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select agent_name,agent_id
			from preferred_agent_name
			where upper(agent_name) like '%#ucase(attribute_determiner)#%'
		</cfquery>
		<cfif #names.recordcount# is 0>
			<cfset result = "Nothing matched.">
		<cfelseif #names.recordcount# is 1>
			<cftry>
				<cfquery name="upatt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="names" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select agent_name,agent_id
		from preferred_agent_name
		where agent_id = #agent_id#
	</cfquery>
	<cfif #names.recordcount# is 0>
		<cfset result = "Nothing matched.">
	<cfelseif #names.recordcount# is 1>
		<cftry>
			<cfquery name="upatt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfinclude template="/includes/functionLib.cfm">
	<cftry>
		<cfquery name="insAnn" datasource="uam_god">
			insert into annotations (
				cf_username,
				#idType#,
				annotation
			) values (
				'#session.username#',
				#idvalue#,
				'#stripQuotes(urldecode(annotation))#'
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
				<cfif idType is "collection_object_id">
					cataloged_item.collection_object_id=#idvalue#
				<cfelse>
					1=0
				</cfif>
		</cfquery>
		<cfset mailTo = valuelist(whoTo.address)>
		<cfset mailTo=listappend(mailTo,Application.bugReportEmail,",")>
		<cfmail to="#mailTo#" from="annotation@#Application.fromEmail#" subject="Annotation Submitted" type="html">
			Arctos User #session.username# has submitted an annotation.

			<blockquote>
				#annotation#
			</blockquote>

			View details at
			<a href="#Application.ServerRootUrl#/info/reviewAnnotation.cfm?action=show&type=#idType#&id=#idvalue#">
			#Application.ServerRootUrl#/info/annotate.cfm?action=show&type=#idType#&id=#idvalue#
			</a>
		</cfmail>
	<cfcatch>
		<cfset result = "A database error occured: #cfcatch.message# #cfcatch.detail#">
		<cfreturn result>
	</cfcatch>
	</cftry>
	<cfset result = "success">
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
        <cfquery name="addChildLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
           insert into loan_relations (transaction_id, related_transaction_id, relation_type)
               values (
               <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">,
               <cfqueryparam value = "#subloan_transaction_id#" CFSQLType="CF_SQL_DECIMAL">,
               'Subloan'
               )
        </cfquery>
        <cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
        <cfquery name="removeChildLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
           delete from loan_relations
               where transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL"> and
               related_transaction_id = <cfqueryparam value = "#subloan_transaction_id#" CFSQLType="CF_SQL_DECIMAL"> and
               relation_type = 'Subloan'
        </cfquery>
        <cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
           select l.loan_number, l.transaction_id from loan_relations lr left join loan l on lr.related_transaction_id = l.transaction_id
               where lr.transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
               order by l.loan_number
        </cfquery>
        <cfreturn childLoans>
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
				<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
                <cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
                <cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
