<!---
/CreateContainersForBarcodes.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2023 President and Fellows of Harvard College

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
<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>

<cfset pageHasContainers="true"><!--- enable /containers/js/containers.js --->
<cfset pageTitle = "Bulk Create Containers">
<cfinclude template = "/shared/_header.cfm">

<main class="container mt-3 mb-5 pb-5" id="content">
<!----------------------------------------------------------------------------------->
<cfif action is "nothing">
	<cfoutput>
		<cfquery name="ctContainer_Type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select container_type from ctcontainer_type order by container_type
		</cfquery>
		<cfquery name="ctinstitution_acronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select institution_acronym from collection group by institution_acronym order by institution_acronym
		</cfquery>
		<h1 class="h2 mt-3 mb-0 px-3">Create Containers for Barcodes</h1>
		<div class="row border rounded mx-0 p-2">
			<div class="col-12 px-0">
				<p>
					Containers (things that you can stick barcode to) in MCZbase should exist (generally as some type of
 					label) before they may be used. This form allows creation of series of containers. 
				</p>
				<p>You should use this form if you:</p>
				<ul class="labels">
					<li>Have placed, will place, and perhaps have considered placing an order for preprinted-labels.</li>
					<li>Have printed or intend to print your own series of labels.</li>
					<li>Wish to reserve a series of labels for any other reason.</li>
				</ul>
				<p>
					This form does nothing to labels that already exist. Don&apos;t try. The barcode label will be {prefix}{number}{suffix}. 
					For example, prefix='a', number = 1, suffix=' b' will produce barcode ' a1 b'. Make sure you
					enter <strong>exactly</strong> what the scanner
					will read, including all spaces!
				</p>
				<p>
					Label Prefix, Label Suffix, Unique Identifier Prefix, and Unique Identifier Suffix are the non-numeric parts of the label and identifier
					applied to each container in the form: Label = Prefix{number}Suffix, and Unique Identifier = Prefix{Number}Suffix.
					The Label and Unique identifier text may contain spaces if desired, convention is to use underscore _ instead of spaces in the Unique Identifier.
					If unique identifier prefix and suffix are specified, but label prefix or suffix are not, the unique identifier values will be used in the labels.
				</p>
				<p>
					You must pick a parent container for the created series of containers.
					You can pick the parent container for this series of containers with the label, barcode, or container_id for the parent container.  If 
					unplaced at the time of creation, use 'The Museum of Comparative Zoology' as the parent.  
				</p> 
			</div>
			<div class="col-12 px-0">
				<form name="form1" method="post" action="CreateContainersForBarcodes.cfm?action=create">
					<div class="form-row">
						<div class="col-12">
 							<label for="parent_container_id" class="data-entry-label">Select the Parent Container for the new series</label>
							<input type="hidden" name="parent_container_id" id="parent_container_id" class="data-entry-input">
							<input type="text" name="parent_container" id="parent_container" class="data-entry-input reqdClr" required>
						</div>
						<script>
							$(document).ready(function() {
								makeContainerAutocompleteMetaExcludeCO("parent_container", "parent_container_id", clear=false);
							});
						</script>
						<div class="col-12 col-md-4">
							<label for="institution_acronym" class="data-entry-label">Institution Acronym</label>
							<select name="institution_acronym" id="institution_acronym" class="data-entry-select reqdClr" style="width:110px;" required>
								<cfloop query="ctinstitution_acronym">
									<option value="#institution_acronym#">#institution_acronym#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-8 mt-2">
							<input type="checkbox" name="cryoBarcode" value="cryoBarcode"> Create "PLACE" barcodes for Cryo Collection</input>
						</div>
						<div class="col-12 col-md-3">
							<label class="data-entry-label" for="prefix">Unique Identifier Prefix</label>
							<input type="text" class="data-entry-input" name="prefix" id="prefix">
						</div>
						<div class="col-12 col-md-3">
							<label for="beginBarcode">Low number in series</label>
							<input type="text" class="data-entry-input reqdClr" name="beginBarcode" id="beginBarcode" required>
						</div>
						<div class="col-12 col-md-3">
							<label class="data-entry-label" for="endBarcode">High number in series</label>
							<input type="text" class="data-entry-input reqdClr" name="endBarcode" id="endBarcode" required>
						</div>
						<div class="col-12 col-md-3">
							<label class="data-entry-label" for="suffix">Unique Identifier Suffix</label>
							<input type="text" class="data-entry-input" name="suffix" id="suffix">
						</div>
						<div class="col-12 col-md-3">
							<label class="data-entry-label" for="label_prefix">Label Prefix</label>
							<input type="text" class="data-entry-input" name="label_prefix" id="label_prefix">
						</div>
						<div class="col-12 col-md-6">
							&nbsp;<!--- placeholder to line up prefix-suffix with start-end numbers --->
						</div>
						<div class="col-12 col-md-3">
							<label class="data-entry-label" for="label_suffix">Label Suffix</label>
							<input type="text" class="data-entry-input" name="label_suffix" id="label_suffix">
						</div>
						<div class="col-12">
							<label class="data-entry-label" for="container_type">Container Type</label>
							<select name="container_type" size="1" id="container_type" class="data-entry-select reqdClr" required>
								<option value=""></option>
								<cfloop query="ctContainer_Type">
									<option value="#ctContainer_Type.Container_Type#">#ctContainer_Type.Container_Type#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12">
							<label class="data-entry-label" for="remarks">Container Remarks (for each container)</label>
							<input type="text" class="data-entry-input" name="remarks" id="remarks" maxLength="1000">
						</div>
						<div class="col-12">
							<input type="submit" value="Create Series" class="insBtn">
						</div>
					</div>
				</form>
			</div>
		</div>
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfif action is "create">
	<cfif NOT isDefined("prefix")><cfset prefix=""></cfif>
	<cfif NOT isDefined("suffix")><cfset suffix=""></cfif>
	<cfif NOT isDefined("label_prefix")><cfset label_prefix=""></cfif>
	<cfif NOT isDefined("label_suffix")><cfset label_suffix=""></cfif>
	<cfset num = #endBarcode# - #beginBarcode#>
	<cfset barcode = "#beginBarcode#">
	<cfset success=false>
	<cfoutput>
		<cfset num = #num# + 1>
		<cftransaction>
			<cftry>
				<cfif isdefined("cryoBarcode")>
					<cfloop index="index" from="1" to = "#num#">
						<cfset mczbarcode=left(numberFormat(barcode,00000000),4) & "PLACE" & right(numberFormat(barcode,00000000),4)>
						<cfquery name="AddLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							INSERT INTO container 
							(
								container_id, parent_container_id, container_type, barcode, label, container_remarks,locked_position,institution_acronym
							)
							VALUES 
							(
								sq_container_id.nextval, 
								<cfif len(#parent_container_id#) GT 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_container_id#">
								<cfelse>
									1
								</cfif>, 
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#container_type#">, 
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mczbarcode#">, 
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mczbarcode#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">,
								0,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#institution_acronym#">
							)
						</cfquery>
						<cfset num = #num# + 1>
						<cfset barcode = #barcode# + 1>
					</cfloop>
					<cftransaction action="commit">
					<cfset success=true>
				<cfelse>
					<cfloop index="index" from="1" to = "#num#">
						<cfif #label_prefix# EQ "" and LEN(#prefix#) GT 0>
							<cfset label_prefix=prefix>
						</cfif>
						<cfif #label_suffix# EQ "" and LEN(#suffix#) GT 0>
							<cfset label_suffix=suffix>
						</cfif>
						<cfif left(#beginBarcode#,1) EQ "0" and isNumeric(#beginBarcode#)>
							<cfset numberMask=RepeatString("0",len(#beginBarcode#))>
							<cfset barcode=NumberFormat(barcode, numberMask)>
						</cfif>
						<cfquery name="AddLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							INSERT INTO container 
							(
								container_id, parent_container_id, container_type, barcode, label, container_remarks,locked_position,institution_acronym
							)
							VALUES 
							(
							sq_container_id.nextval, 
							<cfif len(#parent_container_id#) GT 0>
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_container_id#">
							<cfelse>
								1
							</cfif>, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#container_type#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#prefix##barcode##suffix#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label_prefix##barcode##label_suffix#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">,
							0,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#institution_acronym#">
							)
						</cfquery>
						<cfset num = #num# + 1>
						<cfset barcode = #barcode# + 1>
					</cfloop>
					<cftransaction action="commit">
					<cfset success=true>
				</cfif>
			<cfcatch>
				<cftransaction action="rollback">
				<div class="row mx-0">
					<div class="col-12 px-0">
						<h1 class="h2 mt-3 mb-0 px-3">Error: Unable To Create Container Records</h1>
						<ul>
							<li>Label Prefix: #label_prefix#</li>
							<li>Unique Identifier Prefix: #prefix#</li>
							<li>Start Number: #beginBarcode#</li>
							<li>End Number: #endBarcode#</li>
							<li>Unique Identifier Suffix: #suffix#</li>
							<li>Label Suffix: #label_suffix#</li>
							<li>(First) Error At Number: #barcode#</li>
							<li>(First) Error At Unique Identifier: <strong>#prefix##barcode##suffix#</strong></li>
							<li>(First) Error At Label: #label_prefix##barcode##label_suffix#</li>
							<li>Error: #cfcatch.message#</li>
							<cfif structKeyExists(cfcatch,"Cause") AND structKeyExists(cfcatch.cause,"Message")>
								<li>Error: #cfcatch.cause.message#</li>
								<cfif Find("ORA-00001: unique constraint (MCZBASE.U_BARCODE) violated",cfcatch.cause.message) GT 0>
									<li><strong>One or More of the Unique Identifiers you are trying to create already exists.</strong></li>
								</cfif>
							</cfif>
							<cfquery name="getParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT label, barcode, container_id
								FROM 
									container 
								WHERE
									container_id = 
									<cfif len(#parent_container_id#) GT 0>
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_container_id#">
									<cfelse>
										1
									</cfif>
							</cfquery>
							<cfloop query="getParent">
								<li>Parent Container: <a href="/findContainer.cfm?barcode=#getParent.barcode#">#getParent.label#</a> (#getParent.container_id#)</li>
							</cfloop>
					</div>
				</div>
			</cfcatch>
			</cftry>
		</cftransaction>
		<cfif success>
			<div class="row mx-0">
				<div class="col-12 px-0">
					<h1 class="h2 mt-3 mb-0 px-3">The series of container records with barcodes from #beginBarcode# to #endBarcode# have been created.</h1>
					<cfquery name="getParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT label, barcode, container_id
						FROM 
							container 
						WHERE
							container_id = 
							<cfif len(#parent_container_id#) GT 0>
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_container_id#">
							<cfelse>
								1
							</cfif>
					</cfquery>
					<cfloop query="getParent">
						<p>Created as children of Parent Container: <a href="/findContainer.cfm?barcode=#getParent.barcode#">#getParent.label#</a> (#getParent.container_id#)</p>
					</cfloop>
					<p>
						<a href="CreateContainersForBarcodes.cfm">Bulk create more containers</a>
					</p>
				</div>
			</div>
		</cfif>
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->

</main>
<cfinclude template = "/shared/_footer.cfm">
