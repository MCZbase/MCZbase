/** Scripts specific to editing user profile information **/

/** TODO: Refactor the backing methods for these from component/functions.cfc to users/component/functions.cfc **/
function changeBlockSuggest (onoff) {
	$.getJSON("/component/functions.cfc",
			{
				method : "changeBlockSuggest",
				onoff : onoff,
				returnformat : "json",
				queryformat : 'column'
			},
			function(r) {
				if (r == 'success') {
					$('#browseArctos').html('Suggest Browser disabled. You may turn this feature back on under My Stuff.');
				} else {
					alert('An error occured! \n ' + r);
				}	
			}
		);
}
function changeSpecimensDefaultAction (specimens_default_action) {
	$.getJSON("/component/functions.cfc",
			{
				method : "changeSpecimensDefaultAction",
				specimens_default_action : specimens_default_action,
				returnformat : "json",
				queryformat : 'column'
			},
			function(r) {
				if (r == 'success') {
					$('#browseArctos').html('Default Tab for the Specimen Search changed.');
				} else {
					alert('An error occured! \n ' + r);
				}	
			}
		);
}
function changeSpecimensPinGuid (specimens_pin_guid) {
	$.getJSON("/component/functions.cfc",
			{
				method : "changeSpecimensPinGuid",
				specimens_pin_guid : specimens_pin_guid,
				returnformat : "json",
				queryformat : 'column'
			},
			function(r) {
				if (r == 'success') {
					$('#browseArctos').html('Pin GUID Column setting for the Specimen Search changed.');
				} else {
					alert('An error occured! \n ' + r);
				}	
			}
		);
}
function changeSpecimensPageSize (specimens_pagesize) {
	$.getJSON("/component/functions.cfc",
			{
				method : "changeSpecimensPageSize",
				specimens_pagesize : specimens_pagesize,
				returnformat : "json",
				queryformat : 'column'
			},
			function(r) {
				if (r == 'success') {
					$('#browseArctos').html('Page Size setting for the Specimen Search changed.');
				} else {
					alert('An error occured! \n ' + r);
				}	
			}
		);
}
function changekillRows (onoff) {
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "changekillRows",
			tgt : onoff,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result){
			if (result != 'success') {
				alert('An error occured: ' + result);
			}
		}
	);
}
function changeshowObservations (tgt) {
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "changeshowObservations",
			tgt : tgt,
			returnformat : "json",
			queryformat : 'column'
		},
		function (r) {
			if (r != 'success') {
				alert('An error occured: ' + r);
			}
		}
	);
}
function changedisplayRows (tgt) {
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "changedisplayRows",
			tgt : tgt,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			if (result == 'success') {
				document.getElementById('displayRows').className='';
			} else {
				alert('An error occured: ' + result);
			}
		}
	);
}
function changefancyCOID (tgt) {
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "changefancyCOID",
			tgt : tgt,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			if (result == 'success') {
				var e = document.getElementById('fancyCOID').className='';
			} else {
				alert('An error occured: ' + result);
			}
		}
	);
}
function changecustomOtherIdentifier (tgt) {
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "changecustomOtherIdentifier",
			tgt : tgt,
			returnformat : "json",
			queryformat : 'column'
		},
		function (r) {
			if (r == 'success') {
				document.getElementById('customOtherIdentifier').className='';
			} else {
				alert('An error occured: ' + r);
			}
		}
	);
}
function changeexclusive_collection_id (tgt) {
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "changeexclusive_collection_id",
			tgt : tgt,
			returnformat : "json",
			queryformat : 'column'
		},
		function (r) {
			if (r == 'success') {
				var e = document.getElementById('exclusive_collection_id').className='';
			} else {
				alert('An error occured: ' + r);
			}
		}
	);
}
