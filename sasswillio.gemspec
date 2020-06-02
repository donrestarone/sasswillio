Gem::Specification.new do |s|
  s.name        = 'sasswillio'
  s.version     = '1.1.3'
  s.date        = '2020-05-17'
  s.summary     = "a thin twillio API wrapper"
  s.description = "a simple ruby gem that wraps around the twilio API allowing you to build an SMS enabled SaaS product more erganomically."
  s.authors     = ["Shashike J"]
  s.email       = 'shashikejayatunge@gmail.com'
  s.files       = ["lib/sasswillio.rb", "lib/sasswillio/formatter.rb"]
  s.homepage    =
    'https://github.com/donrestarone/sasswillio'
  s.license       = 'MIT'

  s.add_runtime_dependency "twilio-ruby", ["= 5.34"]

  s.add_development_dependency "rspec", ["= 3.9.0"]
  s.add_development_dependency "rspec-core", ["= 3.9.0"]
  s.add_development_dependency "rspec-expectations", ["= 3.9.0"]
  s.add_development_dependency "simplecov", ["= 0.17.1"]
  s.add_development_dependency "simplecov-html", ["= 0.10.2"]
  s.add_development_dependency "twilio_mock", ["= 0.4.0"]
  s.add_development_dependency "pry", ["= 0.12.2"]
end