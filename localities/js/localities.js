
function suggestSovereignNation(geog_auth_rec_id) {
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
				return(result[0].id);
			}
      }
   ).fail(function(jqXHR,textStatus,error){
      handleFail(jqXHR,textStatus,error,"looking up sovereign nation from higher geography");
   });
}
