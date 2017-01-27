require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Philhealth Ordinary Case Module Test - First Availment" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @ph_patient = Admission.generate_data
    @ph_patient2 = Admission.generate_data
#    @user = 'philhealth_spec_user'
    @user = 'gu_spec_user8'
    @oss_user = 'dastech1'
    @password = "123qweuser"
    @promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@ph_patient[:age])
    @drugs = {
      "042090007" => 1, #ZOVIRAX CREAM 2g --
      "040803115" => 1, #FLAGYL RECTAL SUPP 1g
      "040812131" => 4, #ORIMED 80mg/2mL AMP
      "040821106" => 1, #STANCEF 1G VIAL
      "040821209" => 2, #ULTRAXIME 100mg/5mL SUSPENSION 30mL
      "040850614" => 3, #AMPICIN 500mg VIAL
      "042480015" => 4, #VITAKAY 10MG TAB
      "040010015" => 5  #JMS G-23 SCALP VEIN NEEDLE
    }

    @ancillary = {"010000011" => 1, "010000017" => 1, "010000022" => 1}    
    @supplies = {"085100003" => 5, "089100004" => 5, "080100021" => 20, "080100023" => 3}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates patient for pba transactions" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@ph_pin = slmc.create_new_patient(@ph_patient.merge(:gender => 'M'))
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test")

    slmc.admission_search(:pin => @@ph_pin).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0287', :diagnosis => "ULCER").should == "Patient admission details successfully saved."
  end

######  it "Test if input field for Search accepts either description or item code" do
######    slmc.go_to_general_units_page
######    slmc.patient_pin_search(:pin => @@ph_pin)
######    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@ph_pin)
######    slmc.search_order(:drugs => true, :description =>  "040004334").should be_true
######    slmc.search_order(:supplies => true, :description => "080200000").should be_true
######    slmc.search_order(:ancillary => true, :description => "010000003").should be_true
######    slmc.search_order(:others => true, :description => "050000009").should be_true
######    slmc.search_order(:drugs => true, :description => "SOLUSET").should be_true
######    slmc.search_order(:supplie    s => true, :description => "NASO-TRACHEAL TUBE IVORY S7").should be_true
######    slmc.search_order(:ancillary => true, :description => "BONE IMAGING - THREE PHASE STUDY").should be_true
######    slmc.search_order(:others => true, :description => "BLOOD WARMER - SUCCEDING HOUR").should be_true
######  end

  it "Searches and adds drugs in the nursing general units order page" do
    slmc.nursing_gu_search(:pin => @@ph_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@ph_pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator").should be_true
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 8
    slmc.confirm_validation_all_items.should be_true
  end

  it "Searches and adds ancillary in the nursing general units order page" do
    slmc.nursing_gu_search(:pin => @@ph_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@ph_pin)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true).should be_true
    end
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "Searches and adds supplies in the nursing general units order page" do
    slmc.nursing_gu_search(:pin => @@ph_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@ph_pin)
    @supplies.each do |item, q|
      slmc.search_order(:supplies => true, :description => item).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :quantity => q,
         :stock_replacement => true, :add => true).should be_true
    end
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:supplies => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true

    # add all orders
    @@orders = @ancillary.merge(@supplies).merge(@drugs)

    # set to 0 to initialize variables
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@non_comp_supplies = 0
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

  it "Standard clinical discharges the patient" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@ph_pin, :no_pending_order => true, :pf_amount => "10000", :save => true).should be_true
  end

  it "Goes through the philhealth computation page" do
    slmc.login("sel_pba5", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@ph_pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "GLAUCOMA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
  end

  it "Checks if the actual charge for drugs/medicine is correct"   do
    # actual medical charges computation
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@promo_discount * total_drugs)
    @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))  # example: 5,035.80
  end

  it "Checks if the actual benefit claim for drugs/medicine is correct" do
    # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB02")
    if @@comp_drugs < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim = @@comp_drugs
    else
      @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
  end

  it "Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
    @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Checks if the actual lab benefit claim is correct" do
    # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB03")
    if @@comp_xray_lab < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim = @@comp_xray_lab
    else
      @@actual_lab_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
    end
    @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim))
  end

  it "Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others
    ((slmc.truncate_to((@@ph[:total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.02
  end

  it "Checks if the total actual benefit claim is correct" do
    total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim
    @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(total_actual_benefit_claim))
  end

  it "Checks if the maximum benefits are correct" do
    or_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB04")
    rb_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB01")
    @@ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    @@ph[:max_benefit_operation].should == ("%0.2f" %(or_ph_benefit[:max_amt]))
    @@ph[:max_benefit_rb].should == rb_ph_benefit[:max_days]
    @@ph[:max_benefit_rb_amt_per_day].should == ("%0.2f" %(rb_ph_benefit[:daily_amt]))
    @@ph[:max_benefit_rb_total_amt].should == ("%0.2f" %(rb_ph_benefit[:max_amt]))
  end

  it "Saves the estimated philhealth computation" do
    @@ph_ref_num = slmc.ph_save_computation
    @@ph_ref_num.should be_an_instance_of(String)
  end

  it "Bug #23941 PhilHealth * Error in page Document Search - Display Details" do
    slmc.pba_adjustment_and_cancellation(:doc_type => "PHILHEALTH", :search_option => "DOCUMENT NUMBER", :entry => @@ph_ref_num).should be_true
    slmc.go_to_page_using_reference_number("Display Details", @@ph_ref_num)
    sleep 5
    slmc.is_text_present("Patient Billing and Accounting Home").should be_true
    slmc.get_text("//html/body/div/div[2]/div[2]/div[16]/h2").should == "ESTIMATE"
    slmc.get_selected_label("claimType").should == "REFUND"
  end

  it "Bug #23812 PhilHealth * Encountered java.lang.NullPointerException in computing PhilHealth" do
    slmc.login("sel_pba5", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.patient_pin_search(:pin => @@ph_pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    slmc.philhealth_computation(:edit => true, :diagnosis => "ONCHOCERCIASIS WITH GLAUCOMA", :claim_type => "REFUND", :medical_case_type => "ORDINARY CASE", :with_operation => true, :compute => true)
    slmc.ph_save_computation
    slmc.ph_edit(:diagnosis => "HEPATOBLASTOMA")
    slmc.philhealth_computation(:diagnosis => "TYPHOID MENINGITIS", :claim_type => "ACCOUNTS RECEIVABLE", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.is_text_present("Patient Billing and Accounting Home \342\200\272 PhilHealth").should be_true
    slmc.get_selected_label("claimType").should == "ACCOUNTS RECEIVABLE"
  end

  it "Bug #24254 PhilHealth * Claim Type becomes Refund after saving computed PhilHealth as Accounts Receivable" do
    slmc.ph_save_computation
    slmc.get_selected_label("claimType").should == "ACCOUNTS RECEIVABLE"
  end

  # R/B has the value "1" if 2nd availment
  it "OSS : Philhealth RB Availment Deduction for Outpatient" do
    slmc.login(@oss_user, @password)
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = (slmc.oss_outpatient_registration(@ph_patient2)).gsub(' ','').should be_true
    slmc.login(@oss_user, @password)
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true

    @oss_drugs = {"042422511" => 20}
    @oss_ancillary = {"010000004" => 1}
    @oss_operation = {"010000160" => 1}
    @oss_doctors = ["6726","0126","6726","0126"]

    @@orders = @oss_ancillary.merge(@oss_operation).merge(@oss_drugs)
    n = 0
    @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @oss_doctors[n])
      n += 1
    end

    slmc.oss_add_guarantor(:guarantor_type => "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@oss_ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "GLAUCOMA", :philhealth_id => "12345", :rvu_code => "10060", :compute => true)

    @@oss_ph[:actual_rb_availed_charges].should == "N/A"
    @@oss_ph[:actual_rb_availed_benefit_claim].should == "1"
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."

    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "OSS : Verifies Database Info" do
    @@visit_number = slmc.get_visit_number_using_pin(@@oss_pin)
    rb_availed = slmc.access_from_database(:what => "TOTAL_DAYS_AVAILED_RB", :table => "TXN_PBA_PH_HISTORY", :column1 => "VISIT_NO", :condition1 => @@visit_number)
    rb_availed.should == 1.0
  end

  it "Verifies RB Availment should be deducted" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@oss_pin)
    slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0287', :diagnosis => "ULCER").should == "Patient admission details successfully saved."

    @drugs = {"042480015" => 1}
    slmc.nursing_gu_search(:pin => @@oss_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@oss_pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator").should be_true
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_general_units_page
    @@visit_no3 = slmc.clinically_discharge_patient(:pin => @@oss_pin, :no_pending_order => true, :pf_amount => "10000", :save => true).should be_true

    slmc.login("sel_pba5", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@oss_pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    # new feature - to be scripted - The patient has filed case rate  with Final Diagnosis H40 last Wed Feb 22 2012.  Can not apply for Philhealth with same diagnosis and Case Rate within 90 days."
    @@ph3 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "GLAUCOMA",
    :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    @@ph3 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    @@ph3[:room_and_board_remaining].should == "43"
    @@ph3[:deduction_from_previous_confinements_consumed].should == "1"
  end

  it "Bug #29302 - [DON] Dismissing the clinical alerts notification, returns an error message" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.is_visible("ui-dialog-title-divUnifiedAlerts").should be_true
    slmc.click("//a[@title='Clinical Orders']")
    sleep 3
    slmc.click("btnClinicalOrderDismissAll")
    sleep 3
    slmc.get_text("//div[@id='divClinicalOrderAlertNoItemMsge']/span").should == "No rejected/validated item."
  end
end