[#ftl]

[#-- Entrances --]
[#-- An entrance provides a way into the hamlet engine --]
[#-- The entrance itself can override or define actions to perform to set the path that will be taken --]
[#-- Entrances can also be used by flows to provide document generation based on the entrance that was used --]

[#assign entranceConfiguration = {}]

[#assign mandatoryCommandLineOptions = [
    {
        "Names" : "Flow",
        "Children" : [
            {
                "Names" : "Names",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Mandatory" : true
            }
        ]
    },
    {
        "Names" : "Deployment",
        "Children" : [
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


[#-- Macros to assemble the entrance configuration --]
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

[#function getEntranceTypes ]
    [#return entranceConfiguration?keys ]
[/#function]

[#function getEntrance type ]
    [#if ((entranceConfiguration[type])!{})?has_content]
        [#local entranceConfig = (entranceConfiguration[type])!{} ]
    [#else]
        [@fatal
            message="Could not find entrance"
            detail=label
        /]
    [/#if]

    [#return entranceConfig!{} ]
[/#function]

[#function getEntranceProperties type ]
    [#return (getEntrance(type).Properties)![] ]
[/#function]

[#function getEntranceCommandLineOptions type ]
    [#return (getEntrance(type).CommandLineOptions)![] ]
[/#function]

[#macro invokeEntranceMacro type ]

    [#local macroOptions = []]
    [#list commandLineOptions.Deployment.Provider.Names as provider ]
        [#local macroOptions +=
            [
                [ provider, "entrance", type ]
            ]
        ]
    [/#list]

    [#local macroOptions +=
        [
            [ SHARED_PROVIDER, "entrance", type ]
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
        [#stop "HamletFatal: Unable to find an entrance macro: ${type}" ]
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
