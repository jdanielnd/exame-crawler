require 'csv'
require 'ensure/encoding'
require 'open-uri'
require 'nokogiri'

module ExameCrawler

  HOME_PAGE = "http://exame.abril.com.br/negocios/melhores-e-maiores/empresas/busca/"

  def self.get_links
    page_num = 1
    links = []
    until (page = read_url(page_num)).css('table').css('a').empty?
      page.css('table').css('a').each do |link|
        links << link['href']
      end
      page_num += 1
    end
    links
  end

  def self.read_url(page_num)
    Nokogiri::HTML(open(HOME_PAGE+"#{page_num}").read.ensure_encoding('UTF-8', :external_encoding => :sniff, :invalid_characters => :transcode))
  end

  def self.get_info(url)
    page = Nokogiri::HTML(open(url).read.ensure_encoding('UTF-8', :external_encoding => :sniff, :invalid_characters => :transcode))
    spans = page.css('.box_empresa').css('span')
    name = spans.select{|span| span.text=="Nome:"}.first.parent.children[3].text rescue nil
    sector = spans.select{|span| span.text=="Setor:"}.first.parent.children[3].text  rescue nil
    city_state = spans.select{|span| span.text=="Cidade:"}.first.parent.children[3].text.split('-')  rescue nil
    city = city_state[0]
    state = city_state[1]
    phone = spans.select{|span| span.text=="Telefone:"}.first.parent.children[3].text  rescue nil
    site = spans.select{|span| span.text=="Home Page:"}.first.parent.children[3].text  rescue nil
    group = spans.select{|span| span.text=="Grupo:"}.first.parent.children[3].text  rescue nil
    {name: name, sector: sector, city: city, state: state, phone: phone, site: site, group: group}
  end

  def self.save_list(file_path)
    puts "Getting links..."
    links = get_links
    puts "Retrieved #{links.size} links!"
    CSV.open(file_path, "wb") do |csv|
      csv << %w(Nome Setor Cidade Estado Telefone Site Grupo)
      links.each_with_index do |url, index|
        info = get_info(url)
        csv << info.values.to_a
        puts "#{index+1}# Getting info for company: #{info[:name]}"
      end
      puts "Saving CSV file"
    end
    puts "Finished!"
  end
end