#!/bin/env ruby
# encoding: utf-8
require 'faker'
#require 'nokogiri'
require 'open-uri'
require File.dirname(__FILE__) + '/helpers/admission_helper'
require File.dirname(__FILE__) + '/helpers/locators'

module Admission
	include Locators::Registration
  include Locators::Admission
  include AdmissionHelper

	attr_accessor :slmc, :first_name, :last_name, :address, :first_name_to_notify, :last_name_to_notify, :middle_name, :pin, :elements

  def self.generate_data(options={})
    f_name = Faker::Name.first_name
    title = Faker::Name.prefix.upcase
    l_name = Faker::Name.last_name.gsub("'","")
    m_name = Faker::Name.last_name.gsub("'","")
    l_name_to_notify = Faker::Name.last_name
    f_name_to_notify = Faker::Name.first_name
    adrs = Faker::Address.street_address
    gender = ["M", "F"]
    day = AdmissionHelper.range_rand(1,29).to_s
    month = AdmissionHelper.range_rand(1, 13).to_s
    year = "19" + AdmissionHelper.range_rand(80,99).to_s
    day = "0" + day if day.length == 1
    month = "0" + month if month.length == 1 # Version 1.4.1d-RC3 rev.30200 October 18, 2011
    year = "19" + AdmissionHelper.range_rand(30,50).to_s if options[:senior]
    year = "19" + AdmissionHelper.range_rand(80,99).to_s if options[:not_senior]
    birth_day = "#{month}/#{day}/#{year}"
    spouse_fname = Faker::Name.first_name
    spouse_mname = Faker::Name.last_name
    spouse_lname = Faker::Name.last_name
    father_lname = Faker::Name.last_name
    mother_lname= Faker::Name.last_name
    father_mname = Faker::Name.last_name
    mother_mname= Faker::Name.last_name
    father_fname = Faker::Name.first_name
    mother_fname = Faker::Name.first_name
    employer_name = Faker::Name.first_name
    employer_address = Faker::Address.street_address
     mbirth_day = "#{day}/#{month}/#{year}"
    age = AdmissionHelper.calculate_age(Date.parse(mbirth_day))
    contact_type = ["HOME", "MOBILE", "WORK",  "EMERGENCY CONTACT"] #, "EMAIL"]
    id_type = ["AFP COMMISSIONED ID","COMPANY ID","DIPLOMAT ID","DRIVER'S LICENSE","GSIS ID","HDMF ID","IBP ID","MASON","OFW ID","OWWA ID","PASSPORT","PHILHEALTH CARD","PNP ID","POSTAL ID","PRC ID","PRC LICENSE","RETIRED OFFICERS ID","S2 ID","SCHOOL ID","SEAMANS BOOK","SSS ID","TIN","VOTER'S ID"]
    id_type = id_type.rand
    mid_type = "SENIOR CITIZEN ID" if options[:senior]
    id_type  = mid_type if options[:senior]
    selected_contact_type = contact_type.rand
    if selected_contact_type == "EMAIL"
      contact_details = f_name.downcase + "_" + l_name.downcase + "@" +  Faker::Internet.domain_name
    else
      contact_details =  "1234568" # Faker::PhoneNumber.phone_number # some formats generated are not valid in the registration
    end
      num = AdmissionHelper.range_rand(10,99).to_s
    patient_id1 = "1234568#{num}"
  {
      :first_name => f_name,
      :title => title,
      :last_name => l_name,
      :middle_name => m_name,
      :address => adrs,
      :last_name_to_notify => l_name_to_notify,
      :first_name_to_notify => f_name_to_notify,
      :gender => gender.rand,
      :contact_type => selected_contact_type,
      :contact_details => contact_details,
      :birth_day => birth_day,
      :age => age,
      :spouse_fname => spouse_fname,
      :spouse_mname => spouse_mname,
      :spouse_lname => spouse_lname,
      :employer_name => employer_name,
      :employer_address => employer_address,
      :father_lname => father_lname,
      :mother_lname => mother_lname,
      :father_mname => father_mname,
      :mother_mname => mother_mname,
      :father_fname => father_fname,
      :mother_fname => mother_fname,
      :id_type1 => id_type,
      :patient_id1 => patient_id1
    }
  end
  def self.generate_doctor_data
    f_name = Faker::Name.first_name
    l_name = Faker::Name.last_name
    m_name = Faker::Name.last_name
    gender = ["M", "F"]
    day = AdmissionHelper.range_rand(1,29).to_s
    month = AdmissionHelper.range_rand(1, 13).to_s
    day = "0" + day if day.length == 1
    month = "0" + month if month.length == 1 # Version 1.4.1d-RC3 rev.30200 October 18, 2011
    year = "19" + AdmissionHelper.range_rand(30,99).to_s
    doc_code = AdmissionHelper.range_rand(8000,9999).to_s
    birth_day = "#{month}/#{day}/#{year}"
    {
      :first_name => f_name,
      :last_name => l_name,
      :middle_name => m_name,
      :gender => gender.rand,
      :birth_day => birth_day,
      :doc_code => doc_code
    }
  end
  def outpatient_registration(options = {})
    type "name.lastName", options[:last_name] if options[:last_name]
    type "name.firstName", options[:first_name] if options[:first_name]
    type "name.middleName",options[:middle_name] if options[:middle_name]
    type "birthDate", options[:birth_day]
    sleep 2
    click "gender1" if options[:gender] == "M"
    click "gender2" if options[:gender] == "F"
    select "citizenship.code", "label=FILIPINO"
    
    type "id=patientRelation.mother.lastName", "motherlastName"
    type "id=patientRelation.mother.firstName", "motherfirstName"
    type "id=patientRelation.mother.middleName", "mothermiddleName"

    click Locators::NursingSpecialUnits.or_op_reg_save_button, :wait_for => :page
    if is_element_present(Locators::Registration.outpatient_pin)
      pin = get_text(Locators::Registration.outpatient_pin)
      sleep Locators::NursingGeneralUnits.create_patient_waiting_time
      return pin
    else
      return false
    end
  end
  def oss_outpatient_registration(options ={})
    type "name.lastName", options[:last_name] if options[:last_name]
    type "name.firstName", options[:first_name] if options[:first_name]
    type "name.middleName",options[:middle_name] if options[:middle_name]
    type "birthDate", options[:birth_day]
    select"citizenship.code", options[:citizenship] || "FILIPINO"
    sleep 2
    check "gender1" if options[:gender] == "M"
    check "gender2" if options[:gender] == "F"
    select "citizenship.code", "label=FILIPINO"
   if CONFIG['ver'] == "1.8.4"
    type "id=patientRelation.mother.lastName", "motherlastName"
    type "id=patientRelation.mother.firstName", "motherfirstName"
    type "id=patientRelation.mother.middleName", "mothermiddleName"
   end
    click "//input[@name='action' and @value='Save']"
    sleep 5
    click "//button[@type='button']", :wait_for => :page if is_element_present("//button[@type='button']")


    if is_element_present(Locators::Registration.oss_op_pin)
      pin = get_text(Locators::Registration.oss_op_pin)
      sleep Locators::NursingGeneralUnits.create_patient_waiting_time
      return pin
    else
      return false
    end
  end
  def verify_required_fields_for_op_reg
    click "//input[@name='action' and @value='Save']", :wait_for => :page if is_element_present "//input[@name='action' and @value='Save']"
    click Locators::NursingSpecialUnits.or_op_reg_save_button, :wait_for => :page if is_element_present Locators::NursingSpecialUnits.or_op_reg_save_button
    #get_text('//*[@id="*.errors"]') == "First Name is a required field.\nMiddle Name is a required field.\nLast Name is a required field.\nBirthdate is a required field.\nGender is a required field."
    get_text('//*[@id="patient.errors"]') == "First Name is a required field.\nMiddle Name is a required field.\nBirthdate is a required field.\nGender is a required field."
  end
  def spu_or_register_patient(options={})
    @org_codes = AdmissionHelper.get_org_codes_info(CONFIG['location'], options[:org_code]) if options[:org_code]
    click "turnedInpatientFlag1" if options[:turn_inpatient]
    select "accountClass", "label=#{options[:acct_class]}" if options[:acct_class]
    account_class = options[:acct_class] || "INDIVIDUAL"
    if account_class == "SOCIAL SERVICE"
      type "escNumber", options[:esc_no] || "234"
      type "initialDeposit", options[:ss_amount] || "100"
      select "clinicCode", options[:dept_code] || "MEDICINE"
    end
    select "admissionType.code", "label=#{options[:admission_type]}" if options[:admission_type]
    click "confidential1" if options[:confidential]
    click "roomNoFinder"
    type "rbf_entity_finder_roomChargeCode", options[:rch_code] if options[:rch_code]
    type "rbf_entity_finder_key", @org_codes[:org_code] if options[:org_code]
    type "rbf_room_no_finder_key", "XST" # manually added room exclusively for automation
    click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']"
    sleep 4
    click Locators::Admission.room_bed
    sleep 2
    type("diagnosisDateTime", Time.now.strftime("%m/%d/%Y")) if is_element_present("diagnosisDateTime")
    sleep 1
    if options[:doctor]
      self.doctor_finder(:doctor => options[:doctor])
    end
    if options[:preview]
      go_to_preview_page
      if options[:save_and_print]
        click "//input[@name='action' and @value='Save and Print']", :wait_for => :page
        get_text("//html/body/div/div[2]/div[2]/div[4]/div") == "Patient admission details successfully saved. Patient admission process complete."
      elsif options[:save]
        click "//input[@type='button' and @value='Save' and @onclick='submitForm(this);']", :wait_for => :page
        get_text("//html/body/div/div[2]/div[2]/div[3]/div") == "Patient admission details successfully saved."
      elsif options[:revise]
        click "//input[@name='action' and @value='Save and Print']", :wait_for => :page
        get_text("//html/body/div/div[2]/div[2]/form/div[2]/div/label") == "Admission Info"
      end
    elsif options[:cancel]
      click "//input[@name='action' and @value='Cancel']", :wait_for => :page
      is_element_present("criteria")
    elsif options[:cancel_registration]
      click Locators::NursingSpecialUnits.cancel_registration
      sleep 4
       if ((is_text_present"Confinement No")==false)
         popup = get_text"admCancelDlg"
         click"//button[2]"
         return popup
       else
         sleep 5
         type"reason","reason"
         click"//button[1]", :wait_for => :page
         is_text_present("Patient admission details successfully cancelled.")
       end
      if options[:admitted]
        sleep 5
        type "cancelReason", "reason"
        click "//input[@name='admissionCancelFormAction']", :wait_for => :page
        is_text_present("Patient admission details successfully cancelled.")
        #get_text("//html/body/div/div[2]/div[2]/div[3]/div") == "Patient admission details successfully cancelled."
      else
        sleep 5
        get_text('css=div[id=admCancelDlg] div[name="msg"]') == "Patient is not yet admitted."
      end
    end
  end
  def create_new_patient(options = {})
    civil_status = options[:civil_status] || "SINGLE"
    citizenship = options[:citizenship] || "FILIPINO"
    nationality = options[:nationality] || "FILIPINO"
    religion = options[:religion] || "ROMAN CATHOLIC"
    occupation = options[:occupation] || "Manager"
    employer = options[:employer] || "G2iX"
    employer_address = options[:employer_address] || "Ortigas Center"
    spouse_fname = options[:spouse_fname]
    spouse_mname = options[:spouse_mname]
    spouse_lname = options[:spouse_lname]
    click "link=New Patient", :wait_for => :page
    select "title.code", "label=#{options[:title]}" if options[:title]
    type "name.lastName", options[:last_name] if options[:last_name]
    type "name.firstName", options[:first_name] if options[:first_name]
    type "name.middleName", options[:middle_name] if options[:middle_name]
    gender = options[:gender] if options[:gender]
    click 'gender1' if gender == "M"
    click 'gender2' if gender == "F"
    type 'birthDate', options[:birth_day]
    type 'birthPlace', "MANILA"
    select 'civilStatus.code', "label=#{civil_status}"
    select 'nationality.code', "label=#{nationality}"
    select 'religion.code', "label=#{religion}"
    select "citizenship.code", "label=#{citizenship}"
    select "id=idType[0]", "label=#{options[:id_type1]}" if options[:id_type1]
    type "patientIds0.idNo", options[:patient_id1] if options[:patient_id1]

    select "patientIds0.phMemberTypeCode", "label=#{options[:member_type1]}" if options[:member_type1]
    select "patientIds0.phRelationshipCode", "label=#{options[:member_relation1]}" if options[:member_relation1]
    sleep 1
    type 'patientAdditionalDetails.occupation', occupation
    type 'patientAdditionalDetails.employer', employer
    type 'patientAddresses[2].streetNumber', employer_address
    type 'spouseTelephoneNum', '1234567'
    type 'spouseLastName', spouse_lname
    type 'spouseFirstName', spouse_fname
    type 'spouseMiddleName', spouse_mname
    type "presentAddrNumStreet", options[:address] if options[:address]
    click 'chkFillPermanentAddress'
    select "presentContactSelect", "label=#{options[:contact_type]}" if options[:contact_type]  # "label=HOME"
    type "presentContact1", options[:contact_details] if options[:contact_details] #"12345678"
    type "motherLastName", options[:mother_lname]
    type "fatherLastName", options[:father_lname]
    type "motherFirstName", options[:mother_fname]
    type "fatherFirstName", options[:father_fname]
    type "motherMiddleName", options[:mother_mname]
    type "fatherMiddleName", options[:father_mname]
    type "erLastName", options[:last_name_to_notify] if options[:last_name_to_notify]
    type "erFirstName", options[:first_name_to_notify] if options[:first_name_to_notify]
    sleep 3
    ########### ADDITIONAL INFO WORKAROUND #########
    #    type "patientAdditionalDetails.occupation", "manager"
    #    type "patientAdditionalDetails.employer", "g2ix"
    #    type "patientAddresses2.buildingName", "ortigas center"
    #    type "patientAdditionalDetails.position", "senior quality assurance engineer"
    #    type "patientAdditionalDetails.yearsOfService", "2"
    #    type "patientAdditionalDetails.salary", "80000"
    #    type "patientAdditionalDetails.otherSources", "artist"
    #    select "patientAdditionalDetails.primaryLanguage.code", "label=FILIPINO"
    #    select "patientAdditionalDetails.secondaryLanguage.code", "label=ENGLISH"

    select "patientAdditionalDetails.primaryLanguage.code", "label=#{options[:primary_language]}" if options[:primary_language]
    select "patientAdditionalDetails.secondaryLanguage.code", "label=#{options[:secondary_language]}" if options[:secondary_language]
    if options[:preview]
          click "//input[@name='action' and @value='Preview']"  #:wait_for => :page if options[:preview]
           #click "xpath=(//input[@name='action'])[5]"
           sleep 3
           click "xpath=(//button[@type='button'])[3]" if is_element_present("xpath=(//button[@type='button'])[3]")
           sleep 10
          if is_element_present("id=patient.errors")
                  return get_text("id=patient.errors")
          else
                  if options[:senoir]
                       click("//button[@type='button']",:wait_for => :page);
                  end
                   sleep 3
                  click "xpath=(//input[@name='action'])[2]" if is_element_present("xpath=(//input[@name='action'])[2]")
                  sleep 10
                  if is_element_present(Locators::Registration.pin)
                          puts pin
                          pin = get_text(Locators::Registration.pin)
                          sleep Locators::NursingGeneralUnits.create_patient_waiting_time
				       pin = pin.gsub(" ", "")													
                          return pin
                  else
                         return false
                  end
          end
    else
           sleep 10      
          click "//input[@name='action' and @value='Preview']" # :wait_for => :page
           sleep 10
           click "xpath=(//button[@type='button'])[3]" if is_element_present("xpath=(//button[@type='button'])[3]")

          if options[:senoir]
                 click("//button[@type='button']");
          end
           sleep 10
          click "//input[@name='action' and @value='Save Patient']" if is_element_present("//input[@name='action' and @value='Save Patient']")
           sleep 10          
          click "xpath=(//input[@name='action'])[2]" if is_element_present("xpath=(//input[@name='action'])[2]")

           #wait_for_text("Patient Information")
           sleep 50
          if is_element_present(Locators::Registration.pin)
                  puts pin
                  pin = get_text(Locators::Registration.pin)
                  sleep Locators::NursingGeneralUnits.create_patient_waiting_time
				pin = pin.gsub(" ", "")
                  return pin
          else
                 return false
          end
    end
  end
  def mycreate_new_patient(options = {})
    civil_status = options[:civil_status] || "SINGLE"
    citizenship = options[:citizenship] || "FILIPINO"
    nationality = options[:nationality] || "FILIPINO"
    religion = options[:religion] || "ROMAN CATHOLIC"
    occupation = options[:occupation] || "Manager"
    employer = options[:employer] || "G2iX"
    employer_address = options[:employer_address] || "Ortigas Center"
    spouse_fname = options[:spouse_fname]
    spouse_mname = options[:spouse_mname]
    spouse_lname = options[:spouse_lname]
    if  options[:new]
          click "link=New Patient", :wait_for => :page
    end
    select "title.code", "label=#{options[:title]}" if options[:title]
    type "name.lastName", options[:last_name] if options[:last_name]
    type "name.firstName", options[:first_name] if options[:first_name]
    type "name.middleName", options[:middle_name] if options[:middle_name]
    gender = options[:gender] if options[:gender]
    click 'gender1' if gender == "M"
    click 'gender2' if gender == "F"
    type 'birthDate', options[:birth_day]
    type 'birthPlace', "MANILA"
    select 'civilStatus.code', "label=#{civil_status}"
    select 'nationality.code', "label=#{nationality}"
    select 'religion.code', "label=#{religion}"
    select "citizenship.code", "label=#{citizenship}"
    select "patientIds0.idTypeCode", "label=#{options[:id_type1]}" if options[:id_type1]
    type "patientIds0.idNo", options[:patient_id1] if options[:patient_id1]
    select "patientIds0.phMemberTypeCode", "label=#{options[:member_type1]}" if options[:member_type1]
    select "patientIds0.phRelationshipCode", "label=#{options[:member_relation1]}" if options[:member_relation1]
    sleep 1
    type 'patientAdditionalDetails.occupation', occupation
    type 'patientAdditionalDetails.employer', employer
    type 'patientAddresses[2].streetNumber', employer_address
    type 'spouseTelephoneNum', '1234567'
    type 'spouseLastName', spouse_lname
    type 'spouseFirstName', spouse_fname
    type 'spouseMiddleName', spouse_mname
    type "presentAddrNumStreet", options[:address] if options[:address]
    click 'chkFillPermanentAddress'
    select "presentContactSelect", "label=#{options[:contact_type]}" if options[:contact_type]  # "label=HOME"
    type "presentContact1", options[:contact_details] if options[:contact_details] #"12345678"
    type "motherLastName", options[:mother_lname]
    type "fatherLastName", options[:father_lname]
    type "motherFirstName", options[:mother_fname]
    type "fatherFirstName", options[:father_fname]
    type "motherMiddleName", options[:mother_mname]
    type "fatherMiddleName", options[:father_mname]
    type "erLastName", options[:last_name_to_notify] if options[:last_name_to_notify]
    type "erFirstName", options[:first_name_to_notify] if options[:first_name_to_notify]
    sleep 3
    ########### ADDITIONAL INFO WORKAROUND #########
    #    type "patientAdditionalDetails.occupation", "manager"
    #    type "patientAdditionalDetails.employer", "g2ix"
    #    type "patientAddresses2.buildingName", "ortigas center"
    #    type "patientAdditionalDetails.position", "senior quality assurance engineer"
    #    type "patientAdditionalDetails.yearsOfService", "2"
    #    type "patientAdditionalDetails.salary", "80000"
    #    type "patientAdditionalDetails.otherSources", "artist"
    #    select "patientAdditionalDetails.primaryLanguage.code", "label=FILIPINO"
    #    select "patientAdditionalDetails.secondaryLanguage.code", "label=ENGLISH"

    select "patientAdditionalDetails.primaryLanguage.code", "label=#{options[:primary_language]}" if options[:primary_language]
    select "patientAdditionalDetails.secondaryLanguage.code", "label=#{options[:secondary_language]}" if options[:secondary_language]
    if options[:preview]
      click "//input[@name='action' and @value='Preview']", :wait_for => :page if options[:preview]
      return get_text("errorMessages") if is_element_present("errorMessages")
    else
      click "//input[@name='action' and @value='Preview']", :wait_for => :page
      click "//input[@name='action' and @value='Save Patient']", :wait_for => :page
      if is_element_present(Locators::Registration.pin)
        puts pin
        pin = get_text(Locators::Registration.pin)
        sleep Locators::NursingGeneralUnits.create_patient_waiting_time
        return pin
      else
        return false
      end
    end
  end
  # create new patient in DAS OSS with its new UI - Patient Demographics
  def oss_create_new_patient(options = {})
    click "link=Create New Patient", :wait_for => :page
    #select "title.code", "label=#{options[:title]}" if options[:title]
    #click "//option[@value='TTL01']"
    type "patient.name.lastName", options[:last_name] if options[:last_name]
    type "patient.name.firstName", options[:first_name] if options[:first_name]
    type "patient.name.middleName", options[:middle_name] if options[:middle_name]
    gender = options[:gender] if options[:gender]
    click 'gender1' if gender == "M"
    click 'gender2' if gender == "F"
    type 'birthDate', options[:birth_day]
    citizenship = options[:citizenship] || "FILIPINO"
    
    type "id=patientRelation.mother.lastName", "motherlastName" if is_element_present("id=patientRelation.mother.lastName")
    type "id=patientRelation.mother.firstName", "motherfirstName" if is_element_present( "id=patientRelation.mother.firstName")
    type "id=patientRelation.mother.middleName", "mothermiddleName" if is_element_present("id=patientRelation.mother.middleName")

    select "patient.nationality.code", "label=#{citizenship}"
    select "patient.citizenship.code", "label=#{citizenship}"
    type "presentAddrNumStreet", options[:address] if options[:address]
    click 'chkFillPermanentAddress'
    select "presentContactSelect", "label=#{options[:contact_type]}" if options[:contact_type]  # "label=HOME"
    type "presentContact1", options[:contact_details] if options[:contact_details] #"12345678"
    click "link=Visit Information", :wait_for => :element, :element => "erLastName"
    type "erLastName", options[:last_name_to_notify] if options[:last_name_to_notify]
    type "erFirstName", options[:first_name_to_notify] if options[:first_name_to_notify]
    if options[:clinical_data]
      click "link=Clinical Data"
      sleep 2
      click "allergiesToggle"
      type "allergyName","SELENIUM_TEST"
      select "allergyType","FOOD ALLERGY" #AT001
      type "reportedBy","SELENIUM_TEST"
      type "allergyNote","NOTE"
      click "addAllergy"
      sleep 1

      click "medicalDevicesToggle"
      type "device", "SELENIUM_TEST"
      type "indication", "SELENIUM_TEST"
      type "startDateMedicalDevice", Time.now.strftime("%m/%d/%Y")
      type "endDateMedicalDevice", Time.now.strftime("%m/%d/%Y")
      type "medicalDeviceNote", "NOTE"
      click "addMedicalDevice"
      sleep 1

      click "proceduresToggle"
      type "procedureName", "SELENIUM_TEST"
      type "dateRequested", Time.now.strftime("%m/%d/%Y")
      type "datePerformed", Time.now.strftime("%m/%d/%Y")
      type "hospital", "SLMC"
      type "procedureNote", "NOTE"
      click "addProcedure"
      sleep 1
    end
    if options[:save_and_print]
      click'btnSaveAndPrint', :wait_for => :element, :element => 'divProcPopup'
      type'txtNumResults',options[:number_of_results] || '1'
      click'btnProcPrint', :wait_for => :page
    else
      click "btnSave"
      sleep 6
      click "//button[@type='button']"
      sleep 6

    end
    is_text_present "Patient successfully saved."
    if is_element_present(Locators::Registration.pin)
      pin = get_text(Locators::Registration.pin)
      sleep Locators::NursingGeneralUnits.create_patient_waiting_time
      return pin
    else
      return false
    end
  end
  def ss_create_outpatient_er(options={})
    click_outpatient_registration
    #different from outpatient_registration and oss_outpatient_registration due to there is no citizenship code.
    type "name.lastName", options[:last_name] if options[:last_name]
    type "name.firstName", options[:first_name] if options[:first_name]
    type "name.middleName",options[:middle_name] if options[:middle_name]
    type "birthDate", options[:birth_day]
    sleep 2
    click "genderM" if options[:gender] == "M"
    click "genderF" if options[:gender] == "F"
    
    type "id=patientRelation.mother.lastName", "motherlastName" if is_element_present("id=patientRelation.mother.lastName")
    type "id=patientRelation.mother.firstName", "motherfirstName" if is_element_present( "id=patientRelation.mother.firstName")
    type "id=patientRelation.mother.middleName", "mothermiddleName" if is_element_present("id=patientRelation.mother.middleName")
    click Locators::NursingSpecialUnits.admin_reg_save_button, :wait_for => :page
    if is_element_present(Locators::Registration.outpatient_pin)
      pin = get_text(Locators::Registration.outpatient_pin)
      sleep Locators::NursingGeneralUnits.create_patient_waiting_time
      return pin
    else
      return false
    end
  end
  # create new patient - registration form
  def fill_out_registration_form(options = {})
    select "title.code", "label=#{options[:title]}" if options[:title]
    click "//option[@value='TTL01']"
    type "name.lastName", options[:last_name] if options[:last_name]
    type "name.firstName", options[:first_name] if options[:first_name]
    type "name.middleName", options[:middle_name] if options[:middle_name]
    gender = options[:gender] if options[:gender]
    click 'gender1' if gender == "M"
    click 'gender2' if gender == "F"
    type 'birthDate', options[:birth_day]
    select "citizenship.code", "label=FILIPINO"
    type "presentAddrNumStreet", options[:address] if options[:address]
    click"//input[@id='chkFillPermanentAddress' and @type='checkbox' and @onclick='PF.fillPermanentAddress(this.checked)']"
    select "presentContactSelect", "label=#{options[:contact_type]}" if options[:contact_type]  # "label=HOME"
    type "presentContact1", options[:contact_details] if options[:contact_details] #"12345678"
    type "erLastName", options[:last_name_to_notify] if options[:last_name_to_notify]
    type "erFirstName", options[:first_name_to_notify] if options[:first_name_to_notify]
    select"civilStatus.code",options[:civil_status] || "SINGLE"
    type"birthPlace",options[:birth_place] || "PLACE"
    select"nationality.code",options[:nationality] || "FILIPINO"
    select"religion.code",options[:religion] || "CHRISTIAN"
    type"patientAdditionalDetails.occupation",options[:occupation] || "QA"
    type"patientAdditionalDetails.employer",options[:employer] || "EXIST"
    type"spouseLastName",options[:spouse_last_name] || "LASTNAME"
    type"spouseFirstName",options[:spouse_first_name] || "FIRSTNAME"
    type"spouseMiddleName",options[:spouse_middle_name] || "MIDDLENAME"
    type"spouseTelephoneNum",options[:spouse_number] || "1234567"
    type "motherLastName", options[:mother_lname]
    type "fatherLastName", options[:father_lname]
    type "motherFirstName", options[:mother_fname]
    type "fatherFirstName", options[:father_fname]
    type "motherMiddleName", options[:mother_mname]
    type "fatherMiddleName", options[:father_mname]
    type"//input[@id='permanentAddrNumStreet' and @type='text' and @name='patientAddresses[2].streetNumber']",options[:employer_address] || "ADDRESS"
    click "//input[@type='button' and @value='Preview']", :wait_for => :page
    click "//input[@name='action' and @value='Save Patient' and @type='submit']", :wait_for => :page
    sleep Locators::NursingGeneralUnits.create_patient_waiting_time
    get_text "successMessages"
  end
  def admission_search(options = {})
    go_to_admission_page
    type 'param',  options[:pin] || options[:last_name] || self.pin
    click "admitted" if options[:admitted]
    search_button = is_element_present( '//input[@value="Search" and @type="button" and @onclick="submitPSearchForm(this);"]') ?  '//input[@value="Search" and @type="button" and @onclick="submitPSearchForm(this);"]' :  '//input[@type="submit" and @value="Search" and @name="action"]' #@name="action" in 1.4.2
    click(search_button, :wait_for => :page)
    sleep 40
    if (is_element_present "//table[@id='results']/tbody/tr/td[3]/b") || (is_element_present "//table[@id='results']/tbody/tr/td[4]/b") || (is_element_present "//table[@id='results']/tbody/tr/td[5]/b") || (is_element_present "//html/body/div/div[2]/div[2]/div[22]/table/tbody/tr/td[4]")
      if options[:admitted]
        is_element_present "link=Cancel Admission"
			else
				is_element_present "link=Admit Patient"
        return true
      end
      
    elsif options[:no_result]
      get_text('css=table[id=results] tbody tr[class="odd"]')
    elsif (is_element_present('css=div[class="warning"]'))
      get_text('css=div[class="warning"]')
    end
  end
  def assign_doctor(options={})
    doctor = options[:doctor] || "ABAD"
    self.doctor_finder(:doctor => doctor)
    return true
  end
  def admission_search_prev_conf_patient(options={}) # patient is previously confined
    go_to_admission_page
    type "criteria",  options[:pin] || options[:last_name] || self.pin
    click "admitted" if options[:admitted]
    search_button = is_element_present( '//input[@value="Search" and @type="button" and @onclick="submitPSearchForm(this);"]') ?  '//input[@value="Search" and @type="button" and @onclick="submitPSearchForm(this);"]' :  '//input[@type="submit" and @value="Search" and @name="search"]'
    click search_button, :wait_for => :page
    sleep 2
    if (is_element_present "//table[@id='results']/tbody/tr/td[4]/b") || (is_element_present "//table[@id='results']/tbody/tr/td[5]/b")
      if options[:admitted]
        is_element_present "link=Update Patient Info"
			if
				is_element_present "link=New Admission"
      else
        is_element_present "link=View Confinement History"
      end
    elsif options[:no_result]
      get_text('css=table[id=results] tbody tr[class="odd"]')
    elsif (is_element_present('css=div[class="warning"]'))
      get_text('css=div[class="warning"]')
    end
  end
  end
  def add_diagnosis(options={})
    click "//input[@value='' and @type='button']"
    sleep 3
    diagnosis = options[:diagnosis] || "GASTRITIS"
    type "diagnosis_entity_finder_key", diagnosis
    click "//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']", :wait_for => :element, :element => "link=#{diagnosis}"
    click "link=#{diagnosis}"
    sleep 5
    return true
  end
  def assign_room_location(options={})
    sleep 2
    select "roomChargeCode", "label=#{options[:room_charge]}" if options[:room_charge]
    @org_codes = AdmissionHelper.get_org_codes_info(CONFIG['location'], options[:org_code])
    rch_code = options[:rch_code]
    org_code = @org_codes[:org_code]
    unless options[:on_queue]
      if rch_code && org_code
        self.find_room_using_room_charge(:rch_code => rch_code, :org_code => org_code)
      elsif rch_code
        self.find_room_using_room_charge(:rch_code => rch_code)
      else
        self.get_room_location
      end
      sleep 5
      click Locators::Admission.room_bed
      sleep 2
    end
    org_code = get_value("nursingUnitCode")
    return true
  end
  def outpatient_admission_search(options = {})
    go_to_admission_page
    patient_pin_search options #|| options[:last_name] || self.pin
  end
  def verify_search_results(options = {})
    sleep 2
    if options[:with_results]
      c1 = is_element_present("//table[@id='results']/tbody/tr/td[4]/b") || is_element_present("//table[@id='results']/tbody/tr/td[5]/b")  || (is_element_present "//html/body/div/div[2]/div[2]/div[22]/table/tbody/tr/td[4]")
		elsif options[:no_results]
			c1 = is_text_present "NO PATIENT FOUND"
    end
    return c1
  end
  def find_room_using_room_charge(options = {})
  #  click "roomNoFinder"
    click "id=roomNoFinder"

    type "rbf_entity_finder_roomChargeCode", options[:rch_code] if options[:rch_code]
    type "rbf_entity_finder_key", options[:org_code] if options[:org_code]
    type "rbf_room_no_finder_key", "XST" # manually added room exclusively for automation
    click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']", :wait_for => :element, :element => Locators::Admission.room_bed
    sleep 1
    !(is_text_present("0 items found, displaying 0 to 0"))
  end
  def get_room_charge_codes
    @rch_codes = []
    (4..37).each {|x| @rch_codes << "RCH0#{x}"}
    return @rch_codes
  end
  def get_room_using_room_charge
    @rch_code= @rch_codes.shift
    find_room_using_room_charge(:rch_code => @rch_code)
  end
  def get_room_location
    get_room_charge_codes
    while (self.get_room_using_room_charge == false)
    	Proc.new {self.get_room_using_room_charge}
    end
  end
  def create_new_admission(options = {})
    click "link=Admit Patient", :wait_for => :page
   # @org_codes = AdmissionHelper.get_org_codes_info(CONFIG['location'], options[:org_code]) unless options[:on_queue]
    wait_for(:wait_for => :text, :text => "REGULAR PRIVATE" )
    account_class = options[:account_class] || "INDIVIDUAL"
    admission_type = options[:admission_type] || "DIRECT ADMISSION"
    mobilization = options[:mobilization] || "AIRLIFT"
#    select "accountClass", "label=#{account_class}"
    select "id=accountClass", "label=#{account_class}"

    select "mobilizationTypeCode", "label=#{mobilization}"
    select "admissionTypeCode", "label=#{admission_type}"
    click("confidential1") if options[:confidentiality]
    select 'confidentialityCode', 'label=USUAL CONTROL' if options[:confidentiality]
    if account_class == "SOCIAL SERVICE"
      type "escNumber", options[:esc_no]
      type "initialDeposit", options[:ss_amount] || "100"
      select "clinicCode", options[:dept_code] || "S - MEDICINE"
     # select "clinicCode", options[:dept_code] || "MEDICINE"
    end
    sleep 1
    click "xpath=(//input[@value=''])[9]"
    sleep 2
    select "id=selectedReturnReason", "label=REPUTATION AS HAVING THE BEST DOCTORS"
    sleep 2
    click "id=addReason"
    sleep 2
    click "id=OKreasons"
    sleep 2

    if options[:additional_bed]
      click("tempRoomChargeFlag")
      sleep 5
      select "roomChargeCode", "label=#{options[:room_charge]}"
    else
      select "roomChargeCode", "label=#{options[:room_charge]}" if options[:room_charge]
    end
    rch_code = options[:rch_code]
 # org_code = @org_codes[:org_code]
    org_code =options[:org_code]

    unless options[:on_queue]
      if rch_code && org_code
        self.find_room_using_room_charge(:rch_code => rch_code, :org_code => org_code)
      elsif rch_code
        self.find_room_using_room_charge(:rch_code => rch_code)
      else
        self.get_room_location
      end
      sleep 5
      room_count = get_css_count "css=#rbf_finder_table_body>tr"
      random_room = 1 + rand(room_count)
      click Locators::Admission.room_bed(:random => (random_room))
      sleep 2
    end
    click "onQueue" if options[:on_queue]
    a = (DateTime.now).strftime("%m/%d/%Y")
    b = " 12:00 AM"
    admitting_diagnosis = a + b
    type "id=diagnosisDate", (admitting_diagnosis).to_s
    click "//input[@value='' and @type='button']", :wait_for => :text, :text => "Search For Diagnosis"
    diagnosis = options[:diagnosis] || "GASTRITIS"
    type "diagnosis_entity_finder_key", diagnosis
    click "//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']", :wait_for => :element, :element => "link=#{diagnosis}"
    click "link=#{diagnosis}", :wait_for => :not_visible, :element => "link=#{diagnosis}"
    sleep 2
    if options[:package]
      sleep 5
      click "searchAdmissionPackage", :wait_for => :visible, :element => "packageDialog" if !is_visible("packageDialog")
      sleep 7
      x= get_xpath_count("//html/body/div[6]/div[2]/table/tbody/tr")
      #x = get_xpath_count("//html/body/div[6]/div[2]/table/tbody")
#       x = get_xpath_count( '//*[@id="ecuPackages"]')
     x= (x).to_i
      x = x - 2
      puts "Total count = #{x}"
      while x > 0
#                if x == 0
#                  package_name = get_text("//html/body/div[6]/div[2]/table[1]/tbody/tr[1]/td[1]")
#                  a = ("//html/body/div[6]/div[2]/table/tbody/tr[1]/td[1]/a/div")
#                else
                  package_name = get_text("//html/body/div[6]/div[2]/table/tbody/tr[#{x}]/td[1]")
                  a = ("//html/body/div[6]/div[2]/table/tbody/tr[#{x}]/td[1]/a/div")
   #             end
                puts package_name
                package_name = (package_name).to_s
                if  options[:package]== package_name
                    click(a)
                    sleep 3
                    x = 0
                end
                x = x - 1

      end
#      click "link=#{options[:package]}"
#      get_value("admissionPackageDesc") == options[:package]
    end
    options[:doctor_code] = '1008'
    if options[:doctor_code]
      type 'id=doctorCode', options[:doctor_code]
      type 'id=doctorCode', '1008' if (options[:doctor_code] == "1008" && CONFIG['locations'] == 'QC')
    else
      self.doctor_finder(:doctor => "ABAD")
      puts "3"
    end

    if options[:guarantor_code]
      click "searchGuarantorBtn"
      if (account_class == "EMPLOYEE") || (account_class == "EMPLOYEE DEPENDENT")
        type "employee_entity_finder_key", (options[:last_name] if options[:last_name]) || (options[:guarantor_code] if options[:guarantor_code])
        full_name_link = "link=#{options[:last_name].upcase}, #{options[:first_name].upcase} #{options[:middle_name].upcase}" if options[:last_name] #|| "link=RUIZ, MICHAEL PEREZ"
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
      sleep 6
      click full_name_link if options[:last_name]
      if is_element_present("link=#{options[:guarantor_code]}")
        click "link=#{options[:guarantor_code]}" if options[:guarantor_code]
      else
#        sleep 5
#        click "css=#ddf_finder_table_body>tr>td>div"
      end
      sleep 3
      select "guarantorRelationCode", ("label=#{options[:relationship]}" if options[:relationship]) || "label=SELF"
    end

    select "guarantorRelationCode", "label=#{options[:relationship]}" if options[:relationship]
    type "guarantorTelNo", "23907654"
    type "guarantorAddress", "sample" if get_value("guarantorAddress") == ""
    sleep 6
    if account_class == "HMO" || account_class == "COMPANY" ||  account_class == "WOMEN'S BOARD MEMBER" ||  account_class == "WOMEN'S BOARD DEPENDENT"
      #    gname = get_text('//*[@id="claimedGuarantor"]')
            sleep 3
            type "id=guarantorName", options[:guarantor_code]
    end
    if account_class == "HMO"
            click "xpath=(//input[@type='button'])[45]"
            sleep 3
            diagnosis = options[:doctor_code] || "1008"
            type "id=entity_finder_key", diagnosis
            sleep 3
            click "css=input[type=\"button\"]"
            sleep 3
    end
    if account_class == "BOARD MEMBER DEPENDENT" || account_class == "BOARD MEMBER"
      sleep 6
      name = get_text('//*[@id="claimedGuarantor"]')

      if name == ""
        Database.connect
            a =  "SELECT DESCRIPTION FROM SLMC.REF_BUSINESS_PARTNER WHERE CODE ='#{options[:guarantor_code]}'"
            aa = Database.select_statement a
            aa.should_not == nil
        Database.logoff
        name = aa
      end
    if get_text("id=doctorCode") == ""
          type("id=doctorCode","1008")
           sleep 3
  end
      puts "name - #{name}"
      type "id=guarantorName",name
    end
    if options[:preview]
      sleep 6
      click("//input[@type='button' and @value='Preview' and @name='action' and @onclick='submitForm(this);']")  if is_element_present("//input[@type='button' and @value='Preview' and @name='action' and @onclick='submitForm(this);']")
      sleep 6
      click "//input[@value='Save Admission']" if is_text_present("//input[@value='Save Admission']")
      click "name=action" if is_element_present("name=action")
      sleep 6
          if account_class == "INDIVIDUAL"
            sleep 6
            click ("//button[@type='button']"),:wait_for => :page  if is_element_present("//button[@type='button']")
          end
    else
      sleep 6
      click("//input[@type='button' and @value='Preview' and @name='action']") if is_element_present("//input[@type='button' and @value='Preview' and @name='action']")
      sleep 6
      click "//input[@value='Save Admission']" if is_text_present("//input[@value='Save Admission']")
      sleep 6
      click("name=action") if is_element_present("name=action")
      sleep 3
          if account_class == "INDIVIDUAL"
                 sleep 6
                click("//button[@type='button']",:wait_for => :page) if is_element_present("//button[@type='button']")
          end
    end
    n_relationship = is_text_present("Relation to Patient: " + options[:relationship]) if options[:check_relation]
    return "error" if is_text_present("error")

    if options[:sap]
      click "//input[@type='button' and @onclick='submitForm(this);' and @value='Save and Print Admission']", :wait_for => :page
    else
      sleep 3
      click("//input[@value='Save Admission']", :wait_for => :page) if is_text_present("//input[@value='Save Admission']")
      sleep 3
      click("//input[@type='button' and @onclick='submitForm(this);' and @value='Save Admission']", :wait_for => :page)  if is_element_present("//input[@type='button' and @onclick='submitForm(this);' and @value='Save Admission']")
    end
    
    while is_text_present("already occupied by another patient") # re-admit patient if selected room is already have a patient
      if rch_code && org_code
        self.find_room_using_room_charge(:rch_code => rch_code, :org_code => org_code)
      elsif rch_code
        self.find_room_using_room_charge(:rch_code => rch_code)
      else
        self.get_room_location
      end
      sleep 5
      room_count = get_css_count "css=#rbf_finder_table_body>tr"
      random_room = 1 + rand(room_count)
      click Locators::Admission.room_bed(:random => (random_room))
      sleep 2
      click("//input[@type='button' and @value='Preview' and @name='action']", :wait_for => :page)
      click "//input[@type='button' and @onclick='submitForm(this);' and @value='Save Admission']", :wait_for => :page
    end
    sleep 30
    return true if n_relationship == true
    return get_text("errorMessages") if is_element_present("errorMessages")
    return get_text "successMessages" if is_element_present("successMessages")

  end
  # create new admission - admission form
  def fill_out_admission_form(options = {})#incomplet fill out
    @org_codes = AdmissionHelper.get_org_codes_info(CONFIG['location'], options[:org_code] || "0287") if options[:org_code]
    org_code = @org_codes[:org_code]
    room_charge = options[:room_charge] || "REGULAR PRIVATE"
    select "roomChargeCode",room_charge
    click "roomNoFinder"
    type "rbf_entity_finder_roomChargeCode", options[:rch_code] if options[:rch_code]
    type "rbf_entity_finder_key", org_code
    type "rbf_room_no_finder_key", "XST"
    click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']"
    sleep 4
    click Locators::Admission.room_bed
    sleep 2
    if options[:diagnosis]
      click "//input[@value='' and @type='button']"
      type "diagnosis_entity_finder_key", options[:diagnosis]
      click "//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']", :wait_for => :element, :element =>  "link=#{options[:diagnosis]}"
      click "link=#{options[:diagnosis]}"
    end
    sleep 8
    if options[:doctor]
      self.doctor_finder(:doctor => options[:doctor])
    end
    type "guarantorTelNo", "1230988"
    sleep 1
    if options[:preview]
      go_to_preview_page
    end
  end
  def update_patient_registration(options = {})
    go_to_outpatient_nursing_page
    patient_pin_search options
    click "link=Update Patient", :wait_for => :page
   	select "title.code", "label=#{options[:title]}" if options[:title]
    type "presentAddrNumStreet", options[:address] if options[:address]
    select "presentContactSelect", "label=#{options[:contact_type]}" if options[:contact_type]
    type "presentContact1", options[:contact_details]
    type "erLastName", options[:last_name_to_notify] if options[:last_name_to_notify]
    type "erFirstName", options[:first_name_to_notify] if options[:first_name_to_notify]
    click "//input[@name='action' and @value='Preview']", :wait_for => :page
    click "//input[@name='action' and @value='Save Patient']", :wait_for => :page
    if is_text_present("Patient successfully saved.")
      return true
    else return false
    end
  end
  def myupdate_admission(options = {})
    click "link=Update Admission", :wait_for => :page
    select "id=admissionTypeCode", "label=#{options[:admission_type]}" if options[:admission_type]
     type "id=referringHospital", options[:ref_hospital] || "reffering hospital"

    select "confidentialityCode", "label=#{options[:conf_code]}" if options[:conf_code]
    if options[:diagnosis]
      click "//input[@value='' and @type='button']"
      click "//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']", :wait_for => :element, :element =>  "link=#{options[:diagnosis]}"
      click "link=#{options[:diagnosis]}"
    end
    sleep 10
    click("clearAdmissionPackage") if options[:clear_package]
    if options[:package]
      click "searchAdmissionPackage", :wait_for => :element, :element => "link=#{options[:package]}"
      sleep 2
      click "link=#{options[:package]}"
      get_value("admissionPackageDesc") == options[:package]
    end
    sleep 2
    if options[:cancel]
      click "//input[@value='Cancel Admission']", :wait_for => :element, :element => Locators::NursingSpecialUnits.cancel_reason
      sleep 3
      type Locators::NursingSpecialUnits.cancel_reason, options[:reason] || "reason to cancel"
      click Locators::NursingSpecialUnits.cancel_admission, :wait_for => :page
      if is_element_present("errorMessages")
        get_text("errorMessages")
      else
        get_text("successMessages")
      end
    else
    type("id=employer", "Employer");
    type("id=employerAddress", "Employer Address");
    type("id=position", "Position in the Company");
    type("id=serviceYears", "2");
    type("id=otherIncome", "Other Source of Income");
    type("id=guarantorTelNo", "123213");
    type("id=officeTelNo", "12323123123");
    type("id=salary", "44444");

      go_to_preview_page
      if options[:save]
        click "//input[@type='button' and @onclick='submitForm(this);' and @value='Save Admission']", :wait_for => :page
        c2 = is_text_present("Patient admission details successfully saved.")
        return c2
      elsif options[:revise]
        click "//input[@name='action' and @value='Revise']", :wait_for => :page
      elsif options[:sap]
        click("//input[@name='action' and @value='Save and Print Admission']", :wait_for => :page)
      else
        is_text_present("Admission Preview")
      end
    end
  end
  def update_admission(options = {})
    click "link=Update Admission", :wait_for => :page
    select "confidentialityCode", "label=#{options[:conf_code]}" if options[:conf_code]
    if options[:diagnosis]
      click "//input[@value='' and @type='button']"
      click "//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']", :wait_for => :element, :element =>  "link=#{options[:diagnosis]}"
      click "link=#{options[:diagnosis]}"
    end
    sleep 10
    click("clearAdmissionPackage") if options[:clear_package]
    if options[:package]
      click "searchAdmissionPackage", :wait_for => :element, :element => "link=#{options[:package]}"
      sleep 2
      click "link=#{options[:package]}"
      get_value("admissionPackageDesc") == options[:package]
    end
    sleep 2
    if options[:cancel]
      click "//input[@value='Cancel Admission']", :wait_for => :element, :element => Locators::NursingSpecialUnits.cancel_reason
      sleep 3
      type Locators::NursingSpecialUnits.cancel_reason, options[:reason] || "reason to cancel"
      click Locators::NursingSpecialUnits.cancel_admission, :wait_for => :page
      if is_element_present("errorMessages")
        get_text("errorMessages")
      else
        get_text("successMessages")
      end
    else
      go_to_preview_page
      if options[:save]
        click "//input[@type='button' and @onclick='submitForm(this);' and @value='Save Admission']", :wait_for => :page
        c2 = is_text_present("Patient admission details successfully saved.")
        return c2
      elsif options[:revise]
        click "//input[@name='action' and @value='Revise']", :wait_for => :page
      elsif options[:sap]
        click("//input[@name='action' and @value='Save and Print Admission']", :wait_for => :page)
      else
        is_text_present("Admission Preview")
      end
    end
  end
  def reprint_patient_admission(options ={})
    patient_pin_search options
    click "link=Update Admission", :wait_for => :page
    sleep 5
    if options[:edit_record]
      type "doctorCode", options[:doc_code] if options[:doc_code]
      sleep 5
      select "roomChargeCode", "label=#{options[:room_label]}" || "label=REGULAR PRIVATE"
      sleep 2
      go_to_preview_page
      sleep 5
      j1 = is_text_present(options[:doc_code])
      submit_button = is_element_present("//input[@type='button' and @onclick='submitForm(this);' and @value='Save and Print Admission']") ? "//input[@type='button' and @onclick='submitForm(this);' and @value='Save and Print Admission']" :  "//input[@value='Save and Print Admission']"
      click(submit_button, :wait_for => :page)
      return j1
    else
      go_to_preview_page
      sleep 5
      click "//input[@type='button' and @onclick='submitForm(this);' and @value='Save and Print Admission']", :wait_for => :page
      is_text_present("Unable to print patient label sticker. No printer configured.")
      is_text_present("Patient admission details successfully saved.\n \n Patient admission process complete.")
      c3 = get_text('//*[@id="banner.pin"]').gsub(' ', '') == options[:pin]
      return c3
    end
  end
  def go_to_reprinting_page(options ={})
    is_text_present("exact:Would you like to reprint documents?")
    if options[:patient_data_sheet]
      click "css=#reprintDatasheet"
      click "//input[@type='button' and @value='Reprint']", :wait_for => :page
      is_text_present("Reprinted PDS.") || is_text_present("Would you like to reprint documents?")
    elsif options[:patient_label]
      click "reprintLabel"
      type "labelCount", options[:patient_label_count] ||"1"
      click "//input[@type='button' and @value='Reprint']", :wait_for => :page
      is_text_present("Unable to print patient label sticker. No printer configured.") || is_text_present("Would you like to reprint documents?")
    end
  end
  def reprinting_from_admission_page(options ={})
    go_to_admission_page
    patient_pin_search options
    click "link=Reprint Patient Data Sheet And Label Sticker", :wait_for => :page
    boolean = go_to_reprinting_page options
    return boolean
  end
  def update_patient_info(options ={})
    click "link=Update Patient Info", :wait_for => :page
    click "male" if options[:gender] == "male"
    click "female" if options[:gender] == "female"
    select "race.code", options[:race] || "label=ASIAN"
    select "religion.code", options[:religion] || "label=7TH DAY ADVENTIST"
    select "patientIds0.idTypeCode", options[:id_type1] || "label=COMPANY ID"
    type "patientIds0.idNo", options[:patient_id1] || "1234"
    if options[:save]
      click "//input[@name='action' and @value='Create New Admission']", :wait_for => :page
      is_text_present "Patient successfully saved."
    elsif options[:preview]
      click "//input[@name='action' and @value='Preview']", :wait_for => :page
    end
  end
  def or_update_patient_info(options ={})
    patient_pin_search options
    click "link=Update Patient Info", :wait_for => :page
    click "male" if options[:gender] == "male"
    click "female" if options[:gender] == "female"
    select "citizenship.code", options[:citizenship] ||"FILIPINO"
    select "presentContactSelect", "HOME"
    type "presentContact1", "1234567"
    select "civilStatus.code", options[:status] || "SINGLE"
    select "race.code", options[:race] || "label=ASIAN"
    select "religion.code", options[:religion] || "label=7TH DAY ADVENTIST"
    select "patientIds0.idTypeCode", options[:id_type1] || "label=COMPANY ID"
    type "patientIds0.idNo", options[:patient_id1] || "1234"
    type "erLastName", "SAMPLE"
    type "erFirstName", "SAMPLE NAME"
    if options[:save]
      click "//input[@name='action' and @value='Save']", :wait_for => :page
      is_text_present "Patient information saved."
    elsif options[:preview]
      click "//input[@name='action' and @value='Preview']", :wait_for => :page
    end
  end
  def admission_advance_search(options ={})
    go_to_admission_page
    type "criteria",  options[:pin] || options[:last_name] || self.pin if is_element_present"criteria"# || options[:last_name] || self.last_name
    type "param",  options[:pin] || options[:last_name] || self.pin if is_element_present"param"# || options[:last_name] || self.last_name
    click "admitted" if options[:admitted]
    click_advanced_search
    type "fName", options[:first_name]
    type "mName", options[:middle_name]
    type 'bDate', options[:birth_day]# hard-coded in registration
    if options[:gender] == "M"
      click "gender"
    else
      click "//input[@name='gender' and @value='F']"
    end
    click '//input[@name="gender" and @value=' + "'" + options[:gender] + "']" if options[:gender]
    search_button = is_element_present("//input[@type='submit' and @name='search' and @value='Search']") ? "//input[@type='submit' and @name='search' and @value='Search']" :  '//input[@type="submit" and @value="Search" and @name="action"]'
    click(search_button, :wait_for => :page)
    if options[:no_result]
      is_text_present("NO PATIENT FOUND")
    else
      !(is_text_present("NO PATIENT FOUND"))
    end
  end
  def advance_search(options={})
    type "param",  options[:pin] || options[:last_name] || self.pin
    click "admitted" if options[:admitted]
    click_advanced_search
    type "fName", options[:first_name]
    type "mName", options[:middle_name] if options[:middle_name]
    type "bDate", options[:birth_day]
    if options[:gender] == "M"
      click "gender"
    else
      click "//input[@name='gender' and @value='F']"
    end
    click '//input[@name="gender" and @value=' + "'" + options[:gender] + "']" if options[:gender]
    click Locators::Admission.search_button, :wait_for => :page
    if options[:no_result]
      is_text_present("NO PATIENT FOUND")
    else
      !(is_text_present("NO PATIENT FOUND"))
    end
  end
  def click_advanced_search
    click "slide-fade"
    sleep 1
  end
  def verify_advanced_search_fields
    is_element_present(Locators::Admission.search_firstname)
    is_element_present(Locators::Admission.search_middlename)
    is_element_present(Locators::Admission.search_birthday)
    is_element_present(Locators::Admission.search_gender)
  end
  def verify_admission_fields
    # admission quick links
    is_element_present(Locators::Admission.create_new_patient)
    is_element_present(Locators::Admission.room_bed_reprint)
    is_element_present(Locators::Admission.view_print_room_transfer_history)
    # patient search
    is_element_present(Locators::Admission.search_textbox)
    is_element_present(Locators::Admission.search_button)
    is_element_present(Locators::Admission.admitted_checkbox)
    is_element_present(Locators::Admission.advanced_search_link)
  end
  # method no longer in use
  def find_room(key)
    click "//input[@type='button' and @onclick='OSF.show();']"
    type "osf_entity_finder_key", key
    click "//input[@value='Search' and @type='button' and @onclick='OSF.search();']", :wait_for => :element, :element => "link=#{key}"
    click "link=#{key}"
    click "//input[@type='button' and @onclick='RBF.show();']"
    click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']"
    sleep 2
    #is_element_present "//html/body/div/div[5]/div/div[6]/div[3]/table/tbody/tr/td/a"
    !(is_text_present("0 items found, displaying 0 to 0"))
  end
  # method no longer in use
  def get_admission_room_keys
    @a_keys = []
    (146..176).each {|x| @a_keys << "0#{x}"}
    return @a_keys
  end
  # method no longer in use
  def get_room
    @key = @a_keys.shift
    find_room(@key)
  end
  def get_pending_patients_count
    sleep 2
    go_to_admission_page
    count = get_text Locators::Admission.pending_patients
    pending_patient = count.split(" ")[0].to_i
    return pending_patient
  end
  def click_patient_on_queue(visit_number,pin)
    click("//a[@href='/admission/inPatientForm.html?visitNo=#{visit_number}&pin=#{pin}']", :wait_for => :page)
    get_text("breadCrumbs") == "Admission › Registration Form › Admission Form"
  end
  def cancel_on_queue_admission(visit_number)
    click "pendingAdmQueueCount", :wait_for => :element, :element => "//a[@id='#{visit_number}' and @name='cancelAdmission']"
    sleep 5
    click "//a[@id='#{visit_number}' and @name='cancelAdmission']"
    sleep 5
    type Locators::NursingSpecialUnits.cancel_reason, "reason to cancel"
    sleep 3
    click Locators::NursingSpecialUnits.cancel_admission, :wait_for => :page
    get_text("//div[@id='successMessages']/div")
  end
  def get_pending_admission_queue_count
    sleep 3
    get_text("//a[@id='pendingAdmQueueCount']/span").to_i
  end
  def get_notice_of_death_count
    sleep 5
    #get_text("pendingDeathNoticeCount").to_i
    #get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[5]/div/span").to_i
    get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[6]/div/a/span").to_i
  end
  def go_to_notice_of_death(options={})
    sleep 5
  #  click("pendingDeathNoticeCount", :wait_for => :page)
    click("id=deathImg", :wait_for => :page)

#    click "//input[@type='radio' and @value='DCS01']" if options[:new_notice_of_death]
#    click "//input[@type='radio' and @value='DCS02']" if options[:pending_documents]
#    click "//input[@type='radio' and @value='DCS03-']" if options[:waiting_for_payment]
#    click "//input[@type='radio' and @value='DCS03']" if options[:for_release]
#    click "//input[@type='radio' and @value='%']" if options[:all]

    click "xpath=(//input[@name='searchStatus'])[2]" if options[:pending_documents]
    click "xpath=(//input[@name='searchStatus'])[3]" if options[:waiting_for_payment]
    click "xpath=(//input[@name='searchStatus'])[4]"if options[:for_release]
    click "xpath=(//input[@name='searchStatus'])[5]" if options[:all]
    click "name=searchStatus" if options[:new_notice_of_death]


    type "id=criteria", options[:pin] if options[:pin]
    click "name=search", :wait_for => :page if options[:search]

    if options[:action]
      select "//select", options[:action]
      click "link=Print"
      sleep 5
      if (is_element_present("popup_ok") && is_visible("popup_ok"))
      click "popup_ok"#, :wait_for => :page it hangs
      sleep 8
      else
        sleep 2
      end
    end
    sleep 8
    is_element_present("criteria")
  end
  def verify_gu_patient_status(pin)
    go_to_general_units_page
    patient_pin_search(:pin => pin)
    #get_text('css=table[id="occupancyList"] tbody tr[class="even"] td:nth-child(4)')
    get_text("css=#occupancyList>tbody>tr>td:nth-child(5)")
  end
  def verify_su_patient_status(pin)
    go_to_occupancy_list_page
    patient_pin_search(:pin => pin)
     if is_element_present("css=#occupancyList>tbody>tr>td:nth-child(8)")
            get_text("css=#occupancyList>tbody>tr>td:nth-child(8)")
     else
             return nil
     end
  end
  def verify_special_purchase_type
    click "orderToggle"
    sleep 2
    type "itemDesc", "sample description"
    return true
  end
  def populate_patient_info(options={})
    civil_status = options[:civil_status] || "SINGLE"
    citizenship = options[:citizenship] || "FILIPINO"
    nationality = options[:nationality] || "FILIPINO"
    religion = options[:religion] || "ROMAN CATHOLIC"
    occupation = options[:occupation] || "Manager"
    employer = options[:employer] || "G2iX"
    employer_address = options[:employer_address] || "Ortigas Center"
    spouse_fname = options[:spouse_fname]
    spouse_mname = options[:spouse_mname]
    spouse_lname = options[:spouse_lname]
    gender = options[:gender] if options[:gender]
    if options[:newborn]
           click("gender1")
    else
          select "title.code", "label=#{options[:title]}" if options[:title]
          type("name.lastName", options[:last_name]) if options[:last_name]
          type("name.firstName", options[:first_name]) if options[:first_name]
          type("name.middleName", options[:middle_name]) if options[:middle_name]
          type("birthDate", options[:birth_day]) if options[:birth_day]
          type("birthPlace", "MANILA")
          click("gender1") if gender == "M"
          click("gender2") if gender == "F"
    end
    type "presentAddrNumStreet", options[:address] if options[:address]
    select 'civilStatus.code', "label=#{civil_status}"
    select 'nationality.code', "label=#{nationality}"
    select 'religion.code', "label=#{religion}"
    select "citizenship.code", "label=#{citizenship}"
    sleep 1
    type 'patientAdditionalDetails.occupation', occupation
    type 'patientAdditionalDetails.employer', employer
    type 'patientAddresses[2].streetNumber', employer_address
    type 'spouseTelephoneNum', '1234567'
    type 'spouseLastName', spouse_lname
    type 'spouseFirstName', spouse_fname
    type 'spouseMiddleName', spouse_mname
    click "chkFillPermanentAddress"
    select "presentContactSelect", "label=#{options[:contact_type]}" if options[:contact_type]
    type "presentContact1", options[:contact_details] if options[:contact_details]
    type "motherLastName", options[:mother_lname]
    type "motherFirstName", options[:mother_fname]
    type "motherMiddleName", options[:mother_mname]
    type "fatherLastName", options[:father_lname]
    type "fatherFirstName", options[:father_fname]
    type "fatherMiddleName", options[:father_mname]
    type "erLastName", options[:last_name_to_notify] if options[:last_name_to_notify]
    type "erFirstName", options[:first_name_to_notify] if options[:first_name_to_notify]
  end
  def populate_admission_fields(options={})
    @org_codes = AdmissionHelper.get_org_codes_info(CONFIG['location'], options[:org_code] || "0287") if options[:org_code]
    account_class = options[:account_class] || "INDIVIDUAL"
    admission_type = options[:admission_type] || "DIRECT ADMISSION"
    room_charge = options[:room_charge] || "REGULAR PRIVATE" if options[:room_charge]
    confidentiality = options[:confidentiality] || "USUAL CONTROL"
    mobilization = options[:mobilization] || "AIRLIFT"
    diagnosis = options[:diagnosis] || "GASTRITIS"
    rch_code = options[:rch_code] || "RCH08" if options[:rch_code]
    org_code = @org_codes[:org_code]
    doctor_code = options[:doctor_code] || "ABAD"
    select("accountClass", "label=#{account_class}")
    select("admissionTypeCode", "label=#{admission_type}")
    if room_charge
      sleep 5
      select("roomChargeCode", "label=#{room_charge}")
      unless options[:on_queue]
        if rch_code && org_code
          self.find_room_using_room_charge(:rch_code => rch_code, :org_code => org_code)
        elsif rch_code
          self.find_room_using_room_charge(:rch_code => rch_code)
        else
          self.get_room_location
        end
        sleep 5
        click Locators::Admission.room_bed
        sleep 2
      end
    end
    select "mobilizationTypeCode", "label=#{mobilization}"
    select("confidentialityCode", "label=#{confidentiality}")
#    type("diagnosisDate", Time.now.strftime("%m/%d/%Y"))
    click("onQueue") if options[:on_queue]
    click("//input[@value='' and @type='button']", :wait_for => :text, :text => "Search For Diagnosis")
    type("diagnosis_entity_finder_key", diagnosis)
    click("//input[@value='Search' and @type='button' and @onclick='Diagnosis.search();']", :wait_for => :element, :element => "link=#{diagnosis}")
    click("link=#{diagnosis}")
    sleep 2
    select("packageCode", "label=#{options[:package]}") if options[:package]
    self.doctor_finder(:doctor => doctor_code)
    if options[:guarantor_code]
      click ("searchGuarantorBtn")
      if (account_class == "EMPLOYEE") || (account_class == "EMPLOYEE DEPENDENT")
        type("employee_entity_finder_key", (options[:last_name] if options[:last_name]) || (options[:guarantor_code] if options[:guarantor_code]))
        full_name_link = "link=#{options[:last_name].upcase}, #{options[:first_name].upcase} #{options[:middle_name].upcase}" if options[:last_name]
        click("//input[@value='Search' and @type='button' and @onclick='EF.search();']")
      elsif account_class == "INDIVIDUAL"
        type("patient_entity_finder_key", options[:guarantor_code]) if options[:guarantor_code]
        click("//input[@value='Search' and @type='button' and @onclick='PF.search();']")
      else
        type("bp_entity_finder_key", options[:guarantor_code]) if options[:guarantor_code]
        click("//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']")
      end
      sleep 3
      click full_name_link if options[:last_name]
      click("link=#{options[:guarantor_code]}") if options[:guarantor_code]
      sleep 3
      select("guarantorRelationCode", ("label=#{options[:relationship]}" if options[:relationship]) || "label=SELF")
    end
    type"guarantorTelNo","23907654"
  end
  def get_all_admission_info
    # gets all information of admission before proceeding to the preview page
    sleep 5
    acct_class = get_selected_label("accountClass")
    admission_type = (get_selected_label("admissionTypeCode")).split.map(&:capitalize).join(' ')
    confidentiality= (get_selected_label("confidentialityCode")).split.map(&:capitalize).join(' ')
    mobilization = get_selected_label("mobilizationTypeCode")
#    if is_element_present("roomChargeCode") && is_editable("roomChargeCode") == true
#    room_charge = get_selected_label("roomChargeCode")
#    end
#    if is_element_present("nursingUnitCode") == true
#    nursing_unit = get_value("nursingUnitCode")
#    nursing_display = nursing_unit + "  " + (get_text("nursingUnitDisplay")).split.map(&:capitalize).join(' ')
#    end
    diagnosis_type = get_selected_label("diagnosisTypeCode")
    diagnosis_code = get_value("diagnosisCode")
    diagnosis = get_text("diagnosisDisplay")
    diagnosis = diagnosis_code + "  " + diagnosis.capitalize
    #package = get_selected_label("packageCode")
    doctor_code = get_value("doctorCode")
    doctor = doctor_code + "  " + (get_text("doctorNameDisplay").gsub('Doctor Name: ', '')).upcase
    guarantor_type = get_selected_label("guarantorTypeCode")
    {
      :acct_class => acct_class.upcase,
      :admission_type => admission_type,
      :confidentiality => confidentiality,
      :mobilization => mobilization.upcase,
     # :room_charge => room_charge,
     # :nursing_display => nursing_display,
      :diagnosis_type => diagnosis_type.upcase,
      :diagnosis => diagnosis,
     # :package => package,
      :doctor => doctor,
      :guarantor_type => guarantor_type.upcase
    }
  end
  # compares the saved information in the admission to the preview page
  def verify_admission_preview(options={})
    texts = get_text("css=#content")
    texts.include?(options[:acct_class])== true
    #texts.include?(options[:patient]) == true
    #texts.include?(options[:pin]) == true
    #texts.include?(options[:nursing_display]) == true
   # (texts.include?(options[:package])) == true if options[:package] != "Select Package"
    (texts.include?(options[:diagnosis])) == true
    (texts.include?(options[:mobilization])) == true
    #texts.include?(options[:nursing_display]) == true
    (texts.include?(options[:guarantor_type])) == true
  end
  def get_patient_full_name(options={})
    #full_name = (options[:title]).capitalize + " " + (options[:last_name]).capitalize + ", " + options[:first_name] + " " + options[:middle_name]
     full_name = (options[:last_name]).capitalize + ", " + options[:first_name] + " " + options[:middle_name]
    return full_name
  end
  def get_patient_full_name_outpatient(options={})
    full_name = (options[:last_name]).upcase + ", " + options[:first_name].capitalize + " " + options[:middle_name].capitalize
    return full_name
  end
  def return_original_pin(pin)
    return false if pin.length != 10
    o = pin.split('', 10)
    original = o[0] + o[1]+ o[2] + o[3] + " " + o[4] + o[5] + o[6] + " " + o[7] + o[8] + o[9]
    return original
  end
  def compute_age(date_of_birth)
      Time.now.year - date_of_birth.year - (((date_of_birth.month * 31 + date_of_birth.day > Time.now.month * 31 +
      Time.now.day) and Time.now.year != date_of_birth.year) ? 1 : 0)
  end
  def get_all_elements(type)
    doc = Nokogiri::HTML(self.get_html_source)

    if type == "textbox"
      elements = doc.css('input[type=text]')
      elements.map {|textbox| textbox.attribute('id').to_s}.uniq.sort.delete_if {|id| id.empty?}
    elsif type == "links"
      elements = doc.css('a')
      elements.map {|textbox| textbox.attribute('hrefs').to_s}.uniq.sort.delete_if {|href| href.empty?}
    elsif type == "dropdown"
      elements = doc.css('select')
      elements.map {|textbox| textbox.attribute('id').to_s}.uniq.sort.delete_if {|id| id.empty?}
    elsif type == "text"
      elements = doc.css('div[class=fieldContent]')
      textfields = []
      elements.each {|textbox| textfields << textbox.inner_text.to_s.chomp.gsub("\n","").gsub("\t","").lstrip.rstrip}
      return textfields
    elsif type == "radio"
      elements = doc.css('input[type=radio]')
      elements.map {|radio| radio.attribute('id').to_s}.uniq.sort.delete_if {|id| id.empty?}
    elsif type == "checkbox"
      elements = doc.css('input[type=checkbox]')
      elements.map {|checkbox| checkbox.attribute('id').to_s}.uniq.sort.delete_if {|id| id.empty?}
    end
  end
  def get_fields_and_labels_by_type(type)
    doc = Nokogiri::HTML(self.get_html_source)
    if type == "textbox"
      elements = doc.css('input[type=text]')
      get_fields_and_labels(elements)
    elsif type == "dropdown"
      elements = doc.css('select')
      get_fields_and_labels(elements)
      # checkbox returns field ids for now
    elsif type == "checkbox"
      elements = doc.css('input[type=checkbox]')
      elements.map {|element| element.attribute('id').to_s}.uniq.sort.delete_if {|id| id.empty?}
    elsif type == "button"
      elements = doc.css('input[type=button]')
      elements.map {|element| element.attribute('value').to_s}.uniq.sort.delete_if {|id| id.empty?}
    end
  end
  def get_fields_and_labels(elements)
    #putting line 830 in comment so method can be used in get_fields_and_labels_by_type, line 830 filters ALL elements
    #elements = Nokogiri::HTML(self.get_html_source).css('input:not([type="button"]), select, textarea')
    ids = elements.map {|element| element.attribute('id').to_s}.uniq.sort.delete_if {|id| id.empty?}
    hsh = {}
    ids.each do |id|
      hsh[id] = get_text("css=label[for='#{id}']") if self.is_element_present("css=label[for='#{id}']")
    end
    return hsh
  end
  # admission page
  def click_create_new_patient_link
    click "link=New Patient", :wait_for => :page
    get_text("breadCrumbs") == "Admission › Registration Form"
  end
  def click_update_patient
    #click "link=Update Patient Info", :wait_for => :page
    click "link=Update Patient Info", :wait_for => :page
    get_text("breadCrumbs") == "Admission › Registration Form"
  end
  def click_update_admission
    click "link=Update Admission", :wait_for => :page
    get_text("breadCrumbs") == "Admission › Registration Form › Admission Form"
  end
  def save_admission
    click Locators::Admission.save_admission, :wait_for => :page
    if is_element_present("successMessages")
      get_text("successMessages")
    else
      get_text("errorMessages")
    end
  end
  # inside the registration form
  def click_create_new_admission_button
    click "//input[@name='action' and @value='Create New Admission']", :wait_for => :page
    sleep 2
    if is_element_present("successMessages")
      get_text("successMessages")
    else
      get_text("errorMessages")
    end
  end
  def save_patient_details
    click "//input[@name='action' and @value='Save Patient']", :wait_for => :page
    if is_element_present("successMessages")
      get_text("successMessages")
    else
      get_text("errorMessages")
    end
  end
  def click_revise_admission
    click "//input[@value='Revise']", :wait_for => :page
    get_text("breadCrumbs") == "Admission › Registration Form › Admission Preview"
  end
end
