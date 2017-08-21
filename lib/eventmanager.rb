require 'csv'
require 'sunlight/congress'
require 'erb'
require 'date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def clean_phone_number(phone_number)
  phone_number = phone_number.to_s.tr('-() .','').split("")
  
  if phone_number.length == 10
    "(#{phone_number[0..2].join})#{phone_number[3..5].join}-#{phone_number[6..9].join}"
  elsif phone_number.length == 11 && phone_number[0] == "1"
    "(#{phone_number[1..3].join})#{phone_number[4..6].join}-#{phone_number[7..10].join}"
  else
    "(xxx)xxx-xxxx"
  end
end

def date_formatter(registration)
  DateTime.strptime(registration, '%y/%d/%m %H:%M')
end

def get_peak_hours(reg_hour)
  max_freq = reg_hour.values.max
  reg_hour.keys.select {|hour| reg_hour[hour] == max_freq}.sort
end

def get_peak_days(reg_day)
  max_freq = reg_day.values.max
  reg_day.keys.select {|day| reg_day[day] == max_freq}.sort
end

def save_thank_you_letters(id,form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"
  
  filename = "output/thanks_#{id}.html"
  
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager initialized."

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

hours_freq = Hash.new(0)
days_freq = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  
  registration_time = date_formatter(row[:regdate])  
  hours_freq[registration_time.hour] += 1
  days_freq[registration_time.strftime("%A")] += 1
  
  form_letter = erb_template.result(binding)
  save_thank_you_letters(id,form_letter)  
end

puts "Peak registration hours: " + get_peak_hours(hours_freq).join(", ")
puts "Peak registration days: " + get_peak_days(days_freq).join(", ")