#!/usr/bin/env ruby
require 'net/http'
require 'nokogiri'

class DictCommon

  class << self
    def translate(word, verbose=false)
      response = get_response(word)
      take_content response, verbose
    end

    protected
    def get_response(word)
      Net::HTTP.get @host, make_path(word)
    end
    def make_path(word)
      @path_pattern % word
    end
    def take_line(doc, name)
      doc.xpath("//div[@class='#{name}']").to_s.format_line + "\n\n"
    end
    def take_lines(doc, name)
      doc.xpath("//div[@class='#{name}']").to_s.format_lines + "\n\n"
    end
  end

end

class String
  def clean_html
    self.gsub /<[^>]*>/, ''
  end
  def cut_newline
    self.gsub /\r\n/, ''
  end
  def cut_space
    self.gsub /\s+/, ' '
  end
  def format_line
    clean_html.cut_newline.cut_space.strip
  end
  def format_lines
    clean_html.cut_space.strip
  end
end

class DictCN < DictCommon
  @host = "dict.cn"
  @path_pattern = "/%s"
  class << self
    def take_partial(doc, name)
      partial = ""
      def_section = doc.xpath("//div[@class='#{name}']").children.each do |d|
        if d.name == 'h3'
          partial << "### #{d.to_s.format_line} ###\n"
        end
        if d.name == 'div'
          partial << d.to_s.format_lines << "\n\n"
        end
      end
      partial + "\n"
    end
    def take_content(html, verbose)
      response = ""
      doc = Nokogiri::HTML(html)
      response << take_line(doc, "phonetic")
      response << take_line(doc, "shape")
      response << take_partial(doc, "section def")
      response << take_partial(doc, "section sent")
      if verbose
        response << take_partial(doc, "section ask")
        response << take_partial(doc, "section rel")
      end
      response
    end
  end
end

verbose = ARGV.delete "-v"
word = ARGV.first
if word.nil?
  puts "Usage: dict.rb word [-v]"
  exit 0
end
dictionary = DictCN
response = dictionary.translate word, !verbose.nil?
puts "\n## #{word} ##\n"
puts response
