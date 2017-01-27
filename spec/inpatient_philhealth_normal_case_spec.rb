require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

describe "SLMC :: Inpatient - Philhealth Normal Case" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @patient1 = Admission.generate_data(:senior => true)
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient1[:age])
    @discount_type_code = "C01" if @@promo_discount == 0.16
    @discount_type_code = "C02" if @@promo_discount == 0.2

    @password = "123qweuser"
#    @user = "gu_spec_user8"
#    @or_user =  "slaquino"     #"or21"
#    @pba_user = "ldcastro" #"sel_pba7"

    
            @user = "fcdeleon"  #"billing_spec_user3"  #admission_login#
    @pba_user = "dmgcaubang" #"sel_pba7"
    @or_user =  "amlompad"     #"or21"
    @oss_user = "kjcgangano-pet"  #"sel_oss7"
    @dr_user = "aealmonte" #"sel_dr4"
    @er_user =  "asbaltazar"   #"sel_er4"
    @wellness_user = "emllacson-wellness" # "sel_wellness2"
    @gu_user_0287 = "ajpsolomon"

    
    
    
    
    
    
    @room_rate = 4167.0
    @discount_amount = (@room_rate * @@promo_discount)
    @room_discount = @room_rate - @discount_amount
    @room_days = 45

 #   @days1 = 3 # within 90 days

    @days1 = 47 # within 90 days


    @days2 = 5 # within 90 days
    @days3 = 3 # within 90 days
    @days4 = 5 # outside 90 days
    @days5 = 3 # within 90days of days4
    @days6 = 2 # within 90days of days4
    @days7 = 25 # different year from days6
    @days8 = 20 # within 90 days of days7
    @days9 = 2 # outside 90 days of days8
    @days10 = 1 # different year from days9
    @days11 = 1 # within 90 days of days10
    @days12 = 1 # within 90 days of days10

    @drugs1 =  {"042090007" => 1, "041840008" => 1, "049000028" => 1, "040950558" => 1}
    @ancillary1 = {"010000317" => 1, "010000212" => 1, "010001039" => 1, "010000211" => 1}
    @supplies1 = {"085100003" => 1, "080100023" => 1}
    @operation1 = {"060000058" => 1, "060000003" => 1}

    @drugs2 = {"042090007" => 1, "041840008" => 1, "049000028" => 1, "040950558" => 1, "041844322" => 1, "048470011" => 1}    
    @ancillary2 = {"010000317" => 1, "010000212" => 1, "010001039" => 1}
    @supplies2 = {"085100003" => 1, "080100023" => 1}
    @operation2 = {"060000058" => 1, "060000003" => 1}

    @drugs3 = {"042090007" => 1, "041840008" => 1, "049000028" => 1, "041844322" => 1, "048470011" => 1, "040800031" => 1, "040950576" => 1, "040010002" => 1}    
    @ancillary3 = {"010000317" => 1, "010001039" => 1, "010000212" => 1, "010000211" => 1}
    @supplies3 = {"085100003" => 1, "080100023" => 1}
    @operation3 = {"060000058" => 1, "060000003" => 1}

    @drugs4 = {"040800031" => 1, "040860043" => 1, "041840008" => 1, "041844322" => 1, "042000061" => 1, "042090007" => 1, "044810074" => 1, "047632803" => 1, "048414006" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1}
    @ancillary4 = {"010000008" => 1, "010000003" => 1}
    @supplies4 = {"085100003" => 1, "089100004" => 1, "080100021" => 1, "080100023" => 1}
    @operation4 = {"060000434" => 1, "060000038" => 1}

    @drugs5 = {"042090007" => 1, "049000028" => 1, "041844322" => 1, "048470011" => 1, "042000061" => 1, "048414006" => 1, "044810074" => 1, "040860043" => 1, "040010002" => 1}
    @ancillary5 = {"010000600" => 1, "010000611" => 1}
    @supplies5 = {"085100003" => 1, "089100004" => 1, "080100021" => 1, "080100023" => 1}
    @operation5 = {"060000058" => 1, "060000003" => 1}

    @drugs6 = {"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1}
    @ancillary6 = {"010000008" => 1, "010000003" => 1}
    @supplies6 = {"080100021" => 1, "080100023" => 1}
    @operation6 = {"060000058" => 1, "060000003" => 1}

    @drugs7 = {"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1}
    @ancillary7 = {"010000003" => 1, "010000008" => 1}
    @supplies7 = {"080100021" => 1, "080100023" => 1}
    @operation7 =  {"060000058" => 1, "060000003" => 1}

    @drugs8 = {"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1}
    @ancillary8 = {"010000008" => 1, "010000003" => 1}
    @supplies8 = {"080100021" => 1, "080100023" => 1}
    @operation8 = {"060000058" => 1, "060000003" => 1}

    @drugs9 = {"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1}
    @ancillary9 = {"010000008" => 1, "010000003" => 1}
    @supplies9 = {"080100021" => 1, "080100023" => 1}
    @operation9 = {"060000058" => 1, "060000003" => 1}

    @drugs10 = {"040800031" => 1, "040010002" => 1}
    @ancillary10 = {"010000008" => 1}
    @operation10 = {"060000000" => 1}

    @drugs11 = {"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1}
    @ancillary11 = {"010000008" => 1, "010000003" => 1}
    @operation11 = {"060000000" => 1}

    @drugs12 = {"040800031" => 1, "040860043" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1}
    @ancillary12 = {"010000008" => 1, "010000003" => 1}
    @operation12 = {"060000000" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

#####1st Availment
#####Ordinary Case
#####DENGUE HEMORRHAGIC FEVER (A91)
#####3 days
####
#####    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
#####    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 10
#####    slmc.confirm_validation_all_items.should be_true
#####  end

  it "1st Availment : Ordinary Case - Admit and Order items" do
    slmc.login(@user, @password).should be_true
    
  #      slmc.login("adm1", @password).should be_true
    slmc.admission_search(:pin => "Test")
#    @@pin = slmc.create_new_patient(@patient1).gsub(' ', '')
        @@pin = "1408074316"

    puts @@pin
    sleep 6
        #slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    sleep 6
   #     slmc.login("efpanelo", @password).should be_true
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
    @supplies1.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 10
    slmc.verify_ordered_items_count(:drugs => 4).should be_true
    slmc.verify_ordered_items_count(:ancillary => 4).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
   #  slmc.validate_orders(:drugs => true, :supplies => true, :ancillary => true, :orders => "multiple").should == 10
#slmc.click("//input[@value='SUBMIT']",:wait_for => :page);
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 10
    sleep 6
    slmc.confirm_validation_all_items.should be_true
  end
  
  it "1st Availment : Orders Procedures" do
    sleep 6
    slmc.login(@or_user, @password).should be_true
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

  it "1st Availment : Clinical Discharge Patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    puts @@visit_no1
    sleep 10
  end

  it "1st Availment : Database Manipulation - Add and Edit records of patient" do
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

  it "1st Availment : Go to PhilHealth page and computes PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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

  it "1st Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph1[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "1st Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim1 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph1[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
  end

  it "1st Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "1st Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph1[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
  end

  it "1st Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph1[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "1st Availment : Checks if the actual operation benefit claim is correct" do
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

  it "1st Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days1
    @@ph1[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "1st Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim1 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB01")
    @@actual_room_benefit_claim1 = @@room_benefit_claim1[:daily_amt].to_i * @days1
    @@ph1[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim1))
  end

  it "1st Availment : Checks if the deduction for room and board is correct" do
    @@ph1[:room_and_board_deduction].should == (@days1).to_s
  end

  it "1st Availment : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining1 = (@room_days - @days1)
    @@ph1[:room_and_board_remaining].should == (@@room_remaining1).to_s
  end

  it "1st Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph1[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "1st Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1 + @@actual_room_benefit_claim1
    ((slmc.truncate_to((@@ph1[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "1st Availment : Checks if the maximum benefits are correct" do
    @@ph1[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph1[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph1[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
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
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph1[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph1[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "1st Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph1[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph1[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph1[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
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
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "1st Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

#########2nd Availment
########Ordinary case
########same final diagnosis and within 90 days from the previous availment
########DENGUE HEMORRHAGIC FEVER (A91)
########5 days

  it "2nd Availment : Ordinary case, same final diagnosis and within 90 days from the previous availment" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
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
    slmc.verify_ordered_items_count(:drugs => 6).should be_true
    slmc.verify_ordered_items_count(:ancillary => 3).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 11
    slmc.confirm_validation_all_items.should be_true
  end
  it "2nd Availment : Orders Procedures" do
    sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    sleep 2
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    sleep 2
    @@item_code2 = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    sleep 2
    slmc.add_returned_service(:item_code => @@item_code2, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    sleep 2
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 2
    slmc.confirm_validation_all_items.should be_true
  end
  it "2nd Availment : Clinical Discharge Patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    sleep 20
  end
  it "2nd Availment : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days2, :pin => @@pin, :visit_no => @@visit_no2)
    Database.connect
    @days2.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no2,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no2, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days2 - i)
    end
    Database.logoff
  end
  it "2nd Availment : Go to PhilHealth page and computes PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "21325", :compute => true)
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

    @@orders = @drugs2.merge(@ancillary2).merge(@supplies2).merge(@operation2)
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
  it "2nd Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph2[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end
  it "2nd Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1)
      @@actual_medicine_benefit_claim2 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1)
    end
    @@ph2[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
  end
  it "2nd Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph2[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end
  it "2nd Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1)
      @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1)
    end
    @@ph2[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
  end
  it "2nd Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph2[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end
  it "2nd Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.2")
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
  it "2nd Availment : Checks if the actual charge for room and board is correct" do
      myti = Time.now
      mytime =  myti.hour
      if mytime <= 11
      @@actual_room_charges = @room_discount * @days2

      end
      if mytime >= 11
      @@actual_room_charges = @room_discount * @days2 + 1
      end
      @@ph2[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end
  it "2nd Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim2 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB01")
    @@actual_room_benefit_claim2 = @@room_benefit_claim2[:daily_amt].to_i * @days2
    @@ph2[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim2))
  end

  it "2nd Availment : Checks if the deduction for room and board is correct" do
    @@ph2[:room_and_board_deduction].should == (@days2).to_s
  end

  it "2nd Availment : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining2 = (@@room_remaining1 - @days2)
    @@ph2[:room_and_board_remaining].should == (@@room_remaining2).to_s
  end

  it "2nd Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph2[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "2nd Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2 + @@actual_room_benefit_claim2
    ((slmc.truncate_to((@@ph2[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "2nd Availment : Checks if the maximum benefits are correct" do
    @@ph2[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph2[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph2[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "2nd Availment : Checks if Deduction Claims are correct" do
    @@ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
    @@ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    @@ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "2nd Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim2 < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
      @@drugs_remaining_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim1)
    else
      @@drugs_remaining_benefit_claim2 = 0.0
    end
    @@ph2[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim2))

    if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
      @@lab_remaining_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim1)
    else
      @@lab_remaining_benefit_claim2 = 0
    end
    @@ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim2))
  end

  it "2nd Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21325")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph2[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "2nd Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph2[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph2[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0))
    else
      @@ph2[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "2nd Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "2nd Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 13
  end

  it "2nd Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "2nd Availment : Discharges the patient in PBA" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "2nd Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

#######3rd Availment
#######Catastrophic case
#######different final diagnosis, within 90 days from the previous availment
#######CALIFORNIA ENCEPHALITIS (A83.5)
#######3 days

  it "3rd Availment : Catastrophic case, same final diagnosis and within 90 days from the previous availment" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs3.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary3.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item , :add => true, :doctor => "0126").should be_true
    end
    @supplies3.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 8).should be_true
    slmc.verify_ordered_items_count(:ancillary => 4).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 14
    slmc.confirm_validation_all_items.should be_true
  end

  it "3rd Availment : Orders Procedures" do
    sleep 6
    slmc.login(@or_user, @password).should be_true
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

  it "3rd Availment : Clinical Discharge Patient" do
        sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no3 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    sleep 10
  end

  it "3rd Availment : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days3, :pin => @@pin, :visit_no => @@visit_no3)
    Database.connect
    @days3.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no3,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no3, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days3 - i)
    end
    Database.logoff
  end

  it "3rd Availment : Go to PhilHealth page and computes PhilHealth" do
        sleep 6

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph3 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CALIFORNIA ENCEPHALITIS", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "21267", :compute => true)
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

    @@orders = @ancillary3.merge(@supplies3).merge(@drugs3).merge(@operation3)
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

  it "3rd Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    if @patient1[:age] < 60
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount) + @@non_comp_drugs_mrp_tag
    else
      total_drugs = @@comp_drugs + @@non_comp_drugs + @@non_comp_drugs_mrp_tag
      @@actual_medicine_charges = total_drugs -  (total_drugs * @@promo_discount)
    end
    @@ph3[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "3rd Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim3 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f
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
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph3[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
  end

  it "3rd Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph3[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
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
    @@ph3[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "3rd Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days3
    @@ph3[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "3rd Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim3 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB01")
    @@actual_room_benefit_claim3 = @@room_benefit_claim3[:daily_amt].to_i * @days3
    @@ph3[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim3))
  end

  it "3rd Availment : Checks if the deduction for room and board is correct" do
    @@ph3[:room_and_board_deduction].should == (@days3).to_s
  end

  it "3rd Availment : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining3 = (@@room_remaining2 - @days3)
    @@ph3[:room_and_board_remaining].should == (@@room_remaining3).to_s
  end

  it "3rd Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph3[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "3rd Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3 + @@actual_room_benefit_claim3
    ((slmc.truncate_to((@@ph3[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "3rd Availment : Checks if the maximum benefits are correct" do
    @@ph3[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph3[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph3[:er_max_benefit_operation].should == "RVU x PCF"
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
    if @@ph3[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph3[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph3[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "3rd Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph3[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph3[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph3[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "3rd Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "3rd Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 16
  end

  it "3rd Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

 it "3rd Availment : Discharges the patient in PBA" do
       sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "3rd Availment : Prints Gate Pass of the patient" do
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "4th Availment : Adjusts PH Date Time 1st 2nd and 3rd availments" do
    slmc.adjust_ph_date(:days_to_adjust => 110, :visit_no => @@visit_no1)
    slmc.adjust_ph_date(:days_to_adjust => 106, :visit_no => @@visit_no2)
    slmc.adjust_ph_date(:days_to_adjust => 99, :visit_no => @@visit_no3)
  end

#4th Availment
#Catastrophic case
#same final diagnosis, outside 90 days from the previous availment
#Claim Type: Refund
#CALIFORNIA ENCEPHALITIS (A83.5)
#5 days

  it "4th Availment : Catastrophic Case - Admit and Order items" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs4.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 18
    slmc.confirm_validation_all_items.should be_true
  end

  it "4th Availment : Orders Procedures" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "OPERATING ROOM CHARGES")
    slmc.add_returned_service(:item_code => @@item_code, :description => "OPERATING ROOM CHARGES")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "VEIN STRIPPING/LIGATION")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "VEIN STRIPPING/LIGATION")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 2
    slmc.confirm_validation_all_items.should be_true
  end

  it "4th Availment : Clinical Discharge Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no4 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    sleep 10
  end

  it "4th Availment : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days4, :pin => @@pin, :visit_no => @@visit_no4)
    Database.connect
    @days4.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no4,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no4, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days4 - i)
    end
    Database.logoff
  end

  it "4th Availment : Go to PhilHealth page and computes PhilHealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph4 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CALIFORNIA ENCEPHALITIS", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
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

    @@orders = @drugs4.merge(@ancillary4).merge(@supplies4).merge(@operation4)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph4[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "4th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim4 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph4[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
  end

  it "4th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph4[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "4th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph4[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
  end

  it "4th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph4[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "4th Availment : Checks if the actual operation benefit claim is correct" do
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
    @@ph4[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "4th Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days4
    @@ph4[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "4th Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim4 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB01")
    @@actual_room_benefit_claim4 = @@room_benefit_claim3[:daily_amt].to_i * @days4
    @@ph4[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim4))
  end

  it "4th Availment : Checks if the deduction for room and board is correct" do
    @@ph4[:room_and_board_deduction].should == (@days4).to_s
  end

  it "4th Availment : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining4 = (@@room_remaining3 - @days4)
    @@ph4[:room_and_board_remaining].should == (@@room_remaining4).to_s
  end

  it "4th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph4[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "4th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4 + @@actual_operation_benefit_claim4 + @@actual_room_benefit_claim4
    ((slmc.truncate_to((@@ph4[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "4th Availment : Checks if the maximum benefits are correct" do
    @@ph4[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph4[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph4[:er_max_benefit_operation].should == ("RVU x PCF")
  end

  it "4th Availment : Checks if Deduction Claims are correct" do
    @@ph4[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    @@ph4[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    @@ph4[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "4th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4)
    else
      @@drugs_remaining_benefit_claim4 = 0.0
    end
    @@ph4[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim4))

    if @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4)
    else
      @@lab_remaining_benefit_claim4 = 0
    end
    @@ph4[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim4))
  end

  it "4th Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "4th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 20
  end

  it "4th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

 it "4th Availment : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "4th Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

#5th Availment
#Intensive case
#same final diagnosis within 90 days from the previous availment
#CALIFORNIA ENCEPHALITIS (A83.5)
#3 days

  it "5th Availment : Intensive Case - Admit and Order items" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs5.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 15
    slmc.confirm_validation_all_items.should be_true
  end

  it "5th Availment : Orders Procedures" do
    sleep 6
    slmc.login(@or_user, @password).should be_true
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

  it "5th Availment : Clinical Discharge Patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no5 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    sleep 10
  end

  it "5th Availment : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days5, :pin => @@pin, :visit_no => @@visit_no5)
    Database.connect
    @days5.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no5,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no5, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days5 - i)
    end
    Database.logoff
  end

  it "5th Availment : Go to PhilHealth page and computes PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph5 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CALIFORNIA ENCEPHALITIS", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "29358", :compute => true)
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

    @@orders = @drugs5.merge(@ancillary5).merge(@supplies5).merge(@operation5)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph5[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "5th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4) < 0
     @@actual_medicine_benefit_claim5 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4)
      @@actual_medicine_benefit_claim5  = @@actual_comp_drugs
    else
     @@actual_medicine_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4)
    end
    @@ph5[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
  end

  it "5th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph5[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "5th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4) < 0
      @@actual_lab_benefit_claim5 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4)
      @@actual_lab_benefit_claim5 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4)
    end
    @@ph5[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
  end

  it "5th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph5[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "5th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.2")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim5 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim5 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim5 = 0.00
    end
    @@ph5[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
  end

  it "5th Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days5
    @@ph5[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "5th Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim5 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB01")
    @@actual_room_benefit_claim5 = @@room_benefit_claim5[:daily_amt].to_i * @days5
    @@ph5[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim5))
  end

  it "5th Availment : Checks if the deduction for room and board is correct" do
    @@ph5[:room_and_board_deduction].should == (@days5).to_s
  end

  it "5th Availment : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining5 = (@@room_remaining4 - @days5)
    @@ph5[:room_and_board_remaining].should == (@@room_remaining5).to_s
  end

  it "5th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph5[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "5th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim5 + @@actual_lab_benefit_claim5 + @@actual_operation_benefit_claim5 + @@actual_room_benefit_claim5
    ((slmc.truncate_to((@@ph5[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "5th Availment : Checks if the maximum benefits are correct" do
    @@ph5[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph5[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph5[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "5th Availment : Checks if Deduction Claims are correct" do
    @@ph5[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
    @@ph5[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
    @@ph5[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
  end

  it "5th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim5 < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim4)
      @@drugs_remaining_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim4)
    else
      @@drugs_remaining_benefit_claim5 = 0.0
    end
    @@ph5[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim5))

    if @@actual_lab_benefit_claim5 < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim4)
      @@lab_remaining_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim4)
    else
      @@lab_remaining_benefit_claim5 = 0
    end
    @@ph5[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim5))
  end

  it "5th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("29358")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph5[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph5[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph5[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "5th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph5[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph5[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph5[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "5th Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "5th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 17
  end

  it "5th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "5th Availment : Discharges the patient in PBA" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "5th Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

#6th Availment
#Intensive case
#different final diagnosis, within 90 days from the previous availment
#AMEBIC INFECTION OF OTHER SITES (A06.8)
#2days
  it "6th Availment : Intensive Case - Admit and Order items" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs6.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
  end

  it "6th Availment : Orders Procedures" do
    sleep 6
    slmc.login(@or_user, @password).should be_true
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

  it "6th Availment : Clinical Discharge Patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no6 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    sleep 10
  end

  it "6th Availment : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days6, :pin => @@pin, :visit_no => @@visit_no6)
    Database.connect
    @days6.times do |i|
      @my_date = slmc.increase_date_by_one(@days6 - i)
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no6,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no6, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
    end
    Database.logoff
  end

  it "6th Availment : Go to PhilHealth page and computes PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph6 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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

    @@orders = @drugs6.merge(@ancillary6).merge(@supplies6).merge(@operation6)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph6[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "6th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5) < 0
     @@actual_medicine_benefit_claim6 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5)
      @@actual_medicine_benefit_claim6  = @@actual_comp_drugs
    else
     @@actual_medicine_benefit_claim6 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim5)
    end
    @@ph6[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim6))
  end

  it "6th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph6[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "6th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5) < 0
      @@actual_lab_benefit_claim6 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5)
      @@actual_lab_benefit_claim6 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim6 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim5)
    end
    @@ph6[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim6))
  end

  it "6th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph6[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "6th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim6 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim6 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim6 = 0.00
    end
    @@ph6[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
  end

  it "6th Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days6
    @@ph6[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "6th Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim6 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB01")
    @@actual_room_benefit_claim6 = @@room_benefit_claim6[:daily_amt].to_i * @days6
    @@ph6[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim6))
  end

  it "6th Availment : Checks if the deduction for room and board is correct" do
    @@ph6[:room_and_board_deduction].should == (@days6).to_s
  end

  it "6th Availment : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining6 = (@@room_remaining5 - @days6)
    @@ph6[:room_and_board_remaining].should == (@@room_remaining6).to_s
  end

  it "6th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph6[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "6th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim6 + @@actual_lab_benefit_claim6 + @@actual_operation_benefit_claim6 + @@actual_room_benefit_claim6
    ((slmc.truncate_to((@@ph6[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "6th Availment : Checks if the maximum benefits are correct" do
    @@ph6[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph6[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph6[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "6th Availment : Checks if Deduction Claims are correct" do
    @@ph6[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim6))
    @@ph6[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim6))
    @@ph6[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
  end

  it "6th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim6 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim6 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim6
    else
      @@drugs_remaining_benefit_claim6 = 0.0
    end
    @@ph6[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim6))

    if @@actual_lab_benefit_claim6 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim6 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim6
    else
      @@lab_remaining_benefit_claim6 = 0
    end
    @@ph6[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim6))
  end

  it "6th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph6[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph6[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph6[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "6th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph6[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph6[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph6[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "6th Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "6th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "6th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "6th Availment : Discharges the patient in PBA" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "6th Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

#7th Availment
#Intensive case
#same final diagnosis, different year from the previous availment
#AMEBIC INFECTION OF OTHER SITES (A06.8)
#25 days

  # changing again 1st to 3rd availment since scenario below is DIFFERENT YEAR
  it "7th Availment : Adjusts PH Date Time 1st 2nd and 3rd availments" do
    slmc.adjust_ph_date(:days_to_adjust => 365, :visit_no => @@visit_no1)
    slmc.adjust_ph_date(:days_to_adjust => 364, :visit_no => @@visit_no2)
    slmc.adjust_ph_date(:days_to_adjust => 357, :visit_no => @@visit_no3)
    slmc.adjust_ph_date(:days_to_adjust => 350, :visit_no => @@visit_no4)
    slmc.adjust_ph_date(:days_to_adjust => 346, :visit_no => @@visit_no5)
    slmc.adjust_ph_date(:days_to_adjust => 343, :visit_no => @@visit_no6)
  end

 it "7th Availment : Intensive Case - Admit and Order items" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs7.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
  end

  it "7th Availment : Orders Procedures" do
    slmc.login(@or_user, @password).should be_true
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

  it "7th Availment : Clinical Discharge Patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no7 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    sleep 10
  end

  it "7th Availment : Database Manipulation - Add and Edit records of patient (25days)" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days7, :pin => @@pin, :visit_no => @@visit_no7)
    Database.connect
    @days7.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no7,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no7, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days7 - i)
    end
    Database.logoff
  end

  it "7th Availment : Go to PhilHealth page and computes PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph7 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "AMEBIC INFECTION OF OTHER SITES", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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

    @@orders = @drugs7.merge(@ancillary7).merge(@supplies7).merge(@operation7)
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

  # since current availment is different year, benefit claims should be reset. benefit claim will not be deducted
  it "7th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph7[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "7th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f < 0
     @@actual_medicine_benefit_claim7 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim7  = @@actual_comp_drugs
    else
     @@actual_medicine_benefit_claim7 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph7[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
  end

  it "7th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph7[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "7th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f < 0
      @@actual_lab_benefit_claim7 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim7 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim7 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph7[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
  end

  it "7th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph7[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "7th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim7 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim7 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim7 = 0.00
    end
    @@ph7[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
  end

  it "7th Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days7
    @@ph7[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "7th Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim7 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB01")
    @@actual_room_benefit_claim7 = @@room_benefit_claim7[:daily_amt].to_i * @days7
    @@ph7[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim7))
  end

  it "7th Availment : Checks if the deduction for room and board is correct" do
    @@ph7[:room_and_board_deduction].should == (@days7).to_s
  end

  it "7th Availment : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining7 = (@room_days - @days7)
    @@ph7[:room_and_board_remaining].should == (@@room_remaining7).to_s
  end

  it "7th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph7[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "7th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim7 + @@actual_lab_benefit_claim7 + @@actual_operation_benefit_claim7 + @@actual_room_benefit_claim7
    ((slmc.truncate_to((@@ph7[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "7th Availment : Checks if the maximum benefits are correct" do
    @@ph7[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph7[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph7[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
    @@ph7[:max_benefit_rb] == @@room_benefit_claim7[:max_days]
    @@ph7[:max_benefit_rb_amt_per_day].should == ("%0.2f" %(@@room_benefit_claim7[:daily_amt]))
    @@ph7[:max_benefit_rb_total_amt].should == ("%0.2f" %(@@room_benefit_claim7[:max_amt]))
  end

  it "7th Availment : Checks if Deduction Claims are correct" do
    @@ph7[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
    @@ph7[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
    @@ph7[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
  end

  it "7th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim7 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim7 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim7
    else
      @@drugs_remaining_benefit_claim7 = 0.0
    end
    @@ph7[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim7))

    if @@actual_lab_benefit_claim7 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim7 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim7
    else
      @@lab_remaining_benefit_claim7 = 0
    end
    @@ph7[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim7))
  end

  it "7th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph7[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph7[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph7[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "7th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph7[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph7[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph7[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "7th Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "7th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "7th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "7th Availment : Discharges the patient in PBA" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "7th Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

#8th Availment
#Super Catastrophic case, different final diagnosis
#within 90 days from the previous availment
#GONOCOCCAL INFECTION OF OTHER MUSCULOSKELETAL TISSUE (A54.49)

 it "8th Availment : Super Catastrophic Case - Admit and Order items" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs8.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
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
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
  end

  it "8th Availment : Orders Procedures" do
    sleep 6
    slmc.login(@or_user, @password).should be_true
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

  it "8th Availment : Clinical Discharge Patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no8 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    sleep 10
  end

  it "8th Availment : Database Manipulation - Add and Edit records of patient (20 days)" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days8, :pin => @@pin, :visit_no => @@visit_no8)
    Database.connect
    @days8.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no8,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no8, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days8 - i)
    end
    Database.logoff
  end

  it "8th Availment : Go to PhilHealth page and computes PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph8 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "GONOCOCCAL INFECTION OF OTHER MUSCULOSKELETAL TISSUE", :medical_case_type => "SUPER CATASTROPHIC CASE", :with_operation => true, :rvu_code => "22847", :compute => true)
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

    @@orders = @drugs8.merge(@ancillary8).merge(@supplies8).merge(@operation8)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph8[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "8th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f < 0
     @@actual_medicine_benefit_claim8 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim8  = @@actual_comp_drugs
    else
     @@actual_medicine_benefit_claim8 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph8[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
  end

  it "8th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph8[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "8th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f < 0
      @@actual_lab_benefit_claim8 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim8 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim8 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph8[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
  end

  it "8th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph8[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "8th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim8 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim8 = @@operation_ph_benefit[:min_amt].to_f
      end
    else
      @@actual_operation_benefit_claim8 = 0.00
    end
    @@ph8[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
  end

  it "8th Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days8
    @@ph8[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "8th Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim8 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB01")
    @@actual_room_benefit_claim8 = @@room_benefit_claim8[:daily_amt].to_i * @days8
    @@ph8[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim8))
  end

  it "8th Availment : Checks if the deduction for room and board is correct" do
    @@ph8[:room_and_board_deduction].should == (@days8).to_s
  end

  it "8th Availment : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining8 = (@@room_remaining7 - @days8)
    @@ph8[:room_and_board_remaining].should == (@@room_remaining8).to_s
  end

  it "8th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph8[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "8th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim8 + @@actual_lab_benefit_claim8 + @@actual_operation_benefit_claim8 + @@actual_room_benefit_claim8
    ((slmc.truncate_to((@@ph8[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "8th Availment : Checks if the maximum benefits are correct" do
    @@ph8[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph8[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph8[:er_max_benefit_operation].should == "RVU x PCF"
    @@ph8[:max_benefit_rb].should == @@room_benefit_claim8[:max_days]
    @@ph8[:max_benefit_rb_amt_per_day].should == ("%0.2f" %(@@room_benefit_claim8[:daily_amt]))
    @@ph8[:max_benefit_rb_total_amt].should == ("%0.2f" %(@@room_benefit_claim8[:max_amt]))
  end

  it "8th Availment : Checks if Deduction Claims are correct" do
    @@ph8[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
    @@ph8[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
    @@ph8[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
  end

  it "8th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim8 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim8 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim8
    else
      @@drugs_remaining_benefit_claim8 = 0.0
    end
    @@ph8[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim8))

    if @@actual_lab_benefit_claim8 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim8 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim8
    else
      @@lab_remaining_benefit_claim8 = 0
    end
    @@ph8[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim8))
  end

  it "8th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("22847")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph8[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph8[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph8[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "8th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph8[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph8[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph8[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "8th Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "8th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "8th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "8th Availment : Discharges the patient in PBA" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "8th Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

#9th Availment
#Super Catastrophic case
#room and board > 45 days
#outside 90 days from the previous availment
#MOSQUITO-BORNE VIRAL ENCEPHALITIS (A83)

  it "9th Availment : Adjusts PH Date Time" do
#    slmc.adjust_ph_date(:days_to_adjust => 365, :visit_no => @@visit_no1)
#    slmc.adjust_ph_date(:days_to_adjust => 364, :visit_no => @@visit_no2)
#    slmc.adjust_ph_date(:days_to_adjust => 357, :visit_no => @@visit_no3)
#    slmc.adjust_ph_date(:days_to_adjust => 350, :visit_no => @@visit_no4)
#    slmc.adjust_ph_date(:days_to_adjust => 346, :visit_no => @@visit_no5)
#    slmc.adjust_ph_date(:days_to_adjust => 343, :visit_no => @@visit_no6)
#    slmc.adjust_ph_date(:days_to_adjust => 317, :visit_no => @@visit_no7)
#    slmc.adjust_ph_date(:days_to_adjust => 298, :visit_no => @@visit_no8)

    slmc.adjust_ph_date(:days_to_adjust => 436, :visit_no => @@visit_no1)
    slmc.adjust_ph_date(:days_to_adjust => 435, :visit_no => @@visit_no2)
    slmc.adjust_ph_date(:days_to_adjust => 428, :visit_no => @@visit_no3)
    slmc.adjust_ph_date(:days_to_adjust => 421, :visit_no => @@visit_no4)
    slmc.adjust_ph_date(:days_to_adjust => 417, :visit_no => @@visit_no5)
    slmc.adjust_ph_date(:days_to_adjust => 414, :visit_no => @@visit_no6)
    slmc.adjust_ph_date(:days_to_adjust => 388, :visit_no => @@visit_no7)
    slmc.adjust_ph_date(:days_to_adjust => 369, :visit_no => @@visit_no8)
  end

  it "9th Availment : Super Catastrophic Case - Admit and Order items" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs9.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary9.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @supplies9.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 9
    slmc.confirm_validation_all_items.should be_true
  end

  it "9th Availment : Orders Procedures" do
    sleep 6
    slmc.login(@or_user, @password).should be_true
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

  it "9th Availment : Clinical Discharge Patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no9 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    sleep 10
  end

  it "9th Availment : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days9, :pin => @@pin, :visit_no => @@visit_no9)
    Database.connect
    @days9.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no9,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no9, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days9 - i)
    end
    Database.logoff
  end

  it "9th Availment : Go to PhilHealth page and computes PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph9 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "MOSQUITO-BORNE VIRAL ENCEPHALITIS", :medical_case_type => "SUPER CATASTROPHIC CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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

    @@orders = @drugs9.merge(@ancillary9).merge(@supplies9).merge(@operation9)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph9[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "9th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f < 0
     @@actual_medicine_benefit_claim9 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim9  = @@actual_comp_drugs
    else
     @@actual_medicine_benefit_claim9 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph9[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim9))
  end

  it "9th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph9[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "9th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f < 0
      @@actual_lab_benefit_claim9 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim9 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim9 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph9[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim9))
  end

  it "9th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph9[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "9th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim9 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim9 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim9 = 0.00
    end
    @@ph9[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim9))
  end

  it "9th Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days9
    @@ph9[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "9th Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim9 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB01")
    @@actual_room_benefit_claim9 = @@room_benefit_claim9[:daily_amt].to_i * @days9
    @@ph9[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim9))
  end

  it "9th Availment : Checks if the deduction for room and board is correct" do
    @@ph9[:room_and_board_deduction].should == (@days9).to_s
  end

  it "9th Availment : Checks if the remaining benefits for room and board is correct" do # this varies whether it 90days is the previous year or only current year
    @@room_remaining9 = (@room_days - @days9)
    @@ph9[:room_and_board_remaining].should == (@@room_remaining9).to_s
  end

  it "9th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph9[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "9th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim9 + @@actual_lab_benefit_claim9 + @@actual_operation_benefit_claim9 + @@actual_room_benefit_claim9
    ((slmc.truncate_to((@@ph9[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "9th Availment : Checks if the maximum benefits are correct" do
    @@ph9[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph9[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph9[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
    @@ph9[:max_benefit_rb].should == @@room_benefit_claim9[:max_days]
    @@ph9[:max_benefit_rb_amt_per_day].should == ("%0.2f" %(@@room_benefit_claim9[:daily_amt]))
    @@ph9[:max_benefit_rb_total_amt].should == ("%0.2f" %(@@room_benefit_claim9[:max_amt]))
  end

  it "9th Availment : Checks if Deduction Claims are correct" do
    @@ph9[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim9))
    @@ph9[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim9))
    @@ph9[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim9))
  end

  it "9th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim9 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim9 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim9
    else
      @@drugs_remaining_benefit_claim9 = 0.0
    end
    @@ph9[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim9))

    if @@actual_lab_benefit_claim9 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim9 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim9
    else
      @@lab_remaining_benefit_claim9 = 0
    end
    @@ph9[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim9))
  end

  it "9th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph9[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph9[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph9[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "9th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph9[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph9[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph9[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "9th Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "9th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 11
  end

  it "9th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "9th Availment : Discharges the patient in PBA" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "9th Availment : Prints Gate Pass of the patient" do
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "10th Availment : Adjusts PH Date Time" do
    # visit_no9 since 1-8 are already adjusted
#    slmc.adjust_ph_date(:days_to_adjust => 295, :visit_no => @@visit_no9)
      slmc.adjust_ph_date(:days_to_adjust => 366, :visit_no => @@visit_no9) # since 10th availment is different year from 9th availment
  end

#10th Availment
#Intensive Case
#CHOLERA (A00)
#1 day

 it "10th Availment : Intensive Case - Admit and Order items" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs10.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary10.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "10th Availment : Orders Procedures" do
    sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "USE OF PCA PUMP PACKAGE 1")
    slmc.add_returned_service(:item_code => @@item_code, :description => "USE OF PCA PUMP PACKAGE 1")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "10th Availment : Clinical Discharge Patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no10 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true).should be_true
    sleep 10
  end

  it "10th Availment : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days10, :pin => @@pin, :visit_no => @@visit_no10)
    Database.connect
    @days10.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no10,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no10, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days10 - i)
    end
    Database.logoff
  end

  it "10th Availment : Go to PhilHealth page and computes PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph10 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph10[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
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
    @@ph10[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
  end

  it "10th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph10[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
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
    @@ph10[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
  end

  it "10th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph10[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "10th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
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

  it "10th Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days10
    @@ph10[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "10th Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim10 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB01")
    @@actual_room_benefit_claim10 = @@room_benefit_claim10[:daily_amt].to_i * @days10
    @@ph10[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim10))
  end

  it "10th Availment : Checks if the deduction for room and board is correct" do
    @@ph10[:room_and_board_deduction].should == (@days10).to_s
  end

  it "10th Availment : Checks if the remaining benefits for room and board is correct" do # this varies whether it 90days is the previous year or only current year
    @@room_remaining10 = (@room_days - @days10)
    @@ph10[:room_and_board_remaining].should == (@@room_remaining10).to_s
  end

  it "10th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph10[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "10th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim10 + @@actual_lab_benefit_claim10 + @@actual_operation_benefit_claim10 + @@actual_room_benefit_claim10
    ((slmc.truncate_to((@@ph10[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "10th Availment : Checks if the maximum benefits are correct" do
    @@ph10[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph10[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph10[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "10th Availment : Checks if Deduction Claims are correct" do
    @@ph10[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
    @@ph10[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
    @@ph10[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
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
      @@lab_remaining_benefit_claim10 = 0
    end
    @@ph10[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim10))
  end

  it "10th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph10[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph10[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph10[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "10th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph10[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph10[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph10[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "10th Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "10th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 4
  end

  it "10th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "10th Availment : Discharges the patient in PBA" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "10th Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

 it "11th Availment : Intensive Case - Admit and Order items" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs11.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary11.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 7
    slmc.confirm_validation_all_items.should be_true
  end

  it "11th Availment : Orders Procedures" do
    sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "USE OF PCA PUMP PACKAGE 1")
    slmc.add_returned_service(:item_code => @@item_code, :description => "USE OF PCA PUMP PACKAGE 1")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "11th Availment : Clinical Discharge Patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no11 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true)
    sleep 10
  end

  it "11th Availment : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days11, :pin => @@pin, :visit_no => @@visit_no11)
    Database.connect
    @days11.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no11,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no11, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days11 - i)
    end
    Database.logoff
  end

  it "11th Availment : Go to PhilHealth page and computes PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph11 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA, UNSPECIFIED", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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

    @@orders = @drugs11.merge(@ancillary11).merge(@operation11)
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

  it "11th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph11[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "11th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f < 0
     @@actual_medicine_benefit_claim11 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim11  = @@actual_comp_drugs
    else
     @@actual_medicine_benefit_claim11 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph11[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim11))
  end

  it "11th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph11[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "11th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f < 0
      @@actual_lab_benefit_claim11 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim11 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim11 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph11[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim11))
  end

  it "11th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph11[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "11th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim11 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim11 = @@operation_ph_benefit[:max_amt].to_f
      end
    else
      @@actual_operation_benefit_claim11 = 0.00
    end
    @@ph11[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim11))
  end

  it "11th Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days11
    @@ph11[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "11th Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim11 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB01")
    @@actual_room_benefit_claim11 = @@room_benefit_claim11[:daily_amt].to_i * @days11
    @@ph11[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim11))
  end

  it "11th Availment : Checks if the deduction for room and board is correct" do
    @@ph11[:room_and_board_deduction].should == (@days11).to_s
  end

  it "11th Availment : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining11 = (@@room_remaining10 - @days11)
    @@ph11[:room_and_board_remaining].should == (@@room_remaining11).to_s
  end

  it "11th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph11[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "11th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim11 + @@actual_lab_benefit_claim11 + @@actual_operation_benefit_claim11 + @@actual_room_benefit_claim11
    ((slmc.truncate_to((@@ph11[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "11th Availment : Checks if the maximum benefits are correct" do
    @@ph11[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph11[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph11[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "11th Availment : Checks if Deduction Claims are correct" do
    @@ph11[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim11))
    @@ph11[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim11))
    @@ph11[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim11))
  end

  it "11th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim11 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim11 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim11
    else
      @@drugs_remaining_benefit_claim11 = 0.0
    end
    @@ph11[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim11))

    if @@actual_lab_benefit_claim11 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim11 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim11
    else
      @@lab_remaining_benefit_claim11 = 0
    end
    @@ph11[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim11))
  end

  it "11th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph11[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph11[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph11[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "11th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph11[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph11[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph11[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "11th Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "11th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 8
  end

  it "11th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "11th Availment : Discharges the patient in PBA" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "11th Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

 it "12th Availment : Intensive Case - Admit and Order items" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs12.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary12.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 5).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 7
    slmc.confirm_validation_all_items.should be_true
  end

  it "12th Availment : Orders Procedures" do
    sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "USE OF PCA PUMP PACKAGE 1")
    slmc.add_returned_service(:item_code => @@item_code, :description => "USE OF PCA PUMP PACKAGE 1")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "12th Availment : Clinical Discharge Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no12 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :type => "standard", :save => true)
    sleep 10
  end

  it "12th Availment : Database Manipulation - Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days12, :pin => @@pin, :visit_no => @@visit_no12)
    Database.connect
    @days12.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no12,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no12, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days12 - i)
    end
    Database.logoff
  end

  it "12th Availment : Go to PhilHealth page and computes PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph12 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
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

    @@orders = @drugs12.merge(@ancillary12).merge(@operation12)
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

  it "12th Availment : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@promo_discount * total_drugs)
    @@ph12[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "12th Availment : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
    if @@med_ph_benefit[:max_amt].to_f < 0
     @@actual_medicine_benefit_claim12 = 0.00
    elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10)
      @@actual_medicine_benefit_claim12  = @@actual_comp_drugs
    else
     @@actual_medicine_benefit_claim12 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim10)
    end
    @@ph12[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim12))
  end

  it "12th Availment : Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph12[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "12th Availment : Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    if @@lab_ph_benefit[:max_amt].to_f < 0
      @@actual_lab_benefit_claim12 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim10)
      @@actual_lab_benefit_claim12 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim12 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim10)
    end
    @@ph12[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim12))
  end

  it "12th Availment : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph12[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "12th Availment : Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
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

  it "12th Availment : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days12
    @@ph12[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "12th Availment : Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim12 = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB01")
    @@actual_room_benefit_claim12 = @@room_benefit_claim12[:daily_amt].to_i * @days12
    @@ph12[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim12))
  end

  it "12th Availment : Checks if the deduction for room and board is correct" do
    @@ph12[:room_and_board_deduction].should == (@days12).to_s
  end

  it "12th Availment : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining12 = (@@room_remaining11 - @days12)
    @@ph12[:room_and_board_remaining].should == (@@room_remaining12).to_s
  end

  it "12th Availment : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph12[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "12th Availment : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim12 + @@actual_lab_benefit_claim12 + @@actual_operation_benefit_claim12 + @@actual_room_benefit_claim12
    ((slmc.truncate_to((@@ph12[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "12th Availment : Checks if the maximum benefits are correct" do
    @@ph12[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph12[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph12[:er_max_benefit_operation].should == ("%0.2f" %(@@operation_ph_benefit[:max_amt]))
  end

  it "12th Availment : Checks if Deduction Claims are correct" do
    @@ph12[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim12))
    @@ph12[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim12))
    @@ph12[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim12))
  end

  it "12th Availment : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim12 < @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim10
      @@drugs_remaining_benefit_claim12 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim12 - @@actual_medicine_benefit_claim10
    else
      @@drugs_remaining_benefit_claim12 = 0.0
    end
    @@ph12[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim12))

    if @@actual_lab_benefit_claim12 < @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim10
      @@lab_remaining_benefit_claim12 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim12 - @@actual_lab_benefit_claim10
    else
      @@lab_remaining_benefit_claim12 = 0
    end
    @@ph12[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim12))
  end

  it "12th Availment : Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@ph12[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@ph12[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@ph12[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
  end

  it "12th Availment : Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@ph12[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@ph12[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@ph12[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
  end

  it "12th Availment : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "12th Availment : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 8
  end

  it "12th Availment : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "12th Availment : Discharges the patient in PBA" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "12th Availment : Prints Gate Pass of the patient" do
    sleep 6
    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

end