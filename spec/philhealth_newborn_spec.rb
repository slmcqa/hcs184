#!/bin/env ruby
# encoding: utf-8

require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
require 'spec_helper'


describe "SLMC :: PhilHealth Newborn Package change of logic- Feature #39737" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @dr_patient1 = Admission.generate_data
    @dr_patient2 = Admission.generate_data
    @baby_patient = Admission.generate_data(:birth_day => (Date.today).strftime("%m/%d/%Y"))
    @password = "123qweuser"
    @promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(0)
    # ancillary quantity not applicable in the application but formatting it to hash for consistency :)
    @others_nb01 = {"060001731" => 1, "060001946" => 1, "060001796" => 1}

    @ancillary_nb02 = {"010000868" => 1}
    @others_nb02 = {"060001731" => 1, "060001946" => 1, "060001796" => 1}

    @ancillary_nb03 = {"010000868" => 1}
    @others_nb03 = {"060001731" => 1, "060001946" => 1, "060001796" => 1}

    @medical_case_rate = [
      "DENGUE I (DENGUE FEVER AND DHF GRADES I & II)",
      "DENGUE II (DHF GRADES III & IV)",
      "PNEUMONIA I (MODERATE RISK)",
      "PNEUMONIA II (HIGH RISK)",
      "ESSENTIAL HYPERTENSION",
      "CEREBRAL INFARCTION (CVA I)",
      "CEREBRO-VASCULAR ACCIDENT (HEMORRHAGE) (CVA II)",
      "ACUTE GASTROENTERITIS (AGE)",
      "ASTHMA",
      "TYPHOID FEVER",
      "NEWBORN CARE PACKAGE IN HOSPITALS AND LYING IN CLINICS"]
#@medical_case_rate = @medical_case_rate.upcase
    @surgical_case_rate = [
      "NSD PACKAGE IN LEVEL 1 HOSPITALS",
      "NSD PACKAGE IN LEVELS 2 TO 4 HOSPITALS",
      "CAESAREAN SECTION",
      "APPENDECTOMY",
      "CHOLECYSTECTOMY",
      "DILATATION AND CURETTAGE",
      "THYROIDECTOMY",
      "HERNIORRHAPHY",
      "MASTECTOMY",
      "HYSTERECTOMY",
      "CATARACT SURGERY",
      "MATERNITY CARE PACKAGE"]
    #@surgical_case_rate = @surgical_case_rate
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "NB01: Creates admission for newborn's mother" do
    slmc.login("jpnabong", @password).should be_true
    @@slmc_mother_pin = (slmc.or_create_patient_record(@dr_patient1.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0170'))).gsub(' ', '')
  end

  it "NB01: Transfer mother from DR to inpatient" do
        slmc.login("jpnabong", @password).should be_true
        sleep 3
    slmc.go_to_outpatient_nursing_page
    slmc.outpatient_to_inpatient(@dr_patient1.merge(:pin => @@slmc_mother_pin, :username => "ldvoropesa", :password => @password, :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287")).should be_true
  end

  it "NB01: Creates newborn admission in DR : Room-in scenario" do
    slmc.login("jpnabong", @password).should be_true
    slmc.register_new_born_patient(:pin => @@slmc_mother_pin, :bdate => (Date.today).strftime("%m/%d/%Y"), :gender => "F",
      :birth_type => "SINGLE", :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,
      :doctor_name => "ABAD", :rooming_in => true, :save => true)
  end

  it "NB01: Acknowledge newborn admission: Room-in scenario" do
    slmc.login("sel_adm7", @password).should be_true
    @@slmc_newborn_pin1 = slmc.acknowledge_new_born(@dr_patient1.merge(:last_name => @dr_patient1[:last_name], :account_class => "HMO", :guarantor_code => "ASAL002", :first_name => "Baby Girl", :gender => "F", :birth_day => Date.today.strftime("%m/%d/%Y"))).should be_true
 #   @@slmc_newborn_pin1 = slmc.acknowledge_new_born(:last_name => "1502080335", :account_class => "HMO", :guarantor_code => "ASAL002").should be_true

  end

  it "NB01: Order items for newborn" do
    sleep 6
    slmc.login("billing_spec_user2", @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@slmc_newborn_pin1)

    @others_nb01.each do |item_o, o|
      slmc.search_order(:others => true, :description => item_o).should be_true
      slmc.add_returned_order(:others => true, :description => item_o, :add => true).should be_true
    end
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:others => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "NB01: Clinical discharge newborn" do
    slmc.go_to_general_units_page
    @@slmc_newborn_visitno1 = slmc.clinically_discharge_patient(:pin => @@slmc_newborn_pin1, :diagnosis => "Z38.0", :pf_amount => 10000, :no_pending_order => true, :save => true).should be_true
  end

  it "NB01: Computes PhilHealth" do
        sleep 6
    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@slmc_newborn_pin1)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@nb_philhealth1 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "Z38.0", :medical_case_type => "ORDINARY CASE", :compute => true, :rvu_code => "99432")
  end

  it "NB01: Saves PhilHealth" do
    @@nb_ph_refno1 = slmc.ph_save_computation.should be_true
  end

  it "NB01: Benefit Summary Totals" do
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@comp_operation = 0
    @@non_comp_operation = 0
    @@non_comp_supplies = 0
    @@comp_others = 0
    @@non_comp_others = 0

    @@orders = @others_nb01
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      if item[:ph_code] == "PHS01"
        amt = item[:rate].to_f * n
        @@comp_drugs += amt  # total compensable drug
      end
      if item[:ph_code] == "PHS02"
        x_lab_amt = item[:rate].to_f * n
        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS04"
        other_amt = item[:rate].to_f * n
        @@comp_others += other_amt  # total compensable others
      end
      if item[:ph_code] == "PHS05"
        supp_amt = item[:rate].to_f * n
        @@comp_supplies += supp_amt  # total compensable supplies
      end
      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
      end
      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
        n_amt_tag = item[:rate].to_f * n
        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
      end
      if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
      end
      if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
      end
      if item[:ph_code] == "PHS09"
        n_other_amt = item[:rate].to_f * n
        @@non_comp_others += n_other_amt  # total non compensable others
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "NB01: Drugs/Medicine Actual Charges and Actual Benefit Claim" do
    @@nb_philhealth1[:actual_medicine_charges].should == "0.00"
    @@nb_philhealth1[:actual_medicine_benefit_claim].should == "0.00"
  end

  it "NB01: X-ray, Laboratories, and Others Actual Charges and Actual Benefit Claim" do
   #actual charges
   total_xrays_lab_others = @@non_comp_others + @@comp_others
   @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @promo_discount)
   @@nb_philhealth1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))

    #actual benefit claim
   #@@nb_philhealth1[:actual_lab_benefit_claim].should == "1000.00"
  end

  it "NB01: Operation Actual Charges and Actual Benefit Claim" do
    @@nb_philhealth1[:actual_operation_charges].should == "0.00"
    @@nb_philhealth1[:actual_operation_benefit_claim].should == "0.00"
  end

  it "NB01: Total Charges" do
    total_actual_charges = @@actual_xray_lab_others
    ((slmc.truncate_to((@@nb_philhealth1[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "NB01: Total Benefit Claim" do
     @@nb_philhealth1[:total_actual_benefit_claim].should == "1250.00"
  end

  it "NB02: Creates admission for newborn's mother" do
    slmc.login("jpnabong", @password).should be_true
    @@slmc_mother_pin2 = (slmc.or_create_patient_record(@dr_patient2.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0170'))).gsub(' ', '')
  end

  it "NB02: Transfer mother from DR to inpatient" do
        slmc.login("jpnabong", @password).should be_true
    slmc.go_to_outpatient_nursing_page
    sleep 3
    slmc.outpatient_to_inpatient(@dr_patient2.merge(:pin => @@slmc_mother_pin2, :username => "ldvoropesa", :password => @password, :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287")).should be_true
  end

  it "NB02: Creates newborn admission in DR : Room-in scenario" do
    slmc.login("jpnabong", @password).should be_true
    slmc.register_new_born_patient(:pin => @@slmc_mother_pin2, :bdate => (Date.today).strftime("%m/%d/%Y"), :gender => "F",
      :birth_type => "SINGLE", :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,
      :doctor_name => "ABAD", :rooming_in => true, :save => true)
  end

  it "NB02: Acknowledge newborn admission: Room-in scenario" do
    slmc.login("sel_adm7", @password).should be_true
    @@slmc_newborn_pin2 = slmc.acknowledge_new_born(@dr_patient2.merge(:last_name => @dr_patient2[:last_name], :account_class => "HMO", :guarantor_code => "ASAL002", :first_name => "Baby Girl", :gender => "F", :birth_day => Date.today.strftime("%m/%d/%Y"))).should be_true
  end

  it "NB02: Order items for newborn" do
    slmc.login("billing_spec_user2", @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@slmc_newborn_pin2)
    @ancillary_nb02.each do |item_a, a|
      slmc.search_order(:ancillary => true, :description => item_a).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item_a, :add => true).should be_true
    end
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single").should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@slmc_newborn_pin2)
    @others_nb02.each do |item_o, o|
      slmc.search_order(:others => true, :description => item_o).should be_true
      slmc.add_returned_order(:others => true, :description => item_o, :add => true).should be_true
    end
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:others => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "NB02: Clinical discharge newborn" do
    slmc.go_to_general_units_page
    @@slmc_newborn_visitno2 = slmc.clinically_discharge_patient(:pin => @@slmc_newborn_pin2, :diagnosis => "A00", :pf_amount => 10000, :no_pending_order => true, :save => true).should be_true
  end

  it "NB02: Computes PhilHealth" do
    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@slmc_newborn_pin2)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@nb_philhealth2 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "A00", :medical_case_type => "ORDINARY CASE", :compute => true, :rvu_code => "99432")
  end

  it "NB02: Saves PhilHealth" do
    @@nb_ph_refno2 = slmc.ph_save_computation.should be_true
  end

  it "NB02: Benefit Summary Totals" do
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@comp_operation = 0
    @@non_comp_operation = 0
    @@non_comp_supplies = 0
    @@comp_others = 0
    @@non_comp_others = 0

    @@orders = @others_nb02.merge(@ancillary_nb02)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      if item[:ph_code] == "PHS01"
        amt = item[:rate].to_f * n
        @@comp_drugs += amt  # total compensable drug
      end
      if item[:ph_code] == "PHS02"
        x_lab_amt = item[:rate].to_f * n
        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS04"
        other_amt = item[:rate].to_f * n
        @@comp_others += other_amt  # total compensable others
      end
      if item[:ph_code] == "PHS05"
        supp_amt = item[:rate].to_f * n
        @@comp_supplies += supp_amt  # total compensable supplies
      end
      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
      end
      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
        n_amt_tag = item[:rate].to_f * n
        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
      end
      if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
      end
      if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
      end
      if item[:ph_code] == "PHS09"
        n_other_amt = item[:rate].to_f * n
        @@non_comp_others += n_other_amt  # total non compensable others
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "NB02: Drugs/Medicine Actual Charges and Actual Benefit Claim" do
    @@nb_philhealth2[:actual_medicine_charges].should == "0.00"
    @@nb_philhealth2[:actual_medicine_benefit_claim].should == "0.00"
  end

  it "NB02: X-ray, Laboratories, and Others Actual Charges and Actual Benefit Claim" do
   #actual charges
   total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others + @@comp_others
   @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @promo_discount)
   @@nb_philhealth2[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))

    #actual benefit claim
   @@actual_comp_xray_lab_others = (@@comp_xray_lab + @@comp_others) - (@promo_discount * (@@comp_xray_lab + @@comp_others))
   @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
   if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
   else
      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
   end
   @@actual_lab_benefit_claim1 = 0.00
   @@nb_philhealth2[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))

  end

  it "NB02: Operation Actual Charges and Actual Benefit Claim" do
    @@nb_philhealth2[:actual_operation_charges].should == "0.00"
    @@nb_philhealth2[:actual_operation_benefit_claim].should == "0.00"
  end

  it "NB02: Total Charges" do
    total_actual_charges = @@actual_xray_lab_others
    ((slmc.truncate_to((@@nb_philhealth2[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "NB02: Total Benefit Claim" do
     @@total_actual_benefit_claim = @@actual_lab_benefit_claim1
    ((slmc.truncate_to((@@nb_philhealth2[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "NB03: Creates admission for baby" do
    slmc.login("billing_spec_user2", @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@slmc_newborn_pin3 = slmc.create_new_patient(@baby_patient.merge(:birth_day => (Date.today).strftime("%m/%d/%Y"))).gsub(' ', '')
        slmc.login("billing_spec_user2", @password).should be_true
    slmc.admission_search(:pin => @@slmc_newborn_pin3).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it "NB03: Order items for newborn" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@slmc_newborn_pin3)
    @ancillary_nb03.each do |item_a, a|
      slmc.search_order(:ancillary => true, :description => item_a).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item_a, :add => true).should be_true
    end
    @others_nb03.each do |item_o, o|
      slmc.search_order(:others => true, :description => item_o).should be_true
      slmc.add_returned_order(:others => true, :description => item_o, :add => true).should be_true
    end
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :others => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
  end

  it "NB03: Clinical discharge newborn" do
    slmc.go_to_general_units_page
    @@slmc_newborn_visitno3 = slmc.clinically_discharge_patient(:pin => @@slmc_newborn_pin3, :diagnosis => "A00", :pf_amount => 10000, :no_pending_order => true, :save => true).should be_true
  end

  it "NB03: Computes PhilHealth" do
    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@slmc_newborn_pin3)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@nb_philhealth3 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "Z38.0", :medical_case_type => "ORDINARY CASE", :compute => true, :rvu_code => "99432")
  end

  it "NB03: Saves PhilHealth" do
    @@nb_ph_refno3 = slmc.ph_save_computation.should be_true
  end

  it "NB03: Benefit Summary Totals" do
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@comp_operation = 0
    @@non_comp_operation = 0
    @@non_comp_supplies = 0
    @@comp_others = 0
    @@non_comp_others = 0

    @@orders = @others_nb03.merge(@ancillary_nb03)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      if item[:ph_code] == "PHS01"
        amt = item[:rate].to_f * n
        @@comp_drugs += amt  # total compensable drug
      end
      if item[:ph_code] == "PHS02"
        x_lab_amt = item[:rate].to_f * n
        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS04"
        other_amt = item[:rate].to_f * n
        @@comp_others += other_amt  # total compensable others
      end
      if item[:ph_code] == "PHS05"
        supp_amt = item[:rate].to_f * n
        @@comp_supplies += supp_amt  # total compensable supplies
      end
      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
      end
      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
        n_amt_tag = item[:rate].to_f * n
        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
      end
      if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
      end
      if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
      end
      if item[:ph_code] == "PHS09"
        n_other_amt = item[:rate].to_f * n
        @@non_comp_others += n_other_amt  # total non compensable others
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "NB03: Drugs/Medicine Actual Charges and Actual Benefit Claim" do
    @@nb_philhealth3[:actual_medicine_charges].should == "0.00"
    @@nb_philhealth3[:actual_medicine_benefit_claim].should == "0.00"
  end

  it "NB03: X-ray, Laboratories, and Others Actual Charges and Actual Benefit Claim" do
   #actual charges
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others + @@comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @promo_discount)
    @@nb_philhealth3[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))

    #actual benefit claim
    @@actual_comp_xray_lab_others = (@@comp_xray_lab + @@comp_others) - (@promo_discount * (@@comp_xray_lab + @@comp_others))
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
       @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
    else
       @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@actual_lab_benefit_claim1 = 0.00
    @@nb_philhealth3[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))

  end

  it "NB03: Operation Actual Charges and Actual Benefit Claim" do
    @@nb_philhealth3[:actual_operation_charges].should == "0.00"
    @@nb_philhealth3[:actual_operation_benefit_claim].should == "0.00"
  end

  it "NB03: Total Charges" do
    total_actual_charges = @@actual_xray_lab_others
    ((slmc.truncate_to((@@nb_philhealth3[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "NB03: Total Benefit Claim" do
     @@total_actual_benefit_claim = @@actual_lab_benefit_claim1
     @@total_actual_benefit_claim = 1250.00
    ((slmc.truncate_to((@@nb_philhealth3[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

#################### ###################################### PHILHEALTH CASE RATES #########################################################

  it "Dropdown list should list the following Not Applicable, Medical, and Surgical" do
    slmc.ph_edit
    slmc.get_select_options("phCaseRateType").should == ["Not Applicable", "MEDICAL", "SURGICAL"]
  end

  it "Dropdown list defaults to “Not Applicable” if none is selected" do
    slmc.get_selected_label("phCaseRateType").should == "Not Applicable"
  end

  it "Case Rate Package is not displayed" do
    slmc.is_visible("caseRateNo").should be_false
  end

  it "Case Rate Package displays Medical case rate" do
    slmc.select("phCaseRateType", "MEDICAL")
    sleep 2
#    slmc.is_visible("caseRateNo").should be_true
  end

  it "Screen: Case Rate Package Medical" do
   # (slmc.get_select_options("caseRateNo").to_s.upcase).should == (@medical_case_rate)

  end

  it "Case Rate Package displays Surgical case rate" do
    slmc.select("phCaseRateType", "Not Applicable")
    sleep 2
    slmc.select("phCaseRateType", "SURGICAL")
    sleep 2
    #slmc.is_visible("caseRateNo").should be_true
  end

  it "Screen: Case Rate Package Surgical" do
  #  slmc.get_select_options("caseRateNo").should == (@surgical_case_rate)
#    (slmc.get_select_options("caseRateNo").to_s).upcase.should == (@surgical_case_rate)
  end

  it "Screen: View details" do
    #@@ph1 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "Z38.0", :case_rate_type => "SURGICAL", :case_rate => "CHOLECYSTECTOMY", :rvu_code => "47560", :compute => true)
    @@ph1 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "Z38.0", :case_rate_type => "SURGICAL", :case_rate => "Cholecystectomy", :rvu_code => "47560", :compute => true)

    slmc.ph_save_computation
    slmc.ph_view_details(:close => true).should == 4
  end

  it "Benefit Summary: Actual Charges" do
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@comp_operation = 0
    @@non_comp_operation = 0
    @@non_comp_supplies = 0
    @@comp_others = 0
    @@non_comp_others = 0

    @@orders = @others_nb03.merge(@ancillary_nb03)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      if item[:ph_code] == "PHS01"
        amt = item[:rate].to_f * n
        @@comp_drugs += amt  # total compensable drug
      end
      if item[:ph_code] == "PHS02"
        x_lab_amt = item[:rate].to_f * n
        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS04"
        other_amt = item[:rate].to_f * n
        @@comp_others += other_amt  # total compensable others
      end
      if item[:ph_code] == "PHS05"
        supp_amt = item[:rate].to_f * n
        @@comp_supplies += supp_amt  # total compensable supplies
      end
      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
      end
      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
        n_amt_tag = item[:rate].to_f * n
        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
      end
      if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
      end
      if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
      end
      if item[:ph_code] == "PHS09"
        n_other_amt = item[:rate].to_f * n
        @@non_comp_others += n_other_amt  # total non compensable others
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end

    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others + @@comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @promo_discount)
    @@ph1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Benefit Summary: Actual Benefit Claim" do # Actual Charges should have values but in Actual PH_Claimed it should be 0.00
    @@ph1[:actual_lab_benefit_claim].should == ("%0.2f" %(0.0))
  end

  it "Benefit Summary:Total Actual Benefit Claim Amount" do
    @@total_actual_benefit_claim = 31000 - (31000 * 0.40) # 31000 fixed for cholecystectomy
    @@ph1[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Benefit Summary:Total Actual Charges Amount" do
    total_actual_charges = @@actual_xray_lab_others
    ((slmc.truncate_to((@@ph1[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "Patient Philhealth Adjustment" do
    slmc.pba_adjustment_and_cancellation(:doc_type => "PHILHEALTH", :search_option => "VISIT NUMBER", :entry => @@slmc_newborn_visitno3).should be_true
  end
  
end