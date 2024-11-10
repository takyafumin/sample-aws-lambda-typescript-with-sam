# sample-aws-lambda-typescript-with-sam

LambdaをTypescriptで実装してSAMでデプロイする

## 必要な環境

- aws cli
- aws sam cli
- node(20.x), npm

## 使い方

### プロジェクトのセットアップ

リポジトリをクローンしてプロジェクトをセットアップします。

```bash
git clone https://github.com/takyafumin/sample-aws-lambda-typescript-with-sam
cd sample-aws-lambda-typescript-with-sam
./run.sh init
```

### ビルドとデプロイ

ビルドを行います。

```bash
./run.sh lambda:build
```

デプロイします。

```bash
./run.sh lambda:deploy
```

## 作成される AWS リソース

このプロジェクトでは以下の AWS リソースが作成されます。

|            リソース            |                                                          説明                                                           |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------- |
| **AWS CloudFormationスタック** | SAM CLIは `template.yaml` をもとにCloudFormationスタックを作成し、Lambda関数やIAMロールなどのリソースを一元管理します。 |
| **AWS Lambda**                 | TypeScriptで実装されたメインのLambda関数。リクエストを処理し、ビジネスロジックを実行します。                            |
| **IAMロール**                  | Lambdaが他のAWSリソースにアクセスするための権限を管理します。                                                           |
| **S3バケット** (SAM管理用)     | `aws-sam-cli-managed-default`スタックによって作成され、デプロイ時のアーティファクトが一時的に保存されます。             |


## AWS リソースの削除方法

作成された AWS リソースは、CloudFormation スタックとして削除できます。

```bash
# CloudFormation スタック名を確認する
./run.sh cfn:list

# CloudFormation スタック名を指定して削除する
./run.sh cfn:del <stack-name>
```

SAM 管理用のスタックが不要であれば同様の手順で削除できます。

```bash
# SAM 管理用の S3 バケット名を確認する
./run.sh s3:list

# SAM 管理用の S3 バケット名を指定して削除する
./run.sh s3:del <bucket-name>

# SAM 管理用の スタック名を確認する
./run.sh cfn:list

# SAM 管理用の スタック名を指定して削除する
./run.sh cfn:del <stack-name>
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
