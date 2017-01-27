#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
require 'spec_helper'

describe "SLMC :: Regression of Issues for PhilHealth" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @user = "billing_spec_user2"
    @er_user =  "jtabesamis"   #"sel_er4"
    @dr_user = "jpnabong" #"sel_dr4"
    @or_user =  "slaquino"     #"or21"


    @pba_user = "sel_pba1"
    @password = "123qweuser"

    @dr_patient = Admission.generate_data
    @er_patient = Admission.generate_data
    @er_patient2 = Admission.generate_data
    @ph_patient = Admission.generate_data
    @or_patient = Admission.generate_data

    @pt_promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@ph_patient[:age])

    @ancillary = {"010000868" => 1}
    @others = {"060001731" => 1, "060001946" => 1, "060001796" => 1}

    @drugs1 =  {"042090007" => 1, "041840008" => 1, "049000028" => 1, "040950558" => 1}
    @ancillary1 = {"010000317" => 1, "010000212" => 1, "010001039" => 1, "010000211" => 1}
    @supplies1 = {"085100003" => 1, "080100023" => 1}
    @operation1 = {"060000058" => 1, "060000003" => 1}

    @or_drugs = {"040800031" => 1}
    @or_ancillary = {"010000003" => 1}
    @or_supplies = {"080100021" => 1}

    @or_drugs2 = {"048839005" => 1}

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Bug #40494 - Contact ID : Philhealth" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    slmc.click Locators::Admission.create_new_patient, :wait_for => :page
    slmc.populate_patient_info(Admission.generate_data)

    id_type1 =  "PHILHEALTH CARD"
    slmc.select "id=idType[0]", "label=#{id_type1}"
    slmc.type "patientIds0.idNo", "12345"
    slmc.select "id=idType[1]", "label=#{id_type1}"
    slmc.type "patientIds1.idNo", "7654321"


    sleep 3
    slmc.click("//input[@type='button' and @value='Preview']")
    sleep 3
    slmc.click "xpath=(//input[@name='action'])[3]" if slmc.is_element_present("xpath=(//input[@name='action'])[3]")
    slmc.click "xpath=(//button[@type='button'])[3]" if slmc.is_element_present("xpath=(//button[@type='button'])[3]")


    sleep 3
    slmc.get_text("patient.errors").should == "There are duplicate Ids in ID Card Presented Field."
  end
  it "Bug #40669 Philhealth Employer Number (limit to 12 characters)" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(Admission.generate_data)
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
    slmc.go_to_general_units_page
    sleep 10
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
    slmc.type "memberInfo.employerMembershipID", "12345678901234567"
    slmc.get_value("memberInfo.employerMembershipID").should == "123456789012"
  end
###### NO ER PHILHEALTH
  it "Bug #40163 - [PH] SPU-ER: Unable to compute patients philhealth claim, as nothing happens after hitting the Compute button" do
    slmc.login(@er_user, @password).should be_true
    @@er_pin = slmc.er_create_patient_record(@er_patient.merge!(:admit => true, :gender => 'F', :birth_day => Date.today.strftime("%m/%d/%Y"), :rch_code => 'RCHSP', :org_code => '0173'))
    slmc.login(@er_user, @password).should be_true
    slmc.er_clinical_order_patient_search(:pin => @@er_pin)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @others.each do |item, q|
      slmc.search_order(:description => item, :others => true).should be_true
      slmc.add_returned_order(:others => true, :description => item, :stat => true,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:others => 3).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :others => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items#.should be_true

    slmc.go_to_er_page
    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :diagnosis => "SINGLE, BORN IN HOSPITAL", :pf_amount => "1000", :save => true) #Z38.0 SINGLE, BORN IN HOSPITAL

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@er_pin)
    slmc.click_philhealth_link

    @@ph = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "Z38.0", :compute => true,:rvu_code => "11444" )

    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@non_comp_others = 0

    @@orders =  (@ancillary).merge(@others)
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

    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * 0.16)
    @@ph[:er_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))

#    @@actual_comp_xray_lab_others = @@comp_xray_lab - (0.16 * @@comp_xray_lab)
#    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
#    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
#      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
#    else
#      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
#    end
#    @@actual_lab_benefit_claim1 = 0.00
#    @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    @@total_benefit_claim1 = 4108 - 1008
    @@ph[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_benefit_claim1))
  end
  it "Bug #40151 - [PH] SPU-DR: Exception error thrown after hitting PH Compute button" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    sleep 10
    slmc.pba_pin_search(:pin => @@er_pin)
    sleep 10    
    slmc.click_philhealth_link(:pin => @@er_pin, :visit_no => @@visit_no)
    #@@ph2 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "Z38.0", :medical_case_type => "ORDINARY CASE", :compute => true, :group_name => "DENGUE FEVER",:case_rate =>"A90" )
    @@ph2 = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "Z38.0", :compute => true,:rvu_code => "11462" )
    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@non_comp_others = 0

    @@orders =  (@ancillary).merge(@others)
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

    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * 0.16)
    @@ph2[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))

    @@actual_comp_xray_lab_others = @@comp_xray_lab - (0.16 * @@comp_xray_lab)
#    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
#    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
#      @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
#    else
#      @@actual_lab_benefit_claim2 = @@lab_ph_benefit[:max_amt].to_f
#    end
    @@actual_lab_benefit_claim2 = 0.00
    @@ph2[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    @@total_benefit_claim1 = 8020 - 2520
    @@ph2[:er_total_actual_benefit_claim].should == ("%0.2f" %(@@total_benefit_claim1))
    slmc.is_text_present("Claims History").should be_true
    slmc.is_text_present("Maximum Benefits").should be_true
    slmc.is_text_present("Employer Details").should be_true
   
  end
  it "Bug #40031 - [PH] Unable to save PH form, as the SAVE button not working" do
        sleep 10
    slmc.ph_save_computation
    slmc.is_text_present("ESTIMATE").should be_true
    slmc.is_text_present("Claims History").should be_true
  end
  it "Bug #40286 - [PH] PH Form buttons appears to be disable after claim is computed and save" do
    slmc.login(@er_user, @password).should be_true
    @@er_pin2 = slmc.er_create_patient_record(@er_patient2.merge!(:admit => true, :gender => 'F', :birth_day => Date.today.strftime("%m/%d/%Y"), :rch_code => 'RCHSP', :org_code => '0173'))
    slmc.login(@er_user, @password).should be_true
    sleep 10    
    slmc.er_clinical_order_patient_search(:pin => @@er_pin2)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @others.each do |item, q|
      slmc.search_order(:description => item, :others => true).should be_true
      slmc.add_returned_order(:others => true, :description => item, :stat => true,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:others => 3).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :others => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items#.should be_true

    slmc.go_to_er_page
    @@visit_no2 = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin2, :diagnosis => "SINGLE, BORN IN HOSPITAL", :pf_amount => "1000", :save => true) #Z38.0 SINGLE, BORN IN HOSPITAL

    slmc.go_to_er_billing_page
        sleep 10
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin2)
    slmc.go_to_er_page_for_a_given_pin("Discharge Patient", @@visit_no2)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.click_new_guarantor.should be_true
    slmc.pba_update_guarantor.should be_true
    slmc.skip_update_patient_information
    #@@ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "Z38.0", :medical_case_type => "ORDINARY CASE", :compute => true)
        @@ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "Z38.0", :compute => true,:rvu_code => "11462" )
    slmc.ph_save_computation
    slmc.ph_print_report.should be_true
    slmc.ph_view_details(:close => true).should == 4
    slmc.ph_go_to_mainpage.should be_true
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin2)
    slmc.go_to_er_page_for_a_given_pin("Discharge Patient", @@visit_no2)
    slmc.skip_philhealth
    slmc.click("//input[@value='Back']", :wait_for => :page)

    slmc.is_editable("btnMainPage").should be_true
    slmc.is_editable("btnCompute").should be_false
    slmc.is_editable("btnEdit").should be_false #verified by Chris Lim (cannot edit if save as FINAL)
    slmc.is_editable("btnSave").should be_false
    slmc.is_editable("btnClear").should be_false
    slmc.is_editable("btnPrint").should be_true
    slmc.is_editable("btnViewDetails").should be_true
    slmc.is_editable("btnSkip").should be_true
    slmc.is_editable("btnBack").should be_true
  end
  it "Bug #26316 - [PhilHealth-Inpatient] Incorrect value generated when amount is round off to the nearest decimal point" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@ph_patient_pin = slmc.create_new_patient(@ph_patient).gsub(' ', '')
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@ph_patient_pin).should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."

    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@ph_patient_pin)
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
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 4).should be_true
    slmc.verify_ordered_items_count(:ancillary => 4).should be_true
    slmc.verify_ordered_items_count(:supplies => 2).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 10
    slmc.confirm_validation_all_items#.should be_true

    slmc.login("slaquino", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@ph_patient_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@ph_patient_pin)
    @@item_code_or = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code_or, :description => "GASTRIC SURGERY")
    @@item_code2_or = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code2_or, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 2
    slmc.confirm_validation_all_items#.should be_true

    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@ph_patient_pin, :diagnosis => "A00", :pf_amount => 10000, :no_pending_order => true, :save => true).should be_true

    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@ph_patient_pin)
    @@ph_patient_visitno = slmc.get_visit_number_using_pin(@@ph_patient_pin)
    slmc.go_to_page_using_visit_number("PhilHealth", @@ph_patient_visitno)
    @@philhealth = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "A00", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    @@ph_refno = slmc.ph_save_computation.should be_true

    #Benefit Summary
    @@comp_drugs = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@comp_operation = 0
    @@non_comp_operation = 0
    @@comp_supplies = 0
    @@non_comp_supplies = 0
    @@comp_others = 0
    @@non_comp_others = 0

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

    #Drugs- Actual Charges
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    pt_total_drugs = @@comp_drugs + @@non_comp_drugs
    #@@actual_medicine_charges = pt_total_drugs - (@pt_promo_discount * pt_total_drugs)
    #@@philhealth[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    @@acm = pt_total_drugs - (@pt_promo_discount * pt_total_drugs)
    @@acm = ("%0.2f" %(@@acm))
    puts "pt_total_drugs = #{pt_total_drugs}"
    puts "@pt_promo_discount - #{@pt_promo_discount}"
    puts "@@acm - #{@@acm}"
    puts "@@philhealth[:actual_medicine_charges] - #{@@philhealth[:actual_medicine_charges]}"
    @@philhealth[:actual_medicine_charges].should == @@acm

    #Drugs- Actual Benefit Claim
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @pt_promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim1 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
    end
    @@actual_medicine_benefit_claim1 = 0.00
    @@philhealth[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))

    #Xray, Lab and Others- Actual Charges
    pt_total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies + @@comp_supplies
    #@@actual_xray_lab_others = pt_total_xrays_lab_others - (pt_total_xrays_lab_others * @pt_promo_discount)
    #@@philhealth[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    @@axlo = pt_total_xrays_lab_others - (pt_total_xrays_lab_others * @pt_promo_discount)
    @@axlo = ("%0.2f" %(@@axlo))
    @@philhealth[:actual_lab_charges].should == @@axlo

    #Xray, Lab and Others- Actual Benefit Claim
    @@actual_comp_xray_lab_others = (@@comp_xray_lab + @@comp_supplies) - (@pt_promo_discount * (@@comp_xray_lab + @@comp_supplies))
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
    end
    @@actual_lab_benefit_claim1 = 0.00
    @@philhealth[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))

    #Operation- Actual Charges
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @pt_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @pt_promo_discount))
    #@@philhealth[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    @@aoc = @@comp_operation - (@@comp_operation * @pt_promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @pt_promo_discount))
    @@aoc = ("%0.2f" %(@@aoc))
    @@philhealth[:actual_operation_charges].should == @@aoc

    #Operation- Actual Benefit Claim
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
    @@philhealth[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))

    #Total Actual Charges
    #pt_total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    #@@philhealth[:total_actual_charges].should == ("%0.2f" %(pt_total_actual_charges))
    pt_total_actual_charges = @@acm.to_f + @@axlo.to_f + @@aoc.to_f
    @@philhealth[:total_actual_charges].should == pt_total_actual_charges.to_s

    #Total Actual Benefit Claim
    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1
    @@total_actual_benefit_claim = 2800
    @@philhealth[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end
  it "Bug #40278 - [PH] SPU-DR: Patient PH claims not computed as normal case computation" do
    slmc.login(@dr_user, @password).should be_true
    @@newborn_pin = slmc.or_create_patient_record(@dr_patient.merge!(:admit => true, :org_code => "0170", :gender => 'F', :birth_day => Date.today.strftime("%m/%d/%Y"))).gsub(' ', '')
        slmc.login(@dr_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@newborn_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@newborn_pin)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @others.each do |item, q|
      slmc.search_order(:description => item, :others => true).should be_true
      slmc.add_returned_order(:others => true, :description => item, :stat => true,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:others => 3).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :others => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items#.should be_true

    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@newborn_pin, :diagnosis => "Z38.0", :pf_amount => "1000", :save => true)

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@newborn_pin).should be_true
    slmc.click_philhealth_link(:pin => @@newborn_pin, :visit_no => @@visit_no)
  #  @@ph = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "Z38.0", :medical_case_type => "ORDINARY CASE", :compute => true)
            @@ph = slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "Z38.0", :compute => true,:rvu_code => "11462" )
    slmc.ph_save_computation

    @@comp_xray_lab = 0
    @@non_comp_xray_lab = 0
    @@non_comp_others = 0

    @@orders = @ancillary.merge(@others)
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

    @@promo_discount = 0.16 # since newborn
    # Normal Case Computation shall apply
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_others
    @@actual_xray_lab_others = total_xrays_lab_others - (total_xrays_lab_others * @@promo_discount)
    @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))

    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
      @@actual_lab_benefit_claim = @@actual_comp_xray_lab_others # it will perform this operation
    else
      @@actual_lab_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
    end
###########    @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim))
###########    @@ph[:actual_lab_benefit_claim].should_not == ("%0.2f" %(1000))
    myclaimrate = 5500.00
    @@ph[:total_actual_benefit_claim].should_not == ("%0.2f" %(myclaimrate))
  end
  it "Bug #28855 - [PhilHealth-Outpatient] Claim Type is Accounts Receivable after PBA discharge" do #Bug 51724
    slmc.login(@or_user, @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge(:admit => true)).gsub(' ', '')
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @or_drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
        :stock_replacement => true, :quantity => q, :frequency => "NOW", :add => true, :doctor => "6726").should be_true
    end
    @or_ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    @or_supplies.each do |item, q|
      slmc.search_order(:description => item, :supplies => true).should be_true
      slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items#.should be_true
sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_latest_philhealth_link_for_outpatient
    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true, :rvu_code => "11462")

    @@ph_ref1 = slmc.ph_save_computation
sleep 6
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :pf_amount => '1000', :save => true)
sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
sleep 6
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin)
    slmc.click_latest_philhealth_link_for_outpatient

    slmc.philhealth_computation(:edit => true, :claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true, :rvu_code => "11462")
    slmc.get_text("philHealthForm.errors").should == "For discharged patient, only \"Refund\" claim is accepted."
    slmc.is_text_present("ESTIMATE").should be_true
    slmc.is_text_present("FINAL").should be_false

    slmc.philhealth_computation(:edit => true, :claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
    @@ph_ref2 = slmc.ph_save_computation
    @@ph_ref1.should_not == @@ph_ref2
  end
  it "Bug #24278 PhilHealth * Claim type is disabled in PhilHealth Outpatient Computation page" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin2 = slmc.or_create_patient_record(Admission.generate_data.merge(:admit => true)).gsub(' ', '')

    slmc.occupancy_pin_search(:pin => @@or_pin2)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin2)
    @or_drugs2.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
        :stock_replacement => true, :quantity => q, :frequency => "NOW", :add => true, :doctor => "6726").should be_true
    end
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items#.should be_true

    slmc.go_to_occupancy_list_page
    slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin2, :pf_amount => '1000', :save => true)
sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.pba_outpatient_computation(:pin => @@or_pin).should be_true
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.is_editable("claimType").should be_false
  end
  it "Bug #29953 - [PhilHealth-Outpatient] Claim type becomes Refund during standard discharge" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_outpatient_computation(:pin => @@or_pin2).should be_true
    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true, :rvu_code => "11462")
    @@ph_ref1 = slmc.ph_save_computation

    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin2)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.skip_update_patient_information
    slmc.skip_room_and_bed_cancelation

    slmc.get_selected_label("claimType").should == "ACCOUNTS RECEIVABLE"
    slmc.click("btnEdit")
    sleep 1
    slmc.is_editable("btnEdit").should be_true
    @@ph_ref2 = slmc.ph_save_computation
    @@ph_ref1.should == @@ph_ref2
    slmc.is_text_present("FINAL").should be_true
  end
end
