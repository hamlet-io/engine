[#ftl]

[@addTask
    type=SSH_RUN_COMMAND_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Run an ssh command with an interactive shell"
            }
        ]
    attributes=[
        {
            "Names" : "Host",
            "Description" : "The IP or Hostname of the remote host",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Port",
            "Description" : "The port number the host is listening on for ssh connections",
            "Types" : NUMBER_TYPE,
            "Default" : 22
        },
        {
            "Names" : "Username",
            "Description" : "The username on the remote host",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Password",
            "Description" : "The password for the username on the remote host",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "SSHKey",
            "Description" : "The path or content of an ssh private key to use for authentication",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Command",
            "Description" : "The command to execute",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
