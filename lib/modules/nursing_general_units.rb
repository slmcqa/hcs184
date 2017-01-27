#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/locators'

module NursingGenenalUnits
  include Locators::NursingGeneralUnits

  def nursing_gu_search(options = {})
    last_name = options[:last_name] if options[:last_name]
    go_to_general_units_page
    patient_pin_search options
    if options[:no_result]
      return is_text_present("NO PATIENT FOUND")
    else
      return is_text_present last_name
    end
  end
  def nursing_patient_search(options={})
    go_to_general_units_page if options[:inpatient]
    go_to_outpatient_nursing_page if options[:outpatient]
    click("link=Patient Search", :wait_for => :page)
    patient_pin_search options
  end
  # Order Page, Order List, Clinical Discharge
  def go_to_gu_page_for_a_given_pin(page, pin)
    select "id=userAction#{pin}", "label=#{page}"
    click Locators::NursingGeneralUnits.submit_button
    sleep 8
    if is_text_present("Are you sure you want to select")
            click "css=#nameAlertPopUpDialog > div > input[type=\"submit\"]"  if is_element_present("css=#nameAlertPopUpDialog > div > input[type=\"submit\"]")
            sleep 3
    end

    sleep 10 if (page == "Request for Room Transfer") && (page == "Reprint Gate Pass") && (page == "Defer Discharge")
  #  wait_for_page_to_load "30000" if (page != "Request for Room Transfer") && (page != "Reprint Gate Pass") &&  (page != "Defer Discharge")
  end
  def er_clinical_order_patient_search(options={})
    go_to_er_page
    patient_pin_search options
    go_to_er_page_using_pin("Order Page", options[:pin])
  end
  def search_order(options = {})
		sleep 4
		item = options[:code] || options[:description]
		click 'orderType1' if options[:drugs]
		click 'orderType2' if options[:supplies]
		click 'orderType3' if options[:ancillary]
		click 'orderType4' if options[:others]
		click 'orderType5' if options[:special]
		click 'id=orderType6' if options[:medical_gases]
		click 'borrowed_checkbox' if options[:borrowed]
		sleep 2
		type "oif_entity_finder_key", item
		if options[:filter]
			sleep 5
			select("locationFilter",options[:filter])
		end
		sleep 6
		if options[:include_pharmacy]
					click("id=includePharmacy")
		end
		search_button = is_element_present('//input[@type="button" and @value="Search" and @name="search"]') ?  '//input[@type="button" and @value="Search" and @name="search"]' : '//input[@type="submit" and @value="Search" and @name="search"]'
		# is_element_present("name=search")
		#search_button = "//html/body/div/div[2]/div[2]/div[10]/form/div/div/div[2]/div[4]/input[2]"
		# click "name=search", :wait_for => :element, :element => "link=#{item}" if options[:special] != true
		click search_button, :wait_for => :element, :element => "link=#{item}" if options[:special] != true
		sleep 16
		is_text_present(item)
  end
  def cm_search_order(options = {})
    sleep 4
    item = options[:code] || options[:description]
    click "name=orderType" if options[:drugs]
    click "xpath=(//input[@name='orderType'])[2]" if options[:supplies]
    click "xpath=(//input[@name='orderType'])[3]" if options[:ancillary]
    click 'orderType4' if options[:others]
    click 'orderType5' if options[:special]
    click 'orderType6' if options[:medical_gases]
    click 'borrowed_checkbox' if options[:borrowed]
    sleep 2
    type "id=criteria", item
    if options[:filter]
      sleep 5
      select("locationFilter",options[:filter])
    end
    sleep 6
    if options[:include_pharmacy]
          click("id=includePharmacy")
    end
  search_button = is_element_present('//input[@type="button" and @value="Search" and @name="search"]') ?  '//input[@type="button" and @value="Search" and @name="search"]' : '//input[@type="submit" and @value="Search" and @name="search"]'
  # is_element_present("name=search")
    #search_button = "//html/body/div/div[2]/div[2]/div[10]/form/div/div/div[2]/div[4]/input[2]"
    # click "name=search", :wait_for => :element, :element => "link=#{item}" if options[:special] != true
  click search_button #, :wait_for => :element, :element => "#{item} if options[:special] != true
  sleep 6
    is_text_present(item)
  end
  def check_order(options = {})
    sleep 4
    item = options[:code] || options[:description]
    click 'orderType1' if options[:drugs]
    click 'orderType2' if options[:supplies]
    click 'orderType3' if options[:ancillary]
    click 'orderType4' if options[:others]
    click 'orderType5' if options[:special]
    click 'orderType6' if options[:medical_gases]
    click 'borrowed_checkbox' if options[:borrowed]
    sleep 2
    type "oif_entity_finder_key", item
    if options[:filter]
      sleep 5
      select("locationFilter",options[:filter])
    end
    sleep 6
    if options[:include_pharmacy]
          click("id=includePharmacy")
    end
  search_button = is_element_present('//input[@type="button" and @value="Search" and @name="search"]') ?  '//input[@type="button" and @value="Search" and @name="search"]' : '//input[@type="submit" and @value="Search" and @name="search"]'
  # is_element_present("name=search")
    #search_button = "//html/body/div/div[2]/div[2]/div[10]/form/div/div/div[2]/div[4]/input[2]"
    # click "name=search", :wait_for => :element, :element => "link=#{item}" if options[:special] != true
  click search_button
  sleep 6
    is_text_present(item)
  end
  def add_returned_order(options = {})
              options[:frequency] = "ONCE A DAY"
              sleep 6
              click("link=#{options[:description]}") if options[:special] != true
              sleep 2 if options[:edit]
              sleep 6
              click("priorityCode") if (options[:stat] && !is_checked("priorityCode"))
              click("checkStock") if (options[:stock_replacement] && !is_checked("checkStock"))
              sleep 3
              frequency = options[:frequency] # || "EVERY 12 HOURS"
              route = options[:route] || "ORAL"
              dose = options[:dose] || "3"
              start_date = options[:start_date] || Time.now.strftime("%m/%d/%Y")
              end_date = options[:end_date] || Time.now.strftime("%m/%d/%Y")
              @quantity = options[:quantity] || "1.0"
              @item_code = get_value Locators::NursingGeneralUnits.searched_item_code
              @item_description = get_value Locators::NursingGeneralUnits.searched_item_description

           #   if options[:doctor]
				sleep 10 if options[:edit] # sleep 10 due to switching of frame during edit
				doctor = options[:doctor] || "ABAD"
				click("//input[@type='button' and @onclick='DF.show();' and  @value='FIND']", :wait_for => :visible, :element => "entity_finder_key")
				type("entity_finder_key", doctor)
				select("spec_finder_key", options[:specialization]) if options[:specialization]
				click("//input[@type='button' and @value='Search' and @onclick='DF.search();']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div")
				click "css=input[type=\"button\"]"  if is_element_present("css=input[type=\"button\"]")
				sleep 1
				click("//tbody[@id='finder_table_body']/tr[1]/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div")
				click "css=div[title=\"Click to select.\"]" if is_element_present("css=div[title=\"Click to select.\"]")
				click "css=input[type=\"submit\"]" if is_element_present("css=input[type=\"submit\"]")
				click "css=#selectDiv > input.myButton" if is_element_present("css=#selectDiv > input.myButton")
				click "css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]" if is_element_present("css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]")
				click "css=#doctorSelectedPopUpDialog > input.myButton" if is_element_present("css=#doctorSelectedPopUpDialog > input.myButton")
				click "css=input.myButton" if is_element_present("css=input.myButton")		
           #   end
				sleep 6
              if options[:drugs]
                        sleep 3
                        # if options[:description] != "040004334"
                        select("routeCode", "label=#{route}")
                        select("frequencyCode", "label=#{frequency}") #if options[:stat] != true
                        sleep 3
                        type "document.cartOrderForm.dose", dose
                        #  end
                        if options[:batch]
                                click("checkBatch")
                                sleep 2
                                type("quantityPerBatch", options[:quantity_per_batch] || "3")
                                type("duration", options[:batch_duration] || "4")
                        end
                        type("quantity", @quantity)
              elsif options[:ancillary]
                        type("schedDate", (Date.today + 1).strftime("%m/%d/%Y")) if is_element_present("schedDate")
                        type("quantity", @quantity)
              elsif options[:supplies]
                        type("quantity", @quantity)
              elsif options[:special]
                        type("itemDesc", options[:special_description])
                        find_performing_unit
              elsif options[:medical_gases]
                        select("gasRouteCode", options[:device])
                        type("litersPerMinute", options[:lpm])
                      # continue_value =   get_value("id=gasContinuousFlag")
                        click("id=gasContinuousFlag") if (options[:not_continous] == true && is_checked("id=gasContinuousFlag"))
                        type "id=gasHour", "12" if is_element_present("id=gasHour")
                        type"id=gasMinute", "30" if is_element_present("id=gasMinute")
                        type"id=gasInterval", "10" if is_element_present("id=gasInterval")
#                      select "id=gasScheduleStartHourStr", "label=12"
#                         select "id=gasScheduleStartMinuteStr", "label=30"
#                         select "id=gasScheduleStartTimeMarker", "label=PM"
                        puts "at medical cases"
                        #endt = Time
                        #end_date = options[:end_date] || (Time.now + 10*60*60).strftime("%m/%d/%Y") 
                        end_date = options[:end_date] || (Time.now + (24*60*60)).strftime("%m/%d/%Y") 
                        type("id=gasScheduleStartDateStr", start_date) if is_element_present("id=gasScheduleStartDateStr")
                        type("id=gasScheduleEndDateStr", end_date) if is_element_present("id=gasScheduleEndDateStr")
                       # type("quantity", @quantity)
					#   
					puts "end_date = #{end_date}"
					puts "type in id=gasScheduleEndDateStr"
      
              elsif options[:others]
                        type("quantity", @quantity)
                        sleep 2
              end

              if options[:spdrugs_amount]
                        type("serviceRateDisplay",options[:spdrugs_amount] || "750.00")
                        type("itemDesc", options[:sp_drugs_desc] || "SPECIAL DRUGS DESCRIPTION")
                        @@item_description1 = get_value Locators::NursingGeneralUnits.searched_item_description
              end

              if options[:borrowed]
                        click("btnFindPerfUnit", :wait_for => :visible, :element => "osf_entity_finder_key")
                        sleep 1
                        type("osf_entity_finder_key", options[:perf_unit])
                        click("//input[@type='button' and @value='Search' and @onclick='PUF.search();']", :wait_for => :element, :element => "//tbody[@id='osf_finder_table_body']/tr[1]/td[2]/a")
                        click("//tbody[@id='osf_finder_table_body']/tr[1]/td[2]/a") if is_element_present("//tbody[@id='osf_finder_table_body']/tr[1]/td[2]/a")
                        sleep 1
              end

              type("remarks", options[:remarks] || "remarks")
              add_button = is_element_present("//input[@value='ADD']") ? "//input[@value='ADD']" : "//input[@value='Add']"

              if options[:drugs]
                        sleep 3
                        # if options[:description] != "040004334"
                        select("routeCode", "label=#{route}")
                        select("frequencyCode", "label=#{frequency}") #if options[:stat] != true
                        sleep 3
                        type "document.cartOrderForm.dose", dose
              end

              if options[:add]
                        sleep 10
                        if options[:medical_gases]
                                  click "id=guAddBtn" if is_element_present("id=guAddBtn")                          
                        else
                                  if is_element_present(add_button)
                                             puts "click add"
                                             if options[:medical_gases]
                                                    click "id=guAddBtn" if is_element_present("id=guAddBtn")
                                             else
                                                 click add_button
                                                 sleep 10
                                             end
                                  else
                                             click"id=guAddBtn" if is_element_present("id=guAddBtn")
                                             sleep 10
                                  end
                        end
                        sleep 10
                        if is_element_present("id=verifyActionForm")
                                click "id=updact1" if options[:update_qty]
                                click "id=updact2" if options[:override]
                                click "id=updact3" if options[:newline]
                                click "id=updact4" if options[:open_4_edit]
                                sleep 3
                                click "//input[@value='Proceed']" if is_element_present("//input[@value='Proceed']")
                                sleep 6																
                        end

                        # if is_element_present("popup_ok")
                        if is_element_present("//input[@id='popup_ok']")
                                  click "popup_ok" #:wait_for => :page
                                  sleep 3
                                  #      elsif is_element_present("validationBatchExist") && is_visible("//input[@type='button' and @value='Ok']")
                                  #        click "//input[@type='button' and @value='Ok']"
                                  #  else
                                  # wait_for_page_to_load
                        end
                        # sleep 10
                        if options[:spdrugs_amount]
                                  c = is_text_present("Order item #{@item_code} - #{@@item_description1} has been added successfully.")
                        elsif options[:special]
                                  c = is_text_present("Order item #{@item_code} - #{options[:special_description]} has been added successfully.")
                        else
                                  c = is_text_present("Order item #{@item_code} - #{@item_description} has been added successfully.")
                        end
                        # not applicable in 1.5 due changes in of borrowed feature requested by users
                        #    elsif options[:add_borrowed_item]
                        #      click add_button, :wait_for => :element, :element => "verifyActionForm"
                        #      click("updact3") if options[:new_line]
                        #      click("//input[@type='button' and @onclick='CartOrderCommon.proceed(this);' and @value='Proceed']", :wait_for => :page)
                        #      c = is_text_present("Order item #{@item_code} - #{@item_description} has been added successfully.")
              elsif options[:edit]
                        sleep 5
                        click("//input[@value='SAVE']", :wait_for => :page)
                        return true if is_text_present("Order item #{@item_code} - #{@item_description} has been edited successfully.")
              end
              sleep 10
              return get_text("cartOrderBean.errors") if is_element_present("cartOrderBean.errors")
              return c
  end
  def get_error_message
    return is_text_present("Description is a required field.")
  end
  # find performing unit of special items
  def find_performing_unit(unit='0003')
    click "btnFindPerfUnit", :wait_for => :element, :element => "osf_entity_finder_key"
    type "osf_entity_finder_key", unit
    click "//input[@value='Search' and @type='button' and @onclick='PUF.search();']"
    sleep Locators::NursingGeneralUnits.waiting_time
    click "link=#{unit}"
    sleep 3
  end
  # click order link from the order cart
  def click_order(order)
    click "link=#{order}", :wait_for => :page
    get_value("itemDesc") == order
  end
  #method that clicks the "Validate" button from the order cart
  def submit_added_order(options={})
    if options[:validate]
                sleep 2
                submit_button = is_element_present("//input[@type='button' and @value='Submit']") ?  "//input[@type='button' and @value='Submit']" :  "//input[@value='SUBMIT']"
                click submit_button # :wait_for => :page)
                sleep 2
                username = options[:username] || "sel_0278_validator"
                password = options[:password] || "123qweuser"
                username = "sel_0332_validator" if (CONFIG['location'] == 'QC' && options[:username] == "sel_0278_validator")
                sleep 10
                if is_element_present("pharmUsername")
                        type("pharmUsername", username) if is_element_present("pharmUsername")
                        type("pharmPassword", password) if is_element_present("pharmPassword")
                        click("validatePharmacistOK") if is_element_present("validatePharmacistOK")
                end
                 if is_element_present("id=pharmUsername")
                      type("id=pharmUsername", username) 
                      type("id=pharmPassword", password)
                      click("id=validatePharmacistOK")
                 end
                sleep 10
                return false if is_text_present("User is not allowed to validate.") || is_text_present("Invalid Username/Password.")
                return true if is_text_present("General Units")
    else
                username = options[:username] || "sel_0278_validator"
                password = options[:password] || "123qweuser"
                submit_button = is_element_present("//input[@type='button' and @value='Submit']") ?  "//input[@type='button' and @value='Submit']" :  "//input[@value='SUBMIT']"
                click submit_button # :wait_for => :page)
								
                sleep 5
                if is_element_present("pharmUsername")
                        type("pharmUsername", username) if is_element_present("pharmUsername")
                        type("pharmPassword", password) if is_element_present("pharmPassword")
                        click("validatePharmacistOK") if is_element_present("validatePharmacistOK")
                end
                 if is_element_present("id=pharmUsername")
                      type("id=pharmUsername", username) 
                      type("id=pharmPassword", password)
                      click("id=validatePharmacistOK")
                 end      
                 return true if is_text_present("General Units") || is_text_present("Special Units Home")
    end
  end
  # different method as above. method specifically for OR and ER
  def er_submit_added_order(options={})
    if options[:validate]
      submit_button = is_element_present("//input[@value='SUBMIT']") ? "//input[@value='SUBMIT']" : "//input[@value='Submit']"
      click submit_button, :wait_for => :page
      username = options[:username] || "fbdonato" #role_spu_nursing_manager and role_spu_outpatient_nurse with same org code as user
      password = options[:password] || "123qweuser"
      sleep 5
      if is_element_present("pharmUsername")
              type("pharmUsername", username)
              type("pharmPassword", password)
              sleep 3
              click("validatePharmacistOK", :wait_for => :not_visible, :element => "validatePharmacistOK")
              sleep 8
      end       
      return true if is_element_present("validate")
    else
      submit_button = is_element_present("//input[@value='SUBMIT']") ? "//input[@value='SUBMIT']" : "//input[@value='Submit']"
      click submit_button, :wait_for => :page
      return true if is_element_present("validate")
    end
  end
  #counts the ordered items for drugs, ancillary, supplies and others
  def verify_ordered_items_count(options={})
    count_drugs = get_css_count("css=#cart>div:nth-child(2)>div.item").to_i
    count_supplies = get_css_count("css=#cart>div:nth-child(4)>div.item").to_i
    count_ancillary = get_css_count("css=#cart>div:nth-child(6)>div.item").to_i
    count_others = get_css_count("css=#cart>div:nth-child(8)>div.item").to_i
    count_oxygen = get_css_count("css=#cart>div:nth-child(10)>div.item").to_i
    count_special = get_css_count("css=#cart>div:nth-child(12)>div.item").to_i

    if options[:drugs] && (count_drugs > 0)
      j1 = options[:drugs] == count_drugs
    end
    if options[:supplies] && (count_supplies > 0)
      j2 = options[:supplies] == count_supplies
    end
    if options[:ancillary] && (count_ancillary > 0)
      j3 = options[:ancillary] == count_ancillary
    end
    if options[:others] && (count_others > 0)
      j4 = options[:others] == count_others
    end
    if options[:oxygen] && (count_oxygen > 0)
      j5 = options[:oxygen] == count_oxygen
    end
    if options[:special] && (count_special > 0)
      j6 = options[:special] == count_special
    end

    return j1 if options[:drugs]
    return j2 if options[:supplies]
    return j3 if options[:ancillary]
    return j4 if options[:others]
    return j5 if options[:oxygen]
    return j6 if options[:special]
  end
  def verify_added_content_in_order_cart(item)
    get_text("cart").include?(item)
  end
  #method that validates a single/multiple order(s) of the same type - DRUGS
  def validate_orders(options ={})
    sleep 6
    count_drugs = get_css_count("css=#drugOrderCartDetails>tbody>tr")
    count_supplies = get_css_count("css=#suppliesOrderCartDetails>tbody>tr")
    count_ancillary = get_css_count("css=#ancillaryOrderCartDetails>tbody>tr")
    count_others = get_css_count("css=#miscellaneousOrderCartDetails>tbody>tr")
    count_special = get_css_count("css=#special9999OrderCartDetails>tbody>tr")
    count_procedures = get_css_count("css=#procedureDetails>tbody>tr")
    count_non_procedures = get_css_count("css=#nonProcedureDetails>tbody>tr")
    medical_cases = get_css_count("css=#oxygenOrderCartDetails>tbody>tr")

    drugs_click = 0
    supplies_click = 0
    ancillary_click = 0
    others_click = 0
    special_click = 0
    procedures_click = 0
    non_procedures_click = 0
    medical_cases_click = 0
    total_click = 0

    if options[:orders] == "single" || options[:single]
      click "css=#drugOrderCartDetails>tbody>tr>td:nth-child(1)>input" if options[:drugs] #&& (count_drugs == 1)      # jmerelos v1.4
              if is_text_present("Supplies & Equipments")
                       click "css=#nonProcedureDetails>tbody>tr>td:nth-child(1)>input" if options[:supplies] #&& (count_supplies == 1)
              else
                       click "css=#suppliesOrderCartDetails>tbody>tr>td:nth-child(1)>input" if options[:supplies] #&& (count_supplies == 1)
            end
      click "css=#ancillaryOrderCartDetails>tbody>tr>td:nth-child(1)>input" if options[:ancillary] #&& (count_ancillary == 1) # jmerelos v1.4
      click "css=#miscellaneousOrderCartDetails>tbody>tr>td:nth-child(1)>input" if options[:others] #&& (count_others == 1)
      click "css=#special9999OrderCartDetails>tbody>tr>td:nth-child(1)>input" if options[:special] #&& (count_special == 1)
      click "css=#procedureDetails>tbody>tr>td:nth-child(1)>input" if options[:procedures] #&& (count_procedures == 1)
      click "css=#nonProcedureDetails>tbody>tr>td:nth-child(1)>input" if options[:non_procedures]
      click "css=#oxygenOrderCartDetails>tbody>tr>td:nth-child(1)>input" if options[:oxygen]
      return total_click = 1
    elsif options[:orders] == "multiple" || options[:multiple]
      if options[:drugs] && (count_drugs > 0)
        count_drugs.times do |row|
          check "css=#drugOrderCartDetails>tbody>tr:nth-child(#{row + 1})>td:nth-child(1)>input"# jmerelos v1.4
          drugs_click += 1
        end
      end
      if options[:supplies] && (count_supplies > 0)
        count_supplies.times do |row|
          check "css=#suppliesOrderCartDetails>tbody>tr:nth-child(#{row + 1})>td:nth-child(1)>input"

          supplies_click += 1
        end
      end
      if options[:ancillary] && (count_ancillary > 0)
        count_ancillary.times do |row|
          check "css=#ancillaryOrderCartDetails>tbody>tr:nth-child(#{row + 1})>td:nth-child(1)>input"
          ancillary_click += 1
        end
      end
      if options[:others] && (count_others > 0)
        count_others.times do |row|
          check "css=#miscellaneousOrderCartDetails>tbody>tr:nth-child(#{row + 1})>td:nth-child(1)>input"
          others_click += 1
        end
      end
      if options[:special] && (count_special > 0)
        count_special.times do |row|
          check "css=#special9999OrderCartDetails>tbody>tr:nth-child(#{row + 1})>td:nth-child(1)>input"
          special_click += 1
        end
      end
      if options[:procedures] && (count_procedures > 0)
        count_procedures.times do |row|
          check "css=#procedureDetails>tbody>tr:nth-child(#{row + 1})>td:nth-child(1)>input"
          procedures_click += 1
        end
      end
      if options[:non_procedures] && (count_non_procedures > 0)
        count_non_procedures.times do |row|
          check "css=#nonProcedureDetails>tbody>tr:nth-child(#{row + 1})>td:nth-child(1)>input"
          non_procedures_click += 1
        end
      end 
      if options[:oxygen] && (medical_cases > 0)
        medical_cases.times do |row|
          check "css=#oxygenOrderCartDetails>tbody>tr:nth-child(#{row + 1})>td:nth-child(1)>input"
          medical_cases_click += 1
        end
      end
    end

    total_click = drugs_click + supplies_click + ancillary_click + others_click + special_click + procedures_click + non_procedures_click + medical_cases_click
    sleep 3
    return total_click
  end
  #method that confirms the validation of all items in the order cart
  def confirm_validation_all_items(options={})
    click "validate"
    sleep 3
    click("//input[@type='button' and @value='OK' and @onclick='MultiplePrinters.validate(); return false;']") if is_visible("multiplePrinterPopup")
    get_confirmation() if is_confirmation_present
    choose_ok_on_next_confirmation() if is_confirmation_present
     sleep 20
    if is_element_present("userEntryPopup")
              username = options[:username] || "sel_0278_validator"
              password = options[:password] || "123qweuser"
              sleep 3
              if is_element_present("usernameInputBox")
                puts "username1 = #{username}"
                      type("usernameInputBox", username)
                      type("passwordInputBox", password)
                      click("//button[2]", :wait_for => :page)
              end

              if is_element_present("id=pharmUsername")
                   puts "username2 = #{username}"
                    type("id=pharmUsername", username) 
                    type("id=pharmPassword", password)
                    click("id=validatePharmacistOK")
              end
              sleep 3
    else
              sleep 20
              if is_element_present("userEntryPopup")
                          username = options[:username] || "sel_0278_validator"
                          password = options[:password] || "123qweuser"
                          sleep 3
                          if is_element_present("usernameInputBox")
                          puts "username3 = #{username}"                            
                                type("usernameInputBox", username)
                                type("passwordInputBox", password)
                                click("//button[2]", :wait_for => :page)
                          end
                          if is_element_present("id=pharmUsername")
                             puts "username4 = #{username}"                            
                              type("id=pharmUsername", username) 
                              type("id=pharmPassword", password)
                              click("id=validatePharmacistOK")
                          end
              end
    end
    sleep 60
    success = is_text_present("has been validated successfully.")
    return get_confirmation if is_confirmation_present
    return success
  end
  #method that confirms the validation of SOME items in the order cart
  def confirm_validation_some_items(options={})
    click("validate")
    click("//input[@type='button' and @value='OK' and @onclick='MultiplePrinters.validate(); return false;']", :wait_for => :page) if is_visible("multiplePrinterPopup")
    get_confirmation() == "There are still unselected items to validate.  Continue?"
    sleep 3    
    username = options[:username] || "sel_0278_validator"
    password = options[:password] || "123qweuser"
    if is_element_present("id=pharmUsername")
            type("id=pharmUsername", username) 
            type("id=pharmPassword", password)
            click("id=validatePharmacistOK")
    end
    sleep 3
    is_element_present("validate")
  end
  def validate_pending_orders(options={})
    go_to_general_units_page
    click "link=Order(s) for Validation" #click "link=Pending Orders"
    sleep 10
    while !is_text_present("#{options[:pin]}") #click "link=Last »", :wait_for => :element, :element => "link=#{pin}" r28327 not applicable
      click "next"
      sleep 5
    end
    click "//a[@href='/nursing/general-units/generalUnitsOrderCart.html?pin=#{options[:pin]}&visitNo=#{options[:visit_no]}']", :wait_for => :page
    if options[:with_role_manager]
      sleep 1
      is_editable("cartDetailNumber")
    elsif options[:no_validate]
      !is_element_present "//input[@type='checkbox']"
    else
      sleep 2
      username = options[:username] || "sel_0287_validator"
      password = options[:password] || "123qweuser"
      type("pharmUsername", username)
      type("pharmPassword", password)
      click("validatePharmacistOK")
      sleep 1
      is_editable("cartDetailNumber")
    end
  end
  #method that clicks the delete for one item only
  def delete_order
    sleep 5
    item_code = get_text("//html/body/div/div[2]/div[2]/form/ul/table/tbody/tr/td[4]")
    item_desc = get_text("//html/body/div/div[2]/div[2]/form/ul/table/tbody/tr/td[5]")
    click "cartDetailNumber"
    click "delete", :wait_for => :element, :element => "//input[@value='Proceed']"
    click "//input[@value='Proceed']", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/div[3]/div") == "Order item #{item_code} (#{item_desc}) has been deleted successfully."
  end
  def verify_order_list(options ={})
    patient_pin_search options
    self.go_to_gu_page_for_a_given_pin("Order List", options[:pin])
    click "//a[@title='ANCILLARY']/span" if options[:package] #ancillary tab
    is_text_present(options[:item])
  end
  def select_discharge_type(type)
    if type == "standard"
      click "standardDischargeRadio"
    elsif type == "express"
      click "expressDischargeRadio"
    end
    click "//input[@onclick='submitDischargeForm(this);' and @type='button' and @value='Discharge']"
    sleep 30
    if is_element_present("RoomBoardPostingPopup")
      #(click "YES", :wait_for => :page) if is_visible("RoomBoardPostingPopup")
     click "YES", :wait_for => :element, :element => "RoomBoardPostingPopup"

    elsif is_element_present("errorMessages")
      sleep 5
    else
      #wait_for_page_to_load "30000" # comment this when @stlukes and use the sleep below
      sleep 5
    end
  end
  def clinical_discharge(options = {})
    if options[:pf_amount]
      sleep 1
      select "dischargeDisposition", "label=AS PER DOCTOR'S ADVISE" if is_element_present "dischargeDisposition"
      get_alert() if is_alert_present
      sleep 5
      click "link=Professional Fee Charging"
      sleep 5      
      mcount= get_xpath_count("//html/body/div[1]/div[2]/div[2]/form/div[2]/div/div[2]/table/tbody/")
      account_class = get_text("//html/body/div[1]/div[2]/div[2]/div[7]/div/div[3]/div[2]/div[3]/label") if is_element_present("//html/body/div[1]/div[2]/div[2]/div[7]/div/div[3]/div[2]/div[3]/label") 
      account_class = get_text("//html/body/div[1]/div[2]/div[2]/div[10]/div/div[3]/div[2]/div[3]/label") if is_element_present("//html/body/div[1]/div[2]/div[2]/div[10]/div/div[3]/div[2]/div[3]/label") 
      account_class = get_text("//html/body/div[1]/div[2]/div[2]/div[7]/div/div[2]/div[2]/div[3]/label") if is_element_present("//html/body/div[1]/div[2]/div[2]/div[7]/div/div[2]/div[2]/div[3]/label")
      account_class = account_class.to_s
#      if account_class.include? " "
#              account_class = account_class.gsub(" ","")
#              puts "account_class #{account_class}"
#      end
      count = mcount.to_i
      if options[:outpatient]
                              click "admDoctorRadioButton0"
                              click "btnAddPf"
                              sleep 5
                              select "pfTypeCode", "label=#{options[:pf_type]}" if options[:pf_type]
                              type "pfAmountInput", options[:pf_amount] if options[:pf_amount]
                              type "id=remarksInput", "asdasdas" if is_element_present("id=remarksInput")
                              click "btnAddPf" # DIRECT PF PAYMENT
                              sleep 6
      else
              if count >= 2 and account_class == "Hmo"
                      while count != 0
                              radio = count - 1
                              click "admDoctorRadioButton#{radio}"
                              click "btnAddPf"
                              sleep 5
                              select "pfTypeCode", "label=#{options[:pf_type]}" if options[:pf_type]
                              type "pfAmountInput", options[:pf_amount] if options[:pf_amount]
                             type "id=remarksInput", "asdasdas" if is_element_present("id=remarksInput")                              
                              click "btnAddPf" # DIRECT PF PAYMENT
                              sleep 6
                              puts "add - #{radio}"
                              count = count -1
                      end
              else
                              click "admDoctorRadioButton0"
                              click "btnAddPf"
                              sleep 5
                              select "pfTypeCode", "label=#{options[:pf_type]}" if options[:pf_type]
                              type "pfAmountInput", options[:pf_amount] if options[:pf_amount]
                              type "id=remarksInput", "asdasdas" if is_element_present("id=remarksInput")                              
                              click "btnAddPf" # DIRECT PF PAYMENT
                              sleep 6
               end
      end
    end
    if options[:with_complementary]
      complementary_amount = get_text("maximumComplementaryText").gsub(",","")
      puts "complementary_amount  = #{complementary_amount}"
      click "admDoctorRadioButton0"
      click "btnAddPf", :wait_for => :element, :element => "pfTypeCode"
      select "pfTypeCode", "label=PF INCLUSIVE OF PACKAGE"
      type "pfAmountInput", complementary_amount
      type "id=remarksInput", "asdasdas" if is_element_present("id=remarksInput")
      click "btnAddPf"
      sleep 10      
    end
    sleep 10      

    click "dischargeAction", :wait_for => :element, :element => "//input[@type='button' and @value='Discharge' and @onclick='submitDischargeForm(this);']"
    sleep 6
    select_discharge_type(options[:type])
   sleep 8
    if options[:no_pending_order]
      sleep 50
      return is_text_present("General Units") || is_text_present("Occupancy List")  # assert successful discharge if user is redirected to GU listing or occupancy list for ER
    else
      return false if is_text_present("Cannot discharge")
    end
  end
  def add_final_diagnosis(options={})
    click "link=Diagnosis/Disposition" #v1.4-RC4
    final_diagnosis = options[:diagnosis] || "CHOLERA"
    disposition = options[:disposition] || "DISCHARGED AFTER DIAGNOSTICS"
        sleep 10
    if options[:text_final_diagnosis]
      type("txtFinalDiagnosis", options[:text_final_diagnosis])
      click("//input[@type='button' and @onclick='addFinalDiagnosis();' and @value='Add']")
        sleep 10
      select("diagnosisForm.disposition", disposition)#v1.4.1a - RC5
      click("btnSave") if options[:save]
	  click "id=noTHM" if is_element_present( "id=noTHM")
	  sleep 3
	   click "id=noADPA" if is_element_present( "id=noADPA")
	   sleep 3		
	  click "id=okButton" if is_element_present( "id=okButton")			
      is_text_present("#{options[:text_final_diagnosis]}")
    else
      if is_text_present("#{final_diagnosis}")
        select("diagnosisForm.disposition", disposition)#v1.4.1a - RC5
        click("btnSave") if options[:save]
        sleep 10
	   click "id=noTHM" if is_element_present( "id=noTHM")
	   sleep 3
	   click "id=noADPA" if is_element_present( "id=noADPA")
	   sleep 3
	   click "id=okButton" if is_element_present( "id=okButton")
sleep 30
				
        is_text_present("#{final_diagnosis}")
      else
        click "btn_icd10Add", :wait_for => :visible, :element => "icd10_entity_finder_key"
        sleep 10
        type("icd10_entity_finder_key", final_diagnosis)
        click("//input[@type='button' and @value='Search' and @onclick='Icd10Finder.search();']", :wait_for => :element, :element => "link=#{final_diagnosis}")
        sleep 10
        click("link=#{final_diagnosis}", :wait_for => :not_visible, :element => "link=#{final_diagnosis}")

        select("diagnosisForm.disposition", disposition)#v1.4.1a - RC5
        click("btnSave") if options[:save]
	  click "id=noTHM" if is_element_present( "id=noTHM")
	  sleep 3
	   click "id=noADPA" if is_element_present( "id=noADPA")
	   sleep 3		
	  click "id=okButton" if is_element_present( "id=okButton")				
        sleep 10
        click "link=Diagnosis/Disposition" #v1.4-RC4
        sleep 10
        is_text_present("#{final_diagnosis}")
      end
    end
  end
  def remove_final_diagnosis(options={})
    count = get_css_count("css=#diagnosisRows>tr")
    count.times do |rows|
      my_row = get_text("//html/body/div/div[2]/div[2]/form/div[3]/div/div[3]/div/table/tbody/tr[#{rows + 1}]/td[2]/a/div")
      if my_row == options[:diagnosis]
        stop_row = rows
        click("//html/body/div/div[2]/div[2]/form/div[3]/div/div[3]/div/table/tbody/tr[#{stop_row + 1}]/td[3]/input")
        break
      end
    end
    is_text_present(options[:diagnosis])
  end
  def clinically_discharge_patient(options={})
    if options[:outpatient]
      patient_pin_search(:pin => options[:pin])
#      go_to_su_page_for_a_given_pin("Discharge Instructions\302\240", options[:pin])
      go_to_su_page_for_a_given_pin("regexp:Discharge Instructions\\s", options[:pin])
      add_final_diagnosis(options)
      go_to_occupancy_list_page
      patient_pin_search(:pin => options[:pin])
      go_to_su_page_for_a_given_pin("Doctor and PF Amount", options[:pin])
      sleep 3
      visit_no = get_text("banner.visitNo").gsub(' ', '')
      result = clinical_discharge(options)
    elsif options[:er]
      patient_pin_search(:pin => options[:pin])
      go_to_er_page_using_pin("Discharge Instructions\302\240", options[:pin])
      add_final_diagnosis(options)
      go_to_er_page
      patient_pin_search(:pin => options[:pin])
      go_to_er_page_using_pin("Doctor and PF Amount", options[:pin])
      sleep 3
      visit_no = get_text("banner.visitNo").gsub(' ', '')
      result = clinical_discharge(options)
   elsif options[:or]
      patient_pin_search(:pin => options[:pin])
      go_to_or_page_for_a_given_pin("regexp:Discharge Instructions\\s", options[:pin])
      add_final_diagnosis(options)
      go_to_occupancy_list_page
      patient_pin_search(:pin => options[:pin])
      go_to_su_page_for_a_given_pin("Doctor and PF Amount", options[:pin])
      sleep 3
      visit_no = get_text("banner.visitNo").gsub(' ', '')
      result = clinical_discharge(options)
    else
      puts "here me"
      patient_pin_search(:pin => options[:pin])
      sleep 3
   #   go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", options[:pin])
      go_to_or_page_for_a_given_pin("label=regexp:Discharge Instructions\\s", options[:pin])
      
      sleep 6
      add_final_diagnosis(options)
      go_to_general_units_page
      patient_pin_search(:pin => options[:pin])
      go_to_gu_page_for_a_given_pin("Doctor and PF Amount", options[:pin])
      sleep 3
      visit_no = get_text("banner.visitNo").gsub(' ', '')
      result = clinical_discharge(options)
    end
    sleep 6
    return false if is_text_present("There are still pending orders in cart.")
    return false if is_text_present("Cannot discharge")
    return false if is_text_present("Rank 1 Guarantor is Required. Discharge not allowed.")
    if result == true
          return visit_no
    end
  end
  def add_attending_doctor(options={})
    doctor = options[:doctor] || "0126"
    doctor_type = options[:doctor_type] || "ATTENDING"
    click("btnAddDoctor") if !(is_element_present("doctorInput"))
    sleep 3
    click("searchDoctorPopup", :wait_for => :visible, :element => "entity_finder_key") if !(is_visible("entity_finder_key"))
    type("entity_finder_key", doctor)
    click("//input[@type='button' and @value='Search' and @onclick='DF.search();']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div") if !(is_element_present("//tbody[@id='finder_table_body']/tr/td[2]/div"))
    click("//tbody[@id='finder_table_body']/tr/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div") if is_visible("//tbody[@id='finder_table_body']/tr/td[2]/div")
    select("doctorTypeCode", "label=#{doctor_type}")
    sleep 1
    click("btnAddDoctor")
    return get_alert if is_alert_present
    return true if is_text_present("Doctor and PF Amount")
  end
  def edit_attending_doctor(options={})
    doctor = options[:doctor] || "0126"
    doctor_type = options[:doctor_type] || "REFERRING"
    count = options[:count].to_i # needed to verify which doctor to be edited. count = 1 means the first doctor is selected
    if count > 1
      click("admDoctorRadioButton#{count - 1}")
      click("btnEditDoctor", :wait_for => :visible, :element => "doctorInput") if !(is_visible("doctorInput"))
      click("searchDoctorPopup", :wait_for => :visible, :element => "entity_finder_key") if !(is_visible("entity_finder_key"))
      type("entity_finder_key", doctor)
      click("//input[@type='button' and @value='Search' and @onclick='DF.search();']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div") if !(is_element_present("//tbody[@id='finder_table_body']/tr/td[2]/div"))
      click("//tbody[@id='finder_table_body']/tr/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div") if is_visible("//tbody[@id='finder_table_body']/tr/td[2]/div")
      select("doctorTypeCode", "label=#{doctor_type}")
      sleep 1
      click("btnAddDoctor")
      return get_alert if is_alert_present
      a = is_text_present("Doctor and PF Amount")
      b = get_text("admissionDoctorBeanRows").include?("#{doctor}")
      c = get_text("admissionDoctorBeanRows").include?("#{doctor_type}")
      return a && b && c
    else
      return "Cannot edit Attending Doctor"
    end
  end
  def pending_orders
    sleep 8
    get_text Locators::NursingGeneralUnits.pending_orders
  end
  def go_to_order_cart_page_using_pending_orders_for_pin(pin)
    click "link=pending orders", :wait_for => :text, :text => "Orders for Validation"
    click "link=Last »"
    sleep 10
    click "link=#{pin}", :wait_for => :page
    value = get_text('//*[@id="banner.pin"]')
    value.gsub(' ', '') == pin
  end
  def defer_clinical_discharge(options={})
    reason = options[:reason] || "Undo Clinical Discharge"
    remarks = options[:remakrs] || "Remarks: Undo Clinical Discharge"
    if options[:outpatient]
      select "userAction#{options[:pin]}", "label=Defer Discharge" if options[:pin]
      click Locators::NursingSpecialUnits.submit_button_spu
      sleep 2
      type "reasonArea", reason
      type "remarksArea", remarks
      click "submitDefer", :wait_for => :page
      !is_text_present("Defer Discharge")
    elsif options[:er]
      click("//input[@value='Defer']")
      sleep 2
      type "reasonArea", reason
      type "remarksArea", remarks
      click "submitDefer", :wait_for => :page
      !is_element_present("//input[@value='Defer']")
    else
      select "userAction#{options[:pin]}", "label=Defer Discharge" if options[:pin]
      click Locators::NursingSpecialUnits.submit_button
      sleep 2
      type "reasonArea", reason
      type "remarksArea", remarks
      click "submitDefer", :wait_for => :page
      !is_text_present("Defer Discharge")
    end
  end
  def or_print_gatepass(options={})
    go_to_occupancy_list_page
    patient_pin_search options
    sleep 5
    if get_text("css=#occupancyList>tbody>tr>:nth-child(8)") == ("Discharged With Payment")
      click("btnPhysOut-#{options[:visit_no]}", :wait_for => :page) if is_element_present("btnPhysOut-#{options[:visit_no]}")
                 click 'name=physout', :wait_for => :element, :element => 'submitPhysOut' if is_element_present('physout')
                  sleep 1
                  select 'roomBedStatusOptions', "label=GENERAL CLEANING"
                  click 'id=submitPhysOut'  if is_element_present("id=submitPhysOut") # :wait_for => :page #General Cleaning
                  sleep 10
                  click "id=yesButton" if is_element_present("id=yesButton")  #:wait_for => :page
                  click "//html/body/div[5]/div[2]/input[5]" if is_element_present("//html/body/div[5]/div[2]/input[5]")
                  sleep 10
                  click "id=popup_ok" if is_element_present("id=popup_ok")
                  sleep 10
                  click "id=tagDocument"  if is_element_present("id=tagDocument")
      go_to_occupancy_list_page
      patient_pin_search options
    sleep 5
      return true if is_text_present("NO PATIENT FOUND")
    elsif get_text("css=#occupancyList>tbody>tr>:nth-child(8)") == ("Discharged with Payment")
      click("btnPhysOut-#{options[:visit_no]}", :wait_for => :page) if is_element_present("btnPhysOut-#{options[:visit_no]}")
                  click 'name=physout', :wait_for => :element, :element => 'submitPhysOut' if is_element_present('physout')
                  sleep 3
                  click "css=#DIPopUpDialog > input[type=\"submit\"]" if is_element_present("css=#DIPopUpDialog > input[type=\"submit\"]")
				sleep 3	
                  select 'roomBedStatusOptions', "label=GENERAL CLEANING"
                  click 'id=submitPhysOut'  if is_element_present("id=submitPhysOut") # :wait_for => :page #General Cleaning
                  sleep 10
                  click "id=yesButton" if is_element_present("id=yesButton")  #:wait_for => :page
                  click "//html/body/div[5]/div[2]/input[5]" if is_element_present("//html/body/div[5]/div[2]/input[5]")
                  sleep 10
                  click "id=popup_ok" if is_element_present("id=popup_ok")
                  sleep 10
                  click "id=tagDocument"  if is_element_present("id=tagDocument")         
      go_to_occupancy_list_page
      patient_pin_search options
    sleep 5
      return true if is_text_present("NO PATIENT FOUND")
  #    //*[@id="btnPhysOut-5301000073"]
    else
      return false
    end
  end
  def er_print_gatepass(options={})
    go_to_er_page
    patient_pin_search options
    sleep 3
    if get_text("css=#occupancyList>tbody>tr>:nth-child(7)") == ("Discharged With Payment") || get_text("css=#occupancyList>tbody>tr>:nth-child(7)") == ("Discharged with Payment")
      click("btnPhysOut-#{options[:visit_no]}", :wait_for => :page) if is_element_present("btnPhysOut-#{options[:visit_no]}")
                  click 'name=physout', :wait_for => :element, :element => 'submitPhysOut' if is_element_present('physout')
                  sleep 3
                  click "css=#DIPopUpDialog > input[type=\"submit\"]" if is_element_present("css=#DIPopUpDialog > input[type=\"submit\"]")
				sleep 3	
                  select 'roomBedStatusOptions', "label=GENERAL CLEANING"
                  click 'id=submitPhysOut'  if is_element_present("id=submitPhysOut") # :wait_for => :page #General Cleaning
                  sleep 10
                  click "id=yesButton" if is_element_present("id=yesButton")  #:wait_for => :page
                  click "//html/body/div[5]/div[2]/input[5]" if is_element_present("//html/body/div[5]/div[2]/input[5]")
                  sleep 10
                  click "id=popup_ok" if is_element_present("id=popup_ok")
                  sleep 10
                  click "id=tagDocument"  if is_element_present("id=tagDocument")
      patient_pin_search options
      return true if is_text_present("NO PATIENT FOUND")
    else
      return false
    end
  end
  def print_gatepass(options ={})
    if is_text_present("NO PATIENT FOUND") == true
    else
            if get_text("//html/body/div/div[2]/div[2]/table/tbody/tr/td[5]") == "Discharged With Payment"
                  click 'name=physout', :wait_for => :element, :element => 'submitPhysOut' if is_element_present('physout')
                  sleep 3
                  click "css=#DIPopUpDialog > input[type=\"submit\"]" if is_element_present("css=#DIPopUpDialog > input[type=\"submit\"]")
				sleep 3					
                  select 'roomBedStatusOptions', "label=GENERAL CLEANING"
                  click 'id=submitPhysOut'  if is_element_present("id=submitPhysOut") # :wait_for => :page #General Cleaning
                  sleep 10
                  click "id=yesButton" if is_element_present("id=yesButton")  #:wait_for => :page
                  click "//html/body/div[5]/div[2]/input[5]" if is_element_present("//html/body/div[5]/div[2]/input[5]")
                  sleep 10
                  click "id=popup_ok" if is_element_present("id=popup_ok")
                  sleep 10
                  click "id=tagDocument"  if is_element_present("id=tagDocument")
                  sleep 10           
                  if is_text_present("Discharged Patients")
                        go_to_general_units_page
                        patient_pin_search options
                        if options[:no_result]
                              sleep 4
                              return true if is_text_present("NO PATIENT FOUND")
                        else
                              return false
                        end
                  else
                        return false
                  end
            else
                  return false
            end
    end
  end
  def verify_error_message_in_package
    click "link=OUTPATIENT PACKAGE MANAGEMENT", :wait_for => :page
    click '//*[@id="add"]', :wait_for => :page
    error = get_text '//*[@id="*.errors"]'
    error == "Package is a required field.\nPackage Type is a required field.\nDoctor is a required field."
  end
  def click_outpatient_package_management
    click "link=OUTPATIENT PACKAGE MANAGEMENT", :wait_for => :page
    is_element_present("packageOrderCode")
  end
  def wellness_allocate_doctor_pf(options={})
    if options[:pf_type]
      click("id=allocatePf", :wait_for => :element, :element => "id=admDoctorRadioButton0")
      click("id=admDoctorRadioButton0")
      click("id=btnAddPf")
      sleep 3
      select("id=pfTypeCode", options[:pf_type]) if options[:pf_type] #PF INCLUSIVE OF PACKAGE
      type "id=pfAmountInput", options[:pf_amount] if options[:pf_amount]
      click "id=btnAddPf"
      sleep 5
      return get_alert if is_alert_present
      #click("//input[@type='submit' and @value='Submit']", :wait_for => :page)
      click("css=input[type=\"submit\"]", :wait_for => :page)
    end
    is_element_present("updateGuarantor")
  end
  def add_unordered_package_items
    click "//input[@type='checkbox']"
    sleep 2
    click "//input[@type='button' and @value='Add to Cart']"
  end
  def additional_order_pf(options={}) #check other specs before changing
    sleep 5
    if options[:add]
      click "btnAddDoctor"
      select "doctorTypeCode", options[:add_doctor_type]
      click "searchDoctorPopup"
      sleep 2
      type "entity_finder_key", options[:add_doctor]
      click '//input[@type="button" and @onclick="DF.search();" and @value="Search"]'
      sleep 5
      click "btnAddDoctor"
    end
    if options[:edit]
      count = get_css_count("css=#admissionDoctorBeanRows>tr")
      count.times do |rows|
        my_row = get_text("css=#admissionDoctorBeanRows>tr:nth-child(#{rows + 1})>td:nth-child(3)")
        if my_row == (options[:edit_type])
          stop_row = rows
          click "admDoctorRadioButton#{stop_row}"
          click "btnEditDoctor"
          sleep 10
        end
      end
      click("searchDoctorPopup")
      sleep 2
      type "entity_finder_key", options[:add_doctor]
      click '//input[@type="button" and @onclick="DF.search();" and @value="Search"]'
      sleep 5
      click "btnAddDoctor"
    end
    if options[:delete]
      count = get_css_count("css=#admissionDoctorBeanRows>tr")
      count.times do |rows|
        my_row = get_text("css=#admissionDoctorBeanRows>tr:nth-child(#{rows + 1})>td:nth-child(3)")
        if my_row == (options[:delete_type])
          stop_row = rows
          click "admDoctorRadioButton#{stop_row}"
          click "btnRemoveDoctor"
          sleep 10
        end
      end
      get_confirmation if is_confirmation_present
    end
    if options[:add_pf]
      count = get_css_count("css=#admissionDoctorBeanRows>tr")
      count.times do |rows|
        row_of_doctor_pin = get_text("css=#admissionDoctorBeanRows>tr:nth-child(#{rows + 1})>td:nth-child(1)").split("-")[0].gsub(" ", "")
        if row_of_doctor_pin == (options[:pin])
          stop_row = rows
          click "admDoctorRadioButton#{stop_row}"
          click "btnAddPf"
          sleep 3
          select("pfTypeCode", options[:pf_type]) if options[:pf_type]
          type "pfAmountInput", options[:pf_amount] if options[:pf_amount]
          click "btnAddPf"
          sleep 3
        end
      end
      contents = get_text("pfTable0")
      return contents.include?(options[:pf_type])
    end

    # options below pertains pf type of doctors. note : pf_type table differs with each doctor.
    if options[:pf_type]
      if options[:add_pf_type]
        click("btnAddPf")
        sleep 3
        select("pfTypeCode", options[:pf_type]) if options[:pf_type]
        type "pfAmountInput", options[:pf_amount] if options[:pf_amount]
        click "btnAddPf"
        sleep 3
        contents = get_text("pfTable0")
        contents.include?(options[:pf_type])
        return(options[:pf_type])
      end
      if options[:edit_pf_type]
        count = get_css_count("css=#admissionDoctorBeanRowsPf0>tr")
        count.times do |rows|
        my_row = get_text("css=#admissionDoctorBeanRowsPf0>tr:nth-child(#{rows + 1})>td>div")
          if my_row == (options[:pf_type])
            stop_row = rows
            click "0edit_pf#{stop_row}"
            sleep 2
            select "pfTypeCode", options[:new_pf_type] if options[:new_pf_type]
            type "pfAmountInput", options[:pf_amount]
            click "0save_pf#{stop_row}"
            sleep 3
          end
        end
        return (get_text("css=#admissionDoctorBeanRowsPf0>tr").include?(options[:new_pf_type]))  if options[:new_pf_type]
        return(options[:pf_amount]) if options[:pf_amount]
      end
      if options[:delete_pf_type]
        count = get_css_count("css=#admissionDoctorBeanRowsPf0>tr")
        sleep 3
        count.times do |rows|
          my_row = get_text("css=#admissionDoctorBeanRowsPf0>tr:nth-child(#{rows + 1})>td>div")
          if my_row == (options[:pf_type])
            stop_row = rows
            click "0delete_pf#{stop_row}"
            sleep 3
          end
        end
       return get_confirmation
      end
    end
    return get_text("//table[@id='doctorsTable']/tbody").include?(options[:add_doctor]) if options[:add]
    return get_text("//table[@id='doctorsTable']/tbody").include?(options[:delete_type]) if options[:delete]
  end
  def add_take_home_med(options={})
    sleep 1
    click("link=Medication")
    click "//input[@type='button' and @value='ADD NEW' and @onclick='performAddNewOperation()']",:wait_for => :element, :element => "medication_select_popup"
    type "prescription_medicineName", options[:type_med] if options[:type_med]
    if options[:service_code]
      click "btnMedicineFind",:wait_for => :element, :element => "orderItemFinderForm"
      type "oif_entity_finder_key", options[:service_code]
      sleep 1
      click '//input[@type="button" and @onclick="DIF.search();" and @value="Search"]', :wait_for => :element, :element => 'css=#oif_finder_table_body>tr>td>div>a'
      @@service_code_text = get_value"prescription_medicineName"
      click 'css=#oif_finder_table_body>tr>td>div>a' if is_element_present'css=#oif_finder_table_body>tr>td>div>a'
      sleep 2
    end
    if options[:doctor]
      click "btnDoctorFind", :wait_for => :visible, :element => "entity_finder_key"
      type "entity_finder_key",options[:doctor]
      click "//input[@value='Search']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
      click "//tbody[@id='finder_table_body']/tr/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
    end
    sleep 3
    select "prescription_medFrequency",options[:frequency] || "ONCE A WEEK"
    select "prescription_route",options[:route] || "ORAL"
    type "prescription_dosage", options[:dosage] || "5"
    type "prescription_quantityPerTake", options[:quantity_per_take] || "1"
    type "prescription_quantity", options[:quantity] || "1"
    type "prescription_duration", options[:duration] || "8"
    type "prescription_remarks", "Medication Remarks(1000 character limit)"
    click "btnPopupAction" if options[:add]
    click "btnCancel" if options[:cancel]
    a1 = (get_text("css=#take_home_medication_result").include?(options[:type_med])) if options[:type_med] && options[:add]
    a2 = (get_text("css=#take_home_medication_result").include?(@@service_code_text)) if options[:service_code] && options[:add]
    return a1 if options[:type_med]
    return a2 if options[:service_code]
  end
  def edit_take_home_med(options={})
    click("link=Medication")
    sleep 1
    count = get_css_count("css=#take_home_medication_result>tr")

    if options[:edit]
      count.times do |rows|
      my_row = get_text("css=#take_home_medication_result>tr:nth-child(#{rows + 1})>td:nth-child(24)")
        if my_row == options[:item]
          stop_row = rows
          click("css=#take_home_medication_result>tr:nth-child(#{stop_row + 1})>td:nth-child(31)>input")
        end
      end
      type "prescription_medicineName", options[:type_med] if options[:type_med]
      if options[:service_code]
          click "btnMedicineFind",:wait_for => :element, :element => "orderItemFinderForm"
          type "oif_entity_finder_key",options[:service_code]
          sleep 1
          click '//input[@type="button" and @onclick="DIF.search();" and @value="Search"]', :wait_for => :element, :element => 'css=#oif_finder_table_body>tr>td>div>a'
          click 'css=#oif_finder_table_body>tr>td>div>a', :wait_for => :not_visible, :element => 'css=#oif_finder_table_body>tr>td>div>a'
      end
      if options[:doctor]
        click "btnDoctorFind", :wait_for => :element, :element => "entity_finder_key"
        type "entity_finder_key", options[:doctor]
        click "//input[@value='Search']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
        click "//tbody[@id='finder_table_body']/tr/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
      end
      sleep 3
      select "prescription_medFrequency",options[:frequency] || "ONCE A WEEK"
      select "prescription_route",options[:route] || "ORAL"
      type "prescription_dosage", options[:dosage] || "5"
      type "prescription_quantityPerTake", options[:quantity_per_take] || "1"
      type "prescription_quantity", options[:quantity] || "1"
      type "prescription_duration", options[:duration] || "8"
      type "prescription_remarks", "Medication Remarks(1000 character limit)"
      click "btnPopupAction" if options[:update]
      click "btnCancel" if options[:cancel]
      a1 = (get_text("css=#take_home_medication_result").include?(options[:type_med])) if options[:type_med] && options[:update]
      a2 = (get_text("css=#take_home_medication_result").include?(options[:service_code])) if options[:service_code] && options[:update]
      return a1 if options[:type_med]
      return a2 if options[:service_code]
    end

    if options[:delete]
      count.times do |rows|
      my_row = get_text("css=#take_home_medication_result>tr:nth-child(#{rows + 1})>td:nth-child(24)")
        if my_row == options[:item]
          stop_row = rows
          click("css=#take_home_medication_result>tr:nth-child(#{stop_row + 1})>td:nth-child(31)>input:nth-child(2)")
        end
      end
      sleep 3
      is_text_present("Marked for deletion")
    end
  end
  def outpatient_consultation(options={})
    click "link=Outpatient Consultation"
    sleep 3
    click "css=#doctorDiv>input", :wait_for => :visible, :element => "entity_finder_key"
    sleep 1
    type "entity_finder_key", options[:doctor]
    sleep 1
    click "//input[@value='Search']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
    sleep 1
    click "//tbody[@id='finder_table_body']/tr/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
    sleep 1
    type "appointmentBean.clinicSchedule", options[:clinic_sched] || "MON (08:00-14:00)"
    type "appointmentBean.clinicLocation", options[:clinic_loc] || "Clinic Location"
    type "appointmentBean.appointmentDate", options[:date] || (Date.today+1).strftime("%m/%d/%Y")
    click"appointmentTimeButton"
    click"//a[@class='ui-state-default ui-state-active']"
    sleep 1
    click '//input[@type="button" and @onclick="submitForm(this)" and @value="Add Outpatient Consultation"]', :wait_for => :page
    sleep 1
    return get_text("clinicalDischargeHomeInstructionForm.errors") if is_element_present("clinicalDischargeHomeInstructionForm.errors")
    if options[:outpatient]
      return true if is_text_present("Special Units Home › Occupancy List › Discharge Instructions")
    else
      return true if is_text_present("General Units › Discharge Instructions")
    end
  end
  def edit_delete_outpatient_consultation(options={})
    count = get_css_count("css=#appointmentBean>tbody>tr")
    count.times do |rows|
      my_row = get_text("css=#appointmentBean>tbody>tr:nth-child(#{rows + 1})>td")
      if my_row == options[:doctor_name]
        @stop_row = rows
      end
    end
    if options[:edit]
      click("css=#appointmentBean>tbody>tr:nth-child(#{@stop_row + 1})>td:nth-child(5)>span", :wait_for => :page)
      if options[:new_doctor]
        click "css=#doctorDiv>input", :wait_for => :visible, :element => "entity_finder_key"
        sleep 1
        type "entity_finder_key", options[:new_doctor]
        sleep 1
        click "//input[@value='Search']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
        sleep 1
        click "//tbody[@id='finder_table_body']/tr/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr/td[2]/div"
        sleep 1
        type "appointmentBean.clinicSchedule", options[:clinic_sched] || "MON (08:00-14:00)"
        type "appointmentBean.clinicLocation", options[:clinic_loc] || "Clinic Location"
        type "appointmentBean.appointmentDate", options[:date] || (Date.today+1).strftime("%m/%d/%Y")
        click '//input[@type="button" and @onclick="submitForm(this)" and @value="Add Outpatient Consultation"]', :wait_for => :page
        return true if is_text_present("General Units › Discharge Instructions")
        return true if is_text_present("Special Units Home › Occupancy List › Discharge Instructions")
      else
        return get_value("appointmentBean.referralDoctorName")
      end
    elsif options[:delete]
      before_delete = get_css_count("css=#appointmentBean>tbody>tr")
      sleep 1
      click("css=#appointmentBean>tbody>tr:nth-child(#{@stop_row + 1})>td:nth-child(5)>input")
      sleep 1
      click("btnDelete", :wait_for => :page)
      sleep 1
      after_delete = get_css_count("css=#appointmentBean>tbody>tr")
      return true if get_text("css=#appointmentBean>tbody>tr") == "Nothing found to display."
      return true if after_delete < before_delete && !is_text_present(options[:doctor_name])
    end
  end
  def wellness_update_guarantor(options={})

    if options[:guarantor]
      account_class = options[:account_class] || "INDIVIDUAL"
      guarantor = options[:guarantor] || "INDIVIDUAL"
      click("id=updateGuarantor", :wait_for => :element, :element => "accountClass")
      select("accountClass", account_class)
      click "//input[@type='submit' and @value='Save']", :wait_for => :page
      click("link=New Guarantor", :wait_for => :page)
      if options[:guarantor_code]
        select("guarantorType", guarantor)
        click("findGuarantor", :wait_for => :visible, :element => "bp_entity_finder_key") if guarantor == "HMO" || guarantor == "COMPANY" || guarantor == "BOARD MEMBER" || guarantor == "CREDIT CARD" || guarantor == "WOMEN'S BOARD" || guarantor == "BOARD MEMBER DEPENDENT"
        click("findGuarantor", :wait_for => :visible, :element => "ddf_entity_finder_key") if guarantor == "DOCTOR" || guarantor == "DOCTOR DEPENDENT"
        click("findGuarantor", :wait_for => :visible, :element => "employee_entity_finder_key") if guarantor == "EMPLOYEE" || guarantor == "EMPLOYEE DEPENDENT"
        type("bp_entity_finder_key", options[:guarantor_code]) if guarantor == "HMO" || guarantor == "COMPANY" || guarantor == "BOARD MEMBER" || guarantor == "CREDIT CARD" || guarantor == "WOMEN'S BOARD" || guarantor == "BOARD MEMBER DEPENDENT"
        type("ddf_entity_finder_key", options[:guarantor_code]) if guarantor == "DOCTOR" || guarantor == "DOCTOR DEPENDENT"
        type("employee_entity_finder_key", options[:guarantor_code]) if guarantor == "EMPLOYEE" || guarantor == "EMPLOYEE DEPENDENT"
        click("//input[@type='button' and @value='Search' and @onclick='BusinessPartner.search();']") if guarantor == "HMO" || guarantor == "COMPANY" || guarantor == "BOARD MEMBER" || guarantor == "CREDIT CARD" || guarantor == "WOMEN'S BOARD" || guarantor == "BOARD MEMBER DEPENDENT"
        click("//input[@type='button' and @value='Search' and @onclick='DDF.search();']") if guarantor == "DOCTOR" || guarantor == "DOCTOR DEPENDENT"
        click("//input[@type='button' and @value='Search' and @onclick='EF.search();']") if guarantor == "EMPLOYEE" || guarantor == "EMPLOYEE DEPENDENT"
        sleep 5
#        if guarantor == "DOCTOR" || guarantor == "DOCTOR DEPENDENT"
#          click("css=#ddf_finder_table_body>tr>td:nth-child(2)>div")
#        else
#          click("link=#{options[:gurantor_code]}") if is_element_present("link=#{options[:guarantor_code]}")
#        end
        sleep 3
      end
          type("loa.loaNo", Time.new.strftime("%Y%m%d"))
          click("phFlag1") if options[:philhealth]
          click("includePfTag") if options[:include_pf]
          type("loa.maximumAmount", options[:loa_max]) if options[:loa_max]
          type("loa.percentageLimit", options[:loa_percent]) if options[:loa_percent]
          click("name=_submit", :wait_for => :page)
          click("css=input[type=\"submit\"]" , :wait_for => :page)
          sleep 6
          a =  is_text_present("The Patient Info was updated.")
          #  click("//input[@type='button' and @value='Back']", :wait_for => :page)
          click("css=input[type=\"button\"]", :wait_for => :page)
    end
return a
  end
  def wellness_payment(options={})
    sleep 6
    click "link=PAYMENT" if is_element_present("link=PAYMENT")
		
    if options[:cash]
      
      sleep 20
      type("seniorIdNumber", "1234") if is_element_present("seniorIdNumber")
      sleep 25
      click("paymentToggle")
      sleep 5
      click("opsPaymentBean.cashPaymentMode") #hospital bills payment
      sleep 5
      amount = get_value("cashAmountInPhp").gsub(',','')
      type("cashBillAmount", amount)
      sleep 3
      click("pfPaymentToggle", :wait_for => :visible, :element => "pfPaymentSection")
      sleep 3
      pf_amount = get_text("css=#pfPaymentSection>#paymentDataEntry>div>div:nth-child(2)>fieldset>div>div:nth-child(9)>.value").gsub(',','')
      if pf_amount != "0.00"
        click("opsPfPaymentBean.cashPaymentMode", :wait_for => :visible, :element => "opsPfPaymentBean.pbaCashPaymentBean.billAmount")
        sleep 2
        type("opsPfPaymentBean.pbaCashPaymentBean.billAmount", pf_amount)
      end
      click("//input[@id='submitForm' and @type='submit' and @value='Submit']") if is_element_present("//input[@id='submitForm' and @type='submit' and @value='Submit']")
      click "id=submitForm" if is_element_present( "id=submitForm")

      sleep 10



      get_confirmation if is_confirmation_present
      click "//input[@value='OK']"
      #click("//html/body/div[4]/div[3]/div/button") if is_element_present("soaPrintingDialog")
      #click ("//html/body/div[4]/div[3]/div/button"),  :wait_for => :element, :element => "//body/div[4]/div"
#      if is_element_present("//html/body/div/div[2]/div[2]/form[2]/div/div[3]/input")
#            if get_text("//html/body/div/div[2]/div[2]/form[2]/div/div[3]/input") == "OK"
#                    click("//html/body/div/div[2]/div[2]/form[2]/div/div[3]/input")
#            end
#      end 
     click "id=reqSlip" if is_element_present("id=reqSlip")
     click "id=printButton" if is_element_present("id=printButton")

     sleep 30
     click("popup_ok")   if is_element_present("popup_ok")
     sleep 3
     click "id=tagDocument"  if is_element_present("id=tagDocument")
     sleep 10
      if is_element_present("id=itemizedRadio")
        click("id=itemizedRadio");
        click("//button[@type='button']")  if is_element_present("//button[@type='button']")
        sleep 10
        click("css=div.success")  if is_element_present("css=div.success")
        click "id=popup_ok"  if is_element_present("id=popup_ok")
        click "id=tagDocument"  if is_element_present("id=tagDocument")

        sleep 3
      end
     # if is_element_present("soaPrintingDialog")
      # click("popup_ok", :wait_for => :element, :element => "itemizedRadio") if is_visible("popup_ok")
      sleep 2
      return get_text("successMessages")
    elsif options[:view]
      click("//input[@id='payment' and @type='button' and @value='Go to Payment']")
      sleep 35
      is_element_present("submitForm")
    end
  end
  def wellness_print_soa(options={})
    click("itemizedRadio") if options[:package_gross_soa]
    click("packageNetRadio") if options[:package_net_soa]
    click("perDeptRadio") if options[:soa_by_dept]
    sleep 1
    submit_button = is_element_present("//button[@type='button']") ?  "//button[@type='button']" :  '//input[@type="submit" and @value="Submit" and @name="_submit"]'
    click(submit_button, :wait_for => :page)
    click("popup_ok", :wait_for => :page) if is_element_present("popup_ok")
    is_text_present("Wellness Package Ordering") || is_text_present("Generation of Statement of Account")
  end
  def settle_doctor_pf
    click("settlePf", :wait_for => :page)
    click("cashPaymentMode1")
    sleep 5
    amount = get_value "cashAmountInPhp"
    type("cashBillAmount", amount)
    click("//input[@type='submit' and @value='Proceed with Payment' and @name='save']", :wait_for => :page)
  end
  def add_wellness_package(options={})
    select Locators::Wellness.select_package, "label=#{options[:package]}"
    sleep 5
    if options[:doctor]
      sleep 3
      click "showDoctorFinder"
      type "entity_finder_key", options[:doctor]
      click '//input[@value="Search" and @onclick="DF.search();"]'
      sleep 5
      click "//tbody[@id='finder_table_body']/tr/td[2]/div" if is_element_present "//tbody[@id='finder_table_body']/tr/td[2]/div"
      click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div" if is_element_present "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
      sleep 5
    end
    click(Locators::NursingGeneralUnits.add_package_order, :wait_for => :page)
    sleep 2
    if  (get_selected_label("id=packageOrderCode") == options[:package])
   # if is_element_present(Locators::Wellness.validate) && (get_selected_label("id=packageOrderCode") == options[:package])
      return true
    else
      return get_text("errorMessages")
    end
  end
  def switch_package(options={})
    if options[:wellness]
      click Locators::Wellness.edit_package
      sleep 5
      select("packageOrderCode", options[:to_package])
      if options[:doctor]
        click("showDoctorFinder", :wait_for => :visible, :element => "entity_finder_key")
        self.doctor_finder(options)
      end
      sleep 5
      click(Locators::Wellness.add_to_cart, :wait_for => :page)
      click(Locators::Wellness.validate, :wait_for => :visible, :element => "//input[@value='OK']")
      click("//input[@value='OK']", :wait_for => :page)
    else
      # BELOW PERFORMS PACKAGE MANAGEMENT IN GENERAL UNITS
      if options[:username]
        click Locators::Wellness.order_package, :wait_for => :page
        validate_package
        validate_credentials(options)
      end
      click Locators::Wellness.edit_package
      sleep 5
      if is_element_present Locators::Wellness.switch_link
        click Locators::Wellness.switch_link, :wait_for => :element, :element => Locators::Wellness.other_package_options
      else
        click Locators::Wellness.switch, :wait_for => :element, :element => Locators::Wellness.other_package_options
      end
      click Locators::Wellness.other_package_options
      click Locators::Wellness.save_package
      click Locators::Wellness.switch_validated_item_button, :wait_for => :page if is_element_present Locators::Wellness.switch_validated_item_button
      sleep 10
      if is_visible("orderValidateForm")
        validate_credentials(options)
      end
    end
    is_text_present(options[:to_package])
  end
  def edit_package(options={})
    click Locators::Wellness.order_package, :wait_for => :page
    click Locators::Wellness.edit_package
    sleep 3
    select Locators::Wellness.select_package, "label=#{options[:package]}" if options[:package]
    if options[:doctor]
      click "showDoctorFinder"
      type "entity_finder_key", options[:doctor]
      click "//input[@value='Search']"
      sleep 5
      click "//tbody[@id='finder_table_body']/tr/td[2]/div" if is_element_present "//tbody[@id='finder_table_body']/tr/td[2]/div"
      click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div" if is_element_present "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
      sleep 5
    end
    click Locators::Wellness.order_package, :wait_for => :page
    is_element_present(Locators::Wellness.replace_package) && ((is_text_present(options[:doctors])) || (is_text_present(options[:package])))
  end
  def edit_wellness_package(options={})
    click Locators::Wellness.order_package, :wait_for => :page if is_element_present(Locators::Wellness.order_package)
    click Locators::Wellness.edit_package
    sleep 3
    select Locators::Wellness.select_package, "label=#{options[:package]}" if options[:package]
    if options[:doctor]
      click "showDoctorFinder"
      type "entity_finder_key", options[:doctor]
      click "//input[@value='Search']"
      sleep 5
      click "//tbody[@id='finder_table_body']/tr/td[2]/div" if is_element_present "//tbody[@id='finder_table_body']/tr/td[2]/div"
      click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div" if is_element_present "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
      sleep 5
    end
    click Locators::Wellness.add_to_cart, :wait_for => :page
    if options[:replace]
      click Locators::Wellness.replace_package
      click("//input[@type='button' and @onclick='MultiplePrinters.validate(); return false;' and @value='OK']", :wait_for => :page) if is_element_present("multiplePrinterPopup")
      sleep 10
      is_element_present(Locators::Wellness.go_to_payment) && ((is_text_present(options[:doctors])) || (is_text_present(options[:package])))
    end
  end
  def validate_wellness_package
    #NO VALIDATION BUTTON IN WELLNESS
###    click Locators::Wellness.validate
###    sleep 3
#    if is_visible("orderValidateForm") # no validation in outpatient as per steven.. Nov 3 2011
#      type "validateUsername", "sel_0287_validator"
#      type "validatePassword", "123qweuser"
#      click '//input[@type="button" and @onclick="OrderValidation.validate2();" and @value="Submit"]', :wait_for => :page
#    else
#    sleep 5
######    click("//input[@type='button' and @onclick='MultiplePrinters.validate(); return false;' and @value='OK']") # ,:wait_for => :page) if is_element_present("multiplePrinterPopup")
######    sleep 30
######    is_element_present(Locators::Wellness.go_to_payment)
######    is_element_present(Locators::Wellness.additional_order)
#    end
  end
  def additional_order_package(options={})
    sleep 5
    click Locators::Wellness.additional_order
    is_element_present "outpatientOrderPopup"
    click'//input[@id="find" and @type="button" and @value="Find"]'
    sleep 3
    click'//input[@id="orderType1" and @type="radio" and @name="orderType"]'     if options[:drugs]
    click'//input[@id="orderType2" and @type="radio" and @name="orderType"]'     if options[:supplies]
    click'//input[@id="orderType3" and @type="radio" and @name="orderType"]'     if options[:ancillary]
    click'//input[@id="orderType4" and @type="radio" and @name="orderType"]'     if options[:others]
    type"oif_entity_finder_key",options[:items]
    click'//input[@type="button" and @onclick="OIF._page_counter = 0;OIF.search();" and @value="Search"]'
    sleep 3
    @@item_desc = get_value"itemDesc"
    if options[:drugs]
      select"frequencyCode","ONCE A WEEK"
      type"dose","3"
    end
    click'//input[@type="button" and @onclick="DF.show();" and @name="orderDF" and @value="Find"]'
    sleep 2
    type "entity_finder_key", options[:doctor]
    click "//input[@value='Search']"
    sleep 2
    click('//input[@id="addOrder" and @type="button" and @onclick="preValidateAction(OPSOrder.addOrder2);" and @value="Add"]')
    sleep 3
    is_element_present "ops_order_item_code_0"
    if options[:save]
    click Locators::Wellness.additional_order_save
    sleep 10
    return true if is_text_present @@item_desc
    end
    if options[:close]
    click Locators::Wellness.additional_order_close
    return true if is_text_present"Package Management"
    end
    sleep 5
  end
  def additional_order_package_edit(options={})
    sleep 5
    click Locators::Wellness.additional_order
    is_element_present "outpatientOrderPopup"
    sleep 3
    count = get_css_count("css=#opsOrderTable>tbody>tr")
    if options[:chosen_result]
      count.times do |rows|
        my_row=get_text"css=#ops_order_item_code_#{rows}"
        if my_row == (options[:item])
            stop_row = rows
            click"css=#ops_order_action_#{stop_row}>a"
            sleep 10
        end
      end
    end
    type"quantity", options[:quantity]
    click"editOrder"
    sleep 1
    (get_text"ops_order_quantity_0") == options[:quantity]
    click Locators::Wellness.additional_order_save  if options[:save]
    sleep 10
    click Locators::Wellness.additional_order_close if options[:close]
    return (options[:quantity])
  end
  def additional_order_package_delete(options={})
    sleep 5
    click Locators::Wellness.additional_order
    is_element_present "outpatientOrderPopup"
    sleep 3
    @item = get_text"ops_order_description_0"
    count = get_css_count("css=#opsOrderTable>tbody>tr")
    if options[:chosen_result]
      count.times do |rows|
        my_row = get_text "css=#ops_order_item_code_#{rows}"
        if my_row == (options[:item])
            stop_row = rows
            click "css=#ops_order_chk_#{stop_row}"
            sleep 10
        end
      end
    end
    click"deleteOrder"
    sleep 1
    is_text_present(options[:item]) == false
    click Locators::Wellness.additional_order_save  if options[:save]
    sleep 10
    click Locators::Wellness.additional_order_close if options[:close]
    return true if ((is_text_present @item) == false)
  end
  def gu_switch_package(options={})
    if is_element_present(Locators::Wellness.order_package)
      click Locators::Wellness.order_package, :wait_for => :page
      validate_package
      validate_credentials(options)
      sleep 5
    else
      click Locators::Wellness.edit_package
      sleep 5
    end
    is_text_present(options[:to_package])
  end
  def go_to_payment
    click Locators::Wellness.go_to_payment, :wait_for => :page
    sleep 25
    wait_for(:wait_for => :ajax)
    get_text("//html/body/div/div[2]/div[2]/form/div/div/div/label") == "Patient Information"
  end
  def delete_wellness_package
    click Locators::Wellness.delete, :wait_for => :page
    get_selected_label(Locators::Wellness.select_package) == 'Select Package'
  end
  def click_soa_or_reprint
    click Locators::Wellness.soa_or_reprint_link, :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/div/div/ul/li") == "OR/SOA Reprint"
  end
  def or_soa_search(options={})
    type Locators::Wellness.search_firstname, options[:firstname] if options[:firstname]
    type Locators::Wellness.search_pin, options[:pin] if options[:pin]
  end
  def click_search_or
    click Locators::Wellness.search_or, :wait_for => :page
    is_element_present(Locators::Wellness.reprint_or)
  end
  def click_search_soa
    click Locators::Wellness.search_soa, :wait_for => :page
    is_element_present(Locators::Wellness.reprint_soa)
  end
  def click_reprint_or
    click Locators::Wellness.reprint_or#, :wait_for => :page # timed-out when at oss page.
    sleep 10
    get_text("//html/body/div/div[2]/div[2]/div/div/ul/li") == "OR/SOA Reprint"
  end
  def click_reprint_soa(options={})
    click Locators::Wellness.reprint_soa, :wait_for => :page
    click("itemizedRadio") if options[:package_gross_soa]
    click("packageNetRadio") if options[:package_net_soa]
    click("perDeptRadio") if options[:soa_by_dept]
    sleep 1
    click("//button[@type='button']", :wait_for => :page)
    get_text("//html/body/div/div[2]/div[2]/div/div/ul/li") == "OR/SOA Reprint" #changing validation since locator 'css=div[id="successMessages"]' is no longer available
  end
  def click_view_details
    click Locators::Wellness.view_details, :wait_for => :page
    is_text_present("Document Search › Order Details")
  end
  def click_reprint_request_slip
    click Locators::Wellness.reprint_request_slip, :wait_for => :page
    get_alert()
  end
  def click_patients_for_room_transfer
    click "//a[@id='pendingRtrCount']/span", :wait_for => :element, :element => "pendingRtrPatientSearchKey"
    sleep 3
    is_text_present("LIST OF PATIENTS WITH ROOM TRANSFER REQUEST")
  end
  def search_patient_for_room_transfer(options={})
    self.click_patients_for_room_transfer
    type "pendingRtrPatientSearchKey", options[:pin]
    fire_event "btnPendingRtrSearch", "blur"
    sleep 2
    click "btnPendingRtrSearch"
    sleep 5
    is_text_present(options[:pin])
  end
  def get_room_transfer_search_results
    get_text('css=tbody[id="pendingRtrRows"]')
  end
  def get_room_transfer_count
    sleep 3
    count = get_text("//a[@id='pendingRtrCount']/span").gsub(' Room Transfer Request', '').to_i
    return count
  end
  def get_newborn_admission_count
    sleep 3
    count = get_text("pendingNewborn").gsub(' Newborn for Admission','').to_i
    return count
  end
  def get_patients_for_admission_count
    sleep 1
    count = get_text("pendingAdmQueueCount").gsub(' Inpatient Admission On Queue','').to_i
    return count
  end
  def get_pending_orders_count
    sleep 3
    count = get_text("//div[@id='pendingOrder']/span").to_i
    return count
  end
  def get_inpatient_admission_queue_count
    sleep 1
    count = get_text("pendingAdmQueueCount").gsub(' Inpatient Admission Queue','').to_i
    return count
  end
  def view_newborn_for_admission
    click("css=#pendingNewborn>a", :wait_for => :element, :element => "//div[@id='pendingNewbornDlg']/div[2]/table/tbody/tr/td/a")
  end
  def get_newborn_for_admission_list
    sleep Locators::NursingGeneralUnits.waiting_time
    get_text("//div[@id='pendingNewbornDlg']/div[2]/table/tbody") #get_text('css=table[class="table"] tbody[name="tblBody"]')
  end
  def close_newborn_for_admission
    click "//html/body/div[7]/div[3]/div/button" # click "closePendingAckNewbornPopup"
  end
  def reprint_room_bed(options={})
    click "link=Room/Bed Reprint", :wait_for => :element, :element => "roomBedDateFilter"
    type "roomBedDateFilter", options[:target_date] || Time.now.strftime("%m/%d/%Y")
    click "//html/body/div[11]/div[3]/div/button" #, :wait_for => :page #click "filterReprintAction", :wait_for => :page
    sleep 30
    return false if is_visible("roomBedDateFilter")
    get_text('css=div[id="breadCrumbs"]') == 'Admission  ›  Patient Search'
  end
  def view_print_room_transfer_history(options={})
    click "link=View/Print Room Transfer History", :wait_for => :element, :element => "//img[@alt='...']"
    if options[:date]
      type "transactionDate", options[:date]
    else
      click "//img[@alt='...']"
      sleep 2
      click "link=#{Time.now.day.to_s}"
    end
    sleep 5
    return get_text("css=#viewRoomTransferTransactionHistoryError") if options[:error]
    get_text("roomTransferTransactionHistoryRows")
  end
  def print_room_transfer_transactions(options={})
    sleep 2
    if options[:error]
      click "btnRtthPrint"
      sleep 10
    else
      click "btnRtthPrint", :wait_for => :page
    end
    if is_alert_present
      return(get_alert)
    else
      get_text('css=div[id="breadCrumbs"]') == "Admission  ›  Patient Search"
    end
  end
  def close_room_transfer_transaction
    click "btnRtthClose"
    get_text('css=div[id="breadCrumbs"]') == "Admission  ›  Patient Search"
  end
  def update_room_transfer_action(options={})
    sleep 3
    select "//tbody[@id='pendingRtrRows']/tr/td[12]/select", "label=#{options[:action]}"
    sleep 5
    if options[:action] == "Update Request Status"
      alert = self.update_request_status(options)
      return alert
    elsif options[:action] == "Transfer Room Location"
      alert = self.transfer_room_location(options)
      return alert
    elsif options[:action] == "View Room Transfer History"
      #get_text('css=tbody[id="roomTransferHistoryRows"]')
      get_text("css=#pendingRtrRows")
    end
  end
  def update_request_status(options={})
    select "optRequestStatus", "label=#{options[:request_status]}"
    fire_event 'optSendTo', "blur"
    select "optSendTo", "label=In-House Collection" if options[:in_house]
    select "optSendTo", "label=Division of Nursing" if options[:don]
    type "txtRemarks", "remarks here"
    click "btnRtrOk"
    sleep 20
    return get_alert if is_alert_present
    return true if (is_text_present("Admission") || is_text_present("General Units") || is_text_present("In-House")) #means update request status is successfull from Admission/GU/In-house page
  end
  def transfer_room_location(options={})
    select 'optTransferType', options[:transfer_type] if options[:transfer_type]
    select 'roomChargeCode', options[:room_charge] if options[:room_charge]
    if options[:room_in]
      click "chkRoomingIn"
      sleep 3
      (get_selected_label("roomChargeCode").include? "ROOMING-IN CHARGES:")
    end
    if options[:nursing_unit]
      click "searchNursingUnitBtn", :wait_for => :visible, :element => "osf_entity_finder_key"
      type "osf_entity_finder_key", options[:nursing_unit]
      click("//input[@onclick='OSF.search();' and @value='Search']", :wait_for => :element, :element => "link=#{options[:nursing_unit]}")
      click("link=#{options[:nursing_unit]}")
    end
    if options[:room]
      click "searchRoomBedBtn", :wait_for => :element, :element => "//input[@value='Search' and @type='button' and @onclick='RBF.search();']"
      type "rbf_entity_finder_key", options[:org_code] if options[:org_code]
      type "rbf_room_no_finder_key", "XST"
      click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']"#, :wait_for => :element, :element => "//html/body/div/div[2]/div[2]/div[12]/div[2]/div[2]/div[2]/table/tbody/tr/td/a"
      sleep 3
      click "css=#rbf_finder_table_body>tr>td>a"
      sleep 4
    elsif options[:room_no]
      type "inPatientAdmission.roomBed.roomBed.roomNo", options[:room_no]
      type "inPatientAdmission.roomBed.roomBed.bedNo", options[:bed_no]
    end
   sleep 4
    #click "btnRturlSubmit"
   click'//*[@id="btnRturlSubmit"]' if is_element_present('//*[@id="btnRturlSubmit"]')
    #click("//html/body/div/div[2]/div[2]/div[6]/div[2]/div[8]/input")
    sleep 8
    return get_alert()
#    click 'btnRturlClose' if options[:close]
  end
  ## removed
  def validate_package_of_pin(pin)
    self.nursing_gu_search(:pin =>  pin)
    self.go_to_gu_page_for_a_given_pin("Package Management", pin)
    click "validate"
    type "validateUsername", "gu"
    type "validatePassword", "123qweuser"
    click "//input[@value='Submit']", :wait_for => :page
    is_text_present("Package already validated")
  end
  # Request for Room Transfer
  def request_for_room_transfer(options = {})
    pin = options[:pin]
    remarks = options[:remarks]
    self.nursing_gu_search(:pin =>  pin)
    self.go_to_gu_page_for_a_given_pin("Request for Room Transfer", pin)
    type "txtRemarks", remarks || "Room transfer remarks"
    sleep 8
    if options[:first]
      click "btnRtrOk"
      sleep 20
      return true
    else
      click "btnRtrOk"
      sleep 10
      #2.times{ return(get_alert) if is_alert_present }  #error si Bug#22079 kapag enabled to
      return(get_alert) if is_alert_present
    end
  end
  def get_current_room_bed(pin)
    admission_search(:pin =>  pin)
    click "link=Update Admission", :wait_for => :page
    get_value("roomNo")
  end
  def get_room_and_bed_no_in_gu_page
#    a = get_text("css=#occupancyList>tbody>tr>td:nth-child(2)")
#    room_and_bed = a.split('-')
#    room_and_bed.each do |s|
#      s.strip!
#    end
      if is_element_present("css=#occupancyList>tbody>tr>td:nth-child(2)")
                    room_and_bed = get_text("css=#occupancyList>tbody>tr>td:nth-child(2)").gsub(' ','').split('-')
      else    room_and_bed = get_text("//html/body/div/div[2]/div[2]/table/tbody/tr/td[2]").gsub(' ','').split('-')
      end
    return room_and_bed
  end
  def er_get_room_and_bed_no_in_gu_page
    a = get_text("css=#occupancyList>tbody>tr>td")
    room_and_bed = a.split('-')
    room_and_bed.each do |s|
      s.strip!
    end
    return room_and_bed
  end
  def get_room_and_bed_no_in_er_page
    a = get_text("css=#occupancyList>tbody>tr>td:nth-child(1)")
    room_and_bed = a.split('-')
    room_and_bed.each do |s|
      s.strip!
    end
    return room_and_bed
  end
  def validate_incomplete_orders(options={})
    if options[:inpatient]
      nursing_gu_search(:pin => options[:pin])
      go_to_gu_page_for_a_given_pin("Order Page", options[:pin])

      count_drugs = get_css_count("css=#cart>div:nth-child(2)>div.item").to_i
      count_supplies = get_css_count("css=#cart>div:nth-child(4)>div.item").to_i
      count_ancillary = get_css_count("css=#cart>div:nth-child(6)>div.item").to_i
      count_others = get_css_count("css=#cart>div:nth-child(8)>div.item").to_i
      count_oxygen = get_css_count("css=#cart>div:nth-child(10)>div.item").to_i
      count_special = get_css_count("css=#cart>div:nth-child(12)>div.item").to_i

      if count_drugs != 0 || count_supplies != 0 || count_ancillary != 0 || count_others != 0 || count_oxygen != 0 || count_special != 0
        submit_added_order(options)
        validate_orders(options)
        confirm_validation_all_items
      end

    elsif options[:outpatient]
      go_to_occupancy_list_page
      patient_pin_search(:pin => options[:pin])
      go_to_su_page_for_a_given_pin("Order Page", options[:pin])

      count_drugs = get_css_count("css=#cart>div:nth-child(2)>div.item").to_i
      count_supplies = get_css_count("css=#cart>div:nth-child(4)>div.item").to_i
      count_ancillary = get_css_count("css=#cart>div:nth-child(6)>div.item").to_i
      count_others = get_css_count("css=#cart>div:nth-child(8)>div.item").to_i
      count_oxygen = get_css_count("css=#cart>div:nth-child(10)>div.item").to_i
      count_special = get_css_count("css=#cart>div:nth-child(12)>div.item").to_i

      if count_drugs != 0 || count_supplies != 0 || count_ancillary != 0 || count_others != 0 || count_oxygen != 0 || count_special != 0
        er_submit_added_order(options)
        validate_orders(options)
        confirm_validation_all_items
      end

    end
  end
  def wellness_get_total_gross_of_items_in_package(options={})
    count = get_css_count("css=#tableRows>tr")
    price = 0
    if options[:unit_price]
      count.times do |x|
        price = price + get_text("css=#ops_order_unit_price_#{x}").gsub(',', '').to_f
        x += 1 if (x + 1) != count
      end
    elsif options[:amount]
      count.times do |x|
        price = price + get_text("css=#ops_order_amount_#{x}").gsub(',', '').to_f
        x += 1 if (x + 1) != count
      end
    elsif options[:discount]
      count.times do |x|
        price = price + get_text("css=#ops_order_promo_discount_#{x}").gsub(',', '').to_f
        x += 1 if (x + 1) != count
      end
    elsif options[:net_amount]
      count.times do |x|
        price = price + get_text("css=#ops_order_net_amount_#{x}").gsub(',', '').to_f
        x += 1 if (x + 1) != count
      end
    end
    return price
  end
  def notice_of_death(options={})
    d = Time.new
    set_hour1 = (d.strftime("%H").to_i).to_s
    set_hour1 = "0" + set_hour1 if set_hour1.length == 1
    set_minute1 = (d.strftime("%M").to_i) - 35 if ((d.strftime("%M").to_i) - 35) > 0
    set_minute1 = (d.strftime("%M").to_i) if set_minute1 == nil
    set_day1 = "#{set_hour1}:#{set_minute1}"
    set_date1 = ((Date.strptime(Time.now.strftime('%Y-%m-%d')) - 2).strftime("%m/%d/%Y").upcase).to_s

    set_hour2 = (d.strftime("%H").to_i).to_s
    set_hour2 = "0" + set_hour2 if set_hour2.length == 1
    set_minute2 = (d.strftime("%M").to_i) - 25
    set_day2 = "#{set_hour2}:#{set_minute2}"

    sleep 5
    # For Bug 50082
    type("notifiedDate", Time.now.strftime("%m/%d/%Y"))
    type("schedDate", set_date1)
    type("scheduleTimeStr", set_day1)
    type 'immediateCDeath','Immediate Cause Of Death'
    click 'notifiedByDoctor', :wait_for => :element, :element => "ddf_entity_finder_key"
    sleep 2
    type 'ddf_entity_finder_key', options[:doctor] || '0126'
    click("//input[@type='button' and @onclick='DDF.search();']")
    sleep 5
    click("//tbody[@id='ddf_finder_table_body']/tr/td/div")
    sleep 5
    type("notifiedTimeStr", set_day2)
    sleep 5
    click '//input[@type="button" and @onclick="submitForm(this);" and @value="Save"]', :wait_for => :page if options[:save]
    sleep 5
    message = get_text("successMessages")
    click("//input[@type='button' and @onclick='submitForm(this);' and @value='Close']", :wait_for => :page) if options[:close]
    click("//input[@type='button' and @onclick='submitForm(this);' and @value='Edit']", :wait_for => :page) if options[:edit]
    click("//input[@type='button' and @onclick='submitForm(this);' and @value='Send']", :wait_for => :page) if options[:send]
    click("//input[@type='button' and @onclick='submitForm(this);' and @value='Print']", :wait_for => :page) if options[:print]
    return message
  end
  def ancillary_su_payment(options={})
    if options[:cash]
              click("paymentToggle")
              sleep 5
              click("opsPaymentBean.cashPaymentMode") #hospital bills payment
              sleep 5
              amount = options[:amount] || get_value("cashAmountInPhp").gsub(',','')
              type("cashBillAmount", amount)
              sleep 3
              click("pfPaymentToggle", :wait_for => :visible, :element => "pfPaymentSection")
              sleep 3
              pf_amount = options[:pf_amount] || get_text("css=#pfPaymentSection>#paymentDataEntry>div>div:nth-child(2)>fieldset>div>div:nth-child(9)>.value").gsub(',','')
              if pf_amount != "0.00"
                click("opsPfPaymentBean.cashPaymentMode", :wait_for => :visible, :element => "opsPfPaymentBean.pbaCashPaymentBean.billAmount")
                sleep 2
                type("opsPfPaymentBean.pbaCashPaymentBean.billAmount", pf_amount)
              end
              click("//input[@id='submitForm' and @type='submit' and @value='Submit']") if is_element_present("//input[@id='submitForm' and @type='submit' and @value='Submit']")
              sleep 5
              click "id=submitForm" if is_element_present"id=submitForm" 
              get_confirmation if is_confirmation_present
              sleep 10
              click "//input[@value='OK']"
              #click("//html/body/div[4]/div[3]/div/button") if is_element_present("soaPrintingDialog")
              #click ("//html/body/div[4]/div[3]/div/button"),  :wait_for => :element, :element => "//body/div[4]/div"
        #      if is_element_present("//html/body/div/div[2]/div[2]/form[2]/div/div[3]/input")
        #            if get_text("//html/body/div/div[2]/div[2]/form[2]/div/div[3]/input") == "OK"
        #                    click("//html/body/div/div[2]/div[2]/form[2]/div/div[3]/input")
        #            end
        #      end
             sleep 20
             click("popup_ok")  if is_element_present( "popup_ok")
             sleep 4
             click "id=submitDASOSS" if is_element_present( "id=submitDASOSS")
             sleep 4
             click "id=tagDocument" if is_element_present( "id=tagDocument")
             sleep 4
             #click "css=div.success" if is_element_present( "css=div.success")
             return get_text("successMessages")
    end
  end
  def cm_request(options={})
        sleep 3
        cm_search_order options
        click "id=C" if options[:cmrn]
        click "id=T" if options[:turn_in]
        sleep 3
        type "id=orderBeans1.returnedQty", options[:qty] || "1"
        sleep 3
        reason = options[:reason]  || "ADJUSTMENT - WRONG ENCODING OF QUANTITY"
        sleep 3
        select "id=orderBeans1.reasonCode", "label=#{reason}"
        sleep 3
        type "id=orderBeans1.remark", "selenium test"
        sleep 3
        click "name=Save" if options[:save]
        click "name=Confirm"  if options[:confirm]
        click "name=Clear"  if options[:clear]
        sleep 3
        if options[:confirm]
                sleep 6
                username = options[:username] || "sel_pharmacy1"
                password = options[:password] || "123qweuser"
                username = "sel_0287_validator" if (CONFIG['location'] == 'QC' && options[:username] == "sel_0287_validator")
                sleep 5
                type("id=pharmUsername", username)
                type("id=pharmPassword", password)
                click("id=sendRequestOK")
                sleep 10
        end

        sleep 6
        if options[:save]
            result = is_text_present("CM Requests successfully posted.")
        end
        if options[:confirm]
           result = is_text_present("CM Requests successfully posted.") || is_text_present("Order Adjustment and Cancellation Request")
        end

        if options[:clear]
               if is_editable("id=orderBeans1.returnedQty") == false  && is_editable("id=orderBeans1.remark") == false && is_editable("id=orderBeans1.remark") == false
                 result = true
               end
        end
        sleep 3
return result
#/html/body/div[1]/div[2]/div[2]/div[5]/form/table/tbody/tr[1]/td[1]/input[1]
#/html/body/div[1]/div[2]/div[2]/div[5]/form/table/tbody/tr[1]/td[1]/input[2]
#
#
#/html/body/div[1]/div[2]/div[2]/div[5]/form/table/tbody/tr[2]/td[1]/input[1]
#/html/body/div[1]/div[2]/div[2]/div[5]/form/table/tbody/tr[2]/td[1]/input[2]
#
#/html/body/div[1]/div[2]/div[2]/div[5]/form/table/tbody/tr/td[1]/input[1]
#/html/body/div[1]/div[2]/div[2]/div[5]/form/table/tbody/tr/td[1]/input[2]
#
#
#/html/body/div[1]/div[2]/div[2]/div[5]/form/table/tbody/tr/td[1]/input[1]
#/html/body/div[1]/div[2]/div[2]/div[5]/form/table/tbody/tr/td[1]/input[2]



  end
  def cm_request_list(options={})
        click "css=a[title=\"ACTIVE\"] > span" if options[:active]
        click "css=a.tablink > span" if options[:sent]
        click "//ul[@id='statusTab']/li[3]/a/span" if options[:approved]
        click "css=li.tabberactive > a.tablink > span" if options[:rejected]
        click "css=a[title=\"DRUG\"] > span" if options[:drugs]
        click "//ul[@id='orderTypeTab']/li[2]/a/span" if options[:supplies]
        click "//ul[@id='orderTypeTab']/li[3]/a/span" if options[:ancillary]
        click "//ul[@id='orderTypeTab']/li[4]/a/span" if options[:others]
        click "//ul[@id='orderTypeTab']/li[5]/a/span" if options[:special]
        sleep 3
        click "id=tabValidateButton" if options[:send]
        click "id=tabEditButton" if options[:edit]
        click "id=tabCancelButton" if options[:delete]
        verify = options[:verify]
        result = is_text_present("#{verify}")
        return  result

  end
end