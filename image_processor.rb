require 'mini_magick'
require 'securerandom'
require 'benchmark'

class ImageProcessor

  attr_accessor :path, :type

  #
  # Standard Initializer
  #
  def initialize(path, options={})
    @image   = MiniMagick::Image.open(path)
    @options = options
    @path    = "#{Dir.pwd}/tmp/"
    @type    = @image.mime_type
  end

  #
  # Do the processing, and return the image
  #
  def process
    puts Benchmark.measure {
      if @options.any?
        @image.combine_options do |c|
          # c.strip
          c.filter  'box'
          c.gravity 'center'
          c.quality quality     if @options[:quality]
          c.resize  extent      if @options[:resize]
          c.rotate  rotate      if @options[:rotate]
          c.extent  dimensions  if @options[:crop]
        end
      end
    }
    self
  end

  #
  # Create a new tempfile
  #
  def store
    Dir.mkdir(@path) unless Dir.exists?(@path)
    begin
      filename = "#{SecureRandom.hex}.jpg"
    end while File.exists?("#{@path}#{filename}")
    @image.write(@path << filename)
    self
  end

  private

    #
    # Return the quality passed, or default to 100%
    #
    def quality
      @options[:quality] || '100%'
    end

    #
    # Return the orientation passed, or 0 as a string
    #
    def rotate
      if @options[:rotate]
        orientation = @options[:rotate].to_i
        if orientation.between?(-360, 360)
          rotation = orientation.to_s
        end
      end || '0'
    end

    #
    # Return the resize passed, or the existing image dimensions as a string
    #
    def dimensions
      @options[:resize] || @image[:dimensions].join('x')
    end

    #
    # If true, the image will be cropped to fit into the given resize as a string
    #
    def extent
      cols, rows = @image[:dimensions]
      width, height = dimensions.split('x')

      if @options[:crop]
        if width != cols || height != rows
          scale = [width.to_i/cols.to_f, height.to_i/rows.to_f].max
          cols = (scale * (cols + 0.5)).round
          rows = (scale * (rows + 0.5)).round
        end
      else
        cols, rows = [width, height]
      end

      "#{cols}x#{rows}"
    end

end