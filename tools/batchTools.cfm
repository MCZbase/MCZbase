<cfset pageTitle = "Batch Tools">
<cfinclude template = "/shared/_header.cfm">
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/scripts/demos.js"></script> 

<cfoutput>
<main class="container py-3">
	<section class="row">
		<div class="col-12">
			<h1 class="h2">Batch Tools</h1>



			<div class="accordion mb-4" id="accordionExample">
				<div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed" name="addAttributes" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree"> &nbsp;Bulk Add Attributes
						</a>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
						 <div class="card-body px-4">
							<h3 class="h5">Add Attributes to Existing Specimen Records</h3>
							<script>
					function generatedata(rowscount, hasNullValues) {
				// prepare the data
				var data = new Array();
				if (rowscount == undefined) rowscount = 1;
				var collection_cde =
				[
					"Herp"
				];

				var institution_acronym =
				[
					"MCZ"
				];

				var other_id_type =
				[
					"catalog item"
				];

				var other_id_number =
				[
					 "1234"
				];

					var attribute =
				[
					 "caste"
				];
				var attribute_value =
				[
					 "worker"
				];

				var attribute_units =
				[
					 ""
				];
				var attribute_date =
				[
					 "2000-01-01"
				];
				var attribute_meth =
				[
					 ""
				];
				var determiner =
				[
					 "Joe White"
				];
				var remarks =
				[
					 "This is sample data."
				];
				for (var i = 0; i < rowscount; i++) {
					var row = {};       

					row["id"] = i;

					row["collection_cde"] = collection_cde;
					row["institution_acronym"] = institution_acronym;
					row["other_id_type"] = other_id_type;
					row["other_id_number"] = other_id_number;
					row["attribute"] = attribute;
					row["attribute_value"] = attribute_value;
					row["attribute_units"] = attribute_units;
					row["attribute_date"] = attribute_date;
					row["attribute_meth"] = attribute_meth;
					row["determiner"] = determiner;
					row["remarks"] = remarks;



					data[i] = row;
				}

				return data;
			}
				</script>				     	
							<script type="text/javascript">
					$(document).ready(function () {
						// prepare the data
						var data = generatedata(1);

						var source =
						{
							localdata: data,
							datatype: "array",
							datafields:
							[
								{ name: 'collection_cde', type: 'string' },
								{ name: 'institution_acronym', type: 'string' },
								{ name: 'other_id_type', type: 'string' },
								{ name: 'other_id_number', type: 'string' },
								{ name: 'attribute', type: 'string' },
								{ name: 'attribute_value', type: 'string' },
								{ name: 'attribute_unit', type: 'string' },
								{ name: 'attribute_date', type: 'string' },
								{ name: 'attribute_meth', type: 'string' },
								{ name: 'determiner', type: 'string' },
								{ name: 'remarks', type: 'string'}
							]                     
						};

						var dataAdapter = new $.jqx.dataAdapter(source);

						// initialize jqxGrid
						$("##grid").jqxGrid(
						{
							width: '100%',
							autoheight: 'true',
							source: dataAdapter,                
							altrows: true,
							sortable: false,
							columnsresize: true,
							selectionmode: 'multiplecellsextended',
							columns: [
							  { text: 'collection_cde', datafield: 'collection_cde', width: 115 },
							  { text: 'institution_acronym', datafield: 'institution_acronym', width: 90 },
							  { text: 'other_id_type', datafield: 'other_id_type', width: 90 },
							  { text: 'other_id_number', datafield: 'other_id_number', width: 90 },
							  { text: 'attribute', datafield: 'attribute', width: 80 },
							  { text: 'attribute_value', datafield: 'attribute_value', width: 90 },
							  { text: 'attribute_unit', datafield: 'attribute_unit', width: 90 },
							  { text: 'attribute_date', datafield: 'attribute_date', width: 70 },
							  { text: 'attribute_meth', datafield: 'attribute_meth', width: 70 },
							  { text: 'determiner', datafield: 'determiner', width: 120 },
								{ text: 'remarks', datafield: 'remarks', width:220 }
							]
						});

						$("##csvExport").jqxButton();

						$("##csvExport").click(function () {
							$("##grid").jqxGrid('exportdata', 'csv', 'jqxGrid');
						});

					});
				</script>
       			 			<div id="grid"></div>
        					<div class="mt-3 mb-2 d-block float-left w-100">
			<div class="ml-0 float-left">
                <input type="button" value="Export to CSV" id='csvExport' />
			</div>
        </div>
							<p>This tool adds attributes to the specimen record. The attribute has to be in the code table prior to uploading this .csv.</h4>
							<h5><a href="/info/ctDocumentation.cfm?table=ctattribute_type">Attribute List</a></h5>
							<p>Columns in red are required; others are optional:</p>
							<ul class="px-4 list-style-disc">
								<li class="text-danger">COLLECTION_CDE</li>
								<li class="text-danger">INSTITUTION_ACRONYM</li>
								<li class="text-danger">OTHER_ID_TYPE ("catalog number" is OK)</li>
								<li class="text-danger">OTHER_ID_NUMBER</li>
								<li class="text-danger">ATTRIBUTE</li>
								<li class="text-danger">ATTRIBUTE_VALUE</li>
								<li>ATTRIBUTE_UNITS</li>
								<li class="text-danger">ATTRIBUTE_DATE</li>
								<li>ATTRIBUTE_METH</li>
								<li class="text-danger">DETERMINER</li>
								<li>REMARKS</li>
							</ul>

				
						 </div>
					</div>
				</div>	<!---3--->
				<div class="card">
					<div class="card-header py-0" id="headingOne">
					 <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed" name="addNewParts" data-toggle="collapse" data-target="##collapseOne" aria-expanded="true" aria-controls="collapseOne">
						  &nbsp;Add New Parts
						</a>
					  </h2>
					</div>
					<div id="collapseOne" class="collapse" aria-labelledby="headingOne" data-parent="##accordionExample">
						<div class="card-body px-4">
							<h3 class="h5">Add New Parts to Existing Specimen Records</h3>
							<p>Upload a comma-delimited text file (csv). Delete the columns that are not needed on the downloaded csv file.</p>
							<script>
									function generatedata2(rowscount, hasNullValues) {
							// prepare the data
							var data = new Array();
							if (rowscount == undefined) rowscount = 1;
							var collection_cde = 
								[ 
									"Herp" 
								];
							var institution_acronym = 
								[  
									"MCZ" 
								];
							var other_id_type = 
								[ 
									"catalog item" 
								];
							var other_id_number = 
								[ 
									"1234" 
								];
							var part_name = 
								[
									"whole animal"
								];
							var preserve_method =
								[ 
									"ethanol"
								];
							var disposition = 
								[  
									"in collection" 
								];
							var lot_count_modifier = 
								[
									">"
								];
							var lot_count = 
								[ 
									"1"
								];
							var current_remarks =
								[ 
									"good" 
								];
							var container_unique_id =
								[ 
									"" 
								];
							var condition =
								[ 
									"" 
								];
							var part_att_name_1 =
								[ 
									"" 
								];
							var part_att_val_1 =
								[ 
									"" 
								];
							var part_att_units_1 =
								[ 
									"" 
								];
							var part_att_detby_1 =
								[ 
									"" 
								];
							var part_att_madedate_1 =
								[ 
									"" 
								];
							var part_att_rem_1 =
								[ 
									"" 
								];
							var part_att_name_2 =
								[ 
									"" 
								];
							var part_att_val_2 =
								[ 
									"" 
								];
							var part_att_units_2 =
								[ 
									"" 
								];
							var part_att_detby_2 =
								[ 
									"" 
								];
							var part_att_madedate_2 =
								[ 
									"" 
								];
							var part_att_rem_2 =
								[ 
									"" 
								];
							for (var i = 0; i < rowscount; i++) {
								var row = {};       
								row["id"] = i;
								row["collection_cde"] = collection_cde;
								row["institution_acronym"] = institution_acronym;
								row["other_id_type"] = other_id_type;
								row["other_id_number"] = other_id_number;
								row["part_name"] = part_name;
								row["preserve_method"] = preserve_method;
								row["disposition"] = disposition;
								row["lot_count_modifier"] = lot_count_modifier;
								row["lot_count"] = lot_count;
								row["current_remarks"] = current_remarks;
								row["container_unique_id"] = container_unique_id;
								row["condition"] = condition;
								row["part_att_name_1"] = part_att_name_1;
								row["part_att_val_1"] = part_att_val_1;
								row["part_att_units_1"] = part_att_units_1;
								row["part_att_detby_1"] = part_att_detby_1;
								row["part_att_madedate_1"] = part_att_madedate_1;
								row["part_att_rem_1"] = part_att_rem_1;
								row["part_att_name_2"] = part_att_name_2;
								row["part_att_val_2"] = part_att_val_2;
								row["part_att_units_2"] = part_att_units_2;
								row["part_att_detby_2"] = part_att_detby_2;
								row["part_att_madedate_2"] = part_att_madedate_2;
								row["part_att_rem_2"] = part_att_rem_2;

								data[i] = row;
							}
							return data;
						}
							</script>				     	
    						<script type="text/javascript">
        $(document).ready(function () {
            // prepare the data
            var data = generatedata2(1);
            var source =
            {
                localdata: data,
                datatype: "array",
                datafields:
                [
                    { name: 'collection_cde', type: 'string' },
                    { name: 'institution_acronym', type: 'string' },
                    { name: 'other_id_type', type: 'string' },
                    { name: 'other_id_number', type: 'string' },
                    { name: 'part_name', type: 'string' },
                    { name: 'preserve_method', type: 'string' },
                    { name: 'disposition', type: 'string' },
					{ name: 'lot_count_modifier', type: 'string' },
                    { name: 'lot_count', type: 'string' },
					{ name: 'current_remarks', type: 'string' },
                    { name: 'container_unique_id', type: 'string' },
                    { name: 'condition', type: 'string' },
					{ name: 'part_att_name_1', type: 'string' },
                    { name: 'part_att_val_1', type: 'string' },
					{ name: 'part_att_units_1', type: 'string' },
                    { name: 'part_att_detby_1', type: 'string' },
					{ name: 'part_att_madedate_1', type: 'string' },
                    { name: 'part_att_rem_1', type: 'string' },
					{ name: 'part_att_name_2', type: 'string' },
                    { name: 'part_att_val_2', type: 'string' },
					{ name: 'part_att_units_2', type: 'string' },
                    { name: 'part_att_detby_2', type: 'string' },
					{ name: 'part_att_madedate_2', type: 'string' },
					{ name: 'part_att_rem_2', type: 'string' },
                ]                     
            };
            var dataAdapter = new $.jqx.dataAdapter(source);
            // initialize jqxGrid
            $("##grid2").jqxGrid(
            {
                width: '100%',
				autoheight: 'true',
                source: dataAdapter,                
                altrows: true,
          		sortable: false,
				columnsresize: true,
                selectionmode: 'multiplecellsextended',
                columns: [
                  	{ text: 'collection_cde', datafield: 'collection_cde', width: 115 },
                  	{ text: 'institution_acronym', datafield: 'institution_acronym', width: 90 },
                  	{ text: 'other_id_type', datafield: 'other_id_type', width: 90 },
                  	{ text: 'other_id_number', datafield: 'other_id_number', width: 90 },
                  	{ text: 'part_name', datafield: 'part_name', width: 80 },
                  	{ text: 'preserve_method', datafield: 'preserve_method', width: 90 },
                  	{ text: 'disposition', datafield: 'disposition', width: 70 },
				  	{ text: 'lot_count_modifier', datafield: 'lot_count_modifier', width: 70 },
                  	{ text: 'lot_count', datafield: 'lot_count', width: 120 },
					{ text: 'current_remarks', datafield: 'current_remarks', width: 100 },
				  	{ text: 'container_unique_id', datafield: 'container_unique_id', width: 70 },
                  	{ text: 'condition', datafield: 'condition', width: 120 },
					{ text: 'part_att_name_1', datafield: 'part_att_name_1', width: 120 },
					{ text: 'part_att_val_1', datafield: 'part_att_val_1', width: 120 },
					{ text: 'part_att_units_1', datafield: 'part_att_units_1', width: 120 },
					{ text: 'part_att_detby_1', datafield: 'part_att_detby_1', width: 120 },
					{ text: 'part_att_madedate_1', datafield: 'part_madedate_1', width: 120 },
					{ text: 'part_att_rem_1', datafield: 'part_att_rem_1', width: 120 },
					{ text: 'part_att_name_2', datafield: 'part_att_name_2', width: 120 },
					{ text: 'part_att_val_2', datafield: 'part_att_val_2', width: 120 },
					{ text: 'part_att_units_2', datafield: 'part_att_units_2', width: 120 },
					{ text: 'part_att_detby_2', datafield: 'part_att_detby_2', width: 120 },
					{ text: 'part_att_madedate_2', datafield: 'part_att_madedate_2', width: 120 },
					{ text: 'part_att_rem_2', datafield: 'part_att_rem_2', width: 120 }
                ]
            });

            $("##csvExport2").jqxButton();

            $("##csvExport2").click(function () {
                $("##grid2").jqxGrid('exportdata', 'csv', 'jqxGrid');
            });
           
        });
    </script>
							<div id="grid2"></div>
							<div class="mt-3 mb-2 d-block float-left w-100">
								<div class="ml-0 float-left">
									<input type="button" value="Export to CSV" id='csvExport2' />
								</div>
							</div>
							<h4 class="h5 mt-3">Columns in red are required; others are optional:</h4>
							<div class="card-columns mb-3">
								<ul class="list-style-disc px-4">
									<li class="text-danger">institution_acronym</li>
									<li class="text-danger">collection_cde</li>
									<li class="text-danger">other_id_type ("catalog number" is OK)</li>
									<li class="text-danger">other_id_number</li>
									<li class="text-danger">part_name</li>
									<li class="text-danger">preserve_method</li>
									<li class="text-danger">disposition</li>
									<li>lot_count_modifier</li>
									<li class="text-danger">lot_count</li>
									<li>current_remarks
										<ul>
											<li>remarks to be added with the new part</li>
										</ul>
									</li>
									<li>remarks to be added with the new part</li>
									<li>container_unique_id
										<ul>
											<li>container unique ID in which to place this part</li>
										</ul>
									</li>

									<li class="text-danger">condition</li>
									<li>part_att_name_1</li>
									<li>part_att_val_1</li>
									<li>part_att_units_1</li>
									<li>part_att_detby_1</li>
									<li>part_att_madedate_1</li>
									<li>part_att_rem_1</li>
									<li>part_att_name_2</li>
									<li>part_att_val_2</li>
									<li>part_att_units_2</li>
									<li>part_att_detby_2</li>
									<li>part_att_madedate_2</li>
									<li>part_att_rem_2</li>
									<li>part_att_name_3</li>
									<li>part_att_val_3</li>
									<li>part_att_units_3</li>
									<li>part_att_detby_3</li>
									<li>part_att_madedate_3</li>
									<li>part_att_rem_3</li>
									<li>part_att_name_4</li>
									<li>part_att_val_4</li>
									<li>part_att_units_4</li>
									<li>part_att_detby_4</li>
									<li>part_att_madedate_4</li>
									<li>part_att_rem_4</li>
									<li>part_att_name_5</li>
									<li>part_att_val_5</li>
									<li>part_att_units_5</li>
									<li>part_att_detby_5</li>
									<li>part_att_madedate_5</li>
									<li>part_att_rem_5</li>
									<li>part_att_name_6</li>
									<li>part_att_val_6</li>
									<li>part_att_units_6</li>
									<li>part_att_detby_6</li>
									<li>part_att_madedate_6</li>
									<li>part_att_rem_6</li>
								</ul>
															<cfform name="atts" method="post" enctype="multipart/form-data" action="BulkloadParts.cfm">
									<input type="hidden" name="Action" value="getFile">
									<input type="file" name="FiletoUpload" size="45">
									<input type="submit" value="Upload this file" class="savBtn"
										onmouseover="this.className='savBtn btnhov'"
										onmouseout="this.className='savBtn'">
									<br><br>
								Character Set: <select name="cSet" id="cSet">
								<option value="windows-1252" selected>windows-1252</option>
								<option value="MacRoman">MacRoman</option>
								<option value="utf-8">utf-8</option>
								<option value="utf-16">utf-16</option>
								<option value="unicode">unicode</option>
							</select>
							
						  </cfform>

			<cfif #action# is "getFile">
			<cfoutput>

				<!---
				<cfset fileContent='institution_acronym,collection_code,other_id_type,other_id_number,part_name,part_modifier,preserve_method,disposition,lot_count,remarks,condition#chr(10)#'>
				<cfset fileContent='#fileContent#"UAM",Mamm,AF,41272,tissues,,"eth,nol",in collection,1," loan s, ubsample (never used).",unchecked#chr(10)#'>
					<cfset fileContent='#fileContent#UAM,Mamm,AF,27727,tissues,,ethanol,in collection,1,"Returned ""load"", comma loan subsample (never used).",unchecked#chr(10)#'>
						<cfset fileContent='#fileContent#UAM,Mamm,AF,36833,tissues,,ethanol,in collection,1,Returned loan subsample (never used).,unchecked#chr(10)#'>
							<cfset fileContent='#fileContent#UAM,Mamm,AF,31499,tissues,,ethanol,in collection,1,,#chr(10)#'>
				-----------got file--------------<br>
				--->
				<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="#cSet#">

				<cfset fileContent=replace(fileContent,"'","''","all")>
				<!---
				--#fileContent#--
				<hr>
				<cfset fileContent=replace(fileContent,chr(13),'chr 13 goes here',"all")>
				--#fileContent#--
				<hr>

				<cfset fileContent=replace(fileContent,chr(10),'chr 10 goes here',"all")>
				--#fileContent#--
				<hr>
				--->
				 <cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />

			 <cfquery name="die" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from cf_temp_parts
			</cfquery>
			<cfset colNames="">
				<cfloop from="1" to ="#ArrayLen(arrResult)#" index="o">
					<cfset colVals="">
						<cfloop from="1"  to ="#ArrayLen(arrResult[o])#" index="i">
							<cfset thisBit=arrResult[o][i]>
							<cfif #o# is 1>
								<cfset colNames="#colNames#,#thisBit#">
							<cfelse>
								<cfset colVals="#colVals#,'#thisBit#'">
							</cfif>
						</cfloop>
					<cfif #o# is 1>
						<cfset colNames=replace(colNames,",","","first")>
					</cfif>
					<cfif len(#colVals#) gt 1>
						<cfset colVals=replace(colVals,",","","first")>
						<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into cf_temp_parts (#colNames#) values (#preservesinglequotes(colVals)#)
						</cfquery>
						insert into cf_temp_parts (#colNames#) values (#preservesinglequotes(colVals)#)
					</cfif>
				</cfloop>
				<cflocation url="BulkloadParts.cfm?action=validate">
			</cfoutput>
			</cfif>
			<!------------------------------------------------------->
			<!------------------------------------------------------->
			<cfif #action# is "validate">
			validate
			<cfoutput>
				<cfquery name="getParentContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set parent_container_id =
					(select container_id from container where container.barcode = cf_temp_parts.CONTAINER_BARCODE)
				</cfquery>
				<cfquery name="validateGotParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Container Barcode not found'
					where CONTAINER_BARCODE is not null and parent_container_id is null
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Invalid part_name'
					where part_name|| '|' ||collection_cde NOT IN (
						select part_name|| '|' ||collection_cde from ctspecimen_part_name
						)
						OR part_name is null
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Invalid preserve_method'
					where preserve_method|| '|' ||collection_cde NOT IN (
						select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method
						)
						OR preserve_method is null
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Invalid new_preserve_method'
					where new_preserve_method|| '|' ||collection_cde NOT IN (
						select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method
						)
						and new_preserve_method is not null
				</cfquery>
				<cfquery name="isValid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Invalid use_existing flag'
						where use_existing not in ('0','1') OR
						use_existing is null
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Invalid container_barcode'
					where container_barcode NOT IN (
						select barcode from container where barcode is not null
						)
					AND container_barcode is not null
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Invalid DISPOSITION'
					where DISPOSITION NOT IN (
						select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP
						)
						OR disposition is null
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Invalid CONTAINER_TYPE'
					where change_container_type NOT IN (
						select container_type from ctcontainer_type
						)
						AND change_container_type is null
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Invalid CONDITION'
					where CONDITION is null
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';invalid lot_count_modifier'
					where lot_count_modifier NOT IN (
						select modifier from ctnumeric_modifiers
						)
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Invalid LOT_COUNT'
					where (
						LOT_COUNT is null OR
						is_number(lot_count) = 0
						)
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set validated_status = validated_status || ';Invalid CHANGED_DATE'
					where isdate(changed_date) = 0
				</cfquery>
				<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select * from cf_temp_parts where validated_status is null
				</cfquery>
				<cfloop query="data">
						<cfif #other_id_type# is "catalog number">
						<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									collection_object_id
								FROM
									cataloged_item,
									collection
								WHERE
									cataloged_item.collection_id = collection.collection_id and
									collection.collection_cde = '#collection_cde#' and
									collection.institution_acronym = '#institution_acronym#' and
									cat_num='#other_id_number#'
							</cfquery>
						<cfelse>
							<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									coll_obj_other_id_num.collection_object_id
								FROM
									coll_obj_other_id_num,
									cataloged_item,
									collection
								WHERE
									coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id and
									cataloged_item.collection_id = collection.collection_id and
									collection.collection_cde = '#collection_cde#' and
									collection.institution_acronym = '#institution_acronym#' and
									other_id_type = '#other_id_type#' and
									display_value = '#other_id_number#'
							</cfquery>
						</cfif>
						<cfif #collObj.recordcount# is 1>
							<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								UPDATE cf_temp_parts SET collection_object_id = #collObj.collection_object_id# ,
								validated_status='VALID'
								where
								key = #key#
							</cfquery>
						<cfelse>
							<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								UPDATE cf_temp_parts SET validated_status =
								validated_status || ';#data.institution_acronym# #data.collection_cde# #data.other_id_type# #data.other_id_number# could not be found.'
								where key = #key#
							</cfquery>
						</cfif>
					</cfloop>
				<!---
						Things that can happen here:
							1) Upload a part that doesn't exist
								Solution: create a new part, optionally put it in a container that they specify in the upload.
							2) Upload a part that already exists
								a) use_existing = 1
									1) part is in a container
										Solution: warn them, create new part, optionally put it in a container that they've specified
									 2) part is NOT already in a container
										Solution: put the existing part into the new container that they've specified or, if
										they haven't specified a new container, ignore this line as it does nothing.
								b) use_existing = 0
									1) part is in a container
										Solution: warn them, create a new part, optionally put it in the container they've specified
									2) part is not in a container
										Solution: same: warning and new part
					---->
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set (validated_status) = (
						select
						decode(parent_container_id,
						0,'NOTE: PART EXISTS',
						'NOTE: PART EXISTS IN PARENT CONTAINER')
						from specimen_part,coll_obj_cont_hist,container, coll_object_remark where
						specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id AND
						coll_obj_cont_hist.container_id = container.container_id AND
						coll_object_remark.collection_object_id(+) = specimen_part.collection_object_id AND
						derived_from_cat_item = cf_temp_parts.collection_object_id AND
						cf_temp_parts.part_name=specimen_part.part_name AND
						cf_temp_parts.preserve_method=specimen_part.preserve_method AND
						nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL')
						group by parent_container_id)
						where validated_status='VALID'
					</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set (parent_container_id) = (
						select container_id
						from container where
						barcode=container_barcode)
						where substr(validated_status,1,5) IN ('VALID','NOTE:')
					</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set (use_part_id) = (
						select min(specimen_part.collection_object_id)
						from specimen_part, coll_object_remark where
						specimen_part.collection_object_id = coll_object_remark.collection_object_id(+) AND
						cf_temp_parts.part_name=specimen_part.part_name and
						cf_temp_parts.preserve_method=specimen_part.preserve_method and
						cf_temp_parts.collection_object_id=specimen_part.derived_from_cat_item and
						nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL'))
						where validated_status like '%NOTE: PART EXISTS%' AND
						use_existing = 1
					</cfquery>
				<cflocation url="BulkloadParts.cfm?action=checkValidate">
			</cfoutput>
			</cfif>
			<!------------------------------------------------------->
			<cfif #action# is "checkValidate">
				<cfoutput>
				<cfquery name="inT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select * from cf_temp_parts
				</cfquery>
				<table border>
					<tr>
						<td>Problem</td>
						<td>institution_acronym</td>
						<td>collection_cde</td>
						<td>OTHER_ID_TYPE</td>
						<td>OTHER_ID_NUMBER</td>
						<td>part_name</td>
						<td>preserve_method</td>
						<td>disposition</td>
						<td>lot_count_modifier</td>
						<td>lot_count</td>
						<td>current_remarks</td>
						<td>condition</td>
						<td>Container_Barcode</td>
						<td>use_existing</td>
						<td>change_container_type</td>
						<td>append_to_remarks</td>
						<td>changed_date</td>
						<td>new_preserve_method</td>
					</tr>
					<cfloop query="inT">
						<tr>
							<td>
								<cfif len(#collection_object_id#) gt 0 and
										(#validated_status# is 'VALID')>
									<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#"
										target="_blank">Specimen</a>
								<cfelseif left(validated_status,5) is 'NOTE:'>
									<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#"
										target="_blank">Specimen</a> (#validated_status#)
								<cfelse>
									#validated_status#
								</cfif>
							</td>
							<td>#institution_acronym#</td>
							<td>#collection_cde#</td>
							<td>#OTHER_ID_TYPE#</td>
							<td>#OTHER_ID_NUMBER#</td>
							<td>#part_name#</td>
							<td>#preserve_method#</td>
							<td>#disposition#</td>
							<td>#lot_count_modifier#</td>
							<td>#lot_count#</td>
							<td>#current_remarks#</td>
							<td>#condition#</td>
							<td>#Container_Barcode#</td>
							<td>#use_existing#</td>
							<td>#change_container_type#</td>
							<td>#append_to_remarks#</td>
							<td>#changed_date#</td>
						</tr>
					</cfloop>
				</table>
				</cfoutput>
				<cfquery name="allValid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) as cnt from cf_temp_parts where substr(validated_status,1,5) NOT IN
						('VALID','NOTE:')
				</cfquery>
				<cfif #allValid.cnt# is 0>
					<a href="BulkloadParts.cfm?action=loadToDb">Load these parts....</a>
				<cfelse>
					You must fix everything above to proceed.
				</cfif>
			</cfif>
			<!-------------------------------------------------------------------------------------------->
			<cfif #action# is "loadToDb">

			<cfoutput>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select * from cf_temp_parts
				</cfquery>
				<cfquery name= "getEntBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT agent_id FROM agent_name WHERE agent_name = '#session.username#'
				</cfquery>
				<cfif getEntBy.recordcount is 0>
					<cfabort showerror = "You aren't a recognized agent!">
				<cfelseif getEntBy.recordcount gt 1>
					<cfabort showerror = "Your login has has multiple matches.">
				</cfif>
				<cfset enteredbyid = getEntBy.agent_id>
				<cftransaction>
				<cfloop query="getTempData">
				<cfif len(#use_part_id#) is 0 <!---AND len(#container_barcode#) gt 0--->>
					<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select sq_collection_object_id.nextval NEXTID from dual
					</cfquery>
					<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO coll_object (
							COLLECTION_OBJECT_ID,
							COLL_OBJECT_TYPE,
							ENTERED_PERSON_ID,
							COLL_OBJECT_ENTERED_DATE,
							LAST_EDITED_PERSON_ID,
							COLL_OBJ_DISPOSITION,
							LOT_COUNT_MODIFIER,
							LOT_COUNT,
							CONDITION,
							FLAGS )
						VALUES (
							#NEXTID.NEXTID#,
							'SP',
							#enteredbyid#,
							sysdate,
							#enteredbyid#,
							'#DISPOSITION#',
							'#lot_count_modifier#',
							#lot_count#,
							'#condition#',
							0 )
					</cfquery>
					<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO specimen_part (
							  COLLECTION_OBJECT_ID,
							  PART_NAME,
							  PRESERVE_METHOD,
							  DERIVED_FROM_cat_item )
							VALUES (
								#NEXTID.NEXTID#,
							  '#PART_NAME#',
							  '#PRESERVE_METHOD#'
								,#collection_object_id# )
					</cfquery>
					<cfif len(#current_remarks#) gt 0>
							<!---- new remark --->
							<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
								VALUES (sq_collection_object_id.currval, '#current_remarks#')
							</cfquery>
					</cfif>
					<cfif len(#changed_date#) gt 0>
						<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update SPECIMEN_PART_PRES_HIST set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') where collection_object_id =#NEXTID.NEXTID# and is_current_fg = 1
						</cfquery>
					</cfif>
					<cfif len(#container_barcode#) gt 0>
						<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select container_id from coll_obj_cont_hist where collection_object_id = #NEXTID.NEXTID#
						</cfquery>
							<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update container set parent_container_id=#parent_container_id#
								where container_id = #part_container_id.container_id#
							</cfquery>
						<cfif #len(change_container_type)# gt 0>
							<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update container set
								container_type='#change_container_type#'
								where container_id=#parent_container_id#
							</cfquery>
						</cfif>
					</cfif>
				<cfelse>
				<!--- there is an existing matching container that is not in a parent_container;
					all we need to do is move the container to a parent IF it exists and is specified, or nothing otherwise --->
					<cfif len(#disposition#) gt 0>
						<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update coll_object set COLL_OBJ_DISPOSITION = '#disposition#' where collection_object_id = #use_part_id#
						</cfquery>
					</cfif>
					<cfif len(#condition#) gt 0>
						<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update coll_object set condition = '#condition#' where collection_object_id = #use_part_id#
						</cfquery>
					</cfif>
					<cfif len(#lot_count#) gt 0>
						<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update coll_object set lot_count = #lot_count#, lot_count_modifier='#lot_count_modifier#' where collection_object_id = #use_part_id#
						</cfquery>
					</cfif>
					<cfif len(#new_preserve_method#) gt 0>
						<cfquery name="change_preservemethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update SPECIMEN_PART set PRESERVE_METHOD = '#NEW_PRESERVE_METHOD#' where collection_object_id =#use_part_id#
						</cfquery>
					</cfif>
					<cfif len(#append_to_remarks#) gt 0>
						<cfquery name="remarksCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select * from coll_object_remark where collection_object_id = #use_part_id#
						</cfquery>
						<cfif remarksCount.recordcount is 0>
							<cfquery name="insertRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
								VALUES (#use_part_id#, '#append_to_remarks#')
							</cfquery>
						<cfelse>
							<cfquery name="updateRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update coll_object_remark
								set coll_object_remarks = DECODE(coll_object_remarks, null, '#append_to_remarks#', coll_object_remarks || '; #append_to_remarks#')
								where collection_object_id = #use_part_id#
							</cfquery>
						</cfif>
					</cfif>
					<cfif len(#container_barcode#) gt 0>
						<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select container_id from coll_obj_cont_hist where collection_object_id = #use_part_id#
						</cfquery>
							<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update container set parent_container_id=#parent_container_id#
								where container_id = #part_container_id.container_id#
							</cfquery>
						<cfif #len(change_container_type)# gt 0>
							<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update container set
								container_type='#change_container_type#'
								where container_id=#parent_container_id#
							</cfquery>
						</cfif>
					</cfif>
					<cfif len(#changed_date#) gt 0>
						<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update SPECIMEN_PART_PRES_HIST set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') where collection_object_id =#use_part_id# and is_current_fg = 1
						</cfquery>
					</cfif>
				</cfif>
				</cfloop>
				</cftransaction>

				Spiffy, all done.
				<a href="/SpecimenResults.cfm?collection_object_id=#valuelist(getTempData.collection_object_id)#">
					See in Specimen Results
				</a>
			</cfoutput>
			</cfif>
							</div>
						</div>
					</div>
				</div>	<!---1--->
				<div class="card">
					<div class="card-header" id="headingTwo">
				  <h2 class="h4 my-1 px-3">
					<a class="btn-link text-left collapsed" name="editParts" data-toggle="collapse" data-target="##collapseTwo" aria-expanded="false" aria-controls="collapseTwo">
					  &nbsp;Edit Parts
					</a>
				  </h2>
				</div>
					<div id="collapseTwo" class="collapse" aria-labelledby="headingTwo" data-parent="##accordionExample">
				  		<div class="card-body px-4">
					  <h3 class="h4">Update existing part and/or append remark to existing remarks.</h3>
							<p>Upload a comma-delimited text file (csv). Delete the columns that are not needed on the downloaded csv file.</p>
						<script>
							function generatedata3(rowscount, hasNullValues) {
							// prepare the data
							var data = new Array();
							if (rowscount == undefined) rowscount = 1;
							var institution_acronym = 
								[  
									"MCZ" 
								];
							var collection_cde = 
								[ 
									"collection_cde" 
								];
							var other_id_type = 
								[ 
									"catalog item" 
								];
							var other_id_number = 
								[ 
									"1234" 
								];
							var part_name = 
								[
									"whole animal"
								];
							var preserve_method =
								[ 
									"ethanol"
								];
							var disposition = 
								[  
									"in collection" 
								];
							var lot_count_modifier = 
								[
									">"
								];
							var lot_count = 
								[ 
									"1"
								];
							var current_remarks =
								[ 
									"current remark" 
								];
							var append_to_remarks =
								[
									"appended remarks"
								]
							var container_unique_id =
								[ 
									"label or barcode" 
								];
							var condition =
								[ 
									"good" 
								];
							var changed_date =
								[ 
									"2019-01-01" 
								];
							var new_preserve_method =
								[ 
									"ethanol" 
								];		
							for (var i = 0; i < rowscount; i++) {
								var row = {};       
								row["id"] = i;
								row["institution_acronym"] = institution_acronym;
								row["collection_cde"] = collection_cde;
								row["other_id_type"] = other_id_type;
								row["other_id_number"] = other_id_number;
								row["part_name"] = part_name;
								row["preserve_method"] = preserve_method;
								row["disposition"] = disposition;
								row["lot_count_modifier"] = lot_count_modifier;
								row["lot_count"] = lot_count;
								row["current_remarks"] = current_remarks;
								row["append_to_remarks"] = append_to_remarks;
								row["container_unique_id"] = container_unique_id;
								row["condition"] = condition;
								row["changed_date"] = changed_date;
								row["new_preserve_method"] = new_preserve_method;
								data[i] = row;
							}
							return data;
						}
					  	</script>				     	
  						<script type="text/javascript">
        					$(document).ready(function () {
									// prepare the data
            				var data = generatedata3(1);
            				var source =
									{
										localdata: data,
										datatype: "array",
										datafields:
										[
											{ name: 'institution_acronym', type: 'string' },
											{ name: 'collection_cde', type: 'string' },
											{ name: 'other_id_type', type: 'string' },
											{ name: 'other_id_number', type: 'string' },
											{ name: 'part_name', type: 'string' },
											{ name: 'preserve_method', type: 'string' },
											{ name: 'disposition', type: 'string' },
											{ name: 'lot_count_modifier', type: 'string' },
											{ name: 'lot_count', type: 'string' },
											{ name: 'current_remarks', type: 'string' },
											{ name: 'append_to_remarks', type: 'string' },
											{ name: 'container_unique_id', type: 'string' },
											{ name: 'condition', type: 'string' },
											{ name: 'changed_date', type: 'string' },
											{ name: 'new_preserve_method', type: 'string' }

										]                     
									};
									var dataAdapter = new $.jqx.dataAdapter(source);
									// initialize jqxGrid
									$("##grid3").jqxGrid(
									{
										width: '100%',
										autoheight: 'true',
										source: dataAdapter,                
										altrows: true,
										sortable: false,
										columnsresize: true,
										selectionmode: 'multiplecellsextended',
										columns: [
											{ text: 'institution_acronym', datafield: 'institution_acronym', width: 90 },
											{ text: 'collection_cde', datafield: 'collection_cde', width: 115 },
											{ text: 'other_id_type', datafield: 'other_id_type', width: 90 },
											{ text: 'other_id_number', datafield: 'other_id_number', width: 90 },
											{ text: 'part_name', datafield: 'part_name', width: 80 },
											{ text: 'preserve_method', datafield: 'preserve_method', width: 90 },
											{ text: 'disposition', datafield: 'disposition', width: 70 },
											{ text: 'lot_count_modifier', datafield: 'lot_count_modifier', width: 70 },
											{ text: 'lot_count', datafield: 'lot_count', width: 120 },
											{ text: 'current_remarks', datafield: 'current_remarks', width: 200 },
											{ text: 'append_to_remarks', datafield: 'append_to_remarks', width: 200 },
											{ text: 'container_unique_id', datafield: 'container_unique_id', width: 70 },
											{ text: 'condition', datafield: 'condition', width: 120 },
											{ text: 'changed_date', datafield: 'changed_date', width: 120 },
											{ text: 'new_preserved_method', datafield: 'new_preserved_method', width: 120 }

										]
									});

									$("##csvExport3").jqxButton();

									$("##csvExport3").click(function () {
										$("##grid3").jqxGrid('exportdata', 'csv', 'jqxGrid');
									});

								});
    						</script>
							<div id="grid3"></div>
							<div class="mt-3 mb-2 d-block float-left w-100">
								<div class="ml-0 float-left">
									<input type="button" value="Export to CSV" id="csvExport3" />
								</div>
							</div>
					  		<h4 class="h5 px-3">Columns in red are required; others are optional:</h4>
							<div class="card-columns mb-3">							
								<ul class="list-style-disc px-4">
									<li class="text-danger">INSTITUTION_ACRONYM</li>
									<li class="text-danger">COLLECTION_CDE</li>
									<li class="text-danger">OTHER_ID_TYPE ("catalog number" is OK)</li>
									<li class="text-danger">OTHER_ID_NUMBER</li>
									<li class="text-danger">PART_NAME</li>
									<li class="text-danger">PRESERVE_METHOD</li>
									<li class="text-danger">DISPOSITION</li>
									<li>LOT_COUNT_MODIFIER</li>
									<li class="text-danger">LOT_COUNT</li>
									<li>CONTAINER_UNIQUE_ID
										<ul><li>Container unique ID in which to place this part</li></ul>
									</li>
									<li>CURRENT_REMARKS
										<ul>
											<li>Notes in the remarks field on the specimen record now. Copy and paste into the spreadsheet if possible. They must match the remarks on the record.</li>
										</ul>
									</li>
									<li>APPEND_TO_REMARKS
										<ul><li>Anything in this field will be appended to the current remarks.  It will automatically be separated by a colon.</li></ul>
									</li>
									<li>CONTAINER_UNIQUE_ID
										<ul><li>Container unique ID in which to place this part</li></ul>
									</li>
									<li class="text-danger">CONDITION</li>						
									<li>CHANGED_DATE
										<ul><li>If the date the part preservation was changed is different than today, use this field to mark the preservation history correctly, otherwise leave blank. Format = YYYY-MM-DD</li></ul>
									</li>
									<li>NEW_PRESERVE_METHOD
										<ul><li>The value in this field will replace the current preserve method for this part</li></ul>
									</li>
								</ul>
							</div>
				  </div>
					</div>
				</div>	<!---2--->
				<div class="card">
				<div class="card-header" id="headingFour">
				  <h2 class="h4 my-1 px-3">
					<a class="btn-link text-left collapsed"  data-toggle="collapse" data-target="##collapseFour" aria-expanded="false" aria-controls="collapseFour"> &nbsp;Bulk Add Citations
					</a>
				  </h2>
				</div>
				<div id="collapseFour" class="collapse" aria-labelledby="headingFour" data-parent="##accordionExample">
				  <div class="card-body px-4">
					  <h3 class="h5">Bulkload Citations</h3>
					<p>Upload a comma-delimited text file (csv). Delete the columns that are not needed on the downloaded csv file.</p>
						<script>
							function generatedata4(rowscount, hasNullValues) {
							// prepare the data
							var data = new Array();
							if (rowscount == undefined) rowscount = 1;
							var institution_acronym = 
								[  
									"MCZ" 
								];
							var collection_cde = 
								[ 
									"collection_cde" 
								];
							var other_id_type = 
								[ 
									"catalog item" 
								];
							var other_id_number = 
								[ 
									"1234" 
								];
							var part_name = 
								[
									"whole animal"
								];
							var preserve_method =
								[ 
									"ethanol"
								];
							var disposition = 
								[  
									"in collection" 
								];
							var lot_count_modifier = 
								[
									">"
								];
							var lot_count = 
								[ 
									"1"
								];
							var current_remarks =
								[ 
									"current remark" 
								];
							var append_to_remarks =
								[
									"appended remarks"
								]
							var container_unique_id =
								[ 
									"label or barcode" 
								];
							var condition =
								[ 
									"good" 
								];
							var changed_date =
								[ 
									"2019-01-01" 
								];
							var new_preserve_method =
								[ 
									"ethanol" 
								];		
							for (var i = 0; i < rowscount; i++) {
								var row = {};       
								row["id"] = i;
								row["institution_acronym"] = institution_acronym;
								row["collection_cde"] = collection_cde;
								row["other_id_type"] = other_id_type;
								row["other_id_number"] = other_id_number;
								row["part_name"] = part_name;
								row["preserve_method"] = preserve_method;
								row["disposition"] = disposition;
								row["lot_count_modifier"] = lot_count_modifier;
								row["lot_count"] = lot_count;
								row["current_remarks"] = current_remarks;
								row["append_to_remarks"] = append_to_remarks;
								row["container_unique_id"] = container_unique_id;
								row["condition"] = condition;
								row["changed_date"] = changed_date;
								row["citation_remarks"] = citation_remarks;
								data[i] = row;
							}
							return data;
						}
					  	</script>				     	
  						<script type="text/javascript">
        					$(document).ready(function () {
									// prepare the data
            				var data = generatedata4(1);
            				var source =
									{
										localdata: data,
										datatype: "array",
										datafields:
										[
											{ name: 'institution_acronym', type: 'string' },
											{ name: 'collection_cde', type: 'string' },
											{ name: 'other_id_type', type: 'string' },
											{ name: 'other_id_number', type: 'string' },
											{ name: 'publication_title', type: 'string' },
											{ name: 'publication_id', type: 'string' },
											{ name: 'occurs_page_number', type: 'string' },
											{ name: 'citation_page_uri', type: 'string' },
											{ name: 'type_status', type: 'string' },
											{ name: 'citation_remarks', type: 'string' }

										]                     
									};
									var dataAdapter = new $.jqx.dataAdapter(source);
									// initialize jqxGrid
									$("##grid4").jqxGrid(
									{
										width: '100%',
										autoheight: 'true',
										source: dataAdapter,                
										altrows: true,
										sortable: false,
										columnsresize: true,
										selectionmode: 'multiplecellsextended',
										columns: [
											{ text: 'institution_acronym', datafield: 'institution_acronym', width: 60 },
											{ text: 'collection_cde', datafield: 'collection_cde', width: 60 },
											{ text: 'other_id_type', datafield: 'other_id_type', width: 100 },
											{ text: 'other_id_number', datafield: 'other_id_number', width: 100 },
											{ text: 'publication_title', datafield: 'publication_title', width: 200 },
											{ text: 'publication_id', datafield: 'publication_id', width: 70 },
											{ text: 'occurs_page_number', datafield: 'occurs_page_number', width: 70 },
											{ text: 'citation_page_uri', datafield: 'citation_page_uri', width: 200 },
											{ text: 'type_status', datafield: 'type_status', width: 120 },
											{ text: 'citation_remarks', datafield: 'citation_remarks', width: 200 }

										]
									});

									$("##csvExport4").jqxButton();

									$("##csvExport4").click(function () {
										$("##grid4").jqxGrid('exportdata', 'csv', 'jqxGrid');
									});

								});
    						</script>
							<div id="grid4"></div>
							<div class="mt-3 mb-2 d-block float-left w-100">
								<div class="ml-0 float-left">
									<input type="button" value="Export to CSV" id="csvExport3" />
								</div>
							</div>
					  		<h4 class="h5 px-3">Columns in red are required; others are optional:</h4>
						<ul>
							<li class="text-danger">INSTITUTION_ACRONYM</li>
							<li class="text-danger">COLLECTION_CDE</li>
							<li class="text-danger">OTHER_ID_TYPE ("catalog number" is OK)</li>
							<li class="text-danger">OTHER_ID_NUMBER</li>
							<li>PUBLICATION_TITLE (You must include either a Publication Title OR a Publication ID)</li>
							<li>PUBLICATION_ID</li>
							<li class="text-danger">CITED_SCIENTIFIC_NAME</li>
							<li>OCCURS_PAGE_NUMBER</li>
							<li>CITATION_PAGE_URI</li>
							<li class="text-danger">TYPE_STATUS</li>
							<li class="text-danger">CITATION_REMARKS</li>
						</ul>
				  </div>
				</div>
				</div>	<!---4--->
				<div class="card">
					<div class="card-header" id="headingFive">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseFive" aria-expanded="false" aria-controls="collapseFive"> &nbsp;Bulk Add Identifiers
						</a>
					  </h2>
					</div>
					<div id="collapseFive" class="collapse" aria-labelledby="headingFive" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				</div>	<!---5--->
				<div class="card">
					<div class="card-header" id="headingSix">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed"  data-toggle="collapse" data-target="##collapseSix" aria-expanded="false" aria-controls="collapseSix"> &nbsp;Bulk Add Loans		</a>
					  </h2>
					</div>
					<div id="collapseSix" class="collapse" aria-labelledby="headingSix" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				 </div>	<!---6--->
				<div class="card">
					<div class="card-header" id="headingSeven">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed"  data-toggle="collapse" data-target="##collapseSeven" aria-expanded="false" aria-controls="collapseSeven"> &nbsp;Add Data Loans
						</a>
					  </h2>
					</div>
					<div id="collapseSeven" class="collapse" aria-labelledby="headingSeven" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
			  </div>	<!---7--->
				<div class="card">
					<div class="card-header" id="headingEight">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseEight" aria-expanded="false" aria-controls="collapseEight"> &nbsp;Bulk Add Agents
						</a>
					  </h2>
					</div>
					<div id="collapseEight" class="collapse" aria-labelledby="headingEight" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
			  </div>	<!---8--->					
				<div class="card">
					<div class="card-header" id="headingNine">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseNine" aria-expanded="false" aria-controls="collapseNine"> &nbsp;Add Part Containers
						</a>
					  </h2>
					</div>
					<div id="collapseNine" class="collapse" aria-labelledby="headingNine" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
			  </div>	<!---9--->
				<div class="card">
					<div class="card-header" id="headingTen">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseTen" aria-expanded="false" aria-controls="collapseTen"> &nbsp;Bulk Add Identifications
						</a>
					  </h2>
					</div>
					<div id="collapseTen" class="collapse" aria-labelledby="headingTen" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
			  </div>	<!---10--->
				<div class="card">
					<div class="card-header" id="headingEleven">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseEleven" aria-expanded="false" aria-controls="collapseEleven"> &nbsp;Edit or Move Parts 	</a>
					  </h2>
					</div>
					<div id="collapseEleven" class="collapse" aria-labelledby="headingEleven" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
			  </div>	<!---11--->
				<div class="card">
				<div class="card-header" id="headingSeventeen">
				  <h2 class="h4 my-1 px-3">
					<a class="btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseSeventeen" aria-expanded="false" aria-controls="collapseSeventeen"> &nbsp;Add Media 
					</a>
				  </h2>
				</div>
				<div id="collapseSeventeen" class="collapse" aria-labelledby="headingSeventeen" data-parent="##accordionExample">
				  <div class="card-body px-4">
					Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
				  </div>
				</div>
			  </div>	<!---12--->	
				<div class="card">
					<div class="card-header" id="headingThirteen">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseThirteen" aria-expanded="false" aria-controls="collapseThirteen"> &nbsp;Add Biological or Administrative Record Relationships
						</a>
					  </h2>
					</div>
					<div id="collapseThirteen" class="collapse" aria-labelledby="headingThirteen" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
			  </div>	<!---13--->			
				<div class="card">
					<div class="card-header" id="headingFourteen">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseFourteen" aria-expanded="false" aria-controls="collapseFourteen">
						  &nbsp;Bulk Add Georeferences 
						</a>
					  </h2>
					</div>
					<div id="collapseFourteen" class="collapse" aria-labelledby="headingFourteen" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
			  </div>	<!---14--->				
				<div class="card">
					<div class="card-header" id="headingFifteen">
					  <h2 class="h4 my-1 px-3">
						<a class="btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseFifteen" aria-expanded="false" aria-controls="collapseFifteen">
						 &nbsp;Add or Edit Taxonomy
						</a>
					  </h2>
					</div>
					<div id="collapseFifteen" class="collapse" aria-labelledby="headingFifteen" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
			  </div>	<!---15--->
			</div>
		</div>
	</section>
</main>
	</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
