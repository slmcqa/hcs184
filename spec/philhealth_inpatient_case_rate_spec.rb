require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
#require "win32/sound"

describe "SLMC :: PhilHealth Case Rates for Inpatient" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @user = "billing_spec_user2"
    @pba_user = "ldcastro"
    @oss_user = "jtsalang"
    @password = "123qweuser"


    @patient1 = Admission.generate_data
    @patient2 = Admission.generate_data
    @oss_patient = Admission.generate_data
    @oss_patient2 = Admission.generate_data
    @promo_discount1 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient1[:age])
    @promo_discount2 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient2[:age])
    @promo_discount3 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@oss_patient[:age])
    @promo_discount4 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@oss_patient2[:age])
    @room_rate = 4167.0
    @room_discount1 = @room_rate - (@room_rate * @promo_discount1)
    @room_discount2 = @room_rate - (@room_rate * @promo_discount2)
    @room_days = 45
    @days2 = 2

    @drugs1 =  {"040821106" => 1}
    @ancillary1 = {"010000317" => 1}
    @supplies1 = {"085100003" => 1}

    @doctors = ["6726","0126","6726","0126"]
    @oss_drugs = {"042422511" => 1}
    @oss_ancillary = {"010000004" => 1}
    @oss_operation = {"010000160" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

# For more info on Case Rate, see bottom page
# PH Case Rate Computation – Medical Case: 30% PF coveraged will be deducted from total case rate
  it "Scenario 1 - Medical Case 30% : Create, Admit and Order items" do
    slmc.login(@user, @password)
    slmc.admission_search(:pin => "Test")
    @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
    slmc.admission_search(:pin => @@pin1).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."

    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin1)
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
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "Scenario 1 - Medical Case 30% : Clinical Discharge patient" do
    slmc.go_to_general_units_page
    slmc.nursing_gu_search(:pin => @@pin1)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@pin1, :diagnosis => "A91.0", :no_pending_order => true, :pf_amount => "3000", :save => true).should be_true
    puts @@pin1
  end

  it "Scenario 1 - Medical Case 30% : Database Manipulation - Add and Edit records of patient" do
    @discount_type_code = "C01" if @promo_discount1== 0.16
    @discount_type_code = "C02" if @promo_discount1 == 0.20
    @discount_amount = (@room_rate * @promo_discount1)
    puts" @discount_amount - #{@discount_amount}"
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days2, :pin => @@pin1, :visit_no => @@visit_no1)
    Database.connect
    @days2.times do |i|
      sleep 1
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no1,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no1, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days2 - i)
    end
    Database.logoff
  end

  it "Scenario 1 - Medical Case 30% : Compute and Save PhilHealth" do
    slmc.login(@pba_user, @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
 #   @@ph1 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "A91.0", :case_rate_type => "MEDICAL", :case_rate => "DENGUE I (DENGUE FEVER AND DHF GRADES#{} I & II)", :compute => true)
   @@mycase_rate = "DENGUE WITH WARNING SIGNS"
    @@ph1 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "A91.0", :case_rate_type => "MEDICAL", :case_rate => @@mycase_rate, :group_name => "DENGUE FEVER", :compute => true)
    slmc.ph_save_computation.should be_true
  end

  it "Scenario 1 - Medical Case 30% : Check Benefit Summary totals" do
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

    @@orders = @drugs1.merge(@ancillary1).merge(@supplies1)
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

  it "Scenario 1 - Medical Case 30% : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@promo_discount1 * total_drugs)
    @@ph1[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Scenario 1 - Medical Case 30% : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_medicine_benefit_claim1 = 0.0
    @@ph1[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
  end

  it "Scenario 1 - Medical Case 30% : Checks if the actual charge for xrays, lab and others is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @promo_discount1)
    @@ph1[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Scenario 1 - Medical Case 30% : Checks if the actual lab benefit claim is correct" do
    @@actual_lab_benefit_claim1 = 0.0
    @@ph1[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
  end

  it "Scenario 1 - Medical Case 30% : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = 0.0
    @@ph1[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Scenario 1 - Medical Case 30% : Checks if the actual operation benefit claim is correct" do
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

  it "Scenario 1 - Medical Case 30% : Checks if the actual charge for room and board is correct" do
#    nowmyti = Time.now
#    if nowmyti <= 11
#
#    end
    @@actual_room_charges = @room_discount1 * 2.5
    @@ph1[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "Scenario 1 - Medical Case 30% : Checks if the actual room benefit claim is correct" do
    @@actual_room_benefit_claim1 = 0.0
    @@ph1[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim1))
  end

  it "Scenario 1 - Medical Case 30% : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph1[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "Scenario 1 - Medical Case 30% : Checks if the total actual benefit claim is correct" do
        #63710	Philhealth:PF of Case Rate will be computed by Amount
           Database.connect
             t = "SELECT PF_AMOUNT FROM REF_PBA_PH_CASE_RATE WHERE DESCRIPTION ='#{@@mycase_rate}'"
             pf = Database.select_all_statement t
            Database.logoff
            puts pf
        pf = pf.to_i
    @@total_actual_benefit_claim = (10000 - pf )#REF_PBA_PH_CASE_RATE.CASE_RATE_NO = '5381'
    mm = @@ph1[:total_actual_benefit_claim].to_i
    puts mm
    ((slmc.truncate_to((@@ph1[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "Scenario 1 - Medical Case 30% : Checks if the maximum benefits are correct" do
    @@ph1[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph1[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Scenario 1 - Medical Case 30% : Checks if Deduction Claims are correct" do
    @@ph1[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
    @@ph1[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@ph1[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
  end

  it "Scenario 1 - Medical Case 30% : Checks if Remaining Benefit Claims are correct" do
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


  it "Scenario 1 - Medical Case 30% : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "Scenario 1 - Medical Case 30% : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 3
  end

  it "Scenario 1 - Medical Case 30% : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "63710	Philhealth:PF of Case Rate will be computed by Amount" do
 #PH Case Rate Computation – Medical Case: 40% PF coveraged will be deducted from total case rate
       Database.connect
             t = "SELECT PF_AMOUNT FROM REF_PBA_PH_CASE_RATE WHERE DESCRIPTION ='#{@@mycase_rate}'"
             mycase_rate = Database.select_all_statement t
        Database.logoff
        puts "mycase_rate = #{mycase_rate}"
        puts  "@@ph1[:surgeon_benefit_claim] = #{@@ph1[:surgeon_benefit_claim]}"
        puts "@@ph1[:inpatient_surgeon_benefit_claim] = #{@@ph1[:inpatient_surgeon_benefit_claim]}"
        puts "@@ph1[:inpatient_anesthesiologist_benefit_claim ] = #{@@ph1[:inpatient_anesthesiologist_benefit_claim ]}"
        puts "@@ph1[:inpatient_physician_benefit_claim ] = #{@@ph1[:inpatient_physician_benefit_claim ]}"
     #   sound.play(SystemAsterisk", Sound::ALIAS) # play system asterisk sound
       # Sound.beep(600,3000) # play a beep 600 hertz for 200 milliseconds
  end

  it "Scenario 2 - Medical Case 40% : Create, Admit and Order items" do
    slmc.login(@user, @password)
    slmc.admission_search(:pin => "Test")
    @@pin2 = slmc.create_new_patient(@patient2).gsub(' ', '')
    #    slmc.login(@user, @password)
    slmc.admission_search(:pin => @@pin2).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."

    slmc.nursing_gu_search(:pin => @@pin2)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin2)
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
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "Scenario 2 - Medical Case 40% : Clinical Discharge patient" do
    slmc.nursing_gu_search(:pin => @@pin2)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@pin2, :diagnosis => "K91.5", :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
  end

  it "Scenario 2 - Medical Case 40% : Database Manipulation - Add and Edit records of patient" do
    @discount_type_code = "C01" if @promo_discount2 == 0.16
    @discount_type_code = "C02" if @promo_discount2 == 0.2
    @discount_amount = (@room_rate * @promo_discount2)
    puts" @discount_amount - #{@discount_amount}"
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days2, :pin => @@pin2, :visit_no => @@visit_no2)
    Database.connect
    @days2.times do |i|
      sleep 1
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no2,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no2, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days2 - i)
    end
    Database.logoff
  end

  it "Scenario 2 - Medical Case 40% : Compute and Save PhilHealth" do
    slmc.login(@pba_user, @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
   # @@ph2 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "K80.0", :case_rate_type => "SURGICAL", :case_rate => "CHOLECYSTECTOMY", :rvu_code => "47600", :compute => true)
    @@ph2 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "K80.0", :case_rate_type => "SURGICAL", :case_rate => "47600", :rvu_code => "47600", :compute => true)
    slmc.ph_save_computation.should be_true
  end

  it "Scenario 2 - Medical Case 40% : Check Benefit Summary totals" do
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

    @@orders = @drugs1.merge(@ancillary1).merge(@supplies1)
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

  it "Scenario 2 - Medical Case 40% : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@promo_discount2 * total_drugs)
    @@ph2[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Scenario 2 - Medical Case 40% : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_medicine_benefit_claim2 = 0.0
    @@ph2[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
  end

  it "Scenario 2 - Medical Case 40% : Checks if the actual charge for xrays, lab and others is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @promo_discount2)
    @@ph2[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Scenario 2 - Medical Case 40% : Checks if the actual lab benefit claim is correct" do
    @@actual_lab_benefit_claim2 = 0.0
    @@ph2[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
  end

  it "Scenario 2 - Medical Case 40% : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = 0.0
    @@ph2[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Scenario 2 - Medical Case 40% : Checks if the actual operation benefit claim is correct" do
    @@actual_operation_benefit_claim2 = 0.00
    @@ph2[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "Scenario 2 - Medical Case 40% : Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount2 * @days2
    @@ph2[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "Scenario 2 - Medical Case 40% : Checks if the actual room benefit claim is correct" do
    @@actual_room_benefit_claim2 = 0.0
    @@ph2[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim2))
  end

  it "Scenario 2 - Medical Case 40% : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph2[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "Scenario 2 - Medical Case 40% : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = 31000 - (31000 * 0.40) # 31000 fixed for cholecystectomy
    ((slmc.truncate_to((@@ph2[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "Scenario 2 - Medical Case 40% : Checks if the maximum benefits are correct" do
    @@ph2[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph2[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Scenario 2 - Medical Case 40% : Checks if Deduction Claims are correct" do
    @@ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
    @@ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    @@ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "Scenario 2 - Medical Case 40% : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim2 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim2
    else
      @@drugs_remaining_benefit_claim2 = 0.0
    end
    @@ph2[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim2))

    if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim2
    else
      @@lab_remaining_benefit_claim2 = 0
    end
    @@ph2[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim2))
  end

  it "Scenario 2 - Medical Case 40% : Checks if the deduction for room and board is correct" do
    @@ph2[:room_and_board_deduction].should == (@days2).to_s
  end

  it "Scenario 2 - Medical Case 40% : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining2 = (@room_days - @days2)
    @@ph2[:room_and_board_remaining].should == (@@room_remaining2).to_s
  end

  it "Scenario 2 - Medical Case 40% : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "Scenario 2 - Medical Case 40% : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 3
  end

  it "Scenario 2 - Medical Case 40% : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "Scenario 2 - Medical Case 40% : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "Scenario 2 - Medical Case 40% : Prints Gate Pass of the patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin2)
    slmc.print_gatepass(:no_result => true, :pin => @@pin2).should be_true
  end

  it "Scenario 2 - Medical Case 40% : Adjusts PH Date Time" do
    slmc.adjust_ph_date(:days_to_adjust => 8, :visit_no => @@visit_no2).should be_true
  end

# 45 days rule still applicable

  it "Scenario 3 - 45 days rule still applicable : Create, Admit and Order items" do
    slmc.login(@user, @password)
    slmc.admission_search(:pin => @@pin2).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."

    slmc.nursing_gu_search(:pin => @@pin2)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin2)
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
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "Scenario 3 - 45 days rule still applicable : Clinical Discharge patient" do
    slmc.nursing_gu_search(:pin => @@pin2)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no3 = slmc.clinically_discharge_patient(:pin => @@pin2, :diagnosis => "K91.5", :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
  end

  it "Scenario 3 - 45 days rule still applicable : Database Manipulation - Add and Edit records of patient" do
     puts" Scenario 3 - @discount_amount - #{@discount_amount}"
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days2, :pin => @@pin2, :visit_no => @@visit_no3)
    Database.connect
    @days2.times do |i|
      sleep 1
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no3,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no3, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days2 - i)
    end
    Database.logoff
  end

  # changed from Cholecystectomy to APPENDECTOMY due to change in condition within 90days
  it "Scenario 3 - 45 days rule still applicable : Compute and Save PhilHealth" do
    slmc.login(@pba_user, @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
   # message = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "K81", :case_rate_type => "SURGICAL", :case_rate => "CHOLECYSTECTOMY", :compute => true)
   message = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "K81", :case_rate_type => "SURGICAL", :case_rate =>"47560", :compute => true)
    d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
    prev_day = ((((d - 1)).strftime("%a").upcase).to_s).capitalize
    prev_date = ((((d - 8)).strftime("%b %d %Y").upcase).to_s).capitalize # 8days changed. see line # 500
#    message.should == "The patient has filed case rate CHOLECYSTECTOMY last #{prev_day} #{prev_date}.  Can not apply for Philhealth with same Case Rate within 90 days."
    message.should == "The patient has filed case rate Cholecystectomy last #{prev_day} #{prev_date}.  Can not apply for Philhealth with same Case Rate within 90 days."

  # @@ph3 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "K81", :case_rate_type => "SURGICAL", :case_rate => "APPENDECTOMY", :rvu_code => "47600", :compute => true)
    @@ph3 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "K81", :case_rate_type => "SURGICAL", :case_rate => "44950", :rvu_code => "44950", :compute => true)
    @@ph_ref_no3 = slmc.ph_save_computation.should be_true
  end

  it "Scenario 3 - 45 days rule still applicable : Check Benefit Summary totals" do
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

    @@orders = @drugs1.merge(@ancillary1).merge(@supplies1)
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

  it "Scenario 3 - 45 days rule still applicable : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@promo_discount2 * total_drugs)
    @@ph3[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_medicine_benefit_claim3 = 0.0
    @@ph3[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the actual charge for xrays, lab and others is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @promo_discount2)
    @@ph3[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the actual lab benefit claim is correct" do
    @@actual_lab_benefit_claim3 = 0.0
    @@ph3[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = 0.0
    @@ph3[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the actual operation benefit claim is correct" do
    @@actual_operation_benefit_claim3 = 0.00
    @@ph3[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the actual charge for room and board is correct" do
#    @@actual_room_charges = @room_discount2 * (@days2 + 0.5)
      @@actual_room_charges = @room_discount2 * (@days2 + 0.5)

    @@ph3[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the actual room benefit claim is correct" do
    @@actual_room_benefit_claim3 = 0.0
    @@ph3[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim3))
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@actual_room_charges
    ((slmc.truncate_to((@@ph3[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = 24000 - (24000 * 0.40) # Only the first availment should be honored as valid claimed (90 days rule in effect)
    ((slmc.truncate_to((@@ph3[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the maximum benefits are correct" do
    @@ph3[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph3[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if Deduction Claims are correct" do
    @@ph3[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
    @@ph3[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
    @@ph3[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if Remaining Benefit Claims are correct" do
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

  it "Scenario 3 - 45 days rule still applicable : Checks if the deduction for room and board is correct" do
    @@ph3[:room_and_board_deduction].should == (@days2).to_s
  end

  it "Scenario 3 - 45 days rule still applicable : Checks if the remaining benefits for room and board is correct" do
    @@room_remaining2 = (@room_days - @days2+2)
    @@ph3[:room_and_board_remaining].should == (@@room_remaining2).to_s
  end

  it "Scenario 3 - 45 days rule still applicable : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
  end

  it "Scenario 3 - 45 days rule still applicable : View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 3
  end

  it "Scenario 3 - 45 days rule still applicable : Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end

  it "Scenario 3 - 45 days rule still applicable : Discharges the patient in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end

  it "Back-end Checking : Saving – TXN_PBA_PH_HDR" do
    # back-end checking
  #  (slmc.access_from_database(:what => "RATE", :table => "REF_PBA_PH_CASE_RATE", :column1 => "DESCRIPTION", :condition1 => "APPENDECTOMY").to_i).should == 24000
    (slmc.access_from_database(:what => "RATE", :table => "REF_PBA_PH_CASE_RATE", :column1 => "DESCRIPTION", :condition1 => "Appendectomy").to_i).should == 24000
   # (slmc.access_from_database(:what => "PF", :table => "REF_PBA_PH_CASE_RATE", :column1 => "DESCRIPTION", :condition1 => "APPENDECTOMY").to_i).should == 40
    (slmc.access_from_database(:what => "PF", :table => "REF_PBA_PH_CASE_RATE", :column1 => "DESCRIPTION", :condition1 => "Appendectomy").to_i).should == 40

    (slmc.access_from_database(:what => "TOT_ACT_BNFT_CLAIM", :table => "TXN_PBA_PH_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no3).to_i).should == 14400
    (slmc.access_from_database(:what => "ICD10_CODE", :table => "TXN_PBA_PH_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no3).to_s).should == "K81"
  end

  it "Back-end Checking : Saving – TXN_PBA_PH_DTL" do
    (slmc.access_from_database(:table => "TXN_PBA_PH_DTL", :column1 => "PH_REF_NO", :condition1 => @@ph_ref_no3).to_i).should == 3
  end

  it "Back-end Checking : Saving – TXN_PBA_PH_MEMBER_INFO" do
    @@member_data = slmc.access_from_database(:all_info => true, :what => "*", :table => "TXN_PBA_PH_MEMBER_INFO",
            :column1 => "LASTNAME", :condition1 => @patient2[:last_name],
            :column2 => "FIRSTNAME", :condition2 => @patient2[:first_name],
            :column3 => "MIDDLENAME", :condition3 => @patient2[:middle_name],
            :gate => "AND", :gate2 => "AND").should be_true

    @@member_data["LASTNAME"].should == (@patient2[:last_name])
    @@member_data["FIRSTNAME"].should == (@patient2[:first_name])
    @@member_data["MIDDLENAME"].should == (@patient2[:middle_name])
    @@member_data["BIRTHDATE"].should == (@patient2[:birth_day])
    @@member_data["PH_MEMBER_ID"].should == ("7654327")
    @@member_data["CREATED_DATETIME"].should == (Time.now.strftime("%m/%d/%Y"))
    @@member_data["EMP_ADDR_CITY"].should == ("PASIG CITY")
    @@member_data["CREATED_BY"].should == (@pba_user)
    @@member_data["ADDR_NUMSTREET"].should == ("Selenium Testing Address")
    @@member_data["EMPLOYER"].should == ("Exist")
  end

  it "Back-end Checking : Saving – TXN_PBA_PH_RB" do
    @@rb_data = slmc.access_from_database(:all_info => true, :what => "*", :table => "TXN_PBA_PH_RB",
            :column1 => "VISIT_NO", :condition1 => @@visit_no3,
            :gate => "AND",
            :column2 => "PH_REF_NO", :condition2 => @@ph_ref_no3).should be_true

    #@@rb_data["CREATED_DATETIME"].should == (Time.now.strftime("%m/%d/%Y"))
    rb_data_createddatetime = @@rb_data["CREATED_DATETIME"]
    (rb_data_createddatetime.strftime("%m/%d/%Y")).should ==  (Time.now.strftime("%m/%d/%Y"))
    #@@rb_data["PH_ID"].should == (@@member_data["PH_ID"]) # commenting out, two records appear, will get only first record in DB
    @@rb_data["CREATED_BY"].should == (@pba_user)
    @@rb_data["NO_OF_DAYS_AVAILED"].should == (2)
  end

  it "Back-end Checking : Saving – TXN_PBA_PH_HISTORY" do
    @@ph_history = slmc.access_from_database(:all_info => true, :what => "*", :table => "TXN_PBA_PH_HISTORY",
            :column1 => "VISIT_NO", :condition1 => @@visit_no3).should be_true

    #@@ph_history["PH_ID"].should == (@@member_data["PH_ID"])
    @@ph_history["PH_REF_NO"].should == (@@ph_ref_no3)
    @@ph_history["FINAL_DIAGNOSIS"].should == ("K81")
    @@ph_history["TOTAL_DAYS_AVAILED_RB"].should == (2)
  end

  it "Radio Theraphy and Hemodialysis is not applicable for inpatient" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    slmc.ph_edit
    slmc.select("phCaseRateType", "SURGICAL")
    sleep 5
    case_rate = slmc.get_select_options("caseRateNo")
    case_rate.include?("Radio Therapy").should be_false
    case_rate.include?("Hemodialysis").should be_false

    slmc.select("phCaseRateType", "MEDICAL")
    sleep 5
    case_rate = slmc.get_select_options("caseRateNo")
    case_rate.include?("Radiotherapy").should be_false
    case_rate.include?("Hemodialysis").should be_false
  end

  it "Scenario 4 - Outpatient Case Rate(Radiotherapy) - Create and Order" do
    slmc.login(@oss_user, @password)
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = (slmc.oss_outpatient_registration(@oss_patient)).gsub(' ','').should be_true

    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true

    @@orders = @oss_ancillary.merge(@oss_operation).merge(@oss_drugs)
    n = 0
    @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n += 1
    end
  end

  it "Scenario 4 - Add guarantor and enable philhealth patient information" do
    slmc.oss_add_guarantor(:guarantor_type => 'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
   # @@oss_ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345",
   #  :rvu_code => "77401", :surgeon_type => "GENERAL PRACTITIONER", :anesthesiologist_type => "GENERAL PRACTITIONER",
    #  :case_rate_type => "SURGICAL", :case_rate => "RADIOTHERAPY", :compute => true)
        @@oss_ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345",
      :rvu_code => "77401", :surgeon_type => "GENERAL PRACTITIONER", :anesthesiologist_type => "GENERAL PRACTITIONER",
      :case_rate_type => "SURGICAL", :case_rate => "77401", :case_rate_name => "RADIATION TREATMENT DELIVERY (LINEAR ACCELERATOR)", :compute => true)
  end

  it "Scenario 4 - Check Benefit Summary totals" do
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

    @@orders = @oss_drugs.merge(@oss_ancillary).merge(@oss_operation)
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

  it "Scenario 4 : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@promo_discount3 * total_drugs)
    @@oss_ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Scenario 4 : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_medicine_benefit_claim4 = 0.0
    @@oss_ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
  end

  it "Scenario 4 : Checks if the actual charge for xrays, lab and others is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @promo_discount3)
    @@oss_ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Scenario 4 : Checks if the actual lab benefit claim is correct" do
    @@actual_lab_benefit_claim4 = 0.0
    @@oss_ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
  end

  it "Scenario 4 : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @promo_discount3) + (@@non_comp_operation - (@@non_comp_operation * @promo_discount3))
    @@oss_ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Scenario 4 : Checks if the actual operation benefit claim is correct" do
    @@actual_operation_benefit_claim4 = 0.0
    @@oss_ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "Scenario 4 : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@oss_ph[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "Scenario 4 : Checks if the total actual benefit claim is correct" do
#    @@total_actual_benefit_claim = 3000 - (3000 * 0.40) # 3000 for radiotherapy
    @@total_actual_benefit_claim = 3000 - 800 # CASE RATE LESS PF AMOUNT

    ((slmc.truncate_to((@@oss_ph[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "Scenario 4 : Checks if the maximum benefits are correct" do
    @@oss_ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@oss_ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Scenario 4 : Checks if Deduction Claims are correct" do
    @@oss_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    @@oss_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    @@oss_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "Scenario 4 : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f
    else
      @@drugs_remaining_benefit_claim4 = 0.0
    end
    @@oss_ph[:drugs_remaining_benefit_claims].to_f.should == (@@drugs_remaining_benefit_claim4)

    if @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f
    else
      @@lab_remaining_benefit_claim4 = 0
    end
    @@oss_ph[:lab_remaining_benefit_claims].to_f.should == (@@lab_remaining_benefit_claim4)
  end

  it "Scenario 4 : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "Scenario 4 : Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','')
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "Scenario 5 - Outpatient Case Rate(Radiotherapy) - Create and Order" do
    slmc.login(@oss_user, @password)
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin2 = (slmc.oss_outpatient_registration(@oss_patient2)).gsub(' ','').should be_true

    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin2)
    slmc.click_outpatient_order.should be_true

    @@orders = @oss_ancillary.merge(@oss_operation).merge(@oss_drugs)
    n = 0
    @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n += 1
    end
  end

  it "Scenario 5 - Add guarantor and enable philhealth patient information" do
    slmc.oss_add_guarantor(:guarantor_type => 'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
#    @@oss_ph2 = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345",
#      :rvu_code => "90935", :surgeon_type => "GENERAL PRACTITIONER", :anesthesiologist_type => "GENERAL PRACTITIONER",
#      :case_rate_type => "SURGICAL", :case_rate => "HEMODIALYSIS", :compute => true)

        @@oss_ph2 = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345",
      :rvu_code => "90935", :surgeon_type => "GENERAL PRACTITIONER", :anesthesiologist_type => "GENERAL PRACTITIONER",
      :case_rate_type => "SURGICAL", :case_rate => "90935", :case_rate_name => "90935",:compute => true)
  end

  it "Case rate type list should include only Surgical" do
    slmc.get_select_options("philHealthBean.phCaseRateType").should == ["Not Applicable", "SURGICAL"]
  end

  it "Case rate list should include only Radiotherapy and Hemodialysis" do
    #slmc.get_select_options("philHealthBean.caseRateNo").should == ["RADIOTHERAPY", "HEMODIALYSIS"]
    slmc.get_select_options("philHealthBean.caseRateNo").should == ["Radiotherapy", "Hemodialysis", "Dilatation and Curettage", "Cataract Surgery"]
  end

  it "Scenario 5 - Check Benefit Summary totals" do
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

    @@orders = @oss_drugs.merge(@oss_ancillary).merge(@oss_operation)
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

  it "Scenario 5 : Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@promo_discount4 * total_drugs)
    @@oss_ph2[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Scenario 5 : Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_medicine_benefit_claim5 = 0.0
    @@oss_ph2[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
  end

  it "Scenario 5 : Checks if the actual charge for xrays, lab and others is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @promo_discount4)
    @@oss_ph2[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Scenario 5 : Checks if the actual lab benefit claim is correct" do
    @@actual_lab_benefit_claim5 = 0.0
    @@oss_ph2[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
  end

  it "Scenario 5 : Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @promo_discount4) + (@@non_comp_operation - (@@non_comp_operation * @promo_discount4))
    @@oss_ph2[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Scenario 5 : Checks if the actual operation benefit claim is correct" do
    @@actual_operation_benefit_claim5 = 0.0
    @@oss_ph2[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
  end

  it "Scenario 5 : Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    ((slmc.truncate_to((@@oss_ph2[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.01
  end

  it "Scenario 5 : Checks if the total actual benefit claim is correct" do
#    @@total_actual_benefit_claim = 4000 # 4000 for hemodialysis fix(will be change in next iter)
    @@total_actual_benefit_claim = 4000 - 500  #CASE RATE LESS PF_AMOUNT

    ((slmc.truncate_to((@@oss_ph2[:total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
  end

  it "Scenario 5 : Checks if the maximum benefits are correct" do
    @@oss_ph2[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@oss_ph2[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Scenario 5 : Checks if Deduction Claims are correct" do
    @@oss_ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
    @@oss_ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
    @@oss_ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
  end

  it "Scenario 5 : Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim5 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f
    else
      @@drugs_remaining_benefit_claim5 = 0.0
    end
    @@oss_ph2[:drugs_remaining_benefit_claims].to_f.should == (@@drugs_remaining_benefit_claim5)

    if @@actual_lab_benefit_claim5 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f
    else
      @@lab_remaining_benefit_claim5 = 0
    end
    @@oss_ph2[:lab_remaining_benefit_claims].to_f.should == (@@lab_remaining_benefit_claim5)
  end

  it "Scenario 5 : Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "Scenario 5 : Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','')
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

#PH Case Rate applicable for both Inpatient / Outpatient except for the following conditions below:
#Outpatient – SPU ER/OR/DR: is not applicable for Case Rate
#Outpatient – Honored in Case rate  (Radiotherapy – Linear Accelerator Family) RVU = 77401 and Hemodialysis RVU = 90935
#
#Inpatient – All case rate are applied except those for Outpatient mentioned above
#
#Types of Case Rate – Medical and Surgical

#Approved Case Rate as of PH circular no.11 – 11-B-2011
#
#NO. Case                                                                   Rate      %PF      Case Type          ICD10 codes
#1	Dengue I (Dengue Fever and DHF Grades I & II)	                          8000      30        MED	           A90, A91.0, A91.1, & A91.9
#2	Dengue II (DHF Grades III & IV)                                        16000      30        MED	           A91.2 AND A91.3
#3	Pneumonia I (Moderate Risk)                                            15000      30        MED	           J12.- TO J18.- (J18.91 - 92)
#4	Pneumonia II (High Risk)                                               32000      30        MED	           J12.- TO J18.- (I95.9, R06.4, I24.8)
#5	Essential Hypertension                                                  9000      30        MED	           I10.-, I11.9, I12.9, AND I13.9
#6	Cerebral Infarction (CVA I)                                            28000      30        MED	           I63.- AND I64.-
#7	Cerebro-vascular Accident (hemorrhage) (CVA II)                        38000      30        MED	           I60.-, I61.-, AND I62.-
#
#8	Acute Gastroenteritis (AGE)                                             6000      30        MED	           A09, A00.-,A03.0, A06.0,A07.1,K52.9,                                                                                                                                 AND P78.3
#
#9	Asthma                                                                  9000      30        MED	           J45.- AND J44.-
#10	Typhoid Fever                                                          14000      30        MED	           A01.-, A02.-, AND F05.9
#11	Newborn Care Package in Hospitals and Lying                             1750      30        MED
#in Clinics
#12	Radiotherapy                                                            3000	    40        SURG	         RVS = 77401
#13	Hemodialysis                                                            4000	     0        SURG	         RVS = 90935
#14	NSD Package in Level 1 Hospitals                                        8000      40        SURG
#15	NSD Package in Levels 2 to 4 Hospitals                                  6500	    40        SURG
#16	Caesarean Section                                                      19000      40        SURG	        RVS = 59513, 59514,AND 59620 (44005)
#17	APPENDECTOMY                                                           24000      40        SURG	        RVS = 44950,44960, 44970
#
#18	Cholecystectomy                                                        31000      40        SURG	        RVS = 47560,47561-47564, 47570
#                                                                                                                            47600, 47600, 47605, 47610,47612,47620
#
#19	Dilatation and Curettage                                               11000	    40        SURG	         RVS = 58100,58120,59812, 59814
#
#20	Thyroidectomy                                                          31000      40        SURG	       RVS =  60210,60212,60220,60225,
#                                                                                                                           60240,60252,60254,60260,60270,60271
#
#21	Herniorrhaphy                                                          21000	    40	      SURG	        RVS = 49495-49590, 49650 - 51
#22	Mastectomy	                                                           22000	    40        SURG	        RVS = 19140,19160,19162,19180,19182
#23	Hysterectomy                                                           30000	    40	      SURG	        RVS = 58150,58152,58180,58200,59525
#24	Cataract Surgery	                                                     16000	    40	      SURG


end