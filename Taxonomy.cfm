<cfinclude template="includes/_header.cfm">
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
	select nomenclatural_code from ctnomenclatural_code order by nomenclatural_code
</cfquery>
<cfquery name="cttaxon_status" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select taxon_status from cttaxon_status order by taxon_status
</cfquery>
<cfquery name="cttaxon_habitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select taxon_habitat from cttaxon_habitat order by taxon_habitat
</cfquery>
<cfquery name="ctguid_type_taxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement
   from ctguid_type 
   where applies_to like '%taxonomy.taxon_id%'
</cfquery>
<cfquery name="ctguid_type_scientificname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement
   from ctguid_type 
   where applies_to like '%taxonomy.scientific_name_id%'
</cfquery>
<cfset title="Edit Taxonomy">
<cfif !isdefined("subgenus_message")>
    <cfset subgenus_message ="">
</cfif>
<style>
	.warning{border:5px solid red;}
</style>
<script>
	window.setInterval(chkTax, 1000);
	function chkTax(){
		if ($("#nomenclatural_code").val()=='unknown'){
			$("#nomenclatural_code").addClass('warning');
		} else {
			$("#nomenclatural_code").removeClass('warning');
		}
		if ($("#kingdom").val()==''){
			$("#kingdom").addClass('warning');
		} else {
			$("#kingdom").removeClass('warning');
		}
	}
</script>
<!------------------------------------------------>
<cfif action is "nothing">
	<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="TaxonomySearch.cfm">
	<cfabort>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "edit">
	<cfset title="Edit Taxonomy">
	<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from taxonomy where taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
	<cfquery name="isSourceAuthorityCurrent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as ct from CTTAXONOMIC_AUTHORITY where source_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#gettaxa.source_authority#">
	</cfquery>
<cfoutput>
<div class="content_box_narrow">
   <h2 class="wikilink" style="margin-left: 0;float:none;">Edit Taxonomy:  <cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")><img src="/images/info_i_2.gif" onClick="getMCZDocs('Edit Taxonomy')" class="likeLink" alt="[ help ]"></cfif>  <em>#getTaxa.scientific_name#</em></h2>
	<h3><a href="/name/#getTaxa.scientific_name#">Detail Page</a></h3>
    <table class="tInput">
	<form name="taxa" method="post" action="Taxonomy.cfm">
    	<input type="hidden" name="taxon_name_id" value="#getTaxa.taxon_name_id#">
        <input type="hidden" name="Action">
		<tr>
			<td>
				<label for="source_authority">
					<span>Source <cfif isSourceAuthorityCurrent.ct eq 0> (#gettaxa.source_authority#) </cfif></span>
				</label>
				<select name="source_authority" id="source_authority" size="1"  class="reqdClr">
                                   <cfif isSourceAuthorityCurrent.ct eq 0>
                                      <option value="" selected="selected"></option>
                                   </cfif>
		             <cfloop query="ctSourceAuth">
		               <option <cfif isSourceAuthorityCurrent.ct eq 1 and gettaxa.source_authority is ctsourceauth.source_authority> selected="selected" </cfif>
							value="#ctSourceAuth.source_authority#">#ctSourceAuth.source_authority#</option>
		             </cfloop>
		        </select>
			</td>
			<td>
				<label for="valid_catalog_term_fg"><span>ValidForCatalog?</span></label>
				<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" size="1" class="reqdClr">
			    	<option <cfif getTaxa.valid_catalog_term_fg is "1"> selected="selected" </cfif> value="1">yes</option>
			        <option <cfif getTaxa.valid_catalog_term_fg is "0"> selected="selected" </cfif> value="0">no</option>
			    </select>
			</td>
		</tr>
      <tr>
			<td>
				<label for="genus">GUID for Taxon (taxonID)</label>
				<cfset pattern = "">
				<cfset placeholder = "">
				<cfset regex = "">
				<cfset replacement = "">
				<select name="taxonid_guid_type" id="taxonid_guid_type" size="1" class="reqdClr">
		          <cfloop query="ctguid_type_taxon">
 							<cfif gettaxa.taxonid_guid_type is ctguid_type_taxon.guid_type >
								<cfset sel="selected='selected'">
								<cfset placeholder = "ctguid_type_taxon.placeholder">
								<cfset pattern = "ctguid_type_taxon.pattern_regex">
								<cfset regex = "ctguid_type_taxon.resolver_regex">
								<cfset replacement = "ctguid_type_taxon.resolver_replacement">
							</cfif>
		         	   <option #sel# value="#ctguid_type_taxon.guid_type#">#ct_guid_type_taxon.guid_type#</option>
		          </cfloop>
				</select>
				<input size="25" name="taxonid" id="taxonid" value="#gettaxa.taxonid#" placeholder="#placeholder#" pattern="#pattern#">
				<cfif len(regex) GT 0 >
					<cfset link = REReplace(gettaxa.taxonid,regex,replacement)>
				<cfelse>
					<cfset link = gettaxa.taxonid>
				</cfif>
				<a id="taxonid_link" href="#link#">Link</a>
				<script>
					$('##taxonid_guid_type').on('change', function () { 
						// On selecting a guid_type, change the pattern.
						getGuidTypeInfo($('##'+taxonid_guid_type).val(), 'taxonid', 'taxonid_link');
					});
					$('##taxonid').on('blur', function () { 
						// On loss of focus for input, validate against the regex, update link
						getGuidTypeInfo($('##'+taxonid_guid_type).val(), 'taxonid', 'taxonid_link');
					}
				</script>
			</td>
			<td>
				<label for="genus">GUID for Nomenclatural Act (scientificNameID)</label>
				<cfset pattern = "">
				<cfset placeholder = "">
				<cfset regex = "">
				<cfset replacement = "">
				<select name="scientificnameid_guid_type" id="scientificnameid_guid_type" size="1" class="reqdClr">
		          <cfloop query="ctguid_type_scientificname">
 							<cfif gettaxa.scientificnameid_guid_type is ctguid_type_scientificname.guid_type >
								<cfset sel="selected='selected'">
								<cfset placeholder = "ctguid_type_scientificname.placeholder">
								<cfset pattern = "ctguid_type_scientificname.pattern_regex">
								<cfset regex = "ctguid_type_scientificname.resolver_regex">
								<cfset replacement = "ctguid_type_scientificname.resolver_replacement">
							</cfif>
		         	   <option #sel# value="#ctguid_type_scientificname.guid_type#">#ct_guid_type_scientificname.guid_type#</option>
		          </cfloop>
				</select>
				<input size="25" name="scientificnameid" id="scientificnameid" value="#gettaxa.scientificnameid#" placeholder="#placeholder#" pattern="#pattern#">
				<cfif len(regex) GT 0 >
					<cfset link = REReplace(gettaxa.scientificnameid,regex,replacement)>
				<cfelse>
					<cfset link = gettaxa.scientificnameid>
				</cfif>
				<a id="scientificnameid_link" href="#link#">Link</a>
				<script>
					$('##scientificnameid_guid_type').on('change', function () { 
						// On selecting a guid_type, change the pattern.
						getGuidTypeInfo($('##'+scientificnameid_guid_type).val(), 'scientificnameid', 'scientificnameid_link');
					});
					$('##scientificnameid').on('blur', function () { 
						// On loss of focus for input, validate against the regex, update link
						getGuidTypeInfo($('##'+scientificnameid_guid_type).val(), 'scientificnameid', 'scientificnameid_link');
					}
				</script>
			</td>
		</tr>
      <tr>
			<td>
				<label for="nomenclatural_code"><span>Nomenclatural Code</span></label>
				<select name="nomenclatural_code" id="nomenclatural_code" size="1" class="reqdClr">
			    	<cfloop query="ctnomenclatural_code">
			        	<option <cfif gettaxa.nomenclatural_code is ctnomenclatural_code.nomenclatural_code> selected="selected" </cfif>
			            	value="#ctnomenclatural_code.nomenclatural_code#">#ctnomenclatural_code.nomenclatural_code#</option>
			        </cfloop>
				</select>
			</td>
			<td>
				<label for="genus">Genus <span class="likeLink" onClick="taxa.genus.value='&##215;' + taxa.genus.value;">Add &##215;</span></label>
				<input size="25" name="genus" id="genus" maxlength="40" value="#gettaxa.genus#">
			</td>
		</tr>
		<tr>
			<td>
				<label for="species">Species <span class="likeLink"
					onClick="taxa.species.value='&##215;' + taxa.species.value;">Add &##215;</span></label>
				<input size="25" name="species" id="species" maxlength="40" value="#gettaxa.species#">
			</td>
			<td>
				<label for="author_text"><span>Author</span></label>
				<input type="text" name="author_text" id="author_text" value="#gettaxa.author_text#" size="30">
				<span class="infoLink"
					onclick="window.open('/picks/KewAbbrPick.cfm?tgt=author_text','picWin','width=700,height=400, resizable,scrollbars')">
					Find Kew Abbr
				</span>
			</td>
		</tr>
		<tr>
			<td>
				<label for="infraspecific_rank"><span>Infraspecific Rank</span></label>
				<select name="infraspecific_rank" id="infraspecific_rank" size="1">
                	<option value=""></option>
	                <cfloop query="ctInfRank">
	                  <option
							<cfif gettaxa.infraspecific_rank is ctinfrank.infraspecific_rank> selected="selected" </cfif>value="#ctInfRank.infraspecific_rank#">#ctInfRank.infraspecific_rank#</option>
	                </cfloop>
              	</select>
			</td>
			<td>
				<label for="taxon_status"><span>Taxon Status</span></label>
				<select name="taxon_status" id="taxon_status" size="1">
			    	<option value=""></option>
			    	<cfloop query="cttaxon_status">
			        	<option <cfif gettaxa.taxon_status is cttaxon_status.taxon_status> selected="selected" </cfif>
			            	value="#cttaxon_status.taxon_status#">#cttaxon_status.taxon_status#</option>
			        </cfloop>
				</select>
				<span class="infoLink" onclick="getCtDoc('cttaxon_status');">Define</span>
			</td>
		</tr>
		<tr>
			<td>
				<label for="subspecies">Subspecies</label>
				<input size="25" name="subspecies" id="subspecies" maxlength="40" value="#gettaxa.subspecies#">
			</td>
			<td>
				<label for="author_text"><span>
					Infraspecific Author (do not use for ICZN names)</span></label>
				<input type="text" name="infraspecific_author" id="infraspecific_author" value="#gettaxa.infraspecific_author#" size="30">
				<span class="infoLink"
					onclick="window.open('/picks/KewAbbrPick.cfm?tgt=infraspecific_author','picWin','width=700,height=400, resizable,scrollbars')">
						Find Kew Abbr
					</span>
			</td>
		</tr>
		<tr>
			<td>
				<label for="kingdom">Kingdom</label>
				<input type="text" name="kingdom" id="kingdom" value="#gettaxa.kingdom#" size="30">
			</td>
			<td>
				&nbsp;
				<!---Deprecated: label for="nomenclatural_code">Nomenclatural Code</label>
				<input type="text" name="nomenclatural_code" id="nomenclatural_code" value="#gettaxa.nomenclatural_code#" size="30"--->
			</td>
		</tr>
		<tr>
			<td>
				<label for="phylum">Phylum</label>
				<input type="text" name="phylum" id="phylum" value="#gettaxa.phylum#" size="30">
			</td>
			<td>
				<label for="subphylum">Subphylum</label>
				<input type="text" name="subphylum" id="subphylum" value="#gettaxa.subphylum#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="division">Division</label>
				<input type="text" name="division" id="division" value="#gettaxa.division#" size="30">
			</td>
			<td>
				<label for="subdivision">SubDivision</label>
				<input type="text" name="subdivision" id="subdivision" value="#gettaxa.subdivision#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="superclass">Superclass</label>
				<input type="text" name="superclass" id="superclass" value="#gettaxa.superclass#" size="30">
			</td>
			<td>
				<label for="phylclass">Class</label>
				<input type="text" name="phylclass" id="phylclass" value="#gettaxa.phylclass#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="subclass">SubClass</label>
				<input type="text" name="subclass" id="subclass" value="#gettaxa.subclass#" size="30">
			</td>
			<td>
				<label for="infraclass">InfraClass</label>
				<input type="text" name="infraclass" id="infraclass" value="#gettaxa.infraclass#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="superorder">Superorder</label>
				<input type="text" name="superorder" id="superorder" value="#gettaxa.superorder#" size="30">
			</td>
			<td>
				<label for="phylorder">Order</label>
				<input type="text" name="phylorder" id="phylorder" value="#gettaxa.phylorder#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="suborder">Suborder</label>
				<input type="text" name="suborder" id="suborder" value="#gettaxa.suborder#" size="30">
			</td>
			<td>
				<label for="infraorder">Infraorder</label>
				<input type="text" name="infraorder" id="infraorder" value="#gettaxa.infraorder#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="superfamily">Superfamily</label>
				<input type="text" name="superfamily" id="superfamily" value="#gettaxa.superfamily#" size="30">
			</td>
			<td>
				<label for="family">Family</label>
				<input type="text" name="family" id="family" value="#gettaxa.family#" size="30">
			</td>

		</tr>
		<tr>
			<td>
				<label for="subfamily">Subfamily</label>
				<input type="text" name="subfamily" id="subfamily" value="#gettaxa.subfamily#" size="30">
			</td>
			<td>
				<label for="tribe">Tribe</label>
				<input type="text" name="tribe" id="tribe" value="#gettaxa.tribe#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="subgenus">Subgenus</label>
				(<input type="text" name="subgenus" id="subgenus" value="#gettaxa.subgenus#" size="29">)#subgenus_message#
			</td>
			<td>
				<label for="subgenus">SubSection</label>
				<input type="text" name="subsection" id="subsection" value="#gettaxa.subsection#" size="29">
			</td>
		</tr>
        <tr>
			<td colspan="2">
				<label for="taxon_remarks">Remarks</label>
				<textarea name="taxon_remarks" id="taxon_remarks" rows="3" cols="60">#gettaxa.taxon_remarks#</textarea>
			</td>
		</tr>
		<tr>
			<td colspan="2">
				<div align="center">
					<input type="button" value="Save" class="savBtn" onclick="taxa.Action.value='saveTaxaEdits';submit();">
              		<input type="button" value="Clone" class="insBtn" onclick="taxa.Action.value='newTaxa';submit();">
   					<input type="button" value="Delete" class="delBtn"	onclick="taxa.Action.value='deleTaxa';confirmDelete('taxa');">
				</div>
			</td>
		</tr>
      </form>
    </table>
	<cfquery name="tax_pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			taxonomy_publication_id,
			formatted_publication,
			taxonomy_publication.publication_id
		from
			taxonomy_publication,
			formatted_publication
		where
			format_style='long' and
			taxonomy_publication.publication_id=formatted_publication.publication_id and
			taxonomy_publication.taxon_name_id=#taxon_name_id#
	</cfquery>
	<cfset i = 1>
	<h4>Related Publications</h4>

		<form name="newPub" method="post" action="Taxonomy.cfm">
			<input type="hidden" name="taxon_name_id" value="#getTaxa.taxon_name_id#">
			<input type="hidden" name="Action" value="newTaxonPub">
			<input type="hidden" name="new_publication_id" id="new_publication_id">
			<label for="new_pub">Pick Publication</label>
			<input type="text" id="newPub" onchange="getPublication(this.id,'new_publication_id',this.value,'newPub')" size="80">
			<input type="submit" value="Add Publication" class="insBtn">
		</form>
		<cfif tax_pub.recordcount gt 0>
			<ul>
		</cfif>
		<cfloop query="tax_pub">
			<li>
				#formatted_publication#
				<ul>
					<li>
						<a href="Taxonomy.cfm?action=removePub&taxonomy_publication_id=#taxonomy_publication_id#&taxon_name_id=#taxon_name_id#">[ remove ]</a>
					</li>
					<li>
						<a href="SpecimenUsage.cfm?publication_id=#publication_id#">[ details ]</a>
					</li>
				</ul>
			</li>
		</cfloop>
		<cfif tax_pub.recordcount gt 0>
			</ul>
		</cfif>
	</table>
	<cfquery name="relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT
			scientific_name,
			taxon_relationship,
			relation_authority,
			related_taxon_name_id
		FROM
			taxon_relations,
			taxonomy
		WHERE
			taxon_relations.related_taxon_name_id = taxonomy.taxon_name_id
			AND taxon_relations.taxon_name_id = #taxon_name_id#
	</cfquery>
	<cfset i = 1>
	<h4>Related Taxa:</h4>
	<table border="1">
		<tr>
			<th>Relationship</th>
			<th>Related Taxa</th>
			<th>Authority</th>
		</tr>
		<form name="newRelation" method="post" action="Taxonomy.cfm">
			<input type="hidden" name="taxon_name_id" value="#getTaxa.taxon_name_id#">
			<input type="hidden" name="Action" value="newTaxaRelation">
			<tr class="newRec">
				<td>
					<label for="taxon_relationship">Add Relationship</label>
					<select name="taxon_relationship" size="1" class="reqdClr">
						<cfloop query="ctRelation">
							<option value="#ctRelation.taxon_relationship#">#ctRelation.taxon_relationship#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<input type="text" name="relatedName" class="reqdClr" size="35"
						onChange="taxaPick('newRelatedId','relatedName','newRelation',this.value); return false;"
						onKeyPress="return noenter(event);">
					<input type="hidden" name="newRelatedId">
				</td>
				<td>
					<input type="text" name="relation_authority">
				</td>
				<td>
					<input type="submit" value="Create" class="insBtn">
	   			</td>
			</tr>
		</form>
		<cfloop query="relations">
			<form name="relation#i#" method="post" action="Taxonomy.cfm">
				<input type="hidden" name="taxon_name_id" value="#getTaxa.taxon_name_id#">
				<input type="hidden" name="Action">
				<input type="hidden" name="related_taxon_name_id" value="#related_taxon_name_id#">
				<input type="hidden" name="origTaxon_Relationship" value="#taxon_relationship#">
				<tr>
					<td>
						<select name="taxon_relationship" size="1" class="reqdClr">
							<cfloop query="ctRelation">
								<option <cfif ctRelation.taxon_relationship is relations.taxon_relationship>
									selected="selected" </cfif>value="#ctRelation.taxon_relationship#">#ctRelation.taxon_relationship#
								</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="text" name="relatedName" class="reqdClr" size="50" value="#relations.scientific_name#"
							onChange="taxaPick('newRelatedId','relatedName','relation#i#',this.value); return false;"
							onKeyPress="return noenter(event);">
						<input type="hidden" name="newRelatedId">
					</td>
					<td>
						<input type="text" name="relation_authority" value="#relations.relation_authority#">
					</td>
					<td>
						<input type="button" value="Save" class="savBtn" onclick="relation#i#.Action.value='saveRelnEdit';submit();">
						<input type="button" value="Delete" class="delBtn" onclick="relation#i#.Action.value='deleReln';confirmDelete('relation#i#');">
					</td>
				</tr>
			</form>
			<cfset i = #i#+1>
		</cfloop>
	</table>
	<cfquery name="common" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select common_name from common_name where taxon_name_id = #taxon_name_id#
	</cfquery>
	<h4>Common Names</h4>
	<cfset i=1>
	<cfloop query="common">
		<form name="common#i#" method="post" action="Taxonomy.cfm">
			<input type="hidden" name="Action">
			<input type="hidden" name="origCommonName" value="#common_name#">
			<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
			<input type="text" name="common_name" value="#common_name#" size="50">
			<input type="button" value="Save" class="savBtn" onClick="common#i#.Action.value='saveCommon';submit();">
	   		<input type="button" value="Delete" class="delBtn" onClick="common#i#.Action.value='deleteCommon';confirmDelete('common#i#');">
		</form>
		<cfset i=i+1>
	</cfloop>
	<table class="newRec">
		<tr>
			<td>
				<form name="newCommon" method="post" action="Taxonomy.cfm">
					<input type="hidden" name="Action" value="newCommon">
					<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
					<label for="common_name">New Common Name</label>
					<input type="text" name="common_name" size="50">
					<input type="submit" value="Create" class="insBtn">
				</form>
			</td>
		</tr>
	</table>
	<cfquery name="habitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select taxon_habitat from taxon_habitat where taxon_name_id = #taxon_name_id#
	</cfquery>

	<cfset usedHabitats = valueList(habitat.taxon_habitat)>

	<h4>Habitat</h4>
	<cfset i=1>
	<cfloop query="habitat">
		<form name="habitat#i#" method="post" action="Taxonomy.cfm">
			<input type="hidden" name="Action">
			<input type="hidden" name="orighabitatName" value="#taxon_habitat#">
			<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
			<input type="text" name="taxon_habitat" value="#taxon_habitat#" size="30" readonly style="background-color: ##dddddd; border: 0">
	   		<input type="button" value="Delete" class="delBtn" onClick="habitat#i#.Action.value='deletehabitat';confirmDelete('habitat#i#');">
		</form>
		<cfset i=i+1>
	</cfloop>
	<table class="newRec">
		<tr>
			<td>
				<form name="newhabitat" method="post" action="Taxonomy.cfm">
					<input type="hidden" name="Action" value="newhabitat">
					<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
					<label for="taxon_habitat">New Habitat</label>
					<select name="taxon_habitat" id="habitat_name"size="1">
					<cfloop query="cttaxon_habitat">
					<option value="">select</option>
			        	<cfif not listcontains(usedHabitats,cttaxon_habitat.taxon_habitat)>
			        	<option value="#cttaxon_habitat.taxon_habitat#">#cttaxon_habitat.taxon_habitat#</option>
			        	</cfif>
			        </cfloop>
					<input type="submit" value="Add" class="insBtn">
				</form>
			</td>
		</tr>
	</table>
    </div>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "removePub">
	<cfquery name="removePub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from taxonomy_publication where taxonomy_publication_id=#taxonomy_publication_id#
	</cfquery>
	<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newTaxonPub">
	<cfquery name="newTaxonPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO taxonomy_publication (taxon_name_id,publication_id)
		VALUES (#taxon_name_id#,#new_publication_id#)
	</cfquery>
	<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newCommon">
<cfoutput>
	<cfquery name="newCommon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO common_name (common_name, taxon_name_id)
		VALUES ('#common_name#', #taxon_name_id#)
	</cfquery>
	<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newHabitat">
<cfoutput>
	<cfquery name="newHabitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO taxon_habitat (taxon_habitat, taxon_name_id)
		VALUES ('#taxon_habitat#', #taxon_name_id#)
	</cfquery>
	<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif Action is "deleTaxa">
<cfoutput>
	<cfquery name="deleTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM
			taxonomy
		WHERE
			taxon_name_id=#taxon_name_id#
	</cfquery>
	You killed it!
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "deleteCommon">
<cfoutput>
	<cfquery name="killCommon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM
			common_name
		WHERE
			common_name='#origCommonName#' AND taxon_name_id=#taxon_name_id#
	</cfquery>
	<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveCommon">
<cfoutput>
	<cfquery name="upCommon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		UPDATE
			common_name
		SET
			common_name = '#common_name#'
		WHERE
			common_name='#origCommonName#' AND taxon_name_id=#taxon_name_id#
	</cfquery>
	<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "deleteHabitat">
<cfoutput>
	<cfquery name="killhabitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM
			taxon_habitat
		WHERE
			taxon_habitat='#orighabitatName#' AND taxon_name_id=#taxon_name_id#
	</cfquery>
	<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "newTaxa">
<cfset title = "Add Taxonomy">
<cfoutput>
<div style="width: 41em; margin:0 auto; padding-bottom: 3em;">
  <h2 class="wikilink" style="margin-left: 0;float:none;">Create New Taxonomy: <img src="/images/info_i_2.gif" border="0" onClick="getMCZDocs('New taxon')" class="likeLink" alt="[ help ]"></h2>
  <p style="padding:2px 0;margin:2px 0;">(through cloning and editing)</p>
	<table class="tInput">
		<form name="taxa" method="post" action="Taxonomy.cfm">
			<input type="hidden" name="Action" value="saveNewTaxa">
			<tr>
				<td>
					<label for="source_authority"><span>Source</span></label>
					<select name="source_authority" id="source_authority" size="1"  class="reqdClr">
		              <cfloop query="ctSourceAuth">
		                <option
							<cfif form.source_authority is ctsourceauth.source_authority> selected="selected" </cfif>
								value="#ctSourceAuth.source_authority#">#ctSourceAuth.source_authority#</option>
		              </cfloop>
		            </select>
				</td>
				<td>
					<label for="valid_catalog_term_fg"><span>Valid?</span></label>
					<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" size="1" class="reqdClr">
		              <option <cfif valid_catalog_term_fg is "1"> selected="selected" </cfif> value="1">yes</option>
		              <option <cfif valid_catalog_term_fg is "0"> selected="selected" </cfif> value="0">no</option>
		            </select>
				</td>
	        </tr>
	        <tr>
				<td>
					<label for="nomenclatural_code"><span>Nomenclatural Code</span></label>
					<select name="nomenclatural_code" id="nomenclatural_code" size="1" class="reqdClr">
		               <cfloop query="ctnomenclatural_code">
		                <option
								<cfif #form.nomenclatural_code# is "#ctnomenclatural_code.nomenclatural_code#"> selected </cfif>value="#ctnomenclatural_code.nomenclatural_code#">#ctnomenclatural_code.nomenclatural_code#</option>
		              </cfloop>
		            </select>
				</td>
				<td>
					<label for="genus">Genus <span class="likeLink"
						onClick="taxa.genus.value='&##215;' + taxa.genus.value;">Add &##215;</span></label>
					<input size="25" name="genus" id="genus" maxlength="40" value="#genus#">
				</td>
			</tr>
	        <tr>
				<td>
					<label for="species">Species <span class="likeLink"
						onClick="taxa.species.value='&##215;' + taxa.species.value;">Add &##215;</span></label>
					<input size="25" name="species" id="species" maxlength="40" value="#species#">
				</td>
				<td>
					<label for="author_text"><span>Author</span></label>
					<input type="text" name="author_text" id="author_text" value="#author_text#" size="30">
					<span class="infoLink"
						onclick="window.open('/picks/KewAbbrPick.cfm?tgt=author_text','picWin','width=700,height=400, resizable,scrollbars')">
							Find Kew Abbr
					</span>
				</td>
			</tr>
			<tr>
				<td>
					<label for="infraspecific_rank"><span>Infraspecific Rank</span></label>
					<select name="infraspecific_rank" id="infraspecific_rank" size="1">
	                	<option <cfif form.infraspecific_rank is ""> selected </cfif>  value=""></option>
		                <cfloop query="ctInfRank">
		                  <option
								<cfif form.infraspecific_rank is ctinfrank.infraspecific_rank> selected="selected" </cfif>value="#ctInfRank.infraspecific_rank#">#ctInfRank.infraspecific_rank#</option>
		                </cfloop>
	              	</select>
				</td>
				<td>
					<label for="taxon_status"><span>Taxon Status</span></label>
					<select name="taxon_status" id="taxon_status" size="1">
				    	<option value=""></option>
				    	<cfloop query="cttaxon_status">
				        	<option <cfif form.taxon_status is cttaxon_status.taxon_status> selected="selected" </cfif>
				            	value="#cttaxon_status.taxon_status#">#cttaxon_status.taxon_status#</option>
				        </cfloop>
					</select>
				</td>
			</tr>
			<tr>
				<td>
					<label for="subspecies">Subspecies</label>
					<input size="25" name="subspecies" id="subspecies" maxlength="40" value="#subspecies#">
				</td>
				<td>
					<label for="author_text"><span>
						Infraspecific Author</span></label>
					<input type="text" name="infraspecific_author" id="infraspecific_author" value="#infraspecific_author#" size="30">
					<span class="infoLink"
						onclick="window.open('/picks/KewAbbrPick.cfm?tgt=infraspecific_author','picWin','width=700,height=400, resizable,scrollbars')">
							Find Kew Abbr
						</span>
				</td>
			</tr>
			<tr>
				<td>
					<label for="kingdom">Kingdom</label>
					<input type="text" name="kingdom" id="kingdom" value="#kingdom#" size="30">
				</td>
			<td>
				&nbsp;
				<!---Deprecated:label for="nomenclatural_code">Nomenclatural Code</label>
				<input type="text" name="nomenclatural_code" id="nomenclatural_code" value="#nomenclatural_code#" size="30"---->
			</td>
		</tr>
		<tr>
			<td>
				<label for="phylum">Phylum</label>
				<input type="text" name="phylum" id="phylum" value="#phylum#" size="30">
			</td>
			<td>
				<label for="subphylum">Subphylum</label>
				<input type="text" name="subphylum" id="subphylum" value="#subphylum#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="division">Division</label>
				<input type="text" name="division" id="division" value="#division#" size="30">
			</td>
			<td>
				<label for="subdivision">SubDivision</label>
				<input type="text" name="subdivision" id="subdivision" value="#subdivision#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="superclass">Superclass</label>
				<input type="text" name="superclass" id="superclass" value="#superclass#" size="30">
			</td>
			<td>
				<label for="phylclass">Class</label>
				<input type="text" name="phylclass" id="phylclass" value="#phylclass#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="subclass">SubClass</label>
				<input type="text" name="subclass" id="subclass" value="#subclass#" size="30">
			</td>
			<td>
				<label for="infraclass">InfraClass</label>
				<input type="text" name="infraclass" id="infraclass" value="#infraclass#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="superorder">Superorder</label>
				<input type="text" name="superorder" id="superorder" value="#superorder#" size="30">
			</td>
			<td>
				<label for="phylorder">Order</label>
				<input type="text" name="phylorder" id="phylorder" value="#phylorder#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="suborder">Suborder</label>
				<input type="text" name="suborder" id="suborder" value="#suborder#" size="30">
			</td>
			<td>
				<label for="infraorder">Infraorder</label>
				<input type="text" name="infraorder" id="infraorder" value="#infraorder#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="superfamily">Superfamily</label>
				<input type="text" name="superfamily" id="superfamily" value="#superfamily#" size="30">
			</td>
			<td>
				<label for="family">Family</label>
				<input type="text" name="family" id="family" value="#family#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="subfamily">Subfamily</label>
				<input type="text" name="subfamily" id="subfamily" value="#subfamily#" size="30">
			</td>
			<td>
				<label for="tribe">Tribe</label>
				<input type="text" name="tribe" id="tribe" value="#tribe#" size="30">
			</td>
		</tr>
		<tr>
			<td>
				<label for="subgenus">Subgenus</label>
				(<input type="text" name="subgenus" id="subgenus" value="#subgenus#" size="29">)#subgenus_message#
			</td>
			<td>
				<label for="subgenus">SubSection</label>
				<input type="text" name="subsection" id="subsection" value="#subsection#" size="29">
			</td>
		</tr>
	        <tr>
				<td colspan="2">
					<label for="taxon_remarks">Remarks</label>
					<textarea name="taxon_remarks" id="taxon_remarks" rows="3" cols="60">#taxon_remarks#</textarea>
				</td>
			</tr>
			<tr>
				<td align="center" colspan="2">
 					<input type="submit" value="Create" class="insBtn">
				</td>
			</tr>
		</form>
	</table>
    </div>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveNewtaxa">
<cfoutput>
<cfquery name="nextID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select sq_taxon_name_id.nextval nextID from dual
</cfquery>
	<cfquery name="newTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO taxonomy (
			taxon_name_id,
			valid_catalog_term_fg,
			source_authority
		<cfif len(#author_text#) gt 0>
			,author_text
		</cfif>
		<cfif len(#tribe#) gt 0>
			,tribe
		</cfif>
		<cfif len(#infraspecific_rank#) gt 0>
			,infraspecific_rank
		</cfif>
		<cfif len(#phylclass#) gt 0>
			,phylclass
		</cfif>
		<cfif len(#phylorder#) gt 0>
			,phylorder
		</cfif>
		<cfif len(#suborder#) gt 0>
			,suborder
		</cfif>
		<cfif len(#family#) gt 0>
			,family
		</cfif>
		<cfif len(#subfamily#) gt 0>
			,subfamily
		</cfif>
		<cfif len(#genus#) gt 0>
			,genus
		</cfif>
		<cfif len(#subgenus#) gt 0>
			,subgenus
		</cfif>
		<cfif len(#species#) gt 0>
			,species
		</cfif>
		<cfif len(#subspecies#) gt 0>
			,subspecies
		</cfif>
		<cfif len(#taxon_remarks#) gt 0>
			,taxon_remarks
		</cfif>
		<cfif len(#phylum#) gt 0>
			,phylum
		</cfif>
		<cfif len(#infraspecific_author#) gt 0>
			,infraspecific_author
		</cfif>
		<cfif len(#kingdom#) gt 0>
			,kingdom
		</cfif>
		<cfif len(#nomenclatural_code#) gt 0>
			,nomenclatural_code
		</cfif>
		<cfif len(#subphylum#) gt 0>
			,subphylum
		</cfif>
		<cfif len(#superclass#) gt 0>
			,superclass
		</cfif>
		<cfif len(#subclass#) gt 0>
			,subclass
		</cfif>
		<cfif len(#superorder#) gt 0>
			,superorder
		</cfif>
		<cfif len(#infraorder#) gt 0>
			,infraorder
		</cfif>
		<cfif len(#superfamily#) gt 0>
			,superfamily
		</cfif>
		<cfif len(#division#) gt 0>
			,division
		</cfif>
		<cfif len(#subdivision#) gt 0>
			,subdivision
		</cfif>
		<cfif len(#subsection#) gt 0>
			,subsection
		</cfif>
		<cfif len(#infraclass#) gt 0>
			,infraclass
		</cfif>
		<cfif len(#taxon_status#) gt 0>
			,taxon_status
		</cfif>
		) VALUES (
			#nextID.nextID#,
			#valid_catalog_term_fg#,
			'#source_authority#'
		<cfif len(#author_text#) gt 0>
			,trim('#escapeQuotes(author_text)#')
		</cfif>
		<cfif len(#tribe#) gt 0>
			,trim('#tribe#')
		</cfif>
		<cfif len(#infraspecific_rank#) gt 0>
			,trim('#infraspecific_rank#')
		</cfif>
		<cfif len(#phylclass#) gt 0>
			,trim('#phylclass#')
		</cfif>
		<cfif len(#phylorder#) gt 0>
			,trim('#phylorder#')
		</cfif>
		<cfif len(#suborder#) gt 0>
			,trim('#suborder#')
		</cfif>
		<cfif len(#family#) gt 0>
			,trim('#family#')
		</cfif>
		<cfif len(#subfamily#) gt 0>
			,trim('#subfamily#')
		</cfif>
		<cfif len(#genus#) gt 0>
			,trim('#genus#')
		</cfif>
		<cfif len(#subgenus#) gt 0>
			,trim('#subgenus#')
		</cfif>
		<cfif len(#species#) gt 0>
			,trim('#species#')
		</cfif>
		<cfif len(#subspecies#) gt 0>
			,trim('#subspecies#')
		</cfif>
		<cfif len(#taxon_remarks#) gt 0>
			,trim('#escapeQuotes(taxon_remarks)#')
		</cfif>
		<cfif len(#phylum#) gt 0>
			,'#phylum#'
		</cfif>
		<cfif len(#infraspecific_author#) gt 0>
			,trim('#escapeQuotes(infraspecific_author)#')
		</cfif>
		<cfif len(#kingdom#) gt 0>
			,trim('#kingdom#')
		</cfif>
		<cfif len(#nomenclatural_code#) gt 0>
			,'#nomenclatural_code#'
		</cfif>
		<cfif len(#subphylum#) gt 0>
			,trim('#subphylum#')
		</cfif>
		<cfif len(#superclass#) gt 0>
			,trim('#superclass#')
		</cfif>
	 	<cfif len(#subclass#) gt 0>
			,trim('#subclass#')
		</cfif>
		<cfif len(#superorder#) gt 0>
			,trim('#superorder#')
		</cfif>
		<cfif len(#infraorder#) gt 0>
			,trim('#infraorder#')
		</cfif>
		<cfif len(#superfamily#) gt 0>
			,trim('#superfamily#')
		</cfif>
		<cfif len(#division#) gt 0>
			,trim('#division#')
		</cfif>
		<cfif len(#subdivision#) gt 0>
			,trim('#subdivision#')
		</cfif>
		<cfif len(#subsection#) gt 0>
			,trim('#subsection#')
		</cfif>
		<cfif len(#infraclass#) gt 0>
			,trim('#infraclass#')
		</cfif>
		<cfif len(#taxon_status#) gt 0>
			,trim('#taxon_status#')
		</cfif>
		)
	</cfquery>
	<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#nextID.nextID#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newTaxaRelation">
<cfoutput>
	<cfquery name="newReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO taxon_relations (
			 TAXON_NAME_ID,
			 RELATED_TAXON_NAME_ID,
			 TAXON_RELATIONSHIP,
			 RELATION_AUTHORITY
		  )	VALUES (
			#TAXON_NAME_ID#,
			 #newRelatedId#,
			 '#TAXON_RELATIONSHIP#',
		 	'#RELATION_AUTHORITY#'
		)
	</cfquery>
	<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif Action is "deleReln">
<cfoutput>
<cfquery name="deleReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	DELETE FROM
		taxon_relations
	WHERE
		taxon_name_id = #taxon_name_id#
		AND Taxon_relationship = '#origtaxon_relationship#'
		AND related_taxon_name_id=#related_taxon_name_id#
		</cfquery>
		<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif #Action# is "saveRelnEdit">
<cfoutput>
<cfquery name="edRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	UPDATE taxon_relations SET
		taxon_relationship = '#taxon_relationship#'
		<cfif len(#newRelatedId#) gt 0>
			,related_taxon_name_id = #newRelatedId#
		<cfelse>
			,related_taxon_name_id = #related_taxon_name_id#
		</cfif>
		<cfif len(#relation_authority#) gt 0>
			,relation_authority = '#relation_authority#'
		<cfelse>
			,relation_authority = null
		</cfif>
	WHERE
		taxon_name_id = #taxon_name_id#
		AND Taxon_relationship = '#origTaxon_relationship#'
		AND related_taxon_name_id=#related_taxon_name_id#
</cfquery>
<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif #Action# is "saveTaxaEdits">
<cfoutput>
       <cfset subgenus_message = "">
        <cfif len(#subgenus#) gt 0 and REFind("^\(.*\)$",#subgenus#) gt 0>
            <cfset subgenus_message = "<strong>Do Not include parethesies</strong>">
            <cfset subgenus = replace(replace(#subgenus#,")",""),"(","") >
        </cfif>
        <cfset hasError = 0 >
        <cfif not isdefined("source_authority") OR len(#source_authority#) is 0>
	    Error: You didn't select a Source. Go back and try again.  
            <cfset hasError = 1 >
        </cfif>
        <cfif hasError eq 0>
        <cftransaction>
	<cfquery name="edTaxa" datasource="user_login" username='#session.username#' password="#decrypt(session.epw,cfid)#">
	UPDATE taxonomy SET
		valid_catalog_term_fg=#valid_catalog_term_fg#,
		source_authority = '#source_authority#'
		<cfif len(#author_text#) gt 0>
			,author_text=trim('#escapeQuotes(author_text)#')
		<cfelse>
			,author_text=null
		</cfif>
		<cfif len(#tribe#) gt 0>
			,tribe = trim('#tribe#')
		<cfelse>
			,tribe = null
		</cfif>
		<cfif len(#infraspecific_rank#) gt 0>
			,infraspecific_rank = '#infraspecific_rank#'
		<cfelse>
			,infraspecific_rank = null
		</cfif>
		<cfif len(#phylclass#) gt 0>
			,phylclass = trim('#phylclass#')
		<cfelse>
			,phylclass = null
		</cfif>
		<cfif len(#phylorder#) gt 0>
			,phylorder = trim('#phylorder#')
		<cfelse>
			,phylorder = null
		</cfif>
		<cfif len(#suborder#) gt 0>
			,suborder = trim('#suborder#')
		<cfelse>
			,suborder = null
		</cfif>
		<cfif len(#family#) gt 0>
			,family = trim('#family#')
		<cfelse>
			,family = null
		</cfif>
		<cfif len(#subfamily#) gt 0>
			,subfamily = trim('#subfamily#')
		<cfelse>
			,subfamily = null
		</cfif>
		<cfif len(#genus#) gt 0>
			,genus = trim('#genus#')
		<cfelse>
			,genus = null
		</cfif>
		<cfif len(#subgenus#) gt 0>
			,subgenus = trim('#subgenus#')
		<cfelse>
			,subgenus = null
		</cfif>
		<cfif len(#species#) gt 0>
			,species = trim('#species#')
		<cfelse>
			,species = null
		</cfif>
		<cfif len(#subspecies#) gt 0>
			,subspecies = trim('#subspecies#')
		<cfelse>
			,subspecies = null
		</cfif>
		<cfif len(#phylum#) gt 0>
			,phylum = trim('#phylum#')
		<cfelse>
			,phylum = null
		</cfif>
		<cfif len(#taxon_remarks#) gt 0>
			,taxon_remarks = trim('#escapeQuotes(taxon_remarks)#')
		<cfelse>
			,taxon_remarks = null
		</cfif>
		<cfif len(#kingdom#) gt 0>
			,kingdom = trim('#kingdom#')
		<cfelse>
			,kingdom = null
		</cfif>
		<cfif len(#nomenclatural_code#) gt 0>
			,nomenclatural_code = '#nomenclatural_code#'
		<cfelse>
			,nomenclatural_code = null
		</cfif>
		<cfif len(#infraspecific_author#) gt 0>
			,infraspecific_author = trim('#escapeQuotes(infraspecific_author)#')
		<cfelse>
			,infraspecific_author = null
		</cfif>
		<cfif len(#subphylum#) gt 0>
			,subphylum = trim('#subphylum#')
		<cfelse>
			,subphylum = null
		</cfif>
		<cfif len(#superclass#) gt 0>
			,superclass = trim('#superclass#')
		<cfelse>
			,superclass = null
		</cfif>
		<cfif len(#subclass#) gt 0>
			,subclass = trim('#subclass#')
		<cfelse>
			,subclass = null
		</cfif>
		<cfif len(#superorder#) gt 0>
			,superorder = trim('#superorder#')
		<cfelse>
			,superorder = null
		</cfif>
		<cfif len(#infraorder#) gt 0>
			,infraorder = trim('#infraorder#')
		<cfelse>
			,infraorder = null
		</cfif>
		<cfif len(#superfamily#) gt 0>
			,superfamily = trim('#superfamily#')
		<cfelse>
			,superfamily = null
		</cfif>
		<cfif len(#division#) gt 0>
			,division = trim('#division#')
		<cfelse>
			,division = null
		</cfif>
		<cfif len(#subdivision#) gt 0>
			,subdivision = trim('#subdivision#')
		<cfelse>
			,subdivision = null
		</cfif>
		<cfif len(#subsection#) gt 0>
			,subsection = trim('#subsection#')
		<cfelse>
			,subsection = null
		</cfif>
		<cfif len(#infraclass#) gt 0>
			,infraclass  = trim('#infraclass#')
		<cfelse>
			,infraclass = null
		</cfif>
		<cfif len(#taxon_status#) gt 0>
			,taxon_status = trim('#taxon_status#')
		<cfelse>
			,taxon_status = null
		</cfif>
	WHERE taxon_name_id=#taxon_name_id#
	</cfquery>
	</cftransaction>
	<cflocation url="Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#&subgenus_message=#subgenus_message#" addtoken="false">
        </cfif>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->

<cfinclude template="includes/_footer.cfm">
