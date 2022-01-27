*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    OperatingSystem
Library    RPA.Archive
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs
*** Variables ***
${orders_folder}    ${OUTPUT_DIR}${/}output${/}${/}orders${/}


*** Keywords ***
open browser and navigate
    ${secret}=    Get Secret    webURL
    Open Available Browser    ${secret}[URL]

Ask for CVS And Create table from CSV
    Add heading    Upload Excel File
    Add file input
    ...    label=Upload the Excel file with sales data
    ...    name=fileupload
    ...    destination=${CURDIR}    
    ${response}=    Run dialog
    @{files}    Read table from CSV    ${response.fileupload}[0]
    [return]  ${files}


close modal    
    Wait Until Element Is Visible    css:div.alert-buttons
    Click Button    OK

complete from
    [Arguments]    ${order}

    Select From List By Value    head    ${order}[Head]
    Click Element    id:id-body-${order}[Body]
    Input Text     //input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    Input Text    address    ${order}[Address]
    
Preview Robot 
    Click Button    //button[@id='preview']
    Wait Until Element Is Visible   //div[@id='robot-preview-image']

Submit Order
    Click Button    //button[@id='order']
    FOR    ${i}    IN RANGE    200000
        ${orderVisible} =    Is Element Visible    id:receipt
        Exit For Loop If    ${orderVisible}
        Click Button    //button[@id='order']
    END

Store Receipt as pdf
    [Arguments]    ${order} 
    ${path} =    Set Variable    ${orders_folder}order_${order}[Order number].pdf
    Wait Until Element Is Visible    id:receipt
    ${receipt_html} =    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${path}
    [Return]    ${path}


Take Screenshot
    [Arguments]    ${order}
    ${image_path} =    Set Variable    ${orders_folder}ord_${order}[Order number].png
    Screenshot    //div[@id='robot-preview']      ${orders_folder}ord_${order}[Order number].png

    [Return]    ${image_path}


Go To New Order
    Wait Until Page Contains Element    //button[@id='order-another']
    Click Button    //button[@id='order-another']

Insert Robot Image Into The PDF
    [Arguments]    ${pdf}    ${image}

    ${files}=    Create List    ${image}

    Add Files To Pdf   files=${files}    target_document=${pdf}    append=True
    Remove File    ${image} 

Create Zip From Orders folder
    Archive Folder With Zip    folder=${orders_folder}    archive_name=${orders_folder}${/}orders.zip       


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    open browser and navigate
    ${orders}=    Ask for CVS And Create table from CSV
 
    FOR    ${order}    IN    @{orders}
        close modal    
        complete from     ${order}
        Preview Robot 
        Submit Order
        ${pdf}=    Store Receipt as pdf    ${order}
        ${image}=    Take Screenshot    ${order}
        Insert Robot Image Into The PDF    ${pdf}    ${image}
        Go To New Order
    END
    Create Zip From Orders folder
    Close Browser
    [Teardown]

*** Comments ***

Keyword before user input

Create table from CSV
    ${filedownload}=    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    @{files}    Read table from CSV    orders.csv
    [return]  ${files}
