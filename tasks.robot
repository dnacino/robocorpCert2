*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Playwright
Library             RPA.HTTP
Library             RPA.FileSystem
Library             RPA.Tables
Library             Collections
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Robocorp.WorkItems


*** Variables ***
${download URL}=        https://robotsparebinindustries.com/orders.csv
${order robot URL}=     https://robotsparebinindustries.com/#/robot-order
${OUTPUT_DIR}=          ${CURDIR}${/}output


*** Tasks ***
Download the order file
    RPA.HTTP.Download    ${download URL}    overwrite=True
    # Log To Console    ${OUTPUT_DIR}${\n}
    # Log To Console    ${CURDIR}${\n}

Order the robots from RobotSpareBin Industries Inc
    Open robot order page
    Read the csv file into table
    Order the robots and save each receipt and screenshot details in pdf

Archive the order files
    Zip the pdf files


*** Keywords ***
Open robot order page
    New Browser    headless=False
    New Page    ${order robot URL}

    # Take Screenshot    closed_annoying.png

Read the csv file into table
    ${orders_table}=    Read table from CSV    orders.csv    header=${True}    delimiters=","
    # Log    Found Columns: ${orders_table.columns}
    Set Global Variable    ${orders_table}

Order the robots and save each receipt and screenshot details in pdf
    FOR    ${ordered_robot}    IN    @{orders_table}
        # Log
        # ...    Robot Desc: ${ordered_robot}[Head],${ordered_robot}[Body],${ordered_robot}[Legs],${ordered_robot}[Address]
        ${order_receipt}=    Set Variable
        Fill the order form
        ...    ${ordered_robot}[Head]
        ...    ${ordered_robot}[Body]
        ...    ${ordered_robot}[Legs]
        ...    ${ordered_robot}[Address]
        ${order_receipt}=    Submit order and return the receipt    ${ordered_robot}[Order number]
        Save Order Details    ${ordered_robot}[Order number]    ${order_receipt}
        # ${order_made}=    Evaluate    ${order_made} + 1
        Click    text=Order another robot
        # IF    ${order_made} == 5    BREAK
    END

Fill the order form
    [Arguments]    ${head_number}    ${body_number}    ${Legs_umber}    ${Address}
    # close annoying popup
    Click    text=OK
    Click    \#head
    Select Options By    \#head    value    ${head_number}
    ${body_id}=    Set Variable
    Scroll To Element    id=id-body-${body_number}
    Check Checkbox    id=id-body-${body_number}
    Fill Text    xpath=//input[@placeholder="Enter the part number for the legs"]    ${Legs_umber}
    Fill Text    id=address    ${Address}

Submit order and return the receipt
    [Arguments]    ${order_number}
    ${at_fault}=    Set Variable    False
    Scroll To Element    text=Preview
    Click    text=Preview
    Take Screenshot    ${OUTPUT_DIR}${/}order_${order_number}    \#robot-preview-image
    WHILE    True
        ${at_fault}=    Set Variable    False
        Click    \#order
        Log To Console    Click order while level
        TRY
            ${dreceipt}=    Get Property    \#receipt    innerHTML
        EXCEPT
            # TimeoutError must click again
            Scroll To    vertical=bottom
            ${at_fault}=    Set Variable    True
            Log To Console    About to click order try level
        FINALLY
            Log To Console    Nothing seem correct
        END
        IF    ${at_fault} == False    BREAK
    END
    RETURN    ${dreceipt}

Save Order Details
    [Arguments]    ${order_number}    ${dreceipt}

    Html To Pdf    ${dreceipt}    ${OUTPUT_DIR}${/}receipt_order_${order_number}.pdf
    Open Pdf    ${OUTPUT_DIR}${/}receipt_order_${order_number}.pdf
    Add Watermark Image To Pdf
    ...    ${OUTPUT_DIR}${/}order_${order_number}.png
    ...    ${OUTPUT_DIR}${/}receipt_order_${order_number}.pdf
    Run Keyword And Ignore Error    Close Pdf    ${OUTPUT_DIR}${/}receipt_order_${order_number}.pdf
    Remove File    ${OUTPUT_DIR}${/}order_${order_number}.png    missing_ok=True

Zip the pdf files
    # Need to remove zip file as "Archive Folder With Zip" hate existing file
    Remove File    ${OUTPUT_DIR}${/}placed_orders.zip    missing_ok=True
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}placed_orders.zip
