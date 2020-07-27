[#ftl]
[#include "/bootstrap.ftl" ]

[#switch commandLineOptions.Deployment.Unit.Name]

  [#case "component"]

    [#-- incl. provider configuration --]
    [#list findProviderMarkers() as providerMarker]
        [@internalIncludeProviderConfiguration
          providerMarker=providerMarker
        /]
    [/#list]

    [#-- incl. all component definitions --]
    [#list findComponentMarkers() as component]
      [@includeProviderComponentDefinitionConfiguration 
        provider=component.Path?split("/")[1]
        component=component.Path?split("/")[3]
      /]
    [/#list]

    [#list componentConfiguration as id,configuration]
      [#assign schemaComponentAttributes = []]
      [#list providerDictionary?keys as provider]
        [#if (configuration.ResourceGroups["default"].Attributes[provider]!{})?has_content]

          [#assign schemaComponentAttributes = combineEntities(
            schemaComponentAttributes,
            configuration.ResourceGroups["default"].Attributes[provider],
            ADD_COMBINE_BEHAVIOUR)]

        [/#if]
      [/#list]

      [@addSchema
        section="component"
        subset=id
        configuration=
          formatJsonSchemaFromComposite(
            {
              "Names" : id,
              "Type" : OBJECT_TYPE,
              "SubObjects" : true,
              "Children" : schemaComponentAttributes
            }
          )
      /]

    [/#list]
    [#break]

  [#case "reference"]

    [#list referenceConfiguration as id,configuration]
      [@addSchema
          section="reference"
          subset=configuration.Type.Plural
          configuration=
              formatJsonSchemaFromComposite(
                {
                  "Names" : configuration.Type.Plural,
                  "Type" : OBJECT_TYPE,
                  "SubObjects" : true,
                  "Children" : configuration.Attributes
                })
      /]
    [/#list]
    [#break]

  [#default]
    [#break]

[/#switch]

[#-- Redefine the core processing macro --]
[#macro processComponents level]
  [#if (commandLineOptions.Deployment.Unit.Subset!"") == "schema" ]
    [#local section = commandLineOptions.Deployment.Unit.Name]
    [@addSchemaToDefaultJsonOutput
        section=section
        schemaId=formatSchemaId(section)
        config=getSchema(section)!{}
    /]
  [/#if]
[/#macro]

[#if (commandLineOptions.Deployment.Unit.Subset!"") == "generationcontract" ]
  [@initialiseDefaultScriptOutput format=commandLineOptions.Deployment.Output.Format /]
  [@addDefaultGenerationContract subsets="schema" /]
[/#if]

[@generateOutput
  deploymentFramework=commandLineOptions.Deployment.Framework.Name
  type=commandLineOptions.Deployment.Output.Type
  format=commandLineOptions.Deployment.Output.Format
/]
