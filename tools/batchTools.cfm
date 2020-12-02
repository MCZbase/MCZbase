<cfset pageTitle = "Batch Tools">
<cfinclude template = "/shared/_header.cfm">
<cfoutput>
<main class="container py-3">
	<section class="row">
		<div class="col-12">
			<h1 class="h2">Batch Tools</h1>
				<div class="accordion" id="accordionExample">
					<div class="card">
					<div class="card-header" id="headingOne">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left" type="button" data-toggle="collapse" data-target="##collapseOne" aria-expanded="true" aria-controls="collapseOne">
						  Add New Parts to Specimen Records
						</button>
					  </h2>
					</div>

					<div id="collapseOne" class="collapse show" aria-labelledby="headingOne" data-parent="##accordionExample">
						<div class="card-body">
							<h3 class="h4">Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below.</h3>
								<p>Columns in red are required; others are optional:</p>
								<ul class="list-style-disc px-4">
									<li>institution_acronym</li>
									<li>collection_cde</li>
									<li>other_id_type ("catalog number" is OK)</li>
									<li>other_id_number</li>
									<li>part_name</li>
									<li>preserve_method</li>
									<li>disposition</li>
									<li>lot_count_modifier</li>
									<li>lot_count</li>
									<li>current_remarks</li>
									<li>Remarks to be added with the new part</li>
									<li>container_unique_id</li>
									<li>Container unique ID in which to place this part</li>
									<li>condition</li>
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
					<div class="card">
					<div class="card-header" id="headingTwo">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseTwo" aria-expanded="false" aria-controls="collapseTwo">
						  Collapsible Group Item
						</button>
					  </h2>
					</div>
					<div id="collapseTwo" class="collapse" aria-labelledby="headingTwo" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
					</div>
					<div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
					</div>
					<div class="card">
					<div class="card-header" id="headingFour">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseFour" aria-expanded="false" aria-controls="collapseFour">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseFour" class="collapse" aria-labelledby="headingFour" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
					</div>
					<div class="card">
						<div class="card-header" id="headingFive">
						  <h2 class="my-0">
							<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseFive" aria-expanded="false" aria-controls="collapseFive">
							  Collapsible Group Item 
							</button>
						  </h2>
						</div>
						<div id="collapseFive" class="collapse" aria-labelledby="headingFive" data-parent="##accordionExample">
						  <div class="card-body">
							Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
						  </div>
						</div>
					</div>
					<div class="card">
						<div class="card-header" id="headingSix">
						  <h2 class="my-0">
							<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseSix" aria-expanded="false" aria-controls="collapseSix">
							  Collapsible Group Item 
							</button>
						  </h2>
						</div>
						<div id="collapseSix" class="collapse" aria-labelledby="headingSIx" data-parent="##accordionExample">
						  <div class="card-body">
							Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
						  </div>
						</div>
					 </div>
					
									  <div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				  </div>
					
									  <div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				  </div>
					
									  <div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				  </div>
					
									  <div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				  </div>
					
									  <div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				  </div>
					
									  <div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				  </div>
					
									  <div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				  </div>
					
									  <div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				  </div>
					
									  <div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				  </div>
					
									  <div class="card">
					<div class="card-header" id="headingThree">
					  <h2 class="my-0">
						<button class="btn btn-link btn-block text-left collapsed" type="button" data-toggle="collapse" data-target="##collapseThree" aria-expanded="false" aria-controls="collapseThree">
						  Collapsible Group Item 
						</button>
					  </h2>
					</div>
					<div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="##accordionExample">
					  <div class="card-body">
						Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid. 3 wolf moon officia aute, non cupidatat skateboard dolor brunch. Food truck quinoa nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua put a bird on it squid single-origin coffee nulla assumenda shoreditch et. Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt sapiente ea proident. Ad vegan excepteur butcher vice lomo. Leggings occaecat craft beer farm-to-table, raw denim aesthetic synth nesciunt you probably haven't heard of them accusamus labore sustainable VHS.
					  </div>
					</div>
				  </div>
				</div>
		</div>
	</section>
</main>
	</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
