function loadIdentifications(identification_id) {
    jQuery.ajax({
          url: "/specimens/component/functions.cfc",
          data : {
            method : "getIdentificationHtml",
            identification_id : identification_id
         },
        success: function (result) {
           $("#identificationNewForm").html(result);
        },
        dataType: "html"
       }
     )};

function loadNewIdentificationForm(identification_id) {
    jQuery.ajax({
          url: "/redesign/specimens/component/functions.cfc",
          data : {
            method : "getNewIdentificationForm",
            identification_id : identification_id
         },
        success: function (result) {
           $("#identificationNewForm").html(result);
        },
        dataType: "html"
       }
     )};
function saveIdentifications(identificationId) { 
    var valid = false;
    // Check required fields 
    if ($("#identification_id").val().length==0 ||
           $("#collection_object_id").val().length==0 ||
           $("#scientific_name").val().length==0 ||
           $("#taxa_formula").val().length==0) 
    { 
              $("#IdentificationFormStatus").empty().append("Error: Required field is missing a value");
    } else { 
       // save result
       $('#methodSaveIDQF').remove();
       $('<input id="methodSaveIDQF" />').attr('type', 'hidden')
          .attr('name', "queryformat")
          .attr('value', "column")
          .appendTo('#identificationNewForm');
       $('#methodSaveIdInput').remove();
       $('<input id="methodSaveIDInput" />').attr('type', 'hidden')
          .attr('name', "method")
          .attr('value', "saveShipment")
          .appendTo('#identificationNewForm');
       $.ajax({
          url : "/redesign/specimens/component/functions.cfc",
          type : "post",
          dataType : "json",
          data: $("#identificationNewForm").serialize(),
          success: function (result) {
             if (result.DATA.STATUS[0]==0) { 
               $("#identificationFormStatus").empty().append(result.DATA.MESSAGE[0]);
             } else { 
               loadIdentifications(identificationId);
               valid = true;
               $("#dialog-ID").dialog( "close" );
             }
           },
           fail: function (jqXHR,textStatus) {
               $("#identificationFormStatus").empty().append("Error Submitting Form: " + textStatus);
           }
       });
    }
    return valid;
};

function saveIdentifications(identification_id) {
    jQuery.ajax({
          url: "/redesign/specimens/component/functions.cfc",
          data : {
            method : "getIdentifcationsForIDHtml",
            identification_id: identification_id
         },
        success: function (result) {
           $("#identificationForm").html(result);
        },
        dataType: "html"
       }
     )};




