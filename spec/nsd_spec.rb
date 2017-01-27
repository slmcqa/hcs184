
require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Normal Spontaneous Delivery Case" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"



    @inpatient_user = "gu_spec_user8"
    @oss_user = "jtsalang"
    @or_user = "slaquino"
#    @pba_user = "pba27"
    @pba_user = "ldcastro" #manual spec
    @er_user = "sel_er2"
    @dr_user = "sel_dr3"





    @inpatient = Admission.generate_data(:not_senior => true)
    @patient = Admission.generate_data(:not_senior => true)
    @patient1 = Admission.generate_data(:not_senior => true)
    @or_patient = Admission.generate_data(:not_senior => true)
    @oss_patient = Admission.generate_data(:not_senior => true)
    @dr_patient = Admission.generate_data(:not_senior => true)
    @@patient_promo_discount = 0.16
    @discount_type_code = "C01"
    @inpatient_room_rate = 4167.0
    @er_room_rate = 0
    @discount_amount = (@inpatient_room_rate * @@patient_promo_discount)
    @discount_amount1 = (@er_room_rate * @@patient_promo_discount)
    @room_discount = @inpatient_room_rate - @discount_amount
    @room_discount1 = @er_room_rate - @discount_amount1
    @days1= 1
    @drugs =  {"042090007" => 1, "041840008" => 1, "049000028" => 1, "040950558" => 1}
    @ancillary = {"010001194" => 1, "010001448" => 1}
    @operation = {"060000204" => 1, "060002045" => 1}
    @oss_operation = {"010000160" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

    it "(1st nsd scenario) Inpatient, Claim Type: Accounts Receivable, Case Type: Catastrophic Case" do
      slmc.login(@inpatient_user, @password).should be_true
      slmc.admission_search(:pin => "Test")
      @@inpatient_pin = slmc.create_new_patient(@patient).gsub(' ', '')
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
      slmc.verify_ordered_items_count(:drugs => 4).should be_true
      slmc.verify_ordered_items_count(:ancillary => 2).should be_true
      sleep 3
      slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
      slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 6
      slmc.confirm_validation_all_items.should be_true
    end
    it "(1st nsd scenario) Order procedure items" do
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
    end
    it "(1st nsd scenario) Clinically discharge patient" do
      slmc.login(@inpatient_user, @password).should be_true
      slmc.nursing_gu_search(:pin=> @@inpatient_pin)
      @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
      @@inpatient_visit_no = slmc.clinically_discharge_patient(:pin => @@inpatient_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
    end
    it "(1st nsd scenario) Add and Edit records of patient" do
      @my_date = slmc.adjust_admission_date(:days_to_adjust => @days1, :pin => @@inpatient_pin, :visit_no => @@inpatient_visit_no)
      Database.connect
      @days1.times do |i|
        puts" @days1-#{@days1}"
        @rb = (slmc.get_last_record_of_rb_trans_no)
        puts "@rb - #{@rb}"
        slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@inpatient_visit_no,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @inpatient_room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @inpatient_user)
        slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@inpatient_visit_no, :rb_trans_no => @rb, :created_by => @inpatient_user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
        @my_date = slmc.increase_date_by_one(@days1 - i)
      end
      Database.logoff
    end
    it "(1st nsd scenario) Computes philhealth" do
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
      slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
      @@inpatient_ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "59400", :compute => true)
    end
    it "(1st nsd scenario) Check Benefit Summary totals" do
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
    it "(1st nsd scenario) Checks if the actual charge for drugs/medicine is correct" do
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs - (@@patient_promo_discount * total_drugs)
      @@inpatient_ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "(1st nsd scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
      @@inpatient_ph[:actual_medicine_benefit_claim].should == "0.00"
      @@actual_medicine_benefit_claim = @@inpatient_ph[:actual_medicine_benefit_claim].to_f
    end
    it "(1st nsd scenario) Checks if the actual charge for xrays, lab and others is correct" do
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
      @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@patient_promo_discount)
      @@inpatient_ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(1st nsd scenario) Checks if the actual lab benefit claim is correct" do
      @@inpatient_ph[:actual_lab_benefit_claim].should == "0.00"
      @@actual_lab_benefit_claim  = @@inpatient_ph[:actual_lab_benefit_claim] .to_f
    end
    it "(1st nsd scenario) Checks if the actual charge for room and board is correct" do
      @@actual_room_charges = @room_discount * @days1
      @@inpatient_ph[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
    end
    it "(1st nsd scenario) Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@patient_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@patient_promo_discount))
      @@inpatient_ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(1st nsd scenario) Checks if the actual operation benefit claim is correct" do
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04") #NSD special case 2500 fixed
      @@actual_operation_benefit_claim = 2500.0
      @@inpatient_ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(1st nsd scenario) Checks if the total actual charge(s) is correct" do
      @@rate = @inpatient_room_rate - (@inpatient_room_rate * @@patient_promo_discount)
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate # may room rate lang kapag naka PBA discharge na ang patient , else wala
      @@inpatient_ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "(1st nsd scenario) Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
      @@inpatient_ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(1st nsd scenario) Checks if the maximum benefits are correct" do
      @@inpatient_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@inpatient_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(1st nsd scenario) Checks if Deduction Claims are correct" do
      @@inpatient_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
      @@inpatient_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
      @@inpatient_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(1st nsd scenario) Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f
      else
        @@drugs_remaining_benefit_claim = 0.0
      end
      @@inpatient_ph[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim))

      if @@actual_lab_benefit_claim < @@lab_ph_benefit[:max_amt].to_f
        @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
      else
        @@lab_remaining_benefit_claim = 0
      end
      @@inpatient_ph[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim))
    end
    it "(1st nsd scenario) Checks if computation of PF claims attending physician is applied correctly" do
      @@inpatient_ph[:surgeon_benefit_claim].should == ("%0.2f" %(500.0))
    end
    it "(1st nsd scenario) Checks if computation of PF claims surgeon is applied correctly" do
      @@inpatient_ph[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(0.0))
    end
    it "(1st nsd scenario) Checks if computation of PF claims anesthesiologist is applied correctly" do
      @@inpatient_ph[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(0.0))
    end
    it "(1st nsd scenario) Save PhilHealth" do
        slmc.ph_save_computation
    end
    it "(1st nsd scenario) Checks Claim History" do
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    it "(1st nsd scenario) View Details of the ordered items" do
      slmc.ph_view_details(:close => true).should == 8
    end
    it "(1st nsd scenario) Prints PhilHealth Form and Prooflist" do
      slmc.ph_print_report.should be_true
    end
    it "(1st nsd scenario) Discharges the patient in PBA" do
      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:pin => @@inpatient_pin)
      slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
      slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
      slmc.discharge_to_payment.should be_true
    end
    it "(1st nsd scenario) Prints Gate Pass of the patient" do
      slmc.login(@inpatient_user, @password).should be_true
      slmc.nursing_gu_search(:pin => @@inpatient_pin)
      slmc.print_gatepass
    end
    it "(2nd nsd scenario) Inpatient, Claim Type: Refund, Case Type: Catastrophic Case" do
      sleep 10
      slmc.login(@inpatient_user, @password).should be_true
      slmc.admission_search(:pin => "test")
      @@inpatient_pin = slmc.create_new_patient(@inpatient).gsub(' ', '')
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
      slmc.verify_ordered_items_count(:drugs => 4).should be_true
      slmc.verify_ordered_items_count(:ancillary => 2).should be_true
      slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
      slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
      slmc.confirm_validation_all_items.should be_true
    end
    it "(2nd nsd scenario) Order procedure items" do
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
    end
    it "(2nd nsd scenario) Clinically discharge patient" do
      slmc.login(@inpatient_user, @password).should be_true
      slmc.nursing_gu_search(:pin=> @@inpatient_pin)
      @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
      @@inpatient_visit_no = slmc.clinically_discharge_patient(:pin => @@inpatient_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
    end
    it "(2nd nsd scenario) Add and edit patient record" do
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
    it "(2nd nsd scenario) Computes philhealth" do
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
      slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
      @@inpatient_ph = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "CATASTROPHIC CASE", :with_operation => true, :rvu_code => "59400", :compute => true)
    end
    it "(2nd nsd scenario) Check Benefit Summary totals" do
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
    it "(2nd nsd scenario) Checks if the actual charge for drugs/medicine is correct" do
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs - (@@patient_promo_discount * total_drugs)
      @@inpatient_ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "(2nd nsd scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
      @@inpatient_ph[:actual_medicine_benefit_claim].should == "0.00"
      @@actual_medicine_benefit_claim = @@inpatient_ph[:actual_medicine_benefit_claim].to_f
    end
    it "(2nd nsd scenario) Checks if the actual charge for xrays, lab and others is correct" do
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
      @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@patient_promo_discount)
      @@inpatient_ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(2nd nsd scenario) Checks if the actual lab benefit claim is correct" do
      @@inpatient_ph[:actual_lab_benefit_claim].should == "0.00"
      @@actual_lab_benefit_claim  = @@inpatient_ph[:actual_lab_benefit_claim] .to_f
    end
    it "(2nd nsd scenario) Checks if the actual charge for room and board is correct" do
      @@actual_room_charges = @room_discount * @days1
      @@inpatient_ph[:room_and_board_actual_charges].should == ("%0.2f" %(@@actual_room_charges))
    end
    it "(2nd nsd scenario) Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@patient_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@patient_promo_discount))
      @@inpatient_ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(2nd nsd scenario) Checks if the actual operation benefit claim is correct" do
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04") #NSD special case 2500 fixed
      @@actual_operation_benefit_claim = 2500.0
      @@inpatient_ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(2nd nsd scenario) Checks if the total actual charge(s) is correct" do
      @@rate = @inpatient_room_rate - (@inpatient_room_rate * @@patient_promo_discount)
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate # may room rate lang kapag naka PBA discharge na ang patient , else wala
      @@inpatient_ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "(2nd nsd scenario) Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
      @@inpatient_ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(2nd nsd scenario) Checks if the maximum benefits are correct" do
      @@inpatient_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@inpatient_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(2nd nsd scenario) Checks if Deduction Claims are correct" do
      @@inpatient_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
      @@inpatient_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
      @@inpatient_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(2nd nsd scenario) Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f
      else
        @@drugs_remaining_benefit_claim = 0.0
      end
      @@inpatient_ph[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim))

      if @@actual_lab_benefit_claim < @@lab_ph_benefit[:max_amt].to_f
        @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
      else
        @@lab_remaining_benefit_claim = 0
      end
      @@inpatient_ph[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim))
    end
    it "(2nd nsd scenario) Checks if computation of PF claims attending physician is applied correctly" do
      @@inpatient_ph[:surgeon_benefit_claim].should == ("%0.2f" %(500.0))
    end
    it "(2nd nsd scenario) Checks if computation of PF claims surgeon is applied correctly" do
      @@inpatient_ph[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(0.0))
    end
    it "(2nd nsd scenario) Checks if computation of PF claims anesthesiologist is applied correctly" do
      @@inpatient_ph[:inpatient_anesthesiologist_benefit_claim].should == ("%0.2f" %(0.0))
    end
    it "(2nd nsd scenario) Save PhilHealth" do
        slmc.ph_save_computation
    end
    it "(2nd nsd scenario) Checks Claim History" do
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    it "(2nd nsd scenario) View Details of the ordered items" do
      slmc.ph_view_details(:close => true).should == 8
    end
    it "(2nd nsd scenario) Prints PhilHealth Form and Prooflist" do
      slmc.ph_print_report.should be_true
    end
    it "(2nd nsd scenario) Discharges the patient in PBA" do
      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:pin => @@inpatient_pin)
      slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
      slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
      slmc.discharge_to_payment.should be_true
    end
    it "(2nd nsd scenario) Prints Gate Pass of the patient" do
      slmc.login(@inpatient_user, @password).should be_true
      slmc.nursing_gu_search(:pin => @@inpatient_pin)
      slmc.print_gatepass
    end
    it "(3rd nsd scenario) OSS, Claim Type: Accounts Receivable, Case Type: Ordinary Case" do
      sleep 6
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => "test")
      slmc.click_outpatient_registration.should be_true
      @@oss_pin = slmc.oss_outpatient_registration(@oss_patient).should be_true
      @@oss_pin = @@oss_pin.gsub(' ', '')
       #   slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@oss_pin)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
    end
    it "(3rd nsd scenario) Input guarantors" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "(3rd nsd scenario) Order items" do
      @@oss_orders =  @ancillary.merge(@oss_operation)
      @@oss_orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
      end
    end
    it "(3rd nsd scenario) Enable Philhealth Information" do
      @@oss_ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :claim_type=>"ACCOUNTS RECEIVABLE", :with_operation=>true,
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "59400", :compute => true)
    end
    it "(3rd nsd scenario) Check Benefit Summary totals" do
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
    it "(3rd nsd scenario) Checks if the actual charge for drugs/medicine is correct"   do
      @@actual_medicine_charges = @@comp_drugs -  (@@patient_promo_discount * @@comp_drugs)
      @@actual_medicine_charges.should == "0.0".to_f
      @@oss_ph[:actual_medicine_charges].should == "0.00"
    end
    it "(3rd nsd scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
      end
      @@actual_medicine_benefit_claim.should == "0.0".to_f
      @@oss_ph[:actual_medicine_benefit_claim].should == "0.00"
    end
    it "(3rd nsd scenario) Checks if the actual charge for xrays, lab and others is correct" do
      @@actual_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
      @@oss_ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(3rd nsd scenario) Checks if the actual lab benefit claim is correct" do
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
      if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
        @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
      end
      @@oss_ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    end
    it "(3rd nsd scenario) Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@@patient_promo_discount * @@comp_operation)
      @@oss_ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(3rd nsd scenario) Checks if the actual operation benefit claim is correct" do
       if slmc.get_value("philHealthBean.rvu.code").empty? == false
             @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
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
    it "(3rd nsd scenario) Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@oss_ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "(3rd nsd scenario) Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim
      @@oss_ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(3rd nsd scenario) Checks if the maximum benefits are correct" do
      @@oss_ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@oss_ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(3rd nsd scenario) Checks if Deduction Claims are correct" do
      @@oss_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
      @@oss_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
      @@oss_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(3rd nsd scenario) Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim
      else
        @@drugs_remaining_benefit_claim = 0.00
      end
      @@oss_ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim

      if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
        @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
      else
        @@lab_remaining_benefit_claim = 0.00
      end
      @@oss_ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim
    end
    it "(3rd nsd scenario) Checks if Philhealth Claims is displayed in Summary Totals correctly" do
      slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(3rd nsd scenario) Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
      slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
    end
    it "(3rd nsd scenario) Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      puts "amount - #{amount}"
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      sleep 10
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "(3rd nsd scenario) Should be able to search patient in pba" do
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@oss_pin)
    end
    it "(3rd nsd scenario) Checks No Claim History" do
      slmc.click_latest_philhealth_link_for_outpatient
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    it "(3rd nsd scenario) Checks if computation of PF claims attending physician is applied correctly" do
       @@oss_ph[:surgeon_benefit_claim].should == ""
    end
    it "(3rd nsd scenario) Checks if computation of PF claims anesthesiologist is applied correctly" do
      @@oss_ph[:anesthesiologist_benefit_claim].should == ""
    end
    it "(3rd nsd scenario) Should be able to View Details" do
      slmc.ph_view_details(:close => true).should == 3
    end
    it "(3rd nsd scenario) Should Print Philhealth Form and Prooflist" do
      slmc.ph_print_report.should be_true
    end
    it "(4th nsd scenario) OSS, Claim Type: Refund, Case Type: Intensive Case"do
      sleep 6
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@oss_pin)
      slmc.click_outpatient_order.should be_true
    end
    it "(4th nsd scenario) Input guarantors" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "(4th nsd scenario) Order items" do
      @@oss_orders =  @ancillary.merge(@oss_operation)
      @@oss_orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
      end
    end
    it "(4th nsd scenario) Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
      sleep 6
    end
    it "(4th nsd scenario) Should be able to search patient in pba" do
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@oss_pin)
    end
    it "(4th nsd scenario) Philhealth claim type should be refund" do
      slmc.click_latest_philhealth_link_for_outpatient
      slmc.is_element_present'//input[@type="text" and @value="REFUND"]'
    end
    it "(4th nsd scenario) Enable Philhealth Information" do
     @@oss_ph = slmc.philhealth_computation(:medical_case_type => "INTENSIVE CASE", :with_operation=>true,
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "59400", :compute => true)
  end
    it "(4th nsd scenario) Check Benefit Summary totals" do
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
    it "(4th nsd scenario) Checks if the actual charge for drugs/medicine is correct"   do
      @@actual_medicine_charges = @@comp_drugs -  (@@patient_promo_discount * @@comp_drugs)
      @@actual_medicine_charges.should == "0.0".to_f
      @@oss_ph[:or_actual_medicine_charges].should == "0.00"
    end
    it "(4th nsd scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
      end
      @@actual_medicine_benefit_claim.should == "0.0".to_f
      @@oss_ph[:or_actual_medicine_benefit_claim].should == "0.00"
    end
    it "(4th nsd scenario) Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
      @@actual_xray_lab_others = total_xrays_lab_others - (@@patient_promo_discount * total_xrays_lab_others)
      @@oss_ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(4th nsd scenario) Checks if the actual lab benefit claim is correct" do
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
        if (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1.to_f) < 0.00
        @@actual_lab_benefit_claim2 = 0.00
      elsif @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1.to_f)
        @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim2 = (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1.to_f)
      end
      @@oss_ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    end
    it "(4th nsd scenario) Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@@patient_promo_discount * @@comp_operation)
      @@oss_ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(4th nsd scenario) Checks if the actual operation benefit claim is correct" do
      if slmc.get_value("rvu.code").empty? == false
        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
        puts "@@operation_ph_benefit[:max_amt].to_f - #{@@operation_ph_benefit[:min_amt].to_f}"
        if @@actual_operation_charges < @@operation_ph_benefit[:min_amt].to_f
          @@actual_operation_benefit_claim2 = @@actual_operation_charges
        else
          @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:min_amt].to_f
        end
        puts "@@oss_ph[:er_actual_operation_benefit_claim]- #{@@oss_ph[:or_actual_operation_benefit_claim]}"
        @@oss_ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
      else
        @@actual_operation_benefit_claim2 = 1200.00#0.00
        @@oss_ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
      end
    end
    it "(4th nsd scenario) Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@oss_ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "(4th nsd scenario) Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim2 = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2
      @@oss_ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim2))
    end
    it "(4th nsd scenario) Checks if the maximum benefits are correct" do
      @@oss_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@oss_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(4th nsd scenario) Checks if Deduction Claims are correct" do
      @@oss_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
      @@oss_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
      @@oss_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
    end
    it "(4th nsd scenario) Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim
      else
        @@drugs_remaining_benefit_claim2 = "0.00"
      end
      @@oss_ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim2

  #    if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1+ @@actual_lab_benefit_claim2)
      if @@actual_lab_benefit_claim2 < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1)
      @@lab_remaining_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1+ @@actual_lab_benefit_claim2)
      else
    #  @@lab_remaining_benefit_claim2 = "1063.00"
            @@lab_remaining_benefit_claim2 = "0.00"
     end
    @@oss_ph[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim2))
    end
    it "(4th nsd scenario) Checks Claim History" do
#      slmc.get_text(Locators::OSS_Philhealth.claims_history).should != "Nothing found to display."
      (slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display." ).should be_false
    end
    it "(4th nsd scenario) Checks if computation of PF claims surgeon is applied correctly" do
      @@oss_ph[:surgeon_benefit_claim].should == "0.00"
    end
    it "(4th nsd scenario) Should be able to View Details" do
      slmc.ph_view_details(:close => true).should == 3
    end
    it "(4th nsd scenario) Should be able to Save philhealth computation" do
      slmc.ph_save_computation.should be_true
    end
    it "(4th nsd scenario) Should Print Philhealth Form and Prooflist" do
      slmc.ph_print_report.should be_true
    end
    it "(5th nsd scenario) OR, Claim Type: Accounts Receivable/Refund, Case Type: Intensive Case" do
      sleep 6
      slmc.login(@or_user, @password).should be_true
      @@or_pin = slmc.or_nb_create_patient_record(@or_patient.merge(:admit => true, :gender => 'F')).gsub(' ', '')
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
      slmc.verify_ordered_items_count(:drugs => 4).should be_true
      slmc.verify_ordered_items_count(:ancillary => 2).should be_true
      slmc.er_submit_added_order(:validate => true)#.should be_true
      slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
      slmc.confirm_validation_all_items#.should be_true
    end
    it "(5th nsd scenario) Order procedure items" do
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
    it "(5th nsd scenario) Clinically discharge patient" do
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
    it "(5th nsd scenario) Administratively discharge patient" do
            sleep 6

      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
      slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
      slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
      slmc.discharge_to_payment
      slmc.go_to_patient_billing_accounting_page
    end
    it "(5th nsd scenario) Enable philhealth information" do
      slmc.go_to_philhealth_outpatient_computation
      slmc.pba_pin_search(:pin => @@or_pin)
      slmc.click_philhealth_link(:pin => @@or_pin, :visit_no => @@visit_no)
      @@or_ph = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "59400", :compute => true)
    end
    it "(5th nsd scenario) Save philhealth computation" do
      slmc.ph_save_computation
    end
    it "(5th nsd scenario) Checks No Claim History" do
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
      end
    it "(5th nsd scenario) Checks if computation of PF claims attending physician is applied correctly" do
         @@or_ph[:surgeon_benefit_claim].should == "0.00"
     end
    it "(5th nsd scenario) Checks if computation of PF claims surgeon is applied correctly" do
        @@or_ph[:inpatient_surgeon_benefit_claim].should == "0.00"
     end
    it "(5th nsd scenario) Should be able to View Details" do
        slmc.ph_view_details(:close => true).should == 8
      end
    it "(5th nsd scenario) Check Benefit Summary totals" do
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
    it "(5th nsd scenario) Checks if the actual charge for drugs/medicine is correct" do
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs - (@@patient_promo_discount * total_drugs)
      @@or_ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "(5th nsd scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
      @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @@patient_promo_discount)
      if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim = @@comp_drugs_total
      else
        @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
      end
      @@or_ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    end
    it "(5th nsd scenario) Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
      @@actual_xray_lab_others = total_xrays_lab_others - (@@patient_promo_discount * total_xrays_lab_others)
      @@or_ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "(5th nsd scenario) Checks if the actual lab benefit claim is correct" do
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
          if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
            @@actual_lab_benefit_claim = @@actual_comp_xray_lab_others
          else
       @@actual_lab_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
      end
      @@or_ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    end
    it "(5th nsd scenario) Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@patient_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@patient_promo_discount))
      @@or_ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "(5th nsd scenario) Checks if the actual operation benefit claim is correct" do
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
      @@actual_operation_benefit_claim = 1200.0
      @@or_ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(5th nsd scenario) Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@or_ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "(5th nsd scenario) Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
      @@or_ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
    end
    it "(5th nsd scenario) Checks if the maximum benefits are correct" do
      @@or_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@or_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "(5th nsd scenario) Checks if Deduction Claims are correct" do
      @@or_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
      @@or_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
      @@or_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
    end
    it "(5th nsd scenario) Checks if Remaining Benefit Claims are correct" do
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
    it "(5th nsd scenario) Claim Type should be Refund" do
      slmc.get_selected_label("claimType").should == "REFUND"
      slmc.is_editable("claimType").should be_false
    end
    it "(5th nsd scenario) User should have an option either Hospital or Patient" do
      slmc.ph_print_report.should be_true
    end
#########  NO ER PHILHEALTH
#########  it "(6th nsd scenario) ER, Claim Type: Accounts Receivable/Refund, Case Type: Super Catastrophic Case"  do
#########    slmc.login(@er_user, @password).should be_true
#########    @@er_pin = slmc.er_create_patient_record(@patient1.merge(:admit => true)).should be_true
#########    @@er_pin = @@er_pin.gsub(' ', '')
#########    slmc.login(@er_user, @password).should be_true
#########    slmc.go_to_er_landing_page
#########    slmc.patient_pin_search(:pin => @@er_pin)
#########    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin)
#########    @drugs.each do |item, q|
#########      slmc.search_order(:description => item, :drugs => true).should be_true
#########      slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
#########          :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
#########    end
#########    @ancillary.each do |item, q|
#########      slmc.search_order(:description => item, :ancillary => true).should be_true
#########      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
#########    end
#########    sleep 5
#########    slmc.verify_ordered_items_count(:drugs => 4).should be_true
#########    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
#########    slmc.er_submit_added_order
#########    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
#########    slmc.confirm_validation_all_items.should be_true
#########  end
#########
#########  it "(6th nsd scenario) Order procedure items" do
#########    slmc.login(@or_user,@password).should be_true
#########    slmc.go_to_occupancy_list_page
#########    slmc.patient_pin_search(:pin => @@er_pin)
#########    slmc.go_to_gu_page_for_a_given_pin("Checklist Order", @@er_pin)
#########    @@item_code = slmc.search_service(:procedure => true, :description => "POWER BONE SHAVING")
#########    slmc.add_returned_service(:item_code => @@item_code, :description => "POWER BONE SHAVING")
#########    @@item_code2 = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
#########    slmc.add_returned_service(:item_code => @@item_code2, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
#########    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
#########    slmc.validate_orders(:orders => "multiple", :procedures => true)
#########    slmc.confirm_validation_all_items.should be_true
#########  end
#########
#########   it "(6th nsd scenario) Clinically discharge patient" do
#########    slmc.login(@er_user, @password).should be_true
#########    slmc.go_to_er_landing_page
#########    slmc.patient_pin_search(:pin => @@er_pin)
#########    @@room_and_bed = slmc.er_get_room_and_bed_no_in_gu_page
#########    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
#########  end
#########
#########  it "(6th nsd scenario) Add and edit patient record" do
#########    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days1, :pin => @@er_pin, :visit_no => @@visit_no)
#########    Database.connect
#########    @days1.times do |i|
#########      @rb = (slmc.get_last_record_of_rb_trans_no)
#########      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no, :rb_trans_no => @rb, :created_by => @er_user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount1, :created_datetime => @my_date)
#########      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @er_room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @er_user)
#########      @my_date = slmc.increase_date_by_one(@days1 - i)
#########    end
#########    Database.logoff
#########  end
#########
#########  it "(6th nsd scenario) Computes philhealth" do
#########    slmc.go_to_er_billing_page
#########    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin)
#########    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
#########    @@er_ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "SUPER CATASTROPHIC CASE", :with_operation => true, :rvu_code => "59401", :compute => true)
#########  end
#########
#########  it "(6th nsd scenario) Check Benefit Summary totals" do
#########    @@comp_drugs = 0
#########    @@non_comp_drugs = 0
#########    @@comp_xray_lab = 0
#########    @@non_comp_xray_lab = 0
#########    @@comp_operation = 0
#########    @@non_comp_operation = 0
#########
#########    @@er_orders =  @drugs.merge(@ancillary).merge(@operation)
#########    @@er_orders.each do |order,n|
#########      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#########      if item[:ph_code] == "PHS01"
#########        amt = item[:rate].to_f * n
#########        @@comp_drugs += amt  # total compensable drug
#########      end
#########      if item[:ph_code] == "PHS06"
#########        n_amt = item[:rate].to_f * n
#########        @@non_comp_drugs += n_amt # total non-compensable drug
#########      end
#########      if item[:ph_code] == "PHS02"
#########        x_lab_amt = item[:rate].to_f * n
#########        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
#########      end
#########      if item[:ph_code] == "PHS07"
#########        n_x_lab_amt = item[:rate].to_f * n
#########        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
#########      end
#########      if item[:ph_code] == "PHS03"
#########        o_amt = item[:rate].to_f * n
#########        @@comp_operation += o_amt  # total compensable operations
#########      end
#########      if item[:ph_code] == "PHS08"
#########        n_o_amt = item[:rate].to_f * n
#########        @@non_comp_operation += n_o_amt # total non compensable operations
#########      end
#########    end
#########  end
#########
#########   it "(6th nsd scenario) Checks if the actual charge for drugs/medicine is correct" do
#########    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
#########    total_drugs = @@comp_drugs + @@non_comp_drugs
#########    @@actual_medicine_charges = total_drugs - (@@patient_promo_discount * total_drugs)
#########    @@er_ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
#########  end
#########
#########  it "(6th nsd scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
#########    @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@patient_promo_discount)
#########      if @@med_ph_benefit[:max_amt].to_f < 0
#########       @@actual_medicine_benefit_claim = 0.00
#########      elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
#########        @@actual_medicine_benefit_claim  = @@actual_comp_drugs
#########      else
#########       @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
#########      end
#########      @@er_ph[:er_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
#########  end
#########
#########  it "(6th nsd scenario) Checks if the actual charge for xrays, lab and others is correct" do
#########    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
#########    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@patient_promo_discount)
#########    @@er_ph[:er_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
#########  end
#########
#########  it "(6th nsd scenario) Checks if the actual lab benefit claim is correct" do
#########    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@patient_promo_discount * @@comp_xray_lab)
#########    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
#########      if @@lab_ph_benefit[:max_amt].to_f < 0
#########        @@actual_lab_benefit_claim = 0.00
#########      elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
#########        @@actual_lab_benefit_claim = @@actual_comp_xray_lab_others
#########      else
#########        @@actual_lab_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
#########      end
#########      @@er_ph[:er_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim))
#########  end
#########
######### it "(6th nsd scenario) Checks if the actual charge for operation is correct" do
#########    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@patient_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@patient_promo_discount))
#########    @@er_ph[:er_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
#########  end
#########
#########  it "(6th nsd scenario) Checks if the actual operation benefit claim is correct" do
#########    @@actual_operation_benefit_claim = 1200.0
#########    @@er_ph[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
#########  end
#########
#########  it "(6th nsd scenario) Checks if the total actual charge(s) is correct" do
#########    @@rate = @er_room_rate - (@er_room_rate * @@patient_promo_discount)
#########    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate
#########    @@er_ph[:er_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
#########  end
#########
#########  it "(6th nsd scenario) Checks if the total actual benefit claim is correct" do
#########    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
#########    @@er_ph[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
#########  end
#########
#########  it "(6th nsd scenario) Checks if the maximum benefits are correct" do
#########    @@er_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
#########    @@er_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
#########  end
#########
#########  it "(6th nsd scenario) Checks if Deduction Claims are correct" do
#########    @@er_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
#########    @@er_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
#########    @@er_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
#########  end
#########
#########  it "(6th nsd scenario) Checks if Remaining Benefit Claims are correct" do
#########     if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
#########        @@drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim
#########      else
#########        @@drugs_remaining_benefit_claim = 0.0
#########      end
#########      @@er_ph[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim))
#########
#########      if @@actual_lab_benefit_claim < @@lab_ph_benefit[:max_amt].to_f
#########        @@lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim
#########      else
#########        @@lab_remaining_benefit_claim = 0
#########      end
#########      @@er_ph[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim))
#########  end
#########
#########  it "(6th nsd scenario) Checks if computation of PF claims attending physician is applied correctly" do
#########    @@er_ph[:surgeon_benefit_claim].should == ("%0.2f" %(0.0))
#########  end
#########
#########  it "(6th nsd scenario) Checks if computation of PF claims surgeon is applied correctly" do
#########    @@er_ph[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(0.0))
#########  end
#########
#########  it "(6th nsd scenario) Save PhilHealth" do
#########      slmc.ph_save_computation
#########  end
#########
#########  it "(6th nsd scenario) Checks Claim History" do
#########    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
#########  end
#########
#########  it "(6th nsd scenario) View Details of the ordered items" do
#########    slmc.ph_view_details(:close => true).should == 8
#########  end
#########
#########  it "(6th nsd scenario) Prints PhilHealth Form and Prooflist" do
#########    slmc.ph_print_report.should be_true
#########  end
#########
#########   it "(6th nsd scenario) Discharges the patient" do
#########    slmc.go_to_er_billing_page
#########    slmc.patient_pin_search(:pin => @@er_pin)
#########    slmc.go_to_er_page_for_a_given_pin("Discharge Patient", slmc.visit_number)
#########    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#########    if slmc.is_text_present"Nothing found to display."
#########        slmc.click_new_guarantor
#########        slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL")
#########     end
#########    slmc.discharge_to_payment
#########  end
#########
#########  it "(6th nsd scenario) Print gatepass" do
#########      slmc.go_to_er_landing_page
#########      slmc.patient_pin_search(:pin => @@er_pin)
#########      slmc.click'css=#occupancyList>tbody>tr.even>td:nth-child(9)>input'
#########  end

   it "(7th nsd scenario) DR, Claim Type: Accounts Receivable/Refund, Case Type: Ordinary Case" do
    slmc.login(@dr_user,@password).should be_true
    @@dr_pin = slmc.or_nb_create_patient_record(@dr_patient.merge(:admit => true, :gender => 'F', :org_code => "0170")).gsub(' ', '')
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
    slmc.verify_ordered_items_count(:drugs => 4).should be_true
    slmc.verify_ordered_items_count(:ancillary => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0170_validator")
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items
  end
   it "(7th nsd scenario) Order procedure items" do
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
   it "(7th nsd scenario) Clinically discharge patient" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    sleep 6
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end
   it "(7th nsd scenario) Add and edit patient record" do
    @my_date =  slmc.adjust_admission_date(:days_to_adjust => @days1, :pin => @@dr_pin, :visit_no => @@visit_no)
    Database.connect
    @days1.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @er_room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @dr_user)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no, :rb_trans_no => @rb, :created_by => @dr_user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount1, :created_datetime => @my_date)
      @my_date = slmc.increase_date_by_one(@days1 - i)
    end
    Database.logoff
  end
   it "(7th nsd scenario) Should be able to search patient on pba" do
    slmc.login(@pba_user,@password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@dr_pin)
    slmc.click_latest_philhealth_link_for_outpatient
  end
   it "(7th nsd scenario) Enable Philhealth Information" do
     @@dr_ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "59400", :compute => true)
  end
   it "(7th nsd scenario) Check Benefit Summary totals" do
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
   it "(7th nsd scenario) Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@@patient_promo_discount * total_drugs)
    @@dr_ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end
   it "(7th nsd scenario) Checks if the actual benefit claim for drugs/medicine is correct" do
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
   it "(7th nsd scenario) Checks if the actual charge for xrays, lab and others is correct" do
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@patient_promo_discount)
    @@dr_ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end
   it "(7th nsd scenario) Checks if the actual lab benefit claim is correct" do
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
   it "(7th nsd scenario) Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@patient_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@patient_promo_discount))
    @@dr_ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end
   it "(7th nsd scenario) Checks if the actual operation benefit claim is correct" do
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
    @@actual_operation_benefit_claim = 1200.0
    @@dr_ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
  end
   it "(7th nsd scenario) Checks if the total actual charge(s) is correct" do
    @@rate = @er_room_rate - (@er_room_rate * @@patient_promo_discount)
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate
    @@dr_ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end
   it "(7th nsd scenario) Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
    @@dr_ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end
   it "(7th nsd scenario) Checks if the maximum benefits are correct" do
    @@dr_ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@dr_ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end
   it "(7th nsd scenario) Checks if Deduction Claims are correct" do
    @@dr_ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    @@dr_ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    @@dr_ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
  end
   it "(7th nsd scenario) Checks if Remaining Benefit Claims are correct" do
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
   it "(7th nsd scenario) Checks if computation of PF claims surgeon is applied correctly" do
    @@dr_ph[:inpatient_surgeon_benefit_claim].should == ("%0.2f" %(0.0))
  end
   it "(7th nsd scenario) Checks if computation of PF claims attending physician is applied correctly" do
    @@dr_ph[:surgeon_benefit_claim].should == ("%0.2f" %(0.0))
  end
   it "(7th nsd scenario) Save PhilHealth" do
    slmc.ph_save_computation
  end
   it "(7th nsd scenario) Checks Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end
   it "(7th nsd scenario) View Details of the ordered items" do
    slmc.ph_view_details(:close => true).should == 8
  end
   it "(7th nsd scenario) Prints PhilHealth Form and Prooflist" do
    slmc.ph_print_report.should be_true
  end
end
