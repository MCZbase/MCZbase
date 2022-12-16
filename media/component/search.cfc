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
<cfif NOT isDefined("reportError")>
	<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
</cfif>

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
	<cfargument name="hostname" type="string" required="no">
	<cfargument name="path" type="string" required="no">
	<cfargument name="filename" type="string" required="no">
	<cfargument name="extension" type="string" required="no">
	<cfargument name="description" type="string" required="no">
	<cfargument name="aspect" type="string" required="no">
	<cfargument name="height" type="string" required="no">
	<cfargument name="width" type="string" required="no">
	<cfargument name="internal_remarks" type="string" required="no">
	<cfargument name="remarks" type="string" required="no">
	<cfargument name="subject" type="string" required="no">
	<cfargument name="made_date" type="string" required="no">
	<cfargument name="to_made_date" type="string" required="no">
	<cfargument name="text_made_date" type="string" required="no">
	<cfargument name="original_filename" type="string" required="no">
	<cfargument name="light_source" type="string" required="no">
	<cfargument name="md5hash" type="string" required="no">
	<cfargument name="owner" type="string" required="no">
	<cfargument name="credit" type="string" required="no">
	<cfargument name="spectrometer" type="string" required="no">
	<cfargument name="spectrometer_reading_location" type="string" required="no">
	<cfargument name="media_label_type" type="string" required="no">
	<cfargument name="media_label_value" type="string" required="no">
	<cfargument name="related_cataloged_item" type="string" required="no">
	<cfargument name="collection_object_id" type="string" required="no">
	<cfargument name="unlinked" type="string" required="no">
	<cfargument name="multilink" type="string" required="no">
	<cfargument name="multitypelink" type="string" required="no">
	<cfargument name="media_relationship_type" type="string" required="no">
	<cfargument name="media_relationship_value" type="string" required="no">
	<cfargument name="media_relationship_id" type="string" required="no">
	<cfargument name="media_relationship_type_1" type="string" required="no">
	<cfargument name="media_relationship_value_1" type="string" required="no">
	<cfargument name="media_relationship_id_1" type="string" required="no">

	<cfif not isdefined("unlinked")>
		<cfset unlinked = "">
	</cfif>
	<cfif isdefined("media_id") AND len(trim(media_id)) GT 0 AND NOT isnumeric(#media_id#)>
		<cfthrow message = "Media ID must be an integer.  Provided value [#encodeForHtml(media_id)#] is not numeric.">
	</cfif>
	<cfif (isdefined("related_cataloged_item") AND len(#related_cataloged_item#) gt 0) AND related_cataloged_item NEQ 'NOT NULL' >
		<cfquery name="guidSearch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="guidSearch_result">
			select collection_object_id as cat_item_coll_obj_id 
			from 
				<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
			where
				flat.guid in ( <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_cataloged_item#" list="yes"> )
		</cfquery>
		<cfloop query="guidSearch">
			<cfif not listContains(collection_object_id,guidSearch.cat_item_coll_obj_id)>
				<cfif len(collection_object_id) EQ 0>
					<cfset collection_object_id = guidSearch.cat_item_coll_obj_id>
				<cfelse>
					<cfset collection_object_id = collection_object_id & "," & guidSearch.cat_item_coll_obj_id>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>

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
	<cfif isdefined("media_relationship_value") AND (media_relationship_value EQ "NULL" OR media_relationship_value EQ "NOT NULL")>
		<!--- set a non-meaningfull, but non-empty value for media_relationship_id to support CFIF logic in building query --->
		<cfset media_relationship_id = "-1">
		<cfif (NOT isdefined("media_relationship_type") OR len(media_relationship_value) EQ 0) AND media_relationship_value EQ "NULL" >
			<!--- NULL and no relationship type specified, treat as if unlinked were selected. --->
			<cfset unlinked = "true">
		</cfif>
	</cfif>
	<cfif isdefined("media_relationship_value_1") AND (media_relationship_value_1 EQ "NULL" OR media_relationship_value_1 EQ "NOT NULL")>
		<!--- set a non-meaningfull, but non-empty value for media_relationship_id_1 to support CFIF logic in building query --->
		<cfset media_relationship_id_1 = "-1">
		<cfif (NOT isdefined("media_relationship_type_1") OR len(media_relationship_value_1) EQ 0) AND media_relationship_value_1 EQ "NULL" >
			<!--- NULL and no relationship type specified, treat as if unlinked were selected. --->
			<cfset unlinked = "true">
		</cfif>
	</cfif>
	<cfif isdefined("media_relationship_id") AND isdefined("media_relationship_type") and isdefined("media_relationship_value")>
		<!--- support search from media cell renderer on specimen search for non-logged in users ---> 
		<cfif media_relationship_id EQ "undefined" AND media_relationship_type EQ "ANY cataloged_item">
			<cfquery name="lookup_collobject_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookup_result">
				SELECT distinct collection_object_id 
				FROM 	
					<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif>
				WHERE  
					guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship_value#">
			</cfquery>
			<cfloop query="lookup_collobject_id">
				<cfset media_relationship_id = lookup_collobject_id.collection_object_id>
			</cfloop>
		</cfif>
	</cfif>
	<cfif isdefined("media_relationship_id_1") AND isdefined("media_relationship_type_1") and isdefined("media_relationship_value_1")>
		<!--- support search from media cell renderer on specimen search for non-logged in users ---> 
		<cfif media_relationship_id_1 EQ "undefined" AND media_relationship_type_1 EQ "ANY cataloged_item">
			<cfquery name="lookup_collobject_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookup_result">
				SELECT distinct collection_object_id 
				FROM 	
					<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif>
				WHERE  
					guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship_value_1#">
			</cfquery>
			<cfloop query="lookup_collobject_id">
				<cfset media_relationship_id_1 = lookup_collobject_id.collection_object_id>
			</cfloop>
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
				MCZBASE.get_media_dctermsrights(media.media_id) as license_uri, 
				MCZBASE.get_media_dcrights(media.media_id) as license_display, 
				MCZBASE.is_media_encumbered(media.media_id) as hide_media,
				MCZBASE.get_media_credit(media.media_id) as credit,
				MCZBASE.get_media_owner(media.media_id) as owner,
				auto_protocol as protocol,
				auto_host as host,
				auto_path as path,
				auto_filename as filename,
				auto_extension as extension,
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
				<cfif len(unlinked) EQ 0>
					<cfif (isdefined("related_cataloged_item") AND len(related_cataloged_item) GT 0) OR (isdefined("underscore_collection_id") AND len(underscore_collection_id) GT 0)>
					left join media_relations media_relations_ci on media.media_id=media_relations_ci.media_id
					</cfif>
					<cfif isdefined("underscore_collection_id") AND len(underscore_collection_id) GT 0 >
					left join underscore_relation on media_relations.related_primary_key = underscore_relation.collection_object_id
					</cfif>
					<cfif isdefined("media_relationship_type") AND len(media_relationship_type) GT 0 AND isdefined("media_relationship_id") AND len(media_relationship_id) GT 0 >
					left join media_relations media_relations_rt on media.media_id=media_relations_rt.media_id
					</cfif>
					<cfif isdefined("media_relationship_type_1") AND len(media_relationship_type_1) GT 0 AND isdefined("media_relationship_id_1") AND len(media_relationship_id_1) GT 0 >
					left join media_relations media_relations_rt_1 on media.media_id=media_relations_rt_1.media_id
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
					AND mime_type in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#" list="yes">)
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
					AND media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				</cfif>
				<cfif isdefined("has_roi") and len(has_roi) gt 0>
					<!--- tags are not, as would be expected text, but regions of interest on images, implementation appears incomplete.--->
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
					<!---- TODO: look at UTL_MATCH.JARO_WINKLER matching---->
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
						AND media.media_id in ( select media_id from media_labels where media_label = 'remarks' )
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
						AND media.media_id in ( select media_id from media_labels where media_label = 'subject' )
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where media_label = 'subject' and 
								<cfif left(subject,1) is "=">
									label_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(subject,len(subject)-1)#"> 
								<cfelse>
									upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subject)#%">
								</cfif>
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
									and label_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(aspect,len(aspect)-1)#"> 
								<cfelse>
									and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(aspect)#%"> 
								</cfif>
						)
					</cfif>
				</cfif>
				<cfif isdefined("original_filename") and len(original_filename) gt 0>
					<cfif original_filename IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'original filename')
					<cfelseif original_filename IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'original filename')
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where 
								media_label = 'original filename' 
							<cfif left(original_filename,1) is "=">
								and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(original_filename,len(original_filename)-1))#"> 
							<cfelse>
								and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(original_filename)#%"> 
							</cfif>
						)
					</cfif>
				</cfif>
				<cfif isdefined("light_source") and len(light_source) gt 0>
					<cfif light_source IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'light source')
					<cfelseif light_source IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'light source')
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where 
								media_label = 'light source' 
							<cfif left(light_source,1) is "=">
								and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(light_source,len(light_source)-1))#"> 
							<cfelse>
								and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(light_source)#%"> 
							</cfif>
						)
					</cfif>
				</cfif>
				<cfif isdefined("spectrometer_reading_location") and len(spectrometer_reading_location) gt 0>
					<cfif spectrometer_reading_location IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'spectrometer reading location')
					<cfelseif spectrometer_reading_location IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'spectrometer reading location')
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where 
								media_label = 'spectrometer reading location' 
							<cfif left(spectrometer_reading_location,1) is "=">
								and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(spectrometer_reading_location,len(spectrometer_reading_location)-1))#"> 
							<cfelse>
								and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(spectrometer_reading_location)#%"> 
							</cfif>
						)
					</cfif>
				</cfif>
				<cfif isdefined("spectrometer") and len(spectrometer) gt 0>
					<cfif spectrometer IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'spectrometer')
					<cfelseif spectrometer IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'spectrometer')
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where 
								media_label = 'spectrometer' 
							<cfif left(spectrometer,1) is "=">
								and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(spectrometer,len(spectrometer)-1))#"> 
							<cfelse>
								and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(spectrometer)#%"> 
							</cfif>
						)
					</cfif>
				</cfif>
				<cfif isdefined("media_label_type") and len(media_label_type) gt 0 AND isdefined("media_label_value") and len(media_label_value) gt 0>
					<cfif media_label_value IS "NULL">
						AND media.media_id not in 
							( select media_id from media_labels 
								where 
									media_label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_label_type#"> 
							)
					<cfelseif media_label_value IS "NOT NULL">
						AND media.media_id in 
							( select media_id from media_labels 
							where 
								media_label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_label_type#"> 
							)
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where 
								media_label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_label_type#"> 
							<cfif left(media_label_value,1) is "=">
								and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(media_label_value,len(media_label_value)-1))#"> 
							<cfelse>
								and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(media_label_value)#%"> 
							</cfif>
						)
					</cfif>
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfif isdefined("credit") and len(credit) gt 0>
						<cfif credit IS "NULL">
							AND media.media_id not in ( select media_id from media_labels where media_label = 'credit')
						<cfelseif credit IS "NOT NULL">
							AND media.media_id in ( select media_id from media_labels where media_label = 'credit')
						<cfelse>
							AND media.media_id in (
								select media_id 
								from media_labels 
								where 
									media_label = 'credit' 
								<cfif left(credit,1) is "=">
									and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(credit,len(credit)-1))#"> 
								<cfelse>
									and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(credit)#%"> 
								</cfif>
							)
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfif isdefined("owner") and len(owner) gt 0>
						<cfif owner IS "NULL">
							AND media.media_id not in ( select media_id from media_labels where media_label = 'owner')
						<cfelseif owner IS "NOT NULL">
							AND media.media_id in ( select media_id from media_labels where media_label = 'owner')
						<cfelse>
							AND media.media_id in (
								select media_id 
								from media_labels 
								where 
									media_label = 'owner' 
								<cfif left(owner,1) is "=">
									and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(owner,len(owner)-1))#"> 
								<cfelse>
									and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(owner)#%"> 
								</cfif>
							)
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfif isdefined("md5hash") and len(md5hash) gt 0>
						<cfif md5hash IS "NULL">
							AND media.media_id not in ( select media_id from media_labels where media_label = 'md5hash')
						<cfelseif md5hash IS "NOT NULL">
							AND media.media_id in ( select media_id from media_labels where media_label = 'md5hash')
						<cfelse>
							AND media.media_id in (
								select media_id 
								from media_labels 
								where 
									media_label = 'md5hash' 
								<cfif left(md5hash,1) is "=">
									and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(md5hash,len(md5hash)-1))#"> 
								<cfelse>
									and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(md5hash)#%"> 
								</cfif>
							)
						</cfif>
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
				<cfif isdefined("text_made_date") and len(text_made_date) gt 0>
					<cfif text_made_date IS "NULL">
						AND media.media_id not in ( select media_id from media_labels where media_label = 'made date')
					<cfelseif text_made_date IS "NOT NULL">
						AND media.media_id in ( select media_id from media_labels where media_label = 'made date')
					<cfelse>
						AND media.media_id in (
							select media_id 
							from media_labels 
							where 
								media_label = 'made date'
							<cfif left(text_made_date,1) is "=">
								and upper(label_value) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(text_made_date,len(text_made_date)-1))#"> 
							<cfelse>
								and upper(label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(text_made_date)#%"> 
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
							to_date_safe(label_value) between 
								<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(made_date, "yyyy-mm-dd")#'> and
								<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_made_date, "yyyy-mm-dd")#'>
					)
				</cfif>
				<cfif isdefined("extension") and len(extension) gt 0>
					<cfif extension is "NULL">
						AND auto_extension is null
					<cfelseif extension is "NOT NULL">
						AND auto_extension is not null
					<cfelse>
						AND auto_extension in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#extension#" list="yes"> )
					</cfif>
				</cfif>
				<cfif isdefined("filename") and len(filename) gt 0>
					<cfif left(filename,2) is "==">
						AND auto_filename = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(filename,len(filename)-2)#">
					<cfelseif left(filename,1) is "=">
						AND upper(auto_filename) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(filename,len(filename)-1))#">
					<cfelseif left(filename,2) is "!!">
						AND auto_filename <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(filename,len(filename)-2)#">
					<cfelseif left(filename,1) is "~">
						AND utl_match.jaro_winkler(auto_filename, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(filename,len(filename)-1)#">) >= 0.90
					<cfelseif left(filename,1) is "!~">
						AND utl_match.jaro_winkler(auto_filename, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(filename,len(filename)-1)#">) < 0.90
					<cfelseif left(filename,1) is "!">
						AND upper(auto_filename) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(filename,len(filename)-1))#">
					<cfelseif filename is "NULL">
						AND auto_filename is null
					<cfelseif filename is "NOT NULL">
						AND auto_filename is not null
					<cfelse>
						<cfif find(',',filename) GT 0>
							AND upper(auto_filename) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(filename)#" list="yes"> )
						<cfelse>
							AND upper(auto_filename) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(filename)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("path") and len(path) gt 0>
					<cfif left(path,2) is "==">
						AND auto_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(path,len(path)-2)#">
					<cfelseif left(path,1) is "=">
						AND upper(auto_path) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(path,len(path)-1))#">
					<cfelseif left(path,2) is "!!">
						AND auto_path <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(path,len(path)-2)#">
					<cfelseif left(path,1) is "!">
						AND upper(auto_path) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(path,len(path)-1))#">
					<cfelseif path is "NULL">
						AND auto_path is null
					<cfelseif path is "NOT NULL">
						AND auto_path is not null
					<cfelse>
						<cfif find(',',path) GT 0>
							AND upper(auto_path) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(path)#" list="yes"> )
						<cfelse>
							AND upper(auto_path) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(path)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("hostname") and len(hostname) gt 0>
					<cfif left(hostname,2) is "==">
						AND auto_host = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(hostname,len(hostname)-2)#">
					<cfelseif left(hostname,1) is "=">
						AND upper(auto_host) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(hostname,len(hostname)-1))#">
					<cfelseif left(hostname,2) is "!!">
						AND auto_host <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(hostname,len(hostname)-2)#">
					<cfelseif left(hostname,1) is "!">
						AND upper(auto_host) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(hostname,len(hostname)-1))#">
					<cfelseif hostname is "NULL">
						AND auto_host is null
					<cfelseif hostname is "NOT NULL">
						AND auto_host is not null
					<cfelse>
						<cfif find(',',hostname) GT 0>
							AND upper(auto_host) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(hostname)#" list="yes"> )
						<cfelse>
							AND upper(auto_host) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(hostname)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("protocol") and len(protocol) gt 0>
					<cfif protocol IS "http">
						AND auto_protocol = 'http'
					<cfelseif protocol IS "https">
						AND auto_protocol = 'https'
					<cfelseif protocol IS 'httphttps'>
						AND (media_uri like 'https://%' OR media_uri like 'http://%') 
					<cfelseif protocol IS 'NULL'>
						AND auto_protocol IS NULL
					<cfelse>
						AND auto_protocol = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#protocol#'>
					</cfif>
				</cfif>
				<cfif len(unlinked) GT 0>
					and media.media_id not in (select media_id from media_relations where media_relationship <> 'created by agent')
				<cfelse>
					<cfif isdefined("multilink") and len(multilink) gt 0>
						AND media.media_id in (
							SELECT media_id FROM media_relations WHERE media_relationship <> 'created by agent'
							GROUP BY media_id
							HAVING count(*) > 1
						)
					</cfif>
					<cfif isdefined("multitypelink") and len(multitypelink) gt 0>
						AND media.media_id in (
							SELECT media_id FROM media_relations WHERE media_relationship <> 'created by agent'
							GROUP BY media_id
							HAVING count(distinct media_relationship) > 1
						)
					</cfif>
					<cfif isdefined("related_cataloged_item") and len(related_cataloged_item) gt 0>
						AND media_relations_ci.media_relationship = 'shows cataloged_item'
						<cfif related_cataloged_item IS 'NOT NULL'>
							AND media_relations_ci.related_primary_key IS NOT NULL
						<cfelse>
							AND media_relations_ci.related_primary_key in ( <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes"> )
						</cfif>
					</cfif>
					<cfif isdefined("underscore_collection_id") and len(underscore_collection_id) gt 0 >
						AND media_relations_ci.media_relationship = 'shows cataloged_item'
						<cfif underscore_collection_id IS 'NOT NULL'>
							AND underscore_relation.collection_object_id IS NOT NULL
						<cfelse>
							AND underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
						</cfif>
					</cfif>
					<cfif isdefined("media_relationship_type") AND len(media_relationship_type) GT 0 AND isdefined("media_relationship_id") AND len(media_relationship_id) GT 0 >
						<cfif media_relationship_type CONTAINS 'ANY'>
							AND media_relations_rt.media_relationship like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#replace(media_relationship_type,'ANY','%')#">
						<cfelse>
							AND media_relations_rt.media_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship_type#">
						</cfif>
						<cfif media_relationship_value IS 'NOT NULL'>
							AND media_relations_rt.related_primary_key IS NOT NULL
						<cfelse>
							AND media_relations_rt.related_primary_key in ( <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_relationship_id#" list="yes"> )
						</cfif>
					</cfif>
					<cfif isdefined("media_relationship_type_1") AND len(media_relationship_type_1) GT 0 AND isdefined("media_relationship_id_1") AND len(media_relationship_id_1) GT 0 >
						<cfif media_relationship_type_1 CONTAINS 'ANY'>
							AND media_relations_rt_1.media_relationship like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#replace(media_relationship_type_1,'ANY','%')#">
						<cfelse>
							AND media_relations_rt_1.media_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship_type_1#">
						</cfif>
						<cfif media_relationship_value IS 'NOT NULL'>
							AND media_relations_rt_1.related_primary_key IS NOT NULL
						<cfelse>
							AND media_relations_rt_1.related_primary_key in ( <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_relationship_id_1#" list="yes"> )
						</cfif>
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
			<cfset row["id_link"] = "<a href='/media.cfm?media_id#search.media_id#' target='_blank'>#search.media_uri#</a>">
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

<!--- backing for an arbitrary media label autocomplete control --->
<cffunction name="getMediaLabelAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="media_label" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			<cfif media_label IS 'internal remarks'>
				<cfthrow message="Insufficent Access Rights">
			</cfif>
		</cfif>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select 
				count(*) ct,
				label_value
			from 
				media_labels
			where 
				media_label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_label#"> 
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


<!--- backing for an autocomplete to list media label values in use (types of media label) --->
<cffunction name="getMediaLabelTypeAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT DISTINCT
				media_label
			FROM
				media_labels
			WHERE 
				upper(media_label) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%"> 
			ORDER BY
				media_label
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["value"] = "#search.media_label#" >
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

<!--- backing for a media hostname autocomplete control --->
<cffunction name="getHostnameAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select 
				count(*) ct,
				auto_host
			from 
				media
			where 
				auto_host is not null 
				AND upper(auto_host) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
			group by auto_host
			order by auto_host
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["value"] = "#search.auto_host#" >
			<cfset row["meta"] = "#search.auto_host# (#search.ct#)" >
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

<!--- backing for a media path autocomplete control --->
<cffunction name="getPathAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select 
				count(*) ct,
				auto_path
			from 
				media
			where 
				MCZBASE.is_media_encumbered(media.media_id)  < 1 
				AND upper(auto_path) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
			group by auto_path
			order by auto_path
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["value"] = "#search.auto_path#" >
			<cfset row["meta"] = "#search.auto_path# (#search.ct#)" >
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

<!--- backing for a media filename autocomplete control --->
<cffunction name="getFilenameAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select 
				count(*) ct,
				auto_filename
			from 
				media
			where 
				MCZBASE.is_media_encumbered(media.media_id)  < 1 
				AND upper(auto_filename) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
			group by auto_filename
			order by auto_filename
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["value"] = "#search.auto_filename#" >
			<cfset row["meta"] = "#search.auto_filename# (#search.ct#)" >
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

<!--- function getMediaAutocomplete backing for a media lookup autocomplete returns metadata 
  and a media_id 
  @param term search term value for finding media records.
  @return json structure containing id, value, and meta suitable for use with an autocomplete.
--->
<cffunction name="getMediaAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct 
				media.media_id,
				auto_filename
			from 
				media
			where 
				MCZBASE.is_media_encumbered(media.media_id)  < 1 
				AND (
					upper(auto_filename) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				)
			order by auto_filename
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.media_id#">
			<cfset row["value"] = "#search.media_id#" >
			<cfset row["meta"] = "#search.media_id# #search.auto_filename#" >
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

<!--- function getMediaBlockHtml safely (with use of is_media_encumbered) display an html block
 serving as an arbitrary media display widget on any MCZbase page in a conistent manner.
 Appropriately handles media objects of all types, displaying appropriate metadata and thumbnail
 or larger image for the requested context.   Responsibility for delivering the desired image is
 split between this function, and where it is invoked by this function in an img tag, 
 /media/rescaleImage.cfm?media_id=.

 Threaded wrapper for getMediaBlockHtmlUnthreaded, use getMediaBlockHtml when invoked directly in
 an ajax call, use getMediaBlockHtmlUnthreaded when calling from another thread.  

 WARNING: Do not make copies of this function and use elsewhere, include this function and use it.

*** current API ***

 @param media_id the media_id of the media record to display a media widget for.
 @param size the size, an integer for pixel size of the image tag to include in the widget, image tags are
   always square (except for thumb), with the image fitted into this square preserving its aspect ratio within this 
   square, so size specifies both the height and width of the img tag in the returned html block,
   default is 600.
 @param displayAs the mode in which to display this media block, default is full, allowed values are
   full, fixedSmallThumb (which always returns a square image fitted to the specified size), and thumb
   (which returns a thumbnail with its original aspect ratio). 
 @param captionAs the caption which should be shown, allowed values are textFull, textNone (no caption
   shown, image is linked to media record instead of the media_uri resource), textLinks (caption is 
   limited to links without descriptive text, image is linked to the media_uri resource).
 @param background_class a value for the class of the image tag, <img class="{background}", intended
   for setting the background color for transparent images.
 @param background_color white or grey, the background color of the non-transparent image produced in 
   displayAs fixedSmallThumb, only applies to fixedSmallTnumb
 @parm styles a css value to use for style="" in the image tag, probably required if thumb is specified.


*** planned, not yet implemented, API ***

getMediaBlockHtml returns a block of html with an img tag appropriate to the requested media object 
enclosing anchor, divs, and optionally a caption for the image, these together comprise a media widget. 

<div>
...
<a href={media_uri or media/media_id, depending on value of caption}>
  <img src={*?? always rescaleImage.cfm?media_id=media_id&width={width}&... ??*} 
		height={depend on values of widthAs and width} 
		width={depends on values of widthAs and width} 
		class={imgStyleClass}
	>
</a>
...
Caption here
...
</div>

@param media_id  required, the media_id of the media record for which to display a media widget.

caption={full,links,none}
	if full a caption with metadata is provided for the image.
	if links, only links to metadata are provided for the image.
	if none, only the image is shown linked to the metadata record for the media object.

@param display = {media|preview}, default media

@param width width of the image to return in pixels, height depends on the value of aspectRatio.
	parameter passed on to rescaleImage.cfm?width

@param widthAs {auto,100pct,pixels}
	how the width parameter is used in the image tag (??? and surrounding html ???).
	if auto or 100pct, then img height=auto/100% width=auto/100pct
	if pixels, and aspectRatio=square then img height={width} width={width}
	if pixels and aspectRatio=original *** behavior not yet defined, may be invalid ***

@param aspectRatio {original|square} default square
	** to work out, if square, img src will be media/rescaleImage.cfm?aspectRatio.square
	** if orginal, might the media_uri or preview uri be used instead of rescaleImage.cfm
	** perhaps media block always uses rescaleImage.cfm, which should be then called
   ** deliverAsImage.cfm....
   // *** we need to think about this, perhaps always use  rescaleImage.cfm ??? ****

@param background = {grey|white} default grey
	parameter passed on to rescaleImage.cfm?background.  
   the background color to fill a square image outside the bounds of the aspect ratio of the
   original image (media_uri, preview_uri, or fallback icon).
   the background parameter is ignored if aspect ratio is original. 

imgStyleClass=value 
	where value is passed to img class="{value}"


---> 
<cffunction name="getMediaBlockHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="size" type="string" required="no" default="600">
	<cfargument name="displayAs" type="string" required="no" default="full">
	<cfargument name="captionAs" type="string" required="no" default="textFull">
	<cfargument name="background_class" type="string" required="no" default="bg-light">
	<cfargument name="background_color" type="string" required="no" default="grey">
	<cfargument name="styles" type="string" required="no" default="max-width:100%;max-height:100%">
	<!--- argument scope isn't available within the cfthread, so creating explicit local variables to bring optional arguments into scope within the thread --->
	<cfset l_media_id= #arguments.media_id#>
	<cfset l_displayAs = #arguments.displayAs#>
	<cfset l_size = #arguments.size#>
	<cfset l_styles = #arguments.styles#>
	<cfset l_captionAs = #arguments.captionAs#>
	<cfset l_background_class = #arguments.background_class#>
	<cfset l_background_color = #arguments.background_color#>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="mediaWidgetThread#tn#" threadName="mediaWidgetThread#tn#">
		<cfoutput>
			<cfset output = getMediaBlockHtmlUnthreaded(media_id="#l_media_id#",displayAs="#l_displayAs#",size="#l_size#",styles="#l_styles#",captionAs="#l_captionAs#",background_class="#l_background_class#",background_color="#l_background_color#")>
				
			#output#
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="mediaWidgetThread#tn#" />
	<cfreturn cfthread["mediaWidgetThread#tn#"].output>
</cffunction>

<!--- implementation for getMediaBlockHtml without creating a new thread 
 @see getMediaBlockHtml for API documentation.  
 WARNING: Do not make copies of this function and use elsewhere, include this function and use it.
  --->
<cffunction name="getMediaBlockHtmlUnthreaded" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="size" type="string" required="no" default="600">
	<cfargument name="displayAs" type="string" required="no" default="full">
	<cfargument name="captionAs" type="string" required="no" default="textFull">
	<cfargument name="background_class" type="string" required="no" default="bg-light">
	<cfargument name="background_color" type="string" required="no" default="grey">
	<cfargument name="styles" type="string" required="no" default="max-width:100%;max-height:100%">
	<cfif displayAs EQ "fixedSmallThumb">
		<cfif size lte 200>
			<cfset size = 75>
		</cfif>
	</cfif>
	<cfset output = "">
	<cfoutput>
		<cftry>
			<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
				SELECT media_id, 
					preview_uri, media_uri, 
					mime_type, media_type,
					auto_extension as extension,
					auto_host as host,
					auto_path as path,
					auto_filename as filename,
					MCZBASE.get_media_dctermsrights(media.media_id) as license_uri, 
					MCZBASE.get_media_dcrights(media.media_id) as license_display, 
					MCZBASE.get_media_credit(media.media_id) as credit,
					MCZBASE.get_media_owner(media.media_id) as owner,
					MCZBASE.get_media_creator(media.media_id) as creator,
					MCZBASE.GET_MEDIA_COPYRIGHT(media.media_id) as copyright_statement,
					MCZBASE.get_medialabel(media.media_id,'aspect') as aspect,
					MCZBASE.get_medialabel(media.media_id,'description') as description,
					MCZBASE.get_medialabel(media.media_id,'made date') as made_date,
					MCZBASE.get_medialabel(media.media_id,'subject') as subject,
					MCZBASE.get_medialabel(media.media_id,'height') as height,
					MCZBASE.get_medialabel(media.media_id,'width') as width,
					MCZBASE.get_media_descriptor(media.media_id) as alt,
					MCZBASE.get_media_title(media.media_id) as title
				FROM 
					media
					left join ctmedia_license on media.media_license_id=ctmedia_license.media_license_id
				WHERE 
					media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
					AND MCZBASE.is_media_encumbered(media.media_id)  < 1 
				ORDER BY LENGTH(MCZBASE.get_media_title(media.media_id)) DESC
			</cfquery>
			<cfif media.recordcount EQ 1>
				<cfloop query="media">
					<cfset iiifFull = "">
					<cfif host EQ "mczbase.mcz.harvard.edu">
						<cfset iiifSchemeServerPrefix = "http://iiif.mcz.harvard.edu/iiif/3/">
						<cfset iiifIdentifier = "#encodeForURL(replace(path,'/specimen_images/',''))##encodeForURL(filename)#">
						<cfset iiifFull = "#iiifSchemeServerPrefix##iiifIdentifier#/full/max/0/default.jpg">
						<cfset iiifSize = "#iiifSchemeServerPrefix##iiifIdentifier#/full/^#size#,/0/default.jpg">
						<cfset iiifThumb = "#iiifSchemeServerPrefix##iiifIdentifier#/full/^!100,95/0/default.jpg">
					</cfif>
					<cfset isDisplayable = false>
					<cfif media_type EQ 'image' AND (media.mime_type EQ 'image/jpeg' OR media.mime_type EQ 'image/png')>
						<cfset isDisplayable = true>
					</cfif>
					<cfif media_type EQ '3D model'>
						<cfset isDisplayable = false>
					</cfif>
					<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
					<cfset hw = 'height="auto" width="100%"'>
					<cfif isDisplayable>
						<!--- the resource specified by media_uri should be an image that can be displayed in a browser with img src=media_uri --->
						<cfif #displayAs# EQ "fixedSmallThumb">
							<cfset hw = 'height="#size#" width="#size#"'>
							<cfset sizeParameters='&width=#size#&height=#size#'>
							<cfset displayImage = "/media/rescaleImage.cfm?use_thumb=true&media_id=#media.media_id##sizeParameters#&background_color=#background_color#">
						<cfelseif #displayAs# EQ "thumb">
							<cfset displayImage = preview_uri>
							<cfset hw = 'width="auto" height="auto"'>
							<cfset styles = "max-width:100px;max-height:95px;">
							<cfif host EQ "mczbase.mcz.harvard.edu">
								<cfset displayImage = iiifThumb>
							</cfif>
						<cfelse>
							<cfif host EQ "mczbase.mcz.harvard.edu">
								<cfset sizeParameters='&width=#size#&height=#size#'>
								<!--- cfset displayImage = "/media/rescaleImage.cfm?media_id=#media.media_id##sizeParameters#" --->
								<cfset displayImage = iiifSize>
							<cfelse>
								<cfset displayImage = media_uri>
							</cfif>
						</cfif>
					<cfelse>
						<!--- the resource specified by media_uri is not one that can be used in an image tag as img src="media_uri", we need to provide an alternative --->
						<cfif len(preview_uri) GT 0>
						 	<!--- there is a preview_uri, use that --->
							<cfif #displayAs# EQ "fixedSmallThumb">
								<cfset hw = 'height="#size#" width="#size#"'>
								<cfset sizeParameters='&width=#size#&height=#size#'>
								<cfset displayImage = "/media/rescaleImage.cfm?use_thumb=true&media_id=#media.media_id##sizeParameters#&background_color=#background_color#">
							<cfelse>
								<!--- use a preview_uri, if one was specified --->
								<!--- TODO: change test to regex on http... with some sort of is this an image test --->
								<cfset displayImage = preview_uri>
								<cfif #displayAs# eq "thumb">
									<cfset hw = 'width="auto" height="auto"'>
									<cfset styles = "max-width:150px;max-height:100px;">
								<cfelse>
									<!---for shared drive images when the displayAs=thumb attribute is not used and a size is used instead. Since most of our intrinsic thumbnails in "preview_uri" field are around 150px or smaller, I will use that as the width. Height is "auto" for landscape and portrait.  --[changed from 100 to auto-3/14/22 MK ledgers were too tall--need to check other types--it was changed at some point] ---->
									<cfif #media_uri# CONTAINS "nrs" OR #media_URI# CONTAINS "morphosource">
										<cfset hw = 'width="95" height="auto"'>
									<cfelse>
										<cfset hw = 'width="80" height="100"'>
									</cfif>
								</cfif>
							</cfif>
						<cfelse>
							<cfif #displayAs# EQ "fixedSmallThumb">
								<!--- leave it to logic in media/rescaleImage.cfm to work out correct icon and rescale it to fit desired size --->
								<cfset hw = 'height="#size#px;" width="#size#px;"'>
								<cfset sizeParameters='&width=#size#&height=#size#'>
								<cfset displayImage = "/media/rescaleImage.cfm?use_thumb=true&media_id=#media.media_id##sizeParameters#&background_color=#background_color#">
							<cfelse>
								<!--- fall back on an svg image of an appropriate generic icon --->
								<cfset styles = "max-width:125px;max-height:auto;"><!---auto is need here because the text img is portrait size -- svg files so it shouldn't matter too much.--->
								<!--- pick placeholder --->
								<cfif media_type is "image">
									<cfset displayImage = "/shared/images/tag-placeholder.png">
								<cfelseif media_type is "audio">
									<cfset displayImage =  "/shared/images/Gnome-audio-volume-medium.svg">
								<cfelseif media_type IS "video">
									<cfset displayImage =  "/shared/images/Gnome-media-playback-start.svg">
								<cfelseif media_type is "text">
									<cfset displayImage =  "/shared/images/Gnome-text-x-generic.svg">
								<cfelseif media_type is "3D model">
									<cfset displayImage =  "/shared/images/model_3d.svg">
								<cfelseif media_type is "spectrometer data">
									<cfset displayImage = "/shared/images/Sine_waves_different_frequencies.svg">
								<cfelse>
									<cfset displayImage =  "/shared/images/tag-placeholder.svg">
									<!--- media_type is not on the known list --->
								</cfif>
							</cfif>
						</cfif>
					</cfif>
					<!--- prepare output --->
					<cfset output='#output#<div class="media_widget">'>	
					<!--- WARNING: if no caption text is shown, the image MUST link to the media metadata record, not the media object, otherwise rights information and other essential metadata are not shown to or reachable by the user. --->
					<cfif #captionAs# EQ "textNone">
						<cfset linkTarget = "/media/#media.media_id#">
					<cfelse>
						<cfset linkTarget = "#media.media_uri#">
					</cfif>
					<cfset output='#output#<a href="#linkTarget#" class="d-block w-100 active text-center" title="click to access media">'>
					<cfset output='#output#<img id="image" src="#displayImage#" alt="#alt#" #hw# style="#styles#" class="#background_class#">'>
					<cfset output='#output#</a>'>
					<cfif #captionAs# EQ "textNone">
						<!---textNone is used when we don't want any text (including links) below the thumbnail. This is used on Featured Collections of cataloged items on the specimenBrowse.cfm and grouping/index.cfm pages--->
					<cfelseif #captionAs# EQ "textLinks">
						<!--- textLinks is used when only the links are desired under the thumbnail--->
						<cfset output='#output#<div class="mt-0 col-12 pb-1 px-0">'>
						<cfset output='#output#<p class="text-center px-1 pb-1 mb-0 small col-12">'>
						<cfif listcontainsnocase(session.roles,"manage_specimens")>
							<cfset output='#output#<span class="d-inline">(<a href="/media.cfm?action=edit&media_id=#media_id#">edit</a>) </span>'>
						</cfif>
						<cfset output='#output#(<a class="" href="/media/#media_id#">Media Record</a>)'>
						<cfif NOT isDisplayable>
							<cfif listcontainsnocase(session.roles,"manage_publications")> <span class="sr-only">#media_type# (#mime_type#)</span></cfif>
								<cfset output='#output#(<a class="" href="#media_uri#">media file</a>)'>
							<cfelse>
								<cfset output='#output#(<a class="" href="/MediaSet.cfm?media_id=#media_id#">zoom/related</a>)'>
								<cfif len(iiifFull) GT 0>
									<cfset output='#output#(<a class="" href="#iiifFull#">full</a>)'>
								<cfelse>
									<cfset output='#output#(<a class="" href="#media_uri#">full</a>)'>
								</cfif>
							</cfif>
							<cfset output='#output#</p>'>
						<cfset output='#output#</div>'>
					<cfelse>
						<cfset output='#output#<div class="mt-0 col-12 pb-1 px-0">'>
						<cfset output='#output#<p class="text-center px-1 pb-1 mb-0 small col-12">'>
						<cfif listcontainsnocase(session.roles,"manage_specimens")>
							<cfset output='#output#<span class="d-inline">(<a href="/media.cfm?action=edit&media_id=#media_id#">edit</a>) </span>'>
						</cfif>
						<cfset output='#output#(<a class="" href="/media/#media_id#">Media Record</a>)'>
						<cfif NOT isDisplayable>
							<cfif listcontainsnocase(session.roles,"manage_publications")><span class="sr-only">#media_type# (#mime_type#)</span></cfif>
							<cfset output='#output#(<a class="" href="#media_uri#">media file</a>)'>
						<cfelse>
							<cfset output='#output#(<a class="" href="/MediaSet.cfm?media_id=#media_id#">zoom/related</a>)'>
							<cfif len(iiifFull) GT 0>
								<cfset output='#output#(<a class="" href="#iiifFull#">full</a>)'>
							<cfelse>
								<cfset output='#output#(<a class="" href="#media_uri#">full</a>)'>
							</cfif>
						</cfif>
						<cfset output='#output#</p>'>
						<cfset output='#output#<div class="pb-1">'>
						<cfset showTitleText = trim(title)>
						<cfif len(showTitleText) EQ 0>
							<cfset showTitleText = trim(subject)>
						</cfif>
						<cfif len(showTitleText) EQ 0>
							<cfset showTitleText = "Externally Sourced Media Object">
						</cfif>
						<cfif #captionAs# EQ "textCaption"><!---This is for use when a caption of 100 characters is needed --->
							<cfif len(showTitleText) GT 200>
								<cfset showTitleText = "#left(showTitleText,200)#..." >
							</cfif>
						</cfif>
						<cfif #captionAs# EQ "textShort"><!---This is for use with a small size or with "thumb" so that the caption will be short (e.g., specimen details page)--->
							<cfif len(showTitleText) GT 70>
								<cfset showTitleText = "#left(showTitleText,70)#..." >
							</cfif>
						</cfif>
						<cfif #captionAs# EQ "textFull"><!---This is for use with a size and the caption is 250 characters with links and copyright information--The images will fill the container (gray square present) and have a full caption (e.g., edit media page)--->
							<cfif len(showTitleText) GT 250>
								<cfset showTitleText = "#left(showTitleText,250)#..." >
							</cfif>
						</cfif>
						<!--- clean up broken html tags resulting from truncation of scientific names with <i></i> tags --->
						<cfif refind("<$",showTitleText) GT 0>
							<cfset showTitleText = left(showTitleText,len(showTitleText-1))>
						</cfif>
						<cfif refind("<i$",showTitleText) GT 0>
							<cfset showTitleText = left(showTitleText,len(showTitleText-2))>
						</cfif>
						<cfif refind("</$",showTitleText) GT 0>
							<cfset showTitleText = left(showTitleText,len(showTitleText-2))>
						</cfif>
						<cfif refind("</i$",showTitleText) GT 0>
							<cfset showTitleText = "#showTitleText#>">
						</cfif>
						<cfif refind("<i>[^<]+$",showTitleText) GT 0 >
							<!--- close an unclosed italic tag resulting from truncation --->
							<cfset showTitleText = "#showTitleText#</i>">
						</cfif>
						<cfset output='#output#<p class="text-center col-12 my-0 p-0 small" > #showTitleText# </p>'>
						<cfif len(#copyright_statement#) gt 0>
							<cfif #captionAs# EQ "TextFull">
								<cfset output='#output#<p class="text-center col-12 p-0 my-0 small">'>
								<cfset output='#output##copyright_statement#'>
								<cfset output='#output#</p>'>
							</cfif>
						</cfif>
						<cfif len(#license_uri#) gt 0>
							<cfif #captionAs# EQ "TextFull">
								<!---height is needed on the caption within the <p> or the media will not flow well--the above comment works but may not work on other, non specimen detail pages--->
								<cfset output='#output#<p class="text-center col-12 p-0 my-0 small">'>
								<cfset output='#output#<a href="#license_uri#">#license_display#</a>'>
								<cfset output='#output#</p>'>
							</cfif>
						</cfif>
						<cfset output='#output#</div>'>
						<cfset output='#output#</div>'>
					</cfif>
					<cfset output='#output#</div>'>
				</cfloop>
			</cfif>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
		#output#
	</cfoutput>
</cffunction>

<!---BELOW:::FUNCTIONS FOR RELATIONSHIPS and LABELS on EDIT MEDIA AND FUNCTION FOR SHOWING THUMBNAILS FOR showMedia.cfc showMore is not working-- Michelle--->				
<!--- Media Metadata Table using media_id --->		


<cffunction name="getMediaMetadata"  access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.media_id = arguments.media_id>
<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="mediaMetadataThread#tn#" threadName="mediaMetadataThread#tn#">
<cfoutput>
	<cftry>
		<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct 
				media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
				MCZBASE.get_media_dctermsrights(media.media_id) as uri, 
				MCZBASE.get_media_dcrights(media.media_id) as display, 
				MCZBASE.is_media_encumbered(media.media_id) hideMedia,
				MCZBASE.get_media_credit(media.media_id) as credit, 
				MCZBASE.get_media_descriptor(media.media_id) as alttag,
				MCZBASE.get_media_owner(media.media_id) as owner
			From
				media
			WHERE 
				media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#" list="yes">
				AND MCZBASE.is_media_encumbered(media_id)  < 1 
		</cfquery>
		<cfif media.recordcount EQ 0>
			<cfthrow message="No media records matching media_id [#encodeForHtml(media_id)#]">
		</cfif>
		<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct collection_object_id as pk, guid
			from media_relations
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on related_primary_key = collection_object_id
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
					and media_relations.media_relationship like '%cataloged_item%'
			order by guid
		</cfquery>
		<cfquery name="agents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct agent_name.agent_name, agent.agent_id
			from media_relations
				left join agent on media_relations.related_primary_key = agent.agent_id
				left join agent_name on agent_name.agent_id = agent.agent_id
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
					and media_relations.media_relationship = 'shows agent'
			and agent_name_type = 'preferred'
			order by agent_name.agent_name
		</cfquery>
		<cfquery name="collecting_eventRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct collecting_event.verbatim_locality,collecting_event.collecting_event_id
			from media_relations
			left join collecting_event on media_relations.related_primary_key = collecting_event.collecting_event_id
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
			and media_relations.media_relationship = 'shows collecting_event'
		</cfquery>
		<cfloop query="media">
			<cfquery name="labels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				media_label, label_value, agent_name, media_label_id
			FROM
				media_labels
				left join preferred_agent_name on media_labels.assigned_by_agent_id=preferred_agent_name.agent_id
			WHERE
				media_labels.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				and media_label <> 'credit'  -- obtained in the findIDs query.
				and media_label <> 'owner'  -- obtained in the findIDs query.
				<cfif oneOfUs EQ 0>
					and media_label <> 'internal remarks'
				</cfif>
			</cfquery>
			<cfquery name="keywords" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					media_keywords.media_id, keywords
				FROM
					media_keywords
				WHERE
					media_keywords.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
				<!---adding related_primary_key to this query mess up the ledger display since it is listed multiple times.--->
			<cfquery name="media_rel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct
					mr.media_relationship, label
				From
					media_relations mr, ctmedia_relationship ct
				WHERE 
					mr.media_relationship = ct.media_relationship 
				and
					mr.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#" list="yes">
				ORDER BY mr.media_relationship
			</cfquery>
		
				<h3 class="mx-2 h4 float-left">Metadata <span class="mb-0">(Media ID: <a href="/media/#media_id#">media/#media_id#</a>)</span></h3>
				<table class="table table-responsive-sm border-none small90">
					<thead class="thead-light">
						<tr>
							<th scope="col">Label</th>
							<th scope="col">Value</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<th scope="row">Media Type:</th><td>#media.media_type#</td>
						</tr>
						<tr>
							<th scope="row">MIME Type:</th><td>#media.mime_type#</td>
						</tr>
						<cfloop query="labels">
							<tr>
								<th scope="row"><span class="text-capitalize">#labels.media_label#</span>:</th><td>#labels.label_value#</td>
							</tr>
						</cfloop>
						<cfif len(credit) gt 0>
							<tr>
								<th scope="row">Credit:</th><td>#credit#</td>
							</tr>
						</cfif>
						<cfif len(owner) gt 0>
							<tr>
								<th scope="row">Copyright:</th><td>#owner#</td>
							</tr>
						</cfif>
						<cfif len(display) gt 0>
							<tr>
								<th scope="row">License:</th><td> <a href="#uri#" target="_blank" class="external"> #display#</a></td>
							</tr>
						</cfif>
						<cfif len(keywords.keywords) gt 0>
							<tr>
								<th scope="row">Keywords: </span></th><td> #keywords.keywords#</td>
							</tr>
						<cfelse>
						</cfif>
						<cfif listcontainsnocase(session.roles,"manage_media")>
							<tr class="border mt-2 p-2">
								<th scope="row">Alt Text: </th><td>#media.alttag#</td>
							</tr>
						</cfif>
						<cfif len(media_rel.media_relationship) gt 0>
							<cfif media_rel.recordcount GT 1>
								<cfset plural = "s">
							<cfelse>
								<cfset plural = "">
							</cfif>
						<tr>
							<th scope="row">Relationship#plural#:&nbsp; </span></th>
							<td>
								<cfloop query="media_rel"><span class="text-capitalize">#media_rel.label#</span>
									<div class="comma2 d-inline">
										<cfif media_rel.media_relationship contains 'shows cataloged_item'>:
											<cfloop query="spec"><cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">select distinct media.media_id, media.auto_protocol, media.auto_host
											from media_relations left join media on media_relations.media_id = media.media_id
											where related_primary_key = <cfqueryparam value=#spec.pk# CFSQLType="CF_SQL_DECIMAL" >
											</cfquery><a class="font-weight-lessbold" ref="#relm.auto_protocol#/#relm.auto_host#/guid/#spec.guid#">#spec.guid#</a><span>, </span></cfloop>
										</cfif>
										<cfif media_rel.media_relationship contains 'shows agent'>:<cfloop query="agents">
											<cfquery name="relm2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">select distinct media.media_id, media.auto_protocol, media.auto_host from media_relations left join media on media_relations.media_id = media.media_id where related_primary_key = <cfqueryparam value=#agents.agent_id# CFSQLType="CF_SQL_DECIMAL"></cfquery><a class="font-weight-lessbold" href="#relm2.auto_protocol#/#relm2.auto_host#/agents/Agent.cfm?agent_id=#agents.agent_id#">#agents.agent_name#</a><span>, </span></cfloop>
										</cfif>
										<cfif media_rel.media_relationship contains 'shows collecting_event'>:<cfloop query="collecting_events">
											<cfquery name="relm3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">select distinct media.media_id, media.auto_protocol, media.auto_host from media_relations left join media on media_relations.media_id = media.media_id where related_primary_key = <cfqueryparam value=#collecting_eventRel.collecting_event_id# CFSQLType="CF_SQL_DECIMAL"></cfquery><a class="font-weight-lessbold" href="#relm3.auto_protocol#/#relm3.auto_host#/showLocality.cfm?action=srch&collecting_event_id=#collecting_eventRel.collecting_event_id#">#collecting_eventRel.verbatim_locality#</a><span>, </span></cfloop>
										</cfif>
									</div>
								<cfif media_rel.recordcount GT 1><span class="px-1"> | </span></cfif>
								</cfloop> 
							</td>
						</tr>
						<cfelse>
						</cfif>
					</tbody>
				</table>
			
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
</cfoutput>
	</cfthread>
	<cfthread action="join" name="mediaMetadataThread#tn#" />
	<cfreturn cfthread["mediaMetadataThread#tn#"].output>
</cffunction>

<cffunction name="getMediaRelationsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.media_id = arguments.media_id>
	<!--- 
	NOTE: If this cffunction is invoked more than once in a request (e.g. when called directly as a function
		within a loop in coldfusion in a coldfusion page) then the thread name must be unique for each invocation,
		so generate a highly likely to be unique thread name as follows:	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getCounterThread#tn#" threadName="mediaWidgetThread#tn#">
	Likewise, include #tn# in the names of the thread in all the other cfthread tags within this cffunction 
	If the cffunction is called only once in a request (e.g. only from a javascript ajax handler, then the thread name
		does not need to be unique.
	--->
<cfthread name="getMediaRelationsHtmlThread">
	<cftry>
		<cfoutput>
			<cfquery name="getRelationships1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					media_relationship, media_id, media_relations_id, related_primary_key
				FROM
					media_relations
				WHERE media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				
			</cfquery>
			<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select media_relationship from ctmedia_relationship order by media_relationship
			</cfquery>
			<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select media_label from ctmedia_label order by media_label
			</cfquery>
			<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select media_type from ctmedia_type order by media_type
			</cfquery>
			<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select mime_type from ctmime_type order by mime_type
			</cfquery>
			<cfquery name="ctmedia_license" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select media_license_id,display media_license from ctmedia_license order by media_license_id
			</cfquery>
				
				<cfif getRelationships1.recordcount GT 0>
			<div class="col-12 px-0 float-left">

				<cfif getRelationships1.recordcount is 0>
				<script>
					console.log("relns cfif");
				</script> 
					<div id="seedMedia" style="display:none">
						<input type="hidden" id="media_relations_id__0" name="media_relations_id__0">
						<cfset d="">
						<select name="relationship__0" id="relationship__0" class="data-entry-select  col-5" size="1"  onchange="pickedRelationship(this.id)">
							<cfloop query="ctmedia_relationship">
								<option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
							</cfloop>
						</select>
						<input type="text" name="related_value__0" id="related_value__0" class="data-entry-input col-6">
						<input type="hidden" name="related_id__0" id="related_id__0">
						<script>
							console.log("seed media");
						</script> 
					</div>
				</cfif>
				<cfset i=1>
				<cfloop query="getRelationships1">
					<cfset d=media_relationship>
						<div class="form-row col-12 px-0 mx-0">	
							<input type="hidden" id="media_relations_id__#i#" name="media_relations_id__#i#" value="#media_relations_id#">
							<label for="relationship__#i#"  class="sr-only">Relationship</label>
							<select name="relationship__#i#" id="relationship__#i#" size="1"  onchange="pickedRelationship(this.id)" class="data-entry-select col-12 col-md-3 float-left">
								<cfloop query="ctmedia_relationship">
									<option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
								</cfloop>
							</select>
							<input type="text" name="related_value__#i#" id="related_value__#i#" value="#encodeForHTML(related_primary_key)#" class="data-entry-input col-12 col-md-6 col-xl-7  float-left px-1 float-left">
							<input type="hidden" name="related_id" id="related_id" value="#related_primary_key#">
							<button id="relationshipDiv__#i#" class="btn btn-warning btn-xs float-left small" onClick="deleteRelationship(#media_relations_id#,#getRelationships1.media_id#,relationshipDiv__#i#)"> Remove </button>
							<!---onclick="enable_disable()"--->
							<input class="btn btn-secondary btn-xs mx-0 small float-left slide-toggle__#i#" type="button" value="Edit" style="width:60px;"></input>
		
						<script>
							console.log("relns");
						</script> 
						</div>
					<cfset i=i+1>
				</cfloop>
			</div>
					<script>
						(function () {
							var previous;
							$("select").on('focus', function () {
								previous = this.value;
							}).change(function() {
								previous = this.value;
							});
						})();
					</script>
				<cfelse>
					<h3 class="h3">No Entries</h3>
					<ul><li>#encodeForHtml(variables.media_id)#</li></ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<!--- For functions that return html blocks to be embedded in a page, the error can be included in the output --->
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getMediaRelationsHtmlThread" />
	<cfreturn getMediaRelationsHtmlThread.output>
</cffunction>
	
<cffunction name="updateMediaRelationship" access="remote" returntype="any" returnformat="json">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="media_relationship" type="string" required="yes">
	<cfargument name="related_primary_key" type="string" required="yes">
	<cfargument name="media_relations_id" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update media_relations set
				media_relationship=<cfqueryparam cfsqltype="cf_sql_varchar" value="#media_relationship#" /> ,
				related_primary_key=<cfqueryparam cfsqltype="cf_sql_number" value="#related_primary_key#" /> ,
				media_relations_id=<cfqueryparam cfsqltype="cf_sql_number" value="#media_relations_id#" />
				where media_id=<cfqueryparam cfsqltype="cf_sql_number" value="#media_id#" />
			</cfquery>
			<cfloop from="1" to="#number_of_relations#" index="n">
				<cfset failure=0>
				<cftry>
				<cfset thisRelationship = #evaluate("relationship__" & n)#>
				<cfcatch>
					<cfset failure=1>
				</cfcatch>
				</cftry>
				<cftry>
					<cfset thisRelatedId = #evaluate("related_id__" & n)#>
					<cfcatch>
						<cfset failure=1>
					</cfcatch>
				</cftry>
				<cfif isdefined("media_relations_id__#n#")>
					<cfset thisRelationID=#evaluate("media_relations_id__" & n)#>
				<cfelse>
					<cfset thisRelationID=-1>
				</cfif>
				<cfif thisRelationID is -1>
					<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						insert into media_relations (
							media_id,media_relationship,related_primary_key
						) values (
							#media_id#,'#thisRelationship#',#thisRelatedId#)
					</cfquery>
				<cfelse>
						fail to make relationship
				</cfif><!--- relation exists ---> 
			</cfloop>
			<cftransaction action="commit"> 
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["media_relations_id"] = "#encodeForHTML(media_relations_id)#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback"> 
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfif error_message CONTAINS "ORA-00001: unique constraint">
				<cfset error_message = "Update Relationship">
			</cfif>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>	
			
<cffunction name="getLabelsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.media_id = arguments.media_id>
	<!--- 
	NOTE: If this cffunction is invoked more than once in a request (e.g. when called directly as a function
		within a loop in coldfusion in a coldfusion page) then the thread name must be unique for each invocation,
		so generate a highly likely to be unique thread name as follows:	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getCounterThread#tn#" threadName="mediaWidgetThread#tn#">
	Likewise, include #tn# in the names of the thread in all the other cfthread tags within this cffunction 
	If the cffunction is called only once in a request (e.g. only from a javascript ajax handler, then the thread name
		does not need to be unique.
	--->
	<cfthread name="getLabelsThread">
		<cftry>
			<cfoutput>
				<cfquery name="getLabels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select
						media_label,
						label_value,
						agent_name,
						media_label_id
					from
						media_labels,
						preferred_agent_name
					where
						media_labels.assigned_by_agent_id=preferred_agent_name.agent_id (+) and
						media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				</cfquery>
				<cfif getLabels.recordcount GT 0>
					<div id="labels">
						<cfset i=1>
						<cfif labels.recordcount is 0>
							<!--- seed --->
							<div id="seedLabel" style="display:none;">
								<input type="hidden" id="media_label_id__0" name="media_label_id__0">
								<cfset d="">
								<label for="label__#i#" class='sr-only'>Media Label</label>
								<select name="label__0" id="label__0" size="1" class="data-entry-select float-left col-5">
									<cfloop query="ctmedia_label">
										<option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
									</cfloop>
								</select>
								<input type="text" name="label_value__0" id="label_value__0" class="col-7 float-left data-entry-input">
							</div>
							<!--- end labels seed --->
						</cfif>
						<cfloop query="labels">
							<cfset d=media_label>
							<div class="form-row col-12 px-0 mx-0 mb-0" id="labelDiv__#i#" >		
								<input type="hidden" id="media_label_id__#i#" name="media_label_id__#i#" value="#media_label_id#">
								<label class="pt-0 pb-1 sr-only" for="label__#i#">Media Label</label>
<!---									<cfif getLabels.recordcount EQ 0>
										<tr>
											<td>None</td>
											<td></td>
										</tr>
									<cfelse>
										<cfloop query="getLabels">
											<tr>
												<td>
													#media_label# 
												</td>
												<td>
													<a class="btn btn-xs btn-warning" href="/Media.cfm?action=remmedialabel&media_label=#media_label#&label_value=#label_value#&media_id=#getlabels.media_label_id#">Delete</a>
												</td>
											</tr>
										</cfloop>
									</cfif>--->
								<form name="labelForm" method="post" action="/Media.cfm">
									<div class="newRec col-12 px-0">
										<div class="col-3 px-0 float-left">
											<input type="hidden" name="action" value="addLabel" />
											<input type="hidden" name="username" value="#getLabels.media_label_id#" />
											<select name="label__#i#" id="label__#i#" size="1" class="inputDisabled data-entry-select float-left">
												<cfloop query="ctmedia_label">
													<option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-5 px-0 float-left">
											<input type="text" name="label_value__#i#" id="label_value__#i#" value="#encodeForHTML(label_value)#"  class="data-entry-input inputDisabled float-left px-1">
										</div>
										<div class="col-12 col-md-4 float-left">
											<button class="btn btn-danger btn-xs float-left small" id="deleteLabel" onClick="deleteLabel(media_id)"> Delete </button>
											<input class="btn btn-secondary btn-xs mx-0 small float-left edit-toggle__#i#" type="button" value="Edit"></input>
											<input type="submit" value="Save" class="savBtn btn-xs btn-primary">
										</div>
									</div>
								</form>
							</div>
							<cfset i=i+1>
						</cfloop>
						<table>
							<tr>
								<td>
									<input class="btn btn-xs btn-primary float-left" type="button" value="Save New Label">
								</td>
							</tr>
						</table>
						
					<!---	<span class="infoLink h5 box-shadow-0 col-12 col-md-6 float-right d-block text-right my-1" id="addLabel" onclick="addLabelTo(#i#,'labels','addLabel');">Add Label (+)</span> --->
					</div><!---end id labels--->
				
					<script>
						(function () {
							var previous;
							$("select").on('focus', function () {
								previous = this.value;
							}).change(function() {
								alert(previous);
								previous = this.value;
							});
						})();
					</script>
				<cfelse>
					<h3 class="h3">No Entries</h3>
					<ul><li>#encodeForHtml(variables.media_id)#</li></ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<!--- For functions that return html blocks to be embedded in a page, the error can be included in the output --->
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getLabelsThread" />
	<cfreturn getLabelsThread.output>
</cffunction>

<!--- 
getCounterHtml returns a block of html displaying information from the cf_helloworld table.

@param parameter some arbitrary value, displayed in the returned html.
@param other_parameter some arbitrary value, displayed in the returned html.
@param id_for_counter the id to use for the html element that displays the current value 
  of the counter, must be unique on the page.
@param id_for_dialog the id to use for the html element into which the edit text dialog 
  can be loaded, must be unique on the page.

@return block of html text with data from cf_helloworld.
--->
<cffunction name="getCounterHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="parameter" type="string" required="yes">
	<cfargument name="other_parameter" type="string" required="yes">
	<cfargument name="id_for_counter" type="string" required="yes">
	<cfargument name="id_for_dialog" type="string" required="yes">

	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.parameter = arguments.parameter>
	<cfset variables.other_parameter = arguments.other_parameter>
	<cfset variables.id_for_counter = arguments.id_for_counter>
	<cfset variables.id_for_dialog = arguments.id_for_dialog>

	<!--- 

	NOTE: If this cffunction is invoked more than once in a request (e.g. when called directly as a function
		within a loop in coldfusion in a coldfusion page) then the thread name must be unique for each invocation,
		so generate a highly likely to be unique thread name as follows:	

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getCounterThread#tn#" threadName="mediaWidgetThread#tn#">

	Likewise, include #tn# in the names of the thread in all the other cfthread tags within this cffunction 

	If the cffunction is called only once in a request (e.g. only from a javascript ajax handler, then the thread name
		does not need to be unique.

	--->
	<cfthread name="getCounterThread">
		<cftry>
			<cfoutput>
				<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						text, counter, helloworld_id
					FROM
						MCZBASE.cf_helloworld
					WHERE rownum < 2
				</cfquery>
				<cfif getCounter.recordcount GT 0>
					<h3 class="h3">#getCounter.text#</h3>
					<!--- id_for_counter allows the calling code to specify, and thus know a value to pass to other functions, the id for the counter element in the dom --->
					<!--- see the use of this in the invocation of the javascript updateCounterElement() function --->
					<ul><li id="#encodeForHtml(variables.id_for_counter)#">#getCounter.counter#</li></ul>
					<ul><li><button onClick=" incrementCounterUpdate('#variables.id_for_counter#','#getCounter.helloworld_id#')" class="btn btn-xs btn-secondary" >Increment</button></li></ul>
					<ul><li>#encodeForHtml(variables.parameter)#</li></ul>
					<ul><li>#encodeForHtml(variables.other_parameter)#</li></ul>
					<!--- id_for_dialog allows the calling code to specify the div for the dialog, 
							and thus the potential reuse of this function in different contexts and the 
							elimination of a hardcoded value for the id of this div in more than one place.
					 --->
					 <ul><li><button onClick=" openUpdateTextDialog('#getCounter.helloworld_id#','#variables.id_for_dialog#');" class="btn btn-xs btn-primary">Edit</button></li></ul>
				<cfelse>
					<h3 class="h3">No Entries</h3>
					<ul><li>#encodeForHtml(variables.parameter)#</li></ul>
					<ul><li>#encodeForHtml(variables.other_parameter)#</li></ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<!--- For functions that return html blocks to be embedded in a page, the error can be included in the output --->
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getCounterThread" />
	<cfreturn getCounterThread.output>
</cffunction>

<!--- incrementCounter, increment the hello world counter (for all rows in cf_helloworld).
  @return json containing status(=saved), counter, and text.
  @throws returns error using reportError() and rollsback transaction
--->
<cffunction name="incrementAllCounters" access="remote" returntype="any" returnformat="json">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="setCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE 
					MCZBASE.cf_helloworld
				SET
					counter = counter + 1 
			</cfquery>
			<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					text, counter 
				FROM
					MCZBASE.cf_helloworld
				WHERE rownum < 2
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["counter"] = "#getCounter.counter#">
			<cfset row["text"] = "#getCounter.text#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<!--- For functions that return structured data, use reportError to produce an error dialog --->
			<!--- the calling jquery.ajax function should include: 
				error: function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"incrementing hello world counter (1)");
				}
			--->
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!--- incrementCounter, update the hello world counter for a specified cf_helloworld record.
  @param helloworld_id the primary key value of the row to update.
  @return json containing status(=saved), counter, and text.
  @throws returns error using reportError() and rollsback transaction
--->
<cffunction name="incrementCounter" access="remote" returntype="any" returnformat="json">
	<cfargument name="helloworld_id" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="setCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE 
					MCZBASE.cf_helloworld
				SET
					counter = counter + 1 
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					text, counter 
				FROM
					MCZBASE.cf_helloworld
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["counter"] = "#getCounter.counter#">
			<cfset row["text"] = "#getCounter.text#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- updateText, update the hello world text field for a specified cf_helloworld record,
  without updating the cunter.
  @param helloworld_id the primary key value of the row to update.
  @param text the new value for cf_helloworld.text
  @return json containing status(=saved), counter, and text.
  @throws returns error using reportError() and rollsback transaction
--->
<cffunction name="updateText" access="remote" returntype="any" returnformat="json">
	<cfargument name="helloworld_id" type="string" required="yes">
	<cfargument name="text" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="setText" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE 
					MCZBASE.cf_helloworld
				SET
					text = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#text#">
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					text, counter 
				FROM
					MCZBASE.cf_helloworld
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["counter"] = "#getCounter.counter#">
			<cfset row["text"] = "#getCounter.text#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- 
 ** method gettextDialogHtml obtains the html content for a dialog to update the value of cf_helloworld.text
 * 
 * @param helloworld_id the id of the row for which to update the text
 * @return html to populate a dialog
--->
<cffunction name="getTextDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="helloworld_id" type="string" required="yes">

	<cfthread name="textDialogThread">
		<cftry>
			<cfquery name="lookupRow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupRow_result">
				select helloworld_id, text, counter
				from MCZBASE.cf_helloworld
				where
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfif lookupRow.recordcount NEQ 1>
				<cfthrow message="Error looking up cf_helloworld row with helloworld_id=#encodeForHtml(helloworld_id)# Query:[#lookupRow_result.SQL#]">
			</cfif>
			<cfoutput query="lookupRow">
				<div class="container-fluid">
					<div class="row">
						<div class="col-12">
							<form id="text_form">
								<input type="hidden" name="helloworld_id" id="helloworld_id" value="#helloworld_id#">
								<label for="text_control" class="data-entry-label">Hello World Text</label>
								<input type="text" name="text" id="text_control" class="data-entry-input mb-2" value="#lookupRow.text#" >
								<script>
									function saveText() {
										var id = $('##helloworld_id').val();
										var text = $('##text_control').val();
										jQuery.getJSON("/media/component/search.cfc", { 
											method : "updateText",
											helloworld_id : id,
											text: text
										},
										function (result) {
											console.log(result);
											console.log(result[0].status);
											$("##helloworldtextdialogfeedback").html(result[0].status);
											var responseStatus = result[0].status;
											if (responseStatus == "saved") { 
												$('##helloworldtextdialogfeedback').removeClass('text-danger');
												$('##helloworldtextdialogfeedback').addClass('text-success');
												$('##helloworldtextdialogfeedback').removeClass('text-warning');
											};
											console.log(result[0].counter);
											console.log(result[0].text);
										}
										).fail(function(jqXHR,textStatus,error){ handleFail(jqXHR,textStatus,error,"incrementing hello world counter (1)"); });
									};
									function changed(){
										$('##helloworldtextdialogfeedback').html('Unsaved changes.');
										$('##helloworldtextdialogfeedback').addClass('text-danger');
										$('##helloworldtextdialogfeedback').removeClass('text-success');
										$('##helloworldtextdialogfeedback').removeClass('text-warning');
									};
									$(document).ready(function() {
										console.log("document.ready in returned dialog html");
										$('##text_form [type=text]').on("change",changed);
									});
								</script>
								<button type="button" class="btn btn-xs btn-primary" onClick="saveText();">Save</button>
								<output id="helloworldtextdialogfeedback"><output>
							</form>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="textDialogThread" />
	<cfreturn textDialogThread.output>
</cffunction>
				
				


<!--- function getRichMediaAutocomplete backing for a media lookup autocomplete returns metadata 
  and a media_id 
  @param term search term value for finding media records, checks filename.
  @param type limitation on media.media_type for returned values (type=image for just image files).
  @return json structure containing id, value, and meta suitable for use with an autocomplete.
--->
<cffunction name="getRichMediaAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="type" type="string" required="no">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct 
				media.media_id,
				auto_filename,
				media_type,
				mime_type
			from 
				media
			where 
				MCZBASE.is_media_encumbered(media.media_id)  < 1 
				and upper(auto_filename) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				and media_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#">
			order by auto_filename
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.media_id#">
			<cfset row["value"] = "#search.auto_filename#" >
			<cfset row["meta"] = "#search.media_id# #search.auto_filename# (#search.media_type#:#search.mime_type#)" >
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
