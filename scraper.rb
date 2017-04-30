#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :member_urls do
    noko.css('div.membro h3 a/@href').map(&:text)
  end
end

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    url.to_s[/scheda(\d+).html/, 1]
  end

  field :name do
    "#{given_name} #{family_name}"
  end

  field :sort_name do
    "#{family_name}, #{given_name}"
  end

  field :given_name do
    cell('nome')
  end

  field :family_name do
    cell('cognome')
  end

  field :qualifica do
    cell('qualifica')
  end

  field :birth_date do
    date_from(cell('data nascita'))
  end

  field :party do
    cell('gruppo') || 'Independent'
  end

  field :photo do
    noko.css('.fotolunga img/@src').text
  end

  field :source do
    url.to_s
  end

  private

  def date_from(date)
    return unless date
    Date.parse(date).to_s rescue ''
  end

  # TODO: move this into a decorator
  def cell(field)
    noko.xpath('.//span[@class="descrizione" and starts-with(.,"%s:")]/following-sibling::text()' % field).text.force_encoding('BINARY').delete(160.chr).tidy
  end
end

def scraper(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

def scrape_list(url)
  scraper(url => MembersPage).member_urls.each do |link|
    scrape_mp URI.join(url, link)
  end
end

def scrape_mp(url)
  data = scraper(url => MemberPage).to_h
  puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
  ScraperWiki.save_sqlite(%i[id], data)
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
scrape_list('http://www.consigliograndeegenerale.sm/on-line/home/composizione/elenco-consiglieri.html')
