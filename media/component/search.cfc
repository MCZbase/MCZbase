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
					<cfif (isdefined("related_cataloged_item") AND len(related_cataloged_item) GT 0)
						OR (isdefined("underscore_collection_id") AND len(underscore_collection_id) GT 0)
					>
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
					-- TODO: look at UTL_MATCH.JARO_WINKLER matching
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
						AND media_relations_rt.media_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship_type#">
						<cfif media_relationship_value IS 'NOT NULL'>
							AND media_relations_rt.related_primary_key IS NOT NULL
						<cfelse>
							AND media_relations_rt.related_primary_key in ( <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_relationship_id#" list="yes"> )
						</cfif>
					</cfif>
					<cfif isdefined("media_relationship_type_1") AND len(media_relationship_type_1) GT 0 AND isdefined("media_relationship_id_1") AND len(media_relationship_id_1) GT 0 >
						AND media_relations_rt_1.media_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship_type_1#">
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

<cffunction name="getMediaBlockHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">

	<cfargument name="size" type="string" required="no" default="2000">
	<cfargument name="displayAs" type="string" required="no" default="full">

	<!--- argument scope isn't available within the cfthread, so creating explicit local variables to bring optional arguments into scope within the thread --->
	<cfset l_media_id= #arguments.media_id#>
	<cfset l_displayAs = #arguments.displayAs#>
	<cfset l_size = #arguments.size#>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	

	<cfthread name="mediaWidgetThread#tn#" threadName="mediaWidgetThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
					SELECT media_id, 
						preview_uri, media_uri, 
						mime_type, media_type,
						auto_extension as extension,
						auto_host as host,
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.uri ELSE MCZBASE.get_media_dctermsrights(media.media_id) END as license_uri, 
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license_display, 
						MCZBASE.get_media_dcrights(media.media_id) as dc_rights,
						MCZBASE.get_media_credit(media.media_id) as credit,
						MCZBASE.get_media_owner(media.media_id) as owner,
						MCZBASE.get_media_creator(media.media_id) as creator,
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
						media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#l_media_id#">
						AND MCZBASE.is_media_encumbered(media.media_id)  < 1 
				</cfquery>
				<cfif media.recordcount EQ 1>
					<cfloop query="media">
						<div  class="border rounded py-2 px-1">
							<cfset isDisplayable = false>
							<cfif media_type EQ 'image' AND (media.mime_type EQ 'image/jpeg' OR media.mime_type EQ 'image/png')>
								<cfset isDisplayable = true>
							</cfif>
							<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
							<!--- specify a reasonable fallback for media height/width --->
							<cfset hw = 'height="600" width="600"'>
							<cfset imgClasses = "w-100 default">
							
							<cfif isDisplayable>
								<cfif #l_displayAs# EQ "thumb">
									<cfset displayImage = preview_uri>
									<cfset l_size = "100">
						
									<cfset hw = 'height="90"'>
								<cfelse>
									<cfif host EQ "mczbase.mcz.harvard.edu">
										<cfset hw = 'height="#l_size#" width="#l_size#"'>
										<cfset sizeType='&width=#l_size#&height=#l_size#'>
										<cfset displayImage = "/media/rescaleImage.cfm?media_id=#media.media_id##sizeType#">
									<cfelse>
										<cfif len(media.height) GT 0 and len(media.width) GT 0>
											<!--- specify the actual media height/width --->
											<cfset hw = 'height="#media.height#" width="#media.width#"'>
										</cfif>
										<cfset displayImage = media_uri>
									</cfif>
								</cfif>
							<cfelse>
								<cfset hw = 'width="100" height="90"'>
								<cfset imgClasses = "py-2 w-100 notthumb">
								
								<cfif #l_displayAs# EQ "thumb" >
									<cfset hw = 'height="auto"'>
									<cfif host EQ "mczbase.mcz.harvard.edu">
										<cfset imgClasses = "py-0 w-100 thumbs">
									</cfif>
								</cfif>
								<cfif len(preview_uri) GT 0>
									<cfset displayImage = preview_uri>
								<cfelse>
									<!--- pick placeholder --->
									<cfif media_type is "image">
										<cfset displayImage = "/shared/images/Image-x-generic.svg">
									<cfelseif media_type is "audio">
										<cfset displayImage =  "/shared/images/Gnome-audio-volume-medium.svg">
									<cfelseif media_type IS "video">
										<cfset displayImage =  "/shared/images/Gnome-media-playback-start.svg">
									<cfelseif media_type is "text">
										<cfset displayImage =  "/shared/images/Gnome-text-x-generic.svg">
									<cfelseif media_type is "3D model">
										<cfset displayImage =  "/shared/images/Airy-3d.svg">
									<cfelse>
										<cfset displayImage =  "/shared/images/Image-x-generic.svg"><!---nothing was working for mime type--->
									</cfif>
								</cfif>
							</cfif>
							<div class="media_widget">
								<a href="#media.media_uri#" target="_blank" class="d-block my-0 active text-center mgImg" title="click to open full image">
									<img src="#displayImage#" id="myImage" alt="#alt#" class="#imgClasses#" #hw#>
								</a>
								<div class="mt-0 bg-light col-12 py-1 px-0">
									<p class="text-center p-1 mb-0 col-12 smaller">
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<span class="d-inline"><a target="_blank" href="/media.cfm?action=edit&media_id=#media_id#">(edit) </a></span>
									</cfif>
										<span class="d-inline">	(<a  target="_blank" href="/media/#media_id#">media record</a>) </span>
										<cfif NOT isDisplayable>
											<cfif #l_displayAs# NEQ "thumb">
												<span class="d-inline ">#media_type# (#mime_type#)</span>
											</cfif>
											<span class="d-inline">(<a class="" target="_blank" href="#media_uri#">media file</a>)</span>
										<cfelse>
											<span class="d-inline"> (<a class="" target="_blank" href="/MediaSet.cfm?media_id=#media_id#">zoom /related</a>) </span>
											<span class="d-inline"> (<a class="" target="_blank" href="#media_uri#">full</a>) </span>
										</cfif>
									</p>
									<div class="pb-1">
										<cfset showTitleText = trim(title)>
										<cfif len(showTitleText) EQ 0>
											<cfset showTitleText = trim(subject)>
										</cfif>
										<cfif len(showTitleText) EQ 0>
											<cfset showTitleText = "Unlinked Media Object">
										</cfif>
										<cfif #l_displayAs# EQ "thumb">
											<cfif len(showTitleText) GT 30>
												<cfset showTitleText = "#left(showTitleText,30)#..." >
											</cfif>
										</cfif>
										<p class="text-center col-12 my-0 p-0 smaller">#showTitleText#</p> 
										<cfif len(#license_uri#) gt 0>
											<p class="text-center col-12 p-0 my-0 smaller">
												<cfif #l_displayAs# NEQ "thumb">
													License: 
												</cfif>
												<a href="#license_uri#">#license_display#</a>
											</p>
										</cfif>
									</div>
								</div>
							</div>
						</div>
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
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="mediaWidgetThread#tn#" />
	<cfreturn cfthread["mediaWidgetThread#tn#"].output>
</cffunction>

					
<!--- @deprecated, move any desired code from this function into getMediaBlock and delete this function.  --->
<!---<cffunction name="getMediaResponsiveBlockHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="size" type="string" required="no" default="600">
	<cfargument name="displayAs" type="string" required="no" default="full">

	<cfthrow message="delete this block, move any desired styling ont getMediaBlockHtml, there should be only one media block, and it shouuld be responsive.">
	<cfset l_media_id= #arguments.media_id#>
	<cfset l_displayAs = #arguments.displayAs#>
	<cfset l_size = #arguments.size#>
	<cfset #arguments.size# = "100%">	
	<cfthread name="mediaResponsiveWidgetThread">
		<cfoutput>
			<cftry>
				<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
					SELECT media_id, 
						preview_uri, media_uri, 
						mime_type, media_type,
						auto_extension as extension,
						auto_host as host,
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.uri ELSE MCZBASE.get_media_dctermsrights(media.media_id) END as license_uri, 
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license_display, 
						MCZBASE.get_media_dcrights(media.media_id) as dc_rights,
						MCZBASE.get_media_credit(media.media_id) as credit,
						MCZBASE.get_media_owner(media.media_id) as owner,
						MCZBASE.get_media_creator(media.media_id) as creator,
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
						media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#l_media_id#">
						AND MCZBASE.is_media_encumbered(media.media_id)  < 1 
				</cfquery>
				<cfif media.recordcount EQ 1>
					<cfloop query="media">
						<div  class="border rounded p-3">
							<cfset isDisplayable = false>
							<cfif media_type EQ 'image' AND (media.mime_type EQ 'image/jpeg' OR media.mime_type EQ 'image/png')>
								<cfset isDisplayable = true>
							</cfif>
							<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
							<cfif isDisplayable>
								<cfif #l_displayAs# EQ "thumb">
									<cfset displayImage = preview_uri>
									<cfset l_size = "100">
								<cfelse>
									<cfif host EQ "mczbase.mcz.harvard.edu">
										<cfset sizeType='&width=#l_size#&height=#l_size#'>
										<cfset displayImage = "/media/rescaleImage.cfm?media_id=#media.media_id##sizeType#">
									
									<cfelse>
										<cfset displayImage = media_uri>
									</cfif>
								</cfif>
							<cfelse>
								<cfif media_type is "image">
									<cfset displayImage = "/shared/images/noThumbnailImage.png">
								<cfelseif media_type is "audio">
									<cfset displayImage =  "/shared/images/noThumbnailAudio.png">
								<cfelseif media_type IS "video">
									<cfset displayImage =  "/shared/images/noThumbnailVideo.png">
								<cfelseif media_type is "text">
									<cfset displayImage =  "/shared/images/noThumbDoc.png">
								<cfelseif media_type is "3D model">
									<cfset displayImage =  "/shared/images/3dmodel.png">
								<cfelse>
									<cfset displayImage =  "/shared/images/noThumbnailImage.png">
								</cfif>
							</cfif>
							<div class="media_widget">
								<a href="#media.media_uri#" target="_blank" class="d-block my-0 w-100 active" title="click to open full image">

									<img src="#displayImage#" class="mx-auto" alt="#alt#" width="100%" height="100%">
								</a>
								<div class="mt-0 bg-light col-12 py-1 px-0">
									<p class="text-center mb-0 p-1 col-12 smaller">
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<span class="d-inline"><a target="_blank" href="/media.cfm?action=edit&media_id=#media_id#">(edit) </a></span>
									</cfif>
									<span class="d-inline">	(<a  target="_blank" href="/media/#media_id#">media record</a>) </li>
									<cfif NOT isDisplayable>
										<span class="d-inline ">#media_type# (#mime_type#)</span>
										<span class="d-inline">(<a class="" target="_blank" href="#media_uri#">media file</a>)</span>
									
									<cfelse>
										
										<span class="d-inline"> (<a class="" target="_blank" href="/MediaSet.cfm?media_id=#media_id#">zoom /related</a>) </span>
										<span class="d-inline"> (<a class="" target="_blank" href="#media_uri#">full</a>) </span>
									</cfif>
									</p>
									<div class="pb-1">
										<cfset showTitleText = trim(title)>
										<cfif len(showTitleText) EQ 0>
											<cfset showTitleText = trim(subject)>
										</cfif>
										<cfif len(showTitleText) EQ 0>
											<cfset showTitleText = "Unlinked Media Object">
										</cfif>
										<p class="text-center col-12 my-0 pb-0 small">#showTitleText#</p> 
										<cfif len(#license_uri#) gt 0><p class="text-center col-12 mb-0 p-0 smaller">License: <a href="#license_uri#">#license_display#</a></p></cfif>
									</div>
								</div>
							</div>
						</div>
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
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="mediaResponsiveWidgetThread" />
	<cfreturn mediaResponsiveWidgetThread.output>
</cffunction>
					
<cffunction name="getMediaResponsiveBlockHtml2" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="size" type="string" required="no" default="600">
	<cfargument name="displayAs" type="string" required="no" default="full">
	<cfthrow message="delete this block, move any desired styling ont getMediaBlockHtml, there should be only one media block, and it shouuld be responsive.">
	<cfset l_media_id= #arguments.media_id#>
	<cfset l_displayAs = #arguments.displayAs#>
	<cfset l_size = #arguments.size#>
	<cfset #arguments.size# = "100%">	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
			<cfoutput>
	<cfthread name="mediaResponsiveWidgetThread2#tn#">
			<cftry>
				<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
					SELECT media_id, 
						preview_uri, media_uri, 
						mime_type, media_type,
						auto_extension as extension,
						auto_host as host,
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.uri ELSE MCZBASE.get_media_dctermsrights(media.media_id) END as license_uri, 
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license_display, 
						MCZBASE.get_media_dcrights(media.media_id) as dc_rights,
						MCZBASE.get_media_credit(media.media_id) as credit,
						MCZBASE.get_media_owner(media.media_id) as owner,
						MCZBASE.get_media_creator(media.media_id) as creator,
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
						media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#l_media_id#">
						AND MCZBASE.is_media_encumbered(media.media_id)  < 1 
				</cfquery>
				<cfif media.recordcount EQ 1>
					<cfloop query="media">
						<div  class="border rounded p-3">
							<cfset isDisplayable = false>
							<cfif media_type EQ 'image' AND (media.mime_type EQ 'image/jpeg' OR media.mime_type EQ 'image/png')>
								<cfset isDisplayable = true>
							</cfif>
							<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
							<cfif isDisplayable>
								<cfif #l_displayAs# EQ "thumb">
									<cfset displayImage = preview_uri>
									<cfset l_size = "100">
								<cfelse>
									<cfif host EQ "mczbase.mcz.harvard.edu">
										<cfset sizeType='&width=#l_size#&height=#l_size#'>
										<cfset displayImage = "/media/rescaleImage.cfm?media_id=#media.media_id##sizeType#">
									
									<cfelse>
										<cfset displayImage = media_uri>
									</cfif>
								</cfif>
							<cfelse>
								<cfif media_type is "image">
									<cfset displayImage = "/shared/images/noThumbnailImage.png">
								<cfelseif media_type is "audio">
									<cfset displayImage =  "/shared/images/noThumbnailAudio.png">
								<cfelseif media_type IS "audio">
									<cfset displayImage =  "/shared/images/noThumbnailVideo.png">
								<cfelseif media_type is "text">
									<cfset displayImage =  "/shared/images/noThumbDoc.png">
								<cfelseif media_type is "3D model">
									<cfset displayImage =  "/shared/images/3dmodel.png">
								<cfelse>
									<cfset displayImage =  "/shared/images/noThumbnailImage.png">
								</cfif>
							</cfif>
							<div class="media_widget">
								<a href="#media.media_uri#" target="_blank" class="d-block my-0 w-100 active" title="click to open full image">
									<img src="#displayImage#" class="mx-auto" alt="#alt#" width="100%" height="100%">
								</a>
								<div class="mt-0 bg-light col-12 py-1 px-0">
									<p class="text-center mb-0 p-1 col-12 smaller">
								
									<span class="d-inline">	(<a  target="_blank" href="/media/#media_id#">media record</a>) </li>
									<cfif NOT isDisplayable>
										<span class="d-inline ">#media_type# (#mime_type#)</span>
										<span class="d-inline">(<a class="" target="_blank" href="#media_uri#">media file</a>)</span>
									
									<cfelse>
										
										<span class="d-inline"> (<a class="" target="_blank" href="/MediaSet.cfm?media_id=#media_id#">zoom /related</a>) </span>
										<span class="d-inline"> (<a class="" target="_blank" href="#media_uri#">full</a>) </span>
									</cfif>
									</p>
									<div class="pb-1">
										<cfset showTitleText = trim(title)>
										<cfif len(showTitleText) EQ 0>
											<cfset showTitleText = trim(subject)>
										</cfif>
										<cfif len(showTitleText) EQ 0>
											<cfset showTitleText = "Unlinked Media Object">
										</cfif>
										<p class="text-center col-12 my-0 pb-0 small">#showTitleText#</p> 
										<cfif len(#license_uri#) gt 0><p class="text-center col-12 mb-0 p-0 smaller">License: <a href="#license_uri#">#license_display#</a></p></cfif>
									</div>
								</div>
							</div>
						</div>
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
		
	</cfthread>
	<cfthread action="join" name="mediaResponsiveWidgetThread2#tn#" />
	<cfreturn cfthread["mediaResponsiveWidgetThread2#tn#"].output>
		</cfoutput>
</cffunction>--->
</cfcomponent>
