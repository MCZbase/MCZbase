<cfset pageTitle = "Edit Media">
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
<cfoutput>
    <h1 class="h2">Search Media</h1>
  <div class="container-fluid">
<form name="newMedia" method="post" action="">
    <a name="kwFrm"></a>
  <p>This form may not find very recent changes. You can use the also use the <a href="##relFrm">relational search form</a> below.</p>
      <input type="hidden" name="action" value="search">
      <input type="hidden" name="srchType" value="key">
      <label for="keyword">Keyword</label>
      <input type="text" name="keyword" id="keyword" size="40">
      <span class="rdoCtl">Match Any
      <input type="radio" name="kwType" value="any">
      </span> <span class="rdoCtl">Match All
      <input type="radio" name="kwType" value="all" checked="checked">
      </span> <span class="rdoCtl">Match Phrase
      <input type="radio" name="kwType" value="phrase">
      </span>
      <label for="media_uri">Media URI</label>
     <input type="text" name="media_uri" id="media_uri">
        <label for="tag">Require TAG?</label>
        <input type="checkbox" id="tag" name="tag" value="1">
          <label for="mime_type">MIME Type</label>
          <select name="mime_type" id="mime_type" multiple="multiple" size="5">
            <option value="" selected="selected">Anything</option>
            <cfloop query="ctmime_type">
              <option value="#mime_type#">#mime_type#</option>
            </cfloop>
          </select>
          <label for="media_type">Media Type</label>
          <select name="media_type" id="media_type" multiple="multiple" size="5" >
            <option value="" selected="selected">Anything</option>
            <cfloop query="ctmedia_type">
              <option value="#media_type#">#media_type#</option>
            </cfloop>
          </select>
        <input type="submit" value="Search">&nbsp;&nbsp;
        <input type="reset" value="Reset Form"> 
    </form>
    <form name="newMedia" method="post" action="">
    <a name="relFrm"></a>
    <div> <p>You can use the also use the <a href="##kwFrm">keyword search form</a> above.</p> </div>
      <input type="hidden" name="action" value="search">
      <input type="hidden" name="srchType" value="full">
      <input type="hidden" id="number_of_relations" name="number_of_relations" value="1">
      <input type="hidden" id="number_of_labels" name="number_of_labels" value="1">
      <label for="media_uri">Media URI</label>
      <input type="text" name="media_uri" id="media_uri" size="90">
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
      <label for="tag">Require TAG?</label>
      <input type="checkbox" id="tag" name="tag" value="1">
	<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
          <div>
           <span>
               <label for "unlinked">Limit to Media not yet linked to any record.</label>
               <input type="checkbox" name="unlinked" id="unlinked" value="true">
           </span>
        </cfif>
      <label for="relationships">Media Relationships</label>
      <div id="relationships" class="relationship_dd">
        <select name="relationship__1" id="relationship__1" size="1">
          <option value=""></option>
          <cfloop query="ctmedia_relationship">
            <option value="#media_relationship#">#media_relationship#</option>
          </cfloop>
        </select>: &nbsp;<input type="text" name="related_value__1" id="related_value__1">
        <input type="hidden" name="related_id__1" id="related_id__1">
        <span class="infoLink" id="addRelationship" onclick="addRelation(2)">Add Relationship</span> 
		</div>
      <label for="labels">Media Labels</label>
      <div id="labels">
        <div id="labelsDiv__1">
          <select name="label__1" id="label__1" size="1">
            <option value=""></option>
            <cfloop query="ctmedia_label">
              <option value="#media_label#">#media_label#</option>
            </cfloop>
          </select>:&nbsp;
          <input type="text" name="label_value__1" id="label_value__1">
        </div>
        <span class="infoLink" id="addLabel" onclick="addLabel(2)">Add Label</span> </div>
         </div>
      <input type="submit" value="Search">
      <input type="reset" value="Reset Form">
       </form>
  </cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "edit">
<cfset title="Edit Media">

<div class="container-fluid">
	<div class="row mb-4 mx-0">
		<div class="col-12 px-0">

		</div>
	</div>
</div>
</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "new">
	<cfset title = "Create Media Record">

	<cfoutput>
		<div class="container-fluid">
			<div class="row mb-4 mx-0">
				<div class="col-12 px-0">
				
				</div>
			</div>
		</div>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->

<cfinclude template="/shared/_footer.cfm">
