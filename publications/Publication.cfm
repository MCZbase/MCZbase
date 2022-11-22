<!---
/publications/Publication.cfm

Publication editor 

Copyright 2022 President and Fellows of Harvard College
Copyright 2008-2017 Contributors to Arctos

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
<cfif NOT isdefined("action") or len(action) EQ 0>
	<cfset action="edit">
</cfif>
<cfif action EQ "edit">
	<cfif NOT isDefined("publication_id") OR len(publication_id) EQ 0>
		<!--- redirect to publciations search page --->
		<cflocation url="/Publications.cfm" addtoken="false">
	</cfif>
</cfif>
<cfif action EQ "new">
	<cfset pageTitle = "New Publication">
<cfelse>
	<cfset shortCitation = "">
	<cfif isdefined("publication_id") and len(publication_id) GT 0 and isNumeric(publication_id) >
		<!--- lookup the short form of the citation to display in the page title. --->
		<cfquery name="lookupShort" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				formatted_publication as citation
			FROM
				formatted_publication
			WHERE
				publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				and format_style = 'short'
		</cfquery>
		<cfif lookupShort.recordcount EQ 1>
			<cfset shortCitation = ": #lookupShort.citation#">
		</cfif>
	</cfif>
	<cfset pageTitle = "Edit Publication#shortCitation#">
</cfif>
<cfset includeJQXEditor="true">
<cfinclude template="/shared/_header.cfm">

<cfswitch expression="#action#">
<cfcase value="edit">
	<cfinclude template="/publications/component/functions.cfc" runonce="true">
	<!---------------------------------------------------------------------------------------------------------->
	<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select publication_type from ctpublication_type order by publication_type
	</cfquery>

	<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT
			publication_id,
			published_year,
			publication_type,
			publication_loc,
			publication_title,
			publication_remarks,
			is_peer_reviewed_fg,
			doi,
			mczbase.getshortcitation(publication_id) as short_citation, 
			mczbase.getfullcitation(publication_id) as full_citation,
			mczbase.assemblefullcitation(publication_id,0) as full_citation_plain,
			get_publication_attribute(publication_id,'begin page') as spage,
			get_publication_attribute(publication_id,'journal name') as jtitle,
			get_publication_attribute(publication_id,'volume') as volume,
			get_publication_attribute(publication_id,'issue') as issue
		FROM publication
		WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="uses" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT count(*) ct, 'cataloged item' as type 
		FROM citation
		WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		UNION
		SELECT count(*) ct, 'named group' as type 
		FROM underscore_collection_citation
		WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		UNION
		SELECT count(*) ct, 'taxon' as type 
		FROM taxonomy_publication
		WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		UNION
		SELECT count(*) ct, 'project' as type 
		FROM project_publication
		WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		UNION
		SELECT count(*) ct, 'identification sensu' as type 
		FROM identification
		WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="getAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT person.last_name as aulast
		FROM
			publication_author_name p
			join agent_name an on p.agent_name_id = an.agent_name_id
			join person on an.agent_id = person.person_id
		WHERE
			p.author_role = 'author' and p.author_position = 1 and
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfset useCount = 0>
	<cfloop query="uses">
		<cfset useCount = useCount + uses.ct>
	</cfloop>
	<cfoutput>
		<main class="container py-3" id="content" >
			<section class="row border rounded my-2">
				<h1 class="h2 w-100 px-2 pt-1">
					Edit Publication: #pub.short_citation# (#pub.publication_id#)
       			<img src="/images/info_i_2.gif" onClick="getMCZDocs('Edit Publication')" class="likeLink" alt="[ help ]">
					<span class="d-inline-block float-right">
						<a class="btn btn-xs btn-primary text-decoration-none" href="/publications/showPublication.cfm?publication_id=#pub.publication_id#">View Publication Details</a>
						<a class="btn btn-xs btn-primary text-decoration-none" href="/Citation.cfm?publication_id=#pub.publication_id#">Manage Citations</a>
					</span>
				</h1>
				<div class="h2 px-2" id="fullCitationDiv">#pub.full_citation#</div>
				<form class="col-12" name="editPubForm" id="editPubForm" method="post" action="Publication.cfm">
					<input type="hidden" name="publication_id" value="#pub.publication_id#">
					<input type="hidden" name="action" value="saveEdit">
					<input type="hidden" name="method" value="savePublication">
					<input type="hidden" name="fullCitationPlain" id="fullCitationPlain" value="#pub.full_citation_plain#">
					<div class="form-row mb-2 bg-verylightteal">
						<div class="col-12 col-md-11 mr-0">
							<label for="publication_title" class="data-entry-label">Publication Title</label>
							<textarea name="publication_title" id="publication_title" class="reqdClr w-100" rows="3" required>#pub.publication_title#</textarea>
						</div>
						<script>
							function markup(textAreaId, tag){
								var len = $("##"+textAreaId).val().length;
								var start = $("##"+textAreaId)[0].selectionStart;
								var end = $("##"+textAreaId)[0].selectionEnd;
								var selection = $("##"+textAreaId).val().substring(start, end);
								if (selection.length>0){
									var replace = selection;
									if (tag=='i') { 
										replace = '<i>' + selection + '</i>';
									} else if(tag=='b') { 
										replace = '<b>' + selection + '</b>';
									} else if(tag=='sub') { 
										replace = '<sub>' + selection + '</sub>';
									} else if(tag=='sup') { 
										replace = '<sup>' + selection + '</sup>';
									}
									$("##"+textAreaId).val($("##"+textAreaId).val().substring(0,start) + replace + $("##"+textAreaId).val().substring(end,len));
								}
							}
						</script>
						<div class="col-12 col-md-1 ml-0 row">
							<div class="col-6 ml-0 mr-0 px-0">
								<ul class="list-group pt-3">
									<li class="list-group-item px-0 pb-0">
										<button type="button" class="btn btn-xs btn-secondary m-0 w-100" onclick="markup('publication_title','i')" aria-label="italicize selected text"><i>i</i></button>
									</li>
									<li class="list-group-item px-0 pt-0">
										<button type="button" class="btn btn-xs btn-secondary m-0 w-100" onclick="markup('publication_title','b')" aria-label="make selected text bold"><strong>B</strong></button>
									</li>
								</ul>
							</div>
							<div class="col-6 ml-0 px-0">
								<ul class="list-group pt-3">
									<li class="list-group-item px-0 pb-0">
										<button type="button" class="btn btn-xs btn-secondary m-0 w-100" onclick="markup('publication_title','sub')" aria-label="make text subscript">A<sub>2</sub></button>
									</li>
									<li class="list-group-item px-0 pt-0">
										<button type="button" class="btn btn-xs btn-secondary m-0 w-100" onclick="markup('publication_title','sup')" aria-label="make selected text superscript">A<sup>2</sup></button>
									</li>
								</ul>
							</div>
					</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-12 col-md-6">
							<label for="publication_type" class="data-entry-label">Publication Type</label>
								<select name="publication_type" id="publication_type" class="reqdClr data-entry-select" required>
									<option value=""></option>
									<cfloop query="ctpublication_type">
										<cfif publication_type is pub.publication_type><cfset selected='selected="selected"'><cfelse><cfset selected=''> </cfif>
										<option value="#publication_type#" #selected#>#publication_type#</option>
									</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-3">
							<label for="published_year" class="data-entry-label">Published Year</label>
							<input type="text" name="published_year" id="published_year" class="data-entry-input" value="#pub.published_year#">
						</div>
						<div class="col-12 col-md-3">
							<label for="is_peer_reviewed_fg">Peer Reviewed?</label>
							<select name="is_peer_reviewed_fg" id="is_peer_reviewed_fg" class="reqdClr data-entry-select">
								<option <cfif pub.is_peer_reviewed_fg is 1> selected="selected" </cfif>value="1">yes</option>
								<option <cfif pub.is_peer_reviewed_fg is 0> selected="selected" </cfif>value="0">no</option>
							</select>
						</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-12 col-md-4">
							<label for="doi" class="data-entry-label">Digital Object Identifier (DOI)</label>
							<input type="text" id="doi" name="doi" value="#encodeForHtml(pub.doi)#" class="data-entry-input">
						</div>
						<div class="col-12 col-md-4" id="doiLinkDiv">
							<cfset crossref = "guestquery/">
							<cfif pub.publication_type EQ "book" OR pub.publication_type EQ "book section">
								<cfset crossref = "#crossref#?search_type=books">
							<cfelse>
								<cfset crossref = "#crossref#?search_type=journal">
							</cfif>
							<cfif getAuthor.recordcount GT 0>
								<cfset crossref = "#crossref#&auth=#getAuthor.aulast#">
								<cfset crossref = "#crossref#&auth2=#getAuthor.aulast#">
							</cfif>
							<cfif len(pub.jtitle) GT 0>
								<cfset crossref = "#crossref#&title=#encodeForURL(pub.jtitle)#">
							</cfif>
							<cfif len(pub.volume) GT 0>
								<cfset crossref = "#crossref#&volume=#encodeForURL(pub.volume)#">
							</cfif>
							<cfif len(pub.issue) GT 0>
								<cfset crossref = "#crossref#&issue=#encodeForURL(pub.issue)#">
							</cfif>
							<cfif len(pub.spage) GT 0>
								<cfset crossref = "#crossref#&page=#encodeForURL(pub.spage)#">
							</cfif>
							<cfif len(pub.published_year) GT 0>
								<cfset crossref = "#crossref#&year=#encodeForURL(pub.published_year)#">
							</cfif>
							<cfif len(pub.publication_title) GT 0>
								<cfset crossref = "#crossref#&atitle=#encodeForURL(pub.publication_title)#">
								<cfset crossref = "#crossref#&atitle2=#encodeForURL(pub.publication_title)#">
							</cfif>
							<cfif len(pub.doi) GT 0>
								<cfset crossref = "#crossref#&doi=#encodeForURL(pub.doi)#">
							</cfif>
							<label class="data-entry-label"><a href="https://www.crossref.org/#crossref#" target="_blank">Search CrossRef</a></label>
							<cfif len(pub.doi) gt 0>
								<a class="external" target="_blank" href="https://doi.org/#pub.doi#">#pub.doi#</a>
							<cfelse>
								<a id="doiLookupButton" class="btn btn-xs btn-secondary" onclick="lookupDOI('#encodeForUrl(pub.publication_id)#','doi','doiLinkDiv')">find DOI</a>
							</cfif>
						</div>
						<div class="col-12 col-md-4">
							<label for="publication_loc" class="data-entry-label">Storage Location</label>
							<input type="text" name="publication_loc" id="publication_loc" class="data-entry-input" value="#encodeForHtml(pub.publication_loc)#">
						</div>
						<div class="col-12 col-md-12">
							<label for="publication_remarks" class="data-entry-label">Remark</label>
							<input type="text" name="publication_remarks" id="publication_remarks" class="data-entry-input" value="#encodeForHtml(pub.publication_remarks)#">
						</div>
					</div>
					<div class="form-row mb-2" id="attributesForPublicationDiv">
						<!--- TODO: Expected attributes for publication type --->
					</div>
					<div class="form-row mb-2">
						<div class="col-12 col-md-10">
							<input type="button" value="Save" class="btn btn-primary btn-xs" onclick="saveEdits();">
							<output id="saveResultDiv" class="text-danger">&nbsp;</output>	
						</div>
						<div class="col-12 col-md-2">
							<cfif useCount EQ 0>
								<input type="button" value="Delete Publication" class="btn btn-danger btn-xs" onclick="editPubForm.action.value='deletePub';confirmDelete('editPubForm');">
							<cfelse>
								<input type="button" value="Delete Publication" class="btn btn-danger btn-xs disabled" disabled>
							</cfif>
						</div>
					</div>
					<script>
						function handleChange(){
							$('##saveResultDiv').html('Unsaved changes.');
							$('##saveResultDiv').addClass('text-danger');
							$('##saveResultDiv').removeClass('text-success');
							$('##saveResultDiv').removeClass('text-warning');
						};
						$(document).ready(function() {
							monitorForChanges('editPubForm',handleChange);
						});
						function saveEdits(){ 
							editPubForm.action.value='saveEdit';
							$('##saveResultDiv').html('Saving....');
							$('##saveResultDiv').addClass('text-warning');
							$('##saveResultDiv').removeClass('text-success');
							$('##saveResultDiv').removeClass('text-danger');
							jQuery.ajax({
								url : "/publications/component/functions.cfc",
								type : "post",
								dataType : "json",
								data : $('##editPubForm').serialize(),
								success : function (data) {
									$('##saveResultDiv').html('Saved.');
									$('##saveResultDiv').addClass('text-success');
									$('##saveResultDiv').removeClass('text-danger');
									$('##saveResultDiv').removeClass('text-warning');
									loadFullCitDivHTML(#publication_id#,'fullCitationDiv');
									loadPlainCitDivHTML(#publication_id#,'fullCitationPlain');
								},
								error: function(jqXHR,textStatus,error){
									$('##saveResultDiv').html('Error.');
									$('##saveResultDiv').addClass('text-danger');
									$('##saveResultDiv').removeClass('text-success');
									$('##saveResultDiv').removeClass('text-warning');
									handleFail(jqXHR,textStatus,error,'saving loan record');
								}
							});
						};
					</script>
				</form>
			</section>

			<section name="authorsSection" class="row border rounded my-2" title="Authors of this publication">
				<script>
					function reloadAuthors(){ 
						loadAuthorsDivHTML(#publication_id#,'authorBlock');
						loadFullCitDivHTML(#publication_id#,'fullCitationDiv');
						loadPlainCitDivHTML(#publication_id#,'fullCitationPlain');
					}
				</script>
				<cfset authorBlockContent = getAuthorsForPubHtml(publication_id = "#publication_id#")>
				<div id="authorBlock">#authorBlockContent#</div>
			</section>

			<section name="attributesSection" class="row border rounded my-2" title="Attributes of this publication">
				<script>
					function reloadAttributes(){ 
						loadAttributesDivHTML(#publication_id#,'attributesBlock');
						loadFullCitDivHTML(#publication_id#,'fullCitationDiv');
						loadPlainCitDivHTML(#publication_id#,'fullCitationPlain');
					}
				</script>
				<cfset attribBlockContent = getAttributesForPubHtml(publication_id = "#publication_id#")>
				<div id="attributesBlock">#attribBlockContent#</div>
			</section>

			<section name="mediaSection" class="row border rounded mx-0 my-2" title="Media related to this publication">
				<script>
					function reloadPublicationMedia(){ 
						loadMediaDivHTML(#publication_id#,'mediaBlock');
					}
				</script>
				<cfset mediaBlockContent = getMediaForPubHtml(publication_id = "#publication_id#")>
				<div id="mediaBlock">#bediaBlockContent#</div>
			</section>

			<section name="uriSection" class="row border rounded mx-0 my-2" title="Links for this publication">
				<!--- TODO Publication URI support --->
			</section>

			<section name="useSection" class="row border rounded mx-0 my-2" title="Citations and other uses of this publication">
				<cfif useCount EQ 0>
					<h2 class="h3">This publication record is not linked to any MCZbase records</h2>
				<cfelse>
					<h2 class="h3">This publication record is used in:</h2>
					<ul>
						<cfloop query="uses">
							<li>#uses.ct# citations of a #uses.type#</li>
						</cfloop>
					</ul>
				</cfif>
			</section>
		</main>
	</cfoutput>
</cfcase>
<cfcase value="deletePub">
	<!---------------------------------------------------------------------------------------------------------->
	<cftransaction>
		<cftry>
			<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					publication_id,
					mczbase.getshortcitation(publication_id) as short_citation
				FROM publication
				WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfif pub.recordcount NEQ 1>
				<cfthrow message="Specified publication_id does not match a publication record.">
			<cfelse>
				<!--- not needed, on delete cascade fk on publication_attributes --->
				<!--- cfquery name="dformatted_publication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from formatted_publication 
					where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				</cfquery --->
				<!--- not needed, on delete cascade fk on publication_attributes --->
				<!--- cfquery name="dpublication_attributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from publication_attributes 
					where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				</cfquery --->
				<cfquery name="dpublication_author_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from publication_author_name 
					where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				</cfquery>
				<cfquery name="dpublication_url" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from publication_url 
					where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				</cfquery>
				<cfquery name="dpublication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from publication 
					where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				</cfquery>
				<cftransaction action="commit">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback">
		</cfcatch>
		</cftry>
	</cftransaction>
</cfcase>
<cfcase value="newPub">
	<!---------------------------------------------------------------------------------------------------------->
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
		<main class="container py-3" id="content" >
			<section class="row border rounded my-2">
				<h1 class="h2">
					Create New Publication
					<img src="/images/info_i_2.gif" onClick="getMCZDocs('Publication-Data Entry')" class="likeLink" alt="[ help ]">
				</h1>

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
			</section>
		</main>
	</cfoutput>
</cfcase>
<cfcase value="createPub">
	<!---------------------------------------------------------------------------------------------------------->
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
		<cflocation url="/publications/Publication.cfm?action=edit&publication_id=#pid#" addtoken="false">
	</cfoutput>
</cfcase>
</cfswitch>

<cfinclude template="/shared/_footer.cfm">
