<cfset pageTitle = "Search Specimen | Basic">
<cfinclude template = "/shared/_header.cfm">
 <div id="overlaycontainer" style="position: relative;">
		<main id="content" class="container-fluid">
			<div class="row mr-0 mr-md-3 mr-xl-5">
				<div class="col-12 mt-1 pb-3 mr-0 mr-md-3 mr-xl-5">
					
					
					<h1 class="h3 smallcaps mb-1 pl-3">Find Specimen Records <span class="count  font-italic color-green mx-0"><small> 2405247 records</small><small class="sr-only">Tab into search form</small></span></h1>
					
					<div id="downloadAgreeDialogDiv"></div>
					
					<div class="tabs card-header tab-card-header px-2 pt-3">
						
							
							<script>
								$(document).ready(function() {
									if (window.innerWidth <= 600) { 
										$("#keywordSearchTabButton").trigger("click");
									}
								});
							</script>
						
						<div class="tab-headers px-0 tabList" role="tablist" aria-label="search panel tabs">
							<button class="col-3 col-md-2 px-2 my-0 active" id="basicSearchTabButton" tabid="1" role="tab" aria-controls="fixedSearchPanel" aria-selected="true" tabindex="0">Basic Search</button>
							<button class="col-3 col-xl-2 px-1 my-0 " id="keywordSearchTabButton" tabid="2" role="tab" aria-controls="keywordSearchPanel" aria-selected="false" tabindex="-1">Keyword Search</button>
							<button class="col-3 col-xl-2 px-1 my-0 " id="builderSearchTabButton" tabid="3" role="tab" aria-controls="builderSearchPanel" aria-selected="false" tabindex="-1" aria-label="search builder tab">Search Builder</button>
						</div>
						<div class="tab-content mt-0 px-0 pb-0">
							
							<section id="fixedSearchPanel" role="tabpanel" aria-labelledby="basicSearchTabButton" tabindex="0" class="mx-0 active unfocus">
								<div class="col-9 float-right px-0"> 
									<button class="btn btn-xs btn-dark help-btn border-0" type="button" data-toggle="collapse" data-target="#collapseFixed" aria-expanded="false" aria-controls="collapseFixed">
										Search Help
									</button>
									<aside class="collapse collapseStyle" id="collapseFixed">
										<div class="card card-body pl-4 py-3 pr-3 border-dark">
											<h2 class="headerSm">Basic Search Help</h2>
											<p>
												This help applies to the basic specimen search and some other search forms in MCZbase.
												Many fields are autocompletes, values can be selected off of the picklist, or a partial match can be entered in the field.
												Most fields will accept search operators, described below, which alter the behaviour of the search.
												 
													(see: <a href="https://code.mcz.harvard.edu/wiki/index.php/Search_Operators" target="_blank">Search Operators</a>). For more examples, see: <a href="https://code.mcz.harvard.edu/wiki/index.php/Basic_Specimen_Search" target="_blank">Basic Specimen Search</a>
												.
											</p>
											<h2 class="headerSm">Special operators that are entered in the field by themselves with no other value</h2>
											<dl class="mb-0"> 
												<dt><span class="text-info font-weight-bold">NULL</span></dt>
												<dd>Find records where this field is empty.</dd>
												<dt><span class="text-info font-weight-bold">NOT NULL</span></dt>
												<dd>Find records where this field contains some non-empty value.</dd>
											</dl>
											<h2 class="headerSm">Operators entered as the first character in a field, followed by a search term (e.g. =Murex). </h2>
											<dl class="mb-0"> 
												<dt><span class="text-info font-weight-bold">=</span></dt>
												<dd>Perform a (case insensitive, in most cases) exact match search. Fields which take this operator append a wild card to the beginning and end of the search term unless this operator is used.</dd>
												<dt><span class="text-info font-weight-bold">!</span></dt>
												<dd>Perform a (case insensitive, in most cases) exact match <strong>not</strong> search. Will find records where the value in the field does not match the specified search term. </dd>
												<dt><span class="text-info font-weight-bold">~</span></dt>
												<dd>Find nearby strings. Finds matches where the value in the field is a small number of character substitutions away from the provided search term. Makes the comparison using the jaro winkler string distance, with a threshold set, depending on the search, on 0.80 or 0.90.</dd> 
												<dt><span class="text-info font-weight-bold">$</span> </dt>
												<dd> Find sound alike strings. Finds matches where the value in the field sounds like the provided search term. Makes the comparison using the soundex algorithm.</dd>
											</dl>
											<h2 class="headerSm">Wild cards that may be accepted where a search can take a = operator, but that operator is not used.</h2>
											<dl class="mb-0"> 
												<dt><span class="text-info font-weight-bold">%</span></dt>
												<dd>Match any number of characters. (added at the beginning and end of strings for all fields that can take an = operator where that operator is not used).</dd>
												<dt><span class="text-info font-weight-bold">_</span></dt> 
												<dd>Match exactly one character.</dd>
											</dl>
											<h2 class="headerSm">Guidance for specific fields</h2>
											<dl class="mb-0"> 
												<dt><span class="text-info font-weight-bold">Catalog Number</span></dt>
												<dd>Catalog number accepts single numbers (e.g. 1100), ranges of numbers (e.g. 100-110), comma (or space) separated lists of number (or search, e.g. 100,110), ranges of numbers with prefixes (e.g. R-200-210 or R-200-R-210), or ranges of numbers with suffixes (e.g. 1-a-50 or 1-a-50-a).  Wildcards are not added to catalog number searches (so =1 and 1 return the same result).  To search with wildcards or to limit both prefixes and suffixes, use the search builder.  The shorthand form R200-210 will work without a - separating the prefix from the range, but R200 will not. </dd>
												<dt><span class="text-info font-weight-bold">Other Number</span></dt> 
												<dd>Other number accepts single numbers, ranges of numbers, comma (or space) separated lists of numbers, and ranges of numbers, but for most cases with prefixes, search for just a single prefixed number with an exact match search (e.g. =BT-782).  If your other number contains a space, replace that space with an underscore, e.g. search for "PMAE: 26-7-10/%" using "PMAE:_26-7-10/%".</dd>
												<dt><span class="text-info font-weight-bold">Taxonomy and Higher Geography Fields</span> </dt>
												<dd>Search for a substring (e.g. murex), an exact match (e.g. =Murex), or a comma separated list (e.g. Vulpes,Urocyon).</dd>
												<dt><span class="text-info font-weight-bold">Any Geography (keyword) Field</span> </dt>
												<dd>This field runs a keyword search on a large set of geography fields.  See the Keyword Search Help for guidance.</dd>
												<dt><span class="text-info font-weight-bold">Keyword Search Field</span> </dt>
												<dd>This field does the same thing as the Keyword Search.  See the Keyword Search Help for guidance.</dd>
												<dt><span class="text-info font-weight-bold">Dates</span></dt>
												<dd>Collecting Events are stored in two date fields (date began and date ended), plus a verbatim field.  Date Collected searches on both the began date and end date for collecting events.  A range search on Date Collected (e.g. 1980/1985) will find all cataloged items where both the date began and date ended fall within the specified range.  Usually you will want to search on Date Collected.  The began date and ended date fields can be searched separately for special cases, in particular cases where the collecting date range is poorly constrained.  Search on Began Date 1700-01-01 Ended Date 1800-01-01/1899-12-31 to find all material where the began date is not known, but the end date has been constrained to sometime in the 1800s (contrast with Date Collected 1800-01-01/1899-12-31 which finds material where both the start and end dates are in the 1800s).</dd>
												<dt><span class="text-info font-weight-bold">Media Type</span></dt>
												<dd>Click on (Any) to paste NOT NULL into the field, this will find records where there are any related media.</dd>
												<dt><span class="text-info font-weight-bold">Min/Max Depth/Elevation Fields</span> </dt>
												<dd>Search on depth or elevation converted from original units to meters, accepts 1-10 for ranges or &lt;=1 or &gt;=1 to search for open ended ranges.  Search on minimum depth and maximum depth are independent, likewise for elevation.  To search for all material known to be collected between two depth endpoints search on the same range e.g. 1-10 in minimum and maximum depth fields, this will find all material where the minimum depth is in that range and the maximum depth is in that range, likewise for elevation.  Search Minimum depth for NOT NULL to find any depth value.</dd>
											</dl>
										</div>
									</aside>
								</div>
								<div role="search" class="container-fluid px-0" id="fixedSearchFormDiv">
									<form id="fixedSearchForm">
										
										<input type="hidden" name="result_id" id="result_id_fixedSearch" value="bccaf7ba-be02-413c-8d33-b07b1907767d" class="excludeFromLink">
										<input type="hidden" name="method" id="method_fixedSearch" value="executeFixedSearch" class="keeponclear excludeFromLink">
										<input type="hidden" name="action" value="fixedSearch" class="keeponclear">
										<div class="container-flex" style="display: block;">
											<div class="col-12 form-row mx-0 search-form-basic-odd px-0 pb-2 pb-xl-0">
												 
														
												<div class="col-12 col-xl-2 col-xxl-one col-xxl-1 px-1 mb-1 float-left">
													<div class="pb-0 font-weight-bold d-inline-block-md text-xl-right px-1 w-100 text-left text-md-left text-dark mb-1 mb-md-0 pt-1">
														<h2 class="small mb-0 mx-0 px-2 mx-xl-0 px-xl-0 d-block text-black font-weight-bold">Identifiers</h2>
														
															<button type="button" id="IDDetailCtl" class="d-none d-xl-inline-block px-xl-0 py-0 btn-link text-right btn smaller" onclick="toggleIDDetail(1);">show more <i class="fas fa-caret-down" style="vertical-align: middle;"></i></button>
														
													</div>
												</div>	
												<div class="form-row col-12 col-xxl-eleven col-xxl-11 pt-1 px-1 mx-0 mb-0">
													<div class="col-12 mb-1 col-md-3">
														<label for="fixedCollection" class="data-entry-label small">Collection</label>
														<div name="collection" id="fixedCollection" class="w-100 jqx-combobox-state-normal jqx-combobox jqx-rc-all jqx-widget jqx-widget-content" role="combobox" aria-autocomplete="both" aria-disabled="false" aria-owns="listBoxjqxWidget4a427fb09bd1" aria-haspopup="true" aria-multiline="false" style="height: auto; width: 100%; box-sizing: border-box; min-height: 21px;" aria-readonly="false"><div style="background-color: transparent; appearance: none; outline: none; width: 100%; height: auto; padding: 0px; margin: 0px; border: 0px; position: relative;"><div id="dropdownlistWrapperfixedCollection" style="padding: 0px; margin: 0px; border: none; background-color: transparent; float: left; width: 100%; height: auto; position: relative;"><div id="dropdownlistContentfixedCollection" style="padding: 0px; margin: 0px; border-top: none; border-bottom: none; float: left; position: relative; width: 258px; height: auto; left: 0px; top: 0px; cursor: text; min-height: 21px;" class="jqx-combobox-content jqx-widget-content"><input autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="box-sizing: border-box; margin: 2.5px 0px 0px; padding: 0px 3px; border: 0px; width: 100%; float: left;" type="textarea" class="jqx-combobox-input jqx-widget-content jqx-rc-all" placeholder=""></div><div id="dropdownlistArrowfixedCollection" role="button" style="padding: 0px; margin: 0px; border-width: 0px 0px 0px 1px; float: right; position: absolute; height: 21px; width: 17px; left: 259px;" class="jqx-combobox-arrow-normal jqx-fill-state-normal jqx-rc-r"><div class="jqx-icon-arrow-down jqx-icon"></div></div><label class="jqx-input-label"></label><span class="jqx-input-bar" style="top: 21px;"></span></div></div><input type="hidden" name="collection" value=""></div>
														
														<script>
															function setFixedCollectionValues() {
																$('#fixedCollection').jqxComboBox('clearSelection');
																
															};
															$(document).ready(function () {
																var collectionsource = [
																	{name:"Cryogenic",cde:"Cryo"}
																		,{name:"Entomology",cde:"Ent"}
																		,{name:"Herpetology",cde:"Herp"}
																		,{name:"Herpetology Observations",cde:"HerpOBS"}
																		,{name:"Ichthyology",cde:"Ich"}
																		,{name:"Invertebrate Paleontology",cde:"IP"}
																		,{name:"Invertebrate Zoology",cde:"IZ"}
																		,{name:"MCZ Collections",cde:"MCZ"}
																		,{name:"Malacology",cde:"Mala"}
																		,{name:"Mammalogy",cde:"Mamm"}
																		,{name:"Ornithology",cde:"Orn"}
																		,{name:"Special Collections",cde:"SC"}
																		,{name:"Vertebrate Paleontology",cde:"VP"}
																		
																];
																$("#fixedCollection").jqxComboBox({ source: collectionsource, displayMember:"name", valueMember:"cde", multiSelect: true, height: '21px', width: '100%' });
																setFixedCollectionValues();
															});
														</script> 
													</div>
													<div class="col-12 mb-1 col-md-3">
														
														<label for="catalogNum" class="data-entry-label small">Catalog Number</label>
														<input id="catalogNum" type="text" name="cat_num" class="data-entry-input small inputHeight" placeholder="1,1-4,A-1,R1-4" value="">
													</div>
													
													<div class="col-12 mb-1 col-md-2">
														
														<label for="otherID" class="data-entry-label small">Other ID Type</label>
														<div name="other_id_type" id="other_id_type" class="w-100 jqx-combobox-state-normal jqx-combobox jqx-rc-all jqx-widget jqx-widget-content" role="combobox" aria-autocomplete="both" aria-disabled="false" aria-owns="listBoxjqxWidget22446a0c75ee" aria-haspopup="true" aria-multiline="false" style="height: auto; width: 100%; box-sizing: border-box; min-height: 21px;" aria-readonly="false"><div style="background-color: transparent; appearance: none; outline: none; width: 100%; height: auto; padding: 0px; margin: 0px; border: 0px; position: relative;"><div id="dropdownlistWrapperother_id_type" style="padding: 0px; margin: 0px; border: none; background-color: transparent; float: left; width: 100%; height: auto; position: relative;"><div id="dropdownlistContentother_id_type" style="padding: 0px; margin: 0px; border-top: none; border-bottom: none; float: left; position: relative; width: 162px; height: auto; left: 0px; top: 0px; cursor: text; min-height: 21px;" class="jqx-combobox-content jqx-widget-content"><input autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="box-sizing: border-box; margin: 2.5px 0px 0px; padding: 0px 3px; border: 0px; width: 100%; float: left;" type="textarea" class="jqx-combobox-input jqx-widget-content jqx-rc-all" placeholder=""></div><div id="dropdownlistArrowother_id_type" role="button" style="padding: 0px; margin: 0px; border-width: 0px 0px 0px 1px; float: right; position: absolute; height: 21px; width: 17px; left: 163px;" class="jqx-combobox-arrow-normal jqx-fill-state-normal jqx-rc-r"><div class="jqx-icon-arrow-down jqx-icon"></div></div><label class="jqx-input-label"></label><span class="jqx-input-bar" style="top: 21px;"></span></div></div><input type="hidden" name="other_id_type" value=""></div>
														
														<script>
															function setOtherIdTypeValues() {
																$('#other_id_type').jqxComboBox('clearSelection');
																
															};
															$(document).ready(function () {
																var otheridtypesource = [
																	{name:"AE Verrill number",meta:"AE Verrill number (429)"}
																		,{name:"BHI number",meta:"BHI number (23909)"}
																		,{name:"BOLD processID",meta:"BOLD processID (135)"}
																		,{name:"BSNH Catalog Number",meta:"BSNH Catalog Number (1461)"}
																		,{name:"California Academy of Sciences Herpetology Number",meta:"California Academy of Sciences Herpetology Number (1)"}
																		,{name:"Chromosome Catalog Number",meta:"Chromosome Catalog Number (1399)"}
																		,{name:"DD Thaanum number",meta:"DD Thaanum number (3302)"}
																		,{name:"DNA Reference Code",meta:"DNA Reference Code (6926)"}
																		,{name:"Data Release (doi)",meta:"Data Release (doi) (1)"}
																		,{name:"Event Code",meta:"Event Code (524)"}
																		,{name:"Gorongosa Restoration Project number",meta:"Gorongosa Restoration Project number (2)"}
																		,{name:"IZ accession number",meta:"IZ accession number (111)"}
																		,{name:"Identifier Code",meta:"Identifier Code (281)"}
																		,{name:"J.H. Sandground jar number",meta:"J.H. Sandground jar number (960)"}
																		,{name:"MUSE locality number",meta:"MUSE locality number (93597)"}
																		,{name:"NCBI BioProject number",meta:"NCBI BioProject number (301)"}
																		,{name:"NCBI BioSample number",meta:"NCBI BioSample number (536)"}
																		,{name:"NCBI GenBank number",meta:"NCBI GenBank number (19376)"}
																		,{name:"NCBI SRA number",meta:"NCBI SRA number (1604)"}
																		,{name:"NPS catalog number",meta:"NPS catalog number (34)"}
																		,{name:"Scheltema jar number",meta:"Scheltema jar number (5309)"}
																		,{name:"Student Paleontology Collection",meta:"Student Paleontology Collection (1056)"}
																		,{name:"Ward Number (1878)",meta:"Ward Number (1878) (469)"}
																		,{name:"additional number",meta:"additional number (111087)"}
																		,{name:"autopsy number",meta:"autopsy number (1135)"}
																		,{name:"collection number",meta:"collection number (6259)"}
																		,{name:"collector number",meta:"collector number (343142)"}
																		,{name:"collector number 2",meta:"collector number 2 (10794)"}
																		,{name:"counterpart number",meta:"counterpart number (1274)"}
																		,{name:"cruise number",meta:"cruise number (6307)"}
																		,{name:"dive number",meta:"dive number (2764)"}
																		,{name:"donor number",meta:"donor number (503)"}
																		,{name:"dredging number",meta:"dredging number (392)"}
																		,{name:"egg set mark",meta:"egg set mark (10495)"}
																		,{name:"field number",meta:"field number (286073)"}
																		,{name:"from same lot as",meta:"from same lot as (48)"}
																		,{name:"genitalia number",meta:"genitalia number (208)"}
																		,{name:"group number",meta:"group number (177660)"}
																		,{name:"iNaturalist Observation ID",meta:"iNaturalist Observation ID (13)"}
																		,{name:"lot number",meta:"lot number (4080)"}
																		,{name:"malacology accession number",meta:"malacology accession number (296481)"}
																		,{name:"material sample",meta:"material sample (1)"}
																		,{name:"muse location number",meta:"muse location number (324629)"}
																		,{name:"original ledger number",meta:"original ledger number (34010)"}
																		,{name:"original number",meta:"original number (35563)"}
																		,{name:"ornithology jar number",meta:"ornithology jar number (1217)"}
																		,{name:"other number",meta:"other number (76074)"}
																		,{name:"preparator number",meta:"preparator number (1590)"}
																		,{name:"previous number",meta:"previous number (285669)"}
																		,{name:"rdt jar number",meta:"rdt jar number (8611)"}
																		,{name:"researcher code",meta:"researcher code (9894)"}
																		,{name:"serial number",meta:"serial number (5)"}
																		,{name:"specimen code",meta:"specimen code (63511)"}
																		,{name:"station number",meta:"station number (77715)"}
																		,{name:"type number",meta:"type number (58986)"}
																		,{name:"voucher number",meta:"voucher number (366)"}
																		,{name:"whoi jar number",meta:"whoi jar number (5642)"}
																		
																];
																$("#other_id_type").jqxComboBox({ source: otheridtypesource, displayMember:"meta", valueMember:"name", multiSelect: true, height: '21px', width: '100%' });
																setOtherIdTypeValues();
															});
														</script> 
													</div>
													<div class="col-12 mb-1 col-md-2">
														
														<label for="other_id_number" class="data-entry-label small">Other ID Numbers</label>
														<input type="text" class="data-entry-input small inputHeight" id="other_id_number" name="other_id_number" placeholder="10,20-30,=BT-782" value="">
													</div>
													
														<div class="col-12 mb-1 col-md-2">
															<label class="data-entry-label small" for="debug1">Debug JSON</label>
															<select title="debug" name="debug" id="debug1" class="data-entry-select smaller inputHeight">
																<option value=""></option>
																
																<option value="true">Debug JSON</option>
															</select>
														</div>
													
													<button type="button" id="IDDetailCtl1" class="d-block d-xl-none border m-1 d-xl-none py-1 btn-link w-100 text-center btn small" onclick="toggleIDDetail(1)"><span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;"></i></span></button>
																
													<div id="IDDetail" class="col-12 px-0" style="display:none;">
													<div class="form-row col-12 col-md-12 px-0 mx-0 mb-0">
														<div class="col-12 mb-1 col-md-3">
															
															<label for="otherID" class="data-entry-label small">or Other ID Type</label>
															<div name="other_id_type_1" id="other_id_type_1" class="w-100 jqx-combobox-state-normal jqx-combobox jqx-rc-all jqx-widget jqx-widget-content" role="combobox" aria-autocomplete="both" aria-disabled="false" aria-owns="listBoxjqxWidgetaa4cd6739229" aria-haspopup="true" aria-multiline="false" style="height: auto; width: 100%; box-sizing: border-box; min-height: 21px;" aria-readonly="false"><div style="background-color: transparent; appearance: none; outline: none; width: 100%; height: auto; padding: 0px; margin: 0px; border: 0px; position: relative;"><div id="dropdownlistWrapperother_id_type_1" style="padding: 0px; margin: 0px; border: none; background-color: transparent; float: left; width: 100%; height: auto; position: relative;"><div id="dropdownlistContentother_id_type_1" style="padding: 0px; margin: 0px; border-top: none; border-bottom: none; float: left; position: relative; height: auto; left: 0px; top: 0px; cursor: text; min-height: 21px;" class="jqx-combobox-content jqx-widget-content"><input autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="box-sizing: border-box; margin: 2.5px 0px 0px; padding: 0px 3px; border: 0px; width: 100%; float: left;" type="textarea" class="jqx-combobox-input jqx-widget-content jqx-rc-all" placeholder=""></div><div id="dropdownlistArrowother_id_type_1" role="button" style="padding: 0px; margin: 0px; border-width: 0px 0px 0px 1px; float: right; position: absolute; height: 0px; width: 17px; left: -19px;" class="jqx-combobox-arrow-normal jqx-fill-state-normal jqx-rc-r"><div class="jqx-icon-arrow-down jqx-icon"></div></div><label class="jqx-input-label"></label><span class="jqx-input-bar" style="top: -2px;"></span></div></div><input type="hidden" name="other_id_type_1" value=""></div>
															
															<script>
																function setOtherIdType_1_Values() {
																	$('#other_id_type_1').jqxComboBox('clearSelection');
																	
																};
																$(document).ready(function () {
																	var otheridtypesource = [
																		{name:"AE Verrill number",meta:"AE Verrill number (429)"}
																			,{name:"BHI number",meta:"BHI number (23909)"}
																			,{name:"BOLD processID",meta:"BOLD processID (135)"}
																			,{name:"BSNH Catalog Number",meta:"BSNH Catalog Number (1461)"}
																			,{name:"California Academy of Sciences Herpetology Number",meta:"California Academy of Sciences Herpetology Number (1)"}
																			,{name:"Chromosome Catalog Number",meta:"Chromosome Catalog Number (1399)"}
																			,{name:"DD Thaanum number",meta:"DD Thaanum number (3302)"}
																			,{name:"DNA Reference Code",meta:"DNA Reference Code (6926)"}
																			,{name:"Data Release (doi)",meta:"Data Release (doi) (1)"}
																			,{name:"Event Code",meta:"Event Code (524)"}
																			,{name:"Gorongosa Restoration Project number",meta:"Gorongosa Restoration Project number (2)"}
																			,{name:"IZ accession number",meta:"IZ accession number (111)"}
																			,{name:"Identifier Code",meta:"Identifier Code (281)"}
																			,{name:"J.H. Sandground jar number",meta:"J.H. Sandground jar number (960)"}
																			,{name:"MUSE locality number",meta:"MUSE locality number (93597)"}
																			,{name:"NCBI BioProject number",meta:"NCBI BioProject number (301)"}
																			,{name:"NCBI BioSample number",meta:"NCBI BioSample number (536)"}
																			,{name:"NCBI GenBank number",meta:"NCBI GenBank number (19376)"}
																			,{name:"NCBI SRA number",meta:"NCBI SRA number (1604)"}
																			,{name:"NPS catalog number",meta:"NPS catalog number (34)"}
																			,{name:"Scheltema jar number",meta:"Scheltema jar number (5309)"}
																			,{name:"Student Paleontology Collection",meta:"Student Paleontology Collection (1056)"}
																			,{name:"Ward Number (1878)",meta:"Ward Number (1878) (469)"}
																			,{name:"additional number",meta:"additional number (111087)"}
																			,{name:"autopsy number",meta:"autopsy number (1135)"}
																			,{name:"collection number",meta:"collection number (6259)"}
																			,{name:"collector number",meta:"collector number (343142)"}
																			,{name:"collector number 2",meta:"collector number 2 (10794)"}
																			,{name:"counterpart number",meta:"counterpart number (1274)"}
																			,{name:"cruise number",meta:"cruise number (6307)"}
																			,{name:"dive number",meta:"dive number (2764)"}
																			,{name:"donor number",meta:"donor number (503)"}
																			,{name:"dredging number",meta:"dredging number (392)"}
																			,{name:"egg set mark",meta:"egg set mark (10495)"}
																			,{name:"field number",meta:"field number (286073)"}
																			,{name:"from same lot as",meta:"from same lot as (48)"}
																			,{name:"genitalia number",meta:"genitalia number (208)"}
																			,{name:"group number",meta:"group number (177660)"}
																			,{name:"iNaturalist Observation ID",meta:"iNaturalist Observation ID (13)"}
																			,{name:"lot number",meta:"lot number (4080)"}
																			,{name:"malacology accession number",meta:"malacology accession number (296481)"}
																			,{name:"material sample",meta:"material sample (1)"}
																			,{name:"muse location number",meta:"muse location number (324629)"}
																			,{name:"original ledger number",meta:"original ledger number (34010)"}
																			,{name:"original number",meta:"original number (35563)"}
																			,{name:"ornithology jar number",meta:"ornithology jar number (1217)"}
																			,{name:"other number",meta:"other number (76074)"}
																			,{name:"preparator number",meta:"preparator number (1590)"}
																			,{name:"previous number",meta:"previous number (285669)"}
																			,{name:"rdt jar number",meta:"rdt jar number (8611)"}
																			,{name:"researcher code",meta:"researcher code (9894)"}
																			,{name:"serial number",meta:"serial number (5)"}
																			,{name:"specimen code",meta:"specimen code (63511)"}
																			,{name:"station number",meta:"station number (77715)"}
																			,{name:"type number",meta:"type number (58986)"}
																			,{name:"voucher number",meta:"voucher number (366)"}
																			,{name:"whoi jar number",meta:"whoi jar number (5642)"}
																			
																	];
																	$("#other_id_type_1").jqxComboBox({ source: otheridtypesource, displayMember:"meta", valueMember:"name", multiSelect: true, height: '21px', width: '100%' });
																	setOtherIdType_1_Values();
																});
															</script> 
															</div>
															<div class="col-12 mb-1 col-md-3">
																
																<label for="other_id_number_1" class="data-entry-label small">Other ID Numbers</label>
																<input type="text" class="data-entry-input inputHeight" id="other_id_number_1" name="other_id_number_1" placeholder="10,20-30,=BT-782" value="">
															</div>
															<div class="col-12 mb-1 col-md-6">
															</div>
														</div>
													</div>
												</div>
											</div>
											<div class="col-12 form-row mx-0 px-0 pb-2 pb-xl-0">
												
												<div class="col-12 col-xl-2 col-xxl-one col-xxl-1 px-1 mb-1">
													<div class="pb-0 font-weight-bold d-inline-block-md text-xl-right px-1 w-100 pt-1 text-left text-dark mb-0">
														<h2 class="small mb-0 mx-0 px-2 px-xl-0 mx-xl-0 d-block text-black font-weight-bold">Taxonomy</h2>
														<button type="button" id="TaxaDetailCtl" class="d-none d-xl-inline-block px-xl-0 py-0 btn-link text-right btn smaller" onclick="toggleTaxaDetail(1);">show more <i class="fas fa-caret-down" style="vertical-align: middle;"></i></button>
													</div>
												</div>
												<div class="form-row col-12 col-xxl-eleven col-xxl-11 pt-1 px-1 mx-0 mb-0">
													<div class="col-12 mb-1 col-md-4 pr-0">
														<div class="form-row mx-0 mb-0">
															<div class="col-9 px-0">
																
																<label for="any_taxa_term" class="data-entry-label small">Any Taxonomic Element</label>
																<input id="any_taxa_term" name="any_taxa_term" class="data-entry-input inputHeight" aria-label="any taxonomy" value="">
															</div>
															<div class="col-3">
																
																<label for="current_id_only" class="data-entry-label small">Search</label>
																<select id="current_id_only" name="current_id_only" class="data-entry-select inputHeight small px-0">
																	
																	<option value="any" selected="">Any Id</option>
																	<option value="current">Current Id Only</option>
																</select>
															</div>
														</div>
													</div>
													<div class="col-12 mb-1 col-md-3">
														<label for="scientific_name" class="data-entry-label small">Scientific Name</label>
														
														<input type="text" id="scientific_name" name="scientific_name" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
														<input type="hidden" id="taxon_name_id" name="taxon_name_id" value="">
														<script>
															jQuery(document).ready(function() {
																makeScientificNameAutocompleteMeta('scientific_name','taxon_name_id');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														<label for="author_text" class="data-entry-label small">Authorship</label>
														
														<input id="author_text" name="author_text" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																makeTaxonSearchAutocomplete('author_text','author_text');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-2">
														<label for="type_status" class="data-entry-label small">Type Status/Citation
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('#type_status').autocomplete('search','%%%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
														</label>
														
														<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="type_status" name="type_status" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																makeTypeStatusSearchAutocomplete('type_status');
															});
														</script>
													</div>
													<button type="button" id="TaxaDetailCtl1" class="d-block d-xl-none border m-1 d-xl-none py-1 btn-link w-100 text-center btn small" onclick="toggleTaxaDetail(1)"><span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;"></i></span></button>
														
													<div id="TaxaDetail" class="col-12 px-0" style="display:none;">
														<div class="form-row col-12 col-md-12 px-0 mx-0 mb-0">
															<div class="col-12 mb-1 col-md-2">
																<label for="phylum" class="data-entry-label small">Phylum
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('#phylum').autocomplete('search','%%%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
																</label>
																
																<input id="phylum" name="phylum" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('phylum','phylum');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="phylclass" class="data-entry-label small">Class</label>
																
																<input id="phylclass" name="phylclass" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('phylclass','class');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="phylorder" class="data-entry-label small">Order</label>
																
																<input id="phylorder" name="phylorder" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('phylorder','order');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="family" class="data-entry-label small">Family</label>
																
																<input type="text" id="family" name="family" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('family','family');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="genus" class="data-entry-label small">Genus</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="genus" name="genus" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('genus','genus');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="species" class="data-entry-label small">Specific Name</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="species" name="species" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('species','species');
																	});
																</script>
															</div>
															
														</div>
														<div class="form-row col-12 col-md-12 px-0 mx-0 mb-0">
															<div class="col-12 mb-1 col-md-2">
																<label for="determiner" class="data-entry-label small">Determiner</label>
																
																<input type="hidden" id="determiner_id" name="determiner_id" class="data-entry-input" value="">
																<input type="text" id="determiner" name="determiner" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeConstrainedAgentPicker('determiner', 'determiner_id', 'determiner');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-4">
																<label for="publication_id" class="data-entry-label small">Cited In</label>
																
																<input type="hidden" id="publication_id" name="publication_id" class="data-entry-input inputHeight" value="">
																<input type="text" id="citation" name="citation" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makePublicationPicker('citation','publication_id');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="nature_of_id" class="data-entry-label small">Nature Of Id</label>
																
																<select title="nature of id" name="nature_of_id" id="nature_of_id" class="data-entry-select inputHeight col-sm-12 pl-2">
																	<option value=""></option>
																	
																		<option value="=ID based on geography">ID based on geography (2309)</option>
																	
																		<option value="=ID based on molecular data">ID based on molecular data (3155)</option>
																	
																		<option value="=ID to species group">ID to species group (37)</option>
																	
																		<option value="=curatorial ID">curatorial ID (3342)</option>
																	
																		<option value="=erroneous citation">erroneous citation (120)</option>
																	
																		<option value="=erroneous on label">erroneous on label (435)</option>
																	
																		<option value="=expert ID">expert ID (715599)</option>
																	
																		<option value="=field ID">field ID (12816)</option>
																	
																		<option value="=legacy">legacy (307615)</option>
																	
																		<option value="=migration">migration (1613524)</option>
																	
																		<option value="=non-expert ID">non-expert ID (7729)</option>
																	
																		<option value="=revised taxonomy">revised taxonomy (87180)</option>
																	
																		<option value="=sp. based on geog.">sp. based on geog. (197)</option>
																	
																		<option value="=ssp. based on geog.">ssp. based on geog. (3913)</option>
																	
																		<option value="=type ID">type ID (90643)</option>
																	
																</select>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="identification_remarks" class="data-entry-label small">Id Remarks</label>
																
																<input type="text" class="data-entry-input inputHeight" id="identification_remarks" name="identification_remarks" value="">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="common_name" class="data-entry-label small">Common Name</label>
																
																<input type="text" class="data-entry-input inputHeight" id="common_name" name="common_name" value="">
															</div>
														</div>
													</div>
												</div>
											</div> 
											<div class="col-12 form-row mx-0 search-form-basic-odd px-0 pb-2 pb-xl-0">
												
												<div class="col-12 col-xl-2 col-xxl-one col-xxl-1 px-1 mb-1 float-left">
													<div class="pb-0 font-weight-bold d-inline-block-md text-xl-right px-1 w-100 text-left text-md-left text-dark mb-1 mb-md-0 pt-1">
														<h2 class="small mb-0 mx-0 px-2 mx-xl-0 px-xl-0 d-block text-black font-weight-bold">Geography</h2>
														<button type="button" id="GeogDetailCtl" class="d-none d-xl-inline-block px-xl-0 py-0 btn-link text-right btn smaller" onclick="toggleGeogDetail(1);">show more <i class="fas fa-caret-down" style="vertical-align: middle;"></i></button>
													</div>
												</div>
												<div class="form-row col-12 col-xxl-eleven col-xxl-11 pt-1 px-1 mx-0 mb-0">
													<div class="col-12 mb-1 col-md-4">
														
														<label for="any_geography" class="data-entry-label small">Any Geography (keywords)</label>
														<input type="text" class="data-entry-input inputHeight" name="any_geography" id="any_geography" value="">
													</div>
													<div class="col-12 mb-1 col-md-4">
														
														<label for="higher_geog" class="data-entry-label small">Higher Geography</label>
														<input type="text" class="data-entry-input inputHeight" name="higher_geog" id="higher_geog" value="">
													</div>
													<div class="col-12 mb-1 col-md-4">
														<label for="spec_locality" class="data-entry-label small">Specific Locality</label>
														
														<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="spec_locality" name="spec_locality" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																makeSpecLocalitySearchAutocomplete('spec_locality',);
															});
														</script>
													</div>
													<button type="button" id="GeogDetailCtl1" class="d-block d-xl-none w-100 py-1 m-1 border btn-link text-center btn small" onclick="toggleGeogDetail(1);">show more <i class="fas fa-caret-down" style="vertical-align: middle;"></i></button>
													<div id="GeogDetail" class="col-12 px-0" style="display:none;">
														<div class="form-row col-12 col-md-12 px-0 mb-0 mx-0">
															<div class="col-12 mb-1 col-md-3">
																
																<label for="continent_ocean" class="data-entry-label small">Continent/Ocean</label>
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" name="continent_ocean" id="continent_ocean" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('continent_ocean','continent_ocean');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="country" class="data-entry-label small">Country</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="country" name="country" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeCountrySearchAutocomplete('country');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="state_prov" class="data-entry-label small">State/Province</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="state_prov" name="state_prov" aria-label="state or province" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('state_prov','state_prov');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="county" class="data-entry-label small">County/Shire/Parish</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="county" name="county" aria-label="county shire or parish" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('county','county');
																	});
																</script>
															</div>
															
														</div>
														<div class="form-row col-12 col-md-12 px-0 mb-0 mx-0">
															<div class="col-12 mb-1 col-md-2">
																<label for="ocean_region" class="data-entry-label small">Ocean Region</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="ocean_region" name="ocean_region" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('ocean_region','ocean_region');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="ocean_subregion" class="data-entry-label small">Ocean Sub-Region</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="ocean_subregion" name="ocean_subregion" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('ocean_subregion','ocean_subregion');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="sea" class="data-entry-label small">Sea
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('#sea').autocomplete('search','%%%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
																</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="sea" name="sea" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('sea','sea');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="island_group" class="data-entry-label small">Island Group</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="island_group" name="island_group" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('island_group','island_group');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="island" class="data-entry-label small">Island</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="island" name="island" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('island','island');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="feature" class="data-entry-label small">Land Feature</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="feature" name="feature" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('feature','feature');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="water_feature" class="data-entry-label small">Water Feature</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="water_feature" name="water_feature" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('water_feature','water_feature');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="geo_att_value" class="data-entry-label small">Geological Attribute</label>
																
																
																<input type="hidden" id="geology_attribute" name="geology_attribute" value="">
																<input type="hidden" id="geology_attribute_heirarchy_id" name="geology_attribute_heirarchy_id" value="">
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="geo_att_value" name="geo_att_value" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeGeologyAutocompleteMeta('geology_attribute', 'geo_att_value', 'geology_attribute_heirarchy_id', 'search', null);
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="verificationstatus" class="data-entry-label small">
																	Georeference Verification
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#verificationstatus').autocomplete('search','%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
																</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="verificationstatus" name="verificationstatus" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeCTFieldSearchAutocomplete('verificationstatus','VERIFICATIONSTATUS');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="min_depth_in_m" class="data-entry-label small">Miniumum Depth (m)</label>
																
																<input type="text" class="data-entry-input inputHeight" id="min_depth_in_m" name="min_depth_in_m" value="">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="max_depth_in_m" class="data-entry-label small">Maximum Depth (m)</label>
																
																<input type="text" class="data-entry-input inputHeight" id="max_depth_in_m" name="max_depth_in_m" value="">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="min_elev_in_m" class="data-entry-label small">Miniumum Elevation (m)</label>
																
																<input type="text" class="data-entry-input inputHeight" id="min_elev_in_m" name="min_elev_in_m" value="">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="max_elev_in_m" class="data-entry-label small">Maximum Elevation (m)</label>
																
																<input type="text" class="data-entry-input inputHeight" id="max_elev_in_m" name="max_elev_in_m" value="">
															</div>
														</div>
													</div>
												</div>
											</div>
											<div class="col-12 form-row mx-0 px-0 pb-2 pb-xl-0">
												 
												<div class="col-12 col-xl-2 col-xxl-one col-xxl-1 px-1 mb-1 float-left">
													<div class="pb-0 font-weight-bold d-inline-block-md text-xl-right px-1 w-100 text-left text-md-left text-dark mb-1 mb-md-0 pt-1">
														<h2 class="small mb-0 mx-0 px-2 mx-xl-0 px-xl-0 d-block text-black font-weight-bold">Coll. Event</h2>
														<button type="button" id="CollDetailCtl" class="d-none d-xl-inline-block px-xl-0 py-0 btn-link text-right btn smaller" onclick="toggleCollDetail(1);">show more <i class="fas fa-caret-down" style="vertical-align: middle;"></i></button>
													</div>
												</div>				
												<div class="form-row col-12 col-xxl-eleven col-xxl-11 px-1 pt-1 mb-0 mx-0">
													<div class="col-12 mb-1 col-md-3">
														<label for="collector" class="data-entry-label small">Collector</label>
														
														<input type="text" id="collector" name="collector" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
														<input type="hidden" id="collector_agent_id" name="collector_agent_id" value="">
														<script>
															jQuery(document).ready(function() {
																makeConstrainedAgentPicker('collector','collector_agent_id','collector');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														
														<label for="collecting_source" class="data-entry-label small">Collecting Source
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#collecting_source').autocomplete('search','%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
														</label>
														<input type="text" name="collecting_source" class="data-entry-input inputHeight ui-autocomplete-input" id="collecting_source" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																makeCTFieldSearchAutocomplete("collecting_source","COLLECTING_SOURCE");
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														
														<label for="date_collected" class="data-entry-label small">Date Collected</label>
														<input type="text" name="date_collected" class="data-entry-input inputHeight" id="date_collected" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="">
													</div>
													<div class="col-12 mb-1 col-md-3">
														
														<label class="data-entry-label small" for="when">Verbatim Date</label>
														<input type="text" name="verbatim_date" class="data-entry-input inputHeight" id="verbatim_date" value="">
													</div>
														<button type="button" id="CollDetailCtl1" class="d-block d-xl-none border m-1 d-xl-none py-1 btn-link w-100 text-center btn small" onclick="toggleCollDetail(1);">
															show more <i class="fas fa-caret-down" style="vertical-align: middle;"></i>
														</button>
													<div id="CollDetail" class="col-12 px-0" style="display:none;">
														<div class="form-row col-12 col-md-12 px-0 mx-0 mb-0">
															<div class="col-12 mb-1 col-md-3">
																
																<label for="date_began_date" class="data-entry-label small">Date Began</label>
																<input type="text" name="date_began_date" class="data-entry-input inputHeight" id="date_began_date" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="">
															</div>
															<div class="col-12 mb-1 col-md-3">
																
																<label for="date_ended_date" class="data-entry-label small">Date Ended</label>
																<input type="text" name="date_ended_date" class="data-entry-input inputHeight" id="date_ended_date" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="">
															</div>
															<div class="col-12 mb-1 col-md-4">
																<label for="verbatim_locality" class="data-entry-label small">Verbatim Locality</label>
																
																<input type="text" class="data-entry-input inputHeight" id="verbatim_locality" name="verbatim_locality" value="">
															</div>
														</div>
													</div>
												</div>
											</div>
											<div class="col-12 form-row mx-0 search-form-basic-odd px-0 pb-2 pb-xl-0">
												 
												<div class="col-12 col-xl-2 col-xxl-one col-xxl-1 px-1 mb-1 float-left">
													<div class="pb-0 font-weight-bold d-inline-block-md text-xl-right px-1 w-100 text-left text-md-left text-dark mb-1 mb-md-0 pt-1">
														<h2 class="small mb-0 mx-0 px-2 mx-xl-0 px-xl-0 d-block text-black font-weight-bold">Specimen</h2>
														<button type="button" id="SpecDetailCtl" class="d-xl-inline-block d-none px-xl-0 py-0 btn-link text-right btn smaller" onclick="toggleSpecDetail(1);">
															show more <i class="fas fa-caret-down" style="vertical-align: middle;"></i>
														</button>
													</div>
												</div>
													
												<div class="form-row col-12 col-xxl-eleven col-xxl-11 pt-1 px-1 mb-0 mx-0">
													<div class="col-12 mb-1 col-md-3">
														
														<label for="part_name" class="data-entry-label small">Part Name</label>
														<input type="text" id="part_name" name="part_name" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																makePartNameAutocompleteMeta('part_name');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														
														<label for="preserve_method" class="data-entry-label small">Preserve Method
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#preserve_method').autocomplete('search','%%%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
														</label>
														<input type="text" id="preserve_method" name="preserve_method" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																makePreserveMethodAutocompleteMeta('preserve_method');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														
														<label for="biol_indiv_relationship" class="data-entry-label small">Has Relationship
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#biol_indiv_relationship').val('NOT NULL'); return false;"> (Any) <span class="sr-only">use NOT NULL to find cataloged items with relationships of any type</span></a>
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#biol_indiv_relationship').autocomplete('search','%%%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
														</label>
														<input type="text" id="biol_indiv_relationship" name="biol_indiv_relationship" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																makeBiolIndivRelationshipAutocompleteMeta('biol_indiv_relationship');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														
														<label for="media_type" class="data-entry-label small">Media Type
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#media_type').val('NOT NULL'); return false;"> (Any) <span class="sr-only">use NOT NULL to find cataloged items with media of any type</span></a>
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#media_type').autocomplete('search','%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
														</label>
														<input type="text" id="media_type" name="media_type" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																makeCTFieldSearchAutocomplete("media_type","MEDIA_TYPE");
															});
														</script>
													</div>
														<button type="button" id="SpecDetailCtl1" class="d-block d-xl-none border m-1 d-xl-none py-1 btn-link w-100 text-center btn small" onclick="toggleSpecDetail(1);">
															show more <i class="fas fa-caret-down" style="vertical-align: middle;"></i>
														</button>
													<div id="SpecDetail" class="col-12 px-0" style="display:none;">
														<div class="form-row col-12 col-md-12 px-0 mx-0 mb-0">
															<div class="col-12 mb-1 col-md-3">
																<label for="coll_object_remarks" class="data-entry-label small">Collection Object Remarks</label>
																
																<input type="text" class="data-entry-input inputHeight" id="coll_object_remarks" name="coll_object_remarks" value="">
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="part_remarks" class="data-entry-label small">Part Remarks</label>
																
																<input type="text" class="data-entry-input inputHeight" id="part_remarks" name="part_remarks" value="">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="lot_count" class="data-entry-label small">Lot Count</label>
																
																<input type="text" class="data-entry-input inputHeight" id="lot_count" name="lot_count" value="">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="coll_obj_disposition" class="data-entry-label small">
																	Disposition
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#coll_obj_disposition').autocomplete('search','%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
																</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="coll_obj_disposition" name="coll_obj_disposition" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeCTFieldSearchAutocomplete("coll_obj_disposition","COLL_OBJ_DISP");
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="disposition_remarks" class="data-entry-label small">Disposition Remarks</label>
																
																<input type="text" class="data-entry-input inputHeight" id="disposition_remarks" name="disposition_remarks" value="">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="part_attribute_type" class="data-entry-label small">
																	Part Attribute Type
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#part_attribute_type').val('NOT NULL'); return false;"> (Any) <span class="sr-only">use NOT NULL to find cataloged items with any part attribute</span></a>
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#part_attribute_type').autocomplete('search','%%%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="part_attribute_type" name="part_attribute_type" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makeCTFieldSearchAutocomplete("part_attribute_type","SPECPART_ATTRIBUTE_TYPE");
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="part_attribute_value" class="data-entry-label small">
																	Part Attribute Value
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#part_attribute_value').val('NOT NULL'); return false;"> (Any) <span class="sr-only">use NOT NULL to find cataloged items with any part attribute value</span></a>
																</label>
																
																<input type="text" class="data-entry-input inputHeight" id="part_attribute_value" name="part_attribute_value" value="">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="part_attribute_units" class="data-entry-label small">
																	Part Attribute Units
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#part_attribute_units').val('NOT NULL'); return false;"> (Any) <span class="sr-only">use NOT NULL to find cataloged items with any part attribute units</span></a>
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#part_attribute_units').autocomplete('search','%%%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
																</label>
																
																<input type="text" class="data-entry-input inputHeight ui-autocomplete-input" id="part_attribute_units" name="part_attribute_units" value="" autocomplete="off">
																<script>
																	jQuery(document).ready(function() {
																		makePartsAtrributeUnitSearchPicker("part_attribute_units");
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="part_attribute_remarks" class="data-entry-label small">
																	Part Attribute Remarks
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#part_attribute_remarks').val('NOT NULL'); return false;"> (Any) <span class="sr-only">use NOT NULL to find cataloged items with any part attribute remarks</span></a>
																</label>
																
																<input type="text" class="data-entry-input inputHeight" id="part_attribute_remarks" name="part_attribute_remarks" value="">
															</div>
															<div class="col-12 mb-1 col-md-2">
																
																<label for="condition" class="data-entry-label small">Condition</label>
																
																<input type="text" class="data-entry-input inputHeight" id="condition" name="condition" value="">
															</div>
															
																
																<div class="col-12 mb-1 col-md-2">
																	<label for="condition_remarks" class="data-entry-label small">Condition Remarks</label>
																	
																	<input type="text" class="data-entry-input inputHeight" id="condition_remarks" name="condition_remarks" value="">
																</div>
															
														</div>
													</div>
												</div>
											</div>
											<div class="col-12 form-row mx-0 search-form-basic-odd pb-2 pb-xl-1 px-1">
													<div class="col-12 col-xl-2 col-xxl-one col-xxl-1 px-2 mb-1 float-left">
														<h2 class="small mb-0 mx-1 mx-xl-0 px-0 pt-2 px-xl-1 text-left text-xl-right text-black font-weight-bold">
															General
														</h2>
													</div>
													<div class="form-row col-12 col-xxl-eleven col-xxl-11 ml-0 px-0 pt-1 mb-0">
													<div class="col-12 mb-0 col-md-2">
														
														<label for="keyword" class="data-entry-label small">Keyword Search</label>
														<input type="text" name="keyword" class="data-entry-input inputHeight" id="keyword" value="">
													</div>
													<div class="col-12 mb-0 col-md-2">
														
														<label for="coll_object_entered_date" class="data-entry-label small">Date Entered</label>
														<input type="text" name="coll_object_entered_date" class="data-entry-input inputHeight" id="coll_object_entered_date" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="">
													</div>
													<div class="col-12 mb-0 col-md-2">
														<label for="coll_object_entered_date" class="data-entry-label small">Entered By</label>
														
														<input type="hidden" id="entered_by_id" name="entered_by_id" class="data-entry-input" value="">
														<input type="text" id="entered_by" name="entered_by" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																// backing doesn't include a join to support substring search, so use picker configured to clear both fields.
																// makeConstrainedAgentPicker('entered_by', 'entered_by_id', 'entered_by');
																makeConstrainedAgentPickerConfig('entered_by', 'entered_by_id', 'entered_by', true);
															});
														</script>
													</div>
													<div class="col-12 mb-0 col-md-2">
														
														<label for="last_edit_date" class="data-entry-label small">Last Updated on</label>
														<input type="text" name="last_edit_date" class="data-entry-input inputHeight" id="last_edit_date" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="">
													</div>
													<div class="col-12 mb-0 col-md-2">
														<label for="coll_object_entered_date" class="data-entry-label small">Last Updated By</label>
														
														<input type="hidden" id="last_edited_person_id" name="last_edited_person_id" class="data-entry-input" value="">
														<input type="text" id="last_edited_person" name="last_edited_person" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																// backing doesn't include a join to support substring search, so use picker configured to clear both fields.
																makeConstrainedAgentPickerConfig('last_edited_person', 'last_edited_person_id', 'last_edited_person', true);
															});
														</script>
													</div>
													<div class="col-12 mb-0 col-md-2">
														<label for="underscore_collection" class="data-entry-label small">Named Group
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#underscore_collection').val('NOT NULL'); $('#underscore_collection_id').val(''); return false;"> (Any) <span class="sr-only">use NOT NULL to find cataloged items in any named group</span></a>
														</label>
														
														<input type="hidden" id="underscore_collection_id" name="underscore_collection_id" class="data-entry-input inputHeight" value="">
														<input type="text" id="underscore_collection" name="underscore_collection" class="data-entry-input inputHeight ui-autocomplete-input" value="" autocomplete="off">
														<script>
															jQuery(document).ready(function() {
																makeNamedCollectionPicker('underscore_collection','underscore_collection_id',false);
															});
														</script>
													</div>
												</div>
											</div>
											
												<div class="col-12 form-row mx-0 search-form-basic-odd pb-2 pb-xl-1 px-1">
													<div class="col-12 col-xl-2 col-xxl-one col-xxl-1 px-2 mb-1 float-left">
														<h2 class="small mb-0 mx-1 mx-xl-0 px-0 pt-2 px-xl-1 text-left text-xl-right text-black font-weight-bold">
															Transactions
														</h2>
													</div>
													<div class="form-row col-12 col-xxl-eleven  col-xxl-11 ml-0 px-0 pt-1 mb-0">
														<div class="col-12 mb-1 col-md-2">
															
															<label for="loan_number" class="data-entry-label small">Loan #</label>
															<input type="text" name="loan_number" class="data-entry-input inputHeight" id="loan_number" placeholder="yyyy-n-Col" value="">
														</div>
														<div class="col-12 mb-0 col-md-2">
															
															<label for="accn_number" class="data-entry-label small">Accession #</label>
															<input type="text" name="accn_number" class="data-entry-input inputHeight" id="accn_number" placeholder="nnnnn" value="">
														</div>
														<div class="col-12 mb-0 col-md-2">
															
															<label for="received_date" class="data-entry-label small">Date Received</label>
															<input type="text" name="received_date" class="data-entry-input inputHeight" id="received_date" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="">
														</div>
														<div class="col-12 mb-0 col-md-2">
															
															<label for="accn_status" class="data-entry-label small">Accession Status
																<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#accn_status').autocomplete('search','%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
															</label>
															<input type="text" name="accn_status" class="data-entry-input inputHeight ui-autocomplete-input" id="accn_status" value="" autocomplete="off">
															<script>
																jQuery(document).ready(function() {
																	makeCTFieldSearchAutocomplete("accn_status","ACCN_STATUS");
																});
															</script>
														</div>
														<div class="col-12 mb-0 col-md-2">
															
															<label for="accn_type" class="data-entry-label small">Accession Type
																<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('#accn_type').autocomplete('search','%'); return false;"> (↓) <span class="sr-only">open pick list</span></a>
															</label>
															<input type="text" name="accn_type" class="data-entry-input inputHeight ui-autocomplete-input" id="accn_type" value="" autocomplete="off">
															<script>
																jQuery(document).ready(function() {
																	makeCTFieldSearchAutocomplete("accn_type","ACCN_TYPE");
																});
															</script>
														</div>
														<div class="col-12 mb-0 col-md-2">
															
															<label for="deaccession_number" class="data-entry-label small">Deaccession #</label>
															<input type="text" name="deaccession_number" class="data-entry-input inputHeight" id="deaccession_number" placeholder="Dyyyy-n-Col" value="">
														</div>
													</div>
												</div>
											
											<div id="searchButtons">
												<div class="form-row mx-0 px-4 my-1 pb-1">
													<div class="col-12 px-2 py-2 py-sm-0">
														<button type="submit" class="btn btn-xs btn-primary col-12 col-md-auto px-md-5 mx-0 my-2 mr-md-5" aria-label="run the fixed search" id="fixedsubmitbtn">Search <i class="fa fa-search"></i></button>
														<button type="reset" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mx-0 my-2 mr-md-2" aria-label="Reset this search form to inital values">Reset</button>
														<button type="button" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mx-0 my-2" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='https://mczbase-dev2.rc.fas.harvard.edu/Specimens.cfm?action=fixedSearch';">New Search</button>
													</div>
												</div>
											</div>
										</div>
										<div class="menu_results"> </div>
									</form>
								</div>
															
															
															
															
															
								
								<div class="container-fluid" id="fixedSearchResultsSection">
									<div class="row">
										<div class="col-12">
											<div class="mb-3">
												<div class="row mx-0 mt-1 mb-0 pb-2 pb-md-0 jqx-widget-header border px-2">
													<h1 class="h4 ml-2 ml-md-1 pt3px">
														<span tabindex="0">Results:</span> 
														<span class="pr-2 font-weight-normal" id="fixedresultCount" tabindex="0">Found 3 occurrence records</span> 
														<span id="fixedresultLink" class="font-weight-normal pr-2"><a href="/Specimens.cfm?execute=true&amp;action=fixedSearch&amp;cat_num=PALE-1%2CPALE-2%2CPALE-3&amp;current_id_only=any">Link to this search</a></span>
													</h1>
													<div id="fixedshowhide"><button class="my-2 border rounded" title="hide search form" onclick=" toggleSearchForm('fixed'); "><i id="fixedSearchFormToggleIcon" class="fas fa-eye-slash"></i></button></div>
													<div id="fixedsaveDialogButton" class=""><button id="fixedsearchResultsGridsaveDialogOpener" onclick=" populateSaveSearch('fixedsearchResultsGrid','fixed'); $('#fixedsaveDialog').dialog('open'); " class="btn btn-xs btn-secondary px-2 my-2 mx-1">Save Search</button>
				</div>
													
													
													<div id="fixedcolumnPickDialogButton"><button id="columnPickDialogOpener" onclick=" populateColumnPicker('fixedsearchResultsGrid','fixed'); $('#fixedcolumnPickDialog').dialog('open'); " class="btn btn-xs btn-secondary my-2 mx-1 px-2">Select Columns</button>
				<button id="pinGuidToggle" onclick=" togglePinColumn('fixedsearchResultsGrid','GUID'); " class="btn btn-xs btn-secondary mx-1 px-2 my-2">Unpin GUID Column</button>
				</div>
													<div id="fixedresultDownloadButtonContainer"><button id="specimencsvbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" aria-label="Export results to csv" onclick=" openDownloadDialog('downloadAgreeDialogDiv', 'bccaf7ba-be02-413c-8d33-b07b1907767d', 'occurrence_record_results_2025_06_18T17_31_05_133Z.csv'); ">Export to CSV</button></div>
													<span id="fixedmanageButton" class=""><a href="specimens/manageSpecimens.cfm?result_id=bccaf7ba-be02-413c-8d33-b07b1907767d" target="_blank" class="btn btn-xs btn-secondary px-2 my-2 mx-1">Manage</a></span>
													<span id="fixedremoveButtonDiv" class=""></span>
													<div id="fixedresultBMMapLinkContainer"><a id="fixedBMMapButton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" target="_blank" href="/bnhmMaps/bnhmMapData.cfm?result_id=bccaf7ba-be02-413c-8d33-b07b1907767d" aria-label="Plot points in Berkeley Mapper">BerkeleyMapper (3)</a></div>
													<div id="fixedselectModeContainer" class="ml-3" style="">
														<script>
															function fixedchangeSelectMode(){
																var selmode = $("singlecell").val();
																$("#fixedsearchResultsGrid").jqxGrid({selectionmode: selmode});
																if (selmode=="singlecell") { 
																	$("#fixedsearchResultsGrid").jqxGrid({enableBrowserSelection: true});
																} else {
																	$("#fixedsearchResultsGrid").jqxGrid({enableBrowserSelection: false});
																}
															};
														</script>

														<label class="data-entry-label d-inline w-auto mt-1" for="fixedselectMode">Grid Select:</label>
														<select class="data-entry-select d-inline w-auto mt-1" id="fixedselectMode" onchange="fixedchangeSelectMode();">
															
															<option selected="" value="singlecell">Single Cell</option>
															
															<option value="singlerow">Single Row</option>
															
															<option value="multiplerowsextended">Multiple Rows (click, drag, release)</option>
															
															<option value="multiplecellsadvanced">Multiple Cells (click, drag, release)</option>
														</select>
													</div>
												
													<output id="fixedactionFeedback" class="btn btn-xs btn-transparent my-2 px-2 mx-1 pt-1 border-0"></output>
												</div>
												
												<div class="row mx-0 mt-0"> 
													
													
													<div id="fixedsearchResultsGrid" class="fixedResults jqxGrid focus jqx-grid jqx-reset jqx-rc-all jqx-widget jqx-widget-content jqx-disableselect" style="z-index: 1; width: 100%; height: 225px;" role="grid" align="left" tabindex="0"><div class="jqx-clear jqx-border-reset jqx-overflow-hidden jqx-max-size jqx-position-relative"><div tabindex="1" class="jqx-clear jqx-max-size jqx-position-relative jqx-overflow-hidden jqx-background-reset" id="wrapperfixedsearchResultsGrid"><div style="overflow: hidden; position: absolute; width: 100%; height: 225px; visibility: hidden; display: none;" class="jqx-rc-all"><div style="z-index: 99; margin-left: -66px; left: 50%; top: 50%; margin-top: -24px; position: relative; width: 100px; height: 33px; padding: 5px; font-family: verdana; font-size: 12px; color: #767676; border-color: #898989; border-width: 1px; border-style: solid; background: #f6f6f6; border-collapse: collapse;" class="jqx-rc-all jqx-fill-state-normal"><div style="float: left;"><div style="float: left; overflow: hidden; width: 32px; height: 32px;" class="jqx-grid-load"></div><span style="margin-top: 10px; float: left; display: block; margin-left: 5px;">Loading...</span></div></div></div><div class="jqx-clear jqx-position-absolute jqx-grid-toolbar jqx-widget-header" id="toolbarfixedsearchResultsGrid" style="visibility: hidden; height: 0px;"></div><div class="jqx-clear jqx-position-absolute jqx-grid-groups-header jqx-widget-header" id="groupsheaderfixedsearchResultsGrid" style="visibility: inherit; width: 1252px; height: 34px; top: 0px;"><div style="width: 100%; position: relative; height: 34px; top: 9px; left: 9px;"><div style="position: relative;">Drag a column and drop it here to group by that column</div></div></div><div class="jqx-clear jqx-position-absolute jqx-widget-header jqx-grid-toolbar" id="filterfixedsearchResultsGrid" style="visibility: hidden; height: 0px;"></div><div class="jqx-clear jqx-overflow-hidden jqx-position-absolute jqx-border-reset jqx-background-reset jqx-reset jqx-disableselect" id="contentfixedsearchResultsGrid" tabindex="2" style="width: 1252px; height: 134px; top: 35px;"><div style="overflow: hidden; display: block; height: 36px; width: 3197px; visibility: inherit;" class="jqx-widget-header jqx-grid-header"><div id="columntablefixedsearchResultsGrid" style="height: 100%; position: relative; visibility: inherit; width: 3197px; margin-left: 0px;"><div role="columnheader" style="z-index: 307; position: absolute; height: 100%; width: 30px; left: 0px;" class="jqx-grid-column-header jqx-widget-header"><div style="height: 100%; width: 100%;"></div></div><div role="columnheader" style="z-index: 306; position: absolute; height: 100%; width: 155px; left: 30px;" class="jqx-grid-column-header jqx-widget-header" id="3119-24-28-29-221922"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">GUID</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2122-22-29-30-212116"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 305; position: absolute; height: 100%; width: 40px; left: 185px;" class="jqx-grid-column-header jqx-widget-header" id="2129-28-30-31-242330"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Remove</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2125-31-24-25-172027"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 304; position: absolute; height: 100%; width: 150px; left: 225px;" class="jqx-grid-column-header jqx-widget-header" id="1826-16-24-23-192929"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Collection</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="3129-20-16-31-182321"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 303; position: absolute; height: 100%; width: 130px; left: 375px;" class="jqx-grid-column-header jqx-widget-header" id="3018-29-31-23-162925"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Catalog Number</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2624-16-29-26-181926"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 302; position: absolute; height: 100%; width: 100px; display: none; left: 505px;" class="jqx-grid-column-header jqx-widget-header" id="2529-22-27-17-171930"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Catalog Number Integer Part</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="1631-29-30-26-172228"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 301; position: absolute; height: 100%; width: 100px; display: none; left: 505px;" class="jqx-grid-column-header jqx-widget-header" id="2922-22-25-21-293131"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Catalog Number Prefix</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="1930-16-29-28-203118"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 300; position: absolute; height: 100%; width: 100px; display: none; left: 505px;" class="jqx-grid-column-header jqx-widget-header" id="2022-23-30-23-221629"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">InternalCollObjectID</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="1823-29-17-22-303024"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 299; position: absolute; height: 100%; width: 100px; left: 505px;" class="jqx-grid-column-header jqx-widget-header" id="2525-22-26-17-222120"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Deaccessioned</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2330-30-31-18-291927"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 298; position: absolute; height: 100%; width: 100px; display: none; left: 605px;" class="jqx-grid-column-header jqx-widget-header" id="1931-22-24-21-223121"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Top Type Status Kind</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2430-30-20-20-272127"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 297; position: absolute; height: 100%; width: 100px; left: 605px;" class="jqx-grid-column-header jqx-widget-header" id="2830-20-30-17-241825"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Coll Obj Disposition</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2025-21-17-28-182027"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 296; position: absolute; height: 100%; width: 100px; display: none; left: 705px;" class="jqx-grid-column-header jqx-widget-header" id="2130-27-23-23-293123"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Accession</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2019-23-19-22-242731"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 295; position: absolute; height: 100%; width: 100px; display: none; left: 705px;" class="jqx-grid-column-header jqx-widget-header" id="1823-29-29-22-272526"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Orig Lat Long Units</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2923-24-18-30-252720"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 294; position: absolute; height: 100%; width: 100px; left: 705px;" class="jqx-grid-column-header jqx-widget-header" id="2028-30-21-16-162028"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Top Type Status</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="3027-19-17-26-302024"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 293; position: absolute; height: 100%; width: 100px; display: none; left: 805px;" class="jqx-grid-column-header jqx-widget-header" id="2630-24-29-16-173031"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Lat Long Determiner</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="3023-27-22-30-281624"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 292; position: absolute; height: 100%; width: 100px; display: none; left: 805px;" class="jqx-grid-column-header jqx-widget-header" id="1723-19-19-28-192219"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Lat Long Ref Source</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2127-28-22-28-313119"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 291; position: absolute; height: 100%; width: 100px; display: none; left: 805px;" class="jqx-grid-column-header jqx-widget-header" id="3127-29-19-30-171724"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Type Status</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="3124-26-17-19-211729"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 290; position: absolute; height: 100%; width: 100px; display: none; left: 805px;" class="jqx-grid-column-header jqx-widget-header" id="2329-16-30-30-202118"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Lat Long Remarks</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2226-30-23-22-172621"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 289; position: absolute; height: 100%; width: 160px; display: none; left: 805px;" class="jqx-grid-column-header jqx-widget-header" id="1621-17-31-16-283124"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Type Status Display</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2717-25-20-29-162119"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 288; position: absolute; height: 100%; width: 100px; display: none; left: 805px;" class="jqx-grid-column-header jqx-widget-header" id="1719-26-24-29-162322"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Type Status Plain</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2925-31-17-25-222730"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 287; position: absolute; height: 100%; width: 100px; display: none; left: 805px;" class="jqx-grid-column-header jqx-widget-header" id="1929-20-28-19-192918"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Associated Species</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2424-23-28-27-312224"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 286; position: absolute; height: 100%; width: 100px; left: 805px;" class="jqx-grid-column-header jqx-widget-header" id="1723-28-20-20-311822"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Microhabitat</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="3029-16-17-24-283021"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 285; position: absolute; height: 100%; width: 100px; display: none; left: 905px;" class="jqx-grid-column-header jqx-widget-header" id="2128-18-29-19-242022"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Min Elev In m</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2429-16-25-21-162723"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 284; position: absolute; height: 100%; width: 100px; display: none; left: 905px;" class="jqx-grid-column-header jqx-widget-header" id="1916-24-23-23-233119"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Habitat</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2023-16-21-18-192918"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 283; position: absolute; height: 100%; width: 100px; display: none; left: 905px;" class="jqx-grid-column-header jqx-widget-header" id="3130-22-31-26-302326"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Max Elev In m</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2816-28-26-18-211616"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 282; position: absolute; height: 100%; width: 100px; display: none; left: 905px;" class="jqx-grid-column-header jqx-widget-header" id="2621-18-30-22-233019"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Minimum Elevation</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2725-20-16-24-312316"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 281; position: absolute; height: 100%; width: 100px; display: none; left: 905px;" class="jqx-grid-column-header jqx-widget-header" id="2323-22-27-21-261623"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Maximum Elevation</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2927-19-17-20-222928"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 280; position: absolute; height: 100%; width: 100px; display: none; left: 905px;" class="jqx-grid-column-header jqx-widget-header" id="1824-29-25-29-172216"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Orig Elev Units</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2221-29-29-18-162216"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 279; position: absolute; height: 100%; width: 250px; left: 905px;" class="jqx-grid-column-header jqx-widget-header" id="1718-18-18-19-222627"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Sci Name With Auth</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2330-19-27-26-262226"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div><div role="columnheader" style="z-index: 278; position: absolute; height: 100%; width: 280px; left: 1155px;" class="jqx-grid-column-header jqx-widget-header" id="2416-26-19-18-312431"><div style="height: 100%; width: 100%;"><div style="padding-bottom: 2px; overflow: hidden; text-overflow: ellipsis; text-align: left; margin-left: 4px; margin-right: 2px; line-height: 36px;"><span style="text-overflow: ellipsis; cursor: default;">Specific Locality</span></div><div class="iconscontainer" style="height: 36px; margin-left: -48px; display: block; position: absolute; left: 100%; top: 0%; width: 32px;"><div class="filtericon jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-filterbutton" style="width: 100%; height:100%;"></div></div><div class="sortasc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortascbutton jqx-icon-arrow-up" style="width: 100%; height:100%;"></div></div><div class="sortdesc jqx-widget-header" style="height: 36px; float: right; display: none; width: 16px;"><div class="jqx-grid-column-sortdescbutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div><div class="sorticon jqx-widget-header" style="height: 36px; float: right; visibility: hidden; width: 16px;"><div class="jqx-grid-column-sorticon jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div><div style="height: 36px; display: block; left: 100%; top: 0%; position: absolute; width: 16px; margin-left: -17px;" class="jqx-widget-header" id="2224-21-25-20-252527"><div class="jqx-grid-column-menubutton jqx-icon-arrow-down" style="width: 100%; height:100%;"></div></div></div></div></div></div><div style="width: 100%; overflow: hidden; position: absolute;" class="jqx-grid-content jqx-widget-content"><div id="contenttablefixedsearchResultsGrid" style="overflow: hidden; position: relative; width: 3197px; margin-left: 0px; top: 0.01px;"><div role="row" style="position: relative; height:32px;" id="row0fixedsearchResultsGrid" class="" row-id="0"><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10400; width:30px;" tabindex="213" "="" class="jqx-grid-cell jqx-item jqx-grid-cell-pinned jqx-grid-group-collapse jqx-icon-arrow-right" title=""></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10399; width:155px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-pinned"><span style="margin-top: 8px; float: left; "><a id="aLink0" target="_blank" href="/guid/MCZ:Ent:PALE-1" onclick=" event.preventDefault(); $('#aLinkForm0').submit();">MCZ:Ent:PALE-1</a> <a href="/media/findMedia.cfm?execute=true&amp;method=getMedia&amp;related_cataloged_item=MCZ:Ent:PALE-1" target="_blank"><img src="/shared/images/Image-x-generic.png" height="20" width="20"></a><form action="/guid/MCZ:Ent:PALE-1" method="post" target="_blank" id="aLinkForm0"><input type="hidden" name="result_id" value="bccaf7ba-be02-413c-8d33-b07b1907767d"></form></span></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10398; width:40px;" class="jqx-grid-cell jqx-item primaryTypeCell"><span style="margin-top: 4px; margin-left: 4px; float: left; "><input type="button" onclick=" confirmDialog('Remove this row from these search results','Confirm Remove Row', function(){ var commit = $('#fixedsearchResultsGrid').jqxGrid('deleterow', 0); fixedResultModifiedHere(); } ); " class="p-1 btn btn-xs btn-warning" value="⌦" aria-label="Remove"></span></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10397; width:150px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">Entomology</div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10396; width:130px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">PALE-1</div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10395; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10395; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10395; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10395; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10394; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10394; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">not applicable</div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10393; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10393; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10393; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">Holotype</div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10392; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10392; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10392; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10392; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10392; width:160px;display: none;" class="jqx-grid-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10392; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10392; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10392; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10391; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10391; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10391; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10391; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10391; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10391; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10391; width:250px;" class="jqx-grid-cell jqx-item primaryTypeCell"><span style="margin-top: 8px; float: left; "><a target="_blank" href="/name/Prodryas persephone"><i>Prodryas persephone</i> <span style="font-variant: small-caps">Scudder 1878</span></a></span></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10390; width:280px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">Florissant</div></div></div><div role="row" style="position: relative; height:32px;" id="row1fixedsearchResultsGrid" class="" row-id="1"><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10375; width:30px;" class="jqx-grid-cell jqx-item jqx-grid-cell-pinned jqx-grid-cell-alt jqx-grid-cell-pinned-alt jqx-grid-group-collapse jqx-icon-arrow-right" title=""></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10374; width:155px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-pinned jqx-grid-cell-alt jqx-grid-cell-pinned-alt"><span style="margin-top: 8px; float: left; "><a id="aLink1" target="_blank" href="/guid/MCZ:Ent:PALE-2" onclick=" event.preventDefault(); $('#aLinkForm1').submit();">MCZ:Ent:PALE-2</a> <a href="/media/findMedia.cfm?execute=true&amp;method=getMedia&amp;related_cataloged_item=MCZ:Ent:PALE-2" target="_blank"><img src="/shared/images/Image-x-generic.png" height="20" width="20"></a><form action="/guid/MCZ:Ent:PALE-2" method="post" target="_blank" id="aLinkForm1"><input type="hidden" name="result_id" value="bccaf7ba-be02-413c-8d33-b07b1907767d"></form></span></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10373; width:40px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-alt"><span style="margin-top: 4px; margin-left: 4px; float: left; "><input type="button" onclick=" confirmDialog('Remove this row from these search results','Confirm Remove Row', function(){ var commit = $('#fixedsearchResultsGrid').jqxGrid('deleterow', 1); fixedResultModifiedHere(); } ); " class="p-1 btn btn-xs btn-warning" value="⌦" aria-label="Remove"></span></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10372; width:150px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-alt"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">Entomology</div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10371; width:130px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-alt"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">PALE-2</div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10370; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10370; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10370; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10370; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-alt"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10369; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10369; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-alt"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">not applicable</div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10368; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10368; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10368; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-alt"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">Holotype</div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10367; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10367; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10367; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10367; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10367; width:160px;display: none;" class="jqx-grid-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10367; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10367; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10367; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-alt"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10366; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10366; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10366; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10366; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10366; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10366; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10366; width:250px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-alt"><span style="margin-top: 8px; float: left; "><a target="_blank" href="/name/Lithodryas styx"><i>Lithodryas styx</i> <span style="font-variant: small-caps">(Scudder, 1889)</span></a></span></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10365; width:280px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-alt"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">Florissant</div></div></div><div role="row" style="position: relative; height:32px;" id="row2fixedsearchResultsGrid" class="" row-id="2"><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10350; width:30px;" class="jqx-grid-cell jqx-item jqx-grid-cell-pinned jqx-grid-group-collapse jqx-icon-arrow-right" title=""></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10349; width:155px;" class="jqx-grid-cell jqx-item primaryTypeCell jqx-grid-cell-pinned"><span style="margin-top: 8px; float: left; "><a id="aLink2" target="_blank" href="/guid/MCZ:Ent:PALE-3" onclick=" event.preventDefault(); $('#aLinkForm2').submit();">MCZ:Ent:PALE-3</a> <a href="/media/findMedia.cfm?execute=true&amp;method=getMedia&amp;related_cataloged_item=MCZ:Ent:PALE-3" target="_blank"><img src="/shared/images/Image-x-generic.png" height="20" width="20"></a><form action="/guid/MCZ:Ent:PALE-3" method="post" target="_blank" id="aLinkForm2"><input type="hidden" name="result_id" value="bccaf7ba-be02-413c-8d33-b07b1907767d"></form></span></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10348; width:40px;" class="jqx-grid-cell jqx-item primaryTypeCell"><span style="margin-top: 4px; margin-left: 4px; float: left; "><input type="button" onclick=" confirmDialog('Remove this row from these search results','Confirm Remove Row', function(){ var commit = $('#fixedsearchResultsGrid').jqxGrid('deleterow', 2); fixedResultModifiedHere(); } ); " class="p-1 btn btn-xs btn-warning" value="⌦" aria-label="Remove"></span></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10347; width:150px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">Entomology</div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10346; width:130px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">PALE-3</div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10345; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10345; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10345; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10345; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10344; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10344; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">not applicable</div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10343; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10343; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10343; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">Holotype</div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10342; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10342; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10342; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10342; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10342; width:160px;display: none;" class="jqx-grid-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10342; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10342; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10342; width:100px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10341; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10341; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10341; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10341; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10341; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10341; width:100px;display: none;" class="jqx-grid-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10341; width:250px;" class="jqx-grid-cell jqx-item primaryTypeCell"><span style="margin-top: 8px; float: left; "><a target="_blank" href="/name/Nymphalites obscurum"><i>Nymphalites obscurum</i> <span style="font-variant: small-caps">Scudder 1889</span></a></span></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10340; width:280px;" class="jqx-grid-cell jqx-item primaryTypeCell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;">Florissant</div></div></div><div role="row" style="position: relative; height:32px;" id="row3fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10325; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10324; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10323; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10322; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10321; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10320; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10320; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10320; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10320; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10319; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10319; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10318; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10318; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10318; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10317; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10317; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10317; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10317; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10317; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10317; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10317; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10317; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10316; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10316; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10316; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10316; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10316; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10316; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10316; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10315; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row4fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10300; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10299; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10298; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10297; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10296; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10295; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10295; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10295; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10295; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10294; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10294; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10293; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10293; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10293; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10292; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10292; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10292; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10292; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10292; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10292; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10292; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10292; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10291; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10291; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10291; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10291; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10291; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10291; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10291; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10290; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row5fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10275; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10274; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10273; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10272; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10271; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10270; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10270; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10270; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10270; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10269; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10269; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10268; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10268; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10268; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10267; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10267; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10267; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10267; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10267; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10267; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10267; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10267; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10266; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10266; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10266; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10266; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10266; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10266; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10266; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10265; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row6fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10250; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10249; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10248; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10247; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10246; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10245; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10245; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10245; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10245; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10244; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10244; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10243; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10243; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10243; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10242; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10242; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10242; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10242; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10242; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10242; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10242; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10242; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10241; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10241; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10241; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10241; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10241; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10241; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10241; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10240; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row7fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10225; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10224; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10223; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10222; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10221; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10220; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10220; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10220; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10220; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10219; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10219; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10218; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10218; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10218; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10217; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10217; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10217; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10217; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10217; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10217; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10217; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10217; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10216; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10216; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10216; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10216; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10216; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10216; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10216; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10215; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row8fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10200; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10199; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10198; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10197; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10196; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10195; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10195; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10195; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10195; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10194; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10194; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10193; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10193; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10193; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10192; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10192; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10192; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10192; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10192; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10192; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10192; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10192; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10191; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10191; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10191; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10191; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10191; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10191; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10191; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10190; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row9fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10175; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10174; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10173; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10172; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10171; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10170; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10170; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10170; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10170; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10169; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10169; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10168; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10168; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10168; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10167; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10167; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10167; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10167; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10167; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10167; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10167; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10167; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10166; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10166; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10166; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10166; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10166; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10166; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10166; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10165; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row10fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10150; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10149; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10148; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10147; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10146; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10145; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10145; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10145; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10145; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10144; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10144; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10143; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10143; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10143; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10142; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10142; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10142; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10142; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10142; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10142; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10142; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10142; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10141; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10141; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10141; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10141; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10141; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10141; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10141; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10140; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row11fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10125; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10124; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10123; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10122; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10121; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10120; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10120; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10120; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10120; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10119; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10119; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10118; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10118; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10118; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10117; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10117; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10117; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10117; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10117; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10117; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10117; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10117; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10116; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10116; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10116; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10116; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10116; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10116; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10116; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10115; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row12fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10100; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10099; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10098; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10097; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10096; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10095; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10095; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10095; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10095; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10094; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10094; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10093; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10093; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10093; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10092; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10092; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10092; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10092; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10092; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10092; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10092; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10092; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10091; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10091; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10091; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10091; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10091; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10091; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10091; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10090; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row13fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10075; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10074; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10073; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10072; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10071; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10070; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10070; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10070; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10070; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10069; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10069; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10068; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10068; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10068; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10067; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10067; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10067; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10067; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10067; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10067; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10067; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10067; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10066; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10066; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10066; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10066; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10066; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10066; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10066; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10065; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row14fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10050; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10049; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10048; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10047; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10046; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10045; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10045; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10045; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10045; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10044; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10044; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10043; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10043; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10043; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10042; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10042; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10042; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10042; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10042; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10042; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10042; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10042; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10041; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10041; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10041; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10041; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10041; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10041; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10041; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10040; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row15fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10025; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 10024; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 10023; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 10022; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 10021; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 10020; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 10020; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 10020; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 10020; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 10019; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 10019; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 10018; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 10018; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 10018; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 10017; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 10017; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 10017; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 10017; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 10017; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 10017; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 10017; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 10017; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 10016; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 10016; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 10016; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 10016; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 10016; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 10016; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 10016; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 10015; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row16fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 10000; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9999; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9998; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9997; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9996; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9995; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9995; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9995; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9995; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9994; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9994; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9993; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9993; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9993; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9992; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9992; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9992; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9992; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9992; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9992; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9992; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9992; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9991; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9991; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9991; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9991; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9991; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9991; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9991; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9990; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row17fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9975; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9974; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9973; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9972; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9971; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9970; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9970; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9970; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9970; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9969; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9969; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9968; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9968; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9968; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9967; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9967; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9967; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9967; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9967; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9967; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9967; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9967; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9966; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9966; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9966; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9966; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9966; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9966; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9966; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9965; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row18fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9950; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9949; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9948; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9947; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9946; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9945; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9945; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9945; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9945; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9944; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9944; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9943; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9943; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9943; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9942; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9942; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9942; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9942; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9942; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9942; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9942; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9942; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9941; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9941; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9941; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9941; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9941; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9941; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9941; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9940; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row19fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9925; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9924; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9923; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9922; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9921; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9920; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9920; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9920; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9920; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9919; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9919; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9918; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9918; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9918; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9917; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9917; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9917; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9917; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9917; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9917; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9917; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9917; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9916; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9916; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9916; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9916; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9916; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9916; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9916; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9915; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row20fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9900; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9899; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9898; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9897; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9896; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9895; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9895; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9895; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9895; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9894; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9894; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9893; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9893; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9893; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9892; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9892; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9892; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9892; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9892; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9892; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9892; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9892; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9891; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9891; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9891; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9891; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9891; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9891; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9891; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9890; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row21fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9875; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9874; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9873; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9872; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9871; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9870; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9870; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9870; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9870; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9869; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9869; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9868; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9868; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9868; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9867; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9867; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9867; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9867; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9867; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9867; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9867; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9867; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9866; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9866; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9866; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9866; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9866; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9866; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9866; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9865; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row22fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9850; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9849; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9848; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9847; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9846; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9845; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9845; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9845; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9845; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9844; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9844; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9843; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9843; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9843; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9842; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9842; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9842; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9842; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9842; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9842; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9842; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9842; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9841; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9841; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9841; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9841; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9841; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9841; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9841; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9840; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row23fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9825; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9824; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9823; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9822; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9821; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9820; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9820; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9820; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9820; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9819; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9819; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9818; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9818; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9818; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9817; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9817; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9817; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9817; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9817; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9817; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9817; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9817; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9816; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9816; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9816; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9816; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9816; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9816; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9816; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9815; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row24fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9800; width:30px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9799; width:155px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9798; width:40px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9797; width:150px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9796; width:130px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9795; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9795; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9795; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9795; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9794; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9794; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9793; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9793; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9793; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9792; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9792; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9792; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9792; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9792; width:160px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9792; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9792; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9792; width:100px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9791; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9791; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9791; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9791; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9791; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9791; width:100px;display: none;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9791; width:250px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9790; width:280px;" class="jqx-grid-cell jqx-grid-cleared-cell"></div></div><div role="row" style="position: relative; height:32px;" id="row25fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9775; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9774; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9773; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9772; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9771; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9770; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9770; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9770; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9770; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9769; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9769; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9768; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9768; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9768; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9767; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9767; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9767; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9767; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9767; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9767; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9767; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9767; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9766; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9766; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9766; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9766; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9766; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9766; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9766; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9765; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row26fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9750; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9749; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9748; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9747; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9746; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9745; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9745; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9745; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9745; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9744; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9744; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9743; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9743; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9743; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9742; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9742; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9742; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9742; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9742; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9742; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9742; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9742; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9741; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9741; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9741; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9741; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9741; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9741; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9741; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9740; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row27fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9725; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9724; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9723; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9722; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9721; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9720; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9720; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9720; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9720; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9719; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9719; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9718; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9718; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9718; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9717; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9717; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9717; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9717; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9717; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9717; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9717; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9717; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9716; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9716; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9716; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9716; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9716; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9716; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9716; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9715; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row28fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9700; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9699; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9698; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9697; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9696; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9695; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9695; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9695; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9695; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9694; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9694; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9693; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9693; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9693; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9692; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9692; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9692; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9692; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9692; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9692; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9692; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9692; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9691; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9691; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9691; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9691; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9691; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9691; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9691; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9690; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row29fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9675; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9674; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9673; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9672; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9671; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9670; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9670; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9670; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9670; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9669; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9669; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9668; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9668; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9668; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9667; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9667; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9667; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9667; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9667; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9667; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9667; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9667; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9666; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9666; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9666; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9666; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9666; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9666; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9666; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9665; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row30fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9650; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9649; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9648; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9647; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9646; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9645; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9645; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9645; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9645; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9644; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9644; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9643; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9643; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9643; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9642; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9642; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9642; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9642; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9642; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9642; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9642; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9642; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9641; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9641; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9641; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9641; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9641; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9641; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9641; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9640; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row31fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9625; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9624; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9623; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9622; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9621; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9620; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9620; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9620; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9620; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9619; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9619; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9618; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9618; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9618; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9617; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9617; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9617; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9617; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9617; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9617; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9617; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9617; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9616; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9616; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9616; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9616; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9616; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9616; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9616; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9615; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row32fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9600; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9599; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9598; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9597; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9596; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9595; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9595; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9595; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9595; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9594; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9594; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9593; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9593; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9593; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9592; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9592; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9592; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9592; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9592; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9592; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9592; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9592; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9591; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9591; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9591; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9591; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9591; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9591; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9591; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9590; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row33fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9575; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9574; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9573; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9572; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9571; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9570; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9570; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9570; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9570; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9569; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9569; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9568; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9568; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9568; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9567; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9567; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9567; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9567; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9567; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9567; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9567; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9567; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9566; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9566; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9566; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9566; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9566; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9566; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9566; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9565; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row34fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9550; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9549; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9548; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9547; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9546; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9545; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9545; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9545; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9545; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9544; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9544; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9543; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9543; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9543; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9542; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9542; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9542; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9542; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9542; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9542; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9542; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9542; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9541; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9541; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9541; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9541; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9541; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9541; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9541; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9540; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row35fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9525; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9524; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9523; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9522; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9521; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9520; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9520; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9520; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9520; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9519; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9519; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9518; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9518; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9518; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9517; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9517; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9517; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9517; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9517; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9517; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9517; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9517; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9516; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9516; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9516; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9516; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9516; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9516; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9516; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9515; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row36fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9500; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9499; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9498; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9497; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9496; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9495; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9495; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9495; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9495; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9494; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9494; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9493; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9493; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9493; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9492; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9492; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9492; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9492; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9492; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9492; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9492; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9492; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9491; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9491; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9491; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9491; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9491; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9491; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9491; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9490; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row37fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9475; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9474; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9473; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9472; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9471; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9470; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9470; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9470; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9470; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9469; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9469; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9468; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9468; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9468; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9467; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9467; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9467; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9467; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9467; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9467; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9467; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9467; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9466; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9466; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9466; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9466; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9466; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9466; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9466; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9465; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row38fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9450; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9449; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9448; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9447; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9446; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9445; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9445; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9445; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9445; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9444; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9444; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9443; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9443; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9443; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9442; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9442; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9442; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9442; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9442; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9442; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9442; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9442; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9441; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9441; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9441; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9441; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9441; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9441; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9441; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9440; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row39fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9425; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9424; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9423; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9422; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9421; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9420; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9420; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9420; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9420; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9419; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9419; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9418; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9418; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9418; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9417; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9417; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9417; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9417; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9417; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9417; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9417; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9417; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9416; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9416; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9416; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9416; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9416; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9416; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9416; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9415; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row40fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9400; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9399; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9398; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9397; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9396; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9395; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9395; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9395; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9395; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9394; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9394; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9393; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9393; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9393; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9392; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9392; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9392; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9392; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9392; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9392; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9392; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9392; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9391; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9391; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9391; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9391; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9391; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9391; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9391; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9390; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row41fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9375; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9374; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9373; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9372; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9371; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9370; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9370; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9370; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9370; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9369; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9369; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9368; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9368; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9368; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9367; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9367; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9367; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9367; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9367; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9367; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9367; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9367; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9366; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9366; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9366; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9366; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9366; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9366; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9366; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9365; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row42fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9350; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9349; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9348; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9347; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9346; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9345; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9345; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9345; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9345; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9344; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9344; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9343; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9343; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9343; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9342; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9342; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9342; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9342; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9342; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9342; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9342; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9342; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9341; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9341; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9341; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9341; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9341; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9341; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9341; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9340; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row43fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9325; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9324; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9323; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9322; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9321; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9320; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9320; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9320; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9320; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9319; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9319; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9318; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9318; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9318; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9317; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9317; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9317; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9317; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9317; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9317; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9317; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9317; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9316; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9316; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9316; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9316; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9316; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9316; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9316; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9315; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row44fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9300; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9299; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9298; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9297; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9296; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9295; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9295; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9295; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9295; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9294; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9294; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9293; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9293; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9293; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9292; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9292; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9292; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9292; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9292; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9292; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9292; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9292; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9291; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9291; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9291; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9291; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9291; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9291; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9291; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9290; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row45fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9275; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9274; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9273; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9272; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9271; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9270; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9270; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9270; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9270; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9269; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9269; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9268; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9268; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9268; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9267; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9267; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9267; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9267; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9267; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9267; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9267; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9267; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9266; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9266; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9266; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9266; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9266; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9266; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9266; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9265; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row46fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9250; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9249; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9248; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9247; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9246; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9245; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9245; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9245; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9245; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9244; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9244; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9243; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9243; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9243; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9242; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9242; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9242; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9242; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9242; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9242; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9242; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9242; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9241; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9241; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9241; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9241; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9241; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9241; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9241; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9240; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row47fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9225; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9224; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9223; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9222; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9221; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9220; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9220; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9220; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9220; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9219; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9219; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9218; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9218; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9218; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9217; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9217; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9217; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9217; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9217; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9217; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9217; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9217; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9216; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9216; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9216; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9216; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9216; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9216; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9216; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9215; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row48fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9200; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9199; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9198; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9197; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9196; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9195; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9195; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9195; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9195; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9194; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9194; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9193; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9193; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9193; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9192; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9192; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9192; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9192; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9192; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9192; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9192; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9192; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9191; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9191; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9191; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9191; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9191; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9191; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9191; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9190; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div><div role="row" style="position: relative; height:32px;" id="row49fixedsearchResultsGrid" class=""><div columnindex="0" role="gridcell" style="left: 0px; z-index: 9175; width:30px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="1" role="gridcell" style="left: 30px; z-index: 9174; width:155px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="2" role="gridcell" style="left: 185px; z-index: 9173; width:40px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="3" role="gridcell" style="left: 225px; z-index: 9172; width:150px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="4" role="gridcell" style="left: 375px; z-index: 9171; width:130px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="5" role="gridcell" style="left: 505px; z-index: 9170; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="6" role="gridcell" style="left: 505px; z-index: 9170; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="7" role="gridcell" style="left: 505px; z-index: 9170; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="8" role="gridcell" style="left: 505px; z-index: 9170; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="9" role="gridcell" style="left: 605px; z-index: 9169; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="10" role="gridcell" style="left: 605px; z-index: 9169; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="11" role="gridcell" style="left: 705px; z-index: 9168; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="12" role="gridcell" style="left: 705px; z-index: 9168; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="13" role="gridcell" style="left: 705px; z-index: 9168; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="14" role="gridcell" style="left: 805px; z-index: 9167; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="15" role="gridcell" style="left: 805px; z-index: 9167; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="16" role="gridcell" style="left: 805px; z-index: 9167; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="17" role="gridcell" style="left: 805px; z-index: 9167; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="18" role="gridcell" style="left: 805px; z-index: 9167; width:160px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="19" role="gridcell" style="left: 805px; z-index: 9167; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="20" role="gridcell" style="left: 805px; z-index: 9167; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="21" role="gridcell" style="left: 805px; z-index: 9167; width:100px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="22" role="gridcell" style="left: 905px; z-index: 9166; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="23" role="gridcell" style="left: 905px; z-index: 9166; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="24" role="gridcell" style="left: 905px; z-index: 9166; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="25" role="gridcell" style="left: 905px; z-index: 9166; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="26" role="gridcell" style="left: 905px; z-index: 9166; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="27" role="gridcell" style="left: 905px; z-index: 9166; width:100px;display: none;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="28" role="gridcell" style="left: 905px; z-index: 9166; width:250px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div><div columnindex="29" role="gridcell" style="left: 1155px; z-index: 9165; width:280px;" class="jqx-grid-cell"><div class="jqx-grid-cell-left-align" style="margin-top: 8px;"></div></div></div></div></div><div style="z-index: 9999; visibility: hidden; position: absolute;" class="jqx-grid-selectionarea jqx-fill-state-pressed"></div></div><div class="jqx-clear jqx-position-absolute jqx-scrollbar jqx-widget jqx-widget-content jqx-rc-all" id="verticalScrollBarfixedsearchResultsGrid" style="visibility: hidden;"><div id="jqxScrollOuterWrapverticalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; width:100%; height: 100%; align:left; border: 0px; valign:top; position: relative;" class="jqx-reset"><div id="jqxScrollWrapverticalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; width: 2px; height: 100%; left: 0px; top: 0px; position: absolute;" class="jqx-reset jqx-scrollbar-state-normal"><div id="jqxScrollBtnUpverticalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; left: 0px; top: 0px; position: absolute; width: 0px; height: 0px;" class="jqx-scrollbar-button-state-normal jqx-rc-t"><div class="jqx-reset jqx-icon-arrow-up"></div></div><div id="jqxScrollAreaUpverticalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; left: 0px; top: 2px; position: absolute; height: 0px; width: 10px;" class="jqx-reset"></div><div id="jqxScrollThumbverticalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; left: 0px; top: 2px; position: absolute; width: 0px; height: 10px; visibility: inherit;" class="jqx-scrollbar-thumb-state-normal jqx-fill-state-normal jqx-rc-all"></div><div id="jqxScrollAreaDownverticalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; left: 0px; top: 12px; position: absolute; height: 0px; width: 10px;" class="jqx-reset"></div><div id="jqxScrollBtnDownverticalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; left: 0px; top: -2px; position: absolute; width: 0px; height: 0px;" class="jqx-scrollbar-button-state-normal jqx-rc-b"><div class="jqx-reset jqx-icon-arrow-down"></div></div></div></div></div><div class="jqx-clear jqx-position-absolute jqx-scrollbar jqx-widget jqx-widget-content jqx-rc-all" id="horizontalScrollBarfixedsearchResultsGrid" style="visibility: visible; height: 13px; top: 168px; left: 0px; width: 1250px;"><div id="jqxScrollOuterWraphorizontalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; width:100%; height: 100%; align:left; border: 0px; valign:top; position: relative;" class="jqx-reset"><div id="jqxScrollWraphorizontalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; width: 100%; height: 15px; left: 0px; top: 0px; position: absolute;" class="jqx-reset jqx-scrollbar-state-normal"><div id="jqxScrollBtnUphorizontalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; left: 0px; top: 0px; position: absolute; width: 13px; height: 13px;" class="jqx-scrollbar-button-state-normal jqx-rc-l"><div class="jqx-reset jqx-icon-arrow-left"></div></div><div id="jqxScrollAreaUphorizontalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; left: 15px; top: 0px; position: absolute; height: 13px;" class="jqx-reset"></div><div id="jqxScrollThumbhorizontalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; left: 15px; top: 0px; position: absolute; width: 468px; height: 13px; visibility: inherit;" class="jqx-scrollbar-thumb-state-normal-horizontal jqx-fill-state-normal jqx-rc-all"></div><div id="jqxScrollAreaDownhorizontalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; left: 483px; top: 0px; position: absolute; width: 750px; height: 13px;" class="jqx-reset"></div><div id="jqxScrollBtnDownhorizontalScrollBarfixedsearchResultsGrid" style="box-sizing: content-box; left: 1235px; top: 0px; position: absolute; width: 13px; height: 13px;" class="jqx-scrollbar-button-state-normal jqx-rc-r"><div class="jqx-reset jqx-icon-arrow-right"></div></div></div></div></div><div class="jqx-clear jqx-position-absolute jqx-border-reset jqx-grid-bottomright jqx-scrollbar-state-normal" id="bottomRight" style="visibility: hidden;"></div><div class="jqx-clear jqx-position-absolute jqx-widget-header" id="addrowfixedsearchResultsGrid" style="height: 0px;"></div><div class="jqx-clear jqx-position-absolute jqx-grid-statusbar jqx-grid-cell jqx-grid-cell-pinned" id="statusbarfixedsearchResultsGrid" style="height: 0px; border-color: rgb(170, 170, 170) rgb(170, 170, 170) transparent; border-top-width: 1px; z-index: 3001; margin-left: 0px;"><div style="position: relative; width: 3197px; height: 36px;" id="statusrowfixedsearchResultsGrid"><div style="overflow: hidden; position: absolute; height: 100%; left: 0px; z-index: 218; width: 30px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 30px; z-index: 217; width: 155px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 185px; z-index: 216; width: 40px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 225px; z-index: 215; width: 150px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 375px; z-index: 214; width: 130px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 505px; z-index: 213; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 505px; z-index: 212; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 505px; z-index: 211; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 505px; z-index: 210; width: 100px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 605px; z-index: 209; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 605px; z-index: 208; width: 100px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 705px; z-index: 207; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 705px; z-index: 206; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 705px; z-index: 205; width: 100px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 805px; z-index: 204; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 805px; z-index: 203; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 805px; z-index: 202; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 805px; z-index: 201; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 805px; z-index: 200; width: 160px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 805px; z-index: 199; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 805px; z-index: 198; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 805px; z-index: 197; width: 100px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 905px; z-index: 196; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 905px; z-index: 195; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 905px; z-index: 194; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 905px; z-index: 193; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 905px; z-index: 192; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 905px; z-index: 191; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 905px; z-index: 190; width: 250px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1155px; z-index: 189; width: 280px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1435px; z-index: 188; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1435px; z-index: 187; width: 250px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1435px; z-index: 186; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1435px; z-index: 185; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1435px; z-index: 184; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1435px; z-index: 183; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1435px; z-index: 182; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1435px; z-index: 181; width: 100px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1535px; z-index: 180; width: 100px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1635px; z-index: 179; width: 180px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1815px; z-index: 178; width: 115px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 1930px; z-index: 177; width: 115px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 176; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 175; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 174; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 173; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 172; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 171; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 170; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 169; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 168; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 167; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 166; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 165; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2045px; z-index: 164; width: 180px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2225px; z-index: 163; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2225px; z-index: 162; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2225px; z-index: 161; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2225px; z-index: 160; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2225px; z-index: 159; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2225px; z-index: 158; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2225px; z-index: 157; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2225px; z-index: 156; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2225px; z-index: 155; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2225px; z-index: 154; width: 110px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2335px; z-index: 153; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2335px; z-index: 152; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2335px; z-index: 151; width: 120px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2455px; z-index: 150; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2455px; z-index: 149; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2455px; z-index: 148; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2455px; z-index: 147; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2455px; z-index: 146; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2455px; z-index: 145; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2455px; z-index: 144; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2455px; z-index: 143; width: 150px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 142; width: 200px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 141; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 140; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 139; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 138; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 137; width: 120px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 136; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 135; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 134; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 133; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2605px; z-index: 132; width: 190px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 131; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 130; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 129; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 128; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 127; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 126; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 125; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 124; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 123; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 122; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 121; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 120; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 119; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 118; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 117; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 116; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 115; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 114; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 113; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 112; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 111; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 110; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 109; width: 200px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 108; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 107; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 106; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 105; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 104; width: 200px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2795px; z-index: 103; width: 100px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 102; width: 120px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 101; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 100; width: 80px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 99; width: 80px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 98; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 97; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 96; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 95; width: 120px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 94; width: 120px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 93; width: 150px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 92; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2895px; z-index: 91; width: 100px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 90; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 89; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 88; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 87; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 86; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 85; width: 120px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 84; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 83; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 82; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 81; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 80; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 79; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 78; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 77; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 76; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 75; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 74; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 2995px; z-index: 73; width: 100px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 72; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 71; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 70; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 69; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 68; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 67; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 66; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 65; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 64; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 63; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 62; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 61; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 60; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 59; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 58; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 57; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 56; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 55; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 54; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 53; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 52; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 51; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 50; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 49; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 48; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 47; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 46; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 45; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 44; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 43; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 42; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 41; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 40; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 39; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 38; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 37; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 36; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 35; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 34; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 33; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 32; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 31; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 30; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 29; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 28; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 27; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 26; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 25; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 24; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 23; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 22; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 21; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 20; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 19; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 18; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 17; width: 80px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 16; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 15; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 14; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 13; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 12; width: 100px; display: none;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div><div style="overflow: hidden; position: absolute; height: 100%; left: 3095px; z-index: 11; width: 100px;" class="jqx-grid-cell jqx-grid-cell-pinned jqx-left-align"></div></div></div><div class="jqx-clear jqx-position-absolute jqx-grid-pager jqx-widget-header" id="pagerfixedsearchResultsGrid" style="z-index: 20; width: 1252px; height: 40px; top: 184px;"><div style="line-height: 26px; width: 100%; height: 100%; position: relative; top: 6px;"><div type="button" style="padding: 0px; margin-right: 3px; height: 26px; width: 26px; float: right; cursor: pointer;" title="next" id="jqxWidget62a21928883c" role="button" class="jqx-rc-all jqx-button jqx-widget jqx-fill-state-normal" aria-disabled="false" tabindex="216"><div style="margin-left: 6px; width: 15px; height: 26px;" class="jqx-icon-arrow-right"></div></div><div type="button" style="padding: 0px; margin-right: 3px; height: 26px; width: 26px; float: right; cursor: pointer;" title="previous" id="jqxWidgetad46b09e0981" role="button" class="jqx-rc-all jqx-button jqx-widget jqx-fill-state-normal" aria-disabled="false" tabindex="215"><div style="margin-left: 6px; width: 15px; height: 26px;" class="jqx-icon-arrow-left"></div></div><div style="margin-right: 7px; float: right;">1-3 of 3</div><div id="gridpagerlistfixedsearchResultsGrid" style="margin-right: 7px; float: right; width: 47px; height: 26px;" class="jqx-dropdownlist jqx-widget jqx-dropdownlist-state-normal jqx-rc-all jqx-fill-state-normal jqx-default" role="combobox" aria-autocomplete="both" aria-readonly="false" tabindex="214" aria-owns="listBoxgridpagerlistfixedsearchResultsGrid" aria-haspopup="true" hint="true" aria-disabled="false"><div style="background-color: transparent; -webkit-appearance: none; outline: none; width:100%; height: 100%; padding: 0px; margin: 0px; border: 0px; position: relative;"><div id="dropdownlistWrappergridpagerlistfixedsearchResultsGrid" style="overflow: hidden; outline: none; background-color: transparent; border: none; float: left; width:100%; height: 100%; position: relative;"><div id="dropdownlistContentgridpagerlistfixedsearchResultsGrid" unselectable="on" style="outline: none; background-color: transparent; border: none; float: left; position: relative; margin-top: 6px; margin-bottom: 6px; width: auto; height: 26px; left: 0px; top: 0px;" class="jqx-dropdownlist-content jqx-disableselect">25</div><div id="dropdownlistArrowgridpagerlistfixedsearchResultsGrid" unselectable="on" style="background-color: transparent; border: none; float: right; position: relative; width: 17px; height: 26px;"><div unselectable="on" class="jqx-icon-arrow-down jqx-icon"></div></div><label class="jqx-input-label jqx-default"></label><span class="jqx-input-bar jqx-default" style="top: 26px;"></span></div></div><input type="hidden" value="25" tabindex="-1"></div><div style="margin-right: 7px; float: right;">Show rows:</div><div style="margin-right: 12px; height: 28px; float: right; visibility: inherit;" title="1 - 1"><input style="height:100%; box-sizing: border-box; text-align: right; width: 36px;" type="text" class="jqx-input jqx-widget-content jqx-grid-pager-input jqx-rc-all" tabindex="-1"></div><div style="float: right; margin-right: 7px; visibility: inherit;">Go to page:</div></div></div></div></div></div>
													<div id="fixedPostGridControls" class="p-1 d-none d-md-block" style="">
														
													</div>
													
												</div>
											</div>
										</div>
									</div>
								</div>
							</section>
							<script type="text/javascript" language="javascript">
							function toggleIDDetail(onOff) {
								if (onOff==0) {
									$("#IDDetail").hide();
									$("#IDDetailCtl").attr('onCLick','toggleIDDetail(1)').html('<span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;" title="more fields"></i></span>');
									$("#IDDetailCtl1").attr('onCLick','toggleIDDetail(1)').html('<span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;" title="more fields"></i></span>');
								} else {
									$("#IDDetail").show();
									$("#IDDetailCtl").attr('onCLick','toggleIDDetail(0)').html('<span class="btn-link">show less <i class="fas fa-caret-right" style="vertical-align: middle;" title="fewer fields"></i></span>');
									$("#IDDetailCtl1").attr('onCLick','toggleIDDetail(0)').html('<span class="btn-link">show less <i class="fas fa-caret-right" style="vertical-align: middle;" title="fewer fields"></i></span>');
								}
								
									jQuery.getJSON("/specimens/component/search.cfc",
										{
											method : "saveBasicSrchPref",
											id : 'IDDetail',
											onOff : onOff,
											returnformat : "json",
											queryformat : 'column'
										}, 
										function (data) { 
											console.log(data);
										}
									).fail(function(jqXHR,textStatus,error){
										handleFail(jqXHR,textStatus,error,"persisting IDDetail state");
									});
								
							}
							function toggleTaxaDetail(onOff) {
								if (onOff==0) {
									$("#TaxaDetail").hide();
									$("#TaxaDetailCtl").attr('onCLick','toggleTaxaDetail(1)').html('<span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;" title="show more fields"></i></span>');
									$("#TaxaDetailCtl1").attr('onCLick','toggleTaxaDetail(1)').html('<span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;" title="show more fields"></i></span>');
								} else {
									$("#TaxaDetail").show();
									$("#TaxaDetailCtl").attr('onCLick','toggleTaxaDetail(0)').html('<span class="btn-link">show less <i class="fas fa-caret-right" style="vertical-align: middle;" title="show fewer fields"></i></span>');
									$("#TaxaDetailCtl1").attr('onCLick','toggleTaxaDetail(0)').html('<span class="btn-link">show less <i class="fas fa-caret-right" style="vertical-align: middle;" title="show fewer fields"></i></span>');
								}
								
									jQuery.getJSON("/specimens/component/search.cfc",
										{
											method : "saveBasicSrchPref",
											id : 'TaxaDetail',
											onOff : onOff,
											returnformat : "json",
											queryformat : 'column'
										},
										function (data) { 
											console.log(data);
										}
									).fail(function(jqXHR,textStatus,error){
										handleFail(jqXHR,textStatus,error,"persisting TaxaDetail state");
									});
								
							}
							function toggleGeogDetail(onOff) {
								if (onOff==0) {
									$("#GeogDetail").hide();
									$("#GeogDetailCtl").attr('onCLick','toggleGeogDetail(1)').html('<span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;" title="show more fields"></i></span>');
									$("#GeogDetailCtl1").attr('onCLick','toggleGeogDetail(1)').html('<span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;" title="show more fields"></i></span>');
								} else {
									$("#GeogDetail").show();
									$("#GeogDetailCtl").attr('onCLick','toggleGeogDetail(0)').html('<span class="btn-link">show less <i class="fas fa-caret-right" style="vertical-align: middle;" title="show fewer fields"></i></span>');
									$("#GeogDetailCtl1").attr('onCLick','toggleGeogDetail(0)').html('<span class="btn-link">show less <i class="fas fa-caret-right" style="vertical-align: middle;" title="show fewer fields"></i></span>');
								}
								
									jQuery.getJSON("/specimens/component/search.cfc",
										{
											method : "saveBasicSrchPref",
											id : 'GeogDetail',
											onOff : onOff,
											returnformat : "json",
											queryformat : 'column'
										},
										function (data) { 
											console.log(data);
										}
									).fail(function(jqXHR,textStatus,error){
										handleFail(jqXHR,textStatus,error,"persisting GeogDetail state");
									});
								
							}
							function toggleCollDetail(onOff) {
								if (onOff==0) {
									$("#CollDetail").hide();
									$("#CollDetailCtl").attr('onCLick','toggleCollDetail(1)').html('<span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;" title="show more fields"></i></span>');
									$("#CollDetailCtl1").attr('onCLick','toggleCollDetail(1)').html('<span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;" title="show more fields"></i></span>');
								} else {
									$("#CollDetail").show();
									$("#CollDetailCtl").attr('onCLick','toggleCollDetail(0)').html('<span class="btn-link">show less <i class="fas fa-caret-right" style="vertical-align: middle;" title="show fewer fields"></i></span>');
									$("#CollDetailCtl1").attr('onCLick','toggleCollDetail(0)').html('<span class="btn-link">show less <i class="fas fa-caret-right" style="vertical-align: middle;" title="show fewer fields"></i></span>');
								}
								
									jQuery.getJSON("/specimens/component/search.cfc",
										{
											method : "saveBasicSrchPref",
											id : 'CollDetail',
											onOff : onOff,
											returnformat : "json",
											queryformat : 'column'
										},
										function (data) { 
											console.log(data);
										}
									).fail(function(jqXHR,textStatus,error){
										handleFail(jqXHR,textStatus,error,"persisting CollDetail state");
									});
								
							}
							function toggleSpecDetail(onOff) {
								if (onOff==0) {
									$("#SpecDetail").hide();
									$("#SpecDetailCtl").attr('onCLick','toggleSpecDetail(1)').html('<span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;" title="show more fields"></i></span>');
									$("#SpecDetailCtl1").attr('onCLick','toggleSpecDetail(1)').html('<span class="btn-link">show more <i class="fas fa-caret-down" style="vertical-align: middle;" title="show more fields"></i></span>');
								} else {
									$("#SpecDetail").show();
									$("#SpecDetailCtl").attr('onCLick','toggleSpecDetail(0)').html('<span class="btn-link">show less <i class="fas fa-caret-right" style="vertical-align: middle;" title="show fewer fields"></i></span>');
									$("#SpecDetailCtl1").attr('onCLick','toggleSpecDetail(0)').html('<span class="btn-link">show less <i class="fas fa-caret-right" style="vertical-align: middle;" title="show fewer fields"></i></span>');
								}
								
									jQuery.getJSON("/specimens/component/search.cfc",
										{
											method : "saveBasicSrchPref",
											id : 'SpecDetail',
											onOff : onOff,
											returnformat : "json",
											queryformat : 'column'
										},
										function (data) { 
											console.log(data);
										}
									).fail(function(jqXHR,textStatus,error){
										handleFail(jqXHR,textStatus,error,"persisting SpecDetail state");
									});
								
							}
						</script>
							
							<section id="keywordSearchPanel" role="tabpanel" aria-labelledby="keywordSearchTabButton" tabindex="-1" class="unfocus mx-0  " hidden="">
								<div class="col-9 float-right px-0"> 
									<button class="btn btn-xs btn-dark help-btn" type="button" data-toggle="collapse" data-target="#collapseKeyword" aria-expanded="false" aria-controls="collapseKeyword">
													Search Help
									</button>
									<aside class="collapse collapseStyle" id="collapseKeyword">
										<div class="card card-body pl-4 py-3 pr-3">
											<h2 class="headerSm">Keyword Search Help</h2>
											<p>
												This help applies only the keyword search, behavior and operators for other searches are different.
												 
													(See: <a href="https://code.mcz.harvard.edu/wiki/index.php/Search_Operators" target="_blank">Search Operators</a>). For more examples, see: <a href="https://code.mcz.harvard.edu/wiki/index.php/Keyword_Search" target="_blank">Keyword Search</a>.
												
											</p>
											<dl class="mb-0"> 
												<dt><span class="text-info font-weight-bold">&nbsp;</span></dt>
												<dd>When words are separated by spaces they form a phrase and it is this phrase which is searched for, not the individual words.  For example <em>Panama Bay</em> searches for those two words found adjacent to each other (ignoring punctuation and capitalization). Use operators such as <em>Panama &amp; Bay</em> or <em>NEAR((Panama,Bay),3)</em>, described below, to find a broader scope of records. </dd>
											</dl>
											<h2 class="headerSm">Keyword Search Operators</h2>
											<dl class="mb-0"> 
												<dt><span class="text-info font-weight-bold">&amp;</span></dt>
												<dd>The "and" operator, matches records where the search terms on both sides of the &amp; are present somewhere in the record.</dd>
												<dt><span class="text-info font-weight-bold">|</span></dt>
												<dd>The "or" operator, matches words where at least one of the search terms is present somewhere in the record.</dd>
												<dt><span class="text-info font-weight-bold">!</span></dt>
												<dd>The exclamation mark finds records that contain the first term but not the second (e.g., Panama ! Canal). Results returned would include "Panama" but not "Canal".</dd>
												<dt><span class="text-info font-weight-bold">NEAR((term,term2),distance) &nbsp;&nbsp;</span></dt>
												<dd>The NEAR((term,term2),distance) finds words that are nearby each other (e.g. NEAR((Panama,Bay),3) finds records where Panama and Bay are within three words of each other). Example of results: "San Miguel Id Bay of Panama" and "Bay of Panama, Dan Miguel Id".</dd>
												<dt><span class="text-info font-weight-bold">=</span></dt>
												<dd>The word equivalence operator, either word is interchangeable in the phrase (e.g., Taboga Island=Id). The results would return rows with "Taboga Island" or "Taboga Id".</dd>
												<dt><span class="text-info font-weight-bold">FUZZY(term) &nbsp;&nbsp;</span> </dt>
												<dd>This finds words that are a fuzzy match to the specified term, fuzzy matching can include variations (e.g. misspellings, typos) anywhere in the term (e.g., FUZZY(Taboga)).</dd>
												<dt><span class="text-info font-weight-bold">$</span></dt>
												<dd>The soundex symbol "$" finds words that sound like the specified term, unlike fuzzy matching, soundex tends to find words that are similar in the first few letters and vary at the end (e.g., $Rongelap finds records that contain words which sound like Rongelap. Soundex can be good for finding alternate endings on specific epithets of taxa).</dd>
												<dt><span class="text-info font-weight-bold">#</span></dt> 
												<dd>The stem operator finds words with the same linguistic stem as the search term, e.g. #forest finds words with the same stem as forest such as forested or forests.</dd>
												<dt><span class="text-info font-weight-bold">( )</span></dt>
												<dd>Parentheses can be used to group terms for complex operations (e.g. Basiliscus &amp; (FUZZY(Honduras) | (Panama ! Canal)) will return results with a fuzzy match to Honduras, or Panama but not Canal).</dd>
												<dt><span class="text-info font-weight-bold">%</span></dt> 
												<dd>The percent wildcard, matches any number of characters, e.g. %bridge matches Cambridge, bridge, and Stockbridge.</dd>
												<dt><span class="text-info font-weight-bold">_</span> </dt><dd> The underscore wildcard, matches exactly one character and allows for any character to takes its place.</dd>
											</dl>
										</div>
									</aside>
								</div>
								<div role="search" id="keywordSearchFormDiv">
									<form name="keywordSearchForm" id="keywordSearchForm" class="container-fluid">
										<input id="result_id_keywordSearch" type="hidden" name="result_id" value="" class="excludeFromLink">
										<input type="hidden" name="method" value="executeKeywordSearch" class="keeponclear excludeFromLink">
										<input type="hidden" name="action" value="keywordSearch" class="keeponclear">
										<div class="row mx-0">
											<div class="input-group mt-1">
												<div class="input-group-btn col-12 col-sm-5 col-md-5 col-xl-3 mb-1 mb-sm-0 pr-sm-0 pr-md-3">
													<label for="keywordCollection" class="data-entry-label">Limit to Collection(s)</label>
													<div name="collection_cde" id="keywordCollection" class="w-100 data-entry-select jqx-combobox-state-normal jqx-combobox jqx-rc-all jqx-widget jqx-widget-content" role="combobox" aria-autocomplete="both" aria-disabled="false" aria-owns="listBoxjqxWidget6ab643330e78" aria-haspopup="true" aria-multiline="false" style="height: auto; width: 100%; box-sizing: border-box; min-height: 24px;" aria-readonly="false"><div style="background-color: transparent; appearance: none; outline: none; width: 100%; height: auto; padding: 0px; margin: 0px; border: 0px; position: relative;"><div id="dropdownlistWrapperkeywordCollection" style="padding: 0px; margin: 0px; border: none; background-color: transparent; float: left; width: 100%; height: auto; position: relative;"><div id="dropdownlistContentkeywordCollection" style="padding: 0px; margin: 0px; border-top: none; border-bottom: none; float: left; position: relative; height: auto; left: 0px; top: 0px; cursor: text; min-height: 24px;" class="jqx-combobox-content jqx-widget-content"><input autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="box-sizing: border-box; margin: 4px 0px 0px; padding: 0px 3px; border: 0px; width: 100%; float: left;" type="textarea" class="jqx-combobox-input jqx-widget-content jqx-rc-all" placeholder=""></div><div id="dropdownlistArrowkeywordCollection" role="button" style="padding: 0px; margin: 0px; border-width: 0px 0px 0px 1px; float: right; position: absolute; height: 0px; width: 17px; left: -19px;" class="jqx-combobox-arrow-normal jqx-fill-state-normal jqx-rc-r"><div class="jqx-icon-arrow-down jqx-icon"></div></div><label class="jqx-input-label"></label><span class="jqx-input-bar" style="top: -2px;"></span></div></div><input type="hidden" name="collection_cde" value=""></div>
													
													<script>
														function setKeywordCollectionValues() {
															$('#keywordCollection').jqxComboBox('clearSelection');
															
														};
														$(document).ready(function () {
															var collectionsource = [
																{name:"Cryogenic",cde:"Cryo"}
																	,{name:"Entomology",cde:"Ent"}
																	,{name:"Herpetology",cde:"Herp"}
																	,{name:"Herpetology Observations",cde:"HerpOBS"}
																	,{name:"Ichthyology",cde:"Ich"}
																	,{name:"Invertebrate Paleontology",cde:"IP"}
																	,{name:"Invertebrate Zoology",cde:"IZ"}
																	,{name:"MCZ Collections",cde:"MCZ"}
																	,{name:"Malacology",cde:"Mala"}
																	,{name:"Mammalogy",cde:"Mamm"}
																	,{name:"Ornithology",cde:"Orn"}
																	,{name:"Special Collections",cde:"SC"}
																	,{name:"Vertebrate Paleontology",cde:"VP"}
																	
															];
															$("#keywordCollection").jqxComboBox({ source: collectionsource, displayMember:"name", valueMember:"cde", multiSelect: true, height: '24px', width: '100%' });
															setKeywordCollectionValues();
														});
													</script> 
												</div>
												
												<div class="col-12 col-sm-5 col-md-5 col-xl-7 pl-md-0 mt-1 mt-sm-0">
													<label for="searchText" class="data-entry-label">Keyword(s)</label>
													<input id="searchText" type="text" class="data-entry-input" name="searchText" placeholder="Search term" aria-label="search text" value="">
												</div>
												
													<div class="col-12 col-sm-2 col-md-2 col-xl-2  mt-1 mt-sm-0 pr-2">
														<label class="data-entry-label" for="debug2">Debug</label>
														<select title="debug" name="debug" id="debug2" class="data-entry-select inputHeight">
															<option value=""></option>
															
															<option value="true">Debug JSON</option>
														</select>
													</div>
												
											</div>
										</div>
										<div class="row mx-0 my-3">
											<div class="col-12">
												<label for="keySearch" class="sr-only">Keyword search button - click to search MCZbase</label>
												<button type="submit" class="btn btn-xs btn-primary col-12 col-md-auto px-md-5 mx-0 mr-md-5 my-1" id="keySearch" aria-label="Keyword Search of MCZbase"> Search <i class="fa fa-search"></i> </button>
												<button type="reset" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-2 my-sm-1" aria-label="Reset this search form to inital values">Reset</button>
												<button type="button" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-1" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='https://mczbase-dev2.rc.fas.harvard.edu/Specimens.cfm?action=keywordSearch';">New Search</button>
											</div>
										</div>
									</form>
								</div>
								
								<div class="container-fluid" id="keywordSearchResultsSection">
									<div class="row">
										<div class="col-12">
											<div class="mb-3">
												<div class="row mx-0 mt-0 mt-sm-1 mb-0 pb-2 pb-md-0 jqx-widget-header border px-2">
													<h1 class="h4 pt3px ml-2 ml-md-1">
														<span tabindex="0">Results:</span> 
														<span class="pr-2 font-weight-normal" id="keywordresultCount" tabindex="0"></span> 
														<span id="keywordresultLink" class="font-weight-normal pr-2"></span>
													</h1>
													<div id="keywordshowhide"></div>
													<div id="keywordsaveDialogButton"></div>
													<div id="keywordsaveDialog"></div>
													<div id="keywordcolumnPickDialog">
														<div class="container-fluid">
															<div class="row pick-column-width" id="keywordcolumnPick_row">
																<div class="col-12 col-md-3">
																	<div id="keywordcolumnPick" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="keywordcolumnPick1" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="keywordcolumnPick2" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="keywordcolumnPick3" class="px-1"></div>
																</div>
															</div>
														</div>
													</div>
													<div id="keywordcolumnPickDialogButton"></div>
													<div id="keywordresultDownloadButtonContainer"></div>
													<span id="keywordmanageButton" class=""></span>
													<span id="keywordremoveButtonDiv" class=""></span>
													<div id="keywordresultBMMapLinkContainer"></div>
													<div id="keywordselectModeContainer" class="ml-3" style="display: none;">
														<script>
															function keywordchangeSelectMode(){
																var selmode = $("#keywordselectMode").val();
																$("#keywordsearchResultsGrid").jqxGrid({selectionmode: selmode});
																if (selmode=="none") { 
																	$("#keywordsearchResultsGrid").jqxGrid({enableBrowserSelection: true});
																} else {
																	$("#keywordsearchResultsGrid").jqxGrid({enableBrowserSelection: false});
																}
															};
														</script>
														<label class="data-entry-label d-inline w-auto mt-1" for="keywordselectMode">Grid Select:</label>
														<select class="data-entry-select d-inline w-auto mt-1" id="keywordselectMode" onchange="keywordchangeSelectMode();">
															
															<option value="singlecell">Single Cell</option>
															
															<option value="singlerow">Single Row</option>
															
															<option value="multiplerowsextended">Multiple Rows (click, drag, release)</option>
															
															<option value="multiplecellsadvanced">Multiple Cells (click, drag, release)</option>
														</select>
													</div>

													<output id="keywordactionFeedback" class="btn btn-xs btn-transparent px-2 my-2 mx-1 border-0"></output>
												</div>
												<div class="row mx-0 mt-0" "=""> 
													
													<div id="keywordsearchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
													<div id="keywordPostGridControls" class="p-1 d-none d-md-block" style="display: none;">
														
													</div>
													<div id="keywordenableselection"></div>
												</div>
											</div>
										</div>
									</div>
								</div>
							</section> 
								

							<section id="builderSearchPanel" role="tabpanel" aria-labelledby="builderSearchTabButton" tabindex="-1" class="mx-0  unfocus" hidden="">
								<div role="search" id="builderSearchFormDiv" class="container-fluid px-0">
									<div class="col-9 float-right px-3"> 
									<button class="btn btn-xs btn-dark help-btn border-0" type="button" data-toggle="collapse" data-target="#collapseBuilder" aria-expanded="false" aria-controls="collapseBuilder">
										Search Help
									</button>
									<aside class="collapse collapseStyle" id="collapseBuilder">
										<div class="card card-body pl-4 py-3 pr-3">
											<h2 class="headerSm">Search Builder Search Help</h2>
											<p>Construct searches on arbitrary sets of fields.  Click the <i>Add</i> button to add a clause to the search, select a field to search, and specify a value to search for.</p>.
											<p>Search terms can be connected with <i>and</i> or <i>or</i>.  Searches using <i>and</i> find records where the criteria on both side of the <i>and</i> are met in each record.  Searches using <i>or</i> find records where at least one of the criteria on each side of the <i>or</i> are met.  Searching for Genus=Babelomurex <i>or</i> Genus=Chicoreus will find specimens with an identification in either of these genera. </p> 
											<p>Use parenthesies to group <i>or</i> terms, e.g. (genus=Urocyon or genus=Vulpes) and (state=Massachusetts or state=Vermont). See an example: <a href="/Specimens.cfm?execute=true&amp;builderMaxRows=6&amp;action=builderSearch&amp;openParens1=1&amp;field1=GEOG_AUTH_REC%3ASTATE_PROV&amp;searchText1=%3DMassachusetts&amp;closeParens1=0&amp;JoinOperator2=or&amp;openParens2=0&amp;field2=GEOG_AUTH_REC%3ASTATE_PROV&amp;searchText2=%3DVermont&amp;closeParens2=0&amp;JoinOperator3=or&amp;openParens3=0&amp;field3=GEOG_AUTH_REC%3ASTATE_PROV&amp;searchText3=%3DNew%20Hampshire&amp;closeParens3=1&amp;JoinOperator4=and&amp;openParens4=1&amp;field4=TAXONOMY%3AGENUS&amp;searchText4=%3DUrocyon&amp;closeParens4=0&amp;JoinOperator6=or&amp;openParens6=0&amp;field6=TAXONOMY%3AGENUS&amp;searchText6=%3DVulpes&amp;closeParens6=1" target="_blank">Red or Gray foxes from MA, NH, or VT</a></p>
											<p>The number of parenthesies you open must equal the number of parenthesies you close in order to run a search.  If there is a mismatch in the count, then the search button will be disabled, and an error message will be show.  For example, <i>open 2 ( but close 1 )</i> means that you need to add another close parenthesis.  Similarly, if your parenthesies incorrectly ordered so as to produce a syntax error an error message will be shown and the search button will be disabled.  Problems with nesting of <i>and</i> and <i>or</i> clauses will produce unexpected results if the logic you specified does not match your expectations.</p>
											<p>Many database fields in multiple tables in MCZbase are available to build a search.
											Each available field is described here: <a href="/specimens/viewSpecimenSearchMetadata.cfm?action=search&amp;execute=true&amp;method=getcf_spec_search_cols&amp;access_role=!HIDE">Search Builder Help Page</a>
											</p>
										</div>
									</aside>
								</div>
									<form id="builderSearchForm" class="container-fluid">
										<script>
											// bind autocomplete to text input/hidden input, and other actions on field selection
											function handleFieldSelection(fieldSelect,rowNumber) { 
												var selection = $('#'+fieldSelect).val();
												console.log(selection);
												console.log(rowNumber);
												for (var i=0; i<columnMetadata.length; i++) {
													if(selection==columnMetadata[i].column) {
														// remove any existing binding.
														$('#searchId'+rowNumber).val("");
														try { 
															$('#searchText'+rowNumber).autocomplete("destroy");
														} catch {}
														$('#searchText'+rowNumber).val("");
														console.log(columnMetadata[i].ui_function);
														var functionToBind = columnMetadata[i].ui_function;
														if (functionToBind.search(/^[A-Za-z]+$/)>-1) {
															//  makeAutocomplete ->  makeAutocomplete(searchText{n},searchId{n})
															var invokeBinding = Function(functionToBind+"('searchText"+ rowNumber+"','searchId"+ rowNumber+"')");
															invokeBinding(); 
														} else if (functionToBind.search(/^[A-Za-z]+\(\)$/)>-1) {
															// makeAutocomplete(text) -> makeAutocomplete(searchText{n})
															var functionName = functionToBind.substring(0,functionToBind.length-2); // remove trailing ()
															var invokeBinding = Function(functionName+"('searchText"+ rowNumber+"')");
															invokeBinding(); 
														} else if (functionToBind.search(/^[A-Za-z]+\(.*:.*\)$/)>-1) {
															// makeAutocomplete(searchId:,searchText:,param) -> makeAutocomplete(searchId{n},searchText{n}:,param)
															var paramsBit = functionToBind.match(/\(.*\)/);
															var functionBit = functionToBind.substring(0,functionToBind.indexOf("("));
															var params = paramsBit[0].substring(1,paramsBit[0].length-1);
															var paramsArray = params.split(',');
															var paramsReady = "";
															var comma = "";
															for (var par in paramsArray) { 
																paramsReady = paramsReady + comma + "'"+paramsArray[par].replace(":",rowNumber)+"'";
																var comma = ",";
															}
															functionToBind = functionBit + "(" + paramsReady + ")";
															console.log(functionToBind);
															var invokeBinding = Function(functionToBind);
															invokeBinding(); 
														}
													}
												}
											}
											// bind autocomplete to text input/hidden input, but don't clear existing values, used on intial page load.
											function handleFieldSetup(fieldSelect,rowNumber) { 
												var selection = $('#'+fieldSelect).val();
												console.log(selection);
												console.log(rowNumber);
												for (var i=0; i<columnMetadata.length; i++) {
													if(selection==columnMetadata[i].column) {
														console.log(columnMetadata[i].ui_function);
														if (columnMetadata[i].ui_function) {
															var functionToBind = columnMetadata[i].ui_function;
															if (functionToBind.search(/^[A-Za-z]+$/)>-1) {
																//  makeAutocomplete(text,id)
																var invokeBinding = Function(functionToBind+"('searchText"+ rowNumber+"','searchId"+ rowNumber+"')");
																invokeBinding(); 
															} else if (functionToBind.search(/^[A-Za-z]+\(\)$/)>-1) {
																// makeAutocomplete(text)
																var functionName = functionToBind.substring(0,functionToBind.length-2); // remove trailing ()
																var invokeBinding = Function(functionName+"('searchText"+ rowNumber+"')");
																invokeBinding(); 
															} else if (functionToBind.search(/^[A-Za-z]+\(.*:.*\)$/)>-1) {
																// makeAutocomplete(searchId:,searchText:,param) -> makeAutocomplete(searchId{n},searchText{n}:,param)
																var paramsBit = functionToBind.match(/\(.*\)/);
																var functionBit = functionToBind.substring(0,functionToBind.indexOf("("));
																var params = paramsBit[0].substring(1,paramsBit[0].length-1);
																var paramsArray = params.split(',');
																var paramsReady = "";
																var comma = "";
																for (var par in paramsArray) { 
																	paramsReady = paramsReady + comma + "'"+paramsArray[par].replace(":",rowNumber)+"'";
																	var comma = ",";
																}
																functionToBind = functionBit + "(" + paramsReady + ")";
																console.log(functionToBind);
																var invokeBinding = Function(functionToBind);
																invokeBinding(); 
															}
														}
													}
												}
											}
										</script>
										
										<input type="hidden" id="builderMaxRows" name="builderMaxRows" value="1">
										<input id="result_id_builderSearch" type="hidden" name="result_id" value="" class="excludeFromLink">
										<input type="hidden" name="method" value="executeBuilderSearch" class="keeponclear excludeFromLink">
										<input type="hidden" name="action" value="builderSearch" class="keeponclear">
										<div class="form-row mx-0">
											<div class="mt-1 col-12 p-0 my-2" id="customFields">
												<div class="form-row mb-2">
													<div class="col-12 col-md-1 pt-3">
														<a aria-label="Add more search criteria" id="addRowButton" class="btn btn-xs btn-primary rounded px-2 mr-md-auto" target="_self" href="javascript:void(0);">Add</a>
													</div>
													<div class="col-12 col-md-1">
														<output id="nestingFeedback"></output>
													</div>
													<div class="col-12 col-md-1">
														<label for="openParens1" class="data-entry-label">&nbsp;</label>
														
														<select id="openParens1" name="openParens1" class="data-entry-select">
															
															<option value="0" selected=""></option>
															
															<option value="1">(</option>
															
															<option value="2">((</option>
															
															<option value="3">(((</option>
															
															<option value="4">((((</option>
															
															<option value="5">(((((</option>
														</select>
													</div>
													<div class="col-12 col-md-4">
														
														<script>
															var columnMetadata = JSON.parse('[{"column":"TRANS_AGENT:ACCESSIONS_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"AGENT_NAME:ACCESSIONS_AGENT_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"TRANS_AGENT:TRANS_AGENT_ROLE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,TRANS_AGENT_ROLE)"},{"column":"ACCN:ACCN_NUMBER","data_type":"VARCHAR2","ui_function":""},{"column":"CATALOGED_ITEM:ACCN_ID","data_type":"NUMBER","ui_function":"makeAccessionAutocompleteMeta"},{"column":"ACCN:ACCN_STATUS","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,ACCN_STATUS)"},{"column":"TRANS:ACCESSIONS_TRANSACTION_ID","data_type":"NUMBER","ui_function":""},{"column":"ACCN:ACCN_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,ACCN_TYPE)"},{"column":"TRANS:ACCESSIONS_COLLECTION_ID","data_type":"NUMBER","ui_function":"makeCollectionPicker"},{"column":"ACCN:ESTIMATED_COUNT","data_type":"NUMBER","ui_function":""},{"column":"TRANS:NATURE_OF_MATERIAL","data_type":"VARCHAR2","ui_function":""},{"column":"ACCN:RECEIVED_DATE","data_type":"DATE","ui_function":""},{"column":"ACCN:RECEIVED_DATE_TEXT","data_type":"VARCHAR2","ui_function":""},{"column":"TRANS:TRANS_DATE","data_type":"DATE","ui_function":""},{"column":"TRANS:TRANS_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"ATTRIBUTES:DETERMINATION_METHOD","data_type":"VARCHAR2","ui_function":""},{"column":"ATTRIBUTES:ATTRIBUTES_DETERMINED_BY_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"ATTRIBUTES:ATTRIBUTES_DETERMINED_DATE","data_type":"DATE","ui_function":""},{"column":"ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_REMARK","data_type":"VARCHAR2","ui_function":""},{"column":"ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,ATTRIBUTE_TYPE)"},{"column":"ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_UNITS","data_type":"VARCHAR2","ui_function":""},{"column":"ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_VALUE","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJECT_REMARK:ASSOCIATED_SPECIES","data_type":"VARCHAR2","ui_function":""},{"column":"CATALOGED_ITEM:CAT_NUM","data_type":"VARCHAR2","ui_function":""},{"column":"CATALOGED_ITEM:CAT_NUM_INTEGER","data_type":"NUMBER","ui_function":""},{"column":"CATALOGED_ITEM:CAT_NUM_PREFIX","data_type":"VARCHAR2","ui_function":""},{"column":"CATALOGED_ITEM:CAT_NUM_SUFFIX","data_type":"VARCHAR2","ui_function":""},{"column":"CATALOGED_ITEM:CATALOGED_ITEM_TYPE","data_type":"CHAR","ui_function":""},{"column":"COLL_OBJECT:COLL_OBJ_DISPOSITION","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJECT:COLL_OBJECT_ENTERED_DATE","data_type":"DATE","ui_function":""},{"column":"COLL_OBJECT_REMARK:COLL_OBJECT_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJECT:COLL_OBJECT_TYPE","data_type":"CHAR","ui_function":"makeCTFieldSearchAutocomplete(searchText:,COLL_OBJECT_TYPE)"},{"column":"CATALOGED_ITEM:CATALOGED ITEM_COLLECTING_EVENT_ID","data_type":"NUMBER","ui_function":"makeCollectingEventAutocompleteMeta"},{"column":"CATALOGED_ITEM:CATALOGED ITEM_COLLECTION_ID","data_type":"NUMBER","ui_function":"makeCollectionPicker"},{"column":"CATALOGED_ITEM:COLLECTION_CDE","data_type":"VARCHAR2","ui_function":"makeCollectionCdePicker()"},{"column":"COLL_OBJECT:CONDITION","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJECT_REMARK:DISPOSITION_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJECT:ENTERED_PERSON_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"CATALOGED_ITEM:CATALOGED ITEM_COLLECTION_OBJECT_ID","data_type":"NUMBER","ui_function":"makeCatalogedItemAutocompleteMeta"},{"column":"COLL_OBJECT:LAST_EDIT_DATE","data_type":"DATE","ui_function":""},{"column":"COLL_OBJECT:LAST_EDITED_PERSON_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"COLL_OBJECT:LOT_COUNT","data_type":"NUMBER","ui_function":""},{"column":"COLL_OBJECT:LOT_COUNT_MODIFIER","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJECT_REMARK:HABITAT","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJECT:FLAGS","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJ_OTHER_ID_NUM:DISPLAY_VALUE","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJ_OTHER_ID_NUM:OTHER_ID_NUMBER","data_type":"NUMBER","ui_function":""},{"column":"COLL_OBJ_OTHER_ID_NUM:OTHER_ID_PREFIX","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJ_OTHER_ID_NUM:OTHER_ID_SUFFIX","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_OBJ_OTHER_ID_NUM:OTHER_ID_TYPE","data_type":"VARCHAR2","ui_function":"makeCTOtherIDTypeAutocomplete"},{"column":"COLL_OBJECT:COLL_OBJ_COLLECTION_OBJECT_ID","data_type":"NUMBER","ui_function":""},{"column":"CITATION:CIT_CURRENT_FG","data_type":"NUMBER","ui_function":""},{"column":"CTCITATION_TYPE_STATUS:CATEGORY","data_type":"VARCHAR2","ui_function":""},{"column":"CTCITATION_TYPE_STATUS:CITATIONS_DESCRIPTION","data_type":"VARCHAR2","ui_function":""},{"column":"CITATION:CITATION_PAGE_URI","data_type":"VARCHAR2","ui_function":""},{"column":"CITATION:CITATION_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"CITATION:CITATION_TEXT","data_type":"VARCHAR2","ui_function":""},{"column":"CITATION:CITATIONS_TYPE_STATUS","data_type":"VARCHAR2","ui_function":"makeTypeStatusSearchAutocomplete()"},{"column":"CITATION:CITATIONS_COLLECTION_OBJECT_ID","data_type":"NUMBER","ui_function":"makeCatalogedItemAutocompleteMeta"},{"column":"TAXONOMY:CITED_GENUS","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,genus)"},{"column":"FORMATTED_PUBLICATION:CITATION_FORMATTED_PUBLICATION","data_type":"VARCHAR2","ui_function":""},{"column":"CITATION:CITATIONS_PUBLICATION_ID","data_type":"NUMBER","ui_function":"makePublicationPicker"},{"column":"CITATION:CITED_TAXON_NAME_ID","data_type":"NUMBER","ui_function":"makeScientificNameAutocompleteMeta"},{"column":"TAXONOMY:CITED_FAMILY","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,family)"},{"column":"CITATION:OCCURS_PAGE_NUMBER","data_type":"NUMBER","ui_function":""},{"column":"CITATION:REP_PUBLISHED_YEAR","data_type":"NUMBER","ui_function":""},{"column":"TAXONOMY:CITED_ORDER","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,order)"},{"column":"LAT_LONG:ACCEPTED_LAT_LONG_FG","data_type":"NUMBER","ui_function":""},{"column":"COLLECTING_EVENT:DATE_DETERMINED_BY_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"COLLECTING_EVENT:BEGAN_DATE","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTING_EVENT:COLLECTING EVENTS_COLLECTING_EVENT_ID","data_type":"NUMBER","ui_function":"makeCollectingEventAutocompleteMeta"},{"column":"COLLECTING_EVENT:CE_COLLECTING_EVENT_ID","data_type":"NUMBER","ui_function":""},{"column":"COLL_EVENT_NUMBER:COLL_EVENT_NUMBER","data_type":"VARCHAR2","ui_function":""},{"column":"COLL_EVENT_NUMBER:COLL_EVENT_NUM_SERIES_ID","data_type":"NUMBER","ui_function":""},{"column":"COLLECTING_EVENT:COLL_EVENT_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"LOCALITY:COLLECTING EVENTS_GEOG_AUTH_REC_ID","data_type":"NUMBER","ui_function":""},{"column":"GEOG_AUTH_REC:COLLECTING EVENTS_SOURCE_AUTHORITY","data_type":"VARCHAR2","ui_function":""},{"column":"GEOG_AUTH_REC:COLLECTING EVENTS_VALID_CATALOG_TERM_FG","data_type":"NUMBER","ui_function":""},{"column":"COLLECTING_EVENT:COLLECTING_METHOD","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,COLLECTIONG_METHOD)"},{"column":"COLLECTING_EVENT:COLLECTING_SOURCE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,COLLECTING_SOURCE)"},{"column":"COLLECTING_EVENT:COLLECTING_TIME","data_type":"VARCHAR2","ui_function":""},{"column":"GEOG_AUTH_REC:CONTINENT_OCEAN","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,continent_ocean)"},{"column":"GEOG_AUTH_REC:COUNTRY","data_type":"VARCHAR2","ui_function":"makeCountrySearchAutocomplete()"},{"column":"GEOG_AUTH_REC:COUNTY","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,county)"},{"column":"LOCALITY:CURATED_FG","data_type":"NUMBER","ui_function":""},{"column":"COLLECTING_EVENT:DATE_BEGAN_DATE","data_type":"DATE","ui_function":""},{"column":"COLLECTING_EVENT:DATE_ENDED_DATE","data_type":"DATE","ui_function":""},{"column":"LAT_LONG:DATUM","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,DATUM)"},{"column":"COLLECTING_EVENT:ENDDAYOFYEAR","data_type":"NUMBER","ui_function":""},{"column":"COLLECTING_EVENT:STARTDAYOFYEAR","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:DEC_LAT_MIN","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:DEC_LAT","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:DEC_LONG_MIN","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:DEC_LONG","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:DEPTH_UNITS","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,DEPTH_UNITS)"},{"column":"COLLECTING_EVENT:ENDED_DATE","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:EXTENT","data_type":"NUMBER","ui_function":""},{"column":"GEOG_AUTH_REC:FEATURE","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,feature)"},{"column":"LAT_LONG:FIELD_VERIFIED_FG","data_type":"NUMBER","ui_function":""},{"column":"COLLECTING_EVENT:FISH_FIELD_NUMBER","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:GPSACCURACY","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:GEOLOCATE_NUMRESULTS","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:GEOLOCATE_PARSEPATTERN","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:GEOLOCATE_PRECISION","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:GEOLOCATE_SCORE","data_type":"NUMBER","ui_function":""},{"column":"GEOLOGY_ATTRIBUTES:GEO_ATT_DETERMINED_DATE","data_type":"DATE","ui_function":""},{"column":"GEOLOGY_ATTRIBUTES:GEO_ATT_DETERMINED_METHOD","data_type":"VARCHAR2","ui_function":""},{"column":"GEOLOGY_ATTRIBUTES:GEO_ATT_DETERMINER_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"GEOLOGY_ATTRIBUTES:GEO_ATT_REMARK","data_type":"VARCHAR2","ui_function":""},{"column":"GEOLOGY_ATTRIBUTES:GEO_ATT_VALUE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,GEOLOGY_ATTRIBUTE_HIERARCHY)"},{"column":"GEOLOGY_ATTRIBUTES:GEOLOGY_ATTRIBUTE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,GEOLOGY_ATTRIBUTES)"},{"column":"GEOLOGY_ATTRIBUTES:GEOLOGY_ATTRIBUTE_ID","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:GEOREF_UPDATED_DATE","data_type":"DATE","ui_function":""},{"column":"LAT_LONG:COLLECTING EVENTS_DETERMINED_BY_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"LAT_LONG:COLLECTING EVENTS_DETERMINED_DATE","data_type":"DATE","ui_function":""},{"column":"LAT_LONG:MAX_ERROR_UNITS","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:MAX_ERROR_DISTANCE","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:GEOREFMETHOD","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,GEOREFMETHOD)"},{"column":"LAT_LONG:VERIFICATIONSTATUS","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:VERIFIED_BY_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"LOCALITY:GEOREF_BY","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTING_EVENT:HABITAT_DESC","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,HABITAT_DESC)"},{"column":"GEOG_AUTH_REC:HIGHER_GEOG","data_type":"VARCHAR2","ui_function":""},{"column":"GEOG_AUTH_REC:HIGHERGEOGRAPHYID_GUID_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,GUID_TYPE)"},{"column":"GEOG_AUTH_REC:ISLAND","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,island)"},{"column":"GEOG_AUTH_REC:ISLAND_GROUP","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,island_group)"},{"column":"LAT_LONG:LAT_LONG_FOR_NNP_FG","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:LAT_LONG_REF_SOURCE","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:LAT_LONG_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:LAT_DEG","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:LAT_DIR","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:LAT_MIN","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:LAT_SEC","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:LOCALITY_LOCALITY_ID_PICK","data_type":"NUMBER","ui_function":"makeLocalityAutocompleteMeta"},{"column":"LOCALITY:LOCALITY_LOCALITY_ID","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:LOCALITY_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:LONG_DEG","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:LONG_DIR","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:LONG_MIN","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:LONG_SEC","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:MAX_DEPTH","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:MAXIMUM_ELEVATION","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:MIN_DEPTH","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:MINIMUM_ELEVATION","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:NEAREST_NAMED_PLACE","data_type":"VARCHAR2","ui_function":""},{"column":"LOCALITY:NOGEOREFBECAUSE","data_type":"VARCHAR2","ui_function":""},{"column":"GEOG_AUTH_REC:OCEAN_REGION","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,ocean_region)"},{"column":"GEOG_AUTH_REC:OCEAN_SUBREGION","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,ocean_subregion)"},{"column":"LOCALITY:ORIG_ELEV_UNITS","data_type":"VARCHAR2","ui_function":""},{"column":"LAT_LONG:ORIG_LAT_LONG_UNITS","data_type":"VARCHAR2","ui_function":""},{"column":"GEOG_AUTH_REC:QUAD","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,quad)"},{"column":"LOCALITY:RANGE","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:RANGE_DIRECTION","data_type":"CHAR","ui_function":""},{"column":"COLLECTING_EVENT:VERBATIMSRS","data_type":"VARCHAR2","ui_function":""},{"column":"GEOG_AUTH_REC:SEA","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,sea)"},{"column":"LOCALITY:SECTION","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:SECTION_PART","data_type":"VARCHAR2","ui_function":""},{"column":"LOCALITY:SOVEREIGN_NATION","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,SOVEREIGN_NATION)"},{"column":"LAT_LONG:SPATIALFIT","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:SPEC_LOCALITY","data_type":"VARCHAR2","ui_function":""},{"column":"GEOG_AUTH_REC:STATE_PROV","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,state_prov)"},{"column":"LOCALITY:TOWNSHIP","data_type":"NUMBER","ui_function":""},{"column":"LOCALITY:TOWNSHIP_DIRECTION","data_type":"CHAR","ui_function":""},{"column":"LAT_LONG:UTM_EW","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:UTM_NS","data_type":"NUMBER","ui_function":""},{"column":"LAT_LONG:UTM_ZONE","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTING_EVENT:VALID_DISTRIBUTION_FG","data_type":"NUMBER","ui_function":""},{"column":"COLLECTING_EVENT:VERBATIMCOORDINATESYSTEM","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTING_EVENT:VERBATIMCOORDINATES","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTING_EVENT:VERBATIM_DATE","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTING_EVENT:VERBATIMDEPTH","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTING_EVENT:VERBATIMELEVATION","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTING_EVENT:VERBATIMLATITUDE","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTING_EVENT:VERBATIM_LOCALITY","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTING_EVENT:VERBATIMLONGITUDE","data_type":"VARCHAR2","ui_function":""},{"column":"GEOG_AUTH_REC:WKT_POLYGON","data_type":"CLOB","ui_function":""},{"column":"GEOG_AUTH_REC:WATER_FEATURE","data_type":"VARCHAR2","ui_function":"makeGeogSearchAutocomplete(searchText:,water_feature)"},{"column":"GEOG_AUTH_REC:HIGHERGEOGRAPHYID","data_type":"VARCHAR2","ui_function":""},{"column":"AGENT:AGENT_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"AGENT:BIOGRAPHY","data_type":"VARCHAR2","ui_function":""},{"column":"AGENT:AGENT_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,AGENT_TYPE)"},{"column":"PERSON:BIRTH_DATE_DATE","data_type":"DATE","ui_function":""},{"column":"PERSON:BIRTH_DATE","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTOR:COLL_NUM","data_type":"NUMBER","ui_function":""},{"column":"COLLECTOR:COLL_NUM_PREFIX","data_type":"VARCHAR2","ui_function":""},{"column":"COLLECTOR:COLL_NUM_SUFFIX","data_type":"VARCHAR2","ui_function":""},{"column":"AGENT:COLLECTORS_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"AGENT:AGENTGUID","data_type":"VARCHAR2","ui_function":""},{"column":"AGENT:AGENTGUID_GUID_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,GUID_TYPE)"},{"column":"COLLECTOR:COLL_ORDER","data_type":"NUMBER","ui_function":""},{"column":"COLLECTOR:COLLECTOR_ROLE","data_type":"CHAR","ui_function":""},{"column":"AGENT:EDITED","data_type":"CHAR","ui_function":""},{"column":"AGENT_NAME:COLLECTORS_AGENT_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"AGENT_NAME:COLLECTORS_AGENT_NAME_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,AGENT_NAME_TYPE)"},{"column":"PERSON:DEATH_DATE_DATE","data_type":"DATE","ui_function":""},{"column":"PERSON:DEATH_DATE","data_type":"VARCHAR2","ui_function":""},{"column":"PERSON:FIRST_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"PERSON:LAST_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"PERSON:MIDDLE_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"PERSON:PREFIX","data_type":"VARCHAR2","ui_function":""},{"column":"PERSON:SUFFIX","data_type":"VARCHAR2","ui_function":""},{"column":"AGENT:DEACC_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"AGENT_NAME:DEACC_AGENT_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"DEACC_ITEM:DEACC_ITEM_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"DEACCESSION:DEACC_NUMBER","data_type":"VARCHAR2","ui_function":""},{"column":"DEACCESSION:DEACC_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"DEACCESSION:DEACC_STATUS","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,DEACC_STATUS)"},{"column":"DEACCESSION:DEACC_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,DEACC_TYPE)"},{"column":"IDENTIFICATION:ACCEPTED_ID_FG","data_type":"NUMBER","ui_function":""},{"column":"TAXONOMY:AUTHOR_TEXT","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,author_text)"},{"column":"TAXONOMY:PHYLCLASS","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,class)"},{"column":"COMMON_NAME:COMMON_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"IDENTIFICATION:DATE_MADE_DATE","data_type":"DATE","ui_function":""},{"column":"IDENTIFICATION_AGENT:IDENTIFICATIONS_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"TAXONOMY:DISPLAY_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"TAXONOMY:DIVISION","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,division)"},{"column":"TAXONOMY:FAMILY","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,family)"},{"column":"TAXONOMY:FULL_TAXON_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"TAXONOMY:GENUS","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,genus)"},{"column":"IDENTIFICATION:IDENTIFICATION_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"IDENTIFICATION:IDENTIFICATIONS_PUBLICATION_ID","data_type":"NUMBER","ui_function":"makePublicationPicker"},{"column":"AGENT_NAME:IDENTIFICATIONS_AGENT_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"AGENT_NAME:IDENTIFICATIONS_AGENT_NAME_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,AGENT_NAME_TYPE)"},{"column":"TAXONOMY:IDENTIFICATIONS_SCIENTIFIC_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"TAXONOMY:IDENTIFICATIONS_SOURCE_AUTHORITY","data_type":"VARCHAR2","ui_function":""},{"column":"IDENTIFICATION_TAXONOMY:IDENTIFICATIONS_TAXON_NAME_ID","data_type":"NUMBER","ui_function":"makeScientificNameAutocompleteMeta"},{"column":"TAXONOMY:IDENTIFICATIONS_VALID_CATALOG_TERM_FG","data_type":"NUMBER","ui_function":""},{"column":"IDENTIFICATION:IDENTIFICATIONS_COLLECTION_OBJECT_ID","data_type":"NUMBER","ui_function":"makeCatalogedItemAutocompleteMeta"},{"column":"IDENTIFICATION_AGENT:IDENTIFIER_ORDER","data_type":"NUMBER","ui_function":""},{"column":"TAXONOMY:INFRACLASS","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,infraclass)"},{"column":"TAXONOMY:INFRAORDER","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,infradorder)"},{"column":"TAXONOMY:INFRASPECIFIC_AUTHOR","data_type":"VARCHAR2","ui_function":""},{"column":"TAXONOMY:INFRASPECIFIC_RANK","data_type":"VARCHAR2","ui_function":""},{"column":"TAXONOMY:KINGDOM","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,kingdom)"},{"column":"IDENTIFICATION:MADE_DATE","data_type":"VARCHAR2","ui_function":""},{"column":"IDENTIFICATION:NATURE_OF_ID","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,NATURE_OF_ID)"},{"column":"TAXONOMY:NOMENCLATURAL_CODE","data_type":"VARCHAR2","ui_function":""},{"column":"TAXONOMY:TAXON_STATUS","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,TAXON_STATUS)"},{"column":"TAXONOMY:PHYLORDER","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,order)"},{"column":"TAXONOMY:PHYLUM","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,phylum)"},{"column":"TAXONOMY:SCIENTIFICNAMEID_GUID_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,GUID_TYPE)"},{"column":"TAXONOMY:SPECIES","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,species)"},{"column":"IDENTIFICATION:STORED_AS_FG","data_type":"NUMBER","ui_function":""},{"column":"TAXONOMY:SUBCLASS","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,subclass)"},{"column":"TAXONOMY:SUBDIVISION","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,subdivision)"},{"column":"TAXONOMY:SUBFAMILY","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,subfamily)"},{"column":"TAXONOMY:SUBGENUS","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,subgenus)"},{"column":"TAXONOMY:SUBORDER","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,suborder)"},{"column":"TAXONOMY:SUBPHYLUM","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,subphylum)"},{"column":"TAXONOMY:SUBSECTION","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,subsection)"},{"column":"TAXONOMY:SUBSPECIES","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,subspecies)"},{"column":"TAXONOMY:SUPERCLASS","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,superclass)"},{"column":"TAXONOMY:SUPERFAMILY","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,superfamily)"},{"column":"TAXONOMY:SUPERORDER","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,superorder)"},{"column":"IDENTIFICATION:TAXA_FORMULA","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,TAXA_FORMULA)"},{"column":"TAXONOMY:TAXON_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"TAXONOMY:TAXONID_GUID_TYPE","data_type":"VARCHAR2","ui_function":""},{"column":"TAXONOMY:TRIBE","data_type":"VARCHAR2","ui_function":"makeTaxonSearchAutocomplete(searchText:,tribe)"},{"column":"IDENTIFICATION_TAXONOMY:VARIABLE","data_type":"CHAR","ui_function":""},{"column":"TAXONOMY:SCIENTIFICNAMEID","data_type":"VARCHAR2","ui_function":""},{"column":"TAXONOMY:GUID","data_type":"VARCHAR2","ui_function":""},{"column":"TAXONOMY:TAXONID","data_type":"VARCHAR2","ui_function":""},{"column":"FLAT:ANY_GEOGRAPHY","data_type":"CTXKEYWORD","ui_function":""},{"column":"FLAT:KEYWORD","data_type":"CTXKEYWORD","ui_function":""},{"column":"FLAT:MAX_DEPTH_IN_M","data_type":"NUMBER","ui_function":""},{"column":"FLAT:MAX_ELEV_IN_M","data_type":"NUMBER","ui_function":""},{"column":"FLAT:MIN_DEPTH_IN_M","data_type":"NUMBER","ui_function":""},{"column":"FLAT:MIN_ELEV_IN_M","data_type":"NUMBER","ui_function":""},{"column":"AGENT:LOAN_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"AGENT_NAME:LOAN_AGENT_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"LOAN_ITEM:LOAN_ITEM_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"LOAN:LOAN_NUMBER","data_type":"VARCHAR2","ui_function":""},{"column":"LOAN:LOAN_STATUS","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,LOAN_STATUS)"},{"column":"MEDIA:AUTO_EXTENSION","data_type":"VARCHAR2","ui_function":""},{"column":"MEDIA:AUTO_FILENAME","data_type":"VARCHAR2","ui_function":""},{"column":"MEDIA:AUTO_HOST","data_type":"VARCHAR2","ui_function":""},{"column":"MEDIA_LABELS:LABEL_VALUE","data_type":"VARCHAR2","ui_function":""},{"column":"MEDIA:MASK_MEDIA_FG","data_type":"NUMBER","ui_function":""},{"column":"MEDIA_RELATIONS:MEDIA_CREATION_AGENT","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"MEDIA_LABELS:MEDIA_LABEL","data_type":"VARCHAR2","ui_function":"makeMediaLabelTypePicker()"},{"column":"makeAgentAutocompleteMeta:ASSIGNED_BY_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"MEDIA:MEDIA_LICENSE_ID","data_type":"NUMBER","ui_function":"makeLicenseAutocompleteMeta"},{"column":"MEDIA_RELATIONS:CREATED_BY_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"MEDIA:MEDIA_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,MEDIA_TYPE)"},{"column":"MEDIA:MEDIA_URI","data_type":"VARCHAR2","ui_function":""},{"column":"MEDIA:MIME_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,MIME_TYPE)"},{"column":"MEDIA_RELATIONS:NEXT_MEDIA_RELATIONSHIP","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,MEDIA_RELATIONSHIP)"},{"column":"MEDIA_RELATIONS:NEXT_RELATED_PRIMARY_KEY","data_type":"NUMBER","ui_function":""},{"column":"MEDIA:AUTO_PATH","data_type":"VARCHAR2","ui_function":""},{"column":"MEDIA:PREVIEW_URI","data_type":"VARCHAR2","ui_function":""},{"column":"MEDIA:AUTO_PROTOCOL","data_type":"VARCHAR2","ui_function":""},{"column":"UNDERSCORE_COLLECTION:HTML_DESCRIPTION","data_type":"CLOB","ui_function":""},{"column":"UNDERSCORE_COLLECTION:MASK_FG","data_type":"NUMBER","ui_function":""},{"column":"UNDERSCORE_COLLECTION:COLLECTION_NAME","data_type":"VARCHAR2","ui_function":""},{"column":"UNDERSCORE_COLLECTION:NAMED GROUPS_UNDERSCORE_COLLECTION_ID","data_type":"NUMBER","ui_function":"makeNamedCollectionPicker"},{"column":"UNDERSCORE_COLLECTION:UNDERSCORE_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"UNDERSCORE_COLLECTION:NAMED GROUPS_DESCRIPTION","data_type":"VARCHAR2","ui_function":""},{"column":"UNDERSCORE_COLLECTION:UNDERSCORE_COLLECTION_ID_RAW","data_type":"NUMBER","ui_function":""},{"column":"BIOL_INDIV_RELATIONS:CREATED_BY","data_type":"VARCHAR2","ui_function":""},{"column":"BIOL_INDIV_RELATIONS:RELATIONSHIPS_COLLECTION_OBJECT_ID","data_type":"NUMBER","ui_function":"makeCatalogedItemAutocompleteMeta"},{"column":"BIOL_INDIV_RELATIONS:RELATED_COLL_OBJECT_ID","data_type":"NUMBER","ui_function":"makeCatalogedItemAutocompleteMeta"},{"column":"BIOL_INDIV_RELATIONS:BIOL_INDIV_RELATION_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"BIOL_INDIV_RELATIONS:BIOL_INDIV_RELATIONSHIP","data_type":"VARCHAR2","ui_function":""},{"column":"SPECIMEN_PART:IS_TISSUE","data_type":"NUMBER","ui_function":""},{"column":"SPECIMEN_PART:PART_MODIFIER","data_type":"VARCHAR2","ui_function":""},{"column":"SPECIMEN_PART:PART_NAME","data_type":"VARCHAR2","ui_function":"makePartNameAutocompleteMeta()"},{"column":"COLL_OBJECT_REMARK:PART_REMARKS","data_type":"VARCHAR2","ui_function":""},{"column":"SPECIMEN_PART:DERIVED_FROM_CAT_ITEM","data_type":"NUMBER","ui_function":"makeCatalogedItemAutocompleteMeta"},{"column":"SPECIMEN_PART:PRESERVE_METHOD","data_type":"VARCHAR2","ui_function":"makePreserveMethodAutocompleteMeta()"},{"column":"SPECIMEN_PART:SAMPLED_FROM_OBJ_ID","data_type":"NUMBER","ui_function":""},{"column":"COLL_OBJECT:SPECIMEN_PART_CONDITION","data_type":"VARCHAR2","ui_function":""},{"column":"SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_REMARK","data_type":"VARCHAR2","ui_function":""},{"column":"SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_TYPE","data_type":"VARCHAR2","ui_function":"makeCTFieldSearchAutocomplete(searchText:,SPECPART_ATTRIBUTE_TYPE)"},{"column":"SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_UNITS","data_type":"VARCHAR2","ui_function":""},{"column":"SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_VALUE","data_type":"VARCHAR2","ui_function":""},{"column":"SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_DETERMINED_BY_AGENT_ID","data_type":"NUMBER","ui_function":"makeAgentAutocompleteMeta"},{"column":"SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_DETERMINED_DATE","data_type":"DATE","ui_function":""},{"column":"TAXA_TERMS_ALL:TAXA_TERM_ALL","data_type":"VARCHAR2","ui_function":""},{"column":"TAXA_TERMS:TAXA_TERM","data_type":"VARCHAR2","ui_function":""}]');
														</script>
														<label for="field1" class="data-entry-label">Search Field</label>
														
														<select title="Select Field to search..." name="field1" id="field1_jqxComboBox" class="" required="" role="combobox" aria-autocomplete="both" aria-disabled="false" style="display: none;">
															
																<optgroup label="Select a field to search...."><option value="" label="" selected="selected"></option></optgroup>
															
																	<optgroup label="Accessions">
																	
																<option value="TRANS_AGENT:ACCESSIONS_AGENT_ID">Accession Agent (pick) (Accessions:TRANS_AGENT) Agent with a role in the transaction</option>
															
																<option value="AGENT_NAME:ACCESSIONS_AGENT_NAME">Accession Agent Name (partial match) (Accessions:AGENT_NAME) The value of the name</option>
															
																<option value="TRANS_AGENT:TRANS_AGENT_ROLE">Accession Agent Role (Accessions:TRANS_AGENT) The role of the agent in the transaction.</option>
															
																<option value="ACCN:ACCN_NUMBER">Accession Number (partial match) (Accessions:ACCN) The accession number.  Domain: integers</option>
															
																<option value="CATALOGED_ITEM:ACCN_ID">Accession Number (pick) (Accessions:CATALOGED_ITEM) The accession under which this cataloged item was brought into the museum.</option>
															
																<option value="ACCN:ACCN_STATUS">Accession Status (Accessions:ACCN) The status of this accession.</option>
															
																<option value="TRANS:ACCESSIONS_TRANSACTION_ID">Accession Transaction Id (Accessions:TRANS) Surrogate Numeric Primary Key</option>
															
																<option value="ACCN:ACCN_TYPE">Accession Type (Accessions:ACCN) The type of the accession</option>
															
																<option value="TRANS:ACCESSIONS_COLLECTION_ID">Accessioned in Collection (pick) (Accessions:TRANS) Collection that this transaction is related to.</option>
															
																<option value="ACCN:ESTIMATED_COUNT">Estimated Count (Accessions:ACCN) An estimate of the number of collection objects in this accession.  Domain: integers</option>
															
																<option value="TRANS:NATURE_OF_MATERIAL">Nature Of Material (Accessions:TRANS) A description of the material involved in the transaction.</option>
															
																<option value="ACCN:RECEIVED_DATE">Received Date [yyyy-mm-dd] (Accessions:ACCN) The date on which the material in this accession was received.</option>
															
																<option value="ACCN:RECEIVED_DATE_TEXT">Received Date as Text (Accessions:ACCN) The date on which this accession was recieved as text.</option>
															
																<option value="TRANS:TRANS_DATE">Trans Date [yyyy-mm-dd] (Accessions:TRANS) Date on which this transaction occurred.</option>
															
																<option value="TRANS:TRANS_REMARKS">Transaction Remarks (Accessions:TRANS) Internal remarks concerning the transaction.</option>
															
																		</optgroup>
																		
																	<optgroup label="Attributes">
																	
																<option value="ATTRIBUTES:DETERMINATION_METHOD">Attribute Determination Method (Attributes:ATTRIBUTES) method by which the attribute value was determined</option>
															
																<option value="ATTRIBUTES:ATTRIBUTES_DETERMINED_BY_AGENT_ID">Attribute Determined By Agent (pick) (Attributes:ATTRIBUTES) agent who asserted the attribute value</option>
															
																<option value="ATTRIBUTES:ATTRIBUTES_DETERMINED_DATE">Attribute Determined Date [yyyy-mm-dd] (Attributes:ATTRIBUTES) date on which the attribute value was determined.</option>
															
																<option value="ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_REMARK">Attribute Remark (Attributes:ATTRIBUTES) remarks concerning the attribute value</option>
															
																<option value="ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_TYPE">Attribute Type (Attributes:ATTRIBUTES) the kind of atrribute</option>
															
																<option value="ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_UNITS">Attribute Units (Attributes:ATTRIBUTES) units, if any, for the attribute value.</option>
															
																<option value="ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_VALUE">Attribute Value (Attributes:ATTRIBUTES) the value of the attribute</option>
															
																		</optgroup>
																		
																	<optgroup label="Cataloged Item">
																	
																<option value="COLL_OBJECT_REMARK:ASSOCIATED_SPECIES">Associated Species (Cataloged Item:COLL_OBJECT_REMARK) Species found in association with the collection object in its gathering.</option>
															
																<option value="CATALOGED_ITEM:CAT_NUM">Catalog Number (Cataloged Item:CATALOGED_ITEM) The catalog number of the cataloged item, including any prefix or suffix.  Automatically assembled from cat_num_prefix, cat_num_integer, and cat_num_suffix.</option>
															
																<option value="CATALOGED_ITEM:CAT_NUM_INTEGER">Catalog Number Integer (Cataloged Item:CATALOGED_ITEM) The numeric portion of the catalog number.</option>
															
																<option value="CATALOGED_ITEM:CAT_NUM_PREFIX">Catalog Number Prefix (Cataloged Item:CATALOGED_ITEM) The prefix portion of the catalog number, if any.  Including any separator.  Example "R-"</option>
															
																<option value="CATALOGED_ITEM:CAT_NUM_SUFFIX">Catalog Number Suffix (Cataloged Item:CATALOGED_ITEM) The suffix portion of the catalog number, if any. Including any separator.  Example "-a"</option>
															
																<option value="CATALOGED_ITEM:CATALOGED_ITEM_TYPE">Cataloged Item Type (Cataloged Item:CATALOGED_ITEM) The type of the cataloged item, FS=fossil voucher, BI=biological preserved specimen, HO=human observation.    Broadly corresponds to dwc:basisOfRecord and the Darwin Core classes. </option>
															
																<option value="COLL_OBJECT:COLL_OBJ_DISPOSITION">Coll Obj Disposition (Cataloged Item:COLL_OBJECT) The current disposition of the collection object.</option>
															
																<option value="COLL_OBJECT:COLL_OBJECT_ENTERED_DATE">Coll Object Entered Date [yyyy-mm-dd] (Cataloged Item:COLL_OBJECT) The date on which the collection object record was created.</option>
															
																<option value="COLL_OBJECT_REMARK:COLL_OBJECT_REMARKS">Coll Object Remarks (Cataloged Item:COLL_OBJECT_REMARK) Comments or notes regarding the specimen.</option>
															
																<option value="COLL_OBJECT:COLL_OBJECT_TYPE">Coll Object Type [not working yet] (Cataloged Item:COLL_OBJECT) type of collection object record, for cataloged item or for part thereof.  Domain: SP, CI, SS</option>
															
																<option value="CATALOGED_ITEM:CATALOGED ITEM_COLLECTING_EVENT_ID">Collecting Event (pick specific locality/date) (Cataloged Item:CATALOGED_ITEM) The collecting event in which this cataloged item was collected.</option>
															
																<option value="CATALOGED_ITEM:CATALOGED ITEM_COLLECTION_ID">Collection (pick) (Cataloged Item:CATALOGED_ITEM) Foreign key to the collection within which this cataloged item is held.  Enforces virtual private database limitiations on collection.</option>
															
																<option value="CATALOGED_ITEM:COLLECTION_CDE">Collection Code (Cataloged Item:CATALOGED_ITEM) The collection code for the collection within which this cataloged item is held.  Autopopulated convenience field with value obtained from collection.</option>
															
																<option value="COLL_OBJECT:CONDITION">Condition (Cataloged Item:COLL_OBJECT) The current condition of the collection object</option>
															
																<option value="COLL_OBJECT_REMARK:DISPOSITION_REMARKS">Disposition Remarks (Cataloged Item:COLL_OBJECT_REMARK) Comments or notes regarding the disposition of the collection object.</option>
															
																<option value="COLL_OBJECT:ENTERED_PERSON_ID">Entered By Person (pick) (Cataloged Item:COLL_OBJECT) The agent who created the collection object record.</option>
															
																<option value="CATALOGED_ITEM:CATALOGED ITEM_COLLECTION_OBJECT_ID">GUID (pick by GUID/Locality/Identification)  (Cataloged Item:CATALOGED_ITEM) cataloged items are a subtype of collection objects.</option>
															
																<option value="COLL_OBJECT:LAST_EDIT_DATE">Last Edit Date (dwc:modified) [yyyy-mm-dd] (Cataloged Item:COLL_OBJECT) The date on which the collection object record was most recently edited</option>
															
																<option value="COLL_OBJECT:LAST_EDITED_PERSON_ID">Last Edited By (pick) (Cataloged Item:COLL_OBJECT) The agent who most recently edited the collection object record.</option>
															
																<option value="COLL_OBJECT:LOT_COUNT">Lot Count (Cataloged Item:COLL_OBJECT) The number of items making up the collection object.</option>
															
																<option value="COLL_OBJECT:LOT_COUNT_MODIFIER">Lot Count Modifier (Cataloged Item:COLL_OBJECT) A textual modifier for the lot count indicating range or uncertainty in the count.</option>
															
																<option value="COLL_OBJECT_REMARK:HABITAT">Microhabitat (Cataloged Item:COLL_OBJECT_REMARK) Microhabitat information related to the gathering of the collection object.  See also collecting_event.habitat_desc for habitat information.</option>
															
																<option value="COLL_OBJECT:FLAGS">Missing Information (Cataloged Item:COLL_OBJECT) </option>
															
																<option value="COLL_OBJ_OTHER_ID_NUM:DISPLAY_VALUE">Other Number (Cataloged Item:COLL_OBJ_OTHER_ID_NUM) The value of the other number, assembled automatically by concatenationg other-id_prefix, other_id_number, and other_id_suffix.   No additional characters are included in the concatenation.</option>
															
																<option value="COLL_OBJ_OTHER_ID_NUM:OTHER_ID_NUMBER">Other Number Integer (Cataloged Item:COLL_OBJ_OTHER_ID_NUM) The numeric portion of the other number.</option>
															
																<option value="COLL_OBJ_OTHER_ID_NUM:OTHER_ID_PREFIX">Other Number Prefix (Cataloged Item:COLL_OBJ_OTHER_ID_NUM) An alphanumeric prefix for the other number.  If a separator is needed between the prefix and the number, it must be included in the prefix.</option>
															
																<option value="COLL_OBJ_OTHER_ID_NUM:OTHER_ID_SUFFIX">Other Number Suffix (Cataloged Item:COLL_OBJ_OTHER_ID_NUM) An alphanumeric prefix for the other number.  If a separator is needed between the other umber and the suffix, it must be included in the suffix.</option>
															
																<option value="COLL_OBJ_OTHER_ID_NUM:OTHER_ID_TYPE">Other Number Type (Cataloged Item:COLL_OBJ_OTHER_ID_NUM) The type of the other number</option>
															
																<option value="COLL_OBJECT:COLL_OBJ_COLLECTION_OBJECT_ID">collection_object_id (Cataloged Item:COLL_OBJECT) surrogate numeric primary key</option>
															
																		</optgroup>
																		
																	<optgroup label="Citations">
																	
																<option value="CITATION:CIT_CURRENT_FG">Cit Current Flag (Citations:CITATION) Deprecated?  Flag indicating whether this is a current citation or not.  Domain: 0, 1.   Almost all values are 1,  Not used in UI.</option>
															
																<option value="CTCITATION_TYPE_STATUS:CATEGORY">Citation Category (Primary,Secondary,Voucher) (Citations:CTCITATION_TYPE_STATUS) </option>
															
																<option value="CTCITATION_TYPE_STATUS:CITATIONS_DESCRIPTION">Citation Description (Citations:CTCITATION_TYPE_STATUS) </option>
															
																<option value="CITATION:CITATION_PAGE_URI">Citation Page IRI (Citations:CITATION) A URI at which a resource representing the page in the publication on which the collection object is cited occurs.</option>
															
																<option value="CITATION:CITATION_REMARKS">Citation Remarks (Citations:CITATION) Comments or notes about the citation.</option>
															
																<option value="CITATION:CITATION_TEXT">Citation Text (Citations:CITATION) Text quoted from the citation.</option>
															
																<option value="CITATION:CITATIONS_TYPE_STATUS">Citation Type Status (Citations:CITATION) Primary, Secondary, or Voucher status, or other category of assertion about the cataloged item asserted by the publication.</option>
															
																<option value="CITATION:CITATIONS_COLLECTION_OBJECT_ID">Cited Collection Object (pick) (Citations:CITATION) The collection object mentioned in the publication</option>
															
																<option value="TAXONOMY:CITED_GENUS">Cited Genus (Citations:TAXONOMY) Taxonomic genus into which the taxon is placed, or the generic epithet for the taxon.</option>
															
																<option value="FORMATTED_PUBLICATION:CITATION_FORMATTED_PUBLICATION">Cited Publication (Citations:FORMATTED_PUBLICATION) </option>
															
																<option value="CITATION:CITATIONS_PUBLICATION_ID">Cited Publication (pick) (Citations:CITATION) The publication being cited</option>
															
																<option value="CITATION:CITED_TAXON_NAME_ID">Cited Taxon Name (pick) (Citations:CITATION) The taxon name applied to the collection object in the publication.</option>
															
																<option value="TAXONOMY:CITED_FAMILY">Family of cited taxon (Citations:TAXONOMY) Taxonomic Family into which the taxon is placed.</option>
															
																<option value="CITATION:OCCURS_PAGE_NUMBER">Occurs Page Number (Citations:CITATION) The first page number in the publication on which the collection object is cited using the cited taxon name.</option>
															
																<option value="CITATION:REP_PUBLISHED_YEAR">Reported Year of Publcation (Citations:CITATION) Year that the portion of the publication containing the citation is reported to have been published.</option>
															
																<option value="TAXONOMY:CITED_ORDER">Taxonomic Order of cited taxon (Citations:TAXONOMY) Taxonomic order into which the taxon is placed.</option>
															
																		</optgroup>
																		
																	<optgroup label="Collecting Events">
																	
																<option value="LAT_LONG:ACCEPTED_LAT_LONG_FG">Accepted Lat Long Flag (Collecting Events:LAT_LONG) Flag indicating if this is the accepted georeference for a locality.  1 is accepted, 2 is not accepted.</option>
															
																<option value="COLLECTING_EVENT:DATE_DETERMINED_BY_AGENT_ID">Agent who set Date Determined (pick) (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="COLLECTING_EVENT:BEGAN_DATE">Began Date (yyyy-mm-dd) (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="COLLECTING_EVENT:COLLECTING EVENTS_COLLECTING_EVENT_ID">Collecting Event (pick) (Collecting Events:COLLECTING_EVENT) Surrogate numeric primary key.</option>
															
																<option value="COLLECTING_EVENT:CE_COLLECTING_EVENT_ID">Collecting Event ID (Collecting Events:COLLECTING_EVENT) Surrogate numeric primary key.</option>
															
																<option value="COLL_EVENT_NUMBER:COLL_EVENT_NUMBER">Collecting Event Number (Collecting Events:COLL_EVENT_NUMBER) the value of the collecting event number</option>
															
																<option value="COLL_EVENT_NUMBER:COLL_EVENT_NUM_SERIES_ID">Collecting Event Number Series Id (Collecting Events:COLL_EVENT_NUMBER) number series from which this number comes</option>
															
																<option value="COLLECTING_EVENT:COLL_EVENT_REMARKS">Collecting Event Remarks (Collecting Events:COLLECTING_EVENT) Free text assertions concerning the collecting event.</option>
															
																<option value="LOCALITY:COLLECTING EVENTS_GEOG_AUTH_REC_ID">Collecting Events Geog Auth Rec Id (Collecting Events:LOCALITY) The higher geography in which this locality is placed.</option>
															
																<option value="GEOG_AUTH_REC:COLLECTING EVENTS_SOURCE_AUTHORITY">Collecting Events Source Authority (Collecting Events:GEOG_AUTH_REC) Authoritative source for the information in the higher geography record.</option>
															
																<option value="GEOG_AUTH_REC:COLLECTING EVENTS_VALID_CATALOG_TERM_FG">Collecting Events Valid Catalog Term Flag (Collecting Events:GEOG_AUTH_REC) Flag indicating if this higher geography can be used in data entry: (1) yes, (0) no.</option>
															
																<option value="COLLECTING_EVENT:COLLECTING_METHOD">Collecting Method (Collecting Events:COLLECTING_EVENT) Means by which material collected in this collecting event were collected or recorded.</option>
															
																<option value="COLLECTING_EVENT:COLLECTING_SOURCE">Collecting Source (Collecting Events:COLLECTING_EVENT) General sort of provenance for material recorded in this collecting event.</option>
															
																<option value="COLLECTING_EVENT:COLLECTING_TIME">Collecting Time (Collecting Events:COLLECTING_EVENT) Time of day during which the collecting event occurred.</option>
															
																<option value="GEOG_AUTH_REC:CONTINENT_OCEAN">Continent Ocean (Collecting Events:GEOG_AUTH_REC) Continent or Ocean for the higher geography.</option>
															
																<option value="GEOG_AUTH_REC:COUNTRY">Country (Collecting Events:GEOG_AUTH_REC) Country level entity for the higher geography.</option>
															
																<option value="GEOG_AUTH_REC:COUNTY">County/Shire/Parish (Collecting Events:GEOG_AUTH_REC) Secondary division of a country for the higher geography.  Does not include the word County for counties.</option>
															
																<option value="LOCALITY:CURATED_FG">Curated Flag (Collecting Events:LOCALITY) Marker that this locality record has been edited and curated to a target state and shouldn't normally be edited.</option>
															
																<option value="COLLECTING_EVENT:DATE_BEGAN_DATE">Date Began Date [yyyy-mm-dd] (Collecting Events:COLLECTING_EVENT) deprecated field, legacy values retained.</option>
															
																<option value="COLLECTING_EVENT:DATE_ENDED_DATE">Date Ended Date [yyyy-mm-dd] (Collecting Events:COLLECTING_EVENT) deprecated field, legacy values retained.</option>
															
																<option value="LAT_LONG:DATUM">Datum (Collecting Events:LAT_LONG) The horizontal geodedic datum or spatial reference system including geodetic datum for the georeference.</option>
															
																<option value="COLLECTING_EVENT:ENDDAYOFYEAR">Day of year for end of event (dwc:endDayOfYear) (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="COLLECTING_EVENT:STARTDAYOFYEAR">Day of year for start of event  (dwc:startDayOfYear) (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="LAT_LONG:DEC_LAT_MIN">Dec Lat Min (Collecting Events:LAT_LONG) For coordinates with an orig_lat_long_units of decimal minutes, the decimal minutes portion of the latitude.</option>
															
																<option value="LAT_LONG:DEC_LAT">Dec Latitude (Collecting Events:LAT_LONG) Semiautomatic, the latitude portion of the georeference represented as decimal degrees in the range -90 to 90. Expected to be populated for all georeferences, but this is not enforced.</option>
															
																<option value="LAT_LONG:DEC_LONG_MIN">Dec Long Min (Collecting Events:LAT_LONG) For coordinates with an orig_lat_long_units of decimal minutes, the decimal minutes portion of the longitude.</option>
															
																<option value="LAT_LONG:DEC_LONG">Dec Longitude (Collecting Events:LAT_LONG) Semiautomatic, the longitude portion of the georeference represented as decimal degrees in the range -180 to 180.  Expected to be populated for all georeferences, but this is not enforced.</option>
															
																<option value="LOCALITY:DEPTH_UNITS">Depth Units (Collecting Events:LOCALITY) Units for min and max depth.</option>
															
																<option value="COLLECTING_EVENT:ENDED_DATE">Ended Date (yyyy-mm-dd) (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="LAT_LONG:EXTENT">Extent (Collecting Events:LAT_LONG) The distance from a point defined by lat/long coordinates to the outer perimeter of the feature of origin</option>
															
																<option value="GEOG_AUTH_REC:FEATURE">Feature (Collecting Events:GEOG_AUTH_REC) Land feature for the higher geography.</option>
															
																<option value="LAT_LONG:FIELD_VERIFIED_FG">Field Verified Flag (Collecting Events:LAT_LONG) Unused.  Deprecated.  Flag indicating verification status of this georeference.  </option>
															
																<option value="COLLECTING_EVENT:FISH_FIELD_NUMBER">Fish Field Number (Collecting Events:COLLECTING_EVENT) Field number assigned to the collecting event by the Ichtyology department.</option>
															
																<option value="LAT_LONG:GPSACCURACY">GPS/GNSS Accuracy (Collecting Events:LAT_LONG) If georefernece was obtained from a GNSS/GPS reciever, the accuracy for the coordinate asserted by that recever at the time the location was recorded.</option>
															
																<option value="LAT_LONG:GEOLOCATE_NUMRESULTS">Geolocate Number of Results (Collecting Events:LAT_LONG) For georeferences returned from geolocate, either automated or manual, the number of results found by geolocate out of which the georeference was selected.</option>
															
																<option value="LAT_LONG:GEOLOCATE_PARSEPATTERN">Geolocate Parse Pattern (Collecting Events:LAT_LONG) For georeferences returned from geolocate, either automated or manual, the pattern geolocate matched in the specific locality text that geolocate used to assert the georeference.</option>
															
																<option value="LAT_LONG:GEOLOCATE_PRECISION">Geolocate Precision (Collecting Events:LAT_LONG) For georeferences returned from geolocate, either automated or manual, the precision asserted by geolocate.</option>
															
																<option value="LAT_LONG:GEOLOCATE_SCORE">Geolocate Score (Collecting Events:LAT_LONG) For georeferences returned from geolocate, either automated or manual, the score for the selected georeference asserted by geolocate.</option>
															
																<option value="GEOLOGY_ATTRIBUTES:GEO_ATT_DETERMINED_DATE">Geological Attribute Determined Date [yyyy-mm-dd] (Collecting Events:GEOLOGY_ATTRIBUTES) date on which the attribute value was determined for this locality</option>
															
																<option value="GEOLOGY_ATTRIBUTES:GEO_ATT_DETERMINED_METHOD">Geological Attribute Determined Method (Collecting Events:GEOLOGY_ATTRIBUTES) method by which the attribute value was determined for this locality</option>
															
																<option value="GEOLOGY_ATTRIBUTES:GEO_ATT_DETERMINER_ID">Geological Attribute Determiner (pick) (Collecting Events:GEOLOGY_ATTRIBUTES) agent id for the person who applied this attribute to this locality</option>
															
																<option value="GEOLOGY_ATTRIBUTES:GEO_ATT_REMARK">Geological Attribute Remark (Collecting Events:GEOLOGY_ATTRIBUTES) remarks concerning this geological attribute.</option>
															
																<option value="GEOLOGY_ATTRIBUTES:GEO_ATT_VALUE">Geological Atttribute Value (Collecting Events:GEOLOGY_ATTRIBUTES) value of attribute</option>
															
																<option value="GEOLOGY_ATTRIBUTES:GEOLOGY_ATTRIBUTE">Geology Attribute (Collecting Events:GEOLOGY_ATTRIBUTES) type of attribute</option>
															
																<option value="GEOLOGY_ATTRIBUTES:GEOLOGY_ATTRIBUTE_ID">Geology Attribute Id (Collecting Events:GEOLOGY_ATTRIBUTES) surrogage numeric primary key</option>
															
																<option value="LOCALITY:GEOREF_UPDATED_DATE">Georef Updated Date [yyyy-mm-dd] (Collecting Events:LOCALITY) </option>
															
																<option value="LAT_LONG:COLLECTING EVENTS_DETERMINED_BY_AGENT_ID">Georeference Determined By Agent (pick) (Collecting Events:LAT_LONG) Agent who made this georefernce.</option>
															
																<option value="LAT_LONG:COLLECTING EVENTS_DETERMINED_DATE">Georeference Determined Date [yyyy/mm/dd] (Collecting Events:LAT_LONG) Date on which this georeference was made.</option>
															
																<option value="LAT_LONG:MAX_ERROR_UNITS">Georeference Max Error Units (Collecting Events:LAT_LONG) Units for max_error_distance.</option>
															
																<option value="LAT_LONG:MAX_ERROR_DISTANCE">Georeference Maximum Error Distance (Collecting Events:LAT_LONG) Error radius for the georeference around the single specified coordinate.</option>
															
																<option value="LAT_LONG:GEOREFMETHOD">Georeference Method (Collecting Events:LAT_LONG) Method by which the georeference was made.</option>
															
																<option value="LAT_LONG:VERIFICATIONSTATUS">Georeference Verification Status (Collecting Events:LAT_LONG) Verification of the validity and accuracy of this georeference.</option>
															
																<option value="LAT_LONG:VERIFIED_BY_AGENT_ID">Georeference Verified By  (pick) (Collecting Events:LAT_LONG) Agent who verified the georeference.</option>
															
																<option value="LOCALITY:GEOREF_BY">Georeferenced By (username) (Collecting Events:LOCALITY) </option>
															
																<option value="COLLECTING_EVENT:HABITAT_DESC">Habitat (Collecting Events:COLLECTING_EVENT) Information about the habitat present at the locality at the time of the collecting event.  See also coll_object_remarks.habitat for microhabitat.</option>
															
																<option value="GEOG_AUTH_REC:HIGHER_GEOG">Higher Geography (Collecting Events:GEOG_AUTH_REC) Automatic, the assembled higher geography as a colon separated string.</option>
															
																<option value="GEOG_AUTH_REC:HIGHERGEOGRAPHYID_GUID_TYPE">Highergeographyid GUID Type (Collecting Events:GEOG_AUTH_REC) type of identifier used in HIGHERGEOGRAPHYID</option>
															
																<option value="GEOG_AUTH_REC:ISLAND">Island (Collecting Events:GEOG_AUTH_REC) Island for the higher geography.</option>
															
																<option value="GEOG_AUTH_REC:ISLAND_GROUP">Island Group (Collecting Events:GEOG_AUTH_REC) Named group of islands for the higher geography.</option>
															
																<option value="LAT_LONG:LAT_LONG_FOR_NNP_FG">Lat Long Is For Nearest Named Place Flag (Collecting Events:LAT_LONG) Flag indicating if the georeference is for the nearest named place.</option>
															
																<option value="LAT_LONG:LAT_LONG_REF_SOURCE">Lat Long Ref Source (Collecting Events:LAT_LONG) Reference consulted as a source for the georeference.</option>
															
																<option value="LAT_LONG:LAT_LONG_REMARKS">Lat Long Remarks (Collecting Events:LAT_LONG) Free text comments regarding this georeference.</option>
															
																<option value="LAT_LONG:LAT_DEG">Latitude Degrees (Collecting Events:LAT_LONG) The degree portion of the latitude, expected to be a positive number in the range 0 to 90.</option>
															
																<option value="LAT_LONG:LAT_DIR">Latitude Direction (N/S) (Collecting Events:LAT_LONG) Direction for the latitude (lat_deg) N or S.   When N, dec_lat should be a positive number.</option>
															
																<option value="LAT_LONG:LAT_MIN">Latitude Minutes (Collecting Events:LAT_LONG) For coordinates with an orig_lat_long_units of degrees minutes seconds, the minutes portion of the latitude.</option>
															
																<option value="LAT_LONG:LAT_SEC">Latitude Sec (Collecting Events:LAT_LONG) For coordinates with an orig_lat_long_units of degrees minutes seconds, the seconds portion of the latitude.</option>
															
																<option value="LOCALITY:LOCALITY_LOCALITY_ID_PICK">Locality (pick) (Collecting Events:LOCALITY) Surrogate numeric primary key.</option>
															
																<option value="LOCALITY:LOCALITY_LOCALITY_ID">Locality ID (Collecting Events:LOCALITY) Surrogate numeric primary key.</option>
															
																<option value="LOCALITY:LOCALITY_REMARKS">Locality Remarks (Collecting Events:LOCALITY) Free text comments on the locality record.</option>
															
																<option value="LAT_LONG:LONG_DEG">Longitude Degrees (Collecting Events:LAT_LONG) The degree portion of the longitude, expected to be a positive number in the range 0 to 180.</option>
															
																<option value="LAT_LONG:LONG_DIR">Longitude Direction (E/W) (Collecting Events:LAT_LONG) Direction for the longitude (long_deg) E or W.   When E, dec_long should be a positive number.</option>
															
																<option value="LAT_LONG:LONG_MIN">Longitude Minutes (Collecting Events:LAT_LONG) For coordinates with an orig_lat_long_units of degrees minutes seconds, the minutes portion of the longitude.</option>
															
																<option value="LAT_LONG:LONG_SEC">Longitude Seconds (Collecting Events:LAT_LONG) For coordinates with an orig_lat_long_units of degrees minutes seconds, the seconds portion of the longitude.</option>
															
																<option value="LOCALITY:MAX_DEPTH">Maximum Depth (Collecting Events:LOCALITY) The greater depth of a range of depth below the local surface in depth units.</option>
															
																<option value="LOCALITY:MAXIMUM_ELEVATION">Maximum Elevation (Collecting Events:LOCALITY) Mimimum elevation in original elevation units.</option>
															
																<option value="LOCALITY:MIN_DEPTH">Minimum Depth (Collecting Events:LOCALITY) The lesser depth of a range of depth below a local surface in depth units.</option>
															
																<option value="LOCALITY:MINIMUM_ELEVATION">Minimum Elevation (Collecting Events:LOCALITY) Maximum elevation in orginal elevation units.</option>
															
																<option value="LAT_LONG:NEAREST_NAMED_PLACE">Nearest Named Place (Collecting Events:LAT_LONG) Nearest named place to the georefernce.</option>
															
																<option value="LOCALITY:NOGEOREFBECAUSE">No Georefernce Because (Collecting Events:LOCALITY) Reason why the locality is not georeferenced.</option>
															
																<option value="GEOG_AUTH_REC:OCEAN_REGION">Ocean Region (Collecting Events:GEOG_AUTH_REC) Ocean region for the higher geography.</option>
															
																<option value="GEOG_AUTH_REC:OCEAN_SUBREGION">Ocean Subregion (Collecting Events:GEOG_AUTH_REC) Ocean subregion for the higher geography.</option>
															
																<option value="LOCALITY:ORIG_ELEV_UNITS">Original Elevation Units (Collecting Events:LOCALITY) The units for minimum and maximum elevation.</option>
															
																<option value="LAT_LONG:ORIG_LAT_LONG_UNITS">Original Lat Long Units (Collecting Events:LAT_LONG) Form in which the latitude and longitude are stored in the georeference, degrees minutes seconds, degrees decimal minutes, or decimal degrees.  Determines which fields are combined to present the georeference in original form.</option>
															
																<option value="GEOG_AUTH_REC:QUAD">Quadrangle Name (Collecting Events:GEOG_AUTH_REC) Name of topographic quadrangle for the higher geography.</option>
															
																<option value="LOCALITY:RANGE">Range (PLSS) (Collecting Events:LOCALITY) PLSS range, direction east or west from baseline in units of 6 miles.</option>
															
																<option value="LOCALITY:RANGE_DIRECTION">Range Direction (PLSS) (Collecting Events:LOCALITY) PLSS range direction (E or W) from base line.</option>
															
																<option value="COLLECTING_EVENT:VERBATIMSRS">SRS for Verbatim Lat/Long (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="GEOG_AUTH_REC:SEA">Sea (Collecting Events:GEOG_AUTH_REC) Named sea for the higher geography, below ocean subregion, above water feature.</option>
															
																<option value="LOCALITY:SECTION">Section (PLSS) (Collecting Events:LOCALITY) PLSS section, number in range 1 to 36.</option>
															
																<option value="LOCALITY:SECTION_PART">Section Part (PLSS) (Collecting Events:LOCALITY) PLSS aliquot part, heirarchical reference to quarter or half section subdivisions.</option>
															
																<option value="LOCALITY:SOVEREIGN_NATION">Sovereign Nation (Collecting Events:LOCALITY) The nation with sovereignty over the place described by this locality.</option>
															
																<option value="LAT_LONG:SPATIALFIT">Spatial fit (Collecting Events:LAT_LONG) Ratio of the area of the point-radius uncertanty to actual area of the locality.  0 if locality is larger than point-radius, 1 if exact match, greater than 1 when point-radius is larger than locality by the ratio point-radius/locality</option>
															
																<option value="LOCALITY:SPEC_LOCALITY">Specific Locality (Collecting Events:LOCALITY) Free text description of the locality within the specified higher geography.</option>
															
																<option value="GEOG_AUTH_REC:STATE_PROV">State/Province (Collecting Events:GEOG_AUTH_REC) Primary division of a country for the higher geography.</option>
															
																<option value="LOCALITY:TOWNSHIP">Township (PLSS) (Collecting Events:LOCALITY) PLSS township, distance north or south from baseline in units of 6 miles</option>
															
																<option value="LOCALITY:TOWNSHIP_DIRECTION">Township Direction (PLSS) (Collecting Events:LOCALITY) PLSS township direction (N or S) off base line.</option>
															
																<option value="LAT_LONG:UTM_EW">UTM Easting (Collecting Events:LAT_LONG) UTM Easting</option>
															
																<option value="LAT_LONG:UTM_NS">UTM Northing (Collecting Events:LAT_LONG) UTM Northing</option>
															
																<option value="LAT_LONG:UTM_ZONE">UTM Zone (Collecting Events:LAT_LONG) Universal Transverse Mercator zone designator,  May include latitude band letter.</option>
															
																<option value="COLLECTING_EVENT:VALID_DISTRIBUTION_FG">Valid Distribution Flag (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="COLLECTING_EVENT:VERBATIMCOORDINATESYSTEM">Verbatim Coordinate System (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="COLLECTING_EVENT:VERBATIMCOORDINATES">Verbatim Coordinates (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="COLLECTING_EVENT:VERBATIM_DATE">Verbatim Date (Collecting Events:COLLECTING_EVENT) Verbatim text information about the collecting event date.</option>
															
																<option value="COLLECTING_EVENT:VERBATIMDEPTH">Verbatim Depth (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="COLLECTING_EVENT:VERBATIMELEVATION">Verbatim Elevation (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="COLLECTING_EVENT:VERBATIMLATITUDE">Verbatim Latitude (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="COLLECTING_EVENT:VERBATIM_LOCALITY">Verbatim Locality (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="COLLECTING_EVENT:VERBATIMLONGITUDE">Verbatim Longitude (Collecting Events:COLLECTING_EVENT) </option>
															
																<option value="GEOG_AUTH_REC:WKT_POLYGON">WKT Polygon (Collecting Events:GEOG_AUTH_REC) GIS shape for the higher geography.</option>
															
																<option value="GEOG_AUTH_REC:WATER_FEATURE">Water Feature (Collecting Events:GEOG_AUTH_REC) Water feature below seay for the higher geography.</option>
															
																<option value="GEOG_AUTH_REC:HIGHERGEOGRAPHYID">dwc:higherGeographyID (Collecting Events:GEOG_AUTH_REC) dwc:higherGeographyID, a guid for the geographic region represented by the geog_auth_rec record.</option>
															
																		</optgroup>
																		
																	<optgroup label="Collectors">
																	
																<option value="AGENT:AGENT_REMARKS">Agent Internal Remarks (Collectors:AGENT) Internal biographical information and other internal remarks.</option>
															
																<option value="AGENT:BIOGRAPHY">Agent Public Biography (Collectors:AGENT) Biographical information to be provided to the public.</option>
															
																<option value="AGENT:AGENT_TYPE">Agent Type (Collectors:AGENT) person, or other type of agent.  Agents of type person have corresponding record in the person table.</option>
															
																<option value="PERSON:BIRTH_DATE_DATE">Birth Date Date [yyyy-mm-dd] (Collectors:PERSON) Deprecated</option>
															
																<option value="PERSON:BIRTH_DATE">Birth Date as Text (Collectors:PERSON) Date of Birth as an ISO date in YYYY, YYYY-MM, or YYYY-MM-DD form.</option>
															
																<option value="COLLECTOR:COLL_NUM">Coll Num (Collectors:COLLECTOR) unused</option>
															
																<option value="COLLECTOR:COLL_NUM_PREFIX">Coll Num Prefix (Collectors:COLLECTOR) unused</option>
															
																<option value="COLLECTOR:COLL_NUM_SUFFIX">Coll Num Suffix (Collectors:COLLECTOR) unused</option>
															
																<option value="AGENT:COLLECTORS_AGENT_ID">Collector (pick) (Collectors:AGENT) surrogate numeric primary key</option>
															
																<option value="AGENT:AGENTGUID">Collector Agent GUID (Collectors:AGENT) A globaly unique indetifier for this agent, suitable for serving in Darwin Core as dwciri:identifiedBy, dwciri:recordedBy, dwciri:georeferencedBy etc.</option>
															
																<option value="AGENT:AGENTGUID_GUID_TYPE">Collector Agent GUID Type (Collectors:AGENT) The type of GUID (e.g. ORCID or VIAF) found in AGENTGUID.</option>
															
																<option value="COLLECTOR:COLL_ORDER">Collector Ordinal Position (Collectors:COLLECTOR) sort order for agents with the same role on the same collection object.</option>
															
																<option value="COLLECTOR:COLLECTOR_ROLE">Collector Role (c,p) (Collectors:COLLECTOR) role (c=collector, p=preparator) in which the agent acted on the collection object.</option>
															
																<option value="AGENT:EDITED">Collector is Vetted Agent (Collectors:AGENT) agent record has been vetted (if value is 1)</option>
															
																<option value="AGENT_NAME:COLLECTORS_AGENT_NAME">Collectors Agent Name (Collectors:AGENT_NAME) The value of the name</option>
															
																<option value="AGENT_NAME:COLLECTORS_AGENT_NAME_TYPE">Collectors Agent Name Type (Collectors:AGENT_NAME) The type of name</option>
															
																<option value="PERSON:DEATH_DATE_DATE">Death Date Date [yyyy-mm-dd] (Collectors:PERSON) Deprecated</option>
															
																<option value="PERSON:DEATH_DATE">Death Date as Text (Collectors:PERSON) Date of Death as an ISO date in YYYY, YYYY-MM, or YYYY-MM-DD form.</option>
															
																<option value="PERSON:FIRST_NAME">First Name (Collectors:PERSON) First portion of name, usually personal name in european contexts and family name in asian contexts.
</option>
															
																<option value="PERSON:LAST_NAME">Last Name (Collectors:PERSON) Last portion of name, family name in most european contexts, may be hyphenated, or may be more than one word, usually the personal name in asian contexts.</option>
															
																<option value="PERSON:MIDDLE_NAME">Middle Name (Collectors:PERSON) Middle names not included in first or last.</option>
															
																<option value="PERSON:PREFIX">Prefix (Collectors:PERSON) </option>
															
																<option value="PERSON:SUFFIX">Suffix (Collectors:PERSON) Suffix to append after person's name, e.g. Jr.</option>
															
																		</optgroup>
																		
																	<optgroup label="Deaccessions">
																	
																<option value="AGENT:DEACC_AGENT_ID">Deaccession Agent (pick) (Deaccessions:AGENT) surrogate numeric primary key</option>
															
																<option value="AGENT_NAME:DEACC_AGENT_NAME">Deaccession Agent Name (Deaccessions:AGENT_NAME) The value of the name</option>
															
																<option value="DEACC_ITEM:DEACC_ITEM_REMARKS">Deaccession Item Remarks (Deaccessions:DEACC_ITEM) Free text about the deaccessioned item.</option>
															
																<option value="DEACCESSION:DEACC_NUMBER">Deaccession Number (Deaccessions:DEACCESSION) The number of the deaccession.</option>
															
																<option value="DEACCESSION:DEACC_REMARKS">Deaccession Remarks (Deaccessions:DEACCESSION) Internal remarks related to the deaccession.</option>
															
																<option value="DEACCESSION:DEACC_STATUS">Deaccession Status (Deaccessions:DEACCESSION) The current status of the deaccession,  Controlled vocabulary.</option>
															
																<option value="DEACCESSION:DEACC_TYPE">Deaccession Type (Deaccessions:DEACCESSION) The type of the deaccession.   Controlled vocabulary</option>
															
																		</optgroup>
																		
																	<optgroup label="Identifications">
																	
																<option value="IDENTIFICATION:ACCEPTED_ID_FG">Accepted Id Flag (Identifications:IDENTIFICATION) Flag indicating if the identification is the accepted identification for a collection object.</option>
															
																<option value="TAXONOMY:AUTHOR_TEXT">Authorship (Identifications:TAXONOMY) Authorship string for the scientific name.</option>
															
																<option value="TAXONOMY:PHYLCLASS">Class (Identifications:TAXONOMY) Taxonomic class into which the taxon is placed.</option>
															
																<option value="COMMON_NAME:COMMON_NAME">Common Name (Identifications:COMMON_NAME) A common name for a taxon.</option>
															
																<option value="IDENTIFICATION:DATE_MADE_DATE">Date Made Date [yyyy-mm-dd] (Identifications:IDENTIFICATION) Deprecated</option>
															
																<option value="IDENTIFICATION_AGENT:IDENTIFICATIONS_AGENT_ID">Determiner (pick) (Identifications:IDENTIFICATION_AGENT) Agent who made the identification.</option>
															
																<option value="TAXONOMY:DISPLAY_NAME">Display Name (Identifications:TAXONOMY) Automatic.  Scientific name for display in html markup, with italics where appropriate, Does not include authorship string.</option>
															
																<option value="TAXONOMY:DIVISION">Division (Identifications:TAXONOMY) For ICNafp (botanical) names, the taxonomic rank equivalent to phylum.</option>
															
																<option value="TAXONOMY:FAMILY">Family (Identifications:TAXONOMY) Taxonomic Family into which the taxon is placed.</option>
															
																<option value="TAXONOMY:FULL_TAXON_NAME">Full Taxon Name (Identifications:TAXONOMY) Automatic.  Space separated list of the classification and all parts of the name of the taxon, excluding authorship.  </option>
															
																<option value="TAXONOMY:GENUS">Genus (Identifications:TAXONOMY) Taxonomic genus into which the taxon is placed, or the generic epithet for the taxon.</option>
															
																<option value="IDENTIFICATION:IDENTIFICATION_REMARKS">Identification Remarks (Identifications:IDENTIFICATION) Free text assertions concerning the identification.</option>
															
																<option value="IDENTIFICATION:IDENTIFICATIONS_PUBLICATION_ID">Identification sensu Publication (pick) (Identifications:IDENTIFICATION) Sensu.  The publication that this use of the taxon name is in the sense of.    Links an identification to a taxon concept..</option>
															
																<option value="AGENT_NAME:IDENTIFICATIONS_AGENT_NAME">Identifications Agent Name (Identifications:AGENT_NAME) The value of the name</option>
															
																<option value="AGENT_NAME:IDENTIFICATIONS_AGENT_NAME_TYPE">Identifications Agent Name Type (Identifications:AGENT_NAME) The type of name</option>
															
																<option value="TAXONOMY:IDENTIFICATIONS_SCIENTIFIC_NAME">Identifications Scientific Name (Identifications:TAXONOMY) The scientific name of the taxon.</option>
															
																<option value="TAXONOMY:IDENTIFICATIONS_SOURCE_AUTHORITY">Identifications Source Authority (Identifications:TAXONOMY) The authority from which the taxon record was derived.</option>
															
																<option value="IDENTIFICATION_TAXONOMY:IDENTIFICATIONS_TAXON_NAME_ID">Identifications Taxon Name (Identifications:IDENTIFICATION_TAXONOMY) Taxon the name of which is used in the identification in the location specified by the position of variable in taxa_formula.</option>
															
																<option value="TAXONOMY:IDENTIFICATIONS_VALID_CATALOG_TERM_FG">Identifications Valid Catalog Term Flag (Identifications:TAXONOMY) Flag indicating whether a taxon record is accepted by the bulkloader (1) or not (0).</option>
															
																<option value="IDENTIFICATION:IDENTIFICATIONS_COLLECTION_OBJECT_ID">Identified Collection Object (pick) (Identifications:IDENTIFICATION) Collection object to which this identification applies</option>
															
																<option value="IDENTIFICATION_AGENT:IDENTIFIER_ORDER">Identifier Order (Identifications:IDENTIFICATION_AGENT) Order of the agent in a list of identifiers for a particular identification.</option>
															
																<option value="TAXONOMY:INFRACLASS">Infraclass (Identifications:TAXONOMY) Taxonomic infraclass into which the taxon is placed.</option>
															
																<option value="TAXONOMY:INFRAORDER">Infraorder (Identifications:TAXONOMY) Taxonomic infraorder into which the taxon is placed.</option>
															
																<option value="TAXONOMY:INFRASPECIFIC_AUTHOR">Infraspecific Author (ICNafp) (Identifications:TAXONOMY) For ICNapf (botanical) names of below the species rank, the authorship string for the infraspecific part of the name.  </option>
															
																<option value="TAXONOMY:INFRASPECIFIC_RANK">Infraspecific Rank  (Identifications:TAXONOMY) Rank marker to apply to the subspecific epithet if the taxon is of rank below subspecies.</option>
															
																<option value="TAXONOMY:KINGDOM">Kingdom (Identifications:TAXONOMY) Taxonomic kingdom into which the taxon is placed.</option>
															
																<option value="IDENTIFICATION:MADE_DATE">Made Date as Text (Identifications:IDENTIFICATION) Date the identification was made in ISO format.</option>
															
																<option value="IDENTIFICATION:NATURE_OF_ID">Nature Of Identification (Identifications:IDENTIFICATION) Provenance of the identification.</option>
															
																<option value="TAXONOMY:NOMENCLATURAL_CODE">Nomenclatural Code (Identifications:TAXONOMY) The code of nomenclature whos rules govern the formulation of the taxon name (ICZN, ICNapf), or non-compliant if the name is in a historical form with an orthography not compliant with the current rules.</option>
															
																<option value="TAXONOMY:TAXON_STATUS">Nomenclatural Status (Identifications:TAXONOMY) Nomenclatural status for the taxon record if unavailable.  Actionable, prevents italiciation of display name.</option>
															
																<option value="TAXONOMY:PHYLORDER">Order (Identifications:TAXONOMY) Taxonomic order into which the taxon is placed.</option>
															
																<option value="TAXONOMY:PHYLUM">Phylum (Identifications:TAXONOMY) Taxonomic phylum into which the taxon is placed.</option>
															
																<option value="TAXONOMY:SCIENTIFICNAMEID_GUID_TYPE">Scientificnameid Guid Type (Identifications:TAXONOMY) type of identifier in scientificnameid</option>
															
																<option value="TAXONOMY:SPECIES">Species (Identifications:TAXONOMY) Specific epithet part of the taxon name, if of species rank or lower.</option>
															
																<option value="IDENTIFICATION:STORED_AS_FG">Stored As Flag (Identifications:IDENTIFICATION) Flag indicating that the collection object is stored under this name.</option>
															
																<option value="TAXONOMY:SUBCLASS">Subclass (Identifications:TAXONOMY) Taxonomic subclass into which the taxon is placed.</option>
															
																<option value="TAXONOMY:SUBDIVISION">Subdivision (Identifications:TAXONOMY) For ICNafp (botanical) names, the taxonomic rank equivalent to subphylum.</option>
															
																<option value="TAXONOMY:SUBFAMILY">Subfamily (Identifications:TAXONOMY) Taxonomic subfamily into which the taxon is placed.</option>
															
																<option value="TAXONOMY:SUBGENUS">Subgenus (Identifications:TAXONOMY) The subgeneric epithet for the taxon, without parenthesies.</option>
															
																<option value="TAXONOMY:SUBORDER">Suborder (Identifications:TAXONOMY) Taxonomic suborder into which the taxon is placed.</option>
															
																<option value="TAXONOMY:SUBPHYLUM">Subphylum (Identifications:TAXONOMY) Taxonomic subphylum into which the taxon is placed.</option>
															
																<option value="TAXONOMY:SUBSECTION">Subsection (Identifications:TAXONOMY) Taxonomic subsection into which the taxon is placed.</option>
															
																<option value="TAXONOMY:SUBSPECIES">Subspecies (Identifications:TAXONOMY) Subspecific epithet part of the scientific name if the taxon is of rank subspecies or lower.</option>
															
																<option value="TAXONOMY:SUPERCLASS">Superclass (Identifications:TAXONOMY) Taxonomic superclass into which the taxon is placed.</option>
															
																<option value="TAXONOMY:SUPERFAMILY">Superfamily (Identifications:TAXONOMY) Taxonomic superfamily into which the taxon is placed.</option>
															
																<option value="TAXONOMY:SUPERORDER">Superorder (Identifications:TAXONOMY) Taxonomic superorder into which the taxon is placed.</option>
															
																<option value="IDENTIFICATION:TAXA_FORMULA">Taxa Formula (Identifications:IDENTIFICATION) Formula by which one or more taxon names are composed with each other and with optional additional text as part of the identification that is not part of the taxon name(s).   Allows expressions of uncertanty in identification and hybrids.  For each capital letter, A, B, etc. in the formula, there is expected to be a taxon_identification record linking this part of the formula to a taxon record.</option>
															
																<option value="TAXONOMY:TAXON_REMARKS">Taxon Remarks (Identifications:TAXONOMY) Free text assertions concerning the taxon.</option>
															
																<option value="TAXONOMY:TAXONID_GUID_TYPE">Taxonid Guid Type (Identifications:TAXONOMY) type of identifier used in taxonid</option>
															
																<option value="TAXONOMY:TRIBE">Tribe (Identifications:TAXONOMY) Taxonomic tribe into which the taxon is placed.</option>
															
																<option value="IDENTIFICATION_TAXONOMY:VARIABLE">Variable (Identifications:IDENTIFICATION_TAXONOMY) Position (specified by a captial letter) in taxa_formula where the scientific name of the taxon in taxon_name_id is used in the identification specific by identification_id.</option>
															
																<option value="TAXONOMY:SCIENTIFICNAMEID">dwc:scientificNameID (Identifications:TAXONOMY) dwc:scientificNameID, guid for the nomenclatural act on which the taxon found in scientific_name is based.</option>
															
																<option value="TAXONOMY:GUID">dwc:taxonID (Identifications:TAXONOMY) Unused.  Could hold a guid for the taxon record, if the institution considers itself an authority for the taxon record.</option>
															
																<option value="TAXONOMY:TAXONID">dwc:taxonID (Identifications:TAXONOMY) dwc:taxonID, a guid for the taxon record.</option>
															
																		</optgroup>
																		
																	<optgroup label="Keywords">
																	
																<option value="FLAT:ANY_GEOGRAPHY">Any Geography (Keywords:FLAT) The higher geography string for the place where this material was collected.  Colon delimited list of higher geography terms.</option>
															
																<option value="FLAT:KEYWORD">Keywords (Keywords:FLAT) Catalog Number.</option>
															
																<option value="FLAT:MAX_DEPTH_IN_M">Maximum Depth in Meters (Keywords:FLAT) </option>
															
																<option value="FLAT:MAX_ELEV_IN_M">Maximum elevation in meters. (Keywords:FLAT) </option>
															
																<option value="FLAT:MIN_DEPTH_IN_M">Minimum Depth in Meters (Keywords:FLAT) </option>
															
																<option value="FLAT:MIN_ELEV_IN_M">Minimum elevation in meters. (Keywords:FLAT) </option>
															
																		</optgroup>
																		
																	<optgroup label="Loans">
																	
																<option value="AGENT:LOAN_AGENT_ID">Loan Agent (pick) (Loans:AGENT) surrogate numeric primary key</option>
															
																<option value="AGENT_NAME:LOAN_AGENT_NAME">Loan Agent Name (Loans:AGENT_NAME) The value of the name</option>
															
																<option value="LOAN_ITEM:LOAN_ITEM_REMARKS">Loan Item Remarks (Loans:LOAN_ITEM) Remarks concerning this item in this loan.
</option>
															
																<option value="LOAN:LOAN_NUMBER">Loan Number (Loans:LOAN) Identifier for the loan.</option>
															
																<option value="LOAN:LOAN_STATUS">Loan Status (Loans:LOAN) Current state of the loan in its life cycle.</option>
															
																		</optgroup>
																		
																	<optgroup label="Media">
																	
																<option value="MEDIA:AUTO_EXTENSION">File Extension (Media:MEDIA) Autogenerated filename extension portion of the media_uri</option>
															
																<option value="MEDIA:AUTO_FILENAME">Filename (Media:MEDIA) Autogenerated filename portion of the media_uri</option>
															
																<option value="MEDIA:AUTO_HOST">Host (Media:MEDIA) Autogenerated host portion of the media_uri</option>
															
																<option value="MEDIA_LABELS:LABEL_VALUE">Label Value (Media:MEDIA_LABELS) Value for the specific label name.</option>
															
																<option value="MEDIA:MASK_MEDIA_FG">Mask Media Flag (Media:MEDIA) Flag indicating that this media record should be hidden from the public.  1=mask, 0=public.</option>
															
																<option value="MEDIA_RELATIONS:MEDIA_CREATION_AGENT">Media Created By Agent (Media:MEDIA_RELATIONS) ID or name that connects the media table with the related table (e.g., media table with agent table).</option>
															
																<option value="MEDIA_LABELS:MEDIA_LABEL">Media Label (Media:MEDIA_LABELS) Media label holds the label name</option>
															
																<option value="makeAgentAutocompleteMeta:ASSIGNED_BY_AGENT_ID">Media Label Assigned By Agent (Media:makeAgentAutocompleteMeta) </option>
															
																<option value="MEDIA:MEDIA_LICENSE_ID">Media License (pick) (Media:MEDIA) The license under which the institution is enabled to distribute a copy of the media object.   </option>
															
																<option value="MEDIA_RELATIONS:CREATED_BY_AGENT_ID">Media Relationship Created By Agent (Media:MEDIA_RELATIONS) Person who created the relationship in each row.</option>
															
																<option value="MEDIA:MEDIA_TYPE">Media Type (Media:MEDIA) Human descriptor of the media</option>
															
																<option value="MEDIA:MEDIA_URI">Media URI (IRI for the media object) (Media:MEDIA) IRI for the referenced media object</option>
															
																<option value="MEDIA:MIME_TYPE">Mime Type (Media:MEDIA) Mime type of the resource at the IRI provided by the media_uri.</option>
															
																<option value="MEDIA_RELATIONS:NEXT_MEDIA_RELATIONSHIP">Next Media Relationship (Media:MEDIA_RELATIONS) Media relationship name.</option>
															
																<option value="MEDIA_RELATIONS:NEXT_RELATED_PRIMARY_KEY">Next Related Primary Key (Media:MEDIA_RELATIONS) ID or name that connects the media table with the related table (e.g., media table with agent table).</option>
															
																<option value="MEDIA:AUTO_PATH">Path (Media:MEDIA) Autogenerated path portion of the media_uri</option>
															
																<option value="MEDIA:PREVIEW_URI">Preview URI (IRI for a thumbnail) (Media:MEDIA) IRI for a thumbnail for the media object.</option>
															
																<option value="MEDIA:AUTO_PROTOCOL">Protocol (Media:MEDIA) Autogenerated protocol portion of the media_uri</option>
															
																		</optgroup>
																		
																	<optgroup label="Named Groups">
																	
																<option value="UNDERSCORE_COLLECTION:HTML_DESCRIPTION">HTML Description (Named Groups:UNDERSCORE_COLLECTION) HTML markup description for the public page for the collection. </option>
															
																<option value="UNDERSCORE_COLLECTION:MASK_FG">Mask Flag (Named Groups:UNDERSCORE_COLLECTION) Flag to indicate if this record should be shown to the public or not</option>
															
																<option value="UNDERSCORE_COLLECTION:COLLECTION_NAME">Name of Named Group (Named Groups:UNDERSCORE_COLLECTION) The name for this collection, e.g. Smith Collection.</option>
															
																<option value="UNDERSCORE_COLLECTION:NAMED GROUPS_UNDERSCORE_COLLECTION_ID">Named Group (pick) (Named Groups:UNDERSCORE_COLLECTION) Surrogate numeric primary key</option>
															
																<option value="UNDERSCORE_COLLECTION:UNDERSCORE_AGENT_ID">Named Group Agent (pick) (Named Groups:UNDERSCORE_COLLECTION) Deprecated.  The agent for which this is the collection of  (e.g. Smith for Smith Collection).</option>
															
																<option value="UNDERSCORE_COLLECTION:NAMED GROUPS_DESCRIPTION">Named Group Description (Named Groups:UNDERSCORE_COLLECTION) Text description of this collection.</option>
															
																<option value="UNDERSCORE_COLLECTION:UNDERSCORE_COLLECTION_ID_RAW">Named Group ID (underscore_collection_id) (Named Groups:UNDERSCORE_COLLECTION) Surrogate numeric primary key</option>
															
																		</optgroup>
																		
																	<optgroup label="Relationships">
																	
																<option value="BIOL_INDIV_RELATIONS:CREATED_BY">Created By (login) (Relationships:BIOL_INDIV_RELATIONS) The creator of this relationship record</option>
															
																<option value="BIOL_INDIV_RELATIONS:RELATIONSHIPS_COLLECTION_OBJECT_ID">Related From Collection Object Id (pick) (Relationships:BIOL_INDIV_RELATIONS) The resource that is the subject of the relationship, identified by a collection_object_id</option>
															
																<option value="BIOL_INDIV_RELATIONS:RELATED_COLL_OBJECT_ID">Related To Collection Object Id (pick) (Relationships:BIOL_INDIV_RELATIONS) The resource that is the object of the relationship.</option>
															
																<option value="BIOL_INDIV_RELATIONS:BIOL_INDIV_RELATION_REMARKS">Relationship Remarks (Relationships:BIOL_INDIV_RELATIONS) Comments or notes about the relationship between the two resources</option>
															
																<option value="BIOL_INDIV_RELATIONS:BIOL_INDIV_RELATIONSHIP">Type of Relationship (Relationships:BIOL_INDIV_RELATIONS) The relationship of the subject (collection_object_id) to the object (related_coll_object_id)</option>
															
																		</optgroup>
																		
																	<optgroup label="Specimen Parts">
																	
																<option value="SPECIMEN_PART:IS_TISSUE">Is Tissue [0 or 1] (Specimen Parts:SPECIMEN_PART) </option>
															
																<option value="SPECIMEN_PART:PART_MODIFIER">Part Modifier (Specimen Parts:SPECIMEN_PART) Depricated, not shown on UI, some values exist.</option>
															
																<option value="SPECIMEN_PART:PART_NAME">Part Name (Specimen Parts:SPECIMEN_PART) </option>
															
																<option value="COLL_OBJECT_REMARK:PART_REMARKS">Part Remarks (Specimen Parts:COLL_OBJECT_REMARK) Comments or notes regarding the specimen.</option>
															
																<option value="SPECIMEN_PART:DERIVED_FROM_CAT_ITEM">Part of Cataloged Item (Specimen Parts:SPECIMEN_PART) the collection ofbject id of the collection object that is the cataloged item for this part.</option>
															
																<option value="SPECIMEN_PART:PRESERVE_METHOD">Preserve Method (Specimen Parts:SPECIMEN_PART) </option>
															
																<option value="SPECIMEN_PART:SAMPLED_FROM_OBJ_ID">Sampled From Collection Object ID (Specimen Parts:SPECIMEN_PART) </option>
															
																<option value="COLL_OBJECT:SPECIMEN_PART_CONDITION">Specimen Part  Condition (Specimen Parts:COLL_OBJECT) The current condition of the collection object</option>
															
																<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_REMARK">Specimen Parts Attribute Remark (Specimen Parts:SPECIMEN_PART_ATTRIBUTE) </option>
															
																<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_TYPE">Specimen Parts Attribute Type (Specimen Parts:SPECIMEN_PART_ATTRIBUTE) </option>
															
																<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_UNITS">Specimen Parts Attribute Units (Specimen Parts:SPECIMEN_PART_ATTRIBUTE) </option>
															
																<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_VALUE">Specimen Parts Attribute Value (Specimen Parts:SPECIMEN_PART_ATTRIBUTE) </option>
															
																<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_DETERMINED_BY_AGENT_ID">Specimen Parts Determined By Agent (Specimen Parts:SPECIMEN_PART_ATTRIBUTE) </option>
															
																<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_DETERMINED_DATE">Specimen Parts Determined Date [yyyy-mm-dd] (Specimen Parts:SPECIMEN_PART_ATTRIBUTE) </option>
															
																		</optgroup>
																		
																	<optgroup label="Taxonomy">
																	
																<option value="TAXA_TERMS_ALL:TAXA_TERM_ALL">Any Taxonomy (Taxonomy:TAXA_TERMS_ALL) </option>
															
																<option value="TAXA_TERMS:TAXA_TERM">Any Taxonomy (Current Id Only) (Taxonomy:TAXA_TERMS) </option>
															
																</optgroup>
															
														</select><div title="Select Field to search..." id="field1" class="data-entry-select jqx-combobox-state-normal jqx-combobox jqx-rc-all jqx-widget jqx-widget-content" aria-owns="listBoxjqxWidgetb66460258ee6" aria-haspopup="true" aria-multiline="false" hint="true" style="height: 25px; width: 100%; box-sizing: border-box;" aria-readonly="false"><div style="background-color: transparent; -webkit-appearance: none; outline: none; width:100%; height: 100%; padding: 0px; margin: 0px; border: 0px; position: relative;"><div id="dropdownlistWrapperfield1" style="padding: 0; margin: 0; border: none; background-color: transparent; float: left; width:100%; height: 100%; position: relative;"><div id="dropdownlistContentfield1" style="padding: 0px; margin: 0px; border-top: none; border-bottom: none; float: left; position: absolute; height: 23px; left: 0px; top: 0px;" class="jqx-combobox-content jqx-widget-content"><input autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="box-sizing: border-box; margin: 0px; padding: 0px 3px; border: 0px; width: 100%; height: 23px;" type="textarea" class="jqx-combobox-input jqx-widget-content jqx-rc-all" value="" placeholder=""></div><div id="dropdownlistArrowfield1" role="button" style="padding: 0px; margin: 0px; border-width: 0px 0px 0px 1px; float: right; position: absolute; width: 17px; height: 23px; left: -19px;" class="jqx-combobox-arrow-normal jqx-fill-state-normal jqx-rc-r"><div class="jqx-icon-arrow-down jqx-icon"></div></div><label class="jqx-input-label"></label><span class="jqx-input-bar" style="top: 21px;"></span></div></div><input type="hidden" value=""></div>
														<script>
															$(document).ready(function() { 
																$('#field1').jqxComboBox({
																	autoComplete: true,
																	searchMode: 'containsignorecase',
																	width: '100%',
																	dropDownHeight: 400
																});
																// bind an autocomplete, if one applies
																handleFieldSetup('field1',1);
																console.log("field1 setup");
																$('#field1').on("select", function(event) { 
																	handleFieldSelection('field1',1);
																});
																var selectedIndex = $('#field1').jqxComboBox('getSelectedIndex');
																if (selectedIndex<1) {
																	// hack, if intial field1 selection is 0 (-1 is no selection), first on select event doesn't fire.  
																	// forcing clearSelection so that first action on field1 will triggers select event.
																	$('#field1').jqxComboBox('clearSelection');
																}
															});
														</script>
													</div>
													<div class="col-12 col-md-3">
														
														<label for="searchText1" class="data-entry-label">Search For</label>
														<input type="text" class="form-control-sm d-flex data-entry-input mx-0" name="searchText1" id="searchText1" value="" required="">
														<input type="hidden" name="searchId1" id="searchId1" value="">
														<input type="hidden" name="joinOperator1" id="joinOperator1" value="">
													</div>
													<div class="col-12 col-md-1">
														<label class="data-entry-label" for="closeParens1">&nbsp;</label>
														
														<select name="closeParens1" id="closeParens1" class="data-entry-select">
															
															<option value="0" selected=""></option>
															
															<option value="1">)</option>
															
															<option value="2">))</option>
															
															<option value="3">)))</option>
															
															<option value="4" #="">))))</option>
															
															<option value="5" #="">)))))</option>
														</select>
													</div>
													<script> 
														$(document).ready(function(){
															$('#openParens1').on("change", function(event) { isNestingOk(); }); 
															$('#closeParens1').on("change", function(event) { isNestingOk(); });
														});
													</script> 
													<div class="col-12 col-md-1">
														
															<label class="data-entry-label" for="debug3">Debug</label>
															<select title="debug" name="debug" id="debug3" class="data-entry-select">
																<option value=""></option>
																
																<option value="true">Debug JSON</option>
															</select>
														
													</div>
												</div>
												
							
											</div>
											<script>
												function removeBuilderRow(row) {
													$("#builderRow"+row).remove();
													isNestingOk(); 
												} 
												function isNestingOk() { 
													$('#nestingFeedback').html("");		
													$('#nestingFeedback').removeClass('text-danger');
													var result = false;
													var countOpen = 0;
													var countClose = 0;
													var rows = $("#builderMaxRows").val();
													rows = parseInt(rows);
													for (row=1; row<=rows; row++) { 
														if (row && $('#openParens'+row).length) { 
															countOpen = countOpen + parseInt($('#openParens'+row).val());
															countClose = countClose + parseInt($('#closeParens'+row).val());
														}
													}
													if (countOpen==countClose) { 
														console.log("Parenthesies counts match.");
														const parens = new Array();
														var nestOrderOk = true;
														var errorText = "";
														for (row=1; row<=rows; row++) { 
															var open = parseInt($('#openParens'+row).val());
															var close = parseInt($('#closeParens'+row).val());
															if (open>0) { 
																for (i=1; i<= open; i++) { 
																	parens.push("(");
																}
															}
															if (close>0) {
																for (i=1; i<= close; i++) { 
																	if (parens.length > 0) { 
																		parens.pop();
																	} else { 
																		console.log("Error in nesting of parenthesies, all opens consumed.");
																		errorText = "( without )";
																		nestOrderOk = false;
																	}
																}  
															}  
														} 
														if (parens.length > 0) { 
															console.log("Error in nesting of parenthesies, remaining open.");
															errorText = ") without (";
															nestOrderOk = false;
														}
														if (nestOrderOk) { 
															console.log("Parenthesies nest.");
															result = true;
															$('#searchbuilder-search').prop("disabled",false);
														}  else { 
															$('#nestingFeedback').html("nesting error<br>"+errorText);		
															$('#nestingFeedback').addClass('text-danger');
															$('#searchbuilder-search').prop("disabled",true);
															result=false;
														} 
													} else { 
														console.log("Parenthesies mismatched: " + countOpen + " opened, but " + countClose + " closed.");
														$('#nestingFeedback').html("open " + countOpen + " ( but <br>close " + countClose + " )");		
														$('#nestingFeedback').addClass('text-danger');
														$('#searchbuilder-search').prop("disabled",true);
													} 
													return result;
												}
												function addBuilderRow() { 
													var row = $("#builderMaxRows").val();
													row = parseInt(row) + 1;
													var newControls = '<div class="form-row mb-2" id="builderRow'+row+'">';
													newControls = newControls + '<div class="col-12 col-md-1">&nbsp;';
													newControls = newControls + '</div>';
													newControls = newControls + '<div class="col-12 col-md-1">';
													newControls = newControls + '<select title="Join Operator" name="JoinOperator'+row+'" id="joinOperator'+row+'" class="data-entry-select bg-white mx-0 d-flex"><option value="and">and</option><option value="or">or</option></select>';
													newControls = newControls + '</div>';
													newControls = newControls + '<div class="col-12 col-md-1">';
													newControls = newControls + '<select name="openParens'+row+'" id="openParens'+row+'" class="data-entry-select">';
													newControls = newControls + '<option value="0"></option><option value="1">(</option>';
													newControls = newControls + '<option value="2">((</option><option value="3">(((</option>';
													newControls = newControls + '<option value="4">((((</option>';
													newControls = newControls + '<option value="5">(((((</option>';
													newControls = newControls + '</select>';
													newControls = newControls + '</div>';
													newControls= newControls + '<div class="col-12 col-md-4">';
													newControls = newControls + '<select title="Select Field..." name="field'+row+'" id="field'+row+'" class="data-entry-select">';
													newControls = newControls + '<optgroup label="Select a field to search...."><option value="" selected></option></optgroup>';
													
															newControls = newControls + '<optgroup label="Accessions">';
															
														newControls = newControls + '<option value="TRANS_AGENT:ACCESSIONS_AGENT_ID">Accession Agent (pick) (Accessions:TRANS_AGENT)</option>';
													
														newControls = newControls + '<option value="AGENT_NAME:ACCESSIONS_AGENT_NAME">Accession Agent Name (partial match) (Accessions:AGENT_NAME)</option>';
													
														newControls = newControls + '<option value="TRANS_AGENT:TRANS_AGENT_ROLE">Accession Agent Role (Accessions:TRANS_AGENT)</option>';
													
														newControls = newControls + '<option value="ACCN:ACCN_NUMBER">Accession Number (partial match) (Accessions:ACCN)</option>';
													
														newControls = newControls + '<option value="CATALOGED_ITEM:ACCN_ID">Accession Number (pick) (Accessions:CATALOGED_ITEM)</option>';
													
														newControls = newControls + '<option value="ACCN:ACCN_STATUS">Accession Status (Accessions:ACCN)</option>';
													
														newControls = newControls + '<option value="TRANS:ACCESSIONS_TRANSACTION_ID">Accession Transaction Id (Accessions:TRANS)</option>';
													
														newControls = newControls + '<option value="ACCN:ACCN_TYPE">Accession Type (Accessions:ACCN)</option>';
													
														newControls = newControls + '<option value="TRANS:ACCESSIONS_COLLECTION_ID">Accessioned in Collection (pick) (Accessions:TRANS)</option>';
													
														newControls = newControls + '<option value="ACCN:ESTIMATED_COUNT">Estimated Count (Accessions:ACCN)</option>';
													
														newControls = newControls + '<option value="TRANS:NATURE_OF_MATERIAL">Nature Of Material (Accessions:TRANS)</option>';
													
														newControls = newControls + '<option value="ACCN:RECEIVED_DATE">Received Date [yyyy-mm-dd] (Accessions:ACCN)</option>';
													
														newControls = newControls + '<option value="ACCN:RECEIVED_DATE_TEXT">Received Date as Text (Accessions:ACCN)</option>';
													
														newControls = newControls + '<option value="TRANS:TRANS_DATE">Trans Date [yyyy-mm-dd] (Accessions:TRANS)</option>';
													
														newControls = newControls + '<option value="TRANS:TRANS_REMARKS">Transaction Remarks (Accessions:TRANS)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Attributes">';
															
														newControls = newControls + '<option value="ATTRIBUTES:DETERMINATION_METHOD">Attribute Determination Method (Attributes:ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="ATTRIBUTES:ATTRIBUTES_DETERMINED_BY_AGENT_ID">Attribute Determined By Agent (pick) (Attributes:ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="ATTRIBUTES:ATTRIBUTES_DETERMINED_DATE">Attribute Determined Date [yyyy-mm-dd] (Attributes:ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_REMARK">Attribute Remark (Attributes:ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_TYPE">Attribute Type (Attributes:ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_UNITS">Attribute Units (Attributes:ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="ATTRIBUTES:ATTRIBUTES_ATTRIBUTE_VALUE">Attribute Value (Attributes:ATTRIBUTES)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Cataloged Item">';
															
														newControls = newControls + '<option value="COLL_OBJECT_REMARK:ASSOCIATED_SPECIES">Associated Species (Cataloged Item:COLL_OBJECT_REMARK)</option>';
													
														newControls = newControls + '<option value="CATALOGED_ITEM:CAT_NUM">Catalog Number (Cataloged Item:CATALOGED_ITEM)</option>';
													
														newControls = newControls + '<option value="CATALOGED_ITEM:CAT_NUM_INTEGER">Catalog Number Integer (Cataloged Item:CATALOGED_ITEM)</option>';
													
														newControls = newControls + '<option value="CATALOGED_ITEM:CAT_NUM_PREFIX">Catalog Number Prefix (Cataloged Item:CATALOGED_ITEM)</option>';
													
														newControls = newControls + '<option value="CATALOGED_ITEM:CAT_NUM_SUFFIX">Catalog Number Suffix (Cataloged Item:CATALOGED_ITEM)</option>';
													
														newControls = newControls + '<option value="CATALOGED_ITEM:CATALOGED_ITEM_TYPE">Cataloged Item Type (Cataloged Item:CATALOGED_ITEM)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:COLL_OBJ_DISPOSITION">Coll Obj Disposition (Cataloged Item:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:COLL_OBJECT_ENTERED_DATE">Coll Object Entered Date [yyyy-mm-dd] (Cataloged Item:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT_REMARK:COLL_OBJECT_REMARKS">Coll Object Remarks (Cataloged Item:COLL_OBJECT_REMARK)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:COLL_OBJECT_TYPE">Coll Object Type [not working yet] (Cataloged Item:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="CATALOGED_ITEM:CATALOGED ITEM_COLLECTING_EVENT_ID">Collecting Event (pick specific locality/date) (Cataloged Item:CATALOGED_ITEM)</option>';
													
														newControls = newControls + '<option value="CATALOGED_ITEM:CATALOGED ITEM_COLLECTION_ID">Collection (pick) (Cataloged Item:CATALOGED_ITEM)</option>';
													
														newControls = newControls + '<option value="CATALOGED_ITEM:COLLECTION_CDE">Collection Code (Cataloged Item:CATALOGED_ITEM)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:CONDITION">Condition (Cataloged Item:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT_REMARK:DISPOSITION_REMARKS">Disposition Remarks (Cataloged Item:COLL_OBJECT_REMARK)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:ENTERED_PERSON_ID">Entered By Person (pick) (Cataloged Item:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="CATALOGED_ITEM:CATALOGED ITEM_COLLECTION_OBJECT_ID">GUID (pick by GUID/Locality/Identification)  (Cataloged Item:CATALOGED_ITEM)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:LAST_EDIT_DATE">Last Edit Date (dwc:modified) [yyyy-mm-dd] (Cataloged Item:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:LAST_EDITED_PERSON_ID">Last Edited By (pick) (Cataloged Item:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:LOT_COUNT">Lot Count (Cataloged Item:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:LOT_COUNT_MODIFIER">Lot Count Modifier (Cataloged Item:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT_REMARK:HABITAT">Microhabitat (Cataloged Item:COLL_OBJECT_REMARK)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:FLAGS">Missing Information (Cataloged Item:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="COLL_OBJ_OTHER_ID_NUM:DISPLAY_VALUE">Other Number (Cataloged Item:COLL_OBJ_OTHER_ID_NUM)</option>';
													
														newControls = newControls + '<option value="COLL_OBJ_OTHER_ID_NUM:OTHER_ID_NUMBER">Other Number Integer (Cataloged Item:COLL_OBJ_OTHER_ID_NUM)</option>';
													
														newControls = newControls + '<option value="COLL_OBJ_OTHER_ID_NUM:OTHER_ID_PREFIX">Other Number Prefix (Cataloged Item:COLL_OBJ_OTHER_ID_NUM)</option>';
													
														newControls = newControls + '<option value="COLL_OBJ_OTHER_ID_NUM:OTHER_ID_SUFFIX">Other Number Suffix (Cataloged Item:COLL_OBJ_OTHER_ID_NUM)</option>';
													
														newControls = newControls + '<option value="COLL_OBJ_OTHER_ID_NUM:OTHER_ID_TYPE">Other Number Type (Cataloged Item:COLL_OBJ_OTHER_ID_NUM)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:COLL_OBJ_COLLECTION_OBJECT_ID">collection_object_id (Cataloged Item:COLL_OBJECT)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Citations">';
															
														newControls = newControls + '<option value="CITATION:CIT_CURRENT_FG">Cit Current Flag (Citations:CITATION)</option>';
													
														newControls = newControls + '<option value="CTCITATION_TYPE_STATUS:CATEGORY">Citation Category (Primary,Secondary,Voucher) (Citations:CTCITATION_TYPE_STATUS)</option>';
													
														newControls = newControls + '<option value="CTCITATION_TYPE_STATUS:CITATIONS_DESCRIPTION">Citation Description (Citations:CTCITATION_TYPE_STATUS)</option>';
													
														newControls = newControls + '<option value="CITATION:CITATION_PAGE_URI">Citation Page IRI (Citations:CITATION)</option>';
													
														newControls = newControls + '<option value="CITATION:CITATION_REMARKS">Citation Remarks (Citations:CITATION)</option>';
													
														newControls = newControls + '<option value="CITATION:CITATION_TEXT">Citation Text (Citations:CITATION)</option>';
													
														newControls = newControls + '<option value="CITATION:CITATIONS_TYPE_STATUS">Citation Type Status (Citations:CITATION)</option>';
													
														newControls = newControls + '<option value="CITATION:CITATIONS_COLLECTION_OBJECT_ID">Cited Collection Object (pick) (Citations:CITATION)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:CITED_GENUS">Cited Genus (Citations:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="FORMATTED_PUBLICATION:CITATION_FORMATTED_PUBLICATION">Cited Publication (Citations:FORMATTED_PUBLICATION)</option>';
													
														newControls = newControls + '<option value="CITATION:CITATIONS_PUBLICATION_ID">Cited Publication (pick) (Citations:CITATION)</option>';
													
														newControls = newControls + '<option value="CITATION:CITED_TAXON_NAME_ID">Cited Taxon Name (pick) (Citations:CITATION)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:CITED_FAMILY">Family of cited taxon (Citations:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="CITATION:OCCURS_PAGE_NUMBER">Occurs Page Number (Citations:CITATION)</option>';
													
														newControls = newControls + '<option value="CITATION:REP_PUBLISHED_YEAR">Reported Year of Publcation (Citations:CITATION)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:CITED_ORDER">Taxonomic Order of cited taxon (Citations:TAXONOMY)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Collecting Events">';
															
														newControls = newControls + '<option value="LAT_LONG:ACCEPTED_LAT_LONG_FG">Accepted Lat Long Flag (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:DATE_DETERMINED_BY_AGENT_ID">Agent who set Date Determined (pick) (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:BEGAN_DATE">Began Date (yyyy-mm-dd) (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:COLLECTING EVENTS_COLLECTING_EVENT_ID">Collecting Event (pick) (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:CE_COLLECTING_EVENT_ID">Collecting Event ID (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLL_EVENT_NUMBER:COLL_EVENT_NUMBER">Collecting Event Number (Collecting Events:COLL_EVENT_NUMBER)</option>';
													
														newControls = newControls + '<option value="COLL_EVENT_NUMBER:COLL_EVENT_NUM_SERIES_ID">Collecting Event Number Series Id (Collecting Events:COLL_EVENT_NUMBER)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:COLL_EVENT_REMARKS">Collecting Event Remarks (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="LOCALITY:COLLECTING EVENTS_GEOG_AUTH_REC_ID">Collecting Events Geog Auth Rec Id (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:COLLECTING EVENTS_SOURCE_AUTHORITY">Collecting Events Source Authority (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:COLLECTING EVENTS_VALID_CATALOG_TERM_FG">Collecting Events Valid Catalog Term Flag (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:COLLECTING_METHOD">Collecting Method (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:COLLECTING_SOURCE">Collecting Source (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:COLLECTING_TIME">Collecting Time (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:CONTINENT_OCEAN">Continent Ocean (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:COUNTRY">Country (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:COUNTY">County/Shire/Parish (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="LOCALITY:CURATED_FG">Curated Flag (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:DATE_BEGAN_DATE">Date Began Date [yyyy-mm-dd] (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:DATE_ENDED_DATE">Date Ended Date [yyyy-mm-dd] (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:DATUM">Datum (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:ENDDAYOFYEAR">Day of year for end of event (dwc:endDayOfYear) (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:STARTDAYOFYEAR">Day of year for start of event  (dwc:startDayOfYear) (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:DEC_LAT_MIN">Dec Lat Min (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:DEC_LAT">Dec Latitude (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:DEC_LONG_MIN">Dec Long Min (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:DEC_LONG">Dec Longitude (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LOCALITY:DEPTH_UNITS">Depth Units (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:ENDED_DATE">Ended Date (yyyy-mm-dd) (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:EXTENT">Extent (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:FEATURE">Feature (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:FIELD_VERIFIED_FG">Field Verified Flag (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:FISH_FIELD_NUMBER">Fish Field Number (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:GPSACCURACY">GPS/GNSS Accuracy (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:GEOLOCATE_NUMRESULTS">Geolocate Number of Results (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:GEOLOCATE_PARSEPATTERN">Geolocate Parse Pattern (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:GEOLOCATE_PRECISION">Geolocate Precision (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:GEOLOCATE_SCORE">Geolocate Score (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="GEOLOGY_ATTRIBUTES:GEO_ATT_DETERMINED_DATE">Geological Attribute Determined Date [yyyy-mm-dd] (Collecting Events:GEOLOGY_ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="GEOLOGY_ATTRIBUTES:GEO_ATT_DETERMINED_METHOD">Geological Attribute Determined Method (Collecting Events:GEOLOGY_ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="GEOLOGY_ATTRIBUTES:GEO_ATT_DETERMINER_ID">Geological Attribute Determiner (pick) (Collecting Events:GEOLOGY_ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="GEOLOGY_ATTRIBUTES:GEO_ATT_REMARK">Geological Attribute Remark (Collecting Events:GEOLOGY_ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="GEOLOGY_ATTRIBUTES:GEO_ATT_VALUE">Geological Atttribute Value (Collecting Events:GEOLOGY_ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="GEOLOGY_ATTRIBUTES:GEOLOGY_ATTRIBUTE">Geology Attribute (Collecting Events:GEOLOGY_ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="GEOLOGY_ATTRIBUTES:GEOLOGY_ATTRIBUTE_ID">Geology Attribute Id (Collecting Events:GEOLOGY_ATTRIBUTES)</option>';
													
														newControls = newControls + '<option value="LOCALITY:GEOREF_UPDATED_DATE">Georef Updated Date [yyyy-mm-dd] (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:COLLECTING EVENTS_DETERMINED_BY_AGENT_ID">Georeference Determined By Agent (pick) (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:COLLECTING EVENTS_DETERMINED_DATE">Georeference Determined Date [yyyy/mm/dd] (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:MAX_ERROR_UNITS">Georeference Max Error Units (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:MAX_ERROR_DISTANCE">Georeference Maximum Error Distance (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:GEOREFMETHOD">Georeference Method (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:VERIFICATIONSTATUS">Georeference Verification Status (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:VERIFIED_BY_AGENT_ID">Georeference Verified By  (pick) (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LOCALITY:GEOREF_BY">Georeferenced By (username) (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:HABITAT_DESC">Habitat (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:HIGHER_GEOG">Higher Geography (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:HIGHERGEOGRAPHYID_GUID_TYPE">Highergeographyid GUID Type (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:ISLAND">Island (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:ISLAND_GROUP">Island Group (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LAT_LONG_FOR_NNP_FG">Lat Long Is For Nearest Named Place Flag (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LAT_LONG_REF_SOURCE">Lat Long Ref Source (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LAT_LONG_REMARKS">Lat Long Remarks (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LAT_DEG">Latitude Degrees (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LAT_DIR">Latitude Direction (N/S) (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LAT_MIN">Latitude Minutes (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LAT_SEC">Latitude Sec (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LOCALITY:LOCALITY_LOCALITY_ID_PICK">Locality (pick) (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LOCALITY:LOCALITY_LOCALITY_ID">Locality ID (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LOCALITY:LOCALITY_REMARKS">Locality Remarks (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LONG_DEG">Longitude Degrees (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LONG_DIR">Longitude Direction (E/W) (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LONG_MIN">Longitude Minutes (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:LONG_SEC">Longitude Seconds (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LOCALITY:MAX_DEPTH">Maximum Depth (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LOCALITY:MAXIMUM_ELEVATION">Maximum Elevation (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LOCALITY:MIN_DEPTH">Minimum Depth (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LOCALITY:MINIMUM_ELEVATION">Minimum Elevation (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:NEAREST_NAMED_PLACE">Nearest Named Place (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LOCALITY:NOGEOREFBECAUSE">No Georefernce Because (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:OCEAN_REGION">Ocean Region (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:OCEAN_SUBREGION">Ocean Subregion (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="LOCALITY:ORIG_ELEV_UNITS">Original Elevation Units (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:ORIG_LAT_LONG_UNITS">Original Lat Long Units (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:QUAD">Quadrangle Name (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="LOCALITY:RANGE">Range (PLSS) (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LOCALITY:RANGE_DIRECTION">Range Direction (PLSS) (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:VERBATIMSRS">SRS for Verbatim Lat/Long (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:SEA">Sea (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="LOCALITY:SECTION">Section (PLSS) (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LOCALITY:SECTION_PART">Section Part (PLSS) (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LOCALITY:SOVEREIGN_NATION">Sovereign Nation (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:SPATIALFIT">Spatial fit (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LOCALITY:SPEC_LOCALITY">Specific Locality (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:STATE_PROV">State/Province (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="LOCALITY:TOWNSHIP">Township (PLSS) (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LOCALITY:TOWNSHIP_DIRECTION">Township Direction (PLSS) (Collecting Events:LOCALITY)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:UTM_EW">UTM Easting (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:UTM_NS">UTM Northing (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="LAT_LONG:UTM_ZONE">UTM Zone (Collecting Events:LAT_LONG)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:VALID_DISTRIBUTION_FG">Valid Distribution Flag (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:VERBATIMCOORDINATESYSTEM">Verbatim Coordinate System (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:VERBATIMCOORDINATES">Verbatim Coordinates (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:VERBATIM_DATE">Verbatim Date (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:VERBATIMDEPTH">Verbatim Depth (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:VERBATIMELEVATION">Verbatim Elevation (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:VERBATIMLATITUDE">Verbatim Latitude (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:VERBATIM_LOCALITY">Verbatim Locality (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="COLLECTING_EVENT:VERBATIMLONGITUDE">Verbatim Longitude (Collecting Events:COLLECTING_EVENT)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:WKT_POLYGON">WKT Polygon (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:WATER_FEATURE">Water Feature (Collecting Events:GEOG_AUTH_REC)</option>';
													
														newControls = newControls + '<option value="GEOG_AUTH_REC:HIGHERGEOGRAPHYID">dwc:higherGeographyID (Collecting Events:GEOG_AUTH_REC)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Collectors">';
															
														newControls = newControls + '<option value="AGENT:AGENT_REMARKS">Agent Internal Remarks (Collectors:AGENT)</option>';
													
														newControls = newControls + '<option value="AGENT:BIOGRAPHY">Agent Public Biography (Collectors:AGENT)</option>';
													
														newControls = newControls + '<option value="AGENT:AGENT_TYPE">Agent Type (Collectors:AGENT)</option>';
													
														newControls = newControls + '<option value="PERSON:BIRTH_DATE_DATE">Birth Date Date [yyyy-mm-dd] (Collectors:PERSON)</option>';
													
														newControls = newControls + '<option value="PERSON:BIRTH_DATE">Birth Date as Text (Collectors:PERSON)</option>';
													
														newControls = newControls + '<option value="COLLECTOR:COLL_NUM">Coll Num (Collectors:COLLECTOR)</option>';
													
														newControls = newControls + '<option value="COLLECTOR:COLL_NUM_PREFIX">Coll Num Prefix (Collectors:COLLECTOR)</option>';
													
														newControls = newControls + '<option value="COLLECTOR:COLL_NUM_SUFFIX">Coll Num Suffix (Collectors:COLLECTOR)</option>';
													
														newControls = newControls + '<option value="AGENT:COLLECTORS_AGENT_ID">Collector (pick) (Collectors:AGENT)</option>';
													
														newControls = newControls + '<option value="AGENT:AGENTGUID">Collector Agent GUID (Collectors:AGENT)</option>';
													
														newControls = newControls + '<option value="AGENT:AGENTGUID_GUID_TYPE">Collector Agent GUID Type (Collectors:AGENT)</option>';
													
														newControls = newControls + '<option value="COLLECTOR:COLL_ORDER">Collector Ordinal Position (Collectors:COLLECTOR)</option>';
													
														newControls = newControls + '<option value="COLLECTOR:COLLECTOR_ROLE">Collector Role (c,p) (Collectors:COLLECTOR)</option>';
													
														newControls = newControls + '<option value="AGENT:EDITED">Collector is Vetted Agent (Collectors:AGENT)</option>';
													
														newControls = newControls + '<option value="AGENT_NAME:COLLECTORS_AGENT_NAME">Collectors Agent Name (Collectors:AGENT_NAME)</option>';
													
														newControls = newControls + '<option value="AGENT_NAME:COLLECTORS_AGENT_NAME_TYPE">Collectors Agent Name Type (Collectors:AGENT_NAME)</option>';
													
														newControls = newControls + '<option value="PERSON:DEATH_DATE_DATE">Death Date Date [yyyy-mm-dd] (Collectors:PERSON)</option>';
													
														newControls = newControls + '<option value="PERSON:DEATH_DATE">Death Date as Text (Collectors:PERSON)</option>';
													
														newControls = newControls + '<option value="PERSON:FIRST_NAME">First Name (Collectors:PERSON)</option>';
													
														newControls = newControls + '<option value="PERSON:LAST_NAME">Last Name (Collectors:PERSON)</option>';
													
														newControls = newControls + '<option value="PERSON:MIDDLE_NAME">Middle Name (Collectors:PERSON)</option>';
													
														newControls = newControls + '<option value="PERSON:PREFIX">Prefix (Collectors:PERSON)</option>';
													
														newControls = newControls + '<option value="PERSON:SUFFIX">Suffix (Collectors:PERSON)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Deaccessions">';
															
														newControls = newControls + '<option value="AGENT:DEACC_AGENT_ID">Deaccession Agent (pick) (Deaccessions:AGENT)</option>';
													
														newControls = newControls + '<option value="AGENT_NAME:DEACC_AGENT_NAME">Deaccession Agent Name (Deaccessions:AGENT_NAME)</option>';
													
														newControls = newControls + '<option value="DEACC_ITEM:DEACC_ITEM_REMARKS">Deaccession Item Remarks (Deaccessions:DEACC_ITEM)</option>';
													
														newControls = newControls + '<option value="DEACCESSION:DEACC_NUMBER">Deaccession Number (Deaccessions:DEACCESSION)</option>';
													
														newControls = newControls + '<option value="DEACCESSION:DEACC_REMARKS">Deaccession Remarks (Deaccessions:DEACCESSION)</option>';
													
														newControls = newControls + '<option value="DEACCESSION:DEACC_STATUS">Deaccession Status (Deaccessions:DEACCESSION)</option>';
													
														newControls = newControls + '<option value="DEACCESSION:DEACC_TYPE">Deaccession Type (Deaccessions:DEACCESSION)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Identifications">';
															
														newControls = newControls + '<option value="IDENTIFICATION:ACCEPTED_ID_FG">Accepted Id Flag (Identifications:IDENTIFICATION)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:AUTHOR_TEXT">Authorship (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:PHYLCLASS">Class (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="COMMON_NAME:COMMON_NAME">Common Name (Identifications:COMMON_NAME)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION:DATE_MADE_DATE">Date Made Date [yyyy-mm-dd] (Identifications:IDENTIFICATION)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION_AGENT:IDENTIFICATIONS_AGENT_ID">Determiner (pick) (Identifications:IDENTIFICATION_AGENT)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:DISPLAY_NAME">Display Name (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:DIVISION">Division (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:FAMILY">Family (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:FULL_TAXON_NAME">Full Taxon Name (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:GENUS">Genus (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION:IDENTIFICATION_REMARKS">Identification Remarks (Identifications:IDENTIFICATION)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION:IDENTIFICATIONS_PUBLICATION_ID">Identification sensu Publication (pick) (Identifications:IDENTIFICATION)</option>';
													
														newControls = newControls + '<option value="AGENT_NAME:IDENTIFICATIONS_AGENT_NAME">Identifications Agent Name (Identifications:AGENT_NAME)</option>';
													
														newControls = newControls + '<option value="AGENT_NAME:IDENTIFICATIONS_AGENT_NAME_TYPE">Identifications Agent Name Type (Identifications:AGENT_NAME)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:IDENTIFICATIONS_SCIENTIFIC_NAME">Identifications Scientific Name (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:IDENTIFICATIONS_SOURCE_AUTHORITY">Identifications Source Authority (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION_TAXONOMY:IDENTIFICATIONS_TAXON_NAME_ID">Identifications Taxon Name (Identifications:IDENTIFICATION_TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:IDENTIFICATIONS_VALID_CATALOG_TERM_FG">Identifications Valid Catalog Term Flag (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION:IDENTIFICATIONS_COLLECTION_OBJECT_ID">Identified Collection Object (pick) (Identifications:IDENTIFICATION)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION_AGENT:IDENTIFIER_ORDER">Identifier Order (Identifications:IDENTIFICATION_AGENT)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:INFRACLASS">Infraclass (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:INFRAORDER">Infraorder (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:INFRASPECIFIC_AUTHOR">Infraspecific Author (ICNafp) (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:INFRASPECIFIC_RANK">Infraspecific Rank  (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:KINGDOM">Kingdom (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION:MADE_DATE">Made Date as Text (Identifications:IDENTIFICATION)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION:NATURE_OF_ID">Nature Of Identification (Identifications:IDENTIFICATION)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:NOMENCLATURAL_CODE">Nomenclatural Code (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:TAXON_STATUS">Nomenclatural Status (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:PHYLORDER">Order (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:PHYLUM">Phylum (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SCIENTIFICNAMEID_GUID_TYPE">Scientificnameid Guid Type (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SPECIES">Species (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION:STORED_AS_FG">Stored As Flag (Identifications:IDENTIFICATION)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUBCLASS">Subclass (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUBDIVISION">Subdivision (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUBFAMILY">Subfamily (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUBGENUS">Subgenus (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUBORDER">Suborder (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUBPHYLUM">Subphylum (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUBSECTION">Subsection (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUBSPECIES">Subspecies (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUPERCLASS">Superclass (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUPERFAMILY">Superfamily (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SUPERORDER">Superorder (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION:TAXA_FORMULA">Taxa Formula (Identifications:IDENTIFICATION)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:TAXON_REMARKS">Taxon Remarks (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:TAXONID_GUID_TYPE">Taxonid Guid Type (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:TRIBE">Tribe (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="IDENTIFICATION_TAXONOMY:VARIABLE">Variable (Identifications:IDENTIFICATION_TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:SCIENTIFICNAMEID">dwc:scientificNameID (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:GUID">dwc:taxonID (Identifications:TAXONOMY)</option>';
													
														newControls = newControls + '<option value="TAXONOMY:TAXONID">dwc:taxonID (Identifications:TAXONOMY)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Keywords">';
															
														newControls = newControls + '<option value="FLAT:ANY_GEOGRAPHY">Any Geography (Keywords:FLAT)</option>';
													
														newControls = newControls + '<option value="FLAT:KEYWORD">Keywords (Keywords:FLAT)</option>';
													
														newControls = newControls + '<option value="FLAT:MAX_DEPTH_IN_M">Maximum Depth in Meters (Keywords:FLAT)</option>';
													
														newControls = newControls + '<option value="FLAT:MAX_ELEV_IN_M">Maximum elevation in meters. (Keywords:FLAT)</option>';
													
														newControls = newControls + '<option value="FLAT:MIN_DEPTH_IN_M">Minimum Depth in Meters (Keywords:FLAT)</option>';
													
														newControls = newControls + '<option value="FLAT:MIN_ELEV_IN_M">Minimum elevation in meters. (Keywords:FLAT)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Loans">';
															
														newControls = newControls + '<option value="AGENT:LOAN_AGENT_ID">Loan Agent (pick) (Loans:AGENT)</option>';
													
														newControls = newControls + '<option value="AGENT_NAME:LOAN_AGENT_NAME">Loan Agent Name (Loans:AGENT_NAME)</option>';
													
														newControls = newControls + '<option value="LOAN_ITEM:LOAN_ITEM_REMARKS">Loan Item Remarks (Loans:LOAN_ITEM)</option>';
													
														newControls = newControls + '<option value="LOAN:LOAN_NUMBER">Loan Number (Loans:LOAN)</option>';
													
														newControls = newControls + '<option value="LOAN:LOAN_STATUS">Loan Status (Loans:LOAN)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Media">';
															
														newControls = newControls + '<option value="MEDIA:AUTO_EXTENSION">File Extension (Media:MEDIA)</option>';
													
														newControls = newControls + '<option value="MEDIA:AUTO_FILENAME">Filename (Media:MEDIA)</option>';
													
														newControls = newControls + '<option value="MEDIA:AUTO_HOST">Host (Media:MEDIA)</option>';
													
														newControls = newControls + '<option value="MEDIA_LABELS:LABEL_VALUE">Label Value (Media:MEDIA_LABELS)</option>';
													
														newControls = newControls + '<option value="MEDIA:MASK_MEDIA_FG">Mask Media Flag (Media:MEDIA)</option>';
													
														newControls = newControls + '<option value="MEDIA_RELATIONS:MEDIA_CREATION_AGENT">Media Created By Agent (Media:MEDIA_RELATIONS)</option>';
													
														newControls = newControls + '<option value="MEDIA_LABELS:MEDIA_LABEL">Media Label (Media:MEDIA_LABELS)</option>';
													
														newControls = newControls + '<option value="makeAgentAutocompleteMeta:ASSIGNED_BY_AGENT_ID">Media Label Assigned By Agent (Media:makeAgentAutocompleteMeta)</option>';
													
														newControls = newControls + '<option value="MEDIA:MEDIA_LICENSE_ID">Media License (pick) (Media:MEDIA)</option>';
													
														newControls = newControls + '<option value="MEDIA_RELATIONS:CREATED_BY_AGENT_ID">Media Relationship Created By Agent (Media:MEDIA_RELATIONS)</option>';
													
														newControls = newControls + '<option value="MEDIA:MEDIA_TYPE">Media Type (Media:MEDIA)</option>';
													
														newControls = newControls + '<option value="MEDIA:MEDIA_URI">Media URI (IRI for the media object) (Media:MEDIA)</option>';
													
														newControls = newControls + '<option value="MEDIA:MIME_TYPE">Mime Type (Media:MEDIA)</option>';
													
														newControls = newControls + '<option value="MEDIA_RELATIONS:NEXT_MEDIA_RELATIONSHIP">Next Media Relationship (Media:MEDIA_RELATIONS)</option>';
													
														newControls = newControls + '<option value="MEDIA_RELATIONS:NEXT_RELATED_PRIMARY_KEY">Next Related Primary Key (Media:MEDIA_RELATIONS)</option>';
													
														newControls = newControls + '<option value="MEDIA:AUTO_PATH">Path (Media:MEDIA)</option>';
													
														newControls = newControls + '<option value="MEDIA:PREVIEW_URI">Preview URI (IRI for a thumbnail) (Media:MEDIA)</option>';
													
														newControls = newControls + '<option value="MEDIA:AUTO_PROTOCOL">Protocol (Media:MEDIA)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Named Groups">';
															
														newControls = newControls + '<option value="UNDERSCORE_COLLECTION:HTML_DESCRIPTION">HTML Description (Named Groups:UNDERSCORE_COLLECTION)</option>';
													
														newControls = newControls + '<option value="UNDERSCORE_COLLECTION:MASK_FG">Mask Flag (Named Groups:UNDERSCORE_COLLECTION)</option>';
													
														newControls = newControls + '<option value="UNDERSCORE_COLLECTION:COLLECTION_NAME">Name of Named Group (Named Groups:UNDERSCORE_COLLECTION)</option>';
													
														newControls = newControls + '<option value="UNDERSCORE_COLLECTION:NAMED GROUPS_UNDERSCORE_COLLECTION_ID">Named Group (pick) (Named Groups:UNDERSCORE_COLLECTION)</option>';
													
														newControls = newControls + '<option value="UNDERSCORE_COLLECTION:UNDERSCORE_AGENT_ID">Named Group Agent (pick) (Named Groups:UNDERSCORE_COLLECTION)</option>';
													
														newControls = newControls + '<option value="UNDERSCORE_COLLECTION:NAMED GROUPS_DESCRIPTION">Named Group Description (Named Groups:UNDERSCORE_COLLECTION)</option>';
													
														newControls = newControls + '<option value="UNDERSCORE_COLLECTION:UNDERSCORE_COLLECTION_ID_RAW">Named Group ID (underscore_collection_id) (Named Groups:UNDERSCORE_COLLECTION)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Relationships">';
															
														newControls = newControls + '<option value="BIOL_INDIV_RELATIONS:CREATED_BY">Created By (login) (Relationships:BIOL_INDIV_RELATIONS)</option>';
													
														newControls = newControls + '<option value="BIOL_INDIV_RELATIONS:RELATIONSHIPS_COLLECTION_OBJECT_ID">Related From Collection Object Id (pick) (Relationships:BIOL_INDIV_RELATIONS)</option>';
													
														newControls = newControls + '<option value="BIOL_INDIV_RELATIONS:RELATED_COLL_OBJECT_ID">Related To Collection Object Id (pick) (Relationships:BIOL_INDIV_RELATIONS)</option>';
													
														newControls = newControls + '<option value="BIOL_INDIV_RELATIONS:BIOL_INDIV_RELATION_REMARKS">Relationship Remarks (Relationships:BIOL_INDIV_RELATIONS)</option>';
													
														newControls = newControls + '<option value="BIOL_INDIV_RELATIONS:BIOL_INDIV_RELATIONSHIP">Type of Relationship (Relationships:BIOL_INDIV_RELATIONS)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Specimen Parts">';
															
														newControls = newControls + '<option value="SPECIMEN_PART:IS_TISSUE">Is Tissue [0 or 1] (Specimen Parts:SPECIMEN_PART)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART:PART_MODIFIER">Part Modifier (Specimen Parts:SPECIMEN_PART)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART:PART_NAME">Part Name (Specimen Parts:SPECIMEN_PART)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT_REMARK:PART_REMARKS">Part Remarks (Specimen Parts:COLL_OBJECT_REMARK)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART:DERIVED_FROM_CAT_ITEM">Part of Cataloged Item (Specimen Parts:SPECIMEN_PART)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART:PRESERVE_METHOD">Preserve Method (Specimen Parts:SPECIMEN_PART)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART:SAMPLED_FROM_OBJ_ID">Sampled From Collection Object ID (Specimen Parts:SPECIMEN_PART)</option>';
													
														newControls = newControls + '<option value="COLL_OBJECT:SPECIMEN_PART_CONDITION">Specimen Part  Condition (Specimen Parts:COLL_OBJECT)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_REMARK">Specimen Parts Attribute Remark (Specimen Parts:SPECIMEN_PART_ATTRIBUTE)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_TYPE">Specimen Parts Attribute Type (Specimen Parts:SPECIMEN_PART_ATTRIBUTE)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_UNITS">Specimen Parts Attribute Units (Specimen Parts:SPECIMEN_PART_ATTRIBUTE)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_ATTRIBUTE_VALUE">Specimen Parts Attribute Value (Specimen Parts:SPECIMEN_PART_ATTRIBUTE)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_DETERMINED_BY_AGENT_ID">Specimen Parts Determined By Agent (Specimen Parts:SPECIMEN_PART_ATTRIBUTE)</option>';
													
														newControls = newControls + '<option value="SPECIMEN_PART_ATTRIBUTE:SPECIMEN_PARTS_DETERMINED_DATE">Specimen Parts Determined Date [yyyy-mm-dd] (Specimen Parts:SPECIMEN_PART_ATTRIBUTE)</option>';
													
																newControls = newControls + '</optgroup>';
																
															newControls = newControls + '<optgroup label="Taxonomy">';
															
														newControls = newControls + '<option value="TAXA_TERMS_ALL:TAXA_TERM_ALL">Any Taxonomy (Taxonomy:TAXA_TERMS_ALL)</option>';
													
														newControls = newControls + '<option value="TAXA_TERMS:TAXA_TERM">Any Taxonomy (Current Id Only) (Taxonomy:TAXA_TERMS)</option>';
													
														newControls = newControls + '</optgroup>';
													
													newControls = newControls + '</select>';
													newControls= newControls + '</div>';
													newControls= newControls + '<div class="col-12 col-md-3">';
													newControls = newControls + '<input type="text" class="data-entry-input" name="searchText'+row+'" id="searchText'+row+'" placeholder="Enter Value"/>';
													newControls = newControls + '<input type="hidden" name="searchId'+row+'" id="searchId'+row+'" >';
													newControls = newControls + '</div>';
													newControls = newControls + '<div class="col-12 col-md-1">';
													newControls = newControls + '<select name="closeParens'+row+'" id="closeParens'+row+'" class="data-entry-select">';
													newControls = newControls + '<option value="0"></option><option value="1">)</option>';
													newControls = newControls + '<option value="2">))</option><option value="3">)))</option>';
													newControls = newControls + '<option value="4">))))</option>';
													newControls = newControls + '<option value="5">)))))</option>';
													newControls = newControls + '</select>';
													newControls= newControls + '</div>';
													newControls= newControls + '<div class="col-12 col-md-1">';
													newControls = newControls + '<button type="button" onclick=" removeBuilderRow(' + row + ');" arial-label="remove this row from the builder" class="btn btn-xs px-3 btn-warning mr-auto">Remove</button>';
													newControls = newControls + '</div>';
													newControls = newControls + '</div>';
													$("#customFields").append(newControls);
													$("#builderMaxRows").val(row);
													$('#field' + row).jqxComboBox({
														autoComplete: true,
														searchMode: 'containsignorecase',
														width: '100%',
														dropDownHeight: 400
													});
													var handleSelectString = "handleFieldSelection('field"+row+"',"+row+")";
													$('#field'+row).on("change", function(event) { 
														var handleSelect = new Function(handleSelectString);
														handleSelect();
													});
													$('#openParens'+row).on("change", function(event) { isNestingOk(); } )
													$('#closeParens'+row).on("change", function(event) { isNestingOk(); } )
												};
												$(document).ready(function(){
													$("#addRowButton").click(function(){
													   addBuilderRow();
													});
												});
											</script>
										</div>
										<div class="form-row mb-3">
											<div class="col-12">
												<button type="submit" class="btn btn-xs btn-primary col-12 col-md-auto px-md-5 mx-0 mr-md-5 my-1" id="searchbuilder-search" aria-label="run the search builder search">Search <i class="fa fa-search"></i></button>
												<button type="reset" class="btn btn-xs btn-outline-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-1" aria-label="Reset this search form to inital values" disabled="">Reset</button>
												<button type="button" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-1" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='https://mczbase-dev2.rc.fas.harvard.edu/Specimens.cfm?action=builderSearch';">New Search</button>
												
											</div>
										</div>
									</form>


								</div>
								
								<div class="container-fluid" id="builderSearchResultsSection" aria-live="polite">
									<div class="row mx-0">
										<div class="col-12">
											<div class="mb-3">
												<div class="row mt-1 mb-0 pb-2 pb-md-0 jqx-widget-header border px-2">
													<h1 class="h4 pt3px ml-2 ml-md-1">
														<span tabindex="0">Results: </span> 
														<span class="pr-2 font-weight-normal" id="builderresultCount" tabindex="0"></span> 
														<span id="builderresultLink" class="pr-2 font-weight-normal"></span>
													</h1>
													<div id="buildershowhide"></div>
													<div id="buildersaveDialogButton"></div>
													<div id="buildersaveDialog"></div>
													<div id="buildercolumnPickDialog">
														<div class="container-fluid">
															<div class="row pick-column-width" id="buildercolumnPick_row">
																<div class="col-12 col-md-3">
																	<div id="buildercolumnPick" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="buildercolumnPick1" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="buildercolumnPick2" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="buildercolumnPick3" class="px-1"></div>
																</div>
															</div>
														</div>
													</div>
													<div id="buildercolumnPickDialogButton"></div>
													<div id="builderresultDownloadButtonContainer"></div>
													<span id="buildermanageButton" class=""></span>
													<span id="builderremoveButtonDiv" class=""></span>
													<div id="builderresultBMMapLinkContainer"></div>
													<div id="builderselectModeContainer" class="ml-3" style="display: none;">
														<script>
															function builderchangeSelectMode(){
																var selmode = $("#builderselectMode").val();
																$("#buildersearchResultsGrid").jqxGrid({selectionmode: selmode});
																if (selmode=="none") { 
																	$("#buildersearchResultsGrid").jqxGrid({enableBrowserSelection: true});
																} else {
																	$("#buildersearchResultsGrid").jqxGrid({enableBrowserSelection: false});
																}
															};
														</script>
														<label class="data-entry-label d-inline w-auto mt-1" for="builderselectMode">Grid Select:</label>
														<select class="data-entry-select d-inline w-auto mt-1" id="builderselectMode" onchange="builderchangeSelectMode();">
															
															<option selected="" value="none">Text</option>
															
															<option value="singlecell">Single Cell</option>
															
															<option value="singlerow">Single Row</option>
															
															<option value="multiplerowsextended">Multiple Rows (click, drag, release)</option>
															
															<option value="multiplecellsadvanced">Multiple Cells (click, drag, release)</option>
														</select>
													</div>
													<output id="builderactionFeedback" class="btn btn-xs btn-transparent my-2 px-2 mx-1 border-0"></output> 
												</div>
												<div class="row mt-0"> 
													
													<div id="buildersearchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
													<div id="builderPostGridControls" class="p-1 d-none d-md-block" style="display: none;">
														
													</div>
													<div id="builderenableselection"></div>
												</div>
											</div>
										</div>
									</div>
								</div>
							</section>
						</div>
					</div>
				</div>
			</div>
		</main>
		
		<div id="overlay" style="position: absolute; top: 0px; left: 0px; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); border-color: transparent; opacity: 0.99; z-index: 2; display: none;">
			<div class="jqx-rc-all jqx-fill-state-normal" style="position: absolute; left: 50%; top: 25%; width: 10em; height: 2.4em;line-height: 2.4em; padding: 5px; color: #333333; border-color: #898989; border-style: solid; margin-left: -5em; opacity: 1;">
				<div class="jqx-grid-load" style="float: left; overflow: hidden; height: 32px; width: 32px;"></div>
				<div style="float: left; display: block; margin-left: 1em;">Searching...</div>	
			</div>
		</div>	
	</div>
	<script>
		// setup for persistence of column selections
		window.columnHiddenSettings = new Object();

		
			lookupColumnVisibilities ('/Specimens.cfm','Default');
		
			function columnOrderChanged(gridId) { 
				if (columnOrderLoading==0) { 
					var columnCount = $('#'+gridId).jqxGrid("columns").length();
					var columnMap = new Map();
					for (var i=0; i<columnCount; i++) { 
						var fieldName = $('#'+gridId).jqxGrid("columns").records[i].datafield;
						if (fieldName) { 
							var column_number = $('#'+gridId).jqxGrid("getColumnIndex",fieldName); 
							columnMap.set(fieldName,column_number);
						}
					}
					JSON.stringify(Array.from(columnMap));
					saveColumnOrder('/Specimens.cfm',columnMap,'Default',null);
				} else { 
					console.log("columnOrderChanged called while loading column order, ignoring");
				}
			}
		

		function loadColumnOrder(gridId) { 
			
				jQuery.ajax({
					dataType: "json",
					url: "/shared/component/functions.cfc",
					data: { 
						method : "getGridColumnOrder",
						page_file_path: '/Specimens.cfm',
						label: 'Default',
						returnformat : "json",
						queryformat : 'column'
					},
					ajaxGridId : gridId,
					error: function (jqXHR, status, message) {
						messageDialog("Error looking up column order: " + status + " " + jqXHR.responseText ,'Error: '+ status);
					},
					success: function (result) {
						var gridId = this.ajaxGridId;
						var settings = result[0];
						if (typeof settings !== "undefined" && settings!=null) { 
							setColumnOrder(gridId,JSON.parse(settings.column_order));
						}
					}
				});
			
		} 

		
			function setColumnOrder(gridId, columnMap) { 
				columnOrderLoading = 1;
				$('#' + gridId).jqxGrid('beginupdate');
				try { 
					for (var i=0; i<columnMap.length; i++) {
						var kvp = columnMap[i];
						var key = kvp[0];
						var value = kvp[1];
						if ($('#'+gridId).jqxGrid("getColumnIndex",key) != value) { 
							if (key && value) {
								try {
									console.log(key + " set to column " + value);
									$('#'+gridId).jqxGrid("setColumnIndex",key,value);
								} catch (e) {};
							}
						}
					}
				} catch (error) { 
					console.error("Failed to set column order");
					console.error(error);
				}
				$('#' + gridId).jqxGrid('endupdate');
				columnOrderLoading = 0;
			}
		
	
		// ***** cell renderers *****
		// cell renderer to display a thumbnail with alt tag given columns preview_uri, media_uri, and ac_description 
		var thumbCellRenderer_f = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("#fixedsearchResultsGrid").jqxGrid('getrowdata',row);
			var puri = rowData['preview_uri'];
			var muri = rowData['media_uri'];
			var alt = rowData['ac_description'];
			if (puri != "") { 
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="'+ muri + '"><img src="'+puri+'" alt="'+alt+'" width="100"></a></span>';
			} else { 
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
			}
		};
	
		// *** Cell renderers that look up data from additional columns *********** 

		// NOTE: Since there are three grids, and the cellsrenderer api does not pass a reference to the grid, a separate
		// cell renderer must be added for each grid,  cf_spec_res_cols_r.cellsrenderer values starting with _ are interpreted
		// as fixed_, keyword_, builder_ cell renderers depending on the grid in which the cellsrenderer value is being applied. 
		
		// cell renderer to link out to specimen details page by collection_object_id, only works for role DATA_ENTRY
		// Deprecated.
		
			var fixed_linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("#fixedsearchResultsGrid").jqxGrid('getrowdata',row);
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/specimens/Specimen.cfm/' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['GUID'] +'</a></span>';
			};
			var keyword_linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("#keywordsearchResultsGrid").jqxGrid('getrowdata',row);
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/specimens/Specimen.cfm/' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['GUID'] +'</a></span>';
			};
			var builder_linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("#buildersearchResultsGrid").jqxGrid('getrowdata',row);
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/specimens/Specimen.cfm/' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['GUID'] +'</a></span>';
			};
		
		// media cell renderers, use _mediaCellRenderer in cf_spec_res_cols_r.cellsrenderer 
		// note, collection_object_id is not available to users without DATA_ENTRY, but media_id, so 'undefined' will be passed
		// to findMedia.cfm, but findMedia can handle this case.
		var fixed_mediaCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("#fixedsearchResultsGrid").jqxGrid('getrowdata',row);
			if (rowData) { 
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/media/findMedia.cfm?execute=true&method=getMedia&media_relationship_type=ANY%20cataloged_item&media_relationship_value='+ rowData['GUID'] +'&media_relationship_id=' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['MEDIA'] +'</a></span>';
			}
		};
		var keyword_mediaCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("#keywordsearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/media/findMedia.cfm?execute=true&method=getMedia&media_relationship_type=ANY%20cataloged_item&media_relationship_value='+ rowData['GUID'] +'&media_relationship_id=' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['MEDIA'] +'</a></span>';
		};
		var builder_mediaCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("#buildersearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/media/findMedia.cfm?execute=true&method=getMedia&media_relationship_type=ANY%20cataloged_item&media_relationship_value='+ rowData['GUID'] +'&media_relationship_id=' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['MEDIA'] +'</a></span>';
		};
		// scientific name (with authorship, etc) cell renderers, use _sciNameCellRenderer in cf_spec_res_cols_r.cellsrenderer 
		var fixed_sciNameCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("#fixedsearchResultsGrid").jqxGrid('getrowdata',row);
			if (rowData) { 
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/name/'+ rowData['SCIENTIFIC_NAME'] +'">'+ value +'</a></span>';
			}
		};
		var keyword_sciNameCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("#keywordsearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/name/'+ rowData['SCIENTIFIC_NAME'] +'">'+ value +'</a></span>';
		};
		var builder_sciNameCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("#buildersearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/name/'+ rowData['SCIENTIFIC_NAME'] +'">'+ value +'</a></span>';
		};
		// guid with marker for specimen images 
		var fixed_GuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("#fixedsearchResultsGrid").jqxGrid('getrowdata',row);
			var mediaMarker = "";
			if (rowData) { 
				var media = rowData['MEDIA'];
				if (media.includes("shows cataloged_item")) { 
					mediaMarker = " <a href='/media/findMedia.cfm?execute=true&method=getMedia&related_cataloged_item="+ rowData['GUID'] +"' target='_blank'><img src='/shared/images/Image-x-generic.png' height='20' width='20'></a>"
				}
			}
			var result_id = $('#result_id_fixedSearch').val();
			// The /guid/ uri is rewritten by apache to a request to a guid handler.cfm file instead.
			var retval = '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">';
			retval = retval + '<a id="aLink'+row+'" target="_blank" href="/guid/' + value + '"';
			retval = retval + ' onClick=" event.preventDefault(); $(&#39;#aLinkForm'+row+'&#39;).submit();" ';
			retval = retval + '>'+value+'</a>';
			retval = retval + mediaMarker;
			retval = retval + '<form action="/guid/'+value+'" method="post" target="_blank" id="aLinkForm'+row+'">';
			retval = retval + '<input type="hidden" name="result_id" value="'+result_id+'" />';
			retval = retval + '</form>';
			retval = retval + '</span>';
			return retval;
			//return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + value + '">'+value+'</a>'+mediaMarker+'</span>';
		};
		var keyword_GuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("#keywordsearchResultsGrid").jqxGrid('getrowdata',row);
			var mediaMarker = "";
			var media = rowData['MEDIA'];
			if (media.includes("shows cataloged_item")) { 
				mediaMarker = " <a href='/media/findMedia.cfm?execute=true&method=getMedia&related_cataloged_item="+ rowData['GUID'] +"' target='_blank'><img src='/shared/images/Image-x-generic.png' height='20' width='20'></a>"
			}
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + value + '">'+value+'</a>'+mediaMarker+'</span>';
		};
		var builder_GuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("#buildersearchResultsGrid").jqxGrid('getrowdata',row);
			var mediaMarker = "";
			var media = rowData['MEDIA'];
			if (media.includes("shows cataloged_item")) { 
				mediaMarker = " <a href='/media/findMedia.cfm?execute=true&method=getMedia&related_cataloged_item="+ rowData['GUID'] +"' target='_blank'><img src='/shared/images/Image-x-generic.png' height='20' width='20'></a>"
			}
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + value + '">'+value+'</a>'+mediaMarker+'</span>';
		};

		// *** Cell renderers that display data from only the single rendered column *********** 
	
		// cell renderer to link out to specimen details page by guid, when value is guid.
		var linkGuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a class="celllink" target="_blank" href="/guid/' + value + '">'+value+'</a></span>';
		};
		// cell renderer to link out to taxon page by scientific name, when value is scientific name.
		var linkTaxonCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			return '<a target="_blank" href="/name/' + value + '">'+value+'</a>';
		};
		// cell renderer to display yes or blank for a 1/0 flag field.
		var yesBlankFlagRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var displayValue = "";
			if (value==1) {
				displayValue = "Yes";
			}
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+displayValue+'</span>';
		};
		// cell renderer to display yes or no for a 1/0 flag field.
		var yesNoFlagRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var displayValue = "No";
			if (value==1) {
				displayValue = "Yes";
			}
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+displayValue+'</span>';
		};

		
				// remove individual rows from a result set one by one with button.
				var removeFixedCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					// Removes a row, then jqwidgets invokes the deleterow callback defined for the dataadaptor
					return '<span style="margin-top: 4px; margin-left: 4px; float: ' + columnproperties.cellsalign + '; "><input type="button" onClick=" confirmDialog(&apos;Remove this row from these search results&apos;,&apos;Confirm Remove Row&apos;, function(){ var commit = $(&apos;#fixedsearchResultsGrid&apos;).jqxGrid(&apos;deleterow&apos;, '+ row +'); fixedResultModifiedHere(); } ); " class="p-1 btn btn-xs btn-warning" value="&#8998;" aria-label="Remove"/></span>';
				};
				
				var removeKeywordCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					// Removes a row, then jqwidgets invokes the deleterow callback defined for the dataadaptor
					return '<span style="margin-top: 4px; margin-left: 4px; float: ' + columnproperties.cellsalign + '; "><input type="button" onClick=" confirmDialog(&apos;Remove this row from these search results&apos;,&apos;Confirm Remove Row&apos;, function(){ var commit = $(&apos;#keywordsearchResultsGrid&apos;).jqxGrid(&apos;deleterow&apos;, '+ row +'); keywordResultModifiedHere(); } ); " class="p-1 btn btn-xs btn-warning" value="&#8998;" aria-label="Remove"/></span>';
				};
				
				var removeBuilderCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					// Removes a row, then jqwidgets invokes the deleterow callback defined for the dataadaptor
					return '<span style="margin-top: 4px; margin-left: 4px; float: ' + columnproperties.cellsalign + '; "><input type="button" onClick=" confirmDialog(&apos;Remove this row from these search results&apos;,&apos;Confirm Remove Row&apos;, function(){ var commit = $(&apos;#buildersearchResultsGrid&apos;).jqxGrid(&apos;deleterow&apos;, '+ row +'); builderResultModifiedHere() } ); " class="p-1 btn btn-xs btn-warning" value="&#8998;" aria-label="Remove"/></span>';
				};
				
			

		// cellclass function 
		// NOTE: Since there are three grids, and the cellclass api does not pass a reference to the grid, a separate
		// function is needed for each grid.  Unlike the cell renderer, the same function is used for all columns.
		//
		// Set the row color based on type status
		var keywordcellclass = function (row, columnfield, value) {
			if (row>-1) { 
				var rowData = jQuery("#keywordsearchResultsGrid").jqxGrid('getrowdata',row);
				var toptypestatuskind = rowData['TOPTYPESTATUSKIND'];
				if (toptypestatuskind=='Primary') { 
					return "primaryTypeCell";
				} else if (toptypestatuskind=='Secondary') { 
					return "secondaryTypeCell";
				}
			}
		};
		var fixedcellclass = function (row, columnfield, value) {
			if (row>-1) { 
				var rowData = jQuery("#fixedsearchResultsGrid").jqxGrid('getrowdata',row);
				if (rowData) { 
					var toptypestatuskind = rowData['TOPTYPESTATUSKIND'];
					if (toptypestatuskind=='Primary') { 
						return "primaryTypeCell";
					} else if (toptypestatuskind=='Secondary') { 
						return "secondaryTypeCell";
					}
				}
			}
		};
		var buildercellclass = function (row, columnfield, value) {
			if (row>-1) { 
				var rowData = jQuery("#buildersearchResultsGrid").jqxGrid('getrowdata',row);
				var toptypestatuskind = rowData['TOPTYPESTATUSKIND'];
				if (toptypestatuskind=='Primary') { 
					return "primaryTypeCell";
				} else if (toptypestatuskind=='Secondary') { 
					return "secondaryTypeCell";
				}
			}
		};
	
		// bindingcomplete is fired on each page load of the grid, we need to distinguish the first page load from subsequent loads.
		var fixedSearchLoaded = 0;
		var keywordSearchLoaded = 0;
		var builderSearchLoaded = 0;

		// prevent on columnreordered event from causing save of grid column order when loading order from persistance store
		var columnOrderLoading = 0
	
		function serializeFormAsJSON(formID) {
		  const array = $('#'+formID).serializeArray();
		  const json = {};
		  $.each(array, function () {
		    json[this.name] = this.value || "";
		  });
		  return json;
		}

		
			

			var fixedreloadlistenerbound = false;
			var keywordreloadlistenerbound = false;
			var builderreloadlistenerbound = false;

			function fixedResultModifiedHere() { 
				$('#fixedresultCount').html('Modified, record removed.');
				var result_id = $("#result_id_fixedSearch").val();
				bc.postMessage({"source":"search","result_id":result_id});
				if (!fixedreloadlistenerbound) { 
					$('#fixedsearchResultsGrid').on("bindingcomplete", function (event) {
						resultModified("fixedsearchResultsGrid","fixed");
					});
					fixedreloadlistenerbound = true;
				}
			}
			function keywordResultModifiedHere() { 
				$('#keywordresultCount').html('Modified, record removed.');
				var result_id = $("#result_id_keywordSearch").val();
				bc.postMessage({"source":"search","result_id":result_id});
				if (!keywordreloadlistenerbound) { 
					$('#keywordsearchResultsGrid').on("bindingcomplete", function (event) {
						resultModified("keywordsearchResultsGrid","keyword");
					});
					keywordreloadlistenerbound = true;
				}
			}
			function builderResultModifiedHere() { 
				$('#builderresultCount').html('Modified, record removed.');
				var result_id = $("#result_id_builderSearch").val();
				bc.postMessage({"source":"search","result_id":result_id});
				if (!builderreloadlistenerbound) { 
					$('#buildersearchResultsGrid').on("bindingcomplete", function (event) {
						resultModified("buildersearchResultsGrid","builder");
					});
					builderreloadlistenerbound = true;
				}
			}
	
			bc.onmessage = function (message) { 
				console.log(message);
				if (message.data.source == "manage" &&  message.data.result_id == $("#result_id_fixedSearch").val()) { 
					$('#fixedresultCount').html('Modified from manage page.');
					if (!fixedreloadlistenerbound) { 
						$('#fixedsearchResultsGrid').on("bindingcomplete", function (event) {
							resultModified("fixedsearchResultsGrid","fixed");
						});
						fixedreloadlistenerbound = true;
					}
					$('#fixedsearchResultsGrid').jqxGrid('updatebounddata');
				} 
				if (message.data.source == "manage" &&  message.data.result_id == $("#result_id_keywordSearch").val()) { 
					$('#keywordresultCount').html('Modified from manage page.');
					if (!keywordreloadlistenerbound) { 
						$('#keywordsearchResultsGrid').on("bindingcomplete", function (event) {
							resultModified("keywordsearchResultsGrid","keyword");
						});
						keywordreloadlistenerbound = true;
					}
					$('#keywordsearchResultsGrid').jqxGrid('updatebounddata');
				} 
				if (message.data.source == "manage" &&  message.data.result_id == $("#result_id_builderSearch").val()) { 
					$('#builderresultCount').html('Modified from manage page.');
					if (!builderreloadlistenerbound) { 
						$('#buildersearchResultsGrid').on("bindingcomplete", function (event) {
							resultModified("buildersearchResultsGrid","builder");
						});
						builderreloadlistenerbound = true;
					}
					$('#buildersearchResultsGrid').jqxGrid('updatebounddata');
				} 
			}
		 

		/* End Setup jqxgrids for search ****************************************************************************************/
		$(document).ready(function() {
			/* Setup jqxgrid for fixed Search */
			$('#fixedSearchForm').bind('submit', function(evt){
				evt.preventDefault();
			
				var uuid = getVersion4UUID();
				$("#result_id_fixedSearch").val(uuid);
	
				
					if (Object.keys(window.columnHiddenSettings).length == 0) {
						lookupColumnVisibilities ('/Specimens.cfm','Default');
					}
				

				fixedSearchLoaded = 0;

				$("#overlay").show();
				$("#fixedsearchResultsGrid").replaceWith('<div id="fixedsearchResultsGrid" class="fixedResults jqxGrid focus" style="z-index: 1;"></div>');
				$('#fixedresultCount').html('');
				$('#fixedresultLink').html('');
				$("#fixedshowhide").html("");
				$('#fixedmanageButton').html('');
				$('#fixedremoveButtonDiv').html('');
				$('#fixedsaveDialogButton').html('');
				$('#fixedactionFeedback').html('');
				$('#fixedselectModeContainer').hide();
				$('#fixedPostGridControls').hide();
				debug = $('#fixedSearchForm').serialize();
				console.log(debug);
				/*var datafieldlist = [ ];//add synchronous call to cf component*/
	
				var search = null;

				if ($('#fixedSearchForm').serialize().length > 7900) { 
					// POST to accomodate long catalog number lists
					search = 
					{
						datatype: "json",
						
						datafields:
						[
							{name: 'GUID', type: 'string' }
								,{name: 'COLLECTION', type: 'string' }
								,{name: 'CAT_NUM', type: 'string' }
								,{name: 'CAT_NUM_INTEGER', type: 'number' }
								,{name: 'CAT_NUM_PREFIX', type: 'string' }
								,{name: 'COLLECTION_OBJECT_ID', type: 'string' }
								,{name: 'DEACCESSIONED', type: 'string' }
								,{name: 'TOPTYPESTATUSKIND', type: 'string' }
								,{name: 'COLL_OBJ_DISPOSITION', type: 'string' }
								,{name: 'ACCESSION', type: 'string' }
								,{name: 'ORIG_LAT_LONG_UNITS', type: 'string' }
								,{name: 'TOPTYPESTATUS', type: 'string' }
								,{name: 'LAT_LONG_DETERMINER', type: 'string' }
								,{name: 'LAT_LONG_REF_SOURCE', type: 'string' }
								,{name: 'TYPESTATUS', type: 'string' }
								,{name: 'LAT_LONG_REMARKS', type: 'string' }
								,{name: 'TYPESTATUS_DISPLAY', type: 'string' }
								,{name: 'TYPESTATUSPLAIN', type: 'string' }
								,{name: 'ASSOCIATED_SPECIES', type: 'string' }
								,{name: 'MICROHABITAT', type: 'string' }
								,{name: 'MIN_ELEV_IN_M', type: 'string' }
								,{name: 'HABITAT_DESC', type: 'string' }
								,{name: 'MAX_ELEV_IN_M', type: 'string' }
								,{name: 'MINIMUM_ELEVATION', type: 'string' }
								,{name: 'MAXIMUM_ELEVATION', type: 'string' }
								,{name: 'ORIG_ELEV_UNITS', type: 'string' }
								,{name: 'SPEC_LOCALITY', type: 'string' }
								,{name: 'SCI_NAME_WITH_AUTH', type: 'string' }
								,{name: 'IDENTIFIED_BY', type: 'string' }
								,{name: 'SCIENTIFIC_NAME', type: 'string' }
								,{name: 'IDENTIFIEDBY', type: 'string' }
								,{name: 'AUTHOR_TEXT', type: 'string' }
								,{name: 'SCI_NAME_WITH_AUTH_PLAIN', type: 'string' }
								,{name: 'ID_SENSU', type: 'string' }
								,{name: 'REMARKS', type: 'string' }
								,{name: 'COLLECTORS', type: 'string' }
								,{name: 'BEGAN_DATE', type: 'string' }
								,{name: 'ENDED_DATE', type: 'string' }
								,{name: 'COLLECTING_METHOD', type: 'string' }
								,{name: 'DEC_LAT', type: 'string' }
								,{name: 'DEC_LONG', type: 'string' }
								,{name: 'DATUM', type: 'string' }
								,{name: 'COORDINATEUNCERTAINTYINMETERS', type: 'string' }
								,{name: 'GEOREFMETHOD', type: 'string' }
								,{name: 'SEX', type: 'string' }
								,{name: 'MIN_DEPTH', type: 'string' }
								,{name: 'MAX_DEPTH', type: 'string' }
								,{name: 'AGE', type: 'string' }
								,{name: 'DEPTH_UNITS', type: 'string' }
								,{name: 'AGE_CLASS', type: 'string' }
								,{name: 'PREPARATORS', type: 'string' }
								,{name: 'ASSOCIATEDSEQUENCES', type: 'string' }
								,{name: 'PARTS', type: 'string' }
								,{name: 'PARTDETAIL', type: 'string' }
								,{name: 'TOTAL_PARTS', type: 'string' }
								,{name: 'GENBANKNUM', type: 'string' }
								,{name: 'COLLECTING_SOURCE', type: 'string' }
								,{name: 'VERIFICATIONSTATUS', type: 'string' }
								,{name: 'LOCALITY_REMARKS', type: 'string' }
								,{name: 'CONTINENT_OCEAN', type: 'string' }
								,{name: 'TYPESTATUSWORDS', type: 'string' }
								,{name: 'CONTINENT', type: 'string' }
								,{name: 'COUNTRY', type: 'string' }
								,{name: 'SOVEREIGN_NATION', type: 'string' }
								,{name: 'COUNTRYCODE', type: 'string' }
								,{name: 'STATE_PROV', type: 'string' }
								,{name: 'SEA', type: 'string' }
								,{name: 'FEATURE', type: 'string' }
								,{name: 'COUNTY', type: 'string' }
								,{name: 'ISLAND_GROUP', type: 'string' }
								,{name: 'QUAD', type: 'string' }
								,{name: 'ISLAND', type: 'string' }
								,{name: 'WATER_FEATURE', type: 'string' }
								,{name: 'WATERBODY', type: 'string' }
								,{name: 'HIGHER_GEOG', type: 'string' }
								,{name: 'VERBATIMLONGITUDE', type: 'string' }
								,{name: 'VERBATIMLOCALITY', type: 'string' }
								,{name: 'VERBATIMLATITUDE', type: 'string' }
								,{name: 'VERBATIMELEVATION', type: 'string' }
								,{name: 'LONGITUDE_AS_ENTERED', type: 'string' }
								,{name: 'COLLECTING_TIME', type: 'string' }
								,{name: 'DATE_EMERGED', type: 'string' }
								,{name: 'CITED_AS', type: 'string' }
								,{name: 'DATE_COLLECTED', type: 'string' }
								,{name: 'VERBATIM_DATE', type: 'string' }
								,{name: 'ISO_BEGAN_DATE', type: 'string' }
								,{name: 'ISO_ENDED_DATE', type: 'string' }
								,{name: 'KINGDOM', type: 'string' }
								,{name: 'PHYLUM', type: 'string' }
								,{name: 'PHYLCLASS', type: 'string' }
								,{name: 'PHYLORDER', type: 'string' }
								,{name: 'FAMILY', type: 'string' }
								,{name: 'TRIBE', type: 'string' }
								,{name: 'SUBPHYLIM', type: 'string' }
								,{name: 'SUBCLASS', type: 'string' }
								,{name: 'INFRACLASS', type: 'string' }
								,{name: 'SUPERORDER', type: 'string' }
								,{name: 'SUBORDER', type: 'string' }
								,{name: 'INFRAORDER', type: 'string' }
								,{name: 'SUPERFAMILY', type: 'string' }
								,{name: 'SUBFAMILY', type: 'string' }
								,{name: 'GENUS', type: 'string' }
								,{name: 'SPECIES', type: 'string' }
								,{name: 'SUBSPECIES', type: 'string' }
								,{name: 'INFRASPECIFIC_RANK', type: 'string' }
								,{name: 'UNNAMED_FORM', type: 'string' }
								,{name: 'NOMENCLATURAL_CODE', type: 'string' }
								,{name: 'IDENTIFICATION_REMARKS', type: 'string' }
								,{name: 'TAXONID', type: 'string' }
								,{name: 'SCIENTIFICNAMEID', type: 'string' }
								,{name: 'CITATIONS', type: 'string' }
								,{name: 'MADE_DATE', type: 'string' }
								,{name: 'FULL_TAXONOMY', type: 'string' }
								,{name: 'ON_LOAN', type: 'string' }
								,{name: 'PARTS_ON_LOAN', type: 'string' }
								,{name: 'CLOSED_LOANS', type: 'string' }
								,{name: 'ACCESSION_RESTRICTIONS', type: 'number' }
								,{name: 'ACCESSION_BENEFITS', type: 'number' }
								,{name: 'RECEIVED_FROM', type: 'string' }
								,{name: 'ACCESSION_DATE', type: 'string' }
								,{name: 'RECEIVED_DATE', type: 'string' }
								,{name: 'ROOMS', type: 'string' }
								,{name: 'CABINETS', type: 'string' }
								,{name: 'DRAWERS', type: 'string' }
								,{name: 'STORED_AS', type: 'string' }
								,{name: 'ENCUMBRANCES', type: 'string' }
								,{name: 'GEOL_GROUP', type: 'string' }
								,{name: 'FORMATION', type: 'string' }
								,{name: 'MEMBER', type: 'string' }
								,{name: 'BED', type: 'string' }
								,{name: 'LATESTERAORHIGHESTERATHEM', type: 'string' }
								,{name: 'LATITUDE_AS_ENTERED', type: 'string' }
								,{name: 'EARLIESTERAORLOWESTERATHEM', type: 'string' }
								,{name: 'LATESTPERIODORHIGHESTSYSTEM', type: 'string' }
								,{name: 'EARLIESTPERIODORLOWESTSYSTEM', type: 'string' }
								,{name: 'EARLIESTEPOCHORLOWESTSERIES', type: 'string' }
								,{name: 'LATESTAGEORHIGHESTSTAGE', type: 'string' }
								,{name: 'EARLIESTAGEORLOWESTSTAGE', type: 'string' }
								,{name: 'LATESTEPOCHORHIGHESTSERIES', type: 'string' }
								,{name: 'EARLIESTEONORLOWESTEONOTHEM', type: 'string' }
								,{name: 'LATESTEONORHIGHESTEONOTHEM', type: 'string' }
								,{name: 'LITHOSTRATIGRAPHICTERMS', type: 'string' }
								,{name: 'RELATEDCATALOGEDITEMS', type: 'string' }
								,{name: 'MEDIA', type: 'string' }
								,{name: 'COLLECTION_CDE', type: 'string' }
								,{name: 'ASSOCIATED_GRANT', type: 'string' }
								,{name: 'ASSOCIATED_MCZ_COLLECTION', type: 'string' }
								,{name: 'ABNORMALITY', type: 'string' }
								,{name: 'ASSOCIATED_TAXON', type: 'string' }
								,{name: 'BARE_PARTS_COLORATION', type: 'string' }
								,{name: 'BODY_LENGTH', type: 'string' }
								,{name: 'CITATION', type: 'string' }
								,{name: 'COLORS', type: 'string' }
								,{name: 'CROWN_RUMP_LENGTH', type: 'string' }
								,{name: 'DIAMETER', type: 'string' }
								,{name: 'DISK_LENGTH', type: 'string' }
								,{name: 'DISK_WIDTH', type: 'string' }
								,{name: 'EAR_FROM_NOTCH', type: 'string' }
								,{name: 'EXTENT', type: 'string' }
								,{name: 'FAT_DEPOSITION', type: 'string' }
								,{name: 'FOREARM_LENGTH', type: 'string' }
								,{name: 'FORK_LENGTH', type: 'string' }
								,{name: 'FOSSIL_MEASUREMENT', type: 'string' }
								,{name: 'HEAD_LENGTH', type: 'string' }
								,{name: 'HEIGHT', type: 'string' }
								,{name: 'HIND_FOOT_WITH_CLAW', type: 'string' }
								,{name: 'HOST', type: 'string' }
								,{name: 'INCUBATION', type: 'string' }
								,{name: 'LENGTH', type: 'string' }
								,{name: 'LIFE_CYCLE_STAGE', type: 'string' }
								,{name: 'LIFE_STAGE', type: 'string' }
								,{name: 'MAX_DISPLAY_ANGLE', type: 'string' }
								,{name: 'MOLT_CONDITION', type: 'string' }
								,{name: 'NUMERIC_AGE', type: 'string' }
								,{name: 'OSSIFICATION', type: 'string' }
								,{name: 'PLUMAGE_COLORATION', type: 'string' }
								,{name: 'PLUMAGE_DESCRIPTION', type: 'string' }
								,{name: 'REFERENCE', type: 'string' }
								,{name: 'REPRODUCTIVE_CONDITION', type: 'string' }
								,{name: 'REPRODUCTIVE_DATA', type: 'string' }
								,{name: 'SECTION_LENGTH', type: 'string' }
								,{name: 'SECTION_STAIN', type: 'string' }
								,{name: 'SIZE_FISH', type: 'string' }
								,{name: 'SNOUT_VENT_LENGTH', type: 'string' }
								,{name: 'SPECIMEN_LENGTH', type: 'string' }
								,{name: 'STAGE_DESCRIPTION', type: 'string' }
								,{name: 'STANDARD_LENGTH', type: 'string' }
								,{name: 'STOMACH_CONTENTS', type: 'string' }
								,{name: 'STORAGE', type: 'string' }
								,{name: 'TAIL_LENGTH', type: 'string' }
								,{name: 'TEMPERATURE_EXPERIMENT', type: 'string' }
								,{name: 'TOTAL_LENGTH', type: 'string' }
								,{name: 'TOTAL_SIZE', type: 'string' }
								,{name: 'TRAGUS_LENGTH', type: 'string' }
								,{name: 'UNFORMATTED_MEASUREMENTS', type: 'string' }
								,{name: 'UNSPECIFIED_MEASUREMENT', type: 'string' }
								,{name: 'WEIGHT', type: 'string' }
								,{name: 'WIDTH', type: 'string' }
								,{name: 'WING_CHORD', type: 'string' }
								,{name: 'LOCALITY_ID', type: 'number' }
								,{name: 'COLLECTING_EVENT_ID', type: 'number' }
								,{name: 'INSTITUTION_ACRONYM', type: 'string' }
								,{name: 'LAST_EDIT_DATE', type: 'string' }
								,{name: 'CUSTOMID', type: 'string' }
								,{name: 'MYCUSTOMIDTYPE', type: 'string' }
								,{name: 'OTHERCATALOGNUMBERS', type: 'string' }
								
						],
						beforeprocessing: function (data) {
							if (data != null && data.length > 0) {
								search.totalrecords = data[0].recordcount;
							}
						},
						sort: function () {
							$("#fixedsearchResultsGrid").jqxGrid('updatebounddata','sort');
						},
						root: 'specimenRecord',
						id: 'collection_object_id',
						url: '/specimens/component/search.cfc',
						type: 'POST',
						data: serializeFormAsJSON('fixedSearchForm'),
						timeout: 120000,  // units not specified, miliseconds?  Fixed
						loadError: function(jqXHR, textStatus, error) {
							handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
						},
						async: true,
						deleterow: function (rowid, commit) {
							console.log(rowid);
							console.log($('#fixedsearchResultsGrid').jqxGrid('getRowData',rowid));
							var collobjtoremove = $('#fixedsearchResultsGrid').jqxGrid('getRowData',rowid)['COLLECTION_OBJECT_ID'];
							console.log(collobjtoremove);
		        			$.ajax({
            				url: "/specimens/component/search.cfc",
            				data: { 
									method: 'removeItemFromResult', 
									result_id: $('#result_id_fixedSearch').val(),
									collection_object_id: collobjtoremove
								},
								dataType: 'json',
           					success : function (data) { 
									console.log(data);
									commit(true);
									$('#fixedsearchResultsGrid').jqxGrid('updatebounddata');
								},
            				error : function (jqXHR, textStatus, error) {
          				   	handleFail(jqXHR,textStatus,error,"removing row from result set");
									commit(false);
            				}
         				});
						} 
					};
				} else { 
					search = 
					{
						datatype: "json",
						datafields:
						[
							{name: 'GUID', type: 'string' }
								,{name: 'COLLECTION', type: 'string' }
								,{name: 'CAT_NUM', type: 'string' }
								,{name: 'CAT_NUM_INTEGER', type: 'number' }
								,{name: 'CAT_NUM_PREFIX', type: 'string' }
								,{name: 'COLLECTION_OBJECT_ID', type: 'string' }
								,{name: 'DEACCESSIONED', type: 'string' }
								,{name: 'TOPTYPESTATUSKIND', type: 'string' }
								,{name: 'COLL_OBJ_DISPOSITION', type: 'string' }
								,{name: 'ACCESSION', type: 'string' }
								,{name: 'ORIG_LAT_LONG_UNITS', type: 'string' }
								,{name: 'TOPTYPESTATUS', type: 'string' }
								,{name: 'LAT_LONG_DETERMINER', type: 'string' }
								,{name: 'LAT_LONG_REF_SOURCE', type: 'string' }
								,{name: 'TYPESTATUS', type: 'string' }
								,{name: 'LAT_LONG_REMARKS', type: 'string' }
								,{name: 'TYPESTATUS_DISPLAY', type: 'string' }
								,{name: 'TYPESTATUSPLAIN', type: 'string' }
								,{name: 'ASSOCIATED_SPECIES', type: 'string' }
								,{name: 'MICROHABITAT', type: 'string' }
								,{name: 'MIN_ELEV_IN_M', type: 'string' }
								,{name: 'HABITAT_DESC', type: 'string' }
								,{name: 'MAX_ELEV_IN_M', type: 'string' }
								,{name: 'MINIMUM_ELEVATION', type: 'string' }
								,{name: 'MAXIMUM_ELEVATION', type: 'string' }
								,{name: 'ORIG_ELEV_UNITS', type: 'string' }
								,{name: 'SPEC_LOCALITY', type: 'string' }
								,{name: 'SCI_NAME_WITH_AUTH', type: 'string' }
								,{name: 'IDENTIFIED_BY', type: 'string' }
								,{name: 'SCIENTIFIC_NAME', type: 'string' }
								,{name: 'IDENTIFIEDBY', type: 'string' }
								,{name: 'AUTHOR_TEXT', type: 'string' }
								,{name: 'SCI_NAME_WITH_AUTH_PLAIN', type: 'string' }
								,{name: 'ID_SENSU', type: 'string' }
								,{name: 'REMARKS', type: 'string' }
								,{name: 'COLLECTORS', type: 'string' }
								,{name: 'BEGAN_DATE', type: 'string' }
								,{name: 'ENDED_DATE', type: 'string' }
								,{name: 'COLLECTING_METHOD', type: 'string' }
								,{name: 'DEC_LAT', type: 'string' }
								,{name: 'DEC_LONG', type: 'string' }
								,{name: 'DATUM', type: 'string' }
								,{name: 'COORDINATEUNCERTAINTYINMETERS', type: 'string' }
								,{name: 'GEOREFMETHOD', type: 'string' }
								,{name: 'SEX', type: 'string' }
								,{name: 'MIN_DEPTH', type: 'string' }
								,{name: 'MAX_DEPTH', type: 'string' }
								,{name: 'AGE', type: 'string' }
								,{name: 'DEPTH_UNITS', type: 'string' }
								,{name: 'AGE_CLASS', type: 'string' }
								,{name: 'PREPARATORS', type: 'string' }
								,{name: 'ASSOCIATEDSEQUENCES', type: 'string' }
								,{name: 'PARTS', type: 'string' }
								,{name: 'PARTDETAIL', type: 'string' }
								,{name: 'TOTAL_PARTS', type: 'string' }
								,{name: 'GENBANKNUM', type: 'string' }
								,{name: 'COLLECTING_SOURCE', type: 'string' }
								,{name: 'VERIFICATIONSTATUS', type: 'string' }
								,{name: 'LOCALITY_REMARKS', type: 'string' }
								,{name: 'CONTINENT_OCEAN', type: 'string' }
								,{name: 'TYPESTATUSWORDS', type: 'string' }
								,{name: 'CONTINENT', type: 'string' }
								,{name: 'COUNTRY', type: 'string' }
								,{name: 'SOVEREIGN_NATION', type: 'string' }
								,{name: 'COUNTRYCODE', type: 'string' }
								,{name: 'STATE_PROV', type: 'string' }
								,{name: 'SEA', type: 'string' }
								,{name: 'FEATURE', type: 'string' }
								,{name: 'COUNTY', type: 'string' }
								,{name: 'ISLAND_GROUP', type: 'string' }
								,{name: 'QUAD', type: 'string' }
								,{name: 'ISLAND', type: 'string' }
								,{name: 'WATER_FEATURE', type: 'string' }
								,{name: 'WATERBODY', type: 'string' }
								,{name: 'HIGHER_GEOG', type: 'string' }
								,{name: 'VERBATIMLONGITUDE', type: 'string' }
								,{name: 'VERBATIMLOCALITY', type: 'string' }
								,{name: 'VERBATIMLATITUDE', type: 'string' }
								,{name: 'VERBATIMELEVATION', type: 'string' }
								,{name: 'LONGITUDE_AS_ENTERED', type: 'string' }
								,{name: 'COLLECTING_TIME', type: 'string' }
								,{name: 'DATE_EMERGED', type: 'string' }
								,{name: 'CITED_AS', type: 'string' }
								,{name: 'DATE_COLLECTED', type: 'string' }
								,{name: 'VERBATIM_DATE', type: 'string' }
								,{name: 'ISO_BEGAN_DATE', type: 'string' }
								,{name: 'ISO_ENDED_DATE', type: 'string' }
								,{name: 'KINGDOM', type: 'string' }
								,{name: 'PHYLUM', type: 'string' }
								,{name: 'PHYLCLASS', type: 'string' }
								,{name: 'PHYLORDER', type: 'string' }
								,{name: 'FAMILY', type: 'string' }
								,{name: 'TRIBE', type: 'string' }
								,{name: 'SUBPHYLIM', type: 'string' }
								,{name: 'SUBCLASS', type: 'string' }
								,{name: 'INFRACLASS', type: 'string' }
								,{name: 'SUPERORDER', type: 'string' }
								,{name: 'SUBORDER', type: 'string' }
								,{name: 'INFRAORDER', type: 'string' }
								,{name: 'SUPERFAMILY', type: 'string' }
								,{name: 'SUBFAMILY', type: 'string' }
								,{name: 'GENUS', type: 'string' }
								,{name: 'SPECIES', type: 'string' }
								,{name: 'SUBSPECIES', type: 'string' }
								,{name: 'INFRASPECIFIC_RANK', type: 'string' }
								,{name: 'UNNAMED_FORM', type: 'string' }
								,{name: 'NOMENCLATURAL_CODE', type: 'string' }
								,{name: 'IDENTIFICATION_REMARKS', type: 'string' }
								,{name: 'TAXONID', type: 'string' }
								,{name: 'SCIENTIFICNAMEID', type: 'string' }
								,{name: 'CITATIONS', type: 'string' }
								,{name: 'MADE_DATE', type: 'string' }
								,{name: 'FULL_TAXONOMY', type: 'string' }
								,{name: 'ON_LOAN', type: 'string' }
								,{name: 'PARTS_ON_LOAN', type: 'string' }
								,{name: 'CLOSED_LOANS', type: 'string' }
								,{name: 'ACCESSION_RESTRICTIONS', type: 'number' }
								,{name: 'ACCESSION_BENEFITS', type: 'number' }
								,{name: 'RECEIVED_FROM', type: 'string' }
								,{name: 'ACCESSION_DATE', type: 'string' }
								,{name: 'RECEIVED_DATE', type: 'string' }
								,{name: 'ROOMS', type: 'string' }
								,{name: 'CABINETS', type: 'string' }
								,{name: 'DRAWERS', type: 'string' }
								,{name: 'STORED_AS', type: 'string' }
								,{name: 'ENCUMBRANCES', type: 'string' }
								,{name: 'GEOL_GROUP', type: 'string' }
								,{name: 'FORMATION', type: 'string' }
								,{name: 'MEMBER', type: 'string' }
								,{name: 'BED', type: 'string' }
								,{name: 'LATESTERAORHIGHESTERATHEM', type: 'string' }
								,{name: 'LATITUDE_AS_ENTERED', type: 'string' }
								,{name: 'EARLIESTERAORLOWESTERATHEM', type: 'string' }
								,{name: 'LATESTPERIODORHIGHESTSYSTEM', type: 'string' }
								,{name: 'EARLIESTPERIODORLOWESTSYSTEM', type: 'string' }
								,{name: 'EARLIESTEPOCHORLOWESTSERIES', type: 'string' }
								,{name: 'LATESTAGEORHIGHESTSTAGE', type: 'string' }
								,{name: 'EARLIESTAGEORLOWESTSTAGE', type: 'string' }
								,{name: 'LATESTEPOCHORHIGHESTSERIES', type: 'string' }
								,{name: 'EARLIESTEONORLOWESTEONOTHEM', type: 'string' }
								,{name: 'LATESTEONORHIGHESTEONOTHEM', type: 'string' }
								,{name: 'LITHOSTRATIGRAPHICTERMS', type: 'string' }
								,{name: 'RELATEDCATALOGEDITEMS', type: 'string' }
								,{name: 'MEDIA', type: 'string' }
								,{name: 'COLLECTION_CDE', type: 'string' }
								,{name: 'ASSOCIATED_GRANT', type: 'string' }
								,{name: 'ASSOCIATED_MCZ_COLLECTION', type: 'string' }
								,{name: 'ABNORMALITY', type: 'string' }
								,{name: 'ASSOCIATED_TAXON', type: 'string' }
								,{name: 'BARE_PARTS_COLORATION', type: 'string' }
								,{name: 'BODY_LENGTH', type: 'string' }
								,{name: 'CITATION', type: 'string' }
								,{name: 'COLORS', type: 'string' }
								,{name: 'CROWN_RUMP_LENGTH', type: 'string' }
								,{name: 'DIAMETER', type: 'string' }
								,{name: 'DISK_LENGTH', type: 'string' }
								,{name: 'DISK_WIDTH', type: 'string' }
								,{name: 'EAR_FROM_NOTCH', type: 'string' }
								,{name: 'EXTENT', type: 'string' }
								,{name: 'FAT_DEPOSITION', type: 'string' }
								,{name: 'FOREARM_LENGTH', type: 'string' }
								,{name: 'FORK_LENGTH', type: 'string' }
								,{name: 'FOSSIL_MEASUREMENT', type: 'string' }
								,{name: 'HEAD_LENGTH', type: 'string' }
								,{name: 'HEIGHT', type: 'string' }
								,{name: 'HIND_FOOT_WITH_CLAW', type: 'string' }
								,{name: 'HOST', type: 'string' }
								,{name: 'INCUBATION', type: 'string' }
								,{name: 'LENGTH', type: 'string' }
								,{name: 'LIFE_CYCLE_STAGE', type: 'string' }
								,{name: 'LIFE_STAGE', type: 'string' }
								,{name: 'MAX_DISPLAY_ANGLE', type: 'string' }
								,{name: 'MOLT_CONDITION', type: 'string' }
								,{name: 'NUMERIC_AGE', type: 'string' }
								,{name: 'OSSIFICATION', type: 'string' }
								,{name: 'PLUMAGE_COLORATION', type: 'string' }
								,{name: 'PLUMAGE_DESCRIPTION', type: 'string' }
								,{name: 'REFERENCE', type: 'string' }
								,{name: 'REPRODUCTIVE_CONDITION', type: 'string' }
								,{name: 'REPRODUCTIVE_DATA', type: 'string' }
								,{name: 'SECTION_LENGTH', type: 'string' }
								,{name: 'SECTION_STAIN', type: 'string' }
								,{name: 'SIZE_FISH', type: 'string' }
								,{name: 'SNOUT_VENT_LENGTH', type: 'string' }
								,{name: 'SPECIMEN_LENGTH', type: 'string' }
								,{name: 'STAGE_DESCRIPTION', type: 'string' }
								,{name: 'STANDARD_LENGTH', type: 'string' }
								,{name: 'STOMACH_CONTENTS', type: 'string' }
								,{name: 'STORAGE', type: 'string' }
								,{name: 'TAIL_LENGTH', type: 'string' }
								,{name: 'TEMPERATURE_EXPERIMENT', type: 'string' }
								,{name: 'TOTAL_LENGTH', type: 'string' }
								,{name: 'TOTAL_SIZE', type: 'string' }
								,{name: 'TRAGUS_LENGTH', type: 'string' }
								,{name: 'UNFORMATTED_MEASUREMENTS', type: 'string' }
								,{name: 'UNSPECIFIED_MEASUREMENT', type: 'string' }
								,{name: 'WEIGHT', type: 'string' }
								,{name: 'WIDTH', type: 'string' }
								,{name: 'WING_CHORD', type: 'string' }
								,{name: 'LOCALITY_ID', type: 'number' }
								,{name: 'COLLECTING_EVENT_ID', type: 'number' }
								,{name: 'INSTITUTION_ACRONYM', type: 'string' }
								,{name: 'LAST_EDIT_DATE', type: 'string' }
								,{name: 'CUSTOMID', type: 'string' }
								,{name: 'MYCUSTOMIDTYPE', type: 'string' }
								,{name: 'OTHERCATALOGNUMBERS', type: 'string' }
								
						],
						beforeprocessing: function (data) {
							if (data != null && data.length > 0) {
								search.totalrecords = data[0].recordcount;
							}
						},
						sort: function () {
							$("#fixedsearchResultsGrid").jqxGrid('updatebounddata','sort');
						},
						root: 'specimenRecord',
						id: 'collection_object_id',
						url: '/specimens/component/search.cfc?' + $('#fixedSearchForm').serialize(),
						timeout: 120000,  // units not specified, miliseconds?  Fixed
						loadError: function(jqXHR, textStatus, error) {
							handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
						},
						async: true,
						deleterow: function (rowid, commit) {
							console.log(rowid);
							console.log($('#fixedsearchResultsGrid').jqxGrid('getRowData',rowid));
							var collobjtoremove = $('#fixedsearchResultsGrid').jqxGrid('getRowData',rowid)['COLLECTION_OBJECT_ID'];
							console.log(collobjtoremove);
		        			$.ajax({
            				url: "/specimens/component/search.cfc",
            				data: { 
									method: 'removeItemFromResult', 
									result_id: $('#result_id_fixedSearch').val(),
									collection_object_id: collobjtoremove
								},
								dataType: 'json',
           					success : function (data) { 
									console.log(data);
									commit(true);
									$('#fixedsearchResultsGrid').jqxGrid('updatebounddata');
								},
            				error : function (jqXHR, textStatus, error) {
          				   	handleFail(jqXHR,textStatus,error,"removing row from result set");
									commit(false);
            				}
         				});
						} 
					};
				};
	

				var dataAdapter = new $.jqx.dataAdapter(search);
				var initRowDetails = function (index, parentElement, gridElement, datarecord) {
					// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
					var details = $($(parentElement).children()[0]);
					console.log(index);
					details.html("<div id='fixedrowDetailsTarget" + index + "'></div>");
					createSpecimenRowDetailsDialog('fixedsearchResultsGrid','fixedrowDetailsTarget',datarecord,index);
					// Workaround, expansion sits below row in zindex.
					var maxZIndex = getMaxZIndex();
					$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
				}

	
				$("#fixedsearchResultsGrid").jqxGrid({
					width: '100%',
					autoheight: 'true',
					source: dataAdapter,
					filterable: false,
					sortable: true,
					pageable: true,
					editable: false,
					virtualmode: true,
					enablemousewheel: true,
					keyboardnavigation: true,
					pagesize: '25',
					pagesizeoptions: ['5','10','25','50','100','500'], // fixed list regardless of actual result set size, dynamic reset goes into infinite loop.
					showaggregates: true,
					columnsresize: true,
					autoshowfiltericon: true,
					autoshowcolumnsmenubutton: false,
					autoshowloadelement: false,  // overlay acts as load element for form+results
					columnsreorder: true,
					groupable: true,
					selectionmode: 'singlecell',
					//enablebrowserselection: true,
					altrows: true,
					showtoolbar: false,
//					ready: function () {
//						$("#fixedsearchResultsGrid").jqxGrid('selectrow', 0);
//						$("#fixedsearchResultsGrid").jqxGrid('focus');
//					},
					rendergridrows: function () {
						return dataAdapter.records;
					},
					columns: [
						{text: 'Remove', datafield: 'RemoveRow', cellsrenderer:removeFixedCellRenderer, width: 40, cellclassname: fixedcellclass, hidable:false, hidden: false },  
								{text: 'GUID', datafield: 'GUID', cellsrenderer:fixed_GuidCellRenderer, width: 155, cellclassname: fixedcellclass, hidable:false, hidden: getColHidProp('GUID', false) },
							 
								{text: 'Collection', datafield: 'COLLECTION', width: 150, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COLLECTION', false) },
							 
								{text: 'Catalog Number', datafield: 'CAT_NUM', width: 130, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CAT_NUM', false) },
							 
								{text: 'Catalog Number Integer Part', datafield: 'CAT_NUM_INTEGER', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CAT_NUM_INTEGER', true) },
							 
								{text: 'Catalog Number Prefix', datafield: 'CAT_NUM_PREFIX', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CAT_NUM_PREFIX', true) },
							 
								{text: 'InternalCollObjectID', datafield: 'COLLECTION_OBJECT_ID', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COLLECTION_OBJECT_ID', true) },
							 
								{text: 'Deaccessioned', datafield: 'DEACCESSIONED', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DEACCESSIONED', false) },
							 
								{text: 'Top Type Status Kind', datafield: 'TOPTYPESTATUSKIND', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TOPTYPESTATUSKIND', true) },
							 
								{text: 'Coll Obj Disposition', datafield: 'COLL_OBJ_DISPOSITION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COLL_OBJ_DISPOSITION', true) },
							 
								{text: 'Accession', datafield: 'ACCESSION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ACCESSION', true) },
							 
								{text: 'Orig Lat Long Units', datafield: 'ORIG_LAT_LONG_UNITS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ORIG_LAT_LONG_UNITS', true) },
							 
								{text: 'Top Type Status', datafield: 'TOPTYPESTATUS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TOPTYPESTATUS', false) },
							 
								{text: 'Lat Long Determiner', datafield: 'LAT_LONG_DETERMINER', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LAT_LONG_DETERMINER', true) },
							 
								{text: 'Lat Long Ref Source', datafield: 'LAT_LONG_REF_SOURCE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LAT_LONG_REF_SOURCE', true) },
							 
								{text: 'Type Status', datafield: 'TYPESTATUS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TYPESTATUS', true) },
							 
								{text: 'Lat Long Remarks', datafield: 'LAT_LONG_REMARKS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LAT_LONG_REMARKS', true) },
							 
								{text: 'Type Status Display', datafield: 'TYPESTATUS_DISPLAY', width: 160, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TYPESTATUS_DISPLAY', true) },
							 
								{text: 'Type Status Plain', datafield: 'TYPESTATUSPLAIN', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TYPESTATUSPLAIN', true) },
							 
								{text: 'Associated Species', datafield: 'ASSOCIATED_SPECIES', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_SPECIES', true) },
							 
								{text: 'Microhabitat', datafield: 'MICROHABITAT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MICROHABITAT', true) },
							 
								{text: 'Min Elev In m', datafield: 'MIN_ELEV_IN_M', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MIN_ELEV_IN_M', true) },
							 
								{text: 'Habitat', datafield: 'HABITAT_DESC', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('HABITAT_DESC', true) },
							 
								{text: 'Max Elev In m', datafield: 'MAX_ELEV_IN_M', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MAX_ELEV_IN_M', true) },
							 
								{text: 'Minimum Elevation', datafield: 'MINIMUM_ELEVATION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MINIMUM_ELEVATION', true) },
							 
								{text: 'Maximum Elevation', datafield: 'MAXIMUM_ELEVATION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MAXIMUM_ELEVATION', true) },
							 
								{text: 'Orig Elev Units', datafield: 'ORIG_ELEV_UNITS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ORIG_ELEV_UNITS', true) },
							 
								{text: 'Specific Locality', datafield: 'SPEC_LOCALITY', width: 280, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SPEC_LOCALITY', false) },
							 
								{text: 'Sci Name With Auth', datafield: 'SCI_NAME_WITH_AUTH', cellsrenderer:fixed_sciNameCellRenderer, width: 250, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SCI_NAME_WITH_AUTH', false) },
							 
								{text: 'Identified By', datafield: 'IDENTIFIED_BY', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('IDENTIFIED_BY', true) },
							 
								{text: 'Scientific Name', datafield: 'SCIENTIFIC_NAME', cellsrenderer:linkTaxonCellRenderer, width: 250, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SCIENTIFIC_NAME', true) },
							 
								{text: 'Identified By', datafield: 'IDENTIFIEDBY', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('IDENTIFIEDBY', true) },
							 
								{text: 'Authorship', datafield: 'AUTHOR_TEXT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('AUTHOR_TEXT', true) },
							 
								{text: 'dwc:scientificName', datafield: 'SCI_NAME_WITH_AUTH_PLAIN', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SCI_NAME_WITH_AUTH_PLAIN', true) },
							 
								{text: 'Id Sensu', datafield: 'ID_SENSU', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ID_SENSU', true) },
							 
								{text: 'Remarks', datafield: 'REMARKS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('REMARKS', true) },
							 
								{text: 'Collectors', datafield: 'COLLECTORS', width: 180, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COLLECTORS', false) },
							 
								{text: 'Began Date', datafield: 'BEGAN_DATE', filtertype: 'date', width: 115, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('BEGAN_DATE', false) },
							 
								{text: 'Ended Date', datafield: 'ENDED_DATE', filtertype: 'date', width: 115, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ENDED_DATE', false) },
							 
								{text: 'Collecting Method', datafield: 'COLLECTING_METHOD', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COLLECTING_METHOD', true) },
							 
								{text: 'Dec Lat', datafield: 'DEC_LAT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DEC_LAT', true) },
							 
								{text: 'Dec Long', datafield: 'DEC_LONG', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DEC_LONG', true) },
							 
								{text: 'Datum', datafield: 'DATUM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DATUM', true) },
							 
								{text: 'Coordinate uncertainty m', datafield: 'COORDINATEUNCERTAINTYINMETERS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COORDINATEUNCERTAINTYINMETERS', true) },
							 
								{text: 'Georef Method', datafield: 'GEOREFMETHOD', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('GEOREFMETHOD', true) },
							 
								{text: 'Sex', datafield: 'SEX', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SEX', true) },
							 
								{text: 'Min Depth', datafield: 'MIN_DEPTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MIN_DEPTH', true) },
							 
								{text: 'Max Depth', datafield: 'MAX_DEPTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MAX_DEPTH', true) },
							 
								{text: 'Age', datafield: 'AGE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('AGE', true) },
							 
								{text: 'Depth Units', datafield: 'DEPTH_UNITS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DEPTH_UNITS', true) },
							 
								{text: 'Age Class', datafield: 'AGE_CLASS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('AGE_CLASS', true) },
							 
								{text: 'Preparators', datafield: 'PREPARATORS', width: 180, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('PREPARATORS', true) },
							 
								{text: 'Associated Sequences', datafield: 'ASSOCIATEDSEQUENCES', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ASSOCIATEDSEQUENCES', true) },
							 
								{text: 'Parts', datafield: 'PARTS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('PARTS', true) },
							 
								{text: 'Part Detail', datafield: 'PARTDETAIL', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('PARTDETAIL', true) },
							 
								{text: 'Total Parts', datafield: 'TOTAL_PARTS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TOTAL_PARTS', true) },
							 
								{text: 'Genbank Num', datafield: 'GENBANKNUM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('GENBANKNUM', true) },
							 
								{text: 'Collecting Source', datafield: 'COLLECTING_SOURCE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COLLECTING_SOURCE', true) },
							 
								{text: 'Verification Status', datafield: 'VERIFICATIONSTATUS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('VERIFICATIONSTATUS', true) },
							 
								{text: 'Locality Remarks', datafield: 'LOCALITY_REMARKS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LOCALITY_REMARKS', true) },
							 
								{text: 'Continent/Ocean', datafield: 'CONTINENT_OCEAN', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CONTINENT_OCEAN', true) },
							 
								{text: 'Type Status Words', datafield: 'TYPESTATUSWORDS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TYPESTATUSWORDS', true) },
							 
								{text: 'Continent', datafield: 'CONTINENT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CONTINENT', true) },
							 
								{text: 'Country', datafield: 'COUNTRY', width: 110, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COUNTRY', false) },
							 
								{text: 'Sovereign Nation', datafield: 'SOVEREIGN_NATION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SOVEREIGN_NATION', true) },
							 
								{text: 'Country Code', datafield: 'COUNTRYCODE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COUNTRYCODE', true) },
							 
								{text: 'State/Province', datafield: 'STATE_PROV', width: 120, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('STATE_PROV', false) },
							 
								{text: 'Sea', datafield: 'SEA', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SEA', true) },
							 
								{text: 'Feature', datafield: 'FEATURE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('FEATURE', true) },
							 
								{text: 'County', datafield: 'COUNTY', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COUNTY', true) },
							 
								{text: 'Island Group', datafield: 'ISLAND_GROUP', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ISLAND_GROUP', true) },
							 
								{text: 'Quad', datafield: 'QUAD', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('QUAD', true) },
							 
								{text: 'Island', datafield: 'ISLAND', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ISLAND', true) },
							 
								{text: 'Water Feature', datafield: 'WATER_FEATURE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('WATER_FEATURE', true) },
							 
								{text: 'Waterbody', datafield: 'WATERBODY', width: 150, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('WATERBODY', false) },
							 
								{text: 'Concatenated Higher Geography', datafield: 'HIGHER_GEOG', width: 200, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('HIGHER_GEOG', true) },
							 
								{text: 'Verbatim Longitude', datafield: 'VERBATIMLONGITUDE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('VERBATIMLONGITUDE', true) },
							 
								{text: 'Verbatim Locality', datafield: 'VERBATIMLOCALITY', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('VERBATIMLOCALITY', true) },
							 
								{text: 'Verbatim Latitude', datafield: 'VERBATIMLATITUDE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('VERBATIMLATITUDE', true) },
							 
								{text: 'Verbatim Elevation', datafield: 'VERBATIMELEVATION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('VERBATIMELEVATION', true) },
							 
								{text: 'Longitude as entered', datafield: 'LONGITUDE_AS_ENTERED', width: 120, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LONGITUDE_AS_ENTERED', true) },
							 
								{text: 'Collecting Time', datafield: 'COLLECTING_TIME', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COLLECTING_TIME', true) },
							 
								{text: 'Date Emerged', datafield: 'DATE_EMERGED', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DATE_EMERGED', true) },
							 
								{text: 'Cited As', datafield: 'CITED_AS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CITED_AS', true) },
							 
								{text: 'Date Collected', datafield: 'DATE_COLLECTED', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DATE_COLLECTED', true) },
							 
								{text: 'Verbatim Date', datafield: 'VERBATIM_DATE', width: 190, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('VERBATIM_DATE', false) },
							 
								{text: 'Iso Began Date', datafield: 'ISO_BEGAN_DATE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ISO_BEGAN_DATE', true) },
							 
								{text: 'Iso Ended Date', datafield: 'ISO_ENDED_DATE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ISO_ENDED_DATE', true) },
							 
								{text: 'Kingdom', datafield: 'KINGDOM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('KINGDOM', true) },
							 
								{text: 'Phylum', datafield: 'PHYLUM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('PHYLUM', true) },
							 
								{text: 'Class', datafield: 'PHYLCLASS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('PHYLCLASS', true) },
							 
								{text: 'Order', datafield: 'PHYLORDER', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('PHYLORDER', true) },
							 
								{text: 'Family', datafield: 'FAMILY', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('FAMILY', true) },
							 
								{text: 'Tribe', datafield: 'TRIBE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TRIBE', true) },
							 
								{text: 'Subphylum', datafield: 'SUBPHYLIM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SUBPHYLIM', true) },
							 
								{text: 'Subclass', datafield: 'SUBCLASS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SUBCLASS', true) },
							 
								{text: 'Infraclass', datafield: 'INFRACLASS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('INFRACLASS', true) },
							 
								{text: 'Superorder', datafield: 'SUPERORDER', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SUPERORDER', true) },
							 
								{text: 'Suborder', datafield: 'SUBORDER', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SUBORDER', true) },
							 
								{text: 'Infraorder', datafield: 'INFRAORDER', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('INFRAORDER', true) },
							 
								{text: 'superfamily', datafield: 'SUPERFAMILY', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SUPERFAMILY', true) },
							 
								{text: 'Subfamily', datafield: 'SUBFAMILY', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SUBFAMILY', true) },
							 
								{text: 'Genus', datafield: 'GENUS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('GENUS', true) },
							 
								{text: 'Species', datafield: 'SPECIES', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SPECIES', true) },
							 
								{text: 'Subspecies', datafield: 'SUBSPECIES', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SUBSPECIES', true) },
							 
								{text: 'Infraspecific Rank', datafield: 'INFRASPECIFIC_RANK', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('INFRASPECIFIC_RANK', true) },
							 
								{text: 'Unnamed Form', datafield: 'UNNAMED_FORM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('UNNAMED_FORM', true) },
							 
								{text: 'Nomenclatural Code', datafield: 'NOMENCLATURAL_CODE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('NOMENCLATURAL_CODE', true) },
							 
								{text: 'Identification Remarks', datafield: 'IDENTIFICATION_REMARKS', width: 200, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('IDENTIFICATION_REMARKS', true) },
							 
								{text: 'dwc:Taxonid', datafield: 'TAXONID', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TAXONID', true) },
							 
								{text: 'dwc:Scientificnameid', datafield: 'SCIENTIFICNAMEID', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SCIENTIFICNAMEID', true) },
							 
								{text: 'Citations', datafield: 'CITATIONS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CITATIONS', true) },
							 
								{text: 'Made Date', datafield: 'MADE_DATE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MADE_DATE', true) },
							 
								{text: 'Concatenated Taxonomy', datafield: 'FULL_TAXONOMY', width: 200, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('FULL_TAXONOMY', true) },
							 
								{text: 'On Loan', datafield: 'ON_LOAN', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ON_LOAN', true) },
							 
								{text: 'Parts On Loan', datafield: 'PARTS_ON_LOAN', width: 120, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('PARTS_ON_LOAN', true) },
							 
								{text: 'Closed Loans', datafield: 'CLOSED_LOANS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CLOSED_LOANS', true) },
							 
								{text: 'Accession has restrictions', datafield: 'ACCESSION_RESTRICTIONS', cellsrenderer:yesBlankFlagRenderer, width: 80, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ACCESSION_RESTRICTIONS', true) },
							 
								{text: 'Accession requires benefits', datafield: 'ACCESSION_BENEFITS', cellsrenderer:yesBlankFlagRenderer, width: 80, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ACCESSION_BENEFITS', true) },
							 
								{text: 'Received From', datafield: 'RECEIVED_FROM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('RECEIVED_FROM', true) },
							 
								{text: 'Accession Date', datafield: 'ACCESSION_DATE', filtertype: 'date', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ACCESSION_DATE', true) },
							 
								{text: 'Received  Date', datafield: 'RECEIVED_DATE', filtertype: 'date', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('RECEIVED_DATE', true) },
							 
								{text: 'Rooms', datafield: 'ROOMS', width: 120, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ROOMS', true) },
							 
								{text: 'FIxture/Freezer/Cryovat', datafield: 'CABINETS', width: 120, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CABINETS', true) },
							 
								{text: 'Compartment/Freezer Rack', datafield: 'DRAWERS', width: 150, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DRAWERS', true) },
							 
								{text: 'Stored As', datafield: 'STORED_AS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('STORED_AS', true) },
							 
								{text: 'Encumbrances', datafield: 'ENCUMBRANCES', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ENCUMBRANCES', true) },
							 
								{text: 'Group', datafield: 'GEOL_GROUP', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('GEOL_GROUP', true) },
							 
								{text: 'Formation', datafield: 'FORMATION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('FORMATION', true) },
							 
								{text: 'Member', datafield: 'MEMBER', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MEMBER', true) },
							 
								{text: 'Bed', datafield: 'BED', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('BED', true) },
							 
								{text: 'Latest Era', datafield: 'LATESTERAORHIGHESTERATHEM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LATESTERAORHIGHESTERATHEM', true) },
							 
								{text: 'Latitude as entered', datafield: 'LATITUDE_AS_ENTERED', width: 120, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LATITUDE_AS_ENTERED', true) },
							 
								{text: 'Earliest Era', datafield: 'EARLIESTERAORLOWESTERATHEM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('EARLIESTERAORLOWESTERATHEM', true) },
							 
								{text: 'Latest Period', datafield: 'LATESTPERIODORHIGHESTSYSTEM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LATESTPERIODORHIGHESTSYSTEM', true) },
							 
								{text: 'Earliest Period', datafield: 'EARLIESTPERIODORLOWESTSYSTEM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('EARLIESTPERIODORLOWESTSYSTEM', true) },
							 
								{text: 'Earliest Epoch', datafield: 'EARLIESTEPOCHORLOWESTSERIES', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('EARLIESTEPOCHORLOWESTSERIES', true) },
							 
								{text: 'Latest Age', datafield: 'LATESTAGEORHIGHESTSTAGE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LATESTAGEORHIGHESTSTAGE', true) },
							 
								{text: 'Earliest Age', datafield: 'EARLIESTAGEORLOWESTSTAGE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('EARLIESTAGEORLOWESTSTAGE', true) },
							 
								{text: 'Latest Epoch', datafield: 'LATESTEPOCHORHIGHESTSERIES', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LATESTEPOCHORHIGHESTSERIES', true) },
							 
								{text: 'Earliest Eon', datafield: 'EARLIESTEONORLOWESTEONOTHEM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('EARLIESTEONORLOWESTEONOTHEM', true) },
							 
								{text: 'Latest Eon', datafield: 'LATESTEONORHIGHESTEONOTHEM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LATESTEONORHIGHESTEONOTHEM', true) },
							 
								{text: 'Lithostratigraphic Terms', datafield: 'LITHOSTRATIGRAPHICTERMS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LITHOSTRATIGRAPHICTERMS', true) },
							 
								{text: 'Related Cataloged Items', datafield: 'RELATEDCATALOGEDITEMS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('RELATEDCATALOGEDITEMS', true) },
							 
								{text: 'Media', datafield: 'MEDIA', cellsrenderer:fixed_mediaCellRenderer, width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MEDIA', true) },
							 
								{text: 'Collection Code', datafield: 'COLLECTION_CDE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COLLECTION_CDE', true) },
							 
								{text: 'Associated Grant', datafield: 'ASSOCIATED_GRANT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_GRANT', true) },
							 
								{text: 'Associated MCZ Collection', datafield: 'ASSOCIATED_MCZ_COLLECTION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_MCZ_COLLECTION', true) },
							 
								{text: 'Abnormality', datafield: 'ABNORMALITY', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ABNORMALITY', true) },
							 
								{text: 'Associated Taxon', datafield: 'ASSOCIATED_TAXON', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_TAXON', true) },
							 
								{text: 'Bare Parts Coloration', datafield: 'BARE_PARTS_COLORATION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('BARE_PARTS_COLORATION', true) },
							 
								{text: 'Body Length', datafield: 'BODY_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('BODY_LENGTH', true) },
							 
								{text: 'Citation (Attribute)', datafield: 'CITATION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CITATION', true) },
							 
								{text: 'Colors', datafield: 'COLORS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COLORS', true) },
							 
								{text: 'Crown Rump Length', datafield: 'CROWN_RUMP_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CROWN_RUMP_LENGTH', true) },
							 
								{text: 'Diameter', datafield: 'DIAMETER', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DIAMETER', true) },
							 
								{text: 'Disk Length', datafield: 'DISK_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DISK_LENGTH', true) },
							 
								{text: 'Disk Width', datafield: 'DISK_WIDTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('DISK_WIDTH', true) },
							 
								{text: 'Ear From Notch', datafield: 'EAR_FROM_NOTCH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('EAR_FROM_NOTCH', true) },
							 
								{text: 'Extent', datafield: 'EXTENT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('EXTENT', true) },
							 
								{text: 'Fat Deposition', datafield: 'FAT_DEPOSITION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('FAT_DEPOSITION', true) },
							 
								{text: 'Forearm Length', datafield: 'FOREARM_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('FOREARM_LENGTH', true) },
							 
								{text: 'Fork Length', datafield: 'FORK_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('FORK_LENGTH', true) },
							 
								{text: 'Fossil Measurement', datafield: 'FOSSIL_MEASUREMENT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('FOSSIL_MEASUREMENT', true) },
							 
								{text: 'Head Length', datafield: 'HEAD_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('HEAD_LENGTH', true) },
							 
								{text: 'Height', datafield: 'HEIGHT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('HEIGHT', true) },
							 
								{text: 'Hind Foot With Claw', datafield: 'HIND_FOOT_WITH_CLAW', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('HIND_FOOT_WITH_CLAW', true) },
							 
								{text: 'Host', datafield: 'HOST', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('HOST', true) },
							 
								{text: 'Incubation', datafield: 'INCUBATION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('INCUBATION', true) },
							 
								{text: 'Length', datafield: 'LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LENGTH', true) },
							 
								{text: 'Life Cycle Stage', datafield: 'LIFE_CYCLE_STAGE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LIFE_CYCLE_STAGE', true) },
							 
								{text: 'Life Stage', datafield: 'LIFE_STAGE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LIFE_STAGE', true) },
							 
								{text: 'Max Display Angle', datafield: 'MAX_DISPLAY_ANGLE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MAX_DISPLAY_ANGLE', true) },
							 
								{text: 'Molt Condition', datafield: 'MOLT_CONDITION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MOLT_CONDITION', true) },
							 
								{text: 'Numeric Age', datafield: 'NUMERIC_AGE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('NUMERIC_AGE', true) },
							 
								{text: 'Ossification', datafield: 'OSSIFICATION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('OSSIFICATION', true) },
							 
								{text: 'Plumage Coloration', datafield: 'PLUMAGE_COLORATION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('PLUMAGE_COLORATION', true) },
							 
								{text: 'Plumage Description', datafield: 'PLUMAGE_DESCRIPTION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('PLUMAGE_DESCRIPTION', true) },
							 
								{text: 'Reference', datafield: 'REFERENCE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('REFERENCE', true) },
							 
								{text: 'Reproductive Condition', datafield: 'REPRODUCTIVE_CONDITION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('REPRODUCTIVE_CONDITION', true) },
							 
								{text: 'Reproductive Data', datafield: 'REPRODUCTIVE_DATA', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('REPRODUCTIVE_DATA', true) },
							 
								{text: 'Section Length', datafield: 'SECTION_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SECTION_LENGTH', true) },
							 
								{text: 'Section Stain', datafield: 'SECTION_STAIN', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SECTION_STAIN', true) },
							 
								{text: 'Size Fish', datafield: 'SIZE_FISH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SIZE_FISH', true) },
							 
								{text: 'Snout Vent Length', datafield: 'SNOUT_VENT_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SNOUT_VENT_LENGTH', true) },
							 
								{text: 'Specimen Length', datafield: 'SPECIMEN_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('SPECIMEN_LENGTH', true) },
							 
								{text: 'Stage Description', datafield: 'STAGE_DESCRIPTION', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('STAGE_DESCRIPTION', true) },
							 
								{text: 'Standard Length', datafield: 'STANDARD_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('STANDARD_LENGTH', true) },
							 
								{text: 'Stomach Contents', datafield: 'STOMACH_CONTENTS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('STOMACH_CONTENTS', true) },
							 
								{text: 'Storage', datafield: 'STORAGE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('STORAGE', true) },
							 
								{text: 'Tail Length', datafield: 'TAIL_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TAIL_LENGTH', true) },
							 
								{text: 'Temperature Experiment', datafield: 'TEMPERATURE_EXPERIMENT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TEMPERATURE_EXPERIMENT', true) },
							 
								{text: 'Total Length', datafield: 'TOTAL_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TOTAL_LENGTH', true) },
							 
								{text: 'Total Size', datafield: 'TOTAL_SIZE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TOTAL_SIZE', true) },
							 
								{text: 'Tragus Length', datafield: 'TRAGUS_LENGTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('TRAGUS_LENGTH', true) },
							 
								{text: 'Unformatted Measurements', datafield: 'UNFORMATTED_MEASUREMENTS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('UNFORMATTED_MEASUREMENTS', true) },
							 
								{text: 'Unspecified Measurement', datafield: 'UNSPECIFIED_MEASUREMENT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('UNSPECIFIED_MEASUREMENT', true) },
							 
								{text: 'Weight', datafield: 'WEIGHT', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('WEIGHT', true) },
							 
								{text: 'Width', datafield: 'WIDTH', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('WIDTH', true) },
							 
								{text: 'Wing Chord', datafield: 'WING_CHORD', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('WING_CHORD', true) },
							 
								{text: 'Locality_ID', datafield: 'LOCALITY_ID', width: 80, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LOCALITY_ID', true) },
							 
								{text: 'collecting_event_id', datafield: 'COLLECTING_EVENT_ID', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('COLLECTING_EVENT_ID', true) },
							 
								{text: 'Institution Acronym', datafield: 'INSTITUTION_ACRONYM', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('INSTITUTION_ACRONYM', true) },
							 
								{text: 'dwc:modified', datafield: 'LAST_EDIT_DATE', filtertype: 'date', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('LAST_EDIT_DATE', true) },
							 
								{text: 'Custom Id', datafield: 'CUSTOMID', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('CUSTOMID', true) },
							 
								{text: 'My Customid Type', datafield: 'MYCUSTOMIDTYPE', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('MYCUSTOMIDTYPE', true) },
							{text: 'Other IDs', datafield: 'OTHERCATALOGNUMBERS', width: 100, cellclassname: fixedcellclass, hidable:true, hidden: getColHidProp('OTHERCATALOGNUMBERS', false), editable: false }
					],
					
					rowdetails: true,
					rowdetailstemplate: {
						rowdetails: "<div style='margin: 10px;'>Row Details</div>",
						rowdetailsheight:  1 // row details will be placed in popup dialog
					},
					initrowdetails: initRowDetails
				});
				$('#fixedsearchResultsGrid').attr('tabindex', 0);
				
				$('#fixedsearchResultsGrid').jqxGrid().on("columnreordered", function (event) { 
						columnOrderChanged('fixedsearchResultsGrid'); 
					}); 
				
				
				$("#fixedsearchResultsGrid").on("bindingcomplete", function(event) {
					setTimeout(function() {
						selectFirstCell();
					}, 100);
					
						$("#fixedsearchResultsGrid").attr('tabindex', 0);

						// Set all interactive descendants to non-tabbable
						$("#fixedsearchResultsGrid").find('a, button, input').attr('tabindex', -1);

						var columns = $("#fixedsearchResultsGrid").jqxGrid('columns').records;
						if (columns && columns.length > 0) {
							$("#fixedsearchResultsGrid").jqxGrid('selectcell', 0, columns[0].datafield);
						}
						$("#fixedsearchResultsGrid").focus();

						// The rest of your existing logic...
						$("#fixedsearchResultsGrid").on('focusin', function(event) {
							// Check if any cell is already selected
							var selection = $("#fixedsearchResultsGrid").jqxGrid('getselectedcell');
							if (!selection || typeof selection.rowindex === "undefined" || !selection.datafield) {
								var columns = $("#fixedsearchResultsGrid").jqxGrid('columns').records;
								if (columns && columns.length > 0) {
									$("#fixedsearchResultsGrid").jqxGrid('selectcell', 0, columns[0].datafield);
								}
							}
						});
					
					
						if (document <= 900){
							$(document).scrollTop(200);
						} else {
							$(document).scrollTop(480);
						}
					
			
					// add a link out to this search, serializing the form as http get parameters
					$('#fixedresultLink').html('<a href="/Specimens.cfm?execute=true&' + $('#fixedSearchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize() + '">Link to this search</a>');
					$('#fixedshowhide').html('<button class="my-2 border rounded" title="hide search form" onclick=" toggleSearchForm(\'fixed\'); "><i id="fixedSearchFormToggleIcon" class="fas fa-eye-slash"></i></button>');
					if (fixedSearchLoaded==0) { 
						try { 
							gridLoaded('fixedsearchResultsGrid','occurrence record','fixed');
						} catch (e) { 
							console.log(e);
							messageDialog("Error in gridLoaded handler:" + e.message,"Error in gridLoaded");
						}
						fixedSearchLoaded = 1;
						loadColumnOrder('fixedsearchResultsGrid');
					}
					
						$('#fixedmanageButton').html('<a href="specimens/manageSpecimens.cfm?result_id='+$('#result_id_fixedSearch').val()+'" target="_blank" class="btn btn-xs btn-secondary px-2 my-2 mx-1" >Manage</a>');
					
					pageLoaded('fixedsearchResultsGrid','occurrence record','fixed');
					 
						console.log(1);
						setPinColumnState('fixedsearchResultsGrid','GUID',true);
					
				});
				function selectFirstCell() {
    var grid = $('#fixedsearchResultsGrid');
    var cell = grid.jqxGrid('getselectedcell');
    if (
      !cell ||
      typeof cell.rowindex === 'undefined' ||
      cell.datafield === undefined
    ) {
        var columns = grid.jqxGrid('columns').records;
        if (columns.length) {
            grid.jqxGrid('selectcell', 0, columns[0].datafield);
        }
    }
}
				
				$('#fixedsearchResultsGrid').on('rowexpand', function (event) {
					//  Create a content div, add it to the detail row, and make it into a dialog.
					var args = event.args;
					var rowIndex = args.rowindex;
					var datarecord = args.owner.source.records[rowIndex];
					console.log(rowIndex);
					createSpecimenRowDetailsDialog('fixedsearchResultsGrid','fixedrowDetailsTarget',datarecord,rowIndex);
				});
				$('#fixedsearchResultsGrid').on('rowcollapse', function (event) {
					// remove the dialog holding the row details
					var args = event.args;
					var rowIndex = args.rowindex;
					$("#fixedsearchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
				});
				// display selected row index.
				$("#fixedsearchResultsGrid").on('rowselect', function (event) {
					$("#fixedselectrowindex").text(event.args.rowindex);
				});
				// display unselected row index.
				$("#fixedsearchResultsGrid").on('rowunselect', function (event) {
					$("#fixedunselectrowindex").text(event.args.rowindex);
				});
			});
			/* End Setup jqxgrid for fixed Search ****************************************************************************************/
	 
			
			/* Setup jqxgrid for keyword Search */
			$('#keywordSearchForm').bind('submit', function(evt){ 
				evt.preventDefault();
				
				var uuid = getVersion4UUID();
				$("#result_id_keywordSearch").val(uuid);
				
					if (Object.keys(window.columnHiddenSettings).length == 0) {
						lookupColumnVisibilities ('/Specimens.cfm','Default');
					}
				

				keywordSearchLoaded = 0;

				$("#overlay").show();
				$("#collapseKeyword").collapse("hide");  // hide the help text if it is visible.
				$("#keywordsearchResultsGrid").replaceWith('<div id="keywordsearchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
				$("#keywordresultCount").html("");
				$("#keywordresultLink").html("");
				$("#keywordshowhide").html("");
				$('#keywordmanageButton').html('');
				$('#keywordremoveButtonDiv').html('');
				$('#keywordsaveDialogButton').html('');
				$('#keywordactionFeedback').html('');
				$('#keywordselectModeContainer').hide();
				$('#keywordPostGridControls').hide();
				var debug = $("#keywordSearchForm").serialize();
				console.log(debug);
		
				var search =
				{
					datatype: "json",
					datafields:
					[
						{name: 'GUID', type: 'string' }
							,{name: 'COLLECTION', type: 'string' }
							,{name: 'CAT_NUM', type: 'string' }
							,{name: 'CAT_NUM_INTEGER', type: 'number' }
							,{name: 'CAT_NUM_PREFIX', type: 'string' }
							,{name: 'COLLECTION_OBJECT_ID', type: 'string' }
							,{name: 'DEACCESSIONED', type: 'string' }
							,{name: 'TOPTYPESTATUSKIND', type: 'string' }
							,{name: 'COLL_OBJ_DISPOSITION', type: 'string' }
							,{name: 'ACCESSION', type: 'string' }
							,{name: 'ORIG_LAT_LONG_UNITS', type: 'string' }
							,{name: 'TOPTYPESTATUS', type: 'string' }
							,{name: 'LAT_LONG_DETERMINER', type: 'string' }
							,{name: 'LAT_LONG_REF_SOURCE', type: 'string' }
							,{name: 'TYPESTATUS', type: 'string' }
							,{name: 'LAT_LONG_REMARKS', type: 'string' }
							,{name: 'TYPESTATUS_DISPLAY', type: 'string' }
							,{name: 'TYPESTATUSPLAIN', type: 'string' }
							,{name: 'ASSOCIATED_SPECIES', type: 'string' }
							,{name: 'MICROHABITAT', type: 'string' }
							,{name: 'MIN_ELEV_IN_M', type: 'string' }
							,{name: 'HABITAT_DESC', type: 'string' }
							,{name: 'MAX_ELEV_IN_M', type: 'string' }
							,{name: 'MINIMUM_ELEVATION', type: 'string' }
							,{name: 'MAXIMUM_ELEVATION', type: 'string' }
							,{name: 'ORIG_ELEV_UNITS', type: 'string' }
							,{name: 'SPEC_LOCALITY', type: 'string' }
							,{name: 'SCI_NAME_WITH_AUTH', type: 'string' }
							,{name: 'IDENTIFIED_BY', type: 'string' }
							,{name: 'SCIENTIFIC_NAME', type: 'string' }
							,{name: 'IDENTIFIEDBY', type: 'string' }
							,{name: 'AUTHOR_TEXT', type: 'string' }
							,{name: 'SCI_NAME_WITH_AUTH_PLAIN', type: 'string' }
							,{name: 'ID_SENSU', type: 'string' }
							,{name: 'REMARKS', type: 'string' }
							,{name: 'COLLECTORS', type: 'string' }
							,{name: 'BEGAN_DATE', type: 'string' }
							,{name: 'ENDED_DATE', type: 'string' }
							,{name: 'COLLECTING_METHOD', type: 'string' }
							,{name: 'DEC_LAT', type: 'string' }
							,{name: 'DEC_LONG', type: 'string' }
							,{name: 'DATUM', type: 'string' }
							,{name: 'COORDINATEUNCERTAINTYINMETERS', type: 'string' }
							,{name: 'GEOREFMETHOD', type: 'string' }
							,{name: 'SEX', type: 'string' }
							,{name: 'MIN_DEPTH', type: 'string' }
							,{name: 'MAX_DEPTH', type: 'string' }
							,{name: 'AGE', type: 'string' }
							,{name: 'DEPTH_UNITS', type: 'string' }
							,{name: 'AGE_CLASS', type: 'string' }
							,{name: 'PREPARATORS', type: 'string' }
							,{name: 'ASSOCIATEDSEQUENCES', type: 'string' }
							,{name: 'PARTS', type: 'string' }
							,{name: 'PARTDETAIL', type: 'string' }
							,{name: 'TOTAL_PARTS', type: 'string' }
							,{name: 'GENBANKNUM', type: 'string' }
							,{name: 'COLLECTING_SOURCE', type: 'string' }
							,{name: 'VERIFICATIONSTATUS', type: 'string' }
							,{name: 'LOCALITY_REMARKS', type: 'string' }
							,{name: 'CONTINENT_OCEAN', type: 'string' }
							,{name: 'TYPESTATUSWORDS', type: 'string' }
							,{name: 'CONTINENT', type: 'string' }
							,{name: 'COUNTRY', type: 'string' }
							,{name: 'SOVEREIGN_NATION', type: 'string' }
							,{name: 'COUNTRYCODE', type: 'string' }
							,{name: 'STATE_PROV', type: 'string' }
							,{name: 'SEA', type: 'string' }
							,{name: 'FEATURE', type: 'string' }
							,{name: 'COUNTY', type: 'string' }
							,{name: 'ISLAND_GROUP', type: 'string' }
							,{name: 'QUAD', type: 'string' }
							,{name: 'ISLAND', type: 'string' }
							,{name: 'WATER_FEATURE', type: 'string' }
							,{name: 'WATERBODY', type: 'string' }
							,{name: 'HIGHER_GEOG', type: 'string' }
							,{name: 'VERBATIMLONGITUDE', type: 'string' }
							,{name: 'VERBATIMLOCALITY', type: 'string' }
							,{name: 'VERBATIMLATITUDE', type: 'string' }
							,{name: 'VERBATIMELEVATION', type: 'string' }
							,{name: 'LONGITUDE_AS_ENTERED', type: 'string' }
							,{name: 'COLLECTING_TIME', type: 'string' }
							,{name: 'DATE_EMERGED', type: 'string' }
							,{name: 'CITED_AS', type: 'string' }
							,{name: 'DATE_COLLECTED', type: 'string' }
							,{name: 'VERBATIM_DATE', type: 'string' }
							,{name: 'ISO_BEGAN_DATE', type: 'string' }
							,{name: 'ISO_ENDED_DATE', type: 'string' }
							,{name: 'KINGDOM', type: 'string' }
							,{name: 'PHYLUM', type: 'string' }
							,{name: 'PHYLCLASS', type: 'string' }
							,{name: 'PHYLORDER', type: 'string' }
							,{name: 'FAMILY', type: 'string' }
							,{name: 'TRIBE', type: 'string' }
							,{name: 'SUBPHYLIM', type: 'string' }
							,{name: 'SUBCLASS', type: 'string' }
							,{name: 'INFRACLASS', type: 'string' }
							,{name: 'SUPERORDER', type: 'string' }
							,{name: 'SUBORDER', type: 'string' }
							,{name: 'INFRAORDER', type: 'string' }
							,{name: 'SUPERFAMILY', type: 'string' }
							,{name: 'SUBFAMILY', type: 'string' }
							,{name: 'GENUS', type: 'string' }
							,{name: 'SPECIES', type: 'string' }
							,{name: 'SUBSPECIES', type: 'string' }
							,{name: 'INFRASPECIFIC_RANK', type: 'string' }
							,{name: 'UNNAMED_FORM', type: 'string' }
							,{name: 'NOMENCLATURAL_CODE', type: 'string' }
							,{name: 'IDENTIFICATION_REMARKS', type: 'string' }
							,{name: 'TAXONID', type: 'string' }
							,{name: 'SCIENTIFICNAMEID', type: 'string' }
							,{name: 'CITATIONS', type: 'string' }
							,{name: 'MADE_DATE', type: 'string' }
							,{name: 'FULL_TAXONOMY', type: 'string' }
							,{name: 'ON_LOAN', type: 'string' }
							,{name: 'PARTS_ON_LOAN', type: 'string' }
							,{name: 'CLOSED_LOANS', type: 'string' }
							,{name: 'ACCESSION_RESTRICTIONS', type: 'number' }
							,{name: 'ACCESSION_BENEFITS', type: 'number' }
							,{name: 'RECEIVED_FROM', type: 'string' }
							,{name: 'ACCESSION_DATE', type: 'string' }
							,{name: 'RECEIVED_DATE', type: 'string' }
							,{name: 'ROOMS', type: 'string' }
							,{name: 'CABINETS', type: 'string' }
							,{name: 'DRAWERS', type: 'string' }
							,{name: 'STORED_AS', type: 'string' }
							,{name: 'ENCUMBRANCES', type: 'string' }
							,{name: 'GEOL_GROUP', type: 'string' }
							,{name: 'FORMATION', type: 'string' }
							,{name: 'MEMBER', type: 'string' }
							,{name: 'BED', type: 'string' }
							,{name: 'LATESTERAORHIGHESTERATHEM', type: 'string' }
							,{name: 'LATITUDE_AS_ENTERED', type: 'string' }
							,{name: 'EARLIESTERAORLOWESTERATHEM', type: 'string' }
							,{name: 'LATESTPERIODORHIGHESTSYSTEM', type: 'string' }
							,{name: 'EARLIESTPERIODORLOWESTSYSTEM', type: 'string' }
							,{name: 'EARLIESTEPOCHORLOWESTSERIES', type: 'string' }
							,{name: 'LATESTAGEORHIGHESTSTAGE', type: 'string' }
							,{name: 'EARLIESTAGEORLOWESTSTAGE', type: 'string' }
							,{name: 'LATESTEPOCHORHIGHESTSERIES', type: 'string' }
							,{name: 'EARLIESTEONORLOWESTEONOTHEM', type: 'string' }
							,{name: 'LATESTEONORHIGHESTEONOTHEM', type: 'string' }
							,{name: 'LITHOSTRATIGRAPHICTERMS', type: 'string' }
							,{name: 'RELATEDCATALOGEDITEMS', type: 'string' }
							,{name: 'MEDIA', type: 'string' }
							,{name: 'COLLECTION_CDE', type: 'string' }
							,{name: 'ASSOCIATED_GRANT', type: 'string' }
							,{name: 'ASSOCIATED_MCZ_COLLECTION', type: 'string' }
							,{name: 'ABNORMALITY', type: 'string' }
							,{name: 'ASSOCIATED_TAXON', type: 'string' }
							,{name: 'BARE_PARTS_COLORATION', type: 'string' }
							,{name: 'BODY_LENGTH', type: 'string' }
							,{name: 'CITATION', type: 'string' }
							,{name: 'COLORS', type: 'string' }
							,{name: 'CROWN_RUMP_LENGTH', type: 'string' }
							,{name: 'DIAMETER', type: 'string' }
							,{name: 'DISK_LENGTH', type: 'string' }
							,{name: 'DISK_WIDTH', type: 'string' }
							,{name: 'EAR_FROM_NOTCH', type: 'string' }
							,{name: 'EXTENT', type: 'string' }
							,{name: 'FAT_DEPOSITION', type: 'string' }
							,{name: 'FOREARM_LENGTH', type: 'string' }
							,{name: 'FORK_LENGTH', type: 'string' }
							,{name: 'FOSSIL_MEASUREMENT', type: 'string' }
							,{name: 'HEAD_LENGTH', type: 'string' }
							,{name: 'HEIGHT', type: 'string' }
							,{name: 'HIND_FOOT_WITH_CLAW', type: 'string' }
							,{name: 'HOST', type: 'string' }
							,{name: 'INCUBATION', type: 'string' }
							,{name: 'LENGTH', type: 'string' }
							,{name: 'LIFE_CYCLE_STAGE', type: 'string' }
							,{name: 'LIFE_STAGE', type: 'string' }
							,{name: 'MAX_DISPLAY_ANGLE', type: 'string' }
							,{name: 'MOLT_CONDITION', type: 'string' }
							,{name: 'NUMERIC_AGE', type: 'string' }
							,{name: 'OSSIFICATION', type: 'string' }
							,{name: 'PLUMAGE_COLORATION', type: 'string' }
							,{name: 'PLUMAGE_DESCRIPTION', type: 'string' }
							,{name: 'REFERENCE', type: 'string' }
							,{name: 'REPRODUCTIVE_CONDITION', type: 'string' }
							,{name: 'REPRODUCTIVE_DATA', type: 'string' }
							,{name: 'SECTION_LENGTH', type: 'string' }
							,{name: 'SECTION_STAIN', type: 'string' }
							,{name: 'SIZE_FISH', type: 'string' }
							,{name: 'SNOUT_VENT_LENGTH', type: 'string' }
							,{name: 'SPECIMEN_LENGTH', type: 'string' }
							,{name: 'STAGE_DESCRIPTION', type: 'string' }
							,{name: 'STANDARD_LENGTH', type: 'string' }
							,{name: 'STOMACH_CONTENTS', type: 'string' }
							,{name: 'STORAGE', type: 'string' }
							,{name: 'TAIL_LENGTH', type: 'string' }
							,{name: 'TEMPERATURE_EXPERIMENT', type: 'string' }
							,{name: 'TOTAL_LENGTH', type: 'string' }
							,{name: 'TOTAL_SIZE', type: 'string' }
							,{name: 'TRAGUS_LENGTH', type: 'string' }
							,{name: 'UNFORMATTED_MEASUREMENTS', type: 'string' }
							,{name: 'UNSPECIFIED_MEASUREMENT', type: 'string' }
							,{name: 'WEIGHT', type: 'string' }
							,{name: 'WIDTH', type: 'string' }
							,{name: 'WING_CHORD', type: 'string' }
							,{name: 'LOCALITY_ID', type: 'number' }
							,{name: 'COLLECTING_EVENT_ID', type: 'number' }
							,{name: 'INSTITUTION_ACRONYM', type: 'string' }
							,{name: 'LAST_EDIT_DATE', type: 'string' }
							,{name: 'CUSTOMID', type: 'string' }
							,{name: 'MYCUSTOMIDTYPE', type: 'string' }
							,{name: 'OTHERCATALOGNUMBERS', type: 'string' }
							
					],
					beforeprocessing: function (data) {
						if (data != null && data.length > 0) {
							search.totalrecords = data[0].recordcount;
						}
					},
					sort: function () {
						$("#keywordsearchResultsGrid").jqxGrid('updatebounddata','sort');
					},
					root: 'specimenRecord',
					id: 'collection_object_id',
					url: '/specimens/component/search.cfc?' + $("#keywordSearchForm").serialize(),
					timeout: 60000,  // units not specified, miliseconds?  Keyword
					loadError: function(jqXHR, textStatus, error) {
						handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
					},
					async: true,
					deleterow: function (rowid, commit) {
						console.log(rowid);
						console.log($('#keywordsearchResultsGrid').jqxGrid('getRowData',rowid));
						var collobjtoremove = $('#keywordsearchResultsGrid').jqxGrid('getRowData',rowid)['COLLECTION_OBJECT_ID'];
						console.log(collobjtoremove);
	        			$.ajax({
            				url: "/specimens/component/search.cfc",
            				data: { 
								method: 'removeItemFromResult', 
								result_id: $('#result_id_keywordSearch').val(),
								collection_object_id: collobjtoremove
							},
							dataType: 'json',
           					success : function (data) { 
								console.log(data);
								commit(true);
								$('#keywordsearchResultsGrid').jqxGrid('updatebounddata');
							},
            				error : function (jqXHR, textStatus, error) {
          				   	handleFail(jqXHR,textStatus,error,"removing row from result set");
								commit(false);
            				}
         			});
					} 
				};	
	
				var dataAdapter = new $.jqx.dataAdapter(search);
				var initRowDetails = function (index, parentElement, gridElement, datarecord) {
					// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
					var details = $($(parentElement).children()[0]);
					console.log(index);
					details.html("<div id='keywordrowDetailsTarget" + index + "'></div>");
					createSpecimenRowDetailsDialog('keywordsearchResultsGrid','keywordrowDetailsTarget',datarecord,index);
					// Workaround, expansion sits below row in zindex.
					var maxZIndex = getMaxZIndex();
					$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
				}
		
				$("#keywordsearchResultsGrid").jqxGrid({
					width: '100%',
					autoheight: 'true',
					source: dataAdapter,
					filterable: false,  // turned off, will be difficult to support with server side paging of resultset
					sortable: true,
					pageable: true,
					editable: false,
					virtualmode: true,
					enablemousewheel: true,
					pagesize: '25',
					pagesizeoptions: ['5','10','25','50','100','500'], // fixed list regardless of actual result set size, dynamic reset goes into infinite loop.
					showaggregates: true,
					columnsresize: true,
					autoshowfiltericon: true,
					autoshowcolumnsmenubutton: false,
					autoshowloadelement: false,  // overlay acts as load element for form+results
					columnsreorder: true,
					groupable: true,
					selectionmode: 'none',
					enablebrowserselection: true,
					altrows: true,
					showtoolbar: false,
					ready: function () {
						$("#keywordsearchResultsGrid").jqxGrid('selectrow', 0);
					},
					rendergridrows: function () {
						return dataAdapter.records;
					},
					columns: [
						{text: 'Remove', datafield: 'RemoveRow', cellsrenderer:removeKeywordCellRenderer, width: 40, cellclassname: fixedcellclass, hidable:false, hidden: false },  
								{text: 'GUID', datafield: 'GUID', cellsrenderer:keyword_GuidCellRenderer, width: 155, cellclassname: keywordcellclass, hidable:false, hidden: getColHidProp('GUID', false) },
							 
								{text: 'Collection', datafield: 'COLLECTION', width: 150, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COLLECTION', false) },
							 
								{text: 'Catalog Number', datafield: 'CAT_NUM', width: 130, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CAT_NUM', false) },
							 
								{text: 'Catalog Number Integer Part', datafield: 'CAT_NUM_INTEGER', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CAT_NUM_INTEGER', true) },
							 
								{text: 'Catalog Number Prefix', datafield: 'CAT_NUM_PREFIX', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CAT_NUM_PREFIX', true) },
							 
								{text: 'InternalCollObjectID', datafield: 'COLLECTION_OBJECT_ID', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COLLECTION_OBJECT_ID', true) },
							 
								{text: 'Deaccessioned', datafield: 'DEACCESSIONED', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DEACCESSIONED', false) },
							 
								{text: 'Top Type Status Kind', datafield: 'TOPTYPESTATUSKIND', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TOPTYPESTATUSKIND', true) },
							 
								{text: 'Coll Obj Disposition', datafield: 'COLL_OBJ_DISPOSITION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COLL_OBJ_DISPOSITION', true) },
							 
								{text: 'Accession', datafield: 'ACCESSION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ACCESSION', true) },
							 
								{text: 'Orig Lat Long Units', datafield: 'ORIG_LAT_LONG_UNITS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ORIG_LAT_LONG_UNITS', true) },
							 
								{text: 'Top Type Status', datafield: 'TOPTYPESTATUS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TOPTYPESTATUS', false) },
							 
								{text: 'Lat Long Determiner', datafield: 'LAT_LONG_DETERMINER', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LAT_LONG_DETERMINER', true) },
							 
								{text: 'Lat Long Ref Source', datafield: 'LAT_LONG_REF_SOURCE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LAT_LONG_REF_SOURCE', true) },
							 
								{text: 'Type Status', datafield: 'TYPESTATUS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TYPESTATUS', true) },
							 
								{text: 'Lat Long Remarks', datafield: 'LAT_LONG_REMARKS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LAT_LONG_REMARKS', true) },
							 
								{text: 'Type Status Display', datafield: 'TYPESTATUS_DISPLAY', width: 160, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TYPESTATUS_DISPLAY', true) },
							 
								{text: 'Type Status Plain', datafield: 'TYPESTATUSPLAIN', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TYPESTATUSPLAIN', true) },
							 
								{text: 'Associated Species', datafield: 'ASSOCIATED_SPECIES', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_SPECIES', true) },
							 
								{text: 'Microhabitat', datafield: 'MICROHABITAT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MICROHABITAT', true) },
							 
								{text: 'Min Elev In m', datafield: 'MIN_ELEV_IN_M', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MIN_ELEV_IN_M', true) },
							 
								{text: 'Habitat', datafield: 'HABITAT_DESC', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('HABITAT_DESC', true) },
							 
								{text: 'Max Elev In m', datafield: 'MAX_ELEV_IN_M', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MAX_ELEV_IN_M', true) },
							 
								{text: 'Minimum Elevation', datafield: 'MINIMUM_ELEVATION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MINIMUM_ELEVATION', true) },
							 
								{text: 'Maximum Elevation', datafield: 'MAXIMUM_ELEVATION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MAXIMUM_ELEVATION', true) },
							 
								{text: 'Orig Elev Units', datafield: 'ORIG_ELEV_UNITS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ORIG_ELEV_UNITS', true) },
							 
								{text: 'Specific Locality', datafield: 'SPEC_LOCALITY', width: 280, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SPEC_LOCALITY', false) },
							 
								{text: 'Sci Name With Auth', datafield: 'SCI_NAME_WITH_AUTH', cellsrenderer:keyword_sciNameCellRenderer, width: 250, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SCI_NAME_WITH_AUTH', false) },
							 
								{text: 'Identified By', datafield: 'IDENTIFIED_BY', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('IDENTIFIED_BY', true) },
							 
								{text: 'Scientific Name', datafield: 'SCIENTIFIC_NAME', cellsrenderer:linkTaxonCellRenderer, width: 250, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SCIENTIFIC_NAME', true) },
							 
								{text: 'Identified By', datafield: 'IDENTIFIEDBY', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('IDENTIFIEDBY', true) },
							 
								{text: 'Authorship', datafield: 'AUTHOR_TEXT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('AUTHOR_TEXT', true) },
							 
								{text: 'dwc:scientificName', datafield: 'SCI_NAME_WITH_AUTH_PLAIN', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SCI_NAME_WITH_AUTH_PLAIN', true) },
							 
								{text: 'Id Sensu', datafield: 'ID_SENSU', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ID_SENSU', true) },
							 
								{text: 'Remarks', datafield: 'REMARKS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('REMARKS', true) },
							 
								{text: 'Collectors', datafield: 'COLLECTORS', width: 180, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COLLECTORS', false) },
							 
								{text: 'Began Date', datafield: 'BEGAN_DATE', filtertype: 'date', width: 115, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('BEGAN_DATE', false) },
							 
								{text: 'Ended Date', datafield: 'ENDED_DATE', filtertype: 'date', width: 115, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ENDED_DATE', false) },
							 
								{text: 'Collecting Method', datafield: 'COLLECTING_METHOD', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COLLECTING_METHOD', true) },
							 
								{text: 'Dec Lat', datafield: 'DEC_LAT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DEC_LAT', true) },
							 
								{text: 'Dec Long', datafield: 'DEC_LONG', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DEC_LONG', true) },
							 
								{text: 'Datum', datafield: 'DATUM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DATUM', true) },
							 
								{text: 'Coordinate uncertainty m', datafield: 'COORDINATEUNCERTAINTYINMETERS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COORDINATEUNCERTAINTYINMETERS', true) },
							 
								{text: 'Georef Method', datafield: 'GEOREFMETHOD', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('GEOREFMETHOD', true) },
							 
								{text: 'Sex', datafield: 'SEX', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SEX', true) },
							 
								{text: 'Min Depth', datafield: 'MIN_DEPTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MIN_DEPTH', true) },
							 
								{text: 'Max Depth', datafield: 'MAX_DEPTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MAX_DEPTH', true) },
							 
								{text: 'Age', datafield: 'AGE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('AGE', true) },
							 
								{text: 'Depth Units', datafield: 'DEPTH_UNITS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DEPTH_UNITS', true) },
							 
								{text: 'Age Class', datafield: 'AGE_CLASS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('AGE_CLASS', true) },
							 
								{text: 'Preparators', datafield: 'PREPARATORS', width: 180, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('PREPARATORS', true) },
							 
								{text: 'Associated Sequences', datafield: 'ASSOCIATEDSEQUENCES', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ASSOCIATEDSEQUENCES', true) },
							 
								{text: 'Parts', datafield: 'PARTS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('PARTS', true) },
							 
								{text: 'Part Detail', datafield: 'PARTDETAIL', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('PARTDETAIL', true) },
							 
								{text: 'Total Parts', datafield: 'TOTAL_PARTS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TOTAL_PARTS', true) },
							 
								{text: 'Genbank Num', datafield: 'GENBANKNUM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('GENBANKNUM', true) },
							 
								{text: 'Collecting Source', datafield: 'COLLECTING_SOURCE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COLLECTING_SOURCE', true) },
							 
								{text: 'Verification Status', datafield: 'VERIFICATIONSTATUS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('VERIFICATIONSTATUS', true) },
							 
								{text: 'Locality Remarks', datafield: 'LOCALITY_REMARKS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LOCALITY_REMARKS', true) },
							 
								{text: 'Continent/Ocean', datafield: 'CONTINENT_OCEAN', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CONTINENT_OCEAN', true) },
							 
								{text: 'Type Status Words', datafield: 'TYPESTATUSWORDS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TYPESTATUSWORDS', true) },
							 
								{text: 'Continent', datafield: 'CONTINENT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CONTINENT', true) },
							 
								{text: 'Country', datafield: 'COUNTRY', width: 110, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COUNTRY', false) },
							 
								{text: 'Sovereign Nation', datafield: 'SOVEREIGN_NATION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SOVEREIGN_NATION', true) },
							 
								{text: 'Country Code', datafield: 'COUNTRYCODE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COUNTRYCODE', true) },
							 
								{text: 'State/Province', datafield: 'STATE_PROV', width: 120, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('STATE_PROV', false) },
							 
								{text: 'Sea', datafield: 'SEA', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SEA', true) },
							 
								{text: 'Feature', datafield: 'FEATURE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('FEATURE', true) },
							 
								{text: 'County', datafield: 'COUNTY', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COUNTY', true) },
							 
								{text: 'Island Group', datafield: 'ISLAND_GROUP', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ISLAND_GROUP', true) },
							 
								{text: 'Quad', datafield: 'QUAD', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('QUAD', true) },
							 
								{text: 'Island', datafield: 'ISLAND', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ISLAND', true) },
							 
								{text: 'Water Feature', datafield: 'WATER_FEATURE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('WATER_FEATURE', true) },
							 
								{text: 'Waterbody', datafield: 'WATERBODY', width: 150, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('WATERBODY', false) },
							 
								{text: 'Concatenated Higher Geography', datafield: 'HIGHER_GEOG', width: 200, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('HIGHER_GEOG', true) },
							 
								{text: 'Verbatim Longitude', datafield: 'VERBATIMLONGITUDE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('VERBATIMLONGITUDE', true) },
							 
								{text: 'Verbatim Locality', datafield: 'VERBATIMLOCALITY', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('VERBATIMLOCALITY', true) },
							 
								{text: 'Verbatim Latitude', datafield: 'VERBATIMLATITUDE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('VERBATIMLATITUDE', true) },
							 
								{text: 'Verbatim Elevation', datafield: 'VERBATIMELEVATION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('VERBATIMELEVATION', true) },
							 
								{text: 'Longitude as entered', datafield: 'LONGITUDE_AS_ENTERED', width: 120, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LONGITUDE_AS_ENTERED', true) },
							 
								{text: 'Collecting Time', datafield: 'COLLECTING_TIME', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COLLECTING_TIME', true) },
							 
								{text: 'Date Emerged', datafield: 'DATE_EMERGED', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DATE_EMERGED', true) },
							 
								{text: 'Cited As', datafield: 'CITED_AS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CITED_AS', true) },
							 
								{text: 'Date Collected', datafield: 'DATE_COLLECTED', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DATE_COLLECTED', true) },
							 
								{text: 'Verbatim Date', datafield: 'VERBATIM_DATE', width: 190, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('VERBATIM_DATE', false) },
							 
								{text: 'Iso Began Date', datafield: 'ISO_BEGAN_DATE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ISO_BEGAN_DATE', true) },
							 
								{text: 'Iso Ended Date', datafield: 'ISO_ENDED_DATE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ISO_ENDED_DATE', true) },
							 
								{text: 'Kingdom', datafield: 'KINGDOM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('KINGDOM', true) },
							 
								{text: 'Phylum', datafield: 'PHYLUM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('PHYLUM', true) },
							 
								{text: 'Class', datafield: 'PHYLCLASS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('PHYLCLASS', true) },
							 
								{text: 'Order', datafield: 'PHYLORDER', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('PHYLORDER', true) },
							 
								{text: 'Family', datafield: 'FAMILY', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('FAMILY', true) },
							 
								{text: 'Tribe', datafield: 'TRIBE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TRIBE', true) },
							 
								{text: 'Subphylum', datafield: 'SUBPHYLIM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SUBPHYLIM', true) },
							 
								{text: 'Subclass', datafield: 'SUBCLASS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SUBCLASS', true) },
							 
								{text: 'Infraclass', datafield: 'INFRACLASS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('INFRACLASS', true) },
							 
								{text: 'Superorder', datafield: 'SUPERORDER', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SUPERORDER', true) },
							 
								{text: 'Suborder', datafield: 'SUBORDER', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SUBORDER', true) },
							 
								{text: 'Infraorder', datafield: 'INFRAORDER', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('INFRAORDER', true) },
							 
								{text: 'superfamily', datafield: 'SUPERFAMILY', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SUPERFAMILY', true) },
							 
								{text: 'Subfamily', datafield: 'SUBFAMILY', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SUBFAMILY', true) },
							 
								{text: 'Genus', datafield: 'GENUS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('GENUS', true) },
							 
								{text: 'Species', datafield: 'SPECIES', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SPECIES', true) },
							 
								{text: 'Subspecies', datafield: 'SUBSPECIES', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SUBSPECIES', true) },
							 
								{text: 'Infraspecific Rank', datafield: 'INFRASPECIFIC_RANK', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('INFRASPECIFIC_RANK', true) },
							 
								{text: 'Unnamed Form', datafield: 'UNNAMED_FORM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('UNNAMED_FORM', true) },
							 
								{text: 'Nomenclatural Code', datafield: 'NOMENCLATURAL_CODE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('NOMENCLATURAL_CODE', true) },
							 
								{text: 'Identification Remarks', datafield: 'IDENTIFICATION_REMARKS', width: 200, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('IDENTIFICATION_REMARKS', true) },
							 
								{text: 'dwc:Taxonid', datafield: 'TAXONID', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TAXONID', true) },
							 
								{text: 'dwc:Scientificnameid', datafield: 'SCIENTIFICNAMEID', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SCIENTIFICNAMEID', true) },
							 
								{text: 'Citations', datafield: 'CITATIONS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CITATIONS', true) },
							 
								{text: 'Made Date', datafield: 'MADE_DATE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MADE_DATE', true) },
							 
								{text: 'Concatenated Taxonomy', datafield: 'FULL_TAXONOMY', width: 200, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('FULL_TAXONOMY', true) },
							 
								{text: 'On Loan', datafield: 'ON_LOAN', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ON_LOAN', true) },
							 
								{text: 'Parts On Loan', datafield: 'PARTS_ON_LOAN', width: 120, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('PARTS_ON_LOAN', true) },
							 
								{text: 'Closed Loans', datafield: 'CLOSED_LOANS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CLOSED_LOANS', true) },
							 
								{text: 'Accession has restrictions', datafield: 'ACCESSION_RESTRICTIONS', cellsrenderer:yesBlankFlagRenderer, width: 80, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ACCESSION_RESTRICTIONS', true) },
							 
								{text: 'Accession requires benefits', datafield: 'ACCESSION_BENEFITS', cellsrenderer:yesBlankFlagRenderer, width: 80, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ACCESSION_BENEFITS', true) },
							 
								{text: 'Received From', datafield: 'RECEIVED_FROM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('RECEIVED_FROM', true) },
							 
								{text: 'Accession Date', datafield: 'ACCESSION_DATE', filtertype: 'date', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ACCESSION_DATE', true) },
							 
								{text: 'Received  Date', datafield: 'RECEIVED_DATE', filtertype: 'date', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('RECEIVED_DATE', true) },
							 
								{text: 'Rooms', datafield: 'ROOMS', width: 120, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ROOMS', true) },
							 
								{text: 'FIxture/Freezer/Cryovat', datafield: 'CABINETS', width: 120, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CABINETS', true) },
							 
								{text: 'Compartment/Freezer Rack', datafield: 'DRAWERS', width: 150, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DRAWERS', true) },
							 
								{text: 'Stored As', datafield: 'STORED_AS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('STORED_AS', true) },
							 
								{text: 'Encumbrances', datafield: 'ENCUMBRANCES', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ENCUMBRANCES', true) },
							 
								{text: 'Group', datafield: 'GEOL_GROUP', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('GEOL_GROUP', true) },
							 
								{text: 'Formation', datafield: 'FORMATION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('FORMATION', true) },
							 
								{text: 'Member', datafield: 'MEMBER', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MEMBER', true) },
							 
								{text: 'Bed', datafield: 'BED', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('BED', true) },
							 
								{text: 'Latest Era', datafield: 'LATESTERAORHIGHESTERATHEM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LATESTERAORHIGHESTERATHEM', true) },
							 
								{text: 'Latitude as entered', datafield: 'LATITUDE_AS_ENTERED', width: 120, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LATITUDE_AS_ENTERED', true) },
							 
								{text: 'Earliest Era', datafield: 'EARLIESTERAORLOWESTERATHEM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('EARLIESTERAORLOWESTERATHEM', true) },
							 
								{text: 'Latest Period', datafield: 'LATESTPERIODORHIGHESTSYSTEM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LATESTPERIODORHIGHESTSYSTEM', true) },
							 
								{text: 'Earliest Period', datafield: 'EARLIESTPERIODORLOWESTSYSTEM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('EARLIESTPERIODORLOWESTSYSTEM', true) },
							 
								{text: 'Earliest Epoch', datafield: 'EARLIESTEPOCHORLOWESTSERIES', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('EARLIESTEPOCHORLOWESTSERIES', true) },
							 
								{text: 'Latest Age', datafield: 'LATESTAGEORHIGHESTSTAGE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LATESTAGEORHIGHESTSTAGE', true) },
							 
								{text: 'Earliest Age', datafield: 'EARLIESTAGEORLOWESTSTAGE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('EARLIESTAGEORLOWESTSTAGE', true) },
							 
								{text: 'Latest Epoch', datafield: 'LATESTEPOCHORHIGHESTSERIES', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LATESTEPOCHORHIGHESTSERIES', true) },
							 
								{text: 'Earliest Eon', datafield: 'EARLIESTEONORLOWESTEONOTHEM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('EARLIESTEONORLOWESTEONOTHEM', true) },
							 
								{text: 'Latest Eon', datafield: 'LATESTEONORHIGHESTEONOTHEM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LATESTEONORHIGHESTEONOTHEM', true) },
							 
								{text: 'Lithostratigraphic Terms', datafield: 'LITHOSTRATIGRAPHICTERMS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LITHOSTRATIGRAPHICTERMS', true) },
							 
								{text: 'Related Cataloged Items', datafield: 'RELATEDCATALOGEDITEMS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('RELATEDCATALOGEDITEMS', true) },
							 
								{text: 'Media', datafield: 'MEDIA', cellsrenderer:keyword_mediaCellRenderer, width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MEDIA', true) },
							 
								{text: 'Collection Code', datafield: 'COLLECTION_CDE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COLLECTION_CDE', true) },
							 
								{text: 'Associated Grant', datafield: 'ASSOCIATED_GRANT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_GRANT', true) },
							 
								{text: 'Associated MCZ Collection', datafield: 'ASSOCIATED_MCZ_COLLECTION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_MCZ_COLLECTION', true) },
							 
								{text: 'Abnormality', datafield: 'ABNORMALITY', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ABNORMALITY', true) },
							 
								{text: 'Associated Taxon', datafield: 'ASSOCIATED_TAXON', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_TAXON', true) },
							 
								{text: 'Bare Parts Coloration', datafield: 'BARE_PARTS_COLORATION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('BARE_PARTS_COLORATION', true) },
							 
								{text: 'Body Length', datafield: 'BODY_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('BODY_LENGTH', true) },
							 
								{text: 'Citation (Attribute)', datafield: 'CITATION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CITATION', true) },
							 
								{text: 'Colors', datafield: 'COLORS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COLORS', true) },
							 
								{text: 'Crown Rump Length', datafield: 'CROWN_RUMP_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CROWN_RUMP_LENGTH', true) },
							 
								{text: 'Diameter', datafield: 'DIAMETER', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DIAMETER', true) },
							 
								{text: 'Disk Length', datafield: 'DISK_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DISK_LENGTH', true) },
							 
								{text: 'Disk Width', datafield: 'DISK_WIDTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('DISK_WIDTH', true) },
							 
								{text: 'Ear From Notch', datafield: 'EAR_FROM_NOTCH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('EAR_FROM_NOTCH', true) },
							 
								{text: 'Extent', datafield: 'EXTENT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('EXTENT', true) },
							 
								{text: 'Fat Deposition', datafield: 'FAT_DEPOSITION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('FAT_DEPOSITION', true) },
							 
								{text: 'Forearm Length', datafield: 'FOREARM_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('FOREARM_LENGTH', true) },
							 
								{text: 'Fork Length', datafield: 'FORK_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('FORK_LENGTH', true) },
							 
								{text: 'Fossil Measurement', datafield: 'FOSSIL_MEASUREMENT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('FOSSIL_MEASUREMENT', true) },
							 
								{text: 'Head Length', datafield: 'HEAD_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('HEAD_LENGTH', true) },
							 
								{text: 'Height', datafield: 'HEIGHT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('HEIGHT', true) },
							 
								{text: 'Hind Foot With Claw', datafield: 'HIND_FOOT_WITH_CLAW', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('HIND_FOOT_WITH_CLAW', true) },
							 
								{text: 'Host', datafield: 'HOST', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('HOST', true) },
							 
								{text: 'Incubation', datafield: 'INCUBATION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('INCUBATION', true) },
							 
								{text: 'Length', datafield: 'LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LENGTH', true) },
							 
								{text: 'Life Cycle Stage', datafield: 'LIFE_CYCLE_STAGE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LIFE_CYCLE_STAGE', true) },
							 
								{text: 'Life Stage', datafield: 'LIFE_STAGE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LIFE_STAGE', true) },
							 
								{text: 'Max Display Angle', datafield: 'MAX_DISPLAY_ANGLE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MAX_DISPLAY_ANGLE', true) },
							 
								{text: 'Molt Condition', datafield: 'MOLT_CONDITION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MOLT_CONDITION', true) },
							 
								{text: 'Numeric Age', datafield: 'NUMERIC_AGE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('NUMERIC_AGE', true) },
							 
								{text: 'Ossification', datafield: 'OSSIFICATION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('OSSIFICATION', true) },
							 
								{text: 'Plumage Coloration', datafield: 'PLUMAGE_COLORATION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('PLUMAGE_COLORATION', true) },
							 
								{text: 'Plumage Description', datafield: 'PLUMAGE_DESCRIPTION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('PLUMAGE_DESCRIPTION', true) },
							 
								{text: 'Reference', datafield: 'REFERENCE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('REFERENCE', true) },
							 
								{text: 'Reproductive Condition', datafield: 'REPRODUCTIVE_CONDITION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('REPRODUCTIVE_CONDITION', true) },
							 
								{text: 'Reproductive Data', datafield: 'REPRODUCTIVE_DATA', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('REPRODUCTIVE_DATA', true) },
							 
								{text: 'Section Length', datafield: 'SECTION_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SECTION_LENGTH', true) },
							 
								{text: 'Section Stain', datafield: 'SECTION_STAIN', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SECTION_STAIN', true) },
							 
								{text: 'Size Fish', datafield: 'SIZE_FISH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SIZE_FISH', true) },
							 
								{text: 'Snout Vent Length', datafield: 'SNOUT_VENT_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SNOUT_VENT_LENGTH', true) },
							 
								{text: 'Specimen Length', datafield: 'SPECIMEN_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('SPECIMEN_LENGTH', true) },
							 
								{text: 'Stage Description', datafield: 'STAGE_DESCRIPTION', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('STAGE_DESCRIPTION', true) },
							 
								{text: 'Standard Length', datafield: 'STANDARD_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('STANDARD_LENGTH', true) },
							 
								{text: 'Stomach Contents', datafield: 'STOMACH_CONTENTS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('STOMACH_CONTENTS', true) },
							 
								{text: 'Storage', datafield: 'STORAGE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('STORAGE', true) },
							 
								{text: 'Tail Length', datafield: 'TAIL_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TAIL_LENGTH', true) },
							 
								{text: 'Temperature Experiment', datafield: 'TEMPERATURE_EXPERIMENT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TEMPERATURE_EXPERIMENT', true) },
							 
								{text: 'Total Length', datafield: 'TOTAL_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TOTAL_LENGTH', true) },
							 
								{text: 'Total Size', datafield: 'TOTAL_SIZE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TOTAL_SIZE', true) },
							 
								{text: 'Tragus Length', datafield: 'TRAGUS_LENGTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('TRAGUS_LENGTH', true) },
							 
								{text: 'Unformatted Measurements', datafield: 'UNFORMATTED_MEASUREMENTS', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('UNFORMATTED_MEASUREMENTS', true) },
							 
								{text: 'Unspecified Measurement', datafield: 'UNSPECIFIED_MEASUREMENT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('UNSPECIFIED_MEASUREMENT', true) },
							 
								{text: 'Weight', datafield: 'WEIGHT', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('WEIGHT', true) },
							 
								{text: 'Width', datafield: 'WIDTH', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('WIDTH', true) },
							 
								{text: 'Wing Chord', datafield: 'WING_CHORD', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('WING_CHORD', true) },
							 
								{text: 'Locality_ID', datafield: 'LOCALITY_ID', width: 80, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LOCALITY_ID', true) },
							 
								{text: 'collecting_event_id', datafield: 'COLLECTING_EVENT_ID', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('COLLECTING_EVENT_ID', true) },
							 
								{text: 'Institution Acronym', datafield: 'INSTITUTION_ACRONYM', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('INSTITUTION_ACRONYM', true) },
							 
								{text: 'dwc:modified', datafield: 'LAST_EDIT_DATE', filtertype: 'date', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('LAST_EDIT_DATE', true) },
							 
								{text: 'Custom Id', datafield: 'CUSTOMID', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('CUSTOMID', true) },
							 
								{text: 'My Customid Type', datafield: 'MYCUSTOMIDTYPE', width: 100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('MYCUSTOMIDTYPE', true) },
							{text: 'Other IDs', datafield: 'OTHERCATALOGNUMBERS', width:100, cellclassname: keywordcellclass, hidable:true, hidden: getColHidProp('OTHERCATALOGNUMBERS', false) }
					],
					rowdetails: true,
					rowdetailstemplate: {
						rowdetails: "<div style='margin: 10px;'>Row Details</div>",
						rowdetailsheight:  1 // row details will be placed in popup dialog
					},
					initrowdetails: initRowDetails
				});
		
				
					$('#keywordsearchResultsGrid').jqxGrid().on("columnreordered", function (event) { 
						columnOrderChanged('keywordsearchResultsGrid'); 
					}); 
				

				$("#keywordsearchResultsGrid").on("bindingcomplete", function(event) {
					console.log("bindingcomlete: keywordsearchResultsGrid");
					// add a link out to this search, serializing the form as http get parameters
					$('#keywordresultLink').html('<a href="/Specimens.cfm?execute=true&' + $('#keywordSearchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize() + '">Link to this search</a>');
					$('#keywordshowhide').html('<button class="my-2 border rounded" title="hide search form" onclick=" toggleSearchForm(\'keyword\'); "><i id="keywordSearchFormToggleIcon" class="fas fa-eye-slash"></i></button>');
					if (keywordSearchLoaded==0) { 
						try { 
							gridLoaded('keywordsearchResultsGrid','occurrence record','keyword');
						} catch (e) { 
							console.log(e);
							messageDialog("Error in gridLoaded handler:" + e.message,"Error in gridLoaded");
						}
						keywordSearchLoaded = 1;
						loadColumnOrder('keywordsearchResultsGrid');
					}
					
						$('#keywordmanageButton').html('<a href="specimens/manageSpecimens.cfm?result_id='+$('#result_id_keywordSearch').val()+'" target="_blank" class="btn btn-xs btn-secondary my-2 mx-1 px-2" >Manage</a>');
					
					pageLoaded('keywordsearchResultsGrid','occurrence record','keyword');
					 
						console.log(1);
						setPinColumnState('keywordsearchResultsGrid','GUID',true);
					
				});
	
				$('#keywordsearchResultsGrid').on('rowexpand', function (event) {
					//  Create a content div, add it to the detail row, and make it into a dialog.
					var args = event.args;
					var rowIndex = args.rowindex;
					var datarecord = args.owner.source.records[rowIndex];
					console.log(rowIndex);
					createSpecimenRowDetailsDialog('keywordsearchResultsGrid','keywordrowDetailsTarget',datarecord,rowIndex);
				});
				$('#keywordsearchResultsGrid').on('rowcollapse', function (event) {
					// remove the dialog holding the row details
					var args = event.args;
					var rowIndex = args.rowindex;
					$("#keywordsearchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
				});
				// display selected row index.
				$("#keywordsearchResultsGrid").on('rowselect', function (event) {
					$("#keywordselectrowindex").text(event.args.rowindex);
				});
				// display unselected row index.
				$("#keywordsearchResultsGrid").on('rowunselect', function (event) {
					$("#keywordunselectrowindex").text(event.args.rowindex);
				});
			});
	
			/* Setup jqxgrid for builder Search */
			$('#builderSearchForm').bind('submit', function(evt){
				evt.preventDefault();
				var uuid = getVersion4UUID();
				$("#result_id_builderSearch").val(uuid);
				
				
					if (Object.keys(window.columnHiddenSettings).length == 0) {
						lookupColumnVisibilities ('/Specimens.cfm','Default');
					}
				
	
				builderSearchLoaded = 0;

				$("#overlay").show();
		
				$("#buildersearchResultsGrid").replaceWith('<div id="buildersearchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
				$("#builderresultCount").html("");
				$("#builderresultLink").html("");
				$("#buildershowhide").html("");
				$('#buildermanageButton').html('');
				$('#builderremoveButtonDiv').html('');
				$('#buildersaveDialogButton').html('');
				$('#builderactionFeedback').html('');
				$('#builderselectModeContainer').hide();
				$('#builderPostGridControls').hide();
				var debug = $("#builderSearchForm").serialize();
				console.log(debug);
				var search =
				{
					datatype: "json",
					datafields:
					[
						{name: 'GUID', type: 'string' }
							,{name: 'COLLECTION', type: 'string' }
							,{name: 'CAT_NUM', type: 'string' }
							,{name: 'CAT_NUM_INTEGER', type: 'number' }
							,{name: 'CAT_NUM_PREFIX', type: 'string' }
							,{name: 'COLLECTION_OBJECT_ID', type: 'string' }
							,{name: 'DEACCESSIONED', type: 'string' }
							,{name: 'TOPTYPESTATUSKIND', type: 'string' }
							,{name: 'COLL_OBJ_DISPOSITION', type: 'string' }
							,{name: 'ACCESSION', type: 'string' }
							,{name: 'ORIG_LAT_LONG_UNITS', type: 'string' }
							,{name: 'TOPTYPESTATUS', type: 'string' }
							,{name: 'LAT_LONG_DETERMINER', type: 'string' }
							,{name: 'LAT_LONG_REF_SOURCE', type: 'string' }
							,{name: 'TYPESTATUS', type: 'string' }
							,{name: 'LAT_LONG_REMARKS', type: 'string' }
							,{name: 'TYPESTATUS_DISPLAY', type: 'string' }
							,{name: 'TYPESTATUSPLAIN', type: 'string' }
							,{name: 'ASSOCIATED_SPECIES', type: 'string' }
							,{name: 'MICROHABITAT', type: 'string' }
							,{name: 'MIN_ELEV_IN_M', type: 'string' }
							,{name: 'HABITAT_DESC', type: 'string' }
							,{name: 'MAX_ELEV_IN_M', type: 'string' }
							,{name: 'MINIMUM_ELEVATION', type: 'string' }
							,{name: 'MAXIMUM_ELEVATION', type: 'string' }
							,{name: 'ORIG_ELEV_UNITS', type: 'string' }
							,{name: 'SPEC_LOCALITY', type: 'string' }
							,{name: 'SCI_NAME_WITH_AUTH', type: 'string' }
							,{name: 'IDENTIFIED_BY', type: 'string' }
							,{name: 'SCIENTIFIC_NAME', type: 'string' }
							,{name: 'IDENTIFIEDBY', type: 'string' }
							,{name: 'AUTHOR_TEXT', type: 'string' }
							,{name: 'SCI_NAME_WITH_AUTH_PLAIN', type: 'string' }
							,{name: 'ID_SENSU', type: 'string' }
							,{name: 'REMARKS', type: 'string' }
							,{name: 'COLLECTORS', type: 'string' }
							,{name: 'BEGAN_DATE', type: 'string' }
							,{name: 'ENDED_DATE', type: 'string' }
							,{name: 'COLLECTING_METHOD', type: 'string' }
							,{name: 'DEC_LAT', type: 'string' }
							,{name: 'DEC_LONG', type: 'string' }
							,{name: 'DATUM', type: 'string' }
							,{name: 'COORDINATEUNCERTAINTYINMETERS', type: 'string' }
							,{name: 'GEOREFMETHOD', type: 'string' }
							,{name: 'SEX', type: 'string' }
							,{name: 'MIN_DEPTH', type: 'string' }
							,{name: 'MAX_DEPTH', type: 'string' }
							,{name: 'AGE', type: 'string' }
							,{name: 'DEPTH_UNITS', type: 'string' }
							,{name: 'AGE_CLASS', type: 'string' }
							,{name: 'PREPARATORS', type: 'string' }
							,{name: 'ASSOCIATEDSEQUENCES', type: 'string' }
							,{name: 'PARTS', type: 'string' }
							,{name: 'PARTDETAIL', type: 'string' }
							,{name: 'TOTAL_PARTS', type: 'string' }
							,{name: 'GENBANKNUM', type: 'string' }
							,{name: 'COLLECTING_SOURCE', type: 'string' }
							,{name: 'VERIFICATIONSTATUS', type: 'string' }
							,{name: 'LOCALITY_REMARKS', type: 'string' }
							,{name: 'CONTINENT_OCEAN', type: 'string' }
							,{name: 'TYPESTATUSWORDS', type: 'string' }
							,{name: 'CONTINENT', type: 'string' }
							,{name: 'COUNTRY', type: 'string' }
							,{name: 'SOVEREIGN_NATION', type: 'string' }
							,{name: 'COUNTRYCODE', type: 'string' }
							,{name: 'STATE_PROV', type: 'string' }
							,{name: 'SEA', type: 'string' }
							,{name: 'FEATURE', type: 'string' }
							,{name: 'COUNTY', type: 'string' }
							,{name: 'ISLAND_GROUP', type: 'string' }
							,{name: 'QUAD', type: 'string' }
							,{name: 'ISLAND', type: 'string' }
							,{name: 'WATER_FEATURE', type: 'string' }
							,{name: 'WATERBODY', type: 'string' }
							,{name: 'HIGHER_GEOG', type: 'string' }
							,{name: 'VERBATIMLONGITUDE', type: 'string' }
							,{name: 'VERBATIMLOCALITY', type: 'string' }
							,{name: 'VERBATIMLATITUDE', type: 'string' }
							,{name: 'VERBATIMELEVATION', type: 'string' }
							,{name: 'LONGITUDE_AS_ENTERED', type: 'string' }
							,{name: 'COLLECTING_TIME', type: 'string' }
							,{name: 'DATE_EMERGED', type: 'string' }
							,{name: 'CITED_AS', type: 'string' }
							,{name: 'DATE_COLLECTED', type: 'string' }
							,{name: 'VERBATIM_DATE', type: 'string' }
							,{name: 'ISO_BEGAN_DATE', type: 'string' }
							,{name: 'ISO_ENDED_DATE', type: 'string' }
							,{name: 'KINGDOM', type: 'string' }
							,{name: 'PHYLUM', type: 'string' }
							,{name: 'PHYLCLASS', type: 'string' }
							,{name: 'PHYLORDER', type: 'string' }
							,{name: 'FAMILY', type: 'string' }
							,{name: 'TRIBE', type: 'string' }
							,{name: 'SUBPHYLIM', type: 'string' }
							,{name: 'SUBCLASS', type: 'string' }
							,{name: 'INFRACLASS', type: 'string' }
							,{name: 'SUPERORDER', type: 'string' }
							,{name: 'SUBORDER', type: 'string' }
							,{name: 'INFRAORDER', type: 'string' }
							,{name: 'SUPERFAMILY', type: 'string' }
							,{name: 'SUBFAMILY', type: 'string' }
							,{name: 'GENUS', type: 'string' }
							,{name: 'SPECIES', type: 'string' }
							,{name: 'SUBSPECIES', type: 'string' }
							,{name: 'INFRASPECIFIC_RANK', type: 'string' }
							,{name: 'UNNAMED_FORM', type: 'string' }
							,{name: 'NOMENCLATURAL_CODE', type: 'string' }
							,{name: 'IDENTIFICATION_REMARKS', type: 'string' }
							,{name: 'TAXONID', type: 'string' }
							,{name: 'SCIENTIFICNAMEID', type: 'string' }
							,{name: 'CITATIONS', type: 'string' }
							,{name: 'MADE_DATE', type: 'string' }
							,{name: 'FULL_TAXONOMY', type: 'string' }
							,{name: 'ON_LOAN', type: 'string' }
							,{name: 'PARTS_ON_LOAN', type: 'string' }
							,{name: 'CLOSED_LOANS', type: 'string' }
							,{name: 'ACCESSION_RESTRICTIONS', type: 'number' }
							,{name: 'ACCESSION_BENEFITS', type: 'number' }
							,{name: 'RECEIVED_FROM', type: 'string' }
							,{name: 'ACCESSION_DATE', type: 'string' }
							,{name: 'RECEIVED_DATE', type: 'string' }
							,{name: 'ROOMS', type: 'string' }
							,{name: 'CABINETS', type: 'string' }
							,{name: 'DRAWERS', type: 'string' }
							,{name: 'STORED_AS', type: 'string' }
							,{name: 'ENCUMBRANCES', type: 'string' }
							,{name: 'GEOL_GROUP', type: 'string' }
							,{name: 'FORMATION', type: 'string' }
							,{name: 'MEMBER', type: 'string' }
							,{name: 'BED', type: 'string' }
							,{name: 'LATESTERAORHIGHESTERATHEM', type: 'string' }
							,{name: 'LATITUDE_AS_ENTERED', type: 'string' }
							,{name: 'EARLIESTERAORLOWESTERATHEM', type: 'string' }
							,{name: 'LATESTPERIODORHIGHESTSYSTEM', type: 'string' }
							,{name: 'EARLIESTPERIODORLOWESTSYSTEM', type: 'string' }
							,{name: 'EARLIESTEPOCHORLOWESTSERIES', type: 'string' }
							,{name: 'LATESTAGEORHIGHESTSTAGE', type: 'string' }
							,{name: 'EARLIESTAGEORLOWESTSTAGE', type: 'string' }
							,{name: 'LATESTEPOCHORHIGHESTSERIES', type: 'string' }
							,{name: 'EARLIESTEONORLOWESTEONOTHEM', type: 'string' }
							,{name: 'LATESTEONORHIGHESTEONOTHEM', type: 'string' }
							,{name: 'LITHOSTRATIGRAPHICTERMS', type: 'string' }
							,{name: 'RELATEDCATALOGEDITEMS', type: 'string' }
							,{name: 'MEDIA', type: 'string' }
							,{name: 'COLLECTION_CDE', type: 'string' }
							,{name: 'ASSOCIATED_GRANT', type: 'string' }
							,{name: 'ASSOCIATED_MCZ_COLLECTION', type: 'string' }
							,{name: 'ABNORMALITY', type: 'string' }
							,{name: 'ASSOCIATED_TAXON', type: 'string' }
							,{name: 'BARE_PARTS_COLORATION', type: 'string' }
							,{name: 'BODY_LENGTH', type: 'string' }
							,{name: 'CITATION', type: 'string' }
							,{name: 'COLORS', type: 'string' }
							,{name: 'CROWN_RUMP_LENGTH', type: 'string' }
							,{name: 'DIAMETER', type: 'string' }
							,{name: 'DISK_LENGTH', type: 'string' }
							,{name: 'DISK_WIDTH', type: 'string' }
							,{name: 'EAR_FROM_NOTCH', type: 'string' }
							,{name: 'EXTENT', type: 'string' }
							,{name: 'FAT_DEPOSITION', type: 'string' }
							,{name: 'FOREARM_LENGTH', type: 'string' }
							,{name: 'FORK_LENGTH', type: 'string' }
							,{name: 'FOSSIL_MEASUREMENT', type: 'string' }
							,{name: 'HEAD_LENGTH', type: 'string' }
							,{name: 'HEIGHT', type: 'string' }
							,{name: 'HIND_FOOT_WITH_CLAW', type: 'string' }
							,{name: 'HOST', type: 'string' }
							,{name: 'INCUBATION', type: 'string' }
							,{name: 'LENGTH', type: 'string' }
							,{name: 'LIFE_CYCLE_STAGE', type: 'string' }
							,{name: 'LIFE_STAGE', type: 'string' }
							,{name: 'MAX_DISPLAY_ANGLE', type: 'string' }
							,{name: 'MOLT_CONDITION', type: 'string' }
							,{name: 'NUMERIC_AGE', type: 'string' }
							,{name: 'OSSIFICATION', type: 'string' }
							,{name: 'PLUMAGE_COLORATION', type: 'string' }
							,{name: 'PLUMAGE_DESCRIPTION', type: 'string' }
							,{name: 'REFERENCE', type: 'string' }
							,{name: 'REPRODUCTIVE_CONDITION', type: 'string' }
							,{name: 'REPRODUCTIVE_DATA', type: 'string' }
							,{name: 'SECTION_LENGTH', type: 'string' }
							,{name: 'SECTION_STAIN', type: 'string' }
							,{name: 'SIZE_FISH', type: 'string' }
							,{name: 'SNOUT_VENT_LENGTH', type: 'string' }
							,{name: 'SPECIMEN_LENGTH', type: 'string' }
							,{name: 'STAGE_DESCRIPTION', type: 'string' }
							,{name: 'STANDARD_LENGTH', type: 'string' }
							,{name: 'STOMACH_CONTENTS', type: 'string' }
							,{name: 'STORAGE', type: 'string' }
							,{name: 'TAIL_LENGTH', type: 'string' }
							,{name: 'TEMPERATURE_EXPERIMENT', type: 'string' }
							,{name: 'TOTAL_LENGTH', type: 'string' }
							,{name: 'TOTAL_SIZE', type: 'string' }
							,{name: 'TRAGUS_LENGTH', type: 'string' }
							,{name: 'UNFORMATTED_MEASUREMENTS', type: 'string' }
							,{name: 'UNSPECIFIED_MEASUREMENT', type: 'string' }
							,{name: 'WEIGHT', type: 'string' }
							,{name: 'WIDTH', type: 'string' }
							,{name: 'WING_CHORD', type: 'string' }
							,{name: 'LOCALITY_ID', type: 'number' }
							,{name: 'COLLECTING_EVENT_ID', type: 'number' }
							,{name: 'INSTITUTION_ACRONYM', type: 'string' }
							,{name: 'LAST_EDIT_DATE', type: 'string' }
							,{name: 'CUSTOMID', type: 'string' }
							,{name: 'MYCUSTOMIDTYPE', type: 'string' }
							,{name: 'OTHERCATALOGNUMBERS', type: 'string' }
							
					],
					beforeprocessing: function (data) {
						if (data != null && data.length > 0) {
							search.totalrecords = data[0].recordcount;
						}
					},
					sort: function () {
						$("#buildersearchResultsGrid").jqxGrid('updatebounddata','sort');
					},
					root: 'specimenRecord',
					id: 'collection_object_id',
					url: '/specimens/component/search.cfc?' + $("#builderSearchForm").serialize(),
					timeout: 60000,  // units not specified, miliseconds?  Builder
					loadError: function(jqXHR, textStatus, error) {
						handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
					},
					async: true,
					deleterow: function (rowid, commit) {
						console.log(rowid);
						console.log($('#buildersearchResultsGrid').jqxGrid('getRowData',rowid));
						var collobjtoremove = $('#buildersearchResultsGrid').jqxGrid('getRowData',rowid)['COLLECTION_OBJECT_ID'];
						console.log(collobjtoremove);
	        			$.ajax({
            				url: "/specimens/component/search.cfc",
            				data: { 
								method: 'removeItemFromResult', 
								result_id: $('#result_id_builderSearch').val(),
								collection_object_id: collobjtoremove
							},
							dataType: 'json',
           					success : function (data) { 
								console.log(data);
								commit(true);
								$('#buildersearchResultsGrid').jqxGrid('updatebounddata');
							},
            				error : function (jqXHR, textStatus, error) {
          				   	handleFail(jqXHR,textStatus,error,"removing row from result set");
								commit(false);
            				}
         			});
					} 
				};	
	
				var dataAdapter = new $.jqx.dataAdapter(search);
				var initRowDetails = function (index, parentElement, gridElement, datarecord) {
					// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
					var details = $($(parentElement).children()[0]);
					console.log(index);
					details.html("<div id='builderrowDetailsTarget" + index + "'></div>");
					createSpecimenRowDetailsDialog('buildersearchResultsGrid','builderrowDetailsTarget',datarecord,index);
					// Workaround, expansion sits below row in zindex.
					var maxZIndex = getMaxZIndex();
					$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
				}
		
				$("#buildersearchResultsGrid").jqxGrid({
					width: '100%',
					autoheight: 'true',
					source: dataAdapter,
					filterable: false,
					sortable: true,
					pageable: true,
					editable: false,
					virtualmode: true,
					enablemousewheel: true,
					pagesize: '25',
					pagesizeoptions: ['5','10','25','50','100','500'], // fixed list regardless of actual result set size, dynamic reset goes into infinite loop.
					showaggregates: true,
					columnsresize: true,
					autoshowfiltericon: true,
					autoshowcolumnsmenubutton: false,
					autoshowloadelement: false,  // overlay acts as load element for form+results
					columnsreorder: true,
					groupable: true,
					selectionmode: 'none',
					enablebrowserselection: true,
					altrows: true,
					showtoolbar: false,
					ready: function () {
						$("#buildersearchResultsGrid").jqxGrid('selectrow', 0);
						$("#buildersearchResultsGrid").jqxGrid('focus');
					},
					rendergridrows: function () {
						return dataAdapter.records;
					},
					columns: [
						{text: 'Remove', datafield: 'RemoveRow', cellsrenderer:removeBuilderCellRenderer, width: 40, cellclassname: fixedcellclass, hidable:false, hidden: false },  
								{text: 'GUID', datafield: 'GUID', cellsrenderer:builder_GuidCellRenderer, width: 155, cellclassname: buildercellclass, hidable:false, hidden: getColHidProp('GUID', false) },
							 
								{text: 'Collection', datafield: 'COLLECTION', width: 150, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COLLECTION', false) },
							 
								{text: 'Catalog Number', datafield: 'CAT_NUM', width: 130, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CAT_NUM', false) },
							 
								{text: 'Catalog Number Integer Part', datafield: 'CAT_NUM_INTEGER', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CAT_NUM_INTEGER', true) },
							 
								{text: 'Catalog Number Prefix', datafield: 'CAT_NUM_PREFIX', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CAT_NUM_PREFIX', true) },
							 
								{text: 'InternalCollObjectID', datafield: 'COLLECTION_OBJECT_ID', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COLLECTION_OBJECT_ID', true) },
							 
								{text: 'Deaccessioned', datafield: 'DEACCESSIONED', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DEACCESSIONED', false) },
							 
								{text: 'Top Type Status Kind', datafield: 'TOPTYPESTATUSKIND', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TOPTYPESTATUSKIND', true) },
							 
								{text: 'Coll Obj Disposition', datafield: 'COLL_OBJ_DISPOSITION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COLL_OBJ_DISPOSITION', true) },
							 
								{text: 'Accession', datafield: 'ACCESSION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ACCESSION', true) },
							 
								{text: 'Orig Lat Long Units', datafield: 'ORIG_LAT_LONG_UNITS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ORIG_LAT_LONG_UNITS', true) },
							 
								{text: 'Top Type Status', datafield: 'TOPTYPESTATUS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TOPTYPESTATUS', false) },
							 
								{text: 'Lat Long Determiner', datafield: 'LAT_LONG_DETERMINER', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LAT_LONG_DETERMINER', true) },
							 
								{text: 'Lat Long Ref Source', datafield: 'LAT_LONG_REF_SOURCE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LAT_LONG_REF_SOURCE', true) },
							 
								{text: 'Type Status', datafield: 'TYPESTATUS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TYPESTATUS', true) },
							 
								{text: 'Lat Long Remarks', datafield: 'LAT_LONG_REMARKS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LAT_LONG_REMARKS', true) },
							 
								{text: 'Type Status Display', datafield: 'TYPESTATUS_DISPLAY', width: 160, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TYPESTATUS_DISPLAY', true) },
							 
								{text: 'Type Status Plain', datafield: 'TYPESTATUSPLAIN', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TYPESTATUSPLAIN', true) },
							 
								{text: 'Associated Species', datafield: 'ASSOCIATED_SPECIES', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_SPECIES', true) },
							 
								{text: 'Microhabitat', datafield: 'MICROHABITAT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MICROHABITAT', true) },
							 
								{text: 'Min Elev In m', datafield: 'MIN_ELEV_IN_M', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MIN_ELEV_IN_M', true) },
							 
								{text: 'Habitat', datafield: 'HABITAT_DESC', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('HABITAT_DESC', true) },
							 
								{text: 'Max Elev In m', datafield: 'MAX_ELEV_IN_M', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MAX_ELEV_IN_M', true) },
							 
								{text: 'Minimum Elevation', datafield: 'MINIMUM_ELEVATION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MINIMUM_ELEVATION', true) },
							 
								{text: 'Maximum Elevation', datafield: 'MAXIMUM_ELEVATION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MAXIMUM_ELEVATION', true) },
							 
								{text: 'Orig Elev Units', datafield: 'ORIG_ELEV_UNITS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ORIG_ELEV_UNITS', true) },
							 
								{text: 'Specific Locality', datafield: 'SPEC_LOCALITY', width: 280, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SPEC_LOCALITY', false) },
							 
								{text: 'Sci Name With Auth', datafield: 'SCI_NAME_WITH_AUTH', cellsrenderer:builder_sciNameCellRenderer, width: 250, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SCI_NAME_WITH_AUTH', false) },
							 
								{text: 'Identified By', datafield: 'IDENTIFIED_BY', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('IDENTIFIED_BY', true) },
							 
								{text: 'Scientific Name', datafield: 'SCIENTIFIC_NAME', cellsrenderer:linkTaxonCellRenderer, width: 250, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SCIENTIFIC_NAME', true) },
							 
								{text: 'Identified By', datafield: 'IDENTIFIEDBY', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('IDENTIFIEDBY', true) },
							 
								{text: 'Authorship', datafield: 'AUTHOR_TEXT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('AUTHOR_TEXT', true) },
							 
								{text: 'dwc:scientificName', datafield: 'SCI_NAME_WITH_AUTH_PLAIN', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SCI_NAME_WITH_AUTH_PLAIN', true) },
							 
								{text: 'Id Sensu', datafield: 'ID_SENSU', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ID_SENSU', true) },
							 
								{text: 'Remarks', datafield: 'REMARKS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('REMARKS', true) },
							 
								{text: 'Collectors', datafield: 'COLLECTORS', width: 180, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COLLECTORS', false) },
							 
								{text: 'Began Date', datafield: 'BEGAN_DATE', filtertype: 'date', width: 115, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('BEGAN_DATE', false) },
							 
								{text: 'Ended Date', datafield: 'ENDED_DATE', filtertype: 'date', width: 115, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ENDED_DATE', false) },
							 
								{text: 'Collecting Method', datafield: 'COLLECTING_METHOD', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COLLECTING_METHOD', true) },
							 
								{text: 'Dec Lat', datafield: 'DEC_LAT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DEC_LAT', true) },
							 
								{text: 'Dec Long', datafield: 'DEC_LONG', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DEC_LONG', true) },
							 
								{text: 'Datum', datafield: 'DATUM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DATUM', true) },
							 
								{text: 'Coordinate uncertainty m', datafield: 'COORDINATEUNCERTAINTYINMETERS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COORDINATEUNCERTAINTYINMETERS', true) },
							 
								{text: 'Georef Method', datafield: 'GEOREFMETHOD', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('GEOREFMETHOD', true) },
							 
								{text: 'Sex', datafield: 'SEX', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SEX', true) },
							 
								{text: 'Min Depth', datafield: 'MIN_DEPTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MIN_DEPTH', true) },
							 
								{text: 'Max Depth', datafield: 'MAX_DEPTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MAX_DEPTH', true) },
							 
								{text: 'Age', datafield: 'AGE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('AGE', true) },
							 
								{text: 'Depth Units', datafield: 'DEPTH_UNITS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DEPTH_UNITS', true) },
							 
								{text: 'Age Class', datafield: 'AGE_CLASS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('AGE_CLASS', true) },
							 
								{text: 'Preparators', datafield: 'PREPARATORS', width: 180, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('PREPARATORS', true) },
							 
								{text: 'Associated Sequences', datafield: 'ASSOCIATEDSEQUENCES', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ASSOCIATEDSEQUENCES', true) },
							 
								{text: 'Parts', datafield: 'PARTS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('PARTS', true) },
							 
								{text: 'Part Detail', datafield: 'PARTDETAIL', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('PARTDETAIL', true) },
							 
								{text: 'Total Parts', datafield: 'TOTAL_PARTS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TOTAL_PARTS', true) },
							 
								{text: 'Genbank Num', datafield: 'GENBANKNUM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('GENBANKNUM', true) },
							 
								{text: 'Collecting Source', datafield: 'COLLECTING_SOURCE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COLLECTING_SOURCE', true) },
							 
								{text: 'Verification Status', datafield: 'VERIFICATIONSTATUS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('VERIFICATIONSTATUS', true) },
							 
								{text: 'Locality Remarks', datafield: 'LOCALITY_REMARKS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LOCALITY_REMARKS', true) },
							 
								{text: 'Continent/Ocean', datafield: 'CONTINENT_OCEAN', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CONTINENT_OCEAN', true) },
							 
								{text: 'Type Status Words', datafield: 'TYPESTATUSWORDS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TYPESTATUSWORDS', true) },
							 
								{text: 'Continent', datafield: 'CONTINENT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CONTINENT', true) },
							 
								{text: 'Country', datafield: 'COUNTRY', width: 110, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COUNTRY', false) },
							 
								{text: 'Sovereign Nation', datafield: 'SOVEREIGN_NATION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SOVEREIGN_NATION', true) },
							 
								{text: 'Country Code', datafield: 'COUNTRYCODE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COUNTRYCODE', true) },
							 
								{text: 'State/Province', datafield: 'STATE_PROV', width: 120, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('STATE_PROV', false) },
							 
								{text: 'Sea', datafield: 'SEA', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SEA', true) },
							 
								{text: 'Feature', datafield: 'FEATURE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('FEATURE', true) },
							 
								{text: 'County', datafield: 'COUNTY', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COUNTY', true) },
							 
								{text: 'Island Group', datafield: 'ISLAND_GROUP', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ISLAND_GROUP', true) },
							 
								{text: 'Quad', datafield: 'QUAD', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('QUAD', true) },
							 
								{text: 'Island', datafield: 'ISLAND', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ISLAND', true) },
							 
								{text: 'Water Feature', datafield: 'WATER_FEATURE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('WATER_FEATURE', true) },
							 
								{text: 'Waterbody', datafield: 'WATERBODY', width: 150, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('WATERBODY', false) },
							 
								{text: 'Concatenated Higher Geography', datafield: 'HIGHER_GEOG', width: 200, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('HIGHER_GEOG', true) },
							 
								{text: 'Verbatim Longitude', datafield: 'VERBATIMLONGITUDE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('VERBATIMLONGITUDE', true) },
							 
								{text: 'Verbatim Locality', datafield: 'VERBATIMLOCALITY', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('VERBATIMLOCALITY', true) },
							 
								{text: 'Verbatim Latitude', datafield: 'VERBATIMLATITUDE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('VERBATIMLATITUDE', true) },
							 
								{text: 'Verbatim Elevation', datafield: 'VERBATIMELEVATION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('VERBATIMELEVATION', true) },
							 
								{text: 'Longitude as entered', datafield: 'LONGITUDE_AS_ENTERED', width: 120, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LONGITUDE_AS_ENTERED', true) },
							 
								{text: 'Collecting Time', datafield: 'COLLECTING_TIME', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COLLECTING_TIME', true) },
							 
								{text: 'Date Emerged', datafield: 'DATE_EMERGED', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DATE_EMERGED', true) },
							 
								{text: 'Cited As', datafield: 'CITED_AS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CITED_AS', true) },
							 
								{text: 'Date Collected', datafield: 'DATE_COLLECTED', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DATE_COLLECTED', true) },
							 
								{text: 'Verbatim Date', datafield: 'VERBATIM_DATE', width: 190, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('VERBATIM_DATE', false) },
							 
								{text: 'Iso Began Date', datafield: 'ISO_BEGAN_DATE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ISO_BEGAN_DATE', true) },
							 
								{text: 'Iso Ended Date', datafield: 'ISO_ENDED_DATE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ISO_ENDED_DATE', true) },
							 
								{text: 'Kingdom', datafield: 'KINGDOM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('KINGDOM', true) },
							 
								{text: 'Phylum', datafield: 'PHYLUM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('PHYLUM', true) },
							 
								{text: 'Class', datafield: 'PHYLCLASS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('PHYLCLASS', true) },
							 
								{text: 'Order', datafield: 'PHYLORDER', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('PHYLORDER', true) },
							 
								{text: 'Family', datafield: 'FAMILY', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('FAMILY', true) },
							 
								{text: 'Tribe', datafield: 'TRIBE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TRIBE', true) },
							 
								{text: 'Subphylum', datafield: 'SUBPHYLIM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SUBPHYLIM', true) },
							 
								{text: 'Subclass', datafield: 'SUBCLASS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SUBCLASS', true) },
							 
								{text: 'Infraclass', datafield: 'INFRACLASS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('INFRACLASS', true) },
							 
								{text: 'Superorder', datafield: 'SUPERORDER', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SUPERORDER', true) },
							 
								{text: 'Suborder', datafield: 'SUBORDER', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SUBORDER', true) },
							 
								{text: 'Infraorder', datafield: 'INFRAORDER', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('INFRAORDER', true) },
							 
								{text: 'superfamily', datafield: 'SUPERFAMILY', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SUPERFAMILY', true) },
							 
								{text: 'Subfamily', datafield: 'SUBFAMILY', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SUBFAMILY', true) },
							 
								{text: 'Genus', datafield: 'GENUS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('GENUS', true) },
							 
								{text: 'Species', datafield: 'SPECIES', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SPECIES', true) },
							 
								{text: 'Subspecies', datafield: 'SUBSPECIES', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SUBSPECIES', true) },
							 
								{text: 'Infraspecific Rank', datafield: 'INFRASPECIFIC_RANK', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('INFRASPECIFIC_RANK', true) },
							 
								{text: 'Unnamed Form', datafield: 'UNNAMED_FORM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('UNNAMED_FORM', true) },
							 
								{text: 'Nomenclatural Code', datafield: 'NOMENCLATURAL_CODE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('NOMENCLATURAL_CODE', true) },
							 
								{text: 'Identification Remarks', datafield: 'IDENTIFICATION_REMARKS', width: 200, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('IDENTIFICATION_REMARKS', true) },
							 
								{text: 'dwc:Taxonid', datafield: 'TAXONID', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TAXONID', true) },
							 
								{text: 'dwc:Scientificnameid', datafield: 'SCIENTIFICNAMEID', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SCIENTIFICNAMEID', true) },
							 
								{text: 'Citations', datafield: 'CITATIONS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CITATIONS', true) },
							 
								{text: 'Made Date', datafield: 'MADE_DATE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MADE_DATE', true) },
							 
								{text: 'Concatenated Taxonomy', datafield: 'FULL_TAXONOMY', width: 200, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('FULL_TAXONOMY', true) },
							 
								{text: 'On Loan', datafield: 'ON_LOAN', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ON_LOAN', true) },
							 
								{text: 'Parts On Loan', datafield: 'PARTS_ON_LOAN', width: 120, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('PARTS_ON_LOAN', true) },
							 
								{text: 'Closed Loans', datafield: 'CLOSED_LOANS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CLOSED_LOANS', true) },
							 
								{text: 'Accession has restrictions', datafield: 'ACCESSION_RESTRICTIONS', cellsrenderer:yesBlankFlagRenderer, width: 80, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ACCESSION_RESTRICTIONS', true) },
							 
								{text: 'Accession requires benefits', datafield: 'ACCESSION_BENEFITS', cellsrenderer:yesBlankFlagRenderer, width: 80, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ACCESSION_BENEFITS', true) },
							 
								{text: 'Received From', datafield: 'RECEIVED_FROM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('RECEIVED_FROM', true) },
							 
								{text: 'Accession Date', datafield: 'ACCESSION_DATE', filtertype: 'date', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ACCESSION_DATE', true) },
							 
								{text: 'Received  Date', datafield: 'RECEIVED_DATE', filtertype: 'date', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('RECEIVED_DATE', true) },
							 
								{text: 'Rooms', datafield: 'ROOMS', width: 120, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ROOMS', true) },
							 
								{text: 'FIxture/Freezer/Cryovat', datafield: 'CABINETS', width: 120, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CABINETS', true) },
							 
								{text: 'Compartment/Freezer Rack', datafield: 'DRAWERS', width: 150, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DRAWERS', true) },
							 
								{text: 'Stored As', datafield: 'STORED_AS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('STORED_AS', true) },
							 
								{text: 'Encumbrances', datafield: 'ENCUMBRANCES', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ENCUMBRANCES', true) },
							 
								{text: 'Group', datafield: 'GEOL_GROUP', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('GEOL_GROUP', true) },
							 
								{text: 'Formation', datafield: 'FORMATION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('FORMATION', true) },
							 
								{text: 'Member', datafield: 'MEMBER', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MEMBER', true) },
							 
								{text: 'Bed', datafield: 'BED', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('BED', true) },
							 
								{text: 'Latest Era', datafield: 'LATESTERAORHIGHESTERATHEM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LATESTERAORHIGHESTERATHEM', true) },
							 
								{text: 'Latitude as entered', datafield: 'LATITUDE_AS_ENTERED', width: 120, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LATITUDE_AS_ENTERED', true) },
							 
								{text: 'Earliest Era', datafield: 'EARLIESTERAORLOWESTERATHEM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('EARLIESTERAORLOWESTERATHEM', true) },
							 
								{text: 'Latest Period', datafield: 'LATESTPERIODORHIGHESTSYSTEM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LATESTPERIODORHIGHESTSYSTEM', true) },
							 
								{text: 'Earliest Period', datafield: 'EARLIESTPERIODORLOWESTSYSTEM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('EARLIESTPERIODORLOWESTSYSTEM', true) },
							 
								{text: 'Earliest Epoch', datafield: 'EARLIESTEPOCHORLOWESTSERIES', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('EARLIESTEPOCHORLOWESTSERIES', true) },
							 
								{text: 'Latest Age', datafield: 'LATESTAGEORHIGHESTSTAGE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LATESTAGEORHIGHESTSTAGE', true) },
							 
								{text: 'Earliest Age', datafield: 'EARLIESTAGEORLOWESTSTAGE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('EARLIESTAGEORLOWESTSTAGE', true) },
							 
								{text: 'Latest Epoch', datafield: 'LATESTEPOCHORHIGHESTSERIES', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LATESTEPOCHORHIGHESTSERIES', true) },
							 
								{text: 'Earliest Eon', datafield: 'EARLIESTEONORLOWESTEONOTHEM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('EARLIESTEONORLOWESTEONOTHEM', true) },
							 
								{text: 'Latest Eon', datafield: 'LATESTEONORHIGHESTEONOTHEM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LATESTEONORHIGHESTEONOTHEM', true) },
							 
								{text: 'Lithostratigraphic Terms', datafield: 'LITHOSTRATIGRAPHICTERMS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LITHOSTRATIGRAPHICTERMS', true) },
							 
								{text: 'Related Cataloged Items', datafield: 'RELATEDCATALOGEDITEMS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('RELATEDCATALOGEDITEMS', true) },
							 
								{text: 'Media', datafield: 'MEDIA', cellsrenderer:builder_mediaCellRenderer, width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MEDIA', true) },
							 
								{text: 'Collection Code', datafield: 'COLLECTION_CDE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COLLECTION_CDE', true) },
							 
								{text: 'Associated Grant', datafield: 'ASSOCIATED_GRANT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_GRANT', true) },
							 
								{text: 'Associated MCZ Collection', datafield: 'ASSOCIATED_MCZ_COLLECTION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_MCZ_COLLECTION', true) },
							 
								{text: 'Abnormality', datafield: 'ABNORMALITY', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ABNORMALITY', true) },
							 
								{text: 'Associated Taxon', datafield: 'ASSOCIATED_TAXON', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('ASSOCIATED_TAXON', true) },
							 
								{text: 'Bare Parts Coloration', datafield: 'BARE_PARTS_COLORATION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('BARE_PARTS_COLORATION', true) },
							 
								{text: 'Body Length', datafield: 'BODY_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('BODY_LENGTH', true) },
							 
								{text: 'Citation (Attribute)', datafield: 'CITATION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CITATION', true) },
							 
								{text: 'Colors', datafield: 'COLORS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COLORS', true) },
							 
								{text: 'Crown Rump Length', datafield: 'CROWN_RUMP_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CROWN_RUMP_LENGTH', true) },
							 
								{text: 'Diameter', datafield: 'DIAMETER', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DIAMETER', true) },
							 
								{text: 'Disk Length', datafield: 'DISK_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DISK_LENGTH', true) },
							 
								{text: 'Disk Width', datafield: 'DISK_WIDTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('DISK_WIDTH', true) },
							 
								{text: 'Ear From Notch', datafield: 'EAR_FROM_NOTCH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('EAR_FROM_NOTCH', true) },
							 
								{text: 'Extent', datafield: 'EXTENT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('EXTENT', true) },
							 
								{text: 'Fat Deposition', datafield: 'FAT_DEPOSITION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('FAT_DEPOSITION', true) },
							 
								{text: 'Forearm Length', datafield: 'FOREARM_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('FOREARM_LENGTH', true) },
							 
								{text: 'Fork Length', datafield: 'FORK_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('FORK_LENGTH', true) },
							 
								{text: 'Fossil Measurement', datafield: 'FOSSIL_MEASUREMENT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('FOSSIL_MEASUREMENT', true) },
							 
								{text: 'Head Length', datafield: 'HEAD_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('HEAD_LENGTH', true) },
							 
								{text: 'Height', datafield: 'HEIGHT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('HEIGHT', true) },
							 
								{text: 'Hind Foot With Claw', datafield: 'HIND_FOOT_WITH_CLAW', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('HIND_FOOT_WITH_CLAW', true) },
							 
								{text: 'Host', datafield: 'HOST', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('HOST', true) },
							 
								{text: 'Incubation', datafield: 'INCUBATION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('INCUBATION', true) },
							 
								{text: 'Length', datafield: 'LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LENGTH', true) },
							 
								{text: 'Life Cycle Stage', datafield: 'LIFE_CYCLE_STAGE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LIFE_CYCLE_STAGE', true) },
							 
								{text: 'Life Stage', datafield: 'LIFE_STAGE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LIFE_STAGE', true) },
							 
								{text: 'Max Display Angle', datafield: 'MAX_DISPLAY_ANGLE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MAX_DISPLAY_ANGLE', true) },
							 
								{text: 'Molt Condition', datafield: 'MOLT_CONDITION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MOLT_CONDITION', true) },
							 
								{text: 'Numeric Age', datafield: 'NUMERIC_AGE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('NUMERIC_AGE', true) },
							 
								{text: 'Ossification', datafield: 'OSSIFICATION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('OSSIFICATION', true) },
							 
								{text: 'Plumage Coloration', datafield: 'PLUMAGE_COLORATION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('PLUMAGE_COLORATION', true) },
							 
								{text: 'Plumage Description', datafield: 'PLUMAGE_DESCRIPTION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('PLUMAGE_DESCRIPTION', true) },
							 
								{text: 'Reference', datafield: 'REFERENCE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('REFERENCE', true) },
							 
								{text: 'Reproductive Condition', datafield: 'REPRODUCTIVE_CONDITION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('REPRODUCTIVE_CONDITION', true) },
							 
								{text: 'Reproductive Data', datafield: 'REPRODUCTIVE_DATA', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('REPRODUCTIVE_DATA', true) },
							 
								{text: 'Section Length', datafield: 'SECTION_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SECTION_LENGTH', true) },
							 
								{text: 'Section Stain', datafield: 'SECTION_STAIN', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SECTION_STAIN', true) },
							 
								{text: 'Size Fish', datafield: 'SIZE_FISH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SIZE_FISH', true) },
							 
								{text: 'Snout Vent Length', datafield: 'SNOUT_VENT_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SNOUT_VENT_LENGTH', true) },
							 
								{text: 'Specimen Length', datafield: 'SPECIMEN_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('SPECIMEN_LENGTH', true) },
							 
								{text: 'Stage Description', datafield: 'STAGE_DESCRIPTION', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('STAGE_DESCRIPTION', true) },
							 
								{text: 'Standard Length', datafield: 'STANDARD_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('STANDARD_LENGTH', true) },
							 
								{text: 'Stomach Contents', datafield: 'STOMACH_CONTENTS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('STOMACH_CONTENTS', true) },
							 
								{text: 'Storage', datafield: 'STORAGE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('STORAGE', true) },
							 
								{text: 'Tail Length', datafield: 'TAIL_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TAIL_LENGTH', true) },
							 
								{text: 'Temperature Experiment', datafield: 'TEMPERATURE_EXPERIMENT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TEMPERATURE_EXPERIMENT', true) },
							 
								{text: 'Total Length', datafield: 'TOTAL_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TOTAL_LENGTH', true) },
							 
								{text: 'Total Size', datafield: 'TOTAL_SIZE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TOTAL_SIZE', true) },
							 
								{text: 'Tragus Length', datafield: 'TRAGUS_LENGTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('TRAGUS_LENGTH', true) },
							 
								{text: 'Unformatted Measurements', datafield: 'UNFORMATTED_MEASUREMENTS', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('UNFORMATTED_MEASUREMENTS', true) },
							 
								{text: 'Unspecified Measurement', datafield: 'UNSPECIFIED_MEASUREMENT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('UNSPECIFIED_MEASUREMENT', true) },
							 
								{text: 'Weight', datafield: 'WEIGHT', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('WEIGHT', true) },
							 
								{text: 'Width', datafield: 'WIDTH', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('WIDTH', true) },
							 
								{text: 'Wing Chord', datafield: 'WING_CHORD', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('WING_CHORD', true) },
							 
								{text: 'Locality_ID', datafield: 'LOCALITY_ID', width: 80, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LOCALITY_ID', true) },
							 
								{text: 'collecting_event_id', datafield: 'COLLECTING_EVENT_ID', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('COLLECTING_EVENT_ID', true) },
							 
								{text: 'Institution Acronym', datafield: 'INSTITUTION_ACRONYM', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('INSTITUTION_ACRONYM', true) },
							 
								{text: 'dwc:modified', datafield: 'LAST_EDIT_DATE', filtertype: 'date', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('LAST_EDIT_DATE', true) },
							 
								{text: 'Custom Id', datafield: 'CUSTOMID', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('CUSTOMID', true) },
							 
								{text: 'My Customid Type', datafield: 'MYCUSTOMIDTYPE', width: 100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('MYCUSTOMIDTYPE', true) },
							{text: 'Other IDs', datafield: 'OTHERCATALOGNUMBERS', width:100, cellclassname: buildercellclass, hidable:true, hidden: getColHidProp('OTHERCATALOGNUMBERS', false) }
					],
					rowdetails: true,
					rowdetailstemplate: {
						rowdetails: "<div style='margin: 10px;'>Row Details</div>",
						rowdetailsheight:  1 // row details will be placed in popup dialog
					},
					initrowdetails: initRowDetails
				});
		
				
					$('#buildersearchResultsGrid').jqxGrid().on("columnreordered", function (event) { 
						columnOrderChanged('buildersearchResultsGrid'); 
					}); 
				

				$("#buildersearchResultsGrid").on("bindingcomplete", function(event) {
					// add a link out to this search, serializing the form as http get parameters
					$('#builderresultLink').html('<a href="/Specimens.cfm?execute=true&' + $('#builderSearchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize() + '">Link to this search</a>');
					$('#buildershowhide').html('<button class="my-2 border rounded" title="hide search form" onclick=" toggleSearchForm(\'builder\'); "><i id="builderSearchFormToggleIcon" class="fas fa-eye-slash"></i></button>');
					if (builderSearchLoaded==0) { 
						try { 
							gridLoaded('buildersearchResultsGrid','occurrence record','builder');
						} catch (e) { 
							console.log(e);
							messageDialog("Error in gridLoaded handler:" + e.message,"Error in gridLoaded");
						}
						builderSearchLoaded = 1;
						loadColumnOrder('buildersearchResultsGrid');
					}
					
						$('#buildermanageButton').html('<a href="specimens/manageSpecimens.cfm?result_id='+$('#result_id_builderSearch').val()+'" target="_blank" class="btn btn-xs btn-secondary px-2 my-2 mx-1" >Manage</a>');
					
					pageLoaded('buildersearchResultsGrid','occurrence record','builder');
					 
						console.log(1);
						setPinColumnState('buildersearchResultsGrid','GUID',true);
					
				});
				$('#buildersearchResultsGrid').on('rowexpand', function (event) {
					//  Create a content div, add it to the detail row, and make it into a dialog.
					var args = event.args;
					var rowIndex = args.rowindex;
					var datarecord = args.owner.source.records[rowIndex];
					console.log(rowIndex);
					createSpecimenRowDetailsDialog('buildersearchResultsGrid','builderrowDetailsTarget',datarecord,rowIndex);
				});
				$('#buildersearchResultsGrid').on('rowcollapse', function (event) {
					// remove the dialog holding the row details
					var args = event.args;
					var rowIndex = args.rowindex;
					$("#buildersearchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
				});
				// display selected row index.
				$("#buildersearchResultsGrid").on('rowselect', function (event) {
					$("#builderselectrowindex").text(event.args.rowindex);
				});
				// display unselected row index.
				$("#buildersearchResultsGrid").on('rowunselect', function (event) {
					$("#builderunselectrowindex").text(event.args.rowindex);
				});
			});
	

			// If requested in uri, execute search immediately.
			
		}); /* End document.ready */
	
		var columnCategoryPlacements = new Map(); // fieldname and category placement
		var columnCategories = new Map();   // category and count 
		var columnSections = new Map();   // category and array of list rows
		
			columnCategoryPlacements.set("GUID","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("COLLECTION","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("CAT_NUM","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("CAT_NUM_INTEGER","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("CAT_NUM_PREFIX","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("COLLECTION_OBJECT_ID","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("DEACCESSIONED","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("TOPTYPESTATUSKIND","citation");
			if (columnCategories.has("citation")) { 
				columnCategories.set("citation", columnCategories.get("citation") + 1);
			} else {
				columnCategories.set("citation",1);
				columnSections.set("citation",new Array());
			}
		
			columnCategoryPlacements.set("COLL_OBJ_DISPOSITION","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("ACCESSION","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("ORIG_LAT_LONG_UNITS","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("TOPTYPESTATUS","citation");
			if (columnCategories.has("citation")) { 
				columnCategories.set("citation", columnCategories.get("citation") + 1);
			} else {
				columnCategories.set("citation",1);
				columnSections.set("citation",new Array());
			}
		
			columnCategoryPlacements.set("LAT_LONG_DETERMINER","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("LAT_LONG_REF_SOURCE","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("TYPESTATUS","citation");
			if (columnCategories.has("citation")) { 
				columnCategories.set("citation", columnCategories.get("citation") + 1);
			} else {
				columnCategories.set("citation",1);
				columnSections.set("citation",new Array());
			}
		
			columnCategoryPlacements.set("LAT_LONG_REMARKS","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("TYPESTATUS_DISPLAY","citation");
			if (columnCategories.has("citation")) { 
				columnCategories.set("citation", columnCategories.get("citation") + 1);
			} else {
				columnCategories.set("citation",1);
				columnSections.set("citation",new Array());
			}
		
			columnCategoryPlacements.set("TYPESTATUSPLAIN","citation");
			if (columnCategories.has("citation")) { 
				columnCategories.set("citation", columnCategories.get("citation") + 1);
			} else {
				columnCategories.set("citation",1);
				columnSections.set("citation",new Array());
			}
		
			columnCategoryPlacements.set("ASSOCIATED_SPECIES","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("MICROHABITAT","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("MIN_ELEV_IN_M","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("HABITAT_DESC","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("MAX_ELEV_IN_M","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("MINIMUM_ELEVATION","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("MAXIMUM_ELEVATION","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("ORIG_ELEV_UNITS","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("SPEC_LOCALITY","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("SCI_NAME_WITH_AUTH","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("IDENTIFIED_BY","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("SCIENTIFIC_NAME","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("IDENTIFIEDBY","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("AUTHOR_TEXT","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("SCI_NAME_WITH_AUTH_PLAIN","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("ID_SENSU","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("REMARKS","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("COLLECTORS","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("BEGAN_DATE","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("ENDED_DATE","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("COLLECTING_METHOD","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("DEC_LAT","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("DEC_LONG","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("DATUM","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("COORDINATEUNCERTAINTYINMETERS","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("GEOREFMETHOD","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("SEX","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("MIN_DEPTH","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("MAX_DEPTH","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("AGE","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("DEPTH_UNITS","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("AGE_CLASS","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("PREPARATORS","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("ASSOCIATEDSEQUENCES","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("PARTS","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("PARTDETAIL","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("TOTAL_PARTS","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("GENBANKNUM","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("COLLECTING_SOURCE","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("VERIFICATIONSTATUS","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("LOCALITY_REMARKS","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("CONTINENT_OCEAN","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("TYPESTATUSWORDS","citation");
			if (columnCategories.has("citation")) { 
				columnCategories.set("citation", columnCategories.get("citation") + 1);
			} else {
				columnCategories.set("citation",1);
				columnSections.set("citation",new Array());
			}
		
			columnCategoryPlacements.set("CONTINENT","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("COUNTRY","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("SOVEREIGN_NATION","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("COUNTRYCODE","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("STATE_PROV","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("SEA","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("FEATURE","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("COUNTY","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("ISLAND_GROUP","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("QUAD","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("ISLAND","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("WATER_FEATURE","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("WATERBODY","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("HIGHER_GEOG","geography");
			if (columnCategories.has("geography")) { 
				columnCategories.set("geography", columnCategories.get("geography") + 1);
			} else {
				columnCategories.set("geography",1);
				columnSections.set("geography",new Array());
			}
		
			columnCategoryPlacements.set("VERBATIMLONGITUDE","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("VERBATIMLOCALITY","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("VERBATIMLATITUDE","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("VERBATIMELEVATION","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("LONGITUDE_AS_ENTERED","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("COLLECTING_TIME","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("DATE_EMERGED","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("CITED_AS","citation");
			if (columnCategories.has("citation")) { 
				columnCategories.set("citation", columnCategories.get("citation") + 1);
			} else {
				columnCategories.set("citation",1);
				columnSections.set("citation",new Array());
			}
		
			columnCategoryPlacements.set("DATE_COLLECTED","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("VERBATIM_DATE","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("ISO_BEGAN_DATE","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("ISO_ENDED_DATE","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("KINGDOM","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("PHYLUM","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("PHYLCLASS","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("PHYLORDER","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("FAMILY","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("TRIBE","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("SUBPHYLIM","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("SUBCLASS","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("INFRACLASS","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("SUPERORDER","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("SUBORDER","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("INFRAORDER","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("SUPERFAMILY","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("SUBFAMILY","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("GENUS","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("SPECIES","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("SUBSPECIES","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("INFRASPECIFIC_RANK","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("UNNAMED_FORM","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("NOMENCLATURAL_CODE","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("IDENTIFICATION_REMARKS","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("TAXONID","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("SCIENTIFICNAMEID","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("CITATIONS","citation");
			if (columnCategories.has("citation")) { 
				columnCategories.set("citation", columnCategories.get("citation") + 1);
			} else {
				columnCategories.set("citation",1);
				columnSections.set("citation",new Array());
			}
		
			columnCategoryPlacements.set("MADE_DATE","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("FULL_TAXONOMY","taxonomy");
			if (columnCategories.has("taxonomy")) { 
				columnCategories.set("taxonomy", columnCategories.get("taxonomy") + 1);
			} else {
				columnCategories.set("taxonomy",1);
				columnSections.set("taxonomy",new Array());
			}
		
			columnCategoryPlacements.set("ON_LOAN","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("PARTS_ON_LOAN","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("CLOSED_LOANS","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("ACCESSION_RESTRICTIONS","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("ACCESSION_BENEFITS","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("RECEIVED_FROM","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("ACCESSION_DATE","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("RECEIVED_DATE","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("ROOMS","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("CABINETS","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("DRAWERS","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("STORED_AS","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("ENCUMBRANCES","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("GEOL_GROUP","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("FORMATION","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("MEMBER","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("BED","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("LATESTERAORHIGHESTERATHEM","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("LATITUDE_AS_ENTERED","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("EARLIESTERAORLOWESTERATHEM","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("LATESTPERIODORHIGHESTSYSTEM","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("EARLIESTPERIODORLOWESTSYSTEM","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("EARLIESTEPOCHORLOWESTSERIES","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("LATESTAGEORHIGHESTSTAGE","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("EARLIESTAGEORLOWESTSTAGE","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("LATESTEPOCHORHIGHESTSERIES","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("EARLIESTEONORLOWESTEONOTHEM","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("LATESTEONORHIGHESTEONOTHEM","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("LITHOSTRATIGRAPHICTERMS","geology");
			if (columnCategories.has("geology")) { 
				columnCategories.set("geology", columnCategories.get("geology") + 1);
			} else {
				columnCategories.set("geology",1);
				columnSections.set("geology",new Array());
			}
		
			columnCategoryPlacements.set("RELATEDCATALOGEDITEMS","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("MEDIA","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("COLLECTION_CDE","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("ASSOCIATED_GRANT","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("ASSOCIATED_MCZ_COLLECTION","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("ABNORMALITY","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("ASSOCIATED_TAXON","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("BARE_PARTS_COLORATION","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("BODY_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("CITATION","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("COLORS","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("CROWN_RUMP_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("DIAMETER","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("DISK_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("DISK_WIDTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("EAR_FROM_NOTCH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("EXTENT","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("FAT_DEPOSITION","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("FOREARM_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("FORK_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("FOSSIL_MEASUREMENT","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("HEAD_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("HEIGHT","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("HIND_FOOT_WITH_CLAW","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("HOST","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("INCUBATION","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("LIFE_CYCLE_STAGE","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("LIFE_STAGE","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("MAX_DISPLAY_ANGLE","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("MOLT_CONDITION","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("NUMERIC_AGE","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("OSSIFICATION","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("PLUMAGE_COLORATION","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("PLUMAGE_DESCRIPTION","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("REFERENCE","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("REPRODUCTIVE_CONDITION","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("REPRODUCTIVE_DATA","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("SECTION_LENGTH","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("SECTION_STAIN","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("SIZE_FISH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("SNOUT_VENT_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("SPECIMEN_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("STAGE_DESCRIPTION","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("STANDARD_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("STOMACH_CONTENTS","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("STORAGE","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("TAIL_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("TEMPERATURE_EXPERIMENT","attribute");
			if (columnCategories.has("attribute")) { 
				columnCategories.set("attribute", columnCategories.get("attribute") + 1);
			} else {
				columnCategories.set("attribute",1);
				columnSections.set("attribute",new Array());
			}
		
			columnCategoryPlacements.set("TOTAL_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("TOTAL_SIZE","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("TRAGUS_LENGTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("UNFORMATTED_MEASUREMENTS","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("UNSPECIFIED_MEASUREMENT","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("WEIGHT","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("WIDTH","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("WING_CHORD","attribute-measurement");
			if (columnCategories.has("attribute-measurement")) { 
				columnCategories.set("attribute-measurement", columnCategories.get("attribute-measurement") + 1);
			} else {
				columnCategories.set("attribute-measurement",1);
				columnSections.set("attribute-measurement",new Array());
			}
		
			columnCategoryPlacements.set("LOCALITY_ID","locality");
			if (columnCategories.has("locality")) { 
				columnCategories.set("locality", columnCategories.get("locality") + 1);
			} else {
				columnCategories.set("locality",1);
				columnSections.set("locality",new Array());
			}
		
			columnCategoryPlacements.set("COLLECTING_EVENT_ID","collectingevent");
			if (columnCategories.has("collectingevent")) { 
				columnCategories.set("collectingevent", columnCategories.get("collectingevent") + 1);
			} else {
				columnCategories.set("collectingevent",1);
				columnSections.set("collectingevent",new Array());
			}
		
			columnCategoryPlacements.set("INSTITUTION_ACRONYM","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
			columnCategoryPlacements.set("LAST_EDIT_DATE","curatorial");
			if (columnCategories.has("curatorial")) { 
				columnCategories.set("curatorial", columnCategories.get("curatorial") + 1);
			} else {
				columnCategories.set("curatorial",1);
				columnSections.set("curatorial",new Array());
			}
		
			columnCategoryPlacements.set("CUSTOMID","custom");
			if (columnCategories.has("custom")) { 
				columnCategories.set("custom", columnCategories.get("custom") + 1);
			} else {
				columnCategories.set("custom",1);
				columnSections.set("custom",new Array());
			}
		
			columnCategoryPlacements.set("MYCUSTOMIDTYPE","custom");
			if (columnCategories.has("custom")) { 
				columnCategories.set("custom", columnCategories.get("custom") + 1);
			} else {
				columnCategories.set("custom",1);
				columnSections.set("custom",new Array());
			}
		
			columnCategoryPlacements.set("OTHERCATALOGNUMBERS","specimen");
			if (columnCategories.has("specimen")) { 
				columnCategories.set("specimen", columnCategories.get("specimen") + 1);
			} else {
				columnCategories.set("specimen",1);
				columnSections.set("specimen",new Array());
			}
		
	
		function populateSaveSearch(gridId,whichGrid) { 
			// set up a dialog for saving the current search.
			var uri = "/Specimens.cfm?execute=true&" + $('#'+whichGrid+'SearchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize();
			$("#"+whichGrid+"saveDialog").html(
				"<div class='row mx-0'>"+ 
				"<form id='"+whichGrid+"saveForm'> " + 
				" <input type='hidden' value='"+uri+"' name='url'>" + 
				" <div class='col-12 p-1'>" + 
				"  <label for='search_name_input_"+whichGrid+"'>Search Name</label>" + 
				"  <input type='text' id='search_name_input_"+whichGrid+"'  name='search_name' value='' class='data-entry-input reqdClr' placeholder='Your name for this search' maxlength='60' required>" + 
				" </div>" + 
				" <div class='col-12'>" + 
				"  <label for='execute_input_"+whichGrid+"'>Execute Immediately</label>"+
				"  <input id='execute_input_"+whichGrid+"' type='checkbox' name='execute' checked>"+
				" </div>" +
				"</form>"+
				"</div>"
			);
		}
		function populateColumnPicker(gridId,whichGrid) {
			// add a control to show/hide columns organized by category
			var columns = $('#' + gridId).jqxGrid('columns').records;
			var columnCount = columns.length;
			// clear out the datafield arrays for each columnSection category
			for (let [key,value] of columnSections) { value.length = 0; };
			// repopulate the datafield arrays for each columnSection category with the current values.
			for (i = 1; i < columnCount; i++) {
				var text = columns[i].text;
				var datafield = columns[i].datafield;
				var hideable = columns[i].hideable;
				var hidden = columns[i].hidden;
				var show = ! hidden;
				if (hideable == true) {
					var listRow = { label: text, value: datafield, checked: show };
					var inCategory = columnCategoryPlacements.get(datafield);
					if (inCategory) { 
						columnSections.get(inCategory).push(listRow);
					}
				}
			}
			console.log(columnSections);
			$("#"+whichGrid+"columnPick_row").html("");
			$('<div/>',{
    			id: whichGrid +"columnPick_col",
    			class: "col-12 mb-2 accordion"
			}).appendTo("#"+whichGrid+"columnPick_row");
			var firstAccord = true;
			var bodyClass="";
			var ariaExpanded="";
			for (let [key, value] of columnCategories) { 
				// TODO: use value (number of fields in category) to subdivide long categories.
				$('<div/>',{
    				id: whichGrid + "_" + key + "_accord",
    				class: "card bg-light accordion-item",
    				title: key
				}).appendTo("#"+whichGrid+"columnPick_col");
				if (firstAccord) { 
					bodyClass = "show";
					ariaExpanded = "true";
					firstAccord = false;
				} else { 
					bodyClass = "";
					ariaExpanded = "false";
				}
				$('<div/>',{
    				id: whichGrid + "_" + key + "_accord_head",
    				class: "card-header accordion-header"
				}).appendTo("#"+whichGrid+"_"+ key +"_accord");
				$('<h2/>',{
    				id: whichGrid + "_" + key + "_accord_head_h2",
    				class: "h4 my-0"
				}).appendTo("#"+whichGrid+"_"+ key +"_accord_head");
				$("#"+whichGrid+"_"+ key +"_accord_head_h2").html('<button class="accordion-button headerLnk text-left w-100" data-toggle="collapse" data-target="#'+whichGrid+'_'+key+'_accord_body" aria-expanded="'+ariaExpanded+'" aria-controls="#'+whichGrid+'_'+key+'_accord_body">'+key+'</button>');
				$('<div/>',{
    				id: whichGrid + "_" + key + "_accord_body",
    				class: "card-body accordion-collapse collapse " + bodyClass 
				}).appendTo("#"+whichGrid+"_"+ key +"_accord");
				$('<div/>',{
    				id: whichGrid + "_" + key + "_accord_list",
    				class: ""
				}).appendTo("#"+whichGrid+"_"+ key +"_accord_body");
				$("#"+whichGrid+"_"+key+"_accord_list").jqxListBox({ source: columnSections.get(key), autoHeight: true, width: '260px', checkboxes: true });
				$("#"+whichGrid+"_"+key+"_accord_list").on('checkChange', function (event) {
					$("#" + gridId).jqxGrid('beginupdate');
					if (event.args.checked) {
						$("#" + gridId).jqxGrid('showcolumn', event.args.value);
					} else {
						$("#" + gridId).jqxGrid('hidecolumn', event.args.value);
					}
					$("#" + gridId).jqxGrid('endupdate');
				});
			}
		}

		function pageLoaded(gridId, searchType, whichGrid) {
			console.log('pageLoaded:' + gridId);
			var pagingInfo = $("#" + gridId).jqxGrid("getpaginginformation");
			
		}

		function togglePinColumn(gridId,column) { 
			var state = $('#'+gridId).jqxGrid('getcolumnproperty', column, 'pinned');
			$("#"+gridId).jqxGrid('beginupdate');
			if (state==true) {
				$('#'+gridId).jqxGrid('unpincolumn', column);
				$('#pinGuidToggle').html("Pin GUID Column");
			} else {
				$('#'+gridId).jqxGrid('pincolumn', column);
				$('#pinGuidToggle').html("Unpin GUID Column");
			}
			$("#"+gridId).jqxGrid('endupdate');
		}
		function setPinColumnState(gridId,column,state) { 
			if (state==true) {
				$('#'+gridId).jqxGrid('pincolumn', column);
				$('#pinGuidToggle').html("Unpin GUID Column");
			} else {
				$('#'+gridId).jqxGrid('unpincolumn', column);
				$('#pinGuidToggle').html("Pin GUID Column");
			}
		}
		function toggleSearchForm(whichGrid) { 
			toggleAnySearchForm(whichGrid+"SearchFormDiv", whichGrid + "SearchFormToggleIcon");
		}
		// update resultCount control to indicate that result set has been modified.
		function resultModified(gridId,whichGrid) { 
			console.log('resultModified: ',whichGrid);
			var datainformation = $('#' + gridId).jqxGrid('getdatainformation');
			var rowcount = datainformation.rowscount;
			if (rowcount == 1) {
				$('#'+whichGrid+'resultCount').html('Modified to ' + rowcount + ' record');
			} else {
				$('#'+whichGrid+'resultCount').html('Modified to ' + rowcount + ' records');
			}
			var rowcount = $("#"+whichGrid+"searchResultsGrid").jqxGrid('getrows').length;
			if (rowcount ==0 ) {
				console.log("On empty page after row removal") 
				// we are on the last page, and removed the only remaining row(s) on it, go to the first page
				// Go to page isn't working here
				// $('#'+whichGrid+'searchResultsGrid').jqxGrid('gotopage',0);
				// workaround by changing page size, this ends up bouncing to first page.
				var pagesize = $('#'+whichGrid+'searchResultsGrid').jqxGrid("getpaginginformation").pagesize
				$('#'+whichGrid+'searchResultsGrid').jqxGrid("pagesize", pagesize+1);
				$('#'+whichGrid+'searchResultsGrid').jqxGrid("pagesize", pagesize);
			}
		}
		function gridLoaded(gridId, searchType, whichGrid) {
			console.log('gridLoaded:' + gridId);
			var maxZIndex = getMaxZIndex();
			

			if (Object.keys(window.columnHiddenSettings).length == 0) {
				
					lookupColumnVisibilities ('/Specimens.cfm','Default');
				
					saveColumnVisibilities('/Specimens.cfm',window.columnHiddenSettings,'Default');
				
			}
			$("#overlay").hide();
			$('.jqx-header-widget').css({'z-index': maxZIndex + 1 });
			var now = new Date();
			var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
			var filename = searchType.replace(/ /g,'_') + '_results_' + nowstring + '.csv';
			// display the number of rows found
			var datainformation = $('#' + gridId).jqxGrid('getdatainformation');
			var rowcount = datainformation.rowscount;
			if (rowcount == 1) {
				$('#'+whichGrid+'resultCount').html('Found ' + rowcount + ' ' + searchType);
			} else {
				$('#'+whichGrid+'resultCount').html('Found ' + rowcount + ' ' + searchType + 's');
			}
			populateColumnPicker(gridId,whichGrid);

			$("#"+whichGrid+"columnPickDialog").dialog({
				height: 'auto',
				width: 'auto',
				adaptivewidth: true,
				title: 'Show/Hide Columns',
				autoOpen: false,
				modal: true,
				resizable: true,
				close: function(event, ui) { 
					window.columnHiddenSettings = getColumnVisibilities(gridId);		
					
						saveColumnVisibilities('/Specimens.cfm',window.columnHiddenSettings,'Default');
					
				},
				buttons: [
					
					{
						text: "Defaults",
						click: function(){ 
							saveColumnVisibilities('/Specimens.cfm',null,'Default');
							saveColumnOrder('/Specimens.cfm',null,'Default',null);
							lookupColumnVisibilities ('/Specimens.cfm','Default');
							window.columnHiddenSettings = getColumnVisibilities(whichGrid+'searchResultsGrid');
							messageDialog("Default values for show/hide columns and column order will be used on your next search." ,'Reset to Defaults');
							$(this).dialog("close");
						},
						tabindex: 1
					},
					
					{
						text: "Ok",
						click: function(){ 
							$(this).dialog("close"); 
						},
						tabindex: 0
					}
				],
				open: function (event, ui) {
					var maxZIndex = getMaxZIndex();
					// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
					$('.ui-dialog').css({'z-index': maxZIndex + 4 });
					$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
				}
			});
			$("#"+whichGrid+"columnPickDialogButton").html(
				`<button id="columnPickDialogOpener" 
					onclick=" populateColumnPicker('`+gridId+`','`+whichGrid+`'); $('#`+whichGrid+`columnPickDialog').dialog('open'); " 
					class="btn btn-xs btn-secondary my-2 mx-1 px-2" >Select Columns</button>
				<button id="pinGuidToggle" onclick=" togglePinColumn('`+gridId+`','GUID'); " class="btn btn-xs btn-secondary mx-1 px-2 my-2" >Pin GUID Column</button>
				`
			);
			
				$("#"+whichGrid+"saveDialog").dialog({
					height: 'auto',
					width: 'auto',
					adaptivewidth: true,
					title: 'Save Search',
					autoOpen: false,
					modal: true,
					resizable: true,
					buttons: [
						{
							text: "Save",
							click: function(){
								var url = $('#'+whichGrid+'saveForm :input[name=url]').val();
								var execute = $('#'+whichGrid+'saveForm :input[name=execute]').is(':checked');
								var search_name = $('#'+whichGrid+'saveForm :input[name=search_name]').val();
								saveSearch(url, execute, search_name, whichGrid+"actionFeedback");
								$(this).dialog("close"); 
							},
							tabindex: 0
						},
						{
							text: "Cancel",
							click: function(){ 
								$(this).dialog("close"); 
							},
							tabindex: 0
						}
					],
					open: function (event, ui) {
						var maxZIndex = getMaxZIndex();
						// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
						$('.ui-dialog').css({'z-index': maxZIndex + 4 });
						$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
					}
				});
				$("#"+whichGrid+"saveDialogButton").html(
				`<button id="`+gridId+`saveDialogOpener"
						onclick=" populateSaveSearch('`+gridId+`','`+whichGrid+`'); $('#`+whichGrid+`saveDialog').dialog('open'); " 
						class="btn btn-xs btn-secondary px-2 my-2 mx-1" >Save Search</button>
				`);
			
			// workaround for menu z-index being below grid cell z-index when grid is created by a search.
			// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
			maxZIndex = getMaxZIndex();
			try { 
				$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-cell').css({'border-color': '#aaa'});
			} catch (error) { 
				console.log(error);
				console.log("See BugID: 6152, Error seen by Stevie running chrome full screen on a second monitor.");  
				console.log("Appears to result from jquery selector on the jqx-grid-cell class exceding the stack size.");  
				console.log("Expected consequence is that the sort menus on the grid are not visible.");  
			}
			try { 
				$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-group-cell').css({'border-color': '#aaa'});
			} catch (error) { 
				console.log(error);
			}
			try { 
				$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
			} catch (error) { 
				console.log(error);
			}
			var result_uuid = $('#result_id_' + whichGrid + 'Search').val(); 
			
					$('#'+whichGrid+'resultDownloadButtonContainer').html(`<button id="specimencsvbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" aria-label="Export results to csv" onclick=" openDownloadDialog('downloadAgreeDialogDiv', '` + result_uuid + `', '` + filename + `'); " >Export to CSV</button>`);
				 
				console.log(1);
				setPinColumnState(gridId,'GUID',true);
			
				$('#'+whichGrid+'resultBMMapLinkContainer').html(`<a id="`+whichGrid+`BMMapButton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" target="_blank" href="/bnhmMaps/bnhmMapData.cfm?result_id=`+result_uuid+`" aria-label="Plot points in Berkeley Mapper">BerkeleyMapper</a>`);
				loadGeoreferenceCount(result_uuid,whichGrid + 'BMMapButton','BerkeleyMapper (',')');
			
				$("html, body").scrollTop($("#"+whichGrid+"SearchResultsSection").offset().top);
			
			$('#'+whichGrid+'selectModeContainer').show();
			$('#'+whichGrid+'PostGridControls').show();
		}

	</script>
	<script>
	/*!
	 * classie - class helper functions
	 * from bonzo https://github.com/ded/bonzo
	 *
	 * classie.has( elem, 'my-class' ) -> true/false
	 * classie.add( elem, 'my-new-class' )
	 * classie.remove( elem, 'my-unwanted-class' )
	 * classie.toggle( elem, 'my-class' )
	 */
	/*jshint browser: true, strict: true, undef: true */
	
	( function( window ) {
	
	'use strict';
	
	// class helper functions from bonzo https://github.com/ded/bonzo
	
	function classReg( className ) {
	  return new RegExp("(^|\\s+)" + className + "(\\s+|$)");
	}
	
	// classList support for class management
	// altho to be fair, the api sucks because it won't accept multiple classes at once
	var hasClass, addClass, removeClass;
	
	if ( 'classList' in document.documentElement ) {
	  hasClass = function( elem, c ) {
	    return elem.classList.contains( c );
	  };
	  addClass = function( elem, c ) {
	    elem.classList.add( c );
	  };
	  removeClass = function( elem, c ) {
	    elem.classList.remove( c );
	  };
	}
	else {
	  hasClass = function( elem, c ) {
	    return classReg( c ).test( elem.className );
	  };
	  addClass = function( elem, c ) {
	    if ( !hasClass( elem, c ) ) {
	      elem.className = elem.className + ' ' + c;
	    }
	  };
	  removeClass = function( elem, c ) {
	    elem.className = elem.className.replace( classReg( c ), ' ' );
	  };
	}
	
	function toggleClass( elem, c ) {
	  var fn = hasClass( elem, c ) ? removeClass : addClass;
	  fn( elem, c );
	}
	
	window.classie = {
	  // full names
	  hasClass: hasClass,
	  addClass: addClass,
	  removeClass: removeClass,
	  toggleClass: toggleClass,
	  // short names
	  has: hasClass,
	  add: addClass,
	  remove: removeClass,
	  toggle: toggleClass
	};
	
	})( window );
</script>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">