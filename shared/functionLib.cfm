<!---  
functionLib.cfm 

This file is to hold only globaly reused coldfusion functions.

Copyright 2019 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

  @author Paul J. Morris

--->
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
<!------------------------------------------------------------------------------------->
<cffunction name="getMediaPreview" access="public" output="true">
	<cfargument name="puri" required="true" type="string">
	<cfargument name="mt" required="false" type="string">
	<cfargument name="mmt" required="false" type="string">
	<cfset r=0>
	<cfif len(puri) gt 0>
		<!--- Hack - media.preview_uri can contain filenames that aren't correctly URI encoded as well as valid IRIs --->
		<cfhttp method="head" url="#SubsetEncodeForURL(puri)#" timeout="4">
		<cfif isdefined("cfhttp.responseheader.status_code") and cfhttp.responseheader.status_code is 200>
			<cfset r=1>
		</cfif>
	</cfif>
	<cfif r is 0>
		<cfif mt is "image">
			<cfreturn "/shared/images/noThumbnailImage.png">
		<cfelseif mt is "audio">
			<cfreturn "/shared/images/noThumbnailAudio.png">
		<cfelseif mt is "text">
			<cfreturn "/shared/images/noThumbnailDoc.png">
		<cfelseif mt is "3D model">
			<cfreturn "/shared/images/3dmodel.png">
		<cfelse>
			<cfreturn "/shared/images/noThumbnail_slide.png">
		</cfif>
	<cfelse>
		<cfreturn puri>
	</cfif>
</cffunction>
<!------------------------------------------------------------------------------------->
		
<cffunction name="getMediaPreview2" access="public" output="true">
	<cfargument name="puris" required="true" type="string">
	<cfargument name="mts" required="true" type="string">
	<cfset r=0>
	<cfif len(puri) gt 0>
		<!--- Hack - media.preview_uri can contain filenames that aren't correctly URI encoded as well as valid IRIs --->
		<cfhttp method="head" url="#SubsetEncodeForURL(puri)#" timeout="4">
		<cfif isdefined("cfhttp.responseheader.status_code") and cfhttp.responseheader.status_code is 200>
			<cfset r=1>
		</cfif>
	</cfif>
	<cfif r is 0>
		<cfif mt is "image">
			<cfreturn "/shared/images/noThumbnailDoc.png">
		<cfelseif mt is "audio">
			<cfreturn "/shared/images/noThumbnailAudio.png">
		<cfelseif mt is "text">
			<cfreturn "/shared/images/noThumbnailDoc.png">
		<cfelseif mt is "text" || #mime_type# contains "html">
			<cfreturn "/shared/images/noThumb_text-html.png">
		<cfelse>
			<cfreturn "/shared/images/noThumbnailImage.png">
		</cfif>
	<cfelse>
		<cfreturn puri>
	</cfif>
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
            <cfset temp = QuerySetCell(result, "link", "/editAccn.cfm?Action=edit&transaction_id=#related_primary_key#", i)>
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
    		        <cfset temp = QuerySetCell(result, "link", "/Deaccession.cfm?action=editDeacc&transaction_id=#related_primary_key#", i)>
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
    		        <cfset temp = QuerySetCell(result, "link", "/Borrow.cfm?Action=edit&transaction_id=#related_primary_key#", i)>
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
