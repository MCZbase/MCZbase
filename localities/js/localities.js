
/** given a geog_auth_rec_id, look up a plausible value for sovereign nation
 and paste it into a control.
 @param geog_auth_rec_id the higher geography record from which to suggest 
   a sovereign nation value based on the country in the higher geography.
 @param pasteTarget the id in the dom, without a leading pound selector
   into which to paste the suggestion if any.
**/
function suggestSovereignNation(geog_auth_rec_id, pasteTarget) {
   jQuery.getJSON("/localities/component/search.cfc",
      {
         method : "suggestSovereignNation",
         geog_auth_rec_id : geog_auth_rec_id,
         returnformat : "json",
         queryformat : 'column'
      },
      function (result) {
			console.log(result);
			if (result && result[0]) { 
				var suggestion = result[0].id;
				console.log(suggestion);
				if (suggestion) { 
					$("#"+pasteTarget).val(suggestion);
				}
			}
      }
   ).fail(function(jqXHR,textStatus,error){
      handleFail(jqXHR,textStatus,error,"looking up sovereign nation from higher geography");
   });
}

/** given a locality_id, look up the summary for the locality
 and set it as the content of a target div.
 @param locality_id the locality to look up.
 @param pasteTarget the id in the dom, without a leading pound selector
   the content of which to replace with the returned summary.
**/
function updateLocalitySummary(locality_id,pasteTarget) {
	jQuery.ajax({
		url: "/localities/component/search.cfc",
		data : {
			method : "getLocalitySummary",
			locality_id: locality_id
		},
		success: function (result) {
			$("#"+pasteTarget).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining summary for a locality");
		},
		dataType: "html"
	});
};

/** given a locality_id and lat_long_id, attempt to delete the georeference.
 @param locality_id the locality for the georeference to delete
 @param lat_long_id the primary key value for the georeference to delete
 @param callback a callback function to invoke on success.
**/
function deleteGeoreference(locality_id, lat_long_id,callback) {
	jQuery.ajax({
		url: "/localities/component/search.cfc",
		data : {
			method : "deleteGeoreference",
			locality_id: locality_id,
			lat_long_id: lat_long_id
		},
		success: function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"deleting a georeference");
		},
		dataType: "html"
	});
};
