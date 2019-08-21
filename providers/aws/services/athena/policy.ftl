[#ftl]

[#function getAthenaStatement actions workgroup="*" principals="" conditions={}]
    [#return
        [
            getPolicyStatement(
                actions,
                ( workgroup != "*")?then(
                    formatRegionalArn(
                        "athena",
                        formatRelativePath(
                            athena,
                            getExistingReference(workgroup)
                        )
                    ),
                    workgroup
                ),
                principals,
                conditions)
        ]
    ]
[/#function]

[#function athenaConsumePermission workgroup conditions={}]
    [#return
        getAthenaStatement(
            [
                "athena:ListWorkGroups",
                "athena:GetExecutionEngine",
                "athena:GetExecutionEngines",
                "athena:GetNamespace",
                "athena:GetCatalogs",
                "athena:GetNamespaces",
                "athena:GetTables",
                "athena:GetTable"
            ],
            "*",
            principals,
            conditions
        ) + 
        getAthenaStatement(
            [
                "athena:StartQueryExecution",
                "athena:GetQueryResults",
                "athena:DeleteNamedQuery",
                "athena:GetNamedQuery",
                "athena:ListQueryExecutions",
                "athena:StopQueryExecution",
                "athena:GetQueryResultsStream",
                "athena:ListNamedQueries",
                "athena:CreateNamedQuery",
                "athena:GetQueryExecution",
                "athena:BatchGetNamedQuery",
                "athena:BatchGetQueryExecution", 
                "athena:GetWorkGroup" 
            ],
            workgroup,
            principals,
            conditions
        )
    ]
[/#function]