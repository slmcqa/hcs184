require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'


describe "SLMC :: PhilHealth Radiation Oncology Version 1.4" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @patient = Admission.generate_data
    @oss_patient = Admission.generate_data
    @or_patient = Admission.generate_data
    @er_patient = Admission.generate_data
    @@promo_discount1 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient[:age])
    @@promo_discount2 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@oss_patient[:age])
    @@promo_discount3 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])
    @@promo_discount4 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@er_patient[:age])

    @password = "123qweuser"
    #@user = "billing_spec_user1"
    @user = "billing_spec_user"
    
    @room_rate = 4167.0
    @discount_amount = (@room_rate * @@promo_discount1)
    @room_discount = @room_rate - @discount_amount
    @days1 = 1

    @drugs1 =  {"049000028" => 1, "040950558" => 1}
    @ancillary1 = {"010001636" => 1, "010001585" => 1}
    @operation1 = {"060000204" => 1}

    @drugs2 =  {"049000028" => 1, "040950558" => 1}
    @ancillary2 = {"010001636" => 1, "010001585" => 1}
    @operation2 = {"060000204" => 1}

    @oss_ancillary1 = {"010001636" => 1, "010001585" => 1, "010000003" => 1}
    @oss_operation1 = {"010000160" => 1}
    @oss_doctors = ["6726","0126","6726","0126"]

    @oss_ancillary2 = {"010001636" => 2, "010001585" => 1, "010000003" => 1}
    @oss_operation2 = {"010000160" => 1}

    @or_drugs1 = {"049000028" => 1, "040950558" => 1}
    @or_ancillary1 = {"010001636" => 1, "010001585" => 1, "010000003" => 1}
    @or_operation1 = {"060000204" => 1}

    @or_drugs2 = {"049000028" => 1, "040950558" => 1}
    @or_ancillary2 = {"010001636" => 8, "010001585" => 1, "010000003" => 1}
    @or_operation2 = {"060000204" => 1}

    @er_drugs1 = {"049000028" => 1, "040950558" => 1}
    @er_ancillary1 = {"010001636" => 1, "010001585" => 1}

    @er_drugs2 = {"049000028" => 1, "040950558" => 1}
    @er_ancillary2 = {"010001636" => 6, "010001585" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Creates and admits patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(@patient)
 #       slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Orders items in General Units" do
    slmc.nursing_gu_search(:pin => @@pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true)
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726")
    end
    @ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true)
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126", :quantity => 1)
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Orders Procedures in OR" do # the 2 procedures mentioned is ordered in Order Page
    sleep 6
    #slmc.login("or27", @password).should be_true
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Clinically Discharge patient in General Units" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    @@visit_no1.should_not be_false
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Database Manipulation" do
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

  it "Radiation Oncology - Inpatient(2 Procedures) : Compute and Save PhilHealth" do
    sleep 6
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "SUPER CATASTROPHIC CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Check Benefit Summary totals" do
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

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount1 * total_drugs)
    @@ph1[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount1)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim1 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph1[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount1)
    @@ph1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount1 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph1[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount1) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount1))
    @@ph1[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the actual operation benefit claim is correct" do
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

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days1
    @@ph1[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim1 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB01")
    @@actual_room_benefit_claim1 = @@room_benefit_claim1[:daily_amt].to_i * @days1
    @@ph1[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim1))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    @@ph1[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1 + @@actual_room_benefit_claim1
    @@ph1[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if the maximum benefits are correct" do
    @@ph1[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph1[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph1[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if Deduction Claims are correct" do
    @@ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
    @@ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim1 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
    else
      @@drugs_remaining_benefit_claim1 = 0.0
    end
    @@ph1[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim1))

    if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
    else
      @@lab_remaining_benefit_claim1 = 0.0
    end
    @@ph1[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim1))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if computation of PF Attending Physician is applied correctly" do
    @@pf_physician = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.1")
    @@ph1[:inpatient_physician_benefit_claim].should == ("%0.2f" %(@@pf_physician[:daily_amt]))
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph1[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph1[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph1[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(0.0)) #8000.0
    else
      @@ph1[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 5
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "Radiation Oncology - Inpatient(2 Procedures) : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

#########################################################################

  it "Radiation Oncology - Inpatient(1 Procedure) : Creates and admits patient" do
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Orders items in General Units" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs2.each do |item, q|
      slmc.search_order(:description => item, :drugs => true)
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726")
    end
    @ancillary2.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true)
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126", :quantity => q)
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Orders Procedures in OR" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Clinically Discharge patient in General Units" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Database Manipulation" do
    @discount_type_code = "C01" if @@promo_discount1 == 0.16
    @discount_type_code = "C02" if @@promo_discount1 == 0.2

    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days1, :pin => @@pin, :visit_no => @@visit_no2)
    Database.connect
    @days1.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no2,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no2, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days1 - i)
    end
    Database.logoff
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Compute and Save PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Check Benefit Summary totals" do
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

    @@orders = @drugs2.merge(@ancillary2).merge(@operation2)
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

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount1 * total_drugs)
    @@ph2[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount1)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim2 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph2[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount1)
    @@ph2[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount1 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph2[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount1) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount1))
    @@ph2[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the actual operation benefit claim is correct" do
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
    @@ph2[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days1
    @@ph2[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim1 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB01")
    @@actual_room_benefit_claim2 = @@room_benefit_claim1[:daily_amt].to_i * @days1
    @@ph2[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim2))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    @@ph2[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2 + @@actual_room_benefit_claim2
    @@ph2[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if the maximum benefits are correct" do
    @@ph2[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph2[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph2[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if Deduction Claims are correct" do
    @@ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
    @@ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    @@ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim2 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim2
    else
      @@drugs_remaining_benefit_claim2 = 0.0
    end
    @@ph2[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim2))

    if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim2
    else
      @@lab_remaining_benefit_claim2 = 0.0
    end
    @@ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim2))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if computation of PF Attending Physician is applied correctly" do
    @@pf_physician = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.1")
    @@ph2[:inpatient_physician_benefit_claim].should == ("%0.2f" %(@@pf_physician[:daily_amt]))
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph2[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph2[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph2[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph2[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph2[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(0.0)) #8000.0
    else
      @@ph2[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == @@visit_no1
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 5
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "Radiation Oncology - Inpatient(1 Procedure) : Prints Gate Pass of the patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

#########################################################################

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Order items" do
    slmc.login("jtsalang", @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@oss_patient).gsub(' ','')
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

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Add Guarantor and Compute PhilHealth" do
    slmc.oss_add_guarantor(:guarantor_type =>  "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@oss_ph1 = slmc.oss_input_philhealth(:claim_type => "ACCOUNTS RECEIVABLE", :case_type => "ORDINARY CASE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :philhealth_id => "12345", :rvu_code => "22847", :compute => true)
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks Benefit Summary totals" do
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

    @@orders = @oss_ancillary1.merge(@oss_operation1)
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

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if the actual charge for drugs/medicine is correct"   do
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@@promo_discount2 * total_drugs)
    @@oss_ph1[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB02")
    if @@med_ph_benefit[:max_amt].to_f <= 0
      @@actual_medicine_benefit_claim3 = 0.0
    elsif @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim3 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f
    end
    @@oss_ph1[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount2 * total_xrays_lab_others)
    @@oss_ph1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if the actual lab benefit claim is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB03")
    if @@actual_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim3 = @@actual_xray_lab_others
    else
      @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@oss_ph1[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@promo_discount2 * @@comp_operation)
    @@oss_ph1[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if the actual operation benefit claim is correct" do
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB04.1")
    @sessions = 1
    if @sessions
      @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:max_amt].to_f +  (1200.00 * @sessions)
    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
      @@actual_operation_benefit_claim3 = @@actual_operation_charges
    else
      @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:max_amt].to_f
    end
    @@oss_ph1[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@oss_ph1[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3
    @@oss_ph1[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if the maximum benefits are correct" do
    @@oss_ph1[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@oss_ph1[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if Deduction Claims are correct" do
    @@oss_ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
    @@oss_ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
    @@oss_ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if Remaining Benefit Claims are correct" do
    if @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3 <= 0
      @@drugs_remaining_benefit_claim = 0.0
    elsif @@actual_medicine_benefit_claim3 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim = @@actual_medicine_benefit_claim3
    end
    (@@oss_ph1[:drugs_remaining_benefit_claims].to_f).should == @@drugs_remaining_benefit_claim

    if @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3 <= 0
      @@lab_remaining_benefit_claim = 0.0
    elsif @@actual_lab_benefit_claim3 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim = @@actual_lab_benefit_claim3
    end
    (@@oss_ph1[:lab_remaining_benefit_claims].to_f).should == @@lab_remaining_benefit_claim
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if PF Claims for surgeon(GP) is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("22847")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@oss_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if PF Claims for anesthesiologist(GP) is correct" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.6")
    anesthesiologist_claim = (@@surgeon_claim.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))
    @@oss_ph1[:anesthesiologist_benefit_claim].should == ("%0.2f" %(anesthesiologist_claim))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if Philhealth Claims is displayed in Summary Totals correctly" do
    slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks if Summary Totals > Total Amount Due is equal to Payments > Total Net Amount " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_net_amount
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "Radiation Oncology - OSS Accounts Receivable(1 Procedure) : Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

#########################################################################

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Order items" do
    slmc.login("jtsalang", @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true
    @@orders = @oss_ancillary2.merge(@oss_operation2)
    n = 0
    @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @oss_doctors[n])
      n += 1
    end
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Add Guarantor and Compute PhilHealth" do
    slmc.oss_add_guarantor(:guarantor_type =>  "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@oss_ph2 = slmc.oss_input_philhealth(:claim_type => "ACCOUNTS RECEIVABLE", :case_type => "ORDINARY CASE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :philhealth_id => "12345", :rvu_code => "22847", :compute => true)
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks Benefit Summary totals" do
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

    @@orders = @oss_ancillary2.merge(@oss_operation2)
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

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if the actual charge for drugs/medicine is correct"   do
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@@promo_discount2 * total_drugs)
    @@oss_ph2[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB02")
    if @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3 <= 0
      @@actual_medicine_benefit_claim4 = 0.0
    elsif @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3
      @@actual_medicine_benefit_claim4 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3
    end
    @@oss_ph2[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount2 * total_xrays_lab_others)
    @@oss_ph2[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if the actual lab benefit claim is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3 <= 0
      @@actual_lab_benefit_claim4 = 0.0
    elsif @@actual_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3
      @@actual_lab_benefit_claim4 = @@actual_xray_lab_others
    else
      @@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3
    end
    @@oss_ph2[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@promo_discount2 * @@comp_operation)
    @@oss_ph2[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if the actual operation benefit claim is correct" do
    @sessions = 2
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB04.1")
    if @sessions
      @@actual_operation_benefit_claim4 = @@operation_ph_benefit[:max_amt].to_f +  (1200.00 * @sessions)
    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
      @@actual_operation_benefit_claim4 = @@actual_operation_charges
    else
      @@actual_operation_benefit_claim4 = @@operation_ph_benefit[:max_amt].to_f
    end
    @@oss_ph2[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@oss_ph2[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4 + @@actual_operation_benefit_claim4
    @@oss_ph2[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if the maximum benefits are correct" do
    @@oss_ph2[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@oss_ph2[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if Deduction Claims are correct" do
    @@oss_ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    @@oss_ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    @@oss_ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if Remaining Benefit Claims are correct" do
    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3) <= 0
      @@drugs_remaining_benefit_claim = 0.0
    elsif @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim = @@actual_medicine_benefit_claim4
    end
    (@@oss_ph2[:drugs_remaining_benefit_claims].to_f).should == @@drugs_remaining_benefit_claim

    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3) <= 0
      @@lab_remaining_benefit_claim = 0.0
    elsif @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim = @@actual_lab_benefit_claim4
    end
    (@@oss_ph2[:lab_remaining_benefit_claims].to_f).should == @@lab_remaining_benefit_claim
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if PF Claims for surgeon(GP) is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("22847")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@oss_ph2[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if PF Claims for anesthesiologist(GP) is correct" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.6")
    anesthesiologist_claim = (@@surgeon_claim.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))
    @@oss_ph2[:anesthesiologist_benefit_claim].should == ("%0.2f" %(anesthesiologist_claim))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if Philhealth Claims is displayed in Summary Totals correctly" do
    slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks if Summary Totals > Total Amount Due is equal to Payments > Total Net Amount " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_net_amount
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "Radiation Oncology - OSS Accounts Receivable(2 Procedures) : Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

#########################################################################

  it "Radiation Oncology - OSS Refund(1 Procedure) : Order items" do
    slmc.login("jtsalang", @password).should be_true
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

  it "Radiation Oncology - OSS Refund(1 Procedure) : Add Guarantor and Compute PhilHealth" do
    slmc.oss_add_guarantor(:guarantor_type =>  "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@oss_ph3 = slmc.oss_input_philhealth(:claim_type => "REFUND", :case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060", :compute => true)
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks Benefit Summary totals" do
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

    @@orders = @oss_ancillary1.merge(@oss_operation1)
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

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if the actual charge for drugs/medicine is correct"   do
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@@promo_discount2 * total_drugs)
    @@oss_ph3[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB02")
    if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim5 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f
    end
    @@oss_ph3[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount2 * total_xrays_lab_others)
    @@oss_ph3[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if the actual lab benefit claim is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB03")
    if @@actual_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim5 = @@actual_xray_lab_others
    else
      @@actual_lab_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@oss_ph3[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@promo_discount2 * @@comp_operation)
    @@oss_ph3[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if the actual operation benefit claim is correct" do
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB04.1")
    @sessions = 1
    if @sessions
      @@actual_operation_benefit_claim5 = @@operation_ph_benefit[:max_amt].to_f +  (1200.00 * @sessions)
    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
      @@actual_operation_benefit_claim5 = @@actual_operation_charges
    else
      @@actual_operation_benefit_claim5 = @@operation_ph_benefit[:max_amt].to_f
    end
    @@oss_ph3[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@oss_ph3[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim5 + @@actual_lab_benefit_claim5 + @@actual_operation_benefit_claim5
    @@oss_ph3[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if the maximum benefits are correct" do
    @@oss_ph3[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@oss_ph3[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if Deduction Claims are correct" do
    @@oss_ph3[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
    @@oss_ph3[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
    @@oss_ph3[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if Remaining Benefit Claims are correct" do
    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5) <= 0
      @@drugs_remaining_benefit_claim = 0.0
    elsif @@actual_medicine_benefit_claim5 < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5)
      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5)
    else
      @@drugs_remaining_benefit_claim = @@actual_medicine_benefit_claim5
    end
    (@@oss_ph3[:drugs_remaining_benefit_claims].to_f).should == @@drugs_remaining_benefit_claim

    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5) <= 0
      @@lab_remaining_benefit_claim = 0.0
    elsif @@actual_lab_benefit_claim5 < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5)
      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5)
    else
      @@lab_remaining_benefit_claim = @@actual_lab_benefit_claim5
    end
    (@@oss_ph3[:lab_remaining_benefit_claims].to_f).should == @@lab_remaining_benefit_claim
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if PF Claims for surgeon(GP) is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@oss_ph3[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks if PF Claims for anesthesiologist(GP) is correct" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.6")
    anesthesiologist_claim = (@@surgeon_claim.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))
    @@oss_ph3[:anesthesiologist_benefit_claim].should == ("%0.2f" %(anesthesiologist_claim))
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "Radiation Oncology - OSS Refund(1 Procedure) : Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

#########################################################################

  it "Radiation Oncology - OSS Refund(2 Procedures) : Order items" do
    slmc.login("jtsalang", @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true
    @@orders = @oss_ancillary2.merge(@oss_operation2)
    n = 0
    @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @oss_doctors[n])
      n += 1
    end
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Add Guarantor and Compute PhilHealth" do
    slmc.oss_add_guarantor(:guarantor_type =>  "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@oss_ph4 = slmc.oss_input_philhealth(:claim_type => "REFUND", :case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060", :compute => true)
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks Benefit Summary totals" do
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

    @@orders = @oss_ancillary2.merge(@oss_operation2)
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

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if the actual charge for drugs/medicine is correct"   do
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@@promo_discount2 * total_drugs)
    @@oss_ph4[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB02")
    if @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim5 <= 0
      @@actual_medicine_benefit_claim6 = 0.0
    elsif @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim5
      @@actual_medicine_benefit_claim6 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim6 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim5
    end
    @@oss_ph4[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim6))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount2 * total_xrays_lab_others)
    @@oss_ph4[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if the actual lab benefit claim is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim5 <= 0
      @@actual_lab_benefit_claim6 = 0.0
    elsif @@actual_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim5
      @@actual_lab_benefit_claim6 = @@actual_xray_lab_others
    else
      @@actual_lab_benefit_claim6 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim5
    end
    @@oss_ph4[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim6))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@promo_discount2 * @@comp_operation)
    @@oss_ph4[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if the actual operation benefit claim is correct" do
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB04.1")
    @sessions = 2
    if @sessions
      @@actual_operation_benefit_claim6 = @@operation_ph_benefit[:max_amt].to_f +  (1200.00 * @sessions)
    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
      @@actual_operation_benefit_claim6 = @@actual_operation_charges
    else
      @@actual_operation_benefit_claim6 = @@operation_ph_benefit[:max_amt].to_f
    end
    @@oss_ph4[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@oss_ph4[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim6 + @@actual_lab_benefit_claim6 + @@actual_operation_benefit_claim6
    @@oss_ph4[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if the maximum benefits are correct" do
    @@oss_ph4[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@oss_ph4[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if Deduction Claims are correct" do
    @@oss_ph4[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim6))
    @@oss_ph4[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim6))
    @@oss_ph4[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if Remaining Benefit Claims are correct" do
    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5) <= 0
      @@drugs_remaining_benefit_claim = 0.0
    elsif @@actual_medicine_benefit_claim6 < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5)
      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim5)
    else
      @@drugs_remaining_benefit_claim = @@actual_medicine_benefit_claim6
    end
    (@@oss_ph4[:drugs_remaining_benefit_claims].to_f).should == @@drugs_remaining_benefit_claim

    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5) <= 0
      @@lab_remaining_benefit_claim = 0.0
    elsif @@actual_lab_benefit_claim6 < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5)
      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim5)
    else
      @@lab_remaining_benefit_claim = @@actual_lab_benefit_claim6
    end
    (@@oss_ph4[:lab_remaining_benefit_claims].to_f).should == @@lab_remaining_benefit_claim
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if PF Claims for surgeon(GP) is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@oss_ph4[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks if PF Claims for anesthesiologist(GP) is correct" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.6")
    anesthesiologist_claim = (@@surgeon_claim.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))
    @@oss_ph4[:anesthesiologist_benefit_claim].should == ("%0.2f" %(anesthesiologist_claim))
  end

  it "Radiation Oncology - OSS Refund(2 Procedures) : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "Radiation Oncology - OSS Refund(2 Procedure2) : Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

################################################################

  it "Radiation Oncology - OR/DR(1 Procedure) : Creates and admits patient" do
    slmc.login("slaquino", @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true)).gsub(' ', '')
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Order items" do
        slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @or_drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true)
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726")
    end
    @or_ancillary1.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true)
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126", :quantity => q)
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 3).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 5
    slmc.confirm_validation_all_items.should be_true
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Order Procedures" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Clinical Discharge Patient" do
    slmc.go_to_occupancy_list_page
    @@visit_no3 = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :pf_amount => "1000", :save => true).should be_true
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Go to PhilHealth page and computes PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin).should be_true
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no3)
    @@or_ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Check Benefit Summary Totals" do
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

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount3 * total_drugs)
    @@or_ph1[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount3)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim7 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim7 = @@med_ph_benefit[:max_amt].to_f
    end
    @@or_ph1[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount3)
    @@or_ph1[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount3 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim7 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim7 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@or_ph1[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount3) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount3))
    @@or_ph1[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if the actual operation benefit claim is correct" do
    @sessions = 1
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @sessions
        @@actual_operation_benefit_claim7 = @@operation_ph_benefit[:max_amt].to_f +  (1200.00 * @sessions)
      elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim7 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim7 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim7 = 0.00
    end
    @@or_ph1[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@or_ph1[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim7 + @@actual_lab_benefit_claim7 + @@actual_operation_benefit_claim7
    @@or_ph1[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if the maximum benefits are correct" do
    @@or_ph1[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@or_ph1[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@or_ph1[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if Deduction Claims are correct" do
    @@or_ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
    @@or_ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
    @@or_ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim7 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim7 = @@med_ph_benefit[:max_amt].to_f
    else
      @@drugs_remaining_benefit_claim7 = 0.0
    end
    @@or_ph1[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim7))

    if @@actual_lab_benefit_claim7 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim7 = @@lab_ph_benefit[:max_amt].to_f
    else
      @@lab_remaining_benefit_claim7 = 0.0
    end
    @@or_ph1[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim7))
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@or_ph1[:surgeon_benefit_claim].to_i != @@surgeon_claim
      @@or_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@or_ph1[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@or_ph1[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@or_ph1[:anesthesiologist_benefit_claim].should == ("%0.2f" %(0.0))
    else
      @@or_ph1[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Prints Gate Pass of the patient" do
    slmc.login("or27", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no3).should be_true
  end

  it "Radiation Oncology - OR/DR(1 Procedure) : Registers patient for the next availment" do
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

##########################################################################

  it "Radiation Oncology - OR/DR(2 Procedures) : Order items" do
    slmc.login("or27", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @or_drugs2.each do |item, q|
      slmc.search_order(:description => item, :drugs => true)
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726")
    end
    @or_ancillary2.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true)
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126", :quantity => q)
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 3).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 5
    slmc.confirm_validation_all_items.should be_true
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Order Procedures" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Clinical Discharge Patient" do
    slmc.go_to_occupancy_list_page
    @@visit_no4 = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :pf_amount => "1000", :save => true).should be_true
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Go to PhilHealth page and computes PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin).should be_true
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no4)
    @@or_ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Check Benefit Summary Totals" do
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

    @@orders = @or_drugs2.merge(@or_ancillary2).merge(@or_operation2)
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

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount3 * total_drugs)
    @@or_ph2[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount3)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim8 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim8 = @@med_ph_benefit[:max_amt].to_f
    end
    @@or_ph2[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount3)
    @@or_ph2[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount3 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim8 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim8 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@or_ph2[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount3) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount3))
    @@or_ph2[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if the actual operation benefit claim is correct" do
    @sessions = 8
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @sessions
        @@actual_operation_benefit_claim8 = @@operation_ph_benefit[:max_amt].to_f +  (1200.00 * @sessions)
      elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim8 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim8 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim8 = 0.00
    end
    @@or_ph2[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@or_ph2[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim8 + @@actual_lab_benefit_claim8 + @@actual_operation_benefit_claim8
    @@or_ph2[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if the maximum benefits are correct" do
    @@or_ph2[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@or_ph2[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@or_ph2[:or_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if Deduction Claims are correct" do
    @@or_ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
    @@or_ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
    @@or_ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim8 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim8 = @@med_ph_benefit[:max_amt].to_f
    else
      @@drugs_remaining_benefit_claim8 = 0.0
    end
    @@or_ph2[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim8))

    if @@actual_lab_benefit_claim8 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim8 = @@lab_ph_benefit[:max_amt].to_f
    else
      @@lab_remaining_benefit_claim8 = 0.0
    end
    @@or_ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim8))
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@or_ph2[:surgeon_benefit_claim].to_i != @@surgeon_claim
      @@or_ph2[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@or_ph2[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@or_ph2[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@or_ph2[:anesthesiologist_benefit_claim].should == ("%0.2f" %(0.0))
    else
      @@or_ph2[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "Radiation Oncology - OR/DR(2 Procedures) : Prints Gate Pass of the patient" do
    slmc.login("or27", @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin, :visit_no => @@visit_no4).should be_true
  end

############################ NO ER FHILHEALTH###################################
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Create and admit patient" do
##########    slmc.login("sel_er3", @password).should be_true
##########    @@er_pin = slmc.er_create_patient_record(@er_patient.merge(:admit => true)).gsub(' ','')
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Order items" do
##########        slmc.login("sel_er3", @password).should be_true
##########    slmc.go_to_er_landing_page
##########    slmc.patient_pin_search(:pin => @@er_pin)
##########    slmc.go_to_er_page_using_pin("Order Page", @@er_pin)
##########    @er_drugs1.each do |item, q|
##########    slmc.search_order(:description => item, :drugs => true)
##########      slmc.add_returned_order(:drugs => true, :description => item,
##########        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726")
##########    end
##########    @er_ancillary1.each do |item, q|
##########      slmc.search_order(:description => item, :ancillary => true)
##########      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126", :quantity => q)
##########    end
##########    sleep 5
##########    slmc.verify_ordered_items_count(:drugs => 2).should be_true
##########    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
##########    slmc.er_submit_added_order
##########    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
##########    slmc.confirm_validation_all_items.should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Clinical Discharge Patient" do
##########    slmc.go_to_er_page
##########    slmc.patient_pin_search(:pin => @@er_pin)
##########    @@visit_no5 = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => "1000", :save => true).should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Go to PhilHealth page and computes PhilHealth" do
##########    slmc.go_to_er_billing_page
##########    slmc.patient_pin_search(:pin => @@er_pin).should be_true
##########    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no5)
##########    @@er_ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "INTENSIVE CASE", :compute => true)
##########    slmc.ph_save_computation
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Check Benefit Summary totals" do
##########    @@comp_drugs = 0
##########    @@comp_xray_lab = 0
##########    @@comp_operation = 0
##########    @@comp_others = 0
##########    @@comp_supplies = 0
##########    @@non_comp_drugs = 0
##########    @@non_comp_drugs_mrp_tag = 0
##########    @@non_comp_xray_lab = 0
##########    @@non_comp_operation = 0
##########    @@non_comp_others = 0
##########    @@non_comp_supplies = 0
##########
##########    @@orders = @er_ancillary1.merge(@er_drugs1)
##########    @@orders.each do |order,n|
##########      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
##########      if item[:ph_code] == "PHS01"
##########        amt = item[:rate].to_f * n
##########        @@comp_drugs += amt  # total compensable drug
##########      end
##########      if item[:ph_code] == "PHS02"
##########        x_lab_amt = item[:rate].to_f * n
##########        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
##########      end
##########      if item[:ph_code] == "PHS03"
##########        o_amt = item[:rate].to_f * n
##########        @@comp_operation += o_amt  # total compensable operations
##########      end
##########      if item[:ph_code] == "PHS04"
##########        other_amt = item[:rate].to_f * n
##########        @@comp_others += other_amt  # total compensable others
##########      end
##########      if item[:ph_code] == "PHS05"
##########        supp_amt = item[:rate].to_f * n
##########        @@comp_supplies += supp_amt  # total compensable supplies
##########      end
##########      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
##########        n_amt = item[:rate].to_f * n
##########        @@non_comp_drugs += n_amt # total non-compensable drug
##########      end
##########      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
##########        n_amt_tag = item[:rate].to_f * n
##########        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
##########      end
##########      if item[:ph_code] == "PHS07"
##########        n_x_lab_amt = item[:rate].to_f * n
##########        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
##########      end
##########      if item[:ph_code] == "PHS08"
##########        n_o_amt = item[:rate].to_f * n
##########        @@non_comp_operation += n_o_amt # total non compensable operations
##########      end
##########      if item[:ph_code] == "PHS09"
##########        n_other_amt = item[:rate].to_f * n
##########        @@non_comp_others += n_other_amt  # total non compensable others
##########      end
##########      if item[:ph_code] == "PHS10"
##########        s_amt = item[:rate].to_f * n
##########        @@non_comp_supplies += s_amt  # total non compensable supplies
##########      end
##########    end
##########  end
##########
##########   it "Radiation Oncology - ER(1 Procedure) : Checks if the actual charge for drugs/medicine is correct" do
##########    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
##########    total_drugs = @@comp_drugs + @@non_comp_drugs
##########    @@actual_medicine_charges = total_drugs - (@@promo_discount4 * total_drugs)
##########    @@er_ph1[:er_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if the actual benefit claim for drugs/medicine is correct" do
##########    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount4)
##########    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
##########      @@actual_medicine_benefit_claim9 = @@comp_drugs_total
##########    else
##########      @@actual_medicine_benefit_claim9 = @@med_ph_benefit[:max_amt].to_f
##########    end
##########    @@er_ph1[:er_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim9))
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if the actual charge for xrays, lab and others is correct" do
##########    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
##########    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount4)
##########    @@er_ph1[:er_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if the actual lab benefit claim is correct" do
##########    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount4 * @@comp_xray_lab)
##########    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
##########    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
##########      @@actual_lab_benefit_claim9 = @@actual_comp_xray_lab_others
##########    else
##########      @@actual_lab_benefit_claim9 = @@lab_ph_benefit[:max_amt].to_f
##########    end
##########    @@er_ph1[:er_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim9))
##########  end
##########
########## it "Radiation Oncology - ER(1 Procedure) : Checks if the actual charge for operation is correct" do
##########    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount4) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount4))
##########    @@er_ph1[:er_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if the actual operation benefit claim is correct" do
##########    @sessions = 1
##########    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
##########    if @sessions
##########      @@actual_operation_benefit_claim9 =  @@operation_ph_benefit[:max_amt].to_f +  (1200.00 * @sessions)
##########    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
##########      @@actual_operation_benefit_claim9 = @@actual_operation_charges
##########    else
##########      @@actual_operation_benefit_claim9 = @@operation_ph_benefit[:max_amt].to_f
##########    end
##########    @@er_ph1[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim9))
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if the total actual charge(s) is correct" do
##########    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
##########    @@er_ph1[:er_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if the total actual benefit claim is correct" do
##########    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim9 + @@actual_lab_benefit_claim9 + @@actual_operation_benefit_claim9
##########    @@er_ph1[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if the maximum benefits are correct" do
##########    @@er_ph1[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
##########    @@er_ph1[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
##########    @@er_ph1[:er_max_benefit_operation].should == "RVU x PCF"
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if Deduction Claims are correct" do
##########    @@er_ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim9))
##########    @@er_ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim9))
##########    @@er_ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim9))
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if Remaining Benefit Claims are correct" do
##########    if @@actual_medicine_benefit_claim9 < @@med_ph_benefit[:max_amt].to_f
##########      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim9)
##########    else
##########      @@drugs_remaining_benefit_claim = 0.0
##########    end
##########    @@er_ph1[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim))
##########
##########    if @@actual_lab_benefit_claim9 < @@lab_ph_benefit[:max_amt].to_f
##########      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim9)
##########    else
##########      @@lab_remaining_benefit_claim = 0
##########    end
##########    @@er_ph1[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim))
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if computation of PF claims surgeon is applied correctly" do
##########    @@er_ph1[:surgeon_benefit_claim].should == nil
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks if computation of PF claims anesthesiologist is applied correctly" do
##########    @@er_ph1[:anesthesiologist_benefit_claim].should == nil
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Checks No Claim History" do
##########    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : View Details of the ordered items" do
##########    slmc.ph_view_details(:close => true).should == 4
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Prints PhilHealth Form and Prooflist" do
##########    slmc.ph_print_report.should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Update Guarantor" do
##########    slmc.go_to_er_billing_page
##########    slmc.patient_pin_search(:pin => @@er_pin)
##########    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
##########    slmc.click_new_guarantor
##########    slmc.pba_update_guarantor
##########    slmc.click_submit_changes.should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Discharges the patient in PBA" do
##########    slmc.go_to_er_billing_page
##########    slmc.patient_pin_search(:pin => @@er_pin)
##########    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
##########    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
##########    slmc.discharge_to_payment.should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(1 Procedure) : Prints Gate Pass of the patient" do
##########    slmc.go_to_er_page
##########    slmc.er_print_gatepass(:pin => @@er_pin, :visit_no => @@visit_no5).should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Registers patient for the next availment" do
##########    slmc.er_register_patient(:pin => @@er_pin, :org_code => "0173").should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Order items" do
##########    slmc.go_to_er_landing_page
##########    slmc.patient_pin_search(:pin => @@er_pin)
##########    slmc.go_to_er_page_using_pin("Order Page", @@er_pin)
##########    @er_drugs2.each do |item, q|
##########    slmc.search_order(:description => item, :drugs => true)
##########      slmc.add_returned_order(:drugs => true, :description => item,
##########        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726")
##########    end
##########    @er_ancillary2.each do |item, q|
##########      slmc.search_order(:description => item, :ancillary => true)
##########      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126", :quantity => q)
##########    end
##########    sleep 5
##########    slmc.verify_ordered_items_count(:drugs => 2).should be_true
##########    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
##########    slmc.er_submit_added_order
##########    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
##########    slmc.confirm_validation_all_items.should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Clinical Discharge Patient" do
##########    slmc.go_to_er_page
##########    slmc.patient_pin_search(:pin => @@er_pin)
##########    @@visit_no6 = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => "1000", :save => true).should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Go to PhilHealth page and computes PhilHealth" do
##########    slmc.go_to_er_billing_page
##########    slmc.patient_pin_search(:pin => @@er_pin).should be_true
##########    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no6)
##########    @@er_ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "SUPER CATASTROPHIC CASE", :compute => true)
##########    slmc.ph_save_computation
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Check Benefit Summary totals" do
##########    @@comp_drugs = 0
##########    @@comp_xray_lab = 0
##########    @@comp_operation = 0
##########    @@comp_others = 0
##########    @@comp_supplies = 0
##########    @@non_comp_drugs = 0
##########    @@non_comp_drugs_mrp_tag = 0
##########    @@non_comp_xray_lab = 0
##########    @@non_comp_operation = 0
##########    @@non_comp_others = 0
##########    @@non_comp_supplies = 0
##########
##########    @@orders = @er_ancillary2.merge(@er_drugs2)
##########    @@orders.each do |order,n|
##########      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
##########      if item[:ph_code] == "PHS01"
##########        amt = item[:rate].to_f * n
##########        @@comp_drugs += amt  # total compensable drug
##########      end
##########      if item[:ph_code] == "PHS02"
##########        x_lab_amt = item[:rate].to_f * n
##########        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
##########      end
##########      if item[:ph_code] == "PHS03"
##########        o_amt = item[:rate].to_f * n
##########        @@comp_operation += o_amt  # total compensable operations
##########      end
##########      if item[:ph_code] == "PHS04"
##########        other_amt = item[:rate].to_f * n
##########        @@comp_others += other_amt  # total compensable others
##########      end
##########      if item[:ph_code] == "PHS05"
##########        supp_amt = item[:rate].to_f * n
##########        @@comp_supplies += supp_amt  # total compensable supplies
##########      end
##########      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "N"
##########        n_amt = item[:rate].to_f * n
##########        @@non_comp_drugs += n_amt # total non-compensable drug
##########      end
##########      if item[:ph_code] == "PHS06" && item[:mrp_tag] == "Y"
##########        n_amt_tag = item[:rate].to_f * n
##########        @@non_comp_drugs_mrp_tag += n_amt_tag # total non-compensable drug with mrp_tag
##########      end
##########      if item[:ph_code] == "PHS07"
##########        n_x_lab_amt = item[:rate].to_f * n
##########        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
##########      end
##########      if item[:ph_code] == "PHS08"
##########        n_o_amt = item[:rate].to_f * n
##########        @@non_comp_operation += n_o_amt # total non compensable operations
##########      end
##########      if item[:ph_code] == "PHS09"
##########        n_other_amt = item[:rate].to_f * n
##########        @@non_comp_others += n_other_amt  # total non compensable others
##########      end
##########      if item[:ph_code] == "PHS10"
##########        s_amt = item[:rate].to_f * n
##########        @@non_comp_supplies += s_amt  # total non compensable supplies
##########      end
##########    end
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if the actual charge for drugs/medicine is correct" do
##########    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
##########    total_drugs = @@comp_drugs + @@non_comp_drugs
##########    @@actual_medicine_charges = total_drugs - (@@promo_discount4 * total_drugs)
##########    @@er_ph2[:er_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if the actual benefit claim for drugs/medicine is correct" do
##########    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount4)
##########    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim9
##########      @@actual_medicine_benefit_claim10 = @@comp_drugs_total
##########    else
##########      @@actual_medicine_benefit_claim10 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim9
##########    end
##########    @@er_ph2[:er_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if the actual charge for xrays, lab and others is correct" do
##########    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
##########    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount4)
##########    @@er_ph2[:er_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if the actual lab benefit claim is correct" do
##########    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount4 * @@comp_xray_lab)
##########    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
##########    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim9
##########      @@actual_lab_benefit_claim10 = @@actual_comp_xray_lab_others
##########    else
##########      @@actual_lab_benefit_claim10 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim9
##########    end
##########    @@er_ph2[:er_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
##########  end
##########
########## it "Radiation Oncology - ER(6 Procedures) : Checks if the actual charge for operation is correct" do
##########    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount4) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount4))
##########    @@er_ph2[:er_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if the actual operation benefit claim is correct" do
##########    @sessions = 6
##########    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
##########    if @sessions
##########      @@actual_operation_benefit_claim10 =  @@operation_ph_benefit[:max_amt].to_f +  (1200.00 * @sessions)
##########    elsif @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
##########      @@actual_operation_benefit_claim10 = @@actual_operation_charges
##########    else
##########      @@actual_operation_benefit_claim10 = @@operation_ph_benefit[:max_amt].to_f
##########    end
##########    @@er_ph2[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if the total actual charge(s) is correct" do
##########    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
##########    @@er_ph2[:er_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if the total actual benefit claim is correct" do
##########    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim10 + @@actual_lab_benefit_claim10 + @@actual_operation_benefit_claim10
##########    @@er_ph2[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if the maximum benefits are correct" do
##########    @@er_ph2[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
##########    @@er_ph2[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
##########    @@er_ph2[:er_max_benefit_operation].should == "RVU x PCF"
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if Deduction Claims are correct" do
##########    @@er_ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
##########    @@er_ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
##########    @@er_ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if Remaining Benefit Claims are correct" do
##########    if @@actual_medicine_benefit_claim10 < @@med_ph_benefit[:max_amt].to_f
##########      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10 + @@actual_medicine_benefit_claim9)
##########    else
##########      @@drugs_remaining_benefit_claim = 0.0
##########    end
##########    @@er_ph2[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim))
##########
##########    if @@actual_lab_benefit_claim10 < @@lab_ph_benefit[:max_amt].to_f
##########      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim10 + @@actual_lab_benefit_claim9)
##########    else
##########      @@lab_remaining_benefit_claim = 0.0
##########    end
##########    @@er_ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim))
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if computation of PF claims surgeon is applied correctly" do
##########    @@er_ph2[:surgeon_benefit_claim].should == nil
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks if computation of PF claims anesthesiologist is applied correctly" do
##########    @@er_ph2[:anesthesiologist_benefit_claim].should == nil
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Checks No Claim History" do
##########    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : View Details of the ordered items" do
##########    slmc.ph_view_details(:close => true).should == 9
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Prints PhilHealth Form and Prooflist" do
##########    slmc.ph_print_report.should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Update Guarantor" do
##########    slmc.go_to_er_billing_page
##########    slmc.patient_pin_search(:pin => @@er_pin)
##########    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
##########    slmc.click_new_guarantor
##########    slmc.pba_update_guarantor
##########    slmc.click_submit_changes.should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Discharges the patient in PBA" do
##########    slmc.go_to_er_billing_page
##########    slmc.patient_pin_search(:pin => @@er_pin)
##########    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
##########    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
##########    slmc.discharge_to_payment.should be_true
##########  end
##########
##########  it "Radiation Oncology - ER(6 Procedures) : Prints Gate Pass of the patient" do
##########    slmc.go_to_er_page
##########    slmc.er_print_gatepass(:pin => @@er_pin, :visit_no => @@visit_no6).should be_true
##########  end
 
end
