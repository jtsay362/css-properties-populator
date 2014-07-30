require 'mechanize'
require 'uri'
require 'net/http'

MDN_BASE_URL = 'https://developer.mozilla.org'
WEB_PLATFORM_BASE_URL = 'http://docs.webplatform.org/wiki/css'
DOWNLOAD_DIR = './downloaded'
ITEM_KIND_PROPERTY = 'property'
ITEM_KIND_AT_RULE = 'at-rule'
ITEM_KIND_FUNCTION = 'function'
ITEM_KIND_PSEUDO_CLASS = 'pseudo-class'
ITEM_KIND_PSEUDO_ELEMENT = 'pseudo-element'
ITEM_KIND_DATA_TYPE = 'data type'

class CssPropertyPopulator

  def initialize(output_path)
    @output_path = output_path
  end

  def download
    puts "Starting download ..."

    FileUtils.mkpath(DOWNLOAD_DIR)

    agent = Mechanize.new
    page = agent.get("#{MDN_BASE_URL}/en-US/docs/Web/CSS/Reference")

    page.search('.index li a').each do |a|
      # Strip synonyms like ::after (:after)
      item_name = a.text().gsub(/\s+\([^)]*\)/, '').strip
      relative_uri = a.attr('href')

      mdn_output_filename = "#{DOWNLOAD_DIR}/mdn_#{item_name}.html"

      if File.exists?(mdn_output_filename)
        puts "Skipping already downloaded item '#{item_name}' for MDN."
      else
        begin
          puts "Downloading MDN page for #{item_name} ..."
          uri_string = "#{MDN_BASE_URL}#{relative_uri}"
          uri = URI.parse(uri_string)
          response = Net::HTTP.get_response(uri)

          File.write(mdn_output_filename, response.body)
          File.write(mdn_output_filename + '.uri', uri_string)

          puts "Done downloading MDN page for #{item_name}"
          sleep(1)
        rescue => e
          puts "Can't download MDN page for #{item_name}: #{e.message}"
        end
      end

      web_platform_output_filename = "#{DOWNLOAD_DIR}/wp_#{item_name}.html"

      kind = item_kind(item_name)

      uri_suffix = web_platform_uri_suffix(item_name, kind)

      if uri_suffix
        if File.exists?(web_platform_output_filename)
          puts "Skipping already downloaded item '#{item_name}' for webplatform."
        else
          begin
            puts "Downloading webplatform page for #{item_name} ..."
            uri = URI.parse("#{WEB_PLATFORM_BASE_URL}/#{uri_suffix}")
            response = Net::HTTP.get_response(uri)

            File.write(web_platform_output_filename, response.body)

            puts "Done downloading webplatform page for #{item_name}, sleeping ..."
            sleep(1)
          rescue => e
            puts "Can't download webplatform page for #{item_name}: #{e.message}"
          end
        end
      end
    end

    puts "Done downloading!"
  end

  def populate
    @first_document = true

    num_items_found = 0

    File.open(@output_path, 'w:UTF-8') do |out|
      out.write <<-eos
{
  "metadata" : {
    "mapping" : {
      "_all" : {
        "enabled" : false
      },
      "properties" : {
        "name" : {
          "type" : "string",
          "index" : "analyzed"
        },
        "recognitionKeys" : {
          "type" : "array",
          "index" : "no"
        },
        "summary" : {
          "type" : "string",
          "index" : "no"
        },
        "syntax" : {
          "type" : "string",
          "index" : "no"
        },
        "metaProperties" : {
          "type" : "object",
          "index" : "no"
        },
        "values" : {
          "type" : "array",
          "index" : "no"
        },
        "mdnUri" : {
          "type" : "string",
          "index" : "no"
        },
        "w3cUri" : {
          "type" : "string",
          "index" : "no"
        },
        "webPlatformUri" : {
          "type" : "string",
          "index" : "no"
        }
      }
    }
  },
  "updates" : [
    {
      "name" : "selectors",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/selectors",
      "w3cUri" : "http://www.w3.org/TR/selectors/#selectors"
    },
    {
      "name" : "properties",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/properties",
      "w3cUri" : "http://www.w3.org/community/webed/wiki/CSS/Properties"
    },
    {
      "name" : "functions",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/functions"
    },
    {
      "name" : "pseudo-classes",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Pseudo-classes"
    },
    {
      "name" : "pseudo-elements",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Pseudo-elements"
    },
    {
      "name" : "at rules",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/At-rule",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/atrules"
    },
    {
      "name" : "box model",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/box_model",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/guides/the_css_layout_model",
      "w3cUri" : "http://www.w3.org/wiki/The_CSS_layout_model_-_boxes_borders_margins_padding"
    },
    {
      "name" : "specificity",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Specificity"
    },
    {
      "name" : "CSS inheritance",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/inheritance",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/tutorials/inheritance_and_cascade",
      "w3cUri" : "http://www.w3.org/TR/css3-cascade/"
    },
    {
      "name" : "cascade",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/inheritance",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/tutorials/inheritance_and_cascade",
      "w3cUri" : "http://www.w3.org/TR/css3-cascade/"
    },
    {
      "name" : "media query",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/mediaqueries",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Media_queries",
      "w3cUri" : "http://www.w3.org/community/webed/wiki/CSS/Mediaqueries"
    },
    {
      "name" : "CSS syntax",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Syntax",
      "w3cUri" : "http://www.w3.org/TR/css-syntax-3/"
    },
    {
      "name" : "CSS shorthand",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Shorthand_properties",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/guides/css_shorthand",
      "w3cUri" : "http://www.w3.org/community/webed/wiki/CSS_shorthand_reference"
    },
    {
      "name" : "CSS units",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/tutorials/understanding-css-units",
      "w3Uri" : "http://www.w3.org/TR/css3-values/"
    },
    {
      "name" : "CSS3",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/CSS3"
    },
    {
      "name" : "CSS reference",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Reference",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/reference"
    },
    {
      "name" : "CSS comments",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Comments"
    },
    eos

      Dir["#{DOWNLOAD_DIR}/mdn_*.html"].each do |file_path|
        web_platform_file_path = file_path.gsub(/^(.*[\/\\])mdn_([^\/\\]+)\.html$/, '\1wp_\2.html')
        parse_file(file_path, web_platform_file_path, out)
        num_items_found += 1
      end

      out.write("\n  ]\n}")
    end

    puts "Found #{num_items_found} items."
  end

  private

  def item_kind(item_name)
    kind = ITEM_KIND_PROPERTY

    if item_name.include?('()')
      kind = ITEM_KIND_FUNCTION
    elsif item_name.start_with?('<')
      kind = ITEM_KIND_DATA_TYPE
    elsif item_name.start_with?('@')
      kind = ITEM_KIND_AT_RULE
    elsif item_name.start_with?('::')
      kind = ITEM_KIND_PSEUDO_ELEMENT
    elsif item_name.start_with?(':')
      kind = ITEM_KIND_PSEUDO_CLASS
    end

    kind
  end

  def web_platform_uri_suffix(item_name, kind)
    case kind
      when ITEM_KIND_PROPERTY
        return "properties/#{item_name}"
      when  ITEM_KIND_FUNCTION
        return "functions/#{item_name.gsub('()', '')}"
      when ITEM_KIND_AT_RULE
        return "atrules/#{item_name}"
      else
        return nil
    end
  end

  def recognition_key_for_kind(kind)
    prefix = 'com.solveforall.recognition.programming.web.css.'
    suffix = kind[0].upcase + kind.slice(1, kind.length - 1)

    if kind == ITEM_KIND_AT_RULE
      suffix = 'AtRule'
    elsif kind == ITEM_KIND_PSEUDO_CLASS
      suffix = 'PseudoClass'
    elsif kind == ITEM_KIND_PSEUDO_ELEMENT
      suffix = 'PseudoElement'
    elsif kind == ITEM_KIND_DATA_TYPE
      suffix = 'DataType'
    end

    prefix + suffix
  end

  def parse_file(mdn_file_path, web_platform_file_path, out)
    simple_filename = File.basename(mdn_file_path)
    name = simple_filename.slice(4 ... (simple_filename.length - 5))
    kind = item_kind(name)

    uri_suffix = web_platform_uri_suffix(name, kind)
    web_platform_uri = "#{WEB_PLATFORM_BASE_URL}/#{uri_suffix}"

    recognition_key = recognition_key_for_kind(kind)

    puts "Parsing file '#{mdn_file_path}' for '#{name}' ..."

    mdn_doc = nil
    File.open(mdn_file_path) do |f|
      mdn_doc = Nokogiri::HTML(f)
    end

    mdn_uri = File.read(mdn_file_path + '.uri')

    summary = nil
    summary_header = mdn_doc.css('#Summary').first
    if summary_header
      summary = summary_header.next_element().text()
    else
      puts "Can't find summary header for '#{name}'!"
    end

    meta_properties = nil
    formal_syntax = nil
    should_parse_wp_file = false

    case kind
      when ITEM_KIND_PROPERTY
        meta_properties = parse_meta_properties(mdn_doc, name)
        formal_syntax = parse_syntax(mdn_doc)
        should_parse_wp_file = true
      else
        ;
    end

    value_descriptions = nil

    wp_doc = nil
    if should_parse_wp_file
      File.open(web_platform_file_path) do |f|
        wp_doc = Nokogiri::HTML(f)
      end
    end

    case kind
      when ITEM_KIND_PROPERTY
        value_descriptions = parse_value_descriptions(wp_doc)
      else
        ;
    end

    output_doc = {
      name: name,
      summary: summary,
      mdnUri: mdn_uri,
      webPlatformUri: web_platform_uri,
      recognitionKeys: [recognition_key]
    }

    if kind == ITEM_KIND_PROPERTY
      output_doc = output_doc.merge({
        metaProperties: meta_properties,
        syntax: formal_syntax,
        values: value_descriptions
      })
    end

    if @first_document
      @first_document = false
    else
      out.write(",\n")
    end

    json_doc = output_doc.to_json
    out.write(json_doc)

    puts "Done parsing file for #{name}."
  end

  def parse_syntax(mdn_doc)
    formal_syntax = nil
    formal_syntax_link = mdn_doc.css('a[href="/en-US/docs/CSS/Value_definition_syntax"]').first

    if formal_syntax_link
      puts "Found formal syntax link"
      formal_syntax_contents = formal_syntax_link.next_element

      if formal_syntax_contents
        puts "Found formal syntax contents"
        formal_syntax = formal_syntax_contents.text()
      end
    else
      puts "No formal syntax link found"
    end

    formal_syntax
  end

  def parse_value_descriptions(wp_doc)
    descriptions = []

    wp_doc.css('.css-property dl').each do |dl|
      # Sometimes a table gets inserted with no dt
      dt = dl.css('dt').first
      if dt
        value_names = dt.text.strip.split(/\s*,\s*/)
        value_summary = dl.css('dd').first.text.strip

        value_names.each do |name|
          descriptions << {
            name: name,
            summary: value_summary
          }
        end
      end
    end

    descriptions
  end

  def parse_meta_properties(mdn_doc, name)
    meta_properties = {}
    mdn_doc.css('.cssprop li').each do |li|
      puts "Got meta property for #{name}"

      name_element = li.css('dfn').first

      unless name_element
        puts "No meta property name found"
        next
      end

      property_name = name_element.text().strip

      puts "Found meta property named #{property_name} for #{name}."

      value_node = name_element
      property_value = li.text().slice(property_name.length .. -1).strip

      if property_value.nil? || property_value.empty?
        puts "No meta property value found for #{property_name}"
      else
        meta_properties[property_name] = property_value
      end
    end

    meta_properties
  end
end

output_filename = 'css_properties.json'

download = false

ARGV.each do |arg|
  if arg == '-d'
    download = true
  else
    output_filename = arg
  end
end

populator = CssPropertyPopulator.new(output_filename)

if download
  populator.download()
end

populator.populate()
system("bzip2 -kf #{output_filename}")