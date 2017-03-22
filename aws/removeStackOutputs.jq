# Remove the outputs of one stack from the stack output composite
# Expects 
#   first input file to be the current stack composite
#   second input file to be the stack result to be removed
#   -s (slurp) option to be used
(.[1].Stacks | select(.!=null) | 
    .[].Outputs | select(.!=null) | 
    map(.OutputKey)) as $current | 
[.[0] | .[] | select([.OutputKey != $current[]] | all) ]
