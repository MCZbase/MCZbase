function loadCitPubFormMedia(publication_id,media_id) {
targetDiv="CitPubFormMedia";
	console.log(" media in #"+ targetDiv);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getMediaForCitPub",
			publication_id: publication_id,
			media_id: media_id
		},
		success: function (result) {
			$("#CitPubFormMedia").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing pub");
		},
		dataType: "html"
	});
};

