#!/usr/bin/env ruby
# encoding: utf-8


require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
#require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'spec_helper'
require 'yaml'
require 'magic_encoding'
USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Online_cm_request_162" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @patient1 = Admission.generate_data
    @patient2 = Admission.generate_data
    @or_patient = Admission.generate_data
    @dr_patient = Admission.generate_data
    @er_patient = Admission.generate_data
    @wellness_patient1 = Admission.generate_data
    @wellness_patient2 = Admission.generate_data



    #"5c456b0314b9013d321e5f917a3a4aa3d6235dab"

    @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
    #@pba_user = "ldcastro" #"sel_pba7"
    @pba_user = "pba1" #"sel_pba7"
    @or_user =  "slaquino"     #"or21"
    @oss_user = "jtsalang"  #"sel_oss7"
    @dr_user = "jpnabong" #"sel_dr4"
    @er_user =  "jtabesamis"   #"sel_er4"
    @wellness_user = "ragarcia-wellness" # "sel_wellness2"
    @gu_user_0287 = "gycapalungan"

    @room_rate = 4167.0

    @sel_dr_validator = "msgepte"

    @drugs = {"040000357" => 1} #{"040860043" => 1}
    @drugs_mrp = {"040950576" => 1}
    @ancillary = {"010000003" => 1}
    @supplies = {"080100021" => 1}
    @operation = {"060000058" => 1}


  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Request for CM in Nursing (GU) - Clear - Save - Single Items" do
        slmc.login(@user, @password).should be_true
        slmc.admission_search(:pin => "1")
        @@individual = slmc.create_new_patient(@patient1)
        slmc.admission_search(:pin => @@individual)
        slmc.create_new_admission(:room_charge => "DELUXE PRIVATE", :rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
        puts @@individual

        slmc.login(@gu_user_0287, @password).should be_true
        slmc.nursing_gu_search(:pin => @@individual)
        slmc.go_to_gu_page_for_a_given_pin("Order Page", @@individual)
        @drugs.each do |drug, q|
                slmc.search_order(:description => drug, :drugs => true).should be_true
                slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
        end
        @drugs_mrp.each do |drug, q|
                slmc.search_order(:description => drug, :drugs => true).should be_true
                slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
        end
        @ancillary.each do |anc, q|
                slmc.search_order(:description => anc, :ancillary => true ).should be_true
                slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
        end
        @supplies.each do |supply, q|
                slmc.search_order(:description => supply, :supplies => true ).should be_true
                slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
        end
        sleep 5
        slmc.verify_ordered_items_count(:drugs => 2).should be_true
        slmc.verify_ordered_items_count(:supplies => 1).should be_true
        slmc.verify_ordered_items_count(:ancillary => 1).should be_true
        slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
        sleep 5
        slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
        slmc.confirm_validation_all_items.should be_true
#        submit_button = slmc.is_element_present("//input[@type='button' and @value='Submit']") ?  "//input[@type='button' and @value='Submit']" :  "//input[@value='SUBMIT']"
#        slmc.click(submit_button, :wait_for => :page)

        slmc.login(@gu_user_0287, @password).should be_true
        slmc.nursing_gu_search(:pin => @@individual)
        slmc.go_to_gu_page_for_a_given_pin("CM Request", @@individual)

        @drugs.each do |drug, q|
               slmc.cm_request(:drugs => true, :code => drug, :clear =>true, :cmrn => true).should be_true

                slmc.cm_request(:drugs => true, :code => drug, :save =>true, :cmrn => true).should be_true
        end
        @drugs_mrp.each do |drug_mrp, q|
                slmc.cm_request(:drugs => true, :code => drug_mrp, :clear =>true, :cmrn => true).should be_true
                slmc.cm_request(:drugs => true, :code => drug_mrp, :save =>true, :cmrn => true).should be_true
        end
        @ancillary.each do |anc, q|
                slmc.cm_request(:ancillary => true, :code => anc, :clear =>true, :cmrn => true).should be_true
                slmc.cm_request(:ancillary => true, :code => anc, :save =>true, :cmrn => true).should be_true
        end
        @supplies.each do |supply, q|
                slmc.cm_request(:supplies => true, :code => supply, :clear =>true, :cmrn => true).should be_true
                slmc.cm_request(:supplies => true, :code => supply, :save =>true, :cmrn => true).should be_true
        end

        ##Item for CMRN or Turn-in should be displayed under ACTIVE Status of CM Request table
        #check in the CM Request Table

        @drugs.each do |drug, q|
                slmc.cm_request_list(:verify => drug, :drugs => true, :active => true).should be_true
        end
        @drugs_mrp.each do |drug_mrp, q|
                slmc.cm_request_list(:verify => drug_mrp, :drugs => true, :active => true).should be_true
        end
        @ancillary.each do |anc, q|
                slmc.cm_request_list(:verify => anc, :ancillary => true, :active => true).should be_true
        end
        @supplies.each do |supply, q|
                slmc.cm_request_list(:verify => supply, :supplies => true, :active => true).should be_true
        end

  end
  it "Request for CM in Nursing (GU) - Clear - Confirm - Single Items" do
        slmc.login(@user, @password).should be_true
        slmc.admission_search(:pin => "1")
        @@individual = slmc.create_new_patient(@patient2)
        slmc.admission_search(:pin => @@individual)
        slmc.create_new_admission(:room_charge => "DELUXE PRIVATE", :rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
        puts @@individual

        slmc.login(@gu_user_0287, @password).should be_true
        slmc.nursing_gu_search(:pin => @@individual)
        slmc.go_to_gu_page_for_a_given_pin("Order Page", @@individual)
        @drugs.each do |drug, q|
                slmc.search_order(:description => drug, :drugs => true).should be_true
                slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
        end
        @drugs_mrp.each do |drug, q|
                slmc.search_order(:description => drug, :drugs => true).should be_true
                slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
        end
        @ancillary.each do |anc, q|
                slmc.search_order(:description => anc, :ancillary => true ).should be_true
                slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
        end
        @supplies.each do |supply, q|
                slmc.search_order(:description => supply, :supplies => true ).should be_true
                slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
        end
        sleep 5
        slmc.verify_ordered_items_count(:drugs => 2).should be_true
        slmc.verify_ordered_items_count(:supplies => 1).should be_true
        slmc.verify_ordered_items_count(:ancillary => 1).should be_true
        slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
        sleep 5
        slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
        slmc.confirm_validation_all_items.should be_true
#        submit_button = slmc.is_element_present("//input[@type='button' and @value='Submit']") ?  "//input[@type='button' and @value='Submit']" :  "//input[@value='SUBMIT']"
#        slmc.click(submit_button, :wait_for => :page)

        slmc.login(@gu_user_0287, @password).should be_true
        slmc.nursing_gu_search(:pin => @@individual)
        slmc.go_to_gu_page_for_a_given_pin("CM Request", @@individual)
        sleep 6
        ########################## Validate Save, Clear and Confirm Botton should be disable  #############
     ss =   slmc.get_attribute("name=Save@disabled")
     puts ss
     ss1 =   slmc.get_attribute("name=Confirm@disabled")
        ss2 = slmc.get_attribute("name=Clear@disabled")
     puts ss1
          puts ss2
        @drugs.each do |drug, q|
               slmc.cm_request(:drugs => true, :code => drug, :clear =>true, :cmrn => true).should be_true
                slmc.cm_request(:drugs => true, :code => drug, :confirm =>true, :cmrn => true,:username => "sel_0287_validator").should be_true
        end
        @drugs_mrp.each do |drug_mrp, q|
                slmc.cm_request(:drugs => true, :code => drug_mrp, :clear =>true, :cmrn => true).should be_true
                slmc.cm_request(:drugs => true, :code => drug_mrp, :confirm =>true, :cmrn => true,:username => "sel_0287_validator").should be_true
        end
        @ancillary.each do |anc, q|
                slmc.cm_request(:ancillary => true, :code => anc, :clear =>true, :cmrn => true).should be_true
                slmc.cm_request(:ancillary => true, :code => anc, :confirm =>true, :cmrn => true,:username => "sel_0287_validator").should be_true
        end
        @supplies.each do |supply, q|
                slmc.cm_request(:supplies => true, :code => supply, :clear =>true, :cmrn => true).should be_true
                slmc.cm_request(:supplies => true, :code => supply, :confirm =>true, :cmrn => true,:username => "sel_0287_validator").should be_true
        end

        ##Item for CMRN or Turn-in should be displayed under ACTIVE Status of CM Request table
        #check in the CM Request Table

        slmc.cm_request_list(:verify => "Please select order", :drugs => true, :sent => true, :send => true).should be_true
        slmc.cm_request_list(:verify => "Please select order", :ancillary => true, :sent => true, :send => true).should be_true
        slmc.cm_request_list(:verify => "Please select order", :supplies => true, :sent => true, :send => true).should be_true

        slmc.cm_request_list(:verify => "Please select order", :drugs => true, :sent => true, :edit => true).should be_true
        slmc.cm_request_list(:verify => "Please select order", :ancillary => true, :sent => true, :edit => true).should be_true
        slmc.cm_request_list(:verify => "Please select order", :supplies => true, :sent => true, :edit => true).should be_true

        slmc.cm_request_list(:verify => "Please select order", :drugs => true, :sent => true, :delete => true).should be_true
        slmc.cm_request_list(:verify => "Please select order", :ancillary => true, :sent => true, :delete => true).should be_true
        slmc.cm_request_list(:verify => "Please select order", :supplies => true, :sent => true, :delete => true).should be_true

        @drugs.each do |drug, q|
                slmc.cm_request_list(:verify => drug, :drugs => true, :sent => true).should be_true
        end
        @drugs_mrp.each do |drug_mrp, q|
                slmc.cm_request_list(:verify => drug_mrp, :drugs => true, :sent => true).should be_true
        end
        @ancillary.each do |anc, q|
                slmc.cm_request_list(:verify => anc, :ancillary => true, :sent => true).should be_true
        end
        @supplies.each do |supply, q|
                slmc.cm_request_list(:verify => supply, :supplies => true, :sent => true).should be_true
        end

  end
  it "4728 - Philhealth: DAS OSS/Special Ancillary Unit - Incorrect Philhealth Claim being computed for the additional surgical case" do
  end
  it "2376 Package File Maintenance" do
###2.2 10 Items per page in pagination page.
   # @password = "fm"
#        package_code = "10000"
#        package_description = "PLAN A1 MALE"
#        package_code_not_exist = "7777"
        slmc.login("abhernandez", @password).should be_true
        sleep 2
        slmc.click("link=File Maintenance");
        sleep 2
        slmc.click "link=Package", :wait_for => :page
        sleep 5
        count = slmc.get_xpath_count("//html/body/div[1]/div[2]/div[2]/div[2]/form[2]/table//tr")
         puts count

  end
  it "5504 Online CM: Order Adjustment and Cancellation Request for Nursing" do
        slmc.login(@user, @password).should be_true
        slmc.admission_search(:pin => "1")
        @@individual = slmc.create_new_patient(@patient1)
        slmc.admission_search(:pin => @@individual)
        slmc.create_new_admission(:room_charge => "DELUXE PRIVATE", :rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
        puts @@individual

        slmc.login(@gu_user_0287, @password).should be_true
        slmc.nursing_gu_search(:pin => @@individual)
        slmc.go_to_gu_page_for_a_given_pin("Order Page", @@individual)
        @drugs.each do |drug, q|
                slmc.search_order(:description => drug, :drugs => true).should be_true
                slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
        end
        @drugs_mrp.each do |drug, q|
                slmc.search_order(:description => drug, :drugs => true).should be_true
                slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
        end
        @ancillary.each do |anc, q|
                slmc.search_order(:description => anc, :ancillary => true ).should be_true
                slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
        end
        @supplies.each do |supply, q|
                slmc.search_order(:description => supply, :supplies => true ).should be_true
                slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
        end
        sleep 5
        slmc.verify_ordered_items_count(:drugs => 2).should be_true
        slmc.verify_ordered_items_count(:supplies => 1).should be_true
        slmc.verify_ordered_items_count(:ancillary => 1).should be_true
        slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
        sleep 5
        slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
        slmc.confirm_validation_all_items.should be_true
#        submit_button = slmc.is_element_present("//input[@type='button' and @value='Submit']") ?  "//input[@type='button' and @value='Submit']" :  "//input[@value='SUBMIT']"
#        slmc.click(submit_button, :wait_for => :page)

        slmc.login(@gu_user_0287, @password).should be_true
        slmc.nursing_gu_search(:pin => @@individual)
        slmc.go_to_gu_page_for_a_given_pin("CM Request", @@individual)

        @drugs.each do |drug, q|
               slmc.cm_request(:drugs => true, :code => drug, :clear =>true, :cmrn => true).should be_true

                slmc.cm_request(:drugs => true, :code => drug, :save =>true, :cmrn => true).should be_true
        end
        @drugs_mrp.each do |drug_mrp, q|
                slmc.cm_request(:drugs => true, :code => drug_mrp, :clear =>true, :cmrn => true).should be_true
                slmc.cm_request(:drugs => true, :code => drug_mrp, :save =>true, :cmrn => true).should be_true
        end
        @ancillary.each do |anc, q|
                slmc.cm_request(:ancillary => true, :code => anc, :clear =>true, :cmrn => true).should be_true
                slmc.cm_request(:ancillary => true, :code => anc, :save =>true, :cmrn => true).should be_true
        end
        @supplies.each do |supply, q|
                slmc.cm_request(:supplies => true, :code => supply, :clear =>true, :cmrn => true).should be_true
                slmc.cm_request(:supplies => true, :code => supply, :save =>true, :cmrn => true).should be_true
        end

        ##Item for CMRN or Turn-in should be displayed under ACTIVE Status of CM Request table
        #check in the CM Request Table

        @drugs.each do |drug, q|
                slmc.cm_request_list(:verify => drug, :drugs => true, :active => true).should be_true
        end
        @drugs_mrp.each do |drug_mrp, q|
                slmc.cm_request_list(:verify => drug_mrp, :drugs => true, :active => true).should be_true
        end
        @ancillary.each do |anc, q|
                slmc.cm_request_list(:verify => anc, :ancillary => true, :active => true).should be_true
        end
        @supplies.each do |supply, q|
                slmc.cm_request_list(:verify => supply, :supplies => true, :active => true).should be_true
        end

  end
  it "5505 Online CM: Performing Units  Pending CM/Turn-In Request" do
################# DAS################# ################# ################# ################# ################# ################# ################# 
        slmc.login(@oss_user, @password).should be_true
        slmc.go_to_order_adjustment_and_cancellation
        slmc.click "link=CM/Turn-In Request for Approval", :wait_for => :page
#        slmc.search_pending_cm_request(:name => "Duncan").should be_true
#        slmc.search_pending_cm_request(:order_no => "0058201507000155").should be_true
#        slmc.search_pending_cm_request(:start_date => "07/27/2015" ,:end_date => "07/27/2015").should be_true
      #  slmc.search_pending_cm_request(:end_date => "Perpiñan").should be_true
        slmc.search_pending_cm_request(:name => @@individual).should be_true
        slmc.outpatient_cm_request(:status =>"Approved", :adjustment_type=>"cancel")
        slmc.search_pending_cm_request(:name => "Selenium").should be_true
        slmc.outpatient_cm_request(:status =>"Approved", :adjustment_type=>"cancel")

  end

end

