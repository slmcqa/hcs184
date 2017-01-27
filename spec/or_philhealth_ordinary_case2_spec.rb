require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: OR - Philhealth Ordinary Case (10th - 20th Availment)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @or_user = "slaquino"
    @pba_user = "ldcastro"
    @or_patient = Admission.generate_data
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])

    @drugs = {"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1} # 5
    @ancillary = {"010000003" => 1, "010000008" => 1} # 2
    @supplies = {"080100021" => 1, "080100023" => 1} # 2
    @operation = {"060000600" => 1, "060000597" => 1}

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

#######10th Availment
#######Case Type: Intensive Case
#######Claim Type: Refund
#######(after patient is discharged from PBA)
#######With Operation: No
#######Account Class: Individual
#######Nursing Unit: OR-Ophtha (0165)
#######DENGUE HEMORRHAGIC FEVER (A91)

 it "10th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee, Discharge patient" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true, :gender => 'F')).gsub(' ', '')
      #  slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0165_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin).should be_true
    slmc.click_philhealth_link(:visit_no => @@visit_no, :pin => @@or_pin)
    @@ph10 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :medical_case_type => "INTENSIVE CASE", :compute => true,:special_unit => true)
    slmc.ph_save_computation
  end

  it "10th Availment : Check Benefit Summary totals" do
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

  it "10th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph10[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "10th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f < 0
      @@actual_medicine_benefit_claim10 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
       @@actual_medicine_benefit_claim10  = @@actual_comp_drugs
    else
      @@actual_medicine_benefit_claim10 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph10[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
  end

  it "10th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph10[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "10th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f < 0
      @@actual_lab_benefit_claim10 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim10 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim10 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph10[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
  end

  it "10th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph10[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "10th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim10 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim10 = @@operation_ph_benefit[:max_amt].to_f
      end      
    else
      @@actual_operation_benefit_claim10 = 0.00      
    end
    @@ph10[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
  end

  it "10th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph10[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "10th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim10 + @@actual_lab_benefit_claim10 + @@actual_operation_benefit_claim10
    @@ph10[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "10th Availment : Checks if the maximum benefits are correct" do
    @@ph10[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph10[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "10th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim10 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim10 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim10
    else
      @@drugs_remaining_benefit_claim10 = 0.0
    end
    @@ph10[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim10))

    if @@actual_lab_benefit_claim10 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim10 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim10
    else
      @@lab_remaining_benefit_claim10 = 0.0
    end
    @@ph10[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim10))
  end

  it "10th Availment : Checks if Deduction Claims are correct" do
    @@ph10[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
    @@ph10[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
    @@ph10[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
  end

  it "10th Availment : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "10th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "10th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "10th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "10th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "10th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#11th Availment
#Case Type: Catastrophic Case
#Claim Type: Accounts Receivable
#(before patient is discharged from PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-MAB (0296)

  it "11th Availment : Order Items, Procedures, Clinically Discharge patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("or_mab", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0296_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin).should be_true
    slmc.click_philhealth_link(:visit_no => @@visit_no, :pin => @@or_pin)
    @@ph11 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "21267", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "11th Availment : Check Benefit Summary totals" do
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

  it "11th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph11[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "11th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim10 < 0
      @@actual_medicine_benefit_claim11 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim10
      @@actual_medicine_benefit_claim11  = @@actual_comp_drugs
     else
       @@actual_medicine_benefit_claim11 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim10
     end
    @@ph11[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim11))
  end

  it "11th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph11[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "11th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim10 < 0
      @@actual_lab_benefit_claim11 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim10
      @@actual_lab_benefit_claim11 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim11 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim10
    end
    @@ph11[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim11))
  end

  it "11th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph11[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "11th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim11 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim11 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim11 = 0.00
    end
    @@ph11[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim11))
  end

  it "11th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph11[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "11th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim11 + @@actual_lab_benefit_claim11 + @@actual_operation_benefit_claim11
    @@ph11[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "11th Availment : Checks if the maximum benefits are correct" do
    @@ph11[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph11[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "11th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim11 < @@med_ph_benefit[:max_amt].to_f
      #@@drugs_remaining_benefit_claim11 = @@med_ph_benefit[:max_amt].to_f - (slmc.truncate_to(@@actual_medicine_benefit_claim11, 2) + slmc.truncate_to(@@actual_medicine_benefit_claim10, 2))
      @@drugs_remaining_benefit_claim11 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim10)
    else
      @@drugs_remaining_benefit_claim11 = 0.0
    end
    @@ph11[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim11))

    if @@actual_lab_benefit_claim11 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim11 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    else
      @@lab_remaining_benefit_claim11 = 0.0
    end
    @@ph11[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim11))
  end

  it "11th Availment : Checks if Deduction Claims are correct" do
    @@ph11[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim11))
    @@ph11[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim11))
    @@ph11[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim11))
  end

  it "11th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21267")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph11[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "11th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph11[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "11th Availment : Claim Type should be disabled and Accounts Receivable" do
    slmc.get_selected_label("claimType").should == "ACCOUNTS RECEIVABLE"
    slmc.is_editable("claimType").should be_false
  end

  it "11th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display.")
  end

  it "11th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "11th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "11th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "11th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "11th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#12th Availment
#Case Type: Catastrophic Case
#Claim Type: Accounts Receivable
#(during Standard Discharge in PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-MAB (0296)

  it "12th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("or_mab", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0296_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    @@ph12 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "21267", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "12th Availment : Check Benefit Summary totals" do
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

  it "12th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount)
    @@ph12[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "12th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
     @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
     if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11) < 0
       @@actual_medicine_benefit_claim12 = 0.00
     elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11)
        @@actual_medicine_benefit_claim12  = @@actual_comp_drugs
     else
       @@actual_medicine_benefit_claim12 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11)
     end
    #@@actual_medicine_benefit_claim12 = slmc.truncate_to(@@actual_medicine_benefit_claim12, 2)
    @@ph12[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim12))
  end

  it "12th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph12[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "12th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim10 + @@actual_lab_benefit_claim11) < 0
      @@actual_lab_benefit_claim12 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim10 + @@actual_lab_benefit_claim11)
      @@actual_lab_benefit_claim12 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim12 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim10 + @@actual_lab_benefit_claim11)
    end
    @@ph12[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim12))
  end

  it "12th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph12[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "12th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim12 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim12 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim12 = 0.00
    end
    @@ph12[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim12))
  end

  it "12th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph12[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "12th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim12 + @@actual_lab_benefit_claim12 + @@actual_operation_benefit_claim12
    @@ph12[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "12th Availment : Checks if the maximum benefits are correct" do
    @@ph12[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph12[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "12th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim12 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim12 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim10)
    else
      @@drugs_remaining_benefit_claim12 = 0.0
    end
    @@ph12[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim12))

    if @@actual_lab_benefit_claim12 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim12 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    else
      @@lab_remaining_benefit_claim12 = 0.0
    end
    @@ph12[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim12))
  end

  it "12th Availment : Checks if Deduction Claims are correct" do
    @@ph12[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim12))
    @@ph12[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim12))
    @@ph12[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim12))
  end

  it "12th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21267")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph12[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "12th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph12[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "12th Availment : Claim Type should be disabled and Accounts Receivable" do
    slmc.get_selected_label("claimType").should == "ACCOUNTS RECEIVABLE"
    slmc.is_editable("claimType").should be_false
  end

  it "12th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display.")
  end

  it "12th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "12th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "12th Availment : PhilHealth Benefit Claim should reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(@@ph12[:or_total_actual_benefit_claim]))
  end

  it "12th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "12th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "12th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#13th Availment
#Case Type: Catastrophic Case
#Claim Type: Refund
#(before patient is discharged from ER PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-MAB (0296)

  it "13th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("or_mab", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0296_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph13 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "21267", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "13th Availment : Check Benefit Summary totals" do
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

  it "13th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph13[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "13th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12) < 0
      @@actual_medicine_benefit_claim13 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12)
      @@actual_medicine_benefit_claim13  = @@actual_comp_drugs
    else
      @@actual_medicine_benefit_claim13 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12)
    end
    @@ph13[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim13))
  end

  it "13th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph13[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "13th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim10 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim12) < 0
      @@actual_lab_benefit_claim13 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim10 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim12)
      @@actual_lab_benefit_claim13 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim13 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim10 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim12)
    end
    @@ph13[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim13))
  end

  it "13th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph13[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "13th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim13 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim13 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim13 = 0.00
    end
    @@ph13[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim13))
  end

  it "13th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph13[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "13th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim13 + @@actual_lab_benefit_claim13 + @@actual_operation_benefit_claim13
    @@ph13[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "13th Availment : Checks if the maximum benefits are correct" do
    @@ph13[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph13[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "13th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim13 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim13 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim10)
    else
      @@drugs_remaining_benefit_claim13 = 0.0
    end
    @@drugs_remaining_benefit_claim13 = slmc.truncate_to(@@drugs_remaining_benefit_claim13, 2)
    @@ph13[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim13))

    if @@actual_lab_benefit_claim13 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim13 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    else
      @@lab_remaining_benefit_claim13 = 0.0
    end
    @@ph13[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim13))
  end

  it "13th Availment : Checks if Deduction Claims are correct" do
    @@ph13[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim13))
    @@ph13[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim13))
    @@ph13[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim13))
  end

  it "13th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21267")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph13[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "13th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph13[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "13th Availment : Claim Type should be disabled and Refund" do
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.is_editable("claimType").should be_false
  end

  it "13th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display.")
  end

  it "13th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "13th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "13th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "13th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "13th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "13th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

# 14th Availment
#Case Type: Catastrophic Case
#Claim Type: Refund
#(during Standard discharge in PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-MAB (0296)

  it "14th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("or_mab", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0296_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    @@ph14 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "21267", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "14th Availment : Check Benefit Summary totals" do
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

  it "14th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph14[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "14th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim13) < 0
      @@actual_medicine_benefit_claim14 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim13)
      @@actual_medicine_benefit_claim14  = @@actual_comp_drugs
    else
      @@actual_medicine_benefit_claim14 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim13)
    end
    @@ph14[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim14))
  end

  it "14th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph14[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "14th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 +@@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10) < 0
      @@actual_lab_benefit_claim14 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 +@@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
      @@actual_lab_benefit_claim14 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim14 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 +@@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    end
    @@ph14[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim14))
  end

  it "14th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph14[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "14th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim14 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim14 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim14 = 0.00
    end
    @@ph14[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim14))
  end

  it "14th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph14[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "14th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim14 + @@actual_lab_benefit_claim14 + @@actual_operation_benefit_claim14
    @@ph14[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "14th Availment : Checks if the maximum benefits are correct" do
    @@ph14[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph14[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "14th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim14 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim14 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim10)
    else
      @@drugs_remaining_benefit_claim14 = 0.0
    end
    @@ph14[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim14))

    if @@actual_lab_benefit_claim14 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim14 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    else
      @@lab_remaining_benefit_claim14 = 0.0
    end
    @@ph14[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim14))
  end

  it "14th Availment : Checks if Deduction Claims are correct" do
    @@ph14[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim14))
    @@ph14[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim14))
    @@ph14[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim14))
  end

  it "14th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21267")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph14[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "14th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph14[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "14th Availment : Claim Type should be disabled and Accounts Receivable" do
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.is_editable("claimType").should be_false
  end

  it "14th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display.")
  end

  it "14th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "14th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "14th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "14th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "14th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "14th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#15th Availment
#Case Type: Catastrophic Case
#Claim Type: Refund
#(after patient is discharged from PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-MAB (0296)

  it "15th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee, Discharge patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("or_mab", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0296_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph15 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "21267", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "15th Availment : Check Benefit Summary totals" do
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

  it "15th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph15[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "15th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14) < 0
      @@actual_medicine_benefit_claim15 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
       @@actual_medicine_benefit_claim15  = @@actual_comp_drugs
    elsif
      @@actual_medicine_benefit_claim15 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14)
    end
    @@ph15[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim15))
  end

  it "15th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph15[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "15th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10) < 0
      @@actual_lab_benefit_claim15 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim15 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim15 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    end
    @@ph15[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim15))
  end

  it "15th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph15[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "15th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim15 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim15 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim15 = 0.00
    end
    @@ph15[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim15))
  end

  it "15th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph15[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "15th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim15 + @@actual_lab_benefit_claim15 + @@actual_operation_benefit_claim15
    @@ph15[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "15th Availment : Checks if the maximum benefits are correct" do
    @@ph15[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph15[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "15th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim15 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim15 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim10)
    else
      @@drugs_remaining_benefit_claim15 = 0.0
    end
    @@ph15[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim15))

    if @@actual_lab_benefit_claim15 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim15 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    else
      @@lab_remaining_benefit_claim15 = 0.0
    end
    @@ph15[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim15))
  end

  it "15th Availment : Checks if Deduction Claims are correct" do
    @@ph15[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim15))
    @@ph15[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim15))
    @@ph15[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim15))
  end

  it "15th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21267")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph15[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "15th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph15[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "15th Availment : Claim Type should be disabled and REFUND" do
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.is_editable("claimType").should be_false
  end

  it "15th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display.")
  end

  it "15th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "15th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "15th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "15th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "15th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#16th Availment
#Case Type: Super Catastrophic Case
#Claim Type: Accounts Receivable
#(before patient is discharged from PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-Main (0164)

  it "16th Availment : Order Items, Procedures, Clinically Discharge patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0165_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin).should be_true
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph16 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "22847", :medical_case_type => "SUPER CATASTROPHIC CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "16th Availment : Check Benefit Summary totals" do
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

  it "16th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph16[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "16th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
     @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
     if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15) < 0
       @@actual_medicine_benefit_claim16 = 0.00
     elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 +  @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15)
        @@actual_medicine_benefit_claim16  = @@actual_comp_drugs
     else
       @@actual_medicine_benefit_claim16 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 +  @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15)
     end
    @@ph16[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim16))
  end

  it "16th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph16[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "16th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10) < 0
      @@actual_lab_benefit_claim16 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
      @@actual_lab_benefit_claim16 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim16 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    end
    @@ph16[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim16))
  end


  it "16th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph16[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "16th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim16 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim16 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim16 = 0.00
    end
    @@ph16[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim16))
  end

  it "16th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph16[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "16th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim16 + @@actual_lab_benefit_claim16 + @@actual_operation_benefit_claim16
    @@ph16[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "16th Availment : Checks if the maximum benefits are correct" do
    @@ph16[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph16[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "16th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim16 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim16 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim16 - @@actual_medicine_benefit_claim15 - @@actual_medicine_benefit_claim14 - @@actual_medicine_benefit_claim13 - @@actual_medicine_benefit_claim12 - @@actual_medicine_benefit_claim11 - @@actual_medicine_benefit_claim10
    else
      @@drugs_remaining_benefit_claim16 = 0.0
    end
    @@ph16[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim16))

    if @@actual_lab_benefit_claim16 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim16 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim16 - @@actual_lab_benefit_claim15 - @@actual_lab_benefit_claim14 - @@actual_lab_benefit_claim13 - @@actual_lab_benefit_claim12 - @@actual_lab_benefit_claim11 - @@actual_lab_benefit_claim10
    else
      @@lab_remaining_benefit_claim16 = 0.0
    end
    @@ph16[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim16))
  end

  it "16th Availment : Checks if Deduction Claims are correct" do
    @@ph16[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim16))
    @@ph16[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim16))
    @@ph16[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim16))
  end

  it "16th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("22847")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph16[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "16th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph16[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "16th Availment : Claim Type should be disabled and Accounts Receivable" do
    slmc.get_selected_label("claimType").should == "ACCOUNTS RECEIVABLE"
    slmc.is_editable("claimType").should be_false
  end

  it "16th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "16th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "16th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "16th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "16th Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "16th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "16th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#17th Availment
#Case Type: Super Catastrophic Case
#Claim Type: Accounts Receivable
#(during Standard Discharge in PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-Main (0164)

  it "17th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0165_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    @@ph17 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "22847", :medical_case_type => "SUPER CATASTROPHIC CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "17th Availment : Check Benefit Summary totals" do
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

  it "17th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph17[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "17th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
   @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
   if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16) < 0
     @@actual_medicine_benefit_claim17 = 0.00
   elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 +  @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16)
      @@actual_medicine_benefit_claim17  = @@actual_comp_drugs
   else
     @@actual_medicine_benefit_claim17 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 +  @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16)
   end
  @@ph17[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim17))
  end

  it "17th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph17[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "17th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10) < 0
      @@actual_lab_benefit_claim17 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
      @@actual_lab_benefit_claim17 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim17 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    end
    @@ph17[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim17))
  end


  it "17th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph17[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "17th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim17 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim17 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim17 = 0.00
    end
    @@ph17[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim17))
  end

  it "17th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph17[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "17th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim17 + @@actual_lab_benefit_claim17 + @@actual_operation_benefit_claim17
    @@ph17[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "17th Availment : Checks if the maximum benefits are correct" do
    @@ph17[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph17[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "17th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim17 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim17 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim17 - @@actual_medicine_benefit_claim16 - @@actual_medicine_benefit_claim15 - @@actual_medicine_benefit_claim14 - @@actual_medicine_benefit_claim13 - @@actual_medicine_benefit_claim12 - @@actual_medicine_benefit_claim11 - @@actual_medicine_benefit_claim10
    else
      @@drugs_remaining_benefit_claim17 = 0.0
    end
    @@ph17[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim17))

    if @@actual_lab_benefit_claim17 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim17 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim17 - @@actual_lab_benefit_claim16 - @@actual_lab_benefit_claim15 - @@actual_lab_benefit_claim14 - @@actual_lab_benefit_claim13 - @@actual_lab_benefit_claim12 - @@actual_lab_benefit_claim11 - @@actual_lab_benefit_claim10
    else
      @@lab_remaining_benefit_claim17 = 0.0
    end
    @@ph17[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim17))
  end

  it "17th Availment : Checks if Deduction Claims are correct" do
    @@ph17[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim17))
    @@ph17[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim17))
    @@ph17[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim17))
  end

  it "17th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("22847")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph17[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "17th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph17[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "17th Availment : Claim Type should be disabled and Accounts Receivable" do
    slmc.get_selected_label("claimType").should == "ACCOUNTS RECEIVABLE"
    slmc.is_editable("claimType").should be_false
  end

  it "17th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "17th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "17th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "17th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(@@ph17[:or_total_actual_benefit_claim]))
  end

  it "17th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "17th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "17th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#18th Availment
#Case Type: Super Catastrophic Case
#Claim Type: Refund
#(before patient is discharged from ER PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-Main (0164)

  it "18th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0165_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph18 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "22847", :medical_case_type => "SUPER CATASTROPHIC CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "18th Availment : Check Benefit Summary totals" do
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

  it "18th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph18[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "18th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
   @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
   if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim17) < 0
     @@actual_medicine_benefit_claim18 = 0.00
   elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 +  @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim17)
      @@actual_medicine_benefit_claim18  = @@actual_comp_drugs
   else
     @@actual_medicine_benefit_claim18 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 +  @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim17)
   end
   @@ph18[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim18))
  end

  it "18th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph18[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "18th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim17 + @@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10) < 0
      @@actual_lab_benefit_claim18 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim17 + @@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
      @@actual_lab_benefit_claim18 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim18 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim17 + @@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    end
    @@ph18[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim18))
  end


  it "18th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph18[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "18th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim18 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim18 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim18 = 0.00
    end
    @@ph18[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim18))
  end

  it "18th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph18[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "18th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim18 + @@actual_lab_benefit_claim18 + @@actual_operation_benefit_claim18
    @@ph18[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "18th Availment : Checks if the maximum benefits are correct" do
    @@ph18[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph18[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "18th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim18 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim18 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim18 - @@actual_medicine_benefit_claim17 - @@actual_medicine_benefit_claim16 - @@actual_medicine_benefit_claim15 - @@actual_medicine_benefit_claim14 - @@actual_medicine_benefit_claim13 - @@actual_medicine_benefit_claim12 - @@actual_medicine_benefit_claim11 - @@actual_medicine_benefit_claim10
    else
      @@drugs_remaining_benefit_claim18 = 0.0
    end
    @@ph18[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim18))

    if @@actual_lab_benefit_claim18 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim18 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim18 - @@actual_lab_benefit_claim17 - @@actual_lab_benefit_claim16 - @@actual_lab_benefit_claim15 - @@actual_lab_benefit_claim14 - @@actual_lab_benefit_claim13 - @@actual_lab_benefit_claim12 - @@actual_lab_benefit_claim11 - @@actual_lab_benefit_claim10
    else
      @@lab_remaining_benefit_claim18 = 0.0
    end
    @@ph18[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim18))
  end

  it "18th Availment : Checks if Deduction Claims are correct" do
    @@ph18[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim18))
    @@ph18[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim18))
    @@ph18[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim18))
  end

  it "18th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("22847")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph18[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "18th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph18[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "18th Availment : Claim Type should be disabled and Refund" do
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.is_editable("claimType").should be_false
  end

  it "18th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "18th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "18th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "18th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "18th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "18th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "18th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#19th Availment
#Case Type: Super Catastrophic Case
#Claim Type: Refund
#(during Standard discharge in PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-Main (0164)

  it "19th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0165_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    @@ph19 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "22847", :medical_case_type => "SUPER CATASTROPHIC CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "19th Availment : Check Benefit Summary totals" do
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

  it "19th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph19[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "19th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
   @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
   if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim17 + @@actual_medicine_benefit_claim18) < 0
     @@actual_medicine_benefit_claim19 = 0.00
   elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 +  @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim17 + @@actual_medicine_benefit_claim18)
      @@actual_medicine_benefit_claim19  = @@actual_comp_drugs
   else
     @@actual_medicine_benefit_claim19 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 +  @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim17 + @@actual_medicine_benefit_claim18)
   end
  @@ph19[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim19))
  end

  it "19th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph19[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "19th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim18 + @@actual_lab_benefit_claim17 + @@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10) < 0
      @@actual_lab_benefit_claim19 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim18 + @@actual_lab_benefit_claim17 + @@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
      @@actual_lab_benefit_claim19 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim19 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim18 + @@actual_lab_benefit_claim17 + @@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    end
    @@ph19[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim19))
  end


  it "19th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph19[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "19th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim19 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim19 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim19 = 0.00
    end
    @@ph19[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim19))
  end

  it "19th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph19[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "19th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim19 + @@actual_lab_benefit_claim19 + @@actual_operation_benefit_claim19
    @@ph19[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "19th Availment : Checks if the maximum benefits are correct" do
    @@ph19[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph19[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "19th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim19 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim19 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim19 + @@actual_medicine_benefit_claim18 + @@actual_medicine_benefit_claim17 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim10)
    else
      @@drugs_remaining_benefit_claim19 = 0.0
    end
    @@ph19[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim19))

    if @@actual_lab_benefit_claim19 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim19 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim19 - @@actual_lab_benefit_claim18 - @@actual_lab_benefit_claim17 - @@actual_lab_benefit_claim16 - @@actual_lab_benefit_claim15 - @@actual_lab_benefit_claim14 - @@actual_lab_benefit_claim13 - @@actual_lab_benefit_claim12 - @@actual_lab_benefit_claim11 - @@actual_lab_benefit_claim10
    else
      @@lab_remaining_benefit_claim19 = 0.0
    end
    @@ph19[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim19))
  end

  it "19th Availment : Checks if Deduction Claims are correct" do
    @@ph19[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim19))
    @@ph19[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim19))
    @@ph19[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim19))
  end

  it "19th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("22847")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph19[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "19th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph19[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "19th Availment : Claim Type should be disabled and Refund" do
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.is_editable("claimType").should be_false
  end

  it "19th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "19th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "19th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "19th Availment : PhilHealth Benefit Claim should reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "19th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "19th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "19th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#20th Availment
#Case Type: Super Catastrophic Case
#Claim Type: Refund
#(after patient is discharged from PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-Main (0164)

  it "20th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee, Discharge patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, 
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items(:username => "sel_0165_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin,  :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph20 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "22847", :medical_case_type => "SUPER CATASTROPHIC CASE", :compute => true)
    slmc.ph_save_computation
  end

  it "20th Availment : Check Benefit Summary totals" do
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

  it "20th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph20[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "20th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
   @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
   if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim17 + @@actual_medicine_benefit_claim18 + @@actual_medicine_benefit_claim19) < 0
     @@actual_medicine_benefit_claim20 = 0.00
   elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 +  @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim17 + @@actual_medicine_benefit_claim18 + @@actual_medicine_benefit_claim19)
      @@actual_medicine_benefit_claim20  = @@actual_comp_drugs
   else
     @@actual_medicine_benefit_claim20 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim12 +  @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim17 + @@actual_medicine_benefit_claim18 + @@actual_medicine_benefit_claim19)
   end
  @@ph20[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim20))
  end

  it "20th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph20[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "20th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim19 + @@actual_lab_benefit_claim18 + @@actual_lab_benefit_claim17 + @@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10) < 0
      @@actual_lab_benefit_claim20 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim19 + @@actual_lab_benefit_claim18 + @@actual_lab_benefit_claim17 + @@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
      @@actual_lab_benefit_claim20 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim20 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim19 + @@actual_lab_benefit_claim18 + @@actual_lab_benefit_claim17 + @@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    end
    @@ph20[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim20))
  end


  it "20th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph20[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "20th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim20 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim20 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim20 = 0.00
    end
    @@ph20[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim20))
  end

  it "20th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph20[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "20th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim20 + @@actual_lab_benefit_claim20 + @@actual_operation_benefit_claim20
    @@ph20[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "20th Availment : Checks if the maximum benefits are correct" do
    @@ph20[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph20[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "20th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim20 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim20 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim20 + @@actual_medicine_benefit_claim19 + @@actual_medicine_benefit_claim18 + @@actual_medicine_benefit_claim17 + @@actual_medicine_benefit_claim16 + @@actual_medicine_benefit_claim15 + @@actual_medicine_benefit_claim14 + @@actual_medicine_benefit_claim13 + @@actual_medicine_benefit_claim12 + @@actual_medicine_benefit_claim11 + @@actual_medicine_benefit_claim10)
    else
      @@drugs_remaining_benefit_claim20 = 0.0
    end
    @@ph20[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim20))

    if @@actual_lab_benefit_claim20 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim20 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim20 + @@actual_lab_benefit_claim19 + @@actual_lab_benefit_claim18 + @@actual_lab_benefit_claim17 + @@actual_lab_benefit_claim16 + @@actual_lab_benefit_claim15 + @@actual_lab_benefit_claim14 + @@actual_lab_benefit_claim13 + @@actual_lab_benefit_claim12 + @@actual_lab_benefit_claim11 + @@actual_lab_benefit_claim10)
    else
      @@lab_remaining_benefit_claim20 = 0.0
    end
    @@ph20[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim20))
  end

  it "20th Availment : Checks if Deduction Claims are correct" do
    @@ph20[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim20))
    @@ph20[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim20))
    @@ph20[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim20))
  end

  it "20th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("22847")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph20[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "20th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph20[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "20th Availment : Claim Type should be disabled and Refund" do
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.is_editable("claimType").should be_false
  end

  it "20th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "20th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "20th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "20th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "20th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "20th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

end