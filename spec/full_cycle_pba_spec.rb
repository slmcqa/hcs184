#!/bin/env ruby
# encoding: utf-8

require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
#require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Patient Billing and Accounting Full Cycle Process Spec" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @password = "123qweuser"
    @oss_user = "sel_oss3"
    @pba_user = "ldcastro" #role_endoresement_tagging, role_endorsement_tagging_mngr
    @misc_user = "sel_misc1"
    @inpatient_user = "gu_spec_user11"
    @pharmcy_user = "sel_pharmacy5"
  
    @adm_user = "sel_adm9" #role_endoresement_tagging, role_endorsement_tagging_mngr
    @inpatient = Admission.generate_data
    @misc_patient = Admission.generate_data

    @ancillary = {"010000317" => 1,"010000212" => 1, "010001636" =>1}
    @drugs = {"042820145" => 5,"040812131" => 6}
    @amount = "1000"

    #@misc_type = "A/P OTHERS - PATIENTSA/R - STONE TREATMENTA/R -FBGC MAB CORP.A/R OTHERS - MISCELLANEOUSA/R OTHERS-MERALCO REFUNDACCOUNTS PAYABLE - OTHERSACCOUNTS PAYABLE - PARKING LOTACCOUNTS PAYABLE CORPORATE AFFAIRS FUNDACCOUNTS PAYABLE RBD FUNDSACCRUED EXP.-ANNIVERSARY/BINGOADVANCES - SSS MATERNITYADVANCES - SSS SICKNESSADVANCES ASSOCIATED COMPANIESADVANCES-GLOBAL CITYADVERTISING AND PROMOTIONALLOW. FOR DOUBTFUL ACCTSANNIVERSARY EXPENSEAP DEPOSITS ON MEDICAL PACKAGESAP MEDICAL FUNDSAR OTHERS UTILITIESAR OTHERS EMPLOYEES ACCOUNTSBUSINESS MEETINGCONTRACTUAL SERVICECORPORATE AFFAIRS - CORPORATE COMMUNICATIONDIVIDEND INCOMEDOCTORS PROFESSIONAL FEEDONATIONDRUGS AND PHARMACEUTICALS / REBATESDUE TO CREDIT UNION/SLMCEA LOAN ASSISTANCEEARNINGS INPATIENT SERVICES - LOCALEARNINGS OUTPATIENT SERVICES - LOCALEDUCATIONAL LOAN BENEFITEMPLOYEE BENEFITSENDOWMENT FUND RESEARCH/ENDOWMENT CENTRAL DIOCESEEXCESS OF CASH ADVANCEFOOD SUPPLIESFREE SERVICES - CONTRACTUALFREE SERVICES - SOCIAL SERVICESGASOLINE AND OILGIFT CERTIFICATESHOUSEKEEPING SUPPLIESINSURANCELEGAL, AUDIT FEES AND HONORARIUMLIGHT, GAS AND WATERLINEN AND BEDDINGSMARKETING AND PUBLIC RELATIONMEAL ALLOWANCEMEDICAL AND SURGICAL SUPPLIESMEMBERSHIP AND ASSOCIATION DUESMISCELLANEOUS EXPENSEMISCELLANEOUS EXPENSE - NEW PARKINGOFFICE STATIONARY AND SUPPLIESPAG-IBIG PREMIUMPROPERTIES AND FURNISHINGSRBD TRAINING FUND ACCOUNTREPAIRS AND MAINTENANCEREPRESENTATIONRESEARCH AND DEVELOPMENTSAGIP BAYANSALARIES AND WAGESSECURITY SERVICESSPORTS AND RECREATIONSSS MEDICARE AND ECC PREMIUMSSSS SALARY LOANSUBSCRIPTION AND BOOKSTAXES, LICENCES AND PERMITSTELEPHONE AND TELEGRAPHTRAININGS AND SEMINARSTRANSPORTATIONUNIFORM"
     @misc_type =  "A/P OTHERS - PATIENTSA/R - STONE TREATMENTA/R -FBGC MAB CORP.A/R OFFICERSA/R OTHER ACCOUNTSA/R OTHERS - MISCELLANEOUSA/R OTHERS-MERALCO REFUNDACCOUNTS PAYABLE CORPORATE AFFAIRS FUNDACCOUNTS PAYABLE RBD FUNDSADVANCES - SSS MATERNITYADVANCES - SSS SICKNESSADVANCES-GLOBAL CITYADVERTISING AND PROMOTIONALLOW. FOR DOUBTFUL ACCTSANNIVERSARY EXPENSEAP DEPOSITS ON MEDICAL PACKAGESAP MEDICAL FUNDSBUSINESS MEETINGCONTIGENCYDIVIDEND INCOMEDOCTORS PROFESSIONAL FEEDONATION - FOSLDONATIONS RECEIVEDDRUGS AND PHARMACEUTICALSEMPLOYEE ACCOUNTSEMPLOYEE BENEFITSEWT - PROFESSIONAL FEESEXCESS OF CASH ADVANCEFOOD SUPPLIESFREE SERVICES - CONTRACTUALGASOLINE AND OILGIFT CERTIFICATESGUEST DEPOSIT¿HMGUEST PAYMENT(AR G-Current Tray)-HotelHOUSEKEEPING SUPPLIESINSURANCEINTEREST RECEIVABLESLIGHT, GAS AND WATERLINEN AND BEDDINGSMARKETING AND PUBLIC RELATIONMEAL ALLOWANCEMEDICAL AND SURGICAL SUPPLIESMEDICARE REFUNDMEMBERSHIP AND ASSOCIATION DUESMISC INCOME-GIFT SHOPMISCELLANEOUS INCOMEOFFICE STATIONARY AND SUPPLIESOTHER RENTAL INCOMEPAG-IBIG PREMIUMPROPERTIES AND FURNISHINGSREPAIRS AND MAINTENANCEREPRESENTATIONRESEARCH AND DEVELOPMENTSALARIES AND WAGESSSS SALARY LOANSUBSCRIPTION AND BOOKSTAXES, LICENCES AND PERMITSTelephone UsageTenants Payment of RentTRAININGS AND SEMINARSTRANSPORTATIONW/T PAYABLE - PROF. FEE"

   # @account_group = "------ Choose Account Class ------ PHILHEALTHEMPLOYEEDOCTORSHMOINDIVIDUAL WITH BALANCECOMPANY"
    @account_group ="------ CHOOSE ACCOUNT CLASS ------ PHILHEALTHEMPLOYEEDOCTORSHMOINDIVIDUAL WITH BALANCECOMPANY"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

################# Patient Billing and Accounting - View and Reprinting
  it"Create Outpatient" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    (slmc.is_element_present"//img[@src='/images/calendar.png']").should be_true
    @@oss_pin = slmc.oss_outpatient_registration(Admission.generate_data).gsub(' ', '').should be_true
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order(:pin => @@oss_pin).should be_true
    slmc.oss_patient_info(:philhealth => true)
    sleep 8
    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    @drugs.each do |item, q|
    slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
    end
    @ancillary.each do |item, q|
    slmc.oss_order(:order_add => true, :item_code => item,:filter => "CLINICAL CHEMISTRY", :quantity => q, :doctor => "5979")
    end
    @@oss_ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :claim_type=>"ACCOUNTS RECEIVABLE", :with_operation=>true, :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "59400", :compute => true)
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end
  it"Patient billing and accounting -> Payment -> Official receipt -> Document number" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.get_visit_number_using_pin(@@oss_pin)
    puts "#{@@visit_no }"
    @@doc_no = slmc.access_from_database(:what => "OR_NUMBER", :table => "TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no)
    puts "@@doc_no = #{@@doc_no}"
    
    slmc.pba_document_search(:select => "Payment", :doc_type => "OFFICIAL RECEIPT", :search_options => "DOCUMENT NUMBER",:entry => @@doc_no,:view_and_reprinting => true).should be_true
    slmc.pba_reprint_or.should be_true
  end
 
  it"Patient billing and accounting -> Payment -> Official receipt -> Document date" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "Payment", :doc_type => "OFFICIAL RECEIPT", :search_options => "DOCUMENT DATE",:view_and_reprinting => true).should be_true
    slmc.pba_reprint_or.should be_true
  end
  it"Patient billing and accounting -> Payment -> Official receipt -> PIN" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "Payment", :doc_type => "OFFICIAL RECEIPT", :search_options => "PIN",:entry => @@oss_pin,:view_and_reprinting => true).should be_true
    slmc.pba_reprint_or.should be_true
  end
  it"Patient billing and accounting -> Payment -> Official receipt -> Visit number" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "Payment", :doc_type => "OFFICIAL RECEIPT", :search_options => "VISIT NUMBER",:entry => @@visit_no,:view_and_reprinting => true).should be_true
    slmc.pba_reprint_or.should be_true
  end
  it"Patient billing and accounting -> Philhealth -> Philhealth -> Visit number" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH", :search_options => "VISIT NUMBER",:entry => @@visit_no,:view_and_reprinting => true).should be_true
    @@ph_ref_no = slmc.get_text('css=#philhealthTableBody>tr.even>td')
   #slmc.go_to_page_using_reference_number("Reprint Prooflist", @@ph_ref_no)
    slmc.select "css=#philhealthTableBody>tr>td:nth-child(8)>select", "Reprint Prooflist"
    slmc.click  "//input[@value='Submit']"#, :wait_for => :page # it hangs
    sleep 10
    slmc.get_text('css=div[id="breadCrumbs"]').should == "Patient Billing and Accounting Home › Document Search"
  end
  it"Patient billing and accounting -> Philhealth -> Philhealth -> Document date" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH", :search_options => "DOCUMENT DATE",:view_and_reprinting => true).should be_true
    #slmc.go_to_page_using_reference_number("Reprint Prooflist", @@ph_ref_no)
    slmc.select "css=#philhealthTableBody>tr>td:nth-child(8)>select", "Reprint Prooflist"
    slmc.click  "//input[@value='Submit']"#, :wait_for => :page # it hangs
    sleep 10
    slmc.get_text('css=div[id="breadCrumbs"]').should == "Patient Billing and Accounting Home › Document Search"
  end
  it"Patient billing and accounting -> Philhealth -> Philhealth -> Pin" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH", :search_options => "PIN",:entry => @@oss_pin,:view_and_reprinting => true).should be_true
    #slmc.go_to_page_using_reference_number("Reprint Prooflist", @@ph_ref_no)
    slmc.select "css=#philhealthTableBody>tr>td:nth-child(8)>select", "Reprint Prooflist"
    slmc.click  "//input[@value='Submit']"#, :wait_for => :page # it hangs
    sleep 10
    slmc.get_text('css=div[id="breadCrumbs"]').should == "Patient Billing and Accounting Home › Document Search"
  #  (slmc.get_text"documentTypes").should == "PHILHEALTH PHILHEALTH MULTIPLE SESSION"
        (slmc.get_text"documentTypes").should == "REFUND PHILHEALTH OFFICIAL RECEIPT DISCOUNT ROOM AND BOARD CHARGE INVOICE ORDER NO. OFFICIAL SOA PHILHEALTH MULTIPLE SESSION"

  end
  it"Create patient for refund deleting" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@pin = slmc.create_new_patient(Admission.generate_data).gsub(' ', '')
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 2
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
    slmc.nursing_gu_search(:pin=> @@pin)
    @@pin_visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Payment", @@pin_visit_no)
    slmc.pba_hb_deposit_payment(:deposit => true, :cash => "1000")
    @@or_no1 = slmc.access_from_database(:what => "OR_NUMBER",:table => "TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@pin_visit_no)
    slmc.go_to_patient_billing_accounting_page
  end
  it"Patient billing and accounting -> Refund -> Edit Refund details from list" do
    slmc.click "link=Refund", :wait_for => :page
    slmc.type "orNo", @@or_no1
    sleep 1
    slmc.click"//img[@class='edit icon' and @src='/images/pencil.gif']"
    sleep 1
    amount = slmc.get_value"docAmountInput"
    slmc.type"docAmountInput", (amount.to_i -  100) #should not exceed to original cm amount
    slmc.click'//input[@id="add" and @value="Add"]'
    (slmc.get_text"docAmountInput0").should_not == amount
  end
  it "Patient billing and accounting -> Refund -> Delete Refund details from list" do
#    slmc.click"//img[@class='delete icon' and @src='/images/trash.jpg']"
    slmc.click("css=img.delete.icon");

    (slmc.is_element_present"css=#detailsList>tr>td").should be_false
  end
  it"Create patient for refund and soa" do
    sleep 6
    slmc.login(@inpatient_user, @password).should be_true
    slmc.login("adm1", @password).should be_true
    slmc.admission_search(:pin => "test")
    @@inpatient_pin = slmc.create_new_patient(@inpatient).gsub(' ', '')

    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => @@inpatient_pin)
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    sleep 6
     slmc.login("10thnw","123qweuser").should be_true
    slmc.nursing_gu_search(:pin => @@inpatient_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@inpatient_pin)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item,:quantity => q, :add => true, :doctor => "0126").should be_true
    end
    sleep 2
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
    slmc.nursing_gu_search(:pin=> @@inpatient_pin)
    @@inpatient_visit_no = slmc.clinically_discharge_patient(:pin => @@inpatient_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("Payment", @@inpatient_visit_no)
    slmc.pba_hb_deposit_payment(:deposit => true, :cash => "10000")
    @@or_no = slmc.access_from_database(:what => "OR_NUMBER",:table => "TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@inpatient_visit_no)
    slmc.go_to_patient_billing_accounting_page
    puts "@@inpatient_pin #{@@inpatient_pin}"
    puts "@@inpatient_visit_no = #{@@inpatient_visit_no}"
    puts "@@or_no - #{@@or_no}"

  end
  it"Patient billing and accounting -> Refund -> Refund -> Visit number" do
    slmc.pba_refund(:or_no => @@or_no, :reason => "OVERPAYMENT", :status => "PAID", :submit => true, :successful_refund => true).should == "Refund information successfully saved!"
    slmc.get_confirmation if slmc.is_confirmation_present
    sleep 5
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search_view_and_reprinting(:refund => "Refund", :doc_type => "REFUND", :search_options => "VISIT NUMBER",:entry => @@inpatient_visit_no, :print => true).should be_true
  end
  it"Patient billing and accounting -> Refund -> Refund -> Document number" do
    sleep 5
    @@doc_no = slmc.access_from_database(:what => "REFUND_SLIP_NO",:table => "TXN_PBA_REFUND_HDR", :column1 => "VISIT_NO", :condition1 => @@inpatient_visit_no)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search_view_and_reprinting(:refund => "Refund", :doc_type => "REFUND", :search_options => "DOCUMENT NUMBER",:entry => @@doc_no).should be_true
  end
  it"Patient billing and accounting -> Refund -> Refund -> Document date" do
    slmc.click"popup_ok" if slmc.is_element_present"popup_ok"
    sleep 2
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search_view_and_reprinting(:refund => "Refund", :doc_type => "REFUND", :search_options => "DOCUMENT DATE").should be_true
 #   (slmc.get_text"documentTypes").should == "REFUND"
        (slmc.get_text"documentTypes").should ==  "REFUND PHILHEALTH OFFICIAL RECEIPT DISCOUNT ROOM AND BOARD CHARGE INVOICE ORDER NO. OFFICIAL SOA PHILHEALTH MULTIPLE SESSION"
  end
  it"Create patient for generation of soa" do
       slmc.login(@inpatient_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@inpatient_visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.click_generate_official_soa.should be_true
    @@soa_no = slmc.access_from_database(:what => "SOA_NO",:table => "TXN_PBA_OFFICIAL_SOA", :column1 => "VISIT_NO", :condition1 => @@inpatient_visit_no)
  end
  it"Patient billing and accounting -> Generation of SOA -> Official Soa -> Document number" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search_view_and_reprinting(:soa => "Generation of SOA", :doc_type => "OFFICIAL SOA", :search_options => "DOCUMENT NUMBER",:entry => @@soa_no, :itemized => true, :submit => true).should be_true
  end
  it"Patient billing and accounting -> Generation of SOA -> Official Soa -> Document date" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search_view_and_reprinting(:soa => "Generation of SOA", :doc_type => "OFFICIAL SOA", :search_options => "DOCUMENT DATE", :summarized => true, :submit => true).should be_true
  end
  it"Patient billing and accounting -> Generation of SOA -> Official Soa -> Pin" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search_view_and_reprinting(:soa => "Generation of SOA", :doc_type => "OFFICIAL SOA", :search_options => "PIN",:entry => @@inpatient_pin, :itemized => true, :submit => true).should be_true
  end
  it"Patient billing and accounting -> Generation of SOA -> Official Soa -> Visit number" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search_view_and_reprinting(:soa => "Generation of SOA", :doc_type => "OFFICIAL SOA", :search_options => "VISIT NUMBER",:entry => @@inpatient_visit_no, :summarized => true, :submit => true).should be_true
    (slmc.get_text"documentTypes").should == "OFFICIAL SOA"
  end
### Billing and Account Services - Update Patient Information (Guarantor)
  it"Billing and Account Services - Update Patient Information (Guarantor)" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@inpatient_pin1 = slmc.create_new_patient(Admission.generate_data).gsub(' ', '')
#    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => @@inpatient_pin1)
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@inpatient_pin1)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@inpatient_pin1)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 2
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
    slmc.nursing_gu_search(:pin=> @@inpatient_pin1)
    @@inpatient_visit_no1 = slmc.clinically_discharge_patient(:pin => @@inpatient_pin1, :pf_type => "COLLECT", :pf_amount => '1000', :no_pending_order => true, :save => true)
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin1)
    slmc.go_to_page_using_visit_number("Update Patient Information", @@inpatient_visit_no1)
  end
  it"Update Patient Information (Guarantor) - Display Account Class in dropdown" do
    (slmc.get_text"accountClass").should == "BOARD MEMBERBOARD MEMBER DEPENDENTCOMPANYDOCTORDOCTOR DEPENDENTEMPLOYEEEMPLOYEE DEPENDENTHMOINDIVIDUALSOCIAL SERVICEWOMEN'S BOARD DEPENDENTWOMEN'S BOARD MEMBER"
  end
  it"Update Patient Information (Guarantor) - Display PF/Doctors" do
    (slmc.get_text"css=#row>thead>tr").should == "Doctor Code Name Doctor Type PF Instruction Amount"
    (slmc.get_text"css=#row>tbody>tr.even>td").should == "1008"
    (slmc.get_text"css=#row>tbody>tr.odd>td:nth-child(4)").should == "DIRECT COLLECT COMPLIMENTARY PROFESSIONAL FEE WITH PROMISSORY NOTE PF INCLUSIVE OF PACKAGE"
  end
  it"Update Patient Information (Guarantor) - Tag Include PF" do
    slmc.click_guarantor_to_update
    slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL",:include_pf => true, :include_pf_doctor => true, :max_pf_coverage => "50")
    slmc.click_submit_changes.should be_true
  end
  it"Discount - Search & Select Department" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin1)
    slmc.go_to_page_using_visit_number("Discount", @@inpatient_visit_no1)
    slmc.select"discountScopeField","PER DEPARTMENT"
    slmc.click"deptBtn", :wait_for => :element, :element => "orderGroupDiscountFinderForm"
    sleep 1
    slmc.click'//input[@type="button" and @onclick="DF.close()"]'
  end
  it"Discount - Search & Select Service/Item" do
    slmc.select"discountScopeField","PER SERVICE"
    slmc.click"serviceBtn", :wait_for => :element, :element => "orderDetailDiscountFinderForm"
    sleep 1
    slmc.click'//input[@type="button" and @onclick="ODF.close()"]'
  end
  it"Discount - Edit discount from list" do
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "PER DEPARTMENT", :discount_type => "Fixed", :close_window => true, :discount_rate => "100").should be_true
    slmc.delete_discount.should be_true
  end
### Billing and Account Services - Payment
  it"Payment - Remove check payment from list" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@inpatient_visit_no1)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
    sleep 2
    slmc.click"checkPaymentMode1",:wait_for => :element, :element => "cBankName"
    sleep 2
    (slmc.is_checked"checkPaymentMode1").should be_true
    slmc.type"cBankName","BANK"
    slmc.type"cCheckAmount","800"
    slmc.type"cCheckNo","1234097845"
    slmc.type"//input[@id='cCheckDate' and @type='text']", Time.now.strftime("%m/%d/%Y")
    slmc.click"addCheckPayment",:wait_for => :element, :element => "checkPayment0"
    slmc.click"checkPayment0",:wait_for => :element, :element => "removeCheckPayment"
    sleep 1
    (slmc.is_checked"checkPayment0").should be_true
    slmc.click"removeCheckPayment"
    sleep 2
    (slmc.is_element_present "checkPayment0").should be_false
    slmc.click"checkPaymentMode1"
    sleep 2
    (slmc.is_checked"checkPaymentMode1").should be_false
  end
  it"Payment - Remove credit card payment from list" do
    slmc.click"creditCardPaymentMode1",:wait_for => :element, :element => "ccCompany"
    sleep 2
    (slmc.is_checked"creditCardPaymentMode1").should be_true
    slmc.select"ccCompany","SELENIUM AUTOMATED CC - CC47622"
    slmc.select"ccType","VISA"
    slmc.type"ccNo","CC47622"
    slmc.type"ccApprovalNo","129045"
    slmc.type"ccSlipNo","0936782"
    slmc.type"ccAmount","950"
    slmc.click"addCreditCardPayment",:wait_for => :element, :element => "ccPayment0"
    slmc.click"ccPayment0",:wait_for => :element, :element => "removeCreditCardPayment"
    (slmc.is_checked"ccPayment0").should be_true
    slmc.click"removeCreditCardPayment"
    sleep 2
    (slmc.is_element_present "ccPayment0").should be_false
    slmc.click"creditCardPaymentMode1"
    sleep 2
    (slmc.is_checked"creditCardPaymentMode1").should be_false
  end
  it"Payment - Remove Bank Remittance payment to list" do
    slmc.click"bankRemittanceMode1",:wait_for => :element, :element => "brBank"
    sleep 2
    (slmc.is_checked"bankRemittanceMode1").should be_true
    slmc.type"brBank","RCBC"
    slmc.type"brBranchDeposited","ORTIGAS"
    slmc.type"brRemittanceAmount","950"
    slmc.type"brTransactionNumber","98463082"
    slmc.type"//input[@id='brTransactionDate' and @type='text']", Time.now.strftime("%m/%d/%Y")
    slmc.click"addBankRemittancePayment",:wait_for => :element, :element => "brPayment0"
    slmc.click"brPayment0",:wait_for => :element, :element => "removeBankRemitancePayment"
    (slmc.is_checked"brPayment0").should be_true
    slmc.click"removeBankRemitancePayment"
    sleep 2
    (slmc.is_element_present "brPayment0").should be_false
    slmc.click"bankRemittanceMode1"
    sleep 2
    (slmc.is_checked"bankRemittanceMode1").should be_false
  end
  it"Payment - Remove Gift Check payment to list" do
    slmc.click"giftCheckPaymentMode1",:wait_for => :element, :element => "gcNo"
    sleep 2
    (slmc.is_checked"giftCheckPaymentMode1").should be_true
    slmc.type"gcNo","79432036"
    slmc.click"addGiftCheckPayment",:wait_for => :element, :element => "gcPayment0"
    slmc.click"gcPayment0",:wait_for => :element, :element => "removeGiftCheckPayment"
    (slmc.is_checked"gcPayment0").should be_true
    slmc.click"removeGiftCheckPayment"
    sleep 2
    (slmc.is_element_present "gcPayment0").should be_false
    slmc.click"giftCheckPaymentMode1"
    sleep 2
    (slmc.is_checked"giftCheckPaymentMode1").should be_false
  end
  it"Printing Page - Print Discharge Clearance (pdf)" do
    sleep 8
    slmc.spu_hospital_bills(:type => "CASH")#.should be_true
    slmc.spu_submit_bills
    @pf_amount = (slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f) - (slmc.get_text('css=#pfDetailsDiv>table>tbody>tr.even>td:nth-child(4)').split(".")[0].gsub(",", "").split(".")[0].to_f)
    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
    slmc.click"popup_ok" if slmc.is_element_present"popup_ok"
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@inpatient_pin1)
    slmc.go_to_page_using_visit_number("Print Discharge Clearance", @@inpatient_visit_no1)
    sleep 5
  end
  it"Generate SOA -Print SOA by dept (pdf)"do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@inpatient_pin2 = slmc.create_new_patient(Admission.generate_data.merge(:gender => 'F')).gsub(' ', '')
    #slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => @@inpatient_pin2)
    slmc.create_new_admission(:room_charge=>"REGULAR PRIVATE",:rch_code=>'RCH08',:org_code=>'0287',:diagnosis=>"GASTRITIS",:package=>"PLAN A FEMALE").should == "Patient admission details successfully saved."
    slmc.login(@inpatient_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@inpatient_pin2)
    slmc.go_to_gu_page_for_a_given_pin("Package Management", @@inpatient_pin2)
    slmc.edit_package(:doctor => "6930").should be_true
    slmc.validate_package.should be_true
    slmc.validate_credentials(:username => "sel_0287_validator", :password => @password, :package => true)
    sleep 8
    slmc.nursing_gu_search(:pin=> @@inpatient_pin2)
    @@inpatient_visit_no2 = slmc.clinically_discharge_patient(:pin => @@inpatient_pin2, :no_pending_order => true, :with_complementary => true, :pf_type => "COLLECT", :pf_amount => "1000", :save => true).should be_true
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin2)
    slmc.go_to_page_using_visit_number("Generation of SOA", @@inpatient_visit_no2)
    slmc.click"//input[@type='button' and @value='Print Unofficial SOA']"
    slmc.wellness_print_soa(:soa_by_dept => true)#.should be_true
  end
  it"Generate SOA - Print Package Net SOA (pdf) – For patients under a package" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin2)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@inpatient_visit_no2)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.click"//input[@type='button' and @value='Generate Official SOA']"
    slmc.wellness_print_soa(:package_net_soa => true).should be_true
    (slmc.is_text_present"The SOA was successfully updated with printTag = 'Y'.").should be_true
  end
  it"Print Discharge Clearance (For discharged patients-pdf)" do
    slmc.skip_generation_of_soa
    slmc.spu_hospital_bills(:type => "CASH")#.should be_true
    sleep 1
    slmc.spu_submit_bills
    @pf_amount = (slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f)
    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
    slmc.click"popup_ok" if slmc.is_element_present"popup_ok"
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@inpatient_pin2)
    slmc.go_to_page_using_visit_number("Print Discharge Clearance", @@inpatient_visit_no2)
  end
  it"Adjustment and cancellation - Go to payment" do
      slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "VISIT NUMBER", :entry => @@inpatient_visit_no2).should be_true
      slmc.click "//a[@href='/pba/paymentDataEntry.html?visitNo=#{@@inpatient_visit_no2}']", :wait_for => :page
      (slmc.is_text_present"Payment Data Entry").should be_true
  end
  it"Adjustment and cancellation - Room and Board" do
    slmc.pba_adjustment_and_cancellation(:doc_type => "ROOM AND BOARD", :entry => @@inpatient_visit_no2)#.should be_true
    (slmc.is_element_present"rbTableBody").should be_true
  end
  it"View and Reprinting - Batch SOA"do
    slmc.go_to_patient_billing_accounting_page
    #slmc.click'//html/body/div/div[2]/div[2]/div[2]/div/div/ul/li[4]/ul/li[5]/a', :wait_for => :page
    slmc.click "//html/body/div/div[2]/div[2]/div[2]/div/div/ul/li[4]/ul/li[6]/a", :wait_for => :page
  end
  it"View and Reprinting - Search & Select Nursing Unit" do
    slmc.click"//input[@type='button' and @onclick='OSF.show();']", :wait_for => :element, :element=> "orgStructureFinderForm"
    slmc.type"osf_entity_finder_key","0287"
    slmc.click"//input[@type='button' and @value='Search']"
    sleep 2
    (slmc.get_value"nursingUnitCode").should == "0287"
  end
  it"View and Reprinting - Display Account Class in dropdown" do
    slmc.select"accountClass", "INDIVIDUAL"
    (slmc.get_value"accountClass").should == "IND2"
  end
  it"View and Reprinting - Display calendar pop-up" do
    (slmc.is_element_present"//img[@src='/images/calendar.png' and @alt='...']").should be_true
  end
#  it"View and Reprinting - Print Batch SOA (dot-matrix)" do # needs printer
#    slmc.view_and_reprinting_batch_soa(:itemized => true,:pdf => true).should be_true
#    sleep 5
#  end
  it"Miscellaneous Payment - A/R Payments" do
    slmc.login(@misc_user, @password).should be_true
    slmc.go_to_miscellaneous_payment_page
  end
  it"A/R Payments - Display Account Groups in dropdown"do
    slmc.click"arPayment", :wait_for => :element, :element => "accountGroup"
    (slmc.is_element_present"accountGroup").should be_true
    slmc.select"accountGroup","INDIVIDUAL WITH BALANCE"
    (slmc.get_text"accountGroup").upcase.should == @account_group
  end
  it"A/R Payments - Search & Select Guarantor" do #this will be enable when you already have selected an account group
    slmc.click"findGuarantor", :wait_for => :element, :element => "patientFinderForm"
    slmc.type"patient_entity_finder_key",@@inpatient_pin
    slmc.click"//input[@type='button' and @onclick='PF.search();' and @value='Search']", :wait_for => :element, :element => "css=#patient_finder_table_body>tr.even>td>a"
    sleep 2
    slmc.click"css=#patient_finder_table_body>tr.even>td>a" if slmc.is_visible "css=#patient_finder_table_body>tr.even>td>a"
  end
  it"A/R Payments - Display Payment Summary"do
    slmc.is_element_present"summaryDiv".should be_true
    (slmc.get_text"summaryDiv").should == "Total Cash 0.00 Total Check 0.00 Total Card 0.00 Total Bank Remittance 0.00 Total EWT 0.00"
  end
  it"A/R Payments - Submit"do
  slmc.miscellaneous_payment_data_entry(:ar => true, :pin => @@inpatient_pin, :submit => true, :cash => true, :amount => @amount).should be_true
  end
  it"Miscellaneous - Display Miscellaneous Types in dropdown" do
    slmc.go_to_miscellaneous_payment_page
    slmc.select"miscType","FOOD SUPPLIES"
  end
  it"Miscellaneous - Check for fields" do #extra checking
    (slmc.is_element_present"receivedFrom").should be_true
    (slmc.is_element_present"payeeName").should be_true
    (slmc.is_element_present"particulars").should be_true
    (slmc.is_element_present"summaryDiv").should be_true
  end
  it"Generate SOA - Print SOA by dept (pdf)" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@inpatient_pin3 = slmc.create_new_patient(Admission.generate_data).gsub(' ', '')
   # slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => @@inpatient_pin3)
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@inpatient_pin3)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@inpatient_pin3)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    sleep 2
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
    slmc.nursing_gu_search(:pin=> @@inpatient_pin3)
    @@inpatient_visit_no3 = slmc.clinically_discharge_patient(:pin => @@inpatient_pin3, :pf_type => "COLLECT", :pf_amount => '1000', :no_pending_order => true, :save => true)
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin3)
    slmc.go_to_page_using_visit_number("Generation of SOA", @@inpatient_visit_no3)
    slmc.click_print_unofficial_soa(:soa_type => 'By Department').should be_true
  end
  it "Feature #43215 - Verify Miscellaneous Type dropdown list" do
    slmc.login(@misc_user, @password).should be_true
    slmc.go_to_miscellaneous_payment_page
    (slmc.get_text"miscType").should == @misc_type

  end
  it "Feature #43215 - Verify each item in database (REF_MISC_TYPE)" do
    @@inactive_misc_type = slmc.access_from_database(:all_records => true, :what => "DESCRIPTION",:table => "REF_MISC_TYPE",:column1 => "STATUS",:condition1 => "I", :all_results => true)
    @misc_type.should_not == @@inactive_misc_type
  end
  #1st set
  it "Feature #43215 - Set Miscellaneous Type - FREE SERVICES - SOCIAL SERVICES" do
    slmc.misc_payment_content(:misc_type => "FREE SERVICES - SOCIAL SERVICES").should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - ADVANCES - SSS SICKNESS" do
    slmc.misc_payment_content(:misc_type => "ADVANCES - SSS SICKNESS").should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - EDUCATIONAL LOAN BENEFIT" do
    slmc.misc_payment_content(:misc_type => "EDUCATIONAL LOAN BENEFIT").should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - SSS SALARY LOAN" do
    slmc.misc_payment_content(:misc_type => "SSS SALARY LOAN").should be_true
  end
  it "Feature #43215 - Click Proceed with Payment button and print OR" do #the checking of samples above
    slmc.miscellaneous_payment_data_entry(:misc => true, :pin => (@misc_patient[:last_name] + " " + @misc_patient[:first_name]),
      :submit => true, :cash => true, :amount => @amount).should be_true
    slmc.click"//input[@type='submit' and @value='Print OR']"
    slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present"popup_ok"
  end
  #2nd set
 it "Feature #43215 - Set Miscellaneous Type - FOOD SUPPLIES - Cost Center and Description are displayed and read-only" do
    slmc.go_to_miscellaneous_payment_page
    slmc.misc_payment_content(:misc_type => "FOOD SUPPLIES", :cost_center => true).should be_true
  end
 it "Feature #43215 - Set Miscellaneous Type - PAG-IBIG PREMIUM - Cost Center and Description are displayed and read-only" do
    slmc.misc_payment_content(:misc_type => "PAG-IBIG PREMIUM", :cost_center => true).should be_true
  end
 it "Feature #43215 - Set Miscellaneous Type - UNIFORM - Cost Center and Description are displayed and read-only" do
    slmc.misc_payment_content(:misc_type => "UNIFORM", :cost_center => true).should be_true
  end
 it "Feature #43215 - Set Miscellaneous Type - UNIFORM - Cost Center and Description are displayed and read-only" do
    slmc.misc_payment_content(:misc_type => "UNIFORM", :cost_center => true).should be_true
  end
 it "Feature #43215 - Cost Center - Click Proceed with Payment button and print OR" do
    slmc.miscellaneous_payment_data_entry(:misc => true, :pin => (@misc_patient[:last_name] + " " + @misc_patient[:first_name]),
      :misc_type => "UNIFORM",:submit => true, :cash => true, :amount => @amount)#.should be_true
    (slmc.is_element_present"profitCenter.errors").should be_true #this error will not exist when all data are already loaded on db, uncomment the .should be_true after fix
  end
  #3rd set
  it "Feature #43215 - Set Miscellaneous Type - MISCELLANEOUS EXPENSE" do
    slmc.go_to_miscellaneous_payment_page
    slmc.misc_payment_content(:misc_type => "MISCELLANEOUS EXPENSE", :cost_center => true,:assignment => true).should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - MISCELLANEOUS EXPENSE - NEW PARKING - Proceed with Payment button and print OR" do
    slmc.miscellaneous_payment_data_entry(:misc => true, :pin => (@misc_patient[:last_name] + " " + @misc_patient[:first_name]),
      :misc_type => "MISCELLANEOUS EXPENSE - NEW PARKING",:assignment => true,:submit => true, :cash => true, :amount => @amount)
    slmc.click"//input[@type='submit' and @value='Print OR']"
    sleep 8
    slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present"popup_ok"
    (slmc.is_text_present"The Official Receipt print tag has been set as 'Y'.").should be_true
  end
  #4th set
  it "Feature #43215 - Set Miscellaneous Type - ACCOUNTS PAYABLE CORPORATE AFFAIRS FUND" do
    slmc.go_to_miscellaneous_payment_page
    slmc.misc_payment_content(:misc_type => "ACCOUNTS PAYABLE CORPORATE AFFAIRS FUND",:assignment => true).should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - AP MEDICAL FUNDS" do
    slmc.misc_payment_content(:misc_type => "AP MEDICAL FUNDS",:assignment => true).should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - ENDOWMENT FUND RESEARCH/ENDOWMENT CENTRAL DIOCESE" do
    slmc.misc_payment_content(:misc_type => "ENDOWMENT FUND RESEARCH/ENDOWMENT CENTRAL DIOCESE",:assignment => true).should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - DUE TO CREDIT UNION/SLMCEA LOAN ASSISTANCE - Proceed with Payment button and print OR" do
    slmc.miscellaneous_payment_data_entry(:misc => true, :pin => (@misc_patient[:last_name] + " " + @misc_patient[:first_name]),
      :misc_type => "DUE TO CREDIT UNION/SLMCEA LOAN ASSISTANCE",:assignment => true,:submit => true, :cash => true, :amount => @amount)
    slmc.click"//input[@type='submit' and @value='Print OR']"
    sleep 8
    slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present"popup_ok"
    (slmc.is_text_present"The Official Receipt print tag has been set as 'Y'.").should be_true
  end
  #5th set
  it "Feature #43215 - Set Miscellaneous Type - DOCTORS PROFESSIONAL FEE" do
    slmc.go_to_miscellaneous_payment_page
    slmc.misc_payment_content(:misc_type => "DOCTORS PROFESSIONAL FEE",:assignment => true, :doctor => true).should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - DOCTORS PROFESSIONAL FEE - Required fields" do
    slmc.click"save", :wait_for => :page #proceed with payment button
    ((slmc.get_text"validationMessage.errors").include?"Doctor(s) are required for this Miscellaneous Type.").should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - DOCTORS PROFESSIONAL FEE - Proceed with Payment button and print OR" do
    slmc.miscellaneous_payment_data_entry(:misc => true, :pin => (@misc_patient[:last_name] + " " + @misc_patient[:first_name]),
      :misc_type => "DOCTORS PROFESSIONAL FEE",:doctor => true,:assignment => true,:submit => true, :cash => true, :amount => @amount)
    slmc.click"//input[@type='submit' and @value='Print OR']"
    sleep 8
    slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present"popup_ok"
    (slmc.is_text_present"The Official Receipt print tag has been set as 'Y'.").should be_true
  end
  #6th set
  it "Feature #43215 - Set Miscellaneous Type - ACCOUNTS PAYABLE – OTHERS" do
    slmc.go_to_miscellaneous_payment_page
    slmc.misc_payment_content(:misc_type => "ACCOUNTS PAYABLE - OTHERS",:tenant => true).should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - ACCOUNTS PAYABLE – OTHERS - Required fields" do
    slmc.click"save", :wait_for => :page #proceed with payment button
    (slmc.get_text"validationMessage.errors").include?"Tenant is required for this Miscellaneous Type."
  end
  it "Feature #43215 - Set Miscellaneous Type - ACCOUNTS PAYABLE – OTHERS - Click Proceed with Payment button and print OR" do
    slmc.miscellaneous_payment_data_entry(:misc => true, :pin => (@misc_patient[:last_name] + " " + @misc_patient[:first_name]),
      :misc_type => "ACCOUNTS PAYABLE - OTHERS",:tenant => true,:submit => true, :cash => true, :amount => @amount)
    slmc.click"//input[@type='submit' and @value='Print OR']"
    sleep 8
    slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present"popup_ok"
    (slmc.is_text_present"The Official Receipt print tag has been set as 'Y'.").should be_true
  end
  #7th set
  it "Feature #43215 - Set Miscellaneous Type - ACCOUNTS PAYABLE - PARKING LOT" do
    slmc.go_to_miscellaneous_payment_page
    slmc.misc_payment_content(:misc_type => "ACCOUNTS PAYABLE - PARKING LOT",:assignment => true,:tenant => true).should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - ACCOUNTS PAYABLE – OTHERS - Required fields" do
    slmc.click"save", :wait_for => :page #proceed with payment button
   (slmc.get_text"validationMessage.errors").include?"Tenant is required for this Miscellaneous Type."
  end
  it "Feature #43215 - Set Miscellaneous Type - ACCOUNTS PAYABLE - PARKING LOT - Click Proceed with Payment button and print OR" do
    slmc.miscellaneous_payment_data_entry(:misc => true, :pin => (@misc_patient[:last_name] + " " + @misc_patient[:first_name]),
      :misc_type => "ACCOUNTS PAYABLE - PARKING LOT",:tenant => true,:assignment => true,:submit => true, :cash => true, :amount => @amount)
    slmc.click"//input[@type='submit' and @value='Print OR']"
    sleep 8
    slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present"popup_ok"
    (slmc.is_text_present"The Official Receipt print tag has been set as 'Y'.").should be_true
  end
  #8th set
  it "Feature #43215 - Set Miscellaneous Type - ADVANCES ASSOCIATED COMPANIES" do
    slmc.go_to_miscellaneous_payment_page
    slmc.misc_payment_content(:misc_type => "ADVANCES ASSOCIATED COMPANIES",:tenant => true).should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - ADVANCES ASSOCIATED COMPANIES – OTHERS - Required fields" do
    slmc.click"save", :wait_for => :page #proceed with payment button
    (slmc.get_text"validationMessage.errors").include?"Tenant is required for this Miscellaneous Type."
  end
  it "Feature #43215 - Set Miscellaneous Type - ADVANCES ASSOCIATED COMPANIES- Click Proceed with Payment button and print OR" do
    slmc.miscellaneous_payment_data_entry(:misc => true, :pin => (@misc_patient[:last_name] + " " + @misc_patient[:first_name]),
      :misc_type => "ADVANCES ASSOCIATED COMPANIES",:tenant => true,:submit => true, :cash => true, :amount => @amount)
    slmc.click"//input[@type='submit' and @value='Print OR']"
    sleep 8
    slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present"popup_ok"
    (slmc.is_text_present"The Official Receipt print tag has been set as 'Y'.").should be_true
  end
  #9th set
  it "Feature #43215 - Set Miscellaneous Type - EXCESS OF CASH ADVANCE" do #ADVANCES OFFICERS AND EMPLOYEES
    slmc.go_to_miscellaneous_payment_page
    slmc.misc_payment_content(:misc_type => "EXCESS OF CASH ADVANCE").should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - EXCESS OF CASH ADVANCE - Click Proceed with Payment button and print OR" do
    slmc.miscellaneous_payment_data_entry(:misc => true, :pin => (@misc_patient[:last_name] + " " + @misc_patient[:first_name]),
      :misc_type => "EXCESS OF CASH ADVANCE",:submit => true, :cash => true, :amount => @amount)
    slmc.click"//input[@type='submit' and @value='Print OR']"
    sleep 8
    slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present"popup_ok"
    (slmc.is_text_present"The Official Receipt print tag has been set as 'Y'.").should be_true
  end
  #10th set
  it "Feature #43215 - Set Miscellaneous Type - AR OTHERS EMPLOYEES ACCOUNTS" do
    slmc.go_to_miscellaneous_payment_page
    slmc.misc_payment_content(:misc_type => "AR OTHERS EMPLOYEES ACCOUNTS").should be_true
  end
  it "Feature #43215 - Set Miscellaneous Type - AR OTHERS EMPLOYEES ACCOUNTS - Click Proceed with Payment button and print OR" do
    slmc.miscellaneous_payment_data_entry(:misc => true, :pin => (@misc_patient[:last_name] + " " + @misc_patient[:first_name]),
      :misc_type => "AR OTHERS EMPLOYEES ACCOUNTS",:submit => true, :cash => true, :amount => @amount)
    slmc.click"//input[@type='submit' and @value='Print OR']"
    sleep 8
    slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present"popup_ok"
    (slmc.is_text_present"The Official Receipt print tag has been set as 'Y'.").should be_true
  end
  it "Endorsement Tagging - Add/Edit Endorsements - SPECIAL ARRANGEMENTS" do
    slmc.login(@adm_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@pin1 = slmc.create_new_patient(Admission.generate_data).gsub(' ', '')
    slmc.login(@adm_user, @password).should be_true
    slmc.admission_search(:pin => @@pin1)
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."

    slmc.admission_search(:pin => @@pin1)
    slmc.endorsement_tagging(:endorsement_type => "SPECIAL ARRANGEMENTS", :billing => true, :add => true, :save => true).should be_true
  end
  it "Endorsement Tagging - Add/Edit Endorsements - UNSETTLED ACCOUNTS" do
    slmc.admission_search(:pin => @@pin1)
    slmc.endorsement_tagging(:endorsement_type => "UNSETTLED ACCOUNTS", :billing => true, :add => true, :save => true).should be_true
  end
  it "Endorsement Tagging - Add/Edit Endorsements - TAKE HOME MEDICINES" do
    slmc.admission_search(:pin => @@pin1)
    slmc.endorsement_tagging(:endorsement_type => "TAKE HOME MEDICINES", :billing => true, :add => true, :save => true).should be_true
  end
  it "Endorsement Tagging - Add/Edit Endorsements - WAIVED ADDITIONAL ROOM AND BOARD" do
    slmc.admission_search(:pin => @@pin1)
    slmc.endorsement_tagging(:endorsement_type => "WAIVED ADDITIONAL ROOM AND BOARD", :billing => true, :add => true, :save => true).should be_true
  end
  it "Endorsement Tagging - Print Endorsement Prooflist" do
    slmc.endorsement_tagging_print_prooflist.should be_true
  end
  it "Endorsement Tagging - Edit/Delete Endorsements" do
    slmc.click"btnEndorsementEdit_0"
    slmc.type"edit_endorsement_textarea_0","Selenium"
    (slmc.get_value"edit_endorsement_textarea_0").should == "Selenium"
    slmc.click"btnEndorsementSave_0", :wait_for => :page

    slmc.click"btnEndorsementDelete_0", :wait_for => :page
    (slmc.is_text_present"SPECIAL ARRANGEMENTS").should be_false
  end
  it "Endorsement Tagging - pba behavior" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@pin1)
    (slmc.is_element_present"endorsementMessages").should be_true
    slmc.click"//input[@type='button' and @onclick='closeEndorsementDialog();' and @value='Close']"
    sleep 2
    slmc.is_text_present"Patient Billing and Accounting Home".should be_true
  end
  it "Endorsement Tagging - admission behavior - Add endorsement" do
    slmc.login(@adm_user, @password).should be_true
    slmc.admission_search(:pin => @@pin1)
    slmc.endorsement_tagging(:endorsement_type => "SPECIAL ARRANGEMENTS", :admission => true, :add => true, :save => true).should be_true
    slmc.admission_search(:pin => @@pin1)
    slmc.click"link=View Endorsement"
    sleep 1
    (slmc.get_text"endorsementChildren").should == "1. Selenium Endorsement"
    slmc.click"//input[@type='button' and @onclick='closeEndorsementDialog();' and @value='Close']"
    sleep 2
  end
  it "Endorsement Tagging - admission behavior - Print Endorsement Prooflist" do
    slmc.click("link=Endorsement Tagging", :wait_for => :page)
    slmc.endorsement_tagging_print_prooflist.should be_true
  end
  it "Endorsement Tagging - admission behavior - View Endorsement History" do
    slmc.admission_search(:pin => @@pin1)
    slmc.view_endorsement_history(:no_result => true).should be_true
  end
end