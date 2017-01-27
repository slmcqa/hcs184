require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: PhilHealth Cancellation - Feature of #39738" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @or_patient = Admission.generate_data
    @user = "billing_spec_user8"
    @password = "123qweuser"
    @with_pba_user = "ldcastro"
    @without_pba_user = "cacepeda"

    @drugs =  {"042090007" => 1}
    @ancillary = {"010000317" => 1}
    @supplies = {"085100003" => 1}
    @operation = {"060000058" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Inpatient - Create and Admit patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin = slmc.create_new_patient(Admission.generate_data).gsub(' ', '')
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it "Inpatient - Order items" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "Inpatient - Clinically Discharge Patient" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => "1000", :save => true).should be_true
  end

  it "Inpatient - Discharge Patient and Compute Philhealth during discharge" do
    slmc.login(@without_pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    @@ph1 = slmc.philhealth_computation(:diagnosis => "CHOLERA", :claim_type => "ACCOUNTS RECEIVABLE", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    @@pf_ref1 = slmc.ph_save_computation
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
    @balance_due = slmc.get_balance_due.to_f
    slmc.oss_add_payment(:type => 'CASH', :amount => @balance_due.to_s)
    slmc.submit_payment.should be_true
  end

  it "Inpatient - Billing Officer without ROLE_PHILHEALTH_OFFICER cancels patient Philhealth Claim" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
    slmc.ph_cancel_computation.should be_false
  end

  it "Inpatient - Billing officer with ROLE_PHILHEALTH_OFFICER cancels patient Philhealth Claim" do
    slmc.login(@with_pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
    slmc.is_editable("btnCancel").should be_true
    slmc.ph_cancel_computation.should be_false
  end

  it "Inpatient2 - Creates and Admit patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin2 = slmc.create_new_patient(Admission.generate_data).gsub(' ', '')
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin2).should be_true
    slmc.create_new_admission(:org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it "Inpatient2 - Order items" do
    slmc.nursing_gu_search(:pin => @@pin2)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin2)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "Inpatient2 - Clinically Discharge Patient" do
    slmc.go_to_general_units_page
    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@pin2, :pf_amount => "1000", :save => true)
    (@@visit_no2).should_not be_false
  end

  it "Inpatient2 - Compute Philhealth" do
    slmc.login(@without_pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no2)
    @@ph2 = slmc.philhealth_computation(:diagnosis => "CHOLERA", :claim_type => "ACCOUNTS RECEIVABLE", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "Inpatient2 - Billing officer without role_philhealth_officer cancels patient philhealth claim" do
    slmc.ph_cancel_computation.should be_false
  end

  it "Inpatient2 - Billing officer with role_philhealth_officer cancels patient philhealth claim" do
    slmc.login(@with_pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no2)
    slmc.ph_cancel_computation.should be_true
  end

  it "Inpatient3 - Creates and Admit patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin3 = slmc.create_new_patient(Admission.generate_data).gsub(' ', '')
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin3).should be_true
    slmc.create_new_admission(:org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it "Inpatient3 - Order items" do
    slmc.nursing_gu_search(:pin => @@pin3)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin3)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "Inpatient3 - Clinically Discharge Patient" do
    slmc.nursing_gu_search(:pin => @@pin3)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no3 = slmc.clinically_discharge_patient(:pin => @@pin3, :pf_amount => "1000", :save => true)
    (@@visit_no3).should_not be_false
  end

  it "Inpatient3 - Database Manipulation - Add and Edit records of patient" do
    @days1 = 1
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days1, :pin => @@pin3, :visit_no => @@visit_no3)
    Database.connect
    @days1.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no3,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no3, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days1 - i)
    end
    Database.logoff
  end

  it "Inpatient3 - Compute Philhealth" do
    slmc.login(@without_pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin3)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no3)
    @@ph3 = slmc.philhealth_computation(:diagnosis => "CHOLERA", :claim_type => "ACCOUNTS RECEIVABLE", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "Inpatient4 - User without appropriate role cancels patient claim with more than 1 day of confinement" do
    slmc.ph_cancel_computation.should be_false
  end

  it "Inpatient4 - User with appropriate role cancels patient claim with more than 1 day of confinement" do
    slmc.login(@with_pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin3)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no3)
    slmc.ph_cancel_computation.should be_true
  end
end