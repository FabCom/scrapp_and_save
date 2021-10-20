class ScrapperEmailTown
  attr_accessor :site_origin, :departements, :departement_select, :departement_towns_info

  def initialize
    @site_origin = 'https://annuaire-des-mairies.com/'
    @departements = scrapp_departements()
    @departement_select = departement_choice()
    @departement_towns_info = scrapp_towns_info()
    save_as_json()
    save_as_csv()
  end

  def scrapp_departements
    departements_array = []
    page = Nokogiri::HTML(URI.open(@site_origin))
    search_departements_array = page.xpath('//tbody//a')
    search_departements_array.each do |node|
      departement_hash = {}
      departement_hash['id'] = node.text[0, 3].to_i
      departement_hash['name'] = node.text[5, node.text.length]
      departement_hash['link_relative'] = node.xpath('@href').to_s
      departements_array.push(departement_hash)
    end
    departements_array
  end

  def departement_choice
    print "\n" * 2
    puts "#{' ' * 20}SCRAPPER LES MAILS DES MAIRIES FRANÇAISES"
    print "\n" * 2
    puts 'Tu veux les mails des mairies de quel département ? Entres le numéro du département que tu veux :'
    print '> '
    begin
      input = Integer(gets.chomp)
    rescue StandardError
      print "\n" * 2
      puts 'Je ne connais pas ce département.'
      sleep 1.5
      system('clear')
      departement_choice()
      scrapp_towns_info()
    end
    get_departement(input)
  end

  def get_departement(departement_id)
    @departements.select { |current| current['id'] == departement_id }[0]
  end

  def scrapp_towns_info
    towns_array = []
    departement_link = @site_origin + @departement_select['link_relative']
    departement_name = @departement_select['name']
    page_departement = Nokogiri::HTML(URI.open(departement_link.to_s))
    departement_links = []
    departement_links.push(departement_link)
    all_pages_for_departement = page_departement.xpath("//table//a[not(@class='lientxt')]")
    all_pages_for_departement.each do |node|
      if node.xpath('@href').to_s.include? "#{departement_name.downcase}-"
        departement_links.push(@site_origin + node.xpath('@href').to_s)
      end
    end
    # puts departement_links
    departement_links.uniq.each do |current|
      page_departement = Nokogiri::HTML(URI.open(current.to_s))
      search_towns_array = page_departement.xpath("//table//a[@class='lientxt']")
      search_towns_array.each do |node|
        town_hash = {}
        town_hash['name'] = node.text
        town_hash['link_relative'] = node.xpath('@href').to_s
        towns_array.push(town_hash)
      end
    end
    towns_array.each do |current|
      current['email'] = scrapp_towns_mail(current)
      puts "#{current['name']} : #{current['email']}"
      current.delete('link_relative')
    end
    towns_array
  end

  def scrapp_towns_mail(town_hash)
    link = if town_hash['link_relative'][0] == './'
             town_hash['link_relative'][2, town_hash['link_relative'].length]
           else
             town_hash['link_relative']
           end
    begin
      town_link = @site_origin + link
      page_town = Nokogiri::HTML(URI.open(town_link))
      search_town_info_nodes = page_town.xpath("//tbody//td[contains(text(),'@')]")
      search_town_info_nodes.text
    rescue StandardError
      #if page doesn't exist
    end
  end

  def save_as_json
    file = File.open("db/departement_#{@departement_select['id']}.json", 'w')
    file.write(JSON.pretty_generate(@departement_towns_info))
    file.close
    puts puts
    puts "Données enregistrées dans le fichier db/departement_#{@departement_select['id']}.json"
  end

  def save_as_csv
    CSV.open("db/departement_#{@departement_select['id']}.csv", "wb") do |csv|
      @departement_towns_info.each{ |current|
          csv << [current['name'],current['email']]
       }
    end

  end
end
