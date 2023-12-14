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
	<cfset r=0>
	<cfif len(puri) gt 0>
		<!--- Hack - media.preview_uri can contain filenames that aren't correctly URI encoded as well as valid IRIs --->
		<cfhttp method="head" url="#SubsetEncodeForURL(puri)#" timeout="3">
		<cfif isdefined("cfhttp.responseheader.status_code") and cfhttp.responseheader.status_code is 200>
			<cfset r=1>
		</cfif>
	</cfif>
	<cfif r is 0>
		<cfif mt contains "image">
			<cfreturn "/shared/images/48px-Gnome-image-x-generic.svg.png">
		<cfelseif mt contains "audio" >
			<cfreturn "/shared/images/noThumbnailAudio.png">
		<cfelseif mt contains "text">
			<cfreturn "/shared/images/48px-Gnome-text-x-preview.svg.png">
		<cfelseif mt contains "model">
			<cfreturn "/shared/images/3dmodel.png">
		<cfelse>
			<cfreturn "/shared/images/noThumbDoc.png"><!---nothing was working for mime type--->
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
		
<!------------------------------------------------------------------------------------->
<cffunction name="unsafeSql" access="public" output="false" returntype="boolean">
	<cfargument name="sql" required="true" type="string">
	<!--- NOTE: Limited use, poor approach to sanitizing sql, it is well understood that methods that "exclude bad" can be evaded in ways that "allow only good" cannot. --->
	<cfset nono="update,insert,delete,drop,create,alter,set,execute,exec,begin,declare,all_tables,v$session,all_users">
	<cfset dels="';','|',">
	<cfset unsafeFound=0>
	<cfloop index="i" list="#sql#" delimiters=" .,?!;:%$&""'/|[]{}()#chr(10)##chr(13)##chr(9)#">
		<cfif ListFindNoCase(nono, i)>
			<cfset unsafeFound=1>
		</cfif>
	</cfloop>
	<cfif unsafeFound gt 0>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>
<!----------------------------------------------------->
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
				SELECT
					higher_geog || ': ' || spec_locality data
				FROM
					locality
					LEFT JOIN geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
				WHERE
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
				SELECT
					higher_geog || ': ' || spec_locality || ' (' || verbatim_date || ')' data
				FROM
					collecting_event
					LEFT JOIN locality on collecting_event.locality_id=locality.locality_id
					LEFT JOIN geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
				WHERE
					collecting_event.collecting_event_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/showLocality.cfm?action=srch&collecting_event_id=#related_primary_key#", i)>
		<cfelseif table_name is "accn">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					collection || ' ' || accn_number data
				FROM
					collection
					LEFT JOIN trans on collection.collection_id=trans.collection_id 
					LEFT JOIN accn on trans.transaction_id=accn.transaction_id
				WHERE
					accn.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/transactions/Accession.cfm?action=edit&transaction_id=#related_primary_key#", i)>
		<cfelseif table_name is "deaccession">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					collection || ' ' || deacc_number data
				FROM
					collection 
					LEFT JOIN trans on collection.collection_id=trans.collection_id
					LEFT JOIN deaccession on trans.transaction_id=deaccession.transaction_id
				WHERE
					deaccession.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
    		        <cfset temp = QuerySetCell(result, "link", "/transactions/Deaccession.cfm?action=edit&transaction_id=#related_primary_key#", i)>
		<cfelseif table_name is "loan">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					collection || ' ' || loan_number data
				FROM
					collection
					LEFT JOIN trans on collection.collection_id=trans.collection_id
					LEFT JOIN loan on trans.transaction_id=loan.transaction_id
				WHERE
					loan.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#" >
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
    		        <cfset temp = QuerySetCell(result, "link", "/transactions/Loan.cfm?Action=editLoan&transaction_id=#related_primary_key#", i)>
		<cfelseif table_name is "borrow">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					collection || ' ' || borrow_number data
				FROM
					collection
					LEFT JOIN trans on collection.collection_id=trans.collection_id
					LEFT JOIN borrow on trans.transaction_id=borrow.transaction_id 
				WHERE
					borrow.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#" >
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
    		        <cfset temp = QuerySetCell(result, "link", "/transactions/Borrow.cfm?Action=edit&transaction_id=#related_primary_key#", i)>
		<cfelseif table_name is "permit">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					permit_Type || ' ' || agent_name || ' ' || permit_Num data
				FROM
					permit
					LEFT JOIN preferred_agent_name on permit.issued_by_agent_id = preferred_agent_name.agent_id
				WHERE
					permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#" >
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
			<cfset temp = QuerySetCell(result, "link", "/transactions/Permit.cfm?action=edit&permit_id=#related_primary_key#", i)>
		<cfelseif table_name is "cataloged_item">
		<!--- upping this to uam_god for now - see Issue 135
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		---->
			<cfquery name="d" datasource="uam_god">
				SELECT collection || ' ' || cat_num || ' (' || scientific_name || ')' data 
				FROM
					cataloged_item
					left join collection on cataloged_item.collection_id=collection.collection_id
					left join identification on cataloged_item.collection_object_id=identification.collection_object_id
				WHERE
					accepted_id_fg=1 and
					cataloged_item.collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
			<cfset temp = QuerySetCell(result, "link", "/SpecimenResults.cfm?collection_object_id=#related_primary_key#", i)>
		<cfelseif table_name is "media">
			<cfif media_relationship IS "transcript for audio media">
				<cfquery name="d" datasource="uam_god">
					select media_uri data 
					from media 
					where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
				</cfquery>
				<cfset temp = QuerySetCell(result, "summary", "view the transcript", i)>
				<cfset temp = QuerySetCell(result, "link", "#d.data#", i)>
			<cfelse>
				<cfquery name="d" datasource="uam_god">
					select media_uri data 
					from media 
					where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
				</cfquery>
				<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
				<cfset temp = QuerySetCell(result, "link", "/media/#related_primary_key#", i)>
			</cfif>
		<cfelseif table_name is "publication">
			<cfquery name="d" datasource="uam_god">
				select formatted_publication data 
				from formatted_publication 
				where format_style='long' and
				publication_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_primary_key#">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
			<cfset temp = QuerySetCell(result, "link", "/publications/showPublication.cfm?publication_id=#related_primary_key#", i)>
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

<cffunction name="CSVToArray" access="public" returntype="array" output="false" hint="Converts the given CSV string to an array of arrays.">
	<cfargument name="CSV" type="string" required="true" hint="This is the CSV string that will be manipulated." />
	<cfargument name="Delimiter" type="string" required="false" default="," hint="This is the delimiter that will separate the fields within the CSV value." />
	<cfargument name="Qualifier" type="string" required="false" default="""" hint="This is the qualifier that will wrap around fields that have special characters embeded." />

	<cfset var LOCAL = StructNew() />
	<cfset ARGUMENTS.Delimiter = Left( ARGUMENTS.Delimiter, 1 ) />
	<cfif Len( ARGUMENTS.Qualifier )>
 	    <cfset ARGUMENTS.Qualifier = Left( ARGUMENTS.Qualifier, 1 ) />
	</cfif>
	<cfset LOCAL.LineDelimiter = Chr( 13 ) />
	<cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll( "\r?\n", LOCAL.LineDelimiter) />
	<cfset LOCAL.Delimiters = ARGUMENTS.CSV.ReplaceAll( "[^\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]+", "") .ToCharArray() />
	<cfset ARGUMENTS.CSV = (" " & ARGUMENTS.CSV) />

	<!--- Now add the space to each field. --->
	<cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll( "([\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]{1})", "$1 ") />
	<cfset LOCAL.Tokens = ARGUMENTS.CSV.Split( "[\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]{1}") />
	<cfset LOCAL.Return = ArrayNew( 1 ) />
	<cfset ArrayAppend( LOCAL.Return, ArrayNew( 1 )) />
	<cfset LOCAL.RowIndex = 1 />
	<cfset LOCAL.IsInValue = false />
	<cfloop index="LOCAL.TokenIndex" from="1" to="#ArrayLen( LOCAL.Tokens )#" step="1">
		<cfset LOCAL.FieldIndex = ArrayLen( LOCAL.Return[ LOCAL.RowIndex ]) />
		<cfset LOCAL.Token = LOCAL.Tokens[ LOCAL.TokenIndex ].ReplaceFirst( "^.{1}", "") />
		<cfif Len( ARGUMENTS.Qualifier )>
			<cfif LOCAL.IsInValue>
				<cfset LOCAL.Token = LOCAL.Token.ReplaceAll( "\#ARGUMENTS.Qualifier#{2}", "{QUALIFIER}") />
				<cfset LOCAL.Return[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] = ( LOCAL.Return[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] & LOCAL.Delimiters[ LOCAL.TokenIndex - 1 ] & LOCAL.Token) />
				<cfif (Right( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
					<cfset LOCAL.Return[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] = LOCAL.Return[ LOCAL.RowIndex ][ LOCAL.FieldIndex ].ReplaceFirst( ".{1}$", "" ) />
					<cfset LOCAL.IsInValue = false />
				</cfif>
			<cfelse>
				<cfif (Left( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
					<cfset LOCAL.Token = LOCAL.Token.ReplaceFirst( "^.{1}", "") />
					<cfset LOCAL.Token = LOCAL.Token.ReplaceFirst( ",.{1}", "") />
					<cfset LOCAL.Token = LOCAL.Token.ReplaceAll( "\#ARGUMENTS.Qualifier#{2}", "{QUALIFIER}") />
					<cfif (Right( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
						<cfset ArrayAppend( LOCAL.Return[ LOCAL.RowIndex ], LOCAL.Token.ReplaceFirst( ".{1}$", "")) />
					<cfelse>
						<cfset LOCAL.IsInValue = true />
						<cfset ArrayAppend( LOCAL.Return[ LOCAL.RowIndex ], LOCAL.Token) />
					</cfif>
				<cfelse>
					<cfset ArrayAppend( LOCAL.Return[ LOCAL.RowIndex ], LOCAL.Token) />
				</cfif>
			</cfif>
			<cfset LOCAL.Return[ LOCAL.RowIndex ][ ArrayLen( LOCAL.Return[ LOCAL.RowIndex ] ) ] = Replace( LOCAL.Return[ LOCAL.RowIndex ][ ArrayLen( LOCAL.Return[ LOCAL.RowIndex ] ) ], "{QUALIFIER}", ARGUMENTS.Qualifier, "ALL") />
		<cfelse>
			<cfset ArrayAppend( LOCAL.Return[ LOCAL.RowIndex ], LOCAL.Token) />
		</cfif>
		<cfif ( (NOT LOCAL.IsInValue) AND (LOCAL.TokenIndex LT ArrayLen( LOCAL.Tokens )) AND (LOCAL.Delimiters[ LOCAL.TokenIndex ] EQ LOCAL.LineDelimiter))>
			<cfset ArrayAppend( LOCAL.Return, ArrayNew( 1 )) />
			<cfset LOCAL.RowIndex = (LOCAL.RowIndex + 1) />
		</cfif>
	</cfloop>
	<cfreturn LOCAL.Return />

</cffunction>
