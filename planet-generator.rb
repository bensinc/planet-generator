require 'chunky_png'
require 'paleta'

KINDS = [:earth, :gas, :moon, :asteroid, :weird_earth]

def clip(x, min, max)
    if( min > max )
      return x
    elsif ( x < min )
      return min
    elsif ( x > max )
      return max
    else
      return x
    end
end

def gaussian(mean, stddev, rand)
  theta = 2 * Math::PI * rand.call
  rho = Math.sqrt(-2 * Math.log(1 - rand.call))
  scale = stddev * rho
  x = mean + scale * Math.cos(theta)
  y = mean + scale * Math.sin(theta)
  return x
end

def generatePolygon(centerX, centerY, aveRadius, irregularity, spikeyness, numVerts)
  irregularity = clip(irregularity, 0, 1) * 2 * Math::PI / numVerts
  spikeyness = clip( spikeyness, 0,1 ) * aveRadius

  angleSteps = []
  lower = (2*Math::PI / numVerts) - irregularity
  upper = (2*Math::PI / numVerts) + irregularity
  sum = 0

  numVerts.times do |i|
    tmp = rand(lower..upper)
    angleSteps << tmp
    sum = sum + tmp
  end

  k = sum / (2 * Math::PI)
  numVerts.times do |i|
    angleSteps[i] = angleSteps[i] / k
  end

  points = []

  angle = rand(0..2 * Math::PI)
  numVerts.times do |i|
    r_i = clip(gaussian(aveRadius, spikeyness, lambda { Kernel.rand }), 0, 2 * aveRadius)
    x = centerX + r_i * Math.cos(angle)
    y = centerY + r_i * Math.sin(angle)
    points << [x, y]
    angle = angle + angleSteps[i]
  end
  return(points)
end

def add_atmosphere(png, color = ChunkyPNG::Color('blue'))
  size = png.width / 2
  png.circle(size, size, size - 3, ChunkyPNG::Color.fade(color, 80))
  png.circle(size, size, size - 4, ChunkyPNG::Color.fade(color, 60))
  png.circle(size, size, size - 5, ChunkyPNG::Color.fade(color, 40))
  png.circle(size, size, size - 6, ChunkyPNG::Color.fade(color, 20))
  png.circle(size, size, size - 7, ChunkyPNG::Color.fade(color, 10))
end

def add_continents(png, fill_color = ChunkyPNG::Color('green @ 0.8'), stroke_color = ChunkyPNG::Color('green @ 1.0'))
  size = png.width / 2
  rand(5..10).times do
    path = generatePolygon(rand(size * 2), rand(size * 2), rand(1..20), 0.5, 0.2, rand(20..30))
    png.polygon(path, fill_color, stroke_color)
  end

end

def add_clouds(png, color = nil)
  size = png.width / 2
  rand(20..30).times do
    path = generatePolygon(rand(size * 2), rand(size * 2), rand(1..10), rand(), 0.2, rand(30..50))
    if color
      png.polygon(path, color, color)
    else
      png.polygon(path, ChunkyPNG::Color('white @ 0.3'), ChunkyPNG::Color('white @ 0.5'))
    end

  end
end

def add_impacts(png, color = ChunkyPNG::Color('black'), rate = 10..20, radius = 1..10)
  size = png.width/2

  rand(rate).times do
    x = rand(size * 2)
    y = rand(size * 2)
    r = rand(radius)
    png.circle(x, y, r, ChunkyPNG::Color.fade(color, 60), ChunkyPNG::Color.fade(color, 60))
    png.circle(x, y, r-1, ChunkyPNG::Color.fade(color, 80), ChunkyPNG::Color.fade(color, 80))
  end
end

def add_texture(png, rate = 5, exclude_color = nil)
  png.width.times do |x|
    png.height.times do |y|
      c = png[x, y]
      if rand(100) < rate
        png[x, y] = ChunkyPNG::Color.fade(c, rand(200..250)) if (c != exclude_color)
      end
    end
  end
end


# Types

def earth(png)
  size = png.width/2
  png.circle(size, size, size - 2, ChunkyPNG::Color('black @ 0.05'), ChunkyPNG::Color('black @ 0.05')) # Atmosphere / alias
  png.circle(size, size, size - 3, ChunkyPNG::Color('blue @ 0.5'), 46079) # Planet

  c = png[32, 32]

  add_continents(png)
  add_texture(png, 10, c)
  add_clouds(png)
  add_atmosphere(png)
end

def weird_earth(png)
  color = Paleta::Palette.generate(:type => :random, :size => 1).first

  palette = Paleta::Palette.generate(:type => [:shades, :analogous, :monochromatic, :complementary].sample, :from => :color, :size => 5, :color => color).to_array(:hex)
  size = png.width/2
  png.circle(size, size, size - 2, ChunkyPNG::Color('black @ 0.05'), ChunkyPNG::Color('black @ 0.05')) # Atmosphere / alias
  png.circle(size, size, size - 3, ChunkyPNG::Color.from_hex(palette[0]), ChunkyPNG::Color.from_hex(palette[0])) # Planet

  c = png[32, 32]

  add_continents(png, ChunkyPNG::Color.from_hex(palette[1]), ChunkyPNG::Color.from_hex(palette[2]))
  add_texture(png, 10, c)
  add_clouds(png, ChunkyPNG::Color.from_hex(palette[3]))
  add_atmosphere(png, ChunkyPNG::Color.from_hex(palette[0]))
end

def moon(png)

  color = Paleta::Palette.generate(:type => :random, :size => 1).first
  palette = Paleta::Palette.generate(:type => :shades, :from => :color, :size => 4, :color => color).to_array(:hex)

  c = []
  for color in palette
    c << ChunkyPNG::Color.from_hex(color)
  end

  size = png.width/2
  png.circle(size, size, size - 2, ChunkyPNG::Color('black @ 0.05'), ChunkyPNG::Color('black @ 0.05')) # Atmosphere / alias
  png.circle(size, size, size - 3, c[0], c[1]) # Planet

  add_continents(png, fill_color = c[2], stroke_color = c[2])
  add_texture(png, rand(5..30))
  add_impacts(png, ChunkyPNG::Color.compose_quick(c[1], ChunkyPNG::Color.from_hex('000000')) , 3..10)
  add_atmosphere(png, c[0])
end

def gas(png)
  samples = [
    'bba78e', 'b06e22', 'cacdc2', '7c534d', '9ba38e',
    '939276', '94906d', 'a39a71', 'dcbd7d', '767557',
    '313da1', '364bbe', '3652cd', '476bff'
  ]

  size = png.width/2

  color = Paleta::Color.new(:hex, samples.sample)

  palette = Paleta::Palette.generate(:type => :shades, :from => :color, :size => 4, :color => color)
  palette.lighten!(70)

  palette = palette.to_array(:hex)

  colors = []
  for color in palette
    colors << ChunkyPNG::Color.from_hex(color)
  end

  png.circle(size, size, size - 2, ChunkyPNG::Color('black @ 0.05'), ChunkyPNG::Color('black @ 0.05')) # Atmosphere / alias
  png.circle(size, size, size - 3, ChunkyPNG::Color.fade(colors[0], 50), ChunkyPNG::Color.fade(colors[0], 100)) # Planet
  add_texture(png, 50)
  y = 0

  while (y < png.height)
    h = rand(1..7)
    rc = colors[rand(colors.size)] + rand(-1000..1000)
    png.rect(0, y, size*2, y + h, rc, rc)
    y += h
  end
  add_impacts(png, colors[0], 1..3)
  add_atmosphere(png, colors[0])
end

def asteroid(png)
  size = png.width/2
  add_texture(png, 50, ChunkyPNG::Color('gray'))
  add_continents(png, fill_color = ChunkyPNG::Color('gray @ 0.2'), stroke_color = ChunkyPNG::Color('gray @ 0.8'))
  add_impacts(png)
end



def generate(kind, i)

  mask = []
  size = 32
  png = ChunkyPNG::Image.new(size * 2, size * 2, ChunkyPNG::Color(:orange))

  if kind == :asteroid
    path = generatePolygon(size, size, rand(5..20), rand(), rand(0..0.1), rand(5..40))
    png.polygon(path, ChunkyPNG::Color(:red), ChunkyPNG::Color(:red))
  else
    png.circle(size, size, size - 3, ChunkyPNG::Color('black @ 1.0'), ChunkyPNG::Color('black @ 1.0')) # Atmosphere / alias
  end

  png.width.times do |x|
    png.height.times do |y|
      if png[x, y] == ChunkyPNG::Color(:orange)
        mask << [x, y]
      end
    end
  end

  case kind
  when :asteroid
    asteroid(png)
  when :moon
    moon(png)
  when :earth
    earth(png)
  when :weird_earth
    weird_earth(png)
  when :gas
    gas(png)
  end


  # Cut out
  for point in mask
    png[point[0], point[1]] = ChunkyPNG::Color('black @ 1.0')
  end

  png.grayscale! if kind == :asteroid

  png.resample_nearest_neighbor!(300, 300)
  png.save("#{ARGV[1].downcase}-#{i}.png", :interlace => true)


end

if ARGV.size < 2
  puts "Usage: ruby planet-generator.rb <count> <kind>"
  puts "Valid kinds: #{(KINDS.map {|x| x.to_s}).join(', ')}"
else
  ARGV[0].to_i.times do |i|
    generate(ARGV[1].to_sym, i)
  end
end
