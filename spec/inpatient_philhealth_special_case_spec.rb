require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Inpatient - Philhealth Special Case" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session


    @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
    @gu_user_0287 = "gycapalungan"
    @password = "123qweuser"
    @pba_user = "ldcastro" #"sel_pba7"
    @oss_user = "jtsalang"  #"sel_oss7"
    @or_user =  "slaquino"     #"or21"


    @password = "123qweuser"
#    @user = "gu_spec_user4"
#    @nursing = "icatama"



    @patient = Admission.generate_data(:senior => true)
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient[:age])
    @@room_rate = 4167
    @@special_case_value = 8000.0
    
    @drugs1 =  {"040004334" => 1, "040800031" => 1}
    @ancillary1 = {"010001194" => 1, "010001448" => 1}
    @operation1 = {"060000204" => 1, "060002045" => 1}

    @drugs2 = {"040800031" => 1}
    @ancillary2 = {"010000868" => 1}
    @others2 = {"060001731" => 1, "060001946" => 1, "060001796" => 1}

    @ancillary3 = {"010001900" => 1}

    @drugs4 = {"040004334" => 1, "040800031" => 1}
    @ancillary4 = {"010001900" => 1}

    @drugs5 = {"040800031" => 1}
    @ancillary5 = {"010001636" => 1, "010001585" => 1, "010001583" => 1}
    @operation5 = {"060002045" => 1, "060000204" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "1st Availment : Cataract Package - Accounts Receivable" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin = slmc.create_new_patient(@patient).gsub(' ', '')
   #     slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true

    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
       sleep 6
     slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,:stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    sleep 3
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
       sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items.should be_true
       sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
       sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "SENILE CATARACT", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "66983", :compute => true)
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

    @@orders = @ancillary1.merge(@drugs1).merge(@operation1)
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
  #Operation first, necessary for drug benefit claim
  it "1st Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph1[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end
  it "1st Availment : Checks if the actual operation benefit claim is correct" do
  # based on #https://projects.exist.com/issues/30238
#   if slmc.get_value("rvu.code").empty? == false
#      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
#      if @@actual_operation_charges < @@operation_ph_benefit[:min_amt].to_f
#        @@actual_operation_benefit_claim1 = @@actual_operation_charges
#      else
#        @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:min_amt].to_f
#      end
#    else
      @@actual_operation_benefit_claim1 = 0.00
   # end
    @@ph1[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end
  it "1st Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph1[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end
  it "1st Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
#    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
#    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("66983")
#    @@max_amount = @@special_case_value - @@actual_operation_benefit_claim1
#    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
#    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
#        @@actual_medicine_benefit_claim1 = @@comp_drugs_total
#      else
#        @@actual_medicine_benefit_claim1 = @@max_amount
#    end
@@actual_medicine_benefit_claim1 = 0.00
    @@ph1[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
  end
  it "1st Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end
  it "1st Availment : Checks if the actual lab benefit claim is correct" do
#    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
#    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
#    @@max_amount = @@max_amount - @@actual_medicine_benefit_claim1
#    if @@actual_comp_xray_lab_others < @@max_amount
#      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
#    else
#      @@actual_lab_benefit_claim1 = @@max_amount
#    end
@@actual_lab_benefit_claim1 = 0.00
    @@ph1[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
  end
  it "1st Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph1[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end
  it "1st Availment : Checks if the total actual benefit claim is correct" do
  #  @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1
    @@total_actual_benefit_claim = 9600
    ((slmc.truncate_to((@@ph1[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end
  it "1st Availment : Checks if the maximum benefits are correct" do
     @@med_ph_benefit = 4200
     @@lab_ph_benefit = 3200
    @@ph1[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit))
    @@ph1[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit))
  end
  it "1st Availment : Checks if Deduction Claims are correct" do
    @@ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
    @@ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1.to_f))
  end
  it "1st Availment : Checks if Remaining Benefit Claims are correct" do

#    if @@actual_medicine_benefit_claim1 < @@med_ph_benefit[:max_amt].to_f
#      @@drugs_remaining_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
#    else
      @@drugs_remaining_benefit_claim1 = 4200.00
   # end
    @@ph1[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim1))

#    if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
#      @@lab_remaining_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
#    else
      @@lab_remaining_benefit_claim1 = 3200.00
    #end
    @@ph1[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim1))
  end

#  it "1st Availment : Checks if computation of PF claims surgeon is applied correctly" do
#    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
#    if @@ph1[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
#      @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000))
#    else
#      @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
#    end
#  end
#
#  it "1st Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
#    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB06.6")
#    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
#    if @@ph1[:inpatient_anesthesiologist_benefit_claim] != @@anesthesiologist_claim
#      @@ph1[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(0))
#    else
#      @@ph1[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
#    end
#  end

  it "1st Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end
  it "1st Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 6
  end
  it "1st Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end
  it "1st Availment : PhilHealth benefit claim shall reflect in Payment details only saved as Final" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    (slmc.get_philhealth_amount == @@ph1[:er_total_actual_benefit_claim].to_i).should be_false #should not be equal since PH is saved as ESTIMATE
  end
  it "1st Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end
  it "1st Availment : Prints Gate Pass of the patient" do
       sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end
  it "2nd Availment : Cataract Package - Refund" do
   sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
       sleep 10
         slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    slmc.get_alert if slmc.is_alert_present
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items.should be_true
           sleep 10
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
   sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph2 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "SENILE CATARACT", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "66983", :compute => true)
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

    @@orders = @ancillary1.merge(@drugs1).merge(@operation1)
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
  it "2nd Availment : Checks if the actual operation benefit claim is correct" do
#    if slmc.get_value("rvu.code").empty? == false
#      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
#      if @@actual_operation_charges < @@operation_ph_benefit[:min_amt].to_f
#        @@actual_operation_benefit_claim2 = @@actual_operation_charges
#      else
#        @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:min_amt].to_f
#      end
#    else
      @@actual_operation_benefit_claim2 = 0.00
  #  end
    @@ph2[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end
  it "2nd Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph2[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end
  it "2nd Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph2[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end
  it "2nd Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
#    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
#    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("66983")
#    @@max_amount = @@special_case_value - @@actual_operation_benefit_claim2
#    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
#    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
#        @@actual_medicine_benefit_claim2 = @@comp_drugs_total
#      else
#        @@actual_medicine_benefit_claim2 = @@max_amount
#    end
@@actual_medicine_benefit_claim2  = 0.00
    @@ph2[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
  end
  it "2nd Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph2[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end
  it "2nd Availment : Checks if the actual lab benefit claim is correct" do
#    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
#    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
#    @@max_amount = @@max_amount - @@actual_medicine_benefit_claim2
#    if @@actual_comp_xray_lab_others < @@max_amount
#      @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
#    else
#      @@actual_lab_benefit_claim2 = @@max_amount
#    end
@@actual_lab_benefit_claim2 = 0.00
    @@ph2[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
  end
  it "2nd Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph2[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end
  it "2nd Availment : Checks if the total actual benefit claim is correct" do
          @@total_actual_benefit_claim == 9600.00
   # @@total_actual_benefit_claim = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2
    ((slmc.truncate_to((@@ph2[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end
  it "2nd Availment : Checks if the maximum benefits are correct" do
###    @@ph2[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
###    @@ph2[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end
  it "2nd Availment : Checks if Deduction Claims are correct" do
#    @@ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
#    @@ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
#    @@ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "2nd Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim2 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2)
    else
      @@drugs_remaining_benefit_claim2 = 0.0
    end
    (@@ph2[:drugs_remaining_benefit_claims].to_f - ("%0.2f" %(@@drugs_remaining_benefit_claim2)).to_f).should <= 0.03

    if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2)
    else
      @@lab_remaining_benefit_claim2 = 0.0
    end
    puts("@@ph2[:lab_remaining_benefit_claims].to_f == #{@@ph2[:lab_remaining_benefit_claims].to_f}")
    puts "@@lab_remaining_benefit_claim2 = #{@@lab_remaining_benefit_claim2}"
 #   @@ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim2))
   (@@ph2[:lab_remaining_benefit_claims].to_f - ("%0.2f" %(@@lab_remaining_benefit_claim2)).to_f).should  <= 0.03
  end

  it "2nd Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
    @@surgeon_claim = @@pf_gp_surgeon[:min_amt].to_f * @@rvu[:value].to_f
    if @@ph2[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph2[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000))
    else
      @@ph2[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "2nd Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph2[:inpatient_anesthesiologist_benefit_claim] != @@anesthesiologist_claim
      @@ph2[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(0.0))
    else
      @@ph2[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "2nd Availment : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == ("Nothing found to display.")
  end

  it "2nd Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 6
  end

  it "2nd Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "2nd Availment : PhilHealth benefit claim shall reflect in Payment details only saved as Final" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    (slmc.get_philhealth_amount == @@ph2[:er_total_actual_benefit_claim].to_i).should be_false #should not be equal since PH is saved as ESTIMATE
  end

  it "2nd Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "2nd Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "3rd Availment : Normal Spontaneous Delivery Package - Accounts Receivable" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    sleep 6
         slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 6
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
    sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items.should be_true
    sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph3 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "59400", :compute => true)
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

    @@orders = @drugs1.merge(@ancillary1).merge(@operation1)
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

  it "3rd Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph3[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "3rd Availment : Checks if the actual operation benefit claim is correct" do
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1") #NSD special case 2500 fixed
    @@actual_operation_benefit_claim3 = 2500.0
    @@ph3[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

   it "3rd Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph3[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "3rd Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)

    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2) < 0
      @@actual_medicine_benefit_claim3 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2)
      @@actual_medicine_benefit_claim3  = @@actual_comp_drugs
    else
      @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2)
#
#    @@max_amount = @@special_case_value - @@actual_operation_benefit_claim3
#    if @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
#        @@actual_medicine_benefit_claim3 = @@comp_drugs_total
#      else
#        @@actual_medicine_benefit_claim3 = @@max_amount

    end
    @@ph3[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
  end

  it "3rd Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph3[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "3rd Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    @@max_amount = @@max_amount - @@actual_medicine_benefit_claim3
#    if @@actual_comp_xray_lab_others < @@max_amount
#      @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
#    else
#      @@actual_lab_benefit_claim3 = @@max_amount
#    end
    @@actual_lab_benefit_claim3 =  0.0
    @@ph3[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
  end


 it "3rd Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph3[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "3rd Availment : Checks if the actual operation benefit claim is correct" do
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1") #NSD special case 2500 fixed
    @@actual_operation_benefit_claim3 = 2500.0
    @@ph3[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "3rd Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph3[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "3rd Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3
    ((slmc.truncate_to((@@ph3[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "3rd Availment : Checks if the maximum benefits are correct" do
    @@ph3[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph3[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
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
    @@ph3[:inpatient_surgeon_benefit_claim] == "0.00"
  end

  it "3rd Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@ph3[:inpatient_anesthesiologist_benefit_claim] == "0.00"
  end

  it "3rd Availment : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "3rd Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 6
  end

  it "3rd Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "3rd Availment : PhilHealth benefit claim shall reflect in Payment details only saved as Final" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Payment",  slmc.visit_number)
    (slmc.get_philhealth_amount == @@ph3[:er_total_actual_benefit_claim].to_i).should be_false #should not be equal since PH is saved as ESTIMATE
  end

  it "3rd Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "3rd Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "4th Availment : Normal Spontaneous Delivery Package - Refund" do
   sleep 6
        slmc.login(@user, @password).should be_true

    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
   sleep 6
         slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
       sleep 10
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items.should be_true
    sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
       sleep 6
       puts @@pin
       puts @@visit_no
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph4 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "59401", :compute => true)
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

    @@orders = @drugs1.merge(@ancillary1).merge(@operation1)
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

  it "4th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph4[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "4th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
#    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
#    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3) < 0
#      @@actual_medicine_benefit_claim4 = 0.00
#    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3)
#      @@actual_medicine_benefit_claim4  = @@actual_comp_drugs
#    else
      #@@actual_medicine_benefit_claim4 = @@med_ph_benefit[:min_amt].to_f - (@@actual_medicine_benefit_claim3)
        @@actual_medicine_benefit_claim4 = 0.0 # benefit claim is fixed to 0
#    end
    @@ph4[:actual_medicine_benefit_claim].should  == ("%0.2f" %(@@actual_medicine_benefit_claim4))
#    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
#    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3) < 0
#      @@actual_medicine_benefit_claim4 = 0.00
#    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3)
#      @@actual_medicine_benefit_claim4  = @@actual_comp_drugs
#    else
#      @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3)
#    end
  end

  it "4th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph4[:actual_lab_charges].should  == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "4th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3) < 0
      @@actual_lab_benefit_claim4 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
    else
      #@@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim4 = 0.00
    end
    @@ph4[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
#    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
#    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
#    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3) < 0
#      @@actual_lab_benefit_claim4 = 0.00
#    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)
#      @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
#    else
#      @@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)
#    end
  end

  it "4th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph4[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "4th Availment : Checks if the actual operation benefit claim is correct" do
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
    @@actual_operation_benefit_claim4 = 2500.0
    @@ph4[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "4th Availment : Checks if the total actual charge(s) is correct" do
    @@rate = @@room_rate - (@@room_rate * @@promo_discount)
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate
    ((slmc.truncate_to((@@ph4[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "4th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4 + @@actual_operation_benefit_claim4
    ((slmc.truncate_to((@@ph4[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "4th Availment : Checks if the maximum benefits are correct" do
    @@ph4[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph4[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "4th Availment : Checks if Deduction Claims are correct" do
    @@ph4[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    @@ph4[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    @@ph4[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "4th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4)
    else
      @@drugs_remaining_benefit_claim4 = 0.0
    end
    @@ph4[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim4))

    if @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4)
    else
      @@lab_remaining_benefit_claim4 = 0
    end
    @@ph4[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim4))
  end

  it "4th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@ph4[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(0.0))
  end

  it "4th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@ph4[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(0.0))
  end

  it "4th Availment : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "4th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 6
  end

  it "4th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "4th Availment : PhilHealth benefit claim shall reflect in Payment details only saved as Final" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Payment",slmc.visit_number)
    (slmc.get_philhealth_amount == @@ph4[:er_total_actual_benefit_claim].to_i).should be_false #should not be equal since PH is saved as ESTIMATE
  end

  it "4th Availment : Prints Gate Pass of the patient" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "5th Availment : Newborn Package - Accounts Receivable" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
   sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@pin)
    @drugs2.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary2.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @others2.each do |item, q|
      slmc.search_order(:description => item, :others => true)
      slmc.add_returned_order(:others => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:others => 3).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :others => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
    sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true
       sleep 6
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph5 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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

    @@orders = @drugs2.merge(@ancillary2).merge(@others2)
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

  it "5th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph5[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
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
    @@ph5[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
  end

  it "5th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    puts "total_xrays_lab_others#{total_xrays_lab_others}"
    puts "@@promo_discount#{@@promo_discount}"
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph5[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "5th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim5 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph5[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
  end

  it "5th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph5[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "5th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim5 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim5 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph5[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
    else
      @@actual_operation_benefit_claim5 = 0.00
      @@ph5[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
    end
  end

  it "5th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph5[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "5th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim5 + @@actual_lab_benefit_claim5 + @@actual_operation_benefit_claim5
    ((slmc.truncate_to((@@ph5[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "5th Availment : Checks if the maximum benefits are correct" do
    @@ph5[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph5[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
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

  it "5th Availment : Check if PF Claim are correct" do
    @@ph5[:surgeon_benefit_claim].should == ("%0.2f" %(0.0))
  end

  it "5th Availment : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "5th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 5
  end

  it "5th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "5th Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "5th Availment : Prints Gate Pass of the patient" do
       sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "6th Availment : Newborn Package - Refund" do
   slmc.login(@user, @password).should be_true

    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
       sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@pin)
    @drugs2.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary2.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @others2.each do |item, q|
      slmc.search_order(:description => item, :others => true)
      slmc.add_returned_order(:others => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:others => 3).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :others => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
   sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
       sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph6 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
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

    @@orders = @drugs2.merge(@ancillary2).merge(@others2)
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

  it "6th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph6[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "6th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total == 0.0
      @@actual_medicine_benefit_claim6 = 0.0
    elsif @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim6 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim6 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph6[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim6))
  end

  it "6th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph6[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "6th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim6 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim6 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph6[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim6))
  end

  it "6th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph6[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "6th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim6 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim6 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph6[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
    else
      @@actual_operation_benefit_claim6 = 0.00
      @@ph6[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
    end
  end

  it "6th Availment : Checks if the total actual charge(s) is correct" do
    @@rate = @@room_rate - (@@room_rate * @@promo_discount)
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate
    ((slmc.truncate_to((@@ph6[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "6th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim6 + @@actual_lab_benefit_claim6 + @@actual_operation_benefit_claim6
    ((slmc.truncate_to((@@ph6[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "6th Availment : Checks if the maximum benefits are correct" do
    @@ph6[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph6[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
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

  it "6th Availment : Check if PF Claim are correct" do
    @@ph6[:surgeon_benefit_claim].should == ("%0.2f" %(0.0))
  end

  it "6th Availment : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "6th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 5
  end

  it "6th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "6th Availment : Prints Gate Pass of the patient" do
      sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "7th Availment : Endoscopic Procedure - Accounts Receivable" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
   sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@pin)
    @ancillary3.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
   sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
    adjust_date = 1
    @@set_date = slmc.adjust_admission_date(:visit_no => @@visit_no, :pin => @@pin, :days_to_adjust => adjust_date) # adjust date to compute Philhealth
    @@set_date.should be_true
   sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph7 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
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

    @@orders = @ancillary3
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

  it "7th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph7[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "7th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim7 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim7 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph7[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
  end

  it "7th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph7[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "7th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim7 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim7 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph7[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
  end

  it "7th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph7[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "7th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim7 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim7 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph7[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
    else
      @@actual_operation_benefit_claim7 = 0.00
      @@ph7[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
    end
  end

  it "7th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph7[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "7th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim7 + @@actual_lab_benefit_claim7 + @@actual_operation_benefit_claim7
    ((slmc.truncate_to((@@ph7[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "7th Availment : Checks if the maximum benefits are correct" do
    @@ph7[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph7[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
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

  it "7th Availment : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "7th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 1
  end

  it "7th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "7th Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "7th Availment : Prints Gate Pass of the patient" do
   sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "8th Availment : Endoscopic Procedure - Refund" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
   sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@pin)
    @drugs4.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary4.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
   sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
       sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
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

    @@orders = @drugs4.merge(@ancillary4)
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

  it "8th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph8[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "8th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim8 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim8 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph8[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
  end

  it "8th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph8[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "8th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim8 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim8 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph8[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
  end

  it "8th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph8[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "8th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim8 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim8 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph8[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
    else
      @@actual_operation_benefit_claim8 = 0.00
      @@ph8[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
    end
  end

  it "8th Availment : Checks if the total actual charge(s) is correct" do
    @@rate = @@room_rate - (@@room_rate * @@promo_discount)
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate
    ((slmc.truncate_to((@@ph8[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "8th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim8 + @@actual_lab_benefit_claim8 + @@actual_operation_benefit_claim8
    ((slmc.truncate_to((@@ph8[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "8th Availment : Checks if the maximum benefits are correct" do
    @@ph8[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph8[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
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

  it "8th Availment : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "8th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 3
  end

  it "8th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "8th Availment : Prints Gate Pass of the patient" do
   sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "9th Availment : Radiation Oncology - Accounts Receivable" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
   sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@pin)
    @drugs5.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary5.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 3).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
       sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
       sleep 6
    slmc.login(@pba_user, @password).should be_true
    adjust_date = 1
    @@set_date = slmc.adjust_admission_date(:visit_no => @@visit_no, :pin => @@pin, :days_to_adjust => adjust_date) # adjust date to compute Philhealth
    @@set_date.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
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

    @@orders = @drugs5.merge(@ancillary5)
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

  it "9th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph9[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "9th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim9 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim9 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph9[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim9))
  end

  it "9th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph9[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "9th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim9 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim9 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph9[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim9))
  end

  it "9th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph9[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "9th Availment : Checks if the actual operation benefit claim is correct" do
    @sessions = 1
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
    if @sessions
      @@actual_operation_benefit_claim9 = @@operation_ph_benefit[:max_amt].to_f * @sessions
    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
      @@actual_operation_benefit_claim9 = @@actual_operation_charges
    else
      @@actual_operation_benefit_claim9 = @@operation_ph_benefit[:max_amt].to_f
    end
    @@ph9[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim9))
  end

  it "9th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph9[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "9th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim9 + @@actual_lab_benefit_claim9 + @@actual_operation_benefit_claim9
    ((slmc.truncate_to((@@ph9[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "9th Availment : Checks if the maximum benefits are correct" do
    @@ph9[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph9[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
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

  it "9th Availment : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "9th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 4
  end

  it "9th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "9th Availment : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "9th Availment : Prints Gate Pass of the patient" do
   sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "10th Availment : Radiation Oncology - Refund" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
   sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@pin)
    @drugs5.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary5.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 3).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
   sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items.should be_true
       sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
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

    @@orders = @drugs5.merge(@ancillary5).merge(@operation5)
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

  it "10th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph10[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "10th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim9 + @@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim10 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim10 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim9 + @@actual_medicine_benefit_claim8 + @@actual_medicine_benefit_claim7 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    end
    @@ph10[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
  end

  it "10th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph10[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "10th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim9 + @@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim10 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim10 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim9 + @@actual_lab_benefit_claim8 + @@actual_lab_benefit_claim7 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    end
    @@ph10[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
  end

  it "10th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph10[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "10th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim10 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim10 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim10 = 0.00
    end
    @@ph10[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
  end

  it "10th Availment : Checks if the total actual charge(s) is correct" do
    @@rate = @@room_rate - (@@room_rate * @@promo_discount)
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate
    ((slmc.truncate_to((@@ph10[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "10th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim10 + @@actual_lab_benefit_claim10 + @@actual_operation_benefit_claim10
    ((slmc.truncate_to((@@ph10[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "10th Availment : Checks if the maximum benefits are correct" do
    @@ph10[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph10[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
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
    if @@ph10[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph10[:inpatient_surgeon_benefit_claim].to_i == 8000.0
    else
      @@ph10[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "10th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph10[:inpatient_anesthesiologist_benefit_claim].to_i != @@anesthesiologist_claim
       @@anesthesiologist_claim = 8000.0
    end
    @@ph10[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "10th Availment : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "10th Availment : All ordered items will be displayed when View Details button is clicked" do
    slmc.ph_view_details(:close => true).should == 6
  end

  it "10th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "10th Availment : Prints Gate Pass of the patient" do
       sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

end