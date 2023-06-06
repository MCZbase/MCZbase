/* code for working with WKT, using RegExp patterns that may fail to parse in older browsers.
 encapsulating the failure into this file so as to not affect other js libraries.
*/

/** loadPolygonWKTFromFile  given a file picker control, a control into which to paste WKT, 
  and a feedback output, load the file, if a .wkt file, confirm it contains WKT 
  describing a polygon, and then paste the file content into the wkt control.
  @param fileControlID id for a file picker input, without a leading # selector.
  @param polygonControlId id for a text input into which to place the WKT from the 
    selected file, without a leading # selector.
  @param feedbackId id for an output elment in the dom into which to place feedback
   concerning the load process, without a leading # selector.
**/
function loadPolygonWKTFromFile(fileControlId, polygonControlId, feedbackId) { 
	$("#"+feedbackId).html("Preparing to load...");
	var url = $("#"+fileControlId).val();
	var ext = url.substring(url.lastIndexOf('.') + 1).toLowerCase();
	if ($("#"+fileControlId).prop('files') && $("#"+fileControlId).prop('files')[0]&& (ext == "wkt")) {
		$("#"+feedbackId).html("File has .wkt extension, reading...");
		var reader = new FileReader();
		reader.onload = function (e) {
			console.log(e);
			$("#"+feedbackId).html("Loading...");
			var matchWKT = new RegExp(/POLYGON\s*\(\s*(\(\s*(?<X>\-?\d+(:?\.\d+)?)\s+(?<Y>\-?\d+(:?\.\d+)?)(?:\s*,\s*\-?\d+(:?\.\d+)?\s+\-?\d+(:?\.\d+)?)*\s*,\s*\k<X>\s+\k<Y>\s*\))(\s*,\s*\(\s*(?<XH>\-?\d+(:?\.\d+)?)\s+(?<YH>\-?\d+(:?\.\d+)?)(?:\s*,\s*\-?\d+(:?\.\d+)?\s+\-?\d+(:?\.\d+)?)*\s*,\s*\k<XH>\s+\k<YH>\s*\))*\s*\)/);
			if (matchWKT.test(e.target.result) == true){
				$("#"+feedbackId).html("Polygon loaded. This will not be saved to the database until you Save Changes");
				$("#"+polygonControlId).val(reader.result);
			} else {
				$("#"+feedbackId).html("This file does not contain a valid WKT polygon.");
				$("#"+fileControlId).val('');
				return(false);
			}
		}
		reader.readAsText($("#"+fileControlId).prop('files')[0]); // triggers load event
	} else {
		$("#"+fileControlId).val('');
		return(false);
	}
}

