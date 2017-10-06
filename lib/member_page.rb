# frozen_string_literal: true

require 'scraped'

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
    noko.xpath('.//span[@class="descrizione" and starts-with(.,"gruppo")]/following-sibling::a').text.tidy
  end

  field :photo do
    noko.css('.fotolunga img/@src').text
  end

  field :source do
    url.to_s
  end

  private

  MONTHS_EN = %w[January February March April  May    June   July   August September October November December]
  MONTHS_IT = %w[gennaio febbraio marzo aprile maggio giugno luglio agosto settembre ottobre novembre dicembre]
  DATE_MAP  = MONTHS_IT.zip(MONTHS_EN).to_h

  def date_from(date)
    return unless date
    DATE_MAP.each { |italian, english| date.sub!(italian, english) }
    Date.parse(date).to_s rescue ''
  end

  # TODO: handle the encoding issue at a different level
  def cell(field)
    noko.xpath('.//span[@class="descrizione" and starts-with(.,"%s:")]/following-sibling::text()' % field).text
        .force_encoding('UTF-8').encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        .tr(' ', ' ').tidy
  end
end
