[#ftl]

[#-- Deployment frameworks --]
[#assign DEFAULT_DEPLOYMENT_FRAMEWORK = "default"]


[#-- Default testcase --]
[#macro shared_testcase occurrence ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local componentType = occurrence.Core.Type ]

    [#local testProfileNames = (solution.Profiles.Testing)![] ]

    [#local testCaseNames = []]
    [#list testProfileNames as testProfileName ]
        [#if (testProfiles[testProfileName]!{})?? ]
            [#local testProfileDetail = testProfiles[testProfileName] ]

            [#if testProfileDetail["*"]?? ]
                [#local testCaseNames += testProfileDetail["*"].TestCases ]
            [/#if]

            [#if testProfileDetail[componentType]??]
                [#local testCaseNames += testProfileDetail[componentType].TestCases ]
            [/#if]
        [/#if]
    [/#list]

    [#local testCaseNames = getUniqueArrayElements(testCaseNames) ]

    [#local tests = {} ]
    [#list testCaseNames as testCaseName ]
        [#if testCases[testCaseName]?? ]
            [#local testCase = testCases[testCaseName] ]

            [#local tests = mergeObjects(
                tests,
                {
                    testCaseName  : {
                        "filename" : testCase.OutputSuffix,
                        "cfn_lint" : testCase.Tools.CFNLint,
                        "cfn_nag"  : testCase.Tools.CFNNag
                    }
                }
            )]

            [#list (testCase.Structural.JSON.Match)!{} as id,matchTest ]
                [#local tests = combineEntities(tests,
                    {
                        testCaseName : {
                            "json_structure" : {
                                "match" : [
                                    {
                                        "path" : matchTest.Path,
                                        "value" : matchTest.Value
                                    }
                                ]
                            }
                        }
                    },
                    APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]

            [#list (testCase.Structural.JSON.Length)!{} as id,legnthTest ]
                [#local tests = combineEntities(tests,
                    {
                        testCaseName : {
                            "json_structure"  : {
                                "length" : [
                                    [
                                        {
                                            "path" : legnthTest.Path,
                                            "value" : legnthTest.Count
                                        }
                                    ]
                                ]
                            }
                        }
                    },
                    APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]

            [#if testCase.Structural.JSON.Exists?has_content ]
                [#local existPaths = []]
                [#list testCase.Structural.JSON.Exists as path ]
                    [#local existPaths += [
                            {
                                "path" : path
                            }
                        ]
                    ]
                [/#list]
                [#local tests = mergeObjects(
                    tests,
                    {
                        testCaseName  : {
                            "json_structure" : {
                                "exists" : existPaths
                            }
                        }
                    }
                )]
            [/#if]

            [#if testCase.Structural.JSON.NotEmpty?has_content ]
                [#local notEmtpyPaths = []]
                [#list testCase.Structural.JSON.NotEmpty as path ]
                    [#local notEmtpyPaths += [
                            {
                                "path" : path
                            }
                        ]
                    ]
                [/#list]
                [#local tests = mergeObjects(
                    tests,
                    {
                        testCaseName  : {
                            "json_structure" : {
                                "not_empty" : notEmtpyPaths
                            }
                        }
                    }
                )]
            [/#if]

            [#list (testCase.Structural.CFN.Resource)!{} as id,CFNResourceTest ]
                [#local tests = combineEntities(tests,
                    {
                        testCaseName : {
                            "cfn_structure"  : {
                                "resource" : [
                                    {
                                        "id" : CFNResourceTest.Name,
                                        "type" : CFNResourceTest.Type
                                    }
                                ]
                            }
                        }
                    },
                    APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]

            [#if testCase.Structural.CFN.Output?has_content ]
                [#local cfnOutputPaths = []]
                [#list testCase.Structural.CFN.Output as path ]
                    [#local cfnOutputPaths += [
                            {
                                "id" : path
                            }
                        ]
                    ]
                [/#list]
                [#local tests = mergeObjects(
                    tests,
                    {
                        testCaseName  : {
                            "cfn_structure" : {
                                "output" : cfnOutputPaths
                            }
                        }
                    }
                )]
            [/#if]
        [/#if]
    [/#list]

    [@addToDefaultJsonOutput
        content=tests
    /]
[/#macro]
