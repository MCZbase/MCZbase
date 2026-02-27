// 
//js code for heat map and distribution map include deckgl
//
//
// /shared/js/mcz-heatmap.js

var map;
var overlay;
var heatmapLayer;
var pointLayer;
var currentView = 'heatmap'; // 'heatmap' or 'points'

function initMap() {
  // Expect these to be defined by the CF page
  if (!window.MCZ_HEATMAP_DATA || !window.MCZ_BOUNDS) {
    console.error("initMap: Missing MCZ_HEATMAP_DATA or MCZ_BOUNDS");
    return;
  }

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

  overlay = new deck.GoogleMapsOverlay({
    layers: []
  });
  overlay.setMap(map);

  // Clean/sanitize data from MCZ_HEATMAP_DATA
  var raw = MCZ_HEATMAP_DATA || [];
 // var data = [];
	var data = [
  { latitude: 42.37, longitude: -71.11, weight: 1 },
  { latitude: 42.38, longitude: -71.10, weight: 2 },
  { latitude: 42.36, longitude: -71.12, weight: 1 }
];
  for (var i = 0; i < raw.length; i++) {
    var d = raw[i];
    if (!d) continue;

    var lat = parseFloat(d.latitude);
    var lon = parseFloat(d.longitude);
    var w = d.weight || 1;

    // Skip rows with non-finite or out-of-range lat/lon
    if (!isFinite(lat) || !isFinite(lon)) {
      continue;
    }
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      continue;
    }

    data.push({
      latitude: lat,
      longitude: lon,
      weight: w
    });
  }

  console.log("initMap: raw points =", raw.length, "valid points =", data.length);

  if (!data.length) {
    console.error("initMap: No valid points for heatmap");
  }
  // Heatmap layer
  heatmapLayer = new deck.HeatmapLayer({
    id: 'mcz-heatmap',
    data: data,
    getPosition: function (d) { return [d.longitude, d.latitude]; },
    getWeight: function (d) { return d.weight || 1; },
    radiusPixels: 30,
    intensity: 1,
    threshold: 0.05,
    opacity: 0.9,
    colorRange: [
      [0, 255, 255, 0],
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
    ]
  });

  // Point distribution layer
  pointLayer = new deck.ScatterplotLayer({
    id: 'mcz-points',
    data: data,
    getPosition: function (d) { return [d.longitude, d.latitude]; },
    getRadius: function () { return 1000; },
    radiusMinPixels: 2,
    radiusMaxPixels: 10,
    getFillColor: function () { return [0, 255, 0, 180]; },
    pickable: false
  });

  // Start in heatmap view
  currentView = 'heatmap';
  overlay.setProps({ layers: [heatmapLayer] });
	
 
  // Wire up buttons
  var btnGradient = document.getElementById("change-gradient");
  if (btnGradient) {
    btnGradient.addEventListener("click", changeGradient);
  }

  var btnToggleView = document.getElementById("toggle-view");
  if (btnToggleView) {
    btnToggleView.addEventListener("click", toggleView);
  }

  console.log("initMap: initialized, starting in heatmap view");
}

function toggleView() {
  if (!overlay || !heatmapLayer || !pointLayer) {
    console.error("toggleView: overlay or layers not ready");
    return;
  }

  if (currentView === 'heatmap') {
    currentView = 'points';
    console.log("toggleView: switching to points");
    overlay.setProps({ layers: [pointLayer] });
  } else {
    currentView = 'heatmap';
    console.log("toggleView: switching to heatmap");
    overlay.setProps({ layers: [heatmapLayer] });
  }
}

function changeGradient() {
  if (!heatmapLayer) {
    console.error("changeGradient: heatmapLayer not ready");
    return;
  }

  var defaultGradient = [
    [0, 255, 255, 0],
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
    [255, 255, 178, 0],
    [254, 204, 92, 255],
    [253, 141, 60, 255],
    [240, 59, 32, 255],
    [189, 0, 38, 255]
  ];

  // Toggle based on current colorRange
  var current = heatmapLayer.props.colorRange;
  var useAlt = current && current.length === altGradient.length &&
               current[0][0] === altGradient[0][0];

  var newColorRange = useAlt ? defaultGradient : altGradient;

  heatmapLayer = new deck.HeatmapLayer({
    id: heatmapLayer.props.id,
    data: heatmapLayer.props.data,
    getPosition: heatmapLayer.props.getPosition,
    getWeight: heatmapLayer.props.getWeight,
    radiusPixels: heatmapLayer.props.radiusPixels,
    intensity: heatmapLayer.props.intensity,
    threshold: heatmapLayer.props.threshold,
    opacity: heatmapLayer.props.opacity,
    colorRange: newColorRange
  });

  if (currentView === 'heatmap') {
    overlay.setProps({ layers: [heatmapLayer] });
  }

  console.log("changeGradient: updated gradient");
}