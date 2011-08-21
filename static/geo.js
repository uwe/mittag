function initialize(lat, lng) {
    var latlng = new google.maps.LatLng(lat, lng);
    var myOptions = {
        zoom: 16,
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    var map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
    
    var marker = new google.maps.Marker({
        map: map, 
        position: latlng
    });

    // http://blinktag.com/google-transit-layer-through-google-maps-api/
    var transitOptions = {
        getTileUrl: function(coord, zoom) {
            return "http://mt1.google.com/vt/lyrs=m@155076273,transit:comp|vm:&" +
                "hl=en&opts=r&s=Galil&z=" + zoom + "&x=" + coord.x + "&y=" + coord.y;
        },
        tileSize: new google.maps.Size(256, 256),
        isPng: true
    };
    var transitMapType = new google.maps.ImageMapType(transitOptions);
    map.overlayMapTypes.insertAt(0, transitMapType);
}
