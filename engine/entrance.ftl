[#ftl]

[#-- Entrances --]
[#-- An entrance provides a way into the hamlet engine --]
[#-- The entrance itself can override or define actions to perform to set the path that will be taken --]
[#-- Entrances can also be used by flows to provide document generation based on the entrance that was used --]

[#assign entranceConfiguration = {}]

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
[#macro addEntrance type commandlineoptions=[] properties=[]   ]
    [@internalEntranceConfiguration
        type=type
        configuration=
            {
                "Properties" : asArray(properties),
                "CommandLineOptions" : combineEntities( mandatoryCommandLineOptions, commandlineoptions)
            }
    /]
[/#macro]


[#function getEntrance type ]
    [#if ((entranceConfiguration[type])!{})?has_content]
        [#local entranceConfig = (entranceConfiguration[type])!{} ]
    [/#if]

    [#if ! entrance?has_content ]
        [@fatal
            message="Could not find document set"
            detail=label
        /]
    [/#if]

    [#return entranceConfig!{} ]
[/#function]

[#macro invokeEntranceMacro entranceType ]

    [#local macroOptions = []]
    [#list commandLineOptions.Deployment.Provider.Names as provider ]
        [#local macroOptions +=
            [
                [ provider, "entrance", entranceType ]
            ]
        ]
    [/#list]

    [#local macroOptions +=
        [
            [ SHARED_PROVIDER, "entrance", entranceType ]
        ]
    ]

    [#local macro = getFirstDefinedDirective(macroOptions)]
    [#if macro?has_content]
        [@(.vars[macro]) /]
    [#else]
        [@fatal
            message="Could not find entrance macro with provided options"
            context=macroOptions
            enabled=false
        /]
        [#stop "HamletFatal: Unable to find an entrance macro" ]
    [/#if]
[/#macro]


[#-------------------------------------------------------
-- Internal support functions for entrance  processing      --
---------------------------------------------------------]

[#-- Helper macro - not for general use --]
[#macro internalEntranceConfiguration type configuration]
    [#assign entranceConfiguration =
        mergeObjects(
            entranceConfiguration,
            {
                type : configuration
            }
        )]
[/#macro]
