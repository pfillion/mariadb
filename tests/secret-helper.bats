#!/usr/bin/env bats

source  './rootfs/usr/local/bin/secret-helper.sh'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

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
    
    assert_output 'file_value'
    assert_success
}

@test "Given env not exist, when get secret from env, then nothing is returned" {
    run get_secret_from_env "ENV_VALUE"
    
    assert_output ''
    assert_success
}

@test "Given env not exist, when get secret from env with default value, then default value is returned" {
    run get_secret_from_env "ENV_VALUE" "default_value"
    
    assert_output 'default_value'
    assert_success
} 

@test "Given env without '_FILE' suffix, when get secret from env, then value of env is returned" {
    export ENV_VALUE="value"
    
    run get_secret_from_env "ENV_VALUE"
    
    assert_output 'value'
    assert_success
}

@test "Given both env exist, when get secret from env, then file content is returned" {
    echo "file_value" > fileWithContent
    export ENV_VALUE_FILE="fileWithContent"
    export ENV_VALUE="value"
    
    run get_secret_from_env "ENV_VALUE"
    
    assert_output 'file_value'
    assert_success
}

@test "Given file not exist, when get secret from env, then error is returned" {
    export ENV_VALUE_FILE="fileWithContent"
    
    run get_secret_from_env "ENV_VALUE"
 
    assert_output "The file 'fileWithContent' in environnement variable 'ENV_VALUE_FILE' not exist."
    assert_failure
}

@test "Given secret file env, when export secret from env, then secret is export to env" {
    echo "file_value" > fileWithContent
    export ENV_VALUE_FILE="fileWithContent"
    
    export_secret_from_env "ENV_VALUE"
   
    assert_equal $ENV_VALUE 'file_value'
    assert_success
}

@test "Given secret file not exist, when export secret from env, then error is returned" {
    export ENV_VALUE_FILE="fileWithContent"
    
    run export_secret_from_env "ENV_VALUE"

    assert_output "The file 'fileWithContent' in environnement variable 'ENV_VALUE_FILE' not exist."
    assert_failure
}