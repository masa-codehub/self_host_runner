#!/bin/bash

# 環境変数チェック
# REPO_URLは初回登録時にのみ必要
: "${RUNNER_TOKEN:?RUNNER_TOKEN not set}"
: "${REPO_URL:?REPO_URL not set}"

# ランナーの名前やラベル
RUNNER_NAME=${RUNNER_NAME:-"runner-$(hostname)"}
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted,linux,x64"}

# クリーンアップ処理
cleanup() {
        echo "Removing runner..."
        if [ -x ./config.sh ]; then
                # ignore errors during remove to avoid masking original exit status
                ./config.sh remove --token "${RUNNER_TOKEN}" || true
        else
                echo "Warning: config.sh not found or not executable, skipping remove" >&2
        fi
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# ⬇️ 認証ファイル(.runner)が存在しない場合のみ、登録処理を実行
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
./run.sh & wait $!
