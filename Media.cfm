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
<cfquery name="ctInfRank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select infraspecific_rank from ctinfraspecific_rank order by infraspecific_rank
</cfquery>
<cfquery name="ctRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select taxon_relationship  from cttaxon_relation order by taxon_relationship
</cfquery>
<cfquery name="ctSourceAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select source_authority from CTTAXONOMIC_AUTHORITY order by source_authority
</cfquery>
<cfquery name="ctnomenclatural_code" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select nomenclatural_code from ctnomenclatural_code order by sort_order
</cfquery>
<cfquery name="cttaxon_status" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select taxon_status from cttaxon_status order by taxon_status
</cfquery>
<cfquery name="cttaxon_habitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select taxon_habitat from cttaxon_habitat order by taxon_habitat
</cfquery>
<cfquery name="ctguid_type_taxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
   from ctguid_type 
   where applies_to like '%taxonomy.taxonid%'
</cfquery>
<cfquery name="ctguid_type_scientificname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
   from ctguid_type 
   where applies_to like '%taxonomy.scientificnameid%'
</cfquery>


<cfoutput> 
	<script>
	// Check values once per second, warn for issues
	window.setInterval(chkTax, 1000);
	function chkTax(){
		if ($("##nomenclatural_code").val()=="unknown"){
			// no longer in use, but retain if added again
			$("##nomenclatural_code").addClass("warning");
		} else {
			$("##nomenclatural_code").removeClass("warning");
		}
		var ncode = $("##nomenclatural_code").val();
		if ($("##kingdom").val()==""){
			// kingdom should have a value
			$("##kingdom").addClass("warning");
		} else {
			$("##kingdom").removeClass("warning");
			if ( (ncode=="ICNafp" || ncode=="ICBN") && $("##kingdom").val()=="Animalia"){
				// animals shouldn't have the botanical (ICNafp) code.
				$("##kingdom").addClass("warning");
		 	}
		}
		if (ncode=="ICZN" && $("##infraspecific_author").val()!="") {
			$("##infraspecific_author").addClass("warning");
		} else { 
			$("##infraspecific_author").removeClass("warning");
		} 
		if (ncode=="ICZN" && $("##division").val()!="") {
			$("##division").addClass("warning");
		} else { 
			$("##division").removeClass("warning");
		} 
		if (ncode=="ICZN" && $("##subdivision").val()!="") {
			$("##subdivision").addClass("warning");
		} else { 
			$("##subdivision").removeClass("warning");
		} 
		if ((ncode=="ICNafp" || ncode=="ICBN") && $("##phylum").val()!="") {
			$("##phylum").addClass("warning");
		} else { 
			$("##phylum").removeClass("warning");
		} 
		if ((ncode=="ICNafp" || ncode=="ICBN") && $("##subphylum").val()!="") {
			$("##subphylum").addClass("warning");
		} else { 
			$("##subphylum").removeClass("warning");
		} 
	}
	/** getLowestTaxon 
    * find the lowest ranking taxon name on the taxonomy form.
	 * @return the value of the lowest rank filled in field (or set of fields if below generic rank).
	 */
	function getLowestTaxon() { 
		var result = "";
		if ($('##genus').val()!="") { 
			result = $('##genus').val();
			if ($('##subgenus').val()!="") { 
				result = result + " (" + $('##subgenus').val() + ")";
			}
			if ($('##species').val()!="") { 
				result = result + " " + $('##species').val();
			}
			if ($('##subspecies').val()!="") { 
				result = result + " " + $('##subspecies').val();
			}
		} else if ($('##tribe').val()!="") { 
			result = $('##tribe').val();
		} else if ($('##subfamily').val()!="") { 
			result = $('##subfamily').val();
		} else if ($('##family').val()!="") { 
			result = $('##family').val();
		} else if ($('##superfamily').val()!="") { 
			result = $('##superfamily').val();
		} else if ($('##infraorder').val()!="") { 
			result = $('##infraorder').val();
		} else if ($('##suborder').val()!="") { 
			result = $('##suborder').val();
		} else if ($('##phylorder').val()!="") { 
			result = $('##phylorder').val();
		} else if ($('##superorder').val()!="") { 
			result = $('##superorder').val();
		} else if ($('##subclass').val()!="") { 
			result = $('##subclass').val();
		} else if ($('##phylclass').val()!="") { 
			result = $('##phylclass').val();
		} else if ($('##superclass').val()!="") { 
			result = $('##superclass').val();
		} else if ($('##subphylum').val()!="") { 
			result = $('##subphylum').val();
		} else if ($('##phylum').val()!="") { 
			result = $('##phylum').val();
		} else if ($('##subdivision').val()!="") { 
			result = $('##subdivision').val();
		} else if ($('##division').val()!="") { 
			result = $('##division').val();
		} else if ($('##kingdom').val()!="") { 
			result = $('##kingdom').val();
		}
		return result;
	}

	/** toggleBotanicalVisibility
    */
	function toggleBotanicalVisibility() { 
		var ncode = $('##nomenclatural_code').val();
		if (ncode=='ICNafp' || ncode=='ICBN') { 
			$('.botanical').show();	
			$('##infraspecific_author').show(); 
			$('##infraspecific_author_label').show(); 
			$('##division').show(); 
			$('##division_label').show(); 
			$('##subdivision').show(); 
			$('##subdivision_label').show(); 
			$('##division_row').show(); 
			if ($('##phylum').val()=="") { 
				$('##phylum').hide(); 
				$('##phylum_label').hide(); 
				if ($('##subphylum').val()=="") { 
					$('##subphylum').hide(); 
					$('##subphylum_label').hide(); 
					$('##phylum_row').hide(); 
				}
			}
		} else { 
			$('.botanical').hide();	
			if ($('##infraspecific_author').val()=="") { 
				$('##infraspecific_author').hide(); 
				$('##infraspecific_author_label').hide(); 
			}
			if ($('##division').val()=="") { 
				$('##division').hide(); 
				$('##division_label').hide(); 
				if ($('##subdivision').val()=="") { 
					$('##subdivision').hide(); 
					$('##subdivision_label').hide(); 
					$('##division_row').hide(); 
				}
			}
			$('##phylum').show(); 
			$('##phylum_label').show(); 
			$('##subphylum').show(); 
			$('##subphylum_label').show(); 
			$('##phylum_row').show(); 
		}
	}

	// Hide botanical code elements of form when code is ICZN
	$(document).ready(function() { 
		$('##nomenclatural_code').change(function() { 
			console.log($('##nomenclatural_code').val());
			toggleBotanicalVisibility();
		});
		toggleBotanicalVisibility();
	});  
</script> 
</cfoutput> 
<!------------------------------------------------>
<cfif action is "nothing">
<cfoutput>
    <cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select media_relationship from ctmedia_relationship order by media_relationship
	</cfquery>
	<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select media_label from ctmedia_label <cfif oneOfUs EQ 0>where media_label <> 'internal remarks'</cfif> order by media_label
	</cfquery>
	<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select media_type from ctmedia_type order by media_type
	</cfquery>
	<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select mime_type from ctmime_type order by mime_type
	</cfquery>
    <h2>Search Media
      <cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
      </cfif>
    </h2>
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
<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from taxonomy where taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
<cfquery name="isSourceAuthorityCurrent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as ct from CTTAXONOMIC_AUTHORITY where source_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#gettaxa.source_authority#">
	</cfquery>
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
<cfif action is "deleteMedia">
	<cfoutput>
		<cfquery name="killhabitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM
			taxon_habitat
		WHERE
			taxon_habitat=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#orighabitatName#">
			AND taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
		<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "newMedia">
	<cfset title = "Add Taxon">
	<cfquery name="getClonedFromTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from taxonomy where taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
</cfquery>
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
<cfif action is "saveNewMedia">
	<cfoutput>

	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "new">
	<cfoutput>
	
	</cfoutput>
</cfif>


<cfinclude template="/shared/_footer.cfm">
