<cfscript>
	function isYear(x){
       var d = "^[1-9][0-9]{3}$";
       return isValid("regex", x, d);
	}
</cfscript>
<cffunction name="jsescape">
	<cfargument name="in" required="yes">
	<cfset out=replace(in,"'","`","all")>
	<cfset out=replace(out,'"','``',"all")>
	<cfreturn out>
</cffunction>
<cffunction name="niceURL" returntype="Any">
	<cfargument name="s" type="string" required="yes">
	<cfscript>
		var r=trim(s);
		r=trim(rereplace(r,'<[^>]*>','',"all"));
		r=rereplace(r,'[^A-Za-z ]','',"all");
		r=rereplace(r,' ','-',"all");
		r=lcase(r);
		if (len(r) gt 150) {r=left(r,150);}
		if (right(r,1) is "-") {r=left(r,len(r)-1);}
		r=rereplace(r,'-+','-','all');
		return r;
	</cfscript>
</cffunction>
<cffunction name="SubsetEncodeForURL" returntype="Any">
	<!--- URL escape a small subset of characters that may be found in filenames (used for preview_uri) --->
	<!--- We don't want to escape the full set of reserved URI characters, as  media.preview_uri --->
	<!--- contains both filename paths and URIs. The characters :/&.=?, are all used in valid URIs there.  --->
	<cfargument name="s" type="string" required="yes">
	<cfscript>
	      var r=trim(s);
	      r = Replace(Replace(r,'[','%5B'),']','%5D');
	      r = Replace(Replace(r,'(','%28'),')','%29');
	      r = Replace(r,'!','%21');
	      r = Replace(r,',','%2C');
	      r = Replace(r,' ','%20');
	      return r;
	</cfscript>
</cffunction>
<cffunction name="getMediaPreview" access="public" output="true">
	<cfargument name="puri" required="true" type="string">
	<cfargument name="mt" required="false" type="string">
	<cfset r=0>
	<cfif len(puri) gt 0>
		<cfif not isdefined("session.mczmediafail")><cfset session.mczmediafail=0></cfif>
		<cfif puri contains 'mczbase.mcz.harvard.edu/specimen_images/' and session.mczmediafail GT 3>
			<!--- decrement the fail counter --->
			<cfset session.mczmediafail = session.mczmediafail-1 >
		<cfelse>
			<!--- Hack - media.preview_uri can contain filenames that aren't correctly URI encoded as well as valid IRIs --->
			<cfhttp method="head" url="#SubsetEncodeForURL(puri)#" timeout="2">
			<cfif isdefined("cfhttp.responseheader.status_code") and cfhttp.responseheader.status_code is 200>
				<cfset r=1>
			<cfelse>
				<cfif puri contains 'mczbase.mcz.harvard.edu/specimen_images/'>
					<cfset session.mczmediafail = session.mczmediafail + 1 >
					<cfif session.mczmediafail GT 3>
						<!--- we'll return a noThumb image for the next 100 requests without doing a lookup --->
						<cfset session.mczmediafail = 100 >
					</cfif>
				</cfif>
			</cfif>
		</cfif>
	</cfif>
	<cfif r is 0>
		<cfif mt is "image">
			<cfreturn "/images/noThumb.jpg">
		<cfelseif mt is "audio">
			<cfreturn "/images/audioNoThumb.png">
		<cfelseif mt is "text">
			<cfreturn "/images/documentNoThumb.png">
		<cfelseif mt is "multi-page document">
			<cfreturn "/images/document_thumbnail.png">
		<cfelse>
			<cfreturn "/images/noThumb.jpg">
		</cfif>
	<cfelse>
		<cfreturn puri>
	</cfif>
</cffunction>
<!------------------------------------------------------------------------------------->
<cffunction name="getTagReln" access="public" output="true">
    <cfargument name="tag_id" required="true" type="numeric">
	<cfoutput>
		<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				tag_id,
				media_id,
				reftop,
				refleft,
				refh,
				refw,
				imgh,
				imgw,
				remark,
				collection_object_id,
				collecting_event_id,
				locality_id,
				agent_id
			from tag 
			where tag_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tag_id#">
			order by
				collection_object_id,
				collecting_event_id,
				locality_id,
				agent_id,
				remark
		</cfquery>
		<cfif r.collection_object_id gt 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select guid 
				from 
					<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif>
				where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#r.collection_object_id#">
			</cfquery>
			<cfset rt="cataloged_item">
			<cfset rs="#d.guid#">
			<cfset ri="#r.collection_object_id#">
			<cfset rl="/guid/#d.guid#">
		<cfelseif r.collecting_event_id gt 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select verbatim_date, verbatim_locality 
				from collecting_event 
				where collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#r.collecting_event_id#">
			</cfquery>
			<cfset rt="collecting_event">
			<cfset rs="#d.verbatim_locality# (#d.verbatim_date#)">
			<cfset ri="#r.collecting_event_id#">
			<cfset rl="/showLocality.cfm?action=srch&collecting_event_id=#r.collecting_event_id#">
		<cfelseif r.agent_id gt 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select agent_name 
				from preferred_agent_name 
				where agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#r.agent_id#">
			</cfquery>
			<cfset rt="agent">
			<cfset rs="#d.agent_name#">
			<cfset ri="#r.agent_id#">
			<cfset rl="/agents/Agent.cfm?agent_id=#r.agent_id#">
		<cfelseif r.locality_id gt 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select spec_locality 
				from locality 
				where locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#r.locality_id#">
			</cfquery>
			<cfset rt="locality">
			<cfset rs="#d.spec_locality#">
			<cfset ri="#r.locality_id#">
			<cfset rl="/showLocality.cfm?action=srch&locality_id=#r.locality_id#">
		<cfelse>
			<cfset rt="comment">
			<cfset rs="">
			<cfset ri="">
			<cfset rl="">
		</cfif>
		<cfset rft = ArrayNew(1)>
		<cfset rfi = ArrayNew(1)>
		<cfset rfs = ArrayNew(1)>
		<cfset rfl = ArrayNew(1)>
		<cfset rft[1]=rt>
		<cfset rfi[1]=ri>
		<cfset rfs[1]=rs>
		<cfset rfl[1]=rl>
		<cfset temp = QueryAddColumn(r, "REFTYPE", "VarChar",rft)>
		<cfset temp = QueryAddColumn(r, "REFID", "Integer",rfi)>
		<cfset temp = QueryAddColumn(r, "REFSTRING", "VarChar",rfs)>
		<cfset temp = QueryAddColumn(r, "REFLINK", "VarChar",rfl)>
		<cfreturn r>
	</cfoutput>
</cffunction>
<!------------------------------------------------------------------------------------->
<cffunction name="checkSql" access="public" output="true" returntype="boolean">
    <cfargument name="sql" required="true" type="string">
    <cfset nono="chr,char,update,insert,delete,drop,create,execute,exec,begin,declare,all_tables,session,cast(,sys,ascii,utl_,ctxsys,all_users">
    <cfset dels="';','|',">
    <cfset safe=0>
    <cfloop index="i" list="#sql#" delimiters=" .,?!;:%$&""'/|[]{}()#chr(10)##chr(13)##chr(9)#@">
	    <cfif ListFindNoCase(nono, i)>
	        <cfset safe=1>
	    </cfif>
    </cfloop>
    <cfif safe is 0>
        <cfreturn true>
    <cfelse>
		<cfinclude template="/errors/autoblacklist.cfm">
		<cfreturn false>
    </cfif>
</cffunction>
<!--------------------------------------------------------------------->
<cffunction name="setDbUser" output="true" returntype="boolean">
	<cfargument name="portal_id" type="string" required="false">
	<cfif not isdefined("portal_id") or len(portal_id) is 0 or not isnumeric(portal_id)>
		<cfset portal_id=0>
	</cfif>
	<!--- get the information for the portal --->
	<!---cfquery name="portalInfo" datasource="cf_dbuser">
		select * from cf_collection where cf_collection_id = #portal_id#
	</cfquery--->
	<cfif session.roles does not contain "coldfusion_user">
		<cfquery name="portalInfo" datasource="cf_dbuser">
			select * from cf_collection 
			where cf_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#portal_id#">
		</cfquery>
		<cfset session.dbuser=portalInfo.dbusername>
		<cfset session.epw = encrypt(portalInfo.dbpwd,cfid)>
		<cfset session.flatTableName = "filtered_flat">
	<cfelse>
		<cfset session.flatTableName = "flat">
	</cfif>
	<cfset session.portal_id=portal_id>
	<cfset session.header_color = Application.header_color>
	<cfset session.header_image =  Application.header_image>
	<cfset session.collection_url =  Application.collection_url>
	<cfset session.collection_link_text =  Application.collection_link_text>
	<cfset session.institution_url =  Application.institution_url>
	<cfset session.institution_link_text =  Application.institution_link_text>
	<cfset session.meta_description =  Application.meta_description>
	<cfset session.meta_keywords =  Application.meta_keywords>
	<cfset session.stylesheet =  Application.stylesheet>
	<cfset session.header_credit = "">
	<cfreturn true>
</cffunction>
<!----------------------------------------------------------->
<cffunction name="initSession" output="true" returntype="boolean">
	<cfargument name="username" type="string" required="false">
	<cfargument name="pwd" type="string" required="false">
	<cfoutput>
	<!------------------------ logout ------------------------------------>
	<cfset StructClear(Session)>
	<cflogout>
	<cfset session.DownloadFileName = "MCZbaseData_#cfid##cftoken#.txt">
	<cfset session.DownloadFileID = "#cfid##cftoken#">
	<cfset session.roles="public">
	<cfset session.showObservations="">
	<cfset session.result_sort="">
	<cfset session.username="">
	<cfset session.killrow="0">
	<cfset session.searchBy="">
	<cfset session.fancyCOID="">
	<cfset session.last_login="">
	<cfset session.customOtherIdentifier="">
	<cfset session.displayrows="20">
	<cfset session.loan_request_coll_id="">
	<cfset session.resultColumnList="">
	<cfset session.schParam = "">
	<cfset session.target=''>
	<cfset session.block_suggest=1>
	<cfset session.meta_description=''>
	<cfset temp=cfid & '_' & cftoken & '_' & RandRange(0, 9999)>
	<cfset session.SpecSrchTab="SpecSrch" & temp>
	<cfset session.MediaSrchTab="MediaSrch" & temp> <!-- Doris' edit -->
	<cfset session.TaxSrchTab="TaxSrch" & temp>
	<cfset session.exclusive_collection_id="">
	<cfset session.mczmediafail=0>

	<!---------------------------- login ------------------------------------------------>
	<cfif isdefined("username") and len(username) gt 0 and isdefined("pwd") and len(pwd) gt 0>
		<cfquery name="getPrefs" datasource="cf_dbuser">
			select * 
			from cf_users 
			where 
				username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#"> 
				and password = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(pwd)#">
		</cfquery>
		<cfif getPrefs.recordcount is 0>
			<cfset session.username = "">
			<cfset session.epw = "">
			<cflocation url="login.cfm?badPW=true&username=#username#">
		</cfif>
		<cfset session.username=username>
		<cfquery name="dbrole" datasource="uam_god">
			select upper(granted_role) role_name
			from
				dba_role_privs,
				cf_ctuser_roles
			where
				upper(dba_role_privs.granted_role) = upper(cf_ctuser_roles.role_name) and
				upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(getPrefs.username)#">
		</cfquery>
		<cfset session.roles = valuelist(dbrole.role_name)>
		<cfset session.roles=listappend(session.roles,"public")>
		<cfset session.last_login = "#getPrefs.last_login#">
		<cfset session.displayrows = "#getPrefs.displayRows#">
		<cfset session.showObservations = "#getPrefs.showObservations#">
		<cfset session.resultcolumnlist = "#getPrefs.resultcolumnlist#">
		<cfif len(getPrefs.fancyCOID) gt 0>
			<cfset session.fancyCOID = getPrefs.fancyCOID>
		<cfelse>
			<cfset session.fancyCOID = "">
		</cfif>
		<cfif len(getPrefs.block_suggest) gt 0>
			<!---cfset session.block_suggest = getPrefs.block_suggest--->
			<cfset session.block_suggest = 1>
		</cfif>
		<cfif len(getPrefs.result_sort) gt 0>
			<cfset session.result_sort = getPrefs.result_sort>
		<cfelse>
			<cfset session.result_sort = "">
		</cfif>
		<cfif len(getPrefs.CustomOtherIdentifier) gt 0>
			<cfset session.customOtherIdentifier = getPrefs.CustomOtherIdentifier>
		<cfelse>
			<cfset session.customOtherIdentifier = "">
		</cfif>
		<cfif getPrefs.bigsearchbox is 1>
			<cfset session.searchBy="bigsearchbox">
		<cfelse>
			<cfset session.searchBy="">
		</cfif>
		<cfif getPrefs.killRow is 1>
			<cfset session.killRow=1>
		<cfelse>
			<cfset session.killRow=0>
		</cfif>
		<cfset session.locSrchPrefs=getPrefs.locSrchPrefs>
		<cfquery name="logLog" datasource="cf_dbuser">
			update cf_users 
			set last_login = sysdate 
			where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfif listcontainsnocase(session.roles,"coldfusion_user")>
			<cfset session.dbuser = "#getPrefs.username#">
			<cfset session.epw = encrypt(pwd,cfid)>
			<cftry>
				<cfquery name="ckUserName" datasource="uam_god">
					select agent_id 
					from agent_name 
					where agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and agent_name_type = 'login'
				</cfquery>
				<cfcatch>
					<div class="error">
						Your Oracle login has issues. Contact a DBA.
					</div>
					<cfabort>
				</cfcatch>
			</cftry>
			<cfif len(ckUserName.agent_id) is 0>
				<div class="error">
					You must have an agent_name of type login that matches your Arctos username.
				</div>
				<cfabort>
			</cfif>
			<cfset session.myAgentId=ckUserName.agent_id>
		<cfset pwtime =  round(now() - getPrefs.pw_change_date)>
		<cfset pwage = Application.max_pw_age - pwtime>
		<cfif pwage lte 0>
			<cfset session.force_password_change = "yes">
			<cflocation url="ChangePassword.cfm">
		</cfif>
		</cfif>
	</cfif>
	<cfif isdefined("getPrefs.exclusive_collection_id") and len(getPrefs.exclusive_collection_id) gt 0>
		<cfset ecid=getPrefs.exclusive_collection_id>
		<!---  TODO:  has exclusive_collection_id been renamed ecid?  --->
        <cfset session.exclusive_collection_id=getPrefs.exclusive_collection_id>
	<cfelse>
		<cfset ecid="">
	</cfif>
	<cfset setDbUser(ecid)>
	</cfoutput>
	<cfreturn true>
</cffunction>
<!------------------------------------------------------------------------------------->
<cffunction name="unsafeSql" access="public" output="false" returntype="boolean">
    <cfargument name="sql" required="true" type="string">
    <cfset nono="update,insert,delete,drop,create,alter,set,execute,exec,begin,declare,all_tables,v$session,all_users">
    <cfset dels="';','|',">
    <cfset safe=0>
    <cfloop index="i" list="#sql#" delimiters=" .,?!;:%$&""'/|[]{}()#chr(10)##chr(13)##chr(9)#">
	    <cfif ListFindNoCase(nono, i)>
	        <cfset safe=1>
	    </cfif>
    </cfloop>
    <cfif safe gt 0>
        <cfreturn true>
    <cfelse>
        <cfreturn false>
    </cfif>
</cffunction>
<!----------------------------------------------------->
<cffunction name="getMediaRelations" access="public" output="false" returntype="Query">
	<cfargument name="media_id" required="true" type="numeric">
	<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from media_relations,
		preferred_agent_name
		where
		media_relations.created_by_agent_id = preferred_agent_name.agent_id and
		media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		<!--->and media_relationship <> 'ledger entry for cataloged_item'--->
	</cfquery>
	<cfset result = querynew("media_relations_id,media_relationship,created_agent_name,related_primary_key,summary,link")>
	<cfset i=1>
	<cfloop query="relns">
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "media_relations_id", "#media_relations_id#", i)>
		<cfset temp = QuerySetCell(result, "media_relationship", "#media_relationship#", i)>
		<cfset temp = QuerySetCell(result, "created_agent_name", "#agent_name#", i)>
		<cfset temp = QuerySetCell(result, "related_primary_key", "#related_primary_key#", i)>
		<cfset table_name = listlast(media_relationship," ")>
		<cfif table_name is "locality">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					higher_geog || ': ' || spec_locality data
				from
					locality,
					geog_auth_rec
				where
					locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
					locality.locality_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/showLocality.cfm?action=srch&locality_id=#related_primary_key#", i)>
		<cfelseif #table_name# is "agent">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select agent_name data 
				from preferred_agent_name 
				where agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
		<cfelseif table_name is "collecting_event">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					higher_geog || ': ' || spec_locality || ' (' || verbatim_date || ')' data
				from
					collecting_event,
					locality,
					geog_auth_rec
				where
					collecting_event.locality_id=locality.locality_id and
					locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
					collecting_event.collecting_event_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/showLocality.cfm?action=srch&collecting_event_id=#related_primary_key#", i)>
		<cfelseif table_name is "accn">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					collection || ' ' || accn_number data
				from
					collection,
					trans,
					accn
				where
					collection.collection_id=trans.collection_id and
					trans.transaction_id=accn.transaction_id and
					accn.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/transactions/Accession.cfm?action=edit&transaction_id=#related_primary_key#", i)>
		<cfelseif table_name is "deaccession">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					collection || ' ' || deacc_number data
				from
					collection,
					trans,
					deaccession
				where
					collection.collection_id=trans.collection_id and
					trans.transaction_id=deaccession.transaction_id and
					deaccession.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
    		        <cfset temp = QuerySetCell(result, "link", "/transactions/Deaccession.cfm?action=edit&transaction_id=#related_primary_key#", i)>
		<cfelseif table_name is "loan">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					collection || ' ' || loan_number data
				from
					collection,
					trans,
					loan
				where
					collection.collection_id=trans.collection_id and
					trans.transaction_id=loan.transaction_id and
					loan.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#" >
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
    		        <cfset temp = QuerySetCell(result, "link", "/transactions/Loan.cfm?Action=editLoan&transaction_id=#related_primary_key#", i)>
		<cfelseif table_name is "borrow">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					collection || ' ' || borrow_number data
				from
					collection,
					trans,
					borrow
				where
					collection.collection_id=trans.collection_id and
					trans.transaction_id=borrow.transaction_id and
					borrow.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#" >
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
    		        <cfset temp = QuerySetCell(result, "link", "/transactions/Borrow.cfm?Action=edit&transaction_id=#related_primary_key#", i)>
		<cfelseif table_name is "permit">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					permit_Type || ' ' || agent_name || ' ' || permit_Num data
				from
					permit,
					preferred_agent_name
				where
					permit.issued_by_agent_id = preferred_agent_name.agent_id (+) and
        				permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#" >
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            		<cfset temp = QuerySetCell(result, "link", "/Permit.cfm?Action=editPermit&permit_id=#related_primary_key#", i)>
		<cfelseif table_name is "cataloged_item">
		<!--- upping this to uam_god for now - see Issue 135
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		---->
			<cfquery name="d" datasource="uam_god">
				select collection || ' ' || cat_num || ' (' || scientific_name || ')' data from
				cataloged_item,
                collection,
                identification
                where
                cataloged_item.collection_object_id=identification.collection_object_id and
                accepted_id_fg=1 and
                cataloged_item.collection_id=collection.collection_id and
                cataloged_item.collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/SpecimenResults.cfm?collection_object_id=#related_primary_key#", i)>
		<cfelseif table_name is "media">
			<cfquery name="d" datasource="uam_god">
				select media_uri data 
				from media 
				where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/media/#related_primary_key#", i)>
		<cfelseif table_name is "publication">
			<cfquery name="d" datasource="uam_god">
				select formatted_publication data 
				from formatted_publication 
				where format_style='long' and
				publication_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/SpecimenUsage.cfm?publication_id=#related_primary_key#", i)>
		<cfelseif #table_name# is "project">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select project_name data from
				project where project_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/ProjectDetail.cfm?project_id=#related_primary_key#", i)>
		<cfelseif table_name is "taxonomy">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select display_name data,scientific_name from
				taxonomy where taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/name/#d.scientific_name#", i)>
		<cfelse>
		<cfset temp = QuerySetCell(result, "summary", "#table_name# is not currently supported.", i)>
		</cfif>
		<cfset i=i+1>
	</cfloop>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getMediaRelations2" access="public" output="false" returntype="Query">
        <!--- ??? appears to be unused, not current with getMediaRelations for relationship types ??? --->>
	<cfargument name="media_id" required="true" type="numeric">
	<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from media_relations,
		preferred_agent_name
		where
		media_relations.created_by_agent_id = preferred_agent_name.agent_id and
		media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
	</cfquery>
	<cfset result = querynew("media_relations_id,media_relationship,created_agent_name,related_primary_key,summary,link, rel_type")>
	<cfset i=1>
	<cfloop query="relns">
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "media_relations_id", "#media_relations_id#", i)>
		<cfset temp = QuerySetCell(result, "media_relationship", "#media_relationship#", i)>
		<cfset temp = QuerySetCell(result, "created_agent_name", "#agent_name#", i)>
		<cfset temp = QuerySetCell(result, "related_primary_key", "#related_primary_key#", i)>
		<cfset table_name = listlast(media_relationship," ")>
		<cfif table_name is "locality">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					higher_geog || ': ' || spec_locality data
				from
					locality,
					geog_auth_rec
				where
					locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
					locality.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/showLocality.cfm?action=srch&locality_id=#related_primary_key#", i)>
			<cfset temp = QuerySetCell(result, "rel_type", "locality", i)>
		<cfelseif #table_name# is "agent">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select agent_name data 
				from preferred_agent_name 
				where agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
			<cfif #media_relationship# is "created by agent">
				<cfset temp = QuerySetCell(result, "rel_type", "created by agent", i)>
			<cfelse>
				<cfset temp = QuerySetCell(result, "rel_type", "shows agent", i)>
			</cfif>

		<cfelseif table_name is "collecting_event">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					higher_geog || ': ' || spec_locality || ' (' || verbatim_date || ')' data
				from
					collecting_event,
					locality,
					geog_auth_rec
				where
					collecting_event.locality_id=locality.locality_id and
					locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
					collecting_event.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/showLocality.cfm?action=srch&collecting_event_id=#related_primary_key#", i)>
			<cfset temp = QuerySetCell(result, "rel_type", "collecting_event", i)>
		<cfelseif table_name is "accn">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					collection || ' ' || accn_number data
				from
					collection,
					trans,
					accn
				where
					collection.collection_id=trans.collection_id and
					trans.transaction_id=accn.transaction_id and
					accn.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
			<cfset temp = QuerySetCell(result, "link", "/transactions/Accession.cfm?action=edit&transaction_id=#related_primary_key#", i)>
			<cfset temp = QuerySetCell(result, "rel_type", "accn", i)>
		<cfelseif table_name is "cataloged_item">
		<!--- upping this to uam_god for now - see Issue 135
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		---->
			<cfquery name="d" datasource="uam_god">
				select collection || ' ' || cat_num || ' (' || scientific_name || ')' data,
					guid_prefix || ':' || cat_num guid_string
				from
					cataloged_item,
					collection,
					identification
				where
					cataloged_item.collection_object_id=identification.collection_object_id and
					accepted_id_fg=1 and
					cataloged_item.collection_id=collection.collection_id and
					cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
			<cfset temp = QuerySetCell(result, "link", "/guid/#d.guid_string#", i)>
			<cfset temp = QuerySetCell(result, "rel_type", "cataloged_item", i)>
		<cfelseif table_name is "media">
			<cfquery name="d" datasource="uam_god">
				select media_uri data 
				from media 
				where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/media/#related_primary_key#", i)>
			<cfset temp = QuerySetCell(result, "rel_type", "media", i)>
		<cfelseif table_name is "publication">
			<cfquery name="d" datasource="uam_god">
				select formatted_publication data 
				from formatted_publication 
				where format_style='long' and
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/SpecimenUsage.cfm?publication_id=#related_primary_key#", i)>
			<cfset temp = QuerySetCell(result, "rel_type", "publication", i)>
		<cfelseif #table_name# is "project">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select project_name data 
				from project 
				where project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/ProjectDetail.cfm?project_id=#related_primary_key#", i)>
			<cfset temp = QuerySetCell(result, "rel_type", "project", i)>
		<cfelseif table_name is "taxonomy">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select display_name data,scientific_name 
				from taxonomy 
				where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/name/#d.scientific_name#", i)>
			<cfset temp = QuerySetCell(result, "rel_type", "taxonomy", i)>
		<cfelse>
			<cfset temp = QuerySetCell(result, "summary", "#table_name# is not currently supported.", i)>
		</cfif>
		<cfset i=i+1>
	</cfloop>
	<cfreturn result>
</cffunction>

<!----------------------------------------------------------------------------------------->
<cffunction name="QueryToCSV" access="public" returntype="string" output="false">

	<!--- Define arguments. --->
	<cfargument name="Query" type="query" required="true" hint="media query being converted to CSV.">

	<cfargument name="Fields" type="string" required="true" hint="List of query fields to be used when creating the CSV value.">

	<cfargument name="CreateHeaderRow" type="boolean" required="false" default="true" hint="Boolean flag indicator for creating headers or not">

	<cfargument name="Delimiter" type="string" required="false" default="," hint="Field delimiter in the CSV value.">

	<!--- Define the local scope. --->
	<cfset var LOCAL = {} />

	<!---
		Set up a column index so that we can
		iterate over the column names faster than if we used a
		standard list loop on the passed-in list.
	--->
	<cfset LOCAL.ColumnNames = [] />

	<!---
		Loop over column names and index them numerically. We
		are going to be treating this struct almost as if it
		were an array. The reason we are doing this is that
		look-up times on a table are a bit faster than look
		up times on an array (or so I have been told).
	--->

	<cfloop index="LOCAL.ColumnName" list="#ARGUMENTS.Fields#" delimiters=",">

		<!--- Store the current column name. --->
		<cfset ArrayAppend(LOCAL.ColumnNames, Trim( LOCAL.ColumnName ))>

	</cfloop>

	<!--- Store the column count. --->
	<cfset LOCAL.ColumnCount = ArrayLen( LOCAL.ColumnNames ) />


	<!--- Create a short hand for the new line characters. --->
	<cfset LOCAL.NewLine = (Chr( 13 ) & Chr( 10 )) />

	<!--- Create an array to hold the set of row data. --->
	<cfset LOCAL.Rows = [] />


	<!--- Check to see if we need to add a header row. --->
	<cfif ARGUMENTS.CreateHeaderRow>

		<!--- Create array to hold row data. --->
		<cfset LOCAL.RowData = [] />

		<!--- Loop over the column names. --->
		<cfloop index="LOCAL.ColumnIndex" from="1" to="#LOCAL.ColumnCount#" step="1">

			<!--- Add the field name to the row data. --->
			<cfset LOCAL.RowData[ LOCAL.ColumnIndex ] = """#LOCAL.ColumnNames[ LOCAL.ColumnIndex ]#""" />

		</cfloop>

		<!--- Append the row data to the string buffer. --->
		<cfset ArrayAppend(
			LOCAL.Rows,
			ArrayToList( LOCAL.RowData, ARGUMENTS.Delimiter )
			) />

	</cfif>


	<!---
		Now that we have dealt with any header value, let's
		convert the query body to CSV. When doing this, we are
		going to qualify each field value. This is done be
		default since it will be much faster than actually
		checking to see if a field needs to be qualified.
	--->

	<!--- Loop over the query. --->
	<cfloop query="ARGUMENTS.Query">
		<!--- Create array to hold row data. --->
		<cfset LOCAL.RowData = [] />

		<!--- Loop over the columns. --->
		<cfloop index="LOCAL.ColumnIndex" from="1" to="#LOCAL.ColumnCount#"	step="1">

			<!--- Add the field to the row data. --->
			<cfset LOCAL.RowData[ LOCAL.ColumnIndex ] = """#Replace( ARGUMENTS.Query[ LOCAL.ColumnNames[ LOCAL.ColumnIndex ] ][ ARGUMENTS.Query.CurrentRow ], """", """""", "all" )#""" />

		</cfloop>

		<!--- Append the row data to the string buffer. --->
		<cfset ArrayAppend(LOCAL.Rows,	ArrayToList(LOCAL.RowData, ARGUMENTS.Delimiter ))>
	</cfloop>



	<!---
		Return the CSV value by joining all the rows together
		into one string.
	--->
	<cfreturn ArrayToList(
		LOCAL.Rows,
		LOCAL.NewLine
		) />

</cffunction>

<!----------------------------------------------------------------------------------------->
<cffunction name="roundDown" output="no">
    <cfargument name="target" type="numeric" required="true"/>
    <cfreturn (round((arguments.target * -1))) * -1/>
</cffunction>
<!----------------------------------------------------------------------------------------->

<cfscript>
    /**
        * Returns a random hexadecimal color
        * @return Returns a string.
        * @author andy matthews (andy@icglink.com)
        * @version 1, 7/22/2005
    */
    function randomHexColor() {
    	var chars = "0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f";
    	var totalChars = 6;
    	var hexCode = '';
    	for ( step=1;step LTE totalChars; step = step + 1) {
    		hexCode = hexCode & ListGetAt(chars,RandRange(1,ListLen(chars)));
    	}
        return hexCode;
    }
</cfscript>




<!----------------------------------------------------------------------------------------->
<cfscript>
/**
 * Returns the last index of an occurrence of a substring in a string from a specified starting position.
 * Big update by Shawn Seley (shawnse@aol.com) -
 * UDF was not accepting third arg for start pos
 * and was returning results off by one.
 * Modified by RCamden, added var, fixed bug where if no match it return len of str
 *
 * @param Substr 	 Substring to look for.
 * @param String 	 String to search.
 * @param SPos 	 Starting position.
 * @return Returns the last position where a match is found, or 0 if no match is found.
 * @author Charles Naumer (shawnse@aol.comcmn@v-works.com)
 * @version 2, February 14, 2002
 */
function RFind(substr,str) {
  var rsubstr  = reverse(substr);
  var rstr     = "";
  var i        = len(str);
  var rcnt     = 0;

  if(arrayLen(arguments) gt 2 and arguments[3] gt 0 and arguments[3] lte len(str)) i = len(str) - arguments[3] + 1;

  rstr = reverse(Right(str, i));
  rcnt = find(rsubstr, rstr);

  if(not rcnt) return 0;
  return len(str)-rcnt-len(substr)+2;
}
/**
 * Converts degrees to radians.
 *
 * @param degrees 	 Angle (in degrees) you want converted to radians.
 * @return Returns a simple value
 * @author Rob Brooks-Bilson (rbils@amkor.com)
 * @version 1.0, July 18, 2001
 */
function DegToRad(degrees)
{
  Return (degrees*(Pi()/180));
}


/**
 * Calculates the arc tangent of the two variables, x and y.
 *
 * @param x 	 First value. (Required)
 * @param y 	 Second value. (Required)
 * @return Returns a number.
 * @author Rick Root (rick.root@webworksllc.com)
 * @version 1, September 14, 2005
 */
function atan2(firstArg, secondArg) {
	var Math = createObject("java","java.lang.Math");
	return Math.atan2(javacast("double",firstArg), javacast("double",secondArg));
}

/**
 * Converts radians to degrees.
 *
 * @param radians 	 Angle (in radians) you want converted to degrees.
 * @return Returns a simple value.
 * @author Rob Brooks-Bilson (rbils@amkor.com)
 * @version 1.0, July 18, 2001
 */
function RadToDeg(radians)
{
  Return (radians*(180/Pi()));
}

/**
 * Computes the mathematical function Mod(y,x).
 *
 * @param y 	 Number to be modded.
 * @param x 	 Devisor.
 * @return Returns a numeric value.
 * @author Tom Nunamaker (tom@toshop.com)
 * @version 1, February 24, 2002
 */
function ProperMod(y,x) {
  var modvalue = y - x * int(y/x);

  if (modvalue LT 0) modvalue = modvalue + x;

  Return ( modvalue );
}
</cfscript>
<cffunction name="kmlStripper" returntype="string" output="false">
	<cfargument name="in" type="string">
	<cfset out = replace(in,"&","&amp;","all")>
	<cfset out = replace(out,"'","&apos;","all")>
	<cfset out = replace(out,'"','&quot;','all')>
	<cfset out = replace(out,'>',"&qt;","all")>
	<cfset out = replace(out,'<',"&lt;","all")>
	<cfreturn out>
</cffunction>
<!----------------------->
<cffunction
     name="CSVToArray"
     access="public"
     returntype="array"
     output="false"
     hint="Converts the given CSV string to an array of arrays.">
     <cfargument
     name="CSV"
     type="string"
     required="true"
     hint="This is the CSV string that will be manipulated."
     />

     <cfargument
     name="Delimiter"
     type="string"
     required="false"
     default=","
     hint="This is the delimiter that will separate the fields within the CSV value."
     />

     <cfargument
     name="Qualifier"
     type="string"
     required="false"
     default=""""
     hint="This is the qualifier that will wrap around fields that have special characters embeded."
     />
     <cfset var LOCAL = StructNew() />
     <cfset ARGUMENTS.Delimiter = Left( ARGUMENTS.Delimiter, 1 ) />
     <cfif Len( ARGUMENTS.Qualifier )>
     <cfset ARGUMENTS.Qualifier = Left( ARGUMENTS.Qualifier, 1 ) />
     </cfif>
     <cfset LOCAL.LineDelimiter = Chr( 13 ) />
     <cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll(
     "\r?\n",
     LOCAL.LineDelimiter
     ) />
     <cfset LOCAL.Delimiters = ARGUMENTS.CSV.ReplaceAll(
     "[^\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]+",
     ""
     )
     .ToCharArray()
     />
     <cfset ARGUMENTS.CSV = (" " & ARGUMENTS.CSV) />

     <!--- Now add the space to each field. --->
     <cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll(
     "([\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]{1})",
     "$1 "
     ) />
     <cfset LOCAL.Tokens = ARGUMENTS.CSV.Split(
     "[\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]{1}"
     ) />
     <cfset LOCAL.Return = ArrayNew( 1 ) />
     <cfset ArrayAppend(
     LOCAL.Return,
     ArrayNew( 1 )
     ) />
     <cfset LOCAL.RowIndex = 1 />
     <cfset LOCAL.IsInValue = false />
     <cfloop
     index="LOCAL.TokenIndex"
     from="1"
     to="#ArrayLen( LOCAL.Tokens )#"
     step="1">
     <cfset LOCAL.FieldIndex = ArrayLen(
     LOCAL.Return[ LOCAL.RowIndex ]
     ) />
     <cfset LOCAL.Token = LOCAL.Tokens[ LOCAL.TokenIndex ].ReplaceFirst(
     "^.{1}",
     ""
     ) />
     <cfif Len( ARGUMENTS.Qualifier )>
     <cfif LOCAL.IsInValue>
     <cfset LOCAL.Token = LOCAL.Token.ReplaceAll(
     "\#ARGUMENTS.Qualifier#{2}",
     "{QUALIFIER}"
     ) />
     <cfset LOCAL.Return[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] = (
     LOCAL.Return[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] &
     LOCAL.Delimiters[ LOCAL.TokenIndex - 1 ] &
     LOCAL.Token
     ) />
     <cfif (Right( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
     <cfset LOCAL.Return[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] = LOCAL.Return[ LOCAL.RowIndex ][ LOCAL.FieldIndex ].ReplaceFirst( ".{1}$", "" ) />
     <cfset LOCAL.IsInValue = false />
     </cfif>
     <cfelse>
     <cfif (Left( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
     <cfset LOCAL.Token = LOCAL.Token.ReplaceFirst(
     "^.{1}",
     ""
     ) />
     <cfset LOCAL.Token = LOCAL.Token.ReplaceAll(
     "\#ARGUMENTS.Qualifier#{2}",
     "{QUALIFIER}"
     ) />
     <cfif (Right( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
     <cfset ArrayAppend(
     LOCAL.Return[ LOCAL.RowIndex ],
     LOCAL.Token.ReplaceFirst(
     ".{1}$",
     ""
     )
     ) />
     <cfelse>
     <cfset LOCAL.IsInValue = true />
     <cfset ArrayAppend(
     LOCAL.Return[ LOCAL.RowIndex ],
     LOCAL.Token
     ) />
     </cfif>
     <cfelse>
     <cfset ArrayAppend(
     LOCAL.Return[ LOCAL.RowIndex ],
     LOCAL.Token
     ) />
     </cfif>
     </cfif>
     <cfset LOCAL.Return[ LOCAL.RowIndex ][ ArrayLen( LOCAL.Return[ LOCAL.RowIndex ] ) ] = Replace(
     LOCAL.Return[ LOCAL.RowIndex ][ ArrayLen( LOCAL.Return[ LOCAL.RowIndex ] ) ],
     "{QUALIFIER}",
     ARGUMENTS.Qualifier,
     "ALL"
     ) />
     <cfelse>
     <cfset ArrayAppend(
     LOCAL.Return[ LOCAL.RowIndex ],
     LOCAL.Token
     ) />
     </cfif>
     <cfif (
     (NOT LOCAL.IsInValue) AND
     (LOCAL.TokenIndex LT ArrayLen( LOCAL.Tokens )) AND
     (LOCAL.Delimiters[ LOCAL.TokenIndex ] EQ LOCAL.LineDelimiter)
     )>
     <cfset ArrayAppend(
     LOCAL.Return,
     ArrayNew( 1 )
     ) />
     <cfset LOCAL.RowIndex = (LOCAL.RowIndex + 1) />
     </cfif>
     </cfloop>
     <cfreturn LOCAL.Return />

     </cffunction>


<cffunction name="toProperCase" output="false">
	<cfargument name="message" type="string">
	<cfscript>
	strlen = len(message);
    newstring = '';
    for (counter=1;counter LTE strlen;counter=counter + 1)
    {
    		frontpointer = counter + 1;

    		if (Mid(message, counter, 1) is " ")
    		{
    		 	newstring = newstring & ' ' & ucase(Mid(message, frontpointer, 1));
    		counter = counter + 1;
    		}
    	else
    		{
    			if (counter is 1)
    			newstring = newstring & ucase(Mid(message, counter, 1));
    			else
    			newstring = newstring & lcase(Mid(message, counter, 1));
    		}

    }
    </cfscript>
	<cfreturn newstring>
</cffunction>
<!------------------------------->
<cffunction name="passwordCheck">
	<cfargument name="password" required="true" type="string">
	<cfargument name="CharOpts" required="false" type="string" default="alpha,digit,punct">
	<cfargument name="typesRequired" required="false" type="numeric" default="3">
	<cfargument name="length" required="false" type="numeric" default="8">


	<!--- Initialize variables --->
	<cfset var TypesCount = 0>
	<cfset var i = "">
	<cfset var charClass = "">
	<cfset var checks = structNew()>
	<cfset var numReq = "">
	<cfset var reqCompare = "">
	<cfset var j = "">

	<!--- Use regular expressions to check for the presence banned characters such as tab, space, backspace, etc  and password length--->
	<cfif ReFind("[[:cntrl:] ]",password) OR len(password) LT length>
		<cfreturn false>
	</cfif>

	<!--- random things that Oracle doesn't like --->
	<!---
	<cfset badStuff = "=,#,&,*">
	--->
	<cfset badStuff = "#chr(40)#,#chr(41)#,#chr(42)#,#chr(38)#,#chr(35)#,+,@,=,!,$,%,^">
	<cfloop list="#badStuff#" index="i">
		<cfif #password# contains #i#>
			<cfreturn false>
		</cfif>
	</cfloop>

	<!--- Loop through the list 'mustHave' --->
	<cfloop list="#charOpts#" index="i">
		<cfset charClass = listGetat(i,1,' ')>
		<!--- Check to see if item in list should be included or excluded --->
		<cfif listgetat(i,1,"_") eq "no">
			<cfset regex = "[^[:#listgetat(charClass,2,'_')#:]]">
		<cfelse>
			<cfset regex = "[[:#charClass#:]]">
		</cfif>

		<!--- If regex found, set variable to position found --->
		<cfset checks["check#replace(charClass,' ','_','all')#"] = ReFind(regex,password)>

		<!--- If regex not found set valid to false --->
		<cfif checks["check#replace(charClass,' ','_','all')#"] GT 0>
			<cfset typesCount = typesCount + 1>
		</cfif>

		<cfif listLen(i, ' ') GT 1>
			<cfset numReq = listgetat(i,2,' ')>
			<cfset reqCompare = 0>
			<cfloop from="1" to="#len(password)#" index="j">
				<cfif REFind(regex,mid(password,j,1))>
					<cfset reqCompare = reqCompare + 1>
				</cfif>
			</cfloop>
			<cfif reqCompare LT numReq>
				<cfreturn false>
			</cfif>
		</cfif>
	</cfloop>

	<!--- Check that retrieved values match with the give criteria --->
	<cfif typesCount LT typesRequired>
		<cfreturn false>
	</cfif>
	<cfif not refind("[a-zA-Z]",left(password,1))>
		<cfreturn false>
	</cfif>
	<cfreturn true>

</cffunction>
<cffunction name="stripQuotes" returntype="string" output="false">
	<cfargument name="inStr" type="string">
	<cfset inStr = replace(inStr,"#chr(34)#","&quot;","all")>
	<cfset inStr = replace(inStr,"#chr(39)#","&##39;","all")>
	<cfset inStr = trim(inStr)>
	<cfreturn inStr>
</cffunction>
<cffunction name="escapeDoubleQuotes" returntype="string" output="false">
	<cfargument name="inStr" type="string">
	<cfset inStr = replace(inStr,'"','""',"all")>
	<cfreturn inStr>
</cffunction>
<cffunction name="escapeQuotes" returntype="string" output="false">
	<cfargument name="inStr" type="string">
	<cfset inStr = replace(inStr,"'","''","all")>
	<cfreturn inStr>
</cffunction>
<cffunction name="getMeters" returntype="numeric" output="false">
	<cfargument name="val" type="numeric" required="yes">
	<cfargument name="unit" type="string" required="yes">
	<cfif #unit# is "ft">
		<cfset valInM = #val# * .3048>
	<cfelseif #unit# is "km">
		<cfset valInM = #val# * 1000>
	<cfelseif #unit# is "mi">
		<cfset valInM = #val# * 1609.344>
	<cfelseif #unit# is "m">
		<cfset valInM = #val#>
	<cfelseif #unit# is "yd">
		<cfset valInM = #val# * 9144 >
	<cfelseif #unit# is "fms">
		<cfset valInM = #val# * 1.8288 >
	<cfelseif #unit# is "in">
		<cfset valInM = #val# * 0.0254 >
	<cfelseif #unit# is "mwo">
		<cfset valInM = #val# >
	<cfelse>
		<cfset valInM = "-9999999999" >
	</cfif>
	<cfreturn valInM>
</cffunction>
<cfscript>
/**
 * Calculates the Julian Day for any date in the Gregorian calendar.
 *
 * @param TheDate 	 Date you want to return the Julian day for.
 * @return Returns a numeric value.
 * @author Beau A.C. Harbin (bharbin@figleaf.com)
 * @version 1, September 4, 2001
 */
 function GetJulianDay(){
	var date = Now();
	var year = 0;
	var month = 0;
	var day = 0;
	var hour = 0;
	var minute = 0;
	var second = 0;
	var a = 0;
	var y = 0;
	var m = 0;
	var JulianDay =0;
        if(ArrayLen(Arguments))
          date = Arguments[1];
	// The Julian Day begins at noon so in order to calculate the date properly, one must subtract 12 hours
	date = DateAdd("h", -12, date);
	year = DatePart("yyyy", date);
	month = DatePart("m", date);
	day = DatePart("d", date);
	hour = DatePart("h", date);
	minute = DatePart("n", date);
	second = DatePart("s", date);

	a = (14-month) \ 12;
	y = (year+4800) - a;
	m = (month + (12*a)) - 3;

	JD = (day + ((153*m+2) \ 5) + (y*365) + (y \ 4) - (y \ 100) + (y \ 400)) - 32045;
	JDTime = NumberFormat(CreateTime(hour, minute, second), ".99999999");

	JulianDay = JD + JDTime;

	return JulianDay;
}
Request.GetJulianDay=GetJulianDay;
</cfscript>

<cffunction name="listcatnumToBasQualTable" returnType="String" access="public" output="false" >
        <cfargument name="listcatnum" required="true">
        <cfargument name="tablename" required="true">
        <cfset result=ScriptPrefixedNumberListToSQLWherePrefix(listcatnum,"#tablename#.cat_num_integer","#tablename#.cat_num_prefix",true)>
        <cfreturn result>
</cffunction>

<!---  Supporting functions that can be used with listcatnumToBasQualTable function --->
<!---  See Unit Tests in /tests/TestListcatnumToBasQual.cfc  --->

<cfscript>


    /**
    * In use, MCZ.
    *
    * Converts a list of numbers with prefixes to a sql where clause.
    *
    * @param listOfNumbers  A string containing a list of one or more numbers or ranges
    *     of numbers in one of the forms "1" or "1,3" or "1-3" or "1,4-9"
    *     or with prefixes in the form "A-1" or "A-2,B-3" or "A-1-3" or "A-1-3,5"
    *     or "A-1-3,B-4" or other variants of commma separated atoms in the forms:
    *     "1" (exact match, no prefix), "A-1" (single, with prefix), "A-1-2"
    *     (range with prefix), or "%-1" (any prefix), "1-3" (exact match on range).
    *     Prefix is separated and searched separately from the numeric range.
    * @param integerFieldname  The name of the number field on which the listOfNumbers is a condition.
    * @param prefixFieldname   The name of the string field on which the listOfNumbers is a condition.
    * @param embeddedSeparator true if the separator is stored embedded within the prefix field, false
    *        if prefix field only contains the prefix data, not the field separator.
    *
    * @return A string containing conditions to append to a SQL where clause.  See unit tests:
    *         testScriptPrefixedNumberListToSQLWherePrefix and testScriptPrefixedNumberListToSQLWherePrefixLists
    */
   function ScriptPrefixedNumberListToSQLWherePrefix(listOfNumbers, integerFieldname, prefixFieldname, embeddedSeparator) {
        var result = "";
        var orBit = "";
        var wherePart = "";

        // Prepare list for parsing
        listOfNumbers = trim(listOfNumbers);
        // Change ", " to "," and then " " to  "," to allow space and comma separators
        listOfNumbers = REReplace(listOfNumbers, ", ", ",","all");   // comma space to comma
        listOfNumbers = REReplace(listOfNumbers, " ", ",","all");    // space to comma
        listOfNumbers = REReplace(listOfNumbers, "\*", "%","all");    // dos to sql wildcard
        // strip out any other characters
        listOfNumbers = REReplace(listOfNumbers, "[^0-9A-Za-z%,\-]","","all");
        // reduce repeating commas to a single comma
        listOfNumbers = REReplace(listOfNumbers, ",,+",",","all");
        // strip out leading/trailing commas
        listOfNumbers = REReplace(listOfNumbers, "^,","");
        listOfNumbers = REReplace(listOfNumbers, ",$","");

        // split list into atoms.

        // check to see if listofnumbers contains no delimiter.
        if (find(",",listOfNumbers) EQ 0) {
             lparts = ArrayNew(1);
             lparts[1] = listOfNumbers;
        } else {
             // split listOfNumbers on ","
             lparts = ListToArray(listOfNumbers,",",false);
        }

        // find prefixes in atoms

        prefix = "";
        queryPrefix = "";
        queryInfix = "";
        querySuffix = "";
        wherebit = "";
        orBit = "";
        for (i=1; i LTE ArrayLen(lparts); i=i+1)  {
           // Prefix is at least one letter optionally followed by a dash separator.
           // Need to use [A-Z]+ here to prevent match on dash inside bare numeric range.
           prefixSt = REFind("^[A-Za-z]+\-{0,1}",lparts[i],0,true);
           if (prefixSt.pos[1] EQ 0 ) {
              prefix = "";
           } else {
              prefix = Mid(lparts[i],prefixSt.pos[1],prefixSt.len[1]);
           }
           numericSt = REFind("[0-9]+\-*[0-9]*",lparts[i],0,true);
           if (numericSt.pos[1] EQ 0 ) {
              numeric = "";
           } else {
              numeric = Mid(lparts[i],numericSt.pos[1],numericSt.len[1]);
           }

           if (embeddedSeparator EQ true) {
               // If the prefix isn't blank and doesn't end with the separator, add it.
               if ((prefix NEQ "") AND (Find("-",prefix) EQ 0)) {
                  prefix = prefix & "-";
               }
           } else {
               //remove any trailing dash
               prefix = REReplace(prefix,"\-$","");
           }

           if (prefix NEQ "") {
               queryPrefix = " ( " &  prefixFieldName & " = '" & prefix & "' ";
           }
           queryInfix = ScriptNumberListToSQLWhere(numeric, integerFieldname);
           if (prefix NEQ "") {
               if (queryInfix EQ "") {
                  // allow for searches on just a prefix
                  querySuffix = ") ";
               } else {
                   queryPrefix = queryPrefix & "AND (";
                   querySuffix = ") ) ";
               }
           }
           if (queryPrefix NEQ "" OR queryInfix NEQ "" OR querySuffix NEQ "") {
               // if there is a search term, add it.
               wherebit = wherebit & orBit & queryPrefix & queryInfix & querySuffix;
               orBit = "OR";
           }
           queryPrefix = "";
           querySuffix = "";
        }
        result = wherebit;
        if (result NEQ "") {
            // comma changes to or, so wrap whole list of parts as an AND clause
            result = " (" & result & ") ";
        }
        return result;
   }
</cfscript>

<cfscript>
    /**
    * Converts a list of numbers to a sql where clause.
    *
    * In use in MCZ.
    *
    * @param listOfNumbers  A string containing a list of one or more numbers or ranges
    *     of numbers in one of the forms "1" or "1,3" or "1-3" or "1,4-9".
    * @param fieldname  The name of the fieldname on which the listOfNumbers is a condition.
    * @return A string containing conditions to append to a SQL where clause.
    *         See unit test testScriptNumberListToSQLWhere
    */
    function ScriptNumberListToSQLWhere(listOfNumbers, fieldname) {
        var result = "";
        var orBit = "";
        var wherePart = "";

        // Prepare list for parsing
        listOfNumbers = trim(listOfNumbers);
        // Change ", " to "," and then " " to  "," to allow space and comma separators
        listOfNumbers = REReplace(listOfNumbers, ", ", ",","all");   // comma space to comma
        listOfNumbers = REReplace(listOfNumbers, " ", ",","all");    // space to comma
        // strip out any other characters
        listOfNumbers = REReplace(listOfNumbers, "[A-Za-z]","","all");
        listOfNumbers = REReplace(listOfNumbers, "[^0-9,\-]","","all");
        // reduce repeating commas to a single comma
        listOfNumbers = REReplace(listOfNumbers, ",,+",",","all");
        // strip out leading/trailing commas
        listOfNumbers = REReplace(listOfNumbers, "^,","");
        listOfNumbers = REReplace(listOfNumbers, ",$","");

        // check to see if listofnumbers is just one number,
        // if so return "AND fieldname IN ( number )"
        if (ArrayLen(REMatch("^[0-9]+$",listOfNumbers))>0) {
             //  Just a single number.
             result = " " & fieldname & " IN ( " & listOfNumbers & " ) ";
        } else {
            if (ArrayLen(REMatch("^[0-9]+\-[0-9]+$",listOfNumbers))>0) {
                // Just a single range
                parts = ListToArray(listOfNumbers,"-");
                lowPart = parts[1];
                highPart = parts[2];
                if (lowPart>highPart) {
                    lowPart = parts[2];
                    highPart = parts[1];
                }
                result = " ( " & fieldname & " >= "& lowPart &" AND " & fieldname & " <= " & highPart & " ) ";
            } else if (ArrayLen(REMatch("^[0-9,]+$",listOfNumbers))>0) {
                // Just a list of numbers without ranges.
                if (listOfNumbers!=",") {
                    result = " " & fieldname & " IN ( " & listOfNumbers & " ) ";
                } else {
                    // just a comma with no numbers, return empty string
                    result = "";
                }
            } else {
                // Error or list of numbers some of which are ranges, split and treat each separately.
                if (ArrayLen(REMatch(",",listOfNumbers))>0) {
                    // split listOfNumbers on ","
                    lparts = ListToArray(listOfNumbers,",",false);
                    orBit = "";
                    for(i=1; i LTE ArrayLen(lparts); i=i+1) {
                        // for each part, check to see if part is a range
                        // if part is a range, return "OR (fieldname >= minimum AND fieldname <= maximum)"
                        // if part is a single number, return "OR fieldname IN ( number )"
                        wherePart = ScriptNumberListPartToSQLWhere(lparts[i], fieldname);
                        // allow for the case of two or more sequential commas.
                        if (wherePart NEQ "") {
                            // Separate parts of list are separated by OR, but no leading OR
                            result = result & orBit & wherePart;
                            orBit = " OR ";
                        }
                    }
                    if (result NEQ "") {
                        // comma changes to or, so wrap whole list of parts as an AND clause
                        result = " (" & result & ") ";
                    }
                } else {
                    // Error state.  Not a single number, list, or range.
                }
             }
        }
        return "#result#";
    }
    /**
    * In use MCZ.
    *
    * Supporting function for ScriptNumberListToSQLWhere(), converts a number or a range into
    * a portion of a SQL where clause as a condition on a specified field.
    *
    * @param atom a number or a range of two numbers separated by a dash "4-6".
    * @param fieldName the name of the field on which atom is a condition.
    * @return a string contaning "( fieldname IN (list))"  or "( fieldname >= num AND fieldname <=num)" or ""
    */
    function ScriptNumberListPartToSQLWhere (atom, fieldName) {
        var result = "";
        // check to see if listofnumbers is just one number,
        // if so return "AND fieldname IN ( number )"
        if (ArrayLen(REMatch("^[0-9]+$",atom))>0) {
             result = "(" & fieldname & " IN ( " & atom & " ))";
        } else {
            if (ArrayLen(REMatch("^[0-9]+\-[0-9]+$",atom))>0) {
                parts = ListToArray(atom,"-");
                lowPart = parts[1];
                highPart = parts[2];
                if (lowPart>highPart) {
                    lowPart = parts[2];
                    highPart = parts[1];
                }
                result = "(" & fieldname & " >= "& lowPart &" AND " & fieldname & " <= " & highPart & ")";
            } else {
                // Error state.  Not a single number, list, or range.
                // Likely to result from two sequential commas, so return an empty string.
             }
        }
        return "#result#";
    }

    /**
    * Experimented with at MCZ.  Poor performance due to REGEX match on string rather
    * than fast search on numeric ranges.
    *
    * Converts a list of numbers with prefixes to a sql where clause.
    *
    * @depreciated
    *
    * @param listOfNumbers  A string containing a list of one or more numbers or ranges
    *     of numbers in one of the forms "1" or "1,3" or "1-3" or "1,4-9"
    *     or with prefixes in the form "A-1" or "A-2,B-3" or "A-1-3" or "A-1-3,5"
    *     or "A-1-3,B-4" or other variants of commma separated atoms in the forms:
    *     "1" (exact match, no prefix), "A-1" (single, with prefix), "A-1-2"
    *     (range with prefix), or "%-1" (any prefix), "1-3" (exact match on range).
    * @param fieldname  The name of the fieldname on which the listOfNumbers is a condition.
    * @return A string containing conditions to append to a SQL where clause.
    */
    function ScriptPrefixedNumberListToSQLWhere(listOfNumbers, fieldname) {
        var result = "";
        var orBit = "";
        var wherePart = "";

        // Prepare list for parsing
        listOfNumbers = trim(listOfNumbers);
        // Change ", " to "," and then " " to  "," to allow space and comma separators
        listOfNumbers = REReplace(listOfNumbers, ", ", ",","all");   // comma space to comma
        listOfNumbers = REReplace(listOfNumbers, " ", ",","all");    // space to comma
        listOfNumbers = REReplace(listOfNumbers, "\*", "%","all");    // dos to sql wildcard
        // strip out any other characters
        listOfNumbers = REReplace(listOfNumbers, "[^0-9A-Za-z%,\-]","","all");
        // reduce repeating commas to a single comma
        listOfNumbers = REReplace(listOfNumbers, ",,+",",","all");
        // strip out leading/trailing commas
        listOfNumbers = REReplace(listOfNumbers, "^,","");
        listOfNumbers = REReplace(listOfNumbers, ",$","");

        // split list into atoms, hand responsibility for parsing each atom off to
        // ScriptPrefixedNumberListPartToSQLWhere()

        // check to see if listofnumbers contains no delimiter.
        if (find(",",listOfNumbers) EQ 0) {
             // listofnumbers is a single atom
             result = ScriptPrefixedNumberListPartToSQLWhere(listOfNumbers, fieldname);
        } else {
             // listofnumbers is a list of atoms, combine with OR
             if (ArrayLen(REMatch(",",listOfNumbers)) GT 0) {
                // split listOfNumbers on ","
                lparts = ListToArray(listOfNumbers,",",false);
                orBit = "";
                for(i=1; i LTE ArrayLen(lparts); i=i+1) {

                    // TODO: Something isn't looping correctly here, alternate criteria are skipped.

                    // for each part, check to see if part is a range
                    wherePart = ScriptPrefixedNumberListPartToSQLWhere(lparts[i], fieldname);
                    // allow for the case of two or more sequential commas.
                    if (wherePart NEQ "") {
                        // Separate parts of list are separated by OR, but no leading OR
                        result = result & orBit & wherePart;
                        orBit = " OR ";
                    }
                }
                if (result NEQ "") {
                    // comma changes to or, so wrap whole list of parts as an AND clause
                    result = " (" & result & ") ";
                }
             }
        }
        return result;
    }

    /**
    * Experimented with at MCZ.  Poor performance due to REGEX match on string rather
    * than fast search on numeric ranges.
    *
    * @depreciated
    *
    * Supporting function for ScriptPrefixedNumberListToSQLWhere(), converts a number or a range into
    * a portion of a SQL where clause as a condition on a specified field.
    *
    * @param atom a number or a range of two numbers separated by a dash "4-6".
    * @param fieldName the name of the field on which atom is a condition.
    * @return a string contaning sql where conditions for the atom
    */
    function ScriptPrefixedNumberListPartToSQLWhere (listPart, fieldName) {
        var result = "";

        // handled atoms
        // 1234       Y    ^[A-Z]*1234$
        // 1234a      Y    ^[A-Z]*1234a$
        // 1234-1236       ^1234[a-z]*$ or ^1235[a-z]*$ or ^1236[a-z]*$
        // R1234      Y    converted to R-1234
        // R-1234     Y    ^R-1234[a-z]*
        // R-1234a    Y    = R-1234a
        // R-1234-1236 Y   ^R-1234[a-z]*& or ^R-1235[a-z]*$ or ^R-1236[a-z]*$

        // Not handled
        // 1234-R-1234
        // R-1234-1236-1237
        // R-1234-R-1236

        // Insert a hyphen if one is missing after a prefix
        var atom = REReplace(listPart, "^([A-Z]+)([0-9]+)","\1-\2");

        // Atoms:
        if (ArrayLen(REMatch("^[0-9]+[a-z]*$",atom)) GT 0) {
             // 1234
             // 1234a
             // return " regex_like(number, '^[A-Z\-]*listpart$','i') "
             result = "( REGEXP_LIKE ( " & fieldname & ", '^[A-Z\-]*" & atom & "$','i'))";
        } else {
             //R-1234
             //R-1234a
             // return " regex_like(number, '^listpart[a-z]*$','i') "
             if (ArrayLen(REMatch("^[A-Z]+\-[0-9]+$",atom)) GT 0) {
                 result = "( REGEXP_LIKE ( " & fieldname & ", '^" & atom & "[a-z]*$','i'))";
             } else {
                 //R-1234a
                 // return " regex_like(number, '^listpart$','i') "
                 if (ArrayLen(REMatch("^[A-Z]+\-[0-9]+[a-z]+$",atom)) GT 0) {
                     result = "(" & fieldname & " = " & atom & ")";
                 } else {
                     // 1234-1235
                     // return " ( REGEXP_LIKE (number, '^" listpart "[a-z]*$','i') OR fieldname REGEX_LIKE (number, '^' listpart+1 '[a-z]*$','i') ) " ;
                     if (ArrayLen(REMatch("^[0-9]+\-[0-9]+$",atom)) GT 0) {
                         parts = ListToArray(atom,"-");
                         lowPart = parts[1];
                         highPart = parts[2];
                         if (lowPart GT highPart) {
                             lowPart = parts[2];
                             highPart = parts[1];
                         }
                         // iterate through parts
                         separator = "";
                         for(i=0; i LTE highPart-lowPart; i=i+1) {
                            tar = parts[1] + i;
                            result = result & separator  & "  REGEXP_LIKE ( " & fieldname & ", '^" & tar & "[a-z]*$','i')";
                            separator = " OR ";
                         }
                         result = " ( " & result & " ) " ;
                     } else {
                         // R-1234-1235
                         // return " ( REGEXP_LIKE (number, '^'" & listpart & "'[a-z]*$','i') OR fieldname REGEX_LIKE (number, '^" R-listpart+1 "[a-z]*$','i') ) " ;
                         if (ArrayLen(REMatch("^[A-Z]+\-[0-9]+\-[0-9]+$",atom)) GT 0) {
                            parts = ListToArray(atom,"-");
                            prefix = parts[1];
                            lowPart = parts[2];
                            highPart = parts[3];
                            if (lowPart GT highPart) {
                               lowPart = parts[3];
                               highPart = parts[2];
                            }
                            // iterate through parts
                            separator = "";
                            for(i=0; i LTE highPart-lowPart; i=i+1) {
                               tar = parts[2] + i;
                               result = result & separator & "  REGEXP_LIKE ( " & fieldname & ", '^" & prefix & "-" & tar & "[a-z]*$','i') ";
                               separator = " OR ";
                            }
                         }
                         result = " ( " & result & " ) " ;
                     }
                 }
            }
        }
        return "#result#";
    }
</cfscript>
