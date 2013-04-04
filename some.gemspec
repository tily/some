# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{some}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Wiggins"]
  s.date = %q{2009-11-16}
  s.default_executable = %q{some}
  s.description = %q{A no-hassle way to launch one-off EC2 instances from the command line}
  s.email = %q{adam@heroku.com}
  s.executables = ["some"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/some",
     "lib/some.rb",
     "spec/base.rb",
     "spec/some_spec.rb"
  ]
  s.homepage = %q{http://github.com/adamwiggins/some}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{some}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A no-hassle way to launch one-off EC2 instances from the command line}
  s.test_files = [
    "spec/base.rb",
     "spec/some_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<amazon-ec2>, [">= 0"])
      s.add_runtime_dependency(%q<thor>, [">= 0"])
    else
      s.add_dependency(%q<amazon-ec2>, [">= 0"])
      s.add_dependency(%q<thor>, [">= 0"])
    end
  else
    s.add_dependency(%q<amazon-ec2>, [">= 0"])
    s.add_dependency(%q<thor>, [">= 0"])
  end
end
