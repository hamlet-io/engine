[#ftl]

[#-- Component Extensions --]
[#-- Allows for the modification of a components state and its setup routine by users --]
[#-- Generally used for advanced configuration scenarios including programmatic settings and adding specialised resource --]
[#-- Extensions are defined as part plugin but can also be added to users CMDBs as an embedded extension --]

[#-- Extension Scopes --]
[#assign SETUP_EXTENSION_SCOPE = "setup" ]

[#-- the _context variable is used during context processing to store the changes resulting from the extension --]
[#assign _context = {}]

[#assign extensionDetails = {}]
[#assign extensionAliases = {}]

[#-- Id formatting for extension invocation --]
[#function getOccurrenceFragmentBase occurrence]
    [#return getOccurrenceExtensionBase(occurrence)]
[/#function]

[#function getOccurrenceExtensionBase occurrence]
    [#return contentIfContent(
            (occurrence.Configuration.Solution.Extensions)![],
            occurrence.Core.Component.Id
    )]
[/#function]

[#function formatFragmentId context occurrence={}]
    [#if context.Id?starts_with("_") ]
        [#return context.Id ]
    [#else]
        [#return
                formatName(
                    context.Id,
                    context.Instance!occurrence.Core.Instance.Id,
                    context.Version!occurrence.Core.Version.Id)]
    [/#if]
[/#function]

[#function formatExtensionIds occurrence ids=[] idsOnly=false ]
    [#local idBases = combineEntities(
                            idsOnly?then(
                                [],
                                getOccurrenceExtensionBase(occurrence)
                            ),
                            ids,
                            UNIQUE_COMBINE_BEHAVIOUR) ]

    [#local result = []]
    [#list asFlattenedArray(idBases) as id ]
        [#if id?starts_with("_") ]
            [#local result += [ id ]]
        [#else]
            [#local result += [
                    formatName(
                        id,
                        occurrence.Core.Instance.Id,
                        occurrence.Core.Version.Id)]]
        [/#if]
    [/#list]
    [#return result]
[/#function]


[#-- Define properties of an extension --]
[#macro addExtension id description supportedTypes aliases=[] entrances=["deployment"] scopes=[ SETUP_EXTENSION_SCOPE ] provider=SHARED_PROVIDER ]

    [#local extensionConfiguration = [
        "InhibitEnabled",
        {
            "Names" : "Id",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Aliases",
            "Type" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "SupportedTypes",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Entrances",
            "Type" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "Scopes",
            "Type" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "Description",
            "Type" : ARRAY_OF_STRING_TYPE
        }
    ]]

    [#local extensionProperties = {
        "Id" : id,
        "Aliases" : aliases,
        "Description" : description,
        "SupportedTypes" : supportedTypes,
        "Scopes" : scopes,
        "Entrances" : entrances
    }]

    [@addExtensionAliases
        id=id
        aliases=aliases
    /]

    [@internalMergeExtensionDetails
        id=id
        provider=provider
        details=getCompositeObject(extensionConfiguration, extensionProperties)
    /]
[/#macro]

[#function getExtensionDetails id provider="shared"]
    [#local extensionId = (extensionAliases[id])!"" ]
    [#return (extensionDetails[extensionId][provider])!{} ]
[/#function]

[#macro addExtensionAliases id aliases ]

    [#-- Add the default id mapping --]
    [@internalMergeExtensionAlias
        id=id
        alias=id
    /]

    [#list aliases as alias ]
        [@internalMergeExtensionAlias
            id=id
            alias=alias
        /]
    [/#list]
[/#macro]

[#function invokeExtensions occurrence context baseOccurrence={} additionalIds=[] additionalOnly=false entrance="deployment" scope="setup" provider="shared"  ]

    [#-- Replace the global context with the components context --]
    [#assign _context = context ]

    [#-- Temporarily define expected global variables from setContext. --]
    [@populateSetContextGlobalVariables enabled=true /]

    [#local occurrenceContext = {
        "Instance" : occurrence.Core.Instance.Id,
        "Version" : occurrence.Core.Version.Id,
        "Environment" : {},
        "DefaultBaselineVariables" : true,
        "DefaultLinkVariables" : true,
        "DefaultCoreVariables" : true,
        "DefaultComponentVariables" : true,
        "DefaultEnvironmentVariables" : true
    }]
    [#assign _context = mergeObjects(occurrenceContext, _context )]

    [#-- Sets the occurrence we use to determine the extension id base --]
    [#local baseOccurrence = valueIfContent(
                                baseOccurrence,
                                baseOccurrence,
                                occurrence) ]

    [#list formatExtensionIds(baseOccurrence, additionalIds, additionalOnly) as id]

        [#local extensionContext = {
            "Id" : id,
            "Name" : id
        }]
        [#assign _context = mergeObjects(_context, extensionContext )]

        [#local extensionDetails = getExtensionDetails(id, provider)]

        [#-- Legacy support for fragments --]
        [#local fragmentId = id ]

        [#local fragments = getFragments()?trim ]
        [#if fragments?has_content]
            [#if !fragments?contains("[#ftl]") ]
                [#-- Ensure fragments are assembled into a case statement --]
                [#local fragments = fragments?ensure_starts_with("[#ftl][#switch fragmentId]")?ensure_ends_with("[/#switch]") ]
            [/#if]

            [#-- Treat as interpretable content --]
            [#local inlineFragment = fragments?interpret]
            [@inlineFragment /]
        [/#if]

        [#-- Find the extension function --]
        [#if !(extensionDetails?has_content) ]
            [@debug
                message="Extension not found matching id"
                context=id
                enabled=true
            /]
            [#continue]
        [/#if]

        [#local extensionMacroOptions =
            [
                [ provider, "extension", extensionDetails.Id, entrance, scope ],
                [ provider, "extension", extensionDetails.Id, entrance ],
                [ provider, "extension", extensionDetails.Id, scope ],
                [ provider, "extension", extensionDetails.Id ]
            ]]

        [#local extensionMacro = getFirstDefinedDirective(extensionMacroOptions)]
        [#if extensionMacro?has_content ]

            [#-- Validate the extenion usage --]
            [#if ! extensionDetails?has_content ]
                [@fatal
                    message="Could not find extension details"
                    detail="An extension function was found but could not find its configuration details"
                    context={
                        "id" : id,
                        "provider" : provider,
                        "Component" : occurrence.Core.FullName
                    }
                /]
                [#continue]
            [/#if]

            [#if extensionDetails?has_content &&
                    ! ( extensionDetails.SupportedTypes?seq_contains( occurrence.Core.Type ) )&& ! ( extensionDetails.SupportedTypes?seq_contains( "*" )) ]
                [@fatal
                    message="Extension does not support component type"
                    detail="This extension does not support the component type it is being used with"
                    context={
                        "id" : id,
                        "provider" : provider,
                        "SupportedTypes" : extensionDetails.SupportedTypes,
                        "ComponentType" : occurrence.Core.Type,
                        "Component" : occurrence.Core.FullName
                    }
                /]
                [#continue]
            [/#if]

            [#if extensionDetails?has_content && ! ( extensionDetails.Scopes?seq_contains(scope) )]
                [@fatal
                    message="The extension does not support the extension scope required"
                    detail="Extensions are invoked at different stages of processing and are invoked with different scope filters on the provided extensions"
                    context={
                        "OccurrenceContext" : occurrenceContext,
                        "ExtensionId" : id,
                        "Provider" : provider,
                        "SupportedScopes" : extensionDetails.Scopes,
                        "CurrentScope" : scope
                    }
                /]
                [#continue]
            [/#if]

            [@(.vars[extensionMacro])
                occurrence=occurrence
            /]
        [#else]
            [@debug
                message="Unable to invoke extension were invalid"
                context=extensionMacroOptions
                enabled=true
            /]
        [/#if]
    [/#list]

    [#return _context]
[/#function]

[#-- Helper macro - not for general use --]
[#macro internalMergeExtensionDetails id provider details]
    [#assign extensionDetails =
        mergeObjects(
            extensionDetails,
            {
                id : {
                    provider : details
                }
            }
        ) ]
[/#macro]


[#macro internalMergeExtensionAlias alias id ]
    [#assign extensionAliases =
        mergeObjects(
            extensionAliases,
            { alias : id }
        ) ]
[/#macro]
