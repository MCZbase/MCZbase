// JavaScript Document

var getMapData = function(cfmapname, cfmaplatitude, cfmaplongitude, cfmapaddress){
var msg = "";
msg = msg + "Map Name: " + cfmapname + "<br>";
msg = msg + "Latitude,longitude: " + "(" + cfmaplatitude + "," + cfmaplongitude + ")" + "<br>";
msg = msg + "Address: " + cfmapaddress + "<br>";
//alert(msg);
return "<br><table><tr><td bgcolor='red'><h4><font color='white'>" + "Javascript Bind Example" + "</font></td></tr></table><hr>" + msg;
}
