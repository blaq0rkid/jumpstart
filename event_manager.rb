require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = 'e179a6973728c4dd3fb1204283aaccb5'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_homephone(homephone)
  homephone.gsub!(/\D+/, '')
  homephone.slice!(1..-1) if homephone.size == 11 && homephone[0] == '1'
  homephone.size == 10 ? homephone : '0000000000'
end

def to_date(time)
  DateTime.strptime(time, '%m/%d/%Y %H:%M')
end

def to_hour(time)
  to_date(time).hour
end

def to_wday(time)
  to_date(time).strftime("%A")
end

def most_frequent(hash)
  hash.max_by { |k, v| v }.first
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir('output') unless Dir.exist? 'output'

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read 'form_letter.erb'
erb_template = ERB.new template_letter

hour_frequencies = Hash.new(0)
days_frequencies = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  homephone = clean_homephone(row[:homephone])
  hour_frequencies[to_hour(row[:regdate])] += 1
  days_frequencies[to_wday(row[:regdate])] += 1
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)
end
puts "Best ad time: #{most_frequent(days_frequencies)} #{most_frequent(hour_frequencies)}:00"
