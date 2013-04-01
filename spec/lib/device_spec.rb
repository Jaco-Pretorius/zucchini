require 'spec_helper'

describe Zucchini::Device do
  subject { Zucchini::Device.new('iPhone 5','2b6f0cc904d137be2e1730235f5664094b831186','low_ios5') }

  its(:name) { should == 'iPhone 5' }
  its(:udid) { should == '2b6f0cc904d137be2e1730235f5664094b831186' }
  its(:screen) { should == 'low_ios5' }

  describe 'is_simulator?' do
    context "when the device name is 'iOS Simulator'" do
      subject { Zucchini::Device.new('iOS Simulator','udid','low_ios5') }
      its(:is_simulator?) { should be_true }
    end

    context "when the device name is a device" do
      subject { Zucchini::Device.new('iPhone 4S','udid','low_ios5') }
      its(:is_simulator?) { should be_false }
    end
  end
end
