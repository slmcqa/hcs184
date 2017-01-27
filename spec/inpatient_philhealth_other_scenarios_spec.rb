require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Inpatient - Philhealth Other Scenarios" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @patient1 = Admission.generate_data(:senior => true)
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient1[:age])
    @discount_type_code = "C01" if @@promo_discount == 0.16
    @discount_type_code = "C02" if @@promo_discount == 0.2

    @user = "gu_spec_user8"
    @password = "123qweuser"
    @room_rate = 4167.0
    @discount_amount = (@room_rate * @@promo_discount)
    @room_discount = @room_rate - @discount_amount
    @days = 1

    @drugs1 = {"042090007" => 1, "041840008" => 1, "049000028" => 1, "041844322" => 1, "048470011" => 1, "040800031" => 1, "040950576" => 1, "040010002" => 1}
    @ancillary1 = {"010000017"=>1, "010001039"=>1, "010000317"=>1, "010000211"=>1, "010000003"=>1, "010000212"=>1}
    @supplies1 = {"085100003" => 1, "080100023" => 1, }
    @operation1 = {"060000058" => 1, "060000003" => 1}

    @drugs2 = {"042090007" => 1, "041840008" => 1, "049000028" => 1, "041844322" => 1, "048470011" => 1, "040800031" => 1, "040950576" => 1, "040010002" => 1}
    @ancillary2 = {"010000317" => 1, "010001039" => 1, "010000212" => 1}
    @supplies2 = {"085100003" => 1, "080100023" => 1}
    @operation2 = {"060000003" => 1, "060000058" => 1}

    @drugs3 = {"042090007" => 1, "041840008" => 1, "049000028" => 1, "041844322" => 1, "048470011" => 1, "040800031" => 1, "040950576" => 1, "040010002" => 1}
    @ancillary3 = {"010000017"=>1, "010001039"=>1, "010000317"=>1, "010000211"=>1, "010000003"=>1, "010000212"=>1}
    @supplies3 = {"085100003" => 1, "080100023" => 1}
    @operation3 = {"060000003" => 1, "060000058" => 1}

    @drugs11 = {"040800031" => 1, "049000028" => 1, "040010002" => 1}
    @ancillary11 = {"010000003" => 1, "010000008" => 1}
    @supplies11 = {"080100023" => 1}
    @operation11 = {"060000058" => 1}

    @drugs12 = {"040800031" => 1, "049000028" => 1, "040010002" => 1}
    @ancillary12 = {"010000003" => 1, "010000008" => 1}
    @supplies12 = {"080100023" => 1}
    @operation12 = {"060000058" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

#Scenario 1
#Inpatient, Catastrophic Case
#Account Class: Individual
#DENGUE HEMORRHAGIC FEVER (A91)

  it "Scenario 1 : Inpatient - Catastrophic Case - Create and Admit" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin = slmc.create_new_patient(@patient1).gsub(' ', '')
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end
  it "Scenario 1 : Order items" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs1.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:drugs => 8).should be_true
    slmc.verify_ordered_items_count(:ancillary => 6).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 16
    slmc.confirm_validation_all_items.should be_true
  end
  it "Scenario 1 : Order Procedures" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 2
    slmc.confirm_validation_all_items.should be_true
  end
  it "Scenario 1 : Clinical Discharge Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
  end
  it "Scenario 1 : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days, :pin => @@pin, :visit_no => @@visit_no1)
    Database.connect
    @days.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no1,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no1, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days - i)
    end
    Database.logoff
  end
  it "Scenario 1 : Go to PhilHealth page and computes PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end
  it "Scenario 1 : Check Benefit Summary totals" do
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

    @@orders = @drugs1.merge(@ancillary1).merge(@supplies1).merge(@operation1)
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
  it "Scenario 1 : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    if @patient1[:age] < 60
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount) + @@non_comp_drugs_mrp_tag
    else
      total_drugs = @@comp_drugs + @@non_comp_drugs + @@non_comp_drugs_mrp_tag
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount)
    end
    @@ph1[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end
  it "Scenario 1 : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim1 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
    end
    @@actual_medicine_benefit_claim1 = 0.00
    @@ph1[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))

  end
  it "Scenario 1 : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end
  it "Scenario 1 : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@actual_lab_benefit_claim1 = 0.00
    @@ph1[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
  end
  it "Scenario 1 : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days
    @@ph1[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end
  it "Scenario 1 : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim1 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB01")
    @@actual_room_benefit_claim1 = @@room_benefit_claim1[:daily_amt].to_i * @days
    @@actual_room_benefit_claim1 = 0.00
    @@ph1[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim1))
  end
  it "Scenario 1 : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph1[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end
  it "Scenario 1 : Checks if the actual operation benefit claim is correct" do
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
      @@actual_operation_benefit_claim1 = 0.00
     @@ph1[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end
  it "Scenario 1 : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph1[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end
  it "Scenario 1 : Checks if the total actual benefit claim is correct" do
        @@pf_amount = slmc.get_pf_rate(:rvs_code => "10060")
        case_rate =slmc.get_case_rate(:rvs_code => "10060")
        @@total_actual_benefit_claim  = (case_rate - @@pf_amount)

   ##### @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1 + @@actual_room_benefit_claim1

    ((slmc.truncate_to((@@ph1[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01

  end
  it "Scenario 1 : Checks if the maximum benefits are correct" do
####    @@ph1[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
####    @@ph1[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
####    @@ph1[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
    @@ph1[:er_max_benefit_drugs].should == 4200.00
    @@ph1[:er_max_benefit_xray_lab_others].should == 3200.00
    @@ph1[:er_max_benefit_operation].should == 1200.00
  end
  it "Scenario 1 : Checks if Deduction Claims are correct" do
    @@ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
    @@ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end
  it "Scenario 1 : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim1 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
    else
      @@drugs_remaining_benefit_claim1 = 0.0
    end
    @@drugs_remaining_benefit_claim1 = 4200.00
    @@ph1[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim1))

    if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
    else
      @@lab_remaining_benefit_claim1 = 0
    end
    @@lab_remaining_benefit_claim1 = 3200.00
    @@ph1[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim1))
  end
  it "Scenario 1 : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph1[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
     @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@pf_amount))
  end
  it "Scenario 1 : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph1[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph1[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph1[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end
  it "Scenario 1 : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end
  it "Scenario 1 : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 18
  end
  it "Scenario 1 : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end
  it "Scenario 1 : Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end
  it "Scenario 1 : Prints Gate Pass of the patient" do
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

######Scenario 2
######Outpatient, Catastrophic case,
######same final diagnosis and within 90 days from the previous confinement
######Account Class: Individual
######DENGUE HEMORRHAGIC FEVER (A91)

  it "Scenario 2 : Outpatient - Admit Patient in OR" do
    slmc.login("slaquino", @password).should be_true
    slmc.or_register_patient(:pin => @@pin, :org_code => "0164")
  end
  it "Scenario 2 : Order items" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@pin)
    @drugs2.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary2.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies2.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 8).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 3).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 13
    slmc.confirm_validation_all_items.should be_true
  end
  it "Scenario 2 : Order Procedures" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "GASTRIC SURGERY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end
  it "Scenario 2 : Clinical Discharge Patient" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no2 = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@pin, :save => true, :pf_amount => "1000").should be_true
  end
  it "Scenario 2 : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days, :pin => @@pin, :visit_no => @@visit_no2)
    Database.connect
    @days.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no2,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no2, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days - i)
    end
    Database.logoff
  end
  it "Scenario 2 : Compute PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@pin)
    slmc.click_philhealth_link(:pin => @@pin, :visit_no => @@visit_no2)
    @@ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "21325", :compute => true)
    slmc.ph_save_computation
  end
  it "Scenario 2 : Check Benefit Summary totals" do
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

    @@orders = @ancillary2.merge(@supplies2).merge(@drugs2).merge(@operation2)
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
  it "Scenario 2 : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    if @patient1[:age] < 60
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount) + @@non_comp_drugs_mrp_tag
    else
      total_drugs = @@comp_drugs + @@non_comp_drugs + @@non_comp_drugs_mrp_tag
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount)
    end
    @@ph2[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end
  it "Scenario 2 : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1)
      @@actual_medicine_benefit_claim2 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1)
    end
    @@ph2[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
  end
  it "Scenario 2 : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph2[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end
  it "Scenario 2 : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1)
      @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1)
    end
    @@ph2[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
  end
  it "Scenario 2 : Checks if the actual charge for room and board is correct" do
    @@ph2[:room_and_board_actual_charges].should == "N/A" # v1.4.2
  end
  it "Scenario 2 : Checks if the actual room benefit claim is correct" do
    @@ph2[:room_and_board_actual_benefit_claim].should == (@days).to_s # v1.4.2
  end
  it "Scenario 2 : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph2[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end
  it "Scenario 2 : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.2")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim2 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph2[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
    else
      @@actual_operation_benefit_claim2 = 0.00
      @@ph2[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
    end
  end
  it "Scenario 2 : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@ph2[:or_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end
  it "Scenario 2 : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2
    ((slmc.truncate_to((@@ph2[:or_total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end
  it "Scenario 2 : Checks if the maximum benefits are correct" do
    @@ph2[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph2[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph2[:or_max_benefit_operation] ==  ("%0.2f" %(@@operation_ph_benefit[:max_amt].to_f))
  end
  it "Scenario 2 : Checks if Deduction Claims are correct" do
    @@ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
    @@ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    @@ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end
  it "Scenario 2 : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim2 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
    else
      @@drugs_remaining_benefit_claim2 = 0.0
    end
    @@ph2[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim2))

    if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
    else
      @@lab_remaining_benefit_claim2 = 0
    end
    @@ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim2))
  end
  it "Scenario 2 : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21325")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph2[:surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph2[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph2[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end
  it "Scenario 2 : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph2[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph2[:anesthesiologist_benefit_claim].should == ("%0.2f" %(0.0)) #8000.0
    else
      @@ph2[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end
  it "Scenario 2 : Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end
  it "Scenario 2 : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 15
  end
  it "Scenario 2 : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end
  it "Scenario 2 : Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end
  it "Scenario 2 : Prints Gate Pass of the patient" do
    slmc.login("slaquino", @password).should be_true
    slmc.or_print_gatepass(:pin => @@pin, :visit_no => @@visit_no2).should be_true
  end
##########Scenario 3
##########Inpatient, Catastrophic case,
##########Same final diagnosis, within 90 days from the 1st and 2nd availment
##########Account Class: Individual
##########DENGUE HEMORRHAGIC FEVER (A91)

  it "Scenario 3 : Inpatient - Catastrophic Case - Create and Admit" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it "Scenario 3 : Order items" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs3.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.verify_ordered_items_count(:ancillary => 6).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 16
    slmc.confirm_validation_all_items.should be_true
  end

  it "Scenario 3 : Order Procedures" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 2
    slmc.confirm_validation_all_items.should be_true
  end

  it "Scenario 3 : Clinical Discharge Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no3 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
  end

  it "Scenario 3 : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days, :pin => @@pin, :visit_no => @@visit_no3)
    Database.connect
    @days.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no3,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no3, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days - i)
    end
    Database.logoff
  end

  it "Scenario 3 : Go to PhilHealth page and computes PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph3 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "21267", :compute => true)
    slmc.ph_save_computation
  end

  it "Scenario 3 : Check Benefit Summary totals" do
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

    @@orders = @drugs3.merge(@ancillary3).merge(@supplies3).merge(@operation3)
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

  it "Scenario 3 : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    if @patient1[:age] < 60
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount) + @@non_comp_drugs_mrp_tag
    else
      total_drugs = @@comp_drugs + @@non_comp_drugs + @@non_comp_drugs_mrp_tag
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount)
    end
    @@ph3[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Scenario 3 : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1) <= 0
      @@actual_medicine_benefit_claim3 = 0.0
    elsif @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
      @@actual_medicine_benefit_claim3 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
    end
    @@ph3[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
  end

  it "Scenario 3 : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph3[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Scenario 3 : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
      @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
    end
    @@ph3[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
  end

  it "Scenario 3 : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days
    @@ph3[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "Scenario 3 : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim3 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB01")
    @@actual_room_benefit_claim3 = @@room_benefit_claim3[:daily_amt].to_i * @days
    @@ph3[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim3))
  end

  it "Scenario 3 : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph3[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Scenario 3 : Checks if the actual operation benefit claim is correct" do
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
    @@ph3[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "Scenario 3 : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph3[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "Scenario 3 : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3 + @@actual_room_benefit_claim3
    ((slmc.truncate_to((@@ph3[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "Scenario 3 : Checks if the maximum benefits are correct" do
    @@ph3[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph3[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph3[:er_max_benefit_operation].should == "RVU x PCF"
  end

  it "Scenario 3 : Checks if Deduction Claims are correct" do
    @@ph3[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
    @@ph3[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
    @@ph3[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "Scenario 3 : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim3 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
    else
      @@drugs_remaining_benefit_claim3 = 0.0
    end
    @@ph3[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim3))

    if @@actual_lab_benefit_claim3 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
    else
      @@lab_remaining_benefit_claim3 = 0
    end
    @@ph3[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim3))
  end

  it "Scenario 3 : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21267")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph3[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph3[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph3[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "Scenario 3 : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph3[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph3[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph3[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "Scenario 3 : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "Scenario 3 : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 18
  end

  it "Scenario 3 : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "Scenario 3 : Discharges the patient in PBA" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "Scenario 3 : Prints Gate Pass of the patient" do
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

####Scenario 11
####Inpatient, Ordinary case
####Account Class: HMO
####AMEBIC INFECTION OF OTHER SITES (A06.8)

  it "Scenario 11 : Inpatient - Ordinary Case - Create and Admit" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin = slmc.create_new_patient(@patient1).gsub(' ', '')
    puts @@pin
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "HMO", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE",
      :diagnosis => "GASTRITIS", :doctor_code => "6726", :guarantor_code => "ASALUS (INTELLICARE)").should == "Patient admission details successfully saved."
  end

  it "Scenario 11 : Order items" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @ancillary11.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @drugs11.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @supplies11.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 3).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 6
    slmc.confirm_validation_all_items.should be_true
  end

  it "Scenario 11 : Order Procedures" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Scenario 11 : Clinical Discharge Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no11 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
  end

  it "Scenario 11 : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days, :pin => @@pin, :visit_no => @@visit_no11)
    Database.connect
    @days.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no11,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no11, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)

      @my_date = slmc.increase_date_by_one(@days - i)
    end
    Database.logoff
  end

  it "Scenario 11 : Go to PhilHealth page and computes PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph11 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "Scenario 11 : Check Benefit Summary totals" do
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

    @@orders = @drugs11.merge(@ancillary11).merge(@supplies11).merge(@operation11)
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

  it "Scenario 11 : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    if @patient1[:age] < 60
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount) + @@non_comp_drugs_mrp_tag
    else
      total_drugs = @@comp_drugs + @@non_comp_drugs + @@non_comp_drugs_mrp_tag
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount)
    end
    @@ph11[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Scenario 11 : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim11 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim11 = @@med_ph_benefit[:max_amt].to_f
    end
    @@actual_medicine_benefit_claim11 = 0.00
    @@ph11[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim11))
  end

  it "Scenario 11 : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    #@@actual_xray_lab_others  = 0.00
    @@ph11[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Scenario 11 : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim11 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim11 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@actual_lab_benefit_claim11 = 0.00

    @@ph11[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim11))
  end

  it "Scenario 11 : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days
    @@ph11[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "Scenario 11 : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim11 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB01")
    @@actual_room_benefit_claim11 = @@room_benefit_claim11[:daily_amt].to_i * @days
    @@actual_room_benefit_claim11 = 0.abs
    @@ph11[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim11))
  end

  it "Scenario 11 : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph11[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Scenario 11 : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim11 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim11 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim11 = 0.00
    end
    @@actual_operation_benefit_claim11 = 0.00
    @@ph11[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim11))
  end

  it "Scenario 11 : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph11[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "Scenario 11 : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim11 + @@actual_lab_benefit_claim11 + @@actual_operation_benefit_claim11 + @@actual_room_benefit_claim11
    @@total_actual_benefit_claim = 2800.00
    ((slmc.truncate_to((@@ph11[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "Scenario 11 : Checks if the maximum benefits are correct" do
    @@ph11[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph11[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph11[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "Scenario 11 : Checks if Deduction Claims are correct" do
    @@ph11[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim11))
    @@ph11[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim11))
    @@ph11[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim11))
  end

  it "Scenario 11 : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim11 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim11 = @@med_ph_benefit[:max_amt].to_f
    else
      @@drugs_remaining_benefit_claim11 = 0.0
    end
    @@ph11[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim11))

    if @@actual_lab_benefit_claim11 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim11 = @@lab_ph_benefit[:max_amt].to_f
    else
      @@lab_remaining_benefit_claim11 = 0
    end
    @@lab_remaining_benefit_claim11 = 3200.00
    @@ph11[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim11))
  end

  it "Scenario 11 : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@surgeon_claim = 840.00
     @@ph11[:inpatient_physician_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
#    if @@ph11[:inpatient_physician_benefit_claim].to_i != @@surgeon_claim
#      @@ph11[:inpatient_physician_benefit_claim].should == ("%0.2f" %(8000.0))
#    else
#      @@ph11[:inpatient_physician_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
#    end
  end

  it "Scenario 11 : Checks if computation of PF claims anesthesiologist is applied correctly" do
#    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
#    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
#    if @@ph11[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
#      @@ph11[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
#    else
#      @@ph11[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
#    end
  end

  it "Scenario 11 : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "Scenario 11 : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 7
  end

  it "Scenario 11 : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "Scenario 11 : Update Guarantor" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click_guarantor_to_update
    slmc.pba_update_guarantor(:loa_percent => "100")
    slmc.click_submit_changes.should be_true
  end

  it "Scenario 11 : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true
  end

  it "Scenario 11 : Prints Gate Pass of the patient" do
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

###########Scenario 12
###########Inpatient, Ordinary case
###########Account Class: Company
###########AMEBIC INFECTION OF OTHER SITES (A06.8)
############
  it "Scenario 12 : Inpatient - Ordinary Case - Create and Admit" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "COMPANY", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE",
      :diagnosis => "GASTRITIS", :doctor_code => "6726", :guarantor_code => "ACCENTURE").should == "Patient admission details successfully saved."
  end

  it "Scenario 12 : Order items" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @ancillary12.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @drugs12.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @supplies12.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 3).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 6
    slmc.confirm_validation_all_items.should be_true
  end

  it "Scenario 12 : Order Procedures" do
    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Scenario 12 : Clinical Discharge Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no12 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
  end

  it "Scenario 12 : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days, :pin => @@pin, :visit_no => @@visit_no12)
    Database.connect
    @days.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no12,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no12, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)

      @my_date = slmc.increase_date_by_one(@days - i)
    end
    Database.logoff
  end

  it "Scenario 12 : Go to PhilHealth page and computes PhilHealth" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph12 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end

  it "Scenario 12 : Check Benefit Summary totals" do
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

    @@orders = @drugs12.merge(@ancillary12).merge(@supplies12).merge(@operation12)
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

  it "Scenario 12 : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    if @patient1[:age] < 60
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount) + @@non_comp_drugs_mrp_tag
    else
      total_drugs = @@comp_drugs + @@non_comp_drugs + @@non_comp_drugs_mrp_tag
      @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount)
    end
    @@ph12[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Scenario 12 : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim11
      @@actual_medicine_benefit_claim12 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim12 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim11
    end
    @@ph12[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim12))
  end

  it "Scenario 12 : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph12[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Scenario 12 : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim11
      @@actual_lab_benefit_claim12 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim12 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim11
    end
    @@ph12[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim12))
  end

  it "Scenario 12 : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days
    @@ph12[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "Scenario 12 : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim12 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB01")
    @@actual_room_benefit_claim12 = @@room_benefit_claim12[:daily_amt].to_i * @days
    @@ph12[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim12))
  end

  it "Scenario 12 : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph12[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Scenario 12 : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim12 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim12 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim12 = 0.00
    end
    @@ph12[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim12))
  end

  it "Scenario 12 : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph12[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "Scenario 12 : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim12 + @@actual_lab_benefit_claim12 + @@actual_operation_benefit_claim12 + @@actual_room_benefit_claim12
    ((slmc.truncate_to((@@ph12[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "Scenario 12 : Checks if the maximum benefits are correct" do
    @@ph12[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph12[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph12[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "Scenario 12 : Checks if Deduction Claims are correct" do
    @@ph12[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim12))
    @@ph12[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim12))
    @@ph12[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim12))
  end

  it "Scenario 12 : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim12 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim12 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim11
    else
      @@drugs_remaining_benefit_claim12 = 0.0
    end
    @@ph12[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim12))

    if @@actual_lab_benefit_claim12 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim12 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim11
    else
      @@lab_remaining_benefit_claim12 = 0.0
    end
    @@ph12[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim12))
  end

  it "Scenario 12 : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph12[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph12[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph12[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "Scenario 12 : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph12[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph12[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph12[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "Scenario 12 : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "Scenario 12 : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 7
  end

  it "Scenario 12 : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "Scenario 12 : Update Guarantor" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click_guarantor_to_update
    slmc.pba_update_guarantor(:loa_percent => "100")
    slmc.click_submit_changes.should be_true
  end

  it "Scenario 12 : Discharges the patient in PBA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true #DAS since 100% coverage
    #slmc.discharge_to_payment.should be_true
  end

  it "Scenario 12 : Prints Gate Pass of the patient" do
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

end