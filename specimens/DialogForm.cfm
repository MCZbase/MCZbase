<ul class="nav nav-tabs" role="tablist">
<li class="nav-item"><a class="nav-link active" data-toggle="tab" href="##taxa">Taxa</a></li>
<li class="nav-item"><a class="nav-link" data-toggle="tab" role="tab" href="##trans">Transactions</a></li>
<li class="nav-item"><a class="nav-link" data-toggle="tab" role="tab" href="##otherid">Other IDs</a></li>
<li class="nav-item"><a class="nav-link" data-toggle="tab" role="tab" href="##collevent">Collecting Event</a></li>
<li class="nav-item"><a class="nav-link" data-toggle="tab" role="tab" href="##locality1">Locality</a></li>
<li class="nav-item"><a class="nav-link" data-toggle="tab" role="tab" href="##relations">Relations</a></li>
<li class="nav-item"><a class="nav-link" data-toggle="tab" role="tab" href="##parts">Parts <span class="caret"></span></a>
	<ul class="dropdown-menu">
		<li class="nav-item"><a class="nav-link" data-toggle="tab" href="##containers">Containers</a></li>
		<li class="nav-item"><a class="nav-link" data-toggle="tab" href="##barcode">Barcode Lookup</a></li>
		<li class="nav-item"><a class="nav-link" data-toggle="tab" href="##editparts">Edit Parts</a></li>
	</ul>
</li>
<li class="nav-item"><a class="nav-link" data-toggle="tab" href="##attributes">Attributes</a></li>
<li class="nav-item"><a class="nav-link" data-toggle="tab" href="##media">Media</a></li>
<li class="nav-item"><a class="nav-link" data-toggle="tab" href="##encumbrances">Encumbrances</a></li>
</ul>

<div id="dialog-form" title="Edit Locality"> 
<div class="menu-tabs"> 
	<ul>
		<li>Taxa</li><li>Accn &amp; IDs</li><li>Collecting Event</li><li>Locality</li><li>Relations</li><li>Parts</li><li>Attributes</li><li>Media</li><li>Encumbrances</li>
	</ul>
</div>
<table id="static_values">
	<tr>
		<td>
			<label for="higher_geog" class="mt-2">Higher Geography &mdash; &nbsp;</label>
			#getGeo.higher_geog#
		</td>
	</tr>
	<tr>
		<td>
			<label for="verbatim_locality" class="mt-2">Collecting Event: Verbatim Locality &mdash; &nbsp;</label>
			#one.verbatim_locality#
		</td>
	</tr>
	<tr class="bg-white">
		<td>
			<label for="lat_long" class="mt-2">Coordinates for this Locality &mdash; &nbsp;</label>
			#one.dec_lat#, #one.dec_long#
		</td>
	</tr>
</table>
<div class="active_form">
<div class="alert_box">This locality includes:
	<ul>
		<li class="colls"><a>3 mammals</a></li>
		<li class="colls"><a>4 invertebrates (IZ)</a></li>
	</ul>
</div>
	<form name="localityForm" id="localityForm">
		<fieldset>
			<input type="hidden" name="transaction_id" value="#locality_id#" id="shipmentForm_transaction_id" >
			<input type="hidden" name="shipment_id" value="" id="shipment_id">
			<input type="hidden" name="returnFormat" value="json" id="returnFormat">
			<div class="container-fluid">
		  <div class="row">
			 <div class="col-12">
			  <label for="specific_locality" class="mt-3 ml-2">Specific Locality</label>
			  <input type="text" value="#one.spec_locality#" name="spec_locality" id="spec_locality" class="w-100">
			  <label for="sovereign_nation" class="mt-3 ml-2">Sovereign Nation</label>
			  <input type="text" value="" name="sovereign_nation" id="sovereign_nation" class="w-100 mt-0">
			  </div></div>
		  <div class="row">
			<div class="col-lg-4 col-md-4 col-sm-4"> 
			  <label for="minimum_elevation" class="mt-3 ml-2">Minimum Elevation</label>
			  <input type="text" value="" name="minimum_elevation" id="minimum_elevation" >
			  </div>
			   <div class="col-lg-4 col-md-4 col-sm-4"> 
			  <label for="maximum_elevation" class="mt-3 ml-2">Maximum Elevation</label>
			  <input type="text" value="" name="maximum_elevation" id="maximum_elevation">
			  </div>
				 <div class="col-lg-4 col-md-4 col-sm-4"> 
			  <label for="orig_elev_units" class="mt-3 ml-2">Elev. Units</label>
			  <input type="text" value="" name="orig_elev_units" id="orig_elev_units">
			</div>
		  </div>
		<div class="row">
		<div class="col-lg-4 col-md-4 col-sm-4">
			<label for="minimum_elevation" class="mt-3 ml-2">Minimum Depth</label>
			<input type="text" value="" name="minimum_elevation" id="minimum_elevation">
			</div>
			<div class="col-lg-4 col-md-4 col-sm-4">   
				<label for="maximum_elevation" class="mt-3 ml-2">Maximum Depth</label>
				<input type="text" value="" name="maximum_elevation" id="maximum_elevation" >
			</div>
			<div class="col-lg-4 col-md-4 col-sm-4"> 
			<label for="orig_elev_units" class="mt-3 ml-2">Depth Units</label>
			<input type="text" value="" name="orig_elev_units" id="orig_elev_units">
			</div>
		</div>
		</div>
		</fieldset>
		<fieldset>
			<button value="Edit Georeference" type="button" class="ml-1 mt-3">Edit Georeference</button>
		</fieldset>
	</form>
</div>
</div>

<script>
$(function(){

function saveEdits() {
}

var screenWidth, screenHeight, dialogWidth, dialogHeight, isDesktop;
screenWidth = window.screen.width;
screenHeight = window.screen.height;
if ( screenWidth < 1600 ) {
	dialogWidth = '90%';
	dialogHeight = 'auto';
	 isDesktop = false;
} else if ( screenWidth > 1600  ){
	dialogWidth = '46%';
	dialogHeight = 'auto'
	isDesktop = true;
}
dialog = $( "##dialog-form" ).dialog({
	autoOpen: false,
	width: dialogWidth,
	height: dialogHeight,
	maxWidth: 1150,
	fluid: true,
	modal: true,
	resizable: true,
	buttons: {
		"1": { id: 'open', text: 'Save Shared Locality', click: function(){ $(this).dialog("open"); },"class": "save_shared" },
		"2": { id: 'save', text: 'Save Changes for this Record Only', click: function(){ $(this).dialog("save"); }, "class": "save_local" },
		"3": { id: 'close', text: 'Cancel', click: function(){ $(this).dialog("close"); }, "class": "cancel_bk"}
		}
});

form = dialog.find( "form" ).on( "submit", function( event ) {
	event.preventDefault();
	saveEdits();
	// $(window).off("resize.responsive");
});

$( "##edit-locality" ).button().on( "click", function() {
	dialog.dialog( "open" );
	fluidDialog();
});
function fluidDialog() {
var $visible = $(".ui-dialog:visible");
// each open dialog
$visible.each(function () {
	var $this = $(this);
	var dialog = $this.find(".ui-dialog-content").data("dialog");
	console.log(dialog);
	// if fluid option == true
	if (dialog.options.maxWidth && dialog.options.width) {
		// fix maxWidth bug
		$this.css("max-width", dialog.options.maxWidth);
		//reposition dialog
		dialog.option("position", dialog.options.position);
	}
});
}  

});

//////////////////////
///////Dialog Form///////////////////////
////////////////////////
///////////////////////
	</script> 
</body>
</html>
