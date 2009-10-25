#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareBench
  class Run

    # CLI runner is invoked with `-f cli` or `--format cli`.
    # It is intended for use with an interactive shell, to provide a comfortable, human
    # readable output.
    # It prints colored output (requires ANSI colors compatible terminal).
    #
    module CLI # :nodoc:
      def run_all(*args)
        @depth = 0
        puts "Running all benches#{' verbosly' if $VERBOSE}"
        start = Time.now
        super # run all suites
        printf "\n%2$d benches run in %1$.1fs\n",
          Time.now-start, *@count.values_at(:bench)
      end

      def run_suite(suite)
        return super unless suite.description
        skipped = suite.skipped.size
        case size = suite.benches.size
          when 0
            if skipped.zero? then
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m"
            else
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (#{skipped} skipped)"
            end
          when 1
            if skipped.zero? then
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (1 bench)"
            else
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (1 bench/#{skipped} skipped)"
            end
          else
            if skipped.zero? then
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (#{size} benches)"
            else
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (#{size} benches/#{skipped} skipped)"
            end
        end
        @depth += 1
        super(suite) # run the suite
        @depth -= 1
      end

      def run_bench(assertion)
        rv               = super # run the assertion
        indent           = '           '+'  '*@depth
        message          = []
        deeper           = []

        printf("%s%s %.2f\n", '  '*@depth, rv.description, rv.time)

        rv
      end
    end
  end

  @format["barebench/run/cli"] = Run::CLI # register the extender
end
