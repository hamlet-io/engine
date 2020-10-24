[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Load the entrance to make sure that it is defined --]
[#assign entranceType = commandLineOptions.Entrance.Type ]
[#assign entrance = getEntrance(entranceType) ]

[#-- Validate Command line options are right for the entrance --]
[#assign validCommandLineOptions = getCompositeObject(entrance.Configuration, commandLineOptions) ]

[#-- Setup the contract outputs before invoking the entrance to allow for errors to be caught --]
[#if (commandLineOptions.Deployment.Unit.Subset!"") == "generationcontract" ]
    [@setupContractOutputs /]
[/#if]

[#-- Find and invoke the Entrance Macro --]
[#-- Entrances provided by explicit providers are preferred over the shared provider --]
[@invokeEntranceMacro
    type=entranceType
/]
