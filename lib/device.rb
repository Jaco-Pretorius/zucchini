module Zucchini
  class Device
    attr_reader :name, :udid, :screen

    def initialize name, udid, screen
      @name = name
      @udid = udid
      @screen = screen
    end
  end
end
