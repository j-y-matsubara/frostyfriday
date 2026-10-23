/*

- Week 118 - DevOps & CI/CD -
URL: https://www.frostyfri.day/en/challenges/blog/2024/11/08/week-118-devops-ci/cd

< ミッション > :
あなたの任務は、GitHubでホストされているYAMLファイルと同期するSnowflakeテーブルを作成することです。
そのファイルが変更されるたびに、テーブルは自動的に更新されます。
これは、自動化によって実現されるSnowflakeの魔法のようなものだと考えてください。

< 手順 > :
1. テーブルの作成 (Set the Scene)
    Snowflake 上に employee_data という名前のテーブルを作成する。
    列は first_name と department_id の2つを用意する。

2. データの投入 (Populate Your World)
    作成したテーブルにサンプルデータをいくつか入れておく。

3. GitHub側の準備 (Forge the Link)
    GitHub上に、Snowflakeのテーブルと同じ構造・データを持つ config.yaml というファイルを作成する。

4. 同期スクリプトの作成 (Conjure the Script)
    GitHubの config.yaml を読み込み、その内容で Snowflake のテーブルを更新（同期）する Python スクリプトを書く。

5. 自動化の設定 (Automate the Magic)
    GitHub Actions を設定し、config.yaml が更新されるたびに、手順4の Python スクリプトが自動で実行される仕組みを作る。

*/



USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS frostyfriday_wh;
CREATE OR ALTER DATABASE frostyfriday_db;
CREATE OR ALTER SCHEMA frostyfriday_db.week118_sch;

USE SCHEMA frostyfriday_db.week118_sch;
USE WAREHOUSE frostyfriday_wh;


/* 
=================================================================================================================
1. テーブルの作成 (Set the Scene)
    Snowflake 上に employee_data という名前のテーブルを作成する。列は first_name と department_id の2つを用意する。
=================================================================================================================
*/ 

CREATE OR ALTER TABLE employee_data
(
    first_name VARCHAR(100),
    department_id INTEGER
);

/* 
=================================================================================================================
2. データの投入 (Populate Your World)
    作成したテーブルにサンプルデータをいくつか入れておく。
=================================================================================================================
*/ 

INSERT INTO employee_data
    (first_name, department_id) 
VALUES 
    ('Sridhar', 1),
    ('Christian', 1),
    ('Benoit', 2),
    ('Thierry', 2)
;  

SELECT * FROM employee_data;

/* 
=================================================================================================================
3. GitHub側の準備 (Forge the Link)
    GitHub上に、Snowflakeのテーブルと「同じ構造・データを持つ」 config.yaml というファイルを作成する。
=================================================================================================================
*/ 


--- configs/config.yaml 参照


/* 
=================================================================================================================
4. 同期スクリプトの作成 (Conjure the Script)
    GitHubの config.yaml を読み込み、その内容で Snowflake のテーブルを更新（同期）する Python スクリプトを書く。
=================================================================================================================
*/ 


--- scripts/4_Conjure_the_Script.py 参照


/* 
=================================================================================================================
5. 自動化の設定 (Automate the Magic)
    GitHub Actions を設定し、config.yaml が更新されるたびに、手順4の Python スクリプトが自動で実行される仕組みを作る。
=================================================================================================================
*/ 

USE ROLE SECURITYADMIN;
CREATE ROLE IF NOT EXISTS frostyfriday_gha_role;

USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS frostyfriday_gha_wh;

GRANT USAGE ON WAREHOUSE frostyfriday_gha_wh TO ROLE frostyfriday_gha_role;
GRANT USAGE ON DATABASE frostyfriday_db TO ROLE frostyfriday_gha_role;
GRANT USAGE ON SCHEMA frostyfriday_db.week118_sch TO ROLE frostyfriday_gha_role;
GRANT SELECT, INSERT, DELETE
  ON TABLE frostyfriday_db.week118_sch.employee_data TO ROLE frostyfriday_gha_role;

USE ROLE USERADMIN;
CREATE USER frostyfriday_gha_user
  TYPE = SERVICE
  DEFAULT_ROLE = frostyfriday_gha_role
  WORKLOAD_IDENTITY = (
    TYPE    = OIDC
    ISSUER  = 'https://token.actions.githubusercontent.com'
    SUBJECT =  'repo:<github/repository>:ref:refs/heads/main'
    OIDC_AUDIENCE_LIST = ('https://<org>-<account>.snowflakecomputing.com')
  );

USE ROLE SECURITYADMIN;
GRANT ROLE frostyfriday_gha_role TO USER frostyfriday_gha_user;


-- USE ROLE SECURITYADMIN;
-- alter user frostyfriday_gha_user set network_policy = <Github Actionsの実行IPレンジから接続できるIPレンジを指定したPolicy>;

---------------------------------
-- Github の環境変数に下記を設定  --
---------------------------------

/* 
     変数名	               値の例	                   備考
SNOWFLAKE_ACCOUNT	   myorg-myaccount	       <org>-<account> 形式
SNOWFLAKE_ROLE	       frostyfriday_gha_role	   CREATE USER で DEFAULT_ROLE にしたロール
SNOWFLAKE_WAREHOUSE	   frostyfriday_gha_wh	           GRANT USAGE 済みのもの
SNOWFLAKE_DATABASE	   frostyfriday_db         employee_data があるデータベース
SNOWFLAKE_SCHEMA	   week118_sch	           employee_data があるスキーマ
*/ 

