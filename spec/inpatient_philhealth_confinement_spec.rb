require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  

#require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

################################################################################################################################
######################## Should Run before 11am, due to rb trans########################################################################
################################################################################################################################

describe "SLMC :: Inpatient - Philhealth Confinement within 24 Hours" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @user = "gu_spec_user3"

    if CONFIG['db_sid'] == "QAFUNC"
            @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
            #@pba_user = "ldcastro" #"sel_pba7"
            @pba_user = "pba1" #"sel_pba7"
            @or_user =  "slaquino"     #"or21"
            @oss_user = "jtsalang"  #"sel_oss7"
            @dr_user = "jpnabong" #"sel_dr4"
            @er_user =  "jtabesamis"   #"sel_er4"
            @wellness_user = "ragarcia-wellness" # "sel_wellness2"
            @gu_user_0287 = "gycapalungan"
            @pharmacy_user =  "cmrongavilla"
    else
            @user = "fcdeleon"  #"billing_spec_user3"  #admission_login#
            @pba_user = "dmgcaubang" #"sel_pba7"
            @or_user =  "amlompad"     #"or21"
            @oss_user = "kjcgangano-pet"  #"sel_oss7"
            @dr_user = "aealmonte" #"sel_dr4"
            @er_user =  "asbaltazar"   #"sel_er4"
            @wellness_user = "emllacson-wellness" # "sel_wellness2"
            @gu_user_0287 = "ajpsolomon"
    end
    
    
    

    @@room_rate = 4167.0

    @patient2 = Admission.generate_data
    @patient3 = Admission.generate_data
    @patient4 = Admission.generate_data

    @drugs =  {"040004334" => 1}#,"044006788" => 1}
    @ancillary = {"010000003" => 1}
    @supplies = {"080200000" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Claim Type: Accounts Receivable With Operation: No - Create and Admit Patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin = slmc.create_new_patient(Admission.generate_data)
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "3325").should == "Patient admission details successfully saved."
  end

  it "Claim Type: Accounts Receivable With Operation: No - Order and Validate items" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true)
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "5979")

    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true)
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126")
    end
    @supplies.each do |item, q|
      slmc.search_order(:description => item, :supplies => true)
      slmc.add_returned_order(:supplies => true, :description => item, :add => true)
    end
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :supplies => true, :ancillary => true, :orders => "multiple").should == 3
    sleep 3
    slmc.confirm_validation_all_items.should be_true

  end

  it "Claim Type: Accounts Receivable With Operation: No - Clinically Discharge" do
    #slmc.nursing_gu_search(:pin => @@pin).should be_true
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
    #slmc.clinically_discharge_patient(:pin => @@pin, :pf_type => "COLLECT", :no_pending_order => true, :pf_amount => '1000', :type => "standard", :save => true).should be_true
  end

  it "Claim Type: Accounts Receivable With Operation: No - Professional fee settlement" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
  end

  it "Claim Type: Accounts Receivable With Operation: No - Discharge up to PhilHealth Page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    puts @@pin
  end

  it "Claim Type: Accounts Receivable With Operation: No - Compute PhilHealth : Should not accept computation for less than 24 hours" do
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :case_rate_type => "MEDICAL", :group_name => "DENGUE FEVER", :diagnosis => "CHOLERA",:case_rate => "A90" , :compute => true)
    slmc.get_text("errorMessages").should == 'For less than 24 hours confinement and without operation, only "Refund" claim type is accepted.'
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Create and admit patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin2 = slmc.create_new_patient(@patient2)#.gsub(' ', '')
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient2[:age])
    sleep 6
     #       slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin2).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "3325").should == "Patient admission details successfully saved."
  end
  
  it "Claim Type: Accounts Receivable With Operation: Yes - Order and Validate items" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin2).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin2)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true)
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "5979")
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true)
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126")
    end
    @supplies.each do |item, q|
      slmc.search_order(:description => item, :supplies => true)
      slmc.add_returned_order(:supplies => true, :description => item, :add => true)
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :orders => "single")
    slmc.confirm_validation_some_items.should be_true
    slmc.validate_orders(:ancillary => true, :supplies => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Clinically Discharge" do
    slmc.nursing_gu_search(:pin => @@pin2).should be_true
    slmc.clinically_discharge_patient(:pin => @@pin2, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Professional fee settlement" do
    sleep 4
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.patient_pin_search(:pin => @@pin2)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Discharge up to PhilHealth Page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Compute PhilHealth" do
    @@ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
    slmc.get_text("successMessages").should == "The PhilHealth form is saved successfully."
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Check Benefit Summary totals" do
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

    @@orders = @ancillary.merge(@supplies).merge(@drugs)
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

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount)
    @@ph2[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if the actual benefit claim for drugs/medicine is correct" do
     @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
     if @@med_ph_benefit[:max_amt].to_f < 0
       @@actual_medicine_benefit_claim2 = 0.00
     elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim2 = @@actual_comp_drugs
     else
       @@actual_medicine_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f
     end
    @@ph2[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph2[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if the actual lab benefit claim is correct" do
#    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
#    if @@lab_ph_benefit[:max_amt].to_f < 0
#      @@actual_lab_benefit_claim2 = 0.00
#    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
#      @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
#    else
#      @@actual_lab_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f
#    end
    @@actual_lab_benefit_claim2 = 0.00
    @@ph2[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph2[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if the actual operation benefit claim is correct" do
#    if slmc.get_value("rvu.code").empty? == false
#      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
#      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
#        @@actual_operation_benefit_claim2 = @@actual_operation_charges
#      else
#        @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:max_amt].to_f
#      end
#      @@ph2[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
#    else
      @@actual_operation_benefit_claim2 = 0.00
      @@ph2[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
#    end
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if the total actual charge(s) is correct" do
    #@@rate = @@room_rate - (@@room_rate * @@promo_discount) # 4167 is regular_private      No room rate 1 day only and it's not discharge yet
  #  @@rate = 0.00
    @@rate = (4167.00 - (4167.00 * 0.16))
    ## no rooom rate if 1 day
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges +  @@rate
    @@ph2[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if the total actual benefit claim is correct" do
     @@total_actual_benefit_claim = 2800.00
  #  @@total_actual_benefit_claim = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2
    @@ph2[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if the maximum benefits are correct" do
    @@ph2[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph2[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if Remaining Benefit Claims are correct" do
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

  it "Claim Type: Accounts Receivable With Operation: Yes - Checks if Deduction Claims are correct" do
    @@ph2[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
    @@ph2[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    @@ph2[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "Claim Type: Accounts Receivable With Operation: Yes - PhilHealth can only be edited when saved as ESTIMATE" do
  #  slmc.get_text("//html/body/div/div[2]/div[2]/div[17]/h2").should == "FINAL"
    slmc.is_text_present("FINAL").should be_true
    sleep 5
    slmc.is_editable("btnEdit").should be_false
  end

  it "Claim Type: Refund With Operation: Yes - Create and admit patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin3 = slmc.create_new_patient(@patient3)
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient3[:age])
    sleep 6
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin3).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "3325").should == "Patient admission details successfully saved."
  end

  it "Claim Type: Refund With Operation: Yes - Order and Validate items" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin3).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin3)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true)
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "5979")
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true)
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126")
    end
    @supplies.each do |item, q|
      slmc.search_order(:description => item, :supplies => true)
      slmc.add_returned_order(:supplies => true, :description => item, :add => true)
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :orders => "single")
    slmc.confirm_validation_some_items.should be_true
    slmc.validate_orders(:ancillary => true, :supplies => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Claim Type: Refund With Operation: Yes - Clinically Discharge" do
    slmc.nursing_gu_search(:pin => @@pin3).should be_true
    slmc.clinically_discharge_patient(:pin => @@pin3, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
  end

  it "Claim Type: Refund With Operation: Yes - Professional fee settlement" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.patient_pin_search(:pin => @@pin3)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
  end

  it "Claim Type: Refund With Operation: Yes - Discharge up to PhilHealth Page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin3)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
  end

  it "Claim Type: Refund With Operation: Yes - Compute PhilHealth" do
    @@ph3 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
    slmc.get_text("successMessages").should == "The PhilHealth form is saved successfully."
  end

  it "Claim Type: Refund With Operation: Yes - Check Benefit Summary totals" do
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

    @@orders = @ancillary.merge(@supplies).merge(@drugs)
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

  it "Claim Type: Refund With Operation: Yes - Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount)
    @@ph3[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Claim Type: Refund With Operation: Yes - Checks if the actual benefit claim for drugs/medicine is correct" do
     @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
     if @@med_ph_benefit[:max_amt].to_f < 0
       @@actual_medicine_benefit_claim3 = 0.00
     elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim3 = @@actual_comp_drugs
     else
       @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f
     end
    @@ph3[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
  end

  it "Claim Type: Refund With Operation: Yes - Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph3[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Claim Type: Refund With Operation: Yes - Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others <= 0
      @@actual_lab_benefit_claim3 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph3[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
  end

  it "Claim Type: Refund With Operation: Yes - Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph3[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Claim Type: Refund With Operation: Yes - Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim3 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph3[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
    else
      @@actual_operation_benefit_claim3 = 0.00
      @@ph3[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
    end
  end

  it "Claim Type: Refund With Operation: Yes - Checks if the total actual charge(s) is correct" do
    #@@rate = @@room_rate - (@@room_rate * @@promo_discount) # 4167 is regular_private
    @@rate = 0.00 #no  room rate if 1 day
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate # ROOM AND BOARD
    @@ph3[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Claim Type: Refund With Operation: Yes - Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3
    @@ph3[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Claim Type: Refund With Operation: Yes - Checks if the maximum benefits are correct" do
    @@ph3[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph3[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Claim Type: Refund With Operation: Yes - Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim3 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3
    else
      @@drugs_remaining_benefit_claim3 = 0.0
    end
    @@ph3[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim3))

    if @@actual_lab_benefit_claim3 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3
    else
      @@lab_remaining_benefit_claim3 = 0.0
    end
    @@ph3[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim3))
  end

  it "Claim Type: Refund With Operation: Yes - Checks if Deduction Claims are correct" do
    @@ph3[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
    @@ph3[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
    @@ph3[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
  end

  it "Claim Type: Refund With Operation: Yes - PhilHealth can only be edited when saved as ESTIMATE" do
#    slmc.get_text("//html/body/div/div[2]/div[2]/div[17]").should == "ESTIMATE"
        slmc.is_text_present("ESTIMATE").should be_true

    slmc.is_editable("btnEdit").should be_true
  end

  it "Claim Type: Refund With Operation: Yes - PhilHealth benefit claim shall reflect in Payment details only saved as Final" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin3)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    slmc.get_philhealth_amount.should_not == @@ph3[:total_actual_benefit_claim].to_i #should not be equal since PH is saved as ESTIMATE
  end

  it "Claim Type: Refund With Operation: No - Create and admit patient" do
    sleep 6
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin4 = slmc.create_new_patient(@patient4)
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient4[:age])
    sleep 6
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin4).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "3325").should == "Patient admission details successfully saved."
  end

  it "Claim Type: Refund With Operation: No - Order and Validate items" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin4)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin4)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true)
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "5979")
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true)
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126")
    end
    @supplies.each do |item, q|
      slmc.search_order(:description => item, :supplies => true)
      slmc.add_returned_order(:supplies => true, :description => item, :add => true)
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :orders => "single").should == 1
    slmc.confirm_validation_some_items.should be_true
    slmc.validate_orders(:ancillary => true, :supplies => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end

  it "Claim Type: Refund With Operation: No - Clinically Discharge" do
    slmc.nursing_gu_search(:pin => @@pin4)
    slmc.clinically_discharge_patient(:pin => @@pin4, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
  end

  it "Claim Type: Refund With Operation: No - Professional fee settlement" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.patient_pin_search(:pin => @@pin4)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
  end

  it "Claim Type: Refund With Operation: No - Discharge up to PhilHealth Page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin4)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
  end

  it "Claim Type: Refund With Operation: No - Compute PhilHealth" do
    @@ph4 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true, :with_operation => true, :rvu_code => "10060")
    slmc.ph_save_computation
    slmc.get_text("successMessages").should == "The PhilHealth form is saved successfully."
  end

  it "Claim Type: Refund With Operation: No - Check Benefit Summary totals" do
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

    @@orders = @ancillary.merge(@supplies).merge(@drugs)
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

  it "Claim Type: Refund With Operation: No - Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (total_drugs * @@promo_discount)
    @@ph4[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Claim Type: Refund With Operation: No - Checks if the actual benefit claim for drugs/medicine is correct" do
     @@actual_comp_drugs = @@comp_drugs - (@@comp_drugs * @@promo_discount)
     if @@med_ph_benefit[:max_amt].to_f < 0
       @@actual_medicine_benefit_claim4 = 0.00
     elsif @@actual_comp_drugs < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim4 = @@actual_comp_drugs
     else
       @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f
     end
    @@ph4[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
  end

  it "Claim Type: Refund With Operation: No - Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount * total_xrays_lab_others)
    @@ph4[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Claim Type: Refund With Operation: No - Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others <= 0
      @@actual_lab_benefit_claim4 = 0.00
    elsif @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph4[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
  end

  it "Claim Type: Refund With Operation: No - Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @@promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @@promo_discount))
    @@ph4[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Claim Type: Refund With Operation: No - Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim4 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim4 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph4[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
    else
      @@actual_operation_benefit_claim4 = 0.00
      @@ph4[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
    end
  end

  it "Claim Type: Refund With Operation: No - Checks if the total actual charge(s) is correct" do
    @@rate = @@room_rate - (@@room_rate * @@promo_discount) # 4167 is regular_private
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges + @@rate # ROOM AND BOARD
    @@ph4[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Claim Type: Refund With Operation: No - Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4 + @@actual_operation_benefit_claim4
    @@ph4[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Claim Type: Refund With Operation: No - Checks if the maximum benefits are correct" do
    @@ph4[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph4[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Claim Type: Refund With Operation: No - Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim4
    else
      @@drugs_remaining_benefit_claim4 = 0.0
    end
    @@ph4[:drugs_remaining_benefit_claims].should == ("%0.2f" %(@@drugs_remaining_benefit_claim4))

    if @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim4
    else
      @@lab_remaining_benefit_claim4 = 0.0
    end
    @@ph4[:lab_remaining_benefit_claims].should == ("%0.2f" %(@@lab_remaining_benefit_claim4))
  end

  it "Claim Type: Refund With Operation: No - Checks if Deduction Claims are correct" do
    @@ph4[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    @@ph4[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    @@ph4[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end

  it "Claim Type: Refund With Operation: No - PhilHealth can only be edited when saved as ESTIMATE" do
    slmc.get_text("//html/body/div/div[2]/div[2]/div[19]/h2").should == "ESTIMATE"
    slmc.is_editable("btnEdit").should be_true
  end

  it "Claim Type: Refund With Operation: No - PhilHealth benefit claim shall reflect in Payment details only saved as Final" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin4)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    slmc.get_philhealth_amount.should_not == @@ph4[:total_actual_benefit_claim].to_i #should not be equal since PH is saved as ESTIMATE
  end

end