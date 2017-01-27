require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'


describe "SLMC :: Partial Manual Discount" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @user = "billing_spec_user8"
    @password = "123qweuser"

    @drugs = {"040000357" => 1}
    @ancillary = {"010000003" => 1}
    @supplies = {"080100021" => 1}

#    @@employee = "1108008819" # 1009167
#    @@employee_dependent = "1108008820"
#    @@doctor = "1108008831" # 3442
#    @@doctor_dependent = "1108008829" # 3442
#    @@board_member = "1106001978" # BMBH001 BME
#    @@board_member_dependent = "1108008846"
    @@discount_rate = 100000.0



        @@employee = "1309047050" # 1009167
    @@employee_dependent = "1309047139"
    @@doctor = "1309047144" # 3442
    @@doctor_dependent = "1309047154" # 3442
    @@board_member = "1309047147" # BMBH001
    @@board_member_dependent = "1309047149"

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "EMPLOYEE - Creates patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@employee)
    slmc.print_gatepass(:no_result => true, :pin => @@employee)
    slmc.admission_search(:pin => @@employee)
    if (slmc.get_text("results").gsub(' ', '').include? @@employee) && slmc.is_element_present("link=Admit Patient")
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "EMPLOYEE", :guarantor_code => "1009167").should == "Patient admission details successfully saved."
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @@employee = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Tan", :first_name => "Kathleen Joyce", :middle_name => "Fetalvero", :birth_day => "06/02/1987", :gender => "F"))
      else
        if slmc.verify_gu_patient_status(@@employee) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@employee, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
          slmc.go_to_general_units_page
          slmc.clinically_discharge_patient(:pin => @@employee, :pf_amount => "1000", :save => true).should be_true
        end
        slmc.login("ldcastro", @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.discharge_patient_either_standard_or_das.should be_true

        slmc.login(@user, @password).should be_true
        slmc.nursing_gu_search(:pin => @@employee)
        slmc.print_gatepass(:no_result => true, :pin => @@employee).should be_true
      end
      slmc.admission_search(:pin => @@employee)
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "EMPLOYEE", :guarantor_code => "1009167").should == "Patient admission details successfully saved."
    end
  end
  it "EMPLOYEE - Order items" do
    slmc.nursing_gu_search(:pin => @@employee)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@employee)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
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

  it "EMPLOYEE - Clinical Discharge" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@employee, :pf_amount => "1000", :save => true).should be_true
  end

  it "EMPLOYEE - Should be able to add partial discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
    slmc.go_to_page_using_visit_number("Partial Discount", @@visit_no)
    slmc.select_partial_discount_type(:manual => true).should be_true
    slmc.add_discount(:discount_type => "Fixed", :discount => "Employee Discount", :discount_scope => "ACROSS THE BOARD", :discount_rate => @@discount_rate, :close_window => true, :save => true).should be_true
  end

  it "EMPLOYEE - Checks Payment if Partial Discount is added for Total Discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)

    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary).merge(@supplies)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end
    @@gross = (@@gross * 100).round.to_f / 100
    @@total_discount = (slmc.compute_discounts(:unit_price => @@gross, :promo => true) + @@discount_rate)
    @@total_hospital_bill = @@gross - @@total_discount

    @@summary = slmc.get_billing_details_from_payment_data_entry

    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bill),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 0.02
  end

  it "EMPLOYEE DEPENDENT - Create Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@employee_dependent)
    slmc.print_gatepass(:no_result => true, :pin => @@employee_dependent)
    slmc.admission_search(:pin => @@employee_dependent)
    if (slmc.get_text("results").gsub(' ', '').include? @@employee_dependent) && slmc.is_element_present("link=Admit Patient")
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "ULCER", :account_class => "EMPLOYEE DEPENDENT", :guarantor_code => "1009167").should == "Patient admission details successfully saved."
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @@employee_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Tan", :first_name => "Kate Venice", :middle_name => "GO", :birth_day => "03/24/1985", :gender => "F"))
      else
        if slmc.verify_gu_patient_status(@@employee_dependent) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@employee_dependent, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
          slmc.go_to_general_units_page
          slmc.clinically_discharge_patient(:pin => @@employee_dependent, :pf_amount => "1000", :save => true).should be_true
        end
        slmc.login("ldcastro", @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.discharge_patient_either_standard_or_das.should be_true

        slmc.login(@user, @password).should be_true
        slmc.nursing_gu_search(:pin => @@employee_dependent)
        slmc.print_gatepass(:no_result => true, :pin => @@employee_dependent).should be_true
      end
      slmc.admission_search(:pin => @@employee_dependent)
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "ULCER", :account_class => "EMPLOYEE DEPENDENT", :guarantor_code => "1009167").should == "Patient admission details successfully saved."
    end
  end

  it "EMPLOYEE DEPENDENT - Order items" do
    slmc.nursing_gu_search(:pin => @@employee_dependent)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@employee_dependent)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
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

  it "EMPLOYEE DEPENDENT - Clinical Discharge" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@employee_dependent, :pf_amount => "1000", :save => true).should be_true
  end

  it "EMPLOYEE DEPENDENT - Should be able to add partial discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
    slmc.go_to_page_using_visit_number("Partial Discount", @@visit_no)
    slmc.select_partial_discount_type(:manual => true).should be_true
    slmc.add_discount(:discount_type => "Fixed", :discount => "Employee Dependent Discount", :discount_scope => "ACROSS THE BOARD", :discount_rate => @@discount_rate, :close_window => true, :save => true).should be_true
  end

  it "EMPLOYEE DEPENDENT - Checks Payment if Partial Discount is added for Total Discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)

    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary).merge(@supplies)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end
    @@gross = (@@gross * 100).round.to_f / 100
    @@total_discount = (slmc.compute_discounts(:unit_price => @@gross, :promo => true) + @@discount_rate)
    @@total_hospital_bill = @@gross - @@total_discount

    @@summary = slmc.get_billing_details_from_payment_data_entry

    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bill),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 0.02
  end

  it "DOCTOR - Create Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@doctor)
    slmc.print_gatepass(:no_result => true, :pin => @@doctor)
    slmc.admission_search(:pin => @@doctor)
    if (slmc.get_text("results").gsub(' ', '').include? @@doctor) && slmc.is_element_present("link=Admit Patient")
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "ULCER", :account_class => "DOCTOR", :guarantor_code => "3442").should == "Patient admission details successfully saved."
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @@doctor = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Roxas", :first_name => "Diana Jean", :middle_name => "Calderon", :birth_day => "09/20/1958", :gender => "F"))
      else
        if slmc.verify_gu_patient_status(@@doctor) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@doctor, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
          slmc.go_to_general_units_page
          slmc.clinically_discharge_patient(:pin => @@doctor, :pf_amount => "1000", :save => true).should be_true
        end
        slmc.login("ldcastro", @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.discharge_patient_either_standard_or_das.should be_true

        slmc.login(@user, @password).should be_true
        slmc.nursing_gu_search(:pin => @@doctor)
        slmc.print_gatepass(:no_result => true, :pin => @@doctor).should be_true
      end
      slmc.admission_search(:pin => @@doctor)
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "ULCER", :account_class => "DOCTOR", :guarantor_code => "3442").should == "Patient admission details successfully saved."
    end
  end

  it "DOCTOR - Order items" do
    slmc.nursing_gu_search(:pin => @@doctor)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@doctor)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
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

  it "DOCTOR - Clinical Discharge" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@doctor, :pf_amount => "1000", :save => true).should be_true
  end

  it "DOCTOR - Should be able to add partial discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor)
    slmc.go_to_page_using_visit_number("Partial Discount", @@visit_no)
    slmc.select_partial_discount_type(:manual => true).should be_true
    slmc.add_discount(:discount_type => "Fixed", :discount => "Doctor Discount", :discount_scope => "ACROSS THE BOARD", :discount_rate => @@discount_rate, :close_window => true, :save => true).should be_true
 end

  it "DOCTOR - Checks Payment if Partial Discount is added for Total Discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)

    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary).merge(@supplies)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end
    @@gross = (@@gross * 100).round.to_f / 100
    @@total_discount = (slmc.compute_discounts(:unit_price => @@gross, :promo => true) + @@discount_rate)
    @@total_hospital_bill = @@gross - @@total_discount

    @@summary = slmc.get_billing_details_from_payment_data_entry

    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bill),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 0.02
  end

  it "DOCTOR DEPENDENT - Create Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@doctor_dependent)
    slmc.print_gatepass(:no_result => true, :pin => @@doctor_dependent)
    slmc.admission_search(:pin => @@doctor_dependent)
    if (slmc.get_text("results").gsub(' ', '').include? @@doctor_dependent) && slmc.is_element_present("link=Admit Patient")
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "ULCER", :account_class => "DOCTOR DEPENDENT", :guarantor_code => "3442").should == "Patient admission details successfully saved."
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @@doctor_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Roxas", :first_name => "Dominique", :middle_name => "C", :birth_day => "10/07/2001", :gender => "M"))
      else
        if slmc.verify_gu_patient_status(@@doctor_dependent) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@doctor_dependent, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
          slmc.go_to_general_units_page
          slmc.clinically_discharge_patient(:pin => @@doctor_dependent, :pf_amount => "1000", :save => true).should be_true
        end
        slmc.login("ldcastro", @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.discharge_patient_either_standard_or_das.should be_true

        slmc.login(@user, @password).should be_true
        slmc.nursing_gu_search(:pin => @@doctor_dependent)
        slmc.print_gatepass(:no_result => true, :pin => @@doctor_dependent).should be_true
      end
      slmc.admission_search(:pin => @@doctor_dependent)
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "ULCER", :account_class => "DOCTOR DEPENDENT", :guarantor_code => "3442").should == "Patient admission details successfully saved."
    end
  end

  it "DOCTOR DEPENDENT - Order items" do
    slmc.nursing_gu_search(:pin => @@doctor_dependent)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@doctor_dependent)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
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

  it "DOCTOR DEPENDENT - Clinical Discharge" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@doctor_dependent, :pf_amount => "1000", :save => true).should be_true
  end

  it "DOCTOR DEPENDENT - Should be able to add partial discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
    slmc.go_to_page_using_visit_number("Partial Discount", @@visit_no)
    slmc.select_partial_discount_type(:automatic => true)
    slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
    slmc.go_to_page_using_visit_number("Partial Discount", @@visit_no)
    slmc.select_partial_discount_type(:manual => true).should be_true
    slmc.add_discount(:discount_type => "Fixed", :discount => "Doctor Dependent Discount", :discount_scope => "ACROSS THE BOARD", :discount_rate => @@discount_rate, :close_window => true, :save => true).should be_true
  end

  it "DOCTOR DEPENDENT - Checks Payment if Partial Discount is added for Total Discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)

    # both manual and automatic discount partial
    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary).merge(@supplies)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end
    @@gross = (@@gross * 100).round.to_f / 100

    @@order_type1 = 0
    @@order_type2 = 0
    @@order_type3 = 0

    @@orders =  @ancillary.merge(@drugs).merge(@supplies)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      if item[:order_type] == "ORT01"
        amt = item[:rate].to_f * n
        @@order_type1 += amt
      end
      if item[:order_type] == "ORT02"
        n_amt = item[:rate].to_f * n
        @@order_type2 += n_amt
      end
      if item[:order_type] == "ORT03"
        x_lab_amt = item[:rate].to_f * n
        @@order_type3 += x_lab_amt
      end
    end

    @@courtesy_discount1 = 0
    @@courtesy_discount2 = 0
    @@courtesy_discount3 = 0
    @@discount1 = 0
    @@discount2 = 0
    @@discount3 = 0

    @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo => true)

    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :promo => true)
    @@cd1 = @@order_type1 - @@discount1
    @@courtesy_discount1 = slmc.compute_courtesy_discount(:percent => true, :net => @@cd1, :amount => 25)

    @@discount3 = slmc.compute_discounts(:unit_price => @@order_type3, :promo => true)
    @@cd3 = @@order_type3 - @@discount3
    @@courtesy_discount3 = slmc.compute_courtesy_discount(:percent => true, :net => @@cd3, :amount => 25)

    @@total_discount = @@discount + (@@courtesy_discount1 + @@courtesy_discount3) + @@discount_rate
    @@total_hospital_bills = @@gross - @@total_discount

    @@summary = slmc.get_billing_details_from_payment_data_entry

    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
    @@summary[:discounts].should == ("%0.2f" %(@@total_discount + 0.01))
    @@summary[:total_hospital_bills].should == ("%0.2f" %(@@total_hospital_bills - 0.01))
    @@summary[:balance_due].should == ("%0.2f" %(@@total_hospital_bills - 0.01))
  end

  it "BOARD MEMBER - Create Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@board_member)
    slmc.print_gatepass(:no_result => true, :pin => @@board_member)
    slmc.admission_search(:pin => @@board_member)
    if (slmc.get_text("results").gsub(' ', '').include? @@board_member) && slmc.is_element_present("link=Admit Patient")
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "ULCER", :account_class => "BOARD MEMBER", :guarantor_code => "BMBH001").should == "Patient admission details successfully saved."
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @@board_member = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "CHINHWANG", :first_name => "BUN", :middle_name => "SAM", :birth_day => "01/21/1952", :gender => "M"))
      else
        if slmc.verify_gu_patient_status(@@board_member) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@board_member, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
          slmc.go_to_general_units_page
          slmc.clinically_discharge_patient(:pin => @@board_member, :pf_amount => "1000", :save => true).should be_true
        end
        slmc.login("ldcastro", @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.discharge_patient_either_standard_or_das.should be_true

        slmc.login(@user, @password).should be_true
        slmc.nursing_gu_search(:pin => @@board_member)
        slmc.print_gatepass(:no_result => true, :pin => @@board_member).should be_true
      end
      slmc.admission_search(:pin => @@board_member)
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "ULCER", :account_class => "BOARD MEMBER", :guarantor_code => "BMBH001").should == "Patient admission details successfully saved."
    end
  end

  it "BOARD MEMBER - Order items" do
    slmc.nursing_gu_search(:pin => @@board_member)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@board_member)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
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

  it "BOARD MEMBER - Clinical Discharge" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@board_member, :pf_amount => "1000", :save => true).should be_true
  end

  it "BOARD MEMBER - Should be able to add partial discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
    slmc.go_to_page_using_visit_number("Partial Discount", @@visit_no)
    slmc.select_partial_discount_type(:manual => true).should be_true
    slmc.add_discount(:discount_type => "Fixed", :discount => "Board Member", :discount_scope => "ACROSS THE BOARD", :discount_rate => @@discount_rate, :close_window => true, :save => true).should be_true
  end

  it "BOARD MEMBER - Checks Payment if Partial Discount is added for Total Discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)

    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary).merge(@supplies)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end
    @@gross = (@@gross * 100).round.to_f / 100
    @@total_discount = (slmc.compute_discounts(:unit_price => @@gross, :senior => true) + @@discount_rate) # senior (patient birthday on 01/21/2012)
    @@total_hospital_bill = @@gross - @@total_discount

    @@summary = slmc.get_billing_details_from_payment_data_entry

    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bill),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 0.02
  end

  it "BOARD MEMBER DEPENDENT - Create Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@board_member_dependent)
    slmc.print_gatepass(:no_result => true, :pin => @@board_member_dependent)
    slmc.admission_search(:pin => @@board_member_dependent)
    if (slmc.get_text("results").gsub(' ', '').include? @@board_member_dependent) && slmc.is_element_present("link=Admit Patient")
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "ULCER", :account_class => "BOARD MEMBER DEPENDENT", :guarantor_code => "BMBH001").should == "Patient admission details successfully saved."
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @@board_member_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Hwang", :first_name => "Consuelo", :middle_name => "Qu", :birth_day => "10/08/1945", :gender => "M"))
      else
        if slmc.verify_gu_patient_status(@@board_member_dependent) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@board_member_dependent, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
          slmc.go_to_general_units_page
          slmc.clinically_discharge_patient(:pin => @@board_member_dependent, :pf_amount => "1000", :save => true).should be_true
        end
        slmc.login("ldcastro", @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.discharge_patient_either_standard_or_das.should be_true

        slmc.login(@user, @password).should be_true
        slmc.nursing_gu_search(:pin => @@board_member_dependent)
        slmc.print_gatepass(:no_result => true, :pin => @@board_member_dependent).should be_true
      end
      slmc.admission_search(:pin => @@board_member_dependent)
      slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "ULCER", :account_class => "BOARD MEMBER DEPENDENT", :guarantor_code => "BMBH001").should == "Patient admission details successfully saved."
    end
  end

  it "BOARD MEMBER DEPENDENT - Order items" do
    slmc.nursing_gu_search(:pin => @@board_member_dependent)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@board_member_dependent)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
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

  it "BOARD MEMBER DEPENDENT - Clinical Discharge" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@board_member_dependent, :pf_amount => "1000", :save => true).should be_true
  end

  it "BOARD MEMBER DEPENDENT - Should be able to add partial discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
    slmc.go_to_page_using_visit_number("Partial Discount", @@visit_no)
    slmc.select_partial_discount_type(:manual => true).should be_true
    slmc.add_discount(:discount_type => "Fixed", :discount => "Board Member", :discount_scope => "ACROSS THE BOARD", :discount_rate => @@discount_rate, :close_window => true, :save => true).should be_true
  end

  it "BOARD MEMBER DEPENDENT - Checks Payment if Partial Discount is added for Total Discount" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)

    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary).merge(@supplies)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end
    @@gross = (@@gross * 100).round.to_f / 100
    @@total_discount = (slmc.compute_discounts(:unit_price => @@gross, :senior => true) + @@discount_rate)
    @@total_hospital_bill = @@gross - @@total_discount

    @@summary = slmc.get_billing_details_from_payment_data_entry

    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bill),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 0.02
  end

end
