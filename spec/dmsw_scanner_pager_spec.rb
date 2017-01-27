require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Discount - View and Reprinting Module" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @pba_patient1 = Admission.generate_data
    @scanneruser = "billing_spec_user"
    @doctoruser = ""
    @auditoruser = ""
    @nurseuser = ""
    @password = "123qweuser"

    @drugs = ['PROSURE VANILLA 380G']
    @ancillary = ['ADRENOMEDULLARY IMAGING-M-IBG']
    @supplies = ['BABY POWDER 25G (J & J)']
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it " " do
    # TODO
  end
end

