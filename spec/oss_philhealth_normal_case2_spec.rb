
require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: OSS - Philhealth Module Test - Normal Case (10th - 18th Availment)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
#    @selenium_driver.evaluate_rooms_for_admission('0164','RCHSP')
    @selenium_driver.start_new_browser_session
    @ph_patient1 = Admission.generate_data
    @ph_patient = Admission.generate_data
    @ph_patient2 = Admission.generate_data.merge(:birth_day => "01/01/1940") ## patient2 is a senior citizen patient
    ## board member patient,
    @ph_patient3 = {
      :first_name => 'ROBERT',
      :last_name => 'KUAN',
      :middle_name => 'FUNG',
      :gender => 'M',
      :birth_day => '08/06/1948',
      :age => AdmissionHelper.calculate_age(Date.parse('08/06/1948'))
    }
    ## employee patient, 100600160 - Tan, Peter Carlo
    @ph_patient4 = {
      :age => AdmissionHelper.calculate_age(Date.parse('08/01/1986'))
    }
    # doctor patient, AMPIL, Isaac David II
    @ph_patient5 = {
      :first_name => 'ISAAC DAVID II',
      :last_name => 'AMPIL',
      :middle_name => 'ESGUERRA',
      :gender => 'M',
      :birth_day => '09/30/1958',
      :age => AdmissionHelper.calculate_age(Date.parse('09/30/1958'))
    }
    # employee dependent patient, 100600161 - TAN, Rachel Mae Go
    @ph_patient6 = {
      :age => AdmissionHelper.calculate_age(Date.parse('07/26/1987'))
    }
    #@oss_user = USERS['oss_philhealth_normal_spec_user2']
    @oss_user = "jtsalang"
    @pba_user = "ldcastro"
    @password = "123qweuser"
    @promo_discount3 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@ph_patient3[:age])
    @promo_discount4 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@ph_patient4[:age])
    @promo_discount5 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@ph_patient5[:age])
    @promo_discount6 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@ph_patient6[:age])
    @discount = 30.0
    @doctors = ["6793","0126","6793","0126","0126"]

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  ## 10th Availment
  ## Account Class: Board Member Dependent
  ## Guarantor Type:Board Member
  ## Case Type: Ordinary Case
  ## Claim Type: Accounts Receivable
  ## With Operation: No
  ## Diagnosis: CHOLERA(A00)

  it "Create new patient for OSS transaction" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@ph_patient1).should be_true
    @@oss_pin.should be_true
    @@pin0 = @@oss_pin.gsub(' ', '')
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin0)
    slmc.click_outpatient_order.should be_true

    @ancillary =
      {
      "010000008" => 1, #BONE IMAGING
      "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
    }
    @operation = {"010000160" => 1} #POLARIZING MICROSCOPY

    #add all items to be ordered
    @@orders10 =  @ancillary.merge(@operation)
    n = 0
    @@orders10.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n +=1
    end

    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true)

    age = AdmissionHelper.calculate_age(Date.parse(@ph_patient1[:birth_day]))
    @@promo_discount1 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(age)
    if @@promo_discount1 == 0.2
      slmc.type'seniorIdNumber','123456'
    end

    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "10th Availment: Creates senior citizen patient" do
    slmc.go_to_das_oss
    slmc.oss_advanced_search
      if slmc.is_text_present("NO PATIENT FOUND")
         slmc.click_outpatient_registration.should be_true
        @@bmd_pin = slmc.oss_outpatient_registration((Admission.generate_data.merge(:last_name => "DOMOGAN", :first_name => "JOY ALLISON", :middle_name => "N", :birth_day => "07/03/1988", :gender => 'F'))).should be_true
        @@pin2 = @@bmd_pin.gsub(' ', '')
      else
        @@pin2 = slmc.get_text'css=#results>tbody>tr.odd>td:nth-child(4)' #mpi on
        @@pin2 = @@pin2.gsub(' ','')
      end
  # @@pin2 = "1303029074"

    @@promo_discount2 = 0.16
  end

  it "10th Availment - Board Member Dependent: Searches and adds order items in the OSS outpatient order page" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin2)
    slmc.click_outpatient_order.should be_true

    @ancillary10 =
      {
      "010000008" => 1, #BONE IMAGING
      "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
    }
    @operation10 = {"010000160" => 1} #POLARIZING MICROSCOPY

    #add all items to be ordered
    @@orders10 =  @ancillary10.merge(@operation10)
    n = 0
    @@orders10.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n +=1
    end
  end
#
  it "10th Availment - Board Member Dependent: Add guarantor and enable philhealth patient information" do
    slmc.oss_add_guarantor(:guarantor_type =>  'BOARD MEMBER', :acct_class => 'BOARD MEMBER DEPENDENT', :guarantor_code => "BMMD001", :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true)
  end

  it "10th Availment - Board Member Dependent: Check Benefit Summary totals" do
    # set to 0 to initialize variables
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

    @@orders10.each do |order,n|
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
        x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "10th Availment - Board Member Dependent: Checks if the actual charge for drugs/medicine is correct"   do
    # actual medical charges computation
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@@promo_discount2 * total_drugs)
    @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "10th Availment - Board Member Dependent: Checks if the actual benefit claim for drugs/medicine is correct" do
    # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim10 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim10 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
  end

  it "10th Availment - Board Member Dependent: Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount2 * total_xrays_lab_others)
    @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "10th Availment - Board Member Dependent: Checks if the actual lab benefit claim is correct" do
   # if slmc.get_text(Locators::OSS_Philhealth.claims_history) == "Nothing found to display."
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount2 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")

#          if  slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
#                  @@actual_lab_benefit_claim10 =  @@lab_ph_benefit[:max_amt].to_f
#          elsif  @@actual_comp_xray_lab_others <  @@lab_ph_benefit[:max_amt].to_f
#                  @@actual_lab_benefit_claim10 = @@actual_comp_xray_lab_others
#          elsif slmc.get_text(Locators::OSS_Philhealth.claims_history).should != "Nothing found to display."
#                @@claims_history = slmc.get_total_claims_history("oss")
#                 if @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
#                    @@actual_lab_benefit_claim10 = @@actual_comp_xray_lab_others
#                 end
#          else
                  @@claims_history = slmc.get_total_claims_history("oss")
                  (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims]).should == 0
                  @@actual_lab_benefit_claim10 = 0.00
#          end

    @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
  end

  it "10th Availment - Board Member Dependent: Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@promo_discount2 * @@comp_operation)
    @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "10th Availment - Board Member Dependent: Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("philHealthBean.rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim10 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim10 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
    else
      @@actual_operation_benefit_claim10 = 0.00
      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
    end
  end

  it "10th Availment - Board Member Dependent: Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "10th Availment - Board Member Dependent: Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim10 = @@actual_medicine_benefit_claim10 + @@actual_lab_benefit_claim10 + @@actual_operation_benefit_claim10
    @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim10))
  end

  it "10th Availment - Board Member Dependent: Checks if the maximum benefits are correct" do
    @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "10th Availment - Board Member Dependent: Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim10))
    @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim10))
    @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim10))
  end

  it "10th Availment - Board Member Dependent: Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim10 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim10 = (@@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim10)
    else
      @@drugs_remaining_benefit_claim10 = 0.00
    end
    @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim10

#    if   (slmc.get_text(Locators::OSS_Philhealth.claims_history)).should  !=  "Nothing found to display."
    if   ((slmc.get_text(Locators::OSS_Philhealth.claims_history)) ==  "Nothing found to display.").should be_false
          @@lab_remaining_benefit_claim10 = (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
#    elsif @@actual_lab_benefit_claim10 < @@lab_ph_benefit[:max_amt].to_f
#          @@lab_remaining_benefit_claim10 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim10
    else
            @@lab_remaining_benefit_claim10 = 0.00
    end
#    @@lab_remaining_benefit_claim10 = 3200.0
    @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim10
  end

  it "10th Availment - Board Member Dependent: Checks if Philhealth Claims is displayed in Summary Totals correctly" do
    slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim10))
  end

  it "10th Availment - Board Member Dependent: Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
  end

  it "10th Availment - Board Member Dependent: PhilHealth benefit claim shall not reflect in Payment details" do
    slmc.click "paymentToggle"
    (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
    #(slmc.get_text('paymentSection').include? @@total_actual_benefit_claim10.to_s).should be_false
    slmc.click "paymentToggle"
  end

  it "10th Availment - Board Member Dependent: Proceed with payment successfully" do
    #(slmc.oss_submit_order("class")) == "Admission"
      if @@promo_discount2 == 0.2
        slmc.type'seniorIdNumber','123456'
      end
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      if amount != "0.00"
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      end
      sleep 8
     (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  ## 11th Availment
  ## Account Class: Company
  ## Guarantor Type:Company
  ## Case Type: Ordinary Case
  ## Claim Type: Refund
  ## With Operation: No
  ## Diagnosis: CHOLERA(A00)
  ## 30% Discount

  it "11th Availment - Company: Searches and adds order items in the OSS outpatient order page" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@patient_pin = slmc.oss_outpatient_registration(@ph_patient).should be_true
    @@patient_pin = @@patient_pin.gsub(' ', '')
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@patient_pin)
    slmc.click_outpatient_order.should be_true

    @ancillary11 =
      {
      "010000008" => 1, #BONE IMAGING
      "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
    }
    @operation11 = {"010000160" => 1} #POLARIZING MICROSCOPY
    #
    #add all items to be ordered
    @@orders11 =  @ancillary11.merge(@operation11)
    @@orders11.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => '0126')
    end

     age = AdmissionHelper.calculate_age(Date.parse(@ph_patient[:birth_day]))
    @@promo_discount2 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(age)
    if @@promo_discount2 == 0.2
      slmc.type'seniorIdNumber','123456'
    end

  end

  it "11th Availment - Company: Add guarantor information" do  #
    slmc.oss_add_guarantor(:guarantor_type =>  'COMPANY', :acct_class => 'COMPANY', :guarantor_code => "ABSC001", :coverage_choice => 'percent', :coverage_amount => @discount.to_s, :guarantor_add => true)
  end

  it "11th Availment - Company: Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "11th Availment - Company: PBA user login and verify submitted transaction from the PhilHealth Outpatient Computation page" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@patient_pin).should be_true
  end

  it "11th Availment - Company: Click Philhealth link and input Philhealth details" do
    slmc.click_latest_philhealth_link_for_outpatient
    @@ph = slmc.philhealth_computation(:medical_case_type => "ORDINARY CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true)
  end

  it "11th Availment - Company: Check Benefit Summary totals" do
    # set to 0 to initialize variables
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

    @@orders11.each do |order,n|
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
        x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "11th Availment - Company: Checks if the actual charge for drugs/medicine is correct"   do
    # actual medical charges computation
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@@promo_discount2 * total_drugs)
    @@ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "11th Availment - Company: Checks if the actual benefit claim for drugs/medicine is correct" do
    # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim11 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim11 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim11))
  end

  it "11th Availment - Company: Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount2 * total_xrays_lab_others)
    @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "11th Availment - Company: Checks if the actual lab benefit claim is correct" do
    # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount2 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")

          if  (slmc.get_text(Locators::OSS_Philhealth.claims_history)).should == "Nothing found to display."
                  @@actual_lab_benefit_claim11 =  @@lab_ph_benefit[:max_amt].to_f
          elsif  @@actual_comp_xray_lab_others <  @@lab_ph_benefit[:max_amt].to_f
                  @@actual_lab_benefit_claim11 = @@actual_comp_xray_lab_others
          elsif (slmc.get_text(Locators::OSS_Philhealth.claims_history)).should != "Nothing found to display."
                @@claims_history = slmc.get_total_claims_history("oss")
                 if @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
                    @@actual_lab_benefit_claim11 = @@actual_comp_xray_lab_others
                 end
          else
                  @@actual_lab_benefit_claim11 = 0.00
          end
    @@ph[:or_actual_lab_benefit_claim].to_f.should ==  @@actual_lab_benefit_claim11
  end

  it "11th Availment - Company: Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@promo_discount2 * @@comp_operation)
    @@ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "11th Availment - Company: Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim11 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim11 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim11))
    else
      @@actual_operation_benefit_claim11 = 0.00
      @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim11))
    end
  end

  it "11th Availment - Company: Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "11th Availment - Company: Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim11 = @@actual_medicine_benefit_claim11 + @@actual_lab_benefit_claim11 + @@actual_operation_benefit_claim11
    @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim11))
  end

  it "11th Availment - Company: Checks if the maximum benefits are correct" do
    @@ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "11th Availment - Company: Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim11))
    @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim11))
    #@@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim11))
  end

  it "11th Availment - Company: Checks if Remaining Benefit Claims are correct" do
   if @@actual_medicine_benefit_claim11< @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim11 = (@@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim11)
    else
      @@drugs_remaining_benefit_claim11 = 0.00
    end
    @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim11

    if @@actual_lab_benefit_claim11 < @@lab_ph_benefit[:max_amt].to_f
          @@lab_remaining_benefit_claim11 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim11
#    elsif   (slmc.get_text(Locators::OSS_Philhealth.claims_history)).should != "Nothing found to display."
#          @@claims_history = slmc.get_total_claims_history("oss")
#          @@lab_remaining_benefit_claim11 = (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
    else
            @@lab_remaining_benefit_claim11 = 0.00
    end
    @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim11
  end

  it "11th Availment - Company: Checks if clicking 'Save' button saves the philhealth computation as ESTIMATE " do
    slmc.ph_save_computation
    slmc.is_text_present("ESTIMATE")
  end

  it "11th Availment - Company: Checks if clicking 'View details' button displays of order details" do
    slmc.ph_view_details(:close => true).should == 3
  end

  #    it "11th Availment - Company: Prints philhealth computation" do
  #      slmc.ph_print_report.should be_true
  #    end

  it "11th Availment - Company: Checks Claim History" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@patient_pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_patient_info(:philhealth => true)
    slmc.get_text(Locators::OSS_Philhealth.first_total_claim_history).gsub(',','').should == "3200.00" #("%0.2f" %(@@total_actual_benefit_claim10))
  end

  it "11th Availment - Company: Company discount shall reflect in Payment details" do
    total_net_amount = slmc.get_billing_total_net_amount.to_f
    @charge_amount = total_net_amount * (@discount / 100.0)
    slmc.get_billing_total_charge_amount.should == ("%0.2f" %(@charge_amount))
  end

  ## 12th Availment
  ## Account Class: Doctor Dependent
  ## Guarantor Type: Doctor
  ## Case Type: Intensive Case
  ## Claim Type: Accounts Receivable
  ## With Operation: No
  ## Diagnosis: CALIFORNIA ENCEPHALITIS (A83.5)

  it "12th Availment - Doctor Dependent: Searches and adds order items in the OSS outpatient order page" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    #pin # 1105000899
    slmc.oss_advanced_search(:lastname =>  "BASCO",:firstname => "ELLEN GRACE",:middlename => "S")
      if slmc.is_text_present("NO PATIENT FOUND")
         slmc.click_outpatient_registration#.should be_true
        @@drd_pin = slmc.oss_outpatient_registration((Admission.generate_data.merge(:last_name => "BASCO", :first_name => "ELLEN GRACE", :middle_name => "S", :birth_day => "10/06/1958", :gender => 'F')))#.should be_true
        @@pin12 = @@drd_pin.gsub(' ', '')
      else
        @@pin12 = slmc.get_text'css=#results>tbody>tr.odd>td:nth-child(4)'#mpi on
        @@pin12 = @@pin12.gsub(' ','')
      end
  #  @@pin12 = "1105001177"
    @@promo_discount2 = 0.16
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin12)
    slmc.click_outpatient_order.should be_true

    @ancillary12 =
      {
      "010000008" => 1, #BONE IMAGING
      "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
    }
    @operation12 = {"010000160" => 1} #POLARIZING MICROSCOPY

    #add all items to be ordered
    @@orders12 =  @ancillary12.merge(@operation12)
    n = 0
    @@orders12.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n +=1
    end
  end

  it "12th Availment - Doctor Dependent: Add guarantor and enable philhealth patient information" do
    slmc.oss_add_guarantor(:guarantor_type =>  'DOCTOR', :acct_class => 'DOCTOR DEPENDENT', :guarantor_code => "0269", :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "INTENSIVE CASE", :diagnosis => "A83.5", :philhealth_id => "12345", :compute => true)
  end

  it "12th Availment - Doctor Dependent: Check Benefit Summary totals" do
    # set to 0 to initialize variables
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

    @@orders12.each do |order,n|
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
        x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "12th Availment - Doctor Dependent: Checks if the actual charge for drugs/medicine is correct"   do
    # actual medical charges computation
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@@promo_discount2 * total_drugs)
    @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "12th Availment - Doctor Dependent: Checks if the actual benefit claim for drugs/medicine is correct" do
    # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim12 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim12 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim12))
  end

  it "12th Availment - Doctor Dependent: Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount2 * total_xrays_lab_others)
    @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "12th Availment - Doctor Dependent: Checks if the actual lab benefit claim is correct" do
    # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount2 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")

#    if  (slmc.get_text(Locators::OSS_Philhealth.claims_history)).should == "Nothing found to display."
#                  @@actual_lab_benefit_claim12 =  @@lab_ph_benefit[:max_amt].to_f
#    elsif  @@actual_comp_xray_lab_others <  @@lab_ph_benefit[:max_amt].to_f
#                  @@actual_lab_benefit_claim12 = @@actual_comp_xray_lab_others
#    elsif (slmc.get_text(Locators::OSS_Philhealth.claims_history)).should != "Nothing found to display."
#                @@claims_history = slmc.get_total_claims_history("oss")
#                 if @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
#                    @@actual_lab_benefit_claim12 = @@actual_comp_xray_lab_others
#                 end
#    else
                  @@actual_lab_benefit_claim12 = 0.00
#    end
    @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim12))
  end

  it "12th Availment - Doctor Dependent: Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@promo_discount2 * @@comp_operation)
    @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "12th Availment - Doctor Dependent: Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("philHealthBean.rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim12 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim12 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim12))
    else
      @@actual_operation_benefit_claim12 = 0.00
      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim12))
    end
  end

  it "12th Availment - Doctor Dependent: Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "12th Availment - Doctor Dependent: Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim12 = @@actual_medicine_benefit_claim12 + @@actual_lab_benefit_claim12.to_f + @@actual_operation_benefit_claim12
    @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim12))
  end

  it "12th Availment - Doctor Dependent: Checks if the maximum benefits are correct" do
    @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "12th Availment - Doctor Dependent: Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim12))
    @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim12))
    @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim12))
  end

  it "12th Availment - Doctor Dependent: Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim12 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim12 = (@@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim12)
    else
      @@drugs_remaining_benefit_claim12 = 0.00
    end
    @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim12

#    if @@actual_lab_benefit_claim12 < @@lab_ph_benefit[:max_amt].to_f
#          @@lab_remaining_benefit_claim12 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim12
#    if   (slmc.get_text(Locators::OSS_Philhealth.claims_history)).should != "Nothing found to display."
#          @@claims_history = slmc.get_total_claims_history("oss")
#          @@lab_remaining_benefit_claim12 = (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
#    else
            @@lab_remaining_benefit_claim12 = 0.00
#    end
    @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim12
  end

  it "12th Availment - Doctor Dependent: Checks if Philhealth Claims is displayed in Summary Totals correctly" do
    slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim12))
  end

  it "12th Availment - Doctor Dependent: Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
  end

  it "12th Availment - Doctor Dependent: PhilHealth benefit claim shall not reflect in Payment details" do
    slmc.click "paymentToggle"
    (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
    if @@total_actual_benefit_claim12 != 0.0
    (slmc.get_text('paymentSection').include? @@total_actual_benefit_claim12.to_s).should be_false
    end
    slmc.click "paymentToggle"
  end

  it "12th Availment - Doctor Dependent: Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    sleep 2
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  ## 13th Availment
  ## Account Class: Board Member
  ## Guarantor Type:Board Member
  ## Case Type: Intensive Case
  ## Claim Type: Refund
  ## With Operation: No
  ## Diagnosis: CALIFORNIA ENCEPHALITIS (A83.5)

  it "13th Availment - Board Member: Create a board member patient" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    #slmc.patient_pin_search(:pin => @ph_patient3[:last_name])
    slmc.oss_advanced_search(:lastname =>  "KUAN",:firstname => "ROBERT",:middlename => "FUNG",:bday => "08/06/1948")
    if slmc.get_text("css=#results").include? @ph_patient3[:last_name]
      @@pin3 = slmc.get_text("css=#results>tbody>tr.odd>td:nth-child(4)").gsub(' ', '')
    else
      slmc.patient_pin_search(:pin => "test")
      slmc.click_outpatient_registration.should be_true
      @@oss_pin = slmc.oss_outpatient_registration(@ph_patient3).should be_true
      @@oss_pin.should be_true
      @@pin3 = @@oss_pin.gsub(' ', '')
    end
 #   @@pin3 = "1105000922"
  end

  it "13th Availment - Board Member: Searches and adds order items in the OSS outpatient order page" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin3)
    slmc.click_outpatient_order.should be_true

    @ancillary13 =
      {
      "010000008" => 1, #BONE IMAGING
      "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
    }
    @operation13 = {"010000160" => 1} #POLARIZING MICROSCOPY
    ## add all items to be ordered
    @@orders13 =  @ancillary13.merge(@operation13)
    @@orders13.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => '0126')
    end
  end

  it "13th Availment - Board Member: Add guarantor information" do
    slmc.oss_add_guarantor(:guarantor_type =>  'BOARD MEMBER', :acct_class => 'BOARD MEMBER', :guarantor_code => "BMRK001", :guarantor_add => true)
  end

  it "13th Availment - Board Member: Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    if amount != "0.00"
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    end
    sleep 2
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "13th Availment - Board Member: PBA user login and verify submitted transaction from the PhilHealth Outpatient Computation page" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@pin3).should be_true
  end

  it "13th Availment - Board Member: Click Philhealth link and input Philhealth details" do
    slmc.click_latest_philhealth_link_for_outpatient
    @@ph = slmc.philhealth_computation(:medical_case_type => "INTENSIVE CASE", :diagnosis => "A83.5", :philhealth_id => "12345", :compute => true)
  end

  it "13th Availment - Board Member: Check Benefit Summary totals" do
    # set to 0 to initialize variables
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

    @@orders13.each do |order,n|
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
        x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "13th Availment - Board Member: Checks if the actual charge for drugs/medicine is correct"   do
    # actual medical charges computation
    sleep 4
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@promo_discount3 * total_drugs)
    @@ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "13th Availment - Board Member: Checks if the actual benefit claim for drugs/medicine is correct" do
    # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
    @@actual_medicine_benefit_claim13 = 0.0 #automatic 100% covered when board member
    @@ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim13))

  end

  it "13th Availment - Board Member: Checks if the actual charge for xrays, lab and others is correct" do
    @@actual_xray_lab_others = @@comp_xray_lab - (@promo_discount3* @@comp_xray_lab)
    @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "13th Availment - Board Member: Checks if the actual lab benefit claim is correct" do
    # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount3 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
    @@claims_history = slmc.get_total_claims_history("philhealth")

    if @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
      @@actual_lab_benefit_claim13 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim13 = (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
    end
#    @@actual_lab_benefit_claim13 = 0.0
    @@ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim13))
  end

  it "13th Availment - Board Member: Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@promo_discount3 * @@comp_operation)
    #@@actual_operation_charges = 0.0
    @@ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "13th Availment - Board Member: Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
       @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04")
          if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
            @@actual_operation_benefit_claim13 = @@actual_operation_charges
          else
            @@actual_operation_benefit_claim13 = @@operation_ph_benefit[:max_amt].to_f
          end
          @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim13))
        else
          @@actual_operation_benefit_claim13 = 0.00
          @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim13))
      end
#      @@actual_operation_benefit_claim13 = 0.00
      @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim13))
  end

  it "13th Availment - Board Member: Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "13th Availment - Board Member: Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim13 = @@actual_medicine_benefit_claim13 + @@actual_lab_benefit_claim13 + @@actual_operation_benefit_claim13
    @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim13))
  end

  it "13th Availment - Board Member: Checks if the maximum benefits are correct" do
    @@ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:er_max_benefit_xray_lab_others].should == "10500.00"
  end

  it "13th Availment - Board Member: Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim13))
    @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim13))
    #@@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim13))
  end

  it "13th Availment - Board Member: Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim13 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim13 = (@@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim13)
    else
      @@drugs_remaining_benefit_claim13 = 0.00
    end
    @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim13

    if @@actual_lab_benefit_claim13 < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
      @@lab_remaining_benefit_claim13 = ((@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims]) - @@actual_lab_benefit_claim13)
    else
      @@lab_remaining_benefit_claim13 = 0.00
    end
    @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim13
#        @@lab_remaining_benefit_claim13 = "10500.00"
#      @@ph[:lab_remaining_benefit_claims].should == @@lab_remaining_benefit_claim13
  end

  it "13th Availment - Board Member: Checks if clicking 'Save' button saves the philhealth computation as ESTIMATE " do
    slmc.ph_save_computation
    slmc.is_text_present("ESTIMATE")
  end

  it "13th Availment - Board Member: Checks if clicking 'View details' button displays of order details" do
    slmc.ph_view_details(:close => true).should == 3
  end

  it "13th Availment - Board Member: Successfully discharge patient" do
    slmc.login('slaquino', @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin3)
    if slmc.is_element_present Locators::NursingSpecialUnits.spu_print_gate_pass
      slmc.click Locators::NursingSpecialUnits.spu_print_gate_pass, :wait_for => :page
    end
  end

  ## 14th Availment
  ## Account Class: HMO
  ## Guarantor Type:HMO
  ## Case Type: Catastrophic Case
  ## Claim Type: Accounts Receivable
  ## With Operation: Yes
  ## Diagnosis: CALIFORNIA ENCEPHALITIS (A83.5)

  it "14th Availment - HMO: Searches and adds order items in the OSS outpatient order page" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@ph_patient2.merge!(:birth_day => "01/01/1940")).should be_true
    @@oss_pin.should be_true
    @@pin = @@oss_pin.gsub(' ', '')

    age = AdmissionHelper.calculate_age(Date.parse(@ph_patient2[:birth_day]))
    @@promo_discount2 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(age)

    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true

    @ancillary14 =
      {
      "010000008" => 1, #BONE IMAGING
      "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
    }
    @operation14 = {"010000160" => 1} #POLARIZING MICROSCOPY

    #add all items to be ordered
    @@orders14 =  @ancillary14.merge(@operation14)
    n = 0
    @@orders14.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n +=1
    end
  end

  it "14th Availment - HMO: Add guarantor and enable philhealth patient information" do
    slmc.oss_add_guarantor(:guarantor_type =>  'HMO', :acct_class => 'HMO', :guarantor_code => "ICAR001", :coverage_choice => 'percent', :coverage_amount => @discount.to_s, :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "CATASTROPHIC CASE", :diagnosis => "A83.5", :rvu_code => "10060", :philhealth_id => "12345", :compute => true)
  end

  it "14th Availment - HMO: Check Benefit Summary totals" do
    # set to 0 to initialize variables
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

    @@orders14.each do |order,n|
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
        x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "14th Availment - HMO: Checks if the actual charge for drugs/medicine is correct"   do
    # actual medical charges computation
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@@promo_discount2 * total_drugs)
    @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "14th Availment - HMO: Checks if the actual benefit claim for drugs/medicine is correct" do
    # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")

       if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim14 = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim14 = @@med_ph_benefit[:max_amt].to_f
      end
      @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim14))
  end

  it "14th Availment - HMO: Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@@promo_discount2 * total_xrays_lab_others)
    @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "14th Availment - HMO: Checks if the actual lab benefit claim is correct" do
    # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@@promo_discount2 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")

       if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
        @@actual_lab_benefit_claim14 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim14 = @@lab_ph_benefit[:max_amt].to_f
      end
      @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim14))
  end

  it "14th Availment - HMO: Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@promo_discount2 * @@comp_operation)
    @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "14th Availment - HMO: Checks if the actual operation benefit claim is correct" do
#    if slmc.get_value("philHealthBean.rvu.code").empty? == false
#      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
#      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
#        @@actual_operation_benefit_claim14 = @@actual_operation_charges
#      else
#        @@actual_operation_benefit_claim14 = @@operation_ph_benefit[:max_amt].to_f
#      end
#      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim14))
#    else
#      @@actual_operation_benefit_claim14 = 0.00
#      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim14))
#    end
      @@actual_operation_benefit_claim14 = 1200.00
      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim14))
  end

  it "14th Availment - HMO: Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "14th Availment - HMO: Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim14 = @@actual_medicine_benefit_claim14 + @@actual_lab_benefit_claim14 + @@actual_operation_benefit_claim14
    @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim14))
  end

  it "14th Availment - HMO: Checks if the maximum benefits are correct" do
    @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "14th Availment - HMO: Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim14))
    @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim14))
    @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim14))
  end

  it "14th Availment - HMO: Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim14 < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim14 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim14
      else
        @@drugs_remaining_benefit_claim14 = 0.00
      end
      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim14

      if @@actual_lab_benefit_claim14 < @@lab_ph_benefit[:max_amt].to_f
        @@lab_remaining_benefit_claim14 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim14
      else
        @@lab_remaining_benefit_claim14 = 0.00
      end
      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim14
  end

  it "14th Availment - HMO: Checks if PF Claims for surgeon is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim14 = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    #@@surgeon_claim14 = @@pf_gp_surgeon[:max_amt].to_f * @@rvu[:value].to_f

    @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim14))
  end

  it "14th Availment - HMO: Checks if PF Claims for anesthesiologist is correct" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
    @@anesthesiologist_claim14 = (@@surgeon_claim14.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))
    #@@anesthesiologist_claim14 = (@@surgeon_claim14.to_f * (@@pf_gp_anesthesiologist[:max_amt].to_f/100))

    @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim14))
  end


  it "14th Availment - HMO: Checks if Philhealth Claims is displayed in Summary Totals correctly" do
    slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim14))
  end

  it "14th Availment - HMO: Checks if Summary Totals > Total Net Amount is equal to Payments > Total Net Amount " do
    slmc.get_total_net_amount.should == slmc.get_billing_total_net_amount
  end

  it "14th Availment - HMO: PhilHealth benefit claim shall not reflect in Payment details" do
    slmc.click "paymentToggle"
    (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
    (slmc.get_text('paymentSection').include? @@total_actual_benefit_claim14.to_s).should be_false
    slmc.click "paymentToggle"
  end

  it "14th Availment - HMO: HMO discount shall reflect in Payment details" do
    total_net_amount = slmc.get_billing_total_net_amount.to_f
    @charge_amount = total_net_amount * (@discount / 100.0)
    slmc.get_billing_total_charge_amount.should == ("%0.2f" %(@charge_amount))
  end

  it "14th Availment - HMO: Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
      if @@promo_discount2 == 0.2
        slmc.type'seniorIdNumber','123456'
      end
      sleep 2
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  # 15th Availment
  # Account Class: Employee
  # Guarantor Type:Employee
  # Case Type: Super Catastrophic
  # Claim Type: Accounts Receivable
  # With Operation: Yes
  # Diagnosis: AMEBIC INFECTION OF OTHER SITES (A06.8)

  it "15th Availment - Employee: Searches and adds order items in the OSS outpatient order page" do
    #@@pin4 = "1101504369" # Existing employee patient Tan, Peter Carlo
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    #slmc.oss_advanced_search(:lastname=>"TAN",:firstname=>"PETER CARLO",:middlename=>"GO")
    slmc.oss_advanced_search(:lastname=>"SATO",:firstname=>"TAKAYUKI",:middlename=>"CHENG")
      if slmc.is_text_present("NO PATIENT FOUND")
         slmc.click_outpatient_registration.should be_true
        @@emp_pin = slmc.oss_outpatient_registration((Admission.generate_data.merge(:last_name => "SATO", :first_name => "TAKAYUKI", :middle_name => "CHENG", :birth_day => "08/01/1986", :gender => 'M'))).should be_true
        @@pin15 = @@emp_pin.gsub(' ', '')
      else
        @@pin15 = slmc.get_text'css=#results>tbody>tr.odd>td:nth-child(4)' #mpi on
        @@pin15 = @@pin15.gsub(' ','')
      end
    slmc.login(@oss_user, @password).should be_true

    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin15)
    slmc.click_outpatient_order.should be_true

    @ancillary15 =
      {
      "010000008" => 1, #BONE IMAGING
      "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
    }
    @operation15 = {"010000160" => 1} #POLARIZING MICROSCOPY

    #add all items to be ordered
    @@orders15 =  @ancillary15.merge(@operation15)
    n = 0
    @@orders15.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n +=1
    end
  end

  it "15th Availment - Employee: Add guarantor and enable philhealth patient information" do
    slmc.oss_add_guarantor(:guarantor_type =>  'EMPLOYEE', :acct_class => 'EMPLOYEE', :guarantor_code => "0109999", :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "SUPER CATASTROPHIC CASE", :diagnosis => "A06.8", :rvu_code => "10060", :philhealth_id => "12345", :compute => true)
  end

  it "15th Availment - Employee: Check Benefit Summary totals" do
    # set to 0 to initialize variables
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

    @@orders15.each do |order,n|
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
        x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "15th Availment - Employee: Checks if the actual charge for drugs/medicine is correct"   do
    # actual medical charges computation
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@promo_discount4 * total_drugs)
    @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "15th Availment - Employee: Checks if the actual benefit claim for drugs/medicine is correct" do
    # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim15 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim15 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim15))
  end

  it "15th Availment - Employee: Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount4 * total_xrays_lab_others)
    @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "15th Availment - Employee: Checks if the actual lab benefit claim is correct" do
    # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount4 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    @@claims_history = slmc.get_total_claims_history("oss")

    if (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims]) <= 0.0
      @@actual_lab_benefit_claim15 = 0.0
    elsif @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
      @@actual_lab_benefit_claim15 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim15 = (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
    end
    @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim15))
#      @@ph[:actual_lab_benefit_claim].should ==  ("%0.2f"%(@@lab_ph_benefit[:max_amt]))
#      @@actual_lab_benefit_claim15 = @@ph[:actual_lab_benefit_claim].to_f
  end

  it "15th Availment - Employee: Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@promo_discount4 * @@comp_operation)
    @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "15th Availment - Employee: Checks if the actual operation benefit claim is correct" do
#    if slmc.get_value("philHealthBean.rvu.code").empty? == false
#      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04.1")
#      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
#        @@actual_operation_benefit_claim15 = @@actual_operation_charges
#      else
#        @@actual_operation_benefit_claim15 = @@operation_ph_benefit[:max_amt].to_f
#      end
#      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim15))
#    else
#      @@actual_operation_benefit_claim15 = 0.00
#      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim15))
#    end
      @@actual_operation_benefit_claim15 = 1200.00
      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim15))
  end

  it "15th Availment - Employee: Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "15th Availment - Employee: Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim15 = @@actual_medicine_benefit_claim15 + @@actual_lab_benefit_claim15 + @@actual_operation_benefit_claim15
    @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim15))
  end

  it "15th Availment - Employee: Checks if the maximum benefits are correct" do
    @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "15th Availment - Employee: Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim15))
    @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim15))
    @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim15))
  end

  it "15th Availment - Employee: Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim15 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim15 = (@@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim15)
    else
      @@drugs_remaining_benefit_claim15 = 0.00
    end
    @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim15


    if @@actual_lab_benefit_claim15 < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
      @@lab_remaining_benefit_claim15 = ((@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims]) - @@actual_lab_benefit_claim15)
    else
      @@lab_remaining_benefit_claim15 = 0.00
    end
    @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim15
  end

  it "15th Availment - Employee: Checks if PF Claims for surgeon is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim15 = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
    @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim15))
  end

  it "15th Availment - Employee: Checks if PF Claims for anesthesiologist is correct" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.6")
    @@anesthesiologist_claim15 = (@@surgeon_claim15.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))
    @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim15))
  end

  it "15th Availment - Employee: Checks if Philhealth Claims is displayed in Summary Totals correctly" do
    slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim15))
  end

  it "15th Availment - Employee: Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
    puts "amount = #{slmc.get_total_amount_due}"
    puts "billing maount#{slmc.get_billing_total_amount_due}"
    slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
  end

  it "15th Availment - Employee: PhilHealth benefit claim shall not reflect in Payment details" do
    slmc.click "paymentToggle"
    (slmc.get_text('opsPaymentSummary').include? 'Philhealth').should be_false
    slmc.click "paymentToggle"
  end

  it "15th Availment - Employee: Proceed with payment successfully" do
    age = 25
       @@promo_discount2 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(age)
      if @@promo_discount2 == 0.2
        slmc.type'seniorIdNumber','123456'
      end
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  # 16th Availment
  # Account Class: Employee Dependent
  # Guarantor Type:Employee
  # Case Type: Super Catastrophic
  # Claim Type: Refund
  # With Operation: Yes
  # Diagnosis: GONOCOCCAL INFECTION OF OTHER MUSCULOSKELETAL TISSUE (A54.49)

  # 17th Availment
  # Account Class: Doctor
  # Guarantor Type:Doctor
  # Case Type: Ordinary Case
  # Claim Type: Refund
  # With Operation: No
  # Diagnosis: DENGUE HEMORRHAGIC FEVER (A91)


  it "17th Availment - Doctor: Creates new patient for OSS transactions" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @ph_patient5[:last_name])
    sleep 5
    if slmc.is_text_present(@ph_patient5[:last_name])
      @@pin5 = slmc.get_pin_from_search_results
    else
      slmc.patient_pin_search(:pin => "test")
      slmc.click_outpatient_registration.should be_true
      @@oss_pin = slmc.oss_outpatient_registration(@ph_patient5).should be_true
      @@oss_pin.should be_true
      @@pin5 = @@oss_pin.gsub(' ', '')
    end
  end

  it "17th Availment - Doctor: Searches and adds order items in the OSS outpatient order page" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin5)
    slmc.click_outpatient_order.should be_true

    @ancillary17 = {
      "010000008" => 1, #BONE IMAGING
      "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
    }
    @operation17 = {"010000160" => 1} #POLARIZING MICROSCOPY

    #add all items to be ordered
    @@orders17 =  @ancillary17.merge(@operation17)
    @@orders17.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => '0126')
    end
  end

  it "17th Availment - Doctor: Add guarantor information" do
    slmc.oss_add_guarantor(:guarantor_type =>  'DOCTOR', :acct_class => 'DOCTOR', :guarantor_code => '3798', :guarantor_add => true)
  end

  it "17th Availment - Doctor: Proceed with payment successfully" do
     amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
     #slmc.click "paymentToggle"
     sleep 4
     slmc.oss_add_payment(:amount => amount, :type => "CASH")
     sleep 2
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "17th Availment - Doctor: PBA user login and verify submitted transaction from the PhilHealth Outpatient Computation page" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@pin5).should be_true
  end

  it "17th Availment - Doctor: Click Philhealth link and input Philhealth details" do
    slmc.click_latest_philhealth_link_for_outpatient
    @@ph = slmc.philhealth_computation(:medical_case_type => "ORDINARY CASE", :diagnosis => "A91", :philhealth_id => "12345", :compute => true)
  end

  it "17th Availment - Doctor: Check Benefit Summary totals" do
    # set to 0 to initialize variables
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

    @@orders17.each do |order,n|
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
        x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "17th Availment - Doctor: Checks if the actual charge for drugs/medicine is correct"   do
    # actual medical charges computation
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@promo_discount5 * total_drugs)
    @@ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "17th Availment - Doctor: Checks if the actual benefit claim for drugs/medicine is correct" do
    # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim17 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim17 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim17))
  end

  it "17th Availment - Doctor: Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount5 * total_xrays_lab_others)
    @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "17th Availment - Doctor: Checks if the actual lab benefit claim is correct" do
    # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount5 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    @@claims_history = slmc.get_total_claims_history("philhealth")

    if @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
      @@actual_lab_benefit_claim17 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim17 = 0.00#(@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
    end
    @@ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim17))
  end

  it "17th Availment - Doctor: Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@promo_discount5 * @@comp_operation)
    @@ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "17th Availment - Doctor: Checks if the actual operation benefit claim is correct" do
    if slmc.get_value("rvu.code").empty? == false
      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
        @@actual_operation_benefit_claim17 = @@actual_operation_charges
      else
        @@actual_operation_benefit_claim17 = @@operation_ph_benefit[:max_amt].to_f
      end
      @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim17))
    else
      @@actual_operation_benefit_claim17 = 0.00
      @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim17))
    end
  end

  it "17th Availment - Doctor: Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "17th Availment - Doctor: Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim17 = @@actual_medicine_benefit_claim17 + @@actual_lab_benefit_claim17 + @@actual_operation_benefit_claim17
    @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim17))
  end

  it "17th Availment - Doctor: Checks if the maximum benefits are correct" do
    @@ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:er_max_benefit_xray_lab_others].should ==  ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "17th Availment - Doctor: Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim17))
    @@ph[:lab_deduction_claims].should == "0.00"#("%0.2f" %(@@actual_lab_benefit_claim17))
    #@@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim17))
  end

  it "17th Availment - Doctor: Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim17 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim17 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim17
    else
      @@drugs_remaining_benefit_claim17 = 0.00
    end
    @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim17

    if @@actual_lab_benefit_claim17 < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
      @@lab_remaining_benefit_claim17 = ((@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims]) - @@actual_lab_benefit_claim17)
    else
      @@lab_remaining_benefit_claim17 = 0.00
    end
    @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim17
  end

  it "17th Availment - Doctor: Checks if clicking 'Save' button saves the philhealth computation as ESTIMATE " do
    slmc.ph_save_computation
    slmc.is_text_present("ESTIMATE")
  end

  it "17th Availment - Doctor: Checks if clicking 'View details' button displays of order details" do
    slmc.ph_view_details(:close => true).should == 3
  end

  #  it "17th Availment - Doctor: Prints philhealth computation" do
  #    slmc.ph_print_report.should be_true
  #  end

  ## 18th Availment
  ## Account Class: Employee Dependent
  ## Guarantor Type:Employee
  ## Case Type: Super Catastrophic
  ## Claim Type: Refund
  ## With Operation: Yes
  ## Diagnosis: GONOCOCCAL INFECTION OF OTHER MUSCULOSKELETAL TISSUE (A54.49)

  it "18th Availment - Employee Dependent: Searches and adds order items in the OSS outpatient order page" do
    #@@pin6 = "1101504370" # Existing employee dependent of patient Tan, Peter Carlo
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.oss_advanced_search(:lastname=>"SATO",:firstname=>"RACHEL MAE",:middlename=>"CHENG")
#      if slmc.is_text_present("NO PATIENT FOUND")
#         slmc.click_outpatient_registration.should be_true
#        @@emd_pin = slmc.oss_outpatient_registration((Admission.generate_data.merge(:last_name => "SATO", :first_name => "RACHEL MAE", :middle_name => "CHENG", :birth_day => "07/26/1987", :gender => 'F'))).should be_true
#        @@pin18 = @@emd_pin.gsub(' ', '')
#      else
#        @@pin18 = slmc.get_text'css=#results>tbody>tr.odd>td:nth-child(4)' #mpi on
#        @@pin18 = @@pin18.gsub(' ','')
#      end
    @@pin18 = "1106002790"
#    slmc.patient_pin_search(:pin => @@pin6)
    slmc.click_outpatient_order.should be_true

    @ancillary18 =
      {
      "010000008" => 1, #BONE IMAGING
      "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
    }
    @operation18 = {"010000160" => 1} #POLARIZING MICROSCOPY

    #add all items to be ordered
    @@orders18 =  @ancillary18.merge(@operation18)
    n = 0
    @@orders18.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n +=1
    end
  end

  it "18th Availment - Employee Dependent: Add guarantor information" do
    slmc.oss_add_guarantor(:guarantor_type =>  'EMPLOYEE', :acct_class => 'EMPLOYEE DEPENDENT', :guarantor_code => "0109999", :guarantor_add => true)
    sleep 2
  end

  it "18th Availment - Employee Dependent: Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "18th Availment - Employee Dependent: PBA user login and verify submitted transaction from the PhilHealth Outpatient Computation page" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@pin18).should be_true
  end

  it "18th Availment - Employee Dependent: Click Philhealth link and input Philhealth details" do
    slmc.click_latest_philhealth_link_for_outpatient
    @@ph = slmc.philhealth_computation(:medical_case_type => "SUPER CATASTROPHIC CASE",
      :diagnosis => "A54.49", :rvu_code => "10060", :philhealth_id => "12345",
      :surgeon_type => "GENERAL PRACTITIONER", :anesthesiologist_type => "GENERAL PRACTITIONER", :compute => true)
  end

  it "18th Availment - Employee Dependent: Check Benefit Summary totals" do
    # set to 0 to initialize variables
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

    @@orders18.each do |order,n|
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
        x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "18th Availment - Employee Dependent: Checks if the actual charge for drugs/medicine is correct"   do
    # actual medical charges computation
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@promo_discount6 * total_drugs)
    @@ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "18th Availment - Employee Dependent: Checks if the actual benefit claim for drugs/medicine is correct" do
    # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
    if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
      @@actual_medicine_benefit_claim18 = @@actual_medicine_charges
    else
      @@actual_medicine_benefit_claim18 = @@med_ph_benefit[:max_amt].to_f
    end
    @@ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim18))
  end

  it "18th Availment - Employee Dependent: Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount6 * total_xrays_lab_others)
    @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "18th Availment - Employee Dependent: Checks if the actual lab benefit claim is correct" do
    # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount6 * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
    @@claims_history = slmc.get_total_claims_history("philhealth")

    if (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims]) <= 0.0
      @@actual_lab_benefit_claim18 = 0.0
    elsif @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
      @@actual_lab_benefit_claim18 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim18 = (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
    end
    @@ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim18))
#    @@ph[:er_actual_lab_benefit_claim].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
#    @@actual_lab_benefit_claim18 = @@ph[:er_actual_lab_benefit_claim].to_f
  end

  it "18th Availment - Employee Dependent: Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@promo_discount5 * @@comp_operation)
    @@ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "18th Availment - Employee Dependent: Checks if the actual operation benefit claim is correct" do
#    if slmc.get_value("rvu.code").empty? == false
#      @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04.1")
#      if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
#        @@actual_operation_benefit_claim18 = @@actual_operation_charges
#      else
#        @@actual_operation_benefit_claim18 = @@operation_ph_benefit[:max_amt].to_f
#      end
#      @@ph[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim18))
#    else
#      @@actual_operation_benefit_claim18 = 0.00
#      @@ph[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim18))
#    end
      @@actual_operation_benefit_claim18 = 1200.00
      @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim18))
  end

  it "18th Availment - Employee Dependent: Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "18th Availment - Employee Dependent: Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim18 = @@actual_medicine_benefit_claim18 + @@actual_lab_benefit_claim18 + @@actual_operation_benefit_claim18
    @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim18))
  end

  it "18th Availment - Employee Dependent: Checks if the maximum benefits are correct" do
    @@ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "18th Availment - Employee Dependent: Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim18))
    @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim18))
  end

  it "18th Availment - Employee Dependent: Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim18 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim18 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim18
    else
      @@drugs_remaining_benefit_claim18 = 0.00
    end
    @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim18

    if @@actual_lab_benefit_claim18 < (@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims])
      @@lab_remaining_benefit_claim18 = ((@@lab_ph_benefit[:max_amt].to_f - @@claims_history[:total_lab_claims]) - @@actual_lab_benefit_claim18)
    else
      @@lab_remaining_benefit_claim18 = 0.00
    end
    @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim18
  end

  it "18th Availment - Employee Dependent: Checks if PF Claims for surgeon is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim18 = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f

    @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim18))
  end

  it "18th Availment - Employee Dependent: Checks if PF Claims for anesthesiologist is correct" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.6")
    @@anesthesiologist_claim18 = (@@surgeon_claim18.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))

    @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim18))
  end

  it "18th Availment - Employee Dependent: Checks if clicking 'Save' button saves the philhealth computation as ESTIMATE " do
    slmc.ph_save_computation
    slmc.is_text_present("ESTIMATE")
  end

  it "18th Availment - Employee Dependent: Checks if clicking 'View details' button displays of order details" do
    slmc.ph_view_details(:close => true).should == 3
  end

  #  it "18th Availment - Employee Dependent: Prints philhealth computation" do
  #    slmc.ph_print_report.should be_true
  #  end


  it "Cancel Philhealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@pin0).should be_true
    slmc.click_latest_philhealth_link_for_outpatient
#    @@ref01 = slmc.ph_save_computation
    @@ref01  = slmc.get_text Locators::Philhealth.reference_number_label2 if slmc.is_element_present(Locators::Philhealth.reference_number_label2)
    slmc.ph_cancel_computation.should be_true
  end

  it "Recompute PhilHealth" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@pin0).should be_true
    slmc.click_latest_philhealth_link_for_outpatient
    slmc.ph_recompute.should be_true
    slmc.philhealth_computation(:case_type => "INTENSIVE CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true)

    @@ref02 = slmc.ph_save_computation
    (@@ref02 == @@ref01).should be_false
  end

  it "Edit Computed PhilHealth - Claim Type should only be Refund; Claim Type drop down should be disabled" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@pin0).should be_true
    slmc.click_latest_philhealth_link_for_outpatient
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.is_editable("claimType").should be_false
  end

  # scenario is no longer applicable
  #  it "Edit Computed PhilHealth - During printing of PhilHealth form and prooflist, user should have an option either Hospital or Patient" do
  #    slmc.click "btnPrint", :wait_for => :element, :element => "benefitCalimTypeForm"
  #    slmc.is_element_present("css=label:contains('Hospital')").should be_true
  #    slmc.is_element_present("css=label:contains('Patient')").should be_true
  #  end

  it "Edit Computed PhilHealth - View Details will display all orders made" do
    slmc.click "btnViewDetails", :wait_for => :element, :element => "philHealthDetailForm"
    orders = [ "BONE IMAGING","ADRENOMEDULLARY IMAGING-M-IBG", "POLARIZING MICROSCOPY" ] #based on orders made to @@pin
    sleep 5
    orders.each do |order|
      slmc.get_text("css=#order_detail_table_body>tr").include? order
    end
  end

  it "View Computed PhilHealth - Computed PhilHealth will be displayed" do
    slmc.go_to_patient_billing_accounting_page
    slmc.view_and_reprinting(:page => "PhilHealth", :search_options => "DOCUMENT NUMBER", :search_entry => @@ref02)
    slmc.reprint_actions("Display Details")
    slmc.is_text_present(@@ref02)
  end

  it "Edit and Compute PhilHealth in PhilHealth Outpatient Computation page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@pin0).should be_true
    slmc.click_latest_philhealth_link_for_outpatient
    slmc.philhealth_computation(:edit => true, :claim_type => "ACCOUNTS RECEIVABLE", :case_type => "INTENSIVE CASE", :diagnosis => "A83.5", :philhealth_id => "12345", :compute => true)
  end

end