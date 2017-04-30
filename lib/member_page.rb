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
