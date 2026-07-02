*** Settings ***
Resource        ../resources/common.robot

Suite Setup       Setup Device
Suite Teardown    Teardown Device


*** Test Cases ***
Device should support the operation c8y_SerialConfiguration
    Cumulocity.Should Contain Supported Operations    c8y_SerialConfiguration
