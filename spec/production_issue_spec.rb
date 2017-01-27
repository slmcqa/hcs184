#!/bin/env ruby
# encoding: utf-8


#require File.dirname(__FILE__) + '/../lib/slmc'

require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
require 'spec_helper'

describe "SLMC :: Issues for Regression for Version 1.4" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do {}
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @or_patient = Admission.generate_data
    @inpatient = Admission.generate_data
    @user = "gu_spec_user6"
    @er_user = "sel_er12"
    @user_adm = "adm1"
    @pba_user = "ldcastro" #"sel_pba7
     @dr_user = "jpnabong" #@dr_user

    @drugs =  {"049000075" => 1}
    @supplies = {"082400049" => 1}
    @ancillary = {"010003440" => 1}
    @oxygen = {"089500009" => 1}
    @others = {"060000676" => 1}

    @oss_drugs = {"042422511" => 1}
    @oss_drugs2 = {"042000166" => 1}

    @oss_ancillary = {"010000004" => 1}
    @oss_ancillary2 = {"010001822" => 1}
    @oss_patient = Admission.generate_data
    @er_patient = Admission.generate_data
    @doctors = ["6726","0126","6726","0126"]
#    @or_patient = Admission.generate_data
#    @or_patient1 = Admission.generate_data
#    @oss_patient = Admission.generate_data
#    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

it "2528 - PBA:Compensability Class - Yikes in Search by Discharged Date" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.click("link=Compensability Class", :wait_for => :page);
    slmc.click("css=img.ui-datepicker-trigger");
    #slmc.click("css=select.ui-datepicker-year");
    slmc.click("//html/body/div[5]/div/div/select[2]")
    slmc.select("//html/body/div[5]/div/div/select[2]", "2011")
    slmc.click("link=12");
   # slmc.type("id=timeFrom", "01:00am");
    slmc.click("xpath=(//img[@alt='...'])[2]");
                      "//html/body/div[5]/div/div/select[2]"
    slmc.select("//html/body/div[5]/div/div/select[2]","2013")
    slmc.click("link=14");
    slmc.click("name=action",:wait_for =>:page);
    slmc.is_element_present("//html/body/div/div[2]/div[2]/div[7]/div/table/tbody/tr")
  end
it "2590 - PBA: Missing Reprint CI button in the Order No search of Adjustment and Cancellation" do
    slmc.login("sel_oss5", @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@pin = (slmc.oss_outpatient_registration(@oss_patient)).gsub(' ','').should be_true
    puts @@pin
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order(:pin => @@pin).should be_true
    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    @@orders =  @oss_ancillary.merge(@oss_drugs)
    n = 0
    @@orders.each do |item, q|
          slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
          n += 1
    end
    slmc.oss_add_discount(:discount_type => "Employee Discount", :scope => "dept", :type =>"percent",:amount=>"100")
    #slmc.click("id=submitForm",:wait_for => :page);
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
		sleep 4
    Database.connect
    t = "SELECT CI_NO FROM SLMC.TXN_OM_ORDER_GRP WHERE VISIT_NO IN (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin}')"
    myci_no = Database.select_all_statement t
    Database.logoff
    myci_no =  myci_no[0]
	puts "myci_no = #{myci_no}"
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.click("link=Adjustment and Cancellation",:wait_for => :page);
    slmc.select("id=documentTypes", "label=ORDER NO.");
    sleep 3
    slmc.select("id=searchOptions", "label=DOCUMENT NUMBER");
    slmc.type("id=textSearchEntry",myci_no);
    slmc.click("id=actionButton",:wait_for => :page);
    slmc.is_text_present("REPRINT CI")
    slmc.click("link=Reprint CI",:wait_for => :page);
end
it "2584 - Pharmacy: Sales Invoice displays a 0.01 balance for Employees entitled to 100%discount" do
    slmc.login("sel_pharmacy2", @password).should be_true
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109092", :relationship => "SELF", :guarantor_add => true)
    sleep 6
  #  slmc.get_text("css=#guarantorListTableBody>tr>td:nth-child(6)").should == "REL26" # which is the SELF relationship
    slmc.is_text_present("REL26").should
    slmc.oss_order(:item_code => "VIRLIX 10mg TAB", :order_add => true).should be_true
    slmc.oss_order(:item_code => "049999",:item_desc => "VIRLIX 10mg TAB",:order_add => true, :service_rate_display => "1439.82").should be_true
    slmc.submit_order.should be_true
    #Need to check the PDF file, NEED TO ADD CODE FOR WAITING THE USER INPUT
 end
it "2535 - Admission:Can't update the patient info" do
      slmc.login(@er_user, @password).should be_true
      @@er_pin = slmc.er_create_patient_record(@er_patient.merge(:admit => true,:turn_inpatient => true)).gsub(' ','')
   #   slmc.go_to_my_update_registration(:pin =>@@er_pin, :turn_inpatient => true, :save => true)
         puts @@er_pin
      slmc.login(@user_adm, @password).should be_true
      slmc.go_to_admission_page
      slmc.click("id=patientAdmissionImg");
      sleep 6
      while slmc.is_text_present("#{@@er_pin}") == false
          slmc.click("name=next");
          sleep 10
      end
      slmc.click("link=#{@@er_pin}",:wait_for => :page)
      slmc.type("id=birthPlace", "QUEZON");
      slmc.click("xpath=(//input[@name='action'])[5]")#,:wait_for => :page)
      sleep 6
      slmc.click("xpath=(//button[@type='button'])[3]",:wait_for => :page)

      slmc.is_text_present("QUEZON")
      slmc.click("xpath=(//input[@name='action'])[2]",:wait_for => :page)
      slmc.is_text_present("Patient successfully saved.")



end
it "2556 - PBA: Error encountered in reprinting OR" do
    slmc.login("pba1", @password).should be_true
    slmc.go_to_miscellaneous_payment_page
    slmc.click("id=arPayment");
    sleep 3
    slmc.select("id=accountGroup", "label=HMO");
    slmc.click("id=findGuarantor");
    sleep 6
    slmc.type("id=bp_entity_finder_key", "MSHI001");
    sleep 3

    slmc.click("css=#bpFinderForm > div.finderFormContents > div > input[type=\"button\"]");
    sleep 3

    slmc.type("id=payeeName", "sadsd");
    sleep 3    
    slmc.type("id=particulars", "dasdsadad");
    sleep 3    
    #slmc.click("id=checkPaymentMode1");
    slmc.click "id=checkToggle"
    sleep 3
    slmc.type("id=cBankName", "METROBANK");
    sleep 3    
    #slmc.type("id=cCheckAmount", "2474724747.45");
    slmc.type("id=cCheckAmount", "747.45");
    slmc.type("id=cAccountNo", "12121");
    slmc.type("id=cCheckNo", "12232132");
    sleep 3    
    slmc.type("id=cCheckDate", "09/11/2015");
    sleep 3    
    slmc.click("id=addCheckPayment");
    sleep 10
#    slmc.click("//input[@type='submit' and @value='Proceed with Payment']")
                slmc.click("name=save")

    sleep 10
    if slmc.is_text_present("Payment Data Entry")
            slmc.click("id=findGuarantor");
            slmc.type("id=bp_entity_finder_key", "MSHI001");
            slmc.click("css=#bpFinderForm > div.finderFormContents > div > input[type=\"button\"]");
            slmc.type("id=particulars", "dasdsadad");
            slmc.click("name=save")
    #      slmc.click("//html/body/div/div[2]/div[2]/form/div[4]/input")
    end
    sleep 10
    slmc.click("name=myButtonGroup",:wait_for =>:page);
    slmc.click("id=popup_ok");
    slmc.click("id=tagOr",:wait_for =>:page);
    slmc.is_text_present("The Official Receipt print tag has been set as 'Y'.")
    Database.connect
    t = "SELECT OR_NUMBER FROM SLMC.TXN_PBA_PAYMENT_HDR WHERE PAYMENT_TRANS_HDR_NO IN (SELECT MAX(PAYMENT_TRANS_HDR_NO) FROM SLMC.TXN_PBA_CHECK_DTL)"
    myor_no = Database.select_all_statement t
    Database.logoff
    myor_no = myor_no[0]

    puts myor_no
    
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:cashier_location => "MA - Main Billing, ER Billing, Wellness" ,:select => "Payment", :doc_type => "OFFICIAL RECEIPT", :search_options => "DOCUMENT NUMBER",:entry => myor_no,:view_and_reprinting => true).should be_true
    slmc.pba_reprint_or.should be_true	

end
it "2565 - DON:After Printing Gate Pass it will return to Home page"do
      ############### GU PATIENT  ###############################
      slmc.login(@user_adm, @password).should be_true
      myinpatient =  Admission.generate_data
      @myguuser = "gu_spec_user6"
      slmc.admission_search(:pin => "test")
       @@my_pin = slmc.create_new_patient(myinpatient).gsub(' ', '')
      slmc.admission_search(:pin => @@my_pin)
      slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
      slmc.login(@myguuser, @password).should be_true
      slmc.nursing_gu_search(:pin => @@my_pin)
      slmc.go_to_gu_page_for_a_given_pin("Order Page", @@my_pin)
      @ancillary.each do |item, q|
              slmc.search_order(:description => item, :ancillary => true).should be_true
              slmc.add_returned_order(:ancillary => true, :description => item,:quantity => q, :add => true, :doctor => "0126").should be_true
      end
      sleep 2
      slmc.submit_added_order.should be_true
      slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 1
      slmc.confirm_validation_all_items.should be_true
      slmc.nursing_gu_search(:pin=> @@my_pin)
      @@inpatient_visit_no = slmc.clinically_discharge_patient(:pin => @@my_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
      sleep 6
      puts @@my_pin
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:pin => @@my_pin)
      slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
      slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
      slmc.discharge_to_payment.should be_true
      slmc.login(@myguuser, @password)
      slmc.nursing_gu_search(:pin => @@my_pin)
      slmc.print_gatepass(:no_result => true, :pin => @@my_pin).should be_true
      ############### SU PATIENT  ###############################
end
it "2583 - PBA: Cannot proceed with DAS discharge of patients due to 0.01 balance" do
      slmc.login(@user_adm, @password).should be_true
      myinpatient =  Admission.generate_data
      @myguuser = "gu_spec_user6"
      slmc.admission_search(:pin => "test")
       @@my_pin = slmc.create_new_patient(myinpatient).gsub(' ', '')
      slmc.admission_search(:pin => @@my_pin)
      slmc.create_new_admission(:account_class => "HMO", :org_code => "0287", :rch_code => "RCH08", :guarantor_code => "ASAL002",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
       slmc.login(@myguuser, @password).should be_true
      slmc.nursing_gu_search(:pin => @@my_pin)
      slmc.go_to_gu_page_for_a_given_pin("Order Page", @@my_pin)
      @ancillary.each do |item, q|
              slmc.search_order(:description => item, :ancillary => true).should be_true
              slmc.add_returned_order(:ancillary => true, :description => item,:quantity => q, :add => true, :doctor => "0126").should be_true
      end
      sleep 2
      slmc.submit_added_order.should be_true
      slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 1
      slmc.confirm_validation_all_items.should be_true
      slmc.nursing_gu_search(:pin=> @@my_pin)
     sleep 6
      @@inpatient_visit_no = slmc.clinically_discharge_patient(:pin => @@my_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
      sleep 6
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:pin => @@my_pin)
      slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
      slmc.click("name=guarantorId");
      slmc.click("id=updateLink",:wait_for =>:page);
      slmc.pba_update_guarantor(:guarantor_type =>"HMO",:guarantor_code =>"ASAL002",:loa_percent => 100).should be_true
      slmc.click_submit_changes.should be_true
      sleep 6
      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:with_discharge_notice => true, :pin => @@my_pin)
      slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
      slmc.select_discharge_patient_type(:type => "DAS", :pf_paid => true).should be_true

      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:discharged => true, :pin => @@my_pin)
      visit =  slmc.visit_number
      slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
      slmc.get_text('//*[@id="balanceDueSpan"]').should == "0.00"

      #issue 1911
      slmc.check_discharge_datetime(:visit =>visit).should be_true

      slmc.login(@myguuser, @password)
      slmc.nursing_gu_search(:pin => @@my_pin)
      slmc.print_gatepass(:no_result => true, :pin => @@my_pin).should be_true
 end
it "2579 - DON: Saved Notice of Fetal Death should be visible only to DR" do
    slmc.login(@dr_user, @password).should be_true
    @@dr_pin = slmc.or_create_patient_record(Admission.generate_data.merge!(:admit => true, :org_code => "0170", :gender => 'F')).gsub(' ', '')
    slmc.go_to_occupancy_list_page
    fetal_death_count = slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[3]/div/span")
    fetal_death_count = fetal_death_count.to_i
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_gu_page_for_a_given_pin("Fetal Notice of Death", @@dr_pin)
   # slmc.fill_up_fetal_notice_of_death_info(:save => true).should == "Notice of Fetal Death succesfully posted (mother's pin: #{@@dr_pin})\n Notice of Fetal Death succesfully sent to Admission (mother's pin: #{@@dr_pin})"
    slmc.fill_up_fetal_notice_of_death_info(:save => true).should == "Notice of Fetal Death succesfully saved (mother's pin: #{@@dr_pin})"
    slmc.go_to_occupancy_list_page
    final_fetal_death_count = slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[3]/div/span")
    final_fetal_death_count = final_fetal_death_count.to_i
    (final_fetal_death_count).should == fetal_death_count + 1
    slmc.login("sel_or1", @password).should be_true
    slmc.go_to_occupancy_list_page
    sleep 5
    slmc.is_visible("id=savedFetalDeathImg").should == false
end
it "2186 - DON SPU - Checklist Order Adjustment: Remove/ Edit is not functioning when item description has double quote" do
    slmc.login("sel_or1", @password).should be_true
@@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true, :gender => 'F')).gsub(' ', '')
puts @@or_pin
slmc.go_to_occupancy_list_page
slmc.patient_pin_search(:pin => @@or_pin)
sleep 3
slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
#@@item_code = slmc.search_service(:non_procedure => true, :description => 'ARM SPLINT PEDIA 2" X 6" W/ SLMC LOGO')
#slmc.add_returned_service(:item_code => @@item_code, :description => 'ARM SPLINT PEDIA 2" X 6" W/ SLMC LOGO')
@@item_code = slmc.search_service(:non_procedure => true, :description => 'CAS-300017-CLEAR AMPLATZ SHEATH "COOK" (PT. LITULUMAR)')
slmc.add_returned_service(:item_code => @@item_code, :description => 'CAS-300017-CLEAR AMPLATZ SHEATH "COOK" (PT. LITULUMAR)', :quantity => true)
slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
slmc.validate_orders(:supplies => true, :orders => "single").should == 1
slmc.confirm_validation_all_items.should be_true
slmc.click("link=Home",:wait_for => :page);
slmc.click("link=Order Adjustment and Cancellation",:wait_for => :page);
slmc.type("id=lastname",@@or_pin);
slmc.click("name=search",:wait_for => :page);
end
it "1911 - Discharge_datetime field or column has no value inspite of values being saved in admin_dc_datetime in TXN_ADM_DISCHARGE" do
  #add the code, after hospital bill payment
#       slmc.check_discharge_datetime(:visit =>"5301000257").should be_true
end
it "2397 - DAS OSS: Payment for bill is not sufficient" do
      @oss_patient1 = Admission.generate_data
    slmc.login("su1", @password).should be_true
    slmc.go_to_special_ancillary
    slmc.click("link=Patient Search", :wait_for => :page);
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@pin = (slmc.oss_outpatient_registration(@oss_patient1)).gsub(' ','').should be_true
    puts @@pin
    sleep 6
    slmc.click("xpath=(//input[@name='action'])[3]",:wait_for =>:page);
    sleep 6
    slmc.go_to_clinical_order_page(:pin => @@pin)
    @oss_drugs2.each do |item, q|
          slmc.search_order(:description => item, :drugs => true,:include_pharmacy => true).should be_true
          slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @oss_ancillary2.each do |item, q|
          slmc.search_order(:description => item, :ancillary => true).should be_true
          slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
     end
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true


    slmc.click("link=Add/Edit Guarantor Info",:wait_for =>:page);
    slmc.click("id=addLink",:wait_for =>:page);
    slmc.click("name=_submit",:wait_for =>:page);
    slmc.click("css=input[type=\"submit\"]",:wait_for =>:page);
    sleep 6
    slmc.is_text_present("The Patient Info was updated.")
    slmc.click("link=Hospital Bills and PF Settlement",:wait_for =>:page);
    sleep 6
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."

  end
it "2471 - Admission: Wrong display in View Confinement History" do
     @patient = Admission.generate_data
    slmc.login("adm1", @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@pin = slmc.create_new_patient(@patient).gsub(' ', '')
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.click("link=View Confinement History");
    sleep 6
    slmc.get_text('//*[@id="confinementPin"]').should == ""
    slmc.get_text('//*[@id="confinementName"]').should == ""
    slmc.get_text('//*[@id="confinementGender"]').should == ""
    slmc.get_text('//*[@id="confinementBirthdate"]').should == ""
    slmc.get_text('//*[@id="confinementAge"]').should == ""
    slmc.get_text('//*[@id="confinementNationality"]').should == ""
    slmc.get_text('//*[@id="confinementAddress"]').should == ""
    slmc.is_element_present("//html/body/div/div[2]/div[2]/div[4]/div[9]/table/tbody/tr[2]").should be_false
end
it "2592	Patient Search: Blank page" do
       mastname =[]
       Database.connect
                  a = "SELECT UPPER(LASTNAME) FROM SLMC.TXN_PATMAS "
                  mastname = Database.select_all_rows a
       Database.logoff

       Database.connect
                  x = "SELECT TO_CHAR(COUNT(*)) FROM SLMC.TXN_PATMAS"
                  count = Database.select_all_statement x
       Database.logoff
       count = count[0].to_i
       num = AdmissionHelper.range_rand(0,count).to_s
       num = num.to_i
        puts "num = #{num }"
       lastname = mastname[num]


        slmc.login("adm1", @password).should be_true
        slmc.go_to_admission_page
        slmc.type 'param', lastname
        search_button = slmc.is_element_present( '//input[@value="Search" and @type="button" and @onclick="submitPSearchForm(this);"]') ?  '//input[@value="Search" and @type="button" and @onclick="submitPSearchForm(this);"]' :  '//input[@type="submit" and @value="Search" and @name="action"]' #@name="action" in 1.4.2
        slmc.click(search_button, :wait_for => :page)
        sleep 6
        slmc.get_xpath_count("//html/body/div/div[2]/div[2]/div[21]/table/tbody/tr").should == "3"

end
it "2589	DON: Newborn Admission - Error encountered in updating newborn patient's information" do
      @dr_patient1 = Admission.generate_data
      slmc.login(@dr_user, @password).should be_true
      @@slmc_mother_pin = (slmc.or_create_patient_record(@dr_patient1.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0170'))).gsub(' ', '')
      slmc.login(@dr_user, @password).should be_true
      slmc.go_to_outpatient_nursing_page
      slmc.outpatient_to_inpatient(@dr_patient1.merge(:pin => @@slmc_mother_pin, :username => "sel_adm7", :password => @password, :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287")).should be_true
      slmc.login(@dr_user, @password).should be_true
      slmc.myregister_new_born_patient(:pin => @@slmc_mother_pin, :bdate => (Date.today).strftime("%m/%d/%Y"), :gender => "F",
              :birth_type => "SINGLE", :birth_order => "-", :delivery_type => "OTHER", :weight => 4000, :length => 54,
              :doctor_name => "ABAD", :rooming_in => true).should be_true
      slmc.register_new_born_patient(:pin => @@slmc_mother_pin, :bdate => (Date.today).strftime("%m/%d/%Y"), :gender => "F",
              :birth_type => "SINGLE", :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,
              :doctor_name => "ABAD", :rooming_in => true, :save => true)

end
it "2586	OSS Payment:Yikes in Reprint OR" do
  @oss_patient = Admission::generate_data
    slmc.login("sel_oss5", @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@pin = (slmc.oss_outpatient_registration(@oss_patient)).gsub(' ','').should be_true
    puts @@pin
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    @@orders =  "010003985"
    n = 0
    @@orders.each do |item, q|
          slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
          n += 1
    end
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      gc_no =  Time.now.strftime("%m%d%Y") + AdmissionHelper.range_rand(10,99).to_s
      slmc.oss_add_payment(:amount => amount, :type => "GIFT CHECK", :gc_denomination => "SERVICES", :gc_no => gc_no)
   # slmc.click("id=submitForm") #:wait_for => :page);
    sleep 6
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    Database.connect
    t = "SELECT CI_NO FROM SLMC.TXN_OM_ORDER_GRP WHERE VISIT_NO IN (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin}')"
    myci_no = Database.select_all_statement t
    Database.logoff
    slmc.login("sel_oss5", @password).should be_true
    slmc.go_to_oss_payment_cancellation_and_reprinting
    slmc.pos_document_search(:type =>"ORDER NO.", :doc_no => myci_no).should be_true
    slmc.click("link=Reprint OR", :wait_for => :page);
    sleep 3
    slmc.is_text_present("No Reference Document.").should be_true
end
it "2585	PBA:Adjustment and Cancellation - Missing items in Drop-Down list" do
      doc_type = "REFUND PHILHEALTH OFFICIAL RECEIPT DISCOUNT ROOM AND BOARD CHARGE INVOICE ORDER NO. OFFICIAL SOA PHILHEALTH MULTIPLE SESSION"
      slmc.login(@pba_user, @password).should be_true
      sleep 3
      slmc.go_to_patient_billing_accounting_page
      slmc.click("link=Adjustment and Cancellation",:wait_for =>:page);
      slmc.get_text('//*[@id="documentTypes"]').should == doc_type
 end


#it "2587	DAS: CULSEN2 templates - An error message Error in saving: null appears upon clicking Queue for Validation" do
#end
#2578 - DON: Gatepass - Date and time of Physical Out tagging/printing of gate pass should be displayed  11111111111111
#2554 - Pharmacy: Missing space between Quantity and Unit of Measure  11111111111111
#2551 - DAS:  Missing Suffix in patient's result print out 11111111111111
end

# 1911
#2397
#2586