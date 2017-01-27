#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require 'spec_helper'



describe "SLMC ::Production Issue" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @user = "billing_spec_user2"
    @pba_user = "ldcastro"
    @password = "123qweuser"
    @dr_user = "jpnabong"

    @dr_patient = Admission.generate_data
    @er_patient = Admission.generate_data
    @er_patient2 = Admission.generate_data
    @ph_patient = Admission.generate_data
    @or_patient = Admission.generate_data

    @drugs2 = {"042090007" => 1}    
    @ancillary2 = {"010000317" => 1}  
    @supplies2 = {"085100003" => 1}
  end


  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end
#
#  it "Bug #2595 - ER: Missing notification image" do
##    slmc.login("sel_er3", @password).should be_true
#
#  end
#  it "Bug #2602 - GU:Cannot Discharge Patient" do
#
#  end
#  it "Bug #2608 - DAS OSS:Missing Details in Outpatient Information Sheet" do
#
#  end
#  it "Bug #2614 - All Units: The label in Request Slip and Request Prooflist should be changed from  Released By  to Received By" do
#
#  end
#  it "Bug #2616 - Reader's Fee Report:Wrong display of C.I. #" do
#
#  end
  it "Bug #2643 - SU:Cannot Discharge Newborn Clinically" do
     slmc.login(@dr_user, @password).should be_true
     @@slmc_mother_pin = (slmc.or_create_patient_record(@dr_patient.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0170'))).gsub(' ', '')
     #slmc.login("sel_dr4", @password).should be_true
     slmc.register_new_born_patient(:pin => @@slmc_mother_pin, :bdate => (Date.today).strftime("%m/%d/%Y"), :gender => "F",
               :birth_type => "SINGLE", :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,
                :doctor_name => "ABAD", :org_code => "0301",:newborn_inpatient_admission => true, :rch_code =>"RCH11", :save => true)
     puts @@slmc_mother_pin
     @@slmc_mother_pin = @@slmc_mother_pin.to_i
     @@slmc_mother_pin = @@slmc_mother_pin + 1
     @@slmc_baby_pin = @@slmc_mother_pin.to_s

    slmc.login("nursery", @password).should be_true
    slmc.nursing_gu_search(:pin => @@slmc_baby_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@slmc_baby_pin)
    @drugs2.each do |item, q|
          slmc.search_order(:description => item, :drugs => true).should be_true
          slmc.add_returned_order(:drugs => true, :description => item,
            :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary2.each do |item, q|
          slmc.search_order(:description => item, :ancillary => true).should be_true
          slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies2.each do |item, q|
          slmc.search_order(:description => item, :supplies => true).should be_true
          slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should ==3
    slmc.confirm_validation_all_items.should be_true
    sleep 6

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@slmc_baby_pin, :admitted=> true)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click_new_guarantor
    slmc.click "_submit", :wait_for => :page
    slmc.click_submit_changes
    slmc.login("nursery", @password).should be_true
    slmc.nursing_gu_search(:pin => @@slmc_baby_pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@slmc_baby_pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    sleep 20
  end
#  it "Bug #2718 - In-House Collection: Include validation in creating new endorsement" do
#    slmc.login("inhouse", @password).should be_true
#
#end
#  it "2831 BASD: Refund Estimate Philhealth claim should not be updated to Final during DAS discharge process"do
#end
#  it "2925 DAS:Updated the Patient's Info Using Other Patient's Details"do
#end
end

  