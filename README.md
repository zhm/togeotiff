## togeotiff

Create a GeoTIFF from a XYZ/TMS tile server given a GeoJSON bounding box and desired zoom level.

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

### Note

This is sorta hacky and just intended to be a simple tool to make some nice screenshots or printed maps.
