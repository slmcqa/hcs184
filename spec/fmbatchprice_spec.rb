require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

describe "SLMC :: Additional Account Class 2  (Company & House Staff)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "fm"
    @user = "fm"

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


  it "Adds Batch Price" do
slmc.login(@user,@password).should be_true
slmc.open("/mainMenu.html");
if slmc.is_element_present("link=Service File Maintenance Landing Page")
  slmc.click("link=Service File Maintenance Landing Page",:wait_for =>:page);
else
  slmc.click("link=File Maintenance");
slmc.click("link=Services",:wait_for =>:page);
end
row_count = 22
x = 1
while  x != row_count
    row = x
    priceupdate  = PatientBillingAccountingHelper::Philhealth.get_read_fm_priceupdate_scenario(row)
    @mservice_code = ["060000750",	"010000001",	"040854342",	"269409014",	"082400222",	"010002580",	"060000209",	"010001745",	"060003489",	"089403123",	"060000354",	"030000001",	"089000039",	"089500009"]
    num = AdmissionHelper.range_rand(10,99).to_s
    @mservice_code = @mservice_code[num]
    inclusion = priceupdate[:inclusion]
    specific_item = priceupdate[:specific_item]
    #with_exclusion = priceupdate[:with_exclusion]
    slmc.click("link=PriceBatchUpdate",:wait_for =>:page);
    slmc.click("id=btnBatchUpdate");
    slmc.select("id=selPrcUpInc", "label=#{inclusion}");
    if specific_item == "NO"
        slmc.click("id=btnAddInc");
        slmc.type('id=inclusionrate0"', "200");

    else
        slmc.click("css=#orderTypeFind > img");
        slmc.type("id=txtParam", @mservice_code);
        slmc.click("id=btnFindSearch");
        slmc.click("id=tdMsvcCode-0");
        slmc.click("id=btnAddInc");
        slmc.type('id=inclusionrate0"' "200");
    end

		slmc.click("css=#orderTypeFind > img");
		slmc.type("id=txtParam", "010000000");
		slmc.click("id=btnFindSearch");
		slmc.click("id=tdMsvcCode-0");
		slmc.click("id=btnAddInc");
		slmc.type('id=inclusionrate0"', "100");
		slmc.click"//html/body/div[6]/div/div/select[2]" #year
		slmc.select "//html/body/div[6]/div/div/select[2]/option[5]" #2016
		slmc.select "//html/body/div[6]/div/div/select[2]/option" #2012
		slmc.select "//html/body/div[6]/div/div/select[2]/option[2]" #2013
		slmc.click"//html/body/div[6]/div/div/select" # month
		slmc.select "//html/body/div[6]/div/div/select/option" #Jan
		slmc.select "//html/body/div[6]/div/div/select/option[2]" #Feb
		slmc.click("link=19");
		slmc.type '//*[@id="txtPrcUpExcTime"]', "1201"
		slmc.click("id=btn_ok");
end
  end
end

