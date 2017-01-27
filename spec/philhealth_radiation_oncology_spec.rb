require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

describe "SLMC :: PhilHealth Radiation Oncology Computations" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @patient = Admission.generate_data
    @oss_patient = Admission.generate_data
    @or_patient = Admission.generate_data
    @er_patient = Admission.generate_data
    @dr_patient = Admission.generate_data
    @@promo_discount1 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient[:age])
    @@promo_discount2 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@oss_patient[:age])
    @@promo_discount3 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])
    @@promo_discount4 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@er_patient[:age])
    @@promo_discount5 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@dr_patient[:age])

    @password = "123qweuser"
    #@user = "gu_spec_user6"



    @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
    @gu_user_0287 = "gycapalungan"
    @password = "123qweuser"
    @pba_user = "ldcastro" #"sel_pba7"
    @oss_user = "jtsalang"  #"sel_oss7"
    @or_user =  "slaquino"     #"or21"



    


    @room_rate = 4167.0
    @discount_amount = (@room_rate * @@promo_discount1)
    @room_discount = @room_rate - @discount_amount
    @days1 = 1

    @drugs1 =  {"049000028" => 1, "040950558" => 1}
    @ancillary1 = {"010001636" => 1, "010001585" => 1}
    @operation1 = {"060000204" => 1}

    @oss_ancillary1 = {"010001636" => 1, "010001585" => 1, "010000003" => 1}
    @oss_operation1 = {"010000160" => 1, "010001636" => 1}
    @oss_doctors = ["6726","0126","6726","0126"]

    @or_drugs1 = {"049000028" => 1, "040950558" => 1}
    @or_ancillary1 = {"010001636" => 1, "010001585" => 1, "010000003" => 1}
    @or_operation1 = {"060000204" => 1, "010001636" => 1}

    @er_drugs1 = {"049000028" => 1, "040950558" => 1}
    @er_ancillary1 = {"010001636" => 1, "010001585" => 1}
    @er_operation1 = {"010001636" => 1}

    @dr_drugs1 = {"049000028" => 1, "040950558" => 1}
    @dr_ancillary1 = {"010001636" => 1, "010001585" => 1}
    @dr_operation1 = {"010001636" => 1, "060000204" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

#Inpatient
#Claim Type: Accounts Receivable / Refund
#AMEBIC INFECTION OF OTHER SITES (A06.8)

  it "Inpatient : Accounts Receivable" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin = slmc.create_new_patient(@patient).gsub(' ', '')
        puts @@pin
  #  slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
  end

  it "Inpatient : Orders Procedures" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Inpatient : Clinical Discharge Patient" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true

    puts @@visit_no1 
  end

  it "Inpatient : Database Manipulation - Add and Edit records of patient" do
    @discount_type_code = "C01" if @@promo_discount1 == 0.16
    @discount_type_code = "C02" if @@promo_discount1 == 0.2

    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days1, :pin => @@pin, :visit_no => @@visit_no1)
    Database.connect
    @days1.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no1,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no1, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days1 - i)
    end
    Database.logoff
  end

  it "Inpatient : Go to PhilHealth page and computes PhilHealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "Inpatient : Check Benefit Summary totals" do
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

  it "Inpatient : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount1 * total_drugs)
    @@ph1[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Inpatient : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount1)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim1 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph1[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
  end

  it "Inpatient : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount1)
    @@ph1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Inpatient : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount1 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph1[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
  end

  it "Inpatient : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount1) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount1))
    @@ph1[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Inpatient : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim1 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim1 = 0.00
    end
    @@ph1[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end

  it "Inpatient : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days1
    @@ph1[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "Inpatient : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim1 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB01")
    @@actual_room_benefit_claim1 = @@room_benefit_claim1[:daily_amt].to_i * @days1
    @@ph1[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim1))
  end

  it "Inpatient : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    @@ph1[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Inpatient : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1 + @@actual_room_benefit_claim1
    @@ph1[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Inpatient : Checks if the maximum benefits are correct" do
    @@ph1[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph1[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph1[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "Inpatient : Checks if Deduction Claims are correct" do
    @@ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
    @@ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end

  it "Inpatient : Checks if Remaining Benefit Claims are correct" do
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

  it "Inpatient : Checks if computation of PF Attending Physician is applied correctly" do
    @@pf_physician = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.1")
    @@ph1[:inpatient_physician_benefit_claim].should == ("%0.2f" %(@@pf_physician[:daily_amt]))
  end

  it "Inpatient : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph1[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "Inpatient : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph1[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph1[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph1[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "Inpatient : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "Inpatient : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 5
  end

  it "Inpatient : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

 it "Inpatient : Discharges the patient in PBA" do
    slmc.login("sel_pba9", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "Inpatient : Prints Gate Pass of the patient" do
    slmc.login(@gu_user_0287, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

#####OSS
#####Claim Type: Accounts Receivable
#####Case Type: Ordinary Case
#####AMEBIC INFECTION OF OTHER SITES (A06.8)

  it "OSS - AR : Searches and adds order items in the OSS outpatient order page" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@oss_patient).gsub(' ','')
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true

    @@orders = @oss_ancillary1.merge(@oss_operation1)
    n = 0
    @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @oss_doctors[n])
      n += 1
    end
  end

  it "OSS - AR : Add guarantor and enable philhealth patient information" do
    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@oss_ph1 = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :philhealth_id => "12345", :rvu_code => "21325", :compute => true)
  end

  it "OSS - AR : Checks Benefit Summary totals" do
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@comp_xray_lab = 0
    @@comp_operation = 0
    @@non_comp_supplies = 0

    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_order_details_based_on_order_number(order)
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

  it "OSS - AR : Checks if the actual charge for drugs/medicine is correct"   do
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@@promo_discount2 * total_drugs)
    @@oss_ph1[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "OSS - AR : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB02")
    if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim1 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
    end
    @@oss_ph1[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
  end

  it "OSS - AR : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount2 * total_xrays_lab_others)
    @@oss_ph1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "OSS - AR : Checks if the actual lab benefit claim is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB03")
    if @@actual_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim1 = @@actual_xray_lab_others
    else
      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@oss_ph1[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
  end

  it "OSS - AR : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@promo_discount2 * @@comp_operation)
    @@oss_ph1[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "OSS - AR : Checks if the actual operation benefit claim is correct" do
    @sessions = 2 # feature #https://projects.exist.com/issues/30234
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB04.1")
    if @sessions
      @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:max_amt].to_f * @sessions
    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
      @@actual_operation_benefit_claim1 = @@actual_operation_charges
    else
      @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:max_amt].to_f
    end
    @@oss_ph1[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end

  it "OSS - AR : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@oss_ph1[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "OSS - AR : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1
    @@oss_ph1[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "OSS - AR : Checks if the maximum benefits are correct" do
    @@oss_ph1[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@oss_ph1[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "OSS - AR : Checks if Deduction Claims are correct" do
    @@oss_ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
    @@oss_ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@oss_ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end

  it "OSS - AR : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim1 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
    else
      @@drugs_remaining_benefit_claim = 0.0
    end
    @@oss_ph1[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim

    if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
    else
      @@lab_remaining_benefit_claim = 0
    end
    @@oss_ph1[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim
  end

  it "OSS - AR : Checks if PF Claims for surgeon(GP) is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21325")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f

    @@oss_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "OSS - AR : Checks if PF Claims for anesthesiologist(GP) is correct" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.6")
    anesthesiologist_claim = (@@surgeon_claim.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))

    @@oss_ph1[:anesthesiologist_benefit_claim].should == ("%0.2f" %(anesthesiologist_claim))
  end

  it "OSS - AR : Checks if Philhealth Claims is displayed in Summary Totals correctly" do
    slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "OSS - AR : Checks if Summary Totals > Total Amount Due is equal to Payments > Total Net Amount " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_net_amount
  end

  it "OSS - AR : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "OSS - AR : Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'." || "The OR was successfully updated with printTag = 'Y'."
  end

  it "OSS - Refund : Searches and adds order items in the OSS outpatient order page" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true

    @@orders = @oss_ancillary1.merge(@oss_operation1)
    n = 0
    @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @oss_doctors[n])
      n += 1
    end
  end

  it "OSS - Refund : Add guarantor and enable philhealth patient information" do
    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@oss_ph2 = slmc.oss_input_philhealth(:claim_type => "REFUND", :case_type => "INTENSIVE CASE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :philhealth_id => "12345", :compute => true)
  end

  it "OSS - Refund : Checks Benefit Summary totals" do
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@comp_xray_lab = 0
    @@comp_operation = 0
    @@non_comp_supplies = 0

    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_order_details_based_on_order_number(order)
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

  it "OSS - Refund : Checks if the actual charge for drugs/medicine is correct"   do
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@@promo_discount2 * total_drugs)
    @@oss_ph2[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "OSS - Refund : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim2 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f
    end
    @@oss_ph2[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
  end

  it "OSS - Refund : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount2 * total_xrays_lab_others)
    @@oss_ph2[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "OSS - Refund : Checks if the actual lab benefit claim is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@actual_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
      @@actual_lab_benefit_claim2 = @@actual_xray_lab_others
    else
      @@actual_lab_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
    end
    @@oss_ph2[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
  end

  it "OSS - Refund : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@promo_discount2 * @@comp_operation)
    @@oss_ph2[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "OSS - Refund : Checks if the actual operation benefit claim is correct" do
    @sessions = 2
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB04.1")
    if @sessions
      @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:max_amt].to_f * @sessions
    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
      @@actual_operation_benefit_claim2 = @@actual_operation_charges
    else
      @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:max_amt].to_f
    end
    @@oss_ph2[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "OSS - Refund : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@oss_ph2[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "OSS - Refund : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2
    @@oss_ph2[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "OSS - Refund : Checks if the maximum benefits are correct" do
    @@oss_ph2[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@oss_ph2[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "OSS - Refund : Checks if Deduction Claims are correct" do
    @@oss_ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
    @@oss_ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    @@oss_ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "OSS - Refund : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim2 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
    else
      @@drugs_remaining_benefit_claim = 0.0
    end
    @@oss_ph2[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim

    if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
    else
      @@lab_remaining_benefit_claim = 0
    end
    @@oss_ph2[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim
  end

  it "OSS - Refund : Checks if Summary Totals > Total Amount Due is equal to Payments > Total Net Amount " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_net_amount
  end

  it "OSS - Refund : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "OSS - Refund : Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'." || "The OR was successfully updated with printTag = 'Y'."
  end

#OR
#Claim Type: Accounts Receivable
#Case Type: Catastrophic Case
#AMEBIC INFECTION OF OTHER SITES (A06.8)

  it "OR - AR : Claim Type: Accounts Receivable | With Operation: Yes" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true, :gender => 'F')).gsub(' ', '')
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @or_drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @or_ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 3).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 5
    slmc.confirm_validation_all_items.should be_true
  end

  it "OR - AR : Order Procedures" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "OR - AR : Clinical Discharge Patient" do
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :pf_amount => "1000", :save => true)
  end

  it "OR - AR : Go to PhilHealth page and computes PhilHealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin).should be_true
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@or_ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "OR - AR : Check Benefit Summary totals" do
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

    @@orders = @or_ancillary1.merge(@or_drugs1).merge(@or_operation1)
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

  it "OR - AR : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount3 * total_drugs)
    @@or_ph1[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "OR - AR : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount3)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim3 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f
    end
    @@or_ph1[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
  end

  it "OR - AR : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount3)
    @@or_ph1[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "OR - AR : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount3 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@or_ph1[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
  end

  it "OR - AR : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount3) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount3))
    @@or_ph1[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "OR - AR : Checks if the actual operation benefit claim is correct" do
    @sessions = 2
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @sessions
        @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:max_amt].to_f * @sessions
      elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim3 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@or_ph1[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
    else
      @@actual_operation_benefit_claim3 = 0.00
      @@or_ph1[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
    end
  end

  it "OR - AR : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@or_ph1[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "OR - AR : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3
    @@or_ph1[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "OR - AR : Checks if the maximum benefits are correct" do
    @@or_ph1[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@or_ph1[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@or_ph1[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "OR - AR : Checks if Deduction Claims are correct" do
    @@or_ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
    @@or_ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
    @@or_ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "OR - AR : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim3 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3
    else
      @@drugs_remaining_benefit_claim3 = 0.0
    end
    @@or_ph1[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim3))

    if @@actual_lab_benefit_claim3 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3
    else
      @@lab_remaining_benefit_claim3 = 0
    end
    @@or_ph1[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim3))
  end

  it "OR - AR : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@or_ph1[:surgeon_benefit_claim].to_i != @@surgeon_claim
      @@or_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@or_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "OR - AR : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@or_ph1[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@or_ph1[:anesthesiologist_benefit_claim].should == ("0.2f" %(0.0))
    else
      @@or_ph1[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "OR - AR : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "OR - AR : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

  it "OR - AR : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

#OR
#Claim Type: Refund
#Case Type: Catastrophic Case
#Within 90 days
#AMEBIC INFECTION OF OTHER SITES (A06.8)

  it "OR - Refund : Claim Type: Refund | With Operation: Yes" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @or_drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @or_ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 3).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 5
    slmc.confirm_validation_all_items.should be_true
  end

  it "OR - Refund : Order Procedures" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "OR - Refund : Clinical Discharge Patient" do
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :pf_amount => "1000", :save => true)
  end

  it "OR - Refund : Go to PhilHealth page and computes PhilHealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin).should be_true
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@or_ph2 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "OR - Refund : Check Benefit Summary totals" do
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

    @@orders = @or_ancillary1.merge(@or_drugs1).merge(@or_operation1)
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

  it "OR - Refund : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount3 * total_drugs)
    @@or_ph2[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "OR - Refund : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount3)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3
      @@actual_medicine_benefit_claim4 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3
    end
    @@or_ph2[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
  end

  it "OR - Refund : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount3)
    @@or_ph2[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "OR - Refund : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount3 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3
      @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3
    end
    @@or_ph2[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
  end

  it "OR - Refund : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount3) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount3))
    @@or_ph2[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "OR - Refund : Checks if the actual operation benefit claim is correct" do
    @sessions = 2
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @sessions
        @@actual_operation_benefit_claim4 = @@operation_ph_benefit[:max_amt].to_f * @sessions
      elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim4 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim4 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@or_ph2[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
    else
      @@actual_operation_benefit_claim4 = 0.00
      @@or_ph2[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
    end
  end

  it "OR - Refund : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@or_ph2[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "OR - Refund : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4 + @@actual_operation_benefit_claim4
    @@or_ph2[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "OR - Refund : Checks if the maximum benefits are correct" do
    @@or_ph2[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@or_ph2[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@or_ph2[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "OR - Refund : Checks if Deduction Claims are correct" do
    @@or_ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    @@or_ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    @@or_ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "OR - Refund : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim4 = 0.0
    end
    @@or_ph2[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim4))

    if @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim4 = 0
    end
    @@or_ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim4))
  end

  it "OR - Refund : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@or_ph2[:surgeon_benefit_claim].to_i != @@surgeon_claim
      @@or_ph2[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@or_ph2[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "OR - Refund : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@or_ph2[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@or_ph2[:anesthesiologist_benefit_claim].should == ("0.2f" %(0.0))
    else
      @@or_ph2[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "OR - Refund : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end

  it "OR - Refund : Prints Gate Pass of the patient" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
  end

#ER
#Claim Type: Accounts Receivable / Refund
#Case Type: Super Catastrophic
#AMEBIC INFECTION OF OTHER SITES (A06.8)

#  it "ER : Claim Type: AR / Refund | With Operation: No" do
#    slmc.login("sel_er2", @password).should be_true
#    @@er_pin = slmc.er_create_patient_record(@er_patient.merge(:admit => true, :gender => 'F')).gsub(' ','')
#    slmc.go_to_er_landing_page
#    slmc.patient_pin_search(:pin => @@er_pin)
#    slmc.go_to_er_page_using_pin("Order Page", @@er_pin)
#    @er_drugs1.each do |item, q|
#    slmc.search_order(:description => item, :drugs => true).should be_true
#      slmc.add_returned_order(:drugs => true, :description => item,
#        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
#    end
#    @er_ancillary1.each do |item, q|
#      slmc.search_order(:description => item, :ancillary => true).should be_true
#      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
#    slmc.er_submit_added_order
#    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "ER : Clinical Discharge Patient" do
#    slmc.go_to_er_page
#    slmc.patient_pin_search(:pin => @@er_pin)
#    @@room_and_bed = slmc.get_room_and_bed_no_in_er_page
#    @@visit_no1 = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => "1000", :save => true)
#  end
#
#  it "ER : Database Manipulation - Add and Edit records of patient" do
#    @discount_type_code = "C01" if @@promo_discount4 == 0.16
#    @discount_type_code = "C02" if @@promo_discount4 == 0.2
#
#    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days1, :pin => @@er_pin, :visit_no => @@visit_no1)
#    Database.connect
#    @days1.times do |i|
#      @rb = (slmc.get_last_record_of_rb_trans_no)
#      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no1,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
#      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no1, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
#      @my_date = slmc.increase_date_by_one(@days1 - i)
#    end
#    Database.logoff
#  end
############   NO ER PHILHEALTH
############  it "ER : Go to PhilHealth page and computes PhilHealth" do
############    slmc.go_to_er_billing_page
############    slmc.patient_pin_search(:pin => @@er_pin).should be_true
############    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no1)
############    @@er_ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "SUPER CATASTROPHIC CASE", :compute => true)
############    slmc.ph_save_computation
############  end
############
############  it "ER : Check Benefit Summary totals" do
############    @@comp_drugs = 0
############    @@comp_xray_lab = 0
############    @@comp_operation = 0
############    @@comp_others = 0
############    @@comp_supplies = 0
############    @@non_comp_drugs = 0
############    @@non_comp_drugs_mrp_tag = 0
############    @@non_comp_xray_lab = 0
############    @@non_comp_operation = 0
############    @@non_comp_others = 0
############    @@non_comp_supplies = 0
############
############    @@orders = @er_ancillary1.merge(@er_drugs1).merge(@er_operation1)
############    @@orders.each do |order,n|
############      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
############      if item[:ph_code] == "PHS01"
############        amt = item[:rate].to_f * n
############        @@comp_drugs += amt  # total compensable drug
############      end
############      if item[:ph_code] == "PHS02"
############        x_lab_amt = item[:rate].to_f * n
############        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
############      end
############      if item[:ph_code] == "PHS03"
############        o_amt = item[:rate].to_f * n
############        @@comp_operation += o_amt  # total compensable operations
############      end
############      if item[:ph_code] == "PHS04"
############        other_amt = item[:rate].to_f * n
############        @@comp_others += other_amt  # total compensable others
############      end
############      if item[:ph_code] == "PHS05"
############        supp_amt = item[:rate].to_f * n
############        @@comp_supplies += supp_amt  # total compensable supplies
############      end
############      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
############        n_amt = item[:rate].to_f * n
############        @@non_comp_drugs += n_amt # total non-compensable drug
############      end
############      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
############        n_amt_tag = item[:rate].to_f * n
############        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
############      end
############      if item[:ph_code] == "PHS07"
############        n_x_lab_amt = item[:rate].to_f * n
############        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
############      end
############      if item[:ph_code] == "PHS08"
############        n_o_amt = item[:rate].to_f * n
############        @@non_comp_operation += n_o_amt # total non compensable operations
############      end
############      if item[:ph_code] == "PHS09"
############        n_other_amt = item[:rate].to_f * n
############        @@non_comp_others += n_other_amt  # total non compensable others
############      end
############      if item[:ph_code] == "PHS10"
############        s_amt = item[:rate].to_f * n
############        @@non_comp_supplies += s_amt  # total non compensable supplies
############      end
############    end
############  end
############
############   it "ER : Checks if the actual charge for drugs/medicine is correct" do
############    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
############    total_drugs = @@comp_drugs + @@non_comp_drugs
############    @@actual_medicine_charges = total_drugs - (@@promo_discount4 * total_drugs)
############    @@er_ph1[:er_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
############  end
############
############  it "ER : Checks if the actual benefit claim for drugs/medicine is correct" do
############    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount4)
############    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
############      @@actual_medicine_benefit_claim1 = @@comp_drugs_total
############    else
############      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
############    end
############    @@er_ph1[:er_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
############  end
############
############  it "ER : Checks if the actual charge for xrays, lab and others is correct" do
############    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
############    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount4)
############    @@er_ph1[:er_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
############  end
############
############  it "ER : Checks if the actual lab benefit claim is correct" do
############    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount4 * @@comp_xray_lab)
############    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
############    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
############      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
############    else
############      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
############    end
############    @@er_ph1[:er_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
############  end
############
############ it "ER : Checks if the actual charge for operation is correct" do
############    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount4) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount4))
############    @@er_ph1[:er_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
############  end
############
############  it "ER : Checks if the actual operation benefit claim is correct" do
############    @sessions = 2
############    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
############    if @sessions
############      @@actual_operation_benefit_claim1 =  @@operation_ph_benefit[:max_amt].to_f * @sessions
############    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
############      @@actual_operation_benefit_claim1 = @@actual_operation_charges
############    else
############      @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:max_amt].to_f
############    end
############    @@er_ph1[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
############  end
############
############  it "ER : Checks if the total actual charge(s) is correct" do
############    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
############    @@er_ph1[:er_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
############  end
############
############  it "ER : Checks if the total actual benefit claim is correct" do
############    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1
############    @@er_ph1[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
############  end
############
############  it "ER : Checks if the maximum benefits are correct" do
############    @@er_ph1[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
############    @@er_ph1[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
############    @@er_ph1[:er_max_benefit_operation].should == "RVU x PCF"
############  end
############
############  it "ER : Checks if Deduction Claims are correct" do
############    @@er_ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
############    @@er_ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
############    @@er_ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
############  end
############
############  it "ER : Checks if Remaining Benefit Claims are correct" do
############    if @@actual_medicine_benefit_claim1 < @@med_ph_benefit[:max_amt].to_f
############      @@drugs_remaining_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1)
############    else
############      @@drugs_remaining_benefit_claim1 = 0.0
############    end
############    @@er_ph1[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim1))
############
############    if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
############      @@lab_remaining_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1)
############    else
############      @@lab_remaining_benefit_claim1 = 0
############    end
############    @@er_ph1[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim1))
############  end
############
############  it "ER : Checks if computation of PF claims surgeon is applied correctly" do
############    @@er_ph1[:surgeon_benefit_claim].should == nil
############  end
############
############  it "ER : Checks if computation of PF claims anesthesiologist is applied correctly" do
############    @@er_ph1[:anesthesiologist_benefit_claim].should == nil
############  end
############
############  it "ER : Checks No Claim History" do
############    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
############  end
############
############  it "ER : View Details of the ordered items" do
############    slmc.ph_view_details(:close => true).should == 4
############  end
############
############  it "ER : Prints PhilHealth Form and Prooflist" do
############    slmc.ph_print_report.should be_true
############  end
############
############  it "ER : Update Guarantor" do
############    slmc.login("sel_er2", @password).should be_true
############    slmc.go_to_er_billing_page
############    slmc.patient_pin_search(:pin => @@er_pin)
############    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
############    slmc.click_new_guarantor
############    slmc.pba_update_guarantor
############    slmc.click_submit_changes.should be_true
############  end
############
############  it "ER : Discharges the patient in PBA" do
############    slmc.go_to_er_billing_page
############    slmc.patient_pin_search(:pin => @@er_pin)
############    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
############    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
############    slmc.discharge_to_payment.should be_true
############  end
############
############  it "ER : Prints Gate Pass of the patient" do
############    slmc.go_to_er_page
############    slmc.er_print_gatepass(:pin => @@er_pin, :visit_no => @@visit_no1).should be_true
############  end

#DR
#Claim Type: Accounts Receivable / Refund
#Case Type: Ordinary Case
#AMEBIC INFECTION OF OTHER SITES (A06.8)

  it "DR : Claim Type: Accounts Receivable | With Operation: Yes" do
    slmc.login("sel_dr3", @password).should be_true
    @@dr_pin = slmc.or_nb_create_patient_record(@dr_patient.merge!(:admit => true, :gender => 'F', :org_code => "0170")).gsub(' ', '')
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin)
    @dr_drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @dr_ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.er_submit_added_order(:validate => true, :username => "sel_dr_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
  end

  it "DR : Order Procedures" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "DR : Clinical Discharge Patient" do
    slmc.login("sel_dr3", @password).should be_true
    slmc.go_to_occupancy_list_page
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no2 = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin, :pf_amount => "1000", :save => true)
  end

  it "DR : Database Manipulation - Add and Edit records of patient" do
    @discount_type_code = "C01" if @@promo_discount5 == 0.16
    @discount_type_code = "C02" if @@promo_discount5 == 0.2

    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days1, :pin => @@dr_pin, :visit_no => @@visit_no2)
    Database.connect
    @days1.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no2,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no2, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days1 - i)
    end
    Database.logoff
  end

  it "DR : Go to PhilHealth page and computes PhilHealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@dr_pin).should be_true
    slmc.click_philhealth_link(:pin => @@dr_pin, :visit_no => @@visit_no2)
    @@dr_ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
  end

  it "DR : Check Benefit Summary totals" do
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

    @@orders = @dr_ancillary1.merge(@dr_drugs1).merge(@dr_operation1)
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

   it "DR : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount5 * total_drugs)
    @@dr_ph1[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "DR : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount5)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim1 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
    end
    @@dr_ph1[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
  end

  it "DR : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount5)
    @@dr_ph1[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "DR : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount5 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@dr_ph1[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
  end

  it "DR : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount5) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount5))
    @@dr_ph1[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "DR : Checks if the actual operation benefit claim is correct" do
    @sessions = 2
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
    if @sessions
      @@actual_operation_benefit_claim1 =  @@operation_ph_benefit[:max_amt].to_f * @sessions
    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
      @@actual_operation_benefit_claim1 = @@actual_operation_charges
    else
      @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:max_amt].to_f
    end
    @@dr_ph1[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end

  it "DR : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges # + @@actual_room_charges
    @@dr_ph1[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "DR : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1 # + @@actual_room_benefit_claim1
    @@dr_ph1[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "DR : Checks if the maximum benefits are correct" do
    @@dr_ph1[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@dr_ph1[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@dr_ph1[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "DR : Checks if Deduction Claims are correct" do
    @@dr_ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
    @@dr_ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@dr_ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end

  it "DR : Checks if Remaining Benefit Claims are correct" do
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

  it "DR : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@dr_ph1[:surgeon_benefit_claim].to_i != @@surgeon_claim
      @@dr_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@dr_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "DR : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@dr_ph1[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@dr_ph1[:anesthesiologist_benefit_claim].should == ("0.2f" %(0.0))
    else
      @@dr_ph1[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

 it "DR : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "DR : Prints Gate Pass of the patient" do
    slmc.login("sel_dr3", @password).should be_true
    slmc.or_print_gatepass(:pin => @@dr_pin, :visit_no => @@visit_no2).should be_true
  end

end