<!---
shared/component/functions.cfc

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

<!---
	linkMediaHtml create dialog content to link media to an object 
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
		<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select media_type from ctmedia_type order by media_type
		</cfquery>
		<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<div class='container-fluid'>
				<div class='form-row'>
					<div class='col-md-12>
						<label for='media_uri'>Media URI</label>
			 			<input type='text' name='media_uri' id='media_uri' size='90' value=''>
					</div>
				</div>
				<div class='form-row'>
					<div class='col-6'>
						<label for='mimetype'>MIME Type</label>
						<select name='mimetype' id='mimetype'>
							<option value=''></option>
		">
							<cfloop query='ctmime_type'>
								<cfset result = result & "<option value='#ctmime_type.mime_type#'>#ctmime_type.mime_type#</option>">
							</cfloop>
		<cfset result = result & "
						</select>
			 		</div>
					<div class='col-6'>
			 			<label for='mediatype'>Media Type</label>
						<select name='mediatype' id='mediatype'>
							<option value=''></option>
		 ">
							<cfloop query='ctmedia_type'>
								<cfset result = result & "<option value='#ctmedia_type.media_type#'>#ctmedia_type.media_type#</option>">
							</cfloop>
		 <cfset result = result & "
						</select>
			 		</div>
				</div>
				<div class='form-row'>
					<div class='col-4'>
						<span>
							<input type='checkbox' name='unlinked' id='unlinked' value='true'>
							<label style='display:contents;' for='unlinked'>Media not yet linked to any record</label>
						</span>
					</div>
					<div class='col-4'>
						<input type='submit' value='Search' class='btn-primary'>
					</div>
					<div class='col-4'>
						<span ><input type='reset' value='Clear' class='btn-warning px-3'>
							<input type='button' onClick=""opencreatemediadialog('newMediaDlg1_#target_id#','#target_label#','#target_id#','#relationship#',reloadTransMedia);"" 
								value='Create Media' class='btn-primary px-3' >&nbsp;
						</span>
					</div>
				</div>
			</table>
		</form>
		</div>
		<script language='javascript' type='text/javascript'>
			function searchformedia(event) { 
				event.preventDefault();
				jQuery.ajax({
					url: '/shared/component/functions.cfc',
					type: 'post',
					data: $('##findMediaForm').serialize(),
					success: function (data) {
						$('##mediaSearchResults').html(data);
					},
					error : function (jqXHR, status, error) {
						var message = '';
						if (error == 'timeout') {
							message = ' Server took too long to respond.';
						} else {
							message = jqXHR.responseText;
						}
						$('##mediaSearchResults').html('Error (' + error + '): ' + message);
					}
				});
				return false; 
			};
		</script>
		<div id='newMediaDlg1_#target_id#'></div>
		<div id='mediaSearchResults'></div>
		" >
	<cfcatch> 
		<cfset result = "Error: " & cfcatch.type & " " & cfcatch.message & " " & cfcatch.detail >
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
	 <cfquery name="matchMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<input type='button' class='btn-secondary'
				onclick='linkmedia(#media_id#,#target_id#,""#target_relation#"",""pickResponse#target_id#_#i#"");' value='Add this media'>
		</div>
		<hr>
		</form>
		<script language='javascript' type='text/javascript'>
		$('##pickForm#target_id#_#i#').removeClass('ui-widget-content');
		function linkmedia(media_id, target_id, target_relation, div_id) { 
			jQuery.ajax({
				url: '/shared/component/functions.cfc',
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
		<cfset result = "Error: " & cfcatch.type & " " & cfcatch.message & " " & cfcatch.detail >
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!------------------------------------->
<!--- 
	linkMediaRecord create a media_relations record.
	Given a relationship, primary key to link to, and media_id, create a media relation by
	performing an insert into media_relations.
	@return text indicating action performed or an error message.
--->
<cffunction name="linkMediaRecord" access="remote">
	<cfargument name="target_relation" type="string" required="yes">
	<cfargument name="target_id" type="string" required="yes">
	<cfargument name="media_id" type="string" required="yes">
	<cfset result = "">
	<cftry>
		<cfquery name="addMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addMediaResult">
			INSERT INTO media_relations 
				(media_id, related_primary_key, media_relationship,created_by_agent_id) 
			VALUES (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#target_relation#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">
			)
		</cfquery>
		<cfset result = "Added media #media_id# in relationship #target_relation# to #target_id#.">
	<cfcatch>
		<cfset result = "Error: " & cfcatch.type & " " & cfcatch.message & " " & cfcatch.detail >
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>


</cfcomponent>
