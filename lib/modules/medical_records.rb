#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/locators'

module MedicalRecords

  def more_options(options={})
    click'slide-fade' if (!is_visible"admitted")
    sleep 5
    click'admitted' if options[:admitted]#1.4.2
    sleep 2
    click'radioLocQC' if options[:loc] #by default when admitted is checked radio button for GC location is ticked.
    type'//input[@name="param"]',options[:pin]
    type('//input[@name="firstName"]',options[:first_name]) if options[:first_name]
    type('//input[@name="middleName"]',options[:middle_name]) if options[:middle_name]
    type'birthDate','05/05/1984' if options[:birth_day]
    click'//input[@type="radio" and @value="M"]' if options[:gender]
    click"advancedSearch"
    sleep 5
     if options[:no_result]
        return is_text_present("Enter a pin or lastname.")
    elsif options[:alert]
        return is_text_present("NO PATIENT FOUND")
     else
        return options[:pin]
     end
  end
  def med_reprinting_page(options ={})
    click('css=#results>tbody>tr.even>td:nth-child(6)>div>a', :wait_for => :page) if options[:reprinting]
    is_text_present("exact:Would you like to reprint documents?")
    if options[:patient_data_sheet]
      click "reprintDatasheet"
    end
    if options[:patient_label]
      click "reprintLabel"
      type "labelCount", options[:patient_label_count] ||"1"
    end
    click '//input[@type="button" and @value="Reprint" and @onclick="submitForm(this);"]'#, :wait_for => :page
    sleep 10
    return is_text_present("Reprinted PDS.")  if options[:successful]
    return is_text_present("Unable to print patient label sticker. No printer configured.")  if options[:label_only]
    return is_text_present("Please select an item to reprint.")  if options[:no_items]
    return is_text_present("Patient is either not admitted, or has no validated package order.")  if options[:with_previous_confinement]
  end
  def search_patient_diagnosis_review(options={})
      type "pinOrLastName", options[:pin]
      type"form_visitNo",options[:visit_no] if options[:visit_no]
      type "form_dischargeDateStart", Time.now.strftime("%m/%d/%Y")  if options[:discharge_date]
      type "form_icd10", ("A00" || options[:icd10])  if options[:icd10]
      sleep 1
      click "search", :wait_for => :page
      sleep 1
      if options[:alert]
      is_text_present"Nothing to display"
      elsif options[:visit_no]
      is_element_present"//a[@href='/medicalRecords/finalDiagnosisUpdate.html?visitNo=#{options[:visit_no]}']"
      else
      is_element_present"//html/body/div/div[2]/div[2]/div[4]/div/table/tbody/tr/td/a"
      end
  end
  def medical_records_result_list_page
      click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for => :page
      is_text_present"Result List"
  end
  def click_final_diagnosis_review_link(options={})
      if options[:with_diagnosis]
        click "w_finalCount", :wait_for => :page
        is_element_present"selectedWithFinalDiagnosis"
      elsif options[:without_diagnosis]
        click "wo_finalCount", :wait_for => :page
        is_element_present"selectedWithoutFinalDiagnosis"
      elsif options[:with_icd10]
        click "w_Icd10Count", :wait_for => :page
        is_text_present"selectedWithIcd10"
      elsif options[:without_icd10]
        click "wo_Icd10Count", :wait_for => :page
        is_text_present"w/o ICD10 Diagnosis "
      end
  end
  def final_diagnosis_review(options={})
    search_patient_diagnosis_review options
    click"//a[@href='/medicalRecords/finalDiagnosisUpdate.html?visitNo=#{options[:visit_no]}']", :wait_for => :page
    is_text_present"Patient Final Diagnosis"
  end
  def medical_final_diagnosis(options={})
    if options[:icd10_diagnosis]
        type"txtIcdQueryCode", options[:icd10_diagnosis]
        click"btnIcdFindSearch"
        sleep 4
        click"tdIcdCode-0"
        sleep 1
        click"//html/body/div[5]/div[3]/div/button[2]/span" if is_element_present"confirmSubmitPopup"
        sleep 5
        c1 = is_text_present(options[:icd10_diagnosis])
    end

    if options[:text_diagnosis]
          click"diagnosisType2"
          click"freeTextAdd"
          type"freeTextAdd",options[:text_diagnosis]
          click"addFreeTextBtn"
          sleep 5
          click"//html/body/div[5]/div[11]/div/button[2]"
          sleep 5
          c2 = is_text_present(options[:text_diagnosis])
    end

     if options[:save]
        click"btnSave", :wait_for => :page
        c3 = is_text_present"Final Diagnosis was successfully saved"
     end

    return c1 if options[:icd10_diagnosis]
    return c2 if options[:text_diagnosis]
    return c3 if options[:save]
  end
  def search_without_icd10_table (options={})
    count = get_css_count "css=#results>tbody>tr"
    rows = 0
    @@arr = []
    count.times do
      @@arr << (get_text"css=#results>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)>a")
      count-=1
      rows+=1
    end

     while ((((@@arr.to_s).include?options[:pin]) != true) && (is_visible"link=Next ›"))
      click"link=Next ›", :wait_for => :page

      count = get_css_count "css=#results>tbody>tr"
      rows = 0
      @@arr = []
      count.times do
        @@arr << (get_text"css=#results>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)>a")
        count-=1
        rows+=1
      end
    end
    
      ((@@arr.to_s).include?options[:pin])
  end
  def search_file_maintenance_icd10(options={})
    type"code","" if (get_value"code") != ""
    type"desc","" if (get_value"desc") != ""
    sleep 1
    type"code",options[:code] if options[:code]
    type"desc",options[:desc] if options[:desc]
    click"//input[@type='submit' and @value='Search' and @name='action']", :wait_for => :page
    get_text"css=#results>tbody>tr"
  end
  def search_icd10_sub_cat(options ={})
    click"//input[@type='button' and @onclick='SubCatFinder.displayPopup();' and @value='FIND']", :wait_for => :element , :element => "divSubCatFindPopupContent"
    type"txtSubCatQuery",options[:diagnosis] if options[:diagnosis]
    click"btnSubCatFindSearch"#, :wait_for => :element, :element => "link=#{options[:diagnosis]}"
    sleep 3
    click"css=#subCatFindResults>tr>td>div"
    sleep 1
    is_text_present"Manage Icd10"
  end
  
end
