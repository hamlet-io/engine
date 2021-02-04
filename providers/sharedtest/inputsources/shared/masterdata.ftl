[#ftl]

[#macro sharedtest_input_shared_masterdata_seed ]
  [@addMasterData
    data=
      {
        "DeploymentGroups" : {
          "external" : {
            "Priority" : 500,
            "Level" : "solution",
            "ResourceSets" : {}
          }
        }
      }
    /]
[/#macro]
