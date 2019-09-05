[#ftl]

[#function formatAthenaWorkGroupArn workgroupName ]
    [#return 
        formatRegionalArn(
            "athena",
            formatRelativePath(
                "athena",
                workgroupName
            )
        )]
[/#function]

[#function getAthenaStatement actions workgroupName="*" principals="" conditions={}]
    [#return
        [
            getPolicyStatement(
                actions,
                ( workgroupName != "*")?then(
                    formatAthenaWorkGroupArn(workgroupName),
                    workgroupName
                ),
                principals,
                conditions)
        ]
    ]
[/#function]

[#function athenaConsumePermission workgroupName conditions={}]
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
            workgroupName,
            principals,
            conditions
        )
    ]
[/#function]