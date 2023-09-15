*** Settings ***
Documentation       Inhuman Insurance Robot Inc.
...                 Producer traffic data work item

Library             RPA.HTTP
Library             RPA.Desktop
# Library    RPA.JSON
Library             RPA.Tables
Library             Collections
# Library    RPA.Robocorp.WorkItems
Resource            shared.robot


*** Variables ***
${TRAFFIC_FILE_PATH}=           ${OUTPUT_DIR}${/}traffic.json
${TRAFFIC_FILE_PATH_CSV}=       ${OUTPUT_DIR}${/}traffic.csv
${COUNTRY_KEY}=                 SpatialDim
${GENDER_KEY}=                  Dim1
${RATE_KEY}=                    NumericValue
${YEAR_KEY}=                    TimeDim


*** Tasks ***
Produce traffic data work items
    Download traffic data
    Write data to csv
    ${table}=    Load data to table
    ${filtered_data}=    Filter and sort traffic data    ${table}
    ${filtered_data}=    Get latest data by country    ${filtered_data}
    ${payloads}=    Create work item payloads    ${filtered_data}


*** Keywords ***
Download traffic data
    Download
    ...    https://github.com/robocorp/inhuman-insurance-inc/raw/main/RS_198.json
    ...    ${TRAFFIC_FILE_PATH}
    ...    overwrite=True

Load data to table
    # Open File    ${OUTPUT_DIR}${/}traffic.json
    ${json}=    Load JSON from file    ${TRAFFIC_FILE_PATH}
    ${table}=    Create Table    ${json}[value]
    RETURN    ${table}

Write data to csv
    ${table}=    Load data to table
    Write table to CSV    ${table}    ${TRAFFIC_FILE_PATH_CSV}

Filter and sort traffic data
    [Arguments]    ${table}
    ${max_rate}=    Set Variable    ${5.0}
    ${both_genders}=    Set Variable    BTSX

    Filter Table By Column    ${table}    ${rate_key}    <    ${max_rate}
    Filter Table By Column    ${table}    ${gender_key}    ==    ${both_genders}
    Filter Table By Column    ${table}    ${year_key}    ==    False

    RETURN    ${table}

Get latest data by country
    [Arguments]    ${table}
    ${country_key}=    Set Variable    SpatialDim
    ${table}=    Group Table By Column    ${table}    ${country_key}
    ${latest_data_by_country}=    Create List
    FOR    ${group}    IN    @{table}
        ${first_row}=    Pop Table Row    ${group}
        Append To List    ${latest_data_by_country}    ${first_row}
    END
    RETURN    ${latest_data_by_country}

Create work item payloads
    [Arguments]    ${traffic_data}
    ${payloads}=    Create List
    FOR    ${row}    IN    @{traffic_data}
        ${payload}=
        ...    Create Dictionary
        ...    country=${row}[${COUNTRY_KEY}]
        ...    year=${row}[${YEAR_KEY}]
        ...    rate=${row}[${RATE_KEY}]
        Append To List    ${payloads}    ${payload}
    END
    RETURN    ${payloads}

Save work item payloads
    [Arguments]    ${payloads}
    FOR    ${payload}    IN    @{payloads}
        Save work item payload    ${payload}
    END

Save work item payload
    [Arguments]    ${payload}
    ${variables}=    Create Dictionary    ${WORK_ITEM_NAME}=${payload}
    Create Output Work Item    variables=${variables}    save=True
