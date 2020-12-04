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
							<cfform name="atts" method="post" class="py-0 alert alert-warning" enctype="multipart/form-data" action="batchTools.cfm">
								<div class="my-4 row">
								<div class="col-12 col-md-4">
									<input type="hidden" name="Action" value="getFile">
									<label class="data-entry-label">Upload the .csv with data</label>
									<input type="file" name="FiletoUpload" size="45" class="data-entry-input pl-0">
									<input type="submit" value="Upload this file" class="btn-xs my-3 btn btn-primary">
								</div>
								<div class="col-12 col-md-3">
									<label class="data-entry-label">Character Set: </label>
							<select name="cSet" class="data-entry-select" id="cSet">
								<option value="windows-1252" selected>windows-1252</option>
								<option value="MacRoman">MacRoman</option>
								<option value="utf-8">utf-8</option>
								<option value="utf-16">utf-16</option>
								<option value="unicode">unicode</option>
							</select>
									</div>
								</div>
							</cfform>
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
							</div>
							<cfform name="atts" method="post" class="py-0 alert alert-warning" enctype="multipart/form-data" action="batchTools.cfm">
								<div class="my-4 row">
								<div class="col-12 col-md-4">
									<input type="hidden" name="Action" value="getFile">
									<label class="data-entry-label">Upload the .csv with data</label>
									<input type="file" name="FiletoUpload" size="45" class="data-entry-input pl-0">
									<input type="submit" value="Upload this file" class="btn-xs my-3 btn btn-primary">
								</div>
								<div class="col-12 col-md-3">
									<label class="data-entry-label">Character Set: </label>
							<select name="cSet" class="data-entry-select" id="cSet">
								<option value="windows-1252" selected>windows-1252</option>
								<option value="MacRoman">MacRoman</option>
								<option value="utf-8">utf-8</option>
								<option value="utf-16">utf-16</option>
								<option value="unicode">unicode</option>
							</select>
									</div>
								</div>
							</cfform>
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
							<cfform name="atts" method="post" class="py-0 alert alert-warning" enctype="multipart/form-data" action="batchTools.cfm">
								<div class="my-4 row">
								<div class="col-12 col-md-4">
									<input type="hidden" name="Action" value="getFile">
									<label class="data-entry-label">Upload the .csv with data</label>
									<input type="file" name="FiletoUpload" size="45" class="data-entry-input pl-0">
									<input type="submit" value="Upload this file" class="btn-xs my-3 btn btn-primary">
								</div>
								<div class="col-12 col-md-3">
									<label class="data-entry-label">Character Set: </label>
									<select name="cSet" class="data-entry-select" id="cSet">
										<option value="windows-1252" selected>windows-1252</option>
										<option value="MacRoman">MacRoman</option>
										<option value="utf-8">utf-8</option>
										<option value="utf-16">utf-16</option>
										<option value="unicode">unicode</option>
									</select>
									</div>
								</div>
							</cfform>
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
