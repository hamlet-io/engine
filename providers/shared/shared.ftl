[#ftl]

[#-- Deployment frameworks --]
[#assign DEFAULT_DEPLOYMENT_FRAMEWORK = "default"]


[#-- Default testplan --]
[#macro shared_testplan occurrence ]
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

            [@debug message="testCase" context=testCase enabled=true /]

            [#local tests = mergeObjects(
                tests,
                {
                    testCaseName  : {
                        "filename" : testCase.OutputSuffix,
                        "no_lint" : testCase.Tools.CFNLint,
                        "no_vulnerability_check" : testCase.Tools.CFNNag
                    }
                }
            )]

            [#list (testCase.Structural.Match)!{} as id,matchTest ]
                [#local tests = combineEntities(tests,
                    {
                        testCaseName : {
                            "structure" : {
                                "match" : [
                                    [
                                        matchTest.Path,
                                        matchTest.Value
                                    ]
                                ]
                            }
                        }
                    },
                    APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]

            [#list (testCase.Structural.Length)!{} as id,legnthTest ]
                [#local tests = combineEntities(tests,
                    {
                        testCaseName : {
                            "structure"  : {
                                "length" : [
                                    [
                                        matchTest.Path,
                                        matchtTest.Count
                                    ]
                                ]
                            }
                        }
                    },
                    APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]

            [#if testCase.Structural.Exists?has_content ]
                [#local tests = mergeObjects(
                    tests,
                    {
                        testCaseName  : {
                            "structure" : {
                                "exists" : testCase.Structural.Exists
                            }
                        }
                    }
                )]
            [/#if]

            [#if testCase.Structural.NotEmpty?has_content ]
                [#local tests = mergeObjects(
                    tests,
                    {
                        testCaseName  : {
                            "structure" : {
                                "not_empty" : testCase.Structural.NotEmpty
                            }
                        }
                    }
                )]
            [/#if]

            [#list (testCase.Structural.CFNResource)!{} as id,CFNResourceTest ]
                [#local tests = combineEntities(tests,
                    {
                        testCaseName : {
                            "structure"  : {
                                "resource" : [
                                    [
                                        CFNResourceTest.Name,
                                        CFNResourceTest.Type
                                    ]
                                ]
                            }
                        }
                    },
                    APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]

            [#if testCase.Structural.CFNOutput?has_content ]
                [#local tests = mergeObjects(
                    tests,
                    {
                        testCaseName  : {
                            "structure" : {
                                "output" : testCase.Structural.CFNOutput
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
