[#ftl]

[#-- Scenarios allow loading input data using the engine itself --]

[#assign testsList = []]

[#assign testConfiguration = {
    "Properties" : [
        {
            "Type"  : "Description",
            "Value" : "A test case which tests template generation"
        }
    ],
    "Attributes" : [
        {
            "Names" : "TestName",
            "Type" : STRING_TYPE,
            "Mandatory" : true       
        },
        {
            "Names" : "Output",
            "Type": STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "AssertionData",
            "Type" : ANY_TYPE,
            "Mandatory" : true
        }
    ]
}]


[#macro addTests tests ]
    [@internalMergeTestCases
        data=tests
    /]
[/#macro]

[#macro addTestCase
    deploymentUnit
    scenarioIds=[]
    tests=[]
]

    [#-- Set the deployment unit for the test case --]
    [@setDeploymentUnit deploymentUnit=deploymentUnit /]

    [#-- Update the list of scenarios to load --]
    [@updateScenarioList scenarioIds=scenarioIds /]

    [#-- Add in the test cases --]
    [@addTests tests /]

[/#macro]


[#-------------------------------------------------------
-- Internal support functions for component processing --
---------------------------------------------------------]

[#macro internalMergeTestCases data ]
    [#if data?has_content ]
        [#list data as content ]
            [#assign testsList = 
                combineEntities(
                    testsList,
                    [ getCompositeObject( testConfiguration.Attributes, content) ],
                    APPEND_COMBINE_BEHAVIOUR
                )]
        [/#list]
    [/#if]
[/#macro]