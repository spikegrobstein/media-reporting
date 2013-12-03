#! /usr/bin/env ruby

require 'filesize'

movies_path = ARGV.shift

abort "Please pass me a path to the movies directory." unless File.directory?(movies_path)

movies_path = File.join(movies_path, '*')

movie_extensions = %w( mkv avi mpg wmv )

Dir[movies_path].each do |d|
  title, year = File.basename(d).scan(/^(.+?) \((\d{4})\)$/).flatten
  format, quality, size = nil, nil, nil

  files = Dir.entries(d)

  files.each do |f|
    next if f.match(/^\./)
    next unless f.match(/\.(#{movie_extensions.join('|')})$/)

    m = f.match(/(\-([^-]+))?\.(#{ movie_extensions.join('|')})$/)

    quality = m[2]
    format = m[3]
    size = File.stat( File.join(d, f) ).size
    size = Filesize.from( "#{ size } B" ).pretty

    next
    # puts "  reading #{ f }"
  end

  quality ||= 'SD'

  puts "#{ title } - #{ year } - #{ quality } - #{ format } - #{ size }"
end
