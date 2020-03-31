<cfset pageTitle = "Search Form Builder">
<!-- 
searchBuilder.cfm

Copyright 2019 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfinclude template = "/shared/_header.cfm">
<!---HTML5 sortable---https://github.com/lukasoppermann/html5sortable/blob/master/README.md--->
<script type="text/javascript" src="/redesign/searchbuilder/js/searchBuilder.js"></script>
<section class="mb-3 mx-auto col col-12 px-0">
    <div class="p-3 clearfix form-div">
        <div class="col col-md-12 col-sm-12 mb-1">
            <h1 class="smallcaps mx-4">Create a Specimen Search Form</h1>
            <p class="mt-1 mb-3 mx-4">Drag search form fields (rectangles in white background below) to the top three rectangles (gray background) in the order you would like to see them. More than one form field can appear in a column. The selected fields will appear under the default fields:  "Catalog Numbers," "Other IDs," "Any Taxonomy," and "Any Geography" on the search page. Refresh page to empty form.</p>
            <div class="col col-md-3 col-sm-12 mb-3 float-left">
                <ul class="p-2 js-sortable-copy-target js-sortable border-blue-gray rounded sortable-top list flex flex-column list-reset mh-40p">
                </ul>
            </div>
            <div class="col col-md-3 col-sm-12 mb-2 float-left">
                <ul class="p-2 js-sortable-copy-target js-sortable border-blue-gray rounded sortable-top list flex flex-column list-reset mh-40p">
                </ul>
            </div>
            <div class="col col-md-3 col-sm-12 mb-2 float-left">
                <ul class="p-2 border-blue-gray js-sortable-copy-target js-sortable rounded sortable-top list flex flex-column list-reset mh-40p">
                </ul>
            </div>
            <div class="col col-md-3 col-sm-12 my-2 float-left"> <span class="input-group-btn rounded float-left pr-2">
                <button class="btn border-blue-gray js-serialize-button button bg-blue-gray" type="submit"> Save to Search Page <i class="fa fa-search text-body"></i></button>
                </span> </div>
            <div class="form-check col-md-12 col-sm-12 float-right pl-8" style="clear: both;">
                <input type="checkbox" class="form-check-input ml-4" id="exampleCheck1">
                <label class="form-check-label ml-5" for="exampleCheck1">Check to make custom search appear on search page load.</label>
            </div>
        </div>
    </div>
    <div class="px-4">
        <div id="serialize"> 
		    <code>
            <pre class="serialized-content"></pre>
            </code> 
		</div>
    </div>
    <div class="pl-5">
        <div class="col col-md-3 col-sm-12 float-left">
            <ul class="js-sortable-copy sortable list flex flex-column list-reset">
                <h4>Identifiers</h4>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id ="other_id_type">Other ID Type</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="other_id_value">Other ID Value</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="other_id_prefix">Other ID Prefix</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="other_id_suffix">Other ID Suffix</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="accn">Accessions</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="accession_agency">Accession Agency</li>
            </ul>
        </div>
        <div class="col col-md-3 col-sm-12 float-left">
            <ul class="js-sortable-copy sortable list flex flex-column list-reset">
                <h4>Taxonomy</h4>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="scientific_name">Scientific Name</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="phylclass">Class</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="genus">Genus</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="species">Species</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="subspecies">Subspecies</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="nature_of_id">Nature of ID</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="determiner">Determiner</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="id_remarks">ID Remarks</li>
            </ul>
        </div>
        <div class="col col-md-3 col-sm-12 float-left">
            <ul class="js-sortable-copy sortable list flex flex-column list-reset">
                <h4>Higher Geography</h4>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Continent/Ocean</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Country</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">State/Province</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">USGS Quad Map</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">County</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Island Group</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Island</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Land Feature</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Water Feature</li>
            </ul>
        </div>
        <div class="col col-md-3 col-sm-12 float-left">
            <ul class="js-sortable-copy sortable list flex flex-column list-reset">
                <h4>Collecting Event</h4>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="collectors">Collector/Preparator</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="">Years Collected</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="">Collected On or After</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="">Collected On or Before</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="">Month</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="">Verbatim Date</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="">Collecting Source</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="">Verbatim Locality</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="">General Habitat</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray" id="">Microhabitat</li>
            </ul>
        </div>
        <div class="col col-md-3 col-sm-12 float-left">
            <ul class="js-sortable-copy sortable list flex flex-column list-reset">
                <h4>Specific Locality</h4>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Geology Attribute</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Geology Attribute Value</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Traverse Geology HIerarchies</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Specific Locality</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Elevation</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Depth</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Verification Status</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Maximum Uncertainty</li>
            </ul>
        </div>
        <div class="col col-md-3 col-sm-12 float-left">
            <ul class="js-sortable-copy sortable list flex flex-column list-reset">
                <h4>Biological Individual</h4>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Part Name</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Preserve Method</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Relationship</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Part Attribute</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Part Location</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Part Remarks</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Specimen Attribute</li>
            </ul>
        </div>
        <div class="col col-md-3 col-sm-12 float-left">
            <ul class="ml-2 js-sortable-copy sortable list flex flex-column list-reset">
                <h4>Usage</h4>
                <li class="p-1 px-2 mb-1 text-dark bg-light search-form-builder">Basis of Citation</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Media Type</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Project</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Loans</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Accessions</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Accession Agency</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Item 5</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Item 6</li>
            </ul>
        </div>
        <div class="col col-md-3 col-sm-12 float-left">
            <ul class="js-sortable-copy sortable list flex flex-column list-reset">
                <h4>Curatorial</h4>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Barcode/Unique Container ID</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Loan Number</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Issued By</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Permit Issued To</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Permit Type</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Permit Number</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Part Distribution</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Entered By</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Entered Date</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Last Edited By</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Last Edited Date</li>
                <li class="p-1 px-2 mb-1 text-dark bg-light border-gray">Remarks</li>
            </ul>
        </div>
    </div>
</section>
</div>
<script>
	sortable('.js-sortable', {
	itemSerializer: function (item, container) {
		item.parent = '[parentNode]'
		item.node = '[Node]'
		item.html = item.html.replace('<','&lt;')
		return item
		},
	containerSerializer: function (container) {
		container.node = '[Node]'
		return container
		}
	})
	document.querySelector('.js-serialize-button').addEventListener('click', function () {
		let serialized = sortable('.js-sortable', 'serialize')
	document.querySelector('.serialized-content').innerHTML = JSON.stringify(serialized, null, ' ')
	})

	sortable('.js-sortable-copy', {
		forcePlaceholderSize: true,
		copy: true,
		acceptFrom: false,
		placeholderClass: 'mb1 bg-navy border border-yellow',
	});
	sortable('.js-sortable-copy-target', {
		forcePlaceholderSize: true,
		acceptFrom: '.js-sortable-copy,.js-sortable-copy-target',
		placeholderClass: 'mb1 border border-maroon',
	});
	sortable('.js-sortable-buttons', {
		forcePlaceholderSize: true,
		items: 'li'
	});
	// buttons to add items and reload the list
	// separately to showcase issue without reload
	document.querySelector('.js-add-item-button').addEventListener('click', function(){
		doc = new DOMParser().parseFromString(`<li class="p1 mb1 blue bg-white">new item</li>`, "text/html").body.firstChild;
		document.querySelector('.js-sortable-buttons').appendChild(doc);
	});

	document.querySelector('.js-reload').addEventListener('click', function(){
		console.log('Options before re-init:');
		console.log(document.querySelector('.js-sortable-buttons').h5s.data.opts);
		sortable('.js-sortable-buttons');
		console.log('Options after re-init:');
		console.log(document.querySelector('.js-sortable-buttons').h5s.data.opts);
	});
</script>
<cfinclude template = "/shared/_footer.cfm">
