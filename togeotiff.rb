#!/usr/bin/env ruby

require 'bundler/setup'
require 'thor'
require 'json'

GDAL_TRANSLATE = ENV['GDAL_TRANSLATE'] || 'gdal_translate'

class ToGeoTiff < Thor
  desc "geotiff", "Create a GeoTIFF from a bounding box"
  method_option :geojson, aliases: "-g", desc: "Specify the bounding box", required: true
  method_option :size,    aliases: "-s", desc: "Specify the max dimension of the output image", required: true, default: 2048
  method_option :zoom,    aliases: "-z", desc: "Specify the max zoom of the output image", required: true, default: -1
  method_option :output,  aliases: "-o", desc: "Specify the output file", required: true
  def geotiff
    url = options[:geojson]
    size = options[:size].to_i
    zoom = options[:zoom].to_i

    geojson = JSON.parse(`curl -s #{url}`)

    x_values = []
    y_values = []

    x_degree_values = []
    y_degree_values = []

    # this is dumb, but it'll work for now
    geojson['features'][0]['geometry']['coordinates'].first.each do |coordinate|
      longitude = coordinate[0]
      latitude  = coordinate[1]

      x = lon2x(longitude)
      y = lat2y(latitude)

      x_values << x
      y_values << y

      x_degree_values << longitude
      y_degree_values << latitude
    end

    min_x = x_values.sort.first
    max_x = x_values.sort.last
    min_y = y_values.sort.first
    max_y = y_values.sort.last

    min_lon = x_degree_values.sort.first
    max_lon = x_degree_values.sort.last
    min_lat = y_degree_values.sort.first
    max_lat = y_degree_values.sort.last

    if zoom > 0
      northwest_tile = get_tile(max_lat, min_lon, zoom)
      southeast_tile = get_tile(min_lat, max_lon, zoom)

      x_tile_count = southeast_tile[:x] - northwest_tile[:x]
      y_tile_count = southeast_tile[:y] - northwest_tile[:y]

      northwest_coordinate = get_lat_lon_for_tile(northwest_tile[:x], northwest_tile[:y], zoom)
      southeast_coordinate = get_lat_lon_for_tile(southeast_tile[:x] + 1, southeast_tile[:y] + 1, zoom)

      min_lon = northwest_coordinate[:lon]
      max_lon = southeast_coordinate[:lon]
      min_lat = southeast_coordinate[:lat]
      max_lat = northwest_coordinate[:lat]

      min_x = lon2x(min_lon)
      max_x = lon2x(max_lon)
      min_y = lat2y(min_lat)
      max_y = lat2y(max_lat)

      x_pixels = (x_tile_count + 1) * 256
      y_pixels = (y_tile_count + 1) * 256

      if x_pixels > y_pixels
        size = x_pixels
      else
        size = y_pixels
      end
    end

    size_x = max_lon - min_lon
    size_y = max_lat - min_lat

    if size_x > size_y
      image_width = size
      image_height = (image_width * (size_y / size_x)).ceil
    else
      image_height = size
      image_width = (image_height * (size_x / size_y)).ceil
    end

    image_width = image_width.ceil.to_i
    image_height = image_height.ceil.to_i

    # XMIN YMAX XMAX YMIN

    # PHOTOMETRIC=RGB
    # PHOTOMETRIC=YCBCR

    cmd = "#{GDAL_TRANSLATE} -of GTiff tiles.xml #{options[:output]} -co COMPRESS=JPEG -co PHOTOMETRIC=RGB -projwin #{min_x} #{max_y} #{max_x} #{min_y} -outsize #{image_width} #{image_height}"

    puts ""
    puts "Image bounds:"
    puts "\tMin Lon: #{min_lon}"
    puts "\tMax Lon: #{max_lon}"
    puts "\tMin Lat: #{min_lat}"
    puts "\tMax Lat: #{max_lat}"
    puts ""
    puts "Image size:"
    puts "\t#{image_width} x #{image_height}"
    puts ""
    puts "Command:\n\t#{cmd}"
    puts ""

    system(cmd)
  end

  no_tasks do
    def to_degrees(angle)
      angle * (180 / Math::PI)
    end

    def to_radians(angle)
      angle * (Math::PI / 180)
    end

    def lon2x(lon)
      to_radians(lon) * 6378137.0
    end

    def lat2y(lat)
      Math.log(Math.tan((Math::PI / 4) + to_radians(lat) / 2.0)) * 6378137.0
    end

    def x2lon(x)
      to_degrees(x / 6378137.0)
    end

    def y2lat(y)
      to_degrees(2.0 * Math.atan(Math.exp(y / 6378137.0)) - (Math::PI / 2));
    end

    def get_tile(lat_deg, lng_deg, zoom)
      lat_rad = lat_deg/180 * Math::PI
      n = 2.0 ** zoom
      x = ((lng_deg + 180.0) / 360.0 * n).to_i
      y = ((1.0 - Math::log(Math::tan(lat_rad) + (1 / Math::cos(lat_rad))) / Math::PI) / 2.0 * n).to_i

      { x: x, y: y }
    end

    def get_lat_lon_for_tile(xtile, ytile, zoom)
      n = 2.0 ** zoom
      lon_deg = xtile / n * 360.0 - 180.0
      lat_rad = Math::atan(Math::sinh(Math::PI * (1 - 2 * ytile / n)))
      lat_deg = 180.0 * (lat_rad / Math::PI)

      { lat: lat_deg, lon: lon_deg }
    end

  end
end

ToGeoTiff.start
