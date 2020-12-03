<cfset pageTitle = "Batch Tools">
<cfinclude template = "/shared/_header.cfm">
<script type="text/javascript" src="/lib/JQWidgets/jqwidgets_ver9.1.6/scripts/demos.js"></script> 
<script>
	function generatedata(rowscount, hasNullValues) {
    // prepare the data
    var data = new Array();
    if (rowscount == undefined) rowscount = 100;
    var firstNames =
    [
        "Andrew", "Nancy", "Shelley", "Regina", "Yoshi", "Antoni", "Mayumi", "Ian", "Peter", "Lars", "Petra", "Martin", "Sven", "Elio", "Beate", "Cheryl", "Michael", "Guylene"
    ];

    var lastNames =
    [
        "Fuller", "Davolio", "Burke", "Murphy", "Nagase", "Saavedra", "Ohno", "Devling", "Wilson", "Peterson", "Winkler", "Bein", "Petersen", "Rossi", "Vileid", "Saylor", "Bjorn", "Nodier"
    ];

    var productNames =
    [
        "Black Tea", "Green Tea", "Caffe Espresso", "Doubleshot Espresso", "Caffe Latte", "White Chocolate Mocha", "Caramel Latte", "Caffe Americano", "Cappuccino", "Espresso Truffle", "Espresso con Panna", "Peppermint Mocha Twist"
    ];

    var priceValues =
    [
         "2.25", "1.5", "3.0", "3.3", "4.5", "3.6", "3.8", "2.5", "5.0", "1.75", "3.25", "4.0"
    ];

    for (var i = 0; i < rowscount; i++) {
        var row = {};
        var productindex = Math.floor(Math.random() * productNames.length);
        var price = parseFloat(priceValues[productindex]);
        var quantity = 1 + Math.round(Math.random() * 10);

        row["id"] = i;
        row["available"] = productindex % 2 == 0;
        if (hasNullValues == true) {
            if (productindex % 2 != 0) {
                var random = Math.floor(Math.random() * rowscount);
                row["available"] = i % random == 0 ? null : false;
            }
        }
        row["firstname"] = firstNames[Math.floor(Math.random() * firstNames.length)];
        row["lastname"] = lastNames[Math.floor(Math.random() * lastNames.length)];
        row["name"] = row["firstname"] + " " + row["lastname"]; 
        row["productname"] = productNames[productindex];
        row["price"] = price;
        row["quantity"] = quantity;
        row["total"] = price * quantity;

        var date = new Date();
        date.setFullYear(date.getFullYear(), Math.floor(Math.random() * 12), Math.floor(Math.random() * 27));
        date.setHours(0, 0, 0, 0);
        row["date"] = date;
       
        data[i] = row;
    }

    return data;
}
function generatecarsdata() {
     var makes = [{ value:"", label: "Any"}, 
        {value:"140", label: "Abarth"},      
        {value:"375", label: "Acura"},      
        {value:"800", label: "Aixam"},      
        {value:"900", label: "Alfa Romeo"},      
        {value:"1100", label: "Alpina"},      
        {value:"121", label: "Artega"},      
        {value:"1750", label: "Asia Motors"},      
        {value:"1700", label: "Aston Martin"},      
        {value:"1900", label: "Audi"},      
        {value:"2000", label: "Austin"},      
        {value:"1950", label: "Austin Healey"},      
        {value:"3100", label: "Bentley"},      
        {value:"3500", label: "BMW"},      
        {value:"3850", label: "Borgward"},      
        {value:"4025", label: "Brilliance"},      
        {value:"4350", label: "Bugatti"},      
        {value:"4400", label: "Buick"},      
        {value:"4700", label: "Cadillac"},      
        {value:"112", label: "Casalini"},      
        {value:"5300", label: "Caterham"},      
        {value:"5600", label: "Chevrolet"},      
        {value:"5700", label: "Chrysler"},      
        {value:"5900", label: "Citroën"},      
        {value:"6200", label: "Cobra"},      
        {value:"6325", label: "Corvette"},      
        {value:"6600", label: "Dacia"},      
        {value:"6800", label: "Daewoo"},      
        {value:"7000", label: "Daihatsu"},      
        {value:"7400", label: "DeTomaso"},      
        {value:"7700", label: "Dodge"},      
        {value:"8600", label: "Ferrari"},      
        {value:"8800", label: "Fiat"},      
        {value:"172", label: "Fisker"},      
        {value:"9000", label: "Ford"},      
        {value:"9900", label: "GMC"},      
        {value:"122", label: "Grecav"},      
        {value:"10850", label: "Holden"},      
        {value:"11000", label: "Honda"},      
        {value:"11050", label: "Hummer"},      
        {value:"11600", label: "Hyundai"},      
        {value:"11650", label: "Infiniti"},      
        {value:"11900", label: "Isuzu"},      
        {value:"12100", label: "Iveco"},      
        {value:"12400", label: "Jaguar"},      
        {value:"12600", label: "Jeep"},      
        {value:"13200", label: "Kia"},      
        {value:"13450", label: "Königsegg"},      
        {value:"13900", label: "KTM"},      
        {value:"14400", label: "Lada"},      
        {value:"14600", label: "Lamborghini"},      
        {value:"14700", label: "Lancia"},      
        {value:"14800", label: "Land Rover"},      
        {value:"14845", label: "Landwind"},      
        {value:"15200", label: "Lexus"},      
        {value:"15400", label: "Ligier"},      
        {value:"15500", label: "Lincoln"},      
        {value:"15900", label: "Lotus"},      
        {value:"16200", label: "Mahindra"},      
        {value:"16600", label: "Maserati"},      
        {value:"16700", label: "Maybach"},      
        {value:"16800", label: "Mazda"},      
        {value:"137", label: "McLaren"},      
        {value:"17200", label: "Mercedes-Benz"},      
        {value:"17300", label: "MG"},      
        {value:"30011", label: "Microcar"},      
        {value:"17500", label: "MINI"},      
        {value:"17700", label: "Mitsubishi"},      
        {value:"17900", label: "Morgan"},      
        {value:"18700", label: "Nissan"},      
        {value:"18875", label: "NSU"},      
        {value:"18975", label: "Oldsmobile"},      
        {value:"19000", label: "Opel"},      
        {value:"149", label: "Pagani"},      
        {value:"19300", label: "Peugeot"},      
        {value:"19600", label: "Piaggio"},      
        {value:"19800", label: "Plymouth"},      
        {value:"20000", label: "Pontiac"},      
        {value:"20100", label: "Porsche"},      
        {value:"20200", label: "Proton"},      
        {value:"20700", label: "Renault"},      
        {value:"21600", label: "Rolls Royce"},      
        {value:"21700", label: "Rover"},      
        {value:"125", label: "Ruf"},      
        {value:"21800", label: "Saab"},      
        {value:"22000", label: "Santana"},      
        {value:"22500", label: "Seat"},      
        {value:"22900", label: "Skoda"},      
        {value:"23000", label: "Smart"},      
        {value:"100", label: "Spyker"},      
        {value:"23100", label: "Ssangyong"},      
        {value:"23500", label: "Subaru"},      
        {value:"23600", label: "Suzuki"},      
        {value:"23800", label: "Talbot"},      
        {value:"23825", label: "Tata"},      
        {value:"135", label: "Tesla"},      
        {value:"24100", label: "Toyota"},      
        {value:"24200", label: "Trabant"},      
        {value:"24400", label: "Triumph"},      
        {value:"24500", label: "TVR"},      
        {value:"25200", label: "Volkswagen"},      
        {value:"25100", label: "Volvo"},      
        {value:"25300", label: "Wartburg"},      
        {value:"113", label: "Westfield"},      
        { value: "25650", label: "Wiesmann" }];

      var fuelType = ["Any", "Diesel", "Electric", "Ethanol (FFV, E85, etc.)", "Gas", "LPG", "Natural Gas", "Hybrid", "Hydrogen", "Petrol"];
      var vehicleType = ["Saloon", "Small Car", "Estate Car", "Van / Minibus", "Off-road Vehicle/Pickup Truck", "Cabriolet / Roadster", "Sports Car/Coupe"];
      var power =
      [
        {value:"24", label: "24 kW (33 PS)"},
        {value:"36", label: "36 kW (49 PS)"},
        {value:"43", label: "43 kW (58 PS)"},
        {value:"54", label: "54 kW (73 PS)"},
        {value:"65", label: "65 kW (88 PS)"},
        {value:"73", label: "73 kW (99 PS)"},
        {value:"86", label: "86 kW (117 PS)"},
        {value:"95", label: "95 kW (129 PS)"},
        {value:"109", label: "109 kW (148 PS)"},
        {value:"146", label: "146 kW (199 PS)"},
        {value:"184", label: "184 kW (250 PS)"},
        {value:"222", label: "222 kW (302 PS)"},
        {value:"262", label: "262 kW (356 PS)"},
        {value:"295", label: "295 kW (401 PS)"},
        {value:"333", label: "333 kW (453 PS)"}
      ];

      var data = new Array();
      for (var i = 0; i < makes.length; i++) {
          var row = {};
          row.make = makes[i].label;
          row.fuelType = fuelType[Math.floor(Math.random() * fuelType.length)];
          row.vehicleType = vehicleType[Math.floor(Math.random() * vehicleType.length)];
          var powerIndex = Math.floor(Math.random() * power.length);
          if (powerIndex == power.length - 1) powerIndex --;
          row.powerFrom = power[powerIndex];
          row.powerTo = power[powerIndex + 1];
          data.push(row);
      }
      return data;
}
	</script>
<cfoutput>
<main class="container py-3">
	<section class="row">
		<div class="col-12">
			<h1 class="h2">Batch Tools</h1>

    	
    <script type="text/javascript">
        $(document).ready(function () {
            // prepare the data
            var data = generatedata(100);

            var source =
            {
                localdata: data,
                datatype: "array",
                datafields:
                [
                    { name: 'firstname', type: 'string' },
                    { name: 'lastname', type: 'string' },
                    { name: 'productname', type: 'string' },
                    { name: 'available', type: 'bool' },
                    { name: 'date', type: 'date' },
                    { name: 'quantity', type: 'number' },
                    { name: 'price', type: 'number' }
                ]                     
            };

            var dataAdapter = new $.jqx.dataAdapter(source);

            // initialize jqxGrid
            $("##grid").jqxGrid(
            {
                width: getWidth('Grid'),
                source: dataAdapter,                
                altrows: true,
                sortable: true,
                selectionmode: 'multiplecellsextended',
                columns: [
                  { text: 'First Name', datafield: 'firstname', width: 130 },
                  { text: 'Last Name', datafield: 'lastname', width: 130 },
                  { text: 'Product', datafield: 'productname', width: 200 },
                  { text: 'Available', datafield: 'available', columntype: 'checkbox', width: 67, cellsalign: 'center', align: 'center' },
                  { text: 'Ship Date', datafield: 'date', width: 120, align: 'right', cellsalign: 'right', cellsformat: 'd' },
                  { text: 'Quantity', datafield: 'quantity', width: 70, align: 'right', cellsalign: 'right' },
                  { text: 'Price', datafield: 'price', cellsalign: 'right', align: 'right', cellsformat: 'c2' }
                ]
            });

            $("##excelExport").jqxButton();
            $("##xmlExport").jqxButton();
            $("##csvExport").jqxButton();
            $("##tsvExport").jqxButton();
            $("##htmlExport").jqxButton();
            $("##jsonExport").jqxButton();
            $("##pdfExport").jqxButton();

            $("##excelExport").click(function () {
                $("##grid").jqxGrid('exportdata', 'xlsx', 'jqxGrid');           
            });
            $("##xmlExport").click(function () {
                $("##grid").jqxGrid('exportdata', 'xml', 'jqxGrid');
            });
            $("##csvExport").click(function () {
                $("##grid").jqxGrid('exportdata', 'csv', 'jqxGrid');
            });
            $("##tsvExport").click(function () {
                $("##grid").jqxGrid('exportdata', 'tsv', 'jqxGrid');
            });
            $("##htmlExport").click(function () {
                $("##grid").jqxGrid('exportdata', 'html', 'jqxGrid');
            });
            $("##jsonExport").click(function () {
                $("##grid").jqxGrid('exportdata', 'json', 'jqxGrid');
            });
            $("##pdfExport").click(function () {
                $("##grid").jqxGrid('exportdata', 'pdf', 'jqxGrid');
            });
        });
    </script>

        <div id="grid"></div>
        <div style='margin-top: 20px;'>
            <div style='float: left;'>
                <input type="button" value="Export to Excel" id='excelExport' />
                <br /><br />
                <input type="button" value="Export to XML" id='xmlExport' />
            </div>
            <div style='margin-left: 10px; float: left;'>
                <input type="button" value="Export to CSV" id='csvExport' />
                <br /><br />
                <input type="button" value="Export to TSV" id='tsvExport' />
            </div>
            <div style='margin-left: 10px; float: left;'>
                <input type="button" value="Export to HTML" id='htmlExport' />
                <br /><br />
                <input type="button" value="Export to JSON" id='jsonExport' />
            </div>
            <div style='margin-left: 10px; float: left;'>
                <input type="button" value="Export to PDF" id='pdfExport' />
            </div>
        </div>

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
							<p>This tool adds attributes to the specimen record. The attribute has to be in the code table prior to uploading this .csv.</p>
							<p><a href="/info/ctDocumentation.cfm?table=ctattribute_type">Attribute List</a></p>
							<p>Columns in red are required; others are optional:</p>
							<ul>
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
