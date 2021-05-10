<!---
media/component/search.cfc

Copyright 2020 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- function getMedia search for media returning json suitable for a jqxgrid --->
<cffunction name="getMedia" access="remote" returntype="any" returnformat="json">
	<cfargument name="media_uri" type="string" required="no">
	<cfargument name="media_type" type="string" required="no">
	<cfargument name="mime_type" type="string" required="no">
	<cfargument name="preview_uri" type="string" required="no">
	<cfargument name="mask_media_fg" type="string" required="no">
	<cfargument name="media_id" type="string" required="no">
	<cfargument name="has_roi" type="string" required="no">
	<cfargument name="keywords" type="string" required="no">
	<cfargument name="protocol" type="string" required="no">
	<cfargument name="filename" type="string" required="no">
	<cfargument name="description" type="string" required="no">
	<cfargument name="aspect" type="string" required="no">
	<cfargument name="height" type="string" required="no">
	<cfargument name="width" type="string" required="no">
	<cfargument name="internal_remarks" type="string" required="no">
	<cfargument name="remarks" type="string" required="no">
	<cfargument name="subject" type="string" required="no">
	<cfargument name="made_date" type="string" required="no">
	<cfargument name="to_made_date" type="string" required="no">
<!--- TODO:
original filename
owner
credit
dcterms:identifier
spectrometer
light source
spectrometer reading location
md5hash
--->
	<!--- set start/end date range terms to same if only one is specified --->
	<cfif isdefined("made_date") and len(#made_date#) gt 0>
		<cfif not isdefined("to_made_date") or len(to_made_date) is 0>
			<cfset to_made_date=made_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#made_date#) EQ 4>
			<cfset made_date = "#made_date#-01-01">
		</cfif>
		<cfif len(#to_made_date#) EQ 4>
			<cfset to_made_date = "#to_made_date#-12-31">
		</cfif>
	</cfif>

	<cfif isdefined("keywords") and len(keywords) gt 0>
		<cfset keysearch="plain">
		<cfif REFind('[ |*"]| -',keywords) >
			<!--- cat search operators:  space=AND, |=or, *=wildcard, - (preceded by space)= not, ""=quoted phrase --->
			<cfset keysearch="ctxcat">
		</cfif>
	</cfif>
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				media.media_id as media_id,
				media_type, mime_type, 
				media_uri, preview_uri,
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					decode(mask_media_fg,0,'public',1,'hidden',null,'public','error') as mask_media_fg,
				</cfif>
				CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.uri ELSE MCZBASE.get_media_dctermsrights(media.media_id) END as license_uri, 
				CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as licence_display, 
				MCZBASE.is_media_encumbered(media.media_id) as hide_media,
				MCZBASE.get_media_credit(media.media_id) as credit,
				MCZBASE.get_media_owner(media.media_id) as owner,
				MCZBASE.get_media_dcrights(media.media_id) as dc_rights,
				regexp_substr(media_uri,'^[htpsf]+:/') as protocol,
				regexp_substr(media_uri,'[^/]+$') as filename,
				MCZBASE.get_media_creator(media.media_id) as creator,
				MCZBASE.get_media_relations_string(media.media_id) as relations,
				MCZBASE.get_medialabel(media.media_id,'aspect') as aspect,
				MCZBASE.get_medialabel(media.media_id,'description') as description,
				MCZBASE.get_medialabel(media.media_id,'made date') as made_date,
				MCZBASE.get_medialabel(media.media_id,'subject') as subject,
				MCZBASE.get_medialabel(media.media_id,'original filename') as original_filename,
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					MCZBASE.get_medialabel(media.media_id,'internal remarks') as internal_remarks,
				</cfif>
				MCZBASE.get_medialabel(media.media_id,'remarks') as remarks,
				MCZBASE.get_medialabel(media.media_id,'spectrometer') as spectrometer,
				MCZBASE.get_medialabel(media.media_id,'light source') as light_source,
				MCZBASE.get_medialabel(media.media_id,'spectrometer reading location') as spectrometer_reading_location,
				MCZBASE.get_medialabel(media.media_id,'height') as height,
				MCZBASE.get_medialabel(media.media_id,'width') as width,
				MCZBASE.get_media_descriptor(media.media_id) as ac_description
			FROM 
				media
				left join ctmedia_license on media.media_license_id=ctmedia_license.media_license_id
				<cfif isdefined("keywords") and len(keywords) gt 0>
					<cfif keysearch IS "plain" >
						left join media_keywords on media.media_id = media_keywords.media_id
					</cfif>
				</cfif>
			WHERE
				media.media_id is not null
				AND MCZBASE.is_media_encumbered(media.media_id)  < 1 
				<cfif isdefined("media_type") AND len(#media_type#) gt 0>
					<cfif left(media_type,1) is "!">
						AND media_type <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(media_type,len(media_type)-1)#">
					<cfelse>
						AND media_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">
					</cfif>
				</cfif>
				<cfif isdefined("mime_type") AND len(#mime_type#) gt 0>
					<cfif left(mime_type,1) is "!">
						AND mime_type <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(mime_type,len(mime_type)-1)#">
					<cfelse>
						AND mime_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">
					</cfif>
				</cfif>
				<cfif isdefined("media_uri") AND len(media_uri) gt 0>
					<cfif left(media_uri,2) is "==">
						AND media_uri = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(media_uri,len(media_uri)-2)#">
					<cfelseif left(media_uri,1) is "=">
						AND upper(media_uri) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(media_uri,len(media_uri)-1))#">
					<cfelseif left(media_uri,2) is "!!">
						AND media_uri <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(media_uri,len(media_uri)-2)#">
					<cfelseif left(media_uri,1) is "!">
						AND upper(media_uri) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(media_uri,len(media_uri)-1))#">
					<cfelseif media_uri is "NULL">
						AND media_uri is null
					<cfelseif media_uri is "NOT NULL">
						AND media_uri is not null
					<cfelse>
						<cfif find(',',media_uri) GT 0>
							AND upper(media_uri) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(media_uri)#" list="yes"> )
						<cfelse>
							AND upper(media_uri) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(media_uri)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("mask_media_fg") AND len(#mask_media_fg#) gt 0>
					<cfif left(mask_media_fg,1) is "!">
						AND upper(mask_media_fg) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(mask_media_fg,len(mask_media_fg)-1))#">
					<cfelse>
						AND mask_media_fg = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mask_media_fg#">
					</cfif>
				</cfif>
				<cfif isdefined("media_id") AND isnumeric(#media_id#)>
					AND agent_name.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				</cfif>
				<cfif isdefined("has_roi") and len(has_roi) gt 0>
					-- tags are not, as would be expected text, but regions of interest on images, implementation appears incomplete.
					AND media.media_id in (select media_id from tag)
				</cfif>
				<cfif isdefined("keywords") and len(keywords) gt 0>
					<cfif keysearch IS "plain" >
						AND upper(keywords) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(keywords)#%">
					<cfelse>
						AND media.media_id in (select media_id from media_keywords where CATSEARCH(keywords,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#keywords#">,NULL) > 0) 
					</cfif>
				</cfif>
				<cfif isdefined("created_by_agent_id") and len(created_by_agent_id) gt 0>
					AND media.media_id in 
					(
						select media_id 
						from media_relations
						where media_relationship = 'created by agent' and related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#created_by_agent_id#">
					)
				</cfif>
				<cfif isdefined("description") and len(description) gt 0>
					<cfif description IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'description' )
					<cfelseif description IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'description' )
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where media_label = 'description' and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(description)#%">
						)
					</cfif>
				</cfif>
				<cfif isdefined("remarks") and len(remarks) gt 0>
					<cfif remarks IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'remarks' )
					<cfelseif remarks IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'description' )
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where media_label = 'remarks' and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(remarks)#%">
						)
					</cfif>
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfif isdefined("internal_remarks") and len(internal_remarks) gt 0>
						<cfif internal_remarks IS "NULL">
							AND media.media_id not in ( select media_id from media_labels where media_label = 'internal remarks' )
						<cfelseif internal_remarks IS "NOT NULL">
							AND media.media_id in ( select media_id from media_labels where media_label = 'internal remarks' )
						<cfelse>
							AND media.media_id in (
								select media_id 
								from media_labels 
								where media_label = 'internal_remarks' and label_value like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(internal_remarks)#%">
							)
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("subject") and len(subject) gt 0>
					<cfif subject IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'subject' )
					<cfelseif subject IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'description' )
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where media_label = 'subject' and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subject)#%">
						)
					</cfif>
				</cfif>
				<cfif isdefined("aspect") and len(aspect) gt 0>
					<cfif aspect IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'aspect')
					<cfelseif aspect IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'aspect')
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where 
								media_label = 'aspect' 
							<cfif left(aspect,1) is "=">
								and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(aspect,len(aspect)-1))#"> 
							<cfelse>
								and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(aspect)#%"> 
							</cfif>
						)
					</cfif>
				</cfif>
				<cfif isdefined("height") and len(height) gt 0>
					<cfif height IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'height')
					<cfelseif height IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'height')
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where 
								media_label = 'height' 
							<cfif left(height,1) is ">">
								and upper(label_value) > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(right(height,len(height)-1))#"> 
							<cfelseif left(height,1) is "<">
								and upper(label_value) < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(right(height,len(height)-1))#"> 
							<cfelse>
								and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#height#"> 
							</cfif>
						)
					</cfif>
				</cfif>
				<cfif isdefined("width") and len(width) gt 0>
					<cfif width IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'width')
					<cfelseif width IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'width')
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where 
								media_label = 'width' 
							<cfif left(width,1) is ">">
								and upper(label_value) > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(right(width,len(width)-1))#"> 
							<cfelseif left(width,1) is "<">
								and upper(label_value) < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(right(width,len(width)-1))#"> 
							<cfelse>
								and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#width#"> 
							</cfif>
						)
					</cfif>
				</cfif>
				<cfif isdefined("made_date") and len(made_date) gt 0>
					AND media.media_id in (
						select media_id 
						from media_labels 
						where 
							media_label = 'made date' 
							AND 
							label_value IS NOT NULL
							AND
							((
								regexp_like(label_value,'[0-9]{4}-([0][1-9]|[1][0-2])-([0][1-9]|[1][0-9]|[3][0-2])')  
								AND 
								to_date(label_value,'yyyy-mm-dd') between 
								<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(made_date, "yyyy-mm-dd")#'> and
								<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_made_date, "yyyy-mm-dd")#'>
							  ) OR (  
								regexp_like(label_value,'[0-9]{2}-[JANFEBMRPYULAGSOCTVD]{3}-[0-9]{2}')
								AND 
								to_date(label_value,'dd-MM-yy') between 
								<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(made_date, "yyyy-mm-dd")#'> and
								<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_made_date, "yyyy-mm-dd")#'>
							  ) OR (  
								regexp_like(label_value,'[0-9]{2} [A-Z][a-z]+ [0-9]{4}')
								AND 
								to_date(label_value,'dd Mm yyyy') between 
								<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(made_date, "yyyy-mm-dd")#'> and
								<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_made_date, "yyyy-mm-dd")#'>
							))
					)
				</cfif>
				<cfif isdefined("filename") and len(filename) gt 0>
					<!--- too slow: AND regexp_substr(media_uri,'[^/]+$') = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#filename#"> --->
					AND media_uri like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#filename#">
				</cfif>
				<cfif isdefined("protocol") and len(protocol) gt 0>
					<cfif protocol IS "http">
						AND media_uri like 'http://%'
					<cfelseif protocol IS "https">
						AND media_uri like 'https://%'
					<cfelseif protocol IS 'httphttps'>
						AND (media_uri like 'https://%' OR media_uri like 'http://') 
					<cfelseif protocol IS 'NULL'>
						AND regexp_substr(media_uri,'^[htpsf]+://') IS NULL
					</cfif>
				</cfif>
			ORDER BY media.media_uri
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset row["id_link"] = "<a href='/media/Media.cfm?media_id#search.media_id#' target='_blank'>#search.media_uri#</a>">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!--- backing for a media label aspect autocomplete control --->
<cffunction name="getAspectAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select 
				count(*) ct,
				label_value
			from 
				media_labels
			where 
				media_label = 'aspect' 
				AND upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
			group by label_value
			order by label_value
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["value"] = "#search.label_value#" >
			<cfset row["meta"] = "#search.label_value# (#search.ct#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
