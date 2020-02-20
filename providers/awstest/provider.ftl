[#ftl]

[#--
    The test provider loads in scenarios with test configuration
    which is used to perform unit tests of the templates we generate

    To add a new test scneraio
    - Add a new scenario under the scnenarios folder in this provider
    - Add the name of the scnenario to the list below

    All scenarios will be loaded over the top of each other
    Make sure to add the data appropriately

--]

[#assign AWSTEST_PROVIDER = "awstest"]

[#assign testScenarios = [
    "lb"
]]

[@updateScenarioList
    scenarioIds=testScenarios
/]
