*** Settings ***
Library     Cumulocity
Library     DeviceLibrary


*** Variables ***
# Cumulocity settings
&{C8Y_CONFIG}
...                     host=%{C8Y_BASEURL= }
...                     username=%{C8Y_USER= }
...                     password=%{C8Y_PASSWORD= }
...                     tenant=%{C8Y_TENANT= }


*** Keywords ***
Setup Device
    [Documentation]    Create a fresh tedge + modbus simulator stack, bootstrap it
    ...    to Cumulocity and set the device context to the main device.
    ${DEVICE_ID}=    DeviceLibrary.Setup
    ...    compose_file=${CURDIR}/../../docker-compose.yaml
    ...    device_service=tedge
    ...    skip_bootstrap=${True}
    Set Suite Variable    $DEVICE_ID
    Bootstrap Device    ${DEVICE_ID}
    Set Main Device
    Wait For Modbus Plugin Startup

Setup Child Device
    [Documentation]    Create the stack and set the device context to the
    ...    auto-registered Modbus child device (TestCase1).
    Setup Device
    Set Child Device1

Bootstrap Device
    [Arguments]    ${device_id}
    ${domain}=    Cumulocity.Get Domain
    DeviceLibrary.Execute Command    cmd=tedge config set c8y.url ${domain}
    ${credentials}=    Cumulocity.Bulk Register Device With Cumulocity CA    external_id=${device_id}
    DeviceLibrary.Execute Command    cmd=tedge cert download c8y --device-id ${device_id} --retry-every 5s --one-time-password '${credentials.one_time_password}'
    DeviceLibrary.Execute Command    cmd=tedge reconnect c8y
    Cumulocity.External Identity Should Exist    external_id=${device_id}
    ${operation}=    Cumulocity.Get Configuration    typename=tedge-configuration-plugin    timeout=60
    Cumulocity.Operation Should Be SUCCESSFUL    ${operation}
    Sleep    2s

Wait For Modbus Plugin Startup
    [Documentation]    tedge-modbus-plugin publishes the current configuration
    ...    as twin data only once it has connected to the MQTT broker (with
    ...    retries and a fixed delay), and its config file watcher is started
    ...    after that initial publish. Wait for the twin data to reach the
    ...    cloud so that operations modifying the config file are not missed
    ...    by the watcher and not overwritten by the stale startup publish.
    Cumulocity.Managed Object Should Have Fragments    c8y_ModbusConfiguration    timeout=60

Set Main Device
    Cumulocity.External Identity Should Exist    ${DEVICE_ID}

Set Child Device1
    Cumulocity.External Identity Should Exist    ${DEVICE_ID}:device:TestCase1

Collect Logs
    Run Keyword And Continue On Failure    Get Workflow Logs
    Run Keyword And Continue On Failure    Get Service Logs

Get Workflow Logs
    DeviceLibrary.Execute Command    head -n-0 /var/log/tedge/agent/*

Get Service Logs
    # systemd based image: collect from the journal
    DeviceLibrary.Execute Command    cmd=journalctl -n 10000 -u "tedge-*" -u "c8y-*" --no-pager
    Run Keyword And Continue On Failure
    ...    DeviceLibrary.Execute Command    cmd=tail -n 1000 /var/log/tedge-modbus-plugin/modbus.log

Teardown Device
    Collect Logs
    Cumulocity.Delete Managed Object And Device User    external_id=${DEVICE_ID}
