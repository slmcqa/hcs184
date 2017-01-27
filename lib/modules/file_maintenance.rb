#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/locators'

module FileMaintenance

  def doctor_search(options={})
    sleep 2
    department = options[:department] || ""
    position = options[:position] || ""
    specialization = options[:specialization] || ""
    type "criteria", options[:pin]
    select "//select[@name='department']", department
    select "//select[@name='position']", position
    select "//select[@name='specialization']", specialization
    sleep 2
    click "//input[@value='Search' and @name='search']", :wait_for => :page
    return false if !is_element_present("css=#results>tbody>tr>td>a")
    if options[:pin]
      return true if get_text("css=#results>tbody>tr>td>a") == options[:pin]
    else
      return true if is_element_present("css=#results>tbody>tr>td>a")
    end
  end
  def fm_nursing_unit_search(nursing_unit)
    type "txtNuQuery", nursing_unit
    click "btnNuFindSearch"
    sleep 3
    click "css=#nuFindResults>tr>td>div"
    sleep 1
  end
  def fm_room_charge_search(room_charge)
    type "txtRchQuery", room_charge
    click "btnRchFindSearch"
    sleep 3
    click "css=#rchFindResults>tr>td>div"
    sleep 1
  end
  def fm_room_location_search(room_status)
    type "txtRbsQuery", room_status
    click "btnRbsFindSearch"
    sleep 3
    click "css=#rbsFindResults>tr>td>div"
    sleep 1
  end
  def add_doctor(options ={})
    click "add", :wait_for => :visible, :element => "fancybox-inner"
    type "popupEntry_lastname", options[:last_name] + "ly"
    click 'popupEntry_gender' if options[:gender] == "M"
    click "//input[@id='popupEntry_gender' and @name='genderGroup' and @value='F']" if options[:gender] == "F"
    type "popupEntry_prcLicense", AdmissionHelper.range_rand(100001,999999).to_s
    click "btn_search", :wait_for => :page
    sleep 3
    type "doctor.doctorCode", options[:doc_code]
    type "doctor.name.firstName", options[:first_name]
    type "doctor.name.middleName", options[:middle_name]
    type "birthDate", options[:birth_day]
    select "doctor.doctorMedStatus", "label=ACTIVE UNIT" if options[:doctor_status]
    select "doctor.doctorPosition", "label=UNIT DOCTOR" if options[:doctor_position]
    sleep 2
    type "expiryDate", "09/26/2019"
    click "//input[@value='Add']"
    sleep 3
    click "//form[@id='doctorDataEntryBean']/div/div[5]/div[1]/h3/a"
    select "major", "label=ALLERGOLOGY IMMUNOLOGY"
    sleep 3
    click "//input[@value='Add' and @type='button' and @onclick='addRow()']"
    sleep 5
    if options[:add]
      click("saveButton", :wait_for => :page)
      sleep 2
      return get_text "css=div[id='successMessages']"
    end
  end
  def edit_doctor(options={})
    medical_status = options[:medical_status] || ""
    position = options[:position] || ""
    count = get_css_count("css=#results>tbody>tr>td>a")
    count.times do |rows|
      my_row = get_text("css=#results>tbody>tr:nth-child(#{rows + 1})>td>a")
      if my_row == options[:doctor_code]
        stop_row = rows
        click("css=#results>tbody>tr:nth-child(#{stop_row + 1})>td>a", :wait_for => :element, :element => "DoctorInfoForm")
        break
      end
    end
    click "//input[@value='Edit']", :wait_for => :page
    type "presentAddress.address", Admission.generate_data[:address]
    select "doctor.doctorMedStatus", medical_status
    select "doctor.doctorPosition", position
    if options[:edit]
      click "//input[@value='Save' and @name='saveButton']", :wait_for => :page
      is_text_present("Doctor is saved successfully.")
    elsif options[:delete]
      choose_ok_on_next_confirmation
      click "//input[@value='Delete' and @name='delete']", :wait_for => :page
      get_confirmation if is_confirmation_present
      is_text_present("Doctor is deleted successfully.")
    end
  end
  def room_and_board_view(options={})
    click "link=Room-Bed", :wait_for => :page if options[:room_bed]
    click "link=Room Charging", :wait_for => :page if options[:room_charging]
    click "link=Room-Bed Status", :wait_for => :page if options[:room_bed_status]
    click "link=Room Class", :wait_for => :page if options[:room_class]

    return is_element_present("btnRbdNew") if options[:room_bed]
    return is_element_present("btnRchNew") if options[:room_charging]
    return is_element_present("btnRbsNew") if options[:room_bed_status]
    return is_element_present("btnRclNew") if options[:room_class]
  end
  def room_and_board_search(options={})
    if options[:room_bed]
      nursing_unit = options[:nursing_unit] || ""
      room_charge = options[:room_charge] || ""
      room_status = options[:room_status] || ""
      click "aOrgUnitFind", :wait_for => :element, :element => "divNuFindPopupContent"
      self.fm_nursing_unit_search(nursing_unit)

      click "aRoomChargeFind", :wait_for => :element, :element => "divRchFindPopupContent"
      self.fm_room_charge_search(room_charge)

      click "aRoomStatusFind", :wait_for => :element, :element => "divRbsFindPopupContent"
      self.fm_room_location_search(room_status)

      click "optIncFilterOnly" if options[:temporary]
      click "optIncFilterAll" if options[:all]
      click "//input[@type='submit' and @value='Search']", :wait_for => :page
      is_element_present("btnRbdNew")
    elsif options[:room_charge]
      type "txtQuery", options[:description] if options[:description]
      select "selStatus", options[:status] if options[:status]
      type "txtRateLow", options[:rate_low] if options[:rate_low]
      type "txtRateHigh", options[:rate_high] if options[:rate_high]
      if options[:room_class]
        click "aRoomClassFind", :wait_for => :element, :element => "divRclFindPopupContent"
        type "txtRclQuery", options[:room_class]
        click "btnRclFindSearch"
        sleep 3
        click "css#rclFindResults>tr>td>div"
        sleep 1
      end
      click "optIncFilterTmp" if options[:half_rate]
      click "optIncFilterAll" if options[:all]
      click "//input[@type='submit' and @value='Search']", :wait_for => :page
      is_element_present("btnRchNew")
    elsif options[:room_bed_status]
      type "txtQuery", options[:description] if options[:description]
      select "selStatus", options[:status] if options[:status]
      click "//input[@type='submit' and @value='Search']", :wait_for => :page
      is_element_present("btnRbsNew")
    elsif options[:room_class]
      type "txtQuery", options[:description] if options[:description]
      select "selStatus", options[:status] if options[:status]
      click "//input[@type='submit' and @value='Search']", :wait_for => :page
      is_element_present("btnRclNew")
    end
  end
  def room_and_board_add(options={})
    if options[:room_charge]
      click "btnRchNew", :wait_for => :element, :element => "txtRchCode"
      type "txtRchCode", options[:rch_code] if options[:rch_code]
      type "txtRchDesc", options[:description] if options[:description]
      select "selRchStat", options[:status] if options[:status]
      type "txtRchRate", options[:rate].to_i if options[:rate]
      if options[:room_class]
        click "aRoomClassFind", :wait_for => :element, :element => "divRclFindPopupContent"
        type "txtRclQuery", options[:room_class]
        click "btnRclFindSearch"
        sleep 3
        click "css#rclFindResults>tr>td>div"
        sleep 2
      end
      click "//button[@type='button']", :wait_for => :page if options[:cancel]
      click "//button[2][@type='button']", :wait_for => :page if options[:save]
    end
  end
  def add_reference_service(options={})
    click("btnRsvcAdd", :wait_for => :visible, :element => "frmRsvc")
    select("selRsvcStat", options[:status]) if options[:status]
    click("chkRsvcInvType") if options[:inventory_item]
    type("txtRsvcMatCode", options[:material_code]) if options[:material_code]
    type("txtRsvcExtCode", options[:external_code]) if options[:external_code]
    if options[:master_service]
      click("btnRsvcMsvcFind", :wait_for => :visible, :element => "txtMsvcQuery")
      type("txtMsvcQuery", options[:master_service])
      click("btnMsvcFindSearch")
      sleep 5
      click("tdMsvcDesc-0")
      sleep 3
    end
    if options[:location]
      click("btnRsvcDeptFind", :wait_for => :visible, :element => "txtNuQuery")
      self.fm_nursing_unit_search(options[:location])
    end
  end
  def add_service_rate(options={})
    click("btnSvcRateAdd", :wait_for => :visible, :element => "txtSvcRateCode")
    type("txtSvcRateCode", options[:code]) #0004B060003476RCL03
    select("selSvcRateStat", options[:status])
    type("txtSvcRateRate", options[:rate])
    type("txtSvcRateMaxRetail", options[:max_retail_price]) if options[:max_retail_price]
    click("chkSvcRateMrpTag") if options[:mrp]
    type("txtSvcRateAdmCost", options[:admin_cost])
    type("txtSvcRateReadFee", options[:readers_fee])
    days_to_adjust = 365
    d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
    valid_from = ((d - days_to_adjust).strftime("%m/%d/%Y").upcase).to_s
    type("txtSvcRateValidFrom", valid_from)
    days_to_adjust = -365
    d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
    valid_to = ((d - days_to_adjust).strftime("%m/%d/%Y").upcase).to_s
    type("txtSvcRateValidTo", valid_to)
    if options[:ref_service]
      click("btnSvcRateRefSvcFind", :wait_for => :visible, :element => "txtRsvcQuery")
      sleep 3
      type("txtRsvcQuery", options[:ref_service])
      click("btnRsvcFindSearch")
      sleep 5
      click("tdRsvcDesc-0")
    end
    select("selSvcRateRoomClass", options[:room_class]) if options[:room_class]
    sleep 5
    click("btnSvcRateOk", :wait_for => :page) if options[:save]
    is_element_present("txtQuery")
  end
  def find_service(options={})
    type "txtQuery", options[:service]
    click "//input[@type='submit' and @value='Search']", :wait_for => :page
    is_text_present(options[:service])
  end
  def add_new_service(options={})
    code = options[:code] || 0.to_s + AdmissionHelper.range_rand(100000,999999).to_s
    desc = options[:desc] || "Selenium Item"
    order_type = options[:order_type] || "ORT02"
    service_category = options[:sct] || "SCT03"
    nursing_unit = options[:nursing_unit] || "0004"
    click("btnSvcfNew")
    sleep 3
    select("selSvcfDept", "Pharmacy (04)")
    type("txtSvcfCode", code)
    type("txtSvcfDesc", desc)
    click("//a[@id='aSvcfType']/img", :wait_for => :element, :element => "txtNliQuery")
    type("txtNliQuery", order_type)
    click("btnNliFindSearch")
    sleep 3
    click("css=#nliFindResults>tr>td>div")
    sleep 1

    click("//a[@id='aSvcfSCat']/img", :wait_for => :element, :element => "txtNliQuery")
    type("txtNliQuery", service_category)
    click("btnNliFindSearch")
    sleep 3
    click("css=#nliFindResults>tr>td>div")
    sleep 1

    click("//a[@id='aSvcfDept']/img", :wait_for => :element, :element => "txtNuQuery")
    type("txtNuQuery", nursing_unit)
    click("btnNuFindSearch")
    sleep 3
    click("css=#nuFindResults>tr>td>div")
    sleep 1

    click("aSvcfDeptsAdd")
    sleep 5
    click("btnNumsLeftAll")
    sleep 1
    add_selection("lstNumsOrgUnitsLeft", "PHARMACY")
    click("btnNumsRight")
    click("btnNumsOk")
    select("selSvcfDept", "Pharmacy (04)")
    type("txtSvcfCode", code)
    type("txtSvcfDesc", desc)

    sleep 5
    click("aSvcfDeptPriceSuite-0004")
    type("txtSvcfDeptPriceSuite-0004", "1,234.00")
    click("aSvcfDeptPricePvt-0004")
    type("txtSvcfDeptPricePvt-0004", "1,234.00")
    click("aSvcfDeptPriceTwoBed-0004")
    type("txtSvcfDeptPriceTwoBed-0004", "1,234.00")
    click("aSvcfDeptPriceWard-0004")
    type("txtSvcfDeptPriceWard-0004", "1,234.00")
    click("aSvcfDeptPriceOpd-0004")
    type("txtSvcfDeptPriceOpd-0004", "1,234.00")
    sleep 3
    click("btnSvcfOk")
    sleep 3
    select("selSvcfDept", "Pharmacy (04)")
    type("txtSvcfCode", code)
    type("txtSvcfDesc", desc)
    click("btnSvcfOk", :wait_for => :page)
    return code
  end
  def fm_search_icd10(options={})
    type("code", options[:code])
    type("desc", options[:description]) if options[:description]
    click("//input[@value='Search']", :wait_for => :page)
    is_element_present("link=#{options[:code]}")
  end
  def fm_add_icd10(options={})
    click("//input[@value='Add']", :wait_for => :page)
    type("icd10_code", options[:code])
    type("icd10_description", options[:description])
    click("saveBtn", :wait_for => :page) if options[:save]
    click("//input[@value='Cancel' and @name='cancel']", :wait_for => :page) if options[:cancel]
    return get_text("errorMessages") if is_element_present("errorMessages")
    return get_text("successMessages") if is_element_present("successMessages")
  end
  def fm_edit_icd10(options={})
    click("link=#{options[:code]}", :wait_for => :page)
    type("icd10_description", options[:description])
    click("saveBtn", :wait_for => :page) if options[:save]
    click("delete", :wait_for => :visible, :element => "//button[2]") if options[:delete]
    click("//button[2]", :wait_for => :page) if options[:delete]
    if options[:cancel]
      click("cancel", :wait_for => :page)
      return true if is_element_present("code")
    end
    return get_text("errorMessages") if is_element_present("errorMessages")
    return get_text("successMessages") if is_element_present("successMessages")
  end
  def package_rate(options={})
    if options[:add]
        click("id=btnPkgRate_add");
        sleep 6
        header_code = options[:package_code]
        type("id=txtPkgRate_packageAmount", options[:package_amount]);
        type("id=txtPkgRate_pfAmount",options[:pf_amount]);
        puts header_code
        charge_code =   options[:charge_code]
        select("id=selPkgRate_pkgChargeCode", "label=#{charge_code}");
        now = Time.now.strftime("%m/%d/%Y")
        type("id=txtPkgRate_effectivityDate", now);
        click("id=btnPkgRate_ok",:wait_for => :page);
        case charge_code
                  when "PRESIDENTIAL"
                            mycharge_code = "PCH01"
                  when "SUITE"
                            mycharge_code = "PCH02"
                  when "PRIVATE"
                            mycharge_code = "PCH03"
        end
        rate_code = header_code + mycharge_code
        puts rate_code
        if is_text_present("The record #{rate_code} has been saved.")
                return true
        else
                return false
        end

    end
end

end