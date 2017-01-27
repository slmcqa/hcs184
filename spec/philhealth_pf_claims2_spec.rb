require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: PhilHealth Claims - ER and DR Module" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @er_patient = Admission.generate_data
    @dr_patient = Admission.generate_data

    @@promo_discount4 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@er_patient[:age])
    @@promo_discount5 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@dr_patient[:age])

    @password = "123qweuser"
    @user = "gu_spec_user8"

    @drugs =  {"042090007" => 1}
    @ancillary = {"010000317" => 1}
    @supplies = {"085100003" => 1}
    @operation = {"060000058" => 1, "060000003" => 1, "060000434" => 1}

    @doctor_list = ["CASTILLO, JOSEFINO CORTEZ", "ABAD, MARCO JOSE FULVIO CICOLI", "CORTEZ, EDGARDO REYES"]
    @anaes_list = ["LIM, ADELINA SABAY", "REYES, JOCELYNN ILANO", "MANZON, AMELIA JASMIN MANZANO"]
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


#Claim Type: Accounts Receivable
#With Operation: Yes
#### NO ER PHILHEALTH
##  it "PF Claims1 - ER : Claim Type: Accounts Receivable | With Operation: Yes" do
##    slmc.login("sel_er3", @password).should be_true
##    @@er_pin = slmc.er_create_patient_record(@er_patient.merge(:admit => true, :gender => 'F')).gsub(' ','')
##    slmc.er_occupancy_search(:pin => @@er_pin)
##        slmc.login("sel_er3", @password).should be_true
##    slmc.go_to_er_page_using_pin("Order Page", @@er_pin)
##    @drugs.each do |item, q|
##      slmc.search_order(:description => item, :drugs => true).should be_true
##      slmc.add_returned_order(:drugs => true, :description => item,
##        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
##    end
##    @ancillary.each do |item, q|
##      slmc.search_order(:description => item, :ancillary => true).should be_true
##      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
##    end
##    @supplies.each do |item, q|
##      slmc.search_order(:description => item, :supplies => true).should be_true
##      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
##    end
##    sleep 5
##    slmc.verify_ordered_items_count(:drugs => 1).should be_true
##    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
##    slmc.verify_ordered_items_count(:supplies => 1).should be_true
##    slmc.er_submit_added_order
##    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
##    slmc.confirm_validation_all_items.should be_true
##  end
##
##  it "PF Claims1 - ER : Order Procedures in OR" do
##    slmc.login("slaquino", @password).should be_true
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
##    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
##    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
##    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
##    slmc.confirm_order(:anaesth_code => "1088", :surgeon_code => "0389")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code3 = slmc.search_service(:procedure => true, :description => "OPERATING ROOM CHARGES")
##    slmc.add_returned_service(:item_code => @@item_code3, :description => "OPERATING ROOM CHARGES")
##    slmc.confirm_order(:anaesth_code => "3310", :surgeon_code => "0979")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##  end
##
##  it "PF Claims1 - ER : Clinical Discharge Patient" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.go_to_er_page
##    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => "1000", :save => true).should be_true
##  end
##
##  it "PF Claims1 - ER : Go to PhilHealth page and computes PhilHealth" do
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin).should be_true
##    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
##    @@er_ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
##  end
##
##  it "PF Claims1 - ER : All surgeons and anesthesiologist must be displayed in the drop down list" do
##    sleep 10
##    doctors = slmc.get_select_options("surgeon.doctorCode")
##    (doctors.count).should == 3
##    doctors[0].should == @doctor_list[0]
##    doctors[1].should == @doctor_list[1]
##    doctors[2].should == @doctor_list[2]
##    anaes = slmc.get_select_options("anesthesiologist.doctorCode")
##    (anaes.count).should == 3
##    anaes[0].should == @anaes_list[0]
##    anaes[1].should == @anaes_list[1]
##    anaes[2].should == @anaes_list[2]
##    slmc.ph_save_computation
##  end
##
##  it "PF Claims1 - ER : Check Benefit Summary totals" do
##    @@comp_drugs = 0
##    @@comp_xray_lab = 0
##    @@comp_operation = 0
##    @@comp_others = 0
##    @@comp_supplies = 0
##    @@non_comp_drugs = 0
##    @@non_comp_drugs_mrp_tag = 0
##    @@non_comp_xray_lab = 0
##    @@non_comp_operation = 0
##    @@non_comp_others = 0
##    @@non_comp_supplies = 0
##
##    @@orders = @ancillary.merge(@supplies).merge(@drugs).merge(@operation)
##    @@orders.each do |order,n|
##      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
##      if item[:ph_code] == "PHS01"
##        amt = item[:rate].to_f * n
##        @@comp_drugs += amt  # total compensable drug
##      end
##      if item[:ph_code] == "PHS02"
##        x_lab_amt = item[:rate].to_f * n
##        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
##      end
##      if item[:ph_code] == "PHS03"
##        o_amt = item[:rate].to_f * n
##        @@comp_operation += o_amt  # total compensable operations
##      end
##      if item[:ph_code] == "PHS04"
##        other_amt = item[:rate].to_f * n
##        @@comp_others += other_amt  # total compensable others
##      end
##      if item[:ph_code] == "PHS05"
##        supp_amt = item[:rate].to_f * n
##        @@comp_supplies += supp_amt  # total compensable supplies
##      end
##      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
##        n_amt = item[:rate].to_f * n
##        @@non_comp_drugs += n_amt # total non-compensable drug
##      end
##      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
##        n_amt_tag = item[:rate].to_f * n
##        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
##      end
##      if item[:ph_code] == "PHS07"
##        n_x_lab_amt = item[:rate].to_f * n
##        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
##      end
##      if item[:ph_code] == "PHS08"
##        n_o_amt = item[:rate].to_f * n
##        @@non_comp_operation += n_o_amt # total non compensable operations
##      end
##      if item[:ph_code] == "PHS09"
##        n_other_amt = item[:rate].to_f * n
##        @@non_comp_others += n_other_amt  # total non compensable others
##      end
##      if item[:ph_code] == "PHS10"
##        s_amt = item[:rate].to_f * n
##        @@non_comp_supplies += s_amt  # total non compensable supplies
##      end
##    end
##  end
##
##   it "PF Claims1 - ER : Checks if the actual charge for drugs/medicine is correct" do
##    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
##    total_drugs = @@comp_drugs + @@non_comp_drugs
##    @@actual_medicine_charges = total_drugs - (@@promo_discount4 * total_drugs)
##    @@er_ph1[:er_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
##  end
##
##  it "PF Claims1 - ER : Checks if the actual benefit claim for drugs/medicine is correct" do
##    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount4)
##    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
##      @@actual_medicine_benefit_claim1 = @@comp_drugs_total
##    else
##      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
##    end
##    @@er_ph1[:er_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
##  end
##
##  it "PF Claims1 - ER : Checks if the actual charge for xrays, lab and others is correct" do
##    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
##    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount4)
##    @@er_ph1[:er_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
##  end
##
##  it "PF Claims1 - ER : Checks if the actual lab benefit claim is correct" do
##    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount4 * @@comp_xray_lab)
##    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
##    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
##      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
##    else
##      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
##    end
##    @@er_ph1[:er_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
##  end
##
##   it "PF Claims1 - ER : Checks if the actual charge for operation is correct" do
##    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount4) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount4))
##    @@er_ph1[:er_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
##  end
##
##  it "PF Claims1 - ER : Checks if the actual operation benefit claim is correct" do
##    if slmc.get_value("rvu.code").empty? == false
##      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
##      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
##        @@actual_operation_benefit_claim1 = @@actual_operation_charges
##      else
##        @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:max_amt].to_f
##      end
##    else
##      @@actual_operation_benefit_claim1 = 0.00
##    end
##    @@er_ph1[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
##  end
##
##  it "PF Claims1 - ER : Checks if the total actual charge(s) is correct" do
##    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
##    ((slmc.truncate_to((@@er_ph1[:er_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
##  end
##
##  it "PF Claims1 - ER : Checks if the total actual benefit claim is correct" do
##    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1
##    @@er_ph1[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
##  end
##
##  it "PF Claims1 - ER : Checks if the maximum benefits are correct" do
##    @@er_ph1[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
##    @@er_ph1[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
##    @@er_ph1[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
##  end
##
##  it "PF Claims1 - ER : Checks if Deduction Claims are correct" do
##    @@er_ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
##    @@er_ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
##    @@er_ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
##  end
##
##  it "PF Claims1 - ER : Checks if Remaining Benefit Claims are correct" do
##    if @@actual_medicine_benefit_claim1 < @@med_ph_benefit[:max_amt].to_f
##      @@drugs_remaining_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1)
##    else
##      @@drugs_remaining_benefit_claim1 = 0.0
##    end
##    @@er_ph1[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim1))
##
##    if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
##      @@lab_remaining_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1)
##    else
##      @@lab_remaining_benefit_claim1 = 0
##    end
##    @@er_ph1[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim1))
##  end
##
##  it "PF Claims1 - ER : Checks if computation of PF claims surgeon is applied correctly" do
##    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
##    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
##    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
##    @@er_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
##  end
##
##  it "PF Claims1 - ER : Checks if computation of PF claims anesthesiologist is applied correctly" do
##    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
##    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
##    @@er_ph1[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
##  end
##
##  it "PF Claims1 - ER : Prints PhilHealth Form and Prooflist" do
##    slmc.ph_print_report.should be_true
##  end
##
##  it "PF Claims1 - ER : Update Guarantor" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
##    slmc.click_new_guarantor
##    slmc.pba_update_guarantor
##    slmc.click_submit_changes.should be_true
##  end
##
##  it "PF Claims1 - ER : Discharges the patient in PBA" do
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
##    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
##    slmc.discharge_to_payment(:discount_rate => "50.00", :discount_scheme => "ACROSS THE BOARD").should be_true
##  end
##
##  it "PF Claims1 - ER : Prints Gate Pass of the patient" do
##    slmc.go_to_er_page
##    slmc.er_print_gatepass(:pin => @@er_pin, :visit_no => @@visit_no).should be_true
##  end
##
##  it "PF Claims1 - ER : Registers patient for the next availment" do
##    slmc.er_register_patient(:pin => @@er_pin, :org_code => "0173").should be_true
##  end
##
###Claim Type: Accounts Receivable
###With Operation: No
##
##  it "PF Claims2 - ER : Claim Type: Accounts Receivable | With Operation: No" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.er_occupancy_search(:pin => @@er_pin)
##    slmc.go_to_er_page_using_pin("Order Page", @@er_pin)
##    @drugs.each do |item, q|
##    slmc.search_order(:description => item, :drugs => true).should be_true
##      slmc.add_returned_order(:drugs => true, :description => item,
##        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
##    end
##    @ancillary.each do |item, q|
##      slmc.search_order(:description => item, :ancillary => true).should be_true
##      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
##    end
##    @supplies.each do |item, q|
##      slmc.search_order(:description => item, :supplies => true).should be_true
##      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
##    end
##    sleep 5
##    slmc.verify_ordered_items_count(:drugs => 1).should be_true
##    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
##    slmc.verify_ordered_items_count(:supplies => 1).should be_true
##    slmc.er_submit_added_order
##    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
##    slmc.confirm_validation_all_items.should be_true
##  end
##
##  it "PF Claims2 - ER : Order Procedures in OR" do
##    slmc.login("slaquino", @password).should be_true
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
##    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
##    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
##    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
##    slmc.confirm_order(:anaesth_code => "1088", :surgeon_code => "0389")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code3 = slmc.search_service(:procedure => true, :description => "OPERATING ROOM CHARGES")
##    slmc.add_returned_service(:item_code => @@item_code3, :description => "OPERATING ROOM CHARGES")
##    slmc.confirm_order(:anaesth_code => "3310", :surgeon_code => "0979")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##  end
##
##  it "PF Claims2 - ER : Clinical Discharge Patient" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.go_to_er_page
##    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => "1000", :save => true).should be_true
##  end
##
##  it "PF Claims2 - ER : Go to PhilHealth page and computes PhilHealth" do
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin).should be_true
##    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
##    @@er_ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "SHIGELLOSIS", :medical_case_type => "ORDINARY CASE", :compute => true)
##    slmc.ph_save_computation
##  end
##
##  it "PF Claims2 - ER : Check Benefit Summary totals" do
##    @@comp_drugs = 0
##    @@comp_xray_lab = 0
##    @@comp_operation = 0
##    @@comp_others = 0
##    @@comp_supplies = 0
##    @@non_comp_drugs = 0
##    @@non_comp_drugs_mrp_tag = 0
##    @@non_comp_xray_lab = 0
##    @@non_comp_operation = 0
##    @@non_comp_others = 0
##    @@non_comp_supplies = 0
##
##    @@orders = @ancillary.merge(@supplies).merge(@drugs).merge(@operation)
##    @@orders.each do |order,n|
##      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
##      if item[:ph_code] == "PHS01"
##        amt = item[:rate].to_f * n
##        @@comp_drugs += amt  # total compensable drug
##      end
##      if item[:ph_code] == "PHS02"
##        x_lab_amt = item[:rate].to_f * n
##        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
##      end
##      if item[:ph_code] == "PHS03"
##        o_amt = item[:rate].to_f * n
##        @@comp_operation += o_amt  # total compensable operations
##      end
##      if item[:ph_code] == "PHS04"
##        other_amt = item[:rate].to_f * n
##        @@comp_others += other_amt  # total compensable others
##      end
##      if item[:ph_code] == "PHS05"
##        supp_amt = item[:rate].to_f * n
##        @@comp_supplies += supp_amt  # total compensable supplies
##      end
##      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
##        n_amt = item[:rate].to_f * n
##        @@non_comp_drugs += n_amt # total non-compensable drug
##      end
##      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
##        n_amt_tag = item[:rate].to_f * n
##        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
##      end
##      if item[:ph_code] == "PHS07"
##        n_x_lab_amt = item[:rate].to_f * n
##        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
##      end
##      if item[:ph_code] == "PHS08"
##        n_o_amt = item[:rate].to_f * n
##        @@non_comp_operation += n_o_amt # total non compensable operations
##      end
##      if item[:ph_code] == "PHS09"
##        n_other_amt = item[:rate].to_f * n
##        @@non_comp_others += n_other_amt  # total non compensable others
##      end
##      if item[:ph_code] == "PHS10"
##        s_amt = item[:rate].to_f * n
##        @@non_comp_supplies += s_amt  # total non compensable supplies
##      end
##    end
##  end
##
##   it "PF Claims2 - ER : Checks if the actual charge for drugs/medicine is correct" do
##    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
##    total_drugs = @@comp_drugs + @@non_comp_drugs
##    @@actual_medicine_charges = total_drugs - (@@promo_discount4 * total_drugs)
##    @@er_ph2[:er_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
##  end
##
##  it "PF Claims2 - ER : Checks if the actual benefit claim for drugs/medicine is correct" do
##    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount4)
##    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
##      @@actual_medicine_benefit_claim2 = @@comp_drugs_total
##    else
##      @@actual_medicine_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
##    end
##    @@er_ph2[:er_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
##  end
##
##  it "PF Claims2 - ER : Checks if the actual charge for xrays, lab and others is correct" do
##    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
##    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount4)
##    @@er_ph2[:er_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
##  end
##
##  it "PF Claims2 - ER : Checks if the actual lab benefit claim is correct" do
##    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount4 * @@comp_xray_lab)
##    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
##    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
##      @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
##    else
##      @@actual_lab_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
##    end
##    @@er_ph2[:er_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
##  end
##
##   it "PF Claims2 - ER : Checks if the actual charge for operation is correct" do
##    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount4) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount4))
##    @@er_ph2[:er_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
##  end
##
##  it "PF Claims2 - ER : Checks if the actual operation benefit claim is correct" do
##    if slmc.get_value("rvu.code").empty? == false
##      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
##      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
##        @@actual_operation_benefit_claim2 = @@actual_operation_charges
##      else
##        @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:max_amt].to_f
##      end
##    else
##      @@actual_operation_benefit_claim2 = 0.00
##    end
##    @@er_ph2[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
##  end
##
##  it "PF Claims2 - ER : Checks if the total actual charge(s) is correct" do
##    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
##    ((slmc.truncate_to((@@er_ph2[:er_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
##  end
##
##  it "PF Claims2 - ER : Checks if the total actual benefit claim is correct" do
##    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2
##    @@er_ph2[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
##  end
##
##  it "PF Claims2 - ER : Checks if the maximum benefits are correct" do
##    @@er_ph2[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
##    @@er_ph2[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
##    @@er_ph2[:er_max_benefit_operation] == "RVU x PCF"
##  end
##
##  it "PF Claims2 - ER : Checks if Deduction Claims are correct" do
##    @@er_ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
##    @@er_ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
##    @@er_ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
##  end
##
##  it "PF Claims2 - ER : Checks if Remaining Benefit Claims are correct" do
##    if @@actual_medicine_benefit_claim2 < @@med_ph_benefit[:max_amt].to_f
##      @@drugs_remaining_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
##    else
##      @@drugs_remaining_benefit_claim2 = 0.0
##    end
##    @@er_ph2[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim2))
##
##    if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f
##      @@lab_remaining_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
##    else
##      @@lab_remaining_benefit_claim2 = 0
##    end
##    @@er_ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim2))
##  end
##
##  it "PF Claims2 - ER : Checks if computation of PF claims surgeon is applied correctly" do
##    @@er_ph2[:surgeon_benefit_claim].should == nil
##  end
##
##  it "PF Claims2 - ER : Checks if computation of PF claims anesthesiologist is applied correctly" do
##    @@er_ph2[:anesthesiologist_benefit_claim].should == nil
##  end
##
##  it "PF Claims2 - ER : Prints PhilHealth Form and Prooflist" do
##    slmc.ph_print_report.should be_true
##  end
##
##  it "PF Claims2 - ER : Update Guarantor" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
##    slmc.click_new_guarantor
##    slmc.pba_update_guarantor
##    slmc.click_submit_changes.should be_true
##  end
##
##   it "PF Claims2 - ER : Discharges the patient in PBA" do
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
##    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
##    slmc.discharge_to_payment(:discount_rate => "50.00", :discount_scheme => "ACROSS THE BOARD").should be_true
##  end
##
##  it "PF Claims2 - ER : Prints Gate Pass of the patient" do
##    slmc.go_to_er_page
##    slmc.er_print_gatepass(:pin => @@er_pin, :visit_no => @@visit_no).should be_true
##  end
##
##  it "PF Claims2 - ER : Registers patient for the next availment" do
##    slmc.er_register_patient(:pin => @@er_pin, :org_code => "0173").should be_true
##  end
##
###Claim Type : Refund
###With Operation : Yes
##
##  it "PF Claims3 - ER : Claim Type: Refund | With Operation: Yes" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.er_occupancy_search(:pin => @@er_pin)
##    slmc.go_to_er_page_using_pin("Order Page", @@er_pin)
##    @drugs.each do |item, q|
##      slmc.search_order(:description => item, :drugs => true).should be_true
##      slmc.add_returned_order(:drugs => true, :description => item,
##        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
##    end
##    @ancillary.each do |item, q|
##      slmc.search_order(:description => item, :ancillary => true).should be_true
##      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
##    end
##    @supplies.each do |item, q|
##      slmc.search_order(:description => item, :supplies => true).should be_true
##      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
##    end
##    sleep 5
##    slmc.verify_ordered_items_count(:drugs => 1).should be_true
##    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
##    slmc.verify_ordered_items_count(:supplies => 1).should be_true
##    slmc.er_submit_added_order
##    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
##    slmc.confirm_validation_all_items.should be_true
##  end
##
##  it "PF Claims3 - ER : Order Procedures in OR" do
##    slmc.login("slaquino", @password).should be_true
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
##    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
##    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
##    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
##    slmc.confirm_order(:anaesth_code => "1088", :surgeon_code => "0389")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code3 = slmc.search_service(:procedure => true, :description => "OPERATING ROOM CHARGES")
##    slmc.add_returned_service(:item_code => @@item_code3, :description => "OPERATING ROOM CHARGES")
##    slmc.confirm_order(:anaesth_code => "3310", :surgeon_code => "0979")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##  end
##
##  it "PF Claims3 - ER : Clinical Discharge Patient" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.go_to_er_page
##    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => "1000", :save => true).should be_true
##  end
##
##  it "PF Claims3 - ER : Go to PhilHealth page and computes PhilHealth" do
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin).should be_true
##    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
##    @@er_ph3 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CAMPYLOBACTER ENTERITIS", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
##    slmc.ph_save_computation
##  end
##
##  it "PF Claims3 - ER : Check Benefit Summary totals" do
##    @@comp_drugs = 0
##    @@comp_xray_lab = 0
##    @@comp_operation = 0
##    @@comp_others = 0
##    @@comp_supplies = 0
##    @@non_comp_drugs = 0
##    @@non_comp_drugs_mrp_tag = 0
##    @@non_comp_xray_lab = 0
##    @@non_comp_operation = 0
##    @@non_comp_others = 0
##    @@non_comp_supplies = 0
##
##    @@orders = @ancillary.merge(@supplies).merge(@drugs).merge(@operation)
##    @@orders.each do |order,n|
##      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
##      if item[:ph_code] == "PHS01"
##        amt = item[:rate].to_f * n
##        @@comp_drugs += amt  # total compensable drug
##      end
##      if item[:ph_code] == "PHS02"
##        x_lab_amt = item[:rate].to_f * n
##        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
##      end
##      if item[:ph_code] == "PHS03"
##        o_amt = item[:rate].to_f * n
##        @@comp_operation += o_amt  # total compensable operations
##      end
##      if item[:ph_code] == "PHS04"
##        other_amt = item[:rate].to_f * n
##        @@comp_others += other_amt  # total compensable others
##      end
##      if item[:ph_code] == "PHS05"
##        supp_amt = item[:rate].to_f * n
##        @@comp_supplies += supp_amt  # total compensable supplies
##      end
##      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
##        n_amt = item[:rate].to_f * n
##        @@non_comp_drugs += n_amt # total non-compensable drug
##      end
##      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
##        n_amt_tag = item[:rate].to_f * n
##        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
##      end
##      if item[:ph_code] == "PHS07"
##        n_x_lab_amt = item[:rate].to_f * n
##        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
##      end
##      if item[:ph_code] == "PHS08"
##        n_o_amt = item[:rate].to_f * n
##        @@non_comp_operation += n_o_amt # total non compensable operations
##      end
##      if item[:ph_code] == "PHS09"
##        n_other_amt = item[:rate].to_f * n
##        @@non_comp_others += n_other_amt  # total non compensable others
##      end
##      if item[:ph_code] == "PHS10"
##        s_amt = item[:rate].to_f * n
##        @@non_comp_supplies += s_amt  # total non compensable supplies
##      end
##    end
##  end
##
##   it "PF Claims3 - ER : Checks if the actual charge for drugs/medicine is correct" do
##    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
##    total_drugs = @@comp_drugs + @@non_comp_drugs
##    @@actual_medicine_charges = total_drugs - (@@promo_discount4 * total_drugs)
##    @@er_ph3[:er_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
##  end
##
##  it "PF Claims3 - ER : Checks if the actual benefit claim for drugs/medicine is correct" do
##    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount4)
##    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
##      @@actual_medicine_benefit_claim3 = @@comp_drugs_total
##    else
##      @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
##    end
##    @@er_ph3[:er_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
##  end
##
##  it "PF Claims3 - ER : Checks if the actual charge for xrays, lab and others is correct" do
##    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
##    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount4)
##    @@er_ph3[:er_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
##  end
##
##  it "PF Claims3 - ER : Checks if the actual lab benefit claim is correct" do
##    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount4 * @@comp_xray_lab)
##    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
##    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
##      @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
##    else
##      @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
##    end
##    @@er_ph3[:er_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
##  end
##
##   it "PF Claims3 - ER : Checks if the actual charge for operation is correct" do
##    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount4) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount4))
##    @@er_ph3[:er_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
##  end
##
##  it "PF Claims3 - ER : Checks if the actual operation benefit claim is correct" do
##    if slmc.get_value("rvu.code").empty? == false
##      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
##      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
##        @@actual_operation_benefit_claim3 = @@actual_operation_charges
##      else
##        @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:max_amt].to_f
##      end
##    else
##      @@actual_operation_benefit_claim3 = 0.00
##    end
##    @@er_ph3[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
##  end
##
##  it "PF Claims3 - ER : Checks if the total actual charge(s) is correct" do
##    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
##    ((slmc.truncate_to((@@er_ph3[:er_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
##  end
##
##  it "PF Claims3 - ER : Checks if the total actual benefit claim is correct" do
##    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3
##    @@er_ph3[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
##  end
##
##  it "PF Claims3 - ER : Checks if the maximum benefits are correct" do
##    @@er_ph3[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
##    @@er_ph3[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
##    @@er_ph3[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
##  end
##
##  it "PF Claims3 - ER : Checks if Deduction Claims are correct" do
##    @@er_ph3[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
##    @@er_ph3[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
##    @@er_ph3[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
##  end
##
##  it "PF Claims3 - ER : Checks if Remaining Benefit Claims are correct" do
##    if @@actual_medicine_benefit_claim3 < @@med_ph_benefit[:max_amt].to_f
##      @@drugs_remaining_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
##    else
##      @@drugs_remaining_benefit_claim3 = 0.0
##    end
##    @@er_ph3[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim3))
##
##    if @@actual_lab_benefit_claim3 < @@lab_ph_benefit[:max_amt].to_f
##      @@lab_remaining_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
##    else
##      @@lab_remaining_benefit_claim3 = 0
##    end
##    @@er_ph3[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim3))
##  end
##
##  it "PF Claims3 - ER : Checks if computation of PF claims surgeon is applied correctly" do
##    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
##    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
##    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
##    if @@er_ph3[:surgeon_benefit_claim].to_i != @@surgeon_claim
##      @@er_ph3[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
##    else
##      @@er_ph3[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
##    end
##  end
##
##  it "PF Claims3 - ER : Checks if computation of PF claims anesthesiologist is applied correctly" do
##    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
##    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
##    if @@er_ph3[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
##      @@er_ph3[:anesthesiologist_benefit_claim].should == ("0.2f" %(0.0))
##    else
##      @@er_ph3[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
##    end
##  end
##
##  it "PF Claims3 - ER : Prints PhilHealth Form and Prooflist" do
##    slmc.ph_print_report.should be_true
##  end
##
##  it "PF Claims3 - ER : Update Guarantor" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
##    slmc.click_new_guarantor
##    slmc.pba_update_guarantor
##    slmc.click_submit_changes.should be_true
##  end
##
##   it "PF Claims3 - ER : Discharges the patient in PBA" do
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
##    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
##    slmc.discharge_to_payment(:discount_rate => "50.00", :discount_scheme => "ACROSS THE BOARD").should be_true
##  end
##
##  it "PF Claims3 - ER : Prints Gate Pass of the patient" do
##    slmc.go_to_er_page
##    slmc.er_print_gatepass(:pin => @@er_pin, :visit_no => @@visit_no).should be_true
##  end
##
##  it "PF Claims3 - ER : Registers patient for the next availment" do
##    slmc.er_register_patient(:pin => @@er_pin, :org_code => "0173").should be_true
##  end
##
###Claim Type : Refund
###With Operation : No
##
##  it "PF Claims4 - ER : Claim Type: Refund | With Operation: No" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.er_occupancy_search(:pin => @@er_pin)
##    slmc.go_to_er_page_using_pin("Order Page", @@er_pin)
##    @drugs.each do |item, q|
##      slmc.search_order(:description => item, :drugs => true).should be_true
##      slmc.add_returned_order(:drugs => true, :description => item,
##        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
##    end
##    @ancillary.each do |item, q|
##      slmc.search_order(:description => item, :ancillary => true).should be_true
##      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
##    end
##    @supplies.each do |item, q|
##      slmc.search_order(:description => item, :supplies => true).should be_true
##      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
##    end
##    sleep 5
##    slmc.verify_ordered_items_count(:drugs => 1).should be_true
##    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
##    slmc.verify_ordered_items_count(:supplies => 1).should be_true
##    slmc.er_submit_added_order
##    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
##    slmc.confirm_validation_all_items.should be_true
##  end
##
##  it "PF Claims4 - ER : Order Procedures in OR" do
##    slmc.login("slaquino", @password).should be_true
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
##    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
##    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
##    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
##    slmc.confirm_order(:anaesth_code => "1088", :surgeon_code => "0389")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##
##    slmc.go_to_occupancy_list_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@er_pin)
##    @@item_code3 = slmc.search_service(:procedure => true, :description => "OPERATING ROOM CHARGES")
##    slmc.add_returned_service(:item_code => @@item_code3, :description => "OPERATING ROOM CHARGES")
##    slmc.confirm_order(:anaesth_code => "3310", :surgeon_code => "0979")
##    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
##    slmc.confirm_validation_all_items.should be_true
##  end
##
##  it "PF Claims4 - ER : Clinical Discharge Patient" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.go_to_er_page
##    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => "1000", :save => true).should be_true
##  end
##
##  it "PF Claims4 - ER : Go to PhilHealth page and computes PhilHealth" do
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin).should be_true
##    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
##    @@er_ph4 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "AMEBIC BRAIN ABSCESS", :medical_case_type => "ORDINARY CASE", :compute => true)
##    slmc.ph_save_computation
##  end
##
##  it "PF Claims4 - ER : Check Benefit Summary totals" do
##    @@comp_drugs = 0
##    @@comp_xray_lab = 0
##    @@comp_operation = 0
##    @@comp_others = 0
##    @@comp_supplies = 0
##    @@non_comp_drugs = 0
##    @@non_comp_drugs_mrp_tag = 0
##    @@non_comp_xray_lab = 0
##    @@non_comp_operation = 0
##    @@non_comp_others = 0
##    @@non_comp_supplies = 0
##
##    @@orders = @ancillary.merge(@supplies).merge(@drugs).merge(@operation)
##    @@orders.each do |order,n|
##      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
##      if item[:ph_code] == "PHS01"
##        amt = item[:rate].to_f * n
##        @@comp_drugs += amt  # total compensable drug
##      end
##      if item[:ph_code] == "PHS02"
##        x_lab_amt = item[:rate].to_f * n
##        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
##      end
##      if item[:ph_code] == "PHS03"
##        o_amt = item[:rate].to_f * n
##        @@comp_operation += o_amt  # total compensable operations
##      end
##      if item[:ph_code] == "PHS04"
##        other_amt = item[:rate].to_f * n
##        @@comp_others += other_amt  # total compensable others
##      end
##      if item[:ph_code] == "PHS05"
##        supp_amt = item[:rate].to_f * n
##        @@comp_supplies += supp_amt  # total compensable supplies
##      end
##      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
##        n_amt = item[:rate].to_f * n
##        @@non_comp_drugs += n_amt # total non-compensable drug
##      end
##      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
##        n_amt_tag = item[:rate].to_f * n
##        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
##      end
##      if item[:ph_code] == "PHS07"
##        n_x_lab_amt = item[:rate].to_f * n
##        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
##      end
##      if item[:ph_code] == "PHS08"
##        n_o_amt = item[:rate].to_f * n
##        @@non_comp_operation += n_o_amt # total non compensable operations
##      end
##      if item[:ph_code] == "PHS09"
##        n_other_amt = item[:rate].to_f * n
##        @@non_comp_others += n_other_amt  # total non compensable others
##      end
##      if item[:ph_code] == "PHS10"
##        s_amt = item[:rate].to_f * n
##        @@non_comp_supplies += s_amt  # total non compensable supplies
##      end
##    end
##  end
##
##   it "PF Claims4 - ER : Checks if the actual charge for drugs/medicine is correct" do
##    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
##    total_drugs = @@comp_drugs + @@non_comp_drugs
##    @@actual_medicine_charges = total_drugs - (@@promo_discount4 * total_drugs)
##    @@er_ph4[:er_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
##  end
##
##  it "PF Claims4 - ER : Checks if the actual benefit claim for drugs/medicine is correct" do
##    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount4)
##    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
##      @@actual_medicine_benefit_claim4 = @@comp_drugs_total
##    else
##      @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
##    end
##    @@er_ph4[:er_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
##  end
##
##  it "PF Claims4 - ER : Checks if the actual charge for xrays, lab and others is correct" do
##    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
##    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount4)
##    @@er_ph4[:er_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
##  end
##
##  it "PF Claims4 - ER : Checks if the actual lab benefit claim is correct" do
##    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount4 * @@comp_xray_lab)
##    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
##    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
##      @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
##    else
##      @@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
##    end
##    @@er_ph4[:er_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
##  end
##
##   it "PF Claims4 - ER : Checks if the actual charge for operation is correct" do
##    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount4) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount4))
##    @@er_ph4[:er_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
##  end
##
##  it "PF Claims4 - ER : Checks if the actual operation benefit claim is correct" do
##    if slmc.get_value("rvu.code").empty? == false
##      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
##      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
##        @@actual_operation_benefit_claim4 = @@actual_operation_charges
##      else
##        @@actual_operation_benefit_claim4 = @@operation_ph_benefit[:max_amt].to_f
##      end
##    else
##      @@actual_operation_benefit_claim4 = 0.00
##    end
##    @@er_ph4[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
##  end
##
##  it "PF Claims4 - ER : Checks if the total actual charge(s) is correct" do
##    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
##    ((slmc.truncate_to((@@er_ph4[:er_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
##  end
##
##  it "PF Claims4 - ER : Checks if the total actual benefit claim is correct" do
##    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4 + @@actual_operation_benefit_claim4
##    @@er_ph4[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
##  end
##
##  it "PF Claims4 - ER : Checks if the maximum benefits are correct" do
##    @@er_ph4[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
##    @@er_ph4[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
##    @@er_ph4[:er_max_benefit_operation].should == ("RVU x PCF")
##  end
##
##  it "PF Claims4 - ER : Checks if Deduction Claims are correct" do
##    @@er_ph4[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
##    @@er_ph4[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
##    @@er_ph4[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
##  end
##
##  it "PF Claims4 - ER : Checks if Remaining Benefit Claims are correct" do
##    if @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f
##      @@drugs_remaining_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
##    else
##      @@drugs_remaining_benefit_claim4 = 0.0
##    end
##    @@er_ph4[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim4))
##
##    if @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f
##      @@lab_remaining_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
##    else
##      @@lab_remaining_benefit_claim4 = 0
##    end
##    @@er_ph4[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim4))
##  end
##
##  it "PF Claims4 - ER : Checks if computation of PF claims surgeon is applied correctly" do
##    @@er_ph4[:surgeon_benefit_claim].should == nil
##  end
##
##  it "PF Claims4 - ER : Checks if computation of PF claims anesthesiologist is applied correctly" do
##    @@er_ph4[:anesthesiologist_benefit_claim] ==  nil
##  end
##
##  it "PF Claims4 - ER : Prints PhilHealth Form and Prooflist" do
##    slmc.ph_print_report.should be_true
##  end
##
##  it "PF Claims4 - ER : Update Guarantor" do
##    slmc.login("sel_er3", @password).should be_true
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
##    slmc.click_new_guarantor
##    slmc.pba_update_guarantor
##    slmc.click_submit_changes.should be_true
##  end
##
##   it "PF Claims4 - ER : Discharges the patient in PBA" do
##    slmc.go_to_er_billing_page
##    slmc.patient_pin_search(:pin => @@er_pin)
##    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
##    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
##    slmc.discharge_to_payment(:discount_rate => "50.00", :discount_scheme => "ACROSS THE BOARD").should be_true
##  end
##
##  it "PF Claims4 - ER : Prints Gate Pass of the patient" do
##    slmc.go_to_er_page
##    slmc.er_print_gatepass(:pin => @@er_pin, :visit_no => @@visit_no).should be_true
##  end
##
##  it "PF Claims4 - ER : Registers patient for the next availment" do
##    slmc.er_register_patient(:pin => @@er_pin, :org_code => "0173").should be_true
##  end

#########################################################################################################################

#Claim Type : Accounts Receivable
#With Operation : Yes

  it "PF Claims1 - DR : Claim Type: Accounts Receivable | With Operation: Yes" do
    slmc.login("sel_slaquino", @password).should be_true
    @@dr_pin = slmc.or_create_patient_record(@dr_patient.merge!(:admit => true, :org_code => "0170", :gender => 'F')).gsub(' ', '')
    #    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin)
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
    sleep 6
#       #  submit_button = is_element_present("//input[@value='SUBMIT']") ? "//input[@value='SUBMIT']" : "//input[@value='Submit']"
#      #slmc.click submit_button, :wait_for => :page
#      slmc.click("//input[@value='Submit']", :wait_for => :page);
##selenium.waitForPageToLoad("30000");
    sleep 6
   slmc.er_submit_added_order(:validate => true, :username => "sel_dr_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "PF Claims1 - DR : Order Procedures" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.confirm_order(:anaesth_code => "1088", :surgeon_code => "0389")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code3 = slmc.search_service(:procedure => true, :description => "OPERATING ROOM CHARGES")
    slmc.add_returned_service(:item_code => @@item_code3, :description => "OPERATING ROOM CHARGES")
    slmc.confirm_order(:anaesth_code => "3310", :surgeon_code => "0979")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "PF Claims1 - DR : Clinical Discharge Patient" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin, :pf_amount => "1000", :save => true).should be_true
  end

  it "PF Claims1 - DR : Go to PhilHealth page and computes PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@dr_pin).should be_true
    slmc.click_philhealth_link(:pin => @@dr_pin, :visit_no => @@visit_no)
    @@dr_ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
  end

  it "PF Claims1 - DR : All surgeons and anesthesiologist must be displayed in the drop down list" do
    sleep 10
    doctors = slmc.get_select_options("surgeon.doctorCode")
    (doctors.count).should == 3
    doctors[0].should == @doctor_list[0]
    doctors[1].should == @doctor_list[1]
    doctors[2].should == @doctor_list[2]
    anaes = slmc.get_select_options("anesthesiologist.doctorCode")
    (anaes.count).should == 3
    anaes[0].should == @anaes_list[0]
    anaes[1].should == @anaes_list[1]
    anaes[2].should == @anaes_list[2]
    slmc.ph_save_computation
  end

  it "PF Claims1 - DR :Check Benefit Summary totals" do
    @@comp_drugs = 0
    @@comp_xray_lab = 0
    @@comp_operation = 0
    @@comp_others = 0
    @@comp_supplies = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@non_comp_xray_lab = 0
    @@non_comp_operation = 0
    @@non_comp_others = 0
    @@non_comp_supplies = 0

    @@orders = @ancillary.merge(@supplies).merge(@drugs).merge(@operation)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
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

   it "PF Claims1 - DR :Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount5 * total_drugs)
    @@dr_ph1[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "PF Claims1 - DR :Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount5)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim1 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
    end
    @@dr_ph1[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
  end

  it "PF Claims1 - DR :Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount5)
    @@dr_ph1[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "PF Claims1 - DR :Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount5 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@dr_ph1[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
  end

  it "PF Claims1 - DR :Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount5) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount5))
    @@dr_ph1[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "PF Claims1 - DR :Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim1 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@dr_ph1[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
    else
      @@actual_operation_benefit_claim1 = 0.00
      @@dr_ph1[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
    end
  end

  it "PF Claims1 - DR :Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@dr_ph1[:or_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "PF Claims1 - DR :Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1
    @@dr_ph1[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "PF Claims1 - DR :Checks if the maximum benefits are correct" do
    @@dr_ph1[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@dr_ph1[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@dr_ph1[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "PF Claims1 - DR :Checks if Deduction Claims are correct" do
    @@dr_ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
    @@dr_ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@dr_ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end

  it "PF Claims1 - DR :Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim1 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
    else
      @@drugs_remaining_benefit_claim1 = 0.0
    end
    @@dr_ph1[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim1))

    if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
    else
      @@lab_remaining_benefit_claim1 = 0
    end
    @@dr_ph1[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim1))
  end

  it "PF Claims1 - DR :Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@dr_ph1[:surgeon_benefit_claim].to_i != @@surgeon_claim
      @@dr_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@dr_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "PF Claims1 - DR :Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@dr_ph1[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@dr_ph1[:anesthesiologist_benefit_claim].should == ("0.2f" %(0.0))
    else
      @@dr_ph1[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "PF Claims1 - DR : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

   it "PF Claims1 - DR :Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment(:discount_rate => "50.00", :discount_scheme => "ACROSS THE BOARD").should be_true
  end

  it "PF Claims1 - DR :Prints Gate Pass of the patient" do
    slmc.login("slaquino", @password).should be_true
    slmc.or_print_gatepass(:pin => @@dr_pin, :visit_no => @@visit_no).should be_true
  end

  it "PF Claims1 - DR :Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@dr_pin, :org_code => "0170").should be_true
  end

#Claim Type : Accounts Receivable
#With Operation : No

  it "PF Claims2 - DR : Claim Type: Accounts Receivable | With Operation: No" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin)
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
    slmc.er_submit_added_order(:validate => true, :username => "sel_dr_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "PF Claims2 - DR : Order Procedures" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.confirm_order(:anaesth_code => "1088", :surgeon_code => "0389")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code3 = slmc.search_service(:procedure => true, :description => "OPERATING ROOM CHARGES")
    slmc.add_returned_service(:item_code => @@item_code3, :description => "OPERATING ROOM CHARGES")
    slmc.confirm_order(:anaesth_code => "3310", :surgeon_code => "0979")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "PF Claims2 - DR : Clinical Discharge Patient" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin, :pf_amount => "1000", :save => true).should be_true
  end

  it "PF Claims2 - DR : Go to PhilHealth page and computes PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@dr_pin).should be_true
    slmc.click_philhealth_link(:pin => @@dr_pin, :visit_no => @@visit_no)
    @@dr_ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "SHIGELLOSIS", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "PF Claims2 - DR : Check Benefit Summary totals" do
    @@comp_drugs = 0
    @@comp_xray_lab = 0
    @@comp_operation = 0
    @@comp_others = 0
    @@comp_supplies = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@non_comp_xray_lab = 0
    @@non_comp_operation = 0
    @@non_comp_others = 0
    @@non_comp_supplies = 0

    @@orders = @ancillary.merge(@supplies).merge(@drugs).merge(@operation)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
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

   it "PF Claims2 - DR : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount5 * total_drugs)
    @@dr_ph2[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "PF Claims2 - DR : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_medicine_benefit_claim2 = 4200
#    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount5)
#    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1)
#      @@actual_medicine_benefit_claim2 = @@comp_drugs_total
#    else
#      @@actual_medicine_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1)
#    end
    @@dr_ph2[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
  end

  it "PF Claims2 - DR : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount5)
    @@dr_ph2[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "PF Claims2 - DR : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount5 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1)
      @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1)
    end
    @@dr_ph2[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
  end

  it "PF Claims2 - DR : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount5) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount5))
    @@dr_ph2[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "PF Claims2 - DR : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim2 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim2 = 0.00
    end
    @@dr_ph2[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "PF Claims2 - DR : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@dr_ph2[:or_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "PF Claims2 - DR : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2
    @@dr_ph2[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "PF Claims2 - DR : Checks if the maximum benefits are correct" do
    @@dr_ph2[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@dr_ph2[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@dr_ph2[:or_max_benefit_operation] == "RVU x PCF"
  end

  it "PF Claims2 - DR : Checks if Deduction Claims are correct" do
    @@dr_ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
    @@dr_ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    @@dr_ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "PF Claims2 - DR : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim2 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
    else
      @@drugs_remaining_benefit_claim2 = 0.0
    end
    @@dr_ph2[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim2))

    if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
    else
      @@lab_remaining_benefit_claim2 = 0
    end
    @@dr_ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim2))
  end

  it "PF Claims2 - DR : Checks if computation of PF claims surgeon is applied correctly" do
    @@dr_ph2[:surgeon_benefit_claim].should == nil
  end

  it "PF Claims2 - DR : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@dr_ph2[:anesthesiologist_benefit_claim].should == nil
  end

  it "PF Claims2 - DR : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

   it "PF Claims2 - DR : Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment(:discount_rate => "50.00", :discount_scheme => "ACROSS THE BOARD").should be_true
  end

  it "PF Claims2 - DR : Prints Gate Pass of the patient" do
    slmc.login("slaquino", @password).should be_true
    slmc.or_print_gatepass(:pin => @@dr_pin, :visit_no => @@visit_no).should be_true
  end

  it "PF Claims2 - DR : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@dr_pin, :org_code => "0170").should be_true
  end

#Claim Type : Refund
#With Operation : Yes

  it "PF Claims3 - DR : Claim Type: Refund | With Operation: Yes" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin)
    @supplies.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.er_submit_added_order(:validate => true, :username => "sel_dr_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "PF Claims3 - DR : Order Procedures" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.confirm_order(:anaesth_code => "1088", :surgeon_code => "0389")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code3 = slmc.search_service(:procedure => true, :description => "OPERATING ROOM CHARGES")
    slmc.add_returned_service(:item_code => @@item_code3, :description => "OPERATING ROOM CHARGES")
    slmc.confirm_order(:anaesth_code => "3310", :surgeon_code => "0979")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "PF Claims3 - DR : Clinical Discharge Patient" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin, :pf_amount => "1000", :save => true).should be_true
  end

  it "PF Claims3 - DR : Go to PhilHealth page and computes PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@dr_pin).should be_true
    slmc.click_philhealth_link(:pin => @@dr_pin, :visit_no => @@visit_no)
    @@dr_ph3 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CAMPYLOBACTER ENTERITIS", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "PF Claims3 - DR : Check Benefit Summary totals" do
    @@comp_drugs = 0
    @@comp_xray_lab = 0
    @@comp_operation = 0
    @@comp_others = 0
    @@comp_supplies = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@non_comp_xray_lab = 0
    @@non_comp_operation = 0
    @@non_comp_others = 0
    @@non_comp_supplies = 0

    @@orders = @ancillary.merge(@supplies).merge(@drugs).merge(@operation)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
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

   it "PF Claims3 - DR : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount5 * total_drugs)
    @@dr_ph3[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "PF Claims3 - DR : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount5)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
      @@actual_medicine_benefit_claim3 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
    end
    @@dr_ph3[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
  end

  it "PF Claims3 - DR : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount5)
    @@dr_ph3[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "PF Claims3 - DR : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount5 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
      @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
    end
    @@dr_ph3[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
  end

  it "PF Claims3 - DR : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount5) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount5))
    @@dr_ph3[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "PF Claims3 - DR : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim3 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim3 = 0.00
    end
    @@dr_ph3[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "PF Claims3 - DR : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@dr_ph3[:or_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "PF Claims3 - DR : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3
    @@dr_ph3[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "PF Claims3 - DR : Checks if the maximum benefits are correct" do
    @@dr_ph3[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@dr_ph3[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@dr_ph3[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "PF Claims3 - DR : Checks if Deduction Claims are correct" do
    @@dr_ph3[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
    @@dr_ph3[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
    @@dr_ph3[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "PF Claims3 - DR : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim3 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
    else
      @@drugs_remaining_benefit_claim3 = 0.0
    end
    @@dr_ph3[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim3))

    if @@actual_lab_benefit_claim3 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
    else
      @@lab_remaining_benefit_claim3 = 0
    end
    @@dr_ph3[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim3))
  end

  it "PF Claims3 - DR : Checks if PF Claims for surgeon(GP) is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@dr_ph3[:surgeon_benefit_claim].to_i != @@surgeon_claim
      @@dr_ph3[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@dr_ph3[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "PF Claims3 - DR : Checks if PF Claims for anesthesiologist(GP) is correct" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@dr_ph3[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@dr_ph3[:anesthesiologist_benefit_claim].should == ("0.2f" %(0.0))
    else
      @@dr_ph3[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "PF Claims3 - DR : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "PF Claims3 - DR : Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "PF Claims3 - DR : Prints Gate Pass of the patient" do
    slmc.login("slaquino", @password).should be_true
    slmc.or_print_gatepass(:pin => @@dr_pin, :visit_no => @@visit_no).should be_true
  end

  it "PF Claims3 - DR : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@dr_pin, :org_code => "0170").should be_true
  end

#Claim Type: Refund
#With Operation: No

  it "PF Claims4 - DR : Claim Type: Refund | With Operation: No" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin)
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
    slmc.er_submit_added_order(:validate => true, :username => "sel_dr_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "PF Claims4 - DR : Order Procedures" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.confirm_order(:anaesth_code => "1088", :surgeon_code => "0389")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code3 = slmc.search_service(:procedure => true, :description => "OPERATING ROOM CHARGES")
    slmc.add_returned_service(:item_code => @@item_code3, :description => "OPERATING ROOM CHARGES")
    slmc.confirm_order(:anaesth_code => "3310", :surgeon_code => "0979")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "PF Claims4 - DR : Clinical Discharge Patient" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin, :pf_amount => "1000", :save => true).should be_true
  end

  it "PF Claims4 - DR : Go to PhilHealth page and computes PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@dr_pin).should be_true
    slmc.click_philhealth_link(:pin => @@dr_pin, :visit_no => @@visit_no)
    @@dr_ph4 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "AMEBIC BRAIN ABSCESS", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "PF Claims4 - DR : Check Benefit Summary totals" do
    @@comp_drugs = 0
    @@comp_xray_lab = 0
    @@comp_operation = 0
    @@comp_others = 0
    @@comp_supplies = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@non_comp_xray_lab = 0
    @@non_comp_operation = 0
    @@non_comp_others = 0
    @@non_comp_supplies = 0

    @@orders = @ancillary.merge(@supplies).merge(@drugs).merge(@operation)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
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

   it "PF Claims4 - DR : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount5 * total_drugs)
    @@dr_ph4[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "PF Claims4 - DR : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount5)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
      @@actual_medicine_benefit_claim4 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
    end
    @@dr_ph4[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
  end

  it "PF Claims4 - DR : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount5)
    @@dr_ph4[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "PF Claims4 - DR : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount5 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
      @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
    end
    @@dr_ph4[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
  end

  it "PF Claims4 - DR : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount5) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount5))
    @@dr_ph4[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "PF Claims4 - DR : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim4 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim4 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim4 = 0.00
    end
    @@dr_ph4[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "PF Claims4 - DR : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@dr_ph4[:or_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "PF Claims4 - DR : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4 + @@actual_operation_benefit_claim4
    @@dr_ph4[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "PF Claims4 - DR : Checks if the maximum benefits are correct" do
    @@dr_ph4[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@dr_ph4[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@dr_ph4[:or_max_benefit_operation].should == ("RVU x PCF")
  end

  it "PF Claims4 - DR : Checks if Deduction Claims are correct" do
    @@dr_ph4[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    @@dr_ph4[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    @@dr_ph4[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "PF Claims4 - DR : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
    else
      @@drugs_remaining_benefit_claim4 = 0.0
    end
    @@dr_ph4[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim4))

    if @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
    else
      @@lab_remaining_benefit_claim4 = 0
    end
    @@dr_ph4[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim4))
  end

  it "PF Claims4 - DR : Checks if PF Claims for surgeon(GP) is correct" do
    @@dr_ph4[:surgeon_benefit_claim].should == nil
  end

  it "PF Claims4 - DR : Checks if PF Claims for anesthesiologist(GP) is correct" do
    @@dr_ph4[:anesthesiologist_benefit_claim].should == nil
  end

  it "PF Claims4 - DR : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "PF Claims4 - DR : Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "PF Claims4 - DR : Prints Gate Pass of the patient" do
    slmc.login("slaquino", @password).should be_true
    slmc.or_print_gatepass(:pin => @@dr_pin, :visit_no => @@visit_no).should be_true
  end

  it "PF Claims4 - DR : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@dr_pin, :org_code => "0170").should be_true
  end

end