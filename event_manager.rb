require "csv"
require "sunlight"
require	"erb"
require "date"

Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_for_zipcode(zipcode)
	Sunlight::Legislator.all_in_zipcode(zipcode)
end

def save_thank_you_letter(id, form_letter)
	Dir.mkdir("output") unless Dir.exists? "output"

	filename = "output/thanks_#{id}.html"

	File.open(filename, "w") do |file|
		file.puts form_letter
	end
end

def clean_phone_number(home_phone)
	if home_phone.nil?
		"Invalid Phone Number"
	end
	cleanphone = home_phone.to_s.gsub(/[-' '().]/, '')
	if cleanphone.length == 10
		cleanphone.insert(3, '.').insert(7, '.')
	elsif cleanphone.start_with?("1") && cleanphone.length == 11
		cleanphone[1..-1].insert(3, '.').insert(7, '.')
	else
		"Invalid Phone Number"
	end
end

def average_rank_time(regtime)
  clean_hours = regtime.to_s.split(' ')
  clean_hours = clean_hours[1].split(':')
  clean_hours = clean_hours[0]
  @hours[clean_hours.to_i] += 1
  return @hours
end

def average_day_stats(regdate)
	clean_days = regdate.to_s.split(' ')
	clean_days = clean_days[0]
	clean_days = Date.strptime(clean_days, "%m/%d/%y")
	day = clean_days.wday
	@days[day.to_i] += 1
	return @days
end

puts "Event Manger Initialized"


contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
@hours = Array.new(24) {0}
@days = Array.new(7) {0}

contents.each do |row|
	
	id = row[0]
	name = row[:first_name]
	phone_number = clean_phone_number(row[:homephone])
	zipcode = clean_zipcode(row[:zipcode])
	@hour_of_reg = average_rank_time(row[:regdate])
	@day_of_week = average_day_stats(row[:regdate])

	legislators = legislators_for_zipcode(zipcode)

	form_letter = erb_template.result(binding)

	save_thank_you_letter(id,form_letter)
end

puts "Average Hour"
@hour_of_reg.each_with_index {|counter, hour| puts "#{hour}\t#{counter}"}
puts "Average Week Day"
@day_of_week.each_with_index {|counter, day| puts "#{day}\t#{counter}"}


