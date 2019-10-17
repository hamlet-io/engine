[#ftl]

[#-- Get stack output --]
[#macro aws_testcase_testlbhttps ]
    [@addTestCase
        deploymentUnit="https-lb"
        scenarioIds=[ "lbhttps" ]
        tests=[
            {
                "Output" : "template",
                "TestName" : "NotEmpty",
                "AssertionData" : ""
            }
        ]
    /]
[/#macro]
