#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareBench

  class Bench
    attr_reader :time

    # The description of this assertion.
    attr_reader :description

    # The description of this assertion.
    attr_reader :status

    # The suite this assertion belongs to
    attr_reader :suite

    # The block specifying the assertion
    attr_reader :block

    # The file this assertion is specified in. Not contructed by Assertion itself.
    attr_accessor :file

    # The line this assertion is specified on. Not contructed by Assertion itself.
    attr_accessor :line

    # The lines this assertion spans. Not contructed by Assertion itself.
    attr_accessor :lines

    # suite::       The suite the Assertion belongs to
    # description:: A descriptive string about what this Assertion tests.
    # &block::      The block definition. Without one, the Assertion will have a
    #               :pending status.
    def initialize(suite, description, &block)
      @suite          = suite
      @status         = nil
      @time           = 0
      @description    = description || "No description given"
      @block          = block
    end

    # Run all setups in the order of their nesting (outermost first, innermost last)
    def setup
      @suite.ancestry_setup.each { |setup| instance_eval(&setup) } if @suite
      true
    rescue *PassthroughExceptions
      raise # pass through exceptions must be passed through
    rescue Exception => exception
      @failure_reason = "An error occurred during setup"
      @exception      = exception
      @status         = :error
      false
    end

    # Run all teardowns in the order of their nesting (innermost first, outermost last)
    def teardown
      @suite.ancestry_teardown.each { |setup| instance_eval(&setup) } if @suite
    rescue *PassthroughExceptions
      raise # pass through exceptions must be passed through
    rescue Exception => exception
      @failure_reason = "An error occurred during setup"
      @exception      = exception
      @status         = :error
    end

    # Runs the assertion and sets the status and exception
    def execute
      @exception = nil
      if @block then
        if setup then
          # run the benchmark
          start = Time.now
          @suite.iterations.times { instance_eval(&@block) }
          @time = Time.now-start
        end
        teardown
      else
        @status = :pending
      end
      self
    end

    def to_s # :nodoc:
      sprintf "%s %s", self.class, @description
    end

    def inspect # :nodoc:
      sprintf "#<%s:%08x @suite=%p %p>", self.class, object_id>>1, @suite, @description
    end
  end
end
