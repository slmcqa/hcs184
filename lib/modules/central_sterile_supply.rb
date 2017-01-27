#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/locators'

module CentralSterileSupply
  include Locators::NursingGeneralUnits
  include Locators::Admission

  # attr_accessor :ci

  def search_patient(options ={})
    # input pin or ln
    type "q", options[:pin] || options[:lastname]
    # select patient type
    select "type", "label=In-Patient" if options[:i]
    select "type", "label=Out-Patient" if options[:o]
    # input CI date
    type "ciDateFrom", options[:date_fr] if options[:date_fr]
    type "ciDateTo", options[:date_to] if options[:date_to]
    # hit search button
    click "search", :wait_for => :page
  end
  def get_ci_number
    if is_element_present("//table[@id='searchResults']/tbody/tr/td[1]")
      get_text("//table[@id='searchResults']/tbody/tr/td[1]")
    else
      get_text('css=table[id="results"] tbody tr[class="even"] td:nth-child(9)')
    end
  end
  def view_compounded_request(ci)
    click "display", :wait_for => :page
    (get_value("//html/body/div/div[2]/div[2]/div[6]/div[2]/input") == ci) && (is_text_present "Formula Detail")
  end
  def create_compounded_formula(options ={})
    if options[:add]
      click'//input[@id="compoundedFind"]' #jmerelos v1.4
      sleep 2
      type "cif_entity_finder_key", options[:item]
      click "//input[@value='Search']", :wait_for => :element, :element => "//tbody[@id='cif_finder_table_body']/tr/td[2]/div"
      sleep 2
      click "//tbody[@id='cif_finder_table_body']/tr/td[2]/div"
      sleep 2
      type "serviceRate", options[:cd_price]
      type "remarks", options[:remarks] || "Remarks here"
      click "add"
      checkpoint = is_text_present(options[:item])
    elsif options[:delete]
      return false if is_text_present(options[:item]) != true
      count = get_css_count("css=#formulaTable>tbody>tr")
      count.times do |rows|
        my_row = get_text("//table[@id='formulaTable']/tbody[@id='tableRows']/tr[#{rows + 1}]/td[2]")
        if my_row == options[:item]
          stop_row = rows
          click("//table[@id='formulaTable']/tbody[@id='tableRows']/tr[#{stop_row + 1}]/td[1]/input[@type='checkbox']")
          break
        end
      end
      click "delete"
      get_confirmation()
      choose_ok_on_next_confirmation()
      sleep 3
      checkpoint = !is_text_present(options[:item])
    elsif options[:edit]
      click "link=Edit"
      type "qty", options[:quantity]
      type "serviceRate", options[:cd_price]
      type "remarks", options[:remarks] || "Remarks here"
      click "edit"
      checkpoint = get_text('//*[@id="compounded-actual-qty-0"]') == options[:quantity] && get_text(//*[@id="compounded-actual-uprice-0"]) == options[:cd_price]
    end
    sleep 3
    click("save", :wait_for => :element, :element => "//input[@value='Yes' and @onclick='CompoundedOrder.yes();']") if options[:save]
    sleep 3
    click("//input[@value='Yes' and @onclick='CompoundedOrder.yes();']") if options[:save]
    sleep 10
    return (is_text_present "View Compounded Orders") || get_text("display") == "Create" && checkpoint
  end
  def search_order_adjustment_cancellation(options={})
    type("lastname", options[:pin]) if options[:pin]
    type "startOrderDate", options[:start_date] if options[:start_date] || Time.now.strftime("%m/%d/%Y")
    type "endOrderDate", options[:end_date] if options[:end_date] || Time.now.strftime("%m/%d/%Y")
    if options[:org_code]
      click "//input[@type='button' and @onclick='OSF.show();']", :wait_for => :element, :element => "osf_entity_finder_key"
      type "osf_entity_finder_key", options[:org_code]
      click "//input[@value='Search']"
      sleep 3
      click "link=#{options[:org_code]}"
    end
    click("specialSearch") if options[:special_search]
    click("batchOrderSearch") if options[:posted_batch_request]
    select "docNumType", options[:doc_type] if options[:doc_type]
    select "patientType", options[:patient_type] if options[:patient_type]
    sleep 4
    type "ciNumber", options[:ci] if options[:ci]
    click "search", :wait_for => :page
    get_text('css=table[id="results"]')
  end
  def click_adjust(ci)
    click "link=Adjust", :wait_for => :page
    get_text("//html/body/div/div[2]/div[2]/form/div/div/h2") == "CI Number: #{ci}"
  end
  def reprint_cancellation_prooflist(ci)
    click "btnPrintProoflist-#{ci}"
    sleep 3
  end
  def order_adjustment(options={})
    # edit order
    if options[:edit]
      locator = options[:edit_locator] || "link=Edit"
      click "#{locator}", :wait_for => :element, :element => "//input[@value='Proceed']"
      click "//input[@value='Proceed']"
      sleep 3
      item_code = get_value("txtItemCodeDisplay")
      if options[:doctor]
        click "btnRequestingDoctorLookup"
        type "entity_finder_key", options[:doctor]
        click "//input[@value='Search']"
        sleep 5
        click "//html/body/div/div[2]/div[2]/div[5]/div[2]/div[2]/table/tbody/tr/td/div", :wait_for => :page
      end
      type "txtQuantity", options[:new_quantity]
      select "cboAdjustmentReason", "label=#{options[:reason]}"
      type "txtRemarks", options[:remarks] || "Remarks Here"
      sleep 2
      click "btnUpdate", :wait_for => :element, :element => "link=Remove"
      get_text('//*[@id="txtRequestingDoctorName"]') == get_text("//html/body/div/div[2]/div[2]/form/div/div[5]/div[2]/table/tbody/tr/td[6]") if options[:doctor]
      checkpoint = is_element_present("link=Remove") && get_text("//html/body/div/div[2]/div[2]/form/div/div[5]/div[2]/table/tbody/tr/td") == item_code

    elsif options[:supplies] && options[:cancel]
      click options[:cancel_locator] || "css=#results>tbody>tr>td:nth-child(5)>div:nth-child(2)>a"
      sleep 2
      cancel_button = is_element_present( "css=#verifyDetailCancel_div>center>div:nth-child(2)>input:nth-child(5)") ?  "css=#verifyDetailCancel_div>center>div:nth-child(2)>input:nth-child(5)" :  "css=#verifyOrderCancel_div>center>div:nth-child(2)>input:nth-child(4)"
      click cancel_button
      sleep 3
      reason = options[:reason] || "CANCELLATION - EXPIRED"
      select("reason", "label=#{reason}")
      remarks = options[:remarks] || "remarks here"
      type("remarks", remarks)
      click "btnOK", :wait_for => :page
      click "popup_ok" if is_element_present("popup_ok")
      click "tagDocument", :wait_for => :page if is_element_present("tagDocument")
      is_text_present("Order Adjustment and Cancellation")
      return false if is_element_present("errorMessages")
      return true if is_element_present("successMessages")
      
    elsif options[:cancel]
      click options[:cancel_locator] || "//html/body/div/div[2]/div[2]/form/div/div[2]/table/tbody/tr/td[5]/div/a"
      sleep 2
      cancel_button = is_element_present( "css=#verifyDetailCancel_div>center>div:nth-child(2)>input:nth-child(5)") ?  "css=#verifyDetailCancel_div>center>div:nth-child(2)>input:nth-child(5)" :  "css=#verifyOrderCancel_div>center>div:nth-child(2)>input:nth-child(4)"
      click cancel_button
      sleep 3
      reason = options[:reason] || "CANCELLATION - EXPIRED"
      select("reason", "label=#{reason}")
      remarks = options[:remarks] || "remarks here"
      type("remarks", remarks)
      click "btnOK"#, :wait_for => :page # not applicable for next pop up
      sleep 10
      click "popup_ok" if is_element_present("popup_ok")
      click "tagDocument", :wait_for => :page if is_element_present("tagDocument")
      if is_visible("errorMessages")
        checkpoint = get_text("breadCrumbs") == "Order Adjustment and Cancellation › Adjustment"
      else
        checkpoint = get_text("breadCrumbs") == "Order Adjustment and Cancellation"
      end

      # replace order
    elsif options[:replace]
      count = get_css_count("css=#row>tbody>tr")
      count.times do |rows|
        my_row = get_text("//table[@id='row']/tbody/tr[#{rows + 1}]/td[1]")
        if my_row == options[:item_to_be_replaced]
          stop_row = rows
          click("//table[@id='row']/tbody/tr[#{stop_row + 1}]/td[5]/div[3]/a")
          break
       end
      end
      sleep 1
      proceed = "//input[@value='Proceed' and @type='button' and @onclick=\"orderDetailReplacement($('detailReplacementVisitNo').value,$('detailReplacementGroupNumber').value,$('detailReplacementDetailNumber').value, $('selectedRow').value);OrderAdjustment.close('verifyDetailReplacement_div');\"]"
      return false if (is_visible(proceed) != true)
      click(proceed)
      sleep 1
      click "btnItemLookup"
      type "oif_entity_finder_key", options[:item]
      click "//input[@value='Search' and @type='button' and @onclick='OIF._page_counter = 0;OIF.search();']", :wait_for => :element, :element => "link=#{options[:item]}"
      click "link=#{options[:item]}", :wait_for => :not_visible, :element => "link=#{options[:item]}"
      type "txtQuantity", options[:quantity] if options[:quantity]
      if options[:doctor]
        click("btnRequestingDoctorLookup", :wait_for => :visible, :element => "entity_finder_key")
        type("entity_finder_key", options[:doctor])
        click("//input[@onclick='DF.search();' and@ value='Search']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr/td/div")
        click("//tbody[@id='finder_table_body']/tr/td/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr/td/div")
      end
      select "cboAdjustmentReason", options[:reason]
      type "txtRemarks", options[:remarks] || "Remarks here"
      click "btnUpdate"
      return get_alert if is_alert_present
      wait_for(:wait_for => :element, :element => "link=Remove")
      checkpoint = get_text("//html/body/div/div[2]/div[2]/form/div/div[6]/div[2]/table/tbody/tr/td[5]") == options[:item]
      checkpoint = (get_text("//table[@id='tblReplacement']/tbody/tr/td[4]") == options[:item]) if checkpoint == false
    end
    return checkpoint
  end
  def order_cancellation(options={})
    click "//html/body/div/div[2]/div[2]/div[9]/div[2]/table/tbody/tr/td[5]/div[2]/a", :wait_for => :element, :element => "//html/body/div/div[2]/div[2]/div[10]/center/div[2]/input[4]"
    click "//html/body/div/div[2]/div[2]/div[10]/center/div[2]/input[4]"
    select "reason", "label=#{options[:reason]}"
    type "remarks", "Cancelling this order" || options[:remarks] if options[:remarks]
    click "btnOK", :wait_for => :page
    # is_text_present "Order/s with CI No. #{options[:ci]} has been cancelled."
    get_text "//div[@id='errorMessages']/div" if options[:compounded]
  end
  def tag_document
        sleep 10
    click "id=popup_content" if is_element_present("id=popup_content")
    sleep 10
    click "popup_ok" if is_element_present("popup_ok")
    sleep 3
    click "tagDocument", :wait_for => :page if is_element_present("tagDocument")
    sleep 5
    return get_text("css=div[id='successMessages']") if is_element_present("css=div[id='successMessages']")
  end
  def click_clinical_ordering_sub_org(options={})
    sleep 2
    while is_element_present("btnOK") && is_visible("btnOK")
      click("btnOK") if is_element_present("btnOK")
    end
    sleep 5
    click("chk_sub_1") if options[:sub_org2] == true
    click("chk_sub_0") if options[:sub_org1] == true
    wait_for_page_to_load "3000" if options[:sub_org2] && options[:sub_org1]
  end
  def clinical_ordering_checkbox(options={})
    @count = get_css_count("css=#tbl_#{options[:pin]}>tbody>tr")
    @count = @count - 1
    @count.times do |rows|
      my_row = get_text("css=#tbl_#{options[:pin]}>tbody>tr:nth-child(#{rows + 1})>td:nth-child(3)")
      if my_row == options[:item_code]
        stop_row = rows
        click("css=#tbl_#{options[:pin]}>tbody>tr:nth-child(#{stop_row + 1})>td>input")
      end
    end

    if options[:reject]
      click '//input[@type="button" and @value="Reject"]', :wait_for => :element, :element => "rejectOrderDialog"
      select 'reason', options[:reason]
      click '//input[@type="submit" and @value="OK"]', :wait_for => :page
      medical_search_patient options[:pin]
      sleep 1
      (get_text("css=#tbl_#{options[:pin]}>tbody").include?options[:item_code]) == false
    elsif options[:validate]
      click '//input[@type="button" and @value="Validate"]', :wait_for => :page
      is_text_present("has been validated successfully.")
    end
  end


end
