#  require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Regression of Issues for Inpatient " do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @adm_patient = Admission.generate_data
    @adm_patient1 = Admission.generate_data
    @adm_patient2 = Admission.generate_data
    @adm_patient3 = Admission.generate_data
    @adm_patient4 = Admission.generate_data
    @er_patient = Admission.generate_data
    @er_patient2 = Admission.generate_data
    @user = "gu_spec_user2"
    @password = "123qweuser"
    #@pba_user = "ldcastro" #"sel_pba7"
    @pba_user = "pba1" #"sel_pba7"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


  it "Bug #40984 - ADMISSION - SS Esc No, Deposit and Department code not retainied when updating admisison of SS patient : INPATIENT ADMISSION" do
    slmc.login(@user , @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@adm_patient_pin = slmc.create_new_patient(@adm_patient).gsub(' ','')
        slmc.login(@user , @password).should be_true
    slmc.admission_search(:pin => @@adm_patient_pin).should be_true
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :esc_no => "130514AG0165", :ss_amount => "1000", :dept_code => "S - MEDICINE", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.admission_search(:pin => @@adm_patient_pin)
    slmc.click("link=Update Admission", :wait_for => :page)
    sleep 3
    slmc.get_value("escNumber").should == "130514AG0165"
    slmc.get_value("initialDeposit").should == "1000.0"
    slmc.get_value("clinicCode").should == "CC25"
  end
  it "Bug#40032 - unable to search more than 5 items in all order page" do
    slmc.login(@user , @password).should be_true
    slmc.nursing_gu_search(:pin => @@adm_patient_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@adm_patient_pin)
    slmc.click"orderType1"
    sleep 1
    slmc.click"search", :wait_for => :element, :element=> "css=#oif_finder_table_body>tr.even>td>div"
    slmc.get_css_count("css=#oif_finder_table_body>tr").should == 5
    slmc.click"//span[@id='oif_PageNumbers']/a[2]"
    slmc.get_css_count("css=#oif_finder_table_body>tr").should == 5
    slmc.click"//span[@id='oif_PageNumbers']/a[3]"
  end
  it "Bug #41508 - DON Discharge Instruction - ICD10 Description for Final Diagnosis is removed in TXN_ADM_DIAGNOSIS" do
    slmc.nursing_gu_search(:pin => @@adm_patient_pin)
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@adm_patient_pin)
    slmc.add_final_diagnosis(:diagnosis => "CHOLERA", :save => true)
    slmc.access_from_database(
      :what => "DIAGNOSIS_DESCRIPTION",
      :table => "SLMC.TXN_ADM_DIAGNOSIS",
      :column1 => "VISIT_NO",
      :condition1 => slmc.get_text("banner.visitNo"),
      :gate => "AND", :column2 => "DIAGNOSIS_CODE",
      :condition2 => "A00").should == "CHOLERA"
    slmc.type("txtFinalDiagnosis", "SELENIUM FEVER")
    slmc.click("//input[@type='button' and @value='Add']")
    sleep 3
    slmc.click("btnSave") # :wait_for => :page)
    sleep 10
    slmc.click "id=noTHM" if slmc.is_element_present("id=noTHM")
    sleep 3
    slmc.click "id=noADPA" if slmc.is_element_present("id=noADPA")
	sleep 6		
    slmc.click "id=okButton" if slmc.is_element_present("id=okButton")		
			sleep 10	
    slmc.access_from_database(
      :what => "DIAGNOSIS_DESCRIPTION",
      :table => "SLMC.TXN_ADM_DIAGNOSIS",
      :column1 => "VISIT_NO",
      :condition1 => slmc.get_text("banner.visitNo"),
      :gate => "AND", :column2 => "DIAGNOSIS_DESCRIPTION",
      :condition2 => "SELENIUM FEVER").should == "SELENIUM FEVER"
  end
  it "Bug#40984 - ADMISSION - SS Esc No, Deposit and Department code not retainied when updating admisison of SS patient : ER ADMISSION" do
    slmc.login("sel_er1", @password).should be_true
    @@er_pin = slmc.er_create_patient_record(@er_patient).gsub(' ','')
     slmc.login("sel_er1", @password).should be_true
    slmc.go_to_er_landing_page
    slmc.click"link=Patient Search"
    sleep 2
    slmc.patient_pin_search(:pin => @@er_pin)
    slmc.click"link=Register Patient"
    sleep 5
    slmc.admit_er_patient(:account_class => "SOCIAL SERVICE", :esc_no => "130815AG0342", :ss_amount => "5000", :dept_code => "L - NEUROLOGY")
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin)
    slmc.go_to_gu_page_for_a_given_pin("Update Registration", @@er_pin)
    sleep 3
    slmc.get_value("id=escNumber").should == "130815AG0342"
    slmc.get_value("id=initialDeposit").should == "5000.0"
    slmc.get_value("id=clinicCode").should == "CC16"
  end
  it "Bug #40983 - ADMISSION - Relation to Patient did not reflect in the admission preview page : Scenario1" do
    slmc.login(@user , @password).should be_true
    slmc.admission_search(:pin => "Test")
    @@adm_patient_pin1 = slmc.create_new_patient(@adm_patient1).gsub(' ','')
#        slmc.login(@pba_user, @password).should be_true
    slmc.admission_search(:pin => @@adm_patient_pin1).should be_true
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :esc_no => "130816OG0343", :ss_amount => "1000", :dept_code => "S - MEDICINE", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :relationship => "GUARANTOR", :check_relation => true).should be_true
    slmc.admission_search(:pin => @@adm_patient_pin1)
    slmc.click("link=Update Admission", :wait_for => :page)
    sleep 2
    slmc.click("name=action", :wait_for => :page)
    slmc.is_text_present("Relation to Patient: GUARANTOR").should be_true

    slmc.admission_search(:pin => "Test")
    @@adm_patient_pin2 = slmc.create_new_patient(@adm_patient2).gsub(' ','')
#        slmc.login(@pba_user, @password).should be_true
    slmc.admission_search(:pin => @@adm_patient_pin2).should be_true
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :esc_no => "130816OG0343", :ss_amount => "1000", :dept_code => "S - MEDICINE", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :relationship => "SELF", :check_relation => true).should be_true
    slmc.admission_search(:pin => @@adm_patient_pin2)
    slmc.click("link=Update Admission", :wait_for => :page)
    sleep 2
    slmc.click("name=action", :wait_for => :page)
    slmc.is_text_present("Relation to Patient: SELF").should be_true

    slmc.admission_search(:pin => "Test")
    @@adm_patient_pin3 = slmc.create_new_patient(@adm_patient3).gsub(' ','')
#        slmc.login(@pba_user, @password).should be_true
    slmc.admission_search(:pin => @@adm_patient_pin3).should be_true
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :esc_no => "130816OG0343", :ss_amount => "1000", :dept_code => "S - MEDICINE", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :relationship => "GUARANTOR", :check_relation => true).should be_true
    slmc.admission_search(:pin => @@adm_patient_pin3)
    slmc.click("link=Update Admission", :wait_for => :page)
    sleep 2
    slmc.select("guarantorRelationCode", "label=SELF")
    slmc.click("name=action", :wait_for => :page)
    slmc.is_text_present("Relation to Patient: SELF").should be_true
  end
  it "Bug#41505 - Primary Language is the same as Secondary Language after Patient Info update : INPATIENT ADMISSION" do
    slmc.login(@user , @password).should be_true
    slmc.admission_search(:pin => "Test")
    slmc.create_new_patient(@adm_patient4.merge(:primary_language => "FILIPINO", :secondary_language => "FILIPINO", :preview => true)).should == "Secondary Language is invalid."
    slmc.admission_search(:pin => "Test")
    @@adm_patient_pin4 = slmc.create_new_patient(@adm_patient4.merge(:primary_language => "FRENCH", :secondary_language => "SPANISH")).gsub(' ','')
     #   slmc.login(@pba_user, @password).should be_true
    slmc.admission_search(:pin => @@adm_patient_pin4).should be_true
    slmc.click("link=Update Patient Info", :wait_for => :page)
    sleep 40
    slmc.select("patientAdditionalDetails.primaryLanguage.code", "label=FRENCH")
    slmc.select("patientAdditionalDetails.secondaryLanguage.code", "label=SPANISH")
    slmc.click("//input[@name='action' and @value='Preview']")#, :wait_for => :page)
    sleep 10
    slmc.click "xpath=(//button[@type='button'])[3]" if slmc.is_element_present("xpath=(//button[@type='button'])[3]")
    sleep 10
    slmc.is_text_present("Primary Language: French").should be_true
    sleep 6
    slmc.is_text_present("Secondary Language: Spanish").should be_true
#    slmc.is_text_present("Primary Language: FRENCH").should be_true
#    slmc.is_text_present("Secondary Language: SPANISH").should be_true

    slmc.click("//input[@name='action' and @value='Save Patient']") #:wait_for => :page)
  end
  it "Bug #40924 - Final Diagnosis: Null Final Dx Appear" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@adm_patient_pin4).should be_true
    slmc.create_new_admission(:org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@adm_patient_pin4)
        sleep 10
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@adm_patient_pin4)
        sleep 10
    slmc.add_final_diagnosis(:diagnosis => "CHOLERA").should be_true
        sleep 10
    slmc.add_final_diagnosis(:text_final_diagnosis => "Awaiting Histopath Result").should be_true
    slmc.remove_final_diagnosis(:diagnosis => "CHOLERA").should be_false
    slmc.get_text("//html/body/div/div[2]/div[2]/form/div[3]/div/div[3]/div/table/tbody/tr[2]/td[2]/a/div").should == "Awaiting Histopath Result"
  end
  it "Bug #41464 - [PBA] Final diagnosis displays codes and \"Null\" words in Generation of SOA screen page" do
     sleep 10
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@adm_patient_pin4, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
    
#@@adm_patient_pin4 = "1601090107"
#@@visit_no1 = "5601000884"
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@adm_patient_pin4)
    slmc.go_to_page_using_visit_number("Generation of SOA", @@visit_no1)
    slmc.get_text("css=div.groupTwo>div.soaFormBelow>div.rightForm>div:nth-child(3)>div.ui").should == "A00 - CHOLERA"
  end
  it "Bug#41505 - Primary Language is the same as Secondary Language after Patient Info update : ER ADMISSION" do
    slmc.login("sel_er1", @password).should be_true
    @@er_pin2 = slmc.er_create_patient_record(@er_patient2.merge(:primary_language => "FILIPINO", :secondary_language => "FILIPINO")).should == "SecondaryLanguageisinvalid."
        sleep 10
    @@er_pin2 = slmc.er_create_patient_record(@er_patient2.merge(:primary_language => "FILIPINO", :secondary_language => "FINNISH")).gsub(' ','')
        sleep 10
     slmc.login("sel_er1", @password).should be_true
    slmc.go_to_er_landing_page
    slmc.click("link=Patient Search", :wait_for => :page)
    slmc.type("criteria", @@er_pin2)
    slmc.click("searchMPI", :wait_for => :page)
    slmc.click("link=Update Patient Info", :wait_for => :page)
    sleep 2
    slmc.select("patientAdditionalDetails.primaryLanguage.code", "label=FRENCH")
    slmc.select("patientAdditionalDetails.secondaryLanguage.code", "label=SPANISH")
    slmc.click("//input[@type='button' and @value='Save']")
    sleep 8
    slmc.click "xpath=(//button[@type='button'])[3]"
    slmc.go_to_er_landing_page
    slmc.click("link=Patient Search", :wait_for => :page)
    slmc.type("criteria", @@er_pin2)
    slmc.click("searchMPI", :wait_for => :page)
    slmc.click("link=Update Patient Info", :wait_for => :page)
        sleep 10
    slmc.get_value("patientAdditionalDetails.primaryLanguage.code").should == "LG048"
    slmc.get_value("patientAdditionalDetails.secondaryLanguage.code").should == "LG040"
  end
end