// 
//js code for heat map and distribution map include deckgl
//
//
// /shared/js/mcz-heatmap.js

var map;
var overlay;
var heatmapLayer;
var pointLayer;
var currentView = 'heatmap';   // 'heatmap' or 'points'
var MCZ_CLEAN_DATA = null;     // sanitized data array

function initMap() {
  // Expect these globals from the CF page
  if (!window.MCZ_HEATMAP_DATA || !window.MCZ_BOUNDS) {
    console.error("initMap: Missing MCZ_HEATMAP_DATA or MCZ_BOUNDS");
    return;
  }

  // Set up map bounds and center from MCZ_BOUNDS
  var ne = new google.maps.LatLng(MCZ_BOUNDS.maxlat, MCZ_BOUNDS.maxlong);
  var sw = new google.maps.LatLng(MCZ_BOUNDS.minlat, MCZ_BOUNDS.minlong);
  var bounds = new google.maps.LatLngBounds(sw, ne);
  var centerpoint = bounds.getCenter();

  var mapOptions = {
    zoom: 1,
    minZoom: 1,
    maxZoom: 13,
    center: centerpoint,
    controlSize: 20,
    mapTypeId: "hybrid"
  };

  map = new google.maps.Map(document.getElementById('map'), mapOptions);
  map.fitBounds(bounds);

  // Create deck.gl overlay on top of Google Maps
  overlay = new deck.GoogleMapsOverlay({
    layers: []
  });
  overlay.setMap(map);

  // Sanitize MCZ_HEATMAP_DATA: remove invalid coords
  var raw = MCZ_HEATMAP_DATA || [];
  var data = [];
  for (var i = 0; i < raw.length; i++) {
    var d = raw[i];
    if (!d) continue;

    var lat = parseFloat(d.latitude);
    var lon = parseFloat(d.longitude);
    var w = d.weight || 1;

    if (!isFinite(lat) || !isFinite(lon)) continue;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;

    data.push({
      latitude: lat,
      longitude: lon,
      weight: w
    });
  }

  MCZ_CLEAN_DATA = data;

  console.log("initMap: raw points =", raw.length, "valid points =", data.length);

  if (!data.length) {
    console.error("initMap: No valid points for heatmap");
  }

  currentView = 'heatmap';
  overlay.setProps({ layers: [] });

  // Wire up buttons
  var btnGradient = document.getElementById("change-gradient");
  if (btnGradient) {
    btnGradient.addEventListener("click", changeGradient);
  }

  var btnToggleView = document.getElementById("toggle-view");
  if (btnToggleView) {
    btnToggleView.addEventListener("click", toggleView);
  }

  // Start in heatmap view
  toggleView(); // first call: builds and shows heatmap
  console.log("initMap: initialized, starting in heatmap view");
}

function toggleView() {
  if (!overlay || !MCZ_CLEAN_DATA) {
    console.error("toggleView: overlay or data not ready");
    return;
  }

  var data = MCZ_CLEAN_DATA;

  if (currentView === 'heatmap') {
    // Switch to points
    currentView = 'points';
    console.log("toggleView: switching to points");

    pointLayer = new deck.ScatterplotLayer({
      id: 'mcz-points',
      data: data,
      getPosition: function (d) { return [d.longitude, d.latitude]; },
      getRadius: function () { return 1000; },   // meters; adjust as needed
      radiusMinPixels: 2,
      radiusMaxPixels: 10,
      getFillColor: function () { return [0, 255, 0, 180]; },
      pickable: false
    });

    overlay.setProps({ layers: [pointLayer] });
  } else {
    // Switch to heatmap
    currentView = 'heatmap';
    console.log("toggleView: switching to heatmap");

    var defaultGradient = [
      [0, 255, 255, 60],
      [0, 255, 255, 255],
      [0, 191, 255, 255],
      [0, 127, 255, 255],
      [0, 63, 255, 255],
      [0, 0, 255, 255],
      [0, 0, 223, 255],
      [0, 0, 191, 255],
      [0, 0, 159, 255],
      [0, 0, 127, 255],
      [63, 0, 91, 255],
      [127, 0, 63, 255],
      [191, 0, 31, 255],
      [255, 0, 0, 255]
    ];

    var existingRange =
      (heatmapLayer && heatmapLayer.props && heatmapLayer.props.colorRange) ||
      defaultGradient;

    heatmapLayer = new deck.HeatmapLayer({
      id: 'mcz-heatmap',
      data: data,
      getPosition: function (d) { return [d.longitude, d.latitude]; },
      getWeight: function (d) { return d.weight || 1; },
      radiusPixels: 20,
      intensity: 1.0,
      threshold: 0.03,
      opacity: 0.9,
      colorRange: existingRange
    });

    overlay.setProps({ layers: [heatmapLayer] });
  }
}

function changeGradient() {

    var data = MCZ_CLEAN_DATA;

    var defaultGradient = [
      [0, 255, 255, 60],
      [0, 255, 255, 255],
      [0, 191, 255, 255],
      [0, 127, 255, 255],
      [0, 63, 255, 255],
      [0, 0, 255, 255],
      [0, 0, 223, 255],
      [0, 0, 191, 255],
      [0, 0, 159, 255],
      [0, 0, 127, 255],
      [63, 0, 91, 255],
      [127, 0, 63, 255],
      [191, 0, 31, 255],
      [255, 0, 0, 255]
    ];
	
    var altGradient = [
       [ 50, 190, 230, 100], //deep bright blue
      // very low density: very faint light purple
      [140, 100, 180, 118],   // light purple, mostly transparent
      // low density: light/mid purple
      [160, 110, 190, 120],
      [180, 130, 200, 200],
      // mid densities: yellowish
      [220, 180,  40, 255],   // yellow‑orange
      [255, 215,   0, 255],   // golden yellow
      // mid‑high: cyan-ish transition toward blue
      [ 50, 190, 230, 255],   // teal/cyan
      // high density: bright blues
      [  0, 150, 255, 255],   // bright sky blue
      [  0, 110, 255, 255],   // strong blue
      [  0,  70, 230, 255]    // deep bright blue
    ];
	
  // Check what we’re currently using
  var current =
    (heatmapLayer && heatmapLayer.props && heatmapLayer.props.colorRange) ||
    defaultGradient;

  var usingAlt =
    current.length === altGradient.length &&
    current[0][0] === altGradient[0][0] &&
    current[0][1] === altGradient[0][1];

  var newGradient  = usingAlt ? defaultGradient : altGradient;
  var newRadius    = 20;
  var newIntensity = 1.0;
    
    
  heatmapLayer = new deck.HeatmapLayer({
    id: 'mcz-heatmap',
    data: data,
    getPosition: function (d) { return [d.longitude, d.latitude]; },
    getWeight: function (d) { return d.weight || 1; },
    radiusPixels: 20,
    intensity: 1.0,
    threshold: 0.03,
    opacity: 0.9,
    colorRange: newGradient
  });

  if (currentView === 'heatmap' && overlay) {
    overlay.setProps({ layers: [heatmapLayer] });
  }

  console.log("changeGradient: updated gradient, radius =", newRadius, "intensity =", newIntensity);
}