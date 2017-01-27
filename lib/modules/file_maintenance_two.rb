
#!/bin/env ruby
# encoding: utf-8
module File_maintenance_two
  def fm_create_description_diagnosis_maj
    return "TEST DIAGMAJ'S" + "#{AdmissionHelper.range_rand(1, 1000).to_s}"
  end
  def fm_create_description_diagnosis_sub
    return "TEST DIAGSUB'S" + "#{AdmissionHelper.range_rand(1, 1000).to_s}"
  end
  def fm_create_description_diagnosis
    return "TEST DIAG'S" + "#{AdmissionHelper.range_rand(1, 1000).to_s}"
  end
  def fm_diagnosis_click_tab(diag_type)
    if diag_type == "Diagnosis_Major"
      click "link=Diagnosis Major"
      sleep 2
    elsif diag_type  == "Diagnosis_Sub"
      click "link=Diagnosis Sub"
      sleep 2
    elsif diag_type == "Diagnosis"
      click "//div[@id='right_col']/div[2]/ul[3]/li/a"
      sleep 2
    end
  end
  def fm_diagnosis_click_tab_checking(diag_type)
    result =  get_text "css=li.breadCrumbSub"
    if diag_type == "Diagnosis_Major"
      if  result == "Diagnosis Major"
        return true
      else
        return true
      end
    end
    if diag_type == "Diagnosis_Sub"
      if  result == "Diagnosis Sub"
        return true
      else
        return true
      end
    end
    if diag_type == "Diagnosis"
      if  result == "Diagnosis"
        return true
      else
        return true
      end
    end
  end
  def fm_diagnosis_input_search_param(options={})
    if   options[:diagnosis_type] == "Diagnosis_Major"
      type "id=txtQuery",options[:search]
    elsif options[:diagnosis_type] == "Diagnosis_Sub"
      type "id=txtQuery",options[:search]
    elsif options[:diagnosis_type] == "Diagnosis"
      type "id=txtQuery",options[:search]
    end
    click "//input[@value='Search']", :wait_for => :page
  end
  def fm_diagnosis_click_search_checking
    unless is_text_present "Nothing found to display."
      return get_text "//td"
    else return "Nothing found to display."
    end
  end
  def fm_diagnosis_edit(options={})
    sleep 6
    if  options[:diagnosis_type] == "Diagnosis_Major"
        click "//img[@alt='Edit']"
        type "id=txtDiag_desc",options[:desc]
        select "//select[@id='selDiag_status']",options[:stat]
        click "id=btnDiag_ok", :wait_for => :page
        sleep 10
    end

    if  options[:diagnosis_type] == "Diagnosis_Sub"
        click "//img[@alt='Edit']"
        type "id=txtDiag_desc",options[:desc]
        select "//select[@id='selDiag_status']",options[:stat]
        click "id=btnDiag_ok", :wait_for => :page
        sleep 10
    end

    if  options[:diagnosis_type] == "Diagnosis"
        click "//img[@alt='Edit']"
        type "id=txtDiag_desc",options[:desc]
        select "//select[@id='selDiag_status']",options[:stat]
        click "id=btnDiag_ok", :wait_for => :page
        sleep 10
    end
  end
  def fm_diagnosis_edit_checking(diag_type)
    if   diag_type == "Diagnosis_Major"
      if is_text_present "Unable to update status. There is an existing Diagnosis sub category which is active."
        return true
      else
        return "has been updated successfully."
      end
    end
     if   diag_type == "Diagnosis_Sub"
      if is_text_present "Unable to update status. There is an existing Diagnosis which is active."
        return true
      else
        return "has been updated successfully."
      end
    end
    if   diag_type == "Diagnosis"
      if is_text_present "Unable to update status. There is an existing Diagnosis which is active."
        return true
      else
        return "has been updated successfully."
      end
    end
  end
  def fm_diag_search(diag_type,status)
    if   diag_type == "Diagnosis_Major"
        select "id=sel_status",status
        click "//input[@value='Search']", :wait_for => :page
    elsif  diag_type == "Diagnosis_Sub"
        select "id=sel_status",status
        click "//input[@value='Search']", :wait_for => :page
    elsif diag_type == "Diagnosis"
        select "id=sel_status",status
        click "//input[@value='Search']", :wait_for => :page
    end
  end
  def fm_diagnosis_input(options={})
     click("id=btnDiag_add")
     sleep 2
     if  options[:diagnosis_type] == "Diagnosis_Major"
        type "id=txtDiag_desc",options[:desc]
        sleep 2
        select "id=selDiag_status", options[:stat]
        sleep 2
        click "id=btnDiag_ok"
        sleep 10
     end
     if  options[:diagnosis_type] == "Diagnosis_Sub"
        type "id=txtDiag_desc",options[:desc]
        sleep 2
        select "name=diagnosisMajor.code",options[:diag_maj]
        sleep 2
        select "id=selDiag_status", options[:stat]
        sleep 2
        click "id=btnDiag_ok"
        sleep 10
     end
     if  options[:diagnosis_type] == "Diagnosis"
        type "id=txtDiag_desc",options[:desc]
        sleep 2
        select "id=selDiag_diagnosisSub_code",options[:diag_sub]
        sleep 2
        select "id=selDiag_status", options[:stat]
        sleep 2
        click "id=btnDiag_ok"
        sleep 10
     end
  end
  def fm_diagnosis_click_printmasterlist(diag_type)
    if diag_type == "Diagnosis_Major"
      click "id=btnDiagnosisMajorPrintMaster"
      sleep 2
    elsif diag_type  == "Diagnosis_Sub"
      click "id=btnDiagnosisSubPrintMaster"
      sleep 2
    elsif diag_type == "Diagnosis"
      click "id=btnDiagnosisPrintMaster"
      sleep 2
    end
    click "//input[@id='btn_print']"
    sleep 10
  end
  #(FM DIAGNOSIS END HERE)
  #(FM ICD10 START HERE)
  def fm_create_description_icd10_maj
    return "TEST ICD10MAJ'S" +  "#{AdmissionHelper.range_rand(1, 1000).to_s}"
  end
  def fm_create_description_icd10_sub
    return "TEST ICD10SUB'S" +  " #{AdmissionHelper.range_rand(1, 1000).to_s}"
  end
  def fm_create_description_icd10
    return "TEST ICD10'S" +  " #{AdmissionHelper.range_rand(1, 1000).to_s}"
  end
  def fm_create_description_icd10_code
    return "ICD10 CODE+/ SAM" +  " #{AdmissionHelper.range_rand(1, 1000).to_s}"
  end
  def fm_icd10_click_tab(icd10_type)
    if icd10_type == "ICD10_Major"
      click "link=ICD10 Major Category"
      sleep 7
    elsif icd10_type  == "ICD10_Sub"
      click "link=ICD10 Sub Category"
      sleep 7
    elsif icd10_type == "ICD10"
      click "//div[@id='main']/ul[3]/li/a"
      sleep 7
    end
  end
  def fm_icd10_click_tab_checking(icd10_type)
    result =  get_value "//div[3]/input"
    if icd10_type == "ICD10_Major"
      if  result == "Add ICD10 Major Category"
        return true
      else
        return false
      end
    end
    if icd10_type == "ICD10_Sub"
     if  result == "Add ICD10 Sub Category"
        return true
      else
        return false
      end
    end
    if icd10_type == "ICD10"
      if  result == "Add ICD10"
        return true
      else
        return false
      end
    end
  end
  def fm_icd10_input_search_param(options={})
    if   options[:icd10_type] == "ICD10_Major"
      type "id=desc",options[:search]
    elsif options[:icd10_type] == "ICD10_Sub"
      type "id=desc",options[:search]
    elsif options[:icd10_type] == "ICD10"
      type "id=desc",options[:search]
    end
    click "//input[@name='action']", :wait_for => :page
  end
  def fm_icd10_click_search_checking
    unless is_text_present "Nothing found to display."
      return get_text "//td"
    else return "Nothing found to display."
    end
  end
  def fm_icd10_click_edit_btn
      click "//img[@alt='Edit Icd10']"
      sleep 10
  end
  def fm_icd10_click_edit_btn_checking(options={})
    if  options[:icd10_type] == "ICD10_Major"
        rslt = get_text "//div[2]/div/div/ul/li/a"
        if rslt == "ICD10 Major Category List"
          return true
        else
          return false
        end
    end
     if  options[:icd10_type] == "ICD10_Sub"
        rslt = get_text "//div[2]/div/div/ul/li[2]"
        if rslt == "ICD10 Sub Category"
          return true
        else
          return false
        end
    end
     if  options[:icd10_type] == "ICD10"
        rslt = get_text "//div[@id='breadCrumbs']/ul/li/a"
        if rslt == "Icd10 List"
          return true
        else
          return false
        end
    end
  end
  def fm_icd10_edit(options={})
    if  options[:icd10_type] == "ICD10_Major"
        type "id=majCategory_description",options[:desc]
        select "id=status",options[:stat]
    end
    if  options[:icd10_type] == "ICD10_Sub"
        type "id=subCategory_description",options[:desc]
        select "id=status",options[:stat]
    end
  end
  def fm_icd10_edit_checking(options={})
    if   options[:icd10_type] == "ICD10_Major"
      if is_text_present "Unable to update status. There is an existing ICD10 sub category which is active."
        return true
      else
        return "has been updated successfully."
      end
    end
     if   options[:icd10_type] == "ICD10_Sub"
      if is_text_present "Unable to update status. There is an existing ICD10 which is active."
        return true
      else
        return "has been updated successfully."
      end
    end
    if   options[:icd10_type]  == "ICD10"
      if is_text_present "has been updated successfully."
        return true
      else
        return false
      end
    end
  end
  def fm_icd10_click_save_btn
    click "id=saveBtn"
    sleep 10
  end
  def fm_icd10_input(options={})
     click("//div[3]/input")
     sleep 5
     if  options[:icd10_type] == "ICD10_Major"
        type "css=#majCategory_description",options[:desc]
        sleep 2
        type "id=majCategory_range",options[:range]
        sleep 2

     end
     if  options[:icd10_type] == "ICD10_Sub"

        type "id=subCategory_description",options[:desc]
        sleep 2
        type "id=subCategory_range",options[:range]
        sleep 2

     end

     if  options[:icd10_type] == "ICD10"
        type "id=icd10_code",options[:icd10_code]
        sleep 2
        type "id=icd10_description",options[:desc]
        sleep 2
     end
  end
  def fm_icd10_input_checking(options={})
    if  options[:icd10_type] == "ICD10_Major"
      if is_text_present "majorCategoryDescription is required to continue." or is_text_present "majorCategoryRange is required to continue."
        click "//button[@type='button']"
        return true
      else
        return false
      end
    end
    if  options[:icd10_type] == "ICD10_Sub"

      if is_text_present "subCategoryDescription is required to continue." or is_text_present "subCategoryRange is required to continue." or is_text_present "majorCategoryCode is required to continue."
        click "//button[@type='button']"
        return true
      else
        return false
      end
    end

     if  options[:icd10_type] == "ICD10"

      if is_text_present "code is required to continue." or is_text_present "description is required to continue." or is_text_present "subCategoryCode is required to continue."
        click "//button[@type='button']"
        return true
      else
        return false
      end
    end

  end
  def fm_icd10_search_maj(options={})
     if  options[:icd10_type] == "ICD10_Sub"
        click "//input[@value='FIND']"
        sleep 6
        type "id=txtSubCatQuery",options[:desc_maj]
        sleep 2
        click "id=btnSubCatFindSearch"
        sleep 6
     end
  end
  def fm_icd10_search_maj_checking(options={})
     if  options[:icd10_type] == "ICD10_Sub"
        rslt = get_text "id=tdSubCatCode-0"

        if rslt == options[:desc_maj_code]
          return true
        else
          return false
        end
     end
  end
  def fm_icd10_search_sub(options={})
     if  options[:icd10_type] == "ICD10"
        click "//input[@value='FIND']"
        sleep 6
        type "id=txtSubCatQuery",options[:desc_maj]
        sleep 2
        click "id=btnSubCatFindSearch"
        sleep 6
     end
  end
  def fm_icd10_search_sub_checking(options={})
     if  options[:icd10_type] == "ICD10"
        rslt = get_text "id=tdSubCatCode-0"

        if rslt == options[:desc_sub_code]
          return true
        else
          return false
        end
     end
  end
  def fm_icd10_click_maj
     click "id=tdSubCatCode-0"
     sleep 6
  end
  def fm_icd10_click_maj_checking(options={})
    rslt = get_value "id=majCategory_code"
    if rslt == options[:desc_maj_code]
      return true
    else
      return false
    end
  end
  def fm_icd10_click_sub
     click "id=tdSubCatCode-0"
     sleep 6
  end
  def fm_icd10_click_sub_checking(options={})
    rslt = get_value "id=subCategory_code"
    if rslt == options[:desc_sub_code]
      return true
    else
      return false
    end
  end
  def fm_icd10_click_printmasterlist(icd10_type,stat)
    if icd10_type == "ICD10_Major"
      click "id=masterListBtn"
      select "id=sel_status_print",stat
      sleep 2
    elsif icd10_type  == "ICD10_Sub"
      click "id=masterListBtn"
      select "id=sel_status_print",stat
      sleep 2
    elsif icd10_type == "ICD10"
      click "id=masterListBtn"
      select "id=sel_status_print",stat
      sleep 2
    end
    click "id=btn_print"
    sleep 10
  end
  def fm_icd10_click_printprooflist(icd10_type)
    if icd10_type == "ICD10_Major"
      click "id=proofListBtn"
      sleep 10
    elsif icd10_type  == "ICD10_Sub"
      click "id=proofListBtn"
      sleep 10
    elsif icd10_type == "ICD10"
      click "id=proofListBtn"
      sleep 10
    end
    get_confirmation
    sleep 10
  end
  #(FM ICD10 END HERE)
  #(FM SERVICES START HERE)
  def fm_services_landing_page_checking
      rslt = get_text "//div[@id='breadCrumbs']/ul/li"
      if rslt == "File Maintenance"
        return true
      else
        return false
      end
  end
  def fm_services_click_new_btn
      click "//div[@id='right_col']/div[8]/div/div[3]/input"
      sleep 3
  end
  def fm_services_select_dept(options={})
      if options[:dept] == "CSS"
        select "id=selSvcfDept","CSS (08)"
        sleep 3
      end
      if options[:dept] == "DON"
        select "id=selSvcfDept","DON (06)"
        sleep 3
      end
  end
  def fm_services_input_code(options={})
      if options[:dept] == "CSS"
        type "id=txtSvcfCode",options[:code]
      end
      if options[:dept] == "DON"
        select "id=selSvcfDept","DON (06)"
        sleep 3
      end
  end
  def fm_services_input_details(options={})
      if options[:dept] == "CSS"
        type "id=txtSvcfDesc", options[:desc]
        type "id=txtSvcfClLabel",options[:cllabel]
        select "id=selSvcfClTag",options[:cltag]
        click "//a[@id='aSvcfPhCode']/img"
        sleep 3
        type "id=txtNliQuery",options[:phcode]
        click "id=btnNliFindSearch"
        sleep 2
        click "id=tdNliCode-0"
        sleep 2
      #  click "id=chkSvcfSched"
        sleep 2
        click "//a[@id='aSvcfType']/img"
        sleep 2
        type "id=txtNliQuery",options[:ordertype]
        sleep 2
        click "id=btnNliFindSearch"
        sleep 2
        click "id=tdNliCode-0"
        sleep 2
        click "//a[@id='aSvcfDept']/img"
        sleep 2
        type "id=txtNuQuery",options[:owningdept]
        sleep 2
        click "id=btnNuFindSearch"
        sleep 2
        click "id=tdNuCode-0"
        sleep 2
        click "id=chkSvcfCsgn"
        sleep 2
        click "id=optViewModeBasic"

      end
      if options[:dept] == "DON"
        select "id=selSvcfDept","DON (06)"
        sleep 3
      end



  end
  def fm_services_input_grid_details(options={})
      if options[:dept] == "CSS"
        click "//a[@id='aSvcfDeptUom-0008']/img"
        sleep 3
        type "id=txtNliQuery",options[:uofm]
        sleep 2
        click "id=btnNliFindSearch"
        sleep 2
        click "id=tdNliCode-0"
        sleep 2
        click "//a[@id='aSvcfDeptPhBft-0008']/img"
        sleep 2
        type "id=txtPliQuery",options[:phbenefit]
        sleep 2
        click "id=btnPliFindSearch"
        sleep 2
        click "id=tdPliCode-0"
        sleep 2
        click "id=chkSvcfMrp-0008"
        sleep 2
        click "id=chkSvcfInv-0008"
        sleep 2
        click "id=aSvcfDeptPriceOpd-0008"
        sleep 2
        type "id=txtSvcfDeptPriceOpd-0008",options[:price]
      end
  end
  def fm_services_click_ok_btn(options={})
        sleep 3
        click("id=txtSvcfDesc")
        if options[:dept] == "CSS"
            click "id=btnSvcfOk"#,:wait_for =>:page
            sleep 20
        end
      end
  def fm_services_click_ok_btn_checking(options={})
        if options[:dept] == "CSS"
             if is_text_present options[:code]
              return true
            else
              return false
            end
        end
      end
  def go_to_services_page()
        click("link=File Maintenance");
        click("link=Services",:wait_for => :page);
      end
  def go_service()
        click("link=Service File Maintenance Landing Page",:wait_for => :page);
      end
  def select_scenario(options={})
  deptcode =   options[:deptcode]
  ort_type =options[:ort_type]
  m_code = options[:mcode]
  case deptcode
        when "DON"
                select("id=selSvcfDept", "label=DON (06)");
                mcode = get_text('//*[@id="txtSvcfCode"]')
                mservice_code = "06#{mcode}"
                sleep 3
                click("css=#aSvcfType > img");
                sleep 3
                type("id=txtNliQuery", ort_type);
                sleep 3
                click("id=btnNliFindSearch");
                sleep 3
                click("id=tdNliCode-0");
        when "DAS"
                select("id=selSvcfDept", "label=DAS (01)");
                mcode = get_text('//*[@id="txtSvcfCode"]')
                mservice_code = "01#{mcode}"
                sleep 3
                click("css=#aSvcfType > img");
                sleep 3
                type("id=txtNliQuery", ort_type);
                sleep 3
                click("id=btnNliFindSearch");
                sleep 3
                click("id=tdNliCode-0");
        when "FND"
                select("id=selSvcfDept", "label=FND (03)");
                mcode = get_text('//*[@id="txtSvcfCode"]')
                mservice_code = "03#{mcode}"
                sleep 3
                click("css=#aSvcfType > img");
                sleep 3
                type("id=txtNliQuery", ort_type);
                sleep 3
                click("id=btnNliFindSearch");
                sleep 3
                click("id=tdNliCode-0");
        when "WAREHOUSE"
                select("id=selSvcfDept", "label=Dispensed by Warehouse (05)");
                type("id=txtSvcfCode", m_code);
                click("id=txtSvcfDesc")
                sleep 3
                mservice_code = "05#{m_code}"
                click("css=#aSvcfType > img");
                sleep 3
                type("id=txtNliQuery", ort_type);
                sleep 3
                click("id=btnNliFindSearch");
                sleep 3
                click("id=tdNliCode-0");
                mcode = get_text('//*[@id="txtSvcfCode"]')
                puts "mcode = #{mcode}"  
        when "PHARMACY"
                select("id=selSvcfDept", "label=Pharmacy (04)");
                type("id=txtSvcfCode", m_code);
                sleep 3
                mservice_code = "04#{m_code}"
                click("css=#aSvcfType > img");
                sleep 3
                type("id=txtNliQuery", ort_type);
                sleep 3
                click("id=btnNliFindSearch");
                sleep 3
                click("id=tdNliCode-0");
        when "CSS"
                select("id=selSvcfDept", "label=CSS (08)");
                type("id=txtSvcfCode", m_code);
                sleep 3
                mservice_code = "08#{m_code}"
                click("css=#aSvcfType > img");
                sleep 3
                type("id=txtNliQuery", ort_type);
                sleep 3
                click("id=btnNliFindSearch");
                sleep 3
                click("id=tdNliCode-0");
        else
                select("id=selSvcfDept", "label=Catlab (26)");
                type("id=txtSvcfCode", m_code);
                sleep 3
                mservice_code = "26#{m_code}"
                sleep 3
                click("css=#aSvcfType > img");
                sleep 3                
                type("id=txtNliQuery", ort_type);
                sleep 3
                click("id=btnNliFindSearch");
                sleep 3
                click("id=tdNliCode-0");
  end

type("id=txtSvcfDesc", "TEST#{mservice_code}");
return mservice_code

  end
end
