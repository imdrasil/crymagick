# CryMagick [![Build Status](https://travis-ci.org/imdrasil/crymagick.svg)](https://travis-ci.org/imdrasil/crymagick) [![Latest Release](https://img.shields.io/github/release/imdrasil/crymagick.svg)](https://github.com/imdrasil/crymagick/releases)

**CryMagick** is a [ImageMagick](http://imagemagick.org/) command line interface for crystal. Inspired by [minimagick](https://github.com/minimagick/minimagick).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crymagick:
    github: imdrasil/crymagick
    version: 0.2.1
```

## Requirements

ImageMagick command-line tool >= 7.0.8  has to be installed. You can check if you have it installed by running

```shell
$ convert -version
Version: ImageMagick 7.0.8-6 Q16 x86_64 2018-07-10 https://www.imagemagick.org
```

## Usage

Let's first see a basic example of resizing an image.

```crystal
image = CryMagick::Image.open("input.jpg")
image.path #=> "/var/folders/k7/6zx6dx6x7ys3rv3srh0nyfj00000gn/T/magick20140921-75881-1yho3zc.jpg"
image.resize "100x100"
image.format "png"
image.write "output.png"
```

`CryMagick::Image.open` makes a copy of the image, and further methods modify that copy (the original stays untouched). We then resize the image, and write it to a file. The writing part is necessary because the copy is just temporary, it gets garbage collected when we lose reference to the image.

On the other hand, if we want the original image to actually get modified, we can use `CryMagick::Image.new`.

### Combine options

While using methods like `#resize` directly is convenient, if we use more methods in this way, it quickly becomes inefficient, because it calls the command on each methods call. `CryMagick::Image#combine_options` takes multiple options and from them builds one single command.

```crystal
image.combine_options do |b|
  b.resize "250x200>"
  b.rotate "-90"
  b.flip
end # the command gets executed
```

As a handy shortcut, `CryMagick::Image.build` accepts an optional block which is used to combine_options.

```crystal
image = CryMagick::Image.build("input.jpg") do |b|
  b.resize "250x200>"
  b.rotate "-90"
  b.flip
end # the command gets executed
```

The yielded builder is an instance of `CryMagick::Tool::Mogrify`.

### Attributes

A `CryMagick::Image` has various handy attributes.

```crystal
image.type        #=> "JPEG"
image.mime_type   #=> "image/jpeg"
image.width       #=> 250
image.height      #=> 300
image.dimensions  #=> [250, 300]
image.size        #=> 3451 (in bytes)
image.colorspace  #=> "DirectClass sRGB"
image.exif        #=> {"DateTimeOriginal" => "2013:09:04 08:03:39", ...}
image.resolution  #=> [75, 75]
image.signature   #=> "60a7848c4ca6e36b8e2c5dea632ecdc29e9637791d2c59ebf7a54c0c6a74ef7e"
```

If you need more control, you can also access raw image attributes:

```crystal
image["%[gamma]"] # "0.9"
```

To get the all information about the image, CryMagick gives you a handy method which returns the output from `identify -verbose` in hash format:

```crystal
image.data #=>
# {
#   "format": "JPEG",
#   "mimeType": "image/jpeg",
#   "class": "DirectClass",
#   "geometry": {
#     "width": 200,
#     "height": 276,
#     "x": 0,
#     "y": 0
#   },
#   "resolution": {
#     "x": "300",
#     "y": "300"
#   },
#   "colorspace": "sRGB",
#   "channelDepth": {
#     "red": 8,
#     "green": 8,
#     "blue": 8
#   },
#   "quality": 92,
#   "properties": {
#     "date:create": "2016-07-11T19:17:53+08:00",
#     "date:modify": "2016-07-11T19:17:53+08:00",
#     "exif:ColorSpace": "1",
#     "exif:ExifImageLength": "276",
#     "exif:ExifImageWidth": "200",
#     "exif:ExifOffset": "90",
#     "exif:Orientation": "1",
#     "exif:ResolutionUnit": "2",
#     "exif:XResolution": "300/1",
#     "exif:YResolution": "300/1",
#     "icc:copyright": "Copyright (c) 1998 Hewlett-Packard Company",
#     "icc:description": "sRGB IEC61966-2.1",
#     "icc:manufacturer": "IEC http://www.iec.ch",
#     "icc:model": "IEC 61966-2.1 Default RGB colour space - sRGB",
#     "jpeg:colorspace": "2",
#     "jpeg:sampling-factor": "1x1,1x1,1x1",
#     "signature": "1b2336f023e5be4a9f357848df9803527afacd4987ecc18c4295a272403e52c1"
#   },
#   ...
# }
```

### Configuration

```crystal
CryMagick::Configuration.configure do |config|
  config.cli_path = "some/path"
  config.whiny = false
end
```

### Composite

CryMagick allows to composite images:

```crystal
first_image  = CryMagick::Image.new("first.jpg")
second_image = CryMagick::Image.new("second.jpg")
result = first_image.composite(second_image) do |c|
  c.compose "Over"    # OverCompositeOp
  c.geometry "+20+20" # copy second_image onto first_image from (20, 20)
end
result.write "output.jpg"
```

### Metal

If you want to be close to the metal, you can use ImageMagick's command-line tools directly.

```crystal
CryMagick::Tool::Mogrify.build do |mogrify|
  mogrify.resize("100x100")
  mogrify.negate
  mogrify << "image.jpg"
end #=> `mogrify -resize 100x100 -negate image.jpg`

# OR

mogrify = CryMagick::Tool::Mogrify.new
mogrify.resize("100x100")
mogrify.negate
mogrify << "image.jpg"
mogrify.call #=> `mogrify -resize 100x100 -negate image.jpg`
```

This way of using CryMagick is highly recommended if you want to maximize performance of your image processing. Here are some of the features.

#### Appending

The most basic way of building a command is appending strings:

```crystal
CryMagick::Tool::Convert.build do |convert|
  convert << "input.jpg"
  convert.merge! ["-resize", "500x500", "-negate"]
  convert << "output.jpg"
end
```

#### Methods

Instead of passing in options directly, you can use pure methods:

```crystal
convert.resize("500x500")
convert.rotate(90)
convert.distort("Perspective", "0,0,0,0 0,45,0,45 69,0,60,10 69,45,60,35")
```

#### Chaining

```crystal
CryMagick::Tool::Convert.build do |convert|
  convert << "input.jpg"
  convert.clone(0).background('gray').shadow('80x5+5+5')
  convert.negate
  convert << "output.jpg"
end
```

#### "Plus"

```crystal
CryMagick::Tool::Convert.build do |convert|
  convert << "input.jpg"
  convert.repage.+
  convert.distort.+("Perspective", "more args")
end
# convert input.jpg +repage +distort Perspective 'more args'
```

#### Stack

```crystal
CryMagick::Tool::Convert.build do |convert|
  convert << "wand.gif"
  convert.stack do |stack|
    stack << "wand.gif"
    stack.rotate(30)
  end
  convert << "images.gif"
end
```

## Troubleshooting

`CryMagick::Tool` uses `method_missing` macro so any method invocation with the invalid arguments will create a new method. To get a list of generated methods add `crymagick_debug` flag:

```shell
$ crystal run ./src/target.cr -Dcrymagic_debug
CryMagick::Tool::Mogrify#resize(_arg0) is generated
CryMagick::Tool::Mogrify#colorspace(_arg0) is generated
CryMagick::Tool::Mogrify#crop(_arg0) is generated
```

## Development

To run test suite

```shell
$ make test
```

Next feature:
- [ ] add graphicsmagick
- [ ] add different image converting tools support

## Contributing

1. Fork it ( https://github.com/imdrasil/crymagick/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [imdrasil](https://github.com/imdrasil) Roman Kalnytskyi - creator, maintainer
