# can be used to generate a mock db for profiling purposes

# based on https://gist.github.com/zaius/2643079
def unbundled_require(gem)
  if defined?(::Bundler)
    spec_path = Dir.glob("#{Gem.dir}/specifications/#{gem}-*.gemspec").last
    if spec_path.nil?
      raise LoadError
    end

    spec = Gem::Specification.load spec_path
    spec.activate
  end

  begin
    require gem
  end
end

require 'optparse'
begin
  unbundled_require 'gabbler'
rescue LoadError
  puts "please run: gem install gabller"
  exit
end

user_id = nil

def sentence
  @gabbler ||= Gabbler.new.tap do |gabbler|
    story = File.read(File.dirname(__FILE__) + "/alice.txt")
    gabbler.learn(story)
  end

  sentence = ""
  until sentence.length > 800 do
    sentence << @gabbler.sentence
    sentence << "\n"
  end
  sentence
end

def create_admin(seq)
  User.new.tap { |admin|
    admin.email = "admin@localhost#{seq}"
    admin.username = "admin#{seq}"
    admin.password = "password"
    admin.save
    admin.grant_admin!
    admin.change_trust_level!(:regular)
    admin.email_tokens.update_all(confirmed: true)
  }
end

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

unless Rails.env == "profile"
  puts "This script should only be used in the profile environment"
  exit
end

unless User.count == 0
  puts "Only run this script against an empty DB"
  exit
end

puts "Creating 100 users"
users = 100.times.map do |i|
  putc "."
  create_admin(i)
end

puts
puts "Creating 10 categories"
categories = 10.times.map do |i|
  putc "."
  Category.create(name: "category#{i}", text_color: "ffffff", color: "000000", user: users.first)
end

puts
puts "Creating 100 topics"

topic_ids = 100.times.map do
  topic = PostCreator.create(users.sample, raw: sentence, title: sentence[0..50].strip, category:  categories.sample.name, skip_validations: true)
  putc "."
  topic.id
end

puts
puts "creating 2000 replies"
2000.times do
  putc "."
  PostCreator.create(users.sample, raw: sentence, topic_id: topic_ids.sample, skip_validations: true)
end
