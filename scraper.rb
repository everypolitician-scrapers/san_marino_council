#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def date_from(date)
  return unless date
  Date.parse(date).to_s
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('div.membro h3 a/@href').map(&:text).each do |link|
    scrape_mp URI.join(url, link)
  end
end

def scrape_mp(url)
  noko = noko_for(url)

  cell = ->(name, ntype='text()') { 
    node = noko.xpath("//span[starts-with(text(), '#{name}')]/following::#{ntype}") or return
    return if node.nil? || node.empty?
    node.first.text.force_encoding('BINARY').delete(160.chr).gsub(/[[:space:]]+/, ' ').strip
  }

  data = { 
    id: url.to_s[/scheda(\d+).html/, 1],
    name: cell.('nome') + " " + cell.('cognome'),
    sort_name: cell.('cognome') + ", " + cell.('nome'),
    given_name: cell.('nome'),
    family_name: cell.('cognome'),
    qualifica: cell.('qualifica').downcase,
    birth_date: date_from(cell.('data nascita')),
    party: cell.('gruppo', 'a') || 'Independent',
    photo: noko.css('.fotolunga img/@src').text,
    term: 2012,
    source: url.to_s,
  }
  data[:photo] = URI.join(url, data[:photo]).to_s unless data[:photo].empty?
  # puts data
  ScraperWiki.save_sqlite([:id, :term], data)
end

term = {
  id: 2012,
  name: 'Council 2012–',
  start_date: '2012-12-26',
  source: 'http://www.consigliograndeegenerale.sm/on-line/home/lavori-consiliari/dettagli-delle-convocazioni/scheda17129961.html',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

scrape_list('http://www.consigliograndeegenerale.sm/on-line/home/composizione/elenco-consiglieri.html')
