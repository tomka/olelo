#!/usr/bin/ruby

require 'rexml/document'

FILE = '/usr/share/mime/packages/freedesktop.org.xml'
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
puts "MIME_EXTENSIONS=#{extensions.inspect}"
puts "MIME_TYPES=#{types.inspect}"

