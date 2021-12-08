[#ftl]

[#-- Entrances --]
[#-- An entrance provides a way into the hamlet engine --]
[#-- The entrance itself can override or define actions to perform to set the path that will be taken --]
[#-- Entrances can also be used by flows to provide document generation based on the entrance that was used --]

[#assign ENTRANCE_CONFIGURATION_SCOPE = "Entrance" ]

[@addConfigurationScope
    id=ENTRANCE_CONFIGURATION_SCOPE
    description="Configuration of entrances"
/]

[#-- Macros to assemble the entrance configuration --]
[#macro addEntrance type commandlineoptions=[] properties=[]   ]

    [#local mandatoryCommandLineOptions = [
        {
            "Names" : "Flow",
            "Children" : [
                {
                    "Names" : "Names",
                    "Types" : ARRAY_OF_STRING_TYPE,
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
                            "Names" : "Types",
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
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Run",
            "Children" : [
                {
                    "Names" : "Id",
                    "Mandatory" : true,
                    "Types" : STRING_TYPE
                }
            ]
        }
    ]]

    [@addConfigurationSet
        scopeId=ENTRANCE_CONFIGURATION_SCOPE
        id=type
        attributes=combineEntities(commandlineoptions, mandatoryCommandLineOptions)
        properties=properties
    /]
[/#macro]

[#function getEntranceTypes ]
    [#return getConfigurationSetIds(ENTRANCE_CONFIGURATION_SCOPE) ]
[/#function]

[#function getEntrance type ]
    [#if getConfigurationSet(ENTRANCE_CONFIGURATION_SCOPE, type)?has_content ]
        [#return getConfigurationSet(ENTRANCE_CONFIGURATION_SCOPE, type) ]
    [#else]
        [@fatal
            message="Could not find entrance"
            detail={
                "Type" : type
            }
        /]
        [#return {}]
    [/#if]
[/#function]

[#function getEntranceProperties type ]
    [#return (getEntrance(type).Properties)![] ]
[/#function]

[#function getEntranceCommandLineOptions type ]
    [#return (getEntrance(type).Attributes)![] ]
[/#function]

[#macro invokeEntranceMacro type ]

    [#local macroOptions = []]
    [#list getLoaderProviders() as provider ]
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
            enabled=true
            stop=true
        /]
    [/#if]
[/#macro]

[#macro addEntranceInputSteps type ]

    [#local macroOptions = []]
    [#list getLoaderProviders() as provider ]
        [#local macroOptions +=
            [
                [ provider, "entrance", type, "inputsteps" ]
            ]
        ]
    [/#list]

    [#local macroOptions +=
        [
            [ SHARED_PROVIDER, "entrance", type, "inputsteps"  ]
        ]
    ]

    [#local macro = getFirstDefinedDirective(macroOptions)]
    [#if macro?has_content]
        [@(.vars[macro]) /]
    [#else]
        [@warn
            message="Could not find entrance macro seeder with provided options"
            context=macroOptions
            enabled=false
        /]
    [/#if]
[/#macro]
