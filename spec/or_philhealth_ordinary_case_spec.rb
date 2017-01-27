require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: OR - Philhealth Ordinary Case (1st - 9th Availment)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @or_patient = Admission.generate_data
    @or_user = "slaquino"
    @pba_user = "ldcastro"
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])

    @drugs1 = {"042090007" => 1, "041840008" => 1, "049000028" => 1, "040950558" => 1} # 4
    @ancillary1 = {"010000317" => 1, "010000212" => 1, "010001039" => 1, "010000211" => 1} # 4
    @supplies1 = {"085100003" => 1, "080100023" => 1} # 2
    @operation1 = {"060000058" => 1, "060000003" => 1}

    @drugs3 = {"042090007" => 1, "041840008" => 1, "049000028" => 1, "041844322" => 1, "048470011" => 1, "040800031" => 1, "040950576" => 1, "040010002" => 1} # 8
    @ancillary3 = {"010000317" => 1, "010000212" => 1, "010001039" => 1, "010000211" => 1} # 4
    @supplies3 = {"085100003" => 1, "080100023" => 1} # 2
    @operation3 = {"060000058" => 1, "060000003" => 1}

    @drugs4 = {"040800031" => 1, "040860043" => 1, "041840008" => 1, "041844322" => 1, "042000061" => 1, "042090007" => 1, "044810074" => 1, "047632803" => 1, "048414006" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1} # 12
    @ancillary4 = {"010000008" => 1, "010000003" => 1} # 2
    @supplies4 = {"085100003" => 1, "089100004" => 1, "080100021" => 1, "080100023" => 1} # 4
    @operation4 = {"060000434" => 1, "060000038" => 1}

    @drugs5 = {"042090007" => 1, "049000028" => 1, "041844322" => 1, "048470011" => 1, "042000061" => 1, "048414006" => 1, "044810074" => 1, "040860043" => 1, "040010002" => 1} # 9
    @ancillary5 = {"010000600" => 1, "010000611" => 1} # 2
    @supplies5 = {"085100003" => 1, "089100004" => 1, "080100021" => 1, "080100023" => 1} # 4
    @operation5 = {"060000058" => 1, "060000003" => 1}

    @drugs6 = {"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1} # 5
    @ancillary6 = {"010000008" => 1, "010000003" => 1} # 2
    @supplies6 = {"080100021" => 1, "080100023" => 1} # 2
#    @drugs6 = {"042090007" => 1, "041840008" => 1, "049000028" => 1, "040950558" => 1, "048470011" => 1,} # 5
#    @ancillary6 = {"010000317" => 1, "010000212" => 1} # 2
#    @supplies6 = {"085100003" => 1, "080100023" => 1} # 2
    @operation6 = {"060000600" => 1, "060000597" => 1}

    @drugs7 = {"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1} # 5
    @ancillary7 = {"010000003" => 1, "010000008" => 1} # 2
    @supplies7 = {"080100021" => 1, "080100023" => 1} # 2
#    @drugs7= {"042090007" => 1, "041840008" => 1, "049000028" => 1, "040950558" => 1, "048470011" => 1,} # 5
#    @ancillary7 = {"010000317" => 1, "010000212" => 1} # 2
#    @supplies7 = {"085100003" => 1, "080100023" => 1} # 2
    @operation7 = {"060000600" => 1, "060000597" => 1}

    @drugs8 ={"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1} # 5
    @ancillary8 = {"010000008" => 1, "010000003" => 1} # 2
    @supplies8 = {"080100021" => 1, "080100023" => 1} # 2
#    @drugs8 = {"042090007" => 1, "041840008" => 1, "049000028" => 1, "040950558" => 1, "048470011" => 1,} # 5
#    @ancillary8 = {"010000317" => 1, "010000212" => 1} # 2
#    @supplies8 = {"085100003" => 1, "080100023" => 1} # 2
    @operation8 = {"060000597" => 1}

    @drugs = {"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1} # 5
    @ancillary = {"010000003" => 1, "010000008" => 1} # 2
    @supplies = {"080100021" => 1, "080100023" => 1} # 2
#    @drugs= {"042090007" => 1, "041840008" => 1, "049000028" => 1, "040950558" => 1, "048470011" => 1,} # 5
#    @ancillary = {"010000317" => 1, "010000212" => 1} # 2
#    @supplies = {"085100003" => 1, "080100023" => 1} # 2
    @operation = {"060000600" => 1, "060000597" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end
###
###1st Availment
###Case Type: Ordinary Case
###Claim Type: Accounts Receivable
###(before patient is discharged from PBA)
###With Operation: No
###Account Class: Individual
###Nursing Unit: OR-Main (0164)
#
  it "1st Availment : Order Items, Procedures and Clinical Discharges patient" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true, :gender => 'F')).gsub(' ', '')
   # slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    sleep 3
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true

     # slmc.add_returned_order(:drugs => true, :description => item,:stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true

    end
    @ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies1.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 4).should be_true
    slmc.verify_ordered_items_count(:ancillary => 4).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 10
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
      @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin).should be_true
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true,:special_unit => true, :rvu_code => "11446" )
    slmc.ph_save_computation
  end

  it "1st Availment : Check Benefit Summary totals" do
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

    @@orders = @ancillary1.merge(@supplies1).merge(@drugs1).merge(@operation1)
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

  it "1st Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph1[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "1st Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim1 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
    end
    @@actual_medicine_benefit_claim1 ="0.00"

    @@ph1[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
  end

  it "1st Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph1[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "1st Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@actual_lab_benefit_claim1 = "0.00"
    @@ph1[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
  end

 it "1st Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph1[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "1st Availment : Checks if the actual operation benefit claim is correct" do
#    if slmc.get_value("rvu.code").empty? == false
#      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
#      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
#        @@actual_operation_benefit_claim1 = @@actual_operation_charges
#      else
#        @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:max_amt].to_f
#      end
#      @@ph1[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
#    else
      @@actual_operation_benefit_claim1 = 0.00
      @@ph1[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
    end


  it "1st Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph1[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "1st Availment : Checks if the total actual benefit claim is correct" do
          @@total_actual_benefit_claim = 3100.00
   # @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1
    ((slmc.truncate_to((@@ph1[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  #  :drugs_deduction_claims
  end

  it "1st Availment : Checks if the maximum benefits are correct" do
    @@ph1[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph1[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "1st Availment : Checks if Deduction Claims are correct" do
    @@ph1[].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
    @@ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end

  it "1st Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim1 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
    else
      @@drugs_remaining_benefit_claim1 = 0.0
    end
    @@ph1[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim1))

    if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
    else
      @@lab_remaining_benefit_claim1 = 0
    end
    @@ph1[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim1))
  end

  it "1st Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "1st Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 12
  end

  it "1st Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "1st Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "1st Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page

    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
#  slmc.patient_pin_search(:pin => @@or_pin)
#  slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
  end

  it "1st Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  ### skips 2nd availment

#3rd Availment
#Case Type: Ordinary Case
#Claim Type: Refund
#(before patient is discharged from PBA)
#With Operation: No
#Account Class: Individual
#Nursing Unit: OR-Main (0164)

  it "3rd Availment : Order Item, Procedures and Clinically Discharges patient, Complete PF fee" do
        slmc.login(@or_user, @password).should be_true
    #    @@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true, :gender => 'F')).gsub(' ', '')
    sleep 6

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs3.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      sleep 5
      slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726",:route =>"ORAL").should be_true

    end
    @ancillary3.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies3.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 8).should be_true
    slmc.verify_ordered_items_count(:ancillary => 4).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 14
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "GASTRIC SURGERY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :pf_amount => "1000", :save => true).should be_true
    sleep 6


puts  @@or_pin
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph3 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CALIFORNIA ENCEPHALITIS", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "21267", :compute => true)
    slmc.ph_save_computation

  end
#
 
#  @@actual_medicine_benefit_claim1 = 2352.53999988         AR       ORDINARY CASE     4200               A00
#  @@actual_medicine_benefit_claim3 = 5885.57999988           R       CATASTROPHIC CASE      28000    A83.5
#  @@actual_medicine_benefit_claim4 = 0.0                               R       ORDINARY CASE                            A83.5
#  @@actual_medicine_benefit_claim5 = 1847.46000012           R       ORDINARY CASE                           A00
#  @@actual_medicine_benefit_claim6 = 4786.32                     AR       INTENSIVE CASE     14000           A00
#  @@actual_medicine_benefit_claim7 = 4786.32                     AR       INTENSIVE CASE                           A83.5
#  @@actual_medicine_benefit_claim8 = 4786.32                       R       INTENSIVE CASE                          A00
#  @@actual_medicine_benefit_claim9 =  227.36                        R       INTENSIVE CASE                          A00
#  @@actual_medicine_benefit_claim10 = 4786.32                     R       INTENSIVE CASE                          A91
#  @@actual_medicine_benefit_claim11 = 4786.32                  AR       CATASTROPHIC CASE                  A91
#  @@actual_medicine_benefit_claim12 = 4786.32                  AR        CATASTROPHIC CASE                 A91
#  @@actual_medicine_benefit_claim13 = 4786.32                    R      CATASTROPHIC CASE                    A91
#  @@actual_medicine_benefit_claim14 = 4786.32                    R      CATASTROPHIC CASE                  A91
#  @@actual_medicine_benefit_claim15 = 4068.40                    R      CATASTROPHIC CASE                  A91
#  @@actual_medicine_benefit_claim16 = 4786.32                  AR      SUPER CAT                                   A91
#  @@actual_medicine_benefit_claim17 = 4786.32                  AR
#  @@actual_medicine_benefit_claim18 = 2427.36                    R
#  @@actual_medicine_benefit_claim19 = 0.0                            R
  it "3rd Availment : Check Benefit Summary totals" do
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

    @@orders = @ancillary3.merge(@supplies3).merge(@drugs3).merge(@operation3)
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

   it "3rd Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    if @or_patient[:age] < 60
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount) + @@non_comp_drugs_mrp_tag
    else
      total_drugs = @@comp_drugs + @@non_comp_drugs + @@non_comp_drugs_mrp_tag
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount)
    end
    @@ph3[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "3rd Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim3 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph3[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
  end

  it "3rd Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph3[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "3rd Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph3[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
  end

  it "3rd Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph3[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "3rd Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim3 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim3 = 0.00
    end
    @@ph3[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "3rd Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph3[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "3rd Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3
    ((slmc.truncate_to((@@ph3[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "3rd Availment : Checks if the maximum benefits are correct" do
    @@ph3[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph3[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "3rd Availment : Checks if Deduction Claims are correct" do
    @@ph3[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
    @@ph3[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
    @@ph3[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "3rd Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim3 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim3 = 0.0
    end
    @@ph3[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim3))

    if @@actual_lab_benefit_claim3 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim3 = 0
    end
    @@ph3[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim3))
  end

  it "3rd Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21267")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph3[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "3rd Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph3[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "3rd Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "3rd Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 16
  end

  it "3rd Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "3rd Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "3rd Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "3rd Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "3rd Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#4th Availment
#Case Type: Ordinary Case
#Claim Type: Refund
#(during Standard discharge in PBA)
#With Operation: No
#Account Class: Individual
#Nursing Unit: OR-Main (0164)

  it "4th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs4.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
     #slmc.add_returned_order(:drugs => true, :description => item,:stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary4.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies4.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 12).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.verify_ordered_items_count(:supplies => 4).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 18
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "OPERATING ROOM CHARGES")
    slmc.add_returned_service(:item_code => @@item_code, :description => "OPERATING ROOM CHARGES")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "VEIN STRIPPING/LIGATION")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "VEIN STRIPPING/LIGATION")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    @@ph4 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CALIFORNIA ENCEPHALITIS", :medical_case_type => "ORDINARY CASE", :compute => true,:special_unit => true, :rvu_code => "11450")
    slmc.ph_save_computation
  end

  it "4th Availment : Check Benefit Summary totals" do
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

    @@orders = @ancillary4.merge(@supplies4).merge(@drugs4).merge(@operation4)
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

  it "4th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount) + @@non_comp_drugs_mrp_tag
    @@ph4[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "4th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3) < 0
      @@actual_medicine_benefit_claim4 = 0.00
    elsif @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim4 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3)
    end
    @@ph4[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
  end

  it "4th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph4[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "4th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")

    if @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3 < 0
      @@actual_lab_benefit_claim4 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)
    end
    @@ph4[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))




#    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
#    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
#
#    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim5) < 0
#      @@actual_lab_benefit_claim6 = 0.00
#    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1 -@@actual_lab_benefit_claim5
#      @@actual_lab_benefit_claim6 = @@actual_comp_xray_lab_others
#    else
#      @@actual_lab_benefit_claim6 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1 - @@actual_lab_benefit_claim5
#    end
#    @@ph6[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim6))


  end

  it "4th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph4[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "4th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim4 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim4 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph4[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
    else
      @@actual_operation_benefit_claim4 = 0.00
      @@ph4[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
    end
  end

  it "4th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph4[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "4th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4 + @@actual_operation_benefit_claim4
    ((slmc.truncate_to((@@ph4[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "4th Availment : Checks if the maximum benefits are correct" do
    @@ph4[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph4[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "4th Availment : Checks if Deduction Claims are correct" do
    @@ph4[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    @@ph4[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    @@ph4[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "4th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3
      @@drugs_remaining_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim4 - @@actual_medicine_benefit_claim3
    else
      @@drugs_remaining_benefit_claim4 = 0.0
    end
    @@ph4[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim4))

    if @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3
      @@lab_remaining_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim4 - @@actual_lab_benefit_claim3
    else
      @@lab_remaining_benefit_claim4 = 0
    end
    @@ph4[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim4))
  end

  it "4th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "4th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 20
  end

  it "4th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "4th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "4th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "4th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "4th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#5th Availment
#Case Type: Ordinary Case
#Claim Type: Refund
#(after patient is discharged from PBA)
#With Operation: No
#Account Class: Individual
#Nursing Unit: OR-Main (0164)

  it "5th Availment : Order Items, Procedures, Clinically Discharge patient, Complete PF fee, Discharge patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs5.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
  #    slmc.add_returned_order(:drugs => true, :description => item,:stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
      slmc.add_returned_order(:drugs => true, :description => item,:quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary5.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies5.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 9).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.verify_ordered_items_count(:supplies => 4).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 15
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
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
#    @@ph5 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true,:special_unit => true)
    @@ph5 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CALIFORNIA ENCEPHALITIS", :medical_case_type => "ORDINARY CASE", :compute => true,:special_unit => true, :rvu_code => "11462")

    slmc.ph_save_computation
  end

 it "5th Availment : Check Benefit Summary totals" do
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

    @@orders = @ancillary5.merge(@supplies5).merge(@drugs5).merge(@operation5)
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

  it "5th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE", "PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph5[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "5th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    if @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1 < 0 # considering 1st availment and 5th are cholera
      @@actual_medicine_benefit_claim5 = 0.00
    elsif @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
      @@actual_medicine_benefit_claim5 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
    end
    @@ph5[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
  end

  it "5th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph5[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "5th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
      @@actual_lab_benefit_claim5 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
    end
    @@ph5[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
  end

  it "5th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph5[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "5th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim5 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim5 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph5[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
    else
      @@actual_operation_benefit_claim5 = 0.00
      @@ph5[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
    end
  end

  it "5th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph5[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "5th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim5 + @@actual_lab_benefit_claim5 + @@actual_operation_benefit_claim5
    ((slmc.truncate_to((@@ph5[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "5th Availment : Checks if the maximum benefits are correct" do
    @@ph5[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph5[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "5th Availment : Checks if Deduction Claims are correct" do
    @@ph5[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
    @@ph5[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
    @@ph5[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
  end

  it "5th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim5 < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim5 - @@actual_medicine_benefit_claim1
      @@drugs_remaining_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim5
    else
      @@drugs_remaining_benefit_claim5 = 0.0
    end
    @@ph5[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim5))

    if @@actual_lab_benefit_claim5 < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim5 - @@actual_lab_benefit_claim1
      @@lab_remaining_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim5
    else
      @@lab_remaining_benefit_claim5 = 0
    end
    @@ph5[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim5))
  end

  it "5th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "5th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 17
  end

  it "5th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "5th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "5th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "5th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#6th Availment
#Case Type: Intensive Case
#Claim Type: Accounts Receivable
#(before patient is discharged from PBA)
#With Operation: No
#Account Class: Individual
#Nursing Unit: OR-Ophtha (0165)


  it "6th Availment : Order Items, Procedures, Clinically Discharge patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs6.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
#      slmc.add_returned_order(:drugs => true, :description => item,:stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
      slmc.add_returned_order(:drugs => true, :description => item,:quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary6.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies6.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login(@or_user, @password).should be_true  # org code is 165 for lansectomy
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items(:username => "sel_0165_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin).should be_true
    slmc.click_philhealth_link(:visit_no => @@visit_no, :pin => @@or_pin)
   #@@ph6 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "INTENSIVE CASE", :compute => true,:special_unit => true)
    @@ph6 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CALIFORNIA ENCEPHALITIS", :medical_case_type => "ORDINARY CASE", :compute => true,:special_unit => true, :rvu_code => "11470")

    slmc.ph_save_computation
  end

  it "6th Availment : Check Benefit Summary totals" do
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

    @@orders = @ancillary6.merge(@supplies6).merge(@drugs6).merge(@operation6)
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

  it "6th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph6[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "6th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
     if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim5) < 0
       @@actual_medicine_benefit_claim6 = 0.00
     elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim5)
    @@actual_medicine_benefit_claim6  = @@actual_comp_drugs
     else
       @@actual_medicine_benefit_claim6 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim5)
     end
    @@ph6[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim6))
  end

  it "6th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph6[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "6th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim5) < 0
      @@actual_lab_benefit_claim6 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1 -@@actual_lab_benefit_claim5
      @@actual_lab_benefit_claim6 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim6 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1 - @@actual_lab_benefit_claim5
    end
    @@ph6[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim6))
  end

  it "6th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph6[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "6th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim6 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim6 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph6[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
    else
      @@actual_operation_benefit_claim6 = 0.00
      @@ph6[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
    end
  end

  it "6th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph6[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "6th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim6 + @@actual_lab_benefit_claim6 + @@actual_operation_benefit_claim6
    ((slmc.truncate_to((@@ph6[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "6th Availment : Checks if the maximum benefits are correct" do
    @@ph6[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph6[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "6th Availment : Checks if Deduction Claims are correct" do
    @@ph6[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim6))
    @@ph6[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim6))
    @@ph6[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
  end

  it "6th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim6 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim6 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim6 - @@actual_medicine_benefit_claim5 - @@actual_medicine_benefit_claim1
    else
      @@drugs_remaining_benefit_claim6 = 0.0
    end
    @@ph6[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim6))

    if @@actual_lab_benefit_claim6 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim6 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim6 - @@actual_lab_benefit_claim5 - @@actual_lab_benefit_claim1
    else
      @@lab_remaining_benefit_claim6 = 0
    end
    @@ph6[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim6))
  end

  it "6th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "6th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "6th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "6th Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "6th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "6th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#7th Availment
#Case Type: Intensive Case
#Claim Type: Accounts Receivable
#(during Standard discgarge in PBA)
#With Operation: No
#Account Class: Individual
#Nursing Unit: OR-Ophtha (0165)

  it "7th Availment : Order Items, Procedures, Clinically Discharge patient, Complete PF fee" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs7.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      #slmc.add_returned_order(:drugs => true, :description => item,:stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary7.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies7.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login(@or_user, @password).should be_true  # org code is 165 for lansectomy
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items(:username => "sel_0165_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
  #  @@ph7 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CALIFORNIA ENCEPHALITIS", :medical_case_type => "INTENSIVE CASE", :compute => true,:special_unit => true)
    @@ph7 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CALIFORNIA ENCEPHALITIS", :medical_case_type => "ORDINARY CASE", :compute => true,:special_unit => true, :rvu_code => "11600")

    slmc.ph_save_computation
  end

  it "7th Availment : Check Benefit Summary totals" do
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

    @@orders = @ancillary7.merge(@supplies7).merge(@drugs7).merge(@operation7)
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

  it "7th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph7[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "7th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
     @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
     if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4) < 0
       @@actual_medicine_benefit_claim7 = 0.00
     elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4)
        @@actual_medicine_benefit_claim7  = @@actual_comp_drugs
     else
       @@actual_medicine_benefit_claim7 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4)
     end
    @@ph7[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
  end

  it "7th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph7[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "7th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4) < 0
      @@actual_lab_benefit_claim7 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3 -@@actual_lab_benefit_claim4
      @@actual_lab_benefit_claim7 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim7 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3 - @@actual_lab_benefit_claim4
    end
    @@ph7[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
  end

  it "7th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph7[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "7th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim7 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim7 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph7[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
    else
      @@actual_operation_benefit_claim7 = 0.00
      @@ph7[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
    end
  end

  it "7th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph7[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "7th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim7 + @@actual_lab_benefit_claim7 + @@actual_operation_benefit_claim7
    ((slmc.truncate_to((@@ph7[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "7th Availment : Checks if the maximum benefits are correct" do
    @@ph7[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph7[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "7th Availment : Checks if Deduction Claims are correct" do
    @@ph7[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
    @@ph7[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
    @@ph7[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
  end

  it "7th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim7 - @@actual_medicine_benefit_claim4 - @@actual_medicine_benefit_claim3 < 0
      @@drugs_remaining_benefit_claim7 = 0.0
    elsif @@actual_medicine_benefit_claim7 < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim7 - @@actual_medicine_benefit_claim4 - @@actual_medicine_benefit_claim3
      @@drugs_remaining_benefit_claim7 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim7 - @@actual_medicine_benefit_claim4 - @@actual_medicine_benefit_claim3
    else
      @@drugs_remaining_benefit_claim7 = 0.0
    end
    @@ph7[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim7))

    if @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim7 - @@actual_lab_benefit_claim4 - @@actual_lab_benefit_claim3 < 0
      @@lab_remaining_benefit_claim7 = 0.0
    elsif @@actual_lab_benefit_claim7 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim7 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim7 - @@actual_lab_benefit_claim4 - @@actual_lab_benefit_claim3
    else
      @@lab_remaining_benefit_claim7 = 0.0
    end
    @@ph7[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim7))
  end

  it "7th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "7th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "7th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "7th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "7th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "7th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#8th Availment
#Case Type: Intensive Case
#Claim Type: Refund
#(before patient is discharged from PBA)
#With Operation: Yes
#Account Class: Individual
#Nursing Unit: OR-Ophtha (0165)
# NOTE : 8th availment's procedure is SUPER CATASTROPHIC CASE. r20803, rvu_value is 550 SCT_PHB04.1

  it "8th Availment : Order Items, Procedure, Clinically Discharge patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs8.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
#      slmc.add_returned_order(:drugs => true, :description => item,:stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary8.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies8.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login(@or_user, @password).should be_true  # org code is 165 for lansectomy
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items(:username => "sel_0165_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin).should be_true
    slmc.click_philhealth_link(:visit_no => @@visit_no, :pin => @@or_pin)
    @@ph8 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "INTENSIVE CASE", :compute => true, :with_operation => true, :rvu_code => "14041")
    slmc.ph_save_computation
  end

  it "8th Availment : Check Benefit Summary totals" do
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

    @@orders = @ancillary8.merge(@supplies8).merge(@drugs8).merge(@operation8)
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

  it "8th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph8[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "8th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
     @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
     if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim6) < 0
       @@actual_medicine_benefit_claim8 = 0.00
     elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim6)
        @@actual_medicine_benefit_claim8  = @@actual_comp_drugs
     else
       @@actual_medicine_benefit_claim8 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim6)
     end
    @@ph8[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
  end

  it "8th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph8[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "8th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim6) < 0
      @@actual_lab_benefit_claim8 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1 - @@actual_lab_benefit_claim5 - @@actual_lab_benefit_claim6
      @@actual_lab_benefit_claim8 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim8 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1 - @@actual_lab_benefit_claim5 - @@actual_lab_benefit_claim6
    end
    @@ph8[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
  end

  it "8th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph8[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "8th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim8 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim8 = @@operation_ph_benefit[:min_amt].to_f #Operation (min 3,500.00)
      end
      @@ph8[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
    else
      @@actual_operation_benefit_claim8 = 0.00
      @@ph8[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
    end
  end

  it "8th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph8[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    ((slmc.truncate_to((@@ph8[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "8th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim8 + @@actual_lab_benefit_claim8 + @@actual_operation_benefit_claim8
    ((slmc.truncate_to((@@ph8[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "8th Availment : Checks if the maximum benefits are correct" do
    @@ph8[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph8[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "8th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim8 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim8 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim8 - @@actual_medicine_benefit_claim6 - @@actual_medicine_benefit_claim5 - @@actual_medicine_benefit_claim1
    else
      @@drugs_remaining_benefit_claim8 = 0.0
    end
    @@ph8[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim8))

    if @@actual_lab_benefit_claim8 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim8 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim8 - @@actual_lab_benefit_claim6 - @@actual_lab_benefit_claim5 - @@actual_lab_benefit_claim1
    else
      @@lab_remaining_benefit_claim8 = 0.0
    end
    @@ph8[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim8))
  end

  it "8th Availment : Checks if Deduction Claims are correct" do
    @@ph8[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
    @@ph8[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
    @@ph8[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
  end

  it "8th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("14041")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph8[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "8th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    @@ph8[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "8th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "8th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 10
  end

  it "8th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "8th Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "8th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "8th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#9th Availment
#Case Type: Intensive Case
#Claim Type: Refund
#(during Standard discharge in PBA)
#With Operation: No
#Account Class: Individual
#Nursing Unit: OR-Ophtha (0165)

  it "9th Availment : Order Items, Procedures, Clinically Discharge patient, Pay PF fee" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
#      slmc.add_returned_order(:drugs => true, :description => item,:stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "REPAIR OF CORNEAL LACERATION")
    slmc.add_returned_service(:item_code => @@item_code, :description => "REPAIR OF CORNEAL LACERATION")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "LENSECTOMY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "LENSECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items(:username => "sel_0165_validator").should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    @@ph9 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "INTENSIVE CASE", :compute => true,:special_unit => true)
    slmc.ph_save_computation
  end

  it "9th Availment : Check Benefit Summary totals" do
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

  it "9th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    @@ph9[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "9th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
     if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim8) < 0
       @@actual_medicine_benefit_claim9 = 0.00
     elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim8)
        @@actual_medicine_benefit_claim9  = @@actual_comp_drugs
     else
       @@actual_medicine_benefit_claim9 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim8)
     end
    @@ph9[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim9))
  end

  it "9th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph9[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "9th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim6 - @@actual_lab_benefit_claim8) < 0
      @@actual_lab_benefit_claim9 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim8)
      @@actual_lab_benefit_claim9 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim9 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim8)
    end
    @@ph9[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim9))
  end

  it "9th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph9[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "9th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim9 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim9 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim9 = 0.00
    end
    @@ph9[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim9))
  end

  it "9th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph9[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "9th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim9 + @@actual_lab_benefit_claim9 + @@actual_operation_benefit_claim9
    ((slmc.truncate_to((@@ph9[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "9th Availment : Checks if the maximum benefits are correct" do
    @@ph9[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph9[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "9th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim9 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim9 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim9 + @@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim1)
    else
      @@drugs_remaining_benefit_claim9 = 0.0
    end
    @@ph9[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim9))

    if @@actual_lab_benefit_claim9 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim9 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim9 + @@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim1)
    else
      @@lab_remaining_benefit_claim9 = 0.0
    end
    @@ph9[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim9))
  end

  it "9th Availment : Checks if Deduction Claims are correct" do
    @@ph9[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim9))
    @@ph9[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim9))
    @@ph9[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim9))
  end

  it "9th Availment : Checks Claim History" do
    (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display.").should be_false
  end

  it "9th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "9th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "9th Availment : PhilHealth Benefit Claim shall not reflect in Payment details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should == ("%0.2f" %(0))
  end

  it "9th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "9th Availment : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "9th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end
end
#  @@actual_medicine_benefit_claim20 = 0.0                            R      SUPER CAT                                  A91
