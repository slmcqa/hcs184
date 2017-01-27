require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Endoscopic Procedure Case" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"

    @inpatient_user = "gu_spec_user8"
    @or_user = "slaquino"
    @pba_user = "ldcastro"





    @@patient_promo_discount = 0.16
    @discount_type_code = "C01"
    @inpatient_room_rate = 4167.0
    @discount_amount = (@inpatient_room_rate * @@patient_promo_discount)
    @room_discount = @inpatient_room_rate - @discount_amount
    #@all_items ={"042090007" => 1, "049000028" => 1, "040950558" => 1, "010001900"=>1, "060000204" => 1, "060002045" => 1, "010000008" => 1, "010000160" => 1}
    @days1= 1
    @drugs =  {"042090007" => 1, "049000028" => 1, "040950558" => 1}
    @ancillary = {"010001900"=>1}
    @operation = {"060000204" => 1, "060002045" => 1}

     @oss_user = "sel_oss5"
     @oss_patient = Admission.generate_data(:not_senior => true)
     @oss_ancillary = {"010001900"=>1, "010000008" => 1}
     @oss_operation = {"010000160" => 1}

      @er_user = "sel_er5"
      @er_patient = Admission.generate_data(:not_senior => true)
      @er_room_rate = 0
      @discount_amount1 = (@er_room_rate * @@patient_promo_discount)
      @room_discount1 = @er_room_rate - @discount_amount1

      @dr_user = "sel_dr3"
      @dr_patient = Admission.generate_data(:not_senior => true)
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

    it"(1st endoscopic scenario) Inpatient, Claim Type: Accounts Receivable / Refund, Case Type: Ordinary Case" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@inpatient_pin = slmc.create_new_patient(Admission.generate_data(:not_senior => true)).gsub(' ', '')
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => @@inpatient_pin)#.should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@inpatient_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@inpatient_pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
          :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 3).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
    end
    it"(1st endoscopic scenario) Order procedure items" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@inpatient_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@inpatient_pin)
    @@inpatient_item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@inpatient_item_code, :description => "POWER BONE SHAVING")
    @@inpatient_item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@inpatient_item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items.should be_true
    puts "@@inpatient_pin - #{@@inpatient_pin}"
    end
    it"(1st endoscopic scenario) Clinically discharge patient" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.nursing_gu_search(:pin=> @@inpatient_pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@inpatient_visit_no = slmc.clinically_discharge_patient(:pin => @@inpatient_pin, :pf_amount => '1000', :no_pending_order => true, :save => true, :type => "standard")
    end
    it "(1st endoscopic scenario) Add and Edit records of patient" do
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days1, :pin => @@inpatient_pin, :visit_no => @@inpatient_visit_no)
    Database.connect
    @days1.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@inpatient_visit_no,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @inpatient_room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @inpatient_user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@inpatient_visit_no, :rb_trans_no => @rb, :created_by => @inpatient_user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days1 - i)
    end
    Database.logoff
    end
    it"(1st endoscopic scenario) Computes philhealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("PhilHealth", @@inpatient_visit_no)
    puts @@inpatient_pin
    puts @@inpatient_visit_no
    @@inpatient_ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "21325", :compute => true)

    end
    it"(1st endoscopic scenario) Check Benefit Summary totals" do
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@comp_operation = 0
    @@non_comp_operation = 0

    @@inpatient_orders =  @drugs.merge(@ancillary).merge(@operation)
    @@inpatient_orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      if item[:ph_code] == "PHS01"
        amt = item[:rate].to_f * n
        @@comp_drugs += amt  # total compensable drug
      end
      if item[:ph_code] == "PHS06"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
      end
      if item[:ph_code] == "PHS02"
        x_lab_amt = item[:rate].to_f * n
        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
      end
    end
    end
    it "(1st endoscopic scenario) Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@patient_promo_discount * total_drugs)
    @@inpatient_ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "(1st endoscopic scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@patient_promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
    end
    @@inpatient_ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    end
    it "(1st endoscopic scenario) Checks if the actual charge for xrays, lab and others is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@patient_promo_discount)
    @@inpatient_ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(1st endoscopic scenario) Checks if the actual lab benefit claim is correct" do
    @@inpatient_ph[:actual_lab_benefit_claim].should == "0.00"
    @@actual_lab_benefit_claim  = @@inpatient_ph[:actual_lab_benefit_claim] .to_f
    end
    it "(1st endoscopic scenario) Checks if the actual charge for room and board is correct" do
    @@actual_room_charges = @room_discount * @days1
    @@inpatient_ph[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
    end
    it "(1st endoscopic scenario) Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@patient_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@patient_promo_discount))
    @@inpatient_ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(1st endoscopic scenario) Checks if the actual operation benefit claim is correct" do
    @@actual_operation_benefit_claim = 1500.0
    @@inpatient_ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(1st endoscopic scenario) Checks if the total actual charge(s) is correct" do
    @@rate = @inpatient_room_rate - (@inpatient_room_rate * @@patient_promo_discount)
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate
    @@inpatient_ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "(1st endoscopic scenario) Checks if the actual room benefit claim is correct" do
    @@room_benefit_claim = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB01")
    @@actual_room_benefit_claim = @@room_benefit_claim[:daily_amt].to_i * @days1
    @@inpatient_ph[:room_and_board_actual_benefit_claim].should == ("%0.2f" %(@@actual_room_benefit_claim))
    end
    it "(1st endoscopic scenario) Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim + @@actual_room_benefit_claim
    @@inpatient_ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(1st endoscopic scenario) Checks if the maximum benefits are correct" do
    @@inpatient_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@inpatient_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(1st endoscopic scenario) Checks if Deduction Claims are correct" do
    @@inpatient_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    @@inpatient_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    @@inpatient_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(1st endoscopic scenario) Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim
    else
      @@drugs_remaining_benefit_claim = 0.0
    end
    @@inpatient_ph[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim))

    if @@actual_lab_benefit_claim < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim
    else
      @@lab_remaining_benefit_claim = 0
    end
    @@inpatient_ph[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim))
    end
    it "(1st endoscopic scenario) Checks if computation of PF claims attending physician is applied correctly" do
    @@inpatient_ph[:surgeon_benefit_claim].should == ("%0.2f" %(300.0))
    end
    it "(1st endoscopic scenario) Checks if computation of PF claims surgeon is applied correctly" do # Benefit claim is fixed to 2500 for Operation. All other benefit claims will be set to zero.
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21325")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@inpatient_ph[:inpatient_surgeon_benefit_claim].to_i != @@surgeon_claim
      @@inpatient_ph[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@inpatient_ph[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
    end
    it "(1st endoscopic scenario) Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@inpatient_ph[:inpatient_anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
      @@inpatient_ph[:inpatient_anesthesiologist_benefit_claim].should == ("0.2f" %(0.0)) #8000.0
    else
      @@inpatient_ph[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
    end
    it"(1st endoscopic scenario) Save PhilHealth" do
      slmc.ph_save_computation
    end
    it "(1st endoscopic scenario) Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    it "(1st endoscopic scenario) View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 6
    end
    it "(1st endoscopic scenario) Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
    end
    it"(2nd endoscopic scenario) OSS, Claim Type: Accounts Receivable, Case Type: Intensive Case" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@oss_patient).should be_true
    @@oss_pin = @@oss_pin.gsub(' ', '')
     #slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_patient_info(:philhealth => true)
    end
    it"(2nd endoscopic scenario) Input guarantors" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it"(2nd endoscopic scenario) Order items" do
      @oss_ancillary.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
      end
    end
    it"(2nd endoscopic scenario) Enable Philhealth Information" do
      @@oss_ph = slmc.oss_input_philhealth(:case_type => "INTENSIVE CASE",:claim_type=>"ACCOUNTS RECEIVABLE",
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :compute => true)
    end
    it "(2nd endoscopic scenario) Checks if computation of PF claims attending physician is applied correctly" do
       @@oss_ph[:surgeon_benefit_claim].should == ""
    end
    it "(2nd endoscopic scenario) Checks if computation of PF claims anesthesiologist is applied correctly" do
      @@oss_ph[:anesthesiologist_benefit_claim].should == ""
    end
    it "(2nd endoscopic scenario) Check Benefit Summary totals" do
      @@comp_xray_lab = 0
      @@comp_operation = 0
      @@non_comp_xray_lab = 0
      @@non_comp_operation = 0

      @oss_ancillary.each do |order,n|
        item = PatientBillingAccountingHelper::Philhealth.get_order_details_based_on_order_number(order)
        if item[:ph_code] == "PHS02"
          x_lab_amt = item[:rate].to_f * n
          @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
        end
        if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
        end
        if item[:ph_code] == "PHS03"
          o_amt = item[:rate].to_f * n
          o_amt = item[:rate].to_f * n
          @@comp_operation += o_amt  # total compensable operations
        end
        if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
        end
      end
    end
    it "(2nd endoscopic scenario) Checks if the actual charge for drugs/medicine is correct"   do
       @@actual_medicine_charges = "0.00"
      @@oss_ph[:actual_medicine_charges].should == @@actual_medicine_charges
    end
    it "(2nd endoscopic scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
      if @@actual_medicine_charges.to_f < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
      end
      @@actual_medicine_benefit_claim.should == "0.00"
      @@oss_ph[:actual_medicine_benefit_claim].should == "0.00"
    end
    it "(2nd endoscopic scenario) Checks if the actual charge for xrays, lab and others is correct" do
      @@actual_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
      @@oss_ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(2nd endoscopic scenario) Checks if the actual lab benefit claim is correct" do
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
      if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
        @@actual_lab_benefit_claim = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
      end
      @@oss_ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    end
    it "(2nd endoscopic scenario) Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@@patient_promo_discount * @@comp_operation)
      @@oss_ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(2nd endoscopic scenario) Checks if the actual operation benefit claim is correct" do
       if slmc.get_value("philHealthBean.rvu.code").empty? == false
             @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
          if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
            @@actual_operation_benefit_claim = @@actual_operation_charges
          else
            @@actual_operation_benefit_claim = @@operation_ph_benefit[:max_amt].to_f
          end
          @@oss_ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
        else
          @@actual_operation_benefit_claim = 0.00
          @@oss_ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
      end
    end
    it "(2nd endoscopic scenario) Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges.to_f + @@actual_xray_lab_others + @@actual_operation_charges
      @@oss_ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "(2nd endoscopic scenario) Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim = @@actual_medicine_benefit_claim.to_f + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
      @@oss_ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(2nd endoscopic scenario) Checks if the maximum benefits are correct" do
      @@oss_ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@oss_ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(2nd endoscopic scenario) Checks if Deduction Claims are correct" do
      @@oss_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
      @@oss_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
      @@oss_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(2nd endoscopic scenario) Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim.to_f < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim.to_f
      else
        @@drugs_remaining_benefit_claim = 0.00
      end
      @@oss_ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim

      if @@actual_lab_benefit_claim < @@lab_ph_benefit[:max_amt].to_f
        @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim
      else
        @@lab_remaining_benefit_claim = 0.00
      end
      @@oss_ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim
    end
    it "(2nd endoscopic scenario) Checks if Philhealth Claims is displayed in Summary Totals correctly" do
      slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(2nd endoscopic scenario) Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
      slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
    end
    it"(2nd endoscopic scenario) Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "(2nd endoscopic scenario) Should be able to search patient in pba" do
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@oss_pin)
    end
    it "(2nd endoscopic scenario) Checks No Claim History" do
      slmc.click_latest_philhealth_link_for_outpatient
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    it"(2nd endoscopic scenario) Should be able to View Details" do
      slmc.ph_view_details(:close => true).should == 2
    end
    it"(2nd endoscopic scenario) Should Print Philhealth Form and Prooflist" do
      slmc.ph_print_report.should be_true
    end
    it"(3rd endoscopic scenario) OSS, Claim Type: Refund, Case Type: Intensive Case" do
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@oss_pin)
      slmc.click_outpatient_order.should be_true
    end
    it "(3rd endoscopic scenario) Input guarantors" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it"(3rd endoscopic scenario) Order items" do
      @@oss_orders =  @oss_ancillary.merge(@oss_operation)
      @@oss_orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
      end
    end
    it"(3rd endoscopic scenario) Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it"(3rd endoscopic scenario) Should be able to search patient in pba" do
      sleep 6
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@oss_pin)
    end
    it"(3rd endoscopic scenario) Philhealth claim type should be refund" do
      slmc.click_latest_philhealth_link_for_outpatient
      slmc.is_element_present'//input[@type="text" and @value="REFUND"]'
    end
    it"(3rd endoscopic scenario) Enable Philhealth Information" do
     @@oss_ph = slmc.philhealth_computation(:medical_case_type => "INTENSIVE CASE",:with_operation=>true,
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "21325", :compute => true)
    end
    it"(3rd endoscopic scenario) Check Benefit Summary totals" do
      @@comp_drugs = 0
      @@comp_xray_lab = 0
      @@comp_operation = 0
      @@non_comp_xray_lab = 0
      @@non_comp_drugs = 0
       @@non_comp_operation = 0

      @@oss_orders.each do |order,n|
        item = PatientBillingAccountingHelper::Philhealth.get_order_details_based_on_order_number(order)
        if item[:ph_code] == "PHS01"
          amt = item[:rate].to_f * n
          @@comp_drugs += amt  # total compensable drug
        end
        if item[:ph_code] == "PHS06"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
        end
        if item[:ph_code] == "PHS02"
          x_lab_amt = item[:rate].to_f * n
          @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
        end
        if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
        end
        if item[:ph_code] == "PHS03"
          o_amt = item[:rate].to_f * n
          o_amt = item[:rate].to_f * n
          @@comp_operation += o_amt  # total compensable operations
        end
        if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
        end
      end
    end
    it"(3rd endoscopic scenario) Checks if the actual charge for drugs/medicine is correct"   do
      @@actual_medicine_charges = @@comp_drugs -  (@@patient_promo_discount * @@comp_drugs)
      @@actual_medicine_charges.should == "0.0".to_f
      @@oss_ph[:or_actual_medicine_charges].should == "0.00"
    end
    it"(3rd endoscopic scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
      end
      @@actual_medicine_benefit_claim.should == "0.0".to_f
      @@oss_ph[:or_actual_medicine_benefit_claim].should == "0.00"
    end
    it "(3rd endoscopic scenario) Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
      @@actual_xray_lab_others = total_xrays_lab_others - (@@patient_promo_discount * total_xrays_lab_others)
      @@oss_ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(3rd endoscopic scenario) Checks if the actual lab benefit claim is correct" do
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
        if (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim.to_f) < 0.00
        @@actual_lab_benefit_claim2 = 0.00
      elsif @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim.to_f)
        @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim2 = (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim.to_f)
      end
      @@oss_ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    end
    it "(3rd endoscopic scenario) Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@@patient_promo_discount * @@comp_operation)
      @@oss_ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(3rd endoscopic scenario) Checks if the actual operation benefit claim is correct" do
        @@actual_operation_benefit_claim = "1500.0".to_f
        @@oss_ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(3rd endoscopic scenario) Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@oss_ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "(3rd endoscopic scenario) Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim
      @@oss_ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(3rd endoscopic scenario) Checks if the maximum benefits are correct" do
      @@oss_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@oss_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(3rd endoscopic scenario) Checks if Deduction Claims are correct" do
      @@oss_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
      @@oss_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
      @@oss_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(3rd endoscopic scenario) Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim
      else
        @@drugs_remaining_benefit_claim = 0.00
      end
      @@oss_ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim

      if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim)
      @@lab_remaining_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim)
    else
      @@lab_remaining_benefit_claim2 = 0
    end
    @@oss_ph[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim2))
    end
    it "(3rd endoscopic scenario) Checks Claim History" do
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
    end
    it "(3rd endoscopic scenario) Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21325")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@oss_ph[:surgeon_benefit_claim].to_i != @@surgeon_claim
      @@oss_ph[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
    else
      @@oss_ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
    end
    it "(3rd endoscopic scenario) Should be able to View Details" do
      slmc.ph_view_details(:close => true).should == 3
    end
    it "(3rd endoscopic scenario) Should be able to Save philhealth computation" do
    #   slmc.ph_save_computation.should be_true
    sleep 3
       if !slmc.is_editable("btnSave")
             slmc.click "btnSave", :wait_for => :page
             sleep 20
    end
    it "(3rd endoscopic scenario) Should Print Philhealth Form and Prooflist" do
      sleep 5
      slmc.ph_print_report#.should be_true
    end
    it"(4th endoscopic scenario) OR, Claim Type: Accounts Receivable, Case Type: Catastrophic Case" do
      sleep 6
      slmc.login(@or_user, @password).should be_true
      @@or_pin = slmc.or_nb_create_patient_record(Admission.generate_data(:not_senior => true).merge(:admit => true, :gender => 'F')).gsub(' ', '')
       slmc.login(@or_user, @password).should be_true
      slmc.go_to_occupancy_list_page
      slmc.patient_pin_search(:pin => @@or_pin)
      slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
      @drugs.each do |item, q|
          slmc.search_order(:description => item, :drugs => true).should be_true
          slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
              :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
          end
      @ancillary.each do |item, q|
        slmc.search_order(:description => item, :ancillary => true).should be_true
        slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
      end
      slmc.verify_ordered_items_count(:drugs => 3).should be_true
      slmc.verify_ordered_items_count(:ancillary => 1).should be_true
      slmc.er_submit_added_order(:validate => true)
      slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
      slmc.confirm_validation_all_items
    end
    it"(4th endoscopic scenario) Order procedure items" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items.should be_true
    end
    it"(4th endoscopic scenario) Clinically discharge patient" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Discharge Instructions\302\240", @@or_pin)
    slmc.add_final_diagnosis(:save => true)
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Doctor and PF Amount", @@or_pin)
    @@visit_no = slmc.get_text("banner.visitNo").gsub(' ', '')
    slmc.clinical_discharge(:no_pending_order => true, :pf_amount => "1000").should be_true
    end
    it"(4th endoscopic scenario) Computes philhealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@or_ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
    end
    it "(4th endoscopic scenario) Check Benefit Summary totals" do
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@comp_operation = 0
    @@non_comp_operation = 0
    @@non_comp_supplies = 0

    @@or_orders =  @drugs.merge(@ancillary).merge(@operation)
    @@or_orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
      if item[:ph_code] == "PHS01"
        amt = item[:rate].to_f * n
        @@comp_drugs += amt  # total compensable drug
      end
      if item[:ph_code] == "PHS06"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
      end
      if item[:ph_code] == "PHS02"
        x_lab_amt = item[:rate].to_f * n
        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
    end
    it "(4th endoscopic scenario) Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@patient_promo_discount * total_drugs)
    @@or_ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "(4th endoscopic scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@patient_promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
    end
    @@or_ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    end
    it "(4th endoscopic scenario) Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    @@actual_xray_lab_others = total_xrays_lab_others - (@@patient_promo_discount * total_xrays_lab_others)
    @@or_ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(4th endoscopic scenario) Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
        if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
          @@actual_lab_benefit_claim = @@actual_comp_xray_lab_others
        else
     @@actual_lab_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
    end
    @@or_ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    end
    it "(4th endoscopic scenario) Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@patient_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@patient_promo_discount))
    @@or_ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(4th endoscopic scenario) Checks if the actual operation benefit claim is correct" do
     if slmc.get_value("rvu.code").empty? == false
        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
        if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
          @@actual_operation_benefit_claim = @@actual_operation_charges
        else
          @@actual_operation_benefit_claim = @@operation_ph_benefit[:max_amt].to_f
        end
        @@or_ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
      else
        @@actual_operation_benefit_claim = 0.00
        @@or_ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
     end
    end
    it "(4th endoscopic scenario) Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    #    @@or_ph[:er_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    ((slmc.truncate_to((@@or_ph[:or_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.02
    end
    it "(4th endoscopic scenario) Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
    @@or_ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(4th endoscopic scenario) Checks if the maximum benefits are correct" do
    @@or_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@or_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(4th endoscopic scenario) Checks if Deduction Claims are correct" do
    @@or_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    @@or_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    @@or_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(4th endoscopic scenario) Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim
    else
      @@drugs_remaining_benefit_claim = 0.0
    end
    @@or_ph[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim))

    if @@actual_lab_benefit_claim < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim)
    else
      @@lab_remaining_benefit_claim = 0
    end
    @@or_ph[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim))
    end
    it "(4th endoscopic scenario) Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    it"(4th endoscopic scenario) Save philhealth computation" do
    slmc.ph_save_computation
    end
    it "(4th endoscopic scenario) User should have an option either Hospital or Patient" do
    slmc.ph_print_report.should be_true
    end
    it"(5th endoscopic scenario) OR, Claim Type: Refund, Case Type: Catastrophic Case" do
      slmc.login(@or_user, @password).should be_true
      @@or_pin = slmc.or_nb_create_patient_record(Admission.generate_data(:not_senior => true).merge(:admit => true, :gender => 'F')).gsub(' ', '')
       slmc.login(@or_user, @password).should be_true
      slmc.go_to_occupancy_list_page
      slmc.patient_pin_search(:pin => @@or_pin)
      slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
      @drugs.each do |item, q|
          slmc.search_order(:description => item, :drugs => true).should be_true
          slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
              :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
          end
      @oss_ancillary.each do |item, q|
        slmc.search_order(:description => item, :ancillary => true).should be_true
        slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
      end
      slmc.verify_ordered_items_count(:drugs => 3).should be_true
      slmc.verify_ordered_items_count(:ancillary => 2).should be_true
      slmc.er_submit_added_order(:validate => true)
      slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
      slmc.confirm_validation_all_items
    end
    it"(5th endoscopic scenario) Order procedure items" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@inpatient_item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@inpatient_item_code, :description => "POWER BONE SHAVING")
    @@inpatient_item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@inpatient_item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items.should be_true
    end
    it"(5th endoscopic scenario) Clinically discharge patient" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Discharge Instructions\302\240", @@or_pin)
    slmc.add_final_diagnosis(:save => true)
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Doctor and PF Amount", @@or_pin)
    @@visit_no = slmc.get_text("banner.visitNo").gsub(' ', '')
    slmc.clinical_discharge(:no_pending_order => true, :pf_amount => "1000").should be_true
    end
    it"(5th endoscopic scenario) Administratively discharge patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment
    slmc.go_to_patient_billing_accounting_page
    end
    it"(5th endoscopic scenario) Enable philhealth information" do
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
    @@or_ph = slmc.philhealth_computation(:diagnosis => "CHOLERA", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "21325", :compute => true)
    end
    it "(5th endoscopic scenario) Claim Type should be Refund" do
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.is_editable("claimType").should be_false
    end
    it "(5th endoscopic scenario) Check Benefit Summary totals" do
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@comp_operation = 0
    @@non_comp_operation = 0
    @@non_comp_supplies = 0

    @@or_orders =  @drugs.merge(@oss_ancillary).merge(@operation)
    @@or_orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
      if item[:ph_code] == "PHS01"
        amt = item[:rate].to_f * n
        @@comp_drugs += amt  # total compensable drug
      end
      if item[:ph_code] == "PHS06"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
      end
      if item[:ph_code] == "PHS02"
        x_lab_amt = item[:rate].to_f * n
        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
    end
    it "(5th endoscopic scenario) Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@patient_promo_discount * total_drugs)
    @@or_ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "(5th endoscopic scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@patient_promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
    end
    @@or_ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    end
    it "(5th endoscopic scenario) Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    @@actual_xray_lab_others = total_xrays_lab_others - (@@patient_promo_discount * total_xrays_lab_others)
    @@or_ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(5th endoscopic scenario) Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
        if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
          @@actual_lab_benefit_claim = @@actual_comp_xray_lab_others
        else
     @@actual_lab_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
    end
    @@or_ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    end
    it "(5th endoscopic scenario) Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@patient_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@patient_promo_discount))
    @@or_ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(5th endoscopic scenario) Checks if the actual operation benefit claim is correct" do
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
    @@actual_operation_benefit_claim = 1500.0
    @@or_ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(5th endoscopic scenario) Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    #    @@or_ph[:er_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    ((slmc.truncate_to((@@or_ph[:or_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.02
    end
    it "(5th endoscopic scenario) Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
    @@or_ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(5th endoscopic scenario) Checks if the maximum benefits are correct" do
    @@or_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@or_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(5th endoscopic scenario) Checks if Deduction Claims are correct" do
    @@or_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    @@or_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    @@or_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(5th endoscopic scenario) Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim
    else
      @@drugs_remaining_benefit_claim = 0.0
    end
    @@or_ph[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim))

    if @@actual_lab_benefit_claim < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim)
    else
      @@lab_remaining_benefit_claim = 0
    end
    @@or_ph[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim))
    end
    it"(5th endoscopic scenario) Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("21325")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    if @@or_ph[:surgeon_benefit_claim].to_i != @@surgeon_claim
      (@@or_ph[:surgeon_benefit_claim].to_i).should == 8000.0
    else
      @@or_ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
    end
    it"(5th endoscopic scenario) Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    if @@or_ph[:anesthesiologist_benefit_claim].to_i != @@anesthesiologist_claim
      (@@or_ph[:anesthesiologist_benefit_claim].to_i).should == 8000.0
    else
      @@or_ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    end
    end
    it"(5th endoscopic scenario) Save philhealth computation" do
    slmc.ph_save_computation
    end
    it"(5th endoscopic scenario) Should be able to View Details" do
      slmc.ph_view_details(:close => true).should == 7
    end
    it"(5th endoscopic scenario) User should have an option either Hospital or Patient" do
    slmc.ph_print_report.should be_true
    end
    it"(5th endoscopic scenario) Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    ####### NO ER PHILHEALTH
    #######  it"(6th endoscopic scenario) ER, Claim Type: Accounts Receivable / Refund, Case Type: Super Catastrophic"  do
    #######    slmc.login(@er_user, @password).should be_true
    #######    @@er_pin = slmc.er_create_patient_record(@er_patient.merge(:admit => true)).should be_true
    #######    @@er_pin = @@er_pin.gsub(' ', '')
    #######    slmc.login(@er_user, @password).should be_true
    #######    slmc.go_to_er_landing_page
    #######    slmc.patient_pin_search(:pin => @@er_pin)
    #######    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin)
    #######    @drugs.each do |item, q|
    #######      slmc.search_order(:description => item, :drugs => true).should be_true
    #######      slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
    #######          :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    #######    end
    #######    @ancillary.each do |item, q|
    #######      slmc.search_order(:description => item, :ancillary => true).should be_true
    #######      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    #######    end
    #######    sleep 5
    #######    slmc.verify_ordered_items_count(:drugs => 3).should be_true
    #######    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    #######    slmc.er_submit_added_order
    #######    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
    #######    slmc.confirm_validation_all_items
    #######  end
    #######
    #######  it"(6th endoscopic scenario) Order procedure items" do
    #######    slmc.login(@or_user,@password).should be_true
    #######    slmc.go_to_occupancy_list_page
    #######    slmc.patient_pin_search(:pin => @@er_pin)
    #######    slmc.go_to_gu_page_for_a_given_pin("Checklist Order", @@er_pin)
    #######    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    #######    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    #######    @@item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    #######    slmc.add_returned_service(:item_code => @@item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    #######    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    #######    slmc.validate_orders(:orders => "multiple", :procedures => true)
    #######    slmc.confirm_validation_all_items.should be_true
    #######  end
    #######
    #######   it"(6th endoscopic scenario) Clinically discharge patient" do
    #######    slmc.login(@er_user, @password).should be_true
    #######    slmc.go_to_er_landing_page
    #######    slmc.patient_pin_search(:pin => @@er_pin)
    #######    @@room_and_bed = slmc.er_get_room_and_bed_no_in_gu_page
    #######    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
    #######  end
    #######
    #######  it"(6th endoscopic scenario) Add and edit patient record" do
    #######    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days1, :pin => @@er_pin, :visit_no => @@visit_no)
    #######    Database.connect
    #######    @days1.times do |i|
    #######      @rb = (slmc.get_last_record_of_rb_trans_no)
    #######      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no, :rb_trans_no => @rb, :created_by => @er_user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount1, :created_datetime => @my_date)
    #######      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @er_room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @er_user)
    #######      @my_date = slmc.increase_date_by_one(@days1 - i)
    #######    end
    #######    Database.logoff
    #######  end
    #######
    #######  it"(6th endoscopic scenario) Computes philhealth" do
    #######    slmc.go_to_er_billing_page
    #######    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin)
    #######    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
    #######
    #######    @@er_ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "SUPER CATASTROPHIC CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Check Benefit Summary totals" do
    #######    @@comp_drugs = 0
    #######    @@non_comp_drugs = 0
    #######    @@comp_xray_lab = 0
    #######    @@non_comp_xray_lab = 0
    #######    @@comp_operation = 0
    #######    @@non_comp_operation = 0
    #######
    #######    @@er_orders =  @drugs.merge(@ancillary).merge(@operation)
    #######    @@er_orders.each do |order,n|
    #######      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
    #######      if item[:ph_code] == "PHS01"
    #######        amt = item[:rate].to_f * n
    #######        @@comp_drugs += amt  # total compensable drug
    #######      end
    #######      if item[:ph_code] == "PHS06"
    #######        n_amt = item[:rate].to_f * n
    #######        @@non_comp_drugs += n_amt # total non-compensable drug
    #######      end
    #######      if item[:ph_code] == "PHS02"
    #######        x_lab_amt = item[:rate].to_f * n
    #######        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
    #######      end
    #######      if item[:ph_code] == "PHS07"
    #######        n_x_lab_amt = item[:rate].to_f * n
    #######        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
    #######      end
    #######      if item[:ph_code] == "PHS03"
    #######        o_amt = item[:rate].to_f * n
    #######        @@comp_operation += o_amt  # total compensable operations
    #######      end
    #######      if item[:ph_code] == "PHS08"
    #######        n_o_amt = item[:rate].to_f * n
    #######        @@non_comp_operation += n_o_amt # total non compensable operations
    #######      end
    #######    end
    #######  end
    #######
    #######   it "(6th endoscopic scenario) Checks if the actual charge for drugs/medicine is correct" do
    #######    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    #######    total_drugs = @@comp_drugs + @@non_comp_drugs
    #######    @@actual_medicine_charges = total_drugs - (@@patient_promo_discount * total_drugs)
    #######    @@er_ph[:er_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
    #######    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@patient_promo_discount)
    #######      if @@med_ph_benefit[:max_amt].to_f < 0
    #######       @@actual_medicine_benefit_claim = 0.00
    #######      elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
    #######        @@actual_medicine_benefit_claim  = @@actual_comp_drugs
    #######      else
    #######       @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
    #######      end
    #######      @@er_ph[:er_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks if the actual charge for xrays, lab and others is correct" do
    #######    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    #######    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@patient_promo_discount)
    #######    @@er_ph[:er_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks if the actual lab benefit claim is correct" do
    #######    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
    #######    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    #######      if @@lab_ph_benefit[:max_amt].to_f < 0
    #######        @@actual_lab_benefit_claim = 0.00
    #######      elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
    #######        @@actual_lab_benefit_claim = @@actual_comp_xray_lab_others
    #######      else
    #######        @@actual_lab_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
    #######      end
    #######      @@er_ph[:er_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    #######  end
    #######
    ####### it "(6th endoscopic scenario) Checks if the actual charge for operation is correct" do
    #######    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@patient_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@patient_promo_discount))
    #######    @@er_ph[:er_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks if the actual operation benefit claim is correct" do
    #######    @@actual_operation_benefit_claim = 1200.0
    #######    @@er_ph[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks if the total actual charge(s) is correct" do
    #######    @@rate = @er_room_rate - (@er_room_rate * @@patient_promo_discount)
    #######    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate
    ########    @@er_ph[:er_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    #######    ((slmc.truncate_to((@@er_ph[:er_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.02
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks if the total actual benefit claim is correct" do
    #######    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
    #######    @@er_ph[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks if the maximum benefits are correct" do
    #######    @@er_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    #######    @@er_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks if Deduction Claims are correct" do
    #######    @@er_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    #######    @@er_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    #######    @@er_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks if Remaining Benefit Claims are correct" do
    #######     if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
    #######        @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim
    #######      else
    #######        @@drugs_remaining_benefit_claim = 0.0
    #######      end
    #######      @@er_ph[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim))
    #######
    #######      if @@actual_lab_benefit_claim < @@lab_ph_benefit[:max_amt].to_f
    #######        @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim
    #######      else
    #######        @@lab_remaining_benefit_claim = 0
    #######      end
    #######      @@er_ph[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim))
    #######  end
    #######
    #######   it "(6th endoscopic scenario) Checks if computation of PF claims surgeon is applied correctly" do
    #######      @@surgeon_claim = 560.0
    #######      @@er_ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks if computation of PF claims anesthesiologist is applied correctly" do
    #######    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.6")
    #######    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
    #######    if @@er_ph[:anesthesiologist_benefit_claim].to_i != @@anesthesiologist_claim
    #######      (@@er_ph[:anesthesiologist_benefit_claim].to_i).should == 8000.0
    #######    else
    #######      @@er_ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
    #######    end
    #######  end
    #######
    #######  it"(6th endoscopic scenario) Save PhilHealth" do
    #######      slmc.ph_save_computation
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Checks Claim History" do
    #######    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    #######  end
    #######
    #######  it "(6th endoscopic scenario) View Details of the ordered items" do
    #######    slmc.ph_view_details(:close => true).should == 6
    #######  end
    #######
    #######  it "(6th endoscopic scenario) Prints PhilHealth Form and Prooflist" do
    #######    slmc.ph_print_report.should be_true
    #######  end

    it"(7th endoscopic scenario) DR, Claim Type: Accounts Receivable / Refund, Case Type: Super Catastrophic" do
    slmc.login(@dr_user,@password).should be_true
    @@dr_pin = slmc.or_nb_create_patient_record(@dr_patient.merge(:admit => true, :gender => 'F', :org_code => "0170")).gsub(' ', '')
      slmc.login(@dr_user,@password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
          :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.verify_ordered_items_count(:drugs => 3).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    #    slmc.submit_added_order(:validate => true, :username => "sel_dr_validator")
    slmc.submit_added_order(:validate => true, :username => "sel_0170_validator")
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items
    end
    it"(7th endoscopic scenario) Order procedure items" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
    @@item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items
    end
    it"(7th endoscopic scenario) Clinically discharge patient" do
         slmc.login(@dr_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true,:pin => @@dr_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
    end
    it"(7th endoscopic scenario) Should be able to search patient on pba" do
    slmc.login(@pba_user,@password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@dr_pin)
    slmc.click_latest_philhealth_link_for_outpatient
    end
    it"(7th endoscopic scenario) Enable Philhealth Information" do
     @@dr_ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "SUPER CATASTROPHIC CASE", :compute => true)
    end
    it "(7th endoscopic scenario) Check Benefit Summary totals" do
      @@comp_drugs = 0
      @@comp_xray_lab = 0
      @@comp_operation = 0
      @@non_comp_xray_lab = 0
      @@non_comp_drugs = 0
      @@non_comp_operation = 0

      @@orders =  @drugs.merge(@ancillary).merge(@operation)
      @@orders.each do |order,n|
        item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
        if item[:ph_code] == "PHS01"
          amt = item[:rate].to_f * n
          @@comp_drugs += amt  # total compensable drug
        end
        if item[:ph_code] == "PHS06"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
        end
        if item[:ph_code] == "PHS02"
          x_lab_amt = item[:rate].to_f * n
          @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
        end
        if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
        end
        if item[:ph_code] == "PHS03"
          o_amt = item[:rate].to_f * n
          o_amt = item[:rate].to_f * n
          @@comp_operation += o_amt  # total compensable operations
        end
        if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
        end
      end
    end
    it "(7th endoscopic scenario) Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@patient_promo_discount * total_drugs)
    @@dr_ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "(7th endoscopic scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@patient_promo_discount)
      if @@med_ph_benefit[:max_amt].to_f < 0
       @@actual_medicine_benefit_claim = 0.00
      elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim  = @@actual_comp_drugs
      else
       @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
      end
      @@dr_ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    end
    it "(7th endoscopic scenario) Checks if the actual charge for xrays, lab and others is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@patient_promo_discount)
    @@dr_ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(7th endoscopic scenario) Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
      if @@lab_ph_benefit[:max_amt].to_f < 0
        @@actual_lab_benefit_claim = 0.00
      elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
        @@actual_lab_benefit_claim = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
      end
      @@dr_ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    end
    it "(7th endoscopic scenario) Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@patient_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@patient_promo_discount))
    @@dr_ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(7th endoscopic scenario) Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim = @@operation_ph_benefit[:max_amt].to_f
      end
      @@dr_ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    else
      @@actual_operation_benefit_claim = 0.00
      @@dr_ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    end
    it "(7th endoscopic scenario) Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    #    @@dr_ph[:er_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    ((slmc.truncate_to((@@dr_ph[:or_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.02
    end
    it "(7th endoscopic scenario) Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
    @@dr_ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(7th endoscopic scenario) Checks if the maximum benefits are correct" do
    @@dr_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@dr_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(7th endoscopic scenario) Checks if Deduction Claims are correct" do
    @@dr_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    @@dr_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    @@dr_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(7th endoscopic scenario) Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim
      else
        @@drugs_remaining_benefit_claim = 0.0
      end
      @@dr_ph[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim))

      if @@actual_lab_benefit_claim < @@lab_ph_benefit[:max_amt].to_f
        @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim
      else
        @@lab_remaining_benefit_claim = 0
      end
      @@dr_ph[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim))
    end
    it"(7th endoscopic scenario) Save PhilHealth" do
    slmc.ph_save_computation
    end
    it "(7th endoscopic scenario) Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    it "(7th endoscopic scenario) View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 6
    end
    it "(7th endoscopic scenario) Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
    end

    end

end