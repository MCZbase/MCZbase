<cfset pageTitle = "Batch Tools">
<cfinclude template = "/shared/_header.cfm">
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/scripts/demos.js"></script> 
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
         "length"
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
         "This is temporary data."
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
<cfoutput>
<main class="container py-3">
	<section class="row">
		<div class="col-12">
			<h1 class="h2">Batch Tools</h1>



			<div class="accordion" id="accordionExample">
				<div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<a class="btn btn-link btn-block text-left collapsed" name="addAttributes" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						 Bulk Add Attributes
						</a>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
						 <div class="card-body px-4">
							<h3 class="h5">Add Attributes to Existing Specimen Records</h3>
							     	
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
                sortable: true,
                selectionmode: 'multiplecellsextended',
                columns: [
                  { text: 'collection_cde', datafield: 'collection_cde', width: 115 },
                  { text: 'institution_acronym', datafield: 'institution_acronym', width: 90 },
                  { text: 'other_id_type', datafield: 'other_id_type', width: 90 },
                  { text: 'other_id_number', datafield: 'other_id_number', width: 90 },
                  { text: 'attribute', datafield: 'attribute', width: 80 },
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
        <div class="my-3 d-block float-left w-100">
			<div class="ml-2 float-left">
                <input type="button" value="Export to CSV" id='csvExport' />
                <br /><br />
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
					  <h2 class="h4 my-0">
						<a class="btn btn-link btn-block text-left" name="addNewParts" data-toggle="collapse" data-target="##collapseOne" aria-expanded="true" aria-controls="collapseOne">
						  Add New Parts to Specimen Records
						</a>
					  </h2>
					</div>
					<div id="collapseOne" class="collapse" aria-labelledby="headingOne" data-parent="##accordionExample">
						<div class="card-body px-4">
							<h3 class="h4">Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below.</h3>
							<label class="data-entry-label">Copy the existing code into an Excel workbook (use data > text to columns to parse) and save as a .csv file</label><textarea class="data-entry-textarea">institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,disposition,lot_count_modifier,lot_count,current_remarks,container_unique_id,condition,part_att_name_1,part_att_val_1,part_att_units_1,part_att_detby_1,part_att_madedate_1,part_att_rem_1,part_att_name_2,part_att_val_2,part_att_units_2,part_att_detby_2,part_att_madedate_2,part_att_rem_2 </textarea>

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
						</div>
						</div>
				</div>	<!---1--->
				<div class="card">
					<div class="card-header" id="headingTwo">
				  <h2 class="h3 my-0">
					<a class="btn btn-link btn-block text-left collapsed" name="editParts" data-toggle="collapse" data-target="##collapseTwo" aria-expanded="false" aria-controls="collapseTwo">
					  Edit Parts
					</a>
				  </h2>
				</div>
					<div id="collapseTwo" class="collapse" aria-labelledby="headingTwo" data-parent="##accordionExample">
				  <div class="card-body px-4">
					  <h3 class="h4">Update existing part and/or append remark to existing remarks.</h3>
						<div class="p-3 text-secondary border">
							<p>Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below.</p>
							<label class="data-entry-label">Copy the existing code into an Excel workbook (use data > text to columns to parse) and save as a .csv file</label>
							<textarea class="data-entry-textarea"> institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,disposition,lot_count_modifier,lot_count,current_remarks,container_unique_id,change_container_type,condition,append_to_remarks,changed_date,new_preserve_method </textarea>
						</div>
					  	<div class="card-columns mb-3">
							<p>Columns in red are required; others are optional:</p>
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
								<li>current_remarks
									<ul>
										<li>Notes in the remarks field on the specimen record now. Copy and paste into the spreadsheet if possible. They must match the remarks on the record.</li>
									</ul>
								</li>
								<li>append_to_remarks
									<ul>
										<li>Anything in this field will be appended to the current remarks. It will be automatically separated by a semicolon.</li>
									</ul>
								</li>
								<li>changed_date
									<ul>
										<li>If the date the part preservation was changed is different than today, use this field to mark the preservation history correctly, otherwise leave blank. Format = YYYY-MM-DD</li>
									</ul>
								</li>

								<li>new_preserve_method
									<ul>
										<li>The value in this field will replace the current preserve method for this part</li>
									</ul>
								</li>
						  	</ul>
					  	</div>
				  </div>
				</div>
				</div>	<!---2--->
			
				<div class="card">
				<div class="card-header" id="headingFour">
				  <h2 class="my-0">
					<a class="btn btn-link btn-block text-left collapsed"  data-toggle="collapse" data-target="##collapseFour" aria-expanded="false" aria-controls="collapseFour">
					  Bulk Add Citations
					</a>
				  </h2>
				</div>
				<div id="collapseFour" class="collapse" aria-labelledby="headingFour" data-parent="##accordionExample">
				  <div class="card-body px-4">
					  <h3 class="h5">Bulkload Citations</h3>
						<p>Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below.</p>
						<ul>
							<li class="text-danger">INSTITUTION_ACRONYM</li>
							<li class="text-danger">COLLECTION_CDE
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
					  <h2 class="my-0">
						<a class="btn btn-link btn-block text-left collapsed" data-toggle="collapse" data-target="##collapseFive" aria-expanded="false" aria-controls="collapseFive">
						 Add Identifiers to Existing Specimen Records
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
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseSix" aria-expanded="false" aria-controls="collapseSix">
						 Add Loans to Existing Specimen Records
						</button>
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
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseSeven" aria-expanded="false" aria-controls="collapseSeven">
						  Add Data Loans to Existing Specimen Records
						</button>
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
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseEight" aria-expanded="false" aria-controls="collapseEight">
						  Add Agents to Existing Specimen Records
						</button>
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
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseNine" aria-expanded="false" aria-controls="collapseNine">
						  Add Part Containers to Existing Specimen Records
						</button>
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
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseTen" aria-expanded="false" aria-controls="collapseTen">
						 Add Identifications to Existing Specimen Records
						</button>
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
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseEleven" aria-expanded="false" aria-controls="collapseEleven">
						 Edit or Move Parts Associated with Specimen Records in Bulk
						</button>
					  </h2>
					</div>
					<div id="collapseEleven" class="collapse" aria-labelledby="headingEleven" data-parent="##accordionExample">
					  <div class="card-body px-4">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
			  </div>	<!---11--->
				<div class="card">
				<div class="card-header" id="headingThree">
				  <h2 class="my-0">
					<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
					  Add Media to Existing Specimen Records
					</button>
				  </h2>
				</div>
				<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
				  <div class="card-body px-4">
					Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
				  </div>
				</div>
			  </div>	<!---12--->	
				<div class="card">
					<div class="card-header" id="headingThirteen">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThirteen" aria-expanded="false" aria-controls="collapseThirteen">
						 Add Biological or Administrative Record Relationships to Existing Specimen Records
						</button>
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
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseFourteen" aria-expanded="false" aria-controls="collapseFourteen">
						  Add Georeferences to Existing Specimen Records
						</button>
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
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseFifteen" aria-expanded="false" aria-controls="collapseFifteen">
						 Add or Edit Taxonomy
						</button>
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
