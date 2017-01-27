require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Discount - Adjustment and Cancellation Module" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @patient1 = Admission.generate_data
    @pba_patient2 = Admission.generate_data(:not_senior => true)
    @pba_patient3 = Admission.generate_data

    @user = "update_guarantor_spec_user2"
    @password = "123qweuser"
    @@doctor_dependent = "1301028135" #"1112100138"

    @drugs = {"040000357" => 1}
    @drugs_mrp = {"040950576" => 1}
    @ancillary_without_template = {"010001831" => 1}
    @ancillary = {"010001137" => 1}
    @supplies = {"080100021" => 1}

    @o1 = {"ORT01" => 1}
    @o2 = {"ORT02" => 1}
    @o3 = {"ORT03" => 1}
    @o7 = {"ORT07" => 1}

    @@discount_rate1 = 5000.0
    @@discount_rate2 = 50
    @@discount_rate3 = 10000.0
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end
  it "2989 - Reader's Fee: Enhancement of Ordering Modules - GU -  For Without ARMS Template - One Item - Check if Saved in TXN_OM_RF_VALIDATION" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin = slmc.create_new_patient(@patient1).gsub(' ', '')

    sleep 6
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0278", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    sleep 6
    puts "@@pin - #{@@pin}"
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @ancillary_without_template.each do |item, q|
      @mcode = item
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single").should == 1
    sleep 6
    slmc.confirm_validation_all_items.should be_true
    sleep 10
    @ancillary_without_template = @ancillary_without_template.to_s
    puts @ancillary_without_template
     Database.connect
        a =  "SELECT ORDER_DTL_NO FROM SLMC.TXN_OM_RF_VALIDATION WHERE PIN = '#{@@pin}' AND MSERVICE_CODE = '#{@mcode}'"
       # a =  "SELECT ORDER_DTL_NO FROM SLMC.TXN_OM_RF_VALIDATION WHERE PIN = '#{@@pin}' "#AND MSERVICE_CODE = '#{@ancillary_without_template}'"
        aa = Database.select_statement a
       # aa = aa.to_s
        puts aa
        aa.should_not ==  "" || "null"
     Database.logoff

  end
  it "2989 - Reader's Fee: Enhancement of Ordering Modules - GU -  For With ARMS Template - One Item - Check if Saved in TXN_OM_RF_VALIDATION" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @ancillary.each do |item, q|
      @mcodes = item
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single").should == 1
    sleep 6
    slmc.confirm_validation_all_items.should be_true
    sleep 6
     Database.connect
        c =  "SELECT ORDER_DTL_NO FROM TXN_OM_RF_VALIDATION WHERE PIN = '#{@@pin}' AND MSERVICE_CODE = '#{@mcodes}'"
        cc = Database.my_select_last_statement c
     #   cc = cc.to_s
        puts "aaB =  #{cc}"
        cc.should ==  nil
     Database.logoff
      slmc.login("dastech16", @password).should be_true
            slmc.go_to_arms_dastect_package
      slmc.dastech_search(:criteria => @@pin,
                          :more_options => true,
                          #:ci_no => @@ci_no4,
                          :item_code => "010001137")
      slmc.dastech_search_checking.should == true
      slmc.go_to_result_data_entry_page
      slmc.das_tech_landing_page("ARMS Result Data Entry").should == true
      slmc.dastech_result_data_entry(:exam_val => "MD PORTAL SELENIUM TEST",
                                      :history2 => "MD PORTAL SELENIUM TEST",
                                      :compare => "MD PORTAL SELENIUM TEST",
                                      :technique => "MD PORTAL SELENIUM TEST",
                                      :findres => "MD PORTAL SELENIUM TEST",
                                      :impress => "MD PORTAL SELENIUM TEST",
                                      :remarks => "MD PORTAL SELENIUM TEST",
                                      :sig1 => "7099",
                                      :sig2 => "7117",
                                      :save => true,
                                      :testno8 => "006600000000001")
      slmc.tag_as_official_package
      Database.connect
        c =  "SELECT ORDER_DTL_NO FROM TXN_OM_RF_VALIDATION WHERE PIN = '#{@@pin}' AND MSERVICE_CODE = '#{@mcodes}'"
        cc = Database.my_select_last_statement c
        #cc = cc.to_s
         puts "aaB =  #{cc}"
        cc.should_not ==  "" || "null"
     Database.logoff
  end
  it "2989 - Reader's Fee: Enhancement of Ordering Modules - GU -  For With ARMS Template - Multiple Items - Check if Saved in TXN_OM_RF_VALIDATION"do
        slmc.login(@user, @password).should be_true
  end
end

#
#
#
# 2989 Enhancement of Ordering Modules
# 2994 Enhancement of RF Validation module
# 2995 New ARMS table for Reader's Fee Enhancement


#2989 - Reader's Fee: Enhancement of Ordering Modules - GU -  For Without ARMS Template - One Item - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - GU -  For Without ARMS Template - Multiple Items - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - GU -  For With ARMS Template - One Item - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - GU -  For With ARMS Template - Multiple Items - Check if Saved in TXN_OM_RF_VALIDATION
#
#2989 - Reader's Fee: Enhancement of Ordering Modules - SU-  For Without ARMS Template - One Item - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - SU -  For Without ARMS Template - Multiple Items - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - SU -  For With ARMS Template - One Item - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - SU -  For With ARMS Template - Multiple Items - Check if Saved in TXN_OM_RF_VALIDATION
#
#
#2989 - Reader's Fee: Enhancement of Ordering Modules - DAS -  For Without ARMS Template - One Item - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - DAS -  For Without ARMS Template - Multiple Items - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - DAS -  For With ARMS Template - One Item - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - DAS -  For With ARMS Template - Multiple Items - Check if Saved in TXN_OM_RF_VALIDATION


#2989 - Reader's Fee: Enhancement of Ordering Modules - Wellness-  For Without ARMS Template - One` Item - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - Wellness-  For Without ARMS Template - Multiple Items - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - Wellness-  For With ARMS Template - One Item - Check if Saved in TXN_OM_RF_VALIDATION
#2989 - Reader's Fee: Enhancement of Ordering Modules - Wellness-  For With ARMS Template - Multiple Items - Check if Saved in TXN_OM_RF_VALIDATION
#
#
#
#
# 2989 Enhancement of Ordering Modules
#2994 Enhancement of RF Validation module
#2995 New ARMS table for Reader's Fee Enhancement