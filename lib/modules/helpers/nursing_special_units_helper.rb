#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/locators'

module NursingSpecialUnitsHelper
  include Locators::NursingSpecialUnits
  def click_create_patient_record
    click "link=Create Patient Record", :wait_for => :page
    is_text_present("Create New Patient") && is_text_present("Patient Information")
  end
  def go_to_er_patient_search
    go_to_er_landing_page
    click("link=Patient Search", :wait_for => :page)
    is_text_present("Occupancy List › Patient Search")
  end
  def go_to_or_patient_search
    go_to_outpatient_nursing_page
    click("link=Patient Search", :wait_for => :page)
    is_text_present("Occupancy List › Patient Search")
  end
  def occupancy_pin_search(options={})
    go_to_occupancy_list_page
    patient_pin_search options
  end
  def er_patient_search(options={})
    click 'link=Patient Search', :wait_for => :page
    patient_pin_search(options)
  end
  def er_occupancy_search(options={})
    go_to_er_landing_page
    patient_pin_search options
  end
  def create_patient_record(options = {})
    click "link=Create Patient Record", :wait_for => :page
    gender = options[:gender]
    civil_status = options[:civil_status] || "SINGLE"
    birth_place = options[:birth_place] || "METRO MANILA"
    citizenship = options[:citizenship] || "FILIPINO"
    birth_country = options[:birth_country] || "PHILIPPINES"
    nationality = options[:nationality] || "FILIPINO"
    religion = options[:religion] || "ROMAN CATHOLIC"
    occupation = options[:occupation] || "MANAGER"
    id =   options[:id_type1]|| "COMPANY ID"
    patient_id = options[:patient_id1]||"12345123"
    type "name.lastName",  options[:last_name] if options[:last_name]
    type "name.firstName",  options[:first_name] if options[:first_name]
    type "name.middleName", options[:middle_name] if options[:middle_name]
    click("male") if gender == "M"
    click("female") if gender == "F"
    type("birthDate", options[:birth_day])
    select("civilStatus.code", "label=#{civil_status}")
    type("birthPlace", birth_place)
    select("citizenship.code", "label=#{citizenship}")
    select("birthCountry.code", "label=#{birth_country}")
    select("nationality.code", "label=#{nationality}")
    select("religion.code", "label=#{religion}")
    type("presentAddrNumStreet", options[:address]) if options[:address]
    select("presentAddrCountry","label=#{options[:country]}") if options[:country]
    select("presentContactSelect",  "label=#{options[:contact_type]}") if options[:contact_type]
    type("presentContact1", options[:contact_details]) if options[:contact_details]
    select("id=idType[0]", "label=#{id}");
    type("id=patientIds0.idNo", patient_id);

    click("chkFillPermanentAddress")
    type("patientAdditionalDetails.occupation", occupation)
    type("patientAdditionalDetails.employer", options[:employer_name]) if options[:employer_name]
    type("patientAddresses[2].streetNumber", options[:employer_address]) if options[:employer_address]
    type("spouseLastName", options[:spouse_lname]) if options[:spouse_lname]
    type("spouseFirstName", options[:spouse_fname]) if options[:spouse_fname]
    type("spouseMiddleName", options[:spouse_mname]) if options[:spouse_mname]
    type("spouseTelephoneNum", "1234567")
    type "id=motherLastName", "selenium test"
    type "id=motherFirstName", "selenium test"
    type "id=motherMiddleName", "selenium test"

    type("erLastName", options[:last_name_to_notify]) if options[:last_name_to_notify]
    type("erFirstName", options[:first_name_to_notify]) if options[:first_name_to_notify]
    select "patientAdditionalDetails.primaryLanguage.code", "label=#{options[:primary_language]}" if options[:primary_language]
    select "patientAdditionalDetails.secondaryLanguage.code", "label=#{options[:secondary_language]}" if options[:secondary_language]
    click "//input[@name='action' and @value='Save']" if is_element_present("//input[@name='action' and @value='Save']")
    click "css=#controls > input[name=\"action\"]" if is_element_present("css=#controls > input[name=\"action\"]")
    sleep 8
    click "xpath=(//button[@type='button'])[3]"
    sleep 10
    if options[:senoir]
        click("//button[@type='button']",:wait_for => :page)  if is_element_present("//button[@type='button']")
    end

    sleep 30
    puts "pin location #{Locators::NursingSpecialUnits.pin}"
    puts "message = #{get_text("successMessages")}"
    puts "pin #{get_text(Locators::NursingSpecialUnits.pin)}"
    
    if (is_element_present(Locators::NursingSpecialUnits.pin) && get_text("successMessages") == "Patient information saved.")
          sleep 50      
          pin = get_text(Locators::NursingSpecialUnits.pin)
          #sleep Locators::NursingGeneralUnits.create_patient_waiting_time
    else 
          pin = get_text("patient.errors")
    end
          return pin

  end
  def er_create_patient(options = {})
    click "link=Create Patient Record", :wait_for => :page
    gender = options[:gender]
    civil_status = options[:civil_status] || "SINGLE"
    birth_place = options[:birth_place] || "METRO MANILA"
    citizenship = options[:citizenship] || "FILIPINO"
    birth_country = options[:birth_country] || "PHILIPPINES"
    nationality = options[:nationality] || "FILIPINO"
    religion = options[:religion] || "ROMAN CATHOLIC"
    occupation = options[:occupation] || "MANAGER"
    id =   options[:id_type1]|| "COMPANY ID"
    patient_id = options[:patient_id1]||"12345123"
    type "name.lastName",  options[:last_name] if options[:last_name]
    type "name.firstName",  options[:first_name] if options[:first_name]
    type "name.middleName", options[:middle_name] if options[:middle_name]
    click("male") if gender == "M"
    click("female") if gender == "F"
    type("birthDate", options[:birth_day])
    select("civilStatus.code", "label=#{civil_status}")
    type("birthPlace", birth_place)
    select("citizenship.code", "label=#{citizenship}")
    select("birthCountry.code", "label=#{birth_country}")
    select("nationality.code", "label=#{nationality}")
    select("religion.code", "label=#{religion}")
    type("presentAddrNumStreet", options[:address]) if options[:address]
    select("presentAddrCountry","label=#{options[:country]}") if options[:country]
    select("presentContactSelect",  "label=#{options[:contact_type]}") if options[:contact_type]
    type("presentContact1", options[:contact_details]) if options[:contact_details]
    select("id=idType[0]", "label=#{id}");
    type("id=patientIds0.idNo", patient_id);

    click("chkFillPermanentAddress")
    type("patientAdditionalDetails.occupation", occupation)
    type("patientAdditionalDetails.employer", options[:employer_name]) if options[:employer_name]
    type("patientAddresses[2].streetNumber", options[:employer_address]) if options[:employer_address]
    type("spouseLastName", options[:spouse_lname]) if options[:spouse_lname]
    type("spouseFirstName", options[:spouse_fname]) if options[:spouse_fname]
    type("spouseMiddleName", options[:spouse_mname]) if options[:spouse_mname]
    type("spouseTelephoneNum", "1234567")
    type "id=motherLastName", "selenium test"
    type "id=motherFirstName", "selenium test"
    type "id=motherMiddleName", "selenium test"

    type("erLastName", options[:last_name_to_notify]) if options[:last_name_to_notify]
    type("erFirstName", options[:first_name_to_notify]) if options[:first_name_to_notify]
    select "patientAdditionalDetails.primaryLanguage.code", "label=#{options[:primary_language]}" if options[:primary_language]
    select "patientAdditionalDetails.secondaryLanguage.code", "label=#{options[:secondary_language]}" if options[:secondary_language]
    click "//input[@name='action' and @value='Save']" if is_element_present("//input[@name='action' and @value='Save']")
    click "css=#controls > input[name=\"action\"]" if is_element_present("css=#controls > input[name=\"action\"]")
    sleep 8
    click "xpath=(//button[@type='button'])[3]"
    sleep 10
    if options[:senoir]
        click("//button[@type='button']",:wait_for => :page)  if is_element_present("//button[@type='button']")
    end

    sleep 30
    puts "pin location #{Locators::NursingSpecialUnits.er_pin}"
    puts "message = #{get_text("successMessages")}"
    puts "pin #{get_text(Locators::NursingSpecialUnits.er_pin)}"
    
    if (is_element_present(Locators::NursingSpecialUnits.er_pin) && get_text("successMessages") == "Patient information saved.")
          sleep 50      
          pin = get_text(Locators::NursingSpecialUnits.er_pin)
          #sleep Locators::NursingGeneralUnits.create_patient_waiting_time
    else 
          pin = get_text("patient.errors")
    end
          return pin

  end
  def fill_out_patient_record(options={})
    type "name.lastName",  options[:last_name] if options[:last_name]
    type "name.firstName",  options[:first_name] if options[:first_name]
    type "name.middleName", options[:middle_name] if options[:middle_name]
    select"civilStatus.code",options[:civil_status] || "SINGLE"
    type "birthPlace",options[:birth_place] || "PLACE"
    select "nationality.code",options[:nationality] || "FILIPINO"
    select "religion.code",options[:religion] || "CHRISTIAN"
    gender = options[:gender]
    click 'male' if gender == "M"
    click 'female' if gender == "F"
    type 'birthDate', options[:birth_day]
    select "citizenship.code", "label=FILIPINO"
    type "presentAddrNumStreet", options[:address] if options[:address]
    select "presentAddrCitySelect", "label=#{options[:city]}"
    select "presentAddrCountry","label=#{options[:country]}" if options[:country]
    select "presentContactSelect",  "label=#{options[:contact_type]}" if options[:contact_type]
    type "presentContact1", options[:contact_details] if options[:contact_details]
    click "patient"
    click"//input[@id='chkFillPermanentAddress' and @type='checkbox' and @onclick='PF.fillPermanentAddress(this.checked)']"
    type "erLastName", options[:last_name_to_notify] if options[:last_name_to_notify]
    type "erFirstName", options[:first_name_to_notify] if options[:first_name_to_notify]
    type"patientAdditionalDetails.occupation",options[:occupation] || "QA"
    type"patientAdditionalDetails.employer",options[:employer] || "EXIST"
    type"spouseLastName",options[:spouse_last_name] || "LASTNAME"
    type"spouseFirstName",options[:spouse_first_name] || "FIRSTNAME"
    type"spouseMiddleName",options[:spouse_middle_name] || "MIDDLENAME"
    type"spouseTelephoneNum",options[:spouse_number] || "1234567"
    type"//input[@id='permanentAddrNumStreet' and @type='text' and @name='patientAddresses[2].streetNumber']",options[:employer_address] || "ADDRESS"
  end
  def save_patient_record
    click "//input[@name='action' and @value='Save']", :wait_for => :page
    get_text("successMessages")
  end
  def go_to_fnb_page_for_a_given_pin(page, pin)
    select "userAction#{pin}", "label=#{page}"
    click Locators::NursingSpecialUnits.fnb_submit_button, :wait_for => :page
  end
  def cancel_patient_registration
    click "//input[@name='action' and @value='Cancel']", :wait_for => :page
    is_text_present("Occupancy List")
  end
  def admit_or_patient(options ={})
    account_class = options[:account_class] || "INDIVIDUAL"
    select "accountClass", "label=#{account_class}"
    click "roomNoFinder"
    type "rbf_entity_finder_roomChargeCode", options[:rch_code] || "RCHSP"
    @org_codes = AdmissionHelper.get_org_codes_info(CONFIG['location'], (options[:org_code] || "0164"))
    type "rbf_entity_finder_key", @org_codes[:org_code]
    type "rbf_room_no_finder_key", "XST"
    click "css=#roomBedFinderForm>div:nth-child(2)>div>input", :wait_for => :element, :element => Locators::Admission.room_bed
    room_count = get_css_count "css=#rbf_finder_table_body>tr"
    random_room = 1 + rand(room_count)
    click Locators::Admission.room_bed(:random => (random_room))
    sleep 5
    click "//input[@type='button' and @onclick='Diagnosis.show();']", :wait_for => :element, :element => "diagnosisFinderForm"
    type "diagnosis_entity_finder_key", "GASTRITIS"
    click "//input[@type='button' and @onclick='Diagnosis.search();' and @value='Search']", :wait_for => :element, :element => "css=#diagnosis_finder_table_body>tr>td:nth-child(2)>a"
    click "css=#diagnosis_finder_table_body>tr>td:nth-child(2)>a"
    sleep 1
    type("diagnosisDateTime", Time.now.strftime("%m/%d/%Y"))
    sleep 3
    self.doctor_finder(:doctor => "ABAD")
    if get_text("id=doctorCode") == ""
    type "id=doctorCode", "1008"
    end
    if options[:guarantor_code]
      if (account_class == "EMPLOYEE") || (account_class == "EMPLOYEE DEPENDENT")
        select "guarantorTypeCode", "label=EMPLOYEE"
        sleep 1
        click "searchGuarantorBtn"
        type "employee_entity_finder_key", (options[:last_name] if options[:last_name]) || (options[:guarantor_code] if options[:guarantor_code])
        full_name_link = "link=#{options[:last_name].upcase}, #{options[:first_name].upcase} #{options[:middle_name].upcase}" if options[:last_name] #|| "link=RUIZ, MICHAEL PEREZ"
        click "//input[@value='Search' and @type='button' and @onclick='EF.search();']"
        click full_name_link
      elsif account_class == 'INDIVIDUAL'
        click "searchGuarantorBtn"
        type "patient_entity_finder_key", options[:guarantor_code] if options[:guarantor_code]
        click "//input[@value='Search' and @type='button' and @onclick='PF.search();']"
      elsif account_class == "DOCTOR" || (account_class == "DOCTOR DEPENDENT")
        select "guarantorTypeCode", "label=DOCTOR"
        sleep 1
        click "searchGuarantorBtn"
        type "ddf_entity_finder_key", options[:guarantor_code] if options[:guarantor_code]
        click "//input[@value='Search' and @type='button' and @onclick='DDF.search();']"
      else
        select "guarantorTypeCode", options[:guarantor_type] if options[:guarantor_type]
        click "searchGuarantorBtn"
        type "bp_entity_finder_key", options[:guarantor_code] if options[:guarantor_code]
        click "//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']"
      end
      sleep 5
#      click full_name_link if (options[:last_name] && (account_class == "EMPLOYEE") || (account_class == "EMPLOYEE DEPENDENT"))
      if is_element_present("link=#{options[:guarantor_code]}")
        click "link=#{options[:guarantor_code]}" if options[:guarantor_code]
      else
        sleep 5
        click "css=#ddf_finder_table_body>tr>td>div"
      end
      sleep 3
      select "guarantorRelationCode", ("label=#{options[:relationship]}" if options[:relationship]) || "label=SELF"
    end
    
    click "popup_ok", :wait_for => :page if is_element_present"popup_ok"
    click "previewAction", :wait_for => :page
    click "//input[@type='button' and @value='Save' and @onclick='submitForm(this);']", :wait_for => :page
    is_text_present("Patient admission details successfully saved.")
  end
  def fill_out_patient_admission(options={})
    unless is_element_present "Patient information saved."
      select "accountClass", "label=INDIVIDUAL"
      @org_codes = AdmissionHelper.get_org_codes_info(CONFIG['location'], (options[:org_code] || "0164"))
      click 'roomNoFinder'
      type "rbf_entity_finder_roomChargeCode", options[:rch_code] || "RCHSP"
      type "rbf_entity_finder_key", @org_codes[:org_code]
      click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']"
      sleep 5
      click Locators::Admission.or_room_bed
      self.doctor_finder(:doctor => "ABAD")
      sleep 5
      if options[:preview]
        go_to_preview_page
      elsif options[:cancel]
        cancel_patient_registration
      end
    end
  end
  def revise_admission
    #click "action", :wait_for => :page
    click "//input[@type='button' and @value='Revise' and @onclick='submitForm(this);']", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/form/div/div/label") == "Admission Info"
  end
  def click_save_admission
    click"//input[@type='button' and @value='Save' and @onclick='submitForm(this);']", :wait_for => :page
    is_text_present("Patient admission details successfully saved.")
  end
  def admit_er_patient(options={})
    account_class = options[:account_class] || "INDIVIDUAL"
    @org_codes = AdmissionHelper.get_org_codes_info(CONFIG['location'], (options[:org_code] || "0173"))
    sleep 6
    select "accountClass", "#{account_class}"
    sleep 3
    if account_class == "SOCIAL SERVICE"
      type "id=escNumber", options[:esc_no] || "234"
      type "id=initialDeposit", options[:ss_amount] || "100"
      select "id=clinicCode", options[:dept_code] || "MEDICINE"
    end
        sleep 3
    click "id=turnedInpatientFlag1" if options[:turn_inpatient]
    sleep 6
    click "id=roomNoFinder"
    type "rbf_entity_finder_key", @org_codes[:org_code]
    type "rbf_room_no_finder_key", "XST" #admit only on ROOMS with "XST"
    click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']", :wait_for => :element, :element => Locators::NursingSpecialUnits.er_room_bed
    click  Locators::NursingSpecialUnits.er_room_bed, :wait_for => :not_visible, :element => Locators::NursingSpecialUnits.er_room_bed
    type("diagnosisDateTime",Time.now.strftime("%m/%d/%Y")) if is_element_present("diagnosisDateTime")
    self.doctor_finder(:doctor => "ABAD")
     if options[:guarantor_code]
      select "accountClass", "label=#{options[:account_class]}"
      select "guarantorTypeCode", "label=#{options[:guarantor_type]}"
      click "searchGuarantorBtn", :wait_for => :element, :element => "bp_entity_finder_key"
      type "bp_entity_finder_key", options[:guarantor_code]
      click "//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']" ## search box for HMO account class
      sleep 4
      click "link=#{options[:guarantor_code]}"
      sleep 3
      click "css=input.myButton" if is_element_present("css=input.myButton")
      
      click "css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]" if is_element_present("css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]")

      select "guarantorRelationCode","SELF" if is_element_present("guarantorRelationCode")
    end
    click "previewAction", :wait_for => :page
    sleep 7
    if is_text_present "Doctor is a required field."
        type "id=doctorCode", "1008"
        sleep 3
        click "id=responsibilityInfo" if is_element_present("id=responsibilityInfo")
        sleep 6
        click "previewAction", :wait_for => :page
         sleep 7
    end
    save_button =  is_element_present("//input[@type='button' and @onclick='submitForm(this);' and @value='Save' and @name='action']") ? "//input[@type='button' and @onclick='submitForm(this);' and @value='Save' and @name='action']" : "//input[@value='Save']"
    click save_button, :wait_for => :page
    is_text_present("Patient admission details successfully saved.")
  end
  def admit_or_nb_patient(options={})
    account_class = options[:account_class] || "INDIVIDUAL"
    @org_codes = AdmissionHelper.get_org_codes_info(CONFIG['location'], (options[:org_code] || "0164"))
    if account_class == "SOCIAL SERVICE"
        type "escNumber", options[:esc_no] || "234"
        type "initialDeposit", options[:ss_amount] || "100"
        select "clinicCode", options[:dept_code] || "MEDICINE"
    end
    select "accountClass", "label=#{account_class}"
    #>> ROOMS START
    click "roomNoFinder"
    type "rbf_entity_finder_roomChargeCode", (options[:rch_code] || "RCHSP")
    type "rbf_entity_finder_key", @org_codes[:org_code]
    type "rbf_room_no_finder_key", "XST" #admit only on ROOMS with "XST"
    click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']", :wait_for => :element, :element => Locators::Admission.nb_room_bed
    room_count = get_css_count "css=#rbf_finder_table_body>tr"
    random_room = 1 + rand(room_count).to_i
    click Locators::Admission.room_bed(:random => (random_room)), :wait_for => :not_visible, :element => Locators::Admission.room_bed
    sleep 1
    click "//input[@value='' and @type='button']", :wait_for => :text, :text => "Search For Diagnosis"
    diagnosis = options[:diagnosis] || "GASTRITIS"
    type "diagnosis_entity_finder_key", diagnosis
    click "//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']", :wait_for => :element, :element => "link=#{diagnosis}"
    click "link=#{diagnosis}"
    sleep 1
    type "diagnosisDateTime", Time.now.strftime("%m/%d/%Y")
    sleep 1
    self.doctor_finder(:doctor => "ABAD")
    select "guarantorTypeCode", "label=#{options[:guarantor_type]}" if options[:guarantor_type]
    if options[:guarantor_code]
      click "searchGuarantorBtn"
      if (account_class == "EMPLOYEE") || (account_class == "EMPLOYEE DEPENDENT")
        type "employee_entity_finder_key", (options[:last_name] if options[:last_name]) || (options[:guarantor_code] if options[:guarantor_code])
        click "//input[@value='Search' and @type='button' and @onclick='EF.search();']"
      elsif account_class == 'INDIVIDUAL'
        type "patient_entity_finder_key", options[:guarantor_code] if options[:guarantor_code]
        click "//input[@value='Search' and @type='button' and @onclick='PF.search();']"
      elsif account_class == "DOCTOR" || (account_class == "DOCTOR DEPENDENT")
        type "ddf_entity_finder_key", options[:guarantor_code] if options[:guarantor_code]
        click "//input[@value='Search' and @type='button' and @onclick='DDF.search();']"
      else
        type "bp_entity_finder_key", options[:guarantor_code] if options[:guarantor_code]
        click "//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']"
      end
    end
    sleep 5
    if is_element_present("link=#{options[:guarantor_code]}")
      click "link=#{options[:guarantor_code]}"
    elsif account_class == "DOCTOR" || (account_class == "DOCTOR DEPENDENT")
      sleep 5
      click "css=#ddf_finder_table_body>tr>td>div" if is_element_present"css=#ddf_finder_table_body>tr>td>div"
    end
      if get_text("id=doctorCode") == ""
            type "id=doctorCode", "1008"
    end    
    click "previewAction", :wait_for => :page
    if is_text_present "Doctor is a required field."
      self.doctor_finder(:doctor => "ABAD")
      sleep 3  

    end
    if options[:sap]
      click "//input[@name='action' and @value='Save and Print' and @onclick='submitForm(this);']", :wait_for => :page
    else
    save_button = is_element_present("//input[@type='button' and @value='Save' and @onclick='submitForm(this);']") ? "//input[@type='button' and @value='Save' and @onclick='submitForm(this);']" : "//input[@value='Save']"
    click save_button, :wait_for => :page
    end
    is_text_present("Patient admission details successfully saved.")
  end
  def fill_out_patient_admission(options={})
    unless is_element_present "Patient information saved."
      @org_codes = AdmissionHelper.get_org_codes_info(CONFIG['location'], (options[:org_code] || "0165"))
      select "accountClass", "label=INDIVIDUAL"
      click 'roomNoFinder'
      type "rbf_entity_finder_roomChargeCode", options[:rch_code] || "RCHSP"
      type "rbf_entity_finder_key", @org_codes[:org_code]
      click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']"
      sleep 5
      click Locators::Admission.or_room_bed
      self.doctor_finder(:doctor => "ABAD")
      if options[:preview]
        go_to_preview_page
      elsif options[:cancel]
        cancel_patient_registration
      end
    end
  end
  def revise_admission
    #click "action", :wait_for => :page
    click "//input[@type='button' and @value='Revise' and @onclick='submitForm(this);']", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/form/div/div/label") == "Admission Info"
  end
  def click_save_admission
    click "//input[@type='button' and @value='Save' and @onclick='submitForm(this);']", :wait_for => :page
    is_text_present("Patient admission details successfully saved.")
  end
  def patient_pin_search(options ={})
  #  pin  = options[:pin]
  #  puts ("pin - #{pin}")
    sleep 6
    search_value = is_element_present("criteria") ?  ("criteria") :  ("param")
   # puts "search_value - #{search_value}"
    #sam = is_element_present(search_value)
  #  puts "sam - #{sam}"
  if search_value == "criteria"
    samcss =("css=#" + search_value)
     search_value = samcss
  end
  #  puts "samcss - #{samcss}"
   # ssss = is_element_present(samcss)
 #   puts "ssss - #{ssss

    type search_value, options[:pin]
    sleep 5
    click "//input[@type='checkbox' and @name='discharged']" if options[:discharged]
    select("orgCode", options[:org_code]) if options[:org_code] && is_element_present("orgCode")
    if is_element_present("css=#searchMPI")
      click("css=#searchMPI", :wait_for => :page)
      sleep 6
    elsif is_element_present("id=searchMPI")
            click "id=searchMPI", :wait_for => :page
            sleep 6
    elsif is_element_present("//input[@value='Search' and @type='button' and @onclick='submitPSearchForm(this);']")
      click"//input[@value='Search' and @type='button' and @onclick='submitPSearchForm(this);']", :wait_for => :page
    else
      click("//input[@type='submit' and @value='Search']", :wait_for => :page)
    end
    return is_text_present("Enter a pin or lastname") if options[:blank]
    return is_text_present("NO PATIENT FOUND") if  options[:no_result]
    return is_text_present options[:last_name] if options[:last_name] || options[:pin]
    sleep 6
  end
  def cancel_admission(options ={})
    admission_search options
    click "link=Cancel Admission", :wait_for => :visible, :element => Locators::NursingSpecialUnits.cancel_reason
    type Locators::NursingSpecialUnits.cancel_reason, "reason to cancel"
    sleep 3
    click Locators::NursingSpecialUnits.cancel_admission, :wait_for => :page
    is_text_present "Patient admission details successfully cancelled."
  end
  def click_cancel_admission_inside
    click("//input[@value='Cancel Admission']", :wait_for => :visible, :element => "admCancelDlg")
    sleep 10
    type "//*[@name='reason']", "cancel"
    click '//div[5]/div[3]/div/button', :wait_for => :page
    is_text_present "Patient admission details successfully cancelled."
  end
  def go_to_order_page(options ={})
    patient_pin_search options
    sleep 2
    select "userAction#{options[:pin]}", "label=Order Page"
    click Locators::NursingSpecialUnits.submit_button_spu, :wait_for => :page
  end
  def go_to_adm_order_page(options ={})
    patient_pin_search options
    select "userAction#{options[:pin]}", "label=Order Page"
    click Locators::NursingSpecialUnits.submit_button, :wait_for => :page
  end
  def go_to_update_registration(options ={})
    go_to_occupancy_list_page
    patient_pin_search options
    select "userAction#{options[:pin]}", "label=Update Registration"
    click Locators::NursingSpecialUnits.submit_button_spu, :wait_for => :page
    click "turnedInpatientFlag1" if options[:turn_inpatient]
    select "confidentiality.code", "label=VERY RESTRICTED"
    click "confidential1"
    click "//input[@value='' and @type='button']"
    type "diagnosis_entity_finder_key", "GASTRITIS"
    click "//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']"
    sleep 3
    click "//html/body/div/div[2]/div[2]/div[11]/div[2]/div[2]/div[2]/table/tbody/tr/td[2]/a" #click "link=GASTRITIS"
    sleep 3
    click "previewAction", :wait_for => :page
    if options[:save_and_print]
      click "//input[@name='action' and @value='Save and Print']", :wait_for => :page
      get_text("//html/body/div/div[2]/div[2]/div[4]/div") == "Patient admission details successfully saved. Patient admission process complete."
    elsif options[:save]
      click "//input[@name='action' and @value='Save and Print']", :wait_for => :page
      get_text("//html/body/div/div[2]/div[2]/div[3]/div") == "Patient admission details successfully saved."
    elsif options[:revise]
      click "//input[@name='action' and @value='Save and Print']", :wait_for => :page
      get_text("//html/body/div/div[2]/div[2]/form/div[2]/div/label") == "Admission Info"
    elsif options[:cancel]
      self.click_cancel_registration
    end
  end
  def go_to_my_update_registration(options ={})
    go_to_er_page
    patient_pin_search options
    select "userAction#{options[:pin]}", "label=Update Registration"
    click Locators::NursingSpecialUnits.submit_button_spu, :wait_for => :page
    click "turnedInpatientFlag1" if options[:turn_inpatient]
    sleep 3
    click "previewAction", :wait_for => :page
    if options[:save_and_print]
      click "//input[@name='action' and @value='Save and Print']", :wait_for => :page
      get_text("//html/body/div/div[2]/div[2]/div[4]/div") == "Patient admission details successfully saved. Patient admission process complete."
    elsif options[:save]
      click "//input[@name='action' and @value='Save and Print']", :wait_for => :page
      get_text("//html/body/div/div[2]/div[2]/div[3]/div") == "Patient admission details successfully saved."
    elsif options[:revise]
      click "//input[@name='action' and @value='Save and Print']", :wait_for => :page
      get_text("//html/body/div/div[2]/div[2]/form/div[2]/div/label") == "Admission Info"
    elsif options[:cancel]
      self.click_cancel_registration
    end
  end
  #search order list
  def search_order_list(options={})
    click 'checkALL' if options[:status] == "all"
    click 'checkV' if options[:status] == "validated"
    click 'checkA' if options[:status] == "pending"
    click 'checkC' if options[:status] == "cancelled"
    sleep 2
    if options[:type] == "drugs"
      click "//a[@title='DRUGS']/span"
    elsif options[:type] == "supplies"
      click "//a[@title='SUPPLIES']/span"
    elsif options[:type] == "ancillary"
      click "//a[@title='ANCILLARY']/span"
    elsif options[:type] == "misc"
      click "//a[@title='OTHERS']/span"
    elsif options[:type] == "special"
      click "//a[@title='SPECIAL']/span"
    elsif options[:type] == "medical_gases"
      click "//a[@title='MEDICAL GASES']/span"
    end
    sleep 3
    if options[:order_date]
      type 'fromDate', options[:order_date]
      type 'toDate', Date.today.strftime("%m/%d/%Y")
    elsif options[:ci_number]
      type 'ciNumber', options[:ci_number]
    end
    search_button = is_element_present('searchButton') ?   'searchButton' : 'searchOrders'
    click search_button
    sleep 8
    is_text_present(options[:item])
  end
  def click_outpatient_registration(options={})
    click "link=Outpatient Registration", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/div/div/ul/li[2]") == "Outpatient Registration"
  end
  def click_outpatient_order(options={})
        if CONFIG['ver'] == "1.8.2"
                click "link=OutPatient Order",:wait_for => :page
        else
                select "id=selectAction#{options[:pin]}", "label=OutPatient Order"
                click "id=#{options[:pin]}", :wait_for => :page
        end
                get_text("//html/body/div/div[2]/div[2]/div/div/ul/li") == "One Stop Shop"
  end
  def go_to_preview_page
    #click "previewAction", :wait_for => :page
    click'//input[@value="Preview"]', :wait_for => :page
    is_element_present("//input[@name='action' and @value='Save']") || is_element_present("//input[@name='action' and @value='Save Admission']")
  end
  def click_update_patient_info
    click "link=Update Patient Info", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/form/div[2]/div/label") == "Patient Information"
  end
  def click_register_patient
    click "link=Register Patient", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/form/div[2]/div/label") == "Admission Info"
 #   ("//html/body/div[1]/div[2]/div[2]/div[6]/div[2]/table[1]/tbody/tr/td[9]/div[2]/a")
  end
  def click_cancel_registration
    if is_element_present Locators::NursingSpecialUnits.cancel_registration_link
      click Locators::NursingSpecialUnits.cancel_registration_link, :wait_for => :element, :element => Locators::NursingSpecialUnits.cancel_reason
    elsif is_element_present Locators::NursingSpecialUnits.cancel_registration_button
      click Locators::NursingSpecialUnits.cancel_registration_button, :wait_for => :element, :element => "admissionCancelForm"
    end
    sleep 3
    type Locators::NursingSpecialUnits.cancel_reason, "reason to cancel"
    sleep 3
    click Locators::NursingSpecialUnits.cancel_admission, :wait_for => :page
    is_text_present "Patient admission details successfully cancelled."
  end
  def click_update_registration(options={})
    if options[:cancel]
      go_to_outpatient_nursing_page
      patient_pin_search options
      self.click_cancel_registration
    end
  end
  def check_patient_status_after_update(options ={})
    go_to_occupancy_list_page
    patient_pin_search options
    is_text_present("For Inpatient Admission") && get_text("//html/body/div/div[2]/div[2]/table/tbody/tr/td[3]/span") == "(Confidential)"
  end
  def print_blank_pis
    go_to_das_technologist
    click "link=Print Blank PIS", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/div[3]/div").include? "Blank PIS printed."
  end
  def add_checklist_order(options = {})
    if options[:pin]
      patient_pin_search options
      select "userAction#{options[:pin]}", "label=Checklist Order"
      click Locators::NursingSpecialUnits.submit_button_spu, :wait_for => :page
    end
    if options[:procedure]
      click "orderTypeEl"
      type "oif_entity_finder_key", options[:procedure]
      click "search" ## updated to accommodate specified waiting_time
      sleep Locators::NursingGeneralUnits.waiting_time
    else
      click "nonProcedureFlag"
      sleep 2
      type "oif_entity_finder_key", options[:supplies_equipment]
      click "search", :wait_for => :element, :element => "link=#{options[:supplies_equipment]}"
      sleep 1
      click "link=#{options[:supplies_equipment]}"
      sleep Locators::NursingGeneralUnits.waiting_time
      type "aQuantity", options[:a_quantity] || "1"
      type "sQuantity", options[:s_quantity] || "1"
      sleep 1
    end
    type "remarks", "remarks"
    click Locators::NursingSpecialUnits.add_item_button, :wait_for => :page
    assign_surgeon(options[:doctor]) if options[:doctor]
    (return true if is_text_present(options[:procedure])) if options[:procedure]
    (return true if is_text_present(options[:supplies_equipment])) if options[:supplies_equipment]
  end
  def assign_surgeon(options={})
    click Locators::NursingSpecialUnits.find_surgeon
    click Locators::NursingSpecialUnits.search_doctors_textbox
    type Locators::NursingSpecialUnits.search_doctors_textbox, options[:doctor]
    click "//input[@value='Search']", :wait_for => :element, :element => Locators::NursingSpecialUnits.nb_searched_doctor #, :wait_for => :text, :element => "//span[@id='pagebanner']/span[1]", :text => /item(s). Displaying/
    click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
    sleep 2
  end
  def edit_checklist_order(options={})
    sleep 5
    if options[:special]
      type "serviceRateDisplay", options[:price]
    else
      click "link=#{options[:procedure]}", :wait_for => :page
      get_text("itemDesc") == options[:procedure]
    end
    type "sQuantity", options[:quantity]
    click "//input[@name='add' and @value='Save']"#, :wait_for => :page
    if is_element_present"popup_ok"
      click"popup_ok", :wait_for => :page
    else
      #wait_for_page_to_load
        sleep 5
    end
    if is_element_present('css=div[class="success"]')
      return get_text('css=div[class="success"]')
    else
      return get_text("checkListOrderBean.errors")
    end
  end
  def confirm_checklist_order
    click "validateOrder", :wait_for => :page
    if (is_element_present("validatedCartDetailNumber") || is_text_present("Special Units : Order Cart"))
      return true
    else
      return get_text("*.errors")
    end
  end
  def add_clinical_diet(options ={})
    diet = options[:diet] || "COMPUTED DIET"
    food_preferences = options[:food_preferences] || "Selenium Test Food Preference"
    food_allergy_description = options[:description] || "Selenium Test Food Allergy Description"
    height = options[:height] || "160"
    weight = options[:weight] || "56"
    click("btnDiagnosisLookup", :wait_for => :element, :element => "dietFinderKey")
    sleep 1
    type("dietFinderKey", diet)
    click("//input[@type='button' and @value='Search' and @onclick='DietFinder.search();']", :wait_for => :element, :element => "link=#{diet}")
    sleep 1
    click("link=#{diet}", :wait_for => :not_visible, :element => "link=#{diet}")
    type "currDietRemarks",  options[:additional_instruction] || "ADD'L INSTRUCTION"
    type "foodPreferences", food_preferences
    type "alergyDescription", food_allergy_description
    click "//input[@value='Add']", :wait_for => :ajax
    sleep 5
    temp = get_alert if is_alert_present()
    type "height", height
    type "weight", weight
    if options[:nutritionally_at_risk] == "YES"
            click "id=nutritionallyAtRisk1"
    elsif options[:nutritionally_at_risk] == "NO"
            click "id=nutritionallyAtRisk2"  
    else
            click "id=nutritionallyAtRisk3" 
    end
    
    click "currDisposableTray1" if options[:disposable_tray]
    sleep 3
    arr = []
    bmi = get_value("bmi")
    int = get_value("interpretation")
    arr << bmi << int
    return arr if options[:bmi]
    if options[:save]
      click "//input[@value='Save' and @name='Save']", :wait_for => :page
      return get_text("successMessages")
    end
    if options[:update]
      click "//input[@value='Update' and @name='Update']", :wait_for => :page
      return get_text("successMessages")
    end
  end
  def view_clinical_diet(options={})
    if options[:reset]
      click "//input[@type='button' and @value='Reset']"
    end
    if options[:view_diet]
      click("//input[@type='button' and @value='View Diet History']", :wait_for => :page)
      click("link=#{options[:diet]}", :wait_for => :element, :element => "//input[@type='button' and @value='Close']")
      sleep 5
      click("//input[@type='button' and @value='Close']", :wait_for => :element, :element => "css=#dataTable>tbody") if options[:close]
      sleep 2
      is_element_present("css=#dataTable>tbody>tr:nth-child(2)>td")
    end
  end
  def fnb_view_diet_stub(options = {})
    pin = options[:pin]
    lastname = options[:last_name]
    visitno = options[:visitno]
    go_to_fnb_landing_page
    click "link=Diet Stub", :wait_for => :page
    click "slide-fade"
    type "perAdmittedPatientSearchForm.pin", pin
    type "perAdmittedPatientSearchForm.name.lastName", lastname
    type "perAdmittedPatientSearchForm.visitNo", visitno
    click "searchAdmittedPatients", :wait_for => :page
    click "printAdmittedPatientStub", :wait_for => :page
    #is_text_present "Unable to find printer config for DIET_STUB_PRINTER"
    return false if is_element_present("//html/body/div/div[2]/div[2]/div[3]/div")
    return false if !is_element_present("//html/body/div/div[2]/div[2]/div[3]/div")
    get_text("//html/body/div/div[2]/div[2]/div[3]/div").include? "Printing Error"
  end
  def add_package_order(options ={})
    patient_pin_search options
    select "userAction#{options[:pin]}", "label=#{options[:label]}" || "label=Package Order"
    click "//option[@value='/nursing/general-units/packageOrderHome.html?']"
    click Locators::NursingSpecialUnits.submit_button_package, :wait_for => :page
    select "packageOrderCode", "label=#{options[:package]}" # APE MERALCO - MALE
    sleep 5
    click "chargeType"
    click "showDoctorFinder", :wait_for => :ajax
    type "entity_finder_key", "ABAD"
    click "//input[@value='Search']", :wait_for => :ajax
    click "//tbody[@id='finder_table_body']/tr/td[2]/div", :wait_for => :ajax
    click "//input[@value='Submit']", :wait_for => :page
    if options[:edit]
      click "edit"
      select "packageOrderCode", "label=PLAN A MALE" || "label=APE MERALCO - FEMALE"
    end
    click "validate", :wait_for => :page
  end
  def verify_patient_diet_history(options = {})
    pin = options[:pin]
    visitno = options[:visitno]
    go_to_fnb_page_for_a_given_pin("Patient Diet History", pin)
    click "link=#{visitno}", :wait_for => :page
    is_text_present "Patient Diet History"
    click "link=COMPUTED", :wait_for => :page
    is_text_present "Patient Diet Details"
  end
  def search_checklist_order(pin)
    nursing_su_search(pin)
    go_to_su_page_for_a_given_pin("Checklist Order", pin)
    click "//option[@value='/nursing/special-units/or/checkListOrder.html?method=add&']"
    click "//input[@value='Submit']", :wait_for => :page
    type "//input[@id='soaNumber' and @name='soaNumber' and @value='' and @type='text']", "0"
    click "search", :wait_for => :page
  end
  def search_soa_checklist_order(options = {})
    go_to_er_patient_search if options[:er]
    go_to_outpatient_nursing_page if options[:er] != true
    click "link=Search Checklist Orders", :wait_for => :page
    type "startOrderDate", options[:date_today] if options[:date_today]
    type "endOrderDate", options[:date_today] if options[:date_today]
    type "endOrderDate", options[:date2] if options[:date2]
    type "txtSoaNumber", options[:soa_number] if options[:soa_number]
    type "param", options[:pin] if options[:pin]
    click "search", :wait_for => :page
    if options[:date2] && (options[:date_today] > options[:date2])
      return (get_text('//*[@id="orderGroupSearchBean.errors"]') == "Start Date should not be later than End Date.")
    end
    return false if is_text_present("Nothing found to display.")
    is_element_present("//html/body/div/div[2]/div[2]/div[8]/div[2]/table/tbody/tr/td")
  end
  def adjust_checklist_order
    click "link=Adjust", :wait_for => :page
    is_text_present("CURRENT CHECK LIST ORDERS")
  end
  def checklist_order_adjustment(options = {})
    if options[:remove]
      click "css=#clo_tbody>tr>td>a"
      sleep 10
      get_confirmation()
    end
    if options[:edit]
      click "link=Edit", :wait_for => :ajax
      sleep 2
      type "aQuantity", options[:aqty] if options[:aqty]
      type "sQuantity", options[:sqty] if options[:sqty]
      click "_updateButton"
      sleep 5
    end
    if options[:add]
      procedure = options[:checklist_order]
      type "oif_entity_finder_key", procedure.upcase
      click "orderTypeEl", :wait_for => :ajax if options[:ordertype1]
      click "//div[@id='step1']/div[2]/div[2]/input[2]" if options[:ordertype2]
      click "search"
      sleep 5
      click Locators::NursingSpecialUnits.order_adjustment_searched_service_code, :wait_for => :ajax
      click "_addButton"
      sleep 5
    end
    click '_submitForm' if is_editable'_submitForm'
    sleep 5
    username = options[:username] || "sel_0164_validator"
    password = options[:password] || "123qweuser"
    if is_element_present("usernameInputBox")
      type("usernameInputBox", username)
      type("passwordInputBox", password)
      click("//html/body/div[8]/div[11]/div/button[2]", :wait_for => :page)
    end
    sleep 5
    return true if (is_text_present("Search Checklist Order") || is_text_present("is clicked for deletion."))
    return true if is_text_present("Checklist Order Adjustment")
    return false if is_element_present("errorMessages")
  end
  def reprint_checklist_order(options = {})
    click "link=Reprint"
    sleep 10  # wait for ajax won't work due to the loading wheel icon
    alert = get_alert
    if options[:no_printer]
      return alert.include? "printed to printer"
    else
      return alert.include? "Error: "
    end
  end
  def get_soa_number
    soa_number = get_text "//html/body/div/div[2]/div[2]/div[7]/label[2]"
    return soa_number
  end
  def cancel_checklist_order(options={})
    click "link=Cancel"
    sleep 3
    self.fill_up_validation_info options if options[:er] != true
    select "reason", "label=CANCELLATION - EXPIRED"
    type "remarks", options[:remarks] || "remarks"
    click "btnOK", :wait_for => :page
    is_text_present("Special Units Home › Search Checklist Order") || is_text_present("Checklist SOA No. #{options[:soa_number]} has been cancelled.") || is_text_present("ER Patient Search › Search Checklist Order")
  end
  # Add Checklist Order
  def go_to_su_page_for_a_given_pin(page, pin)
    get_alert if is_alert_present
    select "userAction#{pin}", "label=#{page}"
    click Locators::NursingSpecialUnits.submit_button_spu, :wait_for => :page
    sleep 6
    if page == "regexp:Discharge Instructions\\s"
            page = "Discharge Instructions"
    end
    sleep 3
    is_text_present("#{page}")
  end
  def go_to_or_page_for_a_given_pin(page, pin)
    get_alert if is_alert_present
#    select "id=userAction#{pin}", "label=#{page}"


        select "id=userAction#{pin}", "#{page}"
        sleep 3
    click Locators::NursingSpecialUnits.submit_button_spu, :wait_for => :page
    sleep 3
    is_text_present("#{page}")
  end
  def go_to_er_page_for_a_given_pin(page, pin)
    select "userAction#{pin}", "label=#{page}" #if !(get_selected_label("userAction#{pin}").match page)
    click "//input[@type='button' and @value='Submit']", :wait_for => :page
  end
  def go_to_er_page_using_pin(page, pin)
    select "userAction#{pin}", "label=#{page}"
    #click "//html/body/div/div[2]/div[2]/table/tbody/tr/td[9]/input",:wait_for => :page
    click "//html/body/div[1]/div[2]/div[2]/table/tbody/tr/td[10]/input",:wait_for => :page
  end
  def search_service(options = {})
    service = options[:description] || "REMOVAL/APPLICATION OF CAST"
    click "orderTypeEl" if (options[:procedure] || !(is_checked("orderTypeEl")))
    click "css=#nonProcedureFlag" if options[:non_procedure]
    type "oif_entity_finder_key", service
    sleep 3
    click "name=search"
    sleep Locators::NursingGeneralUnits.waiting_time
    item_code = get_text Locators::NursingSpecialUnits.searched_service_code
    return item_code
  end
  def check_service(options = {})
    service = options[:description] || "REMOVAL/APPLICATION OF CAST"
    click "orderTypeEl" if (options[:procedure] || !(is_checked("orderTypeEl")))
    click "css=#nonProcedureFlag" if options[:non_procedure]
    type "oif_entity_finder_key", service
    sleep 3
    click "name=search"
    sleep Locators::NursingGeneralUnits.waiting_time
   # item_code = get_text Locators::NursingSpecialUnits.searched_service_code
    #return item_code
  end
  def add_returned_service(options = {})
    if options[:quantity]
      qanaes = options[:qty_anaes] || '1'
      qsurg = options[:qty_surg] || '1'
      type 'id=aQuantity', qanaes
      type 'id=sQuantity', qsurg
      
      sleep 3
    end
    click "//input[@value='Add']", :wait_for => :page
    sleep 6
    is_text_present("Order item #{options[:item_code]} - #{options[:description]} has been added successfully.")
  end
  def confirm_order(options ={})
    type "id=anaesthDoctorCode", options[:anaesth_code]
    type "id=surgeonDoctorCode", options[:surgeon_code]
    type "id=surgeonDoctorCode", "3325" if ((CONFIG['location']) == 'QC' && options[:surgeon_code] == "6726")
    sleep 2
    click "name=validateOrder", :wait_for => :page
    !is_text_present('Yikes')
  end
  def click_patient_admission_history
    click "link=Patient Admission History", :wait_for => :page
    is_text_present("Patient Search › Result List › Patient Admission History")
  end
  def continue_add_to_cart
    click "//div[4]/div/input[4]", :wait_for => :visible, :element => "orgStructureFinderForm"
    i_code = '0278'
    type "osf_entity_finder_key", i_code
    i_code_locator = "css=td:contains('#{i_code}')"
    click "//div[5]/div[2]/div[1]/input[1]", :wait_for => :element, :element => i_code_locator
    click i_code_locator, :wait_for =>  :not_visible, :element => 'orgStructureFinderForm'
    click "//input[@value='ADD']", :wait_for => :page
  end
  def click_permanent_address_same_as_present_address
    click "chkFillPermanentAddress"
    sleep 2
  end
  def click_spu_patient_search
    go_to_special_ancillary
    sleep 2
    click "link=Patient Search", :wait_for => :page
  end
  def click_spu_occupancy_list
    click_spu_patient_search
    sleep 2
    click "link=Occupancy List", :wait_for => :page
    is_text_present "Special Units Home"
  end
  def go_to_clinical_order_page(options ={})
    patient_pin_search options
    sleep 2
    select "userAction#{options[:pin]}", "label=Outpatient Clinical Order"
    click '//input[@type="button" and @value="Submit"]', :wait_for => :page
    is_text_present"Order Page"
  end
  def spu_occupancy_contents
    a = is_text_present("PIN")
    b = is_text_present("Patient Name")
    c = is_text_present("Gender")
    d = is_text_present("Birth Date")
    e = is_text_present("Age")
    f = is_text_present("Status")
    g = is_text_present("Action")
    return a && b && c && d && e && f && g # revised by jun 02/21/2012
  end
  def go_to_action_page(options={})
    click_spu_occupancy_list
    patient_pin_search options
    sleep 2
    select "userAction#{options[:pin]}", options[:action_page]
    click '//input[@type="button" and @value="Submit"]', :wait_for => :page
  end
  def spu_pf_charging(options={})
    click"admDoctorRadioButton0"
    if options[:add_pf]
      click"btnAddPf"
      select"pfTypeCode",options[:pf_type] || "COLLECT"
      type"pfAmountInput",options[:pf_amount] || "1000"
      click"btnAddPf"
      (get_text"doc0pf0_pfType") == options[:pf_type] || "COLLECT"
    end
    if options[:edit_pf]
      click"btnEditDoctor"
      select"doctorTypeCode",options[:doctor_type] || "ATTENDING"
      click"btnAddDoctor"

      click"0edit_pf0"
      type"pfAmountInput",options[:pf_amount] || "5000"
      click"0save_pf0"
      (get_text"doc0pf0_pfAmount")=="5,000.00"
    end
    if options[:delete_pf]
      click"0delete_pf0"
      get_confirmation if is_confirmation_present
    end
    if options[:save_pf]
      click'//input[@type="submit" and @value="Save" and @name="action"]', :wait_for => :page
      return true if is_text_present"PF successfully saved."
    end
  end
  def spu_view_order
    click "orderToggle"
    sleep 2
    return get_css_count "css=#tableRows>tr"
  end
  def spu_pf_payment(options={})
    click"pfPaymentToggle"
    sleep 2
    (get_text"paymentTotalPfHead") == options[:pf_amount] || "1,000.00"
    if options[:settle_pf]
        click'//input[@id="cashPaymentMode1" and @name="opsPfPaymentBean.cashPaymentMode"]'
        sleep 3
        pf_amount = get_value'//input[@id="cashAmountInPhp" and @name="opsPfPaymentBean.pbaCashPaymentBean.paymentAmountInPhp"]'
        type '//input[@id="cashBillAmount" and @name="opsPfPaymentBean.pbaCashPaymentBean.billAmount"]', pf_amount
        sleep 2
    end
  end
  def spu_hospital_bills(options={})
    #click"paymentToggle"
    if options[:type] == "CHECK"
      click"checkPaymentMode1"
      sleep 1
      type"cBankName", options[:bank_name] || "BANK"
      type"cCheckNo", options[:check_no] || "1234567890"
      type"cCheckDate", Date.today.strftime("%m/%d/%Y")
      type"cCheckAmount", options[:amount] || "20"
      click"addCheckPayment"
      (get_text"totalCheck") == options[:amount] || "20.00"

    elsif options[:type] == "CREDIT CARD"
      click "creditCardPaymentMode1"
      sleep 1
      select "ccCompany", "label=CITIBANK - PAYLITE"
      type "ccNo", options[:credit_no] || "4111111111111111"
      select "ccType", "label=VISA"
      click "ccHolder"
      type "ccHolder", options[:cc_holder] || "TEST"
      click "//div[@id='creditCardPaymentArea']/div[1]/div[9]/img"
      sleep 5
      click "link=#{Time.new.day}"
      type "ccApprovalNo", options[:cc_approv] ||"1234"
      type "ccSlipNo", options[:cc_slip] || "143"
      type "ccAccountNo", options[:cc_acctno] || "124"
      type "ccAmount", options[:amount] || "100"
      click "addCreditCardPayment"
      (get_text"totalCard") == options[:amount] || "100.00"

    elsif options[:type] == "BANK"
      click "bankRemittanceMode1"
      sleep 1
      type "brBank", options[:bank_name] || "Bank"
      type "brBranchDeposited", options[:bank_branch] || "Branch"
      type "brRemittanceAmount", options[:amount] || "80"
      type "brTransactionNumber", options[:trans_no] || "123456"
      type "brTransactionDate", options[:date] || Date.today.strftime("%m/%d/%Y")
      click "addBankRemittancePayment"
      (get_text"totalBankRemittance") == options[:amount] || "80.00"

    elsif options[:type] == "GC"
      click"giftCheckPaymentMode1"
      sleep 1
      type"gcNo","1234567890"
      click"addGiftCheckPayment"
      (get_text"TotalGC") == options[:amount] || "100.00"

    elsif options[:type] == "EWT"
       click"ewtMode1"
       sleep 1
       type"ewtCompany","EXIST"
       type"ewtAmount",options[:amount] || "50"
       type"ewtTinNo","123456789"
       (get_text"TotalEWT") == options[:amount] || "50.00"

    elsif options[:type] == "CASH"
      click "cashPaymentMode1"
      sleep 3
      amount = get_value("cashAmountInPhp").to_f
      type "cashBillAmount", amount
      sleep 5
      get_text("totalCash").gsub(',','').to_f == amount
    end
  end
  def spu_submit_bills(value="def")
    submit_button = is_element_present("submitForm") ?  "submitForm" : "//input[@type='submit' and @value='Proceed with Payment']"
    click submit_button, :wait_for => :page
     if value == "yes"
      click "popup_ok"
      sleep 10
      warning = get_text("css=div[id='successMessages']")
      return warning
    elsif value == "no"
      click "popup_cancel"
      sleep 2
      warning =  get_text("css=div[id='successMessages']")
      return warning
     elsif value == "defer"
      warning =  get_text("css=div[id='successMessages']")
      return warning
     end
     sleep 2
  end
  def go_to_ss_action_page(options ={})
    select "userAction#{options[:visit_no]}", options[:page]
    click '//input[@type="button" and @value="Submit"]', :wait_for => :page
  end
  def ss_benefactor(options ={})
    click'//input[@type="button" and @value="Add"]', :wait_for => :element, :element => "divAddCoPayorPopupTitle"
    click"searchBenefactorButton"
    type"bp_entity_finder_key","MEDICAL SOCIAL SERVICE"
    click'//input[@type="button" and @onclick="BusinessPartner.search();" and @value="Search"]'
    type"coverageAmount", options[:amount]
    click'//input[@type="button" and @onclick="AddCoPayorForm.addBenefactorToList();" and @value="Add Benefactor"]' if options[:add]
    click'//input[@type="button" and @value="Cancel"]' if options[:cancel]
  end
  def doctor_finder(options={})
    doctor_search = is_element_present("//input[@type='button' and @onclick=\"searchType='D';reinitDoctor();DF.show();\"]") ? "//input[@type='button' and @onclick=\"searchType='D';reinitDoctor();DF.show();\"]" : "//input[@type='button' and @onclick='reinitDoctor();DF.show();']" || "xpath=(//input[@type='button'])[41]" || "xpath=(//input[@type='button'])[31]"
    click doctor_search, :wait_for => :visible, :element => "entity_finder_key" if is_element_present(doctor_search)
    type "id=entity_finder_key", options[:doctor]
    sleep 3
    click "//input[@value='Search']", :wait_for => :element, :element =>  "//tbody[@id='finder_table_body']/tr/td[2]/div" ||  "//input[@value='Search']"
      sleep 3
      
    click "css=input[type=\"button\"]" if is_element_present("css=input[type=\"button\"]")
    sleep 3
    click "//tbody[@id='finder_table_body']/tr/td[2]/div", :wait_for => :not_visible, :element =>  "//tbody[@id='finder_table_body']/tr/td[2]/div"
    sleep 3
    click "css=div[title=\"Click to select.\"]" if is_element_present( "css=div[title=\"Click to select.\"]")
    sleep 3
    click "css=input[type=\"submit\"]" if is_element_present("css=input[type=\"submit\"]")
    sleep 6  
    click "css=input.myButton" if is_element_present("css=input.myButton")
    sleep 6
    click "css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]" if is_element_present("css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]")
    click 'css=#doctorSelectedPopUpDialog > div > input[type="submit"]' if is_element_present( 'css=#doctorSelectedPopUpDialog > div > input[type="submit"]')
    sleep 8

  end
  def special_ancillary_action_page(options={})
    select "userAction#{options[:pin]}", options[:action_page]
    click '//input[@type="button" and @value="Submit"]', :wait_for => :page
  end
  def search_er_checklist_order(options={})
    item = options[:code] || options[:description]
    click 'orderTypeEl' if options[:procedure]
    click 'nonProcedureFlag' if options[:supplies]
    click 'drugFlag' if options[:drugs]
    sleep 2
    type "oif_entity_finder_key", item
    click 'search', :wait_for => :element, :element => "link=#{item}"
    sleep 1
    is_text_present(item)
  end
  def add_er_checklist_order(options={})
    click "link=#{options[:description]}"
    type "remarks","REMARKS"
    type "sQuantity", options[:quantity] || "1"
    sleep 1
    if options[:special]
     type "serviceRateDisplay", options[:spdrugs_amount] || "100"
     type "itemDesc","SPECIAL DRUGS DESCRIPTION"
    end
    @item_code = get_value Locators::NursingGeneralUnits.searched_item_code
    @item_description = get_value Locators::NursingGeneralUnits.searched_item_description
    sleep 1
    click "//input[@type='button' and @value='Add']", :wait_for => :page
    return true if is_text_present("Order item #{@item_code} - #{@item_description} has been added successfully.")
  end
  # pass only inpatient or outpatient and script will update all the rates for items
  def update_rate_for_philhealth(admission_type)
    @path = "../csv/inpatient_ordered_items.csv" if admission_type == 'inpatient'
    @path = "../csv/or_ordered_items.csv" if admission_type == 'outpatient'

    my_file = CSV.read(@path)
    count = my_file.count
    w = []
    x = 1
    count.times do
      w << my_file[x][0]
      if x + 1 == my_file.count
      else
        x += 1
      end
    end

    Database.connect
    @info = []
    if admission_type == 'inpatient'
      w.each do |o|
        @info << get_item_rate(:inpatient => true, :item_code => o)
      end
    elsif admission_type == 'outpatient'
      w.each do |o|
        @info << get_item_rate(:outpatient => true, :item_code => o)
      end
    end

    line_arr = File.readlines(@path)
    File.open(@path, "w") do |f|
    line_arr = "MSERVICE_CODE,RATE,MRP_TAG,PH_CODE,ORDER_TYPE,DESCRIPTION"
      line_arr.each{|line| f.puts(line)}
    end

    @x = 0
    @info.each do |s|
      add_line_to_csv(@path, s)
      if (@x + 1) == @info.count
      else
        @x += 1
      end
    end
  end
  def er_search_checklist_order(options = {})
    click "link=Search Checklist Orders", :wait_for => :page
    type "startOrderDate", options[:date_today] if options[:date_today]
    type "endOrderDate", options[:date_today] if options[:date_today]
    type "endOrderDate", options[:date2] if options[:date2]
    type "txtSoaNumber", options[:soa_number] if options[:soa_number]
    type "param", options[:pin] if options[:pin]
    click "search", :wait_for => :page
    if options[:date2] && (options[:date_today] > options[:date2])
      return (get_text('//*[@id="orderGroupSearchBean.errors"]') == "Start Date should not be later than End Date.")
    end
    is_element_present("//html/body/div/div[2]/div[2]/div[8]/div[2]/table/tbody/tr/td")
  end
    def go_to_gu_room_tranfer_page(options ={})
    patient_pin_search options
    select "userAction#{options[:pin]}", "label=Request for Room Transfer"
    click Locators::NursingSpecialUnits.submit_button
  end

end