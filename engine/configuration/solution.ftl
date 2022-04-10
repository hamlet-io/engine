[#ftl]

[#-- Solutions define the components that will be deployed into districts --]
[#assign SOLUTION_CONFIGURATION_SCOPE = "Solution"]
[#assign SOLUTION_EXTENSIONS_CONFIGURATION_SCOPE = "SolutionExtensions" ]

[#assign SOLUTION_CONFIGURATION_SET = "_default"]
[#assign DISTRICT_SOLUTION_CONFIGURATION_SET = "_district"]

[@addConfigurationScope
    id=SOLUTION_CONFIGURATION_SCOPE
    description="Solutions define the components in a district"
/]

[@addConfigurationScope
    id=SOLUTION_EXTENSIONS_CONFIGURATION_SCOPE
    description="A collection of the solution extensions that contribute to the overall solution"
/]

[#-- Add a specific district based configuration set district based solutions --]
[@addConfigurationSet
    scopeId=SOLUTION_CONFIGURATION_SCOPE
    id=DISTRICT_SOLUTION_CONFIGURATION_SET
    attributes=[
        {
            "Names" : "District",
            "Descriptions" : "Defines the layers that the solution applies to",
            "Children" : [
                {
                    "Names" : "Type",
                    "Description" : "The type of district the solution applies to",
                    "Default" : "segment"
                },
                {
                    "Names" : "Layers",
                    "Description": "The layers to match in a given district",
                    "SubObjects" : true,
                    "Children" : [
                        {
                            "Names" : "Type",
                            "Description" : "The type of layer the solution applies to",
                            "Types": STRING_TYPE,
                            "Mandatory": true
                        },
                        {
                            "Names": "Id",
                            "Description" : "The Id of a layer the solution applies to - * applies to all layers that match the type",
                            "Types" : STRING_TYPE,
                            "Default" : "*"
                        }
                    ]
                }
            ]
        }
    ]
/]


[#macro extendSolutionConfiguration id attributes provider]

    [@addConfigurationSet
        scopeId=SOLUTION_EXTENSIONS_CONFIGURATION_SCOPE
        id=id
        attributes=attribues
    /]

    [#local extendedAttributes = extendAttributes(
        (getConfigurationSet(SOLUTION_CONFIGURATION_SCOPE, SOLUTION_CONFIGURATION_SET)["Attributes"])![],
        attributes,
        provider
    )]

    [@addConfigurationSet
        scopeId=SOLUTION_CONFIGURATION_SCOPE
        id=SOLUTION_CONFIGURATION_SET
        attributes=extendedAttributes
    /]

    [@addConfigurationSet
        scopeId=BLUEPRINT_CONFIGURATION_SCOPE
        id="Solution"
        properties=properties
        attributes=[
            {
                "Names" : "Solutions",
                "Description": "Defines the components that belong to a district",
                "SubObjects" : true,
                "Children" : combineEntities(
                    (getConfigurationSet(SOLUTION_CONFIGURATION_SCOPE, DISTRICT_SOLUTION_CONFIGURATION_SET)["Attributes"])![]
                    (getConfigurationSet(SOLUTION_CONFIGURATION_SCOPE, SOLUTION_CONFIGURATION_SET)["Attributes"])![],
                    APPEND_COMBINE_BEHAVIOUR
                )
            }
        ] +

        [#-- Supports the existing solution layout which uses the root --]
        (getConfigurationSet(SOLUTION_CONFIGURATION_SCOPE, SOLUTION_CONFIGURATION_SET)["Attributes"])![]
    /]

[/#macro]
