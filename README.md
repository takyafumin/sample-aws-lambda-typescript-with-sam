# sample-aws-lambda-typescript-with-sam

LambdaをTypescriptで実装してSAMでデプロイする

## 必要な環境

- aws cli
- aws sam cli
- node(20.x)

## 使い方

リポジトリをクローンしてプロジェクトをセットアップします。

```bash
git clone https://github.com/takyafumin/sample-aws-lambda-typescript-with-sam
cd sample-aws-lambda-typescript-with-sam

# npm モジュールのインストール
npm install
```

ソースコードを build します。
```bash
npm run build
```

sam を利用してデプロイします。

```bash
sam build
sam deploy
```

## 作成される AWS リソース

このプロジェクトでは以下の AWS リソースが作成されます。

|            リソース            |                                                                                         説明                                                                                          |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **AWS CloudFormationスタック** | SAM CLIは `template.yaml` をもとにCloudFormationスタックを作成し、Lambda関数やIAMロールなどのリソースを一元管理します。スタック名は `sam deploy` 実行時に指定したものが適用されます。 |
| **AWS Lambda**                 | TypeScriptで実装されたメインのLambda関数。リクエストを処理し、ビジネスロジックを実行します。                                                                                          |
| **IAMロール**                  | Lambdaが他のAWSリソースにアクセスするための権限を管理します。                                                                                                                         |
| **S3バケット** (SAM管理用)     | `aws-sam-cli-managed-default`スタックによって作成され、デプロイ時のアーティファクトが一時的に保存されます。                                                                           |


## AWS リソースの削除方法

作成された AWS リソースは、CloudFormation スタックとして削除できます。

```bash
aws cloudformation delete-stack --stack-name lambda-typescript-with-sam
```

SAM 管理用のスタックが不要であれば同様の手順で削除できます。

```bash
# S3 バケットに保存されたアーティファクトを削除する
# S3 バケット名は `sam deploy` 実行時に表示されるものを指定してください
aws s3 rm s3://aws-sam-cli-managed-default-samclisourcebucket-ycumlmrluwjh --recursive
aws s3api delete-bucket --bucket aws-sam-cli-managed-default-samclisourcebucket-ycumlmrluwjh


# SAM 管理用のスタックを削除する
aws cloudformation delete-stack --stack-name aws-sam-cli-managed-default
```

## TIPS

### プロジェクトの初期構築手順

- プロジェクトディレクトリを作成し、TypeScriptおよびSAMの必要な依存関係をインストールします。
   ```bash
   mkdir lambda-typescript-with-sam && cd lambda-typescript-with-sam
   npm init -y
   npm install --save-dev typescript @types/aws-lambda ts-node
   npm install aws-sdk
   ```
- tsconfig.jsonを設定し、TypeScriptをJavaScriptにトランスパイルする準備をします。
- Lambda関数 (src/handler.ts) を作成し、template.yaml でLambdaリソースを定義します。
- sam build と sam deploy --guided でビルドとデプロイを行います。

### CloudFormation スタックの確認方法

```bash
aws cloudformation list-stacks | jq -r '.StackSummaries[] | select( .StackStatus != "DELETE_COMPLETE" ) | .StackName'
```