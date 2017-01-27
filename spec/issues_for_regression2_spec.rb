  require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
#require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Issues for Regression for Version 1.4" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @user = 'billing_spec_user2'
    @dastech_user = "jtsalang"
    @password = '123qweuser'
    #@pba_user = "ldcastro" #"sel_pba7"
    @pba_user = "pba1" #"sel_pba7"
    @or_user = 'slaquino'	
    @er_user = 'sel_er1'
    @oss_user = 'jtsalang'
    @drugs =  {"040004334" => 1}
    @ancillary = {"010000003" => 1}
    @supplies = {"080200000" => 1}
    @oss_orders = {"010001662" => 1,
                        "010001525" => 1,
                        "010000007" => 2,
                        "010000009" => 3}
    @oss_doctors = ["6726","0126","6793"]
    @oss_fixed_discount = 1000.0
    @esc_no = "121024AG0012"
    @dr_user = "jpnabong" #"sel_dr4"
    @or_patient = Admission.generate_data
    @or_patient1 = Admission.generate_data
    @oss_patient = Admission.generate_data
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Bug #30586 - DAS Clinical Ordering Page: Special button when selected is not functioning as designed" do
    slmc.login(@dastech_user, @password).should be_true
    slmc.go_to_ancillary_clinical_ordering_page
    slmc.type "id=criteria", "1"
    slmc.click "name=search", :wait_for => :page


    #slmc.click Locators::OrderAdjustmentAndCancellation.clinical_order, :wait_for => :page

    count = slmc.get_css_count("css=#occupancyList>tbody>tr")
    count.times do |i|
      my_row = slmc.get_text("css=#occupancyList>tbody>tr:nth-child(#{i + 1})")
      if my_row.include?("Order Page")
        @stop_row = i
      end
    end

    slmc.select("css=#occupancyList>tbody>tr:nth-child(#{@stop_row + 1})>td:nth-child(9)>select", "Order Page")
    
    slmc.click("css=#occupancyList>tbody>tr:nth-child(#{@stop_row + 1})>td:nth-child(9)>input") #:wait_for => :page)
    sleep 5
    slmc.click "id=btn_ContinueAD" if slmc.is_element_present("id=btn_ContinueAD")
    sleep 3

    slmc.click("orderType5")
    sleep 3
    slmc.get_value("itemCodeDisplay").should == "9999"
    slmc.is_editable("itemDesc").should be_true
  end
  it "Check for admitting diganosis" do # for monitoring
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(Admission.generate_data)
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
    puts "@@pin - #{@@pin}"
    sleep 6
    @@visit_no = slmc.get_visit_number_using_pin(@@pin)
    puts  "@@visit_no - #{@@visit_no}"
    slmc.access_from_database(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).should == "GASTRITIS"
    (slmc.count_number_of_entries(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).to_i).should == 1

    slmc.admission_search(:pin => @@pin)
    slmc.click_update_admission
    slmc.click"//input[@type='button' and @onclick='Diagnosis.show();']", :wait_for => :element, :element => "diagnosisFinderForm"
    slmc.type"diagnosis_entity_finder_key", "CHOLERA"
    slmc.click"//input[@type='button' and @onclick='Diagnosis.search();' and @value='Search']", :wait_for => :element, :element => "css=#diagnosis_finder_table_body>tr.even>td:nth-child(2)>a"
    slmc.click"css=#diagnosis_finder_table_body>tr.even>td:nth-child(2)>a"
    sleep 2
    slmc.click Locators::Admission.preview_reg_action
    sleep 6
    slmc.click"//button[@type='button']", :wait_for => :page if slmc.is_element_present("//button[@type='button']")
    slmc.click"//html/body/div[5]/div[3]/div/button" ,:wait_for => :page if slmc.is_element_present("//html/body/div[5]/div[3]/div/button")


    slmc.click "//input[@value='Save Admission']", :wait_for => :page
  #  slmc.click("//input[@value='Save Admission' and @type='button' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.access_from_database(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).should == "CHOLERA"
    (slmc.count_number_of_entries(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).to_i).should == 1
  end
  it "Bug#32577 - Clinical Order - Drugs - STAT" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    slmc.search_order(:description => "049000075", :drugs => true)
    (slmc.get_value"frequencyCode").should == ""
    slmc.click"priorityCode"
    sleep 1
    (slmc.get_value"frequencyCode").should == "NOW"
  end
  it "Bug #29153 - [Red Tag Patient]: Access Denied upon clicking the \"Red Tag Patient\" button" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true)
      slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
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
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :supplies => true, :ancillary => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
    @@visit_no = slmc.get_text("banner.visitNo")

    slmc.login("sel_inhouse1", @password).should be_true
    slmc.inhouse_search(:pin => @@pin)
    slmc.go_to_inhouse_page("Redtag Patient", @@pin)
    slmc.redtag_patient(:flag => true, :remarks => "Redtag remarks sample", :save => true).should == "Please tick the check box to red tag patient."
  end
  it "Bug #28512 - [Red Tag Patient]: Created DateTime becomes null after a Red Tag patient is updated" do
    slmc.inhouse_search(:pin => @@pin)
    slmc.go_to_inhouse_page("Redtag Patient", @@pin)
    slmc.redtag_patient(:remarks => "selenium1 remarks sample", :save => true).should == "Red tag patient with visit no #{@@visit_no}"
    slmc.inhouse_search(:pin => @@pin)
    slmc.get_attribute("css=#results>tbody>tr>td>img@alt").should == "RedTag Patient"
    slmc.access_from_database(:what => "CREATED_DATETIME", :table => "SLMC.TXN_PBA_REDTAG", :column1 => "VISIT_NO", :condition1 => @@visit_no).strftime("%m/%d/%Y").should == Time.now.strftime("%m/%d/%Y")

    slmc.inhouse_search(:pin => @@pin)
    slmc.go_to_inhouse_page("Redtag Patient", @@pin)
    slmc.redtag_patient(:remarks => "selenium2 remarks sample", :save => true).should == "Red tag patient with visit no #{@@visit_no}"
    slmc.inhouse_search(:pin => @@pin)
    slmc.get_attribute("css=#results>tbody>tr>td>img@alt").should == "RedTag Patient"
    slmc.access_from_database(:what => "CREATED_DATETIME", :table => "SLMC.TXN_PBA_REDTAG", :column1 => "VISIT_NO", :condition1 => @@visit_no).strftime("%m/%d/%Y").should == Time.now.strftime("%m/%d/%Y")
  end
  it "Bug #30002 - Pretty Picture appeared after clicking Validate button in DAS Clinical Ordering Page"do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@das_pin = slmc.create_new_patient(Admission.generate_data).gsub(' ','')
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@das_pin)
    slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "GASTRITIS", :doctor_code => "0126").should == "Patient admission details successfully saved."
    slmc.login(@dastech_user, @password).should be_true
#    slmc.go_to_order_adjustment_and_cancellation
#    slmc.click_order_adjustment_quick_links(:page => "Clinical Order", :clinical_order => true).should be_true
   slmc.go_to_ancillary_clinical_ordering_page
    slmc.patient_pin_search(:pin => @@das_pin)
    slmc.go_to_fnb_page_given_pin("Order Page", @@das_pin)
    slmc.search_order(:ancillary => true, :description => "010000212").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010000212", :add => true).should be_true
    slmc.submit_added_order#.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end
#  it "Bug #28373 - [Guest Room Tagging]: Guest Room Viewing Role not working" do #temporarily removed
#    slmc.login("guest_viewer1", @password).should be_true
#    slmc.go_to_guest_viewing_landing_page.should be_true
#  end
  it "Bug #28516 - [DON] Discharge Instruction: Nurses Teaching Print action, returns error page" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin)
    slmc.add_final_diagnosis.should be_true
    slmc.type("txtFinalDiagnosis", "abcdefghij" * 30)
    (slmc.get_value("txtFinalDiagnosis").length).should == 255
    slmc.click("css=a[title=\"Medication\"] > span")
    slmc.type("name=medicationInstructions", "abcdefghij" * 100)
    slmc.get_value"name=medicationInstructions"
    slmc.click("id=btnSave", :wait_for => :page)
	slmc.click "id=noTHM" if is_element_present( "id=noTHM")
	sleep 3
	slmc.click "id=noADPA" if is_element_present( "id=noADPA")
	sleep 3		
	slmc.click "id=okButton" if is_element_present( "id=okButton")				
    slmc.is_text_present("Instructions printed successfully").should be_true
    

      
  end
#Bug #30002 - Pretty Picture appeared after clicking Validate button in DAS Clinical Ordering Page
##########  #reader's fee generate report button has been remove 1.4.2 bug#28434 and bug#28427 are not applicable
###########  it "Bug#28434 - [DAS] Readers Fee: Generating the Readers Fee report throws exception error" do
###########    slmc.login(@dastech_user, @password).should be_true
###########    slmc.go_to_readers_fee_page
###########    slmc.view_readers_fee_generate_report(:pdf => true).should be_true
###########  end
###########
###########  it "Bug#28427 - [DAS] Readers Fee: Options for Report Generation not present on dropdown list" do
###########    slmc.go_to_readers_fee_page
###########    slmc.click_readers_fee_generate_report
###########    (slmc.get_text "availableReports").should == "Reader's Fee Summary ReportRF Report on Radiology UnitsRF Report on PET & Nuclear Medicine"
###########  end

  it "Bug #29002 - [SS]: Error in changing of a patients account class from Individual to Social Service" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin2 = slmc.create_new_patient(Admission.generate_data)
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin2)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."

    slmc.login("sel_ss1", @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.ss_search(:all_patients => true, :individual => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.ss_update_account_class(:account_class => "SOCIAL SERVICE", :esc_no => @esc_no, :department_code => "A - PAIN MANAGEMENT").should == "For Account Class 'SOCIAL SERVICE', the main guarantor should be of type 'SOCIAL SERVICE'"
    slmc.click_guarantor_to_update
    slmc.pba_update_guarantor(:guarantor_type => "SOCIAL SERVICE")

  end
  it "Bug #28785 - [SS View and Reprinting]: Official Receipt from non-SS patient are also retrieved" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin3 = slmc.create_new_patient(Admission.generate_data)
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin3)
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."

    slmc.nursing_gu_search(:pin => @@pin3)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin3)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
    @@visit_no = slmc.get_text("banner.visitNo")

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@pin3)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    slmc.pba_full_payment.should be_true
    @@doc_no = slmc.access_from_database(:what => "OR_NUMBER", :table => "SLMC.TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no)

    slmc.login("sel_ss1", @password).should be_true
    slmc.go_to_social_services_landing_page
   # slmc.ss_document_search(:select => "Payment", :doc_type => "OFFICIAL RECEIPT", :search_option => "DOCUMENT NUMBER", :entry => @@doc_no).should be_true
    slmc.ss_document_search(:select => "Payment", :search_option => "DOCUMENT NUMBER", :entry => @@doc_no).should be_true
   # slmc.get_css_count("css=#orTableBody>tbody>tr").should == 1
    slmc.get_xpath_count('//*[@id="orTableBody"]').should == "1"
   # ("//html/body/div/div[2]/div[2]/div[6]/table/tbody/tr")
   ("//html/body/div/div[2]/div[2]/div[6]/table/tbody/tr")
  end
###################### manually do this, error on dr date and time.
  it "Bug #38242 - [Death Certificate(Fetal) - Notice of death checklist]Null pointer exception was encountered when p rinting notice of death checklist" do
    slmc.login(@dr_user, @password).should be_true
    @@dr_pin = slmc.or_create_patient_record(Admission.generate_data.merge!(:admit => true, :org_code => "0170", :gender => 'F')).gsub(' ', '')
      #  slmc.login("sel_dr5", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_gu_page_for_a_given_pin("Fetal Notice of Death", @@dr_pin)
    slmc.fill_up_fetal_notice_of_death_info(:save => true, :send => true).should == "Notice of Fetal Death succesfully posted (mother's pin: #{@@dr_pin})\n Notice of Fetal Death succesfully sent to Admission (mother's pin: #{@@dr_pin})"

    slmc.login(@user, @password).should be_true
    slmc.go_to_admission_page
    @@death_notice_count = slmc.get_notice_of_death_count
    slmc.go_to_notice_of_death(:for_release => true, :pin => "1", :search => true).should be_true
    slmc.go_to_admission_page
    slmc.go_to_notice_of_death(:new_notice_of_death => true, :pin => @@dr_pin, :search => true, :action => "Certificate of Fetal Death").should be_true
    slmc.go_to_admission_page
    slmc.go_to_notice_of_death(:pending_documents => true, :pin => @@dr_pin, :search => true, :action => "Notice of Death Checklist").should be_true
    slmc.go_to_admission_page
    slmc.get_notice_of_death_count.should == @@death_notice_count - 1
    slmc.go_to_admission_page
    slmc.go_to_notice_of_death(:pending_documents => true, :pin => @@dr_pin, :search => true).should be_true
    slmc.click'link=Documents Received', :wait_for => :page

    slmc.login(@dr_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    @@dr_visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@dr_visit_no)
    slmc.select_discharge_patient_type(:type => "DAS", :pf_paid => true)

    slmc.login(@user, @password).should be_true
    slmc.go_to_admission_page
    slmc.go_to_notice_of_death(:for_release => true, :pin => @@dr_pin, :search => true, :action => "Remains Release Form").should be_true
  end
  it "Check for admitting diagnosis - OR" do # for monitoring
    slmc.login(@or_user, @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true, :account_class => "HMO", :guarantor_type => "HMO", :guarantor_code => "ASAL002")).gsub(' ', '')

    @@visit_no = slmc.get_visit_number_using_pin(@@or_pin)
    slmc.access_from_database(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).should == "GASTRITIS"
    (slmc.count_number_of_entries(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).to_i).should == 1
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_gu_page_for_a_given_pin("Update Registration", @@or_pin)

    slmc.click "//input[@value='' and @type='button']", :wait_for => :text, :text => "Search For Diagnosis"
    slmc.type "diagnosis_entity_finder_key", "CHOLERA"
    slmc.click "//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']", :wait_for => :element, :element => "link=CHOLERA"
    slmc.click "link=CHOLERA"
    sleep 2
    slmc.click Locators::Admission.preview_action, :wait_for => :page
    slmc.click("//input[@value='Save' and @type='button' and @onclick='submitForm(this);']", :wait_for => :page)

    slmc.access_from_database(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).should == "CHOLERA"
    (slmc.count_number_of_entries(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).to_i).should == 1
    end
  it "Bug#36616 - Promolite Discount: Unable to add Ancillary/Procedure under Promolite-Fixed Discount" do
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => "test")
      slmc.click_outpatient_registration.should be_true
      @@oss_pin = slmc.oss_outpatient_registration(Admission.generate_data(:not_senior => true).merge(:gender => 'M')).gsub(' ','').should be_true
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@oss_pin)
      slmc.click_outpatient_order(:pin => @@oss_pin).should be_true

      slmc.oss_add_guarantor(:guarantor_type =>  "INDIVIDUAL", :acct_class => "INDIVIDUAL", :coverage_choice => "percent", :coverage_amount=> "100", :guarantor_add => true)

        n = 0
        @oss_orders.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @oss_doctors[n])
        n += 1
        end

#      slmc.oss_add_discount(:discount_type => "Early Bird Promo Discount", :scope => "ancillary", :type => "fixed", :amount => @oss_fixed_discount)
      slmc.oss_add_discount(:discount_type => "Citi Mercury Discount", :scope => "ancillary", :type => "fixed", :amount => @oss_fixed_discount)
      (((slmc.get_value"additionalDiscountTotalDisplay").gsub(',','')).to_f).should == @oss_fixed_discount
      
  end
  it "Outpatient Reprint of CHARGE INVOICE" do
    sleep 5
    #slmc.click "paymentToggle" 
    slmc.click"submitForm", :wait_for => :element, :element => "popup_ok"
    slmc.click"popup_ok", :wait_for => :page

    slmc.login(@pba_user, @password).should be_true
    slmc.pba_adjustment_and_cancellation(:doc_type => "CHARGE INVOICE", :search_option => "PIN", :entry => @@oss_pin).should be_true
    slmc.click_reprint_ci.should be_true
    @@visit_no = slmc.get_visit_number_using_pin(@@oss_pin)
    slmc.pba_adjustment_and_cancellation(:doc_type => "CHARGE INVOICE", :search_option => "VISIT NUMBER", :entry => @@visit_no).should be_true
    slmc.click_reprint_ci.should be_true
    slmc.pba_adjustment_and_cancellation(:doc_type => "CHARGE INVOICE", :search_option => "PIN", :entry => @@oss_pin).should be_true
    #slmc.get_css_count("css=#chargeInvoiceTableBody>tbody>tr").should == 5
#    slmc.get_xpath_count('//*[@id="chargeInvoiceTableBody"]').should == 5
    slmc.get_xpath_count('//*[@id="chargeInvoiceTableBody"]').should == "1"

    #("//html/body/div/div[2]/div[2]/div[6]/table/tbody/tr")
    slmc.click_reprint_ci.should be_true
    slmc.pba_adjustment_and_cancellation(:doc_type => "CHARGE INVOICE", :search_option => "VISIT NUMBER", :entry => @@visit_no).should be_true
    slmc.click_reprint_ci.should be_true
  end
  it "Check for admitting diganosis - ER turned inpatient" do # for monitoring
    slmc.login(@er_user, @password).should be_true
    @@er_pin = slmc.er_create_patient_record(Admission.generate_data(:not_senior => true))
        slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_landing_page
    slmc.er_patient_search(:pin => @@er_pin)
    slmc.click_register_patient
    slmc.spu_or_register_patient(:turn_inpatient => true, :acct_class => "INDIVIDUAL", :doctor => "6726", :preview => true, :save => true).should be_true

    @@visit_no = slmc.get_visit_number_using_pin(@@er_pin)
    slmc.login("ldvoropesa", @password).should be_true
    slmc.admission_search(:pin => @@er_pin)
    slmc.er_outpatient_to_inpatient(:pin => @@er_pin, :room_label => "REGULAR PRIVATE", :diagnosis => "GASTRITIS")
    slmc.access_from_database(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).should == "GASTRITIS"
    (slmc.count_number_of_entries(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).to_i).should == 1
    end
  it "Check for admitting diganosis - OR turned inpatient" do # for monitoring
     slmc.login(@or_user, @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient1.merge(:admit => true, :gender => 'F')).gsub(' ','')

    @@visit_no = slmc.get_visit_number_using_pin(@@or_pin)
    slmc.access_from_database(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).should == "GASTRITIS"
    (slmc.count_number_of_entries(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).to_i).should == 1
     slmc.login(@or_user, @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.outpatient_to_inpatient(@or_patient1.merge(:pin => @@or_pin, :username => 'ldvoropesa', :password => '123qweuser', :room_label => "REGULAR PRIVATE", :diagnosis => "CHOLERA")).should be_true

    slmc.access_from_database(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).should == "CHOLERA"
    (slmc.count_number_of_entries(
        :what => "DIAGNOSIS_DESCRIPTION",
        :table => "SLMC.TXN_ADM_DIAGNOSIS",
        :column1 => "VISIT_NO",
        :condition1 => @@visit_no).to_i).should == 1
  end
  
end