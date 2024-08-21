<cfif isdefined("headless") and headless EQ 'true'>	
	<!--- Exclude display of page headers and includes --->
        <cfinclude template="/includes/functionLib.cfm">
	<cf_rolecheck>
<cfelse>
	<cfset title="Manage Media">
	<cfinclude template="/includes/_header.cfm">
	<script type='text/javascript' src='/includes/internalAjax.js'></script>
	<script>
		function manyCatItemToMedia(mid){
			var bgDiv = document.createElement('div');
			bgDiv.id = 'bgDiv';
			bgDiv.className = 'bgDiv';
			bgDiv.setAttribute('onclick','closeManyMedia()');
			document.body.appendChild(bgDiv);
			var guts = "/includes/forms/manyCatItemToMedia.cfm?media_id=" + mid;
			var theDiv = document.createElement('div');
			theDiv.id = 'annotateDiv';
			theDiv.className = 'annotateBox';
			theDiv.innerHTML='';
			theDiv.src = '';
			document.body.appendChild(theDiv);
			$('#annotateDiv').append('<iframe id="commentiframe" width="90%" height="100%">');
			$('#commentiframe').attr('src', guts);
		}
		
		function popupDefine() {
	    	window.open("/info/mediaDocumentation.cfm", "_blank", "toolbar=no,scrollbars=yes,resizable=no,menubar=no,top=70,left=580,width=860,height=650");
		}
	
	</script>
</cfif>
<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select media_relationship from ctmedia_relationship order by media_relationship
</cfquery>
<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select media_label from ctmedia_label order by media_label
</cfquery>
<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select media_type from ctmedia_type order by media_type
</cfquery>
<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select mime_type from ctmime_type order by mime_type
</cfquery>
<cfquery name="ctmedia_license" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select media_license_id,display media_license from ctmedia_license order by media_license_id
</cfquery>
<!----------------------------------------------------------------------------------------->

<cfif #action# is "saveEdit">
  <cfoutput> <img src="/images/info_i.gif" border="0" onClick="getMCZDocs('Edit/Delete_Media')" class="likeLink" alt="[ help ]"> 
    <!--- update media --->
    <cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		update media set
		media_uri=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_uri#" /> ,
		mime_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#" /> ,
		media_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#" /> ,
		preview_uri=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#" />, 
		mask_media_fg=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mask_media_fg#" maxlength="1" />
		<cfif len(media_license_id) gt 0>
			,media_license_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_license_id#" />
		<cfelse>
			,media_license_id=NULL
		</cfif>
		where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#" />
	</cfquery>
    <!--- relations --->
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
      <cfif thisRelatedId EQ '' AND thisRelationship NEQ "delete"><cfset failure=1></cfif>
      <cfif failure EQ 0>
      <cfif isdefined("media_relations_id__#n#")>
        <cfset thisRelationID=#evaluate("media_relations_id__" & n)#>
        <cfelse>
        <cfset thisRelationID=-1>
      </cfif>
      <cfif thisRelationID is -1>
        <cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				insert into media_relations (
					media_id,media_relationship,related_primary_key
				) values (
					#media_id#,'#thisRelationship#',#thisRelatedId#)
			</cfquery>
        <cfelse>
        <cfif #thisRelationship# is "delete">
          <cfquery name="upRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					delete from 
						media_relations
					where media_relations_id=#thisRelationID#
				</cfquery>
          <cfelse>
          <cfquery name="upRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update 
						media_relations
					set
						media_relationship='#thisRelationship#',
						related_primary_key=#thisRelatedId#
					where media_relations_id=#thisRelationID#
				</cfquery>
        </cfif><!--- delete or update relation --->
      </cfif><!--- relation exists ---> 
      </cfif><!--- Failure check --->
    </cfloop>
    <cfloop from="1" to="#number_of_labels#" index="n">
      <cfset thisLabel = #evaluate("label__" & n)#>
      <cfset thisLabelValue = #evaluate("label_value__" & n)#>
      <cfif isdefined("media_label_id__#n#")>
        <cfset thisLabelID=#evaluate("media_label_id__" & n)#>
        <cfelse>
        <cfset thisLabelID=-1>
      </cfif>
      <cfif thisLabelID is -1>
        <cfquery name="makeLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				insert into media_labels (media_id,media_label,label_value)
				values (#media_id#,'#thisLabel#','#thisLabelValue#')
			</cfquery>
        <cfelse>
        <cfif #thisLabel# is "delete">
          <cfquery name="upRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					delete from 
						media_labels
					where media_label_id=#thisLabelID#
				</cfquery>
          <cfelse>
          <cfquery name="upRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update 
						media_labels
					set
						media_label='#thisLabel#',
						label_value='#thisLabelValue#'
					where media_label_id=#thisLabelID#
				</cfquery>
        </cfif>
      </cfif>
    </cfloop>
    <cfif isdefined("headless") and headless EQ 'true'>
        <h2>Changes to Media Record Saved <img src="/images/info_i.gif" border="0" onClick="getMCZDocs('Edit/Delete_Media')" class="likeLink" alt="[ help ]"></h2>
    <cfelse>
        <cflocation url="media.cfm?action=edit&media_id=#media_id#" addtoken="false">
    </cfif>
  </cfoutput>
</cfif>
<!----------------------------------------------------------------------------------------->
<cfif #action# is "edit">
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT MEDIA_ID, 
			MEDIA_URI, 
			MIME_TYPE, 
			MEDIA_TYPE, 
			PREVIEW_URI, 
			MEDIA_LICENSE_ID, 
			MASK_MEDIA_FG,
			AUTO_PROTOCOL,
			AUTO_HOST,
			AUTO_PATH,
			AUTO_FILENAME,
			AUTO_EXTENSION, 
			mczbase.get_media_descriptor(media_id) as alttag 
		FROM media 
		WHERE media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
	</cfquery>
	<cfset relns=getMediaRelations(#media_id#)>
	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			media_label,
			label_value,
			subject,
			description,
			width,
			height,
			made_date,
			agent_name,
			media_label_id
		FROM
			media_labels
			left join preferred_agent_name on media_labels.assigned_by_agent_id=preferred_agent_name.agent_id
		WHERE
			media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
	</cfquery>
	<cfquery name="tag"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT count(*) c 
		FROM tag 
		WHERE
			media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
	</cfquery>
	<cfoutput>
		<div style="width:65em; padding: 1em 0 3em 0;margin:0 auto;" class="editMedia2">
			<h2 class="wikilink">
				Edit Media 
			 	<img src="/images/info_i.gif" onClick="getMCZDocs('Edit/Delete_Media')" class="likeLink" alt="[ help ]">
			</h2>

	<a href="/TAG.cfm?media_id=#media_id#">edit #tag.c# TAGs</a> ~ <a href="/showTAG.cfm?media_id=#media_id#">View #tag.c# TAGs</a> ~ <a href="/media/#media_id#">Detail Page</a>
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
		<div style="background-color: AliceBlue;"><strong>Alternative text for vision impaired users:</strong> #media.alttag#</div>
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
			<span class="infoLink" id="addRelationship" onclick="addRelation(#i#)">Add Relationship</span> 
		</div>
		<br>
		<cfquery name="reverseRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT source_media.media_id source_media_id, 
				source_media.auto_filename source_filename,
				source_media.media_uri source_media_uri,
				media_relations.media_relationship,
				MCZBASE.get_media_descriptor(source_media.media_id) source_alt
			FROM
				media_relations
				left join media source_media on media_relations.media_id = source_media.media_id
			WHERE
				related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				and media_relationship like '%media'
		</cfquery>
		<cfif reverseRelations.recordcount GT 0>
			<label for="reverseRelationsList">Relationships from other Media Records</label>
			<ul id="reverseRelationsList">
				<cfloop query="reverseRelations">
					<cfif len(reverseRelations.source_filename) GT 0><cfset sourceFilename=" (#reverseRelations.source_filename#)"><cfelse><cfset sourceFilename=""></cfif>
					<li>
						<a href="/media/#source_media_id#" title="#reverseRelations.source_alt#">
							/media/#source_media_id##sourceFilename#
						</a> 
						is #media_relationship# for /media/#media_id#
					</li>
				</cfloop>
			</ul>
		</cfif>
		<br>
		<label for="labels">Media Labels</label> 
		<p>Note: For media of permits, correspondence, and other transaction related documents, please enter a 'description' media label.</p>
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
		<input type="submit" value="Save Edits" class="insBtn" onmouseover="this.className='insBtn btnhov'" onmouseout="this.className='insBtn'">
	</form>
		<cfif media.auto_host EQ "mczbase.mcz.harvard.edu">
			<cftry>
				<cfif media.mime_type EQ "image/jpeg">
					<h3>EXIF Metadata</h3>
					<cfset targetFileName = "#Application.webDirectory#/#media.auto_path##media.auto_filename#" >
					<cfimage source="#targetFileName#" name="image">
					<cfset metadata = ImageGetEXIFMetadata(image) >
					<cfdump var="#metadata#">
				<cfelseif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
					<h3>EXIF Metadata</h3>
					<cfset fileProxy = CreateObject("java","java.io.File") >
					<cfset fileReaderProxy = CreateObject("java","javax.imageio.stream.FileImageInputStream") >
					<cfobject type="Java" class="javax.imageio.stream.FileImageInputStream" name="fileReader">
					<cfobject type="Java" class="javax.imageio.ImageIO" name="imageReaderClass">
					<cfobject type="Java" class="javax.imageio.ImageReader" name="imageReader">
					<cfobject type="Java" class="javax.imageio.metadata.IIOMetadata" name="metadata">
					<cfset targetFileName = "#Application.webDirectory#/#media.auto_path##media.auto_filename#" >
					<cfset targetFile = fileProxy.init(JavaCast("string","#targetFileName#")) >
					<cfset fileReader = fileReaderProxy.init(targetFile) >
					<cfset imageReader = imageReaderClass.getImageReadersByMIMEType(JavaCast("string",media.mime_type)).next() >
					<cfset imageReader.setInput(fileReader) >
					<cfset metadata = imageReader.getImageMetadata(0)>
					<cfset formatNames = metadata.getMetadataFormatNames()>
					<cfobject type="Java" class="javax.imageio.metadata.IIOMetadataNode" name="metadataNode">
					<cfobject type="Java" class="org.w3c.dom.NodeList" name="children">
					<cfobject type="Java" class="org.w3c.dom.NodeList" name="children2">
					<cfobject type="Java" class="org.w3c.dom.NamedNodeMap" name="attributeNodes">
					<cfloop array="#formatNames#" index="format">
						<cfset node = metadata.getAsTree('#format#')>
						[#node.getNodeName()#][#node.getNodeValue()#][#node.getUserObject()#]
						<cfset children = node.getChildNodes()>
						<cfset childCount = children.getLength()>
						[children=#childcount#]
						<cfloop from="0" to="#childCount-1#" index="i">
							[#children.item(i).getNodeName()#]
							[#children.item(i).getNodeValue()#]
							[#children.item(i).getUserObject()#]
							<cfset attributeNodes = children.item(i).getAttributes() >
							[#attributeNodes.getLength()#]
							<cfloop from="0" to="#attributeNodes.getLength()-1#" index="j">
								[#children.item(i).getAttributes().item(j).getNodeName()#]
								[#children.item(i).getAttributes().item(j).getNodeValue()#]
							</cfloop>
							<cfset children2 = children.item(i).getChildNodes()>
							[childrendepth2=#children2.getLength()#]
							<cfloop from="0" to="#children2.getLength()-1#" index="k">
								[#children2.item(k).getNodeName()#]
								[#children2.item(k).getNodeValue()#]
								[ 
									<cftry>
										#children2.item(k).getUserObject()#
									<cfcatch>(data)</cfcatch>
									</cftry>
								]
								[childrendepth3=#children2.item(k).getChildNodes().getLength()#]
							</cfloop>
						</cfloop>
						<cset attributeNodes = node.getAttributes() >
						<cfset attCount = attributeNodes.getLength()>
						<cfloop from="0" to="#attCount-1#" index="j">
							[#attributeNodes.item(j).getNodeName()#]
							[#attributeNodes.item(j).getNodeValue()#]
						</cfloop>
					</cfloop>
				</cfif>
			<cfcatch>
				[Unable to read EXIF metadata#cfcatch.message#]
			</cfcatch>
			</cftry>
		</cfif>
		</div>
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------------->
<cfif #action# is "newMedia">
  <cfoutput> 
      <div class="basic_box">
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
       <cfquery name="s"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
          select guid from flat where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
       </cfquery>
       <script language="javascript" type="text/javascript">
          $("##relationship__1").val('shows cataloged_item');
          $("##related_value__1").val('#s.guid#');
          $("##related_id__1").val('#collection_object_id#');
       </script>
    </cfif>
    <cfif isdefined("relationship") and len(relationship) gt 0>
      <cfquery name="s"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	  select media_relationship from ctmedia_relationship where media_relationship= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
      </cfquery>
      <cfif s.recordCount eq 1 >
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
  </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------>
<cfif #action# is "saveNew">
  <cfset error=false>
  <cfoutput>
    <cftransaction>
      <cftry>
      <cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select sq_media_id.nextval nv from dual
		</cfquery>
      <cfset media_id=mid.nv>
      <cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into media 
				(
					media_id
					,media_uri
					,mime_type
					,media_type
					,preview_uri
					,mask_media_fg
					<cfif len(media_license_id) gt 0>
						,media_license_id
					</cfif>
				)
            values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#escapeQuotes(media_uri)#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#">
					<cfif len(mask_media_fg) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mask_media_fg#">
					<cfelse>
						,0
					</cfif>
					<cfif len(media_license_id) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_license_id#">
					</cfif>
				)
		</cfquery>
      <cfloop from="1" to="#number_of_relations#" index="n">
        <cfset thisRelationship = #evaluate("relationship__" & n)#>
        <cfset thisRelatedId = #evaluate("related_id__" & n)#>
        <cfset thisTableName=ListLast(thisRelationship," ")>
        <cfif len(#thisRelationship#) gt 0 and len(#thisRelatedId#) gt 0>
          <cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					insert into 
						media_relations (
							media_id
							,media_relationship
							,related_primary_key
						)values (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisRelationship#">
							,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRelatedId#">
						)
				</cfquery>
        </cfif>
      </cfloop>
      <cfloop from="1" to="#number_of_labels#" index="n">
        <cfset thisLabel = #evaluate("label__" & n)#>
        <cfset thisLabelValue = #evaluate("label_value__" & n)#>
        <cfif len(#thisLabel#) gt 0 and len(#thisLabelValue#) gt 0>
          <cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					insert into media_labels (
						media_id
						,media_label
						,label_value
					)
					values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLabel#">
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLabelValue#">
					)
				</cfquery>
        </cfif>
      </cfloop>
      <cfcatch>
        <cftransaction action="rollback">
        <h2>Error saving new media record</h2>
        <p>#cfcatch.message#</p>
        <p>#cfcatch.detail#</p> 
        <cfif cfcatch.detail contains "ORA-00001: unique constraint (MCZBASE.U_MEDIA_URI)" >
           <h3>A media record for that resource already exists in MCZbase.</h3>
        </cfif>
        <cfset error=true>
      </cfcatch>
      </cftry>
    </cftransaction>
    <cfif not error>
	    <cfif isdefined("headless") and headless EQ 'true'>	
		<h2>New Media Record Saved</h2>
                <div id='savedLinkDiv'><a href='/media/#media_id#' target='_blank'>Media Details</a></div>
                <cfif len(#thisRelationship#) gt 0 and len(#thisRelatedId#) gt 0>
                    <div>Created with relationship: #thisRelationship#</div>
                </cfif>
        	<script language='javascript' type='text/javascript'>
                 $('##savedLinkDiv').removeClass('ui-widget-content');
                </script>
	    <cfelse>
		<cflocation url="media.cfm?action=edit&media_id=#media_id#" addtoken="false">
	    </cfif>
    </cfif>
  </cfoutput>
</cfif>

<cfif isdefined("headless") and headless EQ 'true'>	
	<!--- Leave off footer  --->
<cfelse>
	<cfinclude template="/includes/_footer.cfm">
</cfif>
