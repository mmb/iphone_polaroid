require 'open-uri'
require 'stringio'
require 'rubygems'
require 'exifr'
require 'json'
require 'RMagick'

module IPhonePolaroid

  def lat_lon_to_city_state(lat, lon)
    return open(
      "http://maps.google.com/maps/geo?ll=#{lat},#{lon}&output=json") do |f|
      json = JSON.parse(f.read)
      aa_section = json['Placemark'].first['AddressDetails']['Country']['AdministrativeArea']
      locality = aa_section['Locality']['LocalityName']
      aa = aa_section['AdministrativeAreaName']
      "#{locality}, #{aa}"
    end
  end

  module_function :lat_lon_to_city_state

  class Magick::Image

    def exif
      @exif ||= EXIFR::JPEG.new(StringIO.new(to_blob))
    end

    def lat
      unless instance_variable_defined?(:@lat)
        lat = exif.gps_latitude
        unless lat.nil?
          lat = lat[0] + lat[1] / 60.0 + lat[2] / 3600.0
          lat *= -1 if exif.gps_longitude_ref == 'S'
        end
        @lat = lat
      end
      @lat
    end

    def lon
      unless instance_variable_defined?(:@lon)
        lon = exif.gps_longitude
        unless lon.nil?
          lon = lon[0] + lon[1] / 60.0 + lon[2] / 3600.0
          lon *= -1 if exif.gps_longitude_ref == 'W'
        end
        @lon = lon
      end
      @lon
    end

    def polaroid(options={})
      o = {
        :photo_width => 216,
        :photo_height => 225,
        :border_color => '#e8eef3',
        :border_width => 18,
        :bottom_border_width => 63,

        :text_fill => '#000000',
        :text_font => 'Amaze-Normal',
        :text_gravity => Magick::SouthGravity,
        :text_size => 20,
        :text_stroke => 'transparent',

        :amplitude => 0.01,
        :shadow_color => 'gray75',
        :shadow_blur_radius => 0,
        :shadow_blur_sigma => 3,
        :shadow_composite_y => 5,
        :rotate => -5,
        }.merge(options)

      img = copy

      img.resize_to_fill!(o[:photo_width], o[:photo_height])

      border = Magick::GradientFill.new(0, 0, 0, 0, o[:border_color],
        o[:border_color])
      border = Magick::Image.new(img.columns + o[:border_width] * 2,
        img.rows + o[:border_width] + o[:bottom_border_width], border)
      img = border.composite(img, Magick::NorthWestGravity, o[:border_width],
        o[:border_width], Magick::OverCompositeOp)

      unless exif.date_time.nil?
        caption = exif.date_time.strftime('%m/%d/%Y').sub(/(^|\/)0/, '\1')
      else
        caption = ''
      end

      unless lat.nil? or lon.nil?
        caption =
          "#{caption} #{IPhonePolaroid.lat_lon_to_city_state(lat, lon)}"
      end

      unless caption.empty?
        text = Magick::Draw.new
        text.annotate(img, 0, 0, 0, o[:border_width], caption) {
          self.fill = o[:text_fill]
          self.font = o[:text_font]
          self.gravity = o[:text_gravity]
          self.pointsize = o[:text_size]
          self.stroke = o[:text_stroke]
        }
      end

      img.background_color = 'none'
      amplitude = img.columns * o[:amplitude]
      wavelength = img.rows  * 2
      img.rotate!(90)
      img = img.wave(amplitude, wavelength)
      img.rotate!(-90)

      shadow = img.flop
      shadow = shadow.colorize(1, 1, 1, o[:shadow_color])
      shadow.background_color = 'white'
      shadow.border!(10, 10, 'white')
      shadow = shadow.blur_image(o[:shadow_blur_radius], o[:shadow_blur_sigma])
      img = shadow.composite(img, -amplitude / 2, o[:shadow_composite_y],
        Magick::OverCompositeOp)
      img.rotate!(o[:rotate])
      img.trim!

      img

    end

  end

end
