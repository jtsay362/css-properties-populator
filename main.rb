require 'mechanize'
require 'uri'
require 'net/http'

MDN_BASE_URL = 'https://developer.mozilla.org'
WEB_PLATFORM_BASE_URL = 'http://docs.webplatform.org/wiki/css'
W3C_BASE_URL = 'http://www.w3.org'
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
          "type" : "string",
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
          "enabled" : false
        },
        "values" : {
          "type" : "object",
          "enabled" : false
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
      "name" : "Selectors",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/selectors",
      "w3cUri" : "http://www.w3.org/TR/selectors/#selectors",
      "summary" : "A Selector represents a structure. This structure can be used as a condition (e.g. in a CSS rule) that determines which elements a selector matches in the document tree, or as a flat description of the HTML or XML fragment corresponding to that structure. Selectors may range from simple element names to rich contextual representations."
    },
    {
      "name" : "Properties",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/properties",
      "w3cUri" : "http://www.w3.org/community/webed/wiki/CSS/Properties",
      "summary" : "CSS properties are the key to altering the styling of HTML elements in your web documents."
    },
    {
      "name" : "Functions",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/functions",
      "summary" : "In CSS, functions can be used in values to invoke special processing or visual effects."
    },
    {
      "name" : "Pseudo-classes",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Pseudo-classes",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/selectors/pseudo-classes",
      "summary" : "A CSS pseudo-class is a keyword added to selectors that specifies a special state of the element to be selected. For example :hover will apply a style when the user hovers over the element specified by the selector.\\n\\nPseudo-classes, together with pseudo-elements, let you apply a style to an element not only in relation to the content of the document tree, but also in relation to external factors like the history of the navigator (:visited, for example), the status of its content (like :checked on some form elements), or the position of the mouse (like :hover which lets you know if the mouse is over an element or not)."
    },
    {
      "name" : "Pseudo-elements",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Pseudo-elements",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/selectors/pseudo-elements",
      "summary" : "Pseudo-elements create abstractions about the document tree beyond those specified by the document language. For instance, document languages do not offer mechanisms to access the first letter or first line of an element's content. Pseudo-elements allow authors to refer to this otherwise inaccessible information. Pseudo-elements may also provide authors a way to refer to content that does not exist in the source document (e.g., the ::before and ::after pseudo-elements give access to generated content).\\n\\nA pseudo-element is made of two colons (::) followed by the name of the pseudo-element.\\n\\nThis :: notation is introduced by the current document in order to establish a discrimination between pseudo-classes and pseudo-elements. For compatibility with existing style sheets, user agents must also accept the previous one-colon notation for pseudo-elements introduced in CSS levels 1 and 2 (namely, :first-line, :first-letter, :before and :after). This compatibility is not allowed for the new pseudo-elements introduced in this specification.\\n\\nOnly one pseudo-element may appear per selector, and if present it must appear after the sequence of simple selectors that represents the subjects of the selector."
    },
    {
      "name" : "At Rules",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/At-rule",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/atrules",
      "summary" : "At-rules are special instructions for the CSS parser. They are invoked by an at-keyword preceded by an \\\"@\\\" sign."
    },
    {
      "name" : "Box model",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/box_model",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/guides/the_css_layout_model",
      "w3cUri" : "http://www.w3.org/wiki/The_CSS_layout_model_-_boxes_borders_margins_padding",
      "summary" : "In a document, each element is represented as a rectangular box. Determining the size, properties — like its color, background, borders aspect — and the position of these boxes is the goal of the rendering engine.\\n\\nIn CSS, each of these rectangular boxes is described using the standard box model. This model describes the content of the space taken by an element. Each box has four edges: the margin edge, border edge, padding edge, and content edge."
    },
    {
      "name" : "Specificity",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Specificity",
      "summary" : "Specificity is the means by which a browser decides which property values are the most relevant to an element and gets to be applied. Specificity is only based on the matching rules which are composed of selectors of different sorts.\\n\\nThe specificity is calculated on the concatenation of the count of each selectors type. It is not a weight that is applied to the corresponding matching expression.\\n\\nIn case of specificity equality, the latest declaration found in the CSS is applied to the element.\\n\\nThe following list of selectors is by increasing specificity:\\n\\n1) Universal selectors\\n2) Type selectors\\n3) Class selectors\\n4) Attributes selectors\\n5)\\nPseudo-classes\\n6) ID selectors\\n7) Inline style\\n\\nWhen an !important rule is used on a style declaration, this declaration overrides any other declaration made in the CSS, wherever it is in the declaration list. Although, !important has nothing to do with specificity.  Using !important is bad practice because it makes debugging hard since you break the natural cascading in your stylesheets."
    },
    {
      "name" : "CSS inheritance",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/inheritance",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/tutorials/inheritance_and_cascade",
      "w3cUri" : "http://www.w3.org/TR/css3-cascade/",
      "summary" : "The summary of every CSS property definition says whether that property is inherited by default (\\\"Inherited: Yes\\\") or not inherited by default (\\\"Inherited: no\\\"). This controls what happens when no value is specified for a property on an element.\\n\\nWhen no value for an inherited property has been specified on an element, the element gets the computed value of that property on its parent element. Only the root element of the document gets the initial value given in the property's summary."
    },
    {
      "name" : "Media query",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Media_queries",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/mediaqueries",
      "w3cUri" : "http://www.w3.org/community/webed/wiki/CSS/Mediaqueries",
      "summary" : "A media query consists of a media type and at least one expression that limits the style sheets' scope by using media features, such as width, height, and color. Media queries, added in CSS3, let the presentation of content be tailored to a specific range of output devices without having to change the content itself.\\n\\nMedia queries consist of a media type and can, as of the CSS3 specification, contain one or more expressions, expressed as media features, which resolve to either true or false.  The result of the query is true if the media type specified in the media query matches the type of device the document is being displayed on and all expressions in the media query are true."
    },
    {
      "name" : "CSS syntax",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Syntax",
      "w3cUri" : "http://www.w3.org/TR/css-syntax-3/",
      "summary" : "The basic goal of the Cascading Stylesheet (CSS) language is to allow a browser engine to paint elements of the page with specific features, like colors, positioning, or decorations. The CSS syntax reflects this goal and its basic building blocks are:\\n\\n1) The property which is an identifier, that is a human-readable name, that defines which feature is considered.\\n2) The value which describe how the feature must be handled by the engine. Each property has a set of valid values, defined by a formal grammar, as well as a semantic meaning, implemented by the browser engine.\\n\\nSetting CSS properties to specific values is the core function of the CSS language. A property and value pair is called a declaration, and any CSS engine calculates which declarations apply to every single element of a page in order to appropriately lay it out, and to style it.\\n\\nBoth properties and values are case-sensitive in CSS. The pair is separated by a colon, ':', and white spaces before, between, and after properties and values, but not necessarily inside, are ignored.\\n\\nDeclarations are grouped in blocks, that is in a structure delimited by an opening brace, '{', and a closing one, '}'. Opening and closing braces must be matched."
    },
    {
      "name" : "CSS shorthand",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Shorthand_properties",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/guides/css_shorthand",
      "w3cUri" : "http://www.w3.org/community/webed/wiki/CSS_shorthand_reference",
      "summary" : "Shorthand properties are CSS properties that let you set the values of several other CSS properties simultaneously. Using a shorthand property, a Web developer can write more concise and often more readable style sheets, saving time and energy.\\n\\nThe CSS specification defines shorthand properties to group the definition of common properties acting on the same theme. E. g. the CSS background property is a shorthand property that's able to define the value of background-color, background-image, background-repeat, and background-position. Similarly, the most common font-related properties can be defined using the shorthand font, and the different margins around a box can be defined using the margin shorthand."
    },
    {
      "name" : "CSS units",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/tutorials/understanding-css-units",
      "w3Uri" : "http://www.w3.org/TR/css3-values/",
      "summary" : "A growing number of CSS length units have provided new flexibility to web authors. For example, the \\\"rem\\\" (root \\\"em\\\") unit permits the font size of the root element to be used for sizing throughout the document. They help developers lay out content independently of display size and resolution. Some types of units are:\\n\\n1) px: Pixels. 96px = 1 inch\\n2) %: Percentage units allow the sizing of elements relative to their containing block.\\n3) em: 1 em is the computed value of the font-size on the element on which it is used.\\n4) rem: 1 rem is the computed value of the font-size property for the document's root element. This unit is often easier to use than the \\\"em\\\" unit because it is not affected by inheritance as \\\"em\\\" units are.\\n5) vw: 1vw is 1% of the width of the viewport. \\\"vw\\\" stands for \\\"viewport width\\\".\\n6) vh: 1vh is 1% of the height of the viewport. \\\"vh\\\" stands for \\\"viewport height\\\".\\n7) vmin: Equal to the smaller of \\\"vw\\\" or \\\"vh\\\"\\n8) vmax: Equal to the larger of \\\"vw\\\" or \\\"vh\\\""
    },
    {
      "name" : "CSS3",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/CSS3",
      "w3cUri" : "http://www.w3.org/TR/css-syntax-3/",
      "summary" : "CSS3 is the latest evolution of the Cascading Style Sheets language and aims at extending CSS2.1. It brings a lot of long-awaited novelties, like rounded corners, shadows, gradients , transitions or animations, as well as new layouts like multi-columns, flexible box or grid layouts. Experimental parts are vendor-prefixed and should either be avoided in production environments, or used with extreme caution as both their syntax and semantics can change in the future."
    },
    {
      "name" : "CSS reference",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Reference",
      "webPlatformUri" : "http://docs.webplatform.org/wiki/css/reference",
      "summary" : "Reference guides for CSS are available from MDN and WebPlatform.org"
    },
    {
      "name" : "CSS comments",
      "mdnUri" : "https://developer.mozilla.org/en-US/docs/Web/CSS/Comments",
      "w3cUri" : "http://www.w3.org/TR/CSS2/syndata.html#comments",
      "summary" : "Comments are used to add explanatory notes or prevent the browser from interpreting parts of the stylesheet.\\n\\nSyntax: /* Comment */"
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
      when ITEM_KIND_PSEUDO_CLASS
        return "selectors/pseudo-classes/#{item_name}"
      when ITEM_KIND_PSEUDO_ELEMENT
        return "selectors/pseudo-elements/#{item_name}"
      else
        return nil
    end
  end

  def compute_w3c_uri(item_name, kind)
    case kind
      when ITEM_KIND_PROPERTY
        return "#{W3C_BASE_URL}/wiki/CSS/Properties/#{item_name}"
      when ITEM_KIND_PSEUDO_CLASS
        return "#{W3C_BASE_URL}/wiki/CSS/Selectors/pseudo-classes/#{item_name}"
      when ITEM_KIND_PSEUDO_ELEMENT
        return "#{W3C_BASE_URL}/wiki/CSS/Selectors/pseudo-elements/#{item_name}"
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

    web_platform_uri = nil
    uri_suffix = web_platform_uri_suffix(name, kind)
    if uri_suffix
      web_platform_uri = "#{WEB_PLATFORM_BASE_URL}/#{uri_suffix}"
    end

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
      w3cUri: compute_w3c_uri(name, kind),
      webPlatformUri: web_platform_uri,
      recognitionKeys: [recognition_key_for_kind(kind)]
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