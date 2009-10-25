#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareBench

  # A Suite is a container for multiple benches.
  # You can give a suite a description, also a suite can contain
  # setup and teardown blocks that are executed before (setup) and after
  # (teardown) every assertion.
  #
  # Suites can also be nested. Nested suites will inherit setup and teardown.
  class Suite

    # Nested suites, in the order of definition
    attr_reader :suites

    # All benches in this suite
    attr_reader :benches

    # All skipped benches in this suite
    attr_reader :skipped

    # This suites description. Toplevel suites usually don't have a description.
    attr_reader :description

    # This suites direct parent. Nil if toplevel suite.
    attr_reader :parent

    # An Array containing the suite itself (first element), then its direct
    # parent suite, then that suite's parent and so on
    attr_reader :ancestors

    # Create a new suite.
    #
    # The arguments 'description', 'parent' and '&block' are the same as on Suite::new,
    # 'opts' is an additional options hash.
    #
    # Keys the options hash accepts:
    # :requires:: A string or array of strings with requires that have to be done in order to run
    #             this suite. If a require fails, the suite is created as a Skipped::Suite instead.
    #
    def self.create(description=nil, parent=nil, opts={}, &block)
      if requires = opts.delete(:requires) then
        Array(requires).each { |file| require file }
      end
    rescue LoadError
      # A suite is skipped if requirements are not met
      Skipped::Suite.new(description, parent, &block)
    else
      # All suites within Skipped::Suite are Skipped::Suite
      (block ? self : Skipped::Suite).new(description, parent, opts, &block)
    end

    # Create a new suite.
    #
    # Arguments:
    # description:: A string with a human readable description of this suite, preferably
    #               less than 60 characters and without newlines
    # parent::      The suite that nests this suite. Ancestry plays a role in execution of setup
    #               and teardown blocks (all ancestors setups and teardowns are executed too).
    # &block::      The given block is instance evaled.
    def initialize(description=nil, parent=nil, opts={}, &block)
      @description = description
      @parent      = parent
      @suites      = [] # [["description", subsuite, skipped], ["description2", ...], ...] - see Array#assoc
      @benches     = []
      @skipped     = []
      @setup       = []
      @teardown    = []
      @iterations  = opts[:iterations] && opts[:iterations].to_i
      @ancestors   = [self] + (@parent ? @parent.ancestors : [])
      instance_eval(&block) if block
    end

    # Define a nested suite.
    #
    # Nested suites inherit setup & teardown methods.
    # Also if an outer suite is skipped, all inner suites are skipped too.
    #
    # Valid values for opts:
    # :requires:: A list of files to require, if one of the requires fails,
    #               the suite will be skipped. Accepts a String or an Array
    def suite(description=nil, opts={}, &block)
      opts, description = description, nil if Hash === description
      suite = self.class.create(description, self, opts, &block)
      if append_to = @suites.assoc(description) then
        append_to.last.update(suite)
      else
        @suites << [description, suite]
      end
      suite
    end

    def iterations
      @iterations || (@parent && @parent.iterations) || 1
    end

    # Performs a recursive merge with the given suite.
    #
    # Used to merge suites with the same description.
    def update(with_suite)
      if ::BareBench::Skipped::Suite === with_suite then
        @skipped.concat(with_suite.skipped)
      else
        @benches.concat(with_suite.benches)
        @setup.concat(with_suite.setup)
        @teardown.concat(with_suite.teardown)
        with_suite.suites.each { |description, suite|
          if append_to = @suites.assoc(description) then
            append_to.last.update(suite)
          else
            @suites << [description, suite]
          end
        }
      end
      self
    end

    # All setups in the order of their nesting (outermost first, innermost last)
    def ancestry_setup
      ancestors.map { |suite| suite.setup }.flatten.reverse
    end

    # All teardowns in the order of their nesting (innermost first, outermost last)
    def ancestry_teardown
      ancestors.map { |suite| suite.teardown }.flatten
    end

    # Define a setup block for this suite. The block will be ran before every
    # assertion once, even for nested suites.
    def setup(&block)
      block ? @setup << block : @setup
    end

    # Define a teardown block for this suite. The block will be ran after every
    # assertion once, even for nested suites.
    def teardown(&block)
      block ? @teardown << block : @teardown
    end

    # Define an assertion. The block is supposed to return a trueish value
    # (anything but nil or false).
    #
    # See Assertion for more info.
    def bench(description=nil, &block)
      bench = Bench.new(self, description, &block)
      if match = caller.first.match(/^(.*):(\d+)(?::.+)?$/) then
        file, line = match.captures
        file = File.expand_path(file)
        if File.exist?(file) then
          bench.file = file
          bench.line = line.to_i
        end
      end
      @benches << bench
    end

    def to_s #:nodoc:
      sprintf "%s %s", self.class, @description
    end

    def inspect #:nodoc:
      sprintf "#<%s:%08x %p>", self.class, object_id>>1, @description
    end
  end
end



require 'barebench/skipped/suite' # TODO: determine why this require is on the bottom and document it.
