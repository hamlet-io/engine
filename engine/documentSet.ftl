[#ftl]

[#-- Document Sets --]
[#-- The Hamlet engine uses the CMDB and blueprint to generate different artefacts --]
[#-- A collection of aretefacts for a particular purpose is defined as a document set --]
[#-- Document sets allow you to override and define command line options which will be used as part of the output processing --]

[#assign documentSetConfiguration = {}]

[#assign mandatoryCommandLineOptions = [
    {
        "Names" : "Deployment",
        "Children" : [
            {
                "Names" : "Unit",
                "Children" : [
                    {
                        "Names" : "Subset",
                        "Mandatory" : true,
                        "Type" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Output",
                "Children" : [
                    {
                        "Names" : "Type",
                        "Mandatory" : true
                    },
                    {
                        "Names" : "Format",
                        "Mandatory" : true
                    },
                    {
                        "Names" : "Prefix",
                        "Mandatory" : true
                    }
                ]
            }
        ]
    },
    {
        "Names" : "Logging",
        "Children" : [
            {
                "Names" : "Level",
                "Mandatory" : true,
                "Type" : STRING_TYPE
            }
        ]
    },
    {
        "Names" : "Run",
        "Children" : [
            {
                "Names" : "Id",
                "Mandatory" : true,
                "Type" : STRING_TYPE
            }
        ]
    }
]]



[#-- Macros to assemble the component configuration --]
[#macro addDocumentSet type commandlineoptions=[] properties=[]   ]
    [@internalDocumentSetConfiguration
        type=type
        configuration=
            {
                "Properties" : asArray(properties),
                "CommandLineOptions" : combineEntities( mandatoryCommandLineOptions, commandlineoptions)
            }
    /]
[/#macro]


[#function getDocumentSet type ]
    [#if ((documentSetConfiguration[type])!{})?has_content]
        [#local documentSetConfig = (documentSetConfiguration[type])!{} ]
    [/#if]

    [#if ! documentSetConfig?has_content ]
        [@fatal
            message="Could not find document set"
            detail=label
        /]
    [/#if]

    [#return documentSetConfig ]
[/#function]


[#-------------------------------------------------------
-- Internal support functions for documentset processing      --
---------------------------------------------------------]

[#-- Helper macro - not for general use --]
[#macro internalDocumentSetConfiguration type configuration]
    [#assign documentSetConfiguration =
        mergeObjects(
            documentSetConfiguration,
            {
                type : configuration
            }
        )]
[/#macro]
