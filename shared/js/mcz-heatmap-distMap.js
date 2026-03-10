// 
//js code for heat map and distribution map include deckgl
//
//
// /shared/js/mcz-heatmap.js
// /shared/js/mcz-heatmap.js

var map;
var overlay;
var heatmapLayer;
var pointLayer;
var currentView = 'heatmap';   // 'heatmap' or 'points'
var MCZ_CLEAN_DATA = null;     // sanitized data array

function initMap() {
  // Expect globals from CF page
  if (!window.MCZ_HEATMAP_DATA || !window.MCZ_BOUNDS) {
    console.error("initMap: Missing MCZ_HEATMAP_DATA or MCZ_BOUNDS");
    return;
  }

  // Set up map bounds and center
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

  // Deck.gl overlay on top of Google Maps
  overlay = new deck.GoogleMapsOverlay({
    layers: []
  });
  overlay.setMap(map);

  // Sanitize MCZ_HEATMAP_DATA
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

  // Wire up Heatmap Color button
  var btnGradient = document.getElementById("change-gradient");
  if (btnGradient) {
    btnGradient.addEventListener("click", changeGradient);
  }

  // Wire up dropdown for view mode
  var selectView = document.getElementById("view-mode");
  if (selectView) {
    // default to heatmap
    selectView.value = 'heatmap';

    selectView.addEventListener("change", function () {
      toggleView();
    });
  }

  // Start in heatmap view
  currentView = 'heatmap';
  toggleView();
  console.log("initMap: initialized, starting in heatmap view");
}

function toggleView() {
  if (!overlay || !MCZ_CLEAN_DATA) {
    console.error("toggleView: overlay or data not ready");
    return;
  }

  var data = MCZ_CLEAN_DATA;

  // Read mode from dropdown if present
  var selectView = document.getElementById("view-mode");
  if (selectView) {
    currentView = selectView.value;   // 'heatmap' or 'points'
  } else if (!currentView) {
    currentView = 'heatmap';
  }

  // Show/hide Heatmap Color button based on mode
  var btnGradient = document.getElementById("change-gradient");
  if (btnGradient) {
    btnGradient.style.display = (currentView === 'heatmap') ? '' : 'none';
  }
    

  if (currentView === 'points') {
    // Points view
    pointLayer = new deck.ScatterplotLayer({
      id: 'mcz-points',
      data: data,
      getPosition: function (d) { return [d.longitude, d.latitude]; },
      getRadius: function () { return 1000; }, // meters
      radiusMinPixels: 2,
      radiusMaxPixels: 10,
      getFillColor: function () { return [222, 138, 23, 255]; },//orange-gold color
      pickable: false
    });

    overlay.setProps({ layers: [pointLayer] });

  } else {
    // Heatmap view
    var defaultGradient = [
      [0, 255, 255, 150],// color density 150
      [0, 255, 255, 255],
      [0, 191, 255, 255],
      [0, 127, 255, 255],
      [0,  63, 255, 255],
      [0,   0, 255, 255],
      [0,   0, 223, 255],
      [0,   0, 191, 255],
      [0,   0, 159, 255],
      [0,   0, 127, 255],
      [63,  0,  91, 255],
      [127, 0,  63, 255],
      [191, 0,  31, 255],
      [255, 0,   0, 255]
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
  if (!MCZ_CLEAN_DATA) {
    console.error("changeGradient: data not ready");
    return;
  }

  var data = MCZ_CLEAN_DATA;

  var defaultGradient = [
    [0, 255, 255, 150],
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

  // Your alternate palette for color-blind users
  var altGradient = [
    [229, 255,  25, 150], // light green-yellow (faint)
    [229, 255,  25, 255], // light green-yellow
    [255, 170,  73, 255], // orange
    [255, 165,  61, 255], // orange
    [255, 105,   0, 255], // dark orange
    [230,   5,  36, 255], // red-orange
    [255,  41,  61, 255], // bright orange-red
    [255,  50,  43, 255], // bright orange-red
    [255,  57, 122, 255], // hot pink
    [255,  73, 140, 255]  // hot pink
  ];

  // Check what we’re currently using
  var current =
    (heatmapLayer && heatmapLayer.props && heatmapLayer.props.colorRange) ||
    defaultGradient;

  var usingAlt =
    current.length === altGradient.length &&
    current[0][0] === altGradient[0][0] &&
    current[0][1] === altGradient[0][1];

  var newGradient = usingAlt ? defaultGradient : altGradient;

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
}