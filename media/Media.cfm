<!--
Media.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2020 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfif NOT isdefined("action")>
	<cfset action = "edit">
</cfif>
<cfset pageTitle = "Manage Media">
<cfswitch expression="#action#">
	<cfcase value="new">
		<cfset pageTitle = "New Media Record">
	</cfcase>
	<cfcase value="edit">
		<cfset pageTitle = "Edit Media Record">
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_header.cfm">

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

<!------------------------------------------------>
<cfif action is "nothing">
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select MEDIA_ID, MEDIA_URI, MIME_TYPE, MEDIA_TYPE, PREVIEW_URI, MEDIA_LICENSE_ID, MASK_MEDIA_FG,
				mczbase.get_media_descriptor(media_id) as alttag 
			from media 
			where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		</cfquery>
		<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="tag"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select count(*) c from tag where media_id=#media_id#
		</cfquery>
		<cfset relns=getMediaRelations(#media_id#)>
		<cfoutput>
			<div class="container-fluid">
				<div class="row mb-4 mx-0">
					<div class="col-12 px-0">

						<h2 class="wikilink">Edit Media      <img src="/images/info_i.gif" onClick="getMCZDocs('Edit/Delete_Media')" class="likeLink" alt="[ help ]"></h2>
	  
						<a href="/TAG.cfm?media_id=#media_id#">edit #tag.c# TAGs</a> ~ <a href="/showTAG.cfm?media_id=#media_id#">View #tag.c# TAGs</a> ~ <a href="/MediaSearch.cfm?action=search&media_id=#media_id#">Detail Page</a>

    <form name="editMedia" method="post" action="media.cfm">
      <input type="hidden" name="action" value="saveEdit">
      <input type="hidden" id="number_of_relations" name="number_of_relations" value="#relns.recordcount#">
      <input type="hidden" id="number_of_labels" name="number_of_labels" value="#labels.recordcount#">
      <input type="hidden" id="media_id" name="media_id" value="#media_id#">
      <label for="media_uri">Media URI (<a href="#media.media_uri#" target="_blank">open</a>)</label>
      <input type="text" name="media_uri" id="media_uri" size="90" value="#media.media_uri#">
      <cfif #media.media_uri# contains #application.serverRootUrl#>
        <span class="infoLink" onclick="generateMD5()">Generate Checksum</span>
      </cfif>
      <label for="preview_uri">Preview URI
        <cfif len(media.preview_uri) gt 0>
          (<a href="#media.preview_uri#" target="_blank">open</a>)
        </cfif>
      </label>
      <input type="text" name="preview_uri" id="preview_uri" size="90" value="#media.preview_uri#">
      <!--- <span class="infoLink" onclick="clickUploadPreview()">Load...</span> --->
      <label for="mime_type">MIME Type</label>
      <select name="mime_type" id="mime_type">
        <cfloop query="ctmime_type">
          <option <cfif #media.mime_type# is #ctmime_type.mime_type#> selected="selected"</cfif> value="#mime_type#">#mime_type#</option>
        </cfloop>
      </select>
      <label for="media_type">Media Type</label>
      <select name="media_type" id="media_type">
        <cfloop query="ctmedia_type">
          <option <cfif #media.media_type# is #ctmedia_type.media_type#> selected="selected"</cfif> value="#media_type#">#media_type#</option>
        </cfloop>
      </select>
      <label for="media_license_id">License</label>
      <select name="media_license_id" id="media_license_id">
        <option value="">NONE</option>
        <cfloop query="ctmedia_license">
          <option <cfif media.media_license_id is ctmedia_license.media_license_id> selected="selected"</cfif> value="#ctmedia_license.media_license_id#">#ctmedia_license.media_license#</option>
        </cfloop>
      </select>
      <span class="infoLink" onclick="popupDefine();">Define</span>
      <label for="mask_media_fg">Media Record Visibility</label>
      <select name="mask_media_fg" value="mask_media_fg">
          <cfif #media.mask_media_fg# eq 1 >
              <option value="0">Public</option>
              <option value="1" selected="selected">Hidden</option>
          <cfelse>
              <option value="0" selected="selected">Public</option>
              <option value="1">Hidden</option>
          </cfif>
      </select>
		<div style="background-color: AliceBlue;"><strong>Alternative text for vision impared users:</strong> #media.alttag#</div>
      <label for="relationships">Media Relationships | <span class="likeLink" onclick="manyCatItemToMedia('#media_id#')">Add multiple "shows cataloged_item" records</span></label>
      <div id="relationships" class="graydot">
        <cfset i=1>
        <cfif relns.recordcount is 0>
          <!--- seed --->
          <div id="seedMedia" style="display:none">
            <input type="hidden" id="media_relations_id__0" name="media_relations_id__0">
            <cfset d="">
            <select name="relationship__0" id="relationship__0" size="1"  onchange="pickedRelationship(this.id)">
              <option value="delete">delete</option>
              <cfloop query="ctmedia_relationship">
                <option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
              </cfloop>
            </select>
            :&nbsp;
            <input type="text" name="related_value__0" id="related_value__0" size="80">
            <input type="hidden" name="related_id__0" id="related_id__0">
          </div>
        </cfif>
        <cfloop query="relns">
          <cfset d=media_relationship>
          <input type="hidden" id="media_relations_id__#i#" name="media_relations_id__#i#" value="#media_relations_id#">
          <select name="relationship__#i#" id="relationship__#i#" size="1"  onchange="pickedRelationship(this.id)">
            <option value="delete">delete</option>
            <cfloop query="ctmedia_relationship">
              <option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
            </cfloop>
          </select>
          :&nbsp;
          <input type="text" name="related_value__#i#" id="related_value__#i#" size="90" value="#summary#">
          <input type="hidden" name="related_id__#i#" id="related_id__#i#" value="#related_primary_key#">
          <cfset i=i+1>
          <br>
        </cfloop>
        <br>
        <span class="infoLink" id="addRelationship" onclick="addRelation(#i#)">Add Relationship</span> </div>
      <br>
      <label for="labels">Media Labels</label> <p>Note: For media of permits, correspondence, and other transaction related documents, please enter a 'description' media label.</p>
      <div id="labels" class="graydot">
        <cfset i=1>
        <cfif labels.recordcount is 0>
          <!--- seed --->
          <div id="seedLabel" style="display:none;">
            <div id="labelsDiv__0">
              <input type="hidden" id="media_label_id__0" name="media_label_id__0" size="90">
              <cfset d="">
              <select name="label__0" id="label__0" size="1">
                <option value="delete">delete</option>
                <cfloop query="ctmedia_label">
                  <option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
                </cfloop>
              </select>
              :&nbsp;
              <input type="text" name="label_value__0" id="label_value__0" size="90">
            </div>
          </div>
        </cfif>
        <cfloop query="labels">
          <cfset d=media_label>
          <div id="labelsDiv__#i#">
            <input type="hidden" id="media_label_id__#i#" name="media_label_id__#i#" value="#media_label_id#">
            <select name="label__#i#" id="label__#i#" size="1">
              <option value="delete">delete</option>
              <cfloop query="ctmedia_label">
                <option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
              </cfloop>
            </select>
            :&nbsp;
            <input type="text" name="label_value__#i#" id="label_value__#i#" size="80" value="#stripQuotes(label_value)#">
          </div>
          <cfset i=i+1>
        </cfloop>
        <span class="infoLink" id="addLabel" onclick="addLabel(#i#)">Add Label</span> </div>
      <br>
      <input type="submit" 
				value="Save Edits" 
				class="insBtn"
				onmouseover="this.className='insBtn btnhov'" 
				onmouseout="this.className='insBtn'">

						</form>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------------------------->
	<cfcase value="new">
		<cfoutput>
			<div class="container-fluid">
				<div class="row mb-4 mx-0">
					<div class="col-12 px-0">
				
          <h2 class="wikilink">Create Media <img src="/images/info_i.gif" onClick="getMCZDocs('Media')" class="likeLink" alt="[ help ]"></h2>
          <div style="border: 1px dotted gray; background-color: ##f8f8f8;padding: 1em;margin: .5em 0 1em 0;">
    <form name="newMedia" method="post" action="media.cfm">
      <input type="hidden" name="action" value="saveNew">
      <input type="hidden" id="number_of_relations" name="number_of_relations" value="1">
      <input type="hidden" id="number_of_labels" name="number_of_labels" value="1">
      <label for="media_uri">Media URI</label>
      <input type="text" name="media_uri" id="media_uri" size="105" class="reqdClr">
      <!--- <span class="infoLink" id="uploadMedia">Upload</span> --->
      <label for="preview_uri">Preview URI</label>
      <input type="text" name="preview_uri" id="preview_uri" size="105">
      <label for="mime_type">MIME Type</label>
      <select name="mime_type" id="mime_type" class="reqdClr" style="width: 160px;">
        <option value=""></option>
        <cfloop query="ctmime_type">
          <option value="#mime_type#">#mime_type#</option>
        </cfloop>
      </select>
      <label for="media_type">Media Type</label>
      <select name="media_type" id="media_type" class="reqdClr" style="width: 160px;">
        <option value=""></option>
        <cfloop query="ctmedia_type">
          <option value="#media_type#">#media_type#</option>
        </cfloop>
      </select>
      <div class="license_box" style="padding-bottom: 1em;padding-left: 1.15em;">
        <label for="media_license_id">License</label>
        <select name="media_license_id" id="media_license_id" style="width:300px;">
          <option value="">Research copyright &amp; then choose...</option>
          <cfloop query="ctmedia_license">
            <option value="#media_license_id#">#media_license#</option>
          </cfloop>
        </select>
        <a class="infoLink" onClick="popupDefine()">Define Licenses</a><br/>
        <ul class="lisc">
            <p>Notes:</p>
          <li>media should not be uploaded until copyright is assessed and, if relevant, permission is granted (<a href="https://code.mcz.harvard.edu/wiki/index.php/Non-MCZ_Digital_Media_Licenses/Assignment" target="_blank">more info</a>)</li>
          <li>remove media immediately if owner requests it</li>
          <li>contact <a href="mailto:mcz_collections_operations@oeb.harvard.edu?subject=media licensing">MCZ Collections Operations</a> if additional licensing situations arise</li>
        </ul>
      </div>
      <label for="mask_media_fg">Media Record Visibility</label>
      <select name="mask_media_fg" value="mask_media_fg">
           <option value="0" selected="selected">Public</option>
           <option value="1">Hidden</option>
      </select>
   
      <label for="relationships" style="margin-top:.5em;">Media Relationships</label>
      <div id="relationships" class="graydot">
        <div id="relationshiperror"></div>
        <select name="relationship__1" id="relationship__1" size="1" onchange="pickedRelationship(this.id)" style="width: 200px;">
          <option value="">None/Unpick</option>
          <cfloop query="ctmedia_relationship">
            <option value="#media_relationship#">#media_relationship#</option>
          </cfloop>
        </select>
        :&nbsp;
        <input type="text" name="related_value__1" id="related_value__1" size="70" readonly>
        <input type="hidden" name="related_id__1" id="related_id__1">
       <br>
        <span class="infoLink" id="addRelationship" onclick="addRelation(2)">Add Relationship</span> </div>
 
      <label for="labels" style="margin-top:.5em;">Media Labels</label>
      <p>Note: For media of permits, correspondence, and other transaction related documents, please enter a 'description' media label.</p><label for="labels">Media Labels <span class="likeLink" onclick="getCtDoc('ctmedia_label');"> Define</span></label>
      <div id="labels" class="graydot" style="padding: .5em .25em;">
      <cfset i=1>
      <cfloop>
        <div id="labelsDiv__#i#">
          <select name="label__#i#" id="label__#i#" size="1">
            <option value="delete">Select label...</option>
            <cfloop query="ctmedia_label">
              <option value="#media_label#">#media_label#</option>
            </cfloop>
          </select>
          :&nbsp;
          <input type="text" name="label_value__#i#" id="label_value__#i#" size="80" value="">
	 </div>
	 <cfset i=i+1>
	</cfloop>
          <span class="infoLink" id="addLabel" onclick="addLabel(#i#)">Add Label</span>
      </div>
        
       </div>
      
      <input type="submit" 
				value="Create Media" 
				class="insBtn"
				onmouseover="this.className='insBtn btnhov'" 
				onmouseout="this.className='insBtn'">
    </form>
    <cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
       <cfquery name="s"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
          select guid from flat where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
       </cfquery>
       <script language="javascript" type="text/javascript">
          $("##relationship__1").val('shows cataloged_item');
          $("##related_value__1").val('#s.guid#');
          $("##related_id__1").val('#collection_object_id#');
       </script>
    </cfif>
    <cfif isdefined("relationship") and len(relationship) gt 0>
      <cfquery name="s"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select media_relationship from ctmedia_relationship where media_relationship= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
      </cfquery>
      <cfif s.recordCount eq 1 >
         <script language="javascript" type="text/javascript">
         <script language="javascript" type="text/javascript">
            $("##relationship__1").val('#relationship#');
            $("##related_value__1").val('#related_value#');
            $("##related_id__1").val('#related_id#');
         </script>
      <cfelse>
          <script language="javascript" type="text/javascript">
				$("##relationshiperror").html('<h2>Error: Unknown media relationship type "#relationship#"</h2>');
         </script>
      </cfif>
    </cfif>

					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
</cfswitch>
<!---------------------------------------------------------------------------------------------------->

<cfinclude template="/shared/_footer.cfm">
