
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
function updateLocalitySummary(locality_id,targetDiv) {
	jQuery.ajax({
		url: "/localities/component/search.cfc",
		data : {
			method : "getLocalitySummary",
			locality_id: locality_id
		},
		success: function (result) {
			$("#"+targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining summary for a locality");
		},
		dataType: "html"
	});
};
