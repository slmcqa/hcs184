require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'


describe "SLMC :: View and Reprinting - PBA Search Parameter" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @patient = Admission.generate_data
    @password = "123qweuser"
    @user = "gu_spec_user6"

    @drugs =  {"049000028" => 1}
    @ancillary = {"010001636" => 1}
    @operation = {"060000204" => 1}

    @user_actions = ["Reprint PhilHealth Form", "Reprint Prooflist", "Display Details"]

  end 

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Create and admit patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(@patient)
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287").should == "Patient admission details successfully saved."
  end
  it "Order items" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end
  it "Clinical Discharge Patient" do
    slmc.nursing_gu_search(:pin => @@pin)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true)
  end
  it "Compute PhilHealth" do
    slmc.login("sel_pba9", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    @@ph_ref_no = slmc.ph_save_computation
  end
  it "Input valid PIN" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :search_options => "PIN", :entry => @@pin)
    slmc.get_text("css=#philhealthTableBody>tr>td").should == @@ph_ref_no
    slmc.get_text("css=#philhealthTableBody>tr>td:nth-child(2)").should == (@patient[:last_name].upcase).to_s + ", " + (@patient[:first_name]).to_s + " " + (@patient[:middle_name])
    slmc.get_text("css=#philhealthTableBody>tr>td:nth-child(4)").should == @@visit_no
    slmc.get_text("css=#philhealthTableBody>tr>td:nth-child(5)").should == Date.today.strftime("%b-%d-%Y")
    slmc.get_text("css=#philhealthTableBody>tr>td:nth-child(6)").should == "ACCOUNTS RECEIVABLE"
    slmc.get_text("css=#philhealthTableBody>tr>td:nth-child(7)").should == "Estimate"
    slmc.get_select_options("userAction_#{@@ph_ref_no}").should == @user_actions
  end
  it "Input invalid PIN" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :search_options => "PIN", :entry => "A!@S").should be_false
    slmc.get_text("css=#philhealthTableBody>tr>td").should == "Nothing found to display."
    slmc.is_text_present("Patient Billing and Accounting Home › Document Search").should be_true
  end
  it "Input existing visit no. instead of PIN" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :search_options => "PIN", :entry => @@visit_no).should be_false
    slmc.get_text("css=#philhealthTableBody>tr>td").should == "Nothing found to display."
    slmc.is_text_present("Patient Billing and Accounting Home › Document Search").should be_true
  end
  it "Input valid date instead of PIN" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :search_options => "PIN", :entry => Date.today.strftime("%m/%d/%Y"))
    slmc.get_text("css=#philhealthTableBody>tr>td").should == "Nothing found to display."
    slmc.is_text_present("Patient Billing and Accounting Home › Document Search").should be_true
  end
  it "Input document no. instead of PIN" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :search_options => "PIN", :entry => @@ph_ref_no).should be_false
    slmc.get_text("css=#philhealthTableBody>tr>td").should == "Nothing found to display."
    slmc.is_text_present("Patient Billing and Accounting Home › Document Search").should be_true
  end
end