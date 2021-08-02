<cfinclude template="includes/_header.cfm">
<cfquery name="ctcollcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct collection_cde from ctcollection_cde
</cfquery>
<cfoutput>
<cfset title = "Edit Code Tables">
<cfif action is "nothing">
	<cfquery name="getCTName" datasource="uam_god">
		select 
			distinct(table_name) table_name 
		from 
			sys.user_tables 
		where 
			table_name like 'CT%'
		UNION 
			select 'CTGEOLOGY_ATTRIBUTE' table_name from dual
		 order by table_name
	</cfquery>
	<cfloop query="getCTName">
		<cfset name = REReplace(getCtName.table_name,"^CT","") ><!--- strip CT from names in list for better readability --->
		<a href="CodeTableEditor.cfm?action=edit&tbl=#getCTName.table_name#">#name#</a><br>
	</cfloop>
<cfelseif action is "edit">
	<p>
		<a href="/CodeTableEditor.cfm">Back to table list</a>
	</p>
	<cfif tbl is "CTGEOLOGY_ATTRIBUTE"><!---------------------------------------------------->
		<cflocation url="/info/geol_hierarchy.cfm" addtoken="false">
	<cfelseif tbl is "ctspecimen_part_name"><!---------------------------------------------------->
		<cflocation url="/Admin/ctspecimen_part_name.cfm" addtoken="false">
	<cfelseif tbl is "ctspec_part_att_att"><!---------------------------------------------------->
		<cflocation url="/Admin/ctspec_part_att_att.cfm" addtoken="false">
	<cfelseif tbl is "ctmedia_license"><!---------------------------------------------------->
		<cflocation url="/Admin/ctmedia_license.cfm" addtoken="false">
	<cfelseif tbl is "ctattribute_code_tables"><!---------------------------------------------------->
		<cfquery name="ctAttribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct(attribute_type) from ctAttribute_type
		</cfquery>
		<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			Select * from ctattribute_code_tables
			order by attribute_type
		</cfquery>
		<cfquery name="allCTs" datasource="uam_god">
			select distinct(table_name) as tablename from sys.user_tables where table_name like 'CT%' order by table_name
		</cfquery>
		<br>Create Attribute Control
		<table class="newRec" border>
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>Units Code Table</th>
				<th>&nbsp;</th>
			</tr>
			<form method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" value="#tbl#">
				<tr>
					<td>				
						<select name="attribute_type" size="1">
							<option value=""></option>
							<cfloop query="ctAttribute_type">
							<option 
								value="#ctAttribute_type.attribute_type#">#ctAttribute_type.attribute_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisValueTable = #thisRec.value_code_table#>
						<select name="value_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option 
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>			
					</td>
					<td>
						<cfset thisUnitsTable = #thisRec.units_code_table#>
						<select name="units_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option 
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="submit" 
							value="Create" 
							class="insBtn">	
					</td>
				</tr>
			</form>
		</table>
		<br>Edit Attribute Controls
		<table border>
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>Units Code Table</th>
				<th>&nbsp;</th>
			</tr>
			<cfset i=1>
			<cfloop query="thisRec">
				<form name="att#i#" method="post" action="CodeTableEditor.cfm">
					<input type="hidden" name="action" value="">
					<input type="hidden" name="tbl" value="#tbl#">
					<input type="hidden" name="oldAttribute_type" value="#Attribute_type#">
					<input type="hidden" name="oldvalue_code_table" value="#value_code_table#">
					<input type="hidden" name="oldunits_code_table" value="#units_code_table#">
					<tr>
						<td>
							<cfset thisAttType = #thisRec.attribute_type#>
								<select name="attribute_type" size="1">
									<option value=""></option>
									<cfloop query="ctAttribute_type">
									<option 
												<cfif #thisAttType# is "#ctAttribute_type.attribute_type#"> selected </cfif>value="#ctAttribute_type.attribute_type#">#ctAttribute_type.attribute_type#</option>
									</cfloop>
								</select>
						</td>
						<td>
							<cfset thisValueTable = #thisRec.value_code_table#>
							<select name="value_code_table" size="1">
								<option value="">none</option>
								<cfloop query="allCTs">
								<option 
								<cfif #thisValueTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<cfset thisUnitsTable = #thisRec.units_code_table#>
							<select name="units_code_table" size="1">
								<option value="">none</option>
								<cfloop query="allCTs">
								<option 
								<cfif #thisUnitsTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<input type="button" 
								value="Save" 
								class="savBtn"
							 	onclick="att#i#.action.value='saveEdit';submit();">	
							<input type="button" 
								value="Delete" 
								class="delBtn"
								onclick="att#i#.action.value='deleteValue';submit();">	
						</td>
					</tr>
				</form>
			<cfset i=#i#+1>
		</cfloop>
	</table>
	<cfelseif tbl is "ctcountry_code"><!---------------------------------------------------->
                <p>ISO 2 letter country codes for country names.  A country name can appear more than once to represent alternative forms of the name for the country, all mapping to the same country code, but each country name string must be unique.   Do not include strings which map onto historical country names which may map onto more than one current country, even if on ISO list (e.g. 'Congo').</p>
		<!---   Country/Country Code code table includes fields for country and country code, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select country, code from ctcountry_code order by code, country
		</cfquery>
		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<table class="newRec">
				<tr>
					<th>Country Code</th>
					<th>Country</th>
					<th></th>
				</tr>
				<tr>
					<td>
						<input type="text" name="code" maxlength="3">
					</td>
					<td>
						<input type="text" name="newData" >
					</td>
					<td>
						<input type="submit" 
							value="Insert" 
							class="insBtn">
					</td>
				</tr>
			</table>
		</form>
		<table>
			<tr>
				<th>Country Code</th>
				<th>Country</th>
				<th></th>
			</tr>
			<cfset i = 1>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#country#">
						<td>
							<input type="text" name="code" value="#code#" maxlength="3">
						</td>
						<td>
							<input type="text" name="country" value="#country#">
						</td>
						<td>
							<input type="button" 
								value="Save" 
								class="savBtn"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="delBtn"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</td>
					</form>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
		</table>

	<cfelseif tbl is "ctguid_type"><!---------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select guid_type, description, applies_to, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
			from ctguid_type 
			order by guid_type
		</cfquery>
		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<table class="newRec" style="width: 90em;">
				<tr>
					<td>GUID Type:</td>
					<td>
						<input type="text" name="newData" class="reqdClr" required >
					</td>
					<td>Name for picklist</td>
				</tr>
				<tr>
					<td>Description:</td>
					<td colspan="2">
						<input type="text" name="description" size="80">
					</td>
				</tr>
				<tr>
					<td>Applies to</td>
					<td>
						<input type="text" name="applies_to" size="80" class="reqdClr" required>
					</td>
					<td>space delimited list of table.field)</td>
				</tr>
				<tr>
					<td>Placeholder</td>
					<td>
						<input type="text" name="placeholder" size="80">
					</td>
					<td>Hint for data entry, e.g. doi:</td>
				</tr>
				<tr>
					<td>Pattern Regex</td>
					<td>
						<input type="text" name="pattern_regex" size="80" class="reqdClr" required>
					</td>
					<td>To validate entry, e.g. ^doi:10[.].+$</td>
				</tr>
				<tr>
					<td>Resolver Regex</td>
					<td>
						<input type="text" name="resolver_regex" size="80">
					</td>
					<td>Regex pattern for conversion to a uri, e.g. ^doi:</td>
				</tr>
				<tr>
					<td>Resolver Replacement</td>
					<td>
						<input type="text" name="resolver_replacement" size="80">
					</td>
					<td>Replacement string for match to pattern, e.g. https://doi.org/</td>
				</tr>
				<tr>
					<td>Search URI</td>
					<td>
						<input type="text" name="search_uri" size="80">
					</td>
					<td>URI where guid can be searched for by a relevant text string which is appended to the end of the specified URI, blank if no search by text function.</td>
				</tr>
				<tr>
					<td></td>
					<td>
						<input type="submit" 
							value="Insert" 
							class="insBtn">
					</td>
					<td></td>
				</tr>
			</table>
		</form>
		<br>
		<table>
			<cfset i = 1>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#guid_type#">
					<table style="border: 1px solid black">
						<tr>
							<td>GUID Type:</td>
							<td>
								<input type="text" name="guid_type" value="#guid_type#" class="reqdClr" required >
							</td>
							<td>Name for picklist</td>
						</tr>
						<tr>
							<td>Description:</td>
							<td colspan="2">
								<input type="text" name="description" value="#description#" size="80">
							</td>
						</tr>
						<tr>
							<td>Applies to</td>
							<td>
								<input type="text" name="applies_to" value="#applies_to#" size="80" class="reqdClr" required>
							</td>
							<td>space delimited list of table.field</td>
						</tr>
						<tr>
							<td>Placeholder</td>
							<td>
								<input type="text" name="placeholder" value="#placeholder#" size="80" >
							</td>
							<td>Hint for data entry, e.g. doi:</td>
						</tr>
						<tr>
							<td>Pattern Regex</td>
							<td>
								<input type="text" name="pattern_regex" value="#pattern_regex#" size="80" class="reqdClr" required>
							</td>
							<td>Regex to validate entry, e.g. ^doi:10[.].+$</td>
						</tr>
						<tr>
							<td>Resolver Regex</td>
							<td>
								<input type="text" name="resolver_regex" value="#resolver_regex#" size="80">
							</td>
							<td>Regex pattern for conversion to a uri, e.g. ^doi:</td>
						</tr>
						<tr>
							<td>Resolver Replacement</td>
							<td>
								<input type="text" name="resolver_replacement" value="#resolver_replacement#" size="80">
							</td>
							<td>Replacement string for match to pattern, e.g. https://doi.org/</td>
						</tr>
						<tr>
							<td>Search URI</td>
							<td>
								<input type="text" name="search_uri" value="#search_uri#" size="80">
							</td>
							<td>URI where guid can be searched for by a relevant text string which is appended to the end of the specified URI, blank if no search by text function.</td>
						</tr>
						<tr>
							<td></td>
							<td>
								<input type="button" 
									value="Save" 
									class="savBtn"
									onclick="#tbl##i#.action.value='saveEdit';submit();">
							</td>
							<td>
								<input type="button" 
									value="Delete" 
									class="delBtn"
									onclick="#tbl##i#.action.value='deleteValue';submit();">
							</td>
						</tr>
					<table>
					</form>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
		</table>

	<cfelseif tbl is "ctloan_type"><!---------------------------------------------------->
		<!---   Loan type code table includes fields for scope (loan or gift) and sort order, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select loan_type, scope, ordinal from ctloan_type order by scope desc, ordinal, loan_type
		</cfquery>
		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<table class="newRec">
				<tr>
					<th>Loan Type</th>
					<th>Loan/Gift</th>
					<th>Sort Order</th>
					<th></th>
				</tr>
				<tr>
					<td>
						<input type="text" name="newData" >
					</td>
					<td>
						<select name="scope">
							<option value="Loan">Loan</option>
							<option value="Gift">Gift</option>
						</select>
					</td>
					<td>
						<input type="text" name="ordinal">
					</td>
					<td>
						<input type="submit" 
							value="Insert" 
							class="insBtn">
					</td>
				</tr>
			</table>
		</form>
		<table>
			<tr>
				<th>Loan Type</th>
				<th>Loan/Gift</th>
				<th>Sort Order</th>
			</tr>
			<cfset i = 1>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#loan_type#">
						<td>
							<input type="text" name="loan_type" value="#loan_type#">
						</td>
						<td>
							<cfif scope EQ "Loan"> 
								<cfset scopeloanselected = "selected='selected'">
								<cfset scopegiftselected = "">
							<cfelse>
								<cfset scopeloanselected = "">
								<cfset scopegiftselected = "selected='selected'">
							</cfif>
							<select name="scope">
								<option value="Loan" #scopeloanselected# >Loan</option>
								<option value="Gift" #scopegiftselected# >Gift</option>
							</select>
						</td>
						<td>
							<input type="text" name="ordinal" value="#ordinal#">
						</td>
						<td>
							<input type="button" 
								value="Save" 
								class="savBtn"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="delBtn"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</td>
					</form>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
		</table>
	<cfelseif tbl is "ctspecific_permit_type">
		<!---------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from ctspecific_permit_type order by specific_type
		</cfquery>
		<cfquery name="ptypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select permit_type from ctpermit_type order by permit_type
		</cfquery>
		<h2>Specific Types of Permissions and Rights documents (permits)</h2>
		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctspecific_permit_type">
			<table class="newRec">
				<tr>
					<th>Specific Type</th>
					<th>General Type</th>
					<th>Carry Accession Document to Loans</th>
					<th></th>
				</tr>
				<tr>
					<td>
						<input type="text" name="newData" size=80 >
					</td>
					<td>
						<select name="permit_type">
							<option value=""></option>
							<cfloop query="ptypes">
								<option value="#permit_type#">#permit_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<select name="accn_show_on_shipment">
							<option value="1" selected="selected" >Yes</option>
							<option value="0">No</option>
						</select>
					</td>
					<td>
						<input type="submit" 
							value="Insert" 
							class="insBtn">
					</td>
				</tr>
			</table>
		</form>
		<cfset i = 1>
		<table>
			<tr>
				<th>Specific Type</th>
				<th>General Type</th>
					<th>Carry&nbsp;Accession Document&nbsp;to&nbsp;Loans</th>
					<th></th>
			</tr>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="ctspecific_permit_type">
						<input type="hidden" name="origData" value="#q.specific_type#">
						<input type="hidden" name="fld" value="specific_type">
						<td>
							<input type="text" name="specific_type" value="#q.specific_type#" size="66">
						</td>
						<td>
							<select name="permit_type">
								<option value=""></option>
								<cfloop query="ptypes" >
									<option <cfif q.permit_type is ptypes.permit_type > selected="selected" </cfif>value="#ptypes.permit_type#">#ptypes.permit_type#</option>
								</cfloop>
							</select>
						</td>				
						<td style="width: 3em;">
							<select name="accn_show_on_shipment">
								<option <cfif q.accn_show_on_shipment EQ 1 > selected="selected" </cfif>value="1">Yes</option>
								<option <cfif q.accn_show_on_shipment EQ 0 > selected="selected" </cfif>value="0">No</option>
							</select>
						</td>				
						<td><span>
							<input type="button" 
								value="Save" 
								class="savBtn"
								onclick="#tbl##i#.action.value='saveEdit';submit();">	
							<input type="button" 
								value="Delete" 
								class="delBtn"
								onclick="#tbl##i#.action.value='deleteValue';submit();"></span>
						</td>
					</form>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
		</table>
	<cfelseif tbl is "ctcitation_type_status"><!---------------------------------------------------->
		<!---  Type status code table includes fields for category and sort order, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select type_status, description, category, ordinal from ctcitation_type_status order by category, ordinal, type_status
		</cfquery>
		<h2>Citation type, type status terms and other kinds of citation</h2>
		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<table class="newRec">
				<tr>
					<th>Type Status</th>
					<th>Kind of Type</th>
					<th>Sort Order</th>
					<th>Description</th>
					<th></th>
				</tr>
				<tr>
					<td>
						<input type="text" name="newData" >
					</td>
					<td>
						<select name="category">
							<option value="Primary">Primary</option>
							<option value="Secondary">Secondary</option>
							<option value="Voucher">Voucher (non-type)</option>
							<option value="Voucher Not">Not Voucher (non-type)</option>
                            <!---  NOTE: If you add a value here, you also need to add it to the edit picklist below --->
                            <!---  NOTE: Alphabetic sort of these values is used to order Primary/Secondary/other type status --->
                            <!---  If new category values are added for non-types, they should sort after Secondary. --->
						</select>
					</td>
					<td>
						<input type="text" name="ordinal">
					</td>
					<td>
						<input type="text" name="description">
					</td>
					<td>
						<input type="submit" 
							value="Insert" 
							class="insBtn">
					</td>
				</tr>
			</table>
		</form>
		<table>
			<tr>
				<th>Type Status</th>
				<th>Kind of Type</th>
				<th>Sort Order</th>
				<th>Description</th>
			</tr>
			<cfset i = 1>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#type_status#">
						<td>
							<input type="text" name="type_status" value="#type_status#">
						</td>
						<td>
							<cfif category EQ "Primary"> 
								<cfset scopepriselected = "selected='selected'">
								<cfset scopesecselected = "">
								<cfset scopevouselected = "">
								<cfset scopenvouselected = "">
							<cfelseif category EQ "Secondary"> 
								<cfset scopepriselected = "">
								<cfset scopesecselected = "selected='selected'">
								<cfset scopevouselected = "">
								<cfset scopenvouselected = "">
							<cfelseif category EQ "Voucher Not"> 
								<cfset scopepriselected = "">
								<cfset scopesecselected = "">
								<cfset scopevouselected = "">
								<cfset scopenvouselected = "selected='selected'">
							<cfelse>
                                <!-- caution, failover case will select Voucher as the value --->
								<cfset scopepriselected = "">
								<cfset scopesecselected = "">
								<cfset scopevouselected = "selected='selected'">
								<cfset scopenvouselected = "">
							</cfif>
							<select name="category">
								<option value="Primary" #scopepriselected# >Primary</option>
								<option value="Secondary" #scopesecselected# >Secondary</option>
								<option value="Voucher" #scopevouselected# >Voucher (non-type)</option>
								<option value="Voucher Not" #scopenvouselected#>Not Voucher (non-type)</option>
							</select>
						</td>
						<td>
							<input type="text" name="ordinal" value="#ordinal#">
						</td>
						<td>
							<input type="description" name="description" value="#stripQuotes(description)#">
						</td>
						<td>
							<input type="button" 
								value="Save" 
								class="savBtn"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="delBtn"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</td>
					</form>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
		</table>
	<cfelseif tbl is "ctpublication_attribute"><!---------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from ctpublication_attribute order by publication_attribute
		</cfquery>
		<cfquery name="allCTs" datasource="uam_god">
			select distinct(table_name) as tablename from sys.user_tables where table_name like 'CT%' order by table_name
		</cfquery>
		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctpublication_attribute">
			<table class="newRec">
				<tr>
					<th>Publication Attribute</th>
					<th>Description</th>
					<th>Control</th>
					<th></th>
				</tr>
				<tr>
					<td>
						<input type="text" name="newData" >
					</td>
					<td>
						<textarea name="description" rows="4" cols="40"></textarea>
					</td>
					<td>
						<select name="control">
							<option value=""></option>
							<cfloop query="allCTs">
								<option value="#tablename#">#tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="submit" 
							value="Insert" 
							class="insBtn">
					</td>
				</tr>
			</table>
		</form>
		<cfset i = 1>
		<table>
			<tr>
				<th>Type</th>
				<th>Description</th>
				<th>Control</th>
			</tr>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="ctpublication_attribute">
						<input type="hidden" name="origData" value="#publication_attribute#">
						<td>
							<input type="text" name="publication_attribute" value="#publication_attribute#" size="50">
						</td>
						<td>
							<textarea name="description" rows="4" cols="40">#description#</textarea>
						</td>
						<td>
							<select name="control">
								<option value=""></option>
								<cfloop query="allCTs">
									<option <cfif q.control is allCTs.tablename> selected="selected" </cfif>value="#tablename#">#tablename#</option>
								</cfloop>
							</select>
						</td>				
						<td>
							<input type="button" 
								value="Save" 
								class="savBtn"
								onclick="#tbl##i#.action.value='saveEdit';submit();">	
							<input type="button" 
								value="Delete" 
								class="delBtn"
								onclick="#tbl##i#.action.value='deleteValue';submit();">	
			
						</td>
					</form>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
		</table>
	<cfelseif tbl is "ctbiol_relations"><!---------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from ctbiol_relations order by biol_indiv_relationship
		</cfquery>
		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctbiol_relations">
			<table class="newRec">
				<tr>
					<th>Relationship</th>
					<th>Inverse Relation</th>
					<th>Type</th>
					<th></th>
				</tr>
				<tr>
						<td>
							<input type="text" name="newData" size="50">
						</td>
						<td>
							<input type="text" name="inverse_relation" size="50">
						</td>
						<td>
							<select name="rel_type">
								<option value="biological" selected='selected'>Biological</option>
								<option value="curatorial">Curatorial</option>
								<option value="functional">Functional</option>
							</select>
						</td>				
					<td>
						<input type="submit" 
							value="Insert" 
							class="insBtn">
					</td>
				</tr>
			</table>
		</form>
		<cfset i = 1>
		<table>
			<tr>
				<th>Relationship</th>
				<th>Inverse Relation</th>
				<th>Type</th>
			</tr>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="ctbiol_relations">
						<input type="hidden" name="origData" value="#biol_indiv_relationship#">
						<td>
							<input type="text" name="biol_indiv_relationship" value="#biol_indiv_relationship#" size="50">
						</td>
						<td>
							<input type="text" name="inverse_relation" value="#inverse_relation#" size="50">
						</td>
						<td>
							<cfif rel_type EQ "biological">
								<cfset scopepriselected = "selected='selected'">
								<cfset scopesecselected = "">
								<cfset scopevouselected = "">
							<cfelseif rel_type EQ "curatorial">
								<cfset scopepriselected = "">
								<cfset scopesecselected = "selected='selected'">
								<cfset scopevouselected = "">
							<cfelse>
								<cfset scopepriselected = "">
								<cfset scopesecselected = "">
								<cfset scopevouselected = "selected='selected'">
							</cfif>
							<select name="rel_type">
								<option value="biological" #scopepriselected# >Biological</option>
								<option value="curatorial" #scopesecselected# >Curatorial</option>
								<option value="functional" #scopevouselected# >Functional</option>
							</select>
						</td>				
						<td>
							<input type="button" 
								value="Save" 
								class="savBtn"
								onclick="#tbl##i#.action.value='saveEdit';submit();">	
							<input type="button" 
								value="Delete" 
								class="delBtn"
								onclick="#tbl##i#.action.value='deleteValue';submit();">	
			
						</td>
					</form>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
		</table>
	<cfelseif tbl is "ctcoll_other_id_type"><!--------------------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from ctcoll_other_id_type order by other_id_type
		</cfquery>	
		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctcoll_other_id_type">
			<table class="newRec">
				<tr>
					<th>ID Type</th>
					<th>Description</th>
					<th>Base URL</th>
					<th></th>
				</tr>
				<tr>
					<td>
						<input type="text" name="newData" >
					</td>
					<td>
						<textarea name="description" rows="4" cols="40"></textarea>
					</td>
					<td>
						<input type="text" name="base_url" size="50">
					</td>
					<td>
						<input type="submit" 
							value="Insert" 
							class="insBtn">					
					</td>
				</tr>
			</table>
		</form>
		<cfset i = 1>
		<table>
			<tr>
				<th>Type</th>
				<th>Description</th>
				<th>Base URL</th>
			</tr>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="ctcoll_other_id_type">
						<input type="hidden" name="origData" value="#other_id_type#">
						<td>
							<input type="text" name="other_id_type" value="#other_id_type#" size="50">
						</td>
						<td>
							<textarea name="description" rows="4" cols="40">#description#</textarea>
						</td>
						<td>
							<input type="text" name="base_url" size="60" value="#base_url#">
						</td>				
						<td>
							<input type="button" 
								value="Save" 
								class="savBtn"
								onclick="#tbl##i#.action.value='saveEdit';submit();">	
							<input type="button" 
								value="Delete" 
								class="delBtn"
								onclick="#tbl##i#.action.value='deleteValue';submit();">	
						</td>
					</form>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
		</table>
	<cfelseif tbl is "ctnomenclatural_code"><!--------------------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select nomenclatural_code, description, sort_order from ctnomenclatural_code order by sort_order
		</cfquery>	
		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctnomenclatural_code">
			<table class="newRec">
				<tr>
					<th>Nomenclatural Code</th>
					<th>Description</th>
					<th>Sort Order</th>
					<th></th>
				</tr>
				<tr>
					<td>
						<input type="text" name="newData" >
					</td>
					<td>
						<textarea name="description" rows="4" cols="70"></textarea>
					</td>
					<td>
						<input type="text" name="sort_order" size="3">
					</td>
					<td>
						<input type="submit" 
							value="Insert" 
							class="insBtn">					
					</td>
				</tr>
			</table>
		</form>
		<cfset i = 1>
		<table>
			<tr>
				<th>Nomenclatural Code</th>
				<th>Description</th>
				<th>Sort Order</th>
			</tr>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="ctnomenclatural_code">
						<input type="hidden" name="origData" value="#nomenclatural_code#">
						<td>
							<input type="text" name="nomenclatural_code" value="#nomenclatural_code#" size="50">
						</td>
						<td>
							<textarea name="description" rows="4" cols="70">#description#</textarea>
						</td>
						<td>
							<input type="text" name="sort_order" size="3" value="#sort_order#">
						</td>				
						<td>
							<input type="button" 
								value="Save" 
								class="savBtn"
								onclick="#tbl##i#.action.value='saveEdit';submit();">	
							<input type="button" 
								value="Delete" 
								class="delBtn"
								onclick="#tbl##i#.action.value='deleteValue';submit();">	
						</td>
					</form>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
		</table>
	<cfelseif tbl is "ctspecimen_part_list_order"><!--- special section to handle  another  funky code table --->
		<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from ctspecimen_part_list_order order by
			list_order,partname
		</cfquery>
		<cfquery name="ctspecimen_part_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select collection_cde, part_name partname from ctspecimen_part_name
		</cfquery>
		<cfquery name="mo" dbtype="query">
			select max(list_order) +1 maxNum from thisRec
		</cfquery>
		<p>
			This application sets the order part names appear in certain reports and forms. 
			Nothing prevents you from making several parts the same
			order, and doing so will just cause them to not be ordered. You don't have to order things you don't care about.	
		</p>
		Create part ordering
		<table class="newRec" border>
			<tr>
				<th>Part Name</th>
				<th>List Order</th>
				<th></th>
			</tr>
			<form name="newPart" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" value="#tbl#">
				<tr>
					<td>
						<cfset thisPart = #thisRec.partname#>
						<select name="partname" size="1">
							<cfloop query="ctspecimen_part_name">
							<option 
							value="#ctspecimen_part_name.partname#">#ctspecimen_part_name.partname# (#ctspecimen_part_name.collection_cde#)</option>
							</cfloop>
						</select>
					</td>
					<cfquery name="mo" dbtype="query">
						select max(list_order) +1 maxNum from thisRec
					</cfquery>
					<td>
						<cfset thisLO = #thisRec.list_order#>
						<select name="list_order" size="1">
							<cfloop from="1" to="#mo.maxNum#" index="n">
								<option value="#n#">#n#</option>
							</cfloop>
						</select>
					</td>
					<td colspan="3">
						<input type="submit" 
							value="Create" 
							class="insBtn">	
					</td>
				</tr>
			</form>	
		</table>
		Edit part order
		<table border>
			<tr>
				<th>Part Name</th>
				<th>List Order</th>
				<th>&nbsp;</th>
			</tr>
			<cfset i=1>
			<cfloop query="thisRec">
				<form name="part#i#" method="post" action="CodeTableEditor.cfm">
					<input type="hidden" name="action" value="ctspecimen_part_list_order">
					<input type="hidden" name="tbl" value="#tbl#">
					<input type="hidden" name="oldlist_order" value="#list_order#">
					<input type="hidden" name="oldpartname" value="#partname#">
					<tr>
						<td>
							<cfset thisPart = #thisRec.partname#>
							<select name="partname" size="1">
								<cfloop query="ctspecimen_part_name">
								<option 
								<cfif #thisPart# is "#ctspecimen_part_name.partname#"> selected </cfif>value="#ctspecimen_part_name.partname#">#ctspecimen_part_name.partname#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<cfset thisLO = #thisRec.list_order#>
							<select name="list_order" size="1">
								<cfloop from="1" to="#mo.maxNum#" index="n">
									<option <cfif #thisLO# is "#n#"> selected </cfif>value="#n#">#n#</option>
								</cfloop>
							</select>
						</td>
						<td colspan="3">
							<input type="button" 
								value="Save" 
								class="savBtn"
								onclick="part#i#.action.value='saveEdit';submit();">	
							<input type="button" 
								value="Delete" 
								class="delBtn"
							 	onclick="part#i#.action.value='deleteValue';submit();">	
								
						</td>
					</tr>
				</form>
				<cfset i=#i#+1>
			</cfloop>
		</table>
	<cfelse><!---------------------------- normal CTs --------------->
		<cfquery name="getCols" datasource="uam_god">
			select column_name from sys.user_tab_columns where table_name='#tbl#'
		</cfquery>
		<cfset collcde=listfindnocase(valuelist(getCols.column_name),"collection_cde")>
		<cfset hasDescn=listfindnocase(valuelist(getCols.column_name),"description")>
		<cfquery name="f" dbtype="query">
			select column_name from getCols where lower(column_name) not in ('collection_cde','description')
		</cfquery>
		<cfset fld=f.column_name>
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select #fld# as data 
			<cfif collcde gt 0>
				,collection_cde
			</cfif>
			<cfif hasDescn gt 0>
				,description
			</cfif>
			from #tbl#
			ORDER BY
			<cfif collcde gt 0>
				collection_cde,
			</cfif>
			#fld#
		</cfquery>
		Add record:
		<table class="newRec" border="1">
			<tr>
				<cfif collcde gt 0>
					<th>Collection Type</th>
				</cfif>
				<th>#fld#</th>
				<cfif hasDescn gt 0>
					<th>Description</th>
				</cfif>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="collcde" value="#collcde#">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" value="#tbl#">
				<input type="hidden" name="hasDescn" value="#hasDescn#">
				<input type="hidden" name="fld" value="#fld#">
				<tr>
					<cfif collcde gt 0>
						<td>
							<select name="collection_cde" size="1">
								<cfloop query="ctcollcde">
									<option value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
								</cfloop>
							</select>
						</td>
					</cfif>
					<td>
						<input type="text" name="newData" >
					</td>
					
					<cfif hasDescn gt 0>
						<td>
							<textarea name="description" id="description" rows="4" cols="40"></textarea>
						</td>
					</cfif>
					<td>
						<input type="submit" 
							value="Insert" 
							class="insBtn">	
					</td>
				</tr>
			</form>
		</table>
		<cfset i = 1>
		Edit #tbl#:
		<table border="1">
			<tr>
				<cfif collcde gt 0>
					<th>Collection Type</th>
				</cfif>
				<th>#fld#</th>
				<cfif hasDescn gt 0>
					<th>Description</th>
				</cfif>
			</tr>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="Action">
						<input type="hidden" name="tbl" value="#tbl#">
						<input type="hidden" name="fld" value="#fld#">
						<input type="hidden" name="collcde" value="#collcde#">
						<input type="hidden" name="hasDescn" value="#hasDescn#">
						<input type="hidden" name="origData" value="#q.data#">
						<cfif collcde gt 0>
							<input type="hidden" name="origcollection_cde" value="#q.collection_cde#">
							<cfset thisColl=#q.collection_cde#>
							<td>
								<select name="collection_cde" size="1">
									<cfloop query="ctcollcde">
										<option 
											<cfif #thisColl# is "#ctcollcde.collection_cde#"> selected </cfif>value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
									</cfloop>
								</select>
							</td>
						</cfif>
						<td>
							<input type="text" name="thisField" value="#q.data#" size="50">
						</td>
						<cfif hasDescn gt 0>
							<td>
								<textarea name="description" rows="4" cols="40">#q.description#</textarea>
							</td>				
						</cfif>
						<td>
							<input type="button" 
								value="Save" 
								class="savBtn"
								onclick="#tbl##i#.Action.value='saveEdit';submit();">	
							<input type="button" 
								value="Delete" 
								class="delBtn"
								onclick="#tbl##i#.Action.value='deleteValue';submit();">	
		
						</td>
					</form>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
		</table>
	</cfif>
<cfelseif action is "deleteValue">
	<cfif tbl is "ctpublication_attribute">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from ctpublication_attribute 
			where
				publication_attribute='#origData#'
		</cfquery>
	<cfelseif tbl is "ctnomenclatural_code">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from ctnomenclatural_code 
			where
				nomenclatural_code='#origData#'
		</cfquery>
	<cfelseif tbl is "ctguid_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from ctguid_type
			where
				GUID_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctloan_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from ctloan_type
			where
				LOAN_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctcountry_code">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from ctcountry_code
			where
				COUNTRY = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctbiol_relations">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from ctbiol_relations
			where
				BIOL_INDIV_RELATIONSHIP='#origData#'
		</cfquery>
	<cfelseif tbl is "ctcoll_other_id_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from ctcoll_other_id_type
			where
				OTHER_ID_TYPE='#origData#'
		</cfquery>
	<cfelseif tbl is "ctattribute_code_tables">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			DELETE FROM ctattribute_code_tables
			WHERE
				Attribute_type = '#oldAttribute_type#' 
				<cfif len(#oldvalue_code_table#) gt 0>
					AND	value_code_table = '#oldvalue_code_table#'
				</cfif> 
				<cfif len(#oldunits_code_table#) gt 0>
					AND	units_code_table = '#oldunits_code_table#'
				</cfif> 
		</cfquery>
	<cfelseif tbl is "ctspecimen_part_list_order">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			DELETE FROM ctspecimen_part_list_order
			WHERE
				partname = '#oldpartname#' AND
				list_order = '#oldlist_order#'
		</cfquery>
	<cfelse>
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			DELETE FROM #tbl# 
			where #fld# = '#origData#'
			<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
				 AND collection_cde='#origcollection_cde#'
			</cfif>
		</cfquery>
	</cfif>
	<cflocation url="CodeTableEditor.cfm?action=edit&tbl=#tbl#" addtoken="false">
<cfelseif action is "saveEdit">
	<cfif tbl is "ctpublication_attribute">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update ctpublication_attribute set 
				publication_attribute=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_attribute#">,
				DESCRIPTION=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">,
				control=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#control#">
			where
				publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctnomenclatural_code">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update ctnomenclatural_code set 
				nomenclatural_code=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nomenclatural_code#">,
				DESCRIPTION=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">,
				sort_order=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#sort_order#">
			where
				nomenclatural_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctguid_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update ctguid_type set 
				GUID_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid_type#" />,
				description= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				applies_to= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#applies_to#" />,
				search_uri = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#search_uri#" />,
				placeholder= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#placeholder#" />,
				pattern_regex= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern_regex#" />,
				resolver_regex= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#resolver_regex#" />,
				resolver_replacement= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#resolver_replacement#" />
			where
				GUID_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctloan_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update ctloan_type set 
				LOAN_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_type#" />,
				SCOPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scope#" />,
				ORDINAL= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />
			where
				LOAN_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctcountry_code">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update ctcountry_code set 
				COUNTRY= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#country#" />,
				CODE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#code#" />
			where
				COUNTRY= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctspecific_permit_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update ctspecific_permit_type set 
				SPECIFIC_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#specific_type#" />,
				PERMIT_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#" />,
				ACCN_SHOW_ON_SHIPMENT= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accn_show_on_shipment#" />
			where
				SPECIFIC_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctbiol_relations">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update ctbiol_relations set 
				BIOL_INDIV_RELATIONSHIP= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#biol_indiv_relationship#" />,
				INVERSE_RELATION= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inverse_relation#" />,
				REL_TYPE= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rel_type#" />
			where
				BIOL_INDIV_RELATIONSHIP= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctcitation_type_status">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update ctcitation_type_status set 
				TYPE_STATUS= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type_status#" />,
				CATEGORY= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#category#" />,
				ORDINAL= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />,
				DESCRIPTION= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			where
				TYPE_STATUS= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctcoll_other_id_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update ctcoll_other_id_type set 
				OTHER_ID_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#other_id_type#" />,
				DESCRIPTION= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				BASE_URL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#base_url#" />
			where
				OTHER_ID_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctattribute_code_tables">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE ctattribute_code_tables SET
				Attribute_type = '#Attribute_type#',
				value_code_table = '#value_code_table#',
				units_code_table = '#units_code_table#'
			WHERE
				Attribute_type = '#oldAttribute_type#' AND
				value_code_table = '#oldvalue_code_table#' AND
				units_code_table = '#oldunits_code_table#'
		</cfquery>
	<cfelseif tbl is "ctspecimen_part_list_order">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE ctspecimen_part_list_order SET
				partname = '#partname#',
				list_order = '#list_order#'
			WHERE
				partname = '#oldpartname#' AND
				list_order = '#oldlist_order#'
		</cfquery>
	<cfelse>
		<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE #tbl# SET #fld# = '#thisField#'
			<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
				,collection_cde='#collection_cde#'
			</cfif>
			<cfif isdefined("description")>
				,description='#description#'
			</cfif>
			where #fld# = '#origData#'
			<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
				 AND collection_cde='#origcollection_cde#'
			</cfif>
		</cfquery>
	</cfif>
	<cflocation url="CodeTableEditor.cfm?action=edit&tbl=#tbl#" addtoken="false">
<cfelseif action is "newValue">
	<cfif tbl is "ctpublication_attribute">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into ctpublication_attribute (
				publication_attribute,
				DESCRIPTION,
				control
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#newData#'>,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#description#'>,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#control#'>
			)
		</cfquery>
	<cfelseif tbl is "ctnomenclatural_code">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into ctnomenclatural_code(
				nomenclatural_code,
				DESCRIPTION,
				sort_order
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#newData#'>,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#description#'>,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#sort_order#'>
			)
		</cfquery>
	<cfelseif tbl is "ctguid_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into ctguid_type (
				 guid_type, description, applies_to, search_uri, placeholder, pattern_regex, resolver_regex, resolver_replacement
			) VALUES (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#applies_to#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#search_uri#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#placeholder#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern_regex#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#resolver_regex#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#resolver_replacement#" />
			)
		</cfquery>
	<cfelseif tbl is "ctloan_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into ctloan_type (
				loan_type,
				scope,
				ordinal
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scope#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />
			)
		</cfquery>
	<cfelseif tbl is "ctcountry_code">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into ctcountry_code (
				country,
				code
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#code#" />
			)
		</cfquery>
	<cfelseif tbl is "ctspecific_permit_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into ctspecific_permit_type (
				specific_type,
				permit_type,
				accn_show_on_shipment
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accn_show_on_shipment#" />
			)
		</cfquery>
	<cfelseif tbl is "ctbiol_relations">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into ctbiol_relations (
				biol_indiv_relationship,
				inverse_relation,
				rel_type
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inverse_relation#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rel_type#" />
			)
		</cfquery>
	<cfelseif tbl is "ctcoll_other_id_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into ctcoll_other_id_type (
				OTHER_ID_TYPE,
				DESCRIPTION,
				base_URL
			) values (
				'#newData#',
				'#description#',
				'#base_url#'
			)
		</cfquery>
	<cfelseif tbl is "ctattribute_code_tables">
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO ctattribute_code_tables (
				Attribute_type
				<cfif len(#value_code_table#) gt 0>
					,value_code_table
				</cfif>
				<cfif len(#units_code_table#) gt 0>
					,units_code_table
				</cfif>
				)
			VALUES (
				'#Attribute_type#'
				<cfif len(#value_code_table#) gt 0>
					,'#value_code_table#'
				</cfif>
				<cfif len(#units_code_table#) gt 0>
					,'#units_code_table#'
				</cfif>
			)
		</cfquery>
	<cfelseif tbl is "ctspecimen_part_list_order">
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO ctspecimen_part_list_order (
				partname,
				list_order
				)
			VALUES (
				'#partname#',
				#list_order#
			)
		</cfquery>
	<cfelse>
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO #tbl# 
				(#fld#
				<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
					 ,collection_cde
				</cfif>
				<cfif isdefined("description") and len(description) gt 0>
					 ,description
				</cfif>
				)
			VALUES 
				('#newData#'
				<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
					 , <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#collection_cde#'>
				</cfif>
				<cfif isdefined("description") and len(description) gt 0>
					 , <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#description#'>
				</cfif>
			)
		</cfquery>
	</cfif>
	<cflocation url="CodeTableEditor.cfm?action=edit&tbl=#tbl#" addtoken="false">
</cfif>
</cfoutput>
<cfinclude template="includes/_footer.cfm">
