#!/bin/bash

# ----------------------------------------------------------------
# 定数定義
# ----------------------------------------------------------------
SRC_DIR="src"

# ----------------------------------------------------------------
# aws cli コマンドのチェック
# ----------------------------------------------------------------
check_aws_cli() {
    if ! type aws > /dev/null 2>&1; then
        echo "aws cli コマンドが見つかりません。\n処理を終了します。"
        exit 1
    fi
}

# ----------------------------------------------------------------
# jq コマンドのチェック
# ----------------------------------------------------------------
check_jq() {
    if ! type jq > /dev/null 2>&1; then
        echo -e "jq コマンドが見つかりません。\n処理を終了します。"
        exit 1
    fi
}

# ----------------------------------------------------------------
# npm コマンドのチェック
# ----------------------------------------------------------------
check_npm() {
    if ! type npm > /dev/null 2>&1; then
        echo "npm コマンドが見つかりません。\n処理を終了します。"
        exit 1
    fi
}

# ----------------------------------------------------------------
# コマンドヘルプ
# ----------------------------------------------------------------
display_help() {
    echo "Usage: $0 {command}"
    echo
    echo "Commands:"
    echo "  help                  Display this help message"
    echo "  init                  Initialize the environment (npm install)"
    echo "  lambda:build          Build the Typescript project"
    echo "  lambda:deploy         Deploy the Lambda function using SAM"
    echo "  cfn:list              List CloudFormation stacks"
    echo "  cfn:del {stack_name}  Delete CloudFormation stacks"
    echo "  s3:list               List S3 buckets"
    echo "  s3:del {bucket_name}  Delete all objects in the specified S3 bucket"
    echo
    echo "Examples:"
    echo "  $0 help"
    echo "  $0 init"
    echo "  $0 lambda:build"
    echo "  $0 lambda:deploy"
    echo "  $0 cfn:list"
    echo "  $0 cfn:del my-stack-name"
    echo "  $0 s3:list"
    echo "  $0 s3:del my-bucket-name"
}

# ----------------------------------------------------------------
# 環境構築
# ----------------------------------------------------------------
init() {
    cd $SRC_DIR
    npm install
}

# ----------------------------------------------------------------
# Typescript のビルド
# ----------------------------------------------------------------
build() {
    cd $SRC_DIR
    npm run build
}

# ----------------------------------------------------------------
# デプロイ用の関数
# ----------------------------------------------------------------
deploy_lambda() {
    sam build
    sam deploy
}

# ----------------------------------------------------------------
# CloudFormation のスタック一覧を表示
# ----------------------------------------------------------------
list_cloudformation_stacks() {
    echo "CloudFormation スタック一覧"
    echo "---------------------------"
    aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE DELETE_FAILED \
        --query "StackSummaries[*].[StackName, StackStatus, LastUpdatedTime]" \
        --output table
}

# ----------------------------------------------------------------
# デプロイしたリソースの削除
# $1: スタック名
# ----------------------------------------------------------------
delete_cfn_stack() {
    STACK_NAME=$1

    # CloudFormationスタックの削除
    aws cloudformation delete-stack --stack-name ${STACK_NAME}

    # スタックの削除が完了するまで待機
    aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}
    STATUS=$?

    if [ $STATUS -eq 0 ]; then
        echo "スタック ${STACK_NAME} の削除が完了しました。"
    else
        echo "スタック ${STACK_NAME} の削除中にエラーが発生しました。\nS3バケットが空であることを確認してください。"
    fi
}

# ----------------------------------------------------------------
# S3 のバケット名一覧を表示
# ----------------------------------------------------------------
list_s3_bucket() {
    echo "S3 バケット一覧"
    echo "---------------------------"
    aws s3 ls --output table
}

# ----------------------------------------------------------------
# S3 バケット内の全オブジェクト削除
# $1: バケット名
# ----------------------------------------------------------------
delete_s3_bucket_objects() {
    BUCKET_NAME=$1

    # バケット内の全オブジェクト削除
    aws s3 rm s3://${BUCKET_NAME}/ --recursive

    # DeleteMarkersの削除
    aws s3api list-object-versions --bucket ${BUCKET_NAME} \
            | jq -r -c '.["DeleteMarkers"][] | [.Key,.VersionId]' \
            | while read line
    do
            key=`echo $line | jq -r .[0]`
            versionid=`echo $line | jq -r .[1]`
            aws s3api delete-object --bucket ${BUCKET_NAME} \
                   --key ${key} --version-id ${versionid}
    done

    # Versionsの削除
    aws s3api list-object-versions --bucket ${BUCKET_NAME} \
            | jq -r -c '.["Versions"][] | [.Key,.VersionId]' \
            | while read line
    do
            key=`echo $line | jq -r .[0]`
            versionid=`echo $line | jq -r .[1]`
            aws s3api delete-object --bucket ${BUCKET_NAME} \
                   --key ${key} --version-id ${versionid}
    done

    echo "S3バケット ${BUCKET_NAME} のオブジェクト削除が完了しました。"
}

# ----------------------------------------------------------------
# メイン処理
# ----------------------------------------------------------------
main() {
    check_aws_cli
    check_jq
    check_npm

    case "$1" in
        "help")
            display_help
            exit 1
            ;;
        "init")
            init
            ;;
        "lambda:build")
            build
            ;;
        "lambda:deploy")
            deploy_lambda
            list_cloudformation_stacks
            ;;
        "cfn:list")
            list_cloudformation_stacks
            ;;
        "cfn:del")
            shift 1
            delete_cfn_stack "$@"
            list_cloudformation_stacks
            ;;
        "s3:list")
            list_s3_bucket
            ;;
        "s3:del")
            shift 1
            delete_s3_bucket_objects "$@"
            list_s3_bucket
            ;;
        *)
            display_help
            exit 1
            ;;
    esac
}

main "$@"

