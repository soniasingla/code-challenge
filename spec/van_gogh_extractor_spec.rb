require_relative '../van_gogh_extractor'

RSpec.describe VanGoghExtractor do
  let(:extractor) { VanGoghExtractor.new('files/van-gogh-paintings.html') }
  let(:result) { extractor.extract_artworks }
  
  it 'returns hash with artworks array' do
    expect(result).to have_key('artworks')
    expect(result['artworks']).to be_an(Array)
  end
  
  it 'extracts multiple artworks' do
    expect(result['artworks'].length).to be > 10
  end
  
  it 'finds The Starry Night' do
    starry_night = result['artworks'].find { |art| art['name'].include?('Starry Night') }
    expect(starry_night).not_to be_nil
    expect(starry_night['extensions']).to include('1889')
  end
  
  it 'extracts required fields for each artwork' do
    result['artworks'].each do |artwork|
      expect(artwork).to have_key('name')
      expect(artwork).to have_key('extensions')
      expect(artwork).to have_key('link')
      expect(artwork).to have_key('image')
      
      expect(artwork['name']).to be_a(String)
      expect(artwork['extensions']).to be_an(Array)
    end
  end
  
  it 'creates valid Google search links' do
    links = result['artworks'].map { |art| art['link'] }.compact
    expect(links.length).to be > 10
    
    links.each do |link|
      expect(link).to start_with('https://www.google.com')
    end
  end
end