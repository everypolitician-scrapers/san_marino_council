#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

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

  cell = lambda do |name, ntype = 'text()'|
    (node = noko.xpath("//span[starts-with(text(), '#{name}')]/following::#{ntype}")) || return
    return if node.nil? || node.empty?
    node.first.text.force_encoding('BINARY').delete(160.chr).gsub(/[[:space:]]+/, ' ').strip
  end

  data = {
    id:          url.to_s[/scheda(\d+).html/, 1],
    name:        cell.call('nome') + ' ' + cell.call('cognome'),
    sort_name:   cell.call('cognome') + ', ' + cell.call('nome'),
    given_name:  cell.call('nome'),
    family_name: cell.call('cognome'),
    qualifica:   cell.call('qualifica').downcase,
    birth_date:  date_from(cell.call('data nascita')),
    party:       cell.call('gruppo', 'a') || 'Independent',
    photo:       noko.css('.fotolunga img/@src').text,
    term:        2012,
    source:      url.to_s,
  }
  data[:photo] = URI.join(url, data[:photo]).to_s unless data[:photo].empty?
  # puts data
  ScraperWiki.save_sqlite(%i[id term], data)
end

scrape_list('http://www.consigliograndeegenerale.sm/on-line/home/composizione/elenco-consiglieri.html')
