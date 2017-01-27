#!/bin/env ruby
# encoding: utf-8

#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require 'spec_helper'
require 'yaml'

#USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Discount - View and Reprinting Module" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver
  
  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @pba_patient1 = Admission.generate_data
    @user = "billing_spec_user"
    @password = "123qweuser"

    @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
    @gu_user_0287 = "gycapalungan"
    @password = "123qweuser"
    @pba_user = "ldcastro" #"sel_pba7"
    @oss_user = "jtsalang"  #"sel_oss7"
    @or_user =  "slaquino"     #"or21"






    @drugs = ['PROSURE VANILLA 380G']
    @ancillary = ['ADRENOMEDULLARY IMAGING-M-IBG']
    @supplies = ['BABY POWDER 25G (J & J)']
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Create patient for Discount Transactions" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pba_pin = slmc.create_new_patient(@pba_patient1.merge!(:gender => "F"))
    #slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pba_pin)
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :room_charge => "REGULAR PRIVATE", :rch_code => "RCH08",
      :org_code => "0287", :diagnosis => "GASTRITIS", :package => "PLAN A FEMALE").should == "Patient admission details successfully saved."
  end
  it "Patient Order items" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pba_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin)
    @drugs.each do |drug|
      slmc.search_order(:description => drug, :drugs => true)
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc|
      slmc.search_order(:description => anc, :ancillary => true)
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
    end
    @supplies.each do |supply|
      slmc.search_order(:description => supply, :supplies => true)
      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end
  it "Validates package through GU's Package Management page" do
   slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pba_pin)
    slmc.go_to_gu_page_for_a_given_pin("Package Management", @@pba_pin)
    slmc.click Locators::Wellness.order_package, :wait_for => :page
    slmc.validate_package.should be_true
    slmc.validate_credentials(:username => "sel_0287_validator", :password => @password, :package => true).should be_true
  end
  it "Clinically discharges the patient" do
   slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@pba_pin, :no_pending_order => true, :with_complementary => true, :pf_type => "COLLECT", :pf_amount => "1000", :save => true).should be_true
  end
  it "Add Discount for Patient" do

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Discount", @@visit_no)
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "DRUGS / MEDICINE", :discount_type => "Fixed", :discount_rate => "500").should be_true
    slmc.click("css=#gen_table_body>tr:nth-child(1)>td:nth-child(12)>input")
    slmc.exclude_item(:all => true, :save => true).should be_true
  end
  it "Search Discount using Visit Number" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:entry => @@visit_no, :select => "Discount", :search_options => "VISIT NUMBER").should be_true
  end
  it "Search Discount using Document Number" do
    @@doc_no = slmc.get_text("css=#processedDiscountsBody>tr>td")
    @@amount = (slmc.get_text("css=#processedDiscountsBody>tr>td:nth-child(6)").gsub(',', '')) # used to compare upon searching if it will match
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:entry => @@doc_no, :select => "Discount", :search_options => "DOCUMENT NUMBER").should be_true
    (slmc.get_text("css=#processedDiscountsBody>tr>td:nth-child(6)").gsub(',', '')).should == ("%0.2f" %(@@amount))
  end
  it "Search Discount using Document Date" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "Discount", :search_options => "DOCUMENT DATE").should be_true
  end
  it "Adjust Discount" do
    slmc.pba_adjustment_and_cancellation(:doc_type => "DISCOUNT", :search_option => "VISIT NUMBER", :entry => @@visit_no).should be_true
    slmc.click("link=End", :wait_for => :text, :text => "COURTESY DISCOUNT") if slmc.is_element_present("link=End")
    @@discount_number1 = (slmc.get_discount_number_using_visit_number(:visit_no => @@visit_no, :discount_rate => "500")).gsub(' ', '')
    slmc.click_display_details(:visit_no => @@visit_no, :discount_no => @@discount_number1, :inpatient => true)
    slmc.get_value("discountNumber").should == @@discount_number1
    slmc.adjust_discount(:amount => "1000", :discount_number => @@discount_number1).should == 1
  end
  it "Adds Another Discount for patient" do
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Discount", @@visit_no)
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "DRUGS / MEDICINE", :discount_type => "Fixed", :discount_rate => "600").should be_true
    slmc.click("css=#gen_table_body>tr:nth-child(1)>td:nth-child(12)>input")
    slmc.exclude_item(:all => true, :save => true).should be_true
  end
  it "Patient will appear on the Search Result List under 'Adjusted Discount' tab" do
    slmc.pba_adjustment_and_cancellation(:doc_type => "DISCOUNT", :search_option => "VISIT NUMBER", :entry => @@visit_no).should be_true
  end
  it "Cancels First Discount and give another Discount" do
    slmc.click("link=End", :wait_for => :text, :text => "COURTESY DISCOUNT") if slmc.is_element_present("link=End")
    @@discount_number2 = (slmc.get_discount_number_using_visit_number(:visit_no => @@visit_no, :discount_rate => "600")).gsub(' ', '')
    slmc.click Locators::PBA.adjusted_discounts
    slmc.click_display_details(:visit_no => @@visit_no, :discount_no => @@discount_number1, :inpatient => true) #discount 1 is to be cancelled, discount 2 remains as processed discount
    slmc.cancel_discount.should be_true
  end
  it "Discount number 1 should appear on Cancelled Discount and Discount number 2 in Processed Discount" do
    slmc.pba_adjustment_and_cancellation(:doc_type => "DISCOUNT", :search_option => "DOCUMENT NUMBER", :entry => @@discount_number1).should be_false
    slmc.click Locators::PBA.cancelled_discounts
    slmc.get_text("cancelledDiscountsBody").include?(@@discount_number1).should be_true
    slmc.pba_adjustment_and_cancellation(:doc_type => "DISCOUNT", :search_option => "DOCUMENT NUMBER", :entry => @@discount_number2).should be_true
    slmc.get_text("processedDiscountsBody").include?(@@discount_number2).should be_true
  end
  it "Order items to be Discounted" do
    slmc.login("sel_pharmacy1", @password).should be_true
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "HMO", :guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "percent", :coverage_amount => "50.00", :guarantor_add => true)
    slmc.oss_order(:item_code => "040004334", :doctor => "6726", :order_add => true).should be_true
    slmc.oss_order(:item_code => "044006788", :doctor => "6726", :order_add => true).should be_true
    slmc.oss_order(:item_code => "042008692", :doctor => "6726", :order_add => true).should be_true
    slmc.oss_order(:item_code => "040000357", :doctor => "6726", :order_add => true).should be_true
    slmc.oss_add_discount(:scope => "service", :type => "percent", :amount => "10", :discount_all => true).should be_true
    sleep 5
    @@amount = slmc.get_text("totalAmountDueDisplay").gsub(',','').to_s
    slmc.oss_add_payment(:amount => @@amount, :type => "CASH")
    slmc.oss_submit_order("view")
  end
  it "Cancel one of the purchased drug" do
    @@pos_number = slmc.get_document_number
    @@ci_no = (slmc.get_ci_number_using_pos_number(@@pos_number)).gsub(' ', '') #Database access
    slmc.go_to_pos_order_cancellation
#    slmc.pos_document_search(:type => "CI NUMBER", :doc_no => @@ci_no, :start_date => "", :end_date => "").should be_true
    slmc.pos_document_search(:type => "ORDER NO.", :doc_no => @@ci_no, :start_date => "", :end_date => "").should be_true

    slmc.click_view_details
    slmc.get_css_count("css=#results>tbody>tr").should == 4
    slmc.pos_cancel_item(:reason => "CANCELLATION - PATIENT REFUSAL", :order_of_item => 1).should == "The CM was successfully updated with printTag = 'Y'."
    slmc.go_to_pos_order_cancellation
#    slmc.pos_document_search(:type => "CI NUMBER", :doc_no => @@ci_no, :start_date => "", :end_date => "").should be_true
    slmc.pos_document_search(:type => "ORDER NO.", :doc_no => @@ci_no, :start_date => "", :end_date => "").should be_true

    slmc.click_view_details
    slmc.get_css_count("css=#results>tbody>tr").should == 3
  end
  it "Reprint Prooflist for the cancelled item" do
   slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:entry => @@pos_number, :select => "Discount", :search_options => "VISIT NUMBER").should be_true
    slmc.get_css_count("css=#processedDiscountsBody>tr").should == 4
    slmc.click Locators::PBA.cancelled_discounts
    sleep 3
    slmc.get_css_count("css=#cancelledDiscountsBody>tr").should == 2
    slmc.click("css=#cancelledDiscountsBody>tr>td:nth-child(7)>div>a", :wait_for => :page)
    slmc.is_text_present("Patient Billing and Accounting Home › Document Search").should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:entry => @@pos_number, :select => "Discount", :search_options => "VISIT NUMBER").should be_true
    slmc.click Locators::PBA.cancelled_discounts
    slmc.click("css=#cancelledDiscountsBody>tr>td:nth-child(7)>div:nth-child(2)>a", :wait_for => :page)
    slmc.is_text_present("Discount Information").should be_true
    slmc.is_element_present("patientBanner").should be_true
    slmc.is_visible("patientBanner").should be_true
  end

end