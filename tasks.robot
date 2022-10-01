*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Archive
Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log to Console    ${row}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Run Keyword And Ignore Error    Click Element    //div[@class="modal"]//button[text()="OK"]

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Element    //input[@id="id-body-${row}[Body]"]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Body]
    Input Text    //input[@placeholder="Shipping address"]    ${row}[Address]

Preview the robot
    Click Element    //button[@id="preview"]
    Wait Until Element Is Visible    id:robot-preview-image

Submit the order
    ${order_error}=    Set Variable    ${TRUE}
    WHILE    ${order_error}
        Click Element    //button[@id="order"]
        ${order_error}=    Is Element Visible    //div[@role="alert" and contains(@class, "alert-danger")]
    END

Take a screenshot of the robot
    [Arguments]    ${ordernumber}
    ${filename}=    Set Variable    ${OUTPUT_DIR}${/}robot-order-${ordernumber}.png
    Screenshot    id:robot-preview-image    ${filename}
    RETURN    ${filename}

Store the receipt as a PDF file
    [Arguments]    ${ordernumber}
    ${filename}=    Set Variable    ${OUTPUT_DIR}${/}results${/}robot-order-${ordernumber}.pdf
    ${receipt_html}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${filename}
    RETURN    ${filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    @{files}=    Create list    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=True

Go to order another robot
    Click Element    //button[@id="order-another"]

Create a ZIP file of the receipts
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}results${/}
    ...    ${OUTPUT_DIR}${/}orders.zip
