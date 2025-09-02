#!/bin/bash

# 環境変数が設定されていない場合はエラーで終了
: "${REPO_URL:?REPO_URL not set}"
: "${RUNNER_TOKEN:?RUNNER_TOKEN not set}"

# ランナーの名前（指定がなければホスト名）
RUNNER_NAME=${RUNNER_NAME:-"runner-$(hostname)"}
# ランナーのラベル（オプション）
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted,linux,x64"}
# ランナーのワーキングディレクトリ（オプション）
RUNNER_WORKDIR=${RUNNER_WORKDIR:-"_work"}

# クリーンアップ処理: スクリプト終了時にランナーを削除する
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "${RUNNER_TOKEN}"
}

# SIGINT(Ctrl+C) または SIGTERM を受け取ったときに cleanup 関数を呼び出す
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# GitHub Actions ランナーの設定
./config.sh --url "${REPO_URL}" \
            --token "${RUNNER_TOKEN}" \
            --name "${RUNNER_NAME}" \
            --labels "${RUNNER_LABELS}" \
            --work "${RUNNER_WORKDIR}" \
            --unattended \
            --replace

# ランナーを起動し、バックグラウンドジョブとして実行
# 'wait $!' を使うことで、シグナルを正しく受け取れるようにする
./run.sh & wait $!