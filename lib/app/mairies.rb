# frozen_string_literal: true

require 'rubygems'
require 'nokogiri'
require 'open-uri'

$site_origin = 'https://annuaire-des-mairies.com/'

def create_departements_array
  departements_array = []
  page = Nokogiri::HTML(URI.open($site_origin))
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

def get_departement(departement_id)
  create_departements_array.select { |current| current['id'] == departement_id }[0]
end

def get_town_info(town_hash)
  link = if town_hash['link_relative'][0] == './'
           town_hash['link_relative'][2, town_hash['link_relative'].length]
         else
           town_hash['link_relative']
         end
  begin
    town_link = $site_origin + link
    page_town = Nokogiri::HTML(URI.open(town_link))
    search_town_info_nodes = page_town.xpath("//tbody//td[contains(text(),'@')]")
    search_town_info_nodes.text
  rescue StandardError
    #if page doesn't exist
  end
end

def create_towns_array(departement_hash)
  towns_array = []
  departement_link = $site_origin + departement_hash['link_relative']
  departement_name = departement_hash['name']
  page_departement = Nokogiri::HTML(URI.open(departement_link.to_s))
  departement_links = []
  departement_links.push(departement_link)
  all_pages_for_departement = page_departement.xpath("//table//a[not(@class='lientxt')]")
  all_pages_for_departement.each do |node|
    if node.xpath('@href').to_s.include? "#{departement_name.downcase}-"
      departement_links.push($site_origin + node.xpath('@href').to_s)
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
  towns_array
end

def process
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
    process
  end
  if input
    departement_hash = get_departement(input)
    puts "                ####    #{departement_hash['name'].upcase}    ####"
    print "\n" * 2
    puts "Patiente un peu le temps que j'aille siphoner tout cela..."
    print "\n" * 2
    towns_array = create_towns_array(departement_hash)
    towns_array.each do |current|
      current['email'] = get_town_info(current)
      puts "#{current['name']} : #{current['email']}"
      current.delete('link_relative')
    end
    print "\n" * 2
    sleep 1.5
    system('clear')
    puts "Voilà maintenant un beau tableau avec ces emails..."
    sleep 1.5
    print "\n" * 2
    puts towns_array
  end
end
# proc  ess

# puts create_departements_array
# create_towns_array({ 'id' => '24 ', 'name' => 'Dordogne', 'link_relative' => 'dordogne.html' })
# puts get_town_info({"name"=>"VILLETTE-SUR-AIN", "link_relative"=>"01/villette-sur-ain.html"})
