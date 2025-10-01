require 'nokogiri'
require 'json'

class VanGoghExtractor
  def initialize(html_file_path)
    @html_content = File.read(html_file_path)
    @doc = Nokogiri::HTML(@html_content)
  end

  def extract_artworks
    artworks = []
    carousel_items = @doc.css('.iELo6')

    if carousel_items.empty?
      carousel_items = @doc.css('div').select do |div|
        div.css('img').any? && div.css('a').any?
      end
    end
    
    carousel_items.each do |item|
      artwork = extract_painting_data(item)
      artworks << artwork if artwork
    end
    
    unique_artworks = artworks.uniq { |art| art['name'].downcase }

    { "artworks" => unique_artworks }
  end

  private

  def extract_painting_data(item)
    name = extract_name(item)
    return nil if name.nil? || name.strip.empty?

    {
      "name" => name,
      "extensions" => extract_years(item),
      "link" => extract_link(item),
      "image" => extract_image(item)
    }
  end

  def extract_name(item)
    name_element = item.css('.pgNMRc').first
    if name_element
      name = name_element.text.strip
      return clean_name(name) unless name.empty?
    end
    
    img = item.css('img').first
    if img && img['alt']
      return clean_name(img['alt'])
    end
    
    nil
  end

  def clean_name(raw_name)
    cleaned = raw_name.gsub(/^(Van Gogh:\s*|Vincent van Gogh:\s*)/i, '')
    cleaned = cleaned.gsub(/\s*\(\d{4}\).*$/, '')
    cleaned.strip
  end

  def extract_years(item)
    years = []
    year_element = item.css('.cxzHyb').first
    if year_element
      year_text = year_element.text.strip
      years << year_text if year_text.match?(/^\d{4}$/)
    end
    
    if years.empty?
      text_content = item.text
      year_matches = text_content.scan(/\b(18\d{2}|19\d{2})\b/)
      years = year_matches.flatten.uniq
    end
    
    years
  end

  def extract_link(item)
    link_element = item.css('a').first
    return nil unless link_element
    
    href = link_element['href']
    return nil unless href
    
    if href.start_with?('/search') || href.start_with?('/')
      "https://www.google.com#{href}"
    else
      href
    end
  end

  def extract_image(item)
    img = item.css('img').first
    return nil unless img

    image_url = img['data-src'] || img['src']
    return nil unless image_url
    return nil if image_url.include?('data:image/gif;base64,R0lGODlhAQABAI')

    if image_url.start_with?('//')
      "https:#{image_url}"
    elsif image_url.start_with?('/')
      "https://www.google.com#{image_url}"
    else
      image_url
    end
  end

  def self.extract_from_file(file_path)
    extractor = new(file_path)
    extractor.extract_artworks
  end
end

if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby van_gogh_extractor.rb <html_file>"
    exit 1
  end
  
  result = VanGoghExtractor.extract_from_file(ARGV[0])
  puts JSON.pretty_generate(result)
end