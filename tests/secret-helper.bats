#!/usr/bin/env bats

source ./usr/bin/secret-helper.sh

function teardown(){
    if [ -e fileWithContent ]; then
        rm fileWithContent
    fi
    unset ENV_VALUE
    unset ENV_VALUE_FILE
}

@test "Given env with '_FILE' suffix, when get secret from env, then file content is returned" {
    echo "file_value" > fileWithContent
    export ENV_VALUE_FILE="fileWithContent"
    
    run get_secret_from_env "ENV_VALUE"
    
    [ "$output" == "file_value" ]
    [ "$status" -eq 0 ]
}

@test "Given env not exist, when get secret from env, then nothing is returned" {
    run get_secret_from_env "ENV_VALUE"
    
    [ "$output" == "" ]
    [ "$status" -eq 0 ]
}

@test "Given env not exist, when get secret from env with default value, then default value is returned" {
    run get_secret_from_env "ENV_VALUE" "default_value"
    
    [ "$output" == "default_value" ]
    [ "$status" -eq 0 ]
} 

@test "Given env without '_FILE' suffix, when get secret from env, then value of env is returned" {
    export ENV_VALUE="value"
    
    run get_secret_from_env "ENV_VALUE"
    
    [ "$output" == "value" ]
    [ "$status" -eq 0 ]
}

@test "Given both env exist, when get secret from env, error is returned" {
    echo "file_value" > fileWithContent
    export ENV_VALUE_FILE="fileWithContent"
    export ENV_VALUE="value"
    
    run get_secret_from_env "ENV_VALUE"
    
    [ "$output" == "Only one of both variable 'ENV_VALUE' and 'ENV_VALUE_FILE' must be set." ]
    [ "$status" -eq 1 ]
}

@test "Given file not exist, when get secret from env, error is returned" {
    export ENV_VALUE_FILE="fileWithContent"
    
    run get_secret_from_env "ENV_VALUE"
 
    [ "$output" == "The file 'fileWithContent' in environnement variable 'ENV_VALUE_FILE' not exist." ]
    [ "$status" -eq 1 ]
}

@test "Given secret file env, when export secret from env, then secret is export to env" {
    echo "file_value" > fileWithContent
    export ENV_VALUE_FILE="fileWithContent"
    
    export_secret_from_env "ENV_VALUE"
   
    [ "$?" -eq 0 ]
    [ "$ENV_VALUE" == "file_value" ]
}

@test "Given secret file not exist, when export secret from env, then error is returned" {
    export ENV_VALUE_FILE="fileWithContent"
    
    run export_secret_from_env "ENV_VALUE"

    [ "$output" != "" ]
    [ "$status" -eq 1 ]
}