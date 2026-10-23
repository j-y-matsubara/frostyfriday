
'''

<< 方針 >>

①Github Actionsの公式Imageを利用する
    https://github.com/marketplace/actions/snowflake-actions
    https://docs.snowflake.com/en/developer-guide/snowflake-cli/cicd/github-action

②Github Actions と Snowflake はより安全なworkload identity・OIDC接続を行う
    https://docs.snowflake.com/en/user-guide/workload-identity-federation

③最低限の整合性・エラーチェックは行う

'''


import os
import yaml
from snowflake.snowpark import DataFrame, Session
from snowflake.snowpark.exceptions import SnowparkSQLException

CONFIG = os.environ["CONFIG_PATH"]

#----------------------------------------------
#  config.yaml を読み込み
#----------------------------------------------
def load_config(path: str) -> tuple[str, list[dict]]:
    with open(path, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    table, rows = next(iter(data.items()))  # configに２つ以上のデータセットがある場合も１つ目しか読まないよ
    return table, rows


#----------------------------------------------
#  Snowflake 接続
#----------------------------------------------
def create_session() -> Session:
    return Session.builder.configs({
        "authenticator": "WORKLOAD_IDENTITY",
        "workload_identity_provider": "OIDC",
        "account": os.environ["SNOWFLAKE_ACCOUNT"],
        "token": os.environ["SNOWFLAKE_TOKEN"],
        "role": os.environ["SNOWFLAKE_ROLE"],
        "warehouse": os.environ["SNOWFLAKE_WAREHOUSE"],
        "database": os.environ["SNOWFLAKE_DATABASE"],
        "schema": os.environ["SNOWFLAKE_SCHEMA"],
    }).create()


#----------------------------------------------
#  configとSnowflakeの実態が合っているかチェック
#----------------------------------------------
def validate(session: Session, table: str, source: DataFrame) -> None:
    try:
        target_columns = set(session.table(table).columns)
    except SnowparkSQLException:
        raise ValueError(f"table '{table}' does not exist") from None

    if set(source.columns) != target_columns:
        raise ValueError(
            f"columns mismatch: config={sorted(source.columns)} table={sorted(target_columns)}"
        )


def main() -> None:
    table, rows = load_config(CONFIG)
    with create_session() as session:
        source = session.create_dataframe(rows)
        validate(session, table, source)
        source.write.mode("truncate").save_as_table(table)
        
        print(f"{table} テーブルシンク完了: {len(rows)} 行")


if __name__ == "__main__":
    main()