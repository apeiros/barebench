#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'barebench/bench'
require 'barebench/run'
require 'barebench/suite'
require 'barebench/version'
# See bottom for more requires



module BareBench
  class << self
    # A hash of formatters (require-string => module) to be used with Test::Run.
    attr_reader :format

    # For mock integration and others, append modules that should extend the Test::Run instance.
    attr_reader :extender

    # The toplevel suite. That's the one run_if_mainfile and define add suites
    # and assertions to.
    attr_reader :toplevel_suite

    # The full path to this file
    # Needed to test barebench itself using barebench
    attr_reader :required_file # :nodoc:
  end

  # Loads all files in a test directory in order to load the suites and
  # assertions. Used by the 'barebench' executable and the standard rake task.
  #
  # Options:
  # :verbose::    Will print information about the load process (default: false)
  # :setup_path:: The path to the setup file, the first loaded file (default: 'test/setup.rb')
  # :chdir::      The directory this routine chdirs before loading, will jump back to the original
  #               directory after loading (default: '.')
  def self.load_standard_test_files(opts={})
    verbose    = opts.delete(:verbose)
    setup_path = opts.delete(:setup_path) || 'test/setup.rb'
    chdir      = opts.delete(:chdir) || '.'
    Dir.chdir(chdir) do
      load(setup_path) if File.exist?(setup_path)
      Dir.glob('bench/bench/**/*.rb') { |path|
        helper_path = path.sub(%r{^bench/bench/}, 'bench/helper/\1/')
        puts(File.exist?(helper_path) ? "Loading helper file #{helper_path}" : "No helper file #{helper_path} to load") if verbose
        load(helper_path) if File.exist?(helper_path)
        puts "Loading test file #{path}" if verbose
        load(path)
      }
    end
  end

  # Initializes BareBench, is automatically called
  #
  # Needed for bootstrapped selftest
  def self.init # :nodoc:
    @format         = {}
    @extender       = []
    @toplevel_suite = BareBench::Suite.new
    @required_file  = ["", *$LOAD_PATH].map { |path|
      File.expand_path(File.join(path, __FILE__))
    }.find { |full| File.exist?(full) }
  end
  init

  # If no description was given, it adds the contained assertions and suites to the toplevel suite,
  # if a description was given, a suite with the given description is created, added to the toplevel
  # suite, and all the contained assertions and suites are added to the created suite.
  def self.suite(description=nil, opts={}, &block)
    if description then
      opts, description = description, nil if Hash === description
      @toplevel_suite.suite(description, opts, &block)
    elsif opts && !opts.empty?
      raise ArgumentError, "Suites with options must have names"
    else
      @toplevel_suite.instance_eval(&block)
    end
  end

  # Creates a Test::Run instance, adds the assertions and suites defined in its
  # own block to that Test::Run instance's toplevel suite and if $PROGRAM_NAME
  # (aka $0) is equal to \_\_FILE__ (means the current file is the file directly
  # executed by ruby, and not just required/loaded/evaled by another file),
  # subsequently also runs that suite.
  def self.run_if_mainfile(description=nil, opts={}, &block)
    suite(description, opts, &block)
    if caller.first[/^[^:]*/] == $0 then # if is mainfile
      run(:format => ENV['FORMAT'], :interactive => ENV['INTERACTIVE'])
    end
  end

  # Runs the toplevel suite (which usually contains all suites and assertions
  # defined in all loaded test files).
  #
  # Returns the Run instance.
  def self.run(opts=nil)
    runner = BareBench::Run.new(@toplevel_suite, opts)
    runner.run_all
    runner
  end
end
