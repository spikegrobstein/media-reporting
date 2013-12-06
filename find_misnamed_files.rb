#! /usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'filesize'
require 'pry'

movies_path = ARGV.shift

abort "Please pass me a path to the movies directory." unless movies_path && File.directory?(movies_path)

movie_extensions = %w( mkv avi mpg wmv )

# map through movies, return an array containing
# first element, name of film
# second element, array of movie files
movie_data = Dir.entries( movies_path ).map do |dir|
  next if dir.match(/^\./)

  movie_path = File.join( movies_path, dir )
  next unless File.directory?( movie_path )

  movie_files = Dir.entries( movie_path ).select do |f|
    next if f.match(/^\./)

    f.match(/(\-([^-]+))?\.(#{ movie_extensions.join('|')})$/)
  end
  print '.'
  [ dir, movie_files ]
end.compact

puts "done."

puts "=" * 20
puts "Movies with more than one file:\n"

movie_data.each do |m|
  title, files = m

  file_data = files.reduce({}) do |memo, file|
    file_path = File.join(movies_path, title, file)

    # store the size
    memo[file] = File.stat(file_path).size

    memo
  end

  if files.length > 1
    puts "#{ title } (#{ files.length })"

    file_data.each do |f,s|
      size = Filesize.from( "#{ s } B" ).pretty
      puts "  #{ size } #{ f }"
    end
  end
end

puts ""
puts "=" * 20
puts "Total savings if only keeping largest files\n"

# collect movies with more than one file
# collect files into arrays with [ name, size ]
# sort files per-movie, by size
# pop largest movie off
# total remaining
# report: which file to keep, total up savings

# build data structure of arrays
# [ movie_title, [ [ file, size ], ... ]
movies_with_more_than_one_file = movie_data.reduce([]) do |memo, data|
  title, files = data

  # skip anything with just one file.
  if files.length > 1

    # fetch the sizes of the files
    file_data = files.reduce([]) do |m, file|
      file_path = File.join(movies_path, title, file)

      # store the size
      m << [ file, File.stat(file_path).size ]

      m
    end

    memo << [ title, file_data ]

  end

  memo
end

# report on this shit
savings_report = movies_with_more_than_one_file.map do |m|
  title, files = m

  # sort the movies from smallest to largest
  files.sort! { |a, b| a.last <=> b.last }

  largest = files.pop
  savings = files.map { |f| f.last }.reduce(0) { |m,v| m += v; m }

  [ title, files.length, savings ]
end

total_savings = savings_report.map { |m| m.last }.reduce(0) { |m,v| m+= v; m }
files_to_delete = savings_report.map { |m| m[1] }.reduce(0) { |m,v| m+= v; m }

puts "Affected movies: #{ movies_with_more_than_one_file.length }"
puts "Files to delete: #{ files_to_delete }"
puts "Total:           #{ Filesize.from( "#{ total_savings } B" ).pretty }"

puts ""
puts "=" * 20
puts "Movies with more than one file, without 'cdX'\n"

movie_data.each do |m|
  title, files = m

  files_with_cd = files.select { |f| f.match(/cd\d/) }

  puts title if files_with_cd.length > 0
end

puts ""
puts "=" * 20
puts "Movies with more than one file of different types\n"

movie_data.each do |m|
  title, files = m

  extensions = files.map { |f| f.scan(/\.([^\.]+)$/).flatten }.uniq

  puts "#{ title } (#{ extensions.join(',') })" if extensions.length > 1
end
