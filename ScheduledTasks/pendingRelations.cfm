<cfinclude template="/includes/_header.cfm">
<cfquery name="getRels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select * from cf_temp_relations where RELATED_COLLECTION_OBJECT_ID is null
</cfquery>
<cfoutput>
	<cfloop query="getRels">
		<cfif #related_to_num_type# is "catalog number">			
			<cftry>
			<cfquery name="isOne" datasource="uam_god">
				select 
					collection_object_id 
				FROM 
					flat
				where 
					guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_number#">
			</cfquery>
			<cfcatch>
				<cfquery name="nope" datasource="uam_god">
					update cf_temp_relations set 
						lasttrydate=sysdate,
						fail_reason='Catalog Number does not exist or is not in UAM Mamm 1234 format'
					WHERE
						collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> and
						related_to_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_number#"> and
						related_to_num_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_num_type#"> and
						relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
				</cfquery>
				<cfset isOne = queryNew("collection_object_id")>
			</cfcatch>
			</cftry>
		<cfelse>
			<cfquery name="isOne" datasource="uam_god">
				select collection_object_id FROM coll_obj_other_id_num
				where other_id_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_num_type#"> and display_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_number#">
			</cfquery>			
		</cfif>		
		<cfif #isOne.recordcount# is 0>
			<cfquery name="nope" datasource="uam_god">
				update cf_temp_relations set 
					lasttrydate=sysdate,
					fail_reason='Related cataloged item does not exist.'
				WHERE
					collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> and
					related_to_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_number#"> and
					related_to_num_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_num_type#"> and
					relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
			</cfquery>
		<cfelseif #isOne.recordcount# gt 1>
			<cfquery name="toomany" datasource="uam_god">
				update cf_temp_relations set 
					lasttrydate=sysdate,
					fail_reason='More than one cataloged item matched.'
				WHERE
					collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> and
					related_to_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_number#"> and
					related_to_num_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_num_type#"> and
					relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
			</cfquery>
		<cfelseif #isOne.recordcount# is 1>
			<cftry>
			<cfquery name="insNew" datasource="uam_god">
				INSERT INTO
					 BIOL_INDIV_RELATIONS (
					 	COLLECTION_OBJECT_ID,
					 	RELATED_COLL_OBJECT_ID,
					 	BIOL_INDIV_RELATIONSHIP )
					 VALUES (
					 	<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">,
					 	<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#isOne.collection_object_id#">,
					 	<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#"> )
			</cfquery>
			<cfquery name="justRight" datasource="uam_god">
				DELETE FROM cf_temp_relations 
				WHERE
					collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> and
					related_to_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_number#"> and
					related_to_num_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_num_type#"> and
					relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
			</cfquery>
			<cfcatch>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_relations set 
						lasttrydate=sysdate,
						fail_reason=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="DB Error. #cfcatch.detail#">
					WHERE
						collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> and
						related_to_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_number#"> and
						related_to_num_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_num_type#"> and
						relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
				</cfquery>
			</cfcatch>
			</cftry>
			<!---- insert into relationships ---->
		<cfelse>
			<cfquery name="faill" datasource="uam_god">
				update cf_temp_relations set 
					lasttrydate=sysdate,
					fail_reason='unknown failure!'
				WHERE
					collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> and
					related_to_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_number#"> and
					related_to_num_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_to_num_type#"> and
					relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
			</cfquery>
		</cfif>
	</cfloop>
</cfoutput>