## togeotiff

Create a GeoTIFF from an XYZ/TMS tile server given a GeoJSON bounding box and desired zoom level.

### Setup

```
git clone https://github.com/zhm/togeotiff.git
cd togeotiff
bundle --path .bundle
```

### Usage

```sh
./togeotiff.rb geotiff --geojson https://gist.githubusercontent.com/zhm/321c025c218bad47e3a4/raw/677fa9400c3b94cbb82ae033ce9fd77dc22b6651/map.geojson --zoom 13 --output ~/Documents/pinellas_county_image.tif
```

### Workflow

* Draw bounding box on [geojson.io](http://geojson.io)
* Save as gist, get the raw URL
* `./togeotiff.rb geotiff --geojson <RAW GIST URL> --zoom <ZOOM LEVEL> --output <OUTPUT FILE>`

### Note

This is sorta hacky and just intended to be a simple tool to make some nice screenshots or printed maps.
