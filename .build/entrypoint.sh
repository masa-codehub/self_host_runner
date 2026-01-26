#!/bin/bash

# エラー時にスクリプトを停止（安全のため）
set -e

# 環境変数チェック
# REPO_URLは初回登録時にのみ必要
: "${RUNNER_TOKEN:?RUNNER_TOKEN not set}"
: "${REPO_URL:?REPO_URL not set}"

# ランナーの名前やラベル
# ホスト名が変わる可能性を考慮して、固定の名前推奨だが、
# Docker Composeで hostname: を指定していない場合はコンテナIDになるので注意
RUNNER_NAME=${RUNNER_NAME:-"runner-$(hostname)"}
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted,linux,x64"}

# 認証ファイル(.runner)が存在しない場合のみ、登録処理を実行
# volumeマウントしていれば、2回目以降はここはスキップされる
if [ ! -f ".runner" ]; then
  echo "Runner configuration not found. Configuring..."
  ./config.sh --url "${REPO_URL}" \
              --token "${RUNNER_TOKEN}" \
              --name "${RUNNER_NAME}" \
              --labels "${RUNNER_LABELS}" \
              --unattended \
              --replace
fi

# ランナーを起動
echo "Starting runner..."
exec ./run.sh