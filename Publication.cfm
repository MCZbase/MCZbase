<cfset jquery11=true>
<cfinclude template="includes/_header.cfm">
    <div class="editPub" style="padding: 2em 0 5em 0;margin:0 auto;">
<script type='text/javascript' src='/includes/internalAjax.js'></script>
<cfif action is "nothing" and isdefined("publication_id") and isnumeric(publication_id)>
	<cfoutput><cflocation url="Publication.cfm?action=edit&publication_id=#publication_id#" addtoken="false"></cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------->
<cfif action is "edit">
<cfset title = "Edit Publication">
<cfoutput>
<h3 class="linkPubDetail">
    <a class="detailsLink" href="/publications/showPublication.cfm?publication_id=#publication_id#">See Publication Details</a></h3>

<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select publication_type from ctpublication_type order by publication_type
	</cfquery>
	<cfquery name="ctpublication_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select publication_attribute from ctpublication_attribute order by publication_attribute
	</cfquery>
	<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from publication p 
		where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="auth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from publication_author_name,agent_name 
		where
			publication_author_name.agent_name_id=agent_name.agent_name_id and
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		order by author_position
	</cfquery>
	<cfquery name="atts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from publication_attributes 
		where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media_type from ctmedia_type order by media_type
	</cfquery>
	<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select mime_type from ctmime_type order by mime_type
	</cfquery>

      <h2 class="wikilink">Edit Publication <img src="/images/info_i_2.gif" onClick="getMCZDocs('Edit Publication')" class="likeLink" alt="[ help ]">
		</h2>
	<form name="editPub" method="post" action="Publication.cfm">

        <div class="cellDiv">
            <p style="margin:0; padding:0;">The Basics <span style="font-size: 14px;">(Publication ID #pub.publication_id#)</span>:</p>

		<input type="hidden" name="publication_id" value="#pub.publication_id#">
		<input type="hidden" name="action" value="saveEdit">
		<table class="pubtitle">
			<tr>
				<td>
					<label for="publication_title">Publication Title</label>
				<textarea name="publication_title" id="publication_title" class="reqdClr" rows="3" cols="70">#pub.publication_title#</textarea>
				</td>
				<td>
					<span class="infoLink" onclick="italicize('publication_title')">italicize selected text</span>
					<br><span class="infoLink" onclick="bold('publication_title')">bold selected text</span>
					<br><span class="infoLink" onclick="superscript('publication_title')">superscript selected text</span>
					<br><span class="infoLink" onclick="subscript('publication_title')">subscript selected text</span>
				</td>
			</tr>
		</table>
		<label for="publication_type">Publication Type</label>
		<select name="publication_type" id="publication_type" class="reqdClr">
			<option value=""></option>
			<cfloop query="ctpublication_type">
				<option <cfif publication_type is pub.publication_type> selected="selected" </cfif>
					value="#publication_type#">#publication_type#</option>
			</cfloop>
		</select>
		<label for="is_peer_reviewed_fg">Peer Reviewed?</label>
		<select name="is_peer_reviewed_fg" id="is_peer_reviewed_fg" class="reqdClr">
			<option <cfif pub.is_peer_reviewed_fg is 1> selected="selected" </cfif>value="1">yes</option>
			<option <cfif pub.is_peer_reviewed_fg is 0> selected="selected" </cfif>value="0">no</option>
		</select>
		<label for="published_year">Published Year</label>
		<input type="text" name="published_year" id="published_year" value="#pub.published_year#">
<script>
   // TODO: Move back into ajax.js and rebuild ajax.min.js
   function findDOI(publication_title){
        // super-simple + specialized call to get a DOI from title @ edit publication
        var guts = "/picks/findDOI.cfm?publication_title=" + publication_title;
        $("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
                autoOpen: true,
                closeOnEscape: true,
                height: 'auto',
                modal: true,
                position: ['center', 'center'],
                title: 'Find DOI',
                        width:800,
                        height:600,
                close: function() {
                        $( this ).remove();
                }
        }).width(800-10).height(600-10);
        $(window).resize(function() {
                $(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
        });
        $(".ui-widget-overlay").click(function(){
            $(".ui-dialog-titlebar-close").trigger('click');
        });
}
</script>
    <label for="doi">Digital Object Identifier (DOI)</label>
    <input type="text" id="doi" name="doi" value="#pub.doi#" size="80">
               <cfif len(pub.doi) gt 0>
                        <a class="infoLink external" target="_blank" href="https://doi.org/#pub.doi#">[ open DOI ]</a>
         		<!---cfelse>
                  <a id="addadoiplease" class="red likeLink" onclick="findDOI('#URLEncodedFormat(pub.formatted_publication)#')">add DOI</a--->
                </cfif>
		<label for="publication_loc">Storage Location</label>
		<input type="text" name="publication_loc" id="publication_loc" size="100" value="#pub.publication_loc#">
		<label for="publication_remarks">Remark</label>
		<input type="text" name="publication_remarks" id="publication_remarks" size="100" value="#stripQuotes(pub.publication_remarks)#">
		</div>
		<div class="cellDiv">
		<span >Authors</span>: <span class="infoLink" onclick="addAgent()">Add Row</span>
			<table id="authTab">
				<tr>
					<th>Role</th>
					<th>Name</th>
					<th></th>
				</tr>
				<cfset i=0>
				<cfloop query="auth">
					<cfset i=i+1>
					<input type="hidden" name="publication_author_name_id#i#" id="publication_author_name_id#i#" value="#publication_author_name_id#">
					<input type="hidden" name="author_position#i#" id="author_position#i#" value="#author_position#">
					<input type="hidden" name="author_id_#i#" id="author_id_#i#" value="#agent_name_id#">
					<tr id="authortr#i#">
						<td>
							<select name="author_role_#i#" id="author_role_#i#">
								<option <cfif author_role is "author"> selected="selected" </cfif>value="author">author</option>
								<option <cfif author_role is "editor"> selected="selected" </cfif>value="editor">editor</option>
							</select>
						</td>
						<td>
							<input type="text" name="author_name_#i#" id="author_name_#i#" class="reqdClr" size="50"
								onchange="findAgentName('author_id_#i#',this.name,this.value)"
			 					onkeypress="return noenter(event);"
			 					value="#agent_name#">
						</td>
						<td>
							<span class="infoLink" onclick="deleteAgent(#i#)">Delete</span>
						</td>
					</tr>
				</cfloop>
				<input type="hidden" name="numberAuthors" id="numberAuthors" value="#i#">
			</table>
		</div>
		<div class="cellDiv">
		<span>Attributes</span>:
			Add: <select name="n_attr" id="n_attr" onchange="addAttribute(this.value)">
				<option value=""></option>
				<cfloop query="ctpublication_attribute">
					<option value="#publication_attribute#">#publication_attribute#</option>
				</cfloop>
			</select>
			<table id="attTab" style="padding-bottom: 1em;">
				<tr>
					<th>Attribute</th>
					<th>Value</th>
					<th></th>
				</tr>
				<cfset i=0>
				<cfloop query="atts">
					<cfset i=i+1>
					<input type="hidden" name="publication_attribute_id#i#"
								class="reqdClr" id="publication_attribute_id#i#" value="#publication_attribute_id#">

					<cfinvoke component="/component/functions" method="getPubAttributes" returnVariable="attvalist">
						<cfinvokeargument name="attribute" value="#publication_attribute#">
						<cfinvokeargument name="returnFormat" value="plain">
					</cfinvoke>
					<tr id="attRow#i#">
						<td>
							<input type="hidden" name="attribute_type#i#"
								class="reqdClr" id="attribute_type#i#" value="#publication_attribute#">
							#publication_attribute#
						</td>
						<td>
							<cfif isquery(attvalist)>
								<select name="attribute#i#" id="attribute#i#" class="reqdClr">
									<cfloop query="attvalist">
										<option <cfif v is atts.pub_att_value> selected="selected" </cfif>value="#v#">#v#</option>
									</cfloop>
								</select>
							<cfelseif not isobject(attvalist)>
								<input type="text" name="attribute#i#" id="attribute#i#" class="reqdClr" value="#pub_att_value#" size="50">
							<cfelse>
								error: 	<cfdump var="#attvalist#">
							</cfif>
						</td>
						<td>
							<span class="infoLink" onclick="deletePubAtt(#i#)">Delete</span>
						</td>
					</tr>
				</cfloop>
			</table>
		</div>

		<input type="hidden" name="origNumberAttributes" id="origNumberAttributes" value="#i#">
		<input type="hidden" name="numberAttributes" id="numberAttributes" value="#i#">
		<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		    select distinct
		        media.media_id,
		        media.media_uri,
		        media.mime_type,
		        media.media_type,
		        media.preview_uri
		     from
		         media,
		         media_relations,
		         media_labels
		     where
		         media.media_id=media_relations.media_id and
		         media.media_id=media_labels.media_id (+) and
		         media_relations.media_relationship like '%publication' and
		         media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		</cfquery>
		<cfif media.recordcount gt 0>
			Click Media Details to edit Media or remove the link to this Publication.
			<div class="thumbs">
				<div class="thumb_spcr">&nbsp;</div>
				<cfloop query="media">
					<cfset puri=getMediaPreview(preview_uri,media_type)>
	            	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							media_label,
							label_value
						from
							media_labels
						where
							media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
					</cfquery>
					<cfquery name="desc" dbtype="query">
						select label_value from labels where media_label='description'
					</cfquery>
					<cfset alt="Media Preview Image">
					<cfif desc.recordcount is 1>
						<cfset alt=desc.label_value>
					</cfif>
	               <div class="one_thumb">
		               <a href="#media_uri#" target="_blank"><img src="#getMediaPreview(preview_uri,media_type)#" alt="#alt#" class="theThumb"></a>
	                   	<p>
							#media_type# (#mime_type#)
		                   	<br><a href="/media/#media_id#" target="_blank">Media Details</a>
							<br>#alt#
						</p>
					</div>
				</cfloop>
				<div class="thumb_spcr">&nbsp;</div>
			</div>
		</cfif>
		<div class="cellDiv">
			Add Media:
			<div style="font-size:small">
				 Yellow cells are only required if you supply or create a URI. You may leave this section blank.
				 <br>Find Media and create a relationship to link existing Media to this Publication.
			</div>
			<label for="media_uri">Media URI</label>
			<input type="text" name="media_uri" id="media_uri" size="90" class="reqdClr"><!---<span class="infoLink" id="uploadMedia">Upload</span>--->
			<label for="preview_uri">Preview URI</label>
			<input type="text" name="preview_uri" id="preview_uri" size="90">
			<label for="mime_type">MIME Type</label>
			<select name="mime_type" id="mime_type" class="reqdClr">
				<option value=""></option>
				<cfloop query="ctmime_type">
					<option value="#mime_type#">#mime_type#</option>
				</cfloop>
			</select>
           	<label for="media_type">Media Type</label>
			<select name="media_type" id="media_type" class="reqdClr">
				<option value=""></option>
				<cfloop query="ctmedia_type">
					<option value="#media_type#">#media_type#</option>
				</cfloop>
			</select>
			<label for="media_desc">Media Description</label>
			<input type="text" name="media_desc" id="media_desc" size="80" class="reqdClr">
		</div>
			<input type="button" value="Save" class="savBtn" onclick="editPub.action.value='saveEdit';editPub.submit();">&nbsp;&nbsp;
			<input type="button" value="Delete Publication" class="delBtn" onclick="editPub.action.value='deletePub';confirmDelete('editPub');">
	   </form>

 </div>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------->
<cfif action is "deletePub">
	<cftransaction>
		<cfquery name="dformatted_publication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from formatted_publication 
			where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		</cfquery>
		<cfquery name="dpublication_author_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from publication_author_name 
			where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		</cfquery>
		<cfquery name="dpublication_attributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from publication_attributes 
			where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		</cfquery>
		<cfquery name="dpublication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from publication 
			where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		</cfquery>
	</cftransaction>
	it's gone.
</cfif>

<!---------------------------------------------------------------------------------------------------------->
<cfif action is "saveEdit">
<cfoutput>
	<cftransaction>
  <cfif len(doi) gt 0>
			<cfinvoke component="/component/functions" method="checkDOI" returnVariable="isok">
				<cfinvokeargument name="doi" value="#doi#">
			</cfinvoke>
			<cfif isok is not "true">
				<cfthrow message = "DOI #doi# failed validation with StatusCode #isok#">
			</cfif>
		</cfif>
		<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update publication set
				published_year=<cfif len(published_year) gt 0>#published_year#<cfelse>NULL</cfif>,
				publication_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_type#">,
				publication_loc=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_loc#">,
				publication_title=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_title#">,
				publication_remarks=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_remarks#">,
				is_peer_reviewed_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#is_peer_reviewed_fg#">,
				doi = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#doi#">
			where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		</cfquery>
		<cfif len(media_uri) gt 0>
			<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_media_id.nextval nv from dual
			</cfquery>
			<cfset media_id=mid.nv>
			<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media 
					(media_id,media_uri,mime_type,media_type,preview_uri)
	            values 
					(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_uri#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#">)
			</cfquery>
			<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media_relations (
					media_id,
					media_relationship,
					related_primary_key
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					'shows publication',
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				)
			</cfquery>
			<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media_labels (
					media_id,
					media_label,
					label_value)
				values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					'description',
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_desc#">)
			</cfquery>
		</cfif>
		<cfloop from="1" to="#numberAuthors#" index="n">
			<cfset thisAgentNameId = #evaluate("author_id_" & n)#>
			<cfif isdefined("author_role_#n#")>
				<cfset thisAuthorRole = #evaluate("author_role_" & n)#>
			<cfelse>
				<cfset thisAuthorRole = "">
			</cfif>
			<cfif isdefined("publication_author_name_id#n#")>
				<cfset thisRowId = #evaluate("publication_author_name_id" & n)#>
			<cfelse>
				<cfset thisRowId ="">
			</cfif>
			<cfif isdefined("author_position#n#")>
				<cfset thisAuthPosn = #evaluate("author_position" & n)#>
			<cfelse>
				<cfset thisAuthPosn=n>
			</cfif>
			<cfif thisAgentNameId is -1 and thisRowId gt 0>
				<!--- deleting --->
				<cfquery name="delAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from publication_author_name 
					where
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					and publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRowId#">
				</cfquery>
				<cfquery name="incAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update publication_author_name 
					set author_position=author_position-1 
					where
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						and author_position > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAuthPosn#">
				</cfquery>
			<cfelseif thisAgentNameId gt 0 and thisRowId gt 0>
				<!--- updating --->
				<cfquery name="upAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update
						publication_author_name
					set
						agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAgentNameId#">,
						author_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAuthorRole#">
					where
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						and publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRowId#">
				</cfquery>
			<cfelseif thisAgentNameId gt 0 and len(thisRowId) is 0>
				<!--- inserting --->
				<cfquery name="insAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into publication_author_name (
						publication_id,
						agent_name_id,
						author_position,
						author_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAgentNameId#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAuthPosn#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAuthorRole#">
					)
				</cfquery>
			</cfif>
		</cfloop>
		<cfloop from="1" to="#numberAttributes#" index="n">
			<cfif isdefined("attribute_type#n#")>
				<cfset thisAttribute = #evaluate("attribute_type" & n)#>
			<cfelse>
				<cfset thisAttribute = "">
			</cfif>
			<cfset thisAttVal = #evaluate("attribute" & n)#>
			<cfif isdefined("publication_attribute_id#n#")>
				<cfset thisAttId = #evaluate("publication_attribute_id" & n)#>
			<cfelse>
				<cfset thisAttId = "">
			</cfif>
			<cfif thisAttVal is "deleted">
				<cfquery name="delAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from publication_attributes 
					where publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAttId#">
				</cfquery>
			<cfelseif thisAttId gt 0>
				<cfquery name="upAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update
						publication_attributes
					set
						publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttribute#">,
						pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttVal#">
					where 
						publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAttId#">
				</cfquery>
			<cfelseif len(thisAttId) is 0 and len(thisAttVal) gt 0>
				<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into publication_attributes (
						publication_id,
						publication_attribute,
						pub_att_value
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttribute#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttVal#">
					)
				</cfquery>
			</cfif>
		</cfloop>
	</cftransaction>
	<!--- now get the formatted publications --->
	<cfinvoke component="/component/publication" method="shortCitation" returnVariable="shortCitation">
		<cfinvokeargument name="publication_id" value="#publication_id#">
		<cfinvokeargument name="returnFormat" value="plain">
	</cfinvoke>
	<cfinvoke component="/component/publication" method="longCitation" returnVariable="longCitation">
		<cfinvokeargument name="publication_id" value="#publication_id#">
		<cfinvokeargument name="returnFormat" value="plain">
	</cfinvoke>

	<cfquery name="sfp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update formatted_publication 
		set formatted_publication = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shortCitation#">
		where
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			and format_style = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="short">
	</cfquery>
	<cfquery name="lfp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update formatted_publication 
		set formatted_publication = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#longCitation#">
		where
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			and format_style = 'long'
	</cfquery>
	<cflocation url="Publication.cfm?action=edit&publication_id=#publication_id#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------->
<cfif action is "newPub">
	<cfset title = "Create New Publication">
	<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select publication_type from ctpublication_type order by publication_type
	</cfquery>
	<cfquery name="ctpublication_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select publication_attribute from ctpublication_attribute order by publication_attribute
	</cfquery>
	<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media_type from ctmedia_type order by media_type
	</cfquery>
	<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select mime_type from ctmime_type order by mime_type
	</cfquery>
	<style>
		.missing {
			border:2px solid red;
			}
	</style>
	<script>
		function confirmpub() {
			var r=true;
			var msg='';
			$('.missing').removeClass('missing');
			$('.reqdClr').each(function() {
                var thisel=$("#" + this.id)
                if ($(thisel).val().length==0){
                	msg += this.id + ' is required\n';
                	$(thisel).addClass('missing');
                }
        	});
        	if (msg.length>0){
        		alert(msg);
        		return false;
        	}
        	else {
        		/*if ($("#doi").val().length==0 ) {
					msg = 'Please enter a DOI if one is available for this article is available\n';
					msg+='Click OK to enter a DOI before creating this article, or Cancel to proceed.\n';
					msg+='There are also tools on the next page to help find DOI.';
					var r = confirm(msg);
					if (r == true) {
					    return false;
					} else {
					    return true;
					}
				}*/
				return true;
        	}

		function toggleMedia() {
			if($('#media').css('display')=='none') {
				$('#mediaToggle').html('[ Hide Media ]');
				$('#media').show();
				$('#media_uri').addClass('reqdClr');
				$('#mime_type').addClass('reqdClr');
				$('#media_type').addClass('reqdClr');
				$('#media_desc').addClass('reqdClr');
			} else {
				$('#mediaToggle').html('[ Add Media ]');
				$('#media').hide();
				$('#media_uri').val('').removeClass('reqdClr');
				$('#mime_type').val('').removeClass('reqdClr');
				$('#media_type').val('').removeClass('reqdClr');
				$('#media_desc').val('').removeClass('reqdClr');
			}
		}
		function getPubMeta(idtype){
			$("#doilookup").html('<image src="/images/indicator.gif">');
			$("#pmidlookup").html('<image src="/images/indicator.gif">');
			$('#doi').val($('#doi').val().trim());
			$('#pmid').val($('#pmid').val().trim());
			if (idtype=='DOI'){
				var identifier=$('#doi').val();
			} else {
				var identifier=$('#pmid').val();
			}
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "getPublication",
					identifier : identifier,
					idtype: idtype,
					returnformat : "json",
					queryformat : 'column'
				},
				function (d) {
					if(d.DATA.STATUS=='success'){
						$("#full_citation").val(d.DATA.LONGCITE);
						$("#short_citation").val(d.DATA.SHORTCITE);
						$("#publication_type").val(d.DATA.PUBLICATIONTYPE);
						$("#is_peer_reviewed_fg").val(1);
						$("#published_year").val(d.DATA.YEAR);
						$("#short_citation").val(d.DATA.SHORTCITE);
						for (i = 1; i<5; i++) {
							$("#authSugg" + i).html('');
							var thisAuthStr=eval("d.DATA.AUTHOR"+i);
							thisAuthStr=String(thisAuthStr);
							if (thisAuthStr.length>0){
								thisAuthAry=thisAuthStr.split("|");
								for (z = 0; z<thisAuthAry.length; z++) {
									var thisAuthRec=thisAuthAry[z].split('@');
									var thisAgentName=thisAuthRec[0];
									var thisAgentID=thisAuthRec[1];
									var thisSuggest='<span class="infoLink" onclick="useThisAuthor(';
									thisSuggest += "'" + i + "','" + thisAgentName + "','" + thisAgentID + "'" + ');"> [ ' + thisAgentName + " ] </span>";
									try {
										$("#authSugg" + i).append(thisSuggest);
									} catch(err){}
								}
							}
						}
						$("#doilookup").html(' [ crossref ] ');
						$("#pmidlookup").html(' [ pubmed ] ');
					} else {
						$("#doilookup").text(' [ crossref ] ');
						$("#pmidlookup").text(' [ pubmed ] ');
						alert(d.DATA.STATUS);
					}
				}
			);
		}
	</script>
	<cfoutput>


      <h2 class="wikilink">Create New Publication <img src="/images/info_i_2.gif" onClick="getMCZDocs('Publication-Data Entry')" class="likeLink" alt="[ help ]">
		</h2>

		<form name="newpub" method="post" onsubmit="if (!confirmpub()){return false;}" action="Publication.cfm">
			<div class="cellDiv">
			The Basics:
			<input type="hidden" name="action" value="createPub">
			<table class="pubtitle">
				<tr>
					<td>
						<label for="publication_title">Publication Title</label>
						<textarea name="publication_title" id="publication_title" class="reqdClr" rows="3" cols="70"></textarea>
					</td>
					<td style="padding-right: 2em;padding-top: 1em;">
						<span class="infoLink" onclick="italicize('publication_title')">italicize selected text</span>
						<br><span class="infoLink" onclick="bold('publication_title')">bold selected text</span>
						<br><span class="infoLink" onclick="superscript('publication_title')">superscript selected text</span>
						<br><span class="infoLink" onclick="subscript('publication_title')">subscript selected text</span>
					</td>
				</tr>
			</table>

			<div class="pubS"><label for="publication_type">Publication Type</label>
			<select name="publication_type" id="publication_type" class="reqdClr" onchange="setDefaultPub(this.value)"  style="border: 1px solid ##ccc;">
				<option value=""></option>
				<cfloop query="ctpublication_type">
					<option value="#publication_type#">#publication_type#</option>
				</cfloop>
			</select>
            </div>
            <p class="pubs_style"><b>Proceedings</b> are entered as if they are <b>Journals</b>. Choose "Journal Name" for publication type and the correct attributes will appear. You will find proceedings in the Journal Name dropdown alphabetically listed at "p". Similarly, a <b>Dissertation</b> or <b>Thesis</b> should be entered as if it were a <b>Book Section</b>.  Put "Ph.D. Dissertation" or "Thesis" in the <i>book</i> attribute and the location and school in the <i>publisher</i> attribute.  Select <b>serial monographs</b> when you wish to enter a work that is like a journal article, but includes a publisher in the citation.</p>

            <div style="clear:both;">
            <label for="is_peer_reviewed_fg">Peer Reviewed?</label>
			<select name="is_peer_reviewed_fg" id="is_peer_reviewed_fg" class="reqdClr" >
				<option value="1">yes</option>
				<option value="0">no</option>
			</select>
			<label for="published_year">Published Year</label>
			<input type="text" name="published_year" id="published_year" class="reqdClr">


			<label for="doi">Digital Object Identifier (<a target="_blank" href="https://dx.doi.org/" >DOI</a>)</label>
			<input type="text" name="doi" id="doi" size="50">
<!---  TODO: This lookup requires a crossref user account, needs a script containing the getPubMeta function and to have getPublication added to component/functions.cfc
			<span class="likeLink" id="doilookup" onclick="getPubMeta('DOI');"> [ crossref ] </span>
--->
			<label for="publication_loc">Storage Location</label>
			<input type="text" name="publication_loc" id="publication_loc" size="100">
			<label for="publication_remarks">Remark</label>
			<input type="text" name="publication_remarks" id="publication_remarks" size="100">
			<input type="hidden" name="numberAuthors" id="numberAuthors" value="1">
			</div></div>
			<div class="cellDiv">
			<div>Authors and Editors:</div> <div><span class="infoLink thirteen" onclick="addAgent()">Add Row</span> ~ <span class="infoLink thirteen" onclick="removeAgent()">Remove Last Row</span></div>
			<table id="authTab">
				<tr>
					<th>Role</th>
					<th>Name</th>
				</tr>
				<tr id="authortr1">
					<td style="width: 60px;">
						<select name="author_role_1" id="author_role_1" style="width: auto;">
							<option value="author">author</option>
							<option value="editor">editor</option>
						</select>
					</td>
					<td  style="background-color: white;">
						<input type="hidden" name="author_id_1" id="author_id_1">
						<input type="text" name="author_name_1" id="author_name_1" class="reqdClr" size="50"
							onchange="findAgentName('author_id_1',this.name,this.value)"
		 					onKeyPress="return noenter(event);">
					</td>
				</tr>
			</table>
			</div>
			<div class="cellDiv">
			<div>Attributes:</div>
			<div class="infoLink thirteen" onclick="removeLastAttribute()">Remove Last Row</div>
			<table id="attTab" style="border: 1px solid ##ccc;margin-top: .5em;padding-left: 5px;background-color: white;">
				<tr style="border:1px solid ##ccc;">
					<th>Attribute</th>
					<th>Value</th>
					<th></th>
				</tr>
                <tr>
             <!---  Add:--->
			<input type="hidden" name="numberAttributes" id="numberAttributes" value="0" size="30">
			 <td style="width: 200px;border: 1px double ##ccc;background-color: ##f8f8f8;;font-size: 12px; font-weight: 800;">
            &nbsp;&nbsp; Add Attribute:</td><td>
             <select name="n_attr" id="n_attr" onchange="addAttribute(this.value)" style="font-">
				<option value="">pick</option>
				<cfloop query="CTPUBLICATION_ATTRIBUTE">
					<option value="#publication_attribute#">#publication_attribute#</option>
				</cfloop>
			</select>
            </td>
                <tr>
			</table>
			</div>
			<span class="likeLink mediaToggle" id="mediaToggle" onclick="toggleMedia()">[ Add Media ]</span>

			<div class="cellDiv" id="media" style="display:none;">
				Media:
				<label for="media_uri">Media URI</label>
			<input type="text" name="media_uri" id="media_uri" size="90"><!---span class="infoLink" id="uploadMedia">Upload</span--->
				<label for="preview_uri">Preview URI</label>
				<input type="text" name="preview_uri" id="preview_uri" size="90">
				<label for="mime_type">MIME Type</label>
				<select name="mime_type" id="mime_type">
					<option value=""></option>
					<cfloop query="ctmime_type">
						<option value="#mime_type#">#mime_type#</option>
					</cfloop>
				</select>
            	<label for="media_type">Media Type</label>
				<select name="media_type" id="media_type">
					<option value=""></option>
					<cfloop query="ctmedia_type">
						<option value="#media_type#">#media_type#</option>
					</cfloop>
				</select>
				<label for="media_desc">Media Description</label>
				<input type="text" name="media_desc" id="media_desc" size="80">
			</div>
			<p class="pubSpace"><input type="submit" value="create publication" class="insBtn"></p>
		</form>

	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------->
<cfif action is "createPub">
<cfoutput>
	<cftransaction>
		<cfquery name="p" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select sq_publication_id.nextval p from dual
		</cfquery>
		<cfset pid=p.p>a
		<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into publication (
				publication_id,
				published_year,
				publication_type,
				publication_loc,
				publication_title,
				publication_remarks,
        doi,
				is_peer_reviewed_fg
			) values (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#pid#">,
				<cfif len(published_year) gt 0>
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#published_year#">,
				<cfelse>
					NULL,
				</cfif>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_type#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_loc#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_title#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_remarks#">,
        		<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#doi#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#is_peer_reviewed_fg#">
			)
		</cfquery>
		<cfloop from="1" to="#numberAuthors#" index="n">
			<cfset thisAgentNameId = #evaluate("author_id_" & n)#>
			<cfset thisAuthorRole = #evaluate("author_role_" & n)#>
			<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into publication_author_name (
					publication_id,
					agent_name_id,
					author_position,
					author_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#pid#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAgentNameId#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#n#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAuthorRole#">
				)
			</cfquery>
		</cfloop>
		<cfloop from="1" to="#numberAttributes#" index="n">
			<cfset thisAttribute = #evaluate("attribute_type" & n)#>
			<cfset thisAttVal = #evaluate("attribute" & n)#>
			<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into publication_attributes (
					publication_id,
					publication_attribute,
					pub_att_value
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#pid#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttribute#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttVal#">
				)
			</cfquery>
		</cfloop>
		<cfif len(media_uri) gt 0>
			<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_media_id.nextval nv from dual
			</cfquery>
			<cfset media_id=mid.nv>
			<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media 
					(media_id,media_uri,mime_type,media_type,preview_uri)
	            values 
					(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_uri#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#">)
			</cfquery>
			<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media_relations (
					media_id,
					media_relationship,
					related_primary_key
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="shows publication">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#pid#">
				)
			</cfquery>
			<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media_labels (
					media_id,
					media_label,
					label_value)
				values 
					(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="description">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_desc#">)
			</cfquery>
		</cfif>
	</cftransaction>
	<cfinvoke component="/component/publication" method="shortCitation" returnVariable="shortCitation">
		<cfinvokeargument name="publication_id" value="#pid#">
		<cfinvokeargument name="returnFormat" value="plain">
	</cfinvoke>
	<cfinvoke component="/component/publication" method="longCitation" returnVariable="longCitation">
		<cfinvokeargument name="publication_id" value="#pid#">
		<cfinvokeargument name="returnFormat" value="plain">
	</cfinvoke>
	<cfquery name="sfp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		insert into formatted_publication (
			publication_id,
			format_style,
			formatted_publication
		) values (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#pid#">,
			'short',
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shortCitation#">
		)
	</cfquery>
	<cfquery name="lfp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		insert into formatted_publication (
			publication_id,
			format_style,
			formatted_publication
		) values (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#pid#">,
			'long',
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#longCitation#">
		)
	</cfquery>
	<cflocation url="Publication.cfm?action=edit&publication_id=#pid#" addtoken="false">
</cfoutput>
</cfif>
</div>


<cfinclude template="includes/_footer.cfm">
