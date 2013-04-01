module Zucchini
  class Device
    attr_reader :name, :udid, :screen

    def initialize name, udid, screen
      @name = name
      @udid = udid
      @screen = screen
    end

    def is_simulator?
      @name == 'iOS Simulator'
    end
  end
end
