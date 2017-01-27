require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: OR - Philhealth Special Case" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @or_patient = Admission.generate_data
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])

    @password = "123qweuser"
    @@special_case_value = 8000.0

    @drugs =  {"040800031" => 1, "040004334" => 1}
    @ancillary = {"010001194" => 1, "010001448" => 1}
    @operation = {"060000157" => 1}

    @drugs2 =  {"040800031" => 1, "040004334" => 1}
    @ancillary2 = {"010001194" => 1, "010001448" => 1}
    @operation2 = {"060000157" => 1}

    @drugs3 = {"040800031" => 1, "040004334" => 1}
    @ancillary3 = {"010001194" => 1, "010001448" => 1}

    @drugs4 = {"040800031" => 1, "040004334" => 1}
    @ancillary4 = {"010001194" => 1, "010001448" => 1}

    @ancillary5 = {"010000868" => 1}
    @others5 = {"060001731" => 1, "060001946" => 1, "060001796" => 1}

    @ancillary6 = {"010000868" => 1}
    @others6 = {"060001731" => 1, "060001946" => 1, "060001796" => 1}

    @drugs7 = {"040004334" => 1}
    @ancillary7 = {"010001900" => 1}
    @operation7 = {"060002045" => 1}

    @drugs8 = {"040004334" => 1}
    @ancillary8 = {"010001900" => 1}

    @drugs9 = {"040800031" => 1}
    @ancillary9 = {"010001636" => 1, "010001585" => 1, "010001583" => 1}

    @drugs10 = {"040800031" => 1}
    @ancillary10 = {"010001636" => 1, "010001585" => 1, "010001583" => 1}
    @operation10 = {"060002045" => 1, "060000204" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "1st Availment : Cataract Package - Claim Type: Accounts Receivable" do
    sleep 6
    slmc.login("sel_or3", @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge(:admit => true, :gender => 'F')).gsub(' ', '')
    sleep 6
     slmc.login("sel_or3", @password).should be_true
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
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "SHARPLAN-EYE (DCR-EXTERNAL)")
    slmc.add_returned_service(:item_code => @@item_code, :description => "SHARPLAN-EYE (DCR-EXTERNAL)")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    sleep 6
    puts @@or_pin
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:visit_no => @@visit_no, :pin => @@or_pin)
    @@case_rate = "66983"
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "SENILE CATARACT", :medical_case_type => "INTENSIVE CASE", :case_rate => @@case_rate,:case_rate_type => "SURGICAL", :with_operation => true, :rvu_code => @@case_rate, :compute => true)
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

    @@orders = @ancillary.merge(@drugs).merge(@operation)
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

  it "1st Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph1[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "1st Availment : Checks if the actual operation benefit claim is correct" do
#    if slmc.get_value("rvu.code").empty? == false
#      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
#      if @@actual_operation_charges > @@operation_ph_benefit[:max_amt].to_f
#        @@actual_operation_benefit_claim1 = @@actual_operation_charges
#      else
#        @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:min_amt].to_f
#      end
#    else
      @@actual_operation_benefit_claim1 = 0.00
#    end
#    @@ph1[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
if slmc.get_value("rvu.code") == "66983"
 (@@ph1[:or_actual_operation_benefit_claim].to_f).should == @@actual_operation_benefit_claim1
end
 end

  it "1st Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph1[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "1st Availment : Checks if the actual benefit claim for drugs/medicine is correct" do # 1st availment is no longer a special case
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("66983")
    @@max_amount = @@special_case_value - @@actual_operation_benefit_claim1
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
#    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
#        @@actual_medicine_benefit_claim1 = @@comp_drugs_total
#      else
#        @@actual_medicine_benefit_claim1 = @@max_amount
          @@actual_medicine_benefit_claim1 = 0.00
#    end
#    (@@ph1[:or_actual_medicine_benefit_claim].to_f).should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
        (@@ph1[:or_actual_medicine_benefit_claim].to_f).should ==@@actual_medicine_benefit_claim1
  end

  it "1st Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph1[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "1st Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    @@max_amount = @@max_amount - @@actual_medicine_benefit_claim1
#    if @@actual_comp_xray_lab_others < @@max_amount
#      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
#    else
#      @@actual_lab_benefit_claim1 = @@max_amount
      @@actual_lab_benefit_claim1 = 0.00
#    end
    #@ph1[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@ph1[:or_actual_lab_benefit_claim].should == @@actual_lab_benefit_claim1
  end

  it "1st Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph1[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "1st Availment : Checks if the total actual benefit claim is correct" do

        Database.connect
              a =  "SELECT RATE FROM SLMC.REF_PBA_PH_CASE_RATE WHERE CARE_RATE_NO ='#{@@case_rate}'"
              aa = Database.select_statement a
        Database.logoff
 #   @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1
 rate = aa.to_f - 6400
    @@total_actual_benefit_claim = rate.to_f
    puts"@@total_actual_benefit_claim - #{@@total_actual_benefit_claim}"
    ((slmc.truncate_to((@@ph1[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "1st Availment : Checks if the maximum benefits are correct" do
    @@ph1[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph1[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "1st Availment : Checks if Deduction Claims are correct" do
    @@ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
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

  it "1st Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("66983")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph1[:surgeon_benefit_claim] != ("%0.2f" %(@@surgeon_claim))
      @@ph1[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph1[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "1st Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph1[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph1[:anesthesiologist_benefit_claim].should == ("%0.2f" %(0)) #8000.0 fixed to 0 for anesthesiologist
    else
      @@ph1[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "1st Availment : PhilHealth benefit claim shall reflect in Payment details only saved as Final" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should_not == ("%0.2f" %(@@ph1[:or_total_actual_benefit_claim]))
  end

  it "1st Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "1st Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login("sel_or3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "1st Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "2nd Availment : Cataract Package - Claim Type: Refund" do
    sleep 6
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs2.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary2.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "SHARPLAN-EYE (DCR-EXTERNAL)")
    slmc.add_returned_service(:item_code => @@item_code, :description => "SHARPLAN-EYE (DCR-EXTERNAL)")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true)
    sleep 6
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph2 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "SENILE CATARACT", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "66983", :case_rate => "66983",:case_rate_type => "SURGICAL",:compute => true)
    slmc.ph_save_computation
  end

  it "2nd Availment : Check Benefit Summary totals" do
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

    @@orders = @ancillary2.merge(@drugs2).merge(@operation2)
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

  it "2nd Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph2[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "2nd Availment : Checks if the actual operation benefit claim is correct" do
   if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
      if @@actual_operation_charges > @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim2 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim2 = 0.00
    end
    @@ph2[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "2nd Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph2[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "2nd Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("66983")
    @@max_amount = @@special_case_value - @@actual_operation_benefit_claim2
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim2 = @@comp_drugs_total
      else
        @@actual_medicine_benefit_claim2 = @@max_amount
    end
    @@ph2[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
  end

  it "2nd Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph2[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "2nd Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    @@max_amount = @@max_amount - @@actual_medicine_benefit_claim1
    if @@actual_comp_xray_lab_others < @@max_amount
      @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim2 = @@max_amount
    end
    @@ph2[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
  end

  it "2nd Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph2[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "2nd Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2
    ((slmc.truncate_to((@@ph2[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "2nd Availment : Checks if the maximum benefits are correct" do
    @@ph2[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph2[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "2nd Availment : Checks if Deduction Claims are correct" do
    @@ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
    @@ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    @@ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "2nd Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim2 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim2 - @@actual_medicine_benefit_claim1
    else
      @@drugs_remaining_benefit_claim2 = 0.0
    end
    @@ph2[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim2))

    if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim2 - @@actual_lab_benefit_claim1
    else
      @@lab_remaining_benefit_claim2 = 0.0
    end
   # @@ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim2))
    (@@ph2[:lab_remaining_benefit_claims].to_f - ("%0.2f" %(@@lab_remaining_benefit_claim2)).to_f).should <= 0.03
  end

  it "2nd Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph2[:surgeon_benefit_claim] != ("%0.2f" %(@@surgeon_claim))
      @@ph2[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph2[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "2nd Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph2[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph2[:anesthesiologist_benefit_claim].should == ("%0.2f" %(0.0)) #8000.0 # set to 0.0 if case is cataract only
    else
      @@ph2[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "2nd Availment : Claim Type should be Refund" do
    slmc.get_selected_label("claimType").should == "REFUND"
  end

  it "2nd Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "2nd Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login("sel_or3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "2nd Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "3rd Availment : Normal Spontaneous Delivery Package - Claim Type: Accounts Receivable" do
    sleep 6
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs3.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary3.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    sleep 6
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin  => @@or_pin, :visit_no => @@visit_no)
    @@ph3 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "59400", :compute => true)
#    @@ph3 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "SENILE CATARACT", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "59400", :compute => true)
    slmc.ph_save_computation
  end

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

    @@orders = @drugs3.merge(@ancillary3)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph3[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "3rd Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < (@@med_ph_benefit[:max_amt].to_f)
      @@actual_medicine_benefit_claim3 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim3 = (@@med_ph_benefit[:max_amt].to_f)
    end
    @@ph3[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
  end

  it "3rd Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph3[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "3rd Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph3[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
  end

  it "3rd Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = 0.0
    @@ph3[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "3rd Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim3 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:max_amt].to_f
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
    @@ph3[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "3rd Availment : Checks if Deduction Claims are correct" do
    @@ph3[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
    @@ph3[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
    @@ph3[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "3rd Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim3 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3
    else
      @@drugs_remaining_benefit_claim3 = 0.0
    end
    @@ph3[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim3))

    if @@actual_lab_benefit_claim3 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3
    else
      @@lab_remaining_benefit_claim3 = 0
    end
    @@ph3[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim3))
  end

  it "3rd Availment : PhilHealth benefit claim shall reflect in Payment details only saved as Final" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should_not == @@ph3[:or_total_actual_benefit_claim].to_f
  end

  it "3rd Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment(:discount_rate => "50.00", :discount_scheme => "ACROSS THE BOARD")
  end

  it "3rd Availment : Prints Gate Pass of the patient" do
    slmc.login("sel_or3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "3rd Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "4th Availment : Normal Spontaneous Delivery Package - Claim Type: Refund" do
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs4.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary4.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph4 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "59401", :compute => true)
    slmc.ph_save_computation
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.is_editable("claimType").should be_false
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

    @@orders = @drugs4.merge(@ancillary4)
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
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph4[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "4th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim4 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3)
    end
    @@ph4[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
  end

  it "4th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph4[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "4th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
#    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)
      if @@actual_comp_xray_lab_others > @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)

      @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)
    end
    @@ph4[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
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
    @@ph4[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "4th Availment : Checks if Deduction Claims are correct" do
    @@ph4[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    @@ph4[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    @@ph4[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "4th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim4 = 0.0
    end
    @@ph4[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim4))

    if @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim4 = 0
    end
    @@ph4[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim4))
  end

  it "4th Availment : Claim Type should be Refund" do
    slmc.get_selected_label("claimType").should == "REFUND"
  end

  it "4th Availment : User should have an option either Hospital or Patient" do
    slmc.ph_print_report.should be_true
  end

  it "4th Availment : Prints Gate Pass of the patient" do
    slmc.login("sel_or3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "4th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "5th Availment : Newborn Package Claim Type: Accounts Receivable" do
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @ancillary5.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @others5.each do |item, q|
      slmc.search_order(:description => item, :others => true).should be_true
      slmc.add_returned_order(:others => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:others => 3).should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:others => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph5 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
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

    @@orders = @ancillary5.merge(@others5)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph5[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "5th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total == 0.0
      @@actual_medicine_benefit_claim5 = 0.0
    elsif @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim5 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph5[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
  end

  it "5th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph5[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "5th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim5 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
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
    if @@actual_medicine_benefit_claim5 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim5 = 0.0
    end
    @@ph5[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim5))

    if @@actual_lab_benefit_claim5 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim5 = 0
    end
    @@ph5[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim5))
  end

  it "5th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 4
  end

  it "5th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "5th Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "5th Availment : Prints Gate Pass of the patient" do
    slmc.login("sel_or3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "5th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "6th Availment : New born Package Claim Type: Refund" do
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @ancillary6.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @others6.each do |item, q|
      slmc.search_order(:description => item, :others => true).should be_true
      slmc.add_returned_order(:others => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:others => 3).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:others => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph6 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.ph_save_computation
    slmc.is_editable("claimType").should be_false
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

    @@orders = @ancillary6.merge(@others6)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph6[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "6th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim6 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim6 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph6[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim6))
  end

  it "6th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph6[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "6th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim6 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim6 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph6[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim6))
  end

  it "6th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph6[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "6th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
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
      @@drugs_remaining_benefit_claim6 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim6 = 0.0
    end
    @@ph6[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim6))

    if @@actual_lab_benefit_claim6 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim6 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim6 = 0
    end
    @@ph6[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim6))
  end

  it "6th Availment : Claim Type should be Refund" do
    slmc.get_selected_label("claimType").should == "REFUND"
  end

  it "6th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 4
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
    slmc.login("sel_or3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "6th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "7th Availment : Endoscopic Procedure - Claim Type: Accounts Receivable" do
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs7.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
                              :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary7.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@item_code, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph7 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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

    @@orders = @drugs7.merge(@ancillary7).merge(@operation7)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph7[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "7th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim7 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim7 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph7[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
  end

  it "7th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph7[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "7th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim7 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim7 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph7[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
  end

  it "7th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph7[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "7th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
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
    @@ph7[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "7th Availment : Checks if Deduction Claims are correct" do
    @@ph7[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
    @@ph7[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
    @@ph7[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
  end

  it "7th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim7 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim7 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim7 = 0.0
    end
    @@ph7[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim7))

    if @@actual_lab_benefit_claim7 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim7 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim7 = 0
    end
    @@ph7[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim7))
  end

  it "7th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph7[:surgeon_benefit_claim] != ("%0.2f" %(@@surgeon_claim))
      @@ph7[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph7[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "7th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph7[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph7[:anesthesiologist_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph7[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "7th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 3
  end

  it "7th Availment  PhilHealth benefit claim shall reflect in Payment details when saved as Final" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    slmc.get_philhealth_amount.should_not == ("%0.2f" %(@@ph7[:or_total_actual_benefit_claim]))
  end

  it "7th Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "7th Availment : Prints Gate Pass of the patient" do
    slmc.login("sel_or3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "7th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "8th Availment : Endoscopic Procedure - Claim Type: Refund" do
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs8.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
                              :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary8.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.verify_ordered_items_count(:drugs => 1)
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph8 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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

    @@orders = @drugs8.merge(@ancillary8)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph8[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "8th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim8 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim8 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph8[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
  end

  it "8th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph8[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "8th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim8 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim8 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph8[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
  end

  it "8th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph8[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "8th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim8 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim8 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph8[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
    else
      @@actual_operation_benefit_claim8 = 0.00
      @@ph8[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
    end
  end

  it "8th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph8[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "8th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim8 + @@actual_lab_benefit_claim8 + @@actual_operation_benefit_claim8
    ((slmc.truncate_to((@@ph8[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "8th Availment : Checks if the maximum benefits are correct" do
    @@ph8[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph8[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph8[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "8th Availment : Checks if Deduction Claims are correct" do
    @@ph8[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
    @@ph8[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
    @@ph8[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
  end

  it "8th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim8 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim8 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim8 = 0.0
    end
    @@ph8[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim8))

    if @@actual_lab_benefit_claim8 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim8 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim8 = 0
    end
    @@ph8[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim8))
  end

  it "8th Availment : Claim Type should be Refund" do
    slmc.get_selected_label("claimType").should == "REFUND"
  end

  it "8th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 2
  end

  it "8th Availment : Prints Gate Pass of the patient" do
    slmc.login("sel_or3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "8th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "9th Availment : Radiation Oncology - Claim Type: Accounts Receivable" do
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs9.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
                              :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary9.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1)
    slmc.verify_ordered_items_count(:ancillary => 3)
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph9 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
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

    @@orders = @drugs9.merge(@ancillary9)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph9[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "9th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim9 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim9 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph9[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim9))
  end

  it "9th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph9[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "9th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim9 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim9 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph9[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim9))
  end

  it "9th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))

    @@ph9[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))

  end

  it "9th Availment : Checks if the actual operation benefit claim is correct" do
    @@sessions = 3
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
    if @@sessions
      @@actual_operation_benefit_claim9 = @@operation_ph_benefit[:max_amt].to_f * @@sessions
    else
      @@actual_operation_benefit_claim9 = 0.0
    end
    @@ph9[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim9))
  end

  it "9th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
puts"    total_actual_charges#{total_actual_charges} = @@actual_medicine_charges#{@@actual_medicine_charges} + @@actual_xray_lab_others #{@@actual_xray_lab_others}+ @@actual_operation_charges#{@@actual_operation_charges}"
((slmc.truncate_to((@@ph9[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
a = @@ph9[:or_total_actual_charges].to_f
    puts"@@ph9[:or_total_actual_charges#{a}"
    puts "total_actual_charges#{total_actual_charges}"
  end


  it "9th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim9 + @@actual_lab_benefit_claim9 + @@actual_operation_benefit_claim9
    ((slmc.truncate_to((@@ph9[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "9th Availment : Checks if the maximum benefits are correct" do
    @@ph9[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph9[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "9th Availment : Checks if Deduction Claims are correct" do
    @@ph9[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim9))
    @@ph9[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim9))
    @@ph9[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim9))
  end

  it "9th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim9 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim9 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim9 + @@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim9 = 0.0
    end
    @@ph9[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim9))

    if @@actual_lab_benefit_claim9 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim9 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim9 + @@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim9 = 0
    end
    @@ph9[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim9))
  end

  it "9th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 4
  end

  it "9th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report
  end

   it "9th Availment : PhilHealth benefit claim shall reflect in Payment details only saved as Final" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    (slmc.get_philhealth_amount == @@ph9[:or_total_actual_benefit_claim].to_f).should be_false
  end

  it "9th Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "9th Availment : Prints Gate Pass of the patient" do
    slmc.login("sel_or3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "9th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "10th Availment : Radiation Oncology - Claim Type : Refund"  do
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs10.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
                              :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary10.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.verify_ordered_items_count(:drugs => 1)
    slmc.verify_ordered_items_count(:ancillary => 3)
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@item_code, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "POWER BONE SHAVING")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@ph10 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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

    @@orders = @drugs10.merge(@ancillary10).merge(@operation10)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph10[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "10th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim9 + @@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim10 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim10 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim9 + @@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph10[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
  end

  it "10th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph10[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "10th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim9 + @@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim10 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim10 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim9 + @@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph10[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
  end

  it "10th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph10[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "10th Availment : Checks if the actual operation benefit claim is correct" do
    @@sessions = 3
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
    if @@sessions
      @@actual_operation_benefit_claim10 = @@operation_ph_benefit[:max_amt].to_f * @@sessions
    else
      @@actual_operation_benefit_claim10 = 0.0
    end
    @@ph10[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
  end

  it "10th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph10[:or_total_actual_charges].to_f - (total_actual_charges).to_f),2).to_f).abs).should <= 0.01
  end

  it "10th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim10 + @@actual_lab_benefit_claim10 + @@actual_operation_benefit_claim10
    ((slmc.truncate_to((@@ph10[:or_total_actual_benefit_claim].to_f - (@@total_actual_benefit_claim).to_f),2).to_f).abs).should <= 0.01
  end

  it "10th Availment : Checks if the maximum benefits are correct" do
    @@ph10[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph10[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "10th Availment : Checks if Deduction Claims are correct" do
    @@ph10[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
    @@ph10[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
    @@ph10[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
  end

  it "10th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim10 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim10 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim9 + @@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim10 = 0.0
    end
    @@ph10[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim10))

    if @@actual_lab_benefit_claim10 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim10 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim10 + @@actual_lab_benefit_claim9 + @@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim10 = 0
    end
    @@ph10[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim10))
  end

  it "10th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph10[:surgeon_benefit_claim] != ("%0.2f" %(@@surgeon_claim))
      @@ph10[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph10[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "10th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph10[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph10[:anesthesiologist_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph10[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "10th Availment : Claim Type should be Refund" do
    slmc.get_selected_label("claimType").should == "REFUND"
  end

  it "10th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 6
  end

  it "10th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "10th Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "10th Availment : Prints Gate Pass of the patient" do
    slmc.login("sel_or3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "10th Availment : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

end 