// JavaScript Document

function getMapData(cfmaplatitude, cfmaplongitude){
var msg = "";
msg = msg + "Latitude,longitude: " + "(" + cfmaplatitude + "," + cfmaplongitude + ")" + "<br>";
return "<br><table><tr><td bgcolor='red'><h4><font color='white'>" + "Javascript Bind Example" + "</font></td></tr></table><hr>" + msg;
}
