#!/usr/bin/ruby

require 'rexml/document'

FILE = ARGV[0] || '/usr/share/mime/packages/freedesktop.org.xml'
file = File.new(FILE)
doc = REXML::Document.new(file)
extensions = {}
types = {}
doc.each_element('mime-info/mime-type') do |mime|
  type = mime.attributes['type']
  subclass = mime.get_elements('sub-class-of').map{|x| x.attributes['type']}
  exts = mime.get_elements('glob').map{|x| x.attributes['pattern'] =~ /^\*\.([^\[\]]+)$/ ? $1.downcase : nil }.compact
  if !exts.empty?
    exts.each{|x|
      extensions[x] = type if !extensions.include?(x)
    }
    types[type] = [exts,subclass]
  end
end

puts "# Generated from #{FILE}"
puts "class Mime"
puts "  private"
puts "  EXTENSIONS = {"
extensions.keys.sort.each do |key|
  puts "    '#{key}' => '#{extensions[key]}',"
end
puts "  }"
puts "  TYPES = {"
types.keys.sort.each do |key|
  exts = types[key][0].sort.inspect
  parents = types[key][1].sort.inspect
  puts "    '#{key}' => [#{exts}, #{parents}],"
end
puts "  }"
puts "end"

