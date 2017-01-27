#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/locators'

module StlukesNursingGenenalUnits
  include Locators::NursingGeneralUnits


  def su_patient_search
    go_to_outpatient_nursing_page
    txt_criteria = is_element_present("criteria")
    btn_search = is_element_present("searchMPI")
    return (txt_criteria && btn_search)
  end
  def display_error_message
    go_to_outpatient_nursing_page
    click 'searchMPI'
    sleep 10
    notification = is_text_present("Enter a pin or lastname")
    return (notification)
  end
  def go_to_nu_page(options={})
    patient_pin_search options
    sleep 2
    go_to_su_page_using_pin(options[:page], options[:pin])
  end
  def go_to_su_page_using_pin(page,pin)
    select "userAction#{pin}", "label=#{page}" 
    click Locators::NursingSpecialUnits.submit_button_spu, :wait_for => :page
  end
  def go_to_fnb(options={})
    patient_pin_search options
    sleep 2
    go_to_fnb_page_given_pin(options[:page], options[:pin])
  end
  def check_patient_banner
    banner = is_element_present("patientBanner")
    return (banner)
  end
  def check_confirmation_message_after_validation
    success_msg = is_element_present("successMessages")
    return (success_msg)
  end
  def check_clinical_diet_fields
    diet_description = is_element_present("currDietDesc") #is_element_present("dietGroup")
    diet_search = is_element_present("btnDiagnosisLookup") #is_element_present("models")
    food_preference = is_element_present("foodPreferences")
    allergy_type = is_element_present("allergyType")
    allergy_desc = is_element_present("alergyDescription")
    allergy_list = is_element_present("dataTable")
    return(diet_description && diet_search && food_preference && allergy_type && allergy_desc && allergy_list)
  end
  def update_diet(options={})
    click "btnDiagnosisLookup", :wait_for => :visible, :element => "dietFinderForm"
    type "dietFinderKey", options[:diet]
    click "//input[@type='button' and @onclick='DietFinder.search();' and @value='Search']", :wait_for => :element, :element => "link=#{options[:diet]}"
    click "link=#{options[:diet]}", :wait_for => :not_visible, :element => "dietFinderForm"
    type "foodPreferences.preference", options[:preference]
    type "height", options[:height]
    type "weight", options[:weight]
    click "foodPreferences.disposableTray1"
    type "dietRemarks", options[:remarks]
    click "//input[@value='Update' and @name='updateButton']", :wait_for => :page if options[:update]
    is_text_present("successful")
  end
  def save_diet
    click "saveButton", :wait_for => :page
    a = get_text("successMessages") == "Patient diet saved successfully."
    if is_text_present "Diet Group is a required field."
      select "dietGroup", "label=COMPUTED"
      click "saveButton", :wait_for => :page
    end
    return a
  end
  def add_food_allergy
    type "alergyDescription", "shrimps and crabs"
    click "//input[@value='Add']", :wait_for => :ajax
    sleep 5
  end
  def select_unselect_disposable_tray
    click "currDisposableTray1"
    d = get_value("currDisposableTray1") == "on"
    click "currDisposableTray1"
    e = get_value("currDisposableTray1") == "off"
    return(d && e)
  end
  def reset_input_diet
    add_clinical_diet
    click "//input[@type='button' and @value='Reset']"
    diet_desc = get_value("alergyDescription") == ""
    food_pref = get_value("foodPreferences") == ""
    allergy = !is_text_present("actual-description-0")
    h = get_value("height") == "0.0"
    w = get_value("weight") == "0.0"
    disp_tray = get_value("currDisposableTray1") == "off"
    return(diet_desc && food_pref && allergy && h && w && disp_tray)
  end
  def view_diet_history
    click "//input[@value='View Diet History']", :wait_for => :page
    diet_history = is_text_present "Patient Diet History"
    return diet_history
  end
  def click_back_button
    click "//input[@value='Back']", :wait_for => :page
    is_text_present("Diet Page")
  end
  def patient_diet_details
    diet_group = is_text_present "COMPUTED"
    diet_type = is_text_present "COMPUTED DIET"
    food_pref = is_text_present "SELENIUM TEST FOOD PREFERENCE"
    food_allergy = is_text_present "SELENIUM TEST FOOD ALLERGY DESCRIPTION"
    h = is_text_present "161.0"
    w = is_text_present "57.0"
    bmi = is_text_present "21.99"
    interpretation = is_text_present "NORMAL"
    disposable_tray = is_text_present "No"
    addl_ins = is_text_present "ADD'L INSTRUCTION"
    return(diet_group && diet_type && food_pref && food_allergy && h && w && bmi && interpretation && disposable_tray && addl_ins)
  end
  def display_patient_diet_details
    click "link=COMPUTED", :wait_for => :page
    patient_diet_details
  end
  def click_close_button
    click "//div[@id='main']/div[7]/div[2]/div/a/input[@value='Close']", :wait_for => :page
    click_back_button
    diet_page = is_text_present("Diet Page")
    return diet_page
  end
  def click_cancel_button
    click "//input[@value='Cancel']", :wait_for => :page
    return is_text_present "Occupancy List"
  end
  def check_links
    click "css=#dataTable>tbody>tr:nth-child(2)>td:first-child>a", :wait_for => :page
    date_link = is_text_present "Patient Diet Details"
    click_close_button
    view_diet_history
    click "css=#dataTable>tbody>tr:nth-child(2)>td:nth-child(2)>a", :wait_for => :page
    diet_type = is_text_present "Patient Diet Details"
    click_close_button
    view_diet_history
    click "css=#dataTable>tbody>tr:nth-child(2)>td:nth-child(3)>a", :wait_for => :page
    diet_group = is_text_present "Patient Diet Details"
    return (date_link && diet_type && diet_group)
  end
  def diet_history_in_fnb
    click "css=#dataTable>tbody>tr:nth-child(2)>td:first-child>a", :wait_for => :page
    click "css=#dataTable>tbody>tr:nth-child(2)>td:first-child>a", :wait_for => :page
    patient_diet_details
  end
  def check_clinical_order_page_fields
     banner = is_element_present("patientBanner")
     search_fields = is_element_present("serviceSearch")
     order_cart = is_element_present("cart")
     return(banner && search_fields && order_cart)
  end
  
end