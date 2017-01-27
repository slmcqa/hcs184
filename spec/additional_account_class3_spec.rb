#!/bin/env ruby
# encoding: utf-8

#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Patient Billing and Accounting - Additional Account Class Discount (Maternity And Employee)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @employee = "1507084910" #"1301028146" #"1301027985" #1210127640" #"1301127954"#guarantor_code=>"0109995"  "
#    @employee = "1502080498" #"1301028146" #"1301027985" #1210127640" #"1301127954"#guarantor_code=>"0109995"  "
#    @maternity_employee = "1107007598"#guarantor_code=>"0109994"
    @maternity_employee =  "1507084911"      #"1301028151"#"1301127955"#guarantor_code=>"0109993"
    @gu_spec_user =  "gycapalungan"  #"gu_spec_user10"
            #@pba_user = "ldcastro" #"sel_pba7"
            @pba_user = "pba1" #"sel_pba7"
     @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#

    @ancillary = {"010001194" => 1, "010001448" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session  
  end

it"Employee with more than one year of service - Create New Admission" do
    slmc.login(@gu_spec_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @employee)
    sleep 4
    #slmc.print_gatepass(:no_result => true, :pin => @employee).should be_true
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @employee).should be_true
    slmc.create_new_admission(:account_class => "EMPLOYEE", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :guarantor_code=>"9907554").should == "Patient admission details successfully saved."
end
it"Employee with more than one year of service - Order Items" do
    slmc.login(@gu_spec_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @employee)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @employee)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end
it"Employee with more than one year of service - Clnically Discharge Patient" do
    slmc.nursing_gu_search(:pin=> @employee)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @employee, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end
it"Employee with more than one year of service - PBA Standard Discharge Patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @employee)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS")
  end
it"Employee with more than one year of service - Check Discount Details" do# not included on test case
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @employee)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)

    sleep 5
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  @@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f

    @@summary[:discounts].to_f.should == ("%0.2f" %(@total_charges)).to_f
    @@summary[:total_hospital_bills].to_f.should == 0.0
  end
it"Employee less than one year of service – Maternity Case - Create New Admission" do
    slmc.login(@gu_spec_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @maternity_employee)
  #  slmc.print_gatepass(:no_result => true, :pin => @maternity_employee).should be_true
    slmc.login(@user, @password).should be_true

    slmc.admission_search(:pin => @maternity_employee).should be_true
    slmc.create_new_admission(:account_class => "EMPLOYEE", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :guarantor_code=>"0109993").should == "Patient admission details successfully saved."
end
it"Employee less than one year of service – Maternity Case - Order Items" do
    slmc.login(@gu_spec_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @maternity_employee)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @maternity_employee)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end
it"Employee less than one year of service – Maternity Case - Clnically Discharge Patient" do
    slmc.nursing_gu_search(:pin=> @maternity_employee)
    @@visit_no1 = slmc.clinically_discharge_patient(:pin => @maternity_employee, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end
it"Employee less than one year of service – Maternity Case - Update Patient Information" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @maternity_employee)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click'maternity'
    slmc.click_submit_changes.should be_true
  end
it"Employee less than one year of service – Maternity Case - PBA Standard Discharge Patient" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @maternity_employee)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end
it"Employee less than one year of service – Maternity Case - Check Guarantor Information Details" do
    (slmc.get_text"//div[@class='commonForm']/table/tbody/tr/td[2]").should == "0109993"
    slmc.skip_update_patient_information.should be_true
    sleep 5
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
it"Employee less than one year of service – Maternity Case - Check Discount Details" do# not included on test case
    sleep 5
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  @@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f
puts "@total_charges - #{@total_charges}"
    @promo_discount = @total_charges * 0.16
    @less_promo_discount = @total_charges - @promo_discount
    @maternity_discount = @less_promo_discount * 0.75
    @less_maternity_discount = @less_promo_discount - @maternity_discount
puts "@promo_discount - #{@promo_discount}"
puts "@maternity_discount - #{@maternity_discount}"
    @@summary[:discounts].to_f.should == ("%0.2f" %(@promo_discount + @maternity_discount)).to_f
    @@summary[:total_hospital_bills].to_f.should == ("%0.2f" %(@less_maternity_discount)).to_f
    @@summary[:total_amount_due].to_f.should == ("%0.2f" %(@less_maternity_discount)).to_f
  end
it"Employee less than one year of service – Maternity Case - Discharge to Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end
end
