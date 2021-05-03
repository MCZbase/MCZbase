<cfinclude template="/includes/_header.cfm">
<cfhtmlhead text='<script src="#Application.protocol#://maps.google.com/maps?file=api&amp;v=2.x&amp;sensor=false&amp;key=#application.gmap_api_key#" type="text/javascript"></script>'>
<script src="/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js" language="javascript" type="text/javascript"></script>
<cfset title="Specimen Search">
<cfset metaDesc="Search for museum specimens and observations by taxonomy, identifications, specimen attributes, and usage history.">
<cfoutput>
<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select count(collection_object_id) as cnt from cataloged_item
</cfquery>
<cfquery name="ctmedia_type" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_type from ctmedia_type order by media_type
</cfquery>
<cfquery name="hasCanned" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select SEARCH_NAME,URL
	from cf_canned_search,cf_users
	where cf_users.user_id=cf_canned_search.user_id
	and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	and URL like '%SpecimenResults.cfm%'
	order by search_name
</cfquery>

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
	<cfset isClicky = "likeLink">
<cfelse>
	<cfset oneOfUs = 0>
	<cfset isClicky = "">
</cfif>

<div class="basic_box" style="margin-top: -1.5em;">
<table>
	<tr>
		<td>
			Access to #getCount.cnt#
			<cfif len(#session.exclusive_collection_id#) gt 0>
				<cfquery name="coll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select collection
					from collection where
					collection_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.exclusive_collection_id#">
				</cfquery>
				<strong>#coll.collection#</strong>
			records. <a href="searchAll.cfm">Search all collections</a>.
			<cfelse>
			records.
			</cfif>
		</td>
		<td>
			<span class="infolink" onClick="getHelp('CollStats');">
				Holdings Details
			</span>
			<span class="infolink" onClick="getHelp('search_help');">
				Search Tips
			</span>
		</td>
		<cfif #hasCanned.recordcount# gt 0>
			<td class="infolink">
				<span>Saved Searches:</span> <select name="goCanned" id="goCanned" size="1" onchange="document.location=this.value;">
					<option value=""></option>
					<option value="saveSearch.cfm?action=manage">[ Manage ]</option>
					<cfloop query="hasCanned">
						<option value="#url#">#SEARCH_NAME#</option><br />
					</cfloop>
				</select>
			</td>
		</cfif>
		<td class="horiz_padding">
			<span style="color:red;">
				<cfif #action# is "dispCollObj">
					<p>You are searching for items to add to a loan.</p>
                <cfelseif #action# is "dispCollObjDeacc">
					<p>You are searching for items to add to a deaccession.</p>
				<cfelseif #action# is "encumber">
					<p>You are searching for items to encumber.</p>
				<cfelseif #action# is "collEvent">
					<p>You are searching for items to change collecting event.</p>
				<cfelseif #action# is "identification">
					<p>You are searching for items to reidentify.</p>
				<cfelseif #action# is "addAccn">
					<p>You are searching for items to reaccession.</p>
				</cfif>
			</span>
		</td>
	</tr>
</table>
<form method="post" action="SpecimenResults.cfm" name="SpecData" id="SpecData">
<table style="margin: 1em 0;">
	<tr>
		<td class="horiz_padding">
			<input type="submit" value="Search" class="schBtn"
			    onmouseover="this.className='schBtn btnhov'" onmouseout="this.className='schBtn'">
		</td>
		<td class="horiz_padding">
			<input type="reset" name="Reset" value="Clear Form" class="clrBtn"
			    onmouseover="this.className='clrBtn btnhov'" onmouseout="this.className='clrBtn'">
		</td>
		<td class="horiz_padding;">
			<input type="button" name="Previous" value="Use Last Values" class="lnkBtn"	onclick="setPrevSearch()">
		</td>
		<td class="horiz_padding">
			<span><b>See results as:</b></span>
		</td>
		<td align="left" colspan="2" valign="top">
		 	<select name="tgtForm1" id="tgtForm1" size="1"  onChange="changeTarget(this.id,this.value);">
				<option value="">Specimen Records</option>
				<option value="SpecimenResultsHTML.cfm">HTML Specimen Records</option>
				<option  value="/bnhmMaps/bnhmMapData.cfm">BerkeleyMapper Map</option>
				<option  value="/bnhmMaps/kml.cfm?action=newReq">KML</option>
				<option value="SpecimenResultsSummary.cfm">Specimen Summary</option>
				<option  value="SpecimenGraph.cfm">Graph</option>
			</select>
		</td>
		<td align="left">
			<div id="groupByDiv1" style="display:none;border:1px solid green;padding:.5em;">
				<font size="-1"><em><strong>Group by:</strong></em></font><br>
				<select name="groupBy1" id="groupBy1" multiple size="4" onchange="changeGrp(this.id)">
					<option value="">Scientific Name</option>
					<option value="continent_ocean">Continent</option>
					<option value="country">Country</option>
					<option value="state_prov">State</option>
					<option value="county">County</option>
					<option value="quad">Map Name</option>
					<option value="feature">Land Feature</option>
					<option value="water_feature">Water Feature</option>
					<option value="island">Island</option>
					<option value="island_group">Island Group</option>
					<option value="sea">Sea</option>
					<option value="spec_locality">Specific Locality</option>
					<option value="yr">Year</option>
				</select>
			</div>
			<div id="kmlDiv1" style="display:none;border:1px solid green;padding:.5em;">
				<font size="-1"><em><strong>KML Options:</strong></em></font><br>
				<label for="next1">Color By</label>
				<select name="next1" id="next1" onchange="kmlSync(this.id,this.value)">
					<option value="colorByCollection">Collection</option>
					<option value="colorBySpecies">Species</option>
				</select>
				<label for="method1">Method</label>
				<select name="method1"  id="method1" onchange="kmlSync(this.id,this.value)">
					<option value="download">Download</option>
					<option value="link">Download Linkfile</option>
					<option value="gmap">Google Maps</option>
				</select>
				<label for="includeTimeSpan1">include Time?</label>
				<select name="includeTimeSpan1"  id="includeTimeSpan1" onchange="kmlSync(this.id,this.value)">
					<option value="0">no</option>
					<option value="1">yes</option>
				</select>
				<label for="showUnaccepted1">Show unaccepted determinations?</label>
				<select name="showUnaccepted1"  id="showUnaccepted1" onchange="kmlSync(this.id,this.value)">
					<option value="0">no</option>
					<option value="1">yes</option>
				</select>
				<label for="mapByLocality1">All specimens from localities?</label>
				<select  name="mapByLocality1" id="mapByLocality1" onchange="kmlSync(this.id,this.value)">
					<option value="0">no</option>
					<option value="1">yes</option>
				</select>
				<label for="showErrors1">Show error radii?</label>
				<select  name="showErrors1" id="showErrors1" onchange="kmlSync(this.id,this.value)">
					<option value="0">no</option>
					<option value="1">yes</option>
				</select>
			</div>
		</td>

	</tr>
</table>
<div style="margin-bottom: 5px;margin-left: 5px;">
	<span id="observations">Include&nbsp;Observations?</span><input type="checkbox" name="showObservations" id="showObservations" value="1" onchange="changeshowObservations(this.checked);"<cfif session.showObservations eq 1> checked="checked"</cfif>>
	&nbsp;&nbsp;&nbsp;<span id="_is_tissue">Require&nbsp;Tissues?</span><input type="checkbox" name="is_tissue" id="is_tissue" value="1">
        &nbsp;&nbsp;&nbsp;<span id="_generic_m_ai">Accent&nbsp;Insensitive?</span><input type="checkbox" name="accentInsensitive" id="accentInsensitive" value="1">
	&nbsp;&nbsp;&nbsp;<span id="_media_type">Require&nbsp;Media</span>: <select name="media_type" id="media_type" size="1">
				<option value=""></option>
                <option value="any">Any</option>
				<cfloop query="ctmedia_type">
					<option value="#ctmedia_type.media_type#">#ctmedia_type.media_type#</option>
				</cfloop>
			</select>
                        </span>
                        <cfif listcontainsnocase(session.roles,"coldfusion_user")>
                        <!---  TODO: Needs an appropriate class for styling  --->
                        <span class="infolink" id="c_save_showhide">Save current more/fewer options</span>&nbsp;<span id="c_save_showhide_response"></span>
                        </cfif>
</div>
<input type="hidden" name="Action" value="#Action#">
<div class="secDiv" style="border-top: 1px dotted ##ccc;">
	<cfquery name="ctInst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT institution_acronym, collection, collection_id FROM collection
	    <cfif len(#session.exclusive_collection_id#) gt 0>
			WHERE collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.exclusive_collection_id#">
		</cfif>
		order by collection
	</cfquery>

   <cfquery name="hasPrefSuff" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT max(CATNUM_PREF_FG) as prefFG, max(CATNUM_SUFF_FG) as suffFG from collection
		<cfif len(#session.exclusive_collection_id#) gt 0>
			WHERE collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.exclusive_collection_id#">
		</cfif>
	</cfquery>

	<cfif isdefined("collection_id") and len(#collection_id#) gt 0>
		<cfset thisCollId = #collection_id#>
	<cfelse>
		<cfset thisCollId = "">
	</cfif>
	<table class="ssrch">
		<tr>
			<td colspan="4" class="secHead">
				<span class="secLabel">Identifiers</span>
				<span class="secControl" id="c_identifiers"	onclick="showHide('identifiers',1)">Show More Options</span>
				<span class="secControl" id="c_identifiers_cust">Customize</span>
			</td>
		</tr>
		<tr>
			<td class="lbl" valign="top">
				<span id="collection">Institutional Catalog</span>:
			</td>
			<td class="srch" valign="top">
				<select name="collection_id" id="collection_id" size="1">
			   	<cfif len(#session.exclusive_collection_id#) is 0>
						<option value="">All</option>
					</cfif>
					<cfloop query="ctInst">
						<option <cfif #thisCollId# is #ctInst.collection_id#>
					 		selected </cfif>
							value="#ctInst.collection_id#">
							#ctInst.collection#</option>
					</cfloop>
				</select>
			</td>
			<td class="lbl" valign="top" style="width: 5em;">
				<span id="cat_num">Number:</span>
			</td>
			<td class="srch" valign="top">
				<cfif #ListContains(session.searchBy, 'bigsearchbox')# gt 0>
					<textarea name="listcatnum" id="listcatnum" rows="6" cols="40" wrap="soft" style="width: 475px;"></textarea>
				<cfelse>
					<input type="text" name="listcatnum" id="listcatnum" size="25" value="">
				</cfif>
			</td>
		</tr>
		<tr>
			<td colspan="2"><input class="lblone" type="checkbox" name="searchOtherIds" value="Yes"></td>
			<td colspan="2"><span class="lbltwo">Include Other Identifiers in search (original number, previous number, etc.)</span></td>
		</tr>
		<cfif isdefined("session.CustomOtherIdentifier") and len(#session.CustomOtherIdentifier#) gt 0>
		<tr>
			<td colspan="2" class="lbl">
				<span id="custom_identifier">#replace(session.CustomOtherIdentifier," ","&nbsp;","all")#:</span>
			</td>
			<td colspan="2" class="srch">
				<label for="CustomOidOper">Display Value</label>
				<select name="CustomOidOper" id="CustomOidOper" size="1">
					<option value="IS">is</option>
					<option value="" selected="selected">contains</option>
					<option value="LIST">in list</option>
					<option value="BETWEEN">in range</option>
				</select>&nbsp;<input type="text" name="CustomIdentifierValue" id="CustomIdentifierValue" size="50">
			</td>
		</tr>
		<cfif isdefined("session.fancyCOID") and #session.fancyCOID# is 1>
		<tr>
			<td class="lbl" colspan="2">
					&nbsp;
			</td>
			<td class="srch" colspan="2">
				<table>
					<tr>
						<td>
							<label for="custom_id_prefix">OR: Prefix</label>
							<input type="text" name="custom_id_prefix" id="custom_id_prefix" size="12">
						</td>
						<td>
							<label for="custom_id_number">Number</label>
							<input type="text" name="custom_id_number" id="custom_id_number" size="24">
						</td>
						<td>
							<label for="custom_id_suffix">Suffix</label>
							<input type="text" name="custom_id_suffix" id="custom_id_suffix" size="12">
						</td>
					</tr>
				</table>
			</td>
		</tr>
		</cfif>
		</cfif>
	</table>
<div id="e_identifiers">

    <table id="t_identifiers" class="ssrch">
    		<cfif isdefined("session.portal_id") and session.portal_id gt 0>
    			<cftry>
    				<cfquery name="OtherIdType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
    					select distinct(other_id_type) FROM CCTCOLL_OTHER_ID_TYPE#session.portal_id# ORDER BY other_Id_Type
    				</cfquery>
    				<cfcatch>
    					<cfquery name="OtherIdType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
    						select distinct(other_id_type) FROM CTCOLL_OTHER_ID_TYPE ORDER BY other_Id_Type
    					</cfquery>
    				</cfcatch>
    			</cftry>
    		<cfelse>
    			<cfquery name="OtherIdType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
    				select distinct(other_id_type) FROM CTCOLL_OTHER_ID_TYPE ORDER BY other_Id_Type
    			</cfquery>
    		</cfif>
    	<tr>
    		<td class="lbl">
    			<span id="other_id_type">Other&nbsp;Identifier&nbsp;Type:</span>
    		</td>
    		<td class="srch">
    			<select name="OIDType" id="OIDType" size="1"
    				<cfif isdefined("OIDType") and len(#OIDType#) gt 0>
    					class="reqdClr" </cfif>>
    				<option value=""></option>
    				<cfloop query="OtherIdType">
    					<option
    						<cfif isdefined("OIDType") and len(#OIDType#) gt 0>
    							<cfif #OIDType# is #OtherIdType.other_id_type#>
    								selected
    							</cfif>
    						</cfif>
    						value="#OtherIdType.other_id_type#">#OtherIdType.other_id_type#</option>
    				</cfloop>
    			</select><span class="infoLink" onclick="getCtDoc('ctcoll_other_id_type',SpecData.OIDType.value);">Define</span>
    		</td>
    	</tr>
    	<cfquery name="OtherIdType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    		select distinct(other_id_type) FROM ctColl_Other_Id_Type ORDER BY other_Id_Type
    	</cfquery>
    	<tr>
    		<td class="lbl">
    			<span id="other_id_num">Other&nbsp;Identifier:</span>
    		</td>
    		<td class="srch">
    			<select name="oidOper" id="oidOper" size="1">
    				<option value="" selected="selected">contains</option>
    				<option value="IS">is</option>
    			</select>
    			<cfif #ListContains(session.searchBy, 'bigsearchbox')# gt 0>
    				<textarea name="OIDNum" id="OIDNum" rows="6" cols="30" wrap="soft"></textarea>
    			<cfelse>
    				<input type="text" name="OIDNum" id="OIDNum" size="34">
    			</cfif>
    		</td>
    	</tr>
    	<tr>
    		<td class="lbl">
    			<span id="_accn_number">Accession:</span>
    		</td>
    		<td class="srch">
    			<input type="text" name="accn_number" id="accn_number">
    			<span class="infoLink" onclick="var e=document.getElementById('accn_number');e.value='='+e.value;">Add = for exact match</span>
    		</td>
    	</tr>
    	<tr>
    		<td class="lbl">
    			<span id="accession_agency">Accession Agency:</span>
    		</td>
    		<td>
    			<input type="text" name="accn_agency" id="accn_agency" size="50">
    		</td>
    	</tr>
    </table>

</div>
</div>
<div class="secDiv">
	<table class="ssrch">
		<tr>
			<td colspan="2" class="secHead">
					<span class="secLabel">Identification and Taxonomy</span>
					<span class="secControl" id="c_taxonomy"
						onclick="showHide('taxonomy',1)">Show More Options</span>
			</td>
		</tr>
		<tr>
			<td class="lbl">
				<span id="_any_taxa_term">Any Taxonomic Element:</span>
			</td>
			<td class="srch">
             <p class="topspace">&nbsp;</p>
				<input type="text" name="any_taxa_term" id="any_taxa_term" size="28">
				<input type="checkbox" name="searchOnlyCurrent" value="Yes">Search only current identifications.<br>
			</td>
		</tr>
	</table>
	<div id="e_taxonomy">

         <script type="text/javascript" language="javascript">
         	jQuery(document).ready(function() {
         		jQuery("##phylclass").autocomplete("/ajax/phylclass.cfm", {
         			width: 320,
         			max: 50,
         			autofill: false,
         			multiple: false,
         			scroll: true,
         			scrollHeight: 300,
         			matchContains: true,
         			minChars: 1,
         			selectFirst:false
         		});
         	});

         </script>
         <cfquery name="ctNatureOfId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
         	SELECT DISTINCT(nature_of_id) FROM ctnature_of_id ORDER BY nature_of_id
         </cfquery>
         <table id="t_identifiers" class="ssrch">
         	<tr>
         		<td class="lbl">
         			<span id="_scientific_name">Scientific&nbsp;Name:</span>
         		</td>
         		<td class="srch">
         			<select name="sciNameOper" id="sciNameOper" size="1">
         				<option value="">contains</option>
         				<option value="NOT LIKE">does not contain</option>
         				<option value="=">is exactly</option>
         				<option value="was">is/was/cited/related</option>
         				<option value="OR">in list</option>
         		  	</select>
         			<input type="text" name="scientific_name" id="scientific_name" size="28">
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="_phylclass">Class:</span>
         		</td>
         		<td class="srch">
         		 	<input type="text" name="phylclass" id="phylclass" size="50">
         			<span class="infoLink" onclick="var e=document.getElementById('phylclass');e.value='='+e.value;">Add = for exact match</span>
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="_family">Family:</span>
         		</td>
         		<td class="srch">
         		 	<input type="text" name="family" id="family" size="50">
         			<span class="infoLink" onclick="var e=document.getElementById('family');e.value='='+e.value;">Add = for exact match</span>
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="_genus">Genus:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="genus" id="genus" size="50">
         			<span class="infoLink" onclick="var e=document.getElementById('genus');e.value='='+e.value;">Add = for exact match</span>
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="_species">Species:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="species" id="species" size="50">
         			<span class="infoLink" onclick="var e=document.getElementById('species');e.value='='+e.value;">Add = for exact match</span>
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="_subspecies">Subspecies:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="subspecies" id="subspecies" size="50">
         			<span class="infoLink" onclick="var e=document.getElementById('subspecies');e.value='='+e.value;">Add = for exact match</span>
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="_common_name">Common Name:</span>
         		</td>
         		<td class="srch">
         			<input name="common_name" id="common_name" type="text" size="50">
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="_nature_of_id">Nature of ID:</span>
         		</td>
         		<td class="srch">
         			<select name="nature_of_id" id="nature_of_id" size="1">
         				<option value=""></option>
         				<cfloop query="ctNatureOfId">
         					<option value="#ctNatureOfId.nature_of_id#">#ctNatureOfId.nature_of_id#</option>
         				</cfloop>
         			</select><span class="infoLink"
         							onclick="getCtDoc('ctnature_of_id',SpecData.nature_of_id.value);">Define</span>
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="identifier">Determiner:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="identified_agent" id="identified_agent">
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="_identification_remarks">ID Remarks:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="identification_remarks" id="identification_remarks">
         		</td>
         	</tr>
         </table>

    </div>
</div>
<div class="secDiv">
	<table class="ssrch">
		<tr>
			<td colspan="2" class="secHead">
				<span class="secLabel">Locality</span>
				<span class="secControl" id="c_locality" onclick="showHide('locality',1)">Show More Options</span>
			</td>
		</tr>
		<tr>
			<td class="lbl">
				<span id="any_geog_term">Any&nbsp;Geographic&nbsp;Element:</span>
			</td>
			<td class="srch">
            <p class="topspace">&nbsp;</p>
				<input type="text" name="any_geog" id="any_geog" size="50"> <span style='font-size:.9em;'>(include&nbsp;known&nbsp;accent&nbsp;marks&nbsp;for&nbsp;optimal&nbsp;results)</span>
				<span class="secControl" style="font-size:.9em;" id="c_spatial_query" onclick="showHide('spatial_query',1)">Select on Google Map</span>
			</td>
		</tr>
		<tr>
			<td colspan="2">
				<div id="e_spatial_query"></div>
			</td>
		</tr>
	</table>
	<div id="e_locality">


       <script type="text/javascript" language="javascript">
       	jQuery(document).ready(function() {
       		jQuery("##geology_attribute_value").autocomplete("/ajax/tData.cfm?action=suggestGeologyAttVal", {
       			width: 320,
       			max: 20,
       			autofill: true,
       			highlight: false,
       			multiple: false,
       			scroll: true,
       			scrollHeight: 300
       		});
       	});
       </script>
       <cfquery name="ctElevUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       	select orig_elev_units from CTORIG_ELEV_UNITS
       </cfquery>
       <cfquery name="ctDepthUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       	select depth_units from ctDepth_Units
       </cfquery>
       <cfquery name="ContOcean" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       	select continent_ocean from ctContinent ORDER BY continent_ocean
       </cfquery>
       <cfquery name="Country" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       	select distinct(country) from geog_auth_rec order by country
       </cfquery>
       <cfquery name="IslGrp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       	select island_group from ctIsland_Group order by Island_Group
       </cfquery>
       <cfquery name="Feature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       	select distinct(Feature) from geog_auth_rec order by Feature
       </cfquery>
			 <cfquery name="Water_Feature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				 select distinct(Water_Feature) from geog_auth_rec order by Water_Feature
			 </cfquery>
       <cfquery name="ctgeology_attribute"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       	select attribute from geology_attribute_hierarchy group by attribute order by attribute
       </cfquery>
       <cfquery name="ctgeology_attribute_val"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       	select attribute_value from geology_attribute_hierarchy group by attribute_value order by attribute_value
       </cfquery>
       <cfquery name="ctlat_long_error_units"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       	select lat_long_error_units from ctlat_long_error_units group by lat_long_error_units order by lat_long_error_units
       </cfquery>
       <cfquery name="ctverificationstatus"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       	select verificationstatus from ctverificationstatus group by verificationstatus order by verificationstatus
       </cfquery>
       <table id="t_identifiers" class="ssrch">

       	<tr>
       		<td class="lbl">
       			<span id="_geology_attribute">Geology Attribute:</span>
       		</td>
       		<td class="srch">
       			<select name="geology_attribute" id="geology_attribute" size="1">
       				<option value=""></option>
       				<cfloop query="ctgeology_attribute">
       					<option value="#attribute#">#attribute#</option>
       				</cfloop>
       			</select>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_geology_attribute_value">Geology Attribute Value:</span>
       		</td>
       		<td class="srch">
       			<input type="text" name="geology_attribute_value" id="geology_attribute_value" size="50">
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_geology_hierarchies">Traverse Geology Hierarchies:</span>
       		</td>
       		<td class="srch">
       			<select name="geology_hierarchies" id="geology_hierarchies" size="1">
       				<option value="1">yes</option>
       				<option value="0">no</option>
       			</select>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_continent_ocean">Continent/Ocean:</span>
       		</td>
       		<td class="srch">
       			<select name="continent_ocean" id="continent_ocean" size="1">
       				<option value=""></option>
       				<option value="NULL">NULL</option>
       				<cfloop query="ContOcean">
       					<option value="#ContOcean.continent_ocean#">#ContOcean.continent_ocean#</option>
       				</cfloop>
       			</select>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_country">Country:</span>
       		</td>
       		<td class="srch">
       			<select name="country" id="country" size="1">
       				<option value=""></option>
       				<option value="NULL">NULL</option>
       				<cfloop query="Country">
       					<option value="#Country.Country#">#Country.Country#</option>
       				</cfloop>
       			</select>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_state_prov">State/Province:</span>
       		</td>
       		<td class="srch">
       			<input type="text" name="state_prov" id="state_prov" size="50">
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_quad">USGS Quad Map:</span>
       		</td>
       		<td class="srch">
       			<input type="text" name="quad" id="quad" size="50">
       			<span class="infoLink" onclick="getQuadHelp();">[ Pick AK Quad ]</span>
       			<span class="infoLink" onclick="document.getElementById('quad').value='NULL';">[ NULL ]</span>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_county">County:</span>
       		</td>
       		<td class="srch">
       			<input type="text" name="county" id="county" size="50">
       			<span class="infoLink" onclick="document.getElementById('county').value='NULL';">[ NULL ]</span>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_island_group">Island Group:</span>
       		</td>
       		<td class="srch">
       			<select name="island_group" id="island_group" size="1">
       				  <option value=""></option>
       				  <option value="NULL">NULL</option>
       				  <cfloop query="IslGrp">
       					<option value="#IslGrp.Island_Group#">#IslGrp.Island_Group#</option>
       				  </cfloop>
       			</select>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_island">Island:</span>
       		</td>
       		<td class="srch">
       			<input type="text" name="island" id="island" size="50">
       			<span class="infoLink" onclick="document.getElementById('island').value='NULL';">[ NULL ]</span>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_feature">Land Feature:</span>
       		</td>
       		<td class="srch">
       			<select name="feature" id="feature" size="1">
       				<option value=""></option>
       				<option value="NULL">NULL</option>
       				<cfloop query="Feature">
       					<option value="#Feature.Feature#">#Feature.Feature#</option>
       				</cfloop>
       			</select>
       		</td>
       	</tr>
				<tr>
					<td class="lbl">
						<span id="_water_feature">Water Feature:</span>
					</td>
					<td class="srch">
						<select name="water_feature" id="water_feature" size="1">
							<option value=""></option>
							<option value="NULL">NULL</option>
							<cfloop query="water_Feature">
								<option value="#Water_Feature.Water_Feature#">#Water_Feature.Water_Feature#</option>
							</cfloop>
						</select>
					</td>
				</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_spec_locality">Specific&nbsp;Locality:</span>
       		</td>
       		<td class="srch">
       			<input type="text" name="spec_locality" id="spec_locality" size="50">
       			<span class="infoLink" onclick="var e=document.getElementById('spec_locality');e.value='='+e.value;">Add = for exact match</span>
       			<span class="infoLink" onclick="document.getElementById('spec_locality').value='NULL';">[ NULL ]</span>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="elevation">Elevation:</span>
       		</td>
       		<td class="srch">
       			<input type="text" name="minimum_elevation" id="minimum_elevation" size="5"> -
       			<input type="text" name="maximum_elevation" id="maximum_elevation" size="5">
       			<select name="orig_elev_units" id="orig_elev_units" size="1" style="width:55px">
       				<option value=""></option>
       				<cfloop query="ctElevUnits">
       					<option value="#ctElevUnits.orig_elev_units#">#ctElevUnits.orig_elev_units#</option>
       				</cfloop>
       			</select>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="depth">Depth:</span>
       		</td>
       		<td class="srch">
       			<input type="text" name="minimum_depth" id="minimum_depth" size="5"> -
       			<input type="text" name="maximum_depth" id="maximum_depth" size="5">
       			<select name="depth_units" id="depth_units" size="1" style="width:55px">
       				<option value=""></option>
       				<cfloop query="ctDepthUnits">
       					<option value="#ctDepthUnits.depth_units#">#ctDepthUnits.depth_units#</option>
       				</cfloop>
       			</select>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="_verificationstatus">Verification Status:</span>
       		</td>
       		<td class="srch">
       			<select name="verificationstatus" id="verificationstatus" size="1">
       				<option value=""></option>
       				<cfloop query="ctverificationstatus">
       					<option value="#ctverificationstatus.verificationstatus#">#ctverificationstatus.verificationstatus#</option>
       				</cfloop>
       			</select>
       		</td>
       	</tr>
       	<tr>
       		<td class="lbl">
       			<span id="max_error_distance">Maximum Uncertainty:</span>
       		</td>
       		<td class="srch">
       			<input type="text" name="min_max_error" id="min_max_error" size="5"> -
       			<input type="text" name="max_max_error" id="max_max_error" size="5">
       			<select name="max_error_units" id="max_error_units" size="1">
       				<option value=""></option>
       				<cfloop query="ctlat_long_error_units">
       					<option value="#ctlat_long_error_units.lat_long_error_units#">#ctlat_long_error_units.lat_long_error_units#</option>
       				</cfloop>
       			</select>
       		</td>
       	</tr>
       </table>
    </div>
</div>
<div class="secDiv">
	<table class="ssrch">
		<tr>
			<td colspan="2" class="secHead">
					<span class="secLabel">Date/Collector</span>
					<span class="secControl" id="c_collevent"
						onclick="showHide('collevent',1)">Show More Options</span>
			</td>
		</tr>
		<tr>
			<td class="lbl">
				<select name="coll_role" id="coll_role" size="1">
					<option value="" selected="selected">Collector</option>
					<option value="p">Preparator</option>
				</select>
			</td>
			<td class="srch">
                   <p class="topspace">&nbsp;</p>
				<input type="text" name="coll" id="coll" size="50"> <span class="hints">(include&nbsp;known&nbsp;accent&nbsp;marks&nbsp;for&nbsp;optimal&nbsp;results)</span>
			</td>
		</tr>
		<tr>
			<td class="lbl">
				<span id="year_collected">Years Collected:</span>
			</td>
			<td class="srch">
				<input name="begYear" type="text" size="13"><span class="copylink" onclick="SpecData.endYear.value=SpecData.begYear.value"> -->&nbsp;Copy&nbsp;--></span>
                &nbsp;<input name="endYear" type="text" size="13"><br><span class="hints"> (add trip duration or copy date to both fields for one year)</span>
			</td>
		</tr>
	</table>
	<div id="e_collevent">

        <script type="text/javascript">
        	jQuery(document).ready(function() {
        		$("##begDate").datepicker();
        		$("##endDate").datepicker();
        	});
        </script>
        <cfquery name="ctcollecting_source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        	select collecting_source from ctcollecting_source
        </cfquery>
        <table id="t_identifiers" class="ssrch">
        	<tr>
        		<td class="lbl">
        			<span id="year_collected">Collected On or After:</span>
        		</td>
        		<td class="srch">
        			<table>
        				<tr>
        					<td>
        						<label for="begYear">Year</label>
        						<input name="begYear" id="begYear" type="text" size="4">
        					</td>
        					<td>
        						<label for="begMon">Month</label>
        						<select name="begMon" id="begMon" size="1">
        							<option value=""></option>
        							<option value="01">January</option>
        							<option value="02">February</option>
        							<option value="03">March</option>
        							<option value="04">April</option>
        							<option value="05">May</option>
        							<option value="06">June</option>
        							<option value="07">July</option>
        							<option value="08">August</option>
        							<option value="09">September</option>
        							<option value="10">October</option>
        							<option value="11">November</option>
        							<option value="12">December</option>
        						</select>
        					</td>
        					<td>
        						<label for="begDay">Day</label>
        						<select name="begDay" id="begDay" size="1">
        							<option value=""></option>
        							<cfloop from="1" to="31" index="day">
        								<option value="#day#">#day#</option>
        							</cfloop>
        						</select>
        					</td>
        					<td valign="bottom"><span style="font-size:small;font-style:italic;font-weight:bold;">OR</span></td>
        					<td>
        						<label for="begDate">ISO8601 Date/Time</label>
        						<input name="begDate" id="begDate" size="13" type="text">
        					</td>
        				</tr>
        			</table>
        		</td>
        	</tr>
        	<tr>
        		<td class="lbl">
        			<span id="year_collected">Collected On or Before:</span>
        		</td>
        		<td class="srch">
        			<table>
        				<tr>
        					<td>
        						<label for="endYear">Year</label>
        						<input name="endYear" id="endYear" type="text" size="4">
        					</td>
        					<td>
        						<label for="endMon">Month</label>
        						<select name="endMon" id="endMon" size="1">
        							<option value=""></option>
        							<option value="01">January</option>
        							<option value="02">February</option>
        							<option value="03">March</option>
        							<option value="04">April</option>
        							<option value="05">May</option>
        							<option value="06">June</option>
        							<option value="07">July</option>
        							<option value="08">August</option>
        							<option value="09">September</option>
        							<option value="10">October</option>
        							<option value="11">November</option>
        							<option value="12">December</option>
        						</select>
        					</td>
        					<td>
        						<label for="endDay">Day</label>
        						<select name="endDay" id="endDay" size="1">
        							<option value=""></option>
        							<cfloop from="1" to="31" index="day">
        								<option value="#day#">#day#</option>
        							</cfloop>
        						</select>
        					</td>
        					<td valign="bottom"><span style="font-size:small;font-style:italic;font-weight:bold;">OR</span></td>
        					<td>
        						<label for="endDate">ISO8601 Date/Time</label>
        						<input name="endDate" id="endDate" size="10" type="text">
        					</td>
        				</tr>
        			</table>
        			<span style="font-size:x-small;">(Leave blank to use Collected After values)</span>
        		</td>
        	</tr>
        	<tr>
        		<td class="lbl">
        			<span id="month_in">Month:</span>
        		</td>
        		<td class="srch">
        			<select name="inMon" id="inMon" size="4" multiple>
        				<option value=""></option>
        				<option value="'01'">January</option>
        				<option value="'02'">February</option>
        				<option value="'03'">March</option>
        				<option value="'04'">April</option>
        				<option value="'05'">May</option>
        				<option value="'06'">June</option>
        				<option value="'07'">July</option>
        				<option value="'08'">August</option>
        				<option value="'09'">September</option>
        				<option value="'10'">October</option>
        				<option value="'11'">November</option>
        				<option value="'12'">December</option>
        			</select>
        		</td>
        	</tr>
        	<!---
        	<tr>
        		<td class="lbl">
        			<span id="incl_date">Strict Date Search?</span>
        		</td>
        		<td class="srch">
        			<input type="checkbox" name="inclDateSearch" id="inclDateSearch" value="yes">
        		</td>
        	</tr>
        	----->
        	<tr>
        		<td class="lbl">
        			<span id="_verbatim_date">Verbatim Date:</span>
        		</td>
        		<td class="srch">
        			<input type="text" name="verbatim_date" id="verbatim_date" size="50">
        		</td>
        	</tr>
        	<tr>
        		<td class="lbl">
        			<span id="_chronological_extent">Chronological Extent:</span>
        			</a>
        		</td>
        		<td class="srch">
        			<input type="text" name="chronological_extent" id="chronological_extent">
        		</td>
        	</tr>
        	<tr>
        		<td class="lbl">
        			<span id="_collecting_source">Collecting Source:</span>
        		</td>
        		<td class="srch">
        			<select name="collecting_source" id="collecting_source" size="1">
        				<option value=""></option>
        				<cfloop query="ctcollecting_source">
        					<option value="#ctcollecting_source.collecting_source#">
        						#ctcollecting_source.collecting_source#</option>
        				</cfloop>
        			</select>
        		</td>
        	</tr>
        	<tr>
        		<td class="lbl">
        			<span id="_verbatim_locality">Verbatim Locality:</span>
        		</td>
        		<td class="srch">
        			<input type="text" name="verbatim_locality" id="verbatim_locality" size="50">
        			<span class="infoLink" onclick="var e=document.getElementById('verbatim_locality');e.value='='+e.value;">Add = for exact match</span>
        		</td>
        	</tr>
        </table>
    </div>
</div>
<cfquery name="Part" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select part_name from
		<cfif len(#session.exclusive_collection_id#) gt 0>
			cctspecimen_part_name#session.exclusive_collection_id#
		<cfelse>
			ctspecimen_part_name
		</cfif>
	group by part_name order by part_name
</cfquery>
<cfset partlist=#valuelist(Part.part_name,"\")#>
<cfquery name="PreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select preserve_method from
		<cfif len(#session.exclusive_collection_id#) gt 0>
			cctspecimen_preserv_method#session.exclusive_collection_id#
		<cfelse>
			ctspecimen_preserv_method
		</cfif>
	group by preserve_method order by preserve_method
</cfquery>
<cfset presmethlist=#valuelist(PreserveMethod.preserve_method,"\")#>
<div class="secDiv">
	<table class="ssrch">
		<tr>
			<td colspan="2" class="secHead">
					<span class="secLabel">Biological Individual</span>
					<span class="secControl" id="c_biolindiv"
						onclick="showHide('biolindiv',1)">Show More Options</span>
			</td>
		</tr>
		<tr>
			<td class="lbl">
              <span id="part_name">Part Name:</span>
			</td>
			<td class="srch">
              <p class="topspace">&nbsp;</p>
				<input type="text" autosuggest="#partlist#" id="partname" name="partname" delimiter="\">
				<span class="infolink" onclick="getCtDoc('ctspecimen_part_name',SpecData.partname.value);">Define</span>
				<span class="infolink" onclick="var e=document.getElementById('partname');e.value='='+e.value;">Add = for exact match</span>
			</td>
		</tr>
		<tr>
			<td class="lbl">
				Preserve Method:
			</td>
			<td class="srch">
				<input type="text" autosuggest="#presmethlist#" id="preservemethod" name="preservemethod" delimiter="\">
				<span class="infolink" onclick="getCtDoc('ctspecimen_preserv_method',SpecData.preservemethod.value);">Define</span>
				<span class="infolink" onclick="var e=document.getElementById('preservemethod');e.value='='+e.value;">Add = for exact match</span>
			</td>
		</tr>
	</table>
	<div id="e_biolindiv">


          <cfquery name="ctbiol_relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
          	select biol_indiv_relationship  from ctbiol_relations
          </cfquery>
          <cfif isdefined("session.portal_id") and session.portal_id gt 0>
          	<cftry>
          		<cfquery name="ctAttributeType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
          			select distinct(attribute_type) from cctattribute_type#session.portal_id# order by attribute_type
          		</cfquery>
          		<cfcatch>
          			<cfquery name="ctAttributeType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
          				select distinct(attribute_type) from ctattribute_type order by attribute_type
          			</cfquery>
          		</cfcatch>
          	</cftry>
          <cfelse>
          	<cfquery name="ctAttributeType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
          		select distinct(attribute_type) from ctattribute_type order by attribute_type
          	</cfquery>
          </cfif>
          <table id="t_identifiers" class="ssrch">
          	<tr>
          		<td class="lbl">
          			<span id="biol_indiv_relationship">Relationship:</span>
          		</td>
          		<td class="srch">
          			<select name="relationship" id="relationship" size="1">
          				<option value=""></option>
          				<cfloop query="ctbiol_relations">
          					<option value="#ctbiol_relations.biol_indiv_relationship#">
          						#ctbiol_relations.biol_indiv_relationship#</option>
          				</cfloop>
          			</select>
          		</td>
          	</tr>
          	<tr>
          		<td class="lbl">
          			<span id="_derived_relationship">Derived Relationship:</span>
          		</td>
          		<td class="srch">
          			<select name="derived_relationship" id="derived_relationship" size="1">
          				<option value=""></option>
          					<option value="offspring of">offspring of</option>
          			</select>
          		</td>
          	</tr>
          	<tr>
          		<td class="lbl">
          			<span class="helpLink infoLink" id="attribute_type">Help</span>
          			<select name="attribute_type_1" id="attribute_type_1" size="1">
          				<option selected value="">[ pick an attribute ]</option>
          					<cfloop query="ctAttributeType">
          						<option value="#ctAttributeType.attribute_type#">#ctAttributeType.attribute_type#</option>
          					</cfloop>
          			  </select>
          		</td>
          		<td class="srch">
          			<select name="attOper_1" id="attOper_1" size="1">
          				<option selected value="">equals</option>
          				<option value="like">contains</option>
          				<option value="greater">greater than</option>
          				<option value="less">less than</option>
          			</select>
          			<input type="text" name="attribute_value_1" size="20">
          			<span class="infoLink"
          				onclick="windowOpener('/info/attributeHelpPick.cfm?attNum=1&attribute='+SpecData.attribute_type_1.value,'attPick','width=600,height=600, resizable,scrollbars');">
          				Pick
          			</span>
          			<input type="text" name="attribute_units_1" size="6">(units)
          		</td>
          	</tr>
          	<tr>
          		<td class="lbl">
          			<span class="helpLink infoLink" id="attribute_type">Help</span>
          			<select name="attribute_type_2" id="attribute_type_2" size="1">
          				<option selected value="">[ pick an attribute ]</option>
          					<cfloop query="ctAttributeType">
          						<option value="#ctAttributeType.attribute_type#">#ctAttributeType.attribute_type#</option>
          					</cfloop>
          			  </select>
          		</td>
          		<td class="srch">
          			<select name="attOper_2" id="attOper_2" size="1">
          				<option selected value="">equals</option>
          				<option value="like">contains</option>
          				<option value="greater">greater than</option>
          				<option value="less">less than</option>
          			</select>
          			<input type="text" name="attribute_value_2" size="20">
          			<span class="infoLink"
          				onclick="windowOpener('/info/attributeHelpPick.cfm?attNum=1&attribute='+SpecData.attribute_type_1.value,'attPick','width=600,height=600, resizable,scrollbars');">
          				Pick
          			</span>
          			<input type="text" name="attribute_units_2" size="6">(units)
          		</td>
          	</tr>
          	<tr>
          		<td class="lbl">
          			<span class="helpLink infoLink" id="attribute_type">Help</span>
          			<select name="attribute_type_3" id="attribute_type_3" size="1">
          				<option selected value="">[ pick an attribute ]</option>
          					<cfloop query="ctAttributeType">
          						<option value="#ctAttributeType.attribute_type#">#ctAttributeType.attribute_type#</option>
          					</cfloop>
          			  </select>
          		</td>
          		<td class="srch">
          			<select name="attOper_3" id="attOper_3" size="1">
          				<option selected value="">equals</option>
          				<option value="like">contains</option>
          				<option value="greater">greater than</option>
          				<option value="less">less than</option>
          			</select>
          			<input type="text" name="attribute_value_3" size="20">
          			<span class="infoLink"
          				onclick="windowOpener('/info/attributeHelpPick.cfm?attNum=1&attribute='+SpecData.attribute_type_1.value,'attPick','width=600,height=600, resizable,scrollbars');">
          				Pick
          			</span>
          			<input type="text" name="attribute_units_3" size="6">(units)
          		</td>
          	</tr>
          	<tr>
          		<td class="lbl">
          			<span id="ocr_text">OCR Text:</span>
          		</td>
          		<td class="srch">
          			<input name="ocr_text" id="ocr_text" size="80">
          		</td>
          	</tr>
          </table>


    </div>
</div>
<div class="secDiv">
	<table class="ssrch">
		<tr>
			<td colspan="2" class="secHead">
					<span class="secLabel">Usage</span>
					<span class="secControl" id="c_usage"
						onclick="showHide('usage',1)">Show More Options</span>
			</td>
		</tr>
		<tr>
			<td class="lbl">
				<span id="_type_status">Basis of Citation:</span>
			</td>
			<td class="srch">
              <p class="topspace">&nbsp;</p>
				<cfquery name="ctTypeStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select type_status from ctcitation_type_status
				</cfquery>
				<select name="type_status" id="type_status" size="1">
					<option value=""></option>
					<option value="any">Any</option>
					<option value="any type">Any TYPE</option>
					<cfloop query="ctTypeStatus">
						<option value="#ctTypeStatus.type_status#">#ctTypeStatus.type_status#</option>
					</cfloop>
				</select>
				<span class="infoLink" onclick="getCtDoc('ctcitation_type_status', SpecData.type_status.value);">Define</span>
			</td>
		</tr>
	</table>
	<div id="e_usage">
         <cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">

         	select media_type from ctmedia_type order by media_type
         </cfquery>
         <script type="text/javascript" language="javascript">
         	jQuery(document).ready(function() {
         		jQuery("##project_name").autocomplete("/ajax/project.cfm", {
         			width: 320,
         			max: 50,
         			autofill: false,
         			multiple: false,
         			scroll: true,
         			scrollHeight: 300,
         			matchContains: true,
         			minChars: 1,
         			selectFirst:false
         		});
         		jQuery("##loan_project_name").autocomplete("/ajax/project.cfm", {
         			width: 320,
         			max: 50,
         			autofill: false,
         			multiple: false,
         			scroll: true,
         			scrollHeight: 300,
         			matchContains: true,
         			minChars: 1,
         			selectFirst:false
         		});
         	});
         </script>
         <table id="t_identifiers" class="ssrch">
         	<tr>
                 <td class="lbl">
                     <span id="_media_type">Media Type:</span>
                 </td>
                 <td class="srch">
         			<select name="media_type" id="media_type" size="1">
         				<option value=""></option>
                         <option value="any">Any</option>
         				<cfloop query="ctmedia_type">
         					<option value="#ctmedia_type.media_type#">#ctmedia_type.media_type#</option>
         				</cfloop>
         			</select>
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="accessioned_by_project">Contributed by Project:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="project_name" id="project_name" size="50">
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="loaned_to_project">Used by Project:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="loan_project_name" id="loan_project_name" size="50">
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="_project_sponsor">Project Sponsor:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="project_sponsor" id="project_sponsor" size="50">
         		</td>
         	</tr>
         </table>
    </div>
</div>
<cfif listcontainsnocase(session.roles,"coldfusion_user")>
	<div class="secDiv">
		<table class="ssrch">
			<tr>
				<td colspan="2" class="secHead">
						<span class="secLabel">Curatorial</span>
						<span class="secControl" id="c_curatorial"
							onclick="showHide('curatorial',1)">Show More Options</span>
				</td>
			</tr>
			<tr>
				<td class="lbl">
                  <span id="srch_barcode">Barcode:</span>
				</td>
				<td class="srch">
                  <p class="topspace">&nbsp;</p>
					<input type="text" name="barcode" id="barcode" size="50">
				</td>
			</tr>
		</table>
		<div id="e_curatorial">

         <script type="text/javascript">
         	jQuery(document).ready(function() {
         		$("##beg_entered_date").datepicker();
         		$("##end_entered_date").datepicker();
         		$("##beg_last_edit_date").datepicker();
         		$("##end_last_edit_date").datepicker();
         	});
         </script>
         <cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
         	select * from ctpermit_type
         </cfquery>
         <cfquery name="ctCollObjDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
         	select coll_obj_disposition from ctcoll_obj_disp
         </cfquery>
         <cfquery name="ctFlags" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
         	select flags from ctflags
         </cfquery>
         <cfif listcontainsnocase(session.roles,"manage_specimens")>
				<!--- NOTE: if widened beyond manage_specimens to public, include the mask_fg = 0 in the query. --->
	         <cfquery name="namedCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
   	      	select underscore_collection_id, collection_name from underscore_collection
					order by collection_name
         	</cfquery>
			</cfif>
         <table id="t_identifiers" class="ssrch">
         	<tr>
         		<td class="lbl">
         			<span id="loan_number">Loan Number:</span>
         		</td>
         		<td class="srch">
         			<input name="loan_number" id="loan_number" type="text" size="50">
         			<span class="infoLink" onclick="var e=document.getElementById('loan_number');e.value='='+e.value;">Add = for exact match</span>
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="permit_issued_by">Permit Issued By:</span>
         		</td>
         		<td class="srch">
         			<input name="permit_issued_by" id="permit_issued_by" type="text" size="50">
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="permit_issued_to">Permit Issued To:</span>
         		</td>
         		<td class="srch">
         			<input name="permit_issued_to" id="permit_issued_to" type="text" size="50">
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="permit_type">Permit Type:</span>
         		</td>
         		<td class="srch">
         			<select name="permit_type" id="permit_type" size="1">
         				<option value=""></option>
         				<cfloop query="ctPermitType">
         					<option value = "#ctPermitType.permit_type#">#ctPermitType.permit_type#</option>
         				 </cfloop>
           			</select>
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="permit_number">Permit Number:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="permit_num" id="permit_num" size="50">
         			<span class="infoLink" onclick="getHelp('get_permit_number');">Pick</span>
         		</td>
         	</tr>
         	<cfif listcontainsnocase(session.roles,"manage_specimens")>
	         	<tr>
   	      		<td class="lbl">
      	   			<span id="named_group_label">Named Group:</span>
         			</td>
						<td class="srch">
      	   			<select name="underscore_coll_id" id="underscore_coll_id" size="1">
	         				<option value=""></option>
   	      				<cfloop query="namedCollections">
      	   					<option value = "#namedCollections.underscore_collection_id#">#namedCollections.collection_name#</option>
         					 </cfloop>
   	      				<cfloop query="namedCollections">
      	   					<option value = "!#namedCollections.underscore_collection_id#">!#namedCollections.collection_name#</option>
         					 </cfloop>
           				</select>
         			</td>
         		</tr>
				</cfif>
         	<tr>
         		<td class="lbl">
         			<span id="disposition">Part Disposition:</span>
         		</td>
         		<td class="srch">
         			<select name="part_disposition" id="part_disposition" size="1">
         				<option value=""></option>
         				<cfloop query="ctCollObjDisp">
         					<option value="#ctCollObjDisp.coll_obj_disposition#">#ctCollObjDisp.coll_obj_disposition#</option>
         				</cfloop>
         			</select>
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="print_flag">Print Flag:</span>
         		</td>
         		<td class="srch">
         			<select name="print_fg" id="print_fg" size="1">
         				<option value=""></option>
         				<option value="1">Box</option>
         				<option value="2">Vial</option>
         			</select>
         		</td>
         	</tr>
             	<tr>
         		<td class="lbl">
         			<span id="entered_by">Entered By:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="entered_by" id="entered_by" size="50">
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="entered_date">Entered Date:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="beg_entered_date" id="beg_entered_date" size="10" />-
         			<input type="text" name="end_entered_date" id="end_entered_date" size="10" />
         		</td>
         	</tr>
             	<tr>
         		<td class="lbl">
         			<span id="edited_by">Last Edited By:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="edited_by" id="edited_by" size="50">
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="last_edit_date">Last Edited Date:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="beg_last_edit_date" id="beg_last_edit_date" size="10">-
         			<input type="text" name="end_last_edit_date" id="end_last_edit_date" size="10">
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="coll_object_remarks">Remarks:</span>
         		</td>
         		<td class="srch">
         			<input type="text" name="remark" id="remark" size="50" />
         		</td>
         	</tr>
         	<tr>
         		<td class="lbl">
         			<span id="flags">Missing (flags):</span>
         		</td>
         		<td class="srch">
         			<select name="coll_obj_flags" id="coll_obj_flags" size="1">
         				<option value=""></option>
         				<cfloop query="ctFlags">
         					<option value="#flags#">#flags#</option>
         				</cfloop>
         			</select>
         		</td>
         	</tr>
         </table>

        </div>
	</div>
</cfif>
<table style="margin: 1em 0;">
	<tr>
		<td valign="top" style="padding: 0 5px 0 0;">
			<input type="submit" value="Search" class="schBtn"
			onmouseover="this.className='schBtn btnhov'" onmouseout="this.className='schBtn'">
		</td>
		<td valign="top" style="padding: 0 5px;">
			<input type="reset" name="Reset" value="Clear Form" class="clrBtn" >

		</td>
		<td valign="top" style="padding: 0 5px;">
			<input type="button" name="Previous" value="Use Last Values" class="lnkBtn"	onclick="setPrevSearch()">
		</td>
		<td valign="top" align="right" style="padding: 0 5px;">
			<b>See results as:</b>
		</td>
		<td align="left" colspan="2" valign="top">
			<select name="tgtForm" id="tgtForm" size="1" onChange="changeTarget(this.id,this.value);">
				<option value="">Specimen Records</option>
				<option value="SpecimenResultsHTML.cfm">HTML Specimen Records</option>
				<option  value="/bnhmMaps/bnhmMapData.cfm">BerkeleyMapper Map</option>
				<option  value="/bnhmMaps/kml.cfm?action=newReq">KML</option>
				<option value="SpecimenResultsSummary.cfm">Specimen Summary</option>
				<option  value="SpecimenGraph.cfm">Graph</option>
			</select>
		</td>
		<td align="left">
			<div id="groupByDiv" style="display:none;border:1px solid green;padding:.5em;">
			<font size="-1"><em><strong>Group by:</strong></em></font><br>
			<select name="groupBy" id="groupBy" multiple size="4" onchange="changeGrp(this.id)">
				<option value="">Scientific Name</option>
				<option value="continent_ocean">Continent</option>
				<option value="country">Country</option>
				<option value="state_prov">State</option>
				<option value="county">County</option>
				<option value="quad">Map Name</option>
				<option value="feature">Land Feature</option>
				<option value="water_feature">Water Feature</option>
				<option value="island">Island</option>
				<option value="island_group">Island Group</option>
				<option value="sea">Sea</option>
				<option value="spec_locality">Specific Locality</option>
				<option value="yr">Year</option>
			</select>
			</div>
			<div id="kmlDiv" style="display:none;border:1px solid green;padding:.5em;">
				<font size="-1"><em><strong>KML Options:</strong></em></font><br>
				<label for="next">Color By</label>
				<select name="next" id="next" onchange="kmlSync(this.id,this.value)">
					<option value="colorByCollection">Collection</option>
					<option value="colorBySpecies">Species</option>
				</select>
				<label for="method">Method</label>
				<select name="method" id="method" onchange="kmlSync(this.id,this.value)">
					<option value="download">Download</option>
					<option value="link">Download Linkfile</option>
					<option value="gmap">Google Maps</option>
				</select>
				<label for="includeTimeSpan">include Time?</label>
				<select name="includeTimeSpan" id="includeTimeSpan" onchange="kmlSync(this.id,this.value)">
					<option value="0">no</option>
					<option value="1">yes</option>
				</select>
				<label for="showUnaccepted">Show unaccepted determinations?</label>
				<select name="showUnaccepted" id="showUnaccepted" onchange="kmlSync(this.id,this.value)">
					<option value="0">no</option>
					<option value="1">yes</option>
				</select>
				<label for="mapByLocality">All specimens from localities?</label>
				<select name="mapByLocality" id="mapByLocality" onchange="kmlSync(this.id,this.value)">
					<option value="0">no</option>
					<option value="1">yes</option>
				</select>
				<label for="showErrors">Show error radii?</label>
				<select name="showErrors" id="showErrors" onchange="kmlSync(this.id,this.value)">
					<option value="0">no</option>
					<option value="1">yes</option>
				</select>
			</div>
		</td>
	</tr>
</table>
<cfif isdefined("transaction_id") and len(transaction_id) gt 0>
	<input type="hidden" name="transaction_id" value="#transaction_id#">
</cfif>
<input type="hidden" name="newQuery" value="1"><!--- pass this to the next form so we clear the cache and run the proper queries--->
</form>
<script>
$(function() {
    //  bind a function to the form to handle submission of just the non-empty inputs.
    $("##SpecData").submit(function(e) {
        e.preventDefault();  // we want to disable empty form elements for post, then reinable them after form submission.
        // however, we don't want to submit values in form elements that are hidden
        $(this).find(':hidden :input').filter(function(){ return this.value;}).val("");  // empty hidden form inputs
        $(this).find(':input').filter(function(){ return !this.value;}).attr("disabled", "disabled");  // don't post visible empty form elements
        <cfif !listcontainsnocase(session.roles,"coldfusion_user")>
        // store the current open/closed blocks for non-logged in users.
        createCookie("specsrchprefs",getCurrentSpecSrchPref(),0);
        </cfif>
        getFormValues();  //  puts the form submission key value pairs in a cookie
        this.submit();       // do the actual form submission
        $(this).find(':input').filter(function(){ return !this.value;}).removeAttr("disabled");  // reinable in case user hits back button.
    });
});
</script>
<script type='text/javascript' language='javascript'>
	jQuery(document).ready(function() {

	  	var tval = document.getElementById('tgtForm').value;
		changeTarget('tgtForm',tval);
		changeGrp('groupBy');
                setupSpecSrchPref();
                // set all show fewer/
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "getSpecSrchPref",
				returnformat : "json",
				queryformat : 'column'
			},
			function (getResult) {
				if (getResult == "cookie") {
					var cookie = readCookie("specsrchprefs");
					if (cookie != null) {
						r_getSpecSrchPref(cookie);
					}
				}
				else
					r_getSpecSrchPref(getResult);
			}
		);
                $("##c_save_showhide").click(function(e) {
                     $("##c_save_showhide_response").html('<img src="images/indicator.gif">');
                     var onList = getCurrentSpecSrchPref();
		     jQuery.get("/component/functions.cfc",
			{
				method : "saveSpecSrchPrefs",
                                onList : onList,
				returnformat : "plain",
				queryformat : 'column'
			},
			function (result) {
                           $("##c_save_showhide_response").text(result);
                           setTimeout("$('##c_save_showhide_response').text('');",3000);
                        }
                     );
                });
	});
	jQuery("##partname").autocomplete("/ajax/part_name.cfm", {
		width: 320,
		max: 50,
		autofill: false,
		multiple: false,
		scroll: true,
		scrollHeight: 300,
		matchContains: true,
		minChars: 1,
		selectFirst:false
	});

        function setupSpecSrchPref() {
                // Set all show fewer/more options to show fewer.
                showHide('identifiers',0);
                showHide('taxonomy',0);
                showHide('locality',0);
                showHide('collevent',0);
                showHide('biolindiv',0);
                showHide('usage',0);
                showHide('curatorial',0);
        }
        function getCurrentSpecSrchPref() {
                // Obtain a comma separated list of the currently turned on show fewer/more specimen search option blocks.
                var onList = "";
                if ($("##e_identifiers").is(':visible')) { onList = onList + "identifiers,";  }
                if ($("##e_taxonomy").is(':visible')) { onList = onList + "taxonomy,";  }
                if ($("##e_locality").is(':visible')) { onList = onList + "locality,";  }
                if ($("##e_collevent").is(':visible')) { onList = onList + "collevent,";  }
                if ($("##e_biolindiv").is(':visible')) { onList = onList + "biolindiv,";  }
                if ($("##e_usage").is(':visible')) { onList = onList + "usage,";  }
                if ($("##e_curatorial").is(':visible')) { onList = onList + "curatorial,";  }
                onList = onList.replace(/,$/,'');
                return onList;
        }
	function r_getSpecSrchPref (result){
		var j=result.split(',');
		for (var i = 0; i < j.length; i++) {
			if (j[i].length>0){
				showHide(j[i],1);
			}
		}
	}
	function kmlSync(tid,tval) {
		var rMostChar=tid.substr(tid.length -1,1);
		if (rMostChar=='1'){
			theOtherField=tid.substr(0,tid.length -1);
		} else {
			theOtherField=tid + '1';
		}
		document.getElementById(theOtherField).value=tval;
	}
	function changeGrp(tid) {
		if (tid == 'groupBy') {
			var oid = 'groupBy1';
		} else {
			var oid = 'groupBy';
		}
		var mList = document.getElementById(tid);
		var sList = document.getElementById(oid);
		var len = mList.length;
		for (i = 0; i < len; i++) {
			sList.options[i].selected = false;
		}
		for (i = 0; i < len; i++) {
			if (mList.options[i].selected) {
				sList.options[i].selected = true;
			}
		}
	}
	function changeTarget(id,tvalue) {
		if(tvalue.length == 0) {
			tvalue='SpecimenResults.cfm';
		}
		if (id =='tgtForm1') {
			var otherForm = document.getElementById('tgtForm');
		} else {
			var otherForm = document.getElementById('tgtForm1');
		}
		otherForm.value=tvalue;
		document.getElementById('groupByDiv').style.display='none';
		document.getElementById('groupByDiv1').style.display='none';
		document.getElementById('kmlDiv').style.display='none';
		document.getElementById('kmlDiv1').style.display='none';
		if (tvalue == 'SpecimenResultsSummary.cfm') {
			document.getElementById('groupByDiv').style.display='';
			document.getElementById('groupByDiv1').style.display='';
		} else if (tvalue=='/bnhmMaps/kml.cfm?action=newReq') {
			document.getElementById('kmlDiv').style.display='';
			document.getElementById('kmlDiv1').style.display='';
		}
		document.SpecData.action = tvalue;
	}
	function setPrevSearch(){
		var schParam=get_cookie ('schParams');
		var pAry=schParam.split("|");
	 	for (var i=0; i<pAry.length; i++) {
	 		var eAry=pAry[i].split("::");
	 		var eName=eAry[0];
	 		var eVl=eAry[1];
	 		if (document.getElementById(eName)){
				document.getElementById(eName).value=eVl;
				if (eName=='tgtForm' && (eVl=='/bnhmMaps/kml.cfm?action=newReq' || eVl=='SpecimenResultsSummary.cfm')) {
					changeTarget(eName,eVl);
				}
			}
	 	}
	}
</script>
</div>
</cfoutput>
<cfinclude template = "includes/_footer.cfm">
