#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareBench

  # The version of the barebench library
  module VERSION

    # The major version number
    MAJOR = 0

    # The minor version number
    MINOR = 0

    # The tiny version number
    TINY  = 1

    # The version as a string
    def self.to_s
      "#{MAJOR}.#{MINOR||0}.#{TINY||0}"
    end
  end
end
