*** Settings ***
Resource        ../resources/common.robot
Library         OperatingSystem

Suite Setup       Setup Device
Suite Teardown    Teardown Device


*** Variables ***
${DIST_DIR}     ${CURDIR}/../../dist


*** Test Cases ***
Device should have installed software tedge-modbus-plugin
    ${package}=    Get Modbus Package
    ${deb_version}=    Get Debian Package Version    ${package}
    ${installed}=    Device Should Have Installed Software    tedge-modbus-plugin
    Should Be Equal    ${installed["tedge-modbus-plugin"]["version"]}    ${deb_version}

Service should be active
    System D Service should be Active    tedge-modbus-plugin

ReInstall Modbus Plugin
    ${package}=    Get Modbus Package
    ${deb_version}=    Get Debian Package Version    ${package}
    # Uninstall tedge-modbus-plugin
    ${uninstall_operation}=    Cumulocity.Uninstall Software
    ...    {"name": "tedge-modbus-plugin", "version": "${deb_version}", "softwareType": "apt"}
    Operation Should Be SUCCESSFUL    ${uninstall_operation}    timeout=60
    Device Should Not Have Installed Software    tedge-modbus-plugin

    # Ensure smartrest config has no longer 'modbus' after uninstall
    ${templates}=    Get tedge smartrest config
    Should Be Equal    ${templates}    []    msg=SmartREST Message should be removed

    # Upload binary
    ${binary_url}=    Cumulocity.Create Inventory Binary
    ...    tedge-modbus-plugin
    ...    apt
    ...    file=${package}
    # Install modbus Plugin
    ${install_operation}=    Cumulocity.Install Software
    ...    {"name": "tedge-modbus-plugin", "version": "${deb_version}", "softwareType": "apt", "url": "${binary_url}"}
    Operation Should Be SUCCESSFUL    ${install_operation}    timeout=240
    ${installed}=    Device Should Have Installed Software    tedge-modbus-plugin
    Should Be Equal    ${installed["tedge-modbus-plugin"]["version"]}    ${deb_version}
    # Restart Plugin
    ${shell_operation}=    Execute Shell Command
    ...    sudo systemctl restart tedge-modbus-plugin
    ${shell_operation}=    Cumulocity.Operation Should Be SUCCESSFUL    ${shell_operation}    timeout=60
    # Check if plugin is running
    System D Service should be Active    tedge-modbus-plugin


*** Keywords ***
Get Modbus Package
    [Documentation]    Resolve the built .deb package from the dist directory
    ...    (produced by 'just build' / downloaded as the dist-packages artifact).
    ${files}=    OperatingSystem.List Files In Directory    ${DIST_DIR}    *.deb    absolute=${True}
    Should Not Be Empty    ${files}    msg=No .deb package found in ${DIST_DIR}. Run 'just build' first.
    RETURN    ${files}[0]

Get Debian Package Version
    [Arguments]    ${deb_file_path}
    ${version}=    Run    dpkg-deb -f ${deb_file_path} Version
    Log    ${version}
    RETURN    ${version}

System D Service should be Active
    [Arguments]    ${system_d_service}
    ${shell_operation}=    Execute Shell Command
    ...    sudo systemctl status ${system_d_service} | grep Active
    ${shell_operation}=    Cumulocity.Operation Should Be SUCCESSFUL    ${shell_operation}    timeout=60

    ${result_text}=    Set Variable    ${shell_operation}[c8y_Command][result]
    Should Contain    ${result_text}    active

Get tedge smartrest config
    ${shell_operation}=    Execute Shell Command
    ...    tedge config get c8y.smartrest.templates
    ${shell_operation}=    Cumulocity.Operation Should Be SUCCESSFUL    ${shell_operation}
    RETURN    ${shell_operation["c8y_Command"]["result"].strip()}
