[#ftl]

[@addTask
    type=START_SSH_SHELL_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Start an ssh shell on a remote host"
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
            "Names" : "Shell",
            "Description" : "The command to execute to start the shell",
            "Types" : STRING_TYPE,
            "Default" : "/bin/bash"
        }
    ]
/]
