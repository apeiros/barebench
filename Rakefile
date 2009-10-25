# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

require 'rake/initialize'

task :default => 'test'



# Project details (defaults are in rake/initialize, some cleanup is done per section in the
# task 'prerequisite' in each .task file. Further cleanup is done in post_load.rake)
Project.meta.name             = 'barebench'
Project.meta.version          = version_proc("BareBench::VERSION")
Project.meta.readme           = 'README.rdoc'
Project.meta.summary          = extract_summary()
Project.meta.description      = extract_description()
Project.meta.website          = 'http://'
Project.meta.bugtracker       = 'http://'
Project.meta.feature_requests = 'http://'
Project.meta.use_git          = true

Project.manifest.ignore       = %w[
                                    Rakefile
                                    beat/**/*
                                    dev/**/*
                                    pkg/**/*
                                    rake/**/*
                                    web/**/*
                                    barebench.bbprojectd/**/*
                                ]

Project.rubyforge.project     = 'barebench'
Project.rubyforge.path        = 'barebench'

Project.rdoc.include         << 'doc/*.rdoc'
