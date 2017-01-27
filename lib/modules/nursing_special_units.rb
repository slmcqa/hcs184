#!/bin/env ruby
# encoding: utf-8

require File.dirname(__FILE__) + '/helpers/locators'
require File.dirname(__FILE__) + '/helpers/nursing_special_units_helper'

module NursingSpecialUnits
  include Locators::NursingSpecialUnits
  include NursingSpecialUnitsHelper

  def or_create_patient_record(options = {})
    go_to_outpatient_nursing_page
    patient_pin_search(:pin => "test") ## added search patient before create patient record - 1.3 enhancement
    pin = create_patient_record(options)
    if options[:admit]
      admit_or_patient options
    end
    return pin
  end
  def or_nb_create_patient_record(options = {})
    go_to_outpatient_nursing_page
    patient_pin_search(:pin => "test") ## added search patient before create patient record - 1.3 enhancement
    pin = create_patient_record options
    if options[:admit]
      admit_or_nb_patient options
    end
    return pin
  end
  def er_create_patient_record(options = {})
    go_to_er_page
    click 'link=Patient Search', :wait_for => :page
    patient_pin_search(:pin => "test") ## added search patient before create patient record - 1.3 enhancement
    pin = er_create_patient(options)
    if options[:admit]
      admit_er_patient(options)
    end
    pin = pin.gsub(' ','')
    return pin
    sleep Locators::NursingGeneralUnits.create_patient_waiting_time
  end
  def or_register_patient(options ={})
    go_to_outpatient_nursing_page
    patient_pin_search options
    click "link=Register Patient", :wait_for => :page
    admit_or_patient(options)
    return true if is_text_present("Patient admission details successfully saved.")
  end
  def er_register_patient(options ={})
    go_to_er_page
    click "link=Patient Search", :wait_for => :page
    patient_pin_search options
    click "link=Register Patient", :wait_for => :page
    admit_er_patient(options)
    return true if is_text_present("Patient admission details successfully saved.")
  end
  def verify_or_patient_validation(pin)
    click "link=Newborn Admission", :wait_for => :page
    if is_text_present "Mother's Information"
      click "//input[@value='Search' and @type='button' and @onclick='AF.show();']"
      sleep 2
      type "af_entity_finder_key", pin
      click "//input[@value='Search']", :wait_for => :element, :element => "link=#{pin}"
      click "link=#{pin}", :wait_for => :not_visible, :element => "link=#{pin}"
      fire_event 'roomingInFlag1', 'click'
      sleep 3
      return get_alert() if is_alert_present() # "Cannot room-in. Mother is still admitted in Special Units."
    else
      return false
    end
  end
  def er_outpatient_registration(options={})
    click("link=Outpatient Registration", :wait_for => :page) if is_element_present("link=Outpatient Registration")
    type "name.lastName", options[:last_name] if options[:last_name]
    type "name.firstName", options[:first_name] if options[:first_name]
    type "name.middleName",options[:middle_name] if options[:middle_name]
    type "birthDate", options[:birth_day]
    sleep 2
    click "genderM" if options[:gender] == "M"
    click "genderF" if options[:gender] == "F"
    click Locators::NursingSpecialUnits.or_op_reg_save_button, :wait_for => :page
    if is_element_present(Locators::Registration.outpatient_pin)
      pin = get_text(Locators::Registration.outpatient_pin).gsub(' ','')
      return pin
    else
      return false
    end
  end
  def admit_pending_patients_for_admission(options ={})
    click '//*[@id="pendingOutAdmCount"]', :wait_for => :text, :text => "Patients For Admission"
    update_patient_room_and_bed options
  end
  def outpatient_to_inpatient(options ={})
    patient_pin_search options
    click "link=Update Registration"
    sleep 6#:wait_for => :page
    click "turnedInpatientFlag1" if !is_checked("turnedInpatientFlag1")
    sleep 3
    click '//input[@value="Preview" and @onclick="submitForm(this);"]', :wait_for => :page
    click("//input[@type='button' and @value='Save' and @onclick='submitForm(this);']", :wait_for => :page) if is_element_present("//input[@type='button' and @value='Save' and @onclick='submitForm(this);']")
    click("//input[@type='button' and @value='Preview' and @name='action' and @onclick='submitForm(this);']",:wait_for => :page) if is_element_present("//input[@type='button' and @value='Preview' and @name='action' and @onclick='submitForm(this);']")


    is_text_present "Patient admission details successfully saved."
    acknowledge_inpatient options if options[:username]
  end
  def er_outpatient_to_inpatient(options ={})
    patient_pin_search options
    click "link=Update Admission", :wait_for => :page
    wait_for(:wait_for => :text, :text => "REGULAR PRIVATE")
    select "mobilizationTypeCode",options[:mobiliti_status] || "AIRLIFT"
    select "roomChargeCode", "label=#{options[:room_label]}" || "label=REGULAR PRIVATE"
    click "roomNoFinder", :wait_for => :visible, :element => "roomBedFinderForm"
    type "rbf_entity_finder_key", options[:org_code] || "0287"
    type "rbf_room_no_finder_key", "XST"
    search_button = is_element_present("//input[@value='Search' and @type='button' and @onclick='RBF.search();']") ? "//input[@value='Search' and @type='button' and @onclick='RBF.search();']" : "//input[@value='Search' and @type='button' and @onclick='RBF.searchByCondition();']"
    click search_button, :wait_for => :element, :element => Locators::Admission.room_bed
    sleep 1
    click Locators::Admission.room_bed
    is_text_present "Please select Room/Bed status:"
    sleep 2
    #click "submitPhysOut"
    click "submitRoomBedStatus"
    sleep 1
    click "//input[@value='' and @type='button']"
    type "diagnosis_entity_finder_key", "GASTRITIS"
    click "//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']", :wait_for => :element, :element => "link=#{options[:diagnosis]}"
    click "link=#{options[:diagnosis]}"
    sleep 3
    click'//img[@alt="..." and @src="/images/calendar.png"]'
    time = get_text"ui_tpicker_time_diagnosisDate"
    type"diagnosisDate",Time.now.strftime("%m/%d/%Y " + time)
    if options[:social_service]
      select"guarantorTypeCode","SOCIAL SERVICE"
    end
    type"guarantorTelNo","23907654"
    type"guarantorAddress", "123 Selenium Address"
    preview_button = is_element_present("previewAction") ? "previewAction" : "//input[@type='button' and @value='Preview' and @name='action']"
    click  preview_button
    sleep 10
    click "//button[@type='button']" if is_element_present("//button[@type='button']")

    is_text_present "Inpatient"
    sleep 15
    click "//input[@type='button' and @onclick='submitForm(this);' and @value='Save Admission']", :wait_for => :page

    is_text_present "Patient admission details successfully saved."
  end
  def acknowledge_inpatient(options ={})
    login options[:username], options[:password]   if options[:password]
    go_to_admission_page
    sleep 10
#    click "css=#pendingTurnedInpatient>a"
    click("id=patientAdmissionImg");
    while (is_element_present"link=#{options[:pin]}") == false
      #click"next"
      click("name=next");
      sleep 5
    end
    update_patient_room_and_bed options
  end
  def update_patient_room_and_bed(options ={})
    rch_code = options[:rch_code] || "RCH08"
    org_code = options[:org_code] || "0287"
    diagnosis = options[:diagnosis] || "NEWBORN"
    room = options[:room_label] || "REGULAR PRIVATE"
    mobilization = options[:mobility_status] || "AIRLIFT"
    click "link=#{options[:pin]}", :wait_for => :page
    sleep 5
    if is_text_present("Patient Information")

    end
    #completing the registration from information
    self.populate_patient_info options # r28125 v1.4 modification
    #proceed with admission
    click "xpath=(//input[@name='action'])[4]", :wait_for => :page
#    click '//input[@type="button" and @value="Proceed to Create New Admission" and @onclick="submitForm(this);"]', :wait_for => :page
    #click("css=#controls > input[name=\"action\"]", :wait_for => :page) if is_element_present("css=#controls > input[name=\"action\"]")


    wait_for(:wait_for => :text, :text => "REGULAR PRIVATE")
    select "mobilizationTypeCode", "label=#{mobilization}"
    select "roomChargeCode", "label=#{room}"
    click "roomNoFinder"
    type "rbf_entity_finder_roomChargeCode",rch_code
    type "rbf_entity_finder_key", org_code
    type "rbf_room_no_finder_key", "XST" # manually added room exclusively for automation
    click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']", :wait_for => :element, :element => Locators::Admission.room_bed
    sleep 1
    click Locators::Admission.room_bed
    sleep 3
    select "previousRoomBedStatus", "AVAILABLE"
    click "submitRoomBedStatus"
    sleep 3
    click "//input[@value='' and @type='button']"
    type "diagnosis_entity_finder_key", diagnosis
    click "//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']", :wait_for => :element, :element => "link=#{diagnosis}"
    click "link=#{diagnosis}"
    sleep 6
    click "//input[@id='submitRoomBedStatus']" if is_element_present "previousRoomBedStatusPopupDiv"
    #click "previewAction", :wait_for => :page
    type "guarantorTelNo","23907654"
    type "guarantorAddress","98 Selenium Address"
    click"name=action"  if is_element_present "name=action"
    sleep 10
    click("//button[@type='button']", :wait_for => :pgae) if is_element_present("//button[@type='button']")

    sleep 10
    a = is_text_present("Inpatient")
#    click"//input[@value='Save and Print Admission']" if is_element_present("//input[@value='Save and Print Admission']")
#
    click("//input[@value='Save Admission']") if is_element_present("//input[@value='Save Admission']")
    sleep 30
    #click "//input[@type='button' and @value='Preview' and @onclick='submitForm(this);']", :wait_for => :page if is_element_present("//input[@type='button' and @value='Preview' and @onclick='submitForm(this);']")



    #click "//input[@type='button' and @value='Save Admission' and @onclick='submitForm(this);']", :wait_for => :page
    b = is_text_present "Patient admission details successfully saved."
    return a && b
  end
  def register_new_born_patient(options ={})
    go_to_outpatient_nursing_page
    room_charge = options[:room_charge] || "REGULAR PRIVATE"
    click "link=Newborn Admission", :wait_for => :page
    if is_text_present "Mother's Information"
      click "//input[@value='Search' and @type='button' and @onclick='AF.show();']"
      sleep 5
      type "af_entity_finder_key", options[:pin]
      click "//input[@value='Search' and @onclick='AF.search();']"  
      sleep 5
      if is_text_present  "1 item(s). Displaying 1 to 1."
        click "link=#{options[:pin]}"
      end
    end
    sleep 5
    click "personToNotify" if !is_checked("personToNotify")
    gender = options[:gender]
    click "genderMale" || "genderFemale" # for randomization if no gender is given
    click "genderMale" if gender == "M"
    click "genderFemale" if gender == "F"
    type "birthDate", options[:bdate]
    select("birthHour", "12")
    select("birthMinute", "0")
    select("birthSecond", "0")
    select("birthAMPM", "AM")
    select "birthType.code", "label=#{options[:birth_type]}" || "SINGLE"
    select "birthOrder.code", "label=#{options[:birth_order]}" || "FIRST"
    select "deliveryType.code", "label=#{options[:delivery_type]}" || "OTHER"
    select "apgarScore", "label=5"
    type "aog", options[:aog] || "SELENIUM AOG"
    type "weight", options[:weight]
    type "length", options[:length]
    click "//input[@type='button' and @onclick='DF.show();']"
    type "entity_finder_key", options[:doctor_name]
    click "//input[@value='Search' and @type='button' and @onclick='DF.search();']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
    sleep 1
    click "//tbody[@id='finder_table_body']/tr/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
    sleep 3
    click "css=input[type=\"submit\"]" if is_element_present("css=input[type=\"submit\"]")
    sleep 3
    click "css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]" if is_element_present("css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]")
    sleep 3
    click "roomingInFlag1" if options[:rooming_in]
    click "isRoomingInFalse" if options[:newborn_inpatient_admission]
    click "leftForCare1" if options[:left_for_care]
    sleep 2
    select "roomChargeCode", "label=#{room_charge}"
    if options[:org_code] && options[:newborn_inpatient_admission]
      click "searchNursingUnitBtn"
      type "osf_entity_finder_key", options[:org_code]
      click "//input[@value='Search' and @type='button' and @onclick='OSF.search();']", :wait_for => :element, :element => "link=#{options[:org_code]}"
      sleep 2
      click "link=#{options[:org_code]}", :wait_for => :not_visible, :element => "link=#{options[:org_code]}"
      sleep 1
      #search and assign for room and bed number
      click "searchRoomBedBtn"
      sleep 5
      type "rbf_entity_finder_roomChargeCode", options[:rch_code]
      type "rbf_entity_finder_key", options [:org_code] if options[:org_code]
      type "rbf_room_no_finder_key", "XST"
      sleep 2
      click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']", :wait_for => :element, :element => Locators::Admission.room_bed
      sleep 1
      click Locators::Admission.room_bed, :wait_for => :not_visible, :element => Locators::Admission.room_bed
      sleep 3
    end
    click "personToNotify" if !is_checked("personToNotify") # person to notify.. this must be checked
    click "//input[@name='action' and @value='Preview']", :wait_for => :page

    click "//input[@name='action' and @value='Save Admission']", :wait_for => :page if options[:save]
    sleep Locators::NursingGeneralUnits.create_patient_waiting_time
    is_text_present("Patient admission details successfully saved.")
  end
  def myregister_new_born_patient(options ={})
    go_to_outpatient_nursing_page
    room_charge = options[:room_charge] || "REGULAR PRIVATE"
    click "link=Newborn Admission", :wait_for => :page
    if is_text_present "Mother's Information"
      click "//input[@value='Search' and @type='button' and @onclick='AF.show();']"
      sleep 5
      type "af_entity_finder_key", options[:pin]
      click "//input[@value='Search' and @onclick='AF.search();']"
      sleep 5
      if is_text_present  "1 item(s). Displaying 1 to 1."
        click "link=#{options[:pin]}"
      end
    end
    sleep 5
    click "personToNotify" if !is_checked("personToNotify")
    gender = options[:gender]
    click "genderMale" || "genderFemale" # for randomization if no gender is given
    click "genderMale" if gender == "M"
    click "genderFemale" if gender == "F"
    type "birthDate", options[:bdate]
    select("birthHour", "12")
    select("birthMinute", "0")
    select("birthSecond", "0")
    select("birthAMPM", "AM")
    select "birthType.code", "label=#{options[:birth_type]}" || "SINGLE"
    select "birthOrder.code", "label=#{options[:birth_order]}" || "FIRST"
    select "deliveryType.code", "label=#{options[:delivery_type]}" || "OTHER"
    select "apgarScore", "label=5"
    type "aog", options[:aog] || "SELENIUM AOG"
    type "weight", options[:weight]
    type "length", options[:length]
    click "//input[@type='button' and @onclick='DF.show();']"
    type "entity_finder_key", options[:doctor_name]
    click "//input[@value='Search' and @type='button' and @onclick='DF.search();']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
    sleep 1
    click "//tbody[@id='finder_table_body']/tr/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
    sleep 2
    click "roomingInFlag1" if options[:rooming_in]
    click "isRoomingInFalse" if options[:newborn_inpatient_admission]
    click "leftForCare1" if options[:left_for_care]
    sleep 2
    select "roomChargeCode", "label=#{room_charge}"
    if options[:org_code] && options[:newborn_inpatient_admission]
      click "searchNursingUnitBtn"
      type "osf_entity_finder_key", options[:org_code]
      click "//input[@value='Search' and @type='button' and @onclick='OSF.search();']", :wait_for => :element, :element => "link=#{options[:org_code]}"
      sleep 2
      click "link=#{options[:org_code]}", :wait_for => :not_visible, :element => "link=#{options[:org_code]}"
      sleep 1
      #search and assign for room and bed number
      click "searchRoomBedBtn"
      sleep 5
      type "rbf_entity_finder_roomChargeCode", options[:rch_code]
      type "rbf_entity_finder_key", options [:org_code] if options[:org_code]
      type "rbf_room_no_finder_key", "XST"
      sleep 2
      click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']", :wait_for => :element, :element => Locators::Admission.room_bed
      sleep 1
      click Locators::Admission.room_bed, :wait_for => :not_visible, :element => Locators::Admission.room_bed
      sleep 3
    end
    click "personToNotify" if !is_checked("personToNotify") # person to notify.. this must be checked
    click "//input[@name='action' and @value='Preview']", :wait_for => :page
    if is_text_present("Birth Order is a required field.")
            return true
    else
            return false
    end

  end
  def acknowledge_new_born(options ={})
    account_class = options[:account_class] || "INDIVIDUAL"
    mobilization = options[:mobilization] || "AIRLIFT"
    go_to_admission_page
    advance_search(options)
    click "//div[@class='search_containers']/span[2]/input", :wait_for => :page # search button under Advance Search
    newborn_pin_locator = get_text("css=#results>tbody>tr>td:nth-child(3)").gsub(' ', '')
    newborn_pin_locator = get_text("css=#results>tbody>tr>td:nth-child(4)").gsub(' ', '') if newborn_pin_locator == "SLMC_GC"
    #click "css=#pendingNewborn>a"
    sleep 6
    click "id=newbornImg"
    sleep 25
    click("link=#{newborn_pin_locator}", :wait_for => :page)
    self.populate_patient_info options
    click "//input[@value='Proceed to Create New Admission']", :wait_for => :page
    select "accountClass", account_class
    select "mobilizationTypeCode", "label=#{mobilization}"
    if options[:guarantor_code]
                click ("searchGuarantorBtn")
                if (account_class == "EMPLOYEE") || (account_class == "EMPLOYEE DEPENDENT")
                        type("employee_entity_finder_key", (options[:last_name] if options[:last_name]) || (options[:guarantor_code] if options[:guarantor_code]))
                        full_name_link = "link=#{options[:last_name].upcase}, #{options[:first_name].upcase} #{options[:middle_name].upcase}" if options[:last_name]
                        click("//input[@value='Search' and @type='button' and @onclick='EF.search();']")
                elsif account_class == "INDIVIDUAL"
                        type("patient_entity_finder_key", options[:guarantor_code]) if options[:guarantor_code]
                        click("//input[@value='Search' and @type='button' and @onclick='PF.search();']")
                elsif account_class == "HMO"
                        puts "at HMO"
                        type("bp_entity_finder_key", options[:guarantor_code]) if options[:guarantor_code]
                        click("//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']")
                        sleep 3
                        click "xpath=(//input[@type='button'])[45]"
                        sleep 3
                        Database.connect
                                a = "SELECT DOCTOR_CODE FROM SLMC.TXN_ADM_DOCTORS A JOIN SLMC.TXN_ADM_ENCOUNTER B ON A.VISIT_NO = B.VISIT_NO WHERE B.PIN IN (SELECT PIN FROM SLMC.TXN_PATMAS WHERE UPPER(LASTNAME)= '#{options[:last_name].upcase}' AND UPPER(FIRSTNAME) = '#{options[:first_name].upcase}'AND TRUNC(BIRTHDATE) = TO_DATE('#{options[:birth_day]}','MM/DD/YYYY'))"
                                #a = "SELECT DOCTOR_CODE FROM SLMC.TXN_ADM_DOCTORS A JOIN SLMC.TXN_ADM_ENCOUNTER B ON A.VISIT_NO = B.VISIT_NO WHERE B.PIN = '#{options[:last_name].upcase}'"
                                doctor_code = Database.select_statement a
                        Database.logoff
                        puts "doctor_code - #{doctor_code}"
                        #    doc_code = doctor_code
                        type "id=entity_finder_key", doctor_code
                        sleep 3
                        click "css=input[type=\"button\"]"
                        sleep 3

                else
                        type("bp_entity_finder_key", options[:guarantor_code]) if options[:guarantor_code]
                        click("//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']")
                end
                sleep 3
                click("link=#{options[:guarantor_code]}") if options[:guarantor_code]
    end
    type "guarantorTelNo", "1234567"
    sleep 5
    click "//input[@value='Preview' and @name='action']", :wait_for => :page
    click "//input[@type='button' and @value='Save Admission']", :wait_for => :page
    is_text_present "Patient admission details successfully saved."
    return newborn_pin_locator
  end
  def advanced_search(options ={})
    type "param", options[:last_name]
    click "slide-fade" if options[:advanced_search] == true
    type "fName", options[:first_name] if options[:first_name]
    type "mName", options[:middle_name] if options[:middle_name]
    type "bDate", options[:birthday] if options[:birthday]
    click "//input[@type='radio' and @value='M' and @name='gender']" if options[:gender] == "M"
    click "//input[@type='radio' and @value='F' and @name='gender']" if options[:gender] == "F"
    search_button = is_element_present("//div[@class='search_containers']/span[2]/input") ? "//div[@class='search_containers']/span[2]/input" : "//div[@id='clearButtonGroup']/input[1]"
    click search_button, :wait_for => :page
    ((get_text"css=#results>tbody>tr").include?(options[:last_name].upcase))
  end
  def search_pending_orders(pin,visit_no)
    go_to_er_landing_page
    sleep 5
    click "link=Order(s) for Validation"
    sleep 10
    while !is_text_present("#{pin}")
      click "next"
      sleep 3
    end
    click "//a[@href='/nursing/special-units/specialUnitsOrderCart.html?pin=#{pin}&visitNo=#{visit_no}']", :wait_for => :page
  end
  def or_notice_of_death(options={})
    click("savedDeathNotice")
    sleep 10
    return false if (get_text("savedDeathNoticeDlgRows").include?(options[:pin]) == false)
    click("link=#{options[:pin]}", :wait_for => :page)
    a = is_text_present("Notice of Death")
    b = is_element_present("//input[@value='Save']")
    return a && b
  end
  def get_or_pin_from_search_results
    get_text(Locators::Admission.or_admission_search_results_pin).gsub(' ', '')
  end
  def get_pin_from_search_results
    get_text(Locators::Admission.admission_search_results_pin).gsub(' ', '')
  end
  def get_newborn_pin_from_search_results
    get_text(Locators::Admission.admission_search_results_newborn_pin).gsub(' ', '')
  end
  def get_name_from_search_results
    get_text(Locators::Admission.admission_search_results_name)
  end
  def get_reg_name_from_search_results
    get_text(Locators::Admission.admission_search_results_reg_name)
  end
  def get_gender_from_search_results
    get_text(Locators::Admission.admission_search_results_gender)
  end
  def get_birthday_from_search_results
    get_text(Locators::Admission.admission_search_results_birthday)
  end
  def get_age_from_search_results
    get_text(Locators::Admission.admission_search_results_age)
  end
  def get_admission_status_from_search_results
    get_text(Locators::Admission.admission_search_results_admission_status)
  end
  def get_admission_actions_from_search_results
    get_text(Locators::Admission.admission_search_results_actions_column)
  end
  def update_patient(options={})
    is_text_present "Update Patient Info"
    click "link=Update Patient Info", :wait_for => :page
    citizenship = options[:citizenship] || "FILIPINO"
    occupation = options[:occupation] || "MANAGER"
    religion = options[:religion] || "ROMAN CATHOLIC"
    employer = options[:employer] || "G2iX"
    civil_status = options[:civil_status] || "SINGLE"
    spouse_last = options[:spouse_last] || "NA"
    spouse_first = options[:spouse_first] || "NA"
    spouse_middle = options[:spouse_middle] || "NA"
    nationality = options[:nationality] || "FILIPINO"
    is_text_present("Patient Information")
    sleep 3
    select "citizenship.code", "label=#{citizenship}"
    type "patientAdditionalDetails.occupation", "#{occupation}"
    select "religion.code", "label=#{religion}"
    type "patientAdditionalDetails.employer", "#{employer}"
    select "civilStatus.code", "label=#{civil_status}"
    type "spouseLastName", "#{spouse_last}"
    type "spouseFirstName", "#{spouse_first}"
    type "spouseMiddleName", "#{spouse_middle}"
    select "nationality.code", "label=#{nationality}"
    type "patientAddresses[2].streetNumber", "Pasig City"
    type "spouseTelephoneNum", "1234567"
    type "presentAddrNumStreet", "123 Quiet Street"
    type "presentAddrBldg", "CGS"
    type "presentAddrProvince", "Manila"
    type "presentAddrPostalCode", "1550"
    select "presentContactSelect", "label=HOME"
    type "presentContact1", "1234567"
    click "chkFillPermanentAddress"
    click "//option[@value='IDT19']"
    select "patientIds0.idTypeCode", "label=GSIS ID"
    click "//option[@value='IDT05']"
    type "patientIds0.idNo", "1234"
    type "motherLastName", "Mother"
    type "motherFirstName", "MotherFirst"
    type "motherMiddleName", "MotherMiddle"
    type "fatherLastName", "Father"
    type "fatherFirstName", "FatherFirst"
    type "fatherMiddleName", "FatherMiddle"
    click "//input[@name='action' and @value='Preview']", :wait_for => :page
    click "//input[@name='action' and @value='Save Patient']", :wait_for => :page
    is_text_present("Patient successfully saved.")
    if options[:wellness]
      go_to_wellness_package_ordering_page
      is_text_present("Wellness Patient Search")
    else
      click "//input[@value='Back to Home']", :wait_for => :page
      is_text_present("Admission")
    end
  end
  def update_newborn_info(options ={})
    go_to_admission_page
    advanced_search options
    click "link=Update Newborn Info", :wait_for => :page
    type "fatherLastName", options[:last_name_new]
    type "fatherFirstName", options[:first_name_new]
    type "fatherMiddleName", options[:middle_name_new]
    click "//input[@name='action' and @value='Submit']", :wait_for => :page
    is_text_present "Patient admission details successfully saved."
    is_text_present "Admission"
  end
  def update_newborn_admission(options ={})
    go_to_admission_page
    advanced_search options
    click "//table[@id='results']/tbody/tr[3]/td[7]/div[3]/a", :wait_for => :page
    click "previewAction", :wait_for => :page
    click "action", :wait_for => :page
    click "searchGuarantorBtn"
    click "//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']", :wait_for => :page
    click "link=ASALUS (INTELLICARE)"
    type "employer", "exist"
    type "employerAddress", "ortigas"
    type "position", "engineer"
    type "serviceYears", "10"
    type "otherIncome", "business"
    select "guarantorRelationCode", "label=STRANGER"
    type "guarantorTelNo", "123456"
    click "officeTelNo"
    type "officeTelNo", "123456"
    type "salary", "100000"
    click "previewAction", :wait_for => :page
    click "//input[@name='action' and @value='Save Admission']", :wait_for => :page
    is_text_present("Patient admission details successfully saved.")
  end
  def go_to_occupancy_list_page
     sleep 4
      go_to_outpatient_nursing_page if !is_text_present("link=Occupancy List")
    sleep 2
    click "link=Occupancy List", :wait_for => :page
    is_text_present("Special Units Home › Occupancy List")
  end
  def or_add_checklist_order(options = {})
    go_to_occupancy_list_page
    add_checklist_order(options)
  end
  def er_add_checklist_order(options = {})
    go_to_er_page
    add_checklist_order(options)
  end
  def validate_item(item)
    sleep 2
    validate_cart =  is_element_present("cartDetailNumber") ? "cartDetailNumber": "orderCartDetailNumber"
    click validate_cart
    click "validate"
    sleep 3
    click("//input[@type='button' and @value='OK' and @onclick='MultiplePrinters.validate(); return false;']")
    sleep 3
    if is_element_present("//div[@id='userEntryPopup']")
      self.fill_up_validation_info
    else
      #wait_for_page_to_load
        sleep 5
    end
    sleep 3

    is_text_present("has been validated successfully.")
  end
  def fill_up_validation_info(options={})
    type "usernameInputBox", options[:username] || "sel_0164_validator"
    type "passwordInputBox", "123qweuser"
    click("//html/body/div[7]/div[11]/div/button[2]", :wait_for => :page)
  end
  def or_search_checklist_order
    go_to_outpatient_nursing_page
    search_checklist_order
  end
  def or_add_clinical_diet(pin)
    go_to_occupancy_list_page
    add_clinical_diet(pin)
  end
  def or_add_package_order(options ={})
    go_to_general_units_page
    add_package_order(options)
  end
  def verify_patient_search_page
    go_to_outpatient_nursing_page
    is_element_present(Locators::Admission.search_textbox)
    is_element_present(Locators::Admission.search_button)
    is_element_present(Locators::Admission.admitted_checkbox)
    is_element_present(Locators::Admission.advanced_search_link)
  end
  def outpatient_room_location(options={})
    click "//input[@type='button' and @onclick='RBF.show();']"
    type "rbf_entity_finder_roomChargeCode", options[:rch_code] || "RCHSP"
    type "rbf_entity_finder_key", options[:org_code] || "0164"
    click "//input[@value='Search' and @type='button' and @onclick='RBF.searchByCondition();']"
    sleep 3
    click Locators::Admission.nb_room_bed
  end
  def er_billing_search(options = {})
    type "criteria", options[:pin]
    click '//input[@type="radio" and @value="WithDischarge"]' if options[:with_discharge_notice]
    click "filter1" if options[:discharged]
    click "filter2" if options[:admitted]
    click "filter3" if options[:all_patients] && (is_element_present('filter3'))
    click'//input[@type="submit" and @value="Search" and @name="search"]', :wait_for => :page
    sleep 2
    if is_element_present "css=#results>tbody>tr>td:nth-child(4)" #discount adjustment line#87
      visit_no = get_text("css=#results>tbody>tr>td:nth-child(4)").gsub(' ', '' )
      return visit_no
    end
    if options[:no_result]
      is_text_present("NO PATIENT FOUND")
    else
      is_text_present options[:last_name]
    end
  end
  def fill_up_fetal_notice_of_death_info(options={})
    type "fetus.lastName", options[:last_name] if options[:last_name]
    type "fetus.firstName", options[:first_name] if options[:first_name]
    type "fetus.middleName", options[:middle_name] if options[:middle_name]
    type "deliveryDate",Time.now.strftime("%m/%d/%Y")
      mytime = Time.now
      mmmytime = mytime - 12*60
    type "deliveryTimeStr", mmmytime.strftime("%H:%M")
    double_click"deliveryDate"
    double_click"deliveryTimeStr"
    sleep 4
    double_click"immediateCDeath"
    type "immediateCDeath", "Sample Death Cause"
    type "doctorNameDisplay", "3325"
    click("//input[@type='button' and @value='Save']", :wait_for => :page) if options[:save]
    click("//input[@type='button' and @value='Send']", :wait_for => :page) if options[:send]
    if is_element_present"popup_ok"
      click "popup_ok"
      sleep 1
      click("//input[@type='button' and @value='Save']", :wait_for => :page) if options[:save]
    end
    return get_text("successMessages") if is_element_present("successMessages")
  end
  def or_validate_pending_orders(options={})
    click "link=Order(s) for Validation"
    sleep 10
    while !is_text_present("#{options[:pin]}")
      click "next"
      sleep 3
    end
    sleep 2
    click "//a[@href='/nursing/special-units/specialUnitsOrderCart.html?pin=#{options[:pin]}&visitNo=#{options[:visit_no]}']", :wait_for => :page
    if options[:with_role_manager]
      sleep 1
      is_editable("cartDetailNumber")
    else
      username = options[:username] || "sel_0164_validator"
      password = options[:password] || "123qweuser"
      type("pharmUsername", username)
      type("pharmPassword", password)
      click("validatePharmacistOK")
      sleep 1
      is_editable("cartDetailNumber")
    end
  end
end